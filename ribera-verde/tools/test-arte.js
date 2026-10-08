#!/usr/bin/env node
/*
  Ribera Verde — prueba de la integración del arte (F2) sin gastar créditos
  1. Calca el arte procedural a art/crudo (tools/sprites/calco.js), lo procesa y monta un atlas.
  2. Compila el juego con ese atlas en tools/salida/arte/ (el index.html de la raíz no se toca).
  3. Comprueba en Chromium: atlas cargado, caminar y correr, ambiente de los fumadores con su humo,
     que al hablar se corta, que un menor nunca fuma, acciones del jugador, cogollos con el color de la
     variedad, planta seca, agua animada, orillas Wang, carpas (vistas B y C), combate, título, ?arte=procedural y un atlas parcial (solo el player, sin «east»).
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

    // carpas: muebles del piso a 16 px/m y, con A delante, la vista B a 60 px/m (con atlas, la carpa plateada de frente; lo demás, procedural hasta las láminas de P3-P4)
    const carpa = await page.evaluate(async () => {
      const espera = ms => new Promise(r => setTimeout(r, ms)), hasta = f => new Promise(r => { const i = setInterval(() => { if (f()) { clearInterval(i); r(); } }, 20); });
      S.carpas = [{ t: 'p60', foco: 'cfl' }, { t: 'g150', foco: 'led720' }]; S.macetas = ['plastico7', 'tela11', 'plastico18', 'tela25', 'tela11', 'tela11', 'tela11', 'tela11'];
      S.pots = Array(8).fill(null); S.pots[0] = { sid: 'purpura', prog: 1, water: 80, health: 100 }; S.pots[1] = { sid: 'mango', prog: .5, water: 0, health: 80, pest: true };
      S.pots[2] = { sid: 'ria', prog: .5, water: 80, health: 100 }; S.pots[3] = { sid: 'ria', prog: .5, water: 80, health: 100, dead: true };
      const m = MAPS.home, r = {}; enterMap('home', 5, 5, 'up'); const [A, B] = m.carpas;
      r.mapa = ['p60', 'm100', 'g150'].every(t => arteCarpaMapa(t, 50, 50)); r.anchos = [A.x1 - A.x0 + 1, B.x1 - B.x0 + 1].join();
      r.solidas = tileSolid(m, A.x0, A.y) && tileSolid(m, B.x0, B.y) && tileSolid(m, B.x1, B.y) && !tileSolid(m, A.x0, A.y + 1);
      r.piso = [m.w, m.h].join('×');
      // todas las variedades tienen su % índica y su tono de hoja (los híbridos propios, de sus padres; los de partidas viejas, por sus
      // días de floración), que dan el porte; de vegetativo a lista, alto y ancho reales (PLANTA_CM a VB_M) entre ×0,75 y ×1,33; la que crece no encoge
      r.n = DEX.length; r.portes = DEX.every(k => Number.isInteger(STRAINS[k].ind) && STRAINS[k].ind >= 0 && STRAINS[k].ind <= 100 && /^#[0-9a-f]{6}$/.test(STRAINS[k].hj))
        && porteDe('xq9') === 'h' && [porteInd(70), porteInd(69), porteInd(30), porteInd(29)].join() === 'i,h,h,s' && porteDe('rif') === 'i' && porteDe('thai') === 's';
      const caja = c => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; let x0 = 1e9, x1 = -1, y0 = 1e9;
        for (let i = 0; i < d.length; i += 4) if (d[i + 3]) { const x = (i / 4) % c.width; x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, Math.floor(i / 4 / c.width)); }
        return [x1 - x0 + 1, c.height - y0]; };
      r.razones = []; for (const po of ['i', 's', 'h']) for (const st of [2, 3, 4]) { const [w, h] = caja(planta34(po, st, false, '#e0c050')), D = PLANTA_CM[po]; r.razones.push(+(w / D.w[st] / VB_M).toFixed(2), +(h / D.h[st] / VB_M).toFixed(2)); }
      r.alturas = [.05, .2, .5, .8, 1].map(prog => altoPlanta({ sid: 'malawi', prog })); r.crece = r.alturas.every((h, i) => h > 0 && (!i || h >= r.alturas[i - 1])) && r.razones.every(k => k >= .75 && k <= 1.33);
      const colores = c => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data, o = new Set(); for (let i = 0; i < d.length; i += 4) if (d[i + 3]) o.add(d[i] + ',' + d[i + 1] + ',' + d[i + 2]); return o; };
      const verdes = c => [...colores(c)].filter(k => { const [R, G, B] = k.split(',').map(Number); return G > R + 12 && G > B + 12; }).length;
      r.seca = verdes(planta34('h', 3, false, '#e0c050')) >= 3 && verdes(planta34('h', 3, true, '#e0c050')) === 0 && verdes(planta34('h', 9, false, '#e0c050')) === 0;
      // distancia segura (cm): en cada carpa, con cada foco y maceta que admite, las copas en floración (índica lista, la más
      // ancha) no se tocan entre sí ni con las paredes, las macetas caben y la cima (sativa lista, la más alta) queda a FOCO_SEP del foco
      const C0 = S.carpas, M0 = S.macetas; r.espacio = [];
      for (const t in CARPAS) { const C = CARPAS[t], [W, H, D] = C.cm; let peor = 1e9;
        for (const f in FOCOS) if (FOCOS[f].w <= C.wmax) for (const k in MACETAS) if (MACETAS[k].l <= C.lmax) {
          S.carpas = [{ t, foco: f }]; S.macetas = Array(C.plazas).fill(k); const pl = vcGeo(0).pl, md = MACETA_CM[k][0];
          const an = q => caja(planta34('i', 4, false, '#e0c050', q.cw, q.ch))[0] / VB_M, al = q => caja(planta34('s', 4, false, '#e0c050', q.cw, q.ch))[1] / VB_M;
          pl.forEach((a, i) => { const ra = Math.max(an(a), md) / 2; peor = Math.min(peor, a.cx - ra, W - a.cx - ra, a.cy - ra, D - a.cy - ra, H - 28 - FOCO_SEP[f] - MACETA_CM[k][1] - al(a));
            pl.forEach((b, j) => { if (j > i) peor = Math.min(peor, Math.hypot(a.cx - b.cx, a.cy - b.cy) - Math.max((an(a) + an(b)) / 2, md)); }); }); }
        r.espacio.push(t + ' ' + Math.round(peor)); }
      // tierra (1.10): de frente, cada maceta que admite la carpa queda entre las columnas del suelo de la plateada, a su fondo; y el tope de litros de la carpa: en la de 120 con 5 de 25 L y una de 7, solo cabe la de 18 L
      r.dentro = [];
      for (const t in CARPAS) { const C = CARPAS[t], k = VB_PLATA[t]; let peor = 1e9;
        for (const m in MACETAS) if (MACETAS[m].l <= C.lmax) { S.carpas = [{ t, foco: 'led200' }]; S.macetas = Array(C.plazas).fill(m); const g = vcGeo(0, true), w = macetaPx(m).w;
          if (!g.plata) { peor = -1e9; continue; }
          for (const q of g.pl) { const f = (155 - q.y) / 17, xl = 120 + k.xf[0] + (k.xb[0] - k.xf[0]) * f, xr = 120 + k.xf[1] + (k.xb[1] - k.xf[1]) * f;
            peor = Math.min(peor, q.x - (w >> 1) - xl, xr - (q.x - (w >> 1) + w - 1)); } }
        r.dentro.push(t + ' ' + Math.floor(peor)); }
      S.carpas = [{ t: 'm120', foco: 'led480' }]; S.macetas = ['tela25', 'tela25', 'tela25', 'tela25', 'tela25', 'plastico7']; const I0 = S.items;
      S.items = Object.assign({}, I0, { m_tela25: 1, m_plastico18: 1, m_tela11: 0, m_plastico7: 0 });
      r.tierra = [litrosMax(0), litrosCarpa(0), macetasLibres(5).join(), macetasLibres(5, false).join(), Object.keys(CARPAS).every(t => { S.carpas = [{ t, foco: 'cfl' }]; return CARPAS[t].plazas * 7 <= litrosMax(0); })];
      S.items = I0; S.carpas = C0; S.macetas = M0;
      // la escena: A delante del armario, ▶ plaza 2, ▲ el foco, B sale
      enterMap('home', A.x0, A.y + 1, 'up'); press('A'); await hasta(() => mode === 'carpa' && handlers.length === 1); await espera(150);
      const hay = c => c && c.width > 0 && colores(c).size > 2;
      r.escena = hay(cuarto34()) && Object.keys(CARPAS).every(t => hay(carpa34(t))) && Object.keys(MACETAS).every(k => hay(maceta34(k))) && Object.keys(FOCOS).every(k => hay(foco34(k))) && Object.keys(EXTRAS).every(k => hay(extra34(k)));
      r.sel = [VC.sel]; press('right'); r.sel.push(VC.sel); press('up'); r.sel.push(VC.sel); r.info = document.getElementById('vcInfo').textContent;
      press('B'); await hasta(() => mode === 'world' && isFree()); r.sale = !VC && document.getElementById('vcInfo').hidden;
      return r; });
    check('Carpas: muebles del piso (1-2 casillas, sólidos) con su arte, piso de 12×8', carpa.mapa && carpa.anchos === '1,2' && carpa.solidas && carpa.piso === '12×8', carpa);
    check(`Plantas de la vista B: ${carpa.n} variedades con % índica, tono de hoja y porte, alto y ancho reales (×0,75-1,33) de vegetativo a lista, seca y muerta sin verdes`, carpa.portes && carpa.crece && carpa.seca, carpa);
    check('Vista B, distancia segura: en las 5 carpas, con cada foco y maceta, ni las copas en floración ni las macetas se tocan ni tocan las paredes, y la cima queda a su distancia del foco', carpa.espacio.length === 5 && carpa.espacio.every(e => +e.split(' ')[1] >= 0), carpa.espacio);
    check('Vista B de frente: las macetas, dentro del suelo de la carpa plateada en las 5 carpas; tope de tierra por carpa (120: 144 L, con 5 de 25 L y una de 7 solo entra la de 18 L)', carpa.dentro.length === 5 && carpa.dentro.every(e => +e.split(' ')[1] >= 0) && carpa.tierra.join('|') === '144|132|plastico18|plastico18,tela25|true', { dentro: carpa.dentro, tierra: carpa.tierra });
    check('Vista de carpa B: A abre, ▶ plaza 2, ▲ el foco, B sale; cuarto, carpas, macetas, focos y extras', carpa.escena && carpa.sel.join() === '0,1,-1' && /CFL/.test(carpa.info) && carpa.sale, carpa);
    // vista C (P3, imagen A): la pared solo lleva la tela y la luz va en su propio sprite, por delante; macetas y plantas a la escala
    // de la carpa; la planta A del porte de cada planta (su % índica), del ancho que deja aire con sus vecinas de fila y las paredes, de
    // su alto real sin pasar de su distancia al foco (ch) y con el tono de hoja de su variedad; sin arte para algo de la carpa, la vista B
    const vc = await page.evaluate(() => {
      const r = { escenas: [], fallos: [], exactas: 0, aplastadas: 0, anchos: new Set(), portes: new Set() }, C0 = S.carpas, M0 = S.macetas, P0 = S.pots;
      const calidos = c => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; let n = 0; for (let i = 0; i < d.length; i += 4) if (d[i + 3] && d[i] > d[i + 2] + 40) n++; return n; };
      // la pared no sigue a la luz: correlación de luminancias pared ↔ luz donde hay luz (la pared de la 1.ª versión, con la forma del cono: 0,8)
      const sigue = (p, l) => { const P = p.getContext('2d').getImageData(0, 0, 240, 160).data, L = l.getContext('2d').getImageData(0, 0, 240, 160).data, a = [], b = [], Y = (d, i) => .299 * d[i] + .587 * d[i + 1] + .114 * d[i + 2];
        for (let y = 18; y < 138; y++) for (let x = 46; x < 194; x++) { const i = (y * 240 + x) * 4; if (L[i + 3] && P[i + 3]) { a.push(Y(P, i)); b.push(Y(L, i)); } }
        const m = v => v.reduce((s, x) => s + x, 0) / v.length, ma = m(a), mb = m(b); let c = 0, va = 0, vb = 0;
        a.forEach((x, k) => { c += (x - ma) * (b[k] - mb); va += (x - ma) ** 2; vb += (b[k] - mb) ** 2; }); return +(c / Math.sqrt(va * vb)).toFixed(2); };
      // brillos cálidos (no la tierra, más oscura): la luz del foco pintada en el sprite
      // los pistilos de la planta A (#f08a3c, #b45a28) son naranjas de suyo: no cuentan como luz pintada
      const PISTILOS = new Set(['240,138,60', '180,90,40']), conLuz = c => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; let n = 0;
        for (let i = 0; i < d.length; i += 4) { if (!d[i + 3]) continue; const [r, g, b] = [d[i], d[i + 1], d[i + 2]], M = Math.max(r, g, b), m = Math.min(r, g, b); if (M < 46 || M - m < .25 * M || PISTILOS.has(r + ',' + g + ',' + b)) continue;
          const h = M === r ? 60 * (((g - b) / (M - m)) % 6) : M === g ? 60 * ((b - r) / (M - m) + 2) : 60 * ((r - g) / (M - m) + 4); if ((h + 360) % 360 < 88 || (h + 360) % 360 > 340) n++; } return n; };
      const caja = c => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; let x0 = 1e9, x1 = -1; for (let i = 0; i < d.length; i += 4) if (d[i + 3]) { const x = (i / 4) % c.width; x0 = Math.min(x0, x); x1 = Math.max(x1, x); } return [x0, x1]; },
        ancho = c => { const [x0, x1] = caja(c); return x1 - x0 + 1; };
      const colores = c => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data, o = new Set(); for (let i = 0; i < d.length; i += 4) if (d[i + 3]) o.add('#' + [d[i], d[i + 1], d[i + 2]].map(v => v.toString(16).padStart(2, '0')).join('')); return o; };
      // ss: sid o [sid, % índica de la planta]
      const pon = (t, foco, ss, prog = 1, extra = {}) => { S.carpas = [{ t, foco, ...extra }]; S.macetas = Array(CARPAS[t].plazas).fill('plastico7');
        S.pots = ss.map((s, i) => s && { sid: [].concat(s)[0], prog: Array.isArray(prog) ? prog[i] : prog, water: 80, health: 100, f: Array.isArray(s) ? { id: 1, t: 1, y: 1, i: s[1] } : undefined }); return vcGeo(0); };
      // aplastada sin escalar: mide justo su alto, la base del tallo (2 filas) no cambia y sus filas son filas enteras del fotograma, en
      // orden; pierde lo mínimo (las filas con menos píxeles de debajo de la cola, el 40 % de arriba). Escalando se pierden filas sueltas al azar
      const aplastaBien = (a, b, h) => { const W = a.width, H = a.height, A = a.getContext('2d').getImageData(0, 0, W, H).data, B = b.getContext('2d').getImageData(0, 0, W, H).data,
          fila = (D, y) => D.slice(y * W * 4, (y + 1) * W * 4).join(), cuenta = (D, y) => { let k = 0; for (let x = 0; x < W; x++) if (D[(y * W + x) * 4 + 3]) k++; return k; }, alto = vcAlto(a), y0 = H - alto;
        let perdidos = 0; for (let y = 0; y < H; y++) perdidos += cuenta(A, y) - cuenta(B, y);
        let jb = H - h; for (let y = y0; y < H && jb < H; y++) if (fila(A, y) === fila(B, jb)) jb++;
        const enteras = jb === H, base = fila(A, H - 1) === fila(B, H - 1) && fila(A, H - 2) === fila(B, H - 2), mide = vcAlto(b) === h, cola = y0 + Math.round(alto * .4), abajo = [], arriba = [];
        for (let y = y0; y < H - 2; y++) (y < cola ? arriba : abajo).push(cuenta(A, y));
        const minimo = [...abajo.sort((x, y) => x - y), ...arriba.sort((x, y) => x - y)].slice(0, alto - h).reduce((x, y) => x + y, 0);
        return { enteras, base, mide, perdidos, minimo, ok: enteras && base && mide && perdidos <= minimo }; };
      const fotos = n => { const g = ARTE.cubre['misc:' + n], k = frameDe(g, n, 'unica', 0, { i: 0 }).n; return [...Array(k)].map((_, i) => frameDe(g, n, 'unica', 0, { i }).c); },
        clave = new Set(((ARTE.d.rampas || {})['carpa-c-plantas-a'] || { cogollo: { rampa: [] } }).cogollo.rampa.map(h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16)).join())),
        cogollo = c => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; let n = 0; for (let i = 0; i < d.length; i += 4) if (d[i + 3] && clave.has(d[i] + ',' + d[i + 1] + ',' + d[i + 2])) n++; return n; };
      const repetidas = c => { const W = c.width, d = c.getContext('2d').getImageData(0, 0, W, c.height).data, f = y => d.slice(y * W * 4, (y + 1) * W * 4).join(); let n = 0;
        for (let y = 1; y < c.height; y++) { let k = 0; for (let x = 0; x < W; x++) if (d[(y * W + x) * 4 + 3]) k++; if (k > 4 && f(y) === f(y - 1)) n++; } return n; };
      // la Skunk #1 (ria, 65 %) es la paleta A tal cual; la Afghani (100 %), la Haze (10 %) y la Blue Dream (40 %), con su tono
      const ESC = [['p60', 'cfl', ['rif', 'haze'], 1], ['p60', 'sodio250', ['ria', 'nieblamor'], [.7, .5]], ['p60', 'cfl', ['ria', 'thai'], [.05, .2]],
        ['p80', 'sodio400', ['nl', 'tormenta', 'ria'], [1, 1, .5]], ['p80', 'cfl', ['purpurah', 'malawi', 'citrus'], [.5, .8, 1]],
        ['m100', 'sodio400', ['purpurah', 'thai', 'txoko', 'malawi'], [1, .7, .4, .2]], ['m100', 'sodio600', ['haze', 'nieblamor', 'rif', 'ssh'], .8],
        ['m120', 'sodio600', ['mango', 'purpura', 'txoko', 'niebla', 'rif', 'afkush'], .8], ['m120', 'sodio400', ['haze', 'ria', 'afkush', 'thai', 'nieblamor', 'kif'], [1, 1, 1, .5, .5, .5]],
        ['g150', 'sodio600', ['afkush', 'ssh', 'kif', 'nieblamor', 'acapulco', 'rif'], [1, 1, 1, .7, .5, .05]], ['p60', 'sodio250', [['haze', 90], ['rif', 10]], 1]];
      for (const [t, f, ss, prog] of ESC) {
        const g = pon(t, f, ss, prog), n = t + '/' + f; if (!g.vc) { r.fallos.push(n + ' sin vista C'); continue; }
        const { Z } = g.vc, boca = VCA.boca, e = { t, pared: calidos(vcFondo(t, g.vc, 'pared')), luz: calidos(vcFondo(t, g.vc, 'luz')), foco: ancho(g.vc.foco.f.c), focoReal: Math.round(FOCO_CM[f] * Z),
          sigue: sigue(vcFondo(t, g.vc, 'pared'), vcFondo(t, g.vc, 'luz')), objetos: g.pl.reduce((n, q) => n + conLuz(q.v.m.f.c) + (q.v.p ? conLuz(q.v.p.f.c) : 0), 0),
          luzTipo: f === 'cfl' ? calidos(vcLuz(t, g.vc)) : 0 };   // la luz del CFL, fría: ni un píxel cálido
        // lo dibujado, no lo calculado: de cada planta, dónde caen sus píxeles en pantalla (x0, x1), su alto y su cima
        const dib = {};
        for (const q of g.pl) { const v = q.v, p = S.pots[q.i], st = p && plantStage(p);
          if (!p) continue; const po = portePlanta(p), nom = 'planta-c-' + (st < 2 ? 'h' : po) + (st >= 3 ? '' : st) + '-'; r.portes.add(po + st);
          // el porte de la planta: el de su % índica (p.f.i; sin él, el de su variedad): índica desde 70, sativa por debajo de 30
          const ip = p.f && p.f.i != null ? p.f.i : STRAINS[p.sid].ind, pe = ip >= 70 ? 'i' : ip < 30 ? 's' : 'h';
          if (po !== pe) r.fallos.push(`${n} plaza ${q.i}: porte ${po} con ${ip} % índica (${pe})`);
          if (!v.p.n.startsWith(nom)) r.fallos.push(`${n} plaza ${q.i}: fase ${st} (${po}) con ${v.p.n}`);
          // el más ancho que deja 2 px de aire en su sitio (o el más estrecho si ninguno); su sitio, hasta la vecina de fila o la pared
          const A = vcAnchos(nom), a = +v.p.n.slice(nom.length); r.anchos.add(a);
          if (A.some(b => b > a && b <= v.esp - 2) || (a > v.esp - 2 && A.some(b => b < a))) r.fallos.push(`${n} plaza ${q.i}: ${v.p.n} con ${v.esp} px de sitio`);
          const c0 = vcDibujo(v), h = vcAlto(c0), cima = q.y - v.tierra - h, D = PLANTA_CM[po], [x0, x1] = caja(c0), dx = q.x - (c0.width >> 1);
          dib[q.i] = [dx + x0, dx + x1];
          // de alto, el real de su porte y fase (ch como mucho) y su distancia al foco; el de su fotograma tal cual o aplastado 1 fila
          const tope = Math.min(vcAlto(v.p.f.c), Math.round(Math.min(D.h[st], q.ch) * Z), Math.floor(q.y - v.tierra - boca - FOCO_SEP[f] * Z));
          if (h !== v.hp || v.hp !== tope) r.fallos.push(`${n} plaza ${q.i}: ${h} px de alto (hp ${v.hp}, tope ${tope})`);
          if ((cima - boca) / Z < FOCO_SEP[f]) r.fallos.push(`${t} plaza ${q.i}: cima a ${((cima - boca) / Z).toFixed(1)} cm del foco (${FOCO_SEP[f]})`);
          if (v.hp < vcAlto(v.p.f.c)) { const [al, c, i] = vcAltura(v.p.n, v.hp);
            if (al === v.hp) { r.exactas++; if (c0 !== c) r.fallos.push(`${n} plaza ${q.i}: hay fotograma de ${al} px y no se usa`); }
            else { const k = aplastaBien(c, c0, v.hp); r.aplastadas++; if (!k.ok || (st >= 2 && al - v.hp > 1)) r.fallos.push(`${n} plaza ${q.i}: aplastada ${al} → ${v.hp} ${JSON.stringify(k)}`); } }
          // el tono de la hoja: los verdes de la paleta A pasan a los de su variedad (ni uno se queda si su tono es otro)
          // (lo que pinta vcPlantaC, no conRampa por su cuenta)
          const hj = hojaPlanta(p), T = vcTonos(hj), pinta = [], di = ctx.drawImage;
          ctx.drawImage = function (im, ...a) { pinta.push(im); return di.call(this, im, ...a); }; try { vcPlantaC(q, 1000); } finally { ctx.drawImage = di; }
          const pc = pinta.filter(im => im !== v.m.f.c).pop(), cs = pc ? colores(pc) : new Set();
          if (!pc || (hj !== '#57a33e' && (cs.has('#57a33e') || !cs.has(T['#57a33e'])))) r.fallos.push(`${n} plaza ${q.i}: hoja sin el tono ${hj}`); }
        // en pantalla, ninguna planta toca a su vecina de fila (2 px de aire) ni se sale por las paredes de su fila
        for (const a of g.pl) { if (!dib[a.i]) continue; const wy = g.vc.w + 32 * (a.y - VCA.fondo) / 19;
          if (dib[a.i][0] < 120 - wy / 2 - .5 || dib[a.i][1] > 120 + wy / 2 + .5) r.fallos.push(`${t} plaza ${a.i}: ${dib[a.i]} se sale de la pared (${(120 - wy / 2).toFixed(1)}-${(120 + wy / 2).toFixed(1)})`);
          for (const b of g.pl) if (a.i < b.i && dib[b.i] && a.y === b.y) { const aire = a.x < b.x ? dib[b.i][0] - dib[a.i][1] - 1 : dib[a.i][0] - dib[b.i][1] - 1;
            if (aire < 2) r.fallos.push(`${t}: plantas ${a.i} y ${b.i} a ${aire} px`); } }
        for (const a of g.pl) for (const b of g.pl) if (a.i < b.i && a.y === b.y && Math.abs(a.x - b.x) < ancho(a.v.m.f.c)) r.fallos.push(`${t}: macetas ${a.i} y ${b.i} se tocan`);
        if (e.pared || e.luz < 2000 || Math.abs(e.sigue) > .25 || e.objetos || e.luzTipo || Math.abs(e.foco - e.focoReal) > 3) r.fallos.push(JSON.stringify(e));
        // la luz se pinta después de todas las macetas y plantas, en 'overlay', y antes de la campana
        const orden = [], di = ctx.drawImage, luz = vcLuz(t, g.vc), suyas = new Set(g.pl.flatMap(q => [q.v.m.f.c, q.v.p && q.v.p.f.c]));
        ctx.drawImage = function (im, ...a) { orden.push(im === luz ? 'luz:' + ctx.globalCompositeOperation + ':' + ctx.globalAlpha : im === g.vc.foco.f.c ? 'foco' : suyas.has(im) || im.width === 40 ? 'obj' : '-'); return di.call(this, im, ...a); };
        VC = { ci: 0, sel: 0, ocupado: false }; renderCarpa(1000); VC = null; ctx.drawImage = di; r.escenas.push(n);
        const iL = orden.indexOf('luz:overlay:' + (f === 'cfl' ? .6 : 1));   // el CFL, más suave
        if (iL < 0 || orden.lastIndexOf('obj') > iL || orden.indexOf('foco') < iL) r.fallos.push(n + ': orden ' + orden.join(','));
      }
      // en cada carpa con cada foco con campana, los tres portes en vegetativo, floración y lista: su alto cae dentro de los fotogramas
      // de su sprite (sobra 1 fila como mucho: uno cada 2 px)
      r.cubre = 0;
      for (const t in CARPAS) for (const f in FOCOS) if (FOCOS[f].w <= CARPAS[t].wmax) for (const po of ['i', 'h', 's']) for (const pr of [.5, .8, 1]) {
        const sid = { i: 'rif', h: 'nepal', s: 'thai' }[po], g = pon(t, f, Array(CARPAS[t].plazas).fill(sid), pr); if (!g.vc) continue;
        for (const q of g.pl) { const v = q.v, L = vcAltura(v.p.n, v.hp); if (L[0] < v.hp || L[0] - v.hp > 1) r.fallos.push(`${t}/${f} ${po} ${pr} plaza ${q.i}: ${v.hp} px y el fotograma de ${L[0]}`); }
        r.cubre++; }
      // los fotogramas: uno cada 2 px de alto, del más alto al más bajo; sin filas repetidas (estirar repite filas: ninguna fila con hojas o
      // cogollos, más de 4 píxeles, el tronco con su contorno, igual a la de encima; las ramas peladas de la sativa alta, 2 como mucho); como
      // mucho del ancho de su nombre; en vegetativo sin cogollos y, en flor, más alta = más cogollo (nunca menos que una 10 filas más baja)
      r.altos = {};
      for (const po of ['i', 'h', 's']) for (const w of [38, 32]) for (const fa of ['', '2']) { const nm = 'planta-c-' + po + fa + '-' + w, F = fotos(nm), a = F.map(vcAlto), k = F.map(cogollo);
        r.altos[nm] = [a[0], a[a.length - 1], a.length];
        // los altos de cada sprite: los de las carpas (exporta.py)
        const E = fa ? { i: [36, 24], h: [42, 28], s: [46, 32] }[po] : { i: [66, 40], h: [72, 44], s: [w === 38 ? 92 : 80, 54] }[po];
        if (a[0] !== E[0] || a[a.length - 1] !== E[1]) r.fallos.push(nm + ': altos ' + a[0] + '-' + a[a.length - 1] + ', no ' + E.join('-'));
        if (a.some((h, i) => i && h !== a[i - 1] - 2) || F.some(c => ancho(c) > w) || F.some(c => repetidas(c) > 2) || (fa ? k.some(Boolean) : k.some((x, i) => k.some((y, j) => a[j] <= a[i] - 10 && y > x)) || !k[k.length - 1]))
          r.fallos.push(nm + ': ' + JSON.stringify({ a, k })); }
      r.repetidas = ['planta-c-h1-18', 'planta-c-h0-8'].map(n => fotos(n).reduce((s, c) => s + repetidas(c), 0)); if (r.repetidas.some(k => k)) r.fallos.push('filas repetidas (estirada): ' + r.repetidas);
      // la comprobación distingue: el vegetativo estirado a 90 filas (repitiendo filas, como la lista que se rechazó) sí repite
      { const a = fotoMisc('planta-c-h2-38').c, al = vcAlto(a), H = a.height, [e, x] = mkCanvas(a.width, H);
        for (let t = 0; t < 90; t++) x.drawImage(a, 0, H - al + Math.floor(t * al / 90), a.width, 1, 0, H - 90 + t, a.width, 1);
        r.estirada = repetidas(e); if (r.estirada < 20) r.fallos.push('repetidas no ve lo estirado: ' + r.estirada); }
      // el CFL apagado (carpa vacía): la campana dibujada es la apagada y el tubo (luminosidad > 170) se queda oscuro (< 100); sin luz
      { const g = pon('p60', 'cfl', [null, null]), fc = g.vc && g.vc.foco.f.c, off = fc && vcApagado(fc), Y = (d, i) => .299 * d[i] + .587 * d[i + 1] + .114 * d[i + 2],
          px = c => c.getContext('2d').getImageData(0, 0, c.width, c.height).data, tubo = fc ? [...px(fc).keys()].filter(i => i % 4 === 0 && px(fc)[i + 3] && Y(px(fc), i) > 170) : [],
          vivos = c => c === fc ? tubo.length : tubo.filter(i => Y(px(c), i) >= 100).length;
        let dib = 0, luzD = 0; const di = ctx.drawImage, luz = g.vc && vcLuz('p60', g.vc); ctx.drawImage = function (im, ...a) { if (im === off) dib++; if (im === luz) luzD++; return di.call(this, im, ...a); };
        if (g.vc) { VC = { ci: 0, sel: 0, ocupado: false }; renderCarpa(1000); VC = null; } ctx.drawImage = di;
        r.cflApagado = g.vc && { encendidos: vivos(fc), apagados: vivos(off), dib, luzD }; if (!g.vc || !r.cflApagado.encendidos || r.cflApagado.apagados || !dib || luzD) r.fallos.push('p60/cfl apagado: ' + JSON.stringify(r.cflApagado)); }
      // con el atlas, siempre la vista C (1.10): en cada carpa, con cada foco y cada maceta que admite, con los 4 extras y una planta muerta,
      // el foco y la maceta a su ancho real (×0,75-1,25) y los extras dibujados (filtro, ventilador, llaves, depósito pequeño; sin goteo, las
      // garrafas); sin el atlas, la vista B
      r.siempre = 0; r.b = {};
      for (const t in CARPAS) for (const f in FOCOS) if (FOCOS[f].w <= CARPAS[t].wmax) for (const k in MACETAS) if (MACETAS[k].l <= CARPAS[t].lmax) for (const got of [true, false]) {
        const n = CARPAS[t].plazas, g = pon(t, f, ['rif', ...Array(n - 1).fill('thai')], .8, { vent: true, filtro: true, garrafas: true, goteo: got, dep: 100 });
        S.macetas = Array(n).fill(k); S.pots[n - 1].dead = true; const G = vcGeo(0), vc = G.vc;
        if (!vc) { r.fallos.push(`${t}/${f}/${k}: sin vista C`); continue; }
        const fr = FOCO_CM[f] * vc.Z, mr = MACETA_CM[k][0] * vc.Z;
        if (Math.abs(ancho(vc.foco.f.c) - fr) > fr * .25 + 1) r.fallos.push(`${t}/${f}: foco de ${ancho(vc.foco.f.c)} px (${fr.toFixed(1)})`);
        for (const q of G.pl) if (Math.abs(ancho(q.v.m.f.c) - mr) > mr * .25 + 1) r.fallos.push(`${t}/${k}: maceta de ${ancho(q.v.m.f.c)} px (${mr.toFixed(1)})`);
        const usados = new Set(), di = ctx.drawImage, nom = new Map(Object.keys(ARTE.cubre).filter(c => c.startsWith('misc:extra-c-')).flatMap(c => { const s = c.slice(5), A = ARTE.cubre[c];
          return [...Array(frameDe(A, s, 'unica', 0, { i: 0 }).n)].map((_, i) => [frameDe(A, s, 'unica', 0, { i }).c, s.replace(/-\d+$/, '')]); }));
        ctx.drawImage = function (im, ...a) { usados.add(nom.get(im) || (im.width === 48 && im.height === 48 ? 'nivel' : '')); return di.call(this, im, ...a); };
        VC = { ci: 0, sel: 0, ocupado: false }; renderCarpa(1000); VC = null; ctx.drawImage = di;
        const falta = ['extra-c-filtro', 'extra-c-vent', ...(got ? ['extra-c-llave', 'nivel'] : ['nivel'])].filter(x => !usados.has(x));
        if (falta.length) r.fallos.push(`${t}/${f}/${k}${got ? ' goteo' : ''}: sin ${falta}`); r.siempre++; }
      { const ok = ARTE.ok; ARTE.ok = false; r.b.sinAtlas = !pon('p60', 'led100', ['mango', null]).vc; ARTE.ok = ok; }
      r.b.vacia = (() => { const g = pon('m100', 'sodio600', [null, null, null, null]); if (!g.vc) return false;   // vacía: vista C con el foco apagado, sin luz
          const luz = vcFondo('m100', g.vc, 'luz'), di = ctx.drawImage; let n = 0, encendido = 0;
          ctx.drawImage = function (im, ...a) { if (im === luz) n++; if (im === g.vc.foco.f.c) encendido++; return di.call(this, im, ...a); };
          VC = { ci: 0, sel: 0, ocupado: false }; renderCarpa(1000); VC = null; ctx.drawImage = di; return !n && !encendido; })();
      r.anchos = [...r.anchos].sort().join(); r.portes = [...r.portes].sort().join();
      S.carpas = C0; S.macetas = M0; S.pots = P0; return r; });
    check('Vista C (imagen A): en las 5 carpas, la planta A del porte de cada planta (su % índica) en todas sus fases, con el tono de hoja de su variedad; la más ancha que deja 2 px de aire con su vecina de fila y no se sale de las paredes (la de 38 o la de 32); de su alto real, sin pasar de su distancia al foco, con el fotograma de su alto (uno cada 2 px, sin filas repetidas, más alta = más cogollo) o aplastado 1 fila, sin escalar, en todas las carpas y focos; la pared solo lleva tela, macetas y plantas sin luz pintada y la luz es su propio sprite, por delante en «overlay» (la del CFL, fría y al 60 %); el CFL apagado, gris; con el atlas, siempre la vista C (cada foco, maceta y extra, a su ancho, y la muerta); sin atlas, la vista B', vc.escenas.length === 11 && vc.aplastadas >= 5 && vc.exactas >= 5 && vc.anchos === '18,32,38,8' && vc.portes === 'h0,h2,h3,h4,i0,i2,i3,i4,s1,s2,s3,s4' && vc.cubre >= 100 && vc.siempre >= 100 && !vc.fallos.length && Object.values(vc.b).every(Boolean), vc);
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
        const s = R('#screen'), u = R('#ui'), d = R('#dpad'), a = R('#ab'), st = R('#bStart'), so = R('#bSound'), gi = document.getElementById('girar'), cz = R('#dpad .cruz'), A = R('#ab [data-k=A]');
        const dentro = b => b.left >= 0 && b.top >= 0 && b.right <= w + .5 && b.bottom <= h + .5, cruza = (p, q) => p.left < q.right && q.left < p.right && p.top < q.bottom && q.top < p.bottom;
        const sinScroll = document.documentElement.scrollHeight <= h && document.documentElement.scrollWidth <= w;
        if (h > w) return { w, h, ok: !gi.hidden && R('#girar').width >= w - 1 && sinScroll, girar: !gi.hidden };
        const frac = s.width * s.height / (w * h), ancho = w / h >= 1.6, cuadrado = Math.abs(cv.width / 160 - s.width / s.height) < .02;
        const libre = ![d, a, st, so].some(b => cruza(b, u)), mm = 160 / 25.4;
        // mandos en mm (1.10): cruz de 24 mm y A/B de 10,5 si caben (móvil de 740 × 360 o más), y nunca menos que la 1.9 (17,3 y 7,6)
        const talla = w >= 740 && h >= 360 ? cz.width >= 24 * mm - 1 && A.width >= 10.5 * mm - 1 : cz.width >= 17.3 * mm - 1 && A.width >= 7.6 * mm - 1;
        // la caja de vida del combate (#bP) no queda debajo de A, B ni START (1.10)
        const bp = document.getElementById('bP'), oc = bp.hidden; bp.innerHTML = '<div class="row"><span>ANDER</span><span>12 g</span></div><div class="hp">VIDA<span><i></i></span></div><div class="num">20/20 · 1300 €</div>';
        bp.hidden = false; const P = R('#bP'), caja = ![A, R('#ab [data-k=B]'), st].some(b => cruza(b, P)) && P.left >= s.left && P.right <= s.right; bp.hidden = oc;
        return { w, h, ok: gi.hidden && [s, d, a, st, so].every(dentro) && sinScroll && cuadrado && libre && !cruza(d, a) && frac >= (ancho ? .9 : .8) && talla && u.width / 240 >= 1.29 && caja,
          SW, us: +(u.width / 240).toFixed(2), pantalla: Math.round(s.width) + '×' + Math.round(s.height), frac: +frac.toFixed(2), cuadrado, libre, caja, cruz: +(cz.width / mm).toFixed(1), A: +(A.width / mm).toFixed(1) }; }, [w, h]));
    }
    // la cruceta con un dedo (1.10): de ◀ a ▲ sin levantarlo cambia de flecha; un toque fuera de la cruz, en su zona, también vale
    await page.setViewportSize({ width: 844, height: 390 }); await page.waitForTimeout(80);
    const desliza = await page.evaluate(() => { ajustarPantalla(); const el = document.getElementById('dpad'), C = q => { const r = el.querySelector(q).getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; };
      const ev = (t, [x, y]) => el.dispatchEvent(new PointerEvent(t, { pointerId: 7, clientX: x, clientY: y, bubbles: true, cancelable: true })), H = () => Object.keys(held).filter(k => held[k]).join();
      const [l, u] = [C('.l'), C('.u')], r = {}; ev('pointerdown', l); r.baja = H(); for (let i = 1; i <= 6; i++) ev('pointermove', [l[0] + (u[0] - l[0]) * i / 6, l[1] + (u[1] - l[1]) * i / 6]);
      r.tras = H(); ev('pointerup', u); r.suelta = H(); const z = el.getBoundingClientRect(); ev('pointerdown', [z.left + 3, l[1]]); r.borde = H(); ev('pointerup', [z.left + 3, l[1]]); r.fin = H(); return r; });
    marco.push({ w: 'desliza', ok: desliza.baja === 'left' && desliza.tras === 'up' && desliza.suelta === '' && desliza.borde === 'left' && desliza.fin === '', ...desliza });
    // al perder el foco sin pointerup (otra app), la cruceta y A sueltan y la cruceta vuelve a responder a un dedo nuevo
    const foco = await page.evaluate(() => { const el = document.getElementById('dpad'), ab = document.getElementById('ab'), C = (e, q) => { const r = e.querySelector(q).getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; };
      const ev = (e, t, id, [x, y]) => e.dispatchEvent(new PointerEvent(t, { pointerId: id, clientX: x, clientY: y, bubbles: true, cancelable: true })), H = () => Object.keys(held).filter(k => held[k]).join();
      const r = {}; ev(el, 'pointerdown', 8, C(el, '.l')); ev(ab, 'pointerdown', 9, C(ab, '[data-k=A]')); r.antes = H(); dispatchEvent(new Event('blur')); r.blur = H();
      r.on = document.querySelectorAll('#mando .on').length; ev(el, 'pointerdown', 10, C(el, '.r')); r.nuevo = H(); ev(el, 'pointerup', 10, C(el, '.r')); r.fin = H();
      ev(ab, 'pointerdown', 11, C(ab, '[data-k=A]')); r.a = H(); ev(ab, 'pointerup', 11, C(ab, '[data-k=A]')); r.afin = H(); return r; });   // A/B olvidan el dedo de antes
    marco.push({ w: 'foco', ok: foco.antes === 'left,A' && foco.blur === '' && foco.on === 0 && foco.nuevo === 'right' && foco.fin === '' && foco.a === 'A' && foco.afin === '', ...foco });
    // márgenes seguros distintos a cada lado (muesca a un lado): la pantalla va corrida y el escenario sigue sin pisar los mandos (con 12 px, la
    // columna simétrica de antes lo pisaba 3 px)
    for (const lado of ['Left', 'Right']) {
      marco.push(await page.evaluate(lado => { const el = document.getElementById('consola'); el.style['padding' + lado] = '12px'; ajustarPantalla();
        const R = q => document.querySelector(q).getBoundingClientRect(), u = R('#ui'), cruza = (p, q) => p.left < q.right && q.left < p.right && p.top < q.bottom && q.top < p.bottom;
        const libre = !['#dpad', '#ab', '#bStart', '#bSound'].some(q => cruza(R(q), u)); el.style['padding' + lado] = ''; ajustarPantalla();
        return { w: 'muesca ' + lado, ok: libre && u.width / 240 >= 1.29, us: +(u.width / 240).toFixed(2) }; }, lado));
    }
    await page.setViewportSize({ width: 1000, height: 700 });
    check('Pantalla completa en horizontal: reborde, píxeles cuadrados y mandos en mm flotando sin pisar el escenario ni la caja de vida del combate en 7 tamaños (y con la muesca a un lado); la cruceta se desliza y todo se suelta al perder el foco; en vertical, «Gira el móvil»', marco.every(m => m.ok), marco.filter(m => !m.ok).concat(marco.length ? [] : ['sin datos']));
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
