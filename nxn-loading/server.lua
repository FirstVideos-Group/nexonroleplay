-- ============================================================
--  nxn-loading | server.lua
-- ============================================================

local queue      = {}   -- { src = true/false, ... } – várakozók sorban
local queueOrder = {}   -- ordered list of source IDs
local connected  = {}   -- src -> true, ha már bent van

-- ── Helpers ──────────────────────────────────────────────────

local function GetQueuePosition(src)
    for i, v in ipairs(queueOrder) do
        if v == src then return i end
    end
    return 0
end

local function BroadcastQueueUpdate()
    for i, src in ipairs(queueOrder) do
        TriggerClientEvent('nxn-loading:client:queueUpdate', src, {
            position = i,
            total    = #queueOrder
        })
    end
end

-- ── Connecting deferrals ─────────────────────────────────────

if Config.Queue.enabled then
    AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
        local src = source
        deferrals.defer()

        NXN.Loading.Log(('playerConnecting: %s (src=%s)'):format(name, src))

        Citizen.Wait(0)
        deferrals.update(('Üdvözölünk, %s! Betöltés folyamatban...'):format(name))

        local playerCount = #GetPlayers()
        if playerCount >= Config.Queue.maxPlayers then
            -- Helyezzük várólistára
            table.insert(queueOrder, src)
            queue[src] = true
            NXN.Loading.Log(('Queue: %s hozzáadva, pozíció: %d'):format(name, #queueOrder))
            BroadcastQueueUpdate()

            -- Várjunk amíg felszabadul hely
            while #GetPlayers() >= Config.Queue.maxPlayers do
                deferrals.update(('Várólista: %d. pozíció / %d várakozó'):format(
                    GetQueuePosition(src), #queueOrder))
                Citizen.Wait(Config.Queue.updateInterval)
            end

            -- Eltávolítás várólistáról
            for i, v in ipairs(queueOrder) do
                if v == src then table.remove(queueOrder, i) break end
            end
            queue[src] = nil
            BroadcastQueueUpdate()
        end

        deferrals.done()
        NXN.Loading.Log(('playerConnecting done: %s (src=%s)'):format(name, src))
    end)
end

-- ── Net events ───────────────────────────────────────────────

RegisterServerEvent('nxn-loading:server:playerReady', function()
    local src = source
    connected[src] = true
    NXN.Loading.Log(('playerReady: src=%s'):format(src))
    -- Értesítjük a clientet, hogy küldhetünk adatokat
    TriggerClientEvent('nxn-loading:client:serverData', src, {
        serverName  = Config.ServerName,
        description = Config.ServerDescription,
        rules       = Config.Rules,
        keybinds    = Config.Keybinds,
        maxPlayers  = Config.Queue.maxPlayers,
        online      = #GetPlayers()
    })
end)

RegisterServerEvent('nxn-loading:server:enterGame', function()
    local src = source
    NXN.Loading.Log(('enterGame: src=%s'):format(src))
    -- Jelezzük a kliensnek, hogy indíthatja a fade-et
    TriggerClientEvent('nxn-loading:client:doEnter', src)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    connected[src] = nil
    -- Eltávolítás várólistáról is, ha ott volt
    for i, v in ipairs(queueOrder) do
        if v == src then table.remove(queueOrder, i) break end
    end
    queue[src] = nil
    BroadcastQueueUpdate()
    NXN.Loading.Log(('playerDropped: src=%s reason=%s'):format(src, reason))
end)

-- ── Exports ──────────────────────────────────────────────────

--- Visszaadja a jelenlegi várólistát (pozíció -> src)
---@return table
exports('getQueue', function()
    return queueOrder
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
