-- ============================================================
--  nxn-cartheft | server.lua
-- ============================================================

-- ── Állapot ────────────────────────────────────────────────
-- { [plate] = true }  – jelenleg feltörés alatt álló járművek
local activeBreakIns = {}
-- { [plate..':'..ident] = count }
local attemptCounts  = {}
-- { [src..':'..plate] = timestamp }  – cooldown
local cooldowns      = {}

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

local function GetAttemptKey(plate, ident) return plate .. ':' .. ident end
local function GetCooldownKey(src, plate)  return tostring(src) .. ':' .. plate end

-- ── DB init ────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.CarTheft.Info('nxn-cartheft elindul...')
    if not Config.LogAttempts then return end
    CreateThread(function()
        if GetResourceState('nxn-database') ~= 'started' then
            NXN.CarTheft.Warn('nxn-database nem fut – tábla nem hozható létre')
            return
        end
        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_cartheft_log',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_cartheft_log` (
                    `id`          INT AUTO_INCREMENT PRIMARY KEY,
                    `identifier`  VARCHAR(100) NOT NULL,
                    `plate`       VARCHAR(20)  NOT NULL,
                    `success`     TINYINT(1)   DEFAULT 0,
                    `coords`      VARCHAR(100),
                    `created_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })
        NXN.CarTheft.Info('nxn_cartheft_log tábla regisztrálva.')
    end)
end)

-- ── Szerver exportok ───────────────────────────────────────

---@param plate string
---@return boolean
exports('isBeingBrokenInto', function(plate)
    plate = NXN.CarTheft.NormalizePlate(plate)
    return activeBreakIns[plate] == true
end)

---@param plate      string
---@param identifier string
---@return integer
exports('getAttemptCount', function(plate, identifier)
    plate = NXN.CarTheft.NormalizePlate(plate)
    return attemptCounts[GetAttemptKey(plate, identifier)] or 0
end)

---@param plate string
---@return boolean
exports('lockVehicleAgain', function(plate)
    plate = NXN.CarTheft.NormalizePlate(plate)
    if not ValidatePlate(plate) then return false end
    -- Keresés: melyik online játékos közelében van ez a rendszám?
    -- Szerver oldalon entity keresés NetworkId nélkül nehézkes;
    -- ezért kliensre delegálunk egy eventtel
    TriggerClientEvent('nxn-cartheft:client:forceLock', -1, { plate = plate })
    NXN.CarTheft.Info(('lockVehicleAgain: plate=%s'):format(plate))
    return true
end)

-- ── Net eventek ────────────────────────────────────────────

-- Feltörési kísérlet indítása
RegisterNetEvent('nxn-cartheft:server:startAttempt', function(plate, vehicleNetId)
    local src   = source
    plate = NXN.CarTheft.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end

    local ident = GetIdentifier(src)

    -- Cooldown ellenőrzés
    local cdKey = GetCooldownKey(src, plate)
    if cooldowns[cdKey] then
        local remaining = math.ceil(Config.AttemptCooldown - (os.time() - cooldowns[cdKey]))
        if remaining > 0 then
            TriggerClientEvent('nxn-cartheft:client:attemptAllowed', src, {
                ok     = false,
                reason = ('Várj még %d másodpercet!'):format(remaining)
            })
            return
        end
        cooldowns[cdKey] = nil
    end

    -- Ha van kulcsa → nem kell feltörni
    if GetResourceState('nxn-keys') == 'started' then
        if exports['nxn-keys']:hasKey(src, plate) then
            TriggerClientEvent('nxn-cartheft:client:attemptAllowed', src,
                { ok = false, reason = 'Van kulcsod ehhez a járműhöz!' })
            return
        end
    end

    -- Ha tulajdonos → saját autót nem tör fel
    if GetResourceState('nxn-vehicles') == 'started' then
        if exports['nxn-vehicles']:isOwner(src, plate) then
            TriggerClientEvent('nxn-cartheft:client:attemptAllowed', src,
                { ok = false, reason = 'Ez a te járműved!' })
            return
        end
    end

    -- Már folyamatban van-e feltörés
    if activeBreakIns[plate] then
        TriggerClientEvent('nxn-cartheft:client:attemptAllowed', src,
            { ok = false, reason = 'Ezt a járművet már feltörik!' })
        return
    end

    -- Max kísérlet limit
    if Config.MaxAttemptsPerVehicle > 0 then
        local count = attemptCounts[GetAttemptKey(plate, ident)] or 0
        if count >= Config.MaxAttemptsPerVehicle then
            TriggerClientEvent('nxn-cartheft:client:attemptAllowed', src,
                { ok = false, reason = 'Elérted a maximális kísérletszámot ennél a járműnél!' })
            return
        end
    end

    -- Közelség re-ellenőrzés (entity coords)
    local vehicleEntity = NetworkGetEntityFromNetworkId(tonumber(vehicleNetId) or 0)
    if DoesEntityExist(vehicleEntity) then
        local srcPed = GetPlayerPed(src)
        local px, py, pz = GetEntityCoords(srcPed)
        local vx, vy, vz = GetEntityCoords(vehicleEntity)
        local dist = #(vector3(px, py, pz) - vector3(vx, vy, vz))
        if dist > (Config.InteractDistance * 2 + 3.0) then
            TriggerClientEvent('nxn-cartheft:client:attemptAllowed', src,
                { ok = false, reason = 'Túl messze vagy a járműtől!' })
            return
        end
    end

    -- Zöld út
    activeBreakIns[plate] = true
    NXN.CarTheft.Log(('startAttempt: src=%d plate=%s ident=%s'):format(src, plate, ident))
    TriggerClientEvent('nxn-cartheft:client:attemptAllowed', src, { ok = true })
end)

-- Kísérlet eredménye
RegisterNetEvent('nxn-cartheft:server:attemptResult', function(plate, success, vehicleNetId)
    local src   = source
    plate = NXN.CarTheft.NormalizePlate(plate)
    if not ValidatePlate(plate) then return end

    local ident  = GetIdentifier(src)
    local akey   = GetAttemptKey(plate, ident)
    activeBreakIns[plate] = nil

    -- Kísérletszám növelés
    attemptCounts[akey] = (attemptCounts[akey] or 0) + 1

    -- Coords loghoz
    local coordStr = ''
    local srcPed   = GetPlayerPed(src)
    if srcPed and srcPed ~= 0 then
        local cx, cy, cz = GetEntityCoords(srcPed)
        coordStr = ('%.1f,%.1f,%.1f'):format(cx, cy, cz)
    end

    if success then
        -- Jármű kinyitása
        local vehicleEntity = NetworkGetEntityFromNetworkId(tonumber(vehicleNetId) or 0)
        if DoesEntityExist(vehicleEntity) then
            if GetResourceState('nxn-engine') == 'started' then
                -- setLocked az nxn-engine kliens export – server oldali hívás
                -- A szerver csak a kliensnek küldi az utasítást a saját járművére
                -- (a setLocked szerver oldalon nincs, ezért kliensre delegálunk)
                TriggerClientEvent('nxn-cartheft:client:doUnlock', src, {
                    vehicleNetId = vehicleNetId,
                    plate        = plate,
                })
            else
                -- Natív fallback
                SetVehicleDoorsLocked(vehicleEntity, 1)
            end
        end

        -- Police alert
        if math.random() < Config.PoliceAlertChance then
            TriggerEvent('nxn-cartheft:server:policeAlert', src, plate, coordStr, true)
        end

        TriggerEvent('nxn-cartheft:server:vehicleBreached', src, plate)
        NXN.CarTheft.Info(('vehicleBreached: src=%d plate=%s'):format(src, plate))
    else
        -- Cooldown indítása
        cooldowns[GetCooldownKey(src, plate)] = os.time()

        -- Police alert (kisebb eséllyel)
        if math.random() < Config.PoliceAlertOnFail then
            TriggerEvent('nxn-cartheft:server:policeAlert', src, plate, coordStr, false)
        end
    end

    -- DB logolás
    if Config.LogAttempts and GetResourceState('nxn-database') == 'started' then
        MySQL.insert(
            'INSERT INTO `nxn_cartheft_log` (identifier, plate, success, coords) VALUES (?, ?, ?, ?)',
            { ident, plate, success and 1 or 0, coordStr }
        )
    end

    -- Globális event (nxn-police / nxn-mdt figyelhet rá)
    TriggerEvent('nxn-cartheft:server:attemptLogged', src, plate, success, coordStr)
    NXN.CarTheft.Log(('attemptResult: src=%d plate=%s success=%s'):format(src, plate, tostring(success)))
end)

-- Police alert handler (ha nxn-police fut)
AddEventHandler('nxn-cartheft:server:policeAlert', function(src, plate, coordStr, success)
    if GetResourceState('nxn-police') ~= 'started' then return end
    local msg = success
        and ('Járműfeltörés észlelve – rendszám: ' .. plate)
        or  ('Sikertelen járműfeltörési kísérlet – rendszám: ' .. plate)
    TriggerClientEvent('nxn-police:client:alert', -1, {
        type    = 'cartheft',
        message = msg,
        coords  = coordStr,
    })
end)
