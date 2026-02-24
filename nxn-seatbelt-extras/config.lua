Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- ============================================================
--  Utkozes eszleles altalanos beallitasok
-- ============================================================

-- Sebesseg-mintavetel gyakorisaga (ms) - alacsonyabb = pontosabb, de tobb CPU
Config.SampleInterval = 100   -- ms

-- Minimum sebesseg utkozes eszlelesnelhoz (km/h)
-- Ez alatt nem tortenik semmi, kizarja az apro lassulasokat
Config.MinCollisionSpeed = 15.0

-- ============================================================
--  Kirepules (ejection) - kicsatolt ov + nagy utkozes
-- ============================================================

Config.Ejection = {
    enabled = true,

    -- Minimum utkozes-sebesseg aminel kirepites tortenik (km/h)
    -- A jatekos KICSATOLT ovnel kirepul ennyi km/h feletti utkozesnel
    speedThreshold = 60.0,

    -- Kirepules utan alkalmazott impulzus erossege
    -- (minnel nagyobb, annal messzebb repul)
    forceMultiplier = 1.8,

    -- Ertesites megjelenjen-e
    notify = true,
    notifyMsg = 'Kirepultol a jarmubol az utkozesnel!',
}

-- ============================================================
--  Serulesek (damage) - be/kicsatolt ov kulonbsege
-- ============================================================

Config.Damage = {
    enabled = true,

    -- Kicsatolt ov: ennyi sebesseg felett sebzest kap a jatekos
    unfasteningSpeedThreshold = 40.0,  -- km/h

    -- Bekotott ov: ennyi sebesseg felett kap sebzest (tompitva)
    fasteningSpeedThreshold   = 80.0,  -- km/h

    -- Sebzes szorzok (0.0 = semmi, 1.0 = teljes GTA sebzes)
    unfasteningDamageMultiplier = 1.0,   -- kicsatolt: teljes sebzes
    fasteningDamageMultiplier   = 0.25,  -- bekotott: negyedanyi

    -- Fekete kepernyo effekt (blacking out)
    screenFlash = true,
}

-- ============================================================
--  Alacsony sebessegu utkozesek (fender-bender) - mindenkepp
-- ============================================================

Config.MinorCollision = {
    enabled = true,

    -- Sebesseg tartomany amiben "kis utkozeskent" kezel
    minSpeed = 15.0,  -- km/h
    maxSpeed = 35.0,  -- km/h

    -- Ertesites
    notify = true,
    notifyMsg = 'Kisebb utkozest erzekeltunk.',
}

-- ============================================================
--  Nagy sebessegu utkozesek (high-speed)
-- ============================================================

Config.MajorCollision = {
    enabled = true,

    -- Sebesseg tartomany amiben "nagy utkozeskent" kezel
    minSpeed = 35.0,  -- km/h (kicsatolt felettt szamit)
    maxSpeed = 999.0,

    -- Ertesites
    notify = true,
    unfasteningMsg = 'Sulyos utkozest szenvedtel be! Nem volt bekotve az oved!',
    fasteningMsg   = 'Sulyos utkozest szenvedtel be. Az ov segitett!',
}

-- ============================================================
--  Baleset utani extra effektek
-- ============================================================

Config.PostCrash = {
    -- Hangerot csokkenti utkozeskor ("stunned" erzes)
    muteOnCrash         = true,
    muteDuration        = 3.0,   -- masodperc

    -- Kamera remeges (shake)
    cameraShake         = true,
    cameraShakeDuration = 2.0,   -- masodperc
    cameraShakeIntensity = 0.4,  -- 0.0 - 1.0

    -- Jatekos kienged a kormanyrol (ragdoll)
    ragdoll             = true,
    ragdollDuration     = 1500,  -- ms (kicsatolt ovnel)
    ragdollFasteningMs  = 400,   -- ms (bekotott ovnel, kisebb)
}
