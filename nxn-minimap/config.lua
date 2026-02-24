Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- Minimap megjelenitese alapesetben
Config.MinimapEnabled = true

-- Minimap meretek es pozicio
-- A GTA alap minimapja: bal also sarok, kb. 200x200px
-- Ezeket nem modositjuk, csak az overlay keretezest
Config.Width  = 200  -- px
Config.Height = 200  -- px

-- Minimap helye (bottom-left fix az alap GTA minimaphoz illeszkedve)
-- Csak az overlay NUI pozicioja; a natív minimap poziciojat a GTA kezeli
Config.Position = 'bottom-left'

-- Blip-ek es terulet megjelenites a terkepen
-- Ha false: a legtobb blip eltakarodik (pl. PlayerBlipSpriteId)
Config.ShowBlips = true
Config.ShowAreas = true

-- GPS utvonal megjelenites (nativan tamogatott, de ki lehet kapcsolni)
Config.ShowGPS = true

-- GPS aktiv jelzese (szoveges label)
Config.GPSActiveLabel = 'GPS AKTIV'

-- Keruleti szam megjelenites (nxn-districts adja majd)
-- Ha nincs adat, a panel nem jelenik meg
Config.ShowDistrict = true

-- Stamina / lehezes / egyeb GTA HUD elemek elrejtese
-- (ezeket mas resourceok mar megjelenitenek)
Config.HideNativeHUDComponents = true

-- HUD komponensek listaja amit el kell rejteni (GTA HUD component indexek)
-- 1=GTA3 radar, 2=help, 3=floating help, 4=cash, 5=mp cash, 6=mp message,
-- 7=vehicle name, 8=area name, 9=vehicle class, 10=street name,
-- 11=minimap, 12=player switching, 13=weapon switching, 14=mp team,
-- 15=blips, 16=overhead names, 17=weapon wheel, 18=missions,
-- 19=flash minimap, 20=saving game, 21=game timer
Config.HiddenHUDComponents = {
    -- stamina es uszas bar (ezeket mas script jeleníti meg)
    -- oxygen bar
    -- stressbar
    -- A szamok a DISPLAY_HUD_COMPONENT_THIS_FRAME parameternek felelnek meg
    -- Megjegyzes: a minimap maga (11-es) NEM rejuk el, csak ujradizajnoljuk
}
