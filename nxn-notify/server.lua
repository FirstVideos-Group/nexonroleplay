-- ============================================================
--  nxn-notify | server.lua
-- ============================================================

-- ── Belső segédfüggvények ───────────────────────────────────────

---@param src number
---@param msg string
---@param type string
---@param duration number|nil
---@param title string|nil
local function SendToPlayer(src, msg, type, duration, title)
    if not src or not msg then
        NXN.Notify.Warn('SendToPlayer: hiányzó paraméter')
        return
    end
    NXN.Notify.Log(('SendToPlayer: src=%d type=%s'):format(src, tostring(type)))
    TriggerClientEvent('nxn-notify:client:show', src, msg, type or 'info', duration, title)
end

-- ── Exportok ─────────────────────────────────────────────────

--- Értesítés küldése egy játékosnak
---@param src number
---@param msg string
---@param type string  'info'|'success'|'danger'|'warning'
---@param duration number|nil
---@param title string|nil
exports('notify', function(src, msg, type, duration, title)
    SendToPlayer(src, msg, type, duration, title)
end)

--- Info értesítés
---@param src number
---@param msg string
---@param duration number|nil
exports('info', function(src, msg, duration)
    SendToPlayer(src, msg, 'info', duration)
end)

--- Siker értesítés
---@param src number
---@param msg string
---@param duration number|nil
exports('success', function(src, msg, duration)
    SendToPlayer(src, msg, 'success', duration)
end)

--- Hiba értesítés
---@param src number
---@param msg string
---@param duration number|nil
exports('danger', function(src, msg, duration)
    SendToPlayer(src, msg, 'danger', duration)
end)

--- Figyelmeztetés
---@param src number
---@param msg string
---@param duration number|nil
exports('warning', function(src, msg, duration)
    SendToPlayer(src, msg, 'warning', duration)
end)

--- Broadcast: minden online játékosnak küld
---@param msg string
---@param type string
---@param duration number|nil
---@param title string|nil
exports('broadcast', function(msg, type, duration, title)
    NXN.Notify.Log(('broadcast: type=%s'):format(tostring(type)))
    TriggerClientEvent('nxn-notify:client:show', -1, msg, type or 'info', duration, title)
end)
