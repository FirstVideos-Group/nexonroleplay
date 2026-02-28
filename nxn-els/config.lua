-- ============================================================
--  nxn-els | config.lua
--  Minden beállítás itt módosítható.
-- ============================================================

Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- ── Admin jogosultság (Ace) ─────────────────────────────────────
-- A szerver server.cfg-jében add hozzá:
--   add_ace group.admin nxn.els.admin allow
--
-- Ezzel a csöport tagjai a job-tól függetlenül használhatják az ELS-t,
-- és bármely járműn (whitelist bypass is).
Config.AdminAce = 'nxn.els.admin'

-- ── Keybindek ────────────────────────────────────────────────
Config.Keys = {
    cycleStage   = 'Q',
    toggleSiren  = 'R',
    indicatorL   = 'LEFT',
    indicatorR   = 'RIGHT',
    hazard       = 'H',
}

-- ── Jogosultságkezelés ──────────────────────────────────────
Config.AllowedJobs = {
    'police', 'sheriff', 'ems', 'fire', 'ambulance',
}

Config.UseVehicleWhitelist = true

Config.AllowedVehicles = {
    'police','police2','police3','police4','policeb',
    'policeold1','policeold2','sheriff','sheriff2',
    'fbi','fbi2','riot','ambulance','firetruk','lguard','pranger',
}

-- ── Környezeti fényreflexió ─────────────────────────────────
Config.EnvLight = {
    enabled    = true,
    multiplier = 3.5,
    tickMs     = 80,
}

-- ── Villogási pattern rendszer ──────────────────────────────
Config.Patterns = {
    alternating = {
        { extras = {[1]=true,  [2]=false}, miscs = {[0]=true,  [1]=false}, dur = 120 },
        { extras = {[1]=false, [2]=true }, miscs = {[0]=false, [1]=true }, dur = 120 },
    },
    wigwag = {
        { extras = {[1]=true,  [2]=false}, miscs = {[0]=true,  [1]=false}, dur = 80  },
        { extras = {[1]=false, [2]=true }, miscs = {[0]=false, [1]=true }, dur = 80  },
    },
    pileon = {
        { extras = {[1]=true,  [2]=true  }, miscs = {[0]=true,  [1]=true  }, dur = 100 },
        { extras = {[1]=false, [2]=false }, miscs = {[0]=false, [1]=false }, dur = 80  },
    },
    steady = {
        { extras = {[1]=true, [2]=true}, miscs = {[0]=true, [1]=true}, dur = 500 },
    },
}

-- ── Fényfokozatok ─────────────────────────────────────────────
Config.Stages = {
    [0] = { label = 'KI',     sirenActive = false, pattern = nil,           sirenTone = 0 },
    [1] = { label = 'CODE 1', sirenActive = false, pattern = 'steady',      sirenTone = 0 },
    [2] = { label = 'CODE 2', sirenActive = true,  pattern = 'alternating', sirenTone = 1 },
    [3] = { label = 'CODE 3', sirenActive = true,  pattern = 'wigwag',      sirenTone = 2 },
}

-- ── Jármű-specifikus konfig ──────────────────────────────────
Config.VehicleConfigs = {
    police = {
        [1] = { pattern = 'steady',      sirenTone = 0 },
        [2] = { pattern = 'alternating', sirenTone = 1 },
        [3] = { pattern = 'wigwag',      sirenTone = 2 },
    },
    ambulance = {
        [1] = { pattern = 'steady',  sirenTone = 0 },
        [2] = { pattern = 'pileon',  sirenTone = 1 },
        [3] = { pattern = 'wigwag',  sirenTone = 3 },
    },
    firetruk = {
        [1] = { pattern = 'steady',      sirenTone = 0 },
        [2] = { pattern = 'alternating', sirenTone = 1 },
        [3] = { pattern = 'pileon',      sirenTone = 4 },
    },
}

-- ── nxn-vehicle-hud integráció ───────────────────────────────
Config.IntegrateVehicleHud = true

-- ── Szinkronizáció ───────────────────────────────────────────
Config.SyncInterval = 1000
