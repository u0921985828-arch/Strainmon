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
	["acantilado", "Pista de los acantilados", ("valdehierro", [(0, 9), (0, 10)], "left"), ("puerto", [(0, 10), (0, 11)], "left"), "acantilado"],
	["ribera", "Carretera de la ribera", ("ibarbide", [(38, 29)], "down"), ("errotabarri", [(35, 11), (35, 12)], "right"), "ribera"],
]
# casillas de más que se abren hacia dentro (la salida del norte de Errotabarri pasa por la fila 1; la de Puerto Viejo, por (38, 13),
# que antes del muelle es monte)
ABRE_MAS = {"errotabarri": [((15, 1), (15, 0))], "puerto": [((38, 13), (39, 13))]}   # (casilla, la salida que la abre)
DV = {"left": (-1, 0), "right": (1, 0), "up": (0, -1), "down": (0, 1)}
OPUESTO = {"left": "right", "right": "left", "up": "down", "down": "up"}


def h(x, y, s):
	v = (x * 374761393 + y * 668265263 + s * 2147483647) & 0x7fffffff
	v = ((v ^ (v >> 13)) * 1274126177) & 0x7fffffff
	return (v & 0xffff) / 65535.0


# las curvas (lo pidió el usuario: «molaría que los caminos no siempre sean rectos»): [columna, ±1] — la calzada baja (+1) o sube
# (−1) una fila en las columnas x y x + 1; los extremos siguen en las filas 6 y 7 (las salidas). Va en piezas de 2 × 3 casillas
# «cv<R|O|P>-<d|u>-<columna><fila>» (asfalto, roto o pista) que pinta.gd dibuja en curva.
CURVAS = {
	"costa": [(6, 1), (12, 1), (21, -1), (27, -1), (31, -1), (35, 1)],
	"valle": [(5, -1), (10, -1), (18, 1), (23, 1), (29, 1), (34, -1)],
	"monte": [(4, 1), (9, 1), (15, -1), (19, -1), (23, -1), (27, -1), (31, 1), (35, 1)],
	"general": [],
	"molino": [(6, -1), (11, -1), (17, 1), (24, 1), (30, 1), (34, -1)],
	"acantilado": [(5, 1), (12, 1), (19, -1), (23, -1), (28, -1), (33, 1)],
	"ribera": [(5, -1), (11, -1), (20, 1), (26, 1), (31, 1), (35, -1)],
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
			for c in (0, 1):
				col[x + c] = (list(range(arriba, arriba + 3)), (d, c, arriba))
			top += d
			x += 2
			continue
		col[x] = ([top, top + 1], None)
		x += 1
	assert top == RY, paisaje
	return col


def mapa(k, nombre, paisaje, musica):
	g = [["grass"] * W for _ in range(H)]
	o = [[None] * W for _ in range(H)]
	tipo = {"costa": ("roadT", "roadB", "R"), "valle": ("rotoT", "rotoB", "O"), "monte": ("roadT", "roadB", "R"), "general": ("roadT", "roadB", "R"),
		"molino": ("pista", "pista", "P"), "acantilado": ("pista", "pista", "P"), "ribera": ("roadT", "roadB", "R")}[paisaje]
	col = calzada_de(paisaje)
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
	# el agua (el mar arriba en la costa y los acantilados; el río abajo en la ribera), sin monte encima
	agua = {"costa": range(0, 3), "acantilado": range(0, 2), "ribera": range(10, 12)}.get(paisaje, range(0))
	for y in agua:
		for x in range(W):
			assert g[y][x] == "grass", (paisaje, x, y)
			g[y][x] = "water"
			o[y][x] = None
	if paisaje == "costa":   # la arena junto al mar
		for x in range(1, W - 1):
			if g[3][x] == "grass":
				g[3][x] = "dirt"
	if paisaje == "ribera":   # el puente viejo sobre el río, a un lado
		for y in (10, 11):
			g[y][24] = "bridgeT" if y == 10 else "bridgeB"
	if paisaje == "general":   # las aceras
		for x in range(1, W - 1):
			g[RY - 1][x] = "walk"
			g[RY + 2][x] = "walk"
	# lo de los lados: nunca en la calzada ni a 2 filas de ella (no corta el paso)
	cosas = {"costa": ["bench", "lamp", "bush", "fence"], "valle": ["crate", "fence", "tree2", "bush"], "monte": ["tree", "tree2", "manzano", "bush"],
		"general": ["lamp", "seto", "tree", "bench"], "molino": ["manzano", "fence", "tree", "bush"], "acantilado": ["tree2", "bush", "fence", "tree"],
		"ribera": ["tree", "tree2", "bush", "bench"]}[paisaje]
	suelo = {"costa": "flowers", "valle": "tallgrass", "monte": "tallgrass", "general": "flowers", "molino": "flowers", "acantilado": "tallgrass", "ribera": "flowers"}[paisaje]
	sid = sum(ord(c) for c in k)
	for y in range(1, H - 1):
		for x in range(2, W - 2):
			cerca = [r for c in (x - 1, x, x + 1) for r in col[c][0]]
			if min(abs(y - r) for r in cerca) <= 2 or g[y][x] != "grass":
				continue
			r = h(x, y, sid)
			if paisaje == "general" and y in (RY - 2, RY + 3) and x % 6 == 3:
				o[y][x] = "lamp"
			elif r < 0.12:
				c = cosas[int(h(y, x, sid + 1) * len(cosas)) % len(cosas)]
				if c in ("tree", "tree2", "manzano") and y > min(cerca) - 2:   # la copa (6 filas) no tapa la calzada: árboles solo por encima
					c = "bush"
				o[y][x] = c
			elif r < 0.2:
				g[y][x] = suelo
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
		rutas[mid] = {"n": nombre, "a": A[0], "b": B[0], "ch": ch, "k": k}
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
