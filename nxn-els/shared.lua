-- ============================================================
--  nxn-els | shared.lua
--  Közös segédfüggvények és adatok (client + server)
-- ============================================================

NXN       = NXN or {}
NXN.ELS   = {}

--- Debug log
---@param msg string
function NXN.ELS.Log(msg)
    if Config.Debug then
        print(('^9[nxn-els]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.ELS.Info(msg)
    print(('^9[nxn-els]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.ELS.Warn(msg)
    print(('^9[nxn-els]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.ELS.Error(msg)
    print(('^9[nxn-els]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Jármű modellje engedélyezett-e ELS-re?
---@param vehicle number  entitás handle
---@return boolean
function NXN.ELS.IsVehicleAllowed(vehicle)
    if not Config.UseVehicleWhitelist then return true end
    local model = GetEntityModel(vehicle)
    for _, allowed in ipairs(Config.AllowedVehicles) do
        if GetHashKey(allowed) == model then return true end
    end
    return false
end

--- Job engedélyezett-e ELS-re?
---@param job string
---@return boolean
function NXN.ELS.IsJobAllowed(job)
    for _, allowedJob in ipairs(Config.AllowedJobs) do
        if allowedJob == job then return true end
    end
    return false
end

--- Stage-hez tartozó konfig lekérése (jármű-specifikus felülírással)
---@param vehicle number
---@param stage number
---@return table
function NXN.ELS.GetStageConfig(vehicle, stage)
    if stage == 0 then
        return { label = 'KI', sirenActive = false, lightExtras = {}, sirenTone = 0 }
    end
    local model = GetEntityModel(vehicle)
    for modelName, vcfg in pairs(Config.VehicleConfigs) do
        if GetHashKey(modelName) == model and vcfg[stage] then
            local base = Config.Stages[stage]
            local vc   = vcfg[stage]
            return {
                label       = base.label,
                sirenActive = vc.sirenTone ~= nil and vc.sirenTone > 0,
                lightExtras = vc.lightExtras or base.lightExtras,
                sirenTone   = vc.sirenTone   or base.sirenTone,
            }
        end
    end
    return Config.Stages[stage]
end
