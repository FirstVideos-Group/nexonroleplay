// ── Nexon NUI Bridge ─────────────────────────────────────────

const sendNui = (event, data = {}) =>
    fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });

// ── UI ───────────────────────────────────────────────────────

const panel   = document.getElementById('nxn-panel');
const btnClose  = document.getElementById('btn-close');
const btnAction = document.getElementById('btn-action');

btnClose.addEventListener('click', () => {
    panel.classList.add('hidden');
    sendNui('close');
});

btnAction.addEventListener('click', () => {
    sendNui('doAction', { type: 'notify', message: 'Akció sikeresen lefutott!' });
});

// Escape billentyű -> bezárás
window.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        panel.classList.add('hidden');
        sendNui('close');
    }
});

// ── NUI üzenetek fogadása ─────────────────────────────────────

window.addEventListener('message', ({ data }) => {
    if (!data?.action) return;

    switch (data.action) {
        case 'setVisible':
            panel.classList.toggle('hidden', !data.visible);
            break;
        case 'showNotify':
            showNotify(data.message, data.type);
            break;
    }
});

// ── Értesítés ─────────────────────────────────────────────────

function showNotify(message, type = 'info') {
    const container = document.getElementById('notify-container');
    const el = document.createElement('div');
    el.className = `nxn-notify ${type}`;
    el.innerHTML = `<i class="hgi hgi-stroke hgi-information-circle"></i><span>${message}</span>`;
    container.appendChild(el);
    setTimeout(() => el.remove(), 4000);
}