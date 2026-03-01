-- ============================================================
--  nxn-food | client.lua
-- ============================================================

local isConsuming  = false
local consumeTimer = nil

-- ── Helpers ──────────────────────────────────────────────────

local function PlayFoodAnim(animType, duration, cb)
    local animCfg = Config.Animations[animType]
    if not animCfg then
        if cb then cb() end
        return
    end
    local ped = PlayerPedId()
    RequestAnimDict(animCfg.dict)
    local timeout = 0
    while not HasAnimDictLoaded(animCfg.dict) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    local flags = Config.AnimationBlocking and 49 or 16
    TaskPlayAnim(ped, animCfg.dict, animCfg.clip, 2.0, 2.0, duration, flags, 0, false, false, false)
    if cb then
        SetTimeout(duration, function()
            StopAnimTask(ped, animCfg.dict, animCfg.clip, 2.0)
            cb()
        end)
    end
end

local function StopConsumeAnim(animType)
    local animCfg = Config.Animations[animType]
    if not animCfg then return end
    StopAnimTask(PlayerPedId(), animCfg.dict, animCfg.clip, 2.0)
end

-- ── Net events ───────────────────────────────────────────────

RegisterNetEvent('nxn-food:client:consume', function(itemData)
    if isConsuming then
        NXN.Food.Warn('Már folyamatban van egy fogyasztás.')
        return
    end
    isConsuming = true
    NXN.Food.Log(('Fogyasztás indul: %s'):format(itemData.label))

    PlayFoodAnim(itemData.animation, itemData.duration, function()
        if not isConsuming then return end  -- megszakítva
        isConsuming = false
        TriggerServerEvent('nxn-food:server:consumed', itemData.itemName)
    end)
end)

-- ── NPC regisztrálás ─────────────────────────────────────────

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(500)

    if GetResourceState('nxn-npcconversation') ~= 'started' then
        NXN.Food.Warn('nxn-npcconversation nem fut, NPC-k nem regisztrálhatók.')
        return
    end

    for shopId, shop in pairs(Config.Shops) do
        local npcCfg = {
            label    = shop.label,
            model    = shop.npc.model,
            coords   = shop.npc.coords,
            scenario = shop.npc.scenario,
            blip     = shop.npc.blip,
            dialogues = {
                {
                    id    = 'buy_food_' .. shopId,
                    label = 'Vásárolni szeretnék',
                    icon  = 'hgi-shopping-cart-01',
                    event = 'nxn-food:client:openShop',
                    args  = { shopId = shopId },
                },
            },
        }
        exports['nxn-npcconversation']:registerNPC(shopId .. '_food_npc', npcCfg)
        NXN.Food.Log(('NPC regisztrálva: %s'):format(shopId))
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if GetResourceState('nxn-npcconversation') ~= 'started' then return end
    for shopId, _ in pairs(Config.Shops) do
        exports['nxn-npcconversation']:unregisterNPC(shopId .. '_food_npc')
    end
end)

-- ── Shop megnyitás esemény ────────────────────────────────────

RegisterNetEvent('nxn-food:client:openShop', function(shopId)
    local shop = Config.Shops[shopId]
    if not shop then
        NXN.Food.Warn(('Ismeretlen bolt: %s'):format(tostring(shopId)))
        return
    end
    TriggerServerEvent('nxn-food:server:requestShop', shopId)
end)

-- Szerver visszaküldi az adatokat
RegisterNetEvent('nxn-food:client:shopData', function(shopId, shopData, currentMoney)
    SendNUIMessage({
        action       = 'openShop',
        shopId       = shopId,
        shopData     = shopData,
        currentMoney = currentMoney,
    })
    SetNuiFocus(true, true)
end)

-- ── NUI callbacks ────────────────────────────────────────────

RegisterNUICallback('closeShop', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeShop' })
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    TriggerServerEvent('nxn-food:server:buy', data.shopId, data.itemName)
    cb('ok')
end)

-- ── Exports ──────────────────────────────────────────────────

exports('isEating', function()
    return isConsuming
end)

exports('cancelConsume', function()
    if isConsuming then
        isConsuming = false
        NXN.Food.Log('Fogyasztás megszakítva.')
    end
end)
