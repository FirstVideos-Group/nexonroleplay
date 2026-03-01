fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-shop – Általános boltrendszer, NPC kereskedők, inventory integráció'
version     '1.0.0'

dependencies {
    'nxn-inventory',
    'nxn-notify',
    'nxn-npcconversation',
    'nxn-finance',
    'nxn-database'
}

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

ui_page 'html/index.html'

lua54 'yes'
