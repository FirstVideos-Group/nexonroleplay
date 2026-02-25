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
    -- FIX: client.lua ELOBB toltodik mint a modulok,
    -- igy moduleStates es hudVisible mar leteznek amikor
    -- a modul fajlok futni kezdenek
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
    'html/app.js',
    'docs/index.html'
}

ui_page 'html/index.html'

lua54 'yes'
