// ============================================================
//  nxn-notify | app.js
// ============================================================

const container = document.getElementById('notify-container');

// Konfiguracio (NUI message altal felulirható)
let cfg = {
    position:   'top-right',
    maxVisible: 5,
    slideFrom:  null,  // null = auto
};

// Ikonterkep tipusonkent (HugeIcons)
const ICONS = {
    info:    'hgi-information-circle',
    success: 'hgi-checkmark-circle-01',
    danger:  'hgi-alert-01',
    warning: 'hgi-alert-circle',
};

// Cimterkep tipusonkent (ha nincs egyedi cim)
const DEFAULT_TITLES = {
    info:    'Értesítés',
    success: 'Sikeres',
    danger:  'Hiba',
    warning: 'Figyelmeztetés',
};

// ── Pozicio es animacio beallitasa ────────────────────────────

function applyPosition(pos) {
    container.className = '';
    container.classList.add('pos-' + (pos || 'top-right'));
}

function getSlideAnim(pos, slideFrom) {
    if (slideFrom) {
        const map = {
            right:  'nxnSlideIn',
            left:   'nxnSlideInLeft',
            top:    'nxnSlideInTop',
            bottom: 'nxnSlideInBottom',
        };
        return map[slideFrom] || 'nxnSlideIn';
    }
    if (pos && pos.includes('left'))   return 'nxnSlideInLeft';
    if (pos && pos.includes('bottom')) return 'nxnSlideInBottom';
    return 'nxnSlideIn';  // top-right default
}

// ── Notify megjelenites ───────────────────────────────────────

function showNotify(msg, type, duration, title) {
    type     = type     || 'info';
    duration = duration || 4000;

    // Maxlimit: legregebb ertesites eltavolitasa
    const items = container.querySelectorAll('.nxn-notify:not(.removing)');
    if (items.length >= cfg.maxVisible) {
        removeNotify(items[0]);
    }

    const anim     = getSlideAnim(cfg.position, cfg.slideFrom);
    const iconName = ICONS[type] || ICONS.info;
    const titleText = title || DEFAULT_TITLES[type] || 'Értesítés';

    const el = document.createElement('div');
    el.className = `nxn-notify ${type}`;
    el.innerHTML = `
        <i class="hgi hgi-stroke ${iconName} nxn-notify__icon"></i>
        <div class="nxn-notify__body">
            <div class="nxn-notify__title">${escHtml(titleText)}</div>
            <div class="nxn-notify__msg">${escHtml(msg)}</div>
        </div>
        <div class="nxn-notify__progress" style="animation-duration:${duration}ms"></div>
    `;
    el.style.setProperty('--anim-name', anim);
    el.style.animationName = anim;

    container.appendChild(el);

    setTimeout(() => removeNotify(el), duration);
}

function removeNotify(el) {
    if (!el || el.classList.contains('removing')) return;
    el.classList.add('removing');
    setTimeout(() => {
        if (el.parentNode) el.parentNode.removeChild(el);
    }, 220);
}

// ── XSS vedelem ───────────────────────────────────────────────

function escHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

// ── NUI message feldolgozas ───────────────────────────────────

window.addEventListener('message', function(e) {
    const data = e.data;
    if (!data || !data.action) return;

    if (data.action === 'show') {
        showNotify(data.message, data.type, data.duration, data.title);
    }

    if (data.action === 'configure') {
        if (data.position)   { cfg.position   = data.position;   applyPosition(data.position); }
        if (data.maxVisible) { cfg.maxVisible = data.maxVisible; }
        if (data.slideFrom !== undefined) { cfg.slideFrom = data.slideFrom; }
    }
});

// ── Inicializalas ─────────────────────────────────────────────

applyPosition(cfg.position);

// Konfiguracio lekerese a Lua-tol inditaskor
window.addEventListener('load', function() {
    fetch('https://nxn-notify/nui:ready', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(() => {});
});
