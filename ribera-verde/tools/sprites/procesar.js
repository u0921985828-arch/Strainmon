#!/usr/bin/env node
/*
  Ribera Verde — procesa lo que devuelve PixelLab y lo deja listo para el juego.

  Entrada  art/crudo/<grupo>/<sprite>/<dir>/<NN>.png
           grupo  = id de un asset del manifiesto (o de uno de sus items)
           sprite = nombre de animación ("base" = rotaciones) o clave del tile/objeto que sustituye
           dir    = south | north | east | west | unica
  Salida   art/procesado/<grupo>/<sprite>/<dir>/<NN>.png   (tamaño exacto de la celda)
           art/procesado/<grupo>/informe.json
           con --atlas: assets/sprites/atlas.png + assets/sprites/atlas.json

  Pasos por grupo
   1. Alfa binario (≥128 opaco, el resto transparente).
   2. Bloqueo de paleta: primero los colores de identidad del asset (declarados + los de sus referencias);
      si no hay uno cerca, el color más cercano de los que ya usa el juego (paleta «existentes»);
      las rampas clave (p. ej. cogollos) van aparte; con «paleta»: «propia» en el asset se queda con sus colores.
   3. Tope de colores (estilo.max_colores_sprite): funde los menos usados en el más cercano.
   4. Limpieza de píxeles huérfanos (sin vecinos opacos).
   5. Encaje en la celda (la de la animación si declara «celda», si no la del asset), según su «ajuste»:
      · pies   → el centro del contorno y la fila más baja del primer fotograma van al ancla;
      · centro → el centro del contorno va al ancla (iconos);
      · exacto → el PNG tiene que medir lo mismo que la celda; si es un múltiplo limpio (×2, ×4…)
                 se reduce por vecino más próximo y se avisa.
      El desplazamiento del primer fotograma se aplica a toda la secuencia para no matar el movimiento.
   6. Informe de calidad (en paleta antes del bloqueo, colores, huérfanos, deriva de pies).

  Uso:  node tools/sprites/procesar.js <grupo...> | --todos   [--atlas] [--manifiesto ruta] [--crudo dir] [--salida dir] [--atlas-dir dir]
*/
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const ROOT = path.join(__dirname, '..', '..');
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const MAN = opt('--manifiesto', path.join(ROOT, 'art', 'manifest.json'));
const CRUDO = opt('--crudo', path.join(ROOT, 'art', 'crudo'));
const SALIDA = opt('--salida', path.join(ROOT, 'art', 'procesado'));
const ATLAS_DIR = opt('--atlas-dir', path.join(ROOT, 'assets', 'sprites'));
const M = JSON.parse(fs.readFileSync(MAN, 'utf8'));
const PAL = JSON.parse(fs.readFileSync(path.join(ROOT, M.estilo.paleta_json), 'utf8'));
const MAXC = M.estilo.max_colores_sprite || 15;
const TOL = 150; // distancia (ponderada, al cuadrado) hasta la que un color se considera «el mismo» que uno de identidad

const rgb = h => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
const hex = c => '#' + c.map(v => v.toString(16).padStart(2, '0')).join('');
const dist = (a, b) => 2 * (a[0] - b[0]) ** 2 + 4 * (a[1] - b[1]) ** 2 + 3 * (a[2] - b[2]) ** 2;
function hsl([r, g, b]) { r /= 255; g /= 255; b /= 255; const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, d = mx - mn;
  let h = 0; if (d) h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
  return [(h * 60 + 360) % 360, d ? d / (1 - Math.abs(2 * l - 1)) : 0, l]; }
const readPNG = f => PNG.sync.read(fs.readFileSync(f));
const listDir = d => fs.existsSync(d) ? fs.readdirSync(d).filter(x => !x.startsWith('.')).sort() : [];

// asset (o item) por id, con su celda y paleta
function findGroup(id) {
  for (const a of M.assets) {
    if (a.id === id) return { asset: a, item: null };
    for (const it of a.items || []) if (it.id === id) return { asset: a, item: it };
  }
  return null;
}

function processGroup(id) {
  const g = findGroup(id);
  if (!g) throw new Error(`«${id}» no está en el manifiesto`);
  const { asset } = g, cell0 = M.celdas[asset.celda];
  if (!cell0) throw new Error(`${id}: celda «${asset.celda}» no definida`);
  const animDefs = [...(asset.animaciones || []), ...((g.item || {}).animaciones || [])];
  const cellFor = sprite => { const a = animDefs.find(x => x.nombre === sprite && x.celda); return a ? M.celdas[a.celda] : cell0; };
  const ramps = asset.rampas_clave || {};
  // identidad = colores declarados + los de sus PNG de referencia; tienen prioridad sobre la maestra
  const ident = new Set(asset.colores_identidad || []);
  for (const r of asset.referencias || []) { const f = path.join(ROOT, r); if (!fs.existsSync(f)) continue; const p = readPNG(f);
    for (let i = 0; i < p.data.length; i += 4) if (p.data[i + 3] >= 128) ident.add(hex([p.data[i], p.data[i + 1], p.data[i + 2]])); }
  const identity = [...ident].map(rgb);
  const casiIguales = [];
  for (let i = 0; i < identity.length; i++) for (let j = i + 1; j < identity.length; j++) if (dist(identity[i], identity[j]) < 120) casiIguales.push(`${hex(identity[i])}≈${hex(identity[j])}`);
  // 2º nivel: todos los colores que ya usa el juego (la maestra es un subconjunto: es la que se pasa a PixelLab)
  const palette = [...new Set([...PAL.existentes, ...PAL.maestra, ...ident, ...Object.values(ramps).flatMap(r => r.rampa)])].map(rgb);
  const rampSet = new Set(Object.values(ramps).flatMap(r => r.rampa));
  const dir0 = path.join(CRUDO, id);
  const seqs = [];
  for (const sprite of listDir(dir0)) for (const dir of listDir(path.join(dir0, sprite))) {
    const files = listDir(path.join(dir0, sprite, dir)).filter(f => f.endsWith('.png'));
    if (files.length) seqs.push({ sprite, dir, frames: files.map(f => ({ name: f, png: readPNG(path.join(dir0, sprite, dir, f)) })) });
  }
  if (!seqs.length) throw new Error(`${id}: no hay PNG en ${path.relative(ROOT, dir0)}`);
  const rep = { grupo: id, celda: [cell0.w, cell0.h], secuencias: seqs.length, fotogramas: 0, semitransparentes: 0, en_paleta_antes: 0, distancia_media: 0,
    colores_finales: 0, fundidos: [], huerfanos_quitados: 0, deriva_pies: {}, errores: [], avisos: [] };
  if (casiIguales.length) rep.avisos.push(`colores de identidad casi iguales (pueden confundirse): ${casiIguales.join(', ')}`);
  let opaque = 0, inPal = 0, dsum = 0;
  const palKeys = new Set(palette.map(c => hex(c)));
  // ámbito del tope de colores: personajes, combate y VFX comparten paleta en todo el grupo (como un sprite de GBA);
  // tiles, objetos, plantas, edificios y fondos cuentan por sprite (cada tile u objeto con sus animaciones)
  const porGrupo = ['personaje', 'combate', 'vfx'].includes(asset.tipo);
  const ambito = s => porGrupo ? '*' : s.sprite;
  const countsBy = new Map();

  // 1-2: alfa y paleta
  for (const s of seqs) for (const fr of s.frames) {
    const d = fr.png.data; rep.fotogramas++;
    const pix = [];
    for (let i = 0; i < d.length; i += 4) {
      const a = d[i + 3];
      if (a > 0 && a < 255) rep.semitransparentes++;
      if (a < 128) { pix.push(null); continue; }
      const c = [d[i], d[i + 1], d[i + 2]]; opaque++;
      if (palKeys.has(hex(c))) inPal++;
      let out = null;
      for (const r of Object.values(ramps)) {
        const [h, sat, l] = hsl(c);
        if (h >= r.tono[0] && h <= r.tono[1] && sat >= (r.saturacion_min || 0)) { out = rgb(r.rampa[l > 0.62 ? 0 : l > 0.38 ? 1 : 2]); break; }
      }
      if (!out && asset.paleta === 'propia') out = c;   // arte importado con su propia paleta (solo pasa por el tope de colores)
      if (!out) { // 1º identidad (si está cerca), 2º toda la paleta
        let best = null, bd = Infinity;
        for (const p of identity) { const dd = dist(c, p); if (dd < bd) { bd = dd; best = p; } }
        if (bd > TOL) { best = null; bd = Infinity; for (const p of palette) { if (rampSet.has(hex(p))) continue; const dd = dist(c, p); if (dd < bd) { bd = dd; best = p; } } }
        out = best; dsum += Math.sqrt(bd); }
      pix.push(out); const k = hex(out), sc = ambito(s); if (!countsBy.has(sc)) countsBy.set(sc, new Map()); const counts = countsBy.get(sc); counts.set(k, (counts.get(k) || 0) + 1);
    }
    fr.pix = pix; fr.w = fr.png.width; fr.h = fr.png.height;
  }
  rep.en_paleta_antes = opaque ? +(100 * inPal / opaque).toFixed(1) : 100;
  rep.distancia_media = opaque ? +(dsum / opaque).toFixed(2) : 0;

  // 3: tope de colores (las rampas clave no se funden)
  const remaps = new Map();
  for (const [sc, counts] of countsBy) {
  const remap = new Map(); remaps.set(sc, remap);
  let used = [...counts.entries()].sort((a, b) => a[1] - b[1]);
  while (used.length > MAXC) {
    const idx = used.findIndex(([k]) => !rampSet.has(k)); if (idx < 0) break;
    const [k] = used.splice(idx, 1)[0];
    let best = null, bd = Infinity; for (const [k2] of used) { if (rampSet.has(k2)) continue; const dd = dist(rgb(k), rgb(k2)); if (dd < bd) { bd = dd; best = k2; } }
    remap.set(k, best); rep.fundidos.push(`${sc === '*' ? '' : sc + ': '}${k}→${best}`);
    const e = used.find(([k2]) => k2 === best); e[1] += counts.get(k);
  }
  rep.colores_finales = Math.max(rep.colores_finales, used.length);
  }
  const resolve = (k, sc) => { const remap = remaps.get(sc) || new Map(); while (remap.has(k)) k = remap.get(k); return k; };

  // 4-5: huérfanos y encaje en la celda
  const out = [];
  for (const s of seqs) {
    const cell = cellFor(s.sprite);
    const modo = (asset.ajuste_por_sprite || {})[s.sprite] || cell.ajuste || (cell.ancla[0] || cell.ancla[1] ? 'pies' : 'exacto');
    let off = null, feetY = [];
    for (const fr of s.frames) {
      if (modo === 'exacto' && (fr.w !== cell.w || fr.h !== cell.h)) {
        const k = fr.w / cell.w;
        if (Number.isInteger(k) && k > 1 && fr.h === cell.h * k) { // ¿ampliado por bloques?
          let limpios = 0; const small = [];
          for (let by = 0; by < cell.h; by++) for (let bx = 0; bx < cell.w; bx++) {
            const cnt = new Map();
            for (let y = 0; y < k; y++) for (let x = 0; x < k; x++) { const c = fr.pix[(by * k + y) * fr.w + bx * k + x]; const key = c ? hex(c) : '-'; cnt.set(key, (cnt.get(key) || 0) + 1); }
            const [mk, mn] = [...cnt.entries()].sort((a, b) => b[1] - a[1])[0];
            if (mn === k * k) limpios++;
            small.push(mk === '-' ? null : rgb(mk));
          }
          if (limpios / (cell.w * cell.h) >= 0.9) { fr.pix = small; fr.w = cell.w; fr.h = cell.h; rep.avisos.push(`${s.sprite}/${s.dir}/${fr.name}: venía ampliado ×${k}; reducido por vecino más próximo`); }
        }
      }
      const { w, h, pix } = fr;
      const at = (x, y) => x >= 0 && y >= 0 && x < w && y < h ? pix[y * w + x] : null;
      for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        if (!pix[y * w + x]) continue;
        let n = 0; for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) if ((dx || dy) && at(x + dx, y + dy)) n++;
        if (!n) { pix[y * w + x] = null; rep.huerfanos_quitados++; }
      }
      let x0 = w, y0 = h, x1 = -1, y1 = -1;
      for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) if (pix[y * w + x]) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
      fr.bb = x1 < 0 ? null : [x0, y0, x1, y1];
      if (!fr.bb) rep.errores.push(`${s.sprite}/${s.dir}/${fr.name}: fotograma vacío`); else feetY.push(y1);
    }
    // desplazamiento único por secuencia: del primer fotograma; si así algo se sale (efectos que crecen), de la caja de todos
    const vivos = s.frames.filter(fr => fr.bb); if (!vivos.length) continue;
    const offDe = ([x0, y0, x1, y1]) => modo === 'pies' ? [cell.ancla[0] - Math.floor((x0 + x1 + 1) / 2), cell.ancla[1] - y1]
      : [cell.ancla[0] - Math.floor((x0 + x1 + 1) / 2), cell.ancla[1] - Math.floor((y0 + y1 + 1) / 2)];
    const cabe = o => vivos.every(({ bb }) => bb[0] + o[0] >= 0 && bb[1] + o[1] >= 0 && bb[2] + o[0] < cell.w && bb[3] + o[1] < cell.h);
    const f0 = vivos[0];
    if (modo === 'exacto') {
      if (f0.w === cell.w && f0.h === cell.h) off = [0, 0];
      else { rep.errores.push(`${s.sprite}/${s.dir}: mide ${f0.w}×${f0.h} y la celda ${cell.w}×${cell.h}; redúcelo en local por vecino más próximo o regenera al tamaño de la celda`); continue; }
    } else {
      off = offDe(f0.bb);
      if (!cabe(off)) {
        const u = vivos.reduce((a, { bb }) => [Math.min(a[0], bb[0]), Math.min(a[1], bb[1]), Math.max(a[2], bb[2]), Math.max(a[3], bb[3])], [1e9, 1e9, -1, -1]);
        const o2 = offDe(u); if (cabe(o2)) { off = o2; rep.avisos.push(`${s.sprite}/${s.dir}: encuadrado con la caja de todos los fotogramas (el primero no basta)`); }
      }
    }
    for (const fr of vivos) {
      const { w, h, pix } = fr;
      const png = new PNG({ width: cell.w, height: cell.h }); let fuera = 0;
      for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        const c = pix[y * w + x]; if (!c) continue;
        const X = x + off[0], Y = y + off[1];
        if (X < 0 || Y < 0 || X >= cell.w || Y >= cell.h) { fuera++; continue; }
        const o = (Y * cell.w + X) * 4, cc = rgb(resolve(hex(c), ambito(s)));
        png.data[o] = cc[0]; png.data[o + 1] = cc[1]; png.data[o + 2] = cc[2]; png.data[o + 3] = 255;
      }
      if (fuera) rep.errores.push(`${s.sprite}/${s.dir}/${fr.name}: ${fuera} píxeles se salen de la celda ${cell.w}×${cell.h}`);
      out.push({ rel: path.join(id, s.sprite, s.dir, fr.name), png });
    }
    if (feetY.length > 1) { const dev = Math.max(...feetY) - Math.min(...feetY); rep.deriva_pies[`${s.sprite}/${s.dir}`] = dev;
      if (dev > 2 && /^(base|idle|walk|run)$/.test(s.sprite)) rep.avisos.push(`${s.sprite}/${s.dir}: los pies bailan ${dev} px entre fotogramas`); }
  }
  if (rep.colores_finales > MAXC) rep.errores.push(`${rep.colores_finales} colores (máximo ${MAXC})`);
  if (!rep.errores.length) {
    fs.rmSync(path.join(SALIDA, id), { recursive: true, force: true });
    for (const o of out) { const f = path.join(SALIDA, o.rel); fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, PNG.sync.write(o.png)); }
  }
  fs.mkdirSync(path.join(SALIDA, id), { recursive: true });
  fs.writeFileSync(path.join(SALIDA, id, 'informe.json'), JSON.stringify(rep, null, 2) + '\n');
  return rep;
}

function buildAtlas() {
  const frames = [];
  const walk = d => fs.readdirSync(d, { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]);
  for (const f of walk(SALIDA)) if (f.endsWith('.png')) { const key = path.relative(SALIDA, f).replace(/\\/g, '/').replace(/\.png$/, ''); frames.push({ key, png: readPNG(f) }); }
  frames.sort((a, b) => b.png.height - a.png.height || a.key.localeCompare(b.key));
  const W = 1024; let x = 0, y = 0, rowH = 0; const pos = {};
  for (const f of frames) { if (x + f.png.width > W) { x = 0; y += rowH; rowH = 0; } pos[f.key] = { x, y, w: f.png.width, h: f.png.height }; x += f.png.width; rowH = Math.max(rowH, f.png.height); }
  const H = y + rowH, atlas = new PNG({ width: W, height: Math.max(1, H) });
  for (const f of frames) PNG.bitblt(f.png, atlas, 0, 0, f.png.width, f.png.height, pos[f.key].x, pos[f.key].y);
  // animaciones y celdas desde el manifiesto
  const anims = {}, celdas = {}, rampas = {};
  for (const key of Object.keys(pos)) {
    const [grupo, sprite, dir] = key.split('/'); const g = findGroup(grupo); if (!g) continue;
    const c = M.celdas[g.asset.celda]; celdas[grupo] = { w: c.w, h: c.h, ancla: c.ancla };
    if (g.asset.rampas_clave) rampas[grupo] = g.asset.rampas_clave;
    const def = [...(g.asset.animaciones || []), ...((g.item || {}).animaciones || [])].find(a => a.nombre === sprite) || { fps: 0, bucle: false };
    anims[grupo] = anims[grupo] || {};
    const A = anims[grupo][sprite] = anims[grupo][sprite] || { fps: def.fps, bucle: def.bucle, ...(def.celda ? { celda: M.celdas[def.celda] } : {}), ...(def.sobre ? { sobre: def.sobre } : {}), dirs: {} };
    (A.dirs[dir] = A.dirs[dir] || []).push(key);
  }
  for (const g of Object.values(anims)) for (const a of Object.values(g)) for (const d of Object.keys(a.dirs)) a.dirs[d].sort();
  // lo que el motor necesita saber de cada grupo presente (01b-arte.js)
  const cubre = {}, ambiente = {}, fumador = {}, rampas_cambio = {}, menores = [];
  for (const grupo of Object.keys(anims)) {
    const g = findGroup(grupo), src = g.item || g.asset;
    for (const c of src.cubre || []) cubre[c] = grupo;
    if (!g.item) {
      if (g.asset.ambiente) ambiente[grupo] = g.asset.ambiente;
      if (g.asset.fumador && !g.asset.menor) fumador[grupo] = g.asset.fumador;
      if (g.asset.rampas_cambio) rampas_cambio[grupo] = g.asset.rampas_cambio;
      if (g.asset.menor) menores.push(grupo);
    }
  }
  fs.mkdirSync(ATLAS_DIR, { recursive: true });
  fs.writeFileSync(path.join(ATLAS_DIR, 'atlas.png'), PNG.sync.write(atlas));
  fs.writeFileSync(path.join(ATLAS_DIR, 'atlas.json'), JSON.stringify({ version: 2, imagen: 'atlas.png', tamano: [W, H], frames: pos, celdas, anims, rampas, rampas_cambio, cubre, ambiente, fumador, menores }, null, 1) + '\n');
  return { n: frames.length, W, H };
}

const groups = args.includes('--todos') ? listDir(CRUDO).filter(g => !g.startsWith('_')) : args.filter((a, i) => !a.startsWith('--') && !args[i - 1]?.startsWith('--'));
let bad = 0;
for (const id of groups) {
  try {
    const r = processGroup(id);
    const ok = !r.errores.length;
    console.log(`${ok ? 'OK   ' : 'FALLO'} ${id}: ${r.fotogramas} fotogramas · colores ${r.colores_finales}/${MAXC} · en paleta antes ${r.en_paleta_antes}% · semitransparentes ${r.semitransparentes} · huérfanos ${r.huerfanos_quitados}${r.fundidos.length ? ' · fundidos ' + r.fundidos.length : ''}`);
    r.avisos.forEach(a => console.log('   aviso: ' + a)); r.errores.forEach(e => console.log('   error: ' + e));
    if (!ok) bad++;
  } catch (e) { console.log(`FALLO ${id}: ${e.message}`); bad++; }
}
if (args.includes('--atlas')) { const a = buildAtlas(); console.log(`ATLAS ${bad ? 'CON FALLOS PREVIOS' : 'OK'}: ${a.n} fotogramas en ${a.W}×${a.H}`); }
process.exit(bad ? 1 : 0);
