// ── NUI Bridge ────────────────────────────────────────────────
const sendNui = (event, data = {}) =>
    fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });

// ── State ────────────────────────────────────────────────────
let keys = [];
let giveTargetPlate = null;

// ── DOM ──────────────────────────────────────────────────────
const panel       = document.getElementById('keyring-panel');
const keyList     = document.getElementById('key-list');
const emptyState  = document.getElementById('empty-state');
const keyCount    = document.getElementById('key-count');
const giveDrawer  = document.getElementById('give-drawer');
const givePlate   = document.getElementById('give-plate-label');
const nearbyList  = document.getElementById('nearby-list');
const nearbyEmpty = document.getElementById('nearby-empty');
const btnClose    = document.getElementById('btn-close');
const giveClose   = document.getElementById('give-close');

// ── Render ────────────────────────────────────────────────────
function renderKeys() {
    keyList.innerHTML = '';
    keyCount.textContent = keys.length + ' kulcs';

    if (keys.length === 0) {
        emptyState.classList.remove('hidden');
        return;
    }
    emptyState.classList.add('hidden');

    keys.forEach(k => {
        const card = document.createElement('div');
        card.className = 'key-card';
        card.dataset.plate = k.plate;

        const ownerBadge = k.is_owner
            ? `<span class="badge badge-owner"><i class="hgi hgi-stroke hgi-crown"></i>Tulajdonos</span>`
            : `<span class="badge badge-shared"><i class="hgi hgi-stroke hgi-user-01"></i>Megosztott</span>`;

        const lockBadge = k.locked
            ? `<span class="badge badge-locked"><i class="hgi hgi-stroke hgi-lock-01"></i>Zárva</span>`
            : `<span class="badge badge-unlocked"><i class="hgi hgi-stroke hgi-lock-unlock-01"></i>Nyitva</span>`;

        const lockBtnLabel = k.locked ? 'Nyit' : 'Zárol';
        const lockBtnIcon  = k.locked ? 'hgi-lock-unlock-01' : 'hgi-lock-01';

        // Csak tulajdonos adhat kulcsot (is_owner=true) – a Config.OnlyOwnerCanShare logika szerveren van, de UI-ban is jélzünk
        const giveBtn = k.is_owner
            ? `<button class="nxn-btn nxn-btn--ghost btn-give" data-plate="${k.plate}"><i class="hgi hgi-stroke hgi-user-add-01"></i> Átad</button>`
            : '';

        const revokeBtn = k.is_owner
            ? '' // Tulajdonos a saját kulcsát nem vonhatja meg
            : `<button class="nxn-btn nxn-btn--danger btn-revoke hidden" data-plate="${k.plate}"><i class="hgi hgi-stroke hgi-key-remove"></i> Megvon</button>`;

        card.innerHTML = `
            <div class="key-card__top">
                <div class="key-card__icon"><i class="hgi hgi-stroke hgi-car-01"></i></div>
                <div class="key-card__info">
                    <div class="key-card__name">${k.label || k.model || 'Ismeretlen jármű'}</div>
                    <div class="key-card__plate">${k.plate}</div>
                </div>
                <div class="key-card__badges">
                    ${ownerBadge}
                    ${lockBadge}
                </div>
            </div>
            <div class="key-card__actions">
                <button class="nxn-btn btn-lock" data-plate="${k.plate}">
                    <i class="hgi hgi-stroke ${lockBtnIcon}"></i> ${lockBtnLabel}
                </button>
                ${giveBtn}
                ${revokeBtn}
            </div>
        `;

        card.querySelector('.btn-lock').addEventListener('click', () => {
            sendNui('lock', { plate: k.plate });
        });

        const giveBtnEl = card.querySelector('.btn-give');
        if (giveBtnEl) {
            giveBtnEl.addEventListener('click', () => openGiveDrawer(k.plate));
        }

        keyList.appendChild(card);
    });
}

// ── Give drawer ───────────────────────────────────────────────
function openGiveDrawer(plate) {
    giveTargetPlate = plate;
    givePlate.textContent = 'Kulcsátadás: ' + plate;
    giveDrawer.classList.remove('hidden');
    // Közeli játékosok lekérése
    sendNui('getNearby', {}).then(r => r.json()).then(players => {
        renderNearby(players);
    }).catch(() => renderNearby([]));
}

function renderNearby(players) {
    nearbyList.innerHTML = '';
    if (!players || players.length === 0) {
        nearbyEmpty.classList.remove('hidden');
        return;
    }
    nearbyEmpty.classList.add('hidden');
    players.forEach(p => {
        const item = document.createElement('div');
        item.className = 'nearby-item';
        item.innerHTML = `
            <span class="nearby-item__name">${p.name}</span>
            <span class="nearby-item__dist">${p.dist}m</span>
            <button class="nxn-btn nxn-btn--success btn-give-to" data-id="${p.id}">
                <i class="hgi hgi-stroke hgi-key-01"></i> Átad
            </button>
        `;
        item.querySelector('.btn-give-to').addEventListener('click', () => {
            if (giveTargetPlate) {
                sendNui('giveKey', { plate: giveTargetPlate, targetId: p.id });
                closeGiveDrawer();
            }
        });
        nearbyList.appendChild(item);
    });
}

function closeGiveDrawer() {
    giveDrawer.classList.add('hidden');
    giveTargetPlate = null;
}

giveClose.addEventListener('click', closeGiveDrawer);

// ── Close panel ──────────────────────────────────────────────
btnClose.addEventListener('click', () => {
    panel.classList.add('hidden');
    closeGiveDrawer();
    sendNui('close');
});

window.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        if (!giveDrawer.classList.contains('hidden')) {
            closeGiveDrawer();
        } else {
            panel.classList.add('hidden');
            sendNui('close');
        }
    }
});

// ── NUI message handler ───────────────────────────────────────
window.addEventListener('message', ({ data }) => {
    if (!data?.action) return;
    switch (data.action) {
        case 'setVisible':
            panel.classList.toggle('hidden', !data.visible);
            if (!data.visible) closeGiveDrawer();
            break;

        case 'setKeys':
            keys = data.keys || [];
            renderKeys();
            break;

        case 'lockResult':
            // Zárállapot frissítés a megfelelő kártyán
            if (data.plate) {
                const k = keys.find(x => x.plate === data.plate);
                if (k) {
                    k.locked = data.locked;
                    renderKeys();
                }
            }
            break;

        case 'nearbyPlayers':
            if (!giveDrawer.classList.contains('hidden')) {
                renderNearby(data.players);
            }
            break;

        case 'playSound':
            if (data.sound) {
                const audio = new Audio(data.sound);
                audio.volume = 0.5;
                audio.play().catch(() => {});
            }
            break;
    }
});
