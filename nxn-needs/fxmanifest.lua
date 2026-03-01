fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-needs – Játékos szükséglet-kezelő (hunger, thirst, stress, fatigue)'
version     '1.0.0'

dependencies {
    'oxmysql',
    'nxn-database'
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

-- #83: docs/index.html eltávolítva – NUI nélküli resource-ban files szekció felesleges

lua54 'yes'
