-- ============================================================
--  nxn-hotwire | config.lua
-- ============================================================

Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Minijáték típusa: 'wirechoice' | 'sequence' | 'random'
Config.DefaultMinigame = 'wirechoice'

-- WireChoice beállítások
Config.WireChoice = {
    totalWires   = 6,
    correctWires = 1,
    shockWires   = 2,
    neutralWires = 3,
    timeLimit    = 20,
}

-- Sequence (QTE) beállítások
Config.Sequence = {
    steps       = 6,
    timePerStep = 1.5,
    keys        = { 'W', 'A', 'S', 'D' },
}

-- Motor HP minimum (0.0–1.0); alatta nem lehet hotwire-olni
Config.MinEngineHP = 0.15

-- Kudarc esetén motor kár (nxn-engine:applyDamage)
Config.DamageOnFail     = true
Config.FailDamageAmount = 0.08

-- Cooldown próbálkozások között (másodperc)
Config.AttemptCooldown = 20

-- Max próbálkozás egy járművön (0 = korlátlan)
Config.MaxAttemptsPerVehicle = 0

-- Rendőrségi riasztás esélye (0.0–1.0)
Config.PoliceAlertChance = 0.50
Config.PoliceAlertOnFail = 0.20

-- DB logolás
Config.LogAttempts = true

-- Animáció a minijáték közben
Config.HotwireAnim = {
    enabled = true,
    dict    = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
    name    = 'machinic_loop_mechandplayer',
}

-- Interakciós gomb (GTA control index)
Config.InteractKey      = 74   -- H gomb
Config.InteractKeyLabel = 'H'
