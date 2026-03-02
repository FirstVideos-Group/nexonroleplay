// ============================================================
//  nxn-npcconversation | app.js
// ============================================================

const overlay      = document.getElementById('npc-overlay');
const npcNameEl    = document.getElementById('npc-name');
const npcIconEl    = document.getElementById('npc-icon');
const optionsEl    = document.getElementById('npc-options');
const responseWrap = document.getElementById('npc-response-wrap');
const responseEl   = document.getElementById('npc-response');
const interactHint = document.getElementById('nxn-interact-hint');
const hintKeyEl    = document.getElementById('hint-key');
const hintLabelEl  = document.getElementById('hint-label');

let currentNpcId   = null;
let currentOptions = [];

// ── Interact hint ──────────────────────────────────────────────────

function showHint(data) {
    hintKeyEl.textContent   = data.key   || 'E';
    hintLabelEl.textContent = data.label || 'NPC';
    // Animáció újraindítása
    interactHint.classList.remove('hidden');
    interactHint.style.animation = 'none';
    void interactHint.offsetWidth;
    interactHint.style.animation = 'hintSlideUp .2s ease forwards';
}

function hideHint() {
    interactHint.classList.add('hidden');
}

// ── Megnyitás ──────────────────────────────────────────────────

function openUI(data) {
    currentNpcId   = data.npcId;
    currentOptions = data.dialogues || [];

    npcNameEl.textContent = data.npcLabel || 'NPC';
    responseWrap.style.display = 'none';
    responseEl.textContent     = '';

    hideHint();
    renderOptions(currentOptions);
    overlay.classList.remove('hidden');
}

// ── Bezárás ──────────────────────────────────────────────────

function closeUI() {
    overlay.classList.add('hidden');
    currentNpcId   = null;
    currentOptions = [];
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// ESC billentyű
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeUI();
});

// ── Opciók renderelése ──────────────────────────────────────────

function renderOptions(dialogues) {
    optionsEl.innerHTML = '';

    if (!dialogues || dialogues.length === 0) {
        const empty = document.createElement('div');
        empty.style.cssText = 'text-align:center;padding:16px;font-size:13px;color:var(--nxn-muted)';
        empty.textContent = 'Nincs elérhető opció.';
        optionsEl.appendChild(empty);
        return;
    }

    dialogues.forEach(function(opt) {
        const btn = document.createElement('button');
        btn.className = 'npc-opt-btn';

        const iconClass = opt.icon || 'hgi-message-01';
        const hasEvent  = opt.event && opt.event !== '';

        btn.innerHTML = `
            <i class="hgi hgi-stroke ${iconClass} npc-opt-icon"></i>
            <span class="npc-opt-label">${escapeHtml(opt.label || '')}</span>
            ${hasEvent ? '<span class="npc-opt-badge">AKTÍV</span>' : ''}
            <i class="hgi hgi-stroke hgi-arrow-right-01 npc-opt-arrow"></i>
        `;

        btn.addEventListener('click', function() {
            selectOption(opt);
        });

        optionsEl.appendChild(btn);
    });
}

// ── Opció kiválasztása ──────────────────────────────────────────

function selectOption(opt) {
    fetch(`https://${GetParentResourceName()}/selectOption`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            npcId:    currentNpcId,
            optionId: opt.id,
            response: opt.response || '',
            event:    opt.event || '',
        })
    });
}

// ── NPC válasz megjelenítés ────────────────────────────────────

function showResponse(text) {
    if (!text || text === '') {
        responseWrap.style.display = 'none';
        return;
    }
    responseEl.textContent = text;
    responseWrap.style.display = '';
    responseWrap.style.animation = 'none';
    void responseWrap.offsetWidth;
    responseWrap.style.animation = 'npcFadeIn .2s ease forwards';
}

// ── Opciók frissítése (addDialogue export utan) ────────────────

function updateDialogues(dialogues) {
    currentOptions = dialogues || [];
    renderOptions(currentOptions);
}

// ── Segéd: HTML escape ───────────────────────────────────────────

function escapeHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

// ── NUI message feldolgozás ──────────────────────────────────

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;
    switch (d.action) {
        case 'open':            openUI(d);                   break;
        case 'close':           closeUI();                   break;
        case 'showResponse':    showResponse(d.response);    break;
        case 'updateDialogues': updateDialogues(d.dialogues); break;
        case 'showHint':        showHint(d);                 break;
        case 'hideHint':        hideHint();                  break;
    }
});
