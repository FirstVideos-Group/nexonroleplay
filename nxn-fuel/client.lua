-- ============================================================
--  nxn-fuel | client.lua
-- ============================================================

-- ── Állapot ────────────────────────────────────────────────
local fuelCache         = {}     -- { [plate] = float }
local currentPlate      = nil
local currentVehicle    = 0
local lastSaveTime      = 0
local lastNotifyTime    = 0
local lastHudLevel      = -1
local emptyTriggered    = false
local lowTriggered      = false

-- ── Segéd ──────────────────────────────────────────────────

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    local t = ntype or 'info'
    if     t == 'success' then exports['nxn-notify']:success(msg)
    elseif t == 'danger'  then exports['nxn-notify']:danger(msg)
    elseif t == 'warning' then exports['nxn-notify']:warning(msg)
    else                       exports['nxn-notify']:info(msg)
    end
end

local function PushToHUD(level)
    if GetResourceState('nxn-vehicle-hud') == 'started' then
        exports['nxn-vehicle-hud']:setFuel(level)
    end
    if GetResourceState('nxn-hud') == 'started' then
        exports['nxn-hud']:updateModuleData('fuel', {
            value = math.floor(level),
            unit  = 'L%',
        })
    end
end

local function ShowFuelModule(visible)
    if GetResourceState('nxn-vehicle-hud') == 'started' then
        exports['nxn-vehicle-hud']:setModule('fuel', visible)
    end
end

local function OnFuelUpdated(level)
    TriggerEvent('nxn-fuel:updated', level)
    PushToHUD(level)
    lastHudLevel = level
end

-- ── Kliens exportok ─────────────────────────────────────────

exports('getCurrentFuel', function()
    if currentPlate and fuelCache[currentPlate] then
        return fuelCache[currentPlate]
    end
    return nil
end)

exports('isFuelLow', function()
    if currentPlate and fuelCache[currentPlate] then
        return fuelCache[currentPlate] < Config.LowFuelThreshold
    end
    return false
end)

-- ── Járműbe szállás hook ────────────────────────────────────

AddEventHandler('nxn-fuel:internal:enter', function(vehicle)
    local plate = NXN.Fuel.NormalizePlate(GetVehicleNumberPlateText(vehicle))
    if plate == '' then return end

    currentPlate   = plate
    currentVehicle = vehicle
    emptyTriggered = false
    lowTriggered   = false
    lastSaveTime   = GetGameTimer()
    lastNotifyTime = 0

    -- HUD megjelenítés
    ShowFuelModule(true)

    -- Szerver lekérdezés
    TriggerServerEvent('nxn-fuel:server:requestFuel', plate)
    NXN.Fuel.Log(('enter vehicle: plate=%s'):format(plate))
end)

-- ── Kiszállás hook ──────────────────────────────────────────

AddEventHandler('nxn-fuel:internal:exit', function(plate, level)
    -- HUD elrejtés
    ShowFuelModule(false)

    -- Azonnali mentés
    if plate and level then
        TriggerServerEvent('nxn-fuel:server:saveFuel', plate, level)
    end

    currentPlate   = nil
    currentVehicle = 0
    emptyTriggered = false
    lowTriggered   = false
    NXN.Fuel.Log(('exit vehicle: plate=%s level=%.2f'):format(tostring(plate), tonumber(level) or 0))
end)

-- ── Jármű érzékelés loop ───────────────────────────────────

CreateThread(function()
    local wasInVehicle = false
    local lastVehicle  = 0

    while true do
        Wait(500)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local inVehicle = veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped

        if inVehicle and not wasInVehicle then
            wasInVehicle = true
            lastVehicle  = veh
            TriggerEvent('nxn-fuel:internal:enter', veh)
        elseif not inVehicle and wasInVehicle then
            wasInVehicle = false
            local exitPlate = currentPlate
            local exitLevel = exitPlate and fuelCache[exitPlate] or nil
            TriggerEvent('nxn-fuel:internal:exit', exitPlate, exitLevel)
            lastVehicle = 0
        elseif inVehicle and wasInVehicle and veh ~= lastVehicle then
            -- Jármű váltás (pl. passengerből driver)
            local exitPlate = currentPlate
            local exitLevel = exitPlate and fuelCache[exitPlate] or nil
            TriggerEvent('nxn-fuel:internal:exit', exitPlate, exitLevel)
            Wait(100)
            lastVehicle = veh
            TriggerEvent('nxn-fuel:internal:enter', veh)
        end
    end
end)

-- ── Fogyasztási loop ─────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(Config.PollInterval)

        if not currentPlate or currentVehicle == 0 then goto continue end

        local ped = PlayerPedId()
        local veh = currentVehicle

        -- Csak vezető fogyaszt
        if GetPedInVehicleSeat(veh, -1) ~= ped then goto continue end

        local level = fuelCache[currentPlate]
        if level == nil then goto continue end

        -- Motor fut-e?
        local engineOn = GetIsVehicleEngineRunning(veh)
        if not engineOn then goto continue end

        -- Fogyasztás számítás
        local speed   = GetEntitySpeed(veh) * 3.6  -- m/s -> km/h
        local elapsed = Config.PollInterval / 1000.0
        local consumption
        if speed < 2.0 then
            -- Alapjárat
            consumption = Config.IdleConsumption * elapsed
        else
            consumption = (Config.BaseConsumption + speed * Config.SpeedMultiplier) * elapsed
        end

        local newLevel = NXN.Fuel.Clamp(level - consumption, 0.0, 100.0)
        fuelCache[currentPlate] = newLevel

        -- HUD push ha elég nagy a változás
        if math.abs(newLevel - lastHudLevel) >= Config.HudUpdateThreshold then
            OnFuelUpdated(newLevel)
        end

        -- Alacsony üzemanyag figyelmeztetés
        if newLevel < Config.LowFuelThreshold and newLevel > 0.0 then
            local now = GetGameTimer() / 1000.0
            if not lowTriggered or (now - lastNotifyTime) >= Config.LowFuelNotifyCooldown then
                lowTriggered   = true
                lastNotifyTime = now
                TriggerEvent('nxn-fuel:low', newLevel)
                Notify(('Alacsony üzemanyag! (%.0f%%)'):format(newLevel), 'warning')
            end
        elseif newLevel >= Config.LowFuelThreshold then
            lowTriggered = false
        end

        -- Üres tank
        if newLevel <= 0.0 and not emptyTriggered then
            emptyTriggered = true
            TriggerEvent('nxn-fuel:empty', currentPlate)
        end

        -- DB mentés throttle
        local now = GetGameTimer()
        if (now - lastSaveTime) >= Config.SaveInterval then
            lastSaveTime = now
            TriggerServerEvent('nxn-fuel:server:saveFuel', currentPlate, newLevel)
        end

        ::continue::
    end
end)

-- ── Üres tank -> motor leállítás ──────────────────────────────

AddEventHandler('nxn-fuel:empty', function(plate)
    if not Config.StallOnEmpty then return end
    local veh = currentVehicle
    if veh == 0 or not DoesEntityExist(veh) then return end

    Notify('Elfogyott az üzemanyag!', 'danger')

    if GetResourceState('nxn-engine') == 'started' then
        TriggerEvent('nxn-engine:client:forceOff')
    else
        -- Natív fallback
        SetVehicleEngineOn(veh, false, true, false)
    end
end)

-- ── nxn-fuel:updated figyelő (HUD push hook) ──────────────────

AddEventHandler('nxn-fuel:updated', function(level)
    PushToHUD(level)
end)

-- ── Net Events (kliens) ────────────────────────────────────

-- Szerver sync (requestFuel válasz, vagy addFuel/setFuel utáni push)
RegisterNetEvent('nxn-fuel:client:sync', function(data)
    if type(data) ~= 'table' or not data.plate or not data.level then return end
    local plate = NXN.Fuel.NormalizePlate(data.plate)
    local level = NXN.Fuel.Clamp(tonumber(data.level) or 0.0, 0.0, 100.0)

    fuelCache[plate] = level

    -- Ha ez a jelenlegi jármű, frissítjük a HUD-ot is
    if plate == currentPlate then
        emptyTriggered = level <= 0.0
        lowTriggered   = level < Config.LowFuelThreshold
        OnFuelUpdated(level)
    end

    NXN.Fuel.Log(('client:sync plate=%s level=%.2f'):format(plate, level))
end)
