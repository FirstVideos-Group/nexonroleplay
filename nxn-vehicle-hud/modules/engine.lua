-- ============================================================
--  nxn-vehicle-hud | modules/engine.lua
--  Motor allapot: ok / damaged / critical / off
--  #120: hideTimerSeq szamlalo a race condition elkerulesehez
-- ============================================================

-- #120: Szekvencia szamlalos megkozelites (ugyanaz mint lights.lua #119)
local hideTimerSeq = 0
local lastState    = ''
local cfg          = Config.Modules.engine

local HIDE_DELAY = 3000

CreateThread(function()
    while true do
        Wait(Config.PollInterval * 5)

        if not NXN.VehHUD.State.inVehicle              then goto continue end
        if not NXN.VehHUD.State.moduleStates['engine'] then goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then goto continue end

        local engineHealth = GetVehicleEngineHealth(veh)
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

            SendNUIMessage({
                action = 'updateModule',
                module = 'engine',
                state  = state,
                health = engineHealth,
            })

            if not cfg.alwaysVisible then
                if state == 'damaged' or state == 'critical' or state == 'off' then
                    -- Regi hideTimer callback ervenytelenitese
                    hideTimerSeq = hideTimerSeq + 1
                    SendNUIMessage({ action = 'showModuleTemporary', module = 'engine' })
                else
                    local mySeq = hideTimerSeq + 1
                    hideTimerSeq = mySeq
                    SetTimeout(HIDE_DELAY, function()
                        if hideTimerSeq == mySeq then
                            SendNUIMessage({ action = 'hideModuleTemporary', module = 'engine' })
                        end
                    end)
                end
            end
        end

        ::continue::
    end
end)
