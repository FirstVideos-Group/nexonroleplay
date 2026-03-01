-- ============================================================
--  nxn-loading | server.lua
-- ============================================================

-- #55: `queue` tábla eltávolítva – duplikált állapot volt a `queueOrder`-rel.
-- "Benne van-e" ellenőrzéshez GetQueuePosition(src) > 0 használandó.
local queueOrder = {}   -- ordered list of source IDs
local connected  = {}   -- src -> true, ha már bent van

-- ── Helpers ──────────────────────────────────────────────────────

local function GetQueuePosition(src)
    for i, v in ipairs(queueOrder) do
        if v == src then return i end
    end
    return 0
end

local function RemoveFromQueue(src)
    for i, v in ipairs(queueOrder) do
        if v == src then
            table.remove(queueOrder, i)
            break
        end
    end
end

local function BroadcastQueueUpdate()
    for i, src in ipairs(queueOrder) do
        TriggerClientEvent('nxn-loading:client:queueUpdate', src, {
            position = i,
            total    = #queueOrder
        })
    end
end

-- ── Connecting deferrals ─────────────────────────────────────────

if Config.Queue.enabled then
    -- #62: FiveM deferrals.update() minimum 1000ms – runtime guard
    local safeInterval = math.max(1000, Config.Queue.updateInterval)

    AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
        local src = source
        deferrals.defer()

        NXN.Loading.Log(('playerConnecting: %s (src=%s)'):format(name, src))

        Citizen.Wait(0)
        deferrals.update(('Üdvözölünk, %s! Betöltés folyamatban...'):format(name))

        if #GetPlayers() >= Config.Queue.maxPlayers then
            -- Helyezzük várólistára
            table.insert(queueOrder, src)
            NXN.Loading.Log(('Queue: %s hozzáadva, pozíció: %d'):format(name, #queueOrder))
            BroadcastQueueUpdate()

            -- #56: disconnected flag – ha a játékos disconnect-el várakozás
            -- közben, ne hívjuk meg a deferrals.done()-t egy halott kapcsolaton
            local disconnected = false
            local dropHandler = AddEventHandler('playerDropped', function()
                if source == src then
                    disconnected = true
                end
            end)

            -- Várjunk amíg felszabadul hely VAGY a játékos disconnectelt
            while not disconnected and #GetPlayers() >= Config.Queue.maxPlayers do
                deferrals.update(('Várólista: %d. pozíció / %d várakozó'):format(
                    GetQueuePosition(src), #queueOrder))
                Citizen.Wait(safeInterval)
            end

            RemoveEventHandler(dropHandler)

            -- Ha közben disconnectelt, ne folytassuk
            if disconnected then
                NXN.Loading.Log(('Queue: %s disconnect közben várakozás alatt, kihagyva'):format(name))
                return
            end

            -- Eltávolítás várólistáról
            RemoveFromQueue(src)
            BroadcastQueueUpdate()
        end

        deferrals.done()
        NXN.Loading.Log(('playerConnecting done: %s (src=%s)'):format(name, src))
    end)
end

-- ── Net events ────────────────────────────────────────────────

RegisterServerEvent('nxn-loading:server:playerReady', function()
    local src = source
    connected[src] = true
    NXN.Loading.Log(('playerReady: src=%s'):format(src))
    TriggerClientEvent('nxn-loading:client:serverData', src, {
        serverName  = Config.ServerName,
        description = Config.ServerDescription,
        rules       = Config.Rules,
        keybinds    = Config.Keybinds,
        maxPlayers  = Config.Queue.maxPlayers,
        online      = #GetPlayers()
    })
end)

-- #58: enterGame handler connected[src] guard – megakadályozza a loading
-- screen megkerülését (bármely kliens triggerelhette volna, playerReady nélkül)
RegisterServerEvent('nxn-loading:server:enterGame', function()
    local src = source
    if not connected[src] then
        NXN.Loading.Warn(('enterGame: src=%d nem küldött playerReady-t, elutasítva'):format(src))
        return
    end
    NXN.Loading.Log(('enterGame: src=%s'):format(src))
    TriggerClientEvent('nxn-loading:client:doEnter', src)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    connected[src] = nil
    RemoveFromQueue(src)
    BroadcastQueueUpdate()
    NXN.Loading.Log(('playerDropped: src=%s reason=%s'):format(src, reason))
end)

-- ── Exports ────────────────────────────────────────────────────

--- #57: getQueue shallow copy – referencia helyett másolatot ad vissza
--- Megakadályozza, hogy külső resource közvetlenül módosítsa a várólistát
---@return table
exports('getQueue', function()
    local copy = {}
    for i, v in ipairs(queueOrder) do copy[i] = v end
    return copy
end)

--- Visszaadja a várakozó játékosok számát
---@return integer
exports('getQueueLength', function()
    return #queueOrder
end)

--- Visszaadja, hogy egy src belépett-e már
---@param src integer
---@return boolean
exports('isPlayerConnected', function(src)
    return connected[src] == true
end)

--- Manuálisan dobja be a játékost (más resource hívhatja)
---@param src integer
exports('forceEnter', function(src)
    TriggerClientEvent('nxn-loading:client:doEnter', src)
end)
