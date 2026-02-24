-- ============================================================
--  nxn-location-hud | modules/playerstatus.lua
--  Jatekos statusz (gyalog, auto, fut, uszo, ejtoernyo)
--  Periodikusan lekerdezi a GTA nativ allapotokat.
-- ============================================================

CreateThread(function()
    local lastStatus = ''

    while true do
        Wait(Config.StatusPollInterval)
        if not hudVisible then goto continue end
        if not moduleStates['playerstatus'] then goto continue end

        local ped    = PlayerPedId()
        local player = PlayerId()
        local status

        if IsPedInAnyVehicle(ped, false) then
            local veh     = GetVehiclePedIsIn(ped, false)
            local vehClass = GetVehicleClass(veh)
            if vehClass == 14 then
                status = 'on_bike'
            elseif vehClass == 15 or vehClass == 16 then
                status = 'on_boat'
            elseif vehClass == 13 then
                status = 'in_helicopter'
            elseif vehClass == 15 then
                status = 'in_plane'
            else
                status = 'in_vehicle'
            end
        elseif IsPedSwimmingUnderWater(ped) then
            status = 'diving'
        elseif IsPedSwimming(ped) then
            status = 'swimming'
        elseif GetPedParachuteState(ped) == 2 then
            status = 'parachuting'
        elseif IsPedSprinting(ped) then
            status = 'running'
        elseif IsPedWalking(ped) then
            status = 'walking'
        else
            status = 'on_foot'
        end

        if status ~= lastStatus then
            lastStatus = status
            NXN.LocHUD.Log(('playerstatus: %s'):format(status))
            NXN.LocHUD.Send('updateModule', { module = 'playerstatus', status = status })
        end

        ::continue::
    end
end)
