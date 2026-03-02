Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Feladat kategóriák és jutalmazás
-- reward = baseReward + (távolság_km * distanceMultiplier)
Config.TaskCategories = {
    ['small'] = {
        label              = 'Kis csomag',
        icon               = 'hgi-package-01',
        baseReward         = 200,
        distanceMultiplier = 15,   -- Ft/km
        timeLimit          = 600,  -- másodperc (10 perc)
        fatiguePerTask     = 5,
    },
    ['medium'] = {
        label              = 'Közepes csomag',
        icon               = 'hgi-package-02',
        baseReward         = 400,
        distanceMultiplier = 25,
        timeLimit          = 900,
        fatiguePerTask     = 8,
    },
    ['large'] = {
        label              = 'Nagy rakomány',
        icon               = 'hgi-truck-01',
        baseReward         = 700,
        distanceMultiplier = 40,
        timeLimit          = 1200,
        fatiguePerTask     = 12,
    },
}

-- Felvételi pontok (diszpécser NPC helyek)
Config.DispatchLocations = {
    ['downtown'] = {
        label  = 'Downtown Logisztika',
        coords = vector4(103.7, -1089.1, 29.2, 180.0),
        npc = {
            id       = 'delivery_dispatch_downtown',
            model    = 's_m_m_fiboffice_01',
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled=true, sprite=478, color=5, label='Szállítás – Diszpécser', scale=0.9 },
        },
    },
    ['airport'] = {
        label  = 'Repülőtéri Logisztika',
        coords = vector4(-1043.9, -2733.9, 20.2, 330.0),
        npc = {
            id       = 'delivery_dispatch_airport',
            model    = 's_m_m_fiboffice_01',
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled=true, sprite=478, color=5, label='Szállítás – Repülőtér', scale=0.9 },
        },
    },
    ['sandy'] = {
        label  = 'Sandy Shores Logisztika',
        coords = vector4(1940.0, 3748.0, 32.5, 270.0),
        npc = {
            id       = 'delivery_dispatch_sandy',
            model    = 's_m_m_fiboffice_01',
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled=true, sprite=478, color=5, label='Szállítás – Sandy', scale=0.9 },
        },
    },
}

-- Lehetséges leadási célpontok (véletlenszerűen választódnak)
Config.DeliveryTargets = {
    { label='Alta Street Raktár',      coords=vector3(48.0,   -1750.0,  29.4) },
    { label='La Mesa Depó',            coords=vector3(986.0,  -1750.0,  30.4) },
    { label='El Burro Depó',           coords=vector3(686.0,  -2430.0,  23.0) },
    { label='Paleto Logisztika',       coords=vector3(-206.0,  6269.0,  31.5) },
    { label='Sandy Raktár',            coords=vector3(1705.0,  3749.0,  34.3) },
    { label='Strawberry Depó',         coords=vector3(-714.0,  -934.0,  19.2) },
    { label='Cypress Flats Raktár',    coords=vector3(577.0,  -1940.0,  26.0) },
    { label='LSIA Cargo',              coords=vector3(-1073.0,-2926.0,  13.9) },
    { label='Maze Bank Arena Depó',    coords=vector3(-377.0,  -1612.0, 33.0) },
    { label='Chumash Logisztika',      coords=vector3(-3186.0,  1075.0, 20.8) },
    { label='Grapeseed Raktár',        coords=vector3(1690.0,  4827.0,  42.1) },
    { label='Harmony Depó',            coords=vector3(595.0,   2700.0,  42.7) },
    { label='Vinewood Hills Raktár',   coords=vector3(2110.0,  4930.0,  41.1) },
    { label='Davis Raktár',            coords=vector3(79.0,   -1942.0,  20.8) },
    { label='Terminal Logisztika',     coords=vector3(-268.0, -2814.0,   6.0) },
}

-- Munkajármű kiosztás (opcionális)
Config.VehicleEnabled    = true
Config.VehicleModel      = 'mule'
Config.VehicleSpawnOffset = vector3(3.0, 0.0, 0.0)

-- Feladat per műszak limit (0 = korlátlan)
Config.MaxTasksPerShift = 0

-- Bónusz szorzó időben teljesítésért (az időlimit 50%-án belül)
Config.TimeBonusMultiplier = 1.25

-- Fáradtság integráció
Config.FatigueEnabled  = true

-- Stressznövelés ha lejár az idő
Config.StressOnTimeout = 15

-- Admin ACE jog
Config.AdminAce = 'nxn.delivery.admin'

-- Interakciós távolságok
Config.PickupDistance  = 5.0
Config.DropoffDistance = 5.0

-- Marker típus és méret
Config.PickupMarkerType  = 1
Config.DropoffMarkerType = 1
Config.MarkerSize        = vector3(1.5, 1.5, 1.0)
Config.PickupColor       = { r=0,   g=180, b=255, a=180 }
Config.DropoffColor      = { r=255, g=140, b=0,   a=180 }
