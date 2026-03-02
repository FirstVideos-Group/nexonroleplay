/* nxn-garage | app.js */
'use strict';

// ── Állapot ──────────────────────────────────────────────────────
let currentGarageId  = null;
let currentPlate     = '';
let vehicles         = [];
let nearGarageIds    = [];  // a kliens küldött nearGarages list

// ── DOM ───────────────────────────────────────────────────────────
const overlay   = document.getElementById('overlay');
const garageTitle  = document.getElementById('garage-title');
const vehicleCount = document.getElementById('vehicle-count');
const loading   = document.getElementById('loading');
const empty     = document.getElementById('empty');
const grid      = document.getElementById('vehicle-grid');

// ── Segédek ───────────────────────────────────────────────────────
function hpClass(hp) {
    if (hp <= 0)  return 'hp-dead';
    if (hp < 15)  return 'hp-danger';
    if (hp < 40)  return 'hp-warn';
    return 'hp-ok';
}

function hpLabel(hp) {
    if (hp <= 0) return 'Letörtött';
    return Math.round(hp) + '%';
}

function vehicleIcon(cls) {
    const map = {
        8:  'hgi-motorcycle',
        12: 'hgi-boat-01',
        15: 'hgi-helicopter',
        16: 'hgi-plane',
        18: 'hgi-ambulance',
        19: 'hgi-tank',
    };
    return 'hgi hgi-stroke ' + (map[cls] || 'hgi-car-01');
}

function renderCard(v) {
    const isImpounded = v.impounded;
    const isStored    = v.stored;
    const hp          = typeof v.engineHP === 'number' ? v.engineHP : 100;
    const isMyCar     = v.plate === currentPlate;

    const cardClass = [
        'veh-card',
        isImpounded ? 'impounded' : '',
    ].filter(Boolean).join(' ');

    let badge = '';
    if (isImpounded) {
        badge = `<span class="badge badge-impound"><i class="hgi hgi-stroke hgi-police-01" style="font-size:10px"></i> Lefoglalva</span>`;
    } else if (isStored) {
        badge = `<span class="badge badge-stored"><i class="hgi hgi-stroke hgi-checkmark-circle-01" style="font-size:10px"></i> Garázsban</span>`;
    } else {
        badge = `<span class="badge badge-out"><i class="hgi hgi-stroke hgi-circle" style="font-size:10px"></i> Kinn</span>`;
    }

    const spawnDisabled  = (!isStored || isImpounded)  ? 'disabled' : '';
    const despawnDisabled = (!isMyCar || isStored || isImpounded) ? 'disabled' : '';

    return `
    <div class="veh-card ${isImpounded ? 'impounded' : ''}" data-plate="${v.plate}">
        <div class="card-top">
            <i class="${vehicleIcon(v.class)} card-icon"></i>
            <div style="flex:1;min-width:0">
                <div class="card-label">${v.label || v.model}</div>
                <div class="card-plate">${v.plate}</div>
            </div>
            ${badge}
        </div>
        <div class="hp-wrap">
            <div class="hp-label"><span>Motor HP</span><span>${hpLabel(hp)}</span></div>
            <div class="hp-bar-bg">
                <div class="hp-bar-fill ${hpClass(hp)}" style="width:${Math.max(0, Math.min(100, hp))}%"></div>
            </div>
        </div>
        <div class="card-btns">
            <button class="btn-spawn" data-plate="${v.plate}" ${spawnDisabled}>
                <i class="hgi hgi-stroke hgi-arrow-down-01"></i> Kivesz
            </button>
            <button class="btn-despawn" data-plate="${v.plate}" ${despawnDisabled}>
                <i class="hgi hgi-stroke hgi-arrow-up-01"></i> Elrak
            </button>
        </div>
    </div>`;
}

function renderGrid() {
    grid.innerHTML = '';
    if (!vehicles.length) {
        loading.classList.add('hidden');
        empty.classList.remove('hidden');
        return;
    }
    loading.classList.add('hidden');
    empty.classList.add('hidden');
    grid.innerHTML = vehicles.map(renderCard).join('');
    vehicleCount.textContent = vehicles.length + ' jármű';
}

// ── Gomb kezelők ─────────────────────────────────────────────────
document.getElementById('btn-close').addEventListener('click', () => {
    fetch('https://nxn-garage/close', { method: 'POST', body: JSON.stringify({}) });
});

document.getElementById('btn-refresh').addEventListener('click', () => {
    loading.classList.remove('hidden');
    empty.classList.add('hidden');
    grid.innerHTML = '';
    fetch('https://nxn-garage/refresh', { method: 'POST', body: JSON.stringify({}) });
});

grid.addEventListener('click', e => {
    const spawnBtn   = e.target.closest('.btn-spawn');
    const despawnBtn = e.target.closest('.btn-despawn');

    if (spawnBtn && !spawnBtn.disabled) {
        const plate = spawnBtn.dataset.plate;
        spawnBtn.disabled = true;
        fetch('https://nxn-garage/spawn', {
            method: 'POST',
            body: JSON.stringify({ plate })
        });
    }

    if (despawnBtn && !despawnBtn.disabled) {
        const plate = despawnBtn.dataset.plate;
        despawnBtn.disabled = true;
        fetch('https://nxn-garage/despawn', {
            method: 'POST',
            body: JSON.stringify({ plate })
        });
    }
});

// ESC bezárás
window.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        fetch('https://nxn-garage/close', { method: 'POST', body: JSON.stringify({}) });
    }
});

// ── NUI Message handler ───────────────────────────────────────────
window.addEventListener('message', e => {
    const d = e.data;
    if (!d || !d.action) return;

    if (d.action === 'open') {
        currentGarageId = d.garageId;
        overlay.classList.remove('hidden');
        loading.classList.remove('hidden');
        empty.classList.add('hidden');
        grid.innerHTML = '';
        return;
    }

    if (d.action === 'close') {
        overlay.classList.add('hidden');
        vehicles = [];
        grid.innerHTML = '';
        return;
    }

    if (d.action === 'vehicleList') {
        vehicles     = d.vehicles || [];
        currentPlate = d.currentPlate || '';
        garageTitle.textContent = d.garageLabel || 'Garázs';
        renderGrid();
        return;
    }

    if (d.action === 'spawnResult') {
        // gombok resetálása
        document.querySelectorAll('.btn-spawn').forEach(b => b.disabled = false);
        return;
    }

    if (d.action === 'despawnResult') {
        document.querySelectorAll('.btn-despawn').forEach(b => b.disabled = false);
        return;
    }
});
