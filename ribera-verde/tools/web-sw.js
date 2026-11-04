// Landrace Hunters — el juego guardado en el móvil (1.7.0): comprueba que, tras la primera visita, abrir el juego
// no le pide nada al servidor y que sigue arrancando con el servidor apagado (lo pidió el usuario: «que el host esté
// mucho más libre»). Un servidor de pruebas imita lo que hace landrace-hunters.php (la página con su <base> y el
// registro, y /<dirección>/sw.js con la versión y la lista de archivos arriba) y Chromium lo juega de verdad.
// Desde la 1.7.5 lleva además el caso reservado: si alguna pieza del juego está a medias (un tamaño
// distinto del que index.html declara en «fileSizes»), comprueba que el trabajador no la guarda y no
// da la instalación por entera, en vez de dejar la pantalla en negro sin avisar.
//   node tools/web-sw.js <carpeta del plugin> [puerto]
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const RAIZ = process.argv[2];
const PUERTO = +(process.argv[3] || 8795);
const SLUG = 'landrace-hunters';
const GAME = path.join(RAIZ, 'game');
const VER = (fs.readFileSync(path.join(RAIZ, 'landrace-hunters.php'), 'utf8').match(/const VERSION\s*=\s*'([^']+)'/) || [])[1];
const PIEZAS = ['index.js', 'index.wasm', 'index.pck', 'index.audio.worklet.js', 'index.audio.position.worklet.js',
  'index.png', 'icon-192.png', 'icon-576.png', 'lh-fs.js'];
const TIPO = { '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.html': 'text/html' };
const HTML = fs.readFileSync(path.join(GAME, 'index.html'), 'utf8');
// Los tamaños que el juego espera de cada pieza, como los lee el plugin (tamanos() en el PHP).
const SIZES = (() => {
  const m = HTML.match(/fileSizes"?\s*:\s*(\{[^}]*\})/);
  const o = {};
  if (m) { for (const [k, v] of Object.entries(JSON.parse(m[1]))) o[path.basename(k)] = +v; }
  return o;
})();
const rotas = PIEZAS.filter((f) => {
  const q = path.join(GAME, f);
  return SIZES[f] > 0 && fs.existsSync(q) && fs.statSync(q).size !== SIZES[f];
});

const pedidos = [];
let bytes = 0;            // bytes del juego servidos (la medida de lo que tarda en cargar; lo pidió el usuario)
const porArch = {};
const base = (p) => `http://localhost:${PUERTO}${p}`;

const servidor = http.createServer((req, res) => {
  const u = req.url.split('?')[0];
  pedidos.push(u);
  if (u === `/${SLUG}/` || u === `/${SLUG}`) {   // la página: index.html con <base> y el registro, como maybe_serve()
    let html = HTML
      .replace('<meta charset="utf-8">', `<meta charset="utf-8">\n\t\t<base href="${base('/game/')}">`)
      .replace('</head>', `<script>window.LH_SW=new Promise(function(f){`
        + `if(!("serviceWorker" in navigator)){f();return}`
        + `var n=navigator.serviceWorker,t=setTimeout(f,5000),d=function(){clearTimeout(t);f()};`
        + `if(n.controller){d();return}`
        + `n.addEventListener("controllerchange",d);`
        + `n.register("${base(`/${SLUG}/sw.js`)}",{scope:"${base(`/${SLUG}/`)}"}).catch(d)})</script>\n</head>`);
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'public, max-age=600' });
    return res.end(html);
  }
  if (u === `/${SLUG}/sw.js`) {   // el trabajador, como sw(): la versión y la lista de archivos arriba
    const files = PIEZAS.filter((f) => fs.existsSync(path.join(GAME, f))).map((f) => base('/game/' + f));
    const sizes = {};
    for (const u of files) { const n = path.basename(u); if (SIZES[n] > 0) sizes[u] = SIZES[n]; }
    const pre = `const LH_CACHE = ${JSON.stringify('lh-' + VER)};\nconst LH_FILES = ${JSON.stringify(files)};\n`
      + `const LH_SIZES = ${JSON.stringify(sizes)};\n`
      + `const LH_PAGE = ${JSON.stringify(base(`/${SLUG}/`))};\n`;
    res.writeHead(200, { 'Content-Type': 'text/javascript; charset=utf-8', 'Service-Worker-Allowed': `/${SLUG}/`, 'Cache-Control': 'no-cache' });
    return res.end(pre + fs.readFileSync(path.join(GAME, 'lh-sw.js'), 'utf8'));
  }
  if (u.startsWith('/game/')) {
    const f = path.join(GAME, path.basename(u));
    if (!fs.existsSync(f)) { res.writeHead(404); return res.end(); }
    const st = fs.statSync(f);
    const n = path.basename(u);
    // como un servidor de archivos de verdad: ETag y Last-Modified, y 304 si el navegador ya lo tiene
    const etag = `"${st.size.toString(16)}-${st.mtimeMs.toString(16)}"`;
    const cab = {
      'Content-Type': TIPO[path.extname(f)] || 'application/octet-stream',
      'Cache-Control': 'public, max-age=2592000',
      ETag: etag,
      'Last-Modified': st.mtime.toUTCString(),
    };
    if (req.headers['if-none-match'] === etag) { res.writeHead(304, cab); return res.end(); }
    // 1.7.6: la copia comprimida que deja el plugin (comprime_piezas), como la sirve game/.htaccess
    const gz = f + '.gz';
    if (fs.existsSync(gz) && /gzip/.test(req.headers['accept-encoding'] || '')) {
      const dz = fs.readFileSync(gz);
      bytes += dz.length;
      porArch[n] = (porArch[n] || 0) + dz.length;
      res.writeHead(200, { ...cab, 'Content-Encoding': 'gzip', Vary: 'Accept-Encoding' });
      return res.end(dz);
    }
    const d = fs.readFileSync(f);
    bytes += d.length;
    porArch[n] = (porArch[n] || 0) + d.length;
    res.writeHead(200, cab);
    return res.end(d);
  }
  res.writeHead(404);
  res.end();
});

const grandes = (a) => a.filter((u) => /index\.(pck|wasm|js)$/.test(u));
let fallos = 0;
const ok = (q, c) => { console.log((c ? 'ok   ' : 'FALLO') + ' ' + q); if (!c) fallos++; };

(async () => {
  await new Promise((r) => servidor.listen(PUERTO, r));
  const exe = process.env.CHROMIUM_PATH || '';
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'], ...(exe ? { executablePath: exe } : {}) });
  const ctx = await b.newContext({ viewport: { width: 960, height: 540 } });
  const p = await ctx.newPage();
  const errores = [];
  p.on('pageerror', (e) => errores.push(e.message));

  if (rotas.length) {   // caso reservado: una pieza a medias no se guarda ni cuenta como instalación entera
    await p.goto(base(`/${SLUG}/`));
    await p.waitForTimeout(30000);
    await p.waitForFunction(() => navigator.serviceWorker.controller != null, null, { timeout: 60000 }).catch(() => {});
    const dentro = await p.evaluate(async () => {
      const ns = await caches.keys();
      const out = [];
      for (const n of ns) { const c = await caches.open(n); for (const k of await c.keys()) out.push(k.url); }
      return out;
    });
    for (const f of rotas) ok(`la pieza a medias (${f}) no se guarda`, !dentro.some((u) => u.endsWith('/' + f)));
    ok('la instalación no se da por entera', !dentro.some((u) => u.endsWith('/lh-entera')));
    if (process.argv[4]) await p.screenshot({ path: process.argv[4] });
    await b.close();
    await new Promise((r) => servidor.close(r));
    console.log(`web-sw (pieza a medias): ${fallos} fallos`);
    process.exit(fallos ? 1 : 0);
  }

  // 1 · la primera visita: el servidor entrega el juego entero
  await p.goto(base(`/${SLUG}/`));
  await p.waitForTimeout(25000);
  const uno = grandes(pedidos).length;
  ok(`1.ª visita: el servidor da el juego (${uno} archivos)`, uno >= 3);
  const mb = (bytes / 1048576).toFixed(1);
  console.log(`     bytes de la 1.ª visita: ${mb} MB` + Object.entries(porArch).filter(([n]) => /index\.(pck|wasm|js)$/.test(n))
    .map(([n, v]) => ` · ${n} ${(v / 1048576).toFixed(1)} MB ×${(v / fs.statSync(path.join(GAME, n)).size).toFixed(1)}`).join(''));
  const veces = Math.max(...PIEZAS.filter((f) => porArch[f]).map((f) => porArch[f] / fs.statSync(path.join(GAME, f)).size));
  ok(`cada pieza se baja una sola vez (la peor, ${veces.toFixed(1)} veces)`, veces < 1.5);
  await p.waitForFunction(() => navigator.serviceWorker.controller != null, null, { timeout: 60000 }).catch(() => {});
  const claves = await p.evaluate(async () => {
    const out = [];
    for (const n of await caches.keys()) { const c = await caches.open(n); for (const k of await c.keys()) out.push(k.url.split('/').pop()); }
    return out;
  });
  ok(`el juego queda guardado en el navegador (${claves.length} archivos)`, claves.length >= 3);
  const faltan = PIEZAS.filter((f) => fs.existsSync(path.join(GAME, f)) && !claves.includes(f));
  ok(`no falta ninguna pieza por guardar${faltan.length ? ' (faltan ' + faltan.join(', ') + ')' : ''}`, faltan.length === 0);

  // 2 · la segunda visita: ni un archivo del juego al servidor
  pedidos.length = 0;
  await p.goto(base(`/${SLUG}/`));
  await p.waitForTimeout(20000);
  const dos = grandes(pedidos);
  ok(`2.ª visita: el servidor no da ningún archivo del juego (${dos.length}${dos.length ? ': ' + dos.join(', ') : ''})`, dos.length === 0);

  // 3 · con el servidor apagado, el juego sigue abriendo
  await new Promise((r) => servidor.close(r));
  await p.goto(base(`/${SLUG}/`)).catch(() => {});
  await p.waitForTimeout(20000);
  const vivo = await p.evaluate(() => !!document.getElementById('canvas'));
  const pintado = await p.evaluate(() => {
    const c = document.getElementById('canvas');
    return c ? c.width > 0 && c.height > 0 : false;
  });
  ok('sin servidor: el juego abre igual', vivo && pintado);
  if (process.argv[4]) await p.screenshot({ path: process.argv[4] });

  ok('sin errores de JavaScript', errores.length === 0);
  if (errores.length) console.log(errores.slice(0, 5).join('\n'));
  await b.close();
  console.log(`web-sw: ${fallos} fallos`);
  process.exit(fallos ? 1 : 0);
})();
