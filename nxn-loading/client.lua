-- ============================================================
--  nxn-loading | client.lua
-- ============================================================

local loadingDone    = false
local enterTriggered = false
local serverDataSent = false

-- ── Helpers ──────────────────────────────────────────────────

local function SendUI(data)
    SendNUIMessage(data)
end

-- ── Loading screen init ──────────────────────────────────────
--
-- A loadscreen resource már fut mielőtt a session inicializálódna.
-- Ezért Citizen.CreateThread-del folyamatosan próbálkozunk,
-- amíg a NetworkIsSessionStarted() igaz nem lesz.

Citizen.CreateThread(function()
    NXN.Loading.Log('Waiting for session to be active...')

    -- Várunk amíg a session életbe lép
    local timeout = 0
    while not NetworkIsSessionStarted() do
        Citizen.Wait(500)
        timeout = timeout + 500
        if timeout >= 30000 then
            NXN.Loading.Log('Session timeout after 30s, proceeding anyway')
            break
        end
    end

    NXN.Loading.Log('Session active, sending playerReady')

    if not serverDataSent then
        serverDataSent = true
        TriggerServerEvent('nxn-loading:server:playerReady')
    end
end)

-- Fallback: ha a thread mégsem fut le (pl. resource restart közben)
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    NXN.Loading.Log('onClientResourceStart fired')

    Citizen.SetTimeout(1000, function()
        if not serverDataSent then
            serverDataSent = true
            NXN.Loading.Log('Fallback: sending playerReady from onClientResourceStart')
            TriggerServerEvent('nxn-loading:server:playerReady')
        end
    end)
end)

-- ── Net events ───────────────────────────────────────────────

RegisterNetEvent('nxn-loading:client:serverData', function(data)
    NXN.Loading.Log('Received serverData from server')
    -- A konfigurációs adatokat is továbbítjuk
    data.modules        = Config.Loading.modules
    data.enterButtonText = Config.Loading.enterButtonText
    data.musicVolume    = Config.Music.volume
    data.musicFadeOut   = Config.Music.fadeOutDuration
    data.minLoadTime    = Config.Loading.minLoadTime
    data.musicFile      = Config.Music.file
    SendUI({ action = 'serverData', data = data })
end)

RegisterNetEvent('nxn-loading:client:queueUpdate', function(data)
    NXN.Loading.Log(('Queue update: pos=%d total=%d'):format(data.position, data.total))
    SendUI({ action = 'queueUpdate', position = data.position, total = data.total })
end)

RegisterNetEvent('nxn-loading:client:doEnter', function()
    NXN.Loading.Log('doEnter received – shutting down loading screen')
    Citizen.Wait(800)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end)

-- ── NUI callbacks ────────────────────────────────────────────

RegisterNUICallback('enterGame', function(_, cb)
    if enterTriggered then cb('ok') return end
    enterTriggered = true
    NXN.Loading.Log('Player clicked enterGame')
    TriggerServerEvent('nxn-loading:server:enterGame')
    cb('ok')
end)

RegisterNUICallback('loadingComplete', function(_, cb)
    loadingDone = true
    NXN.Loading.Log('Loading modules completed (NUI reported)')
    cb('ok')
end)

-- ── Exports ──────────────────────────────────────────────────

exports('isLoadingDone', function()
    return loadingDone
end)

exports('forceEnter', function()
    if not enterTriggered then
        enterTriggered = true
        TriggerServerEvent('nxn-loading:server:enterGame')
    end
end)

exports('updateModuleProgress', function(moduleName, percent)
    NXN.Loading.Log(('External module progress: %s = %d%%'):format(moduleName, percent))
    SendUI({ action = 'externalModule', name = moduleName, percent = percent })
end)

exports('setStatusText', function(text)
    SendUI({ action = 'setStatus', text = text })
end)
