-- ============================================================
--  nxn-vehicle-hud | modules/gear.lua
--  Fokozat (0 = N/R, 1-8 = sebessegfokozatok)
-- ============================================================

CreateThread(function()
    local lastGear = -1

    while true do
        Wait(Config.PollInterval)
        if not hudVisible or not inVehicle then goto continue end
        if not moduleStates['gear'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local gear    = GetVehicleCurrentGear(veh)
        local reverse = GetVehicleTransmissionMode(veh) == 1 -- hatra

        if gear ~= lastGear then
            lastGear = gear
            NXN.VehHUD.Log(('gear: %d reverse=%s'):format(gear, tostring(reverse)))
            NXN.VehHUD.Send('updateModule', {
                module  = 'gear',
                gear    = gear,
                reverse = reverse,
            })
        end

        ::continue::
    end
end)
