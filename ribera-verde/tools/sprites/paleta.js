#!/usr/bin/env node
/*
  Ribera Verde — saca la paleta real del juego de las referencias exportadas.
  Uso:  node tools/sprites/paleta.js        (después de tools/sprites/referencias.js)
  Sale: art/paleta/ribera.json  colores de sprites y fondos + paleta de identidad por personaje
        art/paleta/ribera.hex   formato Lospec (un color por línea)
        art/paleta/ribera.gpl   paleta de GIMP/Aseprite
        art/paleta/ribera.png   muestras 8×8 (para color_image / palette_image de PixelLab)
*/
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const ROOT = path.join(__dirname, '..', '..');
const REF = path.join(ROOT, 'art', 'referencias');
const OUT = path.join(ROOT, 'art', 'paleta');

const walk = d => fs.readdirSync(d, { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]);
const hex = (r, g, b) => '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('');
function colors(file) {
  const png = PNG.sync.read(fs.readFileSync(file)); const set = new Map();
  for (let i = 0; i < png.data.length; i += 4) {
    if (png.data[i + 3] < 128) continue;
    const h = hex(png.data[i], png.data[i + 1], png.data[i + 2]); set.set(h, (set.get(h) || 0) + 1);
  }
  return set;
}
const hsl = h => { const r = parseInt(h.slice(1, 3), 16) / 255, g = parseInt(h.slice(3, 5), 16) / 255, b = parseInt(h.slice(5, 7), 16) / 255;
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, d = mx - mn;
  let hh = 0; if (d) hh = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
  return [(hh * 60 + 360) % 360, d ? d / (1 - Math.abs(2 * l - 1)) : 0, l]; };
const order = (a, b) => { const A = hsl(a), B = hsl(b); const ga = A[1] < .12 ? -1 : Math.floor(A[0] / 30), gb = B[1] < .12 ? -1 : Math.floor(B[0] / 30); return ga - gb || A[2] - B[2]; };

const files = walk(REF).filter(f => f.endsWith('.png') && !path.basename(f).startsWith('_'));
const sprites = new Map(), fondos = new Map(), porPersonaje = {};
for (const f of files) {
  const rel = path.relative(REF, f).replace(/\\/g, '/');
  if (rel.startsWith('estilo/') || rel.startsWith('mapa/')) continue;   // mapa/: recortes y máscaras para create_map_object (sus colores ya están en tiles/)
  const target = rel.startsWith('combate/') || rel === 'misc/hoja-titulo.png' || rel === 'misc/titulo.png' ? fondos : sprites;
  for (const [h, n] of colors(f)) target.set(h, (target.get(h) || 0) + n);
  const m = rel.match(/^personajes\/([^/]+)\//);
  if (m) { porPersonaje[m[1]] = porPersonaje[m[1]] || new Set(); for (const h of colors(f).keys()) porPersonaje[m[1]].add(h); }
}
const lista = [...sprites.keys()].sort(order);
// paleta maestra: 64 colores por k-means ponderado (en RGB con pesos perceptuales), fijando los colores de identidad
const rgb = h => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
const dist = (a, b) => 2 * (a[0] - b[0]) ** 2 + 4 * (a[1] - b[1]) ** 2 + 3 * (a[2] - b[2]) ** 2;
const FIJOS = ['#26262e', '#f8f8f0', '#e04040', '#46749a', '#a9d2ec', '#3a3a44'];
for (const set of Object.values(porPersonaje)) for (const h of set) if (!FIJOS.includes(h)) FIJOS.push(h);
const K = Math.max(64, FIJOS.length + 24);
const pts = [...sprites.entries()].map(([h, n]) => ({ c: rgb(h), w: n }));
let centros = FIJOS.map(h => ({ c: rgb(h), fijo: true }));
while (centros.length < K) { // k-means++ determinista: el punto más lejos (ponderado) de los centros actuales
  let best = null, bd = -1;
  for (const p of pts) { const d = Math.min(...centros.map(z => dist(p.c, z.c))) * Math.sqrt(p.w); if (d > bd) { bd = d; best = p; } }
  centros.push({ c: best.c.slice(), fijo: false });
}
for (let it = 0; it < 20; it++) {
  const acc = centros.map(() => [0, 0, 0, 0]);
  for (const p of pts) { let bi = 0, bd = Infinity; centros.forEach((z, i) => { const d = dist(p.c, z.c); if (d < bd) { bd = d; bi = i; } }); const a = acc[bi]; a[0] += p.c[0] * p.w; a[1] += p.c[1] * p.w; a[2] += p.c[2] * p.w; a[3] += p.w; }
  centros.forEach((z, i) => { if (!z.fijo && acc[i][3]) z.c = acc[i].slice(0, 3).map(v => Math.round(v / acc[i][3])); });
}
// cada centro libre se cambia por el color real más usado de su grupo (medoide): la maestra solo tiene colores que ya existen en el juego
const grupos = centros.map(() => []);
for (const p of pts) { let bi = 0, bd = Infinity; centros.forEach((z, i) => { const d = dist(p.c, z.c); if (d < bd) { bd = d; bi = i; } }); grupos[bi].push(p); }
centros.forEach((z, i) => { if (!z.fijo && grupos[i].length) z.c = grupos[i].reduce((m, p) => p.w > m.w ? p : m).c.slice(); });
// fuera duplicados casi iguales (los colores fijos mandan)
const kept = [];
for (const z of [...centros.filter(z => z.fijo), ...centros.filter(z => !z.fijo)]) if (z.fijo || !kept.some(k => dist(k.c, z.c) < 100)) kept.push(z);
const maestra = [...new Set(kept.map(z => hex(...z.c)))].sort(order);
const soloFondos = [...fondos.keys()].filter(h => !sprites.has(h)).sort(order);
const json = {
  descripcion: 'Paleta de Ribera Verde extraída del arte procedural. "maestra": paleta bloqueada para los sprites nuevos (incluye todos los colores de identidad de los personajes). "existentes": todos los colores que usa hoy el arte. "fondos": colores que solo salen en fondos de combate y título. "por_personaje": colores de identidad de cada uno.',
  maestra, existentes: lista, fondos: soloFondos,
  por_personaje: Object.fromEntries(Object.entries(porPersonaje).map(([k, s]) => [k, [...s].sort(order)])),
};
fs.mkdirSync(OUT, { recursive: true });
fs.writeFileSync(path.join(OUT, 'ribera.json'), JSON.stringify(json, null, 2) + '\n');
fs.writeFileSync(path.join(OUT, 'ribera.hex'), maestra.map(h => h.slice(1)).join('\n') + '\n');
fs.writeFileSync(path.join(OUT, 'ribera.gpl'), `GIMP Palette\nName: Ribera Verde\nColumns: 16\n#\n` +
  maestra.map(h => `${parseInt(h.slice(1, 3), 16).toString().padStart(3)} ${parseInt(h.slice(3, 5), 16).toString().padStart(3)} ${parseInt(h.slice(5, 7), 16).toString().padStart(3)}\t${h}`).join('\n') + '\n');
const cols = 16, sw = 8, rows = Math.ceil(maestra.length / cols), img = new PNG({ width: cols * sw, height: rows * sw });
maestra.forEach((h, i) => { const r = parseInt(h.slice(1, 3), 16), g = parseInt(h.slice(3, 5), 16), b = parseInt(h.slice(5, 7), 16);
  for (let y = 0; y < sw; y++) for (let x = 0; x < sw; x++) { const o = (((Math.floor(i / cols) * sw + y) * img.width) + (i % cols) * sw + x) * 4; img.data[o] = r; img.data[o + 1] = g; img.data[o + 2] = b; img.data[o + 3] = 255; } });
fs.writeFileSync(path.join(OUT, 'ribera.png'), PNG.sync.write(img));
const maxP = Math.max(...Object.values(json.por_personaje).map(a => a.length));
console.log(`paleta maestra: ${maestra.length} colores (de ${lista.length} existentes) · solo fondos: ${soloFondos.length} · máx. colores por personaje: ${maxP}`);
