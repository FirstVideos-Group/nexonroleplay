Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- Zona-ellenorzes intervalluma (ms)
Config.CheckInterval = 500

-- Alapertelmezett fade animacio ideje (ms)
Config.FadeInMs  = 600
Config.FadeOutMs = 400

-- ============================================================
--  Tablak definicioi
--  category: 'large'  -> kepernyo teteje, kozep, kozepes meret
--            'info'   -> jobb oldal kozepen, kis meret
--
--  duration: masodperc amig latszik, nil = zenaaban marad amig
--            a jatekos a zonaban van
--
--  file: a signs/ mappaban levo SVG fajl neve
-- ============================================================

Config.Zones = {

    -- ---------------------------------------------------------
    --  Belvaros udvozlo tabla
    -- ---------------------------------------------------------
    downtown_welcome = {
        label    = 'Belvaros',
        category = 'large',
        file     = 'downtown_welcome.svg',
        center   = vector3(-264.0, -955.0, 31.0),
        radius   = 180.0,
        duration = 5,     -- 5 masodpercig latszik, nem folyamatos
        fadeIn   = 600,
        fadeOut  = 400,
    },

    -- ---------------------------------------------------------
    --  Belvaros sebesseg tablak (folyamatos, amig bent van)
    -- ---------------------------------------------------------
    downtown_speed = {
        label    = 'Belvaros - 40 km/h',
        category = 'info',
        file     = 'speed_40.svg',
        center   = vector3(-264.0, -955.0, 31.0),
        radius   = 180.0,
        duration = nil,   -- folyamatos
        fadeIn   = 400,
        fadeOut  = 300,
    },

    -- ---------------------------------------------------------
    --  Vontatasi zona
    -- ---------------------------------------------------------
    towing_zone = {
        label    = 'Towing Zone',
        category = 'info',
        file     = 'towing_zone.svg',
        center   = vector3(400.0, -1650.0, 29.0),
        radius   = 120.0,
        duration = nil,
        fadeIn   = 400,
        fadeOut  = 300,
    },

    -- ---------------------------------------------------------
    --  Repuloter udvozlo
    -- ---------------------------------------------------------
    airport_welcome = {
        label    = 'Los Santos Nem. Repuloter',
        category = 'large',
        file     = 'airport_welcome.svg',
        center   = vector3(-1336.0, -3044.0, 14.0),
        radius   = 300.0,
        duration = 6,
        fadeIn   = 800,
        fadeOut  = 500,
    },

    -- ---------------------------------------------------------
    --  Autopalya tabla
    -- ---------------------------------------------------------
    highway_info = {
        label    = 'Autopalya - 130 km/h',
        category = 'info',
        file     = 'speed_130.svg',
        center   = vector3(1216.0, -800.0, 58.0),
        radius   = 250.0,
        duration = nil,
        fadeIn   = 400,
        fadeOut  = 300,
    },
}
