/* ============================================================
   nxn-loading | app.js
   ============================================================ */

'use strict';

// ── Config átvéve a Lua-tól (alapértékek) ────────────────────
const LS = {
    modules: [],
    currentModuleIndex: 0,
    totalWeight: 0,
    completedWeight: 0,
    loadingDone: false,
    musicEnabled: true,
    musicVolume: 0.35,
    musicFadeOut: 2000,
    enterBtnText: 'Irány a város!',
    minLoadTime: 3000,
    startTime: Date.now()
};

// ── DOM referenciák ──────────────────────────────────────────
const $id = id => document.getElementById(id);

// ── NUI üzenet fogadása ──────────────────────────────────────
window.addEventListener('message', function(event) {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {

        case 'serverData':
            handleServerData(data.data);
            break;

        case 'queueUpdate':
            handleQueueUpdate(data.position, data.total);
            break;

        case 'externalModule':
            handleExternalModule(data.name, data.percent);
            break;

        case 'setStatus':
            setStatus(data.text);
            break;
    }
});

// ── Szerver adat feldolgozás ─────────────────────────────────
function handleServerData(d) {
    $id('ls-server-name').textContent = d.serverName  || 'Nexon Roleplay';
    $id('ls-server-desc').textContent = d.description || '';
    $id('info-online').textContent    = d.online      || '–';
    $id('info-max').textContent       = d.maxPlayers  || '–';

    // Szabályok
    if (d.rules && d.rules.length) buildRules(d.rules);
    // Billentyűk
    if (d.keybinds && d.keybinds.length) buildKeybinds(d.keybinds);

    setStatus('Modulok betöltése…');
}

// ── Szabályok felépítése ─────────────────────────────────────
function buildRules(rules) {
    const grid = $id('rules-list');
    grid.innerHTML = '';
    rules.forEach(r => {
        const card = document.createElement('div');
        card.className = 'ls-rule-card';
        card.innerHTML = `
            <div class="rule-icon"><i class="hgi hgi-stroke ${r.icon || 'hgi-information-circle'}"></i></div>
            <h4>${escHtml(r.title)}</h4>
            <p>${escHtml(r.text)}</p>
        `;
        grid.appendChild(card);
    });
}

// ── Billentyűk felépítése ────────────────────────────────────
function buildKeybinds(keys) {
    const wrap = $id('keybinds-list');
    wrap.innerHTML = '';
    keys.forEach(k => {
        const row = document.createElement('div');
        row.className = 'ls-keybind-row';
        row.innerHTML = `
            <span class="ls-key-badge">${escHtml(k.key)}</span>
            <span class="ls-key-desc">${escHtml(k.desc)}</span>
        `;
        wrap.appendChild(row);
    });
}

// ── Modul lista felépítése ───────────────────────────────────
function buildModuleList(modules) {
    LS.modules = modules;
    LS.totalWeight = modules.reduce((s, m) => s + (m.weight || 10), 0);
    LS.completedWeight = 0;
    LS.currentModuleIndex = 0;

    const list = $id('module-list');
    list.innerHTML = '';
    modules.forEach((m, i) => {
        const row = document.createElement('div');
        row.className = 'ls-module-row';
        row.id = 'mod-row-' + i;
        row.innerHTML = `
            <i class="hgi hgi-stroke hgi-circle" id="mod-icon-${i}"></i>
            <span style="flex:1;font-size:11px">${escHtml(m.name)}</span>
            <div class="mod-bar-wrap"><div class="mod-bar-fill" id="mod-bar-${i}" style="width:0%"></div></div>
            <span class="ls-module-pct" id="mod-pct-${i}">0%</span>
        `;
        list.appendChild(row);
    });

    // Animált betöltés indítása
    simulateModuleLoading();
}

// ── Szimulált modul-betöltés ─────────────────────────────────
function simulateModuleLoading() {
    if (LS.modules.length === 0) return;
    loadNextModule(0);
}

function loadNextModule(idx) {
    if (idx >= LS.modules.length) {
        finishLoading();
        return;
    }

    const mod  = LS.modules[idx];
    const row  = $id('mod-row-' + idx);
    const bar  = $id('mod-bar-' + idx);
    const pct  = $id('mod-pct-' + idx);
    const icon = $id('mod-icon-' + idx);

    if (!row) { loadNextModule(idx + 1); return; }

    row.classList.add('active');
    icon.className = 'hgi hgi-stroke hgi-loading-01';
    $id('current-module-name').textContent = mod.name;

    // Gördítjük le a listát az aktív sorra
    row.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

    // Modul betöltési idő: weight * ~80ms
    const duration = (mod.weight || 10) * 80 + Math.random() * 200;
    const start    = performance.now();
    const prevCompleted = LS.completedWeight;
    const modWeight = mod.weight || 10;

    function animate(now) {
        const elapsed  = now - start;
        const progress = Math.min(elapsed / duration, 1);
        const eased    = easeInOutCubic(progress);

        // Modul saját bar
        bar.style.width = (eased * 100).toFixed(1) + '%';
        pct.textContent = Math.round(eased * 100) + '%';

        // Globális progress
        const globalPct = ((prevCompleted + eased * modWeight) / LS.totalWeight) * 100;
        updateGlobalProgress(globalPct);

        if (progress < 1) {
            requestAnimationFrame(animate);
        } else {
            // Modul kész
            row.classList.remove('active');
            row.classList.add('done');
            icon.className = 'hgi hgi-stroke hgi-checkmark-circle-01';
            bar.style.width = '100%';
            pct.textContent = '100%';

            LS.completedWeight = prevCompleted + modWeight;
            loadNextModule(idx + 1);
        }
    }
    requestAnimationFrame(animate);
}

function updateGlobalProgress(pct) {
    const clamped = Math.min(Math.max(pct, 0), 100);
    $id('progress-fill').style.width = clamped.toFixed(1) + '%';
    $id('progress-pct').textContent  = Math.round(clamped) + '%';
}

function finishLoading() {
    const elapsed = Date.now() - LS.startTime;
    const remaining = Math.max(0, LS.minLoadTime - elapsed);

    setTimeout(() => {
        updateGlobalProgress(100);
        $id('progress-pct').textContent = '100%';
        $id('current-module-name').textContent = 'Betöltés kész!';

        // Spinner leállítása
        const spinIcon = document.querySelector('.ls-modules-title i');
        if (spinIcon) spinIcon.classList.add('done');

        setStatus('Minden modul betöltve.');
        LS.loadingDone = true;

        // Enter gomb megjelenítése
        const btn = $id('ls-enter-btn');
        btn.style.display = 'flex';
        btn.style.animation = 'nxnFadeIn .3s ease';

        // Értesítés a Lua felé
        fetch('https://nxn-loading/loadingComplete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {});
    }, remaining);
}

// ── Várólista frissítés ──────────────────────────────────────
function handleQueueUpdate(pos, total) {
    const qEl = $id('ls-queue');
    if (pos > 0) {
        qEl.style.display = 'flex';
        $id('queue-pos').textContent = `Pozíció: ${pos}. / ${total} várakozó`;
    } else {
        qEl.style.display = 'none';
    }
}

// ── Külső modul progress ─────────────────────────────────────
function handleExternalModule(name, percent) {
    // Hozzáadunk egy sort, ha még nincs
    let row = document.querySelector('[data-extmod="' + name + '"]');
    if (!row) {
        row = document.createElement('div');
        row.className = 'ls-module-row active';
        row.setAttribute('data-extmod', name);
        row.innerHTML = `
            <i class="hgi hgi-stroke hgi-link-01"></i>
            <span style="flex:1;font-size:11px">${escHtml(name)}</span>
            <div class="mod-bar-wrap"><div class="mod-bar-fill ext-bar" style="width:0%"></div></div>
            <span class="ls-module-pct ext-pct">0%</span>
        `;
        $id('module-list').appendChild(row);
    }
    const bar = row.querySelector('.ext-bar');
    const pct = row.querySelector('.ext-pct');
    bar.style.width = percent + '%';
    pct.textContent = percent + '%';
    if (percent >= 100) {
        row.classList.remove('active');
        row.classList.add('done');
    }
}

// ── Tab váltás ───────────────────────────────────────────────
function switchTab(tabId, btn) {
    document.querySelectorAll('.ls-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.ls-tab-content').forEach(c => c.classList.remove('active'));
    btn.classList.add('active');
    const content = document.getElementById('tab-' + tabId);
    if (content) content.classList.add('active');
}

// ── Enter gomb ───────────────────────────────────────────────
function enterGame() {
    if (!LS.loadingDone) return;

    const btn = $id('ls-enter-btn');
    btn.disabled = true;
    btn.style.opacity = '0.6';

    setStatus('Belépés a városba…');

    // Zene lehalkulása
    fadeOutMusic(LS.musicFadeOut, () => {
        // Screen fade out
        document.getElementById('loading-screen').classList.add('fade-out');
        // NUI callback
        fetch('https://nxn-loading/enterGame', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {});
    });
}

// ── Zene kezelés ─────────────────────────────────────────────
function initMusic(file, volume, fadeOutMs) {
    LS.musicVolume  = volume;
    LS.musicFadeOut = fadeOutMs;

    const audio = $id('bg-music');
    audio.src    = file;
    audio.volume = volume;
    audio.play().catch(() => {
        // Autoplay blokkolva – gomb megjelenítése
        LS.musicEnabled = false;
        updateMusicIcon();
    });
}

function toggleMusic() {
    const audio = $id('bg-music');
    LS.musicEnabled = !LS.musicEnabled;
    if (LS.musicEnabled) {
        audio.volume = LS.musicVolume;
        audio.play().catch(() => {});
    } else {
        audio.pause();
    }
    updateMusicIcon();
}

function updateMusicIcon() {
    const icon = $id('music-icon');
    icon.className = LS.musicEnabled
        ? 'hgi hgi-stroke hgi-volume-high'
        : 'hgi hgi-stroke hgi-volume-off';
}

function fadeOutMusic(durationMs, callback) {
    const audio = $id('bg-music');
    if (!LS.musicEnabled || audio.paused) {
        if (callback) callback();
        return;
    }

    const startVol = audio.volume;
    const steps    = 40;
    const interval = durationMs / steps;
    let   step     = 0;

    const fade = setInterval(() => {
        step++;
        audio.volume = Math.max(0, startVol * (1 - step / steps));
        if (step >= steps) {
            clearInterval(fade);
            audio.pause();
            if (callback) callback();
        }
    }, interval);
}

// ── Segédfüggvények ──────────────────────────────────────────
function setStatus(text) {
    const el = $id('ls-status');
    if (el) el.textContent = text;
}

function escHtml(str) {
    return String(str)
        .replace(/&/g,'&amp;')
        .replace(/</g,'&lt;')
        .replace(/>/g,'&gt;')
        .replace(/"/g,'&quot;');
}

function easeInOutCubic(t) {
    return t < 0.5 ? 4*t*t*t : 1 - Math.pow(-2*t+2,3)/2;
}

// ── Init ─────────────────────────────────────────────────────
(function init() {
    // Beolvassuk a config értékeket a meta tagekből
    // (Lua nem tud közvetlenül adatot adni a loadscreen HTML-nek,
    //  ezért a config-ot a Lua kliens NUI üzenettel küldi el)
    // Az alapmodulokat a config-ból kapjuk serverData-val, de
    // egy default-ot itt is felépítünk amíg megérkezik:
    const defaultModules = [
        { name: 'Core rendszer',           weight: 10 },
        { name: 'Játékoskezelés',          weight: 10 },
        { name: 'Térkép betöltése',        weight: 15 },
        { name: 'Járművek inicializálása', weight: 10 },
        { name: 'Inventory rendszer',      weight: 10 },
        { name: 'UI komponensek',          weight: 10 },
        { name: 'Gazdasági adatok',        weight: 10 },
        { name: 'Job rendszer',            weight: 8  },
        { name: 'Karakteradatok',          weight: 7  },
        { name: 'Világ szinkronizáció',    weight: 10 },
    ];
    buildModuleList(defaultModules);

    // Zene indítása
    initMusic('music/loading.mp3', 0.35, 2000);

    // Ha az NUI üzenetek már korán megérkeznek:
    window.addEventListener('message', function(ev) {
        if (ev.data && ev.data.action === 'serverData' && ev.data.data) {
            const d = ev.data.data;
            // Ha van modul lista a configból, újraépítjük
            if (d.modules && d.modules.length) {
                buildModuleList(d.modules);
            }
            if (d.enterButtonText) {
                $id('enter-btn-text').textContent = d.enterButtonText;
                LS.enterBtnText = d.enterButtonText;
            }
            if (typeof d.musicVolume !== 'undefined') LS.musicVolume = d.musicVolume;
            if (typeof d.musicFadeOut !== 'undefined') LS.musicFadeOut = d.musicFadeOut;
            if (typeof d.minLoadTime !== 'undefined') LS.minLoadTime = d.minLoadTime;
        }
    });
})();
