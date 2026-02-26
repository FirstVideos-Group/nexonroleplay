-- ============================================================
--  nxn-npcconversation | client.lua
--  NPC spawnolos, interakcio, UI kezelese, export API
-- ============================================================

-- ── Runtime allapot ───────────────────────────────────────────

local spawnedNPCs     = {}   -- { id -> { ped, blip, config } }
local extraDialogues  = {}   -- { npcId -> { { id, label, icon, response, event } } }
local isUIOpen        = false
local currentNPCId    = nil

-- ── NUI segéd ─────────────────────────────────────────────────

local function NUISend(action, data)
    local payload = data or {}
    payload.action = action
    NXN.NPC.Log(('NUI send: action=%s'):format(action))
    SendNUIMessage(payload)
end

-- ── NPC spawn ────────────────────────────────────────────────

---@param npcId  string
---@param cfg    table
local function SpawnNPC(npcId, cfg)
    if spawnedNPCs[npcId] then return end  -- mar letezik

    local modelHash = GetHashKey(cfg.model)
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        t = t + 1
        if t > 50 then
            NXN.NPC.Warn(('Model betoltesi timeout: %s'):format(cfg.model))
            return
        end
    end

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

    -- Blip
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
    if DoesEntityExist(entry.ped) then
        DeletePed(entry.ped)
    end
    spawnedNPCs[npcId] = nil
    NXN.NPC.Log(('NPC despawned: %s'):format(npcId))
end

-- ── Dialogus lista osszegyujtese ─────────────────────────────────

---@param npcId string
---@return table
local function GetDialogues(npcId)
    local base   = (Config.NPCs[npcId] and Config.NPCs[npcId].dialogues) or {}
    local extras = extraDialogues[npcId] or {}
    local merged = {}
    for _, d in ipairs(base)   do table.insert(merged, d) end
    for _, d in ipairs(extras) do table.insert(merged, d) end
    return merged
end

-- ── UI nyitas / zaras ───────────────────────────────────────────

local function OpenConversation(npcId)
    local entry = spawnedNPCs[npcId]
    if not entry then
        NXN.NPC.Warn(('OpenConversation: NPC nem letezik: %s'):format(npcId))
        return
    end

    currentNPCId = npcId
    isUIOpen     = true
    SetNuiFocus(true, true)

    -- NPC nez a jatekosra
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

-- ── NUI callbackok ─────────────────────────────────────────────

-- Bezaras NUI-bol
RegisterNUICallback('close', function(_, cb)
    CloseConversation()
    cb('ok')
end)

-- Opció kivalasztasa
RegisterNUICallback('selectOption', function(data, cb)
    local npcId     = data.npcId
    local optionId  = data.optionId
    local response  = data.response
    local eventName = data.event

    NXN.NPC.Log(('selectOption: npc=%s option=%s event=%s'):format(
        tostring(npcId), tostring(optionId), tostring(eventName)
    ))

    -- NPC valasz kuldese a UI-nak
    NUISend('showResponse', {
        response = response or '',
    })

    -- Ha van event, kivaltjuk
    if eventName and eventName ~= '' then
        TriggerEvent(eventName, { npcId = npcId, optionId = optionId })
        NXN.NPC.Log(('Event kivaltas: %s'):format(eventName))
    end

    cb('ok')
end)

-- ── Kozelitesi interakcios loop ─────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)

        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local nearest = nil
        local nearestDist = 99999

        for npcId, entry in pairs(spawnedNPCs) do
            if DoesEntityExist(entry.ped) then
                local npcCoords = GetEntityCoords(entry.ped)
                local dist = #(coords - npcCoords)

                if dist < nearestDist then
                    nearestDist = dist
                    nearest = { id = npcId, entry = entry, dist = dist }
                end
            end
        end

        if nearest and nearest.dist < Config.HintDistance and not isUIOpen then
            -- Megjeleniti a hint szoveget
            if nearest.dist < Config.InteractDistance then
                -- Interakcio eleg kozel
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

        -- ESC / Backspace bezar
        if isUIOpen and IsControlJustReleased(0, 177) then
            CloseConversation()
        end

        Wait(isUIOpen and 100 or 0)
    end
end)

-- ── Inicializalas spawnnnal ───────────────────────────────────────

AddEventHandler('playerSpawned', function()
    NXN.NPC.Log('playerSpawned – NPCek inicializalasa')
    Wait(1000)
    for npcId, cfg in pairs(Config.NPCs) do
        if cfg.enabled ~= false then
            SpawnNPC(npcId, cfg)
        end
    end
end)

-- Cleanup kilepes elott
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= Config.ResourceName then return end
    for npcId in pairs(spawnedNPCs) do
        DespawnNPC(npcId)
    end
end)

-- ── Exportok ─────────────────────────────────────────────────

--- Uj NPC regisztralasa mas resource-bol
---@param npcId  string  egyedi azonosito
---@param cfg    table   { label, model, coords, scenario, blip, dialogues }
exports('registerNPC', function(npcId, cfg)
    if Config.NPCs[npcId] then
        NXN.NPC.Warn(('registerNPC: ID mar foglalt: %s'):format(npcId))
        return false
    end
    NXN.NPC.Log(('registerNPC: %s'):format(npcId))
    Config.NPCs[npcId] = cfg
    SpawnNPC(npcId, cfg)
    return true
end)

--- NPC eltavolitasa
---@param npcId string
exports('unregisterNPC', function(npcId)
    NXN.NPC.Log(('unregisterNPC: %s'):format(npcId))
    DespawnNPC(npcId)
    Config.NPCs[npcId] = nil
end)

--- Extra dialógus opcio hozzaadasa egy NPC-hez (mas resource)
---@param npcId  string
---@param option table  { id, label, icon, response, event }
---@return boolean
exports('addDialogue', function(npcId, option)
    if not option or not option.id then
        NXN.NPC.Warn('addDialogue: hianyzik az option.id')
        return false
    end
    if not extraDialogues[npcId] then
        extraDialogues[npcId] = {}
    end
    -- ID egyediseg ellenorzes
    for _, d in ipairs(extraDialogues[npcId]) do
        if d.id == option.id then
            NXN.NPC.Warn(('addDialogue: duplikat ID: %s/%s'):format(npcId, option.id))
            return false
        end
    end
    table.insert(extraDialogues[npcId], option)
    NXN.NPC.Log(('addDialogue: %s -> %s'):format(npcId, option.id))
    -- Ha eppen nyitva van ez az NPC menuje, frissitjuk
    if isUIOpen and currentNPCId == npcId then
        local dialogues = GetDialogues(npcId)
        NUISend('updateDialogues', { dialogues = dialogues })
    end
    return true
end)

--- Extra dialogus eltavolitasa
---@param npcId    string
---@param optionId string
exports('removeDialogue', function(npcId, optionId)
    if not extraDialogues[npcId] then return false end
    for i, d in ipairs(extraDialogues[npcId]) do
        if d.id == optionId then
            table.remove(extraDialogues[npcId], i)
            NXN.NPC.Log(('removeDialogue: %s/%s'):format(npcId, optionId))
            if isUIOpen and currentNPCId == npcId then
                local dialogues = GetDialogues(npcId)
                NUISend('updateDialogues', { dialogues = dialogues })
            end
            return true
        end
    end
    return false
end)

--- Beszelgetes kenyszer megnyitasa kulsOrol
---@param npcId string
exports('openConversation', function(npcId)
    OpenConversation(npcId)
end)

--- Beszelgetes bezarasa
exports('closeConversation', function()
    CloseConversation()
end)

--- NPC manualis spawnolasa
---@param npcId string
exports('spawnNPC', function(npcId)
    local cfg = Config.NPCs[npcId]
    if not cfg then
        NXN.NPC.Warn(('spawnNPC: ismeretlen NPC: %s'):format(npcId))
        return false
    end
    SpawnNPC(npcId, cfg)
    return true
end)

--- NPC despawnolasa
---@param npcId string
exports('despawnNPC', function(npcId)
    DespawnNPC(npcId)
end)

--- Letrehozott NPC listaja
---@return table
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

--- Jelenlegi beszelgetesben levo NPC
---@return string|nil
exports('getCurrentNPC', function()
    return currentNPCId
end)

--- UI nyitva van-e
---@return boolean
exports('isConversationOpen', function()
    return isUIOpen
end)
