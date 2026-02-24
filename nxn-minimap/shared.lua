-- ============================================================
--  nxn-minimap | shared.lua
-- ============================================================

NXN         = NXN or {}
NXN.Minimap = NXN.Minimap or {}

--- Debug log
---@param msg string
function NXN.Minimap.Log(msg)
    if Config.Debug then
        print(('[nxn-minimap] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.Minimap.Info(msg)
    print(('[nxn-minimap] [INFO] %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.Minimap.Warn(msg)
    print(('[nxn-minimap] [WARN] %s'):format(tostring(msg)))
end
