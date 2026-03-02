// nxn-gasstation | app.js

const overlay       = document.getElementById('overlay');
const stationLabel  = document.getElementById('station-label');
const fuelPct       = document.getElementById('fuel-pct');
const fuelBar       = document.getElementById('fuel-bar');
const maxLitersEl   = document.getElementById('max-liters');
const priceEl       = document.getElementById('price-per-liter');
const literInput    = document.getElementById('liter-input');
const totalPriceEl  = document.getElementById('total-price');

let maxLiters     = 0;
let pricePerLiter = 0;

function updateTotal() {
    const v = Math.min(Math.max(parseFloat(literInput.value) || 0, 1), maxLiters);
    literInput.value = Math.floor(v);
    totalPriceEl.textContent = (Math.floor(v) * pricePerLiter).toLocaleString('hu-HU') + ' Ft';
}

function openUI(data) {
    stationLabel.textContent   = data.stationLabel  || 'Benzinkút';
    fuelPct.textContent        = (data.currentFuel  || 0) + '%';
    fuelBar.style.width        = (data.currentFuel  || 0) + '%';
    maxLiters                  = data.maxLiters      || 0;
    pricePerLiter              = data.pricePerLiter  || 0;
    maxLitersEl.textContent    = maxLiters.toFixed(1) + ' L';
    priceEl.textContent        = pricePerLiter + ' Ft';
    literInput.min             = 1;
    literInput.max             = Math.max(1, Math.floor(maxLiters));
    literInput.value           = Math.min(Math.floor(maxLiters), 1);
    updateTotal();
    overlay.classList.remove('hidden');
}

function closeUI() {
    overlay.classList.add('hidden');
}

// Stepper
document.getElementById('btn-minus').addEventListener('click', () => {
    const v = parseInt(literInput.value) - 1;
    literInput.value = Math.max(1, v);
    updateTotal();
});
document.getElementById('btn-plus').addEventListener('click', () => {
    const v = parseInt(literInput.value) + 1;
    literInput.value = Math.min(Math.floor(maxLiters), v);
    updateTotal();
});
literInput.addEventListener('input', updateTotal);

// Tele szint
document.getElementById('btn-fill').addEventListener('click', () => {
    literInput.value = Math.floor(maxLiters);
    updateTotal();
});

// Confirm
document.getElementById('btn-confirm').addEventListener('click', () => {
    const liters = parseInt(literInput.value) || 0;
    fetch(`https://${GetParentResourceName()}/confirm`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ liters })
    });
    closeUI();
});

// Cancel
function doCancel() {
    fetch(`https://${GetParentResourceName()}/cancel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    closeUI();
}
document.getElementById('btn-close').addEventListener('click', doCancel);
document.getElementById('btn-cancel').addEventListener('click', doCancel);

// Escape
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') doCancel();
});

// Message handler
window.addEventListener('message', (e) => {
    const d = e.data;
    if (d.action === 'open')  openUI(d.data || {});
    if (d.action === 'close') closeUI();
});
