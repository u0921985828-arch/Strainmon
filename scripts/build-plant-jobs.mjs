#!/usr/bin/env node
/* Construye prompts/gen/plants.json (18 cepas × 5 fases) para gen-sprites.mjs,
   en estilo planta realista en maceta (igual que las plantas actuales), con la
   genética por cepa (color/hoja/porte) leída de src/species.js. */
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');

function loadSpecies() {
  const code = fs.readFileSync(path.join(ROOT, 'src', 'species.js'), 'utf8');
  const stub = () => ({});
  const sandbox = { window: { PH: { util: { RNG: { weighted: stub } }, gen: {
    wildGenotype: stub, express: stub, rarityScore: () => 0, rarityTier: () => ({ key: '' }), phenoSignature: () => '' } } } };
  vm.runInNewContext(code, sandbox, { filename: 'species.js' });
  return sandbox.window.PH.species.SPECIES;
}
const COLOR = { ambar: 'cogollos de tono ámbar cálido', carmesi: 'cogollos rojo carmesí', lima: 'follaje verde lima brillante', obsidiana: 'hojas casi negras (obsidiana)', oro: 'cogollos dorados', purpura: 'cogollos púrpura intenso', rosa: 'pistilos rosados', turquesa: 'reflejos turquesa raros', verde: 'follaje verde intenso', violeta: 'hojas con matices violeta' };
const LEAF = { aciculada: 'hojas finas como agujas', ancha: 'hojas de abanico anchas', digitada: 'hojas palmeadas de dedos largos', estrecha: 'hojas estrechas', lobulada: 'hojas lobuladas', palmada: 'hojas palmeadas', reticulada: 'hojas de nervadura reticulada', serrada: 'hojas de borde serrado' };
function habit(f) {
  if (/Índica/i.test(f)) return 'planta baja y tupida de cogollos densos y resinosos';
  if (/Híbrida/i.test(f)) return 'planta media equilibrada';
  if (/Reliquia|madre/i.test(f)) return 'planta landrace primigenia, alta y robusta';
  return 'planta sativa alta y espigada de entrenudos largos';
}
const topKey = (a) => (a && a.length ? a.slice().sort((x, y) => (y.w || 0) - (x.w || 0))[0].key : null);
const STAGES = [
  { n: 1, d: 'brote diminuto de plántula con dos cotiledones y un primer par de hojas serradas, en una maceta de terracota pequeña' },
  { n: 2, d: 'planta vegetativa pequeña con unos pocos nudos de hojas de abanico, sin flores todavía, en maceta de terracota' },
  { n: 3, d: 'planta vegetativa frondosa y tupida, dosel de hojas completo y tallo fuerte, sin flores, en maceta de terracota' },
  { n: 4, d: 'planta en floración con cogollos formándose y pistilos blancos entre las hojas, en maceta de terracota' },
  { n: 5, d: 'planta madura lista para cosechar, colas grandes escarchadas de tricomas blancos y cogollos densos, en maceta de terracota' },
];
const BASE = 'Pixel art 16-bit estilo Game Boy Advance, original, sin antialias, contorno oscuro 1px (#20161f), sombreado suave con luz cenital y volumen, alta definición de pixel. UNA ÚNICA planta de cannabis en su maceta de terracota, vista frontal, sin turnaround ni duplicados ni varias macetas. ENCUADRE COMPLETO: se ve la planta ENTERA y la maceta ENTERA de arriba abajo, centradas, con margen de aire alrededor; la planta NO toca ni se sale de los bordes, no recortar. Es un objeto pequeño y completo en el centro del lienzo, no un primer plano.';

const species = loadSpecies();
const jobs = [];
for (const sp of species) {
  const color = COLOR[topKey(sp.profile?.colors)] || 'follaje verde';
  const leaf = LEAF[topKey(sp.profile?.leaves)] || 'hojas palmeadas';
  const port = habit(sp.family || '');
  for (const st of STAGES) {
    const gen = st.n >= 3 ? ` ${port}; ${leaf}; ${color}.` : '';
    jobs.push({ name: `${sp.id}_${st.n}`, prompt: `${BASE} Cepa landrace "${sp.name}" (${sp.family.toLowerCase()}): ${st.d}.${gen} Planta completa sin recortar.` });
  }
}
fs.mkdirSync(path.join(ROOT, 'prompts', 'gen'), { recursive: true });
fs.writeFileSync(path.join(ROOT, 'prompts', 'gen', 'plants.json'), JSON.stringify(jobs, null, 2));
console.log(`✅ prompts/gen/plants.json — ${jobs.length} jobs (${species.length} cepas × ${STAGES.length} fases)`);
