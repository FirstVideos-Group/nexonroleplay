-- ============================================================
--  nxn-vehicle-hud | modules/lights.lua
--  Lampa allapot: position lights, full beam, veszviloglo
--  FIX: helyes GTA API, Lua SetTimeout (nem JS setTimeout)
-- ============================================================

local hideTimer  = nil
local HIDE_DELAY = 1500  -- ms, ennyi utan tunteti el a lamp ikont

CreateThread(function()
    local lastState = ''

    while true do
        -- Lampak ritkabban valtoznak, 200ms eleg
        Wait(200)

        if not inVehicle then goto continue end
        if not moduleStates['lights'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        -- GetVehicleLightsState(vehicle) -> lightsOn (bool), highbeamsOn (bool)
        -- FiveM native: a ket return erteke a ket outparam
        local _, lightsOn, highbeamsOn = GetVehicleLightsState(veh)
        -- Veszviloglo: IsVehicleExtraLightOn nem letezik; a hazard
        -- GetVehicleIndicatorLights(veh) -> 0=off,1=left,2=right,3=hazard
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

            -- Show/hide logika lampak be/kikapcsolas alapjan
            if not Config.Modules.lights.alwaysVisible then
                if lightsOn or highbeamsOn or hazard then
                    -- Megszakitjuk az esetleges fuggobe elo eltunetest
                    if hideTimer then
                        hideTimer = nil
                    end
                    SendNUIMessage({ action = 'showModuleTemporary', module = 'lights' })
                else
                    -- Rovid delay utan eltunjuk (ne ugorjon el azonnal)
                    if not hideTimer then
                        hideTimer = true  -- flag, hogy ne inditsunk tobbszor
                        SetTimeout(HIDE_DELAY, function()
                            -- Csak akkor rejtjuk el ha meg mindig "off" az allapot
                            if lastState == 'falsefalsefalse' then
                                SendNUIMessage({ action = 'hideModuleTemporary', module = 'lights' })
                            end
                            hideTimer = nil
                        end)
                    end
                end
            end
        end

        ::continue::
    end
end)
