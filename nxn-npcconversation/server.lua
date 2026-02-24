-- ============================================================
--  nxn-npcconversation | server.lua
--  Szerver oldali esemenyforwardolas
-- ============================================================

NXN     = NXN or {}
NXN.NPC = NXN.NPC or {}

function NXN.NPC.Log(msg)
    if Config.Debug then
        print(('[nxn-npcconversation] [DEBUG] %s'):format(tostring(msg)))
    end
end

-- Ha egy NPC opcio szerver eventet var, ide lehet forward-olni
-- Pelda:
-- RegisterNetEvent('nxn-npcconversation:server:dialogueAction')
-- AddEventHandler('nxn-npcconversation:server:dialogueAction', function(npcId, optionId)
--     NXN.NPC.Log(('dialogueAction: src=%d npc=%s opt=%s'):format(source, npcId, optionId))
--     -- sajat logika ide
-- end)
