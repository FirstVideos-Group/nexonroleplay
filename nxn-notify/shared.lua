-- ============================================================
--  nxn-notify | shared.lua
-- ============================================================

NXN          = NXN or {}
NXN.Notify   = NXN.Notify or {}

--- Debug log
---@param msg string
function NXN.Notify.Log(msg)
    if Config.Debug then
        print(('[nxn-notify] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.Notify.Info(msg)
    print(('[nxn-notify] [INFO] %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.Notify.Warn(msg)
    print(('[nxn-notify] [WARN] %s'):format(tostring(msg)))
end

--- Error log
---@param msg string
function NXN.Notify.Error(msg)
    print(('[nxn-notify] [ERROR] %s'):format(tostring(msg)))
end
