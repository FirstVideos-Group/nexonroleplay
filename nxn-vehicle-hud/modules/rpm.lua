-- ============================================================
--  nxn-vehicle-hud | modules/rpm.lua
--  Motorfordulat (0.0 - 1.0 skala, GTA nativ)
-- ============================================================

CreateThread(function()
    local lastRpm = -1

    while true do
        Wait(Config.PollInterval)

        if not NXN.VehHUD.State.GetInVehicle()            then goto continue end
        if not NXN.VehHUD.State.GetModuleStates()['rpm']  then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local rpm = math.floor(GetVehicleCurrentRpm(veh) * 100)

        if rpm ~= lastRpm then
            lastRpm = rpm
            NXN.VehHUD.Log(('rpm: %d%%'):format(rpm))
            SendNUIMessage({
                action = 'updateModule',
                module = 'rpm',
                value  = rpm,
            })
        end

        ::continue::
    end
end)
