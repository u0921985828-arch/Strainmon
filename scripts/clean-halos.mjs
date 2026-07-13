#!/usr/bin/env node
/* ============================================================
   Strainmon — limpieza de halo magenta (chroma residual)
   Elimina los píxeles rosa/magenta del contorno que dejó el
   chroma-key del generador (post-sprites.mjs), haciéndolos
   transparentes. Solo toca píxeles de BORDE (con algún vecino
   ya transparente): nunca perfora el interior del sprite, así
   que no daña detalles de color legítimos.
   Uso:  node scripts/clean-halos.mjs [dir ...]   (por defecto, todos los assets)
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const DIRS = process.argv.slice(2);
const TARGETS = DIRS.length ? DIRS
  : ['assets/plants', 'assets/sprites', 'assets/chars', 'assets/furni', 'assets/parts'];

// Rosa/magenta del chroma: R y B altos, G claramente el canal menor.
function isMagenta(r, g, b) { return r > 130 && b > 110 && g < r - 25 && g < b - 18; }

async function clean1(file) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width: W, height: H } = info;
  const at = (x, y) => data[(y * W + x) * 4 + 3];
  const edge = new Set();
  // 1) marca solo píxeles magenta que tocan transparencia (contorno)
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const o = (y * W + x) * 4;
    if (data[o + 3] <= 16) continue;
    if (!isMagenta(data[o], data[o + 1], data[o + 2])) continue;
    const border = x === 0 || y === 0 || x === W - 1 || y === H - 1
      || at(x - 1, y) <= 16 || at(x + 1, y) <= 16 || at(x, y - 1) <= 16 || at(x, y + 1) <= 16;
    if (border) edge.add(o);
  }
  if (!edge.size) return 0;
  for (const o of edge) data[o + 3] = 0;
  // re-encode en RGBA (sin re-cuantizar): conserva exactos los colores retenidos
  const out = await sharp(Buffer.from(data), { raw: { width: W, height: H, channels: 4 } })
    .png({ compressionLevel: 9 }).toBuffer();
  fs.writeFileSync(file, out);
  return edge.size;
}

let files = [];
for (const d of TARGETS) {
  if (!fs.existsSync(d)) continue;
  for (const f of fs.readdirSync(d).filter(f => f.endsWith('.png'))) files.push(path.join(d, f));
}
let changed = 0, pixels = 0;
for (const f of files) {
  try {
    const n = await clean1(f);
    if (n > 0) { changed++; pixels += n; console.log('✓', f, '—', n, 'px de halo eliminados'); }
  } catch (e) { console.error('✗', f, e.message); }
}
console.log(`\nListo: ${changed}/${files.length} sprites limpiados, ${pixels} px de halo en total.`);
