-- ============================================================
--  nxn-shop | client.lua
-- ============================================================

local isShopUIOpen = false
local currentMode  = 'buy'  -- 'buy' | 'sell'

-- ── NPC regisztrálás ─────────────────────────────────────────

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(500)

    if GetResourceState('nxn-npcconversation') ~= 'started' then
        NXN.Shop.Warn('nxn-npcconversation nem fut, NPC-k nem regisztrálhatók.')
        return
    end

    for shopId, shop in pairs(Config.Shops) do
        local dialogues = {
            {
                id    = 'open_shop_' .. shopId,
                label = 'Vásárolni szeretnék',
                icon  = 'hgi-shopping-cart-01',
                event = 'nxn-shop:client:openShop',
                args  = { shopId = shopId, mode = 'buy' },
            },
        }
        if shop.canSell and Config.SellEnabled then
            table.insert(dialogues, {
                id    = 'sell_items_' .. shopId,
                label = 'Eladni szeretnék',
                icon  = 'hgi-money-exchange-02',
                event = 'nxn-shop:client:openShop',
                args  = { shopId = shopId, mode = 'sell' },
            })
        end

        local npcCfg = {
            label     = shop.label,
            model     = shop.npc.model,
            coords    = shop.npc.coords,
            scenario  = shop.npc.scenario,
            blip      = shop.npc.blip,
            dialogues = dialogues,
        }
        exports['nxn-npcconversation']:registerNPC(shopId .. '_npc', npcCfg)
        NXN.Shop.Log(('NPC regisztrálva: %s'):format(shopId))
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if GetResourceState('nxn-npcconversation') ~= 'started' then return end
    for shopId, _ in pairs(Config.Shops) do
        exports['nxn-npcconversation']:unregisterNPC(shopId .. '_npc')
    end
end)

-- ── Net events ───────────────────────────────────────────────

RegisterNetEvent('nxn-shop:client:openShop', function(shopId, mode)
    local shop = Config.Shops[shopId]
    if not shop then
        NXN.Shop.Warn(('Ismeretlen bolt: %s'):format(tostring(shopId)))
        return
    end
    currentMode = mode or 'buy'
    TriggerServerEvent('nxn-shop:server:requestShop', shopId, currentMode)
end)

RegisterNetEvent('nxn-shop:client:shopData', function(shopId, shopData, currentMoney, mode)
    isShopUIOpen = true
    SendNUIMessage({
        action       = 'openShop',
        shopId       = shopId,
        shopData     = shopData,
        currentMoney = currentMoney,
        mode         = mode or 'buy',
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('nxn-shop:client:buyResult', function(ok, msg, newBalance)
    SendNUIMessage({ action = 'buyResult', ok = ok, msg = msg, newBalance = newBalance })
end)

RegisterNetEvent('nxn-shop:client:sellResult', function(ok, msg, newBalance)
    SendNUIMessage({ action = 'sellResult', ok = ok, msg = msg, newBalance = newBalance })
end)

-- ── NUI callbacks ────────────────────────────────────────────

RegisterNUICallback('closeShop', function(_, cb)
    isShopUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    TriggerServerEvent('nxn-shop:server:buy', data.shopId, data.itemName, data.amount or 1)
    cb('ok')
end)

RegisterNUICallback('sell', function(data, cb)
    TriggerServerEvent('nxn-shop:server:sell', data.shopId, data.itemName, data.amount or 1)
    cb('ok')
end)

RegisterNUICallback('requestInventory', function(_, cb)
    TriggerServerEvent('nxn-shop:server:requestInventory')
    cb('ok')
end)

-- Szerver küldi vissza az inventory adatokat (sell tab-hoz)
RegisterNetEvent('nxn-shop:client:inventoryData', function(invData)
    SendNUIMessage({ action = 'inventoryData', items = invData })
end)

-- ── Exportok ─────────────────────────────────────────────────

exports('openShop', function(shopId, mode)
    local shop = Config.Shops[shopId]
    if not shop then return end
    TriggerServerEvent('nxn-shop:server:requestShop', shopId, mode or 'buy')
end)

exports('closeShop', function()
    isShopUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeShop' })
end)

exports('isShopOpen', function()
    return isShopUIOpen
end)
