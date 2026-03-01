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

-- #106: files szekció teljeségében eltávolítva
-- (docs/index.html felesleges, nincs NUI/ui_page ebben a resourceban)

lua54 'yes'
