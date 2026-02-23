-- ============================================================
--  nxn-hud | modules/playerid.lua
--  Jatekos szerver-ID megjelenitese
-- ============================================================

AddEventHandler('playerSpawned', function()
    if not moduleStates['playerid'] then return end
    local id = GetPlayerServerId(PlayerId())
    NXN.HUD.Log(('playerid: %d'):format(id))
    NXN.HUD.Send('updateModuleData', { module = 'playerid', id = id })
end)
