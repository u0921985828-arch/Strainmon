#!/usr/bin/env node
/*
  Ribera Verde — los sitios se pueden andar (1.34, lo pidió el usuario: «verifica que son bien accesibles las habitaciones»)
  En cada mapa, con todo montado (el piso con todos los muebles, la nave con todo el equipo y las madres), desde cada sitio por el
  que se llega (las puertas y salidas de los otros mapas que dan a él y la parada del autobús), anda por las casillas libres (las
  mismas que tileSolid; la gente quieta, como un mueble) y comprueba:
   1. que se llega a cada puerta y a cada salida del mapa;
   2. que se puede hablar con cada persona quieta (una casilla libre al lado, o al otro lado de un mostrador: COUNTERS);
   3. en los interiores, que cada mueble y cada cosa de la pared se puede mirar con A (una casilla libre al lado; los de la pared,
      desde la de debajo; los de 2 casillas, por cualquiera de las dos), salvo los de PRIVADO (detrás del mostrador o de la barra);
   4. que nadie está quieto en la casilla por la que se llega.
  Uso: node tools/test-accesos.js (después de node tools/build.js). Sale con 1 si algo no se alcanza.
*/
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage({ viewport: { width: 1000, height: 700 } });
  const errores = [];
  page.on('pageerror', e => errores.push(e.message));
  await page.goto('file://' + path.join(__dirname, '..', 'index.html'));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
  const r = await page.evaluate(() => {
    S = newState(); S.ch = 8; mode = 'world';
    // todo montado: los muebles del salón, la nave con el equipo a tope y la gente de la plantilla en su sitio
    S.muebles = Object.fromEntries(Object.keys(MUEBLES).map(k => [k, 0])); S.nave = naveNueva(); S.nave.ex = EXTR_NAVE.length - 1; S.nave.rg = RIEGO_NAVE.length - 1;
    S.plantilla = [0, 1, 2, 3].map(i => ({ id: 'pl' + i, n: BARRIO[i], lab: 3, cui: 3, lea: 3, rol: 'nave', mesa: i }))
      .concat([{ id: 'pl4', n: BARRIO[4], lab: 3, cui: 3, lea: 3, rol: 'madres' }]);
    if (typeof montarCasa === 'function') montarCasa(); montarNave();
    // lo que no hace falta mirar de cerca: lo de detrás de un mostrador o de una barra (a la gente de detrás se le habla por encima)
    // y el reservado de GAUA, que abre la RRPP; [mapa:objeto] o [mapa:x,y]
    const PRIVADO = new Set(['shop:4,1', 'bar:bottles', 'bar:barcounter', 'disco:bottles', 'disco:neon', 'disco:mesaV', 'disco:cordon',
      ...Object.keys(CLUBS).map(k => 'club-' + k + ':tarros'), 'home:6,1']);   // home: la ventana de encima del banco de la tía (se ve desde el cuarto)
    const ARRIBA = { bedT: 'bedB' };   // la cabecera de la cama: se mira desde la cama
    // lo que va junto y dice lo mismo (las mesitas de un grupo de sofás, las cajas apiladas): basta con llegar a una de ellas
    const JUNTOS = new Set(['mesita', 'crate']);
    const llegadas = {};
    const add = (k, x, y, de) => (llegadas[k] = llegadas[k] || []).push([x, y, de]);
    for (const [n, m] of Object.entries(MAPS)) {
      for (const [k, d] of Object.entries(m.doors || {})) add(d.to, d.x, d.y, n + ' puerta ' + k);
      for (const [k, d] of Object.entries(m.exits || {})) add(d.to, d.x, d.y, n + ' salida ' + k);
    }
    for (const [k, p] of Object.entries(PARADAS)) add(k, p.a[0], p.a[1], 'autobús');
    const fallos = [], visto = {};
    for (const [n, m] of Object.entries(MAPS)) {
      S.map = n; ents = []; buildEnts();
      const quietos = ents.filter(e => !e.wander && !e.pat), quieto = (x, y) => quietos.some(e => e.x === x && e.y === y);
      const libre = (x, y) => !tileSolid(m, x, y) && !quieto(x, y);
      const ini = (llegadas[n] || []).filter(([x, y]) => x >= 0 && y >= 0 && x < m.w && y < m.h);
      if (!ini.length) { visto[n] = 'sin llegada'; continue; }
      for (const [x, y, de] of ini) if (quieto(x, y)) fallos.push(`${n}: alguien quieto en la llegada (${x}, ${y}) desde ${de}`);
      const R = new Set(), cola = [];
      for (const [x, y] of ini) { const k = x + ',' + y; if (!R.has(k)) { R.add(k); cola.push([x, y]); } }
      while (cola.length) {
        const [x, y] = cola.shift();
        for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          const nx = x + dx, ny = y + dy, k = nx + ',' + ny;
          if (R.has(k) || !libre(nx, ny)) continue;
          R.add(k); cola.push([nx, ny]);
        }
      }
      const en = (x, y) => R.has(x + ',' + y);
      const lado = (x, y) => [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => en(x + dx, y + dy));
      const cruza = (x, y) => [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => { const o = m.o[y + dy] && m.o[y + dy][x + dx];
        return o && COUNTERS.has(o) && en(x + 2 * dx, y + 2 * dy); });
      for (const k of Object.keys(m.doors || {}).concat(Object.keys(m.exits || {}))) if (!R.has(k)) fallos.push(`${n}: no se llega a la puerta o salida ${k}`);
      for (const e of quietos) if (!lado(e.x, e.y) && !cruza(e.x, e.y)) fallos.push(`${n}: no se puede hablar con ${e.id} (${e.x}, ${e.y})`);
      if (!ZONAS[n]) for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) {
        const o = m.o[y][x];if (!o || PRIVADO.has(n + ':' + o) || PRIVADO.has(n + ':' + x + ',' + y)) continue;
        if (ARRIBA[o] && m.o[y + 1] && m.o[y + 1][x] === ARRIBA[o]) continue;
        const izq = LOCAL2.has(o) || SEGUNDA.has(o) ? [x - 1, y] : null;
        const ok = y === 1 ? en(x, 2) || (izq && en(izq[0], 2)) : lado(x, y) || (izq && lado(...izq)) || (m.o[y][x + 1] === o + '2' && lado(x + 1, y));
        const junto = JUNTOS.has(o) && [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => m.o[y + dy] && m.o[y + dy][x + dx] === o && lado(x + dx, y + dy));
        if (!ok && !junto) fallos.push(`${n}: no se puede mirar ${o} (${x}, ${y})`);
      }
      visto[n] = R.size;
    }
    return { fallos, visto };
  });
  const n = Object.keys(r.visto).length;
  for (const f of r.fallos) console.log('FALLO  ' + f);
  for (const e of errores) console.log('ERROR  ' + e);
  console.log(`accesos: ${n} mapas, ${r.fallos.length} fallos, ${errores.length} errores JS`);
  await browser.close();
  process.exit(r.fallos.length || errores.length ? 1 : 0);
})();
