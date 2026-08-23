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
    const interiores = ['bar', 'piso', 'taller', 'armeria', 'merca', 'hospital', 'portal'];
    for (const id of interiores) {
      A.entrar(id, { x: P.x, y: P.y }); await dormir(280); paso(8);
      ok(S.escena === 'interior', 'no se entra en ' + id);
      A.salir(); await dormir(280); paso(8);
      ok(S.escena === 'ciudad', 'no se sale de ' + id);
    }
    bien.push(interiores.length + ' interiores entran y salen');

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
