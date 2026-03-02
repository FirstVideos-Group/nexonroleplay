-- ============================================================
--  nxn-cartheft | shared.lua
-- ============================================================

NXN            = NXN            or {}
NXN.CarTheft   = NXN.CarTheft   or {}

function NXN.CarTheft.Log(msg)
    if Config.Debug then
        print(('^9[nxn-cartheft]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

function NXN.CarTheft.Info(msg)
    print(('^9[nxn-cartheft]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

function NXN.CarTheft.Warn(msg)
    print(('^9[nxn-cartheft]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

function NXN.CarTheft.Error(msg)
    print(('^9[nxn-cartheft]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

function NXN.CarTheft.NormalizePlate(plate)
    if type(plate) ~= 'string' then return '' end
    return plate:upper():gsub('%s+', ' '):match('^%s*(.-)%s*$')
end
