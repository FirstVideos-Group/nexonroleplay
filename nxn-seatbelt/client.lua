-- ============================================================
--  nxn-seatbelt | client.lua
--  Biztonsagi ov logika, hang, HUD kommunikacio, export API
-- ============================================================

-- ── Allapot ───────────────────────────────────────────────────

local isBuckled       = false    -- jelenlegi ov allapot
local inVehicle       = false    -- benne van-e jarmube
local reminderActive  = false    -- szol-e most az emlekeztető hang
local reminderTimer   = 0        -- mennyi ideig szolt mar (sec)
local reminderThread  = nil      -- coroutine referencia
local soundHandle     = nil      -- aktiv hang handle
local forceState      = nil      -- kulso feluliras (export)
local lastVehicle     = 0        -- utolso jarmU handle

-- ── Belso segédfüggvények ────────────────────────────────────

local function NUISend(action, data)
    local payload = data or {}
    payload.action = action
    SendNUIMessage(payload)
end

--- nxn-notify exporton keresztul ertesites
---@param msg string
---@param ntype string  'info'|'success'|'danger'|'warning'
local function Notify(msg, ntype)
    NXN.Belt.Log(('Notify: [%s] %s'):format(ntype or 'info', msg))
    -- nxn-notify integracioval
    local ok, err = pcall(function()
        exports['nxn-notify']:sendNotification({
            message = msg,
            type    = ntype or 'info',
        })
    end)
    if not ok then
        -- Fallback: NUI sajat ertesites
        NUISend('notify', { message = msg, ntype = ntype or 'info' })
        NXN.Belt.Warn('nxn-notify nem elerheto, fallback NUI notify hasznalva')
    end
end

--- HUD allapot kuldese az nxn-hud resource-nak
local function BroadcastHudState()
    local state = {
        buckled   = isBuckled,
        inVehicle = inVehicle,
    }
    -- NUI-on keresztul (ha a HUD NUI-ban van)
    NUISend('hudUpdate', state)
    -- nxn-hud export hivasa ha letezik
    pcall(function()
        exports['nxn-hud']:setSeatbelt(isBuckled)
    end)
    -- Globalis event mas resource-oknak (pl. traffipax)
    TriggerEvent('nxn-seatbelt:stateChanged', {
        buckled   = isBuckled,
        inVehicle = inVehicle,
        source    = 'local',
    })
    NXN.Belt.Log(('HUD broadcast: buckled=%s inVehicle=%s'):format(
        tostring(isBuckled), tostring(inVehicle)
    ))
end

-- ── Hang kezelés ─────────────────────────────────────────────

local function StopReminder()
    if reminderActive then
        NUISend('stopSound', {})
        reminderActive = false
        reminderTimer  = 0
        NXN.Belt.Log('Hang emlekeztető leallitva')
    end
end

local function StartReminder()
    if reminderActive then return end
    if isBuckled then return end
    reminderActive = true
    reminderTimer  = 0
    NXN.Belt.Log('Hang emlekeztető inditva')
    NUISend('playSound', { src = Config.ReminderSound })

    -- Idő limit thread
    CreateThread(function()
        local maxTime = Config.ReminderInterval
        while reminderActive do
            Wait(1000)
            reminderTimer = reminderTimer + 1
            if maxTime > 0 and reminderTimer >= maxTime then
                NXN.Belt.Log(('Emlekeztető leallt: %d sec eltelt'):format(reminderTimer))
                StopReminder()
                break
            end
            -- Ha kozben bekototte, all le
            if isBuckled or not inVehicle then
                StopReminder()
                break
            end
        end
    end)
end

-- ── Ov toggle ─────────────────────────────────────────────────

local function SetBuckled(state)
    if isBuckled == state then return end
    isBuckled = state
    NXN.Belt.Log(('Ov allapot: %s'):format(state and 'BEKOTVE' or 'KICSATOLVA'))

    if state then
        StopReminder()
        if Config.NotifyOnBuckle then
            Notify('Biztonsagi öv bekotve.', 'success')
        end
    else
        if Config.NotifyOnUnbuckle then
            Notify('Biztonsagi öv kicsatolva.', 'warning')
        end
        -- Kezdi a hangot hamarosan
        if inVehicle then
            CreateThread(function()
                Wait(Config.ReminderDelay * 1000)
                if not isBuckled and inVehicle then
                    StartReminder()
                end
            end)
        end
    end

    -- UI frissites
    NUISend('setState', { buckled = isBuckled })
    BroadcastHudState()

    -- Szerver ertesites
    TriggerServerEvent('nxn-seatbelt:server:stateChanged', isBuckled)
end

local function ToggleBuckle()
    if not inVehicle then return end
    -- Kulso feluliras figyelembvetele
    if forceState ~= nil then
        NXN.Belt.Warn('Toggle blokkalva: forceState aktiv')
        return
    end
    SetBuckled(not isBuckled)
end

-- ── Jarmube szallas / kiszallas esemeny ─────────────────────────

local function OnEnterVehicle(vehicle)
    inVehicle   = true
    lastVehicle = vehicle
    -- Jarmu tipus szures (ha be van allitva)
    if Config.VehicleTypes then
        local vClass = GetVehicleClass(vehicle)
        local allowed = false
        for _, cls in ipairs(Config.VehicleTypes) do
            if cls == vClass then allowed = true; break end
        end
        if not allowed then
            NXN.Belt.Log(('JarmuOsztaly (%d) nem vonatkozik ra, skip'):format(vClass))
            inVehicle = false
            return
        end
    end

    -- Alapertelmezetten kicsatolt ov
    isBuckled = false
    NXN.Belt.Log(('Jarmube szallt: handle=%d'):format(vehicle))

    NUISend('setState', { buckled = false })
    BroadcastHudState()

    -- Emlekeztető hang indulasa kesleltetve
    CreateThread(function()
        Wait(Config.ReminderDelay * 1000)
        if not isBuckled and inVehicle then
            StartReminder()
        end
    end)
end

local function OnExitVehicle()
    if not inVehicle then return end
    NXN.Belt.Log('Kiszallt a jarmubol')
    StopReminder()
    inVehicle   = false
    isBuckled   = false
    lastVehicle = 0
    forceState  = nil
    NUISend('setState', { buckled = false, inVehicle = false })
    BroadcastHudState()
end

-- ── Fo loop ─────────────────────────────────────────────────────

CreateThread(function()
    local wasInVehicle = false
    while true do
        Wait(300)

        local ped       = PlayerPedId()
        local veh       = GetVehiclePedIsIn(ped, false)
        local nowInVeh  = veh ~= 0 and IsPedInAnyVehicle(ped, false)

        -- Jarmube szallt
        if nowInVeh and not wasInVehicle then
            OnEnterVehicle(veh)
        end

        -- Kiszallt
        if not nowInVeh and wasInVehicle then
            OnExitVehicle()
        end

        wasInVehicle = nowInVeh

        -- Kiszallas blokkolasa bekotott ovnel
        if Config.BlockExitIfBuckled and nowInVeh and isBuckled then
            if IsControlJustReleased(0, 75) then  -- F kiszallas gomb
                Notify('Csatold ki az övet kiszallas előtt!', 'warning')
                NXN.Belt.Log('Kiszallas blokkalva: ov bekotve')
            end
            -- Kiszallas tenylegesen megakadalyozva
            DisableControlAction(0, 75, true)
        end

        -- Toggle gomb
        if nowInVeh and IsControlJustReleased(0, Config.ToggleKey) then
            ToggleBuckle()
        end
    end
end)

-- HUD periodikus frissites (pl. ha a HUD kesobb indul)
CreateThread(function()
    while true do
        Wait(Config.HudUpdateInterval)
        if inVehicle then
            BroadcastHudState()
        end
    end
end)

-- ── Net events ──────────────────────────────────────────────

-- Szerver kérhet ovcsere-t (pl. jatekvezetoi parancs)
RegisterNetEvent('nxn-seatbelt:client:forceState')
AddEventHandler('nxn-seatbelt:client:forceState', function(state)
    NXN.Belt.Log(('Server forceState: %s'):format(tostring(state)))
    SetBuckled(state)
end)

-- ── Exportok ───────────────────────────────────────────────

--- Jelenlegi ov allapot lekerdezese
--- Traffipax, rendorsegi rendszer hasznalhatja
---@return boolean
exports('isBuckled', function()
    return isBuckled
end)

--- Jarmube van-e
---@return boolean
exports('isInVehicle', function()
    return inVehicle
end)

--- Ov allapot kenyszer-beallitasa kulso resource-bol
---@param state boolean
exports('setBuckled', function(state)
    NXN.Belt.Log(('setBuckled export: %s'):format(tostring(state)))
    SetBuckled(state)
end)

--- Ov lock: megakadalyozza a jatekos altal valo valtoztatast
---@param state boolean  true=lock, false=unlock
exports('lockBelt', function(state)
    forceState = state and true or nil
    NXN.Belt.Log(('lockBelt: %s'):format(tostring(state)))
end)

--- Hang emlekeztető manualisan inditasa/megallitasa
---@param state boolean
exports('setReminderActive', function(state)
    if state then
        StartReminder()
    else
        StopReminder()
    end
end)

--- Aktualis jarmU handle (0 ha nem jarmUban)
---@return number
exports('getCurrentVehicle', function()
    return lastVehicle
end)
