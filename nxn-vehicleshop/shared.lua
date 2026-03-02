-- ============================================================
--  nxn-vehicleshop | shared.lua
-- ============================================================

NXN = NXN or {}
NXN.VehicleShop = {}

---@param msg string
function NXN.VehicleShop.Log(msg)
    if Config.Debug then
        print(('^9[nxn-vehicleshop]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.VehicleShop.Info(msg)
    print(('^9[nxn-vehicleshop]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.VehicleShop.Warn(msg)
    print(('^9[nxn-vehicleshop]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.VehicleShop.Error(msg)
    print(('^9[nxn-vehicleshop]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Táblában van-e az érték
---@param tbl table
---@param val any
---@return boolean
function NXN.VehicleShop.TableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end
