-- ============================================================
--  nxn-signs | shared.lua
-- ============================================================

NXN       = NXN or {}
NXN.Signs = NXN.Signs or {}

---@param msg string
function NXN.Signs.Log(msg)
    if Config.Debug then
        print(('[nxn-signs] [DEBUG] %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Signs.Info(msg)
    print(('[nxn-signs] [INFO] %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Signs.Warn(msg)
    print(('[nxn-signs] [WARN] %s'):format(tostring(msg)))
end
