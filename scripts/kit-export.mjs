#!/usr/bin/env node
/* ============================================================
   Strainmon — horneado de recetas a sprites finales.

   Compone recetas del kit (las mismas que produce tools/kit-lab.html) fuera
   del navegador y escribe PNGs sueltos y, opcionalmente, un módulo inline
   con el mismo formato que src/charart.js (claves "<nombre>_<1..4>",
   1=SE 2=SW 3=NW 4=NE) para enchufarlo al juego sin servidor.

   Uso:
     node scripts/kit-export.mjs character --random 6
     node scripts/kit-export.mjs character --recipes recetas.json --module charart.gen.js

   Formato de recetas.json:
     { "entries": [ { "name": "player", "recipe": { "parts": {...}, "tints": {...} } } ] }
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';
import { loadKit, outDirFor, rel } from './kit-lib.mjs';

const argv = process.argv.slice(2);
const flag = (n, def) => { const i = argv.indexOf('--' + n); return i < 0 ? def : (argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[i + 1] : true); };
const kitName = argv.find(a => !a.startsWith('--'));
if (!kitName) { console.log('Uso: node scripts/kit-export.mjs <kit> [--random N] [--recipes f.json] [--module charart.gen.js] [--scale 1]'); process.exit(0); }

const kit = loadKit(kitName);
const dir = outDirFor(kit);
const atlasFile = path.join(dir, 'atlas.json');
if (!fs.existsSync(atlasFile)) { console.error('❌ falta ' + rel(atlasFile) + ' — ejecuta antes scripts/pack-kit.mjs'); process.exit(1); }
const D = JSON.parse(fs.readFileSync(atlasFile, 'utf8'));
const SCALE = Math.max(1, parseInt(flag('scale', 1), 10));
const outDir = path.join(dir, 'out');
fs.mkdirSync(outDir, { recursive: true });

const atlasRaw = await sharp(path.join(dir, 'atlas.png')).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
const AW = atlasRaw.info.width, AD = atlasRaw.data;

// ---- color (misma matemática que src/kitgen.js) ----
const clamp01 = (v) => v < 0 ? 0 : v > 1 ? 1 : v;
function rgb2hsl(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
  if (mx === mn) return [0, 0, l];
  const d = mx - mn, s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
  let h;
  if (mx === r) h = (g - b) / d + (g < b ? 6 : 0);
  else if (mx === g) h = (b - r) / d + 2;
  else h = (r - g) / d + 4;
  return [h * 60, s, l];
}
const hue2rgb = (p, q, t) => {
  if (t < 0) t += 1; if (t > 1) t -= 1;
  if (t < 1 / 6) return p + (q - p) * 6 * t;
  if (t < 1 / 2) return q;
  if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
  return p;
};
function hsl2rgb(h, s, l) {
  h = ((h % 360) + 360) % 360 / 360;
  if (s === 0) { const v = Math.round(l * 255); return [v, v, v]; }
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s, p = 2 * l - q;
  return [Math.round(hue2rgb(p, q, h + 1 / 3) * 255), Math.round(hue2rgb(p, q, h) * 255), Math.round(hue2rgb(p, q, h - 1 / 3) * 255)];
}
const anchorOffset = (a, w, h) => a === 'center' ? [w / 2, h / 2] : a === 'top-center' ? [w / 2, 0] : a === 'top-left' ? [0, 0] : [w / 2, h];
const MIRROR = { 'south-east': 'south-west', 'south-west': 'south-east', 'north-east': 'north-west', 'north-west': 'north-east', east: 'west', west: 'east' };

function resolveTint(group, value) {
  if (!value) return null;
  if (typeof value === 'object') return value;
  return ((D.tints || {})[group] || []).find(t => t.id === value) || null;
}
function frameFor(slotId, partId, dirName) {
  const direct = D.frames[`${slotId}__${partId}__${D.dirCode[dirName]}`];
  if (direct) return { f: direct, dir: dirName };
  for (const alt of D.directions) {
    const f = D.frames[`${slotId}__${partId}__${D.dirCode[alt]}`];
    if (f) return { f, dir: alt };
  }
  return null;
}
const partEntry = (v) => (typeof v === 'string' ? { part: v } : (v || {}));
function repeatCount(slot, raw) {
  const entry = partEntry(raw);
  if (!entry.part) return 0;
  if (!slot.repeat) return 1;
  const lo = slot.repeat.min || 0, hi = slot.repeat.max || 1;
  return Math.max(lo, Math.min(hi, entry.repeat == null ? 1 : entry.repeat));
}

/** Compone una receta y devuelve un PNG (Buffer). */
async function compose(recipe) {
  const W = D.canvas.width, H = D.canvas.height;
  const canvas = Buffer.alloc(W * H * 4, 0);
  const dirName = recipe.dir || D.directions[0];
  const slots = D.slots.slice().sort((a, b) => (a.z || 0) - (b.z || 0));
  const shift = {};
  for (const s of slots) {
    if (!s.repeat) continue;
    const n = repeatCount(s, (recipe.parts || {})[s.id]);
    shift[s.id] = [n * (s.repeat.stepX || 0), n * (s.repeat.stepY || 0)];
  }

  const blit = (src, sw, sh, dx, dy) => {
    for (let y = 0; y < sh; y++) {
      const ty = dy + y; if (ty < 0 || ty >= H) continue;
      for (let x = 0; x < sw; x++) {
        const tx = dx + x; if (tx < 0 || tx >= W) continue;
        const s = (y * sw + x) * 4, a = src[s + 3];
        if (!a) continue;
        const t = (ty * W + tx) * 4;
        if (a === 255) { src.copy(canvas, t, s, s + 4); continue; }
        const ia = a / 255, ib = 1 - ia;
        canvas[t] = Math.round(src[s] * ia + canvas[t] * ib);
        canvas[t + 1] = Math.round(src[s + 1] * ia + canvas[t + 1] * ib);
        canvas[t + 2] = Math.round(src[s + 2] * ia + canvas[t + 2] * ib);
        canvas[t + 3] = Math.max(canvas[t + 3], a);
      }
    }
  };

  for (const slot of slots) {
    const entry = partEntry((recipe.parts || {})[slot.id]);
    if (!entry.part) continue;
    if (slot.dirs && slot.dirs.indexOf(dirName) < 0) continue;
    const meta = slot.parts.find(p => p.id === entry.part);
    if (!meta) continue;
    const hit = frameFor(slot.id, entry.part, dirName);
    if (!hit) continue;
    const f = hit.f;

    // recorta la pieza del atlas
    let layer = Buffer.alloc(f.w * f.h * 4);
    for (let y = 0; y < f.h; y++) {
      const from = ((f.y + y) * AW + f.x) * 4;
      AD.copy(layer, y * f.w * 4, from, from + f.w * 4);
    }
    const tint = resolveTint(slot.tint, (recipe.tints || {})[slot.tint]);
    if (tint) {
      for (let i = 0; i < layer.length; i += 4) {
        if (!layer[i + 3]) continue;
        const [h, s, l] = rgb2hsl(layer[i], layer[i + 1], layer[i + 2]);
        const [r, g, b] = hsl2rgb(h + (tint.h || 0), clamp01(s * (tint.s == null ? 1 : tint.s)), clamp01(l * (tint.l == null ? 1 : tint.l)));
        layer[i] = r; layer[i + 1] = g; layer[i + 2] = b;
      }
    }
    if (hit.dir !== dirName && MIRROR[hit.dir] === dirName) {
      const m = Buffer.alloc(layer.length);
      for (let y = 0; y < f.h; y++) for (let x = 0; x < f.w; x++) {
        layer.copy(m, (y * f.w + (f.w - 1 - x)) * 4, (y * f.w + x) * 4, (y * f.w + x) * 4 + 4);
      }
      layer = m;
    }

    const [ax, ay] = anchorOffset(slot.anchor, f.w, f.h);
    const nudge = (meta.dirNudge && meta.dirNudge[D.dirCode[dirName]]) || meta.nudge || [0, 0];
    const st = (slot.stackAfter && shift[slot.stackAfter]) || [0, 0];
    const rep = repeatCount(slot, entry) || (slot.repeat ? 0 : 1);
    for (let i = 0; i < rep; i++) {
      blit(layer, f.w, f.h,
        Math.round(slot.place[0] - ax + nudge[0] + st[0] + (slot.repeat ? i * (slot.repeat.stepX || 0) : 0)),
        Math.round(slot.place[1] - ay + nudge[1] + st[1] + (slot.repeat ? i * (slot.repeat.stepY || 0) : 0)));
    }
  }

  let img = sharp(canvas, { raw: { width: W, height: H, channels: 4 } });
  if (SCALE > 1) img = img.resize(W * SCALE, H * SCALE, { kernel: 'nearest' });
  return img.png({ palette: true, effort: 8 }).toBuffer();
}

// ---- aleatorio reproducible (mismo LCG que el runtime) ----
function lcg(seed) { let s = (seed >>> 0) || 1; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }
function randomRecipe(seed, dirName) {
  const rnd = lcg(seed);
  const pick = (a) => a[Math.floor(rnd() * a.length) % a.length];
  const r = { dir: dirName || D.directions[0], parts: {}, tints: {}, seed };
  for (const slot of D.slots) {
    if (!slot.parts.length) continue;
    if (slot.optional && rnd() > 0.6) continue;
    const e = { part: pick(slot.parts).id };
    if (slot.repeat) e.repeat = (slot.repeat.min || 0) + Math.floor(rnd() * ((slot.repeat.max || 1) - (slot.repeat.min || 0) + 1));
    r.parts[slot.id] = e;
  }
  for (const g of Object.keys(D.tints || {})) if (D.tints[g].length) r.tints[g] = pick(D.tints[g]).id;
  return r;
}

// ---- entradas ----
let entries = [];
const recipesFile = flag('recipes', null);
const nRandom = parseInt(flag('random', 0), 10) || 0;
if (recipesFile && recipesFile !== true) {
  const j = JSON.parse(fs.readFileSync(recipesFile, 'utf8'));
  entries = (j.entries || j).map((e, i) => ({ name: e.name || `receta_${i + 1}`, recipe: e.recipe || e }));
} else if (nRandom) {
  const base = parseInt(flag('seed', 1), 10);
  for (let i = 0; i < nRandom; i++) entries.push({ name: `rnd_${i + 1}`, recipe: randomRecipe(base * 1000 + i) });
} else {
  console.error('❌ indica --recipes <archivo.json> o --random N');
  process.exit(1);
}

const DIR_INDEX = { 'south-east': 1, 'south-west': 2, 'north-west': 3, 'north-east': 4 };
const DATA = {};
let count = 0;
for (const e of entries) {
  for (const dirName of D.directions) {
    const buf = await compose({ ...e.recipe, dir: dirName });
    const idx = DIR_INDEX[dirName] || (D.directions.indexOf(dirName) + 1);
    const file = path.join(outDir, `${e.name}_${idx}.png`);
    fs.writeFileSync(file, buf);
    DATA[`${e.name}_${idx}`] = 'data:image/png;base64,' + buf.toString('base64');
    count++;
  }
  fs.writeFileSync(path.join(outDir, `${e.name}.json`), JSON.stringify(e.recipe, null, 1));
  console.log('  ✓', e.name);
}

const moduleName = flag('module', null);
if (moduleName && moduleName !== true) {
  const file = path.join(outDir, String(moduleName));
  const body = Object.entries(DATA).map(([k, v]) => `    ${JSON.stringify(k)}: ${JSON.stringify(v)},`).join('\n');
  fs.writeFileSync(file,
    `/* Strainmon — sprites compuestos del kit "${kit.id}" (generado por scripts/kit-export.mjs).\n` +
    `   Claves "<nombre>_<1..4>" (1=SE 2=SW 3=NW 4=NE), igual que src/charart.js. */\n` +
    `(function (PH) {\n  'use strict';\n  const DATA = {\n${body}\n  };\n` +
    `  const IDX = { SE: 1, SW: 2, NW: 3, NE: 4 };\n  const images = {};\n` +
    `  function preload() { for (const k of Object.keys(DATA)) { const im = new Image(); im.src = DATA[k]; images[k] = im; } }\n` +
    `  function has(role) { return !!DATA[role + '_1']; }\n` +
    `  function key(role, dir) { return role + '_' + (IDX[dir] || 1); }\n` +
    `  function img(role, dir) { return images[key(role, dir)] || null; }\n` +
    `  PH.kitart = { DATA, preload, has, key, img };\n})(window.PH = window.PH || {});\n`);
  console.log('🧩 módulo inline →', rel(file));
}

console.log(`\n🖼  ${count} sprites en ${rel(outDir)} (${entries.length} recetas × ${D.directions.length} direcciones)`);
