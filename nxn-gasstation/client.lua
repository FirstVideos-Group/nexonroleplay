-- ============================================================
--  nxn-gasstation | client.lua
-- ============================================================

local isRefueling   = false
local isUIOpen      = false
local activeStation = nil  -- stationId string
local activePump    = nil  -- pump table { coords, heading }
local refuelVehicle = nil  -- vehicle entity
local refuelPlate   = nil  -- plate string

-- ── Helpers ──────────────────────────────────────────────────

local function SetUIVisible(state, data)
    isUIOpen = state
    SetNuiFocus(state, state)
    if state then
        SendNUIMessage({ action = 'open', data = data })
    else
        SendNUIMessage({ action = 'close' })
    end
end

local function GetClosestPump()
    local ped    = PlayerPedId()
    local pos    = GetEntityCoords(ped)
    local best   = nil
    local bestId = nil
    local bestDist = 999

    for stationId, station in pairs(Config.Stations) do
        for _, pump in ipairs(station.pumps) do
            local d = NXN.Gas.Distance(pos, pump.coords)
            if d < bestDist then
                bestDist = d
                best     = pump
                bestId   = stationId
            end
        end
    end

    return bestId, best, bestDist
end

local function StopRefuelAnim()
    if Config.RefuelAnim.enabled then
        local ped = PlayerPedId()
        StopAnimTask(ped, Config.RefuelAnim.dict, Config.RefuelAnim.name, 1.0)
    end
end

local function StartRefuelAnim()
    if not Config.RefuelAnim.enabled then return end
    local ped  = PlayerPedId()
    local dict = Config.RefuelAnim.dict
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    TaskPlayAnim(ped, dict, Config.RefuelAnim.name, 2.0, -1.0, -1, 1, 0, false, false, false)
end

local function GetVehiclePlate(vehicle)
    if GetResourceState('nxn-vehicles') == 'started' then
        local plate = exports['nxn-vehicles']:getPlate(vehicle)
        if plate and plate ~= '' then return plate end
    end
    return GetVehicleNumberPlateText(vehicle)
end

local function OpenRefuelUI(stationId, station, vehicle, plate)
    local currentFuel = 50.0
    local tankSize    = 65.0

    if GetResourceState('nxn-fuel') == 'started' then
        local f = exports['nxn-fuel']:getFuel(plate)
        local t = exports['nxn-fuel']:getTankSize(plate)
        if f then currentFuel = f end
        if t then tankSize    = t end
    end

    local maxLiters   = math.max(0, tankSize * (1 - currentFuel / 100))
    local price       = station.pricePerLiter or Config.DefaultPricePerLiter

    refuelVehicle = vehicle
    refuelPlate   = plate
    activeStation = stationId

    SetUIVisible(true, {
        stationLabel  = station.label,
        currentFuel   = math.floor(currentFuel),
        maxLiters     = math.floor(maxLiters * 10) / 10,
        pricePerLiter = price,
    })
end

-- ── NUI Callbacks ────────────────────────────────────────────

RegisterNUICallback('confirm', function(data, cb)
    local liters = tonumber(data.liters) or 0
    if liters < Config.MinRefuelAmount then
        cb('ok')
        return
    end
    SetUIVisible(false)
    TriggerServerEvent('nxn-gasstation:server:startRefuel', {
        plate        = refuelPlate,
        stationId    = activeStation,
        pumpIndex    = 1,
        requestedLiters = liters,
    })
    cb('ok')
end)

RegisterNUICallback('cancel', function(_, cb)
    SetUIVisible(false)
    cb('ok')
end)

-- ── Net Events ───────────────────────────────────────────────

RegisterNetEvent('nxn-gasstation:client:refuelAllowed', function(data)
    if not data.ok then
        if GetResourceState('nxn-notify') == 'started' then
            exports['nxn-notify']:send(data.reason or 'Tankálás megtagadva.', 'error')
        end
        return
    end

    isRefueling = true
    StartRefuelAnim()

    local liters = data.requestedLiters or 0
    local waitMs = math.max(1000, math.floor((liters / Config.RefuelRate) * 1000))

    Wait(waitMs)

    if not isRefueling then return end  -- megszakítva

    TriggerServerEvent('nxn-gasstation:server:confirmRefuel', {
        plate        = refuelPlate,
        stationId    = activeStation,
        liters       = liters,
        vehicleNetId = NetworkGetNetworkIdFromEntity(refuelVehicle),
    })
end)

RegisterNetEvent('nxn-gasstation:client:refuelDone', function(data)
    isRefueling = false
    StopRefuelAnim()
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:send(
            ('Tankálva: %.1fL – %d Ft'):format(data.litersAdded, data.totalPrice),
            'success'
        )
    end
    NXN.Gas.Log(('Tankálás kész: %s %.1fL %dFt'):format(data.plate, data.litersAdded, data.totalPrice))
end)

RegisterNetEvent('nxn-gasstation:client:refuelFailed', function(data)
    isRefueling = false
    StopRefuelAnim()
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:send(data.reason or 'Tankálás sikertelen.', 'error')
    end
end)

RegisterNetEvent('nxn-gasstation:client:openRefuelUI', function(stationId)
    local ped    = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) then
        -- közelben lévő jármű keresése
        local pos = GetEntityCoords(ped)
        local nearVeh = GetClosestVehicle(pos.x, pos.y, pos.z, 8.0, 0, 71)
        if not DoesEntityExist(nearVeh) then
            if GetResourceState('nxn-notify') == 'started' then
                exports['nxn-notify']:send('Nincs közelben jármű!', 'error')
            end
            return
        end
        vehicle = nearVeh
    end

    local plate   = GetVehiclePlate(vehicle)
    local station = Config.Stations[stationId]
    if not station then return end
    OpenRefuelUI(stationId, station, vehicle, plate)
end)

-- ── Proximity Loop ───────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(500)
        if isUIOpen or isRefueling then goto continue end

        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        for stationId, station in pairs(Config.Stations) do
            if station.markerEnabled then
                for _, pump in ipairs(station.pumps) do
                    local d = NXN.Gas.Distance(pos, pump.coords)

                    if d < Config.MarkerDrawDistance then
                        -- Marker rajzolás (csak közel, de saját thread-ben)
                        DrawMarker(
                            station.markerType or 1,
                            pump.coords.x, pump.coords.y, pump.coords.z - 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            1.5, 1.5, 0.5,
                            station.markerColor.r,
                            station.markerColor.g,
                            station.markerColor.b,
                            station.markerColor.a,
                            false, true, 2, false, nil, nil, false
                        )
                    end

                    if d < Config.InteractionDistance then
                        -- Hint szöveg
                        local vehicle = GetVehiclePedIsIn(ped, false)
                        if not DoesEntityExist(vehicle) then
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Tankálás (' .. station.label .. ')')
                            EndTextCommandDisplayHelp(0, false, true, -1)
                        else
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Tankálás (' .. station.label .. ')')
                            EndTextCommandDisplayHelp(0, false, true, -1)
                        end

                        if IsControlJustReleased(0, 38) and not isUIOpen then  -- E gomb
                            local veh = GetVehiclePedIsIn(ped, false)
                            if not DoesEntityExist(veh) then
                                -- Közelben lévő jármű keresése
                                local nearVeh = GetClosestVehicle(pos.x, pos.y, pos.z, 8.0, 0, 71)
                                if DoesEntityExist(nearVeh) then
                                    veh = nearVeh
                                end
                            end
                            if DoesEntityExist(veh) then
                                local plate = GetVehiclePlate(veh)
                                OpenRefuelUI(stationId, station, veh, plate)
                            else
                                if GetResourceState('nxn-notify') == 'started' then
                                    exports['nxn-notify']:send('Nincs közelben jármű!', 'error')
                                end
                            end
                        end
                    end
                end
            end
        end
        ::continue::
    end
end)

-- ── Blip spawn ───────────────────────────────────────────────

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Blipek
    for stationId, station in pairs(Config.Stations) do
        if station.blip and station.blip.enabled then
            if GetResourceState('nxn-minimap') == 'started' then
                exports['nxn-minimap']:addBlip('gasstation_' .. stationId, {
                    coords = station.pumps[1].coords,
                    sprite = station.blip.sprite,
                    color  = station.blip.color,
                    label  = station.blip.label,
                    scale  = station.blip.scale,
                })
            else
                local b = AddBlipForCoord(station.pumps[1].coords)
                SetBlipSprite(b, station.blip.sprite)
                SetBlipColour(b, station.blip.color)
                SetBlipScale(b, station.blip.scale)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(station.blip.label)
                EndTextCommandSetBlipName(b)
            end
        end

        -- NPC regisztrálás
        if station.npc and station.npc.enabled then
            if GetResourceState('nxn-npcconversation') == 'started' then
                exports['nxn-npcconversation']:registerNPC('gasstation_' .. stationId, {
                    label    = station.label .. ' – Kúltos',
                    model    = station.npc.model,
                    coords   = station.npc.coords,
                    scenario = station.npc.scenario,
                    blip     = station.blip,
                    dialogues = {
                        {
                            id       = 'refuel',
                            label    = 'Tankálás',
                            icon     = 'hgi-fuel-station',
                            response = 'Persze, hozd ide a kocsit!',
                            event    = 'nxn-gasstation:client:openRefuelUI',
                            eventData = stationId,
                        },
                        {
                            id       = 'price',
                            label    = 'Mi az ár?',
                            icon     = 'hgi-dollar-01',
                            response = ('%d Ft/liter.'):format(station.pricePerLiter or Config.DefaultPricePerLiter),
                            event    = '',
                        },
                    },
                })
            end
        end
    end
end)

-- Tankálás megszakítása, ha a játékos kiszáll közben
AddEventHandler('gameEventTriggered', function(name)
    if name == 'CEventNetworkPlayerExitedVehicle' and isRefueling then
        exports['nxn-gasstation']:cancelRefuel()
    end
end)

-- ── Exports ──────────────────────────────────────────────────

exports('startRefuel', function(vehicleEntity, stationId)
    local station = Config.Stations[stationId]
    if not station then return end
    local plate = GetVehiclePlate(vehicleEntity)
    OpenRefuelUI(stationId, station, vehicleEntity, plate)
end)

exports('isRefueling', function()
    return isRefueling
end)

exports('cancelRefuel', function()
    if not isRefueling then return end
    isRefueling = false
    StopRefuelAnim()
    SetUIVisible(false)
    TriggerServerEvent('nxn-gasstation:server:cancelRefuel', { plate = refuelPlate })
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:send('Tankálás megszakítva.', 'info')
    end
end)
