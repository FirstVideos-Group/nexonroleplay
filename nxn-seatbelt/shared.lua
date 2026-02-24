-- ============================================================
--  nxn-seatbelt | shared.lua
-- ============================================================

NXN          = NXN or {}
NXN.Seatbelt = NXN.Seatbelt or {}

---@param msg string
function NXN.Seatbelt.Log(msg)
    if Config.Debug then
        print(('[nxn-seatbelt] [DEBUG] %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Seatbelt.Info(msg)
    print(('[nxn-seatbelt] [INFO] %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Seatbelt.Warn(msg)
    print(('[nxn-seatbelt] [WARN] %s'):format(tostring(msg)))
end
