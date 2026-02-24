-- ============================================================
--  nxn-npcconversation | shared.lua
-- ============================================================

NXN     = NXN or {}
NXN.NPC = NXN.NPC or {}

--- Debug log
---@param msg string
function NXN.NPC.Log(msg)
    if Config.Debug then
        print(('[nxn-npcconversation] [DEBUG] %s'):format(tostring(msg)))
    end
end

--- Info log
---@param msg string
function NXN.NPC.Info(msg)
    print(('[nxn-npcconversation] [INFO] %s'):format(tostring(msg)))
end

--- Warn log
---@param msg string
function NXN.NPC.Warn(msg)
    print(('[nxn-npcconversation] [WARN] %s'):format(tostring(msg)))
end
