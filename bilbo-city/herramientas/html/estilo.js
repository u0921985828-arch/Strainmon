/**
 * Comprueba que todo el arte del juego cumple la guía de estilo (referencia/ESTILO.md).
 *
 *   node herramientas/html/estilo.js
 *
 * Una guía de estilo que nadie comprueba dura dos semanas. Esto la comprueba sobre el
 * arte de verdad, el que se forja al arrancar, y devuelve 1 si algo se ha ido.
 */
require('./arnes.js');

const listo = async () => {
  for (let t = 0; t < 30000; t += 25) {
    const A = global.__;
    if (A && A.TILE && A.ICO && Object.keys(A.TILE).length && Object.keys(A.ICO).length) return;
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
  const todos = obj => Object.entries(obj).flatMap(([k, v]) =>
    Array.isArray(v) ? v.map((c, i) => [k + '[' + i + ']', c]) : [[k, v]]);

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
    if (!malos && !medias) bien.push('todo el arte dentro de los ' + A.PALETA.length + ' colores');
  }

  // ── R2 · los iconos: 24×24, contorno negro y pocos colores ───────────────────────
  {
    const NEG = A.PALETA.find(p => p[3] === '#0b0e12') || [11,14,18];
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
      if (c.width !== 32 || c.height !== 32) { fallos.push('tile ' + k + ': mide ' + c.width + 'x' + c.height); malos++; continue; }
      const d = px(c);
      let huecos = 0;
      for (let i = 3; i < d.length; i += 4) if (d[i] < 255) huecos++;
      // El suelo no tiene agujeros: por un hueco se ve el negro del fondo y aparece una
      // rejilla de puntos por toda la ciudad.
      if (huecos) { fallos.push('tile ' + k + ': ' + huecos + ' píxeles transparentes'); malos++; }
    }
    if (!malos) bien.push((todos(A.TILE).length - A.TILE_MUEBLE.size) + ' tiles de suelo a 32x32 y sin agujeros');
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
