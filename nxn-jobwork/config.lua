Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Fizetés kiosztási mód:
--   'clockout'  : fizetés csak műszak végén egyben
--   'interval'  : megadott időközönként részfizetés
--   'both'      : részfizetés + végső kifizetés
Config.PayMode = 'clockout'

-- Részfizetési intervallum másodpercben (csak 'interval' vagy 'both' módban)
Config.PayInterval = 3600   -- 1 óra

-- Fizetés típusa: 'cash' | 'bank'
Config.PayType = 'cash'

-- Fáradtság növelés műszak közben (nxn-needs integráció)
Config.FatigueEnabled       = true
Config.FatiguePerHour       = 15       -- fatigue +15 / óra
Config.StressPerHour        = 5        -- stress  +5  / óra
Config.FatigueCheckInterval = 300      -- másodperc (5 perc)

-- Maximum műszak hossz másodpercben (0 = korlátlan)
Config.MaxShiftDuration = 0

-- Admin ACE jog
Config.AdminAce = 'nxn.jobwork.admin'

-- Munkahelyi NPC-k definíciója
Config.JobLocations = {
    ['police'] = {
        label = 'Rendőrség – Bejelentkezs',
        npc = {
            id       = 'police_duty_desk',
            model    = 'ig_officer',
            coords   = vector4(440.0, -981.6, 30.7, 89.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled=true, sprite=60, color=29, label='Rendőrség', scale=0.8 },
        },
        requiredJob   = 'police',
        requiredGrade = 0,
    },
    ['ems'] = {
        label = 'Mentőszolgálat – Bejelentkezs',
        npc = {
            id       = 'ems_duty_desk',
            model    = 's_f_y_scrubs_01',
            coords   = vector4(311.3, -591.6, 43.3, 164.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled=true, sprite=61, color=1, label='Kórház', scale=0.8 },
        },
        requiredJob   = 'ems',
        requiredGrade = 0,
    },
    ['mechanic'] = {
        label = 'Autószerelő – Műhelyvezető',
        npc = {
            id       = 'mechanic_boss',
            model    = 'a_m_m_business_01',
            coords   = vector4(248.0, -709.5, 34.3, 115.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled=true, sprite=446, color=5, label='Autószerelő', scale=0.8 },
        },
        requiredJob   = 'mechanic',
        requiredGrade = 0,
    },
    ['taxi'] = {
        label = 'Taxi Iroda',
        npc = {
            id       = 'taxi_dispatch',
            model    = 's_m_m_fiboffice_01',
            coords   = vector4(-59.5, -1101.7, 26.4, 295.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled=true, sprite=198, color=5, label='Taxi Iroda', scale=0.8 },
        },
        requiredJob   = 'taxi',
        requiredGrade = 0,
    },
    ['trucker'] = {
        label = 'Kamionos Bázis',
        npc = {
            id       = 'trucker_dispatch',
            model    = 's_m_m_dockwork_01',
            coords   = vector4(-186.6, -2644.3, 6.0, 335.0),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip     = { enabled=true, sprite=477, color=47, label='Kamionos Bázis', scale=0.8 },
        },
        requiredJob   = 'trucker',
        requiredGrade = 0,
    },
}
