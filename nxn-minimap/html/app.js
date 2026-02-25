// ============================================================
//  nxn-minimap | app.js
//  FIX: #nmap-root kezdeti pozicio class init-kor beallitva
//       (korabban class nelkul volt -> elem a viewport-on kivul)
// ============================================================

const root     = document.getElementById('nmap-root');
const frame    = document.getElementById('nmap-frame');
const gpsEl    = document.getElementById('nmap-gps');
const gpsLabel = document.getElementById('nmap-gps-label');
const distEl   = document.getElementById('nmap-district');
const distNum  = document.getElementById('nmap-district-num');
const distName = document.getElementById('nmap-district-name');

// ── Init ────────────────────────────────────────────────────────────

function init(cfg) {
    // Meret CSS valtozon keresztul
    const w = (cfg.width  || 200) + 'px';
    const h = (cfg.height || 200) + 'px';
    document.documentElement.style.setProperty('--nmap-w', w);
    document.documentElement.style.setProperty('--nmap-h', h);

    // FIX: pozicio class AZONNAL beallitva – kulonben az elem
    // nem kap bottom/left/right/top erteket es a viewport-on kivul marad
    setPosition(cfg.position || 'bottom-left');

    // Lathatosag
    setVisible(cfg.visible !== false);

    // GPS panel alapallapot
    if (!cfg.showGPS) {
        gpsEl.style.display = 'none';
    }

    // District panel alapbol rejtve, adatra var
    distEl.style.display = 'none';

    if (cfg.gpsActiveLabel) {
        gpsLabel.textContent = cfg.gpsActiveLabel;
    }
}

// ── Pozicio ─────────────────────────────────────────────────────────

function setPosition(pos) {
    // Toroljuk az osszes pos-* classt, majd hozzaadjuk a helyeset
    root.classList.remove('pos-bottom-left', 'pos-bottom-right', 'pos-top-left', 'pos-top-right');
    root.classList.add('pos-' + (pos || 'bottom-left'));
}

// ── Lathatosag ──────────────────────────────────────────────────

function setVisible(visible) {
    root.classList.toggle('hidden', !visible);
}

// ── GPS jelzes ────────────────────────────────────────────────

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
    if (!data.enabled) fadeOut(gpsEl);
}

// ── Kerulet ───────────────────────────────────────────────────

function setDistrict(data) {
    if (!data.visible) {
        fadeOut(distEl);
        return;
    }
    distNum.textContent  = data.number || '';
    distName.textContent = data.name   || '';

    if (data.color && data.color !== '') {
        distNum.style.color = data.color;
    } else {
        distNum.style.color = '';
    }

    distEl.classList.remove('nmap-fading-out');
    distEl.style.display = '';
}

// ── Blip jelzes ───────────────────────────────────────────────

function setBlips(data) {
    // A blip elrejtese Lua oldalon tortenik (SetRadarAsInteriorThisFrame)
    // UI jelzes boviteshez fenntartva
}

// ── Segd: fade out ────────────────────────────────────────────

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

// ── NUI message ───────────────────────────────────────────────

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;
    switch (d.action) {
        case 'init':          init(d);                break;
        case 'setVisible':    setVisible(d.visible);  break;
        case 'setPosition':   setPosition(d.position); break;
        case 'setGPS':        setGPS(d);              break;
        case 'setGPSEnabled': setGPSEnabled(d);       break;
        case 'setDistrict':   setDistrict(d);         break;
        case 'setBlips':      setBlips(d);            break;
    }
});
