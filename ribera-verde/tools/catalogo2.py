#!/usr/bin/env python3
# Landrace Hunters — el catálogo, ampliado (lo pidió el usuario: «Ampliarlo»).
# Once variedades más, todas reales y con linaje publicado: seis cruces clásicos de padres que ya están en el
# juego y cinco autoflorecientes de las que se venden de verdad («X × Ruderalis»). Nada inventado, ningún
# criador, banco ni persona: solo el linaje. Van al final de STRAINS para no mover los números de antes.
#   python3 -I tools/catalogo2.py
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

# clave: (nombre, [padres], linaje, nota del diario)
CRUCES = [
	("skunkkush", "Skunk Kush", ["ria", "hindu"], "Skunk #1 × Hindu Kush",
	 "La Skunk de siempre llevada al Kush: más corta, más ancha y con el olor dulzón de la resina afgana. Aguanta el frío mejor que su madre."),
	("sourcheese", "Sour Cheese", ["dragon", "cheese"], "Sour Diesel × Cheese",
	 "El aroma ácido de la Sour con el queso de la Cheese. Huele desde el rellano, así que o hay filtro o hay visita."),
	("chocohaze", "Chocolate Haze", ["chocolope", "ssh"], "Chocolope × Super Silver Haze",
	 "Sativa larga de flor interminable, con el fondo de cacao de la Chocolope. Pide altura y paciencia."),
	("criticalssh", "Critical Super Silver Haze", ["kushrif", "ssh"], "Critical Mass × Super Silver Haze",
	 "La producción de la Critical con el nervio de la Silver. Cogollos pesados que piden tutor en la última semana."),
	("amnesialemon", "Amnesia Lemon", ["tormenta", "citrus"], "Amnesia Haze × Lemon Skunk",
	 "La Amnesia con el limón de la Lemon Skunk: más corta de flor que su madre y con el cítrico por delante."),
	("sourjack", "Sour Jack", ["dragon", "leyenda"], "Sour Diesel × Jack Herer",
	 "Sativa despierta de combustible y pino. Estira mucho al pasar a flor: déjale sitio antes de cambiar la luz."),
]
AUTOS = [
	("criticalmassauto", "Critical Mass Auto", "kushrif", "Critical Mass × Ruderalis",
	 "La Critical con sangre ruderalis: cogollo gordo para lo poco que ocupa. Florece a su edad y no se clona."),
	("superlemonauto", "Super Lemon Haze Auto", "superlemon", "Super Lemon Haze × Ruderalis",
	 "El limón de la Super Lemon en versión automática. Déjala a 18/6 de principio a fin y no la cambies."),
	("orotropauto", "Pineapple Express Auto", "orotrop", "Pineapple Express × Ruderalis",
	 "La piña de la Pineapple Express a su edad. Rinde menos que la de fotoperiodo, pero no espera a nadie."),
	("tangieauto", "Tangie Auto", "brumaog", "Tangie × Ruderalis",
	 "Mandarina en maceta pequeña. Como todas las autos, lo que se pierde de planta se gana de vueltas al año."),
	("whiterussianauto", "White Russian Auto", "whiterussian", "White Russian × Ruderalis",
	 "La White Russian con ruderalis: resina de sobra para el poco tiempo que tarda. No se saca madre de ella."),
]

# la familia de la CannaDex de cada cruce nuevo
FAM = {"skunkkush": "skunk", "sourcheese": "skunk", "chocohaze": "haze",
       "criticalssh": "haze", "amnesialemon": "haze", "sourjack": "leyenda"}

def mezcla(a, b, p=.5):
	a, b = a.lstrip('#'), b.lstrip('#')
	return '#' + ''.join('%02x' % int(round(int(a[i:i+2], 16) * (1 - p) + int(b[i:i+2], 16) * p)) for i in (0, 2, 4))

def main():
	D = json.load(open(DATOS, encoding='utf-8'))
	S, DEX, A, DIA = D["STRAINS"], D["DEX"], D["AUTO"], D["DIARIO"]
	nuevas = []
	for k, n, ps, o, h in CRUCES:
		assert k not in S, k
		for p in ps: assert p in S, p
		P = [S[p] for p in ps]
		m = lambda c: sum(float(x[c]) for x in P) / len(P)
		S[k] = {"n": n, "thc": min(24, int(round(m("thc")))), "y": int(round(m("y"))),
		        "d": round(m("d") * 4) / 4, "r": int(round(m("r"))),
		        "c": mezcla(P[0]["c"], P[1]["c"]), "ind": int(round(m("ind") / 5) * 5),
		        "hj": mezcla(P[0]["hj"], P[1]["hj"]), "tipo": "estable", "o": o,
		        "h": h, "gen": 1 + max(int(x["gen"] or 0) for x in P)}
		D["RECIPES"]["+".join(sorted(ps))] = k
		DEX.append(k); DIA[k] = h; nuevas.append(k)
		fam = FAM[k]
		assert fam in D["FAMILIAS"], fam
		if k not in D["FAMILIAS"][fam]["s"]: D["FAMILIAS"][fam]["s"].append(k)
	for k, n, p, o, h in AUTOS:
		assert k not in S and p in S, k
		x = S[p]
		S[k] = {"n": n, "thc": max(10, int(x["thc"]) - 3), "y": int(round(int(x["y"]) * .55)),
		        "d": max(1.75, round((float(x["d"]) - 1) * 4) / 4), "r": int(x["r"]),
		        "c": x["c"], "ind": int(x["ind"]), "hj": x["hj"], "tipo": "estable", "auto": 1,
		        "o": o, "h": h, "gen": 2}
		A["recipes"]["+".join(sorted([p, "ruderalis"]))] = k
		A["dex"].append(k); DIA[k] = h; nuevas.append(k)
		if k not in D["FAMILIAS"]["autos"]["s"]: D["FAMILIAS"]["autos"]["s"].append(k)
	json.dump(D, open(DATOS, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
	print("catalogo2: %d variedades (%d sin autos, %d autos) · %d nuevas: %s"
	      % (len(S), len(DEX), len(A["dex"]), len(nuevas), ", ".join(S[k]["n"] for k in nuevas)))

if __name__ == '__main__':
	main()
