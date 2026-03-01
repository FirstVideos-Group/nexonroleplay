-- ============================================================
--  nxn-seatbelt | client.lua
-- ============================================================

-- ── Állapot ──────────────────────────────────────────────────────

local fastened        = false
local inVehicle       = false
local currentVehicle  = 0
local warnPlaying     = false
local lastBlockNotify = 0

-- #93: GetGameTimer()-alapú abszolút időmérés a float drift helyétt
-- warnStartTime: mikor kapcsolt be a figyelmeztető hang (ms), nil = nem fut
local warnStartTime   = nil

-- ── FiveM Control ID-k ─────────────────────────────────────────

local INPUT_VEH_ENTER = 23   -- E gomb
local INPUT_VEH_EXIT  = 194  -- F gomb

-- ── Billentyű regisztráció ──────────────────────────────────────

RegisterKeyMapping('nxn_seatbelt_toggle', Config.ToggleKeyLabel, 'keyboard', Config.ToggleKey)

-- ── Notify ───────────────────────────────────────────────────

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

-- ── HUD szinkron ──────────────────────────────────────────────

-- #98: pcall védelem hianyzó setSeatbelt export ellen
local function SyncHUD()
    if GetResourceState('nxn-vehicle-hud') ~= 'started' then return end
    local ok, err = pcall(function()
        local modState = exports['nxn-vehicle-hud']:getModuleState('seatbelt')
        if modState == nil then
            exports['nxn-vehicle-hud']:setModule('seatbelt', true)
        end
        exports['nxn-vehicle-hud']:setSeatbelt(fastened)
    end)
    if not ok then
        NXN.Seatbelt.Warn(('SyncHUD hiba: %s'):format(tostring(err)))
    end
    NXN.Seatbelt.Log(('HUD szinkron: fastened=%s'):format(tostring(fastened)))
end

-- ── Hang ────────────────────────────────────────────────────

local function StopWarningSound()
    if not warnPlaying then return end
    SendNUIMessage({ action = 'stopWarning' })
    warnPlaying  = false
    warnStartTime = nil
end

-- #97: GetCurrentResourceName() mindig friss ertek, nil check
local function PlayWarningSound()
    if warnPlaying then return end
    local resourceName = GetCurrentResourceName()
    if not resourceName or resourceName == '' then
        NXN.Seatbelt.Warn('PlayWarningSound: ResourceName ismeretlen, hang kihagyva')
        return
    end
    warnPlaying = true
    SendNUIMessage({
        action = 'playWarning',
        file   = ('nui://%s/sounds/%s'):format(resourceName, Config.WarningSoundFile),
        volume = Config.WarningSoundVolume,
    })
end

-- ── Öv toggle ────────────────────────────────────────────────

local function SetFastened(state)
    if fastened == state then return end
    fastened = state
    NXN.Seatbelt.Log(('Ov: fastened=%s'):format(tostring(fastened)))
    if fastened then
        StopWarningSound()   -- StopWarningSound reseteli warnStartTime-ot is
        Notify(Config.Notify.fastened, 'success')
    else
        warnStartTime = nil   -- Reset: új warn ciklus indul
        Notify(Config.Notify.unfastened, 'warning')
    end
    SyncHUD()
end

-- ── Command ─────────────────────────────────────────────────

RegisterCommand('nxn_seatbelt_toggle', function()
    if not inVehicle then return end
    SetFastened(not fastened)
end, false)

-- ── Fő loop: kizárólag DisableControlAction (frame-folytonos) ─────────

-- #92: DisableControlAction valóban igényel Wait(0)-t, kulön thread-be került
CreateThread(function()
    while true do
        Wait(0)
        if inVehicle and fastened and Config.BlockExitWhenFastened then
            local now = GetGameTimer()

            local tryingToExit = IsControlJustPressed(0, INPUT_VEH_EXIT)
                              or IsControlJustPressed(0, INPUT_VEH_ENTER)

            DisableControlAction(0, INPUT_VEH_EXIT,  true)
            DisableControlAction(0, INPUT_VEH_ENTER, true)

            if tryingToExit and (now - lastBlockNotify) > 2000 then
                lastBlockNotify = now
                Notify(Config.Notify.blocked, 'warning')
                NXN.Seatbelt.Log('Kiszallas blokkolva, ertesites kuldve')
            end
        end
    end
end)

-- ── Állapot loop: jármuű észlelés, hang, sebesség (200/500 ms) ─────────

-- #92: állapotvizsgálatok lassabb threadben – nincs frame-folytonos overhead
-- #93: warnStartTime (GetGameTimer) alapu figyelmeztető hang – nincs float drift
CreateThread(function()
    while true do
        Wait(inVehicle and 200 or 500)

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- Járműbe / kiszallás észlelés
        if veh ~= 0 and not inVehicle then
            inVehicle      = true
            currentVehicle = veh
            fastened       = false
            warnStartTime  = nil
            StopWarningSound()
            SyncHUD()
            NXN.Seatbelt.Log(('Jarmube szallt: entId=%d'):format(veh))

        elseif veh == 0 and inVehicle then
            inVehicle      = false
            currentVehicle = 0
            fastened       = false
            warnStartTime  = nil
            StopWarningSound()
            SyncHUD()
            NXN.Seatbelt.Log('Kiszallt')
        end

        -- #93: Figyelmeztető hang GetGameTimer()-alapú időméréssel
        -- nincs float drift, nincs kétszeres GetFrameTime() hívás
        if inVehicle and not fastened then
            if not warnStartTime then warnStartTime = GetGameTimer() end
            local elapsed = (GetGameTimer() - warnStartTime) / 1000.0

            if elapsed <= Config.WarningSoundDuration then
                -- Hang intervallumonkent egy beep: ellenorizzuk, hogy átlepte-e a következő intervallum határát
                -- (200 ms-es loop: maximum 1 hang késéssel, de nincs frame-drift)
                local interval = Config.WarningSoundInterval
                if not warnPlaying and math.floor(elapsed / interval) > math.floor((elapsed - 0.2) / interval) then
                    PlayWarningSound()
                end
            elseif warnPlaying then
                StopWarningSound()
            end
        elseif warnPlaying then
            StopWarningSound()
        end

        -- #94: currentVehicle ~= 0 es DoesEntityExist ellenőrzés AutoUnbuckle előtt
        if inVehicle and fastened and Config.AutoUnbuckleSpeedThreshold then
            if currentVehicle ~= 0 and DoesEntityExist(currentVehicle) then
                local speed = GetEntitySpeed(currentVehicle) * 3.6  -- m/s -> km/h
                if speed > Config.AutoUnbuckleSpeedThreshold then
                    NXN.Seatbelt.Warn(('Auto-kicsatolas: %.1f km/h'):format(speed))
                    SetFastened(false)
                end
            end
        end
    end
end)

-- ── NUI callbacks ─────────────────────────────────────────────

RegisterNUICallback('soundEnded', function(_, cb)
    warnPlaying  = false
    warnStartTime = nil
    cb('ok')
end)

-- ── Exportok ───────────────────────────────────────────────

exports('isFastened', function()
    return fastened
end)

-- #95: inVehicle guard – járművön kívül meghívva nincsen hatas
exports('setFastened', function(state)
    if not inVehicle then
        NXN.Seatbelt.Warn('setFastened: jatekos nincs jarmuben, muvelet kihagyva')
        return
    end
    SetFastened(state)
end)

exports('isInVehicle', function()
    return inVehicle
end)

exports('fasten', function()
    if not inVehicle then return end
    SetFastened(true)
end)

exports('unfasten', function()
    if not inVehicle then return end
    SetFastened(false)
end)

-- #99: StopWarningSound() elobb lefut, igy nincs kettős NUI hangpéldány
exports('playWarning', function()
    if inVehicle and not fastened then
        StopWarningSound()  -- leallitja a jelenlegi peldanyt (ha fut)
        PlayWarningSound()  -- utana inditja az ujat
    end
end)
