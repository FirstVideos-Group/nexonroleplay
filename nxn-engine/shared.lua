-- ============================================================
--  nxn-engine | shared.lua
-- ============================================================

NXN        = NXN or {}
NXN.Engine = NXN.Engine or {}

---@param msg string
function NXN.Engine.Log(msg)
    if Config.Debug then
        print(('^9[nxn-engine]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Engine.Info(msg)
    print(('^9[nxn-engine]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Engine.Warn(msg)
    print(('^9[nxn-engine]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Engine.Error(msg)
    print(('^9[nxn-engine]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
