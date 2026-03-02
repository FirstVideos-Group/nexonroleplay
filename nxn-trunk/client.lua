-- ============================================================
--  nxn-trunk | client.lua
-- ============================================================

local isOpen        = false
local currentPlate  = ''
local currentVehicle = 0

-- ── Segédfüggvények ─────────────────────────────────────────

local function SetVisible(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = 'setVisible', visible = state })
end

local function GetVehicleRearCoords(vehicle)
    local pos     = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    local rad     = math.rad(heading)
    local offset  = 2.5
    return vector3(
        pos.x - math.sin(rad) * offset,
        pos.y - math.cos(rad) * offset,
        pos.z
    )
end

local function DrawMarker(coords)
    local c = Config.Marker.color
    DrawMarker(
        Config.Marker.type,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.Marker.size, Config.Marker.size, 0.5,
        c.r, c.g, c.b, c.a,
        false, false, 2, false, nil, nil, false
    )
end

local function DrawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z + 0.6)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

local function GetNearbyVehicleRear()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)

    local vehicle, dist = 0, Config.InteractDistance
    local vehs = GetGamePool('CVehicle')
    for _, v in ipairs(vehs) do
        if v ~= GetVehiclePedIsIn(ped, false) then
            local rearCoords = GetVehicleRearCoords(v)
            local d = #(pos - rearCoords)
            if d < dist then
                -- Halozati jármű ellőrzés
                if Config.RequireNetworkVehicle then
                    local netId = NetworkGetNetworkIdFromEntity(v)
                    if netId and netId > 0 then
                        dist    = d
                        vehicle = v
                    end
                else
                    dist    = d
                    vehicle = v
                end
            end
        end
    end
    return vehicle > 0 and vehicle or nil
end

local function OpenTrunkForVehicle(vehicle)
    local vClass = GetVehicleClass(vehicle)

    -- Motorkerékpár kizárás
    if vClass == 8 and not Config.AllowMotorcycleTrunk then
        if GetResourceState('nxn-notify') == 'started' then
            exports['nxn-notify']:warning('Motorkerékpáron nincs csomagtartó!')
        end
        return
    end

    local rawPlate = GetVehicleNumberPlateText(vehicle)
    local plate    = NXN.Trunk.NormalizePlate(rawPlate)
    if plate == '' then return end

    -- nxn-inventory itemDefs átadása szerver felé (súlyok tájékoztatásához)
    local invItemDefs = {}
    if GetResourceState('nxn-inventory') == 'started' then
        local localInv = exports['nxn-inventory']:getLocalInventory()
        -- itemDefs-et a shared Config-ból vesszuk a játékos kliensjén
        -- (nxn-inventory shared.lua is fut client-en)
        if NXN.Inventory and NXN.Inventory.GetItemDef then
            for name, _ in pairs(localInv.items or {}) do
                local def = NXN.Inventory.GetItemDef(name)
                if def then
                    invItemDefs[name] = { weight = def.weight, label = def.label, icon = def.icon }
                end
            end
        end
    end

    currentVehicle = vehicle
    currentPlate   = plate
    TriggerServerEvent('nxn-trunk:server:open', plate, vClass, invItemDefs)
end

-- ── Közelség-loop ─────────────────────────────────────────────

CreateThread(function()
    while true do
        local sleep   = 1000
        local ped     = PlayerPedId()
        local pos     = GetEntityCoords(ped)
        local vehs    = GetGamePool('CVehicle')

        for _, v in ipairs(vehs) do
            if v ~= GetVehiclePedIsIn(ped, false) then
                local rearCoords = GetVehicleRearCoords(v)
                local dist = #(pos - rearCoords)
                if dist < Config.InteractDistance * 4 then
                    sleep = 0
                    if Config.Marker.enabled then DrawMarker(rearCoords) end
                    local plate = NXN.Trunk.NormalizePlate(GetVehicleNumberPlateText(v))
                    DrawText3D(rearCoords, ('[%s] Csomagtartó – %s'):format(
                        IsControlJustReleased and 'G' or 'G', plate
                    ))
                end
            end
        end
        Wait(sleep)
    end
end)

-- ── Interakció billentyű ──────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        if not isOpen then
            if IsControlJustReleased(0, Config.OpenKey) then
                local vehicle = GetNearbyVehicleRear()
                if vehicle then
                    OpenTrunkForVehicle(vehicle)
                end
            end
        end
    end
end)

-- ── Escape bezárás ─────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        if isOpen and IsControlJustReleased(0, 200) then
            SetVisible(false)
            TriggerServerEvent('nxn-trunk:server:close', currentPlate)
            currentPlate   = ''
            currentVehicle = 0
        end
    end
end)

-- ── NUI callbacks ─────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    SetVisible(false)
    if currentPlate ~= '' then
        TriggerServerEvent('nxn-trunk:server:close', currentPlate)
    end
    currentPlate   = ''
    currentVehicle = 0
    cb('ok')
end)

RegisterNUICallback('moveToInventory', function(data, cb)
    local itemName = data.itemName
    local count    = tonumber(data.count) or 1
    if not itemName or count < 1 then cb({ ok = false }) return end
    TriggerServerEvent('nxn-trunk:server:moveToInventory', currentPlate, itemName, count, data.itemWeight or 1.0)
    cb('ok')
end)

RegisterNUICallback('moveToTrunk', function(data, cb)
    local itemName = data.itemName
    local count    = tonumber(data.count) or 1
    if not itemName or count < 1 then cb({ ok = false }) return end
    TriggerServerEvent('nxn-trunk:server:moveToTrunk', currentPlate, itemName, count, data.itemWeight or 1.0)
    cb('ok')
end)

-- ── Net eventek ───────────────────────────────────────────────

RegisterNetEvent('nxn-trunk:client:sync', function(data)
    -- Inventory adat lekérés nxn-inventory kliensexportból
    local invData = {}
    if GetResourceState('nxn-inventory') == 'started' then
        local localInv = exports['nxn-inventory']:getLocalInventory()
        -- Item defíniációk felgázdágatása
        if NXN.Inventory and NXN.Inventory.GetItemDef then
            for name, slot in pairs(localInv.items or {}) do
                local def = NXN.Inventory.GetItemDef(name)
                if def then
                    invData[name] = {
                        count    = slot.count or 1,
                        label    = def.label,
                        icon     = def.icon,
                        weight   = def.weight,
                        category = def.category or 'misc',
                    }
                end
            end
        end
    end

    -- Trunk itemek gazdagítása label/icon-nal ha hozzáférhető
    local enrichedTrunk = {}
    for _, item in ipairs(data.items or {}) do
        local entry = { name = item.name, count = item.count or 1, weight = item.weight or 0, label = item.label or item.name, icon = item.icon or '' }
        if NXN.Inventory and NXN.Inventory.GetItemDef then
            local def = NXN.Inventory.GetItemDef(item.name)
            if def then
                entry.label = def.label
                entry.icon  = def.icon
                entry.weight = def.weight
            end
        end
        table.insert(enrichedTrunk, entry)
    end

    SendNUIMessage({
        action        = 'sync',
        plate         = data.plate,
        trunkItems    = enrichedTrunk,
        trunkMax      = data.maxWeight,
        trunkCurrent  = data.currentWeight,
        invItems      = invData,
        invMax        = (GetResourceState('nxn-inventory') == 'started') and exports['nxn-inventory']:getLocalWeight and exports['nxn-inventory']:getLocalWeight() or 0,
        invMaxWeight  = 30.0,  -- nxn-inventory Config.MaxWeight default
    })

    if not isOpen then
        SetVisible(true)
    end
end)

RegisterNetEvent('nxn-trunk:client:moveResult', function(data)
    SendNUIMessage({ action = 'moveResult', ok = data.ok, message = data.message, direction = data.direction })
end)

-- ── Kliens exportok ──────────────────────────────────────────

exports('openTrunk', function(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    OpenTrunkForVehicle(vehicle)
end)

exports('closeTrunk', function()
    if isOpen then
        SetVisible(false)
        if currentPlate ~= '' then
            TriggerServerEvent('nxn-trunk:server:close', currentPlate)
        end
        currentPlate   = ''
        currentVehicle = 0
    end
end)

exports('isOpen', function()
    return isOpen
end)

exports('getNearbyVehicle', function()
    return GetNearbyVehicleRear()
end)
