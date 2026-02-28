-- ============================================================
--  nxn-licenses | config.lua
-- ============================================================

Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- ── Parancsok ─────────────────────────────────────────
Config.Command = 'idcard'

-- ── Feldolgozási intervallum (másodperc) ─────────────────────
Config.ProcessInterval = 30

-- ── Inventory integráció ────────────────────────────────
--
-- Ha Config.InventoryCheck = true, a script ellenőrzi, hogy az adott
-- igazolvány fizikailag megtalálható-e a játékos inventoryában
-- (nxn-inventory hasItem exportán keresztül) mielőtt:
--   - megengedi a megtekintést/felmutatást
--   - a hasLicense export true-val tér vissza
--
-- Ha false, a régi viselkedés marad (csak DB-ben kell legyen).
--
Config.InventoryCheck = true

-- ── Igazolvány típusok ───────────────────────────────────
--
-- Új mező:
--   inventoryItem : az nxn-inventory-ban lévő item neve.
--                   Amikor az igazolvány kiadásra kerül (manualis grantLicense
--                   vagy feldolgozó tick), a script 1 db ezt az itemet adja
--                   a játékos inventory-jába.
--                   Ha nil / nem adott és InventoryCheck = true,
--                   a típus nem elérhető megtekintésre sem.
Config.LicenseTypes = {
    {
        id            = 'id_card',
        label         = 'Személyi igazolvány',
        icon          = 'hgi-id-verified',
        color         = '#5b6af0',
        processSec    = 300,
        validDays     = 3650,
        cost          = 0,
        requiredAge   = 14,
        showFields    = { 'name', 'birthdate', 'gender', 'id_number', 'issued', 'expires' },
        inventoryItem = 'license_id_card',
    },
    {
        id            = 'drivers_license',
        label         = 'Jogosítvány',
        icon          = 'hgi-steering-wheel',
        color         = '#4ea8de',
        processSec    = 600,
        validDays     = 1825,
        cost          = 500,
        requiredAge   = 17,
        showFields    = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
        inventoryItem = 'license_drivers',
    },
    {
        id            = 'weapon_license',
        label         = 'Fegyverengedély',
        icon          = 'hgi-gun-01',
        color         = '#f05b5b',
        processSec    = 1800,
        validDays     = 730,
        cost          = 2000,
        requiredAge   = 21,
        showFields    = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
        inventoryItem = 'license_weapon',
    },
    {
        id            = 'pilot_license',
        label         = 'Repülő engedély',
        icon          = 'hgi-airplane-01',
        color         = '#a78bfa',
        processSec    = 3600,
        validDays     = 1095,
        cost          = 5000,
        requiredAge   = 18,
        showFields    = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
        inventoryItem = 'license_pilot',
    },
    {
        id            = 'medical_card',
        label         = 'Mentős Szolgálati Kártya',
        icon          = 'hgi-first-aid-kit',
        color         = '#3ecf8e',
        processSec    = 60,
        validDays     = 365,
        cost          = 0,
        requiredAge   = 18,
        showFields    = { 'name', 'birthdate', 'gender', 'id_number', 'issued', 'expires' },
        inventoryItem = 'license_medical',
    },
    {
        id            = 'police_badge',
        label         = 'Rendőrségi Szolgálati Kártya',
        icon          = 'hgi-police-badge',
        color         = '#60a5fa',
        processSec    = 60,
        validDays     = 365,
        cost          = 0,
        requiredAge   = 21,
        showFields    = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
        inventoryItem = 'license_police_badge',
    },
    {
        id            = 'boat_license',
        label         = 'Hajó Engedély',
        icon          = 'hgi-anchor-01',
        color         = '#22d3ee',
        processSec    = 900,
        validDays     = 1825,
        cost          = 1200,
        requiredAge   = 16,
        showFields    = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
        inventoryItem = 'license_boat',
    },
}

-- ── ID szám prefix ────────────────────────────────────────
Config.IdPrefix = 'NXN'
