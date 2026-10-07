#!/usr/bin/env node
/*
  Ribera Verde — plano del juego (1.8.0; vista de carpa B desde P2)
  Pinta cada mapa entero a 1 casilla = 32 px (×2) con la rejilla, las coordenadas y lo que hay en él (edificios, puertas,
  salidas, NPC, objetos y carpas), y una hoja de escala con todos los sprites junto al jugador, medidos contra su
  tamaño real (en el mapa, 16 px = 1 m; en la vista de carpa B, 48 px = 1 m de ancho y de alto). Salida: docs/plano/<mapa>.png, docs/plano/escala.png, docs/plano/vista-b.png (las 5 carpas abiertas) y docs/plano/medidas.json (lo usa docs/PLANO.md).
  Uso:  node tools/build.js && node tools/plano.js
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const OUT = path.join(ROOT, 'docs', 'plano');

// tamaños reales de referencia (m) y el eje con el que se compara cada sprite (alto: de pie; ancho: de frente)
const REAL = {
  personajes: [['Jugador', 'player', 1.75], ['Kiko', 'kiko', 1.78], ['Baltasar', 'baltasar', 1.80], ['Txaro', 'granny', 1.55], ['Unai (niño)', 'kid', 1.35], ['Agente', 'cop', 1.80]],
  muebles: [['Cama', 'bed', 'ancho', .9], ['Nevera', 'fridge', 'ancho', .6], ['Ordenador', 'pc', 'ancho', 1.2], ['Mesa genética', 'lab', 'ancho', 1.2],
    ['Mesa genética 2', 'lab2', 'ancho', 1.2], ['Mesa', 'table', 'ancho', .8], ['Planta deco', 'plantDeco', 'alto', .9], ['Estantería', 'shelfW', 'ancho', .9],
    ['Mostrador', 'counter', 'alto', 1.0], ['Expositor', 'display', 'ancho', .8], ['Botellero', 'bottles', 'ancho', 1.0], ['Taburete', 'stool', 'alto', .75],
    ['Mesa de bar', 'btable', 'ancho', .7], ['Gramola', 'jukebox', 'ancho', .7], ['Cajas', 'crate', 'ancho', .6]],
  cultivo: [['Armario 60×60', 'carpa:p60', 'ancho', .6], ['Armario 80×80', 'carpa:p80', 'ancho', .8], ['Carpa 100×100', 'carpa:m100', 'ancho', 1.0],
    ['Carpa 120×120', 'carpa:m120', 'ancho', 1.2], ['Carpa 150×100', 'carpa:g150', 'ancho', 1.5]],
  // vista de carpa B (48 px/m de ancho y alto; el fondo, a 24 px/m y corrido a la derecha): de las carpas se mide el frente
  vista: [['Armario 60', 'c34:p60', 'frente', .6, 48], ['Armario 80', 'c34:p80', 'frente', .8, 48], ['Carpa 100', 'c34:m100', 'frente', 1.0, 48],
    ['Carpa 120', 'c34:m120', 'frente', 1.2, 48], ['Carpa 150', 'c34:g150', 'frente', 1.5, 48],
    ['Maceta 7 L', 'm34:plastico7', 'ancho', .22, 48], ['Maceta 11 L', 'm34:tela11', 'ancho', .25, 48], ['Maceta 18 L', 'm34:plastico18', 'ancho', .30, 48],
    ['Maceta 25 L', 'm34:tela25', 'ancho', .35, 48], ['CFL 125', 'f34:cfl', 'ancho', .35, 48], ['Sodio 250', 'f34:sodio250', 'ancho', .45, 48],
    ['Sodio 400', 'f34:sodio400', 'ancho', .5, 48], ['Sodio 600', 'f34:sodio600', 'ancho', .55, 48], ['LED 100', 'f34:led100', 'ancho', .25, 48],
    ['LED 200', 'f34:led200', 'ancho', .3, 48], ['LED 480', 'f34:led480', 'ancho', .6, 48], ['LED 720', 'f34:led720', 'ancho', 1.0, 48],
    ['Ventilador', 'x34:vent', 'ancho', .2, 48], ['Filtro y extractor', 'x34:filtro', 'ancho', .65, 48], ['Depósito de goteo', 'x34:goteo', 'alto', .5, 48]],
  // plantas de la vista B por porte; germinando y plántula, estilizadas a ×2 (plan de producción, §4)
  plantas: ['i', 's', 'h'].flatMap(po => [['Germinando', 0, .05], ['Plántula', 1, .15], ['Vegetativo', 2], ['Floración', 3], ['Lista', 4]]
    .map(([n, st, r]) => [`${n} (${{ i: 'índica', s: 'sativa', h: 'híbrida' }[po]})`, `p34:${po}${st}`, 'alto', r || { i: [0, 0, .35, .55, .65], s: [0, 0, .45, .75, .9], h: [0, 0, .4, .6, .7] }[po][st], 48])),
  exterior: [['Árbol', 'tree', 'alto', 6], ['Farola', 'lamp', 'alto', 4], ['Banco', 'bench', 'ancho', 1.8], ['Fuente', 'fountain', 'ancho', 3], ['Arbusto', 'bush', 'ancho', 1.2],
    ['Valla', 'fence', 'alto', 1.0], ['Edificio (piso)', 'edificio:home', 'ancho', 14], ['Edificio (bar)', 'edificio:bar', 'ancho', 14]],
};

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage({ viewport: { width: 1000, height: 700 }, deviceScaleFactor: 1 });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('file://' + path.join(ROOT, 'index.html'));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
  await page.evaluate(() => document.fonts.ready);

  const res = await page.evaluate(async (REAL) => {
    let K = 2; const MG = 30, out = { mapas: {}, medidas: [] };
    const NOMBRE = { bedT: 'cama', bedB: '', pc: 'ordenador', lab: 'mesa genética', lab2: 'mesa genética', table: 'mesa', fridge: 'nevera', plantDeco: 'planta',
      iwin: 'ventana', poster: 'diploma', shelfW: 'estantería', counter: 'mostrador', display: 'expositor', bottles: 'botellero', barcounter: 'barra', stool: 'taburete',
      btable: 'mesa', jukebox: 'gramola', crate: 'cajas', lamp: 'farola', fountain: 'fuente', sign: 'cartel', bench: 'banco', mesa: '' };
    const NPCN = { kiko: 'Kiko', josune: 'Josune', baltasar: 'Baltasar', tono: 'Toño', begona: 'Begoña', unai: 'Unai', patxi: 'Patxi', txaro: 'Txaro', inaki: 'Iñaki',
      cop: 'Agente', darko: 'Darko', molina: 'Sgto. Molina', jurado: 'Jurado' };
    const ZONAS = { town: [['PARQUE DE LOS SAUCES', 1, 13, 11, 27], ['PLAZA', 14, 13, 26, 24], ['RÍA', 31, 14, 38, 28], ['MUELLE', 34, 16, 38, 25], ['CALLE', 1, 9, 38, 12]] };

    mode = 'plano'; S = newState(); S.ch = 6; S.protect = false; S.flags = { letter: 1, kiko1: 1, harvest1: 1, metB: 1, lab: 1 }; S.min = 12 * 60; S.clients = [];
    S.carpas = [{ t: 'p80', foco: 'sodio250' }, { t: 'g150', foco: 'led720' }, { t: 'm120', foco: 'led480' }]; S.macetas = Array(15).fill('tela11'); S.pots = Array(15).fill(null);
    const espera = ms => new Promise(r => setTimeout(r, ms));

    function mapaEntero(name) {
      S.map = name; if (name === 'home') montarCasa();
      Object.assign(P, { x: -50, y: -50, px: -800, py: -800, fx: -50, fy: -50, moving: false });
      ents = []; buildEnts(); ents.forEach(e => e.wander = 0);
      const m = MAPS[name], W = m.w * 16, H = m.h * 16, [c, x] = mkCanvas(W, H);
      for (let cy = 0; cy < H; cy += SH) for (let cx = 0; cx < W; cx += SW) { renderWorld(1000, { x: cx, y: cy }); x.drawImage(cv, cx, cy); }
      return c;
    }
    function texto(x, s, px, py, col, size = 11, peso = 'bold') {
      x.font = `${peso} ${size}px system-ui, sans-serif`; x.lineWidth = 3; x.strokeStyle = 'rgba(10,12,18,.92)'; x.lineJoin = 'round';
      x.strokeText(s, px, py); x.fillStyle = col; x.fillText(s, px, py);
    }
    function anotar(name, titulo) {
      K = name === 'town' ? 2 : name === 'home' ? 4 : 3; const usados = [];
      const m = MAPS[name], base = mapaEntero(name), W = m.w * 16 * K, H = m.h * 16 * K;
      const [c, x] = mkCanvas(W + MG * 2, H + MG * 2 + 64); x.imageSmoothingEnabled = false;
      x.fillStyle = '#14161c'; x.fillRect(0, 0, c.width, c.height); x.drawImage(base, MG, MG, W, H);
      const T = (tx, ty) => [MG + tx * 16 * K, MG + ty * 16 * K], L = 16 * K;
      for (let i = 0; i <= m.w; i++) { x.fillStyle = i % 5 ? 'rgba(255,255,255,.16)' : 'rgba(255,255,255,.42)'; x.fillRect(MG + i * L, MG, 1, H); }
      for (let j = 0; j <= m.h; j++) { x.fillStyle = j % 5 ? 'rgba(255,255,255,.16)' : 'rgba(255,255,255,.42)'; x.fillRect(MG, MG + j * L, W, 1); }
      x.textAlign = 'center';
      for (let i = 0; i < m.w; i++) { texto(x, String(i), MG + i * L + L / 2, MG - 10, i % 5 ? '#9aa3b5' : '#ffffff', 10); texto(x, String(i), MG + i * L + L / 2, MG + H + 20, i % 5 ? '#9aa3b5' : '#ffffff', 10); }
      for (let j = 0; j < m.h; j++) { texto(x, String(j), MG / 2, MG + j * L + L / 2 + 4, j % 5 ? '#9aa3b5' : '#ffffff', 10); texto(x, String(j), MG + W + MG / 2, MG + j * L + L / 2 + 4, j % 5 ? '#9aa3b5' : '#ffffff', 10); }
      x.textAlign = 'left';
      const caja = (x0, y0, x1, y1, col, dash) => { const [a, b] = T(x0, y0), [c2, d] = T(x1 + 1, y1 + 1); x.setLineDash(dash ? [6, 4] : []); x.lineWidth = 2; x.strokeStyle = col; x.strokeRect(a + 1, b + 1, c2 - a - 2, d - b - 2); x.setLineDash([]); };
      const marca = (tx, ty, col, forma, rot) => { const [a, b] = T(tx, ty), cx = a + L / 2, cy = b + L / 2; x.fillStyle = col; x.strokeStyle = '#0a0c12'; x.lineWidth = 2; x.beginPath();
        if (forma === 'o') x.arc(cx, cy, 7, 0, 7); else if (forma === 'd') { x.moveTo(cx, cy - 8); x.lineTo(cx + 8, cy); x.lineTo(cx, cy + 8); x.lineTo(cx - 8, cy); x.closePath(); } else x.rect(cx - 7, cy - 7, 14, 14);
        x.stroke(); x.fill(); if (rot) texto(x, rot, cx - 3, cy + 4, '#0a0c12', 10); };
      // rótulos sin pisarse: si choca con uno ya puesto, baja una línea (hasta 4 veces)
      const rotulo = (tx, ty, s, col, dx = L - 4, dy = 12) => { const [a, b] = T(tx, ty); x.font = 'bold 11px system-ui, sans-serif';
        const w = x.measureText(s).width + 4, px = Math.min(a + dx, W + MG * 2 - w); let py = b + dy;   // sin salirse por la derecha
        for (let k = 0; k < 4 && usados.some(r => px < r[0] + r[2] && r[0] < px + w && py - 10 < r[1] + 12 && r[1] < py + 2); k++) py += 12;
        usados.push([px, py - 10, w, 12]); texto(x, s, px, py, col, 11); };
      const inv = { nombre: name, titulo, w: m.w, h: m.h, edificios: [], puertas: [], salidas: [], npcs: [], objetos: [], carpas: [] };
      (ZONAS[name] || []).forEach(([n, x0, y0, x1, y1]) => { caja(x0, y0, x1, y1, 'rgba(160,220,255,.75)', true); rotulo(x0, y0, n, '#a0dcff', 4, 13); });
      (m.blds || []).forEach(b => { caja(b.x0, b.y0, b.x0 + b.w - 1, b.y0 + b.h - 1, '#ffd84a'); rotulo(b.x0, b.y0, `EDIFICIO ${b.id.toUpperCase()} · ${b.w}×${b.h}`, '#ffd84a', 4, 13); inv.edificios.push({ id: b.id, x: b.x0, y: b.y0, w: b.w, h: b.h, puerta: b.doorX }); });
      for (const [k, w] of Object.entries(m.doors)) { const [tx, ty] = k.split(',').map(Number); marca(tx, ty, '#58e070', 's', '↑'); rotulo(tx, ty, `→ ${w.to} (${w.x},${w.y})`, '#78f090', L + 2, 30); inv.puertas.push({ x: tx, y: ty, a: w.to }); }
      for (const [k, w] of Object.entries(m.exits)) { const [tx, ty] = k.split(',').map(Number); marca(tx, ty, '#40d8e8', 's', '↓'); rotulo(tx, ty, `salida → ${w.to} (${w.x},${w.y})`, '#70f0ff', L + 2, 14); inv.salidas.push({ x: tx, y: ty, a: w.to }); }
      for (let ty = 0; ty < m.h; ty++) for (let tx = 0; tx < m.w; tx++) {
        const o = m.o[ty][tx]; if (!o || !(o in NOMBRE)) continue;
        if (o === 'sign') { marca(tx, ty, '#ffffff', 'd', 'i'); const t = (SIGNS[name + ':' + tx + ',' + ty] || '').split('\n')[0]; if (t) rotulo(tx, ty, t, '#ffffff', L - 2, 26); continue; }
        if (name === 'town' && (o === 'lamp' || o === 'bench')) continue;
        if (NOMBRE[o] && !(o === m.o[ty][tx - 1])) { rotulo(tx, ty, NOMBRE[o], '#f0e0ff', 2, L - 3); inv.objetos.push({ o, x: tx, y: ty }); }
      }
      if (name === 'home') {
        m.carpas.forEach(t => { const C = CARPAS[t.t], w = t.x1 - t.x0 + 1, pl = huecos().map((h, i) => h.c === t.ci ? i + 1 : 0).filter(Boolean);
          caja(t.x0, t.y, t.x1, t.y, '#a8ff60'); rotulo(t.x0, t.y, C.n.toUpperCase(), '#a8ff60', 2, L + 12); rotulo(t.x0, t.y, `${w}×1 casillas · plazas ${pl[0]}-${pl[pl.length - 1]}`, '#a8ff60', 2, L + 24);
          inv.carpas.push({ t: t.t, x: t.x0, y: t.y, w, h: 1, plazas: C.plazas }); });
        SITIOS.forEach((st, ci) => { if (!S.carpas[ci]) caja(st.x, st.y, st.x + st.w - 1, st.y, '#a8ff60', true); });
      }
      if (name === 'town') CLIENT_TILES.forEach(([tx, ty]) => { const [a, b] = T(tx, ty); x.fillStyle = 'rgba(120,255,160,.55)'; x.fillRect(a + L / 2 - 2, b + L / 2 - 2, 4, 4); });
      NPCDEF.filter(d => d.map === name).forEach(d => { marca(d.x, d.y, '#ff6ad5', 'o'); rotulo(d.x, d.y, NPCN[d.id] || d.id, '#ff9ae5', L - 4, -2); inv.npcs.push({ id: d.id, x: d.x, y: d.y, deambula: d.wander || 0 }); });
      ITEMS.filter(it => it.map === name).forEach(it => { marca(it.x, it.y, it.hidden ? '#ff9a3a' : '#ffe14a', 'd'); rotulo(it.x, it.y, it.id + (it.hidden ? ' (escondido)' : ''), it.hidden ? '#ffb46a' : '#fff07a', L - 2, 26); inv.objetos.push({ o: it.id, x: it.x, y: it.y, item: 1 }); });
      // leyenda
      const ly = MG + H + 36; let lx = MG; texto(x, `${titulo} · ${m.w}×${m.h} casillas · 1 casilla = 16 px (aquí ×${K}) ≈ 1 m`, lx, ly, '#ffffff', 13);
      const ley = [['#ffd84a', 'edificio'], ['#58e070', 'puerta'], ['#40d8e8', 'salida'], ['#ff6ad5', 'NPC'], ['#ffe14a', 'objeto'], ['#ff9a3a', 'escondido'], ['#ffffff', 'cartel']]
        .concat(name === 'home' ? [['#a8ff60', 'carpa']] : name === 'town' ? [['rgba(120,255,160,.9)', 'casillas de clientes'], ['#a0dcff', 'zona']] : []);
      lx = MG; ley.forEach(([col, n]) => { x.fillStyle = col; x.fillRect(lx, ly + 10, 12, 12); texto(x, n, lx + 16, ly + 21, '#d8dce6', 11, 'normal'); lx += 30 + n.length * 6.4; });
      out.mapas[name] = { png: c.toDataURL('image/png'), inv };
    }
    anotar('town', 'RIBERA VERDE · barrio'); anotar('home', 'PISO DE LA TÍA MAITE (armario 80 + carpa 150 + carpa 120)'); anotar('shop', 'GROWSHOP KIKO'); anotar('bar', 'BAR EL ANCLA');

    // ---------- hoja de escala ----------
    function caja(c) { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; let x0 = 1e9, y0 = 1e9, x1 = -1, y1 = -1;
      for (let y = 0; y < c.height; y++) for (let x = 0; x < c.width; x++) if (d[(y * c.width + x) * 4 + 3] > 8) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
      return x1 < 0 ? null : { x0, y0, w: x1 - x0 + 1, h: y1 - y0 + 1 }; }
    function sprite(clave) {
      const [tipo, k] = clave.includes(':') ? clave.split(':') : ['obj', clave];
      const fr = (g, s, d = 'unica') => { const f = g && frameDe(g, s, d, 0, { i: 0 }); return f ? f.c : null; };
      if (tipo === 'look') { const g = grupoLook(LOOKS[k]); return g && ((tieneDir(g, 'idle', 'south') && fr(g, 'idle', 'south')) || fr(g, 'base', 'south')); }
      if (tipo === 'carpa') return fr(ARTE.cubre['misc:carpa-' + k + '-mapa'], 'carpa-' + k + '-mapa') || carpaMapa(k);
      if (tipo === 'c34') return carpa34(k);
      if (tipo === 'm34') return maceta34(k);
      if (tipo === 'p34') return planta34(k[0], +k.slice(1), false, '#e0c050');
      if (tipo === 'f34') return foco34(k);
      if (tipo === 'x34') return extra34(k);
      if (tipo === 'edificio') return fr('edificio-' + k, 'base');
      if (k === 'bed') { const a = sprite('bedT'), b = sprite('bedB'); if (!a || !b) return null; const [c, x] = mkCanvas(Math.max(a.width, b.width), a.height + 16);
        const ca = caja(a), cb = caja(b); x.drawImage(a, 0, 0); x.drawImage(b, 0, ca ? ca.y0 + ca.h - cb.y0 : 16); return c; }
      return fr(ARTE.cubre['obj:' + k], k) || (TILES[k] && TILES[k][0]);
    }
    const filas = [
      ['PERSONAJES · altura de pie', REAL.personajes.map(([n, k, r]) => [n, 'look:' + k, 'alto', r])],
      ['MOBILIARIO · interiores', REAL.muebles], ['CULTIVO · carpas en el piso (16 px/m)', REAL.cultivo],
      ['VISTA DE CARPA B · 48 px/m: carpas (el frente), macetas, focos y extras', REAL.vista],
      ['VISTA DE CARPA B · 48 px/m: plantas por porte (germinando y plántula, a ×2)', REAL.plantas], ['EXTERIOR · calle, parque y edificios', REAL.exterior]];
    const E = 3, PAD = 14, cols = [];
    let H = 40;
    for (const [titulo, items] of filas) {
      const fila = { titulo, items: [], alto: 0 };
      fila.ppm = items[0][4] || 16;
      for (const [n, clave, eje, real, ppm = 16] of items) {
        const c = sprite(clave); if (!c) { fila.items.push({ n, clave, falta: true }); continue; }
        const b = caja(c); const px = eje === 'alto' ? b.h : eje === 'frente' ? b.w - Math.round(CARPAS[clave.split(':')[1]].cm[2] * VB_X) - 1 : b.w, m = px / ppm, ratio = m / real;
        const it = { n, clave, eje, real, px, w: b.w, h: b.h, m: +m.toFixed(2), ratio: +ratio.toFixed(2), c, b };
        fila.items.push(it); fila.alto = Math.max(fila.alto, b.h); out.medidas.push({ grupo: titulo.split(' ·')[0], n, clave, eje, real, ppm, w: b.w, h: b.h, m: it.m, ratio: it.ratio });
      }
      cols.push(fila); H += fila.alto * E + 120;
    }
    const jug = sprite('look:player'), bj = caja(jug);
    let W = 0; for (const f of cols) { let w = 90 + bj.w * E + PAD * 2; for (const it of f.items) if (!it.falta) w += Math.max(it.b.w * E, 110) + PAD * 2; W = Math.max(W, w); }
    const [hc, x] = mkCanvas(Math.min(W, 4000), H + 60); x.imageSmoothingEnabled = false; x.fillStyle = '#1a1d24'; x.fillRect(0, 0, hc.width, hc.height);
    texto(x, 'HOJA DE ESCALA · todos los sprites a ×3 sobre la misma línea de suelo · mapa: 1 casilla = 16 px = 1 m · vista de carpa B: 48 px = 1 m · ratio = tamaño en juego / tamaño real', 16, 26, '#ffffff', 14);
    let y = 40;
    for (const f of cols) {
      const base = y + 34 + f.alto * E; texto(x, f.titulo, 16, y + 18, '#ffd84a', 13);
      const paso = f.ppm > 16 ? f.ppm / 4 : 16, unidad = f.ppm > 16 ? .25 : 1;   // en la vista, una raya cada 25 cm
      for (let mtr = 0; mtr * paso <= f.alto; mtr++) { const yy = base - mtr * paso * E; x.fillStyle = mtr ? 'rgba(255,255,255,.12)' : 'rgba(255,255,255,.5)'; x.fillRect(60, yy, hc.width - 70, 1); texto(x, String(+(mtr * unidad).toFixed(2)).replace('.', ',') + ' m', 18, yy + 4, '#9aa3b5', 11, 'normal'); }
      let cx = 90; if (f.ppm === 16) { x.drawImage(jug, bj.x0, bj.y0, bj.w, bj.h, cx, base - bj.h * E, bj.w * E, bj.h * E); texto(x, 'jugador', cx, base + 16, '#9aa3b5', 11, 'normal'); } cx += bj.w * E + PAD * 2;
      for (const it of f.items) {
        if (it.falta) continue; const ww = Math.max(it.b.w * E, 110);
        x.drawImage(it.c, it.b.x0, it.b.y0, it.b.w, it.b.h, cx + (ww - it.b.w * E) / 2, base - it.b.h * E, it.b.w * E, it.b.h * E);
        const col = it.ratio >= .75 && it.ratio <= 1.34 ? '#78f090' : it.ratio >= .5 && it.ratio <= 2.5 ? '#ffd84a' : '#ff6a6a';
        texto(x, it.n, cx, base + 16, '#e8ecf4', 11); texto(x, `${it.w}×${it.h} px`, cx, base + 31, '#9aa3b5', 10, 'normal');
        texto(x, `${it.eje} ${String(it.m).replace('.', ',')} m / ${String(it.real).replace('.', ',')} m`, cx, base + 45, '#9aa3b5', 10, 'normal'); texto(x, `×${String(it.ratio).replace('.', ',')}`, cx, base + 60, col, 12);
        cx += ww + PAD * 2;
      }
      y = base + 92;
    }
    out.escala = hc.toDataURL('image/png');

    // ---------- vista B: las 5 carpas abiertas, con plantas de los 3 portes, extras y focos (plan de producción, P2) ----------
    const MUESTRA = {
      p60: ['led100', {}, [['limon', 1], ['txoko', 1]], ['plastico7', 'tela11']],
      p80: ['sodio250', { vent: 1 }, [['acapulco', 1], ['ria', .8], ['hindu', 1]], ['tela11', 'plastico18', 'tela11']],
      m100: ['led480', { vent: 1, filtro: 1 }, [['haze', 1], ['nepal', 1], ['afkush', 1], ['thai', .7]], ['tela25', 'plastico18', 'tela25', 'tela25']],
      m120: ['led720', { filtro: 1, goteo: 1 }, [['limon', 1], ['citrus', 1], ['mango', 1], ['malawi', .5], ['ria', .25], ['txoko', .05]], ['tela25', 'tela25', 'tela25', 'plastico18', 'tela11', 'plastico7']],
      g150: ['sodio600', { vent: 1, filtro: 1, goteo: 1 }, [['oaxaca', 1], ['dragon', .8], ['kif', 1], ['lamb', .5], ['nl', .2], null], ['tela25', 'tela25', 'tela25', 'plastico18', 'tela11', 'plastico7']] };
    const VE = 2, [vc, vx] = mkCanvas(5 * (240 * VE + 16) + 16, 160 * VE + 56); vx.imageSmoothingEnabled = false; vx.fillStyle = '#1a1d24'; vx.fillRect(0, 0, vc.width, vc.height);
    Object.entries(MUESTRA).forEach(([t, [foco, ex, pots, mac]], i) => {
      S.carpas = [Object.assign({ t, foco }, ex)]; S.macetas = mac; S.pots = pots.map(p => p && { sid: p[0], prog: p[1], water: 80, health: 100 });
      VC = { ci: 0, sel: 99, ocupado: true }; renderCarpa(1000); VC = null;   // sel 99: sin cursor
      const px = 16 + i * (240 * VE + 16); vx.drawImage(cv, OX(), 0, 240, 160, px, 16, 240 * VE, 160 * VE);
      texto(vx, `${CARPAS[t].n} · ${FOCOS[foco].n}`, px, 160 * VE + 36, '#e8ecf4', 12);
    });
    out.vistaB = vc.toDataURL('image/png');
    // distancia segura de cada carpa: centros de las macetas (cm), separación mínima entre ellas y a la pared, copa máxima de
    // la planta y alto máximo sobre la maceta más alta que admite, con cada foco (FOCO_SEP)
    out.holgura = HOLGURA; out.espacio = Object.keys(CARPAS).map(t => {
      const C = CARPAS[t], mx = Object.keys(MACETAS).filter(k => MACETAS[k].l <= C.lmax).sort((a, b) => MACETA_CM[b][1] - MACETA_CM[a][1])[0];
      S.carpas = [{ t, foco: 'cfl' }]; S.macetas = Array(C.plazas).fill(mx); const pl = vcGeo(0).pl; let sep = 1e9, pared = 1e9;
      pl.forEach((a, i) => { pared = Math.min(pared, a.cx, C.cm[0] - a.cx, a.cy, C.cm[2] - a.cy); pl.forEach((b, j) => { if (j > i) sep = Math.min(sep, Math.hypot(a.cx - b.cx, a.cy - b.cy)); }); });
      const altos = Object.keys(FOCOS).filter(f => FOCOS[f].w <= C.wmax).map(f => { S.carpas[0].foco = f; return { foco: f, sep: FOCO_SEP[f], alto: Math.round(vcGeo(0).pl[0].ch) }; });
      return { t, n: C.n, cm: C.cm, plazas: C.plazas, centros: pl.map(q => [Math.round(q.cx), Math.round(q.cy)]), sep: Math.round(sep), pared: Math.round(pared),
        copa: Math.round(Math.min(...pl.map(q => q.cw))), maceta: mx, altoMaceta: MACETA_CM[mx][1], altos };
    });
    return out;
  }, REAL);

  const png = (f, d) => fs.writeFileSync(path.join(OUT, f), Buffer.from(d.split(',')[1], 'base64'));
  for (const [n, m] of Object.entries(res.mapas)) { png(n + '.png', m.png); console.log('  docs/plano/' + n + '.png'); }
  png('escala.png', res.escala); console.log('  docs/plano/escala.png');
  png('vista-b.png', res.vistaB); console.log('  docs/plano/vista-b.png');
  const inv = Object.fromEntries(Object.entries(res.mapas).map(([n, m]) => [n, m.inv]));
  fs.writeFileSync(path.join(OUT, 'medidas.json'), JSON.stringify({ escala: 'mapa: 1 casilla = 16 px = 1 m · vista de carpa B: 48 px = 1 m de ancho y alto, 24 px/m de fondo', mapas: inv, sprites: res.medidas, espacio: { holgura: res.holgura, carpas: res.espacio } }, null, 1) + '\n');
  console.log('  docs/plano/medidas.json · ' + res.medidas.length + ' sprites medidos');
  await browser.close();
  if (errors.length) { console.log('Errores:', errors); process.exit(1); }
})();
