-- ============================================================
--  nxn-minimap | client.lua
-- ============================================================

-- ── Allapot ─────────────────────────────────────────────────

local minimapVisible = Config.MinimapEnabled
local showBlips      = Config.ShowBlips
local showAreas      = Config.ShowAreas
local districtData   = nil
local gpsActive      = false
local initialized    = false

-- ── NUI segéd ──────────────────────────────────────────────

-- #70: shallow copy – a hívó eredeti táblája nem módosul
local function NUISend(action, data)
    local payload = { action = action }
    if data then
        for k, v in pairs(data) do payload[k] = v end
    end
    NXN.Minimap.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

-- ── Natív minimap alap ─────────────────────────────────────────

local function ApplyMinimapStyle()
    SetRadarBigmapEnabled(false, false)
    DisplayRadar(minimapVisible)
end

-- ── Natív HUD elemek elrejtése ──────────────────────────────────
-- GTA minden frame-ben visszaallitja ezeket, ezert Wait(0) loopban kell hivni.
--
-- Valós FiveM HUD komponens indexek (GetHudComponentState / HideHudComponentThisFrame):
--   6  = vehicle name
--   7  = area name   (LITTLE SEOUL stb.)  ← ezt rejtük el
--   8  = vehicle class
--   9  = street name (San Andreas Ave stb.)  ← ezt rejtük el
--  11  = minimap / radar (nem rejtjük el, csak újradizájnoljuk)
-- #72: if DisplayAreaName felesleges check eltávolítva – mindig elérhető
-- #74: Config.HiddenHUDComponents itérálása – dinamikusan konfigurálható

local function HideNativeComponents()
    if not Config.HideNativeHUDComponents then return end

    HideHudComponentThisFrame(7)  -- area name
    HideHudComponentThisFrame(9)  -- street name
    DisplayAreaName(false)         -- GTA dedikált nativ (mindig elérhető)

    -- #74: dinamikusan konfigurálható extra komponensek
    for _, idx in ipairs(Config.HiddenHUDComponents or {}) do
        HideHudComponentThisFrame(idx)
    end
end

-- ── Blip / belsőteres mód (frame-folytonos) ──────────────────────
-- SetRadarAsInteriorThisFrame(): csak az adott frame-re él.
-- #71: dummy 0,0,0,0 koordináták – a pozíció nem befolyásolja a blip-elrejtést,
--      felesleges GetEntityCoords/GetEntityHeading hívások elávolítva (~180 nativ/s)

local function ApplyBlipVisibility()
    if not showBlips then
        SetRadarAsInteriorThisFrame(0.0, 0.0, 0.0, 0.0, 1.0)
    end
end

-- ── GPS poll ────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(1000)
        if not minimapVisible then goto gps_skip end

        local wp     = GetFirstBlipInfoId(8)
        local newGps = DoesBlipExist(wp)

        if newGps ~= gpsActive then
            gpsActive = newGps
            NXN.Minimap.Log(('GPS aktiv: %s'):format(tostring(gpsActive)))
            NUISend('setGPS', { active = gpsActive, label = Config.GPSActiveLabel })
        end

        ::gps_skip::
    end
end)

-- ── Fő HUD loop (Wait(0) – frame-folytonos nativ hívók) ─────────────

CreateThread(function()
    while true do
        Wait(0)
        ApplyMinimapStyle()
        HideNativeComponents()
        ApplyBlipVisibility()
    end
end)

-- ── Inicializálás ────────────────────────────────────────────

local function Init()
    if initialized then return end
    initialized = true
    NXN.Minimap.Log('Minimap NUI init')
    NUISend('init', {
        position       = Config.Position,
        width          = Config.Width,
        height         = Config.Height,
        showDistrict   = Config.ShowDistrict,
        showGPS        = Config.ShowGPS,
        gpsActiveLabel = Config.GPSActiveLabel,
        showBlips      = showBlips,
        showAreas      = showAreas,
        visible        = minimapVisible,
    })
end

CreateThread(function()
    Wait(500)
    if NetworkIsPlayerActive(PlayerId()) then
        NXN.Minimap.Log('Resource start: jatekos aktiv, init')
        Init()
    end
end)

AddEventHandler('playerSpawned', function()
    NXN.Minimap.Log('playerSpawned – minimap init')
    initialized = false
    Wait(500)
    Init()
end)

-- ── Láthatóság ──────────────────────────────────────────────

local function SetMinimapVisible(state)
    minimapVisible = state
    DisplayRadar(state)
    NUISend('setVisible', { visible = state })
    NXN.Minimap.Log(('SetMinimapVisible: %s'):format(tostring(state)))
end

-- ── Exportok ────────────────────────────────────────────────

exports('setVisible', function(state)
    SetMinimapVisible(state)
end)

exports('isVisible', function()
    return minimapVisible
end)

exports('setBlips', function(state)
    showBlips = state
    NXN.Minimap.Log(('setBlips: %s'):format(tostring(state)))
    NUISend('setBlips', { visible = state })
end)

-- #73: NUISend hozzáadva – korábban a NUI nem reagált a setAreas hívásra
exports('setAreas', function(state)
    showAreas = state
    NXN.Minimap.Log(('setAreas: %s'):format(tostring(state)))
    NUISend('setAreas', { visible = state })
end)

exports('setGPSEnabled', function(state)
    NXN.Minimap.Log(('setGPSEnabled: %s'):format(tostring(state)))
    if not state then SetWaypointOff() end
    NUISend('setGPSEnabled', { enabled = state })
end)

exports('setDistrict', function(number, name, color)
    if not Config.ShowDistrict then return end
    districtData = { number = number, name = name, color = color }
    NXN.Minimap.Log(('setDistrict: #%s - %s'):format(tostring(number), tostring(name)))
    NUISend('setDistrict', {
        number  = tostring(number),
        name    = name  or '',
        color   = color or '',
        visible = true,
    })
end)

exports('clearDistrict', function()
    districtData = nil
    NXN.Minimap.Log('clearDistrict')
    NUISend('setDistrict', { visible = false })
end)

exports('setPosition', function(pos)
    NXN.Minimap.Log(('setPosition: %s'):format(tostring(pos)))
    NUISend('setPosition', { position = pos })
end)

exports('getDistrict', function()
    return districtData
end)
