-- ============================================================
--  nxn-engine | client.lua
-- ============================================================

-- ── Allapot ──────────────────────────────────────────────────

local engineRunning    = false
local engineLocked     = false
local inVehicle        = false
local currentVehicle   = 0
local engineHPPercent  = 100.0
local overheatAccum    = 0.0
local lastHUDState     = ''
local hudSyncTimer     = 0.0

local startAuthCallback = nil

-- ── Degradáció belső állapot ──────────────────────────────────

local stutterTimer      = 0.0   -- utolso stutter check ota eltelt ido
local isStuttering      = false -- jelenleg ki van-e kapcsolva stutter miatt
local stutterEndTime    = 0.0   -- mikor induljon ujra a motor stutter utan
local effectsActive     = false -- vizualis effekt fut-e

-- ── Segéd: notify ────────────────────────────────────────────

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then
        NXN.Engine.Warn(('Notify fallback [%s]: %s'):format(ntype or 'info', msg))
        return
    end
    local t = ntype or 'info'
    if     t == 'success' then exports['nxn-notify']:success(msg)
    elseif t == 'danger'  then exports['nxn-notify']:danger(msg)
    elseif t == 'warning' then exports['nxn-notify']:warning(msg)
    else                       exports['nxn-notify']:info(msg)
    end
end

-- ── HP konverzio ─────────────────────────────────────────────

local function PercentToGTA(pct)
    return math.max(0, pct / 100.0 * 1000.0)
end

local function GTAToPercent(hp)
    return math.min(100, hp / 1000.0 * 100.0)
end

-- ── HUD allapot ──────────────────────────────────────────────

local function CalcHUDState()
    if not engineRunning then return 'off' end
    local cfg = Config.EngineDamage
    if engineHPPercent <= cfg.criticalThreshold then return 'critical' end
    if engineHPPercent <= cfg.damagedThreshold  then return 'damaged' end
    return 'ok'
end

local function SyncHUD(force)
    local state = CalcHUDState()
    if not force and state == lastHUDState then return end
    lastHUDState = state
    if GetResourceState('nxn-vehicle-hud') == 'started' then
        exports['nxn-vehicle-hud']:setEngineState(state)
        NXN.Engine.Log(('HUD sync: state=%s hp=%.1f%%'):format(state, engineHPPercent))
    end
end

-- ── Motor HP ─────────────────────────────────────────────────

local function ReadEngineHP(vehicle)
    local gtaHP = GetVehicleEngineHealth(vehicle)
    engineHPPercent = GTAToPercent(gtaHP)
end

local function WriteEngineHP(vehicle, pct)
    engineHPPercent = math.max(0, math.min(100, pct))
    SetVehicleEngineHealth(vehicle, PercentToGTA(engineHPPercent))
end

-- ── Motor inditas / leallitas ─────────────────────────────────

---@param vehicle number
---@param silent  boolean
---@return boolean
local function StartEngine(vehicle, silent)
    if engineLocked then
        if not silent then Notify(Config.Notify.engineLocked, 'danger') end
        return false
    end

    if startAuthCallback then
        local allowed = startAuthCallback(vehicle)
        if not allowed then
            if not silent then Notify(Config.Notify.noKey, 'danger') end
            return false
        end
    end

    ReadEngineHP(vehicle)
    if engineHPPercent <= 0 then
        if not silent then Notify(Config.Notify.engineStalled, 'danger') end
        return false
    end

    SetVehicleEngineOn(vehicle, true, false, true)
    engineRunning  = true
    isStuttering   = false
    overheatAccum  = 0.0
    stutterTimer   = 0.0
    NXN.Engine.Info(('Motor elindult: entId=%d hp=%.1f%%'):format(vehicle, engineHPPercent))
    if not silent then Notify(Config.Notify.engineStarted, 'success') end
    SyncHUD(true)
    TriggerEvent('nxn-engine:started', { vehicle = vehicle, hp = engineHPPercent })
    return true
end

---@param vehicle number
---@param silent  boolean
local function StopEngine(vehicle, silent)
    SetVehicleEngineOn(vehicle, false, true, true)
    engineRunning = false
    isStuttering  = false
    NXN.Engine.Info(('Motor leallitva: entId=%d'):format(vehicle))
    if not silent then Notify(Config.Notify.engineStopped, 'info') end
    SyncHUD(true)
    TriggerEvent('nxn-engine:stopped', { vehicle = vehicle })
end

-- ── Serules ──────────────────────────────────────────────────

local function ApplyDamage(vehicle, dmgPct, reason)
    if not Config.EngineDamage.enabled then return end
    local before = engineHPPercent
    WriteEngineHP(vehicle, engineHPPercent - dmgPct)
    NXN.Engine.Warn(('Motor serules: reason=%s dmg=%.1f%% hp: %.1f->%.1f'):format(
        reason, dmgPct, before, engineHPPercent
    ))

    local cfg = Config.EngineDamage
    if before > cfg.criticalThreshold and engineHPPercent <= cfg.criticalThreshold then
        Notify(Config.Notify.engineCritical, 'danger')
    elseif before > cfg.damagedThreshold and engineHPPercent <= cfg.damagedThreshold then
        Notify(Config.Notify.engineDamaged, 'warning')
    end

    SyncHUD(false)
    TriggerEvent('nxn-engine:damaged', {
        vehicle = vehicle,
        hp      = engineHPPercent,
        dmg     = dmgPct,
        reason  = reason,
    })
end

-- ── Kritikus leallas ─────────────────────────────────────────

local critStallTimer = 0.0

local function CheckCriticalStall(vehicle, dt)
    if engineHPPercent > Config.EngineDamage.criticalThreshold then
        critStallTimer = 0.0
        return
    end
    critStallTimer = critStallTimer + dt
    if critStallTimer >= 60.0 then
        critStallTimer = 0.0
        if math.random() < Config.EngineDamage.criticalStallChance then
            NXN.Engine.Warn('Kritikus motor: spontan leallas')
            Notify(Config.Notify.engineStalled, 'danger')
            StopEngine(vehicle, true)
        end
    end
end

-- ── Tulhevules ───────────────────────────────────────────────

local ovheatTimer = 0.0

local function ProcessOverheat(vehicle, dt)
    local cfg = Config.EngineDamage.overheat
    if not cfg.enabled then return end
    local rpm = GetVehicleCurrentRpm(vehicle)
    if rpm > cfg.rpmThreshold and engineRunning then
        ovheatTimer = ovheatTimer + dt
        if ovheatTimer > 5.0 then
            ApplyDamage(vehicle, cfg.heatRate * dt, 'overheat')
        end
    else
        if ovheatTimer > 0 then
            ovheatTimer = math.max(0, ovheatTimer - dt * 2)
        end
    end
end

-- ============================================================
--  DEGRADÁCIÓ RENDSZER
-- ============================================================

-- ── Teljesitmeny degradáció ───────────────────────────────────
-- Minél alacsonyabb a HP, annál kisebb az acceleration modifier.
-- A SetVehicleCheatPowerIncrease(veh, mult) 1.0 = alap, <1 = gyengébb.

local lastPerfMod = 1.0

local function ApplyPerformanceDegradation(vehicle)
    local dcfg = Config.Degradation
    if not dcfg.enabled or not dcfg.performance.enabled then
        if lastPerfMod ~= 1.0 then
            SetVehicleCheatPowerIncrease(vehicle, 1.0)
            lastPerfMod = 1.0
        end
        return
    end

    -- penalty = lerp(0, maxPenalty, 1 - hp/100)
    -- tehát 100% HP = 0 penalty, 0% HP = maxPenalty
    local ratio   = math.max(0.0, 1.0 - (engineHPPercent / 100.0))
    local penalty = ratio * dcfg.performance.maxPenalty
    local newMod  = math.max(0.05, 1.0 - penalty)  -- minimum 5% teljesitmeny

    if math.abs(newMod - lastPerfMod) > 0.01 then
        SetVehicleCheatPowerIncrease(vehicle, newMod)
        lastPerfMod = newMod
        NXN.Engine.Log(('PerfDeg: hp=%.1f%% mod=%.2f'):format(engineHPPercent, newMod))
    end
end

-- ── Motor stutter (kihagy / leállogatás) ─────────────────────
-- HP < stutter.threshold esetén periodikusan eséllyel leállítja
-- a motort, majd (restartChance valószínűséggel) újraindítja.

local function ProcessStutter(vehicle, dt)
    local dcfg = Config.Degradation
    if not dcfg.enabled or not dcfg.stutter.enabled then return end
    local scfg = dcfg.stutter

    -- Ha éppen stutter miatt le van állítva, várunk az újraindítási időre
    if isStuttering then
        if GetGameTimer() / 1000.0 >= stutterEndTime then
            isStuttering = false
            if math.random() < scfg.restartChance and engineHPPercent > 0 then
                SetVehicleEngineOn(vehicle, true, false, true)
                engineRunning = true
                NXN.Engine.Log('Stutter: motor ujraindult')
                TriggerEvent('nxn-engine:stutter:restart', { vehicle = vehicle, hp = engineHPPercent })
            else
                -- Nem sikerült újraindulni
                engineRunning = false
                Notify(Config.Notify.engineStalled, 'danger')
                NXN.Engine.Warn('Stutter: motor nem tudott ujraindulni')
                TriggerEvent('nxn-engine:stutter:failed', { vehicle = vehicle, hp = engineHPPercent })
            end
            SyncHUD(true)
        end
        return
    end

    -- Csak akkor vizsgáljuk, ha a motor fut és HP a küszöb alatt van
    if not engineRunning then return end
    if engineHPPercent >= scfg.threshold then
        stutterTimer = 0.0
        return
    end

    stutterTimer = stutterTimer + dt
    if stutterTimer < scfg.checkInterval then return end
    stutterTimer = 0.0

    -- Esély: minél alacsonyabb HP, annál nagyobb
    -- chance = (1 - hp/threshold) * maxChance
    local ratio  = math.max(0.0, 1.0 - (engineHPPercent / scfg.threshold))
    local chance = ratio * scfg.maxChance

    NXN.Engine.Log(('Stutter check: hp=%.1f%% chance=%.2f'):format(engineHPPercent, chance))

    if math.random() < chance then
        -- Motor leáll egy rövid időre
        local duration = scfg.stallDuration.min +
            math.random() * (scfg.stallDuration.max - scfg.stallDuration.min)
        isStuttering  = true
        stutterEndTime = GetGameTimer() / 1000.0 + duration
        engineRunning  = false
        SetVehicleEngineOn(vehicle, false, true, true)
        if scfg.notifyOnStall then
            Notify(Config.Notify.engineDegraded, 'warning')
        end
        NXN.Engine.Warn(('Stutter: motor kihagy %.1fs-ra, hp=%.1f%%'):format(duration, engineHPPercent))
        SyncHUD(true)
        TriggerEvent('nxn-engine:stutter:stall', { vehicle = vehicle, hp = engineHPPercent, duration = duration })
    end
end

-- ── Vizuális effektek (füst, szikra) ─────────────────────────
-- A GTA natív particle systemet használja.
-- Füst: W_car_muffler_smoke | Szikra: W_car_exhaust_sp

local activeEffectHandle = -1

local function StopVehicleEffect()
    if activeEffectHandle ~= -1 then
        StopParticleFxLooped(activeEffectHandle, false)
        activeEffectHandle = -1
        effectsActive = false
        NXN.Engine.Log('Effekt leállítva')
    end
end

local function ProcessVisualEffects(vehicle)
    local dcfg = Config.Degradation
    if not dcfg.enabled or not dcfg.effects.enabled then
        StopVehicleEffect()
        return
    end

    local ecfg = dcfg.effects

    -- Szikra (25% HP alatt)
    if engineHPPercent <= ecfg.sparkThreshold then
        if not effectsActive or activeEffectHandle == -1 then
            StopVehicleEffect()
            UseParticleFxAssetNextCall('core')
            local bx, by, bz = GetVehicleEngineLocation(vehicle)
            activeEffectHandle = StartNetworkedParticleFxLoopedOnEntity(
                'exp_grd_bzgas_linger',
                vehicle, 0.0, by or 0.0, 0.3,
                0.0, 0.0, 0.0,
                0.4, false, false, false
            )
            effectsActive = true
            NXN.Engine.Log(('Szikra effekt: hp=%.1f%%'):format(engineHPPercent))
        end

    -- Füst (60% HP alatt)
    elseif engineHPPercent <= ecfg.smokeThreshold then
        if not effectsActive or activeEffectHandle == -1 then
            StopVehicleEffect()
            UseParticleFxAssetNextCall('core')
            local intensity = math.max(0.2, (ecfg.smokeThreshold - engineHPPercent) / ecfg.smokeThreshold)
            activeEffectHandle = StartNetworkedParticleFxLoopedOnEntity(
                'exp_grd_bzgas_linger',
                vehicle, 0.0, 0.5, 0.3,
                0.0, 0.0, 0.0,
                intensity * 0.6, false, false, false
            )
            effectsActive = true
            NXN.Engine.Log(('Füst effekt: hp=%.1f%% intensity=%.2f'):format(engineHPPercent, intensity))
        end

    -- HP visszament a küszöb fölé: leállítjuk az effekteket
    else
        if effectsActive then
            StopVehicleEffect()
        end
    end
end

-- ── nxn-seatbelt-extras integráció ───────────────────────────

AddEventHandler('nxn-seatbelt-extras:collision', function(data)
    if not inVehicle then return end
    if not Config.EngineDamage.collision.enabled then return end
    local deltaV = data.deltaV or 0
    local dmg = 0
    for _, t in ipairs(Config.EngineDamage.collision.thresholds) do
        if deltaV >= t.min and deltaV < t.max then
            dmg = t.damage
            break
        end
    end
    if dmg > 0 then
        ApplyDamage(currentVehicle, dmg, 'collision')
    end
end)

-- ── Fő loop ──────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        local dt  = GetFrameTime()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- Járműbe szállás
        if veh ~= 0 and not inVehicle then
            inVehicle      = true
            currentVehicle = veh
            ovheatTimer    = 0.0
            critStallTimer = 0.0
            stutterTimer   = 0.0
            isStuttering   = false
            lastPerfMod    = 1.0
            ReadEngineHP(veh)
            NXN.Engine.Log(('Jarmube szallt: entId=%d hp=%.1f%%'):format(veh, engineHPPercent))

            if Config.StopEngineOnEnter then
                SetVehicleEngineOn(veh, false, true, true)
                engineRunning = false
            else
                engineRunning = IsVehicleEngineOn(veh)
            end
            SyncHUD(true)

        -- Kiszállás
        elseif veh == 0 and inVehicle then
            -- Effektek leállítása kiszálláskor
            StopVehicleEffect()
            -- Teljesítmény visszaállítása
            if currentVehicle ~= 0 then
                SetVehicleCheatPowerIncrease(currentVehicle, 1.0)
            end
            inVehicle    = false
            lastPerfMod  = 1.0
            isStuttering = false
            if engineRunning and Config.KeepEngineOnExit and currentVehicle ~= 0 then
                SetVehicleEngineOn(currentVehicle, true, true, true)
            end
            currentVehicle = 0
            engineRunning  = false
            SyncHUD(true)
        end

        -- In-vehicle logika
        if inVehicle and currentVehicle ~= 0 then

            -- GTA saját logikája újraindítja a motort ha mi leállítottuk
            -- (kivéve ha éppen stutter miatt le van állítva – azt mi kezeljük)
            if not engineRunning and not isStuttering and IsVehicleEngineOn(currentVehicle) then
                SetVehicleEngineOn(currentVehicle, false, true, true)
            end

            -- Toggle gomb
            if IsControlJustReleased(0, Config.ToggleKey) then
                if engineRunning then
                    StopEngine(currentVehicle, false)
                else
                    StartEngine(currentVehicle, false)
                end
            end

            -- Túlhevülés
            ProcessOverheat(currentVehicle, dt)

            -- Kritikus leállás
            if engineRunning then
                CheckCriticalStall(currentVehicle, dt)
            end

            -- ── Degradáció rendszer ──────────────────────
            if Config.Degradation.enabled then
                -- Teljesítmény csak akkor csökkentjük, ha a motor fut
                if engineRunning then
                    ApplyPerformanceDegradation(currentVehicle)
                end
                -- Stutter (motor fut VAGY stutter recovery folyamatban)
                ProcessStutter(currentVehicle, dt)
                -- Vizuális effektek (füstöl/szikrázik függetlenül hogy fut-e)
                ProcessVisualEffects(currentVehicle)
            end

            -- HUD szinkron
            hudSyncTimer = hudSyncTimer + dt * 1000
            if hudSyncTimer >= Config.HUDSyncInterval then
                hudSyncTimer = 0
                ReadEngineHP(currentVehicle)
                SyncHUD(false)
            end
        end
    end
end)

-- ── Exportok ─────────────────────────────────────────────────

exports('startEngine', function(silent)
    if not inVehicle then return false end
    return StartEngine(currentVehicle, silent or false)
end)

exports('stopEngine', function(silent)
    if not inVehicle then return end
    StopEngine(currentVehicle, silent or false)
end)

exports('isRunning', function()
    return engineRunning
end)

exports('getEngineHP', function()
    return engineHPPercent
end)

exports('setEngineHP', function(pct)
    if not inVehicle then return end
    WriteEngineHP(currentVehicle, pct)
    SyncHUD(true)
end)

exports('applyDamage', function(dmgPct, reason)
    if not inVehicle then return end
    ApplyDamage(currentVehicle, dmgPct, reason or 'external')
end)

exports('getEngineState', function()
    return CalcHUDState()
end)

exports('setLocked', function(state)
    engineLocked = state
    NXN.Engine.Log(('setLocked: %s'):format(tostring(state)))
    if state and engineRunning and inVehicle then
        StopEngine(currentVehicle, false)
    end
end)

exports('isLocked', function()
    return engineLocked
end)

exports('registerStartAuthCallback', function(fn)
    if type(fn) ~= 'function' then
        NXN.Engine.Warn('registerStartAuthCallback: nem function tipusu ertek!')
        return
    end
    startAuthCallback = fn
    NXN.Engine.Info('Inditas-auth callback regisztralva')
end)

exports('clearStartAuthCallback', function()
    startAuthCallback = nil
end)

exports('hotwireStart', function(vehicle, silent)
    if engineHPPercent <= 0 then return false end
    SetVehicleEngineOn(vehicle or currentVehicle, true, false, true)
    engineRunning = true
    NXN.Engine.Info('hotwireStart: motor elindult (hotwire)')
    if not silent then Notify(Config.Notify.engineStarted, 'success') end
    SyncHUD(true)
    TriggerEvent('nxn-engine:started', { vehicle = vehicle or currentVehicle, hp = engineHPPercent, hotwire = true })
    return true
end)

exports('isInVehicle', function()
    return inVehicle
end)

exports('getCurrentVehicle', function()
    return currentVehicle
end)

--- Visszaadja az aktualis teljesitmeny modifiert (0.0-1.0)
exports('getPerfModifier', function()
    return lastPerfMod
end)

--- Visszaadja hogy éppen stutter miatt all-e le a motor
exports('isStuttering', function()
    return isStuttering
end)

--- Degradáció kézi kikapcsolása (pl. szerviz után)
exports('resetDegradation', function()
    if not inVehicle then return end
    isStuttering    = false
    stutterTimer    = 0.0
    lastPerfMod     = 1.0
    SetVehicleCheatPowerIncrease(currentVehicle, 1.0)
    StopVehicleEffect()
    NXN.Engine.Info('Degradaciо resetelve')
end)
