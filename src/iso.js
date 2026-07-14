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

  // Props de borde/escenario para zonas naturales (setos, vallas, rocas, cañas,
  // palmeras, árboles, cactus…) — arte propio por código, en la proyección iso.
  // Sustituyen a los cubos '#' en los biomas para que los bordes no sean bloques.
  function prop(ctx, sx, sy, kind) {
    let seed = ((((sx | 0) * 131) ^ ((sy | 0) * 57)) >>> 0) || 1;
    const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
    const dot = (x, y, c, s) => { ctx.fillStyle = c; ctx.fillRect(x | 0, y | 0, s || 2, s || 2); };
    const midY = sy + TH / 2;
    switch (kind) {
      case 'hedge': case 'hedgeDark': {
        const g = kind === 'hedgeDark'
          ? { top: '#4a7f3c', left: '#2c4f24', right: '#39682f', d1: '#5c9a48', d2: '#24401d', h: 26 }
          : { top: '#63ab4e', left: '#356b2c', right: '#48853a', d1: '#7cc760', d2: '#2c5a24', h: 20 };
        cube(ctx, sx, sy, g.h, { top: g.top, left: g.left, right: g.right });
        ctx.fillStyle = g.top; ctx.beginPath(); ctx.ellipse(sx, sy + TH / 2 - g.h, TW * 0.34, TH * 0.5, 0, 0, 6.283); ctx.fill();
        for (let i = 0; i < 18; i++) { const a = rnd() * 6.283, r = rnd(); dot(sx + Math.cos(a) * r * TW * 0.3, sy + TH / 2 - g.h + Math.sin(a) * r * TH * 0.45, rnd() < 0.5 ? g.d1 : g.d2); }
        for (let i = 0; i < 8; i++) dot(sx - TW / 2 + rnd() * TW, sy + TH * 0.4 - rnd() * g.h, g.d2);
        break;
      }
      case 'tree': {
        px(ctx, sx - 3, midY - 6, 6, 18, '#7a5533'); px(ctx, sx - 3, midY - 6, 2, 18, '#5c3f26');
        const d1 = '#66ad54', d2 = '#2f5f28';
        ctx.fillStyle = '#4e8f40';
        ctx.beginPath(); ctx.ellipse(sx, midY - 22, TW * 0.32, TH * 0.95, 0, 0, 6.283); ctx.fill();
        ctx.beginPath(); ctx.ellipse(sx - 9, midY - 15, TW * 0.2, TH * 0.62, 0, 0, 6.283); ctx.fill();
        ctx.beginPath(); ctx.ellipse(sx + 9, midY - 17, TW * 0.2, TH * 0.62, 0, 0, 6.283); ctx.fill();
        for (let i = 0; i < 22; i++) { const a = rnd() * 6.283, r = rnd(); dot(sx + Math.cos(a) * r * TW * 0.3, midY - 19 + Math.sin(a) * r * TH * 0.9, rnd() < 0.5 ? d1 : d2); }
        break;
      }
      case 'rock': case 'rockDark': {
        const g = kind === 'rockDark' ? { a: '#4a3a3a', b: '#2e2422', c: '#5f4a46', ember: '#d5713f' } : { a: '#8b8492', b: '#57525f', c: '#a8a2b0' };
        const bo = (dx, dy, r, col, hi) => { ctx.fillStyle = col; ctx.beginPath(); ctx.ellipse(sx + dx, midY + dy, r, r * 0.72, 0, 0, 6.283); ctx.fill(); ctx.fillStyle = hi; ctx.beginPath(); ctx.ellipse(sx + dx - r * 0.3, midY + dy - r * 0.4, r * 0.42, r * 0.3, 0, 0, 6.283); ctx.fill(); };
        bo(-8, 3, 11, g.b, g.a); bo(9, 5, 10, g.b, g.a); bo(0, -6, 13, g.a, g.c);
        if (g.ember) for (let i = 0; i < 4; i++) dot(sx - 8 + rnd() * 16, midY - 2 + rnd() * 8, g.ember);
        break;
      }
      case 'snow': {
        ctx.fillStyle = '#e8eef2'; ctx.beginPath(); ctx.ellipse(sx, midY - 1, TW * 0.36, TH * 0.82, 0, 0, 6.283); ctx.fill();
        ctx.fillStyle = '#ffffff'; ctx.beginPath(); ctx.ellipse(sx - 4, midY - 8, TW * 0.2, TH * 0.5, 0, 0, 6.283); ctx.fill();
        for (let i = 0; i < 8; i++) dot(sx - TW * 0.3 + rnd() * TW * 0.6, midY - 1 + rnd() * 8, '#c4dbe6');
        break;
      }
      case 'reed': {
        for (let i = 0; i < 7; i++) { const rx = sx - 16 + i * 5 + rnd() * 2, top = midY - 18 - rnd() * 10; ctx.strokeStyle = i % 2 ? '#556123' : '#7a8a3a'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(rx, midY + 6); ctx.lineTo(rx + (rnd() * 4 - 2), top); ctx.stroke(); dot(rx - 1, top - 1, '#c9b24a'); }
        break;
      }
      case 'palm': {
        px(ctx, sx - 2, midY - 4, 4, 16, '#9a6a3a'); px(ctx, sx - 2, midY - 4, 1, 16, '#6e4826');
        ctx.strokeStyle = '#4faf6a'; ctx.lineWidth = 3;
        for (const ang of [3.9, 5.0, 4.45, -0.3, 0.8]) { ctx.beginPath(); ctx.moveTo(sx, midY - 18); ctx.lineTo(sx + Math.cos(ang) * 18, midY - 18 + Math.sin(ang) * 10); ctx.stroke(); }
        ctx.fillStyle = '#357b4a'; ctx.beginPath(); ctx.ellipse(sx, midY - 18, 4, 3, 0, 0, 6.283); ctx.fill();
        break;
      }
      case 'cactus': {
        const g = '#4f9a45', gd = '#347030', hi = '#63b358', b0 = midY + 4;
        px(ctx, sx - 3, b0 - 26, 6, 26, g); px(ctx, sx - 3, b0 - 26, 2, 26, gd); px(ctx, sx + 1, b0 - 26, 2, 26, hi);
        px(ctx, sx - 8, b0 - 16, 3, 3, g); px(ctx, sx - 8, b0 - 22, 3, 7, g);
        px(ctx, sx + 5, b0 - 12, 3, 3, g); px(ctx, sx + 5, b0 - 18, 3, 7, g);
        break;
      }
      case 'fence': default: {
        const w = '#b98a52', d = '#7a5533', by = sy + TH * 0.62;
        ctx.fillStyle = w; ctx.fillRect(sx - 17, by - 20, 34, 3); ctx.fillRect(sx - 17, by - 12, 34, 3);
        ctx.fillStyle = d; ctx.fillRect(sx - 17, by - 20, 34, 1); ctx.fillRect(sx - 17, by - 12, 34, 1);
        for (const dx of [-14, 14]) { ctx.fillStyle = w; ctx.fillRect(sx + dx - 2, by - 26, 4, 26); ctx.fillStyle = d; ctx.fillRect(sx + dx - 2, by - 26, 1, 26); ctx.fillStyle = shade(w, 0.15); ctx.fillRect(sx + dx - 2, by - 26, 4, 2); }
        break;
      }
    }
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
        // en zonas naturales el borde '#' se dibuja como prop (seto/valla/roca…) en isogame, no como cubo
        else if (ch === '#' && !map.natural) walls.push({ gx, gy });
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

  PH.iso = { TW, TH, WH, project, unproject, floorDiamond, cube, prop, actor, renderRoom, THEMES };
})(window.PH = window.PH || {});
