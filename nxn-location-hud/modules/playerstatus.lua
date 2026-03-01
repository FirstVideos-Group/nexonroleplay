-- ============================================================
--  nxn-location-hud | modules/playerstatus.lua
--  Jatekos statusz (gyalog, auto, fut, uszo, ejtoernyo)
-- ============================================================

CreateThread(function()
    local lastStatus = ''

    while true do
        Wait(Config.StatusPollInterval)

        -- #63/#67: NXN.LocHUD nevter, == true nil-safe ellenorzés
        if NXN.LocHUD.hudVisible ~= true then goto continue end
        if NXN.LocHUD.moduleStates['playerstatus'] ~= true then goto continue end

        local ped    = PlayerPedId()
        local status

        if IsPedInAnyVehicle(ped, false) then
            local veh      = GetVehiclePedIsIn(ped, false)
            local vehClass = GetVehicleClass(veh)
            -- GTA5 jarmű osztalyok:
            -- 8=Motorcycle, 13=Cycle (bicikli), 14=Boat,
            -- 15=Helicopter, 16=Plane, 17=Blimp
            if vehClass == 8 then
                status = 'on_bike'
            elseif vehClass == 13 then   -- #68: bicikli hozzaadva
                status = 'on_bicycle'
            elseif vehClass == 14 then   -- #68: hajo explicit ag (korabban hianyzott)
                status = 'on_boat'
            elseif vehClass == 15 then
                status = 'in_helicopter'
            elseif vehClass == 16 or vehClass == 17 then
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
            SendNUIMessage({
                action = 'updateModule',
                module = 'playerstatus',
                status = status,
            })
        end

        ::continue::
    end
end)
