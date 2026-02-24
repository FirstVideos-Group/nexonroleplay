// ============================================================
//  nxn-minimap | app.js
// ============================================================

const root     = document.getElementById('nmap-root');
const frame    = document.getElementById('nmap-frame');
const gpsEl    = document.getElementById('nmap-gps');
const gpsLabel = document.getElementById('nmap-gps-label');
const distEl   = document.getElementById('nmap-district');
const distNum  = document.getElementById('nmap-district-num');
const distName = document.getElementById('nmap-district-name');

// ── Init ──────────────────────────────────────────────────────

function init(cfg) {
    // Méret beállítás CSS változón keresztül
    const w = (cfg.width  || 200) + 'px';
    const h = (cfg.height || 200) + 'px';
    document.documentElement.style.setProperty('--nmap-w', w);
    document.documentElement.style.setProperty('--nmap-h', h);

    setPosition(cfg.position || 'bottom-left');
    setVisible(cfg.visible !== false);

    // GPS panel alapállapot
    if (!cfg.showGPS) {
        gpsEl.style.display = 'none';
    }

    // District panel alapállapot
    distEl.style.display = 'none';

    if (cfg.gpsActiveLabel) {
        gpsLabel.textContent = cfg.gpsActiveLabel;
    }
}

// ── Pozíció ───────────────────────────────────────────────────

function setPosition(pos) {
    root.className = 'pos-' + (pos || 'bottom-left');
}

// ── Láthatóság ────────────────────────────────────────────────

function setVisible(visible) {
    root.classList.toggle('hidden', !visible);
}

// ── GPS jelzés ────────────────────────────────────────────────

function setGPS(data) {
    if (data.active) {
        if (data.label) gpsLabel.textContent = data.label;
        gpsEl.classList.remove('nmap-fading-out');
        gpsEl.style.display = '';
    } else {
        fadeOut(gpsEl);
    }
}

function setGPSEnabled(data) {
    if (!data.enabled) {
        fadeOut(gpsEl);
    }
}

// ── Kerület ───────────────────────────────────────────────────

function setDistrict(data) {
    if (!data.visible) {
        fadeOut(distEl);
        return;
    }
    distNum.textContent  = data.number || '';
    distName.textContent = data.name   || '';

    // Szín alkalmazása ha van
    if (data.color && data.color !== '') {
        distNum.style.color = data.color;
    } else {
        distNum.style.color = '';
    }

    distEl.classList.remove('nmap-fading-out');
    distEl.style.display = '';
}

// ── Blip jelzés (vizuális visszajelzés) ───────────────────────

function setBlips(data) {
    // A tényleges blip kezelés Lua oldalon történik,
    // itt csak egy vizuális indikátort tudunk mutatni ha szükséges
    // (jelenleg nincs UI elem ehhez, bővíthetőségért van itt)
}

// ── Segéd: fade out animáció ──────────────────────────────────

function fadeOut(el) {
    if (el.style.display === 'none') return;
    el.classList.add('nmap-fading-out');
    setTimeout(() => {
        if (el.classList.contains('nmap-fading-out')) {
            el.style.display = 'none';
            el.classList.remove('nmap-fading-out');
        }
    }, 220);
}

// ── NUI message feldolgozás ───────────────────────────────────

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;
    switch (d.action) {
        case 'init':          init(d);              break;
        case 'setVisible':    setVisible(d.visible); break;
        case 'setPosition':   setPosition(d.position); break;
        case 'setGPS':        setGPS(d);            break;
        case 'setGPSEnabled': setGPSEnabled(d);     break;
        case 'setDistrict':   setDistrict(d);       break;
        case 'setBlips':      setBlips(d);          break;
    }
});
