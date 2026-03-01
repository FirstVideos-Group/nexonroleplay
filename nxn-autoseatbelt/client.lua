-- ============================================================
--  nxn-autoseatbelt | client.lua
--  Automatikus biztonsagi ov: jarmutipus-alapu auto-bekotes
-- ============================================================

-- ── Allapot ───────────────────────────────────────────────────

local autoEnabled    = true    -- kulsoleg ki/be kapcsolhato
local inVehicle      = false
local lastVehicle    = 0
local pendingFasten  = false   -- varjuk-e meg a kesleltetes letetelere
local fastenSession  = 0       -- race condition elleni session szamlalo

-- ── Lookup set-ek (gyors ellenorzes) ───────────────────────────

local autoClassSet     = {}
local excludedClassSet = {}
local autoModelSet     = {}
local excludedModelSet = {}

for _, c in ipairs(Config.AutoClasses)     do autoClassSet[c]         = true end
for _, c in ipairs(Config.ExcludedClasses) do excludedClassSet[c]     = true end
for _, m in ipairs(Config.AutoModels)      do autoModelSet[m:lower()] = true end
for _, m in ipairs(Config.ExcludedModels)  do excludedModelSet[m:lower()] = true end

-- ── Runtime hozzaadott modellek / osztalyok ─────────────────────
local runtimeAutoModels     = {}  -- { modelName:lower() = true }
local runtimeExcludedModels = {}  -- { modelName:lower() = true }
local runtimeAutoClasses    = {}  -- { classId = true }

-- ── Dontes: kell-e auto-bekotest ────────────────────────────────

---@param vehicle number
---@return boolean
local function ShouldAutoFasten(vehicle)
    if not autoEnabled then
        NXN.AutoSeatbelt.Log('autoEnabled = false, kihagyjuk')
        return false
    end

    local modelHash = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(modelHash):lower()
    local class     = GetVehicleClass(vehicle)

    NXN.AutoSeatbelt.Log(('ShouldAutoFasten: model=%s class=%d'):format(modelName, class))

    -- 1. Kizart modellek (felso prioritas)
    if excludedModelSet[modelName] or runtimeExcludedModels[modelName] then
        NXN.AutoSeatbelt.Log(('Kizart model: %s'):format(modelName))
        return false
    end

    -- 2. Kizart osztalyok
    if excludedClassSet[class] then
        NXN.AutoSeatbelt.Log(('Kizart osztaly: %d'):format(class))
        return false
    end

    -- 3. Explicit auto-modellek (mindig igen)
    if autoModelSet[modelName] or runtimeAutoModels[modelName] then
        NXN.AutoSeatbelt.Log(('Auto model: %s'):format(modelName))
        return true
    end

    -- 4. -1 = minden osztaly engedelyezett (config vagy runtime)
    if autoClassSet[-1] or runtimeAutoClasses[-1] then
        NXN.AutoSeatbelt.Log('Auto osztaly: -1 (minden osztaly)')
        return true
    end

    -- 5. Auto-osztaly
    if autoClassSet[class] or runtimeAutoClasses[class] then
        NXN.AutoSeatbelt.Log(('Auto osztaly: %d'):format(class))
        return true
    end

    NXN.AutoSeatbelt.Log('Nem tartozik auto-kategoriaba')
    return false
end

-- ── Segédek ───────────────────────────────────────────────────

local function Notify(msg, ntype)
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:send(msg, ntype or 'info')
    else
        NXN.AutoSeatbelt.Warn(('Notify fallback [%s]: %s'):format(ntype or 'info', msg))
    end
end

local function FastenViaSeatbelt()
    if GetResourceState('nxn-seatbelt') ~= 'started' then
        NXN.AutoSeatbelt.Warn('nxn-seatbelt nincs elindulva!')
        return
    end
    exports['nxn-seatbelt']:fasten()
    NXN.AutoSeatbelt.Log('nxn-seatbelt:fasten() meghivva')
end

local function PlayAutoSound()
    if not Config.Sound.enabled then return end
    SendNUIMessage({
        action = 'playSound',
        file   = ('nui://%s/sounds/%s'):format(Config.ResourceName, Config.Sound.file),
        volume = Config.Sound.volume,
    })
    NXN.AutoSeatbelt.Log('Auto hang lejatszas inditva')
end

-- ── Auto-bekötés végrehajtása ───────────────────────────────────

local function DoAutoFasten(vehicle)
    -- Ellenorzzes: meg mindig ugyanabban a jarmuben van-e
    local ped     = PlayerPedId()
    local currVeh = GetVehiclePedIsIn(ped, false)
    if currVeh ~= vehicle then
        NXN.AutoSeatbelt.Log('DoAutoFasten: kozben kiszallt, megsem')
        return
    end

    -- Ellenorzzes: nxn-seatbelt el van-e indulva
    if GetResourceState('nxn-seatbelt') ~= 'started' then
        NXN.AutoSeatbelt.Warn('DoAutoFasten: nxn-seatbelt nincs elindulva!')
        return
    end

    -- Ellenorzzes: mar be van-e kotve valaki altal
    if exports['nxn-seatbelt']:isFastened() then
        NXN.AutoSeatbelt.Log('DoAutoFasten: mar be van kotve, kihagyjuk')
        return
    end

    NXN.AutoSeatbelt.Info(('Auto-bekotes: model=%s'):format(
        GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
    ))

    FastenViaSeatbelt()
    PlayAutoSound()

    if Config.NotifyMessage and Config.NotifyMessage ~= '' then
        Notify(Config.NotifyMessage, Config.NotifyType or 'success')
    end

    TriggerEvent('nxn-autoseatbelt:fastened', {
        vehicle = vehicle,
        model   = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower(),
    })

    pendingFasten = false
end

-- ── Fő loop ───────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(300)

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and not inVehicle then
            -- ── Jarmube szallas ───────────────────────────────────
            inVehicle   = true
            lastVehicle = veh
            NXN.AutoSeatbelt.Log(('Jarmube szallt: entId=%d'):format(veh))

            if ShouldAutoFasten(veh) then
                -- Session szamlalas: minden uj belulas egyedi session
                fastenSession = fastenSession + 1
                local mySession = fastenSession
                pendingFasten   = true
                local delay     = math.max(0, Config.AutoFastenDelay)
                NXN.AutoSeatbelt.Log(('Auto-bekotes kesleltetes: %.1f mp'):format(delay))

                CreateThread(function()
                    Wait(math.floor(delay * 1000))
                    -- Csak akkor fut, ha meg mindig ugyanaz a session
                    if pendingFasten and mySession == fastenSession then
                        DoAutoFasten(veh)
                    end
                end)
            end

        elseif veh == 0 and inVehicle then
            -- ── Kiszallas ───────────────────────────────────────
            inVehicle     = false
            lastVehicle   = 0
            pendingFasten = false
            fastenSession = fastenSession + 1  -- ervenytelenitj minden folyamatban levo szalat
            NXN.AutoSeatbelt.Log('Kiszallt, pending reset')
        end
    end
end)

-- ── Exportok ───────────────────────────────────────────────────

--- Auto-ovbekotes rendszer ki/be kapcsolasa
---@param state boolean
exports('setEnabled', function(state)
    autoEnabled = state
    NXN.AutoSeatbelt.Log(('setEnabled: %s'):format(tostring(state)))
end)

--- Rendszer allapota
---@return boolean
exports('isEnabled', function()
    return autoEnabled
end)

--- Azonnal es kesleltetes nelkul bekoti az ovet, ha a jarmufeltetelek teljesulnek (ShouldAutoFasten ellenorzesevel)
exports('triggerNow', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        NXN.AutoSeatbelt.Warn('triggerNow: nincs jarmube')
        return false
    end
    if not ShouldAutoFasten(veh) then
        NXN.AutoSeatbelt.Log('triggerNow: ShouldAutoFasten = false, kihagyjuk')
        return false
    end
    pendingFasten = false
    DoAutoFasten(veh)
    return true
end)

--- Kenyszer auto-bekotes FUGGETLEN a jarmue-lista ellenorzestol
--- (pl. tesztvezetesnel, rendorsegi scriptenel mindig be kell kerni)
exports('forceAutoFasten', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        NXN.AutoSeatbelt.Warn('forceAutoFasten: nincs jarmube')
        return false
    end
    NXN.AutoSeatbelt.Log('forceAutoFasten: kenyszer bekotes (ShouldAutoFasten kihagyva)')
    pendingFasten = false
    DoAutoFasten(veh)
    return true
end)

--- Runtime modell hozzaadasa az auto-listara
---@param modelName string  (pl. 'adder')
exports('addAutoModel', function(modelName)
    runtimeAutoModels[modelName:lower()] = true
    NXN.AutoSeatbelt.Log(('addAutoModel: %s'):format(modelName))
end)

--- Runtime modell eltavolitasa az auto-listarol
---@param modelName string
exports('removeAutoModel', function(modelName)
    runtimeAutoModels[modelName:lower()] = nil
    NXN.AutoSeatbelt.Log(('removeAutoModel: %s'):format(modelName))
end)

--- Runtime osztaly hozzaadasa az auto-listara (-1 = minden osztaly)
---@param classId number
exports('addAutoClass', function(classId)
    runtimeAutoClasses[classId] = true
    NXN.AutoSeatbelt.Log(('addAutoClass: %d'):format(classId))
end)

--- Runtime osztaly eltavolitasa az auto-listarol
---@param classId number
exports('removeAutoClass', function(classId)
    runtimeAutoClasses[classId] = nil
    NXN.AutoSeatbelt.Log(('removeAutoClass: %d'):format(classId))
end)

--- Runtime modell hozzaadasa a KIZART listara
---@param modelName string
exports('excludeModel', function(modelName)
    runtimeExcludedModels[modelName:lower()] = true
    NXN.AutoSeatbelt.Log(('excludeModel: %s'):format(modelName))
end)

--- Runtime modell eltavolitasa a kizart listarol
---@param modelName string
exports('unexcludeModel', function(modelName)
    runtimeExcludedModels[modelName:lower()] = nil
    NXN.AutoSeatbelt.Log(('unexcludeModel: %s'):format(modelName))
end)

--- Jelenlegi auto-bekotest varo allapot
---@return boolean
exports('isPendingFasten', function()
    return pendingFasten
end)

--- Varo bekotes megszakitasa (pl. jatekos manualis kicsatolasa elotti ablakban)
exports('cancelPending', function()
    pendingFasten = false
    fastenSession = fastenSession + 1
    NXN.AutoSeatbelt.Log('cancelPending: pending torolt')
end)
