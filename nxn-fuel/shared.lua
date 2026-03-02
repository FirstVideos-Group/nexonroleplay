-- ============================================================
--  nxn-fuel | shared.lua
-- ============================================================

NXN       = NXN       or {}
NXN.Fuel  = NXN.Fuel  or {}

function NXN.Fuel.Log(msg)
    if Config.Debug then
        print(('^9[nxn-fuel]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

function NXN.Fuel.Info(msg)
    print(('^9[nxn-fuel]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

function NXN.Fuel.Warn(msg)
    print(('^9[nxn-fuel]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

function NXN.Fuel.Error(msg)
    print(('^9[nxn-fuel]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Rendszám normalizálás
function NXN.Fuel.NormalizePlate(plate)
    if type(plate) ~= 'string' then return '' end
    return plate:upper():gsub('%s+', ' '):match('^%s*(.-)%s*$')
end

--- Clamp
function NXN.Fuel.Clamp(val, min, max)
    return math.max(min, math.min(max, val))
end
