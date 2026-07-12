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

  function drawTile(ctx, ch, sx, sy, theme, t) {
    const P = THEMES[theme] || THEMES.meadow;
    const drawGround = () => {
      px(ctx, sx, sy, TS, TS, P.grass);
      px(ctx, sx + 3, sy + 4, 2, 2, P.grassD);
      px(ctx, sx + 10, sy + 9, 2, 2, P.grassD);
      px(ctx, sx + 6, sy + 12, 1, 1, P.grassD);
    };
    const name = (TILE[ch] || {}).name;
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
      case 'path': px(ctx, sx, sy, TS, TS, P.path); px(ctx, sx + 2, sy + 6, 2, 2, P.pathD); px(ctx, sx + 11, sy + 3, 2, 2, P.pathD); break;
      case 'bridge': px(ctx, sx, sy, TS, TS, '#a9793f'); for (let i = 0; i < TS; i += 4) px(ctx, sx + i, sy, 1, TS, '#7c531f'); break;
      case 'tree':
        drawGround();
        px(ctx, sx + 6, sy + 10, 4, 6, '#6b4a2a');
        px(ctx, sx + 2, sy + 1, 12, 11, shade(P.grassD, -0.25));
        px(ctx, sx + 4, sy + 0, 9, 10, theme === 'snow' ? '#cfe0ea' : (theme === 'volcano' ? '#5a3a2a' : '#2f6b2a'));
        px(ctx, sx + 5, sy + 2, 5, 4, theme === 'snow' ? '#eef6fb' : '#458f3a');
        break;
      case 'palm':
        drawGround();
        px(ctx, sx + 7, sy + 5, 2, 11, '#8a6a3a');
        px(ctx, sx + 2, sy + 3, 12, 2, '#3f9a5a'); px(ctx, sx + 4, sy + 1, 8, 2, '#4fb06a'); px(ctx, sx + 1, sy + 5, 5, 2, '#3f9a5a'); px(ctx, sx + 10, sy + 5, 5, 2, '#3f9a5a');
        break;
      case 'bush': drawGround(); px(ctx, sx + 2, sy + 5, 12, 9, shade(P.blade, -0.1)); px(ctx, sx + 4, sy + 6, 5, 4, P.blade2); break;
      case 'rock': px(ctx, sx, sy, TS, TS, '#8a8f97'); px(ctx, sx + 2, sy + 2, 12, 12, '#6d727a'); px(ctx, sx + 4, sy + 3, 5, 4, '#a2a7ae'); break;
      case 'cavefloor': px(ctx, sx, sy, TS, TS, '#3f3b47'); px(ctx, sx + 4, sy + 5, 3, 3, '#332f3a'); px(ctx, sx + 10, sy + 10, 2, 2, '#4a4652'); break;
      case 'stalag': px(ctx, sx, sy, TS, TS, '#3f3b47'); px(ctx, sx + 5, sy + 2, 6, 14, '#5a5566'); px(ctx, sx + 7, sy + 4, 2, 10, '#726c82'); break;
      case 'water': px(ctx, sx, sy, TS, TS, '#4b8fd6'); px(ctx, sx + 2, sy + 4, 6, 2, '#7bb4ec'); px(ctx, sx + 9, sy + 10, 5, 2, '#7bb4ec'); break;
      case 'deepwater': px(ctx, sx, sy, TS, TS, '#2f6bb0'); px(ctx, sx + 3, sy + 7, 6, 2, '#4b8fd6'); break;
      case 'mud': px(ctx, sx, sy, TS, TS, '#6b5637'); px(ctx, sx + 3, sy + 4, 4, 3, '#54432a'); px(ctx, sx + 9, sy + 9, 4, 3, '#7d6543'); break;
      case 'sand': px(ctx, sx, sy, TS, TS, P.grass); px(ctx, sx + 4, sy + 5, 2, 1, P.grassD); px(ctx, sx + 10, sy + 11, 2, 1, P.grassD); break;
      case 'snow': px(ctx, sx, sy, TS, TS, '#e9f0f6'); px(ctx, sx + 5, sy + 6, 2, 2, '#d3ddea'); px(ctx, sx + 11, sy + 3, 1, 1, '#cfd9e4'); break;
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

  function drawActor(ctx, sx, sy, dir, frame, palette) {
    palette = palette || { skin: '#f0c088', hair: '#4a3b2a', shirt: '#3a7bd6', pants: '#33333f' };
    const bob = frame ? 1 : 0;
    px(ctx, sx + 3, sy + 14, 10, 2, 'rgba(0,0,0,0.22)');
    px(ctx, sx + 4, sy + 8 - bob, 8, 6, palette.shirt);
    px(ctx, sx + 4, sy + 13 - bob, 3, 3, palette.pants);
    px(ctx, sx + 9, sy + 13 - bob, 3, 3, palette.pants);
    px(ctx, sx + 4, sy + 2 - bob, 8, 7, palette.skin);
    px(ctx, sx + 4, sy + 1 - bob, 8, 3, palette.hair);
    px(ctx, sx + 3, sy + 3 - bob, 1, 4, palette.hair);
    px(ctx, sx + 12, sy + 3 - bob, 1, 4, palette.hair);
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

  function drawPlant(ctx, cx, cy, pheno, scale, t) {
    scale = scale || 1;
    const pal = PH.gen.paletteFor(pheno);
    const s = scale;
    const height = 14 + (pheno.quant.altura / 100) * 22;
    const bushy = pheno.quant.produccion / 100;
    const flicker = pheno.mutations.includes('fluorescente') ? (0.6 + 0.4 * Math.abs(Math.sin(t / 300))) : 1;

    ctx.save();
    ctx.translate(cx, cy);
    ctx.scale(s, s);
    px(ctx, -9, 2, 18, 3, 'rgba(0,0,0,0.2)');
    const stemH = height;
    px(ctx, -1, -stemH + 4, 2, stemH, pheno.albino ? '#cfc69a' : '#3f7d34');

    const leafCol = pal.leaf;
    const leafPairs = pheno.leaf === 'digitada' ? 4 : (pheno.leaf === 'palmada' ? 3 : 3);
    for (let i = 0; i < leafPairs; i++) {
      const ly = -6 - i * (stemH / (leafPairs + 1)) * 0.9;
      const lw = 6 + bushy * 5;
      leafShape(ctx, -1, ly, -1, lw, pheno.leaf, leafCol, pheno);
      leafShape(ctx, 1, ly, 1, lw, pheno.leaf, leafCol, pheno);
    }

    const fy = -stemH + 2;
    const fw = pheno.mutations.includes('gigantismo') ? 11 : (pheno.mutations.includes('enanismo') ? 5 : 8);
    ctx.globalAlpha = flicker;
    drawFlower(ctx, 0, fy, fw, pal, pheno);
    ctx.globalAlpha = 1;

    if (pheno.mutations.includes('cristalina') || pheno.quant.resina > 55) {
      const n = Math.round((pheno.quant.resina - 45) / 9) + (pheno.mutations.includes('cristalina') ? 4 : 0);
      for (let i = 0; i < n; i++) {
        px(ctx, -fw / 2 + (i * 3) % fw, fy - 2 + ((i * 5) % 6), 1, 1, 'rgba(255,255,255,0.85)');
      }
    }
    ctx.restore();
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
