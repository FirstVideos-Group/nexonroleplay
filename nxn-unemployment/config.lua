Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Segély alapösszege (Ft, készpénz)
Config.BenefitAmount = 500

-- Segély kifizetési intervallum másodpercben (alap: 1800 = 30 perc)
Config.PayInterval = 1800

-- Maximum egyenleg, ami felett NEM jár segély (nil = nincs limit)
Config.MaxCashLimit = 5000

-- Első segély cooldown: munkaváltás után ennyi másodperccel kapja az első kifizetést
Config.FirstPayDelay = 300  -- 5 perc

-- Aktív bíróság esetén levonás a segélyből (nxn-cityhall integráció)
Config.DeductFines       = false
Config.FineDeductionRate = 0.2   -- segély 20%-a megy bíróságra

-- Stressz alapú segélycsökkentés (nxn-needs integráció)
Config.StressReduction     = false
Config.StressThreshold     = 70
Config.StressReductionRate = 0.5

-- Admin ACE jog kézi kifizetéshez
Config.AdminAce = 'nxn.unemployment.admin'

-- Munkáügyi Hivatal NPC
Config.NPCLabel    = 'Munkáügyi Ügyintéző'
Config.NPCModel    = 's_f_y_scrubs_01'
Config.NPCCoords   = vector4(372.3, 327.8, 103.6, 250.0)
Config.NPCScenario = 'WORLD_HUMAN_STAND_IMPATIENT'
Config.NPCBlip     = {
    enabled = true,
    sprite  = 480,
    color   = 5,
    scale   = 0.8,
    label   = 'Munkáügyi Hivatal',
}
