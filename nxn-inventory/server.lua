-- ============================================================
--  nxn-inventory | server.lua
-- ============================================================

--- { [src] = { items = {}, hotbar = {} } }
local invCache = {}

-- ── Segédfüggvények ─────────────────────────────────────────────

local function GetIdentifier(src)
    local id = exports['nxn-database']:getIdentifier(src)
    if not id then NXN.Inventory.Warn(('GetIdentifier: nincs ident src=%d'):format(src)) end
    return id
end

local function SyncClient(src)
    local data = invCache[src]
    if not data then return end
    TriggerClientEvent('nxn-inventory:client:sync', src, data)
    NXN.Inventory.Log(('SyncClient: src=%d'):format(src))
end

--- Új üres inventory struktúra
local function EmptyInventory()
    return { items = {}, hotbar = {} }
end

-- ── DB tábla ──────────────────────────────────────────────────

local function RegisterTable()
    NXN.Inventory.Info('nxn_inventories tábla regisztrálása...')
    local ok = exports['nxn-database']:registerTable(Config.ResourceName, {
        name = Config.InventoryTable,
        sql  = [[
            CREATE TABLE IF NOT EXISTS `nxn_inventories` (
                `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `identifier` VARCHAR(60)  NOT NULL UNIQUE,
                `items`      LONGTEXT     NOT NULL DEFAULT '{}',
                `hotbar`     TEXT         NOT NULL DEFAULT '{}',
                `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_inv_ident` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]
    })
    if ok then NXN.Inventory.Info('nxn_inventories tábla OK.')
    else       NXN.Inventory.Error('Tábla regisztrálás sikertelen!') end
end

-- ── Betöltés / mentés ────────────────────────────────────────────

local function LoadInventory(src, identifier)
    NXN.Inventory.Log(('LoadInventory: src=%d ident=%s'):format(src, identifier))

    local row = MySQL.single.await(
        'SELECT items, hotbar FROM `' .. Config.InventoryTable .. '` WHERE identifier = ?',
        { identifier }
    )

    if row then
        local ok1, items  = pcall(json.decode, row.items  or '{}')
        local ok2, hotbar = pcall(json.decode, row.hotbar or '{}')
        invCache[src] = {
            items  = ok1 and items  or {},
            hotbar = ok2 and hotbar or {},
        }
        NXN.Inventory.Log(('Betöltve DB-ből: src=%d'):format(src))
    else
        MySQL.insert.await(
            'INSERT INTO `' .. Config.InventoryTable .. '` (identifier, items, hotbar) VALUES (?, ?, ?)',
            { identifier, '{}', '{}' }
        )
        invCache[src] = EmptyInventory()
        NXN.Inventory.Info(('Új inventory létrehozva: ident=%s'):format(identifier))
    end

    SyncClient(src)
    TriggerEvent('nxn-inventory:server:loaded', src, invCache[src])
end

local function SaveInventory(src)
    local data = invCache[src]
    if not data then
        NXN.Inventory.Warn(('SaveInventory: nincs cache src=%d'):format(src))
        return
    end
    local identifier = GetIdentifier(src)
    if not identifier then return end

    local ok1, itemsJson  = pcall(json.encode, data.items  or {})
    local ok2, hotbarJson = pcall(json.encode, data.hotbar or {})
    if not ok1 then itemsJson  = '{}' end
    if not ok2 then hotbarJson = '{}' end

    MySQL.update(
        'UPDATE `' .. Config.InventoryTable .. '` SET items=?, hotbar=? WHERE identifier=?',
        { itemsJson, hotbarJson, identifier }
    )
    NXN.Inventory.Log(('Elmentve: src=%d'):format(src))
end

-- ── Nétwork események ───────────────────────────────────────────

AddEventHandler('nxn-database:server:playerLoaded', function(src, playerData)
    NXN.Inventory.Log(('playerLoaded: src=%d'):format(src))
    CreateThread(function()
        LoadInventory(src, playerData.identifier)
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    CreateThread(function()
        SaveInventory(src)
        invCache[src] = nil
    end)
end)

-- Kliens kér szinkronizációt
RegisterNetEvent('nxn-inventory:server:requestSync', function()
    SyncClient(source)
end)

-- Kliens frissíti a hotbart (drag & drop után)
RegisterNetEvent('nxn-inventory:server:updateHotbar', function(hotbar)
    local src = source
    if not invCache[src] then return end
    -- Validació: csak létező slotokba mehet
    local clean = {}
    for slot, itemName in pairs(hotbar) do
        local s = tonumber(slot)
        if s and s >= 1 and s <= Config.HotbarSlots and itemName ~= '' then
            clean[tostring(s)] = itemName
        end
    end
    invCache[src].hotbar = clean
    SyncClient(src)
    NXN.Inventory.Log(('updateHotbar: src=%d'):format(src))
end)

-- Használat (kliens kezdeményezi)
RegisterNetEvent('nxn-inventory:server:useItem', function(itemName)
    local src = source
    NXN.Inventory.Log(('useItem: src=%d item=%s'):format(src, itemName))

    local inv = invCache[src]
    if not inv or not inv.items[itemName] then
        TriggerClientEvent('nxn-inventory:client:useResult', src, false, itemName, 'Nincs nálad ilyen tárgy.')
        return
    end

    local def = NXN.Inventory.GetItemDef(itemName)
    if not def or not def.usable then
        TriggerClientEvent('nxn-inventory:client:useResult', src, false, itemName, 'Ez a tárgy nem használható.')
        return
    end

    -- Item csökkentése / eltávolítása
    local slot = inv.items[itemName]
    if (slot.count or 1) > 1 then
        inv.items[itemName].count = slot.count - 1
    else
        inv.items[itemName] = nil
    end
    invCache[src] = inv

    -- nxn-needs integráció
    if def.needs then
        for need, amount in pairs(def.needs) do
            local ok = exports['nxn-needs']:modifyNeed(src, need, amount)
            NXN.Inventory.Log(('useItem needs: src=%d %s+=%d ok=%s'):format(src, need, amount, tostring(ok)))
        end
    end

    -- HP gyógyítás (bandage stb.)
    if def.heal and def.heal > 0 then
        TriggerClientEvent('nxn-inventory:client:applyHeal', src, def.heal)
    end

    -- Szinkronizálás + értesítés
    SyncClient(src)
    TriggerClientEvent('nxn-inventory:client:useResult', src, true, itemName, nil)

    -- Egyedi use event trigger (más resourceok figyelhetik)
    TriggerEvent('nxn-inventory:server:itemUsed', src, itemName, def)
    if def.useAction then
        TriggerEvent(def.useAction, src)
    end

    NXN.Inventory.Log(('useItem DONE: src=%d item=%s'):format(src, itemName))
end)

-- Eldobás
RegisterNetEvent('nxn-inventory:server:dropItem', function(itemName, count)
    local src   = source
    local count = math.max(1, tonumber(count) or 1)
    NXN.Inventory.Log(('dropItem: src=%d item=%s cnt=%d'):format(src, itemName, count))

    local inv = invCache[src]
    if not inv or not inv.items[itemName] then return end

    local slot = inv.items[itemName]
    local have = slot.count or 1
    if count >= have then
        inv.items[itemName] = nil
    else
        inv.items[itemName].count = have - count
    end
    invCache[src] = inv
    SyncClient(src)
    -- Dropped event (más script reaghat rá, pl. ground items)
    TriggerEvent('nxn-inventory:server:itemDropped', src, itemName, count)
end)

-- Törlés
RegisterNetEvent('nxn-inventory:server:deleteItem', function(itemName, count)
    local src   = source
    local count = math.max(1, tonumber(count) or 1)
    NXN.Inventory.Log(('deleteItem: src=%d item=%s cnt=%d'):format(src, itemName, count))

    local inv = invCache[src]
    if not inv or not inv.items[itemName] then return end

    local slot = inv.items[itemName]
    local have = slot.count or 1
    if count >= have then
        inv.items[itemName] = nil
    else
        inv.items[itemName].count = have - count
    end
    invCache[src] = inv
    SyncClient(src)
end)

-- ── Periodikális mentés ──────────────────────────────────────────

if Config.SaveInterval > 0 then
    CreateThread(function()
        while true do
            Wait(Config.SaveInterval * 1000)
            NXN.Inventory.Log('Periodikális DB-mentés...')
            for src, _ in pairs(invCache) do
                SaveInventory(src)
            end
        end
    end)
end

-- ── Resource start ───────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Config.ResourceName then return end
    NXN.Inventory.Info('nxn-inventory elindul...')
    CreateThread(function()
        RegisterTable()
        NXN.Inventory.Info('nxn-inventory kész.')
    end)
end)

-- ── Exportok ───────────────────────────────────────────────

--- Visszaadja egy játékos teljes inventory-ját
---@param src integer
---@return table|nil  { items={}, hotbar={} }
exports('getInventory', function(src)
    NXN.Inventory.Log(('getInventory export: src=%d'):format(src))
    return invCache[src]
end)

--- Visszaadja, van-e egy itemből megadott mennyiség
---@param src integer
---@param itemName string
---@param amount integer  (alap: 1)
---@return boolean
exports('hasItem', function(src, itemName, amount)
    local inv = invCache[src]
    if not inv or not inv.items[itemName] then return false end
    return (inv.items[itemName].count or 1) >= (amount or 1)
end)

--- Item hozzáadása (más resource hívhatja)
---@param src integer
---@param itemName string
---@param amount integer
---@return boolean, string  ok, hibüz
exports('addItem', function(src, itemName, amount)
    local amount = math.max(1, tonumber(amount) or 1)
    local inv    = invCache[src]
    if not inv then return false, 'Inventory nem betöltve' end

    local def = NXN.Inventory.GetItemDef(itemName)
    if not def then return false, ('Ismeretlen item: %s'):format(itemName) end

    -- Súlyellenorzés
    local currentWeight = NXN.Inventory.CalcWeight(inv.items)
    local addWeight     = def.weight * amount
    if currentWeight + addWeight > Config.MaxWeight then
        return false, 'Túl nehéz – nincs elég hely'
    end

    -- Stack vagy új slot
    if inv.items[itemName] then
        local current = inv.items[itemName].count or 1
        local max     = def.stackable and (def.maxStack or 99) or 1
        if current >= max then
            return false, 'Teljes a kupác'
        end
        inv.items[itemName].count = math.min(current + amount, max)
    else
        inv.items[itemName] = { count = math.min(amount, def.stackable and (def.maxStack or 99) or 1) }
    end

    invCache[src] = inv
    SyncClient(src)
    NXN.Inventory.Log(('addItem: src=%d item=%s cnt=%d'):format(src, itemName, amount))
    return true, ''
end)

--- Item eltávolítása
---@param src integer
---@param itemName string
---@param amount integer
---@return boolean
exports('removeItem', function(src, itemName, amount)
    local amount = math.max(1, tonumber(amount) or 1)
    local inv    = invCache[src]
    if not inv or not inv.items[itemName] then return false end

    local have = inv.items[itemName].count or 1
    if amount >= have then
        inv.items[itemName] = nil
    else
        inv.items[itemName].count = have - amount
    end

    -- Hotbar tisztitás ha nincs több
    if not inv.items[itemName] then
        for slot, name in pairs(inv.hotbar) do
            if name == itemName then inv.hotbar[slot] = nil end
        end
    end

    invCache[src] = inv
    SyncClient(src)
    NXN.Inventory.Log(('removeItem: src=%d item=%s cnt=%d'):format(src, itemName, amount))
    return true
end)

--- Item menű az inventoryban (más resource is kérhet frissítést)
---@param src integer
exports('syncInventory', function(src)
    SyncClient(src)
end)

--- Teljes inventory törlése
---@param src integer
exports('clearInventory', function(src)
    if not invCache[src] then return false end
    invCache[src] = EmptyInventory()
    SyncClient(src)
    NXN.Inventory.Log(('clearInventory: src=%d'):format(src))
    return true
end)

--- Közvetlen DB-mentés
---@param src integer
exports('saveInventory', function(src)
    SaveInventory(src)
end)
