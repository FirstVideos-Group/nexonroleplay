// ── NUI Bridge ───────────────────────────────────────────────
const sendNui = (ev, data = {}) =>
    fetch(`https://${GetParentResourceName()}/${ev}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });

// ── DOM ──────────────────────────────────────────────────────
const overlay   = document.getElementById('overlay');
const hwSub     = document.getElementById('hw-sub');
const timerBar  = document.getElementById('hw-timer-bar');
const timerLbl  = document.getElementById('hw-timer-label');
const mgWC      = document.getElementById('mg-wirechoice');
const mgSEQ     = document.getElementById('mg-sequence');

// ── Globális state ─────────────────────────────────────────────
let cfg        = {};
let activeGame = null;
let timerRaf   = null;
let timerEnd   = 0;
let timerTotal = 0;
let locked     = false;  // Megakadályozza a dupla input-ot

// ── Timer ───────────────────────────────────────────────────

function startTimer(seconds, onExpire) {
    timerTotal = seconds;
    timerEnd   = performance.now() + seconds * 1000;
    cancelAnimationFrame(timerRaf);
    (function tick() {
        const rem = Math.max(0, (timerEnd - performance.now()) / 1000);
        const pct = rem / timerTotal;
        timerBar.style.setProperty('--pct', (pct * 100) + '%');
        timerBar.style.setProperty('--bar-color',
            pct > 0.6 ? '#3ecf8e' : pct > 0.3 ? '#f0b55b' : '#f05b5b');
        timerLbl.textContent = rem.toFixed(1) + 'mp';
        if (rem > 0) timerRaf = requestAnimationFrame(tick);
        else onExpire();
    })();
}

function stopTimer() {
    cancelAnimationFrame(timerRaf);
    timerBar.style.setProperty('--pct', '100%');
    timerBar.style.setProperty('--bar-color', '#3ecf8e');
    timerLbl.textContent = '';
}

// ── Flash helpers ──────────────────────────────────────────────

function flashPanel(type) {
    const panel = activeGame === 'wirechoice' ? mgWC : mgSEQ;
    panel.classList.remove('flash-success', 'flash-fail', 'flash-neutral');
    void panel.offsetWidth;
    panel.classList.add(
        type === 'success' ? 'flash-success' :
        type === 'neutral' ? 'flash-neutral' : 'flash-fail'
    );
}

function finish(success, shock) {
    if (locked) return;
    locked = true;
    stopTimer();
    flashPanel(success ? 'success' : 'fail');
    setTimeout(() => {
        sendNui('minigameResult', { success, shock: !!shock, minigame: activeGame });
    }, 450);
}

// ── WIRECHOICE ────────────────────────────────────────────────

const WIRE_DEFS = [
    { id: 'red',    label: 'Piros',  color: '#e05555' },
    { id: 'blue',   label: 'Kék',    color: '#5588e0' },
    { id: 'yellow', label: 'Sárga',  color: '#e0c055' },
    { id: 'green',  label: 'Zöld',   color: '#55c07a' },
    { id: 'white',  label: 'Fehér',  color: '#d0d5e8' },
    { id: 'black',  label: 'Fekete', color: '#5a5a6a' },
];

let wireTypes = [];   // 'correct' | 'shock' | 'neutral' per wire

function buildWires() {
    const wcCfg  = cfg.wirechoice || {};
    const total  = wcCfg.totalWires  || 6;
    const nCorr  = wcCfg.correctWires || 1;
    const nShock = wcCfg.shockWires   || 2;

    wireTypes = [];
    for (let i = 0; i < nCorr;  i++) wireTypes.push('correct');
    for (let i = 0; i < nShock; i++) wireTypes.push('shock');
    while (wireTypes.length < total)  wireTypes.push('neutral');
    wireTypes.sort(() => Math.random() - 0.5);

    const grid = document.getElementById('wire-grid');
    grid.innerHTML = '';
    const defs = WIRE_DEFS.slice(0, total);

    defs.forEach((def, idx) => {
        const card = document.createElement('div');
        card.className = 'wire-card';
        card.dataset.idx = idx;

        const swatch = document.createElement('div');
        swatch.className = 'wire-swatch';
        swatch.style.background = def.color;

        const lbl = document.createElement('div');
        lbl.className = 'wire-label';
        lbl.textContent = def.label;

        card.appendChild(swatch);
        card.appendChild(lbl);
        card.addEventListener('click', () => onWireClick(idx, card));
        grid.appendChild(card);
    });
}

const feedbackEl = document.getElementById('wire-feedback');

function onWireClick(idx, card) {
    if (locked || card.classList.contains('dead')) return;
    const type = wireTypes[idx];

    if (type === 'correct') {
        card.style.borderColor = '#3ecf8e';
        feedbackEl.className = 'wire-feedback success';
        feedbackEl.textContent = 'Motor beindult!';
        finish(true, false);
    } else if (type === 'shock') {
        card.style.borderColor = '#f05b5b';
        feedbackEl.className = 'wire-feedback shock';
        feedbackEl.textContent = 'Megrázott az áram!';
        finish(false, true);
    } else {
        // Semleges: drót kihalt, folytass
        card.classList.add('dead');
        feedbackEl.className = 'wire-feedback neutral';
        feedbackEl.textContent = 'Semleges – próbálj tovább!';
        flashPanel('neutral');

        // Ha csak shock maradt – auto fail
        const alive = wireTypes.filter((t, i) => {
            const cards = document.querySelectorAll('.wire-card');
            return !cards[i].classList.contains('dead');
        });
        if (alive.every(t => t === 'shock')) {
            setTimeout(() => finish(false, false), 700);
        }
    }
}

function startWirechoice() {
    mgWC.classList.remove('hidden');
    hwSub.textContent = 'Válassz drótot!';
    locked = false;
    buildWires();
    startTimer((cfg.wirechoice?.timeLimit || 20), () => finish(false, false));
}

// ── SEQUENCE ──────────────────────────────────────────────────

let seqKeys    = [];
let seqCurrent = 0;
let seqStepRaf = null;
let seqStepEnd = 0;
let seqRunning = false;

const seqStepEl  = document.getElementById('seq-step');
const seqLblEl   = document.getElementById('seq-label');
const seqProgEl  = document.getElementById('seq-progress');

function seqNextStep() {
    if (seqCurrent >= seqKeys.length) return;
    const key = seqKeys[seqCurrent];
    seqStepEl.textContent = key;
    seqLblEl.textContent  = (seqCurrent + 1) + ' / ' + seqKeys.length;
    seqStepEnd = performance.now() + (cfg.sequence?.timePerStep || 1.5) * 1000;
    cancelAnimationFrame(seqStepRaf);
    (function tick() {
        const rem = Math.max(0, seqStepEnd - performance.now());
        const pct = rem / ((cfg.sequence?.timePerStep || 1.5) * 1000);
        seqProgEl.style.setProperty('--spct', (pct * 100) + '%');
        if (rem > 0 && seqRunning) seqStepRaf = requestAnimationFrame(tick);
        else if (seqRunning) finish(false, false);  // Lejárt az idő
    })();
}

function startSequence() {
    mgSEQ.classList.remove('hidden');
    hwSub.textContent = 'QTE – gyors gombnyomás!';
    locked    = false;
    seqRunning = true;
    const keys  = cfg.sequence?.keys  || ['W', 'A', 'S', 'D'];
    const steps = cfg.sequence?.steps || 6;
    seqKeys    = Array.from({ length: steps }, () => keys[Math.floor(Math.random() * keys.length)]);
    seqCurrent = 0;
    seqNextStep();
}

document.addEventListener('keydown', e => {
    if (activeGame !== 'sequence' || !seqRunning || locked) return;
    if (e.key === 'Escape') { sendNui('cancel'); return; }
    const pressed = e.key.toUpperCase();
    const expected = seqKeys[seqCurrent];
    if (pressed === expected) {
        seqCurrent++;
        if (seqCurrent >= seqKeys.length) {
            seqRunning = false;
            cancelAnimationFrame(seqStepRaf);
            finish(true, false);
        } else {
            seqNextStep();
        }
    } else {
        seqRunning = false;
        cancelAnimationFrame(seqStepRaf);
        seqStepEl.textContent = '❌';
        finish(false, false);
    }
});

// Wirechoice ESC
document.addEventListener('keydown', e => {
    if (activeGame === 'wirechoice' && e.key === 'Escape') sendNui('cancel');
});

// ── NUI Message handler ───────────────────────────────────────
window.addEventListener('message', ({ data }) => {
    if (!data?.action) return;
    if (data.action === 'setVisible') {
        if (data.visible) {
            overlay.classList.remove('hidden');
            activeGame = data.minigame || 'wirechoice';
            cfg        = data.config || {};
            locked     = false;
            mgWC.classList.add('hidden');
            mgSEQ.classList.add('hidden');
            stopTimer();
            if (activeGame === 'wirechoice') startWirechoice();
            else                             startSequence();
        } else {
            overlay.classList.add('hidden');
            activeGame = null;
            seqRunning = false;
            stopTimer();
            cancelAnimationFrame(seqStepRaf);
        }
    }
});
