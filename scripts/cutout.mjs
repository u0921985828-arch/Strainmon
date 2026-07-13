#!/usr/bin/env node
/* ============================================================
   Strainmon — recorte robusto de sprites generados por IA.
   Robusto a los caprichos del modelo:
     · auto-detecta el color de fondo por los bordes (magenta, teal, lo que sea),
     · lo vuelve transparente con tolerancia + limpia halo,
     · se queda SOLO con la figura más grande (descarta turnarounds/figuras extra),
     · recorta al contorno de esa figura y escala al tamaño canónico.
   Uso: node scripts/cutout.mjs <inDir> <outDir> [size=80] [mode=fit|square]
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const inDir = process.argv[2];
const outDir = process.argv[3];
const SIZE = parseInt(process.argv[4] || '80', 10);
const MODE = process.argv[5] || 'fit';
if (!inDir || !outDir) { console.error('uso: cutout.mjs <inDir> <outDir> [size] [mode]'); process.exit(1); }
fs.mkdirSync(outDir, { recursive: true });

const dist2 = (r, g, b, R, G, B) => (r - R) ** 2 + (g - G) ** 2 + (b - B) ** 2;

// Color de fondo = moda de los píxeles del borde.
function detectBg(data, W, H) {
  const counts = new Map();
  const add = (o) => { const k = (data[o] >> 3 << 10) | (data[o + 1] >> 3 << 5) | (data[o + 2] >> 3); counts.set(k, (counts.get(k) || 0) + 1); };
  for (let x = 0; x < W; x++) { add((x) * 4); add(((H - 1) * W + x) * 4); }
  for (let y = 0; y < H; y++) { add((y * W) * 4); add((y * W + W - 1) * 4); }
  let best = 0, bk = 0;
  for (const [k, c] of counts) if (c > best) { best = c; bk = k; }
  return [((bk >> 10) & 31) << 3, ((bk >> 5) & 31) << 3, (bk & 31) << 3];
}

async function process1(file) {
  const src = path.join(inDir, file);
  const { data, info } = await sharp(src).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width: W, height: H } = info;
  const [bR, bG, bB] = detectBg(data, W, H);
  // Magenta explícito también cuenta como fondo (por si el borde no lo captó).
  const isMagenta = (r, g, b) => r > 135 && b > 105 && g < r - 40 && g < b - 28;
  const TOL = 46 * 46 * 3; // tolerancia de color al fondo
  const fg = new Uint8Array(W * H); // 1 = primer plano
  for (let i = 0; i < W * H; i++) {
    const o = i * 4;
    const r = data[o], g = data[o + 1], b = data[o + 2], a = data[o + 3];
    const isBg = a < 20 || isMagenta(r, g, b) || dist2(r, g, b, bR, bG, bB) < TOL;
    fg[i] = isBg ? 0 : 1;
  }
  // Componentes conexas (8-conn), quédate con la mayor.
  const label = new Int32Array(W * H).fill(0);
  const stack = new Int32Array(W * H);
  let cur = 0, bestLbl = 0, bestSize = 0;
  const sizes = [0];
  for (let i = 0; i < W * H; i++) {
    if (!fg[i] || label[i]) continue;
    cur++; let sp = 0; stack[sp++] = i; label[i] = cur; let sz = 0;
    while (sp) {
      const p = stack[--sp]; sz++;
      const x = p % W, y = (p / W) | 0;
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        if (!dx && !dy) continue;
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
        const np = ny * W + nx;
        if (fg[np] && !label[np]) { label[np] = cur; stack[sp++] = np; }
      }
    }
    sizes[cur] = sz;
    if (sz > bestSize) { bestSize = sz; bestLbl = cur; }
  }
  if (!bestLbl) throw new Error('sin primer plano');
  // Alpha final: solo la componente mayor; bbox de esa componente.
  let minX = W, minY = H, maxX = -1, maxY = -1;
  for (let i = 0; i < W * H; i++) {
    if (label[i] === bestLbl) {
      data[i * 4 + 3] = 255;
      const x = i % W, y = (i / W) | 0;
      if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y;
    } else { data[i * 4 + 3] = 0; }
  }
  const cw = maxX - minX + 1, ch = maxY - minY + 1;
  let pipe = sharp(Buffer.from(data), { raw: { width: W, height: H, channels: 4 } })
    .extract({ left: minX, top: minY, width: cw, height: ch });
  if (MODE === 'square') {
    const side = Math.max(cw, ch), px = ((side - cw) / 2) | 0, py = ((side - ch) / 2) | 0;
    pipe = pipe.extend({ top: py, bottom: side - ch - py, left: px, right: side - cw - px, background: { r: 0, g: 0, b: 0, alpha: 0 } }).resize(SIZE, SIZE, { kernel: 'nearest' });
  } else {
    pipe = pipe.resize({ width: cw >= ch ? SIZE : null, height: ch > cw ? SIZE : null, fit: 'inside', kernel: 'nearest' });
  }
  const out = await pipe.png({ palette: true, quality: 90, effort: 8 }).toBuffer();
  fs.writeFileSync(path.join(outDir, file), out);
  return out.length;
}

const files = fs.readdirSync(inDir).filter(f => f.endsWith('.png'));
let ok = 0;
for (const f of files) {
  try { const n = await process1(f); ok++; console.log('✓', f, (n / 1024).toFixed(1) + ' KB'); }
  catch (e) { console.error('✗', f, e.message); }
}
console.log(`Listo: ${ok}/${files.length} en ${outDir}`);
