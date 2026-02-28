-- ============================================================
--  nxn-inventory | config.lua
-- ============================================================

Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- ── Billentyűk ────────────────────────────────────────────
Config.OpenKey = 'F1'

-- ── Súlyrendszer ──────────────────────────────────────────
Config.MaxWeight = 30.0

-- ── Hotbar ──────────────────────────────────────────────
Config.HotbarSlots = 5

-- ── Adatbázis ───────────────────────────────────────────
Config.InventoryTable = 'nxn_inventories'
Config.SaveInterval   = 120

-- ── Itemek ──────────────────────────────────────────────
Config.Items = {
    -- ── Étel/ital ──
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
        label    = 'Energiaiþtal',
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
    -- ── Gyógyszerek ──
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
        label    = 'Fájdalomcsillapitó',
        icon     = 'hgi-medicine-01',
        weight   = 0.1,
        stackable = true,
        maxStack = 10,
        usable   = true,
        useAction = 'nxn-inventory:use:painkiller',
        needs    = { stress = -20 },
        category = 'medical',
    },
    -- ── Egyébek ──
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

    -- ============================================================
    --  nxn-licenses igazolvány tárgyak
    --  Ezeket a nxn-licenses automatikusan adja / veszi el.
    --  usable = false: a játékos nem tudja elővenni/használni,
    --  de más scriptekben ellenorizhető a jelenléte.
    -- ============================================================
    license_id_card = {
        label     = 'Személyi igazolvány',
        icon      = 'hgi-id-verified',
        weight    = 0.01,
        stackable = false,
        usable    = false,
        category  = 'documents',
    },
    license_drivers = {
        label     = 'Jogosítvány',
        icon      = 'hgi-steering-wheel',
        weight    = 0.01,
        stackable = false,
        usable    = false,
        category  = 'documents',
    },
    license_weapon = {
        label     = 'Fegyverengedély',
        icon      = 'hgi-gun-01',
        weight    = 0.01,
        stackable = false,
        usable    = false,
        category  = 'documents',
    },
    license_pilot = {
        label     = 'Repülő engedély',
        icon      = 'hgi-airplane-01',
        weight    = 0.01,
        stackable = false,
        usable    = false,
        category  = 'documents',
    },
    license_medical = {
        label     = 'Mentős Szolgálati Kártya',
        icon      = 'hgi-first-aid-kit',
        weight    = 0.01,
        stackable = false,
        usable    = false,
        category  = 'documents',
    },
    license_police_badge = {
        label     = 'Rendőrségi Szolgálati Kártya',
        icon      = 'hgi-police-badge',
        weight    = 0.01,
        stackable = false,
        usable    = false,
        category  = 'documents',
    },
    license_boat = {
        label     = 'Hajó Engedély',
        icon      = 'hgi-anchor-01',
        weight    = 0.01,
        stackable = false,
        usable    = false,
        category  = 'documents',
    },
}

-- ── Jobb klikk menü akciók ─────────────────────────────────
Config.ContextActions = {
    use    = { label = 'Használat',  icon = 'hgi-play-circle-01',  condition = 'usable'  },
    hotbar = { label = 'Hotbar-ra',  icon = 'hgi-arrow-down-01',   condition = 'always'  },
    drop   = { label = 'Eldobás',   icon = 'hgi-package-remove',  condition = 'always'  },
    delete = { label = 'Törlés',    icon = 'hgi-delete-01',       condition = 'always'  },
}
