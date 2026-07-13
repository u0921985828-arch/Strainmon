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
  // pantalla -> grid (para clics)
  function unproject(sx, sy, cam) {
    const x = sx - cam.x, y = sy - cam.y;
    return { gx: Math.floor((y / (TH / 2) + x / (TW / 2)) / 2), gy: Math.floor((y / (TH / 2) - x / (TW / 2)) / 2) };
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

  // Personaje isométrico (billboard chibi original) anclado a la base del tile.
  function actor(ctx, sx, sy, dir, frame, p) {
    p = p || { skin: '#f0c088', hair: '#3a2a1a', shirt: '#2f9e6b', pants: '#33333f' };
    const cx = sx, by = sy + TH / 2;         // base ~ centro del tile
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

  // Render de una sala/mapa iso con painter's algorithm.
  // map.grid: '.'=suelo, '#'=pared, ' '=vacío, 'D'=puerta(suelo). objects: [{gx,gy,h,draw}]
  function renderRoom(ctx, map, cam, t, actors) {
    const W = map.grid[0].length, Hh = map.grid.length;
    const P = map.pal || THEMES.room;
    // 1) suelos primero (no ocluyen)
    for (let gy = 0; gy < Hh; gy++) for (let gx = 0; gx < W; gx++) {
      const ch = map.grid[gy][gx];
      if (ch === '.' || ch === 'D') {
        const s = project(gx, gy, cam);
        const alt = (gx + gy) % 2;
        floorDiamond(ctx, s.x, s.y, ch === 'D' ? P.door : (alt ? P.floorA : P.floorB), P.floorEdge);
      }
    }
    // 2) drawables con profundidad (paredes, objetos, actores)
    const list = [];
    for (let gy = 0; gy < Hh; gy++) for (let gx = 0; gx < W; gx++) {
      if (map.grid[gy][gx] === '#') {
        const s = project(gx, gy, cam);
        list.push({ d: gx + gy, draw: () => cube(ctx, s.x, s.y, WH, P.wall) });
      }
    }
    for (const o of (map.objects || [])) {
      const s = project(o.gx, o.gy, cam);
      list.push({ d: o.gx + o.gy + 0.4, draw: () => o.draw(ctx, s.x, s.y, o) });
    }
    for (const a of (actors || [])) {
      const s = project(a.gx, a.gy, cam);
      list.push({ d: a.gx + a.gy + 0.5, draw: () => actor(ctx, s.x, s.y, a.dir, a.frame, a.pal) });
    }
    list.sort((p, q) => p.d - q.d);
    for (const it of list) it.draw();
  }

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
