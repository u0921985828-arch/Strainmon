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
      if (t === A.ACERA || t === A.PLAZA || t === A.PARQUE) accesibles++;
    });
    ok(accesibles === A.POI.length, (A.POI.length - accesibles) + ' sitios inaccesibles');
    bien.push(accesibles + '/' + A.POI.length + ' sitios accesibles');

    // ── 4 · cada sitio en su barrio ────────────────────────────────────
    const esperado = {
      piso: 'Santutxu', portal: 'Santutxu', bar: 'Casco Viejo', merca: 'Casco Viejo',
      armeria: 'Santutxu', taller: 'Rekalde', hospital: 'Basurto', obra: 'Zorrotzaurre',
      puerto: 'Olabeaga', poli: 'Indautxu', guggen: 'Abandoibarra', sanmames: 'San Mamés',
      abando: 'Abando', ayto: 'Uribarri', casilla: 'Parque'
    };
    let descolocados = 0;
    A.POI.forEach(p => {
      const real = A.distDe(p.p.x | 0, p.p.y | 0).n;
      if (esperado[p.id] && real !== esperado[p.id]) {
        descolocados++;
        fallos.push(p.n + ' está en ' + real + ' y debería estar en ' + esperado[p.id]);
      }
    });
    if (!descolocados) bien.push('los ' + A.POI.length + ' sitios en su barrio');

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
      for (let k = 0; k < 30 && A.enemigos.length; k++) { A.atacarJugador(); paso(20); }
      ok(A.enemigos.length === 0, 'la pistola no mata a un enemigo a 3 casillas');
      if (!A.enemigos.length) bien.push('combate con pistola');
    }

    // ── 7 · conducción desde varios puntos al azar ─────────────────────
    {
      S.hp = 100; S.muerto = 0; S.estrellas = 0; A.policia.length = 0; A.enemigos.length = 0;
      const recorridos = [];
      for (let i = 0; i < 16; i++) {
        const cc = A.coches.find(c => c.propio), cp = A.puntoCalle();
        cc.x = cp.x; cc.y = cp.y; cc.dano = 0; cc.vivo = true; cc.vx = cc.vy = 0;
        let h = 0, v = 0; const fx = cc.x | 0, fy = cc.y | 0;
        for (let d = 1; d <= 3; d++) {
          if (A.rodable(fx + d, fy)) h++; if (A.rodable(fx - d, fy)) h++;
          if (A.rodable(fx, fy + d)) v++; if (A.rodable(fx, fy - d)) v++;
        }
        cc.ang = h >= v ? 0 : Math.PI / 2;
        P.x = cc.x; P.y = cc.y; P.enCoche = cc;
        const x0 = cc.x, y0 = cc.y;
        A.teclas['w'] = true; paso(150); A.teclas['w'] = false;
        recorridos.push(Math.hypot(cc.x - x0, cc.y - y0));
        P.enCoche = null;
      }
      recorridos.sort((a, b) => a - b);
      const mediana = recorridos[8];
      ok(mediana > 6, 'la mediana de conducción es de solo ' + mediana.toFixed(1) + ' casillas');
      bien.push('conducción: mediana ' + mediana.toFixed(1) + ' casillas en 2,5 s');
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
