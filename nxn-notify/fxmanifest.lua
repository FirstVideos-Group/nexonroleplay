fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-notify – Vizualis ertesitesi rendszer'
version     '1.0.0'

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

files {
    'docs/index.html'
}

lua54 'yes'
