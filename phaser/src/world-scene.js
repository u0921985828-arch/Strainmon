/* WorldScene: motor top-down ortogonal sobre PH.world (tiles/colisiones/warps/
   NPCs/encuentros). Reutiliza TODA la lógica y la UI DOM del juego vanilla.
   Movimiento por rejilla, pixel-perfect (posiciones enteras). */
SM.WorldScene = class WorldScene extends Phaser.Scene {
  constructor() { super('World'); }

  create() {
    const T = SM.TILE, W = PH.world;
    this.T = T; this.W = W;

    // --- shim de PH.game que espera la UI/misiones ---
    PH.game = PH.game || {};
    PH.game.mode = 'overworld';
    PH.game.roomName = () => { const m = this.map; return m ? m.name : ''; };
    PH.game.afterQuestCheck = () => { const done = PH.quests.checkAll ? PH.quests.checkAll() : []; for (const q of done) PH.ui.toast('✅ Misión: ' + q.name, 'ok'); PH.ui.updateHUD(); };
    PH.game.canWalk = (id, x, y) => { const m = W.MAPS[id]; return m ? !W.solidAt(m, x, y) : false; };

    // --- arte + UI DOM ---
    ['sprites', 'plantart', 'strainart', 'charart', 'furniart'].forEach(k => PH[k] && PH[k].preload && PH[k].preload());
    PH.ui.init();

    // --- partida (nueva si no hay guardado) en el mundo top-down ---
    if (PH.state.hasSave && PH.state.hasSave()) PH.state.load(); else PH.state.reset();
    const p = PH.state.get().player;
    if (!W.MAPS[p.map]) { p.map = 'lab'; const s = W.MAPS.lab.spawn; p.x = s.x; p.y = s.y; }
    p.iso = false; if (!p.dir) p.dir = 'down';

    // --- grupos de render ---
    this.tileLayer = this.add.group();
    this.objLayer = this.add.group();
    this.buildMap(p.map);

    this.player = this.add.image(0, 0, 'a_player').setDepth(50);
    this.syncPlayerPx(true);

    const cam = this.cameras.main;
    cam.roundPixels = true;
    cam.startFollow(this.player, true, 1, 1);
    this.applyZoom();
    this.scale.on('resize', () => this.applyZoom());

    this.bindInput();
    PH.ui.updateHUD();
    PH.ui.toast('Bienvenido a Villa Semilla. Explora (WASD).', 'ok');

    // stepping
    this.moving = false; this.fromX = 0; this.fromY = 0; this.moveT = 0; this.MOVE_MS = 130;
    this.DIRV = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] };
  }

  applyZoom() {
    const vw = this.scale.width, vh = this.scale.height;
    const z = Phaser.Math.Clamp(Math.floor(Math.min(vw / SM.BASE_W, vh / SM.BASE_H)) || 1, 2, 6);
    this.cameras.main.setZoom(z);
  }

  buildMap(id) {
    this.tileLayer.clear(true, true); this.objLayer.clear(true, true);
    const m = this.W.MAPS[id]; this.map = m;
    const T = this.T;
    for (let y = 0; y < m.grid.length; y++) {
      const row = m.grid[y];
      for (let x = 0; x < row.length; x++) {
        const t = this.W.TILE ? this.W.TILE[row[x]] : null;
        const base = (m.biome && this.textures.exists('t_' + this.biomeFloor(m))) ? this.biomeFloor(m) : 'grass';
        const name = t ? t.name : base;
        const key = this.textures.exists('t_' + name) ? 't_' + name : 't_' + base;
        this.tileLayer.add(this.add.image(x * T, y * T, key).setOrigin(0).setDepth(0));
      }
    }
    (m.npcs || []).forEach(n => {
      const im = this.add.image(n.x * T + T / 2, n.y * T + T / 2, 'a_npc').setDepth(40);
      im._npc = n; this.objLayer.add(im);
    });
    const dm = this.W.dims(m);
    this.cameras.main.setBounds(0, 0, dm.w * T, dm.h * T);
    this.physics && null;
  }
  biomeFloor(m) { return ({ meadow: 'grass', forest: 'grass', swamp: 'mud', desert: 'sand', volcano: 'ash', snow: 'snow', cave: 'cavefloor', island: 'sand' })[m.theme] || 'grass'; }

  syncPlayerPx(snap) {
    const p = PH.state.get().player, T = this.T;
    this.player.x = Math.round(p.x * T + T / 2);
    this.player.y = Math.round(p.y * T + T / 2);
  }

  bindInput() {
    this.keys = this.input.keyboard.addKeys('W,A,S,D,UP,DOWN,LEFT,RIGHT,SPACE,E,ESC,I,B,C,L,G,Q,M,N');
    // teclas de panel (reutilizan la UI DOM)
    const open = { I: () => PH.ui.bag(), B: () => PH.ui.bank(), C: () => PH.ui.catalog(), L: () => PH.ui.lab(), G: () => PH.ui.greenhouse(), Q: () => PH.ui.quests() };
    for (const k of Object.keys(open)) this.keys[k].on('down', () => { if (PH.game.mode === 'overworld') open[k](); });
    this.keys.M.on('down', () => { PH.state.save(); PH.ui.toast('Guardado.', 'ok'); });
    this.keys.N.on('down', () => { const mm = PH.audio && PH.audio.toggleMute(); PH.ui.toast(mm ? '🔇' : '🔊', ''); });
    const act = () => { if (PH.game.mode === 'dialog') PH.ui.dialogNext(); else if (PH.ui.isOpen()) PH.ui.close(); else this.interact(); };
    this.keys.SPACE.on('down', act); this.keys.E.on('down', act);
    this.keys.ESC.on('down', () => { if (PH.ui.isOpen()) PH.ui.close(); });
    // d-pad táctil (mantener para moverse)
    document.querySelectorAll('[data-dir]').forEach(btn => {
      const d = btn.dataset.dir;
      const on = (e) => { e.preventDefault(); this.held = d; };
      const off = (e) => { if (e) e.preventDefault(); if (this.held === d) this.held = null; };
      btn.addEventListener('touchstart', on, { passive: false }); btn.addEventListener('touchend', off);
      btn.addEventListener('mousedown', on); btn.addEventListener('mouseup', off); btn.addEventListener('mouseleave', off);
    });
    // botones de acción/panel [data-key]
    document.querySelectorAll('[data-key]').forEach(btn => btn.addEventListener('click', () => this.pressKey(btn.dataset.key)));
  }
  pressKey(k) {
    const map = { i: () => PH.ui.bag(), b: () => PH.ui.bank(), c: () => PH.ui.catalog(), l: () => PH.ui.lab(), g: () => PH.ui.greenhouse(), q: () => PH.ui.quests() };
    if (k === 'm') { PH.state.save(); PH.ui.toast('Guardado.', 'ok'); return; }
    if (k === 'n') { const mm = PH.audio && PH.audio.toggleMute(); PH.ui.toast(mm ? '🔇' : '🔊', ''); return; }
    if (k === ' ' || k === 'e') { if (PH.game.mode === 'dialog') return PH.ui.dialogNext(); if (PH.ui.isOpen()) return PH.ui.close(); return this.interact(); }
    if (k === 'escape') { if (PH.ui.isOpen()) PH.ui.close(); return; }
    if (map[k] && PH.game.mode === 'overworld') map[k]();
  }

  heldDir() {
    const K = this.keys;
    if (K.A.isDown || K.LEFT.isDown) return 'left';
    if (K.D.isDown || K.RIGHT.isDown) return 'right';
    if (K.W.isDown || K.UP.isDown) return 'up';
    if (K.S.isDown || K.DOWN.isDown) return 'down';
    return this.held || null;
  }

  update(time, dt) {
    if (PH.game.mode !== 'overworld') { this.held = null; return; }
    const p = PH.state.get().player, T = this.T;
    if (this.moving) {
      this.moveT += dt;
      const k = Phaser.Math.Clamp(this.moveT / this.MOVE_MS, 0, 1);
      this.player.x = Math.round(Phaser.Math.Linear(this.fromX, p.x * T + T / 2, k));
      this.player.y = Math.round(Phaser.Math.Linear(this.fromY, p.y * T + T / 2, k));
      if (k >= 1) { this.moving = false; this.onArrive(); }
      return;
    }
    const dir = this.heldDir(); this.held = null;
    if (!dir) return;
    p.dir = dir;
    const [dx, dy] = this.DIRV[dir];
    const nx = p.x + dx, ny = p.y + dy;
    if (this.W.solidAt(this.map, nx, ny)) { this.syncPlayerPx(); return; }
    this.fromX = this.player.x; this.fromY = this.player.y;
    p.x = nx; p.y = ny; this.moving = true; this.moveT = 0;
    if (PH.audio) PH.audio.sfx && PH.audio.sfx('step');
  }

  onArrive() {
    const p = PH.state.get().player, m = this.map;
    PH.state.get().stats.distance = (PH.state.get().stats.distance || 0) + 1;
    // warp
    const w = this.W.warpAt(m, p.x, p.y);
    if (w) {
      if (String(w.to)[0] === '@') { PH.ui.placeMenu(w.to); return; }
      const t = this.W.MAPS[w.to]; if (t) { p.map = w.to; p.x = w.x != null ? w.x : t.spawn.x; p.y = w.y != null ? w.y : t.spawn.y; this.buildMap(w.to); this.syncPlayerPx(true); PH.ui.updateHUD(); PH.ui.toast('📍 ' + t.name, ''); return; }
    }
    // encuentro
    if (m.biome && this.W.encounterAt(m, p.x, p.y) && PH.util.RNG.chance(0.18)) {
      PH.ui.encounter(PH.species.rollEncounter(m.biome, PH.state.get().env));
    }
  }

  interact() {
    const p = PH.state.get().player, m = this.map;
    const [dx, dy] = this.DIRV[p.dir] || [0, 1];
    const fx = p.x + dx, fy = p.y + dy;
    const npc = (m.npcs || []).find(n => n.x === fx && n.y === fy);
    if (npc) {
      const pages = (PH.quests.DIALOGS && PH.quests.DIALOGS[npc.dialog]) ? PH.quests.DIALOGS[npc.dialog](PH.state.get()) : ['...'];
      PH.ui.dialog(pages, null, { sprite: npc.sprite, name: npc.name });
      return;
    }
    // warp por interacción (puertas de pueblo)
    const w = this.W.warpAt(m, fx, fy);
    if (w && String(w.to)[0] === '@') PH.ui.placeMenu(w.to);
  }
};
