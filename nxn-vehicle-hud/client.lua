-- ============================================================
--  nxn-vehicle-hud | client.lua
--  Kozponti manager: jarmu eszleles, NUI init, export API
-- ============================================================

-- ── Allapot ──────────────────────────────────────────────────

local hudVisible   = false   -- csak jarmuben latszik alapesetben
local inVehicle    = false
local moduleStates = {}

for name, cfg in pairs(Config.Modules) do
    moduleStates[name] = cfg.enabled
end

-- ── NUI kommunikacio ─────────────────────────────────────────

--- NUI uzenet kuldese (csak ha jarmuben vagyunk es HUD lathato)
---@param action string
---@param data table
function NXN.VehHUD.Send(action, data)
    if not hudVisible then return end
    local payload = data or {}
    payload.action = action
    NXN.VehHUD.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

--- Konfig kuldese inicializalaskor
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

-- ── Jarmu eszleles loop ───────────────────────────────────────

local lastVehicle = 0

CreateThread(function()
    while true do
        Wait(300)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and veh ~= lastVehicle then
            -- Jarmubbe szallt
            lastVehicle = veh
            inVehicle   = true
            hudVisible  = true
            NXN.VehHUD.Log(('Jarmubbe szallt: entId=%d'):format(veh))
            SendConfig()
            SendNUIMessage({ action = 'setVisible', visible = true })
        elseif veh == 0 and lastVehicle ~= 0 then
            -- Kiszallt
            lastVehicle = 0
            inVehicle   = false
            hudVisible  = false
            NXN.VehHUD.Log('Kiszallt a jarmubol')
            SendNUIMessage({ action = 'setVisible', visible = false })
        end
    end
end)

-- ── Lathatosag kezeles ────────────────────────────────────────

local function SetHudVisible(state)
    hudVisible = state
    SendNUIMessage({ action = 'setVisible', visible = state })
    NXN.VehHUD.Log(('HUD lathatosag: %s'):format(tostring(state)))
end

-- ── Modul kezeles ─────────────────────────────────────────────

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

--- HUD elrejtese / mutatasa (manualis feluliras)
---@param state boolean
exports('setVisible', function(state)
    SetHudVisible(state)
end)

--- HUD jelenlegi lathatosaga
---@return boolean
exports('isVisible', function()
    return hudVisible
end)

--- Jatekos jarmuben van-e
---@return boolean
exports('isInVehicle', function()
    return inVehicle
end)

--- Modul be- vagy kikapcsolasa
---@param name string
---@param state boolean
---@return boolean
exports('setModule', function(name, state)
    return SetModuleEnabled(name, state)
end)

--- Egy modul allapota
---@param name string
---@return boolean|nil
exports('getModuleState', function(name)
    return moduleStates[name]
end)

--- Osszes modul allapota
---@return table
exports('getAllModuleStates', function()
    return moduleStates
end)

--- Pozicio valtoztatasa menet kozben
---@param pos string
exports('setPosition', function(pos)
    SendNUIMessage({ action = 'setPosition', position = pos })
    NXN.VehHUD.Log(('Pozicio: %s'):format(pos))
end)

--- Uzemanyag ertek frissitese (nxn-fuel fogja hivni)
---@param value number  0-100
exports('setFuel', function(value)
    if not moduleStates['fuel'] then return end
    NXN.VehHUD.Log(('setFuel: %d'):format(value))
    NXN.VehHUD.Send('updateModule', { module = 'fuel', value = value })
end)

--- Biztonsagi ov allapot (nxn-seatbelt fogja hivni)
---@param fastened boolean
exports('setSeatbelt', function(fastened)
    if not moduleStates['seatbelt'] then return end
    NXN.VehHUD.Log(('setSeatbelt: %s'):format(tostring(fastened)))
    NXN.VehHUD.Send('updateModule', { module = 'seatbelt', fastened = fastened })
    if not fastened then
        SendNUIMessage({ action = 'showModuleTemporary', module = 'seatbelt' })
    else
        SendNUIMessage({ action = 'hideModuleTemporary', module = 'seatbelt' })
    end
end)

--- Szirena allapot (nxn-sirencontrol fogja hivni)
---@param active boolean
---@param mode string|nil  'code1'|'code2'|'code3' stb.
exports('setSiren', function(active, mode)
    if not moduleStates['siren'] then return end
    NXN.VehHUD.Log(('setSiren: active=%s mode=%s'):format(tostring(active), tostring(mode)))
    NXN.VehHUD.Send('updateModule', { module = 'siren', active = active, mode = mode })
    if active then
        SendNUIMessage({ action = 'showModuleTemporary', module = 'siren' })
    else
        SendNUIMessage({ action = 'hideModuleTemporary', module = 'siren' })
    end
end)

--- Motor allapot (nxn-engine is hivhatja, de a modul maga is kezeli)
---@param state string  'ok'|'damaged'|'critical'|'off'
exports('setEngineState', function(state)
    if not moduleStates['engine'] then return end
    NXN.VehHUD.Log(('setEngineState: %s'):format(state))
    NXN.VehHUD.Send('updateModule', { module = 'engine', state = state })
end)

--- Altalanos modul adat frissitese kulso resource-bol
---@param moduleName string
---@param data table
exports('updateModuleData', function(moduleName, data)
    local payload = data
    payload.action = 'updateModuleData'
    payload.module = moduleName
    SendNUIMessage(payload)
    NXN.VehHUD.Log(('updateModuleData: %s'):format(moduleName))
end)
