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
# casillas de más que se abren hacia dentro (la salida del norte de Errotabarri pasa por la fila 1)
ABRE_MAS = {"errotabarri": [(15, 1)]}
DV = {"left": (-1, 0), "right": (1, 0), "up": (0, -1), "down": (0, 1)}
OPUESTO = {"left": "right", "right": "left", "up": "down", "down": "up"}


def h(x, y, s):
	v = (x * 374761393 + y * 668265263 + s * 2147483647) & 0x7fffffff
	v = ((v ^ (v >> 13)) * 1274126177) & 0x7fffffff
	return (v & 0xffff) / 65535.0


def mapa(k, nombre, paisaje, musica):
	g = [["grass"] * W for _ in range(H)]
	o = [[None] * W for _ in range(H)]
	calzada = {"costa": ("roadT", "roadB"), "valle": ("rotoT", "rotoB"), "monte": ("roadT", "roadB"), "general": ("roadT", "roadB"),
		"molino": ("pista", "pista"), "acantilado": ("pista", "pista"), "ribera": ("roadT", "roadB")}[paisaje]
	for x in range(W):
		g[RY][x], g[RY + 1][x] = calzada
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
			g[y][x] = "water"
			o[y][x] = None
	if paisaje == "costa":   # la arena junto al mar
		for x in range(1, W - 1):
			g[3][x] = "dirt"
	if paisaje == "ribera":   # el puente viejo sobre el río, a un lado
		for y in (10, 11):
			g[y][24] = "bridgeT" if y == 10 else "bridgeB"
	if paisaje == "general":   # las aceras
		for x in range(1, W - 1):
			g[RY - 1][x] = "walk"
			g[RY + 2][x] = "walk"
	# lo de los lados: nunca en la calzada ni en la fila de al lado (no corta el paso)
	cosas = {"costa": ["bench", "lamp", "bush", "fence"], "valle": ["crate", "fence", "tree2", "bush"], "monte": ["tree", "tree2", "manzano", "bush"],
		"general": ["lamp", "seto", "tree", "bench"], "molino": ["manzano", "fence", "tree", "bush"], "acantilado": ["tree2", "bush", "fence", "tree"],
		"ribera": ["tree", "tree2", "bush", "bench"]}[paisaje]
	suelo = {"costa": "flowers", "valle": "tallgrass", "monte": "tallgrass", "general": "flowers", "molino": "flowers", "acantilado": "tallgrass", "ribera": "flowers"}[paisaje]
	sid = sum(ord(c) for c in k)
	for y in range(1, H - 1):
		for x in range(2, W - 2):
			if abs(y - RY - 0.5) < 2.6 or g[y][x] != "grass":
				continue
			r = h(x, y, sid)
			if paisaje == "general" and y in (RY - 2, RY + 3) and x % 6 == 3:
				o[y][x] = "lamp"
			elif r < 0.12:
				c = cosas[int(h(y, x, sid + 1) * len(cosas)) % len(cosas)]
				if c in ("tree", "tree2", "manzano") and y > 4:   # la copa (6 filas) no tapa la calzada ni la acera: árboles solo arriba
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
			abre.setdefault(pueblo, []).append([q[0], q[1]])
	for pueblo, cs in ABRE_MAS.items():
		for c in cs:
			abre.setdefault(pueblo, []).append(list(c))
	D["CARRETERAS"] = {"_": "La red de carreteras que se andan (con Datos.CAL; tools/carreteras.py): rutas por mapa y, por pueblo, las salidas [x, y, carretera, llegada x, llegada y, lado] y las casillas del borde que se abren [x, y].",
		"rutas": rutas, "puertas": puertas, "abre": abre}
	s = json.dumps(D, ensure_ascii=False, separators=(",", ":"))
	open(DATOS, "w", encoding="utf-8").write(s)
	print("carreteras: %d mapas, %d salidas" % (len(rutas), sum(len(v) for v in puertas.values())))


if __name__ == "__main__":
	sys.exit(main())
