-- ============================================================
--  nxn-database | shared.lua
--  Közös segédfüggvények és namespace
-- ============================================================

NXN         = NXN or {}
NXN.DB      = NXN.DB or {}

--- Debug log – csak akkor ír, ha Config.Debug = true
---@param msg string
function NXN.DB.Log(msg)
    if Config.Debug then
        print(('^9[nxn-database]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

--- Info log – mindig megjelenik
---@param msg string
function NXN.DB.Info(msg)
    print(('^9[nxn-database]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.DB.Warn(msg)
    print(('^9[nxn-database]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

--- Error log
---@param msg string
function NXN.DB.Error(msg)
    print(('^9[nxn-database]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
