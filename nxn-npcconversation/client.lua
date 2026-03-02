-- ============================================================
--  nxn-npcconversation | client.lua
--  NPC spawnolos, interakcio, UI kezelese, export API
-- ============================================================

-- ── Runtime allapot ─────────────────────────────────────────────────────

local spawnedNPCs     = {}   -- { id -> { ped, blip, config } }
local extraDialogues  = {}   -- { npcId -> { { id, label, icon, response, event } } }
local isUIOpen        = false
local currentNPCId    = nil

-- #87: resource stop flag – SpawnNPC model-betoltesi loop korai kilepes
local resourceStopped = false

-- #90: runtime-regisztralt NPC-k kulonvalasztva a statikus Config.NPCs-tol
local runtimeNPCs = {}

-- ── NUI seged ────────────────────────────────────────────────────────

-- #85: shallow copy payload
local function NUISend(action, data)
    local payload = { action = action }
    if data then
        for k, v in pairs(data) do payload[k] = v end
    end
    NXN.NPC.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

-- ── NPC config keresés (config + runtime) ─────────────────────────────────

-- #90: segéd – config.lua VAGY runtimeNPCs-ből adja vissza az NPC configját
local function GetNPCConfig(npcId)
    return Config.NPCs[npcId] or runtimeNPCs[npcId]
end

-- ── NPC spawn ────────────────────────────────────────────────────────

---@param npcId  string
---@param cfg    table
local function SpawnNPC(npcId, cfg)
    -- #88: ghost entry ellenorzes
    if spawnedNPCs[npcId] then
        if DoesEntityExist(spawnedNPCs[npcId].ped) then
            return
        else
            NXN.NPC.Warn(('SpawnNPC: ghost entry, ujraspawn: %s'):format(npcId))
            if spawnedNPCs[npcId].blip then RemoveBlip(spawnedNPCs[npcId].blip) end
            spawnedNPCs[npcId] = nil
        end
    end

    local modelHash = GetHashKey(cfg.model)
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        t = t + 1
        -- Timeout 150 iter x 100ms = 15 masodperc.
        -- Korabban 50 iter (5s) volt, ami lassabb klienseken / nagy szerveren
        -- nem volt eleg a GTA streaming engine-nek, ezert dobta a WARN-t.
        if t > 150 or resourceStopped then
            if t > 150 then NXN.NPC.Warn(('Model betoltesi timeout: %s'):format(cfg.model)) end
            return
        end
    end

    -- #87: extra ellenorzes a Wait utan
    if resourceStopped then return end

    local c   = cfg.coords
    local ped = CreatePed(4, modelHash, c.x, c.y, c.z - 1.0, c.w, false, true)

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    if cfg.scenario and cfg.scenario ~= '' then
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    end

    local blip = nil
    if cfg.blip and cfg.blip.enabled then
        blip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(blip, cfg.blip.sprite or 446)
        SetBlipColour(blip, cfg.blip.color or 0)
        SetBlipScale(blip, cfg.blip.scale or 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(cfg.blip.label or cfg.label)
        EndTextCommandSetBlipName(blip)
    end

    SetModelAsNoLongerNeeded(modelHash)

    spawnedNPCs[npcId] = { ped = ped, blip = blip, config = cfg }
    NXN.NPC.Log(('NPC spawned: %s ped=%d'):format(npcId, ped))
end

---@param npcId string
local function DespawnNPC(npcId)
    local entry = spawnedNPCs[npcId]
    if not entry then return end
    if entry.blip then RemoveBlip(entry.blip) end
    if DoesEntityExist(entry.ped) then DeletePed(entry.ped) end
    spawnedNPCs[npcId] = nil
    NXN.NPC.Log(('NPC despawned: %s'):format(npcId))
end

-- ── Dialogus lista osszegyujtese ───────────────────────────────────────────

---@param npcId string
---@return table
local function GetDialogues(npcId)
    local npcCfg = GetNPCConfig(npcId)
    local base   = (npcCfg and npcCfg.dialogues) or {}
    local extras = extraDialogues[npcId] or {}
    local merged = {}
    for _, d in ipairs(base)   do table.insert(merged, d) end
    for _, d in ipairs(extras) do table.insert(merged, d) end
    return merged
end

-- ── UI nyitas / zaras ────────────────────────────────────────────────

local function OpenConversation(npcId)
    local entry = spawnedNPCs[npcId]
    if not entry then
        NXN.NPC.Warn(('OpenConversation: NPC nem letezik: %s'):format(npcId))
        return
    end

    currentNPCId = npcId
    isUIOpen     = true
    SetNuiFocus(true, true)

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TaskTurnPedToFaceCoord(entry.ped, coords.x, coords.y, coords.z, -1)

    local dialogues = GetDialogues(npcId)
    NXN.NPC.Log(('OpenConversation: %s, %d opció'):format(npcId, #dialogues))

    NUISend('open', {
        npcId     = npcId,
        npcLabel  = entry.config.label,
        dialogues = dialogues,
    })
end

local function CloseConversation()
    if not isUIOpen then return end
    isUIOpen     = false
    currentNPCId = nil
    SetNuiFocus(false, false)
    NUISend('close', {})
    NXN.NPC.Log('ConversationUI bezarva')
end

-- ── NUI callbackok ────────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    CloseConversation()
    cb('ok')
end)

-- #89: selectOption whitelist validacio
RegisterNUICallback('selectOption', function(data, cb)
    local npcId    = data.npcId
    local optionId = data.optionId
    local response = data.response

    NXN.NPC.Log(('selectOption: npc=%s option=%s'):format(tostring(npcId), tostring(optionId)))

    local allowedEvent = nil
    local npcCfg = GetNPCConfig(npcId)
    if npcCfg and npcCfg.dialogues then
        for _, d in ipairs(npcCfg.dialogues) do
            if d.id == optionId then
                allowedEvent = d.event
                break
            end
        end
    end
    if not allowedEvent and extraDialogues[npcId] then
        for _, d in ipairs(extraDialogues[npcId]) do
            if d.id == optionId then
                allowedEvent = d.event
                break
            end
        end
    end

    NUISend('showResponse', { response = response or '' })

    if allowedEvent and allowedEvent ~= '' then
        TriggerEvent(allowedEvent, { npcId = npcId, optionId = optionId })
        NXN.NPC.Log(('Event kivaltas (whitelist OK): %s'):format(allowedEvent))
    end

    cb('ok')
end)

-- ── Kozelitesi interakcios loop ─────────────────────────────────────────────

-- #86: Proximity check kulonvalasztva az input check-tol
local nearestNPC = nil

CreateThread(function()
    while true do
        Wait(250)
        if resourceStopped then return end

        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local best   = nil
        local bestDist = Config.HintDistance

        for npcId, entry in pairs(spawnedNPCs) do
            if DoesEntityExist(entry.ped) then
                local npcCoords = GetEntityCoords(entry.ped)
                local dist = #(coords - npcCoords)
                if dist < bestDist then
                    bestDist = dist
                    best = { id = npcId, entry = entry, dist = dist }
                end
            end
        end

        nearestNPC = best
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if resourceStopped then return end

        local nearest = nearestNPC
        if nearest and not isUIOpen then
            if nearest.dist < Config.InteractDistance then
                local txt = ('[%s] Beszelgetes: %s'):format(
                    Config.InteractKeyLabel,
                    nearest.entry.config.label
                )
                SetTextComponentFormat('STRING')
                AddTextComponentString(txt)
                DisplayHelpTextFromStringLabel(0, false, true, -1)

                if IsControlJustReleased(0, Config.InteractKey) then
                    OpenConversation(nearest.id)
                end
            end
        end

        if isUIOpen and IsControlJustReleased(0, 177) then
            CloseConversation()
        end
    end
end)

-- ── Inicializalas spawnnnal ──────────────────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.NPC.Log('playerSpawned – NPCek inicializalasa')
    -- 3000ms delay: a GTA streaming engine-nek tobb idot adunk inicializalodni,
    -- igy elkeruljuk a korai model-betoltesi timeoutokat (korabban 1000ms volt).
    Wait(3000)
    for npcId, cfg in pairs(Config.NPCs) do
        if cfg.enabled ~= false then
            SpawnNPC(npcId, cfg)
        end
    end
end)

-- #87: resource stop flag beallitasa + cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= Config.ResourceName then return end
    resourceStopped = true
    for npcId in pairs(spawnedNPCs) do
        DespawnNPC(npcId)
    end
    NXN.NPC.Log('onResourceStop: osszes NPC eltavolitva')
end)

-- ── Exportok ─────────────────────────────────────────────────────────

-- #90: registerNPC / unregisterNPC a runtimeNPCs tablat hasznallja
exports('registerNPC', function(npcId, cfg)
    if Config.NPCs[npcId] or runtimeNPCs[npcId] then
        NXN.NPC.Warn(('registerNPC: ID mar foglalt: %s'):format(npcId))
        return false
    end
    NXN.NPC.Log(('registerNPC: %s'):format(npcId))
    runtimeNPCs[npcId] = cfg
    SpawnNPC(npcId, cfg)
    return true
end)

exports('unregisterNPC', function(npcId)
    NXN.NPC.Log(('unregisterNPC: %s'):format(npcId))
    DespawnNPC(npcId)
    runtimeNPCs[npcId] = nil
end)

exports('addDialogue', function(npcId, option)
    if not option or not option.id then
        NXN.NPC.Warn('addDialogue: hianyzik az option.id')
        return false
    end
    if not extraDialogues[npcId] then extraDialogues[npcId] = {} end
    for _, d in ipairs(extraDialogues[npcId]) do
        if d.id == option.id then
            NXN.NPC.Warn(('addDialogue: duplikat ID: %s/%s'):format(npcId, option.id))
            return false
        end
    end
    table.insert(extraDialogues[npcId], option)
    NXN.NPC.Log(('addDialogue: %s -> %s'):format(npcId, option.id))
    if isUIOpen and currentNPCId == npcId then
        NUISend('updateDialogues', { dialogues = GetDialogues(npcId) })
    end
    return true
end)

exports('removeDialogue', function(npcId, optionId)
    if not extraDialogues[npcId] then return false end
    for i, d in ipairs(extraDialogues[npcId]) do
        if d.id == optionId then
            table.remove(extraDialogues[npcId], i)
            NXN.NPC.Log(('removeDialogue: %s/%s'):format(npcId, optionId))
            if isUIOpen and currentNPCId == npcId then
                NUISend('updateDialogues', { dialogues = GetDialogues(npcId) })
            end
            return true
        end
    end
    return false
end)

exports('openConversation', function(npcId)
    OpenConversation(npcId)
end)

exports('closeConversation', function()
    CloseConversation()
end)

exports('spawnNPC', function(npcId)
    local cfg = GetNPCConfig(npcId)
    if not cfg then
        NXN.NPC.Warn(('spawnNPC: ismeretlen NPC: %s'):format(npcId))
        return false
    end
    SpawnNPC(npcId, cfg)
    return true
end)

exports('despawnNPC', function(npcId)
    DespawnNPC(npcId)
end)

exports('getSpawnedNPCs', function()
    local result = {}
    for id, entry in pairs(spawnedNPCs) do
        result[id] = {
            ped    = entry.ped,
            label  = entry.config.label,
            model  = entry.config.model,
            coords = entry.config.coords,
        }
    end
    return result
end)

exports('getCurrentNPC', function()
    return currentNPCId
end)

exports('isConversationOpen', function()
    return isUIOpen
end)
