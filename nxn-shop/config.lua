Config = {}

Config.Debug           = false
Config.ResourceName    = GetCurrentResourceName()

-- Ha 0, nincs automatikus stock feltöltés
Config.StockRefillInterval = 3600  -- másodpercben

-- Globális eladás engedélyezés (bolt szinten felülírható canSell opcióval)
Config.SellEnabled = true

-- ── Boltok ──────────────────────────────────────────────────────
Config.Shops = {
    ['247_supermarket_1'] = {
        label    = '24/7 Szupermarket (Centro)',
        category = 'general',
        npc = {
            model    = 's_m_m_strvend_01',
            coords   = vector4(25.7, -1347.3, 29.5, 90.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 52, color = 2, label = '24/7 Szupermarket', scale = 0.8 },
        },
        canSell = false,
        sellPriceMultiplier = 0.4,
        items = {
            { item = 'water_bottle',  price = 150,  stock = nil },
            { item = 'sandwich',      price = 250,  stock = nil },
            { item = 'energy_drink',  price = 300,  stock = nil },
            { item = 'bandage',       price = 500,  stock = nil },
            { item = 'painkiller',    price = 600,  stock = nil },
        },
    },
    ['247_supermarket_2'] = {
        label    = '24/7 Szupermarket (Strawberry)',
        category = 'general',
        npc = {
            model    = 's_m_m_strvend_01',
            coords   = vector4(-47.1, -1757.5, 29.4, 50.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 52, color = 2, label = '24/7 Szupermarket', scale = 0.8 },
        },
        canSell = false,
        sellPriceMultiplier = 0.4,
        items = {
            { item = 'water_bottle',  price = 150,  stock = nil },
            { item = 'sandwich',      price = 250,  stock = nil },
            { item = 'energy_drink',  price = 300,  stock = nil },
        },
    },
    ['ltd_gasoline_1'] = {
        label    = 'LTD Benzinkút',
        category = 'general',
        npc = {
            model    = 's_m_m_strvend_01',
            coords   = vector4(-707.4, -913.9, 19.2, 270.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 52, color = 4, label = 'LTD Benzinkút', scale = 0.8 },
        },
        canSell = false,
        sellPriceMultiplier = 0.4,
        items = {
            { item = 'water_bottle',  price = 200,  stock = nil },
            { item = 'sandwich',      price = 400,  stock = nil },
            { item = 'energy_drink',  price = 600,  stock = nil },
        },
    },
    ['pharmacy_1'] = {
        label    = 'Gyógyszertár',
        category = 'medical',
        npc = {
            model    = 's_f_y_scrubs_01',
            coords   = vector4(298.8, -594.9, 43.3, 70.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 61, color = 3, label = 'Gyógyszertár', scale = 0.8 },
        },
        canSell = false,
        sellPriceMultiplier = 0.4,
        items = {
            { item = 'bandage',     price = 400,  stock = nil },
            { item = 'painkiller',  price = 600,  stock = nil },
        },
    },
    ['pawn_shop_1'] = {
        label    = 'Zálogház',
        category = 'general',
        npc = {
            model    = 'g_m_m_chigoon_02',
            coords   = vector4(-320.4, -96.1, 49.9, 260.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 277, color = 6, label = 'Zálogház', scale = 0.8 },
        },
        canSell = true,
        sellPriceMultiplier = 0.4,
        items = {
            { item = 'phone',   price = 2000, stock = 10 },
            { item = 'wallet',  price = 500,  stock = 20 },
            { item = 'keys',    price = 300,  stock = 15 },
        },
    },
    -- ── Éttermi boltok (nxn-food étterem NPC-k helyett ide kerülnek)
    ['burger_shot_1'] = {
        label    = 'Burger Shot',
        category = 'food',
        npc = {
            model    = 'a_m_y_foodlmon_01',
            coords   = vector4(314.9, -208.8, 54.2, 200.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 105, color = 1, label = 'Burger Shot', scale = 0.8 },
        },
        canSell = false,
        sellPriceMultiplier = 0.4,
        items = {
            { item = 'burger',        price = 800,  stock = nil },
            { item = 'sandwich',      price = 500,  stock = nil },
            { item = 'water_bottle',  price = 150,  stock = nil },
            { item = 'energy_drink',  price = 300,  stock = nil },
        },
    },
    ['upnatom_1'] = {
        label    = 'Up-n-Atom',
        category = 'food',
        npc = {
            model    = 's_f_y_sweat_01',
            coords   = vector4(-326.84, -1501.3, 27.0, 118.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled = true, sprite = 105, color = 1, label = 'Up-n-Atom', scale = 0.8 },
        },
        canSell = false,
        sellPriceMultiplier = 0.4,
        items = {
            { item = 'burger',        price = 750,  stock = nil },
            { item = 'sandwich',      price = 450,  stock = nil },
            { item = 'water_bottle',  price = 200,  stock = nil },
        },
    },
}

-- ── Kategória ikonok ──────────────────────────────────────────
Config.CategoryIcons = {
    general  = 'hgi-store-01',
    food     = 'hgi-restaurant-01',
    medical  = 'hgi-medicine-01',
    weapons  = 'hgi-gun-01',
    clothing = 'hgi-t-shirt-01',
}
