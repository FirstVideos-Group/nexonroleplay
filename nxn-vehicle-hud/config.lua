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
        alwaysVisible = false,
        order         = 4,
    },
    engine = {
        enabled       = true,
        alwaysVisible = false,
        threshold     = 950,
        order         = 5,
    },
    fuel = {
        enabled       = false,
        alwaysVisible = true,
        order         = 6,
    },
    seatbelt = {
        enabled       = true,
        alwaysVisible = false,
        order         = 7,
    },
    -- FIX: enabled = true, hogy a setSiren export ne terjen vissza azonnal
    -- Az nxn-els hivja exports['nxn-vehicle-hud']:setSiren(active, label)
    -- Ha enabled=false, a moduleStates['siren'] false -> azonnali return
    siren = {
        enabled       = true,
        alwaysVisible = false,  -- csak aktiv szirena eseten jelenik meg
        order         = 8,
    },
}
