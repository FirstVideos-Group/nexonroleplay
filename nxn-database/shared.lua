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
        print(('[nxn-database] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Info log – mindig megjelenik
---@param msg string
function NXN.DB.Info(msg)
    print(('[nxn-database] [INFO] %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.DB.Warn(msg)
    print(('[nxn-database] [WARN] %s'):format(tostring(msg)))
end

--- Error log
---@param msg string
function NXN.DB.Error(msg)
    print(('[nxn-database] [ERROR] %s'):format(tostring(msg)))
end
