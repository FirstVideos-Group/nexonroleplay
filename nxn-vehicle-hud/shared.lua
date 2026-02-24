-- ============================================================
--  nxn-vehicle-hud | shared.lua
-- ============================================================

NXN         = NXN or {}
NXN.VehHUD  = NXN.VehHUD or {}

--- Debug log
---@param msg string
function NXN.VehHUD.Log(msg)
    if Config.Debug then
        print(('[nxn-vehicle-hud] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.VehHUD.Info(msg)
    print(('[nxn-vehicle-hud] [INFO] %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.VehHUD.Warn(msg)
    print(('[nxn-vehicle-hud] [WARN] %s'):format(tostring(msg)))
end
