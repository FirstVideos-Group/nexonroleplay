-- ============================================================
--  nxn-garage | server.lua
-- ============================================================

-- Runtime garázsok (config + registerGarage által hozzáadottak)
local runtimeGarages = {}

-- Spawn cooldown: { [src] = lastSpawnTime (ms) }
local spawnCooldowns = {}

-- ── Segédfüggvények ─────────────────────────────────────────

local function NotifyPlayer(src, msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    local t = ntype or 'info'
    if     t == 'success' then TriggerClientEvent('nxn-notify:client:success', src, msg)
    elseif t == 'danger'  then TriggerClientEvent('nxn-notify:client:danger',  src, msg)
    elseif t == 'warning' then TriggerClientEvent('nxn-notify:client:warning', src, msg)
    else                       TriggerClientEvent('nxn-notify:client:info',    src, msg)
    end
end

local function GetIdentifier(src)
    -- nxn-database getIdentifier export először, fallback: nxn-identity
    if GetResourceState('nxn-database') == 'started' then
        local id = exports['nxn-database']:getIdentifier(src)
        if id then return id end
    end
    if GetResourceState('nxn-identity') == 'started' then
        return exports['nxn-identity']:getIdentifier(src)
    end
    return nil
end

--- Garázs konfig lekérése (config + runtime)
---@param garageId string
---@return table|nil
local function FindGarage(garageId)
    -- Config.Garages
    for _, g in ipairs(Config.Garages) do
        if g.id == garageId then return g end
    end
    -- Runtime
    return runtimeGarages[garageId]
end

-- ── Resource start ─────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.Garage.Info('nxn-garage elindul...')
    NXN.Garage.Info('nxn-garage kész.')
end)

-- ── Net eventek ──────────────────────────────────────────────

--- Járműlista lekérése az NUI-nak
RegisterNetEvent('nxn-garage:server:getVehicles', function(garageId)
    local src = source
    local garage = FindGarage(garageId)
    if not garage then
        TriggerClientEvent('nxn-garage:client:vehicleList', src, { vehicles = {}, garageLabel = '', error = 'Ismeretlen garázs.' })
        return
    end

    local identifier = GetIdentifier(src)
    if not identifier then
        TriggerClientEvent('nxn-garage:client:vehicleList', src, { vehicles = {}, garageLabel = garage.label, error = 'Azonosító nem található.' })
        return
    end

    local vehicles = exports['nxn-vehicles']:getVehicles(identifier)

    -- Motor HP hozzáadása minden járműhöz
    for _, v in ipairs(vehicles) do
        v.engineHP = exports['nxn-vehicles']:getEngineHP(v.plate)
    end

    NXN.Garage.Log(('getVehicles: src=%d garage=%s vehicles=%d'):format(src, garageId, #vehicles))
    TriggerClientEvent('nxn-garage:client:vehicleList', src, {
        vehicles    = vehicles,
        garageLabel = garage.label,
        garageId    = garageId,
    })
end)

--- Jármű spawn
RegisterNetEvent('nxn-garage:server:spawn', function(plate, garageId)
    local src = source
    plate = NXN.Garage.NormalizePlate(plate)
    if type(plate) ~= 'string' or #plate == 0 then return end

    -- Spawn cooldown ellenőrzés
    local now = GetGameTimer()
    if spawnCooldowns[src] and (now - spawnCooldowns[src]) < Config.SpawnCooldown then
        NotifyPlayer(src, 'Kérjünk, várj egy kicsit a következő spawn előtt!', 'warning')
        TriggerClientEvent('nxn-garage:client:spawnResult', src, { ok = false, message = 'Cooldown aktív.' })
        return
    end

    -- Garázs létezik-e
    local garage = FindGarage(garageId)
    if not garage then
        TriggerClientEvent('nxn-garage:client:spawnResult', src, { ok = false, message = 'Garázs nem található.' })
        return
    end

    -- Tulajdonos ellenőrzés
    if not exports['nxn-vehicles']:isOwner(src, plate) then
        TriggerClientEvent('nxn-garage:client:spawnResult', src, { ok = false, message = 'Nem a te járműved.' })
        return
    end

    -- Jármű adatok
    local vehicle = exports['nxn-vehicles']:getVehicle(plate)
    if not vehicle then
        TriggerClientEvent('nxn-garage:client:spawnResult', src, { ok = false, message = 'Jármű nem található.' })
        return
    end

    if not vehicle.stored then
        TriggerClientEvent('nxn-garage:client:spawnResult', src, { ok = false, message = 'A jármő már kinn van.' })
        return
    end

    if vehicle.impounded then
        TriggerClientEvent('nxn-garage:client:spawnResult', src, { ok = false, message = 'A jármő le van foglalva.' })
        return
    end

    -- Motor HP lekérés
    local hp = 100.0
    if Config.PersistEngineHP then
        hp = exports['nxn-vehicles']:getEngineHP(plate)
    end

    -- Állapot frissítés
    exports['nxn-vehicles']:setStored(plate, false)

    -- Kulcs adása (nxn-keys)
    if Config.AutoGiveKey and GetResourceState('nxn-keys') == 'started' then
        exports['nxn-keys']:giveKey(src, plate)
        NXN.Garage.Log(('giveKey: src=%d plate=%s'):format(src, plate))
    end

    -- nxn-vehicles:server:spawned event
    TriggerEvent('nxn-vehicles:server:spawned', src, plate, vehicle.model)

    spawnCooldowns[src] = now

    NXN.Garage.Info(('spawn: src=%d plate=%s model=%s garage=%s'):format(src, plate, vehicle.model, garageId))

    TriggerClientEvent('nxn-garage:client:spawnResult', src, {
        ok          = true,
        plate       = plate,
        model       = vehicle.model,
        hp          = hp,
        spawnCoords = { x = garage.spawn.x, y = garage.spawn.y, z = garage.spawn.z, w = garage.spawn.w },
        message     = 'Jármő kivéve.',
    })
end)

--- Jármű despawn (elrakás)
RegisterNetEvent('nxn-garage:server:despawn', function(plate, hp)
    local src = source
    plate = NXN.Garage.NormalizePlate(plate)
    if type(plate) ~= 'string' or #plate == 0 then return end

    -- Tulajdonos ellenőrzés
    if not exports['nxn-vehicles']:isOwner(src, plate) then
        TriggerClientEvent('nxn-garage:client:despawnResult', src, { ok = false, message = 'Nem a te járműved.' })
        return
    end

    -- Motor HP mentés
    if Config.PersistEngineHP then
        local hpVal = tonumber(hp)
        if hpVal then
            exports['nxn-vehicles']:saveEngineHP(plate, hpVal)
        end
    end

    -- Garázsba rakja
    exports['nxn-vehicles']:setStored(plate, true)

    -- Trunk törlése (ha engedélyezve)
    if Config.ClearTrunkOnDespawn and GetResourceState('nxn-trunk') == 'started' then
        exports['nxn-trunk']:clearTrunk(plate)
        NXN.Garage.Log(('clearTrunk: plate=%s'):format(plate))
    end

    -- nxn-vehicles:server:despawned event
    TriggerEvent('nxn-vehicles:server:despawned', src, plate)

    NXN.Garage.Info(('despawn: src=%d plate=%s hp=%s'):format(src, plate, tostring(hp)))

    TriggerClientEvent('nxn-garage:client:despawnResult', src, {
        ok      = true,
        plate   = plate,
        message = 'Jármő elrakva.',
    })
end)

-- ── Szerver exportok ────────────────────────────────────────

--- Garázs konfig lekérése ID alapján
---@param garageId string
---@return table|nil
exports('getGarage', function(garageId)
    return FindGarage(garageId)
end)

--- Összes garázs listája (config + runtime)
---@return table[]
exports('getAllGarages', function()
    local result = {}
    for _, g in ipairs(Config.Garages) do
        table.insert(result, g)
    end
    for _, g in pairs(runtimeGarages) do
        table.insert(result, g)
    end
    return result
end)

--- Runtime garázs regisztrálása
---@param garageId string
---@param cfg      table
---@return boolean
exports('registerGarage', function(garageId, cfg)
    if FindGarage(garageId) then
        NXN.Garage.Warn(('registerGarage: ID már foglalt: %s'):format(garageId))
        return false
    end
    runtimeGarages[garageId] = cfg
    NXN.Garage.Info(('registerGarage: %s'):format(garageId))
    return true
end)

--- Runtime garázs törlése
---@param garageId string
---@return boolean
exports('unregisterGarage', function(garageId)
    if not runtimeGarages[garageId] then return false end
    runtimeGarages[garageId] = nil
    NXN.Garage.Log(('unregisterGarage: %s'):format(garageId))
    return true
end)

--- Jármő spawnolása szerver-exportént (nxn-garage általi API)
---@param src      integer
---@param plate    string
---@param garageId string?
---@return boolean ok
---@return string  message
exports('spawnVehicle', function(src, plate, garageId)
    plate = NXN.Garage.NormalizePlate(plate)
    garageId = garageId or 'main_garage'
    local garage = FindGarage(garageId)
    if not garage then return false, 'Garázs nem található' end
    if not exports['nxn-vehicles']:isOwner(src, plate) then return false, 'Nem a te járműved' end
    local vehicle = exports['nxn-vehicles']:getVehicle(plate)
    if not vehicle then return false, 'Jármű nem található' end
    if not vehicle.stored then return false, 'Jármő már kinn' end
    if vehicle.impounded  then return false, 'Jármő le van foglalva' end
    local hp = Config.PersistEngineHP and exports['nxn-vehicles']:getEngineHP(plate) or 100.0
    exports['nxn-vehicles']:setStored(plate, false)
    if Config.AutoGiveKey and GetResourceState('nxn-keys') == 'started' then
        exports['nxn-keys']:giveKey(src, plate)
    end
    TriggerEvent('nxn-vehicles:server:spawned', src, plate, vehicle.model)
    TriggerClientEvent('nxn-garage:client:spawnResult', src, {
        ok          = true,
        plate       = plate,
        model       = vehicle.model,
        hp          = hp,
        spawnCoords = { x = garage.spawn.x, y = garage.spawn.y, z = garage.spawn.z, w = garage.spawn.w },
        message     = 'Jármő kivéve.',
    })
    return true, 'OK'
end)

--- Jármő despawn szerver-exportént
---@param src   integer
---@param plate string
---@return boolean
exports('despawnVehicle', function(src, plate)
    plate = NXN.Garage.NormalizePlate(plate)
    if not exports['nxn-vehicles']:isOwner(src, plate) then return false end
    local hp = 100.0
    if Config.PersistEngineHP and GetResourceState('nxn-engine') == 'started' then
        -- hp-t a kliens küldi a net eventnél, itt alapértéket használunk
        hp = 100.0
    end
    exports['nxn-vehicles']:setStored(plate, true)
    if Config.ClearTrunkOnDespawn and GetResourceState('nxn-trunk') == 'started' then
        exports['nxn-trunk']:clearTrunk(plate)
    end
    TriggerEvent('nxn-vehicles:server:despawned', src, plate)
    TriggerClientEvent('nxn-garage:client:despawnResult', src, { ok = true, message = 'Jármő elrakva.' })
    return true
end)

-- Cleanup playerDropped
AddEventHandler('playerDropped', function()
    local src = source
    spawnCooldowns[src] = nil
end)
