fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-vehicle-hud – Modularis jarmu HUD'
version     '1.0.0'

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua',
    'modules/speed.lua',
    'modules/rpm.lua',
    'modules/gear.lua',
    'modules/lights.lua',
    'modules/engine.lua',
    'modules/fuel.lua',
    'modules/seatbelt.lua',
    'modules/siren.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'docs/index.html'
}

ui_page 'html/index.html'

lua54 'yes'
