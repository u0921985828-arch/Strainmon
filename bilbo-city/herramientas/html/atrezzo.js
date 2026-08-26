/**
 * Saca todo el mobiliario urbano en una lámina, con su nombre y su medida en metros.
 *
 *   node herramientas/html/atrezzo.js [salida.png] [--esc N]
 *
 * Una pieza suelta y sobre fondo negro siempre parece que está bien: lo que enseña si el
 * conjunto vale es verlas todas juntas y a la misma escala, que es como se ven en la calle
 * —un banco al lado de una papelera al lado de un árbol—. Debajo va lo que mide de verdad,
 * porque el fallo más habitual no es de dibujo, es de tamaño.
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');
const { createCanvas } = require('canvas');

const listo = async () => {
  for (let t = 0; t < 40000; t += 25) {
    if (global.__ && global.__.PROP && global.__.MOB_M && global.__.PROP.farola) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('el mobiliario no se forjó');
};

listo().then(() => {
  const { PROP, MOB_M } = global.__;
  const opc = n => { const i = process.argv.indexOf(n); return i < 0 ? null : Number(process.argv[i + 1]); };
  const E = opc('--esc') || 2;
  // Ordenadas por altura: así cada fila lleva piezas parecidas y la fila se hace tan alta
  // como la más alta que tenga. Con una sola altura para toda la lámina, la grúa de doce
  // metros dejaba a la papelera perdida en el centro de una celda vacía.
  const piezas = Object.keys(MOB_M).filter(k => PROP[k])
    .sort((a, b) => PROP[a].height - PROP[b].height || (a < b ? -1 : 1));
  const ancho = Math.max(...piezas.map(k => PROP[k].width)) * E;
  const CW = Math.max(120, ancho + 24);
  const COL = Math.max(4, Math.min(8, Math.ceil(Math.sqrt(piezas.length))));
  const filas = [];
  for (let i = 0; i < piezas.length; i += COL) filas.push(piezas.slice(i, i + COL));
  const altoFila = filas.map(f => Math.max(...f.map(k => PROP[k].height)) * E);
  const topes = [];
  let acc = 56;
  for (const h of altoFila) { topes.push(acc); acc += h + 44; }
  const c = createCanvas(COL * CW, acc);
  const g = c.getContext('2d');
  g.imageSmoothingEnabled = false;
  g.fillStyle = '#0b0e12'; g.fillRect(0, 0, c.width, c.height);
  g.fillStyle = '#e8c547'; g.font = 'bold 20px sans-serif';
  g.fillText('BILBO CITY · atrezzo (' + piezas.length + ' piezas)', 20, 34);

  piezas.forEach((k, i) => {
    const fila = Math.floor(i / COL), alto = altoFila[fila];
    const x = (i % COL) * CW, y = topes[fila];
    // Fondo alterno: una pieza que solo se recorta sobre el asfalto y se pierde sobre la
    // acera no está terminada. Es la misma regla que el canto negro.
    g.fillStyle = i % 2 ? '#2b3138' : '#171d23';
    g.fillRect(x + 4, y + 4, CW - 8, alto + 8);
    const s = PROP[k];
    // Apoyadas en el suelo de la celda y centradas, que es como se plantan en el juego.
    g.drawImage(s, x + (CW - s.width * E) / 2, y + 4 + alto - s.height * E, s.width * E, s.height * E);
    g.fillStyle = '#e6e2d6'; g.font = '12px sans-serif';
    g.fillText(k, x + 10, y + alto + 26);
    g.fillStyle = '#8a8578'; g.font = '11px sans-serif';
    g.fillText(MOB_M[k][0] + ' × ' + MOB_M[k][1] + ' m', x + 10, y + alto + 40);
  });

  const salida = (process.argv[2] && !process.argv[2].startsWith('--'))
    ? process.argv[2] : path.join(__dirname, '..', '..', 'referencia', 'capturas', 'atrezzo.png');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, c.toBuffer('image/png'));
  console.log('->', salida, piezas.length + ' piezas a escala ×' + E);
  process.exit(0);
});
