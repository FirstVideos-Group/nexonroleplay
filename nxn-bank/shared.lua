-- ============================================================
--  nxn-bank | shared.lua
--  Közös segédfüggvények és namespace
-- ============================================================

NXN       = NXN or {}
NXN.Bank  = {}

---@param msg string
function NXN.Bank.Log(msg)
    if Config.Debug then
        print(('^9[nxn-bank]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Bank.Info(msg)
    print(('^9[nxn-bank]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Bank.Warn(msg)
    print(('^9[nxn-bank]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Bank.Error(msg)
    print(('^9[nxn-bank]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
