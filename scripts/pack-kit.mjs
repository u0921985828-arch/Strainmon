#!/usr/bin/env node
/* ============================================================
   Strainmon — empaquetador de kits.

   Toma las piezas sueltas generadas por gen-kit.mjs y produce:
     atlas.png    todas las piezas recortadas en una sola lámina
     atlas.json   metadatos + rectángulos de cada pieza
     atlas.js     lo mismo pero inline (PH.kitdata) para abrir sin servidor
     preview_<slot>.png  hoja de contacto por ranura, para revisar a ojo

   Limpieza automática: recorte al contenido y borrado de motas sueltas
   (islas de píxeles muy pequeñas que a veces deja el modelo).

   Uso: node scripts/pack-kit.mjs <kit> [--noclean] [--pad 1] [--width 512]
   Ajustes finos de colocación: crea assets/gen_kits/<kit>/anchors.json
     { "head": { "place": [32, 40], "parts": { "round": { "nudge": [0, -1] } } } }
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';
import { loadKit, outDirFor, rel, DIR_CODE } from './kit-lib.mjs';

const argv = process.argv.slice(2);
const flag = (n, def) => { const i = argv.indexOf('--' + n); return i < 0 ? def : (argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[i + 1] : true); };
const kitName = argv.find(a => !a.startsWith('--'));
if (!kitName) { console.log('Uso: node scripts/pack-kit.mjs <kit>'); process.exit(0); }

const kit = loadKit(kitName);
const dir = outDirFor(kit);
if (!fs.existsSync(dir)) { console.error('❌ no hay piezas generadas en ' + rel(dir)); process.exit(1); }
const CLEAN = !flag('noclean', false);
const PAD = parseInt(flag('pad', 1), 10);
const ATLAS_W = parseInt(flag('width', 512), 10);

const overrides = fs.existsSync(path.join(dir, 'anchors.json'))
  ? JSON.parse(fs.readFileSync(path.join(dir, 'anchors.json'), 'utf8')) : {};

/** Recorta al contenido y quita islas de píxeles menores al 4% de la mayor. */
async function trim(file) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const W = info.width, H = info.height, N = W * H;
  const solid = new Uint8Array(N);
  for (let i = 0; i < N; i++) solid[i] = data[i * 4 + 3] > 16 ? 1 : 0;

  if (CLEAN) {
    // etiquetado de componentes conexas (4-vecinos) y borrado de las mínimas
    const label = new Int32Array(N).fill(-1);
    const sizes = [];
    const stack = [];
    for (let i = 0; i < N; i++) {
      if (!solid[i] || label[i] >= 0) continue;
      const id = sizes.length; sizes.push(0); label[i] = id; stack.push(i);
      while (stack.length) {
        const p = stack.pop(); sizes[id]++;
        const x = p % W, y = (p / W) | 0;
        const push = (q, okx) => { if (okx && q >= 0 && q < N && solid[q] && label[q] < 0) { label[q] = id; stack.push(q); } };
        push(p + 1, x + 1 < W); push(p - 1, x > 0); push(p + W, y + 1 < H); push(p - W, y > 0);
      }
    }
    const biggest = sizes.length ? Math.max(...sizes) : 0;
    const minSize = Math.max(4, Math.round(biggest * 0.04));
    for (let i = 0; i < N; i++) {
      if (label[i] >= 0 && sizes[label[i]] < minSize) { solid[i] = 0; data[i * 4 + 3] = 0; }
    }
  }

  let x0 = W, y0 = H, x1 = -1, y1 = -1;
  for (let i = 0; i < N; i++) {
    if (!solid[i]) continue;
    const x = i % W, y = (i / W) | 0;
    if (x < x0) x0 = x; if (x > x1) x1 = x;
    if (y < y0) y0 = y; if (y > y1) y1 = y;
  }
  if (x1 < 0) return null;
  const w = x1 - x0 + 1, h = y1 - y0 + 1;
  const out = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) data.copy(out, y * w * 4, ((y0 + y) * W + x0) * 4, ((y0 + y) * W + x0 + w) * 4);
  return { raw: out, w, h, srcW: W, srcH: H };
}

// ---- recolectar piezas ----
const pieces = [];
for (const slot of kit.slots) {
  for (const part of slot.parts) {
    for (const d of (slot.dirs || kit.directions)) {
      const code = DIR_CODE[d];
      const file = path.join(dir, slot.id, `${part.id}_${code}.png`);
      if (!fs.existsSync(file)) continue;
      const t = await trim(file);
      if (!t) { console.warn('⚠️  vacía tras recortar:', rel(file)); continue; }
      pieces.push({ key: `${slot.id}__${part.id}__${code}`, slot: slot.id, part: part.id, dir: d, code, ...t });
    }
  }
}
if (!pieces.length) { console.error('❌ ninguna pieza que empaquetar. ¿Has ejecutado gen-kit.mjs?'); process.exit(1); }

// ---- empaquetado por estanterías ----
pieces.sort((a, b) => b.h - a.h || b.w - a.w);
const maxW = Math.max(ATLAS_W, ...pieces.map(p => p.w + PAD * 2));
let cx = PAD, cy = PAD, rowH = 0;
for (const p of pieces) {
  if (cx + p.w + PAD > maxW) { cx = PAD; cy += rowH + PAD; rowH = 0; }
  p.x = cx; p.y = cy;
  cx += p.w + PAD;
  rowH = Math.max(rowH, p.h);
}
const atlasH = cy + rowH + PAD;
const atlas = await sharp({ create: { width: maxW, height: atlasH, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
  .composite(pieces.map(p => ({ input: p.raw, raw: { width: p.w, height: p.h, channels: 4 }, left: p.x, top: p.y })))
  .png({ palette: true, effort: 8 }).toBuffer();
fs.writeFileSync(path.join(dir, 'atlas.png'), atlas);

// ---- metadatos ----
const slotMeta = kit.slots.map(s => {
  const ov = overrides[s.id] || {};
  return {
    id: s.id, title: s.title || s.id, z: s.z ?? 0,
    place: ov.place || s.place, anchor: ov.anchor || s.anchor || 'bottom-center',
    tint: s.tint || null, optional: !!s.optional, required: !!s.required,
    repeat: s.repeat || null, stackAfter: s.stackAfter || null, dirs: s.dirs || null,
    parts: s.parts.filter(p => pieces.some(q => q.slot === s.id && q.part === p.id))
      .map(p => ({
        id: p.id, title: p.title || p.id,
        nudge: (ov.parts?.[p.id]?.nudge) || null,
        dirNudge: (ov.parts?.[p.id]?.dirs) || null,
      })),
  };
}).filter(s => s.parts.length);

const frames = {};
for (const p of pieces) frames[p.key] = { x: p.x, y: p.y, w: p.w, h: p.h };

const data = {
  kit: kit.id, title: kit.title || kit.id, canvas: kit.canvas,
  directions: kit.directions, dirCode: DIR_CODE, tints: kit.tints || {},
  atlas: { width: maxW, height: atlasH, file: 'atlas.png' },
  slots: slotMeta, frames,
};
fs.writeFileSync(path.join(dir, 'atlas.json'), JSON.stringify(data, null, 1));

// versión inline: el laboratorio y el juego funcionan desde file:// sin servidor
const inline = { ...data, png: 'data:image/png;base64,' + atlas.toString('base64') };
fs.writeFileSync(path.join(dir, 'atlas.js'),
  `/* Strainmon — atlas del kit "${kit.id}" (generado por scripts/pack-kit.mjs; no editar a mano). */\n` +
  `(function (PH) { PH.kitdata = PH.kitdata || {}; PH.kitdata[${JSON.stringify(kit.id)}] = ${JSON.stringify(inline)}; })(window.PH = window.PH || {});\n`);

// ---- hojas de contacto por ranura ----
for (const s of slotMeta) {
  const list = pieces.filter(p => p.slot === s.id);
  const cell = Math.max(...list.map(p => Math.max(p.w, p.h))) + 8;
  const cols = Math.min(list.length, 8), rows = Math.ceil(list.length / cols);
  const sheet = await sharp({ create: { width: cell * cols, height: cell * rows, channels: 4, background: { r: 26, g: 30, b: 24, alpha: 1 } } })
    .composite(list.map((p, i) => ({
      input: p.raw, raw: { width: p.w, height: p.h, channels: 4 },
      left: (i % cols) * cell + ((cell - p.w) >> 1), top: ((i / cols) | 0) * cell + ((cell - p.h) >> 1),
    })))
    .png().toBuffer();
  fs.writeFileSync(path.join(dir, `preview_${s.id}.png`), sheet);
}

const combos = slotMeta.reduce((n, s) => n * (s.parts.length + (s.optional ? 1 : 0)), 1);
console.log(`📦 ${pieces.length} piezas → ${rel(path.join(dir, 'atlas.png'))} (${maxW}×${atlasH}, ${(atlas.length / 1024).toFixed(0)} KB)`);
console.log(`   metadatos: atlas.json + atlas.js · hojas de contacto: preview_<ranura>.png`);
console.log(`   combinaciones posibles por dirección: ${combos.toLocaleString('es-ES')}`);
console.log(`   pruébalo en tools/kit-lab.html`);
