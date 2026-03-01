'use strict';

const app    = document.getElementById('app');
const elCash = document.getElementById('cashAmount');
const elBank = document.getElementById('bankAmount');
const elOvCash  = document.getElementById('ovCash');
const elOvBank  = document.getElementById('ovBank');
const elOvTotal = document.getElementById('ovTotal');

let state = { cash: 0, bank: 0, open: false };

const fmt = n => '$' + Number(n).toLocaleString('hu-HU');

function updateBalanceUI() {
    elCash.textContent    = fmt(state.cash);
    elBank.textContent    = fmt(state.bank);
    elOvCash.textContent  = fmt(state.cash);
    elOvBank.textContent  = fmt(state.bank);
    elOvTotal.textContent = fmt(state.cash + state.bank);
}

// Tab switching
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById('tab-' + btn.dataset.tab).classList.add('active');
    });
});

// Quick amount buttons
document.querySelectorAll('.quick-btn[data-amount]').forEach(btn => {
    btn.addEventListener('click', () => {
        const target = document.getElementById(btn.dataset.target);
        if (target) target.value = btn.dataset.amount;
        target && target.dispatchEvent(new Event('input'));
    });
});

// Deposit max
document.getElementById('depositMax').addEventListener('click', () => {
    document.getElementById('depositAmount').value = state.cash;
    document.getElementById('depositAmount').dispatchEvent(new Event('input'));
});

// Withdraw max
document.getElementById('withdrawMax').addEventListener('click', () => {
    document.getElementById('withdrawAmount').value = state.bank;
    document.getElementById('withdrawAmount').dispatchEvent(new Event('input'));
});

// Preview: deposit
document.getElementById('depositAmount').addEventListener('input', e => {
    const v = parseInt(e.target.value) || 0;
    const after = state.bank + v;
    document.getElementById('depositPreview').textContent =
        v > state.cash ? '⚠ Nincs elég készpénz!' :
        v > 0 ? `Bankszámla: ${fmt(state.bank)} → ${fmt(after)}` : '';
});

// Preview: withdraw
document.getElementById('withdrawAmount').addEventListener('input', e => {
    const v = parseInt(e.target.value) || 0;
    const after = state.cash + v;
    document.getElementById('withdrawPreview').textContent =
        v > state.bank ? '⚠ Nincs elég pénz a bankban!' :
        v > 0 ? `Készpénz: ${fmt(state.cash)} → ${fmt(after)}` : '';
});

// Preview: transfer
function updateTransferPreview() {
    const v = parseInt(document.getElementById('transferAmount').value) || 0;
    const after = state.bank - v;
    document.getElementById('transferPreview').textContent =
        v > state.bank ? '⚠ Nincs elég pénz a bankban!' :
        v > 0 ? `Bankszámla: ${fmt(state.bank)} → ${fmt(Math.max(0, after))}` : '';
}
document.getElementById('transferAmount').addEventListener('input', updateTransferPreview);

// Bezárás
document.getElementById('btnClose').addEventListener('click', () => {
    fetch('https://nxn-finance/closeATM', { method: 'POST', body: JSON.stringify({}) });
});

// Deposit
document.getElementById('btnDeposit').addEventListener('click', () => {
    const amount = parseInt(document.getElementById('depositAmount').value) || 0;
    if (amount <= 0) return;
    fetch('https://nxn-finance/deposit', { method: 'POST', body: JSON.stringify({ amount }) });
    document.getElementById('depositAmount').value = '';
    document.getElementById('depositPreview').textContent = '';
});

// Withdraw
document.getElementById('btnWithdraw').addEventListener('click', () => {
    const amount = parseInt(document.getElementById('withdrawAmount').value) || 0;
    if (amount <= 0) return;
    fetch('https://nxn-finance/withdraw', { method: 'POST', body: JSON.stringify({ amount }) });
    document.getElementById('withdrawAmount').value = '';
    document.getElementById('withdrawPreview').textContent = '';
});

// Transfer
document.getElementById('btnTransfer').addEventListener('click', () => {
    const amount   = parseInt(document.getElementById('transferAmount').value) || 0;
    const targetId = parseInt(document.getElementById('transferTarget').value) || 0;
    const reason   = document.getElementById('transferReason').value.trim();
    if (amount <= 0 || targetId <= 0) return;
    fetch('https://nxn-finance/transfer', { method: 'POST', body: JSON.stringify({ amount, targetId, reason }) });
    document.getElementById('transferAmount').value = '';
    document.getElementById('transferTarget').value = '';
    document.getElementById('transferReason').value = '';
    document.getElementById('transferPreview').textContent = '';
});

// NUI üzenetek fogadása
window.addEventListener('message', e => {
    const data = e.data;
    if (!data || !data.action) return;

    if (data.action === 'open') {
        state.cash = data.cash || 0;
        state.bank = data.bank || 0;
        state.open = true;
        updateBalanceUI();
        app.classList.remove('hidden');
        // Alapértelmezett tab
        if (data.defaultTab) {
            const btn = document.querySelector(`.tab-btn[data-tab="${data.defaultTab}"]`);
            if (btn) btn.click();
        }
    }

    if (data.action === 'updateBalance') {
        state.cash = data.cash || 0;
        state.bank = data.bank || 0;
        updateBalanceUI();
    }

    if (data.action === 'close') {
        state.open = false;
        app.classList.add('hidden');
    }
});
