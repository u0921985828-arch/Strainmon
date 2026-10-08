#!/usr/bin/env node
/*
  Ribera Verde — pantallas de prueba para el port de Godot (godot/tests/pantallas.gd): el HTML monta cada escena (mapa, hora,
  jugador, personajes con sus acciones, clientes, objetos, efectos, combate, título o carpa en la vista B), la pinta con su
  render de siempre (renderWorld, renderBattle, renderTitle, renderCarpa) a su ancho (SW de 240 a 400) y guarda:
  - tools/salida/godot/html-p-<escena>.png: lo que pinta el HTML;
  - godot/tests/pantallas.json: el estado de cada escena tal cual (S, P, personajes, combate, carpa abierta, efectos y el instante),
    tomado justo antes de pintar, para que Godot pinte lo mismo.
  El azar va con un Park-Miller fijo (clientes) y el ambiente de los personajes (que tira de Math.random al pintar) no hace nada:
  las acciones de las escenas van puestas a mano (con el humo, como las pone ambiente).
  Uso: node tools/build.js && node tools/godot-pantallas.js [--pantallas f.json] [--salida dir]
  (con --pantallas: otras escenas, p. ej. el caso reservado; escribe su pantallas.json y sus PNG en --salida)
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : d; };
const PAN = arg('--pantallas'), SAL = arg('--salida', path.join(__dirname, 'salida', 'godot'));

const pl = (sid, prog, o = {}) => Object.assign({ sid, prog, water: 70, health: 100, fert: false, pest: false, f: { id: 1, t: 1, y: 1, i: null } }, o);
const T = 123456;   // el instante de las escenas (ms)
// cada escena: k, sw, mode, now, seed (azar de los clientes), S (encima de newState()), carpas/macetas/pots, map + P (enterMap y
// luego lo demás de P), clientes (spawnClients), ents ({id: campos}), SOSP (encima de la de enterMap), vfx ([id, x, y, hace ms, capa,
// sube]), B, VC
const PANTALLAS = PAN ? JSON.parse(fs.readFileSync(PAN, 'utf8')) : [
  // el piso: carpa 100 del atlas con plantas (luz bajo la puerta), carpa 120 procedural vacía, sitio libre de 2 casillas y la carta
  { k: 'casa-a', sw: 240, mode: 'world', now: T, S: { ch: 2, flags: {} }, carpas: [{ t: 'm100', foco: 'sodio400' }, { t: 'm120', foco: 'cfl' }],
    pots: { 0: pl('ria', .5), 1: pl('limon', .3) }, map: 'home', P: { x: 5, y: 5, dir: 'up' } },
  // armario 80 procedural con LED y plantas, sitio libre B (2 casillas), carta cogida; el jugador cruzando (con su polen)
  { k: 'casa-b', sw: 320, mode: 'world', now: T + 777, S: { ch: 4, flags: { letter: true, kiko1: true } }, carpas: [{ t: 'p80', foco: 'led200' }],
    pots: { 1: pl('txoko', .7) }, map: 'home', P: { x: 8, y: 4, dir: 'left', act: { n: 'cruzar', t0: T + 777 - 300 } },
    vfx: [['vfx-polen', 8 * 16 + 8, 4 * 16 - 4, 300, 'home', false]] },
  // la plaza de día: el jugador andando, policía con la radio, Molina fumando (con su humo), clientes (uno andando), Patxi y su
  // paloma, bocadillos, la fuente animada y monedas
  { k: 'calle-plaza', sw: 320, mode: 'world', now: T, seed: 4242, S: { ch: 6, min: 12 * 60, day: 3, rep: 30, flags: { darko1: true } }, clientes: true,
    map: 'town', P: { x: 19, y: 21, dir: 'right', moving: true, fx: 18, fy: 21, t: 90, dur: 240, parity: 1, px: (18 + 90 / 240) * 16, py: 21 * 16, pisT: T - 90 },
    ents: { cop: { act: { n: 'radio', t0: T - 500 } }, molina: { act: { n: 'fumar', t0: T - 900, humo: { vfx: 'vfx-humo-cigarro', frame: 7, off: [4, -18] } } },
      c3_0: { moving: true, fx: null, t: 200 } },
    vfx: [['vfx-monedas', 19 * 16 + 8, 21 * 16 + 2, 120, 'town', false]] },
  // la hierba alta pisada, Txaro y Unai, la bolsa del suelo
  { k: 'calle-hierba', sw: 240, mode: 'world', now: T + 4321, seed: 7, S: { ch: 3, min: 9 * 60 + 30, flags: {} }, map: 'town',
    P: { x: 9, y: 19, dir: 'down', pisT: T + 4321 - 160 } },
  // el muelle a las 20:00 (luz de tarde, empieza la noche y las farolas): el jugador corriendo por el puente, gaviotas, Iñaki
  { k: 'calle-tarde', sw: 360, mode: 'world', now: T + 999, seed: 99, S: { ch: 6, min: 20 * 60, day: 5, flags: {} }, clientes: true, map: 'town',
    P: { x: 32, y: 19, dir: 'right', moving: true, fx: 31, fy: 19, t: 70, dur: 130, parity: 0, px: (31 + 70 / 130) * 16, py: 19 * 16 } },
  { k: 'tienda', sw: 280, mode: 'world', now: T + 50, S: { ch: 4, flags: { kiko1: true } }, map: 'shop', P: { x: 4, y: 5, dir: 'up' },
    ents: { kiko: { act: { n: 'semillas', t0: T + 50 - 400 } } } },
  { k: 'bar', sw: 240, mode: 'world', now: T + 3000, S: { ch: 5, flags: {} }, map: 'bar', P: { x: 4, y: 6, dir: 'up' },
    ents: { baltasar: { act: { n: 'puro', t0: T + 3000 - 950, humo: { vfx: 'vfx-humo-puro', frame: 7, off: [5, -17] } } }, josune: { act: { n: 'servir', t0: T + 2700 } } } },
  // el mapa ampliado (1.10): el barrio alto de día con sus clientes y la puerta ancha de la comisaría abierta (el jugador delante);
  // los astilleros de noche (farolas de su zona, Darko en su esquina y la puerta del almacén, con la pared de la máscara);
  // y los tres interiores nuevos con su personaje
  { k: 'alto', sw: 360, mode: 'world', now: T + 2222, seed: 31, S: { ch: 5, min: 11 * 60, day: 6, flags: { molina1: true } }, clientes: true, map: 'alto',
    P: { x: 27, y: 19, dir: 'up' } },
  { k: 'astilleros-noche', sw: 400, mode: 'world', now: T + 5555, seed: 77, S: { ch: 8, min: 22 * 60 + 30, day: 40, flags: {}, encargo: { g: 2000, hasta: 41 } },
    clientes: true, map: 'astilleros', P: { x: 18, y: 14, dir: 'up' } },
  { k: 'comisaria', sw: 240, mode: 'world', now: T + 300, S: { ch: 5, flags: { molina1: true } }, map: 'comisaria', P: { x: 4, y: 6, dir: 'up' } },
  { k: 'almacen', sw: 280, mode: 'world', now: T + 900, S: { ch: 8, min: 23 * 60, day: 40, flags: {}, encargo: { g: 2000, hasta: 41 } }, map: 'almacen',
    P: { x: 4, y: 6, dir: 'up' } },
  { k: 'casa-txaro', sw: 240, mode: 'world', now: T + 60, S: { ch: 4, flags: { txaro: true } }, map: 'txaro', P: { x: 4, y: 6, dir: 'up' } },
  // la comarca (1.10): el pueblo del prólogo (caseríos, monte, parada y la vecina) y el puerto al atardecer con clientes
  { k: 'mendialde', sw: 320, mode: 'world', now: T + 444, S: { ch: 1, min: 8 * 60, flags: { llegada: false } }, map: 'mendialde', P: { x: 21, y: 19, dir: 'up' } },
  // orgánico (1.10): la pista y el puente de madera de Errotabarri, y el asfalto roto de Valdehierro (árboles corridos y en espejo)
  { k: 'errotabarri', sw: 400, mode: 'world', now: T + 777, S: { ch: 4, min: 10 * 60, flags: {} }, map: 'errotabarri', P: { x: 7, y: 13, dir: 'right' } },
  { k: 'valdehierro', sw: 240, mode: 'world', now: T + 999, S: { ch: 4, min: 12 * 60, flags: {} }, map: 'valdehierro', P: { x: 15, y: 11, dir: 'down' } },
  { k: 'puerto-tarde', sw: 400, mode: 'world', now: T + 3333, seed: 55, S: { ch: 4, min: 19 * 60, day: 8, flags: {} }, clientes: true, map: 'puerto',
    P: { x: 20, y: 10, dir: 'up' } },
  // las patrullas (1.10): de día, el cono amarillo del agente que mira a la izquierda y el catador de rosin con su gota; de noche,
  // sin cono (sigilo) y con la alarma: el agente corre a por el jugador con su «!»
  { k: 'patrulla-dia', sw: 320, mode: 'world', now: T, seed: 4242, S: { ch: 6, min: 12 * 60, day: 3, rep: 30, flags: { darko1: true },
    items: { fert: 0, insect: 0, spray: 0, bocata: 1, prensa: 1 } }, clientes: true, map: 'town', P: { x: 21, y: 19, dir: 'right' },
    ents: { pat0: { x: 24, y: 21, fx: 24, fy: 21, px: 24 * 16, py: 21 * 16, dir: 'left' } } },
  { k: 'patrulla-noche', sw: 240, mode: 'world', now: T + 544, seed: 4242, S: { ch: 6, min: 23 * 60, day: 3, rep: 30, flags: { darko1: true } }, map: 'town',
    P: { x: 19, y: 21, dir: 'left', moving: true, fx: 20, fy: 21, t: 60, dur: 240, parity: 1, px: (20 - 60 / 240) * 16, py: 21 * 16 },
    ents: { pat0: { x: 22, y: 21, fx: 23, fy: 21, px: (23 - 105 / 210) * 16, py: 21 * 16, dir: 'left', moving: true, t: 105, caza: true, dur: 210 } },
    SOSP: { v: 100, alarma: 'pat0' } },
  // la vista B: carpa de 150 con extras (goteo, filtro y ventilador), macetas de todo tipo, fases, plaga, seca y muerta; elegida
  // una plaza de atrás (la fila de delante en transparencia)
  { k: 'carpa-b-g150', sw: 240, mode: 'carpa', now: T + 1234, S: { ch: 5, flags: {} }, map: 'home', P: { x: 5, y: 4, dir: 'up' },
    carpas: [{ t: 'g150', foco: 'sodio600', goteo: true, filtro: true, vent: true }],
    macetas: ['plastico7', 'tela11', 'plastico18', 'tela25', 'plastico7', 'tela25'],
    pots: { 0: pl('malawi', 1), 1: pl('thai', .7, { pest: true, health: 50 }), 2: pl('kif', .05), 3: pl('ria', .5, { water: 0 }), 4: pl('nepal', .9, { dead: true }), 5: pl('lamb', .3) },
    VC: { ci: 0, sel: 4 }, vfx: [['vfx-gotas', 120, 100, 200, 'home', false]] },
  // armario 80 con LED (sin campana: vista B) y el foco elegido; ancho de 360
  { k: 'carpa-b-p80', sw: 360, mode: 'carpa', now: T + 99, S: { ch: 4, flags: {} }, map: 'home', P: { x: 5, y: 4, dir: 'up' },
    carpas: [{ t: 'p80', foco: 'led200' }], macetas: ['tela25', 'plastico7', 'plastico7'],
    pots: { 0: pl('acapulco', .66), 1: null, 2: pl('rif', 1, { f: { id: 4, t: 1, y: 1, i: 20 } }) }, VC: { ci: 0, sel: -1 } },
  // la vista C dentro del lienzo de 320 con un efecto encima
  { k: 'carpa-c', sw: 320, mode: 'carpa', now: T + 2500, S: { ch: 4, flags: {} }, map: 'home', P: { x: 5, y: 4, dir: 'up' },
    carpas: [{ t: 'm100', foco: 'sodio400' }], pots: { 0: pl('txoko', 1), 1: pl('limon', .8, { pest: true }), 2: pl('ria', .4) },
    VC: { ci: 0, sel: 1 }, vfx: [['vfx-brillo', 160, 90, 150, 'home', false]] },
  { k: 'combate-ladron', sw: 240, mode: 'battle', now: T, S: { ch: 3 },
    B: { kind: 'thief', name: 'CHORIZO', look: 'th0.25', t: 400, flashE: 100, shakeP: 200, aP: { n: 'spray', t0: T - 100 } },
    vfx: [['vfx-golpe', 178, 40, 80, '*', false]] },
  { k: 'combate-policia', sw: 400, mode: 'battle', now: T + 5000, S: { ch: 5 }, B: { kind: 'police', name: 'AGENTE', look: 'cop', t: 900, flashE: 0, shakeP: 0 } },
  { k: 'combate-huida', sw: 320, mode: 'battle', now: T + 60, S: { ch: 4 },
    B: { kind: 'thief', name: 'CHORIZO', look: 'th0.75', t: 5000, flashE: 0, shakeP: 0, gone: true, aE: { n: 'huir', t0: T + 60 - 200 } } },
  { k: 'titulo-240', sw: 240, mode: 'title', now: T },
  { k: 'titulo-400', sw: 400, mode: 'title', now: T + 1717 },
  { k: 'intro-320', sw: 320, mode: 'intro', now: T + 800 }];

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage({ viewport: { width: 1000, height: 700 } });
  const errores = [];
  page.on('pageerror', e => errores.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errores.push(m.text()); });
  await page.goto('file://' + (process.env.RV_HTML ? path.resolve(process.env.RV_HTML) : path.join(ROOT, 'index.html')));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
  await page.evaluate(() => arteListo());
  const r = await page.evaluate((PANTALLAS) => {
    try { localStorage.clear(); } catch (e) {}
    mode = 'pausa';   // que el bucle del juego no pinte encima
    for (const k of ['ambiente', 'music', 'sfx']) window[k] = () => {};
    const pm = seed => { let x = seed; return () => (x = x * 48271 % 2147483647) / 2147483647; };
    const rnd0 = Math.random, copia = o => JSON.parse(JSON.stringify(o));
    const o = { escenas: [], png: {} };
    for (const e of PANTALLAS) {
      Math.random = pm(e.seed || 1);
      S = newState();
      for (const k in e.S || {}) S[k] = k === 'flags' ? Object.assign(S.flags, e.S.flags) : copia(e.S[k]);
      if (e.carpas) {
        S.carpas = copia(e.carpas);const n = huecos().length;
        // una maceta por plaza, como al cargar la partida (15-arranque): las que falten, de 7 L
        S.macetas = Array.from({ length: n }, (_, i) => (e.macetas || [])[i] || 'plastico7');S.pots = Array(n).fill(null);
        for (const i in e.pots || {}) S.pots[i] = copia(e.pots[i]);
      }
      if (SW !== e.sw) { SW = e.sw; cv.width = SW; ctx.imageSmoothingEnabled = false; }
      ents = [];B = null;VC = null;ARTE.vfx = [];
      if (e.map) {
        S.clientsDay = S.day;
        enterMap(e.map, e.P.x, e.P.y, e.P.dir);
        if (e.clientes) spawnClients();
        Object.assign(P, { act: null, pisT: 0 }, copia(e.P));
        for (const id in e.ents || {}) {
          const x = ents.find(x => x.id === id);if (!x) throw new Error('sin personaje ' + id + ' en ' + e.k);
          const c = copia(e.ents[id]);
          if (c.moving && c.fx === null) {   // andando: viene de la casilla de al lado, según su dirección
            const d = DV[x.dir];Object.assign(x, { fx: x.x - d[0], fy: x.y - d[1] });delete c.fx;
            const k = Math.min(1, c.t / 320);x.px = (x.fx + (x.x - x.fx) * k) * 16;x.py = (x.fy + (x.y - x.fy) * k) * 16;
          }
          Object.assign(x, c);
        }
      }
      if (e.SOSP) Object.assign(SOSP, e.SOSP);   // la sospecha y la alarma de las patrullas (10b-patrulla)
      for (const [id, x, y, hace, capa, sube] of e.vfx || []) lanzarVfx(id, x, y, e.now - hace, capa, sube);
      if (e.B) { B = copia(e.B);B.look = /^th/.test(e.B.look) ? randLook(e.B.look, 'thief') : LOOKS[e.B.look]; }
      if (e.VC) VC = Object.assign({ ocupado: false }, e.VC);
      mode = e.mode;
      const st = copia({ k: e.k, sw: SW, mode, now: e.now, S, P, B, VC, vfx: ARTE.vfx,
        ents: ents.map(x => Object.assign({ id: x.id, x: x.x, y: x.y, px: x.px, py: x.py, dir: x.dir, moving: x.moving, t: x.t, fx: x.fx, fy: x.fy, act: x.act || null },
          x.pat ? { caza: x.caza, dur: x.dur } : {})), SOSP });
      render(e.now);
      o.png[e.k] = cv.toDataURL('image/png');
      o.escenas.push(st);
      mode = 'pausa';
    }
    Math.random = rnd0;
    return o;
  }, PANTALLAS);
  await browser.close();
  if (errores.length) { console.error('errores JS:', errores); process.exit(1); }
  fs.mkdirSync(SAL, { recursive: true });
  for (const [k, u] of Object.entries(r.png)) fs.writeFileSync(path.join(SAL, `html-p-${k}.png`), Buffer.from(u.split(',')[1], 'base64'));
  const dest = PAN ? path.join(SAL, 'pantallas.json') : path.join(ROOT, 'godot/tests/pantallas.json');
  fs.writeFileSync(dest, JSON.stringify(r.escenas));
  console.log(`${r.escenas.length} pantallas → ${path.relative(ROOT, dest)} y ${path.relative(ROOT, SAL)}/html-p-*.png`);
})();
