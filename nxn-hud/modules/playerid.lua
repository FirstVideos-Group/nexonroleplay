-- ============================================================
--  nxn-hud | modules/playerid.lua
--  Jatekos szerver-ID megjelenitese
--  #29: Kozvetlenul SendNUIMessage, hogy hudVisible allapottol
--       fuggetlenul megkapja a NUI spawn-kor
-- ============================================================

AddEventHandler('playerSpawned', function()
    if not NXN.HUD.moduleStates['playerid'] then return end
    local id = GetPlayerServerId(PlayerId())
    NXN.HUD.Log(('playerid: %d'):format(id))
    -- Kozvetlenul kuldunk (nem NXN.HUD.Send), hogy hudVisible=false eseten is megkapja
    SendNUIMessage({ action = 'updateModuleData', module = 'playerid', id = id })
end)
