Config = {}

Config.Debug          = false
Config.ResourceName   = GetCurrentResourceName()

-- Szükségletek alapértelmezett értéke, minimuma és maximuma
Config.Needs = {
    hunger  = { default = 100, min = 0, max = 100 },
    thirst  = { default = 100, min = 0, max = 100 },
    stress  = { default = 0,   min = 0, max = 100 },
    fatigue = { default = 0,   min = 0, max = 100 },
}

-- Automatikus csökkentés / növekedés beállításai (szerver oldali tick)
-- change: egység/tick  (negatív = csökkentés, pozitív = növekedés)
-- interval: hány másodpercenként fusson a tick
Config.AutoDecay = {
    enabled  = true,
    interval = 60,  -- másodpercenként fut (60 = percenként)
    rates = {
        hunger  = { change = -1   },  -- percenként -1
        thirst  = { change = -1.5 },  -- percenként -1.5
        stress  = { change = 0    },  -- nem változik automatikusan
        fatigue = { change = 1    },  -- percenként +1
    }
}

-- Adatbázis tábla neve
Config.NeedsTable = 'nxn_needs'

-- Mentési intervallum (másodperc) – milyen sűrűn mentsen DB-be
Config.SaveInterval = 300  -- 5 perc

-- Ha a hunger vagy thirst 0-ra csökkenne, okozzon-e GTA damage-et
Config.DamageOnEmpty = {
    enabled  = true,
    hunger   = true,
    thirst   = true,
    interval = 10,   -- másodpercenként ellenőriz
    amount   = 1,    -- HP csökkentés mértéke
}

-- ── Item → Needs hatástáblázat ────────────────────────────────
-- Az nxn-inventory Config.Items[item].needs mezőjéből töltődik fel
-- automatikusan (lásd shared.lua), de itt felülírható/bővíthető.
-- Formátum: { hunger = N, thirst = N, stress = N, fatigue = N }
-- Pozitív érték = növelés, negatív = csökkentés.
--
-- Alapértelmezés: az nxn-inventory config-ból érkezik:
--   water_bottle  -> thirst  +30
--   sandwich      -> hunger  +25
--   energy_drink  -> thirst  +20, fatigue -15
--   burger        -> hunger  +40
--   painkiller    -> stress  -20
--
-- Ha egy itemet itt is megadsz, ez felülírja az inventory config értékét.
Config.ItemOverrides = {
    -- Példa felülírásra:
    -- water_bottle = { thirst = 35 },
}
