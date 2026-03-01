Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- ATM helyszínek
Config.ATMs = {
    { label = 'Fleeca ATM – Grove Street',   coords = vector3(146.0,  -1040.0, 29.3), heading = 0.0   },
    { label = 'Fleeca ATM – Vinewood',       coords = vector3(313.3,   -279.6, 54.2), heading = 180.0 },
    { label = 'Fleeca ATM – Little Seoul',   coords = vector3(-1393.8, -582.8, 30.1), heading = 0.0   },
    { label = 'Fleeca ATM – Sandy Shores',   coords = vector3(1688.3,  3782.1, 34.7), heading = 180.0 },
}

-- Bankfiókok (teljes panel: napló + átutalás)
Config.Banks = {
    { label = 'Fleeca Bank – Del Perro',   coords = vector3(-349.3,  -49.8,  49.0), heading = 70.0  },
    { label = 'Fleeca Bank – Rockford',    coords = vector3(149.5,  -1042.3, 29.4), heading = 340.0 },
    { label = 'Pacific Standard Bank',     coords = vector3(233.2,  220.2,  106.3), heading = 210.0 },
}

-- Interakció hatótávolság (méter)
Config.InteractDistance = 2.0

-- Közelség jelző marker
Config.Marker = {
    enabled = true,
    type    = 1,
    size    = 0.5,
    color   = { r = 52, g = 152, b = 219, a = 100 },
}

-- Tranzakciónapló: max sor per lap
Config.TransactionLogPageSize = 20

-- Átutalás minimum összeg
Config.MinTransferAmount = 1

-- Ismétlős tranzakciók elleni cooldown (ms)
Config.TransactionCooldown = 2000
