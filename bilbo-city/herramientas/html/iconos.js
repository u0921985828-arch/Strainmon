/**
 * Saca todos los iconos del juego en una hoja, con su nombre y a dos tamaños.
 *
 *   node herramientas/html/iconos.js [salida.png]
 *
 * A 24 píxeles un icono se dibuja a ciegas: hay que verlo al lado de los demás, grande
 * para juzgar el dibujo y pequeño para saber si de verdad se distingue en el HUD.
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');
const { createCanvas } = require('canvas');

const listo = async () => {
  for (let t = 0; t < 30000; t += 25) {
    if (global.__ && global.__.ICO && Object.keys(global.__.ICO).length) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('los iconos no se forjaron');
};

listo().then(() => {
  const ICO = global.__.ICO;
  const nombres = Object.keys(ICO).sort();
  const COL = 8, CW = 132, CH = 116;
  const c = createCanvas(COL * CW, 56 + Math.ceil(nombres.length / COL) * CH);
  const g = c.getContext('2d');
  g.imageSmoothingEnabled = false;
  g.fillStyle = '#0b0e12'; g.fillRect(0, 0, c.width, c.height);
  g.fillStyle = '#e8c547'; g.font = 'bold 20px sans-serif';
  g.fillText('BILBO CITY · iconos', 20, 34);

  nombres.forEach((n, i) => {
    const x = (i % COL) * CW, y = 56 + Math.floor(i / COL) * CH;
    // Dos fondos por celda: claro y oscuro. Un icono que solo se ve sobre uno no vale,
    // porque va a caer en los dos —la caja del HUD es oscura y la tienda es clara.
    g.fillStyle = '#171d23'; g.fillRect(x + 6, y + 6, CW - 12, 64);
    g.fillStyle = '#8a8578'; g.fillRect(x + 6 + (CW - 12) / 2, y + 6, (CW - 12) / 2, 64);
    g.drawImage(ICO[n], x + 16, y + 14, 48, 48);
    g.drawImage(ICO[n], x + 84, y + 26, 24, 24);
    g.fillStyle = '#e6e2d6'; g.font = '12px sans-serif';
    g.fillText(n, x + 10, y + 88);
  });

  const salida = process.argv[2] || path.join(__dirname, '..', '..', 'referencia', 'capturas', 'iconos.png');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, c.toBuffer('image/png'));
  console.log('->', salida, nombres.length + ' iconos');
  process.exit(0);
});
