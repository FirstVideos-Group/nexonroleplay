-- ============================================================
--  nxn-location-hud | shared.lua
-- ============================================================

NXN          = NXN or {}
NXN.LocHUD   = NXN.LocHUD or {}

--- Debug log
---@param msg string
function NXN.LocHUD.Log(msg)
    if Config.Debug then
        print(('[nxn-location-hud] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.LocHUD.Info(msg)
    print(('[nxn-location-hud] [INFO] %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.LocHUD.Warn(msg)
    print(('[nxn-location-hud] [WARN] %s'):format(tostring(msg)))
end
