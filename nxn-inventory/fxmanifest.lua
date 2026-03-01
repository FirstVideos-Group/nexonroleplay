fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-inventory – Játékos inventory és itemkezelő rendszer'
version     '1.0.0'

dependencies {
    'nxn-database',
    'nxn-notify',
    'nxn-needs',
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
