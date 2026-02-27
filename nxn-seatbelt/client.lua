-- ============================================================
--  nxn-seatbelt | client.lua
-- ============================================================

-- ── Állapot ──────────────────────────────────────────────────

local fastened        = false
local inVehicle       = false
local currentVehicle  = 0
local warnTimer       = 0.0
local warnPlaying     = false
local lastBlockNotify = 0

-- ── FiveM Control ID-k ───────────────────────────────────────
-- FIX: A korabbi kod 75 (INPUT_ENTER = E gomb) es 245 (INPUT_VEH_HORN =
--      dudagas) ID-kat hasznalta, egyik sem az F kiszallas gomb.
--      Helyes ID-k:
--        23  = INPUT_ENTER       (E gomb, jarmube szallas)
--        194 = INPUT_VEH_EXIT    (F gomb, kiszallas jarmubol)  <-- ez kell

local INPUT_VEH_ENTER = 23   -- E gomb
local INPUT_VEH_EXIT  = 194  -- F gomb

-- ── Billentyű regisztráció ───────────────────────────────────

RegisterKeyMapping('nxn_seatbelt_toggle', Config.ToggleKeyLabel, 'keyboard', Config.ToggleKey)

-- ── Notify ───────────────────────────────────────────────

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then
        NXN.Seatbelt.Warn(('Notify fallback: [%s] %s'):format(ntype or 'info', msg))
        return
    end
    local t = ntype or 'info'
    if     t == 'success' then exports['nxn-notify']:success(msg)
    elseif t == 'danger'  then exports['nxn-notify']:danger(msg)
    elseif t == 'warning' then exports['nxn-notify']:warning(msg)
    else                       exports['nxn-notify']:info(msg)
    end
end

-- ── HUD szinkron ───────────────────────────────────────────

local function SyncHUD()
    if GetResourceState('nxn-vehicle-hud') ~= 'started' then return end
    local modState = exports['nxn-vehicle-hud']:getModuleState('seatbelt')
    if modState == nil then
        exports['nxn-vehicle-hud']:setModule('seatbelt', true)
    end
    exports['nxn-vehicle-hud']:setSeatbelt(fastened)
    NXN.Seatbelt.Log(('HUD szinkron: fastened=%s'):format(tostring(fastened)))
end

-- ── Hang ─────────────────────────────────────────────────

local function StopWarningSound()
    if not warnPlaying then return end
    SendNUIMessage({ action = 'stopWarning' })
    warnPlaying = false
end

local function PlayWarningSound()
    if warnPlaying then return end
    warnPlaying = true
    SendNUIMessage({
        action = 'playWarning',
        file   = ('nui://%s/sounds/%s'):format(Config.ResourceName, Config.WarningSoundFile),
        volume = Config.WarningSoundVolume,
    })
end

-- ── Öv toggle ───────────────────────────────────────────────

local function SetFastened(state)
    if fastened == state then return end
    fastened = state
    NXN.Seatbelt.Log(('Ov: fastened=%s'):format(tostring(fastened)))
    if fastened then
        StopWarningSound()
        warnTimer = 0.0
        Notify(Config.Notify.fastened, 'success')
    else
        warnTimer = 0.0
        Notify(Config.Notify.unfastened, 'warning')
    end
    SyncHUD()
end

-- ── Command ────────────────────────────────────────────────

RegisterCommand('nxn_seatbelt_toggle', function()
    if not inVehicle then return end
    SetFastened(not fastened)
end, false)

-- ── Fő loop ─────────────────────────────────────────────────

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- Járműbe / kiszállás észlelés
        if veh ~= 0 and not inVehicle then
            inVehicle      = true
            currentVehicle = veh
            fastened       = false
            warnTimer      = 0.0
            StopWarningSound()
            SyncHUD()
            NXN.Seatbelt.Log(('Jarmube szallt: entId=%d'):format(veh))

        elseif veh == 0 and inVehicle then
            inVehicle      = false
            currentVehicle = 0
            fastened       = false
            warnTimer      = 0.0
            StopWarningSound()
            SyncHUD()
            NXN.Seatbelt.Log('Kiszallt')
        end

        -- Kiszállás blokkolása bekötött öv esetén
        -- FIX: IsControlJustPressed ELOBB fut, UTANA DisableControlAction.
        --      INPUT_VEH_EXIT = 194 (F gomb), INPUT_ENTER = 23 (E gomb).
        if inVehicle and fastened and Config.BlockExitWhenFastened then
            local now = GetGameTimer()

            -- 1. Először leolvassuk a gombnyomást
            local tryingToExit = IsControlJustPressed(0, INPUT_VEH_EXIT)
                              or IsControlJustPressed(0, INPUT_VEH_ENTER)

            -- 2. Utána tiltjuk le (ha előbb tiltjuk, JustPressed már false lesz)
            DisableControlAction(0, INPUT_VEH_EXIT,  true)
            DisableControlAction(0, INPUT_VEH_ENTER, true)

            -- 3. Értesítés spam-védelemmel (2 másodpercenként egyszer)
            if tryingToExit and (now - lastBlockNotify) > 2000 then
                lastBlockNotify = now
                Notify(Config.Notify.blocked, 'warning')
                NXN.Seatbelt.Log('Kiszallas blokkolva, ertesites kuldve')
            end
        end

        -- Figyelmezteto hang
        if inVehicle and not fastened then
            warnTimer = warnTimer + GetFrameTime()
            if warnTimer <= Config.WarningSoundDuration then
                local interval = Config.WarningSoundInterval
                local cycle    = math.floor(warnTimer / interval)
                local prev     = math.floor((warnTimer - GetFrameTime()) / interval)
                if cycle ~= prev then
                    PlayWarningSound()
                end
            elseif warnPlaying then
                StopWarningSound()
            end
        elseif warnPlaying then
            StopWarningSound()
        end

        -- Auto-kicsatolás sebesség felett
        if inVehicle and fastened and Config.AutoUnbuckleSpeedThreshold then
            local speed = GetEntitySpeed(currentVehicle) * 3.6
            if speed > Config.AutoUnbuckleSpeedThreshold then
                NXN.Seatbelt.Warn(('Auto-kicsatolas: %.1f km/h'):format(speed))
                SetFastened(false)
            end
        end

        if inVehicle then
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ── NUI callbacks ────────────────────────────────────────────

RegisterNUICallback('soundEnded', function(_, cb)
    warnPlaying = false
    cb('ok')
end)

-- ── Exportok ───────────────────────────────────────────────

exports('isFastened', function()
    return fastened
end)

exports('setFastened', function(state)
    SetFastened(state)
end)

exports('isInVehicle', function()
    return inVehicle
end)

exports('fasten', function()
    SetFastened(true)
end)

exports('unfasten', function()
    SetFastened(false)
end)

exports('playWarning', function()
    if inVehicle and not fastened then
        warnPlaying = false
        PlayWarningSound()
    end
end)
