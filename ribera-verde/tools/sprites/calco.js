#!/usr/bin/env node
/*
  Ribera Verde — atlas de calco (sin gastar créditos)
  Calca el arte procedural (art/referencias, npm run sprites:ref) al formato de art/crudo que dejaría PixelLab:
  mismas carpetas, mismos grupos, mismos nombres de animación y las celdas grandes del manifiesto.
  Las animaciones son de prueba (fotogramas de la referencia con un leve balanceo) y los VFX son formas simples.

  Sirve para probar la integración del motor (F2) de punta a punta:
    calco → procesar.js → atlas → build → juego con atlas
  y para comparar posiciones con el procedural (si cuadra, el calco se ve casi igual que el juego de siempre).

  Uso:  node tools/sprites/calco.js [--salida dir] [--solo grupo,grupo]   (por defecto tools/salida/calco/crudo)
*/
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const ROOT = path.join(__dirname, '..', '..');
const REF = path.join(ROOT, 'art', 'referencias');
const args = process.argv.slice(2), opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? path.resolve(args[i + 1]) : d; };
const OUT = opt('--salida', path.join(ROOT, 'tools', 'salida', 'calco', 'crudo'));
const SOLO = args.includes('--solo') ? args[args.indexOf('--solo') + 1].split(',') : null;
const M = JSON.parse(fs.readFileSync(path.join(ROOT, 'art', 'manifest.json'), 'utf8'));
if (!fs.existsSync(path.join(REF, 'personajes'))) { console.error('Faltan las referencias: ejecuta antes npm run sprites:ref'); process.exit(1); }

const rd = f => PNG.sync.read(fs.readFileSync(path.join(REF, f)));
const has = f => fs.existsSync(path.join(REF, f));
let n = 0;
const wr = (grupo, sprite, dir, i, png) => {
  if (SOLO && !SOLO.includes(grupo)) return;
  const f = path.join(OUT, grupo, sprite, dir, String(i).padStart(2, '0') + '.png');
  fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, PNG.sync.write(png)); n++;
};
const blank = (w, h) => new PNG({ width: w, height: h });
const copy = (src, dst, ox, oy, sx = 0, sy = 0, w = src.width, h = src.height) => {
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const X = ox + x, Y = oy + y; if (X < 0 || Y < 0 || X >= dst.width || Y >= dst.height) continue;
    const i = ((sy + y) * src.width + sx + x) * 4; if (src.data[i + 3] < 128) continue;
    const j = (Y * dst.width + X) * 4; dst.data[j] = src.data[i]; dst.data[j + 1] = src.data[i + 1]; dst.data[j + 2] = src.data[i + 2]; dst.data[j + 3] = 255;
  }
  return dst;
};
// lienzo más grande (como devuelve PixelLab) con el sprite apoyado abajo; dy sube el cuerpo (balanceo) sin mover los pies
const lienzo = (src, W, H, dy = 0) => {
  const o = blank(W, H), ox = Math.floor((W - src.width) / 2), oy = H - 2 - src.height;
  if (!dy) return copy(src, o, ox, oy);
  const L = src.height - 4;   // las 4 filas de abajo (piernas) no se mueven
  copy(src, o, ox, oy - dy, 0, 0, src.width, L); copy(src, o, ox, oy + L - 1, 0, L - 1, src.width, 1); copy(src, o, ox, oy + L, 0, L, src.width, 4);
  return o;
};
const scale = (src, k) => { const o = blank(src.width * k, src.height * k);
  for (let y = 0; y < o.height; y++) for (let x = 0; x < o.width; x++) { const i = ((y / k | 0) * src.width + (x / k | 0)) * 4, j = (y * o.width + x) * 4; for (let c = 0; c < 4; c++) o.data[j + c] = src.data[i + c]; }
  return o; };
const shade = (hex, a) => '#' + [1, 3, 5].map(i => Math.max(0, Math.min(255, parseInt(hex.slice(i, i + 2), 16) + a)).toString(16).padStart(2, '0')).join('');
const rgbOf = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const recolor = (p, map) => { const t = {}; for (const k in map) t[rgbOf(k).join()] = rgbOf(map[k]);
  for (let i = 0; i < p.data.length; i += 4) { const c = t[[p.data[i], p.data[i + 1], p.data[i + 2]].join()]; if (c && p.data[i + 3]) [p.data[i], p.data[i + 1], p.data[i + 2]] = c; } return p; };
const dot = (p, x, y, col, r = 0) => { const c = rgbOf(col);
  for (let yy = -r; yy <= r; yy++) for (let xx = -r; xx <= r; xx++) { if (xx * xx + yy * yy > r * r + r) continue; const X = x + xx, Y = y + yy; if (X < 0 || Y < 0 || X >= p.width || Y >= p.height) continue;
    const j = (Y * p.width + X) * 4; p.data[j] = c[0]; p.data[j + 1] = c[1]; p.data[j + 2] = c[2]; p.data[j + 3] = 255; } return p; };

const DIRS = { south: 'down', north: 'up', west: 'left', east: 'right' };
const lookOf = a => ((a.cubre || []).find(c => c.startsWith('look:')) || '').slice(5);

for (const a of M.assets) {
  if (a.estado === 'retirado') continue;   // fuera del juego (1.8: carpas por casillas, mesas, macetas y plantas del mapa)
  // ---------- personajes (celda 32×32) ----------
  if (a.tipo === 'personaje') {
    const L = lookOf(a); if (!has(`personajes/${L}/down_0.png`)) continue;
    const fr = (d, k) => rd(`personajes/${L}/${DIRS[d]}_${k}.png`);
    for (const d of Object.keys(DIRS)) wr(a.id, 'base', d, 0, lienzo(fr(d, 0), 48, 48));
    for (const an of a.animaciones || []) {
      const dirs = an.direcciones || ['south'];
      for (const d of dirs) {
        if (an.nombre === 'walk' || an.nombre === 'run') [0, 1, 0, 2].forEach((k, i) => wr(a.id, an.nombre, d, i, lienzo(fr(d, k), 48, 48)));
        else { const N = an.frames || 4; for (let i = 0; i < N; i++) wr(a.id, an.nombre, d, i, lienzo(fr(d, 0), 48, 48, i % 2)); }
      }
    }
  }
  // ---------- combate (celda 64×64; la referencia ×3 como en el procedural) ----------
  if (a.tipo === 'combate') {
    const L = a.id === 'player-combate' ? 'player' : a.id === 'policia-combate' ? 'cop' : lookOf(a);
    if (!has(`personajes/${L}/down_0.png`)) continue;
    const base = a.id === 'player-combate' ? 'north' : 'south';
    const fr = (d, k) => scale(rd(`personajes/${L}/${DIRS[d]}_${k}.png`), 3);
    wr(a.id, 'base', base, 0, lienzo(fr(base, 0), 64, 64));
    for (const an of a.animaciones || []) for (const d of an.direcciones || [base]) {
      const N = an.frames || 4;
      for (let i = 0; i < N; i++) wr(a.id, an.nombre, d, i, lienzo(fr(d, an.nombre === 'huir' || an.nombre === 'perseguir' ? [1, 0, 2, 0][i % 4] : 0), 64, 64, an.nombre === 'idle' ? 0 : (i % 2) * 2));
    }
  }
  // ---------- fondos ----------
  if (a.tipo === 'fondo') {
    const c = (a.cubre || [])[0] || ''; const m = c.match(/^combate:(fondo-\w+)$/);
    if (m && has(`combate/${m[1]}.png`)) wr(a.id, 'base', 'unica', 0, rd(`combate/${m[1]}.png`));
    if (c === 'misc:hoja-titulo' && has('misc/titulo.png')) wr(a.id, 'base', 'unica', 0, rd('misc/titulo.png'));
    if (c === 'misc:cuarto-cultivo' && has('misc/cuarto-cultivo.png')) wr(a.id, 'cuarto-cultivo', 'unica', 0, rd('misc/cuarto-cultivo.png'));
  }
  // ---------- vista C (P3): sale de la imagen A y no tiene referencia procedural; se calca la lámina ya procesada ----------
  // (todos los fotogramas: la híbrida lleva uno por alto)
  if (/^carpa-c-/.test(a.id)) for (const c of a.cubre || []) { const n = c.slice(5), d = path.join(ROOT, 'art', 'procesado', a.id, n, 'unica');
    if (fs.existsSync(d)) fs.readdirSync(d).filter(f => f.endsWith('.png')).sort().forEach((f, i) => wr(a.id, n, 'unica', i, PNG.sync.read(fs.readFileSync(path.join(d, f))))); }
  // ---------- tiles (16×16 exacto; los animados en bloques de 32×32) ----------
  if (a.tipo === 'tiles') {
    for (const c of a.cubre || []) { const k = c.slice(5); const f = has(`tiles/${k}.png`) ? `tiles/${k}.png` : has(`tiles/${k}_f0.png`) ? `tiles/${k}_f0.png` : null; if (f) wr(a.id, k, 'unica', 0, rd(f)); }
    for (const an of a.animaciones || []) {
      const k = (an.sobre || '').slice(5); const fs0 = [0, 1].map(i => has(`tiles/${k}_f${i}.png`) ? rd(`tiles/${k}_f${i}.png`) : has(`tiles/${k}.png`) ? rd(`tiles/${k}.png`) : null);
      if (!fs0[0]) continue;
      for (let i = 0; i < (an.frames || 4); i++) { const t = fs0[i % 2] || fs0[0], o = blank(32, 32); for (const [x, y] of [[0, 0], [16, 0], [0, 16], [16, 16]]) copy(t, o, x, y);
        if (an.nombre === 'hierba-pisada' && i % 2) for (let y = 0; y < 32; y += 4) for (let x = (y / 4) % 2 * 2; x < 32; x += 4) dot(o, x, y, '#62aa56');
        wr(a.id, an.nombre, 'unica', i, o); }
    }
  }
  // ---------- orillas Wang (F4b): la hierba en los cuartos de las esquinas «hierba»; lo demás, transparente ----------
  if (a.tipo === 'tileset' && a.terrenos && has('tiles/grass.png')) {
    const g = rd('tiles/grass.png');
    for (const t of Object.keys(a.terrenos)) for (let mk = 1; mk < 15; mk++) {
      const o = blank(16, 16); [[0, 0], [8, 0], [0, 8], [8, 8]].forEach(([x, y], b) => { if (mk >> b & 1) copy(g, o, x, y, x, y, 8, 8); });
      wr(a.id, `${t}-${String(mk).padStart(2, '0')}`, 'unica', 0, o);
    }
  }
  // ---------- edificios (una pieza de 7×6 o 6×6 casillas, montada como en building()) ----------
  if (a.tipo === 'edificio') {
    const id = a.id.replace('edificio-', ''), w = a.celda === 'edificio_6x6' ? 6 : 7, h = 6, doorX = id === 'gray' ? null : 3;
    const o = blank(w * 16, h * 16), t = k => rd(`tiles/${k}_${id}.png`);
    for (let x = 0; x < w; x++) { copy(t('roofT'), o, x * 16, 0); copy(t('roofB'), o, x * 16, 16); for (let y = 2; y < h; y++) copy(t('wall'), o, x * 16, y * 16); if (x % 3 === 1 && x !== doorX) copy(t('win'), o, x * 16, 48); }
    if (doorX != null) copy(t('door'), o, doorX * 16, (h - 1) * 16);
    wr(a.id, 'base', 'unica', 0, o);
    if (doorX != null) for (let i = 0; i < 4; i++) { const p = blank(32, 32); copy(o, p, 0, 0, doorX * 16 - 8, (h - 2) * 16, 32, 32);
      for (let y = 0; y < 13; y++) for (let x = 0; x < Math.min(10, i * 4); x++) dot(p, 11 + x, 18 + y, '#26262e'); wr(a.id, 'puerta', 'unica', i, p); }
  }
  // ---------- carpas (1.6): la huella entera, por dentro o cerrada ----------
  if (a.tipo === 'carpa') for (const c of a.cubre || []) { const k = c.slice(5); if (has(`misc/${k}.png`)) wr(a.id, 'base', 'unica', 0, rd(`misc/${k}.png`)); }
  // ---------- objetos (y macetas y focos, que van como misc:) ----------
  if (a.tipo === 'objeto') {
    for (const c of a.cubre || []) { if (c.startsWith('misc:')) { const k = c.slice(5); if (has(`misc/${k}.png`)) wr(a.id, k, 'unica', 0, rd(`misc/${k}.png`)); continue; }
      const k = c.slice(4); if (has(`objetos/${k}.png`)) wr(a.id, k, 'unica', 0, rd(`objetos/${k}.png`)); }
    for (const an of a.animaciones || []) { const k = (an.sobre || '').slice(4); if (!has(`objetos/${k}.png`)) continue;
      for (let i = 0; i < (an.frames || 4); i++) { const o = rd(`objetos/${k}.png`); if (an.nombre === 'luces') dot(o, 4 + (i % 4) * 2, 4, ['#e04040', '#f0d070', '#58d080', '#4a92e0'][i % 4]); wr(a.id, an.nombre, 'unica', i, o); } }
  }
  // ---------- plantas (los cogollos en la rampa clave magenta) ----------
  if (a.tipo === 'planta') {
    const bud = '#9bd35a', rk = a.rampas_clave.cogollo.rampa, key = { [shade(bud, 50)]: rk[0], [bud]: rk[1], [shade(bud, -60)]: rk[2] };
    for (const c of a.cubre || []) {
      const [ns, k] = c.split(':');
      if (ns === 'planta') { const f = k === 'muerta' ? 'plantas/muerta.png' : `plantas/${k}_sana.png`; if (has(f)) wr(a.id, k, 'unica', 0, recolor(rd(f), key)); }
      if (c === 'misc:maceta-vacia' && has('misc/maceta-vacia.png')) wr(a.id, 'maceta-vacia', 'unica', 0, rd('misc/maceta-vacia.png'));
    }
    for (const an of a.animaciones || []) { const k = (an.sobre || '').split(':')[1];
      for (let i = 0; i < (an.frames || 4); i++) { const src = recolor(rd(`plantas/${k}_sana.png`), key), o = blank(src.width, src.height), h = src.height - 6;
        copy(src, o, [0, 1, 0, -1][i % 4], 0, 0, 0, src.width, h); copy(src, o, 0, h, 0, h, src.width, 6);   // la maceta quieta, las hojas se mecen
        wr(a.id, an.nombre, 'unica', i, o); } }
  }
  // ---------- arte importado (plantas de la vista): el mismo recorte que en art/crudo ----------
  if (a.id === 'plantas-vista' && (!SOLO || SOLO.includes(a.id))) { require('child_process').execFileSync(process.execPath, [path.join(__dirname, 'plantas-vista.js'), '--crudo', OUT]); n += 90; }
  // ---------- iconos ----------
  if (a.id === 'iconos' && has('misc/bolsa.png')) wr(a.id, 'bolsa', 'unica', 0, rd('misc/bolsa.png'));
  // el resto de iconos y los cogollos de la Genoteca no tienen versión procedural: un disco de color por icono (los cogollos, en la rampa magenta)
  if (a.id === 'iconos') Object.keys(a.elegidos || {}).filter(k => k !== 'bolsa').forEach((k, i) => { const o = blank(16, 16); dot(o, 8, 8, ['#c48a52', '#58c070', '#e06060', '#f0c040', '#80b0f0', '#c080e0'][i % 6], 5); dot(o, 8, 8, '#26262e', 1); wr(a.id, k, 'unica', 0, o); });
  if (a.id === 'cogollos-genoteca') Object.keys(a.elegidos || {}).forEach((k, i) => { const o = blank(32, 32), rk = a.rampas_clave.cogollo.rampa; dot(o, 16, 16, rk[2], 9 + i % 2); dot(o, 16, 15, rk[1], 7); dot(o, 14, 12, rk[0], 2); wr(a.id, k, 'unica', 0, o); });
  // ---------- VFX y criaturas (formas simples) ----------
  for (const it of a.items || []) {
    const W = a.celda === 'vfx_grande' ? 32 : 16;
    for (const an of it.animaciones || []) for (let i = 0; i < (an.frames || 4); i++) {
      const o = blank(W, W), c = W / 2, b = W - 2;
      if (/humo|nube/.test(it.id)) { const r = Math.min(W / 4, 1 + (i >> 1) + (W > 16 ? 3 : 0)); dot(o, c + (i % 2), b - 3 - i * (W > 16 ? 3 : 1), i < 4 ? '#dcd6c6' : '#bcb4a2', r); if (i > 1) dot(o, c - 2, b - i * 2, '#f8f8f0', Math.max(0, r - 1)); }
      else if (it.id === 'vfx-acaros') [[4, 6], [11, 4], [7, 11], [12, 12]].forEach(([x, y], k) => dot(o, x + ((i + k) % 2), y, '#e04040', 1));
      else if (it.id === 'vfx-gotas') [[4, 3], [11, 5], [7, 8]].forEach(([x, y]) => dot(o, x, y + i, '#76b4f2', 1));
      else if (it.id === 'vfx-brillo' || it.id === 'vfx-golpe') { const r = 2 + (i >> 1); dot(o, c, b - 6, it.id === 'vfx-golpe' ? '#f0d070' : '#ffffff', 1); [[c - r, b - 6], [c + r, b - 6], [c, b - 6 - r], [c, b - 6 + r]].forEach(([x, y]) => dot(o, x, y, it.id === 'vfx-golpe' ? '#f0d070' : '#ffffff', 1)); }
      else if (it.id === 'vfx-polen') for (let k = 0; k < 4; k++) dot(o, 3 + k * 3, b - 3 - ((i + k * 3) % 6), '#f0d070', 1);
      else if (it.id === 'vfx-monedas') dot(o, c, b - 2 - i * 2, '#f0d070', 1);
      else if (it.id === 'vfx-spray') { dot(o, 4, c, '#f09a50', 1); dot(o, W - 5, c, '#f09a50', 1); for (let k = 0; k <= i; k++) dot(o, 8 + k * 3, c + (k % 2) * 3, '#f09a50', 1); }
      else if (it.id === 'gaviota') { dot(o, c, b - 3, '#f8f8f0', 1); dot(o, c - 3, b - 5 - (i % 2) * 2, '#bcb4a2'); dot(o, c + 3, b - 5 - (i % 2) * 2, '#bcb4a2'); dot(o, c + 1, b - 3, '#f0a048'); }
      else if (it.id === 'paloma') { dot(o, c, b - 2, '#8a92a2', 1); dot(o, c + 2, b - 3 + (i % 2), '#6c7482'); }
      else dot(o, c, b - 4, '#f8f8f0', 1);
      wr(it.id, an.nombre, 'unica', i, o);
    }
  }
}
console.log(`calco: ${n} PNG en ${path.relative(ROOT, OUT)}`);
