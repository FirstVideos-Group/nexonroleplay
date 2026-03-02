-- ============================================================
--  nxn-cartheft | client.lua
-- ============================================================

-- ── Állapot ────────────────────────────────────────────────
local isBreaking    = false
local breakingVeh   = 0
local breakingPlate = ''
local propHandle    = 0
local promptActive  = false

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

-- GetEntityCoords() FiveM-ben vector3 típusú értéket ad vissza, nem 3 külön számot.
-- A korábbi "local vx, vy, vz = GetEntityCoords(veh)" formában vx a teljes vector3
-- objektum lett, vy és vz nil — ez okozta a "bad argument #2 to vector3
-- (invalid vector dimensions)" crash-t. Javítás: közvetlen vector3 változó használat.
local function GetClosestLockedVehicle(maxDist)
    local ped  = PlayerPedId()
    local pPos = GetEntityCoords(ped)
    local closest, closestDist = 0, maxDist
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if GetPedInVehicleSeat(veh, -1) ~= ped then
            local vPos = GetEntityCoords(veh)
            local d = #(pPos - vPos)
            if d < closestDist then
                closest     = veh
                closestDist = d
            end
        end
    end
    return closest
end

local function IsVehicleLocked(veh)
    local state = GetVehicleDoorLockStatus(veh)
    return state >= 2
end

local function AttachProp()
    if not Config.BreakInProp.enabled then return end
    local model = GetHashKey(Config.BreakInProp.model)
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) and t < 40 do
        Wait(50); t = t + 1
    end
    if not HasModelLoaded(model) then return end
    local ped = PlayerPedId()
    propHandle = CreateModelSwapObject(model, 0, 0.0, 0.0, 0.0, true)
    AttachEntityToEntity(
        propHandle, ped,
        GetPedBoneIndex(ped, Config.BreakInProp.bone),
        Config.BreakInProp.offset.x, Config.BreakInProp.offset.y, Config.BreakInProp.offset.z,
        Config.BreakInProp.rot.x,    Config.BreakInProp.rot.y,    Config.BreakInProp.rot.z,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(model)
end

local function DetachProp()
    if propHandle ~= 0 and DoesEntityExist(propHandle) then
        DetachEntity(propHandle, true, true)
        DeleteEntity(propHandle)
        propHandle = 0
    end
end

local function PlayBreakInAnim()
    if not Config.BreakInAnim.enabled then return end
    local dict = Config.BreakInAnim.dict
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 30 do
        Wait(50); t = t + 1
    end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(PlayerPedId(), dict, Config.BreakInAnim.name,
            3.0, 3.0, Config.BreakInAnim.duration, 1, 0, false, false, false)
    end
end

local function StopBreakInAnim()
    if Config.BreakInAnim.enabled then
        ClearPedTasks(PlayerPedId())
    end
end

local function ResetState()
    isBreaking    = false
    breakingVeh   = 0
    breakingPlate = ''
    StopBreakInAnim()
    DetachProp()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setVisible', visible = false })
end

-- ── Feltörés indítása ──────────────────────────────────────────

local function StartBreakIn(veh)
    if isBreaking then return end
    local plate = NXN.CarTheft.NormalizePlate(GetVehicleNumberPlateText(veh))
    if plate == '' then return end

    if not IsVehicleLocked(veh) then
        Notify('Ez a jármű nincs lezárva!', 'warning')
        return
    end

    isBreaking    = true
    breakingVeh   = veh
    breakingPlate = plate

    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent('nxn-cartheft:server:startAttempt', plate, netId)
end

exports('startBreakIn', function(veh)
    StartBreakIn(veh)
end)

exports('isBreakingIn', function()
    return isBreaking
end)

exports('cancelBreakIn', function()
    if isBreaking then
        ResetState()
        Notify('Feltörés megszakítva.', 'warning')
    end
end)

-- ── KözelSég detekció loop ───────────────────────────────────────

CreateThread(function()
    while true do
        Wait(500)
        if not isBreaking then
            local veh = GetClosestLockedVehicle(Config.InteractDistance)
            if veh ~= 0 and IsVehicleLocked(veh) then
                if not promptActive then
                    promptActive = true
                end
                local plate = NXN.CarTheft.NormalizePlate(GetVehicleNumberPlateText(veh))
            else
                if promptActive then promptActive = false end
            end
        end
    end
end)

-- ── Prompt + gomb loop ─────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        if not isBreaking then
            local veh = GetClosestLockedVehicle(Config.InteractDistance)
            if veh ~= 0 and IsVehicleLocked(veh) then
                local x, y, z = GetEntityCoords(veh)
                SetTextFont(4)
                SetTextProportional(true)
                SetTextScale(0.0, 0.45)
                SetTextColour(255, 255, 255, 210)
                SetTextOutline()
                SetTextEntry('STRING')
                AddTextComponentString(('[%s] Feltörés'):format(Config.InteractKeyLabel))
                DrawText(0.5, 0.9)

                if IsControlJustPressed(0, Config.InteractKey) and not isBreaking then
                    StartBreakIn(veh)
                end
            end
        end

        if isBreaking then
            if IsControlJustPressed(0, 200) then
                exports['nxn-cartheft']:cancelBreakIn()
            end
        end
    end
end)

-- ── Net Events (kliens) ────────────────────────────────────────

RegisterNetEvent('nxn-cartheft:client:attemptAllowed', function(data)
    if not data.ok then
        isBreaking = false
        Notify(data.reason or 'Nem kezdheted el a feltörést!', 'danger')
        return
    end

    PlayBreakInAnim()
    AttachProp()

    local mgType = Config.DefaultMinigame
    if mgType == 'random' then
        mgType = math.random(2) == 1 and 'lockpick' or 'keypad'
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'setVisible',
        visible  = true,
        minigame = mgType,
        config   = {
            lockpick = Config.Lockpick,
            keypad   = {
                sequenceLength = Config.Keypad.sequenceLength,
                showTime       = Config.Keypad.showTime,
                inputTime      = Config.Keypad.inputTime,
                symbols        = Config.Keypad.symbols,
            },
        },
    })
end)

RegisterNetEvent('nxn-cartheft:client:doUnlock', function(data)
    local veh = NetworkGetEntityFromNetworkId(tonumber(data.vehicleNetId) or 0)
    if not DoesEntityExist(veh) then return end
    if GetResourceState('nxn-engine') == 'started' then
        exports['nxn-engine']:setLocked(false)
    end
    SetVehicleDoorsLocked(veh, 1)
    CreateThread(function()
        Wait(400)
        TaskEnterVehicle(PlayerPedId(), veh, 10000, -1, 2.0, 1, 0)
    end)
end)

RegisterNetEvent('nxn-cartheft:client:forceLock', function(data)
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local p = NXN.CarTheft.NormalizePlate(GetVehicleNumberPlateText(veh))
        if p == data.plate then
            SetVehicleDoorsLocked(veh, 2)
            if GetResourceState('nxn-engine') == 'started' then
                exports['nxn-engine']:setLocked(true)
            end
            break
        end
    end
end)

-- ── NUI Callbacks ──────────────────────────────────────────────

RegisterNUICallback('minigameResult', function(data, cb)
    local success = data.success == true
    local netId   = breakingVeh ~= 0 and NetworkGetNetworkIdFromEntity(breakingVeh) or 0

    StopBreakInAnim()
    DetachProp()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setVisible', visible = false })

    TriggerServerEvent('nxn-cartheft:server:attemptResult', breakingPlate, success, netId)

    if success then
        Notify('Sikeresen feltörve – ' .. breakingPlate .. '!', 'success')
    else
        Notify('Sikertelen feltörés!', 'danger')
    end

    isBreaking    = false
    breakingVeh   = 0
    breakingPlate = ''
    cb('ok')
end)

RegisterNUICallback('cancel', function(_, cb)
    ResetState()
    cb('ok')
end)
