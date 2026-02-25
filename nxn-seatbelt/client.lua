-- ============================================================
--  nxn-seatbelt | client.lua
-- ============================================================

-- ── Allapot ─────────────────────────────────────────────────

local fastened        = false
local inVehicle       = false
local currentVehicle  = 0
local warnTimer       = 0.0
local warnPlaying     = false
local lastBlockNotify = 0

-- ── Billentyu regisztracio ───────────────────────────────────
-- RegisterKeyMapping: jatekos az esc > keybinds menuben atallithatja

RegisterKeyMapping('nxn_seatbelt_toggle', Config.ToggleKeyLabel, 'keyboard', Config.ToggleKey)

-- ── Segd: nxn-notify ─────────────────────────────────────────
-- FIX: exports['nxn-notify']:send() nem letezik
-- Helyes exportok: notify(msg, type, duration, title)
-- vagy tipusos shorthandek: info / success / danger / warning

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then
        NXN.Seatbelt.Warn(('Notify fallback: [%s] %s'):format(ntype or 'info', msg))
        return
    end
    local t = ntype or 'info'
    NXN.Seatbelt.Log(('Notify: type=%s msg=%s'):format(t, msg))
    -- notify(msg, type, duration, title) – az nxn-notify altalanos exportja
    exports['nxn-notify']:notify(msg, t)
end

-- ── Segd: nxn-vehicle-hud szinkron ──────────────────────────

local function SyncHUD()
    if GetResourceState('nxn-vehicle-hud') ~= 'started' then return end
    local modState = exports['nxn-vehicle-hud']:getModuleState('seatbelt')
    if modState == nil then
        exports['nxn-vehicle-hud']:setModule('seatbelt', true)
        NXN.Seatbelt.Log('nxn-vehicle-hud seatbelt modul bekapcsolva')
    end
    exports['nxn-vehicle-hud']:setSeatbelt(fastened)
    NXN.Seatbelt.Log(('HUD szinkron: fastened=%s'):format(tostring(fastened)))
end

-- ── Hang kezeles ─────────────────────────────────────────────

local function StopWarningSound()
    if not warnPlaying then return end
    SendNUIMessage({ action = 'stopWarning' })
    warnPlaying = false
    NXN.Seatbelt.Log('Figyelmezteto hang leallitva')
end

local function PlayWarningSound()
    if warnPlaying then return end
    warnPlaying = true
    NXN.Seatbelt.Log('Figyelmezteto hang lejatszasa')
    SendNUIMessage({
        action = 'playWarning',
        file   = ('nui://%s/sounds/%s'):format(Config.ResourceName, Config.WarningSoundFile),
        volume = Config.WarningSoundVolume,
    })
end

-- ── Ov toggle ────────────────────────────────────────────────

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

-- ── Billentyu command ─────────────────────────────────────────
-- RegisterKeyMapping-hez RegisterCommand kell parban

RegisterCommand('nxn_seatbelt_toggle', function()
    if not inVehicle then return end
    NXN.Seatbelt.Log('Toggle gomb megnyomva')
    SetFastened(not fastened)
end, false)

-- ── Fo loop ──────────────────────────────────────────────────

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- ── Jarmube szallas / kiszallas eszleles ───────────────
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
            NXN.Seatbelt.Log('Kiszallt, ov visszaallitva')
        end

        -- ── Kiszallas blokkolasa (frame-folytonos) ─────────────
        if inVehicle and fastened and Config.BlockExitWhenFastened then
            DisableControlAction(0, 75, true)   -- INPUT_ENTER
            DisableControlAction(0, 245, true)  -- INPUT_VEH_EXIT

            local now = GetGameTimer()
            if IsControlJustPressed(0, 75) or IsControlJustPressed(0, 245) then
                if (now - lastBlockNotify) > 2000 then
                    lastBlockNotify = now
                    Notify(Config.Notify.blocked, 'danger')
                    NXN.Seatbelt.Log('Kiszallas blokkolva')
                end
            end
        end

        -- ── Figyelmezteto hang ─────────────────────────────────
        if inVehicle and not fastened then
            warnTimer = warnTimer + GetFrameTime()

            if warnTimer <= Config.WarningSoundDuration then
                local interval = Config.WarningSoundInterval
                local cycle    = math.floor(warnTimer / interval)
                local prev     = math.floor((warnTimer - GetFrameTime()) / interval)
                if cycle ~= prev then
                    PlayWarningSound()
                    NXN.Seatbelt.Log(('Hang kivaltas: warnTimer=%.1f'):format(warnTimer))
                end
            elseif warnPlaying then
                StopWarningSound()
                NXN.Seatbelt.Log('Figyelmeztetes lejart')
            end
        elseif warnPlaying then
            StopWarningSound()
        end

        -- ── Auto-kicsatolas ────────────────────────────────────
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

-- ── NUI callbacks ─────────────────────────────────────────────

RegisterNUICallback('soundEnded', function(_, cb)
    warnPlaying = false
    NXN.Seatbelt.Log('NUI: hang vege')
    cb('ok')
end)

-- ── Exportok ─────────────────────────────────────────────────

exports('isFastened', function()
    return fastened
end)

exports('setFastened', function(state)
    NXN.Seatbelt.Log(('setFastened export: %s'):format(tostring(state)))
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
