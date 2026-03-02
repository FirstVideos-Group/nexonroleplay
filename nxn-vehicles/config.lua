Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Járműosztály -> jogosítvány típus térkép (GetVehicleClass() értékek)
-- nil érték = nincs jogosítvány ellenőrzés ennél az osztálynál
Config.LicenseByClass = {
    [0]  = 'license_drivers',    -- Compact
    [1]  = 'license_drivers',    -- Sedan
    [2]  = 'license_drivers',    -- SUV
    [3]  = 'license_drivers',    -- Coupe
    [4]  = 'license_drivers',    -- Muscle
    [5]  = 'license_drivers',    -- Sports Classic
    [6]  = 'license_drivers',    -- Off-road
    [7]  = 'license_drivers',    -- Commercial
    [8]  = 'license_drivers',    -- Motorcycle (külön jogosítvány, ha kell add motorcycle-t)
    [9]  = 'license_drivers',    -- Industrial
    [10] = 'license_drivers',    -- Utility
    [12] = 'license_boat',       -- Boats
    [13] = 'license_drivers',    -- Sports
    [14] = 'license_drivers',    -- Super
    [15] = 'license_pilot',      -- Helicopters
    [16] = 'license_pilot',      -- Planes
    [18] = 'license_drivers',    -- Emergency
    [19] = nil,                  -- Military – nincs ellenőrzés
}

-- Jogosítvány-ellenőrzés be/ki
Config.EnableLicenseCheck = true

-- Motor HP perzisztencia be/ki (nxn-engine integráció)
Config.PersistEngineHP = true

-- Emergency osztály (18) siren modul auto-engedélyezés (nxn-vehicle-hud)
Config.EmergencyClass = 18

-- Közelség-detekció intervallum (ms) a járműbe lépés figyelemhez
Config.VehicleCheckInterval = 200
