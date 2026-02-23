fx_version 'cerulean'
game 'gta5'

author      'Nexon Dev Team <nexondev@firstvideosgroup.eu>'
description 'nxn-hud – Modularis jatekos HUD'
version     '1.0.0'

dependencies {
    'nxn-needs'
}

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua',
    'modules/health.lua',
    'modules/needs.lua',
    'modules/stamina.lua',
    'modules/oxygen.lua',
    'modules/stress.lua',
    'modules/money.lua',
    'modules/job.lua',
    'modules/playerid.lua',
    'modules/datetime.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

ui_page 'html/index.html'

files {
    'docs/index.html'
}

lua54 'yes'
