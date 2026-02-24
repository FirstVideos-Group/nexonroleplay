-- ============================================================
--  nxn-location-hud | modules/district.lua
--  Korzetnek neve (GTA zona) – periodikusan lekerdezve
-- ============================================================

CreateThread(function()
    local lastDistrict = ''

    while true do
        Wait(Config.PollInterval)
        if not hudVisible then goto continue end
        if not moduleStates['district'] then goto continue end

        local ped = PlayerPedId()
        local x, y, z = table.unpack(GetEntityCoords(ped))

        -- GTA zona hash -> label
        local zoneHash  = GetHashOfMapAreaAtCoords(x, y, z)
        local zoneName  = GetLabelText(GetNameOfZone(x, y, z))

        if zoneName == 'NULL' or zoneName == '' then
            zoneName = GetNameOfZone(x, y, z)
        end

        if zoneName ~= lastDistrict then
            lastDistrict = zoneName
            NXN.LocHUD.Log(('district: %s'):format(zoneName))
            NXN.LocHUD.Send('updateModule', {
                module = 'district',
                name   = zoneName,
            })
        end

        ::continue::
    end
end)
