/*
 * Landrace Hunters — el juego, guardado en el móvil (lo pidió el usuario: «que el host esté mucho más libre»).
 *
 * El servidor solo entrega los archivos la primera vez: a partir de ahí este trabajador los saca de la caché del
 * propio navegador, así que abrir el juego no le cuesta nada al servidor y arranca aunque no haya conexión.
 * La caché lleva la versión del plugin en el nombre: al actualizar se baja todo otra vez y se borran las viejas.
 *
 * Se sirve desde la dirección del juego (landrace-hunters.php, ?landrace_hunters=sw) para que su ámbito sea esa
 * página; el PHP le pone arriba la versión y la lista de archivos.
 */
/* global LH_CACHE, LH_FILES, LH_SIZES, LH_PAGE */

const CACHE = typeof LH_CACHE === 'string' ? LH_CACHE : 'lh-dev';
const FILES = typeof LH_FILES === 'object' ? LH_FILES : [];
const SIZES = typeof LH_SIZES === 'object' && LH_SIZES ? LH_SIZES : {};
const PAGE = typeof LH_PAGE === 'string' ? LH_PAGE : '';
const ENTERA = 'lh-entera';   // 1.7.5: la marca de que todo lo guardado está entero

// al instalar, todo a la caché; `reload` se salta la caché del navegador, para no guardar la versión vieja.
// Lo que llega a medias (una descarga cortada) no se guarda: con el .pck corto el juego se queda en negro
// con «Failed loading file», y así la próxima vez se vuelve a pedir a la red en vez de quedarse roto para siempre.
self.addEventListener('install', (e) => {
	e.waitUntil((async () => {
		const c = await caches.open(CACHE);
		let entera = true;
		await Promise.all(FILES.map(async (u) => {
			try {
				const r = await fetch(new Request(u, { cache: 'reload', credentials: 'same-origin' }));
				if (!r.ok) { entera = false; return; }
				const debe = SIZES[u] || 0;
				if (!debe) { await c.put(u, r); return; }
				const b = await r.blob();   // el navegador ya lo descomprime: el tamaño es el de verdad
				if (b.size !== debe) { entera = false; return; }
				await c.put(u, new Response(b, { status: 200, headers: { 'Content-Type': r.headers.get('content-type') || 'application/octet-stream' } }));
			} catch (err) { entera = false; }
		}));
		if (entera) await c.put(ENTERA, new Response('1'));
		self.skipWaiting();
	})());
});

// al activarse, fuera las cachés de versiones anteriores, pero solo si la nueva está entera (1.7.5):
// si algo llegó a medias, más vale seguir jugando con la de la versión anterior que quedarse sin nada
self.addEventListener('activate', (e) => {
	e.waitUntil((async () => {
		const c = await caches.open(CACHE);
		if (await c.match(ENTERA)) {
			for (const k of await caches.keys()) {
				if (k !== CACHE && k.startsWith('lh-')) await caches.delete(k);
			}
		}
		await self.clients.claim();
	})());
});

// lo guardado sale de la caché; lo demás (el manifiesto, los ajustes) va a la red como siempre
self.addEventListener('fetch', (e) => {
	const q = e.request;
	if (q.method !== 'GET' || new URL(q.url).origin !== self.location.origin) return;
	const k = q.url.split('?')[0];
	// la página del juego: primero la red (así se ve la versión nueva en cuanto la hay) y, si no hay, la última guardada
	if (q.mode === 'navigate' && PAGE && k === PAGE.split('?')[0]) {
		e.respondWith((async () => {
			try {
				const r = await fetch(q);
				if (r.ok) (await caches.open(CACHE)).put('lh-pagina', r.clone());
				return r;
			} catch (err) {
				const hit = await caches.match('lh-pagina');
				if (hit) return hit;
				throw err;
			}
		})());
		return;
	}
	if (!FILES.includes(k)) return;
	e.respondWith((async () => {
		const c = await caches.open(CACHE);
		const hit = await c.match(k);
		if (hit) return hit;
		// no estaba (o llegó a medias al instalar): a la red, y solo se guarda si viene entero
		const r = await fetch(q);
		if (!r.ok) return r;
		const debe = SIZES[k] || 0;
		if (!debe) { c.put(k, r.clone()); return r; }
		const b = await r.blob();
		const res = new Response(b, { status: 200, headers: { 'Content-Type': r.headers.get('content-type') || 'application/octet-stream' } });
		if (b.size === debe) c.put(k, res.clone());
		return res;
	})());
});
