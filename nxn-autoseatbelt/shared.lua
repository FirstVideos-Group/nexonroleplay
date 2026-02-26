-- ============================================================
--  nxn-autoseatbelt | shared.lua
-- ============================================================

NXN              = NXN or {}
NXN.AutoSeatbelt = NXN.AutoSeatbelt or {}

---@param msg string
function NXN.AutoSeatbelt.Log(msg)
    if Config.Debug then
        print(('^9[nxn-autoseatbelt]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.AutoSeatbelt.Info(msg)
    print(('^9[nxn-autoseatbelt]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.AutoSeatbelt.Warn(msg)
    print(('^9[nxn-autoseatbelt]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.AutoSeatbelt.Error(msg)
    print(('^9[nxn-autoseatbelt]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
