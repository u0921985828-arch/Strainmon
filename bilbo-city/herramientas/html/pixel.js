/* ¿Se dibuja el juego en la rejilla de píxeles?
 *
 * Las tres reglas de CLAUDE.md §Pixel perfect no se pueden mirar a ojo en una captura:
 * un icono de 24 px puesto en 20 y un radar a escala 1,6 se ven «un poco sucios» y ya
 * está, y así llevaban meses. Aquí se envuelve el contexto de verdad, se juega unos
 * cuantos fotogramas —ciudad, interior, portada, HUD y menús— y se apunta cada llamada
 * que cae fuera de la rejilla, con el sitio del código que la hizo.
 *
 * Qué se exige, en píxeles de DISPOSITIVO, que es donde acaba todo:
 *  1. Un píxel de textura ocupa un número entero de píxeles de pantalla.
 *  2. Todo lo que se pinta empieza en un píxel entero.
 *  3. Y mide un número entero de píxeles.
 *
 * Lo que no se mira: los arcos y los trazos del radar y del anillo de salud, que son
 * curvas y no arte de píxel, y el giro de los vehículos, que es del diseño.
 */
require('./arnes.js');
const A = global.__;
/* El arnés evalúa lo que hay dentro de <script>, así que la línea de la pila cuenta
   desde ahí y hay que sumarle dónde empieza la etiqueta para poder abrir el HTML por
   donde dice. */
const DESFASE = require('fs').readFileSync(require('path').join(__dirname, '..', '..',
  'referencia', 'bilbo-city.html'), 'utf8').split('<script>')[0].split('\n').length - 1;
const esc = n => Math.abs(n - Math.round(n)) < 1e-6;
const fallos = new Map();

/* El juego se evalúa entero dentro del arnés, así que en la pila sale como <anonymous>
   y el número de línea es el del <script> del HTML, que es lo que hace falta. */
function sitio() {
  for (const l of new Error().stack.split('\n')) {
    const m = l.includes('eval at') && l.match(/<anonymous>:(\d+):\d+/);
    if (m) return 'línea ' + (Number(m[1]) + DESFASE);
  }
  return '¿?';
}
function falla(regla, det) {
  const k = sitio() + ' · ' + regla;
  const v = fallos.get(k) || { n: 0, det };
  v.n++; fallos.set(k, v);
}

function vigilar(ctx) {
  const T = () => ctx.getTransform();
  const oDI = ctx.drawImage.bind(ctx), oFR = ctx.fillRect.bind(ctx);
  ctx.drawImage = function (im, ...a) {
    const m = T(), gira = m.b !== 0 || m.c !== 0;
    let dx, dy, dw, dh, sw, sh;
    if (a.length >= 8) { [, , sw, sh, dx, dy, dw, dh] = a; }
    else if (a.length === 4) { [dx, dy, dw, dh] = a; sw = im.width; sh = im.height; }
    else { [dx, dy] = a; dw = sw = im.width; dh = sh = im.height; }
    // Un coche girado sigue teniendo que ir a escala entera: el giro está en el diseño,
    // el medio píxel no. De la matriz se saca el módulo, que es el zoom sin el ángulo.
    const zx = Math.hypot(m.a, m.b) * dw / sw, zy = Math.hypot(m.c, m.d) * dh / sh;
    if (!esc(zx) || !esc(zy) || Math.round(zx) < 1 || Math.round(zy) < 1)
      falla('escala no entera', (im.width + 'x' + im.height) + ' a ×' + zx.toFixed(3) +
        (Math.abs(zx - zy) > 1e-6 ? '/' + zy.toFixed(3) : ''));
    else if (!gira && (!esc(m.a * dx + m.e) || !esc(m.d * dy + m.f)))
      falla('arranca a medio píxel', (m.a * dx + m.e).toFixed(2) + ',' + (m.d * dy + m.f).toFixed(2));
    return oDI(im, ...a);
  };
  ctx.fillRect = function (x, y, w, h) {
    const m = T();
    if (m.b === 0 && m.c === 0 &&
        (!esc(m.a * x + m.e) || !esc(m.d * y + m.f) || !esc(m.a * w) || !esc(m.d * h)))
      falla('rectángulo a medio píxel',
        (m.a * x + m.e).toFixed(2) + ',' + (m.d * y + m.f).toFixed(2) +
        ' de ' + (m.a * w).toFixed(2) + 'x' + (m.d * h).toFixed(2));
    return oFR(x, y, w, h);
  };
}

const listo = async () => { for (let t = 0; t < 60000; t += 25) {
  if (global.__H && global.__H['btnNuevo:click'] && A.hoja) return;
  await new Promise(r => setTimeout(r, 25)); } throw new Error('no arrancó'); };

listo().then(async () => {
  vigilar(A.real.getContext('2d'));
  A.dib();                                     // portada, antes de empezar
  global.__H['btnNuevo:click']();
  global.__step(60);
  A.empezarMision(A.MISIONES[0]); global.__step(60);
  A.S.estrellas = 3; A.S.sospecha = .6; A.S.visto = true; global.__step(30);
  A.entrar('tasca', A.player, 'TASCA'); global.__step(30);
  A.salir(); global.__step(20);
  A.entrar('ropa', A.player, 'TRAPOS'); A.tiendaRopa(); global.__step(20);
  A.salir(); global.__step(10);
  for (const t of ['mapa', 'misiones', 'curros', 'ajustes'])
    { A.verTab(t); global.__step(10); }
  // Al volante: el chasis va girado y la cámara se aleja, que es donde se nota el temblor.
  const co = A.coches[0];
  if (co) { co.x = A.player.x; co.y = A.player.y; A.player.enCoche = co; co.ang = .7; }
  global.__step(60);
  A.player.enCoche = null;
  A.S.muerto = 1.2; global.__step(10); A.S.muerto = 0;
  const filas = [...fallos.entries()].sort((a, b) => b[1].n - a[1].n);
  for (const [k, v] of filas)
    console.log('  FALLO ' + k + ': ' + v.det + (v.n > 1 ? '  (×' + v.n + ')' : ''));
  console.log(filas.length ? '\n' + filas.length + ' sitios fuera de la rejilla de píxeles'
                           : '\ntodo cae en la rejilla de píxeles');
  process.exit(filas.length ? 1 : 0);
}).catch(e => { console.error(e); process.exit(1); });
