# python3 -I tools/kaia_cult.py  → KAIA_CULT, el mapa cult-muelle, su puerta desde KAIA y ORDEN_P["cult-muelle"] en godot/datos/datos.json
# (con Datos.CAL)
#
# Lo pidió el usuario: «Incluso molaría tener un cultivo finalmente en la nueva asociación de KAIA» y, de las carpas, «tiene que tener
# lógica con el suelo que hay al rededor y las zonas donde las colocas». La sala de cultivo del club, por la puerta (15, 1) de KAIA,
# cerrada hasta tener la licencia (S.mar.lic): a la izquierda el pasillo con el suelo del club y, pasada la junta, la zona de cultivo,
# con el suelo de resina y desagüe del grow (floorG). Fase 1: las carpas por niveles (KAIA_CULT.niv: cuatro de 2 × 2 m, dos de 4 × 2 y
# una de 4 × 4, con sus LED de 720 W, extractor y goteo) que se compran en el cuadro de la pared (ctrlN) y se ordenan desde él, solo encima de la zona de
# cultivo y sin montarse encima de nada (zona y solapa en cabe_pieza, calle.gd). Fase 2 (KAIA_CULT.f2): la obra que la deja como la nave,
# con ocho mesas, tanque y riego, que lleva un trabajador de rol kaia (PLANTILLA.sueldo.kaia). src/kaiacult.gd le da la vida.

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
# segunda mano (f2.venta) y llega la primera del nuevo. Después (lo pidió el usuario: «los anteriores serían ir completando con las
# diferentes medidas la sala, con espacio para pasar entre ellas»), las de cada nivel se quedan: cuatro de 2 × 2, dos de 4 × 2 y una de
# 4 × 4 conviven en la zona de cultivo con un pasillo de 1 m (el esquema que aprobó: «Sí, así»), y el último nivel es la carpa de sala. Cuanto más grande, menos pared por planta y mejor reparte el aire y la luz:
# rinde más por plaza (efi: 0,9; 1; 1,12), y así cada nivel compensa lo que cuesta. Cada carpa, una pieza de ORDENAR de su tamaño en casillas (1 casilla = 1 m).
NIV = [
	{"k": "s", "n": "Carpa 200×200", "cm": [200, 200, 200], "nf": 2, "plazas": 4, "efi": 0.9, "max": 4, "tam": [2, 2], "obj": "carpaKS", "spr": "kcs",
		"def": [[13, 2], [8, 6], [11, 6], [14, 6]],
		"kit": {"l": [["Carpa de 200 × 200 × 200 cm", 340], ["Dos LED de 720 W", 1900], ["Extractor de 200 mm con filtro de carbón", 320],
			["Goteo de 4 salidas con su depósito", 140]]}},
	{"k": "m", "n": "Carpa 400×200", "cm": [400, 200, 200], "nf": 4, "plazas": 8, "efi": 1.0, "max": 2, "tam": [4, 2], "obj": "carpaKM", "spr": "kcm",
		"def": [[3, 2], [8, 2]],
		"kit": {"l": [["Carpa de 400 × 200 × 200 cm", 620], ["Cuatro LED de 720 W", 3800], ["Extractor de 250 mm con filtro de carbón", 480],
			["Goteo de 8 salidas con su depósito", 240]]}},
	{"k": "l", "n": "Carpa 400×400", "cm": [400, 400, 200], "nf": 8, "plazas": 16, "efi": 1.12, "max": 1, "tam": [4, 4], "obj": "carpaKL", "spr": "kcl",
		"def": [[3, 5]],
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
	# el último nivel (lo pidió el usuario: «que la sala sea previamente una carpa a la que entras, con mayores dimensiones desde
	# fuera… que la carpa ocupe finalmente todo el suelo preparado para la carpa»): la carpa de sala de 13 × 7 m sobre toda la zona de
	# cultivo menos el paso de delante, con su puerta; dentro, ocho mesas de flujo y reflujo de 240 × 120 en dos filas de cuatro con
	# pasillos de 1 m, cada una con su LED doble y su tubería de drenaje al depósito de recogida, el tanque del riego y el cuadro
	"f2": {"l": [["Carpa de sala de 1.300 × 700 × 250 cm, con su puerta", 6400], ["Obra: desagües, cuadro trifásico y clima industrial", 18000],
		["Ocho mesas de flujo y reflujo de 240 × 120 con su LED doble", 14400], ["Riego centralizado con su tanque", 2800],
		["Drenaje: tuberías y depósito de recogida", 1900], ["Extracción con filtros de carbón", 1500]],
		"dias": 5, "venta": 0.4, "foco": "led", "sueldo": 45,
		"carpa": {"obj": "carpaKX", "def": [3, 2], "tam": [13, 7], "puerta": [9, 8]},
		"sala": "cult-sala", "W": 13, "H": 9, "sale": [6, 8], "entra": [6, 7],
		"mesas": [[1, 3], [4, 3], [7, 3], [10, 3], [1, 6], [4, 6], [7, 6], [10, 6]],
		# el riego y el drenaje, con lógica (lo pidió el usuario: «todas las conexiones de riego, de drenaje hazlas con cabeza…
		# LOGICAS»): el rincón del riego contra la pared de delante, a la derecha, fuera de los pasillos y de la puerta: el tanque, su
		# bomba al programador con sus dosificadoras (una casilla más allá: cada uno, un poco más ancho que su casilla) y el depósito de
		# recogida en la esquina (de 2 casillas); la impulsión y el colector suben por la pared de la derecha y corren por debajo de cada
		# fila de mesas (tubos_dren)
		"o": [[1, 1, "ctrlN"], [8, 8, "tanqueN"], [10, 8, "riegoN"], [11, 8, "drenKS2"], [12, 8, "drenKS"]], "npc": [6, 5]},
}
KAIA_CULT["f2"]["p"] = sum(x[1] for x in KAIA_CULT["f2"]["l"])

def pieza(N, i, d):   # la carpa de w × h: el dibujo en la casilla de abajo a la izquierda, lo demás relleno (carpaG2, sin pintar)
	w, h = N["tam"]
	o = [[dx, dy, "carpaG2"] for dy in range(h) for dx in range(w) if not (dx == 0 and dy == h - 1)]
	o.append([0, h - 1, "%s%d" % (N["obj"], i)])
	return {"k": "kc%s%d" % (N["k"], i), "n": "La carpa %d" % (i + 1), "o": o, "def": d, "zona": [ZONA], "si": "kc"}

PIEZAS = [pieza(N, i, d) for N in NIV for i, d in enumerate(N["def"])]

def sala():   # la carpa de sala por dentro: la tela plateada, el suelo de la zona de cultivo, las mesas y su equipo
	F = KAIA_CULT["f2"]
	W2, H2 = F["W"], F["H"]
	g = [["iwT_kcs"] * W2, ["iwB_kcs"] * W2] + [[ZONA] * W2 for _ in range(H2 - 2)]
	o = [[None] * W2 for _ in range(H2)]
	for x, y, k in F["o"]:
		o[y][x] = k
	for x, y in F["mesas"]:   # la mesa de 240 cm de la nave (mesaN) ocupa sus tres casillas: cada fila, un banco seguido de pared a pared
		o[y][x], o[y][x + 1], o[y][x + 2] = "mesaKP", "mesaKP2", "mesaKP2"
	sx, sy = F["sale"]
	return {"name": F["sala"], "w": W2, "h": H2, "g": g, "o": o, "doors": {}, "music": "club", "blds": [], "est": "itsaso",
		"exits": {"%d,%d" % (sx, sy): {"to": MAPA, "x": F["carpa"]["puerta"][0], "y": F["carpa"]["puerta"][1] + 1, "dir": "down"}}}

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
	D["MAPS"][KAIA_CULT["f2"]["sala"]] = sala()
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
	todas = [(x, y, N["tam"][0], N["tam"][1]) for N in NIV for x, y in N["def"]]
	for i, (x, y, w, h) in enumerate(todas):   # las de todos los niveles, juntas, sin pisarse y con su pasillo de 1 m entre ellas
		assert y + h <= H - 1, "delante de su puerta, sitio para abrirla"
		for x2, y2, w2, h2 in todas[i + 1:]:
			assert x + w < x2 or x2 + w2 < x or y + h < y2 or y2 + h2 < y, ((x, y), (x2, y2))
	C = KAIA_CULT["f2"]["carpa"]
	assert C["def"][0] == PASILLO and C["def"][0] + C["tam"][0] == W and C["def"][1] + C["tam"][1] == H - 1, "la carpa de sala, en toda la zona menos el paso"
	F = KAIA_CULT["f2"]
	for x, y in F["mesas"]:
		assert 0 <= x and x + 2 < F["W"] and 2 <= y < F["H"] - 1, "cada mesa, dentro de la carpa"
	for i, (x, y) in enumerate(F["mesas"]):   # sin pisarse
		for x2, y2 in F["mesas"][i + 1:]:
			assert y != y2 or x + 3 <= x2 or x2 + 3 <= x, "dos mesas, una encima de otra"
	ocup = {(x + d, y) for x, y in F["mesas"] for d in range(3)} | {(x, y) for x, y, k in F["o"]}
	sx, sy = F["sale"]; ex, ey = F["entra"]
	assert (sx, sy) not in ocup and (ex, ey) not in ocup, "la puerta y la entrada, libres"
	assert all(x != 0 for x, y in ocup if y >= 2), "la columna de la izquierda, libre: el paso entre los pasillos"
	with open(DJ, "w", encoding="utf-8") as fh:
		json.dump(D, fh, ensure_ascii=False, separators=(",", ":"))
	print("kaia_cult: %s, %d mesas (obra %d €), mapa %s %d × %d" % (", ".join("%d × %s (%d plazas, kit %d €)" % (N["max"], N["n"], N["plazas"], N["kit"]["p"]) for N in NIV), len(KAIA_CULT["f2"]["mesas"]), KAIA_CULT["f2"]["p"], MAPA, W, H))

if __name__ == "__main__":
	main()
