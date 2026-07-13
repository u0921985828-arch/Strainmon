#!/usr/bin/env node
/* ============================================================
   Strainmon — construye prompts/pixellab.json a partir de src/species.js
   Mapea el vocabulario genético (colores, hojas, familia) a descriptores
   de pixel-art en inglés y genera las 18 cepas × 5 fases con estilo
   coherente, además de personajes, mobiliario y piezas de planta.

   Uso: node scripts/build-pixellab-manifest.mjs
   Salida: prompts/pixellab.json  (editable a mano después)
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');

/* --- Cargar SPECIES desde species.js sin ejecutar el juego (stubs de PH) --- */
function loadSpecies() {
  const code = fs.readFileSync(path.join(ROOT, 'src', 'species.js'), 'utf8');
  const stub = () => ({});
  const sandbox = {
    window: { PH: { util: { RNG: { weighted: stub } }, gen: {
      wildGenotype: stub, express: stub, rarityScore: () => 0, rarityTier: () => ({ key: '' }), phenoSignature: () => '',
    } } },
  };
  sandbox.window.PH = sandbox.window.PH; // asegurar referencia
  vm.runInNewContext(code, sandbox, { filename: 'species.js' });
  return sandbox.window.PH.species.SPECIES;
}

/* --- Paleta compartida: Sweetie 16 (coherente, cubre todos los matices) --- */
const PALETTE = [
  '#1a1c2c', '#5d275d', '#b13e53', '#ef7d57', '#ffcd75', '#a7f070', '#38b764', '#257179',
  '#29366f', '#3b5dc9', '#41a6f6', '#73eff7', '#f4f4f4', '#94b0c2', '#566c86', '#333c57',
];

const COLOR = {
  ambar: 'warm amber buds', carmesi: 'deep crimson-red buds', lima: 'bright lime-green foliage',
  obsidiana: 'near-black obsidian-dark leaves', oro: 'golden-yellow buds', purpura: 'royal purple buds',
  rosa: 'soft pink pistils', turquesa: 'rare turquoise tint', verde: 'rich green foliage', violeta: 'violet-tinged leaves',
};
const LEAF = {
  aciculada: 'needle-thin leaves', ancha: 'broad wide fan leaves', digitada: 'finger-like palmate leaves',
  estrecha: 'narrow slender leaves', lobulada: 'lobed leaves', palmada: 'palmate hand-shaped leaves',
  reticulada: 'net-veined leaves', serrada: 'serrated saw-edged leaves',
};
// Hábito/porte según familia (sativa alta y espigada / índica baja y tupida / híbrida media).
function habit(family) {
  if (/Índica/i.test(family)) return 'short bushy plant with dense chunky resinous buds';
  if (/Híbrida/i.test(family)) return 'medium balanced plant with moderately dense buds';
  if (/Reliquia|madre/i.test(family)) return 'ancient primordial landrace plant, tall and hardy';
  return 'tall lanky sativa plant with long internodes and airy foxtail buds';
}
const topKey = (arr) => (arr && arr.length ? arr.slice().sort((a, b) => (b.w || 0) - (a.w || 0))[0].key : null);

/* --- 5 fases del ciclo de vida (comparten sujeto, cambia el tamaño/madurez) --- */
const STAGES = [
  { n: 1, tag: 'seedling', desc: 'tiny young seedling sprout with two cotyledons and a first pair of serrated leaves in a small terracotta pot' },
  { n: 2, tag: 'veg-early', desc: 'small vegetative plant, a few nodes of fan leaves, no buds yet, in a terracotta pot' },
  { n: 3, tag: 'veg-late', desc: 'bushy vegetative plant, full leafy canopy, strong stem, no flowers yet, in a terracotta pot' },
  { n: 4, tag: 'flowering', desc: 'flowering plant with forming buds and white pistils among the leaves, in a terracotta pot' },
  { n: 5, tag: 'harvest', desc: 'mature harvest-ready plant, big frosty trichome-covered colas, dense ripe buds, in a terracotta pot' },
];

function plantItems(species) {
  const items = [];
  for (const sp of species) {
    const color = COLOR[topKey(sp.profile?.colors)] || 'green foliage';
    const leaf = LEAF[topKey(sp.profile?.leaves)] || 'palmate leaves';
    const port = habit(sp.family || '');
    for (const st of STAGES) {
      // La fase seedling apenas muestra color/hoja de la cepa; se mantiene genérica.
      const detail = st.n <= 1 ? '' : ` ${leaf}, ${color}.`;
      items.push({
        name: `${sp.id}_${st.n}`,
        description: `Cannabis ${sp.family.toLowerCase()} landrace "${sp.name}", ${st.desc}. ${st.n >= 3 ? port + '.' : ''}${detail} Single centered plant, transparent background.`,
      });
    }
  }
  return items;
}

/* --- Personajes: player + NPCs, 4 direcciones (S, O, E, N) = frames _1.._4 --- */
const CHAR_DESC = {
  player: 'young plant-hunter hero, green snapback cap, dark-green hoodie, khaki cargo shorts, small backpack, brown boots',
  botanist: 'female botanist scientist, open white lab coat over a green shirt, safety goggles on forehead, dark hair in a bun',
  dealer: 'shady streetwise dealer, dark hoodie with hood up, sunglasses, thin gold chain, baggy jeans, sneakers',
  merchant: 'friendly shopkeeper, green apron over rolled-up sleeves, flat cap, bushy mustache',
  customer1: 'slim casual townsperson, plain t-shirt and jeans',
  customer2: 'stocky cheerful townsperson, oversized hoodie and shorts',
  walker: 'elderly villager out for a walk, cardigan, flat cap, wooden cane',
  neighbor: 'friendly neighbor gardener, denim overalls, straw hat, gardening gloves',
};
const DIRS = [
  { i: 1, dir: 'south', face: 'facing the viewer (front view)' },
  { i: 2, dir: 'west', face: 'facing left (side view)' },
  { i: 3, dir: 'east', face: 'facing right (side view)' },
  { i: 4, dir: 'north', face: 'seen from behind (back view)' },
];
function charItems() {
  const items = [];
  for (const [name, desc] of Object.entries(CHAR_DESC)) {
    for (const d of DIRS) {
      items.push({
        name: `${name}_${d.i}`,
        direction: d.dir,
        description: `Full-body pixel-art game character, ${desc}, standing, ${d.face}. Single centered character, transparent background.`,
      });
    }
  }
  return items;
}

/* --- Mobiliario del laboratorio/casa (vista oblicua tipo RPG) --- */
const FURNI = {
  furni_bed: 'a simple single bed with a green blanket and pillow',
  furni_grow_bench: 'a grow bench with young potted cannabis plants and a small grow light',
  furni_lab_table: 'a science lab table with beakers, a microscope and petri dishes',
  furni_lamp: 'a tall floor lamp with a warm glowing shade',
  furni_pc_desk: 'a desk with a retro CRT computer and keyboard',
  furni_shop_counter: 'a wooden shop counter with a cash register',
};
const furniItems = () => Object.entries(FURNI).map(([name, d]) => ({
  name, description: `Pixel-art game furniture: ${d}. Single centered object, transparent background.`,
}));

/* --- Piezas de planta para el ensamblado procedural (vista lateral) --- */
const PARTS = {
  branch_side: 'a single side branch of a cannabis plant with a few leaves',
  branch_upper: 'an upper branch of a cannabis plant with a small bud',
  bud_medium: 'a medium cannabis flower bud with orange pistils',
  bud_small: 'a small cannabis flower bud',
  cola_large: 'a large frosty top cola of a cannabis plant',
  leaf_fan5_indica: 'a five-fingered broad indica cannabis fan leaf',
  leaf_fan7: 'a seven-fingered cannabis fan leaf',
  leaf_fan9: 'a nine-fingered slender sativa cannabis fan leaf',
  leaf_sugar: 'a small frosty sugar leaf covered in trichomes',
  pistils_cluster: 'a cluster of white and orange cannabis pistils',
  pot_terracotta: 'an empty terracotta plant pot with soil',
  roots: 'a bare root ball of a cannabis plant',
  seedling: 'a tiny cannabis seedling sprout with two cotyledons',
  stem_main: 'a straight main green plant stem',
};
const partItems = () => Object.entries(PARTS).map(([name, d]) => ({
  name, description: `Pixel-art ${d}. Single centered element, transparent background.`,
}));

/* --- Ensamblar manifiesto --- */
const species = loadSpecies();
const manifest = {
  $schema: 'strainmon-pixellab-manifest/1',
  note: 'Generado por scripts/build-pixellab-manifest.mjs. Editable a mano. Ejecutar con scripts/gen-pixellab.mjs.',
  style: {
    // Knobs compartidos = base de la coherencia de estilo.
    outline: 'single color black outline',
    shading: 'basic shading',
    detail: 'medium detail',
    view: 'side',
    no_background: true,
    text_guidance_scale: 8,
    negative_description: 'blurry, 3d render, gradient, soft shading, antialiasing, photo, realistic, watermark, text, signature, extra limbs, cut off',
    palette: PALETTE,
  },
  groups: {
    chars: { size: { width: 64, height: 80 }, view: 'side', seed: 1000, items: charItems() },
    plants: { size: { width: 96, height: 128 }, view: 'side', seed: 2000, items: plantItems(species) },
    furni: { size: { width: 64, height: 64 }, view: 'side', oblique_projection: true, seed: 3000, items: furniItems() },
    parts: { size: { width: 96, height: 96 }, view: 'side', seed: 4000, items: partItems() },
  },
};

const outPath = path.join(ROOT, 'prompts', 'pixellab.json');
fs.writeFileSync(outPath, JSON.stringify(manifest, null, 2) + '\n');
const tot = Object.values(manifest.groups).reduce((a, g) => a + g.items.length, 0);
console.log(`✅ ${path.relative(ROOT, outPath)} — ${tot} sprites`);
for (const [k, g] of Object.entries(manifest.groups)) console.log(`   · ${k}: ${g.items.length}`);
