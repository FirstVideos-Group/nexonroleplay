-- ============================================================
--  nxn-garage | shared.lua
-- ============================================================

NXN        = NXN or {}
NXN.Garage = {}

---@param msg string
function NXN.Garage.Log(msg)
    if Config.Debug then
        print(('^9[nxn-garage]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Garage.Info(msg)
    print(('^9[nxn-garage]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Garage.Warn(msg)
    print(('^9[nxn-garage]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Garage.Error(msg)
    print(('^9[nxn-garage]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Rendszám normalizálás (trim + uppercase + max 8 kar)
---@param plate string
---@return string
function NXN.Garage.NormalizePlate(plate)
    if type(plate) ~= 'string' then return '' end
    local p = plate:match('^%s*(.-)%s*$'):upper()
    if #p > 8 then p = p:sub(1, 8) end
    return p
end
