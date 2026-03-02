/* ============================================================
   nxn-licenses | app.js
   ============================================================ */

'use strict';

// ── Állapot ──

const STATE = {
    licenses:       {},
    activeLicType:  null,
};

// ── DOM helper ──

const $id  = id => document.getElementById(id);
function esc(s) {
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function nuiFetch(cb, data) {
    return fetch('https://nxn-licenses/' + cb, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    }).then(r => r.json()).catch(() => null);
}

// ── Szín segéd ──

function applyLicColor(el, def) {
    const color = (def && def.color) ? def.color : 'var(--nxn-accent)';
    el.style.setProperty('--lic-color', color);
    if (def && def.id) {
        el.classList.forEach(c => { if (c.startsWith('lic-type-')) el.classList.remove(c); });
        el.classList.add('lic-type-' + def.id);
    }
}

// ── Fő panel ──

function renderList() {
    const list = $id('lic-list');
    list.innerHTML = '';

    for (const [typeId, entry] of Object.entries(STATE.licenses)) {
        const { def, license, pending } = entry;
        let statusKey = 'none';
        let subText   = 'Nincs kiváltva';
        let iconClass = '';

        if (pending) {
            statusKey = 'pending';
            iconClass = 'pending';
            // String() védelem: ready_at lehet nem-string (pl. Unix timestamp)
            const rd = pending.ready_at ? String(pending.ready_at).split(' ')[0] : '?';
            subText = `Feldolgozás: ${rd}`;
        } else if (license) {
            const expired = isExpired(license.expires_at);
            statusKey = expired ? 'expired' : 'active';
            iconClass = expired ? 'expired' : '';
            if (license.expires_at) {
                subText = expired
                    ? `Lejárt: ${fmtDate(license.expires_at)}`
                    : `Érvényes: ${fmtDate(license.expires_at)}-ig`;
            } else {
                subText = 'Érvényes (nem jár le)';
            }
        }

        const statusLabels = { active: 'Érvényes', expired: 'Lejárt', pending: 'Folyamatban', none: 'Nincs' };
        const canView  = license && !isExpired(license.expires_at);
        const canShow  = canView;
        const canApply = !pending && (!license || isExpired(license.expires_at));

        const row = document.createElement('div');
        row.className = 'lic-row';
        applyLicColor(row, def);

        row.innerHTML = `
            <div class="lic-icon ${esc(iconClass)}"><i class="hgi hgi-stroke ${esc(def.icon)}"></i></div>
            <div class="lic-info">
                <div class="lic-label">${esc(def.label)}</div>
                <div class="lic-sub">
                    <span class="status-badge ${esc(statusKey)}">${esc(statusLabels[statusKey])}</span>
                    ${esc(subText)}
                </div>
            </div>
            <div class="lic-actions">
                <button class="btn-icon view" title="Megtekintés" data-type="${esc(typeId)}"
                    ${canView ? '' : 'disabled'}>
                    <i class="hgi hgi-stroke hgi-eye-01"></i>
                </button>
                <button class="btn-icon show" title="Felmutatás" data-type="${esc(typeId)}"
                    ${canShow ? '' : 'disabled'}>
                    <i class="hgi hgi-stroke hgi-user-share-01"></i>
                </button>
                <button class="btn-icon apply" title="Igénylés" data-type="${esc(typeId)}"
                    ${canApply ? '' : 'disabled'}>
                    <i class="hgi hgi-stroke hgi-add-circle"></i>
                </button>
            </div>
        `;

        row.querySelector('.btn-icon.view').onclick  = () => openViewModal(typeId);
        row.querySelector('.btn-icon.show').onclick  = () => openShowModal(typeId);
        row.querySelector('.btn-icon.apply').onclick = () => applyLicense(typeId);
        list.appendChild(row);
    }
}

// ── Igazolvány nézet modal ──

function openViewModal(typeId) {
    const entry = STATE.licenses[typeId];
    if (!entry || !entry.license) return;
    buildCard($id('card-wrap'), entry, false);
    $id('card-modal').classList.remove('hidden');
}

function buildCard(container, entry, isShown) {
    const { def, license } = entry;
    const expired    = license.expires_at ? isExpired(license.expires_at) : false;
    const ownerName  = entry.ownerName  || null;
    const birthdate  = entry.birthdate  || null;
    const gender     = entry.gender     || null;
    const fields     = def.showFields   || ['name','birthdate','id_number','issued','expires'];

    let fieldHTML = '';

    if (fields.includes('name') && ownerName) {
        fieldHTML += fieldEl('Név', ownerName, true);
    }

    const rest = [];
    if (fields.includes('birthdate') && birthdate)      rest.push(fieldEl('Születési dátum', birthdate));
    if (fields.includes('gender')    && gender)         rest.push(fieldEl('Nem', gender));
    if (fields.includes('id_number'))                   rest.push(fieldEl('Azonosító', license.id_number || '?'));
    if (fields.includes('issued') && license.issued_at) rest.push(fieldEl('Kiállítva', fmtDate(license.issued_at)));
    if (fields.includes('expires') && license.expires_at) rest.push(fieldEl('Lejár', fmtDate(license.expires_at)));

    fieldHTML += rest.join('');

    container.innerHTML = `
        <div class="id-card">
            <div class="id-card-side">
                <i class="hgi hgi-stroke ${esc(def.icon)}"></i>
                <span class="id-card-side-label">Nexon&nbsp;RP</span>
            </div>
            <div class="id-card-main">
                <div class="id-card-top">
                    <div class="id-card-top-titles">
                        <div class="card-title">${esc(def.label)}</div>
                        <div class="card-subtitle">Nexon Roleplay &ndash; Hivatalos Igazolv&aacute;ny</div>
                    </div>
                    <span class="id-card-flag ${expired ? 'expired' : 'active'}">
                        ${expired ? 'Lejárt' : 'Érvényes'}
                    </span>
                </div>
                <div class="id-card-fields">${fieldHTML}</div>
                <div class="id-card-footer">
                    <div class="id-card-footer-left">
                        <i class="hgi hgi-stroke hgi-shield-01"></i>
                        ${isShown ? 'Felmutatva egy játékos által' : 'Saját igazolvány'}
                    </div>
                    <div class="id-card-footer-right">NEXON&nbsp;RP</div>
                </div>
            </div>
        </div>
    `;

    applyLicColor(container, def);
}

function fieldEl(key, val, wide = false) {
    return `<div class="id-field${wide ? ' wide' : ''}">
        <span class="id-field-key">${esc(key)}</span>
        <span class="id-field-val">${esc(val)}</span>
    </div>`;
}

// ── Felmutatás modal ──

function openShowModal(typeId) {
    STATE.activeLicType = typeId;
    $id('show-modal').classList.remove('hidden');
    loadNearbyPlayers();
}

function loadNearbyPlayers() {
    $id('show-players').innerHTML = `
        <div class="show-loading">
            <i class="hgi hgi-stroke hgi-loading-01"></i> Keresslük a közelben lévőket...
        </div>`;

    nuiFetch('getNearbyPlayers').then(players => {
        const wrap = $id('show-players');
        if (!players || players.length === 0) {
            wrap.innerHTML = `<div class="show-loading" style="color:var(--nxn-muted)"><i class="hgi hgi-stroke hgi-user-remove-01"></i> Nincs közelben játékos (10m)</div>`;
            return;
        }
        wrap.innerHTML = '';
        players.forEach(p => {
            const row = document.createElement('div');
            row.className = 'show-player-row';
            row.innerHTML = `
                <i class="hgi hgi-stroke hgi-user-01" style="color:var(--nxn-accent)"></i>
                <span class="show-player-name">${esc(p.name)}</span>
                <span class="show-player-dist">${p.dist} m</span>
            `;
            row.onclick = () => {
                nuiFetch('showTo', { licenseType: STATE.activeLicType, targetSrc: p.src });
                $id('show-modal').classList.add('hidden');
            };
            wrap.appendChild(row);
        });
    });
}

// ── Igénylés ──

function applyLicense(typeId) {
    nuiFetch('apply', { licenseType: typeId });
}

// ── NUI üzenet fogadás ──

window.addEventListener('message', function(ev) {
    const d = ev.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'setVisible':
            if (d.visible) {
                $id('lic-root').classList.remove('hidden');
            } else {
                $id('lic-root').classList.add('hidden');
                $id('card-modal').classList.add('hidden');
                $id('show-modal').classList.add('hidden');
            }
            break;

        case 'updateData':
            STATE.licenses = d.licenses || {};
            renderList();
            break;

        case 'showCard': {
            const payload = d.payload;
            const fakeEntry = {
                def:       payload.def,
                license:   payload.license,
                ownerName: payload.ownerName,
                birthdate: payload.birthdate,
                gender:    payload.gender,
            };
            buildCard($id('card-wrap'), fakeEntry, true);
            $id('card-modal').classList.remove('hidden');
            $id('lic-root').classList.remove('hidden');
            break;
        }
    }
});

// ── Események ──

document.addEventListener('DOMContentLoaded', function() {
    $id('lic-close').addEventListener('click',  () => nuiFetch('close'));
    $id('card-close').addEventListener('click', () => $id('card-modal').classList.add('hidden'));
    $id('show-close').addEventListener('click', () => $id('show-modal').classList.add('hidden'));
    $id('show-refresh').addEventListener('click', loadNearbyPlayers);

    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') {
            if (!$id('card-modal').classList.contains('hidden')) {
                $id('card-modal').classList.add('hidden');
            } else if (!$id('show-modal').classList.contains('hidden')) {
                $id('show-modal').classList.add('hidden');
            } else {
                nuiFetch('close');
            }
        }
    });
});

// ── Segédfüggvények ──

/**
 * isExpired / fmtDate: a dtStr paraméter a szerverről érkezhet string helyett
 * más típusként is (pl. Unix timestamp számként, Date objektumként).
 * A String() konverzió biztosítja, hogy a .replace() hívás ne crasheljen.
 * isNaN ellenőrzés véd az érvénytelen dátumformátumok ellen.
 */
function isExpired(dtStr) {
    if (!dtStr) return false;
    const s = typeof dtStr === 'string' ? dtStr : String(dtStr);
    const d = new Date(s.replace(' ', 'T') + 'Z');
    if (isNaN(d.getTime())) return false;
    return d < new Date();
}

function fmtDate(dtStr) {
    if (!dtStr) return '?';
    const s = typeof dtStr === 'string' ? dtStr : String(dtStr);
    const d = new Date(s.replace(' ', 'T') + 'Z');
    if (isNaN(d.getTime())) return String(dtStr);
    return d.toLocaleDateString('hu-HU', { year: 'numeric', month: '2-digit', day: '2-digit' });
}
