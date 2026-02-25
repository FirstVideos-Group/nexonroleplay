// ============================================================
//  nxn-seatbelt | app.js
//  NUI hang kezeles: figyelmezteto hang lejatszas / leallitas
// ============================================================

const audio = document.getElementById('seatbelt-warning');

window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;

    if (d.action === 'playWarning') {
        audio.src    = d.file;
        audio.volume = typeof d.volume === 'number' ? d.volume : 0.5;
        audio.loop   = false;
        audio.currentTime = 0;
        audio.play().catch(function() {
            // Autoplay policy: silent fail, a kovetkezo interact utan mukodik
        });
        audio.onended = function() {
            fetch('https://' + GetParentResourceName() + '/soundEnded', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        };
        return;
    }

    if (d.action === 'stopWarning') {
        audio.pause();
        audio.currentTime = 0;
        return;
    }
});
