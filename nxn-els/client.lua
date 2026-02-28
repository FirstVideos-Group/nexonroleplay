-- ============================================================
--  nxn-els | client.lua
--  Villogási pattern motor, környezeti reflexió,
--  misc fények, billentyűk, szerver-szinkron, export API
-- ============================================================

-- ── Állapot ──────────────────────────────────────────────────

local elsEnabled     = false   -- job VAGY admin alapján
local isAdmin        = false   -- szerveroldalról megerősített admin flag
local currentStage   = 0
local sirenMuted     = false
local indicatorState = 'none'
local lastVehicle    = 0
local currentJob     = ''

local patternActive  = false
local patternName    = nil
local patternThread  = nil

-- ── Admin állapot fogadása ───────────────────────────────────
-- A szerver küldi ezt csatlakozáskor és requestAdminCheck válaszként.

AddEventHandler('nxn-els:client:setAdminState', function(adminState)
    isAdmin    = adminState == true
    -- Admin esetén azonnal kap ELS jogosultságot job-tól függetlenül
    if isAdmin then
        elsEnabled = true
    end
    NXN.ELS.Log(('setAdminState: isAdmin=%s elsEnabled=%s'):format(
        tostring(isAdmin), tostring(elsEnabled)))
end)

-- ── Job jogosultság fogadása ──────────────────────────────────

AddEventHandler('nxn-els:client:setJobPermission', function(job, allowed)
    currentJob = job or ''
    -- Ha admin, a job-állapottól függetlenül engedélyezve marad
    elsEnabled = allowed or isAdmin
    NXN.ELS.Log(('setJobPermission: job=%s jobAllowed=%s isAdmin=%s -> elsEnabled=%s'):format(
        currentJob, tostring(allowed), tostring(isAdmin), tostring(elsEnabled)))
end)

-- ── Admin check kérése indításkor ─────────────────────────────

CreateThread(function()
    Wait(2000)  -- bizőnysági várakozás a szerver-sync után
    TriggerServerEvent('nxn-els:server:requestAdminCheck')
end)

-- ── Misc fények ────────────────────────────────────────────────

---@param vehicle number
---@param miscId number  0..25
---@param state boolean
local function SetMisc(vehicle, miscId, state)
    SetVehicleExtra(vehicle, 100 + miscId, not state)
end

-- ── Pattern motor ──────────────────────────────────────────────

local function ClearAllLights(vehicle)
    for i = 0, 14 do SetVehicleExtra(vehicle, i, true) end
    for i = 0, 25 do SetMisc(vehicle, i, false)        end
end

local function ApplyPatternStep(vehicle, step)
    for extraId, on in pairs(step.extras or {}) do
        SetVehicleExtra(vehicle, extraId, not on)
    end
    for miscId, on in pairs(step.miscs or {}) do
        SetMisc(vehicle, miscId, on)
    end
end

local function StopPattern(vehicle)
    patternActive = false
    patternName   = nil
    if vehicle and vehicle ~= 0 then ClearAllLights(vehicle) end
    NXN.ELS.Log('Pattern leallitva')
end

local function StartPattern(vehicle, name)
    local steps = Config.Patterns[name]
    if not steps or #steps == 0 then
        NXN.ELS.Warn(('Ismeretlen pattern: %s'):format(tostring(name)))
        return
    end
    patternName   = name
    patternActive = true
    if patternThread then return end
    patternThread = CreateThread(function()
        NXN.ELS.Log(('Pattern thread indult: %s'):format(name))
        while patternActive do
            local steps2 = Config.Patterns[patternName]
            if not steps2 then break end
            for _, step in ipairs(steps2) do
                if not patternActive then break end
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if veh == 0 then break end
                ApplyPatternStep(veh, step)
                Wait(step.dur or 100)
            end
        end
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then ClearAllLights(veh) end
        patternThread = nil
        NXN.ELS.Log('Pattern thread leallitva')
    end)
end

-- ── Környezeti fényreflexió ───────────────────────────────────

local envLightActive = false
CreateThread(function()
    while true do
        Wait(Config.EnvLight.tickMs)
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 and patternActive and Config.EnvLight.enabled then
            local anyOn = false
            for i = 1, 4 do
                if IsVehicleExtraTurnedOn(veh, i) then anyOn = true; break end
            end
            SetVehicleLightMultiplier(veh, anyOn and Config.EnvLight.multiplier or 1.0)
            envLightActive = true
        elseif envLightActive then
            local veh2 = GetVehiclePedIsIn(PlayerPedId(), false)
            if veh2 ~= 0 then SetVehicleLightMultiplier(veh2, 1.0) end
            envLightActive = false
        end
    end
end)

-- ── Stage alkalmazása ─────────────────────────────────────────────

local function ApplyStage(vehicle, stage)
    if vehicle == 0 then return end
    local cfg = NXN.ELS.GetStageConfig(vehicle, stage)
    if stage == 0 then
        StopPattern(vehicle)
    else
        if cfg.pattern then StartPattern(vehicle, cfg.pattern)
        else StopPattern(vehicle); ClearAllLights(vehicle) end
    end
    local sirenOn = cfg.sirenActive and not sirenMuted
    SetVehicleSiren(vehicle, sirenOn)
    if sirenOn then
        TriggerServerEvent('nxn-els:server:setSirenSound', NetworkGetNetworkIdFromEntity(vehicle), cfg.sirenTone)
    else
        TriggerServerEvent('nxn-els:server:setSirenSound', NetworkGetNetworkIdFromEntity(vehicle), 0)
    end
    if Config.IntegrateVehicleHud and GetResourceState('nxn-vehicle-hud') == 'started' then
        exports['nxn-vehicle-hud']:setSiren(stage > 0, cfg.label)
    end
    NXN.ELS.Log(('ApplyStage: stage=%d pattern=%s siren=%s admin=%s'):format(
        stage, tostring(cfg.pattern), tostring(sirenOn), tostring(isAdmin)))
end

-- ── Szerver szinkron (más játékosok járművei) ───────────────────

AddEventHandler('nxn-els:client:syncState', function(netId, stage, muted)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end
    if vehicle == GetVehiclePedIsIn(PlayerPedId(), false) then return end
    local cfg = NXN.ELS.GetStageConfig(vehicle, stage)
    ClearAllLights(vehicle)
    if stage > 0 and cfg.pattern then
        local steps = Config.Patterns[cfg.pattern]
        if steps and steps[1] then ApplyPatternStep(vehicle, steps[1]) end
    end
    if Config.EnvLight.enabled then
        SetVehicleLightMultiplier(vehicle, stage > 0 and Config.EnvLight.multiplier or 1.0)
    end
    SetVehicleSiren(vehicle, cfg.sirenActive and not muted)
end)

-- ── Irányjelzők ──────────────────────────────────────────────

local function SetIndicators(mode)
    indicatorState = mode
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    SetVehicleIndicatorLights(vehicle, 1, mode == 'left'  or mode == 'hazard')
    SetVehicleIndicatorLights(vehicle, 0, mode == 'right' or mode == 'hazard')
end

-- ── Billentyűkötések ───────────────────────────────────────────

CreateThread(function()
    RegisterKeyMapping('+nxnElsCycleStage',  'ELS Fokozat váltás',  'keyboard', Config.Keys.cycleStage)
    RegisterKeyMapping('+nxnElsToggleSiren', 'ELS Sziréna mute',    'keyboard', Config.Keys.toggleSiren)
    RegisterKeyMapping('+nxnElsIndicatorL',  'ELS Bal irányjelző',  'keyboard', Config.Keys.indicatorL)
    RegisterKeyMapping('+nxnElsIndicatorR',  'ELS Jobb irányjelző', 'keyboard', Config.Keys.indicatorR)
    RegisterKeyMapping('+nxnElsHazard',      'ELS Vészvillogó',     'keyboard', Config.Keys.hazard)

    RegisterCommand('+nxnElsCycleStage', function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 then return end
        if not elsEnabled then
            NXN.ELS.Warn('ELS: nincs jogosultsagod! (job vagy admin szukseges)')
            return
        end
        -- Admin bypass: jármű whitelist-et átugorja
        if not isAdmin and not NXN.ELS.IsVehicleAllowed(vehicle) then
            NXN.ELS.Warn('ELS: ez a jarmu nem ELS-kompatibilis!')
            return
        end
        currentStage = (currentStage + 1) % 4
        sirenMuted   = false
        ApplyStage(vehicle, currentStage)
        TriggerServerEvent('nxn-els:server:updateState',
            NetworkGetNetworkIdFromEntity(vehicle), currentStage, sirenMuted)
    end, false)
    RegisterCommand('-nxnElsCycleStage', function() end, false)

    RegisterCommand('+nxnElsToggleSiren', function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 or currentStage < 2 then return end
        sirenMuted = not sirenMuted
        ApplyStage(vehicle, currentStage)
        TriggerServerEvent('nxn-els:server:updateState',
            NetworkGetNetworkIdFromEntity(vehicle), currentStage, sirenMuted)
    end, false)
    RegisterCommand('-nxnElsToggleSiren', function() end, false)

    RegisterCommand('+nxnElsIndicatorL', function()
        if indicatorState == 'left' then SetIndicators('none')
        else SetIndicators('left') end
    end, false)
    RegisterCommand('-nxnElsIndicatorL', function() end, false)

    RegisterCommand('+nxnElsIndicatorR', function()
        if indicatorState == 'right' then SetIndicators('none')
        else SetIndicators('right') end
    end, false)
    RegisterCommand('-nxnElsIndicatorR', function() end, false)

    RegisterCommand('+nxnElsHazard', function()
        if indicatorState == 'hazard' then SetIndicators('none')
        else SetIndicators('hazard') end
    end, false)
    RegisterCommand('-nxnElsHazard', function() end, false)
end)

-- ── Kiszállás: reset ──────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(500)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 and lastVehicle ~= 0 then
            if currentStage ~= 0 then
                StopPattern(lastVehicle)
                SetVehicleLightMultiplier(lastVehicle, 1.0)
                TriggerServerEvent('nxn-els:server:updateState',
                    NetworkGetNetworkIdFromEntity(lastVehicle), 0, false)
            end
            currentStage = 0
            sirenMuted   = false
            SetIndicators('none')
        end
        lastVehicle = vehicle
    end
end)

-- ── Client Export API ─────────────────────────────────────────

exports('getStage', function() return currentStage end)
exports('isElsActive', function() return currentStage > 0 end)
exports('isAdmin', function() return isAdmin end)

exports('isSirenActive', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return false end
    local cfg = NXN.ELS.GetStageConfig(vehicle, currentStage)
    return cfg.sirenActive and not sirenMuted
end)

exports('setStage', function(stage)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 or not elsEnabled then return false end
    stage = math.max(0, math.min(3, stage))
    currentStage = stage
    sirenMuted   = false
    ApplyStage(vehicle, currentStage)
    TriggerServerEvent('nxn-els:server:updateState',
        NetworkGetNetworkIdFromEntity(vehicle), currentStage, sirenMuted)
    return true
end)

exports('getStageLabel', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return 'KI' end
    return NXN.ELS.GetStageConfig(vehicle, currentStage).label
end)

exports('setJobPermission', function(job, allowed)
    TriggerEvent('nxn-els:client:setJobPermission', job, allowed)
end)

exports('hasPermission', function() return elsEnabled end)
exports('getIndicatorState', function() return indicatorState end)
exports('isPatternRunning', function() return patternActive end)
exports('getCurrentPattern', function() return patternName end)
