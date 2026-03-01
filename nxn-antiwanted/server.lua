-- ============================================================
--  nxn-antiwanted | server.lua
-- ============================================================

-- ── Per-player wanted state tábla ────────────────────────────
-- Nyilvántartja, hogy egyes játékosoknál engedélyezett-e a körözés

local playerWantedState = {}

AddEventHandler('playerDropped', function()
    playerWantedState[source] = nil
end)

-- ── Játékos ready event (kliens jelzi, hogy betöltött) ────────
-- A 'playerSpawned' nem létezik natívan szerver oldalon,
-- ezért a kliens triggereli ezt az eventet spawn után.

RegisterServerEvent('nxn-antiwanted:server:playerReady')
AddEventHandler('nxn-antiwanted:server:playerReady', function()
    local src = source
    NXN.AntiWanted.Log(('playerReady: clearing wanted for src=%s'):format(src))
    TriggerClientEvent('nxn-antiwanted:client:clearWanted', src)
end)

-- ── Kliens visszajelzés az aktuális állapotról ────────────────

RegisterServerEvent('nxn-antiwanted:server:reportState')
AddEventHandler('nxn-antiwanted:server:reportState', function(allow)
    local src = source
    playerWantedState[src] = allow
    NXN.AntiWanted.Log(('reportState: src=%s allow=%s'):format(src, tostring(allow)))
end)

-- ── Net event: wanted state átállítása (ACE védett) ──────────

RegisterServerEvent('nxn-antiwanted:server:setWantedState')
AddEventHandler('nxn-antiwanted:server:setWantedState', function(allow)
    local src = source
    if not IsPlayerAceAllowed(src, 'nxn-antiwanted.setWantedState') then
        NXN.AntiWanted.Warn(('Unauthorized setWantedState attempt from src=%s'):format(src))
        return
    end
    NXN.AntiWanted.Log(('setWantedState: src=%s allow=%s'):format(src, tostring(allow)))
    TriggerClientEvent('nxn-antiwanted:client:setWantedState', src, allow)
end)

-- ── Exports ───────────────────────────────────────────────────

--- Szerver oldalról kényszeríti a körözés törlését egy játékosnál
---@param src integer  játékos source ID
exports('clearWantedForPlayer', function(src)
    NXN.AntiWanted.Log(('Server export: clearWantedForPlayer src=%s'):format(src))
    TriggerClientEvent('nxn-antiwanted:client:clearWanted', src)
end)

--- Szerver oldalról engedélyezi a körözési rendszert egy játékosnál
---@param src integer
exports('enableWantedForPlayer', function(src)
    NXN.AntiWanted.Log(('Server export: enableWantedForPlayer src=%s'):format(src))
    playerWantedState[src] = true
    TriggerClientEvent('nxn-antiwanted:client:setWantedState', src, true)
end)

--- Szerver oldalról letiltja a körözési rendszert egy játékosnál
---@param src integer
exports('disableWantedForPlayer', function(src)
    NXN.AntiWanted.Log(('Server export: disableWantedForPlayer src=%s'):format(src))
    playerWantedState[src] = false
    TriggerClientEvent('nxn-antiwanted:client:setWantedState', src, false)
end)

--- Lekéri, hogy egy játékosnál engedélyezett-e a körözés
---@param src integer
---@return boolean
exports('getWantedStateForPlayer', function(src)
    -- Ha még nincs bejegyezve, a config alapértelmezett értékét adja vissza
    if playerWantedState[src] == nil then
        return Config.AllowWanted
    end
    return playerWantedState[src]
end)
