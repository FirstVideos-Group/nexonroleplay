-- ============================================================
--  nxn-keys | shared.lua
-- ============================================================

NXN       = NXN       or {}
NXN.Keys  = NXN.Keys  or {}

---@param msg string
function NXN.Keys.Log(msg)
    if Config.Debug then
        print(('^9[nxn-keys]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Keys.Info(msg)
    print(('^9[nxn-keys]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Keys.Warn(msg)
    print(('^9[nxn-keys]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Keys.Error(msg)
    print(('^9[nxn-keys]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Rendszám normalizálás (nagybetu, trim)
---@param plate string
---@return string
function NXN.Keys.NormalizePlate(plate)
    if type(plate) ~= 'string' then return '' end
    return plate:upper():gsub('%s+', ' '):match('^%s*(.-)%s*$')
end
