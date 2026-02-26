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
--  Az ertek a motor serules %-os novelese esemenyenkent.
--  A motor serulese 0.0 (uj) - 1000.0 (teljesen torott) skalan
--  van GTA-ban. A config ertekek a 0-100% skalan vannak.
-- ============================================================

Config.EngineDamage = {
    enabled = true,

    -- Tulterheles (rpm tul magas)
    overheat = {
        enabled          = true,
        rpmThreshold     = 0.95,
        heatRate         = 0.05,
        cooldownRate     = 0.02,
        notifyOnCritical = true,
        criticalMsg      = 'A motor tulhevult! Hajtson le!',
    },

    -- Utkozes-szeteses (nxn-seatbelt-extras esemeny alapjan)
    collision = {
        enabled    = true,
        thresholds = {
            { min = 20,  max = 40,  damage = 3  },
            { min = 40,  max = 70,  damage = 10 },
            { min = 70,  max = 120, damage = 25 },
            { min = 120, max = 999, damage = 55 },
        },
    },

    -- Kis motor HP alatti figyelmeztetes
    damagedThreshold  = 40,
    criticalThreshold = 15,

    -- Kritikus allapotban motor leallasanak valoszinusege percenkent
    criticalStallChance = 0.15,
}

-- ============================================================
--  Serules-romlás (Degradation) rendszer
--  Minél sérültebb az auto, annal rosszabbul mukodik:
--   - csokkent teljesitmeny (acceleration / topspeed mod)
--   - motor ritmikusan leallhat (stutter)
--   - vizualis effektek (füst, szikra)
-- ============================================================

Config.Degradation = {
    enabled = true,

    -- ─── Teljesitmeny csökkentes ───────────────────────────
    -- Minél sérültebb a motor, annál kevesebbet gyorsit.
    -- Az ertek 0.0 (teljes teljesitmeny) - 1.0 (nincs gyorsulas).
    -- A vegso mod = lerp(0, maxPenalty, 1 - hp/100)
    performance = {
        enabled    = true,
        maxPenalty = 0.60,   -- max 60% teljesitmeny-vesztes 0% HP-nel
    },

    -- ─── Motor 'stutter' (leallogatás) ────────────────────
    -- Bizonyos HP szint alatt a motor ritmikusan kihagy/leall
    -- majd ujraindul (valoszinuseggel vezérelve).
    stutter = {
        enabled        = true,
        threshold      = 50,    -- % alatt kezd el stutter-elni
        -- HP-tól fuggő eselyek: minél alacsonyabb HP, annál sűrűbb
        -- checkInterval: mikor ellenőrizze (másodperc)
        checkInterval  = 4.0,
        -- chance = (1 - hp/threshold) * maxChance
        maxChance      = 0.55,  -- 0-1, 0% HP-nel ennyi esely van leallasra
        stallDuration  = { min = 1.5, max = 4.0 },  -- masodpercig all le
        restartChance  = 0.85,  -- ujraindulas valoszinusege stall utan
        notifyOnStall  = true,
        msg            = 'A motor kikészül – szervizbe kellene vinni!',
    },

    -- ─── Vizualis effektek ─────────────────────────────────
    effects = {
        enabled        = true,
        -- Füst HP kuszob: ennyi % alatt indul el a füst
        smokeThreshold = 60,
        -- Szikra (heavy damage)
        sparkThreshold = 25,
    },
}

-- Motor allapot-HUD szinkronizalas
Config.HUDSyncInterval = 5000

-- Ertesitesek
Config.Notify = {
    engineStarted   = 'Motor elindult.',
    engineStopped   = 'Motor leallitva.',
    engineLocked    = 'A motor le van zarva. Szukseg van kulcsra!',
    engineDamaged   = 'A motor megsérült!',
    engineCritical  = 'KRITIKUS motorserules! Azonnal allj le!',
    engineStalled   = 'A motor beragadt a sérülés miatt.',
    noKey           = 'Nincs kulcsa ehhez a jarmuhoz!',
    engineDegraded  = 'A motor kikészül – szervizbe kellene vinni!',
}
