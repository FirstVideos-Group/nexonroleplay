-- ============================================================
--  nxn-seatbelt-extras | client.lua
--  Fizikai utkozes-kezeles, kirepules, serules, effektek
-- ============================================================

-- ── Allapot ────────────────────────────────────────────────

local lastSpeed        = 0.0
local lastVehicle      = 0
local inVehicle        = false
local crashCooldown    = false
local extrasEnabled    = true

-- ── Segéd: seatbelt allapot ──────────────────────────────

local function IsFastened()
    if GetResourceState('nxn-seatbelt') ~= 'started' then
        NXN.SeatbeltExt.Warn('nxn-seatbelt nem fut!')
        return false
    end
    return exports['nxn-seatbelt']:isFastened()
end

-- ── Segéd: notify ─────────────────────────────────────────
-- FIX: 'send' export nem létezik az nxn-notify-ban.
-- Elérhető exportok: info | success | danger | warning | notify
-- A 'notify' export általános, típust is fogad – ezt használjuk.

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:notify(msg, ntype or 'info')
    else
        NXN.SeatbeltExt.Warn(('Notify fallback [%s]: %s'):format(ntype or 'info', msg))
    end
end

-- ── Kirepulés (ejection) ─────────────────────────────────────

---@param ped       number
---@param vehicle   number
---@param deltaV    number  km/h
local function ApplyEjection(ped, vehicle, deltaV)
    local cfg = Config.Ejection
    if not cfg.enabled then return end
    if deltaV < cfg.speedThreshold then return end

    NXN.SeatbeltExt.Log(('Ejection: deltaV=%.1f km/h'):format(deltaV))

    local coords = GetEntityCoords(ped)
    SetPedCoordsKeepVehicle(ped, coords.x, coords.y, coords.z)
    TaskLeaveVehicle(ped, vehicle, 4160)

    Wait(50)
    local vehVel = GetEntityVelocity(vehicle)
    local force  = cfg.forceMultiplier
    SetEntityVelocity(ped,
        vehVel.x * force,
        vehVel.y * force,
        math.abs(vehVel.z) * force + (deltaV * 0.012)
    )

    SetPedToRagdoll(ped,
        Config.PostCrash.ragdollDuration * 2,
        Config.PostCrash.ragdollDuration * 2,
        0, false, false, false
    )

    if cfg.notify then
        Notify(cfg.notifyMsg, 'danger')
    end

    TriggerEvent('nxn-seatbelt-extras:ejected', { deltaV = deltaV })
    NXN.SeatbeltExt.Info(('Jatekos kirepult: deltaV=%.1f'):format(deltaV))
end

-- ── Serules alkalmazása ──────────────────────────────────────

---@param ped      number
---@param fastened boolean
---@param deltaV   number
local function ApplyDamage(ped, fastened, deltaV)
    local cfg = Config.Damage
    if not cfg.enabled then return end

    local threshold  = fastened and cfg.fasteningSpeedThreshold   or cfg.unfasteningSpeedThreshold
    local multiplier = fastened and cfg.fasteningDamageMultiplier  or cfg.unfasteningDamageMultiplier

    if deltaV < threshold then
        NXN.SeatbeltExt.Log(('ApplyDamage: deltaV=%.1f < threshold=%.1f, kihagyjuk'):format(deltaV, threshold))
        return
    end

    local rawDamage = math.min((deltaV - threshold) * 1.5 * multiplier, 90.0)
    NXN.SeatbeltExt.Log(('ApplyDamage: deltaV=%.1f fastened=%s dmg=%.1f'):format(
        deltaV, tostring(fastened), rawDamage
    ))

    local currentHealth = GetEntityHealth(ped)
    SetEntityHealth(ped, math.floor(math.max(currentHealth - rawDamage, 100)))

    if cfg.screenFlash then
        AnimpostfxPlay('DamageFlash', 0, false)
    end

    TriggerEvent('nxn-seatbelt-extras:damaged', {
        deltaV   = deltaV,
        damage   = rawDamage,
        fastened = fastened,
    })
end

-- ── Ragdoll ───────────────────────────────────────────────

local function ApplyRagdoll(ped, fastened)
    local cfg = Config.PostCrash
    if not cfg.ragdoll then return end
    local duration = fastened and cfg.ragdollFasteningMs or cfg.ragdollDuration
    NXN.SeatbeltExt.Log(('Ragdoll: fastened=%s duration=%d ms'):format(tostring(fastened), duration))
    SetPedToRagdoll(ped, duration, duration, 0, false, false, false)
end

-- ── Kamera + hang effektek ──────────────────────────────────

local function ApplyCrashEffects(fastened, deltaV)
    local cfg = Config.PostCrash

    if cfg.cameraShake then
        local intensity = math.min(cfg.cameraShakeIntensity * (deltaV / 60.0), 1.0)
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
        NXN.SeatbeltExt.Log(('CameraShake: intensity=%.2f'):format(intensity))
        CreateThread(function()
            Wait(math.floor(cfg.cameraShakeDuration * 1000))
            StopGameplayCamShaking(true)
        end)
    end

    if cfg.muteOnCrash then
        NXN.SeatbeltExt.Log(('PostCrash mute: %.1f mp'):format(cfg.muteDuration))
        StartAudioScene('FBI_HEIST_FINALE_FREEMODE_SCENE')
        CreateThread(function()
            Wait(math.floor(cfg.muteDuration * 1000))
            StopAudioScene('FBI_HEIST_FINALE_FREEMODE_SCENE')
        end)
    end
end

-- ── Utkozes-feldolgozó ─────────────────────────────────────────

---@param ped     number
---@param vehicle number
---@param deltaV  number  km/h
local function ProcessCollision(ped, vehicle, deltaV)
    if deltaV < Config.MinCollisionSpeed then return end
    if not extrasEnabled then
        NXN.SeatbeltExt.Log('Extras ki van kapcsolva, utkozest kihagyjuk')
        return
    end

    local fastened = IsFastened()
    NXN.SeatbeltExt.Log(('ProcessCollision: deltaV=%.1f fastened=%s'):format(
        deltaV, tostring(fastened)
    ))

    if crashCooldown then return end
    crashCooldown = true
    CreateThread(function()
        Wait(2500)
        crashCooldown = false
        NXN.SeatbeltExt.Log('Crash cooldown lejart')
    end)

    local minCfg = Config.MinorCollision
    if minCfg.enabled and deltaV >= minCfg.minSpeed and deltaV < minCfg.maxSpeed then
        NXN.SeatbeltExt.Log('Minor collision')
        if minCfg.notify then
            Notify(minCfg.notifyMsg, 'warning')
        end
        TriggerEvent('nxn-seatbelt-extras:collision', { type = 'minor', deltaV = deltaV, fastened = fastened })
    end

    local majCfg = Config.MajorCollision
    if majCfg.enabled and deltaV >= majCfg.minSpeed then
        NXN.SeatbeltExt.Log(('Major collision: fastened=%s'):format(tostring(fastened)))

        if majCfg.notify then
            local msg = fastened and majCfg.fasteningMsg or majCfg.unfasteningMsg
            local typ = fastened and 'warning' or 'danger'
            Notify(msg, typ)
        end

        ApplyCrashEffects(fastened, deltaV)
        ApplyRagdoll(ped, fastened)

        if not fastened then
            ApplyEjection(ped, vehicle, deltaV)
        end

        ApplyDamage(ped, fastened, deltaV)

        TriggerEvent('nxn-seatbelt-extras:collision', { type = 'major', deltaV = deltaV, fastened = fastened })
    end
end

-- ── Fő detectáló loop ──────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(Config.SampleInterval)

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 then
            if not inVehicle then
                inVehicle   = true
                lastVehicle = veh
                lastSpeed   = GetEntitySpeed(veh) * 3.6
                NXN.SeatbeltExt.Log(('Jarmuebe szallt: entId=%d'):format(veh))
            end

            local currentSpeed = GetEntitySpeed(veh) * 3.6
            local deltaV       = lastSpeed - currentSpeed

            if deltaV >= Config.MinCollisionSpeed then
                ProcessCollision(ped, veh, deltaV)
            end

            lastSpeed   = currentSpeed
            lastVehicle = veh
        else
            if inVehicle then
                inVehicle = false
                lastSpeed = 0.0
                NXN.SeatbeltExt.Log('Kiszallt a jarmubol, sebesseg reset')
            end
        end
    end
end)

-- ── Exportok ────────────────────────────────────────────────

exports('setEnabled', function(state)
    extrasEnabled = state
    NXN.SeatbeltExt.Log(('Extras engedely: %s'):format(tostring(state)))
end)

exports('isEnabled', function()
    return extrasEnabled
end)

exports('simulateCrash', function(deltaV)
    NXN.SeatbeltExt.Log(('simulateCrash export: deltaV=%s'):format(tostring(deltaV)))
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        crashCooldown = false
        ProcessCollision(ped, veh, deltaV or 60.0)
    else
        NXN.SeatbeltExt.Warn('simulateCrash: jatekos nincs jarmuben')
    end
end)

exports('getEjectionThreshold', function()
    return Config.Ejection.speedThreshold
end)

exports('setEjectionThreshold', function(val)
    Config.Ejection.speedThreshold = val
    NXN.SeatbeltExt.Log(('Ejection threshold: %.1f'):format(val))
end)

exports('getDamageConfig', function()
    return Config.Damage
end)

exports('setEjectionEnabled', function(state)
    Config.Ejection.enabled = state
    NXN.SeatbeltExt.Log(('Ejection enabled: %s'):format(tostring(state)))
end)

exports('setDamageEnabled', function(state)
    Config.Damage.enabled = state
    NXN.SeatbeltExt.Log(('Damage enabled: %s'):format(tostring(state)))
end)

exports('resetConfig', function()
    NXN.SeatbeltExt.Log('Config visszaallitva alapertekekre')
end)
