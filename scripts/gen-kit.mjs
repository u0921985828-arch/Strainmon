#!/usr/bin/env node
/* ============================================================
   Strainmon — generador de sets de piezas con Pixel Lab.

   Lee un kit (prompts/kits/*.json), lo expande en piezas x direcciones y
   genera cada una con la API. Todas las piezas de un kit comparten estilo:
   primero se crea una imagen patrón con pixflux y el resto se genera con
   bitforge usando esa imagen como referencia de estilo.

   Uso:
     node scripts/gen-kit.mjs character --dry            # plan y coste, sin red
     node scripts/gen-kit.mjs character --only head,hair # solo esas ranuras
     node scripts/gen-kit.mjs character --limit 20 --yes # generar de verdad
     node scripts/gen-kit.mjs vehicle --dirs rotate      # 1 dir + giros

   Opciones:
     --dry            no llama a la API; escribe el plan en _plan.json
     --only a,b       ranuras a generar          --part a,b   piezas concretas
     --dir south-east direcciones concretas      --limit N    tope de llamadas
     --yes            no preguntar por el coste  --force      ignorar caché/archivos
     --dirs gen|rotate  cómo obtener las demás direcciones (por defecto gen)
     --engine pixflux|bitforge  motor a usar     --out DIR    carpeta de salida
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import { PixelLab } from './pixellab.mjs';
import { loadKit, expandJobs, outDirFor, rel, DIR_CODE, ROOT } from './kit-lib.mjs';

function parseArgs(argv) {
  const a = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const t = argv[i];
    if (t.startsWith('--')) {
      const [k, v] = t.slice(2).split('=');
      const next = v ?? (argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : true);
      a[k] = next;
    } else a._.push(t);
  }
  return a;
}

const args = parseArgs(process.argv.slice(2));
if (!args._[0]) {
  console.log('Uso: node scripts/gen-kit.mjs <kit> [--dry] [--only slot] [--limit N] [--yes]');
  console.log('Kits disponibles:', fs.readdirSync(path.join(ROOT, 'prompts', 'kits'))
    .filter(f => f.endsWith('.json') && !f.startsWith('_')).map(f => f.replace('.json', '')).join(', '));
  process.exit(0);
}

const kit = loadKit(args._[0]);
const dry = !!args.dry;
const outDir = args.out ? path.resolve(args.out) : outDirFor(kit);
const dirMode = args.dirs === 'rotate' ? 'rotate' : 'gen';
const engine = args.engine || kit.api.engine || 'bitforge';
const jobs = expandJobs(kit, args);

// En modo "rotate" solo se generan las piezas de la dirección base; el resto se
// obtiene girando esa imagen (más barato y mucho más coherente entre vistas).
const baseDir = kit.directions[0];
const genJobs = dirMode === 'rotate' ? jobs.filter(j => j.dir === baseDir) : jobs;
const rotJobs = dirMode === 'rotate' ? jobs.filter(j => j.dir !== baseDir) : [];

const pending = (list) => list.filter(j => args.force || !fs.existsSync(path.join(outDir, j.file)));
let todoGen = pending(genJobs), todoRot = pending(rotJobs);
const limit = args.limit ? parseInt(args.limit, 10) : null;
if (limit != null) {
  todoGen = todoGen.slice(0, limit);
  todoRot = todoRot.slice(0, Math.max(0, limit - todoGen.length));
}
const totalCalls = todoGen.length + todoRot.length + (engine === 'bitforge' && kit.styleAnchor ? 1 : 0);

console.log(`🎛  Kit "${kit.id}" — ${kit.title || ''}`);
console.log(`   ranuras: ${kit.slots.length} · piezas: ${kit.slots.reduce((n, s) => n + s.parts.length, 0)} · direcciones: ${kit.directions.join(', ')}`);
console.log(`   trabajos: ${jobs.length} · ya en disco: ${jobs.length - pending(jobs).length} · a generar ahora: ${totalCalls}`);
console.log(`   motor: ${engine} · direcciones: ${dirMode} · salida: ${rel(outDir)}`);

if (dry) {
  fs.mkdirSync(outDir, { recursive: true });
  const plan = { kit: kit.id, engine, dirMode, canvas: kit.canvas, calls: totalCalls, jobs };
  fs.writeFileSync(path.join(outDir, '_plan.json'), JSON.stringify(plan, null, 1));
  for (const j of jobs.slice(0, 6)) console.log(`   · ${j.name}\n     ${j.prompt.slice(0, 150)}…`);
  if (jobs.length > 6) console.log(`   … y ${jobs.length - 6} más (plan completo en ${rel(path.join(outDir, '_plan.json'))})`);
  console.log('🧪 dry-run: no se ha llamado a la API.');
  process.exit(0);
}

if (totalCalls > 40 && !args.yes && limit == null) {
  console.error(`⛔ ${totalCalls} llamadas de golpe. Repite con --yes (o pon --limit N) si es lo que quieres.`);
  process.exit(1);
}

const api = new PixelLab({ force: !!args.force });
try {
  const b = await api.balance();
  console.log(`   saldo actual: $${b.usd.toFixed(3)}`);
} catch (e) { console.error('⚠️  no se pudo leer el saldo:', e.message); }

fs.mkdirSync(outDir, { recursive: true });
const styleCommon = {
  view: kit.api.view, isometric: !!kit.api.isometric, obliqueProjection: !!kit.api.obliqueProjection,
  outline: kit.api.outline, shading: kit.api.shading, detail: kit.api.detail,
  noBackground: kit.api.noBackground !== false, negativeDescription: kit.negative || '',
};

// ---- imagen patrón de estilo (una sola vez por kit) ----
let styleImage = null;
if (engine === 'bitforge' && kit.styleAnchor) {
  const anchorFile = path.join(outDir, '_style_anchor.png');
  if (!fs.existsSync(anchorFile) || args.force) {
    const a = kit.styleAnchor;
    const { buf } = await api.pixflux({
      description: [kit.style, a.prompt].filter(Boolean).join('. ').slice(0, 1000),
      imageSize: a.size || kit.api.size,
      textGuidanceScale: kit.api.textGuidanceScale,
      seed: kit.api.seed || 1,
      ...styleCommon,
    });
    fs.writeFileSync(anchorFile, buf);
    console.log('🎨 patrón de estilo →', rel(anchorFile));
  }
  styleImage = fs.readFileSync(anchorFile);
}

const manifestFile = path.join(outDir, 'manifest.json');
const manifest = fs.existsSync(manifestFile) ? JSON.parse(fs.readFileSync(manifestFile, 'utf8')) : { kit: kit.id, pieces: {} };
manifest.kit = kit.id;
manifest.canvas = kit.canvas;
manifest.directions = kit.directions;
manifest.pieces = manifest.pieces || {};

let ok = 0, fail = 0;
async function runJob(j, fromBuf) {
  const dest = path.join(outDir, j.file);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  const common = { imageSize: j.size, seed: j.seed, ...styleCommon, direction: j.dir };
  let res;
  if (fromBuf) {
    res = await api.rotate({
      ...common, fromImage: fromBuf, fromDirection: baseDir, toDirection: j.dir,
      fromView: kit.api.view, toView: kit.api.view, imageGuidanceScale: kit.api.imageGuidanceScale || 3,
    });
  } else if (engine === 'pixflux') {
    res = await api.pixflux({ ...common, description: j.prompt, textGuidanceScale: kit.api.textGuidanceScale });
  } else {
    res = await api.bitforge({
      ...common, description: j.prompt, styleImage,
      textGuidanceScale: kit.api.textGuidanceScale, extraGuidanceScale: kit.api.extraGuidanceScale,
      styleStrength: kit.api.styleStrength,
    });
  }
  fs.writeFileSync(dest, res.buf);
  manifest.pieces[j.name] = {
    slot: j.slot, part: j.part, dir: j.dir, file: j.file, size: j.size,
    prompt: j.prompt, seed: j.seed, engine: fromBuf ? 'rotate' : engine, usd: res.usd,
  };
  ok++;
  console.log(`  ✓ ${j.name} (${(res.buf.length / 1024).toFixed(1)} KB, $${res.usd.toFixed(4)})`);
}

for (const j of todoGen) {
  try { await runJob(j); } catch (e) { fail++; console.error(`  ✗ ${j.name}: ${e.message}`); }
}
for (const j of todoRot) {
  const src = path.join(outDir, `${j.slot}/${j.part}_${DIR_CODE[baseDir]}.png`);
  if (!fs.existsSync(src)) { fail++; console.error(`  ✗ ${j.name}: falta la vista base ${rel(src)}`); continue; }
  try { await runJob(j, fs.readFileSync(src)); } catch (e) { fail++; console.error(`  ✗ ${j.name}: ${e.message}`); }
}

manifest.usdTotal = Object.values(manifest.pieces).reduce((n, p) => n + (p.usd || 0), 0);
fs.writeFileSync(manifestFile, JSON.stringify(manifest, null, 1));
console.log(`\n📦 ${ok} piezas nuevas, ${fail} fallos · red: ${api.calls} llamadas, caché: ${api.cached}`);
console.log(`   gasto de esta tanda: $${api.usd.toFixed(4)} · acumulado del kit: $${manifest.usdTotal.toFixed(4)}`);
console.log(`   siguiente paso: node scripts/pack-kit.mjs ${kit.id}`);
if (fail) process.exitCode = 1;
