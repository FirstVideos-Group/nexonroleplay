fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-database – Nexon kozponti adatbazis-kezelo resource'
version     '1.0.0'

dependencies {
    'oxmysql'
}

shared_scripts {
    'config.lua',
    'shared.lua'
}

server_scripts {
    -- FIX: az oxmysql MySQL globalisa csak akkor erheto el, ha
    -- ezt a lib fajlt betoltjuk. Enelkul MySQL = nil -> crash.
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

files {
    'docs/index.html'
}

lua54 'yes'
