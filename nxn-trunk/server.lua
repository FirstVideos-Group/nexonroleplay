-- ============================================================
--  nxn-trunk | server.lua
-- ============================================================

-- ── Cache: { [plate] = { items=[], maxWeight=float } } ────
local trunkCache = {}

-- ── Segédfüggvények ─────────────────────────────────────────

local function Notify(src, msg, ntype)
    if GetResourceState('nxn-notify') == 'started' then
        TriggerClientEvent('nxn-notify:client:show', src, msg, ntype or 'info')
    end
end

local function ValidateCount(count)
    return type(count) == 'number' and math.floor(count) == count and count > 0
end

local function ValidatePlate(plate)
    return type(plate) == 'string' and #plate > 0 and #plate <= 8
end

--- Trunk betöltése adatbázisból vagy üres létrehozása
local function LoadTrunk(plate, maxWeight)
    if trunkCache[plate] then return trunkCache[plate] end

    local row = MySQL.single.await(
        'SELECT items, max_weight FROM `nxn_trunks` WHERE plate = ?',
        { plate }
    )

    if row then
        local ok, items = pcall(json.decode, row.items or '[]')
        trunkCache[plate] = {
            items     = ok and items or {},
            maxWeight = row.max_weight or maxWeight or Config.DefaultMaxWeight,
        }
    else
        local mw = maxWeight or Config.DefaultMaxWeight
        MySQL.insert.await(
            'INSERT INTO `nxn_trunks` (plate, items, max_weight) VALUES (?, ?, ?)',
            { plate, '[]', mw }
        )
        trunkCache[plate] = { items = {}, maxWeight = mw }
        NXN.Trunk.Info(('Trunk létrehozva: %s maxW=%.1f'):format(plate, mw))
    end

    return trunkCache[plate]
end

--- Trunk DB-mentés
local function SaveTrunk(plate)
    local trunk = trunkCache[plate]
    if not trunk then return end
    local ok, jsonStr = pcall(json.encode, trunk.items or {})
    if not ok then jsonStr = '[]' end
    MySQL.update(
        'UPDATE `nxn_trunks` SET items = ?, max_weight = ? WHERE plate = ?',
        { jsonStr, trunk.maxWeight, plate }
    )
    NXN.Trunk.Log(('SaveTrunk: %s'):format(plate))
end

--- Szinkron küldés a kliensnek
local function SyncTrunk(src, plate)
    local trunk = trunkCache[plate]
    if not trunk then return end
    local currentWeight = NXN.Trunk.CalcWeight(trunk.items)
    TriggerClientEvent('nxn-trunk:client:sync', src, {
        plate         = plate,
        items         = trunk.items,
        maxWeight     = trunk.maxWeight,
        currentWeight = currentWeight,
    })
end

--- Item keresés trunk listajában
local function FindItem(items, itemName)
    for i, item in ipairs(items) do
        if item.name == itemName then return i, item end
    end
    return nil, nil
end

--- Item súlya az nxn-inventory Config-ból (szerver-oldalon shared script)
local function GetItemWeight(itemName)
    if GetResourceState('nxn-inventory') ~= 'started' then return 1.0 end
    -- nxn-inventory shared.lua hozzáférés nincs közvetlenül, de a klienstol kapjuk
    -- Fallback: 1.0 kg ismeretlen itemnél
    return 1.0
end

-- ── DB init ──────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.Trunk.Info('nxn-trunk elindul...')
    CreateThread(function()
        if GetResourceState('nxn-database') ~= 'started' then
            NXN.Trunk.Warn('nxn-database nem fut – trunk tábla nem hozható létre')
            return
        end
        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_trunks',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_trunks` (
                    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
                    `plate`      VARCHAR(16)  NOT NULL UNIQUE,
                    `items`      JSON         NOT NULL DEFAULT '[]',
                    `max_weight` FLOAT        NOT NULL DEFAULT 50.0,
                    `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`),
                    INDEX `idx_plate` (`plate`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })
        NXN.Trunk.Info('nxn_trunks tábla OK.')
    end)
end)

-- ── Net eventek ──────────────────────────────────────────────

-- Trunk megnyitás
RegisterNetEvent('nxn-trunk:server:open', function(plate, vehicleClass, invItemDefs)
    local src = source
    plate = NXN.Trunk.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end

    -- osztály alapján maxWeight
    local maxWeight = Config.TrunkSizes[vehicleClass] or Config.DefaultMaxWeight

    -- Motorkerékpár kizárás
    if vehicleClass == 8 and not Config.AllowMotorcycleTrunk then
        Notify(src, 'Motorkerékpáron nincs csomagtartó!', 'warning')
        return
    end

    -- Nulla kapacitás kizárás
    if maxWeight <= 0 then
        Notify(src, 'Ez a jármű nem rendelkezik csomagtartóval!', 'warning')
        return
    end

    local trunk = LoadTrunk(plate, maxWeight)

    -- Item súlyok frissítése kliensjátéktól kapott itemDefs alapján
    if type(invItemDefs) == 'table' then
        for _, item in ipairs(trunk.items) do
            if invItemDefs[item.name] then
                item.weight = invItemDefs[item.name].weight or item.weight or 0
                item.label  = invItemDefs[item.name].label  or item.label  or item.name
                item.icon   = invItemDefs[item.name].icon   or item.icon   or ''
            end
        end
    end

    SyncTrunk(src, plate)
    TriggerEvent('nxn-trunk:server:opened', src, plate)
    NXN.Trunk.Log(('open: src=%d plate=%s class=%d maxW=%.1f'):format(src, plate, vehicleClass, maxWeight))
end)

-- Trunk bezárás
RegisterNetEvent('nxn-trunk:server:close', function(plate)
    local src = source
    plate = NXN.Trunk.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end
    SaveTrunk(plate)
    TriggerEvent('nxn-trunk:server:closed', src, plate)
    NXN.Trunk.Log(('close: src=%d plate=%s'):format(src, plate))
end)

-- Trunk → Inventory átrakás
RegisterNetEvent('nxn-trunk:server:moveToInventory', function(plate, itemName, count, itemWeight)
    local src = source
    plate = NXN.Trunk.NormalizePlate(plate)
    if not ValidatePlate(plate) or not ValidateCount(count) then return end
    if type(itemName) ~= 'string' or #itemName == 0 then return end

    local trunk = trunkCache[plate]
    if not trunk then
        Notify(src, 'Csomagtartó nem található!', 'danger')
        TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = false, message = 'Trunk nem található', direction = 'toInventory' })
        return
    end

    -- Trunk-ban megvan-e
    local idx, item = FindItem(trunk.items, itemName)
    if not idx or (item.count or 1) < count then
        Notify(src, 'Nincs elég item a csomagtartóban!', 'danger')
        TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = false, message = 'Nincs elég item', direction = 'toInventory' })
        return
    end

    -- Inventory súlyellenorzés és hozzáadás
    if GetResourceState('nxn-inventory') ~= 'started' then
        Notify(src, 'Az inventory rendszer nem elérhető!', 'danger')
        return
    end

    local ok, errmsg = exports['nxn-inventory']:addItem(src, itemName, count)
    if not ok then
        Notify(src, errmsg or 'Nem fér be az inventoryba!', 'danger')
        TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = false, message = errmsg or 'Nem fér be', direction = 'toInventory' })
        return
    end

    -- Trunk-ból eltávolít
    exports['nxn-trunk']:removeFromTrunk(plate, itemName, count)
    exports['nxn-inventory']:syncInventory(src)
    SaveTrunk(plate)
    SyncTrunk(src, plate)

    Notify(src, ('%d x %s az inventoryba került'):format(count, itemName), 'success')
    TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = true, message = 'OK', direction = 'toInventory' })
    TriggerEvent('nxn-trunk:server:itemMoved', src, plate, itemName, count, 'toInventory')
    NXN.Trunk.Log(('moveToInventory: src=%d plate=%s item=%s cnt=%d'):format(src, plate, itemName, count))
end)

-- Inventory → Trunk átrakás
RegisterNetEvent('nxn-trunk:server:moveToTrunk', function(plate, itemName, count, itemWeight)
    local src = source
    plate = NXN.Trunk.NormalizePlate(plate)
    if not ValidatePlate(plate) or not ValidateCount(count) then return end
    if type(itemName) ~= 'string' or #itemName == 0 then return end

    if GetResourceState('nxn-inventory') ~= 'started' then
        Notify(src, 'Az inventory rendszer nem elérhető!', 'danger')
        return
    end

    -- Inventory-ban megvan-e
    if not exports['nxn-inventory']:hasItem(src, itemName, count) then
        Notify(src, 'Nincs nálad ennyi item!', 'danger')
        TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = false, message = 'Nincs elég item az inventoryban', direction = 'toTrunk' })
        return
    end

    local trunk = trunkCache[plate]
    if not trunk then
        Notify(src, 'Csomagtartó nem található!', 'danger')
        TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = false, message = 'Trunk nem található', direction = 'toTrunk' })
        return
    end

    -- Súlyellenorzés
    local weight    = tonumber(itemWeight) or 1.0
    local addWeight = weight * count
    local curWeight = NXN.Trunk.CalcWeight(trunk.items)
    if curWeight + addWeight > trunk.maxWeight then
        Notify(src, ('Csomagtartó tele! (%.1f/%.1f kg)'):format(curWeight, trunk.maxWeight), 'danger')
        TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = false, message = 'Csomagtartó tele', direction = 'toTrunk' })
        return
    end

    -- Inventory-ból eltávolít
    local ok = exports['nxn-inventory']:removeItem(src, itemName, count)
    if not ok then
        Notify(src, 'Nem sikerült az item eltávolítása!', 'danger')
        TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = false, message = 'removeItem hiba', direction = 'toTrunk' })
        return
    end

    -- Trunk-ba teszi
    local ok2, msg2 = exports['nxn-trunk']:addToTrunk(plate, itemName, count, weight)
    if not ok2 then
        -- Rollback: visszaadja az itemet
        exports['nxn-inventory']:addItem(src, itemName, count)
        Notify(src, msg2 or 'Trunk hiba!', 'danger')
        TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = false, message = msg2, direction = 'toTrunk' })
        return
    end

    exports['nxn-inventory']:syncInventory(src)
    SaveTrunk(plate)
    SyncTrunk(src, plate)

    Notify(src, ('%d x %s a csomagtartóba került'):format(count, itemName), 'success')
    TriggerClientEvent('nxn-trunk:client:moveResult', src, { ok = true, message = 'OK', direction = 'toTrunk' })
    TriggerEvent('nxn-trunk:server:itemMoved', src, plate, itemName, count, 'toTrunk')
    NXN.Trunk.Log(('moveToTrunk: src=%d plate=%s item=%s cnt=%d'):format(src, plate, itemName, count))
end)

-- ── Szerver exportok ─────────────────────────────────────────

--- Csomagtartó tartalmának visszaadása
---@param plate string
---@return table|nil
exports('getTrunk', function(plate)
    plate = NXN.Trunk.NormalizePlate(plate)
    if not ValidatePlate(plate) then return nil end
    local trunk = trunkCache[plate]
    if not trunk then return nil end
    -- Shallow copy
    local copy = { items = {}, maxWeight = trunk.maxWeight }
    for i, v in ipairs(trunk.items) do copy.items[i] = v end
    return copy
end)

--- Item hozzáadása csomagtartóhoz
---@param plate    string
---@param itemName string
---@param count    integer
---@param weight   number?  item súlya (kg)
---@return boolean ok
---@return string  errmsg
exports('addToTrunk', function(plate, itemName, count, weight)
    plate = NXN.Trunk.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false, 'Hibás plate' end
    if not ValidateCount(count)  then return false, 'Hibás mennyiség' end

    local trunk = trunkCache[plate]
    if not trunk then return false, 'Trunk nincs betöltve' end

    local itemWeight = tonumber(weight) or 1.0
    local addWeight  = itemWeight * count
    local curWeight  = NXN.Trunk.CalcWeight(trunk.items)

    if curWeight + addWeight > trunk.maxWeight then
        return false, ('Csomagtartó tele: %.1f/%.1f kg'):format(curWeight, trunk.maxWeight)
    end

    local idx, existing = FindItem(trunk.items, itemName)
    if idx then
        trunk.items[idx].count  = (existing.count or 1) + count
        trunk.items[idx].weight = itemWeight
    else
        table.insert(trunk.items, { name = itemName, count = count, weight = itemWeight, label = itemName, icon = '' })
    end

    return true, ''
end)

--- Item eltávolítása
---@param plate    string
---@param itemName string
---@param count    integer
---@return boolean
exports('removeFromTrunk', function(plate, itemName, count)
    plate = NXN.Trunk.NormalizePlate(plate)
    if not ValidatePlate(plate) or not ValidateCount(count) then return false end

    local trunk = trunkCache[plate]
    if not trunk then return false end

    local idx, item = FindItem(trunk.items, itemName)
    if not idx then return false end

    local have = item.count or 1
    if count >= have then
        table.remove(trunk.items, idx)
    else
        trunk.items[idx].count = have - count
    end
    return true
end)

--- Van-e elég item a csomagtartóban
---@param plate    string
---@param itemName string
---@param count    integer
---@return boolean
exports('hasTrunkItem', function(plate, itemName, count)
    plate = NXN.Trunk.NormalizePlate(plate)
    local trunk = trunkCache[plate]
    if not trunk then return false end
    local _, item = FindItem(trunk.items, itemName)
    if not item then return false end
    return (item.count or 1) >= (count or 1)
end)

--- Jelenlegi súly
---@param plate string
---@return number
exports('getTrunkWeight', function(plate)
    plate = NXN.Trunk.NormalizePlate(plate)
    local trunk = trunkCache[plate]
    if not trunk then return 0 end
    return NXN.Trunk.CalcWeight(trunk.items)
end)

--- Csomagtartó kiürítése
---@param plate string
---@return boolean
exports('clearTrunk', function(plate)
    plate = NXN.Trunk.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local trunk = trunkCache[plate]
    if not trunk then return false end
    trunk.items = {}
    SaveTrunk(plate)
    return true
end)

--- Max súly beállítása
---@param plate  string
---@param weight number
---@return boolean
exports('setMaxWeight', function(plate, weight)
    plate = NXN.Trunk.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    local w = tonumber(weight)
    if not w or w < 0 then return false end
    local trunk = trunkCache[plate]
    if not trunk then return false end
    trunk.maxWeight = w
    SaveTrunk(plate)
    return true
end)
