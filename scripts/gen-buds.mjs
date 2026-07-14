#!/usr/bin/env node
/* Cogollo (bud) por genética: icono compacto para la Guía de cruces y menús.
   Arte 100% procedural propio, teñido por el perfil de color de cada cepa.
   Salida: src/budart.js (PH.budart, data-URIs por id). */
import fs from 'node:fs'; import sharp from 'sharp';

const w = { PH: {} }; global.window = w; await import('../src/species-data.js');
const SPECIES = w.PH.speciesData;

const S = 44;
const hex = h => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
const COLORS = {
  verde: '#3f8f3a', lima: '#8fca4a', ambar: '#d99a3a', purpura: '#7a3f9a', violeta: '#a06fd6',
  carmesi: '#b03a4a', azur: '#3a6ea5', turquesa: '#3aa58f', oro: '#e0b23c', rosa: '#d97aa0',
  magenta: '#c03a8a', obsidiana: '#332c3a', blanco: '#dcdcc8',
};
const mix = (a, b, t) => a.map((v, i) => Math.round(v + (b[i] - v) * t));
const shade = (c, k) => c.map(v => Math.max(0, Math.min(255, Math.round(v * (1 + k)))));

const B = () => new Uint8Array(S * S * 4);
const px = (b, x, y, c, a = 255) => { x |= 0; y |= 0; if (x < 0 || y < 0 || x >= S || y >= S) return; const o = (y * S + x) * 4; b[o] = c[0]; b[o + 1] = c[1]; b[o + 2] = c[2]; b[o + 3] = a; };
const disc = (b, cx, cy, r, c) => { for (let y = -r; y <= r; y++) for (let x = -r; x <= r; x++) if (x * x + y * y <= r * r + 1) px(b, cx + x, cy + y, c); };
const rng = seed => { let a = seed >>> 0 || 1; return () => { a = (a * 1664525 + 1013904223) >>> 0; return a / 4294967296; }; };

function bud(strain) {
  const b = B();
  const cols = (strain.profile && strain.profile.colors) || [{ key: 'verde', w: 1 }];
  const top = hex(COLORS[cols[0].key] || COLORS.verde);
  const green = hex(COLORS.verde);
  const main = mix(green, top, 0.55);           // verde base teñido por el color dominante
  const dark = shade(main, -0.32), lite = shade(main, 0.24);
  const pistil = hex(COLORS.ambar), frost = [235, 235, 220];
  let seed = 0; for (const ch of strain.id) seed = (seed * 31 + ch.charCodeAt(0)) >>> 0;
  const r = rng(seed);
  // tallo
  for (let y = 30; y < 40; y++) { px(b, 22, y, shade(green, -0.4)); px(b, 23, y, shade(green, -0.5)); }
  // racimo de cálices: lágrima (ancha arriba, estrecha abajo)
  const rows = 9;
  for (let i = 0; i < rows; i++) {
    const cy = 8 + i * 3.2;
    const spread = Math.max(2, 9 - Math.abs(i - 2) * 1.1);
    const n = 3 + (spread | 0);
    for (let k = 0; k < n; k++) {
      const cx = 22 + (r() * 2 - 1) * spread;
      const rad = 3 + (r() * 2 | 0);
      disc(b, cx, cy, rad, r() < 0.4 ? dark : main);
      disc(b, cx - 1, cy - 1, Math.max(1, rad - 2), lite);
    }
  }
  // pistilos (pelos ámbar)
  for (let i = 0; i < 7; i++) {
    const x = 8 + (r() * 28 | 0), y = 8 + (r() * 20 | 0);
    px(b, x, y, pistil); px(b, x + (r() < 0.5 ? 1 : -1), y - 1, pistil); px(b, x, y - 2, shade(pistil, 0.2));
  }
  // escarcha (tricomas)
  for (let i = 0; i < 22; i++) px(b, 10 + (r() * 24 | 0), 7 + (r() * 24 | 0), frost, 200);
  return b;
}

let count = 0; const DATA = {};
for (const s of SPECIES) {
  const b = bud(s);
  const buf = await sharp(Buffer.from(b), { raw: { width: S, height: S, channels: 4 } }).png().toBuffer();
  DATA[s.id] = 'data:image/png;base64,' + buf.toString('base64'); count++;
}
const lines = Object.keys(DATA).map(k => `    "${k}": "${DATA[k]}",`).join('\n');
fs.writeFileSync('src/budart.js', `/* STRAINMON — budart.js (cogollo por genética, icono compacto). Procedural, teñido por perfil de color. Generado: scripts/gen-buds.mjs */
(function (PH) {
  'use strict';
  const DATA = {
${lines}
  };
  const images = {};
  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }
  function has(id) { return !!DATA[id]; }
  function uri(id) { return DATA[id] || null; }
  function img(id) { return images[id] || null; }
  PH.budart = { DATA, preload, has, uri, img };
})(window.PH = window.PH || {});
`);
console.log('budart.js ->', count, 'cogollos,', (Buffer.byteLength(lines) / 1024).toFixed(0), 'KB');

// preview
const sc = 3, per = 12, rowsP = Math.ceil(SPECIES.length / per), comps = [];
for (let i = 0; i < SPECIES.length; i++) { const bb = bud(SPECIES[i]); const buf = await sharp(Buffer.from(bb), { raw: { width: S, height: S, channels: 4 } }).resize(S * sc, S * sc, { kernel: 'nearest' }).png().toBuffer(); comps.push({ input: buf, left: (i % per) * (S * sc + 4), top: ((i / per) | 0) * (S * sc + 4) }); }
await sharp({ create: { width: per * (S * sc + 4), height: rowsP * (S * sc + 4), channels: 4, background: { r: 24, g: 20, b: 26, alpha: 1 } } }).composite(comps).png().toFile('/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/buds.png');
console.log('preview -> buds.png');
