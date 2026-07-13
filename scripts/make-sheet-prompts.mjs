import fs from 'node:fs';
// Carga SPECIES desde species.js con stubs mínimos.
global.window = {}; const PH = window.PH = {};
PH.util = { RNG: {}, clamp: () => 0, lerp: () => 0, hslToHex: () => '', shade: () => '', fmt: () => '', id: () => '', cap: s => s };
PH.gen = { wildGenotype: () => ({}), express: () => ({}), rarityScore: () => 0, rarityTier: () => ({}), phenoSignature: () => '' };
eval(fs.readFileSync('src/species.js', 'utf8'));
const SPECIES = window.PH.species.SPECIES;

const dom = (arr) => arr.slice().sort((a, b) => (b.w || 0) - (a.w || 0))[0].key;
const COLORW = { verde: 'verde', lima: 'verde lima', ambar: 'ambar tostado', oro: 'dorado ambar', purpura: 'verde con intensos matices purpura', violeta: 'violeta', carmesi: 'rojo carmesi', rosa: 'rosado', magenta: 'magenta', azur: 'azulado', turquesa: 'turquesa', obsidiana: 'oscuro casi negro obsidiana', blanco: 'blanco palido' };
function leafPhrase(k) {
  if (k === 'ancha') return 'hojas anchas de indica';
  if (k === 'estrecha' || k === 'aciculada') return 'hojas muy estrechas de sativa';
  if (k === 'digitada') return 'hojas de dedos largos y finos de sativa';
  if (k === 'palmada') return 'hojas palmadas';
  if (k === 'serrada') return 'hojas aserradas';
  if (k === 'lobulada') return 'hojas lobuladas';
  return 'hojas reticuladas de aspecto raro';
}
function porte(h) { return h <= 50 ? 'de porte compacto y bajo' : h <= 66 ? 'de porte medio' : 'alta y espigada'; }
function frost(r) { return r >= 78 ? 'cogollos MUY escarchados de tricomas blancos' : r >= 55 ? 'cogollos escarchados de tricomas' : 'cogollos con ligera escarcha'; }

const jobs = SPECIES.map(sp => {
  const c = dom(sp.profile.colors), l = dom(sp.profile.leaves), q = sp.profile.quant;
  const budColor = COLORW[c] || 'verde';
  const prompt = `Pixel art 16-bit estilo Game Boy Advance, botanico realista y detallado, no infantil, sin cara ni ojos. Hoja de sprites: CINCO plantas de cannabis de la misma variedad (${sp.name}, ${sp.family}) en fila horizontal, MUY separadas entre si con amplios huecos de fondo negro. Planta ${porte(q.altura)}, ${leafPhrase(l)}. REGLA DE MACETA: las CINCO macetas de terracota ROJA son IDENTICAS en forma Y TAMANO (exactamente el mismo ancho y alto de maceta en las cinco), alineadas por su base en la misma linea; la maceta NUNCA cambia de tamano, ni siquiera en la plantula. Solo crece la PLANTA. Ciclo real del cannabis de izquierda a derecha, planta cada vez mas alta y frondosa: 1) PLANTULA: brote diminuto con cotiledones y un primer par de hojas, en su maceta (misma maceta grande, planta minuscula). 2) VEGETATIVO temprano: solo hojas verdes y un brote de crecimiento central en la punta (hojas nuevas), SIN flores ni cogollos. 3) VEGETATIVO tardio: mas alta y tupida, tallo central con punta de crecimiento de hojas nuevas, SIN flores ni cogollos. 4) FLORACION: empiezan a formarse los primeros cogollos ${budColor} en la punta y los nudos, todavia poco densos. 5) COSECHA: cogollos ${budColor} densos y maduros, ${frost(q.resina)}. IMPORTANTE: en las fases 1, 2 y 3 NO hay ningun cogollo ni flor, solo follaje verde con punta de crecimiento; los cogollos aparecen SOLO en 4 y 5. Contorno oscuro 1px, sombreado volumetrico, luz cenital. Fondo completamente NEGRO liso (#000000), sin escena, sin suelo, sin texto.`;
  return { name: 'sheet_' + sp.id, raw: true, prompt };
});
fs.writeFileSync('prompts/sheets/all.json', JSON.stringify(jobs, null, 1));
console.log('prompts:', jobs.length, '->', jobs.map(j => j.name).join(', '));
