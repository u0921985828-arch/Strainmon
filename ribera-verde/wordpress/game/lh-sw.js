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
/* global LH_CACHE, LH_FILES, LH_PAGE */

const CACHE = typeof LH_CACHE === 'string' ? LH_CACHE : 'lh-dev';
const FILES = typeof LH_FILES === 'object' ? LH_FILES : [];
const PAGE = typeof LH_PAGE === 'string' ? LH_PAGE : '';

// al instalar, todo a la caché; `reload` se salta la caché del navegador, para no guardar la versión vieja
self.addEventListener('install', (e) => {
	e.waitUntil((async () => {
		const c = await caches.open(CACHE);
		await Promise.all(FILES.map(async (u) => {
			try {
				const r = await fetch(new Request(u, { cache: 'reload', credentials: 'same-origin' }));
				if (r.ok) await c.put(u, r);
			} catch (err) { /* sin conexión o archivo que no está: el juego lo pedirá a la red */ }
		}));
		self.skipWaiting();
	})());
});

// al activarse, fuera las cachés de versiones anteriores
self.addEventListener('activate', (e) => {
	e.waitUntil((async () => {
		for (const k of await caches.keys()) {
			if (k !== CACHE && k.startsWith('lh-')) await caches.delete(k);
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
		const r = await fetch(q);
		if (r.ok) c.put(k, r.clone());
		return r;
	})());
});
