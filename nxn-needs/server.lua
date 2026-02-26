-- ============================================================
--  nxn-needs | server.lua
-- ============================================================

-- ── Belső cache ──────────────────────────────────────────────
--- { [src] = { hunger=N, thirst=N, stress=N, fatigue=N } }
local needsCache = {}

-- ── Segédfüggvények ──────────────────────────────────────────

--- Identifier lekérése az nxn-database exporton keresztül
---@param src number
---@return string|nil
local function GetIdentifier(src)
    local id = exports['nxn-database']:getIdentifier(src)
    if not id then
        NXN.Needs.Warn(('GetIdentifier: nxn-database nem adott vissza identifier-t src=%d'):format(src))
    end
    return id
end

--- Alapértelmezett needs tábla generálása Config alapján
---@return table
local function DefaultNeeds()
    local t = {}
    for need, cfg in pairs(Config.Needs) do
        t[need] = cfg.default
    end
    return t
end

--- Needs cache-t küld a kliensnek
---@param src number
local function SyncClient(src)
    local data = needsCache[src]
    if not data then return end
    NXN.Needs.Log(('SyncClient: src=%d küldve'):format(src))
    TriggerClientEvent('nxn-needs:client:sync', src, data)
end

-- ── Tábla regisztráció nxn-database-n keresztül ──────────────

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

-- ── Betöltés / mentés ────────────────────────────────────────

---@param src number
---@param identifier string
local function LoadNeeds(src, identifier)
    NXN.Needs.Log(('LoadNeeds: src=%d ident=%s'):format(src, identifier))

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
        -- Első alkalommal: defaults alapján
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

---@param src number
local function SaveNeeds(src)
    local data = needsCache[src]
    if not data then
        NXN.Needs.Warn(('SaveNeeds: nincs cache adat src=%d'):format(src))
        return
    end
    local identifier = GetIdentifier(src)
    if not identifier then return end

    MySQL.update(
        'UPDATE `' .. Config.NeedsTable .. '` SET `hunger`=?, `thirst`=?, `stress`=?, `fatigue`=? WHERE `identifier`=?',
        { data.hunger, data.thirst, data.stress, data.fatigue, identifier }
    )
    NXN.Needs.Log(('SaveNeeds: elmentve src=%d'):format(src))
end

---@param src number
local function SaveAndClearNeeds(src)
    SaveNeeds(src)
    needsCache[src] = nil
end

-- ── Eseménykezelők (nxn-database kapcsolat) ──────────────────

--- Amikor az nxn-database betöltötte a játékost, mi is betöltjük a needs-t
AddEventHandler('nxn-database:server:playerLoaded', function(src, playerData)
    NXN.Needs.Log(('playerLoaded event fogadva: src=%d ident=%s'):format(src, playerData.identifier))
    CreateThread(function()
        LoadNeeds(src, playerData.identifier)
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    NXN.Needs.Log(('playerDropped: src=%d – needs mentése'):format(src))
    CreateThread(function()
        SaveAndClearNeeds(src)
    end)
end)

-- ── nxn-inventory itemUsed esemény figyelése ─────────────────
-- Az nxn-inventory server.lua a 'nxn-inventory:server:itemUsed' eventet
-- triggereli minden item használat után (src, itemName, def).
-- Ha a def.needs mező ki van töltve, az nxn-inventory már elvégezte
-- a modifyNeed hívást. Ez az eseménykezelő csak logolásra / kiterjesztésre
-- való, hogy az nxn-needs is tudjon róla.

AddEventHandler('nxn-inventory:server:itemUsed', function(src, itemName, def)
    if not def then return end
    if def.needs and next(def.needs) then
        NXN.Needs.Log(('itemUsed event: src=%d item=%s needs alkalmazva az inventory oldalon'):format(src, itemName))
    end
end)

-- ── Auto-decay (szükségletek automatikus változása) ───────────

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

-- ── Periódikus DB-mentés ──────────────────────────────────────

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

-- ── Damage-on-empty (szerver oldali HP csökkentés) ───────────

if Config.DamageOnEmpty and Config.DamageOnEmpty.enabled then
    CreateThread(function()
        while true do
            Wait(Config.DamageOnEmpty.interval * 1000)
            for src, data in pairs(needsCache) do
                local shouldDamage = false
                if Config.DamageOnEmpty.hunger and data.hunger <= 0 then shouldDamage = true end
                if Config.DamageOnEmpty.thirst and data.thirst <= 0 then shouldDamage = true end
                if shouldDamage then
                    TriggerClientEvent('nxn-needs:client:applyDamage', src, Config.DamageOnEmpty.amount)
                    NXN.Needs.Log(('DamageOnEmpty: src=%d damage küldve'):format(src))
                end
            end
        end
    end)
end

-- ── Net events ────────────────────────────────────────────────

--- Kliens kér szinkronizációt (pl. első spawn után)
RegisterNetEvent('nxn-needs:server:requestSync', function()
    local src = source
    NXN.Needs.Log(('requestSync: src=%d'):format(src))
    SyncClient(src)
end)

-- ── Resource start ───────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= Config.ResourceName then return end
    NXN.Needs.Info('nxn-needs elindult, tábla regisztrálása...')
    CreateThread(function()
        RegisterNeedsTable()
        NXN.Needs.Info('nxn-needs kész.')
    end)
end)

-- ── Exportok ─────────────────────────────────────────────────

--- Visszaadja egy játékos összes szükségletét (cache)
---@param src number
---@return table|nil
exports('getNeeds', function(src)
    local data = needsCache[src]
    NXN.Needs.Log(('getNeeds export: src=%d found=%s'):format(src, tostring(data ~= nil)))
    return data
end)

--- Visszaad egy konkrét szükséglet értéket
---@param src number
---@param need string  'hunger'|'thirst'|'stress'|'fatigue'
---@return number|nil
exports('getNeed', function(src, need)
    local data = needsCache[src]
    if not data then return nil end
    return data[need]
end)

--- Beállít egy szükséglet értéket (clamp-el, szinkronizál)
---@param src number
---@param need string
---@param value number
---@return boolean
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

--- Módosít egy szükséglet értéket relatívan (+ vagy -)
---@param src number
---@param need string
---@param amount number
---@return boolean
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

--- Visszaállítja az összes szükségletet alapértelmezett értékre
---@param src number
---@return boolean
exports('resetNeeds', function(src)
    local identifier = GetIdentifier(src)
    if not identifier then return false end
    needsCache[src] = DefaultNeeds()
    SyncClient(src)
    SaveNeeds(src)
    NXN.Needs.Log(('resetNeeds: src=%d visszaállítva'):format(src))
    return true
end)

--- Azonnali DB-mentés egy játékoshoz
---@param src number
exports('saveNeeds', function(src)
    SaveNeeds(src)
end)
