fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-licenses – Igazolvány és engedélykezelő rendszer'
version     '1.0.0'

shared_scripts {
    'config.lua',
    'shared.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

ui_page 'html/index.html'

lua54 'yes'
