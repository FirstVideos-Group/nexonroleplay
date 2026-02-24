// ============================================================
//  nxn-seatbelt | app.js
// ============================================================

const hudEl      = document.getElementById('belt-hud');
const iconEl     = document.getElementById('belt-icon');
const labelEl    = document.getElementById('belt-label');
const audioEl    = document.getElementById('belt-audio');
const notifyEl   = document.getElementById('belt-notify-container');

// ── HUD megjelenítés ──────────────────────────────────────

function setHUDState(buckled, inVehicle) {
    if (!inVehicle && inVehicle !== undefined) {
        hudEl.classList.add('hidden');
        return;
    }
    hudEl.classList.remove('hidden');
    hudEl.classList.toggle('buckled',   buckled);
    hudEl.classList.toggle('unbuckled', !buckled);
    labelEl.textContent = buckled ? 'KÖTVE' : 'SZABAD';
}

// ── Hang kezelés ──────────────────────────────────────────

function playSound(src) {
    if (!src) return;
    // Resolve: FiveM resource fájl URL
    const url = `https://cfx-nui-${GetParentResourceName()}/${src}`;
    audioEl.src = url;
    audioEl.loop = true;
    audioEl.volume = 0.6;
    audioEl.play().catch(function(e) {
        console.warn('[nxn-seatbelt] Hang lejátszás hiba:', e);
    });
}

function stopSound() {
    audioEl.pause();
    audioEl.currentTime = 0;
}

// ── Fallback notify ───────────────────────────────────────

const iconMap = {
    info:    'hgi-information-circle',
    success: 'hgi-checkmark-circle-01',
    danger:  'hgi-alert-01',
    warning: 'hgi-alert-circle',
};

function showNotify(message, ntype) {
    const el = document.createElement('div');
    el.className = `nxn-notify ${ntype || ''}`;
    const icon = iconMap[ntype] || iconMap.info;
    el.innerHTML = `<i class="hgi hgi-stroke ${icon}"></i><span>${message}</span>`;
    notifyEl.appendChild(el);
    setTimeout(function() {
        el.style.opacity = '0';
        el.style.transition = 'opacity .3s';
        setTimeout(function() { el.remove(); }, 320);
    }, 3500);
}

// ── NUI message handler ───────────────────────────────────

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'setState':
            setHUDState(d.buckled, d.inVehicle);
            break;
        case 'hudUpdate':
            setHUDState(d.buckled, d.inVehicle);
            break;
        case 'playSound':
            playSound(d.src);
            break;
        case 'stopSound':
            stopSound();
            break;
        case 'notify':
            showNotify(d.message, d.ntype);
            break;
    }
});
