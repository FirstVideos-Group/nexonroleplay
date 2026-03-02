// ── NUI Bridge ───────────────────────────────────────────────
const sendNui = (event, data = {}) =>
    fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });

// ── State ────────────────────────────────────────────────────
let state = {
    dealer: null,
    vehicles: [],
    filteredVehicles: [],
    activeCategory: 'all',
    sortMode: 'price_asc',
    maxPrice: 5000000,
    selectedVehicle: null,
    financingAvailable: false,
    financing: { InterestRate: 0.05, MinMonths: 3, MaxMonths: 60, DefaultMonths: 12 },
    financeMonths: 12,
    balance: { bank: 0, cash: 0 },
    pendingPurchase: null,
};

// ── DOM refs ─────────────────────────────────────────────────
const shopPanel     = document.getElementById('shop-panel');
const shopTitle     = document.getElementById('shop-title');
const vehicleGrid   = document.getElementById('vehicle-grid');
const filterCats    = document.getElementById('filter-cats');
const sortSelect    = document.getElementById('sort-select');
const priceRange    = document.getElementById('price-range');
const priceVal      = document.getElementById('price-val');
const balanceDisplay = document.getElementById('balance-display');
const confirmModal  = document.getElementById('confirm-modal');
const confirmBody   = document.getElementById('confirm-body');
const confirmOk     = document.getElementById('confirm-ok');
const confirmCancel = document.getElementById('confirm-cancel');
const btnClose      = document.getElementById('btn-close');
const tabFinance    = document.getElementById('tab-finance');
const tdOverlay     = document.getElementById('testdrive-overlay');
const tdTimer       = document.getElementById('td-timer');
const tdStop        = document.getElementById('td-stop');

// ── Tab switching ────────────────────────────────────────────
function switchTab(tabId) {
    document.querySelectorAll('.shop-tab').forEach(t => t.classList.toggle('active', t.dataset.tab === tabId));
    document.querySelectorAll('.shop-tab-content').forEach(c => {
        c.classList.toggle('active', c.id === 'tab-content-' + tabId);
    });
    if (tabId === 'finance') renderFinance();
}
document.querySelectorAll('.shop-tab').forEach(t => t.addEventListener('click', () => switchTab(t.dataset.tab)));

// ── Filter & sort ─────────────────────────────────────────────
function applyFilters() {
    let list = [...state.vehicles];
    if (state.activeCategory !== 'all') {
        list = list.filter(v => v.category === state.activeCategory);
    }
    list = list.filter(v => v.price <= state.maxPrice);
    if (state.sortMode === 'price_asc')  list.sort((a, b) => a.price - b.price);
    if (state.sortMode === 'price_desc') list.sort((a, b) => b.price - a.price);
    if (state.sortMode === 'name')       list.sort((a, b) => a.label.localeCompare(b.label));
    if (state.sortMode === 'hp')         list.sort((a, b) => b.hp - a.hp);
    state.filteredVehicles = list;
    renderGrid();
}

function buildCategoryFilters() {
    const cats = new Set(['all']);
    state.vehicles.forEach(v => cats.add(v.category));
    filterCats.innerHTML = '';
    cats.forEach(cat => {
        const btn = document.createElement('button');
        btn.className = 'cat-btn' + (cat === state.activeCategory ? ' active' : '');
        btn.textContent = cat === 'all' ? 'Összes' : cat;
        btn.addEventListener('click', () => {
            state.activeCategory = cat;
            document.querySelectorAll('.cat-btn').forEach(b => b.classList.toggle('active', b.textContent === btn.textContent));
            applyFilters();
        });
        filterCats.appendChild(btn);
    });
}

sortSelect.addEventListener('change', () => { state.sortMode = sortSelect.value; applyFilters(); });
priceRange.addEventListener('input', () => {
    state.maxPrice = parseInt(priceRange.value);
    priceVal.textContent = state.maxPrice >= 5000000 ? '$∞' : '$' + state.maxPrice.toLocaleString();
    applyFilters();
});

// ── Render grid ──────────────────────────────────────────────
function renderGrid() {
    vehicleGrid.innerHTML = '';
    if (state.filteredVehicles.length === 0) {
        vehicleGrid.innerHTML = '<p style="color:var(--nxn-muted);text-align:center;padding:40px 0;grid-column:1/-1">Nincs találat a szűrők alapján.</p>';
        return;
    }
    state.filteredVehicles.forEach(v => {
        const card = document.createElement('div');
        card.className = 'vehicle-card';
        card.innerHTML = `
            <div class="vehicle-card__name">${v.label}</div>
            <div class="vehicle-card__price">$${v.price.toLocaleString()}</div>
            <div class="vehicle-card__badges">
                <span class="badge cat"><i class="hgi hgi-stroke hgi-car-01"></i>${v.category}</span>
                <span class="badge hp"><i class="hgi hgi-stroke hgi-fire"></i>${v.hp} HP</span>
                <span class="badge spd"><i class="hgi hgi-stroke hgi-speedometer"></i>${v.maxSpeed} km/h</span>
            </div>
            <div class="vehicle-card__actions">
                <button class="nxn-btn nxn-btn--outline nxn-btn--sm btn-detail" data-model="${v.model}"><i class="hgi hgi-stroke hgi-information-circle"></i> Részletek</button>
                <button class="nxn-btn nxn-btn--sm btn-buy" data-model="${v.model}"><i class="hgi hgi-stroke hgi-shopping-bag-01"></i> Vásárlás</button>
            </div>
        `;
        card.querySelector('.btn-detail').addEventListener('click', () => showDetail(v));
        card.querySelector('.btn-buy').addEventListener('click', () => openConfirm(v, false));
        vehicleGrid.appendChild(card);
    });
}

// ── Detail view ───────────────────────────────────────────────
function showDetail(v) {
    state.selectedVehicle = v;
    const container = document.getElementById('vehicle-detail');
    const testDriveBtn = state.dealer && state.dealer.testDrive
        ? `<button class="nxn-btn nxn-btn--outline btn-testdrive" data-model="${v.model}"><i class="hgi hgi-stroke hgi-steering"></i> Teszt-menet</button>`
        : '';
    container.innerHTML = `
        <div class="detail-header">
            <div>
                <div class="detail-name">${v.label}</div>
                <div style="color:var(--nxn-muted);font-size:13px;margin-top:4px">${v.category} · #${v.model}</div>
            </div>
            <div class="detail-price">$${v.price.toLocaleString()}</div>
        </div>
        <div class="detail-stats">
            <div class="stat-box"><div class="stat-val">${v.hp}</div><div class="stat-lbl">HP</div></div>
            <div class="stat-box"><div class="stat-val">${v.maxSpeed}</div><div class="stat-lbl">Max km/h</div></div>
            <div class="stat-box"><div class="stat-val">${v.weight ?? '—'}</div><div class="stat-lbl">Tömeg (kg)</div></div>
        </div>
        <div class="detail-actions">
            ${testDriveBtn}
            <button class="nxn-btn btn-buy-detail" data-model="${v.model}">
                <i class="hgi hgi-stroke hgi-shopping-bag-01"></i> Megveszem
            </button>
        </div>
    `;
    container.querySelector('.btn-buy-detail')?.addEventListener('click', () => openConfirm(v, false));
    container.querySelector('.btn-testdrive')?.addEventListener('click', () => {
        sendNui('testDrive', { model: v.model });
    });

    // Tab megnyitás
    document.getElementById('tab-detail').style.display = '';
    switchTab('detail');
}

// ── Finance render ────────────────────────────────────────────
function renderFinance() {
    const fp = document.getElementById('finance-panel');
    if (!state.financingAvailable) {
        fp.innerHTML = '<p class="finance-hint">A finanszírozás jelenleg nem elérhető.</p>';
        return;
    }
    const v = state.selectedVehicle;
    if (!v) {
        fp.innerHTML = '<p class="finance-hint">Válassz járművet a böngészés fülön!</p>';
        return;
    }
    const fin = state.financing;
    const months = state.financeMonths;
    const total   = Math.floor(v.price * (1 + fin.InterestRate * (months / 12)));
    const monthly = Math.ceil(total / months);
    const interest = total - v.price;

    fp.innerHTML = `
        <div class="finance-vehicle-info">
            <div>
                <div style="font-weight:700">${v.label}</div>
                <div style="color:var(--nxn-muted);font-size:12px">${v.category}</div>
            </div>
            <div style="color:var(--nxn-success);font-weight:700;font-size:18px">$${v.price.toLocaleString()}</div>
        </div>
        <div class="finance-calc">
            <div class="finance-row">
                <span class="lbl">Futamidő</span>
                <span class="val">${months} hónap</span>
            </div>
            <input type="range" class="months-slider" min="${fin.MinMonths}" max="${fin.MaxMonths}" step="1" value="${months}" id="months-slider"/>
            <div class="finance-row">
                <span class="lbl">Kamatláb</span>
                <span class="val">${(fin.InterestRate * 100).toFixed(1)}%</span>
            </div>
            <div class="finance-row">
                <span class="lbl">Kamat összege</span>
                <span class="val">$${interest.toLocaleString()}</span>
            </div>
            <div class="finance-row">
                <span class="lbl">Teljes összeg</span>
                <span class="val">$${total.toLocaleString()}</span>
            </div>
            <div class="finance-row">
                <span class="lbl">Havi részlet</span>
                <span class="val highlight">$${monthly.toLocaleString()}</span>
            </div>
            <button class="nxn-btn" id="finance-buy-btn">
                <i class="hgi hgi-stroke hgi-credit-card"></i> Részletfizetés indítása
            </button>
        </div>
    `;
    document.getElementById('months-slider').addEventListener('input', e => {
        state.financeMonths = parseInt(e.target.value);
        renderFinance();
    });
    document.getElementById('finance-buy-btn').addEventListener('click', () => openConfirm(v, true));
}

// ── Confirm modal ─────────────────────────────────────────────
function openConfirm(v, useFinancing) {
    state.pendingPurchase = { v, useFinancing };
    const fin    = state.financing;
    const months = state.financeMonths;
    const total  = Math.floor(v.price * (1 + fin.InterestRate * (months / 12)));
    const monthly = Math.ceil(total / months);
    const afterBalance = state.balance.bank - (useFinancing ? monthly : v.price);

    confirmBody.innerHTML = `
        <div class="confirm-row"><span class="lbl">Jármű</span><span class="val">${v.label}</span></div>
        <div class="confirm-row"><span class="lbl">Ár</span><span class="val">$${v.price.toLocaleString()}</span></div>
        ${ useFinancing ? `
        <div class="confirm-row"><span class="lbl">Fizetési mód</span><span class="val">Részletfizetés (${months} hó)</span></div>
        <div class="confirm-row"><span class="lbl">1. részlet</span><span class="val">$${monthly.toLocaleString()}</span></div>
        <div class="confirm-row"><span class="lbl">Teljes összeg</span><span class="val">$${total.toLocaleString()}</span></div>
        ` : `<div class="confirm-row"><span class="lbl">Fizetési mód</span><span class="val">Egyszeri</span></div>` }
        <div class="confirm-row"><span class="lbl">Egyenleg ezután</span><span class="val ${afterBalance >= 0 ? 'green' : 'red'}">$${afterBalance.toLocaleString()}</span></div>
    `;
    confirmModal.classList.remove('hidden');
}

confirmOk.addEventListener('click', () => {
    if (!state.pendingPurchase) return;
    const { v, useFinancing } = state.pendingPurchase;
    sendNui('buy', {
        model:        v.model,
        useFinancing: useFinancing,
        months:       state.financeMonths,
    });
    confirmModal.classList.add('hidden');
    state.pendingPurchase = null;
});
confirmCancel.addEventListener('click', () => {
    confirmModal.classList.add('hidden');
    state.pendingPurchase = null;
});

// ── Close ─────────────────────────────────────────────────────
btnClose.addEventListener('click', () => {
    shopPanel.classList.add('hidden');
    sendNui('close');
});
window.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        shopPanel.classList.add('hidden');
        sendNui('close');
    }
});

// ── Teszt-menet ───────────────────────────────────────────────
tdStop.addEventListener('click', () => {
    sendNui('testDriveStop', {});
    tdOverlay.classList.add('hidden');
});

function formatTime(sec) {
    return Math.floor(sec / 60) + ':' + String(sec % 60).padStart(2, '0');
}

// ── Server balance request ────────────────────────────────────
// A szerver a 'nxn-vehicleshop:client:balanceUpdate' eventre válaszol

// ── NUI message handler ───────────────────────────────────────
window.addEventListener('message', ({ data }) => {
    if (!data?.action) return;
    switch (data.action) {
        case 'openShop':
            state.dealer             = data.dealer;
            state.vehicles           = data.vehicles || [];
            state.financingAvailable = !!data.financingAvailable;
            state.financing          = data.financing || state.financing;
            state.financeMonths      = state.financing.DefaultMonths || 12;
            state.activeCategory     = 'all';
            state.selectedVehicle    = null;
            shopTitle.textContent    = data.dealer?.label || 'Járműkereskedés';
            tabFinance.style.display = state.financingAvailable ? '' : 'none';
            buildCategoryFilters();
            applyFilters();
            switchTab('browse');
            document.getElementById('tab-detail').style.display = 'none';
            shopPanel.classList.remove('hidden');
            sendNui('getBalance', {});
            break;

        case 'setVisible':
            shopPanel.classList.toggle('hidden', !data.visible);
            if (!data.visible) confirmModal.classList.add('hidden');
            break;

        case 'balanceUpdate':
            state.balance = { bank: data.bank || 0, cash: data.cash || 0 };
            balanceDisplay.textContent = '$' + state.balance.bank.toLocaleString();
            break;

        case 'purchaseSuccess':
            shopPanel.classList.add('hidden');
            confirmModal.classList.add('hidden');
            break;

        case 'testDriveStart':
            tdOverlay.classList.remove('hidden');
            tdTimer.textContent = formatTime(data.duration);
            break;

        case 'testDriveTimer':
            tdTimer.textContent = formatTime(data.remaining);
            if (data.remaining <= 0) tdOverlay.classList.add('hidden');
            break;

        case 'testDriveEnd':
            tdOverlay.classList.add('hidden');
            break;

        case 'notify':
            break;
    }
});
