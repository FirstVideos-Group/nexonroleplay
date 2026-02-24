Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- Biztonsagi ov be/ki kapcsolo gomb (alapertelmezett: B)
Config.ToggleKey      = 199  -- B
Config.ToggleKeyLabel = 'B'

-- Hang emlekeztető beallitasok
Config.ReminderSound    = 'sounds/seatbelt_reminder.ogg'  -- relativ ut a resource-hoz
Config.ReminderInterval = 120   -- masodpercek, ennyi ideig szol az emlekeztető (0 = sosem all le)
Config.ReminderDelay    = 3     -- masodperc varakozas elott elkezd szolni (jarmube szallasnelkul)

-- Kiszallas blokkolasa ha be van kotve az ov
Config.BlockExitIfBuckled = true

-- Ertesites (nxn-notify integracioval)
Config.NotifyOnBuckle   = true
Config.NotifyOnUnbuckle = true

-- HUD informacio kuldes gyakorisaga (ms) - nxn-hud szamara
Config.HudUpdateInterval = 500

-- Jarmutipusok amikre vonatkozik (nil = minden jarmura)
-- Pl.: { 'automobile', 'bike' } -- GTA vehicle classes
Config.VehicleTypes = nil
