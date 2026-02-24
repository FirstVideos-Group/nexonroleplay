-- ============================================================
--  nxn-vehicle-hud | modules/engine.lua
--  Motor allapot: ok / damaged / critical / off
--  alwaysVisible=false: csak ha a motor meghibasodott vagy leall
--  Kulso resource (nxn-engine) is felulirhatja: exports['nxn-vehicle-hud']:setEngineState()
-- ============================================================

local hideTimer   = nil
local lastState   = ''
local cfg         = Config.Modules.engine

CreateThread(function()
    while true do
        Wait(Config.PollInterval * 5)  -- ritkan valtozik
        if not hudVisible or not inVehicle then goto continue end
        if not moduleStates['engine'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local engineHealth = GetVehicleEngineHealth(veh)  -- 0-1000
        local engineOn     = GetIsVehicleEngineRunning(veh)

        local state
        if not engineOn then
            state = 'off'
        elseif engineHealth <= 0 then
            state = 'critical'
        elseif engineHealth < (cfg.threshold or 950) then
            state = 'damaged'
        else
            state = 'ok'
        end

        if state ~= lastState then
            lastState = state
            NXN.VehHUD.Log(('engine: state=%s health=%.0f'):format(state, engineHealth))
            NXN.VehHUD.Send('updateModule', {
                module = 'engine',
                state  = state,
                health = engineHealth,
            })

            if not cfg.alwaysVisible then
                if state == 'damaged' or state == 'critical' or state == 'off' then
                    SendNUIMessage({ action = 'showModuleTemporary', module = 'engine' })
                    if hideTimer then clearTimeout(hideTimer); hideTimer = nil end
                else
                    -- 'ok' allapotban eltuntetes
                    if not hideTimer then
                        hideTimer = setTimeout(function()
                            SendNUIMessage({ action = 'hideModuleTemporary', module = 'engine' })
                            hideTimer = nil
                        end, 3000)
                    end
                end
            end
        end

        ::continue::
    end
end)
