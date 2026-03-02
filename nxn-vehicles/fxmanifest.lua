fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-vehicles – Jármű adat- és eseményréteg, belépés-detekció, jogosítvány-ellenőrzés'
version     '1.0.0'

dependencies {
    'nxn-database',
    'nxn-identity',
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
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

lua54 'yes'
