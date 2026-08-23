/**
 * Seis fuentes para el juego, en una sola imagen, escritas con frases de verdad del
 * HUD para verlas como quedan y no como suenan.
 *
 *   node herramientas/html/fuentes.js [salida.png]
 *
 * El alfabeto de 5×7 se lee del propio juego, así que si allí se retoca una letra aquí
 * se ve retocada. Las variantes que derivan de él —negrita, serifa— se calculan; la
 * condensada de 3×5 es un alfabeto aparte, que a ese tamaño no se puede derivar nada.
 */
const fs = require('fs'), path = require('path');
const { createCanvas } = require('canvas');

const RAIZ = path.join(__dirname, '..', '..');
const html = fs.readFileSync(path.join(RAIZ, 'referencia', 'bilbo-city.html'), 'utf8');
const G5 = eval('(' + html.slice(html.indexOf('const GLIFOS={') + 13,
  html.indexOf('};', html.indexOf('const GLIFOS={')) + 1) + ')');

// ── alfabeto condensado de 3×5 ──────────────────────────────────────────────────────
// A este tamaño cada letra es un compromiso: no hay sitio para redondear nada, así que
// se dibuja la que se lee, no la más bonita.
const G3 = {
  A:[2,5,7,5,5], B:[6,5,6,5,6], C:[3,4,4,4,3], D:[6,5,5,5,6], E:[7,4,6,4,7],
  F:[7,4,6,4,4], G:[3,4,5,5,3], H:[5,5,7,5,5], I:[7,2,2,2,7], J:[1,1,1,5,2],
  K:[5,5,6,5,5], L:[4,4,4,4,7], M:[5,7,7,5,5], N:[5,7,7,7,5], O:[2,5,5,5,2],
  P:[6,5,6,4,4], Q:[2,5,5,6,3], R:[6,5,6,5,5], S:[3,4,2,1,6], T:[7,2,2,2,2],
  U:[5,5,5,5,7], V:[5,5,5,5,2], W:[5,5,7,7,5], X:[5,5,2,5,5], Y:[5,5,2,2,2],
  Z:[7,1,2,4,7],
  '0':[7,5,5,5,7], '1':[2,6,2,2,7], '2':[6,1,2,4,7], '3':[6,1,2,1,6], '4':[5,5,7,1,1],
  '5':[7,4,6,1,6], '6':[3,4,6,5,2], '7':[7,1,2,2,2], '8':[2,5,2,5,2], '9':[2,5,3,1,6],
  '.':[0,0,0,0,2], ',':[0,0,0,2,4], ':':[0,2,0,2,0], '!':[2,2,2,0,2], '?':[6,1,2,0,2],
  '-':[0,0,7,0,0], '+':[0,2,7,2,0], '/':[1,1,2,4,4], "'":[2,2,0,0,0],
  '(':[1,2,2,2,1], ')':[4,2,2,2,4], '€':[3,6,4,6,3], '%':[5,1,2,4,5], '>':[0,4,2,4,0],
  'Ñ':[5,7,7,7,5], 'Á':[2,5,7,5,5], 'É':[7,4,6,4,7], 'Í':[7,2,2,2,7], 'Ó':[2,5,5,5,2],
  'Ú':[5,5,5,5,7], ' ':[0,0,0,0,0],
};

// ── derivaciones del alfabeto de 5×7 ────────────────────────────────────────────────
const negrita = g => Object.fromEntries(Object.entries(g)
  .map(([k, f]) => [k, f.map(r => (r | (r << 1)) & 63)]));          // engorda a 6 de ancho
// La serifa es el remate del asta, no un engorde de la fila: ensanchar entera la
// primera y la última fila pega los trazos y la M acaba siendo un borrón. Se busca qué
// columnas son asta —encendidas en cuatro filas o más— y solo a esas se les pone pie.
const serifa = g => Object.fromEntries(Object.entries(g).map(([k, f]) => {
  const asta = [];
  for (let x = 0; x < 5; x++) { let n = 0; for (let y = 0; y < 7; y++) if ((f[y] >> (4 - x)) & 1) n++; asta[x] = n >= 4; }
  const remate = y => {
    let r = f[y];
    for (let x = 0; x < 5; x++) if (asta[x] && ((f[y] >> (4 - x)) & 1)) {
      if (x > 0) r |= 1 << (4 - (x - 1));
      if (x < 4) r |= 1 << (4 - (x + 1));
    }
    return r & 31;
  };
  return [k, f.map((r, i) => (i === 0 || i === 6) ? remate(i) : r)];
}));

// ── las seis ────────────────────────────────────────────────────────────────────────
// Cada una es alfabeto + tratamiento. El tratamiento pesa tanto como la letra: la misma
// A con contorno y degradado, o plana con sombra dura, son dos fuentes distintas.
const P = { crema:'#e8dfc4', mostaza:'#e8c547', ambar:'#d9891f', rojoO:'#8e3316',
  blanco:'#f4f1e6', hueso:'#e6e2d6', acero:'#8d99a4', aceroO:'#5d6771', carbon:'#14181d',
  negro:'#07090c', verdeL:'#8fd08a', rojoL:'#e0685a', papel:'#d8cdae', tinta:'#3a2f22',
  neon:'#f7e58c', neonO:'#e8a33d' };

const FUENTES = [
  { n:'1 · CHIP', d:'la de ahora: 5×7, contorno negro y degradado de tres bandas',
    g:G5, an:5, al:7, sep:6, modo:'contorno', cols:[P.crema,P.mostaza,P.ambar,P.rojoO] },
  { n:'2 · ZURITO', d:'condensada de 3×5: cabe el doble de texto en la misma caja',
    g:G3, an:3, al:5, sep:4, modo:'sombra', cols:[P.hueso], sombra:P.negro },
  { n:'3 · BLOQUE', d:'la de 5×7 engordada a 6: rotulazo, plana y con sombra dura',
    g:negrita(G5), an:6, al:7, sep:7, modo:'sombra', cols:[P.mostaza], sombra:P.rojoO },
  { n:'4 · CINTA', d:'5×7 plana, sin contorno y con más aire entre letras',
    g:G5, an:5, al:7, sep:7, modo:'plana', cols:[P.hueso] },
  { n:'5 · RÓTULO', d:'5×7 con pie en las astas y una sombra larga: prensa vieja',
    g:serifa(G5), an:5, al:7, sep:7, modo:'larga', cols:[P.papel], sombra:'#4a2f1a' },
  { n:'6 · NEÓN', d:'5×7 con halo de un píxel y letra suelta: para avisos, no para leer',
    g:G5, an:5, al:7, sep:8, modo:'halo', cols:[P.neon], halo:[P.neonO] },
];

const MUESTRAS = [
  { t:'VIVE DONDE PUEDAS. COBRA DONDE TOQUE', e:2 },
  { t:'ENTREGA - SAN MAMES     08:05  DIA 1     1240 €', e:1 },
  { t:'ACCION: ENTRAR EN TU PISO', e:1 },
];

function pinta(g, F, s, x, y, esc) {
  let cx = x;
  for (const ch of String(s).toUpperCase()) {
    const f = F.g[ch] || F.g['?'];
    if (ch === ' ') { cx += (F.sep - 2) * esc; continue; }
    const on = (px, py) => py >= 0 && py < F.al && px >= 0 && px < F.an && ((f[py] >> (F.an - 1 - px)) & 1);
    if (F.modo === 'larga') {
      // Sombra larga en diagonal: tres píxeles abajo a la derecha, como un rótulo pintado
      g.fillStyle = F.sombra;
      for (let k = 1; k <= 3; k++)
        for (let py = 0; py < F.al; py++) for (let px = 0; px < F.an; px++)
          if (on(px, py)) g.fillRect(cx + (px + k) * esc, y + (py + k) * esc, esc, esc);
    }
    if (F.modo === 'contorno' || F.modo === 'halo') {
      const anillos = F.modo === 'halo' ? [[1, F.halo[0]]] : [[1, P.carbon]];
      for (const [r, col] of anillos) {
        g.fillStyle = col;
        for (let py = -r; py < F.al + r; py++) for (let px = -r; px < F.an + r; px++) {
          if (on(px, py)) continue;
          let v = false;
          for (let dy = -r; dy <= r; dy++) for (let dx = -r; dx <= r; dx++) if (on(px + dx, py + dy)) v = true;
          if (v) g.fillRect(cx + px * esc, y + py * esc, esc, esc);
        }
      }
    }
    if (F.modo === 'sombra') {
      g.fillStyle = F.sombra;
      for (let py = 0; py < F.al; py++) for (let px = 0; px < F.an; px++)
        if (on(px, py)) g.fillRect(cx + (px + 1) * esc, y + (py + 1) * esc, esc, esc);
    }
    for (let py = 0; py < F.al; py++) for (let px = 0; px < F.an; px++) {
      if (!on(px, py)) continue;
      const c = F.cols.length > 1
        ? (py < 2 ? F.cols[1] : py < 5 ? F.cols[2] : F.cols[3])
        : F.cols[0];
      g.fillStyle = c;
      g.fillRect(cx + px * esc, y + py * esc, esc, esc);
    }
    if (F.cols.length > 1) {           // brillo en la fila de arriba, como la del juego
      g.fillStyle = F.cols[0];
      for (let px = 0; px < F.an; px++) if (on(px, 0)) g.fillRect(cx + px * esc, y - esc, esc, esc);
    }
    cx += F.sep * esc;
  }
  return cx - x;
}

const ANCHO = 1240, ALTO_F = 158;
const c = createCanvas(ANCHO, 84 + ALTO_F * FUENTES.length), g = c.getContext('2d');
g.imageSmoothingEnabled = false;
g.fillStyle = '#0b0e12'; g.fillRect(0, 0, c.width, c.height);
g.fillStyle = P.mostaza; g.font = 'bold 22px sans-serif';
g.fillText('BILBO CITY · seis fuentes para el texto del juego', 26, 40);
g.fillStyle = P.aceroO; g.font = '13px sans-serif';
g.fillText('mismas frases, mismo fondo, mismo tamaño de pantalla', 26, 58);

FUENTES.forEach((F, i) => {
  const y0 = 74 + i * ALTO_F;
  g.fillStyle = i % 2 ? '#10151a' : '#0e1216'; g.fillRect(0, y0, ANCHO, ALTO_F - 8);
  g.fillStyle = P.mostaza; g.font = 'bold 15px sans-serif'; g.fillText(F.n, 26, y0 + 26);
  g.fillStyle = P.aceroO; g.font = '12px sans-serif'; g.fillText(F.d, 26, y0 + 44);
  let y = y0 + 58;
  for (const m of MUESTRAS) { pinta(g, F, m.t, 28, y, m.e * 2); y += (F.al + 3) * m.e * 2 + 6; }
});

const salida = process.argv[2] || path.join(RAIZ, 'referencia', 'capturas', 'fuentes.png');
fs.mkdirSync(path.dirname(salida), { recursive: true });
fs.writeFileSync(salida, c.toBuffer('image/png'));
console.log('->', salida, c.width + 'x' + c.height);
