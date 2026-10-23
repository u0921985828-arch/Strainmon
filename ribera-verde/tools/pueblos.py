#!/usr/bin/env python3
"""Los pueblos de siempre, con su sitio propio (lo pidió el usuario: «toca también los otros para que sean de jugabilidad, pues
como estos… que no sea todo el mismo esquema de pueblo» y «más imperfecto… que no sea tan cuadrado. Pero que los píxeles sean
perfectos»). Solo con Datos.CAL: escribe PUEBLOS en godot/datos/datos.json y no toca los mapas de D.MAPS (el oráculo del HTML).

Cada pueblo gana un sitio que es suyo y se puede usar (un «hito»: un edificio sin puerta, que se mira con A) y trazados de forma
natural: plazas en mancha, sendas en curva, la hierba alta y las flores en corros. Los hitos van en casillas `hito_<suelo>`
(sólidas; debajo se pinta el suelo) con su `bld` (`"hito": id`):

  town (Ribera Verde)  el lavadero junto al río; la plaza en mancha y la senda de tierra en curva
  alto (barrio alto)   el jardín: el estanque, el quiosco de la música en su plazuela y las sendas
  astilleros           la grúa de pórtico vieja sobre la explanada
  mendialde            el frontón con su cancha; la ermita (se entra: ermita-in, con la serora)
  puerto               el espigón con el faro
  valdehierro          la chimenea de la fundición y la vía muerta del desguace
  errotabarri          manzanos sueltos y corros de flores
  ibarbide             la plaza con la estatua y el parque de abajo con su senda
  ensanche             el quiosco en la plaza y las sendas del parque

Sale `PUEBLOS = {MAPS: {k: {cambia: [[x, y, g, o, g0, o0]…], blds, doors}}, CLIENT_TILES, RONDA}` y la ermita en BILBAO.IN y su
gente en BILBAO.NPC (por eso va después de tools/bilbao.py). Comprueba que todo lo que se alcanzaba se sigue alcanzando, que nada
de lo protegido (puertas, personas, objetos de la historia, sitios fijos del código y de las pruebas) cambia y que los hitos no
pisan nada. Nada al azar: el ruido de las formas sale de un hash fijo."""
import json, math, os, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, "godot", "datos", "datos.json")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bilbao as BI   # noqa: E402

BLANDO = ("grass", "flowers", "tallgrass", "plaza", "dirt")       # el suelo que se puede rehacer
QUITABLE = (None, "tree", "tree2", "bench", "fountain", "manzano")  # lo que se puede quitar o poner
SOLIDO = ("water", "roof", "wall", "win", "iwT", "iwB", "void", "hito_", "via")

# sitios fijos del código (calle.gd, campo.gd, mundo.gd) y de las pruebas (enter_map de tests/*.gd): ni el suelo ni lo de encima
FIJOS = {
	"town": [(16, 17), (16, 16), (10, 9), (7, 12), (5, 9), (10, 10), (9, 2), (3, 10), (9, 3), (8, 8), (7, 14), (8, 14), (31, 9), (30, 9),
		(31, 8), (30, 8), (21, 22), (14, 10), (12, 10), (10, 12), (9, 1), (9, 0), (2, 28), (14, 28), (2, 29), (14, 29), (20, 19)]
		+ [(5, y) for y in range(10, 19)],   # la recta de la persecución de tests/ciclo.gd, del portal hacia abajo
	"valdehierro": [(17, 8), (23, 7), (15, 11), (23, 8), (12, 8), (12, 7)] + [(x, y) for x in range(21, 26) for y in range(12, 18)],
	"puerto": [(20, 9), (17, 9), (10, 10)] + [(x, y) for x in range(22, 27) for y in range(9, 15)],
	"mendialde": [(20, 19), (21, 19), (20, 20)] + [(x, y) for x in range(19, 24) for y in range(12, 18)],
	"errotabarri": [(7, 13), (24, 11)] + [(x, y) for x in range(12, 16) for y in range(14, 20)],
	"ensanche": [(38, 10), (38, 9)],
	"callejon": [(8, 11), (19, 8), (17, 9)],
	"ibarbide": [(19, 1), (10, 20)] + [(x, y) for x in range(3, 8) for y in range(22, 28)],
	"astilleros": [(6, 11), (24, 17), (25, 17)],
	"alto": [(36, 19), (31, 9), (31, 10)] + [(x, y) for x in range(27, 37) for y in range(2, 10)],
}
MAPAS = ["town", "alto", "astilleros", "mendialde", "puerto", "valdehierro", "errotabarri", "ibarbide", "ensanche"]


def h01(*a):
	"""un número de 0 a 1 por hash de los argumentos (siempre el mismo)"""
	v = 2166136261
	for c in repr(a).encode():
		v = ((v ^ c) * 16777619) & 0xFFFFFFFF
	return v / 4294967295.0


def protegidas(D):
	"""casillas que no se tocan, por mapa: todo dict con map/x/y de los datos, las señales, las paradas y su llegada, las puertas de
	las carreteras, las puertas y salidas de cada mapa y los FIJOS; y alrededor de cada una (que se pueda llegar y mirar)"""
	P = {k: set() for k in D["MAPS"]}
	def apunta(mp, x, y):
		if mp in P and isinstance(x, (int, float)) and isinstance(y, (int, float)):
			P[mp].add((int(x), int(y)))
	def recorre(v):
		if isinstance(v, dict):
			if isinstance(v.get("map"), str) and "x" in v and "y" in v:
				apunta(v["map"], v["x"], v["y"])
			for w in v.values():
				recorre(w)
		elif isinstance(v, list):
			for w in v:
				recorre(w)
	for k, v in D.items():
		if k not in ("MAPS", "BILBAO", "PUEBLOS"):
			recorre(v)
	for c in D["SIGNS"]:
		mp, xy = c.split(":")
		apunta(mp, *map(int, xy.split(",")))
	for mp, p in D["PARADAS"].items():
		apunta(mp, p["x"], p["y"])
		apunta(mp, p["a"][0], p["a"][1])
	for mp, L in D["CARRETERAS"]["puertas"].items():
		for q in L:
			apunta(mp, q[0], q[1])
	for mp, L in FIJOS.items():
		for c in L:
			apunta(mp, *c)
	for mp, m in D["MAPS"].items():
		for c in list(m["doors"]) + list(m["exits"]):
			x, y = map(int, c.split(","))
			apunta(mp, x, y)
			apunta(mp, x, y + 1)
	return P


class Mapa:
	def __init__(self, k, m, prot):
		self.k, self.m = k, m
		self.W, self.H = int(m["w"]), int(m["h"])
		self.g = [r[:] for r in m["g"]]
		self.o = [r[:] for r in m["o"]]
		self.prot = prot
		self.blds, self.doors = [], {}
		self.cerca = {(x + dx, y + dy) for x, y in prot for dx in (-1, 0, 1) for dy in (-1, 0, 1)}

	def dentro(self, x, y):
		return 0 < x < self.W - 1 and 0 < y < self.H - 1

	def suelo(self, x, y, g, sobre=BLANDO):
		"""cambia el suelo de una casilla blanda y libre de lo que no se quita"""
		if not self.dentro(x, y) or (x, y) in self.prot or self.g[y][x] not in sobre or self.o[y][x] not in QUITABLE:
			return False
		self.g[y][x] = g
		return True

	def obj(self, x, y, o, sobre=BLANDO + ("walk",)):
		"""pone o quita un objeto quitable (nunca al lado de lo protegido si es sólido)"""
		assert self.dentro(x, y) and self.o[y][x] in QUITABLE and self.g[y][x] in sobre, "%s: (%d, %d) %s/%s" % (self.k, x, y, self.g[y][x], self.o[y][x])
		assert o is None or (x, y) not in self.cerca, "%s: (%d, %d) junto a lo protegido" % (self.k, x, y)
		self.o[y][x] = o

	def quita(self, x, y, que):
		assert self.o[y][x] == que, "%s: en (%d, %d) hay %s, no %s" % (self.k, x, y, self.o[y][x], que)
		self.o[y][x] = None

	def mancha(self, cx, cy, rx, ry, g, sem, amp=0.22, sobre=BLANDO):
		"""una elipse con el borde ruidoso (tres armónicos por hash): plazas, charcas y corros sin esquinas de regla"""
		fs = [(h01(sem, i, "a") * 2 * math.pi, 0.5 + h01(sem, i, "b")) for i in range(3)]
		dentro = set()
		for y in range(int(cy - ry) - 2, int(cy + ry) + 3):
			for x in range(int(cx - rx) - 2, int(cx + rx) + 3):
				dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
				t = math.atan2(dy, dx)
				r = 1 + amp * sum(a * math.sin((i + 2) * t + f) for i, (f, a) in enumerate(fs)) / 2
				if dx * dx + dy * dy <= r * r:
					dentro.add((x, y))
		# sin picos de una casilla: fuera lo que toca menos de dos vecinas (se repite hasta que no cambie)
		while True:
			sueltas = {c for c in dentro if sum((c[0] + a, c[1] + b) in dentro for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))) < 2}
			if not sueltas:
				break
			dentro -= sueltas
		for x, y in sorted(dentro, key=lambda c: (c[1], c[0])):
			self.suelo(x, y, g, sobre)

	def senda(self, pts, ancho, g, sobre=BLANDO):
		"""un camino en curva (Catmull-Rom por los puntos) de `ancho` casillas"""
		P = [pts[0]] + list(pts) + [pts[-1]]
		for i in range(1, len(P) - 2):
			p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
			n = int(math.hypot(p2[0] - p1[0], p2[1] - p1[1]) * 6) + 2
			for j in range(n + 1):
				t = j / n
				q = [0.5 * ((2 * p1[c]) + (-p0[c] + p2[c]) * t + (2 * p0[c] - 5 * p1[c] + 4 * p2[c] - p3[c]) * t * t
					+ (-p0[c] + 3 * p1[c] - 3 * p2[c] + p3[c]) * t * t * t) for c in (0, 1)]
				r = ancho / 2
				for y in range(int(q[1] - r) - 1, int(q[1] + r) + 2):
					for x in range(int(q[0] - r) - 1, int(q[0] + r) + 2):
						if math.hypot(x + 0.5 - q[0], y + 0.5 - q[1]) <= r:
							self.suelo(x, y, g, sobre)

	def rect(self, x0, y0, x1, y1, g, sobre=BLANDO):
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				self.suelo(x, y, g, sobre)

	def hito(self, hid, x0, y0, w, h, sobre, puerta=None, agua=False, junto=False):
		"""un edificio de hito: casillas hito_<suelo> (sólidas, con el suelo debajo) y su bld; con `puerta` = (x, to, gate, llega),
		las dos casillas de la puerta (door_<id>) y la entrada"""
		for y in range(y0, y0 + h):
			for x in range(x0, x0 + w):
				assert (x, y) not in (self.prot if junto else self.cerca), "%s: el hito %s pisa (%d, %d), protegida" % (self.k, hid, x, y)
				assert self.o[y][x] in QUITABLE and (agua or not self.g[y][x].startswith(SOLIDO)), "%s: el hito %s pisa %s/%s en (%d, %d)" % (self.k, hid, self.g[y][x], self.o[y][x], x, y)
				self.o[y][x] = None
				self.g[y][x] = "hito_" + sobre
		b = {"id": hid, "x0": x0, "y0": y0, "w": w, "h": h, "hito": hid}
		if puerta:
			dx, to, gate, llega = puerta
			dy = y0 + h - 1
			b["doorX"], b["ancha"] = dx, 1
			for i in (0, 1):
				self.g[dy][dx + i] = "door_" + hid
				self.doors["%d,%d" % (dx + i, dy)] = {"to": to, "x": llega[0] + i, "y": llega[1], "dir": "up", "gate": gate}
		self.blds.append(b)


# ---------------- cada pueblo ----------------

def town(M):
	"""Ribera Verde: la plaza en mancha alrededor de la fuente, el lavadero junto al río, la senda de tierra en curva y la hierba
	alta en corros"""
	M.rect(13, 13, 26, 25, "grass", ("plaza",))
	for x, y in ((16, 22), (24, 16), (24, 22)):
		M.quita(x, y, "bench")
	M.mancha(20, 18.6, 6.6, 5.4, "plaza", "town-plaza", 0.2)
	M.senda([(18.5, 12.6), (19, 14.5)], 3, "plaza")              # la entrada desde la acera
	M.senda([(14, 23), (16.5, 21)], 2, "plaza")                   # la de la senda de tierra
	M.senda([(25, 17.5), (27.6, 17.6)], 2, "plaza")               # hacia el lavadero
	M.quita(28, 15, "tree")
	M.hito("lavadero", 27, 14, 4, 3, "grass")
	M.rect(5, 13, 6, 27, "grass", ("dirt",))                      # la L de tierra, en curva
	M.rect(6, 22, 13, 23, "grass", ("dirt",))
	M.senda([(5.5, 12.6), (5.8, 16), (7.4, 19.4), (10, 22.2), (13.6, 22.8)], 2.2, "dirt", ("grass", "tallgrass", "flowers", "dirt"))
	M.senda([(6.6, 19.6), (5.6, 23.5), (5.8, 27.6)], 1.8, "dirt", ("grass", "tallgrass", "flowers", "dirt"))
	M.rect(7, 18, 10, 20, "grass", ("tallgrass",))
	M.mancha(9.4, 19.3, 2.6, 1.7, "tallgrass", "town-alta", 0.3, ("grass",))
	M.rect(1, 21, 3, 23, "grass", ("tallgrass",))
	M.mancha(2.2, 22.4, 1.9, 1.7, "tallgrass", "town-alta2", 0.3, ("grass",))
	M.obj(24, 20, "bench")
	M.obj(17, 23, "bench")


def alto(M):
	"""el barrio alto: la plaza dura pasa a jardín (el estanque, el quiosco de la música en su plazuela, sendas de tierra, corros
	de flores y árboles sueltos); las farolas y los arbustos, donde estaban"""
	M.rect(3, 4, 19, 17, "grass", ("plaza", "flowers"))
	M.quita(11, 11, "fountain")
	for x, y in ((7, 8), (15, 8), (7, 14), (15, 14)):
		M.quita(x, y, "bench")
	M.mancha(7.2, 12.6, 3.1, 2.1, "water", "alto-agua", 0.18, ("grass",))
	M.hito("kiosko", 13, 7, 3, 2, "plaza")
	M.mancha(14.5, 8.6, 3.4, 2.5, "plaza", "alto-kiosko", 0.15, ("grass",))
	M.senda([(11.5, 18.4), (12.2, 15.6), (13.4, 12.6), (14.4, 10.4)], 1.6, "dirt", ("grass",))
	M.senda([(13, 10.2), (9.6, 8.2), (6, 6.8), (3.6, 5.6)], 1.4, "dirt", ("grass",))
	M.senda([(15.8, 10.4), (17.6, 13), (19.6, 15.6)], 1.4, "dirt", ("grass",))
	for i, (cx, cy, rx, ry) in enumerate(((4.6, 16.2, 1.8, 1.0), (17.2, 5.2, 2.2, 1.0), (10.4, 15.6, 1.6, 0.9), (17.8, 16.6, 1.4, 0.8))):
		M.mancha(cx, cy, rx, ry, "flowers", "alto-flor%d" % i, 0.3, ("grass",))
	for x, y, o in ((4, 9, "tree"), (11, 5, "tree2"), (18, 10, "tree"), (8, 16, "tree2")):
		M.obj(x, y, o)
	for x, y in ((12, 16), (10, 7), (17, 12)):
		M.obj(x, y, "bench")


def astilleros(M):
	"""los astilleros: la grúa de pórtico vieja sobre la explanada y la hierba alta en corro"""
	M.rect(30, 13, 35, 15, "dirt", ("tallgrass",))
	M.hito("gruaT", 27, 11, 4, 7, "dirt")
	M.mancha(34.2, 14.2, 2.4, 1.7, "tallgrass", "ast-alta", 0.3, ("dirt",))


def mendialde(M):
	"""Mendialde: el frontón con su cancha en la plaza (y un corro de plaza junto a la parada) y la ermita, que se entra"""
	M.quita(24, 22, "fountain")
	for x, y in ((21, 23), (27, 23)):
		M.quita(x, y, "bench")
	M.rect(18, 19, 29, 26, "grass", ("plaza",))
	M.hito("fronton", 23, 19, 6, 3, "grass", junto=True)   # la vecina anda al lado
	M.rect(22, 22, 29, 25, "hormigon", ("grass",))               # la cancha (las canchas sí son rectas)
	M.mancha(20.4, 21.6, 2.8, 2.6, "plaza", "men-plaza", 0.2, ("grass",))
	M.senda([(20.6, 23.5), (21.6, 25.6), (24, 26.6), (27, 26.6)], 1.6, "plaza", ("grass",))
	M.quita(25, 10, "manzano")
	M.hito("ermita", 24, 7, 4, 4, "grass", (25, "ermita-in", "iglesia:ermita", (5, 9)))
	M.senda([(25.6, 11.2), (25.4, 11.6)], 2, "plaza", ("grass",))   # el atrio, delante de la puerta


def puerto(M):
	"""Puerto Viejo: el espigón de piedra que sale del paseo y el faro en la punta"""
	for x in range(36, 39):
		for y in (16, 17):
			M.g[y][x] = "muelleP"
	for y in range(18, 24):
		M.g[y][36] = "muelleP"
	M.quita(36, 15, "fence")
	M.hito("faro", 37, 18, 2, 5, "water", agua=True)
	for x, y in ((6, 21), (32, 19)):                      # los norays, en la punta de los pantalanes
		if M.g[y][x] == "dock" and not M.o[y][x]:
			M.o[y][x] = "noray"


def valdehierro(M):
	"""Valdehierro: la chimenea de la fundición en el desguace y su vía muerta"""
	M.quita(28, 21, "tree2")
	M.hito("chimenea", 27, 16, 2, 6, "dirt")
	for x in range(31, 38):                                         # la vía muerta, corta y al fondo: la valla, encima de la tierra
		if M.g[21][x] == "dirt" and not M.o[21][x]:
			M.g[21][x] = "via"
	M.rect(30, 17, 33, 19, "dirt", ("tallgrass",))
	M.mancha(31.6, 18.2, 2.3, 1.5, "tallgrass", "val-alta", 0.3, ("dirt",))


def errotabarri(M):
	"""Errotabarri: la huerta cercada en corro, manzanos sueltos, flores y el colmenar (la miel, ciudad.gd)"""
	M.mancha(6.8, 17.3, 1.7, 0.8, "grass", "err-claro", 0.3, ("tallgrass",))   # un claro en medio; junto a la valla, la hierba alta que acota
	for i, (cx, cy, rx, ry) in enumerate(((10.4, 20.4, 2.2, 0.9), (30.4, 9.6, 1.8, 1.0), (14.2, 4.4, 1.4, 0.9))):
		M.mancha(cx, cy, rx, ry, "flowers", "err-flor%d" % i, 0.3, ("grass",))
	for x, y in ((9, 21), (31, 21), (4, 21)):
		M.obj(x, y, "manzano")
	M.hito("colmenas", 13, 4, 3, 2, "grass")                      # el colmenar, arriba, junto al río


def ibarbide(M):
	"""Ibarbide: la plaza con la torre del reloj en el centro (esperar a una hora, ciudad.gd) y plátanos sueltos; el parque de abajo,
	de hierba con su senda"""
	M.quita(21, 14, "fountain")
	M.rect(19, 13, 23, 15, "plaza", ("grass", "flowers"))
	M.hito("reloj", 21, 11, 2, 5, "plaza")                         # la torre del reloj, en medio de la plaza
	for x, y in ((15, 15), (27, 14), (18, 10)):
		M.obj(x, y, "platano", ("plaza",))
	M.rect(1, 24, 42, 27, "grass", ("dirt",))
	M.senda([(8.6, 23.6), (10.4, 25.4), (16, 26.1), (22, 25.4), (29, 26.3), (35.6, 25.1), (38.4, 23.6)], 2, "dirt", ("grass", "flowers"))


def ensanche(M):
	"""el Ensanche: el quiosco de prensa en la plaza (el periódico, ciudad.gd), que se rehace en mancha, y las sendas del parque en
	curva"""
	M.quita(22, 16, "fountain")
	M.rect(18, 14, 27, 19, "grass", ("plaza",))
	M.mancha(22.6, 16.4, 5.4, 3.3, "plaza", "ens-plaza", 0.16, ("grass", "dirt"))
	M.rect(21, 13, 24, 14, "plaza", ("grass", "plaza"))
	M.hito("prensa", 21, 15, 2, 2, "plaza", junto=True)   # el quiosco de prensa (la de Ibarbide anda por la plaza)
	M.rect(1, 16, 17, 18, "grass", ("dirt",))
	M.rect(26, 16, 44, 18, "grass", ("dirt",))
	M.rect(7, 13, 9, 15, "grass", ("dirt",))
	M.rect(36, 13, 38, 15, "grass", ("dirt",))
	B = ("grass", "flowers", "dirt")
	M.senda([(8, 12.8), (8.3, 15.4), (12, 17.1), (17.6, 17.2)], 2.2, "dirt", B)
	M.senda([(8.3, 15.4), (4.4, 17.3), (1.2, 17.1)], 1.8, "dirt", B)
	M.senda([(37, 12.8), (36.6, 15.4), (32, 17.0), (27.6, 16.8)], 2.2, "dirt", B)
	M.senda([(36.6, 15.4), (40.6, 17.2), (44.6, 16.6)], 1.8, "dirt", B)


HACE = {"town": town, "alto": alto, "astilleros": astilleros, "mendialde": mendialde, "puerto": puerto, "valdehierro": valdehierro,
	"errotabarri": errotabarri, "ibarbide": ibarbide, "ensanche": ensanche}


COPA_N = {"tree": (2, 6), "tree2": (2, 6), "platano": (2, 6), "manzano": (2, 4)}


def alcance(m, g, o, extra_bld=(), desde=()):
	"""lo que se alcanza andando desde las puertas, las salidas, las paradas y las casillas de las carreteras"""
	W, H = int(m["w"]), int(m["h"])
	bld = {(x, y) for b in list(m["blds"]) + list(extra_bld) for x in range(int(b["x0"]), int(b["x0"]) + int(b["w"]))
		for y in range(int(b["y0"]), int(b["y0"]) + int(b["h"]))}
	puertas = {tuple(map(int, c.split(","))) for c in list(m["doors"]) + list(m["exits"])}
	libre = lambda x, y: 0 <= x < W and 0 <= y < H and (((x, y) not in bld and not o[y][x] and not g[y][x].startswith(SOLIDO)) or (x, y) in puertas)
	ini = [(x, y + 1) for x, y in puertas] + list(puertas) + list(desde)
	va = set(c for c in ini if libre(*c))
	cola = list(va)
	while cola:
		x, y = cola.pop()
		for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			q = (x + dx, y + dy)
			if q not in va and libre(*q):
				va.add(q)
				cola.append(q)
	return va


def main():
	D = json.load(open(DATOS, encoding="utf-8"))
	prot = protegidas(D)
	P = {"_": "Los pueblos de siempre con su sitio propio y trazados naturales (con Datos.CAL; tools/pueblos.py): cambia = [x, y, suelo, objeto, suelo de antes, objeto de antes]; mundo.gd (pueblos_mapa) los pone y los quita al entrar; los hitos (bld con «hito»), en ciudad.gd (hito_obj).",
		"MAPS": {}, "CLIENT_TILES": {}, "RONDA": {}}
	ermita = None
	for k in MAPAS:
		m = D["MAPS"][k]
		M = Mapa(k, m, prot.get(k, set()))
		HACE[k](M)
		# lo que se alcanzaba se sigue alcanzando (salvo lo que pasa a ser sólido)
		desde = [tuple(D["PARADAS"][k]["a"][:2])] if k in D["PARADAS"] else []
		desde += [(q[0] + (1 if q[0] == 0 else -1 if q[0] == M.W - 1 else 0), q[1] - (1 if q[1] == M.H - 1 else 0)) for q in D["CARRETERAS"]["puertas"].get(k, [])]
		ant = alcance(m, m["g"], m["o"], (), desde)
		nue = alcance({**m, "doors": {**m["doors"], **M.doors}}, M.g, M.o, M.blds, desde)
		hb = {(x, y) for b in M.blds for x in range(b["x0"], b["x0"] + b["w"]) for y in range(b["y0"], b["y0"] + b["h"])}
		perd = [c for c in ant - nue if c not in hb and not M.o[c[1]][c[0]] and not M.g[c[1]][c[0]].startswith(SOLIDO)]
		assert not perd, "%s: ya no se llega a %s" % (k, sorted(perd)[:12])
		for c in prot.get(k, ()):
			x, y = c
			if 0 <= x < M.W and 0 <= y < M.H:
				assert (M.g[y][x], M.o[y][x]) == (m["g"][y][x], m["o"][y][x]) or M.g[y][x].startswith("door_"), "%s: protegida (%d, %d) cambiada" % (k, x, y)
		cambia = [[x, y, M.g[y][x], M.o[y][x], m["g"][y][x], m["o"][y][x]] for y in range(M.H) for x in range(M.W)
			if (M.g[y][x], M.o[y][x]) != (m["g"][y][x], m["o"][y][x])]
		P["MAPS"][k] = {"cambia": cambia, "blds": M.blds, "doors": M.doors}
		# (revisión: «los clientes salen debajo de las copas»): bajo la copa de un árbol nuevo no sale ninguno (COPA de 04-mapas.js,
		# con una columna y una fila más por el desfase de la copa)
		tap = set()
		for y in range(M.H):
			for x in range(M.W):
				c = COPA_N.get(M.o[y][x])
				if c and M.o[y][x] != m["o"][y][x]:
					tap |= {(i, j) for j in range(y - c[1], y) for i in range(x - c[0], x + c[0] + 1)}
		for t in ("CLIENT_TILES", "RONDA"):
			P[t][k] = [c for c in D[t].get(k, []) if ((c[0], c[1]) in nue or (c[0], c[1]) not in ant) and not M.o[c[1]][c[0]] and not M.g[c[1]][c[0]].startswith(SOLIDO)
				and (t == "RONDA" or (c[0], c[1]) not in tap)]
		print("%-12s %4d casillas, hitos %s, clientes %d → %d" % (k, len(cambia), [b["id"] for b in M.blds], len(D["CLIENT_TILES"].get(k, [])), len(P["CLIENT_TILES"][k])))
	# la ermita por dentro (como las iglesias de Bilbao) y la serora
	e = BI.iglesia_in("ermita", "La ermita", 12, 11, "mendialde", 25, 11)
	for row in e["o"]:
		for x in range(len(row) - 1):
			if row[x] in BI.IN_ANCHO:
				row[x + 1] = row[x] + "2"
	llega = [int(c.split(",")[0]) for c in e["exits"]][0]
	for c, d in P["MAPS"]["mendialde"]["doors"].items():
		d["x"] = llega + (int(c.split(",")[0]) - 25)
		d["y"] = e["h"] - 2
	B = D["BILBAO"]
	B["IN"]["ermita-in"] = e
	B["NPC"] = [n for n in B["NPC"] if n["id"] != "bi_serora"]
	cx = e["w"] // 2 - 1
	assert not e["o"][3][cx + 2]
	B["NPC"].append({"id": "bi_serora", "map": "ermita-in", "x": cx + 2, "y": 3, "look": "granny", "dir": "down", "wander": 0, "desde": 480, "hasta": 1200})
	D["PUEBLOS"] = P
	with open(DATOS, "w", encoding="utf-8") as f:
		json.dump(D, f, ensure_ascii=False, separators=(",", ":"))
	print("PUEBLOS escrito: %d mapas, la ermita en BILBAO.IN" % len(P["MAPS"]))


if __name__ == "__main__":
	main()
