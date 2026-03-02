-- ============================================================
--  nxn-delivery | client.lua
-- ============================================================

-- ── Állapot ──────────────────────────────────────────────────

local localTask   = nil   -- { taskId, category, label, icon, target, reward, timeLimit, distanceM, startedAt, pickedUp }
local pickupBlip  = nil
local dropoffBlip = nil
local onDutyCache = false
local jobCache    = nil

-- ── Helpers ──────────────────────────────────────────────────

local function removeBlip(blip)
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
end

local function createBlip(coords, sprite, color, label, scale)
    local b = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(b, sprite)
    SetBlipColour(b, color)
    SetBlipScale(b, scale or 0.8)
    SetBlipAsShortRange(b, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label)
    EndTextCommandSetBlipName(b)
    return b
end

local function showNUI(data)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'show', data = data })
end

local function hideNUI()
    SendNUIMessage({ type = 'hide' })
end

local function updateNUI(data)
    SendNUIMessage({ type = 'update', data = data })
end

local function getPlayerJob()
    if GetResourceState('nxn-job') == 'started' then
        return exports['nxn-job']:getLocalJob()
    end
    return nil
end

local function isOnDutyLocal()
    return onDutyCache
end

local function drawMarker(type, coords, size, r, g, b, a)
    DrawMarker(type,
        coords.x, coords.y, coords.z - 0.95,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        size.x, size.y, size.z,
        r, g, b, a,
        false, true, 2, false, nil, nil, false)
end

-- ── NPC Regisztrálás ─────────────────────────────────────────

local function registerDispatchNPCs()
    if GetResourceState('nxn-npcconversation') ~= 'started' then
        NXN.Delivery.Warn('nxn-npcconversation nem fut – NPC-k nem regisztrálva.')
        return
    end
    for dispatchId, dispatch in pairs(Config.DispatchLocations) do
        local npc = dispatch.npc
        exports['nxn-npcconversation']:registerNPC({
            id       = npc.id,
            model    = npc.model,
            coords   = dispatch.coords,
            scenario = npc.scenario,
            blip     = npc.blip,
            dialogs  = {
                {
                    id        = 'delivery_request_task',
                    label     = 'Feladat kérése',
                    icon      = 'hgi-package-01',
                    condition = function()
                        local job = getPlayerJob()
                        if not job or job.name ~= 'delivery' then return false end
                        if not isOnDutyLocal() then return false end
                        if localTask then return false end
                        return true
                    end,
                    action = function()
                        TriggerServerEvent('nxn-delivery:server:requestTask', dispatchId)
                    end,
                },
                {
                    id    = 'delivery_status',
                    label = 'Aktuális feladat',
                    icon  = 'hgi-task-01',
                    condition = function()
                        return localTask ~= nil
                    end,
                    action = function()
                        if localTask then
                            local timeLeft = math.max(0, localTask.timeLimit - (os.time() - localTask.startedAt))
                            TriggerEvent('chat:addMessage', {
                                args = { '[Szállítás]',
                                    ('Feladat: %s → %s | Jutalom: %d Ft | Hátralévő idő: %s'):format(
                                        localTask.label, localTask.target.label,
                                        localTask.reward, NXN.Delivery.FormatTime(timeLeft)) }
                            })
                        end
                    end,
                },
            },
        })
        NXN.Delivery.Log(('NPC regisztrálva: %s (%s)'):format(npc.id, dispatchId))
    end
end

-- ── Startup ───────────────────────────────────────────────────

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(1000)
    registerDispatchNPCs()
    if GetResourceState('nxn-loading') == 'started' then
        exports['nxn-loading']:updateModuleProgress('Szállítás', 100)
    end
    NXN.Delivery.Info('Client inicializálva.')
end)

-- ── Duty cache frissítése ─────────────────────────────────────

RegisterNetEvent('nxn-jobwork:client:clockedIn', function(job)
    if job == 'delivery' then
        onDutyCache = true
        jobCache    = job
    end
end)

RegisterNetEvent('nxn-jobwork:client:clockedOut', function(job)
    if job == 'delivery' then
        onDutyCache = false
        jobCache    = nil
    end
end)

-- ── Task net eventek ──────────────────────────────────────────

RegisterNetEvent('nxn-delivery:client:taskStarted', function(taskData)
    localTask = {
        taskId        = taskData.taskId,
        category      = taskData.category,
        label         = taskData.label,
        icon          = taskData.icon,
        target        = taskData.target,
        reward        = taskData.reward,
        timeLimit     = taskData.timeLimit,
        distanceM     = taskData.distanceM,
        startedAt     = os.time(),
        pickedUp      = false,
        dispatchCoords = taskData.dispatchCoords,
    }

    -- Pickup blip a diszpécsernél
    pickupBlip = createBlip(
        vector3(taskData.dispatchCoords.x, taskData.dispatchCoords.y, taskData.dispatchCoords.z),
        351, 3, 'Csomag felvétele', 0.8
    )

    showNUI({
        label     = taskData.label,
        icon      = taskData.icon,
        target    = taskData.target.label,
        reward    = taskData.reward,
        timeLimit = taskData.timeLimit,
        distanceM = math.floor(taskData.distanceM),
        bonus     = false,
    })

    NXN.Delivery.Log(('Feladat kapva: %s → %s'):format(taskData.label, taskData.target.label))
end)

RegisterNetEvent('nxn-delivery:client:taskCompleted', function(data)
    localTask = nil
    removeBlip(pickupBlip)
    removeBlip(dropoffBlip)
    pickupBlip  = nil
    dropoffBlip = nil
    hideNUI()
end)

RegisterNetEvent('nxn-delivery:client:taskFailed', function(data)
    localTask = nil
    removeBlip(pickupBlip)
    removeBlip(dropoffBlip)
    pickupBlip  = nil
    dropoffBlip = nil
    hideNUI()

    local msgs = {
        timeout  = 'Szállítás lejárt! Idő túllépve.',
        clockout = 'Műszak vége – feladat törölve.',
        cancelled= 'Szállítási feladatod törölve.',
    }
    local msg = msgs[data.reason] or 'Szállítás sikertelen.'
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:showNotify(msg, 'error')
    end
end)

-- ── Proximity loop (pickup + dropoff) ────────────────────────

CreateThread(function()
    while true do
        local sleep = 500
        if localTask then
            sleep = 0
            local playerCoords = GetEntityCoords(PlayerPedId())

            if not localTask.pickedUp then
                -- Pickup marker a dispatch közelében
                local pCoords = vector3(
                    localTask.dispatchCoords.x,
                    localTask.dispatchCoords.y,
                    localTask.dispatchCoords.z
                )
                local pDist = NXN.Delivery.Distance(playerCoords, pCoords)
                drawMarker(
                    Config.PickupMarkerType, pCoords, Config.MarkerSize,
                    Config.PickupColor.r, Config.PickupColor.g,
                    Config.PickupColor.b, Config.PickupColor.a
                )
                if pDist < Config.PickupDistance then
                    -- Hint szöveg
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('[E] Csomag felvétele')
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustReleased(0, 38) then  -- E
                        -- Animáció
                        local ped = PlayerPedId()
                        RequestAnimDict('anim@heists@box_carry@')
                        while not HasAnimDictLoaded('anim@heists@box_carry@') do Wait(10) end
                        TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 2.0, 2.0, 2000, 49, 0, false, false, false)
                        Wait(2000)
                        ClearPedTasks(ped)

                        localTask.pickedUp = true
                        TriggerServerEvent('nxn-delivery:server:pickupConfirmed', localTask.taskId)

                        -- Pickup blip eltűnik, dropoff blip megjelenik
                        removeBlip(pickupBlip)
                        pickupBlip = nil
                        dropoffBlip = createBlip(
                            localTask.target.coords,
                            478, 1, ('Szállítás: %s'):format(localTask.target.label), 0.9
                        )
                        SetBlipRoute(dropoffBlip, true)

                        if GetResourceState('nxn-notify') == 'started' then
                            exports['nxn-notify']:showNotify(
                                ('Csomag felvéve! Vidd el: %s'):format(localTask.target.label),
                                'success'
                            )
                        end
                    end
                end
            else
                -- Dropoff marker a célhelyen
                local dCoords = localTask.target.coords
                local dDist   = NXN.Delivery.Distance(playerCoords, dCoords)
                drawMarker(
                    Config.DropoffMarkerType, dCoords, Config.MarkerSize,
                    Config.DropoffColor.r, Config.DropoffColor.g,
                    Config.DropoffColor.b, Config.DropoffColor.a
                )
                if dDist < Config.DropoffDistance then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('[E] Csomag leadása')
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustReleased(0, 38) then  -- E
                        TriggerServerEvent('nxn-delivery:server:confirmDropoff', localTask.taskId)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ── NUI frissítő loop (5 mp-enként) ──────────────────────────

CreateThread(function()
    while true do
        Wait(5000)
        if localTask then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local targetCoords = localTask.target.coords
            local distToTarget = math.floor(NXN.Delivery.Distance(playerCoords, targetCoords))
            local elapsed      = os.time() - localTask.startedAt
            local timeLeft     = math.max(0, localTask.timeLimit - elapsed)
            local bonus        = timeLeft >= math.floor(localTask.timeLimit * 0.5)

            updateNUI({
                timeLeft      = timeLeft,
                distToTarget  = distToTarget,
                bonus         = bonus,
            })

            TriggerServerEvent('nxn-delivery:client:taskUpdate', {
                timeLeft     = timeLeft,
                distToTarget = distToTarget,
            })
        end
    end
end)

-- ── Exportok ──────────────────────────────────────────────────

exports('hasActiveTask', function() return localTask ~= nil end)
exports('getLocalTask',  function() return localTask        end)
