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

  // ── R7 · la interfaz, del mismo juego que la calle ─────────────────────────────
  // Las reglas de «Interfaz», «Color» y «Tipografía» de la guía no las comprobaba nadie,
  // y la hoja de estilo se había ido por su cuenta: siete colores inventados, la
  // tipografía del sistema, bordes de 1 px, esquinas redondeadas, degradados suaves y
  // sombras desenfocadas. Nada de eso existe en el juego que hay detrás, y la pantalla
  // parecía de dos sitios. Esto se mira sobre el CSS de verdad, no sobre el arte.
  {
    const html = require('fs').readFileSync(require('path').join(__dirname, '..', '..',
      'referencia', 'bilbo-city.html'), 'utf8');
    const css = html.slice(html.indexOf('<style>') + 7, html.indexOf('</style>'));
    // Sin comentarios: dentro hay ejemplos de lo que ya no se hace, y acusarían al texto
    // que explica por qué no se hace.
    const limpio = css.replace(/\/\*[\s\S]*?\*\//g, '');
    const linea = i => css.slice(0, i).split('\n').length;
    const pon = (i, t) => fallos.push('estilo, línea ' + linea(i) + ': ' + t);
    const antes = fallos.length;

    const PAL = new Set(A.PALETA.map(p => '#' + [p[0], p[1], p[2]]
      .map(v => v.toString(16).padStart(2, '0')).join('')));
    for (const m of limpio.matchAll(/#[0-9a-fA-F]{6}\b/g))
      if (!PAL.has(m[0].toLowerCase())) pon(m.index, m[0] + ' no está en la paleta');
    for (const m of limpio.matchAll(/\b(rgba?|hsla?)\(/g))
      pon(m.index, m[1] + '() — el color sale de la paleta, no de una mezcla');
    // La tipografía es BLOQUE o no es: una condensada del sistema al lado del HUD canta.
    for (const m of limpio.matchAll(/font-family:\s*([^;}]+)/g))
      if (!/^BLOQUE\b/.test(m[1].trim())) pon(m.index, 'font-family sin BLOQUE delante');
    // Ocho píxeles del dibujo son un em, así que solo las escalas enteras 1..4 caen en
    // la rejilla. Un 15 saca unas filas del glifo del doble de alto que otras.
    for (const m of limpio.matchAll(/font-size:\s*([0-9.]+)px/g))
      if (!['0', '8', '16', '24', '32'].includes(m[1]))
        pon(m.index, 'font-size ' + m[1] + 'px — las escalas enteras son 8, 16, 24 y 32');
    for (const m of limpio.matchAll(/border-radius:\s*([^;}]+)/g))
      if (m[1].trim() !== '0') pon(m.index, 'border-radius ' + m[1].trim() + ' — nada redondeado');
    for (const m of limpio.matchAll(/border(?:-(?:top|right|bottom|left|width))?:\s*([0-9.]+)px/g))
      if (Number(m[1]) < 2) pon(m.index, 'borde de ' + m[1] + 'px — a la resolución de un móvil desaparece');
    // Un degradado suave no existe en pixel art. El de tope duro sí: es la trama de
    // rayas de los paneles, que son dos colores planos y ningún tono intermedio.
    for (const m of limpio.matchAll(/(?<!repeating-)(linear|radial|conic)-gradient/g))
      pon(m.index, m[0] + ' — un degradado suave no está en la paleta');
    // Una sombra con desenfoque es un borde a medio tono, que es lo mismo que un píxel
    // a medio transparente. La sombra dura —el tercer valor a cero— sí es del juego.
    for (const m of limpio.matchAll(/box-shadow:\s*([^;}]+)/g))
      for (const cap of m[1].split(','))
        { // El cero va sin unidad la mitad de las veces: '0 0 0 8px' y '0 0 6px 8px'
          // solo se distinguen si el tercer valor se lee con el px opcional.
          const n = cap.trim().replace(/^inset\s+/, '')
            .match(/^(-?[0-9.]+)(?:px)?\s+(-?[0-9.]+)(?:px)?(?:\s+(-?[0-9.]+)(?:px)?)?/);
          if (n && n[3] && Number(n[3]) !== 0) pon(m.index, 'box-shadow con ' + n[3] + 'px de desenfoque'); }
    // Rejilla de 4: márgenes, separaciones y relleno. Los anchos no, que el hueco del
    // icono mide 30 porque el icono mide 24 más dos de canto por lado.
    for (const m of limpio.matchAll(/\b(padding|margin|gap)(?:-(?:top|right|bottom|left))?:\s*([^;}]+)/g))
      for (const v of m[2].match(/-?[0-9.]+px/g) || [])
        if (Number(v.replace('px', '')) % 4) pon(m.index, m[1] + ' de ' + v + ' — la rejilla es de 4');

    // Y lo que se enseña tiene que existir en la fuente: un emoji del sistema lo dibuja
    // cada móvil a su manera, y un carácter que BLOQUE no tiene sale de interrogación.
    const cuerpo = html.slice(html.indexOf('<body>'), html.indexOf('<script>'));
    const falta = new Set();
    for (const ch of cuerpo.replace(/<[^>]*>/g, '').replace(/\s/g, ''))
      if (!A.GLIFOS_B[ch] && !A.GLIFOS_B[ch.toUpperCase()]) falta.add(ch);
    if (falta.size) fallos.push('la interfaz enseña ' + [...falta].join(' ') + ', que BLOQUE no dibuja');

    if (fallos.length === antes)
      bien.push('la hoja de estilo, en la paleta, con BLOQUE y sin un borde de 1 px');
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
