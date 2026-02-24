fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-location-hud – Modularis lokacois HUD'
version     '1.0.0'

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua',
    'modules/district.lua',
    'modules/street.lua',
    'modules/minimap.lua',
    'modules/zone.lua',
    'modules/danger.lua',
    'modules/wanted.lua',
    'modules/playerstatus.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'docs/index.html'
}

ui_page 'html/index.html'

lua54 'yes'
