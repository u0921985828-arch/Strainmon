/*
 * Landrace Hunters — el juego, guardado en el móvil (lo pidió el usuario: «que el host esté mucho más libre»).
 *
 * El servidor solo entrega los archivos la primera vez: a partir de ahí este trabajador los saca de la caché del
 * propio navegador, así que abrir el juego no le cuesta nada al servidor y arranca aunque no haya conexión.
 * La caché lleva la versión del plugin en el nombre: al actualizar se baja todo otra vez y se borran las viejas.
 *
 * Se sirve desde la dirección del juego (landrace-hunters.php, ?landrace_hunters=sw) para que su ámbito sea esa
 * página; el PHP le pone arriba la versión y la lista de archivos.
 *
 * 1.7.6 — las piezas gordas se guardan al pasar (lo dijo el usuario: «la carga del juego en web tarda muchísimo»).
 * Hasta la 1.7.5 el trabajador se bajaba el juego entero al instalarse, además de la descarga que hacía el propio
 * motor para arrancar: la primera visita bajaba 119,7 MB en vez de 60. Ahora al instalarse solo guarda lo pequeño
 * (que ya está en la caché del navegador: `no-cache` lo revalida y el servidor contesta 304, sin cuerpo) y el
 * index.wasm y el index.pck se guardan de la misma descarga con la que arranca el juego, al pasar por aquí.
 * Para eso la página espera a que este trabajador mande antes de arrancar el motor (LH_SW en index.html).
 */
/* global LH_CACHE, LH_FILES, LH_SIZES, LH_PAGE */

const CACHE = typeof LH_CACHE === 'string' ? LH_CACHE : 'lh-dev';
const FILES = typeof LH_FILES === 'object' ? LH_FILES : [];
const SIZES = typeof LH_SIZES === 'object' && LH_SIZES ? LH_SIZES : {};
const PAGE = typeof LH_PAGE === 'string' ? LH_PAGE : '';
const ENTERA = 'lh-entera';   // 1.7.5: la marca de que todo lo guardado está entero

// al instalar, solo lo pequeño: el motor del juego (index.js), los worklets de audio y las imágenes. `no-cache`
// pregunta al servidor si cambió; si es el mismo contesta 304 y el cuerpo sale de la caché del navegador, que
// acaba de bajarlo para la página, así que no se baja dos veces. Las piezas gordas (las de LH_SIZES: index.wasm
// e index.pck) no se piden aquí: se guardan al pasar por el fetch de abajo, de la descarga del propio motor.
self.addEventListener('install', (e) => {
	e.waitUntil((async () => {
		const c = await caches.open(CACHE);
		await Promise.all(FILES.filter((u) => !SIZES[u]).map(async (u) => {
			try {
				const r = await fetch(new Request(u, { cache: 'no-cache', credentials: 'same-origin' }));
				if (r.ok) await c.put(u, r);
			} catch (err) { /* lo que falle se pedirá a la red al usarlo */ }
		}));
		await marca(c);
		self.skipWaiting();
	})());
});

// al activarse, a mandar ya en la página abierta (así el motor arranca con el trabajador puesto y lo que baje
// se queda guardado) y fuera las cachés de versiones anteriores, pero solo si la nueva está entera (1.7.5):
// si algo llegó a medias, más vale seguir jugando con la de la versión anterior que quedarse sin nada
self.addEventListener('activate', (e) => {
	e.waitUntil((async () => {
		await limpia(await caches.open(CACHE));
		await self.clients.claim();
	})());
});

/** Con todas las piezas guardadas, la instalación está entera: se marca y se borran las cachés viejas. */
async function marca(c) {
	for (const u of FILES) {
		if (!(await c.match(u))) return false;
	}
	await c.put(ENTERA, new Response('1'));
	await limpia(c);
	return true;
}

async function limpia(c) {
	if (!(await c.match(ENTERA))) return;
	for (const k of await caches.keys()) {
		if (k !== CACHE && k.startsWith('lh-')) await caches.delete(k);
	}
}

/**
 * Guarda una pieza de la descarga que acaba de pasar por aquí, sin entretener al juego.
 *
 * Lo que llega a medias (una descarga cortada, o una pieza corta en el servidor) no se queda guardado: con el
 * .pck corto el juego se queda en negro con «Failed loading file», y así la próxima vez se vuelve a pedir a la
 * red en vez de quedarse roto para siempre. El tamaño se mide ya guardado, que es el de verdad aunque el
 * servidor lo haya mandado comprimido.
 */
async function guarda(k, r, debe) {
	const c = await caches.open(CACHE);
	try {
		await c.put(k, r);
	} catch (err) { return; }   // descarga cortada: cache.put falla y no se guarda nada
	if (debe) {
		const hit = await c.match(k);
		const b = hit ? await hit.blob() : null;
		if (!b || b.size !== debe) { await c.delete(k); return; }
	}
	await marca(c);
}

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
		// no estaba: a la red, el juego se lleva la descarga tal cual y la copia se guarda por detrás
		const r = await fetch(q);
		if (!r.ok) return r;
		const p = guarda(k, r.clone(), SIZES[k] || 0);
		try { e.waitUntil(p); } catch (err) { /* el navegador ya no deja alargar el evento */ }
		return r;
	})());
});
