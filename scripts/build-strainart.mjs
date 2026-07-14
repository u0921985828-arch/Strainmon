#!/usr/bin/env node
/* ============================================================
   Strainmon — procesa los retratos de cepa al canon (128², maceta
   abajo, fondo transparente, cuantizado) y los incrusta inline en
   src/strainart.js. Fuente: PNGs 256px del pack (arg 1).
   Uso: node scripts/build-strainart.mjs <dirFuente> [genetics_stock.json]
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const SRC = process.argv[2];
const STOCK = process.argv[3] || path.join(SRC, 'genetics_stock.json');
const OUT_DIR = 'assets/strains';
const SIZE = 128, TOP_AIR = 6, BOT_MARGIN = 2;
fs.mkdirSync(OUT_DIR, { recursive: true });

const stock = JSON.parse(fs.readFileSync(STOCK, 'utf8'));
const ids = stock.strains.map(s => s.id);

async function process1(id) {
  const src = path.join(SRC, id + '.png');
  const { data, info } = await sharp(src).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width: W, height: H } = info;
  // bbox por alfa
  let minX = W, minY = H, maxX = -1, maxY = -1;
  for (let i = 0; i < W * H; i++) { if (data[i * 4 + 3] > 12) { const x = i % W, y = (i / W) | 0; if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y; } }
  if (maxX < 0) throw new Error('vacío');
  const cw = maxX - minX + 1, ch = maxY - minY + 1;
  // encajar dentro de (SIZE × (SIZE-TOP_AIR-BOT_MARGIN)) manteniendo proporción
  const boxH = SIZE - TOP_AIR - BOT_MARGIN, boxW = SIZE;
  const r = Math.min(boxW / cw, boxH / ch, 1 /* no ampliar por encima de 1× salvo si es pequeño */ + 4);
  const rw = Math.max(1, Math.round(cw * r)), rh = Math.max(1, Math.round(ch * r));
  const sprite = await sharp(Buffer.from(data), { raw: { width: W, height: H, channels: 4 } })
    .extract({ left: minX, top: minY, width: cw, height: ch })
    .resize(rw, rh, { kernel: 'lanczos3', fit: 'fill' })
    .png().toBuffer();
  // lienzo 128² transparente, sprite anclado abajo-centro
  const left = Math.round((SIZE - rw) / 2), top = SIZE - rh - BOT_MARGIN;
  const out = await sharp({ create: { width: SIZE, height: SIZE, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([{ input: sprite, left, top }])
    .png({ palette: true, quality: 90, effort: 8 }).toBuffer();
  fs.writeFileSync(path.join(OUT_DIR, id + '.png'), out);
  return out;
}

const entries = [];
let total = 0;
for (const id of ids) {
  try { const buf = await process1(id); entries.push([id, 'data:image/png;base64,' + buf.toString('base64')]); total += buf.length; }
  catch (e) { console.error('✗', id, e.message); }
}
const body = entries.map(([k, v]) => `    "${k}": "${v}",`).join('\n');
const js = `/* ============================================================
   STRAINMON — strainart.js  (retratos de cepa 128², inline base64)
   Generado por scripts/build-strainart.mjs desde el pack de 100 cepas.
   Un retrato por id de cepa (fenotipo "oficial" de la landrace/híbrido).
   ============================================================ */
(function (PH) {
  'use strict';
  const DATA = {
${body}
  };
  const images = {};
  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }
  function img(k) { return images[k] || null; }
  function uri(k) { return DATA[k] || null; }
  function has(k) { return !!DATA[k]; }
  function portrait(id) { return DATA[id] ? id : null; }
  PH.strainart = { DATA, preload, img, uri, has, portrait };
})(window.PH = window.PH || {});
`;
fs.writeFileSync('src/strainart.js', js);
console.log(`strainart.js: ${entries.length}/${ids.length} retratos, ${(total / 1024).toFixed(0)} KB (${(Buffer.byteLength(js) / 1024).toFixed(0)} KB con base64)`);
