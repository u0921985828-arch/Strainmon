#!/usr/bin/env node
/*
  Landrace Hunters — la música de la app de Godot (1.30)
    node tools/musica.js [clave …] [--salida dir] [--wav] [--forzar]
  Sintetiza las canciones de tools/musica/temas.js (partituras propias: notas, acordes, forma y estilo) con instrumentos
  hechos aquí (pulsos y cuadradas con BLEP, flauta, piano eléctrico FM, guitarra y bajo de cuerda pulsada, acordeón, órgano,
  pads y cuerdas de sierras desafinadas, metales, campana, marimba) y una batería sintetizada (bombo, caja, palmas, aro,
  charles, pandero, timbales, platos, escobillas y chatarra), con reverb (Freeverb) y eco estéreo, compresión del bombo
  (sidechain) en lo electrónico, polvo de vinilo en el lo-fi y un limitador. Cada canción sale en OGG Vorbis estéreo a
  godot/musica/<clave>.ogg, con la intro una vez y el resto en bucle sin cortes (`bucle`, en segundos, en indice.json), y las
  de la calle con su versión de noche (<clave>_n; la de Ribera, `night`). Todo con semilla fija: el mismo archivo cada vez.
  No va al repositorio: lo genera `npm run musica` y, si falta o cambió algo, `npm run godot:apk` antes de exportar.
*/
'use strict';
const fs = require('fs'), path = require('path'), crypto = require('crypto'), { spawnSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const { TEMAS } = require('./musica/temas.js');
const SR = 44100, TAU = Math.PI * 2, AVISOS = [];

// ---------- utilidades ----------
function azar(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const hz = n => 440 * Math.pow(2, (n - 69) / 12);
const PC = { c: 0, d: 2, e: 4, f: 5, g: 7, a: 9, b: 11 };
const alt = x => x === '#' ? 1 : x === 'b' ? -1 : 0;
function midi(s) { const m = /^([a-g])([#b]?)(\d)$/.exec(s); if (!m) throw Error('nota ' + s); return 12 * (+m[3] + 1) + PC[m[1]] + alt(m[2]); }
const toks = s => (s || '').split(/\s+/).filter(x => x && x !== '|');
const ACORDES = { '': [0, 4, 7], m: [0, 3, 7], 7: [0, 4, 7, 10], maj7: [0, 4, 7, 11], m7: [0, 3, 7, 10], m9: [0, 3, 7, 10, 14], maj9: [0, 4, 7, 11, 14],
  9: [0, 4, 7, 10, 14], sus4: [0, 5, 7], sus2: [0, 2, 7], dim: [0, 3, 6], dim7: [0, 3, 6, 9], aug: [0, 4, 8], add9: [0, 4, 7, 14], 6: [0, 4, 7, 9], m6: [0, 3, 7, 9], m7b5: [0, 3, 6, 10], '7b9': [0, 4, 7, 10, 13] };
// «Am7», «F#m», «C/E», «Bb:2» (en negras; sin «:», un compás)
function acorde(t) {
  const m = /^([A-G])([#b]?)(maj9|maj7|m7b5|m9|m7|m6|7b9|dim7|dim|aug|sus4|sus2|add9|m|7|9|6)?(?:\/([A-G])([#b]?))?(?::(\d+(?:\.\d+)?))?$/.exec(t);
  if (!m) throw Error('acorde ' + t);
  const r = (PC[m[1].toLowerCase()] + alt(m[2]) + 12) % 12, iv = ACORDES[m[3] || ''];
  return { r, iv, b: m[4] ? (PC[m[4].toLowerCase()] + alt(m[5]) + 12) % 12 : r, negras: m[6] ? +m[6] : 0 };
}

// ---------- osciladores y filtros ----------
function blep(t, dt) { if (t < dt) { t /= dt; return t + t - t * t - 1; } if (t > 1 - dt) { t = (t - 1) / dt; return t * t + t + t + 1; } return 0; }
const sierra = (ph, dt) => 2 * ph - 1 - blep(ph, dt);
function pulso(ph, dt, d) { let v = ph < d ? 1 : -1; v += blep(ph, dt); v -= blep((ph + 1 - d) % 1, dt); return v - (2 * d - 1); }
// filtro de estado variable (TPT): lp, bp, hp
function svf() { let ic1 = 0, ic2 = 0, g = 0, k = 1, a1 = 0, a2 = 0, a3 = 0;
  return { set(fc, q) { g = Math.tan(Math.PI * Math.min(fc, SR * .45) / SR); k = 1 / q; a1 = 1 / (1 + g * (g + k)); a2 = g * a1; a3 = g * a2; },
    run(x) { const v3 = x - ic2, v1 = a1 * ic1 + a2 * v3, v2 = ic2 + a2 * ic1 + a3 * v3; ic1 = 2 * v1 - ic1; ic2 = 2 * v2 - ic2; this.lp = v2; this.bp = v1; this.hp = x - k * v1 - v2; return v2; } }; }
// envolvente: ataque lineal, caída exponencial al sostenido mientras dura la nota y suelta exponencial
function adsr(n, dur, a, d, s, r) { const e = new Float32Array(n), na = Math.max(1, a * SR), nd = dur * SR; let v = 0;
  for (let i = 0; i < n; i++) { if (i < nd) v = i < na ? i / na : s + (1 - s) * Math.exp(-(i - na) / (d * SR)); else { if (i === Math.ceil(nd)) v = e[i - 1] || v; v *= Math.exp(-1 / (r * SR)); } e[i] = v; }
  return e; }

// ---------- instrumentos: cada uno da la nota en mono (con su suelta) ----------
const INST = {
  // los de consola, con vibrato tardío
  pulso: (f, dur, v) => chip(f, dur, v, .25), pulso12: (f, dur, v) => chip(f, dur, v, .125), cuadrada: (f, dur, v) => chip(f, dur, v, .5),
  tri(f, dur, v) { const n = Math.ceil((dur + .08) * SR), o = new Float32Array(n), e = adsr(n, dur, .004, .3, .8, .04); let ph = 0;
    for (let i = 0; i < n; i++) { const vib = 1 + .004 * Math.sin(TAU * 5.5 * i / SR) * Math.min(1, Math.max(0, i / SR - .18) * 4); ph = (ph + f * vib / SR) % 1; o[i] = (1 - 4 * Math.abs(ph - .5)) * e[i] * v; } return o; },
  flauta(f, dur, v, R) { const n = Math.ceil((dur + .15) * SR), o = new Float32Array(n), e = adsr(n, dur, .05, .4, .85, .08), F = svf(); F.set(f * 2.2, 2); let ph = 0;
    for (let i = 0; i < n; i++) { const t = i / SR, vib = 1 + .005 * Math.sin(TAU * 5.2 * t) * Math.min(1, Math.max(0, t - .2) * 3); ph = (ph + f * vib / SR) % 1;
      F.run(R() * 2 - 1); o[i] = (Math.sin(TAU * ph) + .18 * Math.sin(2 * TAU * ph) + .06 * Math.sin(3 * TAU * ph) + .35 * F.bp * (.4 + .6 * Math.exp(-t * 8))) * e[i] * v * .8; } return o; },
  silbido(f, dur, v) { const n = Math.ceil((dur + .1) * SR), o = new Float32Array(n), e = adsr(n, dur, .03, .3, .9, .06); let ph = 0;
    for (let i = 0; i < n; i++) { const t = i / SR; ph = (ph + f * (1 + .007 * Math.sin(TAU * 6 * t) * Math.min(1, t * 3)) / SR) % 1; o[i] = Math.sin(TAU * ph) * e[i] * v * .8; } return o; },
  // piano eléctrico (FM 1:1 con el golpe de la púa) y piano (parciales con su inarmonía)
  epiano(f, dur, v) { const n = Math.ceil((dur + .5) * SR), o = new Float32Array(n), e = adsr(n, dur, .002, 1.4, .25, .25), hi = Math.min(14 * f, SR * .4);
    for (let i = 0; i < n; i++) { const t = i / SR, I = (1.8 * Math.exp(-t * 4) + .25) * (.6 + .5 * v);
      o[i] = (Math.sin(TAU * f * t + I * Math.sin(TAU * f * t)) + .12 * Math.sin(TAU * hi * t) * Math.exp(-t * 30)) * e[i] * v * .7; } return o; },
  piano(f, dur, v) { const n = Math.ceil((dur + .6) * SR), o = new Float32Array(n), B = .0004, P = [];
    for (let k = 1; k <= 8; k++) { const fk = k * f * Math.sqrt(1 + B * k * k); if (fk < SR * .45) P.push([fk, Math.pow(k, -1.3) * (k === 1 ? 1 : .8), .9 + .55 * k + f / 400]); }
    const nd = dur * SR; for (let i = 0; i < n; i++) { const t = i / SR, rel = i < nd ? 1 : Math.exp(-(i - nd) / (.12 * SR)); let s = 0;
      for (const [fk, a, d] of P) s += a * Math.sin(TAU * fk * t) * Math.exp(-t * d); o[i] = s * rel * v * .5 * Math.min(1, i / 40); } return o; },
  // cuerda pulsada (Karplus-Strong): guitarra, la clavi (más brillante y corta) y el bajo de púa
  guitarra: (f, dur, v, R) => cuerda(f, dur, v, R, .55, .996, .3), clavi: (f, dur, v, R) => cuerda(f, dur, v, R, .9, .99, .08),
  bajopick(f, dur, v, R) { const c = cuerda(f, dur, v, R, .35, .997, .1); for (let i = 0; i < c.length; i++) { const t = i / SR; c[i] = c[i] * .8 + .55 * v * Math.sin(TAU * f * t) * Math.exp(-t * 2.5) * Math.min(1, i / 60) * (i < dur * SR ? 1 : Math.exp(-(i - dur * SR) / (.05 * SR))); } return c; },
  contrabajo(f, dur, v) { const n = Math.ceil((dur + .15) * SR), o = new Float32Array(n), nd = dur * SR;
    for (let i = 0; i < n; i++) { const t = i / SR, rel = i < nd ? 1 : Math.exp(-(i - nd) / (.06 * SR));
      o[i] = (Math.sin(TAU * f * t) + .35 * Math.sin(2 * TAU * f * t) * Math.exp(-t * 6) + .1 * Math.sin(3 * TAU * f * t) * Math.exp(-t * 12)) * Math.exp(-t * 1.6) * Math.min(1, i / 300) * rel * v * .9; } return o; },
  subbajo(f, dur, v) { const n = Math.ceil((dur + .08) * SR), o = new Float32Array(n), e = adsr(n, dur, .006, .5, .85, .05); let ph = 0;
    for (let i = 0; i < n; i++) { ph = (ph + f / SR) % 1; const x = Math.sin(TAU * ph) + .25 * (1 - 4 * Math.abs(ph - .5)); o[i] = Math.tanh(1.4 * x) * e[i] * v * .8; } return o; },
  bajo808(f, dur, v) { const n = Math.ceil((dur + .3) * SR), o = new Float32Array(n), nd = dur * SR; let ph = 0;
    for (let i = 0; i < n; i++) { const t = i / SR; ph = (ph + f * (1 + .5 * Math.exp(-t * 40)) / SR) % 1; o[i] = Math.tanh(1.8 * Math.sin(TAU * ph)) * Math.exp(-t * 1.2) * (i < nd ? 1 : Math.exp(-(i - nd) / (.08 * SR))) * Math.min(1, i / 30) * v * .75; } return o; },
  tribajo(f, dur, v) { const n = Math.ceil((dur + .04) * SR), o = new Float32Array(n), e = adsr(n, dur, .002, .4, .9, .02); let ph = 0;
    for (let i = 0; i < n; i++) { ph = (ph + f / SR) % 1; o[i] = (1 - 4 * Math.abs(ph - .5)) * e[i] * v * .9; } return o; },
  sintebajo(f, dur, v) { const n = Math.ceil((dur + .06) * SR), o = new Float32Array(n), e = adsr(n, dur, .003, .25, .7, .04), F = svf(); let p1 = 0, p2 = 0; const dt = f / SR;
    for (let i = 0; i < n; i++) { if (i % 16 === 0) F.set(260 + 1600 * Math.exp(-i / SR * 14) * v, 1.6); p1 = (p1 + dt) % 1; p2 = (p2 + dt / 2) % 1;
      o[i] = Math.tanh(1.3 * F.run(.7 * sierra(p1, dt) + .5 * pulso(p2, dt / 2, .5))) * e[i] * v; } return o; },
  // teclados y fuelles
  organo(f, dur, v) { const n = Math.ceil((dur + .06) * SR), o = new Float32Array(n), e = adsr(n, dur, .008, .1, 1, .05), H = [[.5, .5], [1, 1], [2, .6], [3, .35], [4, .3], [6, .12]].filter(([h]) => h * f < SR * .4);
    for (let i = 0; i < n; i++) { const t = i / SR, w = 1 + .003 * Math.sin(TAU * 6.3 * t); let s = 0; for (const [h, a] of H) s += a * Math.sin(TAU * f * h * w * t);
      o[i] = (s * .45 + (i < 200 ? .3 * Math.sin(TAU * 3000 * t) * (1 - i / 200) : 0)) * e[i] * v; } return o; },
  acordeon(f, dur, v) { const n = Math.ceil((dur + .08) * SR), o = new Float32Array(n), e = adsr(n, dur, .03, .3, .9, .05), F = svf(); F.set(Math.min(3200, f * 7), .8); let a = 0, b = 0, c = 0;
    for (let i = 0; i < n; i++) { const fa = f * 1.0025 / SR, fb = f * .9975 / SR; a = (a + fa) % 1; b = (b + fb) % 1; c = (c + f / 2 / SR) % 1;
      o[i] = F.run(.5 * pulso(a, fa, .3) + .5 * pulso(b, fb, .3) + .4 * Math.sin(TAU * c)) * e[i] * v * .8; } return o; },
  // pads, cuerdas, el lead de sierras y los metales
  pad(f, dur, v) { return sierras(f, dur, v, [-.08, 0, .08], 1400, .35, .9, .5); },
  cuerdas(f, dur, v) { return sierras(f, dur, v, [-.12, -.05, .05, .12], 3200, .22, .5, .9, true); },
  supersaw(f, dur, v) { return sierras(f, dur, v, [-.25, -.15, -.06, 0, .06, .15, .25], 6500, .006, .15, .55); },
  metales(f, dur, v) { const n = Math.ceil((dur + .1) * SR), o = new Float32Array(n), e = adsr(n, dur, .03, .3, .8, .07), F = svf(); let p = 0, q = 0; const dt = f / SR;
    for (let i = 0; i < n; i++) { const t = i / SR; if (i % 16 === 0) F.set(700 + 2600 * Math.min(1, t * 18) * (.55 + .45 * Math.exp(-t * 5)) * v, .9); p = (p + dt) % 1; q = (q + dt * 1.003) % 1;
      o[i] = F.run(.6 * sierra(p, dt) + .5 * sierra(q, dt)) * e[i] * v * .8; } return o; },
  campana(f, dur, v) { const n = Math.ceil((dur + 1.2) * SR), o = new Float32Array(n);
    for (let i = 0; i < n; i++) { const t = i / SR; o[i] = Math.sin(TAU * f * t + 3.2 * Math.exp(-t * 2.5) * Math.sin(TAU * 3.5 * f * t)) * Math.exp(-t * 1.6) * Math.min(1, i / 20) * v * .55; } return o; },
  marimba(f, dur, v) { const n = Math.ceil((Math.min(dur, .6) + .4) * SR), o = new Float32Array(n), f4 = Math.min(f * 3.93, SR * .4);
    for (let i = 0; i < n; i++) { const t = i / SR; o[i] = (Math.sin(TAU * f * t) * Math.exp(-t * 5) + .3 * Math.sin(TAU * f4 * t) * Math.exp(-t * 22)) * Math.min(1, i / 25) * v * .8; } return o; },
};
function chip(f, dur, v, d) { const n = Math.ceil((dur + .06) * SR), o = new Float32Array(n), e = adsr(n, dur, .004, .25, .75, .04), dt = f / SR, F = svf(); F.set(Math.min(9000, f * 9), .7); let ph = 0;
  for (let i = 0; i < n; i++) { const t = i / SR, vib = 1 + .0045 * Math.sin(TAU * 5.6 * t) * Math.min(1, Math.max(0, t - .2) * 3); ph = (ph + dt * vib) % 1; o[i] = F.run(pulso(ph, dt * vib, d)) * e[i] * v * .5; }
  return o; }
function cuerda(f, dur, v, R, brillo, fb, suelta) {
  const n = Math.ceil((dur + suelta + .05) * SR), o = new Float32Array(n), L = SR / f, N = Math.floor(L), fr = L - N, buf = new Float32Array(N + 2), F = svf(); F.set(400 + 9000 * brillo * brillo, .7);
  for (let i = 0; i < buf.length; i++) buf[i] = F.run(R() * 2 - 1);
  let p = 0, last = 0; const nd = dur * SR, amort = Math.pow(fb, 440 / Math.max(f, 60));
  for (let i = 0; i < n; i++) { const a = buf[p], b = buf[(p + 1) % (N + 1)], y = a + (b - a) * fr; o[i] = y * v * .9 * (i < nd ? 1 : Math.exp(-(i - nd) / (suelta * SR)));
    buf[p] = amort * .5 * (y + last); last = y; p = (p + 1) % (N + 1); }
  return o; }
function sierras(f, dur, v, des, fc, a, d, r, vib) {
  const n = Math.ceil((dur + r * 2.5) * SR), o = new Float32Array(n), e = adsr(n, dur, a, d, .8, r), F = svf(), ph = des.map((_, i) => i / des.length), fs = des.map(c => f * Math.pow(2, c / 12));
  F.set(Math.min(fc, f * 10), .7);
  for (let i = 0; i < n; i++) { const w = vib ? 1 + .004 * Math.sin(TAU * 5 * i / SR) : 1; let s = 0;
    for (let k = 0; k < ph.length; k++) { const dt = fs[k] * w / SR; ph[k] = (ph[k] + dt) % 1; s += sierra(ph[k], dt); }
    o[i] = F.run(s / Math.sqrt(ph.length)) * e[i] * v * .5; }
  return o; }

// ---------- batería ----------
function golpe(k, v, R) {
  const L = { z: 2.2, d: 1.2, o: .45, t: .5, T: .4, m: .5, b: .35, i: .9 }[k] || .3, n = Math.ceil(L * SR), o = new Float32Array(n), F = svf(), G = svf();
  let ph = 0;
  for (let i = 0; i < n; i++) { const t = i / SR, w = R() * 2 - 1; let s = 0;
    switch (k) {
      case 'k': ph += (48 + 70 * Math.exp(-t * 28)) / SR; s = Math.sin(TAU * ph) * Math.exp(-t * 7.5) + (i < 120 ? w * .25 * (1 - i / 120) : 0); s = Math.tanh(1.6 * s); break;            // bombo
      case 'K': ph += (44 + 110 * Math.exp(-t * 40)) / SR; s = Math.tanh(2.2 * Math.sin(TAU * ph)) * Math.exp(-t * 5.5) + (i < 90 ? w * .3 * (1 - i / 90) : 0); break;              // bombo electrónico
      case 's': if (!i) { F.set(2600, .7); } F.run(w); ph += (185 - 25 * Math.min(1, t * 30)) / SR; s = F.bp * 1.4 * Math.exp(-t * 16) + .55 * Math.sin(TAU * ph) * Math.exp(-t * 28); break;   // caja
      case 'c': if (!i) F.set(1300, 1.2); F.run(w); s = F.bp * 2.2 * (t < .03 ? (Math.floor(t / .01) % 1 === 0 ? Math.exp(-(t % .01) * 300) : 0) : Math.exp(-(t - .03) * 14)); break;     // palmas
      case 'r': s = (Math.sin(TAU * 1750 * t) * .6 + Math.sin(TAU * 520 * t)) * Math.exp(-t * 70); break;                                                                                // aro
      case 'h': if (!i) F.set(7500, .7); F.run(w); s = F.hp * Math.exp(-t * 55) * .8; break;                                                                                           // charles
      case 'o': if (!i) F.set(7000, .7); F.run(w); s = F.hp * Math.exp(-t * 7) * .55; break;                                                                                           // charles abierto
      case 'p': if (!i) F.set(6000, 1.5); F.run(w); s = F.bp * Math.min(1, t * 90) * Math.exp(-t * 30) * 1.4; break;                                                                   // maraca
      case 'b': if (!i) F.set(8000, .7); F.run(w); s = (F.hp * .5 + .25 * (Math.sin(TAU * 6500 * t) + Math.sin(TAU * 8200 * t) + Math.sin(TAU * 9700 * t)) * (R() * .5 + .5)) * Math.exp(-t * 12); break;   // pandero
      case 't': ph += (95 + 60 * Math.exp(-t * 20)) / SR; s = Math.sin(TAU * ph) * Math.exp(-t * 7) + w * .1 * Math.exp(-t * 40); break;                                              // timbal bajo
      case 'T': ph += (150 + 80 * Math.exp(-t * 20)) / SR; s = Math.sin(TAU * ph) * Math.exp(-t * 9) + w * .1 * Math.exp(-t * 40); break;                                             // timbal alto
      case 'i': ph += (62 + 20 * Math.exp(-t * 8)) / SR; s = Math.sin(TAU * ph) * Math.exp(-t * 3.2) + .3 * Math.sin(TAU * ph * 1.5) * Math.exp(-t * 6) + w * .15 * Math.exp(-t * 50); break;   // timbal de orquesta
      case 'z': if (!i) F.set(5200, .6); F.run(w); s = (F.hp * .7 + .2 * Math.sign(Math.sin(TAU * 4370 * t)) * Math.sign(Math.sin(TAU * 6110 * t))) * Math.exp(-t * 2) * .7; break;   // plato
      case 'd': if (!i) F.set(4000, .7); F.run(w); s = (F.hp * .25 + .3 * Math.sign(Math.sin(TAU * 5300 * t) + Math.sin(TAU * 7900 * t))) * Math.exp(-t * 4) * .45; break;            // ride
      case 'e': if (!i) { F.set(5500, .5); } F.run(w); s = F.lp * Math.min(1, t * 60) * Math.exp(-t * 14) * .9; break;                                                                  // escobilla
      case 'm': s = (Math.sin(TAU * 523 * t) + .8 * Math.sin(TAU * 1187 * t) + .6 * Math.sin(TAU * 1871 * t) + .5 * Math.sin(TAU * 2653 * t)) * Math.exp(-t * 9) * .3 + w * .4 * Math.exp(-t * 60); break;   // chatarra
    }
    o[i] = s * v; }
  return o; }
const BAT_VOL = { k: .9, K: .85, s: .5, c: .45, r: .35, h: .22, o: .2, p: .18, b: .2, t: .55, T: .5, i: .8, z: .3, d: .2, e: .4, m: .32 };

// ---------- estilos: batería por compás (16 o 12 pasos de semicorchea: X fuerte, x normal, o suave), bajo y acompañamiento ----------
// bajo: un token por corchea (R raíz, 5 quinta, 8 octava, 3 tercera, 7 séptima, - liga, . silencio, W caminando a negras)
// acompañamiento: pad (todo el acorde), stab (golpes del patrón), arp (índices del acorde), rasgueo (d abajo, u arriba)
const E = {
  pop: { bat: { base: { k: 'x.....x.x.......', s: '....X.......X...', h: 'x.x.x.x.x.x.x.x.' }, mas: { k: 'x.....x.x.....x.', s: '....X.......X..o', h: 'xxxxxxxxxxxxxxxx', p: '..x...x...x...x.' },
      suave: { k: 'x.......x.......', r: '....x.......x...', h: 'x...x...x...x...' }, relleno: { k: 'x.....x.x.......', s: '....X...xxoxXxXX', h: 'x.x.x.x.........' } },
    bajo: 'R . . R 5 . R .', bajoI: 'bajopick', comp: [{ i: 'guitarra', t: 'rasgueo', p: 'd . d u . u d u' }, { i: 'pad', t: 'pad', v: .5 }], rev: .22, dly: .12 },
  lounge: { platos: false, swing: .3, bat: { base: { k: 'x.........x.....', e: '....x.......x...', d: 'x...x.x.x...x.x.' }, mas: { k: 'x.........x.....', e: '....x.......x..o', d: 'x...x.x.x...x.x.', h: '....x.......x...' },
      suave: { e: '....x.......x...', d: 'x...x...x...x...' }, relleno: { k: 'x.........x.....', e: '....x...x.x.xxxx', d: 'x...x.x.........' } },
    bajo: 'W', bajoI: 'contrabajo', comp: [{ i: 'epiano', t: 'stab', p: 'x - - . . x - .', v: .7 }], rev: .3, dly: .08 },
  industrial: { bat: { base: { k: 'X.....x.X.....x.', s: '....X.......X...', m: '..x.......x.....', h: 'x.x.x.x.x.x.x.x.' }, mas: { k: 'X.....x.X.x...x.', s: '....X.......X.x.', m: '..x...x...x...x.', h: 'xxxxxxxxxxxxxxxx' },
      suave: { k: 'x.......x.......', m: '..o.......o.....', h: 'x...x...x...x...' }, relleno: { k: 'X.....x.X.......', s: '....X...xxxxXXXX', m: '..x.......x.....' } },
    bajo: 'R . 8 R . R 8 .', bajoI: 'sintebajo', comp: [{ i: 'pulso12', t: 'arp', p: 'x x x x x x x x', ap: '0 1 2 1', v: .45 }, { i: 'pad', t: 'pad', v: .45 }], rev: .25, dly: .2 },
  vals: { platos: false, compas: 3, bat: { base: { k: 'x...........', b: '....x...x...', h: 'x.x.x.x.x.x.' }, mas: { k: 'x...........', b: '....x...x...', s: '........o...', h: 'x.x.x.x.x.x.' },
      suave: { b: '....o...o...' }, relleno: { k: 'x...........', b: '....x...xxxx' } },
    bajo: 'R . . . 5 .', bajoI: 'contrabajo', comp: [{ i: 'acordeon', t: 'stab', p: '. . x - x -', v: .55 }], rev: .26, dly: .1 },
  rock: { bat: { base: { k: 'x.....x.x.x.....', s: '....X.......X...', h: 'x.x.x.x.x.x.x.x.' }, mas: { k: 'x.....x.x.x...x.', s: '....X.......X...', h: 'x.x.x.x.x.x.x.x.', d: 'x...x...x...x...' },
      suave: { k: 'x.......x.......', h: 'x...x...x...x...' }, relleno: { k: 'x.....x.........', s: '....X...xxxx', t: '............x.x.', T: '........x.x.....' } },
    bajo: 'R R R R R R R R', bajoI: 'bajopick', comp: [{ i: 'guitarra', t: 'rasgueo', p: 'd . d . d u d .', v: .8 }, { i: 'organo', t: 'pad', v: .35 }], rev: .2, dly: .1 },
  trikiti: { platos: false, compas: 3, bat: { base: { k: 'x.....x.....', b: '..x.x...x.x.', h: 'x.x.x.x.x.x.' }, mas: { k: 'x.....x.....', b: 'x.xxx.x.xxx.', s: '...........o' },
      suave: { b: '..o.....o...' }, relleno: { k: 'x.....x.....', b: 'xxxxxxxxxxxx' } },
    bajo: 'R . . 5 . .', bajoI: 'contrabajo', comp: [{ i: 'acordeon', t: 'stab', p: '. x x . x x', v: .45 }], rev: .2, dly: .05 },
  pastoral: { platos: false, bat: { base: { e: '....o.......o...', p: '..o...o...o...o.' }, mas: { k: 'o.......o.......', e: '....x.......x...', p: '..x...x...x...x.' }, suave: { p: '..o.......o.....' }, relleno: { e: '....x...x.x.x.x.' } },
    bajo: 'R - - - 5 - - -', bajoI: 'contrabajo', comp: [{ i: 'guitarra', t: 'arp', p: 'x x x x x x x x', ap: '0 1 2 3 2 1 2 1', v: .5 }, { i: 'cuerdas', t: 'pad', v: .3 }], rev: .32, dly: .1 },
  funk: { bat: { base: { k: 'x..x..x...x..x..', s: '....X.......X...', h: 'x.xxx.xxx.xxx.xx' }, mas: { k: 'x..x..x...x..x..', s: '....X..o....X..o', h: 'x.xxx.xxx.xxx.xx', o: '......x.......x.' },
      suave: { k: 'x.........x.....', r: '....x.......x...', h: 'x.x.x.x.x.x.x.x.' }, relleno: { k: 'x..x..x.........', s: '....X...xoxoXxXX', h: 'x.xxx.xx........' } },
    bajo: 'R . R 8 . R 5 7', bajoI: 'sintebajo', comp: [{ i: 'clavi', t: 'stab', p: '. x . x x . x .', v: .5 }, { i: 'organo', t: 'pad', v: .25 }], rev: .18, dly: .14 },
  electro: { sc: .55, bat: { base: { K: 'x...x...x...x...', c: '....x.......x...', h: '..x...x...x...x.' }, mas: { K: 'x...x...x...x...', c: '....x.......x...', h: 'xxx.xxx.xxx.xxx.', o: '..x...x...x...x.' },
      suave: { K: 'x...............', h: '..x...x...x...x.' }, relleno: { K: 'x...x...x...x...', c: '....x...x.x.xxxx', h: '..x...x.........' } },
    bajo: '. R . R . R . R', bajoI: 'sintebajo', comp: [{ i: 'supersaw', t: 'stab', p: 'x . . x . . x .', v: .4 }, { i: 'pulso12', t: 'arp', p: 'x x x x x x x x', ap: '0 1 2 3 2 1 2 1', v: .3, oct: 1 }], rev: .25, dly: .22 },
  noir: { platos: false, swing: .25, bat: { base: { e: '....x.......x...', d: 'x..x..x.x..x..x.' , k: 'x.........o.....' }, mas: { e: '....x.......x...', d: 'x..x..x.x..x..x.', k: 'x.......x.o.....' }, suave: { d: 'x...x...x...x...' }, relleno: { e: '....x...x.x.xxxx', k: 'x.........' } },
    bajo: 'W', bajoI: 'contrabajo', comp: [{ i: 'piano', t: 'stab', p: 'x - . . . . x .', v: .5 }], rev: .38, dly: .16 },
  reggae: { bat: { base: { k: '........X.......', r: '........x.......', h: 'x.x.x.x.x.x.x.x.' }, mas: { k: '........X.......', s: '........X.......', h: 'x.xxx.xxx.xxx.xx', p: 'x.x.x.x.x.x.x.x.' },
      suave: { r: '........x.......', h: 'x...x...x...x...' }, relleno: { k: '........X.......', s: '........xxxxXxXX' } },
    bajo: 'R - . R 5 - 3 .', bajoI: 'subbajo', comp: [{ i: 'guitarra', t: 'stab', p: '. x . x . x . x', v: .55 }, { i: 'organo', t: 'stab', p: '. x . x . x . x', v: .3 }], rev: .24, dly: .3 },
  lofi: { platos: false, swing: .28, polvo: .012, corta: 7000, bat: { base: { k: 'x.......x.x.....', s: '....X.......X...', h: 'x.x.x.x.x.x.x.x.' }, mas: { k: 'x.......x.x...o.', s: '....X.......X...', h: 'x.x.x.xxx.x.x.x.', p: '..x...x...x...x.' },
      suave: { k: 'x.........o.....', r: '....x.......x...', h: 'x...x...x...x...' }, relleno: { k: 'x.......x.......', s: '....X.......XoXo' } },
    bajo: 'R - - . . 5 R .', bajoI: 'subbajo', comp: [{ i: 'epiano', t: 'stab', p: 'x - - . . x - -', v: .6 }], rev: .3, dly: .14 },
  tango: { platos: false, compas: 2, bat: { base: { k: 'x...x...', r: '..x.....' }, mas: { k: 'x...x...', s: '......x.', r: '..x.....' }, suave: { r: 'x.......' }, relleno: { k: 'x...x...', s: '....xxXX' } },
    bajo: 'R . 5 .', bajoI: 'contrabajo', comp: [{ i: 'acordeon', t: 'stab', p: 'x . x .', v: .55 }, { i: 'piano', t: 'stab', p: 'x . x .', v: .35 }], rev: .22, dly: .05 },
  tension: { bat: { base: { k: 'x.......x.......', h: 'x.x.x.x.x.x.x.x.', t: '..............x.' }, mas: { k: 'x.....x.x.......', h: 'xxxxxxxxxxxxxxxx', t: '..............x.', s: '............x...' },
      suave: { h: 'x...x...x...x...' }, relleno: { k: 'x.......', t: '........x.x.x.x.', T: '.........x.x.x.x' } },
    bajo: 'R R R R R R R R', bajoI: 'subbajo', comp: [{ i: 'cuerdas', t: 'pad', v: .45 }, { i: 'pulso12', t: 'arp', p: 'x . x . x . x .', ap: '0 2 1 2', v: .3 }], rev: .32, dly: .2 },
  bossa: { platos: false, bat: { base: { r: 'x..x..x...x..x..', p: 'xxxxxxxxxxxxxxxx', k: 'x..x....x..x....' }, mas: { r: 'x..x..x...x..x..', p: 'xxxxxxxxxxxxxxxx', k: 'x..x....x..x....', e: '....x.......x...' },
      suave: { p: 'x.x.x.x.x.x.x.x.' }, relleno: { r: 'x..x..x.xxxxxxxx', k: 'x..x....' } },
    bajo: 'R . . 5 R . . 5', bajoI: 'contrabajo', comp: [{ i: 'guitarra', t: 'stab', p: 'x . x x . x . x', v: .45 }, { i: 'epiano', t: 'pad', v: .25 }], rev: .26, dly: .08 },
  neosoul: { swing: .22, bat: { base: { k: 'x......x..x.....', s: '....X.......X...', h: 'x.x.x.x.x.x.x.x.' }, mas: { k: 'x......x..x...x.', s: '....X.......X...', h: 'x.xxx.x.x.xxx.x.', p: '..x...x...x...x.' },
      suave: { k: 'x.........x.....', r: '....x.......x...' }, relleno: { k: 'x......x', s: '....X...XoXoXxXX' } },
    bajo: 'R - . 5 . 8 7 .', bajoI: 'subbajo', comp: [{ i: 'epiano', t: 'stab', p: 'x - - x - - x -', v: .55 }, { i: 'cuerdas', t: 'pad', v: .2 }], rev: .26, dly: .16 },
  bolero: { platos: false, bat: { base: { k: 'x.......x.......', r: '....x..xx...x...', p: 'x.xxx.x.x.xxx.x.' }, mas: { k: 'x.......x.......', r: '....x..xx...x...', p: 'x.xxx.x.x.xxx.x.', e: '....x.......x...' },
      suave: { p: 'x...x...x...x...' }, relleno: { k: 'x.......', r: '....x..xxxxxxxxx' } },
    bajo: 'R . . 5 R . 5 .', bajoI: 'contrabajo', comp: [{ i: 'guitarra', t: 'arp', p: 'x x x x x x x x', ap: '0 1 2 1 0 1 2 1', v: .45 }, { i: 'organo', t: 'pad', v: .22 }], rev: .3, dly: .08 },
  folk: { platos: false, bat: { base: { k: 'x.......x.......', e: '....x.......x...', b: '..x...x...x...x.' }, mas: { k: 'x.......x.......', e: '....x.......x...', b: 'x.x.x.x.x.x.x.x.' }, suave: { b: '....o.......o...' }, relleno: { e: '....x...x.x.xxxx' } },
    bajo: 'R . . . 5 . . .', bajoI: 'contrabajo', comp: [{ i: 'guitarra', t: 'rasgueo', p: 'd . d u . u d u', v: .55 }], rev: .26, dly: .06 },
  ambiente: { platos: false, zumbido: .01, bat: { base: { k: 'x.........x.....', h: '..x...x...x...x.', m: '......x.........' }, mas: { k: 'x.........x.....', h: 'x.xxx.xxx.xxx.xx', m: '......x.......x.' }, suave: { h: '..x.......x.....' }, relleno: { k: 'x.........', m: '..x.x.x.x' } },
    bajo: 'R - - - - - . .', bajoI: 'subbajo', comp: [{ i: 'marimba', t: 'arp', p: 'x . x x . x . x', ap: '0 2 1 3 2 1 0 2', v: .4, oct: 1 }, { i: 'pad', t: 'pad', v: .45 }], rev: .4, dly: .3 },
  batalla: { bat: { base: { k: 'x.x...x.x.x...x.', s: '....X.......X...', h: 'x.x.x.x.x.x.x.x.' }, mas: { k: 'x.x...x.x.x...x.', s: '....X.......X..x', h: 'xxxxxxxxxxxxxxxx', d: 'x...x...x...x...' },
      suave: { k: 'x.......x.......', h: 'x.x.x.x.x.x.x.x.' }, relleno: { k: 'x.x.....', s: '....XxXxXXXX', T: '........x.x.....', t: '............x.x.' } },
    bajo: 'R R 8 R R R 8 R', bajoI: 'sintebajo', comp: [{ i: 'pulso12', t: 'arp', p: 'x x x x x x x x', ap: '0 1 2 1', v: .4, oct: 1 }, { i: 'metales', t: 'stab', p: 'x - . . . . x .', v: .35 }], rev: .2, dly: .12 },
  drama: { platos: false, bat: { base: { i: 'x.......x.......', t: '..............x.' }, mas: { i: 'x.....x.x.......', s: '....x.......x...', t: '............x.x.' }, suave: { i: 'x...............' }, relleno: { i: 'x...x...x.x.xxxx', T: '..........x.x...' } },
    bajo: 'R - - - - - - -', bajoI: 'subbajo', comp: [{ i: 'cuerdas', t: 'pad', v: .6 }, { i: 'piano', t: 'stab', p: 'x - - - . . . .', v: .4 }], rev: .38, dly: .12 },
  balada: { bat: { base: { k: 'x.......x.......', r: '....x.......x...', h: 'x...x...x...x...' }, mas: { k: 'x.......x.x.....', s: '....X.......X...', h: 'x.x.x.x.x.x.x.x.' }, suave: {}, relleno: { k: 'x.......', s: '....X...x.xoXxXX', t: '............x.x.' } },
    bajo: 'R - - - 5 - - -', bajoI: 'contrabajo', comp: [{ i: 'piano', t: 'arp', p: 'x x x x x x x x', ap: '0 1 2 3 2 1 2 1', v: .45 }, { i: 'cuerdas', t: 'pad', v: .35 }], rev: .36, dly: .1 },
};
// de noche: lead más suave, solo lo suave de la batería, más reverb, menos agudos, más lento y la forma corta
const LEAD_N = { pulso: 'flauta', pulso12: 'flauta', cuadrada: 'flauta', tri: 'silbido', acordeon: 'flauta', metales: 'epiano', supersaw: 'epiano', organo: 'epiano' };

// ---------- la canción → notas ----------
function compila(T, noche) {
  const est = E[T.estilo]; if (!est) throw Error('estilo ' + T.estilo);
  const tiempos = T.compas || est.compas || 4, res = T.res || 8, cPorPaso = 16 / res, ticksBar = tiempos * 4;   // semicorcheas
  const bpm = noche ? Math.round(T.bpm * (T.bpmN || .85)) : T.bpm, sTick = 60 / bpm / 4, swing = T.swing ?? est.swing ?? 0;
  const inst = Object.assign({ lead: 'pulso', lead2: 'campana' }, T.inst);
  if (noche) { inst.lead = (T.noche && T.noche.lead) || LEAD_N[inst.lead] || inst.lead; inst.lead2 = 'epiano'; }
  const forma = (noche ? (T.formaN || 'A- | A B A~') : T.forma).split(/\s+/).filter(Boolean);
  const R = azar(0x5eed ^ T.bpm * 977 ^ (noche ? 77 : 0)), ev = [], drums = [];
  const t2s = tk => { const b = Math.floor(tk / 2), off = tk % 2; return (b * 2 + off + (off ? swing * .66 : 0)) * sTick; };   // swing en las semicorcheas impares de cada corchea
  let tick = 0, buclet = null, prevVoz = [60, 64, 67], seccionN = 0;
  for (const f of forma) {
    if (f === '|') { buclet = tick; continue; }
    const m = /^([A-Za-z0-9]+)([+\-~>]*)$/.exec(f); if (!m) throw Error('forma ' + f);
    const S = T.sec[m[1]]; if (!S) throw Error(`sección ${m[1]} en ${T.n || ''}`);
    const mod = m[2], sinLead = mod.includes('-') || mod.includes('>') || !S.mel, roto = mod.includes('~'), intro = mod.includes('>'), lleno = mod.includes('+') && !noche;
    // acordes (con su duración en ticks)
    const ch = []; for (const t of toks(S.ch)) { const a = acorde(t); a.tk = a.negras ? a.negras * 4 : ticksBar; ch.push(a); }
    const total = ch.reduce((s, a) => s + a.tk, 0), bars = total / ticksBar;
    if (bars !== Math.round(bars)) throw Error(`${m[1]}: los acordes no llenan compases`);
    // melodía
    if (S.mel) { const mt = toks(S.mel); if (mt.length * cPorPaso !== total) throw Error(`${T.n || ''} ${m[1]}: melodía ${mt.length} pasos ≠ ${total / cPorPaso}`);
      S.mel.split('|').forEach((c, j) => { if (toks(c).length * cPorPaso !== ticksBar) throw Error(`${T.n || ''} ${m[1]}: el compás ${j + 1} de la melodía tiene ${toks(c).length} pasos`); }); }
    let a0 = tick;
    const acordeEn = tk => { let s = a0; for (const a of ch) { if (tk < s + a.tk) return a; s += a.tk; } return ch[ch.length - 1]; };
    // bajo
    const bp = toks(S.bajo || T.bajo || est.bajo);
    let s = tick;
    for (const a of ch) {
      if (bp[0] === 'W') {   // caminando: una negra por tiempo, raíz, notas del acorde y la de paso a la siguiente raíz
        const sig = ch[(ch.indexOf(a) + 1) % ch.length], n = a.tk / 4;
        for (let q = 0; q < n; q++) { const r = 36 + (a.b <= 4 ? a.b + 12 : a.b); let nota = r;
          if (q === n - 1 && n > 1) { const rs = 36 + (sig.b <= 4 ? sig.b + 12 : sig.b); nota = rs + (R() < .5 ? -1 : 1); }
          else if (q) nota = r + [0, a.iv[1], a.iv[2], 12][q % 4];
          ev.push({ t: s + q * 4, d: roto ? 4 : 3.6, n: nota, i: T.bajoI || est.bajoI, v: q ? .78 : .9, bus: 'bajo' }); }
      } else {
        const L = a.tk / 2;   // corcheas
        for (let q = 0; q < L; q++) { const tk = bp[q % bp.length]; if (tk === '.' || tk === '-') continue;
          if (roto && q % (tiempos * 2) !== 0) continue;
          let len = 1; while (q + len < L && bp[(q + len) % bp.length] === '-') len++;
          const r = 36 + (a.b <= 4 ? a.b + 12 : a.b), nota = r + ({ R: 0, 5: 7, 8: 12, 3: a.iv[1], 7: a.iv[3] ?? 10 })[tk];
          if (Number.isNaN(nota)) throw Error('bajo ' + tk);
          ev.push({ t: s + q * 2, d: roto ? a.tk : len * 2 - .3, n: nota, i: T.bajoI || est.bajoI, v: q % 2 ? .75 : .92, bus: 'bajo' }); } }
      s += a.tk; }
    // acompañamiento
    const comps = (T.comp || est.comp);
    s = tick;
    for (const a of ch) {
      const voz = voces(a, prevVoz); prevVoz = voz;
      for (const C of comps) {
        const vol = (C.v || .5) * (intro ? .7 : 1), ci = C.i;
        if (C.t === 'pad') { voz.forEach(n => ev.push({ t: s, d: a.tk - .2, n, i: ci, v: vol * .8, bus: 'pad' })); continue; }
        if (C.t === 'arp') { arp(a, C, voz, s, vol); continue; }
        if (roto) continue;
        const p = toks(C.p), L = a.tk / 2;
        for (let q = 0; q < L; q++) { const x = p[q % p.length]; if (x === '.' || x === '-') continue;
          let len = 1; while (q + len < L && p[(q + len) % p.length] === '-') len++;
          const dd = C.t === 'stab' ? len * 2 - .4 : len * 2;
          if (C.t === 'rasgueo') voz.forEach((n, j) => ev.push({ t: s + q * 2 + (x === 'u' ? (voz.length - 1 - j) : j) * .06, d: Math.max(1, len * 2 - .2), n, i: ci, v: vol * (x === 'u' ? .7 : 1) * (.9 + R() * .1), bus: 'comp' }));
          else voz.forEach(n => ev.push({ t: s + q * 2, d: dd, n: n + 12 * (C.oct || 0), i: ci, v: vol * (.92 + R() * .08), bus: 'comp' })); } }
      s += a.tk; }
    function arp(a, C, voz, s0, vol) { const ap = toks(C.ap || '0 1 2'), p = toks(C.p), L = a.tk / 2, ns = voz.slice().sort((x, y) => x - y);
      for (let q = 0; q < L; q++) { if (p[q % p.length] === '.') continue; const ix = +ap[q % ap.length], n = ns[ix % ns.length] + 12 * Math.floor(ix / ns.length) + 12 * (C.oct || 0);
        ev.push({ t: s0 + q * 2, d: 1.8, n, i: C.i, v: vol * (q % 2 ? .8 : 1), bus: 'comp' }); } }
    // melodía (y la segunda voz, una nota del acorde por debajo, en las secciones llenas)
    if (S.mel && !sinLead) {
      const mt = toks(S.mel); let i = 0;
      while (i < mt.length) { const t = mt[i]; if (t === '.' || t === '-') { i++; continue; }
        let len = 1; while (i + len < mt.length && mt[i + len] === '-') len++;
        const acc = t.endsWith('!'), n = midi(acc ? t.slice(0, -1) : t), tk = tick + i * cPorPaso, d = len * cPorPaso - (len === 1 ? .35 : .25);
        ev.push({ t: tk, d, n: n + (T.oct || 0) * 12, i: inst.lead, v: (acc ? 1 : .85) * (roto ? .85 : 1), bus: 'lead' });
        { const a = acordeEn(tk), pcs = a.iv.map(x => (a.r + x) % 12), pc = n % 12;   // aviso: nota larga en tiempo fuerte a un semitono del acorde
          if (!noche && tk % 8 === 0 && len * cPorPaso >= 4 && !pcs.includes(pc) && pcs.some(x => (pc - x + 12) % 12 === 1 || (x - pc + 12) % 12 === 1)) AVISOS.push(`${T.n} ${m[1]} compás ${Math.floor((tk - a0) / ticksBar) + 1}: ${t} sobre ${toks(S.ch).find(() => true) && Object.keys(PC).find(k => PC[k] === a.r) || a.r}${a.iv.join('.')}`); }
        if (lleno) { const a = acordeEn(tk), tonos = []; for (let o = -2; o <= 1; o++) for (const iv of a.iv) tonos.push(60 + a.r + iv + 12 * o);
          const debajo = tonos.filter(x => x <= n - 3).sort((x, y) => y - x)[0]; if (debajo) ev.push({ t: tk, d, n: debajo + (T.oct || 0) * 12, i: inst.lead2, v: .5, bus: 'lead2' }); }
        i += len; } }
    // batería
    if (!roto || intro) {
      for (let b = 0; b < bars; b++) {
        const ultimo = b === bars - 1 && bars >= 4 && !intro && !noche, nom = intro || noche ? 'suave' : ultimo ? 'relleno' : lleno ? 'mas' : 'base', P = est.bat[nom] || est.bat.base;
        for (const k in P) { const pat = P[k]; for (let q = 0; q < ticksBar; q++) { const c = pat[(q + (pat.length > ticksBar ? (b % 2) * ticksBar : 0)) % pat.length]; if (!c || c === '.') continue;
          drums.push({ t: tick + b * ticksBar + q, k, v: ({ X: 1, x: .8, o: .5 })[c] * (noche ? .7 : 1) * (.94 + R() * .06) }); } }
        if (b === 0 && (lleno || (buclet === tick && !noche && !intro)) && est.platos !== false) drums.push({ t: tick, k: 'z', v: .8 });
      }
    } else if (roto && !noche && est.platos !== false) drums.push({ t: tick, k: 'z', v: .5 });
    tick += total; seccionN++;
  }
  if (buclet === null) buclet = 0;
  return { ev, drums, total: tick, buclet, t2s, sTick, est, bpm, noche, inst };
}
// el acorde con la inversión más cercana a la anterior (3 o 4 voces entre 52 y 76)
function voces(a, prev) {
  const pcs = a.iv.map(i => (a.r + i) % 12).slice(0, 4), cand = [];
  for (let base = 52; base <= 64; base++) { const v = []; for (const pc of pcs) { let n = base + ((pc - base) % 12 + 12) % 12; v.push(n); } v.sort((x, y) => x - y); if (v[v.length - 1] <= 76) cand.push(v); }
  const pm = prev.reduce((s, x) => s + x, 0) / prev.length;
  cand.sort((x, y) => Math.abs(x.reduce((s, n) => s + n, 0) / x.length - pm) - Math.abs(y.reduce((s, n) => s + n, 0) / y.length - pm));
  return cand[0]; }

// ---------- mezcla ----------
const BUS = { lead: { g: .42, pan: 0, rev: 1, dly: 1 }, lead2: { g: .26, pan: -.35, rev: 1.2, dly: .6 }, comp: { g: .5, pan: .3, rev: 1, dly: .5 }, pad: { g: .2, pan: -.2, rev: 1.3, dly: 0 }, bajo: { g: .5, pan: 0, rev: .1, dly: 0 } };
// la ventana de cada bus frente a la melodía, en dB de energía (el bajo pesa más en RMS de lo que suena; la batería no se sube)
const AUTO = { lead2: [-12, -6], comp: [-12, -3], pad: [-15, -6], bajo: [-4, 2], bat: [-99, 1] };
const PAN_BAT = { h: .35, o: .35, p: -.4, b: -.3, d: .45, t: -.3, T: .3, r: .15, e: .1, m: -.25 };
function freeverb(L, R, room, damp, ancho) {
  const cl = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617], al = [556, 441, 341, 225], sp = 23, n = L.length, oL = new Float32Array(n), oR = new Float32Array(n);
  for (const [inp, out, off] of [[L, oL, 0], [R, oR, sp]]) {
    const cb = cl.map(l => ({ b: new Float32Array(l + off), p: 0, s: 0 })), ab = al.map(l => ({ b: new Float32Array(l + off), p: 0 }));
    for (let i = 0; i < n; i++) { const x = inp[i] * .015; let y = 0;
      for (const c of cb) { const o = c.b[c.p]; c.s = o * (1 - damp) + c.s * damp; c.b[c.p] = x + c.s * room; if (++c.p >= c.b.length) c.p = 0; y += o; }
      for (const a of ab) { const o = a.b[a.p]; a.b[a.p] = y + o * .5; y = o - y; if (++a.p >= a.b.length) a.p = 0; }
      out[i] = y; } }
  for (let i = 0; i < n; i++) { const l = oL[i], r = oR[i]; oL[i] = l * (.5 + ancho / 2) + r * (.5 - ancho / 2); oR[i] = r * (.5 + ancho / 2) + l * (.5 - ancho / 2); }
  return [oL, oR]; }
function eco(L, R, seg, fb) { const d = Math.round(seg * SR), n = L.length, oL = new Float32Array(n), oR = new Float32Array(n), F = svf(), G = svf(); F.set(3500, .7); G.set(3500, .7);
  for (let i = 0; i < n; i++) { const a = i >= d ? oR[i - d] : 0, b = i >= d ? oL[i - d] : 0; oL[i] = F.run(L[i] + a * fb); oR[i] = G.run(R[i] * .3 + b * fb); }
  return [oL, oR]; }

function render(T, noche) {
  const C = compila(T, noche), { ev, drums, t2s, est } = C, R = azar(0xbeef ^ T.bpm), Rk = azar(0xd0d0);
  const tTot = t2s(C.total), tBuc = t2s(C.buclet), cola = 4, n = Math.ceil((tTot + (tTot - tBuc) + cola) * SR);
  const B = {}; for (const k of ['lead', 'lead2', 'comp', 'pad', 'bajo', 'bat']) B[k] = [new Float32Array(n), new Float32Array(n)];
  const sendR = [new Float32Array(n), new Float32Array(n)], sendD = [new Float32Array(n), new Float32Array(n)];
  const rev = (T.rev ?? est.rev) + (noche ? .12 : 0), dly = noche ? (T.dly ?? est.dly) * .6 : (T.dly ?? est.dly), cache = new Map();
  const bucleTk = C.total - C.buclet;
  // dos vueltas del bucle: la segunda trae las colas de la primera
  const pon = (tk, fn) => { fn(t2s(tk)); if (tk >= C.buclet) fn(t2s(tk + bucleTk)); };
  const suma = (buf, x, t, g, pan, sr, sd) => { const i0 = Math.round(t * SR), gl = g * Math.cos((pan + 1) * Math.PI / 4) * 1.41, gr = g * Math.sin((pan + 1) * Math.PI / 4) * 1.41;
    for (let k = 0; k < x.length && i0 + k < n; k++) { if (i0 + k < 0) continue; const v = x[k]; buf[0][i0 + k] += v * gl; buf[1][i0 + k] += v * gr;
      if (sr) { sendR[0][i0 + k] += v * gl * sr; sendR[1][i0 + k] += v * gr * sr; } if (sd) { sendD[0][i0 + k] += v * gl * sd; sendD[1][i0 + k] += v * gr * sd; } } };
  const nota = e => { const key = `${e.i}|${e.n}|${e.d.toFixed(2)}|${Math.round(e.v * 20)}`; let x = cache.get(key);
    if (!x) { x = INST[e.i](hz(e.n), e.d * C.sTick, Math.round(e.v * 20) / 20, R); if (!x) throw Error('instrumento ' + e.i); cache.set(key, x); } return x; };
  const kit = {}; const golpeDe = (k, v) => { const key = k + Math.round(v * 10); if (!kit[key]) kit[key] = golpe(k, Math.round(v * 10) / 10, Rk); return kit[key]; };
  // automezcla: la energía de cada bus (las notas no se correlan: se suman sus energías) y cada uno en su ventana frente a la melodía
  const en = x => { if (x.e === undefined) { let s = 0; for (let k = 0; k < x.length; k++) s += x[k] * x[k]; x.e = s; } return x.e; }, veces = tk => tk >= C.buclet ? 2 : 1;
  const E = { lead: 0, lead2: 0, comp: 0, pad: 0, bajo: 0, bat: 0 }, corr = { lead: 1 };
  for (const e of ev) E[e.bus] += en(nota(e)) * BUS[e.bus].g ** 2 * veces(e.t);
  for (const d of drums) E.bat += en(golpeDe(d.k, d.v)) * ((BAT_VOL[d.k] || .3) * .45) ** 2 * veces(d.t);
  for (const k in AUTO) { const rel = E[k] && E.lead ? 10 * Math.log10(E[k] / E.lead) : -50, [lo, hi] = AUTO[k]; if (rel === -50) { corr[k] = 1; continue; } corr[k] = Math.pow(10, (rel > hi ? hi - rel : rel < lo ? lo - rel : 0) / 20); }
  if (process.env.MUSICA_DEBUG) console.log('  automezcla', Object.entries(corr).map(([k, c]) => k + ' ' + (20 * Math.log10(c)).toFixed(1)).join(' · '));
  for (const e of ev) {
    const bus = BUS[e.bus], x = nota(e);
    const pan = bus.pan + (e.bus === 'comp' ? (e.n % 3 - 1) * .08 : 0);
    pon(e.t, t => suma(B[e.bus], x, t + (e.bus === 'comp' ? (R() - .5) * .006 : 0), bus.g * corr[e.bus] * (T.g?.[e.bus] ?? 1), pan, rev * bus.rev, dly * bus.dly));
  }
  const kicks = [];
  for (const d of drums) { const x = golpeDe(d.k, d.v), g = (BAT_VOL[d.k] || .3) * corr.bat * (T.g?.bat ?? 1) * .45;
    pon(d.t, t => { suma(B.bat, x, t + (d.k === 'h' || d.k === 'p' ? (R() - .5) * .004 : 0), g, PAN_BAT[d.k] || 0, d.k === 'k' || d.k === 'K' ? .15 * rev : .6 * rev, d.k === 's' || d.k === 'c' ? dly * .4 : 0); if (d.k === 'k' || d.k === 'K') kicks.push(t); }); }
  // sidechain: el bajo, el pad y el acompañamiento bajan con el bombo
  const sc = T.sc ?? est.sc;
  if (sc) { const env = new Float32Array(n).fill(1); for (const t of kicks) { const i0 = Math.round(t * SR); for (let k = 0; k < SR * .3 && i0 + k < n; k++) env[i0 + k] = Math.min(env[i0 + k], 1 - sc * Math.exp(-k / (SR * .07))); }
    for (const b of ['bajo', 'pad', 'comp']) for (const ch of B[b]) for (let i = 0; i < n; i++) ch[i] *= env[i]; }
  if (process.env.MUSICA_DEBUG) console.log('  buses', Object.entries(B).map(([k, b]) => { let e = 0; for (let i = 0; i < n; i++) e += b[0][i] * b[0][i] + b[1][i] * b[1][i]; return k + ' ' + (10 * Math.log10(e / n / 2 + 1e-12)).toFixed(1); }).join(' · '));
  const out = [new Float32Array(n), new Float32Array(n)];
  for (const k in B) for (let c = 0; c < 2; c++) { const s = B[k][c], o = out[c]; for (let i = 0; i < n; i++) o[i] += s[i]; }
  const [rL, rR] = freeverb(sendR[0], sendR[1], noche ? .88 : .84, .35, 1), [dL, dR] = eco(sendD[0], sendD[1], 60 / C.bpm * .75, .38);
  for (let i = 0; i < n; i++) { out[0][i] += rL[i] * 2.2 + dL[i] * .5; out[1][i] += rR[i] * 2.2 + dR[i] * .5; }
  // polvo de vinilo, el zumbido de la nave y, de noche o en el lo-fi, menos agudos
  const polvo = est.polvo || 0, zum = est.zumbido || 0, Rp = azar(99);
  if (polvo || zum) { const F = svf(); F.set(1200, .7); for (let i = 0; i < n; i++) { const t = i / SR; let x = 0;
    if (polvo) { x += (Rp() * 2 - 1) * polvo * .25; if (Rp() < 3 / SR * 30) x += (Rp() * 2 - 1) * polvo * 8; }
    if (zum) x += zum * (Math.sin(TAU * 50 * t) + .5 * Math.sin(TAU * 100 * t) + .3 * F.run(Rp() * 2 - 1));
    out[0][i] += x; out[1][i] += x; } }
  const corta = noche ? Math.min(est.corta || 20000, 5200) : est.corta;
  if (corta) for (const ch of out) { const F = svf(); F.set(corta, .7); for (let i = 0; i < n; i++) ch[i] = F.run(ch[i]); }
  for (const ch of out) { const F = svf(); F.set(28, .7); for (let i = 0; i < n; i++) { F.run(ch[i]); ch[i] = F.hp; } }
  // la intro una vez y la segunda vuelta del bucle
  const iB = Math.round(tBuc * SR), iT = Math.round(tTot * SR), iB2 = Math.round((tTot + 0) * SR), lenB = iT - iB, res = [new Float32Array(iB + lenB), new Float32Array(iB + lenB)];
  for (let c = 0; c < 2; c++) { res[c].set(out[c].subarray(0, iB), 0); res[c].set(out[c].subarray(iB2, iB2 + lenB), iB); }
  // volumen: la misma sonoridad (RMS de la canción) en todas y un limitador suave
  let e2 = 0; for (const ch of res) for (let i = 0; i < ch.length; i++) e2 += ch[i] * ch[i];
  const rms = Math.sqrt(e2 / (res[0].length * 2)), g = Math.pow(10, (T.db ?? -17) / 20) / Math.max(rms, 1e-6);
  let pico = 0;
  for (const ch of res) for (let i = 0; i < ch.length; i++) { let x = ch[i] * g; const ax = Math.abs(x); if (ax > .7) x = Math.sign(x) * (.7 + .25 * Math.tanh((ax - .7) / .25)); ch[i] = x; pico = Math.max(pico, Math.abs(x)); }
  return { L: res[0], R: res[1], bucle: iB / SR, dur: res[0].length / SR, pico, rms: 20 * Math.log10(rms * g) };
}

// ---------- salida ----------
function main() {
  const args = process.argv.slice(2), opt = k => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : null; };
  const sal = path.resolve(opt('--salida') || path.join(ROOT, 'godot/musica')), wav = args.includes('--wav'), forzar = args.includes('--forzar');
  const quiero = args.filter((a, i) => !a.startsWith('--') && !(i && ['--salida'].includes(args[i - 1])));
  fs.mkdirSync(sal, { recursive: true });
  const idxF = path.join(sal, 'indice.json'), idx = fs.existsSync(idxF) ? JSON.parse(fs.readFileSync(idxF, 'utf8')) : {};
  const motor = crypto.createHash('sha1').update(fs.readFileSync(__filename)).digest('hex').slice(0, 10);
  const lista = [];
  for (const [k, T] of Object.entries(TEMAS)) { T.n = k; lista.push([k, T, false]); if (T.calle) lista.push([k === 'town' ? 'night' : k + '_n', T, true]); }
  for (const [k, T, noche] of lista) {
    if (quiero.length && !quiero.includes(k)) continue;
    const h = motor + crypto.createHash('sha1').update(JSON.stringify([T, noche])).digest('hex').slice(0, 10), f = path.join(sal, k + '.ogg');
    if (!forzar && idx[k] && idx[k].h === h && fs.existsSync(f)) continue;
    const t0 = Date.now(), r = render(T, noche), n = r.L.length, il = new Float32Array(n * 2);
    if (!(r.pico > .2) || r.dur < 20) throw Error(`${k}: sale en silencio o corta (pico ${r.pico}, ${r.dur} s)`);
    for (let i = 0; i < n; i++) { il[i * 2] = r.L[i]; il[i * 2 + 1] = r.R[i]; }
    const pcm = Buffer.from(il.buffer);
    const ff = spawnSync('ffmpeg', ['-v', 'error', '-y', '-f', 'f32le', '-ar', String(SR), '-ac', '2', '-i', '-', ...(wav ? [f.replace(/\.ogg$/, '.wav')] : ['-c:a', 'libvorbis', '-q:a', '1', f])], { input: pcm, maxBuffer: 1 << 30 });
    if (ff.status) throw Error('ffmpeg: ' + ff.stderr);
    fs.writeFileSync(f + '.import', '[remap]\n\nimporter="keep"\n');
    idx[k] = { h, bucle: Math.round(r.bucle * SR) / SR, dur: Math.round(r.dur * 1000) / 1000 };
    fs.writeFileSync(idxF, JSON.stringify(idx, null, 1) + '\n');
    console.log(`${k.padEnd(14)} ${r.dur.toFixed(1).padStart(6)} s (bucle desde ${r.bucle.toFixed(2)} s) · pico ${r.pico.toFixed(2)} · ${r.rms.toFixed(1)} dBFS · ${(fs.statSync(f).size / 1024).toFixed(0)} KB · ${((Date.now() - t0) / 1000).toFixed(1)} s`);
  }
  for (const k of Object.keys(idx)) if (!lista.some(([x]) => x === k)) { delete idx[k]; for (const e of ['.ogg', '.ogg.import']) fs.rmSync(path.join(sal, k + e), { force: true }); }
  fs.writeFileSync(idxF, JSON.stringify(idx, null, 1) + '\n');
  if (AVISOS.length) console.log('avisos (nota larga a un semitono del acorde):\n  ' + [...new Set(AVISOS)].join('\n  '));
}
if (require.main === module) main();
module.exports = { compila, render, TEMAS, E };
