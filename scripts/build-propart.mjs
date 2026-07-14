/* Empaqueta los sprites de atrezzo extraídos (assets/ref/extracted) en
   src/propart.js (base64 por nombre). Anclaje base-centro para billboard iso. */
import fs from 'node:fs'; import sharp from 'sharp';
const MAP = { fountain:0, palm:1, treeb:2, lamppost:3, bench:4, tree:5, fence:6, trash:7, fenceh:8, bush:9, sign:10 };
const MAXDIM = 180;   // los billboards se muestran pequeños; recorta peso sin perder nitidez
const DATA = {};
for (const [name, idx] of Object.entries(MAP)) {
  const f = `assets/ref/extracted/s00_${String(idx).padStart(2,'0')}.png`;
  if (!fs.existsSync(f)) { console.warn('falta', f); continue; }
  const buf = await sharp(f).resize({ width: MAXDIM, height: MAXDIM, fit: 'inside', withoutEnlargement: true }).png({ compressionLevel: 9 }).toBuffer();
  DATA[name] = 'data:image/png;base64,' + buf.toString('base64');
}
const lines = Object.keys(DATA).map(k => `    "${k}": "${DATA[k]}",`).join('\n');
fs.writeFileSync('src/propart.js', `/* STRAINMON — propart.js (atrezzo iso extraído del pack de sprites). Generado: scripts/build-propart.mjs */
(function (PH) {
  'use strict';
  const DATA = {
${lines}
  };
  const images = {};
  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }
  function has(k) { return !!DATA[k]; }
  function img(k) { return images[k] || null; }
  PH.propart = { DATA, preload, has, img };
})(window.PH = window.PH || {});
`);
console.log('propart.js ->', Object.keys(DATA).length, 'sprites,', (Buffer.byteLength(lines)/1024|0), 'KB');
