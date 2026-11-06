#!/usr/bin/env python3
# Landrace Hunters — genéticas actuales (lo pidió el usuario: «me refería a genéticas más actuales»), con la
# regla que puso después: «Si el linaje no está claro, no quiero genéticas inventadas ni nada».
#
# Por eso aquí solo entra la variedad moderna cuyo linaje está publicado SIN discusión y cuyos dos padres
# están ya en el juego, de modo que la receta del juego es el linaje de verdad y no un sustituto.
# Descartadas en esta tanda (en el estudio de abajo) todas las que no cumplían las dos cosas.
#
# Lemon Tree = Lemon Skunk × Sour Diesel: los dos padres están (`citrus`, `dragon`) y el linaje no se discute.
#
# DESCARTADAS y por qué:
#   OG Kush (≈ Chemdawg × Hindu Kush), Granddaddy Purple (≈ Purple Urkle × Big Bud), Sunset Sherbet
#   (≈ GSC × Pink Panties), Do-Si-Dos (≈ GSC × Face Off OG), Original Glue (≈ Chem Sister × Sour Dubb ×
#   Chocolate Diesel) y Purple Punch (≈ Larry OG × GDP): linaje discutido o con un padre que no está en el
#   juego, así que la receta habría sido inventada.
#   GSC, Cherry Pie, Wedding Cake, Gelato y Forbidden Fruit: su linaje sí está claro, pero cuelga de una de
#   las anteriores, así que caen con ella.
#   GSC Auto, Gelato Auto y Wedding Cake Auto: sus padres de fotoperiodo ya no están.
#
#   python3 -I tools/catalogo3.py
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

# clave: (nombre, [padres], linaje, nota del diario, familia)
CRUCES = [
	("lemontree", "Lemon Tree", ["citrus", "dragon"], "Lemon Skunk × Sour Diesel",
	 "Limón rallado con un fondo de gasóleo. Estira de lo lindo al pasar a flor, así que se corta antes de cambiar la luz.",
	 "skunk"),
]

def mezcla(a, b, p=.5):
	a, b = a.lstrip('#'), b.lstrip('#')
	return '#' + ''.join('%02x' % int(round(int(a[i:i+2], 16) * (1 - p) + int(b[i:i+2], 16) * p)) for i in (0, 2, 4))

def main():
	D = json.load(open(DATOS, encoding='utf-8'))
	S, DEX, DIA, R, F = D["STRAINS"], D["DEX"], D["DIARIO"], D["RECIPES"], D["FAMILIAS"]
	nuevas = []
	for k, n, ps, o, h, fam in CRUCES:
		assert k not in S, k
		for p in ps: assert p in S, (k, p)
		rk = "+".join(sorted(ps))
		assert rk not in R, (k, rk)
		assert fam in F, fam
		P = [S[p] for p in ps]
		m = lambda c: sum(float(x[c]) for x in P) / len(P)
		S[k] = {"n": n, "thc": min(24, int(round(m("thc")))), "y": int(round(m("y"))),
		        "d": round(m("d") * 4) / 4, "r": int(round(m("r"))),
		        "c": mezcla(P[0]["c"], P[1]["c"]), "ind": int(round(m("ind") / 5) * 5),
		        "hj": mezcla(P[0]["hj"], P[1]["hj"]), "tipo": "estable", "o": o,
		        "h": h, "gen": 1 + max(int(x["gen"] or 0) for x in P)}
		R[rk] = k
		DEX.append(k); DIA[k] = h; nuevas.append(k)
		if k not in F[fam]["s"]: F[fam]["s"].append(k)
	json.dump(D, open(DATOS, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
	print("catalogo3: %d variedades (%d sin autos, %d autos) · %d nueva: %s"
	      % (len(S), len(DEX), len(D["AUTO"]["dex"]), len(nuevas), ", ".join(S[k]["n"] for k in nuevas)))

if __name__ == '__main__':
	main()
