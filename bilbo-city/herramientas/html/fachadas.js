/**
 * Saca las fachadas de un barrio en una lámina, para poder juzgar la arquitectura.
 *
 *   node herramientas/html/fachadas.js [salida.png] [--barrio bloques] [--esc 3] [--plantas 3]
 *
 * Un barrio no se dibuja a ojo: Santutxu se levantó entre los cincuenta y los setenta y es
 * ladrillo caravista y revoco, con planta de 2,7 m; el Ensanche es piedra y revoco claro
 * con planta de 3,2. Esto saca todos los revocos de un estilo cruzados con todos los tipos
 * de fachada y con el bajo que le toca, que es la única forma de ver si la calle va a salir
 * heterogénea o va a ser el mismo edificio catorce veces.
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');

const opc = n => { const i = process.argv.indexOf(n); return i < 0 ? null : process.argv[i+1]; };
const listo = async () => {
  for (let t = 0; t < 40000; t += 25) {
    const A = global.__;
    if (A && A.PROP && A.PROP.pisos && A.PROP.fachadas) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('el arte no se forjó');
};

listo().then(() => {
  const A = global.__, PROP = A.PROP;
  const est = opc('--barrio') || 'bloques';
  const juegos = PROP.pisos[est];
  if (!juegos) throw new Error('no hay revocos para el estilo ' + est);
  const S = Number(opc('--esc')) || 3, PL = Number(opc('--plantas')) || 3;
  const { createCanvas } = require('canvas');

  const TIP = ['liso', 'balcón', 'mirador', 'persiana'];
  const BAJOS = ['portal', 'escaparate', 'garaje', 'persiana'];
  const M = 5.16 / A.TS;                       // metros por píxel
  const W = A.TS, bandaH = juegos[0][0].height, fachH = PROP.fachadas.portal.height;
  const alto = bandaH * PL + fachH;
  const CW = W * S + 18, CH = alto * S + 20;

  const c = createCanvas(CW * juegos.length + 30, CH * TIP.length + 84);
  const g = c.getContext('2d');
  g.imageSmoothingEnabled = false;
  g.fillStyle = '#0b0e12'; g.fillRect(0, 0, c.width, c.height);
  g.fillStyle = '#e8c547'; g.font = 'bold 20px sans-serif';
  g.fillText('BILBO CITY · fachadas de estilo «' + est + '»  ·  planta de '
    + (bandaH * M).toFixed(2) + ' m  ·  1 px = ' + (M * 100).toFixed(0) + ' cm', 22, 32);
  g.font = '12px sans-serif';
  juegos.forEach((_, ci) => { g.fillStyle = '#8a8578'; g.fillText('revoco ' + (ci+1), 30 + ci * CW, 52); });

  TIP.forEach((t, fi) => {
    g.fillStyle = '#8a8578'; g.font = 'bold 12px sans-serif';
    g.save(); g.translate(14, 68 + fi * CH + CH / 2); g.rotate(-Math.PI/2);
    g.textAlign = 'center'; g.fillText(t, 0, 0); g.restore();
    juegos.forEach((tipos, ci) => {
      const x = 30 + ci * CW, y = 68 + fi * CH;
      g.fillStyle = '#171d23'; g.fillRect(x - 4, y - 4, W * S + 8, alto * S + 8);
      for (let k = 0; k < PL; k++)
        g.drawImage(tipos[fi], 0, 0, W, bandaH, x, y + k * bandaH * S, W * S, bandaH * S);
      // el bajo: se rellena la casilla con lo que quepa, igual que en la ciudad
      let px = 0, n = 0;
      while (px < W) {
        let k = BAJOS[(fi + n) % BAJOS.length];
        if (A.ANCHO_FACH[k] * 2 > W - px) k = 'portal';
        const spr = PROP.fachadas[k];
        g.drawImage(spr, 0, 0, spr.width, fachH, x + px * S, y + PL * bandaH * S, spr.width * S, fachH * S);
        px += spr.width; n++;
      }
    });
  });

  const salida = (process.argv[2] && !process.argv[2].startsWith('--')) ? process.argv[2]
    : path.join(__dirname, '..', '..', 'referencia', 'capturas', 'fachadas-' + est + '.png');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, c.toBuffer('image/png'));
  console.log('->', salida, juegos.length + ' revocos × ' + TIP.length + ' tipos');
  process.exit(0);
});
