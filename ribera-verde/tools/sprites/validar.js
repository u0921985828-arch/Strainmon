#!/usr/bin/env node
/*
  Ribera Verde — valida art/manifest.json:
    · que cada asset use una herramienta real del MCP de PixelLab con parámetros dentro de sus límites,
    · que las plantillas de animación existan y los fotogramas sean válidos,
    · que las referencias y la paleta existan,
    · reglas de contenido (ningún menor fuma; cada fumador tiene su VFX de humo),
    · y que el manifiesto cubra todos los assets del juego (art/inventario.json).
  Uso:  node tools/sprites/validar.js [--manifiesto ruta]     (sale con código 1 si hay errores)
*/
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..', '..');
const argi = process.argv.indexOf('--manifiesto');
const M = JSON.parse(fs.readFileSync(argi > 0 ? process.argv[argi + 1] : path.join(ROOT, 'art', 'manifest.json'), 'utf8'));
// los assets retirados (estado «retirado») se quedan en el manifiesto como historia: no se validan ni cubren nada
const RETIRADOS = M.assets.filter(a => a.estado === 'retirado').map(a => a.id); M.assets = M.assets.filter(a => a.estado !== 'retirado');
const INV = JSON.parse(fs.readFileSync(path.join(ROOT, 'art', 'inventario.json'), 'utf8'));

// Límites de las herramientas del MCP oficial de PixelLab (comprobados contra https://api.pixellab.ai/mcp, oct. 2026)
const TEMPLATES = ['backflip', 'breathing-idle', 'cross-punch', 'crouched-walking', 'crouching', 'drinking', 'falling-back-death', 'fight-stance-idle-8-frames',
  'fireball', 'flying-kick', 'front-flip', 'getting-up', 'high-kick', 'hurricane-kick', 'jumping-1', 'jumping-2', 'lead-jab', 'leg-sweep', 'picking-up',
  'pull-heavy-object', 'pushing', 'roundhouse-kick', 'running-4-frames', 'running-6-frames', 'running-8-frames', 'running-jump', 'running-slide', 'sad-walk',
  'scary-walk', 'surprise-uppercut', 'taking-punch', 'throw-object', 'two-footed-jump', 'walk', 'walk-1', 'walk-2', 'walking', 'walking-10', 'walking-2',
  'walking-3', 'walking-4', 'walking-4-frames', 'walking-5', 'walking-6', 'walking-6-frames', 'walking-7', 'walking-8', 'walking-8-frames', 'walking-9'];
const DIRS = ['south', 'north', 'east', 'west', 'south-east', 'south-west', 'north-east', 'north-west'];
const ENUM = {
  view_char: ['low top-down', 'high top-down', 'side', 'oblique'], view_obj: ['low top-down', 'high top-down', 'side'], view_1dir: ['top-down', 'sidescroller'],
  outline: ['single color black outline', 'single color outline', 'selective outline', 'lineless'],
  shading: ['flat shading', 'basic shading', 'medium shading', 'detailed shading', 'highly detailed shading'],
  detail: ['low detail', 'medium detail', 'high detail', 'highly detailed'],
  tile_type: ['hex', 'hex_pointy', 'isometric', 'oblique', 'octagon', 'square_topdown'], tile_view: ['top-down', 'high top-down', 'low top-down', 'side'],
};
const { PNG } = require('pngjs');
const errors = [], warns = [];
const dims = p => { try { const i = PNG.sync.read(fs.readFileSync(path.join(ROOT, p))); return [i.width, i.height]; } catch (e) { return null; } };
// parámetros de imagen que acepta cada herramienta (lo que va en «entrada»); «referencias» es solo para revisar y sacar colores
const ENTRADA_OK = {
  create_character: ['reference_image_base64', 'reference_image_url'],
  create_tiles_pro: ['style_images'],
  create_1_direction_object: ['style_images'],
  create_image_pixflux: ['color_image_base64', 'init_image_base64'],
  edit_image_pixen: ['image_url', 'image_base64'],
  create_map_object: ['background_image', 'inpainting.mask_image'],
  create_topdown_tileset: [], create_building_kit: [], procedural: [], importado: [],
};
function checkEntrada(a) {
  const e = a.entrada; if (!e) return;
  const ok = ENTRADA_OK[a.herramienta] || [];
  for (const [k, v] of Object.entries(e)) {
    if (!ok.includes(k)) { E(a.id, `«${a.herramienta}» no acepta la imagen «${k}»${ok.length ? ' (acepta: ' + ok.join(', ') + ')' : ' (no acepta imágenes)'}`); continue; }
    const files = Array.isArray(v) ? v : [v];
    files.forEach(f => { if (exists(f)) return; if (/^art\/(procesado|crudo\/_ref)\//.test(f)) W(a.id, `${f} sale de un paso anterior (${(a.depende_de || []).join(', ') || 'previo'})`); else E(a.id, `no existe la imagen de entrada ${f}`); });
    const ds = files.map(dims).filter(Boolean);
    if (a.herramienta === 'create_character' && a.parametros.mode !== 'v3') E(a.id, 'reference_image solo funciona con mode "v3"');
    if (a.herramienta === 'create_1_direction_object') {
      if (a.parametros.size != null) E(a.id, 'style_images y size no se pueden usar juntos (el tamaño lo fija la imagen de estilo más grande)');
      if (ds.some(([w, h]) => w > 256 || h > 256)) E(a.id, 'style_images: máximo 256×256 cada una');
      const sz = Math.max(...ds.map(d => Math.max(...d))), maxN = sz <= 85 ? 8 : sz <= 170 ? 4 : 1;
      if (files.length > maxN) E(a.id, `style_images: como mucho ${maxN} con imágenes de ${sz} px`);
      const n = sz <= 42 ? 64 : sz <= 85 ? 16 : sz <= 170 ? 4 : 1;
      if ((a.parametros.item_descriptions || []).length > n) E(a.id, `item_descriptions supera los ${n} objetos que salen con imágenes de ${sz} px`);
    }
    if (k === 'init_image_base64' && ds[0] && (ds[0][0] !== a.parametros.width || ds[0][1] !== a.parametros.height)) E(a.id, 'init_image tiene que medir exactamente width × height');
    if (k === 'background_image' && ds.some(([w, h]) => w > 192 || h > 192 || w < 32 || h < 32)) E(a.id, 'background_image (inpainting): entre 32×32 y 192×192');
    if (k === 'inpainting.mask_image') {
      const bg = e.background_image && dims(e.background_image);
      if (!bg) E(a.id, 'la máscara necesita background_image');
      else if (ds[0] && (ds[0][0] !== bg[0] || ds[0][1] !== bg[1])) E(a.id, 'la máscara tiene que medir lo mismo que background_image');
      try { const m = PNG.sync.read(fs.readFileSync(path.join(ROOT, files[0]))); let blanco = 0;
        for (let i = 0; i < m.data.length; i += 4) { const v = m.data[i]; if ((v !== 0 && v !== 255) || m.data[i + 1] !== v || m.data[i + 2] !== v) { E(a.id, 'máscara: solo blanco puro (genera) y negro puro (se conserva)'); break; } if (v === 255) blanco++; }
        if (!blanco) E(a.id, 'máscara sin zona blanca: no generaría nada'); } catch (err) {}
    }
    if (k === 'reference_image_base64' && ds.some(([w, h]) => w > 256 || h > 256)) E(a.id, 'reference_image: máximo 256×256');
  }
}
const E = (id, m) => errors.push(`${id}: ${m}`), W = (id, m) => warns.push(`${id}: ${m}`);
const inRange = (v, a, b) => typeof v === 'number' && v >= a && v <= b;
const exists = p => fs.existsSync(path.join(ROOT, p));

function checkTool(a) {
  const p = a.parametros || {}, id = a.id;
  switch (a.herramienta) {
    case 'create_character':
      if (!['standard', 'pro', 'v3'].includes(p.mode)) E(id, `mode «${p.mode}» no válido`);
      if (p.mode === 'v3' ? !inRange(p.size, 16, 256) : !inRange(p.size, 16, 128)) E(id, `size ${p.size} fuera de límites (${p.mode === 'v3' ? '16-256' : '16-128'})`);
      if (p.mode !== 'pro' && p.mode !== 'v3' && ![4, 8].includes(p.n_directions)) E(id, 'n_directions debe ser 4 u 8');
      if (p.view && !ENUM.view_char.includes(p.view)) E(id, `view «${p.view}» no válido`);
      if (p.outline && !ENUM.outline.includes(p.outline)) E(id, `outline «${p.outline}» no válido`);
      if (p.shading && !ENUM.shading.slice(0, 4).includes(p.shading)) E(id, `shading «${p.shading}» no válido`);
      if (p.detail && !['low detail', 'medium detail', 'high detail'].includes(p.detail)) E(id, `detail «${p.detail}» no válido`);
      if (p.proportions) { try { JSON.parse(p.proportions); } catch (e) { E(id, 'proportions debe ser un JSON en texto'); } }
      if (p.mode === 'v3' && !(a.entrada && (a.entrada.reference_image_base64 || a.entrada.reference_image_url))) W(id, 'mode v3 sin reference_image: generará desde texto');
      break;
    case 'create_tiles_pro':
      if (!inRange(p.tile_size, 16, 128)) E(id, 'tile_size 16-128');
      if (p.tile_type && !ENUM.tile_type.includes(p.tile_type)) E(id, 'tile_type no válido');
      if (p.tile_view && !ENUM.tile_view.includes(p.tile_view)) E(id, 'tile_view no válido');
      break;
    case 'create_building_kit':
      if (!['isometric', 'square_topdown', 'oblique'].includes(p.tile_type)) E(id, 'tile_type no válido');
      if (p.tile_type === 'isometric' ? !inRange(p.tile_size, 32, 96) : !inRange(p.tile_size, 16, 96)) E(id, 'tile_size fuera de límites');
      if (!inRange(p.wall_tiles, 1, 3)) E(id, 'wall_tiles 1-3');
      if (!p.wall_description || !p.floor_description) E(id, 'faltan wall_description/floor_description');
      break;
    case 'create_topdown_tileset': {
      const ts = typeof p.tile_size === 'object' ? p.tile_size.width : p.tile_size;
      if (p.mode !== 'pro' && ![16, 32].includes(ts)) E(id, 'tile_size 16 o 32 en modo standard');
      if (p.view && !['low top-down', 'high top-down'].includes(p.view)) E(id, 'view: low top-down | high top-down');
      (a.llamadas || []).forEach((l, i) => {
        if (!l.lower_description || !l.upper_description) E(id, `llamada ${i + 1}: faltan lower/upper_description`);
        if (![0, 0.25, 0.5, 1].includes(l.transition_size)) E(id, `llamada ${i + 1}: transition_size 0, 0.25, 0.5 o 1`);
        if (i > 0 && !l.upper_base_tile_id && !l.lower_base_tile_id) W(id, `llamada ${i + 1}: sin base_tile_id no comparte tile con las demás`);
      });
      break; }
    case 'create_map_object':
      if (a.entrada && a.entrada.background_image) { if (p.width != null || p.height != null) E(id, 'con background_image el tamaño sale del recorte: quita width/height'); if (!p.inpainting) W(id, 'sin inpainting usa un óvalo del 60 %'); }
      else if (!inRange(p.width, 32, 400) || !inRange(p.height, 32, 400)) E(id, 'width/height 32-400');
      if (p.inpainting) { try { JSON.parse(p.inpainting.replace(/"<[^>]*>"/g, '""')); } catch (err) { E(id, 'inpainting debe ser un JSON en texto'); } }
      if (p.view && !ENUM.view_obj.includes(p.view)) E(id, 'view no válido');
      break;
    case 'create_1_direction_object': {
      if (p.size == null && a.entrada && a.entrada.style_images) { if (p.view && !ENUM.view_1dir.includes(p.view)) E(id, 'view no válido'); break; } // el tamaño lo fijan las imágenes de estilo
      if (!inRange(p.size, 16, 256)) E(id, 'size 16-256');
      if (p.view && !ENUM.view_1dir.includes(p.view)) E(id, `view «${p.view}» no válido (top-down | sidescroller)`);
      const n = p.size <= 42 ? 64 : p.size <= 85 ? 16 : p.size <= 170 ? 4 : 1;
      if ((p.item_descriptions || []).length > n) E(id, `item_descriptions (${p.item_descriptions.length}) supera los ${n} objetos de size ${p.size}`);
      break; }
    case 'create_image_pixflux':
      if (!inRange(p.width, 16, 400) || !inRange(p.height, 16, 400) || p.width * p.height < 1024) E(id, 'pixflux: 16-400 por lado y área ≥ 32×32');
      break;
    case 'edit_image_pixen': {   // entrada ≤ 256 px por lado; salida ≤ 256 × 256 de área; todo en múltiplos de 4
      const ent = a.entrada && dims(Object.values(a.entrada)[0]);
      if (ent && (ent[0] > 256 || ent[1] > 256 || ent[0] % 4 || ent[1] % 4)) E(id, `entrada de ${ent[0]} × ${ent[1]}: como mucho 256 por lado y en múltiplos de 4`);
      for (const l of a.llamadas || [p]) { const w = l.width, h = l.height; if (w == null) continue;
        if (w % 4 || h % 4) E(id, `${w} × ${h}: la salida va en múltiplos de 4`); if (w * h > 65536) E(id, `${w} × ${h}: la salida no puede pasar de 256 × 256 de área`); }
      break;
    }
    case 'procedural': break;
    case 'importado': if (!a.origen) E(id, 'importado: falta «origen» (de dónde sale el arte)'); break;
    default: E(id, `herramienta «${a.herramienta}» no está en el kit`);
  }
}
function checkAnim(a, an) {
  const id = `${a.id}/${an.nombre}`;
  if (!an.nombre) E(a.id, 'animación sin nombre');
  if (!(an.fps > 0)) E(id, 'fps no válido');
  if (typeof an.bucle !== 'boolean') E(id, 'falta bucle true/false');
  if (an.herramienta === 'animate_character') {
    if (an.plantilla) { if (!TEMPLATES.includes(an.plantilla)) E(id, `plantilla «${an.plantilla}» no existe`); }
    else { if (!an.accion) E(id, 'sin plantilla ni accion'); if (!(an.frames >= 4 && an.frames <= 16 && an.frames % 2 === 0)) E(id, 'v3: frames par entre 4 y 16'); }
    (an.direcciones || []).forEach(d => { if (!DIRS.includes(d)) E(id, `dirección «${d}» no válida`); });
    if (a.herramienta !== 'create_character') E(id, 'animate_character solo sobre personajes');
    if (a.parametros && a.parametros.n_directions === 4) (an.direcciones || []).forEach(d => { if (d.includes('-')) E(id, `dirección diagonal «${d}» en un personaje de 4 direcciones`); });
  } else if (an.herramienta === 'animate_object') {
    if (!(an.frames >= 4 && an.frames <= 16 && an.frames % 2 === 0)) E(id, 'animate_object v3: frames par entre 4 y 16');
    if (!an.accion) E(id, 'falta accion');
  } else if (an.herramienta === 'animate_image') {
    const [w, h] = an.lienzo || [0, 0];
    if (!(an.frames >= 4 && an.frames <= 16 && an.frames % 2 === 0)) E(id, 'animate_image: frames par entre 4 y 16');
    if (!(w && h && w <= 256 && h <= 256)) E(id, 'animate_image: lienzo hasta 256×256');
    if (w * h * an.frames > 524288) E(id, 'animate_image: ancho × alto × fotogramas > 524288');
    if (!an.accion) E(id, 'falta accion');
  } else if (an.herramienta === 'importado') {   // dibujada a mano (1.10, mundo.py)
    if (a.herramienta !== 'importado') E(id, 'animación importada solo en un asset importado');
  } else E(id, `herramienta de animación «${an.herramienta}» no válida`);
  const cel = M.celdas[an.celda || a.celda];
  if (an.celda && !M.celdas[an.celda]) E(id, `celda «${an.celda}» no definida`);
  if (an.lienzo && cel && (an.lienzo[0] !== cel.w || an.lienzo[1] !== cel.h)) E(id, `el lienzo ${an.lienzo.join('×')} no coincide con la celda ${cel.w}×${cel.h}`);
}

const ids = new Set();
const vfx = new Set(M.assets.filter(a => a.tipo === 'vfx').flatMap(a => [a.id, ...(a.items || []).map(i => i.id)]));
for (const a of M.assets) {
  if (!a.id || ids.has(a.id)) E(a.id || '?', 'id vacío o repetido'); ids.add(a.id);
  if (!M.celdas[a.celda]) E(a.id, `celda «${a.celda}» no definida`);
  if (!a.descripcion) E(a.id, 'falta descripcion');
  checkTool(a);
  checkEntrada(a);
  (a.referencias || []).forEach(r => { if (!exists(r) && !r.startsWith('art/procesado/')) E(a.id, `no existe la referencia ${r}`); });

  (a.animaciones || []).forEach(an => checkAnim(a, an));
  if (!a.familia || !(M.familias || {})[a.familia]) E(a.id, `familia «${a.familia}» no está en manifest.familias`);
  if (a.previo) {
    const pv = a.previo, pp = pv.parametros || {};
    if (pv.herramienta !== 'create_image_pro') E(a.id, `previo: herramienta «${pv.herramienta}» no prevista`);
    if (!(pp.width >= 16 && pp.height >= 16 && pp.width <= 512 && pp.height <= 512)) E(a.id, 'previo: create_image_pro de 16 a 512 px');
    const refs = (pv.entrada || {}).reference_images || [];
    if (refs.length > 4) E(a.id, 'previo: como mucho 4 reference_images');
    refs.forEach(r => { if (!r.usage) E(a.id, 'previo: cada referencia necesita usage'); if (!exists(r.archivo)) W(a.id, `previo: ${r.archivo} sale de ${(a.depende_de || []).join(', ')}`); });
    if (!pv.guarda || !Object.values(a.entrada || {}).includes(pv.guarda)) E(a.id, 'previo: lo que guarda tiene que ser la entrada del paso siguiente');
  }
  for (const d of a.depende_de || []) if (!M.assets.some(b => b.id === d)) E(a.id, `depende_de «${d}» no existe`);
  if (a.lote) { const l = (M.lotes || {})[a.lote];
    if (!l) E(a.id, `lote «${a.lote}» no está en manifest.lotes`);
    else { if (a.herramienta !== l.herramienta) E(a.id, `lote ${a.lote}: herramienta distinta (${a.herramienta})`);
      if ((a.parametros || {}).size !== l.size) E(a.id, `lote ${a.lote}: size ${(a.parametros || {}).size} ≠ ${l.size}`);
      if (a.entrada && a.entrada.style_images) E(a.id, `lote ${a.lote}: un asset con style_images no puede compartir llamada`); } }
  for (const [k, v] of Object.entries(a.ajuste_por_sprite || {})) {
    if (!['pies', 'centro', 'exacto'].includes(v)) E(a.id, `ajuste_por_sprite.${k}: «${v}» no es pies, centro ni exacto`);
    if (!(a.cubre || []).some(c => c.endsWith(':' + k))) E(a.id, `ajuste_por_sprite.${k}: no está en cubre`);
  }
  // el nombre de la animación es la carpeta en art/crudo/<grupo>/<nombre>: no puede repetirse en el mismo grupo
  const nombres = (a.animaciones || []).map(an => an.nombre);
  nombres.forEach((n, i) => { if (nombres.indexOf(n) !== i) E(a.id, `animación «${n}» repetida: cada una necesita su propio nombre (es su carpeta en art/crudo)`); });
  if (a.items) {
    if (a.herramienta !== 'create_1_direction_object') E(a.id, 'items solo con create_1_direction_object');
    if ((a.parametros.item_descriptions || []).length !== a.items.length) E(a.id, 'item_descriptions y items deben tener la misma longitud');
    a.items.forEach(it => { if (ids.has(it.id)) E(it.id, 'id repetido'); ids.add(it.id); (it.animaciones || []).forEach(an => checkAnim({ ...a, id: it.id }, an)); });
  }
  const fuma = (a.ambiente?.acciones || []).some(x => /fumar|puro|pipa|vapear/.test(x)) || a.fumador;
  if (a.menor && fuma) E(a.id, 'un menor no puede fumar ni vapear');
  if (a.fumador && !vfx.has(a.fumador.vfx)) E(a.id, `el VFX de humo «${a.fumador.vfx}» no está en el manifiesto`);
  if (a.ambiente) a.ambiente.acciones.forEach(x => { if (!(a.animaciones || []).some(an => an.nombre === x)) E(a.id, `la acción de ambiente «${x}» no tiene animación`); });
  if (a.rampas_clave) for (const [k, r] of Object.entries(a.rampas_clave)) if (!(Array.isArray(r.rampa) && r.rampa.length === 3)) E(a.id, `rampa clave «${k}» debe tener 3 tonos`);
}
if (!exists(M.estilo.paleta)) E('estilo', 'no existe la paleta');
for (const [k, c] of Object.entries(M.celdas)) if (c.ajuste && !['pies', 'centro', 'exacto'].includes(c.ajuste)) E('celdas', `${k}: ajuste «${c.ajuste}» no válido`);

// cobertura contra el inventario real del juego
const want = { personajes: [], resto: [] };
INV.personajes.forEach(k => want.personajes.push('look:' + k));
INV.npcs.forEach(n => want.personajes.push('npc:' + n.id));
INV.tiles_suelo.forEach(k => want.resto.push('tile:' + k));
INV.objetos.forEach(k => want.resto.push('obj:' + k));
INV.combate.forEach(k => want.resto.push('combate:' + k));
INV.misc.forEach(k => want.resto.push('misc:' + k));
const covered = new Set(M.assets.flatMap(a => [...(a.cubre || []), ...(a.items || []).flatMap(i => i.cubre || [])]));
const allWant = new Set([...want.personajes, ...want.resto]);
for (const c of covered) if (!allWant.has(c)) E('cobertura', `«${c}» no existe en el inventario del juego`);
const pct = l => (100 * l.filter(k => covered.has(k)).length / l.length).toFixed(1);
const miss = [...want.personajes, ...want.resto].filter(k => !covered.has(k));
miss.forEach(k => E('cobertura', `nadie cubre «${k}»`));

// lotes: la suma de objetos de todos sus assets tiene que caber en los candidatos de una llamada
for (const [lid, l] of Object.entries(M.lotes || {})) {
  const as = M.assets.filter(a => a.lote === lid), n = as.reduce((s, a) => s + ((a.parametros || {}).item_descriptions || []).length, 0);
  const cap = l.size <= 42 ? 64 : l.size <= 85 ? 16 : l.size <= 170 ? 4 : 1;
  if (!as.length) W(lid, 'lote sin assets'); if (n > cap) E(lid, `${n} objetos no caben en los ${cap} candidatos de una llamada a ${l.size} px`);
}
// coste estimado (solo herramientas con coste documentado)
const DIRS_OF = a => a.parametros?.n_directions || 8;
let known = 0; const unknown = new Set();
for (const a of M.assets) {
  if (a.herramienta === 'create_character') known += a.parametros.mode === 'standard' ? 1 : a.parametros.mode === 'v3' ? 9 : 40;
  else if (a.herramienta === 'create_1_direction_object') { if (!a.lote || M.assets.find(b => b.lote === a.lote) === a) known += 30; }
  else if (a.herramienta === 'create_image_pixflux') known += 1;
  else if (a.herramienta === 'edit_image_pixen') known += Math.max(1, (a.llamadas || []).length);
  else if (a.herramienta === 'create_topdown_tileset') known += 4 * Math.max(1, (a.llamadas || []).length);
  else if (a.herramienta !== 'procedural') unknown.add(a.herramienta);
  if (a.previo) known += 30;
  for (const an of a.animaciones || []) {
    if (an.herramienta === 'animate_character') known += (an.direcciones || []).length || DIRS_OF(a);
    else if (an.herramienta === 'animate_image') known += 1;
    else unknown.add(an.herramienta);
  }
}

const out = [
  `assets: ${M.assets.length}${RETIRADOS.length ? ` (+${RETIRADOS.length} retirados)` : ''} (+${M.assets.reduce((n, a) => n + (a.items || []).length, 0)} items) · animaciones: ${M.assets.reduce((n, a) => n + (a.animaciones || []).length + (a.items || []).reduce((m, i) => m + (i.animaciones || []).length, 0), 0)}`,
  `cobertura_personajes: ${pct(want.personajes)} (${want.personajes.length} claves)`,
  `cobertura_resto: ${pct(want.resto)} (${want.resto.length} claves)`,
  `coste_conocido: ~${known} generaciones · sin coste documentado: ${[...unknown].join(', ') || '—'}`,
  `AVISOS: ${warns.length}`, ...warns.map(w => '  · ' + w),
  `ERRORES: ${errors.length}`, ...errors.map(e => '  ✗ ' + e),
];
console.log(out.join('\n'));
process.exit(errors.length ? 1 : 0);
