-- ============================================================
--  nxn-identity | client.lua
--  Karakter letrehozas UI, skin alkalmazas, spawn, pozicio mentes
-- ============================================================

-- ── Allapot ─────────────────────────────────────────────────
local identity   = nil    -- betoltott identitas
local uiOpen     = false
local camHandle  = nil
local posSaveTimer = 0

-- ── Notify helper ───────────────────────────────────────────
local function Notify(msg, t)
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:send(msg, t or 'info')
    end
end

-- ── Skin alkalmazas ──────────────────────────────────────────

---@param ped    number
---@param data   table  identitas sor
local function ApplySkin(ped, data)
    NXN.Identity.Log(('ApplySkin: gender=%d hair=%d color=%d eye=%d skin=%d'):format(
        data.gender or 0, data.hair_style or 0, data.hair_color or 0,
        data.eye_color or 0, data.skin_color or 0
    ))

    -- Alap model
    local model = data.gender == 1 and GetHashKey('mp_f_freemode_01') or GetHashKey('mp_m_freemode_01')
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(50) end
    end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    ped = PlayerPedId()

    -- Szin beallitasok
    SetPedHeadBlendData(ped, data.skin_color or 0, data.skin_color or 0, 0, data.skin_color or 0, data.skin_color or 0, 0, 0.5, 0.5, 0.0, false)
    SetPedEyeColor(ped, data.eye_color or 0)

    -- Haj
    local hairStyle = data.gender == 1
        and (Config.HairStylesFemale[data.hair_style + 1] or Config.HairStylesFemale[1]).value
        or  (Config.HairStylesMale [data.hair_style + 1] or Config.HairStylesMale [1]).value
    if hairStyle == 99 then
        SetPedComponentVariation(ped, 2, 0, 0, 2)
    else
        SetPedComponentVariation(ped, 2, hairStyle, 0, 2)
    end
    SetPedHairColor(ped, data.hair_color or 0, data.hair_highlight or 0)

    -- Face features (arcvonasok)
    if data.face_features then
        local ok, ff = pcall(type(data.face_features) == 'table' and function() return data.face_features end or json.decode, data.face_features)
        if ok and ff then
            for i, v in ipairs(ff) do
                SetPedFaceFeature(ped, i - 1, v)
            end
        end
    end

    -- Ruhak
    local outfit = nil
    if data.outfit then
        if type(data.outfit) == 'table' then
            outfit = data.outfit
        else
            local ok, o = pcall(json.decode, data.outfit)
            if ok then outfit = o end
        end
    end

    if not outfit then
        outfit = data.gender == 1 and Config.DefaultOutfitFemale or Config.DefaultOutfitMale
    end

    for _, comp in ipairs(outfit) do
        SetPedComponentVariation(ped, comp[1], comp[2], comp[3], 2)
    end

    NXN.Identity.Log('ApplySkin kesz')
end

-- ── Spawn ──────────────────────────────────────────────────

local function SpawnPlayer(data)
    local ped = PlayerPedId()

    -- Skin
    ApplySkin(ped, data)
    ped = PlayerPedId()  -- model valtas utan ujra lekerjuk

    -- Pozicio
    local x = data.pos_x
    local y = data.pos_y
    local z = data.pos_z
    local h = data.pos_heading

    if x and y and z then
        NXN.Identity.Log(('Spawn mentett pozicion: %.1f %.1f %.1f'):format(x, y, z))
    else
        x = Config.DefaultSpawn.x
        y = Config.DefaultSpawn.y
        z = Config.DefaultSpawn.z
        h = Config.DefaultSpawn.heading
        NXN.Identity.Log('Spawn alapertelmezett helyen')
    end

    SetEntityCoords(ped, x, y, z, false, false, false, false)
    SetEntityHeading(ped, h or 0.0)
    FreezeEntityPosition(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    DoScreenFadeIn(1200)

    NXN.Identity.Info(('Jatekos spawnolva: %s %s'):format(data.firstname, data.lastname))
    TriggerEvent('nxn-identity:client:spawned', { identity = data })
end

-- ── Karakter letrehozas kamera ──────────────────────────────────

local function SetupCreationCamera()
    local cfg = Config.CreationCamera
    camHandle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(camHandle, cfg.pos.x, cfg.pos.y, cfg.pos.z)
    PointCamAtCoord(camHandle, cfg.lookAt.x, cfg.lookAt.y, cfg.lookAt.z)
    SetCamActive(camHandle, true)
    RenderScriptCams(true, true, 500, true, false)
    NXN.Identity.Log('Letrehozas kamera aktiv')
end

local function DestroyCreationCamera()
    if camHandle then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(camHandle, false)
        camHandle = nil
        NXN.Identity.Log('Letrehozas kamera megszuntetve')
    end
end

-- ── NUI kuldese ─────────────────────────────────────────────
local function NUISend(data)
    SendNUIMessage(data)
end

-- ── Skin preview (NUI -> kliens real-time) ──────────────────────

RegisterNUICallback('previewSkin', function(data, cb)
    local ped = PlayerPedId()
    NXN.Identity.Log(('previewSkin: gender=%s hair=%s'):format(tostring(data.gender), tostring(data.hair_style)))
    ApplySkin(ped, data)
    cb({ ok = true })
end)

-- ── Karakter mentes (NUI submit) ───────────────────────────────

RegisterNUICallback('createCharacter', function(data, cb)
    NXN.Identity.Log('createCharacter NUI callback meghivva')

    -- Alapos validacio szerveren tortenik, itt csak UI zarjuk
    DestroyCreationCamera()
    SetNuiFocus(false, false)
    uiOpen = false
    NUISend({ action = 'close' })

    -- Ruhak a configbol
    data.outfit = data.gender == 1 and Config.DefaultOutfitFemale or Config.DefaultOutfitMale

    TriggerServerEvent('nxn-identity:server:createIdentity', data)
    cb({ ok = true })
end)

-- ── Server eventek ─────────────────────────────────────────────

-- Meglevo identitas -> spawn
RegisterNetEvent('nxn-identity:client:loaded')
AddEventHandler('nxn-identity:client:loaded', function(data)
    identity = data
    NXN.Identity.Info(('Identitas betoltve: %s %s'):format(data.firstname, data.lastname))
    DoScreenFadeOut(500)
    Wait(600)
    SpawnPlayer(data)
end)

-- Uj jatekos -> karakterletrehozas UI
RegisterNetEvent('nxn-identity:client:create')
AddEventHandler('nxn-identity:client:create', function()
    NXN.Identity.Info('Karakterletrehozas UI megnyitasa')

    -- Elokeszites: fade out, kamera, ped elhelyezese
    DoScreenFadeOut(800)
    Wait(900)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetPlayerInvincible(PlayerId(), true)

    -- Alapertelmezett male model a previewhoz
    local model = GetHashKey('mp_m_freemode_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(50) end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    ped = PlayerPedId()

    local cfg = Config.CreationCamera
    SetEntityCoords(ped, cfg.lookAt.x, cfg.lookAt.y, cfg.lookAt.z, false, false, false, false)

    SetupCreationCamera()
    DoScreenFadeIn(600)

    -- Config kuldese a UI-nek
    NUISend({
        action        = 'open',
        genders       = Config.Genders,
        eyeColors     = Config.EyeColors,
        skinColors    = Config.SkinColors,
        hairStylesMale   = Config.HairStylesMale,
        hairStylesFemale = Config.HairStylesFemale,
        hairColors    = Config.HairColors,
        birthYearMin  = Config.BirthYearMin,
        birthYearMax  = Config.BirthYearMax,
    })

    SetNuiFocus(true, true)
    uiOpen = true
end)

-- ── Pozicio mentes loop ─────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(Config.PositionSaveInterval * 1000)
        if identity then
            local ped = PlayerPedId()
            local c = GetEntityCoords(ped)
            local h = GetEntityHeading(ped)
            TriggerServerEvent('nxn-identity:server:savePosition', c.x, c.y, c.z, h)
            NXN.Identity.Log(('Pozicio mentve: %.1f %.1f %.1f h=%.1f'):format(c.x, c.y, c.z, h))
        end
    end
end)

-- Kilépéskor pozicio mentes
AddEventHandler('onResourceStop', function(res)
    if res ~= Config.ResourceName then return end
    if not identity then return end
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    TriggerServerEvent('nxn-identity:server:savePosition', c.x, c.y, c.z, h)
end)

-- ── Kliens exportok ────────────────────────────────────────────

--- Helyi identitas adat (kliens oldali)
---@return table|nil
exports('getIdentity', function()
    return identity
end)

--- Skin ujraalkalmaza (pl. ruha valtas utan)
exports('reapplySkin', function()
    if identity then
        ApplySkin(PlayerPedId(), identity)
    end
end)

--- Van-e betoltott identitas
---@return boolean
exports('hasIdentity', function()
    return identity ~= nil
end)
