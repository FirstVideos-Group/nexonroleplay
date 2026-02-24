Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- Automatikus ovbekotes kesleltetes jarmube szallas utan (masodperc)
-- 0 = azonnal, pl. 1.5 = 1.5 masodperc utan kotodik be
Config.AutoFastenDelay = 1.5

-- Hang a bekoteskor
Config.Sound = {
    enabled  = true,
    file     = 'seatbelt_auto.ogg',   -- sounds/ mappaban
    volume   = 0.6,                   -- 0.0 - 1.0
}

-- Notify uzenet bekoteskor (nil = nincs uzenet)
Config.NotifyMessage = 'Az automatikus biztonsagi ov bekotodott.'
Config.NotifyType    = 'success'   -- 'info'|'success'|'warning'|'danger'

-- ============================================================
--  Jarmutipusok - osztaly alapu beallitasok
-- Ezek a GTA jarmue-osztalyok szamait hasznaljak:
--   0  = Compact         8  = Motorcycle      16 = Service
--   1  = Sedan           9  = Off-road        17 = Emergency
--   2  = SUV             10 = Industrial      18 = Military
--   3  = Coupe           11 = Utility         19 = Commercial
--   4  = Muscle          12 = Van             20 = Trains
--   5  = Sports Classic  13 = Cycles
--   6  = Sport           14 = Boats
--   7  = Super           15 = Helicopters
-- ============================================================

-- Jarmu OSZTALYOK amelyekben auto bekapcsol (-1 = minden osztaly)
Config.AutoClasses = {
    0,   -- Compact
    1,   -- Sedan
    2,   -- SUV
    3,   -- Coupe
    4,   -- Muscle
    5,   -- Sports Classic
    6,   -- Sport
    7,   -- Super
    12,  -- Van
    16,  -- Service
    17,  -- Emergency
    19,  -- Commercial
}

-- Specifikus jarmu modellek amelyekben MINDIG auto bekotodik
-- (felulirja az osztaly-listakat)
Config.AutoModels = {
    -- 'adder',
    -- 'zentorno',
    -- 'police',
    -- 'ambulance',
}

-- Specifikus jarmu modellek amelyekben SOHA nem kotoodik be automatikusan
-- (felulirja az osztaly-listakat es az AutoModels-t is)
Config.ExcludedModels = {
    -- Motorok - nincs ov
    'faggio',
    'faggio2',
    'faggio3',
    'akuma',
    'bati',
    'bati2',
    'carbonrs',
    'daemon',
    'daemon2',
    -- Csonakok, repulok
    'dinghy',
    'dinghy2',
}

-- Jarmu OSZTÁLYOK amelyekben SOHA nem kotodik be az ov (felulirja az AutoClasses-t)
Config.ExcludedClasses = {
    8,   -- Motorcycle
    13,  -- Cycles
    14,  -- Boats
    15,  -- Helicopters
    18,  -- Military (felold ha kell)
    20,  -- Trains
}
