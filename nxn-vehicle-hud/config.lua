Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- HUD pozicioja a kepernyon
-- 'bottom-left' | 'bottom-right' | 'top-left' | 'top-right'
Config.Position = 'bottom-right'

-- Sebesseg megjelenitesi egyseg: 'kmh' | 'mph'
Config.SpeedUnit = 'kmh'

-- Poll intervallum (ms) - modul loopok Wait erteke
Config.PollInterval = 100

-- Modul beallitasok
Config.Modules = {
    speed = {
        enabled       = true,
        alwaysVisible = true,
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
        alwaysVisible = false,  -- csak ha motor meghibasodott / leall
        threshold     = 950,    -- engine health, ez alatt figyelmeztet
        order         = 5,
    },
    -- nxn-fuel toltiheti, ha az fut
    fuel = {
        enabled       = false,
        alwaysVisible = true,
        order         = 6,
    },
    -- nxn-seatbelt toltiheti: alapbol engedelyezve, de csak kicsatolva latszik
    seatbelt = {
        enabled       = true,   -- FIX: true, hogy a setSeatbelt export mukodjon
        alwaysVisible = false,  -- csak ha NINCS bekotve
        order         = 7,
    },
    siren = {
        enabled       = false,
        alwaysVisible = false,
        order         = 8,
    },
}
