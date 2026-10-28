# python3 -I tools/kaia_cult.py  → KAIA_CULT, el mapa cult-muelle, su puerta desde KAIA y ORDEN_P["cult-muelle"] en godot/datos/datos.json
# (con Datos.CAL)
#
# Lo pidió el usuario: «Incluso molaría tener un cultivo finalmente en la nueva asociación de KAIA» y, de las carpas, «tiene que tener
# lógica con el suelo que hay al rededor y las zonas donde las colocas». La sala de cultivo del club, por la puerta (15, 1) de KAIA,
# cerrada hasta tener la licencia (S.mar.lic): a la izquierda el pasillo con el suelo del club y, pasada la junta, la zona de cultivo,
# con el suelo de resina y desagüe del grow (floorG). Fase 1: hasta cuatro kits de carpa de 240 × 240 (dos LED de 720 W, extractor y
# goteo, nueve plazas; KAIA_CULT.kit) que se compran en el cuadro de la pared (ctrlN) y se ordenan desde él, solo encima de la zona de
# cultivo y sin montarse encima de nada (zona y solapa en cabe_pieza, calle.gd). Fase 2 (KAIA_CULT.f2): la obra que la deja como la nave,
# con seis mesas, tanque y riego, que lleva un trabajador de rol kaia (PLANTILLA.sueldo.kaia). src/kaiacult.gd le da la vida.

import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DJ = os.path.join(RAIZ, "godot", "datos", "datos.json")

MAPA = "cult-muelle"
W, H = 16, 10
PASILLO = 3          # las columnas 0..2, el pasillo con el suelo del club; de la 3 a la derecha, la zona de cultivo
ZONA = "floorG"
PUERTA = [15, 1]     # en la pared de KAIA (la gramola, una casilla a la izquierda)
VUELTA = [1, 1]      # la de la sala

# Lo pidió el usuario: «Como en la huerta no, habría que preparar como en casa, cultivo con carpas, pero más grandes de primeras, con
# una inversión realista, después como en la nave en esa misma habitación, ya con posibilidad de poner a alguien a trabajar ahí y la
# inversión será más grande». Fase 1: kits de carpa de 240 × 240 que se compran de uno en uno (precios de tienda) y llegan al día
# siguiente; fase 2: la obra de la sala entera, con las mesas de la nave y alguien de la plantilla que las lleve.
KAIA_CULT = {
	"mapa": MAPA, "club": "club-muelle", "maceta": "tela25", "plazas": 9, "max": 4,
	"carpa": {"n": "Carpa 240×240", "cm": [240, 200, 240]}, "foco": "led720", "nf": 2,
	"kit": {"l": [["Carpa de 240 × 240 × 200 cm", 520], ["Dos LED de 720 W", 1900], ["Extractor de 250 mm con filtro de carbón", 480],
		["Goteo de 9 salidas con su depósito", 280]]},
	"clima": {"t": 25.0, "hr": 55.0},   # con la licencia, la sala con su clima controlado
	"ctrl": [2, 1], "zona": [ZONA],
	"o": [[2, 1, "ctrlN"]],
	"carpas": [[3, 2], [7, 2], [11, 2], [3, 6]],   # la casilla de arriba a la izquierda de cada carpa de 3 × 2
	"f2": {"l": [["Obra: desagües, cuadro trifásico y clima industrial", 30000], ["Seis mesas de 240 × 120 con su LED doble", 10800],
		["Riego centralizado con su tanque", 2800], ["Extracción con filtros de carbón", 1400]],
		"dias": 5, "venta": 0.4, "foco": "led", "sueldo": 45,
		"mesas": [[4, 3], [8, 3], [12, 3], [4, 7], [8, 7], [12, 7]],
		"o": [[15, 3, "tanqueN"], [15, 8, "riegoN"]], "npc": [7, 5]},
}
KAIA_CULT["kit"]["p"] = sum(x[1] for x in KAIA_CULT["kit"]["l"])
KAIA_CULT["f2"]["p"] = sum(x[1] for x in KAIA_CULT["f2"]["l"])

def pieza(i, d):   # la carpa de 3 × 2: el dibujo en la casilla de abajo a la izquierda, lo demás relleno (carpaG2, sin pintar)
	o = [[dx, dy, "carpaG2"] for dy in (0, 1) for dx in range(3)]
	o[3] = [0, 1, "carpaKG%d" % i]
	return {"k": "kc%d" % i, "n": "La carpa %d" % (i + 1), "o": o, "def": d, "zona": [ZONA], "si": "kc"}

PIEZAS = [pieza(i, d) for i, d in enumerate(KAIA_CULT["carpas"])]

def mapa():
	g = [["iwT_club_itsaso"] * W, ["iwB_club_itsaso"] * W] + [["floorC_itsaso"] * PASILLO + [ZONA] * (W - PASILLO) for _ in range(H - 2)]
	o = [[None] * W for _ in range(H)]
	for x, y, k in KAIA_CULT["o"]:
		o[y][x] = k
	return {"name": MAPA, "w": W, "h": H, "g": g, "o": o, "exits": {}, "doors": {}, "music": "club", "blds": [], "est": "itsaso"}

def main():
	with open(DJ, encoding="utf-8") as fh:
		D = json.load(fh)
	D["KAIA_CULT"] = KAIA_CULT
	D["PLANTILLA"]["sueldo"]["kaia"] = KAIA_CULT["f2"]["sueldo"]   # quien lleva las mesas de la sala de cultivo de KAIA
	D["MAPS"][MAPA] = mapa()
	D["ORDEN_P"][MAPA] = {"n": "ORDENAR LA SALA DE CULTIVO", "filas": [2, H - 1], "pie": [[VUELTA[0], VUELTA[1] + 1]], "piezas": PIEZAS}
	D["ORDEN_MOTIVO"]["zona"] = "Las carpas, en la zona de cultivo: sobre el suelo con desagüe, no en el pasillo."
	D["ORDEN_MOTIVO"]["solapa"] = "Ahí quedaría montado encima de otra cosa."   # calle.gd pieza_solapa (lo pidió el usuario: que nada se superponga)
	P = D["PUERTAS_INT"]
	P["club-muelle"] = [e for e in P["club-muelle"] if e.get("to") != MAPA] + [
		{"x": PUERTA[0], "y": PUERTA[1], "o": "puertaI", "to": MAPA, "tx": VUELTA[0], "ty": VUELTA[1] + 1, "dir": "down", "n": "La puerta de la sala de cultivo", "llave": "kc"}]
	P[MAPA] = [{"x": VUELTA[0], "y": VUELTA[1], "o": "puertaI", "to": "club-muelle", "tx": PUERTA[0], "ty": PUERTA[1] + 1, "dir": "down", "n": "La puerta del club"}]
	m = D["MAPS"]["club-muelle"]
	if m["o"][PUERTA[1] + 1][PUERTA[0]] == "jukebox":
		m["o"][PUERTA[1] + 1][PUERTA[0]] = None
		m["o"][PUERTA[1] + 1][PUERTA[0] - 1] = "jukebox"
	for Pz in D["ORDEN_P"]["club-muelle"]["piezas"]:   # la pieza de ORDENAR KAIA, también (si no, quita_orden no la encuentra y salen dos)
		if Pz["k"] == "jukebox" and Pz["def"] == [PUERTA[0], PUERTA[1] + 1]:
			Pz["def"] = [PUERTA[0] - 1, PUERTA[1] + 1]
	D.setdefault("ORDEN_RESERVA", {})[MAPA] = [[KAIA_CULT["ctrl"][0], KAIA_CULT["ctrl"][1] + 1]]   # delante del cuadro, libre: desde ahí se ordena
	pie = D["ORDEN_P"]["club-muelle"]["pie"]
	if [PUERTA[0], PUERTA[1] + 1] not in pie:
		pie.append([PUERTA[0], PUERTA[1] + 1])   # delante de la puerta, libre al ordenar KAIA
	assert m["o"][PUERTA[1]][PUERTA[0]] is None and m["o"][PUERTA[1] + 1][PUERTA[0]] is None, "la puerta de la sala, en un sitio libre de KAIA"
	for x, y in KAIA_CULT["carpas"]:
		assert x >= PASILLO and x + 2 < W and y >= 2 and y + 1 < H, "cada carpa, de serie, en la zona de cultivo"
	for x, y in KAIA_CULT["f2"]["mesas"]:
		assert x >= PASILLO and x + 1 < W and y >= 2 and y < H, "cada mesa, en la zona de cultivo"
	with open(DJ, "w", encoding="utf-8") as fh:
		json.dump(D, fh, ensure_ascii=False, separators=(",", ":"))
	print("kaia_cult: %d carpas de %d plazas (kit %d €), %d mesas (obra %d €), mapa %s %d × %d" % (len(PIEZAS), KAIA_CULT["plazas"], KAIA_CULT["kit"]["p"], len(KAIA_CULT["f2"]["mesas"]), KAIA_CULT["f2"]["p"], MAPA, W, H))

if __name__ == "__main__":
	main()
