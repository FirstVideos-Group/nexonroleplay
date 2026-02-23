-- ============================================================
--  nxn-hud | shared.lua
-- ============================================================

NXN      = NXN or {}
NXN.HUD  = NXN.HUD or {}

--- Debug log
---@param msg string
function NXN.HUD.Log(msg)
    if Config.Debug then
        print(('[nxn-hud] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.HUD.Info(msg)
    print(('[nxn-hud] [INFO] %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.HUD.Warn(msg)
    print(('[nxn-hud] [WARN] %s'):format(tostring(msg)))
end
