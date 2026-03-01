-- ============================================================
--  nxn-bank | client.lua
-- ============================================================

local isOpen     = false
local panelMode  = 'atm'   -- 'atm' | 'bank'
local nearPoint  = nil     -- { type='atm'|'bank', label=string }

-- ── Segédfüggvények ─────────────────────────────────────────

local function SetVisible(state, mode)
    isOpen    = state
    panelMode = mode or panelMode
    SetNuiFocus(state, state)
    SendNUIMessage({ action = 'setVisible', visible = state, mode = panelMode })
end

local function DrawMarker(coords)
    local c = Config.Marker.color
    DrawMarker(
        Config.Marker.type,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.Marker.size, Config.Marker.size, 0.6,
        c.r, c.g, c.b, c.a,
        false, false, 2, false, nil, nil, false
    )
end

local function DrawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z + 0.8)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

-- ── Közelség-ellenőrző szál ──────────────────────────────────

CreateThread(function()
    while true do
        local sleep = 1000
        local ped   = PlayerPedId()
        local pos   = GetEntityCoords(ped)
        nearPoint   = nil

        for _, atm in ipairs(Config.ATMs) do
            local dist = #(pos - atm.coords)
            if dist < Config.InteractDistance * 4 then
                sleep = 0
                if Config.Marker.enabled then DrawMarker(atm.coords) end
                DrawText3D(atm.coords, '[E] ' .. atm.label)
                if dist < Config.InteractDistance then
                    nearPoint = { type = 'atm', label = atm.label }
                end
            end
        end

        for _, bank in ipairs(Config.Banks) do
            local dist = #(pos - bank.coords)
            if dist < Config.InteractDistance * 4 then
                sleep = 0
                if Config.Marker.enabled then DrawMarker(bank.coords) end
                DrawText3D(bank.coords, '[E] ' .. bank.label)
                if dist < Config.InteractDistance then
                    nearPoint = { type = 'bank', label = bank.label }
                end
            end
        end

        Wait(sleep)
    end
end)

-- ── Interakció billentyű ─────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        if nearPoint and not isOpen then
            if IsControlJustReleased(0, 38) then -- E
                local mode = nearPoint.type
                SetVisible(true, mode)
                -- Egyenleg szinkron kérés
                TriggerServerEvent('nxn-bank:server:getTransactions', 1)
            end
        end
    end
end)

-- ── NUI callbacks ────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    SetVisible(false)
    cb('ok')
end)

RegisterNUICallback('deposit', function(data, cb)
    local amount = tonumber(data.amount)
    if not amount then cb({ ok = false }) return end
    TriggerServerEvent('nxn-bank:server:deposit', amount)
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    local amount = tonumber(data.amount)
    if not amount then cb({ ok = false }) return end
    TriggerServerEvent('nxn-bank:server:withdraw', amount)
    cb('ok')
end)

RegisterNUICallback('transfer', function(data, cb)
    local amount = tonumber(data.amount)
    local target = tonumber(data.targetId)
    if not amount or not target then cb({ ok = false }) return end
    TriggerServerEvent('nxn-bank:server:transfer', target, amount, data.description or '')
    cb('ok')
end)

RegisterNUICallback('getTransactions', function(data, cb)
    local page = tonumber(data.page) or 1
    TriggerServerEvent('nxn-bank:server:getTransactions', page)
    cb('ok')
end)

-- ── Net events ───────────────────────────────────────────────

RegisterNetEvent('nxn-bank:client:syncBalance', function(data)
    SendNUIMessage({ action = 'updateBalance', cash = data.cash, bank = data.bank })
    if GetResourceState('nxn-hud') == 'started' then
        exports['nxn-hud']:updateModuleData('money', {
            amount   = data.cash,
            bank     = data.bank,
            currency = '$',
        })
    end
end)

RegisterNetEvent('nxn-bank:client:transactionResult', function(data)
    SendNUIMessage({ action = 'transactionResult', ok = data.ok, message = data.message })
end)

RegisterNetEvent('nxn-bank:client:transactions', function(data)
    SendNUIMessage({
        action = 'setTransactions',
        items  = data.items,
        page   = data.page,
        total  = data.total,
    })
end)

-- ── Escape bezárás ───────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        if isOpen and IsControlJustReleased(0, 200) then -- ESC
            SetVisible(false)
        end
    end
end)

-- ── Kliens exportok ──────────────────────────────────────────

exports('openATM', function()
    SetVisible(true, 'atm')
end)

exports('openBankCounter', function()
    SetVisible(true, 'bank')
end)

exports('closeBank', function()
    SetVisible(false)
end)
