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
	 "G": ("hormigon", "grua0"), "E": ("hormigon", "escZ"), "V": ("hormigon", "ascensorZ"), "i": ("plaza", "estatua"), "p": ("puenteV", None),
	"{": ("roadL", None), "}": ("roadR", None), "^": ("roadX", None),
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


# El aparcamiento de cada zona (lo pidió el usuario: «En los nuevos mapas no hay parking, hay que estudiar el espacio jugable que no
# sea agobiante»): un hueco de 3 × 4 casillas (aparcamiento.py, APARC en calle.gd: cuatro plazas y el pasillo a la derecha) con una
# vuelta libre alrededor y ninguna fachada a dos casillas (tests/aparc_bilbao.gd)
APARC = {"zorroza": (13, 21), "lapunta": (20, 21), "abando": (54, 3), "casco": (6, 29)}

def hueco_aparc(C, k, suelo):
	x0, y0 = APARC[k]
	rect(C, x0, y0, x0 + 2, y0 + 3, suelo)


# La calle de las cuatro zonas, en la misma fila (se pasa de una a otra por los lados, filas 14 a 19). Lo pidió el usuario: «además
# de los edificios, tienes que buscar la estructura del mapa que se parezca al lugar donde te he dicho»: cada zona, con su trazado de
# verdad alrededor de esa calle (lo de arriba es el norte), y sus edificios de referencia dibujados a mano y genéricos
CALLE_Y = 14
SALE = range(CALLE_Y, CALLE_Y + 6)


def edif(C, blds, k, x0, y0, w, h):
	rect(C, x0, y0, x0 + w - 1, y0 + h - 1, "#")
	blds.append({"id": k, "x0": x0, "y0": y0, "w": w, "h": h, "doorX": None})


def lados(C, W, izq, der, suelo="."):
	"""la casilla de llegada de cada salida, libre (sin farola ni árbol): la calzada se queda; lo demás, al suelo de la acera"""
	for y in SALE:
		for x in ((0, 1) if izq else ()) + ((W - 2, W - 1) if der else ()):
			if C[y][x] not in "TU":
				C[y][x] = suelo


def elipse(x, y, cx, cy, rx, ry):
	return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2


# ------------------------------------------------------------------------------------------------------------------ Zorroza
# Una franja llana entre la ría (arriba) y la ladera (abajo), al este de La Punta (el Kadagua, en La Punta). De norte a sur: la ría con su paseo, la vía
# de ancho ibérico con el andén y la estación junto a la avenida, la avenida (la calle, con la parada «Bilbao»), la manzana del medio
# (las torres y la plaza de la iglesia con su torre) y la vía estrecha con su apeadero, al pie de la ladera. Sin pasos a nivel: cada vía
# se cruza por su paso subterráneo (lo pidió el usuario: «O escaleras, que bajes unas escaleras y aparezcas en las del otro lado, sin
# cambiar el mapa… en la estación de tren de Zorroza el ascensor no funciona»): dos bocas por vía (g, el paso), de 2 casillas
# (escZ, que baja hacia la derecha, y escZ2); se entra andando a la derecha desde la casilla de su izquierda y se sale por la otra
# boca de su paso (calle.gd, bajar_escalera). El ascensor, junto a la del andén, averiado.
ESC_Z = [{"x": 28, "y": 8, "n": "Al paseo de la ría", "g": "ancha"}, {"x": 28, "y": 4, "n": "Al andén de la vía ancha", "g": "ancha"},
	{"x": 28, "y": 31, "n": "A la ladera", "g": "estrecha"}, {"x": 28, "y": 33, "n": "Al andén de la vía estrecha", "g": "estrecha"}]
ASC_Z = (31, 8)
def zorroza(DEC):
	W, H = 46, 36
	C = lienzo(W, H, ".")
	borde(C, W, H)
	blds = []
	rect(C, 0, 0, W - 1, 2, "~")                                   # la ría, que sigue en La Punta
	rect(C, 1, 3, W - 2, 3, "_")                                   # la barandilla de la ría
	rect(C, 1, 4, W - 2, 4, "m")                                   # el paseo de la ría, con sus farolas y bancos
	paseo(C, 4, 4, W - 2, "m", "7", "6", "5")
	rect(C, 1, 5, W - 2, 5, "m")                                   # la otra mitad del paseo, libre (de la vía la separa la catenaria)
	rect(C, 0, 6, W - 1, 7, "=")                                   # la vía ancha, doble, de lado a lado
	rect(C, 1, 8, W - 2, 9, "h")                                   # el andén
	edif(C, blds, "estacion", 5, 10, 8, 4)                         # la estación, entre el andén y la avenida
	rect(C, 13, 10, 14, 13, "h")
	edif(C, blds, "bloqueZ", 15, 9, 6, 5)
	for x in (22, 31):                                             # la placita de delante del paso
		C[11][x] = "Y"
	edif(C, blds, "bloqueZ2", 34, 9, 6, 5)
	calle(C, DEC, CALLE_Y, 0, W - 1, cruces=(22,))                 # la avenida, de La Punta a Abando
	lados(C, W, True, True)
	C[CALLE_Y + 4][12] = "P"                                       # la parada del autobús (Bilbao)
	edif(C, blds, "torreZ", 5, 20, 6, 9)                           # la manzana del medio: torres de pisos y la plaza de la iglesia
	edif(C, blds, "iglesiaZ", 21, 20, 6, 8)                        # la parroquia del barrio, con su campanario exento
	rect(C, 18, 20, 20, 29, ",")
	rect(C, 27, 20, 30, 29, ",")
	rect(C, 21, 28, 26, 29, ",")
	C[24][29] = "F"
	for x, y in ((18, 21), (30, 21), (19, 28), (29, 28)):
		C[y][x] = "L"
	C[29][22], C[29][23] = "n", "3"
	C[29][24], C[29][25] = "n", "3"
	edif(C, blds, "torreZ2", 32, 20, 6, 9)
	edif(C, blds, "torreZ", 39, 20, 6, 9)
	edif(C, blds, "apeadero", 13, 28, 4, 3)                        # el apeadero de la vía estrecha
	rect(C, 1, 31, W - 2, 31, "h")                                 # su andén, la vía de ancho métrico y el camino de la ladera
	paseo(C, 31, 4, W - 2, "h", "e", "r", "4", desde=6)
	rect(C, 0, 32, W - 1, 32, "Ñ")
	rect(C, 1, 33, W - 2, 33, "h")
	for x in range(1, W - 1):
		C[34][x] = "W" if x % 3 else "M"
		C[35][x] = "M"
	for b in ESC_Z:
		C[b["y"]][b["x"]] = "E"
		C[b["y"]][b["x"] - 1] = C[b["y"]][b["x"] - 1] if C[b["y"]][b["x"] - 1] in "hm" else "m"   # la entrada, libre
		C[b["y"]][b["x"] + 2] = C[b["y"]][b["x"] + 2] if C[b["y"]][b["x"] + 2] in "hm" else "m"
	for y in (4, 31):                                              # y el banco o la papelera que se quedan sin su pareja, fuera
		for x in range(1, W - 1):
			if C[y][x] in "6r" and C[y][x - 1] not in "54" and C[y][x + 1] not in "54" or C[y][x] in "54" and C[y][x - 1] not in "6r" and C[y][x + 1] not in "6r":
				C[y][x] = "m" if y == 4 else "h"
	C[ASC_Z[1]][ASC_Z[0]] = "V"
	hueco_aparc(C, "zorroza", ".")
	return C, blds


# ---------------------------------------------------------------------------------------------------------------- La Punta
# El triángulo donde el Kadagua (oeste) entra en la ría (norte): la orilla en diagonal hasta la punta, arriba a la izquierda, con el
# molino de harinas y sus silos en la misma punta; el muelle de piedra con los norays y la última grúa de pórtico; las naves de chapa
# y los pabellones de ladrillo a los dos lados de la calle; y abajo, junto al Kadagua, la franja verde con el bidegorri.
def lapunta(DEC):
	W, H = 46, 32
	C = lienzo(W, H, "h")
	borde(C, W, H, "M")
	blds = []
	rect(C, 0, 0, W - 1, 3, "~")
	for y in range(4, CALLE_Y):                                    # la orilla en diagonal: la punta
		lim = CALLE_Y - y
		for x in range(lim):
			C[y][x] = "~"
		C[y][lim] = "m"
	rect(C, 10, 4, W - 2, 4, "m")                                  # el muelle de piedra, con sus norays al canto
	rect(C, 20, 5, W - 2, 7, "m")
	for x in range(12, W - 1, 4):
		C[4][x] = "o"
	for x in (22, 30, 38):
		C[6][x] = "7"
	edif(C, blds, "molino", 11, 5, 8, 9)                          # el molino con sus silos, en la punta
	edif(C, blds, "grua", 24, 4, 4, 7)                             # la grúa de pórtico
	for x in (21, 23, 29, 31):
		C[12][x] = "Q"
	edif(C, blds, "nave", 32, 8, 6, 6)
	edif(C, blds, "ladrillo", 38, 8, 7, 6)
	calle(C, DEC, CALLE_Y, 0, W - 1, cruces=(17, 33), suelo="h")
	lados(C, W, False, True, "h")
	rect(C, 0, CALLE_Y, 1, CALLE_Y + 5, "~")                      # por el oeste, el Kadagua también junto a la calle: es la punta, no se sigue
	rect(C, 2, CALLE_Y, 2, CALLE_Y + 5, "_")
	rect(C, 0, 20, 1, H - 1, "~")                                  # el Kadagua, al oeste de la calle
	for y in range(20, H):
		C[y][2] = "_"
	edif(C, blds, "ladrillo", 4, 20, 7, 6)
	edif(C, blds, "nave", 12, 20, 6, 6)
	edif(C, blds, "nave", 26, 20, 6, 6)
	edif(C, blds, "ladrillo", 33, 20, 7, 6)
	C[22][41] = "8"
	rect(C, 3, 27, W - 2, 30, "g")                                 # la franja verde con el bidegorri
	for x in range(5, W - 2, 6):
		C[27][x] = "y"
	rect(C, 3, 29, W - 2, 29, ",")
	paseo(C, 29, 3, W - 2, ",", "L", "n", "3", paso=12, desde=4)
	hueco_aparc(C, "lapunta", "h")
	return C, blds


# ------------------------------------------------------------------------------------------------------------------ Abando
# El Ensanche (lo pidió el usuario: «la estructura del mapa que se parezca al lugar»): la retícula de manzanas cerradas entre calles que
# se cruzan. La Gran Vía (la calle, con sus plátanos) de oeste a este y tres calles de norte a sur que la cortan (V_ABANDO: acera,
# calzada de dos carriles y acera); en la primera, la plaza elíptica, una glorieta (el asfalto del cruce alrededor de la isleta del
# jardín con la fuente) donde se cruzan la Gran Vía y la calle; con el palacio de ladrillo al norte, el hotel de la esquina curva al
# sureste y la iglesia neogótica de ladrillo de Indautxu al suroeste. Después, los jardines con su estatua, la Diputación y el teatro
# del arco; la calle que baja a la estación; la plaza redonda, otra glorieta con la estatua en su isleta, la torre oscura al norte y la
# estación al sur; y la calle que sigue hasta el puente sobre la ría, que llega al Casco Viejo. Las manzanas, con miradores.
V_ABANDO = (12, 26, 41)                                            # la acera de la izquierda de cada calle de norte a sur
MOYUA = (9, 18, 12, 21)                                            # la glorieta de la plaza elíptica (x0, x1, y0, y1)
CIRCULAR = (45, 54, CALLE_Y, CALLE_Y + 5)                          # la de la plaza redonda


def glorieta(C, x0, x1, y0, y1, isla):
	"""el anillo de asfalto (2 de ancho) alrededor de la isleta; isla(x, y) da lo de dentro"""
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			C[y][x] = "^" if x < x0 + 2 or x > x1 - 2 or y < y0 + 2 or y > y1 - 2 else isla(x, y)


def abando(DEC):
	W, H = 62, 36
	C = lienzo(W, H, ".")
	borde(C, W, H, "s")
	blds = []
	rect(C, 59, 0, W - 1, H - 1, "~")                              # la ría, al este
	for y in range(H):
		C[y][58] = "_"
	edif(C, blds, "chavarri", 3, 0, 7, 5)                          # el norte de la Gran Vía: el palacio en la plaza elíptica
	edif(C, blds, "ensB2", 17, 0, 7, 8)
	rect(C, 30, 1, 40, 13, ",")                                    # los jardines, con la estatua
	for x0, y0 in ((31, 2), (37, 2), (31, 8), (37, 8)):
		rect(C, x0, y0, x0 + 2, y0 + 3, "g")
		C[y0 + 1][x0 + 1] = "y"
	C[6][35] = "i"
	for x in (30, 40):
		C[6][x] = "L"
	C[12][34], C[12][35] = "n", "3"
	edif(C, blds, "torreBBVA", 46, 0, 6, 14)
	for x in (45, 52, 53):                                         # la plaza redonda, a los lados de la torre
		for y in range(8, CALLE_Y):
			C[y][x] = ","
	for y in (10, 12):                                             # el paseo de la ría
		C[y][57] = "Y"
	edif(C, blds, "diputacion", 30, 20, 8, 6)                      # el sur
	edif(C, blds, "camposE", 31, 28, 8, 7)
	edif(C, blds, "abandoE", 46, 20, 8, 7)
	edif(C, blds, "concordia", 54, 20, 4, 6)
	edif(C, blds, "carlton", 17, 23, 7, 7)
	edif(C, blds, "milagrosa", 3, 27, 6, 8)
	edif(C, blds, "ensB", 46, 28, 7, 8)
	for y in range(1, H - 1):                                      # la plaza elíptica, alrededor de su glorieta
		for x in range(1, 26):
			if CALLE_Y <= y < CALLE_Y + 6 or C[y][x] != "." or elipse(x, y, 13.5, 16.5, 10.5, 12.5) > 1:
				continue
			C[y][x] = ","
	for x, y in ((6, 9), (21, 9), (6, 23), (24, 23)):
		C[y][x] = "L"
	C[9][9], C[9][10], C[9][17], C[9][18] = "n", "3", "n", "3"
	C[25][9], C[25][10], C[26][24], C[26][25] = "n", "3", "n", "3"
	calle(C, DEC, CALLE_Y, 0, W - 1, arbol=True, cruces=(22, 35))  # la Gran Vía
	lados(C, W, True, True)
	for xa in V_ABANDO:                                            # las calles de norte a sur, de lado a lado del mapa
		for y in range(H):
			en = CALLE_Y <= y < CALLE_Y + 6
			C[y][xa + 1], C[y][xa + 2] = ("^", "^") if CALLE_Y + 2 <= y <= CALLE_Y + 3 else ("{", "}")
			if not en:
				C[y][xa] = C[y][xa + 3] = "," if C[y][xa] == "," else "."
	x0, x1, y0, y1 = MOYUA                                         # la glorieta de la plaza elíptica: la isleta, jardín con la fuente
	glorieta(C, x0, x1, y0, y1, lambda x, y: "F" if (x, y) == (13, 16) else "L" if (x, y) in ((11, 14), (16, 19)) else "f" if x in (11, 16) or y in (14, 19) else "g")
	x0, x1, y0, y1 = CIRCULAR                                      # la de la plaza redonda: la isleta de losas con la estatua
	glorieta(C, x0, x1, y0, y1, lambda x, y: "i" if (x, y) == (49, 16) else ",")
	rect(C, 59, CALLE_Y - 1, W - 1, CALLE_Y - 1, "_")              # el puente
	rect(C, 59, CALLE_Y + 6, W - 1, CALLE_Y + 6, "_")
	for y in range(H):                                             # lo de 2 casillas que se queda partido por las calles, fuera
		for x in range(W - 1):
			if C[y][x] in "C" and C[y][x + 1] not in ".,":
				C[y][x] = "."
	hueco_aparc(C, "abando", ".")
	return C, blds


# ------------------------------------------------------------------------------------------------------------- Casco Viejo
# La ría por el oeste y por el sur. El puente (la calle) llega a la plaza del teatro; al norte, el paseo del Arenal con sus plátanos
# y el quiosco, la iglesia barroca de las dos torres en su punta y la plaza porticada, cerrada, con su paso; al sur del teatro, la
# Ribera; las Siete Calles de norte a sur (de 2 casillas), con las casas estrechas apiladas, el cantón de en medio, la catedral en su
# plaza con la fuente y la calle Ronda al este; abajo, la Ribera con el mercado en la orilla y, en la esquina, la iglesia del puente
# de piedra, que cruza la ría hacia el sur.
SIETE = (15, 20, 25, 30, 35, 40, 45)                               # las Siete Calles (x de la primera casilla)
def casco(DEC):
	W, H = 50, 40
	C = lienzo(W, H, "k")
	borde(C, W, H, "M")
	blds = []
	rect(C, 0, 0, 3, H - 1, "~")                                   # la ría, por el oeste
	rect(C, 0, 36, W - 1, H - 1, "~")                              # y por el sur
	for y in range(36):
		C[y][4] = "_"
	rect(C, 5, 35, W - 2, 35, "_")
	calle(C, DEC, CALLE_Y, 0, 13)                                  # el puente y la plaza del teatro
	rect(C, 0, CALLE_Y - 1, 3, CALLE_Y - 1, "_")
	rect(C, 0, CALLE_Y + 6, 3, CALLE_Y + 6, "_")
	lados(C, W, True, False)
	C[CALLE_Y + 2][14] = C[CALLE_Y + 3][14] = "2"                  # se acaba la calzada: los bolardos
	for x in range(18, W - 1, 8):                                  # la calle peatonal hacia la calle Ronda
		C[CALLE_Y + 1][x] = C[CALLE_Y + 4][x] = "j"
	rect(C, 5, 1, 15, 13, ",")                                     # el Arenal
	rect(C, 7, 3, 13, 11, "g")
	rect(C, 8, 5, 12, 8, ",")
	edif(C, blds, "kiosko", 9, 6, 3, 2)
	for y in (2, 5, 8, 11):
		C[y][6] = C[y][14] = "a"
	C[12][8], C[12][9], C[12][11], C[12][12] = "n", "3", "n", "3"
	C[2][10] = C[12][10] = "L"
	edif(C, blds, "sanNicolas", 16, 0, 6, 7)                       # la iglesia en la punta del Arenal, con su plaza
	rect(C, 16, 7, 21, 13, ",")
	C[9][16] = C[9][21] = "L"
	edif(C, blds, "plazaN", 23, 0, 16, 4)                          # la plaza porticada, cerrada, con su paso
	edif(C, blds, "plazaL", 23, 4, 2, 6)
	edif(C, blds, "plazaR", 37, 4, 2, 6)
	edif(C, blds, "plazaS", 23, 10, 7, 4)
	edif(C, blds, "plazaS", 32, 10, 7, 4)
	rect(C, 25, 4, 36, 9, ",")
	for x, y in ((25, 4), (36, 4), (25, 9), (36, 9)):
		C[y][x] = "L"
	rect(C, 40, 1, 48, 6, "M")                                     # la ladera de detrás y las casas de la esquina
	edif(C, blds, "casco", 40, 8, 4, 6)
	edif(C, blds, "casco3", 44, 7, 5, 7)
	edif(C, blds, "teatro", 6, 20, 8, 7)                           # el teatro, de cara al puente
	rect(C, 5, 20, 5, 34, "m")
	for i, x in enumerate(SIETE[:-1]):                             # las Siete Calles, en paralelo hasta la calle de la Ribera (filas 30-32),
		x0 = x + 2 + (1 if x > 25 else 0)                          # con las manzanas de casas estrechas de fachada seguida entre ellas
		                                                           # y un solo cantón estrecho que las cruza (fila 25)
		if x == 25:                                                # entre la tercera y la cuarta, la catedral y su plaza
			edif(C, blds, "catedral", 27, 20, 4, 6)
			rect(C, 27, 26, 30, 30, ",")
			C[28][28] = "F"
			C[26][27] = C[26][30] = "L"
			continue
		edif(C, blds, "casco2", x0, 20, 3, 5)
		edif(C, blds, "cascoB2" if i % 2 else "cascoB", x0, 26, 3, 4)
	edif(C, blds, "mercadoR", 17, 32, 14, 4)                       # la Ribera: el mercado en la orilla, con su muelle delante (se entra
	rect(C, 5, 33, 16, 34, "m")                                    # por abajo: la puerta, en la fila de abajo del edificio)
	paseo(C, 34, 5, 16, "m", "7", "6", "5")
	rect(C, 31, 33, 38, 34, "m")
	paseo(C, 34, 31, 38, "m", "7", "6", "5")
	C[35][31] = "m"
	rect(C, 17, 36, 31, 36, "m")
	C[36][16] = "_"
	rect(C, 16, 37, 32, 37, "_")
	C[36][32] = "_"
	edif(C, blds, "sanAnton", 39, 33, 6, 6)                        # la iglesia y su puente de piedra
	rect(C, 45, 33, 48, 34, "m")
	for y in range(35, H):
		C[y][45], C[y][46], C[y][47], C[y][48] = "_", "p", "p", "_"
	C[H - 1][46] = C[H - 1][47] = "|"
	rect(C, 39, H - 1, 45, H - 1, "m")                             # el muelle de la iglesia, de su puerta al puente
	hueco_aparc(C, "casco", "k")
	return C, blds

# ------------------------------------------------------------------------------------------------------------ por dentro
# (lo pidió el usuario: «en los que has hecho de Bilbao, hay edificios que no se puede acceder… molaría poder acceder al teatro… la
# iglesia también… piensa en qué edificios podrían tener juego en la historia»): el teatro, las iglesias y el mercado se entran por su
# puerta (doors con gate, venta.gd entra_local → ciudad.gd); dentro, mapas propios (BILBAO.IN), con el arte a mano de
# tools/sprites/a-mano/interiores_bilbao.py. PUERTAS: edificio → [mapa, gate, x de la puerta (2 casillas), llegada dentro]
# Después de la revisión (que no quede Bilbao sin entrar): las estaciones, donde se coge el tren (estacion:<k>); la iglesia del
# puente y la de Indautxu; el segundo teatro, el del Ensanche (teatro:camposE); la Diputación, con la ventanilla de Hacienda
# (hacienda); y en La Punta, el molino de mareas (molino) y el almacén del muelle, con su jornal (almacen). Una clave «id@x0»
# elige uno de varios edificios iguales. Las torres, los bloques y los pisos, sin entrar: son casas de otros.
# la casilla de la puerta de cada edificio que se entra (la 1.ª de las dos), debajo del arco o de las puertas que dibuja su fachada
# (lo pidió el usuario: «todas las entradas a edificios deberían estar cuadradas con las baldosas»; tests/puertas_rejilla.gd)
PUERTAS = {
	"casco": {"teatro": ["teatro-in", "teatro", 9], "catedral": ["catedral-in", "iglesia:catedral", 28], "mercadoR": ["mercado-in", "mercado", 23],
		"sanNicolas": ["sannicolas-in", "iglesia:sanNicolas", 18], "sanAnton": ["sananton-in", "iglesia:sanAnton", 42]},
	"zorroza": {"iglesiaZ": ["iglesiaz-in", "iglesia:iglesiaZ", 22], "estacion": ["zorrozae-in", "estacion:estacion", 8]},
	"abando": {"milagrosa": ["milagrosa-in", "iglesia:milagrosa", 4], "camposE": ["campose-in", "teatro:camposE", 34],
		"abandoE": ["abandoe-in", "estacion:abandoE", 49], "concordia": ["concordia-in", "estacion:concordia", 55],
		"diputacion": ["hacienda-in", "hacienda", 33]},
	"lapunta": {"molino": ["molino-in", "molino", 16], "nave@32": ["almacen-in", "almacen", 34]},
}
IN_N = {"teatro-in": "Teatro", "catedral-in": "La catedral", "mercado-in": "Mercado de la Ribera", "sannicolas-in": "San Nicolás",
	"iglesiaz-in": "La parroquia", "sananton-in": "San Antón", "milagrosa-in": "La parroquia de Indautxu", "campose-in": "Teatro del Ensanche",
	"zorrozae-in": "Estación de Zorroza", "abandoe-in": "Estación de Abando", "concordia-in": "Estación de la Concordia",
	"hacienda-in": "Diputación", "molino-in": "Molino de mareas", "almacen-in": "Almacén del muelle"}


IN_ANCHO = ("decoT", "palcoT", "taquillaT", "panelE", "ruedaM", "retabloI", "retabloB", "cruzZ", "altarI", "confesI", "barraMe", "puestoFr", "puestoPe", "puestoCa",
	"puestoQu", "puestoVe", "puestoPa", "puestoFl", "puestoEs")


def interior(nombre, W, H, suelo, pared, musica):
	g = [[suelo] * W for _ in range(H)]
	for x in range(W):
		g[0][x], g[1][x] = "iwT_" + pared, "iwB_" + pared
	return {"name": nombre, "w": W, "h": H, "g": g, "o": [[None] * W for _ in range(H)], "exits": {}, "doors": {}, "music": musica,
		"blds": [], "est": None}


def salida(m, xs, to, tx, ty):
	for i, x in enumerate(xs):
		m["g"][m["h"] - 1][x] = "mat"
		m["exits"]["%d,%d" % (x, m["h"] - 1)] = {"to": to, "x": tx + i, "y": ty, "dir": "down"}


def teatro_in(nombre="Teatro", to="casco", tx=9, ty=27):
	"""el teatro por dentro (20 × 15): arriba, el escenario de tablas entre las dos columnas del proscenio, con el telón recogido a
	los lados, el decorado al fondo y los palcos en la pared; la boca del escenario con las candilejas y dos escalones; el patio de
	butacas en tres filas con los pasillos (las butacas, de espaldas: te sientas mirando al escenario); abajo, el vestíbulo con la
	taquilla y los carteles"""
	W, H = 20, 15
	m = interior(nombre, W, H, "floorTeat", "teat", "club")
	g, o = m["g"], m["o"]
	for y in range(2, 5):
		for x in range(4, 16):
			g[y][x] = "tablado"
		for x in (2, 3, 16, 17):
			g[y][x] = "iwB_teatP"                                     # el proscenio: las columnas pintadas, sólidas
	for x in range(4, 16):
		g[5][x] = "iwB_teatF"                                         # la boca del escenario, con las candilejas
	g[5][4] = g[5][15] = "escalonT"                                   # los dos escalones de subida
	o[2][4], o[2][15] = "telonI", "telonD"                            # el telón recogido, a los lados
	for x in (6, 8, 10, 12):
		o[1][x] = "decoT"                                             # el decorado del fondo (de 2 casillas)
	o[1][0], o[1][18] = "palcoT", "palcoT"                            # los palcos de la pared
	for y, a, b in ((7, 4, 15), (9, 3, 16), (11, 2, 17)):          # el patio en abanico: cada fila, una butaca más por cada lado
		for x in list(range(a, 9)) + list(range(11, b + 1)):
			o[y][x] = "butaca"
	o[11][2] = None                                                   # y la esquina de la última, rota: sin la del rincón
	o[13][16] = "taquillaT"                                           # la taquilla (de 2 casillas) y la taquillera, a su derecha
	o[13][1] = "cartelT"
	o[13][2] = "cartelT2"                                             # bajo la esquina sin butaca: alto, no tapa la fila de delante
	o[12][19] = "plantaT"
	salida(m, (9, 10), to, tx, ty)
	return m


def iglesia_in(k, nombre, W, H, to, tx, ty, retablo="retabloI"):
	"""una iglesia por dentro: el presbiterio arriba (el retablo en la pared, el altar con sus dos velas y el sacerdote), dos
	escalones, la nave con los bancos a los dos lados del pasillo de la alfombra, las columnas, el confesionario, el lampadario de
	las velas, el cepillo y las pilas del agua junto a la puerta"""
	m = interior(nombre, W, H, "floorIg", "ig", "casa_ama")
	g, o = m["g"], m["o"]
	cx = W // 2 - 1                                                   # el pasillo del centro: cx, cx + 1
	for y in range(2, 4):
		for x in range(2, W - 2):
			g[y][x] = "presbI"
	o[1][cx] = retablo                                                # el retablo (de 2 casillas), en la pared
	o[3][cx] = "altarI"                                               # el altar (de 2 casillas)
	o[2][2], o[2][W - 3] = "cirioI", "cirioI"
	for x in range(2, W - 2):
		g[4][x] = "escalonI"
	for y in range(5, H - 1):
		g[y][cx] = g[y][cx + 1] = "alfombraI"
	for y in range(6, H - 3, 2):
		for x in list(range(2, cx - 1)) + list(range(cx + 3, W - 2)):
			o[y][x] = "bancoI"
	o[6][2] = None                                                    # el primer banco de la izquierda, quitado para las velas del santo
	o[list(range(6, H - 3, 2))[-1]][W - 3] = None                                 # y uno del fondo, junto al confesionario
	for y in range(6, H - 3, 4):
		o[y][0] = o[y][W - 1] = "columnaI"
	o[H - 2][W - 3] = "confesI"                                       # el confesionario (de 2 casillas), a la derecha, contra la pared del fondo
	for y in range(H - 4, H - 2):                                     # y, delante de él, ni banco ni columna: es alto y los taparía
		for x in (W - 4, W - 3, W - 2, W - 1):
			if o[y][x] in ("bancoI", "columnaI"):
				o[y][x] = None
	o[6][2] = "velasI"                                                # el lampadario de las velas del santo, en el sitio del primer banco
	# (lo pidió el usuario: «que ningún objeto de pared o suelo se superponga sobre otro»): ni el lampadario ni el confesionario,
	# que son altos, delante de un banco o de una columna (tests/solapes.gd)
	o[H - 2][2] = "cepilloI"
	o[H - 2][cx - 1], o[H - 2][cx + 2] = "pilaI", "pilaI"
	salida(m, (cx, cx + 1), to, tx, ty)
	return m


def mercado_in():
	"""el mercado por dentro (22 × 12): el terrazo, la pared de azulejo con los ventanales, dos calles de puestos (de 2 casillas): la
	fruta, el pescado en hielo, la carne, los quesos, las verduras y el pan; abajo, la barra de pintxos con sus taburetes"""
	W, H = 22, 12
	m = interior("Mercado de la Ribera", W, H, "floorMe", "me", "bar")
	o = m["o"]
	for x, y, p in ((2, 3, "puestoFr"), (6, 4, "puestoPe"), (10, 3, "puestoCa"), (14, 4, "puestoQu"), (18, 3, "puestoVe"),
			(2, 8, "puestoPa"), (6, 7, "puestoFl"), (15, 8, "puestoEs")):   # los puestos, a tresbolillo: nada en fila de regla
		o[y][x] = p
	o[7][9], o[7][11] = "barraMe", "barraMe"                         # la barra de pintxos (dos de 2 casillas)
	for x in (9, 10, 11, 12):
		o[8][x] = "taburMe"
	o[10][1], o[10][20] = "cajasMe", "cajasMe"
	salida(m, (10, 11), "casco", 23, 36)
	return m


def estacion_in(nombre, W, to, tx, ty):
	"""una estación por dentro (W × 11): el vestíbulo de terrazo con los ventanales; la taquilla (de 2 casillas) con su taquillero,
	la máquina de billetes, el panel de salidas en la pared, los bancos de la espera en dos filas, la papelera y, al fondo, el paso
	a los andenes (cerrado: se sube al tren desde la taquilla)"""
	H = 11
	m = interior(nombre, W, H, "floorMe", "me", "ensanche")
	o = m["o"]
	o[4][2] = "taquillaT"                                             # la taquilla, y el taquillero detrás (gente_in)
	o[3][W - 4] = "maquinaE"
	o[1][W // 2 - 1] = "panelE"                                       # el panel de salidas (de 2 casillas), en la pared
	for y, xs in ((6, range(W // 2 - 3, W // 2 - 1)), (6, range(W // 2 + 1, W // 2 + 3)), (8, range(W // 2 - 4, W // 2 - 1))):
		for x in xs:
			o[y][x] = "bench"
	o[H - 2][W - 2] = "papelera"
	o[H - 2][1] = "plantaT"
	cx = W // 2 - 1
	salida(m, (cx, cx + 1), to, tx, ty)
	return m


def hacienda_in():
	"""la Diputación por dentro (16 × 10): el palacio, con la piedra y el damasco; dos ventanillas (de 2 casillas) de Hacienda con la
	funcionaria detrás de la de la izquierda, las columnas, los bancos de la espera y las plantas"""
	W, H = 16, 10
	m = interior("Diputación", W, H, "floorIg", "teat", "casa_ama")
	o = m["o"]
	o[3][3], o[3][10] = "taquillaT", "taquillaT"
	for x in (1, 14):
		o[3][x] = "columnaI"
		o[6][x] = "columnaI"
	for x in (5, 6, 9, 10):
		o[6][x] = "bench"
	o[8][1], o[8][14] = "plantaT", "plantaT"
	salida(m, (7, 8), "abando", 33, 26)
	return m


def molino_in():
	"""el molino de mareas por dentro (14 × 9): la piedra, las losas, la rueda (de 2 casillas) que mueve la marea por el canal de
	abajo, los sacos de grano apilados, el banco del molinero y la papelera"""
	W, H = 14, 9
	m = interior("Molino de mareas", W, H, "floorIg", "bajo", "astilleros")
	o = m["o"]
	o[3][5] = "ruedaM"
	for x, y in ((1, 3), (1, 4), (2, 3), (11, 3), (12, 3), (12, 4)):
		o[y][x] = "sacos"
	o[6][2], o[6][3] = "bench", "bench"
	o[7][12] = "cajasMe"
	salida(m, (6, 7), "lapunta", 16, 14)
	return m


def almacen_in():
	"""el almacén del muelle por dentro (16 × 10): el hormigón de la nave, las cajas y los sacos de la carga en hileras con su
	pasillo, el banco de los estibadores y el capataz junto a la puerta"""
	W, H = 16, 10
	m = interior("Almacén del muelle", W, H, "floorN", "nave", "astilleros")
	o = m["o"]
	for x in (2, 3, 5, 10, 12, 13):
		o[3][x] = "cajasMe"
	for x in (2, 4, 11, 13):
		o[5][x] = "sacos"
	o[8][1], o[8][2] = "bench", "bench"
	o[8][14] = "papelera"
	salida(m, (7, 8), "lapunta", 34, 14)
	return m


def interiores(B):
	"""BILBAO.IN: los mapas de dentro; y en los de fuera, la puerta de cada edificio (doorX, ancha y la casilla door_), con su gate"""
	IN = {"teatro-in": teatro_in(), "mercado-in": mercado_in(),
		"catedral-in": iglesia_in("catedral", "La catedral", 16, 16, "casco", 28, 26),
		"sannicolas-in": iglesia_in("sanNicolas", "San Nicolás", 14, 14, "casco", 18, 7, "retabloB"),
		"iglesiaz-in": iglesia_in("iglesiaZ", "La parroquia", 14, 13, "zorroza", 22, 28, "cruzZ"),
		"sananton-in": iglesia_in("sanAnton", "San Antón", 12, 12, "casco", 42, 39, "retabloB"),
		"milagrosa-in": iglesia_in("milagrosa", "La parroquia de Indautxu", 14, 15, "abando", 4, 35),
		"campose-in": teatro_in("Teatro del Ensanche", "abando", 34, 35),
		"zorrozae-in": estacion_in("Estación de Zorroza", 16, "zorroza", 8, 14),
		"abandoe-in": estacion_in("Estación de Abando", 22, "abando", 49, 27),
		"concordia-in": estacion_in("Estación de la Concordia", 14, "abando", 55, 26),
		"hacienda-in": hacienda_in(), "molino-in": molino_in(), "almacen-in": almacen_in()}
	for m in IN.values():                                              # lo de 2 casillas: la de la derecha, k + "2" (sólida, sin dibujo)
		for row in m["o"]:
			for x in range(len(row) - 1):
				if row[x] in IN_ANCHO:
					row[x + 1] = row[x] + "2"
	for k, P in PUERTAS.items():
		m = B["MAPS"][k]
		for b in m["blds"]:
			kb = b["id"] if b["id"] in P else "%s@%d" % (b["id"], b["x0"])
			if kb not in P:
				continue
			to, gate, dx = P[kb]
			dy = int(b["y0"]) + int(b["h"]) - 1
			b["doorX"], b["ancha"], b["dx"] = dx, 1, 8   # la puerta de 32 px, encima de sus dos casillas (la del almacén del muelle)
			for i in (0, 1):
				assert m["g"][dy + 1][dx + i] not in ("water",) and not m["o"][dy + 1][dx + i], "%s: delante de %s (%d, %d)" % (k, b["id"], dx + i, dy + 1)
				m["g"][dy][dx + i] = "door_" + b["id"]
				ex = IN[to]["exits"]
				llega = [c for c in ex][0]
				m["doors"]["%d,%d" % (dx + i, dy)] = {"to": to, "x": int(llega.split(",")[0]) + i, "y": IN[to]["h"] - 2, "dir": "up", "gate": gate}
	B["IN"] = IN
	B["NPC"] = gente_in(IN)


def gente_in(IN):
	"""BILBAO.NPC: la gente de dentro (ciudad.gd, ciudad_npcs), cada uno con su horario en minutos [desde, hasta): la taquillera
	detrás de la taquilla, la actriz que ensaya de día, los dos de la función, el cura junto al altar de cada iglesia y una
	feligresa en la catedral, los del mercado detrás de su puesto y el camarero detrás de la barra (el muñeco, del sexo del
	oficio: GENERO.mujeres)"""
	def p(i, mp, x, y, look, d, h, dr="down"):
		assert not IN[mp]["o"][y][x], "%s: %s encima de %s" % (mp, i, IN[mp]["o"][y][x])
		return {"id": "bi_" + i, "map": mp, "x": x, "y": y, "look": look, "dir": dr, "wander": 0, "desde": d, "hasta": h}
	L = [p("taquillera", "teatro-in", 16, 12, "cliente4", 600, 1290), p("ainhoa", "teatro-in", 9, 3, "cliente6", 600, 1200),
		p("actor1", "teatro-in", 7, 3, "oldman", 1260, 1380), p("actor2", "teatro-in", 12, 3, "cliente2", 1260, 1380),
		p("feligresa", "catedral-in", 11, 9, "granny", 480, 1200, "up")]
	L += [p("taquillera_c", "campose-in", 16, 12, "cliente6", 600, 1290), p("actor1_c", "campose-in", 7, 3, "cliente2", 1260, 1380),
		p("actor2_c", "campose-in", 12, 3, "turista", 1260, 1380)]
	for mp in ("zorrozae-in", "abandoe-in", "concordia-in"):                # el taquillero, detrás de la taquilla, y el vigilante
		L += [p("taquillero_" + mp[:-3], mp, 2, 3, "obrero", 360, 1380), p("vigilante_" + mp[:-3], mp, IN[mp]["w"] - 2, 6, "judge", 360, 1380, "left")]
	L += [p("funcionaria", "hacienda-in", 3, 2, "cliente4", 510, 840), p("molinero", "molino-in", 8, 6, "oldman", 540, 1140, "left"),
		p("capataz", "almacen-in", 13, 8, "obrero", 420, 900, "left")]
	for mp in ("catedral-in", "sannicolas-in", "iglesiaz-in", "sananton-in", "milagrosa-in"):
		cx = IN[mp]["w"] // 2 - 1
		L.append(p("cura_" + mp[:-3], mp, cx + 2, 3, "judge", 480, 1200))
	o = IN["mercado-in"]["o"]
	look = {"puestoFr": "cliente4", "puestoPe": "sailor", "puestoCa": "obrero", "puestoQu": "granny", "puestoVe": "cliente2",
		"puestoPa": "cliente6", "puestoFl": "turista", "puestoEs": "oldman"}
	for y in range(len(o)):
		for x in range(len(o[y])):
			if o[y][x] in look:
				L.append(p("me_" + o[y][x][6:].lower(), "mercado-in", x, y - 1, look[o[y][x]], 480, 900))
	L.append(p("camarero", "mercado-in", 10, 6, "socio", 480, 900))
	return L


ZONAS_N = {"zorroza": "Zorroza", "lapunta": "La Punta", "abando": "Abando", "casco": "Casco Viejo"}
MUSICA = {"zorroza": "town", "lapunta": "astilleros", "abando": "ensanche", "casco": "ibarbide"}
CADENA = ["lapunta", "zorroza", "abando", "casco"]   # de oeste a este: La Punta, en la boca del Kadagua, al oeste de Zorroza
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
		"PATRULLAS": {k: [1, 2] for k in ZONAS_N}, "KM": 14, "APARC": {k: list(v) for k, v in APARC.items()}, "PRE": {"zorroza": "z", "lapunta": "u", "abando": "a", "casco": "o"}}
	for k, f in (("lapunta", lapunta), ("zorroza", zorroza), ("abando", abando), ("casco", casco)):
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
		for c in list(DEC):                                            # lo del suelo, solo en la calzada de la calle y sin nada encima
			x, y = map(int, c.split(","))
			if m["o"][y][x] or m["g"][y][x] not in ("roadT", "roadB"):
				del DEC[c]
		if k == "zorroza":
			m["escaleras"] = ESC_Z
		B["MAPS"][k] = m
		B["DEC"][k] = DEC
	tablas(B)
	interiores(B)
	D["BILBAO"] = B
	s = json.dumps(D, ensure_ascii=False, separators=(",", ":"))
	open(DATOS, "w", encoding="utf-8").write(s)
	print("bilbao: %d mapas, %d cosas en el suelo" % (len(B["MAPS"]), sum(len(v) for v in B["DEC"].values())))


if __name__ == "__main__":
	sys.exit(main())
