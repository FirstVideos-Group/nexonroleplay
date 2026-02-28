-- ============================================================
--  nxn-els | config.lua
--  Minden beállítás itt módosítható.
-- ============================================================

Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- ── Fényfokozatok (stage) ────────────────────────────────────
-- 0 = kikapcsolva | 1 = CODE 1 (csendes) | 2 = CODE 2 (fény+sziréna) | 3 = CODE 3 (teljes)
Config.Stages = {
    [0] = { label = 'KI',     sirenActive = false, lightExtras = {},          sirenTone = 0  },
    [1] = { label = 'CODE 1', sirenActive = false, lightExtras = { 1, 2 },    sirenTone = 0  },
    [2] = { label = 'CODE 2', sirenActive = true,  lightExtras = { 1, 2, 3 }, sirenTone = 1  },
    [3] = { label = 'CODE 3', sirenActive = true,  lightExtras = { 1, 2, 3 }, sirenTone = 2  },
}

-- ── Keybindek ────────────────────────────────────────────────
Config.Keys = {
    cycleStage   = 'Q',      -- Fokozat váltás (0→1→2→3→0)
    toggleSiren  = 'R',      -- Sziréna hang be/ki (stage 2/3-on belül)
    indicatorL   = 'LEFT',   -- Bal irányjelző
    indicatorR   = 'RIGHT',  -- Jobb irányjelző
    hazard       = 'H',      -- Vészvillogó
}

-- ── Jogosultságkezelés ───────────────────────────────────────
-- Az alábbi job-listában szereplő joboknak van ELS-hozzáférésük.
-- nxn-police, nxn-ems, nxn-fire stb. ezeket a beállításokat olvassák.
Config.AllowedJobs = {
    'police',
    'sheriff',
    'ems',
    'fire',
    'ambulance',
}

-- Ha true: a szerveren tárolt jármű-modell lista alapján
-- engedélyezi az ELS-t (csak Config.AllowedVehicles-ben lévő modelleken)
Config.UseVehicleWhitelist = true

-- ELS-re jogosult jármű modellek (hash vagy string)
Config.AllowedVehicles = {
    'police',
    'police2',
    'police3',
    'police4',
    'policeb',
    'policeold1',
    'policeold2',
    'sheriff',
    'sheriff2',
    'fbi',
    'fbi2',
    'riot',
    'ambulance',
    'firetruk',
    'lguard',
    'pranger',
}

-- ── Jármű-specifikus konfig ──────────────────────────────────
-- Ha egy modell szerepel itt, az alábbi extra-lista felülírja az alapértelmezettet.
-- lightExtras: milyen extra-kat kapcsol be az adott stage-ben
Config.VehicleConfigs = {
    police = {
        [1] = { lightExtras = { 1 },       sirenTone = 0 },
        [2] = { lightExtras = { 1, 2 },    sirenTone = 1 },
        [3] = { lightExtras = { 1, 2, 3 }, sirenTone = 2 },
    },
    ambulance = {
        [1] = { lightExtras = { 2 },       sirenTone = 0 },
        [2] = { lightExtras = { 2, 3 },    sirenTone = 1 },
        [3] = { lightExtras = { 2, 3, 4 }, sirenTone = 3 },
    },
    firetruk = {
        [1] = { lightExtras = { 1 },       sirenTone = 0 },
        [2] = { lightExtras = { 1, 2 },    sirenTone = 1 },
        [3] = { lightExtras = { 1, 2, 3 }, sirenTone = 4 },
    },
}

-- ── nxn-vehicle-hud integráció ───────────────────────────────
-- Ha true, az nxn-vehicle-hud 'setSiren' exportját meghívja állapotváltozáskor
Config.IntegrateVehicleHud = true

-- ── Szinkronizáció ───────────────────────────────────────────
-- Szerver-oldali szinkron tick (ms) – ennyi időközönként frissíti a klienseket
Config.SyncInterval = 1000
