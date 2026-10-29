# Landrace Hunters — las rarezas heredables (ESTUDIO, tanda 2; lo pidió el usuario: «metas mano a las mejoras que hablamos»; solo
# con Datos.CAL). Escribe RAREZAS en godot/datos/datos.json:
#  · p: la probabilidad de que una planta salga con un rasgo raro sin tenerlo su línea (1 de cada 50);
#  · niv: la de que lo saque si su línea lo lleva, por el nivel de fijación (1 a 4): a la 4.ª generación, fijado, todas;
#  · orden y r: los rasgos, con su efecto. Nada que ver con la rara de SHINY (sus semillas no la llevan): estos se heredan.
#   python3 -I tools/rarezas.py
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

RAREZAS = {
	"p": 0.02,
	"niv": [0, 0.25, 0.5, 0.75, 1],
	"fija": 4,
	"orden": ["enana", "doble", "aroma", "resina"],
	"r": {
		"enana": {"n": "Enana", "d": "Porte bajo y compacto: crece un 15 % más deprisa y rinde un 10 % menos.", "crec": 0.15, "g": -0.1},
		"doble": {"n": "Doble cosecha", "d": "Rebrota una vez después de cosecharla: vuelve a vegetativo y da una segunda cosecha del 60 %.", "vuelve": 0.5, "g2": 0.6},
		"aroma": {"n": "Aroma único", "d": "Un olor que no tiene otra: su hierba se paga un 25 % más.", "x": 0.25},
		"resina": {"n": "Resinosa", "d": "Cubierta de tricomas: 1,5 puntos más de THC.", "thc": 1.5},
	},
}

def main():
	s = open(DATOS, encoding='utf8').read()
	D = json.loads(s)
	assert RAREZAS["orden"] == list(RAREZAS["r"]) and len(RAREZAS["niv"]) == RAREZAS["fija"] + 1 and RAREZAS["niv"][-1] == 1
	D["RAREZAS"] = RAREZAS
	t = json.dumps(D, ensure_ascii=False, separators=(',', ':'))
	if t != s:
		open(DATOS, 'w', encoding='utf8').write(t)
	print("rarezas: %s · 1 de cada %d" % (", ".join(RAREZAS["orden"]), round(1 / RAREZAS["p"])))

main()
