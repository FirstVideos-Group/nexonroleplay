/* ============================================================
   nxn-loading | app.js
   Fix: kurzor, motor-init sync, autoplay zene, modulok/adatok
   ============================================================ */

'use strict';

// ── Állapot ──────────────────────────────────────────────────
const LS = {
    modules:          [],
    totalWeight:      0,
    completedWeight:  0,
    loadingDone:      false,
    enterTriggered:   false,
    musicEnabled:     false,   // alapértelmezetten kikapcsolt, autoplay policy miatt
    musicVolume:      0.35,
    musicFadeOut:     2000,
    minLoadTime:      3000,
    startTime:        Date.now(),
    // Motor-init követés (FiveM loadProgress)
    engineProgress:   0,
    engineDone:       false,
    serverDataReceived: false
};

const $id = id => document.getElementById(id);

// ── FiveM motor-init eventi ─────────────────────────────────
//
// A FiveM loadscreen kontextusban a motor a következő üzeneteket küldi:
//   { type: 'loadProgress', loadFraction: 0.0 – 1.0 }
//   { type: 'startInitFunction', type: 'InitFunctionType', name: '...' }
//   { type: 'gameLoadComplete' }
//
window.addEventListener('message', function (event) {
    const d = event.data;
    if (!d) return;

    // — Motor init üzenet (a FiveM küldi automatikusan) —
    if (d.type === 'loadProgress') {
        handleEngineProgress(d.loadFraction || 0);
        return;
    }
    if (d.type === 'startInitFunction') {
        setStatus(d.name ? ('Betöltés: ' + d.name) : 'Motor inicializálás…');
        return;
    }
    if (d.type === 'gameLoadComplete') {
        onEngineLoadComplete();
        return;
    }

    // — Lua NUI üzenetek —
    if (!d.action) return;
    switch (d.action) {
        case 'serverData':    handleServerData(d.data);                      break;
        case 'queueUpdate':   handleQueueUpdate(d.position, d.total);        break;
        case 'externalModule':handleExternalModule(d.name, d.percent);       break;
        case 'setStatus':     setStatus(d.text);                             break;
    }
});

// ── Motor progress ───────────────────────────────────────────
// A valós FiveM motor betöltési progress-t tükrözi vissza
function handleEngineProgress(fraction) {
    LS.engineProgress = fraction;
    // Az első 50%-ot a motor tölti (loadProgress), a második 50%-ot a mi moduljaink
    const enginePct = fraction * 50;
    // Ha még nem kezdtük a modulokat, érintsük meg a bar-t
    if (!LS.engineDone) {
        $id('progress-fill').style.width = enginePct.toFixed(1) + '%';
        $id('progress-pct').textContent  = Math.round(enginePct) + '%';
    }
}

function onEngineLoadComplete() {
    if (LS.engineDone) return;
    LS.engineDone = true;
    setStatus('Motor betöltve. Modulok inicializálása…');

    // Ha a szerver adatok már megérkeztek, induljon a modul animáció
    // Ha nem, a handleServerData majd elindítja
    if (LS.serverDataReceived) {
        startModuleAnimation();
    }
}

// ── Szerver adat feldolgozás ─────────────────────────────────
function handleServerData(d) {
    if (!d) return;
    LS.serverDataReceived = true;

    $id('ls-server-name').textContent = d.serverName  || 'Nexon Roleplay';
    $id('ls-server-desc').textContent = d.description || '';
    $id('info-online').textContent    = d.online      || '–';
    $id('info-max').textContent       = d.maxPlayers  || '–';

    if (Array.isArray(d.rules)    && d.rules.length)    buildRules(d.rules);
    if (Array.isArray(d.keybinds) && d.keybinds.length) buildKeybinds(d.keybinds);
    if (Array.isArray(d.modules)  && d.modules.length)  buildModuleList(d.modules);

    if (d.enterButtonText) $id('enter-btn-text').textContent = d.enterButtonText;
    if (typeof d.musicVolume   !== 'undefined') LS.musicVolume   = d.musicVolume;
    if (typeof d.musicFadeOut  !== 'undefined') LS.musicFadeOut  = d.musicFadeOut;
    if (typeof d.minLoadTime   !== 'undefined') LS.minLoadTime   = d.minLoadTime;
    if (typeof d.musicFile     !== 'undefined') updateMusicSrc(d.musicFile);

    setStatus('Modulok betöltése…');

    // Ha a motor már betöltött (pl. gyors szerver), indítsuk a modulokat
    if (LS.engineDone) {
        startModuleAnimation();
    }
}

// ── Szabályok ─────────────────────────────────────────────────
function buildRules(rules) {
    const grid = $id('rules-list');
    grid.innerHTML = '';
    // Ha nincs adat, placeholder
    if (!rules || rules.length === 0) {
        grid.innerHTML = '<div class="ls-placeholder">Nincsenek megadott szabályok.</div>';
        return;
    }
    rules.forEach(r => {
        const card = document.createElement('div');
        card.className = 'ls-rule-card';
        // icon: vagy hgi- prefix már rajta van, vagy hozzáadjuk
        const iconClass = (r.icon || 'hgi-information-circle').startsWith('hgi-')
            ? r.icon
            : 'hgi-' + r.icon;
        card.innerHTML = `
            <div class="rule-icon"><i class="hgi hgi-stroke ${escHtml(iconClass)}"></i></div>
            <h4>${escHtml(r.title || '')}</h4>
            <p>${escHtml(r.text || '')}</p>
        `;
        grid.appendChild(card);
    });
}

// ── Billentyűk ────────────────────────────────────────────────
function buildKeybinds(keys) {
    const wrap = $id('keybinds-list');
    wrap.innerHTML = '';
    if (!keys || keys.length === 0) {
        wrap.innerHTML = '<div class="ls-placeholder">Nincsenek megadott billentyűk.</div>';
        return;
    }
    keys.forEach(k => {
        const row = document.createElement('div');
        row.className = 'ls-keybind-row';
        row.innerHTML = `
            <span class="ls-key-badge">${escHtml(k.key || '')}</span>
            <span class="ls-key-desc">${escHtml(k.desc || '')}</span>
        `;
        wrap.appendChild(row);
    });
}

// ── Modul lista felépítése ──────────────────────────────────
function buildModuleList(modules) {
    LS.modules         = modules;
    LS.totalWeight     = modules.reduce((s, m) => s + (m.weight || 10), 0);
    LS.completedWeight = 0;

    const list = $id('module-list');
    list.innerHTML = '';
    modules.forEach((m, i) => {
        const row = document.createElement('div');
        row.className = 'ls-module-row';
        row.id = 'mod-row-' + i;
        row.innerHTML = `
            <i class="hgi hgi-stroke hgi-circle" id="mod-icon-${i}"></i>
            <span style="flex:1;font-size:11px">${escHtml(m.name || 'Modul ' + i)}</span>
            <div class="mod-bar-wrap"><div class="mod-bar-fill" id="mod-bar-${i}" style="width:0%"></div></div>
            <span class="ls-module-pct" id="mod-pct-${i}">0%</span>
        `;
        list.appendChild(row);
    });
}

// ── Modul animáció indítása (motor + szerver adat után) ─────────
let moduleAnimStarted = false;
function startModuleAnimation() {
    if (moduleAnimStarted) return;
    moduleAnimStarted = true;

    LS.startTime = Date.now();

    if (!LS.modules || LS.modules.length === 0) {
        finishLoading();
        return;
    }
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
    if (icon) { icon.className = 'hgi hgi-stroke hgi-loading-01 spin'; }
    $id('current-module-name').textContent = mod.name || 'Modul ' + idx;
    row.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

    const duration      = (mod.weight || 10) * 80 + Math.random() * 200;
    const start         = performance.now();
    const prevCompleted = LS.completedWeight;
    const modWeight     = mod.weight || 10;

    function animate(now) {
        const progress = Math.min((now - start) / duration, 1);
        const eased    = easeInOutCubic(progress);

        if (bar) bar.style.width = (eased * 100).toFixed(1) + '%';
        if (pct) pct.textContent  = Math.round(eased * 100) + '%';

        // Globális progress: motor 50% + modulok 50%
        const modPct    = (prevCompleted + eased * modWeight) / LS.totalWeight * 50;
        const globalPct = 50 + modPct;
        updateGlobalProgress(globalPct);

        if (progress < 1) {
            requestAnimationFrame(animate);
        } else {
            row.classList.remove('active');
            row.classList.add('done');
            if (icon) icon.className = 'hgi hgi-stroke hgi-checkmark-circle-01';
            if (bar)  bar.style.width = '100%';
            if (pct)  pct.textContent = '100%';
            LS.completedWeight = prevCompleted + modWeight;
            loadNextModule(idx + 1);
        }
    }
    requestAnimationFrame(animate);
}

function updateGlobalProgress(pct) {
    const c = Math.min(Math.max(pct, 0), 100);
    $id('progress-fill').style.width = c.toFixed(1) + '%';
    $id('progress-pct').textContent  = Math.round(c) + '%';
}

function finishLoading() {
    const elapsed   = Date.now() - LS.startTime;
    const remaining = Math.max(0, LS.minLoadTime - elapsed);

    setTimeout(() => {
        updateGlobalProgress(100);
        $id('progress-pct').textContent = '100%';
        $id('current-module-name').textContent = 'Betöltés kész!';

        const spinIcon = $id('global-spin-icon');
        if (spinIcon) {
            spinIcon.classList.remove('spin');
            spinIcon.classList.add('done');
            spinIcon.className = 'hgi hgi-stroke hgi-checkmark-circle-01 done';
        }

        setStatus('Minden modul betöltve. Kész a belépésre!');
        LS.loadingDone = true;

        const btn = $id('ls-enter-btn');
        btn.style.display    = 'flex';
        btn.style.animation  = 'nxnFadeIn .3s ease';

        fetch('https://nxn-loading/loadingComplete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {});
    }, remaining);
}

// ── Várólista ──────────────────────────────────────────────────
function handleQueueUpdate(pos, total) {
    const qEl = $id('ls-queue');
    if (pos && pos > 0) {
        qEl.style.display = 'flex';
        $id('queue-pos').textContent = `Pozíció: ${pos}. / ${total} várakozó`;
    } else {
        qEl.style.display = 'none';
    }
}

// ── Külső modul progress ──────────────────────────────────────
function handleExternalModule(name, percent) {
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
    row.querySelector('.ext-bar').style.width = percent + '%';
    row.querySelector('.ext-pct').textContent  = percent + '%';
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
    if (!LS.loadingDone || LS.enterTriggered) return;
    LS.enterTriggered = true;

    const btn = $id('ls-enter-btn');
    btn.disabled = true;
    btn.style.opacity = '0.6';
    setStatus('Belépés a városba…');

    fadeOutMusic(LS.musicFadeOut, () => {
        document.getElementById('loading-screen').classList.add('fade-out');
        fetch('https://nxn-loading/enterGame', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {});
    });
}

// ── Zene kezelés ───────────────────────────────────────────────
// A CEF loadscreen AUTOPLAY POLICY-t alkalmaz:
// Az audio.play() csak user interaction után működik megbízhatóan.
// Megoldás: az oldal első kattintására (bármely elem) elindítjuk a zenét,
// és egy tick delay után is próbáljuk (loop fallback).

let musicSrc = 'music/loading.mp3';

function updateMusicSrc(src) {
    musicSrc = src;
    const audio = $id('bg-music');
    if (audio.src !== src) {
        audio.src = src;
    }
}

function tryPlayMusic() {
    if (!LS.musicEnabled) return;
    const audio = $id('bg-music');
    if (audio.paused) {
        audio.volume = LS.musicVolume;
        audio.play().catch(() => { /* autoplay policy */ });
    }
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
    if (!icon) return;
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

// ── Segédfüggvények ───────────────────────────────────────────
function setStatus(text) {
    const el = $id('ls-status');
    if (el) el.textContent = text;
}

function escHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function easeInOutCubic(t) {
    return t < 0.5 ? 4*t*t*t : 1 - Math.pow(-2*t+2,3)/2;
}

// ── INIT ──────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function () {

    // 1. Zene bekészítése (előre betöltés)
    const audio = $id('bg-music');
    audio.src    = musicSrc;
    audio.volume = LS.musicVolume;
    audio.loop   = true;
    // Az icon alapból "off" állapótban van (autoplay policy miatt)
    updateMusicIcon();

    // 2. Első felhasználói interakcióra indítjuk a zenét
    //    A CEF-ben a loadscreen már egérrel kezelheta, ezért a
    //    mousedown eseményre is reagálunk
    function onFirstInteraction() {
        document.removeEventListener('mousedown', onFirstInteraction);
        document.removeEventListener('keydown',   onFirstInteraction);
        LS.musicEnabled = true;
        updateMusicIcon();
        tryPlayMusic();
    }
    document.addEventListener('mousedown', onFirstInteraction);
    document.addEventListener('keydown',   onFirstInteraction);

    // 3. Fallback: ha a FiveM CEF nem blokkolja (pl. dev mód),
    //    0.5s után is próbálkozunk
    setTimeout(() => {
        const a = $id('bg-music');
        if (a.paused) {
            a.volume = LS.musicVolume;
            a.play()
                .then(() => {
                    LS.musicEnabled = true;
                    updateMusicIcon();
                })
                .catch(() => {
                    // Autoplay tiltva – várjuk az interakciót (már feliratkoztunk rá)
                });
        }
    }, 500);

    // 4. Ha a FiveM nem küld loadProgress üzenetet (pl. fejlesztői környezet),
    //    3s után fallback-ként automatikusan "engineDone"-nak tekintjük
    setTimeout(() => {
        if (!LS.engineDone) {
            LS.engineDone = true;
            updateGlobalProgress(50);
            if (LS.serverDataReceived) startModuleAnimation();
        }
    }, 3000);

    // 5. Ha a szerver adatok sem érkeznek meg 8s-on belül,
    //    építsünk default modullistát és indítsuk el
    setTimeout(() => {
        if (!LS.serverDataReceived) {
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
            buildRules([]);
            buildKeybinds([]);
            LS.serverDataReceived = true;
            if (LS.engineDone) startModuleAnimation();
        }
    }, 8000);
});
