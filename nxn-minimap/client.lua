-- ============================================================
--  nxn-minimap | client.lua
--  FIX: SetMinimapInInterior -> SetRadarAsInteriorThisFrame
--  FIX: Helyes HUD elrejtesi nativok (DisplayAreaName, stb.)
--  FIX: playerSpawned + resource start megbizhatosag
-- ============================================================

-- ── Allapot ─────────────────────────────────────────────────

local minimapVisible = Config.MinimapEnabled
local showBlips      = Config.ShowBlips
local showAreas      = Config.ShowAreas
local districtData   = nil
local gpsActive      = false
local initialized    = false

-- ── NUI segd ──────────────────────────────────────────────

local function NUISend(action, data)
    local payload = data or {}
    payload.action = action
    NXN.Minimap.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

-- ── Natív minimap alap ─────────────────────────────────────

local function ApplyMinimapStyle()
    SetRadarBigmapEnabled(false, false)
    DisplayRadar(minimapVisible)
end

-- ── Natív HUD elemek elrejtese ──────────────────────────────
-- A GTA minden frame-ben visszaallitja ezeket, ezert Wait(0) loopban kell hivni.
-- Hasznalunk ket megkozelitest egyutt:
--   1. HideHudComponentThisFrame – az adott HUD elemet rejtjuk el
--   2. DisplayAreaName / DisplayStreetName (ha letezik) – GTA dedikalt nativok
--
-- Helyes HUD komponens indexek (FiveM / GTA V):
--   2  = radar (minimap szoveg overlay)
--   6  = vehicle name
--   7  = area name  (LITTLE SEOUL stb.)
--   9  = street name (San Andreas Ave stb.)

local function HideNativeComponents()
    if not Config.HideNativeHUDComponents then return end

    -- Terulet es utca szoveg elrejtese – ezeket az nxn-location-hud jeleníti meg
    HideHudComponentThisFrame(7)   -- AREA_NAME
    HideHudComponentThisFrame(9)   -- STREET_NAME

    -- Dedikalt nativok: ezek biztosabban mukodnek mint a komponens index
    -- DisplayAreaName: ha false, a GTA nem rendereli a korzetkiemelest
    -- (Csak akkor letezik ha a GTA verzio tamogatja – biztonsagi check-kel)
    if DisplayAreaName then
        DisplayAreaName(false)
    end
end

-- ── Blip / belsoteres mod (frame-folytonos) ─────────────────────
-- SetRadarAsInteriorThisFrame(): csak az adott frame-re el, ezert
-- minden frame-ben hivni kell a Wait(0) loopban.
-- Interior modban a legtobb kulso blip eltakarodik.

local function ApplyBlipVisibility()
    if not showBlips then
        SetRadarAsInteriorThisFrame()
    end
end

-- ── GPS poll ────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(1000)
        if not minimapVisible then goto gps_skip end

        local wp     = GetFirstBlipInfoId(8)  -- waypoint blip
        local newGps = DoesBlipExist(wp)

        if newGps ~= gpsActive then
            gpsActive = newGps
            NXN.Minimap.Log(('GPS aktiv: %s'):format(tostring(gpsActive)))
            NUISend('setGPS', { active = gpsActive, label = Config.GPSActiveLabel })
        end

        ::gps_skip::
    end
end)

-- ── Fo HUD loop (Wait(0) – frame-folytonos nativ hivok) ────────────

CreateThread(function()
    while true do
        Wait(0)
        ApplyMinimapStyle()
        HideNativeComponents()
        ApplyBlipVisibility()
    end
end)

-- ── Inicializalas ────────────────────────────────────────────

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

-- Resource indulasakor (hot-restart)
CreateThread(function()
    Wait(500)
    if NetworkIsPlayerActive(PlayerId()) then
        NXN.Minimap.Log('Resource start: jatekos aktiv, init')
        Init()
    end
end)

-- Spawn / respawn
AddEventHandler('playerSpawned', function()
    NXN.Minimap.Log('playerSpawned – minimap init')
    initialized = false
    Wait(500)
    Init()
end)

-- ── Lathatosag ──────────────────────────────────────────────

local function SetMinimapVisible(state)
    minimapVisible = state
    DisplayRadar(state)
    NUISend('setVisible', { visible = state })
    NXN.Minimap.Log(('SetMinimapVisible: %s'):format(tostring(state)))
end

-- ── Exportok ─────────────────────────────────────────────────

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

exports('setAreas', function(state)
    showAreas = state
    NXN.Minimap.Log(('setAreas: %s'):format(tostring(state)))
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
