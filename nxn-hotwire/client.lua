-- ============================================================
--  nxn-hotwire | client.lua
-- ============================================================

-- ── Állapot ────────────────────────────────────────────────
local isHotwiring   = false
local hotwireVeh    = 0
local hotwirePlate  = ''

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

local function PlayHotwireAnim()
    if not Config.HotwireAnim.enabled then return end
    local dict = Config.HotwireAnim.dict
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 30 do
        Wait(50); t = t + 1
    end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(PlayerPedId(), dict, Config.HotwireAnim.name,
            3.0, 3.0, -1, 1, 0, false, false, false)
    end
end

local function StopHotwireAnim()
    if Config.HotwireAnim.enabled then
        ClearPedTasks(PlayerPedId())
    end
end

local function ResetState()
    isHotwiring  = false
    hotwireVeh   = 0
    hotwirePlate = ''
    StopHotwireAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setVisible', visible = false })
end

-- ── Hotwire indítása ───────────────────────────────────────

local function StartHotwire(veh)
    if isHotwiring then return end

    local ped = PlayerPedId()
    if not IsPedInVehicle(ped, veh, false) then
        Notify('Kell lenned a járműben!', 'warning')
        return
    end

    -- Vezető ülésben kell lenni
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        Notify('A vezétő ülésbe kell ülés a hotwire-hoz!', 'warning')
        return
    end

    local plate = NXN.Hotwire.NormalizePlate(GetVehicleNumberPlateText(veh))
    if plate == '' then return end

    -- Van-e kulcsa?
    if GetResourceState('nxn-keys') == 'started' then
        if exports['nxn-keys']:hasKeyForPlate(plate) then
            Notify('Van kulcsod a járműhöz – használd azt!', 'warning')
            return
        end
    end

    -- Motor HP előellenőrzés
    if GetResourceState('nxn-engine') == 'started' then
        local hp = exports['nxn-engine']:getEngineHP(plate)
        if type(hp) == 'number' and hp < Config.MinEngineHP then
            Notify('A motor túll súlyosan sérült a hotwire-hoz!', 'danger')
            return
        end
    end

    isHotwiring  = true
    hotwireVeh   = veh
    hotwirePlate = plate

    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent('nxn-hotwire:server:startAttempt', plate, netId)
end

exports('startHotwire', function(veh)
    StartHotwire(veh)
end)

exports('isHotwiring', function()
    return isHotwiring
end)

exports('cancelHotwire', function()
    if isHotwiring then
        ResetState()
        Notify('Hotwire megszakítva.', 'warning')
    end
end)

-- ── Gomb loop ([H] gomb) ───────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and not isHotwiring then
            local plate = NXN.Hotwire.NormalizePlate(GetVehicleNumberPlateText(veh))

            -- Csak ha nem tulajdonos és nincs kulcsa (UI prompt)
            local showPrompt = true
            if GetResourceState('nxn-keys') == 'started' then
                if exports['nxn-keys']:hasKeyForPlate(plate) then
                    showPrompt = false
                end
            end

            if showPrompt and IsControlJustPressed(0, Config.InteractKey) then
                StartHotwire(veh)
            end

            -- Prompt szöveg megjelenítése
            if showPrompt then
                SetTextFont(4)
                SetTextProportional(true)
                SetTextScale(0.0, 0.45)
                SetTextColour(255, 255, 255, 210)
                SetTextOutline()
                SetTextEntry('STRING')
                AddTextComponentString(('[%s] Hotwire'):format(Config.InteractKeyLabel))
                DrawText(0.5, 0.93)
            end
        end

        -- ESC megszakítás
        if isHotwiring and IsControlJustPressed(0, 200) then
            exports['nxn-hotwire']:cancelHotwire()
        end
    end
end)

-- ── Net Events (kliens) ────────────────────────────────────

-- Szerver vissza: engedélyezett-e
RegisterNetEvent('nxn-hotwire:client:attemptAllowed', function(data)
    if not data.ok then
        isHotwiring = false
        Notify(data.reason or 'Nem kezdheted el a hotwire-t!', 'danger')
        return
    end

    -- Animáció
    PlayHotwireAnim()

    -- NUI megnyitása
    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'setVisible',
        visible  = true,
        minigame = data.minigame or 'wirechoice',
        config   = {
            wirechoice = Config.WireChoice,
            sequence   = Config.Sequence,
        },
    })
end)

-- Sikeres hotwire
RegisterNetEvent('nxn-hotwire:client:hotwireSuccess', function(data)
    StopHotwireAnim()
    Notify('Motor beindult – ' .. (data.plate or '') .. '!', 'success')
    isHotwiring  = false
    hotwireVeh   = 0
    hotwirePlate = ''
end)

-- Sikertelen hotwire
RegisterNetEvent('nxn-hotwire:client:hotwireFailed', function(data)
    StopHotwireAnim()
    local msg = data.reason or 'Sikertelen hotwire!'
    if data.damageApplied then
        msg = msg .. ' (Motor sérült!)'
    end
    Notify(msg, 'danger')
    isHotwiring  = false
    hotwireVeh   = 0
    hotwirePlate = ''
end)

-- ── NUI Callbacks ──────────────────────────────────────────

RegisterNUICallback('minigameResult', function(data, cb)
    local success  = data.success == true
    local shock    = data.shock   == true
    local mgType   = data.minigame or 'wirechoice'
    local netId    = hotwireVeh ~= 0 and NetworkGetNetworkIdFromEntity(hotwireVeh) or 0
    local plate    = hotwirePlate

    StopHotwireAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setVisible', visible = false })

    TriggerServerEvent('nxn-hotwire:server:attemptResult', plate, success, netId, mgType)

    -- Áramtolás vizualis visszajelzés
    if shock then
        Notify('Megrázott az áram! (Motor sérült)', 'danger')
    end

    isHotwiring  = false
    hotwireVeh   = 0
    hotwirePlate = ''
    cb('ok')
end)

RegisterNUICallback('cancel', function(_, cb)
    ResetState()
    cb('ok')
end)
