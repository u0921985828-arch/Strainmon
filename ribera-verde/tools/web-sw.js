// Landrace Hunters — el juego guardado en el móvil (1.7.0): comprueba que, tras la primera visita, abrir el juego
// no le pide nada al servidor y que sigue arrancando con el servidor apagado (lo pidió el usuario: «que el host esté
// mucho más libre»). Un servidor de pruebas imita lo que hace landrace-hunters.php (la página con su <base> y el
// registro, y /<dirección>/sw.js con la versión y la lista de archivos arriba) y Chromium lo juega de verdad.
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

const pedidos = [];
const base = (p) => `http://localhost:${PUERTO}${p}`;

const servidor = http.createServer((req, res) => {
  const u = req.url.split('?')[0];
  pedidos.push(u);
  if (u === `/${SLUG}/` || u === `/${SLUG}`) {   // la página: index.html con <base> y el registro, como maybe_serve()
    let html = fs.readFileSync(path.join(GAME, 'index.html'), 'utf8')
      .replace('<meta charset="utf-8">', `<meta charset="utf-8">\n\t\t<base href="${base('/game/')}">`)
      .replace('</body>', `<script>if("serviceWorker" in navigator){addEventListener("load",function(){`
        + `navigator.serviceWorker.register("${base(`/${SLUG}/sw.js`)}",{scope:"${base(`/${SLUG}/`)}"}).catch(function(){})})}</script>\n</body>`);
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'public, max-age=600' });
    return res.end(html);
  }
  if (u === `/${SLUG}/sw.js`) {   // el trabajador, como sw(): la versión y la lista de archivos arriba
    const files = PIEZAS.filter((f) => fs.existsSync(path.join(GAME, f))).map((f) => base('/game/' + f));
    const pre = `const LH_CACHE = ${JSON.stringify('lh-' + VER)};\nconst LH_FILES = ${JSON.stringify(files)};\n`
      + `const LH_PAGE = ${JSON.stringify(base(`/${SLUG}/`))};\n`;
    res.writeHead(200, { 'Content-Type': 'text/javascript; charset=utf-8', 'Service-Worker-Allowed': `/${SLUG}/`, 'Cache-Control': 'no-cache' });
    return res.end(pre + fs.readFileSync(path.join(GAME, 'lh-sw.js'), 'utf8'));
  }
  if (u.startsWith('/game/')) {
    const f = path.join(GAME, path.basename(u));
    if (!fs.existsSync(f)) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'Content-Type': TIPO[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'public, max-age=2592000' });
    return res.end(fs.readFileSync(f));
  }
  res.writeHead(404);
  res.end();
});

const grandes = (a) => a.filter((u) => /index\.(pck|wasm|js)$/.test(u));
let fallos = 0;
const ok = (q, c) => { console.log((c ? 'ok   ' : 'FALLO') + ' ' + q); if (!c) fallos++; };

(async () => {
  await new Promise((r) => servidor.listen(PUERTO, r));
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const ctx = await b.newContext({ viewport: { width: 960, height: 540 } });
  const p = await ctx.newPage();
  const errores = [];
  p.on('pageerror', (e) => errores.push(e.message));

  // 1 · la primera visita: el servidor entrega el juego entero
  await p.goto(base(`/${SLUG}/`));
  await p.waitForTimeout(25000);
  const uno = grandes(pedidos).length;
  ok(`1.ª visita: el servidor da el juego (${uno} archivos)`, uno >= 3);
  await p.waitForFunction(() => navigator.serviceWorker.controller != null, null, { timeout: 60000 }).catch(() => {});
  const guardado = await p.evaluate(async () => {
    const c = await caches.open(Object.keys(await caches.keys()).length ? (await caches.keys())[0] : 'x');
    return (await c.keys()).length;
  });
  ok(`el juego queda guardado en el navegador (${guardado} archivos)`, guardado >= 3);

  // 2 · la segunda visita: ni un archivo del juego al servidor
  pedidos.length = 0;
  await p.goto(base(`/${SLUG}/`));
  await p.waitForTimeout(20000);
  const dos = grandes(pedidos);
  ok(`2.ª visita: el servidor no da ningún archivo del juego (${dos.length})`, dos.length === 0);

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
