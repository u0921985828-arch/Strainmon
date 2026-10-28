# Landrace Hunters — los esquemas de macetas de las carpas de KAIA (lo pidió el usuario: «Posibilidad de poner x de cierto tamaño,
# elegir por patrones igual, cuando ya tienes ciertas macetas para completar todo el esquema de la carpa te ofrece poner X cantidad
# dependiendo de cada maceta»; solo con Datos.CAL). Escribe en godot/datos/datos.json:
#  · MACETA50: la maceta de tela de 50 L (como MACETA35, sin carpa de casa que la admita: solo en los esquemas de KAIA);
#  · KC_PATRON: por nivel de KAIA_CULT.niv, cuántas macetas de cada tamaño llenan la carpa, en rejilla y sin pasar de LITROS_M2
#    litros por m² de suelo (la de 200 × 200: 16 de 25 L, 9 de 35 L o 4 de 50 L; las otras, a escala).
#   python3 -I tools/patrones.py
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

MACETA50 = {
	"k": "tela50",
	"m": {"n": "Tela 50 L", "l": 50, "rend": 1.1, "cap": 410, "crec": 1, "agua": 0.95, "plaga": 0.8},
	"cm": [46, 34, "#4a4038", "#625848", 1],
	"shop": {"lbl": "Maceta de tela 50 L", "p": 8, "ch": 4, "cal": 1, "desc": "50 L · hasta 410 g por planta · cosecha +10% · riego ×0,95 · menos plagas\nPara las carpas de KAIA: en el esquema de cada carpa.", "maceta": "tela50"},
	"lmax": {},
}

# las rejillas: 4 × 4, 3 × 3 y 2 × 2 en cada 2 × 2 m
REJILLA = {"tela25": 16, "tela35": 9, "tela50": 4}
CARPAS_M2 = {"s": 4, "m": 8, "l": 16}

def main():
	s = open(DATOS, encoding='utf8').read()
	D = json.loads(s)
	D["MACETA50"] = MACETA50
	litros = {"tela25": 25, "tela35": 35, "tela50": 50}
	pat = {}
	for k, m2 in CARPAS_M2.items():
		pat[k] = [[mk, n * m2 // 4] for mk, n in REJILLA.items()]
		for mk, n in pat[k]:
			assert n * litros[mk] <= m2 * D["LITROS_M2"], (k, mk, n)
	D["KC_PATRON"] = pat
	t = json.dumps(D, ensure_ascii=False, separators=(',', ':'))
	if t != s:
		open(DATOS, 'w', encoding='utf8').write(t)
	print("patrones: %s" % ", ".join("%s %s" % (k, " · ".join("%d × %s" % (n, mk) for mk, n in v)) for k, v in pat.items()))

main()
