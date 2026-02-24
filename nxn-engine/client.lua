-- ============================================================
--  nxn-engine | client.lua
--  Motorvezerles: inditas/leallitas, serules, HUD szinkron,
--  kulcs-API (nxn-keys/nxn-hotwire kesobb)
-- ============================================================

-- ── Allapot ─────────────────────────────────────────────────

local engineRunning    = false   -- motor jár-e
local engineLocked     = false   -- kulcsrendszer zárja-e
local inVehicle        = false
local currentVehicle   = 0
local engineHPPercent  = 100.0   -- 0-100, motor aktualis HP%-a
local overheatAccum    = 0.0    -- hevulesi akkumulator (HP)
local lastHUDState     = ''     -- utolso HUD allapot string
local hudSyncTimer     = 0.0

-- Kulcsrendszer callback (nxn-keys tölti majd fel)
-- Signature: function(vehicleEntity) -> boolean
local startAuthCallback = nil

-- ── Segéd: notify ────────────────────────────────────────────

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:send(msg, ntype or 'info')
    else
        NXN.Engine.Warn(('Notify fallback [%s]: %s'):format(ntype or 'info', msg))
    end
end

-- ── Segéd: motor HP -> GTA engine health ─────────────────────
-- GTA skala: 0 (torott) - 1000 (uj)
-- Config %:  0 (torott) - 100 (uj)

local function PercentToGTA(pct)
    return math.max(0, pct / 100.0 * 1000.0)
end

local function GTAToPercent(hp)
    return math.min(100, hp / 1000.0 * 100.0)
end

-- ── HUD allapot kiszamitasa ──────────────────────────────────
-- Visszater: 'ok'|'damaged'|'critical'|'off'

local function CalcHUDState()
    if not engineRunning then return 'off' end
    local cfg = Config.EngineDamage
    if engineHPPercent <= cfg.criticalThreshold then return 'critical' end
    if engineHPPercent <= cfg.damagedThreshold  then return 'damaged' end
    return 'ok'
end

-- ── HUD szinkron ───────────────────────────────────────────

local function SyncHUD(force)
    local state = CalcHUDState()
    if not force and state == lastHUDState then return end
    lastHUDState = state
    if GetResourceState('nxn-vehicle-hud') == 'started' then
        exports['nxn-vehicle-hud']:setEngineState(state)
        NXN.Engine.Log(('HUD sync: state=%s hp=%.1f%%'):format(state, engineHPPercent))
    end
end

-- ── Motor szerelesegyedületi HP frissitese ────────────────────

local function ReadEngineHP(vehicle)
    local gtaHP = GetVehicleEngineHealth(vehicle)
    engineHPPercent = GTAToPercent(gtaHP)
    NXN.Engine.Log(('ReadEngineHP: gta=%.0f pct=%.1f'):format(gtaHP, engineHPPercent))
end

local function WriteEngineHP(vehicle, pct)
    engineHPPercent = math.max(0, math.min(100, pct))
    SetVehicleEngineHealth(vehicle, PercentToGTA(engineHPPercent))
    NXN.Engine.Log(('WriteEngineHP: pct=%.1f'):format(engineHPPercent))
end

-- ── Motor elinditas / leallitas ───────────────────────────────

---@param vehicle number
---@param silent  boolean  ne kuld-e notify-t
---@return boolean  siker
local function StartEngine(vehicle, silent)
    -- Kulcsrendszer ellenorzese
    if engineLocked then
        NXN.Engine.Warn('StartEngine: motor zarolva (engineLocked)')
        if not silent then Notify(Config.Notify.engineLocked, 'danger') end
        return false
    end

    -- Kulcs-callback ellenorzese (nxn-keys toltotte fel)
    if startAuthCallback then
        local allowed = startAuthCallback(vehicle)
        if not allowed then
            NXN.Engine.Warn('StartEngine: startAuthCallback DENIED')
            if not silent then Notify(Config.Notify.noKey, 'danger') end
            return false
        end
        NXN.Engine.Log('StartEngine: startAuthCallback OK')
    end

    -- Motor HP ellenorzese
    ReadEngineHP(vehicle)
    if engineHPPercent <= 0 then
        NXN.Engine.Warn('StartEngine: motor torott (HP=0), nem indul')
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
    SetVehicleEngineOn(vehicle, false, true, true)
    engineRunning = false
    NXN.Engine.Info(('Motor leallitva: entId=%d'):format(vehicle))
    if not silent then Notify(Config.Notify.engineStopped, 'info') end
    SyncHUD(true)
    TriggerEvent('nxn-engine:stopped', { vehicle = vehicle })
end

-- ── Serules alkalmazasa ─────────────────────────────────────

---@param vehicle number
---@param dmgPct  number  0-100
---@param reason  string
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

-- ── Kritikus motor: véletlenszerű leallas ──────────────────────

local critStallTimer = 0.0

local function CheckCriticalStall(vehicle, dt)
    if engineHPPercent > Config.EngineDamage.criticalThreshold then
        critStallTimer = 0.0
        return
    end
    critStallTimer = critStallTimer + dt
    -- Percenkent Config.criticalStallChance valoszinuseggel all le
    if critStallTimer >= 60.0 then
        critStallTimer = 0.0
        if math.random() < Config.EngineDamage.criticalStallChance then
            NXN.Engine.Warn('Kritikus motor: spontan leallas')
            Notify(Config.Notify.engineStalled, 'danger')
            StopEngine(vehicle, true)
        end
    end
end

-- ── Tulhevules loop ──────────────────────────────────────────

local ovheatTimer = 0.0

local function ProcessOverheat(vehicle, dt)
    local cfg = Config.EngineDamage.overheat
    if not cfg.enabled then return end

    local rpm = GetVehicleCurrentRpm(vehicle)  -- 0.0-1.0

    if rpm > cfg.rpmThreshold and engineRunning then
        ovheatTimer = ovheatTimer + dt
        -- 5 masodpercnyi magas RPM utan kezd serulni
        if ovheatTimer > 5.0 then
            local dmg = cfg.heatRate * dt
            ApplyDamage(vehicle, dmg, 'overheat')
        end
        NXN.Engine.Log(('Overheat: rpm=%.2f timer=%.1f'):format(rpm, ovheatTimer))
    else
        if ovheatTimer > 0 then
            ovheatTimer = math.max(0, ovheatTimer - dt * 2)
        end
    end
end

-- ── nxn-seatbelt-extras esemeny integration ───────────────────

AddEventHandler('nxn-seatbelt-extras:collision', function(data)
    if not inVehicle then return end
    if not Config.EngineDamage.collision.enabled then return end

    local deltaV = data.deltaV or 0
    local dmg    = 0
    for _, t in ipairs(Config.EngineDamage.collision.thresholds) do
        if deltaV >= t.min and deltaV < t.max then
            dmg = t.damage
            break
        end
    end

    if dmg > 0 then
        NXN.Engine.Log(('Kolliziо serules: deltaV=%.1f -> dmg=%.1f%%'):format(deltaV, dmg))
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

        -- ── Jarmube szallas ─────────────────────────────────
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
                NXN.Engine.Log('Motor leallitva belépeskor')
                SyncHUD(true)
            else
                engineRunning = IsVehicleEngineOn(veh)
                SyncHUD(true)
            end

        -- ── Kiszallas ──────────────────────────────────────
        elseif veh == 0 and inVehicle then
            inVehicle = false

            if engineRunning and Config.KeepEngineOnExit and currentVehicle ~= 0 then
                -- Motor tovabb jar kiszallas utan
                SetVehicleEngineOn(currentVehicle, true, true, true)
                NXN.Engine.Log(('Motor tovabb jar kiszallas utan: entId=%d'):format(currentVehicle))
            end

            currentVehicle = 0
            engineRunning  = false
            SyncHUD(true)
        end

        -- ── In-vehicle logika ────────────────────────────────
        if inVehicle and currentVehicle ~= 0 then

            -- GTA altal elindithato motor blokkolasa (ha mi leallitottuk)
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

            -- Kritikus leallas ellenorzese
            if engineRunning then
                CheckCriticalStall(currentVehicle, dt)
            end

            -- HUD szinkron idozitett
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

-- ── Motor alap ─────────────────────────────────────────

--- Motor elinditas kulsoleg (pl. kulcsrendszer engedelyezes utan)
---@param silent boolean|nil
---@return boolean
exports('startEngine', function(silent)
    if not inVehicle then
        NXN.Engine.Warn('startEngine: nincs jarmube')
        return false
    end
    return StartEngine(currentVehicle, silent or false)
end)

--- Motor leallitas kulsoleg
---@param silent boolean|nil
exports('stopEngine', function(silent)
    if not inVehicle then return end
    StopEngine(currentVehicle, silent or false)
end)

--- Motor jar-e
---@return boolean
exports('isRunning', function()
    return engineRunning
end)

--- Motor jelenlegi HP%-a (0-100)
---@return number
exports('getEngineHP', function()
    return engineHPPercent
end)

--- Motor HP% allitasa kulsoleg (pl. mentesbol visszatoltes)
---@param pct number  0-100
exports('setEngineHP', function(pct)
    if not inVehicle then return end
    WriteEngineHP(currentVehicle, pct)
    SyncHUD(true)
    NXN.Engine.Log(('setEngineHP (export): %.1f%%'):format(pct))
end)

--- Serules alkalmazasa kulsoleg (pl. IED, script esemeny)
---@param dmgPct number  0-100
---@param reason string|nil
exports('applyDamage', function(dmgPct, reason)
    if not inVehicle then return end
    ApplyDamage(currentVehicle, dmgPct, reason or 'external')
end)

--- Motor HUD allapot lekerdezes: 'ok'|'damaged'|'critical'|'off'
---@return string
exports('getEngineState', function()
    return CalcHUDState()
end)

-- ── Zarolasi API (nxn-keys / nxn-hotwire) ────────────────────

--- Motor zarolasa kulso resource-bol
--- Ha zarolt, a jatekos nem tudja elindítani a GomB-bal sem
---@param state boolean
exports('setLocked', function(state)
    engineLocked = state
    NXN.Engine.Log(('setLocked: %s'):format(tostring(state)))
    if state and engineRunning and inVehicle then
        -- Ha zaroljak menet kozben, leallitjuk
        StopEngine(currentVehicle, false)
    end
end)

--- Zarolasi allapot lekerdezes
---@return boolean
exports('isLocked', function()
    return engineLocked
end)

--- Egyedi inditas-engedelyezo callback regisztralaas
--- A callback signature: function(vehicleEntity: number) -> boolean
--- nxn-keys hivja meg ezzel a sajat ellenorzo fuggvenyet
--- Ha a callback false-t ad vissza, a motor nem indul el
---@param fn function
exports('registerStartAuthCallback', function(fn)
    if type(fn) ~= 'function' then
        NXN.Engine.Warn('registerStartAuthCallback: nem function tipusu ertek!')
        return
    end
    startAuthCallback = fn
    NXN.Engine.Info('Inditas-auth callback regisztralva')
end)

--- Auth callback torles (pl. nxn-keys leall)
exports('clearStartAuthCallback', function()
    startAuthCallback = nil
    NXN.Engine.Log('Inditas-auth callback torolve')
end)

--- Kozvetlen inditas callback altal (nxn-hotwire hasznali)
--- Zarolas es auth callback megkerulese NINCS - de engedelyezi ha a
--- kulcsos check utan a hotwire sikerrel jart
---@param vehicle number  entitas
---@param silent  boolean|nil
---@return boolean
exports('hotwireStart', function(vehicle, silent)
    -- hotwire: kenyszer-start, csak a motor HP-t ellenorzi
    if engineHPPercent <= 0 then
        NXN.Engine.Warn('hotwireStart: motor HP=0, nem indul')
        return false
    end
    SetVehicleEngineOn(vehicle or currentVehicle, true, false, true)
    engineRunning = true
    NXN.Engine.Info('hotwireStart: motor elindult (hotwire)')
    if not silent then Notify(Config.Notify.engineStarted, 'success') end
    SyncHUD(true)
    TriggerEvent('nxn-engine:started', { vehicle = vehicle or currentVehicle, hp = engineHPPercent, hotwire = true })
    return true
end)

--- Jatekos jarmube van-e (engine kontextus)
---@return boolean
exports('isInVehicle', function()
    return inVehicle
end)

--- Aktualis jarmue entitas (0 ha nincs)
---@return number
exports('getCurrentVehicle', function()
    return currentVehicle
end)
