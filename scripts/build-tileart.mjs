/* Empaqueta los tiles de suelo iso extraídos en src/tileart.js (base64). */
import fs from 'node:fs'; import sharp from 'sharp';
const MAP = { grass_a: 0, pavement: 1, zebra: 2, grass_c: 3, road: 4, plot_a: 5, grass_b: 6, road_x: 7, plot_b: 8, farmland: 9, road_corner: 10, plot_c: 11 };
const MAXW = 128;
const DATA = {};
for (const [name, idx] of Object.entries(MAP)) {
  const f = `assets/ref/extracted/s01_${String(idx).padStart(2, '0')}.png`;
  if (!fs.existsSync(f)) { console.warn('falta', f); continue; }
  const buf = await sharp(f).resize({ width: MAXW, fit: 'inside', withoutEnlargement: true }).png({ compressionLevel: 9 }).toBuffer();
  DATA[name] = 'data:image/png;base64,' + buf.toString('base64');
}
const lines = Object.keys(DATA).map(k => `    "${k}": "${DATA[k]}",`).join('\n');
const out = [
  '/* STRAINMON — tileart.js (tiles de suelo iso del pack). Generado: scripts/build-tileart.mjs */',
  '(function (PH) {',
  "  'use strict';",
  '  const DATA = {',
  lines,
  '  };',
  '  const images = {};',
  '  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }',
  '  function has(k) { return !!DATA[k]; }',
  '  function img(k) { return images[k] || null; }',
  '  PH.tileart = { DATA, preload, has, img };',
  '})(window.PH = window.PH || {});',
  '',
].join('\n');
fs.writeFileSync('src/tileart.js', out);
console.log('tileart.js ->', Object.keys(DATA).length, 'tiles,', (Buffer.byteLength(lines) / 1024 | 0), 'KB');
