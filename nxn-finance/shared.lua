-- ============================================================
--  nxn-finance | shared.lua
-- ============================================================

NXN = NXN or {}
NXN.Finance = {}

local prefix = '^2[nxn-finance]^7'

function NXN.Finance.Log(msg)   print(prefix .. ' ' .. tostring(msg)) end
function NXN.Finance.Info(msg)  print(prefix .. ' ^5[INFO]^7 ' .. tostring(msg)) end
function NXN.Finance.Warn(msg)  print(prefix .. ' ^3[WARN]^7 ' .. tostring(msg)) end
function NXN.Finance.Error(msg) print(prefix .. ' ^1[ERROR]^7 ' .. tostring(msg)) end
