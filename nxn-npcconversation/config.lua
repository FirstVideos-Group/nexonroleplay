Config = {}

Config.Debug        = false
Config.ResourceName = GetCurrentResourceName()

-- Interakcio tavolsag (meter)
Config.InteractDistance = 2.5

-- Interakcio gomb (alapertelmezett: E)
Config.InteractKey     = 38  -- E
Config.InteractKeyLabel = 'E'

-- Kozelito jelzes megjelenesi tavolsag
Config.HintDistance = 5.0

-- NPC modell lista (ha ures, random pedestrian nem lesz interaktiv)
-- Minden NPC egy egyedi ID-val es pozicioval rendelkezik
Config.NPCs = {
    [
    'mechanic_01'] = {
        label       = 'Szerviz Mester',
        model       = 'mp_m_waremech_01',
        coords      = vector4(213.9, -809.3, 30.7, 270.0),
        scenario    = 'WORLD_HUMAN_CLIPBOARD',  -- GTA scenario (nil = alap)
        blip        = {
            enabled = true,
            sprite  = 446,   -- GTA blip sprite
            color   = 3,
            label   = 'Szerviz',
            scale   = 0.8,
        },
        -- Beseélgetesi opciok (config-ban megadott)
        dialogues = {
            {
                id      = 'greet',
                label   = 'Szia, hogy vagy?',
                icon    = 'hgi-message-01',
                -- response: NPC valasza
                response = 'Jól, köszönöm! Mi hozta ide?',
                -- event: kliens event amit kivált (nil = csak szöveg)
                event   = nil,
            },
            {
                id      = 'lore',
                label   = 'Meselsz magadrol?',
                icon    = 'hgi-user-story',
                response = 'Már 20 éve dolgozom itt a műhelyben. Minden járművet meg tudok javítani.',
                event   = nil,
            },
        },
        -- Mas resource-ok altal hozzaadott opciok (runtime)
        -- Ezt a rendszer automatikusan kezeli az exporton keresztul
    },

    ['impound_clerk'] = {
        label    = 'Lefoglalasi Ugyintező',
        model    = 's_m_m_security_01',
        coords   = vector4(404.9, -1631.9, 29.3, 90.0),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        blip     = {
            enabled = true,
            sprite  = 446,
            color   = 1,
            label   = 'Lefoglalt járművek',
            scale   = 0.8,
        },
        dialogues = {
            {
                id       = 'greet',
                label    = 'Jó napot!',
                icon     = 'hgi-message-01',
                response = 'Jó napot kívánok! Miben segíthetek?',
                event    = nil,
            },
        },
    },
}
