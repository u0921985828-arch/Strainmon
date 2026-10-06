#!/usr/bin/env node
/*
  Ribera Verde — prueba de la integración del arte (F2) sin gastar créditos
  1. Calca el arte procedural a art/crudo (tools/sprites/calco.js), lo procesa y monta un atlas.
  2. Compila el juego con ese atlas en tools/salida/arte/ (el index.html de la raíz no se toca).
  3. Comprueba en Chromium: atlas cargado, caminar y correr, ambiente de los fumadores con su humo,
     que al hablar se corta, que un menor nunca fuma, acciones del jugador, cogollos con el color de la
     variedad, planta seca, agua animada, orillas Wang, carpas, combate, título, ?arte=procedural y un atlas parcial (solo el player, sin «east»).
  Salida: lista OK/FALLO + tools/salida/arte/kiko-fuma.png (tira de fotogramas para revisarla a ojo).

  Requisitos: npm run sprites:ref (referencias)   Uso: node tools/test-arte.js
*/
const { chromium } = require('playwright');
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const ROOT = path.join(__dirname, '..');
const SAL = path.join(__dirname, 'salida');
const CAL = path.join(SAL, 'calco'), ART = path.join(SAL, 'arte'), PAR = path.join(SAL, 'arte-parcial');
const node = (...a) => execFileSync(process.execPath, a, { cwd: ROOT, stdio: ['ignore', 'pipe', 'pipe'] }).toString();

if (!fs.existsSync(path.join(ROOT, 'art', 'referencias', 'personajes'))) { console.error('Faltan las referencias: npm run sprites:ref'); process.exit(1); }
for (const d of [CAL, ART, PAR]) fs.rmSync(d, { recursive: true, force: true });
const calco = node('tools/sprites/calco.js', '--salida', path.join(CAL, 'crudo')).trim(); console.log(calco);
const N_CALCO = +(calco.match(/(\d+) PNG/) || [])[1];   // el atlas calcado tiene que traer todos los PNG que declara el manifiesto
const pr = node('tools/sprites/procesar.js', '--todos', '--crudo', path.join(CAL, 'crudo'), '--salida', path.join(CAL, 'procesado'), '--atlas-dir', path.join(CAL, 'atlas'), '--atlas');
console.log(pr.split('\n').filter(l => l.startsWith('ATLAS')).join('\n'));
node('tools/build.js', '--atlas-dir', path.join(CAL, 'atlas'), '--salida', ART);
// atlas parcial: solo el player y sin la dirección east (el motor tiene que usar el espejo de west)
node('tools/sprites/calco.js', '--salida', path.join(PAR, 'crudo'), '--solo', 'player');
for (const s of fs.readdirSync(path.join(PAR, 'crudo', 'player'))) fs.rmSync(path.join(PAR, 'crudo', 'player', s, 'east'), { recursive: true, force: true });
node('tools/sprites/procesar.js', 'player', '--crudo', path.join(PAR, 'crudo'), '--salida', path.join(PAR, 'procesado'), '--atlas-dir', path.join(PAR, 'atlas'), '--atlas');
node('tools/build.js', '--atlas-dir', path.join(PAR, 'atlas'), '--salida', PAR);

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const results = [];
  const check = (name, ok, detail) => { results.push(ok); console.log(`${ok ? 'OK   ' : 'FALLO'}  ${name}${ok || detail === undefined ? '' : '  → ' + JSON.stringify(detail)}`); };
  async function abrir(html, query = '') {
    const page = await browser.newPage({ viewport: { width: 1000, height: 700 } });
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    await page.goto('file://' + html + query);
    await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
    await page.evaluate(() => arteListo());
    await page.evaluate(() => {
      try { localStorage.clear(); } catch (e) {}
      S = newState(); S.ch = 3; mode = 'world'; enterMap('home', 5, 6, 'up');
      window.VFXLOG = []; const _l = lanzarVfx; window.lanzarVfx = function (...a) { VFXLOG.push(a[0]); return _l(...a); };
      window.AMB = []; ARTE.log = { push: v => AMB.push(v), shift() {}, length: 0 };
    });
    return { page, errors };
  }
  const html = path.join(ART, 'index.html');

  // ---------- con atlas ----------
  {
    const { page, errors } = await abrir(html);
    const r0 = await page.evaluate(() => ({ ok: ARTE.ok, n: Object.keys(ARTE.fr).length, esperado: Object.keys(ATLAS.def.frames).length }));
    check('Atlas cargado y recortado', r0.ok && r0.n === r0.esperado && r0.n === N_CALCO, { ...r0, calco: N_CALCO });
    const titulo = await page.evaluate(() => { const g = ARTE.cubre['misc:hoja-titulo'], m0 = mode; mode = 'title'; renderTitle(performance.now()); const d = ctx.getImageData(0, 0, 1, 1).data, f = frameDe(g, 'base', 'unica', 0, { i: 0 }), e = f.c.getContext('2d').getImageData(0, 0, 1, 1).data; mode = m0; return { g, igual: [0, 1, 2].every(i => d[i] === e[i]) }; });
    check('Título: el fondo sale del atlas', titulo.g === 'titulo' && titulo.igual, titulo);

    const walk = await page.evaluate(() => {
      const g = grupoLook(LOOKS.player), idx = new Set(), keys = ATLAS.def.anims[g].walk.dirs.south;
      for (const par of [0, 1]) for (const t of [0, 70, 130, 200]) { const e = { id: 'p', x: 0, y: 0, dir: 'down', moving: true, t, dur: 240, parity: par }; idx.add(pjFrame(e, g, 0, true, 240).i); }
      const run = pjFrame({ id: 'p', dir: 'down', moving: true, t: 10, dur: 130, parity: 0 }, g, 0, true, 130);
      return { idx: [...idx].sort(), walkN: keys.length, run: ATLAS.def.anims[g].run.dirs.south.some(k => ARTE.fr[k] === run.c) };
    });
    check('Caminar: los 4 fotogramas, un ciclo cada 2 casillas', walk.idx.join() === '0,1,2,3' && walk.walkN === 4, walk);
    check('Correr (B) usa la animación run', walk.run, walk);
    // idle solo donde se generó: de espaldas y sin idle norte, el NPC se queda con su base norte (no gira al idle sur)
    const quieto = await page.evaluate(() => { const g = 'unai', A = ATLAS.def.anims[g];
      const n = pjFrame({ id: 'unai', dir: 'up', moving: false }, g, 0, false, 240), s = pjFrame({ id: 'unai', dir: 'down', moving: false }, g, 0, false, 240);
      return { idleNorte: !!A.idle.dirs.north, norteBase: ARTE.fr[A.base.dirs.north[0]] === n.c, surIdle: A.idle.dirs.south.some(k => ARTE.fr[k] === s.c) }; });
    check('Idle solo en sus direcciones: sin idle norte, la base norte', !quieto.idleNorte && quieto.norteBase && quieto.surIdle, quieto);

    // Kiko en el growshop: fuma o pone semillas; el porro suelta su humo
    await page.evaluate(() => { ARTE.prisa = 0.0003; enterMap('shop', 4, 5, 'up'); });
    await page.waitForFunction(() => VFXLOG.includes('vfx-humo-porro'), null, { timeout: 20000 }).catch(() => {});
    const kiko = await page.evaluate(() => ({ amb: [...new Set(AMB)], vfx: [...new Set(VFXLOG)] }));
    check('Kiko: ambiente (fumar/semillas) y humo de porro como VFX aparte', kiko.amb.some(a => a === 'kiko:fumar') && kiko.vfx.includes('vfx-humo-porro'), kiko);

    // tira de fotogramas de Kiko fumando
    await page.evaluate(() => { const e = ents.find(e => e.id === 'kiko'); e.act = { n: 'fumar', t0: performance.now(), humo: { vfx: 'vfx-humo-porro', frame: 9, off: [4, -18] } }; ARTE.prisa = 1000; });
    const tira = [];
    for (let i = 0; i < 8; i++) {
      await page.waitForTimeout(190);
      tira.push(await page.evaluate(() => { const e = ents.find(e => e.id === 'kiko'), cam = camera(), c = ctx.canvas;
        const x = Math.round(e.px - cam.x) - 8, y = Math.round(e.py - cam.y) - 30; const [o, ox] = mkCanvas(32, 48); ox.drawImage(c, x, y, 32, 48, 0, 0, 32, 48); return o.toDataURL(); }));
    }
    const strip = new PNG({ width: 8 * 34 * 4, height: 48 * 4 });
    tira.forEach((d, i) => { const p = PNG.sync.read(Buffer.from(d.split(',')[1], 'base64'));
      for (let y = 0; y < strip.height; y++) for (let x = 0; x < 32 * 4; x++) { const s = ((y >> 2) * 32 + (x >> 2)) * 4, t = (y * strip.width + i * 34 * 4 + x) * 4; for (let k = 0; k < 4; k++) strip.data[t + k] = p.data[s + k]; } });
    fs.writeFileSync(path.join(ART, 'kiko-fuma.png'), PNG.sync.write(strip));

    // al hablarle se corta
    const corte = await page.evaluate(async () => { const e = ents.find(e => e.id === 'kiko'); e.act = { n: 'fumar', t0: performance.now() }; lock++; await new Promise(r => setTimeout(r, 80)); const sin = e.act === null; lock--; return sin; });
    check('Al hablar con un NPC se corta su acción de ambiente', corte);

    // bar: Baltasar con puro y Toño con cigarro
    await page.evaluate(() => { VFXLOG.length = 0; AMB.length = 0; ARTE.prisa = 0.0003; enterMap('bar', 5, 6, 'up'); });
    await page.waitForFunction(() => VFXLOG.includes('vfx-humo-puro') && VFXLOG.includes('vfx-humo-cigarro'), null, { timeout: 25000 }).catch(() => {});
    const bar = await page.evaluate(() => ({ amb: [...new Set(AMB)], vfx: [...new Set(VFXLOG)] }));
    check('Bar: Baltasar fuma puro y Toño cigarro', bar.vfx.includes('vfx-humo-puro') && bar.vfx.includes('vfx-humo-cigarro'), bar);

    // plaza: Darko vapea; Unai (menor) nunca fuma aunque el atlas traiga una animación de fumar
    await page.evaluate(() => {
      VFXLOG.length = 0; AMB.length = 0; S.ch = 5; S.protect = false;
      const A = ATLAS.def; A.anims.unai.fumar = A.anims.unai.pelota; A.ambiente.unai.acciones.push('fumar'); A.fumador.unai = { tipo: 'cigarro', vfx: 'vfx-humo-cigarro', frame_humo: 1, offset_boca: [0, -18] };
      ents.forEach(e => e.wander = 0); enterMap('town', 19, 17, 'up'); ents.forEach(e => e.wander = 0); ARTE.prisa = 0.0003;
    });
    await page.waitForFunction(() => VFXLOG.includes('vfx-nube-vaper') && AMB.filter(a => a.startsWith('unai:')).length >= 6, null, { timeout: 30000 }).catch(() => {});
    const town = await page.evaluate(() => ({ unai: AMB.filter(a => a.startsWith('unai:')), vfx: [...new Set(VFXLOG)], otros: [...new Set(AMB.filter(a => !a.startsWith('unai:')))] }));
    check('Darko vapea (nube de vaper)', town.vfx.includes('vfx-nube-vaper'), town);
    check('Unai (menor) nunca fuma, ni con una animación de fumar inyectada', town.unai.length >= 6 && town.unai.every(a => a === 'unai:pelota'), town.unai);

    // acciones del jugador
    const acc = await page.evaluate(async () => { VFXLOG.length = 0; enterMap('home', 5, 6, 'up'); const t = performance.now(); await accion('regar', { id: 'vfx-gotas', x: 80, y: 80 }); return { ms: Math.round(performance.now() - t), libre: P.act === null, vfx: VFXLOG.slice() }; });
    check('Regar: animación de 1 s y gotas', acc.ms >= 950 && acc.ms < 1600 && acc.libre && acc.vfx.includes('vfx-gotas'), acc);

    // carpas (1.8): muebles del piso a 16 px/m y, con A delante, la vista de carpa a 64 px/m con arte del atlas
    const carpa = await page.evaluate(async () => {
      const espera = ms => new Promise(r => setTimeout(r, ms)), hasta = f => new Promise(r => { const i = setInterval(() => { if (f()) { clearInterval(i); r(); } }, 20); });
      S.carpas = [{ t: 'p60', foco: 'cfl' }, { t: 'g150', foco: 'led720' }]; S.macetas = ['plastico7', 'tela11', 'plastico18', 'tela25', 'tela11', 'tela11', 'tela11', 'tela11'];
      S.pots = Array(8).fill(null); S.pots[0] = { sid: 'purpura', prog: 1, water: 80, health: 100 }; S.pots[1] = { sid: 'mango', prog: .5, water: 0, health: 80, pest: true };
      S.pots[2] = { sid: 'ria', prog: .5, water: 80, health: 100 }; S.pots[3] = { sid: 'ria', prog: .5, water: 80, health: 100, dead: true };
      const m = MAPS.home, r = {}; enterMap('home', 5, 5, 'up'); const [A, B] = m.carpas;
      r.mapa = ['p60', 'm100', 'g150'].every(t => arteCarpaMapa(t, 50, 50)); r.anchos = [A.x1 - A.x0 + 1, B.x1 - B.x0 + 1].join();
      r.solidas = tileSolid(m, A.x0, A.y) && tileSolid(m, B.x0, B.y) && tileSolid(m, B.x1, B.y) && !tileSolid(m, A.x0, A.y + 1);
      r.piso = [m.w, m.h].join('×');
      // las 23 variedades × 5 fases tienen planta; los híbridos propios, una por hash
      const g = ARTE.cubre['misc:planta-vista'];
      r.plantas = DEX.every(k => [1, 2, 3, 4, 5].every(f => !!frameDe(g, 'sm' + smDe(k) + '-' + f, 'unica', 0, { i: 0 }))) && !!frameDe(g, 'sm' + smDe('xq9') + '-3', 'unica', 0, { i: 0 });
      const alto = (sid, prog) => { ctx.save(); const h = artePlantaVista({ sid, prog, water: 80, health: 100 }, 60, 100, 0); ctx.restore(); return h; };
      r.alturas = [.05, .2, .5, .8, 1].map(p => alto('malawi', p)); r.crece = r.alturas.every((h, i) => h > 0 && (!i || h >= r.alturas[i - 1])) && r.alturas[4] <= 56;
      const f = frameDe(g, 'sm08-3', 'unica', 0, { i: 0 }), colores = c => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data, o = new Set(); for (let i = 0; i < d.length; i += 4) if (d[i + 3]) o.add(d[i] + ',' + d[i + 1] + ',' + d[i + 2]); return o; };
      const verdes = c => [...colores(c)].filter(k => { const [R, G, B] = k.split(',').map(Number); return G > R + 12 && G > B + 12; }).length;
      r.seca = verdes(f.c) > 3 && verdes(secar(f.c, 0)) === 0 && verdes(secar(f.c, 1)) === 0;
      // la escena: A delante del armario, ▶ plaza 2, ▲ el foco, B sale
      enterMap('home', A.x0, A.y + 1, 'up'); press('A'); await hasta(() => mode === 'carpa' && handlers.length === 1); await espera(150);
      r.escena = arteFondoCuarto() && arteCarpaVista('p60', 120, 149) && Object.keys(MACETAS).every(k => arteMacetaVista(k, 50, 100) !== null) && ['cfl', 'sodio', 'led'].every(t => arteFoco(t, 50, 40, 20));
      r.sel = [VC.sel]; press('right'); r.sel.push(VC.sel); press('up'); r.sel.push(VC.sel); r.info = document.getElementById('vcInfo').textContent;
      press('B'); await hasta(() => mode === 'world' && isFree()); r.sale = !VC && document.getElementById('vcInfo').hidden;
      return r; });
    check('Carpas: muebles del piso (1-2 casillas, sólidos) con su arte, piso de 12×8', carpa.mapa && carpa.anchos === '1,2' && carpa.solidas && carpa.piso === '12×8', carpa);
    check('Plantas de la vista: 23 variedades × 5 fases, alturas que crecen hasta 56 px, seca y muerta sin verdes', carpa.plantas && carpa.crece && carpa.seca, carpa);
    check('Vista de carpa: A abre, ▶ plaza 2, ▲ el foco, B sale; fondo, carpa, macetas y focos del atlas', carpa.escena && carpa.sel.join() === '0,1,-1' && /CFL/.test(carpa.info) && carpa.sale, carpa);
    const orilla = await page.evaluate(() => { const m = MAPS.town, r = { quince: 0, pintadas: 0 };
      for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) if (TRANS[m.g[y][x]]) { const k = mascaraOrilla(m, x, y); if (k === 15) r.quince++; if (arteOrilla(m, m.g[y][x], x, y, 0, 0)) r.pintadas++; }
      r.rio = mascaraOrilla(m, 31, 15); r.centro = mascaraOrilla(m, 35, 27); r.sinAtlas = (() => { const ok = ARTE.ok; ARTE.ok = false; const v = arteOrilla(m, 'water', 31, 15, 0, 0); ARTE.ok = ok; return v; })(); return r; });
    check('Orillas Wang: agua, tierra y plaza con la máscara de esquinas', orilla.rio === 5 && orilla.centro === 0 && orilla.pintadas > 40 && orilla.quince === 0 && !orilla.sinAtlas, orilla);
    const agua = await page.evaluate(() => { const [g, s] = ARTE.sobre['tile:water'][0]; return frameDe(g, s, 'unica', 0, { bucle: true }).c !== frameDe(g, s, 'unica', 300, { bucle: true }).c; });
    check('Agua animada por reloj (bloque de 2×2 casillas)', agua);

    // combate
    const comb = await page.evaluate(async () => {
      B = { kind: 'thief', name: 'X', look: randLook('t1', 'thief'), t: 999, flashE: 0, shakeP: 0, hp: 9, hpMax: 9 }; mode = 'battle';
      const g = bAnim('P', 'golpe') > 0, e = bAnim('E', 'ataque') > 0, f = combFrame('P', performance.now() + 50);
      const golpe = ATLAS.def.anims[grupoCombate('P')].golpe.dirs.north.some(k => ARTE.fr[k] === f.c);
      B.gone = true; bAnim('E', 'huir'); await new Promise(r => setTimeout(r, 200));
      B = { kind: 'police', name: 'Y', look: LOOKS.cop, t: 999, flashE: 0, shakeP: 0 }; const pol = grupoCombate('E'), alto = bAnim('E', 'alto') > 0;
      await new Promise(r => setTimeout(r, 200)); B = null; mode = 'world';
      return { g, e, golpe, pol, alto };
    });
    check('Combate: golpe, ataque, huida y policía desde el atlas', comb.g && comb.e && comb.golpe && comb.pol === 'policia-combate' && comb.alto, comb);
    // intro y menús: nada de sprites procedurales si el atlas los trae (Kiko de la intro, iconos y cogollos de la Genoteca)
    const ui = await page.evaluate(async () => {
      const r = {}; mode = 'intro'; r.kiko = arteRetrato(LOOKS.kiko, 120, 104, performance.now()); mode = 'world';
      r.iconos = ['abono', 'insecticida', 'spray', 'bocadillo', 'semillas', 'billetes', 'maceta', 'lampara'].every(n => !!icono(n));
      r.cogollos = ['ria', 'leyenda', 'txoko', 'limon'].every(k => !!iconoCogollo(k)) && iconoCogollo('ria') !== iconoCogollo('txoko');
      S.items.fert = 2; addBuds('ria', 5, 12); mochila(); await new Promise(res => setTimeout(res, 60));
      r.mochila = document.querySelectorAll('#menu .ic').length; while (handlers.length) handlers.pop(); document.getElementById('menu').hidden = true; return r; });
    check('Intro y menús con el arte del atlas: Kiko, iconos y cogollos de la Genoteca', ui.kiko && ui.iconos && ui.cogollos && ui.mochila >= 4, ui);
    // pantalla completa en horizontal (1.7): solo el reborde, píxeles cuadrados, mandos flotando dentro del viewport sin tapar el
    // escenario de diálogos y menús en ningún tamaño horizontal, sin scroll; en vertical, el aviso de «Gira el móvil»
    const marco = [];
    for (const [w, h] of [[568, 320], [640, 360], [740, 360], [844, 390], [915, 412], [1024, 768], [1366, 768], [360, 740], [412, 915]]) {
      await page.setViewportSize({ width: w, height: h }); await page.waitForTimeout(80);
      marco.push(await page.evaluate(([w, h]) => { ajustarPantalla(); const R = q => document.querySelector(q).getBoundingClientRect();
        const s = R('#screen'), u = R('#ui'), d = R('#dpad'), a = R('.ab'), pi = R('.pills'), st = R('[data-b=START]'), so = R('#bSound'), gi = document.getElementById('girar');
        const dentro = b => b.left >= 0 && b.top >= 0 && b.right <= w + .5 && b.bottom <= h + .5, cruza = (p, q) => p.left < q.right && q.left < p.right && p.top < q.bottom && q.top < p.bottom;
        const sinScroll = document.documentElement.scrollHeight <= h && document.documentElement.scrollWidth <= w;
        if (h > w) return { w, h, ok: !gi.hidden && R('#girar').width >= w - 1 && sinScroll, girar: !gi.hidden };
        const frac = s.width * s.height / (w * h), ancho = w / h >= 1.6, cuadrado = Math.abs(cv.width / 160 - s.width / s.height) < .02;
        const libre = ![d, a, pi].some(b => cruza(b, u));
        return { w, h, ok: gi.hidden && [s, d, a, st, so].every(dentro) && sinScroll && cuadrado && libre && !cruza(d, a) && frac >= (ancho ? .9 : .8) && d.width >= 96,
          SW, us: +(u.width / 240).toFixed(2), pantalla: Math.round(s.width) + '×' + Math.round(s.height), frac: +frac.toFixed(2), cuadrado, libre, cruceta: Math.round(d.width) }; }, [w, h]));
    }
    await page.setViewportSize({ width: 1000, height: 700 });
    check('Pantalla completa en horizontal: reborde, píxeles cuadrados y mandos flotando en 7 tamaños; en vertical, «Gira el móvil»', marco.every(m => m.ok), marco.filter(m => !m.ok).concat(marco.length ? [] : ['sin datos']));
    await page.waitForTimeout(300);
    check('Con atlas: 0 errores de JavaScript', errors.length === 0, errors.slice(0, 5));
    await page.close();
  }
  // ---------- ?arte=procedural ----------
  {
    const { page, errors } = await abrir(html, '?arte=procedural');
    const ok = await page.evaluate(() => ARTE.ok === false && typeof ATLAS === 'object' && ATLAS !== null);
    await page.waitForTimeout(300);
    check('?arte=procedural ignora el atlas', ok && errors.length === 0, errors);
    await page.close();
  }
  // ---------- atlas parcial ----------
  {
    const { page, errors } = await abrir(path.join(PAR, 'index.html'));
    const r = await page.evaluate(async () => {
      const res = { ok: ARTE.ok, player: grupoLook(LOOKS.player), kiko: grupoLook(LOOKS.kiko), espejo: clavesDe('player', 'base', 'east')[1] };
      P.dir = 'right'; enterMap('town', 19, 17, 'right'); await new Promise(r => setTimeout(r, 400)); enterMap('shop', 4, 5, 'up'); await new Promise(r => setTimeout(r, 300));
      return res;
    });
    check('Atlas parcial: player del atlas (este = espejo de oeste), el resto procedural, 0 errores', r.ok && r.player === 'player' && r.kiko === null && r.espejo === true && errors.length === 0, { r, errors });
    await page.close();
  }
  await browser.close();
  const ok = results.filter(Boolean).length;
  console.log(`\n${ok}/${results.length} comprobaciones OK · tira de Kiko: tools/salida/arte/kiko-fuma.png`);
  process.exit(ok === results.length ? 0 : 1);
})();
