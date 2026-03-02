-- ============================================================
--  nxn-delivery | server.lua
-- ============================================================

-- ── Állapot cache ────────────────────────────────────────────

--- activeTask[src] = { taskId, category, dispatchId, dispatchCoords,
---                     target, reward, startedAt, timeLimit, distanceM,
---                     pickedUp, vehiclePlate }
local activeTask   = {}
local shiftCount   = {}  -- shiftCount[src] = feladatszám az aktuális műszakban
local shiftEarned  = {}  -- shiftEarned[src] = összkereset az aktuális műszakban

-- ── Helpers ──────────────────────────────────────────────────

local function getIdentifier(src)
    if GetResourceState('nxn-identity') == 'started' then
        return exports['nxn-identity']:getIdentifier(src)
    end
    return ('steam:%s'):format(GetPlayerIdentifierByType(src, 'steam') or tostring(src))
end

local function notify(src, msg, ntype)
    if GetResourceState('nxn-notify') == 'started' then
        exports['nxn-notify']:notifyPlayer(src, msg, ntype or 'info')
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '[Delivery]', msg } })
    end
end

local function calculateDistance(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

local function calculateReward(category, distanceM)
    local cat = Config.TaskCategories[category]
    if not cat then return 0 end
    local distKm = distanceM / 1000.0
    return math.floor(cat.baseReward + (distKm * cat.distanceMultiplier))
end

local function cancelActiveTask(src, reason)
    local task = activeTask[src]
    if not task then return false end
    local taskId = task.taskId
    -- DB update
    if GetResourceState('nxn-database') == 'started' then
        exports['nxn-database']:execute(
            "UPDATE nxn_delivery_tasks SET status='cancelled', completed_at=NOW() WHERE id=?",
            { taskId }
        )
    end
    -- Jármű törlése
    if task.vehiclePlate and GetResourceState('nxn-vehicles') == 'started' then
        exports['nxn-vehicles']:deleteVehicle(task.vehiclePlate)
    end
    activeTask[src] = nil
    TriggerClientEvent('nxn-delivery:client:taskFailed', src, { reason = reason, taskId = taskId })
    TriggerEvent('nxn-delivery:server:taskFailed', src, taskId, reason)
    return true
end

-- ── DB setup ─────────────────────────────────────────────────

CreateThread(function()
    Wait(2000)
    if GetResourceState('nxn-database') ~= 'started' then
        NXN.Delivery.Warn('nxn-database nem fut – DB funkciók letiltva!')
        return
    end
    exports['nxn-database']:execute([[
        CREATE TABLE IF NOT EXISTS `nxn_delivery_tasks` (
            `id`            INT UNSIGNED   NOT NULL AUTO_INCREMENT,
            `identifier`    VARCHAR(100)   NOT NULL,
            `category`      VARCHAR(20)    NOT NULL,
            `dispatch_id`   VARCHAR(50)    NOT NULL,
            `target_label`  VARCHAR(100)   NOT NULL,
            `target_coords` VARCHAR(100)   NOT NULL,
            `reward`        INT UNSIGNED   NOT NULL DEFAULT 0,
            `distance_m`    FLOAT          DEFAULT NULL,
            `time_limit`    INT UNSIGNED   NOT NULL,
            `time_taken`    INT UNSIGNED   DEFAULT NULL,
            `status`        ENUM('active','completed','failed','cancelled') NOT NULL DEFAULT 'active',
            `bonus_applied` TINYINT(1)     NOT NULL DEFAULT 0,
            `started_at`    DATETIME       NOT NULL,
            `completed_at`  DATETIME       DEFAULT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_delivery_ident`  (`identifier`),
            INDEX `idx_delivery_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    NXN.Delivery.Info('DB tábla ellenőrizve / létrehozva.')
end)

-- ── Timeout loop ─────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(10000)
        local now = os.time()
        for src, task in pairs(activeTask) do
            local elapsed = now - task.startedAt
            if elapsed >= task.timeLimit then
                NXN.Delivery.Log(('Feladat lejárt: src=%s taskId=%s'):format(src, task.taskId))
                if GetResourceState('nxn-database') == 'started' then
                    exports['nxn-database']:execute(
                        "UPDATE nxn_delivery_tasks SET status='failed', completed_at=NOW() WHERE id=?",
                        { task.taskId }
                    )
                end
                if GetResourceState('nxn-needs') == 'started' then
                    exports['nxn-needs']:modifyNeed(src, 'stress', Config.StressOnTimeout)
                end
                if task.vehiclePlate and GetResourceState('nxn-vehicles') == 'started' then
                    exports['nxn-vehicles']:deleteVehicle(task.vehiclePlate)
                end
                TriggerClientEvent('nxn-delivery:client:taskFailed', src, { reason='timeout', taskId=task.taskId })
                TriggerEvent('nxn-delivery:server:taskFailed', src, task.taskId, 'timeout')
                notify(src, 'Szállítás lejárt! A feladat törlve.', 'error')
                activeTask[src] = nil
            end
        end
    end
end)

-- ── Net Events ───────────────────────────────────────────────

RegisterServerEvent('nxn-delivery:server:requestTask', function(dispatchId)
    local src = source

    -- Jogosultságok ellenőrzése
    if GetResourceState('nxn-job') == 'started' then
        if not exports['nxn-job']:hasJob(src, 'delivery') then
            notify(src, 'Ehhez szállítói munkakör szükséges!', 'error')
            return
        end
    end
    if GetResourceState('nxn-jobwork') == 'started' then
        if not exports['nxn-jobwork']:isOnDuty(src) then
            notify(src, 'Előbb be kell jelentkezni műszakba!', 'error')
            return
        end
    end
    if activeTask[src] then
        notify(src, 'Már van aktív szállítási feladatod!', 'error')
        return
    end

    -- Műszak limit
    if Config.MaxTasksPerShift > 0 then
        local cnt = shiftCount[src] or 0
        if cnt >= Config.MaxTasksPerShift then
            notify(src, 'Elérted a műszakra vonatkozó feladatlimitet!', 'error')
            return
        end
    end

    -- Diszpécser hely
    local dispatch = Config.DispatchLocations[dispatchId]
    if not dispatch then
        notify(src, 'Érvénytelen diszpécserpont.', 'error')
        return
    end

    -- Véletlenszerű célpont és kategória
    local targetIdx = math.random(1, #Config.DeliveryTargets)
    local target    = Config.DeliveryTargets[targetIdx]
    local categories = { 'small', 'medium', 'large' }
    local category   = categories[math.random(1, #categories)]
    local cat        = Config.TaskCategories[category]

    local distanceM  = calculateDistance(dispatch.coords, target.coords)
    local reward     = calculateReward(category, distanceM)
    local timeLimit  = cat.timeLimit
    local identifier = getIdentifier(src)
    local now        = os.time()
    local taskId     = nil

    -- DB INSERT
    if GetResourceState('nxn-database') == 'started' then
        taskId = exports['nxn-database']:insertSync(
            "INSERT INTO nxn_delivery_tasks (identifier, category, dispatch_id, target_label, target_coords, reward, distance_m, time_limit, started_at) VALUES (?,?,?,?,?,?,?,?,NOW())",
            { identifier, category, dispatchId, target.label,
              ('%s/%s/%s'):format(target.coords.x, target.coords.y, target.coords.z),
              reward, distanceM, timeLimit }
        )
    else
        taskId = math.random(100000, 999999)
    end

    -- Cache
    activeTask[src] = {
        taskId        = taskId,
        category      = category,
        dispatchId    = dispatchId,
        dispatchCoords = dispatch.coords,
        target        = target,
        reward        = reward,
        startedAt     = now,
        timeLimit     = timeLimit,
        distanceM     = distanceM,
        pickedUp      = false,
        vehiclePlate  = nil,
    }
    shiftCount[src] = (shiftCount[src] or 0) + 0  -- csak teljesítéskor növeljük

    -- Opcionális: jármű kiosztás
    if Config.VehicleEnabled and GetResourceState('nxn-vehicles') == 'started' then
        local spawnCoords = vector3(
            dispatch.coords.x + Config.VehicleSpawnOffset.x,
            dispatch.coords.y + Config.VehicleSpawnOffset.y,
            dispatch.coords.z + Config.VehicleSpawnOffset.z
        )
        local plate = exports['nxn-vehicles']:spawnVehicle(src, Config.VehicleModel, spawnCoords)
        if plate then activeTask[src].vehiclePlate = plate end
    end

    local taskData = {
        taskId    = taskId,
        category  = category,
        label     = cat.label,
        icon      = cat.icon,
        target    = target,
        reward    = reward,
        timeLimit = timeLimit,
        distanceM = distanceM,
        dispatchCoords = { x=dispatch.coords.x, y=dispatch.coords.y, z=dispatch.coords.z },
    }

    TriggerClientEvent('nxn-delivery:client:taskStarted', src, taskData)
    TriggerEvent('nxn-delivery:server:taskStarted', src, taskId, category, target, reward)
    NXN.Delivery.Info(('Feladat indítva: src=%s taskId=%s kategória=%s jutalom=%d'):format(src, taskId, category, reward))
end)

RegisterServerEvent('nxn-delivery:server:pickupConfirmed', function(taskId)
    local src  = source
    local task = activeTask[src]
    if not task or task.taskId ~= taskId then return end
    if task.pickedUp then return end
    task.pickedUp = true
    NXN.Delivery.Log(('Csomag felvéve: src=%s taskId=%s'):format(src, taskId))
end)

RegisterServerEvent('nxn-delivery:server:confirmDropoff', function(taskId, vehicleNetId)
    local src  = source
    local task = activeTask[src]
    if not task or task.taskId ~= taskId then return end
    if not task.pickedUp then
        notify(src, 'Előbb vedd fel a csomagot!', 'error')
        return
    end

    local now       = os.time()
    local timeTaken = now - task.startedAt

    -- Lejárt?
    if timeTaken >= task.timeLimit then
        if GetResourceState('nxn-database') == 'started' then
            exports['nxn-database']:execute(
                "UPDATE nxn_delivery_tasks SET status='failed', completed_at=NOW() WHERE id=?",
                { taskId }
            )
        end
        if GetResourceState('nxn-needs') == 'started' then
            exports['nxn-needs']:modifyNeed(src, 'stress', Config.StressOnTimeout)
        end
        if task.vehiclePlate and GetResourceState('nxn-vehicles') == 'started' then
            exports['nxn-vehicles']:deleteVehicle(task.vehiclePlate)
        end
        TriggerClientEvent('nxn-delivery:client:taskFailed', src, { reason='timeout', taskId=taskId })
        TriggerEvent('nxn-delivery:server:taskFailed', src, taskId, 'timeout')
        notify(src, 'Késtél! A csomag leadása sikertelen.', 'error')
        activeTask[src] = nil
        return
    end

    -- Bónusz?
    local bonus  = false
    local reward = task.reward
    if timeTaken <= math.floor(task.timeLimit * 0.5) then
        bonus  = true
        reward = math.floor(reward * Config.TimeBonusMultiplier)
    end

    -- Fizetés
    if GetResourceState('nxn-finance') == 'started' then
        exports['nxn-finance']:addMoney(src, reward, 'cash',
            ('Szállítás: #%s'):format(taskId), 'nxn-delivery')
    end

    -- Fáradtság
    if Config.FatigueEnabled and GetResourceState('nxn-needs') == 'started' then
        local cat = Config.TaskCategories[task.category]
        if cat then
            exports['nxn-needs']:modifyNeed(src, 'fatigue', cat.fatiguePerTask)
        end
    end

    -- DB update
    if GetResourceState('nxn-database') == 'started' then
        exports['nxn-database']:execute(
            "UPDATE nxn_delivery_tasks SET status='completed', time_taken=?, completed_at=NOW(), bonus_applied=?, reward=? WHERE id=?",
            { timeTaken, bonus and 1 or 0, reward, taskId }
        )
    end

    -- Jármű törlése
    if task.vehiclePlate and GetResourceState('nxn-vehicles') == 'started' then
        exports['nxn-vehicles']:deleteVehicle(task.vehiclePlate)
    end

    shiftCount[src]  = (shiftCount[src]  or 0) + 1
    shiftEarned[src] = (shiftEarned[src] or 0) + reward
    local totalEarned = shiftEarned[src]

    activeTask[src] = nil

    TriggerClientEvent('nxn-delivery:client:taskCompleted', src, {
        reward      = reward,
        bonus       = bonus,
        timeTaken   = timeTaken,
        totalEarned = totalEarned,
    })
    TriggerEvent('nxn-delivery:server:taskCompleted', src, taskId, reward, bonus, timeTaken)

    notify(src,
        ('Szállítás teljesítve! Jutalom: %d Ft%s'):format(reward, bonus and ' (+BÓNUSZ!)' or ''),
        'success')
    NXN.Delivery.Info(('Feladat teljesítve: src=%s taskId=%s reward=%d bonus=%s'):format(src, taskId, reward, tostring(bonus)))
end)

-- ── Műszak vége → feladat törlése ────────────────────────────

AddEventHandler('nxn-jobwork:server:clockedOut', function(src, job, grade, duration, payout)
    if job ~= 'delivery' then return end
    if activeTask[src] then
        cancelActiveTask(src, 'clockout')
        notify(src, 'Műszak vége – aktív szállítási feladatod törölve.', 'warning')
    end
    -- műszak statisztikák törlése
    shiftCount[src]  = nil
    shiftEarned[src] = nil
end)

-- ── Játékos kilépésekor ────────────────────────────────────────

AddEventHandler('playerUnloading', function()
    local src = source
    if activeTask[src] then
        if GetResourceState('nxn-database') == 'started' then
            exports['nxn-database']:execute(
                "UPDATE nxn_delivery_tasks SET status='cancelled', completed_at=NOW() WHERE id=?",
                { activeTask[src].taskId }
            )
        end
        if activeTask[src].vehiclePlate and GetResourceState('nxn-vehicles') == 'started' then
            exports['nxn-vehicles']:deleteVehicle(activeTask[src].vehiclePlate)
        end
        activeTask[src] = nil
    end
    shiftCount[src]  = nil
    shiftEarned[src] = nil
end)

-- ── Admin parancs ──────────────────────────────────────────────

RegisterCommand('canceldelivery', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then
        notify(src, 'Nincs jogosultságod ehhez!', 'error')
        return
    end
    local targetSrc = tonumber(args[1])
    if not targetSrc then
        if src == 0 then print('[nxn-delivery] Használat: /canceldelivery [src]') end
        return
    end
    if cancelActiveTask(targetSrc, 'cancelled') then
        notify(targetSrc, 'Szállítási feladatodat az admin törölte.', 'error')
        if src ~= 0 then notify(src, ('Feladat törölve: játékos #%d'):format(targetSrc), 'success') end
    else
        if src ~= 0 then notify(src, 'Ennek a játékosnak nincs aktív feladata.', 'error') end
    end
end, true)

-- ── Exportok ──────────────────────────────────────────────────

exports('hasActiveTask', function(src)
    return activeTask[src] ~= nil
end)

exports('getActiveTask', function(src)
    if not activeTask[src] then return nil end
    local t = activeTask[src]
    return {
        category   = t.category,
        target     = t.target,
        reward     = t.reward,
        startedAt  = t.startedAt,
        timeLimit  = t.timeLimit,
        distanceM  = t.distanceM,
        pickedUp   = t.pickedUp,
    }
end)

exports('getTaskCount', function(src)
    return shiftCount[src] or 0
end)

exports('getTotalEarned', function(src)
    return shiftEarned[src] or 0
end)

exports('cancelTask', function(src, reason)
    return cancelActiveTask(src, reason or 'cancelled')
end)

exports('getLeaderboard', function(limit)
    limit = math.min(limit or 10, 50)
    if GetResourceState('nxn-database') ~= 'started' then return {} end
    local result = exports['nxn-database']:fetchSync(
        [[SELECT identifier,
                 COUNT(*) AS total_tasks,
                 SUM(reward) AS total_earned
          FROM nxn_delivery_tasks
          WHERE status='completed'
            AND DATE(started_at) = CURDATE()
          GROUP BY identifier
          ORDER BY total_earned DESC
          LIMIT ?]],
        { limit }
    )
    return result or {}
end)
