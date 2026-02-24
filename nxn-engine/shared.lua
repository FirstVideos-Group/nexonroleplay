-- ============================================================
--  nxn-engine | shared.lua
-- ============================================================

NXN        = NXN or {}
NXN.Engine = NXN.Engine or {}

---@param msg string
function NXN.Engine.Log(msg)
    if Config.Debug then
        print(('[nxn-engine] [DEBUG] %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Engine.Info(msg)
    print(('[nxn-engine] [INFO] %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Engine.Warn(msg)
    print(('[nxn-engine] [WARN] %s'):format(tostring(msg)))
end
