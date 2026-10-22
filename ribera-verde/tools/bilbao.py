#!/usr/bin/env python3
# Landrace Hunters — los mapas de Bilbao (lo pidió el usuario: «Los mapas del juego hazlos los más parecidos y realistas a Bilbao
# centro y sus barrios, Zorroza no puede faltar, investiga las zonas como son»). Escribe en godot/datos/datos.json la clave BILBAO
# (con Datos.CAL, Datos._aplica_auto la pone en lugar de los mapas de siempre; sin CAL, los de siempre: el oráculo no cambia):
#   town        → Zorroza: el barrio al pie del monte, la calle de siempre, el parque, la plaza, la estación con la vía del tren
#                 (las dos vías que cortan el barrio, con sus pasos a nivel) y la ría con su muelle y la barandilla verde;
#   alto        → Zazpi Landa: las torres de pisos de la ladera y las campas;
#   astilleros  → La Punta: el muelle de piedra con las grúas de pórtico, la ría y los pabellones;
#   ibarbide    → el Casco Viejo: las casas estrechas en hilera, los cantones, el adoquín, la plaza porticada, la catedral, el
#                 teatro, el mercado sobre la ría, la Ribera con su barandilla y el puente de piedra;
#   ensanche    → Abando: la Gran Vía con plátanos en alcorque, las casas del Ensanche con miradores, la plaza ovalada con su
#                 fuente y la boca del metro de cristal;
#   callejon    → un cantón del Casco Viejo, de adoquín.
# Los nombres del juego no cambian (Ribera Verde, Ibarbide…): solo la forma. Lo que se nombra desde fuera (puertas, salidas,
# personas, objetos escondidos, carteles, paradas, clubs, locales, estancos, el concesionario, el garaje, la huerta, las carreteras)
# se queda en su casilla: la herramienta lo comprueba y sale con 1 si algo se mueve o se tapa.
#   python3 -I tools/bilbao.py
import json
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, "godot", "datos", "datos.json")

# carácter → (suelo, objeto); «%» deja la casilla como estaba; «#» es de un edificio (lo pone la lista de edificios)
LEY = {
	".": ("walk", None), ",": ("plaza", None), "h": ("hormigon", None), "k": ("adoq", None), "m": ("muelleP", None),
	"_": ("muelleP", "baranda"), "g": ("grass", None), "f": ("flowers", None), "d": ("dirt", None), "~": ("water", None),
	"D": ("dock", None), "c": ("dock", "crate"), "[": ("bridgeT", None), "]": ("bridgeB", None), "T": ("roadT", None),
	"U": ("roadB", None), "=": ("via", None), "H": ("viaV", None), "x": ("viaX", None), "X": ("viaXV", None),
	"Y": ("walk", "tree2"), "y": ("grass", "tree"), "l": ("walk", "lamp"), "L": ("plaza", "lamp"), "b": ("walk", "bench"),
	"n": ("plaza", "bench"), "*": ("grass", "bush"), "+": ("walk", "bush"), "S": ("walk", "sign"), "F": ("plaza", "fountain"),
	"M": ("grass", "monte"), "W": ("grass", "monte2"), "s": ("grass", "seto"), "P": ("walk", "parada"), "$": ("walk", "cajero"),
	"R": ("walk", "rotuloL"), "|": ("walk", "fence"), "Z": ("adoq", "tree2"), "j": ("adoq", "lamp"), "q": ("adoq", "bench"),
	"Q": ("hormigon", "crate"), "e": ("hormigon", "lamp"), "o": ("muelleP", "noray"), "B": ("walk", "metroB"),
	"t": ("hormigon", "tree2"), "&": ("hormigon", "fence"), "A": ("walk", "platano"), "a": ("plaza", "platano"),
}
CAMBIA_HIERBA = {"grass": "walk", "flowers": "walk", "tallgrass": "walk"}


def lienzo(w, h, c):
	return [[c] * w for _ in range(h)]


def pon(C, x0, y0, filas):
	"""escribe un bloque de texto en C a partir de (x0, y0)"""
	for j, f in enumerate(filas):
		for i, ch in enumerate(f):
			if ch != " ":
				C[y0 + j][x0 + i] = ch


def rect(C, x0, y0, x1, y1, ch):
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			C[y][x] = ch


def construye(k, M0, C, blds, G=None):
	"""el mapa nuevo: C (caracteres) sobre el de siempre M0; blds, los edificios (los de puerta, copiados tal cual); G, el suelo
	nuevo de las casillas que conservan su objeto"""
	w, h = int(M0["w"]), int(M0["h"])
	g = [list(r) for r in M0["g"]]
	o = [list(r) for r in M0["o"]]
	for (x, y), t in (G or {}).items():
		g[y][x] = t
	for y in range(h):
		for x in range(w):
			ch = C[y][x]
			if ch in ("%", "#"):
				continue
			g[y][x], o[y][x] = LEY[ch]
			if o[y][x] == "metroB" and x + 1 < w:
				g[y][x + 1], o[y][x + 1] = "walk", "metroB2"
	nb = []
	for b in blds:
		b = dict(b)
		orig = b.pop("orig", False)
		x0, y0, bw, bh = int(b["x0"]), int(b["y0"]), int(b["w"]), int(b["h"])
		ver = b.get("fachada", b["id"])
		for y in range(y0, y0 + bh):
			for x in range(x0, x0 + bw):
				if not orig:
					assert C[y][x] == "#", "%s: (%d, %d) no es de edificio (%s, %s)" % (k, x, y, C[y][x], ver)
					g[y][x] = ("roofT_" if y == y0 else "roofB_" if y == y0 + 1 else "wall_") + b["id"]
				o[y][x] = None
		nb.append(b)
	for y in range(h):
		for x in range(w):
			if C[y][x] == "#":
				assert any(int(b["x0"]) <= x < int(b["x0"]) + int(b["w"]) and int(b["y0"]) <= y < int(b["y0"]) + int(b["h"]) for b in nb), "%s: (%d, %d) «#» sin edificio" % (k, x, y)
	m = dict(M0)
	m["g"], m["o"], m["blds"] = g, o, nb
	m["exits"] = dict(M0["exits"])
	m["doors"] = dict(M0["doors"])
	return m


def calle_arriba(M0, C, filas, guarda=()):
	"""en las filas dadas, la hierba de siempre pasa a acera (salvo las casillas de guarda y los bordes de monte)"""
	for y in filas:
		for x in range(int(M0["w"])):
			if (x, y) in guarda:
				continue
			if M0["g"][y][x] in CAMBIA_HIERBA and not M0["o"][y][x]:
				C[y][x] = "."


EDIF = ("roof", "wall", "win", "door")


def pavimenta(M0, C, G, x0, y0, x1, y1, ch, de=None):
	"""el suelo de un rectángulo pasa a ch; lo que lleva objeto lo conserva (con el suelo nuevo en G); los edificios, no se tocan.
	de: solo las casillas con esos suelos"""
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			t = M0["g"][y][x]
			if t.startswith(EDIF) or C[y][x] not in ("%",) or (de and t not in de):
				continue
			if M0["o"][y][x]:
				if M0["o"][y][x] not in ("monte", "monte2", "seto"):
					G[(x, y)] = LEY[ch][0]
			else:
				C[y][x] = ch


def sin(M0, quita):
	"""los edificios de siempre salvo los de quita ((id, x0, y0)), marcados para copiarlos tal cual"""
	out = []
	for b in M0["blds"]:
		if (b["id"], int(b["x0"]), int(b["y0"])) in quita:
			continue
		b = dict(b)
		b["orig"] = True
		out.append(b)
	return out


# ------------------------------------------------------------------------------------------------------------------ Zorroza
def town(M0):
	W, H = 40, 30
	C = lienzo(W, H, "%")
	# arriba, como estaba (el monte de Cobetas detrás, la calle con el piso, el grow, el bar y la casa de Txaro, la carretera):
	# la hierba de detrás y entre las casas, acera; la cancilla de la huerta (9, 0-2), tal cual
	calle_arriba(M0, C, range(2, 13), guarda={(9, 0), (9, 1), (9, 2)})
	# abajo: el parque, la plaza, el paseo de la ría con la barandilla, la estación y la vía
	rect(C, 0, 13, 0, 28, "s")
	pon(C, 1, 13, [
		"...S....Y...",   # 13 (4, 13) el cartel del parque
		".yggggg.....",   # 14
		".ggfggg.Y.l.",   # 15
		".gggyg..+...",   # 16 (9, 16) el arbusto de la caja
		".b...gg.Y...",   # 17
		"..........b.",   # 18 (3, 18) Txaro
		"Y....Y....Y.",   # 19
		"............",   # 20
	])
	rect(C, 1, 21, 8, 24, "#")                       # la estación (8 × 4)
	pon(C, 9, 21, ["....", "Y...", "....", ".+.."])  # (10, 24) el arbusto
	# la plaza (13-26, 13-25), como estaba pero de losa entera y con los árboles en alcorque alrededor
	rect(C, 13, 13, 26, 24, ",")
	pon(C, 13, 13, [
		"Y...S........Y",     # 13: (17, 13) el cartel de la plaza
		".L...........L",     # 14
		"..............",
		"...n.......n..",     # 16
		"..............",
		"..............",
		"..............",
		"..............",
		"..............",
		"...n.......n..",     # 22
		"..............",
		".L...........L",     # 24
	])
	for y in range(13, 25):
		for x in range(13, 27):
			if C[y][x] == ".":
				C[y][x] = ","
	C[19][20] = "F"
	rect(C, 13, 25, 26, 25, "h")
	rect(C, 27, 13, 29, 24, ".")
	pon(C, 27, 13, ["Y..", "...", "..Y", "...", "...", "..S", "...", "...", "..Y", "...", "...", "Y.."])   # (29, 18) el cartel del muelle
	for y in list(range(13, 19)) + list(range(21, 25)):
		C[y][30] = "_"
	C[19][30] = C[20][30] = "."                       # al puente
	rect(C, 1, 25, 30, 26, "h")                      # el andén
	for x in range(3, 30, 6):
		C[25][x] = "e"
	C[26][2] = "+"                                    # (2, 26) el arbusto del acaparador, en su jardinera
	pon(C, 27, 25, ["hhh"])
	rect(C, 31, 26, 38, 26, "_")
	rect(C, 1, 27, 38, 28, "=")                      # la vía doble
	for x in (2, 14, 28):
		C[27][x] = C[28][x] = "x"                     # pasos a nivel hacia las carreteras de abajo
	rect(C, 0, 29, 38, 29, "s")
	blds = [b for b in M0["blds"]]
	for b in blds:
		b["orig"] = True
	blds.append({"id": "estacion", "x0": 1, "y0": 21, "w": 8, "h": 4, "doorX": None})
	return C, blds, {}


# ------------------------------------------------------------------------------------------------------------- Casco Viejo
def ibarbide(M0):
	W, H = 44, 30
	C, G = lienzo(W, H, "%"), {}
	# las Siete Calles, de adoquín (la de arriba y las de los lados de la plaza); la Plaza Nueva, de losa entera y sin jardín
	pavimenta(M0, C, G, 1, 8, 42, 8, "k")
	pavimenta(M0, C, G, 1, 9, 12, 10, "k")
	pavimenta(M0, C, G, 31, 9, 42, 10, "k")
	pavimenta(M0, C, G, 1, 18, 12, 19, "k")
	pavimenta(M0, C, G, 31, 18, 42, 19, "k")
	pavimenta(M0, C, G, 13, 9, 30, 19, ",")
	for x, y in ((16, 18), (27, 18)):
		C[y][x] = ","                                  # los arbustos de la plaza, fuera
	rect(C, 37, 11, 37, 17, "k")                      # el cantón entre la catedral y las casas
	# el teatro (8 × 7) donde las dos casas de arriba a la derecha; la catedral (6 × 9) en su plazuela, a la derecha de la plaza
	rect(C, 34, 1, 41, 7, "#")
	rect(C, 31, 9, 36, 17, "#")
	# la Ribera: el paseo del muelle con su barandilla, la ría, el mercado y el puente de piedra hacia la carretera de abajo
	rect(C, 1, 24, 42, 25, "m")
	for x in range(3, 42, 6):
		C[24][x] = "o" if x in (21, 27) else "l"
	C[25][13] = C[25][33] = "b"
	rect(C, 1, 26, 42, 26, "_")
	rect(C, 6, 26, 10, 26, "m")                       # la bajada del aparcamiento
	rect(C, 1, 27, 42, 29, "~")
	rect(C, 20, 24, 27, 28, "#")                      # el mercado (8 × 5), sobre la ría
	rect(C, 37, 26, 39, 29, "k")                      # el puente
	for y in range(27, 30):
		C[y][36] = C[y][40] = "_"
	C[24][39] = "l"
	blds = sin(M0, {("casco2", 34, 3), ("casco3", 37, 1), ("casco2", 31, 13), ("casco", 34, 12)})
	blds += [{"id": "teatro", "x0": 34, "y0": 1, "w": 8, "h": 7, "doorX": None},
		{"id": "catedral", "x0": 31, "y0": 9, "w": 6, "h": 9, "doorX": None},
		{"id": "mercado", "x0": 20, "y0": 24, "w": 8, "h": 5, "doorX": None}]
	return C, blds, G


# ------------------------------------------------------------------------------------------------------------------ Abando
def ensanche(M0):
	W, H = 46, 22
	C, G = lienzo(W, H, "%"), {}
	# arriba, las casas del Ensanche con miradores donde los bloques sin puerta (el club y la discoteca, tal cual)
	for x0, k in ((1, "ensB"), (19, "ensB2"), (28, "ensB")):
		rect(C, x0, 1, x0 + 6, 8, "#")
		rect(C, x0 + 7, 2, x0 + 7, 8, ".")
	# la Gran Vía: la acera de abajo con plátanos en alcorque (en la de arriba taparían los miradores)
	for x in range(4, 44, 4):
		if M0["o"][12][x] is None:
			C[12][x] = "A"
	# abajo: la plaza elíptica (losa, cuatro jardines, la fuente y las bocas del metro) y dos casas a cada lado
	rect(C, 15, 13, 30, 20, ",")
	pon(C, 15, 13, [
		"ggg..........ggg",
		"g*...L....L...gg",
		"g..............g",
		"...............L",
		"................",
		"g..............g",
		"gga.B.....n...ag",
		"ggg..........ggg",
	])
	for y in range(13, 21):
		for x in range(15, 31):
			if C[y][x] == ".":
				C[y][x] = ","
	C[16][22] = "F"
	C[19][26] = "B"
	for x0 in (1, 8, 31, 38):
		rect(C, x0, 13, x0 + 6, 20, "#")
	rect(C, 1, 21, 44, 21, ".")
	for x in (4, 11, 34, 41):
		C[21][x] = "l"
	blds = sin(M0, {("bloque", 1, 2), ("bloque", 19, 2), ("bloque2", 28, 2)})
	blds += [{"id": "ensB", "x0": 1, "y0": 1, "w": 7, "h": 8, "doorX": None}, {"id": "ensB2", "x0": 19, "y0": 1, "w": 7, "h": 8, "doorX": None},
		{"id": "ensB", "x0": 28, "y0": 1, "w": 7, "h": 8, "doorX": None}]
	for i, x0 in enumerate((1, 8, 31, 38)):
		blds.append({"id": "ensB2" if i % 2 else "ensB", "x0": x0, "y0": 13, "w": 7, "h": 8, "doorX": None})
	return C, blds, G


# ------------------------------------------------------------------------------------------------------------- Zazpi Landa
def alto(M0):
	W, H = 40, 30
	C, G = lienzo(W, H, "%"), {}
	# las torres de pisos de la ladera, a los lados de la fuente; la plaza que queda, de losa
	rect(C, 3, 4, 8, 12, "#")
	rect(C, 13, 4, 18, 12, "#")
	pavimenta(M0, C, G, 9, 4, 12, 12, ",")
	pavimenta(M0, C, G, 3, 13, 18, 17, ",")
	# las campas de abajo, de hierba alta con el camino de tierra
	pavimenta(M0, C, G, 1, 24, 38, 28, "d", de=("walk",))
	blds = sin(M0, set())
	blds += [{"id": "torreZ", "x0": 3, "y0": 4, "w": 6, "h": 9, "doorX": None}, {"id": "torreZ2", "x0": 13, "y0": 4, "w": 6, "h": 9, "doorX": None}]
	return C, blds, G


# ---------------------------------------------------------------------------------------------------------------- La Punta
def astilleros(M0):
	W, H = 40, 30
	C, G = lienzo(W, H, "%"), {}
	pavimenta(M0, C, G, 1, 2, 38, 18, "h", de=("dirt",))
	# el muelle de piedra con los norays y las grúas de pórtico en el canto
	pavimenta(M0, C, G, 1, 19, 38, 22, "m")
	for x in range(2, 39, 4):
		if x not in (6, 7, 8, 26, 27, 28):
			C[22][x] = "o"
	for x in (9, 20, 31):
		C[19][x] = "e"
	rect(C, 28, 16, 31, 22, "#")
	rect(C, 34, 16, 37, 22, "#")
	blds = sin(M0, set())
	blds += [{"id": "grua", "x0": 28, "y0": 16, "w": 4, "h": 7, "doorX": None}, {"id": "grua", "x0": 34, "y0": 16, "w": 4, "h": 7, "doorX": None}]
	return C, blds, G


# ---------------------------------------------------------------------------------------------------------------- el cantón
def callejon(M0):
	C, G = lienzo(23, 18, "%"), {}
	pavimenta(M0, C, G, 1, 8, 21, 16, "k")
	return C, sin(M0, set()), G


SOLIDO = ("water", "roof", "wall", "win", "iwT", "iwB", "void")
# lo que se nombra desde el código (no está en datos.json con su mapa): [mapa, x, y]
ANCLAS_CODIGO = [
	["town", 9, 0], ["town", 9, 1], ["town", 9, 2],                 # la cancilla y la senda de la huerta (HUERTA)
	["town", 9, 8], ["town", 1, 8], ["town", 30, 8], ["town", 31, 8], # el cartel del garaje y el cajero (CAJERO_CAL)
	["town", 8, 12], ["town", 7, 12], ["ibarbide", 9, 20], ["ibarbide", 10, 20],   # las paradas y sus llegadas
	["town", 5, 9], ["town", 5, 10], ["town", 12, 9], ["town", 12, 10], ["town", 33, 10], ["town", 36, 11], ["town", 2, 11],   # DEMO
]


def anclas(D):
	"""[mapa, x, y, de dónde] de todo lo que en datos.json nombra una casilla de estos mapas"""
	import re
	out = []
	MAP = set(D["BILBAO_K"])

	def anda(v, ruta):
		if isinstance(v, dict):
			mp = None
			for kk in ("map", "mapa", "m", "to"):
				if isinstance(v.get(kk), str) and v[kk] in MAP:
					mp = v[kk]
			if mp and isinstance(v.get("x"), (int, float)) and isinstance(v.get("y"), (int, float)):
				out.append([mp, int(v["x"]), int(v["y"]), ruta])
			for kk, w in v.items():
				mm = re.match(r"^(\w+):(\d+),(\d+)$", str(kk))
				if mm and mm.group(1) in MAP:
					out.append([mm.group(1), int(mm.group(2)), int(mm.group(3)), ruta + "/" + kk])
				if ruta == "" and kk in ("MAPS", "BILBAO"):
					continue
				anda(w, ruta + "/" + str(kk))
		elif isinstance(v, list):
			for i, w in enumerate(v):
				anda(w, ruta + "[%d]" % i)
	anda(D, "")
	return out + [a + ["código"] for a in ANCLAS_CODIGO]


def comprueba(D, B):
	mal = []
	solido = lambda t: t.startswith(SOLIDO)
	for mp, x, y, de in anclas(D):
		if mp not in B["MAPS"]:
			continue
		m0, m1 = D["MAPS"][mp], B["MAPS"][mp]
		if m0["o"][y][x] and m1["o"][y][x] != m0["o"][y][x]:
			mal.append("%s (%d, %d) %s: el objeto %s pasa a %s" % (mp, x, y, de, m0["o"][y][x], m1["o"][y][x]))
		if not solido(m0["g"][y][x]) and solido(m1["g"][y][x]):
			mal.append("%s (%d, %d) %s: %s pasa a %s" % (mp, x, y, de, m0["g"][y][x], m1["g"][y][x]))
		if not m0["o"][y][x] and m1["o"][y][x] and de != "código":
			mal.append("%s (%d, %d) %s: tapada por %s" % (mp, x, y, de, m1["o"][y][x]))
	for mp, m1 in B["MAPS"].items():
		m0 = D["MAPS"][mp]
		for kk in list(m0["exits"]) + list(m0["doors"]):
			x, y = map(int, kk.split(","))
			if m1["g"][y][x] != m0["g"][y][x]:
				mal.append("%s (%d, %d): la puerta o salida %s pasa a %s" % (mp, x, y, m0["g"][y][x], m1["g"][y][x]))
		for q in D["CARRETERAS"]["puertas"].get(mp, []):   # el borde que abre la carretera y la casilla de dentro
			x, y = int(q[0]), int(q[1])
			dx = 1 if x == 0 else -1 if x == int(m1["w"]) - 1 else 0
			dy = 1 if y == 0 else -1 if y == int(m1["h"]) - 1 else 0
			if solido(m1["g"][y + dy][x + dx]) or m1["o"][y + dy][x + dx]:
				mal.append("%s (%d, %d): la entrada de la carretera, tapada" % (mp, x + dx, y + dy))
	return mal


def tablas(D, B):
	"""farolas, casillas de clientes y de ronda de los mapas nuevos: las de siempre que siguen libres y, si no queda ninguna, las aceras"""
	solido = lambda t: t.startswith(SOLIDO)
	for mp, m in B["MAPS"].items():
		libre = lambda x, y: not solido(m["g"][y][x]) and not m["o"][y][x] and m["g"][y][x] not in ("via", "viaV")
		B["LAMPS"][mp] = [[x, y] for y in range(int(m["h"])) for x in range(int(m["w"])) if m["o"][y][x] == "lamp"]
		for t in ("CLIENT_TILES", "RONDA"):
			v = [c for c in D[t].get(mp, []) if libre(int(c[0]), int(c[1]))]
			B[t][mp] = v or [[x, y] for y in range(int(m["h"])) for x in range(int(m["w"])) if m["g"][y][x] == "walk" and libre(x, y)]


def main():
	D = json.load(open(DATOS, encoding="utf-8"))
	MAPS = D["MAPS"]
	B = {"_": "Los mapas de Bilbao (con Datos.CAL; tools/bilbao.py): Zorroza, Zazpi Landa, La Punta, el Casco Viejo, Abando y un cantón. Datos._aplica_auto los pone en D.MAPS y en las tablas de cada mapa.", "MAPS": {}, "LAMPS": {}, "CLIENT_TILES": {}, "RONDA": {}}
	for k, f in (("town", town), ("ibarbide", ibarbide), ("ensanche", ensanche), ("alto", alto), ("astilleros", astilleros), ("callejon", callejon)):
		M0 = json.loads(json.dumps(MAPS[k]))
		C, blds, G = f(M0)
		B["MAPS"][k] = construye(k, M0, C, json.loads(json.dumps(blds)), G)
	D["BILBAO_K"] = list(B["MAPS"])
	mal = comprueba(D, B)
	del D["BILBAO_K"]
	tablas(D, B)
	for t in mal:
		print("  MAL:", t)
	if mal:
		return 1
	D["BILBAO"] = B
	s = json.dumps(D, ensure_ascii=False, separators=(",", ":"))
	open(DATOS, "w", encoding="utf-8").write(s)
	print("bilbao: %d mapas" % len(B["MAPS"]))


if __name__ == "__main__":
	sys.exit(main())
