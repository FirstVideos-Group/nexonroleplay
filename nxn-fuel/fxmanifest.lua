fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-fuel – Üzemanyagkezels, fogyasztásszimuláció, DB-perzisztencia, HUD integráció'
version     '1.0.0'

dependencies {
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

lua54 'yes'
