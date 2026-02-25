-- ============================================================
--  nxn-inventory | config.lua
-- ============================================================

Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- ── Billentyűk ───────────────────────────────────────────────
Config.OpenKey = 'F1'   -- Inventory megnyitó gomb

-- ── Súlyrendszer ────────────────────────────────────────────
Config.MaxWeight = 30.0     -- kg, max súlya az inventorynak

-- ── Hotbar ─────────────────────────────────────────────────
Config.HotbarSlots = 5      -- Hotbar helyek száma (1-8)

-- ── Adatbázis ──────────────────────────────────────────────
Config.InventoryTable = 'nxn_inventories'
Config.SaveInterval   = 120  -- másodperc – periodikális DB-mentés

-- ── Itemek ─────────────────────────────────────────────────
-- icon: HugeIcons osztálynév (hgi-*)
-- weight: kg/darab
-- stackable: több darab egybe számolhat-e
-- usable: használható-e (hasznala eseten csokken)
-- useAction: milyen eseményt triggerel használatkor
-- maxStack: maximalis kupác méret (stackable = true esetén)
-- needs: mit növel használatra (nxn-needs integráció)
--   formátuma: { hunger = 20, thirst = 0, stress = -5 }
Config.Items = {
    -- Étel/ital
    water_bottle = {
        label    = 'Vízespohár',
        icon     = 'hgi-water-polo',
        weight   = 0.5,
        stackable = true,
        maxStack = 10,
        usable   = true,
        useAction = 'nxn-inventory:use:water_bottle',
        needs    = { thirst = 30 },
        category = 'food',
    },
    sandwich = {
        label    = 'Szendvics',
        icon     = 'hgi-bread-01',
        weight   = 0.3,
        stackable = true,
        maxStack = 5,
        usable   = true,
        useAction = 'nxn-inventory:use:sandwich',
        needs    = { hunger = 25 },
        category = 'food',
    },
    energy_drink = {
        label    = 'Energiaéital',
        icon     = 'hgi-drink',
        weight   = 0.4,
        stackable = true,
        maxStack = 5,
        usable   = true,
        useAction = 'nxn-inventory:use:energy_drink',
        needs    = { thirst = 20, fatigue = -15 },
        category = 'food',
    },
    burger = {
        label    = 'Burger',
        icon     = 'hgi-burger-01',
        weight   = 0.4,
        stackable = true,
        maxStack = 5,
        usable   = true,
        useAction = 'nxn-inventory:use:burger',
        needs    = { hunger = 40 },
        category = 'food',
    },
    -- Gyógyszerek
    bandage = {
        label    = 'Kötöszer',
        icon     = 'hgi-first-aid-kit',
        weight   = 0.2,
        stackable = true,
        maxStack = 10,
        usable   = true,
        useAction = 'nxn-inventory:use:bandage',
        needs    = {},
        heal     = 15,
        category = 'medical',
    },
    painkiller = {
        label    = 'Fájdalomcsillapító',
        icon     = 'hgi-medicine-01',
        weight   = 0.1,
        stackable = true,
        maxStack = 10,
        usable   = true,
        useAction = 'nxn-inventory:use:painkiller',
        needs    = { stress = -20 },
        category = 'medical',
    },
    -- Egyebek
    phone = {
        label    = 'Mobiltelefon',
        icon     = 'hgi-smart-phone-01',
        weight   = 0.3,
        stackable = false,
        usable   = false,
        category = 'misc',
    },
    wallet = {
        label    = 'Pénztárca',
        icon     = 'hgi-credit-card-01',
        weight   = 0.1,
        stackable = false,
        usable   = false,
        category = 'misc',
    },
    keys = {
        label    = 'Kulcsok',
        icon     = 'hgi-key-01',
        weight   = 0.1,
        stackable = true,
        maxStack = 5,
        usable   = false,
        category = 'misc',
    },
}

-- ── Jobb klikk menü akciók ─────────────────────────────────
-- Ezeket a NUI-ban is használja a rendszer
Config.ContextActions = {
    use    = { label = 'Használat',  icon = 'hgi-play-circle-01',  condition = 'usable'  },
    hotbar = { label = 'Hotbar-ra',  icon = 'hgi-arrow-down-01',   condition = 'always'  },
    drop   = { label = 'Eldobás',   icon = 'hgi-package-remove',  condition = 'always'  },
    delete = { label = 'Törlés',    icon = 'hgi-delete-01',       condition = 'always'  },
}
