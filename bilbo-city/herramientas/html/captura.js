/**
 * Saca una captura del juego en marcha, sobre el DOM simulado.
 *
 *   node herramientas/html/captura.js [salida.png] [--pasos N] [--anda N]
 *
 * El arte se juzga mal en una lámina de contacto: ahí cada sprite está solo y sobre un
 * fondo elegido. En la calle cae encima del asfalto, de la acera y del portal, y al lado
 * de los coches y del HUD. Esto arranca la partida de verdad, deja correr unos
 * fotogramas y vuelca el lienzo tal cual.
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');

const dormir = ms => new Promise(r => setTimeout(r, ms));
const listo = async (topeMs = 40000) => {
  for (let t = 0; t < topeMs; t += 25) {
    if (global.__H && global.__H['btnNuevo:click']) return;
    await dormir(25);
  }
  throw new Error('el juego no arrancó en ' + topeMs + ' ms');
};

listo().then(() => {
  const H = global.__H, A = global.__, paso = global.__step;
  const opc = n => { const i = process.argv.indexOf(n); return i < 0 ? null : Number(process.argv[i+1]); };

  (H['btnNuevo:click'] || H['btnCont:click'])();
  paso(opc('--pasos') || 90);

  // Andar un poco antes de la foto: al arrancar, el tráfico y los peatones aún no se han
  // repartido y sale una calle vacía que no se parece a jugar.
  const anda = opc('--anda') === null ? 70 : opc('--anda');
  if (anda) { A.teclas['w'] = true; paso(anda); A.teclas['w'] = false; paso(40); }

  const salida = (process.argv[2] && !process.argv[2].startsWith('--')) ? process.argv[2]
    : path.join(__dirname, '..', '..', 'referencia', 'capturas', 'captura-calle.png');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, A.real.toBuffer('image/png'));
  console.log('->', salida, A.real.width + 'x' + A.real.height,
              '· ' + A.peatones.length + ' peatones · ' + A.coches.length + ' coches');
  process.exit(0);
});
