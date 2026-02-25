-- ============================================================
--  nxn-vehicle-hud | client.lua
--  Kozponti manager: jarmu eszleles, NUI init, export API
-- ============================================================

-- ── Allapot ─────────────────────────────────────────────────

hudVisible   = false   -- modulok ezzel ellenorzik (global, modules/* is olvassak)
inVehicle    = false   -- modulok ezzel ellenorzik (global)
moduleStates = {}

for name, cfg in pairs(Config.Modules) do
    moduleStates[name] = cfg.enabled
end

-- ── NUI kommunikacio ───────────────────────────────────────────

--- NUI uzenet kuldese a modul loopoknak.
--- FONTOS: ez NEM blokkolja hudVisible alapjan - a loopok maguk ellenorzik.
--- A send fuggveny csak arra valo, hogy a client.lua exportjaibol hivjunk
--- NUI-t (setSeatbelt, setSiren, setEngineState stb.) ahol a hudVisible
--- ellenorzes helyes. A modul loopok kozvetlenul SendNUIMessage-t hasznalnak.
---@param action string
---@param data table
function NXN.VehHUD.Send(action, data)
    local payload = data or {}
    payload.action = action
    NXN.VehHUD.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

--- Export-alapu NUI kuldese: csak akkor kuldi ha HUD lathato
--- Pl. setSeatbelt, setSiren, setEngineState exportokhoz
---@param action string
---@param data table
function NXN.VehHUD.SendIfVisible(action, data)
    if not hudVisible then return end
    NXN.VehHUD.Send(action, data)
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

-- ── Jarmu eszleles loop ──────────────────────────────────────────

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
            -- HUD lathatova tetele ELOTT kuldjuk a configot
            SendConfig()
            hudVisible  = true
            SendNUIMessage({ action = 'setVisible', visible = true })
            NXN.VehHUD.Log(('Jarmubbe szallt: entId=%d'):format(veh))
        elseif veh == 0 and lastVehicle ~= 0 then
            -- Kiszallt
            lastVehicle = 0
            inVehicle   = false
            hudVisible  = false
            SendNUIMessage({ action = 'setVisible', visible = false })
            NXN.VehHUD.Log('Kiszallt a jarmubol')
        end
    end
end)

-- ── Lathatosag kezeles ─────────────────────────────────────────

local function SetHudVisible(state)
    hudVisible = state
    SendNUIMessage({ action = 'setVisible', visible = state })
    NXN.VehHUD.Log(('HUD lathatosag: %s'):format(tostring(state)))
end

-- ── Modul kezeles ────────────────────────────────────────────

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
    return moduleStates
end)

exports('setPosition', function(pos)
    SendNUIMessage({ action = 'setPosition', position = pos })
    NXN.VehHUD.Log(('Pozicio: %s'):format(pos))
end)

--- Uzemanyag ertek frissitese (nxn-fuel fogja hivni)
exports('setFuel', function(value)
    if not moduleStates['fuel'] then return end
    NXN.VehHUD.Log(('setFuel: %d'):format(value))
    -- Kozvetlenul kuldi, nem hudVisible-fuggoen (az nxn-fuel dontesi kokon belul van)
    SendNUIMessage({ action = 'updateModule', module = 'fuel', value = value })
end)

--- Biztonsagi ov allapot (nxn-seatbelt fogja hivni)
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

--- Szirena allapot (nxn-sirencontrol fogja hivni)
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

--- Motor allapot (nxn-engine hivja)
exports('setEngineState', function(state)
    if not moduleStates['engine'] then return end
    NXN.VehHUD.Log(('setEngineState: %s'):format(state))
    SendNUIMessage({ action = 'updateModule', module = 'engine', state = state })
end)

--- Altalanos modul adat frissitese kulso resource-bol
exports('updateModuleData', function(moduleName, data)
    local payload = data
    payload.action = 'updateModuleData'
    payload.module = moduleName
    SendNUIMessage(payload)
    NXN.VehHUD.Log(('updateModuleData: %s'):format(moduleName))
end)
