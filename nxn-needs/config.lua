Config = {}

Config.Debug          = false
Config.ResourceName   = GetCurrentResourceName()

Config.Needs = {
    hunger  = { default = 100, min = 0, max = 100 },
    thirst  = { default = 100, min = 0, max = 100 },
    stress  = { default = 0,   min = 0, max = 100 },
    fatigue = { default = 0,   min = 0, max = 100 },
}

Config.AutoDecay = {
    enabled  = true,
    interval = 60,
    rates = {
        hunger  = { change = -1   },
        thirst  = { change = -1.5 },
        stress  = { change = 0    },
        fatigue = { change = 1    },
    }
}

Config.NeedsTable   = 'nxn_needs'
Config.SaveInterval = 300

-- #81: DamageOnEmpty dinamikus – bármely need-hez beállítható damage flag
-- A server.lua a Config.Needs kulcsain iterál, és itt is megadott need flag alapján
-- dönti el, hogy az adott need 0-ra érve okoz-e damage-t.
Config.DamageOnEmpty = {
    enabled  = true,
    interval = 10,
    amount   = 1,
    -- Need-enként flag: true = az adott need 0-ra érve damage-t okoz
    hunger  = true,
    thirst  = true,
    stress  = false,  -- stress 100-ra érve nem okoz alapból damage-t
    fatigue = false,  -- fatigue 100-ra érve nem okoz alapból damage-t
}

Config.ItemOverrides = {
    -- Példa felülírásra:
    -- water_bottle = { thirst = 35 },
}
