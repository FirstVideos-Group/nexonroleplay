-- ============================================================
--  nxn-food | shared.lua
-- ============================================================

NXN = NXN or {}
NXN.Food = {}

---@param msg string
function NXN.Food.Log(msg)
    if Config.Debug then
        print(('^9[nxn-food]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Food.Info(msg)
    print(('^9[nxn-food]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Food.Warn(msg)
    print(('^9[nxn-food]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Food.Error(msg)
    print(('^9[nxn-food]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
