/* ============================================================
   PHENO HUNTER — render.js
   Render pixel-art 16-bit sobre canvas. Tiles procedurales,
   personajes y sprites de planta derivados del fenotipo.
   Resolución interna estilo GBA: 240x160, tiles de 16px.
   ============================================================ */
(function (PH) {
  'use strict';
  const { shade } = PH.util;
  const { TILE, isWarp } = PH.world;

  const TS = 16;                 // tamaño de tile
  const VW = 15, VH = 10;        // tiles visibles
  const W = VW * TS, H = VH * TS; // 240 x 160

  // Paletas por tema de mapa
  const THEMES = {
    town:   { grass: '#6fae4a', grassD: '#5c9a3c', path: '#caa96b', pathD: '#b2925a' },
    meadow: { grass: '#7cbd50', grassD: '#68a742', path: '#cbb06f', pathD: '#b2955a' },
    forest: { grass: '#4f9440', grassD: '#3f7d34', path: '#b39b64', pathD: '#997f4f' },
    swamp:  { grass: '#5f7d47', grassD: '#4d6739', path: '#8f7c4e', pathD: '#75643d' },
  };

  function px(ctx, x, y, w, h, col) { ctx.fillStyle = col; ctx.fillRect(x, y, w, h); }

  // ---- Dibujo de un tile en (sx,sy) pantalla ----
  function drawTile(ctx, ch, sx, sy, theme, t) {
    const P = THEMES[theme] || THEMES.meadow;
    // base de césped por defecto
    const drawGrass = () => {
      px(ctx, sx, sy, TS, TS, P.grass);
      // motas
      px(ctx, sx + 3, sy + 4, 2, 2, P.grassD);
      px(ctx, sx + 10, sy + 9, 2, 2, P.grassD);
      px(ctx, sx + 6, sy + 12, 1, 1, P.grassD);
    };
    const name = (TILE[ch] || {}).name;
    switch (name) {
      case 'grass': drawGrass(); break;
      case 'tallgrass': {
        drawGrass();
        const g1 = '#3f7d34', g2 = '#589b45';
        for (let i = 0; i < 5; i++) {
          const bx = sx + 2 + i * 3;
          px(ctx, bx, sy + 6 + ((i % 2) ? 0 : 2), 2, 8, i % 2 ? g1 : g2);
          px(ctx, bx, sy + 5 + ((i % 2) ? 0 : 2), 1, 2, '#7ec36a');
        }
        break;
      }
      case 'path': px(ctx, sx, sy, TS, TS, P.path); px(ctx, sx + 2, sy + 6, 2, 2, P.pathD); px(ctx, sx + 11, sy + 3, 2, 2, P.pathD); break;
      case 'bridge': px(ctx, sx, sy, TS, TS, '#a9793f'); for (let i = 0; i < TS; i += 4) px(ctx, sx + i, sy, 1, TS, '#7c531f'); break;
      case 'tree':
        drawGrass();
        px(ctx, sx + 6, sy + 10, 4, 6, '#6b4a2a');
        px(ctx, sx + 2, sy + 1, 12, 11, shade(P.grassD, -0.25));
        px(ctx, sx + 4, sy + 0, 9, 10, '#2f6b2a');
        px(ctx, sx + 5, sy + 2, 5, 4, '#458f3a');
        break;
      case 'bush': drawGrass(); px(ctx, sx + 2, sy + 5, 12, 9, '#357a2f'); px(ctx, sx + 4, sy + 6, 5, 4, '#4f9a45'); break;
      case 'rock': px(ctx, sx, sy, TS, TS, '#8a8f97'); px(ctx, sx + 2, sy + 2, 12, 12, '#6d727a'); px(ctx, sx + 4, sy + 3, 5, 4, '#a2a7ae'); break;
      case 'cavefloor': px(ctx, sx, sy, TS, TS, '#4a4650'); px(ctx, sx + 4, sy + 5, 3, 3, '#3b3843'); break;
      case 'water': px(ctx, sx, sy, TS, TS, '#4b8fd6'); px(ctx, sx + 2, sy + 4, 6, 2, '#7bb4ec'); px(ctx, sx + 9, sy + 10, 5, 2, '#7bb4ec'); break;
      case 'deepwater': px(ctx, sx, sy, TS, TS, '#2f6bb0'); px(ctx, sx + 3, sy + 7, 6, 2, '#4b8fd6'); break;
      case 'mud': px(ctx, sx, sy, TS, TS, '#6b5637'); px(ctx, sx + 3, sy + 4, 4, 3, '#54432a'); px(ctx, sx + 9, sy + 9, 4, 3, '#7d6543'); break;
      case 'sand': px(ctx, sx, sy, TS, TS, '#e0cd8f'); px(ctx, sx + 4, sy + 5, 2, 2, '#cbb672'); break;
      case 'snow': px(ctx, sx, sy, TS, TS, '#e9f0f6'); px(ctx, sx + 5, sy + 6, 2, 2, '#cfd9e4'); break;
      case 'flowers': drawGrass(); px(ctx, sx + 3, sy + 4, 2, 2, '#ffd34d'); px(ctx, sx + 9, sy + 8, 2, 2, '#ff7ba0'); px(ctx, sx + 6, sy + 11, 2, 2, '#8ac6ff'); break;
      case 'house': px(ctx, sx, sy, TS, TS, '#c86b52'); px(ctx, sx, sy, TS, 5, '#8f3f30'); px(ctx, sx + 2, sy + 7, 4, 4, '#8fd0e8'); px(ctx, sx + 10, sy + 7, 4, 4, '#8fd0e8'); break;
      case 'door': px(ctx, sx, sy, TS, TS, '#c86b52'); px(ctx, sx + 4, sy + 3, 8, 13, '#5a3a26'); px(ctx, sx + 9, sy + 9, 2, 2, '#ffd34d'); break;
      default:
        if (isWarp(ch)) { drawGrass(); px(ctx, sx + 3, sy + 3, 10, 10, '#3a3f4a'); px(ctx, sx + 5, sy + 5, 6, 6, '#20242c'); }
        else drawGrass();
    }
  }

  // ---- Personaje (jugador / NPC) ----
  function drawActor(ctx, sx, sy, dir, frame, palette) {
    palette = palette || { skin: '#f0c088', hair: '#4a3b2a', shirt: '#3a7bd6', pants: '#33333f' };
    const bob = frame ? 1 : 0;
    // sombra
    px(ctx, sx + 3, sy + 14, 10, 2, 'rgba(0,0,0,0.22)');
    // cuerpo
    px(ctx, sx + 4, sy + 8 - bob, 8, 6, palette.shirt);
    px(ctx, sx + 4, sy + 13 - bob, 3, 3, palette.pants);
    px(ctx, sx + 9, sy + 13 - bob, 3, 3, palette.pants);
    // cabeza
    px(ctx, sx + 4, sy + 2 - bob, 8, 7, palette.skin);
    px(ctx, sx + 4, sy + 1 - bob, 8, 3, palette.hair);
    px(ctx, sx + 3, sy + 3 - bob, 1, 4, palette.hair);
    px(ctx, sx + 12, sy + 3 - bob, 1, 4, palette.hair);
    // ojos según dirección
    const ey = sy + 5 - bob;
    if (dir === 'down') { px(ctx, sx + 6, ey, 1, 2, '#222'); px(ctx, sx + 9, ey, 1, 2, '#222'); }
    else if (dir === 'up') { px(ctx, sx + 4, sy + 1 - bob, 8, 4, palette.hair); }
    else if (dir === 'left') { px(ctx, sx + 5, ey, 1, 2, '#222'); }
    else if (dir === 'right') { px(ctx, sx + 10, ey, 1, 2, '#222'); }
  }

  const NPC_PALETTES = {
    mentor: { skin: '#f0c088', hair: '#d8d8e0', shirt: '#e8e8ee', pants: '#555' },
    npc2:   { skin: '#e0a878', hair: '#6a3d2a', shirt: '#d64a6b', pants: '#333' },
    npc3:   { skin: '#f0c088', hair: '#2a2a2a', shirt: '#4aa86b', pants: '#333' },
    npc4:   { skin: '#c98d5a', hair: '#3a2a1a', shirt: '#d68a3a', pants: '#333' },
    npc5:   { skin: '#f0c088', hair: '#8a5a2a', shirt: '#8a6bd6', pants: '#333' },
    npc6:   { skin: '#b98a5a', hair: '#1a1a1a', shirt: '#555', pants: '#222' },
  };

  /* ---- SPRITE DE PLANTA derivado del fenotipo ----
     Se dibuja en un canvas de tamaño `size` (p.ej. 64) centrado. */
  function drawPlant(ctx, cx, cy, pheno, scale, t) {
    scale = scale || 1;
    const pal = PH.gen.paletteFor(pheno);
    const s = scale;
    // altura visual según cuantitativo
    const height = 14 + (pheno.quant.altura / 100) * 22;
    const bushy = pheno.quant.produccion / 100;
    const flicker = pheno.mutations.includes('fluorescente') ? (0.6 + 0.4 * Math.abs(Math.sin(t / 300))) : 1;

    ctx.save();
    ctx.translate(cx, cy);
    ctx.scale(s, s);

    // sombra base
    px(ctx, -9, 2, 18, 3, 'rgba(0,0,0,0.2)');
    // tallo
    const stemH = height;
    px(ctx, -1, -stemH + 4, 2, stemH, pheno.albino ? '#cfc69a' : '#3f7d34');

    // hojas (según forma)
    const leafCol = pal.leaf;
    const leafPairs = pheno.leaf === 'digitada' ? 4 : (pheno.leaf === 'palmada' ? 3 : 3);
    for (let i = 0; i < leafPairs; i++) {
      const ly = -6 - i * (stemH / (leafPairs + 1)) * 0.9;
      const lw = 6 + bushy * 5;
      // izquierda
      leafShape(ctx, -1, ly, -1, lw, pheno.leaf, leafCol, pheno);
      leafShape(ctx, 1, ly, 1, lw, pheno.leaf, leafCol, pheno);
    }

    // cogollo/flor en la punta
    const fy = -stemH + 2;
    const fw = pheno.mutations.includes('gigantismo') ? 11 : (pheno.mutations.includes('enanismo') ? 5 : 8);
    ctx.globalAlpha = flicker;
    drawFlower(ctx, 0, fy, fw, pal, pheno);
    ctx.globalAlpha = 1;

    // resina: puntos brillantes
    if (pheno.quant.resina > 55) {
      const n = Math.round((pheno.quant.resina - 50) / 10);
      for (let i = 0; i < n; i++) {
        px(ctx, -fw / 2 + (i * 3) % fw, fy - 2 + ((i * 5) % 6), 1, 1, 'rgba(255,255,255,0.8)');
      }
    }
    ctx.restore();
  }

  function leafShape(ctx, ox, oy, sign, lw, form, col, pheno) {
    const vg = pheno.mutations.includes('variegacion');
    for (let j = 0; j < lw; j++) {
      const seg = form === 'estrecha' ? 1 : (form === 'ancha' ? 3 : 2);
      const yy = oy - (form === 'palmada' ? j * 0.2 : 0);
      const c = (vg && j % 2 === 0) ? '#e9e2c0' : col;
      px(ctx, ox + sign * j, yy - (j * 0.1 | 0), 1, seg, c);
      if (form === 'serrada' && j % 2 === 0) px(ctx, ox + sign * j, yy - seg, 1, 1, shade(col, -0.2));
    }
  }

  function drawFlower(ctx, cx, cy, w, pal, pheno) {
    // núcleo
    const half = w / 2;
    px(ctx, cx - half, cy - half, w, w, pal.base);
    px(ctx, cx - half + 1, cy - half + 1, w - 2, w - 2, pal.base);
    // volumen
    px(ctx, cx - half, cy - half, w, 2, pal.light);
    px(ctx, cx - half, cy + half - 2, w, 2, pal.dark);
    // codominancia: mitad de otro tono
    if (pheno.colorCo) {
      const co = PH.gen.COLOR_BY_KEY[pheno.colorCo];
      if (co) px(ctx, cx, cy - half, half, w, PH.util.hslToHex(co.hue, 60, 50));
    }
    // brillo
    px(ctx, cx - half + 1, cy - half + 1, 2, 2, pal.light);
    // quimera: parche divergente
    if (pheno.mutations.includes('quimera')) px(ctx, cx - half, cy, half, half, pal.dark);
  }

  PH.render = { TS, VW, VH, W, H, THEMES, drawTile, drawActor, drawPlant, NPC_PALETTES };
})(window.PH = window.PH || {});
