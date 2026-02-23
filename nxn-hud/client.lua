-- ============================================================
--  nxn-hud | client.lua
--  Kozponti HUD manager – modulok koordinalasa, export API
-- ============================================================

-- ── Allapot ───────────────────────────────────────────────

local hudVisible   = true    -- globalis HUD lathatosag
local moduleStates = {}      -- { [moduleName] = bool } – egyedi modul on/off

-- Modulallapotok inicializalasa a Config alapjan
for name, cfg in pairs(Config.Modules) do
    moduleStates[name] = cfg.enabled
end

-- ── NUI kommunikacio ───────────────────────────────────────

--- Adat kuldese a NUI fele
---@param action string
---@param data table
function NXN.HUD.Send(action, data)
    if not hudVisible then return end
    local payload = data or {}
    payload.action = action
    NXN.HUD.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

--- HUD konfig kuldese inicializalaskor
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
        action   = 'init',
        position = Config.Position,
        modules  = modulesCfg,
    })
    NXN.HUD.Log(('HUD init kuldve, pozicio=%s'):format(Config.Position))
end

-- ── Lathatosag kezeles ──────────────────────────────────────

local function SetHudVisible(state)
    hudVisible = state
    SendNUIMessage({ action = 'setVisible', visible = state })
    NXN.HUD.Log(('HUD lathatosag: %s'):format(tostring(state)))
end

-- ── Modul kezeles ──────────────────────────────────────────

local function SetModuleEnabled(name, state)
    if moduleStates[name] == nil then
        NXN.HUD.Warn(('SetModuleEnabled: ismeretlen modul: %s'):format(name))
        return false
    end
    moduleStates[name] = state
    SendNUIMessage({ action = 'setModule', module = name, enabled = state })
    NXN.HUD.Log(('Modul allapot: %s = %s'):format(name, tostring(state)))
    return true
end

-- ── Spawn inicializalas ──────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.HUD.Log('playerSpawned – HUD inicializalas')
    Wait(500)  -- varunk, amig a needs is betolt
    SendConfig()
end)

-- ── nxn-needs frissules figyelese ────────────────────────────

AddEventHandler('nxn-needs:client:updated', function(needs)
    NXN.HUD.Log(('needs updated event fogadva'))
    -- Needs modulok frissitese
    if moduleStates['hunger'] then
        NXN.HUD.Send('updateModule', { module = 'hunger', value = needs.hunger or 0 })
    end
    if moduleStates['thirst'] then
        NXN.HUD.Send('updateModule', { module = 'thirst', value = needs.thirst or 0 })
    end
    if moduleStates['stress'] then
        NXN.HUD.Send('updateModule', { module = 'stress', value = needs.stress or 0 })
    end
end)

-- ── Exportok ─────────────────────────────────────────────────

--- HUD elrejtese / mutatasa
---@param state boolean
exports('setVisible', function(state)
    SetHudVisible(state)
end)

--- Visszaadja a HUD aktualis lathatosagat
---@return boolean
exports('isVisible', function()
    return hudVisible
end)

--- Egy modul be- vagy kikapcsolasa
---@param name string  pl. 'health', 'stress', 'money'
---@param state boolean
---@return boolean  siker
exports('setModule', function(name, state)
    return SetModuleEnabled(name, state)
end)

--- Egy modul aktualis allapota
---@param name string
---@return boolean|nil
exports('getModuleState', function(name)
    return moduleStates[name]
end)

--- Az osszes modul allapota
---@return table
exports('getAllModuleStates', function()
    return moduleStates
end)

--- Pozicio valtoztatasa menet kozben
---@param pos string  'bottom-left'|'bottom-right'|'top-left'|'top-right'
exports('setPosition', function(pos)
    SendNUIMessage({ action = 'setPosition', position = pos })
    NXN.HUD.Log(('Pozicio valtoztatva: %s'):format(pos))
end)

--- Egy modul ertekenek frissitese kulso resource-bol
---@param moduleName string
---@param value any
exports('updateModule', function(moduleName, value)
    NXN.HUD.Send('updateModule', { module = moduleName, value = value })
end)

--- Egyedi modul adat kuldese (pl. munka/penz adatok)
---@param moduleName string
---@param data table
exports('updateModuleData', function(moduleName, data)
    local payload = data
    payload.action = 'updateModuleData'
    payload.module = moduleName
    SendNUIMessage(payload)
    NXN.HUD.Log(('updateModuleData: %s'):format(moduleName))
end)
