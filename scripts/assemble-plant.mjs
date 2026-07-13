#!/usr/bin/env node
/* ============================================================
   Strainmon — ensamblador de planta a partir de piezas
   Compone una planta completa desde assets/parts segun genetica.
   Prueba de concepto (render con sharp). Uso: node scripts/assemble-plant.mjs
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const P = 'assets/parts';
const load = (n) => fs.readFileSync(path.join(P, n + '.png'));

// hue objetivo por color de fenotipo (grados). El verde base ~110.
const HUE = { verde: 0, lima: -25, ambar: -70, oro: -60, purpura: 165, violeta: 185, carmesi: 230, rosa: 210, magenta: 200, azur: 95, turquesa: 60, obsidiana: 150, blanco: 0 };

async function prep(buf, { w, h, rotate = 0, flop = false, hue = 0, sat = 1, bright = 1 }) {
  let img = sharp(buf);
  const meta = await img.metadata();
  w = w ? Math.max(1, Math.round(w)) : null;
  h = h ? Math.max(1, Math.round(h)) : null;
  if (w || h) img = img.resize({ width: w, height: h, fit: 'inside', kernel: 'lanczos3' });
  if (hue || sat !== 1 || bright !== 1) img = img.modulate({ hue, saturation: sat, brightness: bright });
  if (flop) img = img.flop();
  if (rotate) img = img.rotate(rotate, { background: { r: 0, g: 0, b: 0, alpha: 0 } });
  const out = await img.png().toBuffer();
  const m = await sharp(out).metadata();
  return { buf: out, w: m.width, h: m.height };
}

// genotipo simplificado -> planta
async function assemble(g) {
  const W = 240, H = 320, cx = W / 2;
  const comps = [];
  const put = (p, left, top) => comps.push({ input: p.buf, left: Math.round(left), top: Math.round(top) });

  const leafName = g.leaf === 5 ? 'leaf_fan5_indica' : (g.leaf === 9 ? 'leaf_fan9' : 'leaf_fan7');
  const hue = HUE[g.color] ?? 0;

  // maceta
  const pot = await prep(load('pot_terracotta'), { w: 96 });
  const potTop = H - pot.h - 4;
  const soilY = potTop + 14;

  // tallo (altura segun g.altura 0..1)
  const stemH = Math.round(70 + g.altura * 150);
  const stem = await prep(load('stem_main'), { h: stemH });
  const stemTop = soilY - stemH + 6;
  put(stem, cx - stem.w / 2, stemTop);

  // nodos: pares de hojas + cogollos, de abajo a arriba
  const nodes = Math.max(3, Math.round(3 + g.altura * 4));
  for (let i = 0; i < nodes; i++) {
    const f = i / (nodes - 1);                 // 0 abajo .. 1 arriba
    const y = soilY - 12 - f * (stemH - 24);
    const scale = 1 - f * 0.45;                  // hojas menores arriba
    const lw = Math.round((44 + g.leaf * 3) * (0.7 + 0.5 * scale) * (0.85 + g.vigor * 0.4));
    const rot = 18 + f * 12;
    const lL = await prep(load(leafName), { w: lw, rotate: -rot, flop: true, bright: 0.95 + 0.1 * scale });
    const lR = await prep(load(leafName), { w: lw, rotate: rot, bright: 0.95 + 0.1 * scale });
    put(lL, cx - 3 - lL.w, y - lL.h * 0.55);
    put(lR, cx + 3, y - lR.h * 0.55);
    // cogollos laterales en nodos altos si hay produccion
    if (g.prod > 0.4 && f > 0.4 && i % 1 === 0) {
      const bw = Math.round((16 + g.prod * 14) * (0.6 + scale * 0.6));
      const bud = await prep(load('bud_small'), { w: bw, hue, sat: 1.05 });
      put(bud, cx - bud.w / 2 + (i % 2 ? 10 : -10), y - bud.h);
    }
  }

  // cola apical
  const colaW = Math.round(48 + g.prod * 40) * (g.gig ? 1.3 : g.dwf ? 0.7 : 1);
  const cola = await prep(load('cola_large'), { w: colaW, hue, sat: 1.1, bright: g.albino ? 1.3 : 1 });
  put(cola, cx - cola.w / 2, stemTop - cola.h * 0.55);

  // maceta al frente
  put(pot, cx - pot.w / 2, potTop);

  const base = sharp({ create: { width: W, height: H, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } });
  return base.composite(comps).png().toBuffer();
}

// ---- muestras ----
const SAMPLES = [
  { name: 'sativa_oro', label: 'Sativa · Oro', leaf: 9, color: 'oro', altura: 0.9, prod: 0.6, vigor: 0.7, gig: false, dwf: false },
  { name: 'indica_purpura', label: 'Indica · Purpura', leaf: 5, color: 'purpura', altura: 0.35, prod: 0.8, vigor: 0.6, gig: false, dwf: false },
  { name: 'hibrido_verde', label: 'Hibrido · Verde', leaf: 7, color: 'verde', altura: 0.6, prod: 0.6, vigor: 0.7, gig: false, dwf: false },
  { name: 'gigante_carmesi', label: 'Gigante · Carmesi', leaf: 7, color: 'carmesi', altura: 1.0, prod: 0.95, vigor: 0.9, gig: true, dwf: false },
];

const outDir = 'assets/gen_plants';
fs.mkdirSync(outDir, { recursive: true });
const built = [];
for (const s of SAMPLES) {
  const buf = await assemble(s);
  fs.writeFileSync(path.join(outDir, s.name + '.png'), buf);
  built.push({ ...s, buf });
  console.log('🌿', s.name);
}

// lamina de contacto
const CELL = 250, COLS = SAMPLES.length;
const sheet = sharp({ create: { width: CELL * COLS, height: CELL + 20, channels: 4, background: { r: 22, g: 26, b: 20, alpha: 1 } } });
const comps = [];
for (let i = 0; i < built.length; i++) {
  const img = await sharp(built[i].buf).resize(CELL - 20, CELL - 20, { fit: 'inside' }).toBuffer();
  const m = await sharp(img).metadata();
  comps.push({ input: img, left: i * CELL + ((CELL - m.width) >> 1), top: (CELL - m.height) >> 1 });
  const label = Buffer.from(`<svg width="${CELL}" height="18"><text x="${CELL / 2}" y="14" font-family="monospace" font-size="13" fill="#9fdd8f" text-anchor="middle">${built[i].label}</text></svg>`);
  comps.push({ input: label, left: i * CELL, top: CELL });
}
await sheet.composite(comps).png().toFile('/tmp/plants_sheet.png');
console.log('lamina lista');
