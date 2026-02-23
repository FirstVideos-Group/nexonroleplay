// ============================================================
//  nxn-hud | app.js
// ============================================================

const root = document.getElementById('hud-root');

// Modul cache { name: { element, enabled, alwaysVisible, order } }
const modules = {};

// ── Inizializalas ───────────────────────────────────────────────

function init(cfg) {
    // Pozicio beallitasa
    setPosition(cfg.position || 'bottom-left');

    // Modulok bejegyezese
    document.querySelectorAll('.hud-module').forEach(el => {
        const name = el.dataset.module;
        const modCfg = cfg.modules && cfg.modules[name];
        modules[name] = {
            el,
            enabled:       modCfg ? modCfg.enabled       : true,
            alwaysVisible: modCfg ? modCfg.alwaysVisible : true,
            order:         modCfg ? modCfg.order         : 99,
            tempVisible:   false,
        };

        // Rendezesi sorrend
        el.style.order = modules[name].order;

        // Kezdeti lathatosag
        if (modCfg && modCfg.enabled && modCfg.alwaysVisible) {
            el.style.display = '';
        } else {
            el.style.display = 'none';
        }
    });
}

// ── Pozicio ───────────────────────────────────────────────────

function setPosition(pos) {
    root.className = '';
    root.classList.add('pos-' + (pos || 'bottom-left'));
}

// ── HUD lathatosag ────────────────────────────────────────────

function setHudVisible(visible) {
    if (visible) {
        root.classList.remove('hidden');
    } else {
        root.classList.add('hidden');
    }
}

// ── Modul be/kikapcsolas ───────────────────────────────────────

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

// ── Bar / badge frissites ───────────────────────────────────────

const BAR_MODULES = ['health','armor','hunger','thirst','stamina','oxygen','stress'];

function updateModule(data) {
    const name  = data.module;
    const value = data.value !== undefined ? parseFloat(data.value) : null;

    if (name === 'health') {
        setBar('health', data.value);
        setBar('armor',  data.armor !== undefined ? data.armor : null);
        return;
    }

    if (BAR_MODULES.includes(name) && value !== null) {
        setBar(name, value);
        return;
    }

    // Badge modulok
    updateModuleData(data);
}

function setBar(name, value) {
    if (value === null) return;
    const bar = document.getElementById('bar-' + name);
    const val = document.getElementById('val-' + name);
    if (bar) bar.style.width = Math.max(0, Math.min(100, value)) + '%';
    if (val) val.textContent  = Math.round(value);
}

function updateModuleData(data) {
    const name = data.module;
    if (name === 'money') {
        const el = document.getElementById('val-money');
        if (el) el.textContent = (data.currency || '$') + (data.amount || 0).toLocaleString();
    } else if (name === 'job') {
        const el = document.getElementById('val-job');
        if (el) el.textContent = [data.name, data.grade].filter(Boolean).join(' – ');
    } else if (name === 'playerid') {
        const el = document.getElementById('val-playerid');
        if (el) el.textContent = '#' + (data.id || 0);
    } else if (name === 'datetime') {
        // JS oldali idofrissites
        tickDatetime();
    }
}

// ── Idopont frissites ────────────────────────────────────────────

function tickDatetime() {
    const el = document.getElementById('val-datetime');
    if (!el) return;
    const now  = new Date();
    const hh   = String(now.getHours()).padStart(2, '0');
    const mm   = String(now.getMinutes()).padStart(2, '0');
    const dd   = String(now.getDate()).padStart(2, '0');
    const mo   = String(now.getMonth() + 1).padStart(2, '0');
    el.textContent = `${hh}:${mm}  ${dd}.${mo}.`;
}

// 1 perces JS-oldali auto-frissites
setInterval(tickDatetime, 60000);

// ── Ideiglenes modul show/hide ───────────────────────────────────

function showModuleTemporary(name) {
    const m = modules[name];
    if (!m || !m.enabled) return;
    m.el.classList.remove('hud-module--fading-out');
    m.el.style.display = '';
    m.tempVisible = true;
}

function hideModuleTemporary(name) {
    const m = modules[name];
    if (!m) return;
    m.el.classList.add('hud-module--fading-out');
    setTimeout(() => {
        if (m.el.classList.contains('hud-module--fading-out')) {
            m.el.style.display = 'none';
            m.el.classList.remove('hud-module--fading-out');
            m.tempVisible = false;
        }
    }, 260);
}

// ── NUI message feldolgozas ────────────────────────────────────

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'init':               init(d);                          break;
        case 'setVisible':         setHudVisible(d.visible);         break;
        case 'setModule':          setModule(d.module, d.enabled);   break;
        case 'setPosition':        setPosition(d.position);          break;
        case 'updateModule':       updateModule(d);                   break;
        case 'updateModuleData':   updateModuleData(d);              break;
        case 'showModuleTemporary': showModuleTemporary(d.module);   break;
        case 'hideModuleTemporary': hideModuleTemporary(d.module);   break;
        case 'tickDatetime':       tickDatetime();                    break;
    }
});
