-- ============================================================
--  nxn-identity | server.lua
--  Karakter adatok betoltese, mentese, exportok
-- ============================================================

-- ── Tabla letrehozas ───────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= Config.ResourceName then return end
    NXN.Identity.Info('nxn-identity elindult, tabla migracio...')

    if GetResourceState('nxn-database') == 'started' then
        exports['nxn-database']:registerTable(Config.ResourceName, {
            name = 'nxn_identities',
            sql  = [[
                CREATE TABLE IF NOT EXISTS `nxn_identities` (
                    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
                    `identifier`    VARCHAR(60)     NOT NULL UNIQUE,
                    `firstname`     VARCHAR(40)     NOT NULL DEFAULT '',
                    `lastname`      VARCHAR(40)     NOT NULL DEFAULT '',
                    `gender`        TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '0=ferfi 1=no',
                    `birth_day`     TINYINT         NOT NULL DEFAULT 1,
                    `birth_month`   TINYINT         NOT NULL DEFAULT 1,
                    `birth_year`    SMALLINT        NOT NULL DEFAULT 1990,
                    `skin_color`    TINYINT         NOT NULL DEFAULT 0,
                    `eye_color`     TINYINT         NOT NULL DEFAULT 0,
                    `hair_style`    TINYINT         NOT NULL DEFAULT 0,
                    `hair_color`    TINYINT         NOT NULL DEFAULT 0,
                    `hair_highlight`TINYINT         NOT NULL DEFAULT 0,
                    `face_features` LONGTEXT        DEFAULT NULL COMMENT 'JSON: GTA ped face overlay tomb',
                    `outfit`        LONGTEXT        DEFAULT NULL COMMENT 'JSON: [{ comp, draw, tex }]',
                    `pos_x`         FLOAT           DEFAULT NULL,
                    `pos_y`         FLOAT           DEFAULT NULL,
                    `pos_z`         FLOAT           DEFAULT NULL,
                    `pos_heading`   FLOAT           DEFAULT NULL,
                    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`),
                    INDEX `idx_identifier` (`identifier`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]]
        })
        NXN.Identity.Info('nxn_identities tabla OK')
    else
        NXN.Identity.Warn('nxn-database nem fut! Az identitas rendszer DB-t igenyel.')
    end
end)

-- ── Szerversoldali cache ──────────────────────────────────────────
-- { [src] = identityRow }
local identCache = {}

-- ── Azonosito lekerdezes ───────────────────────────────────────

local function GetIdentifier(src)
    if GetResourceState('nxn-database') ~= 'started' then return nil end
    return exports['nxn-database']:getIdentifier(src)
end

-- ── nxn-database:playerLoaded esemeny ──────────────────────────
-- Amikor a DB betolti a jatekost, lekerdjuk az identitasat

AddEventHandler('nxn-database:server:playerLoaded', function(src, dbData)
    NXN.Identity.Log(('playerLoaded event: src=%d ident=%s'):format(src, tostring(dbData and dbData.identifier)))

    local identifier = dbData and dbData.identifier
    if not identifier then return end

    local row = MySQL.single.await(
        'SELECT * FROM `nxn_identities` WHERE identifier = ?',
        { identifier }
    )

    if row then
        identCache[src] = row
        NXN.Identity.Log(('Identitas betoltve: src=%d name=%s %s'):format(src, row.firstname, row.lastname))
        -- Kulduk a kliensnek (spawn + skin)
        TriggerClientEvent('nxn-identity:client:loaded', src, row)
    else
        NXN.Identity.Info(('Uj jatekos, karakterletrehozas szukseges: src=%d'):format(src))
        TriggerClientEvent('nxn-identity:client:create', src)
    end
end)

-- ── Karakter letrehozas (kliens elkuldvi adatokat) ───────────────

RegisterNetEvent('nxn-identity:server:createIdentity')
AddEventHandler('nxn-identity:server:createIdentity', function(data)
    local src = source
    local identifier = GetIdentifier(src)
    if not identifier then
        NXN.Identity.Warn(('createIdentity: nincs identifier, src=%d'):format(src))
        return
    end

    -- Biztonsag: duplikat ellenorzes
    local existing = MySQL.single.await(
        'SELECT id FROM `nxn_identities` WHERE identifier = ?',
        { identifier }
    )
    if existing then
        NXN.Identity.Warn(('createIdentity: mar letezik identitas src=%d'):format(src))
        TriggerClientEvent('nxn-identity:client:loaded', src, identCache[src])
        return
    end

    local faceJson   = data.face_features and json.encode(data.face_features) or nil
    local outfitJson = data.outfit and json.encode(data.outfit) or nil

    local insertId = MySQL.insert.await([[
        INSERT INTO `nxn_identities`
            (identifier, firstname, lastname, gender, birth_day, birth_month, birth_year,
             skin_color, eye_color, hair_style, hair_color, hair_highlight, face_features, outfit)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    ]], {
        identifier,
        data.firstname    or '',
        data.lastname     or '',
        data.gender       or 0,
        data.birth_day    or 1,
        data.birth_month  or 1,
        data.birth_year   or 1990,
        data.skin_color   or 0,
        data.eye_color    or 0,
        data.hair_style   or 0,
        data.hair_color   or 0,
        data.hair_highlight or 0,
        faceJson,
        outfitJson,
    })

    local row = MySQL.single.await(
        'SELECT * FROM `nxn_identities` WHERE id = ?',
        { insertId }
    )
    identCache[src] = row
    NXN.Identity.Info(('Uj identitas letrehozva: src=%d id=%d %s %s'):format(
        src, insertId, data.firstname, data.lastname
    ))

    TriggerClientEvent('nxn-identity:client:loaded', src, row)
    TriggerEvent('nxn-identity:server:identityCreated', src, row)
end)

-- ── Pozicio mentes ───────────────────────────────────────────────

RegisterNetEvent('nxn-identity:server:savePosition')
AddEventHandler('nxn-identity:server:savePosition', function(x, y, z, heading)
    local src = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    MySQL.update(
        'UPDATE `nxn_identities` SET pos_x=?, pos_y=?, pos_z=?, pos_heading=? WHERE identifier=?',
        { x, y, z, heading, identifier }
    )

    if identCache[src] then
        identCache[src].pos_x       = x
        identCache[src].pos_y       = y
        identCache[src].pos_z       = z
        identCache[src].pos_heading = heading
    end

    NXN.Identity.Log(('Pozicio mentve: src=%d x=%.1f y=%.1f z=%.1f h=%.1f'):format(src,x,y,z,heading))
end)

-- ── Skin update (karakter ujratestreszabas utan) ─────────────────

RegisterNetEvent('nxn-identity:server:updateSkin')
AddEventHandler('nxn-identity:server:updateSkin', function(skin)
    local src = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    MySQL.update([[
        UPDATE `nxn_identities` SET
            skin_color=?, eye_color=?, hair_style=?, hair_color=?, hair_highlight=?,
            face_features=?, outfit=?
        WHERE identifier=?
    ]], {
        skin.skin_color, skin.eye_color, skin.hair_style, skin.hair_color, skin.hair_highlight,
        skin.face_features and json.encode(skin.face_features) or nil,
        skin.outfit        and json.encode(skin.outfit)        or nil,
        identifier
    })

    if identCache[src] then
        for k,v in pairs(skin) do identCache[src][k] = v end
    end

    NXN.Identity.Log(('Skin frissitve: src=%d'):format(src))
end)

-- ── Disconnect cleanup ────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local src = source
    local data = identCache[src]
    if not data then return end
    -- Vegso pozicio mentes
    NXN.Identity.Log(('playerDropped pozicio mentes: src=%d'):format(src))
    -- (a kliens mar kuldott savePosition-t, de biztonsagkent cache-bol is irjuk)
    MySQL.update(
        'UPDATE `nxn_identities` SET pos_x=?, pos_y=?, pos_z=?, pos_heading=? WHERE identifier=?',
        { data.pos_x, data.pos_y, data.pos_z, data.pos_heading, data.identifier }
    )
    identCache[src] = nil
end)

-- ── Exportok (szerver) ──────────────────────────────────────────

--- Teljes identitas adat visszaadasa
---@param src number
---@return table|nil
exports('getIdentity', function(src)
    local d = identCache[src]
    NXN.Identity.Log(('getIdentity export: src=%d found=%s'):format(src, tostring(d ~= nil)))
    return d
end)

--- Csak nev visszaadasa (pl. igazolvany)
---@param src number
---@return string|nil  'Vezetéknév Keresztnév' formatum
exports('getFullName', function(src)
    local d = identCache[src]
    if not d then return nil end
    return (d.firstname or '') .. ' ' .. (d.lastname or '')
end)

--- Csak keresztnev
---@param src number
---@return string|nil
exports('getFirstName', function(src)
    local d = identCache[src]
    return d and d.firstname or nil
end)

--- Csak vezeteknev
---@param src number
---@return string|nil
exports('getLastName', function(src)
    local d = identCache[src]
    return d and d.lastname or nil
end)

--- Nem (0=ferfi 1=no)
---@param src number
---@return number|nil
exports('getGender', function(src)
    local d = identCache[src]
    return d and d.gender or nil
end)

--- Szuletesi datum string
---@param src number
---@return string|nil  'ÉÉÉÉ.HH.NN'
exports('getBirthDate', function(src)
    local d = identCache[src]
    if not d then return nil end
    return ('%04d.%02d.%02d'):format(d.birth_year, d.birth_month, d.birth_day)
end)

--- Eletkor szamitasa
---@param src number
---@return number|nil
exports('getAge', function(src)
    local d = identCache[src]
    if not d then return nil end
    local now = os.date('*t')
    local age = now.year - d.birth_year
    if now.month < d.birth_month or (now.month == d.birth_month and now.day < d.birth_day) then
        age = age - 1
    end
    return age
end)

--- Van-e mar identitasa a jatekosnak
---@param src number
---@return boolean
exports('hasIdentity', function(src)
    return identCache[src] ~= nil
end)

--- Osszes online identitas cache
---@return table
exports('getAllIdentities', function()
    return identCache
end)
