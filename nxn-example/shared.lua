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
        print(('[nxn-example] [DEBUG] %s'):format(tostring(msg)))
    end
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