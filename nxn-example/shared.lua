-- ============================================================
--  nxn-example | shared.lua
--  Közös segédfüggvények és adatok (client + server egyaránt)
-- ============================================================

NXN = NXN or {}
NXN.Example = {}

--- Debug log – csak akkor ír, ha Config.Debug = true
---@param msg string
function NXN.Example.Log(msg)
    if Config.Debug then
        print(('^9[nxn-example]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Example.Info(msg)
    print(('^9[nxn-example]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Example.Warn(msg)
    print(('^9[nxn-example]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Example.Error(msg)
    print(('^9[nxn-example]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Tábla tartalmaz-e értéket?
---@param tbl table
---@param val any
---@return boolean
function NXN.Example.TableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end
