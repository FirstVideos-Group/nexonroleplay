Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- Bekotesi gomb - RegisterKeyMapping hasznalathoz a nev kell
-- Az in-game billentyu a jatekos altal atallithato az esc > settings > keybinds menuben
Config.ToggleKey      = 'B'       -- alapertelmezett billentyu (string, RegisterKeyMapping-hez)
Config.ToggleKeyLabel = 'Biztonsagi ov be/ki'

-- Figyelmezteto hang
Config.WarningSoundFile     = 'seatbelt_warning.ogg'  -- sounds/ mappaban
Config.WarningSoundVolume   = 0.5                      -- 0.0 - 1.0
Config.WarningSoundDuration = 120                      -- masodperc, ennyi ideig figyelmeztet
Config.WarningSoundInterval = 3.0                      -- masodperc, ennyi idonkent szol

-- Kiszallas blokkolasa bekotott ov eseten
Config.BlockExitWhenFastened = true

-- Ertesites szovegek
Config.Notify = {
    fastened   = 'Biztonsagi ov bekotve.',
    unfastened = 'Biztonsagi ov kicsatolva.',
    blocked    = 'Csatold ki az ovet kiszallas elott!',
}

-- Gyorsulas limit amifelett automatikus kicsatolas tortenik
-- (nil = kikapcsolt)
Config.AutoUnbuckleSpeedThreshold = nil  -- pl. 80.0 (km/h)
