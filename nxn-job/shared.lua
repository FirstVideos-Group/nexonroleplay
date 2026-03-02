-- ============================================================
--  nxn-job | shared.lua
--  Közös segédfüggvények (client + server)
-- ============================================================

NXN = NXN or {}
NXN.Job = {}

---@param msg string
function NXN.Job.Log(msg)
    if Config.Debug then
        print(('^9[nxn-job]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Job.Info(msg)
    print(('^9[nxn-job]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Job.Warn(msg)
    print(('^9[nxn-job]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Job.Error(msg)
    print(('^9[nxn-job]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Érvényes munkakör-e?
---@param job string
---@param grade number
---@return boolean
function NXN.Job.IsValid(job, grade)
    if not Config.Jobs[job] then return false end
    if grade ~= nil and not Config.Jobs[job].grades[grade] then return false end
    return true
end

--- Teljes munkakör adat összeállítása
---@param job string
---@param grade number
---@return table|nil
function NXN.Job.BuildJobData(job, grade)
    local cfg = Config.Jobs[job]
    if not cfg then return nil end
    local gradeCfg = cfg.grades[grade]
    if not gradeCfg then return nil end
    return {
        job        = job,
        grade      = grade,
        label      = cfg.label,
        gradeLabel = gradeCfg.label,
        salary     = gradeCfg.salary,
        color      = cfg.color,
    }
end
