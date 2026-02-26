-- ============================================================
--  nxn-licenses | shared.lua
-- ============================================================

NXN = NXN or {}
NXN.Licenses = {}

function NXN.Licenses.Log(msg)
    if Config and Config.Debug then
        print(('^9[nxn-licenses]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

function NXN.Licenses.Info(msg)
    print(('^9[nxn-licenses]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

function NXN.Licenses.Warn(msg)
    print(('^9[nxn-licenses]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

function NXN.Licenses.Error(msg)
    print(('^9[nxn-licenses]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Igazolvány típus definìió visszaadása id alapján
---@param typeId string
---@return table|nil
function NXN.Licenses.GetTypeDef(typeId)
    for _, def in ipairs(Config.LicenseTypes) do
        if def.id == typeId then return def end
    end
    return nil
end

--- Timestamp string a jelenlegi időből
---@return string  'YYYY-MM-DD HH:MM:SS'
function NXN.Licenses.NowStr()
    return os.date('!%Y-%m-%d %H:%M:%S')
end

--- Lejarat string számítása validDays alapján
---@param validDays number
---@return string|nil
function NXN.Licenses.ExpiresStr(validDays)
    if not validDays or validDays == 0 then return nil end
    local future = os.time() + (validDays * 86400)
    return os.date('!%Y-%m-%d %H:%M:%S', future)
end

--- Ellenőrzi, hogy egy igazolvány lejart-e (issued_at + validDays)
---@param row table   adatbázis sor (expires_at mezővel)
---@return boolean
function NXN.Licenses.IsExpired(row)
    if not row or not row.expires_at then return false end
    local y,mo,d,h,mi,s = row.expires_at:match('(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)')
    if not y then return false end
    local t = os.time({
        year=tonumber(y), month=tonumber(mo), day=tonumber(d),
        hour=tonumber(h), min=tonumber(mi),   sec=tonumber(s)
    })
    return os.time() > t
end

--- Megfelelő státusz string
---@param row table
---@return string  'active' | 'expired' | 'pending'
function NXN.Licenses.GetStatus(row)
    if not row then return 'none' end
    if NXN.Licenses.IsExpired(row) then return 'expired' end
    return 'active'
end
