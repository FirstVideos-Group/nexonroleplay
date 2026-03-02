-- ============================================================
--  nxn-unemployment | shared.lua
--  Közös segédfüggvények (client + server)
-- ============================================================

NXN = NXN or {}
NXN.Unemployment = {}

---@param msg string
function NXN.Unemployment.Log(msg)
    if Config.Debug then
        print(('^9[nxn-unemployment]^7 ^5[DEBUG]^7 %s'):format(tostring(msg)))
    end
end

---@param msg string
function NXN.Unemployment.Info(msg)
    print(('^9[nxn-unemployment]^7 ^4[INFO]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Unemployment.Warn(msg)
    print(('^9[nxn-unemployment]^7 ^3[WARN]^7 %s'):format(tostring(msg)))
end

---@param msg string
function NXN.Unemployment.Error(msg)
    print(('^9[nxn-unemployment]^7 ^1[HIBA]^7 %s'):format(tostring(msg)))
end

--- Idő formázás: másodpercből olvasható szöveg
---@param secs number
---@return string
function NXN.Unemployment.FormatTime(secs)
    secs = math.max(0, math.floor(secs))
    if secs < 60 then
        return secs .. ' másodperc'
    elseif secs < 3600 then
        return math.floor(secs / 60) .. ' perc '
             .. (secs % 60) .. ' mp'
    else
        return math.floor(secs / 3600) .. ' óra '
             .. math.floor((secs % 3600) / 60) .. ' perc'
    end
end
