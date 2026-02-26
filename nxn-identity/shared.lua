-- ============================================================
--  nxn-identity | shared.lua
-- ============================================================

NXN          = NXN or {}
NXN.Identity = NXN.Identity or {}

---@param msg string
function NXN.Identity.Log(msg)
    if Config.Debug then
        print(('^9[nxn-identity]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Identity.Info(msg)
    print(('^9[nxn-identity]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Identity.Warn(msg)
    print(('^9[nxn-identity]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Identity.Error(msg)
    print(('^9[nxn-identity]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
