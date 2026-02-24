-- ============================================================
--  nxn-location-hud | modules/street.lua
--  Utca neve (legkozelebbi ut) – periodikusan lekerdezve
-- ============================================================

CreateThread(function()
    local lastStreet  = ''
    local lastCross   = ''

    while true do
        Wait(Config.PollInterval)
        if not hudVisible then goto continue end
        if not moduleStates['street'] then goto continue end

        local ped = PlayerPedId()
        local x, y, z = table.unpack(GetEntityCoords(ped))

        local streetHash, crossHash = GetStreetNameAtCoord(x, y, z)
        local streetName = GetStreetNameFromHashKey(streetHash)
        local crossName  = GetStreetNameFromHashKey(crossHash)

        if streetName == nil then streetName = '' end
        if crossName  == nil then crossName  = '' end

        if streetName ~= lastStreet or crossName ~= lastCross then
            lastStreet = streetName
            lastCross  = crossName
            NXN.LocHUD.Log(('street: %s / %s'):format(streetName, crossName))
            NXN.LocHUD.Send('updateModule', {
                module = 'street',
                name   = streetName,
                cross  = crossName,
            })
        end

        ::continue::
    end
end)
