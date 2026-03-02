-- ============================================================
--  nxn-gasstation | shared.lua
--  Közös segédfüggvények (client + server)
-- ============================================================

NXN = NXN or {}
NXN.Gas = {}

---@param msg string
function NXN.Gas.Log(msg)
    if Config.Debug then
        print(('^9[nxn-gasstation]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Gas.Info(msg)
    print(('^9[nxn-gasstation]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Gas.Warn(msg)
    print(('^9[nxn-gasstation]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Gas.Error(msg)
    print(('^9[nxn-gasstation]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Megadott pont távolsága egy vector3-tól
---@param a vector3
---@param b vector3
---@return number
function NXN.Gas.Distance(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end
