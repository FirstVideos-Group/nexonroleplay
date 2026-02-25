-- ============================================================
--  nxn-engine | client.lua
--  FIX 1: Notify helper javitva – exports['nxn-notify']:send()
--          nem letezik, tipusos exportok hasznalata helyette:
--          :info(), :success(), :danger(), :warning()
--  FIX 2: StopEngine utan GTA ujrainditja a motort sajat logikajat.
--          Megoldas: engineRunning=false allapotban minden frameben
--          SetVehicleEngineOn(veh, false, true, true) kenyszeritese.
-- ============================================================

-- ── Allapot ─────────────────────────────────────────────────

local engineRunning    = false
local engineLocked     = false
local inVehicle        = false
local currentVehicle   = 0
local engineHPPercent  = 100.0
local overheatAccum    = 0.0
local lastHUDState     = ''
local hudSyncTimer     = 0.0

local startAuthCallback = nil

-- ── Segéd: notify ────────────────────────────────────────────
-- FIX: :send() nem letezik az nxn-notify-ban.
-- A helyes exportok: :info(), :success(), :danger(), :warning()

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then
        NXN.Engine.Warn(('Notify fallback [%s]: %s'):format(ntype or 'info', msg))
        return
    end
    local t = ntype or 'info'
    if t == 'success' then
        exports['nxn-notify']:success(msg)
    elseif t == 'danger' then
        exports['nxn-notify']:danger(msg)
    elseif t == 'warning' then
        exports['nxn-notify']:warning(msg)
    else
        exports['nxn-notify']:info(msg)
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
    engineRunning = true
    overheatAccum = 0.0
    NXN.Engine.Info(('Motor elindult: entId=%d hp=%.1f%%'):format(vehicle, engineHPPercent))
    if not silent then Notify(Config.Notify.engineStarted, 'success') end
    SyncHUD(true)
    TriggerEvent('nxn-engine:started', { vehicle = vehicle, hp = engineHPPercent })
    return true
end

---@param vehicle number
---@param silent  boolean
local function StopEngine(vehicle, silent)
    -- FIX: engineRunning = false utan a fo loop kenyszeriti
    -- a SetVehicleEngineOn(false)-t minden frameben,
    -- igy a GTA sajat motor-ujrainditasi logikaja nem tud
    -- felulirni az allapotot.
    SetVehicleEngineOn(vehicle, false, true, true)
    engineRunning = false
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

-- ── nxn-seatbelt-extras integraciо ───────────────────────────

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

-- ── Fo loop ──────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        local dt  = GetFrameTime()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- Jarmube szallas
        if veh ~= 0 and not inVehicle then
            inVehicle      = true
            currentVehicle = veh
            ovheatTimer    = 0.0
            critStallTimer = 0.0
            ReadEngineHP(veh)
            NXN.Engine.Log(('Jarmube szallt: entId=%d hp=%.1f%%'):format(veh, engineHPPercent))

            if Config.StopEngineOnEnter then
                SetVehicleEngineOn(veh, false, true, true)
                engineRunning = false
            else
                engineRunning = IsVehicleEngineOn(veh)
            end
            SyncHUD(true)

        -- Kiszallas
        elseif veh == 0 and inVehicle then
            inVehicle = false
            if engineRunning and Config.KeepEngineOnExit and currentVehicle ~= 0 then
                SetVehicleEngineOn(currentVehicle, true, true, true)
            end
            currentVehicle = 0
            engineRunning  = false
            SyncHUD(true)
        end

        -- In-vehicle logika
        if inVehicle and currentVehicle ~= 0 then

            -- FIX: GTA sajat logikaja ujrainditja a motort ha mi leallitottuk.
            -- Megoldas: engineRunning=false allapotban minden frameben
            -- kenyszeritjuk a motor kikapcsolt allapotat.
            if not engineRunning and IsVehicleEngineOn(currentVehicle) then
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

            -- Tulhevules
            ProcessOverheat(currentVehicle, dt)

            -- Kritikus leallas
            if engineRunning then
                CheckCriticalStall(currentVehicle, dt)
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
