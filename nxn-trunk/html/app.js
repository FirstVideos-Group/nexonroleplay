// ── Nexon NUI Bridge ─────────────────────────────────────────
const sendNui = (event, data = {}) =>
    fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });

// ── Állapot ──────────────────────────────────────────────────
let currentPlate   = '';
let trunkItems     = [];
let invItems       = {};
let trunkMax       = 50;
let trunkCurrent   = 0;
let invMax         = 30;
let invMaxWeight   = 30;

let ctxTarget = null;  // { side: 'trunk'|'inv', itemName, count, weight }

// ── DOM ──────────────────────────────────────────────────────
const panel        = document.getElementById('nxn-trunk-panel');
const btnClose     = document.getElementById('btn-close');
const trunkPlate   = document.getElementById('trunk-plate');
const trunkWeightEl = document.getElementById('trunk-weight');
const trunkBar     = document.getElementById('trunk-weight-bar');
const invWeightEl  = document.getElementById('inv-weight');
const invBar       = document.getElementById('inv-weight-bar');
const trunkGrid    = document.getElementById('trunk-grid');
const invGrid      = document.getElementById('inv-grid');
const feedback     = document.getElementById('trunk-feedback');
const ctxMenu      = document.getElementById('item-ctx-menu');
const ctxMove      = document.getElementById('ctx-move');
const ctxCancel    = document.getElementById('ctx-cancel');

// ── Segédfüggvények ──────────────────────────────────────────

function fmtW(n) { return parseFloat(n).toFixed(1); }

function showFeedback(msg, type = 'info') {
    feedback.textContent = msg;
    feedback.className = `trunk-feedback ${type}`;
    feedback.classList.remove('hidden');
    clearTimeout(feedback._t);
    feedback._t = setTimeout(() => feedback.classList.add('hidden'), 3500);
}

function updateWeightBar(barEl, badgeEl, current, max, label) {
    const pct = max > 0 ? Math.min(100, (current / max) * 100) : 0;
    barEl.style.width = pct + '%';
    barEl.style.background = pct > 85 ? 'var(--nxn-danger)' : pct > 60 ? 'var(--nxn-warning)' : 'var(--nxn-accent)';
    badgeEl.textContent = `${fmtW(current)} / ${fmtW(max)} kg`;
}

function hideCtx() {
    ctxMenu.classList.add('hidden');
    ctxTarget = null;
}

function showCtx(e, side, itemName, count, weight) {
    ctxTarget = { side, itemName, count, weight };
    const label = side === 'trunk' ? 'Átrak Inventoryba' : 'Átrak Csomagtartóba';
    ctxMove.textContent = label;
    ctxMenu.style.left = e.pageX + 'px';
    ctxMenu.style.top  = e.pageY + 'px';
    ctxMenu.classList.remove('hidden');
    e.stopPropagation();
}

// ── Renderelés ────────────────────────────────────────────────

function renderGrid(container, items, side) {
    container.innerHTML = '';
    const list = side === 'trunk' ? items : Object.entries(items).map(([name, d]) => ({ name, ...d }));

    if (!list || list.length === 0) {
        const hint = document.createElement('div');
        hint.className = 'empty-hint';
        hint.textContent = 'Nincs item';
        container.appendChild(hint);
        return;
    }

    list.forEach(item => {
        const name   = item.name || item[0];
        const count  = item.count || 1;
        const label  = item.label || name;
        const icon   = item.icon  || 'hgi-package-01';
        const weight = item.weight || 0;

        const card = document.createElement('div');
        card.className = 'item-card';
        card.innerHTML = `
            <span class="item-count">${count}x</span>
            <i class="hgi hgi-stroke ${icon}"></i>
            <span class="item-label">${label}</span>
        `;

        // Bal klikk: azonnali 1 db átrakás
        card.addEventListener('click', () => {
            if (side === 'trunk') {
                sendNui('moveToInventory', { itemName: name, count: 1, itemWeight: weight });
            } else {
                sendNui('moveToTrunk', { itemName: name, count: 1, itemWeight: weight });
            }
        });

        // Jobb klikk: kontextmenü
        card.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            showCtx(e, side, name, count, weight);
        });

        container.appendChild(card);
    });
}

function renderAll() {
    trunkPlate.textContent = currentPlate;
    updateWeightBar(trunkBar, trunkWeightEl, trunkCurrent, trunkMax, 'Csomagtartó');
    updateWeightBar(invBar,   invWeightEl,   invMax,       invMaxWeight, 'Hátizsak');
    renderGrid(trunkGrid, trunkItems, 'trunk');
    renderGrid(invGrid,   invItems,   'inv');
}

// ── Event listeners ──────────────────────────────────────────

btnClose.addEventListener('click', () => {
    panel.classList.add('hidden');
    sendNui('close');
});

document.getElementById('btn-move-all-to-inv').addEventListener('click', () => {
    if (!trunkItems || trunkItems.length === 0) return;
    trunkItems.forEach(item => {
        sendNui('moveToInventory', { itemName: item.name, count: item.count || 1, itemWeight: item.weight || 0 });
    });
});

document.getElementById('btn-move-all-to-trunk').addEventListener('click', () => {
    const entries = Object.entries(invItems);
    if (entries.length === 0) return;
    entries.forEach(([name, d]) => {
        sendNui('moveToTrunk', { itemName: name, count: d.count || 1, itemWeight: d.weight || 0 });
    });
});

// Kontextmenü akciók
ctxMove.addEventListener('click', () => {
    if (!ctxTarget) return;
    if (ctxTarget.side === 'trunk') {
        sendNui('moveToInventory', { itemName: ctxTarget.itemName, count: ctxTarget.count, itemWeight: ctxTarget.weight });
    } else {
        sendNui('moveToTrunk', { itemName: ctxTarget.itemName, count: ctxTarget.count, itemWeight: ctxTarget.weight });
    }
    hideCtx();
});

ctxCancel.addEventListener('click', hideCtx);

document.addEventListener('click', hideCtx);
document.addEventListener('contextmenu', e => {
    if (!ctxMenu.contains(e.target)) hideCtx();
});

window.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        panel.classList.add('hidden');
        sendNui('close');
        hideCtx();
    }
});

// ── NUI üzenetek ─────────────────────────────────────────────

window.addEventListener('message', ({ data }) => {
    if (!data?.action) return;

    switch (data.action) {
        case 'setVisible':
            panel.classList.toggle('hidden', !data.visible);
            if (!data.visible) hideCtx();
            break;

        case 'sync':
            currentPlate = data.plate || '';
            trunkItems   = data.trunkItems  || [];
            invItems     = data.invItems    || {};
            trunkMax     = data.trunkMax    || 50;
            trunkCurrent = data.trunkCurrent || 0;
            invMax       = data.invMax      || 0;
            invMaxWeight = data.invMaxWeight || 30;
            renderAll();
            break;

        case 'moveResult':
            if (!data.ok) {
                showFeedback(data.message || 'Hiba történt!', 'danger');
            }
            break;
    }
});
