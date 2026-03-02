Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Töltőállomás helyek
Config.Stations = {
    ['paleto_bp'] = {
        label   = 'Paleto BP',
        pumps   = {
            { coords = vector3(-93.8, 6419.0, 31.5), heading = 45.0  },
            { coords = vector3(-86.1, 6412.5, 31.5), heading = 225.0 },
        },
        npc = {
            enabled  = true,
            model    = 's_m_m_gasman_01',
            coords   = vector4(-82.0, 6424.0, 31.5, 180.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        },
        blip = {
            enabled = true,
            sprite  = 361,
            color   = 6,
            label   = 'Benzinkút',
            scale   = 0.9,
        },
        pricePerLiter   = 12.0,
        markerEnabled   = true,
        markerType      = 1,
        markerColor     = { r = 0, g = 150, b = 255, a = 120 },
    },
    ['alta_st_gas'] = {
        label  = 'Alta Street Benzinkút',
        pumps  = {
            { coords = vector3(49.4, -1751.6, 29.4), heading = 90.0 },
            { coords = vector3(49.4, -1758.4, 29.4), heading = 90.0 },
        },
        npc   = { enabled = false },
        blip  = { enabled = true, sprite = 361, color = 6, label = 'Benzinkút', scale = 0.9 },
        pricePerLiter = 14.0,
        markerEnabled = true,
        markerType    = 1,
        markerColor   = { r = 0, g = 150, b = 255, a = 120 },
    },
    ['sandy_shores'] = {
        label  = 'Sandy Shores Benzinkút',
        pumps  = {
            { coords = vector3(1693.3, 3762.8, 34.7), heading = 0.0   },
            { coords = vector3(1699.8, 3762.8, 34.7), heading = 180.0 },
        },
        npc   = { enabled = false },
        blip  = { enabled = true, sprite = 361, color = 6, label = 'Benzinkút', scale = 0.9 },
        pricePerLiter = 11.0,
        markerEnabled = true,
        markerType    = 1,
        markerColor   = { r = 0, g = 150, b = 255, a = 120 },
    },
    ['grapeseed'] = {
        label  = 'Grapeseed Benzinkút',
        pumps  = {
            { coords = vector3(1816.0, 4677.1, 42.0), heading = 90.0 },
        },
        npc   = { enabled = false },
        blip  = { enabled = true, sprite = 361, color = 6, label = 'Benzinkút', scale = 0.9 },
        pricePerLiter = 10.0,
        markerEnabled = true,
        markerType    = 1,
        markerColor   = { r = 0, g = 150, b = 255, a = 120 },
    },
    ['la_mesa'] = {
        label  = 'La Mesa Benzinkút',
        pumps  = {
            { coords = vector3(831.9, -1001.9, 27.9), heading = 0.0   },
            { coords = vector3(838.3, -1001.9, 27.9), heading = 180.0 },
        },
        npc   = { enabled = false },
        blip  = { enabled = true, sprite = 361, color = 6, label = 'Benzinkút', scale = 0.9 },
        pricePerLiter = 13.0,
        markerEnabled = true,
        markerType    = 1,
        markerColor   = { r = 0, g = 150, b = 255, a = 120 },
    },
    ['rockford_hills'] = {
        label  = 'Rockford Hills Benzinkút',
        pumps  = {
            { coords = vector3(-714.2, -934.4, 19.2), heading = 270.0 },
            { coords = vector3(-714.2, -942.0, 19.2), heading = 90.0  },
        },
        npc   = { enabled = false },
        blip  = { enabled = true, sprite = 361, color = 6, label = 'Benzinkút', scale = 0.9 },
        pricePerLiter = 16.0,
        markerEnabled = true,
        markerType    = 1,
        markerColor   = { r = 0, g = 150, b = 255, a = 120 },
    },
}

-- Tankálási animáció
Config.RefuelAnim = {
    enabled = true,
    dict    = 'timetable@gardener@filling_can',
    name    = 'filling_can_standing',
}

-- Interakciós távolság a pump-tól
Config.InteractionDistance = 3.0

-- Marker rajzolási távolság
Config.MarkerDrawDistance = 25.0

-- Ár per liter globális fallback
Config.DefaultPricePerLiter = 13.0

-- Minimum vásárolható liter
Config.MinRefuelAmount = 1.0

-- Tankálási sebesség (liter/másodperc)
Config.RefuelRate = 2.0

-- Valósidős tankálás (false = egyszerre fizet + tölt)
Config.RealtimeRefuel = false

-- Szerver oldali távolság ellenőrzés
Config.ServerCheckDistance = 10.0

-- Tranzakció logolása DB-be
Config.LogTransactions = true
