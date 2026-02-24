-- ============================================================
--  nxn-autoseatbelt | shared.lua
-- ============================================================

NXN              = NXN or {}
NXN.AutoSeatbelt = NXN.AutoSeatbelt or {}

---@param msg string
function NXN.AutoSeatbelt.Log(msg)
    if Config.Debug then
        print(('[nxn-autoseatbelt] [DEBUG] %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.AutoSeatbelt.Info(msg)
    print(('[nxn-autoseatbelt] [INFO] %s'):format(tostring(msg)))
end

---@param msg string
function NXN.AutoSeatbelt.Warn(msg)
    print(('[nxn-autoseatbelt] [WARN] %s'):format(tostring(msg)))
end
