-- ============================================================
--  nxn-seatbelt | shared.lua
-- ============================================================

NXN          = NXN or {}
NXN.Seatbelt = NXN.Seatbelt or {}

---@param msg string
function NXN.Seatbelt.Log(msg)
    if Config.Debug then
        print(('^9[nxn-seatbelt]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Seatbelt.Info(msg)
    print(('^9[nxn-seatbelt]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Seatbelt.Warn(msg)
    print(('^9[nxn-seatbelt]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Seatbelt.Error(msg)
    print(('^9[nxn-seatbelt]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
