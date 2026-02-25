-- ============================================================
--  nxn-location-hud | client.lua
--  Kozponti manager: init, NUI kommunikacio, export API
-- ============================================================

-- ── Allapot ─────────────────────────────────────────────────

hudVisible   = false   -- global: modul loopok olvassak
moduleStates = {}      -- global: modul loopok olvassak

for name, cfg in pairs(Config.Modules) do
    moduleStates[name] = cfg.enabled
end

-- ── NUI kommunikacio ──────────────────────────────────────────

--- Kozvetlen NUI kuldese (nem blokkolja hudVisible)
--- A modul loopok KOZVETLENUL SendNUIMessage-t hasznalnak!
--- Ez csak kulso export-hivoknak van megtartva (setZone, setDanger, stb.)
---@param action string
---@param data table
function NXN.LocHUD.Send(action, data)
    local payload = data or {}
    payload.action = action
    NXN.LocHUD.Log(('NUI send: action=%s'):format(action))
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
        action      = 'init',
        position    = Config.Position,
        showMinimap = Config.ShowMinimap,
        modules     = modulesCfg,
    })
    NXN.LocHUD.Log(('LocHUD init kuldve, pos=%s'):format(Config.Position))
end

local function ShowHUD()
    hudVisible = true
    SendNUIMessage({ action = 'setVisible', visible = true })
    NXN.LocHUD.Log('HUD megjelenik')
end

-- ── Inicializalas ────────────────────────────────────────────
-- Megbizhatobb mint csak playerSpawned: azonnal indul resource start-kor,
-- es playerSpawned-ra is figyel (pl. respawn utan)

local initialized = false

local function Init()
    if initialized then return end
    initialized = true
    NXN.LocHUD.Log('LocHUD inicializalas')
    SendConfig()
    ShowHUD()
end

-- Resource indulasakor: a jatekos mar a vilagban van (pl. hot-restart)
CreateThread(function()
    -- Rovid varakozas hogy a NUI betoltodjek
    Wait(500)
    -- Ellenorizzuk hogy a jatekos mar spawned-e
    if NetworkIsPlayerActive(PlayerId()) then
        NXN.LocHUD.Log('Resource start: jatekos aktiv, init')
        Init()
    end
end)

-- Spawn esemeny: uj csatlakozas vagy respawn
AddEventHandler('playerSpawned', function()
    NXN.LocHUD.Log('playerSpawned – LocHUD init / ujrainit')
    -- Reset hogy ujraindul (pl. respawn utan)
    initialized = false
    -- Varakozas hogy a ped hozzarendelodjon
    Wait(500)
    Init()
end)

-- ── Lathatosag kezeles ─────────────────────────────────────────

local function SetHudVisible(state)
    hudVisible = state
    SendNUIMessage({ action = 'setVisible', visible = state })
    NXN.LocHUD.Log(('HUD lathatosag: %s'):format(tostring(state)))
end

-- ── Modul kezeles ────────────────────────────────────────────

local function SetModuleEnabled(name, state)
    if moduleStates[name] == nil then
        NXN.LocHUD.Warn(('SetModuleEnabled: ismeretlen modul: %s'):format(name))
        return false
    end
    moduleStates[name] = state
    SendNUIMessage({ action = 'setModule', module = name, enabled = state })
    NXN.LocHUD.Log(('Modul: %s = %s'):format(name, tostring(state)))
    return true
end

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
    NXN.LocHUD.Log(('Pozicio: %s'):format(pos))
end)

--- Zona es banda adat (nxn-gang hivja)
exports('setZone', function(zoneName, gangName, gangColor)
    if not moduleStates['zone'] then return end
    NXN.LocHUD.Log(('setZone: zone=%s gang=%s'):format(tostring(zoneName), tostring(gangName)))
    local show = (zoneName ~= nil and zoneName ~= '')
    -- Kozvetlenul kuldi (NXN.LocHUD.Send mar nem blokkolja hudVisible)
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
    if not moduleStates['zone'] then return end
    NXN.LocHUD.Log('clearZone')
    SendNUIMessage({ action = 'hideModuleTemporary', module = 'zone' })
end)

--- Veszelyesseg (nxn-dispatch hivja)
exports('setDanger', function(level, label)
    if not moduleStates['danger'] then return end
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
        SendNUIMessage({ action = 'showModuleTemporary', module = 'danger' })
    else
        local delay = (Config.Modules.danger and Config.Modules.danger.hideDelay) or 8000
        SetTimeout(delay, function()
            SendNUIMessage({ action = 'hideModuleTemporary', module = 'danger' })
        end)
    end
end)

--- Korozési info (nxn-wantedstatus hivja)
exports('setWanted', function(wanted, level, label)
    if not moduleStates['wanted'] then return end
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

--- Jatekos statusz (kulso resource is hivhatja)
exports('setPlayerStatus', function(status)
    if not moduleStates['playerstatus'] then return end
    NXN.LocHUD.Log(('setPlayerStatus: %s'):format(tostring(status)))
    SendNUIMessage({ action = 'updateModule', module = 'playerstatus', status = status })
end)

--- Altalanos modul adat push
exports('updateModuleData', function(moduleName, data)
    local payload = data
    payload.action = 'updateModuleData'
    payload.module = moduleName
    SendNUIMessage(payload)
    NXN.LocHUD.Log(('updateModuleData: %s'):format(moduleName))
end)
