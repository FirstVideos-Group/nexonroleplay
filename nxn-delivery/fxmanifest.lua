fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-delivery – Szállítási munka (teljesítményalapú futármunka)'
version     '1.0.0'

dependencies {
    'nxn-job',
    'nxn-jobwork',
    'nxn-finance',
    'nxn-database',
    'nxn-identity',
    'nxn-notify',
    'nxn-npcconversation',
    'nxn-loading',
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
