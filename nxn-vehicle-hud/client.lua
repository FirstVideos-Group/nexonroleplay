-- ============================================================
--  nxn-vehicle-hud | client.lua
--  Kozponti manager: jarmu eszleles, NUI init, export API
-- ============================================================

-- ── Allapot ──────────────────────────────────────────────────────────
-- #115: local kulcsszo hozzaadva - globalisan nem lathato mas resource-nak
-- A modulok (modules/*.lua) NXN.VehHUD.State-en keresztul olvassak ezeket.

local hudVisible   = false
local inVehicle    = false
local moduleStates = {}

for name, cfg in pairs(Config.Modules) do
    moduleStates[name] = cfg.enabled
end

-- NXN.VehHUD.State namespace: a modulok ezen keresztul olvasnak (nem globalisan)
NXN.VehHUD.State = {
    get hudVisible()   return hudVisible   end,
    get inVehicle()    return inVehicle    end,
    get moduleStates() return moduleStates end,
}

-- ── NUI kommunikacio ─────────────────────────────────────────────

function NXN.VehHUD.Send(action, data)
    local payload = data or {}
    payload.action = action
    NXN.VehHUD.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

function NXN.VehHUD.SendIfVisible(action, data)
    if not hudVisible then return end
    NXN.VehHUD.Send(action, data)
end

local function SendConfig()
    local modulesCfg = {}
    for name, cfg in pairs(Config.Modules) do
        modulesCfg[name] = {
            enabled       = moduleStates[name],
            alwaysVisible = cfg.alwaysVisible,
            order         = cfg.order,
        }
    end
    SendNUIMessage({
        action    = 'init',
        position  = Config.Position,
        speedUnit = Config.SpeedUnit,
        modules   = modulesCfg,
    })
    NXN.VehHUD.Log(('VehHUD init kuldve, pos=%s unit=%s'):format(Config.Position, Config.SpeedUnit))
end

-- ── Jarmu eszleles loop ────────────────────────────────────────────
-- #117: wasInVehicle flag biztositja a reinit-et visszaszallaskor
-- ugyanabba a jarmuvebbe is (veh ~= lastVehicle felt etel eltavolitva)

local lastVehicle   = 0
local wasInVehicle  = false

CreateThread(function()
    while true do
        Wait(300)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local nowInVehicle = (veh ~= 0)

        if nowInVehicle and (not wasInVehicle or veh ~= lastVehicle) then
            -- Uj jarmu VAGY visszaszallas ugyanabba (pl. TaskWarpPedIntoVehicle utan)
            lastVehicle   = veh
            inVehicle     = true
            wasInVehicle  = true
            SendConfig()
            hudVisible = true
            SendNUIMessage({ action = 'setVisible', visible = true })
            NXN.VehHUD.Log(('Jarmubbe szallt: entId=%d'):format(veh))
        elseif not nowInVehicle and wasInVehicle then
            lastVehicle   = 0
            inVehicle     = false
            wasInVehicle  = false
            hudVisible    = false
            SendNUIMessage({ action = 'setVisible', visible = false })
            NXN.VehHUD.Log('Kiszallt a jarmubol')
        end
    end
end)

-- ── Lathatosag kezeles ─────────────────────────────────────────────

local function SetHudVisible(state)
    hudVisible = state
    SendNUIMessage({ action = 'setVisible', visible = state })
    NXN.VehHUD.Log(('HUD lathatosag: %s'):format(tostring(state)))
end

-- ── Modul kezeles ────────────────────────────────────────────────

local function SetModuleEnabled(name, state)
    if moduleStates[name] == nil then
        NXN.VehHUD.Warn(('SetModuleEnabled: ismeretlen modul: %s'):format(name))
        return false
    end
    moduleStates[name] = state
    SendNUIMessage({ action = 'setModule', module = name, enabled = state })
    NXN.VehHUD.Log(('Modul allapot: %s = %s'):format(name, tostring(state)))
    return true
end

-- ── Exportok ─────────────────────────────────────────────────

exports('setVisible', function(state)
    SetHudVisible(state)
end)

exports('isVisible', function()
    return hudVisible
end)

exports('isInVehicle', function()
    return inVehicle
end)

exports('setModule', function(name, state)
    return SetModuleEnabled(name, state)
end)

exports('getModuleState', function(name)
    return moduleStates[name]
end)

exports('getAllModuleStates', function()
    -- Shallow copy, belső referencia nem szivárog ki
    local copy = {}
    for k, v in pairs(moduleStates) do copy[k] = v end
    return copy
end)

exports('setPosition', function(pos)
    SendNUIMessage({ action = 'setPosition', position = pos })
    NXN.VehHUD.Log(('Pozicio: %s'):format(pos))
end)

--- Uzemanyag ertek frissitese (nxn-fuel fogja hivni)
--- #122: nil vs false megkulonboztetese warn loggal
exports('setFuel', function(value)
    if moduleStates['fuel'] == nil then
        NXN.VehHUD.Warn('setFuel: fuel modul nem talalhato a Config.Modules-ban')
        return
    end
    if not moduleStates['fuel'] then return end  -- ki van kapcsolva, OK
    NXN.VehHUD.Log(('setFuel: %d'):format(value))
    SendNUIMessage({ action = 'updateModule', module = 'fuel', value = value })
end)

--- Biztonsagi ov allapot
exports('setSeatbelt', function(fastened)
    if not moduleStates['seatbelt'] then return end
    NXN.VehHUD.Log(('setSeatbelt: %s'):format(tostring(fastened)))
    SendNUIMessage({ action = 'updateModule', module = 'seatbelt', fastened = fastened })
    if not fastened then
        SendNUIMessage({ action = 'showModuleTemporary', module = 'seatbelt' })
    else
        SendNUIMessage({ action = 'hideModuleTemporary', module = 'seatbelt' })
    end
end)

--- Szirena allapot
exports('setSiren', function(active, mode)
    if not moduleStates['siren'] then return end
    NXN.VehHUD.Log(('setSiren: active=%s mode=%s'):format(tostring(active), tostring(mode)))
    SendNUIMessage({ action = 'updateModule', module = 'siren', active = active, mode = mode })
    if active then
        SendNUIMessage({ action = 'showModuleTemporary', module = 'siren' })
    else
        SendNUIMessage({ action = 'hideModuleTemporary', module = 'siren' })
    end
end)

--- Motor allapot
exports('setEngineState', function(state)
    if not moduleStates['engine'] then return end
    NXN.VehHUD.Log(('setEngineState: %s'):format(state))
    SendNUIMessage({ action = 'updateModule', module = 'engine', state = state })
end)

--- Altalanos modul adat frissitese kulso resource-bol
--- #116: shallow copy keszul a data tablarol, nem mutaljuk a hivot
exports('updateModuleData', function(moduleName, data)
    local payload = {}
    for k, v in pairs(data) do payload[k] = v end
    payload.action = 'updateModuleData'
    payload.module = moduleName
    SendNUIMessage(payload)
    NXN.VehHUD.Log(('updateModuleData: %s'):format(moduleName))
end)
