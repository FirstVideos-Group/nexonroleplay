-- ============================================================
--  nxn-hud | shared.lua
-- ============================================================

NXN      = NXN or {}
NXN.HUD  = NXN.HUD or {}

--- Debug log
---@param msg string
function NXN.HUD.Log(msg)
    if Config.Debug then
        print(('^9[nxn-hud]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.HUD.Info(msg)
    print(('^9[nxn-hud]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.HUD.Warn(msg)
    print(('^9[nxn-hud]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

--- Error log
---@param msg string
function NXN.HUD.Error(msg)
    print(('^9[nxn-hud]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
