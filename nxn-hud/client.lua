-- ============================================================
--  nxn-hud | client.lua
--  Kozponti HUD manager
-- ============================================================

-- Állapot az NXN.HUD namespace-ben tárolva (#23)
NXN.HUD.visible      = true
NXN.HUD.moduleStates = {}

-- Modulallapotok inicializalasa a Config alapjan
for name, cfg in pairs(Config.Modules) do
    NXN.HUD.moduleStates[name] = cfg.enabled
end

-- ── NUI kommunikacio ─────────────────────────────────────────

---@param action string
---@param data   table
function NXN.HUD.Send(action, data)
    if not NXN.HUD.visible then return end
    local payload = data or {}
    payload.action = action
    NXN.HUD.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

local function SendConfig()
    local modulesCfg = {}
    for name, cfg in pairs(Config.Modules) do
        modulesCfg[name] = {
            enabled       = NXN.HUD.moduleStates[name],
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

-- ── Lathatosag ────────────────────────────────────────────

local function SetHudVisible(state)
    NXN.HUD.visible = state
    SendNUIMessage({ action = 'setVisible', visible = state })
    -- #24: Ha lathatova valik, friss allapot-szinkronizaciot kuldunk
    if state then
        SendConfig()
    end
    NXN.HUD.Log(('HUD lathatosag: %s'):format(tostring(state)))
end

-- ── Modul kezeles ─────────────────────────────────────────

local function SetModuleEnabled(name, state)
    if NXN.HUD.moduleStates[name] == nil then
        NXN.HUD.Warn(('SetModuleEnabled: ismeretlen modul: %s'):format(name))
        return false
    end
    NXN.HUD.moduleStates[name] = state
    SendNUIMessage({ action = 'setModule', module = name, enabled = state })
    NXN.HUD.Log(('Modul allapot: %s = %s'):format(name, tostring(state)))
    return true
end

-- ── Spawn ───────────────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.HUD.Log('playerSpawned – HUD inicializalas')
    Wait(500)
    SendConfig()
end)

-- ── nxn-needs frissites ───────────────────────────────────────
-- #28: stress kezelese a stress.lua modulban tortenik, itt csak hunger+thirst

AddEventHandler('nxn-needs:client:updated', function(needs)
    if NXN.HUD.moduleStates['hunger'] then
        NXN.HUD.Send('updateModule', { module = 'hunger', value = needs.hunger or 0 })
    end
    if NXN.HUD.moduleStates['thirst'] then
        NXN.HUD.Send('updateModule', { module = 'thirst', value = needs.thirst or 0 })
    end
    -- stress: stress.lua kezeli teljes egeszeben
end)

-- ── Exportok ───────────────────────────────────────────────

exports('setVisible', function(state)
    SetHudVisible(state)
end)

exports('isVisible', function()
    return NXN.HUD.visible
end)

exports('setModule', function(name, state)
    return SetModuleEnabled(name, state)
end)

exports('getModuleState', function(name)
    return NXN.HUD.moduleStates[name]
end)

exports('getAllModuleStates', function()
    return NXN.HUD.moduleStates
end)

exports('setPosition', function(pos)
    SendNUIMessage({ action = 'setPosition', position = pos })
    NXN.HUD.Log(('Pozicio valtoztatva: %s'):format(pos))
end)

exports('updateModule', function(moduleName, value)
    NXN.HUD.Send('updateModule', { module = moduleName, value = value })
end)

-- #25: shallow copy a data tablarol, hogy a hivó eredeti tablaja ne valtozzon
exports('updateModuleData', function(moduleName, data)
    local payload = {}
    for k, v in pairs(data or {}) do payload[k] = v end
    payload.action = 'updateModuleData'
    payload.module = moduleName
    SendNUIMessage(payload)
    NXN.HUD.Log(('updateModuleData: %s'):format(moduleName))
end)
