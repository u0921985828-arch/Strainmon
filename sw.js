/* ============================================================
   Strainmon — Service Worker
   Precachea el app-shell (HTML, CSS, JS, iconos) para jugar sin
   conexión. Estrategia cache-first: mínima transferencia de datos
   en visitas repetidas (web sostenible). Sube CACHE_VERSION al
   publicar cambios para invalidar la caché anterior.
   ============================================================ */
const CACHE_VERSION = 'strainmon-v1';
const ASSETS = [
  './',
  'index.html',
  'manifest.webmanifest',
  'assets/style.css',
  'assets/icons/icon-192.png',
  'assets/icons/icon-512.png',
  'src/util.js', 'src/genetics.js', 'src/species.js', 'src/items.js',
  'src/world.js', 'src/render.js', 'src/sprites.js', 'src/plantart.js',
  'src/state.js', 'src/quests.js', 'src/events.js', 'src/research.js',
  'src/garden.js', 'src/encounter.js', 'src/ui.js', 'src/charart.js',
  'src/furniart.js', 'src/audio.js', 'src/heat.js', 'src/iso.js', 'src/isogame.js',
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_VERSION)
      .then((c) => c.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE_VERSION).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  // Solo gestionamos peticiones del propio origen (todo es local).
  if (new URL(req.url).origin !== self.location.origin) return;
  e.respondWith(
    caches.match(req).then((hit) => hit || fetch(req).then((res) => {
      // Cachea al vuelo cualquier recurso local nuevo.
      if (res && res.status === 200 && res.type === 'basic') {
        const copy = res.clone();
        caches.open(CACHE_VERSION).then((c) => c.put(req, copy));
      }
      return res;
    }).catch(() => caches.match('index.html')))
  );
});
