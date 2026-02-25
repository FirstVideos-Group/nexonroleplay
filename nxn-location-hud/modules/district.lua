-- ============================================================
--  nxn-location-hud | modules/district.lua
--  Korzet neve (GTA zona) – periodikusan lekerdezve
--  FIX: helyes zona label lekerese, GetLabelText fallback javitva
-- ============================================================

CreateThread(function()
    local lastDistrict = ''

    while true do
        Wait(Config.PollInterval)

        if not hudVisible then goto continue end
        if not moduleStates['district'] then goto continue end

        local ped = PlayerPedId()
        local x, y, z = table.unpack(GetEntityCoords(ped))

        -- GetNameOfZone: short zona nev (pl. 'AIRP', 'DTOWN')
        -- GetLabelText: a jatekon beluli lokalizalt neve (pl. 'Los Santos International Airport')
        local zoneKey  = GetNameOfZone(x, y, z)
        local zoneName = GetLabelText(zoneKey)

        -- Ha a GetLabelText nem talal ertelmes erteket, a nyers kulcsot adjuk vissza
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
