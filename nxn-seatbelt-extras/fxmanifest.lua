fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-seatbelt-extras – Biztonsagi ov fizikai kiegeszitok'
version     '1.0.0'

dependencies {
    'nxn-seatbelt'
}

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua'
}

files {
    'docs/index.html'
}

lua54 'yes'
