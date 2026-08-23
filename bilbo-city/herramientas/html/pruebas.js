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

(async () => {
  await dormir(500);

  const H = global.__H, A = global.__, S = A.S, P = A.player, paso = global.__step;
  const fallos = [];
  const ok = (cond, msg) => { if (!cond) fallos.push(msg); };
  const bien = [];

  (H['btnNuevo:click'] || H['btnCont:click'])();
  paso(60);

  try {
    // ── 1 · la campaña entera ──────────────────────────────────────────
    for (let k = 0; k < A.MISIONES.length; k++) {
      S.misionIdx = k; S.hp = 100;
      A.empezarMision(A.MISIONES[k]);
      let guarda = 0;
      while (S.mision && guarda++ < 40) {
        A.cerrarDlg(); S.estrellas = 0; A.policia.length = 0; S.hp = 100;
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
    if (!descolocados) bien.push('los 15 sitios en su barrio');

    // ── 5 · la red viaria está conectada ───────────────────────────────
    {
      const vis = new Uint8Array(A.MW * A.MH);
      let sx = 0, sy = 0, total = 0;
      buscar: for (let y = 0; y < A.MH; y++)
        for (let x = 0; x < A.MW; x++) if (A.rodable(x, y)) { sx = x; sy = y; break buscar; }
      for (let y = 0; y < A.MH; y++)
        for (let x = 0; x < A.MW; x++) if (A.rodable(x, y)) total++;
      const pila = [[sx, sy]]; vis[sy * A.MW + sx] = 1; let alcanzado = 0;
      while (pila.length) {
        const [cx, cy] = pila.pop(); alcanzado++;
        for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          const nx = cx + dx, ny = cy + dy;
          if (nx < 0 || ny < 0 || nx >= A.MW || ny >= A.MH || vis[ny * A.MW + nx]) continue;
          if (A.rodable(nx, ny)) { vis[ny * A.MW + nx] = 1; pila.push([nx, ny]); }
        }
      }
      const pct = alcanzado / total * 100;
      ok(pct > 90, 'la red viaria está partida: solo se alcanza el ' + pct.toFixed(1) + '%');
      bien.push('red viaria conectada al ' + pct.toFixed(1) + '%');
    }

    // ── 6 · combate ────────────────────────────────────────────────────
    {
      const p0 = A.puntoAcera(P.x | 0, P.y | 0, 10);
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
      S.hp = 100; S.estrellas = 0; A.policia.length = 0; A.enemigos.length = 0;
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
