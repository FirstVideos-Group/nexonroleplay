-- ============================================================
--  nxn-shop | shared.lua
-- ============================================================

NXN = NXN or {}
NXN.Shop = {}

---@param msg string
function NXN.Shop.Log(msg)
    if Config.Debug then
        print(('^9[nxn-shop]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Shop.Info(msg)
    print(('^9[nxn-shop]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Shop.Warn(msg)
    print(('^9[nxn-shop]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Shop.Error(msg)
    print(('^9[nxn-shop]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
