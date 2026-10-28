# python3 -I tools/banco_tia.py  → BANCO_TIA, el mapa banco-rv y sus puertas en godot/datos/datos.json (con Datos.CAL)
# ESTUDIO tanda 1 (lo pidió el usuario: «mete mano a las mejoras que hablamos»; docs/ESTUDIO.md § 5.1 y § 5.3): el final es la
# genética, no el tráfico. El cuarto de atrás de la asociación del barrio alto, el banco de semillas que la tía no terminó, se abre
# con la lata del manzano (hilo.gd) y se restaura entregando colecciones de semillas, como el Centro Cívico: cada colección
# destapa un mueble del cuarto y abre lo suyo. Lo hace src/bancotia.gd.
#   col: id, n (nombre), s (variedades), k (semillas de cada; si no, BANCO_TIA.k), fija (la línea, estable del todo), z (zona)
#   zonas: x, y (la casilla de la izquierda: los muebles son de 2 casillas, la de la derecha es o + "2"), o (el mueble), n;
#     puerta: la del laboratorio, que es una sala aparte (lab-rv), precintada (puertaLabP) hasta que se restaura
# El laboratorio (lo pidió el usuario: «debe parecer un laboratorio de verdad, no los materiales de labo y ya, las normas que tienes
# que tener en un laboratorio real»): lab-rv, 12 × 8, con la antesala (la percha de las batas, gafas y guantes, el lavamanos de
# pedal, el cartel de las normas y el botiquín) separada de la zona de trabajo por la línea amarilla (floorLabL, columna LAB.linea),
# y dentro la ducha y el lavaojos de emergencia, el extintor, la cabina de flujo laminar, el autoclave, la estufa de germinación,
# la nevera de muestras, la poyata del microscopio, la de la balanza y el contenedor amarillo de residuos. Las normas, en
# bancotia.gd (LAB): manos, bata, gafas y guantes antes de pasar la línea; nada de comer, beber ni fumar; sereno; el instrumental
# esterilizado en el autoclave ese día; el puesto limpio y lo usado al contenedor; el EPI se deja en la antesala.
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DJ = os.path.join(RAIZ, "godot", "datos", "datos.json")

W, H = 12, 8
MAPA = "banco-rv"
PUERTA = (9, 1)          # en la asociación, junto a la foto de la tía (fotoMaite en 7-8)
VUELTA = (1, 1)          # la puerta de vuelta, en el cuarto

BANCO_TIA = {
	"mapa": MAPA, "k": 2, "saca": 7, "socios": 7, "rep": 10, "prest": 3,
	"fichero": [6, 3],
	"col": [
		{"id": "kush", "n": "Las del Kush y el Himalaya", "s": ["rif", "hindu", "chitral", "kashmir", "malana", "nepal"], "z": "camara"},
		{"id": "costa", "n": "Las de la costa", "s": ["acapulco", "lamb", "hawai", "durban", "zamal", "mangarosa"], "z": "lab"},
		{"id": "africa", "n": "Las de África y el Mediterráneo", "s": ["malawi", "congo", "swazi", "etiopia", "kif", "beldia", "libano"], "z": "cata"},
		{"id": "sierra", "n": "Las de la sierra americana", "s": ["mich", "punto", "colgold", "oaxaca", "panama"], "z": "archivo"},
		{"id": "asia", "n": "Las de Asia", "s": ["thai", "choco", "hthai", "lao", "vietblack", "kerala"], "z": "socios"},
		{"id": "haze", "n": "La Haze del 98, fijada", "s": ["silver"], "k": 5, "fija": True, "z": "placa"},
	],
	"zonas": {
		"camara": {"x": 3, "y": 2, "o": "btCamara", "n": "La cámara fría"},
		"archivo": {"x": 9, "y": 2, "o": "btArchivo", "n": "El archivo de la tía"},
		"lab": {"x": 8, "y": 1, "o": "puertaLab", "n": "El laboratorio", "puerta": True},
		"socios": {"x": 5, "y": 5, "o": "btMostrador", "n": "El mostrador de los socios"},
		"cata": {"x": 8, "y": 5, "o": "btCata", "n": "La sala de catas"},
		"placa": {"x": 6, "y": 1, "o": "btPlaca", "n": "La placa de la tía"},
	},
}

LAB = {"mapa": "lab-rv", "w": 12, "h": 8, "linea": 4, "puerta": [1, 1],
	"o": [[0, 1, "labNormas"], [10, 1, "labBotiquin"], [4, 1, "labLavaojos"], [8, 1, "labExtintor"],
		[2, 2, "labPercha"], [3, 2, "labPila"], [5, 2, "labDucha"], [6, 2, "labFlujo"], [7, 2, "labFlujo2"], [9, 2, "labAutoclave"],
		[11, 4, "labEstufa"], [11, 2, "labNevera"], [6, 5, "labMicro"], [7, 5, "labMicro2"], [8, 5, "labBalanza"], [9, 5, "labBalanza2"],
		[11, 6, "labResiduos"], [6, 6, "labTaburete"], [9, 6, "labTaburete"]],
	"esteril": 30}

def mapa_lab():
	W2, H2 = LAB["w"], LAB["h"]
	g = [["iwT_lab"] * W2, ["iwB_lab"] * W2] + [["floorLab"] * W2 for _ in range(H2 - 2)]
	for y in range(2, H2):
		g[y][LAB["linea"]] = "floorLabL"
	o = [[None] * W2 for _ in range(H2)]
	for x, y, k in LAB["o"]:
		o[y][x] = k
	return {"name": LAB["mapa"], "w": W2, "h": H2, "g": g, "o": o, "exits": {}, "doors": {}, "music": "club", "blds": [], "est": None}

def mapa():
	g = [["iwT_club"] * W, ["iwB_club"] * W] + [["floorC"] * W for _ in range(H - 2)]
	o = [[None] * W for _ in range(H)]
	f = BANCO_TIA["fichero"]
	o[f[1]][f[0]] = "btFichero"
	o[f[1]][f[0] + 1] = "btFichero2"
	for k, z in BANCO_TIA["zonas"].items():   # tapado, hasta que se restaura (bancotia.gd lo cambia al entrar)
		if k != "placa" and not z.get("puerta"):
			o[z["y"]][z["x"]] = "btTapado"
			o[z["y"]][z["x"] + 1] = "btTapado2"
	return {"name": MAPA, "w": W, "h": H, "g": g, "o": o, "exits": {}, "doors": {}, "music": "club", "blds": [], "est": None}

def main():
	with open(DJ, encoding="utf-8") as fh:
		D = json.load(fh)
	D["BANCO_TIA"] = BANCO_TIA
	D["MAPS"][MAPA] = mapa()
	D["MAPS"][LAB["mapa"]] = mapa_lab()
	D["LAB"] = LAB
	P = D["PUERTAS_INT"]
	P["club-rv"] = [e for e in P["club-rv"] if e.get("to") != MAPA] + [
		{"x": PUERTA[0], "y": PUERTA[1], "o": "puertaI", "to": MAPA, "tx": VUELTA[0], "ty": VUELTA[1] + 1, "dir": "down", "n": "La puerta del cuarto de atrás", "llave": "banco"}]
	zl = BANCO_TIA["zonas"]["lab"]
	P[MAPA] = [{"x": VUELTA[0], "y": VUELTA[1], "o": "puertaI", "to": "club-rv", "tx": PUERTA[0], "ty": PUERTA[1] + 1, "dir": "down", "n": "La puerta del club"},
		{"x": zl["x"], "y": zl["y"], "o": "puertaLab", "to": LAB["mapa"], "tx": LAB["puerta"][0], "ty": LAB["puerta"][1] + 1, "dir": "down", "n": "La puerta del laboratorio", "llave": "lab"}]
	P[LAB["mapa"]] = [{"x": LAB["puerta"][0], "y": LAB["puerta"][1], "o": "puertaLab", "to": MAPA, "tx": zl["x"], "ty": zl["y"] + 1, "dir": "down", "n": "La puerta del banco"}]
	m = D["MAPS"]["club-rv"]
	assert m["o"][PUERTA[1]][PUERTA[0]] is None and m["o"][PUERTA[1] + 1][PUERTA[0]] is None, "la puerta del banco, en un sitio libre"
	sids = [s for c in BANCO_TIA["col"] for s in c["s"]]
	assert len(sids) == len(set(sids)), "cada variedad, en una sola colección"
	assert all(s in D["STRAINS"] for s in sids), [s for s in sids if s not in D["STRAINS"]]
	with open(DJ, "w", encoding="utf-8") as fh:
		json.dump(D, fh, ensure_ascii=False, separators=(",", ":"))
	print("banco_tia: %d colecciones, %d variedades, mapa %s %d × %d" % (len(BANCO_TIA["col"]), len(sids), MAPA, W, H))

if __name__ == "__main__":
	main()
