-- ============================================================
--  nxn-cartheft | config.lua
-- ============================================================

Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Interakciós távolság a járműhöz
Config.InteractDistance = 2.5

-- Feltörési mód: 'lockpick' | 'keypad' | 'random'
Config.DefaultMinigame = 'lockpick'

-- Lockpick minijáték
Config.Lockpick = {
    rounds      = 3,
    speed       = 1.2,
    successZone = 15,
    timeLimit   = 10,
    failDamage  = false,
}

-- Keypad minijáték (Simon Says)
Config.Keypad = {
    sequenceLength = 5,
    showTime       = 3000,
    inputTime      = 6000,
    symbols        = { '▲', '▼', '◄', '►', '■' },
}

-- Animáció feltörés közben
Config.BreakInAnim = {
    enabled  = true,
    dict     = 'anim@mp_player_intmenu@key_fob@',
    name     = 'fob_click',
    duration = 0,
}

-- Prop: csavarhúzó a kézben
Config.BreakInProp = {
    enabled = true,
    model   = 'prop_screwdriver_01',
    bone    = 57005,
    offset  = vector3(0.0, 0.0, 0.0),
    rot     = vector3(0.0, 0.0, 0.0),
}

-- Cooldown próbálkozások között (másodperc)
Config.AttemptCooldown = 30

-- Max próbálkozás egy járművön (0 = korlátlan)
Config.MaxAttemptsPerVehicle = 5

-- Rendőrségi riasztás esélye (0.0–1.0)
Config.PoliceAlertChance   = 0.35
Config.PoliceAlertOnFail   = 0.15

-- DB logolás
Config.LogAttempts = true

-- Interact gomb (GTA control index)
Config.InteractKey      = 38   -- E gomb
Config.InteractKeyLabel = 'E'
