-- ============================================================
--  nxn-needs | shared.lua
--  Közös segédfüggvények és namespace
-- ============================================================

NXN        = NXN or {}
NXN.Needs  = NXN.Needs or {}

--- Debug log – csak akkor ír, ha Config.Debug = true
---@param msg string
function NXN.Needs.Log(msg)
    if Config.Debug then
        print(('[nxn-needs] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Info log – mindig megjelenik
---@param msg string
function NXN.Needs.Info(msg)
    print(('[nxn-needs] [INFO] %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.Needs.Warn(msg)
    print(('[nxn-needs] [WARN] %s'):format(tostring(msg)))
end

--- Error log
---@param msg string
function NXN.Needs.Error(msg)
    print(('[nxn-needs] [ERROR] %s'):format(tostring(msg)))
end

--- Értéket clamp-el min és max közé
---@param val number
---@param min number
---@param max number
---@return number
function NXN.Needs.Clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end
