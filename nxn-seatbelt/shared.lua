-- ============================================================
--  nxn-seatbelt | shared.lua
-- ============================================================

NXN        = NXN or {}
NXN.Belt   = NXN.Belt or {}

--- Debug log
---@param msg string
function NXN.Belt.Log(msg)
    if Config.Debug then
        print(('[nxn-seatbelt] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.Belt.Info(msg)
    print(('[nxn-seatbelt] [INFO] %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.Belt.Warn(msg)
    print(('[nxn-seatbelt] [WARN] %s'):format(tostring(msg)))
end
