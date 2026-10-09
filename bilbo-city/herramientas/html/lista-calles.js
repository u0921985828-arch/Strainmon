/**
 * La lista del callejero, para contrastarla con Bilbao de verdad.
 *
 *   node herramientas/html/lista-calles.js [salida.txt]
 *
 * El nombre de una calle no se dibuja en ningún sitio del juego: es un índice por casilla
 * que el HUD lee cuando pasas por encima. Eso hace que un error no se vea — una calle
 * puede estar cien metros corrida y solo lo notas si andas justo por ahí. Así que aquí se
 * saca cada calle con sus dos extremos y el barrio en el que cae cada uno, que es lo que
 * se puede leer y decir «esa no va por ahí».
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');

const listo = async () => {
  for (let t = 0; t < 90000; t += 25) {
    const A = global.__;
    if (A && A.LARGO_CALLE && A.LARGO_CALLE.length === A.CALLES.length) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('la ciudad no cargó');
};

listo().then(() => {
  const A = global.__;
  const cel = A.CALLES.map(() => []);
  for (let i = 0; i < A.calleDe.length; i++) {
    const c = A.calleDe[i];
    if (c) cel[c - 1].push([i % A.MW, (i / A.MW) | 0]);
  }
  const filas = A.CALLES.map((via, i) => {
    const p = cel[i];
    if (!p.length) return { n: via.n, txt: 'sin casillas' };
    // Los dos extremos a lo largo del eje que mejor ajusta la calle: es lo que se
    // entiende como «de dónde a dónde va», y no la caja que la contiene.
    const m = p.length;
    const mx = p.reduce((a, q) => a + q[0], 0) / m, my = p.reduce((a, q) => a + q[1], 0) / m;
    let sxx = 0, syy = 0, sxy = 0;
    for (const q of p) { sxx += (q[0]-mx)**2; syy += (q[1]-my)**2; sxy += (q[0]-mx)*(q[1]-my); }
    const ang = .5 * Math.atan2(2*sxy/m, sxx/m - syy/m);
    const ux = Math.cos(ang), uy = Math.sin(ang);
    const ord = [...p].sort((a, b) => (a[0]*ux + a[1]*uy) - (b[0]*ux + b[1]*uy));
    const a = ord[0], b = ord[ord.length - 1];
    const br = q => A.distDe(q[0], q[1]).n;
    const largo = (Math.hypot(b[0]-a[0], b[1]-a[1]) * 5.16) | 0;
    return { n: via.n, m, largo,
             txt: `${a[0]},${a[1]} (${br(a)})  ->  ${b[0]},${b[1]} (${br(b)})` };
  });
  filas.sort((x, y) => x.n.localeCompare(y.n, 'es'));
  const out = [];
  out.push(`${A.CALLES.length} calles del plano municipal de Bilbao`);
  out.push('nombre · casillas · largo · de dónde a dónde (barrio de cada extremo)');
  out.push('');
  for (const f of filas)
    out.push(`${f.n.padEnd(30)} ${String(f.m || 0).padStart(5)}  ${String(f.largo || 0).padStart(5)} m  ${f.txt}`);
  const salida = process.argv[2] || path.join(__dirname, '..', '..', 'referencia', 'callejero.txt');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, out.join('\n') + '\n');
  console.log('->', salida, filas.length, 'calles');
  process.exit(0);
});
