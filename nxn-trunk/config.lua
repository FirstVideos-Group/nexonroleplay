Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Alap súlylimit ha a járműosztály nincs definiálva
Config.DefaultMaxWeight = 50.0

-- Járműosztály alapú trunk kapacitás (GetVehicleClass() értékek)
Config.TrunkSizes = {
    [0]  = 30.0,   -- Compact
    [1]  = 50.0,   -- Sedan
    [2]  = 60.0,   -- SUV
    [3]  = 40.0,   -- Coupe
    [4]  = 45.0,   -- Muscle
    [5]  = 35.0,   -- Sports Classic
    [6]  = 70.0,   -- Off-road
    [7]  = 90.0,   -- Commercial (van, kis teherautó)
    [8]  = 0.0,    -- Motorcycle – nincs csomagtartó
    [9]  = 70.0,   -- Industrial
    [10] = 45.0,   -- Utility
    [11] = 0.0,    -- Cycles – nincs
    [12] = 0.0,    -- Boats – nincs
    [13] = 20.0,   -- Sports
    [14] = 15.0,   -- Super
    [15] = 0.0,    -- Helicopters
    [16] = 0.0,    -- Planes
    [17] = 0.0,    -- Service
    [18] = 80.0,   -- Emergency
    [19] = 100.0,  -- Military
    [20] = 0.0,    -- Commercial (nagy tehergépk)
    [21] = 0.0,    -- Trains
}

-- Interakciós hatótáv (méter)
Config.InteractDistance = 2.5

-- Csomagtartó nyitás billentyűje (GTA control code 47 = G)
Config.OpenKey = 47

-- Marker a jármű mögött
Config.Marker = {
    enabled = true,
    type    = 1,
    size    = 0.4,
    color   = { r = 91, g = 106, b = 240, a = 80 },
}

-- Motorkerékpár (osztály 8) engedélyezése
Config.AllowMotorcycleTrunk = false

-- NPC járművek használatának tiltása
Config.RequireNetworkVehicle = true
