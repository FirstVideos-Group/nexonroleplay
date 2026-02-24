-- ============================================================
--  nxn-identity | shared.lua
-- ============================================================

NXN          = NXN or {}
NXN.Identity = NXN.Identity or {}

---@param msg string
function NXN.Identity.Log(msg)
    if Config.Debug then
        print(('[nxn-identity] [DEBUG] %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Identity.Info(msg)
    print(('[nxn-identity] [INFO] %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Identity.Warn(msg)
    print(('[nxn-identity] [WARN] %s'):format(tostring(msg)))
end
