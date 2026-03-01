-- ============================================================
--  nxn-identity | client.lua
--  Karakter letrehozas UI, skin alkalmazas, spawn, pozicio mentes
-- ============================================================

-- ── Allapot ────────────────────────────────────────────────
local identity  = nil   -- betoltott identitas
local uiOpen    = false
local camHandle = nil
-- #32: posSaveTimer eltavolitva – soha nem volt hasznalatban

-- ── Notify helper ─────────────────────────────────────────
-- #30: helyes nxn-notify exportok használata (nem 'send')
local function Notify(msg, t)
    if GetResourceState('nxn-notify') ~= 'started' then return end
    local ntype = t or 'info'
    if     ntype == 'success' then exports['nxn-notify']:success(msg)
    elseif ntype == 'danger'  then exports['nxn-notify']:danger(msg)
    elseif ntype == 'warning' then exports['nxn-notify']:warning(msg)
    else                           exports['nxn-notify']:info(msg)
    end
end

-- ── NUI Send (namespace + logging) ────────────────────────────
-- #33: NUISend wrapper helyett NXN.Identity.Send (konzisztens naplozassal)
function NXN.Identity.Send(data)
    NXN.Identity.Log(('NUI send: action=%s'):format(tostring(data and data.action)))
    SendNUIMessage(data)
end

-- ── Skin alkalmazas ─────────────────────────────────────────

--- Skin alkalmazasa a játékosra. Visszaadja az új PED handle-t (modellváltás után).
---@param ped  number  kiindulo PED (lehet elavult modelvals utan)
---@param data table   identitas sor
---@return number  az érvényes (esetleg új) PED handle
local function ApplySkin(ped, data)
    NXN.Identity.Log(('ApplySkin: gender=%d hair=%d color=%d eye=%d skin=%d'):format(
        data.gender or 0, data.hair_style or 0, data.hair_color or 0,
        data.eye_color or 0, data.skin_color or 0
    ))

    local model = data.gender == 1 and GetHashKey('mp_f_freemode_01') or GetHashKey('mp_m_freemode_01')
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(50) end
    end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    -- #31: modellvaltas utan frissitjuk a ped handle-t
    ped = PlayerPedId()

    SetPedHeadBlendData(ped,
        data.skin_color or 0, data.skin_color or 0, 0,
        data.skin_color or 0, data.skin_color or 0, 0,
        0.5, 0.5, 0.0, false
    )
    SetPedEyeColor(ped, data.eye_color or 0)

    local hairStyle = data.gender == 1
        and (Config.HairStylesFemale[data.hair_style + 1] or Config.HairStylesFemale[1]).value
        or  (Config.HairStylesMale [data.hair_style + 1] or Config.HairStylesMale [1]).value
    if hairStyle == 99 then
        SetPedComponentVariation(ped, 2, 0, 0, 2)
    else
        SetPedComponentVariation(ped, 2, hairStyle, 0, 2)
    end
    SetPedHairColor(ped, data.hair_color or 0, data.hair_highlight or 0)

    if data.face_features then
        local ok, ff = pcall(
            type(data.face_features) == 'table'
                and function() return data.face_features end
                or  json.decode,
            data.face_features
        )
        if ok and ff then
            for i, v in ipairs(ff) do
                SetPedFaceFeature(ped, i - 1, v)
            end
        end
    end

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
    -- #31: visszaadjuk az (esetleg frissitett) ped handle-t
    return ped
end

-- ── Spawn ────────────────────────────────────────────────

local function SpawnPlayer(data)
    local ped = PlayerPedId()
    -- #31: ApplySkin visszaadja az uj ped handle-t
    ped = ApplySkin(ped, data)

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

-- ── Letrehozas kamera ───────────────────────────────────────

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

-- ── Skin preview (NUI -> kliens real-time) ────────────────────────

RegisterNUICallback('previewSkin', function(data, cb)
    NXN.Identity.Log(('previewSkin: gender=%s hair=%s'):format(tostring(data.gender), tostring(data.hair_style)))
    -- #31: ApplySkin visszaadja az új ped-et; nem használjuk tovább, de garanciát ad a helyességre
    ApplySkin(PlayerPedId(), data)
    cb({ ok = true })
end)

-- ── Karakter mentes (NUI submit) ───────────────────────────────

RegisterNUICallback('createCharacter', function(data, cb)
    NXN.Identity.Log('createCharacter NUI callback meghivva')
    DestroyCreationCamera()
    SetNuiFocus(false, false)
    uiOpen = false
    NXN.Identity.Send({ action = 'close' })
    data.outfit = data.gender == 1 and Config.DefaultOutfitFemale or Config.DefaultOutfitMale
    TriggerServerEvent('nxn-identity:server:createIdentity', data)
    cb({ ok = true })
end)

-- ── Server eventek ───────────────────────────────────────────

RegisterNetEvent('nxn-identity:client:loaded')
AddEventHandler('nxn-identity:client:loaded', function(data)
    identity = data
    NXN.Identity.Info(('Identitas betoltve: %s %s'):format(data.firstname, data.lastname))
    DoScreenFadeOut(500)
    Wait(600)
    SpawnPlayer(data)
end)

RegisterNetEvent('nxn-identity:client:create')
AddEventHandler('nxn-identity:client:create', function()
    NXN.Identity.Info('Karakterletrehozas UI megnyitasa')
    DoScreenFadeOut(800)
    Wait(900)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetPlayerInvincible(PlayerId(), true)

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

    NXN.Identity.Send({
        action           = 'open',
        genders          = Config.Genders,
        eyeColors        = Config.EyeColors,
        skinColors       = Config.SkinColors,
        hairStylesMale   = Config.HairStylesMale,
        hairStylesFemale = Config.HairStylesFemale,
        hairColors       = Config.HairColors,
        birthYearMin     = Config.BirthYearMin,
        birthYearMax     = Config.BirthYearMax,
    })

    SetNuiFocus(true, true)
    uiOpen = true
end)

-- ── Pozicio mentes loop ───────────────────────────────────────

CreateThread(function()
    while true do
        Wait(Config.PositionSaveInterval * 1000)
        if identity then
            local ped = PlayerPedId()
            local c   = GetEntityCoords(ped)
            local h   = GetEntityHeading(ped)
            TriggerServerEvent('nxn-identity:server:savePosition', c.x, c.y, c.z, h)
            NXN.Identity.Log(('Pozicio mentve: %.1f %.1f %.1f h=%.1f'):format(c.x, c.y, c.z, h))
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= Config.ResourceName then return end
    if not identity then return end
    local ped = PlayerPedId()
    local c   = GetEntityCoords(ped)
    local h   = GetEntityHeading(ped)
    TriggerServerEvent('nxn-identity:server:savePosition', c.x, c.y, c.z, h)
end)

-- ── Kliens exportok ───────────────────────────────────────────

exports('getIdentity', function()
    return identity
end)

--- #31: ApplySkin visszaadja az uj ped handle-t
exports('reapplySkin', function()
    if identity then
        ApplySkin(PlayerPedId(), identity)
    end
end)

exports('hasIdentity', function()
    return identity ~= nil
end)
