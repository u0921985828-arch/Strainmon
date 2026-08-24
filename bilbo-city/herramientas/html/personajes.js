/**
 * Saca las hojas de personaje en una lámina de contacto, para poder juzgarlas.
 *
 *   node herramientas/html/personajes.js [salida.png] [--esc N] [--que a,b,c]
 *
 * Un personaje de 20×26 no se dibuja a ojo desde el código: hay que verlo grande para
 * juzgar el dibujo, y en fila para saber si las ocho direcciones son el mismo tipo.
 * La lámina saca cada arquetipo con sus ocho direcciones en reposo, y debajo, del
 * protagonista, todas las poses.
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');
const { createCanvas } = require('canvas');

// Hay que esperar a que el juego esté listo del todo, no a que exista la forja: las
// hojas traídas de PixelLab se descomprimen durante el arranque, y dibujar antes saca la
// forja aunque haya hoja. La lámina tiene que enseñar lo que el juego va a dibujar.
const listo = async () => {
  for (let t = 0; t < 40000; t += 25) {
    if (global.__H && global.__H['btnNuevo:click'] && global.__ && global.__.hoja) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('el juego no arrancó');
};

const DIRS = ['abajo', 'ab-de', 'derecha', 'ar-de', 'arriba', 'ar-iz', 'izquierda', 'ab-iz'];

listo().then(() => {
  const { ARQ, hoja, ORDEN_POSES, SPR } = global.__;
  const [CW, CH] = SPR.cel;
  const opc = n => { const i = process.argv.indexOf(n); return i < 0 ? null : process.argv[i+1]; };
  const E = Number(opc('--esc')) || 4;           // escala de la lámina
  const filtro = opc('--que');
  const arqs = filtro ? filtro.split(',').filter(k => ARQ[k]) : Object.keys(ARQ);
  if (!arqs.length) throw new Error('ningún arquetipo con ese nombre');
  const FW = CW * E, FH = CH * E;
  const PASO_X = FW + 8, PASO_Y = FH + 26;
  const ANCHO = 128 + 8 * PASO_X + 24;
  const ALTO = 64 + arqs.length * PASO_Y + 40 + ORDEN_POSES.length * PASO_Y + 40;

  const c = createCanvas(ANCHO, ALTO);
  const g = c.getContext('2d');
  g.imageSmoothingEnabled = false;
  g.fillStyle = '#0b0e12'; g.fillRect(0, 0, ANCHO, ALTO);
  g.fillStyle = '#e8c547'; g.font = 'bold 20px sans-serif';
  g.fillText('BILBO CITY · personajes', 20, 34);

  // Cada celda lleva su propio fondo, alterno, para ver el contorno del sprite: uno que
  // solo se recorta sobre el asfalto y se pierde sobre la acera no vale.
  const fondo = (x, y, i) => {
    g.fillStyle = i % 2 ? '#171d23' : '#2b3138';
    g.fillRect(x - 4, y - 4, FW + 8, FH + 8);
  };

  const cabecera = (t, y) => {
    g.fillStyle = '#8a8578'; g.font = 'bold 13px sans-serif';
    g.fillText(t, 20, y);
  };

  let y = 64;
  cabecera('ocho direcciones · reposo', y - 14);
  g.font = '11px sans-serif';
  DIRS.forEach((d, i) => { g.fillStyle = '#8a8578'; g.fillText(d, 128 + i * PASO_X, y - 2); });
  y += 8;

  arqs.forEach(k => {
    const h = hoja(k);
    g.fillStyle = '#e6e2d6'; g.font = '12px sans-serif';
    g.fillText(k, 20, y + FH / 2);
    for (let d = 0; d < 8; d++) {
      const x = 128 + d * PASO_X;
      fondo(x, y, d);
      g.drawImage(h, d * CW, 0, CW, CH, x, y, FW, FH);
    }
    y += PASO_Y;
  });

  y += 40;
  cabecera('protagonista · ' + ORDEN_POSES.length + ' poses', y - 14);
  g.font = '11px sans-serif';
  DIRS.forEach((d, i) => { g.fillStyle = '#8a8578'; g.fillText(d, 128 + i * PASO_X, y - 2); });
  y += 8;

  const hp = hoja('protagonista');
  ORDEN_POSES.forEach((p, fy) => {
    g.fillStyle = '#e6e2d6'; g.font = '12px sans-serif';
    g.fillText(p, 20, y + FH / 2);
    for (let d = 0; d < 8; d++) {
      const x = 128 + d * PASO_X;
      fondo(x, y, d);
      g.drawImage(hp, d * CW, fy * CH, CW, CH, x, y, FW, FH);
    }
    y += PASO_Y;
  });

  const salida = (process.argv[2] && !process.argv[2].startsWith('--')) ? process.argv[2] : path.join(__dirname, '..', '..', 'referencia', 'capturas', 'personajes.png');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, c.toBuffer('image/png'));
  console.log('->', salida, arqs.length + ' arquetipos · ' + ORDEN_POSES.length + ' poses');
  process.exit(0);
});
