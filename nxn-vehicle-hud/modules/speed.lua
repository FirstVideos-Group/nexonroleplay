-- ============================================================
--  nxn-vehicle-hud | modules/speed.lua
--  Sebesseg megjelenitese (km/h vagy mph)
-- ============================================================

CreateThread(function()
    local lastSpeed = -1

    while true do
        Wait(Config.PollInterval)
        if not hudVisible or not inVehicle then goto continue end
        if not moduleStates['speed'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local speedMs = GetEntitySpeed(veh)
        local speed
        if Config.SpeedUnit == 'mph' then
            speed = math.floor(speedMs * 2.23694)
        else
            speed = math.floor(speedMs * 3.6)
        end

        if speed ~= lastSpeed then
            lastSpeed = speed
            NXN.VehHUD.Log(('speed: %d %s'):format(speed, Config.SpeedUnit))
            NXN.VehHUD.Send('updateModule', {
                module = 'speed',
                value  = speed,
                unit   = Config.SpeedUnit,
            })
        end

        ::continue::
    end
end)
