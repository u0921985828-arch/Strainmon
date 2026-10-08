#!/usr/bin/env node
/*
  Ribera Verde — análisis de riesgos de la calle (docs/ANALISIS.md): ladrones por paso y por trayecto, combate contra
  ladrones, patrullas (sospecha, alarma y huida), control de policía (soborno, hablar, huir, entregar), calor y redada, ventas,
  la Copa y la caja fuerte.
  Las tablas salen de un modelo exacto con las mismas reglas que el código (08-mundo, 10-calle, 13-combate, 09-cultivo,
  11-historia). Cada cifra de las tablas de paso, trayecto, ladrón, policía, ventas y Copa se comprueba jugando el caso con
  las funciones de verdad del juego (onStepEnd, battle + thiefRound + enemyHits, updatePatrullas + updatePlayer, copRound,
  newDay + raidEvent, talkClient, talkInaki, ventaMayor, harvest + addBuds + talkJurado), con la interfaz y las esperas anuladas y
  un Park-Miller fijo: si
  alguna se aparta más de 4 σ, el código ha cambiado y el modelo también tiene que cambiar. Entonces no escribe nada y sale
  con 1. Desde la 1.10 también las zonas (barrio alto y astilleros: onStepEnd y talkClient en cada mapa) y la caja fuerte
  (los trayectos con lo demás dentro de S.caja y la redada con caja, raidEvent).
  Uso:  node tools/build.js && node tools/analisis-riesgos.js [--n 20000] [--reservado f.json]
  Escribe las tablas en docs/ANALISIS.md, entre <!-- auto:clave --> y <!-- /auto:clave -->. Con --reservado solo comprueba
  los casos de ese archivo y no escribe nada. Formato:
    { "paso":    [{ "ch", "heat", "protect", "g", "money", "night", "tall" }],
      "ladron":  [{ "ch", "hp", "hpMax", "rep", "spray", "bocata", "pol": "punio|patada|spray|huir|hablar|optima" }],
      "policia": [{ "ch", "heat", "rep", "g", "money", "night", "protect" }],
      "ruta":    { "de": [x, y], "a": [x, y], "ch", "heat", "protect", "g", "money", "night" } }
    «ch» es obligatorio en cada caso; el resto, opcional.
*/
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : d; };
const N = +arg('--n', 20000), RES = arg('--reservado'), DOC = path.join(ROOT, 'docs/ANALISIS.md');

// ---------- formato ----------
const coma = (x, d) => x.toFixed(d).replace('.', ',');
const miles = n => (n < 0 ? '−' : '') + String(Math.round(Math.abs(n))).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
const pc = (p, d = 1) => p < .0005 && p > 0 ? '< 0,1 %' : coma(p * 100, d) + ' %';
const eur = x => miles(x) + ' €';
const signo = x => (Math.round(x) > 0 ? '+' : Math.round(x) < 0 ? '−' : '±') + coma(Math.abs(x), 0);

// ---------- modelo exacto ----------
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const unif = (a, b) => Array.from({ length: b - a + 1 }, (_, i) => a + i);
// las zonas (1.10, 04-mapas y 10b-patrulla): el ladrón de cada paso se multiplica por lad; el gramo, por precio; pat: agentes
// de patrulla [de día, de noche], desde el capítulo 2
const ZON = { town: { n: 'Ribera Verde (el barrio)', lad: 1, precio: 1, pat: [1, 2] }, alto: { n: 'Barrio alto', lad: .5, precio: 1, pat: [2, 2] },
  astilleros: { n: 'Astilleros', lad: 2, precio: 1.2, pat: [1, 1] },
  // la comarca (1.10): las dos ciudades pequeñas y los dos pueblos, a un autobús
  puerto: { n: 'Puerto Viejo', lad: .6, precio: 1.15, pat: [1, 1] }, valdehierro: { n: 'Valdehierro', lad: 1.4, precio: .9, pat: [1, 1] },
  mendialde: { n: 'Mendialde', lad: .1, precio: 1, pat: [0, 0] }, errotabarri: { n: 'Errotabarri', lad: .1, precio: 1, pat: [0, 0] } };
const Z = e => ZON[e.zona || 'town'];
// un paso por la calle (08-mundo, onStepEnd), desde el capítulo 2: ladrón si Math.random() < pt (con la alarma, nada). La policía
// ya no sale por paso (1.10): patrulla por la calle. Solo cuenta lo que llevas encima: lo de la caja fuerte no
const pLadron = e => e.ch >= 2 && (e.g >= 5 || e.money >= 150) ? .004 * (e.night ? 2.5 : 1) * (e.tall ? 3 : 1) * Z(e).lad : 0;
// el ladrón (13-combate): desde el capítulo 5, 4 de vida más y 1 más de golpe (1.10)
const fuerte = ch => ch >= 5 ? 1 : 0, vidaL = ch => [12 + 2 * ch + 4 * fuerte(ch), 16 + 2 * ch + 4 * fuerte(ch)], golpeL = ch => [2 + (ch >> 2) + fuerte(ch), 4 + (ch >> 1) + fuerte(ch)];
// el soborno (precioSoborno): 40 + 4·calor + 0,5·gramos + 5 % del dinero que llevas encima (1.10)
const soborno = e => Math.round(40 + 4 * e.heat + .5 * e.g + .05 * e.money);
// un trayecto: la probabilidad de cruzarte con un ladrón (después hay 24 pasos de calma: el primero basta)
function trayecto(tiles, e) {
  let sigue = 1, lad = 0;
  for (const t of tiles) { const b = pLadron({ ...e, tall: t.tall }); lad += sigue * b; sigue *= 1 - b; }
  return { lad };
}
// las patrullas (10b-patrulla). Sospecha (0-100) por segundo mientras un agente te ve con algo encima (gramos de flor y de rosin):
// (8 + 0,12 × gramos, hasta 100 g) × 2,5 de noche × (1 + calor/100) × 0,4 con la protección de Molina; sin verte, −10 por
// segundo; vender a vista[0] casillas o menos de él (aunque no mire), +60. Llena: alarma, alto ms quieto («¡alto!») y corre a por ti (corre ms por casilla, más un fotograma: el paso empieza en
// el fotograma siguiente al que acaba). Te pierde si pasan olvida ms sin verte (ve vista[0] × 2 casillas a la redonda) y estás a
// más de pierde casillas, o si cruzas una puerta, una salida o subes al autobús. Te pilla si te paras con él al lado
const PAT = { corre: [210, 180], alto: 600, vista: [5, 5], sube: [1, 2.5], baja: 10, vende: 60, pierde: 10, olvida: 4000, tregua: 30000 };
const ritmo = e => e.g > 0 ? (8 + Math.min(e.g, 100) * .12) * PAT.sube[e.night ? 1 : 0] * (1 + e.heat / 100) * (e.protect ? .4 : 1) : 0;
const alarmaEn = (e, v0 = 0) => ritmo(e) ? (100 - v0) / ritmo(e) : Infinity;   // segundos
// la huida en campo abierto, fotograma a fotograma (60 por segundo): tu paso dura ceil(240 / 16,7) = 15 fotogramas andando y
// ceil(130 / 16,7) = 8 corriendo (el siguiente empieza en el mismo fotograma en que acaba); el suyo, ceil(corre / 16,7) + 1 (el
// siguiente empieza en el fotograma de después), y empieza después de q fotogramas quieto: los que tarda alto en bajar a 0 restando
// un fotograma cada vez, como en updatePatrullas. Los dos pisan la casilla nueva al empezar el paso. Te pierde cuando lleva olvida
// ms sin verte (a más de vista[0] × 2 casillas) y estás a más de pierde; andando, se te pega (a 1 casilla) y te pilla al pararte
const FR = 1000 / 60, fot = ms => Math.ceil(ms / FR - 1e-9);
function huida(noche, d0, corre) {
  const pt = fot(corre ? 130 : 240), pa = fot(PAT.corre[noche ? 1 : 0]) + 1, r = { va: 60 / pa, vt: 60 / pt, escapa: null, alcanza: null };
  let sin = 0, q = 0;for (let es = PAT.alto; es > 0; es -= FR) q++;
  for (let f = 1; f <= 3600; f++) {
    const d = d0 + Math.floor((f - 1) / pt) + 1 - (f > q ? Math.floor((f - 1 - q) / pa) + 1 : 0);
    if (d <= 1 && r.alcanza == null) { r.alcanza = f * FR / 1000;if (!corre) break; }
    if (d <= PAT.vista[0] * 2) sin = 0;else sin += FR;
    if (sin >= PAT.olvida && d > PAT.pierde) { r.escapa = f * FR / 1000;break; }
  }
  return r;
}
// combate contra un ladrón (13-combate): vida del ladrón 12 + 2·cap + 0…4, golpea entre 2 + cap>>2 y 4 + cap>>1 (enteros; desde
// el capítulo 5, +4 de vida y +1 de golpe);
// cada ronda, tu acción y, si sigue en pie y no te has ido, su golpe. pol: punio, patada, spray (mientras quede; luego puño),
// huir, hablar u optima: la que menos veces acaba en KO (a igualdad, la que más gana), con el bocata (+15 de vida, hasta la
// máxima) entre las opciones mientras quede
const ACC = { punio: { p: .92, d: unif(4, 7) }, patada: { p: .65, d: unif(8, 12) }, spray: { p: 1, d: unif(12, 16) } };
function ladron(e) {
  const atk = unif(...golpeL(e.ch)), ph = clamp(.25 + (e.rep || 0) / 300, .25, .7), hpMax = e.hpMax || e.hp;
  const memo = new Map(), tabla = {};
  const suma = (a, b, k) => { if (k) for (const x in b) a[x] = (a[x] || 0) + k * b[x]; return a; };
  // tras tu acción: el ladrón con vida hE (si ≤ 0, ganas) te golpea
  const golpe = (hp, hE, s, b) => {
    if (hE <= 0) return { win: 1 };
    const o = {};for (const d of atk) suma(o, hp - d <= 0 ? { ko: 1 } : V(hp - d, hE, s, b), 1 / atk.length);return o;
  };
  const accion = (a, hp, hE, s, b) => {
    if (a === 'huir') return suma({ huye: .5 }, golpe(hp, hE, s, b), .5);
    if (a === 'hablar') return suma({ habla: ph }, golpe(hp, hE, s, b), 1 - ph);
    if (a === 'bocata') return golpe(Math.min(hpMax, hp + 15), hE, s, b - 1);
    const m = ACC[a], s2 = a === 'spray' ? s - 1 : s, o = m.p < 1 ? suma({}, golpe(hp, hE, s2, b), 1 - m.p) : {};
    for (const d of m.d) suma(o, golpe(hp, hE - d, s2, b), m.p / m.d.length);
    return o;
  };
  function V(hp, hE, s, b) {
    const k = hp + ',' + hE + ',' + s + ',' + b;if (memo.has(k)) return memo.get(k);
    let a = e.pol === 'spray' ? (s > 0 ? 'spray' : 'punio') : e.pol, o;
    if (e.pol === 'optima') {
      let best = null;
      for (const c of ['punio', 'patada', 'spray', 'huir', 'hablar', 'bocata']) {
        if (c === 'spray' && s <= 0 || c === 'bocata' && (b <= 0 || hp >= hpMax)) continue;
        const r = accion(c, hp, hE, s, b), ko = r.ko || 0, bk = best ? best.r.ko || 0 : 0;
        if (!best || ko < bk - 1e-9 || Math.abs(ko - bk) <= 1e-9 && (r.win || 0) > (best.r.win || 0)) best = { c, r };
      }
      a = best.c;o = best.r;tabla[k] = a;
    } else o = accion(a, hp, hE, s, b);
    memo.set(k, o);return o;
  }
  const o = {}, ini = unif(...vidaL(e.ch));
  for (const hE of ini) suma(o, V(e.hp, hE, e.spray || 0, e.bocata || 0), 1 / ini.length);
  for (const x of ['win', 'ko', 'huye', 'habla']) o[x] = o[x] || 0;
  return { ...o, tabla, ini, primera: ini.map(hE => tabla[e.hp + ',' + hE + ',' + (e.spray || 0) + ',' + (e.bocata || 0)]) };
}
// control de policía (13-combate, copRound) con cada opción: probabilidad de requisa, lo que pierdes de media (dinero y
// gramos, estos a eurG €/g) y cuánto cambia el calor de media. Requisa: todos los gramos, −15 de calor y, salvo al
// entregar, multa de hasta 601 € (MULTA_CALLE)
function policia(e, op, eurG) {
  const multa = Math.min(e.money, 601), bajaReq = Math.min(15, e.heat);
  if (op === 'sobornar') {
    const c = soborno(e), q = !e.protect && e.ch >= 3 ? .15 : 0;
    if (e.money < c) return { posible: false, coste: c };
    const hReq = Math.min(100, e.heat - bajaReq + 20) - e.heat;
    return { posible: true, coste: c, pReq: q, m: (1 - q) * c + q * multa, g: q * e.g, eur: (1 - q) * c + q * (multa + e.g * eurG),
      dh: (1 - q) * (Math.max(0, e.heat - 10) - e.heat) + q * hReq };
  }
  const p = op === 'hablar' ? clamp(.3 + e.rep / 250 - e.heat / 300, .1, .85) : op === 'huir' ? .45 + (e.night ? .15 : 0) : 0;
  const mul = op === 'entregar' ? 0 : multa, dhOk = op === 'huir' ? Math.min(100, e.heat + 8) - e.heat : 0;
  return { posible: true, pReq: 1 - p, m: (1 - p) * mul, g: (1 - p) * e.g, eur: (1 - p) * (mul + e.g * eurG), dh: p * dhOk - (1 - p) * bajaReq };
}
const mejorPolicia = (e, eurG) => ['sobornar', 'hablar', 'huir', 'entregar'].map(op => ({ op, ...policia(e, op, eurG) }))
  .filter(r => r.posible).sort((a, b) => a.eur - b.eur)[0];
// la Copa (talkJurado): un lote gana si su THC, redondeado a una décima, pasa de 26,8. THC de una planta (harvest):
// thc·t·(0,85 + 0,15·salud) + luz (F.thc·densidad) + 0,3 con abono, redondeado a una décima; t = 1 + σ·z, entre 0,6 y 1,5,
// redondeado a centésimas
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

// la redada (11-historia, raidEvent): se lleva lo de fuera y una multa (MULTA_REDADA) que se paga de fuera y, si no llega, de la
// caja; la caja la encuentran 1 de cada 4 veces (CAJA_REDADA): sus gramos y la mitad de su dinero. Pérdida media en euros
const MULTA_R = 3000, P_CAJA = .25;
function redada(e, eurG) {
  const k = e.caja || { money: 0, g: 0 }, multa = m => Math.min(MULTA_R, m);
  const no = e.g * eurG + multa(e.money + k.money);
  if (!e.caja) return { eur: no, hallada: 0 };
  const ce = Math.floor(k.money / 2), si = e.g * eurG + k.g * eurG + ce + multa(e.money + k.money - ce);
  return { eur: (1 - P_CAJA) * no + P_CAJA * si, hallada: k.g ? P_CAJA : 0 };
}

// ---------- comprobación con el juego ----------
const tol = (p, n) => 4 * Math.sqrt(Math.max(p * (1 - p), 1e-6) / n) + 1e-9;
const fallos = [];
let comprobadas = 0;
const compara = (que, exacto, mc, n, sd) => {
  const t = sd != null ? 4 * sd / Math.sqrt(n) + 1e-9 : tol(exacto, n);
  const ok = Math.abs(exacto - mc) <= t;comprobadas++;
  if (!ok) fallos.push(`${que}: modelo ${exacto.toFixed(5)}, juego ${mc.toFixed(5)} (±${t.toFixed(5)})`);
  return ok;
};
const exige = (que, ok, det) => { comprobadas++;if (!ok) fallos.push(que + (det != null ? ': ' + JSON.stringify(det) : '')); };

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  const page = await browser.newPage();
  const errores = [];
  page.on('pageerror', e => errores.push(e.message));
  await page.goto('file://' + (process.env.RV_HTML ? path.resolve(process.env.RV_HTML) : path.join(ROOT, 'index.html')));
  await page.waitForFunction(() => typeof mode !== 'undefined' && mode === 'title');
  // el juego, quieto y sin interfaz: las esperas se resuelven en el acto y el azar es un Park-Miller con semilla. ORIG guarda
  // las funciones que alguna prueba sustituye un rato, para devolverlas al acabar
  await page.evaluate(() => {
    mode = 'pausa';S = newState();
    window.ORIG = { battle, thiefRound, queue, menu, ask };
    window.setTimeout = f => { Promise.resolve().then(f); return 0; };
    for (const k of ['say', 'accion', 'checkStory', 'fade', 'talk', 'got']) window[k] = async () => {};
    for (const k of ['sfx', 'toast', 'bhud', 'prompt', 'vfxCombate', 'updateHUD', 'buildEnts', 'heatWarn', 'music', 'save', 'showObjective']) window[k] = () => {};
    window.bAnim = () => 0;
    window.semilla = n => { let s = n % 2147483647;if (s <= 0) s += 2147483646;Math.random = () => (s = s * 16807 % 2147483647) / 2147483647; };
  });
  const juego = (fn, a) => page.evaluate(fn, a);
  const datos = await juego(() => ({ eurG: precioCalle(18), eurMayor: precioMayor(18), pc: [12, 18, 24, 30].map(t => [t, precioCalle(t), precioMayor(t)]),
    multa: MULTA_CALLE, redada: MULTA_REDADA, olor: OLOR, premio: PREMIO_COPA,
    focos: Object.fromEntries(Object.entries(FOCOS).map(([k, F]) => [k, { thc: F.thc, w: F.w }])), W_M2,
    carpas: Object.fromEntries(Object.entries(CARPAS).map(([k, C]) => [k, { cm: C.cm, n: C.plazas }])),
    sigma: Object.fromEntries(Object.entries(GENETICA).map(([k, G]) => [k, G.sigma])),
    mult: Object.fromEntries(Object.entries(CTYPES).map(([k, c]) => [k, c.mult])),
    thc: { tormenta: STRAINS.tormenta.thc, dragon: STRAINS.dragon.thc }, nombres: { tormenta: STRAINS.tormenta.n, dragon: STRAINS.dragon.n } }));
  // el gramo de flor en la calle y al por mayor (10-calle) y el de rosin (1.10): 10 + 0,6 × THC
  const precioC = t => 4 + t * .2, precioM = t => 2 + t * .1, precioR = t => 10 + t * .6;
  for (const [t, a, b] of datos.pc) exige(`precios con THC ${t}`, Math.abs(precioC(t) - a) < 1e-9 && Math.abs(precioM(t) - b) < 1e-9, [a, b]);
  const luzDe = (t, f) => { const C = datos.carpas[t], F = datos.focos[f];return F.thc * Math.min(1, F.w / (C.cm[0] * C.cm[2] / 1e4 * datos.W_M2)); };

  // ---- 1. un paso: onStepEnd de verdad, n veces en una casilla de hierba o de hierba alta ----
  const pasoMC = (e, n) => juego(({ e, n }) => {
    semilla(12345);const r = { police: 0, thief: 0 };
    window.battle = async k => { r[k]++; };
    const z = e.zona || 'town';S = newState();Object.assign(S, { ch: e.ch, heat: e.heat, protect: !!e.protect, money: e.money, map: z, min: e.night ? 23 * 60 : 12 * 60 });
    S.buds = e.g ? { ria: { g: e.g, thc: 12 } } : {};S.flags.darko1 = S.flags.molina1 = true;
    if (e.caja) S.caja = { money: e.caja.money, buds: e.caja.g ? { ria: { g: e.caja.g, thc: 12 } } : {}, nivel: 2 };
    const [x, y] = z === 'town' ? (e.tall ? [8, 19] : [12, 16]) : e.tall ? [3, 5] : CLIENT_TILES[z][0];P.x = x;P.y = y;
    for (let i = 0; i < n; i++) { S.cool = 0;onStepEnd(); }
    window.battle = ORIG.battle;
    return { pol: r.police / n, lad: r.thief / n, alta: MAPS[z].g[y][x] === 'tallgrass' };
  }, { e, n });
  const paso = async (que, e, n) => {
    const mc = await pasoMC(e, n);
    exige(`${que}: la casilla ${e.tall ? 'no es' : 'es'} de hierba alta`, mc.alta === !!e.tall);
    exige(`${que}: ningún control por paso`, mc.pol === 0, mc.pol);compara(`${que} ladrón`, pLadron(e), mc.lad, n);
    return mc;
  };

  // ---- 2. trayectos desde la puerta de casa (sales en 5, 9): el camino más corto (con tileSolid), evitando la hierba alta
  // si da igual. En la casilla de destino no hay encuentro si es una puerta (onStepEnd entra antes); en las demás, sí ----
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
    { k: 'arbusto', n: 'Arbusto de la Acapulco Gold (delante, en 2, 25)', de: [5, 9], a: [2, 25] }]);
  // un trayecto andado con onStepEnd de verdad, casilla a casilla, hasta el primer encuentro (Darko y Molina ya vistos)
  const trayectoMC = (tiles, e, n) => juego(({ tiles, e, n }) => {
    semilla(31337);let pol = 0, lad = 0, k = null;   // pol: controles por paso (tiene que ser 0)
    window.battle = async x => { k = x; };
    for (let i = 0; i < n; i++) {
      S = newState();Object.assign(S, { ch: e.ch, heat: e.heat, protect: !!e.protect, money: e.money, map: 'town', min: e.night ? 23 * 60 : 12 * 60 });
      S.flags.darko1 = S.flags.molina1 = true;S.buds = e.g ? { ria: { g: e.g, thc: 12 } } : {};k = null;
      if (e.caja) S.caja = { money: e.caja.money, buds: e.caja.g ? { ria: { g: e.caja.g, thc: 12 } } : {}, nivel: 2 };
      for (const t of tiles) { P.x = t.x;P.y = t.y;onStepEnd();if (k) break; }
      if (k === 'police') pol++;else if (k === 'thief') lad++;
    }
    window.battle = ORIG.battle;
    return { pol: pol / n, lad: lad / n };
  }, { tiles, e, n });

  // ---- 2 b. patrullas (10b-patrulla): un agente quieto en la plaza, a 3 casillas y mirando al jugador (o de espaldas);
  // updatePatrullas de verdad cada 50 ms hasta la alarma (o hasta que la sospecha baja a 0) ----
  const sospechaJuego = casos => juego(casos => casos.map(e => {
    S = newState();Object.assign(S, { ch: 5, heat: e.heat, protect: !!e.protect, map: 'town', min: e.night ? 23 * 60 : 12 * 60 });
    S.buds = e.g ? { ria: { g: e.g, thc: 12 } } : {};S.rosin = e.rosin ? { ria: { g: e.rosin, thc: 36 } } : {};
    Object.assign(P, { x: 16, y: 17, fx: 16, fy: 17, moving: false });ents = [];resetSosp();ponPatrullas();
    const p = ents.filter(x => x.pat);
    Object.assign(p[0], { x: 16, y: 14, fx: 16, fy: 14, dir: e.espalda ? 'up' : 'down', moving: false, espera: 1e9, caza: false });
    p.slice(1).forEach(o => Object.assign(o, { x: 1, y: 1, fx: 1, fy: 1, moving: false, espera: 1e9 }));
    if (e.vende) vistoVender();
    if (e.v0) SOSP.v = e.v0;
    const v1 = SOSP.v;let t = 0;
    if (e.baja) while (SOSP.v > 0 && t < 6e5) { updatePatrullas(50);t += 50; }
    else while (!SOSP.alarma && t < 6e5) { updatePatrullas(50);t += 50; }
    const r = { t: t / 1000, v1, n: p.length };ents = [];resetSosp();return r;
  }), casos);
  // la huida, en una pista recta de 80 × 3 casillas de acera: el agente detrás, a d0 casillas, con la alarma; el jugador hacia la
  // derecha con la cruceta (y B si corre). updatePlayer y updatePatrullas de verdad, 60 fotogramas por segundo, hasta que te
  // pierde (o max s; andando, antes de llegar al final de la pista, a los 17 s). Con «para», a los max s suelta la cruceta: ¿te pilla?
  const huidaJuego = casos => juego(async casos => { const out = [];for (const e of casos) {
    const W = 80, fila = v => Array(W).fill(v);
    MAPS.__pista = { w: W, h: 3, g: [fila('walk'), fila('walk'), fila('walk')], o: [fila(null), fila(null), fila(null)], doors: {}, exits: {} };
    ZONAS.__pista = { n: 'pista', lad: 0, precio: 1 };PATRULLAS.__pista = [1, 1];RONDA.__pista = [[0, 1]];
    S = newState();Object.assign(S, { ch: 5, map: '__pista', min: e.night ? 23 * 60 : 12 * 60, money: 0, heat: 0 });S.buds = { ria: { g: 1, thc: 12 } };
    const b0 = battle;let pill = false;window.battle = async () => { pill = true; };
    mode = 'world';ents = [];resetSosp();
    Object.assign(P, { x: 10, y: 1, fx: 10, fy: 1, px: 160, py: 16, dir: 'right', moving: false, chain: false, hold: 0 });
    ponPatrullas();const a = ents.find(x => x.pat);Object.assign(a, { x: 10 - e.d0, y: 1, fx: 10 - e.d0, fy: 1, px: (10 - e.d0) * 16, py: 16, dir: 'right', moving: false });
    alarma(a);held.B = !!e.corre;dirOrder.length = 0;dirOrder.push('right');
    const dt = 1000 / 60;let t = 0, pegado = null;
    while (t < e.max * 1000 && SOSP.alarma && !pill) {
      updatePlayer(dt);if (isFree()) updatePatrullas(dt);t += dt;
      if (pegado === null && Math.abs(a.x - P.x) + Math.abs(a.y - P.y) <= 1) pegado = t / 1000;
    }
    const sigue = !!SOSP.alarma;
    if (e.para && SOSP.alarma) { dirOrder.length = 0;for (let k = 0; k < 120 && !pill; k++) { updatePlayer(dt);if (isFree()) updatePatrullas(dt); } }
    const r = { t: t / 1000, sigue, pegado, pill, d: Math.abs(a.x - P.x) };
    held.B = false;dirOrder.length = 0;mode = 'pausa';ents = [];resetSosp();S.map = 'town';
    for (let k = 0; k < 10; k++) await null;   // que acabe el run() del control (pillado) y suelte el lock
    window.battle = b0;delete MAPS.__pista;delete ZONAS.__pista;delete PATRULLAS.__pista;delete RONDA.__pista;
    out.push(r);
  } return out; }, casos);

  // ---- 3. combate contra un ladrón: battle('thief') de verdad (crea al ladrón, thiefRound, enemyHits y el KO) con una
  // política fija o la tabla de la óptima. Comprueba también la vida y el golpe del ladrón y lo que te quita un KO ----
  const ladronMC = (e, tabla, n) => juego(({ e, tabla, n }) => {
    semilla(777);const r = { win: 0, ko: 0, flee: 0, talk: 0 }, chk = { koMal: 0, vidas: {}, golpes: {} };let res = null;
    window.thiefRound = async () => { const x = await ORIG.thiefRound();if (x) res = x;return x; };
    return (async () => {
      for (let i = 0; i < n; i++) {
        S = newState();Object.assign(S, { ch: e.ch, hp: e.hp, hpMax: e.hpMax || e.hp, rep: e.rep || 0, money: 1000, map: 'town', min: 12 * 60 });
        S.items.spray = e.spray || 0;S.items.bocata = e.bocata || 0;S.buds = { ria: { g: 100, thc: 12 } };
        const quiere = () => e.pol === 'optima' ? tabla[S.hp + ',' + B.hp + ',' + S.items.spray + ',' + S.items.bocata] : e.pol === 'spray' ? (S.items.spray > 0 ? 'spray' : 'punio') : e.pol;
        let primero = true;
        window.menu = async items => {
          if (primero) { primero = false;chk.vidas[B.hpMax] = (chk.vidas[B.hpMax] || 0) + 1;chk.golpes[B.atk.join('-')] = 1; }
          const a = quiere(), l = items.map(x => typeof x === 'string' ? x : x.label);
          if (l[0] === 'LUCHAR') return a === 'spray' || a === 'bocata' ? 1 : a === 'hablar' ? 2 : a === 'huir' ? 3 : 0;
          if (l[0] === 'PUÑETAZO') return a === 'patada' ? 1 : 0;
          return a === 'bocata' ? 1 : 0;   // mochila: el spray o el bocata
        };
        res = null;await ORIG.battle('thief');
        r[res]++;
        if (res === 'ko' && (!S.buds.ria || Math.abs(S.buds.ria.g - 50) > 1e-9 || S.money !== 700)) chk.koMal++;
      }
      window.thiefRound = ORIG.thiefRound;window.menu = ORIG.menu;mode = 'pausa';
      return { win: r.win / n, ko: r.ko / n, huye: r.flee / n, habla: r.talk / n, ...chk };
    })();
  }, { e, tabla, n });
  const pelea = async (que, e, n) => {
    const x = ladron(e), mc = await ladronMC(e, x.tabla, n);
    for (const k of ['win', 'ko', 'huye', 'habla']) compara(`${que} ${k}`, x[k], mc[k], n);
    const vidas = Object.keys(mc.vidas).map(Number).sort((a, b) => a - b);
    exige(`${que}: vida del ladrón entre ${x.ini[0]} y ${x.ini[x.ini.length - 1]}`, vidas[0] === x.ini[0] && vidas[vidas.length - 1] === x.ini[x.ini.length - 1] && vidas.length === x.ini.length, vidas);
    exige(`${que}: golpe del ladrón`, Object.keys(mc.golpes).join() === golpeL(e.ch).join('-'), mc.golpes);
    exige(`${que}: un KO quita la mitad de los gramos y el 30 % del dinero`, mc.koMal === 0, mc.koMal);
    return { x, mc };
  };

  // ---- 4. control de policía: copRound de verdad con cada opción (soborno aceptado) ----
  const policiaMC = (e, op, n) => juego(({ e, op, n }) => {
    semilla(4242);let req = 0, m = 0, g = 0, m2 = 0, h = 0, h2 = 0;
    window.menu = async () => ['sobornar', 'hablar', 'huir', 'entregar'].indexOf(op);
    window.ask = async () => 0;
    return (async () => {
      for (let i = 0; i < n; i++) {
        S = newState();Object.assign(S, { ch: e.ch, heat: e.heat, rep: e.rep, money: e.money, protect: !!e.protect, min: e.night ? 23 * 60 : 12 * 60 });
        S.buds = { ria: { g: e.g, thc: 12 } };B = { kind: 'police', name: 'AGENTE' };
        const r = await copRound();
        const dm = e.money - S.money, dh = S.heat - e.heat;
        if (r === 'caught') req++;m += dm;m2 += dm * dm;g += e.g - totalBuds();h += dh;h2 += dh * dh;
      }
      window.menu = ORIG.menu;window.ask = ORIG.ask;
      return { pReq: req / n, m: m / n, sdm: Math.sqrt(Math.max(0, m2 / n - (m / n) ** 2)), g: g / n, h: h / n, sdh: Math.sqrt(Math.max(0, h2 / n - (h / n) ** 2)) };
    })();
  }, { e, op, n });
  const control = async (que, e, op, n) => {
    const x = policia(e, op, datos.eurG);if (!x.posible) return { x };
    const mc = await policiaMC(e, op, n);
    compara(`${que} ${op} requisa`, x.pReq, mc.pReq, n);compara(`${que} ${op} dinero`, x.m, mc.m, n, mc.sdm);
    compara(`${que} ${op} gramos`, x.g, mc.g, n, e.g * Math.sqrt(x.pReq * (1 - x.pReq)));compara(`${que} ${op} calor`, x.dh, mc.h, n, mc.sdh);
    return { x, mc };
  };

  // ---- 5. calor: newDay de verdad (bajada diaria, olor) y, si la encola, la redada (raidEvent) ----
  const dia = await juego(() => (async () => {
    const r = [];
    for (const [heat, protect, flor] of [[90, false, 0], [89.9, false, 0], [100, true, 0], [40, false, 2]]) {
      S = newState();Object.assign(S, { ch: 5, heat, protect, map: 'home', money: 5000 });S.buds = { ria: { g: 100, thc: 12 } };
      if (flor) { S.carpas = [{ t: 'p60', foco: 'cfl' }, { t: 'm100', foco: 'cfl' }];S.macetas = Array(6).fill('plastico7');S.pots = Array(6).fill(null);
        S.pots[0] = { sid: 'ria', prog: .8, water: 70, health: 100 };S.pots[2] = { sid: 'ria', prog: .8, water: 70, health: 100 }; }
      else S.pots = [{ sid: 'ria', prog: .3, water: 70, health: 100 }, null];
      const q = [];window.queue = (k, fn) => q.push([k, fn]);
      newDay();const antes = { heat: S.heat, money: S.money }, raid = q.find(x => x[0] === 'raid');
      if (raid) await raid[1]();
      r.push({ heat, protect, flor, redada: !!raid, despues: antes.heat, final: S.heat, plantas: S.pots.filter(Boolean).length, g: totalBuds(), multa: antes.money - S.money, dinero: antes.money });
    }
    window.queue = ORIG.queue;
    return r;
  })());
  // una venta en la calle (talkClient) con un cliente fijo: precio, si acepta y cuánto calor sube
  const ventaMC = (c, j, n) => juego(({ c, j, n }) => {
    semilla(99);let ok = 0, dh = 0, lad = 0;const cobro = {};
    window.menu = async () => 0;window.ask = async () => j;window.battle = async () => { lad++; };
    return (async () => {
      for (let i = 0; i < n; i++) {
        const z = c.zona || 'town';S = newState();Object.assign(S, { ch: c.ch, heat: 10, map: z });S.buds = { ria: { g: 50, thc: c.thc } };
        if (c.type === 'ext') { S.buds = {};S.rosin = { ria: { g: 50, thc: c.thc } }; }   // el catador solo compra rosin
        const cl = { id: 'c', map: z, type: c.type, want: c.want, minThc: c.minThc };S.clients = [cl];
        await talkClient(cl);
        if (S.money > 150) { ok++;dh += S.heat - 10;cobro[S.money - 150] = 1; }
      }
      window.menu = ORIG.menu;window.ask = ORIG.ask;window.battle = ORIG.battle;
      return { acepta: ok / n, calor: ok ? dh / ok : 0, cobro: Object.keys(cobro).map(Number), lad: ok ? lad / ok : 0, ok };
    })();
  }, { c, j, n });
  // Iñaki (10 g) y al por mayor (1 kg): talkInaki y ventaMayor de verdad, una vez cada una
  const iñaki = await juego(() => (async () => {
    const r = {};window.menu = async () => 0;
    S = newState();Object.assign(S, { ch: 2, heat: 10, map: 'town' });S.buds = { ria: { g: 50, thc: 18 } };window.ask = async () => 0;
    await talkInaki();r.inaki = { e: S.money - 150, h: S.heat - 10, g: 50 - totalBuds() };
    S = newState();Object.assign(S, { ch: 3, heat: 10, map: 'town' });S.buds = { ria: { g: 5000, thc: 18 } };
    window.ask = async (t, ops) => ops.findIndex(o => /^1 kg/.test(o));
    await ventaMayor('IÑAKI');r.mayor = { e: S.money - 150, h: S.heat - 10, g: 5000 - totalBuds() };
    S = newState();Object.assign(S, { ch: 8, heat: 10, map: 'almacen', min: 22 * 60, encargo: { g: ENCARGO[1], hasta: 99 } });S.buds = { ria: { g: 5000, thc: 18 } };window.ask = async () => 0;
    await talkTonoAlmacen();r.encargo = { e: S.money - 150, h: S.heat - 10, g: 5000 - totalBuds(), fin: S.encargo === null };
    window.menu = ORIG.menu;window.ask = ORIG.ask;
    return r;
  })());

  // la redada con la caja fuerte (1.10): raidEvent de verdad, n veces; lo que se pierde (dinero y gramos a eurG €/g, sin las
  // plantas, que se pierden igual) y cuántas veces encuentran la caja
  const redadaMC = (e, n) => juego(({ e, n }) => {
    semilla(555);let hall = 0, p = 0, p2 = 0;
    return (async () => {
      for (let i = 0; i < n; i++) {
        S = newState();Object.assign(S, { ch: 5, heat: 95, protect: false, map: 'home', money: e.money });S.buds = e.g ? { ria: { g: e.g, thc: 12 } } : {};
        S.caja = e.caja ? { money: e.caja.money, buds: e.caja.g ? { ria: { g: e.caja.g, thc: 12 } } : {}, nivel: 2 } : null;
        const m0 = S.money + cajaE(), g0 = totalBuds() + cajaG();await raidEvent();
        const x = m0 - S.money - cajaE() + (g0 - totalBuds() - cajaG()) * e.eurG;p += x;p2 += x * x;if (e.caja && e.caja.g && !cajaG()) hall++;
      }
      return { eur: p / n, sd: Math.sqrt(Math.max(0, p2 / n - (p / n) ** 2)), hallada: hall / n };
    })();
  }, { e, n });
  // las zonas y la caja de verdad: ZONAS, CAJA y las constantes de la caja (11b-caja)
  const zc = await juego(() => ({ ZONAS, PATRULLAS, PAT, ROSIN, CAJA, CAJA_P, CAJA_REDADA, CAJA_ANIO, MAITE_CAJA, ENCARGO, PAGO_ENCARGO, CUOTA_DIAS,
    rosin: [36, 54, 75].map(t => [t, precioRosin(t)]) }));

  // ---- 6. la Copa: harvest de verdad (fenotipo con rollFeno) de la carpa llena; los lotes se juntan con addBuds, como en el
  // juego (una variedad = un lote, con el THC medio por gramos; lo de un fenotipo estrella, aparte), y cada lote de 20 g o
  // más va al jurado (talkJurado) hasta que gana uno. Con las 2 primeras plantas (las 2 semillas de una tanda de cruces) y
  // con la carpa llena ----
  const copaMC = (e, n) => juego(({ e, n }) => {
    semilla(2026);let pasa = 0, plantas = 0, gana2 = 0, ganaN = 0, gramos = 0, premioMal = 0;
    const jurado = async cos => {
      S.buds = {};for (const [k, g, thc] of cos) addBuds(k, g, thc);S.ch = 6;S.money = 0;S.debt = 15000;
      for (const [k] of budLots(20)) {
        if (!S.buds[k] || S.buds[k].g < 20) continue;
        window.menu = async items => items.findIndex(it => it.label === lotNombre(k));
        await talkJurado();
        if (S.ch === 7) { if (S.money !== PREMIO_COPA) premioMal++;return true; }
      }
      return false;
    };
    return (async () => {
      for (let i = 0; i < n; i++) {
        S = newState();S.ch = 6;S.carpas = [{ t: e.carpa, foco: e.foco }];const h = CARPAS[e.carpa].plazas;
        S.macetas = Array(h).fill(e.maceta);S.pots = Array(h).fill(null);S.gen = { [e.sid]: e.gen };
        for (let j = 0; j < h; j++) S.pots[j] = { sid: e.sid, prog: 1, water: 70, health: 100, fert: e.abono, pest: false, f: rollFeno(e.sid) };
        const cos = [];
        for (let j = 0; j < h; j++) { S.buds = {};await harvest(j);const [k, b] = Object.entries(S.buds)[0];cos.push([k, b.g, b.thc]);
          plantas++;gramos += b.g;if (Math.round(b.thc * 10) / 10 > 26.8) pasa++; }
        if (await jurado(cos.slice(0, 2))) gana2++;
        if (await jurado(cos)) ganaN++;
      }
      window.menu = ORIG.menu;
      return { p: pasa / plantas, plantas, gana2: gana2 / n, ganaN: ganaN / n, g: gramos / plantas, premioMal };
    })();
  }, { e, n });

  const T = {};   // las tablas del documento
  const res = RES ? JSON.parse(fs.readFileSync(RES, 'utf8')) : null;

  if (res) {
    // sin capítulo no hay encuentros (desde el 2): un caso sin «ch» no comprobaría nada
    for (const e of [...(res.paso || []), ...(res.ladron || []), ...(res.policia || []), ...(res.ruta ? [res.ruta] : [])])
      if (!(e.ch >= 1)) throw new Error('caso reservado sin «ch»: ' + JSON.stringify(e));
    // ---------- caso reservado: solo comprobar ----------
    for (const e of res.paso || []) { const mc = await paso('reservado paso', e, N * 5);console.log(`paso: ladrón modelo ${pc(pLadron(e), 2)} · juego ${pc(mc.lad, 2)} (controles por paso: ${mc.pol})`); }
    for (const e of res.ladron || []) { const { x, mc } = await pelea(`reservado ladrón ${e.pol}`, e, N);
      console.log(`ladrón ${e.pol}: modelo KO ${pc(x.ko)} gana ${pc(x.win)} · juego KO ${pc(mc.ko)} gana ${pc(mc.win)}`); }
    for (const e of res.policia || []) for (const op of ['sobornar', 'hablar', 'huir', 'entregar']) {
      const { x, mc } = await control('reservado policía', e, op, N);if (!mc) continue;
      console.log(`policía ${op}: modelo requisa ${pc(x.pReq)}, −${coma(x.m, 1)} €, calor ${coma(x.dh, 2)} · juego ${pc(mc.pReq)}, −${coma(mc.m, 1)} €, ${coma(mc.h, 2)}`); }
    if (res.ruta) {
      const [ru] = await rutasDe([{ k: 'reservada', de: res.ruta.de, a: res.ruta.a }]), er = res.ruta, xr = trayecto(ru.tiles, er), mr = await trayectoMC(ru.tiles, er, N);
      exige('reservado ruta: ningún control por paso', mr.pol === 0, mr.pol);compara('reservado ruta ladrón', xr.lad, mr.lad, N);
      console.log(`ruta reservada (${ru.tiles.length} pasos, ${ru.tiles.filter(t => t.tall).length} en hierba alta): ladrón modelo ${pc(xr.lad)} · juego ${pc(mr.lad)}`);
    }
  } else {
    // ---------- 1. por paso ----------
    const PASOS = [
      { n: 'Sin nada (0 g, < 150 €)', ch: 3, heat: 0, g: 0, money: 100 },
      { n: 'Solo dinero (0 g, ≥ 150 €), de día', ch: 3, heat: 0, g: 0, money: 2000 },
      { n: 'Con gramos, de día', ch: 3, heat: 0, g: 50, money: 2000 },
      { n: 'Con gramos, calor 89 y la protección de Molina, de día (el calor ya no cuenta)', ch: 5, heat: 89, protect: true, g: 50, money: 2000 },
      { n: 'Con gramos, de noche', ch: 3, heat: 50, g: 50, money: 2000, night: true },
      { n: 'Con gramos, de noche en hierba alta', ch: 3, heat: 50, g: 50, money: 2000, night: true, tall: true }];
    const filas = [];
    for (const e of PASOS) {
      const b = pLadron(e), mc = await paso(`paso «${e.n}»`, e, N * 5);
      filas.push(`| ${e.n} | ${pc(b, 2)} | ${b ? miles(1 / b) : '—'} | ${pc(mc.lad, 2)} |`);
    }
    T.paso = ['| Situación | Ladrón por paso | Pasos de media hasta un ladrón | Juego (simulado) |', '|---|---|---|---|', ...filas].join('\n');
    // ---------- 1 b. por zona (1.10): las mismas reglas × lad de cada zona, andadas en cada mapa; y sus patrullas ----------
    for (const z in ZON) exige(`zona ${z}`, ['lad', 'precio'].every(k => zc.ZONAS[z] && zc.ZONAS[z][k] === ZON[z][k]) && zc.PATRULLAS[z].join() === ZON[z].pat.join(),
      [zc.ZONAS[z], zc.PATRULLAS[z]]);
    exige('zonas: las siete', Object.keys(zc.ZONAS).join() === Object.keys(ZON).join(), Object.keys(zc.ZONAS));
    const SZ = [{ n: 'Con gramos, de día', ch: 5, heat: 50, g: 50, money: 2000 }, { n: 'Con gramos, de noche', ch: 5, heat: 50, g: 50, money: 2000, night: true },
      { n: 'Solo dinero (0 g, ≥ 150 €), de noche', ch: 5, heat: 50, g: 0, money: 2000, night: true }];
    const filasZ = [];
    for (const e of SZ) {
      const celdas = [];
      for (const z in ZON) { const ez = { ...e, zona: z };await paso(`paso «${e.n}» en ${z}`, ez, N * 5);celdas.push(pc(pLadron(ez), 2)); }
      filasZ.push(`| Ladrón por paso: ${e.n.charAt(0).toLowerCase() + e.n.slice(1)} | ${celdas.join(' | ')} |`);
    }
    T.zonas = ['| Cap. 5 | ' + Object.values(ZON).map(z => z.n).join(' | ') + ' |', '|---|' + Object.keys(ZON).map(() => '---|').join(''), ...filasZ,
      '| Agentes de patrulla (de día / de noche) | ' + Object.values(ZON).map(z => z.pat.join(' / ')).join(' | ') + ' |',
      '| Precio del gramo en la calle | ' + Object.values(ZON).map(z => '×' + String(z.precio).replace('.', ',')).join(' | ') + ' |'].join('\n');

    // ---------- 2. por trayecto (todas las celdas, andadas también en el juego) ----------
    const ESC = [
      { n: 'de día', ch: 3, heat: 30, g: 50, money: 2000 },
      { n: 'de noche', ch: 5, heat: 80, g: 50, money: 2000, night: true },
      { n: 'de noche, sin gramos y con menos de 150 €', ch: 5, heat: 80, g: 0, money: 100, night: true }];
    const filasR = [];
    for (const r of rutas) {
      const celdas = [];
      for (const e of ESC) { const x = trayecto(r.tiles, e), mc = await trayectoMC(r.tiles, e, N);
        exige(`trayecto ${r.k} (${e.n}): ningún control por paso`, mc.pol === 0, mc.pol);compara(`trayecto ${r.k} (${e.n}) ladrón`, x.lad, mc.lad, N);
        celdas.push(pc(x.lad)); }
      filasR.push(`| ${r.n} | ${r.tiles.length} | ${r.tiles.filter(t => t.tall).length} | ${celdas.join(' | ')} |`);
    }
    T.rutas = ['| Ida desde casa | Pasos | En hierba alta | ' + ESC.map(e => `Ladrón (${e.n})`).join(' | ') + ' |',
      '|---|---|---|' + ESC.map(() => '---|').join(''), ...filasR].join('\n');

    // ---------- 2 b. patrullas: sospecha hasta la alarma y la huida ----------
    exige('patrullas: las constantes de 10b-patrulla', ['corre', 'vista', 'sube'].every(k => zc.PAT[k].join() === PAT[k].join()) && ['alto', 'baja', 'vende', 'pierde', 'olvida', 'tregua'].every(k => zc.PAT[k] === PAT[k]), zc.PAT);
    const SOS = [
      { n: '10 g, calor 0, de día', g: 10, heat: 0 }, { n: '50 g, calor 0, de día', g: 50, heat: 0 }, { n: '100 g o más, calor 0, de día', g: 100, heat: 0 },
      { n: '50 g, calor 50, de día', g: 50, heat: 50 }, { n: '50 g, calor 50, con la protección de Molina', g: 50, heat: 50, protect: true },
      { n: '50 g, calor 0, de noche', g: 50, heat: 0, night: true }, { n: '100 g o más, calor 80, de noche', g: 100, heat: 80, night: true },
      { n: '2 g de rosin (salen de 10 g de flor), calor 0, de día', g: 2, rosin: 2, heat: 0 },
      { n: 'Justo después de venderle 8 g a un cliente con un agente cerca (50 g, calor 0, de día)', g: 50, heat: 0, vende: true },
      { n: 'Sin nada encima', g: 0, heat: 50 }];
    const sj = await sospechaJuego(SOS.filter(e => e.g > 0).map(e => ({ ...e, g: e.rosin ? 0 : e.g })).concat([{ g: 50, heat: 0, espalda: true, v0: 99, baja: true }]));
    const filasS = [];let k = 0;
    for (const e of SOS) {
      if (!e.g) { filasS.push(`| ${e.n} | 0 | nunca | nunca |`);continue; }
      const v0 = e.vende ? PAT.vende : 0, x = alarmaEn(e, v0), mc = sj[k++];
      exige(`sospecha «${e.n}»: alarma en ${coma(x, 2)} s (juego ${coma(mc.t, 2)} s)`, Math.abs(mc.t - x) <= .05 + 1e-9 && Math.abs(mc.v1 - v0) < 1e-9, mc);
      filasS.push(`| ${e.n} | ${coma(ritmo(e), 1)} | ${coma(x, 1)} s | ${coma(mc.t, 2)} s |`);
    }
    const bj = sj[k];exige(`sospecha: de 99 a 0 sin verte en ${coma(99 / PAT.baja, 1)} s`, Math.abs(bj.t - 99 / PAT.baja) <= .05 + 1e-9, bj);
    T.patrullas = ['| Te ve un agente con… | Sospecha por segundo | Hasta la alarma (de 0 a 100) | Juego (updatePatrullas cada 50 ms) |', '|---|---|---|---|', ...filasS].join('\n');
    const HU = [{ noche: false, corre: true }, { noche: true, corre: true }, { noche: false, corre: false }, { noche: true, corre: false }];
    const hj = await huidaJuego(HU.map(h => ({ night: h.noche, corre: h.corre, d0: 3, max: h.corre ? 12 : 15, para: !h.corre })));
    const filasH = HU.map((h, i) => {
      const x = huida(h.noche, 3, h.corre), mc = hj[i], q = `huida ${h.noche ? 'de noche' : 'de día'} ${h.corre ? 'corriendo' : 'andando'}`;
      const fila = (fin, juego) => `| ${h.noche ? 'De noche' : 'De día'} · ${h.corre ? 'corriendo (B)' : 'andando'} | ${coma(x.va, 2)} | ${coma(x.vt, 2)} | ${fin} | ${juego} |`;
      if (h.corre) {
        exige(`${q}: te pierde a los ${x.escapa} s (juego ${mc.t} s)`, x.escapa != null && !mc.sigue && !mc.pill && Math.abs(mc.t - x.escapa) < 1e-6, mc);
        return fila(`te pierde a los ${coma(x.escapa, 2)} s`, `${coma(mc.t, 2)} s`);
      }
      exige(`${q}: se te pega a los ${x.alcanza} s (juego ${mc.pegado} s), no te pierde y, si te paras, te pilla`, mc.sigue && mc.pill && mc.pegado != null && Math.abs(mc.pegado - x.alcanza) < 1e-6, mc);
      return fila(`se te pega a los ${coma(x.alcanza, 2)} s y no te suelta; si te paras, te pilla`, `${coma(mc.pegado, 2)} s · pillado al pararte`);
    });
    T.huida = ['| Con la alarma, desde 3 casillas, en campo abierto | Él (casillas/s) | Tú (casillas/s) | Modelo | Juego (updatePlayer y updatePatrullas, 60 fotogramas/s) |', '|---|---|---|---|---|', ...filasH].join('\n');

    // ---------- 3. ladrón: probabilidad de KO por estrategia (todas las celdas, peleadas también en el juego) ----------
    const FILAS = [[2, 30], [5, 30], [5, 40], [8, 30], [8, 40], [8, 60]];
    const COLS = [
      { pol: 'punio', n: 'Puñetazo' }, { pol: 'patada', n: 'Patada' }, { pol: 'spray', n: '2 sprays, luego puñetazo', e: { spray: 2 } },
      { pol: 'huir', n: 'Huir' }, { pol: 'hablar', n: 'Hablar (rep. 0)' }, { pol: 'hablar', n: 'Hablar (rep. 60)', e: { rep: 60 } },
      { pol: 'optima', n: 'La mejor, sin spray ni bocata' }, { pol: 'optima', n: 'La mejor, con 2 sprays y 1 bocata', e: { spray: 2, bocata: 1 } }];
    const filasL = [];
    for (const [ch, hp] of FILAS) {
      const celdas = [];
      for (const c of COLS) { const { x } = await pelea(`ladrón cap ${ch} vida ${hp} ${c.n}`, { ch, hp, rep: 0, ...c.e, pol: c.pol }, N);celdas.push(pc(x.ko)); }
      filasL.push(`| ${ch} | ${vidaL(ch).join('-')} · ${golpeL(ch).join('-')} | ${hp} | ${celdas.join(' | ')} |`);
    }
    T.ladron = ['| Cap. | Ladrón: vida · golpe | Tu vida | ' + COLS.map(c => c.n).join(' | ') + ' |', '|---|---|---|' + COLS.map(() => '---|').join(''), ...filasL].join('\n');
    const ACN = { punio: 'puñetazo', patada: 'patada', spray: 'spray', huir: 'huir', hablar: 'hablar', bocata: 'bocata' };
    const primera = (ch, hp, ex, txt) => {
      const o = ladron({ ch, hp, rep: 0, ...ex, pol: 'optima' }), g = [];
      o.primera.forEach((a, i) => { const v = o.ini[i], u = g[g.length - 1];if (u && u.a === a) u.b = v;else g.push({ a, d: v, b: v }); });
      return `- ${txt}: ${g.map(u => `${ACN[u.a]} si el ladrón tiene ${u.d === u.b ? u.d : u.d + '-' + u.b} de vida`).join('; ')} (KO ${pc(o.ko)}).`;
    };
    T.optima = ['Primera acción de «la mejor» (la que menos veces acaba en KO):',
      primera(8, 30, {}, 'Cap. 8, 30 de vida, sin spray ni bocata'), primera(8, 40, {}, 'Cap. 8, 40 de vida, sin spray ni bocata'),
      primera(8, 30, { spray: 2, bocata: 1 }, 'Cap. 8, 30 de vida, con 2 sprays y 1 bocata'), primera(5, 30, {}, 'Cap. 5, 30 de vida, sin spray ni bocata')].join('\n');

    // ---------- 4. policía ----------
    const ESP = [
      { n: 'Cap. 2 · calor 20 · rep. 10 · 30 g · 300 €', ch: 2, heat: 20, rep: 10, g: 30, money: 300 },
      { n: 'Cap. 3 · calor 0 · rep. 150 · 5 g · 300 €', ch: 3, heat: 0, rep: 150, g: 5, money: 300 },
      { n: 'Cap. 3 · calor 85 · rep. 0 · 10 g · 450 €', ch: 3, heat: 85, rep: 0, g: 10, money: 450 },
      { n: 'Cap. 4 · calor 50 · rep. 40 · 40 g · 300 €', ch: 4, heat: 50, rep: 40, g: 40, money: 300 },
      { n: 'Cap. 4 · calor 60 · rep. 40 · 200 g · 2.000 € · noche', ch: 4, heat: 60, rep: 40, g: 200, money: 2000, night: true },
      { n: 'Cap. 5 · calor 85 · rep. 60 · 600 g · 8.000 €', ch: 5, heat: 85, rep: 60, g: 600, money: 8000 },
      { n: 'Cap. 5 · igual, con protección', ch: 5, heat: 85, rep: 60, g: 600, money: 8000, protect: true },
      { n: 'Cap. 8 · calor 50 · rep. 150 · 3.000 g · 40.000 €', ch: 8, heat: 50, rep: 150, g: 3000, money: 40000 }];
    const OPS = { sobornar: 'Sobornar', hablar: 'Hablar', huir: 'Huir', entregar: 'Entregar' }, filasP = [];
    for (const e of ESP) {
      const celdas = [];
      for (const op of Object.keys(OPS)) {
        const { x } = await control(`policía «${e.n}»`, e, op, N);
        if (!x.posible) { celdas.push(`no llega (${eur(x.coste)})`);continue; }
        celdas.push(`${op === 'sobornar' ? eur(x.coste) + ' · ' : ''}requisa ${pc(x.pReq, 0)} · −${eur(x.eur)} · calor ${signo(x.dh)}`);
      }
      filasP.push(`| ${e.n} | ${celdas.join(' | ')} | ${OPS[mejorPolicia(e, datos.eurG).op]} |`);
    }
    T.policia = ['| Situación | Sobornar | Hablar | Huir | Entregar | Mejor (en euros) |', '|---|---|---|---|---|---|', ...filasP].join('\n');
    // a partir de cuántos gramos sobornar sale mejor que entregar, según el dinero que llevas encima (el 5 % entra en el
    // precio) y con calor 50; si el soborno ya no te llega, «no llega»
    const umbral = (ch, money, protect) => { for (let g = 1; g <= 20000; g++) { const e = { ch, heat: 50, rep: 0, g, money, protect };
      if (soborno(e) > money) return 'no llega'; if (policia(e, 'entregar', datos.eurG).eur >= policia(e, 'sobornar', datos.eurG).eur) return miles(g) + ' g'; } return '—'; };
    T.umbral = ['| Dinero encima (calor 50) | Cap. 2 | Cap. 3 en adelante, sin protección | Con protección |', '|---|---|---|---|',
      ...[300, 2000, 10000, 40000].map(m => `| ${eur(m)} | ${umbral(2, m, false)} | ${umbral(3, m, false)} | ${umbral(5, m, true)} |`)].join('\n');

    // ---------- 5. calor y ventas ----------
    const d = dia;
    exige('newDay: la redada salta con calor 90 y no con 89,9', d[0].redada && !d[1].redada, d.map(x => x.redada));
    exige('newDay: −12 al día', Math.abs(d[0].despues - 78) < 1e-9 && Math.abs(d[1].despues - 77.9) < 1e-9, [d[0].despues, d[1].despues]);
    exige('redada sin protección: plantas, gramos, multa y calor 30', d[0].plantas === 0 && d[0].g === 0 && d[0].multa === Math.min(d[0].dinero, datos.redada) && d[0].final === 30, d[0]);
    exige('con protección: −20 al día y la redada se para con calor 50, sin quitar nada', d[2].redada && Math.abs(d[2].despues - 80) < 1e-9 && d[2].final === 50 && d[2].plantas === 1 && d[2].g === 100 && d[2].multa === 0, d[2]);
    exige('dos carpas en flor sin filtro', Math.abs(d[3].despues - (40 - 12 + 2 * datos.olor)) < 1e-9, d[3]);
    const VENTAS = [
      { n: 'Calle · currela, 8 g a precio justo', c: { ch: 4, type: 'cur', want: 8, minThc: 0, thc: 18 }, j: 1, acc: .92 },
      { n: 'Calle · pijo del cap. 6 (pide 21 % de THC), 12 g de THC 24 a precio caro', c: { ch: 6, type: 'pij', want: 12, minThc: 21, thc: 24 }, j: 2, acc: clamp(.3 + (24 - 21) * .05 + .25, .1, .9) },
      { n: 'Astilleros · currela, 8 g a precio justo (1 de cada 3 ventas, un chico de Darko)', c: { ch: 4, type: 'cur', want: 8, minThc: 0, thc: 18, zona: 'astilleros' }, j: 1, acc: .92, lad: 1 / 3 }];
    const vender = [], venta = async v => {   // el rosin (catador): a precioR y +2,5 de calor por gramo (la flor, +0,5)
      const ext = v.c.type === 'ext', h = 3 + v.c.want * (ext ? 2.5 : .5);
      const precio = Math.round((ext ? precioR : precioC)(v.c.thc) * datos.mult[v.c.type] * ZON[v.c.zona || 'town'].precio * v.c.want * [.85, 1, 1.3][v.j]), mc = await ventaMC(v.c, v.j, N);
      compara(`${v.n}: acepta`, v.acc, mc.acepta, N);compara(`${v.n}: chico de Darko`, v.lad || 0, mc.lad, mc.ok);
      exige(`${v.n}: cobras ${precio} €`, mc.cobro.length === 1 && mc.cobro[0] === precio, mc.cobro);
      exige(`${v.n}: calor +${h}`, Math.abs(mc.calor - h) < 1e-9, mc.calor);
      return [v.n + ` (acepta el ${coma(v.acc * 100, 0)} %)`, precio, h];
    };
    for (const v of VENTAS) vender.push(await venta(v));
    vender.push(['Iñaki · 10 g para el viaje (una vez al día)', Math.round(precioC(18) * 1.2 * 10), 3],
      ['Al por mayor · 1 kg (una carga al día, hasta 1 kg antes del imperio)', Math.round(1000 * precioM(18)), 2 + 1000 / 100],
      ['Al por mayor · 10 kg (Mayorista del norte; el calor no pasa de 100)', Math.round(10000 * precioM(18)), Math.min(100, 2 + 10000 / 100)],
      ['Encargo de Don Baltasar · 2 kg (cap. 8, Proveedor del barrio)', zc.ENCARGO[1] * zc.PAGO_ENCARGO, 3]);
    exige('Iñaki 10 g', iñaki.inaki.e === vender[3][1] && iñaki.inaki.h === 3 && iñaki.inaki.g === 10, iñaki.inaki);
    exige('al por mayor 1 kg', iñaki.mayor.e === vender[4][1] && iñaki.mayor.h === 12 && iñaki.mayor.g === 1000, iñaki.mayor);
    exige('encargo de Baltasar', iñaki.encargo.e === vender[6][1] && iñaki.encargo.h === 3 && iñaki.encargo.g === zc.ENCARGO[1] && iñaki.encargo.fin, iñaki.encargo);
    // el rosin, al final (las de arriba se miran por su índice)
    for (const [t, p] of zc.rosin) exige(`rosin al ${t} %: ${precioR(t)} €/g`, Math.abs(precioR(t) - p) < 1e-9, p);
    exige('rosin: 20 % del peso, ×3 de THC, hasta el 75 %', zc.ROSIN.rend === .2 && zc.ROSIN.thc === 3 && zc.ROSIN.tope === 75, zc.ROSIN);
    vender.push(await venta({ n: 'Catador · 2 g de rosin al 54 % a precio justo (cap. 3, con la prensa)', c: { ch: 4, type: 'ext', want: 2, minThc: 0, thc: 54 }, j: 1, acc: .92 }));
    T.eficiencia = ['| Venta (THC 18 %, salvo el pijo y el rosin) | Cobras | €/g | Calor | € por punto de calor |', '|---|---|---|---|---|',
      ...vender.map(([n, e, h], i) => { const g = [8, 12, 8, 10, 1000, 10000, zc.ENCARGO[1], 2][i];return `| ${n} | ${eur(e)} | ${coma(e / g, 2)} | +${coma(h, 0)} | ${miles(e / h)} € |`; })].join('\n');
    T.calorOk = `Comprobado con el juego: redada con calor 90 y no con 89,9 (se lleva las plantas, los gramos y hasta ${eur(datos.redada)} de multa, y deja el calor en 30); −12 al día; con protección, −20 y la redada se para (calor 50, sin quitar nada); +${datos.olor} por carpa en flor sin filtro.`;

    // ---------- 6. Copa ----------
    const nom = datos.nombres, CP = { p60: 'armario 60', m100: 'carpa 100', m120: 'carpa 120', g150: 'carpa 150' }, FC = { cfl: 'CFL', led480: 'LED 480 W', sodio600: 'sodio 600 W', led720: 'LED 720 W' };
    const COPA = [['tormenta', 1, 'p60', 'cfl', false, 'plastico7'], ['tormenta', 1, 'm100', 'led480', true, 'tela25'], ['tormenta', 1, 'g150', 'sodio600', true, 'tela25'],
      ['tormenta', 1, 'm120', 'led720', true, 'tela25'], ['tormenta', 4, 'm120', 'led720', true, 'tela25'], ['dragon', 1, 'p60', 'cfl', false, 'plastico7'], ['dragon', 1, 'm120', 'led720', true, 'tela25']]
      .map(([sid, gen, carpa, foco, abono, maceta]) => ({ sid, gen, carpa, foco, abono, maceta, sig: gen >= 4 ? 'estable' : 'F' + gen,
        n: `${nom[sid]} ${gen >= 4 ? 'estable' : 'F' + gen} · ${CP[carpa]} + ${FC[foco]}${abono ? ' · abono' : ''}` }));
    const filasC = [], NC = Math.ceil(N / 4);
    for (const e of COPA) {
      const luz = luzDe(e.carpa, e.foco), p = copa(datos.thc[e.sid], datos.sigma[e.sig], luz, e.abono), mc = await copaMC(e, NC);
      compara(`Copa ${e.n} (por planta)`, p, mc.p, mc.plantas);exige(`Copa ${e.n}: premio`, mc.premioMal === 0, mc.premioMal);
      const media = Math.round((datos.thc[e.sid] + luz + (e.abono ? .3 : 0)) * 10) / 10;
      filasC.push(`| ${e.n} | ${datos.carpas[e.carpa].n} | ${coma(media, 1)} % | ${pc(p)} | ${pc(mc.p)} | ${coma(mc.g, 0)} g | ${pc(mc.gana2)} | ${pc(mc.ganaN)} |`);
    }
    T.copa = ['| Planta y equipo | Plazas | THC medio | Una planta pasa de 26,8 % (modelo) | Juego (por planta) | Gramos por planta | Con 2 plantas (juego) | Carpa llena (juego) |',
      '|---|---|---|---|---|---|---|---|', ...filasC].join('\n');

    // ---------- 7. caja fuerte (1.10): hoy (todo encima), con caja (solo lo del viaje) y con caja y el soborno encima. Los
    // trayectos se andan en el juego con lo demás dentro de S.caja (cada tramo de cada columna); las pérdidas, del modelo ----
    exige('caja: C de 20.000 € y 2 kg, B de 50.000 € y 2,5 kg (380 €), 1 de cada 4 redadas, 1998, 300 € dentro', zc.CAJA[1].money === 20000 && zc.CAJA[1].g === 2000 && zc.CAJA[2].money === 50000 && zc.CAJA[2].g === 2500
      && zc.CAJA_P === 380 && zc.CAJA_REDADA === P_CAJA && zc.CAJA_ANIO === 1998 && zc.MAITE_CAJA === 300 && datos.redada === MULTA_R, zc);
    const R = Object.fromEntries(rutas.map(r => [r.k, r.tiles]));
    // por tramo: el ladrón (la mejor estrategia; el primero del tramo) y, aparte, lo que pierdes si una patrulla te pilla (el
    // control, con la mejor opción); sin gramos encima, la patrulla no sospecha y no hay control
    const perdidaTramo = (tiles, e, eurG) => {
      const t = trayecto(tiles, e), lad = ladron({ ch: e.ch, hp: e.hp, rep: e.rep, spray: e.spray, bocata: e.bocata, pol: 'optima' });
      const lk = lad.ko * (Math.floor(e.g / 2) * eurG + Math.round(e.money * .3));
      return { lad: t.lad, eur: t.lad * lk, pilla: e.g > 0 ? mejorPolicia(e, eurG).eur : null };
    };
    // lo que hay que llevar para poder sobornar: X tal que X ≥ el soborno con X encima (el 5 % del dinero también cuenta)
    const extraSoborno = (heat, g, m) => { if (!g) return 0;let x = 0;while (x < soborno({ heat, g, money: m + x })) x++;return x; };
    const CAJA = [
      { n: 'Cap. 3 · ir a comprar a Kiko (200 €)', ruta: 'tienda', base: { ch: 3, heat: 30, rep: 20, hp: 30, spray: 0, bocata: 1 }, eurG: datos.eurG,
        hoy: [{ g: 300, money: 2000 }, { g: 300, money: 1800 }], caja: [{ g: 0, money: 200 }, { g: 0, money: 0 }] },
      { n: 'Cap. 4 · vender 10 g a Iñaki', ruta: 'muelle', base: { ch: 4, heat: 50, rep: 40, hp: 36, spray: 0, bocata: 1 }, eurG: datos.eurG,
        hoy: [{ g: 400, money: 5000 }, { g: 390, money: 5091 }], caja: [{ g: 10, money: 0 }, { g: 0, money: 91 }] },
      { n: 'Cap. 4 · vender 40 g en la plaza, de noche', ruta: 'plaza', base: { ch: 4, heat: 60, rep: 40, hp: 36, spray: 1, bocata: 1, night: true }, eurG: datos.eurG,
        hoy: [{ g: 400, money: 5000 }, { g: 360, money: 5300 }], caja: [{ g: 40, money: 0 }, { g: 0, money: 300 }] },
      { n: 'Cap. 5 · pagar 12.000 € a Baltasar', ruta: 'bar', base: { ch: 5, heat: 70, rep: 60, hp: 44, spray: 2, bocata: 1 }, eurG: datos.eurG,
        hoy: [{ g: 600, money: 13000 }, { g: 600, money: 1000 }], caja: [{ g: 0, money: 12000 }, { g: 0, money: 0 }] },
      { n: 'Cap. 8 · cargar 2 kg a Iñaki', ruta: 'muelle', base: { ch: 8, heat: 50, rep: 150, hp: 60, spray: 2, bocata: 1 }, eurG: datos.eurMayor,
        hoy: [{ g: 4500, money: 40000 }, { g: 2500, money: 47600 }], caja: [{ g: 2000, money: 0 }, { g: 0, money: 7600 }] }];
    const filasK = [], sup = [];
    for (const c of CAJA) {
      const t = R[c.ruta], gMax = Math.max(...c.caja.map(l => l.g)), extra = extraSoborno(c.base.heat, gMax, Math.max(...c.caja.map(l => l.money)));
      const soborno = c.caja.map(l => ({ ...l, money: l.money + extra }));
      // lo que no llevas encima está en la caja: la diferencia con lo de hoy en ese tramo
      const dentro = legs => legs.map((l, k) => ({ ...l, caja: legs === c.hoy ? null : { money: Math.max(0, c.hoy[k].money - l.money), g: c.hoy[k].g - l.g } }));
      const viaje = async (legs, col) => {
        const L = dentro(legs), x = L.map(l => perdidaTramo(t, { ...c.base, ...l }, c.eurG));
        for (const [k, l] of L.entries()) { const e = { ...c.base, ...l }, mc = await trayectoMC(t, e, N);
          exige(`caja «${c.n}» (${col}, tramo ${k + 1}): ningún control por paso`, mc.pol === 0, mc.pol);compara(`caja «${c.n}» (${col}, tramo ${k + 1}) ladrón`, x[k].lad, mc.lad, N); }
        return { lad: 1 - (1 - x[0].lad) * (1 - x[1].lad), eur: x[0].eur + x[1].eur, pilla: x[0].pilla }; };
      const celda = v => `${pc(v.lad)} · ${Math.round(v.eur) > 0 ? "−" : ""}${eur(v.eur)} · ${v.pilla == null ? 'nada que ver' : '−' + eur(v.pilla)}`;
      filasK.push(`| ${c.n} | ${celda(await viaje(c.hoy, 'hoy'))} | ${celda(await viaje(c.caja, 'con caja'))} | ${extra ? celda(await viaje(soborno, 'con soborno')) : 'igual'} |`);
      const b = c.base, l = (x, y) => `${x.g ? miles(x.g) + ' g y ' : ''}${eur(x.money)} a la ida, ${y.g ? miles(y.g) + ' g y ' : ''}${eur(y.money)} a la vuelta`;
      sup.push(`- **${c.n}:** calor ${b.heat}, reputación ${b.rep}, vida ${b.hp}, ${b.spray ? b.spray + ' spray' + (b.spray > 1 ? 's' : '') : 'sin spray'} y ${b.bocata} bocata${b.night ? ', de noche' : ''}; gramos a ${coma(c.eurG, 2)} €/g. Sin caja: ${l(...c.hoy)}. Con caja: ${l(...c.caja)}${extra ? `; con el soborno, ${eur(extra)} más en cada tramo` : ''}.`);
    }
    // la redada con la caja, jugada
    const RED = [{ n: 'Sin caja: 10.000 € y 500 g en el piso', money: 10000, g: 500 }, { n: 'Con caja: todo dentro', money: 0, g: 0, caja: { money: 10000, g: 500 } },
      { n: 'Con caja: 1.000 € y 100 g fuera, el resto dentro', money: 1000, g: 100, caja: { money: 9000, g: 400 } }, { n: 'Con caja: 3.000 € fuera (pagan la multa), el resto dentro', money: 3000, g: 0, caja: { money: 7000, g: 500 } }];
    const filasRe = [];
    for (const e of RED) {
      const x = redada(e, datos.eurG), mc = await redadaMC({ ...e, eurG: datos.eurG }, N);
      compara(`redada «${e.n}»: pérdida`, x.eur, mc.eur, N, mc.sd);compara(`redada «${e.n}»: caja hallada`, x.hallada, mc.hallada, N);
      filasRe.push(`| ${e.n} | ${e.caja ? pc(x.hallada, 0) : '—'} | −${eur(x.eur)} | −${eur(mc.eur)} |`);
    }
    T.redada = ['| En el piso (gramos a ' + coma(datos.eurG, 2) + ' €/g; las plantas se pierden igual) | Encuentran la caja | Pérdida media (modelo) | Juego |', '|---|---|---|---|', ...filasRe].join('\n');
    T.caja = ['| Ida y vuelta | Sin caja: ladrón · pérdida media · si te pilla una patrulla a la ida | Con caja | Con caja y el soborno encima |', '|---|---|---|---|', ...filasK].join('\n');
    T.cajaSup = sup.join('\n');
    T.meta = `Generado con \`npm run analisis\`: ${miles(comprobadas)} cifras comprobadas con el juego (${miles(N)} combates, controles, ventas o trayectos simulados por celda, ${miles(N * 5)} pasos por situación, ${miles(NC)} carpas por fila de la Copa y las patrullas fotograma a fotograma). Gramos a ${coma(datos.eurG, 2)} €/g (precio de calle de una variedad del 18 %), salvo donde se dice.`;
  }

  await browser.close();
  if (errores.length) { console.error('errores JS:', errores);process.exit(1); }
  for (const f of fallos) console.log('  FALLO', f);
  console.log(`${fallos.length ? 'el modelo no coincide con el juego' : 'modelo = juego'} (${comprobadas} comprobaciones, ${fallos.length} fallos)`);
  if (!res && !fallos.length) {
    let doc = fs.readFileSync(DOC, 'utf8');
    for (const [k, v] of Object.entries(T)) {
      const re = new RegExp(`(<!-- auto:${k} -->)[\\s\\S]*?(<!-- /auto:${k} -->)`);
      if (!re.test(doc)) throw new Error('falta el bloque auto:' + k + ' en docs/ANALISIS.md');
      doc = doc.replace(re, (_, a, b) => a + '\n' + v + '\n' + b);
    }
    fs.writeFileSync(DOC, doc);
    console.log('docs/ANALISIS.md: ' + Object.keys(T).length + ' tablas');
  } else if (!res) console.log('docs/ANALISIS.md sin tocar');
  process.exit(fallos.length ? 1 : 0);
})();
