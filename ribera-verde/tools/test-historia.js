#!/usr/bin/env node
/*
  Ribera Verde — prueba automática de la historia completa (capítulos 1 → 8)
  Abre index.html en Chromium sin ventana, instala un "piloto automático" que pulsa A
  en cada diálogo y elige opciones de menú por texto, y comprueba el estado tras cada paso.

  Requisitos (una vez):  npm install   y   npx playwright install chromium
  Uso:                   node tools/test-historia.js
  Resultado:             lista de pasos OK/FALLO + tools/salida/transcripcion.txt con todos los diálogos
  Oráculo del port de Godot (RV_ORACULO=archivo.json, RV_SEMILLA=n, 4242 por defecto): Math.random pasa a ser un Park-Miller
  con esa semilla, el reloj del juego y los paseos de los personajes se paran (solo corre la cola de eventos) y no se pinta
  nada; tras cada paso se guardan su transcripción, S, el estado del azar, R y dónde está cada personaje
  (godot/tests/historia.gd repite los mismos pasos y lo compara). Solo se escribe si pasan todos; la transcripción va a
  transcripcion-oraculo.txt.
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const OUT = process.env.RV_SALIDA ? path.resolve(process.env.RV_SALIDA) : path.join(__dirname, 'salida');
const ORAC = process.env.RV_ORACULO ? path.resolve(process.env.RV_ORACULO) : null, SEMILLA = +(process.env.RV_SEMILLA || 4242);
if (!Number.isInteger(SEMILLA) || SEMILLA < 1 || SEMILLA > 2147483646) throw new Error('RV_SEMILLA: un entero de 1 a 2147483646');

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage({ viewport: { width: 1000, height: 700 } });
  const errors = [];
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push('console: ' + m.text()); });
  await page.goto('file://' + (process.env.RV_HTML ? path.resolve(process.env.RV_HTML) : path.join(ROOT, 'index.html')));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
  if (ORAC) await page.evaluate(sem => {
    audioInit();   // el ruido del audio tira de Math.random: antes del Park-Miller
    window.PM = { s: sem }; Math.random = () => (PM.s = PM.s * 48271 % 2147483647) / 2147483647;
    window.update = () => { if (mode === 'world' && S && isFree() && pending.length && !P.moving) run(pending.shift()); };
    window.render = () => {};
  }, SEMILLA);

  // ---------- piloto automático dentro de la página ----------
  await page.evaluate(() => {
    try { localStorage.clear(); } catch (e) {}
    window.WANT = []; window.LOG = []; window.HOLD = false;
    const _menu = menu;
    window.menu = function (items, o = {}) {
      const labels = items.map(it => typeof it === 'string' ? it : it.label);
      if (WANT[0] === '<B>') { WANT.shift(); HOLD = true; setTimeout(() => { press('B'); HOLD = false; }, 5); LOG.push('  [menú] ' + labels.join(' | ') + '  → (B)'); }
      else {
        if (WANT.length) { const k = labels.findIndex(l => WANT[0].test(l)); if (k >= 0) { WANT.shift(); o = Object.assign({}, o, { initial: k }); } }
        LOG.push('  [menú] ' + labels.join(' | ') + '  → ' + labels[o.initial || 0]);
      }
      return _menu(items, o);
    };
    const _tt = typeText;
    window.typeText = function (t, n) { LOG.push((n ? n + ': ' : '') + nm(t)); return _tt(t, n); };
    setInterval(() => { if (!HOLD && handlers.length && !(mode === 'carpa' && VC && !VC.ocupado)) press('A'); }, 12);   // en la vista de carpa, las teclas las pulsa el paso
    window.idle = () => new Promise(r => { const t = setInterval(() => { if (isFree() && !pending.length) { clearInterval(t); r(); } }, 25); });
    window.want = w => { WANT = w.map(s => s === '<B>' ? s : new RegExp(s)); };
    window.pr = l => SHOP.find(it => it.lbl.startsWith(l)).p;   // precio de tienda por el principio del rótulo
    // las patrullas (1.10) no andan solas (ni con el reloj en marcha): los pasos que las prueban llaman a UPAT con un dt fijo
    window.UPAT = updatePatrullas; window.updatePatrullas = () => {};
  });

  const results = [], orac = [];
  async function step(name, wantList, fn, check) {
    await page.evaluate(w => want(w), wantList);
    const l0 = await page.evaluate(() => LOG.length);
    await LOGMARK(name);
    let ok = false, detail = '';
    try {
      await page.evaluate(fn);
      await page.evaluate(() => idle());
      const r = await page.evaluate(check);
      ok = r === true; detail = r === true ? '' : JSON.stringify(r);
    } catch (e) { detail = e.message.split('\n')[0]; }
    results.push({ name, ok, detail });
    if (ORAC) orac.push(Object.assign({ name, ok, detail }, await page.evaluate(l0 => JSON.parse(JSON.stringify({
      log: LOG.slice(l0), S, pm: PM.s, R: window.R, I: window.I, TO: window.TO,
      extra: { mode, map: S && S.map, x: P.x, y: P.y, dir: P.dir, ents: ents.map(e => [e.id, e.x, e.y, e.dir, e.wt]),
        vc: VC && { ci: VC.ci, sel: VC.sel, ocupado: VC.ocupado }, h: handlers.length, lock, pend: pending.length } })), l0)));
    console.log(`${ok ? 'OK   ' : 'FALLO'}  ${name}${detail ? '  → ' + detail : ''}`);
  }
  function LOGMARK(name) { return page.evaluate(n => LOG.push('\n=== ' + n + ' ==='), name); }

  // ---------- capítulo 1 ----------
  await step('Nueva partida e intro (prólogo en Mendialde)', [], async () => { await run(newGame); },
    () => S.ch === 1 && S.map === 'casa-ama' && S.flags.llegada === false && S.name === 'EDDIE' && /autobús/.test(objectiveText()) || { ch: S.ch, map: S.map, name: S.name, flags: S.flags });
  await step('Prólogo: la nota de ama y el táper de la nevera', [], async () => { await run(() => objectAction(5, 4)); await run(() => objectAction(9, 6)); await run(() => objectAction(9, 6)); },
    () => S.flags.notaAma === true && S.flags.taper === true && S.items.bocata === 2 || { flags: S.flags, items: S.items });
  await step('Prólogo: el autobús de Mendialde a Ribera Verde (billete de ama)', ['Ribera Verde'], async () => {
    await run(() => warp(MAPS['casa-ama'].exits['4,7'])); window.R = { mapa: S.map, x: P.x, y: P.y, m: S.money, t: S.min }; await run(paradaAction);
  }, () => R.mapa === 'mendialde' && R.x === 6 && R.y === 12 && S.map === 'town' && P.x === 7 && P.y === 12 && S.flags.llegada === true && S.money === R.m && S.min - R.t >= 40 && S.min - R.t < 46 || { R, map: S.map, x: P.x, y: P.y, m: S.money, t: S.min });
  await step('Entrar en el piso de la tía', [], async () => { await run(() => warp(MAPS.town.doors['5,8'])); },
    () => S.map === 'home' && objectiveText() === 'Lee la carta que hay en la mesa.' || { map: S.map, obj: objectiveText() });
  await step('Leer la carta de la tía', [], async () => { await run(() => objectAction(3, 5)); },
    () => S.flags.letter === true);
  await step('Kiko regala semillas y abono', [], async () => { await run(talkKiko); },
    () => S.seeds.ria === 3 && S.items.fert === 2 && S.flags.kiko1 || { seeds: S.seeds, items: S.items });
  await step('Plantar dos Skunk #1 y abonar una', ['Skunk', 'Skunk', 'Abonar'], async () => {
    await run(() => potAction(0)); await run(() => potAction(1)); await run(() => potAction(1));
  }, () => S.pots[0]?.sid === 'ria' && S.pots[1]?.fert === true && S.items.fert === 1 || { pots: S.pots });
  await step('Cuidar 3 días y cosechar → capítulo 2', ['Cosechar', 'Cosechar'], async () => {
    for (let i = 0; i < 9; i++) { S.pots.forEach(p => { if (p) { p.water = 100; p.pest = false; } }); advanceTime(8 * 60); }
    await idle(); await run(() => potAction(0)); await run(() => potAction(1));
  }, () => S.ch === 2 && S.buds.ria?.g > 30 && S.seeds.ria >= 1 && S.clients.length > 0 || { ch: S.ch, buds: S.buds, clients: S.clients.length });

  // ---------- capítulo 2 ----------
  await step('Vender a un cliente (rebaja) → 300 € → capítulo 3; el plazo de 3.000 € corre desde que aparece Toño', ['Skunk', 'Rebaja'], async () => {
    S.sales = META_VENTAS - 1; await run(() => talkClient(S.clients[0]));
  }, () => S.ch === 3 && S.sales >= META_VENTAS && S.heat > 0 && S.due === 3000 && S.deadline === S.day + 7 && S.flags.tono === S.day && !S.flags.metB || { ch: S.ch, sales: S.sales, due: S.due, deadline: S.deadline });
  await step('Hablar con Josune (pintxo)', ['Pintxo'], async () => { S.hp = 10; await run(talkJosune); },
    () => S.hp === 22 || { hp: S.hp });
  await step('Abuela Txaro: dar 5 g → Hindu Kush', ['Skunk'], async () => { await run(talkTxaro); },
    () => S.flags.txaro && S.seeds.hindu === 2 || { seeds: S.seeds });
  await step('Iñaki: vender 10 g → Malawi Gold', ['Skunk', 'Hecho'], async () => { addBuds('ria', 10, 12); await run(talkInaki); },
    () => S.flags.inaki && S.seeds.malawi === 2 || { seeds: S.seeds });
  await step('Iñaki al por mayor: 250 g de Skunk #1 a 3,20 €/g; una carga al día', ['Venta al por mayor', 'Skunk', '^250 g', 'Venta al por mayor'], async () => {
    S.buds = {}; addBuds('ria', 300, 12); window.R = { m: S.money, g: S.buds.ria.g }; await run(talkInaki); R.m1 = S.money; R.g1 = S.buds.ria.g; await run(talkInaki);
  }, () => R.m1 === R.m + 800 && R.g1 === R.g - 250 && S.mDay === S.day && S.money === R.m1 && Math.abs(precioMayor(12) - 3.2) < 1e-9 || R);
  await step('Arbusto escondido → Acapulco Gold', [], async () => { S.map = 'town'; await run(() => objectAction(2, 26)); S.map = 'home'; },
    () => S.seeds.acapulco === 2 || { seeds: S.seeds });
  await step('Autobús de pago: de Ribera Verde a Puerto Viejo (2 €, 25 min) y de allí a Valdehierro (4 €, 45 min)', ['Puerto Viejo', 'Valdehierro'], async () => {
    enterMap('town', 7, 12, 'up'); S.min = 10 * 60; window.R = { m: S.money }; await run(paradaAction); Object.assign(R, { mapa: S.map, x: P.x, y: P.y, m1: S.money, t1: S.min }); await run(paradaAction);
  }, () => R.mapa === 'puerto' && R.x === 20 && R.y === 9 && R.m1 === R.m - 2 && R.t1 >= 625 && R.t1 < 631 && S.map === 'valdehierro' && P.x === 15 && P.y === 11 && S.money === R.m - 6 && S.min - R.t1 >= 45 && S.min - R.t1 < 51 && ents.some(e => e.id === 'obrero') || { R, map: S.map, m: S.money, t: S.min });
  await step('Autobús de vuelta a Ribera Verde (2 €) y a casa', ['Ribera Verde'], async () => { R.m2 = S.money; await run(paradaAction); R.mapa2 = S.map; enterMap('home', 2, 4, 'down'); },
    () => S.money === R.m2 - 2 && R.mapa2 === 'town' && S.map === 'home' || { R, m: S.money, map: S.map });

  // ---------- capítulo 3 ----------
  await step('Don Baltasar explica la deuda', [], async () => { await run(talkBaltasar); },
    () => S.flags.metB && S.due === 3000 && S.debt === 30000 && S.deadline === S.flags.tono + 7 || { due: S.due, deadline: S.deadline, day: S.day });
  await step('Plazo vencido → Toño cobra intereses (1.er plazo vencido)', [], async () => { S.deadline = S.day; advanceTime(24 * 60); await idle(); },
    () => S.due === 3600 && S.debt === 30600 && S.deadline === S.day + 5 && S.vencidos === 1 || { due: S.due, debt: S.debt, vencidos: S.vencidos });
  await step('Pagar 3.600 € → capítulo 4', ['^Pagar'], async () => { S.money = 6000; await run(talkBaltasar); },
    () => S.ch === 4 && S.debt === 27000 && S.due === 0 || { ch: S.ch, debt: S.debt });

  // ---------- capítulo 4 ----------
  await step('Kiko instala la mesa de genética', [], async () => { await run(talkKiko); },
    () => S.flags.lab && S.seeds.rif === 3 || { lab: S.flags.lab, seeds: S.seeds });
  await step('Comprar en el growshop: un bote de abono (4 dosis) y un sobre de 10 Skunk #1', ['Abono', 'Semillas Skunk', 'Sobre de 10', 'Salir'], async () => {
    window.R = { m: S.money, s: S.seeds.ria || 0 }; await run(shop);
  }, () => S.items.fert === 5 && S.seeds.ria === R.s + 10 && S.money === R.m - 14 - 43 || { items: S.items, R, money: S.money, seeds: S.seeds.ria });
  await step('Growshop: carpa de 100, foco LED 200 W colgado en el armario y una maceta de tela', ['Carpa 100', 'Foco LED 200', '^Armario', 'Maceta de tela 11', 'Salir'], async () => {
    S.money = 2000; await run(shop);
  }, () => S.carpas[1]?.t === 'm100' && S.carpas[0].foco === 'led200' && S.items.f_cfl === 1 && S.items.m_tela11 === 1 && S.pots.length === 6 && S.macetas.length === 6 && S.money === 2000 - 120 - 220 - 3 && pr('Carpa 100') === 120
    || { carpas: S.carpas, items: S.items, pots: S.pots.length, money: S.money });
  await step('Plaza vacía: cambiar la maceta de 7 L por la de tela', ['Cambiar maceta', 'Tela 11'], async () => { await run(() => potAction(2)); },
    () => S.macetas[2] === 'tela11' && S.items.m_tela11 === 0 && S.items.m_plastico7 === 1 || { macetas: S.macetas, items: S.items });
  await step('Carpa: cambiar el foco desde la pared (sodio 400 W)', ['Cambiar foco', 'Sodio 400'], async () => { S.items.f_sodio400 = 1; await run(() => carpaAction(1)); },
    () => S.carpas[1].foco === 'sodio400' && S.items.f_cfl === 2 && S.items.f_sodio400 === 0 || { carpas: S.carpas, items: S.items });
  await step('Factura de la luz: solo paga la carpa con plantas (sodio 400 W: 157 kWh a 0,16 € = 25 €)', [], async () => {
    S.money = 100; S.pots[2] = { sid: 'ria', prog: .2, water: 100, health: 100, fert: false, pest: false }; advanceTime(24 * 60); await idle(); S.pots[2] = null;
  }, () => S.luz.e === 25 && S.money === 75 && kwhFoco('sodio400') === 157 || { luz: S.luz, money: S.money });
  await step('Vista de carpa: A delante del armario, ▶ plaza 2, A → Regar, B sale', ['Regar'], async () => {
    const hasta = f => new Promise(r => { const i = setInterval(() => { if (f()) { clearInterval(i); r(); } }, 20); });
    S.pots[1] = { sid: 'ria', prog: .5, water: 20, health: 100, fert: false, pest: false };
    const t = MAPS.home.carpas.find(t => t.ci === 0); enterMap('home', t.x0, t.y + 1, 'up');
    press('A'); await hasta(() => mode === 'carpa' && handlers.length === 1);
    window.R = { sel0: VC.sel, x0: vcGeo(0).pl.map(q => q.x) }; press('right'); R.sel = VC.sel; R.info = document.getElementById('vcInfo').textContent;
    press('A'); await hasta(() => VC && !VC.ocupado && handlers.length === 1); R.agua = S.pots[1].water;
    press('B'); await hasta(() => mode === 'world' && isFree());
  }, () => R.sel0 === 0 && R.sel === 1 && /Plaza 2/.test(R.info) && R.agua === 100 && !VC && document.getElementById('vcInfo').hidden || R);
  await step('Growshop: armario 80 en el sitio A; cada planta se queda en su carpa y su plaza', ['Armario 80', 'Salir'], async () => {
    S.money = 1000; S.pots[3] = { sid: 'txoko', prog: .3, water: 90, health: 100, fert: false, pest: false };
    window.R = { antes: S.pots.map(p => JSON.stringify(p)), mac: S.macetas.slice() }; await run(shop); enterMap('home', 5, 5, 'up');
    const g = vcGeo(0).pl; R.filas = g.map(q => q.fila).join(); R.atras = g[2].x > g[0].x && g[2].x < g[1].x; R.movida = JSON.stringify(S.pots[4]); S.pots[4] = null;
  }, () => S.carpas[0].t === 'p80' && S.carpas[0].foco === 'led200' && S.money === 1000 - 90 && S.pots.length === 7 && R.filas === '0,0,1' && R.atras
    && [0, 1].every(i => JSON.stringify(S.pots[i]) === R.antes[i]) && R.antes[3] !== 'null' && R.movida === R.antes[3] && S.pots[3] === null && S.macetas[2] === 'plastico7' && S.macetas[3] === R.mac[2] && MAPS.home.carpas.length === 2
    || { carpas: S.carpas, money: S.money, R, pots: S.pots.map(p => JSON.stringify(p)), macetas: S.macetas });
  await step('Extras: ventilador, filtro y goteo en la carpa de 100 (el goteo riega del depósito); sin filtro, el olor de la floración sube el calor', ['Ventilador', '^Carpa 100', 'Extractor', '^Carpa 100', 'Riego por goteo', '^Carpa 100', 'Salir', 'Poner filtro'], async () => {
    S.money = 1000; await run(shop); const flor = () => ({ sid: 'ria', prog: .8, water: 100, health: 100, fert: false, pest: false });
    window.R = { money: S.money, f: factores(4), m: MACETAS[S.macetas[4]], F: FOCOS[S.carpas[1].foco] };
    S.protect = false; S.pots[0] = flor(); S.pots[4] = flor(); S.heat = 30; advanceTime(24 * 60); await idle(); R.h1 = S.heat;
    S.items.x_filtro = 1; await run(() => carpaAction(0)); advanceTime(24 * 60); await idle(); R.h2 = S.heat; S.pots[0] = S.pots[4] = null;
  }, () => S.carpas[1].vent && S.carpas[1].filtro && S.carpas[1].goteo && R.money === 1000 - 20 - 110 - 55 && Math.abs(R.f.plaga - R.m.plaga * .7) < 1e-9 && Math.abs(R.f.agua - R.F.agua * R.m.agua) < 1e-9 && S.carpas[1].dep < GOTEO_L
    && R.h1 === 30 - 12 + 2 && R.h2 === R.h1 - 12 && S.carpas[0].filtro && !S.items.x_filtro || { carpas: S.carpas, R, items: S.items });
  await step('Cruce de receta: Afghani × Skunk #1 → Critical Mass (de receta, sacada en la mesa: falta cosecharla)', ['^Afghani', '^Skunk #1', 'Cruzar'], async () => {
    addSeeds('ria', 2); addSeeds('txoko', 2); await run(labAction);
  }, () => S.seeds.kushrif === 2 && S.disc.kushrif && S.gen.kushrif === 1 && S.rec.kushrif === 1 && recCount() === 0 || { seeds: S.seeds, gen: S.gen, rec: S.rec });
  // de la madre (la Skunk #1, 65 % índica) saca el m % (30-70) y del padre (la Hindu Kush, 100 %) el resto: % índica, tono de hoja y cogollo
  await step('Cruce libre: Skunk #1 × Hindu Kush → híbrido propio (m % de la madre, el resto del padre); 8 variedades ya no pasan de capítulo', ['^Skunk #1', '^Hindu Kush', 'Cruzar'], async () => {
    await run(labAction); const k = Object.keys(S.custom)[0]; window.R = { k, c: S.custom[k], linea: k && strainLine(k).split('\n')[1] };
  }, () => Object.keys(S.custom).length === 1 && discCount() >= 8 && S.ch === 4 && S.due === 0 && !(R.k in S.rec) && /\(0\/2\)/.test(objectiveText()) && R.c.ma === 'ria' && R.c.pa === 'hindu' && R.c.m >= 30 && R.c.m <= 70
    && R.c.ind === Math.round((R.c.m * 65 + (100 - R.c.m) * 100) / 100) && R.c.hj === mix(STRAINS.hindu.hj, STRAINS.ria.hj, R.c.m / 100) && R.c.c === mix(STRAINS.hindu.c, STRAINS.ria.c, R.c.m / 100)
    && R.linea === `Índica ${R.c.ind} % · sativa ${100 - R.c.ind} % · ${R.c.m} % madre · ${100 - R.c.m} % padre` || { custom: S.custom, disc: discCount(), ch: S.ch, R });

  await step('Estabilizar Critical Mass: F1 → F2 → F3 → estable', ['^Critical Mass', 'estabilizar', 'Estabilizar', '^Critical Mass', 'estabilizar', 'Estabilizar', '^Critical Mass', 'estabilizar', 'Estabilizar'], async () => {
    window.R = []; for (let k = 0; k < 3; k++) { if (k) addSeeds('kushrif', 1); await run(labAction); R.push(genDe('kushrif') + ':' + S.seeds.kushrif); }
  }, () => R.join() === '2:1,3:1,4:1' && !('kushrif' in S.gen) || { R, gen: S.gen, seeds: S.seeds.kushrif });
  await step('Banco de semillas del PC: Punto Rojo y Thai, llegan al día siguiente', ['Banco de semillas', '^Punto Rojo', '^Thai', 'Salir'], async () => {
    S.money = 500; await run(pcAction); window.R = { pedido: S.pedido.slice(), money: S.money, antes: !!S.seeds.thai }; newDay();
  }, () => R.pedido.join() === 'punto,thai' && R.money === 500 - 30 - 30 && !R.antes && S.seeds.punto === 10 && S.seeds.thai === 10 && S.disc.thai && !S.pedido.length || { R, seeds: S.seeds, pedido: S.pedido });
  await step('Cruce de landraces: Punto Rojo × Thai → Haze (F1: cada planta con su fenotipo; la línea da semillas)', ['^Punto Rojo', '^Thai', 'Cruzar'], async () => {
    await run(labAction);
    window.R = []; for (let k = 0; k < 12; k++) {
      S.pots[0] = { sid: 'haze', prog: 1, water: 80, health: 100, fert: false, pest: false, f: rollFeno('haze') }; const e = gramosPlanta(S.pots[0], factores(0)), y = S.pots[0].f.y;
      const b = Object.entries(S.buds).filter(([k]) => lotSid(k) === 'haze').reduce((a, [, v]) => a + v.g, 0), sd = S.seeds.haze || 0; await run(() => harvest(0));
      R.push({ g: Object.entries(S.buds).filter(([k]) => lotSid(k) === 'haze').reduce((a, [, v]) => a + v.g, 0) - b, e, y, sd: S.seeds.haze - sd }); }
  }, () => S.disc.haze && S.gen.haze === 1 && new Set(R.map(r => r.g)).size > 2 && R.every(r => r.g === r.e && r.sd >= 2 && r.sd <= 5) && /F1: línea inestable/.test(strainLine('haze')) && tipoGen('haze') === 'F1'
    && S.rec.haze === 2 && recCount() === 1 && S.ch === 4 || { R, gen: S.gen.haze, rec: S.rec, ch: S.ch });
  await step('Cosechar una Critical Mass, la 2.ª de receta sacada en la mesa → capítulo 5', [], async () => {
    S.pots[0] = { sid: 'kushrif', prog: 1, water: 80, health: 100, fert: false, pest: false, f: rollFeno('kushrif') }; await run(() => harvest(0));
  }, () => S.rec.kushrif === 2 && recCount() === 2 && S.ch === 5 && S.due === 12000 && loadSave().due === 12000 || { rec: S.rec, ch: S.ch, due: S.due });

  // ---------- capítulo 5 ----------
  await step('Growshop: carpa 120 en el sitio C, junto a la cama (6 plazas más)', ['Carpa 120', 'Salir'], async () => {
    S.money = 1000; await run(shop); enterMap('home', 5, 5, 'up');
  }, () => S.carpas[2]?.t === 'm120' && S.carpas[2].foco === 'cfl' && huecos().length === 13 && S.pots.length === 13 && S.macetas.length === 13 && S.money === 1000 - 150
    && MAPS.home.carpas.some(t => t.ci === 2 && t.x0 === 2 && t.x1 === 3) && tileSolid(MAPS.home, 2, 2) && tileSolid(MAPS.home, 3, 2) || { carpas: S.carpas, money: S.money, n: huecos().length, mapa: MAPS.home.carpas });
  await step('Sargento Molina: pagar protección (1.500 € cada 10 días)', ['^Pagar'], async () => { S.money = 1600; await run(talkMolina); },
    () => S.protect === true && S.money === 100 && S.protHasta === S.day + 10 && S.flags.molina1 || { protect: S.protect, money: S.money, hasta: S.protHasta });
  await step('Calor 95 con protección → Molina para la redada', ['Skunk'], async () => {
    addSeeds('ria', 1); await run(() => potAction(0)); S.heat = 95; advanceTime(24 * 60); await idle();
  }, () => S.heat === 50 && S.pots[0] !== null || { heat: S.heat, pot: S.pots[0] });
  await step('Calor 95 sin protección → redada', [], async () => {
    S.protect = false; S.heat = 95; addBuds('ria', 10, 12); advanceTime(24 * 60); await idle();
  }, () => S.pots.every(p => p === null) && Object.keys(S.buds).length === 0 && S.heat === 30 || { pots: S.pots, buds: S.buds, heat: S.heat });
  await step('Pagar 12.000 € → capítulo 6', ['^Pagar'], async () => { S.protect = true; S.money = 12500; await run(talkBaltasar); },
    () => S.ch === 6 && S.debt === 15000 && S.money === 500 || { ch: S.ch, debt: S.debt });

  // ---------- capítulo 6 ----------
  await step('Darko presume', [], async () => { await run(talkDarko); }, () => S.ch === 6);
  await step('Copa: presentar Skunk #1 (12%) → pierde', ['Skunk'], async () => { addBuds('ria', 25, 12); await run(talkJurado); },
    () => S.ch === 6 && Math.round(S.buds.ria.g) === 5 || { ch: S.ch, buds: S.buds });
  await step('Copa: presentar Fire OG (27,2%) → gana → capítulo 7', ['Fire OG'], async () => {
    S.money = 0; addBuds('dragon', 25, 27.2); await run(talkJurado);
  }, () => S.ch === 7 && S.money === 5000 && S.due === 15000 && S.flags.copa && loadSave().due === 15000 || { ch: S.ch, money: S.money, due: S.due, guardado: loadSave().due });

  // ---------- capítulo 7 → final ----------
  await step('Pagar los últimos 15.000 € → deuda saldada: empieza tu imperio (capítulo 8, con su rótulo)', ['^Pagar'], async () => {
    S.money += 10000; window.TO = []; const _t = toast; window.toast = (h, ms) => { TO.push(h); _t(h, ms); }; await run(talkBaltasar); window.toast = _t;
  }, () => TO.some(h => /CAPÍTULO 8.*Tu imperio/.test(h)) && S.ch === 8 && S.debt === 0 && S.imp0 === S.sales && imperioNivel() === 0 && mayorDia() === 1000 && /^Tu imperio · Cultivador/.test(objectiveText()) && document.getElementById('endcard').hidden || { ch: S.ch, debt: S.debt, o: objectiveText() });
  await step('Imperio: 25.000 € facturados → Proveedor del barrio; Iñaki carga 2 kg al día', [], async () => {
    S.sales += 25000; await run(checkStory);
  }, () => S.impN === 1 && mayorDia() === 2000 && /Proveedor del barrio/.test(objectiveText()) || { impN: S.impN, o: objectiveText() });

  // ---------- sistemas sueltos ----------
  await step('Combate ladrón: ganar con spray', Array(12).fill(['MOCHILA', 'SPRAY']).flat(), async () => {
    S.hpMax = 60; S.hp = 60; S.items.spray = 12; S.money = 100; await run(() => battle('thief')); WANT = [];
  }, () => S.money > 100 && S.hpMax === 60 && mode === 'world' || { money: S.money, hpMax: S.hpMax, mode });
  await step('Combate ladrón: desmayo → despiertas en casa (se lleva la mitad de la flor y del rosin y el 30 % del dinero, y lo dice)', [], async () => {
    S.hpMax = 30; S.hp = 1; S.money = 1000; S.buds = {}; addBuds('ria', 20, 12); S.rosin = { ria: { g: 3, thc: 36 } }; S.map = 'town'; await run(() => battle('thief'));
  }, () => S.map === 'home' && S.hp === S.hpMax && S.money === 700 && S.buds.ria.g === 10 && S.rosin.ria.g === 1.5 && LOG.some(l => l.includes('Te roba 10 g, 1,5 g de rosin y 300 €'))
    || { map: S.map, hp: S.hp, money: S.money, buds: S.buds, rosin: S.rosin });
  await step('Ladrón vencido sube la VIDA máxima', ['LUCHAR', 'PATADA'].concat(Array(20).fill(['MOCHILA', 'SPRAY']).flat()), async () => {
    S.hpMax = 40; S.hp = 40; S.items.spray = 20; await run(() => battle('thief')); WANT = [];
  }, () => S.hpMax === 42 || { hpMax: S.hpMax });
  await step('Policía: soborno con protección (40 + 4 × calor + 0,5 × gramos + 5 % del dinero encima)', ['SOBORNAR', '^Sí'], async () => {
    S.protect = true; S.rosin = {}; S.heat = 40; S.money = 1000; addBuds('ria', 10, 12); window.R = { p: precioSoborno(), g: totalBuds() }; await run(() => battle('police'));
  }, () => R.p === Math.round(40 + 160 + R.g * .5 + 50) && S.money === 1000 - R.p && S.heat === 30 && !!S.buds.ria || { money: S.money, heat: S.heat, R });
  await step('Agente en la plaza: entregar la mercancía', ['ENTREGAR'], async () => {
    S.protect = false; addBuds('ria', 5, 12); await run(talkCop);
  }, () => Object.keys(S.buds).length === 0 || { buds: S.buds });
  await step('Menú START: Genoteca, Mochila, Plantas, Objetivo', ['GENOTECA', '<B>', 'MOCHILA', '<B>', 'PLANTAS', '<B>', 'OBJETIVO', 'SALIR'],
    async () => { await run(startMenu); }, () => handlers.length === 0);
  await step('Cama: siesta de 3 horas', ['Siesta'], async () => { S.min = 600; S.hp = 5; await run(bedAction); },
    () => (S.min === 780 || S.min === 781) && S.hp === S.hpMax || { min: S.min, hp: S.hp });   // 780 = 600 + 180; entre la siesta y la comprobación puede pasar un minuto de reloj real
  // y el % índica de cada planta: igual al de su variedad en una línea estable; alrededor del suyo (σ de su tipo) en una landrace
  await step('Fenotipos: 200.000 plantas por tipo → 1 estrella de cada N (GENETICA[t].uno); de menos a más variable; % índica de cada planta', [], async () => {
    window.R = {}; for (const t in GENETICA) { let n = 0, fl = 0; for (let k = 0; k < 200000; k++) { const f = tiraFeno(GENETICA[t].sigma); if (claseFeno(f) === 'estrella') n++; if (claseFeno(f) === 'floja') fl++; } R[t] = { n, fl, E: 200000 / GENETICA[t].uno }; }
    const n0 = S.fenoN, ria = new Set(), np = []; for (let k = 0; k < 5000; k++) { ria.add(rollFeno('ria').i); np.push(rollFeno('nepal').i); } S.fenoN = n0;
    const m = np.reduce((a, b) => a + b, 0) / np.length; window.I = { ria: [...ria].join(), media: +m.toFixed(1), sd: +Math.sqrt(np.reduce((a, b) => a + (b - m) ** 2, 0) / np.length).toFixed(1) };
  }, () => Object.values(R).every(r => Math.abs(r.n - r.E) <= 4 * Math.sqrt(r.E) + 3 + .1 * r.E) && I.ria === '65' && Math.abs(I.media - 50) < 1 && Math.abs(I.sd - GENETICA.landrace.si) < 1 && ['estable', 'f1', 'F1', 'landrace', 'poli', 'F2'].every((t, i, a) => !i || R[t].n > R[a[i - 1]].n)
    && tipoGen('ria') === 'estable' && tipoGen('mango') === 'f1' && tipoGen('limon') === 'poli' && tipoGen('thai') === 'landrace' && /Cruce F1 \(KC 33 × Afghani\)/.test(strainLine('mango')) || { R, I });
  await step('Esquejes: el clon guarda el fenotipo estrella de la madre; su cosecha va a un lote aparte (★); sin plantar se seca', ['Sacar esqueje', 'Sacar esqueje', 'Cosechar', '^Esqueje'], async () => {
    S.esquejes = []; S.buds = {}; const f = { id: 9999, t: 1.25, y: 1.15 };
    S.pots[0] = { sid: 'limon', prog: .4, water: 100, health: 100, fert: false, pest: false, f }; await run(() => potAction(0)); await run(() => potAction(0));
    window.R = { n: S.esquejes.length, id: S.esquejes.map(e => e.f.id).join() }; S.pots[0].prog = 1; await run(() => potAction(0));
    R.feno = S.fenos[9999]; R.lote = !!S.buds['limon*'] && !S.buds.limon; await run(() => potAction(0)); R.pot = JSON.stringify(S.pots[0]); R.queda = S.esquejes.length;
    advanceTime(48 * 60); await idle(); R.seco = S.esquejes.length; S.pots[0] = null;
  }, () => R.n === 2 && R.id === '9999,9999' && R.feno === 'estrella' && R.lote && JSON.parse(R.pot).f.id === 9999 && JSON.parse(R.pot).prog === .12 && R.queda === 1 && R.seco === 0 || R);
  await step('Cifras reales: CFL en el armario 60 ≈ 0,3 g/W; LED 720 W en la carpa 150 con macetas de 25 L ≈ 1-1,35 g/W y 45 € de luz; tope de la maceta', [], async () => {
    const S0 = S; S = JSON.parse(JSON.stringify(S0)); const sk = h => ({ sid: 'ria', prog: 1, water: 100, health: h, fert: true, pest: false, f: { t: 1, y: 1 } });
    S.carpas = [{ t: 'p60', foco: 'cfl' }, { t: 'g150', foco: 'led720' }]; S.macetas = ['plastico7', 'plastico7'].concat(Array(6).fill('tela25'));
    const gw = (a, b, w) => huecos().slice(a, b).reduce((s, h, j) => s + gramosPlanta(sk(100), factores(a + j)), 0) / w;
    window.R = { cfl: gw(0, 2, 125), led: gw(2, 8, 720), luz: luzCarpa(1) };
    S.carpas[0].foco = 'led200'; R.tope = gramosPlanta(sk(100), factores(0)); S = S0;
  }, () => R.cfl >= .25 && R.cfl <= .4 && R.led >= 1 && R.led <= 1.35 && R.luz === 45 && R.tope === 56 || R);
  await step('Semillas al cosechar: Hindu Kush (regular) da 1-3 siempre; Skunk #1 (feminizada de tienda) solo si sale hermafrodita', [], async () => {
    const r0 = Math.random, sd = S.seeds; window.R = {}; const cos = async (sid, x) => {
      S.seeds = {}; Math.random = () => x; S.pots[0] = { sid, prog: 1, water: 100, health: 100, fert: false, pest: false, f: { t: 1, y: 1 } };
      await run(() => harvest(0)); Math.random = r0; return S.seeds[sid] || 0; };
    R.hindu = [await cos('hindu', .99), await cos('hindu', .5), await cos('hindu', .01)]; R.skunk = [await cos('ria', .5), await cos('ria', .05)]; S.seeds = sd;
  }, () => R.hindu.every(n => n >= 1 && n <= 3) && R.skunk[0] === 0 && R.skunk[1] >= 1 || R);
  await step('Partida de la 1.9 en el capítulo 7 (2.000 € en 3 días) → 15.000 € con 7 días; guardada sin plazo en el 5 → 12.000 €; punto de miles', [], async () => {
    const S0 = S; S = JSON.parse(JSON.stringify(S0)); Object.assign(S, { ch: 7, debt: 2000, due: 2000, deadline: S.day + 3 }); delete S.eco; migrate();
    window.R = { due: S.due, dias: S.deadline - S.day, eco: S.eco, eur: [eur(999), eur(3000), eur(1500.4), eur(-1234), eur(30000)].join('|') };
    Object.assign(S, { ch: 5, debt: 27000, due: 0, deadline: S.day - 2 }); migrate(); R.due5 = S.due; R.dias5 = S.deadline - S.day; S = S0;
  }, () => R.due === 15000 && R.dias === 7 && R.eco === 2 && R.eur === '999 €|3.000 €|1.500 €|-1.234 €|30.000 €' && R.due5 === 12000 && R.dias5 === 10 || R);
  await step('Capítulo 4: la 8.ª variedad (de un arbusto) no pasa de capítulo; la 2.ª de receta cosechada, sí', [], async () => {
    S.ch = 4; S.flags.lab = true; S.due = 0; S.disc = { ria: true, limon: true, txoko: true, niebla: true, mango: true, purpura: true, rif: true };
    S.custom = {}; S.rec = { kushrif: 2, citrus: 1 }; delete S.taken.h_acap; S.map = 'town'; await run(() => objectAction(2, 26)); S.map = 'home'; await idle();
    window.R = { ch: S.ch, disc: discCount() }; S.pots[0] = { sid: 'citrus', prog: 1, water: 80, health: 100, fert: false, pest: false, f: rollFeno('citrus') }; await run(() => harvest(0));
  }, () => R.ch === 4 && R.disc === 8 && S.ch === 5 && S.due === 12000 && loadSave().due === 12000 || { R, ch: S.ch, guardado: loadSave().due });
  // ---------- 1.10: la caja fuerte, el guion completo y el mapa ampliado ----------
  await step('Caja de la tía: la pista en el PC («el año en que lo gané»); detrás del diploma, 1987 no abre y 1998 sí (300 € dentro)', ['Notas de la tía', 'Mirar detrás', '^1987', 'Mirar detrás', '^1998'], async () => {
    for (const k in S.seeds) if (!getStrain(k)) delete S.seeds[k];   // el paso de la 8.ª variedad vació S.custom: fuera las semillas del híbrido
    S.map = 'home'; S.ch = 5; S.caja = null; S.money = 0; const l0 = LOG.length; await run(pcAction); await run(() => objectAction(7, 1));
    window.R = { pista: /el año en que lo gané/.test(LOG.slice(l0).join('\n')), tras1987: S.caja }; await run(() => objectAction(7, 1));
  }, () => R.pista && R.tras1987 === null && S.caja && S.caja.nivel === 1 && S.caja.money === 300 && cajaG() === 0 && S.money === 0 || { R, caja: S.caja });
  await step('Caja: guardar todo (5.000 € y 300 g); sin nada encima no hay ladrones ni policía en la calle; la mochila la enseña', ['Guardar todo', 'Cerrar', 'MOCHILA', '<B>', 'SALIR'], async () => {
    S.money = 5000; S.buds = {}; addBuds('ria', 200, 12); addBuds('dragon', 100, 27); S.protect = false; S.heat = 100;
    const enc = () => { const r0 = Math.random, b0 = battle, n = []; window.battle = async t => { n.push(t); }; Math.random = () => 0; S.map = 'town';
      const [x, y] = CLIENT_TILES.town[0]; for (let k = 0; k < 20; k++) { P.x = x; P.y = y; S.cool = 0; onStepEnd(); } Math.random = r0; window.battle = b0; S.map = 'home'; S.cool = 0; return n.length; };
    window.R = { antes: enc() }; await run(() => objectAction(7, 1)); R.despues = enc(); R.caja = JSON.parse(JSON.stringify(S.caja)); R.m = S.money; R.g = totalBuds();
    const l0 = LOG.length; await run(startMenu); R.mochila = LOG.slice(l0).find(l => /\[menú\] Dinero/.test(l)) || '';
  }, () => R.antes === 20 && R.despues === 0 && R.caja.money === 5300 && R.caja.buds.ria.g === 200 && R.caja.buds.dragon.g === 100 && R.m === 0 && R.g === 0 && /Caja fuerte/.test(R.mochila) || R);
  await step('Caja: sacar 1.000 € y 100 g de Fire OG; el soborno cuenta lo de encima (+5 % del dinero)', ['Sacar dinero', '^1\\.000 €', 'Sacar cogollos', '^Fire OG', '^100 g', 'Cerrar'], async () => {
    S.heat = 20; await run(() => objectAction(7, 1)); window.R = { p: precioSoborno() };
  }, () => S.money === 1000 && S.caja.money === 4300 && S.buds.dragon.g === 100 && !S.caja.buds.dragon && S.caja.buds.ria.g === 200 && R.p === Math.round(40 + 80 + 50 + 50) || { R, money: S.money, caja: S.caja, buds: S.buds });
  await step('Redada con la caja: 3 de cada 4 veces no la ven; si la ven, sus gramos y la mitad de su dinero; la multa sale de la caja si fuera no llega', [], async () => {
    const r0 = Math.random, mira = () => ({ m: S.money, cm: S.caja.money, cg: cajaG(), g: totalBuds(), h: S.heat, pots: S.pots.filter(p => p).length });
    S.protect = false; S.pots = S.pots.map(() => null); S.pots[1] = { sid: 'ria', prog: .5, water: 90, health: 100, fert: false, pest: false };
    S.caja.money = 4000; S.money = 200; S.heat = 95; Math.random = () => .9; await run(raidEvent); Math.random = r0; window.R = { a: mira() };
    addBuds('ria', 30, 12); S.heat = 95; Math.random = () => .1; await run(raidEvent); Math.random = r0; R.b = mira();
  }, () => R.a.m === 0 && R.a.cm === 4000 - (MULTA_REDADA - 200) && R.a.cg === 200 && R.a.g === 0 && R.a.h === 30 && R.a.pots === 0
    && R.b.cg === 0 && R.b.g === 0 && R.b.cm === Math.max(0, R.a.cm - Math.floor(R.a.cm / 2) - MULTA_REDADA) && R.b.m === 0 && R.b.h === 30 || R);
  await step('Caja empotrada por el ordenador (380 €, de fuera y el resto de la caja): Kiko la instala al día siguiente', ['Caja empotrada', 'Pedirla'], async () => {
    S.caja.money = 1000; S.money = 100; await run(pcAction); window.R = { m: S.money, cm: S.caja.money, mejora: S.caja.mejora, nivel: S.caja.nivel };
    const l0 = LOG.length; newDay(); await idle(); R.sms = LOG.slice(l0).some(l => /caja empotrada/.test(l));
  }, () => R.m === 0 && R.cm === 1000 - 280 && R.mejora === 1 && R.nivel === 1 && S.caja.nivel === 2 && !S.caja.mejora && S.caja.money === 720 && R.sms || { R, caja: S.caja });
  await step('Capítulo 7: Darko roba el piso la primera noche con dinero o cogollos fuera de la caja (la mitad); la caja, intacta; la segunda noche, nada', ['Dormir', 'Dormir'], async () => {
    S.ch = 7; S.flags.robo = false; S.deadline = S.day + 20; S.money = 3001; S.buds = {}; addBuds('ria', 120, 12); addBuds('kushrif', 81, 20);
    S.caja.money = 720; S.caja.buds = { dragon: { g: 50, thc: 27 } }; S.pots = S.pots.map(() => null); S.min = 23 * 60;
    await run(bedAction); window.R = { m: S.money, ria: S.buds.ria.g, kr: S.buds.kushrif.g, cm: S.caja.money, cg: cajaG(), robo: S.flags.robo };
    S.min = 23 * 60; await run(bedAction); R.m2 = S.money; R.g2 = totalBuds();
  }, () => R.robo && R.m === 1501 && R.ria === 60 && R.kr === 41 && R.cm === 720 && R.cg === 50 && R.m2 === 1501 && R.g2 === 101 || R);
  await step('Tercer plazo vencido: Toño se lleva la carpa más grande (la de 120, no la de 100) y cada planta sigue en su plaza; después, la otra; sin carpas, la mitad del dinero', [], async () => {
    S.ch = 5; const pl = sid => ({ sid, prog: .3, water: 90, health: 100, fert: false, pest: false });
    S.pots = S.pots.map(() => null); S.pots[0] = pl('ria'); S.pots[3] = pl('hindu'); S.pots[8] = pl('thai'); S.pots[12] = pl('haze');
    window.R = { t: S.carpas.map(c => c && c.t).join(), h0: huecos().length }; S.vencidos = 2; S.due = 1000; S.money = 901; await run(penaltyEvent);
    R.a = { t: S.carpas.map(c => c && c.t).join(), n: huecos().length, v: S.vencidos, p0: S.pots[0] && S.pots[0].sid, p3: S.pots[3] && S.pots[3].sid, vivas: S.pots.filter(p => p).length, mapa: MAPS.home.carpas.length };
    for (const k of [1, 2]) { S.vencidos = 2; await run(penaltyEvent); R['v' + k] = S.carpas.map(c => c && c.t).join() + '|' + S.money + '|' + S.pots.length; }
  }, () => R.t === 'p80,m100,m120' && R.h0 === 13 && R.a.t === 'p80,m100,' && R.a.n === 7 && R.a.v === 0 && R.a.p0 === 'ria' && R.a.p3 === 'hindu' && R.a.vivas === 2 && R.a.mapa === 2
    && R.v1 === 'p80,,|901|3' && R.v2 === 'p80,,|451|3' || R);
  await step('Cuota de Molina: se acaba a los 10 días (SMS) y se renueva en la comisaría del barrio alto, de 10 en 10', ['^Pagar', '^Pagar'], async () => {
    S.protect = true; S.protHasta = S.day; S.flags.molina1 = true; const l0 = LOG.length; newDay(); await idle(); window.R = { p: S.protect, sms: LOG.slice(l0).some(l => /Se acabó lo pagado/.test(l)) };
    S.map = 'comisaria'; buildEnts(); R.ent = ents.filter(e => e.id === 'molina').map(e => e.x + ',' + e.y).join(); S.money = 3000; await run(talkMolina); R.h1 = S.protHasta - S.day; await run(talkMolina);
    R.cub = LOG.slice(l0).some(l => /Estás cubierto hasta el día/.test(l)); S.map = 'home';
  }, () => R.p === false && R.sms && R.ent === '4,2' && R.h1 === 10 && R.cub && S.protect && S.protHasta === S.day + 20 && S.money === 0 || { R, hasta: S.protHasta, day: S.day, money: S.money });
  await step('Imperio: encargo de Don Baltasar (2 kg al almacén de los astilleros, de noche, a 6 €/g); Toño se lleva primero lo más flojo; si no llegas, reputación −10 y 5 días sin encargos', ['Aceptar', 'Entregar', 'Aceptar'], async () => {
    S.ch = 8; S.due = 0; S.encargo = null; S.encVeto = 0; S.rep = 50; S.map = 'bar'; await run(talkBaltasar); window.R = { e: S.encargo && Object.assign({}, S.encargo), d: S.day };
    S.map = 'almacen'; buildEnts(); R.tono = ents.some(e => e.id === 'tono2'); S.buds = {}; addBuds('ria', 1500, 12); addBuds('dragon', 800, 27);
    S.min = 600; await run(talkTonoAlmacen); R.dia = S.encargo && totalBuds(); S.min = 22 * 60; R.m = S.money; R.s = S.sales; R.rep = S.rep; R.heat = S.heat;
    await run(talkTonoAlmacen); R.d1 = { m: S.money - R.m, s: S.sales - R.s, rep: S.rep - R.rep, heat: S.heat - R.heat, ria: S.buds.ria, dragon: S.buds.dragon.g, enc: S.encargo, tono: ents.some(e => e.id === 'tono2') };
    S.map = 'bar'; S.min = 600; await run(talkBaltasar); R.e2 = S.encargo && S.encargo.hasta - S.day; R.rep2 = S.rep;
    S.map = 'almacen'; buildEnts(); for (let k = 0; k < 3; k++) { newDay(); await idle(); } R.veto = S.encVeto - S.day; R.rep3 = S.rep; R.enc3 = S.encargo;
    S.min = 22 * 60; let l0 = LOG.length; await run(talkTonoAlmacen); R.tarde = ents.some(e => e.id === 'tono2') && LOG.slice(l0).some(l => /El plazo se acabó/.test(l));   // vencido con Toño delante
    S.map = 'bar'; S.min = 600; l0 = LOG.length; await run(talkBaltasar); R.fallo = LOG.slice(l0).some(l => /Me fallaste/.test(l)); S.map = 'home';
  }, () => R.e && R.e.g === 2000 && R.e.hasta === R.d + 2 && R.tono && R.dia === 2300 && R.d1.m === 12000 && R.d1.s === 12000 && R.d1.rep === 2 && R.d1.heat === 3 && !R.d1.ria && R.d1.dragon === 300 && R.d1.enc === null && !R.d1.tono
    && R.e2 === 2 && R.rep3 === R.rep2 - 10 && R.enc3 === null && R.veto === 5 && R.tarde && R.fallo || R);
  await step('Mapa ampliado: barrio alto y astilleros con sus puertas; ladrones al azar y patrullas según la zona; clientes de cada zona', [], async () => {
    S.ch = 5; S.protect = false; S.heat = 0; S.min = 600; S.money = 200; S.buds = {}; addBuds('ria', 10, 12);
    const r0 = Math.random, b0 = battle; window.R = { enc: {} }; let n; window.battle = async t => { n = t; };
    R.pat = ['town', 'alto', 'astilleros', 'puerto', 'valdehierro', 'mendialde', 'errotabarri'].map(z => { S.map = z; return [600, 1380].map(mn => { S.min = mn; return nPatrullas(); }).join('/'); }).join(); S.min = 600;
    for (const [z, rs] of [['town', [.0039, .0041]], ['alto', [.0019, .0021]], ['astilleros', [.0079, .0081]]]) {
      S.map = z; const [x, y] = CLIENT_TILES[z][0]; R.enc[z] = rs.map(r => { n = null; Math.random = () => r; P.x = x; P.y = y; S.cool = 0; onStepEnd(); Math.random = r0; return n; }).join(); }
    window.battle = b0; S.cool = 0;
    const W = (m, k) => { const d = MAPS[m].doors[k]; return d && [d.to, d.x, d.y, d.dir].join(); };
    R.puertas = [W('town', '11,0'), W('town', '12,0'), W('alto', '12,29'), W('town', '39,21'), W('astilleros', '0,20'), W('alto', '26,18'), W('astilleros', '18,13'), W('town', '34,8')].join('|');
    R.salidas = ['comisaria', 'almacen', 'txaro'].map(m => { const e = MAPS[m].exits['4,7']; return [e.to, e.x, e.y].join(); }).join('|');
    S.map = 'alto'; R.m0 = S.money; await run(() => objectAction(2, 10)); R.sobre = S.money - R.m0; S.map = 'astilleros'; R.sp = S.items.spray; const it = itemAt(4, 5); if (it) await run(() => pickItem(it)); R.sp = S.items.spray - R.sp;
    S.map = 'town'; await run(() => warp(MAPS.town.doors['11,0'])); R.warp = [S.map, P.x, P.y].join();
    S.ch = 2; spawnClients(); R.c2 = ['town', 'alto', 'astilleros'].map(z => S.clients.filter(c => c.map === z).length).join();
    S.ch = 5; spawnClients(); R.c5 = ['alto', 'astilleros'].map(z => S.clients.filter(c => c.map === z).length).join();
    R.tipos = S.clients.every(c => (c.map === 'alto' ? ['pij', 'tur'] : c.map === 'astilleros' ? ['est', 'cur'] : Object.keys(CTYPES)).includes(c.type) && CLIENT_TILES[c.map].some(t => t[0] === c.x && t[1] === c.y));
    R.ents = ents.filter(e => /^c/.test(e.id) && !/^c\d+_b/.test(e.id)).length; R.entsB = ents.filter(e => /^c\d+_b/.test(e.id)).length; S.map = 'home'; enterMap('home', 5, 5, 'up');
  }, () => R.enc.town === 'thief,' && R.enc.alto === 'thief,' && R.enc.astilleros === 'thief,' && R.pat === '1/2,2/2,1/1,1/1,1/1,0/0,0/0'
    && R.puertas === 'alto,11,28,up|alto,12,28,up|town,12,1,down|astilleros,1,21,right|town,38,20,left|comisaria,4,6,up|almacen,4,6,up|txaro,4,6,up'
    && R.salidas === 'alto,26,19|astilleros,18,14|town,34,9' && R.warp === 'alto,11,28' && R.c2.endsWith(',0,2') && R.c5 === '3,3' && R.tipos && R.ents === 0 && R.entsB === 3 && R.sobre === 80 && R.sp === 2 || R);
  await step('Abuela Txaro, en su casa desde el capítulo 4: 10 g de una índica (solo le valen las de 70 % o más) → 3 semillas de Chitral Kush y 3 bocatas', ['^Hindu Kush'], async () => {
    S.ch = 5; S.flags.txaro = true; S.flags.txaro2 = false; S.map = 'txaro'; buildEnts(); window.R = { ent: ents.filter(e => e.id === 'txaro').map(e => e.x + ',' + e.y).join() };
    S.buds = {}; addBuds('ria', 20, 12); addBuds('hindu', 15, 18); addBuds('thai', 20, 16); R.ch = S.seeds.chitral || 0; R.boc = S.items.bocata; R.rep = S.rep;
    const l0 = LOG.length; await run(talkTxaro); R.menu = LOG.slice(l0).find(l => /\[menú\].*Ahora no/.test(l)) || ''; S.map = 'home';
  }, () => R.ent === '6,3' && S.flags.txaro2 && S.seeds.chitral === R.ch + 3 && S.items.bocata === R.boc + 3 && S.rep === R.rep + 5 && S.buds.hindu.g === 5 && S.buds.ria.g === 20
    && /Hindu Kush/.test(R.menu) && !/Skunk|Thai/.test(R.menu) || R);
  await step('Astilleros: el gramo, un 20 % más caro; 1 de cada 3 ventas, un chico de Darko te sale al paso', ['Justo', 'Justo'], async () => {
    S.ch = 5; S.map = 'astilleros'; S.buds = {}; addBuds('ria', 20, 12); const r0 = Math.random, b0 = battle; window.R = { b: [] }; window.battle = async t => { R.b.push(t); };
    const cl = (id, r) => { const c = { id, map: 'astilleros', x: 5, y: 20, type: 'cur', want: 10, minThc: 0 }; S.clients.push(c); return async () => { Math.random = () => r; await talkClient(c); Math.random = r0; }; };
    R.m = S.money; await run(cl('cx1', .2)); R.m1 = S.money - R.m; R.b1 = R.b.length; await run(cl('cx2', .5)); R.m2 = S.money - R.m - R.m1; window.battle = b0; S.map = 'home';
  }, () => R.m1 === Math.round(precioCalle(12) * CTYPES.cur.mult * 1.2 * 10) && R.m2 === R.m1 && R.b1 === 1 && R.b.join() === 'thief' && ZONAS.astilleros.precio === 1.2 || R);
  await step('Rosin: la prensa de Kiko (250 €, capítulo 3); en la mesa, 25 g de Skunk #1 al 12 % → 5 g de rosin al 36 % en media hora; catadores en 4 zonas; uno paga 10 + 0,6 × THC el gramo', ['Prensa de rosin', 'Salir', 'Prensar rosin', '^Skunk', '^25 g', 'Rebaja'], async () => {
    S.ch = 5; S.money = 1000; S.buds = {}; S.rosin = {}; S.items.prensa = 0; addBuds('ria', 40, 12); await run(shop); window.R = { m: S.money, p: S.items.prensa, min: S.min };
    S.map = 'home'; await run(labAction); R.min = S.min - R.min; R.ros = JSON.parse(JSON.stringify(S.rosin)); R.g = totalBuds();
    S.clientsDay = 0; spawnClients(); R.ext = S.clients.filter(c => c.type === 'ext').map(c => c.map).join();
    S.map = 'town'; const c = { id: 'cx9', map: 'town', x: 5, y: 20, type: 'ext', want: 2, minThc: 0 }; S.clients.push(c); R.m1 = S.money; await run(() => talkClient(c));
    R.m1 = S.money - R.m1; R.r = totalRosin(); R.h = S.heat; S.map = 'home';
  }, () => R.m === 750 && R.p === 1 && R.ros.ria.g === 5 && R.ros.ria.thc === 36 && R.g === 15 && R.min === 30 && R.ext === 'town,town,astilleros,puerto,valdehierro'
    && R.m1 === Math.round(precioRosin(36) * 2 * .85) && R.r === 3 && GLYPH.gota && CTYPES.ext.label === 'CATADOR' || R);
  await step('Rosin a salvo: la caja lo guarda y lo saca (en el hueco de los cogollos); Darko (con 21 g de rosin = 105 g de flor) se lleva la mitad del de fuera y la caja, intacta; la redada que la encuentra, también el suyo; el rosin atrae ladrones (1 g = 5 g de flor)',
    ['Guardar rosin', '^Rosin · Skunk', '^1 g', 'Guardar todo', 'Sacar rosin', '^Rosin · Skunk', '^1 g', 'Cerrar', 'Dormir'], async () => {
    const sv = { ch: S.ch, robo: S.flags.robo, money: S.money, caja: JSON.parse(JSON.stringify(S.caja)), due: S.due, heat: S.heat };
    S.map = 'home'; S.ch = 7; S.flags.robo = false; S.due = 0; S.money = 0; S.heat = 0; S.buds = {}; S.rosin = {}; S.pots = S.pots.map(() => null);
    addRosin('ria', 3, 36); addRosin('hindu', 2, 40); S.caja.money = 0; S.caja.buds = {}; delete S.caja.rosin;
    const l0 = LOG.length; await run(() => objectAction(7, 1));
    window.R = { caja: JSON.parse(JSON.stringify(S.caja.rosin)), fuera: JSON.parse(JSON.stringify(S.rosin)), cr: cajaR(), txt: LOG.slice(l0).filter(l => /Guardas/.test(l)).join('|') };
    addRosin('hindu', 20, 40); R.flor = gramosFlor(); S.min = 23 * 60; const l1 = LOG.length; await run(bedAction);
    R.robo = S.flags.robo; R.f2 = JSON.parse(JSON.stringify(S.rosin)); R.c2 = cajaR(); R.dk = LOG.slice(l1).filter(l => /Se han llevado/.test(l)).join('|');
    const r0 = Math.random; S.protect = false; Math.random = () => .1; const l2 = LOG.length; await run(raidEvent); Math.random = r0;
    R.c3 = 'rosin' in S.caja; R.f3 = totalRosin(); R.rd = LOG.slice(l2).filter(l => /Encuentran la caja/.test(l)).join('|');
    const enc = () => { const b0 = battle, n = []; window.battle = async t => { n.push(t); }; Math.random = () => 0; S.map = 'town';
      const [x, y] = CLIENT_TILES.town[0]; for (let k = 0; k < 20; k++) { P.x = x; P.y = y; S.cool = 0; onStepEnd(); } Math.random = r0; window.battle = b0; S.map = 'home'; S.cool = 0; return n.length; };
    S.money = 0; S.buds = {}; S.rosin = {}; addRosin('ria', 1, 36); R.l1 = enc(); S.rosin = {}; addRosin('ria', .9, 36); R.l0 = enc(); S.rosin = {};
    S.ch = sv.ch; S.flags.robo = sv.robo; S.money = sv.money; S.caja = sv.caja; S.due = sv.due; S.heat = sv.heat;
  }, () => R.caja.ria.g === 2 && R.caja.hindu.g === 2 && R.fuera.ria.g === 1 && !R.fuera.hindu && R.cr === 4 && /Guardas 0 € y 4 g de rosin\./.test(R.txt)
    && R.flor === 105 && R.robo && R.f2.ria.g === .5 && R.f2.hindu.g === 10 && R.c2 === 4 && /Se han llevado 0 € y 10,5 g de rosin\./.test(R.dk)
    && !R.c3 && R.f3 === 0 && /se llevan 4 g de rosin y 0 €/.test(R.rd) && R.l1 === 20 && R.l0 === 0 || R);
  await step('Autobús perdido: en Errotabarri a las 23:50, esperar → a las 7:00 del día siguiente sale el primero; en Mendialde, dormir en casa de ama (sin robo de Darko)',
    ['Esperar', '^Ribera Verde', 'Dormir'], async () => {
    const sv = { ch: S.ch, robo: S.flags.robo, money: S.money, due: S.due }, pa = PARADAS.errotabarri, v = viaje('errotabarri', 'town');
    S.ch = 7; S.flags.robo = false; S.due = 0; S.money = 3000; S.pots = S.pots.map(() => null); enterMap('errotabarri', ...pa.a); S.min = 23 * 60 + 50;
    window.R = { d: S.day }; await run(() => objectAction(pa.x, pa.y)); R.d1 = S.day - R.d; R.min = S.min; R.map = S.map; R.m = S.money; R.v = v;
    enterMap('casa-ama', 1, 3, 'left'); S.min = 22 * 60; R.d2 = S.day; await run(() => objectAction(0, 3)); R.d3 = S.day - R.d2; R.min2 = S.min; R.robo = S.flags.robo; R.hp = S.hp === S.hpMax;
    enterMap('home', 5, 6, 'up'); S.ch = sv.ch; S.flags.robo = sv.robo; S.money = sv.money; S.due = sv.due;
  }, () => R.d1 === 1 && R.min === 7 * 60 + R.v.min && R.map === 'town' && R.m === 3000 - R.v.eur && R.d3 === 1 && R.min2 === 7 * 60 && !R.robo && R.hp || R);
  await step('Patrullas: andan solo por la calle; la sospecha sube si te ven con algo (50 g: 14/s de día, 35 de noche, 5,6 con Molina; nada a la espalda ni sin nada encima); llena → te persiguen → control', ['ENTREGAR'], async () => {
    S.ch = 5; S.protect = false; S.heat = 0; S.min = 600; S.buds = {}; S.rosin = {}; S.clients = []; enterMap('town', 16, 17, 'up');
    const pat = () => ents.filter(e => e.pat), vis = []; window.R = {};
    for (let t = 0; t < 1200; t++) { UPAT(50); if (t % 20 === 0) for (const e of pat()) vis.push(e.x + ',' + e.y); }
    R.calle = vis.every(k => { const [x, y] = k.split(',').map(Number); return CALLE.test(MAPS.town.g[y][x]); }); R.traza = vis.join(' '); R.v0 = SOSP.v; R.sitios = new Set(vis).size;
    const mira = (noche, prot, dir) => { S.min = noche ? 1380 : 600; S.protect = prot; resetSosp(); ponPatrullas(); const e = pat()[0];
      Object.assign(e, { x: 16, y: 14, fx: 16, fy: 14, px: 256, py: 224, dir: dir || 'down', moving: false, espera: 1e9, caza: false });
      pat().slice(1).forEach(o => Object.assign(o, { x: 1, y: 1, fx: 1, fy: 1, moving: false, espera: 1e9 })); Object.assign(P, { x: 16, y: 17, fx: 16, fy: 17, moving: false }); UPAT(1000); return Math.round(SOSP.v * 100) / 100; };
    R.sinNada = mira(false, false); addBuds('ria', 50, 12); R.dia = mira(false, false); R.noche = mira(true, false); R.molina = mira(false, true); R.espalda = mira(false, false, 'up');
    S.buds = {}; S.rosin = { ria: { g: 2, thc: 36 } }; R.rosin = mira(false, false); S.rosin = {}; addBuds('ria', 50, 12);
    mira(false, false); let t = 1000; for (; t < 20000 && isFree(); t += 50) UPAT(50); R.t = t; R.al = SOSP.alarma;
  }, () => R.calle && R.sitios >= 20 && R.v0 === 0 && R.sinNada === 0 && R.dia === 14 && R.noche === 35 && R.molina === 5.6 && R.espalda === 0 && R.rosin === 8.24
    && R.t > 7000 + PAT.alto && R.t < 9000 + PAT.alto && !Object.keys(S.buds).length && SOSP.tregua === PAT.tregua && !R.al && R.traza.split(' ').length === 60 || R);
  await step('Patrullas: con la alarma te pierde a más de 10 casillas y 4 s sin verte (la sospecha se queda en 50); por una puerta, al momento; vender a 5 casillas o menos de un agente, aunque no mire: +60', [], async () => {
    S.ch = 5; S.min = 600; S.buds = {}; addBuds('ria', 50, 12); enterMap('town', 16, 17, 'up'); let e = ents.find(e => e.pat);
    Object.assign(e, { x: 16, y: 14, fx: 16, fy: 14, dir: 'down', moving: false }); alarma(e); Object.assign(P, { x: 37, y: 26, fx: 37, fy: 26 }); window.R = { a: SOSP.alarma };
    let t = 0; for (; t < 30000 && SOSP.alarma; t += 50) UPAT(50); R.t = t; R.v = SOSP.v; R.d = Math.abs(e.x - P.x) + Math.abs(e.y - P.y);
    enterMap('town', 16, 17, 'up'); e = ents.find(e => e.pat); alarma(e); const k = Object.keys(MAPS.town.doors).find(k => MAPS.town.doors[k].to === 'home');
    await run(() => warp(MAPS.town.doors[k])); R.puerta = [S.map, SOSP.alarma, SOSP.v].join();
    enterMap('town', 16, 17, 'up'); e = ents.find(e => e.pat); Object.assign(e, { x: 16, y: 14, fx: 16, fy: 14, dir: 'up', moving: false }); vistoVender(); R.vende = SOSP.v;
    S.map = 'mendialde'; R.pueblo = nPatrullas(); enterMap('home', 5, 5, 'up');
  }, () => R.a === 'pat0' && R.t === 4000 && R.v === 50 && R.d > 10 && R.puerta === 'home,,0' && R.vende === 60 && R.pueblo === 0 || R);
  await step('Patrullas: fuera de la calle (tras una caza por el parque) vuelve a ella y sigue la ronda; si al amanecer se va el agente que te seguía, lo has despistado (sospecha 50)', [], async () => {
    S.ch = 5; S.min = 600; S.buds = {}; S.rosin = {}; enterMap('town', 16, 17, 'up'); let e = ents.find(e => e.pat); window.R = { g: MAPS.town.g[16][2] };
    Object.assign(e, { x: 2, y: 16, fx: 2, fy: 16, px: 32, py: 256, moving: false, espera: 0, caza: false, pasos: 1e9 });
    let t = 0; for (; t < 20000 && !CALLE.test(MAPS.town.g[e.y][e.x]); t += 50) UPAT(50); R.t = t; R.en = e.x + ',' + e.y; const en = R.en;
    for (let i = 0; i < 100; i++) UPAT(50); R.sigue = e.x + ',' + e.y !== en && CALLE.test(MAPS.town.g[e.y][e.x]);
    S.min = 359; resetSosp(); enterMap('town', 16, 17, 'up'); R.n = ents.filter(e => e.pat).length; e = ents.find(e => e.id === 'pat1'); alarma(e);
    S.min = 360; UPAT(50); R.alba = [ents.filter(e => e.pat).length, SOSP.alarma, SOSP.v].join(); S.min = 600; enterMap('home', 5, 5, 'up');
  }, () => !CALLE.test(R.g) && R.t > 0 && R.t <= 3000 && R.sigue && R.n === 2 && R.alba === '1,,50' || R);
  await step('Goteo (1.10): el depósito riega solo lo que baja del 50 %, gasta la mitad de los litros de la maceta por cada 100 % y, vacío, no riega; se rellena desde la carpa', ['Rellenar depósito'], async () => {
    const S0 = S; S = JSON.parse(JSON.stringify(S0)); Object.assign(S, { carpas: [{ t: 'm100', foco: 'sodio400', goteo: true, dep: 10 }], macetas: Array(4).fill('plastico7'), pots: Array(4).fill(null) });
    const i = 1, p = { sid: 'ria', prog: .3, water: 40, health: 100, fert: false, pest: false }, l = MACETAS[S.macetas[i]].l * .5;
    S.pots[i] = p; regarGoteo(p, i); window.R = { w1: p.water, d1: S.carpas[0].dep, e1: Math.round((10 - l * .6) * 100) / 100 };
    S.carpas[0].dep = 1; p.water = 40; regarGoteo(p, i); R.w2 = p.water; R.e2 = 40 + 1 / (l * .6) * 60; R.d2 = S.carpas[0].dep;
    p.water = 45; regarGoteo(p, i); R.w3 = p.water; p.water = 50.1; S.carpas[0].dep = 50; plantsAdvance(10); R.w4 = p.water; R.d4 = S.carpas[0].dep;
    await run(() => carpaAction(0)); R.d5 = S.carpas[0].dep; S = S0;
  }, () => R.w1 === 100 && R.d1 === R.e1 && Math.abs(R.w2 - R.e2) < 1e-9 && R.d2 === 0 && R.w3 === 45 && R.w4 === 100 && R.d4 < 50 && R.d5 === GOTEO_L || R);
  await step('Clima de la sala (1.10): enero, de día con sodio 400 W (+4 °C) y de noche (frío: crecen −18 %); con LED casi no calienta; termohigrómetro, calefactor y deshumidificador del growshop, su factura de noche; moho en floración y su aviso al despertar (julio, de noche)', ['Termohigrómetro', 'Calefactor', 'Deshumidificador', 'Salir'], async () => {
    const S0 = S; S = JSON.parse(JSON.stringify(S0)); Object.assign(S, { ch: 5, money: 1000, sala: {}, day: 10, carpas: [{ t: 'm100', foco: 'sodio400' }], macetas: Array(4).fill('plastico7') });
    S.pots = S.macetas.map(() => ({ sid: 'ria', prog: .8, water: 100, health: 90, fert: false, pest: false }));
    window.R = { mes: MESES[mesDe(S.day)], dia: climaSala(false), noche: climaSala(true) }; R.f = fClima(R.noche); S.min = 23 * 60; R.c0 = factores(0).crec;
    S.carpas[0].foco = 'led480'; R.led = climaSala(false).t; S.carpas[0].foco = 'sodio400';
    await run(shop); R.m = S.money; R.sala = Object.keys(S.sala).join(); R.n2 = climaSala(true); R.d2 = climaSala(false); R.c1 = factores(0).crec; R.fs = facturaSala();
    const p = S.pots[0], f = Object.assign({}, factores(0), { hr: 70, plaga: 0 }); plantStep(p, 1, f); R.moho = p.health;
    S.day = 4; S.sala = {}; R.julio = climaSala(true).hr; const l0 = LOG.length; await run(() => avisoPlaga([])); R.aviso = LOG.slice(l0).filter(l => /^Moho/.test(l)).join('|'); S = S0;
  }, () => R.mes === 'enero' && R.dia.t === 22 && R.dia.hr === 49 && R.noche.t === 15 && R.noche.hr === 58 && Math.abs(R.f - .82) < 1e-9 && R.led === 19.9
    && R.m === 1000 - pr('Termohigrómetro') - pr('Calefactor') - pr('Deshumidificador') && R.sala === 'termo,calef,deshu' && R.n2.t === 20 && R.n2.hr === 55 && R.n2.uso.calef && R.n2.uso.deshu && !R.d2.uso.calef
    && Math.abs(R.c1 / R.c0 - 1 / .82) < 1e-9 && R.fs === Math.round((1500 + 250) * H_24 * (1 - H_DIA) * .5 / 1000 * KWH) && R.moho === 90 && R.julio === 55 + 8 + 5
    && /^Moho en .*\(plaza 1\), .* y .*\(plaza 4\): de noche la sala pasa del 60 % de humedad\./.test(R.aviso) || R);
  await step('Arcón y mochila (1.10): lo que no cabe al cosechar va al arcón; sacar llega hasta el tope; la bolsa de deporte (3 kg); un control no lo ve; la redada se lo lleva; de la caja tampoco sacas más del tope; Darko, la mitad',
    ['Sacar un lote', '^Hindu', '^10 g', 'Guardar todo', 'Cerrar', 'Bolsa de deporte', 'Salir', 'Sacar todo', 'Cerrar'], async () => {
    const S0 = S; S = JSON.parse(JSON.stringify(S0)); Object.assign(S, { ch: 5, map: 'home', buds: {}, rosin: {}, arcon: { buds: {}, rosin: {} }, protect: false, caja: null });
    S.items.bolsa = 0; addBuds('ria', 990, 12); S.pots[0] = { sid: 'hindu', prog: 1, water: 100, health: 100, fert: false, pest: false, f: { id: 9998, t: 1, y: 1 } };
    const g = gramosPlanta(S.pots[0], factores(0)), l0 = LOG.length; await run(() => harvest(0));
    window.R = { g, encima: pesoEncima(), arcon: arconG(), aviso: LOG.slice(l0).filter(l => /arcón/.test(l)).join('|') };
    useBuds('ria', 500); await run(arconAction); R.a2 = arconG(); R.b2 = totalBuds(); S.money = 100; await run(shop); R.cap = capMochila(); R.bolsa = S.items.bolsa;
    addBuds('ria', 20, 12); confiscate(false); R.control = arconG(); addBuds('ria', 5, 12);
    const l1 = LOG.length; await run(raidEvent); R.redada = LOG.slice(l1).filter(l => /Se llevan/.test(l)).join('|'); R.a3 = arconG();
    S.caja = { money: 0, buds: { ria: { g: 1500, thc: 12 } }, nivel: 1 }; S.buds = {}; addBuds('ria', 2000, 12); const l3 = LOG.length; await run(cajaAction);
    R.sacar = [totalBuds(), cajaG(), LOG.slice(l3).some(l => /No te cabe todo encima/.test(l))].join();
    S.arcon = { buds: { ria: { g: 101, thc: 12 } }, rosin: { ria: { g: 3, thc: 36 } } }; S.money = 0; S.buds = {}; S.rosin = {};
    const l2 = LOG.length; await run(roboDarko); R.darko = LOG.slice(l2).filter(l => /Se han llevado/.test(l)).join('|'); R.a4 = JSON.stringify(S.arcon); S = S0;
  }, () => R.g > 10 && R.encima === 1000 && R.arcon === R.g - 10 && new RegExp(`en la mochila: ${R.g - 10} g van al arcón`).test(R.aviso) && R.a2 === 490 + R.g && R.b2 === 0
    && R.cap === 3000 && R.bolsa === 1 && R.control === R.a2 && new RegExp(`y ${Math.floor(5 + R.a2)} g\\.`).test(R.redada) && R.a3 === 0
    && R.sacar === '3000,500,true' && /Se han llevado 0 €, 50 g y 1,5 g de rosin\./.test(R.darko) && R.a4 === '{"buds":{"ria":{"g":51,"thc":12}},"rosin":{"ria":{"g":1.5,"thc":36}}}' || R);
  await step('Móvil (1.10): START → MÓVIL; pedir a Kiko (+15 %, llega mañana) y su SMS en Mensajes; llamar a Kiko; quien te compra te da su número y, llamado, viene a la calle (20 min, +1 de calor, una vez al día)',
    ['MÓVIL', 'Pedir a Kiko', '^Abono', 'Salir', 'Colgar', 'SALIR', 'MÓVIL', 'Mensajes', '<B>', 'Llamar', '^Kiko', 'Colgar', 'SALIR', '^Skunk', 'Rebaja',
      'MÓVIL', 'Llamar', '^(?!Kiko|Nada)', '^Skunk', 'Rebaja', 'SALIR', 'MÓVIL', 'Llamar', '^(?!Kiko|Nada)', 'Colgar', 'SALIR'], async () => {
    const S0 = S; S = JSON.parse(JSON.stringify(S0));
    Object.assign(S, { map: 'home', money: 100, sms: [], envio: [], fijos: [], protect: false, protHasta: 0, encargo: null, heat: 0, due: 0, buds: {}, rosin: {}, min: 600 });
    S.flags.kiko1 = true; S.flags.tono = 0; S.flags.inaki = false; const f0 = S.items.fert;
    await run(startMenu); window.R = { m: S.money, envio: S.envio.join() }; advanceTime(24 * 60); await idle();
    R.fert = S.items.fert - f0; R.sms = S.sms.find(m => m.n === 'KIKO') || null; R.envio2 = S.envio.length;
    const l0 = LOG.length; await run(startMenu); R.log = LOG.slice(l0);
    enterMap('town', 16, 17, 'up'); S.min = 600; addBuds('ria', 50, 12); const c = { id: 'cz1', map: 'town', x: 5, y: 20, type: 'cur', want: 2, minThc: 0 }; S.clients.push(c);
    await run(() => talkClient(c)); R.fijos = JSON.stringify(S.fijos); R.nom = nombreFijo('cz1');
    R.h = S.heat; R.min = S.min; R.mon = S.money; const l1 = LOG.length; await run(startMenu); R.t = S.min - R.min; R.dh = S.heat - R.h; R.cobra = S.money - R.mon; R.dia = S.fijos[0].dia === S.day;
    R.log2 = LOG.slice(l1); const l2 = LOG.length; await run(startMenu); R.otra = LOG.slice(l2).join('|'); S = S0; enterMap('home', 5, 5, 'up');
  }, () => R.m === 100 - Math.round(pr('Abono') * ENVIO) && R.envio === 'Abono de floración 1 L' && R.fert === 4 && R.envio2 === 0 && R.sms && R.sms.t === 'Te he dejado el paquete en casa: Abono de floración 1 L.'
    && R.log.some(l => /\[menú\] KIKO/.test(l)) && R.log.some(l => /^KIKO: /.test(l)) && R.fijos === JSON.stringify([{ id: 'cz1', n: R.nom, t: 'cur', dia: 0 }])
    && R.t === LLAMADA_MIN && R.dh >= 1 + 3 && R.cobra > 0 && R.dia && R.log2.some(l => l === `  [menú] Kiko | ${R.nom} | Nada  → ${R.nom}`) && R.log2.some(l => l.startsWith(R.nom.toUpperCase() + ': Busco')) && new RegExp(`${R.nom} ya ha venido hoy`).test(R.otra) || R);
  await step('Partidas viejas: capítulo 3 sin plazo → 3.000 € en 7 días desde hoy; protección sin fecha → 10 días; los campos nuevos, con su valor (también arcón, sala, agenda, mensajes, pedidos y bolsa); con Toño ya visto, sale en el móvil', [], async () => {
    const S0 = S; S = JSON.parse(JSON.stringify(S0)); Object.assign(S, { ch: 3, due: 0, deadline: 0, protect: true }); S.flags.metB = false; delete S.flags.tono;
    for (const k of ['caja', 'rec', 'vencidos', 'protHasta', 'encargo', 'encVeto', 'arcon', 'sala', 'fijos', 'sms', 'envio']) delete S[k]; delete S.items.bolsa; migrate();
    window.R = { due: S.due, dias: S.deadline - S.day, tono: S.flags.tono === S.day, hasta: S.protHasta - S.day, campos: JSON.stringify([S.caja, S.rec, S.vencidos, S.encargo, S.encVeto]),
      nuevos: JSON.stringify([S.arcon, S.sala, S.fijos, S.sms, S.envio, S.items.bolsa]) };
    S = JSON.parse(JSON.stringify(S0)); S.flags.metB = true; delete S.flags.tono; migrate(); R.tono2 = S.flags.tono === S.day; S = S0;
  }, () => R.due === 3000 && R.dias === 7 && R.tono && R.hasta === 10 && R.campos === '[null,{},0,null,0]' && R.nuevos === '[{"buds":{},"rosin":{}},{},[],[],[],0]' && R.tono2 || R);
  await step('Guardar y cargar la partida', [], async () => { save(); },
    () => { const sv = loadSave(); return sv && sv.ch === S.ch && sv.money === S.money && JSON.stringify(sv.disc) === JSON.stringify(S.disc) || 'no coincide'; });

  // ---------- resumen ----------
  fs.mkdirSync(OUT, { recursive: true });
  // con el oráculo (reloj parado) la transcripción va aparte, para no pisar la de npm test
  fs.writeFileSync(path.join(OUT, ORAC ? 'transcripcion-oraculo.txt' : 'transcripcion.txt'), (await page.evaluate(() => LOG.join('\n'))) + '\n');
  const failed = results.filter(r => !r.ok).length;
  if (ORAC && !failed && !errors.length) { fs.mkdirSync(path.dirname(ORAC), { recursive: true }); fs.writeFileSync(ORAC, JSON.stringify({ semilla: SEMILLA, pasos: orac })); }
  else if (ORAC) console.log('oráculo sin escribir: hay pasos que fallan o errores de JavaScript');
  console.log(`\n${results.length - failed}/${results.length} pasos OK · errores de JavaScript: ${errors.length}`);
  errors.forEach(e => console.log('  ' + e));
  await browser.close();
  process.exit(failed || errors.length ? 1 : 0);
})();
