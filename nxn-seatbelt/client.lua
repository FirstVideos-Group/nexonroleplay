-- ============================================================
--  nxn-seatbelt | client.lua
-- ============================================================

-- ── Allapot ──────────────────────────────────────────────────

local fastened       = false   -- ov be van-e kotve
local inVehicle      = false
local currentVehicle = 0
local warnTimer      = 0       -- figyelmeztetes idozito (masodperc)
local warnPlaying    = false
local soundObj       = nil     -- aktiv hang objektum

-- ── Segéd: nxn-notify integráció ──────────────────────────────

---@param msg   string
---@param ntype string   'info'|'success'|'danger'|'warning'
local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:send(msg, ntype or 'info')
    else
        NXN.Seatbelt.Warn(('Notify (fallback): [%s] %s'):format(ntype or 'info', msg))
    end
end

-- ── Segéd: nxn-vehicle-hud frissités ─────────────────────────

local function SyncHUD()
    if GetResourceState('nxn-vehicle-hud') == 'started' then
        exports['nxn-vehicle-hud']:setSeatbelt(fastened)
        NXN.Seatbelt.Log(('HUD szinkron: fastened=%s'):format(tostring(fastened)))
    end
end

-- ── Hang kezeles ──────────────────────────────────────────────

local function StopWarningSound()
    if soundObj then
        soundObj:destroy()
        soundObj = nil
    end
    warnPlaying = false
    NXN.Seatbelt.Log('Figyelmezteto hang leallitva')
end

local function PlayWarningSound()
    if warnPlaying then return end
    warnPlaying = true
    NXN.Seatbelt.Log('Figyelmezteto hang lejatszas inditva')
    -- GTA natív SendSoundFrontend / SendSoundFrontendForPed
    -- Mivel egyedi .ogg fajlt hasznalunk, NUI audio pipeline-on jatszuk le
    SendNUIMessage({
        action = 'playWarning',
        file   = ('nui://%s/sounds/%s'):format(Config.ResourceName, Config.WarningSoundFile),
        volume = Config.WarningSoundVolume,
    })
end

-- ── Ov toggle ─────────────────────────────────────────────────

local function SetFastened(state)
    if fastened == state then return end
    fastened = state
    NXN.Seatbelt.Log(('Ov allapot: fastened=%s'):format(tostring(fastened)))

    if fastened then
        -- Bekotve: hang leall, warnTimer reset
        StopWarningSound()
        warnTimer = 0
        Notify(Config.Notify.fastened, 'success')
    else
        -- Kicsatolva: warnTimer indul
        warnTimer = 0
        Notify(Config.Notify.unfastened, 'warning')
    end

    SyncHUD()
end

-- ── Kiszallas blokkolasa ──────────────────────────────────────

local function BlockVehicleExit()
    if fastened and Config.BlockExitWhenFastened then
        DisableControlAction(0, 75, true)   -- Enter/Exit vehicle
        DisableControlAction(27, 75, true)
        Notify(Config.Notify.blocked, 'danger')
        NXN.Seatbelt.Log('Kiszallas blokkolva (ov be van kotve)')
    end
end

-- ── Fő loop: jarmueészleles + ov reset + hang ─────────────────

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- ── Jarmube szallas / kiszallas eszleles ──────────────
        if veh ~= 0 and not inVehicle then
            inVehicle      = true
            currentVehicle = veh
            fastened       = false   -- uj jarmube szallasnal mindig kicsatolva
            warnTimer      = 0
            StopWarningSound()
            SyncHUD()
            NXN.Seatbelt.Log(('Jarmube szallt: entId=%d'):format(veh))

        elseif veh == 0 and inVehicle then
            inVehicle      = false
            currentVehicle = 0
            fastened       = false
            warnTimer      = 0
            StopWarningSound()
            SyncHUD()
            NXN.Seatbelt.Log('Kiszallt a jarmubol, ov visszaallitva')
        end

        -- ── Bekotott ov: kiszallas blokkolasa ─────────────────
        if inVehicle and fastened and Config.BlockExitWhenFastened then
            local exitControl = IsControlJustPressed(0, 75)
            if exitControl then
                DisableControlAction(0, 75, true)
                Notify(Config.Notify.blocked, 'danger')
                NXN.Seatbelt.Log('Kiszallas blokkolva')
            end
        end

        -- ── Figyelmezteto hang ────────────────────────────────
        if inVehicle and not fastened then
            warnTimer = warnTimer + (GetFrameTime())

            -- Minden Config.WarningSoundInterval masodpercben szol, Config.WarningSoundDuration-ig
            if warnTimer <= Config.WarningSoundDuration then
                local interval = Config.WarningSoundInterval
                local cycle    = math.floor(warnTimer / interval)
                local prev     = math.floor((warnTimer - GetFrameTime()) / interval)

                if cycle ~= prev then
                    PlayWarningSound()
                    NXN.Seatbelt.Log(('Hang kivaltas: warnTimer=%.1f'):format(warnTimer))
                end
            elseif warnPlaying then
                -- Lejar a figyelmeztetes
                StopWarningSound()
                NXN.Seatbelt.Log('Figyelmeztetes lejart, hang leall')
            end
        end

        -- ── Toggle gomb ───────────────────────────────────────
        if inVehicle and IsControlJustReleased(0, Config.ToggleKey) then
            SetFastened(not fastened)
        end

        -- ── Auto-kicsatolas sebesseg felett ───────────────────
        if inVehicle and fastened and Config.AutoUnbuckleSpeedThreshold then
            local speed = GetEntitySpeed(currentVehicle) * 3.6  -- m/s -> km/h
            if speed > Config.AutoUnbuckleSpeedThreshold then
                NXN.Seatbelt.Warn(('Auto-kicsatolas: sebesseg=%.1f km/h'):format(speed))
                SetFastened(false)
            end
        end
    end
end)

-- ── NUI callbacks ─────────────────────────────────────────────

-- Hang vege jelzes (NUI kuldhet vissza ha lejatszodott)
RegisterNUICallback('soundEnded', function(_, cb)
    warnPlaying = false
    NXN.Seatbelt.Log('NUI: figyelmezteto hang vege')
    cb('ok')
end)

-- ── Exportok ──────────────────────────────────────────────────

--- Ov jelenlegi allapota
---@return boolean
exports('isFastened', function()
    return fastened
end)

--- Ov allapotat kulsoleg allitja be (pl. traffipax, mentes/betoltes)
---@param state boolean
exports('setFastened', function(state)
    NXN.Seatbelt.Log(('setFastened (export): %s'):format(tostring(state)))
    SetFastened(state)
end)

--- Jatekos jarmube van-e (seatbelt kontextus)
---@return boolean
exports('isInVehicle', function()
    return inVehicle
end)

--- Ov bekotese (shorthand)
exports('fasten', function()
    SetFastened(true)
end)

--- Ov kicsatolasa (shorthand)
exports('unfasten', function()
    SetFastened(false)
end)

--- Figyelmezteto hang manualis kenyszerlejatszasa
exports('playWarning', function()
    if inVehicle and not fastened then
        warnPlaying = false  -- reset hogy ujra szoljon
        PlayWarningSound()
    end
end)
