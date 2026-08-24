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
    tomas.push(await pag.screenshot());
    await pag.close();
  }
  await nav.close();

  const salida = process.argv[2] || path.join(__dirname, '..', '..', 'referencia', 'capturas', 'mando.png');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, tomas[1]);
  if (portadas.length) {
    const pp = salida.replace(/\.png$/, '-portada.png');
    fs.writeFileSync(pp, portadas[0]);
    console.log('->', pp);
  }
  console.log('->', salida);
  process.exit(0);
})();
