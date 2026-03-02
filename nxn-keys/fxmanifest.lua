fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-keys – Járműkulcs-rendszer, zárolás/nyitás, kulcskarika UI, nxn-engine auth callback'
version     '1.0.0'

dependencies {
    'nxn-engine',
    'nxn-vehicles',
    'nxn-database',
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
