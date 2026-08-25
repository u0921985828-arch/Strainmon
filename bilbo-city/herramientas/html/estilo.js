/**
 * Comprueba que todo el arte del juego cumple la guía de estilo (referencia/ESTILO.md).
 *
 *   node herramientas/html/estilo.js
 *
 * Una guía de estilo que nadie comprueba dura dos semanas. Esto la comprueba sobre el
 * arte de verdad, el que se forja al arrancar, y devuelve 1 si algo se ha ido.
 */
require('./arnes.js');
const fs = require('fs'), path = require('path');

const listo = async () => {
  for (let t = 0; t < 30000; t += 25) {
    const A = global.__;
    // Los singulares no se forjan con el resto del arte: hasta que no está la ciudad no se
    // sabe de qué tamaño caben, así que hay que esperar a que la ciudad cargue.
    if (A && A.TILE && A.ICO && Object.keys(A.TILE).length && Object.keys(A.ICO).length
        && A.SINGULARES && Object.keys(A.SINGULARES).length) return;
    await new Promise(r => setTimeout(r, 25));
  }
  throw new Error('el arte no se forjó');
};

listo().then(() => {
  const A = global.__;
  const fallos = [], bien = [];
  const px = c => c.getContext('2d').getImageData(0, 0, c.width, c.height).data;
  const enPaleta = new Set(A.PALETA.map(p => (p[0] << 16) | (p[1] << 8) | p[2]));

  // Un lienzo cualquiera: puede venir suelto o dentro de un array (los tejados, el agua).
  // Los grupos anidados —PROP.fachadas, por ejemplo— también son arte y también tienen
  // que pasar por la paleta: sin bajar un nivel se colaban enteros sin revisar.
  const todos = obj => Object.entries(obj).flatMap(([k, v]) => {
    if (Array.isArray(v)) return v.map((c, i) => [k + '[' + i + ']', c]);
    if (v && typeof v.getContext !== 'function' && typeof v === 'object')
      return Object.entries(v).map(([k2, c]) => [k + '.' + k2, c]);
    return [[k, v]];
  });

  // ── R0 · la guía dice la verdad ─────────────────────────────────────────────────
  // Esta regla no mira el arte: mira el documento. Las medidas marcadas [V] en ESTILO.md
  // estaban escritas como si alguien las comprobara y no las comprobaba nadie —el
  // verificador leía `SPR.cel` del juego, nunca el número del papel—, así que la guía
  // llegó a decir celda de 34×38, hoja de 14 filas y 48 colores mientras el juego iba a
  // 24×32, 16 filas y 61. Un documento que puede mentir sin que salte nada acaba
  // mintiendo. Ahora los números del papel se leen del papel y se comparan con el juego.
  {
    const ruta = path.join(__dirname, '..', '..', 'referencia', 'ESTILO.md');
    const doc = fs.readFileSync(ruta, 'utf8');
    const [CW, CH] = A.SPR.cel;
    const dice = [
      [/Persona \|\s*\*\*(\d+)×(\d+) px\*\*/,            [String(A.sc(20)), String(A.sc(26))], 'la figura'],
      [/Celda del personaje \|\s*\*\*(\d+)×(\d+) px\*\*/, [String(CW), String(CH)],     'la celda del personaje'],
      [/Icono de interfaz \|\s*\*\*(\d+)×(\d+) px\*\*/,   ['24', '24'],                 'el icono de interfaz'],
      [/Casilla del mundo \|\s*\*\*(\d+)×(\d+) px\*\*/,   [String(A.TS), String(A.TS)], 'la casilla del mundo'],
      [/Hoja de personaje \|\s*\*\*(\d+) columnas × (\d+) filas\*\*/,
                                                      ['8', String(A.ORDEN_POSES.length)], 'la hoja de personaje'],
      [/\*\*(\d+) colores y ninguno más\*\*/,               [String(A.PALETA.length)],    'la paleta'],
    ];
    let malos = 0;
    for (const [re, esperado, que] of dice) {
      const m = doc.match(re);
      if (!m) { fallos.push('ESTILO.md: no se encuentra la medida de ' + que); malos++; continue; }
      const leido = m.slice(1, esperado.length + 1);
      if (leido.join('×') !== esperado.join('×')) {
        fallos.push('ESTILO.md dice que ' + que + ' mide ' + leido.join('×')
          + ', y el juego la hace de ' + esperado.join('×'));
        malos++;
      }
    }
    if (!malos) bien.push(dice.length + ' medidas de ESTILO.md cuadran con el juego');
  }

  // ── R1 · nada fuera de la paleta, y nada a medio transparente ────────────────────
  {
    let malos = 0, medias = 0;
    const revisa = (nombre, c) => {
      const d = px(c);
      for (let i = 0; i < d.length; i += 4) {
        if (d[i+3] > 0 && d[i+3] < 255) { medias++; if (medias < 4) fallos.push(nombre + ': píxel a medio transparente'); return; }
        if (d[i+3] === 0) continue;
        if (!enPaleta.has((d[i] << 16) | (d[i+1] << 8) | d[i+2])) {
          malos++;
          if (malos < 6) fallos.push(nombre + ': color fuera de la paleta #'
            + [d[i],d[i+1],d[i+2]].map(v => v.toString(16).padStart(2,'0')).join(''));
          return;
        }
      }
    };
    for (const [k, c] of todos(A.TILE)) revisa('tile ' + k, c);
    for (const [k, c] of todos(A.ICO)) revisa('icono ' + k, c);
    for (const [k, c] of todos(A.PROP || {})) revisa('prop ' + k, c);
    for (const k of Object.keys(A.ARQ)) revisa('hoja ' + k, A.HOJAS[k] || A.hoja(k));
    for (const [k, s] of Object.entries(A.SINGULARES || {})) revisa('singular ' + k, s.c);
    if (!malos && !medias) bien.push('todo el arte dentro de los ' + A.PALETA.length + ' colores');
  }

  // ── R2 · los iconos: 24×24, contorno negro y pocos colores ───────────────────────
  {
    // El negro se lee del juego, no se escribe aquí. Escrito a mano, al cambiar la paleta
    // este test acusaba de no tener contorno a treinta iconos que lo tenían perfecto.
    const NEG = A.PALETA.find(p => p[3] === A.C.negro) || [0, 0, 0];
    let malos = 0;
    for (const [k, c] of Object.entries(A.ICO)) {
      if (c.width !== 24 || c.height !== 24) { fallos.push('icono ' + k + ': mide ' + c.width + 'x' + c.height + ', no 24x24'); malos++; continue; }
      const d = px(c), W = 24, H = 24;
      const opaco = (x, y) => x >= 0 && y >= 0 && x < W && y < H && d[(y*W+x)*4+3] > 0;
      let sinBorde = 0, cols = new Set();
      for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
        const i = (y*W+x)*4;
        if (!d[i+3]) continue;
        cols.add((d[i] << 16) | (d[i+1] << 8) | d[i+2]);
        let borde = false;
        for (let dy = -1; dy <= 1 && !borde; dy++) for (let dx = -1; dx <= 1 && !borde; dx++)
          if (!opaco(x+dx, y+dy)) borde = true;
        if (borde && !(d[i] === NEG[0] && d[i+1] === NEG[1] && d[i+2] === NEG[2])) sinBorde++;
      }
      // El borde del lienzo no cuenta: un icono puede llegar al canto y ahí no cabe contorno.
      if (sinBorde > 8) { fallos.push('icono ' + k + ': ' + sinBorde + ' píxeles de silueta sin contorno negro'); malos++; }
      if (cols.size > 7) { fallos.push('icono ' + k + ': ' + cols.size + ' colores; a 24 px más de 6 es ruido'); malos++; }
    }
    if (!malos) bien.push(Object.keys(A.ICO).length + ' iconos a 24x24, con contorno y sin exceso de color');
  }

  // ── R3 · los tiles del suelo: 32×32 y opacos ─────────────────────────────────────
  // Los muebles de interior no cuentan: se dibujan encima del suelo y tienen que dejar
  // ver la tarima. La lista de cuáles son vive en el juego, no aquí.
  {
    let malos = 0;
    for (const [k, c] of todos(A.TILE)) {
      if (A.TILE_MUEBLE.has(k.replace(/\[\d+\]$/, ''))) continue;
      // La medida sale del juego (`TS`), no de un 32 escrito aquí: la casilla subió a 64
      // para que una persona a escala real tuviese píxeles con los que dibujarse, y un
      // verificador con el número a mano habría dado por malo todo el suelo.
      if (c.width !== A.TS || c.height !== A.TS) { fallos.push('tile ' + k + ': mide ' + c.width + 'x' + c.height + ', no ' + A.TS + 'x' + A.TS); malos++; continue; }
      const d = px(c);
      let huecos = 0;
      for (let i = 3; i < d.length; i += 4) if (d[i] < 255) huecos++;
      // El suelo no tiene agujeros: por un hueco se ve el negro del fondo y aparece una
      // rejilla de puntos por toda la ciudad.
      if (huecos) { fallos.push('tile ' + k + ': ' + huecos + ' píxeles transparentes'); malos++; }
    }
    if (!malos) bien.push((todos(A.TILE).length - A.TILE_MUEBLE.size) + ' tiles de suelo a ' + A.TS + 'x' + A.TS + ' y sin agujeros');
  }

  // ── R4 · las hojas de personaje, a su medida ─────────────────────────────────────
  {
    const [cw, ch] = A.SPR.cel, filas = A.ORDEN_POSES.length;
    let malos = 0;
    for (const k of Object.keys(A.ARQ)) {
      const h = A.HOJAS[k] || A.hoja(k);
      if (h.width !== cw*8 || h.height !== ch*filas) {
        fallos.push('hoja ' + k + ': mide ' + h.width + 'x' + h.height + ', se esperaba ' + (cw*8) + 'x' + (ch*filas));
        malos++;
      }
    }
    if (!malos) bien.push(Object.keys(A.ARQ).length + ' hojas de ' + (cw*8) + 'x' + (ch*filas) + ' (8 direcciones × ' + filas + ' poses)');
  }

  // ── R5 · ningún personaje se sale de su celda ───────────────────────────────────
  // Antes esta regla exigía un píxel de aire alrededor. Con la celda de 24×32 que fija
  // CONTEXT.md §18.1 eso ya no se puede pedir: el pivote está en (12,30), así que el
  // contorno de los pies cae en la última fila por diseño, y el de un gorro alto en la
  // primera. Lo que hay que vigilar no es tocar el canto sino **salirse** por él, y eso
  // deja una huella inconfundible: un píxel de color en el borde es un píxel al que le
  // recortaron su contorno. El contorno tocando el canto es correcto; la piel, no.
  {
    const [cw, ch] = A.SPR.cel, filas = A.ORDEN_POSES.length;
    const NEG = A.PALETA.find(p => p[3] === A.C.negro) || [0, 0, 0];
    let cortados = 0;
    for (const k of Object.keys(A.ARQ)) {
      const h = A.HOJAS[k] || A.hoja(k), g = h.getContext('2d');
      for (let f = 0; f < filas; f++) for (let d = 0; d < 8; d++) {
        const px = g.getImageData(d*cw, f*ch, cw, ch).data;
        const cortado = (x, y) => {
          const i = (y*cw + x)*4;
          return px[i+3] > 0 && !(px[i] === NEG[0] && px[i+1] === NEG[1] && px[i+2] === NEG[2]);
        };
        let malo = false;
        for (let x = 0; x < cw && !malo; x++) if (cortado(x, 0) || cortado(x, ch-1)) malo = true;
        for (let y = 0; y < ch && !malo; y++) if (cortado(0, y) || cortado(cw-1, y)) malo = true;
        if (malo) {
          if (cortados < 6) fallos.push('hoja ' + k + ': ' + A.ORDEN_POSES[f] + '/' + d + ' se sale de la celda');
          cortados++;
        }
      }
    }
    if (cortados > 6) fallos.push('...y ' + (cortados - 6) + ' fotogramas más recortados');
    if (!cortados) bien.push('ningún fotograma de personaje se sale de su celda de ' + cw + 'x' + ch);
  }

  // ── R6 · los edificios singulares, a su medida y sin transparencias por dentro ──────
  // Cada singular se dibuja encima del tejado genérico, así que un hueco en medio no es un
  // agujero al fondo negro: es el tejado de siempre asomándose por el centro de la
  // catedral. Se le exige que tape su propia silueta y que mida justo lo que dice medir.
  {
    let malos = 0;
    const SING = A.SINGULARES || {};
    for (const [k, s] of Object.entries(SING)) {
      if (s.c.width !== s.w * A.TS || s.c.height !== s.h * A.TS) {
        fallos.push('singular ' + k + ': mide ' + s.c.width + 'x' + s.c.height
          + ', se esperaba ' + (s.w * A.TS) + 'x' + (s.h * A.TS));
        malos++; continue;
      }
      const d = px(s.c);
      let opacos = 0;
      for (let i = 3; i < d.length; i += 4) if (d[i] === 255) opacos++;
      const cubre = opacos / (s.c.width * s.c.height);
      if (cubre < 0.999) {
        fallos.push('singular ' + k + ': solo tapa el ' + Math.round(cubre * 100) + '% de su celda');
        malos++;
      }
    }
    if (!malos) bien.push(Object.keys(SING).length + ' edificios singulares a su medida y tapando su celda');
  }

  bien.forEach(b => console.log('  ok    ' + b));
  if (fallos.length) {
    console.log('');
    fallos.forEach(f => console.log('  FALLO ' + f));
    console.log('\n' + fallos.length + ' fallos de estilo');
    process.exit(1);
  }
  console.log('\nel arte sigue la guía');
  process.exit(0);
});
