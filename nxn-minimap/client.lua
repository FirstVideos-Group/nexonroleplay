-- ============================================================
--  nxn-minimap | client.lua
--  FIX: SetMinimapInInterior -> SetRadarAsInteriorThisFrame (frame-folytonos)
--  FIX: HUD komponens indexek javitva
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

-- ── Natív minimap stilus ─────────────────────────────────────

local function ApplyMinimapStyle()
    -- Ne nagyitsuk ki
    SetRadarBigmapEnabled(false, false)
    -- Minimap lathatosaga
    DisplayRadar(minimapVisible)
end

-- ── HUD elemek elrejtese (frame-folytonos) ───────────────────────
-- GTA HUD komponens indexek (HideHudComponentThisFrame):
-- 1  = WANTED_STARS
-- 2  = WEAPON_ICON
-- 3  = CASH
-- 4  = MP_CASH
-- 5  = MP_MESSAGE
-- 6  = VEHICLE_NAME
-- 7  = AREA_NAME          <- korzetunk mi jelenítjük meg
-- 8  = VEHICLE_CLASS
-- 9  = STREET_NAME        <- utcanevunk mi jelenítjük meg
-- 10 = HELP_TEXT
-- 11 = MINIMAP_BLIPS      <- blip reteg
-- 12 = MINIMAP            <- maga a minimap (NEM rejtjük el)
-- 13 = MINIMAP_MASK
-- 14 = FULL_MAP
-- 15 = RADAR              <- radar korlet
-- 16 = SAVING
-- 17 = GAME_STREAM
-- 18 = WEAPON_WHEEL
-- 19 = MULTIPLAYER_INDICATORS
-- 20 = HUD_COMPONENTS      <- altalanos hud elem (stb. stamina)
-- 21 = MISSION_NAME
-- 22 = GPS_ROUTE

local function HideNativeComponents()
    if not Config.HideNativeHUDComponents then return end
    -- Kerulet / utca szoveges overlay elrejtese (mi jelenítjük meg)
    HideHudComponentThisFrame(7)   -- AREA_NAME
    HideHudComponentThisFrame(9)   -- STREET_NAME
end

-- ── Blip / belsoteres mod (frame-folytonos) ─────────────────────
-- FIX: SetMinimapInInterior NEM letezik FiveM-ben.
-- Helyes natív: SetRadarAsInteriorThisFrame() – csak az adott frame-re ervenyes,
-- ezert MINDEN frame-ben hivni kell a Wait(0) loopban.
-- Belsoteres modban a legtobb kulso blip eltakarodik a minimaprol.

local function ApplyBlipVisibility()
    if showBlips then
        -- Normál mod: minden blip latszik
        -- Nem hivjuk SetRadarAsInteriorThisFrame-et -> kulso mod aktiv
        return
    end
    -- Blipek elrejtese: belso-teres mod szimulalasa
    -- Ez a legtobb jatekos/POI blipet eltakarja
    SetRadarAsInteriorThisFrame()
    NXN.Minimap.Log('ApplyBlipVisibility: interior mod aktiv (blipek elrejtve)')
end

-- ── GPS poll ────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(1000)
        if not minimapVisible then goto gps_skip end

        -- Waypoint blip (type 8)
        local wp      = GetFirstBlipInfoId(8)
        local newGps  = DoesBlipExist(wp)

        if newGps ~= gpsActive then
            gpsActive = newGps
            NXN.Minimap.Log(('GPS aktiv: %s'):format(tostring(gpsActive)))
            NUISend('setGPS', { active = gpsActive, label = Config.GPSActiveLabel })
        end

        ::gps_skip::
    end
end)

-- ── Fo HUD loop (Wait(0) – frame-folytonos nativ hivok) ────────────
-- A GTA minden frame-ben visszaallitja a HUD allapotot,
-- ezert ezeket MINDEN frame-ben meg kell hivni.

CreateThread(function()
    while true do
        Wait(0)
        ApplyMinimapStyle()
        HideNativeComponents()
        ApplyBlipVisibility()  -- SetRadarAsInteriorThisFrame csak ha showBlips=false
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

-- Resource indulasakor: ha a jatekos mar aktiv (hot-restart)
CreateThread(function()
    Wait(500)
    if NetworkIsPlayerActive(PlayerId()) then
        NXN.Minimap.Log('Resource start: jatekos aktiv, init')
        Init()
    end
end)

-- Spawn / respawn
AddEventHandler('playerSpawned', function()
    NXN.Minimap.Log('playerSpawned – minimap init / ujrainit')
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
    -- A loop automatikusan alkalmazza a kovetkezo frame-ben
    NUISend('setBlips', { visible = state })
end)

exports('setAreas', function(state)
    showAreas = state
    NXN.Minimap.Log(('setAreas: %s'):format(tostring(state)))
end)

exports('setGPSEnabled', function(state)
    NXN.Minimap.Log(('setGPSEnabled: %s'):format(tostring(state)))
    if not state then
        SetWaypointOff()
    end
    NUISend('setGPSEnabled', { enabled = state })
end)

--- Kerület szám és név megadása (nxn-districts hívja)
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
