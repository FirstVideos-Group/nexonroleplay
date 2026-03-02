-- ============================================================
--  nxn-garage | client.lua
-- ============================================================

local garageOpen      = false
local currentGarageId = nil
local blips           = {}

-- ── Segédfüggvények ──────────────────────────────────────────

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    local t = ntype or 'info'
    if     t == 'success' then exports['nxn-notify']:success(msg)
    elseif t == 'danger'  then exports['nxn-notify']:danger(msg)
    elseif t == 'warning' then exports['nxn-notify']:warning(msg)
    else                       exports['nxn-notify']:info(msg)
    end
end

local function NUISend(action, data)
    local payload = { action = action }
    if data then for k, v in pairs(data) do payload[k] = v end end
    SendNUIMessage(payload)
end

-- ── Garázs panel ───────────────────────────────────────────

local function OpenGarageUI(garageId)
    if garageOpen then return end
    garageOpen      = true
    currentGarageId = garageId
    SetNuiFocus(true, true)
    NUISend('open', { garageId = garageId })
    TriggerServerEvent('nxn-garage:server:getVehicles', garageId)
    NXN.Garage.Log(('OpenGarageUI: %s'):format(garageId))
end

local function CloseGarageUI()
    if not garageOpen then return end
    garageOpen      = false
    currentGarageId = nil
    SetNuiFocus(false, false)
    NUISend('close', {})
    NXN.Garage.Log('CloseGarageUI')
end

-- ── NUI callbackok ────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    CloseGarageUI()
    cb('ok')
end)

RegisterNUICallback('spawn', function(data, cb)
    if not data.plate or not currentGarageId then cb('err') return end
    TriggerServerEvent('nxn-garage:server:spawn', data.plate, currentGarageId)
    cb('ok')
end)

RegisterNUICallback('despawn', function(data, cb)
    if not data.plate then cb('err') return end
    local hp = 100.0
    if Config.PersistEngineHP and GetResourceState('nxn-engine') == 'started' then
        local h = exports['nxn-engine']:getEngineHP()
        if type(h) == 'number' then hp = h end
    end
    TriggerServerEvent('nxn-garage:server:despawn', data.plate, hp)
    cb('ok')
end)

RegisterNUICallback('refresh', function(data, cb)
    if currentGarageId then
        TriggerServerEvent('nxn-garage:server:getVehicles', currentGarageId)
    end
    cb('ok')
end)

-- ── Szerver → Kliens eventek ─────────────────────────────────

RegisterNetEvent('nxn-garage:client:vehicleList', function(data)
    NXN.Garage.Log(('vehicleList: %d jármű'):format(#(data.vehicles or {})))
    -- Aktális jármű plate hozzáadása (elrak gombok logikájához)
    local curPlate = ''
    if GetResourceState('nxn-vehicles') == 'started' then
        curPlate = exports['nxn-vehicles']:getCurrentVehiclePlate() or ''
    end
    data.currentPlate = curPlate
    NUISend('vehicleList', data)
end)

RegisterNetEvent('nxn-garage:client:spawnResult', function(data)
    NXN.Garage.Log(('spawnResult: ok=%s plate=%s'):format(tostring(data.ok), tostring(data.plate)))
    if data.ok then
        -- Jármő spawnoloasa a garázs spawn coords-on
        CreateThread(function()
            local sc     = data.spawnCoords
            local model  = GetHashKey(data.model)
            RequestModel(model)
            local t = 0
            while not HasModelLoaded(model) do
                Wait(100)
                t = t + 1
                if t > 60 then
                    Notify('Jármő model betöltési hiba!', 'danger')
                    return
                end
            end

            local veh = CreateVehicle(model, sc.x, sc.y, sc.z, sc.w, true, false)
            SetVehicleNumberPlateText(veh, data.plate)
            SetEntityAsMissionEntity(veh, true, true)
            SetModelAsNoLongerNeeded(model)

            -- Motor HP visszatöltés (nxn-engine)
            if Config.PersistEngineHP and GetResourceState('nxn-engine') == 'started' then
                exports['nxn-engine']:setEngineHP(data.hp or 100.0)
            end

            -- Kulcs adása kliensen (ha nxn-keys fut)
            if Config.AutoGiveKey and GetResourceState('nxn-keys') == 'started' then
                exports['nxn-keys']:giveKey(data.plate)
            end

            Notify('Jármő kivéve: ' .. data.plate, 'success')
            NUISend('spawnResult', { ok = true, plate = data.plate })
        end)
        CloseGarageUI()
    else
        Notify(data.message or 'Spawn sikertelen!', 'danger')
        NUISend('spawnResult', { ok = false, message = data.message })
    end
end)

RegisterNetEvent('nxn-garage:client:despawnResult', function(data)
    NXN.Garage.Log(('despawnResult: ok=%s'):format(tostring(data.ok)))
    if data.ok then
        -- Aktuális jármő törlése ha az a lerákott jármő
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetVehicleNumberPlateText(veh) == data.plate then
            DeleteVehicle(veh)
        end
        Notify('Jármő elrakva.', 'success')
        NUISend('despawnResult', { ok = true })
        -- Lista frissítés
        if currentGarageId then
            TriggerServerEvent('nxn-garage:server:getVehicles', currentGarageId)
        end
    else
        Notify(data.message or 'Despawn sikertelen!', 'danger')
        NUISend('despawnResult', { ok = false, message = data.message })
    end
end)

-- NPC dialóg event
RegisterNetEvent('nxn-garage:client:openFromNPC', function(data)
    if data and data.garageId then
        OpenGarageUI(data.garageId)
    end
end)

-- ── Közelség-detekció + marker + blip loop ──────────────────

local function InitBlips()
    for _, g in ipairs(Config.Garages) do
        if g.blip and g.blip.enabled then
            local b = AddBlipForCoord(g.coords.x, g.coords.y, g.coords.z)
            SetBlipSprite(b, g.blip.sprite or 357)
            SetBlipColour(b, g.blip.color or 0)
            SetBlipScale(b, g.blip.scale or 0.8)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(g.blip.label or g.label)
            EndTextCommandSetBlipName(b)
            blips[g.id] = b
        end
    end
end

CreateThread(function()
    Wait(1000)  -- játékos betöltés után
    InitBlips()

    -- NPC regisztrálás (nxn-npcconversation)
    if GetResourceState('nxn-npcconversation') == 'started' then
        for _, g in ipairs(Config.Garages) do
            if g.npc and g.npc.enabled then
                exports['nxn-npcconversation']:registerNPC(g.id .. '_npc', {
                    label    = g.label,
                    model    = g.npc.model,
                    coords   = vector4(g.coords.x, g.coords.y, g.coords.z, g.npc.heading),
                    scenario = g.npc.scenario,
                    dialogues = {
                        {
                            id     = 'open_garage',
                            label  = 'Járműveim',
                            icon   = 'hgi-car-01',
                            action = 'event',
                            event  = 'nxn-garage:client:openFromNPC',
                            data   = { garageId = g.id },
                        },
                    },
                })
                NXN.Garage.Log(('NPC regisztrálva: %s_npc'):format(g.id))
            end
        end
    end

    -- nxn-signs zónák (opcionális)
    if GetResourceState('nxn-signs') == 'started' then
        for _, g in ipairs(Config.Garages) do
            exports['nxn-signs']:registerZone(g.id .. '_zone', {
                label    = g.label,
                category = 'info',
                file     = 'garage_zone.svg',
                center   = g.coords,
                radius   = Config.InteractDistance * 2,
                duration = nil,
            })
        end
    end
end)

-- Közelség + marker loop (500ms)
CreateThread(function()
    while true do
        Wait(500)
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, g in ipairs(Config.Garages) do
            local dist = #(coords - g.coords)

            -- Marker rajzolás loop-ban (Wait(0) helyett közel lévőknél)
            if dist < (Config.InteractDistance * 3) and g.marker and g.marker.enabled then
                local mc = g.marker.color or { r = 91, g = 106, b = 240, a = 80 }
                DrawMarker(
                    g.marker.type or 1,
                    g.coords.x, g.coords.y, g.coords.z - 0.9,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    g.marker.size or 1.0, g.marker.size or 1.0, 0.5,
                    mc.r, mc.g, mc.b, mc.a,
                    false, true, 2, false, nil, nil, false
                )
            end

            -- E gomb prompt (ha közel van és nem NPC-s garázs, vagy NPC nincs futó)
            if dist < Config.InteractDistance and not garageOpen then
                local npcActive = g.npc and g.npc.enabled and GetResourceState('nxn-npcconversation') == 'started'
                if not npcActive then
                    SetTextComponentFormat('STRING')
                    AddTextComponentString(('[E] %s megnyitása'):format(g.label))
                    DisplayHelpTextFromStringLabel(0, false, true, -1)

                    if IsControlJustReleased(0, Config.OpenKey) then
                        OpenGarageUI(g.id)
                    end
                end
            end
        end
    end
end)

-- Resource stop: NPC-k törlése + blipek
AddEventHandler('onResourceStop', function(res)
    if res ~= Config.ResourceName then return end
    for id, b in pairs(blips) do
        RemoveBlip(b)
    end
    if GetResourceState('nxn-npcconversation') == 'started' then
        for _, g in ipairs(Config.Garages) do
            if g.npc and g.npc.enabled then
                exports['nxn-npcconversation']:unregisterNPC(g.id .. '_npc')
            end
        end
    end
end)

-- ── Kliens exportok ─────────────────────────────────────────

--- Garázs panel megnyitása
---@param garageId string? Ha nil: legközelebbi garázs
exports('openGarage', function(garageId)
    if garageId then
        OpenGarageUI(garageId)
        return
    end
    -- Legközelebbi garázs keresés
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local best, bestDist = nil, math.huge
    for _, g in ipairs(Config.Garages) do
        local d = #(coords - g.coords)
        if d < bestDist then bestDist = d; best = g end
    end
    if best then OpenGarageUI(best.id) end
end)

--- Garázs panel bezárása
exports('closeGarage', function()
    CloseGarageUI()
end)

--- Nyitva van-e a garázs panel
---@return boolean
exports('isGarageOpen', function()
    return garageOpen
end)
