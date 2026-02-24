-- ============================================================
--  nxn-vehicle-hud | modules/lights.lua
--  Lampa allapot: position lights, full beam, hazard
--  Csak akkor jelenik meg, ha valamelyik lampa be van kapcsolva.
-- ============================================================

local hideTimer = nil

CreateThread(function()
    local lastState = ''

    while true do
        Wait(Config.PollInterval * 2)  -- lampak ritkabban valtoznak
        if not hudVisible or not inVehicle then goto continue end
        if not moduleStates['lights'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local lightState = GetVehicleLightsState(veh)  -- [1]=position [2]=fullbeam
        local hasPosition, hasHighbeam = lightState, false
        -- GTA API: GetVehicleLightsState returns int bitmask
        -- bit 0 = position lights, bit 1 = full beam
        local pos   = (lightState & 1) ~= 0
        local high  = (lightState & 2) ~= 0
        local hazard = IsVehicleExtraLightOn(veh, 0) -- hazard lights approx

        local stateStr = tostring(pos) .. tostring(high) .. tostring(hazard)

        if stateStr ~= lastState then
            lastState = stateStr
            NXN.VehHUD.Log(('lights: pos=%s high=%s hazard=%s'):format(tostring(pos), tostring(high), tostring(hazard)))
            NXN.VehHUD.Send('updateModule', {
                module  = 'lights',
                pos     = pos,
                high    = high,
                hazard  = hazard,
            })

            -- Show/hide logika
            if not Config.Modules.lights.alwaysVisible then
                if pos or high or hazard then
                    SendNUIMessage({ action = 'showModuleTemporary', module = 'lights' })
                    if hideTimer then clearTimeout(hideTimer); hideTimer = nil end
                else
                    if not hideTimer then
                        hideTimer = setTimeout(function()
                            SendNUIMessage({ action = 'hideModuleTemporary', module = 'lights' })
                            hideTimer = nil
                        end, 1500)
                    end
                end
            end
        end

        ::continue::
    end
end)
