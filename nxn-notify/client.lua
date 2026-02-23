-- ============================================================
--  nxn-notify | client.lua
-- ============================================================

-- ── Belső segédfüggvények ───────────────────────────────────────

---@param msg string
---@param type string  'info'|'success'|'danger'|'warning'
---@param duration number|nil  ms, nil = Config.Duration
---@param title string|nil  fejléc szöveg
local function ShowNotify(msg, type, duration, title)
    if not msg or msg == '' then
        NXN.Notify.Warn('ShowNotify: üres üzenet, kihagyva')
        return
    end
    local t = type or 'info'
    local d = duration or Config.Duration
    NXN.Notify.Log(('ShowNotify: type=%s dur=%d msg=%s'):format(t, d, msg))
    SendNUIMessage({
        action   = 'show',
        message  = msg,
        type     = t,
        duration = d,
        title    = title or nil,
    })
    if Config.Sound and Config.Sound.enabled then
        PlaySoundFrontend(-1, Config.Sound.soundname, Config.Sound.soundset, true)
    end
end

-- ── Net events ────────────────────────────────────────────────

RegisterNetEvent('nxn-notify:client:show', function(msg, type, duration, title)
    NXN.Notify.Log(('Net event fogadva: type=%s'):format(tostring(type)))
    ShowNotify(msg, type, duration, title)
end)

-- ── Exportok ─────────────────────────────────────────────────

--- Általános értesítés
---@param msg string
---@param duration number|nil
exports('info', function(msg, duration)
    ShowNotify(msg, 'info', duration)
end)

--- Siker értesítés
---@param msg string
---@param duration number|nil
exports('success', function(msg, duration)
    ShowNotify(msg, 'success', duration)
end)

--- Hiba értesítés
---@param msg string
---@param duration number|nil
exports('danger', function(msg, duration)
    ShowNotify(msg, 'danger', duration)
end)

--- Figyelmeztetés
---@param msg string
---@param duration number|nil
exports('warning', function(msg, duration)
    ShowNotify(msg, 'warning', duration)
end)

--- Általános, típust választható hívás
---@param msg string
---@param type string
---@param duration number|nil
---@param title string|nil
exports('notify', function(msg, type, duration, title)
    ShowNotify(msg, type, duration, title)
end)

--- NUI üzenet küldése közvetlenül (haladó használatra)
---@param data table
exports('sendRaw', function(data)
    NXN.Notify.Log('sendRaw export hívva')
    SendNUIMessage(data)
end)
