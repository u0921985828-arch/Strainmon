/* ============================================================
   PHENO HUNTER — game.js
   Bucle principal, entrada, movimiento por rejilla, cámara,
   render del mundo, interacción con NPC/warps y encuentros.
   ============================================================ */
(function (PH) {
  'use strict';
  const { clamp } = PH.util;
  const R = PH.render;
  const World = PH.world;
  const G = () => PH.state.get();

  const game = {
    mode: 'boot',     // boot | title | overworld | menu | dialog | encounter
    canvas: null, ctx: null,
    scale: 3,
    // interpolación de movimiento
    moving: false, from: null, to: null, moveT: 0, moveDur: 150,
    frame: 0, animT: 0,
    keys: {},
    lastSave: 0,
    npcAnimT: 0,
  };
  PH.game = game;

  function init() {
    game.canvas = document.getElementById('screen');
    game.ctx = game.canvas.getContext('2d');
    game.ctx.imageSmoothingEnabled = false;
    // Búfer de mundo a resolución lógica (240x160); se escala x2 al lienzo (480x320).
    game.world = document.createElement('canvas');
    game.world.width = R.W; game.world.height = R.H;
    game.wctx = game.world.getContext('2d');
    game.wctx.imageSmoothingEnabled = false;
    game.RScale = 2;
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
    // Lienzo interno a 480x320 (x2 del mundo lógico); se ajusta a la ventana con escala entera.
    const SW = R.W * game.RScale, SH = R.H * game.RScale;
    const maxW = window.innerWidth - 24, maxH = window.innerHeight - 120;
    const sc = Math.max(1, Math.min(maxW / SW, maxH / SH));
    game.scale = sc;
    game.canvas.width = SW; game.canvas.height = SH;
    game.canvas.style.width = Math.floor(SW * sc) + 'px';
    game.canvas.style.height = Math.floor(SH * sc) + 'px';
    game.ctx.imageSmoothingEnabled = false;
  }

  /* ---------------- Título ---------------- */
  function titleScreen() {
    game.mode = 'title';
    const ov = document.getElementById('overlay');
    ov.className = 'active title';
    const cont = PH.state.hasSave() ? '<button class="btn primary big" id="t_continue">Continuar</button>' : '';
    ov.innerHTML = `
      <div class="title-screen">
        <div class="logo">STRAIN<span>MON</span></div>
        <div class="tagline">Caza cepas landrace · Preserva linajes · Cruza genéticas</div>
        <div class="title-art"><canvas id="title_canvas" width="200" height="120"></canvas></div>
        <div class="title-btns">
          ${cont}
          <button class="btn ${cont ? 'ghost' : 'primary'} big" id="t_new">Nueva partida</button>
        </div>
        <div class="title-help">Mover: WASD / Flechas · Interactuar/Confirmar: Espacio o E<br>
          I Mochila · B Banco · C Catálogo · L Laboratorio · G Invernadero · Q Misiones · M Guardar</div>
      </div>`;
    // arte: pequeño jardín de fenotipos aleatorios
    const c = document.getElementById('title_canvas'); const ctx = c.getContext('2d');
    ctx.imageSmoothingEnabled = false;
    ctx.fillStyle = '#20351f'; ctx.fillRect(0, 0, c.width, c.height);
    for (let i = 0; i < 6; i++) {
      const sp = PH.species.rollEncounter(PH.util.RNG.pick(['pradera', 'bosque', 'pantano']), G().env);
      R.drawPlant(ctx, 20 + i * 30, 108, sp.pheno, 1.6, performance.now());
    }
    if (cont) document.getElementById('t_continue').onclick = () => { PH.state.load(); startGame(); };
    document.getElementById('t_new').onclick = () => { PH.state.reset(); startGame(); };
  }

  function startGame() {
    PH.ui.close();
    game.mode = 'overworld';
    const s = G();
    // asegura posición válida
    const map = World.MAPS[s.player.map];
    PH.ui.updateHUD();
    PH.ui.toast('¡Bienvenido a Strainmon!', 'ok');
  }

  /* ---------------- Entrada ---------------- */
  function bindInput() {
    window.addEventListener('keydown', (e) => {
      const k = e.key.toLowerCase();
      game.keys[k] = true;
      // Confirmaciones de diálogo/encuentro
      if (game.mode === 'dialog' && (k === ' ' || k === 'e' || k === 'enter')) { e.preventDefault(); PH.ui.dialogNext(); return; }
      if (game.mode === 'title') return;
      if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', ' '].includes(k)) e.preventDefault();

      if (game.mode === 'overworld') {
        if (k === ' ' || k === 'e') interact();
        else if (k === 'i') PH.ui.bag();
        else if (k === 'b') PH.ui.bank();
        else if (k === 'c') PH.ui.catalog();
        else if (k === 'q') PH.ui.quests();
        else if (k === 'm') { PH.state.save(); PH.ui.toast('Partida guardada.', 'ok'); }
        else if (k === 'l') PH.ui.lab();
        else if (k === 'g') PH.ui.greenhouse();
      } else if (game.mode === 'menu') {
        if (k === 'escape' || k === 'i' || k === 'b' || k === 'c' || k === 'q') PH.ui.close();
      }
    });
    window.addEventListener('keyup', (e) => { game.keys[e.key.toLowerCase()] = false; });

    // Controles táctiles
    document.querySelectorAll('[data-key]').forEach(btn => {
      const key = btn.dataset.key;
      const press = (v) => { game.keys[key] = v; if (v) simulateKey(key); };
      btn.addEventListener('touchstart', (e) => { e.preventDefault(); press(true); });
      btn.addEventListener('touchend', (e) => { e.preventDefault(); game.keys[key] = false; });
      btn.addEventListener('mousedown', () => press(true));
      btn.addEventListener('mouseup', () => { game.keys[key] = false; });
      btn.addEventListener('mouseleave', () => { game.keys[key] = false; });
    });
  }
  function simulateKey(key) {
    if (game.mode === 'dialog' && (key === ' ')) { PH.ui.dialogNext(); return; }
    if (game.mode === 'overworld' && key === ' ') interact();
    if (game.mode === 'overworld' && key === 'i') PH.ui.bag();
    if (game.mode === 'overworld' && key === 'b') PH.ui.bank();
    if (game.mode === 'overworld' && key === 'c') PH.ui.catalog();
  }

  /* ---------------- Interacción ---------------- */
  function facingTile() {
    const s = G().player;
    let x = s.x, y = s.y;
    if (s.dir === 'up') y--; else if (s.dir === 'down') y++;
    else if (s.dir === 'left') x--; else if (s.dir === 'right') x++;
    return { x, y };
  }
  function interact() {
    const s = G();
    const map = World.MAPS[s.player.map];
    if (!map) return;
    const f = facingTile();
    // NPC?
    const npc = (map.npcs || []).find(n => n.x === f.x && n.y === f.y);
    if (npc) {
      // el NPC mira hacia el jugador
      npc.face = { up: 'down', down: 'up', left: 'right', right: 'left' }[s.player.dir] || 'down';
      const pages = PH.quests.DIALOGS[npc.dialog] ? PH.quests.DIALOGS[npc.dialog](s) : ['...'];
      PH.ui.dialog(pages, null, { sprite: npc.sprite, name: npc.name });
      return;
    }
    // warp de puerta al frente (edificios)?
    const w = World.warpAt(map, f.x, f.y);
    if (w && String(w.to).startsWith('@')) { PH.ui.placeMenu(w.to); }
  }

  /* ---------------- Movimiento ---------------- */
  function tryMove() {
    if (game.moving || game.mode !== 'overworld') return;
    const s = G().player;
    let dx = 0, dy = 0, dir = s.dir;
    if (game.keys['arrowup'] || game.keys['w']) { dy = -1; dir = 'up'; }
    else if (game.keys['arrowdown'] || game.keys['s']) { dy = 1; dir = 'down'; }
    else if (game.keys['arrowleft'] || game.keys['a']) { dx = -1; dir = 'left'; }
    else if (game.keys['arrowright'] || game.keys['d']) { dx = 1; dir = 'right'; }
    else return;
    s.dir = dir;
    const map = World.MAPS[s.player ? s.player.map : G().player.map] || World.MAPS[G().player.map];
    const cur = World.MAPS[G().player.map];
    const nx = s.x + dx, ny = s.y + dy;

    // warp por pisar celda numérica
    const warp = World.warpAt(cur, nx, ny);
    if (warp && !String(warp.to).startsWith('@')) {
      // comprobar desbloqueo por prestigio para regiones
      if (!PH.state.unlocked(warp.to)) {
        PH.ui.toast('🔒 Necesitas más prestigio para acceder aquí.', 'bad');
        return;
      }
      doWarp(warp);
      return;
    }
    if (warp && String(warp.to).startsWith('@')) { PH.ui.placeMenu(warp.to); return; }

    if (World.solidAt(cur, nx, ny)) return; // pared
    // NPC bloquea
    if ((cur.npcs || []).some(n => n.x === nx && n.y === ny)) return;

    game.moving = true; game.moveT = 0;
    game.from = { x: s.x, y: s.y };
    game.to = { x: nx, y: ny };
  }

  function finishMove() {
    const s = G().player;
    s.x = game.to.x; s.y = game.to.y;
    game.moving = false;
    G().stats.distance++;
    // ¿encuentro?
    const map = World.MAPS[s.map];
    if (map.biome && World.encounterAt(map, s.x, s.y)) {
      const p = PH.encounter.encounterChance(map.biome);
      if (PH.util.RNG.chance(p)) {
        if (G().player.cebosActivos > 0) G().player.cebosActivos--;
        const wild = PH.species.rollEncounter(map.biome, G().env);
        PH.ui.encounter(wild);
      }
    }
  }

  function doWarp(warp) {
    const s = G().player;
    const target = World.MAPS[warp.to];
    if (!target) return;
    s.map = warp.to;
    s.x = warp.x != null ? warp.x : target.spawn.x;
    s.y = warp.y != null ? warp.y : target.spawn.y;
    game.moving = false;
    PH.ui.updateHUD();
    PH.ui.toast('📍 ' + target.name, '');
  }

  /* ---------------- Comprobación de misiones tras acciones ---------------- */
  game.afterQuestCheck = function () {
    const done = PH.quests.checkAll();
    for (const q of done) {
      PH.ui.toast(`✅ Misión completada: ${q.name}`, 'ok');
    }
    PH.ui.updateHUD();
  };

  /* ---------------- Bucle ---------------- */
  let last = performance.now();
  function loop(now) {
    const dt = Math.min(50, now - last); last = now;
    game.animT += dt; game.npcAnimT += dt;
    if (game.animT > 260) { game.frame ^= 1; game.animT = 0; }

    if (game.mode === 'overworld' || game.mode === 'menu' || game.mode === 'dialog' || game.mode === 'encounter') {
      PH.state.updateEnv(dt);
      if (PH.events) PH.events.update(dt);
      if (PH.garden) PH.garden.update(dt);
    }
    if (game.mode === 'overworld') {
      tryMove();
      if (game.moving) {
        game.moveT += dt;
        if (game.moveT >= game.moveDur) finishMove();
      }
      // autosave cada 20s
      if (now - game.lastSave > 20000) { PH.state.save(); game.lastSave = now; }
    }

    if (game.mode !== 'title' && game.mode !== 'boot') render(now);
    // refresco de HUD ligero
    if (game.mode === 'overworld' && (game.frame === 0)) PH.ui.updateHUD();

    requestAnimationFrame(loop);
  }

  /* ---------------- Render del mundo ---------------- */
  function render(now) {
    now = now || performance.now();
    const ctx = game.wctx;            // capa MUNDO (240x160 lógico)
    const s = G().player;
    const map = World.MAPS[s.map];
    if (!map) return;
    const dims = World.dims(map);

    // posición interpolada del jugador (en px)
    let pxp, pyp;
    if (game.moving) {
      const t = clamp(game.moveT / game.moveDur, 0, 1);
      pxp = PH.util.lerp(game.from.x, game.to.x, t) * R.TS;
      pyp = PH.util.lerp(game.from.y, game.to.y, t) * R.TS;
    } else { pxp = s.x * R.TS; pyp = s.y * R.TS; }

    // cámara centrada
    let camX = pxp - (R.W / 2 - R.TS / 2);
    let camY = pyp - (R.H / 2 - R.TS / 2);
    camX = clamp(camX, 0, Math.max(0, dims.w * R.TS - R.W));
    camY = clamp(camY, 0, Math.max(0, dims.h * R.TS - R.H));

    ctx.fillStyle = '#101418'; ctx.fillRect(0, 0, R.W, R.H);

    const x0 = Math.floor(camX / R.TS), y0 = Math.floor(camY / R.TS);
    for (let ty = y0 - 1; ty <= y0 + R.VH + 1; ty++) {
      for (let tx = x0 - 1; tx <= x0 + R.VW + 1; tx++) {
        const sx = tx * R.TS - camX, sy = ty * R.TS - camY;
        R.drawTile(ctx, map, tx, ty, sx, sy, now);
      }
    }

    // NPCs
    for (const n of (map.npcs || [])) {
      const sx = n.x * R.TS - camX, sy = n.y * R.TS - camY;
      if (sx < -R.TS || sx > R.W || sy < -R.TS || sy > R.H) continue;
      R.drawActor(ctx, sx, sy, n.face || 'down', 0, R.NPC_PALETTES[n.sprite]);
      // nombre
      ctx.fillStyle = 'rgba(0,0,0,0.5)'; ctx.fillRect(sx - 4, sy - 8, n.name.length * 3 + 6, 7);
      ctx.fillStyle = '#fff'; ctx.font = '5px monospace'; ctx.textAlign = 'left';
      ctx.fillText(n.name, sx - 1, sy - 2);
    }

    // Jugador
    const psx = pxp - camX, psy = pyp - camY;
    const wf = game.moving ? (Math.floor(game.moveT / (game.moveDur / 2)) % 2 === 0 ? 1 : 2) : 0;
    R.drawActor(ctx, psx, psy, s.dir, wf,
      { skin: '#f0c088', hair: '#3a2a1a', shirt: '#2f9e6b', pants: '#33333f', pack: '#8a5a2a', hat: '#1f7a4d' });

    // Overlays ambientales (sobre el búfer de mundo)
    applyEnvOverlay(ctx);

    // --- Componer: escalar el mundo x2 al lienzo, y capa de personajes en alta resolución ---
    const m = game.ctx;
    m.imageSmoothingEnabled = false;
    m.drawImage(game.world, 0, 0, R.W * game.RScale, R.H * game.RScale);
    drawHiresLayer(m, camX, camY, now);
  }

  // Capa de sprites de alta resolución (32 px nativos). Se rellenará con el arte
  // generado (jugador, NPCs y cepas errantes). Coordenadas en espacio de lienzo (x2).
  function drawHiresLayer(m, camX, camY, now) {
    // (pendiente de sprites) — de momento el mundo escalado ya incluye actores procedurales.
  }

  function applyEnvOverlay(ctx) {
    const env = G().env;
    // tinte día/noche
    let a = 0, col = '0,0,20';
    const t = env.time;
    if (t < 5 * 60) a = 0.45;
    else if (t < 7 * 60) a = PH.util.lerp(0.45, 0, (t - 300) / 120);
    else if (t < 18 * 60) a = 0;
    else if (t < 20 * 60) a = PH.util.lerp(0, 0.4, (t - 1080) / 120);
    else a = 0.45;
    if (a > 0) { ctx.fillStyle = `rgba(${col},${a})`; ctx.fillRect(0, 0, R.W, R.H); }

    // clima
    if (env.weather === 'niebla') { ctx.fillStyle = 'rgba(200,205,215,0.28)'; ctx.fillRect(0, 0, R.W, R.H); }
    else if (env.weather === 'nublado') { ctx.fillStyle = 'rgba(120,125,135,0.14)'; ctx.fillRect(0, 0, R.W, R.H); }
    else if (env.weather === 'ola_calor') { ctx.fillStyle = 'rgba(255,160,60,0.10)'; ctx.fillRect(0, 0, R.W, R.H); }
    if (env.weather === 'lluvia' || env.weather === 'tormenta') drawRain(ctx, env.weather === 'tormenta');

    // tinte y partículas de evento raro
    if (PH.events) {
      const tint = PH.events.tint && PH.events.tint();
      if (tint) { ctx.fillStyle = tint; ctx.fillRect(0, 0, R.W, R.H); }
      const parts = PH.events.particles && PH.events.particles();
      if (parts) drawParticles(ctx, parts);
    }
  }

  let partSeed = [];
  function drawParticles(ctx, kind) {
    const n = 26;
    if (partSeed.length !== n) { partSeed = []; for (let i = 0; i < n; i++) partSeed.push([Math.random() * R.W, Math.random() * R.H, 1 + Math.random() * 2, Math.random() * 6]); }
    const t = performance.now();
    for (const d of partSeed) {
      if (kind === 'meteor') {
        const y = (d[1] + (t * 0.12 * d[2]) % R.H) % R.H;
        const x = (d[0] + (t * 0.06 * d[2]) % R.W) % R.W;
        ctx.strokeStyle = 'rgba(255,220,160,0.8)'; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x - 4, y - 6); ctx.stroke();
      } else if (kind === 'petal') {
        const y = (d[1] + (t * 0.03 * d[2]) % R.H) % R.H;
        const x = (d[0] + Math.sin((t + d[3] * 400) / 500) * 8) % R.W;
        ctx.fillStyle = 'rgba(255,150,200,0.75)'; ctx.fillRect(x, y, 2, 2);
      } else if (kind === 'spark') {
        const x = (d[0] + Math.sin((t + d[3] * 300) / 600) * 6);
        const y = (d[1] + Math.cos((t + d[3] * 300) / 700) * 6);
        ctx.fillStyle = 'rgba(160,220,255,' + (0.4 + 0.4 * Math.abs(Math.sin(t / 300 + d[3]))) + ')';
        ctx.fillRect(x, y, 1, 1);
      }
    }
  }

  let rainSeed = [];
  function drawRain(ctx, heavy) {
    const n = heavy ? 60 : 34;
    if (rainSeed.length !== n) { rainSeed = []; for (let i = 0; i < n; i++) rainSeed.push([Math.random() * R.W, Math.random() * R.H, 2 + Math.random() * 3]); }
    ctx.strokeStyle = heavy ? 'rgba(180,200,230,0.6)' : 'rgba(180,200,230,0.4)';
    ctx.lineWidth = 1;
    const t = performance.now();
    for (const d of rainSeed) {
      const y = (d[1] + (t * 0.35 * d[2]) % R.H) % R.H;
      ctx.beginPath(); ctx.moveTo(d[0], y); ctx.lineTo(d[0] - 1, y + 4); ctx.stroke();
    }
    if (heavy && Math.random() < 0.01) { ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.fillRect(0, 0, R.W, R.H); }
  }

  PH.game.init = init;
  window.addEventListener('DOMContentLoaded', init);
})(window.PH = window.PH || {});
