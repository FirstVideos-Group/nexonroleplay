// ============================================================
//  nxn-location-hud | app.js
//  FIX: alwaysVisible init logika javitva (nem hard-coded lista)
//       modul loopok kozvetlenul SendNUIMessage-t hasznalnak
// ============================================================

const root = document.getElementById('lhud-root');

// Modul cache
const modules = {};

// Jatekos statusz szoveg + ikon terkep
const STATUS_MAP = {
    on_foot:       { label: 'GYALOG',      icon: 'hgi-walking-helmet'   },
    walking:       { label: 'GYALOG',      icon: 'hgi-walking-helmet'   },
    running:       { label: 'FUT',         icon: 'hgi-running-shoes-01' },
    in_vehicle:    { label: 'AUTÓBAN',    icon: 'hgi-car-01'           },
    on_bike:       { label: 'MOTOR',       icon: 'hgi-motorbike-01'     },
    on_boat:       { label: 'HAJÓN',      icon: 'hgi-sailboat'         },
    in_helicopter: { label: 'HELIKOPTER', icon: 'hgi-helicopter'       },
    in_plane:      { label: 'REPÜLŐ',    icon: 'hgi-airplane-01'      },
    swimming:      { label: 'ÚSZIK',       icon: 'hgi-swimming'         },
    diving:        { label: 'MERÜL',      icon: 'hgi-scuba-diving'     },
    parachuting:   { label: 'UGRIK',       icon: 'hgi-parachute'        },
};

// ── Init ────────────────────────────────────────────────────────────

function init(cfg) {
    setPosition(cfg.position || 'bottom-left');

    document.querySelectorAll('.lhud-module').forEach(el => {
        const name   = el.dataset.module;
        if (!name) return;
        const modCfg = cfg.modules && cfg.modules[name];
        const enabled       = modCfg ? modCfg.enabled       : false;
        const alwaysVisible = modCfg ? modCfg.alwaysVisible : false;
        const order         = modCfg ? modCfg.order         : 99;

        modules[name] = { el, enabled, alwaysVisible, order, tempVisible: false };
        el.style.order = order;

        // FIX: lathatosag a config alwaysVisible mezo alapjan dontodik
        // nem hard-coded nev lista alapjan
        if (enabled && alwaysVisible) {
            el.style.display = '';
        } else {
            el.style.display = 'none';
        }
    });
}

// ── Pozicio ─────────────────────────────────────────────────────────

function setPosition(pos) {
    root.className = '';
    root.classList.add('pos-' + (pos || 'bottom-left'));
}

// ── HUD lathatosag ────────────────────────────────────────────────

function setHudVisible(visible) {
    root.classList.toggle('hidden', !visible);
}

// ── Modul be/kikapcsolas ──────────────────────────────────────────

function setModule(name, enabled) {
    const m = modules[name];
    if (!m) return;
    m.enabled = enabled;
    if (!enabled) {
        m.el.style.display = 'none';
    } else if (m.alwaysVisible) {
        m.el.style.display = '';
    }
}

// ── Ideiglenes show/hide ─────────────────────────────────────────

function showModuleTemporary(name) {
    const m = modules[name];
    if (!m || !m.enabled) return;
    m.el.classList.remove('lhud-module--fading-out');
    m.el.style.display = '';
    m.tempVisible = true;
}

function hideModuleTemporary(name) {
    const m = modules[name];
    if (!m) return;
    m.el.classList.add('lhud-module--fading-out');
    setTimeout(() => {
        if (m.el.classList.contains('lhud-module--fading-out')) {
            m.el.style.display = 'none';
            m.el.classList.remove('lhud-module--fading-out');
            m.tempVisible = false;
        }
    }, 220);
}

// ── Modul frissitesek ─────────────────────────────────────────────

function updateModule(data) {
    const name = data.module;

    if (name === 'district') {
        const el = document.getElementById('val-district');
        if (el) el.textContent = data.name || 'Ismeretlen';
        return;
    }

    if (name === 'street') {
        const s = document.getElementById('val-street');
        const c = document.getElementById('val-cross');
        if (s) s.textContent = data.name || '';
        if (c) {
            if (data.cross && data.cross !== '') {
                c.textContent   = '\u2229 ' + data.cross;
                c.style.display = '';
            } else {
                c.style.display = 'none';
            }
        }
        return;
    }

    if (name === 'minimap') {
        const el = document.getElementById('val-coords');
        if (el) el.textContent = data.coords || '0 / 0';
        return;
    }

    if (name === 'zone') {
        const zn  = document.getElementById('val-zone-name');
        const zg  = document.getElementById('val-zone-gang');
        const blk = document.querySelector('.lhud-zone-block');
        if (zn) zn.textContent = data.zoneName || '';
        if (zg) {
            zg.textContent  = data.gangName || '';
            zg.style.display = data.gangName ? '' : 'none';
        }
        if (blk && data.gangColor && data.gangColor !== '') {
            blk.style.borderLeftColor = data.gangColor;
            const icon = blk.querySelector('i');
            if (icon) icon.style.color = data.gangColor;
        } else if (blk) {
            blk.style.borderLeftColor = '';
            const icon = blk.querySelector('i');
            if (icon) icon.style.color = '';
        }
        return;
    }

    if (name === 'danger') {
        const label = document.getElementById('val-danger-label');
        const dots  = document.querySelectorAll('.lhud-dot');
        if (label) label.textContent = data.label || 'VESZELY';
        const lvl = Math.max(0, Math.min(5, parseInt(data.level) || 0));
        dots.forEach((dot, i) => {
            dot.className = 'lhud-dot';
            if (i < lvl) dot.classList.add('active-' + (i + 1));
        });
        return;
    }

    if (name === 'wanted') {
        const val   = document.getElementById('val-wanted');
        const stars = document.querySelectorAll('.lhud-wanted-stars i');
        const lvl   = Math.max(0, Math.min(5, parseInt(data.level) || 0));
        if (val) val.textContent = data.label || 'KÖRÖZÖTT';
        stars.forEach((s, i) => s.classList.toggle('active', i < lvl));
        return;
    }

    if (name === 'playerstatus') {
        const icon = document.getElementById('icon-playerstatus');
        const lbl  = document.getElementById('val-playerstatus');
        const s    = STATUS_MAP[data.status] || STATUS_MAP.on_foot;
        if (icon) icon.className = 'hgi hgi-stroke ' + s.icon;
        if (lbl)  lbl.textContent = s.label;
        return;
    }
}

// ── NUI message feldolgozas ────────────────────────────────────────

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;
    switch (d.action) {
        case 'init':                init(d);                          break;
        case 'setVisible':          setHudVisible(d.visible);         break;
        case 'setModule':           setModule(d.module, d.enabled);   break;
        case 'setPosition':         setPosition(d.position);          break;
        case 'updateModule':        updateModule(d);                   break;
        case 'updateModuleData':    updateModule(d);                   break;
        case 'showModuleTemporary': showModuleTemporary(d.module);    break;
        case 'hideModuleTemporary': hideModuleTemporary(d.module);    break;
    }
});
