/**
 * Las pantallas de menú, fotografiadas con el navegador de verdad.
 *
 *   node herramientas/html/menus.js
 *
 * El HUD se dibuja en el lienzo y lo saca `captura.js` leyéndolo del arnés. Los menús no:
 * son DOM con su CSS, y el arnés —que es un remedo del DOM— no los pinta. Para mirarlos
 * hace falta un navegador. De ahí esto, hermano de `mando.js`.
 *
 * Qué saca, y por qué esas dos: la lista de curros es donde se ven doce iconos juntos y a
 * su tamaño de menú, y la pausa es donde se ve el marco de la pantalla entero.
 */
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');

const HTML = path.join(__dirname, '..', '..', 'referencia', 'bilbo-city.html');
const CAPT = path.join(__dirname, '..', '..', 'referencia', 'capturas');
// El mismo que usa mando.js: el contenedor trae Chromium, con otra versión que la que
// pide este Playwright, así que se le señala el binario en vez de bajar otro.
const PUESTO = '/opt/pw-browsers/chromium-1194/chrome-linux/chrome';

(async () => {
  const nav = await chromium.launch(fs.existsSync(PUESTO) ? { executablePath: PUESTO } : {});
  // Al doble de densidad: el menú es DOM con texto, y a 1x la tipografía sale sucia.
  const pag = await nav.newPage({ viewport: { width: 880, height: 420 }, deviceScaleFactor: 2 });
  await pag.goto('file://' + HTML);
  await pag.waitForFunction(() => document.body.dataset.listo === '1', null, { timeout: 90000 });
  await pag.waitForSelector('#btnNuevo', { timeout: 30000 });
  await pag.click('#btnNuevo');
  await pag.waitForTimeout(1500);

  // El móvil, en la pestaña de curros: doce iconos seguidos y a tamaño de menú.
  // Se abren con las funciones del juego, no poniéndoles el display a mano: son ellas
  // las que rellenan el cuerpo, y una pantalla abierta a pelo sale vacía.
  await pag.click('#bSel');
  await pag.click('#tel .tab[data-t="trab"]');
  await pag.waitForTimeout(400);
  fs.writeFileSync(path.join(CAPT, 'ui-curros.png'), await pag.screenshot());

  await pag.click('#telCerrar');
  await pag.click('#bOpt');
  await pag.waitForTimeout(400);
  fs.writeFileSync(path.join(CAPT, 'ui-pausa.png'), await pag.screenshot());

  await nav.close();
  console.log('->', path.join(CAPT, 'ui-curros.png'));
  console.log('->', path.join(CAPT, 'ui-pausa.png'));
})();
