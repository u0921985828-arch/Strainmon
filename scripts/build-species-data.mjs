#!/usr/bin/env node
/* ============================================================
   Strainmon — genera src/species-data.js (100 cepas) desde el pack
   de linaje cerrado (genetics_stock.json). La genética se DERIVA del
   árbol: tier-0 se siembra por tipo (índica/sativa/híbrida); los
   híbridos fusionan los perfiles de sus parentales (orden topológico).
   Determinista (misma entrada -> misma salida).
   Uso: node scripts/build-species-data.mjs <genetics_stock.json>
   ============================================================ */
import fs from 'node:fs';

const STOCK = process.argv[2];
const stock = JSON.parse(fs.readFileSync(STOCK, 'utf8'));
const strains = stock.strains;
const TIERS = stock.tiers;

// --- RNG determinista por id (mulberry32 sembrado con hash de cadena) ---
function hash(str) { let h = 2166136261 >>> 0; for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619); } return h >>> 0; }
function rngFor(id) { let a = hash(id); return () => { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }

// --- pools de genes por tipo (claves válidas del motor) ---
const POOL = {
  indica: {
    colors: [['verde', 4], ['purpura', 3], ['violeta', 1], ['obsidiana', 1]],
    leaves: [['ancha', 5], ['serrada', 1]],
    terps: [['terroso', 4], ['dulce', 3], ['especiado', 1], ['incienso', 1]],
    quant: { altura: [42, 54], produccion: [60, 72], vigor: [55, 66], resistencia: [68, 80], velocidad: [60, 70], resina: [74, 88], aroma: [62, 76] },
  },
  sativa: {
    colors: [['lima', 4], ['verde', 3], ['oro', 2], ['ambar', 2], ['carmesi', 1]],
    leaves: [['estrecha', 5], ['digitada', 3], ['aciculada', 1]],
    terps: [['citrico', 4], ['especiado', 3], ['floral', 2], ['pino', 1], ['dulce', 1]],
    quant: { altura: [66, 82], produccion: [52, 64], vigor: [58, 70], resistencia: [45, 60], velocidad: [30, 46], resina: [45, 62], aroma: [68, 84] },
  },
  hybrid: {
    colors: [['verde', 4], ['lima', 2], ['purpura', 2], ['ambar', 1]],
    leaves: [['digitada', 3], ['ancha', 3], ['serrada', 1]],
    terps: [['dulce', 3], ['terroso', 2], ['citrico', 2], ['combustible', 2], ['especiado', 1]],
    quant: { altura: [55, 68], produccion: [60, 72], vigor: [60, 72], resistencia: [55, 68], velocidad: [45, 58], resina: [60, 76], aroma: [66, 82] },
  },
};
const QK = ['altura', 'produccion', 'vigor', 'resistencia', 'velocidad', 'resina', 'aroma'];
const BIOME_LIST = ['pradera', 'bosque', 'pantano', 'isla', 'volcan', 'cueva', 'desierto', 'nieve'];
const SATIVA_BIOMES = ['pradera', 'bosque', 'pantano', 'isla', 'volcan'];
const INDICA_BIOMES = ['nieve', 'cueva', 'desierto', 'volcan'];

const byId = Object.fromEntries(strains.map(s => [s.id, s]));
// normaliza parents (por si vinieran como nombres) a ids existentes
const nameToId = Object.fromEntries(strains.map(s => [s.name.toLowerCase(), s.id]));
function normParents(p) { return (p || []).map(x => byId[x] ? x : (nameToId[String(x).toLowerCase()] || x)).filter(x => byId[x]); }

// --- topológico por dependencia de parentales ---
function topo() {
  const done = new Set(), order = [];
  let guard = 0;
  while (order.length < strains.length && guard++ < strains.length + 5) {
    for (const s of strains) {
      if (done.has(s.id)) continue;
      const ps = normParents(s.parents);
      if (ps.every(p => done.has(p))) { done.add(s.id); order.push(s); }
    }
  }
  // cualquier residuo (ciclo) al final
  for (const s of strains) if (!done.has(s.id)) order.push(s);
  return order;
}

function pickTop(list, n) {
  const map = new Map();
  for (const [k, w] of list) map.set(k, (map.get(k) || 0) + w);
  return [...map.entries()].sort((a, b) => b[1] - a[1]).slice(0, n).map(([key, w]) => ({ key, w: Math.max(1, Math.round(w)) }));
}
function jitterPool(pool, rnd, n) {
  return pickTop(pool.map(([k, w]) => [k, w + rnd() * 1.5 - 0.4]), n);
}
function baseQuant(type, rnd) {
  const q = {}; const r = POOL[type].quant; for (const k of QK) { const [lo, hi] = r[k]; q[k] = Math.round(lo + (hi - lo) * rnd()); } return q;
}

const profiles = {};   // id -> {colors,leaves,terps,quant}
function genTier0(s, rnd) {
  const t = POOL[s.type] || POOL.hybrid;
  return { colors: jitterPool(t.colors, rnd, 2 + (rnd() < 0.4 ? 1 : 0)), leaves: jitterPool(t.leaves, rnd, rnd() < 0.5 ? 2 : 1), terps: jitterPool(t.terps, rnd, 2 + (rnd() < 0.5 ? 1 : 0)), quant: baseQuant(s.type, rnd) };
}
function genHybrid(s, rnd) {
  const ps = normParents(s.parents).map(id => profiles[id]).filter(Boolean);
  const type = POOL[s.type] ? s.type : 'hybrid';
  // fusiona listas de padres + un empujón hacia el tipo declarado
  const merge = (sel) => {
    const acc = [];
    for (const p of ps) for (const g of p[sel]) acc.push([g.key, g.w]);
    for (const [k, w] of POOL[type][sel]) acc.push([k, w * 0.6]);
    return acc;
  };
  const colors = pickTop(merge('colors'), 3);
  const leaves = pickTop(merge('leaves'), 2);
  const terps = pickTop(merge('terps'), 3);
  // quant = media de padres, sesgada hacia el tipo, + potencia por tier
  const q = {};
  for (const k of QK) {
    const pv = ps.length ? ps.reduce((a, p) => a + p.quant[k], 0) / ps.length : 60;
    const [lo, hi] = POOL[type].quant[k]; const center = (lo + hi) / 2;
    let v = pv * 0.72 + center * 0.28 + (rnd() * 6 - 3);
    q[k] = v;
  }
  q.resina += s.tier * 2.2; q.aroma += s.tier * 1.6; q.produccion += s.tier * 1.1;
  for (const k of QK) q[k] = Math.max(20, Math.min(100, Math.round(q[k])));
  return { colors, leaves, terps, quant: q };
}

const order = topo();
let sat = 0, ind = 0;
const out = [];
for (const s of order) {
  const rnd = rngFor(s.id);
  const prof = s.tier === 0 ? genTier0(s, rnd) : genHybrid(s, rnd);
  profiles[s.id] = prof;
}
// segunda pasada en orden original (para salida estable por id numérico del pack)
for (const s of strains) {
  const rnd = rngFor(s.id + '#bio');
  const prof = profiles[s.id];
  const parents = normParents(s.parents);
  // biomas: solo las tier-0 aparecen salvajes
  let biomes = [];
  if (s.tier === 0) {
    const pool = s.type === 'indica' ? INDICA_BIOMES : (s.type === 'sativa' ? SATIVA_BIOMES : BIOME_LIST);
    const b1 = pool[Math.floor(rnd() * pool.length)];
    biomes = [b1];
    if (rnd() < 0.4) { const b2 = BIOME_LIST[Math.floor(rnd() * BIOME_LIST.length)]; if (b2 !== b1) biomes.push(b2); }
  }
  const typeLabel = s.type === 'indica' ? 'índica' : (s.type === 'sativa' ? 'sativa' : 'híbrida');
  const family = s.tier === 0 ? `Landrace ${typeLabel}` : `${TIERS[s.tier]}`;
  const parentNames = parents.map(p => byId[p].name);
  const story = s.tier === 0
    ? `Genética base del linaje (${typeLabel}). Nodo raíz del árbol filogenético.`
    : `Cruce de ${parentNames.join(' × ')}. ${TIERS[s.tier]}.`;
  const obj = {
    id: s.id, name: s.name, family, biomes,
    origin: s.tier === 0 ? 'Landrace / base' : TIERS[s.tier],
    region: typeLabel, tier: s.tier, type: s.type, parents,
    story, profile: prof,
  };
  if (s.tier >= 3) obj.mutBoost = +(1 + s.tier * 0.12).toFixed(2);
  if (s.tier >= 4) obj.ploidyBoost = 1.3;
  out.push(obj);
}

const js = `/* ============================================================
   STRAINMON — species-data.js  (GENERADO, no editar a mano)
   100 cepas de linaje cerrado (docs matriz filogenética). Genética
   derivada del árbol por scripts/build-species-data.mjs.
   ============================================================ */
window.PH = window.PH || {};
window.PH.speciesData = ${JSON.stringify(out)};
window.PH.strainTiers = ${JSON.stringify(TIERS)};
`;
fs.writeFileSync('src/species-data.js', js);
const spawnable = out.filter(o => o.biomes.length).length;
console.log(`species-data.js: ${out.length} cepas | tier0 salvajes: ${spawnable} | ${(Buffer.byteLength(js) / 1024).toFixed(0)} KB`);
