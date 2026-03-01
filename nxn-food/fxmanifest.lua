fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-food – Étel/ital fogyasztás, NPC éttermek, leltár integráció'
version     '1.0.0'

dependencies {
    'nxn-needs',
    'nxn-inventory',
    'nxn-notify',
    'nxn-npcconversation',
    'nxn-finance'
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
