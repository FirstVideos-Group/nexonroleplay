-- ============================================================
--  nxn-licenses | config.lua
-- ============================================================

Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- ── Parancsok ─────────────────────────────────────────
Config.Command = 'idcard'      -- Inventory megnyitó parancs

-- ── Igénylés feldolgozási intervallum (másodperc) ─────────────
Config.ProcessInterval = 30    -- 30 másodpercenként nézi át a függő igényléseket

-- ── Igazolvány típusok ──────────────────────────────────
--
-- id          : belso azonosító (string, egyedi)
-- label       : megjelenitési név
-- icon        : HugeIcons CSS osztály
-- color       : az igazolvány és lista sor egyedi színe (hex vagy CSS érték)
--               Ha nincs megadva, az alapbázis accent szín érvényesül.
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
        color       = '#5b6af0',   -- kek-lila (alap accent)
        processSec  = 300,
        validDays   = 3650,
        cost        = 0,
        requiredAge = 14,
        showFields  = { 'name', 'birthdate', 'gender', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'drivers_license',
        label       = 'Jogosítvány',
        icon        = 'hgi-steering-wheel',
        color       = '#4ea8de',   -- ég színső kek
        processSec  = 600,
        validDays   = 1825,
        cost        = 500,
        requiredAge = 17,
        showFields  = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'weapon_license',
        label       = 'Fegyverengedély',
        icon        = 'hgi-gun-01',
        color       = '#f05b5b',   -- piros
        processSec  = 1800,
        validDays   = 730,
        cost        = 2000,
        requiredAge = 21,
        showFields  = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'pilot_license',
        label       = 'Repülő engedély',
        icon        = 'hgi-airplane-01',
        color       = '#a78bfa',   -- lila
        processSec  = 3600,
        validDays   = 1095,
        cost        = 5000,
        requiredAge = 18,
        showFields  = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'medical_card',
        label       = 'Mentős Szolgálati Kártya',
        icon        = 'hgi-first-aid-kit',
        color       = '#3ecf8e',   -- zöld
        processSec  = 60,
        validDays   = 365,
        cost        = 0,
        requiredAge = 18,
        showFields  = { 'name', 'birthdate', 'gender', 'id_number', 'issued', 'expires' },
    },
    {
        id          = 'police_badge',
        label       = 'Rendőrségi Szolgálati Kártya',
        icon        = 'hgi-police-badge',
        color       = '#60a5fa',   -- világos kek
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
        color       = '#22d3ee',   -- cian
        processSec  = 900,
        validDays   = 1825,
        cost        = 1200,
        requiredAge = 16,
        showFields  = { 'name', 'birthdate', 'id_number', 'issued', 'expires' },
    },
}

-- ── Névtelen ID szám prefix ─────────────────────────────────
Config.IdPrefix = 'NXN'
