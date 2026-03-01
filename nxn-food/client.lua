-- ============================================================
--  nxn-food | client.lua
--  MEGJEGYZÉS: A bolt vásárlás logika az nxn-shop-ba lett
--  átvezérelve (#140). Ez a fájl csak a fogyasztás animációt
--  és nxn-npcconversation regisztrációt kezeli.
-- ============================================================

local isConsuming = false

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

-- ── Net events ───────────────────────────────────────────────

RegisterNetEvent('nxn-food:client:consume', function(itemData)
    if isConsuming then
        NXN.Food.Warn('Már folyamatban van egy fogyasztás.')
        return
    end
    isConsuming = true
    NXN.Food.Log(('Fogyasztás indul: %s'):format(itemData.label))

    PlayFoodAnim(itemData.animation, itemData.duration, function()
        if not isConsuming then return end
        isConsuming = false
        TriggerServerEvent('nxn-food:server:consumed', itemData.itemName)
    end)
end)

-- ── NPC regisztrálás (csak ha nxn-shop NEM fut) ──────────────
-- Ha nxn-shop fut, az kezeli a bolt NPC-ket.
-- Az nxn-food NPC-k csak a fogyasztás dialóg opciót adják.

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(800)

    if GetResourceState('nxn-npcconversation') ~= 'started' then
        NXN.Food.Warn('nxn-npcconversation nem fut.')
        return
    end

    -- Ha nxn-shop fut, a bolt NPC-ket az nxn-shop regisztrálja
    if GetResourceState('nxn-shop') == 'started' then
        NXN.Food.Info('nxn-shop fut – bolt NPC-k kezelése átadva.')
        return
    end

    -- nxn-shop nélkül: saját NPC-k regisztrálása
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
        NXN.Food.Log(('Fallback NPC regisztrálva: %s'):format(shopId))
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if GetResourceState('nxn-npcconversation') ~= 'started' then return end
    if GetResourceState('nxn-shop') == 'started' then return end
    for shopId, _ in pairs(Config.Shops) do
        exports['nxn-npcconversation']:unregisterNPC(shopId .. '_food_npc')
    end
end)

-- Fallback shop megnyitás (csak ha nxn-shop nem fut)
RegisterNetEvent('nxn-food:client:openShop', function(shopId)
    local shop = Config.Shops[shopId]
    if not shop then return end
    TriggerServerEvent('nxn-food:server:requestShop', shopId)
end)

RegisterNetEvent('nxn-food:client:shopData', function(shopId, shopData, currentMoney)
    SendNUIMessage({
        action       = 'openShop',
        shopId       = shopId,
        shopData     = shopData,
        currentMoney = currentMoney,
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('closeShop', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeShop' })
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    -- Ha nxn-shop fut, az kezeli; egyébként fallback
    if GetResourceState('nxn-shop') == 'started' then
        exports['nxn-shop']:openShop(data.shopId, 'buy')
    else
        TriggerServerEvent('nxn-food:server:buy', data.shopId, data.itemName)
    end
    cb('ok')
end)

-- ── Exportok ─────────────────────────────────────────────────

exports('isEating', function()
    return isConsuming
end)

exports('cancelConsume', function()
    if isConsuming then
        isConsuming = false
        NXN.Food.Log('Fogyasztás megszakítva.')
    end
end)
