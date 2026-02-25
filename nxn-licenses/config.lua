-- ============================================================
--  nxn-licenses | config.lua
-- ============================================================

Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- ── Parancsok ─────────────────────────────────────────────
Config.Command = 'idcard'      -- Inventory megnyitó parancs

-- ── Igénylés feldolgozási intervallum (másodperc) ────────────
Config.ProcessInterval = 30    -- 30 másodpercenként nézi át a függő igényléseket

-- ── Igazolvány típusok ──────────────────────────────────
--
-- id          : belso azonosító (string, egyedi)
-- label       : megjelenitési név
-- icon        : HugeIcons CSS osztály
-- processSec  : hány másodperccel a váltás után kerül a játékoshoz
-- validDays   : érvényesség napokban (0 = sosem jár le)
-- cost        : kiváltás ára ($, 0 = ingyenes) – jövőbeli pénzrendszer integrációhoz
-- requiredAge : minimum életkor (0 = nincs korlát)
-- showFields  : milyen mezőket mutat az igazolványon
--   támogatott mezők: name, birthdate, gender, id_number, issued, expires
Config.LicenseTypes = {
    {
        id          = 'id_card',
        label       = 'Személyi igazolvány',
        icon        = 'hgi-id-verified',
        processSec  = 300,       -- 5 perc
        validDays   = 3650,      -- 10 év
        cost        = 0,
        requiredAge = 14,
        showFields  = { 'name', 'birthdate', 'gender', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'drivers_license',
        label       = 'Jogosítvány',
        icon        = 'hgi-steering-wheel',
        processSec  = 600,       -- 10 perc
        validDays   = 1825,      -- 5 év
        cost        = 500,
        requiredAge = 17,
        showFields  = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'weapon_license',
        label       = 'Fegyverengedély',
        icon        = 'hgi-gun-01',
        processSec  = 1800,      -- 30 perc
        validDays   = 730,       -- 2 év
        cost        = 2000,
        requiredAge = 21,
        showFields  = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'pilot_license',
        label       = 'Repülő engedély',
        icon        = 'hgi-airplane-01',
        processSec  = 3600,      -- 60 perc
        validDays   = 1095,      -- 3 év
        cost        = 5000,
        requiredAge = 18,
        showFields  = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'medical_card',
        label       = 'Mentős Szolgálati Kártya',
        icon        = 'hgi-first-aid-kit',
        processSec  = 60,        -- 1 perc (hiv. kibocsatasa)
        validDays   = 365,       -- 1 év
        cost        = 0,
        requiredAge = 18,
        showFields  = { 'name', 'birthdate', 'gender', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'police_badge',
        label       = 'Rendőrségi Szolgálati Kártya',
        icon        = 'hgi-police-badge',
        processSec  = 60,
        validDays   = 365,
        cost        = 0,
        requiredAge = 21,
        showFields  = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'boat_license',
        label       = 'Hajó Engedély',
        icon        = 'hgi-anchor-01',
        processSec  = 900,       -- 15 perc
        validDays   = 1825,      -- 5 év
        cost        = 1200,
        requiredAge = 16,
        showFields  = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
    },
}

-- ── Névtelen ID szám prefix ─────────────────────────────────
-- Minden igazolványhoz genertorál egy egyedi ID számot
Config.IdPrefix = 'NXN'
