-- ============================================================
--  nxn-minimap | shared.lua
-- ============================================================

NXN         = NXN or {}
NXN.Minimap = NXN.Minimap or {}

--- Debug log
---@param msg string
function NXN.Minimap.Log(msg)
    if Config.Debug then
        print(('^9[nxn-minimap]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.Minimap.Info(msg)
    print(('^9[nxn-minimap]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.Minimap.Warn(msg)
    print(('^9[nxn-minimap]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

--- Error log
---@param msg string
function NXN.Minimap.Error(msg)
    print(('^9[nxn-minimap]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
