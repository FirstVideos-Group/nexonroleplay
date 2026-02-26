-- ============================================================
--  nxn-notify | shared.lua
-- ============================================================

NXN          = NXN or {}
NXN.Notify   = NXN.Notify or {}

--- Debug log
---@param msg string
function NXN.Notify.Log(msg)
    if Config.Debug then
        print(('^9[nxn-notify]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.Notify.Info(msg)
    print(('^9[nxn-notify]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.Notify.Warn(msg)
    print(('^9[nxn-notify]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

--- Error log
---@param msg string
function NXN.Notify.Error(msg)
    print(('^9[nxn-notify]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
