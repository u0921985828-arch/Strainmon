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
const BG = process.argv[7] || 'black'; // 'black' (flood-fill) | 'magenta' (chroma)
const isMag = (r, g, b) => r > 135 && b > 105 && g < r - 40 && g < b - 28;

if (BG === 'magenta') {
  for (let i = 0; i < W * H; i++) { const o = i * 4; if (isMag(data[o], data[o + 1], data[o + 2])) data[o + 3] = 0; }
  // limpiar halo rosado
  for (let i = 0; i < W * H; i++) { const o = i * 4; if (data[o + 3] === 0) continue; const r = data[o], g = data[o + 1], b = data[o + 2]; if (r > 130 && b > 110 && g < r - 25 && g < b - 18) data[o + 3] = 0; }
} else {
  // flood-fill desde el marco (fondo negro)
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
}

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
let use;
if (merged.length === N) use = merged;
else {
  // fallback: N-1 cortes ajustados al hueco real (mínima densidad) cerca de cada límite ideal
  let gx0 = W, gx1 = 0;
  for (let x = 0; x < W; x++) if (colFilled[x] > 2) { if (x < gx0) gx0 = x; if (x > gx1) gx1 = x; }
  const span = (gx1 - gx0 + 1) / N;
  const cuts = [gx0 - 1];
  for (let i = 1; i < N; i++) {
    const ideal = Math.round(gx0 + i * span);
    const win = Math.round(span * 0.38);
    let best = ideal, bestV = Infinity;
    for (let x = ideal - win; x <= ideal + win; x++) {
      if (x <= cuts[cuts.length - 1] + 4 || x >= gx1) continue;
      if (colFilled[x] < bestV) { bestV = colFilled[x]; best = x; }
    }
    cuts.push(best);
  }
  cuts.push(gx1 + 1);
  use = [];
  for (let i = 0; i < N; i++) use.push([cuts[i] + 1, cuts[i + 1] - 1]);
  console.log(`  -> fallback ajustado a huecos: cortes ${cuts.slice(1, -1).join(',')}`);
}

// Modo 'grow' (secuencia de crecimiento): TODAS las fases con la MISMA escala
// y base comun, para que la maceta sea identica y solo crezca la planta.
// Extremo vertical global (base = maceta alineada; techo = planta mas alta).
let gTop = H, gBase = -1;
for (let i = 0; i < W * H; i++) if (data[i * 4 + 3] > 20) { const y = (i / W) | 0; if (y < gTop) gTop = y; if (y > gBase) gBase = y; }
const commonH = gBase - gTop + 1;
const commonW = Math.max(...use.map(b => b[1] - b[0] + 1));
const scale = TARGET_H / commonH;                 // MISMA escala para las 5

async function saveGrow(bx, i) {
  const bw = bx[1] - bx[0] + 1;
  // centra el bloque (la maceta esta centrada) en un lienzo de ancho comun
  const padL = ((commonW - bw) / 2) | 0;
  const canvas = Buffer.alloc(commonW * commonH * 4, 0);
  for (let y = 0; y < commonH; y++) for (let x = 0; x < bw; x++) {
    const src = ((gTop + y) * W + (bx[0] + x)) * 4;
    const dst = (y * commonW + (padL + x)) * 4;
    canvas[dst] = data[src]; canvas[dst + 1] = data[src + 1]; canvas[dst + 2] = data[src + 2]; canvas[dst + 3] = data[src + 3];
  }
  const outW = Math.round(commonW * scale), outH = Math.round(commonH * scale);
  const buf = await sharp(canvas, { raw: { width: commonW, height: commonH, channels: 4 } })
    .resize(outW, outH, { kernel: 'lanczos3' })
    .png({ palette: true }).toBuffer();
  const out = path.join(outDir, `${prefix}_${i + 1}.png`);
  fs.writeFileSync(out, buf);
  console.log('✓', path.basename(out), outW + 'x' + outH, (buf.length / 1024).toFixed(1) + 'KB');
}
for (let i = 0; i < use.length; i++) await saveGrow(use[i], i);
