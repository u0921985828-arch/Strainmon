# python3 -I tools/sala_fria.py  → FRIA, el mapa «fria» y su puerta desde el sótano en godot/datos/datos.json (con Datos.CAL)
#
# Lo pidió el usuario: una habitación fría para las extracciones, «en el sótano del piso», con las máquinas allí y que rindan más. La sala
# fría, por la puerta (3, 1) de la pared del sótano: aislada con paneles de poliuretano, con su equipo de frío a 4 °C y la mesa de acero;
# con la obra hecha, las máquinas de extracción que tengas (MUEBLE_EXTR) dejan el piso y se montan aquí, contra la pared, y lo que se
# saca aquí rinde más (FRIA.rend): en frío los tricomas se quiebran y se sueltan mejor del material (el hielo, el tamiz, la lavadora,
# la static) y el material frío prensa más limpio (la prensa). La obra va por la tienda online, después del sótano; en Google Play,
# donde no hay sótano para setas, la obra lo deja habilitado también (p_play). src/salafria.gd le da la vida.

import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DJ = os.path.join(RAIZ, "godot", "datos", "datos.json")

MAPA = "fria"
W, H = 11, 6
PUERTA = [3, 1]      # en la pared del sótano
VUELTA = [1, 1]      # la de la sala

FRIA = {
	"mapa": MAPA, "ch": 4, "t": 4,
	"l": [["Paneles de poliuretano de 80 mm y puerta frigorífica", 3900], ["Equipo de frío de 1,5 kW para 4 °C", 2400],
		["Mesa de acero inoxidable y luz estanca", 500]],
	"rend": {"ice": 1.15, "lava": 1.15, "seco": 1.15, "stat": 1.1, "rosin": 1.05, "hash": 1.05, "moon": 1.05, "charas": 1.0},
	# las máquinas, en fila contra la pared de arriba; la de serie de la lavadora, al lado de la puerta
	"pos": {"lavadora": [1, 5], "mallas": [3, 5], "staticM": [5, 5], "prensaM": [7, 5], "tamizM": [9, 5]},   # contra la pared de abajo, con una casilla entre las dos (si no, se montan)
	"o": [[6, 1, "frioF"], [5, 3, "mesaF"]],
	"n": "La sala fría del sótano",
}
FRIA["p"] = sum(x[1] for x in FRIA["l"])

def mapa():
	g = [["iwT_bajo"] * W, ["iwB_bajo"] * W] + [["floorG"] * W for _ in range(H - 2)]
	o = [[None] * W for _ in range(H)]
	for x, y, k in FRIA["o"]:
		o[y][x] = k
	return {"name": MAPA, "w": W, "h": H, "g": g, "o": o, "exits": {}, "doors": {}, "music": "home", "blds": [], "est": None}

def main():
	with open(DJ, encoding="utf-8") as fh:
		D = json.load(fh)
	FRIA["ch"] = int(D["SOTANO"]["ch"])
	FRIA["p_play"] = FRIA["p"] + int(D["SOTANO"]["obra"]["p"])   # en Play, también habilitar el sótano
	D["FRIA"] = FRIA
	D["MAPS"][MAPA] = mapa()
	P = D["PUERTAS_INT"]
	P["sotano"] = [e for e in P.get("sotano", []) if e.get("to") != MAPA] + [
		{"x": PUERTA[0], "y": PUERTA[1], "o": "puertaI", "to": MAPA, "tx": VUELTA[0], "ty": VUELTA[1] + 1, "dir": "down", "n": "La puerta de la sala fría", "llave": "fria"}]
	P[MAPA] = [{"x": VUELTA[0], "y": VUELTA[1], "o": "puertaI", "to": "sotano", "tx": PUERTA[0], "ty": PUERTA[1] + 1, "dir": "down", "n": "La puerta del sótano"}]
	s = D["MAPS"]["sotano"]
	assert s["o"][PUERTA[1]][PUERTA[0]] is None and s["o"][PUERTA[1] + 1][PUERTA[0]] is None, "la puerta de la sala fría, en un sitio libre del sótano"
	assert set(FRIA["pos"]) == set(D["MUEBLE_EXTR"]), "una casilla por máquina"
	for k, (x, y) in FRIA["pos"].items():
		assert 0 < x < W and y == H - 1 and [x, y] != [VUELTA[0], VUELTA[1] + 1], k
	assert len({tuple(v) for v in FRIA["pos"].values()}) == len(FRIA["pos"])
	assert set(FRIA["rend"]) == set(D["EXTR"]), "un rendimiento por extracción"
	with open(DJ, "w", encoding="utf-8") as fh:
		json.dump(D, fh, ensure_ascii=False, separators=(",", ":"))
	print("sala_fria: %d € (Play %d €), %d máquinas, mapa %s %d × %d" % (FRIA["p"], FRIA["p_play"], len(FRIA["pos"]), MAPA, W, H))

if __name__ == "__main__":
	main()
