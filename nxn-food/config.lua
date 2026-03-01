Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- Ha true, az animáció lejátszása alatt a játékos nem tud mozogni
Config.AnimationBlocking = false

-- ── Étel és ital definíciók ──────────────────────────────────
Config.Items = {
    ['hamburger'] = {
        label     = 'Hamburger',
        icon      = 'hgi-hamburger',
        hunger    = 35,
        thirst    = -5,
        stress    = -5,
        fatigue   = 0,
        animation = 'eating',
        duration  = 3000,
        sound     = 'eat',
    },
    ['hotdog'] = {
        label     = 'Hot Dog',
        icon      = 'hgi-hot-dog',
        hunger    = 25,
        thirst    = -3,
        stress    = -3,
        fatigue   = 0,
        animation = 'eating',
        duration  = 2500,
        sound     = 'eat',
    },
    ['sandwich'] = {
        label     = 'Szendvics',
        icon      = 'hgi-bread-01',
        hunger    = 20,
        thirst    = -2,
        stress    = -2,
        fatigue   = 0,
        animation = 'eating',
        duration  = 2000,
        sound     = 'eat',
    },
    ['pizza'] = {
        label     = 'Pizza',
        icon      = 'hgi-pizza-01',
        hunger    = 45,
        thirst    = -8,
        stress    = -8,
        fatigue   = 0,
        animation = 'eating',
        duration  = 4000,
        sound     = 'eat',
    },
    ['water_bottle'] = {
        label     = 'Vízesüveg',
        icon      = 'hgi-water-polo',
        hunger    = 0,
        thirst    = 40,
        stress    = -3,
        fatigue   = 0,
        animation = 'drinking',
        duration  = 2000,
        sound     = 'drink',
    },
    ['cola'] = {
        label     = 'Cola',
        icon      = 'hgi-soda-can',
        hunger    = 5,
        thirst    = 25,
        stress    = -5,
        fatigue   = -10,
        animation = 'drinking',
        duration  = 2000,
        sound     = 'drink',
    },
    ['coffee'] = {
        label     = 'Kávé',
        icon      = 'hgi-coffee-01',
        hunger    = 5,
        thirst    = 15,
        stress    = -10,
        fatigue   = -20,
        animation = 'drinking',
        duration  = 2500,
        sound     = 'drink',
    },
    ['energy_drink'] = {
        label     = 'Energiaital',
        icon      = 'hgi-energy-ellipse',
        hunger    = 0,
        thirst    = 20,
        stress    = -5,
        fatigue   = -30,
        animation = 'drinking',
        duration  = 2000,
        sound     = 'drink',
    },
}

-- ── NPC éttermek / boltok ─────────────────────────────────────
-- Megjegyzés: ha az nxn-shop is telepítve van, a vásárlás logika
-- átadható az nxn-shop:registerShop exporton keresztül.
-- Az nxn-food ekkor csak a fogyasztás animációját és nxn-needs
-- hívásokat kezeli.
Config.Shops = {
    ['burger_shot'] = {
        label   = 'Burger Shot',
        npc     = {
            model    = 'a_m_y_foodlmon_01',
            coords   = vector4(314.9, -208.8, 54.2, 200.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 105, color = 1, label = 'Burger Shot', scale = 0.8 },
        },
        items   = {
            { item = 'hamburger',  price = 800  },
            { item = 'hotdog',     price = 500  },
            { item = 'cola',       price = 300  },
            { item = 'water_bottle', price = 150 },
        },
    },
    ['upnatom'] = {
        label   = 'Up-n-Atom',
        npc     = {
            model    = 's_f_y_sweat_01',
            coords   = vector4(-326.84, -1501.3, 27.0, 118.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 105, color = 1, label = 'Up-n-Atom', scale = 0.8 },
        },
        items   = {
            { item = 'hamburger',  price = 750  },
            { item = 'hotdog',     price = 450  },
            { item = 'cola',       price = 250  },
        },
    },
    ['247_supermarket'] = {
        label   = '24/7 Szupermarket',
        npc     = {
            model    = 's_m_m_strvend_01',
            coords   = vector4(25.7, -1347.3, 29.5, 90.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 52, color = 2, label = '24/7 Szupermarket', scale = 0.8 },
        },
        items   = {
            { item = 'water_bottle', price = 150 },
            { item = 'sandwich',     price = 350 },
            { item = 'coffee',       price = 400 },
            { item = 'energy_drink', price = 500 },
        },
    },
    ['ltd_gasoline'] = {
        label   = 'LTD Benzinkút',
        npc     = {
            model    = 's_m_m_strvend_01',
            coords   = vector4(-707.4, -913.9, 19.2, 270.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 52, color = 2, label = 'LTD Benzinkút', scale = 0.8 },
        },
        items   = {
            { item = 'water_bottle', price = 200 },
            { item = 'sandwich',     price = 400 },
            { item = 'energy_drink', price = 600 },
        },
    },
}

-- ── Animáció szótárak ─────────────────────────────────────────
Config.Animations = {
    ['eating'] = {
        dict = 'amb@world_human_aa_coffee@base',
        clip = 'base',
    },
    ['drinking'] = {
        dict = 'amb@world_human_aa_coffee@base',
        clip = 'base',
    },
}
