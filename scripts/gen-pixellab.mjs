#!/usr/bin/env node
/* ============================================================
   Strainmon — generador de sprites con Pixellab (pixel-art real)
   Cero dependencias externas: fetch nativo + zlib para el PNG de paleta.

   La coherencia de estilo se logra aplicando a TODAS las peticiones:
     · los mismos knobs de estilo (outline / shading / detail / view),
     · la misma paleta forzada vía `color_image` (Sweetie 16 por defecto),
     · una `seed` base estable por grupo.
   El estilo por grupo puede sobrescribir el estilo global; cada item solo
   aporta su `description` (+ tamaño/seed/overrides opcionales).

   API key SOLO desde env PIXELLAB_API_KEY o .secrets/pixellab.key.
   Nunca se imprime ni se escribe en artefactos versionados.

   Uso:
     node scripts/gen-pixellab.mjs [manifest.json] [outDir] [opciones]
   Opciones:
     --only=chars,plants     Genera solo esos grupos.
     --limit=N               Máx. N sprites por grupo (para pruebas baratas).
     --force                 Regenera aunque el PNG ya exista (por defecto se salta).
     --dry-run               No llama a la API: imprime las peticiones y escribe
                             solo la paleta (assets/.../_palette.png) para inspección.
     --delay=MS              Pausa entre peticiones (def. 400 ms).
   Ejemplos:
     node scripts/gen-pixellab.mjs --dry-run
     node scripts/gen-pixellab.mjs prompts/pixellab.json assets/gen_pixellab --only=chars --limit=2
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const argv = process.argv.slice(2);
const opts = {};
const positional = [];
for (const a of argv) {
  if (a.startsWith('--')) {
    const [k, v] = a.slice(2).split('=');
    opts[k] = v === undefined ? true : v;
  } else positional.push(a);
}
const MANIFEST = path.resolve(positional[0] || path.join(ROOT, 'prompts', 'pixellab.json'));
const OUT_DIR = path.resolve(positional[1] || path.join(ROOT, 'assets', 'gen_pixellab'));
const ONLY = opts.only ? String(opts.only).split(',').map(s => s.trim()) : null;
const LIMIT = opts.limit ? parseInt(opts.limit, 10) : Infinity;
const FORCE = !!opts.force;
const DRY = !!opts['dry-run'];
const DELAY = opts.delay ? parseInt(opts.delay, 10) : 400;
const BASE = (process.env.PIXELLAB_BASE || 'https://api.pixellab.ai/v1').replace(/\/$/, '');

function loadKey() {
  if (process.env.PIXELLAB_API_KEY && process.env.PIXELLAB_API_KEY.trim()) return process.env.PIXELLAB_API_KEY.trim();
  const f = path.join(ROOT, '.secrets', 'pixellab.key');
  if (fs.existsSync(f)) return fs.readFileSync(f, 'utf8').trim();
  return null;
}

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

/* --- Encoder PNG mínimo (RGBA, sin interlace, un IDAT) para la paleta --- */
function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xEDB88320 & -(c & 1));
  }
  return (~c) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);
  const t = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([t, data])), 0);
  return Buffer.concat([len, t, data, crc]);
}
function encodePNG(width, height, rgba) {
  const sig = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0); ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0; // 8-bit, RGBA
  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0; // filter none
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, y * stride + stride);
  }
  const idat = zlib.deflateSync(raw, { level: 9 });
  return Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]);
}
function hexToRGB(h) {
  const s = h.replace('#', '');
  return [parseInt(s.slice(0, 2), 16), parseInt(s.slice(2, 4), 16), parseInt(s.slice(4, 6), 16)];
}
/** Genera una imagen de swatches (una celda por color) a partir de hex[]. */
function palettePNG(hexes, cell = 8) {
  const n = hexes.length;
  const cols = Math.ceil(Math.sqrt(n));
  const rows = Math.ceil(n / cols);
  const W = cols * cell, H = rows * cell;
  const rgba = Buffer.alloc(W * H * 4);
  for (let i = 0; i < n; i++) {
    const [r, g, b] = hexToRGB(hexes[i]);
    const cx = (i % cols) * cell, cy = ((i / cols) | 0) * cell;
    for (let y = 0; y < cell; y++) for (let x = 0; x < cell; x++) {
      const o = ((cy + y) * W + (cx + x)) * 4;
      rgba[o] = r; rgba[o + 1] = g; rgba[o + 2] = b; rgba[o + 3] = 255;
    }
  }
  return encodePNG(W, H, rgba);
}

/* --- Llamada a Pixellab pixflux con reintentos --- */
async function pixflux(key, body, tries = 4) {
  let last;
  for (let t = 0; t < tries; t++) {
    try {
      const r = await fetch(`${BASE}/generate-image-pixflux`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${key}` },
        body: JSON.stringify(body),
      });
      if (r.status === 429 || r.status >= 500) { last = new Error('HTTP ' + r.status); await sleep(1000 * 2 ** t); continue; }
      const j = await r.json();
      if (!r.ok) throw new Error('HTTP ' + r.status + ' ' + JSON.stringify(j).slice(0, 300));
      const b64 = j?.image?.base64 || j?.images?.[0]?.base64 || j?.image?.data;
      if (!b64) throw new Error('respuesta sin imagen: ' + JSON.stringify(j).slice(0, 200));
      return { buf: Buffer.from(b64, 'base64'), usd: j?.usage?.usd };
    } catch (e) { last = e; await sleep(500 * 2 ** t); }
  }
  throw last;
}

async function main() {
  if (!fs.existsSync(MANIFEST)) { console.error('❌ No existe el manifiesto:', MANIFEST); process.exit(1); }
  const manifest = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));
  const style = manifest.style || {};
  const key = loadKey();
  if (!DRY && !key) {
    console.error('❌ Falta la key. Exporta PIXELLAB_API_KEY o crea .secrets/pixellab.key.');
    console.error('   (o usa --dry-run para validar el manifiesto sin llamar a la API).');
    process.exit(1);
  }

  // Paleta compartida -> color_image (misma en cada petición = coherencia).
  const palette = style.palette || [];
  const palettePng = palette.length ? palettePNG(palette) : null;
  const colorImage = palettePng ? { type: 'base64', base64: palettePng.toString('base64') } : undefined;
  if (palettePng) {
    fs.mkdirSync(OUT_DIR, { recursive: true });
    fs.writeFileSync(path.join(OUT_DIR, '_palette.png'), palettePng);
  }

  // Knobs de estilo que se propagan a cada petición.
  const STYLE_KEYS = ['outline', 'shading', 'detail', 'view', 'direction', 'isometric',
    'oblique_projection', 'no_background', 'text_guidance_scale', 'negative_description', 'coverage_percentage'];
  const pick = (obj) => STYLE_KEYS.reduce((a, k) => (obj[k] !== undefined ? (a[k] = obj[k], a) : a), {});
  const globalStyle = pick(style);

  const groups = manifest.groups || {};
  let count = 0, spent = 0, failed = 0;
  for (const [gName, group] of Object.entries(groups)) {
    if (ONLY && !ONLY.includes(gName)) continue;
    const gStyle = { ...globalStyle, ...pick(group) };
    const gSize = group.size || { width: 64, height: 64 };
    const baseSeed = group.seed != null ? group.seed : 0;
    const items = (group.items || []).slice(0, LIMIT);
    const dir = path.join(OUT_DIR, gName);
    fs.mkdirSync(dir, { recursive: true });
    console.log(`\n=== grupo "${gName}" (${items.length} sprites) → ${path.relative(ROOT, dir)} ===`);

    for (let i = 0; i < items.length; i++) {
      const it = items[i];
      const out = path.join(dir, (it.name.endsWith('.png') ? it.name : it.name + '.png'));
      if (!FORCE && fs.existsSync(out)) { console.log('  ↷ salto (existe):', it.name); continue; }
      const body = {
        description: it.description,
        image_size: it.size || gSize,
        seed: it.seed != null ? it.seed : baseSeed + i,
        ...gStyle,
        ...pick(it),                     // overrides por item
        ...(colorImage ? { color_image: colorImage } : {}),
      };
      if (DRY) {
        const { color_image, ...printable } = body;
        console.log('  · [dry]', it.name, '→', JSON.stringify(printable));
        count++; continue;
      }
      try {
        const { buf, usd } = await pixflux(key, body);
        fs.writeFileSync(out, buf);
        if (usd) spent += usd;
        count++;
        console.log(`  ✓ ${it.name} (${(buf.length / 1024).toFixed(1)} KB)${usd ? ` $${usd.toFixed(4)}` : ''}`);
      } catch (e) {
        failed++;
        console.error('  ✗', it.name, '→', e.message);
      }
      await sleep(DELAY);
    }
  }
  console.log(`\n${DRY ? '[dry-run] ' : ''}Listo: ${count} sprites${failed ? `, ${failed} fallos` : ''}${spent ? `, coste ~$${spent.toFixed(4)}` : ''}.`);
  if (!DRY) console.log(`Salida en ${path.relative(ROOT, OUT_DIR)}/. Siguiente paso: revisar y re-inlinear en charart.js/plantart.js.`);
}
main().catch(e => { console.error('❌', e.message); process.exit(1); });
