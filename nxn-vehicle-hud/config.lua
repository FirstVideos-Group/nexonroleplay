Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- HUD pozicioja a kepernyon
-- 'bottom-left' | 'bottom-right' | 'top-left' | 'top-right'
Config.Position = 'bottom-right'

-- Sebesseg megjelenitesi egyseg: 'kmh' | 'mph'
Config.SpeedUnit = 'kmh'

-- Fordulat animacio simitas (ms)
Config.PollInterval = 100

-- Modul beallitasok
Config.Modules = {
    speed = {
        enabled       = true,
        alwaysVisible = true,   -- motor jar -> mindig latszik
        order         = 1,
    },
    rpm = {
        enabled       = true,
        alwaysVisible = true,
        order         = 2,
    },
    gear = {
        enabled       = true,
        alwaysVisible = true,
        order         = 3,
    },
    lights = {
        enabled       = true,
        alwaysVisible = false,  -- csak ha lampak be vannak kapcsolva
        order         = 4,
    },
    engine = {
        enabled       = true,
        alwaysVisible = false,  -- csak ha a motor kihalt / tulhevult
        threshold     = 950,    -- engine health, ez alatt figyelmeztet
        order         = 5,
    },
    -- Opcionalis, kulső resource toltiheti (nxn-fuel, nxn-seatbelt stb.)
    fuel = {
        enabled       = false,
        alwaysVisible = true,
        order         = 6,
    },
    seatbelt = {
        enabled       = false,
        alwaysVisible = false,  -- csak ha nincs bekotve
        order         = 7,
    },
    siren = {
        enabled       = false,
        alwaysVisible = false,  -- csak ha szirena be van kapcsolva
        order         = 8,
    },
}
