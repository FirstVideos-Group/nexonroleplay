Config = {}

Config.Debug         = false          -- Debug üzenetek megjelenítése
Config.ResourceName  = GetCurrentResourceName()
Config.NotifyDuration = 4000          -- Értesítés időtartama ms-ban
Config.ExampleText   = 'Hello Nexon!' -- Alapértelmezett üdvözlő szöveg

-- UI konfig
Config.UI = {
    position = 'top-right',   -- 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'
    theme     = 'dark'        -- 'dark' | 'light'
}