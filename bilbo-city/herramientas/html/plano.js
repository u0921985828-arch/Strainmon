/**
 * Renderiza el plano completo de la ciudad a PNG y saca sus métricas.
 * Sirve para ver de un vistazo si un cambio ha roto Bilbao.
 *
 *   node herramientas/html/plano.js [salida.png] [--zoom N] [--sin-nombres]
 *                                   [--calles] [--zona x,y,ancho,alto]
 *
 * Con --sin-nombres sale el plano pelado, sin rejilla ni rótulos ni chinchetas: para
 * imprimirlo, anotarlo a mano y devolverlo marcado.
 *
 * Con --calles se pinta encima el callejero: cada calle con nombre en su color y su
 * rótulo, y el resto de la ciudad apagado. Es la única forma de comprobar de un vistazo
 * que la Gran Vía va por la Gran Vía y no por el portal de al lado, porque las calles no
 * llevan escrita una lista de casillas — se buscan solas al cargar la ciudad.
 *
 * Con --zona se recorta un trozo, que a ciudad entera los rótulos no caben: el Ensanche
 * son doce calles en cuatrocientas casillas.
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');
const { createCanvas } = require('canvas');

const args = process.argv.slice(2).filter(a => !a.startsWith('--'));
const zArg = process.argv.indexOf('--zoom');
const Z = zArg > 0 ? Number(process.argv[zArg + 1]) : 1;
const limpio = process.argv.includes('--sin-nombres');
const conCalles = process.argv.includes('--calles');
const zArg2 = process.argv.indexOf('--zona');
const ZONA = zArg2 > 0 ? process.argv[zArg2 + 1].split(',').map(Number) : null;
const salida = args[0] || path.join(__dirname, '..', '..', 'referencia', 'capturas', 'plano-bilbo.png');

const listo = async () => {
  for (let t = 0; t < 30000; t += 25) {
    const A = global.__;
    // El callejero se nombra después de cargar la ciudad, así que esperarlo aparte: sin
    // esto, con --calles salía el plano pelado y ni un rótulo.
    if (A && A.map && A.POI.length && (!conCalles || A.LARGO_CALLE.length === A.CALLES.length)) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('la ciudad no se cargó en 30 s');
};

listo().then(() => {
  const A = global.__;
  const c = createCanvas(A.MW * Z, A.MH * Z), g = c.getContext('2d');
  g.imageSmoothingEnabled = false;
  const col = { 0:'#4a505a', 1:'#8a8578', 2:'#5c5148', 3:'#6c9658', 4:'#3f7396',
                5:'#8d99a4', 6:'#a8a294', 7:'#6b5f45', 8:'#3f3a34', 9:'#241f1c',
                10:'#3d5636' };
  for (let y = 0; y < A.MH; y++)
    for (let x = 0; x < A.MW; x++) {
      g.fillStyle = col[A.map[y * A.MW + x]] || '#f0f';
      g.fillRect(x * Z, y * Z, Z, Z);
    }
  if (conCalles) callejero();
  if (!limpio) mobiliario();

  // ── el callejero ───────────────────────────────────────────────────────────────
  // Cada calle en su color sobre la ciudad apagada, y el rótulo girado al eje de la
  // propia calle: la Gran Vía escrita en horizontal encima de una avenida en diagonal
  // no dice si el nombre ha caído donde toca.
  function callejero() {
    g.fillStyle = 'rgba(12,14,18,.62)';
    g.fillRect(0, 0, c.width, c.height);
    const tono = i => `hsl(${(i * 47) % 360} 85% 62%)`;
    A.CALLES.forEach((via, i) => {
      // Las casillas de esta calle, y de paso su centro y su eje principal.
      let n = 0, sx = 0, sy = 0, sxx = 0, syy = 0, sxy = 0;
      g.fillStyle = tono(i);
      for (let y = 0; y < A.MH; y++)
        for (let x = 0; x < A.MW; x++) {
          if (A.calleDe[y * A.MW + x] !== i + 1) continue;
          g.fillRect(x * Z, y * Z, Z, Z);
          n++; sx += x; sy += y; sxx += x*x; syy += y*y; sxy += x*y;
        }
      if (!n) return;
      const mx = sx/n, my = sy/n;
      // El eje que mejor ajusta la nube de casillas. Se dobla el ángulo para que una
      // recta y su opuesta cuenten igual, y luego se deshace: es la cuenta de siempre
      // para la dirección de una mancha alargada.
      const ang = .5 * Math.atan2(2 * (sxy/n - mx*my), (sxx/n - mx*mx) - (syy/n - my*my));
      g.save();
      g.translate(mx * Z, my * Z);
      g.rotate(Math.abs(ang) > Math.PI/2 ? ang - Math.PI : ang);
      g.font = `bold ${11 * Z}px sans-serif`;
      g.textAlign = 'center'; g.textBaseline = 'middle';
      g.lineWidth = 4; g.strokeStyle = 'rgba(0,0,0,.9)';
      g.strokeText(via.n.toUpperCase(), 0, 0);
      g.fillStyle = tono(i); g.fillText(via.n.toUpperCase(), 0, 0);
      g.restore();
    });
  }
  // ── mobiliario de plano ────────────────────────────────────────────────────────
  // Sin esto el plano es una mancha bonita que no dice dónde está nada. Los barrios van
  // donde el plano municipal pone su rótulo, y los sitios llevan su chincheta: así se
  // ve de un golpe si la catedral ha acabado en Deusto.
  function mobiliario() {
  const CEL = 160 * Z;
  g.strokeStyle = 'rgba(255,255,255,.16)'; g.lineWidth = 1;
  g.textBaseline = 'top';
  for (let x = CEL; x < c.width; x += CEL) { g.beginPath(); g.moveTo(x, 0); g.lineTo(x, c.height); g.stroke(); }
  for (let y = CEL; y < c.height; y += CEL) { g.beginPath(); g.moveTo(0, y); g.lineTo(c.width, y); g.stroke(); }

  const texto = (t, x, y, col, tam, borde) => {
    g.font = `bold ${tam}px sans-serif`;
    g.textAlign = 'center';
    g.lineWidth = 3; g.strokeStyle = borde || 'rgba(0,0,0,.85)';
    g.strokeText(t, x, y); g.fillStyle = col; g.fillText(t, x, y);
  };
  A.BARRIOS.forEach(b => texto(b.n.toUpperCase(), b.x * Z, b.y * Z, '#ffe3b0', 11 * Z));
  // Con --calles las chinchetas sobran: cincuenta y siete rótulos de sitio encima de
  // treinta y cuatro de calle no dejan leer ninguno de los dos.
  (conCalles ? [] : A.POI).forEach(p => {
    const x = p.p.x * Z, y = p.p.y * Z;
    g.fillStyle = p.c || '#fff'; g.strokeStyle = '#000'; g.lineWidth = 1.5;
    g.beginPath(); g.arc(x, y, 3.2 * Z, 0, 7); g.fill(); g.stroke();
    texto(p.n, x, y + 5 * Z, '#ffffff', 9 * Z);
  });

  }
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  let hoja = c;
  if (ZONA) {
    const [zx, zy, zan, zal] = ZONA;
    hoja = createCanvas(zan * Z, zal * Z);
    hoja.getContext('2d').drawImage(c, -zx * Z, -zy * Z);
  }
  fs.writeFileSync(salida, hoja.toBuffer('image/png'));

  // ── métricas ───────────────────────────────────────────────────────────────────
  const cuenta = {};
  for (const v of A.map) cuenta[v] = (cuenta[v] || 0) + 1;
  const nom = { 0:'calle', 1:'acera', 2:'manzana', 3:'parque', 4:'agua', 5:'puente',
                6:'plaza', 7:'muelle', 8:'patio', 9:'vía', 10:'monte' };
  console.log(`${A.MW}x${A.MH} casillas · ${A.BARRIOS.length} barrios · ${A.POI.length} sitios`);
  Object.keys(cuenta).sort((a, b) => a - b).forEach(k =>
    console.log(`  ${(nom[k] || k).padEnd(8)} ${String(cuenta[k]).padStart(8)}  ${(100 * cuenta[k] / (A.MW * A.MH)).toFixed(1)}%`));
  if (conCalles)
    A.CALLES.forEach((via, i) =>
      console.log(`  ${via.n.padEnd(24)} ${String(A.LARGO_CALLE[i] || 0).padStart(5)} casillas`));
  console.log('->', salida, hoja.width + 'x' + hoja.height);
  process.exit(0);
});
