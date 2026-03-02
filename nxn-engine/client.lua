-- ============================================================
--  nxn-engine | client.lua
-- ============================================================

-- ── Állapot ───────────────────────────────────────────────────

local engineRunning    = false
local engineLocked     = false
local inVehicle        = false
local currentVehicle   = 0
local engineHPPercent  = 100.0
local lastHUDState     = ''
local hudSyncTimer     = 0.0

local startAuthCallback = nil

local vehicleEngineStateCache = {}
local ENGINE_CACHE_MAX        = 30
local engineCacheOrder        = {}

-- ── Degradáció belső állapot ───────────────────────────────────

local stutterTimer       = 0.0
local isStuttering       = false
local stutterEndTime     = 0.0
local effectsActive      = false
local activeEffectHandle = -1
local activeEffectType   = nil
local lastPerfMod        = 1.0

-- ── Túlhévülés belső állapot ─────────────────────────────────────

local ovheatTimer    = 0.0
local critStallTimer = 0.0
local ovheatNotified = false

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

-- ── HP konverzió ───────────────────────────────────────────

local function PercentToGTA(pct)
    return math.max(0, pct / 100.0 * 1000.0)
end

local function GTAToPercent(hp)
    return math.min(100, hp / 1000.0 * 100.0)
end

-- ── HUD állapot ─────────────────────────────────────────────

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

-- ── Motor HP ──────────────────────────────────────────────

local function ReadEngineHP(vehicle)
    local gtaHP = GetVehicleEngineHealth(vehicle)
    engineHPPercent = GTAToPercent(gtaHP)
end

local function WriteEngineHP(vehicle, pct)
    engineHPPercent = math.max(0, math.min(100, pct))
    SetVehicleEngineHealth(vehicle, PercentToGTA(engineHPPercent))
end

-- ── Motor indítás / leállítás ──────────────────────────────────────

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
    ovheatTimer    = 0.0
    ovheatNotified = false
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
    engineRunning  = false
    isStuttering   = false
    ovheatTimer    = 0.0
    ovheatNotified = false
    NXN.Engine.Info(('Motor leallitva: entId=%d'):format(vehicle))
    if not silent then Notify(Config.Notify.engineStopped, 'info') end
    SyncHUD(true)
    TriggerEvent('nxn-engine:stopped', { vehicle = vehicle })
end

-- ── Sérülés ─────────────────────────────────────────────────────

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

-- ── Kritikus leállás ─────────────────────────────────────────────

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

-- ── Túlhévülés ────────────────────────────────────────────────

local function ProcessOverheat(vehicle, dt)
    local cfg = Config.EngineDamage.overheat
    if not cfg.enabled then return end
    local rpm = GetVehicleCurrentRpm(vehicle)
    if rpm > cfg.rpmThreshold and engineRunning then
        ovheatTimer = ovheatTimer + dt
        if ovheatTimer > 5.0 then
            ApplyDamage(vehicle, cfg.heatRate * dt, 'overheat')
            if cfg.notifyOnCritical and not ovheatNotified then
                Notify(cfg.criticalMsg, 'danger')
                ovheatNotified = true
            end
        end
    else
        if ovheatTimer > 0 then
            ovheatTimer = math.max(0, ovheatTimer - dt * (cfg.cooldownRate * 100))
        end
        if ovheatTimer == 0 then
            ovheatNotified = false
        end
    end
end

-- ============================================================
--  DEGRADÁCIÓ RENDSZER
-- ============================================================

local function ApplyPerformanceDegradation(vehicle)
    local dcfg = Config.Degradation
    if not dcfg.enabled or not dcfg.performance.enabled then
        if lastPerfMod ~= 1.0 then
            SetVehicleCheatPowerIncrease(vehicle, 1.0)
            lastPerfMod = 1.0
        end
        return
    end

    local ratio   = math.max(0.0, 1.0 - (engineHPPercent / 100.0))
    local penalty = ratio * dcfg.performance.maxPenalty
    local newMod  = math.max(0.05, 1.0 - penalty)

    if math.abs(newMod - lastPerfMod) > 0.01 then
        SetVehicleCheatPowerIncrease(vehicle, newMod)
        lastPerfMod = newMod
        NXN.Engine.Log(('PerfDeg: hp=%.1f%% mod=%.2f'):format(engineHPPercent, newMod))
    end
end

local function ProcessStutter(vehicle, dt)
    local dcfg = Config.Degradation
    if not dcfg.enabled or not dcfg.stutter.enabled then return end
    local scfg = dcfg.stutter

    if isStuttering then
        if GetGameTimer() / 1000.0 >= stutterEndTime then
            isStuttering = false
            if math.random() < scfg.restartChance and engineHPPercent > 0 then
                SetVehicleEngineOn(vehicle, true, false, true)
                engineRunning = true
                NXN.Engine.Log('Stutter: motor ujraindult')
                TriggerEvent('nxn-engine:stutter:restart', { vehicle = vehicle, hp = engineHPPercent })
            else
                engineRunning = false
                Notify(Config.Notify.engineStalled, 'danger')
                NXN.Engine.Warn('Stutter: motor nem tudott ujraindulni')
                TriggerEvent('nxn-engine:stutter:failed', { vehicle = vehicle, hp = engineHPPercent })
            end
            SyncHUD(true)
        end
        return
    end

    if not engineRunning then return end
    if engineHPPercent >= scfg.threshold then
        stutterTimer = 0.0
        return
    end

    stutterTimer = stutterTimer + dt
    if stutterTimer < scfg.checkInterval then return end
    stutterTimer = 0.0

    local ratio  = math.max(0.0, 1.0 - (engineHPPercent / scfg.threshold))
    local chance = ratio * scfg.maxChance

    NXN.Engine.Log(('Stutter check: hp=%.1f%% chance=%.2f'):format(engineHPPercent, chance))

    if math.random() < chance then
        local duration = scfg.stallDuration.min +
            math.random() * (scfg.stallDuration.max - scfg.stallDuration.min)
        isStuttering   = true
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

local function StopVehicleEffect()
    if activeEffectHandle ~= -1 then
        StopParticleFxLooped(activeEffectHandle, false)
        activeEffectHandle = -1
        effectsActive      = false
        activeEffectType   = nil
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
    local newType = nil
    if engineHPPercent <= ecfg.sparkThreshold then
        newType = 'spark'
    elseif engineHPPercent <= ecfg.smokeThreshold then
        newType = 'smoke'
    end

    if newType == activeEffectType then return end

    StopVehicleEffect()
    activeEffectType = newType

    if newType == 'spark' then
        UseParticleFxAssetNextCall('scr_josh_fire')
        activeEffectHandle = StartNetworkedParticleFxLoopedOnEntity(
            'scr_josh_sparks',
            vehicle, 0.0, 1.5, 0.3,
            0.0, 0.0, 0.0,
            0.8, false, false, false
        )
        effectsActive = true
        NXN.Engine.Log(('Szikra effekt: hp=%.1f%%'):format(engineHPPercent))

    elseif newType == 'smoke' then
        UseParticleFxAssetNextCall('veh_damage')
        local intensity = math.max(0.2, (ecfg.smokeThreshold - engineHPPercent) / ecfg.smokeThreshold)
        activeEffectHandle = StartNetworkedParticleFxLoopedOnEntity(
            'veh_damage_event',
            vehicle, 0.0, 1.5, 0.3,
            0.0, 0.0, 0.0,
            intensity * 0.8, false, false, false
        )
        effectsActive = true
        NXN.Engine.Log(('Füst effekt: hp=%.1f%% intensity=%.2f'):format(engineHPPercent, intensity))
    end
end

-- ── nxn-seatbelt-extras integráció ──────────────────────────────────

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

-- ── Fő loop ─────────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        local dt  = GetFrameTime()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and not inVehicle then
            inVehicle      = true
            currentVehicle = veh
            ovheatTimer    = 0.0
            ovheatNotified = false
            critStallTimer = 0.0
            stutterTimer   = 0.0
            isStuttering   = false
            lastPerfMod    = 1.0
            ReadEngineHP(veh)

            local netId  = NetworkGetNetworkIdFromEntity(veh)
            local cached = vehicleEngineStateCache[netId]

            if Config.StopEngineOnEnter then
                SetVehicleEngineOn(veh, false, true, true)
                engineRunning = false
                NXN.Engine.Log(('Jarmube szallt (StopOnEnter): entId=%d netId=%d hp=%.1f%%'):format(veh, netId, engineHPPercent))

            elseif cached ~= nil then
                engineRunning = cached
                SetVehicleEngineOn(veh, cached, not cached, true)
                NXN.Engine.Log(('Jarmube szallt (cache): entId=%d netId=%d running=%s hp=%.1f%%'):format(
                    veh, netId, tostring(cached), engineHPPercent
                ))
            else
                engineRunning = IsVehicleEngineOn(veh)
                NXN.Engine.Log(('Jarmube szallt (natív): entId=%d netId=%d running=%s hp=%.1f%%'):format(
                    veh, netId, tostring(engineRunning), engineHPPercent
                ))
            end

            vehicleEngineStateCache[netId] = nil
            for i, id in ipairs(engineCacheOrder) do
                if id == netId then table.remove(engineCacheOrder, i); break end
            end
            SyncHUD(true)

        elseif veh == 0 and inVehicle then
            local wasRunning = engineRunning
            local lastVeh    = currentVehicle
            local netId      = NetworkGetNetworkIdFromEntity(lastVeh)

            if netId and netId ~= 0 then
                vehicleEngineStateCache[netId] = wasRunning
                table.insert(engineCacheOrder, netId)
                if #engineCacheOrder > ENGINE_CACHE_MAX then
                    local oldest = table.remove(engineCacheOrder, 1)
                    vehicleEngineStateCache[oldest] = nil
                    NXN.Engine.Log(('Cache FIFO: legrégebbi törölve, netId=%d'):format(oldest))
                end
                NXN.Engine.Log(('Kiszallas: netId=%d running=%s elmentve'):format(netId, tostring(wasRunning)))
            end

            StopVehicleEffect()
            if lastVeh ~= 0 then
                SetVehicleCheatPowerIncrease(lastVeh, 1.0)
            end

            inVehicle      = false
            engineRunning  = false
            isStuttering   = false
            ovheatNotified = false
            lastPerfMod    = 1.0
            currentVehicle = 0

            if wasRunning and Config.KeepEngineOnExit and lastVeh ~= 0 then
                SetVehicleEngineOn(lastVeh, true, true, true)
            end

            SyncHUD(true)
        end

        if inVehicle and currentVehicle ~= 0 then

            if not engineRunning and not isStuttering and IsVehicleEngineOn(currentVehicle) then
                SetVehicleEngineOn(currentVehicle, false, true, true)
            end

            if IsControlJustReleased(0, Config.ToggleKey) then
                if engineRunning then
                    StopEngine(currentVehicle, false)
                else
                    StartEngine(currentVehicle, false)
                end
            end

            ProcessOverheat(currentVehicle, dt)

            if engineRunning then
                CheckCriticalStall(currentVehicle, dt)
            end

            if Config.Degradation.enabled then
                if engineRunning then
                    ApplyPerformanceDegradation(currentVehicle)
                end
                ProcessStutter(currentVehicle, dt)
                ProcessVisualEffects(currentVehicle)
            end

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

-- registerStartAuthCallback: hívó resource nevét is logoljuk a jobb debugolhatóságért.
-- Korábban csak azt jelezte a WARN, hogy nem function tipusú az érték, de nem volt
-- egyértelmű melyik resource okozta. Most a GetInvokingResource() hívással
-- pontosan azonosítható a hibás hívó.
exports('registerStartAuthCallback', function(fn)
    local caller = GetInvokingResource() or 'ismeretlen'
    if type(fn) ~= 'function' then
        NXN.Engine.Warn(('registerStartAuthCallback: nem function tipusu ertek! Hivo resource: %s (kapott tipus: %s)'):format(
            caller, type(fn)
        ))
        return false
    end
    startAuthCallback = fn
    NXN.Engine.Info(('Inditas-auth callback regisztralva, hivo: %s'):format(caller))
    return true
end)

exports('clearStartAuthCallback', function()
    startAuthCallback = nil
    NXN.Engine.Log('startAuthCallback torolve')
end)

---@param vehicle number|nil
---@param silent  boolean|nil
exports('hotwireStart', function(vehicle, silent)
    local targetVeh = vehicle or currentVehicle
    if not inVehicle or targetVeh == 0 then
        NXN.Engine.Warn('hotwireStart: nincs jarmuben vagy ervenytelen vehicle')
        return false
    end
    if not DoesEntityExist(targetVeh) then
        NXN.Engine.Warn('hotwireStart: vehicle entity nem letezik')
        return false
    end
    if engineHPPercent <= 0 then
        NXN.Engine.Warn('hotwireStart: motor HP = 0, nem lehet elinditani')
        return false
    end
    SetVehicleEngineOn(targetVeh, true, false, true)
    engineRunning  = true
    ovheatNotified = false
    NXN.Engine.Info('hotwireStart: motor elindult (hotwire)')
    if not silent then Notify(Config.Notify.engineStarted, 'success') end
    SyncHUD(true)
    TriggerEvent('nxn-engine:started', { vehicle = targetVeh, hp = engineHPPercent, hotwire = true })
    return true
end)

exports('isInVehicle', function()
    return inVehicle
end)

exports('getCurrentVehicle', function()
    return currentVehicle
end)

---@return number
exports('getPerfModifier', function()
    return lastPerfMod
end)

---@return boolean
exports('isStuttering', function()
    return isStuttering
end)

exports('resetDegradation', function()
    if not inVehicle then return end
    isStuttering = false
    stutterTimer = 0.0
    lastPerfMod  = 1.0
    SetVehicleCheatPowerIncrease(currentVehicle, 1.0)
    StopVehicleEffect()
    NXN.Engine.Info('Degradacio resetelve')
end)
