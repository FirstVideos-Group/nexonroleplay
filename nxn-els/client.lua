-- ============================================================
--  nxn-els | client.lua
--  Fényfokozat-kezelés, billentyűkötések, NUI frissítés,
--  szerverszinkron és export API
-- ============================================================

-- ── Állapot ──────────────────────────────────────────────────

local elsEnabled    = false   -- játékos jogosult-e ELS-t használni
local currentStage  = 0       -- 0..3
local sirenMuted    = false   -- stage 2/3-on belül némítható a hang
local indicatorState = 'none' -- 'none' | 'left' | 'right' | 'hazard'
local lastVehicle   = 0
local currentJob    = ''

-- ── Jogosultság beállítása ───────────────────────────────────
-- nxn-police és más scriptek hívják ezt a netevent-et / exportot

AddEventHandler('nxn-els:client:setJobPermission', function(job, allowed)
    currentJob = job or ''
    elsEnabled = allowed and NXN.ELS.IsJobAllowed(currentJob)
    NXN.ELS.Log(('setJobPermission: job=%s allowed=%s -> elsEnabled=%s'):format(
        currentJob, tostring(allowed), tostring(elsEnabled)))
end)

-- ── Extras és sziréna alkalmazása ────────────────────────────

local function ApplyStage(vehicle, stage)
    if vehicle == 0 then return end
    local cfg = NXN.ELS.GetStageConfig(vehicle, stage)

    -- Extra-k: előbb mindent ki, majd a stage-hez tartozókat be
    for i = 0, 14 do
        SetVehicleExtra(vehicle, i, true)  -- true = letiltva a GTA API-ban
    end
    for _, extraId in ipairs(cfg.lightExtras) do
        SetVehicleExtra(vehicle, extraId, false) -- false = engedélyezve
    end

    -- Sziréna hang
    local sirenOn = cfg.sirenActive and not sirenMuted
    SetVehicleSiren(vehicle, sirenOn)
    if sirenOn then
        TriggerServerEvent('nxn-els:server:setSirenSound', NetworkGetNetworkIdFromEntity(vehicle), cfg.sirenTone)
    else
        TriggerServerEvent('nxn-els:server:setSirenSound', NetworkGetNetworkIdFromEntity(vehicle), 0)
    end

    -- nxn-vehicle-hud integráció
    if Config.IntegrateVehicleHud then
        local hudLoaded = GetResourceState('nxn-vehicle-hud') == 'started'
        if hudLoaded then
            local active = stage > 0
            exports['nxn-vehicle-hud']:setSiren(active, cfg.label)
        end
    end

    NXN.ELS.Log(('ApplyStage: stage=%d label=%s sirenOn=%s extras=%s'):format(
        stage, cfg.label, tostring(sirenOn), table.concat(cfg.lightExtras, ',')))
end

-- ── Szerver szinkron broadcast fogadása ──────────────────────

AddEventHandler('nxn-els:client:syncState', function(netId, stage, muted)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end
    -- Saját jármű = már alkalmazzuk lokálisan, mások járművénél csak extra-kat állítunk
    if vehicle ~= GetVehiclePedIsIn(PlayerPedId(), false) then
        local cfg = NXN.ELS.GetStageConfig(vehicle, stage)
        for i = 0, 14 do SetVehicleExtra(vehicle, i, true) end
        for _, extraId in ipairs(cfg.lightExtras) do
            SetVehicleExtra(vehicle, extraId, false)
        end
        local sirenOn = cfg.sirenActive and not muted
        SetVehicleSiren(vehicle, sirenOn)
    end
end)

-- ── Irányjelzők ──────────────────────────────────────────────

local function SetIndicators(mode)
    indicatorState = mode
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    SetVehicleIndicatorLights(vehicle, 1, mode == 'left'   or mode == 'hazard')
    SetVehicleIndicatorLights(vehicle, 0, mode == 'right'  or mode == 'hazard')
    NXN.ELS.Log(('Iranyjelzo: %s'):format(mode))
end

-- ── Fő logika + billentyűkötések ─────────────────────────────

CreateThread(function()
    -- Billentyűkötések regisztrálása
    RegisterKeyMapping('+nxnElsCycleStage',  'ELS Fokozat váltás',    'keyboard', Config.Keys.cycleStage)
    RegisterKeyMapping('+nxnElsToggleSiren', 'ELS Sziréna mute',      'keyboard', Config.Keys.toggleSiren)
    RegisterKeyMapping('+nxnElsIndicatorL',  'ELS Bal irányjelző',    'keyboard', Config.Keys.indicatorL)
    RegisterKeyMapping('+nxnElsIndicatorR',  'ELS Jobb irányjelző',   'keyboard', Config.Keys.indicatorR)
    RegisterKeyMapping('+nxnElsHazard',      'ELS Vészvillogó',       'keyboard', Config.Keys.hazard)

    RegisterCommand('+nxnElsCycleStage', function()
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 then return end
        if not elsEnabled then
            NXN.ELS.Warn('ELS: nincs jogosultságod szirénát használni!')
            return
        end
        if not NXN.ELS.IsVehicleAllowed(vehicle) then
            NXN.ELS.Warn('ELS: ez a jármű nem rendelkezik ELS-sel!')
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

-- ── Jármű kiszállás: ELS reset ────────────────────────────────

CreateThread(function()
    while true do
        Wait(500)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 and lastVehicle ~= 0 then
            -- Kiszállt, reset
            if currentStage ~= 0 then
                ApplyStage(lastVehicle, 0)
                TriggerServerEvent('nxn-els:server:updateState',
                    NetworkGetNetworkIdFromEntity(lastVehicle), 0, false)
            end
            currentStage = 0
            sirenMuted   = false
            SetIndicators('none')
            NXN.ELS.Log('Kiszállt: ELS visszaállítva')
        end
        lastVehicle = vehicle
    end
end)

-- ── Client Export API ─────────────────────────────────────────

--- Visszaadja az aktuális stage-t (0..3)
exports('getStage', function()
    return currentStage
end)

--- Visszaadja, hogy aktív-e az ELS (stage > 0)
exports('isElsActive', function()
    return currentStage > 0
end)

--- Visszaadja, hogy a sziréna hang aktív-e
exports('isSirenActive', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return false end
    local cfg = NXN.ELS.GetStageConfig(vehicle, currentStage)
    return cfg.sirenActive and not sirenMuted
end)

--- Kívülről állítja a fokozatot (pl. nxn-police dispatch)
---@param stage number 0..3
exports('setStage', function(stage)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return false end
    if not elsEnabled then return false end
    stage = math.max(0, math.min(3, stage))
    currentStage = stage
    sirenMuted   = false
    ApplyStage(vehicle, currentStage)
    TriggerServerEvent('nxn-els:server:updateState',
        NetworkGetNetworkIdFromEntity(vehicle), currentStage, sirenMuted)
    return true
end)

--- Visszaadja az aktuális stage label-jét (pl. 'CODE 2')
exports('getStageLabel', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return 'KI' end
    local cfg = NXN.ELS.GetStageConfig(vehicle, currentStage)
    return cfg.label
end)

--- Jogosultság beállítása kívülről (nxn-police, nxn-ems stb. hívja)
---@param job string
---@param allowed boolean
exports('setJobPermission', function(job, allowed)
    TriggerEvent('nxn-els:client:setJobPermission', job, allowed)
end)

--- Visszaadja, van-e ELS jogosultsága a játékosnak
exports('hasPermission', function()
    return elsEnabled
end)

--- Irányjelző állapot lekérése
exports('getIndicatorState', function()
    return indicatorState
end)
