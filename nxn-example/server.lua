-- ============================================================
--  nxn-example | server.lua
-- ============================================================

-- ── Net events ───────────────────────────────────────────────

RegisterServerEvent('nxn-example:server:doAction', function(data)
    local src = source
    NXN.Example.Log(('Player %s triggered doAction: %s'):format(src, data.type))

    if data.type == 'notify' then
        TriggerClientEvent('nxn-example:client:notify', src, data.message or Config.ExampleText)
    elseif data.type == 'broadcast' then
        TriggerClientEvent('nxn-example:client:notify', -1, data.message or Config.ExampleText)
    end
end)

RegisterServerEvent('nxn-example:server:openUIForPlayer', function(targetSrc)
    local src = source
    TriggerClientEvent('nxn-example:client:openUI', targetSrc or src)
end)

-- ── Exports ──────────────────────────────────────────────────

exports('notifyPlayer', function(src, msg)
    TriggerClientEvent('nxn-example:client:notify', src, msg)
end)

exports('broadcastNotify', function(msg)
    TriggerClientEvent('nxn-example:client:notify', -1, msg)
end)

exports('openUIForPlayer', function(src)
    TriggerClientEvent('nxn-example:client:openUI', src)
end)