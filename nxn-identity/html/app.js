'use strict';

// ── Allapot ───────────────────────────────────────────────────
let currentStep = 1;
const TOTAL_STEPS = 3;
let cfg = {};

const state = {
    firstname:      '',
    lastname:       '',
    gender:         0,
    birth_day:      1,
    birth_month:    1,
    birth_year:     1990,
    skin_color:     0,
    eye_color:      0,
    hair_style:     0,
    hair_color:     0,
    hair_highlight: 0,
    face_features:  new Array(20).fill(0.0),
};

// ── DOM refs ──────────────────────────────────────────────────
const overlay    = document.getElementById('overlay');
const btnNext    = document.getElementById('btn-next');
const btnBack    = document.getElementById('btn-back');
const stepLabel  = document.getElementById('step-label');

// ── NUI post ──────────────────────────────────────────────────
function nuiPost(event, data) {
    return fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

// ── Segédek ───────────────────────────────────────────────────
function swatch(label, value, group, stateKey, onPick) {
    const el = document.createElement('div');
    el.className = 'swatch' + (state[stateKey] === value ? ' active' : '');
    el.textContent = label;
    el.dataset.value = value;
    el.addEventListener('click', () => {
        state[stateKey] = value;
        document.querySelectorAll(`#${group} .swatch`).forEach(s => s.classList.remove('active'));
        el.classList.add('active');
        if (onPick) onPick();
        triggerPreview();
    });
    return el;
}

function radioBtn(label, value, iconCls) {
    const el = document.createElement('div');
    el.className = 'radio-btn' + (state.gender === value ? ' active' : '');
    el.innerHTML = `<i class="hgi hgi-stroke ${iconCls}"></i>${label}`;
    el.addEventListener('click', () => {
        state.gender = value;
        document.querySelectorAll('#gender-group .radio-btn').forEach(b => b.classList.remove('active'));
        el.classList.add('active');
        // Hajstilus frissitese nemtol fuggoen
        buildHairStyles();
        triggerPreview();
    });
    return el;
}

function selectPopulate(id, items, stateKey, padded) {
    const sel = document.getElementById(id);
    sel.innerHTML = '';
    items.forEach(item => {
        const o = document.createElement('option');
        o.value = item;
        o.textContent = padded ? String(item).padStart(2, '0') : item;
        if (state[stateKey] === item) o.selected = true;
        sel.appendChild(o);
    });
    sel.addEventListener('change', () => { state[stateKey] = Number(sel.value); });
}

// ── Preview kuldese ───────────────────────────────────────────
function triggerPreview() {
    nuiPost('previewSkin', {
        gender:         state.gender,
        skin_color:     state.skin_color,
        eye_color:      state.eye_color,
        hair_style:     state.hair_style,
        hair_color:     state.hair_color,
        hair_highlight: state.hair_highlight,
        face_features:  state.face_features,
    });
}

// ── Step 1 epites ─────────────────────────────────────────────
function buildStep1() {
    // Nev
    document.getElementById('inp-firstname').addEventListener('input', e => { state.firstname = e.target.value.trim(); });
    document.getElementById('inp-lastname').addEventListener('input',  e => { state.lastname  = e.target.value.trim(); });

    // Nem
    const gg = document.getElementById('gender-group');
    gg.innerHTML = '';
    (cfg.genders || ['Férfi', 'Nő']).forEach((label, i) => {
        const icons = ['hgi-user-full-02', 'hgi-user-female'];
        gg.appendChild(radioBtn(label, i, icons[i] || 'hgi-user-circle'));
    });

    // Datum
    const days   = Array.from({ length: 31 }, (_, i) => i + 1);
    const months = Array.from({ length: 12 }, (_, i) => i + 1);
    const minY   = cfg.birthYearMin || 1960;
    const maxY   = cfg.birthYearMax || 2003;
    const years  = Array.from({ length: maxY - minY + 1 }, (_, i) => maxY - i);

    selectPopulate('inp-bday',   days,   'birth_day',   true);
    selectPopulate('inp-bmonth', months, 'birth_month', true);
    selectPopulate('inp-byear',  years,  'birth_year',  false);

    document.getElementById('inp-bday').addEventListener('change',   e => { state.birth_day   = Number(e.target.value); });
    document.getElementById('inp-bmonth').addEventListener('change', e => { state.birth_month  = Number(e.target.value); });
    document.getElementById('inp-byear').addEventListener('change',  e => { state.birth_year   = Number(e.target.value); });
}

// ── Step 2 epites ─────────────────────────────────────────────
function buildHairStyles() {
    const isFemale = state.gender === 1;
    const styles   = isFemale ? (cfg.hairStylesFemale || []) : (cfg.hairStylesMale || []);
    const row      = document.getElementById('hair-style-row');
    row.innerHTML  = '';
    styles.forEach((s, i) => {
        const el = swatch(s.label, i, 'hair-style-row', 'hair_style');
        row.appendChild(el);
    });
    state.hair_style = 0;
}

function buildStep2() {
    // Borszin
    const skinRow = document.getElementById('skin-color-row');
    (cfg.skinColors || []).forEach(s => skinRow.appendChild(swatch(s.label, s.value, 'skin-color-row', 'skin_color')));

    // Haj stilus (gender-alapu)
    buildHairStyles();

    // Haj szin + kiemelés
    const hcRow = document.getElementById('hair-color-row');
    const hhRow = document.getElementById('hair-highlight-row');
    (cfg.hairColors || []).forEach(c => {
        hcRow.appendChild(swatch(c.label, c.value, 'hair-color-row',      'hair_color'));
        hhRow.appendChild(swatch(c.label, c.value, 'hair-highlight-row',  'hair_highlight'));
    });

    // Szemszin
    const eyeRow = document.getElementById('eye-color-row');
    (cfg.eyeColors || []).forEach(c => eyeRow.appendChild(swatch(c.label, c.value, 'eye-color-row', 'eye_color')));
}

// ── Step 3 epites ─────────────────────────────────────────────
const FACE_LABELS = [
    'Orrnyereg szélesség','Orrnyereg magasság','Orrcimpa szélesség',
    'Orr magassága','Orr csúcsa','Orr elfordulás',
    'Szemöldök magasság','Szemöldök mélység',
    'Arccsont magasság','Arccsont szélesség',
    'Arcüreg szélesség','Áll magasság','Állcsúcs szélesség',
    'Áll mélység','Állkapocs szél.','Állkapocs mag.',
    'Száj szélesség','Száj magasság','Ajkak vastagsága','Nyak vastagság'
];

function buildStep3() {
    const container = document.getElementById('face-sliders');
    container.innerHTML = '';
    FACE_LABELS.forEach((label, i) => {
        const row = document.createElement('div');
        row.className = 'slider-row';
        const lbl = document.createElement('label');
        lbl.textContent = label;
        const rng = document.createElement('input');
        rng.type = 'range'; rng.min = '-1'; rng.max = '1'; rng.step = '0.05';
        rng.value = '0';
        const val = document.createElement('div');
        val.className = 'slider-val'; val.textContent = '0.00';
        rng.addEventListener('input', () => {
            const v = parseFloat(rng.value);
            state.face_features[i] = v;
            val.textContent = v.toFixed(2);
            triggerPreview();
        });
        row.appendChild(lbl); row.appendChild(rng); row.appendChild(val);
        container.appendChild(row);
    });
}

// ── Step navigacio ────────────────────────────────────────────
function setStep(n) {
    currentStep = n;
    document.querySelectorAll('.step-content').forEach((el, i) => {
        el.classList.toggle('active', i + 1 === n);
    });
    document.querySelectorAll('.step').forEach((el, i) => {
        el.classList.toggle('active', i + 1 === n);
        el.classList.toggle('done',   i + 1 < n);
    });
    stepLabel.textContent = `${n} / ${TOTAL_STEPS}`;
    btnBack.disabled = (n === 1);
    btnNext.textContent = (n === TOTAL_STEPS) ? 'Létrehozás' : 'Következő';
}

function validateStep(n) {
    if (n === 1) {
        const fn = document.getElementById('inp-firstname');
        const ln = document.getElementById('inp-lastname');
        let ok = true;
        if (!state.firstname) { fn.classList.add('error'); ok = false; } else fn.classList.remove('error');
        if (!state.lastname)  { ln.classList.add('error'); ok = false; } else ln.classList.remove('error');
        return ok;
    }
    return true;
}

btnNext.addEventListener('click', () => {
    if (!validateStep(currentStep)) return;
    if (currentStep < TOTAL_STEPS) {
        setStep(currentStep + 1);
    } else {
        // Submit
        nuiPost('createCharacter', { ...state }).catch(console.error);
    }
});
btnBack.addEventListener('click', () => {
    if (currentStep > 1) setStep(currentStep - 1);
});

// ── Message handler ───────────────────────────────────────────
window.addEventListener('message', e => {
    const d = e.data;
    if (!d || !d.action) return;

    if (d.action === 'open') {
        cfg = d;
        // Reset state
        Object.assign(state, {
            firstname: '', lastname: '', gender: 0,
            birth_day: 1, birth_month: 1, birth_year: cfg.birthYearMax || 2003,
            skin_color: 0, eye_color: 0, hair_style: 0, hair_color: 0, hair_highlight: 0,
            face_features: new Array(20).fill(0.0),
        });
        buildStep1();
        buildStep2();
        buildStep3();
        setStep(1);
        overlay.classList.remove('hidden');
        triggerPreview();
    }

    if (d.action === 'close') {
        overlay.classList.add('hidden');
    }
});
