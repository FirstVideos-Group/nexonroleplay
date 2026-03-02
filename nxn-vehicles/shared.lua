-- ============================================================
--  nxn-vehicles | shared.lua
-- ============================================================

NXN          = NXN or {}
NXN.Vehicles = {}

---@param msg string
function NXN.Vehicles.Log(msg)
    if Config.Debug then
        print(('^9[nxn-vehicles]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Vehicles.Info(msg)
    print(('^9[nxn-vehicles]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Vehicles.Warn(msg)
    print(('^9[nxn-vehicles]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Vehicles.Error(msg)
    print(('^9[nxn-vehicles]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Rendszám normalizálás: trim + uppercase + max 8 karakter
---@param plate string
---@return string
function NXN.Vehicles.NormalizePlate(plate)
    if type(plate) ~= 'string' then return '' end
    local p = plate:match('^%s*(.-)%s*$'):upper()
    if #p > 8 then p = p:sub(1, 8) end
    return p
end
