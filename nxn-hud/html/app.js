// ============================================================
//  nxn-hud | app.js
//  FIX: Lua komment (--) eltavolitva JS-bol (SyntaxError volt)
//  FIX: setPosition classList.add/remove-ra javitva
//       (className= torolte volna a 'hidden' classt is)
// ============================================================

const root      = document.getElementById('hud-root');
const panelTemp = document.getElementById('panel-temp');

// Aktiv temp bar-ok nyilvantartasa
const activeTempBars = new Set();

// -- Init --------------------------------------------------

function init(cfg) {
    setPosition(cfg.position || 'bottom-left');

    // Badge modulok lathatosaga config alapjan
    const badgeModules = ['money', 'job', 'playerid', 'datetime'];
    badgeModules.forEach(name => {
        const el  = document.querySelector('[data-module="' + name + '"]');
        const mod = cfg.modules && cfg.modules[name];
        if (el) {
            el.style.display = (mod && mod.enabled) ? '' : 'none';
        }
    });

    if (cfg.modules && cfg.modules.datetime && cfg.modules.datetime.enabled) {
        tickDatetime();
    }
}

// -- Pozicio -----------------------------------------------
// FIX: classList.remove + add, nem className=
// igy a 'hidden' class nem veszik el poziciovaltas kozben

function setPosition(pos) {
    root.classList.remove('pos-bottom-left', 'pos-bottom-right', 'pos-top-left', 'pos-top-right');
    root.classList.add('pos-' + (pos || 'bottom-left'));
}

// -- HUD lathatosag ----------------------------------------

function setHudVisible(visible) {
    root.classList.toggle('hidden', !visible);
}

// -- Bar frissites -----------------------------------------

const BAR_MODULES  = ['health','armor','hunger','thirst','stamina','oxygen','stress'];
const TEMP_MODULES = ['stamina','oxygen','stress'];

function setBar(name, value) {
    if (value === null || value === undefined) return;
    const bar = document.getElementById('bar-' + name);
    const val = document.getElementById('val-' + name);
    if (bar) bar.style.width = Math.max(0, Math.min(100, value)) + '%';
    if (val) val.textContent  = Math.round(value);
}

function updateModule(data) {
    const name  = data.module;
    const value = data.value !== undefined ? parseFloat(data.value) : null;

    if (name === 'health') {
        setBar('health', data.value);
        if (data.armor !== undefined) setBar('armor', data.armor);
        return;
    }

    if (BAR_MODULES.includes(name) && value !== null) {
        setBar(name, value);
        return;
    }

    updateBadge(data);
}

// -- Badge frissites ----------------------------------------

function updateBadge(data) {
    const name = data.module;
    if (name === 'money') {
        const el = document.getElementById('val-money');
        if (el) el.textContent = (data.currency || '$') + (data.amount || 0).toLocaleString();
    } else if (name === 'job') {
        const el = document.getElementById('val-job');
        if (el) el.textContent = [data.name, data.grade].filter(Boolean).join(' - ');
    } else if (name === 'playerid') {
        const el = document.getElementById('val-playerid');
        if (el) el.textContent = '#' + (data.id || 0);
    } else if (name === 'datetime') {
        tickDatetime();
    }
}

// -- Idopont -----------------------------------------------

function tickDatetime() {
    const el = document.getElementById('val-datetime');
    if (!el) return;
    const now = new Date();
    const hh  = String(now.getHours()).padStart(2, '0');
    const mm  = String(now.getMinutes()).padStart(2, '0');
    const dd  = String(now.getDate()).padStart(2, '0');
    const mo  = String(now.getMonth() + 1).padStart(2, '0');
    el.textContent = hh + ':' + mm + '  ' + dd + '.' + mo + '.';
}

setInterval(tickDatetime, 60000);

// -- Temp panel lathatosag ----------------------------------
// Ha legalabb egy temp bar aktiv, a panel latszik.
// Ha az osszes el lett rejtve, a panel is eltnik.

function updateTempPanel() {
    if (activeTempBars.size > 0) {
        panelTemp.classList.remove('hud-module--fading-out');
        panelTemp.style.display = '';
    } else {
        panelTemp.classList.add('hud-module--fading-out');
        setTimeout(function() {
            if (activeTempBars.size === 0) {
                panelTemp.style.display = 'none';
                panelTemp.classList.remove('hud-module--fading-out');
            }
        }, 260);
    }
}

// -- Ideiglenes bar show/hide -------------------------------

function showModuleTemporary(name) {
    if (!TEMP_MODULES.includes(name)) return;
    const row = document.getElementById('row-' + name);
    if (!row) return;
    row.classList.remove('hud-module--fading-out');
    row.style.display = '';
    activeTempBars.add(name);
    updateTempPanel();
}

function hideModuleTemporary(name) {
    if (!TEMP_MODULES.includes(name)) return;
    const row = document.getElementById('row-' + name);
    if (!row) return;
    row.classList.add('hud-module--fading-out');
    activeTempBars.delete(name);
    setTimeout(function() {
        if (row.classList.contains('hud-module--fading-out')) {
            row.style.display = 'none';
            row.classList.remove('hud-module--fading-out');
        }
        updateTempPanel();
    }, 260);
}

// -- Modul be/kikapcsolas -----------------------------------

function setModule(name, enabled) {
    const badgeEl = document.querySelector('[data-module="' + name + '"]');
    if (badgeEl && !TEMP_MODULES.includes(name)) {
        badgeEl.style.display = enabled ? '' : 'none';
    }
    if (TEMP_MODULES.includes(name) && !enabled) {
        hideModuleTemporary(name);
    }
}

// -- NUI message feldolgozas --------------------------------

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;
    switch (d.action) {
        case 'init':                init(d);                        break;
        case 'setVisible':          setHudVisible(d.visible);       break;
        case 'setModule':           setModule(d.module, d.enabled); break;
        case 'setPosition':         setPosition(d.position);        break;
        case 'updateModule':        updateModule(d);                 break;
        case 'updateModuleData':    updateBadge(d);                  break;
        case 'showModuleTemporary': showModuleTemporary(d.module);  break;
        case 'hideModuleTemporary': hideModuleTemporary(d.module);  break;
        case 'tickDatetime':        tickDatetime();                  break;
    }
});
