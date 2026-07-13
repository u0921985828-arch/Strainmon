#!/usr/bin/env node
/* ============================================================
   Strainmon — post-proceso de sprites generados
   chroma-key magenta -> transparencia, recorte a contenido,
   relleno cuadrado, escala a tamaño canónico, cuantizado.
   Uso: node scripts/post-sprites.mjs <inDir> <outDir> [size=128]
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const inDir = process.argv[2] || 'assets/gen';
const outDir = process.argv[3] || 'assets/strains';
const SIZE = parseInt(process.argv[4] || '128', 10);
const MODE = process.argv[5] || 'square';   // 'square' (rellena a SIZE²) | 'fit' (recorta al contorno, lado mayor = SIZE)
fs.mkdirSync(outDir, { recursive: true });

// Magenta/rosa: el verde es claramente el canal menor y R,B son altos.
function isMagenta(r, g, b) { return r > 135 && b > 105 && g < r - 40 && g < b - 28; }

async function process1(file) {
  const src = path.join(inDir, file);
  const { data, info } = await sharp(src).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width: W, height: H } = info;
  // 1) chroma-key + bbox
  let minX = W, minY = H, maxX = -1, maxY = -1;
  for (let i = 0; i < W * H; i++) {
    const o = i * 4;
    const r = data[o], g = data[o + 1], b = data[o + 2];
    let a = data[o + 3];
    if (a < 20 || isMagenta(r, g, b)) { data[o + 3] = 0; continue; }
    const x = i % W, y = (i / W) | 0;
    if (x < minX) minX = x; if (x > maxX) maxX = x;
    if (y < minY) minY = y; if (y > maxY) maxY = y;
  }
  if (maxX < 0) throw new Error('vacío tras chroma');
  // limpiar halo rosado en bordes (pixeles semi-magenta)
  for (let i = 0; i < W * H; i++) {
    const o = i * 4; if (data[o + 3] === 0) continue;
    const r = data[o], g = data[o + 1], b = data[o + 2];
    if (r > 130 && b > 110 && g < r - 25 && g < b - 18) data[o + 3] = 0;
  }
  const cw = maxX - minX + 1, ch = maxY - minY + 1;
  let pipe = sharp(Buffer.from(data), { raw: { width: W, height: H, channels: 4 } })
    .extract({ left: minX, top: minY, width: cw, height: ch });

  if (MODE === 'fit') {
    // recorta a contorno, escala el lado mayor a SIZE, mantiene proporción
    pipe = pipe.resize({ width: cw >= ch ? SIZE : null, height: ch > cw ? SIZE : null, fit: 'inside', kernel: 'lanczos3' });
  } else {
    const side = Math.max(cw, ch);
    const padX = ((side - cw) / 2) | 0, padY = ((side - ch) / 2) | 0;
    pipe = pipe.extend({ top: padY, bottom: side - ch - padY, left: padX, right: side - cw - padX, background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .resize(SIZE, SIZE, { kernel: 'lanczos3' });
  }
  const cropped = await pipe.png({ palette: true, quality: 90, effort: 8 }).toBuffer();

  const out = path.join(outDir, file);
  fs.writeFileSync(out, cropped);
  return cropped.length;
}

const files = fs.readdirSync(inDir).filter(f => f.endsWith('.png'));
let total = 0;
for (const f of files) {
  try { const n = await process1(f); total += n; console.log('✓', f, (n / 1024).toFixed(1) + ' KB'); }
  catch (e) { console.error('✗', f, e.message); }
}
console.log(`Listo: ${files.length} sprites, ${(total / 1024).toFixed(0)} KB total en ${outDir}`);
