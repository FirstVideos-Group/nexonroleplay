// ── NUI Bridge ───────────────────────────────────────────────
const sendNui = (event, data = {}) =>
    fetch(`https://${GetParentResourceName()}/${event}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data),
    });

// ── DOM ──────────────────────────────────────────────────────
const overlay    = document.getElementById('overlay');
const headerSub  = document.getElementById('header-sub');
const mgLockpick = document.getElementById('mg-lockpick');
const mgKeypad   = document.getElementById('mg-keypad');
const timerBar   = document.getElementById('ct-timer-bar');
const timerLabel = document.getElementById('ct-timer-label');

// ── State ────────────────────────────────────────────────────
let cfg         = {};
let activeGame  = null;   // 'lockpick' | 'keypad'
let timerRaf    = null;
let timerEnd    = 0;
let timerTotal  = 0;

// ── Utils ────────────────────────────────────────────────────
function hideAll() {
    mgLockpick.classList.add('hidden');
    mgKeypad.classList.add('hidden');
}

function setTimerColor(pct) {
    const color = pct > 0.6 ? '#3ecf8e' : pct > 0.3 ? '#f0b55b' : '#f05b5b';
    timerBar.style.setProperty('--bar-color', color);
}

function startTimer(seconds, onExpire) {
    timerTotal = seconds;
    timerEnd   = performance.now() + seconds * 1000;
    cancelAnimationFrame(timerRaf);
    function tick() {
        const remaining = Math.max(0, (timerEnd - performance.now()) / 1000);
        const pct = remaining / timerTotal;
        timerBar.style.setProperty('--pct', (pct * 100) + '%');
        timerLabel.textContent = remaining.toFixed(1) + 'mp';
        setTimerColor(pct);
        if (remaining > 0) {
            timerRaf = requestAnimationFrame(tick);
        } else {
            onExpire();
        }
    }
    timerRaf = requestAnimationFrame(tick);
}

function stopTimer() {
    cancelAnimationFrame(timerRaf);
    timerBar.style.setProperty('--pct', '100%');
    timerBar.style.setProperty('--bar-color', '#3ecf8e');
    timerLabel.textContent = '';
}

function flashPanel(type) {
    const panel = activeGame === 'lockpick' ? mgLockpick : mgKeypad;
    panel.classList.remove('flash-success', 'flash-fail');
    void panel.offsetWidth;
    panel.classList.add(type === 'success' ? 'flash-success' : 'flash-fail');
}

function finishGame(success) {
    stopTimer();
    flashPanel(success ? 'success' : 'fail');
    setTimeout(() => {
        sendNui('minigameResult', { success });
    }, 400);
}

// ── LOCKPICK ─────────────────────────────────────────────────
let lpAngle    = 0;
let lpSpeed    = 2;      // fok/frame
let lpRound    = 1;
let lpRounds   = 3;
let lpZone     = 0;      // célzóna kezdő foka
let lpZoneSize = 15;
let lpRunning  = false;
let lpRaf      = null;
let lpLocked   = false;  // gombnyomás cooldown

const LP_R    = 88;   // SVG kör sugár
const LP_CX   = 100;
const LP_CY   = 100;

function degToRad(d) { return d * Math.PI / 180; }

function polarToXY(angleDeg, r) {
    const a = degToRad(angleDeg - 90);
    return { x: LP_CX + r * Math.cos(a), y: LP_CY + r * Math.sin(a) };
}

function drawZone(startDeg, sizeDeg) {
    const path  = document.getElementById('lp-zone');
    const start = polarToXY(startDeg, LP_R);
    const end   = polarToXY(startDeg + sizeDeg, LP_R);
    const large = sizeDeg > 180 ? 1 : 0;
    path.setAttribute('d',
        `M ${start.x} ${start.y} A ${LP_R} ${LP_R} 0 ${large} 1 ${end.x} ${end.y}`
    );
}

function updateNeedle(angleDeg) {
    const needle = document.getElementById('lp-needle');
    const tip    = polarToXY(angleDeg, LP_R - 8);
    needle.setAttribute('x2', tip.x);
    needle.setAttribute('y2', tip.y);
}

function lpNewRound(round) {
    lpAngle    = 0;
    lpZone     = Math.random() * 360;
    lpZoneSize = cfg.lockpick?.successZone ?? 15;
    lpSpeed    = (cfg.lockpick?.speed ?? 1.2) * (1 + (round - 1) * 0.15) * 2;
    lpRound    = round;
    lpLocked   = false;
    headerSub.textContent = `${round}. zár / ${lpRounds}`;
    drawZone(lpZone, lpZoneSize);
    updateNeedle(lpAngle);
    startTimer(cfg.lockpick?.timeLimit ?? 10, () => {
        if (lpRunning) finishGame(false);
    });
}

function lpTick() {
    if (!lpRunning) return;
    lpAngle = (lpAngle + lpSpeed) % 360;
    updateNeedle(lpAngle);
    lpRaf = requestAnimationFrame(lpTick);
}

function lpStop() {
    if (lpLocked || !lpRunning) return;
    lpLocked = true;
    cancelAnimationFrame(lpRaf);
    stopTimer();

    // Normalizálás 0-360-ba
    let needle = ((lpAngle % 360) + 360) % 360;
    let zone   = ((lpZone  % 360) + 360) % 360;

    // Célzóna ellenőrzés (körkörösen)
    let diff = (needle - zone + 360) % 360;
    const hit = diff <= lpZoneSize || diff >= (360 - 2);

    if (hit) {
        flashPanel('success');
        if (lpRound >= lpRounds) {
            setTimeout(() => finishGame(true), 450);
        } else {
            setTimeout(() => {
                lpLocked = false;
                lpNewRound(lpRound + 1);
                lpRunning = true;
                lpRaf = requestAnimationFrame(lpTick);
            }, 500);
        }
    } else {
        flashPanel('fail');
        setTimeout(() => finishGame(false), 450);
    }
}

function startLockpick() {
    mgLockpick.classList.remove('hidden');
    lpRounds  = cfg.lockpick?.rounds ?? 3;
    lpRunning = true;
    lpNewRound(1);
    lpRaf = requestAnimationFrame(lpTick);
}

// E gomb figyelés a lockpick-hez
document.addEventListener('keydown', e => {
    if (activeGame === 'lockpick' && (e.key === 'e' || e.key === 'E')) {
        lpStop();
    }
    if (e.key === 'Escape') {
        sendNui('cancel');
    }
});

// ── KEYPAD ───────────────────────────────────────────────────
let kpSequence = [];
let kpInput    = [];
let kpSymbols  = ['▲', '▼', '◄', '►', '■'];
let kpPhase    = 'show';  // 'show' | 'input'

const kpSeqEl  = document.getElementById('kp-sequence');
const kpInpEl  = document.getElementById('kp-input');
const kpBtnEl  = document.getElementById('kp-buttons');
const kpHint   = document.getElementById('kp-hint');

function kpGenSequence(len) {
    const seq = [];
    for (let i = 0; i < len; i++) {
        seq.push(kpSymbols[Math.floor(Math.random() * kpSymbols.length)]);
    }
    return seq;
}

function kpRenderSequence(reveal) {
    kpSeqEl.innerHTML = '';
    kpSequence.forEach((sym, i) => {
        const el = document.createElement('div');
        el.className = 'kp-sym';
        el.textContent = reveal ? sym : '?';
        kpSeqEl.appendChild(el);
    });
}

function kpRenderInput() {
    kpInpEl.innerHTML = '';
    for (let i = 0; i < kpSequence.length; i++) {
        const el = document.createElement('div');
        el.className = 'kp-slot' + (kpInput[i] ? ' filled' : '');
        el.textContent = kpInput[i] || '';
        kpInpEl.appendChild(el);
    }
}

function kpRenderButtons() {
    kpBtnEl.innerHTML = '';
    kpSymbols.forEach(sym => {
        const btn = document.createElement('button');
        btn.className = 'kp-btn';
        btn.textContent = sym;
        btn.addEventListener('click', () => kpPress(sym));
        kpBtnEl.appendChild(btn);
    });
}

function kpPress(sym) {
    if (kpPhase !== 'input') return;
    const idx = kpInput.length;
    if (idx >= kpSequence.length) return;

    kpInput.push(sym);
    kpRenderInput();

    // Helyes-e az eddig beírt rész?
    if (sym !== kpSequence[idx]) {
        // Helytelen – piros flash
        stopTimer();
        const slots = kpInpEl.querySelectorAll('.kp-slot');
        slots[idx].classList.add('wrong');
        flashPanel('fail');
        setTimeout(() => finishGame(false), 500);
        return;
    }

    // Összes beírva helyesen?
    if (kpInput.length === kpSequence.length) {
        stopTimer();
        kpInpEl.querySelectorAll('.kp-slot').forEach(s => s.classList.add('correct'));
        flashPanel('success');
        setTimeout(() => finishGame(true), 500);
    }
}

function startKeypad() {
    mgKeypad.classList.remove('hidden');
    kpSymbols  = cfg.keypad?.symbols  ?? kpSymbols;
    kpPhase    = 'show';
    kpInput    = [];
    kpSequence = kpGenSequence(cfg.keypad?.sequenceLength ?? 5);
    headerSub.textContent = 'Jegyezd meg a sorozatot!';

    kpRenderSequence(true);
    kpRenderInput();
    kpBtnEl.classList.add('hidden');
    kpHint.textContent = 'Jegyezd meg a sorozatot!';

    const showTime = cfg.keypad?.showTime ?? 3000;
    const inputTime = cfg.keypad?.inputTime ?? 6000;

    setTimeout(() => {
        // Elrejtés
        kpRenderSequence(false);
        kpPhase = 'input';
        kpBtnEl.classList.remove('hidden');
        kpRenderButtons();
        kpHint.textContent = 'Add meg a helyes sorrendben!';
        headerSub.textContent = 'Add meg a sorozatot!';
        startTimer(inputTime / 1000, () => finishGame(false));
    }, showTime);
}

// ── NUI Message handler ───────────────────────────────────────
window.addEventListener('message', ({ data }) => {
    if (!data?.action) return;
    switch (data.action) {
        case 'setVisible':
            if (data.visible) {
                overlay.classList.remove('hidden');
                activeGame = data.minigame || 'lockpick';
                cfg = data.config || {};
                hideAll();
                stopTimer();
                if (activeGame === 'lockpick') startLockpick();
                else                           startKeypad();
            } else {
                overlay.classList.add('hidden');
                activeGame = null;
                stopTimer();
                if (lpRaf) cancelAnimationFrame(lpRaf);
            }
            break;
    }
});
