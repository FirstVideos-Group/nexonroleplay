-- ============================================================
--  nxn-hotwire | shared.lua
-- ============================================================

NXN          = NXN          or {}
NXN.Hotwire  = NXN.Hotwire  or {}

function NXN.Hotwire.Log(msg)
    if Config.Debug then
        print(('^9[nxn-hotwire]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

function NXN.Hotwire.Info(msg)
    print(('^9[nxn-hotwire]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

function NXN.Hotwire.Warn(msg)
    print(('^9[nxn-hotwire]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

function NXN.Hotwire.Error(msg)
    print(('^9[nxn-hotwire]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

function NXN.Hotwire.NormalizePlate(plate)
    if type(plate) ~= 'string' then return '' end
    return plate:upper():gsub('%s+', ' '):match('^%s*(.-)%s*$')
end
