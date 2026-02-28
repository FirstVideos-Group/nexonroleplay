-- ============================================================
--  nxn-els | server.lua
--  Szerver-oldali szinkron, jogosultságkezelés, export API
-- ============================================================

-- ── Állapottár ───────────────────────────────────────────────
-- Format: vehicleStates[netId] = { stage, muted, owner }
local vehicleStates = {}
-- Format: playerJobs[src] = { job, allowed }
local playerJobs    = {}

-- ── State update (kliens → szerver) ──────────────────────────

RegisterServerEvent('nxn-els:server:updateState', function(netId, stage, muted)
    local src = source
    -- Jogosultság ellenőrzés szerver oldalon is
    if not playerJobs[src] or not playerJobs[src].allowed then
        NXN.ELS.Warn(('updateState: Player %d nincs jogosultsaga!'):format(src))
        return
    end
    vehicleStates[netId] = { stage = stage, muted = muted, owner = src }
    NXN.ELS.Log(('updateState: netId=%d stage=%d muted=%s src=%d'):format(
        netId, stage, tostring(muted), src))
    -- Broadcast minden más kliensnek
    TriggerClientEvent('nxn-els:client:syncState', -1, netId, stage, muted)
end)

-- ── Sziréna hang szinkron ─────────────────────────────────────

RegisterServerEvent('nxn-els:server:setSirenSound', function(netId, tone)
    local src = source
    TriggerClientEvent('nxn-els:client:sirenSound', -1, netId, tone, src)
end)

-- ── Jogosultság megadása (nxn-police / nxn-ems stb. hívja) ───

RegisterServerEvent('nxn-els:server:setJobPermission', function(job, allowed)
    local src = source
    playerJobs[src] = { job = job, allowed = allowed and NXN.ELS.IsJobAllowed(job) }
    TriggerClientEvent('nxn-els:client:setJobPermission', src, job, allowed)
    NXN.ELS.Log(('setJobPermission: src=%d job=%s allowed=%s'):format(
        src, job, tostring(allowed)))
end)

-- ── Játékos kilép: cleanup ────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    playerJobs[src] = nil
    -- Nullázzuk az e játékos tulajdonában lévő jármű-állapotokat
    for netId, state in pairs(vehicleStates) do
        if state.owner == src then
            TriggerClientEvent('nxn-els:client:syncState', -1, netId, 0, false)
            vehicleStates[netId] = nil
        end
    end
    NXN.ELS.Log(('playerDropped: src=%d cleanup kesz'):format(src))
end)

-- ── Szerver Export API ────────────────────────────────────────

--- Visszaadja egy jármű ELS állapotát netId alapján
---@param netId number
---@return table|nil  { stage, muted, owner }
exports('getVehicleState', function(netId)
    return vehicleStates[netId]
end)

--- Visszaadja, hogy egy jármű ELS-e aktív-e
---@param netId number
---@return boolean
exports('isElsActive', function(netId)
    local s = vehicleStates[netId]
    return s ~= nil and s.stage > 0
end)

--- Visszaadja egy játékos ELS-jogosultságát
---@param src number  player source
---@return boolean
exports('playerHasPermission', function(src)
    return playerJobs[src] ~= nil and playerJobs[src].allowed == true
end)

--- Jogosultság megadása szerver-oldalról (nxn-police/nxn-ems hívja)
---@param src number
---@param job string
---@param allowed boolean
exports('setPlayerJobPermission', function(src, job, allowed)
    playerJobs[src] = { job = job, allowed = allowed and NXN.ELS.IsJobAllowed(job) }
    TriggerClientEvent('nxn-els:client:setJobPermission', src, job, allowed)
    NXN.ELS.Log(('setPlayerJobPermission: src=%d job=%s allowed=%s'):format(
        src, job, tostring(allowed)))
end)

--- Visszaadja az összes aktív ELS-állapotot
---@return table
exports('getAllVehicleStates', function()
    return vehicleStates
end)

--- Szerver-oldalról kényszeríti a stage-et egy jármüvön
---@param netId number
---@param stage number 0..3
exports('forceStage', function(netId, stage)
    vehicleStates[netId] = vehicleStates[netId] or { stage = 0, muted = false, owner = -1 }
    vehicleStates[netId].stage = stage
    TriggerClientEvent('nxn-els:client:syncState', -1, netId, stage, false)
end)
