# python3 -I tools/kaia_cult.py  → KAIA_CULT, el mapa cult-muelle, su puerta desde KAIA y ORDEN_P["cult-muelle"] en godot/datos/datos.json
# (con Datos.CAL)
#
# Lo pidió el usuario: «Incluso molaría tener un cultivo finalmente en la nueva asociación de KAIA» y, de las carpas, «tiene que tener
# lógica con el suelo que hay al rededor y las zonas donde las colocas». La sala de cultivo del club, por la puerta (15, 1) de KAIA,
# cerrada hasta tener la licencia (S.mar.lic): a la izquierda el pasillo con el suelo del club y, pasada la junta, la zona de cultivo,
# con el suelo de resina y desagüe del grow (floorG). Las tres carpas de 120 × 120 con su LED de 480 W se ordenan desde el cuadro de
# la pared (ctrlN), solo encima de la zona de cultivo (zona en la pieza: cabe_pieza en calle.gd); el depósito y la bomba del goteo,
# al fondo. src/kaiacult.gd le da la vida.

import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DJ = os.path.join(RAIZ, "godot", "datos", "datos.json")

MAPA = "cult-muelle"
W, H = 14, 8
PASILLO = 3          # las columnas 0..2, el pasillo con el suelo del club; de la 3 a la derecha, la zona de cultivo
ZONA = "floorG"
PUERTA = [15, 1]     # en la pared de KAIA (la gramola, una casilla a la izquierda)
VUELTA = [1, 1]      # la de la sala

KAIA_CULT = {
	"mapa": MAPA, "club": "club-muelle", "carpa": "m120", "foco": "led480", "maceta": "tela25", "plazas": 4,
	"clima": {"t": 25.0, "hr": 55.0},   # con la licencia, la sala con su clima controlado
	"ctrl": [4, 1], "zona": [ZONA],
	"o": [[4, 1, "ctrlN"], [6, 1, "extrN"], [9, 1, "filtroN"], [12, 1, "filtroN"], [13, 6, "tanqueN"], [12, 7, "riegoN"]],
	"carpas": [[6, 2], [9, 2], [6, 5]],
}

PIEZAS = [{"k": "kc%d" % i, "n": "La carpa %d" % (i + 1), "o": [[0, 0, "carpaK%d" % i], [1, 0, "carpaM2"]], "def": d, "zona": [ZONA]}
	for i, d in enumerate(KAIA_CULT["carpas"])]

def mapa():
	g = [["iwT_club_itsaso"] * W, ["iwB_club_itsaso"] * W] + [["floorC_itsaso"] * PASILLO + [ZONA] * (W - PASILLO) for _ in range(H - 2)]
	o = [[None] * W for _ in range(H)]
	for x, y, k in KAIA_CULT["o"]:
		o[y][x] = k
	for P in PIEZAS:
		for dx, dy, k in P["o"]:
			o[P["def"][1] + dy][P["def"][0] + dx] = k
	return {"name": MAPA, "w": W, "h": H, "g": g, "o": o, "exits": {}, "doors": {}, "music": "club", "blds": [], "est": "itsaso"}

def main():
	with open(DJ, encoding="utf-8") as fh:
		D = json.load(fh)
	D["KAIA_CULT"] = KAIA_CULT
	D["MAPS"][MAPA] = mapa()
	D["ORDEN_P"][MAPA] = {"n": "ORDENAR LA SALA DE CULTIVO", "filas": [2, H - 1], "pie": [[VUELTA[0], VUELTA[1] + 1]], "piezas": PIEZAS}
	D["ORDEN_MOTIVO"]["zona"] = "Las carpas, en la zona de cultivo: sobre el suelo con desagüe, no en el pasillo."
	P = D["PUERTAS_INT"]
	P["club-muelle"] = [e for e in P["club-muelle"] if e.get("to") != MAPA] + [
		{"x": PUERTA[0], "y": PUERTA[1], "o": "puertaI", "to": MAPA, "tx": VUELTA[0], "ty": VUELTA[1] + 1, "dir": "down", "n": "La puerta de la sala de cultivo", "llave": "kc"}]
	P[MAPA] = [{"x": VUELTA[0], "y": VUELTA[1], "o": "puertaI", "to": "club-muelle", "tx": PUERTA[0], "ty": PUERTA[1] + 1, "dir": "down", "n": "La puerta del club"}]
	m = D["MAPS"]["club-muelle"]
	if m["o"][PUERTA[1] + 1][PUERTA[0]] == "jukebox":
		m["o"][PUERTA[1] + 1][PUERTA[0]] = None
		m["o"][PUERTA[1] + 1][PUERTA[0] - 1] = "jukebox"
	pie = D["ORDEN_P"]["club-muelle"]["pie"]
	if [PUERTA[0], PUERTA[1] + 1] not in pie:
		pie.append([PUERTA[0], PUERTA[1] + 1])   # delante de la puerta, libre al ordenar KAIA
	assert m["o"][PUERTA[1]][PUERTA[0]] is None and m["o"][PUERTA[1] + 1][PUERTA[0]] is None, "la puerta de la sala, en un sitio libre de KAIA"
	for x, y in KAIA_CULT["carpas"]:
		assert x >= PASILLO and x + 1 < W, "cada carpa, de serie, en la zona de cultivo"
	with open(DJ, "w", encoding="utf-8") as fh:
		json.dump(D, fh, ensure_ascii=False, separators=(",", ":"))
	print("kaia_cult: %d carpas de %d plazas, mapa %s %d × %d" % (len(PIEZAS), KAIA_CULT["plazas"], MAPA, W, H))

if __name__ == "__main__":
	main()
