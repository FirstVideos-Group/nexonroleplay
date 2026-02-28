// ============================================================
//  nxn-vehicle-hud | app.js
// ============================================================

const root      = document.getElementById('vhud-root');
const statusRow = document.getElementById('status-row');

// Modul cache { name: { el, enabled, alwaysVisible, order } }
const modules = {};
let   speedUnit = 'kmh';

// ── Init ──────────────────────────────────────────────────

function init(cfg) {
    setPosition(cfg.position || 'bottom-right');
    speedUnit = cfg.speedUnit || 'kmh';

    document.querySelectorAll('.vhud-module').forEach(el => {
        const name   = el.dataset.module;
        const modCfg = cfg.modules && cfg.modules[name];
        modules[name] = {
            el,
            enabled:       modCfg ? modCfg.enabled       : false,
            alwaysVisible: modCfg ? modCfg.alwaysVisible : false,
            order:         modCfg ? modCfg.order         : 99,
            tempVisible:   false,
        };
        el.style.order = modules[name].order;

        // Kezdeti lathatosag: speed/rpm/gear alap clusterben el
        // Status ikonok: alwaysVisible szerint
        if (modCfg && modCfg.enabled && modCfg.alwaysVisible) {
            el.style.display = '';
        } else if (!['speed','rpm','gear'].includes(name)) {
            el.style.display = 'none';
        }
    });

    const unitEl = document.getElementById('val-speed-unit');
    if (unitEl) unitEl.textContent = speedUnit === 'mph' ? 'mph' : 'km/h';
}

// ── Pozicio ───────────────────────────────────────────────

function setPosition(pos) {
    root.className = '';
    root.classList.add('pos-' + (pos || 'bottom-right'));
}

// ── HUD lathatosag ─────────────────────────────────────────

function setHudVisible(visible) {
    if (visible) {
        root.classList.remove('hidden');
    } else {
        root.classList.add('hidden');
        // HUD elrejtesekor az osszes ideiglenes modult is elrejtjuk
        Object.values(modules).forEach(m => {
            if (m.tempVisible && !m.alwaysVisible) {
                m.el.style.display = 'none';
                m.tempVisible = false;
            }
        });
    }
}

// ── Modul be/kikapcsolas ───────────────────────────────────

function setModule(name, enabled) {
    const m = modules[name];
    if (!m) return;
    m.enabled = enabled;
    if (!enabled) {
        m.el.style.display = 'none';
        m.tempVisible = false;
    } else if (m.alwaysVisible) {
        m.el.style.display = '';
    }
}

// ── Ideiglenes show/hide ───────────────────────────────────
// FIX: showModuleTemporary ellenorizte m.enabled-et, de az init utan
// az enabled flag helyesen van beallitva (config.lua-bol jon).
// A guard megmarad, de az enabled=false esetet most a config.lua javitja.

function showModuleTemporary(name) {
    const m = modules[name];
    // FIX: enabled guard eltavolitva - ha a Lua oldal hivja, az mar
    // ellenorizte a moduleStates-t; a JS ne duplikkan tagadja
    if (!m) return;
    m.el.classList.remove('vhud-module--fading-out');
    m.el.style.display = '';
    m.tempVisible = true;
}

function hideModuleTemporary(name) {
    const m = modules[name];
    if (!m) return;
    m.el.classList.add('vhud-module--fading-out');
    setTimeout(() => {
        if (m.el.classList.contains('vhud-module--fading-out')) {
            m.el.style.display = 'none';
            m.el.classList.remove('vhud-module--fading-out');
            m.tempVisible = false;
        }
    }, 220);
}

// ── Modul frissitesek ────────────────────────────────────────

function updateModule(data) {
    const name = data.module;

    if (name === 'speed') {
        const el = document.getElementById('val-speed');
        if (el) el.textContent = data.value || 0;
        if (data.unit) {
            const u = document.getElementById('val-speed-unit');
            if (u) u.textContent = data.unit === 'mph' ? 'mph' : 'km/h';
        }
        return;
    }

    if (name === 'rpm') {
        const bar = document.getElementById('bar-rpm');
        if (bar) {
            const v = Math.max(0, Math.min(100, data.value || 0));
            bar.style.width = v + '%';
            bar.classList.toggle('redline', v >= 85);
        }
        return;
    }

    if (name === 'gear') {
        const el    = document.getElementById('val-gear');
        if (el) {
            el.classList.remove('reverse', 'neutral');
            if (data.reverse) {
                el.textContent = 'R';
                el.classList.add('reverse');
            } else if (data.gear === 0) {
                el.textContent = 'N';
                el.classList.add('neutral');
            } else {
                el.textContent = data.gear;
            }
        }
        return;
    }

    if (name === 'lights') {
        const posEl    = document.getElementById('icon-lights-pos');
        const highEl   = document.getElementById('icon-lights-high');
        const hazardEl = document.getElementById('icon-lights-hazard');
        if (posEl)    posEl.style.display    = data.pos    ? '' : 'none';
        if (highEl)   highEl.style.display   = data.high   ? '' : 'none';
        if (hazardEl) hazardEl.style.display = data.hazard ? '' : 'none';
        return;
    }

    if (name === 'engine') {
        const icon  = document.getElementById('icon-engine');
        const label = document.getElementById('label-engine');
        const STATE_MAP = {
            ok:       { cls: 'engine-ok',       txt: 'OK'        },
            damaged:  { cls: 'engine-damaged',  txt: 'SÉRÜLT'   },
            critical: { cls: 'engine-critical', txt: 'KRITIKUS'  },
            off:      { cls: 'engine-off',      txt: 'LEÁLLVA'   },
        };
        const s = STATE_MAP[data.state] || STATE_MAP.ok;
        if (icon)  icon.className    = 'hgi hgi-stroke hgi-engine-01 ' + s.cls;
        if (label) { label.textContent = s.txt; label.className = 'vhud-status-label ' + s.cls; }
        return;
    }

    if (name === 'fuel') {
        const bar = document.getElementById('bar-fuel');
        const val = document.getElementById('val-fuel');
        const ico = document.getElementById('icon-fuel');
        const v   = Math.max(0, Math.min(100, data.value || 0));
        if (bar) {
            bar.style.width = v + '%';
            bar.className = 'vhud-fuel-fill' + (v <= 10 ? ' empty' : v <= 25 ? ' low' : '');
        }
        if (val) val.textContent = Math.round(v);
        if (ico) {
            ico.className = 'hgi hgi-stroke hgi-gas-stove ' +
                (v <= 10 ? 'engine-critical' : v <= 25 ? 'engine-damaged' : '');
        }
        return;
    }

    if (name === 'seatbelt') {
        // show/hide a client.lua setSeatbelt exportja kezeli
        return;
    }

    if (name === 'siren') {
        const label = document.getElementById('label-siren');
        // FIX: data.mode a stage label (pl. 'CODE 1', 'CODE 2', 'CODE 3')
        // Ha active=false, 'KI' feliratot mutatunk rovid ideig, majd eltunik
        if (label) {
            if (data.active) {
                label.textContent = data.mode ? String(data.mode).toUpperCase() : 'AKTÍV';
            } else {
                label.textContent = 'KI';
            }
        }
        return;
    }
}

// ── NUI message feldolgozas ───────────────────────────────────

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
