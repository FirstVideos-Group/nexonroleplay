-- ============================================================
--  nxn-location-hud | client.lua
--  Kozponti manager: init, NUI kommunikacio, export API
-- ============================================================

-- ── Allapot ─────────────────────────────────────────────────
-- #63: NXN.LocHUD nevterbe mozgatva (nem globalis valtozok tobbet)
-- A modul fajlok NXN.LocHUD.hudVisible / NXN.LocHUD.moduleStates-t hasznalnak

NXN.LocHUD.hudVisible   = false
NXN.LocHUD.moduleStates = {}

for name, cfg in pairs(Config.Modules) do
    NXN.LocHUD.moduleStates[name] = cfg.enabled
end

-- #66: dangerHideTimer token – korabbi SetTimeout nem rejti el az aktiv dangert
local dangerHideTimer = nil

-- ── NUI kommunikacio ──────────────────────────────────────────

---@param action string
---@param data table
function NXN.LocHUD.Send(action, data)
    local payload = data or {}
    payload.action = action
    NXN.LocHUD.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

local function SendConfig()
    local modulesCfg = {}
    for name, cfg in pairs(Config.Modules) do
        modulesCfg[name] = {
            enabled       = NXN.LocHUD.moduleStates[name],
            alwaysVisible = cfg.alwaysVisible,
            order         = cfg.order,
        }
    end
    SendNUIMessage({
        action      = 'init',
        position    = Config.Position,
        showMinimap = Config.ShowMinimap,
        modules     = modulesCfg,
    })
    NXN.LocHUD.Log(('LocHUD init kuldve, pos=%s'):format(Config.Position))
end

local function ShowHUD()
    NXN.LocHUD.hudVisible = true
    SendNUIMessage({ action = 'setVisible', visible = true })
    NXN.LocHUD.Log('HUD megjelenik')
end

-- ── Inicializalas ────────────────────────────────────────────

local initialized = false

local function Init()
    if initialized then return end
    initialized = true
    NXN.LocHUD.Log('LocHUD inicializalas')
    SendConfig()
    ShowHUD()
end

CreateThread(function()
    Wait(500)
    if NetworkIsPlayerActive(PlayerId()) then
        NXN.LocHUD.Log('Resource start: jatekos aktiv, init')
        Init()
    end
end)

AddEventHandler('playerSpawned', function()
    NXN.LocHUD.Log('playerSpawned – LocHUD init / ujrainit')
    initialized = false
    Wait(500)
    Init()
end)

-- ── Lathatosag kezeles ─────────────────────────────────────────

local function SetHudVisible(state)
    NXN.LocHUD.hudVisible = state
    SendNUIMessage({ action = 'setVisible', visible = state })
    NXN.LocHUD.Log(('HUD lathatosag: %s'):format(tostring(state)))
end

-- ── Modul kezeles ────────────────────────────────────────────

local function SetModuleEnabled(name, state)
    if NXN.LocHUD.moduleStates[name] == nil then
        NXN.LocHUD.Warn(('SetModuleEnabled: ismeretlen modul: %s'):format(name))
        return false
    end
    NXN.LocHUD.moduleStates[name] = state
    SendNUIMessage({ action = 'setModule', module = name, enabled = state })
    NXN.LocHUD.Log(('Modul: %s = %s'):format(name, tostring(state)))
    return true
end

-- ── Exportok ─────────────────────────────────────────────────

exports('setVisible', function(state)
    SetHudVisible(state)
end)

exports('isVisible', function()
    return NXN.LocHUD.hudVisible
end)

exports('setModule', function(name, state)
    return SetModuleEnabled(name, state)
end)

exports('getModuleState', function(name)
    return NXN.LocHUD.moduleStates[name]
end)

-- #64: shallow copy – kulso resource nem tud kozvetlenul modositani
exports('getAllModuleStates', function()
    local copy = {}
    for k, v in pairs(NXN.LocHUD.moduleStates) do copy[k] = v end
    return copy
end)

exports('setPosition', function(pos)
    SendNUIMessage({ action = 'setPosition', position = pos })
    NXN.LocHUD.Log(('Pozicio: %s'):format(pos))
end)

exports('setZone', function(zoneName, gangName, gangColor)
    if not NXN.LocHUD.moduleStates['zone'] then return end
    NXN.LocHUD.Log(('setZone: zone=%s gang=%s'):format(tostring(zoneName), tostring(gangName)))
    local show = (zoneName ~= nil and zoneName ~= '')
    SendNUIMessage({
        action    = 'updateModule',
        module    = 'zone',
        zoneName  = zoneName  or '',
        gangName  = gangName  or '',
        gangColor = gangColor or '',
    })
    if show then
        SendNUIMessage({ action = 'showModuleTemporary', module = 'zone' })
    else
        SendNUIMessage({ action = 'hideModuleTemporary', module = 'zone' })
    end
end)

exports('clearZone', function()
    if not NXN.LocHUD.moduleStates['zone'] then return end
    NXN.LocHUD.Log('clearZone')
    SendNUIMessage({ action = 'hideModuleTemporary', module = 'zone' })
end)

-- #66: dangerHideTimer token-alapu guard
-- Minden uj setDanger hivas egy uj token-t kap; a regi SetTimeout csak akkor
-- rejti el a modult, ha a token meg mindig aktualis (nem indult kozben uj hivas)
exports('setDanger', function(level, label)
    if not NXN.LocHUD.moduleStates['danger'] then return end
    local lvl = tonumber(level) or 0
    NXN.LocHUD.Log(('setDanger: level=%d label=%s'):format(lvl, tostring(label)))
    SendNUIMessage({
        action = 'updateModule',
        module = 'danger',
        level  = lvl,
        label  = label or '',
    })
    local threshold = (Config.Modules.danger and Config.Modules.danger.threshold) or 1
    if lvl >= threshold then
        dangerHideTimer = nil  -- megszakitja az esetleges folyamatban levo timert
        SendNUIMessage({ action = 'showModuleTemporary', module = 'danger' })
    else
        local currentToken = {}
        dangerHideTimer = currentToken
        local delay = (Config.Modules.danger and Config.Modules.danger.hideDelay) or 8000
        SetTimeout(delay, function()
            -- Csak akkor rejti el, ha nem indult kozben ujabb setDanger hivas
            if dangerHideTimer == currentToken then
                dangerHideTimer = nil
                SendNUIMessage({ action = 'hideModuleTemporary', module = 'danger' })
            end
        end)
    end
end)

exports('setWanted', function(wanted, level, label)
    if not NXN.LocHUD.moduleStates['wanted'] then return end
    NXN.LocHUD.Log(('setWanted: wanted=%s level=%s'):format(tostring(wanted), tostring(level)))
    SendNUIMessage({
        action = 'updateModule',
        module = 'wanted',
        wanted = wanted,
        level  = level or 0,
        label  = label or '',
    })
    if wanted then
        SendNUIMessage({ action = 'showModuleTemporary', module = 'wanted' })
    else
        SendNUIMessage({ action = 'hideModuleTemporary', module = 'wanted' })
    end
end)

exports('setPlayerStatus', function(status)
    if not NXN.LocHUD.moduleStates['playerstatus'] then return end
    NXN.LocHUD.Log(('setPlayerStatus: %s'):format(tostring(status)))
    SendNUIMessage({ action = 'updateModule', module = 'playerstatus', status = status })
end)

-- #65: shallow copy – a hivó tablajat nem modositjuk
exports('updateModuleData', function(moduleName, data)
    local payload = {}
    for k, v in pairs(data) do payload[k] = v end
    payload.action = 'updateModuleData'
    payload.module = moduleName
    SendNUIMessage(payload)
    NXN.LocHUD.Log(('updateModuleData: %s'):format(moduleName))
end)
