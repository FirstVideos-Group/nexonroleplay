-- ============================================================
--  nxn-signs | shared.lua
-- ============================================================

NXN       = NXN or {}
NXN.Signs = NXN.Signs or {}

---@param msg string
function NXN.Signs.Log(msg)
    if Config.Debug then
        print(('^9[nxn-signs]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Signs.Info(msg)
    print(('^9[nxn-signs]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Signs.Warn(msg)
    print(('^9[nxn-signs]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Signs.Error(msg)
    print(('^9[nxn-signs]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
