Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- Motor indito gomb (alapertelmezett: G)
-- GTA control lista: https://docs.fivem.net/docs/game-references/controls/
Config.ToggleKey      = 47   -- G
Config.ToggleKeyLabel = 'G'

-- Motor automatikusan leall jarmube szallaskor
-- false = GTA alapviselkedese (azonnal jar)
Config.StopEngineOnEnter = true

-- Motor automatikusan fut ha a jatekos kiszall (nem all le)
-- true = motor tovabbra is jar kiszallas utan
Config.KeepEngineOnExit = true

-- ============================================================
--  Motor serules beallitasok
--  Az ertek a motor serules % -os novelese az esemenykent.
--  A motor serulese 0.0 (uj) - 1000.0 (teljesen torott) skalan
--  van GTA-ban. A config ertekek a 0-100% skalan vannak (egyszerubb).
-- ============================================================

Config.EngineDamage = {
    enabled = true,

    -- Tulterheles (rpm tul magas, pl. sebesseggel hajtva)
    overheat = {
        enabled         = true,
        rpmThreshold    = 0.95,  -- 0.0-1.0, ennyi RPM felett kezd melengni
        heatRate        = 0.05,  -- HP / masodperc serules ra jo RPM-nel
        cooldownRate    = 0.02,  -- HP / masodperc regeneracio alacsony RPM-nel
        notifyOnCritical = true,
        criticalMsg     = 'A motor tulhevult! Hajtson le!',
    },

    -- Utkozes-szeteses (nxn-seatbelt-extras esemeny alapjan)
    collision = {
        enabled         = true,
        -- deltaV (km/h) -> serules% tabla
        -- [{ min, max, damage }]  damage = a motor HP % amit elveszit
        thresholds = {
            { min = 20,  max = 40,  damage = 3  },
            { min = 40,  max = 70,  damage = 10 },
            { min = 70,  max = 120, damage = 25 },
            { min = 120, max = 999, damage = 55 },
        },
    },

    -- Kis motor HP alatti figyelmeztetes
    damagedThreshold  = 40,   -- % alatt: 'damaged' allapot
    criticalThreshold = 15,   -- % alatt: 'critical' allapot (motor leallhat)

    -- Kritikus allapotban motor leallasanak valoszinusege percenkent
    criticalStallChance = 0.15,  -- 0.0-1.0
}

-- Motor allapot-HUD szinkronizalas
Config.HUDSyncInterval = 5000   -- ms

-- Ertesitesek
Config.Notify = {
    engineStarted   = 'Motor elindult.',
    engineStopped   = 'Motor leallitva.',
    engineLocked    = 'A motor le van zarva. Szukseg van kulcsra!',
    engineDamaged   = 'A motor megsérült!',
    engineCritical  = 'KRITIKUS motorserules! Azonnal allj le!',
    engineStalled   = 'A motor beragadt a sérülés miatt.',
    noKey           = 'Nincs kulcsa ehhez a jarmuhoz!',
}
