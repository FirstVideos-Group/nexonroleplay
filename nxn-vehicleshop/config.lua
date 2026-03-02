-- ============================================================
--  nxn-vehicleshop | config.lua
-- ============================================================

Config = {}

Config.ResourceName           = 'nxn-vehicleshop'
Config.Debug                  = false

Config.AllowDuplicatePurchase = false   -- Vásárolhat-e már meglévő modellt
Config.RequireLicense         = true    -- Jogosítvány szükséges-e vásárláshoz
Config.FinancingEnabled       = true    -- Részletfizetés engedélyezve
Config.TestDriveCooldown      = 600     -- Teszt-menet cooldown másodpercben
Config.BlipEnabled            = true    -- Kereskedők megjelennek-e a térképen
Config.GeneratePlate          = true    -- Automatikus rendszámgenerálás

-- Finanszírozás beállítások
Config.Financing = {
    InterestRate  = 0.05,   -- 5% kamat
    MinMonths     = 3,
    MaxMonths     = 60,
    DefaultMonths = 12,
}

-- Kereskedők listája
Config.Dealers = {
    {
        id         = 'premium_deluxe',
        label      = 'Premium Deluxe Motorsport',
        blip       = { sprite = 523, color = 27, scale = 0.8 },
        npc        = {
            model   = 'ig_carmercs',
            coords  = vector4(-46.27, -1098.77, 26.42, 159.0),
            enabled = true
        },
        spawnCoord  = vector4(-33.08, -1096.09, 26.42, 340.0),
        testDrive   = {
            enabled    = true,
            duration   = 180,
            spawnCoord = vector4(-44.53, -1082.62, 26.68, 159.0)
        },
        categories  = { 'sport', 'super', 'sedan', 'suv' },
        defaultGarage = 'main_garage',
        vehicles    = {
            { model = 'adder',      label = 'Truffade Adder',          price = 1000000, category = 'super',  hp = 900,  maxSpeed = 250, weight = 1500 },
            { model = 'zentorno',   label = 'Pegassi Zentorno',        price = 725000,  category = 'super',  hp = 800,  maxSpeed = 230, weight = 1450 },
            { model = 'entityxf',   label = 'Overflod Entity XF',      price = 795000,  category = 'super',  hp = 850,  maxSpeed = 240, weight = 1480 },
            { model = 't20',        label = 'Progen T20',              price = 2200000, category = 'super',  hp = 950,  maxSpeed = 260, weight = 1520 },
            { model = 'sultan',     label = 'Karin Sultan',            price = 12000,   category = 'sport',  hp = 500,  maxSpeed = 190, weight = 1200 },
            { model = 'comet2',     label = 'Pfister Comet',           price = 100000,  category = 'sport',  hp = 600,  maxSpeed = 200, weight = 1250 },
            { model = 'tailgater',  label = 'Obey Tailgater',          price = 60000,   category = 'sedan',  hp = 400,  maxSpeed = 170, weight = 1400 },
            { model = 'gresley',    label = 'Bravado Gresley',         price = 35000,   category = 'suv',    hp = 380,  maxSpeed = 160, weight = 2000 },
        }
    },
    {
        id         = 'simeon_motors',
        label      = 'Simeon Motors',
        blip       = { sprite = 523, color = 4, scale = 0.8 },
        npc        = {
            model   = 'ig_simeon',
            coords  = vector4(-1271.6, -360.9, 36.8, 247.0),
            enabled = true
        },
        spawnCoord  = vector4(-1263.3, -356.2, 36.8, 68.0),
        testDrive   = {
            enabled    = true,
            duration   = 120,
            spawnCoord = vector4(-1255.4, -348.9, 36.8, 68.0)
        },
        categories  = { 'sedan', 'suv', 'van' },
        defaultGarage = 'main_garage',
        vehicles    = {
            { model = 'oracle',     label = 'Ubermacht Oracle',        price = 80000,   category = 'sedan',  hp = 450,  maxSpeed = 175, weight = 1600 },
            { model = 'schafter2',  label = 'Schafter V12',            price = 116000,  category = 'sedan',  hp = 470,  maxSpeed = 180, weight = 1650 },
            { model = 'serrano',    label = 'Canis Serrano',           price = 40000,   category = 'suv',    hp = 400,  maxSpeed = 165, weight = 2100 },
            { model = 'journey',    label = 'Bravado Journey',         price = 28000,   category = 'van',    hp = 320,  maxSpeed = 145, weight = 2600 },
        }
    }
}
