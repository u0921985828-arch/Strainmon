#!/usr/bin/env node
/*
  Ribera Verde — exporta el arte procedural actual como PNG de referencia y el inventario de assets.
  Sirve para dos cosas: (1) pasar a PixelLab referencias de estilo reales del juego
  (no descripciones), y (2) saber qué assets hay que cubrir con sprites.

  Uso:  node tools/build.js && node tools/sprites/referencias.js
  Sale: art/inventario.json · art/referencias/{tiles,objetos,personajes,plantas,combate,misc,mapa}/*.png
        (mapa/: recortes del suelo + máscara para create_map_object con estilo del mapa)
        art/referencias/estilo/*_x2.png (personajes de frente al doble, para reference_image)
        art/referencias/_hoja-*.png (hojas de contacto a 4×, para revisar a ojo)
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..');
const OUT = path.join(ROOT, 'art', 'referencias');

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('file://' + path.join(ROOT, 'index.html'));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');

  await page.evaluate(() => arteListo());   // si el build lleva atlas, los recortes de mapa/ salen con los tiles ya aprobados
  const data = await page.evaluate(() => {
    S = newState(); S.carpas = [{ t: 'p60', foco: 'cfl' }, { t: 'g150', foco: 'cfl' }]; montarCasa();   // el piso con las dos carpas
    const png = c => c.toDataURL('image/png');
    const up = (c, k) => { const [o, x] = mkCanvas(c.width * k, c.height * k); x.drawImage(c, 0, 0, c.width * k, c.height * k); return o; };
    // qué claves de TILES se usan como suelo y cuáles como objeto
    const ground = new Set(), objects = new Set();
    for (const m of Object.values(MAPS)) for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) { ground.add(m.g[y][x]); if (m.o[y][x]) objects.add(m.o[y][x]); }
    const files = {};
    for (const [k, frames] of Object.entries(TILES)) {
      const dir = objects.has(k) ? 'objetos' : 'tiles';
      frames.forEach((c, i) => { files[`${dir}/${k}${frames.length > 1 ? '_f' + i : ''}.png`] = png(c); });
    }
    // personajes: looks fijos + familias aleatorias (clientes y ladrones) con semillas fijas
    const looks = Object.assign({}, LOOKS);
    for (let i = 1; i <= 6; i++) looks['cliente' + i] = randLook('cliente' + i, 'client');
    for (let i = 1; i <= 3; i++) looks['ladron' + i] = randLook('ladron' + i, 'thief');
    const dirs = ['down', 'up', 'left', 'right'];
    for (const [id, L] of Object.entries(looks)) {
      const [sheet, sx] = mkCanvas(16 * 3, 20 * 4);
      dirs.forEach((d, r) => [0, 1, 2].forEach(f => { const c = spriteFor(L, d, f); files[`personajes/${id}/${d}_${f}.png`] = png(c); sx.drawImage(c, f * 16, r * 20); }));
      files[`personajes/${id}.png`] = png(sheet);
      files[`estilo/${id}_south_x2.png`] = png(up(spriteFor(L, 'down', 0), 2));
    }
    files['combate/fondo-ladron.png'] = png(battleBg.thief);
    files['combate/fondo-policia.png'] = png(battleBg.police);
    files['misc/bolsa.png'] = png(bagSprite);
    files['misc/hoja-titulo.png'] = png(titleArt);
    { renderTitle(0); const [c, x] = mkCanvas(240, SH); x.drawImage(ctx.canvas, -OX(), 0); files['misc/titulo.png'] = png(c); }   // los 240 px del centro (SW cambia con la ventana)   // pantalla de título entera (init_image de F7)
    // mapa: recortes del suelo para create_map_object con estilo del mapa (inpainting; máscara BLANCA = lo que genera PixelLab)
    const region = (mapN, x0, y0, w, h, quitar) => { const m = MAPS[mapN], [c, x] = mkCanvas(w * 16, h * 16);
      for (let ty = 0; ty < h; ty++) for (let tx = 0; tx < w; tx++) { const X = x0 + tx, Y = y0 + ty; if (X < 0 || Y < 0 || X >= m.w || Y >= m.h) continue;
        const k = m.g[Y][X], f = ARTE.ok && frameDe(ARTE.cubre['tile:' + k], k, 'unica', 0, { i: 0 });
        x.drawImage(f ? f.c : TILES[k][0], tx * 16, ty * 16);
        const o = m.o[Y][X]; if (o && !(quitar && quitar(X, Y))) { const fo = ARTE.ok && frameDe(ARTE.cubre['obj:' + o], o, 'unica', 0, { i: 0 });
          if (fo) x.drawImage(fo.c, tx * 16 + 8 - fo.cel.ancla[0], ty * 16 + 15 - fo.cel.ancla[1]); else x.drawImage(TILES[o][0], tx * 16, ty * 16); } }
      return c; };
    const mascara = (w, h, [rx, ry, rw, rh]) => { const [c, x] = mkCanvas(w, h); x.fillStyle = '#000000'; x.fillRect(0, 0, w, h); x.fillStyle = '#ffffff'; x.fillRect(rx, ry, rw, rh); return c; };
    for (const b of MAPS.town.blds) { const c = region('town', b.x0 - 1, b.y0 - 1, b.w + 2, b.h + 2);
      files[`mapa/edificio-${b.id}.png`] = png(c); files[`mapa/edificio-${b.id}_mascara.png`] = png(mascara(c.width, c.height, [16, 16, b.w * 16, b.h * 16])); }
    // carpas: el mueble del piso (16 px/m) y, de la vista B (48 px/m, P2), cada carpa en 3/4, el cuarto, las macetas, las
    // plantas por porte y fase (cogollos en el verde de referencia), los focos y los extras (las láminas, en huellas.js)
    for (const t of Object.keys(CARPAS)) { files[`misc/carpa-${t}-mapa.png`] = png(carpaMapa(t)); files[`misc/carpa-${t}-34.png`] = png(carpa34(t)); }
    files['misc/cuarto-34.png'] = png(cuarto34());
    for (const k of Object.keys(MACETAS)) files[`misc/maceta-34-${k}.png`] = png(maceta34(k));
    for (const po of ['i', 's', 'h']) { FASES.forEach((f, st) => { files[`misc/planta-34-${po}-${f}.png`] = png(planta34(po, st, false, '#9bd35a')); });
      files[`misc/planta-34-${po}-muerta.png`] = png(planta34(po, 9, false, '#9bd35a')); }
    for (const k of Object.keys(FOCOS)) files[`misc/foco-34-${k}.png`] = png(foco34(k));
    for (const k of Object.keys(EXTRAS)) files[`misc/extra-34-${k}.png`] = png(extra34(k));
    for (const [k, X, Y] of [['tree', 28, 15], ['lamp', 14, 14], ['fountain', 20, 19]]) {
      const c = region('town', X - 1, Y - 2, 3, 4, (x, y) => x === X && y === Y);
      files[`mapa/${k}.png`] = png(c); files[`mapa/${k}_mascara.png`] = png(mascara(c.width, c.height, [8, 16, 32, 32]));
    }
    const inventario = {
      generado: new Date().toISOString().slice(0, 10),
      tiles_suelo: [...ground].sort(),
      objetos: [...objects].filter(k => k !== 'carpa').sort(),   // la carpa del piso es misc:carpa-<t>-mapa
      tiles_animados: Object.entries(TILES).filter(([, f]) => f.length > 1).map(([k, f]) => ({ clave: k, fotogramas: f.length })),
      personajes: Object.keys(looks),
      personajes_fijos: Object.keys(LOOKS),
      npcs: NPCDEF.map(d => ({ id: d.id, look: d.look, mapa: d.map, deambula: !!d.wander })),
      plantas: { vista: 'misc:planta-vista (cepa × fase, de ../assets/plants)', colores_cogollo: Object.fromEntries(Object.entries(STRAINS).map(([k, s]) => [k, s.c])) },
      combate: ['fondo-ladron', 'fondo-policia', 'frente:ladron', 'frente:policia', 'espalda:player'],
      misc: ['bolsa', 'hoja-titulo', 'burbuja-$', 'burbuja-!', ...Object.keys(CARPAS).flatMap(t => ['carpa-' + t + '-mapa', 'carpa-' + t + '-vista']), 'cuarto-cultivo', 'carpa-c-pared', 'carpa-c-luz', 'foco-c-40', 'foco-c-44', 'foco-c-46', 'maceta-c-15', 'maceta-c-22', 'foco-c-cfl-36', ...['i', 'h', 's'].flatMap(p => [38, 32].flatMap(w => ['planta-c-' + p + '-' + w, 'planta-c-' + p + '2-' + w])), 'planta-c-h1-18', 'planta-c-h0-8',
        ...Object.keys(MACETAS).map(k => 'maceta-vista-' + k), 'planta-vista', 'foco-cfl', 'foco-sodio', 'foco-led', 'detalles'],   // detalles: los de la hierba (orgánico, 1.10)
      tamanos: { tile: [16, 16], personaje: [16, 20], planta: [16, 26], combate_escala: 3, pantalla: [240, 160] },
    };
    return { files, inventario, origenMapa: ARTE.ok ? 'tiles del atlas' : 'tiles procedurales' };
  });

  // hojas de contacto a 4× (vecino más próximo) para revisión visual
  const sheets = await page.evaluate(async files => {
    const load = src => new Promise(r => { const i = new Image(); i.onload = () => r(i); i.src = src; });
    const make = async (keys, cols, cell) => {
      const imgs = await Promise.all(keys.map(k => load(files[k])));
      const rows = Math.ceil(imgs.length / cols), pad = 4, k4 = 4;
      const [c, x] = mkCanvas(cols * (cell[0] * k4 + pad) + pad, rows * (cell[1] * k4 + pad) + pad);
      x.fillStyle = '#7f8a86'; x.fillRect(0, 0, c.width, c.height);
      imgs.forEach((im, i) => x.drawImage(im, pad + (i % cols) * (cell[0] * k4 + pad), pad + Math.floor(i / cols) * (cell[1] * k4 + pad), im.width * k4, im.height * k4));
      return c.toDataURL('image/png');
    };
    const ks = Object.keys(files);
    return {
      '_hoja-tiles.png': await make(ks.filter(k => k.startsWith('tiles/')), 12, [16, 16]),
      '_hoja-objetos.png': await make(ks.filter(k => k.startsWith('objetos/')), 10, [16, 16]),
      '_hoja-personajes.png': await make(ks.filter(k => /^personajes\/[^/]+\.png$/.test(k)), 8, [48, 80]),
    };
  }, data.files);

  fs.rmSync(OUT, { recursive: true, force: true });
  let n = 0;
  for (const [rel, url] of Object.entries({ ...data.files, ...sheets })) {
    const f = path.join(OUT, rel); fs.mkdirSync(path.dirname(f), { recursive: true });
    fs.writeFileSync(f, Buffer.from(url.split(',')[1], 'base64')); n++;
  }
  fs.writeFileSync(path.join(ROOT, 'art', 'inventario.json'), JSON.stringify(data.inventario, null, 2) + '\n');
  await browser.close();
  console.log(`recortes de mapa/: ${data.origenMapa}`);
  console.log(`${n} PNG en art/referencias · inventario: ${data.inventario.tiles_suelo.length} tiles de suelo, ${data.inventario.objetos.length} objetos, ${data.inventario.personajes.length} personajes`);
  if (errors.length) { console.error(errors); process.exit(1); }
})();
