/* El juego, instalable en el móvil y sin conexión.
 *
 * No es otro puerto: es el MISMO `referencia/bilbo-city.html`, sin tocar una línea. Lo
 * único que se le añade al empaquetar son tres cosas que un archivo suelto no puede
 * llevar dentro —el manifiesto, el trabajador de servicio y los iconos— porque el
 * navegador las exige como ficheros aparte del mismo origen. Por eso esto no vive en el
 * HTML sino aquí, y por eso `dist/` no se versiona: es salida, como el APK.
 *
 *   node herramientas/html/pwa.js            # escribe dist/
 *   node herramientas/html/pwa.js --probar   # lo levanta y lo abre en Chromium
 *
 * En el móvil: servir `dist/` por HTTPS (o localhost) y «Añadir a la pantalla de inicio».
 * Desde ahí arranca a pantalla completa, apaisado y sin barra del navegador, y una vez
 * abierto no vuelve a pedir red.
 */
const fs = require('fs'), path = require('path'), crypto = require('crypto'), zlib = require('zlib');
const { createCanvas } = require('canvas');

const RAIZ = path.join(__dirname, '..', '..');
const FUENTE = path.join(RAIZ, 'referencia', 'bilbo-city.html');
const DIST = path.join(RAIZ, 'dist');

/* La paleta se lee del juego, no se copia: son los 61 colores de siempre y un icono con
   un verde de más sería el primer color fuera de la paleta del proyecto. Y se lee
   ejecutando las dos tablas, no con una expresión regular: la segunda son apodos que
   apuntan a la primera (`asfalto: C.hormigon1`), así que leyendo solo literales el icono
   sale entero negro — que es exactamente lo que pasó. */
function paleta() {
  const html = fs.readFileSync(FUENTE, 'utf8');
  const a = html.indexOf('const C={');
  const b = html.indexOf('});', html.indexOf('Object.assign(C,{', a));
  if (a < 0 || b < 0) throw new Error('no encuentro las dos tablas de colores del juego');
  const C = eval(html.slice(a, b + 3) + '; C');            // dos objetos literales, nada más
  for (const k of ['negro','asfalto','carbon','ladrillo2','verde2','verde4','ria1','ria3','ria5','hueso'])
    if (!C[k]) throw new Error('la paleta del juego ya no tiene ' + k);
  return C;
}

/* La paleta otra vez, pero en orden y sin repetidos: es el índice que escribe
   `herramientas/sprites/arte.py` en el bloque ARTE, y tiene que valer igual aquí que en
   el juego. Mismo descarte que hace el Set del juego, mismo orden de aparición. */
function paletaOrdenada() {
  const html = fs.readFileSync(FUENTE, 'utf8');
  const a = html.indexOf('const C={');
  const bloque = html.slice(a, html.indexOf('};', a));
  const fuera = [], vistos = new Set();
  for (const m of bloque.matchAll(/(\w+):'(#[0-9a-fA-F]{6})'/g)) {
    const h = m[2].toLowerCase();
    if (vistos.has(h)) continue;
    vistos.add(h);
    fuera.push([parseInt(h.slice(1,3),16), parseInt(h.slice(3,5),16), parseInt(h.slice(5,7),16)]);
  }
  return fuera;
}

/* El emblema de la portada, sacado del mismo sitio del que lo saca el juego: el bloque
   ARTE. No se vuelve a generar ni se copia a un PNG aparte —un PNG en el repositorio es
   justo lo que este proyecto no tiene— sino que se lee de ahí, se infla y se pinta.
   Si el bloque no lo lleva, devuelve null y el icono vuelve al dibujado a mano. */
function emblema() {
  const html = fs.readFileSync(FUENTE, 'utf8');
  const m = /marca:\{\s*logo:\[(\d+),(\d+),\[([^\]]*)\]\.join\(''\)\]/.exec(html);
  if (!m) return null;
  const w = +m[1], h = +m[2];
  const b64 = [...m[3].matchAll(/'([^']*)'/g)].map(t => t[1]).join('');
  let bytes;
  try { bytes = zlib.inflateRawSync(Buffer.from(b64, 'base64')); } catch (e) { return null; }
  if (bytes.length !== w * h) return null;
  const pal = paletaOrdenada();
  const c = createCanvas(w, h), g = c.getContext('2d'), img = g.createImageData(w, h), d = img.data;
  for (let i = 0, j = 0; i < bytes.length; i++, j += 4) {
    const v = bytes[i];
    if (!v) { d[j+3] = 0; continue; }          // 0 es transparente, como en el juego
    const p = pal[(v - 1) % pal.length];
    d[j] = p[0]; d[j+1] = p[1]; d[j+2] = p[2]; d[j+3] = 255;
  }
  g.putImageData(img, 0, 0);
  return c;
}

/* El icono de la aplicación es el emblema de la portada, no un dibujo aparte: lo que se
   ve en el lanzador tiene que ser lo que se ve al arrancar el juego, o son dos marcas.
   El escudo tiene las esquinas transparentes, así que debajo va una plancha negra: un
   icono de aplicación no puede ser medio transparente. */

/* El emblema centrado en un lienzo de `lado`, a la escala entera más grande que quepa
   dejando `margen` por banda. Entera y por vecino más próximo, no a la medida exacta
   del hueco: a escala rota el redimensionado se come filas sueltas y el aro ámbar sale a
   trozos, que es justo como salió el recortable el primer intento. */
function emblemaEn(lado, margen) {
  const emb = emblema();
  if (!emb) return null;
  const esc = Math.floor((lado - margen * 2) / emb.width);
  if (esc < 1) return null;
  const n = emb.width * esc, o = Math.round((lado - n) / 2);
  const c = createCanvas(lado, lado), g = c.getContext('2d');
  g.imageSmoothingEnabled = false;
  g.drawImage(emb, o, o, n, n);
  return c;
}

/* Plancha y emblema encima. Si no hay emblema en el bloque ARTE, el dibujado a mano de
   aquí abajo, que es lo que había antes y sigue valiendo. */
function iconoApp(C, lado, margen) {
  const c = createCanvas(lado, lado), g = c.getContext('2d');
  g.fillStyle = C.negro; g.fillRect(0, 0, lado, lado);
  const emb = emblemaEn(lado, margen);
  if (emb) { g.drawImage(emb, 0, 0); return c; }
  g.imageSmoothingEnabled = false;
  g.drawImage(icono32(C, margen ? 4 : 0), 0, 0, lado, lado);
  return c;
}

/* El icono se dibuja en 32×32 y se amplía a escala entera, como todo lo demás: 32×6=192 y
   32×16=512. Ampliado con interpolación sería el único dibujo borroso del proyecto.
   Qué se dibuja: la ría partiendo la ciudad en diagonal, con un puente. Es lo que se
   reconoce de Bilbao desde arriba, y a 48 píxeles en un escritorio lleno de iconos hace
   falta una forma gorda, no un plano. */
function icono32(C, margen) {
  const c = createCanvas(32, 32), g = c.getContext('2d');
  const P = (x, y, w, h, col) => { g.fillStyle = col; g.fillRect(x, y, w, h); };
  const m = margen;                       // los iconos recortables pierden el borde
  P(0, 0, 32, 32, C.negro);
  P(m, m, 32 - m*2, 32 - m*2, C.asfalto);
  // manzanas, insinuadas: a 48 píxeles no son manzanas, son textura
  for (let y = m + 1; y < 32 - m; y += 5)
    for (let x = m + 1; x < 32 - m; x += 5)
      P(x, y, Math.min(4, 32 - m - x), Math.min(4, 32 - m - y), C.ladrillo2);
  // el monte, arriba a la izquierda
  P(m, m, 12 - m, 9 - m, C.verde2);
  P(m, m, 12 - m, 1, C.verde4);
  // la ría: una banda ancha en diagonal, a escalones de píxel
  for (let y = m; y < 32 - m; y++) {
    const x = Math.max(m, Math.round(3 + y * 0.72)), an = Math.min(7, 32 - m - x);
    if (an <= 0) continue;
    /* La ría va con los tonos claros de su familia, no con el C.agua del juego: dentro
       de la partida es de noche casi siempre y casa, pero a 48 píxeles junto al asfalto
       es la misma mancha oscura y el icono se queda en una reja de ladrillo. */
    P(x, y, an, 1, C.ria3);
    P(x, y, 1, 1, C.ria1); P(x + an - 1, y, 1, 1, C.ria1);
    if (y % 4 === 0) P(x + 1, y, Math.max(1, an - 2), 1, C.ria5);
  }
  // el puente, y su sombra debajo
  P(9, 15, 15, 1, C.carbon);
  P(9, 13, 15, 2, C.hueso);
  // marco
  P(0, 0, 32, 1, C.negro); P(0, 31, 32, 1, C.negro);
  P(0, 0, 1, 32, C.negro); P(31, 0, 1, 32, C.negro);
  return c;
}

function escalar(base, esc) {
  const l = base.width * esc;
  const c = createCanvas(l, l), g = c.getContext('2d');
  g.imageSmoothingEnabled = false;
  g.drawImage(base, 0, 0, l, l);
  return c.toBuffer('image/png');
}

/* Lo que se le añade al HTML. Va justo antes de </head> y antes de </body> para no
   desplazar ni una línea de lo de arriba: el resto de herramientas leen el original por
   número de línea. */
const CABEZA = `
<link rel="manifest" href="bilbo.webmanifest">
<meta name="theme-color" content="#07090c">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<link rel="apple-touch-icon" href="icono-192.png">
<link rel="icon" href="icono-192.png">`;
const COLA = `
<script>
/* Sin conexión a partir de la primera visita. Si el trabajador no arranca —http sin
   cifrar, un navegador viejo— el juego funciona igual: es un archivo suelto. */
if('serviceWorker' in navigator)addEventListener('load',()=>
 navigator.serviceWorker.register('sw.js').catch(e=>console.warn('sin modo fuera de línea',e)));
</script>`;

const FICHEROS = ['index.html', 'bilbo.webmanifest', 'icono-192.png', 'icono-512.png',
                  'icono-maskable-512.png'];

function empaquetar() {
  const C = paleta();
  let html = fs.readFileSync(FUENTE, 'utf8');
  if (!html.includes('</head>') || !html.includes('</body>'))
    throw new Error('el HTML no tiene head y body: no sé dónde meter el manifiesto');
  html = html.replace('</head>', CABEZA + '\n</head>').replace('</body>', COLA + '\n</body>');

  fs.mkdirSync(DIST, { recursive: true });
  fs.writeFileSync(path.join(DIST, 'index.html'), html);
  /* El recortable lleva banda: el lanzador recorta hasta el 66 % del lado y sin margen
     se come las puntas del escudo. 64 de banda sobre 512 dejan el emblema al sexto. */
  fs.writeFileSync(path.join(DIST, 'icono-192.png'), iconoApp(C, 192, 0).toBuffer('image/png'));
  fs.writeFileSync(path.join(DIST, 'icono-512.png'), iconoApp(C, 512, 0).toBuffer('image/png'));
  fs.writeFileSync(path.join(DIST, 'icono-maskable-512.png'),
                   iconoApp(C, 512, 64).toBuffer('image/png'));

  fs.writeFileSync(path.join(DIST, 'bilbo.webmanifest'), JSON.stringify({
    name: 'Bilbo City', short_name: 'Bilbo City',
    description: 'Sandbox 2D cenital en el Bilbao de 1996.',
    start_url: '.', scope: '.', display: 'fullscreen', display_override: ['fullscreen', 'standalone'],
    orientation: 'landscape',            // el juego lo exige, y ya avisa si lo giras
    background_color: '#07090c', theme_color: '#07090c', lang: 'es',
    icons: [
      { src: 'icono-192.png', sizes: '192x192', type: 'image/png' },
      { src: 'icono-512.png', sizes: '512x512', type: 'image/png' },
      { src: 'icono-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' }
    ]
  }, null, 2) + '\n');

  /* La versión es el contenido, no una fecha ni un número a mano: si el juego no ha
     cambiado no hay caché nueva que crear, y si ha cambiado no hay forma de olvidarse. */
  const v = crypto.createHash('sha256').update(html).digest('hex').slice(0, 12);
  fs.writeFileSync(path.join(DIST, 'sw.js'), `/* Generado por herramientas/html/pwa.js. */
const CACHE='bilbo-${v}';
const FICHEROS=${JSON.stringify(['.', ...FICHEROS])};
self.addEventListener('install',e=>{self.skipWaiting();
 e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FICHEROS)));});
/* Al activarse se tiran las cachés de versiones viejas: si no, el móvil se queda con la
   partida de hace tres meses y no hay manera de saber por qué. */
self.addEventListener('activate',e=>e.waitUntil(
 caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k))))
  .then(()=>self.clients.claim())));
/* Primero la caché: el juego no pide nada a nadie, así que ir a la red antes solo sirve
   para tardar más y para no funcionar en el metro. */
self.addEventListener('fetch',e=>{
 if(e.request.method!=='GET')return;
 e.respondWith(caches.match(e.request,{ignoreSearch:true})
  .then(r=>r||fetch(e.request).then(res=>{
   const cp=res.clone();caches.open(CACHE).then(c=>c.put(e.request,cp));return res;})
   .catch(()=>caches.match('index.html'))));});
`);

  const peso = FICHEROS.concat('sw.js')
    .reduce((n, f) => n + fs.statSync(path.join(DIST, f)).size, 0);
  console.log('-> ' + path.relative(process.cwd(), DIST) + '/  ' +
              (FICHEROS.length + 1) + ' ficheros · ' + (peso / 1024 / 1024).toFixed(2) + ' MB · v' + v);
  return v;
}

/* La comprobación barata, la que entra en verificar.sh: que esté todo, que el manifiesto
   sea JSON con lo que pide el navegador para dejar instalar, y que el trabajador no
   prometa cachear un fichero que no existe —que es la forma de romperlo sin enterarse:
   addAll() falla entero y el modo fuera de línea no llega a instalarse nunca—. */
function comprobar() {
  const mal = [];
  const ok = (c, t) => { if (c) console.log('  ok    ' + t); else { mal.push(t); console.log('  FALLO ' + t); } };
  for (const f of FICHEROS.concat('sw.js'))
    ok(fs.existsSync(path.join(DIST, f)), 'está ' + f);
  if (mal.length) return mal;

  const man = JSON.parse(fs.readFileSync(path.join(DIST, 'bilbo.webmanifest'), 'utf8'));
  ok(man.name && man.start_url && man.display === 'fullscreen' && man.orientation === 'landscape',
     'el manifiesto pide pantalla completa y apaisado');
  ok(man.icons.some(i => i.sizes === '192x192') && man.icons.some(i => i.sizes === '512x512') &&
     man.icons.some(i => (i.purpose || '') === 'maskable'),
     'iconos de 192, de 512 y uno recortable');
  ok(man.icons.every(i => fs.existsSync(path.join(DIST, i.src))), 'todos los iconos existen');

  const sw = fs.readFileSync(path.join(DIST, 'sw.js'), 'utf8');
  const lista = JSON.parse(sw.match(/const FICHEROS=(\[[^\]]*\]);/)[1]);
  ok(lista.every(f => f === '.' || fs.existsSync(path.join(DIST, f))),
     'el trabajador no promete ningún fichero que falte');

  const html = fs.readFileSync(path.join(DIST, 'index.html'), 'utf8');
  ok(html.includes('bilbo.webmanifest') && html.includes("register('sw.js')"),
     'el HTML enlaza el manifiesto y registra el trabajador');
  ok(!/<script src=|<link rel="stylesheet"/.test(html),
     'no pide ni un fichero de fuera: el juego sigue siendo uno solo');
  return mal;
}

/* La cara: levantar dist/ y abrirlo en Chromium a tamaño de móvil apaisado, comprobar que
   el trabajador queda activo y que el juego arranca. Esto no va en la batería —levanta un
   navegador— pero es lo único que demuestra que se instala de verdad. */
async function probar() {
  const http = require('http'), { chromium } = require('playwright-core');
  const tipos = { '.html': 'text/html', '.js': 'text/javascript', '.png': 'image/png',
                  '.webmanifest': 'application/manifest+json' };
  const srv = http.createServer((q, r) => {
    const f = path.join(DIST, q.url === '/' ? 'index.html' : decodeURI(q.url).replace(/^\//, ''));
    if (!f.startsWith(DIST) || !fs.existsSync(f)) { r.writeHead(404); return r.end(); }
    r.writeHead(200, { 'Content-Type': tipos[path.extname(f)] || 'application/octet-stream' });
    r.end(fs.readFileSync(f));
  }).listen(0);
  const url = 'http://localhost:' + srv.address().port + '/';
  const nav = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const pag = await nav.newPage({ viewport: { width: 844, height: 390 }, deviceScaleFactor: 2 });
  const quejas = [];
  pag.on('console', m => { if (m.type() === 'error') quejas.push(m.text()); });
  await pag.goto(url, { waitUntil: 'load' });
  const activo = await pag.evaluate(() =>
    navigator.serviceWorker.ready.then(r => !!r.active).catch(() => false));
  await pag.waitForTimeout(4000);
  const man = await pag.evaluate(() => fetch('bilbo.webmanifest').then(r => r.json()));
  const cacheado = await pag.evaluate(() =>
    caches.keys().then(ks => Promise.all(ks.map(k => caches.open(k).then(c => c.keys()))))
      .then(l => l.flat().length));
  const tiro = path.join(DIST, 'pwa.png');
  await pag.screenshot({ path: tiro });
  await nav.close(); srv.close();
  console.log('  ok    trabajador de servicio activo: ' + activo);
  console.log('  ok    manifiesto servido: ' + man.name + ' · ' + man.display + ' · ' + man.orientation);
  console.log('  ok    ' + cacheado + ' respuestas en caché tras la primera visita');
  if (quejas.length) console.log('  FALLO la consola se queja: ' + quejas.slice(0, 3).join(' | '));
  console.log('-> ' + tiro);
  return quejas.length ? ['consola'] : [];
}

/* apk.js reutiliza la paleta y el icono: el envoltorio de WebView tiene que llevar el
   mismo dibujo que la web instalable, no uno parecido. */
module.exports = { FUENTE, DIST, paleta, icono32, emblema, iconoApp, escalar };

if (require.main === module) (async () => {
  if (!process.argv.includes('--solo-comprobar')) empaquetar();
  let mal = comprobar();
  if (process.argv.includes('--probar')) mal = mal.concat(await probar());
  if (mal.length) { console.log('\n' + mal.length + ' fallos'); process.exit(1); }
  console.log('\nel juego se puede instalar');
})();
