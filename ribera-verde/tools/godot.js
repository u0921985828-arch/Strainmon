#!/usr/bin/env node
/*
  Ribera Verde — corte de prueba en Godot 4 (godot/): saca del juego HTML lo que el port necesita y lo que tiene que dar igual
  1. godot/datos/datos.json: variedades, genética, carpas, focos, macetas y las constantes de la vista C, leídas del juego compilado.
  2. godot/arte/carpa.png + carpa.json: del atlas (assets/sprites), solo los sprites de la vista C (pared, luz, focos, macetas y
     plantas A con todos sus fotogramas).
  3. godot/tests/oraculo.json: lo que calcula el HTML en las escenas de prueba (geometría de la vista C, fotograma de cada planta),
     el tono y el porte de cada variedad a varios % índica, los factores de cada carpa y foco, tres ciclos de cultivo hora a hora,
     jornadas de cama (bedAction: dormir y siesta, cambio de día y factura de la luz) y cosechas (harvest: lotes, estrella, semillas),
     todo con un generador fijo (Park-Miller) en lugar de Math.random y las funciones de verdad del juego (los diálogos, las
     animaciones y lo que no está en el corte, como los clientes, no hacen nada).
  4. tools/salida/godot/html-<escena>.png: la escena de cada prueba pintada por el HTML (240 × 160) para compararla píxel a píxel
     con la de Godot (godot/tests/prueba.gd), y html-<escena>-sinluz.png, sin la capa de luz.
  Uso: node tools/build.js && node tools/godot.js [--escenas archivo.json] [--casos archivo.json] [--salida dir]
  (--escenas: otras escenas; --casos: otras {jornadas, cosechas}, p. ej. un caso reservado; con alguno de los dos solo escribe ese
  oráculo, y sus PNG, en --salida)
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const ROOT = path.join(__dirname, '..'), GD = path.join(ROOT, 'godot');
const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : d; };
const ESC = arg('--escenas'), CASOS = arg('--casos'), SAL = arg('--salida', path.join(__dirname, 'salida', 'godot'));

// escenas de prueba: una carpa con su foco, sus macetas y sus plantas (f.i: el % índica de cada planta), la plaza elegida
// (sel, −1 el foco) y el instante (now, ms: balanceo, cursor y plaga)
const pl = (sid, prog, o = {}) => Object.assign({ sid, prog, water: 70, health: 100, fert: false, pest: false, f: { id: 1, t: 1, y: 1, i: null } }, o);
const ESCENAS = ESC ? JSON.parse(fs.readFileSync(ESC, 'utf8')) : CASOS ? [] : [
  { k: 'm100-fases', t: 'm100', foco: 'sodio400', macetas: Array(4).fill('plastico7'), sel: 0, now: 1000,
    pots: [pl('ria', .05), pl('limon', .2), pl('txoko', .5, { f: { id: 2, t: 1, y: 1, i: 60 } }), pl('niebla', .9)] },
  { k: 'm100-flor', t: 'm100', foco: 'sodio400', macetas: Array(4).fill('plastico7'), sel: 2, now: 2345,
    pots: [pl('txoko', 1), pl('limon', .8, { pest: true }), pl('ria', 1, { water: 0, health: 60 }), null] },
  { k: 'p60-cfl', t: 'p60', foco: 'cfl', macetas: ['plastico7', 'plastico7'], sel: -1, now: 1500,
    pots: [pl('mango', .7, { f: { id: 3, t: 1.1, y: .9, i: 92 } }), pl('limon', .4)] },
  { k: 'p80-apagada', t: 'p80', foco: 'sodio250', macetas: Array(3).fill('plastico7'), sel: 0, now: 700, pots: [null, null, null] },
  { k: 'p80-mixta', t: 'p80', foco: 'sodio400', macetas: Array(3).fill('plastico7'), sel: 1, now: 3100,
    pots: [pl('acapulco', .66), pl('rif', .34, { f: { id: 4, t: 1, y: 1, i: 20 } }), pl('ria', 1, { fert: true })] },
  { k: 'g150-sodio600', t: 'g150', foco: 'sodio600', macetas: Array(6).fill('plastico7'), sel: 4, now: 4321,
    pots: [pl('malawi', 1), pl('hindu', .7), pl('thai', .95, { f: { id: 5, t: 1, y: 1, i: 45 } }), pl('kif', .3), pl('oaxaca', .6, { water: 10 }), pl('nepal', 1, { pest: true })] }];

// ciclos de cultivo: plantar (rollFeno), y cada hora plantsAdvance(60); cada 24 h riega las que bajan de rega % (rega 0: nunca),
// abona la 0 a las 30 h y trata la plaga de la 1 cada día. Al final, se cosechan (harvest) las que estén listas
const CICLOS = CASOS ? [] : [
  { k: 'm100', t: 'm100', foco: 'sodio400', macetas: Array(4).fill('plastico7'), seed: 12345, sids: ['ria', 'limon', 'txoko', 'niebla'], horas: 240, rega: 40 },
  { k: 'p60-seca', t: 'p60', foco: 'cfl', macetas: ['plastico7', 'plastico7'], seed: 777, sids: ['mango', 'thai'], horas: 120, rega: 0 },
  { k: 'g150', t: 'g150', foco: 'sodio600', macetas: Array(6).fill('plastico7'), seed: 2026, sids: ['malawi', 'hindu', 'kif', 'oaxaca', 'nepal', 'lamb'], horas: 200, rega: 35 }];

// jornadas: plantar (rollFeno) y, en cada paso, regar las que bajan de rega % y la cama (bedAction: 0 hasta las 7, 1 siesta de 3 h).
// Al final, se cosechan las que estén listas
// cosechas: plantas ya listas (y lotes de antes, buds0) que se cosechan en ese orden
const DEF = CASOS ? JSON.parse(fs.readFileSync(CASOS, 'utf8')) : {
  jornadas: [
    { k: 'm100-semana', t: 'm100', foco: 'sodio400', macetas: Array(4).fill('plastico7'), seed: 4242, money: 150, min: 480,
      sids: ['ria', 'limon', 'txoko', 'niebla'], rega: 40, pasos: [0, 1, 0, 0, 1, 0, 0, 0, 0, 0], cosechar: true },
    { k: 'p60-sin-dinero', t: 'p60', foco: 'cfl', macetas: ['plastico7', 'plastico7'], seed: 99, money: 20, min: 1380,
      sids: ['mango', 'kif'], rega: 0, pasos: [1, 0, 0, 0, 0, 0], cosechar: true }],
  cosechas: [
    { k: 'lotes', t: 'm100', foco: 'sodio400', macetas: Array(4).fill('plastico7'), seed: 31337, buds0: { ria: { g: 40, thc: 18.3 } }, orden: [1, 0, 2, 3],
      pots: [pl('ria', 1, { f: { id: 11, t: 1.2, y: 1.2, i: null } }), pl('ria', 1, { f: { id: 12, t: 1, y: 1.05, i: null }, fert: true, health: 55 }),
        pl('kif', 1, { f: { id: 13, t: .8, y: .9, i: null } }), { sid: 'txoko', prog: 1, water: 50, health: 90, fert: false, pest: false }] },
    { k: 'g150-macetas', t: 'g150', foco: 'led720', macetas: ['plastico7', 'tela11', 'plastico18', 'tela25', 'plastico7', 'plastico7'], seed: 8080, orden: [3, 2, 1, 0],
      pots: [pl('malawi', 1), pl('thai', 1, { fert: true }), pl('mango', 1, { f: { id: 21, t: 1.1, y: 1.3, i: null } }), pl('limon', 1, { health: 20 }), null, pl('niebla', .99)] }] };

function leePng(f) { return PNG.sync.read(fs.readFileSync(f)); }

// 2. atlas de la vista C
function atlasCarpa() {
  const d = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/sprites/atlas.json'), 'utf8')), src = leePng(path.join(ROOT, 'assets/sprites/atlas.png'));
  const nombres = Object.keys(d.cubre).filter(k => /^misc:(carpa-c-|planta-c-|maceta-c-|foco-c-)/.test(k)).map(k => k.slice(5));   // en el orden del atlas: vcSprite se queda con el primero si dos anchos empatan
  const lista = [];   // [nombre, índice, rect del atlas]
  for (const n of nombres) d.anims[d.cubre['misc:' + n]][n].dirs.unica.forEach((k, i) => lista.push([n, i, d.frames[k]]));
  // estantes de 1024 de ancho, de los más altos a los más bajos
  const W = 1024, ord = [...lista].sort((a, b) => b[2].h - a[2].h || a[0].localeCompare(b[0]) || a[1] - b[1]);
  let x = 0, y = 0, hf = 0;const pos = new Map();
  for (const e of ord) { if (x + e[2].w > W) { x = 0; y += hf; hf = 0; } pos.set(e, [x, y]); x += e[2].w; hf = Math.max(hf, e[2].h); }
  const out = new PNG({ width: W, height: y + hf });
  const sprites = {};
  for (const e of lista) {
    const [n, i, r] = e, [px, py] = pos.get(e);
    PNG.bitblt(src, out, r.x, r.y, r.w, r.h, px, py);
    (sprites[n] = sprites[n] || [])[i] = [px, py, r.w, r.h];
  }
  fs.mkdirSync(path.join(GD, 'arte'), { recursive: true });
  fs.writeFileSync(path.join(GD, 'arte/carpa.png'), PNG.sync.write(out));
  fs.writeFileSync(path.join(GD, 'arte/carpa.json'), JSON.stringify({ sprites, rampa: d.rampas['carpa-c-plantas-a'].cogollo.rampa }));
  // la letra de la interfaz (OFL), la misma que el HTML
  fs.mkdirSync(path.join(GD, 'fuentes'), { recursive: true });
  for (const f of ['atkinson-hyperlegible-latin-400-normal.woff2', 'atkinson-hyperlegible-latin-700-normal.woff2', 'OFL-AtkinsonHyperlegible.txt'])
    fs.copyFileSync(path.join(ROOT, 'assets/fonts', f), path.join(GD, 'fuentes', f));
  return `${lista.length} fotogramas de ${nombres.length} sprites, ${W}×${y + hf}`;
}

(async () => {
  const parcial = !!(ESC || CASOS);
  if (!parcial) console.log('atlas:', atlasCarpa());
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage({ viewport: { width: 1000, height: 700 } });
  const errores = [];
  page.on('pageerror', e => errores.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errores.push(m.text()); });
  await page.goto('file://' + path.join(ROOT, 'index.html'));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
  await page.evaluate(() => arteListo());
  const r = await page.evaluate(async ({ ESCENAS, CICLOS, DEF, parcial }) => {
    try { localStorage.clear(); } catch (e) {}
    mode = 'pausa';   // que el bucle del juego no pinte encima
    const pm = seed => { let x = seed; return () => (x = x * 48271 % 2147483647) / 2147483647; };
    const rnd0 = Math.random;
    function monta(e) {
      S = newState(); S.carpas = [{ t: e.t, foco: e.foco }]; S.macetas = e.macetas.slice(); S.custom = e.custom || {}; S.gen = e.gen || {};
      S.pots = e.pots.map(p => p && JSON.parse(JSON.stringify(p)));
    }
    const o = { escenas: {}, png: {} };
    for (const e of ESCENAS) {
      monta(e); VC = { ci: 0, sel: e.sel, ocupado: false };
      const g = vcGeo(0);if (!g.vc) { o.escenas[e.k] = null; continue; }
      o.escenas[e.k] = { Z: g.vc.Z, w: g.vc.w, xl: g.vc.xl, foco: g.vc.foco.n, tipo: g.vc.tipo, on: plantasVivas(0),
        pl: g.pl.map(q => ({ i: q.i, col: q.col, fila: q.fila, cx: q.cx, cy: q.cy, cw: q.cw, ch: q.ch, x: q.x, y: q.y, alto: q.alto,
          maceta: q.v.m.n, tierra: q.v.tierra, hp: q.v.hp, esp: q.v.esp ?? null, planta: q.v.p ? q.v.p.n : null,
          foto: q.v.p ? vcAltura(q.v.p.n, q.v.hp)[2] : null, hoja: S.pots[q.i] ? hojaPlanta(S.pots[q.i]) : null, porte: S.pots[q.i] ? portePlanta(S.pots[q.i]) : null })) };
      renderCarpaC(g, e.now);
      o.png[e.k] = cv.toDataURL('image/png');
      // la misma sin la capa de luz: así se ve si una diferencia viene del «overlay» o de antes
      const vl = vcLuz;vcLuz = () => mkCanvas(240, 160)[0];renderCarpaC(g, e.now);vcLuz = vl;
      o.png[e.k + '-sinluz'] = cv.toDataURL('image/png');
    }
    // lo que no está en el corte o es solo de pantalla no hace nada: diálogos, animaciones, sonido, avisos, historia, clientes y
    // pedidos del banco (que también tirarían del azar)
    for (const k of ['say', 'accion', 'checkStory', 'fade']) window[k] = async () => {};
    for (const k of ['sfx', 'discover', 'toast', 'buildEnts', 'updateHUD', 'save', 'spawnClients', 'recibirPedido']) window[k] = () => {};
    window.posPlaza = () => [0, 0];
    const nd = newDay;let luz = 0;
    window.newDay = () => { nd();luz += S.luz.e; };
    // harvest de verdad, con lo que sale: lote, gramos, THC, semillas y clase del fenotipo
    async function cosecha(i) {
      const r = { cl: claseFeno(S.pots[i].f), n: 0 }, ab = addBuds, as = addSeeds;
      window.addBuds = (k, g, thc) => { Object.assign(r, { k, g, thc });ab(k, g, thc); };
      window.addSeeds = (sid, n) => { r.n = n;as(sid, n); };
      await harvest(i);
      window.addBuds = ab;window.addSeeds = as;
      return r;
    }
    // al final: lotes, semillas, clase de cada fenotipo cosechado, plazas que siguen ocupadas y el azar que viene
    const fin = () => ({ buds: S.buds, seeds: S.seeds, clases: S.fenos, fenoN: S.fenoN, quedan: S.pots.map(p => !!p), sigue: Math.random() });
    const snap = () => S.pots.map(p => p && { prog: p.prog, water: p.water, health: p.health, pest: p.pest, dead: !!p.dead, st: plantStage(p), etapa: stageName(p) });
    function base(c) {
      Math.random = pm(c.seed);
      S = newState(); S.carpas = [{ t: c.t, foco: c.foco }]; S.macetas = c.macetas.slice(); S.custom = c.custom || {}; S.gen = c.gen || {};
      S.seeds = {}; S.buds = JSON.parse(JSON.stringify(c.buds0 || {})); S.fenos = {};
    }
    o.jornadas = {};
    for (const c of DEF.jornadas || []) {
      base(c); S.money = c.money; S.min = c.min; S.pots = c.macetas.map(() => null);
      c.sids.forEach((sid, i) => { if (sid) S.pots[i] = { sid, prog: 0, water: 70, health: 100, fert: false, pest: false, f: rollFeno(sid) }; });
      const fenos = S.pots.map(p => p && { ...p.f }), tras = [];
      for (const k of c.pasos) {
        S.pots.forEach(p => { if (p && !p.dead && c.rega && p.water < c.rega) p.water = 100; });
        luz = 0;window.ask = async () => k;
        await bedAction();
        tras.push({ day: S.day, min: S.min, money: S.money, luz, pots: snap() });
      }
      const cosechas = [];
      if (c.cosechar) for (let i = 0; i < S.pots.length; i++) { const p = S.pots[i];cosechas.push(p && !p.dead && p.prog >= 1 ? await cosecha(i) : null); }
      o.jornadas[c.k] = { ...c, fenos, tras, cosechas, ...fin() };
    }
    o.cosechas = {};
    for (const c of DEF.cosechas || []) {
      base(c); S.pots = c.pots.map(p => p && JSON.parse(JSON.stringify(p)));
      const r = [];
      for (const i of c.orden) r.push(await cosecha(i));
      o.cosechas[c.k] = { ...c, r, ...fin() };
    }
    Math.random = rnd0;
    if (parcial) return o;
    // datos
    const ids = DEX.slice();
    o.datos = {
      STRAINS: Object.fromEntries(ids.map(k => { const s = STRAINS[k]; return [k, { n: s.n, thc: s.thc, y: s.y, d: s.d, r: s.r, c: s.c, ind: indDe(k), hj: hojaDe(k), tipo: tipoGen(k) }]; })),
      DEX: ids, GENETICA, CARPAS, FOCOS, MACETAS, PLANTA_CM, MACETA_CM, FOCO_CM, FOCO_SEP, HOLGURA, VCA, VC_FILA, VC_TIERRA, LUZ_C, VC_HOJA,
      Y_MEDIA, W_M2, GEN_ESTABLE, TIPO_GEN, KWH, H_LUZ, H_24, EXTRAS, FENO_ESTRELLA, FENO_FLOJO, SEMILLA_HERMA,
      FEM: SHOP.filter(it => it.sid).map(it => it.sid) };   // FEM: las feminizadas (las de tienda)
    // tono y porte por % índica
    o.hojas = [];
    for (const sid of ids) for (const i of [null, 0, 15, 29, 30, 50, 65, 69, 70, 85, 100]) {
      const p = { sid, f: i == null ? undefined : { i } }, h = hojaPlanta(p);
      o.hojas.push({ sid, i, hoja: h, porte: portePlanta(p), tonos: vcTonos(h) });
    }
    // factores de cada carpa, foco y maceta (con y sin goteo y ventilador)
    o.factores = [];
    for (const t in CARPAS) for (const fo in FOCOS) for (const m in MACETAS) for (const x of [0, 1]) {
      S = newState(); S.carpas = [{ t, foco: fo, goteo: !!x, vent: !!x }]; S.macetas = Array(CARPAS[t].plazas).fill(m);
      o.factores.push({ t, foco: fo, m, x, f: factores(0) });
    }
    // ciclos de cultivo con el generador fijo
    o.ciclos = {};
    for (const c of CICLOS) {
      Math.random = pm(c.seed);
      S = newState(); S.carpas = [{ t: c.t, foco: c.foco }]; S.macetas = c.macetas.slice(); S.pots = c.macetas.map(() => null);
      c.sids.forEach((sid, i) => { S.pots[i] = { sid, prog: 0, water: 70, health: 100, fert: false, pest: false, f: rollFeno(sid) }; });
      const fenos = S.pots.map(p => p && { ...p.f }), tiras = [];
      for (let h = 0; h < c.horas; h++) {
        if (h % 24 === 0) S.pots.forEach((p, i) => { if (p && !p.dead) { if (c.rega && p.water < c.rega) p.water = 100; if (i === 1 && p.pest) p.pest = false; } });
        if (h === 30 && S.pots[0]) S.pots[0].fert = true;
        plantsAdvance(60);
        if (h % 12 === 11) tiras.push(snap());
      }
      S.seeds = {};S.buds = {};S.fenos = {};
      const cosechas = [];
      for (let i = 0; i < S.pots.length; i++) { const p = S.pots[i];cosechas.push(p && !p.dead && p.prog >= 1 ? await cosecha(i) : null); }
      o.ciclos[c.k] = { ...c, fenos, tiras, cosechas, ...fin() };
    }
    Math.random = rnd0;
    return o;
  }, { ESCENAS, CICLOS, DEF, parcial });
  await browser.close();
  if (errores.length) { console.error('errores JS:', errores); process.exit(1); }
  fs.mkdirSync(SAL, { recursive: true });
  for (const [k, u] of Object.entries(r.png)) fs.writeFileSync(path.join(SAL, `html-${k}.png`), Buffer.from(u.split(',')[1], 'base64'));
  const orac = { escenas: ESCENAS.map(e => ({ ...e, html: r.escenas[e.k] })), jornadas: r.jornadas, cosechas: r.cosechas };
  if (parcial) {
    fs.writeFileSync(path.join(SAL, 'oraculo.json'), JSON.stringify(orac));
    console.log(`${ESCENAS.length} escenas, ${Object.keys(r.jornadas).length} jornadas, ${Object.keys(r.cosechas).length} cosechas → ${SAL}`);return;
  }
  Object.assign(orac, { hojas: r.hojas, factores: r.factores, ciclos: r.ciclos });
  for (const d of ['datos', 'tests']) fs.mkdirSync(path.join(GD, d), { recursive: true });
  fs.writeFileSync(path.join(GD, 'datos/datos.json'), JSON.stringify(r.datos));
  fs.writeFileSync(path.join(GD, 'tests/oraculo.json'), JSON.stringify(orac));
  const nulas = ESCENAS.filter(e => !r.escenas[e.k]).map(e => e.k);
  console.log(`datos: ${r.datos.DEX.length} variedades · oráculo: ${ESCENAS.length} escenas${nulas.length ? ' (sin vista C: ' + nulas.join(', ') + ')' : ''}, ${r.hojas.length} tonos, ${r.factores.length} factores, ${Object.keys(r.ciclos).length} ciclos, ${Object.keys(r.jornadas).length} jornadas, ${Object.keys(r.cosechas).length} cosechas · PNG en ${path.relative(ROOT, SAL)}`);
})();
