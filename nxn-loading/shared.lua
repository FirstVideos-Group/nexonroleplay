-- ============================================================
--  nxn-loading | shared.lua
--  Közös segédfüggvények (client + server)
-- ============================================================

NXN         = NXN or {}
NXN.Loading = {}

--- Debug log – csak akkor ír, ha Config.Debug = true
---@param msg string
function NXN.Loading.Log(msg)
    if Config.Debug then
        print(('[nxn-loading] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Tábla hosszának lekérése (mixed keys esetén is)
---@param tbl table
---@return integer
function NXN.Loading.TableLen(tbl)
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n
end
