#!/usr/bin/env python3
# Landrace Hunters — la red de carreteras (lo pidió el usuario: «hay mapas que conectan ciertos pueblos, eso se tiene que ver
# reflejado en el mapa… no hay más caminos entre los demás pueblos? Habría que crearlos»; eligió la red completa). Escribe en
# godot/datos/datos.json, con Datos.CAL en el juego:
#   MAPS["carr-<k>"]   siete carreteras de 40 × 14 que se andan, como la comarcal, cada una con su paisaje;
#   CARRETERAS         rutas (pueblo de la izquierda y de la derecha, capítulo) y, por pueblo, las salidas que se abren en su
#                      borde (la casilla del borde pasa a suelo y sin estorbo, y lleva a su carretera).
# Se puede volver a ejecutar: rehace lo suyo y no toca nada más.
#   python3 -I tools/carreteras.py
import json
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, "godot", "datos", "datos.json")
W, H = 40, 14
RY = 6   # las dos filas de la calzada: RY y RY + 1

# [id, nombre, (pueblo de la izquierda, casillas del borde, lado), (pueblo de la derecha, …), paisaje]
RUTAS = [
	["costa", "Carretera de la costa", ("puerto", [(39, 13), (39, 14)], "right"), ("town", [(0, 10), (0, 11)], "left"), "costa"],
	["valle", "Carretera del valle", ("valdehierro", [(39, 9), (39, 10)], "right"), ("town", [(2, 29)], "down"), "valle"],
	["monte", "Carretera del monte", ("town", [(14, 29)], "down"), ("mendialde", [(0, 17), (0, 18)], "left"), "monte"],
	["general", "La general", ("town", [(39, 10), (39, 11)], "right"), ("ibarbide", [(0, 21), (0, 22)], "left"), "general"],
	["molino", "Carretera del molino", ("town", [(28, 29)], "down"), ("errotabarri", [(15, 0)], "up"), "molino"],
	["acantilado", "Pista de los acantilados", ("puerto", [(39, 8)], "right"), ("valdehierro", [(0, 9), (0, 10)], "left"), "acantilado"],
	["ribera", "Carretera de la ribera", ("errotabarri", [(35, 11), (35, 12)], "right"), ("ibarbide", [(38, 29)], "down"), "ribera"],
]
# por su lado (lo pidió el usuario: «si yo voy del camino de izquierda a derecha, no puedo aparecer a la derecha del pueblo»): el
# pueblo de la izquierda sale por su derecha (o por arriba o abajo) y el de la derecha, por su izquierda (o por arriba o abajo)
for _r in RUTAS:
	assert _r[2][2] != "left" and _r[3][2] != "right", "carretera %s: el pueblo sale por el lado de la otra punta" % _r[0]
# casillas de más que se abren hacia dentro (la salida del norte de Errotabarri pasa por la fila 1; la de Puerto Viejo, por (38, 13),
# que antes del muelle es monte)
ABRE_MAS = {"errotabarri": [((15, 1), (15, 0))], "puerto": [((38, 13), (39, 13))]}   # (casilla, la salida que la abre)
DV = {"left": (-1, 0), "right": (1, 0), "up": (0, -1), "down": (0, 1)}
OPUESTO = {"left": "right", "right": "left", "up": "down", "down": "up"}


def h(x, y, s):
	v = (x * 374761393 + y * 668265263 + s * 2147483647) & 0x7fffffff
	v = ((v ^ (v >> 13)) * 1274126177) & 0x7fffffff
	return (v & 0xffff) / 65535.0


# las curvas (lo pidió el usuario: «molaría que los caminos no siempre sean rectos» y, después, «más tramos rectos»): [columna, ±1] —
# la calzada baja (+1) o sube (−1) una fila a lo largo de PIEZA columnas desde x; entre curva y curva, tramos rectos largos; los
# extremos siguen en las filas 6 y 7 (las salidas). Va en piezas de PIEZA × 3 casillas «cv<R|O|P>-<d|u>-<columna><fila>» (asfalto,
# roto o pista) que pinta.gd dibuja en curva suave, con escalones limpios.
PIEZA = 4
CURVAS = {
	"costa": [(9, -1), (27, 1)],
	"valle": [(7, 1), (25, -1)],
	"monte": [(12, -1), (24, 1)],
	"general": [],
	"molino": [(10, 1), (26, -1)],
	"acantilado": [(8, -1), (28, 1)],
	"ribera": [(12, 1), (29, -1)],
}


# las vallas seguidas: [primera columna, largo, fila] — los prados del valle y del molino y la barandilla del acantilado sobre el mar
VALLAS = {
	"valle": [(13, 10, 11), (29, 8, 3)],
	"molino": [(2, 7, 3), (15, 10, 11)],
	"acantilado": [(2, 10, 2), (19, 14, 2)],   # partida por las dos calas
}

# los biomas (lo pidió el usuario: «diferentes biomas, dentro de lo realista de la zona… zona playa, o zona más de monte, o zona más
# de llano, zona más de tierra, pero poco más»)
BIOMA = {"costa": "playa", "acantilado": "playa", "monte": "monte", "valle": "llano", "ribera": "llano", "general": "llano", "molino": "tierra"}

# la playa (lo pidió el usuario: «la playa molaría que no sea todo el rato recta, que haya alguna zona más entrada de la arena… más al
# interior será más verde todo»): por tramos de columnas (de 2 o más, sin salientes de una casilla) [desde, hasta, filas de agua, última
# fila de arena]; la arena, nunca a menos de una fila de hierba de la calzada; sin arena (última < filas de agua), el acantilado
PLAYA = {
	"costa": [(0, 1, 2, 3), (2, 5, 2, 4), (6, 8, 3, 4), (9, 12, 2, 3), (13, 16, 3, 3), (17, 20, 2, 3), (21, 26, 3, 3), (27, 30, 2, 3), (31, 39, 2, 4)],
	"acantilado": [(0, 11, 2, 1), (12, 13, 2, 3), (14, 16, 3, 3), (17, 18, 2, 3), (19, 32, 2, 1), (33, 34, 2, 4), (35, 36, 3, 4), (37, 38, 2, 4), (39, 39, 2, 1)],
}

# los bancales de la tierra arada del molino («surco», con sus surcos en pinta.gd): [desde, hasta, fila de arriba, fila de abajo], de 2 × 2 o más
BANCALES = {"molino": [(2, 8, 1, 2), (14, 21, 1, 3), (30, 36, 1, 3)]}   # por encima de la calzada (abajo los tapa el monte)

# lo suelto, por paisaje: lo que se pone, cuánto por encima de la calzada y por debajo; el suelo (hierba alta, flores) y cuánto
SUELTO = {
	"costa": (["bush"], 0.0, 0.06, ["tallgrass", "flowers", "tallgrass"], 0.34),   # bajo la calzada, hacia el interior, lo verde
	"acantilado": (["tree2", "bush"], 0.06, 0.1, ["tallgrass"], 0.22),
	"monte": (["tree", "tree2", "manzano", "tree"], 0.26, 0.1, ["tallgrass"], 0.36),   # el bosque, encima; debajo, matas
	"valle": (["tree2", "bush", "tree"], 0.04, 0.05, ["flowers", "tallgrass", "flowers"], 0.32),   # prados con flores
	"ribera": (["tree", "tree2", "bush"], 0.07, 0.05, ["flowers", "tallgrass"], 0.24),
	"general": (["seto", "tree"], 0.1, 0.1, ["flowers"], 0.18),
	"molino": (["manzano", "tree", "bush"], 0.05, 0.05, ["flowers"], 0.08),   # la tierra: bancales y poco más
}


def calzada_de(paisaje):
	"""Por columna, las filas de la calzada y, en las curvas, la pieza: {x: (filas, pieza o None)}."""
	pasos = dict(CURVAS[paisaje])
	top = RY
	col = {}
	x = 0
	while x < W:
		if x in pasos:
			d = pasos[x]
			arriba = top if d > 0 else top - 1
			for c in range(PIEZA):
				col[x + c] = (list(range(arriba, arriba + 3)), (d, c, arriba))
			top += d
			x += PIEZA
			continue
		col[x] = ([top, top + 1], None)
		x += 1
	assert top == RY, paisaje
	assert all(col[x][1] is None and col[x][0] == [RY, RY + 1] for x in (0, 1, W - 2, W - 1)), paisaje   # las salidas, rectas
	return col


def mapa(k, nombre, paisaje, musica):
	g = [["grass"] * W for _ in range(H)]
	o = [[None] * W for _ in range(H)]
	tipo = {"costa": ("roadT", "roadB", "R"), "valle": ("rotoT", "rotoB", "O"), "monte": ("roadT", "roadB", "R"), "general": ("roadT", "roadB", "R"),
		"molino": ("pista", "pista", "P"), "acantilado": ("pista", "pista", "P"), "ribera": ("roadT", "roadB", "R")}[paisaje]
	col = calzada_de(paisaje)

	def dist(x, y):
		return min(abs(y - r) for c in (x - 1, x, x + 1) if 0 <= c < W for r in col[c][0])

	for x in range(W):
		filas, pieza = col[x]
		if pieza is None:
			g[filas[0]][x], g[filas[1]][x] = tipo[0], tipo[1]
		else:
			d, c, arriba = pieza
			for r, y in enumerate(filas):
				g[y][x] = "cv%s-%s-%d%d" % (tipo[2], "d" if d > 0 else "u", c, r)
	# el borde: monte, salvo los dos extremos de la calzada
	for x in range(W):
		for y in (0, H - 1):
			o[y][x] = "monte" if (x + y) % 2 == 0 else "monte2"
	for y in range(H):
		for x in (0, W - 1):
			if y not in (RY, RY + 1):
				o[y][x] = "monte" if (x + y) % 2 == 0 else "monte2"
	# el agua (el mar arriba en la costa y los acantilados, con la playa; el río abajo en la ribera), sin monte encima
	for x0, x1, prof, fin in PLAYA.get(paisaje, []):
		for x in range(x0, x1 + 1):
			for y in range(H):
				if y < prof or y <= fin and dist(x, y) >= 2:
					assert g[y][x] == "grass", (paisaje, x, y)
					g[y][x], o[y][x] = "water" if y < prof else "arena", None
	if paisaje == "ribera":
		for y in (10, 11):
			for x in range(W):
				assert g[y][x] == "grass", (paisaje, x, y)
				g[y][x], o[y][x] = "water", None
	for x0, x1, y0, y1 in BANCALES.get(paisaje, []):   # la tierra arada
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				assert g[y][x] == "grass" and o[y][x] is None and dist(x, y) >= 3, (paisaje, x, y)
				g[y][x] = "surco"
	if paisaje == "ribera":   # el puente viejo sobre el río, a un lado
		for y in (10, 11):
			g[y][24] = "bridgeT" if y == 10 else "bridgeB"
	if paisaje == "general":   # las aceras
		for x in range(1, W - 1):
			g[RY - 1][x] = "walk"
			g[RY + 2][x] = "walk"
	# lo de los lados (lo pidió el usuario: «un poco mal los sprites, hazlo mejor»): primero lo puesto con sentido —las vallas de
	# los prados y la barandilla del acantilado, seguidas y paralelas a la calzada, las farolas de la general en la acera de arriba y
	# los bancos de la ribera mirando al río—; después, suelto, solo lo del campo (árboles, matas, frutales, setos), nunca en
	# la calzada ni a 2 filas de ella ni pegado a lo puesto
	def pon(x, y, cosa, minimo=3):
		assert 2 <= x < W - 2 and 1 <= y < H - 1 and g[y][x] == "grass" and o[y][x] is None and dist(x, y) >= minimo, (paisaje, x, y, cosa)
		o[y][x] = cosa

	for x0, largo, y in VALLAS.get(paisaje, []):
		for x in range(x0, x0 + largo):
			pon(x, y, "fence")
	if paisaje == "ribera":   # dos bancos entre la carretera y el río, mirando al agua (no delante del puente)
		for x in (18, 21):
			pon(x, col[x][0][1] + 1, "bench", 1)
	if paisaje == "general":   # las farolas en la acera de arriba, como en el pueblo
		for x in range(3, W - 2, 6):
			assert g[RY - 1][x] == "walk" and o[RY - 1][x] is None
			o[RY - 1][x] = "lamp"
	cosas, p_arriba, p_abajo, suelo, p_suelo = SUELTO[paisaje]
	sid = sum(ord(c) for c in k)
	puesto = [(x, y) for y in range(H) for x in range(W) if o[y][x] in ("fence", "lamp", "bench")]
	for y in range(1, H - 1):
		for x in range(2, W - 2):
			if dist(x, y) <= 2 or g[y][x] != "grass" or o[y][x] is not None:
				continue
			r = h(x, y, sid)
			cerca = min(r for c2 in (x - 1, x, x + 1) for r in col[c2][0])
			if r < (p_arriba if y < cerca else p_abajo) and all(abs(x - a) > 1 or abs(y - b) > 1 for a, b in puesto):
				c = cosas[int(h(y, x, sid + 1) * len(cosas)) % len(cosas)]
				if c in ("tree", "tree2", "manzano") and y > cerca - 2:   # la copa (6 filas) no tapa la calzada: árboles solo por encima
					c = "bush"
				o[y][x] = c
			elif h(x, y, sid + 2) < p_suelo:
				g[y][x] = suelo[int(h(x, y, sid + 3) * len(suelo)) % len(suelo)]
	return {"name": nombre, "w": W, "h": H, "g": [list(r) for r in g], "o": o, "exits": {}, "doors": {}, "music": musica, "blds": [], "est": None}


def main():
	D = json.load(open(DATOS, encoding="utf-8"))
	M = D["MAPS"]
	P = D["PARADAS"]
	rutas = {}
	puertas = {}
	for k, nombre, A, B, paisaje in RUTAS:
		mid = "carr-" + k
		m = mapa(mid, nombre, paisaje, M[A[0]]["music"])
		for lado_mapa, (pueblo, celdas, lado) in (("left", A), ("right", B)):
			# la llegada a la carretera: la casilla de dentro del extremo, mirando hacia dentro
			ex = 0 if lado_mapa == "left" else W - 1
			for i, (bx, by) in enumerate(celdas):
				dx, dy = DV[lado]
				ix, iy = bx - dx, by - dy   # la casilla de dentro del pueblo
				fila = RY + min(i, 1)
				puertas.setdefault(pueblo, []).append([bx, by, mid, 1 if lado_mapa == "left" else W - 2, fila, lado])
			for j, fila in enumerate((RY, RY + 1)):
				bx, by = celdas[min(j, len(celdas) - 1)]
				dx, dy = DV[lado]
				m["exits"]["%d,%d" % (ex, fila)] = {"to": pueblo, "x": bx - dx, "y": by - dy, "dir": OPUESTO[lado], "lado": lado_mapa}
		M[mid] = m
		ch = max(int(P[A[0]]["cap"]), int(P[B[0]]["cap"]))
		rutas[mid] = {"n": nombre, "a": A[0], "b": B[0], "ch": ch, "k": k, "bioma": BIOMA[paisaje]}
	abre = {}
	for pueblo, ps in puertas.items():
		for q in ps:
			abre.setdefault(pueblo, []).append([q[0], q[1], q[0], q[1]])
	for pueblo, cs in ABRE_MAS.items():
		for c, s in cs:
			abre.setdefault(pueblo, []).append([c[0], c[1], s[0], s[1]])
	D["CARRETERAS"] = {"_": "La red de carreteras que se andan (con Datos.CAL; tools/carreteras.py): rutas por mapa y, por pueblo, las salidas [x, y, carretera, llegada x, llegada y, lado] y las casillas del borde que se abren [x, y, la salida que la abre x, y].",
		"rutas": rutas, "puertas": puertas, "abre": abre}
	s = json.dumps(D, ensure_ascii=False, separators=(",", ":"))
	open(DATOS, "w", encoding="utf-8").write(s)
	print("carreteras: %d mapas, %d salidas" % (len(rutas), sum(len(v) for v in puertas.values())))


if __name__ == "__main__":
	sys.exit(main())
