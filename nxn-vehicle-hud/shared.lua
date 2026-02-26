-- ============================================================
--  nxn-vehicle-hud | shared.lua
-- ============================================================

NXN         = NXN or {}
NXN.VehHUD  = NXN.VehHUD or {}

--- Debug log
---@param msg string
function NXN.VehHUD.Log(msg)
    if Config.Debug then
        print(('^9[nxn-vehicle-hud]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.VehHUD.Info(msg)
    print(('^9[nxn-vehicle-hud]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.VehHUD.Warn(msg)
    print(('^9[nxn-vehicle-hud]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

--- Error log
---@param msg string
function NXN.VehHUD.Error(msg)
    print(('^9[nxn-vehicle-hud]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
