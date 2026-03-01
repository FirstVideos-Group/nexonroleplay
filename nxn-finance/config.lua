Config = {}

Config.ResourceName = GetCurrentResourceName()
Config.Debug        = false

-- Pénztípusok
Config.MoneyTypes = {
    ['cash'] = { label = 'Készpénz',   icon = 'hgi-money-02', default = 500  },
    ['bank'] = { label = 'Bankszámla', icon = 'hgi-bank',     default = 2500 },
}
Config.DefaultType = 'cash'

-- Napi mentési ciklus (ms)
Config.SaveInterval = 300000  -- 5 perc

-- ATM helyszínek
Config.ATMs = {
    { id = 'atm_grove',    label = 'Fleeca ATM – Grove Street', coords = vector3(149.5,  -1042.3, 29.4), model = 'prop_atm_01' },
    { id = 'atm_vinewood', label = 'Fleeca ATM – Vinewood',    coords = vector3(313.3,   -279.6, 54.2), model = 'prop_atm_02' },
    { id = 'atm_delperro', label = 'Fleeca ATM – Del Perro',  coords = vector3(-1393.8, -582.8, 30.1), model = 'prop_atm_03' },
}

-- Bank NPC helyszínek
Config.BankNPCs = {
    ['fleeca_main'] = {
        label    = 'Fleeca Bank – Del Perro',
        model    = 's_f_y_bank_01',
        coords   = vector4(149.5, -1042.3, 29.4, 340.0),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        blip     = { enabled = true, sprite = 108, color = 2, label = 'Fleeca Bank', scale = 0.8 },
    },
    ['fleeca_vinewood'] = {
        label    = 'Fleeca Bank – Vinewood',
        model    = 's_f_y_bank_01',
        coords   = vector4(313.3, -279.6, 54.2, 180.0),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        blip     = { enabled = true, sprite = 108, color = 2, label = 'Fleeca Bank – Vinewood', scale = 0.8 },
    },
}

-- Interakciós hatótávolság (méter)
Config.InteractDistance = 2.5

-- Napi limitek (0 = nincs limit)
Config.MaxDepositPerDay  = 0
Config.MaxWithdrawPerDay = 0

-- Minimális átutalás
Config.MinTransferAmount = 1
