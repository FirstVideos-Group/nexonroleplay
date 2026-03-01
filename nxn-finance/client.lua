-- ============================================================
--  nxn-finance | client.lua
-- ============================================================

local localBalances = { cash = 0, bank = 0 }
local atmUIOpen     = false
local atmBlips      = {}

-- ── Egyenleg szinkronizáció ─────────────────────────────────

AddEventHandler('nxn-finance:client:updated', function(data)
    localBalances.cash = data.cash or 0
    localBalances.bank = data.bank or 0
    -- NUI frissítés (ha nyitva)
    if atmUIOpen then
        SendNUIMessage({ action = 'updateBalance', cash = localBalances.cash, bank = localBalances.bank })
    end
    -- nxn-hud frissítés
    if GetResourceState('nxn-hud') == 'started' then
        exports['nxn-hud']:updateModuleData('money', {
            amount   = localBalances.cash,
            bank     = localBalances.bank,
            currency = '$',
        })
    end
end)

-- ── ATM / Bank NPC inicializálás ────────────────────────────

CreateThread(function()
    -- Bank NPC-k regisztrálása nxn-npcconversation-on keresztül
    if GetResourceState('nxn-npcconversation') == 'started' then
        for npcId, npc in pairs(Config.BankNPCs) do
            exports['nxn-npcconversation']:registerNPC(npcId, {
                label    = npc.label,
                model    = npc.model,
                coords   = npc.coords,
                scenario = npc.scenario,
                options  = {
                    {
                        label    = 'Egyenleg megtekintése',
                        icon     = 'hgi-bank',
                        event    = 'nxn-finance:client:openATM',
                        args     = { npcId = npcId },
                    },
                    {
                        label    = 'Letét (cash → bank)',
                        icon     = 'hgi-money-02',
                        event    = 'nxn-finance:client:openATM',
                        args     = { npcId = npcId, tab = 'deposit' },
                    },
                    {
                        label    = 'Felvét (bank → cash)',
                        icon     = 'hgi-safe',
                        event    = 'nxn-finance:client:openATM',
                        args     = { npcId = npcId, tab = 'withdraw' },
                    },
                    {
                        label    = 'Átutalás',
                        icon     = 'hgi-transfer-horizontal',
                        event    = 'nxn-finance:client:openATM',
                        args     = { npcId = npcId, tab = 'transfer' },
                    },
                },
            })
        end
    end

    -- ATM blipek és közelség figyelés
    for _, atm in ipairs(Config.ATMs) do
        if Config.BlipEnabled ~= false then
            local blip = AddBlipForCoord(atm.coords.x, atm.coords.y, atm.coords.z)
            SetBlipSprite(blip, 108)
            SetBlipColour(blip, 2)
            SetBlipScale(blip, 0.6)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(atm.label)
            EndTextCommandSetBlipName(blip)
            atmBlips[atm.id] = blip
        end
    end

    -- ATM E-gomb közelség loop
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            for _, atm in ipairs(Config.ATMs) do
                local dist = #(playerCoords - atm.coords)
                if dist < Config.InteractDistance + 5.0 then
                    sleep = 0
                    if dist < Config.InteractDistance then
                        -- Felirat megjelenítése
                        SetTextComponentFormat('STRING')
                        AddTextComponentString('~INPUT_CONTEXT~ ATM használata')
                        DisplayHelpTextThisFrame(true, false, true, 0)

                        if IsControlJustPressed(0, 38) then  -- E billentyű
                            exports['nxn-finance']:openATM(atm.id)
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end)
end)

-- ── ATM UI megnyitás event ───────────────────────────────────

AddEventHandler('nxn-finance:client:openATM', function(data)
    data = data or {}
    exports['nxn-finance']:openATM(data.npcId, data.tab)
end)

-- ── NUI callback-ek ─────────────────────────────────────────

RegisterNUICallback('deposit', function(data, cb)
    local amount = math.floor(tonumber(data.amount) or 0)
    if amount > 0 then
        TriggerServerEvent('nxn-finance:server:deposit', amount)
    end
    cb({})
end)

RegisterNUICallback('withdraw', function(data, cb)
    local amount = math.floor(tonumber(data.amount) or 0)
    if amount > 0 then
        TriggerServerEvent('nxn-finance:server:withdraw', amount)
    end
    cb({})
end)

RegisterNUICallback('transfer', function(data, cb)
    local amount   = math.floor(tonumber(data.amount) or 0)
    local targetId = tonumber(data.targetId)
    local reason   = data.reason or ''
    if amount > 0 and targetId then
        TriggerServerEvent('nxn-finance:server:transfer', targetId, amount, reason)
    end
    cb({})
end)

RegisterNUICallback('closeATM', function(_, cb)
    exports['nxn-finance']:closeATM()
    cb({})
end)

-- ── ESC bezárás ─────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        if atmUIOpen and IsControlJustPressed(0, 200) then
            exports['nxn-finance']:closeATM()
        end
    end
end)

-- ── Kliens exportok ─────────────────────────────────────────

exports('getLocalBalances', function()
    return { cash = localBalances.cash, bank = localBalances.bank }
end)

exports('openATM', function(atmId, defaultTab)
    if atmUIOpen then return end
    atmUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = 'open',
        cash       = localBalances.cash,
        bank       = localBalances.bank,
        atmId      = atmId or '',
        defaultTab = defaultTab or 'balance',
    })
end)

exports('closeATM', function()
    if not atmUIOpen then return end
    atmUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end)

exports('isATMOpen', function()
    return atmUIOpen
end)
