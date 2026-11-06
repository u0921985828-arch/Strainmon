# -*- coding: utf-8 -*-
# El bajo de Txomin, profesional (lo pidió el usuario: «el lugar donde está, en el sótano, las setas… debería de ser el mismo mapa o
# algo más grande, el doble de grande molaría, y mejor organizado todo, que sea el bajo de Txomin, donde ahí pues sea más profesional
# el cultivo de setas, que también se pueda cruzar micelios para crear nuevas variedades de setas»; solo Godot, con Datos.CAL):
# el mapa grande «setas-g» pasa de 18 × 7 a 22 × 12 (126 → 264 casillas, más del doble) y se organiza en dos bandas separadas por un
# tabique con un hueco de paso: arriba, el obrador (armario, malla, deshidratador y mesa de trabajo) y el laboratorio con el suelo
# técnico (pila, estufa de incubación, campana de flujo, microscopio y balanza, todo del atlas del banco de la tía); abajo, la nave de
# cultivo con las catorce estanterías de rejilla (28 bandejas), el pulverizador y la mesa de Ekaitz. En la campana se cruzan micelios
# que no estén en el cuaderno y sale una cepa propia (CEPAS.cruce). Nada de método ni de dosis.
import json
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DJ = os.path.join(RAIZ, "godot", "datos", "datos.json")

W, H = 22, 12
LABX = 12          # de aquí a la derecha, el laboratorio (su suelo y su pared)
TAB = 5            # el tabique, en las filas 5 y 6
HUECO = [10, 11]   # el paso entre las dos bandas
PUERTA = [4, 11]   # la salida al callejón (la de al lado, en 5)

# lo que trae el mapa de serie (lo condicional lo pone montar_setas: armS, mesaS, deshidS y la mesa de Ekaitz)
OBJ = [
	[13, 1, "labExtintor"], [16, 1, "labNormas"], [19, 1, "labBotiquin"],
	[2, 2, "secaS"], [7, 2, "tuboS"], [9, 2, "labEstufa"],
	[12, 2, "labPila"], [14, 2, "labFlujo"], [15, 2, "labFlujo2"],
	[17, 2, "labMicro"], [18, 2, "labMicro2"], [20, 2, "labBalanza"], [21, 2, "labBalanza2"],
	[12, 3, "labTaburete"], [17, 3, "labTaburete"], [10, 4, "labResiduos"],
	[9, 7, "humidS"], [18, 7, "tuboS"], [20, 7, "crate"],
	[0, 10, "cuboS"], [21, 10, "crate"],
]
BALDAS = list(range(0, 9)) + list(range(12, 17))   # 14 estanterías en la fila 7, con x distinto (balda_i va por x)
X = {"armS": [0, 2], "deshidS": [3, 2], "mesaS": [5, 2]}
AY = {"x": 19, "y": 9, "mesa": [19, 8], "max": 2 * len(BALDAS)}

# el cruce de micelios en la campana: dos panes de cepas que no estén en el cuaderno dan una cepa propia
CRUCE = {
	"max": 8,          # cepas propias por partida
	"sale": 2,         # panes que salen
	"min": 180,        # lo que lleva
	"gen": 5,          # la generación de las propias
	"suf": ["Berri", "Bikoitz", "Hirukoitz", "Laukoitz", "Bostkoitz", "Seikoitz", "Zazpikoitz", "Zortzikoitz"],
}


def mapa():
	g, o = [], []
	for y in range(H):
		fg, fo = [], []
		for x in range(W):
			if y < 2 or (y in (TAB, TAB + 1) and x not in HUECO):
				t = ("iwT_lab" if x >= LABX else "iwT_bajo") if y == 0 else "iwB_lab" if (y == 1 and x >= LABX) else "iwB_bajo" if y == 1 else ("iwT_bajo" if y == TAB else "iwB_bajo")
			elif 2 <= y <= 4 and x >= LABX:
				t = "floorLab"
			else:
				t = "floorSe"
			if [x, y] == PUERTA or [x, y] == [PUERTA[0] + 1, PUERTA[1]]:
				t = "mat"
			fg.append(t)
			fo.append(None)
		g.append(fg)
		o.append(fo)
	for x, y, k in OBJ:
		assert o[y][x] is None, (x, y, k)
		assert y == 1 or not g[y][x].startswith(("iwT", "iwB")), "mueble en la pared: %s" % k   # en la fila 1, lo de colgar
		o[y][x] = k
	for x in BALDAS:
		assert o[7][x] is None
		o[7][x] = "baldaS"
	for k in X:   # el sitio de lo que pone montar_setas, libre y pisable
		x, y = X[k]
		assert o[y][x] is None and not g[y][x].startswith(("iwT", "iwB")), k
	assert o[AY["mesa"][1]][AY["mesa"][0]] is None
	ex = {}
	for dx in (0, 1):
		ex["%d,%d" % (PUERTA[0] + dx, PUERTA[1])] = {"to": "callejon", "x": 19, "y": 8, "dir": "down"}
	return {"w": W, "h": H, "g": g, "o": o, "exits": ex}


def main():
	d = json.load(open(DJ, encoding="utf-8"))
	vieja = d["MAPS"]["setas-g"]
	m = mapa()
	nueva = dict(vieja)
	nueva.update(m)
	d["MAPS"]["setas-g"] = nueva
	d["SETAS_PRO"]["x"] = X
	d["SETAS_AY"].update(AY)
	d["CEPAS"]["cruce"] = CRUCE
	assert len(CRUCE["suf"]) >= CRUCE["max"]
	# la entrada por la puerta del callejón, a la fila de la puerta nueva
	pc = d["MAPS"]["callejon"]["doors"]["19,7"]
	assert pc["to"] == "setas"
	d["CEPAS"]["cruce"]["entra"] = [PUERTA[0], PUERTA[1] - 1]
	json.dump(d, open(DJ, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
	print("bajo_pro: setas-g %d × %d (antes %s × %s), %d estanterías = %d bandejas, %d muebles, cruce máx %d cepas propias"
		% (W, H, vieja["w"], vieja["h"], len(BALDAS), AY["max"], len(OBJ) + len(X), CRUCE["max"]))


if __name__ == "__main__":
	main()
