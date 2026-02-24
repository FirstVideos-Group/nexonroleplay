-- ============================================================
--  nxn-minimap | client.lua
--  Minimap overlay menedzser:
--   - Natív GTA minimap megőrzése, felette NUI keret + adatok
--   - Felesleges HUD elemek elrejtése
--   - GPS aktív jelzés poll
--   - District adat (nxn-districts tölti)
--   - Export API
-- ============================================================

-- ── Állapot ──────────────────────────────────────────────────

local minimapVisible = Config.MinimapEnabled
local showBlips      = Config.ShowBlips
local showAreas      = Config.ShowAreas
local districtData   = nil   -- { number, name, color } | nil
local gpsActive      = false
local nuiReady       = false

-- ── NUI segéd ────────────────────────────────────────────────

---@param action string
---@param data   table|nil
local function NUISend(action, data)
    local payload = data or {}
    payload.action = action
    NXN.Minimap.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

-- ── Natív minimap beállítások ─────────────────────────────────

--- Minimap méret + pozíció megőrzése, csak alak módosítása
local function ApplyMinimapStyle()
    -- Téglalap alak (alapból kör volt régebben, de most mindkettő ok)
    SetRadarBigmapEnabled(false, false)
    -- Biztosítjuk, hogy a minimap látszik
    DisplayRadar(minimapVisible)
    NXN.Minimap.Log(('ApplyMinimapStyle: visible=%s'):format(tostring(minimapVisible)))
end

--- Felesleges HUD elemek elrejtése (folyamatos loop kell mert a GTA visszakapcsolja)
local function HideNativeComponents()
    if not Config.HideNativeHUDComponents then return end

    -- Stamina bar
    HideHudComponentThisFrame(2)   -- radar minimap szöveg
    HideHudComponentThisFrame(20)  -- kerület/utca szöveg (mi jelenítjük meg)
    HideHudComponentThisFrame(21)  -- terület szöveg
    -- Kikommentelve, mert a GPS útvonalat meg kell tartani:
    -- HideHudComponentThisFrame(3)  -- floating help

    -- Sztamina / O2 bar elrejtése ha a GTA megjeleníti
    -- (a GTA HUD komponens sorrend nem tartalmaz explicit stamina indexet
    --  ezért a teljes HUD kikapcsolása nélkül csak SCALEFORM szinten lehet)
end

--- Blip / terület megjelenítés
local function ApplyBlipVisibility()
    -- A GTA-ban nincs teljesen letiltható blip API,
    -- de a radar alpha-val és a SET_RADAR_AS_INTERIOR_THIS_FRAME-el kezelhető
    if showBlips then
        SetMinimapInInterior(false)
    else
        -- Interior módban a legtöbb külső blip eltűnik
        SetMinimapInInterior(true)
    end
    NXN.Minimap.Log(('ApplyBlipVisibility: showBlips=%s'):format(tostring(showBlips)))
end

-- ── GPS státusz poll ──────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(1000)
        if not minimapVisible then goto gps_continue end

        local wp = GetFirstBlipInfoId(8)  -- waypoint blip type
        local wpExists = DoesBlipExist(wp)
        local newGps = wpExists

        if newGps ~= gpsActive then
            gpsActive = newGps
            NXN.Minimap.Log(('GPS aktiv: %s'):format(tostring(gpsActive)))
            NUISend('setGPS', { active = gpsActive, label = Config.GPSActiveLabel })
        end

        ::gps_continue::
    end
end)

-- ── Natív HUD loop ────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        ApplyMinimapStyle()
        HideNativeComponents()
        ApplyBlipVisibility()
    end
end)

-- ── Spawn init ───────────────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.Minimap.Log('playerSpawned – minimap NUI init')
    Wait(500)
    nuiReady = true
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
end)

-- ── Láthatóság ───────────────────────────────────────────────

local function SetMinimapVisible(state)
    minimapVisible = state
    DisplayRadar(state)
    NUISend('setVisible', { visible = state })
    NXN.Minimap.Log(('SetMinimapVisible: %s'):format(tostring(state)))
end

-- ── Exportok ─────────────────────────────────────────────────

--- Minimap elrejtése / megjelenítése
---@param state boolean
exports('setVisible', function(state)
    SetMinimapVisible(state)
end)

--- Minimap aktuális láthatósága
---@return boolean
exports('isVisible', function()
    return minimapVisible
end)

--- Blipek be/ki
---@param state boolean
exports('setBlips', function(state)
    showBlips = state
    NXN.Minimap.Log(('setBlips: %s'):format(tostring(state)))
    NUISend('setBlips', { visible = state })
end)

--- Területek be/ki
---@param state boolean
exports('setAreas', function(state)
    showAreas = state
    NXN.Minimap.Log(('setAreas: %s'):format(tostring(state)))
end)

--- GPS útvonal be/ki (natív raycast)
---@param state boolean
exports('setGPSEnabled', function(state)
    NXN.Minimap.Log(('setGPSEnabled: %s'):format(tostring(state)))
    -- Ha ki van kapcsolva, töröljük a waypointot
    if not state then
        SetWaypointOff()
    end
    NUISend('setGPSEnabled', { enabled = state })
end)

--- Kerület szám és név megadása (nxn-districts hívja)
---@param number number|string  pl. 3 vagy 'III'
---@param name   string         pl. 'Rockford Hills'
---@param color  string|nil     hex pl. '#5b6af0'
exports('setDistrict', function(number, name, color)
    if not Config.ShowDistrict then return end
    districtData = { number = number, name = name, color = color }
    NXN.Minimap.Log(('setDistrict: #%s – %s'):format(tostring(number), tostring(name)))
    NUISend('setDistrict', {
        number  = tostring(number),
        name    = name or '',
        color   = color or '',
        visible = true,
    })
end)

--- Kerület panel elrejtése (pl. ha a játékos ismeretlen területen van)
exports('clearDistrict', function()
    districtData = nil
    NXN.Minimap.Log('clearDistrict')
    NUISend('setDistrict', { visible = false })
end)

--- Pozíció frissítése
---@param pos string  'bottom-left'|'bottom-right'|'top-left'|'top-right'
exports('setPosition', function(pos)
    NXN.Minimap.Log(('setPosition: %s'):format(tostring(pos)))
    NUISend('setPosition', { position = pos })
end)

--- Aktuális district adat lekérése
---@return table|nil
exports('getDistrict', function()
    return districtData
end)
