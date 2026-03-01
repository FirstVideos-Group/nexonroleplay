// ── Nexon NUI Bridge ─────────────────────────────────────────
const sendNui = (event, data = {}) =>
    fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });

// ── Állapot ──────────────────────────────────────────────────
let currentMode  = 'atm';
let currentPage  = 1;
let totalItems   = 0;
const pageSize   = 20;

// ── DOM ──────────────────────────────────────────────────────
const panel        = document.getElementById('nxn-bank-panel');
const btnClose     = document.getElementById('btn-close');
const panelTitleTx = document.getElementById('panel-title-text');
const valCash      = document.getElementById('val-cash');
const valBank      = document.getElementById('val-bank');
const feedback     = document.getElementById('bank-feedback');

// Tab elemek
const tabBtns     = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');
const bankOnly    = document.querySelectorAll('.tab-bank-only');

// Log
const logList      = document.getElementById('log-list');
const logEmpty     = document.getElementById('log-empty');
const logPageInfo  = document.getElementById('log-page-info');
const btnLogPrev   = document.getElementById('btn-log-prev');
const btnLogNext   = document.getElementById('btn-log-next');

// ── Segédfüggvények ──────────────────────────────────────────

function fmt(n) {
    return '$' + Number(n).toLocaleString('hu-HU');
}

function showFeedback(msg, type = 'info') {
    feedback.textContent = msg;
    feedback.className = `bank-feedback ${type}`;
    feedback.classList.remove('hidden');
    clearTimeout(feedback._timer);
    feedback._timer = setTimeout(() => feedback.classList.add('hidden'), 4000);
}

function switchTab(tabId) {
    tabBtns.forEach(b => b.classList.toggle('active', b.dataset.tab === tabId));
    tabContents.forEach(c => c.classList.toggle('active', c.id === 'tab-' + tabId));
    if (tabId === 'log') {
        loadLog(1);
    }
}

function setMode(mode) {
    currentMode = mode;
    panelTitleTx.textContent = mode === 'bank' ? 'Bankfiók' : 'ATM';
    bankOnly.forEach(el => el.classList.toggle('hidden', mode !== 'bank'));
    switchTab('deposit');
}

function loadLog(page) {
    currentPage = page;
    sendNui('getTransactions', { page });
}

function renderLog(items, page, total) {
    totalItems = total;
    currentPage = page;
    logList.innerHTML = '';

    if (!items || items.length === 0) {
        logList.appendChild(logEmpty);
        logEmpty.classList.remove('hidden');
    } else {
        logEmpty.classList.add('hidden');
        items.forEach(tx => {
            const isPositive = tx.type === 'deposit' || tx.type === 'transfer_in';
            const typeLabel = {
                deposit: 'Befizetés', withdraw: 'Felvét',
                transfer_in: 'Beérkező utalás', transfer_out: 'Kimenő utalás', fine: 'Bírság'
            }[tx.type] || tx.type;

            const el = document.createElement('div');
            el.className = 'log-item';
            el.innerHTML = `
                <div>
                    <span class="log-type">${typeLabel}</span>
                    <span class="log-desc">${tx.description || ''}</span>
                    <span class="log-date">${(tx.created_at || '').slice(0, 16)}</span>
                </div>
                <span class="log-amount ${isPositive ? 'positive' : 'negative'}">
                    ${isPositive ? '+' : '-'}${fmt(Math.abs(tx.amount))}
                </span>
            `;
            logList.appendChild(el);
        });
    }

    const totalPages = Math.max(1, Math.ceil(total / pageSize));
    logPageInfo.textContent = `${page}. oldal / ${totalPages}`;
    btnLogPrev.disabled = page <= 1;
    btnLogNext.disabled = page >= totalPages;
}

// ── Event listeners ──────────────────────────────────────────

btnClose.addEventListener('click', () => {
    panel.classList.add('hidden');
    sendNui('close');
});

tabBtns.forEach(btn => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

document.getElementById('btn-deposit').addEventListener('click', () => {
    const amount = parseInt(document.getElementById('input-deposit').value);
    if (!amount || amount <= 0) { showFeedback('Adj meg érvényes összeget!', 'warning'); return; }
    sendNui('deposit', { amount });
    document.getElementById('input-deposit').value = '';
});

document.getElementById('btn-withdraw').addEventListener('click', () => {
    const amount = parseInt(document.getElementById('input-withdraw').value);
    if (!amount || amount <= 0) { showFeedback('Adj meg érvényes összeget!', 'warning'); return; }
    sendNui('withdraw', { amount });
    document.getElementById('input-withdraw').value = '';
});

document.getElementById('btn-transfer').addEventListener('click', () => {
    const targetId = document.getElementById('input-transfer-target').value;
    const amount   = parseInt(document.getElementById('input-transfer-amount').value);
    const desc     = document.getElementById('input-transfer-desc').value;
    if (!targetId || !amount || amount <= 0) { showFeedback('Töltsd ki a kötelező mezőket!', 'warning'); return; }
    sendNui('transfer', { targetId, amount, description: desc });
    document.getElementById('input-transfer-target').value = '';
    document.getElementById('input-transfer-amount').value = '';
    document.getElementById('input-transfer-desc').value   = '';
});

btnLogPrev.addEventListener('click', () => loadLog(currentPage - 1));
btnLogNext.addEventListener('click', () => loadLog(currentPage + 1));

window.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        panel.classList.add('hidden');
        sendNui('close');
    }
});

// ── NUI üzenetek ─────────────────────────────────────────────

window.addEventListener('message', ({ data }) => {
    if (!data?.action) return;

    switch (data.action) {
        case 'setVisible':
            panel.classList.toggle('hidden', !data.visible);
            if (data.visible) setMode(data.mode || 'atm');
            break;

        case 'updateBalance':
            valCash.textContent = fmt(data.cash ?? 0);
            valBank.textContent = fmt(data.bank ?? 0);
            break;

        case 'transactionResult':
            showFeedback(data.message, data.ok ? 'success' : 'danger');
            break;

        case 'setTransactions':
            renderLog(data.items, data.page, data.total);
            break;
    }
});
