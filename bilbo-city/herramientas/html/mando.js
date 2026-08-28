/**
 * Mide el mando en pantallas de móvil de verdad, con el navegador.
 *
 *   node herramientas/html/mando.js [salida.png]
 *
 * El reparto de la pantalla —cuánto marco a los lados y cuánto joystick— no se decide de
 * memoria: depende de cuántos milímetros de cristal le quedan al pulgar en un móvil
 * concreto. Esto abre el juego a los tamaños de unos cuantos móviles apaisados, mide en
 * píxeles CSS lo que ocupa cada cosa, lo pasa a milímetros y saca una foto de cada uno.
 *
 * La regla de bolsillo: un pulgar adulto pide unos 20 mm de zona de contacto y unos 30 mm
 * de recorrido cómodo. Por debajo de 16 mm el joystick es más pequeño que el dedo.
 *
 * Y no solo lo imprime: **falla**. Durante un tiempo esto medía y salía con 0 pasara lo
 * que pasara, así que el joystick de 14,5 mm que obligó a rehacer el mando entero se
 * habría podido colar otra vez sin que nadie lo viera. No está dentro de `verificar.sh`
 * porque necesita navegador; se ejecuta a mano al tocar el mando o la portada.
 */
// No se usa el arnés: aquí manda el navegador de verdad, no el DOM simulado.
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');

const HTML = path.join(__dirname, '..', '..', 'referencia', 'bilbo-city.html');

// Ancho y alto en píxeles CSS con el móvil apaisado, y ancho real del cristal en mm.
const MOVILES = [
  { n: 'compacto 5,4"',  w: 812,  h: 375, mm: 131 },
  { n: 'normal 6,1"',    w: 852,  h: 393, mm: 147 },
  { n: 'grande 6,7"',    w: 932,  h: 430, mm: 161 },
  { n: 'tableta 11"',    w: 1194, h: 834, mm: 249 },
];

(async () => {
  // El contenedor trae Chromium puesto, pero con otra versión que la que pide este
  // Playwright: se le señala el binario en vez de bajar otro.
  const PUESTO = '/opt/pw-browsers/chromium-1194/chrome-linux/chrome';
  const nav = await chromium.launch(fs.existsSync(PUESTO) ? { executablePath: PUESTO } : {});
  const tomas = [], portadas = [];
  const medidas = [];
  console.log('móvil            marco   pantalla   joystick   botón A');
  for (const m of MOVILES) {
    const pag = await nav.newPage({ viewport: { width: m.w, height: m.h } });
    await pag.goto('file://' + HTML);
    // Hay que entrar en la partida: en el título no hay mando que medir. Y el título no
    // se va hasta que la ciudad está forjada, que tarda unos segundos.
    // El botón no hace nada hasta que la ciudad está forjada: el rótulo de carga es el
    // que dice cuándo. Pulsar antes se traga la pulsación y la foto sale del título.
    // El juego marca la raíz cuando la portada ya está pintada del todo.
    await pag.waitForFunction(() => document.body.dataset.listo === '1',
                              null, { timeout: 90000 }).catch(() => {});
    await pag.waitForSelector('#btnNuevo', { timeout: 30000 });
    if (m.n.startsWith('normal')) portadas.push(await pag.screenshot());
    await pag.click('#btnNuevo');
    // El mando aparece cuando el juego arranca; se espera a que el joystick tenga tamaño.
    await pag.waitForFunction(
      () => { const j = document.getElementById('joy');
              return j && j.getBoundingClientRect().width > 10
                       && getComputedStyle(j).visibility !== 'hidden'
                       && j.getBoundingClientRect().top >= 0; },
      null, { timeout: 45000 }).catch(() => {});
    await pag.waitForTimeout(600);
    const med = await pag.evaluate(() => {
      const r = s => { const e = document.querySelector(s); return e ? e.getBoundingClientRect() : null; };
      return { izq: r('#izq'), joy: r('#joy'), btn: r('.btn'), cv: r('canvas#c'), pas: r('.pas') };
    });
    const mm = px => (px * m.mm / m.w).toFixed(1);
    console.log(
      m.n.padEnd(16),
      (mm(med.izq.width) + ' mm').padEnd(8),
      (mm(med.cv.width) + ' mm').padEnd(11),
      (mm(med.joy.width) + ' mm').padEnd(11),
      med.btn ? mm(med.btn.width) + ' mm' : '—');
    medidas.push({ n: m.n, joy: +mm(med.joy.width), cv: +mm(med.cv.width),
                   btn: med.btn ? +mm(med.btn.width) : null });
    tomas.push(await pag.screenshot());
    await pag.close();
  }
  await nav.close();

  // Los mínimos, y de dónde salen: por debajo de 16 mm el joystick es más pequeño que el
  // pulgar que lo usa, y un botón de menos de 9 mm se falla más de lo que se acierta.
  const fallos = [];
  for (const m of medidas) {
    if (m.joy < 16) fallos.push(m.n + ': joystick de ' + m.joy.toFixed(1) + ' mm, menos que el pulgar');
    if (m.btn && m.btn < 9) fallos.push(m.n + ': botones de ' + m.btn.toFixed(1) + ' mm');
    if (m.cv < 40) fallos.push(m.n + ': la pantalla del juego se queda en ' + m.cv.toFixed(0) + ' mm');
  }
  for (const f of fallos) console.log('  FALLO ' + f);

  const salida = process.argv[2] || path.join(__dirname, '..', '..', 'referencia', 'capturas', 'mando.png');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, tomas[1]);
  if (portadas.length) {
    const pp = salida.replace(/\.png$/, '-portada.png');
    fs.writeFileSync(pp, portadas[0]);
    console.log('->', pp);
  }
  console.log('->', salida);
  if (fallos.length) {
    console.log('\n' + fallos.length + ' medidas por debajo del mínimo');
    process.exit(1);
  }
  console.log('\n  ok    el mando se puede usar con el pulgar en los ' + medidas.length + ' tamaños');
  process.exit(0);
})();
