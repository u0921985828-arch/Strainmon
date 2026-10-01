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
    if (A && A.TILE && A.TILE.calzada && A.BORDE && A.BORDE.length > 1) return;
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
  const alto = CAB + ANCHOS.reduce((s, w) => s + filaH(w) + GAP, 0) + 260;
  // El lienzo se mide en píxeles del juego y se amplía al final por un entero: así un
  // píxel de tile ocupa E píxeles exactos y la lámina sigue siendo pixel art.
  const ancho = Math.max(ETI + filaW + MARGEN * 2, ETI + 8 * TS + 8 * (TS + 6) + MARGEN);
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
        g.drawImage(A.tileCalzada(A.codPack(A.EJE_H, canto, centro, 0, A.D_NO)), x0 + fx * TS, y0 + fy * TS);
        const s = sentido(A.EJE_H, an, po);
        if (s && fx % 4 === 2) g.drawImage(A.FLECHA_VIA[s], x0 + fx * TS, y0 + fy * TS);
      } else {
        g.drawImage(A.TILE[A.ACERA], x0 + fx * TS, y0 + fy * TS);
        // El bordillo solo en el canto que da a la calzada, igual que en el juego.
        const m = fy === ACERA - 1 ? 4 : fy === ACERA + an ? 1 : 0;
        if (m) g.drawImage(A.tileBordillo(m), x0 + fx * TS, y0 + fy * TS);
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

  /* El cruce, aparte: no cabe en una calle recta. Una calle de tres con su paso de
     cebra, la línea de detención del que llega —y solo del que llega— y el vado de las
     dos aceras. Es la única parte de la lámina donde se ve lo que la pintura DICE y no
     solo cómo es: de un lado del paso hay raya de parada y del otro no. */
  g.fillStyle = '#e8c547'; g.font = 'bold 14px sans-serif';
  g.fillText('el cruce: paso de cebra, línea de detención y vado', MARGEN, y + 18);
  const CRU = 7, AN = 3, PASO = 3;
  for (let fy = 0; fy < AN + 2; fy++) for (let fx = 0; fx < CRU; fx++) {
    const X = ETI + fx * TS, Y = y + 28 + fy * TS;
    const enCalle = fy >= 1 && fy <= AN, po = fy - 1;
    if (enCalle) {
      if (fx === PASO) { g.drawImage(A.tileCalzada(A.codPack(A.EJE_H, 0, 0, 1, A.D_NO)), X, Y); continue; }
      const [canto, centro] = marca(AN, po);
      const se = sentido(A.EJE_H, AN, po);
      // Pegado al paso y yendo hacia él: línea de detención. La casilla del eje no tiene
      // sentido y la lleva del lado donde está el paso, que es lo que hace la pintura.
      let par = A.D_NO;
      if (fx === PASO - 1 && (se === A.SEN_E || !se)) par = A.D_ALTO;
      if (fx === PASO + 1 && (se === A.SEN_O || !se)) par = A.D_BAJO;
      g.drawImage(A.tileCalzada(A.codPack(A.EJE_H, canto, centro, 0, par)), X, Y);
      if (se && fx % 3 === 0) g.drawImage(A.FLECHA_VIA[se], X, Y);
    } else {
      g.drawImage(A.TILE[A.ACERA], X, Y);
      const bit = fy === 0 ? 4 : 1;               // el canto que da a la calzada
      g.drawImage(A.tileBordillo(fx === PASO ? bit << 4 : bit), X, Y);
    }
  }
  g.fillStyle = '#8a8578'; g.font = '11px sans-serif';
  g.fillText('para el que llega', MARGEN, y + 46);
  g.fillText('nada para el que sale', MARGEN, y + 62);
  g.fillText('vado y botones donde cruza', MARGEN, y + 78);

  // Y la tabla entera: los dieciséis bordillos y los cuatro vados.
  const TAB = ETI + (CRU + 1) * TS;
  g.fillStyle = '#8a8578'; g.font = '10px sans-serif';
  for (let m = 0; m < 16; m++) {
    const x = TAB + (m % 8) * (TS + 6), yy = y + 40 + ((m / 8) | 0) * (TS + 22);
    g.drawImage(A.TILE[A.ACERA], x, yy);
    const t = A.tileBordillo(m); if (t) g.drawImage(t, x, yy);
    g.fillText(String(m), x + 12, yy + TS + 12);
  }
  g.fillStyle = '#e6e2d6'; g.font = 'bold 11px sans-serif';
  g.fillText('bordillos', TAB, y + 34);
  g.fillText('vados', TAB, y + 40 + 2 * (TS + 22) + 12);
  g.fillStyle = '#8a8578'; g.font = '10px sans-serif';
  for (let k = 0; k < 4; k++) {
    const mv = 1 << k;
    const x = TAB + k * (TS + 6), yy = y + 40 + 2 * (TS + 22) + 18;
    g.drawImage(A.TILE[A.ACERA], x, yy);
    g.drawImage(A.tileBordillo(mv << 4), x, yy);
    g.fillText(['N','E','S','O'][k], x + 12, yy + TS + 12);
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
