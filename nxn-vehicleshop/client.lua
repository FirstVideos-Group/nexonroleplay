-- ============================================================
--  nxn-vehicleshop | client.lua
-- ============================================================

local isShopOpen      = false
local currentDealerId = nil
local testDriveVehicle = nil
local testDriveTimer   = 0
local testDriveCooldowns = {}
local dealerNPCs      = {}
local dealerBlips     = {}

-- ── Helpers ──────────────────────────────────────────────────

local function SetShopVisible(state, dealerId)
    isShopOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = 'setVisible', visible = state, dealerId = dealerId })
end

local function NotifyLocal(msg, ntype)
    TriggerEvent('nxn-notify:client:show', msg, ntype or 'info')
end

-- ── NPC & Blip init ──────────────────────────────────────────

local function InitDealers()
    for _, dealer in ipairs(Config.Dealers) do
        -- Blip
        if Config.BlipEnabled then
            local blip = AddBlipForCoord(dealer.npc.coords.x, dealer.npc.coords.y, dealer.npc.coords.z)
            SetBlipSprite(blip, dealer.blip.sprite)
            SetBlipColour(blip, dealer.blip.color)
            SetBlipScale(blip, dealer.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(dealer.label)
            EndTextCommandSetBlipName(blip)
            dealerBlips[dealer.id] = blip
        end

        -- NPC
        if dealer.npc.enabled then
            CreateThread(function()
                local model = GetHashKey(dealer.npc.model)
                RequestModel(model)
                while not HasModelLoaded(model) do Wait(50) end

                local c = dealer.npc.coords
                local npc = CreatePed(4, model, c.x, c.y, c.z - 1.0, c.w, false, true)
                SetEntityInvincible(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                FreezeEntityPosition(npc, true)
                SetPedCanRagdoll(npc, false)
                TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_CLIPBOARD', 0, true)

                dealerNPCs[dealer.id] = npc
                SetModelAsNoLongerNeeded(model)

                -- nxn-npcconversation integráció
                if GetResourceState('nxn-npcconversation') == 'started' then
                    local did = dealer.id
                    exports['nxn-npcconversation']:registerNPC(npc, dealer.label, {
                        {
                            label = 'Megnézem a kínálatot',
                            action = function()
                                exports['nxn-vehicleshop']:openShop(did)
                            end
                        }
                    })
                end
            end)
        end
    end
end

-- ── Shop megnyitás logika ────────────────────────────────────

local function FindDealerById(id)
    for _, d in ipairs(Config.Dealers) do
        if d.id == id then return d end
    end
    return nil
end

local function OpenShopForDealer(dealerId)
    local dealer = FindDealerById(dealerId)
    if not dealer then return end
    currentDealerId = dealerId

    -- Egyenleg lekérés a UI-hoz
    local balance = 0
    if GetResourceState('nxn-finance') == 'started' then
        TriggerServerEvent('nxn-vehicleshop:server:getBalance')
    end

    -- Finanszírozás elérhetősége
    local financingAvailable = Config.FinancingEnabled and GetResourceState('nxn-finance') == 'started'

    SendNUIMessage({
        action            = 'openShop',
        dealer            = {
            id         = dealer.id,
            label      = dealer.label,
            categories = dealer.categories,
            testDrive  = dealer.testDrive and dealer.testDrive.enabled or false,
        },
        vehicles          = dealer.vehicles,
        financingAvailable = financingAvailable,
        financing          = Config.Financing,
    })
    SetShopVisible(true, dealerId)
end

-- ── NUI Callbacks ────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    SetShopVisible(false)
    currentDealerId = nil
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    if not currentDealerId then cb('no_dealer') return end
    TriggerServerEvent('nxn-vehicleshop:server:buy', data.model, currentDealerId, data.useFinancing, data.months)
    cb('ok')
end)

RegisterNUICallback('testDrive', function(data, cb)
    if not currentDealerId then cb('no_dealer') return end
    local dealer = FindDealerById(currentDealerId)
    if not dealer or not dealer.testDrive or not dealer.testDrive.enabled then
        cb('disabled')
        return
    end

    local now = GetGameTimer()
    local cooldownKey = currentDealerId .. '_' .. data.model
    if testDriveCooldowns[cooldownKey] and (now - testDriveCooldowns[cooldownKey]) < (Config.TestDriveCooldown * 1000) then
        local remaining = math.ceil((Config.TestDriveCooldown * 1000 - (now - testDriveCooldowns[cooldownKey])) / 1000)
        SendNUIMessage({ action = 'notify', message = ('Teszt-menet cooldown: %d mp'):format(remaining), ntype = 'warning' })
        cb('cooldown')
        return
    end

    testDriveCooldowns[cooldownKey] = now
    SetShopVisible(false)
    exports['nxn-vehicleshop']:startTestDrive(data.model, currentDealerId)
    cb('ok')
end)

RegisterNUICallback('getBalance', function(_, cb)
    if GetResourceState('nxn-finance') ~= 'started' then cb({ bank = 0, cash = 0 }) return end
    TriggerServerEvent('nxn-vehicleshop:server:requestBalance')
    cb('ok')
end)

-- ── Net Events (kliens) ──────────────────────────────────────

RegisterNetEvent('nxn-vehicleshop:client:purchased', function(model, label, plate)
    SetShopVisible(false)
    currentDealerId = nil
    SendNUIMessage({ action = 'purchaseSuccess', model = model, label = label, plate = plate })
end)

RegisterNetEvent('nxn-vehicleshop:client:balanceUpdate', function(balances)
    SendNUIMessage({ action = 'balanceUpdate', bank = balances.bank, cash = balances.cash })
end)

-- ── Teszt-menet ──────────────────────────────────────────────

local function StartTestDriveInternal(model, dealer)
    if testDriveVehicle then
        DeleteVehicle(testDriveVehicle)
        testDriveVehicle = nil
    end

    local sc = dealer.testDrive.spawnCoord
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(50) end

    local veh = CreateVehicle(hash, sc.x, sc.y, sc.z, sc.w, false, false)
    SetVehicleNumberPlateText(veh, 'TESZT')
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetModelAsNoLongerNeeded(hash)
    testDriveVehicle = veh
    testDriveTimer   = dealer.testDrive.duration

    NXN.VehicleShop.Info(('Teszt-menet indul: model=%s duration=%d'):format(model, dealer.testDrive.duration))
    SendNUIMessage({ action = 'testDriveStart', duration = dealer.testDrive.duration })

    -- Timer
    CreateThread(function()
        while testDriveTimer > 0 and testDriveVehicle do
            Wait(1000)
            testDriveTimer = testDriveTimer - 1
            SendNUIMessage({ action = 'testDriveTimer', remaining = testDriveTimer })
        end
        if testDriveVehicle then
            if DoesEntityExist(testDriveVehicle) then
                TaskLeaveVehicle(PlayerPedId(), testDriveVehicle, 0)
                Wait(1500)
                DeleteVehicle(testDriveVehicle)
            end
            testDriveVehicle = nil
            SendNUIMessage({ action = 'testDriveEnd' })
            -- nxn-notify
            TriggerEvent('nxn-notify:client:show', 'A teszt-menet véget ért.', 'info')
        end
    end)
end

-- ── Proximity check (NPC közelség manuális nyitáshoz) ────────

CreateThread(function()
    Wait(3000)
    InitDealers()
end)

CreateThread(function()
    while true do
        Wait(1000)
        if not isShopOpen then
            local ped = PlayerPedId()
            local px, py, pz = GetEntityCoords(ped)
            for _, dealer in ipairs(Config.Dealers) do
                local c = dealer.npc.coords
                local dist = #(vector3(px, py, pz) - vector3(c.x, c.y, c.z))
                if dist < 2.0 and not dealer.npc.enabled then
                    -- Ha nincs NPC, marker interakció
                    if IsControlJustPressed(0, 38) then -- E gomb
                        OpenShopForDealer(dealer.id)
                    end
                end
            end
        end
    end
end)

-- ── Exportok (kliens) ────────────────────────────────────────

exports('openShop', function(dealerId)
    OpenShopForDealer(dealerId or (Config.Dealers[1] and Config.Dealers[1].id))
end)

exports('closeShop', function()
    SetShopVisible(false)
    currentDealerId = nil
end)

exports('startTestDrive', function(model, dealerId)
    local dealer = FindDealerById(dealerId)
    if not dealer then return end
    StartTestDriveInternal(model, dealer)
end)

exports('isTestDriving', function()
    return testDriveVehicle ~= nil
end)

-- Parancs teszteléshez
RegisterCommand('vehicleshop', function()
    OpenShopForDealer(Config.Dealers[1] and Config.Dealers[1].id)
end, false)
