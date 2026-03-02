-- ============================================================
--  nxn-hotwire | server.lua
-- ============================================================

-- ── Állapot ────────────────────────────────────────────────
local activeHotwires = {}   -- { [plate] = true }
local attemptCounts  = {}   -- { [plate..':'..ident] = int }
local cooldowns      = {}   -- { [src..':'..plate] = timestamp }

-- ── Segéd ──────────────────────────────────────────────────

local function Notify(src, msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    exports['nxn-notify']:notify(src, msg, ntype or 'info')
end

local function GetIdentifier(src)
    if GetResourceState('nxn-identity') == 'started' then
        return exports['nxn-identity']:getIdentifier(src)
    end
    if GetResourceState('nxn-database') == 'started' then
        return exports['nxn-database']:getIdentifier(src)
    end
    return 'unknown:' .. tostring(src)
end

local function ValidatePlate(plate)
    return type(plate) == 'string' and #plate > 0 and #plate <= 20
end

local function AttemptKey(plate, ident) return plate .. ':' .. ident end
local function CooldownKey(src, plate)  return tostring(src) .. ':' .. plate end

-- ── DB init ────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.Hotwire.Info('nxn-hotwire elindul...')
    if not Config.LogAttempts then return end
    CreateThread(function()
        if GetResourceState('nxn-database') ~= 'started' then
            NXN.Hotwire.Warn('nxn-database nem fut – tábla nem hozható létre')
            return
        end
        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_hotwire_log',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_hotwire_log` (
                    `id`          INT AUTO_INCREMENT PRIMARY KEY,
                    `identifier`  VARCHAR(100) NOT NULL,
                    `plate`       VARCHAR(20)  NOT NULL,
                    `success`     TINYINT(1)   DEFAULT 0,
                    `minigame`    VARCHAR(20),
                    `coords`      VARCHAR(100),
                    `created_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })
        NXN.Hotwire.Info('nxn_hotwire_log tábla regisztrálva.')
    end)
end)

-- ── Szerver exportok ───────────────────────────────────────

---@param plate string
---@return boolean
exports('isBeingHotwired', function(plate)
    plate = NXN.Hotwire.NormalizePlate(plate)
    return activeHotwires[plate] == true
end)

---@param plate      string
---@param identifier string
---@return integer
exports('getAttemptCount', function(plate, identifier)
    plate = NXN.Hotwire.NormalizePlate(plate)
    return attemptCounts[AttemptKey(plate, identifier)] or 0
end)

-- ── Net eventek ────────────────────────────────────────────

-- Hotwire indítása
RegisterNetEvent('nxn-hotwire:server:startAttempt', function(plate, vehicleNetId)
    local src   = source
    plate = NXN.Hotwire.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end

    local ident = GetIdentifier(src)

    -- Cooldown ellenőrzés
    local cdKey = CooldownKey(src, plate)
    if cooldowns[cdKey] then
        local remaining = math.ceil(Config.AttemptCooldown - (os.time() - cooldowns[cdKey]))
        if remaining > 0 then
            TriggerClientEvent('nxn-hotwire:client:attemptAllowed', src, {
                ok     = false,
                reason = ('Várj még %d másodpercet!'):format(remaining)
            })
            return
        end
        cooldowns[cdKey] = nil
    end

    -- Tulajdonos ellenőrzés
    if GetResourceState('nxn-vehicles') == 'started' then
        if exports['nxn-vehicles']:isOwner(src, plate) then
            TriggerClientEvent('nxn-hotwire:client:attemptAllowed', src,
                { ok = false, reason = 'Ez a te járműved – használd a kulcsodat!' })
            return
        end
    end

    -- Kulcs ellenőrzés
    if GetResourceState('nxn-keys') == 'started' then
        if exports['nxn-keys']:hasKey(src, plate) then
            TriggerClientEvent('nxn-hotwire:client:attemptAllowed', src,
                { ok = false, reason = 'Van kulcsod ehhez a járműhöz!' })
            return
        end
    end

    -- Konkurens hotwire ellenőrzés
    if activeHotwires[plate] then
        TriggerClientEvent('nxn-hotwire:client:attemptAllowed', src,
            { ok = false, reason = 'Ezt a járművet már hotwire-olják!' })
        return
    end

    -- Max kísérlet
    if Config.MaxAttemptsPerVehicle > 0 then
        local count = attemptCounts[AttemptKey(plate, ident)] or 0
        if count >= Config.MaxAttemptsPerVehicle then
            TriggerClientEvent('nxn-hotwire:client:attemptAllowed', src,
                { ok = false, reason = 'Elérted a maximális kísérletszámot!' })
            return
        end
    end

    -- Közelség re-ellenőrzés
    local vehicleEntity = NetworkGetEntityFromNetworkId(tonumber(vehicleNetId) or 0)
    if DoesEntityExist(vehicleEntity) then
        local srcPed = GetPlayerPed(src)
        local px, py, pz = GetEntityCoords(srcPed)
        local vx, vy, vz = GetEntityCoords(vehicleEntity)
        if #(vector3(px, py, pz) - vector3(vx, vy, vz)) > 10.0 then
            TriggerClientEvent('nxn-hotwire:client:attemptAllowed', src,
                { ok = false, reason = 'Nem vagy a járműben!' })
            return
        end
    end

    -- Zöld út
    activeHotwires[plate] = true
    NXN.Hotwire.Log(('startAttempt: src=%d plate=%s'):format(src, plate))

    -- Minijáték típusát küldjük
    local mgType = Config.DefaultMinigame
    if mgType == 'random' then
        mgType = math.random(2) == 1 and 'wirechoice' or 'sequence'
    end

    TriggerClientEvent('nxn-hotwire:client:attemptAllowed', src, {
        ok       = true,
        minigame = mgType,
    })
end)

-- Kísérlet eredménye
RegisterNetEvent('nxn-hotwire:server:attemptResult', function(plate, success, vehicleNetId, minigame)
    local src   = source
    plate = NXN.Hotwire.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end

    local ident  = GetIdentifier(src)
    local akey   = AttemptKey(plate, ident)
    activeHotwires[plate] = nil
    attemptCounts[akey]   = (attemptCounts[akey] or 0) + 1

    -- Coords loghoz
    local coordStr = ''
    local srcPed   = GetPlayerPed(src)
    if srcPed and srcPed ~= 0 then
        local cx, cy, cz = GetEntityCoords(srcPed)
        coordStr = ('%.1f,%.1f,%.1f'):format(cx, cy, cz)
    end

    local vehicleEntity = NetworkGetEntityFromNetworkId(tonumber(vehicleNetId) or 0)

    if success then
        -- Motor indítása (auth bypass)
        local started = false
        if DoesEntityExist(vehicleEntity) and GetResourceState('nxn-engine') == 'started' then
            local ok = exports['nxn-engine']:hotwireStart(vehicleEntity)
            if not ok then
                -- Motor túll sérült
                activeHotwires[plate] = nil
                TriggerClientEvent('nxn-hotwire:client:hotwireFailed', src, {
                    plate         = plate,
                    reason        = 'A motor túll súlyosan sérült!',
                    damageApplied = false,
                    cooldown      = Config.AttemptCooldown,
                })
                cooldowns[CooldownKey(src, plate)] = os.time()
                return
            end
            started = true
        end

        -- Police alert
        if math.random() < Config.PoliceAlertChance then
            TriggerEvent('nxn-hotwire:server:policeAlert', src, plate, coordStr, true)
        end

        TriggerEvent('nxn-hotwire:server:vehicleHotwired', src, plate)
        TriggerClientEvent('nxn-hotwire:client:hotwireSuccess', src, { plate = plate })
        NXN.Hotwire.Info(('vehicleHotwired: src=%d plate=%s'):format(src, plate))
    else
        -- Motor kár
        local damageApplied = false
        if Config.DamageOnFail and DoesEntityExist(vehicleEntity) then
            if GetResourceState('nxn-engine') == 'started' then
                exports['nxn-engine']:applyDamage(vehicleEntity, Config.FailDamageAmount)
                damageApplied = true
            end
        end

        cooldowns[CooldownKey(src, plate)] = os.time()

        -- Police alert
        if math.random() < Config.PoliceAlertOnFail then
            TriggerEvent('nxn-hotwire:server:policeAlert', src, plate, coordStr, false)
        end

        TriggerClientEvent('nxn-hotwire:client:hotwireFailed', src, {
            plate         = plate,
            cooldown      = Config.AttemptCooldown,
            damageApplied = damageApplied,
        })
    end

    -- DB log
    if Config.LogAttempts and GetResourceState('nxn-database') == 'started' then
        MySQL.insert(
            'INSERT INTO `nxn_hotwire_log` (identifier, plate, success, minigame, coords) VALUES (?, ?, ?, ?, ?)',
            { ident, plate, success and 1 or 0, minigame or 'unknown', coordStr }
        )
    end

    -- Globális event
    TriggerEvent('nxn-hotwire:server:attemptLogged', src, plate, success, coordStr)
    NXN.Hotwire.Log(('attemptResult: src=%d plate=%s success=%s'):format(src, plate, tostring(success)))
end)

-- Police alert handler
AddEventHandler('nxn-hotwire:server:policeAlert', function(src, plate, coordStr, success)
    if GetResourceState('nxn-police') ~= 'started' then return end
    local msg = success
        and ('Jármű beindítás kulcs nélkül – rendszám: ' .. plate)
        or  ('Sikertelen hotwire kísérlet – rendszám: ' .. plate)
    TriggerClientEvent('nxn-police:client:alert', -1, {
        type     = 'hotwire',
        message  = msg,
        coords   = coordStr,
        priority = success and 'high' or 'medium',
    })
end)
