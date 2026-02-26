-- ============================================================
--  nxn-npcconversation | shared.lua
-- ============================================================

NXN     = NXN or {}
NXN.NPC = NXN.NPC or {}

--- Debug log
---@param msg string
function NXN.NPC.Log(msg)
    if Config.Debug then
        print(('^9[nxn-npcconversation]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.NPC.Info(msg)
    print(('^9[nxn-npcconversation]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.NPC.Warn(msg)
    print(('^9[nxn-npcconversation]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

--- Error log
---@param msg string
function NXN.NPC.Error(msg)
    print(('^9[nxn-npcconversation]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end
