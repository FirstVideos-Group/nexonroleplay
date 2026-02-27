-- ============================================================
--  nxn-cityhall | config.lua
-- ============================================================

Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- ── Önkormányzat hely / blip ───────────────────────────────
Config.Building = {
    name     = 'Önkormányzat',
    coords   = vector3(372.77, -596.89, 28.75),   -- Rockford Hills City Hall
    -- Fő épület blip (mindig látszik)
    blip = {
        enabled = true,
        sprite  = 475,      -- City Hall ikon
        color   = 4,        -- zöld
        scale   = 0.9,
        label   = 'Önkormányzat',
    },
}

-- ── NPC beállítások ───────────────────────────────────────
Config.NPC = {
    id      = 'cityhall_clerk',
    label   = 'Ügyintéző',
    model   = 'ig_priest',
    coords  = vector4(372.1, -596.8, 28.75, 159.0),
    scenario = 'WORLD_HUMAN_CLIPBOARD',

    -- NPC közeli blip (csak X méteren belül látszik)
    blip = {
        enabled     = true,
        sprite      = 446,
        color       = 5,
        scale       = 0.7,
        label       = 'Ügyintéző',
        visibleDist = 80.0,   -- láthatSági távolság méterben
    },
}

-- ── Interakciós távolságok ──────────────────────────────
Config.InteractDistance = 3.0   -- nyárás távolsága (m)
Config.HintDistance     = 6.0   -- tipp szöveg megjelenése (m)

-- ── Ügyek / menii ───────────────────────────────────────
--
-- Minden fobészélgetési opció ide kerül. Ezek az nxn-npcconversation-ban
-- registerelt diálogusok. Az 'action' mező mondja meg a scriptnek mi történjen.
--
-- action tímogatott értékek (beépített):
--   'openLicenses'   – Igazolvány menü megnyitása (nxn-licenses)
--   'openFines'      – Csekk/bírsság nézet megnyitása
--   'openInfo'       – Információs panel megnyitása
--   'custom'         – Saját event (eventName mezővel megadható)
--
-- Külső resourceok runtime hozzáadhatnak új menüelemeket az
-- exports['nxn-cityhall']:addMenuItem(...) exporton keresztül.

Config.MenuItems = {
    {
        id       = 'licenses',
        label    = 'Igazolványok',
        icon     = 'hgi-id-verified',
        response = 'Rendben, híd elő az igazolvány kezelőt!',
        action   = 'openLicenses',
    },
    {
        id       = 'fines',
        label    = 'Bírságaim / Csekk',
        icon     = 'hgi-invoice-03',
        response = 'Azonnal megnezem a függő csekkjeit.',
        action   = 'openFines',
    },
    {
        id       = 'info',
        label    = 'Állampolgári Újabb Információk',
        icon     = 'hgi-information-circle',
        response = 'Az aktualitásokat már kitettem a hirdetőtáblára.',
        action   = 'openInfo',
    },
    -- Jövőbeli beővítések (példák):
    --[[
    {
        id       = 'evidence',
        label    = 'Bizonyíték beadása',
        icon     = 'hgi-folder-security',
        response = 'A beadáshoz töltőd ki az űrlapot.',
        action   = 'custom',
        eventName = 'nxn-police:client:openEvidenceForm',
    },
    {
        id       = 'court',
        label    = 'Bírósági időpont',
        icon     = 'hgi-justice-scale-01',
        response = 'A következő szabad időpont már foglalva van önnek.',
        action   = 'custom',
        eventName = 'nxn-court:client:openSchedule',
    },
    ]]
}

-- ── Tájékoztató szöveg (openInfo) ────────────────────────
Config.InfoContent = {
    title   = 'Hatósági Tájékoztató',
    items = {
        { icon = 'hgi-id-verified',     text = 'Az igazolvány kiváltáshoz szükséges személyesen befaiti az önkormányzathoz.' },
        { icon = 'hgi-steering-wheel',  text = 'Jogosítvány igénylése: 17 éves kor fölött, 10 perc feldolgozási idő.' },
        { icon = 'hgi-invoice-03',      text = 'Ki nem fizetett bírság esetén az Ügyintézőnél lehet rendezni.' },
        { icon = 'hgi-alert-circle',    text = 'Az igazolványok lejárata előtt 7 nappal értesítést küldünk.' },
    },
}

-- ── Csekk panel beállítás ────────────────────────────────
Config.FinesPanel = {
    title   = 'Csekk / Bírság Kezelő',
    emptyMsg = 'Nincs fiiggő bírságod. Szép munka!',
}
