#!/usr/bin/env node
/* ============================================================
   Strainmon — re-inlina PNGs (p.ej. los de Pixellab) como base64
   dentro de src/charart.js, src/plantart.js y src/furniart.js, que
   es de donde el juego carga los sprites en runtime.

   Mapeo grupo → archivo destino y clave DATA:
     chars   → src/charart.js    clave = nombre de archivo   (player_1 … walker_4)
     plants  → src/plantart.js   clave = nombre de archivo   (SM-000_1 … SM-017_5)
     furni   → src/furniart.js   clave = nombre SIN prefijo  (furni_bed → "bed")
   (Las "parts" no tienen destino en runtime: alimentan el ensamblador offline.)

   Solo reemplaza claves que YA existen en el archivo destino; nunca añade
   ni borra entradas ni toca el resto del archivo.

   Uso:
     node scripts/inline-sprites.mjs [--from=DIR] [--only=chars,plants,furni] [--dry-run]
   Por defecto lee de assets/gen_pixellab/<grupo>/. Git es tu backup: revisa el
   diff antes de commitear.
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const opts = {};
for (const a of process.argv.slice(2)) {
  if (a.startsWith('--')) { const [k, v] = a.slice(2).split('='); opts[k] = v === undefined ? true : v; }
}
const FROM = path.resolve(opts.from || path.join(ROOT, 'assets', 'gen_pixellab'));
const ONLY = opts.only ? String(opts.only).split(',').map(s => s.trim()) : null;
const DRY = !!opts['dry-run'];

const GROUPS = {
  chars: { file: 'src/charart.js', key: (n) => n },
  plants: { file: 'src/plantart.js', key: (n) => n },
  furni: { file: 'src/furniart.js', key: (n) => n.replace(/^furni_/, '') },
};

const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function inlineGroup(gName, cfg) {
  const srcDir = path.join(FROM, gName);
  const target = path.join(ROOT, cfg.file);
  if (!fs.existsSync(srcDir)) { console.log(`\n· ${gName}: sin carpeta fuente (${path.relative(ROOT, srcDir)}), salto.`); return; }
  if (!fs.existsSync(target)) { console.log(`\n· ${gName}: no existe destino ${cfg.file}, salto.`); return; }
  let text = fs.readFileSync(target, 'utf8');
  const pngs = fs.readdirSync(srcDir).filter(f => f.endsWith('.png') && !f.startsWith('_'));
  let updated = 0, missing = 0;
  const misses = [];
  console.log(`\n=== ${gName} → ${cfg.file} (${pngs.length} PNG) ===`);
  for (const f of pngs) {
    const name = f.replace(/\.png$/, '');
    const key = cfg.key(name);
    const re = new RegExp(`("${esc(key)}"\\s*:\\s*")data:image/png;base64,[A-Za-z0-9+/=]*(")`);
    if (!re.test(text)) { missing++; misses.push(key); continue; }
    const b64 = fs.readFileSync(path.join(srcDir, f)).toString('base64');
    text = text.replace(re, (_m, pre, post) => `${pre}data:image/png;base64,${b64}${post}`);
    updated++;
    if (DRY) console.log(`  · [dry] ${key} ← ${f} (${(b64.length / 1024).toFixed(1)} KB b64)`);
  }
  if (!DRY && updated) fs.writeFileSync(target, text);
  console.log(`  ${DRY ? '[dry] ' : ''}${updated} actualizadas${missing ? `, ${missing} sin clave en destino (${misses.slice(0, 6).join(', ')}${misses.length > 6 ? '…' : ''})` : ''}.`);
  return updated;
}

let total = 0;
for (const [g, cfg] of Object.entries(GROUPS)) {
  if (ONLY && !ONLY.includes(g)) continue;
  total += inlineGroup(g, cfg) || 0;
}
console.log(`\n${DRY ? '[dry-run] ' : ''}Total: ${total} sprites inlineados.${DRY ? ' (nada escrito)' : ''}`);
if (!DRY && total) console.log('Revisa el diff con `git diff --stat src/` antes de commitear.');
