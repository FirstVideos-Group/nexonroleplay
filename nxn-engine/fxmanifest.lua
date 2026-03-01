fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-engine – Motorvezerlesi rendszer'
version     '1.1.0'

dependencies {
    'nxn-notify',
    'nxn-vehicle-hud',
    'nxn-seatbelt-extras',
}

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua'
}

lua54 'yes'
