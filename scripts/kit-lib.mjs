/* ============================================================
   Strainmon — utilidades compartidas de los kits de sprites.

   Un "kit" es un catálogo declarativo (prompts/kits/*.json) de piezas
   intercambiables organizadas en ranuras (slots): cuerpos, cabezas, caras,
   pelos, carrocerías, ruedas, piezas de calzada, módulos de edificio…
   De ahí salen: (1) los trabajos de generación para la API de Pixel Lab y
   (2) el manifiesto que usa el compositor para montar sprites finales.
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
export const KITS_DIR = path.join(ROOT, 'prompts', 'kits');
export const OUT_ROOT = path.join(ROOT, 'assets', 'gen_kits');
export const MAX_PROMPT = 1000;   // límite de "description" de la API

export const DIR_CODE = {
  'south': 's', 'south-east': 'se', 'east': 'e', 'north-east': 'ne',
  'north': 'n', 'north-west': 'nw', 'west': 'w', 'south-west': 'sw',
};

const isObj = (v) => v && typeof v === 'object' && !Array.isArray(v);
/** Mezcla profunda: los valores de `over` ganan; los arrays se sustituyen. */
export function deepMerge(base, over) {
  if (!isObj(base)) return over;
  if (!isObj(over)) return over === undefined ? base : over;
  const out = { ...base };
  for (const k of Object.keys(over)) out[k] = isObj(base[k]) && isObj(over[k]) ? deepMerge(base[k], over[k]) : over[k];
  return out;
}

/** Carga un kit resolviendo "extends" (una cadena de herencia, sin ciclos). */
export function loadKit(file) {
  const full = path.isAbsolute(file) ? file
    : fs.existsSync(file) ? path.resolve(file)
      : path.join(KITS_DIR, file.endsWith('.json') ? file : file + '.json');
  if (!fs.existsSync(full)) throw new Error('kit no encontrado: ' + file);
  const seen = new Set();
  const read = (f) => {
    if (seen.has(f)) throw new Error('herencia circular en ' + f);
    seen.add(f);
    const j = JSON.parse(fs.readFileSync(f, 'utf8'));
    if (!j.extends) return j;
    const parent = read(path.resolve(path.dirname(f), j.extends));
    const { extends: _drop, ...rest } = j;
    return deepMerge(parent, rest);
  };
  const kit = read(full);
  kit._file = full;
  validateKit(kit);
  return kit;
}

export function validateKit(kit) {
  const err = [];
  if (!kit.id) err.push('falta "id"');
  if (!kit.canvas?.width || !kit.canvas?.height) err.push('falta "canvas"');
  if (!Array.isArray(kit.directions) || !kit.directions.length) err.push('falta "directions"');
  for (const d of kit.directions || []) if (!DIR_CODE[d]) err.push(`dirección desconocida: ${d}`);
  if (!Array.isArray(kit.slots) || !kit.slots.length) err.push('falta "slots"');
  const ids = new Set();
  for (const s of kit.slots || []) {
    if (!s.id) err.push('slot sin id');
    if (ids.has(s.id)) err.push('slot duplicado: ' + s.id);
    ids.add(s.id);
    if (!Array.isArray(s.parts) || !s.parts.length) err.push(`slot ${s.id} sin partes`);
    if (!Array.isArray(s.place) || s.place.length !== 2) err.push(`slot ${s.id} sin "place" [x,y]`);
    const pids = new Set();
    for (const p of s.parts || []) {
      if (!p.id) err.push(`parte sin id en ${s.id}`);
      if (pids.has(p.id)) err.push(`parte duplicada ${s.id}/${p.id}`);
      pids.add(p.id);
      if (!p.prompt) err.push(`parte ${s.id}/${p.id} sin prompt`);
    }
    if (s.tint && !kit.tints?.[s.tint]) err.push(`slot ${s.id} usa el tinte inexistente "${s.tint}"`);
  }
  if (err.length) throw new Error('kit inválido (' + (kit.id || '?') + '):\n  - ' + err.join('\n  - '));
  return true;
}

/** Semilla estable a partir del nombre del trabajo: misma pieza -> misma imagen. */
export function seedOf(name, base = 0) {
  const h = crypto.createHash('sha1').update(name).digest();
  return (base + h.readUInt32BE(0)) % 2147483647;
}

export function slotDirs(kit, slot) {
  const dirs = slot.dirs || kit.directions;
  return dirs.filter(d => kit.directions.includes(d));
}

export function buildPrompt(kit, slot, part, dir) {
  const tpl = part.prompt_full || slot.prompt || '{v}';
  const body = tpl.includes('{v}') ? tpl.replace('{v}', part.prompt) : `${tpl}. ${part.prompt}`;
  const dirWord = (kit.dirWords || {})[dir];
  const chunks = [kit.style, body];
  if (dirWord && slot.useDirWord !== false) chunks.push(dirWord);
  let text = chunks.filter(Boolean).join('. ').replace(/\s+/g, ' ').replace(/\.\.+/g, '.').trim();
  if (text.length > MAX_PROMPT) text = text.slice(0, MAX_PROMPT - 1).replace(/[,.\s]+\S*$/, '');
  return text;
}

/** Expande el kit en la lista completa de trabajos de generación. */
export function expandJobs(kit, filter = {}) {
  const only = filter.only ? new Set(String(filter.only).split(',')) : null;
  const onlyPart = filter.part ? new Set(String(filter.part).split(',')) : null;
  const onlyDir = filter.dir ? new Set(String(filter.dir).split(',')) : null;
  const jobs = [];
  for (const slot of kit.slots) {
    if (only && !only.has(slot.id)) continue;
    const size = slot.size || kit.api.size;
    for (const part of slot.parts) {
      if (onlyPart && !onlyPart.has(part.id)) continue;
      for (const dir of slotDirs(kit, slot)) {
        if (onlyDir && !onlyDir.has(dir)) continue;
        const code = DIR_CODE[dir];
        const name = `${slot.id}__${part.id}__${code}`;
        jobs.push({
          kit: kit.id, slot: slot.id, part: part.id, dir, code, name,
          file: `${slot.id}/${part.id}_${code}.png`,
          size, prompt: buildPrompt(kit, slot, part, dir),
          seed: seedOf(`${kit.id}/${name}`, kit.api.seed || 0),
        });
      }
    }
  }
  return jobs;
}

/** Punto de anclaje del contenido recortado, según la regla del slot. */
export function anchorOffset(anchor, w, h) {
  switch (anchor || 'bottom-center') {
    case 'center': return [w / 2, h / 2];
    case 'top-center': return [w / 2, 0];
    case 'top-left': return [0, 0];
    case 'bottom-left': return [0, h];
    case 'bottom-right': return [w, h];
    default: return [w / 2, h];   // bottom-center
  }
}

export const outDirFor = (kit) => path.join(OUT_ROOT, kit.id);
export const rel = (p) => path.relative(ROOT, p);
