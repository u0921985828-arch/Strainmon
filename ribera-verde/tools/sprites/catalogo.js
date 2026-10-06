#!/usr/bin/env node
/*
  Ribera Verde — catálogo de sprites por familia de herramienta de PixelLab
  Lee art/manifest.json y art/inventario.json y escribe:
    docs/CATALOGO-SPRITES.md   qué sprite sale de qué herramienta, en qué lote, con qué entrada, en qué orden y cuánto cuesta
    art/catalogo.json          lo mismo, clave a clave (para scripts)
  Sale con código 1 si alguna clave del juego no está catalogada o lo está dos veces.
  Uso:  node tools/sprites/catalogo.js
*/
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..', '..');
const M = JSON.parse(fs.readFileSync(path.join(ROOT, 'art', 'manifest.json'), 'utf8'));
const INV = JSON.parse(fs.readFileSync(path.join(ROOT, 'art', 'inventario.json'), 'utf8'));

// claves que tiene que cubrir el arte (las mismas que comprueba validar.js)
const want = [
  ...INV.personajes.map(k => 'look:' + k), ...INV.npcs.map(n => 'npc:' + n.id),
  ...INV.tiles_suelo.map(k => 'tile:' + k), ...INV.objetos.map(k => 'obj:' + k),
  ...INV.plantas.fases.map(k => 'planta:' + k), ...INV.plantas.variantes.map(k => 'planta-variante:' + k),
  ...INV.combate.map(k => 'combate:' + k), ...INV.misc.map(k => 'misc:' + k)];

const lote = a => {
  const p = a.parametros || {};
  switch (a.herramienta) {
    case 'create_character': return p.mode === 'standard' ? `${p.n_directions} direcciones, ${p.size} px` : `${p.mode}: 8 direcciones, ${p.size} px`;
    case 'create_1_direction_object': {
      const n = (p.item_descriptions || []).length, sz = p.size || 16, cand = sz <= 42 ? 64 : sz <= 85 ? 16 : sz <= 170 ? 4 : 1;
      if (a.lote) { const as = M.assets.filter(b => b.lote === a.lote), tot = as.reduce((s, b) => s + ((b.parametros || {}).item_descriptions || []).length, 0);
        return `${n} objetos · **comparte ${a.lote}** (${tot} objetos de ${as.length} assets en 1 llamada de ${cand} candidatos a ${sz} px)`; }
      return `${n} objetos en 1 llamada (${cand} candidatos a ${sz} px)`; }
    case 'create_tiles_pro': return `${(a.cubre || []).length} tiles numerados en 1 llamada`;
    case 'create_building_kit': return 'kit: suelo + paredes conectables';
    case 'create_map_object': return '1 por llamada, sobre el recorte del mapa';
    case 'create_topdown_tileset': return `${(a.llamadas || []).length} juegos Wang de 16 tiles`;
    case 'create_image_pixflux': return 'pantalla entera, img2img';
    default: return '—';
  }
};
const gen = a => { // generaciones aproximadas (null = sin coste documentado)
  const p = a.parametros || {}; let g = 0; const unknown = [];
  const base = { create_character: p.mode === 'standard' ? 1 : p.mode === 'v3' ? 9 : 40, create_1_direction_object: 30, create_image_pixflux: 1,
    create_topdown_tileset: 4 * Math.max(1, (a.llamadas || []).length), procedural: 0 }[a.herramienta];
  // en un lote solo paga la llamada el primer asset
  if (a.lote && M.assets.find(b => b.lote === a.lote) !== a) { g -= base; }
  if (base == null) unknown.push(a.herramienta); else g += base;
  if (a.previo) g += 30;
  for (const an of [...(a.animaciones || []), ...(a.items || []).flatMap(i => i.animaciones || [])]) {
    if (an.herramienta === 'animate_character') g += (an.direcciones || []).length || 4;
    else if (an.herramienta === 'animate_image') g += 1;
    else unknown.push(an.herramienta);
  }
  return { g, unknown };
};
const entrada = a => {
  const e = Object.entries(a.entrada || {}).map(([k, v]) => `${k}: ${(Array.isArray(v) ? v : [v]).map(f => path.basename(f)).join(', ')}`);
  const refs = a.previo && ((a.previo.entrada || {}).reference_images || []);
  if (a.previo) e.unshift(refs.length ? `previo create_image_pro ← ${refs.map(r => path.basename(path.dirname(path.dirname(path.dirname(r.archivo)))) + ' aprobado').join(', ')}` : 'previo create_image_pro (solo texto)');
  return e.join(' · ') || 'solo texto';
};
const anims = a => {
  const all = [...(a.animaciones || []), ...(a.items || []).flatMap(i => (i.animaciones || []).map(an => ({ ...an, nombre: i.id + '/' + an.nombre })))];
  return all.map(an => an.nombre + (an.plantilla ? '' : an.herramienta === 'animate_character' ? '*' : '')).join(', ') || '—';
};

// catálogo clave a clave
// una clave puede salir de varios assets cuando son variantes del mismo papel (los 3 ladrones de combate)
const cat = {}, dobles = [];
for (const a of M.assets) {
  const keys = [...(a.cubre || []), ...(a.items || []).flatMap(i => i.cubre || [])];
  for (const k of keys) {
    cat[k] = cat[k] || [];
    if (cat[k].some(c => c.asset === a.id)) dobles.push(`${k} repetida en ${a.id}`);
    cat[k].push({ asset: a.id, familia: a.familia, herramienta: a.herramienta, fase: a.fase, depende_de: a.depende_de || [] });
  }
}
const faltan = want.filter(k => !cat[k]);

// markdown
const fams = Object.entries(M.familias);
const L = [];
L.push('# Catálogo de sprites por herramienta de PixelLab', '',
  '> Generado por `node tools/sprites/catalogo.js` desde `art/manifest.json`. No lo edites a mano: cambia el manifiesto y vuelve a generarlo.', '',
  'Cada sprite del juego sale de la familia de herramientas que mejor lo resuelve: los personajes con rig, el terreno como tiles, lo que se apoya en el suelo pintado sobre el propio mapa, lo pequeño en lotes y las pantallas como imagen. Así se gastan menos generaciones y todo comparte estilo.', '');
L.push('## Resumen', '', '| Familia | Claves del juego | Assets | Herramientas | Generaciones aprox. |', '|---|---|---|---|---|');
let total = 0, sinCoste = new Set();
for (const [fid, f] of fams) {
  const as = M.assets.filter(a => a.familia === fid); if (!as.length) continue;
  const claves = Object.values(cat).filter(c => c.some(x => x.familia === fid)).length;
  let g = 0, u = false; for (const a of as) { const r = gen(a); g += r.g; if (r.unknown.length) { u = true; r.unknown.forEach(t => sinCoste.add(t)); } }
  total += g;
  L.push(`| ${f.nombre} | ${claves} | ${as.length} | ${f.herramientas.join(' · ') || '—'} | ${g}${u ? ' + sin documentar' : ''} |`);
}
L.push('', `**Total documentado: ~${total} generaciones** (más ${[...sinCoste].join(', ')}, que PixelLab no publica: mira \`get_balance\` antes y después). Cobertura: ${want.length - faltan.length}/${want.length} claves.`, '');

L.push('## Orden de creación', '', 'Las dependencias mandan: nada que use el estilo de otra cosa se genera antes de que esa otra esté aprobada.', '');
const fases = M.fases.map(f => f.id);
for (const fid of fases) {
  const as = M.assets.filter(a => a.fase === fid); if (!as.length) continue;
  const fase = M.fases.find(f => f.id === fid);
  L.push(`- **${fid} · ${fase.nombre}:** ${as.map(a => a.id + (a.depende_de ? ` (tras ${a.depende_de.join(', ')})` : '') + (a.opcional ? ' — opcional' : '')).join(', ')}.`);
}
L.push('');

for (const [fid, f] of fams) {
  const as = M.assets.filter(a => a.familia === fid); if (!as.length) continue;
  L.push(`## ${f.nombre}`, '', f.por_que, '', '| Asset | Cubre | Herramienta | Lote | Entrada | Fase | Animaciones | Gen. |', '|---|---|---|---|---|---|---|---|');
  for (const a of as) {
    const keys = [...(a.cubre || []), ...(a.items || []).flatMap(i => i.cubre || [])];
    const cubre = keys.length ? [...new Set(keys.map(k => k.split(':').slice(1).join(':')))].join(', ') : (a.items ? a.items.map(i => i.id).join(', ') : '—');
    const r = gen(a);
    L.push(`| ${a.id} | ${cubre} | ${a.herramienta}${a.parametros && a.parametros.mode ? ' (' + a.parametros.mode + ')' : ''} | ${lote(a)} | ${entrada(a)} | ${a.fase}${a.depende_de ? ' · tras ' + a.depende_de.join(', ') : ''} | ${anims(a)} | ${r.g}${r.unknown.length ? '+?' : ''} |`);
  }
  L.push('');
  if (fid === 'personaje') L.push('`*` = animación a medida (`action_description`, modo v3); el resto son plantillas a 1 generación por dirección.', '');
}

L.push('## Lotes compartidos', '', 'Una llamada a `create_1_direction_object` de ≤42 px devuelve 64 candidatos y cuesta lo mismo con 2 objetos que con 60. Por eso los assets del mismo tamaño y sin `style_images` comparten llamada: se juntan sus `item_descriptions`, se eligen los candidatos con `select_object_frames` y cada uno va a la carpeta de su asset en `art/crudo/`.', '');
for (const [lid, l] of Object.entries(M.lotes || {})) {
  const as = M.assets.filter(a => a.lote === lid), n = as.reduce((s, a) => s + ((a.parametros || {}).item_descriptions || []).length, 0);
  L.push(`- **${lid}** (${l.size} px, se genera en ${l.se_genera_en}): ${as.map(a => `${a.id} (${(a.parametros.item_descriptions || []).length})`).join(', ')} → ${n} objetos, 1 llamada. Ahorro: ${(as.length - 1) * 30} generaciones. ${l.nota}`);
}
L.push('');
L.push('## Llamadas encadenadas', '');
for (const a of M.assets.filter(a => a.previo)) {
  const refs = (a.previo.entrada || {}).reference_images || [];
  L.push(`**${a.id}**`, `1. \`create_image_pro\` ${a.previo.parametros.width}×${a.previo.parametros.height} ${refs.length ? `con \`reference_images\` = ${refs.map(r => '`' + r.archivo + '` («' + r.usage + '»)').join(', ')}` : 'solo con texto'}. Elige ${a.previo.elegir} y guárdalo en \`${a.previo.guarda}\`.`,
    `2. \`create_character\` mode v3, size ${a.parametros.size}, \`reference_image_base64\` = ese PNG: lo rota a 8 direcciones y queda animable.`, '');
}
for (const a of M.assets.filter(a => a.llamadas)) {
  L.push(`**${a.id}** (${a.herramienta}, ${a.opcional ? 'opcional' : 'obligatorio'})`);
  a.llamadas.forEach((l, i) => L.push(`${i + 1}. \`${l.id}\`: lower «${l.lower_description}» → upper «${l.upper_description}», transition_size ${l.transition_size}${l.upper_base_tile_id ? ', `upper_base_tile_id` = ' + l.upper_base_tile_id : ''}${l.guarda_base ? ' — guarda el id del tile de ' + l.guarda_base + ' (get_topdown_tileset)' : ''}.`));
  L.push('');
}
L.push('**Objetos con el estilo del mapa** (`create_map_object`): `background_image` = recorte del mapa de `art/referencias/mapa/` y `inpainting` = `{"type": "mask", "mask_image": "<máscara en base64>"}` con la máscara `*_mascara.png` (blanco = lo que genera, negro = suelo que se conserva). Las fachadas y los props de exterior se generan después de aprobar `tiles-exterior`: regenera antes los recortes con los tiles nuevos (`npm run sprites:ref` con el atlas puesto) para que el contexto ya sea el arte final.', '');

L.push('## Herramientas que no se usan (y por qué)', '', '| Herramienta | Motivo |', '|---|---|');
for (const d of M.descartadas) L.push(`| ${d.herramienta} | ${d.motivo} |`);
L.push('');

fs.writeFileSync(path.join(ROOT, 'docs', 'CATALOGO-SPRITES.md'), L.join('\n'));
fs.writeFileSync(path.join(ROOT, 'art', 'catalogo.json'), JSON.stringify({ generado: 'tools/sprites/catalogo.js', claves: want.length, catalogo: cat }, null, 1) + '\n');
console.log(`catálogo: ${want.length - faltan.length}/${want.length} claves · ${M.assets.length} assets · ~${total} generaciones documentadas → docs/CATALOGO-SPRITES.md`);
faltan.forEach(k => console.log('  falta: ' + k)); dobles.forEach(d => console.log('  doble: ' + d));
process.exit(faltan.length || dobles.length ? 1 : 0);
