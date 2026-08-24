/**
 * Saca una captura del juego en marcha, sobre el DOM simulado.
 *
 *   node herramientas/html/captura.js [salida.png] [--pasos N] [--anda N] [--dentro id]
 *                                       [--donde x,y]
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
  const txt = n => { const i = process.argv.indexOf(n); return i < 0 ? null : process.argv[i+1]; };

  (H['btnNuevo:click'] || H['btnCont:click'])();
  paso(opc('--pasos') || 90);

  // Andar un poco antes de la foto: al arrancar, el tráfico y los peatones aún no se han
  // repartido y sale una calle vacía que no se parece a jugar.
  // Plantarse en un sitio concreto del mapa: la ciudad no se parece a sí misma de un
  // barrio a otro, y una sola foto de Santutxu no dice nada del Casco Viejo.
  // Plantarse en un sitio concreto del mapa. Por defecto se busca una acera cerca, que es
  // donde estaría un jugador; con --exacto se planta en la casilla pedida aunque sea el
  // centro de una manzana. Eso hace falta para mirar un edificio grande: la cámara sigue
  // al jugador y la pantalla son veintiséis casillas, así que buscando acera para el
  // centro del estadio la foto salía de la calle de al lado, sin estadio.
  const donde = txt('--donde');
  if (donde) {
    const [x, y] = donde.split(',').map(Number);
    const q = process.argv.includes('--exacto')
      ? { x: x + .5, y: y + .5 } : A.puntoAcera(x | 0, y | 0, 30);
    A.player.x = q.x; A.player.y = q.y; A.player.enCoche = null;
    paso(30);
  }

  const anda = donde ? 0 : (opc('--anda') === null ? 70 : opc('--anda'));
  if (anda) { A.teclas['w'] = true; paso(anda); A.teclas['w'] = false; paso(40); }

  const dentro = txt('--dentro');
  if (dentro) {
    A.entrar(dentro, { x: A.player.x, y: A.player.y }, txt('--rotulo'));
    // entrar() va con fundido: hay que dejar pasar el temporizador antes de la foto.
    return setTimeout(() => { paso(20); volcar(); }, 400);
  }
  volcar();
});

function volcar() {
  const A = global.__;

  const salida = (process.argv[2] && !process.argv[2].startsWith('--')) ? process.argv[2]
    : path.join(__dirname, '..', '..', 'referencia', 'capturas', 'captura-calle.png');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, A.real.toBuffer('image/png'));
  // Dónde se plantó de verdad: --donde pide una acera cerca del punto, y si el punto cae
  // dentro de una manzana la acera más próxima puede quedar a media calle de distancia.
  // Sin decirlo, uno mira la foto buscando un edificio que está fuera de cuadro.
  console.log('->', salida, A.real.width + 'x' + A.real.height,
              '· en ' + A.player.x.toFixed(0) + ',' + A.player.y.toFixed(0)
              + ' · ' + A.peatones.length + ' peatones · ' + A.coches.length + ' coches');
  process.exit(0);
}
