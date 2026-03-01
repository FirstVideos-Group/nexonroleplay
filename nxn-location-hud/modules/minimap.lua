-- ============================================================
--  nxn-location-hud | modules/minimap.lua
--  Koordinata kijelzo a minimap panel ala
-- ============================================================

if not Config.ShowMinimap then
    NXN.LocHUD.Log('minimap modul: ShowMinimap=false, kihagyva')
    return
end

CreateThread(function()
    local lastCoordStr = ''

    while true do
        Wait(Config.PollInterval * 2)

        -- #63/#67: NXN.LocHUD nevter, == true nil-safe ellenorzés
        if NXN.LocHUD.hudVisible ~= true then goto continue end
        if NXN.LocHUD.moduleStates['minimap'] ~= true then goto continue end

        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local coordStr = ('%d / %d'):format(math.floor(coords.x), math.floor(coords.y))

        if coordStr ~= lastCoordStr then
            lastCoordStr = coordStr
            NXN.LocHUD.Log(('minimap coords: %s'):format(coordStr))
            SendNUIMessage({
                action = 'updateModule',
                module = 'minimap',
                coords = coordStr,
            })
        end

        ::continue::
    end
end)
