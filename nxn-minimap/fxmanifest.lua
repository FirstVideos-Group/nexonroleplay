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

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'docs/index.html'
}

ui_page 'html/index.html'

lua54 'yes'
