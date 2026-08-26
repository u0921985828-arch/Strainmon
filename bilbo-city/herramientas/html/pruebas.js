/**
 * Batería de pruebas del prototipo HTML.
 *
 *   node herramientas/html/pruebas.js
 *
 * Arranca el juego de verdad sobre un DOM simulado con un canvas real, juega la
 * campaña entera, entra y sale de todos los interiores, prueba combate,
 * conducción y muerte, y deja correr el bucle un par de minutos.
 *
 * Si tocas la generación de ciudad o el combate, esto es lo que te dice si has
 * roto algo. Salida distinta de 0 = hay fallos.
 */
const fs = require('fs');
const path = require('path');
require('./arnes.js');

const dormir = ms => new Promise(r => setTimeout(r, ms));
// Esperar un número fijo de milisegundos era una carrera: el arranque forja el arte y
// traza la ciudad, y en cuanto la generación se complicó dejó de caber en el plazo. Se
// espera a que el juego esté listo de verdad.
const listo = async (que = 'btnNuevo:click', topeMs = 20000) => {
  for (let t = 0; t < topeMs; t += 25) {
    if (global.__H && global.__H[que]) return;
    await dormir(25);
  }
  throw new Error('el juego no arrancó en ' + topeMs + ' ms');
};

(async () => {
  await listo();

  const H = global.__H, A = global.__, S = A.S, P = A.player, paso = global.__step;
  const fallos = [];
  const ok = (cond, msg) => { if (!cond) fallos.push(msg); };
  const bien = [];

  (H['btnNuevo:click'] || H['btnCont:click'])();
  paso(60);

  try {
    // ── 0 · el prólogo: llegas de Canarias y conoces el piso ───────────
    /* Una partida nueva no empieza con el piso puesto: empieza en Moyúa, con la bolsa y
       el primo al teléfono. Se juega entera aquí porque es lo único que ve sí o sí un
       jugador nuevo, y porque va montada sobre el motor de misiones: cualquier cambio
       ahí se la lleva por delante sin que nada más se entere. */
    {
      ok(S.prologo === 1, 'una partida nueva no arranca el prólogo');
      ok(!!S.mision && S.mision.def.prologo, 'el prólogo no monta sus pasos');
      const moy = A.poi('moyua').p;
      ok(Math.hypot(P.x - moy.x, P.y - moy.y) < 3, 'no se llega a Bilbao por Moyúa');
      ok(A.poi('piso').n === 'Piso de Yeray', 'el piso es tuyo antes de que te den la llave');
      // La llamada del primo deja el diálogo abierto, y con diálogo abierto el bucle no
      // mira los objetivos: hay que colgar, igual que cuelga el jugador.
      A.cerrarDlg();
      const o = A.objetivo(); P.x = o.x; P.y = o.y; paso(8);
      const p = A.pasoActual();
      ok(!!p && p.t === 'entrar' && p.poi === 'piso', 'llegar a Santutxu no cierra el primer paso');
      A.entrar('piso', { x: P.x, y: P.y }, 'Tu piso', 'piso'); await dormir(280); paso(8);
      ok(S.prologo === 0 && !S.mision, 'entrar en el piso no cierra el prólogo');
      ok(A.poi('piso').n === 'Tu piso', 'el piso no pasa a ser tuyo al instalarte');
      const primo = (S.interior.npcs || []).find(n => n.tipo === 'primo');
      ok(!!primo, 'el primo no está en el piso compartido');
      // Vive en el de Santutxu, no en los que se compran: la plantilla no se toca.
      ok(A.INT.piso.npcs.length === 0, 'el primo se queda pegado a la plantilla del piso');
      A.cerrarDlg(); A.salir(); await dormir(280); paso(8);
      if (primo) bien.push('el prólogo: Moyúa, metro a Santutxu y el piso de ' + primo.n);
    }

    // ── 1 · la campaña entera ──────────────────────────────────────────
    for (let k = 0; k < A.MISIONES.length; k++) {
      S.misionIdx = k; S.hp = 100; S.muerto = 0;
      A.empezarMision(A.MISIONES[k]);
      let guarda = 0;
      while (S.mision && guarda++ < 40) {
        // S.hp = 100 no basta para deshacer un K.O.: deja S.muerto contando, y mientras
        // corre, act() vuelve antes de comprobar objetivos. Al agotarse manda al hospital y
        // da la misión por fallada — daba un rojo intermitente en la última, la más larga.
        A.cerrarDlg(); S.estrellas = 0; A.policia.length = 0; S.hp = 100; S.muerto = 0;
        const p = S.mision.pasos[S.mision.paso];
        if (p.t === 'matar') {
          for (const e of A.enemigos) if (e.mision) e.hp = 0;
          A.avanzarPaso();
        } else {
          const o = A.objetivo();
          if (o) { P.x = o.x; P.y = o.y; }
          if (p.t === 'irCoche' || p.t === 'entregarCoche' || p.t === 'robar') A.avanzarPaso();
          else paso(8);
        }
        paso(4);
      }
      ok(S.misionIdx === k + 1, 'misión no completable: ' + A.MISIONES[k].n);
    }
    bien.push(A.MISIONES.length + ' misiones completadas');
    A.cerrarDlg();

    // ── 1 bis · las misiones mandan a sitios alcanzables ───────────────
    // La prueba de arriba teletransporta al jugador al objetivo, así que da igual lo
    // lejos que esté: una misión imposible la pasa igual. Aquí se miden las distancias
    // de verdad. Hizo falta al crecer el mapa: «La entrega grande» repartía por tres
    // puntos al azar del término municipal con dos minutos por parada, que con 448
    // casillas colaba y con 1440 es mandar a alguien a Zorrotza y darle tiempo de nada.
    {
      // Cruzar la ciudad en coche es normal en un juego así —el jugador tiene el suyo
      // aparcado en el portal desde el minuto uno—, así que el tope suelto es generoso:
      // lo que no vale es cruzarla contrarreloj. Ahí se mide de verdad.
      const VEL = 5;          // casillas por segundo conduciendo, medido en la prueba 7
      const TOPE = 700;       // ~3,6 km, media ciudad; más que eso es que algo se ha ido
      let malas = 0;
      for (const def of A.MISIONES) {
        let ox = P.x, oy = P.y;
        for (const p of def.pasos()) {
          const q = p.p || (p.coche && { x: p.coche.x, y: p.coche.y });
          if (!q) continue;
          const d = Math.hypot(q.x - ox, q.y - oy);
          if (d > TOPE) {
            malas++;
            fallos.push(def.n + ': «' + p.txt + '» a ' + Math.round(d) + ' casillas');
          } else if (p.limite && d > p.limite * VEL) {
            malas++;
            fallos.push(def.n + ': «' + p.txt + '» a ' + Math.round(d)
              + ' casillas con solo ' + p.limite + ' s');
          }
          ox = q.x; oy = q.y;
        }
      }
      if (!malas) bien.push(A.MISIONES.length + ' misiones con destinos alcanzables');
    }

    // ── 2 · interiores ─────────────────────────────────────────────────
    // La lista sale del juego, no de aquí: un interior nuevo se prueba solo.
    const interiores = Object.keys(A.INT);
    // Las medidas de verdad de cada mueble, en metros. Sin esto un plano nuevo puede
    // tener una cama de cinco metros o una puerta por la que no pasa nadie, y no se ve
    // hasta entrar — que es exactamente lo que pasaba cuando el interior iba con la
    // casilla de la calle.
    const MEDIDAS = {           // [ancho mín, ancho máx, largo mín, largo máx] en metros
      C: [0.8, 1.6, 1.6, 2.4], M: [0.8, 2.4, 0.8, 2.4], S: [0.8, 0.8, 0.8, 0.8],
      N: [0.8, 1.6, 0.8, 1.6], T: [0.8, 0.8, 0.8, 0.8], V: [0.8, 0.8, 0.8, 0.8],
      H: [0.8, 1.6, 0.8, 1.6], U: [0.8, 0.8, 0.8, 0.8], L: [0.8, 0.8, 1.6, 2.4],
      Z: [1.6, 1.6, 4.0, 4.0], F: [0.8, 0.8, 1.6, 3.2], J: [0.8, 0.8, 0.8, 0.8],
    };
    let metros = [];
    for (const id of interiores) {
      const d = A.INT[id], m = d.mapa, ih = m.length, iw = m[0].length;
      // La alfombra se pisa aunque se dibuje: para andar cuenta como suelo.
      const suelo = ch => A.BLANDO_I.includes(ch) || A.PISABLE_I.includes(ch);
      ok(m.every(f => f.length === iw), id + ': filas de distinto largo');
      ok(m[0].split('').every(c => c === '#') && m.every(f => f[0] === '#' && f[iw-1] === '#'),
         id + ': el muro de fuera tiene un hueco');
      // La puerta: entre 0,8 m (una de casa) y 3,2 m (el portón de un taller), de una pieza.
      const ds = [];
      for (let y = 0; y < ih; y++) for (let x = 0; x < iw; x++) if (m[y][x] === 'D') ds.push([x, y]);
      ok(ds.length >= 1 && ds.length <= 4, id + ': puerta de ' + (ds.length * A.M_INT).toFixed(1) + ' m');
      ok(ds.every(([, y]) => y === ih - 1), id + ': la salida no está en el muro de abajo');
      // Todo el suelo tiene que ser alcanzable desde delante de la puerta. Una habitación
      // sellada por un mueble no se ve dibujando el plano: se ve cuando no puedes entrar.
      if (ds.length) {
        const ini = [ds[0][0], ds[0][1] - 1], vis = new Set([ini.join()]), q = [ini];
        ok(suelo(m[ini[1]][ini[0]]), id + ': delante de la puerta hay un mueble');
        while (q.length) {
          const [x, y] = q.shift();
          for (const [a, b] of [[1,0],[-1,0],[0,1],[0,-1]]) {
            const nx = x + a, ny = y + b, k = nx + ',' + ny;
            if (nx >= 0 && ny >= 0 && nx < iw && ny < ih && !vis.has(k) && suelo(m[ny][nx])) {
              vis.add(k); q.push([nx, ny]);
            }
          }
        }
        let sueltas = 0;
        for (let y = 0; y < ih; y++) for (let x = 0; x < iw; x++)
          if (suelo(m[y][x]) && !vis.has(x + ',' + y)) sueltas++;
        ok(!sueltas, id + ': ' + sueltas + ' casillas de suelo sin manera de llegar');
        // Y a cada dependiente se le tiene que poder hablar, que para eso está.
        for (const n of d.npcs) {
          const k = Math.floor(n.x) + ',' + Math.floor(n.y);
          ok(suelo(m[Math.floor(n.y)][Math.floor(n.x)]),
             id + ': ' + n.n + ' está dentro de un «' + m[Math.floor(n.y)][Math.floor(n.x)] + '»');
          ok(vis.has(k), id + ': a ' + n.n + ' no se llega desde la puerta');
        }
      }
      for (const p of A.piezasDe(d)) {
        ok(!!A.MUEBLES[p.ch], id + ': el mueble «' + p.ch + '» no tiene dibujo');
        const md = MEDIDAS[p.ch];
        if (!md) continue;
        const an = Math.min(p.w, p.h) * A.M_INT, la = Math.max(p.w, p.h) * A.M_INT;
        const E = 1e-6;   // 3 × 0,8 no da 2,4 exacto en coma flotante
        ok(an >= md[0]-E && an <= md[1]+E && la >= md[2]-E && la <= md[3]+E,
           id + ': ' + A.MUEBLES[p.ch].n + ' de ' + an.toFixed(1) + '×' + la.toFixed(1) + ' m');
      }
      metros.push(Math.round(iw * ih * A.M_INT * A.M_INT));
      A.entrar(id, { x: P.x, y: P.y }); await dormir(280); paso(8);
      ok(S.escena === 'interior', 'no se entra en ' + id);
      A.salir(); await dormir(280); paso(8);
      ok(S.escena === 'ciudad', 'no se sale de ' + id);
    }
    bien.push(interiores.length + ' interiores a escala humana: casilla de ' + A.M_INT
      + ' m, de ' + Math.min(...metros) + ' a ' + Math.max(...metros) + ' m², sin cuartos sellados');

    // ── 1 ter · la calle: bordillo, pasos y mobiliario ─────────────────
    /* El mobiliario iba sembrado por hash sobre cualquier acera y no había un solo paso
       de cebra en toda la ciudad. Lo que se mide aquí es que cada cosa esté donde va: el
       paso, en la calzada y en la bocacalle; la farola, en la fila del bordillo y a la
       distancia a la que se ponen; el semáforo, en una esquina con paso al lado. */
    {
      const MOB = A.MOB, MW = A.MW, MH = A.MH;
      const T = (x, y) => A.Tc(x, y);
      let cebra = 0, mob = 0, fuera = 0, cebraMal = 0, semSuelto = 0;
      let stop = 0, aparca = 0, pinturaMal = 0;
      const cuenta = {};
      for (let y = 1; y < MH-1; y++) for (let x = 1; x < MW-1; x++) {
        const v = MOB[y*MW + x];
        if (!v) continue;
        cuenta[v] = (cuenta[v] || 0) + 1;
        // Del 200 arriba es suelo pintado, no mueble: paso de cebra, línea de detención y
        // plaza de aparcamiento. Todo eso va sobre la calzada y en ningún otro sitio.
        if (v >= 200) {
          if (v === 200 || v === 201) cebra++;
          else if (v < 206) stop++; else aparca++;
          if (T(x, y) !== A.ROAD) { cebraMal += (v < 202 ? 1 : 0); pinturaMal++; }
          continue;
        }
        mob++;
        // Todo el mobiliario va en la acera y tocando calzada: una farola en mitad de la
        // acera ancha es una farola en mitad del paso.
        const bordillo = T(x+1,y) === A.ROAD || T(x-1,y) === A.ROAD
                      || T(x,y+1) === A.ROAD || T(x,y-1) === A.ROAD;
        if (T(x, y) !== A.ACERA || !bordillo) fuera++;
        if (v === 6) {   // semáforo
          const cebra = c => c === 200 || c === 201;
          const hayPaso = cebra(MOB[(y-1)*MW+x]) || cebra(MOB[(y+1)*MW+x])
                       || cebra(MOB[y*MW+x+1]) || cebra(MOB[y*MW+x-1]);
          if (!hayPaso) semSuelto++;
        }
      }
      ok(cebra > 2000, 'solo ' + cebra + ' pasos de cebra en toda la ciudad');
      ok(!cebraMal, cebraMal + ' pasos de cebra pintados fuera de la calzada');
      ok(!fuera, fuera + ' muebles de calle lejos del bordillo');
      ok(!semSuelto, semSuelto + ' semáforos sin un paso al lado');
      ok(!pinturaMal, pinturaMal + ' marcas viales pintadas fuera de la calzada');
      ok(stop > 2000, 'solo ' + stop + ' líneas de detención para ' + cebra + ' pasos');
      ok(aparca > 5000, 'solo ' + aparca + ' plazas de aparcamiento marcadas');
      // Una línea de detención sin su paso al lado es pintura suelta en mitad de la calle.
      {
        let stopSuelta = 0;
        const lados = [[0,0,-1],[1,0,1],[2,-1,0],[3,1,0]];
        for (let y = 1; y < MH-1; y++) for (let x = 1; x < MW-1; x++) {
          const v = MOB[y*MW+x];
          if (v < 202 || v >= 206) continue;
          const [, dx, dy] = lados[v - 202];
          const vec = MOB[(y+dy)*MW + x+dx];
          if (vec !== 200 && vec !== 201) stopSuelta++;
        }
        ok(!stopSuelta, stopSuelta + ' líneas de detención sin paso de cebra delante');
      }
      // La separación entre farolas: en Bilbao hay una cada 25-30 m, y la casilla mide
      // 5,16. Se mide sobre la fila del bordillo entera, que es donde van: cuántas casillas
      // de bordillo hay por farola.
      let kerb = 0;
      for (let y = 1; y < MH-1; y++) for (let x = 1; x < MW-1; x++) {
        if (T(x,y) !== A.ACERA) continue;
        if (T(x+1,y) === A.ROAD || T(x-1,y) === A.ROAD
         || T(x,y+1) === A.ROAD || T(x,y-1) === A.ROAD) kerb++;
      }
      const sep = (cuenta[1] ? kerb / cuenta[1] : 0) * 5.16;
      ok(sep > 15 && sep < 45, 'las farolas van cada ' + sep.toFixed(0) + ' m');
      bien.push(cebra + ' pasos de cebra, ' + stop + ' líneas de detención y ' + aparca
        + ' plazas de aparcamiento marcadas · ' + mob + ' muebles de calle en el bordillo · '
        + 'farola cada ' + sep.toFixed(0) + ' m · ' + (cuenta[6]||0) + ' semáforos, '
        + (cuenta[7]||0) + ' árboles de alineación, ' + (cuenta[9]||0) + ' marquesinas');
    }

    // ── 1 ter bis · los coches aparcan en su plaza ─────────────────────
    /* Los cuarenta coches aparcados se soltaban en cualquier casilla de calzada y con el
       rumbo de la calle a ojo: salían en mitad del carril y cruzados. Ahora van a una plaza
       marcada, arrimados al bordillo y mirando a donde va la calle. */
    {
      let enPlaza = 0, torcidos = 0, total = 0;
      for (const c of A.coches) {
        if (c.propio) continue;
        total++;
        const x = c.x | 0, y = c.y | 0, mb = A.MOB[y * A.MW + x];
        if (mb < 206 || mb >= 210) continue;
        enPlaza++;
        // Bordillo arriba o abajo quiere decir calle este-oeste, y el coche mira a lo largo.
        const eo = mb - 206 < 2;
        const a2 = Math.abs(Math.sin(c.ang)), tumbado = a2 < 0.01, depie = a2 > 0.99;
        if (eo ? !tumbado : !depie) torcidos++;
      }
      ok(total > 20, 'no hay coches aparcados que mirar: ' + total);
      ok(enPlaza >= total - 1, (total - enPlaza) + ' de ' + total + ' coches aparcados fuera de plaza');
      ok(!torcidos, torcidos + ' coches aparcados cruzados en la calle');
      bien.push(enPlaza + ' de ' + total + ' coches aparcados en plaza marcada y en el sentido de la calle');
    }

    // ── 1 ter ter · las gaviotas ───────────────────────────────────────
    /* Bilbao es puerto a catorce kilómetros del mar: hay gaviotas hasta en el Casco. Van
       por la capa de vuelo y planean en círculo, así que lo que se comprueba es que estén,
       que se muevan, que no se queden atrás cuando el jugador se va y que se pinten donde
       les toca — no que hagan un dibujo bonito. */
    {
      S.escena = 'ciudad'; A.cerrarDlg(); P.enCoche = null;
      P.x = 700.5; P.y = 300.5; paso(20);
      ok(A.gaviotas.length === 10, 'no hay gaviotas: ' + A.gaviotas.length);
      const antes = A.gaviotas.map(v => v.x + ',' + v.y);
      paso(20);
      const movidas = A.gaviotas.filter((v, i) => v.x + ',' + v.y !== antes[i]).length;
      ok(movidas === A.gaviotas.length, (A.gaviotas.length - movidas) + ' gaviotas quietas en el aire');
      let lejos = A.gaviotas.filter(v => Math.hypot(v.x - P.x, v.y - P.y) > 22).length;
      ok(!lejos, lejos + ' gaviotas se han quedado fuera de la pantalla sin reciclarse');
      // Y se pintan en vuelo: por encima de la ciudad y por debajo de los rótulos.
      A.gaviotas.forEach((v, i) => { v.cx = P.x + ((i % 3) - 1) * 2; v.cy = P.y; v.r = 0.5; });
      const g = A.real.getContext('2d'), ant = g.drawImage;
      let dibujadas = 0, capas = new Set();
      g.drawImage = function (im, ...r) {
        if (A.AVE.includes(im)) { dibujadas++; capas.add(A.capaAct()); }
        return ant.apply(this, [im, ...r]);
      };
      paso(2);
      g.drawImage = ant;
      ok(dibujadas > 0, 'las gaviotas no se pintan');
      ok(capas.size === 1 && capas.has(A.CAPA.VUELO),
         'las gaviotas se pintan en la capa [' + [...capas].join(',') + '] y no en vuelo');
      bien.push(A.gaviotas.length + ' gaviotas planeando sobre la ría, en la capa de vuelo');
    }

    // ── 1 quater · el sol y la hora ────────────────────────────────────
    /* Desde arriba, la sombra es lo único que dice cuánto levanta un edificio y hasta
       dónde llega su tejado. Antes era fija —siempre abajo y a la derecha, nueve píxeles—
       y a las nueve de la mañana la ciudad se veía igual que a las tres de la tarde. */
    {
      const min0 = S.min;
      const alSol = h => { S.min = h * 60; return { ...A.calcularSol(), luz: A.luzAmbiente() }; };
      const m = alSol(9), t = alSol(14), v = alSol(20), n = alSol(23);
      ok(m.ux < -0.5, 'a las 9 la sombra no cae al oeste (ux ' + m.ux.toFixed(2) + ')');
      ok(t.uy < -0.7 && Math.abs(t.ux) < 0.5,
         'a las 14 la sombra no cae al norte (' + t.ux.toFixed(2) + ',' + t.uy.toFixed(2) + ')');
      ok(v.ux > 0.5, 'a las 20 la sombra no cae al este (ux ' + v.ux.toFixed(2) + ')');
      ok(!n.elev, 'a las 23:00 sigue habiendo sol');
      // Y se alarga cuando el sol baja: es lo que hace que la hora se lea sin reloj.
      S.min = 9 * 60;  A.calcularSol(); const lm = A.largoSombra('denso');
      S.min = 14 * 60; A.calcularSol(); const lt = A.largoSombra('denso');
      ok(lm > lt * 1.5, 'la sombra de las 9 (' + lm.toFixed(1) + ') no es más larga que la de las 14 ('
         + lt.toFixed(1) + ')');
      ok(lt > 0.2 && lm <= 4.01, 'sombras fuera de rango: ' + lt.toFixed(1) + ' a ' + lm.toFixed(1));
      // El tinte: a mediodía no se tiñe nada, de noche azul y a la caída, cálido.
      const l13 = (S.min = 13 * 60, A.luzAmbiente()), l23 = (S.min = 23 * 60, A.luzAmbiente());
      const l20 = (S.min = 20.6 * 60, A.luzAmbiente());
      ok(l13[3] === 0, 'a mediodía la ciudad va teñida');
      ok(l23[3] > 0.4 && l23[2] > l23[0], 'la noche no es azul');
      ok(l20[0] > l20[2], 'el atardecer no es cálido');
      // Y la torre Iberdrola no proyecta lo que un portal: 165 m contra los 13 del barrio.
      S.min = 17 * 60; A.calcularSol();
      const lt2 = A.largoSombra('senorial');
      const torre = Math.min(20, 165 / Math.tan(A.SOL.elev) / 5.16);
      ok(torre > lt2 * 3, 'la torre proyecta ' + torre.toFixed(1) + ' y una manzana ' + lt2.toFixed(1));
      // Y lo que está de pie proyecta al mismo sitio que la manzana: si el coche tira la
      // sombra a un lado y el edificio al otro, la escena se rompe.
      S.min = 9 * 60;  A.calcularSol(); const sm = A.sombraSol(1.7);
      S.min = 14 * 60; A.calcularSol(); const st = A.sombraSol(1.7);
      S.min = 23 * 60; A.calcularSol(); const sn = A.sombraSol(1.7);
      ok(sm && sm.dx < 0 && sm.largo > st.largo, 'la sombra de una persona no sigue al sol');
      ok(st && st.dy < 0 && Math.abs(st.dx) < st.largo * 0.5, 'a las 14 la figura no proyecta al norte');
      ok(!sn, 'de noche las figuras siguen proyectando sombra de sol');
      // Y ninguna sombra se sube a un tejado: al llegar a la fachada, la sombra trepa por
      // la pared, y en una vista cenital eso no se ve. Se mide sobre las farolas de verdad,
      // que son las más largas — cuatro metros de alto a primera hora son veinte de sombra.
      {
        S.min = 9 * 60; A.calcularSol();
        let miradas = 0, encima = 0, recortadas = 0;
        const largoLibre = A.sombraSol(4).largo;
        for (let i = 0; i < A.MOB.length && miradas < 4000; i++) {
          if (A.MOB[i] !== 1) continue;                    // farola
          const x = i % A.MW, y = (i / A.MW) | 0;
          miradas++;
          const so = A.sombraCorta(x * A.TS + A.TS/2, y * A.TS + A.TS/2, 4);
          if (so.largo < largoLibre - 0.01) recortadas++;
          const fx = Math.floor(x + 0.5 + so.dx / A.TS), fy = Math.floor(y + 0.5 + so.dy / A.TS);
          if (fx >= 0 && fy >= 0 && fx < A.MW && fy < A.MH
              && A.map[fy * A.MW + fx] === A.EDIF) encima++;
        }
        ok(!encima, encima + ' de ' + miradas + ' farolas tiran la sombra encima de un tejado');
        ok(recortadas > miradas * 0.2,
           'solo ' + recortadas + ' de ' + miradas + ' sombras se paran en la fachada: no se está recortando');
        bien.push(miradas + ' farolas con la sombra parada en la fachada (' + recortadas + ' recortadas)');
      }
      S.min = min0;
      bien.push('el sol gira con la hora: sombra de ' + lm.toFixed(1) + ' casillas a las 9 y '
        + lt.toFixed(1) + ' a las 14, y tinte de amanecer, día, ocaso y noche');
    }

    // ── 1 quater bis · de noche se encienden las ventanas ──────────────
    /* A las once la ciudad era una mancha negra con farolas. Lo que dice que ahí vive
       gente es la ventana encendida, y tiene que ser siempre la misma: si parpadeara al
       mover la cámara sería un cartel de neón y no un edificio. */
    {
      const g = A.real.getContext('2d'), ant = g.fillRect;
      const cuenta = () => {
        let n = 0;
        g.fillRect = function (...r) {
          // node-canvas normaliza el color, así que se compara sin espacios.
          const col = typeof this.fillStyle === 'string' ? this.fillStyle.replace(/\s/g, '') : '';
          if (col.indexOf('242,210,148') >= 0) n++;
          return ant.apply(this, r);
        };
        paso(1);
        g.fillRect = ant;
        return n;
      };
      S.escena = 'ciudad'; A.cerrarDlg(); P.enCoche = null;
      P.x = 1185.5; P.y = 441.5; paso(30);
      const min0 = S.min;
      S.min = 23 * 60; paso(2);
      const noche = cuenta(), noche2 = cuenta();
      S.min = 14 * 60; paso(2);
      const dia = cuenta();
      S.min = min0;
      ok(noche > 20, 'de noche solo se encienden ' + noche + ' ventanas en toda la pantalla');
      ok(noche === noche2, 'las ventanas parpadean: ' + noche + ' y luego ' + noche2);
      ok(!dia, dia + ' ventanas encendidas a las dos de la tarde');
      bien.push(noche + ' ventanas encendidas de noche en una pantalla de Santutxu, '
        + 'siempre las mismas, y ninguna a mediodía');
    }

    // ── 1 quinquies · la ley de las capas ──────────────────────────────
    /* Lo que se pinta después tapa, así que el orden no es una costumbre: es una ley. El
       suelo entero primero, los bloques después, lo que sobresale encima y los rótulos al
       final. Iba mezclado casilla a casilla y por eso un árbol de dos casillas de ancho
       perdía la mitad derecha —la casilla siguiente le echaba el suelo por encima— y las
       chinchetas se pintaban antes que la gente, así que el jugador tapaba la del sitio al
       que iba. Se comprueba grabando un fotograma de verdad. */
    {
      const g = A.real.getContext('2d');
      const rec = [];
      const espia = ['drawImage', 'fillRect', 'fill'];
      const antes = {};
      for (const m of espia) {
        antes[m] = g[m];
        g[m] = function (...args) { rec.push(A.capaAct()); return antes[m].apply(this, args); };
      }
      S.escena = 'ciudad'; A.cerrarDlg();
      paso(1);                      // un fotograma: entre dos, la capa vuelve al suelo
      for (const m of espia) g[m] = antes[m];
      let saltos = 0, peor = '';
      for (let i = 1; i < rec.length; i++)
        if (rec[i] < rec[i-1]) {
          saltos++;
          if (!peor) peor = 'de ' + rec[i-1] + ' a ' + rec[i] + ' en el dibujo ' + i;
        }
      ok(rec.length > 500, 'el fotograma grabado solo tiene ' + rec.length + ' dibujos');
      ok(!saltos, saltos + ' dibujos rompen el orden de capas (' + peor + ')');
      const capas = new Set(rec);
      ok(capas.has(A.CAPA.SUELO) && capas.has(A.CAPA.EDIFICIO) && capas.has(A.CAPA.OBJETO)
         && capas.has(A.CAPA.HUD), 'hay capas que no se pintan: ' + [...capas].join(','));
      bien.push(rec.length + ' dibujos en un fotograma, todos en orden de capa: '
        + 'suelo → bloques → objetos → vuelo → HUD');
    }

    // ── 1 quinquies bis · los suelos que faltaban ──────────────────────
    /* Del plano salen siete tipos de suelo. El juego tiene arte para diez: muelle, patio de
       manzana y plaza estaban forjados —con sus tiles y sus grúas— y no había ni una casilla
       de ninguno, así que Zorrotzaurre era césped y la grúa no se plantaba nunca. Se
       clasifican con la propia trama y con el callejero, y aquí se comprueba que lo que sale
       es lo que dice ser. */
    {
      const n = A.MW * A.MH, cuenta = {};
      for (let i = 0; i < n; i++) cuenta[A.map[i]] = (cuenta[A.map[i]] || 0) + 1;
      ok((cuenta[A.MUELLE] || 0) > 200, 'no hay muelle: ' + (cuenta[A.MUELLE] || 0) + ' casillas');
      ok((cuenta[A.PATIO] || 0) > 400, 'no hay patios de manzana: ' + (cuenta[A.PATIO] || 0));
      ok((cuenta[A.PLAZA] || 0) > 400, 'no hay plazas: ' + (cuenta[A.PLAZA] || 0));
      // El muelle es orilla de trabajo: agua cerca y barrio industrial. Ni una casilla suelta
      // tierra adentro, que entonces sería un descampado pintado de muelle.
      let sinAgua = 0;
      for (let i = 0; i < n; i++) {
        if (A.map[i] !== A.MUELLE) continue;
        const x = i % A.MW, y = (i / A.MW) | 0;
        let agua = false;
        for (let dy = -5; dy <= 5 && !agua; dy++) for (let dx = -5; dx <= 5; dx++) {
          const j = (y + dy) * A.MW + x + dx;
          if (j >= 0 && j < n && A.map[j] === A.AGUA) { agua = true; break; }
        }
        if (!agua) sinAgua++;
      }
      // Un muelle sin agua a la vista es un descampado pintado de muelle.
      ok(sinAgua < 40, sinAgua + ' casillas de muelle sin agua a menos de 25 m');
      // El patio es un hueco cerrado: si toca calzada, es una calle y no un patio.
      let patioAbierto = 0, patioSuelto = 0;
      for (let i = 0; i < n; i++) {
        if (A.map[i] !== A.PATIO) continue;
        const x = i % A.MW, y = (i / A.MW) | 0;
        let edif = false;
        for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
          const t2 = A.map[(y + dy) * A.MW + x + dx];
          if (t2 === A.ROAD || t2 === A.PUENTE) patioAbierto++;
          if (t2 === A.EDIF) edif = true;
        }
        if (!edif) patioSuelto++;
      }
      ok(!patioAbierto, patioAbierto + ' casillas de patio dan a la calzada: eso es una calle');
      ok(patioSuelto < 40, patioSuelto + ' casillas de patio sin un edificio al lado');
      // Y la plaza lleva el nombre del plano: o es una calle «Plaza …» o toca una que lo es.
      let plazaSinNombre = 0;
      for (let i = 0; i < n; i++) {
        if (A.map[i] !== A.PLAZA) continue;
        const x = i % A.MW, y = (i / A.MW) | 0;
        let nombrada = false;
        for (let dy = -3; dy <= 3 && !nombrada; dy++) for (let dx = -3; dx <= 3; dx++) {
          const nm = A.calleEn(x + dx, y + dy);
          if (nm && /^(pl\.|plaza|plazuela)/i.test(nm)) { nombrada = true; break; }
        }
        if (!nombrada) plazaSinNombre++;
      }
      ok(plazaSinNombre < 30, plazaSinNombre + ' casillas de plaza que no son ninguna plaza del callejero');
      bien.push((cuenta[A.MUELLE] || 0) + ' casillas de muelle en la orilla industrial, '
        + (cuenta[A.PATIO] || 0) + ' de patio de manzana cerrado y '
        + (cuenta[A.PLAZA] || 0) + ' de plaza con nombre del callejero');
    }

    // ── 1 sexies · la ley de la visión ─────────────────────────────────
    /* Un objeto no ocupa solo suelo: ocupa vista. Dos reglas, y las dos se barren enteras
       en vez de mirarse a ojo en una captura:
         · dónde cabe cada cosa — en una acera de dos metros y medio no se planta una grúa
           de doce, y algo de más de cuatro metros en el bordillo deja de ser mobiliario y
           pasa a ser un muro;
         · a quién esconde — lo que pasa de dos metros es más alto que quien anda por
           delante, así que puede tapar al jugador entero. */
    {
      // 1 · todo código de mobiliario es una pieza conocida, y cabe donde está plantado.
      const tope = A.TOPE_ALTO, alto = k => A.MOB_M[k][1];
      let sinPieza = 0, pasadas = 0, peor = '', piezas = new Set();
      for (let i = 0; i < A.MOB.length; i++) {
        const mb = A.MOB[i];
        if (!mb || mb >= 200) continue;                      // del 200 arriba son pasos de cebra
        const k = A.MOB_PIEZA[mb];
        if (!k) { sinPieza++; continue; }
        piezas.add(k);
        if (alto(k) > tope[A.ACERA] + 1e-6) {
          pasadas++;
          if (!peor) peor = k + ' de ' + alto(k) + ' m en la acera ' + (i % A.MW) + ',' + ((i / A.MW) | 0);
        }
      }
      ok(!sinPieza, sinPieza + ' casillas con un código de mobiliario que nadie sabe dibujar');
      ok(!pasadas, pasadas + ' piezas no caben donde están: ' + peor);
      // 2 · y lo que se siembra fuera de la acera, igual: cada suelo tiene su tope.
      let fuera = '';
      for (const suelo of Object.keys(A.SIEMBRA)) {
        for (const [, k] of A.SIEMBRA[suelo]) {
          piezas.add(k);
          if (alto(k) > tope[suelo] + 1e-6)
            fuera = fuera || (k + ' de ' + alto(k) + ' m en un suelo con tope de ' + tope[suelo]);
        }
      }
      for (const fam of Object.keys(A.SIEMBRA_TEJADO))
        for (const [, k] of A.SIEMBRA_TEJADO[fam]) {
          piezas.add(k);
          if (alto(k) > tope[A.EDIF] + 1e-6)
            fuera = fuera || (k + ' de ' + alto(k) + ' m en un tejado');
        }
      ok(!fuera, 'se siembra donde no cabe: ' + fuera);
      // La grúa y el andamio son de muelle y de obra: si alguno acabara en una acera, la
      // regla de arriba lo cazaría, pero se dice aquí por si un día cambia el tope.
      ok(alto('grua') > tope[A.ACERA] && alto('andamio') > tope[A.ACERA],
         'la grúa o el andamio han dejado de ser demasiado altos para una acera');

      // 3 · la silueta. Delante de un árbol de cuatro metros, el jugador no se pierde.
      const g = A.real.getContext('2d');
      S.escena = 'ciudad'; A.cerrarDlg(); P.enCoche = null;
      const conProp = [], sinProp = [];
      for (let i = A.MW * 60; i < A.MOB.length && (!conProp.length || !sinProp.length); i++) {
        const x = i % A.MW, y = (i / A.MW) | 0;
        if (x < 3 || y < 3 || x > A.MW - 4 || y > A.MH - 4) continue;
        if (A.MOB[i] === 7 && !conProp.length) {             // árbol de alineación, 3,8 m
          const [bx, by] = A.anclaMob(x, y);
          if (A.map[(y - 1) * A.MW + x] === A.ACERA) conProp.push(x + bx / 32, y + by / 32);
        }
        if (!sinProp.length && A.map[i] === A.ROAD) {
          let limpio = true;
          for (let dy = 0; dy <= 4 && limpio; dy++) for (let dx = -2; dx <= 2; dx++) {
            const j = (y + dy) * A.MW + x + dx, t = A.map[j];
            if (A.MOB[j] || t === A.EDIF || A.SIEMBRA[t]) { limpio = false; break; }
          }
          if (limpio) sinProp.push(x + 0.5, y + 0.5);
        }
      }
      ok(conProp.length === 2, 'no se encontró ningún árbol de acera con acera por encima');
      ok(sinProp.length === 2, 'no se encontró un trozo de calzada sin nada plantado alrededor');
      const fotograma = () => { const n = A.siluetas(); paso(1); return A.siluetas() - n; };
      const plantarse = (px, py) => {
        P.x = px; P.y = py; P.d8 = 2;
        paso(30);                                            // la cámara va detrás, no salta
      };
      plantarse(conProp[0], conProp[1] - 0.3);
      const tapado = fotograma();
      plantarse(sinProp[0], sinProp[1]);
      const libre = fotograma();
      ok(tapado === 1, 'delante de un árbol de 3,8 m el jugador no lleva silueta');
      ok(libre === 0, 'en mitad de la calzada, sin nada delante, se pinta silueta igual');
      bien.push(piezas.size + ' piezas plantadas donde caben (acera hasta '
        + tope[A.ACERA] + ' m, muelle hasta ' + tope[A.MUELLE]
        + '), y silueta cuando algo de más de ' + A.ALTO_TAPA + ' m tapa al jugador');
    }

    // ── 2 bis · se duerme y te curan ───────────────────────────────────
    // dormir() y curar() miran la casilla que hay delante. Si un plano nuevo pone la cama
    // pegada a la pared de abajo, la cama existe y no se puede usar.
    {
      const delante = (id, ch) => {
        const m = A.INT[id].mapa;
        for (let y = 1; y < m.length; y++) for (let x = 1; x < m[y].length; x++)
          if (m[y][x] === ch && A.BLANDO_I.includes(m[y+1] ? m[y+1][x] : '#')) return true;
        return false;
      };
      ok(delante('piso', 'C'), 'no se puede dormir: no hay hueco delante de ninguna cama');
      ok(delante('hospital', 'L'), 'no te pueden curar: no hay hueco delante de ninguna camilla');
      bien.push('cama y camilla con sitio para plantarse delante');
    }

    // ── 2 ter · la ropa cambia al personaje ────────────────────────────
    {
      const antes = A.hoja('protagonista').toDataURL();
      const puesto = S.pinta.torso;
      const otra = A.PRENDAS.find(q => q.r === 'torso' && q.v !== puesto);
      A.vestir({ torso: otra.v });
      ok(S.pinta.torso === otra.v, 'la prenda comprada no se pone');
      const despues = A.hoja('protagonista').toDataURL();
      ok(antes !== despues, 'el personaje se dibuja igual con otra ropa');
      // Cambiarse quita una estrella: es la baza del jugador contra la descripción.
      S.estrellas = 2; A.vestir({ torso: puesto });
      ok(S.estrellas === 1, 'cambiarse de ropa no quita estrella');
      S.estrellas = 0;
      bien.push(A.PRENDAS.length + ' prendas, y el sprite cambia al vestirse');
    }


    // ── 2 quinquies · una silueta traída viste a muchos ────────────────
    /* Las hojas de PixelLab no se bajan por personaje sino por silueta, y el juego las
       repinta para cada vecino. Aquí no hay red ni hoja de verdad —el bloque SPRITES va
       vacío a propósito—, así que se monta una de mentira con las rampas de plantilla y
       se comprueba lo único que puede romperse en silencio: que los nombres de silueta
       que espera el juego son los que baja el empaquetador, que el repintado le pone a
       cada uno su ropa, y que dos vecinos de la misma silueta no salen clavados. */
    {
      const py = fs.readFileSync(
        path.join(__dirname, '..', 'sprites', 'pixellab.py'), 'utf8');
      const trozo = (marca) => py.slice(py.indexOf(marca), py.indexOf('}', py.indexOf(marca)));
      const sets = [...trozo('SETS = {').matchAll(/^\s*'(\w+)':/gm)].map(m => m[1]);
      ok(sets.length >= 4, 'no leo las siluetas de pixellab.py');

      const rampas = {};
      for (const m of trozo('RAMPAS = {').matchAll(/^\s*'(\w+)':\s*\[([^\]]*)\]/gm)) {
        rampas[m[1]] = [...m[2].matchAll(/'(\w+)'/g)].map(c => {
          const hex = A.C[c[1]];
          ok(!!hex, 'pixellab.py usa un color que no está en la paleta: ' + c[1]);
          return A.PALETA.findIndex(p => p[3] === hex) + 1;
        });
      }
      const todos = Object.values(rampas).flat();
      ok(new Set(todos).size === todos.length,
         'dos partes comparten rampa: repintar una tocaría la otra');

      // Una hoja de mentira por silueta: cabeza, torso, piernas y zapatos, cada parte
      // recorriendo entera su rampa para que el repintado se ejercite en todas sus posiciones.
      const cw = A.SPR.cel[0], ch = A.SPR.cel[1], w = cw * 8, h = ch * A.ORDEN_POSES.length;
      const franjas = [[1, 2, 'pelo'], [2, 10, 'piel'], [10, 18, 'torso'],
                       [18, 24, 'piernas'], [24, 26, 'calzado']];
      const bytes = Buffer.alloc(w * h);
      for (let fy = 0; fy < A.ORDEN_POSES.length; fy++)
        for (let d = 0; d < 8; d++)
          for (const [y0, y1, parte] of franjas) {
            const r = rampas[parte];
            for (let y = y0; y < y1; y++)
              for (let x = cw / 2 - 5; x < cw / 2 + 5; x++)
                bytes[(fy * ch + y + 6) * w + d * cw + (x | 0)] = r[(y - y0) % r.length];
          }
      const b64 = require('zlib').deflateRawSync(bytes).toString('base64');

      const antesForja = A.hoja('protagonista').toDataURL();
      A.SPR.rampas = rampas;
      for (const s of sets) A.SPR.hojas[s] = b64;
      await A.cargarSprites();
      ok(Object.keys(A.BASES).length === sets.length,
         'no se cargaron las ' + sets.length + ' siluetas');

      const sinSilueta = Object.keys(A.ARQ).filter(k => !A.setDe(A.ARQ[k]));
      ok(!sinSilueta.length, 'sin silueta que les valga: ' + sinSilueta.join(', '));

      for (const k of Object.keys(A.ARQ)) delete A.HOJAS[k];
      const color = (k, y) => {
        const c = A.hoja(k), g = c.getContext('2d');
        const d = g.getImageData(cw >> 1, y + 6, 1, 1).data;
        return '#' + [d[0], d[1], d[2]].map(v => v.toString(16).padStart(2, '0')).join('');
      };
      for (const k of ['protagonista', 'ertzaina', 'amaia', 'p6']) {
        const T = A.TORSOS[A.ARQ[k].torso];
        const suyo = [T.s, T.b, T.l].map(x => x.toLowerCase());
        ok(suyo.includes(color(k, 13)),
           k + ': la silueta no se repintó con su torso (salió ' + color(k, 13) + ')');
      }
      // Calvo no lleva hoja propia: el pelo se le manda al color de su piel. Los tonos
      // oscuros de la forja no están entre los 48, así que se compara ya cuantizado.
      const cerca = (hex) => {
        const v = [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16));
        let mej = A.PALETA[0], md = 1e9;
        for (const p of A.PALETA) {
          const d = (p[0] - v[0]) ** 2 + (p[1] - v[1]) ** 2 + (p[2] - v[2]) ** 2;
          if (d < md) { md = d; mej = p; }
        }
        return mej[3].toLowerCase();
      };
      ok([A.ARQ.koldo.piel, A.ARQ.koldo.pielS].map(cerca).includes(color('koldo', 1)),
         'un calvo sigue saliendo con pelo (salió ' + color('koldo', 1) + ')');
      ok(A.hoja('protagonista').toDataURL() !== A.hoja('ertzaina').toDataURL(),
         'dos vecinos de la misma silueta salen clavados');
      ok(A.hoja('protagonista').toDataURL() !== antesForja,
         'la hoja traída no llega a usarse: sigue saliendo la forjada');

      // Se deshace todo: el resto de la batería juega con el arte forjado de verdad.
      A.SPR.rampas = {};
      for (const s of sets) delete A.SPR.hojas[s];
      for (const s of sets) delete A.BASES[s];
      for (const k of Object.keys(A.ARQ)) delete A.HOJAS[k];
      bien.push(sets.length + ' siluetas visten a los ' + Object.keys(A.ARQ).length +
                ' arquetipos, repintadas una a una');
    }
    // ── 2 quater · transporte público ──────────────────────────────────
    {
      ok(A.PARADAS.length === A.BARRIOS.length,
         'hay ' + A.PARADAS.length + ' paradas de bus para ' + A.BARRIOS.length + ' barrios');
      let malas = 0;
      for (const q of A.PARADAS) {
        const t = A.Tc(q.p.x | 0, q.p.y | 0);
        if (t !== A.ACERA && t !== A.PLAZA) malas++;
      }
      ok(!malas, malas + ' paradas de bus fuera de la acera');
      for (const red of Object.keys(A.REDES)) {
        const l = A.nodos(red);
        ok(l.length >= 3, 'la red ' + red + ' solo tiene ' + l.length + ' paradas');
        for (const q of l) {
          const t = A.Tc(q.p.x | 0, q.p.y | 0);
          ok(t !== A.EDIF && t !== A.AGUA, red + ': ' + q.n + ' no se pisa');
        }
      }
      // Viajar cuesta dinero y reloj, y deja al jugador en el destino.
      const metro = A.nodos('metro');
      const origen = metro[0], destino = metro[metro.length - 1];
      P.x = origen.p.x; P.y = origen.p.y;
      const dinero0 = S.dinero, min0 = S.min + S.dia * 1440;
      S.dinero = 50;
      A.viajarA('metro', destino);
      await dormir(280); paso(4);
      ok(Math.hypot(P.x - destino.p.x, P.y - destino.p.y) < 1.5, 'el metro no te deja en el destino');
      ok(S.min + S.dia * 1440 > min0, 'viajar no cuesta reloj');
      S.dinero = dinero0;
      bien.push(Object.keys(A.REDES).length + ' redes · ' + A.nodos('metro').length + ' estaciones de metro, '
                + A.nodos('tren').length + ' de cercanías y ' + A.PARADAS.length + ' paradas de bus');
    }

    // ── 2 quinquies · sigilo ───────────────────────────────────────
    {
      // Un sitio despejado y a plena luz, para que las cuentas sean las del cono y no
      // las de una fachada que se cruza por medio.
      //
      // «Despejado» hay que comprobarlo, no pedirlo: antes esto era puntoAcera(), que
      // elige por sorteo entre las aceras del vecindario, y el sorteo depende de cuántas
      // veces se haya tirado el dado antes en la batería. Añadir un comercio al juego
      // corrió el dado, la acera que salió tenía una fachada a tres casillas, y cuatro
      // pruebas de sigilo se pusieron rojas sin que el sigilo hubiera cambiado. Ahora se
      // busca en espiral la primera acera con ocho casillas libres a los cuatro lados.
      const abierto = (x, y) => {
        const t = A.Tc(x, y);
        return t !== A.EDIF && t !== A.AGUA && t !== A.MONTE;
      };
      const despejado = (cx, cy, rmax, libre) => {
        for (let d = 0; d <= rmax; d++)
          for (let dy = -d; dy <= d; dy++)
            for (let dx = -d; dx <= d; dx++) {
              if (Math.max(Math.abs(dx), Math.abs(dy)) !== d) continue;
              const x = cx + dx, y = cy + dy, t = A.Tc(x, y);
              if (t !== A.ACERA && t !== A.PLAZA) continue;
              let libreAqui = true;
              for (let i = -libre; i <= libre && libreAqui; i++)
                if (!abierto(x + i, y) || !abierto(x, y + i)) libreAqui = false;
              if (libreAqui) return { x: x + .5, y: y + .5 };
            }
        return null;
      };
      const moyua = A.POI.find(q => q.id === 'moyua');
      const llano = despejado(moyua.p.x | 0, moyua.p.y | 0, 60, 8);
      ok(!!llano, 'no hay ninguna explanada cerca de Moyúa donde medir el sigilo');
      if (!llano) throw new Error('sin sitio donde probar el sigilo');
      S.min = 12 * 60;
      ok(!A.esDeNoche(), 'a mediodía dice que es de noche');
      P.x = llano.x; P.y = llano.y; P.enCoche = null;

      // La postura cambia lo lejos que se te ve, y de noche se ve menos.
      P.sigilo = false; P.corriendo = false;
      const dePie = A.alcanceVista();
      P.sigilo = true;  const agachado = A.alcanceVista();
      P.sigilo = false; P.corriendo = true; const corriendo = A.alcanceVista();
      P.corriendo = false;
      ok(agachado < dePie && dePie < corriendo,
         'la postura no cambia el alcance (' + agachado + '/' + dePie + '/' + corriendo + ')');
      S.min = 3 * 60;
      ok(A.esDeNoche() && A.alcanceVista() < dePie, 'de noche se ve igual de lejos');
      S.min = 12 * 60;

      // Un vigilante mirando a otro lado no te ve; girándose, sí.
      const ojo = { x: P.x + 6, y: P.y, d8: A.dir8De(1, 0), sosp: 0 };
      ok(!A.teVe(ojo), 'te ve estando de espaldas');
      ojo.d8 = A.dir8De(-1, 0);
      ok(A.teVe(ojo), 'no te ve teniéndote delante y a seis casillas');
      // Y por lejos que mire, no ve a través de la ciudad.
      ojo.x = P.x + 400;
      ok(!A.teVe(ojo), 'te ve desde el otro lado de Bilbao');

      // Por la espalda: el mismo vigilante, según hacia dónde mire.
      ojo.x = P.x + 1; ojo.y = P.y; ojo.d8 = A.dir8De(1, 0);
      ok(A.porDetras(ojo), 'no reconoce que lo tienes de espaldas');
      ojo.d8 = A.dir8De(-1, 0);
      ok(!A.porDetras(ojo), 'dice que es por la espalda teniéndote de cara');
      ok(A.desprevenido({ alerta: 0, sosp: 0 }) && !A.desprevenido({ alerta: 1, sosp: 0 }),
         'la alerta del enemigo no cuenta');

      // Un delito sin testigos no da estrellas; con un guardia delante, sí.
      A.policia.length = 0; A.enemigos.length = 0; A.peatones.length = 0;
      S.estrellas = 0;
      ok(!A.testigos(), 'hay testigos con la calle vacía');
      ok(!A.delito(1) && S.estrellas === 0, 'un delito sin testigos da estrellas');
      A.enemigos.push({ x: P.x + 4, y: P.y, d8: A.dir8De(-1, 0), hp: 60, arq: 'maton',
                        arma: 'punos', pose: 'quieto', anim: 0, cad: 0, herido: 0,
                        alerta: 1, sosp: 1, oido: null });
      ok(A.testigos(), 'no hay testigos con uno mirándote a cuatro casillas');
      ok(A.delito(1) && S.estrellas === 1, 'un delito visto no da estrellas');

      // El ruido orienta a quien lo oye aunque no vea nada.
      const sordo = A.enemigos[0];
      sordo.sosp = 0; sordo.alerta = 0; sordo.oido = null;
      A.ruido(P.x, P.y, 10);
      ok(sordo.oido && sordo.alerta === 1, 'el ruido no alerta a quien lo tiene al lado');

      // Y mirando fijamente, la sospecha se llena.
      sordo.sosp = 0; sordo.oido = null;
      for (let k = 0; k < 120; k++) A.ojos(1 / 60);
      ok(sordo.sosp >= 1 && S.visto, 'mirándote dos segundos no acaba de verte');
      // Perdido de vista, se vacía.
      sordo.x = P.x + 400;
      for (let k = 0; k < 240; k++) A.ojos(1 / 60);
      ok(sordo.sosp === 0 && !S.visto, 'la sospecha no baja al perderte de vista');

      A.enemigos.length = 0; S.estrellas = 0;
      bien.push('sigilo: postura, cono, línea de vista, ruido y delito sin testigos');
    }

    // ── 2 sexies · nivel, viviendas y negocios ─────────────────────
    {
      // El nivel sube con la experiencia y la curva no se estanca.
      S.nivel = 1; S.xp = 0;
      ok(A.XP_NIVEL(2) > A.XP_NIVEL(1) && A.XP_NIVEL(9) > A.XP_NIVEL(8) * 1.05,
         'la curva de nivel no sube');
      A.darXp(A.XP_NIVEL(1) + A.XP_NIVEL(2));
      ok(S.nivel === 3, 'con dos niveles de experiencia se queda en ' + S.nivel);

      // Comprar: primero falta nivel, luego dinero, y al final es tuyo.
      const caro = A.PROPIEDADES.find(q => q.nivel >= 9);
      S.nivel = 1; S.dinero = 999999;
      ok(A.pegaPara(caro).startsWith('Necesitas nivel'), 'no exige nivel para ' + caro.id);
      S.nivel = 20; S.dinero = 0;
      ok(A.pegaPara(caro).startsWith('Te faltan'), 'no exige dinero para ' + caro.id);
      S.dinero = caro.precio + 500;
      A.comprarProp(caro.id);
      ok(A.esMio(caro.id), 'la compra no se registra');
      ok(Math.round(S.dinero) === 500, 'la compra no cobra: quedan ' + Math.round(S.dinero));
      ok(A.pegaPara(caro) === null, 'lo comprado sigue en venta');

      // Un negocio renta cada día, y la renta se cobra al dormir.
      const neg = A.PROPIEDADES.find(q => q.tipo === 'negocio');
      S.nivel = 20; S.dinero = neg.precio;
      A.comprarProp(neg.id);
      ok(A.rentaDiaria() >= neg.renta, 'el negocio no renta');
      S.dinero = 0; A.cobrarRentas();
      ok(S.dinero >= neg.renta, 'la renta no se cobra');

      // En un local tuyo no se paga.
      S.interior = { id: 'tasca', poi: neg.id }; S.dinero = 100; S.hambre = 0;
      A.comer(18, 1, 0.6, 0, 'Menú.');
      ok(S.dinero === 100, 'te cobran en tu propio local');
      S.interior = null;
      bien.push(A.PROPIEDADES.length + ' propiedades, con nivel, precio y renta');
    }

    // ── 2 septies · el alquiler y la casera ────────────────────────
    {
      // De cero: al día, con recibo cada siete días.
      S.props = {}; S.alquiler = 220; S.deuda = 0; S.ultCobro = 1; S.dia = 1;
      S.casera = { paciencia: 3, avisada: 0, desahucio: false, okupa: false };
      ok(A.estadoCasera() === 'aldia', 'no empieza al día');

      S.dia = 8; A.correrAlquiler();
      ok(S.deuda === 220, 'el recibo semanal no cae: deuda ' + S.deuda);
      ok(A.estadoCasera() === 'debiendo', 'debiendo 220 € dice ' + A.estadoCasera());

      // Dos recibos sin pagar: aviso. Tres: cerradura nueva.
      S.dia = 15; A.correrAlquiler();
      ok(A.estadoCasera() === 'avisado', 'dos meses sin pagar no avisan');
      S.dia = 22; A.correrAlquiler();
      ok(S.casera.desahucio && A.estadoCasera() === 'desahuciado', 'tres meses no desahucian');

      // Volver cuesta la deuda más la cerradura.
      ok(A.deudaTotal() > S.deuda, 'recuperar la llave no cuesta más que la deuda');
      // Y forzar la puerta es un delito que deja okupa.
      A.ocupar();
      ok(S.casera.okupa && A.estadoCasera() === 'okupa', 'forzar la puerta no deja okupa');

      // Pagando todo se recupera la llave y se sale del okupa.
      S.dinero = A.deudaTotal() + 10;
      A.pagarCasera();
      ok(S.deuda === 0 && !S.casera.desahucio && !S.casera.okupa,
         'pagar no devuelve la llave: ' + A.estadoCasera());

      // Dejar el piso corta el recibo.
      A.dejarPiso();
      S.dia += 30; const antes = S.deuda;
      A.correrAlquiler();
      ok(S.deuda === antes, 'sigue corriendo el alquiler de un piso dejado');

      // Y comprarlo también.
      S.props = {}; S.alquiler = 220; S.deuda = 660; S.nivel = 20; S.dinero = 99999;
      S.casera = { paciencia: 3, avisada: 0, desahucio: false, okupa: false };
      A.comprarProp('pisosantutxu');
      ok(A.esMio('pisosantutxu') && S.deuda === 0 && S.alquiler === 0,
         'comprar el piso no quita el alquiler');

      S.props = {}; S.alquiler = 220; S.deuda = 0; S.ultCobro = S.dia; S.dinero = 60;
      S.casera = { paciencia: 3, avisada: 0, desahucio: false, okupa: false };
      bien.push('alquiler: recibo, aviso, desahucio, okupa y vuelta pagando');
    }

    // ── 2 octies · el móvil pinta las cuatro pestañas ──────────────
    {
      for (const t of ['hist', 'trab', 'bien', 'rep']) {
        A.verTab(t);
        ok(A.telC.children.length > 0, 'la pestaña ' + t + ' del móvil sale vacía');
      }
      A.verTab('hist');
      bien.push('las 4 pestañas del móvil pintan');
    }

    // ── 2 nonies · los tejados dicen en qué barrio estás ───────────
    {
      // El material lo pone el barrio de cada casilla, no el rincón por el que el
      // recorrido empezó el edificio: la manzana del Casco Viejo cruza a Abando, y
      // tomando el estilo del origen el casco entero salía de pizarra.
      const porEst = {};
      for (let y = 0; y < A.MH; y += 3) for (let x = 0; x < A.MW; x += 3) {
        if (A.Tc(x, y) !== A.EDIF) continue;
        const e = A.distDe(x, y).estilo, f = A.famDe(A.roof[y * A.MW + x]);
        (porEst[e] = porEst[e] || {})[f] = (porEst[e][f] || 0) + 1;
      }
      const manda = e => Object.keys(porEst[e] || {}).sort((a, b) => porEst[e][b] - porEst[e][a])[0];
      for (const [est, esperada] of [['denso', 'teja'], ['senorial', 'pizarra'],
                                     ['bloques', 'azotea'], ['industrial', 'nave']])
        ok(manda(est) === esperada,
           'en los barrios «' + est + '» manda el tejado «' + manda(est) + '», no «' + esperada + '»');
      bien.push('4 familias de tejado, cada una mandando en su tipo de barrio');
    }

    // ── 3 · los sitios están sobre suelo pisable ───────────────────────
    let accesibles = 0;
    A.POI.forEach(p => {
      const t = A.Tc(p.p.x | 0, p.p.y | 0);
      if (t !== A.EDIF && t !== A.AGUA && t !== A.MONTE) accesibles++;
    });
    ok(accesibles === A.POI.length, (A.POI.length - accesibles) + ' sitios inaccesibles');
    bien.push(accesibles + '/' + A.POI.length + ' sitios accesibles');

    // ── 4 · cada sitio, donde lo pone el plano ─────────────────────────
    // Antes se comprobaba el barrio, que era lo único que se podía comprobar cuando la
    // coordenada era una pista. Ahora la coordenada sale del plano municipal, así que lo
    // que hay que vigilar es otra cosa: que al buscarle una casilla pisable el sitio no
    // se vaya lejos. Treinta casillas son ciento cincuenta metros, que es lo que mide
    // un recinto grande: el rótulo del Hospital de Basurto cae en mitad del complejo y
    // la calle más cercana está en el borde. Más que eso ya no es el borde de la
    // manzana, es otro barrio.
    const TOPE = 30;
    let idos = 0, peor = 0, peorN = '';
    A.POI.forEach(p => {
      if (!p.cerca) return;
      const d = Math.hypot(p.p.x - p.cerca[0], p.p.y - p.cerca[1]);
      if (d > peor) { peor = d; peorN = p.n; }
      if (d > TOPE) {
        idos++;
        fallos.push(p.n + ' se ha ido ' + d.toFixed(0) + ' casillas de donde lo pone el plano');
      }
    });
    if (!idos) bien.push(A.POI.length + ' sitios a menos de ' + TOPE + ' casillas del plano'
      + ' (el peor, ' + peorN + ', a ' + peor.toFixed(0) + ')');

    // ── 4b · los edificios singulares, en su sitio y en tierra ─────────
    // El estadio, la catedral, el Ayuntamiento y los demás no se dibujan sobre una
    // casilla: ocupan una caja de hasta treinta y cinco casillas de largo, y esa caja se
    // busca sola alrededor del rótulo del plano. Dos cosas pueden salir mal y las dos ya
    // salieron mal: que la caja acabe lejos del rótulo, y que acabe encima de la ría
    // —el rótulo de San Mamés cae literalmente en el agua—. Aquí se comprueban las dos
    // sobre la colocación de verdad, la que hace el juego al cargar la ciudad.
    {
      const S = A.SINGULARES || {};
      const ids = Object.keys(S);
      let malos = 0, peorD = 0, peorN = '', peorS = 1, peorSN = '';
      for (const id of ids) {
        const s = S[id], p = A.POI.find(q => q.id === id);
        if (s.x === undefined) { fallos.push('singular ' + id + ': sin colocar'); malos++; continue; }
        const d = Math.hypot(s.x + (s.w >> 1) - p.cerca[0], s.y + (s.h >> 1) - p.cerca[1]);
        if (d > peorD) { peorD = d; peorN = id; }
        if (d > 30) { fallos.push('singular ' + id + ': a ' + d.toFixed(0) + ' casillas del rótulo'); malos++; }
        let pintables = 0;
        for (let y = s.y; y < s.y + s.h; y++)
          for (let x = s.x; x < s.x + s.w; x++) {
            const t = A.Tc(x, y);
            if (t !== A.AGUA && t !== A.MUELLE && t !== A.PUENTE && t !== A.ROAD && t !== A.MONTE) pintables++;
          }
        const seco = pintables / (s.w * s.h);
        if (seco < peorS) { peorS = seco; peorSN = id; }
        if (seco < 0.75) { fallos.push('singular ' + id + ': solo el ' + Math.round(seco * 100) + '% de su caja es suelo'); malos++; }
      }
      // Cuántos hay lo dice la tabla del juego, no un número escrito aquí: si mañana se
      // añade el Arriaga bis, esto tiene que seguir midiendo lo mismo y no romperse.
      const enTabla = Object.keys(A.PLANO_SINGULAR || {}).length;
      if (ids.length !== enTabla) {
        fallos.push('la tabla tiene ' + enTabla + ' singulares y se colocaron ' + ids.length);
        malos++;
      }
      if (!malos) bien.push(ids.length + ' edificios singulares en tierra (el peor, ' + peorSN + ', al '
        + Math.round(peorS * 100) + '%) y a menos de 30 casillas del plano (el peor, ' + peorN + ', a '
        + peorD.toFixed(0) + ')');
    }

    // ── 4c · el callejero ──────────────────────────────────────────────
    // Las calles no llevan escrita una lista de casillas: llevan unos puntos de paso y el
    // juego busca el camino de calle que los une. Eso puede quedarse en nada sin dar
    // error —lo hizo con nueve de las treinta y cuatro la primera vez, porque en el Casco
    // Viejo las calles son peatonales y no llevan trazo de calzada— y una calle de cero
    // casillas es un nombre que no sale nunca. Aquí se comprueba sobre el nombrado de
    // verdad, el que hace el juego al cargar la ciudad.
    {
      // Cuando esto eran 34 ejes puestos a mano se exigía un mínimo de quince casillas a
      // cada uno. Con el callejero del plano —quinientas y pico calles— eso no vale: un
      // callejón de sesenta metros son doce casillas y es una calle perfectamente real.
      // Lo que sí sigue siendo un fallo es que una calle que el plano rotula no aparezca
      // en ninguna casilla, y que la mitad del callejero se quede en nada.
      const CAL = A.CALLES || [];
      const largos = CAL.map((c, i) => A.LARGO_CALLE[i] || 0);
      const vacias = largos.filter(n => n === 0).length;
      const cortas = largos.filter(n => n < 8).length;
      const mediana = [...largos].sort((a, b) => a - b)[largos.length >> 1] || 0;
      CAL.forEach((c, i) => {
        if (largos[i] === 0) fallos.push('la calle ' + c.n + ' no cae en ninguna casilla');
      });
      if (cortas > CAL.length * .25)
        fallos.push(cortas + ' de ' + CAL.length + ' calles se quedan en menos de 8 casillas');
      // Y que el nombre llegue de verdad al jugador: se pregunta por una casilla nombrada,
      // que es lo que hace el HUD.
      let mudas = 0;
      for (let i = 0; i < A.calleDe.length && mudas < 1; i++) {
        if (!A.calleDe[i]) continue;
        if (!A.calleEn(i % A.MW, (i / A.MW) | 0)) { fallos.push('calleEn no devuelve el nombre'); mudas++; }
      }
      if (!vacias && !mudas && cortas <= CAL.length * .25)
        bien.push(CAL.length + ' calles con nombre sobre ' + largos.reduce((a, b) => a + b, 0)
          + ' casillas (mediana ' + mediana + ', ' + cortas + ' de menos de 8)');
    }

    // ── 5 · la red viaria está conectada ───────────────────────────────
    {
      // Se mide la componente MAYOR, no la que toque salir primero al escanear. Lo que
      // interesa es si la ciudad es de una pieza; arrancando por la esquina, un callejón
      // suelto de cien casillas daba 0 % con el 98 % de la red entera y bien conectada.
      const vis = new Uint8Array(A.MW * A.MH);
      let total = 0, mayor = 0, trozos = 0;
      for (let y = 0; y < A.MH; y++)
        for (let x = 0; x < A.MW; x++) if (A.rodable(x, y)) total++;
      for (let y0 = 0; y0 < A.MH; y0++) {
        for (let x0 = 0; x0 < A.MW; x0++) {
          if (!A.rodable(x0, y0) || vis[y0 * A.MW + x0]) continue;
          trozos++;
          const pila = [[x0, y0]]; vis[y0 * A.MW + x0] = 1; let n = 0;
          while (pila.length) {
            const [cx, cy] = pila.pop(); n++;
            for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
              const nx = cx + dx, ny = cy + dy;
              if (nx < 0 || ny < 0 || nx >= A.MW || ny >= A.MH || vis[ny * A.MW + nx]) continue;
              if (A.rodable(nx, ny)) { vis[ny * A.MW + nx] = 1; pila.push([nx, ny]); }
            }
          }
          if (n > mayor) mayor = n;
        }
      }
      const pct = mayor / total * 100;
      ok(pct > 90, 'la red viaria está partida: la pieza mayor es el ' + pct.toFixed(1) + '%');
      bien.push('red viaria conectada al ' + pct.toFixed(1) + '% en ' + trozos + ' trozos');
    }

    // ── 6 · combate ────────────────────────────────────────────────────
    {
      // La prueba es si la pistola mata a 3 casillas, no si hay una pared en medio: hay
      // que buscar una acera con tiro libre al este, que es hacia donde apunta (d8 = 2).
      let p0 = null;
      for (let i = 0; i < 300 && !p0; i++) {
        const c = A.puntoAcera(P.x | 0, P.y | 0, 50);
        let libre = true;
        for (let d = 1; d <= 4; d++) {
          const t = A.Tc((c.x | 0) + d, c.y | 0);
          if (t === A.EDIF || t === A.AGUA) { libre = false; break; }
        }
        if (libre) p0 = c;
      }
      ok(p0, 'no encuentro una acera con tiro libre al este');
      p0 = p0 || A.puntoAcera(P.x | 0, P.y | 0, 10);
      P.x = p0.x; P.y = p0.y; P.enCoche = null;
      S.armas.pistola = 60; S.armaAct = 'pistola'; A.enemigos.length = 0;
      A.enemigos.push({ x: P.x + 3, y: P.y, hp: 60, arq: 'maton', arma: 'punos',
                        d8: 0, pose: 'quieto', anim: 0, cad: 0, herido: 0 });
      P.d8 = 2;
      // se dispara con la cruceta puesta al este, que es como se juega ahora
      for (let k = 0; k < 30 && A.enemigos.length; k++) { A.atacarJugador(1, 0); paso(20); }
      ok(A.enemigos.length === 0, 'la pistola no mata a un enemigo a 3 casillas');
      if (!A.enemigos.length) bien.push('combate con pistola');
    }

    // ── 7 · conducción desde varios puntos al azar ─────────────────────
    // Se conduce señalando, así que la prueba es: ¿un piloto tonto que solo mira por
    // dónde hay calle libre consigue moverse? Antes se apretaba una dirección 2,5 s
    // seguidos y se medía la distancia, pero eso en Bilbao es empotrarse en la primera
    // esquina: medía lo recta que era la calle, no si el mando sirve.
    {
      S.hp = 100; S.muerto = 0; S.estrellas = 0; A.policia.length = 0; A.enemigos.length = 0;
      const DIRS = [[1,0,'d'],[1,1,'ds'],[0,1,'s'],[-1,1,'as'],[-1,0,'a'],[-1,-1,'aw'],[0,-1,'w'],[1,-1,'dw']];
      const conduce = t => t !== A.EDIF && t !== A.AGUA && t !== A.PARQUE && t !== A.MONTE;
      const libreHacia = (cc, dx, dy) => {
        const n = Math.hypot(dx, dy);
        for (let d = 1; d <= 16; d++)
          if (!conduce(A.Tc((cc.x + dx / n * d) | 0, (cc.y + dy / n * d) | 0))) return d - 1;
        return 16;
      };
      const recorridos = [];
      for (let i = 0; i < 16; i++) {
        const cc = A.coches.find(c => c.propio), cp = A.puntoCalle();
        cc.x = cp.x; cc.y = cp.y; cc.dano = 0; cc.vivo = true; cc.vx = cc.vy = 0;
        cc.ang = 0;
        P.x = cc.x; P.y = cc.y; P.enCoche = cc;
        const x0 = cc.x, y0 = cc.y;
        let vx = 1, vy = 0;
        for (let q = 0; q < 10; q++) {
          // cada cuarto de segundo el piloto elige entre las ocho, con ventaja para
          // seguir recto: si no, se queda temblando entre dos direcciones igual de buenas
          let mejor = null, mejorP = -1;
          for (const [dx, dy, ks] of DIRS) {
            const p = libreHacia(cc, dx, dy) + (dx * vx + dy * vy) * 2.5;
            if (p > mejorP) { mejorP = p; mejor = [dx, dy, ks]; }
          }
          vx = mejor[0]; vy = mejor[1];
          // El joystick solo dirige: el gas es su propio pedal, así que hay que mantenerlo
          // o el coche se queda parado por muy bien que se apunte.
          for (const k of mejor[2]) A.teclas[k] = true;
          A.teclas[' '] = true;
          paso(15);
          for (const k of mejor[2]) A.teclas[k] = false;
          A.teclas[' '] = false;
        }
        recorridos.push(Math.hypot(cc.x - x0, cc.y - y0));
        P.enCoche = null;
      }
      recorridos.sort((a, b) => a - b);
      const mediana = recorridos[8];
      // El umbral sale de la física, no de lo que daba antes. Arrancando parado con
      // 3,1 m/s² —los 0-100 en 9 s de un utilitario— en 2,5 s se recorren 9,7 m, o sea
      // 1,9 casillas; con las maniobras y los semáforos de por medio, medio de eso es un
      // suelo razonable. El 10 de antes venía de cuando el coche corría a 204 km/h y
      // aceleraba a 7,5 g: cualquier valor realista lo habría dado por roto.
      ok(mediana > 0.9, 'la mediana de conducción es de solo ' + mediana.toFixed(1) + ' casillas');
      bien.push('conducción en 2,5 s: mediana ' + mediana.toFixed(1) + ' casillas (peor '
        + recorridos[0].toFixed(1) + ', mejor ' + recorridos[15].toFixed(1) + ')');

      // ── el pie no patina ──
      // La cadencia del andar iba a un ritmo fijo, así que con el joystick analógico se
      // podía avanzar despacio moviendo las piernas a toda pastilla. Se comprueba que los
      // pasos por segundo salgan de la velocidad —una zancada son ZANCADA metros— y que
      // andar o correr lo decida la velocidad y no quien llame a la función.
      {
        const paso1 = v => { const e = { anim: 0 }; A.poseAndar(e, v * A.MS, false, 1, false);
                             return { pasos: e.anim, pose: e.pose }; };
        const lento = paso1(1.4), rapido = paso1(5.6);
        const espLento = 1.4 / A.ZANCADA, espRapido = 5.6 / A.ZANCADA;
        ok(Math.abs(lento.pasos - espLento) < .05 && Math.abs(rapido.pasos - espRapido) < .05,
          'la cadencia no sale de la velocidad: a 1,4 m/s da ' + lento.pasos.toFixed(2)
          + ' pasos/s y debería dar ' + espLento.toFixed(2));
        ok(lento.pose.startsWith('andar') && rapido.pose.startsWith('correr'),
          'andar o correr no lo decide la velocidad: a 1,4 m/s sale ' + lento.pose
          + ' y a 5,6 sale ' + rapido.pose);
        bien.push('la cadencia sale de la velocidad: ' + espLento.toFixed(1) + ' pasos/s andando y '
          + espRapido.toFixed(1) + ' corriendo, con zancada de ' + A.ZANCADA + ' m');
      }
    }

    // ── 8 · muerte y reaparición ───────────────────────────────────────
    S.hp = 100; A.estrellas(4); paso(1500);
    A.danarJugador(999); paso(300);
    ok(S.hp > 0, 'no se reaparece tras morir');
    if (S.hp > 0) bien.push('muerte y reaparición en el hospital');

    // ── 9 · el bucle aguanta ───────────────────────────────────────────
    paso(9000);
    bien.push('150 s de bucle sin excepciones');

    ok(Object.keys(global.__store()).length > 0, 'la partida no se guarda');

  } catch (e) {
    fallos.push('EXCEPCIÓN: ' + e.message + ' | ' + (e.stack.split('\n')[1] || '').trim());
  }

  bien.forEach(b => console.log('  ok    ' + b));
  if (fallos.length) {
    console.log();
    fallos.forEach(f => console.log('  FALLO ' + f));
    console.log('\n' + fallos.length + ' fallos');
    process.exit(1);
  }
  console.log('\ntodo correcto');
})();
