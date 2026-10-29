# Landrace Hunters — la Copa de otoño por categorías (ESTUDIO, tanda 5; lo pidió el usuario: «metas mano a las mejoras que
# hablamos»; solo con Datos.CAL). Escribe COPA_OT en godot/datos/datos.json: cada 17 de octubre, desde el capítulo 7, el jurado
# de la plaza abre cinco categorías —potencia, sabor, landrace pura, cruce propio y extracción—, una muestra por categoría y año.
# Los rivales (los tres de la CannaCup y Semillas Ondarea, la empresa del Acto II) suben cada año (sube) hasta su tope; el podio
# da dinero y prestigio, y ganar tres categorías el mismo año, la Copa absoluta.
#   python3 -I tools/copa_ot.py
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

CATS = [
	{"k": "pot", "n": "Potencia", "g": 10, "r": [22, 26], "sube": 0.5, "tope": 30,
		"d": "El THC de un tarro curado del todo. 10 g."},
	{"k": "sab", "n": "Sabor", "g": 10, "r": [68, 82], "sube": 2, "tope": 96,
		"d": "Nota de cata sobre 100: el curado, el afinado, el aroma único y el aroma del año. 10 g de cogollo."},
	{"k": "land", "n": "Landrace pura", "g": 10, "r": [15, 18], "sube": 0.3, "tope": 21,
		"d": "El THC de una landrace sin cruzar, curada del todo. 10 g."},
	{"k": "cru", "n": "Cruce propio", "g": 10, "r": [19, 23], "sube": 0.5, "tope": 28,
		"d": "El THC de un cruce tuyo, sin receta, curado del todo. 10 g."},
	{"k": "ext", "n": "Extracción", "g": 2, "r": [52, 62], "sube": 1.5, "tope": 75,
		"d": "El THC de una extracción sin disolventes. 2 g."},
]

COPA = {
	"m": 10, "d": 17, "ch": 7, "aviso": 3, "mapa": "town",
	"cats": CATS,
	"premio": [3000, 1200, 500], "prest": [2, 1, 0],
	"abs": {"n": 3, "eur": 5000, "prest": 3},
	"sab": {"base": 40, "cu": 25, "af": 10, "ar": 15, "aroma": 10},
	"rivales": ["Txoko Berdea", "Huerta Oihana", "Los de Arratia", "Semillas Ondarea"],
}

def main():
	s = open(DATOS, encoding='utf8').read()
	D = json.loads(s)
	assert len({c["k"] for c in CATS}) == len(CATS) == 5
	for c in CATS:
		assert c["r"][0] < c["r"][1] <= c["tope"], c["k"]
	assert len(COPA["premio"]) == len(COPA["prest"]) == 3
	sb = COPA["sab"]
	assert sb["base"] + sb["cu"] + sb["af"] + sb["ar"] + sb["aroma"] == 100
	assert COPA["mapa"] in D["MAPS"]
	assert not (COPA["m"] in D["CUP"]["meses"] and COPA["d"] == D["CUP"]["dia"])
	D["COPA_OT"] = COPA
	t = json.dumps(D, ensure_ascii=False, separators=(',', ':'))
	if t != s:
		open(DATOS, 'w', encoding='utf8').write(t)
	print("copa_ot: %d categorías el %d/%d desde el capítulo %d · %d rivales" % (len(CATS), COPA["d"], COPA["m"], COPA["ch"], len(COPA["rivales"])))

main()
