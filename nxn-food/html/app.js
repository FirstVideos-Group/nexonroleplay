'use strict';

let currentShopId = null;

// ── NUI message handler ──────────────────────────────────────
window.addEventListener('message', (e) => {
    const data = e.data;
    switch (data.action) {
        case 'openShop':  openShop(data.shopId, data.shopData, data.currentMoney); break;
        case 'closeShop': closeShopUI(); break;
        case 'buyResult': handleBuyResult(data.ok, data.newBalance); break;
    }
});

// ── Bolt megnyitása ──────────────────────────────────────────
function openShop(shopId, shopData, currentMoney) {
    currentShopId = shopId;
    document.getElementById('shop-title').textContent  = shopData.label || 'Étterem';
    document.getElementById('shop-balance').textContent = '$' + (currentMoney || 0).toLocaleString('hu-HU');

    const container = document.getElementById('shop-items');
    container.innerHTML = '';

    (shopData.items || []).forEach(item => {
        const card = document.createElement('div');
        card.className = 'food-item';
        card.innerHTML = `
            <span class="food-item__icon"><i class="hgi hgi-stroke ${item.icon || 'hgi-restaurant-01'}"></i></span>
            <div class="food-item__info">
                <div class="food-item__name">${item.label}</div>
                <div class="food-item__effects">
                    ${item.hunger > 0  ? `<span class="positive"><i class="hgi hgi-stroke hgi-bread-01"></i> +${item.hunger}</span>` : ''}
                    ${item.thirst > 0  ? `<span class="positive"><i class="hgi hgi-stroke hgi-water-polo"></i> +${item.thirst}</span>` : ''}
                    ${item.thirst < 0  ? `<span class="negative"><i class="hgi hgi-stroke hgi-water-polo"></i> ${item.thirst}</span>` : ''}
                </div>
            </div>
            <span class="food-item__price">$${(item.price || 0).toLocaleString('hu-HU')}</span>
            <button class="nxn-btn" onclick="buyItem('${item.item}')">
                <i class="hgi hgi-stroke hgi-shopping-cart-01"></i> Vesz
            </button>
        `;
        container.appendChild(card);
    });

    document.getElementById('shop-overlay').classList.remove('hidden');
}

// ── Bezárás ──────────────────────────────────────────────────
function closeShop() {
    fetch(`https://${GetParentResourceName()}/closeShop`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    closeShopUI();
}

function closeShopUI() {
    document.getElementById('shop-overlay').classList.add('hidden');
    currentShopId = null;
}

// ── Vásárlás ─────────────────────────────────────────────────
function buyItem(itemName) {
    if (!currentShopId) return;
    fetch(`https://${GetParentResourceName()}/buyItem`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ shopId: currentShopId, itemName: itemName })
    });
}

function handleBuyResult(ok, newBalance) {
    if (ok && newBalance !== undefined) {
        document.getElementById('shop-balance').textContent = '$' + newBalance.toLocaleString('hu-HU');
    }
}

// ── ESC bezárás ──────────────────────────────────────────────
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeShop();
});
