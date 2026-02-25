Config = {}

Config.Debug            = false              -- Debug üzenetek megjelenítése
Config.ResourceName     = GetCurrentResourceName()

-- ── Szerver infó (megjelenik a loading screenen) ─────────────
Config.ServerName       = 'Nexon Roleplay'
Config.ServerDescription = 'Üdvözölünk a Nexon Roleplay szerverén! Célunk egy valósághű, szórakoztató RP élmény biztosítása minden játékos számára. Légy részese egy élő, dinamikus városnak!'
Config.ServerLogo       = ''  -- Opcionális: URL vagy üres string (üres = szöveges logo)

-- ── Szabályok ────────────────────────────────────────────────
Config.Rules = {
    { icon = 'hgi-respect',           title = 'Tiszteletadás',       text = 'Minden játékost tiszteld. A személyes sértések és zaklatás tilos.' },
    { icon = 'hgi-mic-01',            title = 'Maradj karakterben',  text = 'OOC kommunikáció csak a kijelölt csatornákon engedélyezett.' },
    { icon = 'hgi-shield-01',         title = 'No RDM / VDM',        text = 'Indokolatlan gyilkosság és járműves ölés szigorúan tiltott.' },
    { icon = 'hgi-bug-01',            title = 'Exploitolás tiltott', text = 'Játékhibák, exploitok és cheatingeszközök használata bannolható.' },
    { icon = 'hgi-communication-01',  title = 'Kommunikáció',        text = 'Konfliktus esetén keress adminisztrátort, ne vedd saját kezedbe.' },
    { icon = 'hgi-time-01',           title = 'Türelem',             text = 'Minden RP szituációban adj időt a másik félnek reagálni.' },
}

-- ── Billentyűparancsok ────────────────────────────────────────
Config.Keybinds = {
    { key = 'F1',       desc = 'Karakterkártya megnyitása' },
    { key = 'F2',       desc = 'Telefonos menü' },
    { key = 'F3',       desc = 'Emote menü' },
    { key = 'F5',       desc = 'Inventory' },
    { key = 'F6',       desc = 'Feladat / Job menu' },
    { key = 'F10',      desc = 'Admin panel (admin only)' },
    { key = 'Y',        desc = 'Kézbe emelt kézfej (megadás)' },
    { key = 'G',        desc = 'Bilétáló / lift interakció' },
    { key = 'E',        desc = 'Általános interakció' },
    { key = 'X',        desc = 'Hangütés / zenemű' },
    { key = '~',        desc = 'OOC chat' },
}

-- ── Zene ─────────────────────────────────────────────────────
Config.Music = {
    enabled = true,
    volume  = 0.35,        -- 0.0 – 1.0
    file    = 'music/loading.mp3',
    fadeOutDuration = 2000 -- ms, mennyi idő alatt halkuljon le
}

-- ── Várólista ────────────────────────────────────────────────
Config.Queue = {
    enabled         = true,
    maxPlayers      = 64,
    updateInterval  = 5000  -- ms, milyen sűrűn frissüljön a pozíció
}

-- ── Loading screen ───────────────────────────────────────────
Config.Loading = {
    modules = {
        { name = 'Core rendszer',          weight = 10 },
        { name = 'Játékoskezelés',         weight = 10 },
        { name = 'Térkép betöltése',       weight = 15 },
        { name = 'Járművek inicializálása',weight = 10 },
        { name = 'Inventory rendszer',     weight = 10 },
        { name = 'UI komponensek',         weight = 10 },
        { name = 'Gazdasági adatok',       weight = 10 },
        { name = 'Job rendszer',           weight = 8  },
        { name = 'Karakteradatok',         weight = 7  },
        { name = 'Világ szinkronizáció',   weight = 10 },
    },
    enterButtonText = 'Irány a város!',
    minLoadTime     = 3000  -- ms minimum loading time (vizuális élmény)
}
