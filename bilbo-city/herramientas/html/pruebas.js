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
    for (const id of interiores) {
      const d = A.INT[id], m = d.mapa;
      ok(m.some(f => f.includes('D')), id + ': no tiene puerta');
      ok(m.every(f => f.length === m[0].length), id + ': filas de distinto largo');
      // Un tendero dentro de una pared o encima del mostrador es lo que sale al dibujar
      // un plano nuevo a mano, y no se ve hasta entrar.
      for (const n of d.npcs) {
        const fx = Math.floor(n.x), fy = Math.floor(n.y);
        const ch = (fy >= 0 && fy < m.length && fx >= 0 && fx < m[fy].length) ? m[fy][fx] : '#';
        ok(!A.solidoInt(ch), id + ': ' + n.n + ' está dentro de un «' + ch + '»');
      }
      for (const f of m) for (const ch of f)
        ok(ch === '.' || ch === 'D' || A.TILE_INT[ch], id + ': tile «' + ch + '» sin dibujo');
      A.entrar(id, { x: P.x, y: P.y }); await dormir(280); paso(8);
      ok(S.escena === 'interior', 'no se entra en ' + id);
      A.salir(); await dormir(280); paso(8);
      ok(S.escena === 'ciudad', 'no se sale de ' + id);
    }
    bien.push(interiores.length + ' interiores entran y salen, con puerta y sin nadie empotrado');

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
      const moyua = A.POI.find(q => q.id === 'moyua');
      const llano = A.puntoAcera(moyua.p.x | 0, moyua.p.y | 0, 20);
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
      if (ids.length !== 12) { fallos.push('hay ' + ids.length + ' singulares, no 12'); malos++; }
      if (!malos) bien.push(ids.length + ' edificios singulares en tierra (el peor, ' + peorSN + ', al '
        + Math.round(peorS * 100) + '%) y a menos de 30 casillas del plano (el peor, ' + peorN + ', a '
        + peorD.toFixed(0) + ')');
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
          for (const k of mejor[2]) A.teclas[k] = true;
          paso(15);
          for (const k of mejor[2]) A.teclas[k] = false;
        }
        recorridos.push(Math.hypot(cc.x - x0, cc.y - y0));
        P.enCoche = null;
      }
      recorridos.sort((a, b) => a - b);
      const mediana = recorridos[8];
      ok(mediana > 10, 'la mediana de conducción es de solo ' + mediana.toFixed(1) + ' casillas');
      bien.push('conducción en 2,5 s: mediana ' + mediana.toFixed(1) + ' casillas (peor '
        + recorridos[0].toFixed(1) + ', mejor ' + recorridos[15].toFixed(1) + ')');
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
