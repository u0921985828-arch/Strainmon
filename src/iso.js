/* ============================================================
   STRAINMON — iso.js
   Motor isométrico original (proyección 2:1, painter's algorithm).
   Sin relación con Habbo/Sulake: matemática y arte propios.
   ============================================================ */
(function (PH) {
  'use strict';
  const { shade } = PH.util;
  const TW = 64, TH = 32;            // ancho/alto de rombo de suelo (2:1)
  const WH = 40;                     // alto de pared/cubo
  const px = (ctx, x, y, w, h, c) => { ctx.fillStyle = c; ctx.fillRect(x, y, w, h); };

  // grid -> pantalla (centro superior del rombo)
  function project(gx, gy, cam) {
    return {
      x: (gx - gy) * (TW / 2) + cam.x,
      y: (gx + gy) * (TH / 2) + cam.y,
    };
  }
  // pantalla -> grid (para clics). Mapea al CENTRO del rombo (project da el
  // vértice superior), por lo que se resta TH/2 y se redondea al tile más
  // cercano (snap-to-grid correcto, sin sesgo en negativos).
  function unproject(sx, sy, cam) {
    const u = (sx - cam.x) / (TW / 2);          // = gx - gy
    const v = (sy - cam.y - TH / 2) / (TH / 2); // = gx + gy
    return { gx: Math.round((u + v) / 2), gy: Math.round((v - u) / 2) };
  }

  // rombo de suelo con relieve
  function floorDiamond(ctx, sx, sy, top, side) {
    ctx.beginPath();
    ctx.moveTo(sx, sy);
    ctx.lineTo(sx + TW / 2, sy + TH / 2);
    ctx.lineTo(sx, sy + TH);
    ctx.lineTo(sx - TW / 2, sy + TH / 2);
    ctx.closePath();
    ctx.fillStyle = top; ctx.fill();
    ctx.strokeStyle = side; ctx.lineWidth = 1; ctx.stroke();
  }

  // cubo (pared / bloque) de altura h
  function cube(ctx, sx, sy, h, pal) {
    const topY = sy - h;
    // cara izquierda
    ctx.beginPath();
    ctx.moveTo(sx - TW / 2, sy + TH / 2);
    ctx.lineTo(sx, sy + TH);
    ctx.lineTo(sx, sy + TH - h);
    ctx.lineTo(sx - TW / 2, sy + TH / 2 - h);
    ctx.closePath(); ctx.fillStyle = pal.left; ctx.fill();
    // cara derecha
    ctx.beginPath();
    ctx.moveTo(sx + TW / 2, sy + TH / 2);
    ctx.lineTo(sx, sy + TH);
    ctx.lineTo(sx, sy + TH - h);
    ctx.lineTo(sx + TW / 2, sy + TH / 2 - h);
    ctx.closePath(); ctx.fillStyle = pal.right; ctx.fill();
    // tapa
    ctx.beginPath();
    ctx.moveTo(sx, sy - h);
    ctx.lineTo(sx + TW / 2, sy + TH / 2 - h);
    ctx.lineTo(sx, sy + TH - h);
    ctx.lineTo(sx - TW / 2, sy + TH / 2 - h);
    ctx.closePath(); ctx.fillStyle = pal.top; ctx.fill();
  }

  // Personaje isométrico. Si hay sprite de arte para su rol+dirección, lo usa
  // (billboard anclado a la base, con bob al andar); si no, dibujo procedural.
  const CHAR_H = 42;
  function actor(ctx, sx, sy, dir, frame, p, char) {
    const cx = sx, by = sy + TH / 2;
    if (char && PH.charart && PH.charart.has(char)) {
      const im = PH.charart.img(char, dir);
      if (im && im.complete && im.naturalWidth) {
        // escala 1/n (entera) para nearest-neighbor limpio: pixel-perfect.
        const s = 1 / Math.max(1, Math.round(im.naturalHeight / CHAR_H)), w = Math.round(im.naturalWidth * s), h = Math.round(im.naturalHeight * s);
        const bob = frame ? -1 : 0;
        ctx.fillStyle = 'rgba(0,0,0,.22)';
        ctx.beginPath(); ctx.ellipse(cx, by, 9, 4, 0, 0, Math.PI * 2); ctx.fill();
        ctx.drawImage(im, Math.round(cx - w / 2), Math.round(by - h + 2 + bob), w, h);
        return;
      }
    }
    p = p || { skin: '#f0c088', hair: '#3a2a1a', shirt: '#2f9e6b', pants: '#33333f' };
    const bob = frame === 1 ? 1 : 0;
    // sombra
    ctx.fillStyle = 'rgba(0,0,0,.25)';
    ctx.beginPath(); ctx.ellipse(cx, by, 10, 5, 0, 0, Math.PI * 2); ctx.fill();
    const H = 34, oy = -bob;
    // piernas
    const stride = frame === 1 ? 3 : (frame === 2 ? -3 : 0);
    px(ctx, cx - 6, by - 10 + oy, 5, 10, p.pants);
    px(ctx, cx + 1, by - 10 + oy, 5, 10, shade(p.pants, -0.15));
    // torso
    px(ctx, cx - 7, by - 22 + oy, 14, 13, p.shirt);
    px(ctx, cx - 7, by - 22 + oy, 14, 2, shade(p.shirt, 0.18));
    px(ctx, cx - 7, by - 11 + oy, 14, 1, shade(p.shirt, -0.22));
    // brazos según dir (izq/der)
    const faceLeft = dir === 'NW' || dir === 'SW';
    px(ctx, cx - 9, by - 21 + oy, 3, 9, p.skin);
    px(ctx, cx + 6, by - 21 + oy, 3, 9, p.skin);
    // cabeza
    px(ctx, cx - 6, by - 34 + oy, 12, 12, p.skin);
    px(ctx, cx - 6, by - 35 + oy, 12, 4, p.hair);
    px(ctx, cx - 7, by - 33 + oy, 1, 5, p.hair);
    px(ctx, cx + 6, by - 33 + oy, 1, 5, p.hair);
    // cara (mirando N = de espaldas, S = de frente)
    const south = dir === 'SW' || dir === 'SE';
    if (south) {
      const ex = faceLeft ? -1 : 1;
      px(ctx, cx - 3, by - 29 + oy, 2, 2, '#20202a');
      px(ctx, cx + 1, by - 29 + oy, 2, 2, '#20202a');
      px(ctx, cx - 2, by - 25 + oy, 4, 1, shade(p.skin, -0.2));
    } else {
      px(ctx, cx - 6, by - 35 + oy, 12, 8, p.hair); // nuca
    }
  }

  // Caché de celdas estáticas por mapa: se escanea el grid UNA vez (no cada
  // frame). Se invalida si cambian dimensiones.
  const EMPTY = [];
  function buildCells(map) {
    const H = map.grid.length, W = map.grid[0].length;
    const floors = [], walls = [];
    for (let gy = 0; gy < H; gy++) {
      const row = map.grid[gy];
      for (let gx = 0; gx < W; gx++) {
        const ch = row[gx];
        if (ch === '.' || ch === 'D') floors.push({ gx, gy, door: ch === 'D', alt: (gx + gy) & 1 });
        else if (ch === '#') walls.push({ gx, gy });
      }
    }
    return { w: W, h: H, floors, walls };
  }

  // Pool de entradas ordenables (reutilizado entre frames -> cero allocs/GC).
  const _pool = [];
  const _order = [];
  function slot(i) { return _pool[i] || (_pool[i] = { t: 0, d: 0, ref: null, gx: 0, gy: 0 }); }

  // Render de una sala/mapa iso con painter's algorithm.
  // map.grid: '.'=suelo, '#'=pared, ' '=vacío, 'D'=puerta(suelo). objects: [{gx,gy,draw}]
  function renderRoom(ctx, map, cam, t, actors, objectsOverride) {
    const P = map.pal || THEMES[map.theme] || THEMES.room;
    let c = map._cache;
    if (!c || c.w !== map.grid[0].length || c.h !== map.grid.length) c = map._cache = buildCells(map);
    const cx = cam.x, cy = cam.y;

    // 1) suelos (no ocluyen) — desde caché, proyección inline
    const fl = c.floors;
    for (let i = 0; i < fl.length; i++) {
      const f = fl[i];
      floorDiamond(ctx, (f.gx - f.gy) * (TW / 2) + cx, (f.gx + f.gy) * (TH / 2) + cy,
        f.door ? P.door : (f.alt ? P.floorA : P.floorB), P.floorEdge);
    }

    // 2) drawables ordenados por profundidad (painter). Entradas pooled.
    const objs = objectsOverride || map.objects || EMPTY;
    const acts = actors || EMPTY, wl = c.walls;
    _order.length = 0;
    let n = 0;
    for (let i = 0; i < wl.length; i++) { const w = wl[i]; const e = slot(n++); e.t = 0; e.ref = w; e.gx = w.gx; e.gy = w.gy; e.d = w.gx + w.gy; _order.push(e); }
    for (let i = 0; i < objs.length; i++) { const o = objs[i]; const e = slot(n++); e.t = 1; e.ref = o; e.gx = o.gx; e.gy = o.gy; e.d = o.gx + o.gy + 0.4; _order.push(e); }
    for (let i = 0; i < acts.length; i++) { const a = acts[i]; const e = slot(n++); e.t = 2; e.ref = a; e.gx = a.gx; e.gy = a.gy; e.d = a.gx + a.gy + 0.5; _order.push(e); }
    _order.sort(byDepth);
    for (let i = 0; i < _order.length; i++) {
      const e = _order[i];
      const sx = (e.gx - e.gy) * (TW / 2) + cx, sy = (e.gx + e.gy) * (TH / 2) + cy;
      if (e.t === 0) cube(ctx, sx, sy, WH, P.wall);
      else if (e.t === 1) e.ref.draw(ctx, sx, sy, e.ref);
      else actor(ctx, sx, sy, e.ref.dir, e.ref.frame, e.ref.pal, e.ref.char);
    }
  }
  function byDepth(p, q) { return p.d - q.d; }

  const THEMES = {
    room: { floorA: '#c8a06a', floorB: '#bd9560', floorEdge: 'rgba(80,50,20,.35)', door: '#8a5a30',
      wall: { top: '#e7ddcf', left: '#b9ac97', right: '#cdc2ad' } },
    grass: { floorA: '#7cbd50', floorB: '#72b048', floorEdge: 'rgba(30,60,20,.3)', door: '#caa96b',
      wall: { top: '#8a8f97', left: '#6d727a', right: '#7d828a' } },
    street: { floorA: '#8b8f96', floorB: '#82868d', floorEdge: 'rgba(20,20,25,.35)', door: '#caa96b',
      wall: { top: '#c86b52', left: '#8f3f30', right: '#a85040' } },
  };

  PH.iso = { TW, TH, WH, project, unproject, floorDiamond, cube, actor, renderRoom, THEMES };
})(window.PH = window.PH || {});
