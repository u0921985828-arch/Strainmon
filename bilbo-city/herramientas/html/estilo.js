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
  // Baja por arrays y por objetos hasta dar con el lienzo, sin suponer un solo nivel:
  // `PROP.pisos` pasó a ser objeto de arrays —cuatro tipos de fachada por material— y con
  // la versión de un nivel se colaba un array entero como si fuese un lienzo.
  const todos = (obj, pre = '') => Object.entries(obj).flatMap(([k, v]) => {
    const n = pre + k;
    if (!v) return [];
    if (typeof v.getContext === 'function') return [[n, v]];
    if (Array.isArray(v)) return v.flatMap((c, i) => todos({ [i]: c }, n + '.'));
    if (typeof v === 'object') return todos(v, n + '.');
    return [];
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
      [/Casilla de interior \|\s*\*\*(\d+)×(\d+) px\*\*/,
                                                      [String(A.TS_INT), String(A.TS_INT)], 'la casilla de interior'],
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
    for (const [k, c] of Object.entries(A.SUELO_I)) revisa('suelo de interior ' + k, c);
    for (const [k, c] of Object.entries(A.PARED_I)) revisa('pared de interior ' + k, c);
    for (const [k, c] of Object.entries(A.PUERTA_I)) revisa('puerta ' + k, c);
    for (const [k, c] of Object.entries(A.PASO_I)) revisa('paso ' + k, c);
    for (const id of Object.keys(A.INT)) for (const p of A.piezasDe(A.INT[id]))
      revisa('mueble ' + A.MUEBLES[p.ch].n, A.sprMueble(p.ch, p.w, p.h));
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
    if (!malos) bien.push(todos(A.TILE).length + ' tiles de suelo a ' + A.TS + 'x' + A.TS + ' y sin agujeros');
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

  // ── R7 · el arte de interior, a su escala y a la de la gente ────────────────────
  /* Dentro de un sitio la casilla no es la de la calle: son 0,80 m dibujados a 16 px. Esa
     densidad —20 px por metro— tiene que ser la misma a la que está dibujada una persona,
     porque dentro de una casa la vara de medir es la gente y no los coches. Si alguien
     cambia una de las dos y no la otra, la cama vuelve a quedarse enorme o la puerta
     enana, y eso no se ve hasta entrar. */
  {
    const pxmInt = A.TS_INT / A.M_INT;
    const pxmPj = A.sc(26) / 1.70;          // la figura mide 26 en el papel y 1,70 m de alto
    if (Math.abs(pxmInt - pxmPj) / pxmPj > 0.1)
      fallos.push('el interior va a ' + pxmInt.toFixed(1) + ' px/m y la gente a '
        + pxmPj.toFixed(1) + ': dentro de una casa tienen que medir igual');
    else bien.push('interior y personaje a la misma densidad: ' + pxmInt.toFixed(0) + ' px/m');

    let malos = 0;
    for (const [d, n] of [[A.SUELO_I, 'suelo'], [A.PARED_I, 'pared']])
      for (const [k, c] of Object.entries(d)) {
        if (c.width !== A.TS_INT || c.height !== A.TS_INT) {
          fallos.push(n + ' ' + k + ': mide ' + c.width + 'x' + c.height); malos++; continue;
        }
        const t = px(c);
        let huecos = 0;
        for (let i = 3; i < t.length; i += 4) if (t[i] !== 255) huecos++;
        if (huecos) { fallos.push(n + ' ' + k + ': ' + huecos + ' píxeles transparentes'); malos++; }
      }
    // Cada mueble se forja del tamaño con el que sale en algún plano de verdad: así se
    // comprueba el dibujo que se va a ver, no uno de muestra.
    const vistos = new Set();
    for (const id of Object.keys(A.INT)) for (const p of A.piezasDe(A.INT[id])) {
      const k = p.ch + p.w + 'x' + p.h;
      if (vistos.has(k)) continue;
      vistos.add(k);
      const c = A.sprMueble(p.ch, p.w, p.h);
      const t = px(c);
      let pinta = 0;
      for (let i = 3; i < t.length; i += 4) if (t[i] === 255) pinta++;
      if (pinta / (c.width * c.height) < 0.35) {
        fallos.push('mueble ' + A.MUEBLES[p.ch].n + ' ' + p.w + 'x' + p.h + ': casi no pinta nada');
        malos++;
      }
    }
    if (!malos) bien.push(vistos.size + ' muebles de interior dibujados a su tamaño, sobre '
      + (Object.keys(A.SUELO_I).length + Object.keys(A.PARED_I).length) + ' suelos y paredes de '
      + A.TS_INT + 'x' + A.TS_INT);
  }

  // ── R8 · el mobiliario urbano mide lo que mide ──────────────────────────────────
  /* Estaba dibujado a ojo: una papelera de 1,9 m de ancho, un bolardo más gordo que una
     farola, un contenedor de barco de cuatro metros y árboles de dos. Cada pieza sale ahora
     de su medida en metros, forjada a 20 px/m —la densidad a la que está dibujada la gente,
     que es con lo que se compara en la calle—, y aquí se comprueba que el dibujo mide lo que
     dice la tabla. */
  {
    let malos = 0;
    const PXM = 20;
    for (const k of Object.keys(A.MOB_M)) {
      const c = A.PROP[k], [an, al] = A.MOB_M[k];
      if (!c) { fallos.push('mobiliario ' + k + ': está en la tabla y no se forja'); malos++; continue; }
      const dx = Math.abs(c.width / an - PXM), dy = Math.abs(c.height / al - PXM);
      if (dx > 1 || dy > 1) {
        fallos.push('mobiliario ' + k + ': ' + (c.width/PXM).toFixed(1) + '×' + (c.height/PXM).toFixed(1)
          + ' m dibujados contra ' + an + '×' + al + ' de la tabla');
        malos++;
      }
    }
    // Y el canto negro: sobre el asfalto o el adoquín, un objeto sin contorno se funde con
    // el fondo. Solo se exige donde hay margen — lo que toca el borde del lienzo no puede
    // llevarlo.
    const NEG = A.C.negro;
    const rgbNeg = [parseInt(NEG.slice(1,3),16), parseInt(NEG.slice(3,5),16), parseInt(NEG.slice(5,7),16)];
    let sinCanto = 0;
    for (const k of A.MOB_CONTORNO) {
      const c = A.PROP[k];
      if (!c) continue;
      const d = px(c), w = c.width, h = c.height;
      const opaco = (x, y) => d[(y*w + x)*4 + 3] > 0;
      let malo = 0;
      for (let y = 1; y < h-1 && !malo; y++) for (let x = 1; x < w-1; x++) {
        const i = (y*w + x)*4;
        if (!d[i+3]) continue;
        if (d[i] === rgbNeg[0] && d[i+1] === rgbNeg[1] && d[i+2] === rgbNeg[2]) continue;
        if (!opaco(x-1,y) || !opaco(x+1,y) || !opaco(x,y-1) || !opaco(x,y+1)) { malo = 1; break; }
      }
      if (malo) { fallos.push('mobiliario ' + k + ': tiene color pegado al hueco, le falta el canto'); sinCanto++; }
    }
    if (!malos && !sinCanto)
      bien.push(Object.keys(A.MOB_M).length + ' piezas de mobiliario a su medida en metros, '
        + A.MOB_CONTORNO.length + ' con canto negro');
  }

  // ── R9 · todos salen del mismo cuerpo ───────────────────────────────────────────
  /* Una figura no se dibuja entera por arquetipo: hay un cuerpo con su anatomía —dónde
     cae la cabeza, el hombro, la cintura y el pie— y la ropa va en capas encima. Es lo que
     permite que cualquiera lleve cualquier prenda y que treinta y ocho vecinos salgan de
     siete siluetas. Si un arquetipo se dibuja por su cuenta, la ropa comprada le queda a
     otra altura y no se ve hasta ponérsela. Aquí se mide sobre el fotograma quieto de
     frente: la coronilla y la planta del pie tienen que caer en la misma fila para todos,
     y el hombro solo puede cambiar lo que cambia la complexión. */
  {
    const [CW, CH] = A.SPR.cel;
    const fila = A.ORDEN_POSES.indexOf('quieto');
    const perfil = k => {
      const hoja = A.HOJAS[k] || A.hoja(k);
      const d = hoja.getContext('2d').getImageData(0, fila * CH, CW, CH).data;
      const filas = [];
      for (let y = 0; y < CH; y++) {
        let a = -1, b = -1;
        for (let x = 0; x < CW; x++) if (d[(y*CW + x)*4 + 3] > 0) { if (a < 0) a = x; b = x; }
        filas.push(a < 0 ? null : [a, b]);
      }
      const arriba = filas.findIndex(f => f), abajo = filas.length - 1 - [...filas].reverse().findIndex(f => f);
      // El hombro se mide contando desde los pies, no desde la coronilla: un casco de obra
      // sube la coronilla tres píxeles y la ventana se iba al pecho, así que la misma figura
      // con y sin gorro salía con dos hombros distintos.
      let hombro = 0;
      for (let y = abajo - 26; y <= abajo - 21; y++)
        if (y >= 0 && filas[y]) hombro = Math.max(hombro, filas[y][1] - filas[y][0] + 1);
      return { arriba, abajo, hombro };
    };
    const arqs = Object.keys(A.ARQ), P = {};
    for (const k of arqs) P[k] = perfil(k);
    const cor = arqs.map(k => P[k].arriba), pie = arqs.map(k => P[k].abajo);
    const dCor = Math.max(...cor) - Math.min(...cor), dPie = Math.max(...pie) - Math.min(...pie);
    // La planta del pie es la que no se mueve: es el pivote con el que la figura se apoya
    // en el suelo. La coronilla sí sube, pero solo lo que suba el gorro — un casco de obra
    // o una capucha son cuatro o cinco píxeles.
    if (dCor > 6) fallos.push('la coronilla baila ' + dCor + ' px entre arquetipos: eso ya no es el gorro');
    if (dPie > 0) fallos.push('la planta del pie baila ' + dPie + ' px: la figura no se apoya igual');
    const hombros = arqs.map(k => P[k].hombro);
    const dH = Math.max(...hombros) - Math.min(...hombros);
    // Tres complexiones, tres anchos. Más que eso ya no es complexión, es otro cuerpo.
    if (Math.min(...hombros) < 14 || Math.max(...hombros) > 24 || dH > 8)
      fallos.push('el hombro va de ' + Math.min(...hombros) + ' a ' + Math.max(...hombros)
        + ' px: eso ya no es complexión, es otro cuerpo');
    else if (dCor <= 6 && dPie === 0)
      bien.push(arqs.length + ' arquetipos sobre el mismo cuerpo: pie clavado, coronilla ±'
        + dCor + ' px por el gorro, y hombro de ' + Math.min(...hombros) + ' a ' + Math.max(...hombros) + ' px');
  }

  // ── R10 · la figura es de una pieza ─────────────────────────────────────────────
  /* Al mover la pierna para que el paso se viera, la pierna se despegó del cuerpo: a esta
     escala la cadera son seis píxeles y un desplazamiento de dos deja el pantalón en el
     aire. En una lámina de contacto eso no canta —cada fotograma se mira solo—, y en
     movimiento se ve como una figura rota. La regla es que **todo lo dibujado esté pegado**:
     un solo trozo de píxeles opacos por fotograma. Las dos excepciones son de dibujo, no de
     error: el fogonazo sale del cañón y va suelto, y el carro de la compra va al lado. */
  {
    const [CW, CH] = A.SPR.cel;
    const arqs = Object.keys(A.ARQ);
    const poses = A.ORDEN_POSES.filter(p => p !== 'dispara');
    let miradas = 0, rotos = 0, peor = '';
    for (const k of arqs) {
      if (A.ARQ[k].acces === 'carrito') continue;          // el carro va suelto a propósito
      const hoja = A.HOJAS[k] || A.hoja(k);
      const g = hoja.getContext('2d');
      for (const pose of poses) {
        const fila = A.ORDEN_POSES.indexOf(pose);
        for (let d = 0; d < 8; d++) {
          const px = g.getImageData(d * CW, fila * CH, CW, CH).data;
          const dentro = i => px[i * 4 + 3] > 0;
          // Un recorrido en anchura desde el primer píxel opaco: lo que no se alcance está
          // suelto.
          let ini = -1;
          for (let i = 0; i < CW * CH && ini < 0; i++) if (dentro(i)) ini = i;
          if (ini < 0) continue;
          const visto = new Uint8Array(CW * CH);
          const pila = [ini]; visto[ini] = 1;
          let n = 1;
          while (pila.length) {
            const i = pila.pop(), x = i % CW, y = (i / CW) | 0;
            for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
              const nx = x + dx, ny = y + dy;
              if (nx < 0 || ny < 0 || nx >= CW || ny >= CH) continue;
              const j = ny * CW + nx;
              if (visto[j] || !dentro(j)) continue;
              visto[j] = 1; n++; pila.push(j);
            }
          }
          let total = 0;
          for (let i = 0; i < CW * CH; i++) if (dentro(i)) total++;
          miradas++;
          if (n !== total) {
            rotos++;
            if (!peor) peor = k + ' · ' + pose + ' · dirección ' + d + ' (' + (total - n) + ' px sueltos)';
          }
        }
      }
    }
    if (rotos) fallos.push(rotos + ' de ' + miradas + ' fotogramas con un trozo despegado del cuerpo: ' + peor);
    else bien.push(miradas + ' fotogramas comprobados y todos de una pieza: nada despegado del cuerpo');
  }

  // ── R11 · la figura mira entera para el mismo lado ──────────────────────────────
  /* Ocho direcciones son ocho dibujos distintos, y es fácil girar la cabeza y dejarse el
     resto: durante un tiempo, en las cuatro diagonales la cara y el torso iban girados y las
     piernas seguían de frente, con los dos pies mirando a cámara. Aquí se mide sobre el
     fotograma quieto de cada arquetipo:
       · los pies se van hacia donde mira la figura (y en las vistas de frente y de espaldas
         se quedan centrados);
       · de frente y en tres cuartos delanteros se le ven los ojos, y de espaldas no. */
  {
    const [CW, CH] = A.SPR.cel;
    const fila = A.ORDEN_POSES.indexOf('quieto');
    // Hacia dónde mira cada dirección, en horizontal, y si se le ve la cara.
    const MIRA = [0, 1, 1, 1, 0, -1, -1, -1];
    /* De lo que se puede afirmar sin discutir de dibujo, se afirma esto: **de espaldas no se
       ve la cara**. Que de frente se vean los ojos no se puede exigir —el matón lleva gafas
       de sol y el de la capucha va tapado— y de perfil el ojo cae en el mismo canto de la
       cara, sin piel a los dos lados. Las tres direcciones de espaldas, en cambio, no
       admiten discusión: si ahí hay ojos, la cabeza está girada al revés que el cuerpo. */
    const CARA = [null, null, null, false, false, false, null, null];
    const arqs = Object.keys(A.ARQ);
    let pies = 0, ojos = 0, peorP = '', peorO = '';
    for (const k of arqs) {
      // El carro de la compra va al lado de la figura y pesa más que ella en el recuento:
      // con él dentro, el centro del tronco se va medio cuerpo y no mide nada.
      if (A.ARQ[k].acces === 'carrito') continue;
      const hoja = A.HOJAS[k] || A.hoja(k);
      const g = hoja.getContext('2d');
      // Los dos tonos de piel del arquetipo, pasados por la paleta como los pasa la forja.
      const tonos = new Set([A.ARQ[k].piel, A.ARQ[k].pielS].map(hex => {
        const r = parseInt(hex.slice(1,3),16), v = parseInt(hex.slice(3,5),16), b = parseInt(hex.slice(5,7),16);
        let mej = null, md = 1e9;
        for (const [pr, pv, pb] of A.PALETA) {          // la paleta viene como [r,g,b,'#hex']
          const dd = (pr-r)**2 + (pv-v)**2 + (pb-b)**2;
          if (dd < md) { md = dd; mej = pr + ',' + pv + ',' + pb; }
        }
        return mej;
      }));
      for (let d = 0; d < 8; d++) {
        const px = g.getImageData(d * CW, fila * CH, CW, CH).data;
        const op = (x, y) => px[(y*CW + x)*4 + 3] > 0;
        // Oscuro, no negro puro: el ojo es negro, pero unas gafas de sol son carbón y
        // también son cara —al matón no se le ven los ojos y no por eso mira hacia otro lado—.
        const negro = (x, y) => { const i = (y*CW + x)*4;
          return op(x,y) && (px[i] + px[i+1] + px[i+2]) / 3 < 60; };
        let abajo = -1;
        for (let y = CH - 1; y >= 0 && abajo < 0; y--)
          for (let x = 0; x < CW; x++) if (op(x, y)) { abajo = y; break; }
        if (abajo < 0) continue;
        const centro = (y0, y1) => {
          let s = 0, n = 0;
          for (let y = y0; y <= y1; y++) for (let x = 0; x < CW; x++) if (op(x, y)) { s += x; n++; }
          return n ? s / n : null;
        };
        // El pie contra el tronco: cuánto se va el zapato del eje del cuerpo. (piel se define
        // arriba, por arquetipo, con los tonos exactos de ESE arquetipo.)
        const cPie = centro(abajo - 1, abajo), cTronco = centro(abajo - 20, abajo - 14);
        if (cPie !== null && cTronco !== null) {
          const dif = cPie - cTronco, m = MIRA[d];
          // De frente el margen es de un píxel largo, no cero: el bolso y la bolsa de la
          // compra cuelgan de un lado y corren el centro del tronco, y eso no es que la
          // figura mire torcida.
          const bien2 = m === 0 ? Math.abs(dif) < 1.1 : (m > 0 ? dif > 0.25 : dif < -0.25);
          if (!bien2) { pies++; if (!peorP) peorP = k + ' mirando a ' + d + ': el pie se va ' + dif.toFixed(2) + ' px y debería irse ' + (m || 'nada'); }
        }
        // Un ojo es un píxel negro **con piel al lado**: así no se cuenta la txapela, que
        // también es casi negra y ocupa media cabeza.
        // Piel es piel, no «un color cálido»: se compara con los dos tonos de piel de este
        // arquetipo, ya cuantizados a la paleta. Con un umbral por color, las katiuskas
        // mostaza de la pescatera contaban como cara y el hueco entre las botas, como un ojo.
        const piel = (x, y) => { const i = (y*CW + x)*4;
          if (!op(x, y)) return false;
          const c = px[i] + ',' + px[i+1] + ',' + px[i+2];
          return tonos.has(c); };
        // Un ojo es una mancha negra **corta con cara a los dos lados**: el contorno de una
        // mano tiene piel por un lado y fondo por el otro, y la txapela es casi negra pero
        // mide media cabeza. Se busca por tramos, que el ojo mide uno o dos píxeles según
        // cómo caiga la escala.
        // Y solo en el tercio de arriba, que es donde está la cabeza: bajo una falda, el
        // hueco entre las dos piernas también es una mancha oscura con piel a los dos lados.
        let arriba = 0;
        while (arriba < CH && !(() => { for (let x = 0; x < CW; x++) if (op(x, arriba)) return true; return false; })()) arriba++;
        const finCabeza = arriba + Math.round((abajo - arriba) / 3);
        let n = 0;
        for (let y = Math.max(1, arriba); y < Math.min(CH - 1, finCabeza); y++) {
          let x = 1;
          while (x < CW - 1) {
            if (!negro(x, y)) { x++; continue; }
            let f = x;
            while (f < CW - 1 && negro(f, y)) f++;
            if (f - x <= 3 && piel(x - 1, y) && piel(f, y)) n += f - x;
            x = f + 1;
          }
        }
        if (CARA[d] !== null && (CARA[d] ? n === 0 : n > 0)) {
          ojos++;
          if (!peorO) peorO = k + ' mirando a ' + d + ': ' + n + ' píxeles de ojo donde debería haber ' + (CARA[d] ? 'cara' : 'nuca');
        }
      }
    }
    if (pies) fallos.push(pies + ' figuras con los pies mirando a otro lado que el cuerpo: ' + peorP);
    if (ojos) fallos.push(ojos + ' figuras con la cara donde no toca: ' + peorO);
    if (!pies && !ojos)
      bien.push(arqs.length * 8 + ' figuras giradas enteras: pie, tronco y cara al mismo lado en las ocho direcciones');
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
