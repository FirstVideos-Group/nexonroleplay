'use strict';

// ── Store ───────────────────────────────────────────────────
const signs = {};  // { [id]: { el, category, fadeOutMs } }

// ── DOM helpers ─────────────────────────────────────────────

function getContainer(category) {
    return category === 'large'
        ? document.getElementById('signs-large')
        : document.getElementById('signs-info');
}

function createSignElement(id, svgUrl, label, category, fadeInMs, fadeOutMs) {
    const cls = category === 'large' ? 'sign-large' : 'sign-info';
    const el  = document.createElement('div');
    el.className = cls;
    el.id = 'sign-' + id;
    el.style.setProperty('--fade-in',  fadeInMs  + 'ms');
    el.style.setProperty('--fade-out', fadeOutMs + 'ms');

    const img = document.createElement('img');
    img.src = svgUrl;
    img.alt = label || id;
    el.appendChild(img);

    if (label) {
        const lbl = document.createElement('div');
        lbl.className = 'sign-label';
        lbl.textContent = label;
        el.appendChild(lbl);
    }

    return el;
}

// ── Sign show/hide ───────────────────────────────────────────

function showSign(data) {
    const { id, svgUrl, label, category, fadeIn, fadeOut } = data;

    // Ha mar letezik, kihagyjuk
    if (signs[id]) return;

    const container = getContainer(category);
    const el = createSignElement(id, svgUrl, label, category, fadeIn, fadeOut);
    container.appendChild(el);

    // Kenyszer-reflow a transition-hoz
    void el.offsetWidth;

    el.classList.add('visible');

    signs[id] = { el, category, fadeOut };
}

function hideSign(data) {
    const { id, fadeOut } = data;
    const entry = signs[id];
    if (!entry) return;

    const { el } = entry;
    const ms = fadeOut || entry.fadeOut || 400;

    el.style.setProperty('--fade-out', ms + 'ms');
    el.classList.remove('visible');
    el.classList.add('hiding');

    setTimeout(() => {
        if (el.parentNode) el.parentNode.removeChild(el);
        delete signs[id];
    }, ms + 50);
}

// ── Message handler ──────────────────────────────────────────

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'showSign': showSign(d); break;
        case 'hideSign': hideSign(d); break;
        case 'hideAll':
            Object.keys(signs).forEach(id => hideSign({ id, fadeOut: d.fadeOut || 400 }));
            break;
    }
});
