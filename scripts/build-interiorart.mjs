/* Empaqueta mobiliario e interiores iso (sheets 3 y 9) en src/interiorart.js. */
import fs from 'node:fs'; import sharp from 'sharp';
// nombre -> [sheet, indice]
const MAP = {
  counter:   [3, 1],   // mostrador en L (dispensario)
  ivy:       [3, 2],   // panel de pared vegetal
  vitrina:   [3, 3],   // vitrina expositora
  ledbar:    [3, 4],   // lámpara LED colgante
  shelfjars: [3, 6],   // estantería con tarros
  ledoff:    [9, 0],   // foco LED apagado
  pot:       [9, 2],   // maceta grande vacía
  ledon:     [9, 5],   // foco LED encendido
  extractor: [9, 10],  // extractor / equipo de aire
  co2:       [9, 13],  // bombona de CO2
  tray:      [9, 15],  // bandeja hidropónica
  wallclean: [9, 12],  // esquina de pared limpia
  wallbrick: [9, 16],  // esquina de pared de ladrillo
  duct:      [9, 22],  // tubos de ventilación
  bench:     [9, 23],  // banco urbano
};
const MAXDIM = 190;
const DATA = {};
for (const [name, [sheet, idx]] of Object.entries(MAP)) {
  const f = `assets/ref/extracted/s${String(sheet).padStart(2, '0')}_${String(idx).padStart(2, '0')}.png`;
  if (!fs.existsSync(f)) { console.warn('falta', f); continue; }
  const buf = await sharp(f).resize({ width: MAXDIM, height: MAXDIM, fit: 'inside', withoutEnlargement: true }).png({ compressionLevel: 9 }).toBuffer();
  DATA[name] = 'data:image/png;base64,' + buf.toString('base64');
}
const lines = Object.keys(DATA).map(k => `    "${k}": "${DATA[k]}",`).join('\n');
const out = [
  '/* STRAINMON — interiorart.js (mobiliario e interiores iso del pack). Generado: scripts/build-interiorart.mjs */',
  '(function (PH) {',
  "  'use strict';",
  '  const DATA = {',
  lines,
  '  };',
  '  const images = {};',
  '  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }',
  '  function has(k) { return !!DATA[k]; }',
  '  function img(k) { return images[k] || null; }',
  '  PH.interiorart = { DATA, preload, has, img };',
  '})(window.PH = window.PH || {});',
  '',
].join('\n');
fs.writeFileSync('src/interiorart.js', out);
console.log('interiorart.js ->', Object.keys(DATA).length, 'piezas,', (Buffer.byteLength(lines) / 1024 | 0), 'KB');
