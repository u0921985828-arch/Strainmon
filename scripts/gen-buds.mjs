#!/usr/bin/env node
/* Cogollo (bud) por genética: RECORTE de la cola/flor superior del RETRATO real
   de la planta (assets/strains/<id>.png). Icono compacto para la Guía de cruces
   y menús. Salida: src/budart.js (PH.budart, data-URIs por id). */
import fs from 'node:fs'; import sharp from 'sharp';

const w = { PH: {} }; global.window = w; await import('../src/species-data.js');
const SPECIES = w.PH.speciesData;
const SRC = 'assets/strains';
const OUT = 44;   // lienzo final del icono

// bbox de contenido (alfa) de un buffer RGBA raw
function bbox(data, W, H, C) {
  let x0 = W, y0 = H, x1 = -1, y1 = -1;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    if (data[(y * W + x) * C + 3] > 24) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
  }
  return { x0, y0, x1, y1, w: x1 - x0 + 1, h: y1 - y0 + 1 };
}

async function budOf(id) {
  const src = `${SRC}/${id}.png`;
  if (!fs.existsSync(src)) return null;
  const base = sharp(src).ensureAlpha();
  const { data, info } = await base.raw().toBuffer({ resolveWithObject: true });
  const { width: W, height: H, channels: C } = info;
  const b = bbox(data, W, H, C);
  // Región de la COLA: franja superior central de la planta (la flor/cogollo),
  // por encima de las ramas bajas y la maceta.
  const colaTop = b.y0;
  const colaH = Math.max(8, Math.round(b.h * 0.40));
  const colaW = Math.max(8, Math.round(b.w * 0.58));
  const cx = Math.round(b.x0 + b.w / 2);
  const left = Math.max(0, cx - Math.round(colaW / 2));
  const region = { left, top: colaTop, width: Math.min(colaW, W - left), height: Math.min(colaH, H - colaTop) };
  // recorte -> re-trim al contenido -> encuadre cuadrado con margen -> OUT px
  const cut = await sharp(src).extract(region).png().toBuffer();
  const cm = await sharp(cut).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const t = bbox(cm.data, cm.info.width, cm.info.height, cm.info.channels);
  if (t.x1 < 0) return null;
  const tight = await sharp(cut).extract({ left: t.x0, top: t.y0, width: t.w, height: t.h }).toBuffer();
  const side = Math.max(t.w, t.h);
  const pad = Math.round(side * 0.12);
  const canvas = side + pad * 2;
  const framed = await sharp({ create: { width: canvas, height: canvas, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([{ input: tight, left: Math.round((canvas - t.w) / 2), top: Math.round((canvas - t.h) / 2) }])
    .png().toBuffer();
  return sharp(framed).resize(OUT, OUT, { kernel: 'nearest' }).png().toBuffer();
}

let count = 0, missing = 0; const DATA = {};
for (const s of SPECIES) {
  const buf = await budOf(s.id);
  if (!buf) { missing++; continue; }
  DATA[s.id] = 'data:image/png;base64,' + buf.toString('base64'); count++;
}
const lines = Object.keys(DATA).map(k => `    "${k}": "${DATA[k]}",`).join('\n');
fs.writeFileSync('src/budart.js', `/* STRAINMON — budart.js (cogollo por genética = recorte de la cola del retrato real). Generado: scripts/gen-buds.mjs */
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
console.log(`budart.js -> ${count} cogollos (${missing} sin retrato), ${(Buffer.byteLength(lines) / 1024).toFixed(0)} KB`);

// preview
const sc = 3, per = 12, names = Object.keys(DATA), rows = Math.ceil(names.length / per), comps = [];
for (let i = 0; i < names.length; i++) { const b64 = DATA[names[i]].split(',')[1]; const buf = await sharp(Buffer.from(b64, 'base64')).resize(OUT * sc, OUT * sc, { kernel: 'nearest' }).png().toBuffer(); comps.push({ input: buf, left: (i % per) * (OUT * sc + 4), top: ((i / per) | 0) * (OUT * sc + 4) }); }
await sharp({ create: { width: per * (OUT * sc + 4), height: rows * (OUT * sc + 4), channels: 4, background: { r: 24, g: 20, b: 26, alpha: 1 } } }).composite(comps).png().toFile('/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/buds.png');
console.log('preview -> buds.png');
