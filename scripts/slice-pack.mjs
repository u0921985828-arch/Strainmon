#!/usr/bin/env node
/* Extrae sprites individuales de las hojas-catálogo (fondo negro + etiquetas).
   Componentes conexos por color (ignora texto pequeño), recorta, hace el negro
   transparente y guarda PNGs + preview. Uso: node scripts/slice-pack.mjs <idx> */
import fs from 'node:fs'; import sharp from 'sharp';

const idx = process.argv[2];
const OUTDIR = 'assets/ref/extracted';
fs.mkdirSync(OUTDIR, { recursive: true });
const sheets = idx != null ? [Number(idx)] : [...Array(10).keys()];

for (const n of sheets) {
  const file = `assets/ref/pack/sheet_${String(n).padStart(2, '0')}.png`;
  if (!fs.existsSync(file)) continue;
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const W = info.width, H = info.height, C = info.channels;
  const content = new Uint8Array(W * H);
  for (let i = 0; i < W * H; i++) {
    const o = i * C, r = data[o], g = data[o + 1], b = data[o + 2], a = data[o + 3];
    // contenido = no-negro y no-casi-blanco puro (texto de etiqueta)
    const sum = r + g + b, white = r > 210 && g > 210 && b > 210 && Math.abs(r - g) < 24 && Math.abs(g - b) < 24;
    content[i] = (a > 24 && sum > 46 && !white) ? 1 : 0;
  }
  // componentes conexos (8-conn), flood-fill iterativo
  const lab = new Int32Array(W * H).fill(-1);
  const comps = [];
  const stack = [];
  for (let s = 0; s < W * H; s++) {
    if (!content[s] || lab[s] >= 0) continue;
    const id = comps.length; let minx = W, miny = H, maxx = 0, maxy = 0, area = 0;
    stack.push(s); lab[s] = id;
    while (stack.length) {
      const p = stack.pop(), px = p % W, py = (p / W) | 0;
      area++; if (px < minx) minx = px; if (px > maxx) maxx = px; if (py < miny) miny = py; if (py > maxy) maxy = py;
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const nx = px + dx, ny = py + dy; if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
        const q = ny * W + nx; if (content[q] && lab[q] < 0) { lab[q] = id; stack.push(q); }
      }
    }
    comps.push({ minx, miny, maxx, maxy, area, w: maxx - minx + 1, h: maxy - miny + 1 });
  }
  // sprites = componentes grandes (texto queda fuera por área)
  let sprites = comps.filter(c => c.area > 2200 && c.w > 34 && c.h > 34);
  // fusiona cajas muy solapadas (partes sueltas de un mismo sprite)
  sprites.sort((a, b) => a.minx - b.minx || a.miny - b.miny);
  const merged = [];
  for (const c of sprites) {
    const hit = merged.find(m => !(c.minx > m.maxx + 8 || c.maxx < m.minx - 8 || c.miny > m.maxy + 8 || c.maxy < m.miny - 8));
    if (hit) { hit.minx = Math.min(hit.minx, c.minx); hit.miny = Math.min(hit.miny, c.miny); hit.maxx = Math.max(hit.maxx, c.maxx); hit.maxy = Math.max(hit.maxy, c.maxy); }
    else merged.push({ ...c });
  }
  // orden lectura (fila, luego columna)
  merged.sort((a, b) => (a.miny - b.miny > 40 ? a.miny - b.miny : a.minx - b.minx));
  let k = 0;
  for (const m of merged) {
    const pad = 2;
    const left = Math.max(0, m.minx - pad), top = Math.max(0, m.miny - pad);
    const width = Math.min(W - left, m.w + pad * 2), height = Math.min(H - top, m.h + pad * 2);
    // negro -> transparente
    const buf = await sharp(file).extract({ left, top, width, height }).ensureAlpha().raw().toBuffer();
    for (let i = 0; i < width * height; i++) { const o = i * 4; if (buf[o] + buf[o + 1] + buf[o + 2] < 30) buf[o + 3] = 0; }
    await sharp(buf, { raw: { width, height, channels: 4 } }).png().toFile(`${OUTDIR}/s${String(n).padStart(2, '0')}_${String(k).padStart(2, '0')}.png`);
    k++;
  }
  console.log(`sheet ${n}: ${merged.length} sprites`);
  // preview
  const cols = 6, cell = 200, comps2 = [];
  for (let i = 0; i < merged.length; i++) { const bufp = await sharp(`${OUTDIR}/s${String(n).padStart(2, '0')}_${String(i).padStart(2, '0')}.png`).resize(cell - 8, cell - 8, { fit: 'inside' }).png().toBuffer(); comps2.push({ input: bufp, left: (i % cols) * cell + 4, top: ((i / cols) | 0) * cell + 4 }); }
  const rows = Math.ceil(merged.length / cols);
  await sharp({ create: { width: cols * cell, height: Math.max(1, rows) * cell, channels: 4, background: { r: 30, g: 30, b: 36, alpha: 1 } } }).composite(comps2).png().toFile(`/tmp/claude-0/-home-user-Strainmon/0f1a7ef5-8d47-53c6-8255-3b41a3c54115/scratchpad/slice_${n}.png`);
}
console.log('done -> ' + OUTDIR);
