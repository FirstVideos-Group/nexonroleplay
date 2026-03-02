Config = {}

Config.ResourceName  = GetCurrentResourceName()
Config.Debug         = false

-- Alapértelmezett munkakör (ha nincs beállítva)
Config.DefaultJob    = 'unemployed'
Config.DefaultGrade  = 0

-- Munkakörök definíciója
-- salary: órabér Ft-ban (az nxn-jobwork fizeti ki, ez csak a mértéket tárolja)
Config.Jobs = {
    ['unemployed'] = {
        label  = 'Munkanélküli',
        color  = '#888888',
        grades = {
            [0] = { label = 'Munkanélküli', salary = 0 },
        },
    },
    ['police'] = {
        label  = 'Rendőrség',
        color  = '#3a7bd5',
        grades = {
            [0] = { label = 'Rendőr',         salary = 2500 },
            [1] = { label = 'Főrendőr',        salary = 3000 },
            [2] = { label = 'Nyomozó',          salary = 3500 },
            [3] = { label = 'Hadnagy',           salary = 4000 },
            [4] = { label = 'Főhadnagy',        salary = 5000 },
            [5] = { label = 'Ezredes',           salary = 6500 },
        },
    },
    ['ems'] = {
        label  = 'Mentőszolgálat',
        color  = '#e74c3c',
        grades = {
            [0] = { label = 'Mentős',           salary = 2200 },
            [1] = { label = 'Főmentős',         salary = 2800 },
            [2] = { label = 'Paramedikus',       salary = 3400 },
            [3] = { label = 'Főorvos',           salary = 4500 },
        },
    },
    ['mechanic'] = {
        label  = 'Szerelő',
        color  = '#f39c12',
        grades = {
            [0] = { label = 'Tanuló szerelő',   salary = 1800 },
            [1] = { label = 'Szerelő',           salary = 2400 },
            [2] = { label = 'Főszerelő',         salary = 3200 },
            [3] = { label = 'Műhelyvezető',     salary = 4200 },
        },
    },
    ['taxi'] = {
        label  = 'Taxisofőr',
        color  = '#f1c40f',
        grades = {
            [0] = { label = 'Sofőr',             salary = 1600 },
            [1] = { label = 'Tapasztalt sofőr', salary = 2000 },
        },
    },
    ['trucker'] = {
        label  = 'Kamionos',
        color  = '#8e44ad',
        grades = {
            [0] = { label = 'Sofőr',             salary = 1700 },
            [1] = { label = 'Senior sofőr',      salary = 2300 },
            [2] = { label = 'Flottavezető',      salary = 3100 },
        },
    },
    -- [nxn-delivery] Teljesítményalapú munkakör – salary=0, az nxn-delivery fizet
    ['delivery'] = {
        label  = 'Szállító',
        color  = '#e67e22',
        grades = {
            [0] = { label = 'Futár',            salary = 0 },
            [1] = { label = 'Tapasztalt Futár', salary = 0 },
            [2] = { label = 'Főfutár',          salary = 0 },
        },
    },
}

-- Admin ACE jog módosításhoz
Config.AdminAce = 'nxn.job.admin'
