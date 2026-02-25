-- ============================================================
--  nxn-location-hud | modules/playerstatus.lua
--  Jatekos statusz (gyalog, auto, fut, uszo, ejtoernyo)
--  FIX: repulo osztaly (15=boat, 16=plane) duplikat javitva
-- ============================================================

CreateThread(function()
    local lastStatus = ''

    while true do
        Wait(Config.StatusPollInterval)

        if not hudVisible then goto continue end
        if not moduleStates['playerstatus'] then goto continue end

        local ped    = PlayerPedId()
        local status

        if IsPedInAnyVehicle(ped, false) then
            local veh      = GetVehiclePedIsIn(ped, false)
            local vehClass = GetVehicleClass(veh)
            -- GTA jarmű osztalyok:
            -- 8  = motorcycle, 13 = cycle (bicikli), 14 = boat,
            -- 15 = helicopter, 16 = plane, 17 = blimp
            if vehClass == 8 then
                status = 'on_bike'
            elseif vehClass == 14 then
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
