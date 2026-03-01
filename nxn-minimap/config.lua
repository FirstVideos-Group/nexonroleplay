Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

Config.MinimapEnabled = true

Config.Width    = 200
Config.Height   = 200
Config.Position = 'bottom-left'

Config.ShowBlips = true
Config.ShowAreas = true
Config.ShowGPS   = true

Config.GPSActiveLabel = 'GPS AKTIV'

Config.ShowDistrict = true

Config.HideNativeHUDComponents = true

-- #75: Valós FiveM HUD komponens indexek (HideHudComponentThisFrame):
--   1  = WANTED_STARS
--   2  = AMMO_DISPLAY
--   3  = HEALTH_ARMOUR (player health bar)
--   4  = RETICLE
--   5  = VEHICLE_NAME (jármű neve)
--   6  = AREA_NAME    (körzet neve, pl. LITTLE SEOUL)
--   7  = VEHICLE_CLASS
--   8  = STREET_NAME  (utca neve, pl. San Andreas Ave)
--   9  = HELP_TEXT
--  11  = CASH
--  12  = MP_CASH
--  13  = MP_MESSAGE
--  14  = VEHICLE_ENTRY
--  17  = MINIMAP / RADAR  ← NEM rejtjük el, csak újradizájnoljuk
--  19  = STREET_NAME_PERMANENT
-- Megjegyzés: az area name (6) és street name (8) elrejtése a client.lua-ban
-- alapértelmezetten történik (HideNativeHUDComponents = true).
-- Ide TOBBÉBBI extra komponenst írj, amit el szeretnél rejteni:
Config.HiddenHUDComponents = {
    -- Példák (szerkeszd igény szerint):
    -- 3,   -- health bar (ha saját HUD van)
    -- 5,   -- jármű neve
    -- 9,   -- help text
}
