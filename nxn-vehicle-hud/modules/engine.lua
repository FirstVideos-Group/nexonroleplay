-- ============================================================
--  nxn-vehicle-hud | modules/engine.lua
--  Motor allapot: ok / damaged / critical / off
--  FIX: Lua SetTimeout (nem JS clearTimeout/setTimeout)
-- ============================================================

local hideTimer = nil
local lastState = ''
local cfg       = Config.Modules.engine

local HIDE_DELAY = 3000  -- ms, ennyi utan tunjuk el az 'ok' allapotot

CreateThread(function()
    while true do
        Wait(Config.PollInterval * 5)  -- ~500ms, ritkan valtozik

        if not inVehicle then goto continue end
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

            -- Kozvetlenul kuldi, mindig (show/hide a HUD-on belul van kezelve)
            SendNUIMessage({
                action = 'updateModule',
                module = 'engine',
                state  = state,
                health = engineHealth,
            })

            if not cfg.alwaysVisible then
                if state == 'damaged' or state == 'critical' or state == 'off' then
                    -- Megszakitjuk a fuggobe levo eltunest
                    hideTimer = nil
                    SendNUIMessage({ action = 'showModuleTemporary', module = 'engine' })
                else
                    -- 'ok': rovid delay utan eltunik
                    if not hideTimer then
                        hideTimer = true
                        SetTimeout(HIDE_DELAY, function()
                            if lastState == 'ok' then
                                SendNUIMessage({ action = 'hideModuleTemporary', module = 'engine' })
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
