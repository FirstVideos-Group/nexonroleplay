-- ============================================================
--  nxn-vehicle-hud | modules/rpm.lua
--  Motorfordulat (0.0 - 1.0 skala, GTA nativ)
-- ============================================================

CreateThread(function()
    local lastRpm = -1

    while true do
        Wait(Config.PollInterval)
        if not hudVisible or not inVehicle then goto continue end
        if not moduleStates['rpm'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        -- GetVehicleCurrentRpm: 0.0 - 1.0
        local rpm = math.floor(GetVehicleCurrentRpm(veh) * 100)

        if rpm ~= lastRpm then
            lastRpm = rpm
            NXN.VehHUD.Log(('rpm: %d%%'):format(rpm))
            NXN.VehHUD.Send('updateModule', {
                module = 'rpm',
                value  = rpm,   -- 0-100 szazalek
            })
        end

        ::continue::
    end
end)
