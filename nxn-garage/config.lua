Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Garázs helyszínek
Config.Garages = {
    {
        id      = 'main_garage',
        label   = 'Fő Garázs',
        coords  = vector3(215.7, -809.3, 30.7),
        heading = 85.0,
        spawn   = vector4(211.0, -808.0, 30.7, 85.0),
        blip    = { enabled = true,  sprite = 357, color = 0,   scale = 0.8, label = 'Garázs' },
        marker  = { enabled = true,  type = 1, size = 1.0, color = { r = 91,  g = 106, b = 240, a = 80 } },
        npc = {
            enabled  = true,
            model    = 'a_m_y_vinewood_01',
            heading  = 180.0,
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        },
    },
    {
        id      = 'impound_lot',
        label   = 'Lefoglaló Telep',
        coords  = vector3(392.5, -1609.7, 29.3),
        heading = 90.0,
        spawn   = vector4(388.0, -1607.0, 29.3, 90.0),
        blip    = { enabled = true,  sprite = 68,  color = 3,   scale = 0.7, label = 'Lefoglaló telep' },
        marker  = { enabled = true,  type = 1, size = 1.0, color = { r = 231, g = 76,  b = 60,  a = 80 } },
        npc     = { enabled = false },
    },
}

-- Interakciós távolság (m)
Config.InteractDistance = 5.0

-- Garázs panel megnyitó gomb (marker közelében)
Config.OpenKey = 38   -- E

-- Spawn után kulcs automatikus adása (nxn-keys)
Config.AutoGiveKey = true

-- Despawn után trunk kilürítése (nxn-trunk)
Config.ClearTrunkOnDespawn = false

-- Motor HP perzisztencia (nxn-vehicles:getEngineHP / saveEngineHP)
Config.PersistEngineHP = true

-- Spawn cooldown (ms) - ennyit kell várni két spawn között
Config.SpawnCooldown = 2000
