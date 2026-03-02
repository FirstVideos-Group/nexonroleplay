-- ============================================================
--  nxn-keys | config.lua
-- ============================================================

Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Kulcskarika megnyitó billentyű
Config.KeyringKey = 75           -- K gomb (GetControlNormal index)
Config.KeyringKeyLabel = 'K'

-- Zárolás/nyitás billentyű
Config.LockKey      = 76         -- L gomb
Config.LockKeyLabel = 'L'

-- Közelségalapot értinekciók
Config.InteractDistance  = 5.0   -- Max táv zároláshoz
Config.GiveKeyDistance   = 3.0   -- Max táv kulcsátadáshoz

-- Csak tulajdonos oszthat kulcsot
Config.OnlyOwnerCanShare = true

-- Animáció
Config.LockAnim = {
    enabled = true,
    dict    = 'anim@mp_player_intmenu@key_fob@',
    name    = 'fob_click',
}

-- Hangeffekt (NUI-n át)
Config.LockSound = {
    enabled = true,
    lock    = 'lock.mp3',
    unlock  = 'unlock.mp3',
}

-- Automatikus kulcs-megvonás despawnkor (csak lokális cache-ből, DB-ből NEM)
Config.AutoRevokeOnDespawn = true

-- Közelségben lévő játékosok lekérési sűrűsége (ms)
Config.NearbyPlayersInterval = 500
