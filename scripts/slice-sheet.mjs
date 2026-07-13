#!/usr/bin/env node
/* Recorta una lámina de N fases y elimina el fondo negro por flood-fill de bordes.
   Uso: node scripts/slice-sheet.mjs <archivo> <N> <outDir> <prefijo> [altura=128] */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const [file, Nraw, outDir, prefix, hraw] = process.argv.slice(2);
const N = parseInt(Nraw || '5', 10);
const TARGET_H = parseInt(hraw || '128', 10);
fs.mkdirSync(outDir, { recursive: true });

const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
const { width: W, height: H } = info;
const lum = (o) => (data[o] * 0.3 + data[o + 1] * 0.59 + data[o + 2] * 0.11);
const T = 42; // umbral de "negro"

// flood-fill desde el marco
const bg = new Uint8Array(W * H);
const stack = [];
const pushIf = (x, y) => {
  if (x < 0 || y < 0 || x >= W || y >= H) return;
  const i = y * W + x; if (bg[i]) return;
  if (lum(i * 4) < T) { bg[i] = 1; stack.push(i); }
};
for (let x = 0; x < W; x++) { pushIf(x, 0); pushIf(x, H - 1); }
for (let y = 0; y < H; y++) { pushIf(0, y); pushIf(W - 1, y); }
while (stack.length) {
  const i = stack.pop(); const x = i % W, y = (i / W) | 0;
  pushIf(x + 1, y); pushIf(x - 1, y); pushIf(x, y + 1); pushIf(x, y - 1);
}
for (let i = 0; i < W * H; i++) if (bg[i]) data[i * 4 + 3] = 0;

// columnas de contenido -> segmentar en N por huecos verticales vacíos
const colFilled = new Array(W).fill(0);
for (let x = 0; x < W; x++) { let c = 0; for (let y = 0; y < H; y++) if (data[(y * W + x) * 4 + 3] > 20) c++; colFilled[x] = c; }
// detecta bloques separados por columnas vacías
const blocks = [];
let start = -1;
for (let x = 0; x < W; x++) {
  const on = colFilled[x] > 2;
  if (on && start < 0) start = x;
  else if (!on && start >= 0) { blocks.push([start, x - 1]); start = -1; }
}
if (start >= 0) blocks.push([start, W - 1]);
// fusiona bloques minúsculos con el vecino
const merged = blocks.filter(b => b[1] - b[0] > 8);
console.log(`bloques detectados: ${merged.length} (esperados ${N})`);
const use = merged.length >= N ? merged.slice(0, N) : merged;

// bbox vertical global para alinear por la base (maceta)
async function saveBlock(bx, i) {
  let minY = H, maxY = -1;
  for (let x = bx[0]; x <= bx[1]; x++) for (let y = 0; y < H; y++) if (data[(y * W + x) * 4 + 3] > 20) { if (y < minY) minY = y; if (y > maxY) maxY = y; }
  const cw = bx[1] - bx[0] + 1, ch = maxY - minY + 1;
  const buf = await sharp(Buffer.from(data), { raw: { width: W, height: H, channels: 4 } })
    .extract({ left: bx[0], top: minY, width: cw, height: ch })
    .resize({ height: TARGET_H, fit: 'inside', kernel: 'lanczos3' })
    .png({ palette: true }).toBuffer();
  const out = path.join(outDir, `${prefix}_${i + 1}.png`);
  fs.writeFileSync(out, buf);
  const m = await sharp(buf).metadata();
  console.log('✓', path.basename(out), m.width + 'x' + m.height, (buf.length / 1024).toFixed(1) + 'KB');
}
for (let i = 0; i < use.length; i++) await saveBlock(use[i], i);
