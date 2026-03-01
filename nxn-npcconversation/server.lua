-- ============================================================
--  nxn-npcconversation | server.lua
--  Szerver oldali esemenyforwardolas
-- ============================================================

-- #84: NXN.NPC.Log / Info / Warn / Error ujradefinicio ELTAVOLITVA
-- A shared.lua (mindket oldalon betoltodik) mar definialta ezeket
-- helyes formatumban. A server.lua felulirasai megakadalyoztak, hogy
-- NXN.NPC.Warn es NXN.NPC.Error szerver oldalon mukodjenek.

-- Ha egy NPC opcio szerver eventet var, ide lehet forward-olni
-- Pelda:
-- RegisterNetEvent('nxn-npcconversation:server:dialogueAction')
-- AddEventHandler('nxn-npcconversation:server:dialogueAction', function(npcId, optionId)
--     NXN.NPC.Log(('dialogueAction: src=%d npc=%s opt=%s'):format(source, npcId, optionId))
--     -- sajat logika ide
-- end)
