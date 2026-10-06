#!/usr/bin/env node
/*
  Ribera Verde — regenera las capturas de screenshots/ a partir de index.html
  Uso:  node tools/build.js && node tools/capturas.js
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const OUT = process.env.RV_SALIDA ? path.resolve(process.env.RV_SALIDA) : path.join(ROOT, 'screenshots');

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage({ viewport: { width: 730, height: 496 }, deviceScaleFactor: 1 });   // pantalla de 240×160 a ×3 exacto (720×480)
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('file://' + (process.env.RV_HTML ? path.resolve(process.env.RV_HTML) : path.join(ROOT, 'index.html')));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
  await page.evaluate(() => document.fonts.ready);
  const screen = page.locator('#screen');
  const shot = async (name, full) => { await page.waitForTimeout(350); await (full ? page : screen).screenshot({ path: path.join(OUT, name) }); console.log('  ' + name); };
  const z = async (n = 1) => { for (let i = 0; i < n; i++) { await page.keyboard.press('z'); await page.waitForTimeout(90); } };
  const untilMenu = async () => { for (let i = 0; i < 60; i++) { if (await page.evaluate(() => !document.getElementById('menu').hidden)) return; await z(); } };
  const finishBattle = async () => { for (let i = 0; i < 900; i++) { if (await page.evaluate(() => mode === 'world' && lock === 0 && handlers.length === 0)) return; await z(); } throw new Error('el juego no queda libre: ' + await page.evaluate(() => JSON.stringify({ mode, lock, h: handlers.length, pend: pending.length, txt: document.getElementById('dlgText').textContent.slice(0, 60), menu: document.getElementById('menu').hidden }))); };
  const reset = () => page.evaluate(() => { while (handlers.length) handlers.pop(); dlg.hidden = true; menuEl.hidden = true; document.getElementById('toast').hidden = true; lock = 0; });

  await page.waitForTimeout(900);
  await shot('01-titulo.png', true);

  // intro
  await page.evaluate(() => { S = newState(); document.getElementById('title').hidden = true; mode = 'intro'; say('Me llamo Kiko. Llevo treinta años con el growshop de la esquina.', '???'); });
  await page.waitForTimeout(1600); await shot('02-intro.png'); await reset();

  // partida de muestra
  await page.evaluate(() => {
    S = newState(); S.ch = 4; S.name = 'EDDIE'; S.flags = { letter: 1, kiko1: 1, harvest1: 1, darko1: 1, metB: 1, lab: 1 }; S.money = 1840; S.heat = 35; S.rep = 30;
    S.carpas = [{ t: 'p60', foco: 'led200' }, { t: 'm100', foco: 'sodio400' }]; S.macetas = ['tela11', 'tela11', 'tela25', 'plastico18', 'tela25', 'tela11'];
    ['ria', 'limon', 'txoko', 'niebla', 'mango', 'purpura', 'rif', 'hindu', 'citrus', 'bluetx', 'kushrif'].forEach(k => addSeeds(k, 2));
    addBuds('citrus', 46, 18.4); addBuds('bluetx', 22, 20.1);
    S.pots = [
      { sid: 'citrus', prog: 1, water: 80, health: 100, fert: true, pest: false },
      { sid: 'bluetx', prog: .8, water: 70, health: 95, fert: true, pest: false },
      { sid: 'kushrif', prog: .5, water: 60, health: 90, fert: false, pest: false },
      { sid: 'purpura', prog: .25, water: 90, health: 100, fert: false, pest: false },
      { sid: 'mango', prog: .7, water: 40, health: 70, fert: false, pest: true },
      { sid: 'niebla', prog: .05, water: 100, health: 100, fert: false, pest: false }];
    S.min = 11 * 60; mode = 'world'; enterMap('home', 13, 5, 'up'); spawnClients(); updateHUD();   // dentro de la carpa de 100; el armario, cerrado
    document.getElementById('toast').hidden = true; pending.length = 0; queued.clear();   // el cambio de capítulo, después de la foto
  });
  await shot('03-piso-armario.png');
  await page.evaluate(() => { run(checkStory); }); await finishBattle();   // el cambio de capítulo, entero antes de seguir (si no, reset() lo deja con lock negativo)

  await page.evaluate(() => { enterMap('town', 17, 9, 'down'); S.min = 12 * 60; ents = ents.filter(e => !e.def.client); });
  await shot('04-barrio-dia.png');

  await page.evaluate(() => {
    S.min = 22 * 60 + 30; enterMap('town', 20, 16, 'down');
    const c = S.clients[0]; c.x = 20; c.y = 17; buildEnts(); const e = ents.find(e => e.id === c.id); Object.assign(e, { x: 20, y: 17, px: 320, py: 272, fx: 20, fy: 17, wander: 0 });
  });
  await shot('05-plaza-noche.png');

  await page.evaluate(() => { ask('6 g de Lemon Skunk. ¿Cuánto le pides?', ['Rebaja · 51 €', 'Justo · 60 €', 'Caro · 78 €', 'Cancelar']); });
  await untilMenu(); await shot('06-venta.png'); await reset();

  await page.evaluate(() => { S.min = 23 * 60; run(() => battle('thief')); });
  await page.waitForTimeout(1800); await untilMenu(); await shot('07-combate-ladron.png');
  await page.keyboard.press('ArrowDown'); await page.keyboard.press('ArrowDown'); await page.keyboard.press('ArrowRight'); await page.waitForTimeout(100);
  await z(); await finishBattle();

  await page.evaluate(() => { S.min = 13 * 60; S.heat = 55; run(() => battle('police')); });
  await page.waitForTimeout(1800); await untilMenu(); await shot('08-combate-policia.png');
  await page.keyboard.press('ArrowDown'); await page.keyboard.press('ArrowRight'); await page.waitForTimeout(100);
  await z(); await finishBattle();

  await page.evaluate(() => { enterMap('home', 5, 3, 'up'); genoteca(); });
  await page.waitForTimeout(200); for (let i = 0; i < 10; i++) { await page.keyboard.press('ArrowDown'); await page.waitForTimeout(40); }
  await shot('09-genoteca.png'); await reset();

  await page.evaluate(() => { say('Nueva variedad: Critical Kush.'); discover('reina'); });
  await page.waitForTimeout(1200); await shot('10-cruce.png'); await reset();

  await page.evaluate(() => { enterMap('shop', 4, 4, 'up'); shop(); });
  await page.waitForTimeout(200); for (let i = 0; i < 2; i++) { await page.keyboard.press('ArrowDown'); await page.waitForTimeout(40); }
  await shot('11-growshop.png'); await reset();

  await page.evaluate(() => { S.ch = 5; S.due = 2000; S.deadline = S.day + 6; enterMap('bar', 7, 6, 'up'); say('Me debes 2000 € para el día 7. Te quedan 6 días.', 'DON BALTASAR'); });
  await page.waitForTimeout(1500); await shot('12-bar-baltasar.png'); await reset();

  await page.setViewportSize({ width: 844, height: 390 });   // móvil en horizontal: el mundo a lo ancho y los mandos flotando
  await page.evaluate(() => { enterMap('town', 18, 18, 'left'); S.min = 18 * 60 + 30; });
  await shot('13-movil.png', true);

  await browser.close();
  if (errors.length) { console.log('Errores:', errors); process.exit(1); }
})();
