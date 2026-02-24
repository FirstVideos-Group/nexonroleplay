-- ============================================================
--  nxn-seatbelt-extras | shared.lua
-- ============================================================

NXN              = NXN or {}
NXN.SeatbeltExt  = NXN.SeatbeltExt or {}

---@param msg string
function NXN.SeatbeltExt.Log(msg)
    if Config.Debug then
        print(('[nxn-seatbelt-extras] [DEBUG] %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.SeatbeltExt.Info(msg)
    print(('[nxn-seatbelt-extras] [INFO] %s'):format(tostring(msg)))
end

---@param msg string
function NXN.SeatbeltExt.Warn(msg)
    print(('[nxn-seatbelt-extras] [WARN] %s'):format(tostring(msg)))
end
