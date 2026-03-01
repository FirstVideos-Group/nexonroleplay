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

-- #40 – DeductItem: közös segédfüggvény dropItem és deleteItem számára
-- Eltávolít egy itemet a cache-ből (nem menti DB-be), hotbart is tisztítja.
---@return boolean siker
local function DeductItem(src, itemName, count)
    local inv = invCache[src]
    if not inv or not inv.items[itemName] then return false end
    local have = inv.items[itemName].count or 1
    if count >= have then
        inv.items[itemName] = nil
        -- Hotbar tisztítás
        for slot, name in pairs(inv.hotbar or {}) do
            if name == itemName then inv.hotbar[slot] = nil end
        end
    else
        inv.items[itemName].count = have - count
    end
    invCache[src] = inv
    return true
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

-- ── Hálózati események ───────────────────────────────────────────

AddEventHandler('nxn-database:server:playerLoaded', function(src, playerData)
    NXN.Inventory.Log(('playerLoaded: src=%d'):format(src))
    CreateThread(function()
        LoadInventory(src, playerData.identifier)
    end)
end)

-- #42 – playerDropped: CreateThread eltávolítva, MySQL.update.await,
--        cache nil-lése CSAK a mentés után
AddEventHandler('playerDropped', function()
    local src  = source
    local data = invCache[src]
    if not data then return end

    local identifier = GetIdentifier(src)
    if identifier then
        local ok1, itemsJson  = pcall(json.encode, data.items  or {})
        local ok2, hotbarJson = pcall(json.encode, data.hotbar or {})
        MySQL.update.await(
            'UPDATE `' .. Config.InventoryTable .. '` SET items=?, hotbar=? WHERE identifier=?',
            { ok1 and itemsJson or '{}', ok2 and hotbarJson or '{}', identifier }
        )
    end
    invCache[src] = nil
end)

-- Kliens kér szinkronizációt
RegisterNetEvent('nxn-inventory:server:requestSync', function()
    SyncClient(source)
end)

-- Kliens frissíti a hotbart (drag & drop után)
RegisterNetEvent('nxn-inventory:server:updateHotbar', function(hotbar)
    local src = source
    if not invCache[src] then return end
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

    -- HP gyógyítás
    if def.heal and def.heal > 0 then
        TriggerClientEvent('nxn-inventory:client:applyHeal', src, def.heal)
    end

    SyncClient(src)
    TriggerClientEvent('nxn-inventory:client:useResult', src, true, itemName, nil)

    TriggerEvent('nxn-inventory:server:itemUsed', src, itemName, def)
    if def.useAction then
        TriggerEvent(def.useAction, src)
    end

    NXN.Inventory.Log(('useItem DONE: src=%d item=%s'):format(src, itemName))
end)

-- #39 / #40 – dropItem: DeductItem segédfüggvény + szerver visszaigazolás (dropResult)
RegisterNetEvent('nxn-inventory:server:dropItem', function(itemName, count)
    local src   = source
    local count = math.max(1, tonumber(count) or 1)
    NXN.Inventory.Log(('dropItem: src=%d item=%s cnt=%d'):format(src, itemName, count))

    local ok = DeductItem(src, itemName, count)
    if not ok then
        TriggerClientEvent('nxn-inventory:client:dropResult', src, false, itemName)
        return
    end

    SyncClient(src)
    -- #39 – visszaigazolás: kliens csak most kap értesítést
    TriggerClientEvent('nxn-inventory:client:dropResult', src, true, itemName)
    TriggerEvent('nxn-inventory:server:itemDropped', src, itemName, count)
end)

-- #40 – deleteItem: DeductItem segédfüggvény használata (duplikált kód eltávolítva)
RegisterNetEvent('nxn-inventory:server:deleteItem', function(itemName, count)
    local src   = source
    local count = math.max(1, tonumber(count) or 1)
    NXN.Inventory.Log(('deleteItem: src=%d item=%s cnt=%d'):format(src, itemName, count))

    if not DeductItem(src, itemName, count) then return end
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

--- #43 – getInventory: shallow copy visszaadása belső referencia helyett
---@param src integer
---@return table|nil  { items={}, hotbar={} }
exports('getInventory', function(src)
    NXN.Inventory.Log(('getInventory export: src=%d'):format(src))
    local data = invCache[src]
    if not data then return nil end
    return { items = data.items, hotbar = data.hotbar }
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

--- #41 – addItem: azonnali SaveInventory hívás szerver crash ellen
---@param src integer
---@param itemName string
---@param amount integer
---@return boolean ok
---@return string errmsg
exports('addItem', function(src, itemName, amount)
    local amount = math.max(1, tonumber(amount) or 1)
    local inv    = invCache[src]
    if not inv then return false, 'Inventory nem betöltve' end

    local def = NXN.Inventory.GetItemDef(itemName)
    if not def then return false, ('Ismeretlen item: %s'):format(itemName) end

    local currentWeight = NXN.Inventory.CalcWeight(inv.items)
    local addWeight     = def.weight * amount
    if currentWeight + addWeight > Config.MaxWeight then
        return false, 'Túl nehéz – nincs elég hely'
    end

    if inv.items[itemName] then
        local current = inv.items[itemName].count or 1
        local max     = def.stackable and (def.maxStack or 99) or 1
        if current >= max then
            return false, 'Teljes a kupac'
        end
        inv.items[itemName].count = math.min(current + amount, max)
    else
        inv.items[itemName] = { count = math.min(amount, def.stackable and (def.maxStack or 99) or 1) }
    end

    invCache[src] = inv
    SyncClient(src)
    SaveInventory(src)  -- #41 azonnali mentés
    NXN.Inventory.Log(('addItem: src=%d item=%s cnt=%d'):format(src, itemName, amount))
    return true, ''
end)

--- #41 – removeItem: azonnali SaveInventory hívás szerver crash ellen
---@param src integer
---@param itemName string
---@param amount integer
---@return boolean
exports('removeItem', function(src, itemName, amount)
    local amount = math.max(1, tonumber(amount) or 1)
    if not DeductItem(src, itemName, amount) then return false end
    SyncClient(src)
    SaveInventory(src)  -- #41 azonnali mentés
    NXN.Inventory.Log(('removeItem: src=%d item=%s cnt=%d'):format(src, itemName, amount))
    return true
end)

--- Szinkronizálás kérése más resource-tól
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
