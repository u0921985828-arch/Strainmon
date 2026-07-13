/* ============================================================
   STRAINMON — isogame.js
   Controlador del sandbox isométrico (híbrido "salas + grow", single-player,
   todo NPC, roam libre). Reemplaza al overworld top-down. Reutiliza
   PH.state / PH.ui / PH.iso / PH.genetics / PH.plantart / PH.garden.
   Arte y diseño originales (sin relación con Habbo/Sulake).
   ============================================================ */
(function (PH) {
  'use strict';
  const { clamp, lerp } = PH.util;
  const ISO = PH.iso;
  const G = () => PH.state.get();

  // Movimiento por ejes de rejilla (cada tecla recorre una arista del rombo).
  // Up=NE(gy-1), Down=SW(gy+1), Left=NW(gx-1), Right=SE(gx+1).
  const DIRV = { NE: [0, -1], SW: [0, 1], NW: [-1, 0], SE: [1, 0] };

  /* ------------------------- SALAS ------------------------- */
  // grid: '.'=suelo  '#'=pared  ' '=vacío(bloqueado)  'D'=puerta(suelo)
  const ROOMS = {
    apt: {
      id: 'apt', name: 'Tu Grow-Room', theme: 'room',
      grid: [
        '#########',
        '#.......#',
        '#.......#',
        '#.......#',
        '#.......#',
        '#.......#',
        '#...D...#',
        '#########',
      ],
      spawn: { gx: 4, gy: 5 },
      doors: [{ gx: 4, gy: 6, to: 'street', tgx: 6, tgy: 3 }],
      npcs: [],
      objects: [
        { gx: 2, gy: 1, kind: 'grow', solid: true, label: 'Invernadero' },
        { gx: 6, gy: 1, kind: 'pc', solid: true, label: 'Ordenador' },
        { gx: 2, gy: 5, kind: 'bed', solid: true, label: 'Cama' },
      ],
    },
    street: {
      id: 'street', name: 'Calle Verde', theme: 'street',
      grid: [
        '.............',
        '.HH..HH..HH..',
        '.HD..HD..HD..',
        '.............',
        '.....P.......',
        '.gg.........',
        '.gg......gg..',
        '.............',
      ],
      spawn: { gx: 6, gy: 3 },
      doors: [
        { gx: 2, gy: 2, to: 'apt', tgx: 4, tgy: 5 },
        { gx: 6, gy: 2, to: 'shop', tgx: 3, tgy: 3 },
        { gx: 10, gy: 2, to: 'lab', tgx: 3, tgy: 3 },
      ],
      npcs: [
        { gx: 6, gy: 5, name: 'Dealer Kez', sprite: 'npc6', dialog: 'contrabandista', dir: 'SW', role: 'dealer', char: 'dealer' },
        { gx: 3, gy: 4, name: 'Vecina Bru', sprite: 'npc2', dialog: 'coleccionista', dir: 'SE', role: 'neighbor', char: 'neighbor' },
        { gx: 8, gy: 3, name: 'Cliente', sprite: 'npc3', dir: 'SW', role: 'customer', char: 'customer1' },
        { gx: 4, gy: 6, name: 'Cliente', sprite: 'npc4', dir: 'NE', role: 'customer', char: 'customer2' },
        { gx: 11, gy: 5, name: 'Transeúnte', sprite: 'npc5', dir: 'NW', role: 'walker', char: 'walker' },
      ],
      objects: [],
      wild: true, // 'g' = parterres con cepas silvestres
    },
    shop: {
      id: 'shop', name: 'Mercado', theme: 'room',
      grid: [
        '#######',
        '#.....#',
        '#.....#',
        '#.....#',
        '#..D..#',
        '#######',
      ],
      spawn: { gx: 3, gy: 4 },
      doors: [{ gx: 3, gy: 4, to: 'street', tgx: 6, tgy: 3 }],
      npcs: [{ gx: 3, gy: 1, name: 'Mercader', sprite: 'npc4', dialog: 'nomada', dir: 'SW', role: 'merchant', char: 'merchant' }],
      objects: [{ gx: 5, gy: 2, kind: 'shop', solid: true, label: 'Mostrador' }],
    },
    lab: {
      id: 'lab', name: 'Laboratorio', theme: 'room',
      grid: [
        '#######',
        '#.....#',
        '#.....#',
        '#.....#',
        '#..D..#',
        '#######',
      ],
      spawn: { gx: 3, gy: 4 },
      doors: [{ gx: 3, gy: 4, to: 'street', tgx: 10, tgy: 3 }],
      npcs: [{ gx: 2, gy: 1, name: 'Dr. Vane', sprite: 'npc5', dialog: 'genetista', dir: 'SE', role: 'botanist', char: 'botanist' }],
      objects: [
        { gx: 4, gy: 1, kind: 'lab', solid: true, label: 'Mesa de cruces' },
        { gx: 5, gy: 2, kind: 'pc', solid: true, label: 'Terminal ADN' },
      ],
    },
  };
  // Lista BLANCA de tiles caminables. Todo lo demás bloquea (paredes '#',
  // vacío ' ', fachadas 'H', farolas 'P', dígitos, o cualquier char extraño).
  const WALKABLE = { '.': 1, 'D': 1, 'g': 1 };
  function walkableChar(ch) { return !!WALKABLE[ch]; }

  function room(id) { return ROOMS[id]; }
  function tileAt(m, gx, gy) {
    if (gy < 0 || gy >= m.grid.length) return '#';
    const r = m.grid[gy]; if (gx < 0 || gx >= r.length) return '#';
    return r[gx];
  }
  function objAt(m, gx, gy) { return (m.objects || []).find(o => o.gx === gx && o.gy === gy); }
  function doorAt(m, gx, gy) { return (m.doors || []).find(d => d.gx === gx && d.gy === gy); }
  function npcAt(m, gx, gy) { return (m.npcs || []).find(n => n.gx === gx && n.gy === gy); }
  // Bloqueado si el tile no es caminable, o hay objeto sólido, o hay un NPC.
  // (ignoreNpc: al comprobar puertas no cuenta el NPC de destino.)
  function solidAt(m, gx, gy, ignoreNpc) {
    if (!walkableChar(tileAt(m, gx, gy))) return true;
    const o = objAt(m, gx, gy); if (o && o.solid !== false) return true;
    if (!ignoreNpc && npcAt(m, gx, gy)) return true;
    return false;
  }
  // Auditoría: colocaciones inválidas de NPCs/objetos (para QA).
  function audit() {
    const problems = [];
    for (const id of Object.keys(ROOMS)) {
      const m = ROOMS[id];
      for (const n of (m.npcs || [])) {
        if (!walkableChar(tileAt(m, n.gx, n.gy))) problems.push(`${id}: NPC ${n.name} en tile no caminable (${n.gx},${n.gy})`);
        if (objAt(m, n.gx, n.gy)) problems.push(`${id}: NPC ${n.name} solapa objeto (${n.gx},${n.gy})`);
        if (doorAt(m, n.gx, n.gy)) problems.push(`${id}: NPC ${n.name} sobre puerta (${n.gx},${n.gy})`);
      }
      for (const o of (m.objects || [])) {
        if (!walkableChar(tileAt(m, o.gx, o.gy))) problems.push(`${id}: objeto ${o.label} en tile no caminable (${o.gx},${o.gy})`);
      }
      for (const d of (m.doors || [])) {
        if (tileAt(m, d.gx, d.gy) !== 'D') problems.push(`${id}: puerta->${d.to} no está sobre 'D' (${d.gx},${d.gy})`);
        const t = ROOMS[d.to]; if (!t) { problems.push(`${id}: puerta a sala inexistente '${d.to}'`); continue; }
        if (solidAt(t, d.tgx, d.tgy, true)) problems.push(`${id}: destino de puerta a ${d.to} es sólido (${d.tgx},${d.tgy})`);
      }
      // spawn caminable
      if (solidAt(m, m.spawn.gx, m.spawn.gy, true)) problems.push(`${id}: spawn sólido (${m.spawn.gx},${m.spawn.gy})`);
    }
    return problems;
  }

  /* ------------------------- ESTADO ------------------------- */
  const game = {
    mode: 'boot', canvas: null, ctx: null, scale: 3,
    W: 480, H: 432,                 // 10:9 (proporción fiel a la Game Boy 160x144)
    dmg: false, _dmg: null,          // modo DMG (4 tonos, 160x144)
    moving: false, from: null, to: null, moveT: 0, moveDur: 170, frame: 0, animT: 0,
    keys: {}, lastSave: 0, cam: { x: 0, y: 0 },
  };
  PH.game = game;

  function init() {
    game.canvas = document.getElementById('screen');
    game.ctx = game.canvas.getContext('2d');
    if (PH.sprites) PH.sprites.preload();
    if (PH.plantart) PH.plantart.preload();
    if (PH.charart) PH.charart.preload();
    if (PH.furniart) PH.furniart.preload();
    PH.ui.init();
    bindInput();
    resize();
    window.addEventListener('resize', resize);
    titleScreen();
    requestAnimationFrame(loop);
  }

  function resize() {
    // Búfer a resolución interna; el tamaño de pantalla lo gestiona la LCD (CSS).
    game.canvas.width = game.W; game.canvas.height = game.H;
    game.canvas.style.width = '100%'; game.canvas.style.height = '100%';
    game.ctx.imageSmoothingEnabled = false;
  }

  /* ------------------------- TÍTULO ------------------------- */
  function titleScreen() {
    game.mode = 'title';
    const ov = document.getElementById('overlay');
    ov.className = 'active title';
    const cont = PH.state.hasSave() ? '<button class="btn primary big" id="t_continue">Continuar</button>' : '';
    ov.innerHTML = `
      <div class="title-screen">
        <div class="logo">STRAIN<span>MON</span></div>
        <div class="tagline">Sandbox isométrico · cultiva · trapichea · colecciona</div>
        <div class="title-btns">${cont}
          <button class="btn ${cont ? 'ghost' : 'primary'} big" id="t_new">Nueva partida</button></div>
        <div class="title-help">Mover: WASD / Flechas (diagonales) · Interactuar: Espacio o E<br>
          I Mochila · B Banco · C Strain-dex · L Lab · G Invernadero · Q Misiones · M Guardar</div>
      </div>`;
    if (cont) document.getElementById('t_continue').onclick = () => { PH.state.load(); startGame(false); };
    document.getElementById('t_new').onclick = () => { PH.state.reset(); startGame(true); };
  }

  function normalizePlayer() {
    const p = G().player;
    if (!ROOMS[p.map]) { p.map = 'apt'; const sp = ROOMS.apt.spawn; p.x = sp.gx; p.y = sp.gy; }
    if (!p.dir || !DIRV[p.dir]) p.dir = 'SW';
  }
  function startGame(fresh) {
    PH.ui.close();
    const p = G().player;
    // Partida nueva -> siempre en el apartamento. Continuar -> respeta sala iso guardada.
    if (fresh || !ROOMS[p.map] || !p.iso) { p.map = 'apt'; p.x = ROOMS.apt.spawn.gx; p.y = ROOMS.apt.spawn.gy; p.dir = 'SW'; }
    p.iso = true;
    game.dmg = !!p.dmg;
    normalizePlayer();
    game.mode = 'overworld';
    centerCam(true);
    PH.ui.updateHUD();
    PH.ui.toast('Bienvenido a tu grow-room. Sal por la puerta (abajo).', 'ok');
  }

  /* ------------------------- ENTRADA ------------------------- */
  const MOVE_KEYS = { arrowup: 1, arrowdown: 1, arrowleft: 1, arrowright: 1, w: 1, a: 1, s: 1, d: 1 };
  // Acción de un botón/tecla (A=espacio/confirmar, B=escape/volver, atajos de panel).
  function doAction(k) {
    if (game.mode === 'title') return;
    if (game.mode === 'dialog') { if (k === ' ' || k === 'e' || k === 'enter') PH.ui.dialogNext(); return; }
    if (game.mode === 'menu') { if (k === 'escape' || k === 'b' || k === 'i' || k === 'c' || k === 'q' || k === 'g' || k === 'l') PH.ui.close(); return; }
    if (game.mode !== 'overworld') return;
    if (k === ' ' || k === 'e') interact();
    else if (k === 'i') PH.ui.bag(); else if (k === 'b') PH.ui.bank();
    else if (k === 'c') PH.ui.catalog(); else if (k === 'q' || k === 'start' || k === 'enter') PH.ui.quests();
    else if (k === 'l') PH.ui.lab(); else if (k === 'g') PH.ui.greenhouse();
    else if (k === 'select' || k === 'p') toggleDMG();
    else if (k === 'm') { PH.state.save(); PH.ui.toast('Partida guardada.', 'ok'); }
  }
  function toggleDMG() {
    game.dmg = !game.dmg;
    G().player.dmg = game.dmg;
    PH.state.save();
    PH.ui.toast(game.dmg ? '🟩 Modo DMG (4 tonos)' : '🌈 Modo color', '');
  }
  function bindInput() {
    window.addEventListener('keydown', (e) => {
      const k = e.key.toLowerCase(); game.keys[k] = true;
      if (MOVE_KEYS[k] || k === ' ') e.preventDefault();
      if (!MOVE_KEYS[k]) doAction(k);
    });
    window.addEventListener('keyup', (e) => { game.keys[e.key.toLowerCase()] = false; });
    document.querySelectorAll('[data-key]').forEach(btn => {
      const key = btn.dataset.key;
      const down = (e) => { e.preventDefault(); if (MOVE_KEYS[key]) game.keys[key] = true; else doAction(key); };
      const up = (e) => { if (e) e.preventDefault(); if (MOVE_KEYS[key]) game.keys[key] = false; };
      btn.addEventListener('touchstart', down, { passive: false }); btn.addEventListener('touchend', up, { passive: false });
      btn.addEventListener('mousedown', down); btn.addEventListener('mouseup', up); btn.addEventListener('mouseleave', up);
    });
  }

  /* ------------------------- INTERACCIÓN ------------------------- */
  function facing() {
    const p = G().player, d = DIRV[p.dir] || [1, 1];
    return { gx: p.x + d[0], gy: p.y + d[1] };
  }
  function interact() {
    const p = G().player, m = room(p.map); if (!m) return;
    const f = facing();
    const npc = npcAt(m, f.gx, f.gy);
    if (npc) {
      npc.dir = { NE: 'SW', SW: 'NE', NW: 'SE', SE: 'NW' }[p.dir] || 'SW';
      if (npc.role === 'customer') return dealWith(npc);
      if (npc.role === 'walker') return PH.ui.dialog(['...cruza la calle sin mirarte.'], null, { sprite: npc.sprite, name: npc.name });
      const pages = PH.quests.DIALOGS[npc.dialog] ? PH.quests.DIALOGS[npc.dialog](G()) : ['...'];
      PH.ui.dialog(pages, null, { sprite: npc.sprite, name: npc.name });
      return;
    }
    const o = objAt(m, f.gx, f.gy);
    if (o) return useObject(o);
  }
  function useObject(o) {
    if (o.kind === 'grow') return PH.ui.greenhouse();
    if (o.kind === 'lab') return PH.ui.lab();
    if (o.kind === 'shop') return PH.ui.shop();
    if (o.kind === 'pc') return pcMenu();
    if (o.kind === 'bed') { PH.state.save(); return PH.ui.toast('Descansas y guardas la partida.', 'ok'); }
  }
  function pcMenu() {
    PH.ui.dialog(['Terminal: accede a tu Banco (B), Strain-dex (C) o Misiones (Q).'], null, null);
  }

  // Trato callejero: el cliente compra una cepa de tu banco (premium sobre el
  // mercado). Base de la economía "dealer" (heat/reputación en fase futura).
  function dealWith(npc) {
    const s = G();
    const stock = s.bank.filter(x => x.form !== 'polen');
    if (!stock.length) {
      return PH.ui.dialog(['Cliente: ¿No llevas género? Vuelve cuando tengas algo bueno.'], null, { sprite: npc.sprite, name: npc.name });
    }
    // pide la más valiosa que lleves
    const want = stock.slice().sort((a, b) => b.rarity - a.rarity)[0];
    const price = Math.round((30 + want.rarity * want.rarity * 1.1 + want.quality * 1.8) * 1.35); // premium callejero
    PH.ui.open(`
      <div class="panel">
        <div class="panel-head"><h2>🤝 Trato callejero</h2><button class="x" id="p_close">✕</button></div>
        <div class="panel-body center-col">
          <p><b>${npc.name}:</b> te compro tu <b>${want.nickname || want.name}</b> (${want.speciesId}) por <b>💰 ${price}</b>.</p>
          <div style="width:120px">${PH.ui.specimenCard(want)}</div>
          <div class="row">
            <button class="btn primary" id="d_yes">Vender 💰${price}</button>
            <button class="btn ghost" id="d_no">Paso</button>
          </div>
        </div>
      </div>`, 'center');
    PH.ui.paintPlant('pc_' + want.uid, want, 2);
    document.getElementById('p_close').onclick = PH.ui.close;
    document.getElementById('d_no').onclick = PH.ui.close;
    document.getElementById('d_yes').onclick = () => {
      PH.state.bankRemove(want.uid); PH.state.addCredits(price);
      s.stats.deals = (s.stats.deals || 0) + 1;
      PH.ui.toast(`Vendido a ${npc.name}: 💰${price}`, 'ok');
      PH.ui.updateHUD(); PH.game.afterQuestCheck(); PH.ui.close();
    };
  }

  /* ------------------------- MOVIMIENTO ------------------------- */
  function tryMove() {
    if (game.moving || game.mode !== 'overworld') return;
    const p = G().player; let dir = null;
    if (game.keys['arrowup'] || game.keys['w']) dir = 'NE';
    else if (game.keys['arrowdown'] || game.keys['s']) dir = 'SW';
    else if (game.keys['arrowleft'] || game.keys['a']) dir = 'NW';
    else if (game.keys['arrowright'] || game.keys['d']) dir = 'SE';
    if (!dir) return;
    p.dir = dir;
    const m = room(p.map), d = DIRV[dir];
    const nx = p.x + d[0], ny = p.y + d[1];
    const door = doorAt(m, nx, ny);
    if (door) { warp(door); return; }
    if (solidAt(m, nx, ny)) return;
    game.moving = true; game.moveT = 0; game.from = { x: p.x, y: p.y }; game.to = { x: nx, y: ny };
  }
  function finishMove() {
    const p = G().player; p.x = game.to.x; p.y = game.to.y; game.moving = false;
    G().stats.distance++;
    // parterres silvestres 'g' -> posible encuentro
    const m = room(p.map);
    if (m.wild && tileAt(m, p.x, p.y) === 'g') {
      if (PH.util.RNG.chance(0.22)) {
        const biome = PH.util.RNG.pick(['pradera', 'bosque', 'pantano', 'desierto', 'nieve', 'volcan', 'cueva', 'isla']);
        PH.ui.encounter(PH.species.rollEncounter(biome, G().env));
      }
    }
  }
  function warp(d) {
    const p = G().player; const t = room(d.to); if (!t) return;
    p.map = d.to; p.x = d.tgx; p.y = d.tgy; game.moving = false;
    centerCam(true); PH.ui.updateHUD(); PH.ui.toast('📍 ' + t.name, '');
  }

  /* ------------------------- IA DE NPCs ------------------------- */
  // Estados: 'idle' | 'walk'. Deambulan por tiles caminables respetando
  // colisión (paredes, objetos, jugador y otros NPCs). Los 'dealer'/'neighbor'
  // se quedan cerca de su sitio; 'customer'/'walker' pasean más.
  const NPC_STEP = 240;
  function npcSolid(m, gx, gy, self) {
    if (solidAt(m, gx, gy, true)) return true;              // pared/objeto/fuera
    const p = G().player; if (p.x === gx && p.y === gy) return true; // jugador
    for (const n of m.npcs) if (n !== self && n.gx === gx && n.gy === gy) return true; // otros NPCs
    return false;
  }
  function updateNPCs(dt) {
    const m = room(G().player.map); if (!m) return;
    for (const n of m.npcs) {
      if (n._talk) continue;                                 // pausado al hablar
      if (n._mv) {
        n._t += dt;
        if (n._t >= NPC_STEP) { n.gx = n._tx; n.gy = n._ty; n._mv = false; n._wait = PH.util.RNG.i(500, 2600); }
        continue;
      }
      n._wait = (n._wait == null) ? PH.util.RNG.i(300, 1800) : n._wait - dt;
      if (n._wait > 0) continue;
      // homebound: dealer/neighbor no se alejan de su origen
      if (n._hx == null) { n._hx = n.gx; n._hy = n.gy; }
      const roam = (n.role === 'customer' || n.role === 'walker') ? 6 : 2;
      const dirs = PH.util.RNG.shuffle([['NE', 0, -1], ['SW', 0, 1], ['NW', -1, 0], ['SE', 1, 0]]);
      let moved = false;
      for (const d of dirs) {
        const nx = n.gx + d[1], ny = n.gy + d[2];
        if (Math.abs(nx - n._hx) + Math.abs(ny - n._hy) > roam) continue;
        if (npcSolid(m, nx, ny, n)) continue;
        n.dir = d[0]; n._tx = nx; n._ty = ny; n._fx = n.gx; n._fy = n.gy; n._mv = true; n._t = 0; moved = true; break;
      }
      if (!moved) n._wait = PH.util.RNG.i(600, 2000);        // atrapado -> espera
    }
  }
  function npcRender(n) {
    let gx = n.gx, gy = n.gy, frame = 0;
    if (n._mv) { const t = clamp(n._t / NPC_STEP, 0, 1); gx = lerp(n._fx, n._tx, t); gy = lerp(n._fy, n._ty, t); frame = (Math.floor(n._t / (NPC_STEP / 2)) % 2 === 0 ? 1 : 2); }
    return { gx, gy, dir: n.dir || 'SW', frame, pal: PH.render.NPC_PALETTES[n.sprite], char: n.char };
  }

  game.roomName = function () { const m = room(G().player.map); return m ? m.name : ''; };
  game.audit = audit;
  game.canWalk = function (mapId, gx, gy) { const m = room(mapId); return m ? !solidAt(m, gx, gy) : false; };
  game.ROOMS = ROOMS;
  game.afterQuestCheck = function () {
    const done = PH.quests.checkAll();
    for (const q of done) PH.ui.toast('✅ Misión completada: ' + q.name, 'ok');
    PH.ui.updateHUD();
  };

  /* ------------------------- CÁMARA ------------------------- */
  function playerScreen() {
    const p = G().player; let gx = p.x, gy = p.y;
    if (game.moving) { const t = clamp(game.moveT / game.moveDur, 0, 1); gx = lerp(game.from.x, game.to.x, t); gy = lerp(game.from.y, game.to.y, t); }
    return ISO.project(gx, gy, { x: 0, y: 0 });
  }
  function centerCam(snap) {
    const ps = playerScreen();
    const tx = game.W / 2 - ps.x, ty = game.H / 2 - ps.y - 20;
    if (snap) { game.cam.x = tx; game.cam.y = ty; }
    else { game.cam.x = lerp(game.cam.x, tx, 0.15); game.cam.y = lerp(game.cam.y, ty, 0.15); }
  }

  /* ------------------------- BUCLE ------------------------- */
  let last = performance.now();
  function loop(now) {
    const dt = Math.min(50, now - last); last = now;
    game.animT += dt;
    if (game.animT > 240) { game.frame ^= 1; game.animT = 0; }
    if (game.mode === 'overworld' || game.mode === 'menu' || game.mode === 'dialog' || game.mode === 'encounter') {
      PH.state.updateEnv(dt); if (PH.events) PH.events.update(dt); if (PH.garden) PH.garden.update(dt);
    }
    if (game.mode === 'overworld') {
      tryMove();
      if (game.moving) { game.moveT += dt; if (game.moveT >= game.moveDur) finishMove(); }
      updateNPCs(dt);
      centerCam(false);
      if (now - game.lastSave > 20000) { PH.state.save(); game.lastSave = now; }
    }
    if (game.mode !== 'title' && game.mode !== 'boot') render(now);
    if (game.mode === 'overworld' && game.frame === 0) PH.ui.updateHUD();
    requestAnimationFrame(loop);
  }

  /* ------------------------- RENDER ------------------------- */
  function render(now) {
    const ctx = game.ctx, m = room(G().player.map); if (!m) return;
    // fondo por tema
    ctx.fillStyle = m.theme === 'street' ? '#2a3550' : '#14100c';
    ctx.fillRect(0, 0, game.W, game.H);

    // parterres 'g' como suelo especial + suelo calle 'H' fachadas
    const extraFloors = [];
    const walls = [];
    for (let gy = 0; gy < m.grid.length; gy++) for (let gx = 0; gx < m.grid[gy].length; gx++) {
      const ch = m.grid[gy][gx];
      if (ch === 'g') extraFloors.push({ gx, gy, col: '#3f7d34', edge: '#2f5b26' });
      else if (ch === 'H') walls.push({ gx, gy, h: 56, pal: ISO.THEMES.street.wall });
      else if (ch === 'P') walls.push({ gx, gy, h: 30, lamp: true, pal: { top: '#ffd34d', left: '#7c6a2a', right: '#9a8330' } });
    }

    const p = G().player;
    const pss = playerScreen();
    const px = pss.x, py = pss.y;
    // actores
    const actors = [];
    for (const n of (m.npcs || [])) actors.push(npcRender(n));
    // jugador con posición interpolada -> insertamos como actor con coords fraccionarias
    let pgx = p.x, pgy = p.y;
    if (game.moving) { const t = clamp(game.moveT / game.moveDur, 0, 1); pgx = lerp(game.from.x, game.to.x, t); pgy = lerp(game.from.y, game.to.y, t); }
    const walkFrame = game.moving ? (Math.floor(game.moveT / (game.moveDur / 2)) % 2 === 0 ? 1 : 2) : 0;
    actors.push({ gx: pgx, gy: pgy, dir: p.dir, frame: walkFrame, pal: { skin: '#f0c088', hair: '#3a2a1a', shirt: '#2f9e6b', pants: '#33333f' }, char: 'player', hero: true });

    // objetos: dibujarlos como parte del render (cubos etiquetados / grow con planta)
    const objects = (m.objects || []).map(o => ({ gx: o.gx, gy: o.gy, draw: (ctx, sx, sy) => drawObject(ctx, sx, sy, o) }));

    // combinar extraFloors dentro de renderRoom: hack -> dibujar suelos extra antes
    for (const ef of extraFloors) { const s = ISO.project(ef.gx, ef.gy, game.cam); ISO.floorDiamond(ctx, s.x, s.y, ef.col, ef.edge); }

    // paredes 'H' como objetos altos; farolas 'P' con su sprite si existe
    for (const w of walls) objects.push({
      gx: w.gx, gy: w.gy, draw: (ctx, sx, sy) => {
        if (w.lamp && drawFurni(ctx, sx, sy, 'lamp', 52)) return;
        ISO.cube(ctx, sx, sy, w.h, w.pal);
      }
    });

    ISO.renderRoom(ctx, m, game.cam, now, actors, objects);

    // etiqueta del objeto/npc al frente si el jugador mira algo interactuable
    hudFacingLabel(ctx, m);
    envTint(ctx);
    if (game.dmg) applyDMG();
  }

  // Post-proceso "modo DMG": reduce a 160x144, cuantiza luminancia a 4 tonos
  // (paleta verde-oliva clásica) y reescala. Barato (~23k px/frame).
  const DMG_PAL = [[15, 56, 15], [48, 98, 48], [139, 172, 15], [155, 188, 15]];
  function applyDMG() {
    if (!game._dmg) { const c = document.createElement('canvas'); c.width = 160; c.height = 144; game._dmg = c; }
    const sc = game._dmg.getContext('2d'); sc.imageSmoothingEnabled = false;
    sc.drawImage(game.canvas, 0, 0, 160, 144);
    const id = sc.getImageData(0, 0, 160, 144), d = id.data;
    for (let i = 0; i < d.length; i += 4) {
      const l = d[i] * 0.3 + d[i + 1] * 0.59 + d[i + 2] * 0.11;
      const c = DMG_PAL[l < 48 ? 0 : l < 108 ? 1 : l < 176 ? 2 : 3];
      d[i] = c[0]; d[i + 1] = c[1]; d[i + 2] = c[2];
    }
    sc.putImageData(id, 0, 0);
    const ctx = game.ctx; ctx.imageSmoothingEnabled = false;
    ctx.drawImage(game._dmg, 0, 0, game.W, game.H);
  }

  // Dibuja un sprite de mueble anclado a la base del tile (fallback: cubo).
  function drawFurni(ctx, sx, sy, kind, hCap) {
    const im = PH.furniart && PH.furniart.forKind(kind);
    if (im && im.complete && im.naturalWidth) {
      const H = hCap || 46, s = H / im.naturalHeight, w = Math.round(im.naturalWidth * s), h = Math.round(im.naturalHeight * s);
      const base = sy + ISO.TH * 0.85;
      ctx.drawImage(im, Math.round(sx - w / 2), Math.round(base - h), w, h);
      return true;
    }
    return false;
  }
  function drawObject(ctx, sx, sy, o) {
    if (PH.furniart && PH.furniart.has(o.kind)) {
      const done = drawFurni(ctx, sx, sy, o.kind, o.kind === 'grow' ? 40 : 48);
      if (o.kind === 'grow') {
        // planta encima de la mesa de cultivo (fase 4 de una cepa del banco)
        const bank = G().bank.find(b => b.form !== 'polen');
        const key = bank && PH.plantart ? PH.plantart.stageKey(bank.speciesId, 4) : null;
        const im = key && PH.plantart.img(key);
        if (im && im.complete) { const h = 34; ctx.drawImage(im, sx - h * 0.4, sy + ISO.TH * 0.85 - 30 - h, h * 0.8, h); }
      }
      if (done) return;
    }
    if (o.kind === 'grow') {
      ISO.cube(ctx, sx, sy, 12, { top: '#6b4a2a', left: '#4a3320', right: '#5a3f28' }); // mesa
      // planta encima (retrato de una cepa del banco si hay)
      const bank = G().bank.find(b => b.form !== 'polen');
      const key = bank && PH.plantart ? PH.plantart.stageKey(bank.speciesId, 4) : null;
      const im = key && PH.plantart.img(key);
      if (im && im.complete) { const h = 40; ctx.drawImage(im, sx - h * 0.4, sy - h + 6, h * 0.8, h); }
      else ISO.cube(ctx, sx, sy - 12, 22, { top: '#5aa64a', left: '#2f6b2a', right: '#3f8f3a' });
    } else if (o.kind === 'pc') ISO.cube(ctx, sx, sy, 20, { top: '#3a6ea5', left: '#233f5a', right: '#2d5273' });
    else if (o.kind === 'bed') ISO.cube(ctx, sx, sy, 8, { top: '#d64a6b', left: '#8f2f45', right: '#b03a55' });
    else if (o.kind === 'lab') ISO.cube(ctx, sx, sy, 14, { top: '#cfe0ea', left: '#8fa3b0', right: '#aebfc9' });
    else if (o.kind === 'shop') ISO.cube(ctx, sx, sy, 14, { top: '#ffb02e', left: '#9a6a18', right: '#c98d22' });
    else ISO.cube(ctx, sx, sy, 14, { top: '#999', left: '#555', right: '#777' });
  }

  function hudFacingLabel(ctx, m) {
    if (game.mode !== 'overworld' || game.moving) return;
    const f = facing();
    const target = npcAt(m, f.gx, f.gy) || objAt(m, f.gx, f.gy) || doorAt(m, f.gx, f.gy);
    if (!target) return;
    const s = ISO.project(f.gx, f.gy, game.cam);
    const label = target.name || target.label || (target.to ? '→ ' + (room(target.to) ? room(target.to).name : '') : '');
    if (!label) return;
    ctx.font = '8px monospace'; ctx.textAlign = 'center';
    const w = ctx.measureText(label).width + 8;
    ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.fillRect(s.x - w / 2, s.y - 6, w, 11);
    ctx.fillStyle = '#fff'; ctx.fillText(label, s.x, s.y + 2);
  }

  function envTint(ctx) {
    const env = G().env; const t = env.time; let a = 0;
    if (t < 5 * 60) a = 0.42; else if (t < 7 * 60) a = lerp(0.42, 0, (t - 300) / 120);
    else if (t < 18 * 60) a = 0; else if (t < 20 * 60) a = lerp(0, 0.38, (t - 1080) / 120); else a = 0.42;
    if (a > 0) { ctx.fillStyle = `rgba(0,0,25,${a})`; ctx.fillRect(0, 0, game.W, game.H); }
  }

  PH.game.init = init;
  window.addEventListener('DOMContentLoaded', init);
})(window.PH = window.PH || {});
