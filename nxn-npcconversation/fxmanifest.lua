fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-npcconversation – Modularis NPC beszelgetes rendszer'
version     '1.0.0'

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

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
    -- #91: docs/index.html eltavolitva – statikus dokumentacio nem kell a files szekcioban
}

ui_page 'html/index.html'

lua54 'yes'
