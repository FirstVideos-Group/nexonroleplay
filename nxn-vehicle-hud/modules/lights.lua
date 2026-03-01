-- ============================================================
--  nxn-vehicle-hud | modules/lights.lua
--  Lampa allapot: position lights, full beam, veszviloglo
--  #119: hideTimerSeq szamlalo a race condition elkerulesehez
-- ============================================================

-- #119: Szekvencia szamlalos megkoezelites a SetTimeout race condition elkerulesehez.
-- FiveM SetTimeout nem megszakithato, ezert a regi callback-ek ervenytelenitesere
-- hideTimerSeq szamlalot hasznalunk.
local hideTimerSeq = 0
local HIDE_DELAY   = 1500

CreateThread(function()
    local lastState = ''

    while true do
        Wait(200)

        if not NXN.VehHUD.State.inVehicle             then goto continue end
        if not NXN.VehHUD.State.moduleStates['lights'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local _, lightsOn, highbeamsOn = GetVehicleLightsState(veh)
        local indicatorState = GetVehicleIndicatorLights(veh)
        local hazard = (indicatorState == 3)

        local stateStr = tostring(lightsOn) .. tostring(highbeamsOn) .. tostring(hazard)

        if stateStr ~= lastState then
            lastState = stateStr
            NXN.VehHUD.Log(('lights: pos=%s high=%s hazard=%s'):format(
                tostring(lightsOn), tostring(highbeamsOn), tostring(hazard)
            ))

            SendNUIMessage({
                action = 'updateModule',
                module = 'lights',
                pos    = lightsOn,
                high   = highbeamsOn,
                hazard = hazard,
            })

            if not Config.Modules.lights.alwaysVisible then
                if lightsOn or highbeamsOn or hazard then
                    -- Regi hideTimer callback ervenytelenitese (seq noveles)
                    hideTimerSeq = hideTimerSeq + 1
                    SendNUIMessage({ action = 'showModuleTemporary', module = 'lights' })
                else
                    local mySeq = hideTimerSeq + 1
                    hideTimerSeq = mySeq
                    SetTimeout(HIDE_DELAY, function()
                        -- Csak akkor rejtjuk el ha a sequence meg ervenyes
                        if hideTimerSeq == mySeq then
                            SendNUIMessage({ action = 'hideModuleTemporary', module = 'lights' })
                        end
                    end)
                end
            end
        end

        ::continue::
    end
end)
