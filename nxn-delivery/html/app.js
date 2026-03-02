// ── nxn-delivery NUI ─────────────────────────────────────────

const card        = document.getElementById('delivery-card');
const taskIcon    = document.getElementById('task-icon');
const taskCat     = document.getElementById('task-category');
const taskTarget  = document.getElementById('task-target');
const taskReward  = document.getElementById('task-reward');
const taskDist    = document.getElementById('task-distance');
const taskTime    = document.getElementById('task-time');
const progressBar = document.getElementById('task-progress-bar');
const bonusBadge  = document.getElementById('bonus-badge');

let totalTimeLimit = 0;
let countdownInterval = null;
let localTimeLeft = 0;

function padTime(n) { return String(n).padStart(2, '0'); }
function formatTime(s) {
    const m = Math.floor(s / 60);
    return `${padTime(m)}:${padTime(s % 60)}`;
}

function updateProgress(timeLeft) {
    if (totalTimeLimit <= 0) return;
    const pct = Math.max(0, Math.min(100, (timeLeft / totalTimeLimit) * 100));
    progressBar.style.width = pct + '%';

    progressBar.classList.remove('urgent', 'warning');
    taskTime.classList.remove('urgent');
    if (pct <= 20) {
        progressBar.classList.add('urgent');
        taskTime.classList.add('urgent');
    } else if (pct <= 40) {
        progressBar.classList.add('warning');
    }
}

function startLocalCountdown(timeLeft) {
    clearInterval(countdownInterval);
    localTimeLeft = timeLeft;
    countdownInterval = setInterval(() => {
        localTimeLeft = Math.max(0, localTimeLeft - 1);
        taskTime.textContent = formatTime(localTimeLeft);
        updateProgress(localTimeLeft);
        if (localTimeLeft <= 0) clearInterval(countdownInterval);
    }, 1000);
}

window.addEventListener('message', ({ data }) => {
    if (!data?.type) return;

    switch (data.type) {
        case 'show': {
            const d = data.data;
            totalTimeLimit = d.timeLimit;

            // Ikon frissítése
            taskIcon.className = `hgi hgi-stroke ${d.icon}`;

            taskCat.textContent    = d.label;
            taskTarget.textContent = d.target;
            taskReward.textContent = `${d.reward.toLocaleString('hu-HU')} Ft`;
            taskDist.textContent   = d.distanceM > 1000
                ? `${(d.distanceM / 1000).toFixed(1)} km`
                : `${d.distanceM} m`;

            bonusBadge.classList.toggle('hidden', !d.bonus);
            card.classList.remove('hidden');
            startLocalCountdown(d.timeLimit);
            break;
        }
        case 'hide': {
            card.classList.add('hidden');
            clearInterval(countdownInterval);
            break;
        }
        case 'update': {
            const u = data.data;
            // Szerver frissítés szinkronizálja a visszaszámlálót
            startLocalCountdown(u.timeLeft);
            taskDist.textContent = u.distToTarget > 1000
                ? `${(u.distToTarget / 1000).toFixed(1)} km`
                : `${u.distToTarget} m`;
            bonusBadge.classList.toggle('hidden', !u.bonus);
            break;
        }
    }
});
