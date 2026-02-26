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
        print(('^9[nxn-loading]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Loading.Info(msg)
    print(('^9[nxn-loading]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Loading.Warn(msg)
    print(('^9[nxn-loading]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Loading.Error(msg)
    print(('^9[nxn-loading]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Tábla hosszának lekérése (mixed keys esetén is)
---@param tbl table
---@return integer
function NXN.Loading.TableLen(tbl)
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n
end
