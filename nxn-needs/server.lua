-- ============================================================
--  nxn-needs | server.lua
-- ============================================================

-- ── Belső cache ─────────────────────────────────────────────
--- { [src] = { hunger=N, thirst=N, stress=N, fatigue=N } }
local needsCache = {}

-- #78: session version token – reconnect race condition védelme
-- playerDropped async thread csak akkor törli a cache-t, ha közben
-- nem történt új playerLoaded (reconnect) az ugyanolyan src-re
local sessionVersion = {}

-- ── Segédfüggvények ──────────────────────────────────────────

---@param src number
---@return string|nil
local function GetIdentifier(src)
    local id = exports['nxn-database']:getIdentifier(src)
    if not id then
        NXN.Needs.Warn(('GetIdentifier: nxn-database nem adott vissza identifier-t src=%d'):format(src))
    end
    return id
end

---@return table
local function DefaultNeeds()
    local t = {}
    for need, cfg in pairs(Config.Needs) do
        t[need] = cfg.default
    end
    return t
end

---@param src number
local function SyncClient(src)
    local data = needsCache[src]
    if not data then return end
    NXN.Needs.Log(('SyncClient: src=%d küldve'):format(src))
    TriggerClientEvent('nxn-needs:client:sync', src, data)
end

-- #82: GetItemEffects áthelyezve ide (server.lua) a shared.lua-ból
-- – kizárólag szerver kontextusban fut, nincs többé felesleges
-- kliens oldali pcall overhead sem potenciális félrevezetés
---@param itemName string
---@return table
local function GetItemEffects(itemName)
    local effects = {}
    local invOk, invConfig = pcall(function()
        return exports['nxn-inventory']:getItemDef(itemName)
    end)
    if invOk and invConfig and invConfig.needs then
        for need, val in pairs(invConfig.needs) do
            effects[need] = val
        end
    end
    if Config.ItemOverrides and Config.ItemOverrides[itemName] then
        for need, val in pairs(Config.ItemOverrides[itemName]) do
            effects[need] = val
        end
    end
    return effects
end

-- ── Tábla regisztráció ─────────────────────────────────────────

local function RegisterNeedsTable()
    NXN.Needs.Info('nxn_needs tábla regisztrálása az nxn-database-n keresztül...')
    local ok = exports['nxn-database']:registerTable(Config.ResourceName, {
        name = Config.NeedsTable,
        sql  = [[
            CREATE TABLE IF NOT EXISTS `nxn_needs` (
                `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `identifier` VARCHAR(60)  NOT NULL UNIQUE,
                `hunger`     FLOAT        NOT NULL DEFAULT 100,
                `thirst`     FLOAT        NOT NULL DEFAULT 100,
                `stress`     FLOAT        NOT NULL DEFAULT 0,
                `fatigue`    FLOAT        NOT NULL DEFAULT 0,
                `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_needs_identifier` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]
    })
    if ok then
        NXN.Needs.Info('nxn_needs tábla OK.')
    else
        NXN.Needs.Error('nxn_needs tábla regisztrálása sikertelen!')
    end
end

-- ── Betöltés / mentés ──────────────────────────────────────────

---@param src number
---@param identifier string
local function LoadNeeds(src, identifier)
    NXN.Needs.Log(('LoadNeeds: src=%d ident=%s'):format(src, identifier))

    -- #78: session verzio növelése minden betöltésnél
    sessionVersion[src] = (sessionVersion[src] or 0) + 1

    local row = MySQL.single.await(
        'SELECT * FROM `' .. Config.NeedsTable .. '` WHERE identifier = ?',
        { identifier }
    )

    if row then
        needsCache[src] = {
            hunger  = row.hunger,
            thirst  = row.thirst,
            stress  = row.stress,
            fatigue = row.fatigue,
        }
        NXN.Needs.Log(('LoadNeeds: betöltve DB-ből src=%d'):format(src))
    else
        local defaults = DefaultNeeds()
        MySQL.insert.await(
            'INSERT INTO `' .. Config.NeedsTable .. '` (`identifier`, `hunger`, `thirst`, `stress`, `fatigue`) VALUES (?, ?, ?, ?, ?)',
            { identifier, defaults.hunger, defaults.thirst, defaults.stress, defaults.fatigue }
        )
        needsCache[src] = defaults
        NXN.Needs.Info(('LoadNeeds: új rekord létrehozva src=%d ident=%s'):format(src, identifier))
    end

    SyncClient(src)
    TriggerEvent('nxn-needs:server:needsLoaded', src, needsCache[src])
end

-- #77: MySQL.update -> MySQL.update.await
-- Disconnect / szerver crash esetén az adatok nem vesznek el
---@param src number
local function SaveNeeds(src)
    local data = needsCache[src]
    if not data then
        NXN.Needs.Warn(('SaveNeeds: nincs cache adat src=%d'):format(src))
        return
    end
    local identifier = GetIdentifier(src)
    if not identifier then return end

    MySQL.update.await(
        'UPDATE `' .. Config.NeedsTable .. '` SET `hunger`=?, `thirst`=?, `stress`=?, `fatigue`=? WHERE `identifier`=?',
        { data.hunger, data.thirst, data.stress, data.fatigue, identifier }
    )
    NXN.Needs.Log(('SaveNeeds: elmentve src=%d'):format(src))
end

-- ── Eseménykezelők ───────────────────────────────────────────────

AddEventHandler('nxn-database:server:playerLoaded', function(src, playerData)
    NXN.Needs.Log(('playerLoaded event fogadva: src=%d ident=%s'):format(src, playerData.identifier))
    CreateThread(function()
        LoadNeeds(src, playerData.identifier)
    end)
end)

-- #78: session token-alapú guard a reconnect race condition ellen
-- Ha a játékos gyorsan reconnect-el, a régi thread nem törli az új session cache-ét
AddEventHandler('playerDropped', function()
    local src    = source
    local ver    = (sessionVersion[src] or 0) + 1
    sessionVersion[src] = ver
    NXN.Needs.Log(('playerDropped: src=%d ver=%d – needs mentése'):format(src, ver))
    CreateThread(function()
        SaveNeeds(src)
        -- Csak töröljük a cache-t, ha közben nem reconnectalt (sessionVersion nem változott)
        if sessionVersion[src] == ver then
            needsCache[src]     = nil
            sessionVersion[src] = nil
            NXN.Needs.Log(('playerDropped: src=%d cache törölve'):format(src))
        else
            NXN.Needs.Log(('playerDropped: src=%d reconnect észlelve, cache megőrizve'):format(src))
        end
    end)
end)

AddEventHandler('nxn-inventory:server:itemUsed', function(src, itemName, def)
    if not def then return end
    if def.needs and next(def.needs) then
        NXN.Needs.Log(('itemUsed event: src=%d item=%s needs alkalmazva az inventory oldalon'):format(src, itemName))
    end
end)

-- ── Auto-decay ────────────────────────────────────────────────

if Config.AutoDecay and Config.AutoDecay.enabled then
    CreateThread(function()
        while true do
            Wait(Config.AutoDecay.interval * 1000)
            for src, data in pairs(needsCache) do
                local changed = false
                for need, rule in pairs(Config.AutoDecay.rates) do
                    if data[need] ~= nil and rule.change ~= 0 then
                        local needCfg = Config.Needs[need]
                        local newVal  = NXN.Needs.Clamp(
                            data[need] + rule.change,
                            needCfg.min,
                            needCfg.max
                        )
                        if newVal ~= data[need] then
                            data[need] = newVal
                            changed = true
                        end
                    end
                end
                if changed then
                    needsCache[src] = data
                    SyncClient(src)
                    NXN.Needs.Log(('AutoDecay: src=%d frissítve'):format(src))
                end
            end
        end
    end)
end

-- ── Periódikus DB-mentés ──────────────────────────────────────────

if Config.SaveInterval and Config.SaveInterval > 0 then
    CreateThread(function()
        while true do
            Wait(Config.SaveInterval * 1000)
            NXN.Needs.Log('Periodikus DB-mentés futtatása...')
            for src, _ in pairs(needsCache) do
                SaveNeeds(src)
            end
        end
    end)
end

-- ── Damage-on-empty ────────────────────────────────────────────

-- #81: Dinamikus Config.Needs iteráció a hardcoded hunger/thirst helyett
-- A szerver operátor bármely need-et beállíthatja damage forrásként

if Config.DamageOnEmpty and Config.DamageOnEmpty.enabled then
    CreateThread(function()
        while true do
            Wait(Config.DamageOnEmpty.interval * 1000)
            for src, data in pairs(needsCache) do
                local shouldDamage = false
                for need, needCfg in pairs(Config.Needs) do
                    if Config.DamageOnEmpty[need] and data[need] ~= nil then
                        if data[need] <= needCfg.min then
                            shouldDamage = true
                        end
                    end
                end
                if shouldDamage then
                    TriggerClientEvent('nxn-needs:client:applyDamage', src, Config.DamageOnEmpty.amount)
                    NXN.Needs.Log(('DamageOnEmpty: src=%d damage küldve'):format(src))
                end
            end
        end
    end)
end

-- ── Net events ──────────────────────────────────────────────────

RegisterNetEvent('nxn-needs:server:requestSync', function()
    local src = source
    NXN.Needs.Log(('requestSync: src=%d'):format(src))
    SyncClient(src)
end)

-- ── Resource start ─────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Config.ResourceName then return end
    NXN.Needs.Info('nxn-needs elindult, tábla regisztrálása...')
    CreateThread(function()
        RegisterNeedsTable()
        NXN.Needs.Info('nxn-needs kész.')
    end)
end)

-- ── Exportok ─────────────────────────────────────────────────

-- #79: shallow copy – külső resource nem tudja közvetlenül módosítani a cache-t
exports('getNeeds', function(src)
    local data = needsCache[src]
    NXN.Needs.Log(('getNeeds export: src=%d found=%s'):format(src, tostring(data ~= nil)))
    if not data then return nil end
    return {
        hunger  = data.hunger,
        thirst  = data.thirst,
        stress  = data.stress,
        fatigue = data.fatigue,
    }
end)

exports('getNeed', function(src, need)
    local data = needsCache[src]
    if not data then return nil end
    return data[need]
end)

exports('setNeed', function(src, need, value)
    local data = needsCache[src]
    if not data then
        NXN.Needs.Warn(('setNeed: nincs cache src=%d'):format(src))
        return false
    end
    local cfg = Config.Needs[need]
    if not cfg then
        NXN.Needs.Warn(('setNeed: ismeretlen szükséglet: %s'):format(tostring(need)))
        return false
    end
    data[need] = NXN.Needs.Clamp(value, cfg.min, cfg.max)
    needsCache[src] = data
    SyncClient(src)
    NXN.Needs.Log(('setNeed: src=%d %s=%s'):format(src, need, tostring(data[need])))
    return true
end)

exports('modifyNeed', function(src, need, amount)
    local data = needsCache[src]
    if not data then
        NXN.Needs.Warn(('modifyNeed: nincs cache src=%d'):format(src))
        return false
    end
    local cfg = Config.Needs[need]
    if not cfg then
        NXN.Needs.Warn(('modifyNeed: ismeretlen szükséglet: %s'):format(tostring(need)))
        return false
    end
    data[need] = NXN.Needs.Clamp(data[need] + amount, cfg.min, cfg.max)
    needsCache[src] = data
    SyncClient(src)
    NXN.Needs.Log(('modifyNeed: src=%d %s += %s (új érték: %s)'):format(src, need, tostring(amount), tostring(data[need])))
    return true
end)

exports('resetNeeds', function(src)
    local identifier = GetIdentifier(src)
    if not identifier then return false end
    needsCache[src] = DefaultNeeds()
    SyncClient(src)
    SaveNeeds(src)
    NXN.Needs.Log(('resetNeeds: src=%d visszaallítva'):format(src))
    return true
end)

exports('saveNeeds', function(src)
    SaveNeeds(src)
end)

-- #82: GetItemEffects elérhető exportként is
exports('getItemEffects', function(itemName)
    return GetItemEffects(itemName)
end)
