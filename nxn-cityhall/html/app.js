/* ============================================================
   nxn-cityhall | app.js
   ============================================================ */

'use strict';

const $id = id => document.getElementById(id);
function esc(s) {
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
function nuiFetch(cb, data) {
    return fetch('https://nxn-cityhall/' + cb, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {}),
    }).then(r => r.json()).catch(() => null);
}

// ── Nézetek ──

function renderInfo(config) {
    const items = (config.infoItems || []).map(item => `
        <div class="info-item">
            <i class="hgi hgi-stroke ${esc(item.icon)}"></i>
            <span>${esc(item.text)}</span>
        </div>
    `).join('');

    $id('ch-panel-title').textContent = config.infoTitle || 'Önkormányzati Tájékoztató';
    $id('ch-body').innerHTML = `
        <div class="info-section">
            <h3>Fontos tudnivalók</h3>
            ${items}
        </div>
    `;
}

function renderFines(fines, config) {
    $id('ch-panel-title').textContent = config.finesTitle || 'Csekk / Bírság Kezelő';

    if (!fines || fines.length === 0) {
        $id('ch-body').innerHTML = `
            <div class="fines-empty">
                <i class="hgi hgi-stroke hgi-checkmark-circle-01"></i>
                <span>${esc(config.finesEmpty || 'Nincs fiiggő bírságod!')}</span>
            </div>
        `;
        return;
    }

    $id('ch-body').innerHTML = fines.map(fine => `
        <div class="fine-row">
            <div class="fine-icon">
                <i class="hgi hgi-stroke hgi-invoice-03"></i>
            </div>
            <div class="fine-info">
                <div class="fine-reason">${esc(fine.reason)}</div>
                <div class="fine-meta">
                    <span>${fmtDate(fine.issued_at)}</span>
                    <span>#${esc(String(fine.id))}</span>
                </div>
            </div>
            <div class="fine-amount">$${esc(String(fine.amount))}</div>
            <button class="btn-pay" data-id="${esc(String(fine.id))}">
                <i class="hgi hgi-stroke hgi-money-send-02"></i> Befizetés
            </button>
        </div>
    `).join('');

    // Gomb események
    $id('ch-body').querySelectorAll('.btn-pay').forEach(btn => {
        btn.addEventListener('click', () => {
            nuiFetch('payFine', { fineId: parseInt(btn.dataset.id) });
        });
    });
}

// ── NUI üzenet fogadás ──

window.addEventListener('message', function(ev) {
    const d = ev.data;
    if (!d || !d.action) return;

    if (d.action === 'setVisible') {
        if (d.visible) {
            $id('ch-root').classList.remove('hidden');
        } else {
            $id('ch-root').classList.add('hidden');
        }
        return;
    }

    if (d.action === 'openView') {
        $id('ch-root').classList.remove('hidden');
        const cfg = d.config || {};

        switch (d.view) {
            case 'info':
                renderInfo(cfg);
                break;
            case 'fines':
                renderFines(d.fines || [], cfg);
                break;
            default:
                $id('ch-panel-title').textContent = 'Önkormányzat';
                $id('ch-body').innerHTML = '';
        }
    }
});

// ── Események ──

document.addEventListener('DOMContentLoaded', function() {
    $id('ch-close').addEventListener('click', () => nuiFetch('close'));
    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') nuiFetch('close');
    });
});

// ── Segéd ──

function fmtDate(dtStr) {
    if (!dtStr) return '?';
    const d = new Date(dtStr.replace(' ', 'T') + 'Z');
    return d.toLocaleDateString('hu-HU', { year:'numeric', month:'2-digit', day:'2-digit' });
}
