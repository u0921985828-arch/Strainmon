/* Empaqueta los edificios iso extraídos (sheet 2) en src/buildingart.js. */
import fs from 'node:fs'; import sharp from 'sharp';
const MAP = { lab: 0, casa: 1, ayuntamiento: 2, dispensario: 3, estadio: 4, invernadero: 5 };
const MAXW = 240;
const DATA = {};
for (const [name, idx] of Object.entries(MAP)) {
  const f = `assets/ref/extracted/s02_${String(idx).padStart(2, '0')}.png`;
  if (!fs.existsSync(f)) { console.warn('falta', f); continue; }
  const buf = await sharp(f).resize({ width: MAXW, fit: 'inside', withoutEnlargement: true }).png({ compressionLevel: 9 }).toBuffer();
  DATA[name] = 'data:image/png;base64,' + buf.toString('base64');
}
const lines = Object.keys(DATA).map(k => `    "${k}": "${DATA[k]}",`).join('\n');
const out = [
  '/* STRAINMON — buildingart.js (edificios iso del pack). Generado: scripts/build-buildingart.mjs */',
  '(function (PH) {',
  "  'use strict';",
  '  const DATA = {',
  lines,
  '  };',
  '  const images = {};',
  '  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }',
  '  function has(k) { return !!DATA[k]; }',
  '  function img(k) { return images[k] || null; }',
  '  PH.buildingart = { DATA, preload, has, img };',
  '})(window.PH = window.PH || {});',
  '',
].join('\n');
fs.writeFileSync('src/buildingart.js', out);
console.log('buildingart.js ->', Object.keys(DATA).length, 'edificios,', (Buffer.byteLength(lines) / 1024 | 0), 'KB');
