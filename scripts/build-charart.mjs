#!/usr/bin/env node
/* Regenera src/charart.js con el personaje nuevo (PixelLab, 8 dir, 140²).
   El iso usa 4 diagonales: 1=SE 2=SW 3=NW 4=NE -> south-east/south-west/
   north-west/north-east. El jugador va en color original; cada NPC es un
   recolor (hue) del MISMO personaje para mantener un estilo coherente. */
import fs from 'node:fs'; import sharp from 'sharp';

const SRC = process.argv[2] || '/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/char3/Personajes_para_juegos_retro_pixel_cannabis/rotations';
const TARGET_H = 88;   // alto final; el iso lo escala 1/round(88/42)=1/2 -> ~44px

// dir iso -> fichero de rotación
const DIR = { 1: 'south-east', 2: 'south-west', 3: 'north-west', 4: 'north-east' };
// jugador original; NPCs recoloreados (hue en grados)
const ROLES = {
  player: null,
  dealer: { hue: 265, saturation: 1.05 },
  neighbor: { hue: 35, saturation: 1.1 },
  botanist: { hue: 190, saturation: 1.0 },
  merchant: { hue: 90, saturation: 1.05 },
  customer1: { hue: 150, saturation: 1.0 },
  customer2: { hue: 320, saturation: 1.05 },
  walker: { hue: 20, saturation: 1.1 },
};

// 1) bbox de contenido común (unión) a partir del alfa de las 4 rotaciones
async function alphaBBox(file) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width: w, height: h, channels: c } = info;
  let x0 = w, y0 = h, x1 = 0, y1 = 0;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    if (data[(y * w + x) * c + 3] > 12) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
  }
  return { x0, y0, x1, y1 };
}

let U = { x0: 1e9, y0: 1e9, x1: -1, y1: -1 };
for (const d of Object.values(DIR)) {
  const bb = await alphaBBox(`${SRC}/${d}.png`);
  U = { x0: Math.min(U.x0, bb.x0), y0: Math.min(U.y0, bb.y0), x1: Math.max(U.x1, bb.x1), y1: Math.max(U.y1, bb.y1) };
}
const region = { left: U.x0, top: U.y0, width: U.x1 - U.x0 + 1, height: U.y1 - U.y0 + 1 };
console.log('bbox común', region);

// 2) genera data-URIs por rol y dirección
const DATA = {};
for (const [role, mod] of Object.entries(ROLES)) {
  for (const [idx, d] of Object.entries(DIR)) {
    let img = sharp(`${SRC}/${d}.png`).extract(region).resize({ height: TARGET_H, kernel: 'nearest' });
    if (mod) img = img.modulate(mod);
    const buf = await img.png().toBuffer();
    DATA[`${role}_${idx}`] = 'data:image/png;base64,' + buf.toString('base64');
  }
}

// 3) reescribe src/charart.js (cabecera + DATA + API original)
const lines = Object.keys(DATA).map(k => `    "${k}": "${DATA[k]}",`).join('\n');
const out = `/* STRAINMON — charart.js (personajes iso, 4 dir, inline base64). Claves "<rol>_<1..4>" (1=SE 2=SW 3=NW 4=NE).
   Personaje base PixelLab (arte propio del usuario); NPCs = recolor por hue del mismo. Generado: scripts/build-charart.mjs */
(function (PH) {
  'use strict';
  const DATA = {
${lines}
  };
  const IDX = { SE: 1, SW: 2, NW: 3, NE: 4 };
  const images = {};
  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }
  function has(role) { return !!DATA[role + '_1']; }
  function key(role, dir) { return role + '_' + (IDX[dir] || 1); }
  function img(role, dir) { return images[key(role, dir)] || null; }
  PH.charart = { DATA, preload, has, key, img };
})(window.PH = window.PH || {});
`;
fs.writeFileSync('src/charart.js', out);
const kb = (Buffer.byteLength(out) / 1024).toFixed(0);
console.log(`charart.js -> ${Object.keys(DATA).length} sprites (${Object.keys(ROLES).length} roles), ${kb} KB`);
