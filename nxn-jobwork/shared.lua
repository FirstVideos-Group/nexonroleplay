-- ============================================================
--  nxn-jobwork | shared.lua
-- ============================================================

NXN = NXN or {}
NXN.JobWork = {}

---@param msg string
function NXN.JobWork.Log(msg)
    if Config.Debug then
        print(('^9[nxn-jobwork]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.JobWork.Info(msg)
    print(('^9[nxn-jobwork]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.JobWork.Warn(msg)
    print(('^9[nxn-jobwork]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.JobWork.Error(msg)
    print(('^9[nxn-jobwork]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Másodpercből olvasható idő formátum
---@param secs number
---@return string
function NXN.JobWork.FormatTime(secs)
    secs = math.max(0, math.floor(secs))
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    if h > 0 then
        return ('%d óra %d perc'):format(h, m)
    elseif m > 0 then
        return ('%d perc %d mp'):format(m, s)
    else
        return ('%d mp'):format(s)
    end
end
