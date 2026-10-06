#!/usr/bin/env node
/*
  Ribera Verde — prueba automática de la historia completa (capítulos 1 → 8)
  Abre index.html en Chromium sin ventana, instala un "piloto automático" que pulsa A
  en cada diálogo y elige opciones de menú por texto, y comprueba el estado tras cada paso.

  Requisitos (una vez):  npm install   y   npx playwright install chromium
  Uso:                   node tools/test-historia.js
  Resultado:             lista de pasos OK/FALLO + tools/salida/transcripcion.txt con todos los diálogos
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const OUT = process.env.RV_SALIDA ? path.resolve(process.env.RV_SALIDA) : path.join(__dirname, 'salida');

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage({ viewport: { width: 1000, height: 700 } });
  const errors = [];
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push('console: ' + m.text()); });
  await page.goto('file://' + (process.env.RV_HTML ? path.resolve(process.env.RV_HTML) : path.join(ROOT, 'index.html')));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');

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
  });

  const results = [];
  async function step(name, wantList, fn, check) {
    await page.evaluate(w => want(w), wantList);
    await LOGMARK(name);
    let ok = false, detail = '';
    try {
      await page.evaluate(fn);
      await page.evaluate(() => idle());
      const r = await page.evaluate(check);
      ok = r === true; detail = r === true ? '' : JSON.stringify(r);
    } catch (e) { detail = e.message.split('\n')[0]; }
    results.push({ name, ok, detail });
    console.log(`${ok ? 'OK   ' : 'FALLO'}  ${name}${detail ? '  → ' + detail : ''}`);
  }
  function LOGMARK(name) { return page.evaluate(n => LOG.push('\n=== ' + n + ' ==='), name); }

  // ---------- capítulo 1 ----------
  await step('Nueva partida e intro', [], async () => { await run(newGame); },
    () => S.ch === 1 && S.map === 'home' && S.name === 'EDDIE' || { ch: S.ch, map: S.map, name: S.name });
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
  await step('Vender a un cliente (rebaja) → 300 € → capítulo 3', ['Skunk', 'Rebaja'], async () => {
    S.sales = 290; await run(() => talkClient(S.clients[0]));
  }, () => S.ch === 3 && S.sales >= 300 && S.heat > 0 || { ch: S.ch, sales: S.sales });
  await step('Hablar con Josune (pintxo)', ['Pintxo'], async () => { S.hp = 10; await run(talkJosune); },
    () => S.hp === 22 || { hp: S.hp });
  await step('Abuela Txaro: dar 5 g → Hindu Kush', ['Skunk'], async () => { await run(talkTxaro); },
    () => S.flags.txaro && S.seeds.hindu === 2 || { seeds: S.seeds });
  await step('Iñaki: vender 10 g → Malawi Gold', ['Skunk', 'Hecho'], async () => { addBuds('ria', 10, 12); await run(talkInaki); },
    () => S.flags.inaki && S.seeds.malawi === 2 || { seeds: S.seeds });
  await step('Arbusto escondido → Acapulco Gold', [], async () => { S.map = 'town'; await run(() => objectAction(2, 26)); S.map = 'home'; },
    () => S.seeds.acapulco === 2 || { seeds: S.seeds });

  // ---------- capítulo 3 ----------
  await step('Don Baltasar explica la deuda', [], async () => { await run(talkBaltasar); },
    () => S.flags.metB && S.due === 1000 && S.deadline === S.day + 7 || { due: S.due, deadline: S.deadline, day: S.day });
  await step('Plazo vencido → Toño cobra intereses', [], async () => { S.deadline = S.day; advanceTime(24 * 60); await idle(); },
    () => S.due === 1300 && S.debt === 5300 && S.deadline === S.day + 5 || { due: S.due, debt: S.debt });
  await step('Pagar 1.300 € → capítulo 4', ['^Pagar'], async () => { S.money = 6000; await run(talkBaltasar); },
    () => S.ch === 4 && S.debt === 4000 && S.due === 0 || { ch: S.ch, debt: S.debt });

  // ---------- capítulo 4 ----------
  await step('Kiko instala la mesa de genética', [], async () => { await run(talkKiko); },
    () => S.flags.lab && S.seeds.rif === 3 || { lab: S.flags.lab, seeds: S.seeds });
  await step('Comprar en el growshop (abono)', ['Fertilizante', 'Salir'], async () => { await run(shop); },
    () => S.items.fert === 2 || { items: S.items });
  await step('Growshop: carpa de 100, foco LED 200 W colgado en el armario y una maceta de tela', ['Carpa 100', 'Foco LED 200', '^Armario', 'Maceta de tela 11', 'Salir'], async () => {
    S.money = 2000; await run(shop);
  }, () => S.carpas[1]?.t === 'm100' && S.carpas[0].foco === 'led200' && S.items.f_cfl === 1 && S.items.m_tela11 === 1 && S.pots.length === 6 && S.macetas.length === 6 && S.money === 2000 - 450 - 260 - 20
    || { carpas: S.carpas, items: S.items, pots: S.pots.length, money: S.money });
  await step('Plaza vacía: cambiar la maceta de 7 L por la de tela', ['Cambiar maceta', 'Tela 11'], async () => { await run(() => potAction(2)); },
    () => S.macetas[2] === 'tela11' && S.items.m_tela11 === 0 && S.items.m_plastico7 === 1 || { macetas: S.macetas, items: S.items });
  await step('Carpa: cambiar el foco desde la pared (sodio 400 W)', ['Cambiar foco', 'Sodio 400'], async () => { S.items.f_sodio400 = 1; await run(() => carpaAction(1)); },
    () => S.carpas[1].foco === 'sodio400' && S.items.f_cfl === 2 && S.items.f_sodio400 === 0 || { carpas: S.carpas, items: S.items });
  await step('Factura de la luz: solo paga la carpa con plantas', [], async () => {
    S.money = 100; S.pots[2] = { sid: 'ria', prog: .2, water: 100, health: 100, fert: false, pest: false }; advanceTime(24 * 60); await idle(); S.pots[2] = null;
  }, () => S.luz.e === 8 && S.money === 92 || { luz: S.luz, money: S.money });
  await step('Vista de carpa: A delante del armario, ▶ plaza 2, A → Regar, B sale', ['Regar'], async () => {
    const hasta = f => new Promise(r => { const i = setInterval(() => { if (f()) { clearInterval(i); r(); } }, 20); });
    S.pots[1] = { sid: 'ria', prog: .5, water: 20, health: 100, fert: false, pest: false };
    const t = MAPS.home.carpas.find(t => t.ci === 0); enterMap('home', t.x0, t.y + 1, 'up');
    press('A'); await hasta(() => mode === 'carpa' && handlers.length === 1);
    window.R = { sel0: VC.sel, x0: vcGeo(0).pl.map(q => q.x) }; press('right'); R.sel = VC.sel; R.info = document.getElementById('vcInfo').textContent;
    press('A'); await hasta(() => VC && !VC.ocupado && handlers.length === 1); R.agua = S.pots[1].water;
    press('B'); await hasta(() => mode === 'world' && isFree());
  }, () => R.sel0 === 0 && R.sel === 1 && /Plaza 2/.test(R.info) && R.agua === 100 && !VC && document.getElementById('vcInfo').hidden || R);
  await step('Cruce de receta: Afghani × Skunk #1 → Critical Mass', ['^Afghani', '^Skunk #1', 'Cruzar'], async () => {
    addSeeds('ria', 2); addSeeds('txoko', 2); await run(labAction);
  }, () => S.seeds.kushrif === 2 && S.disc.kushrif && S.gen.kushrif === 1 || { seeds: S.seeds, gen: S.gen });
  await step('Cruce libre: Skunk #1 × Hindu Kush → híbrido propio → capítulo 5', ['^Skunk #1', '^Hindu Kush', 'Cruzar'], async () => {
    await run(labAction);
  }, () => Object.keys(S.custom).length === 1 && discCount() >= 8 && S.ch === 5 && S.due === 2000 || { custom: S.custom, disc: discCount(), ch: S.ch });

  await step('Estabilizar Critical Mass: F1 → F2 → F3 → estable', ['^Critical Mass', 'estabilizar', 'Estabilizar', '^Critical Mass', 'estabilizar', 'Estabilizar', '^Critical Mass', 'estabilizar', 'Estabilizar'], async () => {
    window.R = []; for (let k = 0; k < 3; k++) { if (k) addSeeds('kushrif', 1); await run(labAction); R.push(genDe('kushrif') + ':' + S.seeds.kushrif); }
  }, () => R.join() === '2:1,3:1,4:1' && !('kushrif' in S.gen) || { R, gen: S.gen, seeds: S.seeds.kushrif });
  await step('Banco de semillas del PC: Punto Rojo y Thai, llegan al día siguiente', ['Banco de semillas', '^Punto Rojo', '^Thai', 'Salir'], async () => {
    S.money = 500; await run(pcAction); window.R = { pedido: S.pedido.slice(), money: S.money, antes: !!S.seeds.thai }; newDay();
  }, () => R.pedido.join() === 'punto,thai' && R.money === 385 && !R.antes && S.seeds.punto === 3 && S.seeds.thai === 3 && S.disc.thai && !S.pedido.length || { R, seeds: S.seeds, pedido: S.pedido });
  await step('Cruce de landraces: Punto Rojo × Thai → Haze (F1, cosechas desiguales)', ['^Punto Rojo', '^Thai', 'Cruzar'], async () => {
    await run(labAction); S.pots[0] = { sid: 'haze', prog: 1, water: 80, health: 100, fert: false, pest: false };
    window.R = []; for (let k = 0; k < 12; k++) { S.pots[0] = { sid: 'haze', prog: 1, water: 80, health: 100, fert: false, pest: false }; const b = S.buds.haze ? S.buds.haze.g : 0; await run(() => harvest(0)); R.push(S.buds.haze.g - b); }
  }, () => S.disc.haze && S.gen.haze === 1 && new Set(R).size > 2 && R.every(g => g >= Math.floor(32 * factores(0).rend * .8) && g <= Math.ceil(32 * factores(0).rend * 1.1)) && /F1: línea inestable/.test(strainLine('haze')) || { R, gen: S.gen.haze, rend: factores(0).rend });

  // ---------- capítulo 5 ----------
  await step('Sargento Molina: pagar protección', ['Pagar 500'], async () => { S.money = 600; await run(talkMolina); },
    () => S.protect === true && S.money === 100 || { protect: S.protect, money: S.money });
  await step('Calor 95 con protección → Molina para la redada', ['Skunk'], async () => {
    addSeeds('ria', 1); await run(() => potAction(0)); S.heat = 95; advanceTime(24 * 60); await idle();
  }, () => S.heat === 50 && S.pots[0] !== null || { heat: S.heat, pot: S.pots[0] });
  await step('Calor 95 sin protección → redada', [], async () => {
    S.protect = false; S.heat = 95; addBuds('ria', 10, 12); advanceTime(24 * 60); await idle();
  }, () => S.pots.every(p => p === null) && Object.keys(S.buds).length === 0 && S.heat === 30 || { pots: S.pots, buds: S.buds, heat: S.heat });
  await step('Pagar 2.000 € → capítulo 6', ['^Pagar'], async () => { S.protect = true; S.money = 2500; await run(talkBaltasar); },
    () => S.ch === 6 && S.debt === 2000 || { ch: S.ch, debt: S.debt });

  // ---------- capítulo 6 ----------
  await step('Darko presume', [], async () => { await run(talkDarko); }, () => S.ch === 6);
  await step('Copa: presentar Skunk #1 (12%) → pierde', ['Skunk'], async () => { addBuds('ria', 25, 12); await run(talkJurado); },
    () => S.ch === 6 && Math.round(S.buds.ria.g) === 5 || { ch: S.ch, buds: S.buds });
  await step('Copa: presentar Fire OG (27,2%) → gana → capítulo 7', ['Fire OG'], async () => {
    S.money = 0; addBuds('dragon', 25, 27.2); await run(talkJurado);
  }, () => S.ch === 7 && S.money === 2500 && S.due === 2000 && S.flags.copa || { ch: S.ch, money: S.money, due: S.due });

  // ---------- capítulo 7 → final ----------
  await step('Pagar los últimos 2.000 € → FIN (capítulo 8)', ['^Pagar'], async () => { await run(talkBaltasar); },
    () => S.ch === 8 && S.debt === 0 && document.getElementById('endcard').hidden || { ch: S.ch, debt: S.debt });

  // ---------- sistemas sueltos ----------
  await step('Combate ladrón: ganar con spray', Array(12).fill(['MOCHILA', 'SPRAY']).flat(), async () => {
    S.hpMax = 60; S.hp = 60; S.items.spray = 12; S.money = 100; await run(() => battle('thief')); WANT = [];
  }, () => S.money > 100 && S.hpMax === 60 && mode === 'world' || { money: S.money, hpMax: S.hpMax, mode });
  await step('Combate ladrón: desmayo → despiertas en casa', [], async () => {
    S.hpMax = 30; S.hp = 1; S.money = 1000; S.buds = {}; addBuds('ria', 20, 12); S.map = 'town'; await run(() => battle('thief'));
  }, () => S.map === 'home' && S.hp === S.hpMax && S.money === 700 && S.buds.ria.g === 10 || { map: S.map, hp: S.hp, money: S.money, buds: S.buds });
  await step('Ladrón vencido sube la VIDA máxima', ['LUCHAR', 'PATADA'].concat(Array(20).fill(['MOCHILA', 'SPRAY']).flat()), async () => {
    S.hpMax = 40; S.hp = 40; S.items.spray = 20; await run(() => battle('thief')); WANT = [];
  }, () => S.hpMax === 42 || { hpMax: S.hpMax });
  await step('Policía: soborno con protección', ['SOBORNAR', '^Sí'], async () => {
    S.protect = true; S.heat = 40; S.money = 1000; addBuds('ria', 10, 12); await run(() => battle('police'));
  }, () => S.money < 1000 && S.heat === 30 && !!S.buds.ria || { money: S.money, heat: S.heat });
  await step('Agente en la plaza: entregar la mercancía', ['ENTREGAR'], async () => {
    S.protect = false; addBuds('ria', 5, 12); await run(talkCop);
  }, () => Object.keys(S.buds).length === 0 || { buds: S.buds });
  await step('Menú START: Genoteca, Mochila, Plantas, Objetivo', ['GENOTECA', '<B>', 'MOCHILA', '<B>', 'PLANTAS', '<B>', 'OBJETIVO', 'SALIR'],
    async () => { await run(startMenu); }, () => handlers.length === 0);
  await step('Cama: siesta de 3 horas', ['Siesta'], async () => { S.min = 600; S.hp = 5; await run(bedAction); },
    () => (S.min === 780 || S.min === 781) && S.hp === S.hpMax || { min: S.min, hp: S.hp });   // 780 = 600 + 180; entre la siesta y la comprobación puede pasar un minuto de reloj real
  await step('8.ª variedad desde un arbusto → capítulo 5 sin más acciones', [], async () => {
    S.ch = 4; S.flags.lab = true; S.due = 0; S.disc = { ria: true, limon: true, txoko: true, niebla: true, mango: true, purpura: true, rif: true };
    S.custom = {}; delete S.taken.h_acap; S.map = 'town'; await run(() => objectAction(2, 26)); S.map = 'home'; await idle();
  }, () => S.ch === 5 && S.due === 2000 || { ch: S.ch, disc: discCount() });
  await step('Guardar y cargar la partida', [], async () => { save(); },
    () => { const sv = loadSave(); return sv && sv.ch === S.ch && sv.money === S.money && JSON.stringify(sv.disc) === JSON.stringify(S.disc) || 'no coincide'; });

  // ---------- resumen ----------
  fs.mkdirSync(OUT, { recursive: true });
  fs.writeFileSync(path.join(OUT, 'transcripcion.txt'), (await page.evaluate(() => LOG.join('\n'))) + '\n');
  const failed = results.filter(r => !r.ok).length;
  console.log(`\n${results.length - failed}/${results.length} pasos OK · errores de JavaScript: ${errors.length}`);
  errors.forEach(e => console.log('  ' + e));
  await browser.close();
  process.exit(failed || errors.length ? 1 : 0);
})();
