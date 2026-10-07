#!/usr/bin/env node
/*
  Ribera Verde — análisis de riesgos de la calle (docs/ANALISIS.md): encuentros por paso y por trayecto, combate contra
  ladrones, control de policía (soborno, hablar, huir, entregar), calor y redada, la Copa y la caja fuerte propuesta.
  Las tablas salen de un modelo exacto con las mismas reglas que el código (08-mundo, 10-calle, 13-combate, 09-cultivo,
  11-historia) y una simulación con las funciones de verdad del juego (onStepEnd, thiefRound, copRound, newDay, talkClient,
  harvest, con la interfaz y las esperas anuladas y un Park-Miller fijo) comprueba cada cifra: si alguna se aparta más de 4 σ,
  el código ha cambiado y el modelo también tiene que cambiar (sale con 1).
  Uso:  node tools/build.js && node tools/analisis-riesgos.js [--n 20000] [--reservado f.json]
  (escribe las tablas en docs/ANALISIS.md, entre <!-- auto:clave --> y <!-- /auto:clave -->; con --reservado solo comprueba
  los casos de ese archivo y no escribe nada)
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : d; };
const N = +arg('--n', 20000), RES = arg('--reservado'), DOC = path.join(ROOT, 'docs/ANALISIS.md');

// ---------- formato ----------
const coma = (x, d) => x.toFixed(d).replace('.', ',');
const miles = n => String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
const pc = (p, d = 1) => p < .0005 && p > 0 ? '< 0,1 %' : coma(p * 100, d) + ' %';
const eur = x => miles(x) + ' €';

// ---------- modelo exacto ----------
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const unif = (a, b) => Array.from({ length: b - a + 1 }, (_, i) => a + i);
// un paso por el barrio (08-mundo, onStepEnd), desde el capítulo 2: un solo Math.random; policía si r < pp, ladrón si pp ≤ r < pp + pt
const pPolicia = e => e.ch >= 2 && e.g > 0 ? (.002 + e.heat * .00025) * (e.protect ? .4 : 1) : 0;
const pLadron = e => e.ch >= 2 && (e.g >= 5 || e.money >= 150) ? .004 * (e.night ? 2.5 : 1) * (e.tall ? 3 : 1) : 0;
// un trayecto: la probabilidad de que el primer encuentro sea un control o un ladrón (después hay 25 pasos de calma)
function trayecto(tiles, e) {
  let sigue = 1, pol = 0, lad = 0;
  for (const t of tiles) { const a = pPolicia(e), b = pLadron({ ...e, tall: t.tall }); pol += sigue * a; lad += sigue * b; sigue *= 1 - a - b; }
  return { pol, lad, alguno: 1 - sigue };
}
// combate contra un ladrón (13-combate): vida del ladrón 12 + 2·cap + 0…4, golpea entre 2 + cap/4 y 4 + cap/2 (enteros);
// cada ronda, tu acción y, si sigue en pie y no te has ido, su golpe. pol: punio, patada, spray (mientras quede; luego puño),
// huir, hablar u optima (la que menos veces acaba en KO; a igualdad, la que más gana)
const ACC = {
  punio: { p: .92, d: unif(4, 7) }, patada: { p: .65, d: unif(8, 12) }, spray: { p: 1, d: unif(12, 16) } };
function ladron(e) {
  const atk = unif(2 + (e.ch >> 2), 4 + (e.ch >> 1)), ph = clamp(.25 + e.rep / 300, .25, .7), memo = new Map(), tabla = {};
  const suma = (a, b, k) => { for (const x in b) a[x] = (a[x] || 0) + k * b[x]; return a; };
  // tras tu acción: el ladrón con vida hE (si ≤ 0, ganas) te golpea
  const golpe = (hp, hE, s) => {
    if (hE <= 0) return { win: 1 };
    const o = {};for (const d of atk) suma(o, hp - d <= 0 ? { ko: 1 } : V(hp - d, hE, s), 1 / atk.length);return o;
  };
  const accion = (a, hp, hE, s) => {
    if (a === 'huir') return suma({ huye: .5 }, golpe(hp, hE, s), .5);
    if (a === 'hablar') return suma({ habla: ph }, golpe(hp, hE, s), 1 - ph);
    const m = ACC[a], s2 = a === 'spray' ? s - 1 : s, o = suma({}, golpe(hp, hE, s2), 1 - m.p);
    for (const d of m.d) suma(o, golpe(hp, hE - d, s2), m.p / m.d.length);
    return o;
  };
  function V(hp, hE, s) {
    const k = hp + ',' + hE + ',' + s;if (memo.has(k)) return memo.get(k);
    let a = e.pol === 'spray' ? (s > 0 ? 'spray' : 'punio') : e.pol, o;
    if (e.pol === 'optima') {
      let best = null;
      for (const c of ['punio', 'patada', 'spray', 'huir', 'hablar']) {
        if (c === 'spray' && s <= 0) continue;
        const r = accion(c, hp, hE, s);
        if (!best || (r.ko || 0) < (best.r.ko || 0) - 1e-12 || Math.abs((r.ko || 0) - (best.r.ko || 0)) <= 1e-12 && (r.win || 0) > (best.r.win || 0)) best = { c, r };
      }
      a = best.c;o = best.r;tabla[k] = a;
    } else o = accion(a, hp, hE, s);
    memo.set(k, o);return o;
  }
  const o = {}, ini = unif(12 + 2 * e.ch, 16 + 2 * e.ch);
  for (const hE of ini) suma(o, V(e.hp, hE, e.spray || 0), 1 / ini.length);
  for (const x of ['win', 'ko', 'huye', 'habla']) o[x] = o[x] || 0;
  return { ...o, tabla, primera: ini.map(hE => tabla[e.hp + ',' + hE + ',' + (e.spray || 0)]) };
}
// control de policía (13-combate, copRound) con cada opción: probabilidad de que te requisen y lo que pierdes de media
// (dinero y gramos, estos a precio de calle de una variedad del 18 %)
function policia(e, op, eurG) {
  const multa = Math.min(e.money, 601), req = { g: e.g, m: multa };
  if (op === 'sobornar') {
    const c = Math.round(40 + 4 * e.heat + .5 * e.g), q = !e.protect && e.ch >= 3 ? .15 : 0;
    if (e.money < c) return { posible: false, coste: c };
    return { posible: true, coste: c, pReq: q, m: (1 - q) * c + q * multa, g: q * e.g, eur: (1 - q) * c + q * (multa + e.g * eurG) };
  }
  const p = op === 'hablar' ? clamp(.3 + e.rep / 250 - e.heat / 300, .1, .85) : op === 'huir' ? .45 + (e.night ? .15 : 0) : 0;
  return { posible: true, pReq: 1 - p, m: (1 - p) * (op === 'entregar' ? 0 : multa), g: (1 - p) * req.g,
    eur: (1 - p) * ((op === 'entregar' ? 0 : multa) + e.g * eurG) };
}
const mejorPolicia = (e, eurG) => ['sobornar', 'hablar', 'huir', 'entregar'].map(op => ({ op, ...policia(e, op, eurG) }))
  .filter(r => r.posible).sort((a, b) => a.eur - b.eur)[0];
// la Copa (talkJurado): un lote de una planta gana si su THC, redondeado a una décima, pasa de 26,8. THC de la cosecha
// (harvest): thc·t·(0,85 + 0,15·salud) + luz (F.thc·densidad) + 0,3 con abono, redondeado a una décima; t = 1 + σ·z,
// entre 0,6 y 1,5, redondeado a centésimas
const erf = x => { const s = Math.sign(x), t = 1 / (1 + .3275911 * Math.abs(x)), y = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - .284496736) * t + .254829592) * t * Math.exp(-x * x);return s * y; };
const Phi = z => .5 * (1 + erf(z / Math.SQRT2));
function copa(thc, sigma, luz, abono, salud = 100) {
  let p = 0;
  for (let c = 60; c <= 150; c++) {   // t = c/100: lo que cae en [c − 0,5, c + 0,5) centésimas (con los extremos del clamp)
    const lo = c === 60 ? -Infinity : (c - .5) / 100, hi = c === 150 ? Infinity : (c + .5) / 100;
    const pt = Phi((hi - 1) / sigma) - Phi((lo - 1) / sigma), t = c / 100;
    const h = Math.min(35, Math.round((thc * t * (.85 + .15 * salud / 100) + luz + (abono ? .3 : 0)) * 10) / 10);
    if (Math.round(h * 10) / 10 > 26.8) p += pt;
  }
  return p;
}

// ---------- comprobación con el juego ----------
const tol = (p, n) => 4 * Math.sqrt(Math.max(p * (1 - p), 1e-6) / n) + 1e-9;
const fallos = [];
const compara = (que, exacto, mc, n, sd) => {
  const t = sd != null ? 4 * sd / Math.sqrt(n) + 1e-9 : tol(exacto, n);
  const ok = Math.abs(exacto - mc) <= t;
  if (!ok) fallos.push(`${que}: modelo ${exacto.toFixed(5)}, juego ${mc.toFixed(5)} (±${t.toFixed(5)})`);
  return ok;
};

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage();
  const errores = [];
  page.on('pageerror', e => errores.push(e.message));
  await page.goto('file://' + (process.env.RV_HTML ? path.resolve(process.env.RV_HTML) : path.join(ROOT, 'index.html')));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
  // el juego, quieto y sin interfaz: las esperas se resuelven en el acto y el azar es un Park-Miller con semilla
  await page.evaluate(() => {
    mode = 'pausa';S = newState();
    window.setTimeout = f => { Promise.resolve().then(f); return 0; };
    for (const k of ['say', 'accion', 'checkStory', 'fade', 'talk', 'got']) window[k] = async () => {};
    for (const k of ['sfx', 'toast', 'bhud', 'prompt', 'vfxCombate', 'updateHUD', 'buildEnts', 'heatWarn', 'music', 'save']) window[k] = () => {};
    window.bAnim = () => 0;
    window.semilla = n => { let s = n % 2147483647;if (s <= 0) s += 2147483646;Math.random = () => (s = s * 16807 % 2147483647) / 2147483647; };
  });
  const juego = (fn, a) => page.evaluate(fn, a);
  const datos = await juego(() => ({ eurG: precioCalle(18), pc: [12, 18, 24, 30].map(t => [t, precioCalle(t), precioMayor(t)]), multa: MULTA_CALLE, soborno: SOBORNO, redada: MULTA_REDADA, olor: OLOR,
    focos: Object.fromEntries(Object.entries(FOCOS).map(([k, F]) => [k, { thc: F.thc, w: F.w }])), W_M2,
    carpas: Object.fromEntries(Object.entries(CARPAS).map(([k, C]) => [k, { cm: C.cm, n: C.plazas }])),
    sigma: Object.fromEntries(Object.entries(GENETICA).map(([k, G]) => [k, G.sigma])),
    thc: { tormenta: STRAINS.tormenta.thc, dragon: STRAINS.dragon.thc, leyenda: STRAINS.leyenda.thc }, nombres: { tormenta: STRAINS.tormenta.n, dragon: STRAINS.dragon.n, leyenda: STRAINS.leyenda.n } }));
  const precioC = t => 4 + t * .2, precioM = t => 2 + t * .1;
  for (const [t, a, b] of datos.pc) if (Math.abs(precioC(t) - a) > 1e-9 || Math.abs(precioM(t) - b) > 1e-9) fallos.push(`precios con THC ${t}: ${a} y ${b}`);
  const luzDe = (t, f) => { const C = datos.carpas[t], F = datos.focos[f];return F.thc * Math.min(1, F.w / (C.cm[0] * C.cm[2] / 1e4 * datos.W_M2)); };

  // ---- 1. un paso: onStepEnd de verdad, n veces en una casilla de hierba o de hierba alta ----
  const pasoMC = (e, n) => juego(({ e, n }) => {
    semilla(12345);const r = { police: 0, thief: 0 };
    window.battle = async k => { r[k]++; };
    S = newState();Object.assign(S, { ch: e.ch, heat: e.heat, protect: e.protect, money: e.money, map: 'town', min: e.night ? 23 * 60 : 12 * 60 });
    S.buds = e.g ? { ria: { g: e.g, thc: 12 } } : {};
    const [x, y] = e.tall ? [8, 19] : [12, 16];P.x = x;P.y = y;
    for (let i = 0; i < n; i++) { S.cool = 0;onStepEnd(); }
    return { pol: r.police / n, lad: r.thief / n, casilla: MAPS.town.g[y][x] };
  }, { e, n });

  // ---- 2. trayectos desde la puerta de casa (5, 9): el camino más corto (con tileSolid), evitando la hierba alta si da igual ----
  // (en la casilla de destino no hay encuentro si es una puerta: onStepEnd entra antes; en las demás, sí)
  const rutasDe = destinos => juego(destinos => {
    const m = MAPS.town;S = newState();S.map = 'town';
    const puertas = new Set(Object.keys(m.doors));
    const ruta = ([x0, y0], [x1, y1]) => {
      const dist = new Map(), prev = new Map(), k = (x, y) => x + ',' + y, cola = [[0, x0, y0]];dist.set(k(x0, y0), 0);
      while (cola.length) {
        cola.sort((a, b) => a[0] - b[0]);const [d, x, y] = cola.shift();
        if (x === x1 && y === y1) break;
        if (d > dist.get(k(x, y))) continue;
        for (const [dx, dy] of [[0, -1], [0, 1], [-1, 0], [1, 0]]) {
          const nx = x + dx, ny = y + dy, nk = k(nx, ny), esDest = nx === x1 && ny === y1;
          if (!esDest && (tileSolid(m, nx, ny) || puertas.has(nk))) continue;
          const nd = d + 1 + (m.g[ny] && m.g[ny][nx] === 'tallgrass' ? 1e-3 : 0);
          if (!dist.has(nk) || nd < dist.get(nk)) { dist.set(nk, nd);prev.set(nk, k(x, y));cola.push([nd, nx, ny]); }
        }
      }
      if (!dist.has(k(x1, y1))) throw new Error('sin camino a ' + x1 + ',' + y1);
      const out = [];let c = k(x1, y1);
      while (c && c !== k(x0, y0)) { const [x, y] = c.split(',').map(Number);out.unshift({ x, y, tall: m.g[y][x] === 'tallgrass' });c = prev.get(c); }
      return puertas.has(k(x1, y1)) ? out.slice(0, -1) : out;
    };
    return destinos.map(d => ({ ...d, tiles: ruta(d.de, d.a) }));
  }, destinos);
  const rutas = await rutasDe([
    { k: 'tienda', n: 'Growshop de Kiko', de: [5, 9], a: [17, 8] }, { k: 'bar', n: 'Bar El Ancla (Baltasar)', de: [5, 9], a: [26, 8] },
    { k: 'plaza', n: 'Plaza (Patxi, clientes)', de: [5, 9], a: [21, 20] }, { k: 'muelle', n: 'Muelle (Iñaki)', de: [5, 9], a: [36, 21] },
    { k: 'txaro', n: 'Parque (Txaro)', de: [5, 9], a: [4, 18] }, { k: 'hierba', n: 'Hierba alta del parque (8, 19)', de: [5, 9], a: [8, 19] },
    { k: 'arbusto', n: 'Arbusto escondido (2, 25)', de: [5, 9], a: [2, 25] }]);
  // un trayecto andado con onStepEnd de verdad, casilla a casilla, hasta el primer encuentro (Darko y Molina ya vistos)
  const trayectoMC = (tiles, e, n) => juego(({ tiles, e, n }) => {
    semilla(31337);let pol = 0, lad = 0, k = null;
    window.battle = async x => { k = x; };
    for (let i = 0; i < n; i++) {
      S = newState();Object.assign(S, { ch: e.ch, heat: e.heat, protect: !!e.protect, money: e.money, map: 'town', min: e.night ? 23 * 60 : 12 * 60 });
      S.flags.darko1 = S.flags.molina1 = true;S.buds = e.g ? { ria: { g: e.g, thc: 12 } } : {};k = null;
      for (const t of tiles) { P.x = t.x;P.y = t.y;onStepEnd();if (k) break; }
      if (k === 'police') pol++;else if (k === 'thief') lad++;
    }
    return { pol: pol / n, lad: lad / n };
  }, { tiles, e, n });

  // ---- 3. combate contra un ladrón: thiefRound de verdad con una política fija (o la tabla de la óptima) ----
  const ladronMC = (e, tabla, n) => juego(({ e, tabla, n }) => {
    semilla(777);const r = { win: 0, ko: 0, flee: 0, talk: 0 };
    return (async () => {
      for (let i = 0; i < n; i++) {
        S = newState();Object.assign(S, { ch: e.ch, hp: e.hp, hpMax: 60, rep: e.rep, money: 1000 });S.items.spray = e.spray || 0;S.buds = { ria: { g: 100, thc: 12 } };
        B = { kind: 'thief', name: 'LADRÓN', hpMax: 12 + e.ch * 2 + ri(0, 4), atk: [2 + (e.ch >> 2), 4 + (e.ch >> 1)] };B.hp = B.hpMax;
        const quiere = () => e.pol === 'optima' ? tabla[S.hp + ',' + B.hp + ',' + S.items.spray] : e.pol === 'spray' ? (S.items.spray > 0 ? 'spray' : 'punio') : e.pol;
        window.menu = async items => {
          const a = quiere(), l = items.map(x => typeof x === 'string' ? x : x.label);
          if (l[0] === 'LUCHAR') return a === 'spray' ? 1 : a === 'hablar' ? 2 : a === 'huir' ? 3 : 0;
          if (l[0] === 'PUÑETAZO') return a === 'patada' ? 1 : 0;
          return 0;   // mochila: el spray
        };
        let res = null;while (!res) res = await thiefRound();
        r[res]++;
      }
      return { win: r.win / n, ko: r.ko / n, huye: r.flee / n, habla: r.talk / n };
    })();
  }, { e, tabla, n });

  // ---- 4. control de policía: copRound de verdad con cada opción (soborno aceptado) ----
  const policiaMC = (e, op, n) => juego(({ e, op, n }) => {
    semilla(4242);let req = 0, m = 0, g = 0, m2 = 0;
    return (async () => {
      for (let i = 0; i < n; i++) {
        S = newState();Object.assign(S, { ch: e.ch, heat: e.heat, rep: e.rep, money: e.money, protect: e.protect, min: e.night ? 23 * 60 : 12 * 60 });
        S.buds = { ria: { g: e.g, thc: 12 } };B = { kind: 'police', name: 'AGENTE' };
        window.menu = async () => ['sobornar', 'hablar', 'huir', 'entregar'].indexOf(op);
        window.ask = async () => 0;
        const r = await copRound();
        const dm = e.money - S.money, dg = e.g - totalBuds();
        if (r === 'caught') req++;m += dm;m2 += dm * dm;g += dg;
      }
      return { pReq: req / n, m: m / n, sdm: Math.sqrt(Math.max(0, m2 / n - (m / n) ** 2)), g: g / n };
    })();
  }, { e, op, n });

  // ---- 5. calor: newDay de verdad (redada, bajada diaria y olor) y una venta en la calle (talkClient) ----
  const dia = await juego(() => {
    const r = [];
    for (const [heat, protect, flor] of [[90, false, 0], [89.9, false, 0], [100, true, 0], [40, false, 2]]) {
      S = newState();Object.assign(S, { ch: 5, heat, protect, map: 'home' });
      if (flor) { S.carpas = [{ t: 'p60', foco: 'cfl' }, { t: 'm100', foco: 'cfl' }];S.macetas = Array(6).fill('plastico7');S.pots = Array(6).fill(null);
        S.pots[0] = { sid: 'ria', prog: .8, water: 70, health: 100 };S.pots[2] = { sid: 'ria', prog: .8, water: 70, health: 100 }; }
      const q = [];window.queue = k => q.push(k);
      newDay();r.push({ heat, protect, flor, redada: q.includes('raid'), despues: S.heat });
    }
    return r;
  });
  const ventaMC = n => juego(n => {
    semilla(99);let ok = 0, dh = 0;
    return (async () => {
      for (let i = 0; i < n; i++) {
        S = newState();Object.assign(S, { ch: 5, heat: 10, map: 'town' });S.buds = { reina: { g: 50, thc: 24 } };
        const c = { id: 'c', type: 'pij', want: 8, minThc: 21 };S.clients = [c];
        window.menu = async () => 0;window.ask = async () => 2;   // el lote y «Caro»
        await talkClient(c);
        if (S.money > 150) { ok++;dh += S.heat - 10; }
      }
      return { acepta: ok / n, calor: ok ? dh / ok : 0 };
    })();
  }, n);

  // Iñaki (10 g) y al por mayor (1 kg): talkInaki y ventaMayor de verdad, una vez cada una
  const iñaki = await juego(() => (async () => {
    const r = {};window.menu = async () => 0;
    S = newState();Object.assign(S, { ch: 2, heat: 10, map: 'town' });S.buds = { ria: { g: 50, thc: 18 } };window.ask = async () => 0;
    await talkInaki();r.inaki = { e: S.money - 150, h: S.heat - 10, g: 50 - totalBuds() };
    S = newState();Object.assign(S, { ch: 3, heat: 10, map: 'town' });S.buds = { ria: { g: 5000, thc: 18 } };
    window.ask = async (t, ops) => ops.findIndex(o => /^1 kg/.test(o));
    await ventaMayor('IÑAKI');r.mayor = { e: S.money - 150, h: S.heat - 10, g: 5000 - totalBuds() };
    return r;
  })());

  // ---- 6. la Copa: harvest de verdad (fenotipo con rollFeno) de la carpa llena; los lotes se juntan con addBuds, como en el juego
  // (una variedad = un lote, con el THC medio por gramos; lo de un fenotipo estrella, aparte) y el jurado pide 20 g de un lote ----
  const copaMC = (e, n) => juego(({ e, n }) => {
    semilla(2026);let pasa = 0, plantas = 0, gana = 0, gramos = 0;
    return (async () => {
      for (let i = 0; i < n; i++) {
        S = newState();S.ch = 6;S.carpas = [{ t: e.carpa, foco: e.foco }];const h = CARPAS[e.carpa].plazas;
        S.macetas = Array(h).fill(e.maceta);S.pots = Array(h).fill(null);S.gen = { [e.sid]: e.gen };
        for (let j = 0; j < h; j++) S.pots[j] = { sid: e.sid, prog: 1, water: 70, health: 100, fert: e.abono, pest: false, f: rollFeno(e.sid) };
        const cos = [];
        for (let j = 0; j < h; j++) { S.buds = {};await harvest(j);const [k, b] = Object.entries(S.buds)[0];cos.push([k, b.g, b.thc]);
          plantas++;gramos += b.g;if (Math.round(b.thc * 10) / 10 > 26.8) pasa++; }
        S.buds = {};for (const [k, g, thc] of cos) addBuds(k, g, thc);
        if (budLots(20).some(([, b]) => Math.round(b.thc * 10) / 10 > 26.8)) gana++;
      }
      return { p: pasa / plantas, plantas, lote: gana / n, g: gramos / plantas };
    })();
  }, { e, n });

  const T = {};   // las tablas del documento
  const res = RES ? JSON.parse(fs.readFileSync(RES, 'utf8')) : null;

  if (res) {
    // ---------- caso reservado: solo comprobar ----------
    for (const e of res.paso) { const mc = await pasoMC(e, N * 5);compara('reservado paso policía', pPolicia(e), mc.pol, N * 5);compara('reservado paso ladrón', pLadron(e), mc.lad, N * 5); }
    for (const e of res.ladron) { const x = ladron(e), mc = await ladronMC(e, x.tabla, N);
      for (const k of ['win', 'ko', 'huye', 'habla']) compara(`reservado ladrón ${e.pol} ${k}`, x[k], mc[k], N);
      console.log(`ladrón ${e.pol}: modelo KO ${pc(x.ko)} gana ${pc(x.win)} · juego KO ${pc(mc.ko)} gana ${pc(mc.win)}`); }
    for (const e of res.policia) for (const op of ['sobornar', 'hablar', 'huir', 'entregar']) {
      const x = policia(e, op, datos.eurG);if (!x.posible) continue;const mc = await policiaMC(e, op, N);
      compara(`reservado policía ${op} requisa`, x.pReq, mc.pReq, N);compara(`reservado policía ${op} dinero`, x.m, mc.m, N, mc.sdm);
      console.log(`policía ${op}: modelo requisa ${pc(x.pReq)}, −${coma(x.m, 1)} € · juego ${pc(mc.pReq)}, −${coma(mc.m, 1)} €`); }
    const [ru] = await rutasDe([{ k: 'reservada', de: res.ruta.de, a: res.ruta.a }]), er = res.ruta, xr = trayecto(ru.tiles, er), mr = await trayectoMC(ru.tiles, er, N);
    compara('reservado ruta policía', xr.pol, mr.pol, N);compara('reservado ruta ladrón', xr.lad, mr.lad, N);
    console.log(`ruta reservada (${ru.tiles.length} pasos, ${ru.tiles.filter(t => t.tall).length} en hierba alta): modelo control ${pc(xr.pol)} robo ${pc(xr.lad)} · juego ${pc(mr.pol)} ${pc(mr.lad)}`);
  } else {
    // ---------- 1. por paso ----------
    const PASOS = [
      { n: 'Sin nada (0 g, < 150 €)', ch: 3, heat: 0, protect: false, g: 0, money: 100 },
      { n: 'Solo dinero (0 g, ≥ 150 €), de día', ch: 3, heat: 0, protect: false, g: 0, money: 2000 },
      { n: 'Con gramos, calor 0, de día', ch: 3, heat: 0, protect: false, g: 50, money: 2000 },
      { n: 'Con gramos, calor 50, de día', ch: 3, heat: 50, protect: false, g: 50, money: 2000 },
      { n: 'Con gramos, calor 89, de día', ch: 3, heat: 89, protect: false, g: 50, money: 2000 },
      { n: 'Con gramos, calor 89, con protección', ch: 5, heat: 89, protect: true, g: 50, money: 2000 },
      { n: 'Con gramos, calor 50, de noche', ch: 3, heat: 50, protect: false, g: 50, money: 2000, night: true },
      { n: 'Con gramos, calor 50, de noche en hierba alta', ch: 3, heat: 50, protect: false, g: 50, money: 2000, night: true, tall: true }];
    const filas = [];
    for (const e of PASOS) {
      const a = pPolicia(e), b = pLadron(e), mc = await pasoMC(e, N * 5);
      compara(`paso «${e.n}» policía`, a, mc.pol, N * 5);compara(`paso «${e.n}» ladrón`, b, mc.lad, N * 5);
      filas.push(`| ${e.n} | ${pc(a, 2)} | ${pc(b, 2)} | ${a + b ? miles(1 / (a + b)) : '—'} | ${pc(mc.pol, 2)} · ${pc(mc.lad, 2)} |`);
    }
    T.paso = ['| Situación | Control por paso | Ladrón por paso | Pasos de media hasta un encuentro | Juego (simulado) |', '|---|---|---|---|---|', ...filas].join('\n');

    // ---------- 2. por trayecto ----------
    const ESC = [
      { n: 'cap. 3, calor 30, de día', ch: 3, heat: 30, g: 50, money: 2000 },
      { n: 'cap. 5, calor 80, de noche', ch: 5, heat: 80, g: 50, money: 2000, night: true },
      { n: 'cap. 5, calor 80, con protección', ch: 5, heat: 80, g: 50, money: 2000, protect: true }];
    for (const [rk, ei] of [['plaza', 1], ['hierba', 0]]) { const tl = rutas.find(r => r.k === rk).tiles, x = trayecto(tl, ESC[ei]), mc = await trayectoMC(tl, ESC[ei], N);
      compara(`trayecto ${rk} control`, x.pol, mc.pol, N);compara(`trayecto ${rk} robo`, x.lad, mc.lad, N); }
    T.rutas = ['| Ida desde casa | Pasos | En hierba alta | ' + ESC.map(e => `Control / robo (${e.n})`).join(' | ') + ' |',
      '|---|---|---|' + ESC.map(() => '---|').join(''),
      ...rutas.map(r => `| ${r.n} | ${r.tiles.length} | ${r.tiles.filter(t => t.tall).length} | ` +
        ESC.map(e => { const x = trayecto(r.tiles, e);return `${pc(x.pol)} / ${pc(x.lad)}`; }).join(' | ') + ' |')].join('\n');

    // ---------- 3. ladrón ----------
    const POL = { punio: 'Puñetazo', patada: 'Patada', spray: 'Spray ×2 y puñetazo', huir: 'Huir', hablar: 'Hablar (rep. 0)', optima: 'La mejor (mínimo KO)' };
    const filasL = [];
    for (const [ch, hp] of [[2, 30], [5, 40], [8, 40], [8, 60]]) {
      for (const pol of Object.keys(POL)) {
        const e = { ch, hp, rep: 0, spray: pol === 'spray' || pol === 'optima' ? 2 : 0, pol }, x = ladron(e);
        let mcTxt = '';
        if ((ch === 2 || ch === 8 && hp === 40) || pol === 'optima') {
          const mc = await ladronMC(e, x.tabla, N);for (const k of ['win', 'ko', 'huye', 'habla']) compara(`ladrón cap ${ch} vida ${hp} ${pol} ${k}`, x[k], mc[k], N);
          mcTxt = `${pc(mc.ko)}`;
        }
        filasL.push(`| ${ch} | ${hp} | ${POL[pol]} | ${pc(x.win)} | ${pc(x.ko)} | ${pc(x.huye + x.habla)} | ${mcTxt || '—'} |`);
      }
    }
    // hablar con reputación alta
    for (const rep of [60, 150]) { const e = { ch: 5, hp: 40, rep, pol: 'hablar' }, x = ladron(e), mc = await ladronMC(e, x.tabla, N);
      for (const k of ['win', 'ko', 'huye', 'habla']) compara(`ladrón hablar rep ${rep} ${k}`, x[k], mc[k], N);
      filasL.push(`| 5 | 40 | Hablar (rep. ${rep}) | ${pc(x.win)} | ${pc(x.ko)} | ${pc(x.huye + x.habla)} | ${pc(mc.ko)} |`); }
    T.ladron = ['| Cap. | Tu vida | Estrategia | Ganas | KO (te roban) | Se acaba sin pelea (huyes o se va) | KO en el juego |', '|---|---|---|---|---|---|---|', ...filasL].join('\n');
    const opt = ladron({ ch: 5, hp: 40, rep: 0, spray: 2, pol: 'optima' }), ACN = { punio: 'puñetazo', patada: 'patada', spray: 'spray', huir: 'huir', hablar: 'hablar' };
    const grupos = [];opt.primera.forEach((a, i) => { const v = 22 + i, g = grupos[grupos.length - 1];if (g && g.a === a) g.b = v;else grupos.push({ a, d: v, b: v }); });
    T.optima = `Con 40 de vida y 2 sprays en el capítulo 5 (el ladrón tiene de 22 a 26 de vida y pega de 3 a 6), la acción que menos veces acaba en KO es, de entrada: ${grupos.map(g => `${ACN[g.a]} si tiene ${g.d === g.b ? g.d : g.d + '-' + g.b}`).join('; ')}. Pelear siempre es mejor que huir o hablar con poca reputación.`;

    // ---------- 4. policía ----------
    const ESP = [
      { n: 'Cap. 2 · calor 20 · rep. 10 · 30 g · 300 €', ch: 2, heat: 20, rep: 10, g: 30, money: 300 },
      { n: 'Cap. 4 · calor 60 · rep. 40 · 200 g · 2.000 € · noche', ch: 4, heat: 60, rep: 40, g: 200, money: 2000, night: true },
      { n: 'Cap. 5 · calor 85 · rep. 60 · 600 g · 8.000 €', ch: 5, heat: 85, rep: 60, g: 600, money: 8000 },
      { n: 'Cap. 5 · igual, con protección', ch: 5, heat: 85, rep: 60, g: 600, money: 8000, protect: true },
      { n: 'Cap. 8 · calor 50 · rep. 150 · 3.000 g · 40.000 €', ch: 8, heat: 50, rep: 150, g: 3000, money: 40000 }];
    const OPS = { sobornar: 'Sobornar', hablar: 'Hablar', huir: 'Huir', entregar: 'Entregar' }, filasP = [];
    for (const e of ESP) {
      const celdas = [];
      for (const op of Object.keys(OPS)) {
        const x = policia(e, op, datos.eurG);
        if (!x.posible) { celdas.push(`no llega (${eur(x.coste)})`);continue; }
        const mc = await policiaMC(e, op, N);
        compara(`policía «${e.n}» ${op} requisa`, x.pReq, mc.pReq, N);compara(`policía «${e.n}» ${op} dinero`, x.m, mc.m, N, mc.sdm);compara(`policía «${e.n}» ${op} gramos`, x.g, mc.g, N, e.g * Math.sqrt(x.pReq * (1 - x.pReq)));
        celdas.push(`${op === 'sobornar' ? eur(x.coste) + ' · ' : ''}requisa ${pc(x.pReq, 0)} · −${eur(x.eur)}`);
      }
      const m = mejorPolicia(e, datos.eurG);
      filasP.push(`| ${e.n} | ${celdas.join(' | ')} | ${OPS[m.op]} |`);
    }
    T.policia = ['| Situación | Sobornar | Hablar | Huir | Entregar | Mejor |', '|---|---|---|---|---|---|', ...filasP].join('\n');

    // ---------- 5. calor ----------
    const d = dia;
    if (!(d[0].redada && !d[1].redada)) fallos.push('newDay: la redada no salta justo en 90');
    if (Math.abs(d[0].despues - 78) > 1e-9 || Math.abs(d[1].despues - 77.9) > 1e-9) fallos.push(`newDay: bajada diaria distinta de 12 (${d[0].despues}, ${d[1].despues})`);
    if (Math.abs(d[2].despues - 80) > 1e-9) fallos.push(`newDay con protección: ${d[2].despues} (esperado 80: sin redada y −20)`);
    if (Math.abs(d[3].despues - (40 - 12 + 2 * datos.olor)) > 1e-9) fallos.push(`newDay con dos carpas en flor: ${d[3].despues}`);
    const v = await ventaMC(N), accV = clamp(.3 + (24 - 21) * .05 + .25, .1, .9);
    compara('venta cara a un pijo: acepta', accV, v.acepta, N);
    if (Math.abs(v.calor - (3 + 8 * .5)) > 1e-9) fallos.push(`venta de 8 g: calor +${v.calor} (esperado +7)`);
    // € por punto de calor: lo que da cada forma de vender frente a lo que sube el calor (la bajada diaria es 12, o 20 con protección)
    const vender = [
      ['Calle · currela, 8 g a precio justo', Math.round(precioC(18) * 1 * 8), 3 + 8 * .5],
      ['Calle · pijo, 12 g caro (THC 24; acepta el 70 %)', Math.round(precioC(24) * 1.35 * 12 * 1.3), 3 + 12 * .5],
      ['Iñaki · 10 g para el viaje (una vez al día)', Math.round(precioC(18) * 1.2 * 10), 3],
      ['Al por mayor · 1 kg (una carga al día, hasta 1 kg antes del imperio)', Math.round(1000 * precioM(18)), 2 + 1000 / 250],
      ['Al por mayor · 10 kg (Mayorista del norte)', Math.round(10000 * precioM(18)), 2 + 10000 / 250]];
    if (iñaki.inaki.e !== vender[2][1] || iñaki.inaki.h !== 3 || iñaki.inaki.g !== 10) fallos.push('Iñaki 10 g: ' + JSON.stringify(iñaki.inaki));
    if (iñaki.mayor.e !== vender[3][1] || iñaki.mayor.h !== 6 || iñaki.mayor.g !== 1000) fallos.push('al por mayor 1 kg: ' + JSON.stringify(iñaki.mayor));
    T.eficiencia = ['| Venta (THC 18 %, salvo el pijo) | Cobras | Calor | € por punto de calor |', '|---|---|---|---|',
      ...vender.map(([n, e, h]) => `| ${n} | ${eur(e)} | +${coma(h, 0)} | ${miles(e / h)} € |`)].join('\n');
    T.calorOk = `Comprobado con el juego: redada con calor 90 y no con 89,9; −12 al día (−20 con protección); +${datos.olor} por carpa en flor sin filtro; una venta cara de 8 g a un pijo (THC 24, pide 21) acepta un ${pc(v.acepta)} (modelo ${pc(accV)}) y suma ${coma(v.calor, 1)} de calor.`;

    // ---------- 6. Copa ----------
    const nom = datos.nombres, CP = { p60: 'armario 60', m100: 'carpa 100', m120: 'carpa 120', g150: 'carpa 150' }, FC = { cfl: 'CFL', led480: 'LED 480 W', sodio600: 'sodio 600 W', led720: 'LED 720 W' };
    const COPA = [['tormenta', 1, 'p60', 'cfl', false, 'plastico7'], ['tormenta', 1, 'm100', 'led480', true, 'tela25'], ['tormenta', 1, 'g150', 'sodio600', true, 'tela25'],
      ['tormenta', 1, 'm120', 'led720', true, 'tela25'], ['tormenta', 4, 'm120', 'led720', true, 'tela25'], ['dragon', 1, 'p60', 'cfl', false, 'plastico7'], ['dragon', 1, 'm120', 'led720', true, 'tela25']]
      .map(([sid, gen, carpa, foco, abono, maceta]) => ({ sid, gen, carpa, foco, abono, maceta, sig: gen >= 4 ? 'estable' : 'F' + gen,
        n: `${nom[sid]} ${gen >= 4 ? 'estable' : 'F' + gen} · ${CP[carpa]} + ${FC[foco]}${abono ? ' · abono' : ''}` }));
    const filasC = [];
    for (const e of COPA) {
      const luz = luzDe(e.carpa, e.foco), p = copa(datos.thc[e.sid], datos.sigma[e.sig], luz, e.abono), mc = await copaMC(e, Math.ceil(N / 4));
      compara(`Copa ${e.n} (por planta)`, p, mc.p, mc.plantas);
      const media = Math.round((datos.thc[e.sid] + luz + (e.abono ? .3 : 0)) * 10) / 10;
      filasC.push(`| ${e.n} | ${datos.carpas[e.carpa].n} | ${coma(media, 1)} % | ${pc(p)} | ${pc(mc.p)} | ${coma(mc.g, 0)} g | ${pc(mc.lote)} |`);
    }
    T.copa = ['| Planta y equipo | Plazas | THC medio | Una planta pasa de 26,8 % (modelo) | Juego (por planta) | Gramos por planta | Carpa llena: algún lote de 20 g gana (juego) |',
      '|---|---|---|---|---|---|---|', ...filasC].join('\n');

    // ---------- 7. caja fuerte: antes (todo encima) y después (solo lo que hace falta) ----------
    const R = Object.fromEntries(rutas.map(r => [r.k, r.tiles]));
    const perdidaTramo = (tiles, e) => {   // primer encuentro del tramo: control (la mejor opción) o ladrón (la mejor estrategia)
      const t = trayecto(tiles, e), lad = ladron({ ch: e.ch, hp: e.hp, rep: e.rep, spray: e.spray, pol: 'optima' });
      const lp = e.g > 0 ? mejorPolicia(e, datos.eurG).eur : 0, lk = lad.ko * (Math.floor(e.g / 2) * datos.eurG + Math.round(e.money * .3));
      return { pol: t.pol, lad: t.lad, eur: t.pol * lp + t.lad * lk };
    };
    const CAJA = [
      { n: 'Cap. 3 · ir a comprar a Kiko (200 €)', ruta: 'tienda', base: { ch: 3, heat: 30, rep: 20, hp: 40, spray: 1 },
        antes: [{ g: 300, money: 2000 }, { g: 300, money: 1800 }], despues: [{ g: 0, money: 200 }, { g: 0, money: 0 }] },
      { n: 'Cap. 4 · vender 10 g a Iñaki', ruta: 'muelle', base: { ch: 4, heat: 50, rep: 40, hp: 40, spray: 1 },
        antes: [{ g: 400, money: 5000 }, { g: 390, money: 5091 }], despues: [{ g: 10, money: 0 }, { g: 0, money: 91 }] },
      { n: 'Cap. 4 · vender 40 g en la plaza, de noche', ruta: 'plaza', base: { ch: 4, heat: 60, rep: 40, hp: 40, spray: 1, night: true },
        antes: [{ g: 400, money: 5000 }, { g: 360, money: 5300 }], despues: [{ g: 40, money: 0 }, { g: 0, money: 300 }] },
      { n: 'Cap. 5 · pagar 12.000 € a Baltasar', ruta: 'bar', base: { ch: 5, heat: 70, rep: 60, hp: 44, spray: 2 },
        antes: [{ g: 600, money: 13000 }, { g: 600, money: 1000 }], despues: [{ g: 0, money: 12000 }, { g: 0, money: 0 }] },
      { n: 'Cap. 8 · cargar 2 kg a Iñaki', ruta: 'muelle', base: { ch: 8, heat: 50, rep: 150, hp: 60, spray: 2 },
        antes: [{ g: 5000, money: 40000 }, { g: 3000, money: 47600 }], despues: [{ g: 2000, money: 0 }, { g: 0, money: 7600 }] }];
    const filasK = [];
    for (const c of CAJA) {
      const t = R[c.ruta], tramo = (k, i) => perdidaTramo(t, { ...c.base, ...c[k][i] });
      const a = [tramo('antes', 0), tramo('antes', 1)], b = [tramo('despues', 0), tramo('despues', 1)];
      const s = x => ({ pol: 1 - (1 - x[0].pol) * (1 - x[1].pol), lad: 1 - (1 - x[0].lad) * (1 - x[1].lad), eur: x[0].eur + x[1].eur });
      const A = s(a), Bq = s(b);
      filasK.push(`| ${c.n} | ${pc(A.pol)} / ${pc(A.lad)} · ${eur(A.eur)} | ${pc(Bq.pol)} / ${pc(Bq.lad)} · ${eur(Bq.eur)} |`);
    }
    T.caja = ['| Ida y vuelta | Hoy: control / ladrón · pérdida media | Con caja fuerte: control / ladrón · pérdida media |', '|---|---|---|', ...filasK].join('\n');
    T.meta = `Generado con \`node tools/analisis-riesgos.js\` (${miles(N)} combates o controles simulados por fila y ${miles(N * 5)} pasos por situación). Gramos a ${coma(datos.eurG, 2)} €/g (precio de calle de una variedad del 18 %).`;
  }

  await browser.close();
  if (errores.length) { console.error('errores JS:', errores);process.exit(1); }
  for (const f of fallos) console.log('  FALLO', f);
  console.log(`${fallos.length ? 'el modelo no coincide con el juego' : 'modelo = juego'} (${fallos.length} fallos)`);
  if (!res) {
    let doc = fs.readFileSync(DOC, 'utf8');
    for (const [k, v] of Object.entries(T)) {
      const re = new RegExp(`(<!-- auto:${k} -->)[\\s\\S]*?(<!-- /auto:${k} -->)`);
      if (!re.test(doc)) throw new Error('falta el bloque auto:' + k + ' en docs/ANALISIS.md');
      doc = doc.replace(re, (_, a, b) => a + '\n' + v + '\n' + b);
    }
    fs.writeFileSync(DOC, doc);
    console.log('docs/ANALISIS.md: ' + Object.keys(T).length + ' tablas');
  }
  process.exit(fallos.length ? 1 : 0);
})();
