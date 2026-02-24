Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- Pozicio mentes intervalluma (masodperc)
Config.PositionSaveInterval = 120

-- Spawn pont ha nincs mentett pozicio (Los Santos Customs kozeleben)
Config.DefaultSpawn = {
    x = -239.74, y = -983.9, z = 30.0, heading = 0.0
}

-- Karakter letrehozas kamera pozicio (jelenet kamera)
Config.CreationCamera = {
    pos     = vector3(-1286.0, -1072.5, 5.5),
    lookAt  = vector3(-1285.0, -1071.8, 5.0),
}

-- NEM lehetseges ertekek
Config.Genders = { 'Ferfi', 'No' }

-- Szuletes ev min-max
Config.BirthYearMin = 1960
Config.BirthYearMax = 2003

-- Szem szinek (nev -> GTA index)
Config.EyeColors = {
    { label = 'Barna',        value = 0  },
    { label = 'Sotet barna',  value = 1  },
    { label = 'Kek',          value = 7  },
    { label = 'Sotet kek',    value = 8  },
    { label = 'Szurke',       value = 10 },
    { label = 'Zold',         value = 12 },
    { label = 'Vilagos zold', value = 13 },
    { label = 'Hazelnut',     value = 5  },
}

-- Bor szinek
Config.SkinColors = {
    { label = 'Nagyon vilagos', value = 0  },
    { label = 'Vilagos',        value = 3  },
    { label = 'Kozepes',        value = 7  },
    { label = 'Sotet',          value = 14 },
    { label = 'Nagyon sotet',   value = 20 },
}

-- Haj stilusok (ferfi)
Config.HairStylesMale = {
    { label = 'Rovid',          value = 0  },
    { label = 'Oldalt nyirt',   value = 1  },
    { label = 'Homlokig fesult',value = 2  },
    { label = 'Hosszu',         value = 5  },
    { label = 'Tarolt',         value = 3  },
    { label = 'Hullamok',       value = 6  },
    { label = 'Afro',           value = 18 },
    { label = 'Kopasz',         value = 99 },
}

-- Haj stilusok (no)
Config.HairStylesFemale = {
    { label = 'Rovid bob',      value = 0  },
    { label = 'Lofarok',        value = 3  },
    { label = 'Hullamok',       value = 5  },
    { label = 'Hosszu egyenes', value = 7  },
    { label = 'Fonat',          value = 10 },
    { label = 'Felkonty',       value = 14 },
    { label = 'Afro',           value = 20 },
}

-- Haj szinek
Config.HairColors = {
    { label = 'Fekete',      value = 0  },
    { label = 'Sotet barna', value = 1  },
    { label = 'Barna',       value = 4  },
    { label = 'Sotet szoke', value = 5  },
    { label = 'Szoke',       value = 6  },
    { label = 'Vilagos sz.', value = 29 },
    { label = 'Voros',       value = 35 },
    { label = 'Osz',         value = 63 },
    { label = 'Feher',       value = 64 },
}

-- Ferfi kezdo ruha komponensek (GTA ped komponens)
-- { componentId, drawable, texture }
Config.DefaultOutfitMale = {
    { 1,  0,  0 },  -- maszk
    { 3,  15, 0 },  -- cipo
    { 4,  21, 0 },  -- nadrago
    { 6,  20, 0 },  -- kezek/csuklok
    { 7,  0,  0 },  -- zokni
    { 8,  15, 0 },  -- felsork
    { 11, 15, 0 },  -- kabat
}

-- No kezdo ruha komponensek
Config.DefaultOutfitFemale = {
    { 1,  0,  0 },
    { 3,  15, 0 },
    { 4,  14, 0 },
    { 6,  18, 0 },
    { 7,  0,  0 },
    { 8,  14, 0 },
    { 11, 14, 0 },
}
