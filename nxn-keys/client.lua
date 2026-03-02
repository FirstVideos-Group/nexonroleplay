-- ============================================================
--  nxn-keys | client.lua
-- ============================================================

-- ── Lokális kulcs cache ────────────────────────────────────────────

-- { [plate] = { is_owner = bool, label = string, model = string } }
local keyCache   = {}
local isRingOpen = false

-- ── Segédfüggvények ────────────────────────────────────────────────

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    local t = ntype or 'info'
    if     t == 'success' then exports['nxn-notify']:success(msg)
    elseif t == 'danger'  then exports['nxn-notify']:danger(msg)
    elseif t == 'warning' then exports['nxn-notify']:warning(msg)
    else                       exports['nxn-notify']:info(msg)
    end
end

local function BuildCacheFromList(keys)
    keyCache = {}
    for _, k in ipairs(keys or {}) do
        keyCache[k.plate] = { is_owner = k.is_owner, label = k.label, model = k.model }
    end
    NXN.Keys.Log(('Cache építve: %d kulcs'):format(#keys or 0))
end

local function GetCacheAsList()
    local list = {}
    for plate, data in pairs(keyCache) do
        table.insert(list, {
            plate    = plate,
            is_owner = data.is_owner,
            label    = data.label,
            model    = data.model,
        })
    end
    return list
end

-- ── nxn-engine auth callback regisztrálása ────────────────────────

local function RegisterEngineAuth()
    if GetResourceState('nxn-engine') ~= 'started' then
        NXN.Keys.Warn('RegisterEngineAuth: nxn-engine nem fut, kihagyva')
        return
    end
    exports['nxn-engine']:registerStartAuthCallback(function(vehicleEntity)
        local plate = NXN.Keys.NormalizePlate(GetVehicleNumberPlateText(vehicleEntity))
        local has   = keyCache[plate] ~= nil
        NXN.Keys.Log(('AuthCallback: plate=%s has=%s'):format(plate, tostring(has)))
        return has
    end)
    NXN.Keys.Info('Engine auth callback regisztrálva')
end

-- Induláskor és ha az nxn-engine / nxn-keys később indul
AddEventHandler('onClientResourceStart', function(res)
    if res == 'nxn-engine' or res == GetCurrentResourceName() then
        RegisterEngineAuth()
        -- Kulcslista szinkronizálás szerverről
        TriggerServerEvent('nxn-keys:server:requestSync')
    end
end)

-- ── Zárolás / Nyitás ────────────────────────────────────────────────

local function GetClosestVehicle(maxDist)
    local ped   = PlayerPedId()
    local px, py, pz = GetEntityCoords(ped)
    local closest = 0
    local closestDist = maxDist
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        local vx, vy, vz = GetEntityCoords(veh)
        local d = #(vector3(px, py, pz) - vector3(vx, vy, vz))
        if d < closestDist then
            closest     = veh
            closestDist = d
        end
    end
    return closest
end

local function PlayLockAnim()
    if not Config.LockAnim.enabled then return end
    local dict = Config.LockAnim.dict
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 30 do
        Wait(50)
        timeout = timeout + 1
    end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(PlayerPedId(), dict, Config.LockAnim.name, 3.0, 3.0, 500, 0, 0, false, false, false)
    end
end

local lockCooldown = false

CreateThread(function()
    while true do
        Wait(0)
        if not isRingOpen then
            -- [L] gómb: zárolás/nyitás
            if IsControlJustPressed(0, Config.LockKey) and not lockCooldown then
                local veh = GetClosestVehicle(Config.InteractDistance)
                if veh ~= 0 then
                    local plate = NXN.Keys.NormalizePlate(GetVehicleNumberPlateText(veh))
                    if keyCache[plate] then
                        lockCooldown = true
                        -- Zárállapot lekérdezés az nxn-engine-től
                        local isLocked = false
                        if GetResourceState('nxn-engine') == 'started' then
                            isLocked = exports['nxn-engine']:isLocked()
                        end

                        PlayLockAnim()

                        if Config.LockSound.enabled then
                            local snd = isLocked and Config.LockSound.unlock or Config.LockSound.lock
                            SendNUIMessage({ action = 'playSound', sound = snd })
                        end

                        -- Engine zárállapot belíttés kliensen
                        if GetResourceState('nxn-engine') == 'started' then
                            exports['nxn-engine']:setLocked(not isLocked)
                        end

                        TriggerServerEvent(not isLocked and 'nxn-keys:server:lock' or 'nxn-keys:server:unlock', plate)

                        if not isLocked then
                            Notify('Jármű lezárva – ' .. plate, 'info')
                        else
                            Notify('Jármű kinyitva – ' .. plate, 'success')
                        end

                        Wait(800)
                        lockCooldown = false
                    else
                        Notify('Nincs kulcsod ehhez a járműhöz!', 'danger')
                    end
                end
            end

            -- [K] gómb: kulcskarika
            if IsControlJustPressed(0, Config.KeyringKey) then
                TriggerServerEvent('nxn-keys:server:getKeys')
                -- A syncKeys event megkapása után a UI megnyílik
            end
        end
    end
end)

-- Közelségben lévő játékosok listája (kulcsátadáshoz)
local nearbyPlayers = {}

CreateThread(function()
    while true do
        Wait(Config.NearbyPlayersInterval)
        if isRingOpen then
            local ped  = PlayerPedId()
            local px, py, pz = GetEntityCoords(ped)
            local list = {}
            for _, pid in ipairs(GetActivePlayers()) do
                if pid ~= PlayerId() then
                    local oPed = GetPlayerPed(pid)
                    local ox, oy, oz = GetEntityCoords(oPed)
                    local d = #(vector3(px, py, pz) - vector3(ox, oy, oz))
                    if d <= Config.GiveKeyDistance then
                        table.insert(list, {
                            id   = GetPlayerServerId(pid),
                            name = GetPlayerName(pid),
                            dist = math.floor(d * 10) / 10,
                        })
                    end
                end
            end
            nearbyPlayers = list
            if isRingOpen then
                SendNUIMessage({ action = 'nearbyPlayers', players = list })
            end
        end
    end
end)

-- ── Net Events (kliens) ─────────────────────────────────────────

RegisterNetEvent('nxn-keys:client:syncKeys', function(keys)
    BuildCacheFromList(keys)
    if isRingOpen then
        -- Zárállapot lekérés az nxn-engine-től minden kulcshoz
        local enriched = {}
        for _, k in ipairs(keys) do
            local locked = false
            -- Megjegyzés: az nxn-engine isLocked() csak az aktuális járműre adja vissza
            -- A UI-ban ez a mező inkább szimbolikus marad hacsak nem fejlesztjük ki per-plate lock state-et
            k.locked = locked
            table.insert(enriched, k)
        end
        SendNUIMessage({ action = 'setKeys', keys = enriched })
        -- Kulcskarika megnyitása szinkronizálás után
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'setVisible', visible = true })
    end
end)

RegisterNetEvent('nxn-keys:client:lockResult', function(data)
    if not data or not data.ok then
        if data and data.message == 'no_key' then
            Notify('Nincs kulcsod ehhez a járműhöz!', 'danger')
        end
        return
    end
    SendNUIMessage({ action = 'lockResult', plate = data.plate, locked = data.locked })
end)

RegisterNetEvent('nxn-keys:client:keyReceived', function(data)
    Notify(('Köszöntöd %s – átadták a(z) %s kulcsát!'):format(data.giverName, data.plate), 'success')
    -- Cache frissítés szinkronizálással
    TriggerServerEvent('nxn-keys:server:requestSync')
end)

RegisterNetEvent('nxn-keys:client:keyRevoked', function(data)
    if data and data.plate then
        keyCache[data.plate] = nil
        NXN.Keys.Log(('keyRevoked: plate=%s eltávolítva a cache-ből'):format(data.plate))
        if isRingOpen then
            SendNUIMessage({ action = 'setKeys', keys = GetCacheAsList() })
        end
        Notify(('A(z) %s kulcsa megvonva!'):format(data.plate), 'warning')
    end
end)

-- ── NUI Callbacks ────────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    isRingOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('lock', function(data, cb)
    local plate = NXN.Keys.NormalizePlate(data.plate or '')
    if plate == '' then cb('invalid') return end
    local isLocked = false
    if GetResourceState('nxn-engine') == 'started' then
        isLocked = exports['nxn-engine']:isLocked()
    end
    if GetResourceState('nxn-engine') == 'started' then
        exports['nxn-engine']:setLocked(not isLocked)
    end
    TriggerServerEvent(not isLocked and 'nxn-keys:server:lock' or 'nxn-keys:server:unlock', plate)
    cb('ok')
end)

RegisterNUICallback('giveKey', function(data, cb)
    local plate    = NXN.Keys.NormalizePlate(data.plate or '')
    local targetId = tonumber(data.targetId)
    if plate == '' or not targetId then cb('invalid') return end
    TriggerServerEvent('nxn-keys:server:giveKey', targetId, plate)
    cb('ok')
end)

RegisterNUICallback('removeKey', function(data, cb)
    local plate    = NXN.Keys.NormalizePlate(data.plate or '')
    local targetId = tonumber(data.targetId)
    if plate == '' or not targetId then cb('invalid') return end
    TriggerServerEvent('nxn-keys:server:removeKey', targetId, plate)
    cb('ok')
end)

RegisterNUICallback('getNearby', function(_, cb)
    cb(nearbyPlayers)
end)

-- ── Exportok (kliens) ───────────────────────────────────────────

--- Szinkron kulcsellenőrzés (auth callback-hez)
---@param plate string
---@return boolean
exports('hasKeyForPlate', function(plate)
    plate = NXN.Keys.NormalizePlate(plate or '')
    return keyCache[plate] ~= nil
end)

--- Kulcskarika UI megnyitása
exports('openKeyring', function()
    isRingOpen = true
    TriggerServerEvent('nxn-keys:server:getKeys')
    -- syncKeys event megjövetele után a setVisible action megnyítja
end)

--- Kulcskarika UI bezárása
exports('closeKeyring', function()
    isRingOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setVisible', visible = false })
end)

--- Nyitva van-e a kulcskarika
---@return boolean
exports('isKeyringOpen', function()
    return isRingOpen
end)
