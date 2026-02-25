/* ============================================================
   nxn-inventory | app.js
   ============================================================ */

'use strict';

// ── Állapot ──

const STATE = {
    items:       {},
    hotbar:      {},
    itemDefs:    {},
    weight:      0,
    maxWeight:   30,
    hotbarSlots: 5,
    filter:      'all',
    search:      '',
    ctxItem:     null,
};

// ── DOM ──

const $id = id => document.getElementById(id);

const DOM = {
    root:     () => $id('inv-root'),
    items:    () => $id('inv-items'),
    empty:    () => $id('inv-empty'),
    wVal:     () => $id('weight-val'),
    wMax:     () => $id('weight-max'),
    wWrap:    () => $id('inv-weight'),
    search:   () => $id('inv-search'),
    ctx:      () => $id('ctx-menu'),
    hotbar:   () => $id('hotbar'),
    close:    () => $id('inv-close'),
};

// ── Segédfüggvények ──

function esc(str) {
    return String(str)
        .replace(/&/g,'&amp;').replace(/</g,'&lt;')
        .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function nuiFetch(cb, data) {
    fetch('https://nxn-inventory/' + cb, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    }).catch(() => {});
}

function closeInv() {
    DOM.root().classList.add('hidden');
    nuiFetch('close');
    hideCtx();
}

// ── Inventory render ──

function renderItems() {
    const wrap  = DOM.items();
    const empty = DOM.empty();
    const q     = STATE.search.toLowerCase();

    // Szűrés
    const visible = [];
    for (const [name, slot] of Object.entries(STATE.items)) {
        if (STATE.filter !== 'all' && slot.category !== STATE.filter) continue;
        if (q && !slot.label.toLowerCase().includes(q)) continue;
        visible.push({ name, ...slot });
    }

    // Hotbar slot számok itemre
    const hotbarSlots = {};
    for (const [slot, name] of Object.entries(STATE.hotbar)) {
        hotbarSlots[name] = slot;
    }

    // Render
    const existing = {};
    wrap.querySelectorAll('.inv-item').forEach(el => {
        existing[el.dataset.item] = el;
    });

    const inDom = new Set();
    visible.forEach(item => {
        let el = existing[item.name];
        const hotSlot = hotbarSlots[item.name];
        const totalW  = (item.weight * item.count).toFixed(2);

        if (!el) {
            el = document.createElement('div');
            el.className   = 'inv-item';
            el.dataset.item = item.name;
            wrap.appendChild(el);
        }

        el.innerHTML = `
            <div class="inv-item-icon"><i class="hgi hgi-stroke ${esc(item.icon)}"></i></div>
            <div class="inv-item-info">
                <div class="inv-item-label">${esc(item.label)}</div>
                <div class="inv-item-meta">
                    <span class="inv-item-weight"><i class="hgi hgi-stroke hgi-weight-scale"></i>${totalW} kg</span>
                    ${item.usable ? '<span class="inv-item-usable">Használható</span>' : ''}
                </div>
            </div>
            <div class="inv-item-count">x${item.count}</div>
            ${hotSlot ? `<div class="inv-item-hotbar-badge">${hotSlot}</div>` : ''}
        `;

        el.oncontextmenu = (e) => { e.preventDefault(); showCtx(e, item.name); };
        el.onclick = null;
        inDom.add(item.name);
    });

    // Töröl feleslegeseket
    for (const [name, el] of Object.entries(existing)) {
        if (!inDom.has(name)) el.remove();
    }

    empty.style.display = visible.length === 0 ? 'flex' : 'none';
}

function renderWeight() {
    const pct = STATE.weight / STATE.maxWeight;
    DOM.wVal().textContent = STATE.weight.toFixed(1);
    DOM.wMax().textContent = STATE.maxWeight.toFixed(1);
    const w = DOM.wWrap();
    w.classList.remove('warn','full');
    if (pct >= 1.0)       w.classList.add('full');
    else if (pct >= 0.75) w.classList.add('warn');
}

// ── Hotbar render ──

function renderHotbar() {
    const bar = DOM.hotbar();
    bar.innerHTML = '';
    for (let i = 1; i <= STATE.hotbarSlots; i++) {
        const itemName = STATE.hotbar[String(i)];
        const slot     = document.createElement('div');
        slot.className = 'hotbar-slot' + (itemName ? ' has-item' : '');
        slot.dataset.slot = i;

        let inner = `<span class="hotbar-slot-key">${i}</span>`;

        if (itemName) {
            const def = STATE.itemDefs[itemName] || STATE.items[itemName];
            const inv = STATE.items[itemName];
            if (def) {
                inner += `
                    <i class="hgi hgi-stroke ${esc(def.icon)} hotbar-slot-icon"></i>
                    ${inv ? `<span class="hotbar-slot-count">x${inv.count}</span>` : ''}
                    <span class="hotbar-slot-label">${esc(def.label)}</span>
                `;
            }
        } else {
            inner += `<i class="hgi hgi-stroke hgi-plus-sign hotbar-slot-icon" style="opacity:.2"></i>`;
        }

        slot.innerHTML = inner;
        bar.appendChild(slot);
    }
}

// ── Context menü ──

function showCtx(e, itemName) {
    STATE.ctxItem = itemName;
    const menu    = DOM.ctx();
    const slot    = STATE.items[itemName];
    if (!slot) return;

    $id('ctx-item-header').textContent = slot.label || itemName;

    const acts = $id('ctx-actions');
    acts.innerHTML = '';

    // Használat (csak használható itemre)
    if (slot.usable) {
        const btn = ctxBtn('hgi-play-circle-01', 'Használat', false, () => {
            nuiFetch('useItem', { item: itemName });
            hideCtx();
        });
        acts.appendChild(btn);
    }

    // Hotbar-ra rakás
    const inHotbar = Object.values(STATE.hotbar).includes(itemName);
    if (inHotbar) {
        const btn = ctxBtn('hgi-arrow-up-01', 'Hotbarról le', false, () => {
            removeFromHotbar(itemName);
            hideCtx();
        });
        acts.appendChild(btn);
    } else {
        const btn = ctxBtn('hgi-arrow-down-01', 'Hotbar-ra', false, () => {
            addToHotbar(itemName);
            hideCtx();
        });
        acts.appendChild(btn);
    }

    // Eldobás
    acts.appendChild(ctxBtn('hgi-package-remove', 'Eldobás', false, () => {
        nuiFetch('dropItem', { item: itemName, count: 1 });
        hideCtx();
    }));

    // Törlés
    acts.appendChild(ctxBtn('hgi-delete-01', 'Törlés', true, () => {
        nuiFetch('deleteItem', { item: itemName, count: slot.count || 1 });
        hideCtx();
    }));

    // Pozícionálás
    const x = Math.min(e.clientX, window.innerWidth  - 200);
    const y = Math.min(e.clientY, window.innerHeight - 200);
    menu.style.left = x + 'px';
    menu.style.top  = y + 'px';
    menu.classList.remove('hidden');
}

function hideCtx() {
    DOM.ctx().classList.add('hidden');
    STATE.ctxItem = null;
}

function ctxBtn(icon, label, danger, fn) {
    const btn = document.createElement('button');
    btn.className = 'ctx-action' + (danger ? ' danger' : '');
    btn.innerHTML = `<i class="hgi hgi-stroke ${esc(icon)}"></i>${esc(label)}`;
    btn.onclick = fn;
    return btn;
}

// ── Hotbar kezelés ──

function addToHotbar(itemName) {
    // Keresünk üres slotot
    for (let i = 1; i <= STATE.hotbarSlots; i++) {
        if (!STATE.hotbar[String(i)]) {
            STATE.hotbar[String(i)] = itemName;
            nuiFetch('updateHotbar', { hotbar: STATE.hotbar });
            renderHotbar();
            renderItems();
            return;
        }
    }
    // Nincs üres slot
    console.warn('[nxn-inventory] Nincs üres hotbar slot');
}

function removeFromHotbar(itemName) {
    for (const [slot, name] of Object.entries(STATE.hotbar)) {
        if (name === itemName) {
            delete STATE.hotbar[slot];
            nuiFetch('updateHotbar', { hotbar: STATE.hotbar });
            renderHotbar();
            renderItems();
            return;
        }
    }
}

// ── NUI üzenet fogadás ──

window.addEventListener('message', function (ev) {
    const d = ev.data;
    if (!d || !d.action) return;

    switch (d.action) {

        case 'setVisible':
            if (d.visible) {
                DOM.root().classList.remove('hidden');
            } else {
                DOM.root().classList.add('hidden');
                hideCtx();
            }
            break;

        case 'updateInventory':
            STATE.items       = d.items       || {};
            STATE.hotbar      = d.hotbar      || {};
            STATE.weight      = d.weight      || 0;
            STATE.maxWeight   = d.maxWeight   || 30;
            STATE.hotbarSlots = d.hotbarSlots || 5;
            STATE.itemDefs    = d.itemDefs    || {};
            renderWeight();
            renderItems();
            renderHotbar();
            break;
    }
});

// ── Események ──

document.addEventListener('DOMContentLoaded', function () {

    // Bezárás gomb
    DOM.close().addEventListener('click', closeInv);

    // ESC kellõ
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') closeInv();
    });

    // Kereső
    DOM.search().addEventListener('input', function () {
        STATE.search = this.value;
        renderItems();
    });

    // Filter gombok
    document.querySelectorAll('.inv-filter').forEach(btn => {
        btn.addEventListener('click', function () {
            document.querySelectorAll('.inv-filter').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            STATE.filter = this.dataset.cat;
            renderItems();
        });
    });

    // Kattintás bárhova = ctx bezár
    document.addEventListener('mousedown', function (e) {
        if (!DOM.ctx().contains(e.target)) hideCtx();
    });

    // Initial hotbar
    renderHotbar();
});
