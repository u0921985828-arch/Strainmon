/* ============================================================
   PHENO HUNTER — render.js
   Render pixel-art 16-bit. Tiles procedurales, personajes y
   sprites de planta derivados del fenotipo. GBA: 240x160, 16px.
   ============================================================ */
(function (PH) {
  'use strict';
  const { shade } = PH.util;
  const { TILE, isWarp } = PH.world;

  const TS = 16;
  const VW = 15, VH = 10;
  const W = VW * TS, H = VH * TS;

  const THEMES = {
    town:    { grass: '#6fae4a', grassD: '#5c9a3c', path: '#caa96b', pathD: '#b2925a', blade: '#3f7d34', blade2: '#589b45' },
    meadow:  { grass: '#7cbd50', grassD: '#68a742', path: '#cbb06f', pathD: '#b2955a', blade: '#3f7d34', blade2: '#589b45' },
    forest:  { grass: '#4f9440', grassD: '#3f7d34', path: '#b39b64', pathD: '#997f4f', blade: '#2f6b2a', blade2: '#458f3a' },
    swamp:   { grass: '#5f7d47', grassD: '#4d6739', path: '#8f7c4e', pathD: '#75643d', blade: '#3d5a2c', blade2: '#4f7038' },
    desert:  { grass: '#e0cd8f', grassD: '#cbb672', path: '#d8c079', pathD: '#c0a860', blade: '#b39a4d', blade2: '#caa95c' },
    volcano: { grass: '#5a4038', grassD: '#4a332c', path: '#3a2822', pathD: '#2e201b', blade: '#8a3520', blade2: '#c04a24' },
    snow:    { grass: '#e9f0f6', grassD: '#cfd9e4', path: '#dbe6f0', pathD: '#c3d2e0', blade: '#8fb0c9', blade2: '#b6d0e2' },
    cave:    { grass: '#4a4650', grassD: '#3b3843', path: '#3a3742', pathD: '#2e2b35', blade: '#4a8f7a', blade2: '#6bd0b0' },
    island:  { grass: '#e6d79a', grassD: '#d3c17f', path: '#e0cd8f', pathD: '#cbb672', blade: '#4faf7a', blade2: '#6bd0a0' },
  };

  function px(ctx, x, y, w, h, col) { ctx.fillStyle = col; ctx.fillRect(x, y, w, h); }

  // Hash determinista 0..1 por casilla (variación estable entre frames)
  function hash(x, y) {
    let h = (x * 374761393 + y * 668265263) ^ 0x9e3779b9;
    h = Math.imul(h ^ (h >>> 13), 1274126177);
    return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
  }
  // Grupo de terreno para transiciones (autotiles)
  function groundGroup(name) {
    if (name === 'grass' || name === 'tallgrass' || name === 'flowers') return 'grass';
    if (name === 'water' || name === 'deepwater') return 'water';
    if (name === 'path' || name === 'bridge') return 'path';
    if (name === 'sand') return 'sand';
    if (name === 'snow' || name === 'ice') return 'snow';
    if (name === 'mud') return 'mud';
    if (name === 'ash' || name === 'lava') return 'ash';
    if (name === 'cavefloor') return 'cave';
    return null;
  }

  // Firma para render con conocimiento de vecinos y tiempo (agua, bordes).
  function drawTile(ctx, map, tx, ty, sx, sy, time) {
    const ch = PH.world.tileAt(map, tx, ty);
    const theme = map.theme;
    const P = THEMES[theme] || THEMES.meadow;
    const name = (TILE[ch] || {}).name;
    const rnd = hash(tx, ty);
    const nGroup = (dx, dy) => groundGroup((TILE[PH.world.tileAt(map, tx + dx, ty + dy)] || {}).name);
    const drawGround = () => {
      px(ctx, sx, sy, TS, TS, P.grass);
      // motas de variación deterministas
      const m = Math.floor(rnd * 4);
      px(ctx, sx + 2 + ((tx * 5) % 11), sy + 3 + ((ty * 7) % 10), 2, 2, P.grassD);
      if (m > 0) px(ctx, sx + 9 + (m % 3), sy + 9 + (m % 4), 2, 2, P.grassD);
      if (m > 2) px(ctx, sx + 5, sy + 12, 1, 1, shade(P.grass, 0.12));
      grassEdges();
    };
    // Bordes suaves de césped hacia terrenos vecinos distintos
    const grassEdges = () => {
      const c = P.grassD;
      if (nGroup(0, -1) && nGroup(0, -1) !== 'grass') { px(ctx, sx, sy, TS, 2, c); px(ctx, sx + 3, sy + 2, 2, 1, c); px(ctx, sx + 10, sy + 2, 2, 1, c); }
      if (nGroup(0, 1) && nGroup(0, 1) !== 'grass') { px(ctx, sx, sy + TS - 2, TS, 2, c); px(ctx, sx + 4, sy + TS - 3, 2, 1, c); }
      if (nGroup(-1, 0) && nGroup(-1, 0) !== 'grass') { px(ctx, sx, sy, 2, TS, c); }
      if (nGroup(1, 0) && nGroup(1, 0) !== 'grass') { px(ctx, sx + TS - 2, sy, 2, TS, c); }
    };
    switch (name) {
      case 'grass': drawGround(); break;
      case 'tallgrass': {
        drawGround();
        for (let i = 0; i < 5; i++) {
          const bx = sx + 2 + i * 3;
          px(ctx, bx, sy + 6 + ((i % 2) ? 0 : 2), 2, 8, i % 2 ? P.blade : P.blade2);
          px(ctx, bx, sy + 5 + ((i % 2) ? 0 : 2), 1, 2, shade(P.blade2, 0.3));
        }
        break;
      }
      case 'path': {
        px(ctx, sx, sy, TS, TS, P.path);
        px(ctx, sx + 2 + ((tx * 3) % 9), sy + 3 + ((ty * 5) % 9), 2, 2, P.pathD);
        px(ctx, sx + 9, sy + 11, 2, 1, shade(P.path, 0.1));
        // bordes: la hierba vecina sombrea el camino
        if (nGroup(0, -1) === 'grass') px(ctx, sx, sy, TS, 1, P.pathD);
        if (nGroup(-1, 0) === 'grass') px(ctx, sx, sy, 1, TS, P.pathD);
        if (nGroup(1, 0) === 'grass') px(ctx, sx + TS - 1, sy, 1, TS, P.pathD);
        break;
      }
      case 'bridge': px(ctx, sx, sy, TS, TS, '#a9793f'); for (let i = 0; i < TS; i += 4) px(ctx, sx + i, sy, 1, TS, '#7c531f'); px(ctx, sx, sy, TS, 1, '#c99a5f'); break;
      case 'tree': {
        drawGround();
        const big = rnd > 0.5;
        const snow = theme === 'snow', volc = theme === 'volcano';
        const canopy = snow ? '#dfeaf2' : (volc ? '#5a3a2a' : (rnd > 0.7 ? '#2b7a3a' : '#2f6b2a'));
        const canHi = snow ? '#f2f8fc' : (volc ? '#6d4636' : '#4a9a3e');
        // sombra bajo el árbol
        px(ctx, sx + 3, sy + 13, 10, 2, 'rgba(0,0,0,0.16)');
        px(ctx, sx + 7, sy + 10, 3, 6, '#6b4a2a');           // tronco
        px(ctx, sx + 7, sy + 10, 1, 6, '#553a20');
        // copa redondeada
        px(ctx, sx + 3, sy + 2, 10, 9, shade(canopy, -0.28));
        px(ctx, sx + 2, sy + 4, 12, 5, shade(canopy, -0.28));
        px(ctx, sx + 4, sy + (big ? 0 : 1), 8, 9, canopy);
        px(ctx, sx + 3, sy + 4, 10, 4, canopy);
        px(ctx, sx + 5, sy + 2, 4, 3, canHi);               // luz
        px(ctx, sx + 5, sy + 2, 2, 2, shade(canHi, 0.15));
        break;
      }
      case 'palm':
        drawGround();
        px(ctx, sx + 7, sy + 5, 2, 11, '#8a6a3a');
        px(ctx, sx + 2, sy + 3, 12, 2, '#3f9a5a'); px(ctx, sx + 4, sy + 1, 8, 2, '#4fb06a'); px(ctx, sx + 1, sy + 5, 5, 2, '#3f9a5a'); px(ctx, sx + 10, sy + 5, 5, 2, '#3f9a5a');
        break;
      case 'bush': drawGround(); px(ctx, sx + 2, sy + 5, 12, 9, shade(P.blade, -0.1)); px(ctx, sx + 4, sy + 6, 5, 4, P.blade2); break;
      case 'rock': px(ctx, sx, sy, TS, TS, '#8a8f97'); px(ctx, sx + 2, sy + 2, 12, 12, '#6d727a'); px(ctx, sx + 4, sy + 3, 5, 4, '#a2a7ae'); break;
      case 'cavefloor': px(ctx, sx, sy, TS, TS, '#3f3b47'); px(ctx, sx + 4, sy + 5, 3, 3, '#332f3a'); px(ctx, sx + 10, sy + 10, 2, 2, '#4a4652'); break;
      case 'stalag': px(ctx, sx, sy, TS, TS, '#3f3b47'); px(ctx, sx + 5, sy + 2, 6, 14, '#5a5566'); px(ctx, sx + 7, sy + 4, 2, 10, '#726c82'); break;
      case 'water': case 'deepwater': {
        const deep = name === 'deepwater';
        px(ctx, sx, sy, TS, TS, deep ? '#2f6bb0' : '#4b8fd6');
        // ondas animadas deterministas
        const ph = (time || 0) / 500 + (tx + ty);
        const o1 = Math.round(Math.sin(ph) * 2), o2 = Math.round(Math.cos(ph * 0.8) * 2);
        px(ctx, sx + 2 + o1, sy + 4, 6, 1, deep ? '#4b8fd6' : '#7bb4ec');
        px(ctx, sx + 8 + o2, sy + 10, 5, 1, deep ? '#4b8fd6' : '#9cc9f2');
        // espuma hacia la orilla (vecino no-agua)
        const foam = '#dff0ff';
        if (nGroup(0, -1) && nGroup(0, -1) !== 'water') px(ctx, sx, sy, TS, 2, foam);
        if (nGroup(0, 1) && nGroup(0, 1) !== 'water') px(ctx, sx, sy + TS - 2, TS, 2, foam);
        if (nGroup(-1, 0) && nGroup(-1, 0) !== 'water') px(ctx, sx, sy, 2, TS, foam);
        if (nGroup(1, 0) && nGroup(1, 0) !== 'water') px(ctx, sx + TS - 2, sy, 2, TS, foam);
        break;
      }
      case 'mud': px(ctx, sx, sy, TS, TS, '#6b5637'); px(ctx, sx + 2 + ((tx * 3) % 8), sy + 3 + ((ty * 3) % 8), 4, 3, '#54432a'); px(ctx, sx + 9, sy + 10, 4, 3, '#7d6543'); if (rnd > 0.6) px(ctx, sx + 5, sy + 7, 3, 2, '#3f7d34'); break;
      case 'sand': px(ctx, sx, sy, TS, TS, P.grass); px(ctx, sx + 3 + ((tx * 5) % 9), sy + 4 + ((ty * 3) % 8), 2, 1, P.grassD); px(ctx, sx + 10, sy + 11, 1, 1, shade(P.grass, 0.1)); if (nGroup(0, 1) === 'water') px(ctx, sx, sy + TS - 2, TS, 2, shade(P.grass, 0.12)); break;
      case 'snow': px(ctx, sx, sy, TS, TS, '#e9f0f6'); px(ctx, sx + 4 + ((tx * 3) % 8), sy + 5 + ((ty * 5) % 7), 2, 2, '#d3ddea'); if (rnd > 0.7) px(ctx, sx + 9, sy + 10, 1, 1, '#c3d0dc'); break;
      case 'ice': px(ctx, sx, sy, TS, TS, '#bfe0ef'); px(ctx, sx + 2, sy + 2, 6, 1, '#e6f6ff'); px(ctx, sx + 8, sy + 9, 5, 1, '#e6f6ff'); break;
      case 'ash': px(ctx, sx, sy, TS, TS, '#4a3b34'); px(ctx, sx + 3, sy + 5, 3, 2, '#5c4a42'); px(ctx, sx + 10, sy + 10, 2, 2, '#3a2d28'); break;
      case 'lava': px(ctx, sx, sy, TS, TS, '#e8531f'); px(ctx, sx + 2, sy + 3, 5, 3, '#ffb02e'); px(ctx, sx + 9, sy + 9, 4, 3, '#ffd34d'); px(ctx, sx + 6, sy + 11, 3, 2, '#c0331a'); break;
      case 'flowers': drawGround(); px(ctx, sx + 3, sy + 4, 2, 2, '#ffd34d'); px(ctx, sx + 9, sy + 8, 2, 2, '#ff7ba0'); px(ctx, sx + 6, sy + 11, 2, 2, '#8ac6ff'); break;
      case 'house': px(ctx, sx, sy, TS, TS, '#c86b52'); px(ctx, sx, sy, TS, 5, '#8f3f30'); px(ctx, sx + 2, sy + 7, 4, 4, '#8fd0e8'); px(ctx, sx + 10, sy + 7, 4, 4, '#8fd0e8'); break;
      case 'door': px(ctx, sx, sy, TS, TS, '#c86b52'); px(ctx, sx + 4, sy + 3, 8, 13, '#5a3a26'); px(ctx, sx + 9, sy + 9, 2, 2, '#ffd34d'); break;
      default:
        if (isWarp(ch)) { drawGround(); px(ctx, sx + 3, sy + 3, 10, 10, '#3a3f4a'); px(ctx, sx + 5, sy + 5, 6, 6, '#20242c'); }
        else drawGround();
    }
  }

  // ---- Personaje con contorno, sombreado y ciclo de caminado ----
  // Se dibuja primero en un búfer offscreen y luego se compone con una
  // silueta oscura desplazada (contorno 1px estilo GBA).
  const _buf = document.createElement('canvas'); _buf.width = 16; _buf.height = 18;
  const _sil = document.createElement('canvas'); _sil.width = 16; _sil.height = 18;
  const OUTLINE = '#20161f';

  function drawActorRaw(g, dir, frame, p) {
    const shS = shade(p.shirt, -0.24), liS = shade(p.shirt, 0.16);
    const skD = shade(p.skin, -0.16), skL = shade(p.skin, 0.14);
    const paD = shade(p.pants, -0.22);
    const bob = frame === 1 ? 1 : 0;
    const oy = -bob;
    g.clearRect(0, 0, 16, 18);

    // ---- Piernas / botas (animadas) ----
    const legY = 12;
    if (dir === 'left' || dir === 'right') {
      let f1 = 6, f2 = 8;
      if (frame === 1) { f1 = 4; f2 = 9; } else if (frame === 2) { f1 = 8; f2 = 5; }
      px(g, f2, legY, 3, 4, paD);
      px(g, f2, 15, 3, 1, '#241a22');            // bota
      px(g, f1, legY, 3, 4, p.pants);
      px(g, f1, 15, 3, 1, '#2a1f28');
    } else {
      let lx = 5, rx = 8;
      if (frame === 1) { lx = 4; rx = 9; } else if (frame === 2) { lx = 6; rx = 7; }
      px(g, lx, legY, 3, 4, p.pants); px(g, lx, 15, 3, 1, '#2a1f28');
      px(g, rx, legY, 3, 4, paD);      px(g, rx, 15, 3, 1, '#241a22');
    }

    // ---- Torso con sombreado ----
    px(g, 4, 8 + oy, 8, 5, p.shirt);
    px(g, 4, 8 + oy, 8, 1, liS);                 // luz superior
    px(g, 4, 12 + oy, 8, 1, shS);                // sombra inferior
    px(g, 4, 8 + oy, 1, 5, shade(p.shirt, -0.12));
    // mochila
    if (p.pack) {
      const pkD = shade(p.pack, -0.2);
      if (dir === 'up') { px(g, 4, 8 + oy, 8, 5, p.pack); px(g, 6, 9 + oy, 4, 3, pkD); }
      else if (dir === 'down') { px(g, 3, 9 + oy, 1, 3, p.pack); px(g, 12, 9 + oy, 1, 3, p.pack); }
      else if (dir === 'left') px(g, 10, 8 + oy, 2, 4, p.pack);
      else px(g, 4, 8 + oy, 2, 4, p.pack);
    }
    // ---- Brazos ----
    const armY = 8 + oy;
    if (dir === 'left') px(g, 4, armY + (frame === 1 ? 1 : 0), 2, 4, p.skin);
    else if (dir === 'right') px(g, 10, armY + (frame === 1 ? 1 : 0), 2, 4, p.skin);
    else {
      px(g, 3, armY + (frame === 2 ? 1 : 0), 2, 4, p.skin);
      px(g, 11, armY + (frame === 1 ? 1 : 0), 2, 4, p.skin);
    }

    // ---- Cabeza ----
    px(g, 4, 2 + oy, 8, 7, p.skin);
    px(g, 4, 2 + oy, 8, 1, skL);                 // luz frente
    px(g, 4, 8 + oy, 8, 1, skD);                 // barbilla
    // pelo
    px(g, 3, 1 + oy, 10, 3, p.hair);
    px(g, 3, 2 + oy, 1, 4, p.hair); px(g, 12, 2 + oy, 1, 4, p.hair);
    px(g, 4, 1 + oy, 8, 1, shade(p.hair, 0.18));
    if (p.hat) {
      const htD = shade(p.hat, -0.22);
      px(g, 3, 0 + oy, 10, 3, p.hat); px(g, 4, -1 + oy < 0 ? 0 : -1 + oy, 8, 1, p.hat);
      px(g, 3, 2 + oy, 10, 1, htD);
      if (dir !== 'up') px(g, 11, 3 + oy, 3, 1, htD); // visera
    }
    // rostro por dirección
    const ey = 5 + oy;
    if (dir === 'down') {
      px(g, 6, ey, 1, 2, '#20202a'); px(g, 9, ey, 1, 2, '#20202a');
      px(g, 6, ey, 1, 1, '#3a6ea5');            // brillo ojo
      px(g, 7, 7 + oy, 2, 1, skD);
    } else if (dir === 'up') {
      px(g, 3, 1 + oy, 10, 6, p.hair);
      px(g, 4, 1 + oy, 8, 1, shade(p.hair, 0.18));
    } else if (dir === 'left') {
      px(g, 4, 2 + oy, 2, 5, p.hair);
      px(g, 6, ey, 1, 2, '#20202a');
      px(g, 4, 6 + oy, 1, 1, skD);
    } else if (dir === 'right') {
      px(g, 10, 2 + oy, 2, 5, p.hair);
      px(g, 9, ey, 1, 2, '#20202a');
      px(g, 11, 6 + oy, 1, 1, skD);
    }
  }

  function drawActor(ctx, sx, sy, dir, frame, palette) {
    const p = palette || { skin: '#f0c088', hair: '#4a3b2a', shirt: '#3a7bd6', pants: '#33333f' };
    // sombra elíptica en el suelo (bajo el contorno)
    px(ctx, sx + 4, sy + 15, 8, 2, 'rgba(0,0,0,0.22)');
    px(ctx, sx + 3, sy + 16, 10, 1, 'rgba(0,0,0,0.12)');

    const bctx = _buf.getContext('2d'); bctx.imageSmoothingEnabled = false;
    drawActorRaw(bctx, dir, frame, p);
    // silueta oscura
    const sctx = _sil.getContext('2d'); sctx.imageSmoothingEnabled = false;
    sctx.globalCompositeOperation = 'source-over';
    sctx.clearRect(0, 0, 16, 18);
    sctx.drawImage(_buf, 0, 0);
    sctx.globalCompositeOperation = 'source-in';
    sctx.fillStyle = OUTLINE; sctx.fillRect(0, 0, 16, 18);
    sctx.globalCompositeOperation = 'source-over';
    // contorno (4 desplazamientos) + cuerpo encima
    const off = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    for (const o of off) ctx.drawImage(_sil, sx + o[0], sy + o[1]);
    ctx.drawImage(_buf, sx, sy);
  }

  const NPC_PALETTES = {
    mentor: { skin: '#f0c088', hair: '#d8d8e0', shirt: '#e8e8ee', pants: '#555' },
    npc2:   { skin: '#e0a878', hair: '#6a3d2a', shirt: '#d64a6b', pants: '#333' },
    npc3:   { skin: '#f0c088', hair: '#2a2a2a', shirt: '#4aa86b', pants: '#333' },
    npc4:   { skin: '#c98d5a', hair: '#3a2a1a', shirt: '#d68a3a', pants: '#333' },
    npc5:   { skin: '#f0c088', hair: '#8a5a2a', shirt: '#8a6bd6', pants: '#333' },
    npc6:   { skin: '#b98a5a', hair: '#1a1a1a', shirt: '#555', pants: '#222' },
  };

  // ---- Criatura-cepa "Strainmon": planta en maceta con cara y carácter ----
  const OUTL = '#20161f';
  function oRect(ctx, x, y, w, h, fill) { px(ctx, x - 1, y - 1, w + 2, h + 2, OUTL); px(ctx, x, y, w, h, fill); }

  function drawPlant(ctx, cx, cy, pheno, scale, t) {
    scale = scale || 1;
    const pal = PH.gen.paletteFor(pheno);
    const leafCol = pheno.albino ? '#dcd6b8' : '#3f8f3a';
    const leafSh = shade(leafCol, -0.22), leafHi = shade(leafCol, 0.2);
    const muts = pheno.mutations || [];
    const gig = muts.includes('gigantismo'), dwf = muts.includes('enanismo');
    const flick = muts.includes('fluorescente') ? (0.6 + 0.4 * Math.abs(Math.sin(t / 300))) : 1;
    const wob = Math.round(Math.sin(t / 600) * 0.6);   // leve balanceo

    // dimensiones según genética
    const bw = dwf ? 8 : (gig ? 14 : 11);              // ancho cuerpo
    const bh = dwf ? 7 : (gig ? 12 : 9) + Math.round((pheno.quant.altura / 100) * 3);
    const hw = dwf ? 7 : (gig ? 11 : 9);               // ancho cabeza (cogollo)

    ctx.save();
    ctx.translate(Math.round(cx), Math.round(cy));
    ctx.scale(scale, scale);

    // sombra
    px(ctx, -bw / 2 - 1, 1, bw + 2, 3, 'rgba(0,0,0,0.22)');

    // --- Maceta de terracota ---
    const potW = bw + 2, potH = 6, potY = -6;
    oRect(ctx, -potW / 2, potY, potW, potH, '#c07048');
    px(ctx, -potW / 2, potY, potW, 1, '#d98a5f');                       // brillo borde
    oRect(ctx, -potW / 2 - 1, potY - 2, potW + 2, 2, '#a85a38');        // reborde
    px(ctx, -potW / 2, potY - 2, potW, 1, '#5a3a26');                   // tierra
    px(ctx, -potW / 2 + 1, potY + 3, potW - 2, 1, '#9a5636');           // sombra interior

    // --- Cuerpo (planta) ---
    const bodyY = potY - 2 - bh + 1 + wob;
    oRect(ctx, -bw / 2, bodyY, bw, bh, leafCol);
    px(ctx, -bw / 2, bodyY, bw, 1, leafHi);                              // luz superior
    px(ctx, -bw / 2, bodyY + bh - 1, bw, 1, leafSh);                     // sombra inferior
    px(ctx, -bw / 2, bodyY, 1, bh, leafSh);
    if (muts.includes('variegacion')) { px(ctx, -bw / 2 + 1, bodyY + 2, 2, 3, '#eae4c4'); px(ctx, bw / 2 - 3, bodyY + 4, 2, 2, '#eae4c4'); }

    // brazos-hoja (según forma de hoja)
    const armY = bodyY + 2;
    const armLen = pheno.leaf === 'estrecha' || pheno.leaf === 'aciculada' ? 4 : (pheno.leaf === 'ancha' ? 6 : 5);
    drawArm(ctx, -bw / 2, armY, -1, armLen, pheno.leaf, leafCol, leafSh);
    drawArm(ctx, bw / 2, armY, 1, armLen, pheno.leaf, leafCol, leafSh);

    // --- Cabeza / cogollo (color del fenotipo) con cara ---
    const headY = bodyY - hw + 2 + wob;
    ctx.globalAlpha = flick;
    oRect(ctx, -hw / 2, headY, hw, hw, pal.base);
    px(ctx, -hw / 2, headY, hw, 1, pal.light);
    px(ctx, -hw / 2, headY + hw - 1, hw, 1, pal.dark);
    px(ctx, -hw / 2, headY, 1, hw, pal.light);
    // patrones de pigmentación
    if (pheno.pattern === 'moteado') { px(ctx, -hw / 2 + 1, headY + 2, 1, 1, pal.dark); px(ctx, hw / 2 - 2, headY + hw - 3, 1, 1, pal.dark); }
    else if (pheno.pattern === 'rayado') { for (let i = -hw / 2 + 1; i < hw / 2; i += 2) px(ctx, i, headY, 1, hw, pal.dark); }
    else if (pheno.pattern === 'jaspeado') px(ctx, -hw / 2, headY + hw / 2, hw / 2, hw / 2, pal.dark);
    // codominancia / quimera: media cabeza de otro tono
    if (pheno.colorCo) { const co = PH.gen.COLOR_BY_KEY[pheno.colorCo]; if (co) px(ctx, 0, headY, hw / 2, hw, hslToHex(co.hue, 60, 52)); }
    if (muts.includes('quimera')) px(ctx, -hw / 2, headY, hw / 2, hw / 2, pal.dark);

    // hojita de azúcar arriba
    px(ctx, -1, headY - 3, 2, 3, leafCol); px(ctx, -2, headY - 2, 1, 1, leafSh); px(ctx, 1, headY - 2, 1, 1, leafSh);
    if (muts.includes('hexaploide')) { px(ctx, -4, headY - 2, 2, 2, pal.light); px(ctx, 3, headY - 2, 2, 2, pal.light); }
    if (gig) { px(ctx, -hw / 2 - 1, headY - 2, 1, 3, leafSh); px(ctx, hw / 2, headY - 2, 1, 3, leafSh); } // "cuernos"

    // cara
    const eyeY = headY + Math.max(2, hw / 2 - 1);
    const ex = Math.max(2, Math.round(hw / 4));
    const eye = (x) => { px(ctx, x, eyeY, 2, 2, '#f4f4ec'); px(ctx, x + (x < 0 ? 1 : 0), eyeY, 1, 2, '#20202a'); px(ctx, x, eyeY, 1, 1, 'rgba(255,255,255,.7)'); };
    eye(-ex); eye(ex - 1);
    // boca por "ánimo" (resina/rareza)
    const my = eyeY + 3;
    if (pheno.quant.resina > 72 || muts.length) { px(ctx, -2, my, 4, 1, '#3a2230'); px(ctx, -3, my - 1, 1, 1, '#3a2230'); px(ctx, 2, my - 1, 1, 1, '#3a2230'); } // sonrisa
    else px(ctx, -1, my, 2, 1, '#3a2230');
    // mejillas
    px(ctx, -ex - 1, eyeY + 1, 1, 1, 'rgba(255,120,140,.5)'); px(ctx, ex, eyeY + 1, 1, 1, 'rgba(255,120,140,.5)');
    ctx.globalAlpha = 1;

    // resina / escarcha
    if (muts.includes('cristalina') || pheno.quant.resina > 55) {
      const n = Math.round((pheno.quant.resina - 45) / 10) + (muts.includes('cristalina') ? 5 : 0);
      for (let i = 0; i < n; i++) px(ctx, -hw / 2 + (i * 3) % hw, headY + ((i * 5) % hw), 1, 1, 'rgba(255,255,255,0.85)');
    }
    // aura de bioluminiscencia
    if (muts.includes('fluorescente')) { ctx.globalAlpha = 0.25 * flick; px(ctx, -hw / 2 - 2, headY - 2, hw + 4, hw + 4, pal.light); ctx.globalAlpha = 1; }

    ctx.restore();
  }

  function drawArm(ctx, ox, oy, sign, len, form, col, sh) {
    const seg = form === 'ancha' ? 3 : (form === 'estrecha' || form === 'aciculada' ? 1 : 2);
    for (let j = 0; j < len; j++) {
      const yy = oy - (form === 'palmada' || form === 'digitada' ? j : (j * 0.4 | 0));
      px(ctx, ox + sign * (j + 1), yy, 1, seg, j === len - 1 ? sh : col);
    }
    // "mano"-hoja al final
    px(ctx, ox + sign * (len + 1), oy - (form === 'palmada' || form === 'digitada' ? len : (len * 0.4 | 0)) - 1, 1, seg + 1, col);
  }

  function leafShape(ctx, ox, oy, sign, lw, form, col, pheno) {
    const vg = pheno.mutations.includes('variegacion');
    for (let j = 0; j < lw; j++) {
      const seg = form === 'estrecha' || form === 'aciculada' ? 1 : (form === 'ancha' ? 3 : 2);
      const yy = oy - (form === 'palmada' ? j * 0.2 : 0);
      const c = (vg && j % 2 === 0) ? '#e9e2c0' : col;
      px(ctx, ox + sign * j, yy - (j * 0.1 | 0), 1, seg, c);
      if (form === 'serrada' && j % 2 === 0) px(ctx, ox + sign * j, yy - seg, 1, 1, shade(col, -0.2));
    }
  }

  function drawFlower(ctx, cx, cy, w, pal, pheno) {
    const half = w / 2;
    px(ctx, cx - half, cy - half, w, w, pal.base);
    px(ctx, cx - half, cy - half, w, 2, pal.light);
    px(ctx, cx - half, cy + half - 2, w, 2, pal.dark);
    // patrones
    if (pheno.pattern === 'moteado') { px(ctx, cx - half + 1, cy - 1, 2, 2, pal.dark); px(ctx, cx + 1, cy + 1, 1, 1, pal.light); }
    else if (pheno.pattern === 'rayado') { for (let i = -half; i < half; i += 3) px(ctx, cx + i, cy - half, 1, w, pal.dark); }
    else if (pheno.pattern === 'jaspeado') { px(ctx, cx - half, cy - half, half, half, pal.light); px(ctx, cx, cy, half, half, pal.dark); }
    else if (pheno.pattern === 'aureolado') { px(ctx, cx - half, cy - half, w, w, pal.dark); px(ctx, cx - half + 2, cy - half + 2, w - 4, w - 4, pal.base); }
    if (pheno.colorCo) { const co = PH.gen.COLOR_BY_KEY[pheno.colorCo]; if (co) px(ctx, cx, cy - half, half, w, PH.util.hslToHex(co.hue, 60, 50)); }
    px(ctx, cx - half + 1, cy - half + 1, 2, 2, pal.light);
    if (pheno.mutations.includes('quimera')) px(ctx, cx - half, cy, half, half, pal.dark);
  }

  PH.render = { TS, VW, VH, W, H, THEMES, drawTile, drawActor, drawPlant, NPC_PALETTES };
})(window.PH = window.PH || {});
