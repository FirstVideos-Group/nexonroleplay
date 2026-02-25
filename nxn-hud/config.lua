Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- HUD pozicioja a kepernyon
-- 'bottom-left' | 'bottom-right' | 'top-left' | 'top-right'
Config.Position = 'bottom-left'

-- Modul beallitasok
Config.Modules = {
    health = {
        enabled       = true,
        alwaysVisible = true,
        order         = 1,
    },
    hunger = {
        enabled       = true,
        alwaysVisible = true,
        order         = 2,
    },
    thirst = {
        enabled       = true,
        alwaysVisible = true,
        order         = 3,
    },
    stamina = {
        enabled       = true,
        alwaysVisible = false,  -- csak ha fogy (< 100)
        hideDelay     = 4000,   -- ms, ennyi utan tunik el ha visszatoltodott
        order         = 4,
    },
    oxygen = {
        enabled       = true,
        alwaysVisible = false,  -- csak vizben
        threshold     = 99,
        hideDelay     = 3000,
        order         = 5,
    },
    stress = {
        enabled       = true,
        alwaysVisible = false,  -- csak ha stress > threshold
        threshold     = 10,
        hideDelay     = 5000,
        order         = 6,
    },
    money = {
        enabled       = false,
        alwaysVisible = true,
        order         = 7,
    },
    job = {
        enabled       = false,
        alwaysVisible = true,
        order         = 8,
    },
    playerid = {
        enabled       = false,
        alwaysVisible = true,
        order         = 9,
    },
    datetime = {
        enabled       = false,
        alwaysVisible = true,
        order         = 10,
    },
}

-- Health, armor, stamina frissitesi intervallum (ms)
Config.PollInterval = 500

-- Oxygen frissitesi intervallum (ms)
Config.OxygenPollInterval = 300
