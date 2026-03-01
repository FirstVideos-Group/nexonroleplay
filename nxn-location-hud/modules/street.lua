-- ============================================================
--  nxn-location-hud | modules/street.lua
--  Utca neve (legkozelebbi ut) – periodikusan lekerdezve
-- ============================================================

CreateThread(function()
    local lastStreet = ''
    local lastCross  = ''

    while true do
        Wait(Config.PollInterval)

        -- #63/#67: NXN.LocHUD nevter, == true nil-safe ellenorzés
        if NXN.LocHUD.hudVisible ~= true then goto continue end
        if NXN.LocHUD.moduleStates['street'] ~= true then goto continue end

        local ped = PlayerPedId()
        local x, y, z = table.unpack(GetEntityCoords(ped))

        local streetHash, crossHash = GetStreetNameAtCoord(x, y, z)
        local streetName = GetStreetNameFromHashKey(streetHash) or ''
        local crossName  = GetStreetNameFromHashKey(crossHash)  or ''

        if streetName ~= lastStreet or crossName ~= lastCross then
            lastStreet = streetName
            lastCross  = crossName
            NXN.LocHUD.Log(('street: %s / %s'):format(streetName, crossName))
            SendNUIMessage({
                action = 'updateModule',
                module = 'street',
                name   = streetName,
                cross  = crossName,
            })
        end

        ::continue::
    end
end)
