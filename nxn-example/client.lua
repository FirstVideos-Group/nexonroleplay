-- ============================================================
--  nxn-example | client.lua
-- ============================================================

local isUIOpen = false

-- ── Helpers ──────────────────────────────────────────────────

local function SetUIVisible(state)
    isUIOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = 'setVisible', visible = state })
end

-- ── NUI callbacks ────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    SetUIVisible(false)
    cb('ok')
end)

RegisterNUICallback('doAction', function(data, cb)
    NXN.Example.Log('NUI action: ' .. tostring(data.type))
    TriggerServerEvent('nxn-example:server:doAction', data)
    cb('ok')
end)

-- ── Net events ───────────────────────────────────────────────

RegisterNetEvent('nxn-example:client:notify', function(msg)
    SendNUIMessage({ action = 'showNotify', message = msg })
end)

RegisterNetEvent('nxn-example:client:openUI', function()
    SetUIVisible(true)
end)

-- ── Commands ─────────────────────────────────────────────────

RegisterCommand('nxnexample', function()
    if isUIOpen then
        SetUIVisible(false)
    else
        SetUIVisible(true)
    end
end, false)

-- ── Exports ──────────────────────────────────────────────────

exports('openUI',  function() SetUIVisible(true)  end)
exports('closeUI', function() SetUIVisible(false) end)
exports('isUIOpen', function() return isUIOpen    end)

exports('sendNotify', function(msg)
    TriggerServerEvent('nxn-example:server:doAction', { type = 'notify', message = msg })
end)