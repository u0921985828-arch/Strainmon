/* ============================================================
   STRAINMON — audio.js
   Motor de sonido chiptune inspirado en la APU de la Game Boy:
   canales de PULSO (onda cuadrada con duty), ONDA (periódica) y
   RUIDO. SFX + bucle de música. Web Audio, sin dependencias.
   Se inicializa en el primer gesto del usuario (política autoplay).
   ============================================================ */
(function (PH) {
  'use strict';
  let ctx = null, master = null, muted = false;
  let musicOn = false, musicTimer = null, step = 0, noiseBuf = null;

  function ensure() {
    if (ctx) { if (ctx.state === 'suspended') ctx.resume(); return ctx; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    try { ctx = new AC(); } catch (e) { return null; }
    master = ctx.createGain(); master.gain.value = muted ? 0 : 0.5; master.connect(ctx.destination);
    return ctx;
  }
  const t = () => (ctx ? ctx.currentTime : 0);

  // Voz de pulso/onda con envolvente rápida (chip).
  function tone(freq, dur, o) {
    o = o || {}; if (!ensure()) return;
    const osc = ctx.createOscillator(), g = ctx.createGain();
    osc.type = o.type || 'square';
    osc.frequency.setValueAtTime(freq, t());
    if (o.slideTo) osc.frequency.exponentialRampToValueAtTime(Math.max(1, o.slideTo), t() + dur);
    const vol = o.vol != null ? o.vol : 0.25, atk = o.attack || 0.004;
    g.gain.setValueAtTime(0.0001, t());
    g.gain.linearRampToValueAtTime(vol, t() + atk);
    g.gain.exponentialRampToValueAtTime(0.0008, t() + dur);
    osc.connect(g); g.connect(master); osc.start(); osc.stop(t() + dur + 0.03);
  }
  // Canal de ruido (percusión / efectos).
  function noise(dur, o) {
    o = o || {}; if (!ensure()) return;
    if (!noiseBuf) { noiseBuf = ctx.createBuffer(1, (ctx.sampleRate * 0.5) | 0, ctx.sampleRate); const d = noiseBuf.getChannelData(0); for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1; }
    const s = ctx.createBufferSource(); s.buffer = noiseBuf;
    const f = ctx.createBiquadFilter(); f.type = 'highpass'; f.frequency.value = o.hp || 1600;
    const g = ctx.createGain(); const vol = o.vol != null ? o.vol : 0.2;
    g.gain.setValueAtTime(vol, t()); g.gain.exponentialRampToValueAtTime(0.001, t() + dur);
    s.connect(f); f.connect(g); g.connect(master); s.start(); s.stop(t() + dur + 0.03);
  }

  const SFX = {
    step: () => tone(200, 0.045, { vol: 0.05 }),
    confirm: () => { tone(660, 0.06, { vol: 0.22 }); tone(990, 0.09, { vol: 0.16 }); },
    cancel: () => tone(320, 0.10, { vol: 0.2, slideTo: 170 }),
    open: () => { tone(520, 0.05, { vol: 0.18 }); tone(760, 0.08, { vol: 0.14 }); },
    warp: () => tone(360, 0.20, { vol: 0.2, slideTo: 900 }),
    blip: () => tone(880, 0.05, { vol: 0.18 }),
    cash: () => { tone(784, 0.06, { vol: 0.2 }); tone(1046, 0.08, { vol: 0.2 }); tone(1318, 0.13, { vol: 0.16 }); },
    harvest: () => { tone(523, 0.08, { vol: 0.2 }); tone(659, 0.08, { vol: 0.2 }); tone(784, 0.16, { vol: 0.18 }); },
    encounter: () => { tone(300, 0.09, { vol: 0.22, slideTo: 620 }); noise(0.10, { vol: 0.1 }); },
    error: () => tone(150, 0.12, { vol: 0.2 }),
  };
  function sfx(k) { if (muted) return; const f = SFX[k]; if (f) f(); }

  // --- Música: bucle pentatónico simple (lead pulso + bajo onda + hats ruido) ---
  const SCALE = [0, 3, 5, 7, 10];
  const LEAD = [0, 3, 5, 7, 5, 3, 7, 10, 7, 5, 3, 0, 3, 5, 7, 3];
  const BASS = [110, 110, 146.83, 130.81];
  function tick() {
    if (!ctx || muted || !musicOn) { step++; return; }
    const s = step % 16;
    if (s % 4 === 0) tone(BASS[(step / 4 | 0) % BASS.length], 0.26, { type: 'triangle', vol: 0.12 });
    if (s % 2 === 0) { const semi = LEAD[s % LEAD.length]; tone(261.63 * Math.pow(2, semi / 12), 0.14, { vol: 0.08 }); }
    if (s % 4 === 2) noise(0.03, { vol: 0.045, hp: 4000 });
    step++;
  }
  function musicStart() { musicOn = true; ensure(); if (!musicTimer) musicTimer = setInterval(tick, 175); }
  function musicStop() { musicOn = false; if (musicTimer) { clearInterval(musicTimer); musicTimer = null; } }

  function setMuted(m) { muted = m; if (master) master.gain.value = m ? 0 : 0.5; }
  function toggleMute() { setMuted(!muted); return muted; }
  function isMuted() { return muted; }

  PH.audio = { ensure, sfx, tone, noise, musicStart, musicStop, setMuted, toggleMute, isMuted };
})(window.PH = window.PH || {});
