fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-minimap – Ujradizajnolt minimap NUI overlay-el'
version     '1.0.0'

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua'
}

-- #76: docs/index.html eltávolítva – NUI-ban nem használt fájl
files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

ui_page 'html/index.html'

lua54 'yes'
