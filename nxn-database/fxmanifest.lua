fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-database – Nexon központi adatbázis-kezelő resource'
version     '1.0.0'

dependencies {
    'oxmysql'
}

shared_scripts {
    'config.lua',
    'shared.lua'
}

server_scripts {
    'server.lua'
}

files {
    'docs/index.html'
}

lua54 'yes'
