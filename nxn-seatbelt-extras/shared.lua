-- ============================================================
--  nxn-seatbelt-extras | shared.lua
-- ============================================================

NXN              = NXN or {}
NXN.SeatbeltExt  = NXN.SeatbeltExt or {}

---@param msg string
function NXN.SeatbeltExt.Log(msg)
    if Config.Debug then
        print(('^9[nxn-seatbelt-extras]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.SeatbeltExt.Info(msg)
    print(('^9[nxn-seatbelt-extras]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.SeatbeltExt.Warn(msg)
    print(('^9[nxn-seatbelt-extras]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.SeatbeltExt.Error(msg)
    print(('^9[nxn-seatbelt-extras]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
