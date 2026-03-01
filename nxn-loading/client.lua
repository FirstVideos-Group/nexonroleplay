-- ============================================================
--  nxn-loading | client.lua
-- ============================================================

local loadingDone    = false
local enterTriggered = false
local serverDataSent = false

-- ── Helpers ──────────────────────────────────────────────────────

-- #59: SendUI – debug log hozzáadva, értékes absztrakcióvá téve
local function SendUI(data)
    NXN.Loading.Log(('SendUI: action=%s'):format(tostring(data.action)))
    SendNUIMessage(data)
end

-- ── Loading screen init ──────────────────────────────────────────
--
-- #60: onClientResourceStart fallback eltávolítva.
-- A loadscreen resource az első futtatott resource – restart nem történik.
-- A CreateThread loop önmagában is kezel 30s timeout-ot, fallback felesleges
-- volt és race condition-t okozhatott a kétszeres playerReady küldéssel.

Citizen.CreateThread(function()
    NXN.Loading.Log('Waiting for session to be active...')

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

-- ── Net events ────────────────────────────────────────────────

RegisterNetEvent('nxn-loading:client:serverData', function(data)
    NXN.Loading.Log('Received serverData from server')
    data.modules         = Config.Loading.modules
    data.enterButtonText = Config.Loading.enterButtonText
    data.musicVolume     = Config.Music.volume
    data.musicFadeOut    = Config.Music.fadeOutDuration
    data.minLoadTime     = Config.Loading.minLoadTime
    data.musicFile       = Config.Music.file
    SendUI({ action = 'serverData', data = data })
end)

RegisterNetEvent('nxn-loading:client:queueUpdate', function(data)
    NXN.Loading.Log(('Queue update: pos=%d total=%d'):format(data.position, data.total))
    SendUI({ action = 'queueUpdate', position = data.position, total = data.total })
end)

-- #61: doEnter – beginFadeOut NUI üzenet küldése a CSS fade-out
-- indításához, majd fadeOutDuration + 200ms buffer után állítjuk le
-- a NUI-t, hogy az animáció ne szakadjon meg (fekete villanás elkerülése)
RegisterNetEvent('nxn-loading:client:doEnter', function()
    NXN.Loading.Log('doEnter received – kezdem a fade-out-ot')
    -- NUI fade-out indítása
    SendUI({ action = 'beginFadeOut' })
    -- Várunk a fade-out animáció lejáratáig + kis buffer
    Citizen.Wait(Config.Music.fadeOutDuration + 200)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end)

-- ── NUI callbacks ──────────────────────────────────────────────

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

-- ── Exportok ────────────────────────────────────────────────

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
