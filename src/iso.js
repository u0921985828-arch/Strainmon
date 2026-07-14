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

  // rombo de suelo con relieve + grano sutil (textura, no plano)
  function floorDiamond(ctx, sx, sy, top, side) {
    ctx.beginPath();
    ctx.moveTo(sx, sy);
    ctx.lineTo(sx + TW / 2, sy + TH / 2);
    ctx.lineTo(sx, sy + TH);
    ctx.lineTo(sx - TW / 2, sy + TH / 2);
    ctx.closePath();
    ctx.fillStyle = top; ctx.fill();
    // grano: motas claras/oscuras deterministas dentro del rombo
    let seed = ((((sx | 0) * 13) ^ ((sy | 0) * 7)) >>> 0) || 1;
    const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
    const cy = sy + TH / 2, dk = shade(top, -0.07), lt = shade(top, 0.07);
    for (let i = 0; i < 6; i++) {
      const u = (rnd() * 2 - 1), v = (rnd() * 2 - 1);
      if (Math.abs(u) + Math.abs(v) > 0.9) continue;         // dentro del rombo
      ctx.fillStyle = rnd() < 0.5 ? dk : lt;
      ctx.fillRect((sx + u * (TW / 2)) | 0, (cy + v * (TH / 2)) | 0, 2, 2);
    }
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
  function prop(ctx, sx, sy, kind, opt) {
    const midY = sy + TH / 2;
    if (kind === 'grass') {
      // HIERBA ALTA: matas de briznas verticales (textura + oclusión por profundidad)
      const base = (opt && opt.col) || '#4f9e3a', dark = shade(base, -0.22), tip = shade(base, 0.28);
      let s2 = ((((sx | 0) * 17) ^ ((sy | 0) * 11)) >>> 0) || 1;
      const r = () => { s2 = (s2 * 1664525 + 1013904223) >>> 0; return s2 / 4294967296; };
      const blades = [[-11, 11], [-7, 15], [-3, 12], [1, 16], [5, 13], [9, 15], [12, 10], [-1, 9]];
      for (const [bx, bh] of blades) {
        const rx = sx + bx + (r() * 2 - 1), top = midY - bh - r() * 3;
        ctx.strokeStyle = r() < 0.5 ? base : dark; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(rx, midY + 5); ctx.lineTo(rx + (r() * 3 - 1.5), top); ctx.stroke();
        ctx.fillStyle = tip; ctx.fillRect((rx - 1) | 0, (top - 1) | 0, 2, 2);
      }
      return;
    }
    // sombra de contacto suave (asienta el prop en el suelo)
    const shadow = (w, o) => { ctx.fillStyle = 'rgba(0,0,0,' + (o || 0.16) + ')'; ctx.beginPath(); ctx.ellipse(sx, midY + 2, w, w * 0.4, 0, 0, 6.283); ctx.fill(); };
    const ell = (x, y, rx, ry, c) => { ctx.fillStyle = c; ctx.beginPath(); ctx.ellipse(x, y, rx, ry, 0, 0, 6.283); ctx.fill(); };
    switch (kind) {
      case 'hedge': case 'hedgeDark': {
        // seto bajo y recortado: prisma corto + remate redondeado, sombreado limpio
        const g = kind === 'hedgeDark'
          ? { top: '#4c8a3f', left: '#2f5628', right: '#3c6e33', hi: '#61a24e' }
          : { top: '#5ba047', left: '#356b2c', right: '#478139', hi: '#7ac05e' };
        const h = 11;
        shadow(TW * 0.44);
        cube(ctx, sx, sy, h, { top: g.top, left: g.left, right: g.right });
        ell(sx, sy + TH / 2 - h, TW * 0.30, TH * 0.40, g.top);       // remate redondeado
        ell(sx - TW * 0.10, sy + TH / 2 - h - 1, TW * 0.16, TH * 0.22, g.hi); // brillo suave
        break;
      }
      case 'tree': {
        shadow(TW * 0.30);
        px(ctx, sx - 2, midY - 4, 5, 14, '#7a5533'); px(ctx, sx - 2, midY - 4, 2, 14, '#5c3f26');
        ell(sx, midY - 18, TW * 0.28, TH * 0.8, '#2f5f28');           // copa (sombra)
        ell(sx - 1, midY - 20, TW * 0.24, TH * 0.68, '#4e8f40');      // copa
        ell(sx - 5, midY - 24, TW * 0.12, TH * 0.34, '#66ad54');      // brillo
        break;
      }
      case 'rock': case 'rockDark': {
        const g = kind === 'rockDark' ? { a: '#463636', b: '#2c2220' } : { a: '#847d8b', b: '#565160' };
        const c3 = kind === 'rockDark' ? '#5c4642' : '#a29caa';
        shadow(TW * 0.34);
        const bo = (dx, dy, r, col, hi) => { ell(sx + dx, midY + dy, r, r * 0.7, col); ell(sx + dx - r * 0.28, midY + dy - r * 0.34, r * 0.36, r * 0.26, hi); };
        bo(-6, 2, 8, g.b, g.a); bo(7, 3, 7, g.b, g.a); bo(0, -3, 10, g.a, c3);
        break;
      }
      case 'snow': {
        shadow(TW * 0.36, 0.12);
        ell(sx, midY - 1, TW * 0.32, TH * 0.62, '#d3e0ea');           // banco de nieve
        ell(sx - 2, midY - 5, TW * 0.24, TH * 0.46, '#eef4f8');
        ell(sx - 5, midY - 8, TW * 0.12, TH * 0.26, '#ffffff');       // brillo
        break;
      }
      case 'reed': {
        shadow(TW * 0.24, 0.12);
        const blades = [[-9, 16], [-4, 20], [1, 14], [5, 19], [9, 15]];
        for (let i = 0; i < blades.length; i++) { const rx = sx + blades[i][0], top = midY + 2 - blades[i][1]; ctx.strokeStyle = i % 2 ? '#586324' : '#7d8d3c'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(rx, midY + 4); ctx.lineTo(rx, top); ctx.stroke(); ctx.fillStyle = '#c9b24a'; ctx.fillRect(rx - 1, top - 2, 2, 3); }
        break;
      }
      case 'palm': {
        shadow(TW * 0.26);
        px(ctx, sx - 2, midY - 6, 4, 18, '#9a6a3a'); px(ctx, sx - 2, midY - 6, 1, 18, '#6e4826');
        ctx.strokeStyle = '#4faf6a'; ctx.lineWidth = 2.4;
        for (const ang of [3.85, 5.05, 4.45, -0.25, 0.75]) { ctx.beginPath(); ctx.moveTo(sx, midY - 20); ctx.lineTo(sx + Math.cos(ang) * 16, midY - 20 + Math.sin(ang) * 9); ctx.stroke(); }
        ell(sx, midY - 20, 3.5, 2.6, '#357b4a');
        break;
      }
      case 'cactus': {
        shadow(TW * 0.2, 0.14);
        const g = '#4f9a45', gd = '#347030', hi = '#63b358', b0 = midY + 4;
        px(ctx, sx - 3, b0 - 24, 6, 24, g); px(ctx, sx - 3, b0 - 24, 2, 24, gd); px(ctx, sx + 1, b0 - 24, 1, 24, hi);
        px(ctx, sx - 8, b0 - 14, 3, 3, g); px(ctx, sx - 8, b0 - 20, 3, 7, g);
        px(ctx, sx + 5, b0 - 11, 3, 3, g); px(ctx, sx + 5, b0 - 17, 3, 7, g);
        break;
      }
      case 'fence': default: {
        // valla fina de madera: 2 travesaños + postes esbeltos
        const w = '#bd8f56', d = '#7a5533', hi = '#d3ab73', by = sy + TH * 0.60;
        shadow(TW * 0.4, 0.12);
        ctx.fillStyle = w; ctx.fillRect(sx - 17, by - 15, 34, 2); ctx.fillRect(sx - 17, by - 9, 34, 2);
        for (const dx of [-13, 0, 13]) { ctx.fillStyle = d; ctx.fillRect(sx + dx - 1, by - 20, 3, 20); ctx.fillStyle = w; ctx.fillRect(sx + dx - 1, by - 20, 2, 20); ctx.fillStyle = hi; ctx.fillRect(sx + dx - 1, by - 20, 2, 2); }
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
