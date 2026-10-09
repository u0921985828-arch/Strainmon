// Árbol genealógico canónico: valida src/lineages.js y genera docs/ARBOL_GENEALOGICO.md.
//   node scripts/arbol.mjs           → valida y reescribe el documento
//   node scripts/arbol.mjs --check   → valida y falla si el documento no está al día
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const ctx = { window: {}, console, Math, Date };
vm.createContext(ctx);
for (const f of ['util.js', 'genetics.js', 'species.js', 'lineages.js']) {
  vm.runInContext(fs.readFileSync(path.join(raiz, 'src', f), 'utf8'), ctx, { filename: f });
}
const PH = ctx.window.PH;
const { SPECIES, SPECIES_BY_ID } = PH.species;
const { HYBRIDS, HYBRIDS_BY_ID, recipe, lineName } = PH.lineages;

// ---------- validación ----------
const fallos = [];
const RELIQUIAS = ['SM-000', 'SM-017'];
const LANDRACES = SPECIES.map(s => s.id).filter(id => !RELIQUIAS.includes(id));
if (HYBRIDS.length !== 100) fallos.push(`hay ${HYBRIDS.length} híbridas, deben ser 100`);
const vistos = new Set(), nombres = new Set(SPECIES.map(s => s.name.toLowerCase())), pares = new Set();
HYBRIDS.forEach((h, i) => {
  const esperado = 'SH-' + String(i + 1).padStart(3, '0');
  if (h.id !== esperado) fallos.push(`${h.id}: id fuera de orden (esperado ${esperado})`);
  if (vistos.has(h.id)) fallos.push(`${h.id}: id repetido`);
  if (nombres.has(h.name.toLowerCase())) fallos.push(`${h.id}: nombre repetido «${h.name}»`);
  nombres.add(h.name.toLowerCase());
  const [a, b] = h.parents;
  if (a === b) fallos.push(`${h.id}: se cruza consigo misma`);
  for (const p of h.parents) {
    if (!SPECIES_BY_ID[p] && !vistos.has(p)) fallos.push(`${h.id}: padre ${p} no existe o va después`);
  }
  const k = [a, b].sort().join('×');
  if (pares.has(k)) fallos.push(`${h.id}: receta ${k} repetida`);
  pares.add(k);
  if (recipe(a, b) !== h || recipe(b, a) !== h) fallos.push(`${h.id}: recipe() no la encuentra`);
  if (!h.nota) fallos.push(`${h.id}: sin nota`);
  vistos.add(h.id);
});
// Las reliquias solo aparecen en la cima; todas las landraces fundan alguna F1.
for (const h of HYBRIDS) {
  if (h.parents.some(p => RELIQUIAS.includes(p)) && h.gen < 5) fallos.push(`${h.id}: reliquia antes de la cima`);
}
const f1 = HYBRIDS.filter(h => h.gen === 1);
for (const id of LANDRACES) if (!f1.some(h => h.parents.includes(id))) fallos.push(`${id}: no funda ninguna F1`);
for (const id of RELIQUIAS) if (!HYBRIDS.some(h => h.parents.includes(id))) fallos.push(`${id}: reliquia sin descendencia`);
// Nombres reales de cultivares comerciales que no pueden aparecer (ni traducidos).
const VETADOS = ['kush', 'haze', 'skunk', 'widow', 'viuda', 'luces del norte', 'diesel', 'cookies', 'galleta',
  'gelato', 'og', 'ak-47', 'blueberry', 'arándano', 'cheese', 'queso', 'amnesia', 'critical', 'mandala', 'nirvana', 'aurora'];
for (const h of HYBRIDS) {
  const n = h.name.toLowerCase();
  for (const v of VETADOS) if (new RegExp(`(^|[^a-záéíóúñ])${v}([^a-záéíóúñ]|$)`).test(n)) fallos.push(`${h.id}: nombre vetado «${v}»`);
}

// ---------- documento ----------
const ascend = (id, prof = 0) => {
  const h = HYBRIDS_BY_ID[id];
  const marca = h ? `${id} ${h.name} (F${h.gen})` : `${id} ${lineName(id)} · landrace`;
  const lineas = ['  '.repeat(prof) + '- ' + marca];
  if (h) for (const p of h.parents) lineas.push(...ascend(p, prof + 1));
  return lineas;
};
const desc = id => HYBRIDS.filter(h => h.parents.includes(id));
const gens = [...new Set(HYBRIDS.map(h => h.gen))].sort((a, b) => a - b);
const titulo = { 1: 'F1 · landrace × landrace', 2: 'F2 · híbrida × híbrida o retrocruce', 3: 'F3', 4: 'F4', 5: 'F5', 6: 'F6 · la cima, con las reliquias' };

let md = `# Árbol genealógico canónico de Strainmon

> Generado por \`node scripts/arbol.mjs\` a partir de \`src/lineages.js\`. No se edita a mano.

16 landraces (SM-001…SM-016) y 2 reliquias (SM-000 Cepa Primigenia, SM-017 Semilla del Edén)
dan **${HYBRIDS.length} híbridas canónicas** (SH-001…SH-${String(HYBRIDS.length).padStart(3, '0')}). Nombres de parodia originales.

En el juego, cruzar en el laboratorio dos líneas que forman receta (landrace o híbrida canónica,
en cualquier orden) da la híbrida con su nombre y su código SH. Cruzar una híbrida canónica
consigo misma la estabiliza y conserva el nombre. Cualquier otro cruce sigue siendo procedural.

| Generación | Híbridas |
|---|---|
${gens.map(g => `| F${g} | ${HYBRIDS.filter(h => h.gen === g).length} |`).join('\n')}
| **Total** | **${HYBRIDS.length}** |

## Las landraces y sus F1

| Landrace | Cepa | F1 que funda |
|---|---|---|
${SPECIES.filter(s => LANDRACES.includes(s.id)).map(s => `| ${s.id} | ${s.name} | ${desc(s.id).filter(h => h.gen === 1).map(h => h.name).join(', ')} |`).join('\n')}
`;
for (const g of gens) {
  md += `\n## ${titulo[g] || 'F' + g}\n\n| Código | Híbrida | Madre × Padre | Nota |\n|---|---|---|---|\n`;
  for (const h of HYBRIDS.filter(x => x.gen === g)) {
    md += `| ${h.id} | **${h.name}** | ${h.parents.map(p => `${lineName(p)} (${p})`).join(' × ')} | ${h.nota} |\n`;
  }
}
md += `\n## Ascendencia completa de las dos cimas\n\n### SH-100 Origen\n\n${ascend('SH-100').join('\n')}\n\n### SH-099 Edén Renacido\n\n${ascend('SH-099').join('\n')}\n`;

const destino = path.join(raiz, 'docs', 'ARBOL_GENEALOGICO.md');
if (process.argv.includes('--check')) {
  if (!fs.existsSync(destino) || fs.readFileSync(destino, 'utf8') !== md) fallos.push('docs/ARBOL_GENEALOGICO.md no está al día: node scripts/arbol.mjs');
} else if (!fallos.length) {
  fs.writeFileSync(destino, md);
}
if (fallos.length) { console.error('✗ árbol genealógico\n  ' + fallos.join('\n  ')); process.exit(1); }
console.log(`✓ árbol genealógico: ${HYBRIDS.length} híbridas, ${gens.map(g => `F${g}=${HYBRIDS.filter(h => h.gen === g).length}`).join(' ')}, ${LANDRACES.length} landraces fundadoras`);
