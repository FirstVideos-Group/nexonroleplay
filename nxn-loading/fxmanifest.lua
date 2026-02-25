fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-loading – Nexon Loading Screen resource'
version     '1.0.0'

loadscreen 'html/index.html'
loadscreen_manual_shutdown 'yes'

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
    'html/app.js',
    'music/*.mp3'
}

lua54 'yes'
