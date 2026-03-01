fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-signs – Jelzotabla megjelenito rendszer'
version     '1.0.0'

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'signs/*.svg'
    -- #114: docs/index.html eltavolitva (felesleges, nem NUI fajl)
}

lua54 'yes'
