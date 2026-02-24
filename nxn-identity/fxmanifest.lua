fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-identity – Karakter identitas es skin rendszer'
version     '1.0.0'

shared_scripts {
    'config.lua',
    'shared.lua'
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'docs/index.html'
}

lua54 'yes'
