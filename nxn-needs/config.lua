Config = {}

Config.Debug          = false
Config.ResourceName   = GetCurrentResourceName()

-- Szükségletek alapértelmezett maximuma és minimuma
Config.Needs = {
    hunger  = { default = 100, min = 0, max = 100 },
    thirst  = { default = 100, min = 0, max = 100 },
    stress  = { default = 0,   min = 0, max = 100 },
    fatigue = { default = 0,   min = 0, max = 100 },
}

-- Automatikus csökkentés / növekedés beállításai (szerver oldali tick)
-- rate: egység/perc | enabled: bekapcsolva-e
Config.AutoDecay = {
    enabled = true,
    interval = 60,      -- másodpercenként fut (1 = valós idejű, 60 = percenként)
    rates = {
        hunger  = { change = -1,  min = 0  },   -- percenként -1
        thirst  = { change = -1.5, min = 0 },   -- percenként -1.5
        stress  = { change = 0,   min = 0  },   -- nem csökken automatikusan
        fatigue = { change = 1,   max = 100 },  -- percenként +1
    }
}

-- Adatbázis tábla neve
Config.NeedsTable = 'nxn_needs'

-- Mentési intervallum (másodperc) – milyen sűrűn mentsen DB-be
Config.SaveInterval = 300  -- 5 perc

-- Ha a hunger vagy thirst 0 alá menne, okozzon-e GTA damage-et
Config.DamageOnEmpty = {
    enabled  = true,
    hunger   = true,
    thirst   = true,
    interval = 10,    -- másodpercenként ellenőriz
    amount   = 1,     -- hp csökkentés egységenként
}
