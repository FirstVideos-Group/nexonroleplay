fx_version 'cerulean'
game 'gta5'

name        'nxn-finance'
author      'Nexon RP'
version     '1.0.0'
description 'Nexon RP – Központi pénzrendszer (cash & bank)'

shared_scripts {
    'config.lua',
    'shared.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

client_scripts {
    'client.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

ui_page 'html/index.html'

dependencies {
    'nxn-database',
    'nxn-notify',
    'nxn-npcconversation',
}
