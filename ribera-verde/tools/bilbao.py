#!/usr/bin/env python3
# Landrace Hunters — Bilbao, zonas nuevas (lo pidió el usuario: «Los mapas del juego hazlos los más parecidos y realistas a Bilbao
# centro y sus barrios, Zorroza no puede faltar», y después «Añade como zonas nuevas / No quiero caos», el caos: «el mobiliario
# urbano, la distribución en el suelo de alcantarillas y demás»). Escribe en godot/datos/datos.json la clave BILBAO; con Datos.CAL,
# Datos._aplica_auto mete los cuatro mapas, su parada, su zona, sus patrullas, sus clientes y su ronda (sin CAL, nada: los seis
# mapas de siempre no cambian). Cuatro mapas en fila, de lado a lado por la calle:
#   zorroza → la parada «Bilbao»: las torres de la ladera, la calle con su calzada, la estación, el parque, la vía doble y la ría;
#   lapunta → La Punta: los pabellones de ladrillo, el hormigón, las grúas de pórtico y el muelle con sus norays;
#   abando  → Abando: las casas del Ensanche con miradores, la Gran Vía con plátanos y la plaza elíptica con la fuente y el metro;
#   casco   → el Casco Viejo: adoquín, casas estrechas, el teatro, la plaza, la catedral, el mercado y la Ribera.
# Nada al azar: el mobiliario (farolas, bancos con su papelera, plátanos, bolardos en los pasos, contenedores) y lo del suelo (la tapa
# de registro, los imbornales junto al bordillo, el paso de cebra) van por calles y a ritmo fijo (RITMO), los de enfrente a la misma
# x; lo del suelo, en BILBAO.DEC (calcomanías que pinta pinta.gd encima de la casilla).
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
	"U": ("roadB", None), "=": ("via", None), "H": ("viaV", None), "x": ("viaX", None), "X": ("viaXV", None), "Ñ": ("viaE", None), "ñ": ("viaEX", None),
	"Y": ("walk", "tree2"), "y": ("grass", "tree"), "l": ("walk", "lamp"), "L": ("plaza", "lamp"), "b": ("walk", "bench"),
	"n": ("plaza", "bench"), "*": ("grass", "bush"), "+": ("walk", "bush"), "S": ("walk", "sign"), "F": ("plaza", "fountain"),
	"M": ("grass", "monte"), "W": ("grass", "monte2"), "s": ("grass", "seto"), "P": ("walk", "parada"), "$": ("walk", "cajero"),
	"R": ("walk", "rotuloL"), "|": ("walk", "fence"), "Z": ("adoq", "tree2"), "j": ("adoq", "lamp"), "q": ("adoq", "bench"),
	"Q": ("hormigon", "crate"), "e": ("hormigon", "lamp"), "o": ("muelleP", "noray"), "B": ("walk", "metroB"),
	"t": ("hormigon", "tree2"), "&": ("hormigon", "fence"), "A": ("walk", "platano"), "a": ("plaza", "platano"),
	"w": ("walk", "papelera"), "v": ("walk", "bolardo"), "C": ("walk", "contenedores"), "1": ("adoq", "papelera"),
	"2": ("adoq", "bolardo"), "3": ("plaza", "papelera"), "4": ("hormigon", "papelera"), "5": ("muelleP", "papelera"),
	"6": ("muelleP", "bench"), "7": ("muelleP", "lamp"), "8": ("hormigon", "contenedores"), "9": ("adoq", "contenedores"), "r": ("hormigon", "bench"),
	 "G": ("hormigon", "grua0"), "E": ("hormigon", "escZ"), "V": ("hormigon", "ascensorZ"),
}
ANCHOS = {"metroB": "metroB2", "contenedores": "contenedores2", "escZ": "escZ2", "ascensorZ": "ascensorZ2"}   # lo de 2 casillas: la de la derecha, sólida y sin dibujo
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
	for y in range(h):                                                # lo de 2 casillas, después: la de la derecha no la pisa el «.»
		for x in range(w - 1):
			if o[y][x] in ANCHOS:
				o[y][x + 1] = ANCHOS[o[y][x]]
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




# ------------------------------------------------------------------------------------------------------- el ritmo de la calle
RITMO = {"farola": 8, "banco": 16, "imbornal": 8, "tapa": 16, "contenedor": 16}


def calle(C, DEC, y, x0, x1, arbol=False, cruces=(), suelo=".", sin_banco=(), sin_cont=()):
	"""una calle de x0 a x1 desde la fila y: acera (y), bordillo con el mobiliario (y + 1), calzada (y + 2, y + 3), bordillo (y + 4)
	y acera (y + 5). A ritmo: farola cada 8 en los dos bordillos a la misma x (+2); plátano en medio (+6) o, sin árboles, banco con
	su papelera a la derecha cada 16 (+6, +7); contenedores cada 16 abajo (+12); imbornal en los dos cantos de la calzada cada 8
	(+4), tapa en medio de la calzada cada 16 (+10); en cada cruce (x, x + 1), paso de cebra y bolardos a los lados."""
	rect(C, x0, y, x1, y + 5, suelo)
	rect(C, x0, y + 2, x1, y + 2, "T")
	rect(C, x0, y + 3, x1, y + 3, "U")
	libre = set()
	for xc in cruces:
		libre |= {xc - 1, xc, xc + 1, xc + 2}
		for xx in (xc, xc + 1):
			DEC["%d,%d" % (xx, y + 2)] = DEC["%d,%d" % (xx, y + 3)] = "cebra"
		for yy in (y + 1, y + 4):
			C[yy][xc - 1] = C[yy][xc + 2] = "v"
	for x in range(x0, x1 + 1):
		r = x - x0
		if x not in libre:
			if r % RITMO["farola"] == 2:
				C[y + 1][x] = C[y + 4][x] = "l"
			elif arbol and r % RITMO["farola"] == 6:
				C[y + 1][x] = C[y + 4][x] = "A"
			elif not arbol and r % RITMO["banco"] == 6 and x + 1 < x1 and x + 1 not in libre and x not in sin_banco:
				C[y + 1][x], C[y + 1][x + 1] = "b", "w"
			elif r % RITMO["contenedor"] == 12 and x + 1 not in libre and x + 1 < x1 and x not in sin_cont:
				C[y + 4][x] = "C"
		if any(x in (xc, xc + 1) for xc in cruces):                    # lo del suelo, a ritmo también junto al cruce (no en la cebra)
			continue
		if r % RITMO["imbornal"] == 4:
			DEC["%d,%d" % (x, y + 2)], DEC["%d,%d" % (x, y + 3)] = "imbT", "imbB"
		elif r % RITMO["tapa"] == 10:
			DEC["%d,%d" % (x, y + 3)] = "tapa"


def paseo(C, y, x0, x1, ch, farola, banco, papelera, paso=8, desde=2):
	"""un paseo de una fila: farola cada paso y, entre dos, banco con su papelera"""
	for x in range(x0, x1 + 1):
		r = (x - x0 - desde) % paso
		if r == 0:
			C[y][x] = farola
		elif r == paso // 2 and x + 1 <= x1:
			C[y][x], C[y][x + 1] = banco, papelera


def borde(C, W, H, ch="M"):
	for x in range(W):
		C[0][x] = ch
	for y in range(H):
		C[y][0] = C[y][W - 1] = ch


def vacio(k, W, H, nombre, musica):
	return {"name": nombre, "w": W, "h": H, "g": [["grass"] * W for _ in range(H)], "o": [[None] * W for _ in range(H)],
		"exits": {}, "doors": {}, "music": musica, "blds": [], "est": None}


def lado(m, x, ys, to, tx, dir_):
	for y in ys:
		m["exits"]["%d,%d" % (x, y)] = {"to": to, "x": tx, "y": y, "dir": dir_, "lado": dir_}


CALLE_Y = 9   # la calle de las cuatro zonas, en la misma fila: se pasa de una a otra por los lados (filas 9 a 14)
SALE = range(CALLE_Y, CALLE_Y + 6)


# ------------------------------------------------------------------------------------------------------------------ Zorroza
# El paso subterráneo (lo pidió el usuario: «O escaleras, que bajes unas escaleras y aparezcas en las del otro lado, sin cambiar el
# mapa. Mejor que lo del ascensor. Me gusta más. Porque además en la estación de tren de Zorroza el ascensor no funciona»): sin
# pasos a nivel; tres bocas de escalera de 2 casillas (escZ, que baja hacia la derecha, y escZ2) junto al camino del parque, en el
# andén de la vía ancha, en el de la estrecha y en el paseo de la ría; se entra andando a la derecha desde la casilla de su
# izquierda y se sale por la de otra boca (calle.gd, bajar_escalera). El ascensor de 2 casillas, al lado, averiado.
ESC_Z = [{"x": 21, "y": 19, "n": "Al andén de la vía ancha"}, {"x": 21, "y": 22, "n": "Al andén de la vía estrecha"}, {"x": 21, "y": 24, "n": "A la ría"}]
ASC_Z = (23, 19)
def zorroza(DEC):
	W, H = 40, 28
	C = lienzo(W, H, "g")
	borde(C, W, H)
	for y in range(1, 9):                                         # la ladera de Arbolantxa detrás de las torres
		for x in range(1, W - 1):
			C[y][x] = "g"
	blds = []
	for i, x0 in enumerate((2, 10, 24, 32)):                       # las torres de pisos, con un paso entre las dos de en medio
		rect(C, x0, 0, x0 + 5, 8, "#")
		blds.append({"id": "torreZ2" if i % 2 else "torreZ", "x0": x0, "y0": 0, "w": 6, "h": 9, "doorX": None})
	for x0 in (8, 16, 22, 30, 38):
		rect(C, x0, 1, min(x0 + 1, W - 2), 8, ".")
	for x in (8, 22, 30):
		C[2][x] = "l"
	rect(C, 16, 1, 21, 8, ",")                                     # la plaza de entre las torres
	C[4][18] = "F"
	for x in (16, 21):
		C[2][x] = C[7][x] = "L"
	C[7][17], C[7][18] = "n", "3"
	C[CALLE_Y][0] = C[CALLE_Y + 5][0] = "M"
	calle(C, DEC, CALLE_Y, 1, W - 1, cruces=(18,))
	for y in SALE:
		C[y][W - 1] = C[y][W - 2] if C[y][W - 2] in ".TU" else "."
	rect(C, 1, 15, W - 2, 22, "g")
	rect(C, 2, 15, 9, 18, "#")                                     # la estación, con su andén
	blds.append({"id": "estacion", "x0": 2, "y0": 15, "w": 8, "h": 4, "doorX": None})
	rect(C, 1, 19, W - 2, 19, "h")
	for x in (11, 17):                                             # el andén de arriba: bajo la estación, libre (el paso al
		C[19][x] = "e"                                             # oeste); dos farolas junto al parque y, pasada la escalera y
	paseo(C, 19, 26, W - 2, "h", "e", "r", "4")                   # su ascensor, el paseo con bancos
	rect(C, 1, 20, W - 2, 21, "=")                                 # la vía doble, sin paso a nivel: se cruza por debajo (ESC_Z)
	rect(C, 12, 15, W - 2, 18, "g")                                # el parque: césped, árboles en fila y el camino del paso
	for x in range(13, W - 2, 6):
		C[16][x] = "y"
	rect(C, 18, 15, 19, 18, ".")
	for x in (17, 20):
		C[15][x] = C[18][x] = "v"
	rect(C, 1, 22, W - 2, 22, "h")                                 # el andén de la vía estrecha (lo dijo el usuario: «Hay tren
	                                                               # renfe y feve»): la de ancho ibérico arriba, la de ancho
	rect(C, 1, 23, W - 2, 23, "Ñ")                                 # métrico de una vía abajo, por la ría, y el bus en la calle
	rect(C, 1, 24, W - 2, 24, "h")
	for b in ESC_Z:                                                # las bocas del paso subterráneo, una por andén (el de abajo,
		C[b["y"]][b["x"]] = "E"                                    # estrecho y sin nada que corte el paso) y la de la ría
	C[ASC_Z[1]][ASC_Z[0]] = "V"                                    # y el ascensor, que no funciona
	for x in range(1, W - 1):
		C[25][x] = "_"                                              # la barandilla de la ría
	rect(C, 1, 26, W - 2, 27, "~")
	C[CALLE_Y + 4][12] = "P"                                       # la parada del autobús (Bilbao)
	for x in (11, 13):
		if C[CALLE_Y + 4][x] not in "lv":
			C[CALLE_Y + 4][x] = "."
	return C, blds


# ---------------------------------------------------------------------------------------------------------------- La Punta
def lapunta(DEC):
	W, H = 40, 24
	C = lienzo(W, H, "h")
	borde(C, W, H, "M")
	blds = []
	for x0, k, w, h in ((2, "ladrillo", 7, 6), (11, "nave", 6, 6), (19, "ladrillo", 7, 6), (28, "nave", 6, 6)):
		rect(C, x0, 9 - h, x0 + w - 1, 8, "#")
		blds.append({"id": k, "x0": x0, "y0": 9 - h, "w": w, "h": h, "doorX": None})
	rect(C, 1, 1, W - 2, 2, "M")
	for y in range(3, 9):
		for x in range(1, W - 1):
			if C[y][x] == "h":
				C[y][x] = "h"
	calle(C, DEC, CALLE_Y, 0, W - 1, cruces=(9, 17), suelo="h")
	for y in SALE:
		C[y][0] = C[y][1] if C[y][1] in "hTU" else "h"
		C[y][W - 1] = C[y][W - 2] if C[y][W - 2] in "hTU" else "h"
	rect(C, 1, 15, W - 2, 17, "h")                                 # la explanada: los contenedores de obra, en fila
	for x in range(3, W - 2, 8):
		C[16][x] = "Q"
	blds += [{"id": "grua", "x0": 12, "y0": 15, "w": 4, "h": 7, "doorX": None}, {"id": "grua", "x0": 28, "y0": 15, "w": 4, "h": 7, "doorX": None}]
	rect(C, 12, 15, 15, 21, "#")
	rect(C, 28, 15, 31, 21, "#")
	rect(C, 1, 18, W - 2, 21, "m")                                 # el muelle de piedra, con los norays al canto cada 4
	for x0 in (12, 28):
		rect(C, x0, 15, x0 + 3, 21, "#")
	for x in range(2, W - 1, 4):
		if C[21][x] == "m":
			C[21][x] = "o"
	for x in range(4, W - 1, 8):
		if C[18][x] == "m":
			C[18][x] = "7"
	rect(C, 1, 22, W - 2, 23, "~")
	return C, blds


# ------------------------------------------------------------------------------------------------------------------ Abando
def abando(DEC):
	W, H = 46, 26
	C = lienzo(W, H, ".")
	borde(C, W, H, "s")
	blds = []
	for i, x0 in enumerate((1, 8, 15, 24, 31, 38)):               # la manzana de arriba, seguida, con el paso de en medio
		rect(C, x0, 0, x0 + 6, 7, "#")
		blds.append({"id": "ensB2" if i % 2 else "ensB", "x0": x0, "y0": 0, "w": 7, "h": 8, "doorX": None})
	rect(C, 22, 0, 23, 8, ".")
	C[0][22] = C[0][23] = "s"
	calle(C, DEC, CALLE_Y - 1 + 1, 0, W - 1, arbol=True, cruces=(22,))
	for y in SALE:
		C[y][0] = C[y][1] if C[y][1] in ".TU" else "."
		C[y][W - 1] = C[y][W - 2] if C[y][W - 2] in ".TU" else "."
	for i, x0 in enumerate((1, 8, 31, 38)):                       # las manzanas de abajo
		rect(C, x0, 17, x0 + 6, 24, "#")
		blds.append({"id": "ensB" if i % 2 else "ensB2", "x0": x0, "y0": 17, "w": 7, "h": 8, "doorX": None})
	rect(C, 1, 15, W - 2, 16, ".")
	rect(C, 15, 15, 30, 24, ",")                                   # la plaza elíptica: simétrica en las dos direcciones
	pon(C, 15, 15, [
		"gggg........gggg",
		"gg..L......L..gg",
		"g..............g",
		"...n3......n3...",
		"......,F,.......",
		"................",
		"...n3......n3...",
		"g..............g",
		"gg..L......L..gg",
		"gggg........gggg",
	])
	for y in range(15, 25):
		for x in range(15, 31):
			if C[y][x] == ".":
				C[y][x] = ","
	rect(C, 1, 25, W - 2, 25, "s")
	return C, blds


# ------------------------------------------------------------------------------------------------------------- Casco Viejo
def casco(DEC):
	W, H = 44, 28
	C = lienzo(W, H, "k")
	borde(C, W, H, "M")
	blds = []
	casas = [("teatro", 2, 8, 7)] + [("casco3", x, 5, 7) for x in (12, 17)] + [("casco", x, 4, 6) for x in (24, 28)] + [("casco2", x, 3, 5) for x in (34, 37, 40)]
	for k, x0, w, h in casas:
		rect(C, x0, 8 - h, x0 + w - 1, 7, "#")
		blds.append({"id": k, "x0": x0, "y0": 8 - h, "w": w, "h": h, "doorX": None})
	for x in range(1, W - 1):
		if C[1][x] != "#":
			C[1][x] = "M"
	for x0, x1 in ((10, 11), (22, 23), (32, 33)):                   # los cantones entre las casas
		rect(C, x0, 2, x1, 7, "k")
	rect(C, 10, 1, 11, 1, "k"); rect(C, 22, 1, 23, 1, "k"); rect(C, 32, 1, 33, 1, "k")
	C[1][10] = C[1][11] = C[1][22] = C[1][23] = C[1][32] = C[1][33] = "M"
	paseo(C, 8, 1, W - 2, "k", "j", "q", "1")                      # la calle de las Siete Calles: farolas y bancos en fila
	for y in SALE:
		C[y][0] = "k"
	rect(C, 13, 10, 30, 15, ",")                                  # la plaza, porticada: farolas en las esquinas y la fuente
	for x, y in ((13, 10), (30, 10), (13, 15), (30, 15)):
		C[y][x] = "L"
	C[12][21] = "F"
	for x in (16, 26):
		C[12][x], C[12][x + 1] = "n", "3"
	casas2 = [("casco3", x, 5, 7) for x in (2, 7)] + [("mercado", 16, 8, 5)] + [("casco", x, 4, 6) for x in (25, 29)] + [("catedral", 36, 6, 9)]
	for k, x0, w, h in casas2:
		y0 = 23 - h
		rect(C, x0, y0, x0 + w - 1, 22, "#")
		blds.append({"id": k, "x0": x0, "y0": y0, "w": w, "h": h, "doorX": None})
	rect(C, 1, 23, W - 2, 24, "m")                                # la Ribera: el paseo con su ritmo y la barandilla
	paseo(C, 23, 1, W - 2, "m", "7", "6", "5")
	for x in range(1, W - 1):
		C[25][x] = "_"
	rect(C, 1, 26, W - 2, 27, "~")
	return C, blds


ZONAS_N = {"zorroza": "Zorroza", "lapunta": "La Punta", "abando": "Abando", "casco": "Casco Viejo"}
MUSICA = {"zorroza": "town", "lapunta": "astilleros", "abando": "ensanche", "casco": "ibarbide"}
CADENA = ["zorroza", "lapunta", "abando", "casco"]
SOLIDO = ("via", "water", "roof", "wall", "win", "iwT", "iwB", "void")


def tablas(B):
	"""farolas, casillas de clientes (acera, plaza y adoquín libres, no en el bordillo del mobiliario) y de ronda (las aceras)"""
	solido = lambda t: t.startswith(SOLIDO)
	for mp, m in B["MAPS"].items():
		W, H = int(m["w"]), int(m["h"])
		libre = lambda x, y: 0 < x < W - 1 and 0 < y < H - 1 and not solido(m["g"][y][x]) and not m["o"][y][x] and m["g"][y][x] in ("walk", "plaza", "adoq", "hormigon", "muelleP")
		vecino = lambda x, y: any(m["o"][y + dy][x + dx] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
		bld = {(x, y) for b in m["blds"] for x in range(int(b["x0"]), int(b["x0"]) + int(b["w"])) for y in range(int(b["y0"]), int(b["y0"]) + int(b["h"]))}
		va, cola = set(), [tuple(int(v) for v in c.split(",")) for c in m["exits"]]   # lo que se alcanza desde las salidas
		while cola:
			x, y = cola.pop()
			for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				q = (x + dx, y + dy)
				if q not in va and 0 <= q[0] < W and 0 <= q[1] < H and q not in bld and not m["o"][q[1]][q[0]] and not solido(m["g"][q[1]][q[0]]):
					va.add(q)
					cola.append(q)
		libre0 = libre
		libre = lambda x, y: libre0(x, y) and (x, y) in va
		B["LAMPS"][mp] = [[x, y] for y in range(H) for x in range(W) if m["o"][y][x] == "lamp"]
		B["CLIENT_TILES"][mp] = [[x, y] for y in range(1, H - 1) for x in range(2, W - 2) if libre(x, y) and not vecino(x, y)]
		B["RONDA"][mp] = [[x, y] for y in range(1, H - 1) for x in range(1, W - 1) if libre(x, y)]


def main():
	D = json.load(open(DATOS, encoding="utf-8"))
	B = {"_": "Bilbao, zonas nuevas (con Datos.CAL; tools/bilbao.py): Zorroza (la parada), La Punta, Abando y el Casco Viejo, en fila por la calle. Datos._aplica_auto los mete en D.MAPS y en sus tablas; DEC, lo del suelo de cada mapa (pinta.gd).",
		"MAPS": {}, "DEC": {}, "LAMPS": {}, "CLIENT_TILES": {}, "RONDA": {},
		"PARADA": {"n": "Bilbao", "x": 12, "y": CALLE_Y + 4, "a": [12, CALLE_Y + 5, "down"], "min": 30, "eur": 3, "cap": 2},
		"ZONAS": {k: {"n": "Bilbao · " + n, "lad": 1.0, "precio": 1.25} for k, n in ZONAS_N.items()},
		"PATRULLAS": {k: [1, 2] for k in ZONAS_N}, "KM": 14, "PRE": {"zorroza": "z", "lapunta": "u", "abando": "a", "casco": "o"}}
	for k, f in (("zorroza", zorroza), ("lapunta", lapunta), ("abando", abando), ("casco", casco)):
		DEC = {}
		C, blds = f(DEC)
		W, H = len(C[0]), len(C)
		M0 = vacio(k, W, H, ZONAS_N[k], MUSICA[k])
		m = construye(k, M0, C, blds)
		i = CADENA.index(k)
		if i > 0:
			lado(m, 0, SALE, CADENA[i - 1], int(B["MAPS"][CADENA[i - 1]]["w"]) - 2, "left")
		if i < len(CADENA) - 1:
			lado(m, W - 1, SALE, CADENA[i + 1], 1, "right")
		for c in list(DEC):
			x, y = map(int, c.split(","))
			if m["o"][y][x]:
				del DEC[c]
		if k == "zorroza":
			m["escaleras"] = ESC_Z
		B["MAPS"][k] = m
		B["DEC"][k] = DEC
	tablas(B)
	D["BILBAO"] = B
	s = json.dumps(D, ensure_ascii=False, separators=(",", ":"))
	open(DATOS, "w", encoding="utf-8").write(s)
	print("bilbao: %d mapas, %d cosas en el suelo" % (len(B["MAPS"]), sum(len(v) for v in B["DEC"].values())))


if __name__ == "__main__":
	sys.exit(main())
