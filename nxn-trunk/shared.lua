-- ============================================================
--  nxn-trunk | shared.lua
-- ============================================================

NXN       = NXN or {}
NXN.Trunk = {}

---@param msg string
function NXN.Trunk.Log(msg)
    if Config.Debug then
        print(('^9[nxn-trunk]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Trunk.Info(msg)
    print(('^9[nxn-trunk]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Trunk.Warn(msg)
    print(('^9[nxn-trunk]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Trunk.Error(msg)
    print(('^9[nxn-trunk]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Rendszám normalizálás: trim + uppercase + max 8 karakter
---@param plate string
---@return string
function NXN.Trunk.NormalizePlate(plate)
    if type(plate) ~= 'string' then return '' end
    local p = plate:match('^%s*(.-)%s*$'):upper()
    if #p > 8 then p = p:sub(1, 8) end
    return p
end

--- Súly kalkulació trunk items táblából
---@param items table  [{ name, count, weight }, ...]
---@return number
function NXN.Trunk.CalcWeight(items)
    local total = 0.0
    if type(items) ~= 'table' then return total end
    for _, item in ipairs(items) do
        total = total + ((item.weight or 0) * (item.count or 1))
    end
    return total
end
