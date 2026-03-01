fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-autoseatbelt – Automatikus biztonsagi ov kiegeszito'
version     '1.0.0'

dependencies {
    'nxn-seatbelt',
    'nxn-notify'
}

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua'
}

files {
    'sounds/seatbelt_auto.ogg',
    'html/index.html',
    'docs/index.html'
}

ui_page 'html/index.html'

lua54 'yes'
