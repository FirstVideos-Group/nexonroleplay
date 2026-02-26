-- ============================================================
--  nxn-antiwanted | shared.lua
-- ============================================================

NXN = NXN or {}
NXN.AntiWanted = {}

--- Debug log – csak akkor ír, ha Config.Debug = true
---@param msg string
function NXN.AntiWanted.Log(msg)
    if Config and Config.Debug then
        print(('^9[nxn-antiwanted]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.AntiWanted.Info(msg)
    print(('^9[nxn-antiwanted]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.AntiWanted.Warn(msg)
    print(('^9[nxn-antiwanted]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.AntiWanted.Error(msg)
    print(('^9[nxn-antiwanted]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
