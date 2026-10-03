/**
 * ¿Cabe en el cuadro lo que dice la gente? Medido en el navegador de verdad.
 *
 *   node herramientas/html/dialogo.js
 *   node herramientas/html/dialogo.js --filas 2    (cuántas filas se consienten)
 *
 * El cuadro de diálogo es DOM con su CSS y crece hacia arriba sin tope: `width` es
 * `min(560px,50%)`, así que en un móvil apaisado mide la mitad que en el escritorio y
 * una frase que en la pantalla grande ocupa dos filas allí ocupa cuatro y se come medio
 * juego. En el arnés no se ve —no pinta CSS— y en una captura del escritorio tampoco.
 *
 * De ahí esto, hermano de `menus.js` y de `mando.js`: carga el juego en Chromium a los
 * tamaños de móvil de verdad, le mete una por una todas las frases que el juego puede
 * decir y mide el cuadro. Las frases salen del propio juego a través del arnés, no de
 * una lista de aquí: una frase nueva se mide sola.
 *
 * Es de los caros —levanta un navegador—, así que va a mano y no en `./verificar.sh`.
 */
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');

const HTML = path.join(__dirname, '..', '..', 'referencia', 'bilbo-city.html');
const PUESTO = '/opt/pw-browsers/chromium-1194/chrome-linux/chrome';
// Los mismos de `mando.js`. El primero es el que manda: es donde el cuadro es más
// estrecho y donde antes se rompe nada.
const MOVILES = [
  { n: 'compacto 5,4"', w: 812, h: 375 },
  { n: 'normal 6,1"',   w: 852, h: 393 },
  { n: 'grande 6,7"',   w: 932, h: 430 },
];
const opc = n => { const i = process.argv.indexOf(n); return i < 0 ? null : Number(process.argv[i + 1]); };
const TOPE = opc('--filas') || 2;

const dormir = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  // El arnés para sacar las frases: están dentro de la clausura del juego y desde el
  // navegador no se llega a ellas. Aquí sí, y así la lista no se escribe dos veces.
  require('./arnes.js');
  for (let t = 0; t < 60000; t += 25) {
    if (global.__ && global.__.FRASES_PARROQ) break;
    await dormir(25);
  }
  const A = global.__;
  const frases = [];
  A.FRASES_PARROQ.forEach(f => frases.push(['parroquiano/' + f.t, f.l]));
  A.MISIONES.forEach(m => m.intro.forEach((l, i) => frases.push(['misión/' + m.id + '·' + i, l])));

  const nav = await chromium.launch(fs.existsSync(PUESTO) ? { executablePath: PUESTO } : {});
  let malas = 0;
  for (const m of MOVILES) {
    const pag = await nav.newPage({ viewport: { width: m.w, height: m.h } });
    await pag.goto('file://' + HTML);
    await pag.waitForFunction(() => document.body.dataset.listo === '1', null, { timeout: 90000 });
    await pag.click('#btnNuevo');
    await pag.waitForTimeout(1200);
    const r = await pag.evaluate(([f, tope]) => {
      const d = document.getElementById('dlg'), t = document.getElementById('dlgT');
      // Con nombre y con una opción puesta: el cuadro es más alto que el párrafo solo, y
      // lo que tapa la pantalla es el cuadro entero.
      d.style.display = 'block';
      document.getElementById('dlgN').textContent = 'MARIBEL';
      document.getElementById('dlgO').innerHTML = '<div class="op"><b>Hasta luego</b></div>';
      const pant = document.getElementById('c').getBoundingClientRect().height;
      const fil = parseFloat(getComputedStyle(t).lineHeight);
      const ancho = Math.round(d.getBoundingClientRect().width);
      let peor = 0; const pasadas = [];
      for (const [q, l] of f) {
        t.textContent = l;
        const h = d.getBoundingClientRect().height;
        const filas = Math.round(t.getBoundingClientRect().height / fil);
        if (h > peor) peor = h;
        if (filas > tope) pasadas.push([q, filas, l]);
      }
      d.style.display = 'none';
      return { ancho, pant: Math.round(pant), peor: Math.round(peor), pasadas };
    }, [frases, TOPE]);
    console.log(m.n.padEnd(15) + ' cuadro ' + r.ancho + 'px de ancho · lo más alto, '
                + r.peor + 'px de ' + r.pant + ' (' + Math.round(100 * r.peor / r.pant) + '%)');
    for (const [q, filas, l] of r.pasadas) {
      malas++;
      console.log('  ' + filas + ' filas · ' + q + ': ' + l);
    }
    await pag.close();
  }
  await nav.close();
  if (malas) {
    console.error('\n' + malas + ' frases pasan de ' + TOPE + ' filas: el cuadro crece y tapa el juego');
    process.exit(1);
  }
  console.log('\n' + frases.length + ' frases, ninguna de más de ' + TOPE + ' filas en ningún móvil');
  process.exit(0);
})();
