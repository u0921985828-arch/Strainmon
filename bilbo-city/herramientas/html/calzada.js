/**
 * Saca la calle: las marcas viales, los bordillos y una calzada de cada ancho.
 *
 *   node herramientas/html/calzada.js [salida.png] [--esc N]
 *
 * El ancho de cada calle sale del plano municipal, pero lo que lo hace visible son las
 * marcas, y esas no se pueden juzgar en el juego: en la calle siempre hay un coche, un
 * contenedor o la propia farola encima. Aquí se ven solas — una calzada de cada ancho,
 * tileada como la pinta el juego, con sus aceras y sus bordillos — y se ve de un vistazo
 * si un callejón de dos se distingue de una avenida de seis.
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');
const { createCanvas } = require('canvas');

const listo = async () => {
  for (let t = 0; t < 40000; t += 25) {
    const A = global.__;
    if (A && A.TILE && A.TILE.calzada && A.BORDE && A.BORDE[1]) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('la calzada no se forjó');
};

listo().then(() => {
  const A = global.__, TS = A.TS;
  const E = Number((process.argv.find((v, i) => process.argv[i-1] === '--esc') || 3));
  const LARGO = 9;                      // casillas de calle que se enseñan de cada ancho
  const ACERA = 2;                      // casillas de acera a cada lado

  /* Lo mismo que hace `trazarCalzada`, pero sobre una calle de laboratorio: recta, de
     ancho constante y sin cruces. Si esto y el juego dejaran de coincidir, lo que estaría
     mal es esto — la verdad es la pasada que mide el plano. */
  const marca = (an, po) => {
    if (an < 2) return [A.M_NADA, A.M_NADA];
    const c = an / 2, cont = an >= 3;
    let canto = A.M_NADA, centro = A.M_NADA;
    if (an % 2 === 0) { if (po === c) canto = cont ? A.M_EJE : A.M_EJE_DIS; }
    else if (po === (an - 1) / 2) centro = cont ? A.M_EJE : A.M_EJE_DIS;
    if (canto === A.M_NADA && po >= 1 && Math.abs(po - c) >= 1) canto = A.M_CARRIL;
    return [canto, centro];
  };
  const sentido = (eje, an, po) => an < 2 ? A.SEN_NO
    : eje === A.EJE_H ? (po + .5 > an / 2 ? A.SEN_E : A.SEN_O)
                      : (po + .5 < an / 2 ? A.SEN_S : A.SEN_N);

  const ANCHOS = [1, 2, 3, 4, 5, 6, 7, 8];
  const filaW = (LARGO) * TS, filaH = w => (w + ACERA * 2) * TS;
  const GAP = 18, MARGEN = 16, CAB = 54, ETI = 210;
  const alto = CAB + ANCHOS.reduce((s, w) => s + filaH(w) + GAP, 0) + 190;
  // El lienzo se mide en píxeles del juego y se amplía al final por un entero: así un
  // píxel de tile ocupa E píxeles exactos y la lámina sigue siendo pixel art.
  const ancho = Math.max(ETI + filaW + MARGEN * 2, ETI + 6 * TS + 8 * (TS + 6) + MARGEN);
  const base = createCanvas(ancho, alto);
  const g = base.getContext('2d');
  g.imageSmoothingEnabled = false;
  g.fillStyle = '#0b0e12'; g.fillRect(0, 0, base.width, base.height);
  g.fillStyle = '#e8c547'; g.font = 'bold 16px sans-serif';
  g.fillText('BILBO CITY · la calzada por anchos', MARGEN, 24);
  g.fillStyle = '#8a8578'; g.font = '11px sans-serif';
  g.fillText('cada fila es una calle este-oeste del ancho que dice, con sus dos aceras', MARGEN, 40);

  let y = CAB;
  for (const an of ANCHOS) {
    const x0 = ETI, y0 = y;
    for (let fy = 0; fy < an + ACERA * 2; fy++) for (let fx = 0; fx < LARGO; fx++) {
      const enCalle = fy >= ACERA && fy < ACERA + an, po = fy - ACERA;
      if (enCalle) {
        const [canto, centro] = marca(an, po);
        g.drawImage(A.tileCalzada(A.codPack(A.EJE_H, canto, centro, 0)), x0 + fx * TS, y0 + fy * TS);
        const s = sentido(A.EJE_H, an, po);
        if (s && fx % 4 === 2) g.drawImage(A.FLECHA_VIA[s], x0 + fx * TS, y0 + fy * TS);
      } else {
        g.drawImage(A.TILE[A.ACERA], x0 + fx * TS, y0 + fy * TS);
        // El bordillo solo en el canto que da a la calzada, igual que en el juego.
        const m = fy === ACERA - 1 ? 4 : fy === ACERA + an ? 1 : 0;
        if (m) g.drawImage(A.BORDE[m], x0 + fx * TS, y0 + fy * TS);
      }
    }
    g.fillStyle = '#e6e2d6'; g.font = 'bold 13px sans-serif';
    g.fillText(an + (an === 1 ? ' casilla' : ' casillas'), MARGEN, y0 + 16);
    g.fillStyle = '#8a8578'; g.font = '11px sans-serif';
    g.fillText((an * 5.16).toFixed(0) + ' m de calzada', MARGEN, y0 + 32);
    g.fillText(an < 2 ? 'sin marcas' : an === 2 ? 'eje discontinuo' :
      an % 2 ? 'eje continuo en la casilla central' : 'eje continuo en el canto central', MARGEN, y0 + 48);
    y += filaH(an) + GAP;
  }

  // El paso de cebra y los dieciséis bordillos, aparte: no caben en una calle recta.
  g.fillStyle = '#e8c547'; g.font = 'bold 14px sans-serif';
  g.fillText('paso de cebra y los dieciséis bordillos', MARGEN, y + 18);
  for (let fy = 0; fy < 5; fy++) for (let fx = 0; fx < 5; fx++) {
    const enCalle = fy >= 1 && fy < 4;
    if (enCalle) g.drawImage(A.tileCalzada(A.codPack(A.EJE_H, 0, 0, fx === 2 ? 1 : 0)), ETI + fx * TS, y + 28 + fy * TS);
    else {
      g.drawImage(A.TILE[A.ACERA], ETI + fx * TS, y + 28 + fy * TS);
      const m = fx === 2 ? 0 : fy === 0 ? 4 : 1;      // vado donde cruza el paso
      if (m) g.drawImage(A.BORDE[m], ETI + fx * TS, y + 28 + fy * TS);
    }
  }
  for (let m = 0; m < 16; m++) {
    const x = ETI + 6 * TS + (m % 8) * (TS + 6), yy = y + 28 + ((m / 8) | 0) * (TS + 22);
    g.drawImage(A.TILE[A.ACERA], x, yy);
    if (A.BORDE[m]) g.drawImage(A.BORDE[m], x, yy);
    g.fillStyle = '#8a8578'; g.font = '10px sans-serif';
    g.fillText(String(m), x + 12, yy + TS + 12);
  }

  const out = createCanvas(base.width * E, base.height * E);
  const og = out.getContext('2d');
  og.imageSmoothingEnabled = false;
  og.drawImage(base, 0, 0, out.width, out.height);
  const salida = process.argv[2] && !process.argv[2].startsWith('--') ? process.argv[2]
    : path.join(__dirname, '..', '..', 'referencia', 'capturas', 'calzada.png');
  fs.mkdirSync(path.dirname(salida), { recursive: true });
  fs.writeFileSync(salida, out.toBuffer('image/png'));
  console.log('->', salida, ANCHOS.length + ' anchos ·', A.VIA_COD.length + ' códigos de marca en el mapa');
  process.exit(0);
});
