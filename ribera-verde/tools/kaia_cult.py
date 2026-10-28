# python3 -I tools/kaia_cult.py  → KAIA_CULT, el mapa cult-muelle, su puerta desde KAIA y ORDEN_P["cult-muelle"] en godot/datos/datos.json
# (con Datos.CAL)
#
# Lo pidió el usuario: «Incluso molaría tener un cultivo finalmente en la nueva asociación de KAIA» y, de las carpas, «tiene que tener
# lógica con el suelo que hay al rededor y las zonas donde las colocas». La sala de cultivo del club, por la puerta (15, 1) de KAIA,
# cerrada hasta tener la licencia (S.mar.lic): a la izquierda el pasillo con el suelo del club y, pasada la junta, la zona de cultivo,
# con el suelo de resina y desagüe del grow (floorG). Fase 1: las carpas por niveles (KAIA_CULT.niv: cuatro de 2 × 2 m, dos de 4 × 2 y
# una de 4 × 4, con sus LED de 720 W, extractor y goteo) que se compran en el cuadro de la pared (ctrlN) y se ordenan desde él, solo encima de la zona de
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
# inversión será más grande». Fase 1: carpas en kit a precio de tienda que llegan al día siguiente; fase 2: la obra de la sala entera, con las mesas de la nave y alguien de la plantilla que las lleve.
# Por niveles (lo pidió el usuario: «4 de 2×2, luego 2 de 4×2, luego una de 4×4 y después la reforma de la sala a mesas, con riego
# automático por tanque»): cada nivel, su carpa con sus LED de 720 W (uno por cada 2,25 m², la huella de uno; lado 150 cm), su
# extractor con filtro, su goteo y un kit por carpa a precio de tienda; al pasar al siguiente, las del nivel de antes se venden de
# segunda mano (f2.venta) y llega la primera del nuevo. Cuanto más grande, menos pared por planta y mejor reparte el aire y la luz:
# rinde más por plaza (efi: 0,9; 1; 1,12), y así cada nivel compensa lo que cuesta. Cada carpa, una pieza de ORDENAR de su tamaño en casillas (1 casilla = 1 m).
NIV = [
	{"k": "s", "n": "Carpa 200×200", "cm": [200, 200, 200], "nf": 2, "plazas": 4, "efi": 0.9, "max": 4, "tam": [2, 2], "obj": "carpaKS", "spr": "kcs",
		"def": [[4, 3], [8, 3], [12, 3], [4, 7]],
		"kit": {"l": [["Carpa de 200 × 200 × 200 cm", 340], ["Dos LED de 720 W", 1900], ["Extractor de 200 mm con filtro de carbón", 320],
			["Goteo de 4 salidas con su depósito", 140]]}},
	{"k": "m", "n": "Carpa 400×200", "cm": [400, 200, 200], "nf": 4, "plazas": 8, "efi": 1.0, "max": 2, "tam": [4, 2], "obj": "carpaKM", "spr": "kcm",
		"def": [[4, 3], [10, 3]],
		"kit": {"l": [["Carpa de 400 × 200 × 200 cm", 620], ["Cuatro LED de 720 W", 3800], ["Extractor de 250 mm con filtro de carbón", 480],
			["Goteo de 8 salidas con su depósito", 240]]}},
	{"k": "l", "n": "Carpa 400×400", "cm": [400, 400, 200], "nf": 8, "plazas": 16, "efi": 1.12, "max": 1, "tam": [4, 4], "obj": "carpaKL", "spr": "kcl",
		"def": [[7, 3]],
		"kit": {"l": [["Carpa de 400 × 400 × 200 cm", 980], ["Ocho LED de 720 W", 7600], ["Extractor de 315 mm con dos filtros de carbón", 1200],
			["Goteo de 16 salidas con su depósito", 420]]}},
]
for N in NIV:
	N["kit"]["p"] = sum(x[1] for x in N["kit"]["l"])

KAIA_CULT = {
	"mapa": MAPA, "club": "club-muelle", "maceta": "tela25", "foco": "led720", "niv": NIV, "plazas": max(N["plazas"] * N["max"] for N in NIV),
	"clima": {"t": 25.0, "hr": 55.0},   # con la licencia, la sala con su clima controlado
	"ctrl": [2, 1], "zona": [ZONA],
	"o": [[2, 1, "ctrlN"]],
	"f2": {"l": [["Obra: desagües, cuadro trifásico y clima industrial", 30000], ["Seis mesas de 240 × 120 con su LED doble", 10800],
		["Riego centralizado con su tanque", 2800], ["Extracción con filtros de carbón", 1400]],
		"dias": 5, "venta": 0.4, "foco": "led", "sueldo": 45,
		"mesas": [[4, 3], [8, 3], [12, 3], [4, 7], [8, 7], [12, 7]],
		"o": [[15, 3, "tanqueN"], [15, 8, "riegoN"]], "npc": [7, 5]},
}
KAIA_CULT["f2"]["p"] = sum(x[1] for x in KAIA_CULT["f2"]["l"])

def pieza(N, i, d):   # la carpa de w × h: el dibujo en la casilla de abajo a la izquierda, lo demás relleno (carpaG2, sin pintar)
	w, h = N["tam"]
	o = [[dx, dy, "carpaG2"] for dy in range(h) for dx in range(w) if not (dx == 0 and dy == h - 1)]
	o.append([0, h - 1, "%s%d" % (N["obj"], i)])
	return {"k": "kc%s%d" % (N["k"], i), "n": "La carpa %d" % (i + 1), "o": o, "def": d, "zona": [ZONA], "si": "kc"}

PIEZAS = [pieza(N, i, d) for N in NIV for i, d in enumerate(N["def"])]

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
	for N in NIV:
		w, h = N["tam"]
		assert len(N["def"]) == N["max"], N["k"]
		for x, y in N["def"]:
			assert x >= PASILLO and x + w <= W and y >= 2 and y + h <= H, "cada carpa, de serie, en la zona de cultivo"
		for i, (x, y) in enumerate(N["def"]):   # las de un nivel, sin pisarse entre ellas
			for x2, y2 in N["def"][i + 1:]:
				assert x + w <= x2 or x2 + w <= x or y + h <= y2 or y2 + h <= y, N["k"]
	for x, y in KAIA_CULT["f2"]["mesas"]:
		assert x >= PASILLO and x + 1 < W and y >= 2 and y < H, "cada mesa, en la zona de cultivo"
	with open(DJ, "w", encoding="utf-8") as fh:
		json.dump(D, fh, ensure_ascii=False, separators=(",", ":"))
	print("kaia_cult: %s, %d mesas (obra %d €), mapa %s %d × %d" % (", ".join("%d × %s (%d plazas, kit %d €)" % (N["max"], N["n"], N["plazas"], N["kit"]["p"]) for N in NIV), len(KAIA_CULT["f2"]["mesas"]), KAIA_CULT["f2"]["p"], MAPA, W, H))

if __name__ == "__main__":
	main()
