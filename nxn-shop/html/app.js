'use strict';

let state = {
    shopId:      null,
    shopData:    null,
    mode:        'buy',
    balance:     0,
    inventory:   [],
    quantities:  {},  // { [item]: qty }
};

// ── NUI message handler ──────────────────────────────────────
window.addEventListener('message', (e) => {
    const d = e.data;
    switch (d.action) {
        case 'openShop':      onOpenShop(d);      break;
        case 'closeShop':     closeShopUI();      break;
        case 'buyResult':     onBuyResult(d);     break;
        case 'sellResult':    onSellResult(d);    break;
        case 'inventoryData': onInventoryData(d); break;
    }
});

// ── Bolt megnyitás ───────────────────────────────────────────
function onOpenShop(d) {
    state.shopId   = d.shopId;
    state.shopData = d.shopData;
    state.balance  = d.currentMoney || 0;
    state.mode     = d.mode || 'buy';
    state.quantities = {};

    const catIcons = {
        general: 'hgi-store-01', food: 'hgi-restaurant-01',
        medical: 'hgi-medicine-01', weapons: 'hgi-gun-01', clothing: 'hgi-t-shirt-01'
    };
    document.getElementById('shop-title').textContent = d.shopData.label || 'Bolt';
    document.getElementById('shop-cat-icon').className = 'hgi hgi-stroke ' + (catIcons[d.shopData.category] || 'hgi-store-01');
    document.getElementById('balance-label').textContent = '$' + state.balance.toLocaleString('hu-HU');
    document.getElementById('weight-label').textContent = '–';

    const sellBtn = document.getElementById('sell-tab-btn');
    sellBtn.style.display = d.shopData.canSell ? '' : 'none';

    renderBuyItems(d.shopData.items);
    updateCart();

    if (state.mode === 'sell') {
        switchTab('sell');
        nuiFetch('requestInventory', {});
    } else {
        switchTab('buy');
    }

    document.getElementById('shop-overlay').classList.remove('hidden');
}

// ── Render buy items ─────────────────────────────────────────
function renderBuyItems(items) {
    const container = document.getElementById('shop-items');
    container.innerHTML = '';
    (items || []).forEach((item, idx) => {
        state.quantities[item.item] = 1;
        const div = document.createElement('div');
        div.className = 'shop-item';
        div.style.animationDelay = (idx * 0.04) + 's';
        const stockBadge = (item.stock !== null && item.stock !== undefined)
            ? `<span class="badge-stock">Készlet: ${item.stock}</span>` : '';
        const maxQty = item.stock !== null && item.stock !== undefined ? item.stock : 99;
        div.innerHTML = `
            <span class="shop-item__icon"><i class="hgi hgi-stroke ${item.icon || 'hgi-store-01'}"></i></span>
            <div class="shop-item__info">
                <div class="shop-item__name">${item.label}</div>
                <div class="shop-item__meta">
                    <span class="price">$${(item.price||0).toLocaleString('hu-HU')}/db</span>
                    <span>${item.weight ? item.weight + ' kg' : ''}</span>
                    ${stockBadge}
                </div>
            </div>
            <div class="qty-ctrl">
                <button onclick="changeQty('${item.item}', -1, ${maxQty})">−</button>
                <input type="number" id="qty-${item.item}" value="1" min="1" max="${maxQty}"
                    onchange="setQty('${item.item}', this.value, ${maxQty})"/>
                <button onclick="changeQty('${item.item}', 1, ${maxQty})">+</button>
            </div>
            <button class="nxn-btn" onclick="doBuy('${item.item}', ${item.price})">
                <i class="hgi hgi-stroke hgi-shopping-cart-01"></i> Vesz
            </button>
        `;
        container.appendChild(div);
    });
}

// ── Render sell items ────────────────────────────────────────
function onInventoryData(d) {
    state.inventory = d.items || [];
    const container = document.getElementById('sell-items');
    container.innerHTML = '';

    const shopItems = {};
    (state.shopData.items || []).forEach(i => { shopItems[i.item] = i; });
    const multiplier = state.shopData.sellPriceMultiplier || 0.4;

    const sellable = state.inventory.filter(i => shopItems[i.item]);
    if (sellable.length === 0) {
        container.innerHTML = '<p style="color:var(--nxn-muted);font-size:13px;padding:8px 0">Nincs eladható tárgyad ebben a boltban.</p>';
        return;
    }

    sellable.forEach((invItem, idx) => {
        const shopEntry = shopItems[invItem.item];
        const sellPrice = Math.floor(shopEntry.price * multiplier);
        state.quantities['sell_' + invItem.item] = 1;
        const div = document.createElement('div');
        div.className = 'shop-item';
        div.style.animationDelay = (idx * 0.04) + 's';
        div.innerHTML = `
            <span class="shop-item__icon"><i class="hgi hgi-stroke ${invItem.icon || 'hgi-store-01'}"></i></span>
            <div class="shop-item__info">
                <div class="shop-item__name">${invItem.label}</div>
                <div class="shop-item__meta">
                    <span class="price">+$${sellPrice.toLocaleString('hu-HU')}/db</span>
                    <span>Nálad: ${invItem.count}</span>
                </div>
            </div>
            <div class="qty-ctrl">
                <button onclick="changeQty('sell_${invItem.item}', -1, ${invItem.count})">−</button>
                <input type="number" id="qty-sell_${invItem.item}" value="1" min="1" max="${invItem.count}"
                    onchange="setQty('sell_${invItem.item}', this.value, ${invItem.count})"/>
                <button onclick="changeQty('sell_${invItem.item}', 1, ${invItem.count})">+</button>
            </div>
            <button class="nxn-btn sell-btn" onclick="doSell('${invItem.item}', ${sellPrice})">
                <i class="hgi hgi-stroke hgi-money-send-02"></i> Elad
            </button>
        `;
        container.appendChild(div);
    });
}

// ── Qty control ──────────────────────────────────────────────
function changeQty(key, delta, max) {
    const current = state.quantities[key] || 1;
    const next = Math.max(1, Math.min(max, current + delta));
    state.quantities[key] = next;
    const input = document.getElementById('qty-' + key);
    if (input) input.value = next;
    updateCart();
}

function setQty(key, val, max) {
    const n = Math.max(1, Math.min(max, parseInt(val) || 1));
    state.quantities[key] = n;
    const input = document.getElementById('qty-' + key);
    if (input) input.value = n;
    updateCart();
}

// ── Cart update ──────────────────────────────────────────────
function updateCart() {
    if (!state.shopData) return;
    let total = 0;
    if (state.mode === 'buy') {
        (state.shopData.items || []).forEach(item => {
            const qty = state.quantities[item.item] || 1;
            total += item.price * qty;
        });
    }
    const after = state.balance - total;
    document.getElementById('cart-total').textContent = '$' + total.toLocaleString('hu-HU');
    const afterEl = document.getElementById('cart-balance-after');
    afterEl.textContent = '$' + after.toLocaleString('hu-HU');
    afterEl.classList.toggle('negative', after < 0);
}

// ── Buy / Sell akciók ────────────────────────────────────────
function doBuy(itemName, pricePerUnit) {
    if (!state.shopId) return;
    const qty = state.quantities[itemName] || 1;
    nuiFetch('buy', { shopId: state.shopId, itemName, amount: qty });
}

function doSell(itemName, sellPricePerUnit) {
    if (!state.shopId) return;
    const qty = state.quantities['sell_' + itemName] || 1;
    nuiFetch('sell', { shopId: state.shopId, itemName, amount: qty });
}

// ── Result kezelés ───────────────────────────────────────────
function onBuyResult(d) {
    if (d.ok && d.newBalance !== undefined) {
        state.balance = d.newBalance;
        document.getElementById('balance-label').textContent = '$' + state.balance.toLocaleString('hu-HU');
        updateCart();
    }
}

function onSellResult(d) {
    if (d.ok && d.newBalance !== undefined) {
        state.balance = d.newBalance;
        document.getElementById('balance-label').textContent = '$' + state.balance.toLocaleString('hu-HU');
        nuiFetch('requestInventory', {});
    }
}

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(tab) {
    state.mode = tab;
    document.querySelectorAll('.shop-tab').forEach(b => b.classList.toggle('active', b.dataset.tab === tab));
    document.getElementById('buy-panel').classList.toggle('hidden', tab !== 'buy');
    document.getElementById('sell-panel').classList.toggle('hidden', tab !== 'sell');
    document.getElementById('shop-cart').style.display = tab === 'buy' ? '' : 'none';
    if (tab === 'sell') nuiFetch('requestInventory', {});
}

document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('close-btn').addEventListener('click', closeShop);
    document.querySelectorAll('.shop-tab').forEach(btn => {
        btn.addEventListener('click', () => switchTab(btn.dataset.tab));
    });
});

// ── Bezárás ──────────────────────────────────────────────────
function closeShop() {
    nuiFetch('closeShop', {});
    closeShopUI();
}

function closeShopUI() {
    document.getElementById('shop-overlay').classList.add('hidden');
    state.shopId = null;
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeShop();
});

// ── NUI fetch helper ─────────────────────────────────────────
function nuiFetch(endpoint, data) {
    fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}
