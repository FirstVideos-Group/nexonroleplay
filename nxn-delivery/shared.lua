-- ============================================================
--  nxn-delivery | shared.lua
--  Közös segédfüggvények és névtér
-- ============================================================

NXN = NXN or {}
NXN.Delivery = {}

---@param msg string
function NXN.Delivery.Log(msg)
    if Config.Debug then
        print(('^9[nxn-delivery]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Delivery.Info(msg)
    print(('^9[nxn-delivery]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Delivery.Warn(msg)
    print(('^9[nxn-delivery]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Delivery.Error(msg)
    print(('^9[nxn-delivery]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- 3D távolság két koordináta között méterben
---@param a vector3
---@param b vector3
---@return number
function NXN.Delivery.Distance(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

--- Másodpercből MM:SS formátum
---@param seconds number
---@return string
function NXN.Delivery.FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return ('%02d:%02d'):format(m, s)
end
