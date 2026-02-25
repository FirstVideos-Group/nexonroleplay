-- ============================================================
--  nxn-loading | client.lua
-- ============================================================

local loadingDone    = false
local enterTriggered = false

-- ── Helpers ──────────────────────────────────────────────────

local function SendUI(data)
    SendNUIMessage(data)
end

-- ── Loading screen init ──────────────────────────────────────

-- Jelezzük a szervernek, hogy a kliens betöltési képernyőn van
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        NXN.Loading.Log('Resource started, sending playerReady to server')
        TriggerServerEvent('nxn-loading:server:playerReady')
    end
end)

-- ── Net events ───────────────────────────────────────────────

RegisterNetEvent('nxn-loading:client:serverData', function(data)
    NXN.Loading.Log('Received serverData from server')
    SendUI({ action = 'serverData', data = data })
end)

RegisterNetEvent('nxn-loading:client:queueUpdate', function(data)
    NXN.Loading.Log(('Queue update: pos=%d total=%d'):format(data.position, data.total))
    SendUI({ action = 'queueUpdate', position = data.position, total = data.total })
end)

RegisterNetEvent('nxn-loading:client:doEnter', function()
    NXN.Loading.Log('doEnter received – shutting down loading screen')
    -- Fade + zene lehalkulás az NUI-ban már megtörtént, most shutdown
    Citizen.Wait(500)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end)

-- ── NUI callbacks ────────────────────────────────────────────

-- Játékos megnyomta az 'Irány a város!' gombot
RegisterNUICallback('enterGame', function(_, cb)
    if enterTriggered then cb('ok') return end
    enterTriggered = true
    NXN.Loading.Log('Player clicked enterGame')
    TriggerServerEvent('nxn-loading:server:enterGame')
    cb('ok')
end)

-- Modul betöltési progress frissítés (NUI -> Lua szükség esetén)
RegisterNUICallback('loadingComplete', function(_, cb)
    loadingDone = true
    NXN.Loading.Log('Loading modules completed (NUI reported)')
    cb('ok')
end)

-- ── Exports ──────────────────────────────────────────────────

--- Visszaadja, hogy a betöltés kész-e
---@return boolean
exports('isLoadingDone', function()
    return loadingDone
end)

--- Más resource kényszerítheti a belépést (pl. admin tool)
exports('forceEnter', function()
    if not enterTriggered then
        enterTriggered = true
        TriggerServerEvent('nxn-loading:server:enterGame')
    end
end)

--- Frissít egy modul progress-t kívülről (más resource hívhatja)
---@param moduleName string
---@param percent number  0-100
exports('updateModuleProgress', function(moduleName, percent)
    NXN.Loading.Log(('External module progress: %s = %d%%'):format(moduleName, percent))
    SendUI({ action = 'externalModule', name = moduleName, percent = percent })
end)

--- Szöveges üzenetet jelenít meg a loading screenre
---@param text string
exports('setStatusText', function(text)
    SendUI({ action = 'setStatus', text = text })
end)
