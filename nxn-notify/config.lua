Config = {}

Config.Debug          = false
Config.ResourceName   = GetCurrentResourceName()

-- Ertesites megjelenitesi ideje milliszekundumban
Config.Duration       = 4000

-- Maximum egyidejuleg megjeleno ertesitesek szama
Config.MaxVisible     = 5

-- Ertesites pozicioja a kepernyon
-- 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'
Config.Position       = 'top-right'

-- Megjelenes animacio iranya (a Position alapjan automatikusan kerül beallitasra,
-- de egyedileg felulirhatod: 'right' | 'left' | 'top' | 'bottom')
Config.SlideFrom      = nil  -- nil = auto a Position alapjan

-- Hangjelzes ertesitesnel (opcionalis)
Config.Sound = {
    enabled  = false,
    soundset  = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
    soundname = 'CONFIRM_BEEP',
}
