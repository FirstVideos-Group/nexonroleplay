-- ============================================================
--  nxn-seatbelt | server.lua
-- ============================================================

NXN      = NXN or {}
NXN.Belt = NXN.Belt or {}

function NXN.Belt.Log(msg)
    if Config.Debug then
        print(('[nxn-seatbelt] [DEBUG] %s'):format(tostring(msg)))
    end
end

-- Jatekosok ov allapotanak nyilvantartasa (szerver oldal)
local playerBelts = {}  -- { [src] = boolean }

RegisterNetEvent('nxn-seatbelt:server:stateChanged')
AddEventHandler('nxn-seatbelt:server:stateChanged', function(state)
    local src = source
    playerBelts[src] = state
    NXN.Belt.Log(('Player %d ov allapot: %s'):format(src, tostring(state)))
    -- Tovabbi resource-oknak broadcastolhatunk:
    TriggerClientEvent('nxn-seatbelt:client:syncState', -1, src, state)
end)

-- Jatekos kilepesekor cleanup
AddEventHandler('playerDropped', function()
    local src = source
    playerBelts[src] = nil
    NXN.Belt.Log(('Player %d kilepe, cleanup'):format(src))
end)

-- Export: jatekos ov allapota szerver oldaron
exports('isPlayerBuckled', function(playerId)
    return playerBelts[playerId] == true
end)

-- Export: forceState szerver oldalrol
exports('forcePlayerBuckled', function(playerId, state)
    NXN.Belt.Log(('forcePlayerBuckled: player=%d state=%s'):format(playerId, tostring(state)))
    TriggerClientEvent('nxn-seatbelt:client:forceState', playerId, state)
end)
