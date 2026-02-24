Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- HUD pozicioja a kepernyon
-- 'bottom-left' | 'bottom-right' | 'top-left' | 'top-right'
Config.Position = 'bottom-left'

-- Lokacio frissitesi intervallum (ms)
Config.PollInterval = 2000

-- Jatekos statusz frissitesi intervallum (ms)
Config.StatusPollInterval = 800

-- Minimap megjelenitese (a GTA minimap fole egy nxn panel)
-- Ha false: csak a szoveges info jelenik meg minimap nelkul
Config.ShowMinimap = true

-- Modul beallitasok
Config.Modules = {
    -- Allandoan lathato modulok
    district = {
        enabled       = true,
        alwaysVisible = true,
        order         = 1,
    },
    street = {
        enabled       = true,
        alwaysVisible = true,
        order         = 2,
    },
    minimap = {
        enabled       = true,
        alwaysVisible = true,
        order         = 3,
    },
    -- Csak esemenynel lathato
    zone = {
        enabled       = true,
        alwaysVisible = false,   -- nxn-gang tolti, csak ha zona-adat erkezik
        order         = 4,
    },
    danger = {
        enabled       = true,
        alwaysVisible = false,   -- nxn-dispatch tolti, csak ha veszely van
        threshold     = 1,       -- minimum danger level (1-5) a megjeleneshez
        hideDelay     = 8000,    -- ms, ennyi utan tunik el
        order         = 5,
    },
    -- Opcionalis modulok
    wanted = {
        enabled       = false,
        alwaysVisible = false,   -- nxn-wantedstatus tolti
        order         = 6,
    },
    playerstatus = {
        enabled       = false,
        alwaysVisible = true,
        order         = 7,
    },
}
