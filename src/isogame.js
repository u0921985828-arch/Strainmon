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
        { gx: 6, gy: 5, name: 'Dealer Kez', sprite: 'npc6', dialog: 'contrabandista', dir: 'SW' },
        { gx: 3, gy: 4, name: 'Vecina Bru', sprite: 'npc2', dialog: 'coleccionista', dir: 'SE' },
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
      npcs: [{ gx: 3, gy: 1, name: 'Mercader', sprite: 'npc4', dialog: 'nomada', dir: 'SW' }],
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
      npcs: [{ gx: 2, gy: 1, name: 'Dr. Vane', sprite: 'npc5', dialog: 'genetista', dir: 'SE' }],
      objects: [
        { gx: 4, gy: 1, kind: 'lab', solid: true, label: 'Mesa de cruces' },
        { gx: 5, gy: 2, kind: 'pc', solid: true, label: 'Terminal ADN' },
      ],
    },
  };
  // 'H'=fachada(pared alta), 'P'=farola: los tratamos como bloqueantes decorativos.
  function solidChar(ch) { return ch === '#' || ch === ' ' || ch === 'H' || ch === 'P'; }

  function room(id) { return ROOMS[id]; }
  function tileAt(m, gx, gy) {
    if (gy < 0 || gy >= m.grid.length) return '#';
    const r = m.grid[gy]; if (gx < 0 || gx >= r.length) return '#';
    return r[gx];
  }
  function objAt(m, gx, gy) { return (m.objects || []).find(o => o.gx === gx && o.gy === gy); }
  function doorAt(m, gx, gy) { return (m.doors || []).find(d => d.gx === gx && d.gy === gy); }
  function npcAt(m, gx, gy) { return (m.npcs || []).find(n => n.gx === gx && n.gy === gy); }
  function solidAt(m, gx, gy) {
    const ch = tileAt(m, gx, gy);
    if (solidChar(ch)) return true;
    const o = objAt(m, gx, gy); if (o && o.solid) return true;
    if (npcAt(m, gx, gy)) return true;
    return false;
  }

  /* ------------------------- ESTADO ------------------------- */
  const game = {
    mode: 'boot', canvas: null, ctx: null, scale: 3,
    W: 480, H: 320,
    moving: false, from: null, to: null, moveT: 0, moveDur: 170, frame: 0, animT: 0,
    keys: {}, lastSave: 0, cam: { x: 0, y: 0 },
  };
  PH.game = game;

  function init() {
    game.canvas = document.getElementById('screen');
    game.ctx = game.canvas.getContext('2d');
    if (PH.sprites) PH.sprites.preload();
    if (PH.plantart) PH.plantart.preload();
    PH.ui.init();
    bindInput();
    resize();
    window.addEventListener('resize', resize);
    titleScreen();
    requestAnimationFrame(loop);
  }

  function resize() {
    const maxW = window.innerWidth - 24, maxH = window.innerHeight - 120;
    const sc = Math.max(1, Math.min(maxW / game.W, maxH / game.H));
    game.canvas.width = game.W; game.canvas.height = game.H;
    game.canvas.style.width = Math.floor(game.W * sc) + 'px';
    game.canvas.style.height = Math.floor(game.H * sc) + 'px';
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
    normalizePlayer();
    game.mode = 'overworld';
    centerCam(true);
    PH.ui.updateHUD();
    PH.ui.toast('Bienvenido a tu grow-room. Sal por la puerta (abajo).', 'ok');
  }

  /* ------------------------- ENTRADA ------------------------- */
  function bindInput() {
    window.addEventListener('keydown', (e) => {
      const k = e.key.toLowerCase(); game.keys[k] = true;
      if (game.mode === 'dialog' && (k === ' ' || k === 'e' || k === 'enter')) { e.preventDefault(); PH.ui.dialogNext(); return; }
      if (game.mode === 'title') return;
      if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', ' '].includes(k)) e.preventDefault();
      if (game.mode === 'overworld') {
        if (k === ' ' || k === 'e') interact();
        else if (k === 'i') PH.ui.bag(); else if (k === 'b') PH.ui.bank();
        else if (k === 'c') PH.ui.catalog(); else if (k === 'q') PH.ui.quests();
        else if (k === 'l') PH.ui.lab(); else if (k === 'g') PH.ui.greenhouse();
        else if (k === 'm') { PH.state.save(); PH.ui.toast('Partida guardada.', 'ok'); }
      } else if (game.mode === 'menu') {
        if (k === 'escape' || k === 'i' || k === 'b' || k === 'c' || k === 'q') PH.ui.close();
      }
    });
    window.addEventListener('keyup', (e) => { game.keys[e.key.toLowerCase()] = false; });
    document.querySelectorAll('[data-key]').forEach(btn => {
      const key = btn.dataset.key;
      const down = (e) => { e.preventDefault(); game.keys[key] = true; if (key === ' ') simTap(); };
      const up = (e) => { if (e) e.preventDefault(); game.keys[key] = false; };
      btn.addEventListener('touchstart', down); btn.addEventListener('touchend', up);
      btn.addEventListener('mousedown', down); btn.addEventListener('mouseup', up); btn.addEventListener('mouseleave', up);
    });
  }
  function simTap() {
    if (game.mode === 'dialog') PH.ui.dialogNext();
    else if (game.mode === 'overworld') interact();
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

  game.roomName = function () { const m = room(G().player.map); return m ? m.name : ''; };
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
      else if (ch === 'P') walls.push({ gx, gy, h: 30, pal: { top: '#ffd34d', left: '#7c6a2a', right: '#9a8330' } });
    }

    const p = G().player;
    const pss = playerScreen();
    const px = pss.x, py = pss.y;
    // actores
    const actors = [];
    for (const n of (m.npcs || [])) actors.push({ gx: n.gx, gy: n.gy, dir: n.dir || 'SW', frame: 0, pal: PH.render.NPC_PALETTES[n.sprite] });
    // jugador con posición interpolada -> insertamos como actor con coords fraccionarias
    let pgx = p.x, pgy = p.y;
    if (game.moving) { const t = clamp(game.moveT / game.moveDur, 0, 1); pgx = lerp(game.from.x, game.to.x, t); pgy = lerp(game.from.y, game.to.y, t); }
    const walkFrame = game.moving ? (Math.floor(game.moveT / (game.moveDur / 2)) % 2 === 0 ? 1 : 2) : 0;
    actors.push({ gx: pgx, gy: pgy, dir: p.dir, frame: walkFrame, pal: { skin: '#f0c088', hair: '#3a2a1a', shirt: '#2f9e6b', pants: '#33333f' }, hero: true });

    // objetos: dibujarlos como parte del render (cubos etiquetados / grow con planta)
    const objects = (m.objects || []).map(o => ({ gx: o.gx, gy: o.gy, draw: (ctx, sx, sy) => drawObject(ctx, sx, sy, o) }));

    // combinar extraFloors dentro de renderRoom: hack -> dibujar suelos extra antes
    for (const ef of extraFloors) { const s = ISO.project(ef.gx, ef.gy, game.cam); ISO.floorDiamond(ctx, s.x, s.y, ef.col, ef.edge); }

    // paredes 'H'/'P' como objetos altos
    for (const w of walls) objects.push({ gx: w.gx, gy: w.gy, draw: (ctx, sx, sy) => ISO.cube(ctx, sx, sy, w.h, w.pal) });

    ISO.renderRoom(ctx, m, game.cam, now, actors, objects);

    // etiqueta del objeto/npc al frente si el jugador mira algo interactuable
    hudFacingLabel(ctx, m);
    envTint(ctx);
  }

  function drawObject(ctx, sx, sy, o) {
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
