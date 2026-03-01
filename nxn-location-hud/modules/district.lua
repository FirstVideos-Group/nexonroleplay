-- ============================================================
--  nxn-location-hud | modules/district.lua
--  Korzet neve (GTA zona) – periodikusan lekerdezve
-- ============================================================

CreateThread(function()
    local lastDistrict = ''

    while true do
        Wait(Config.PollInterval)

        -- #63/#67: NXN.LocHUD nevter, == true nil-safe ellenorzés
        if NXN.LocHUD.hudVisible ~= true then goto continue end
        if NXN.LocHUD.moduleStates['district'] ~= true then goto continue end

        local ped = PlayerPedId()
        local x, y, z = table.unpack(GetEntityCoords(ped))

        local zoneKey  = GetNameOfZone(x, y, z)
        local zoneName = GetLabelText(zoneKey)

        if not zoneName or zoneName == 'NULL' or zoneName == '' then
            zoneName = zoneKey or 'Ismeretlen'
        end

        if zoneName ~= lastDistrict then
            lastDistrict = zoneName
            NXN.LocHUD.Log(('district: %s (key=%s)'):format(zoneName, tostring(zoneKey)))
            SendNUIMessage({
                action = 'updateModule',
                module = 'district',
                name   = zoneName,
            })
        end

        ::continue::
    end
end)
