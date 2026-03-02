fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-vehicleshop – Járműkereskedés, teszt-menet, NPC, nxn-vehicles + nxn-finance adatréteg'
version     '1.0.0'

dependencies {
    'nxn-vehicles',
    'nxn-finance',
    'nxn-notify'
}

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

ui_page 'html/index.html'

lua54 'yes'
