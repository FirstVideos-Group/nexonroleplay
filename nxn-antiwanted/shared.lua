-- ============================================================
--  nxn-antiwanted | shared.lua
-- ============================================================

NXN = NXN or {}
NXN.AntiWanted = {}

--- Debug log – csak akkor ír, ha Config.Debug = true
---@param msg string
function NXN.AntiWanted.Log(msg)
    if Config and Config.Debug then
        print(('[nxn-antiwanted] [DEBUG] %s'):format(tostring(msg)))
    end
end
