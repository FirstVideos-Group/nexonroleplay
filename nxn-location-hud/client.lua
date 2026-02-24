-- ============================================================
--  nxn-location-hud | client.lua
--  Kozponti manager: init, NUI kommunikacio, export API
-- ============================================================

-- ── Allapot ──────────────────────────────────────────────────

local hudVisible   = true
local moduleStates = {}

for name, cfg in pairs(Config.Modules) do
    moduleStates[name] = cfg.enabled
end

-- ── NUI kommunikacio ─────────────────────────────────────────

--- NUI uzenet kuldese
---@param action string
---@param data table
function NXN.LocHUD.Send(action, data)
    if not hudVisible then return end
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
        action     = 'init',
        position   = Config.Position,
        showMinimap = Config.ShowMinimap,
        modules    = modulesCfg,
    })
    NXN.LocHUD.Log(('LocHUD init kuldve, pos=%s'):format(Config.Position))
end

-- ── Spawn inicializalas ──────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.LocHUD.Log('playerSpawned – LocHUD inicializalas')
    Wait(300)
    SendConfig()
    SendNUIMessage({ action = 'setVisible', visible = true })
end)

-- ── Lathatosag kezeles ───────────────────────────────────────

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
    NXN.LocHUD.Log(('Modul allapot: %s = %s'):format(name, tostring(state)))
    return true
end

-- ── Exportok ─────────────────────────────────────────────────

--- HUD elrejtese / mutatasa
---@param state boolean
exports('setVisible', function(state)
    SetHudVisible(state)
end)

--- HUD aktualis lathatosaga
---@return boolean
exports('isVisible', function()
    return hudVisible
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
---@param pos string  'bottom-left'|'bottom-right'|'top-left'|'top-right'
exports('setPosition', function(pos)
    SendNUIMessage({ action = 'setPosition', position = pos })
    NXN.LocHUD.Log(('Pozicio: %s'):format(pos))
end)

--- Zona es banda adat beallitasa (nxn-gang hivja)
---@param zoneName string       zona neve
---@param gangName string|nil   banda neve (nil ha nincs)
---@param gangColor string|nil  hex szin pl. '#f05b5b'
exports('setZone', function(zoneName, gangName, gangColor)
    if not moduleStates['zone'] then return end
    NXN.LocHUD.Log(('setZone: zone=%s gang=%s'):format(tostring(zoneName), tostring(gangName)))
    local show = (zoneName ~= nil and zoneName ~= '')
    NXN.LocHUD.Send('updateModule', {
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

--- Zona adatok torlese (jatekos elhagyta a zonat) (nxn-gang hivja)
exports('clearZone', function()
    if not moduleStates['zone'] then return end
    NXN.LocHUD.Log('clearZone')
    SendNUIMessage({ action = 'hideModuleTemporary', module = 'zone' })
end)

--- Veszelyesseg szint frissitese (nxn-dispatch hivja)
---@param level number  0-5 (0 = nincs veszely)
---@param label string|nil  pl. 'AKTIV LOVOLDOZES'
exports('setDanger', function(level, label)
    if not moduleStates['danger'] then return end
    local lvl = tonumber(level) or 0
    NXN.LocHUD.Log(('setDanger: level=%d label=%s'):format(lvl, tostring(label)))
    NXN.LocHUD.Send('updateModule', {
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

--- Korozesi informacio frissitese (nxn-wantedstatus hivja)
---@param wanted boolean
---@param level number|nil   1-5 csillag
---@param label string|nil   pl. '3 csillag - BVNB'
exports('setWanted', function(wanted, level, label)
    if not moduleStates['wanted'] then return end
    NXN.LocHUD.Log(('setWanted: wanted=%s level=%s'):format(tostring(wanted), tostring(level)))
    NXN.LocHUD.Send('updateModule', {
        module  = 'wanted',
        wanted  = wanted,
        level   = level or 0,
        label   = label or '',
    })
    if wanted then
        SendNUIMessage({ action = 'showModuleTemporary', module = 'wanted' })
    else
        SendNUIMessage({ action = 'hideModuleTemporary', module = 'wanted' })
    end
end)

--- Jatekos statusz frissitese (kulső resource is hivhatja)
---@param status string  'on_foot'|'in_vehicle'|'running'|'swimming'|'parachuting'
exports('setPlayerStatus', function(status)
    if not moduleStates['playerstatus'] then return end
    NXN.LocHUD.Log(('setPlayerStatus: %s'):format(tostring(status)))
    NXN.LocHUD.Send('updateModule', { module = 'playerstatus', status = status })
end)

--- Altalanos modul adat push (boviteshez)
---@param moduleName string
---@param data table
exports('updateModuleData', function(moduleName, data)
    local payload = data
    payload.action = 'updateModuleData'
    payload.module = moduleName
    SendNUIMessage(payload)
    NXN.LocHUD.Log(('updateModuleData: %s'):format(moduleName))
end)
