-- ============================================================
--  nxn-hud | client.lua
--  Kozponti HUD manager
--  FIX: moduleStates es hudVisible GLOBAL (nem local),
--       hogy a modules/*.lua fajlok is elerhessek oket
-- ============================================================

-- FIX: 'local' helyett global, hogy a modulok lathassak
hudVisible   = true
moduleStates = {}

-- Modulallapotok inicializalasa a Config alapjan
for name, cfg in pairs(Config.Modules) do
    moduleStates[name] = cfg.enabled
end

-- ── NUI kommunikacio ─────────────────────────────────────────────

---@param action string
---@param data table
function NXN.HUD.Send(action, data)
    if not hudVisible then return end
    local payload = data or {}
    payload.action = action
    NXN.HUD.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
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
        action   = 'init',
        position = Config.Position,
        modules  = modulesCfg,
    })
    NXN.HUD.Log(('HUD init kuldve, pozicio=%s'):format(Config.Position))
end

-- ── Lathatosag ────────────────────────────────────────────────

local function SetHudVisible(state)
    hudVisible = state
    SendNUIMessage({ action = 'setVisible', visible = state })
    NXN.HUD.Log(('HUD lathatosag: %s'):format(tostring(state)))
end

-- ── Modul kezeles ─────────────────────────────────────────────

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

-- ── Spawn ───────────────────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.HUD.Log('playerSpawned – HUD inicializalas')
    Wait(500)
    SendConfig()
end)

-- ── nxn-needs frissites ────────────────────────────────────────

AddEventHandler('nxn-needs:client:updated', function(needs)
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

exports('setVisible', function(state)
    SetHudVisible(state)
end)

exports('isVisible', function()
    return hudVisible
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
    NXN.HUD.Log(('Pozicio valtoztatva: %s'):format(pos))
end)

exports('updateModule', function(moduleName, value)
    NXN.HUD.Send('updateModule', { module = moduleName, value = value })
end)

exports('updateModuleData', function(moduleName, data)
    local payload = data
    payload.action = 'updateModuleData'
    payload.module = moduleName
    SendNUIMessage(payload)
    NXN.HUD.Log(('updateModuleData: %s'):format(moduleName))
end)
