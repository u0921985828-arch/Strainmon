#!/usr/bin/env python3
# Landrace Hunters — genéticas actuales (lo pidió el usuario: «me refería a genéticas más actuales»).
# Doce cruces modernos en cadena (cada uno con padres que ya están en el juego o que entran antes en esta
# misma lista) y tres autoflorecientes. Todos con su linaje publicado, con «≈» donde el linaje no está claro.
# Nada inventado, ningún criador, banco ni persona, y fuera cualquier nombre que aluda a una franquicia o
# que esté en litigio de marca (de ahí «GSC» y «Original Glue»). Van al final de STRAINS para no mover los
# números de antes.
#   python3 -I tools/catalogo3.py
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

# clave: (nombre, [padres], linaje, nota del diario)
CRUCES = [
	("ogkush", "OG Kush", ["chemdawg", "hindu"], "≈ Chemdawg × Hindu Kush",
	 "La madre de media California: limón, gasolina y pino sobre un fondo de tierra. Linaje discutido hasta hoy, pero el olor no engaña."),
	("gsc", "GSC", ["ogkush", "durban"], "OG Kush × Durban Poison",
	 "La OG con la Durban: cogollos apretados, morados por los bordes y de un dulce a masa de galleta. Poca cosecha para lo que pide, pero se perdona."),
	("gdp", "Granddaddy Purple", ["purpura", "mango"], "≈ Purple Urkle × Big Bud",
	 "Índica morada de cogollo enorme y olor a uva. Con frío por la noche se pone casi negra."),
	("cherrypie", "Cherry Pie", ["gdp", "durban"], "Granddaddy Purple × Durban Poison",
	 "La uva de la Granddaddy con la chispa de la Durban. Huele a cereza en almíbar y florece antes que su madre."),
	("wcake", "Wedding Cake", ["gsc", "cherrypie"], "GSC × Cherry Pie",
	 "Resina por todas partes y un dulce a bizcocho con vainilla. Quiere poda y aire, que el cogollo cierra mucho."),
	("sherbet", "Sunset Sherbet", ["gsc", "purpura"], "≈ GSC × Pink Panties",
	 "La rama dulce de la GSC: naranja, mantequilla y bayas. Más corta de flor y más agradecida de cultivar."),
	("gelato", "Gelato", ["sherbet", "gsc"], "Sunset Sherbet × GSC (Thin Mint)",
	 "Cogollos compactos de morado y naranja con un postre de fondo. Pide pocos nutrientes y mucho control de humedad."),
	("dosidos", "Do-Si-Dos", ["gsc", "ogkush"], "≈ GSC × Face Off OG",
	 "La GSC puesta de vuelta con una OG: aún más resina, aún más olor. Planta baja y ancha, de poda fácil."),
	("glue", "Original Glue", ["chemdawg", "dragon"], "≈ Chem Sister × Sour Dubb × Chocolate Diesel",
	 "Tanta resina que pega las tijeras. Olor a disolvente y tierra; florece larga y no perdona el exceso de abono."),
	("lemontree", "Lemon Tree", ["citrus", "dragon"], "Lemon Skunk × Sour Diesel",
	 "Limón rallado con un fondo de gasóleo. Estira de lo lindo al pasar a flor, así que se corta antes de cambiar la luz."),
	("ppunch", "Purple Punch", ["ogkush", "gdp"], "≈ Larry OG × Granddaddy Purple",
	 "Caramelo de uva y arándano. De las que se cuidan solas, siempre que la noche sea fresca."),
	("forbidden", "Forbidden Fruit", ["cherrypie", "brumaog"], "Cherry Pie × Tangie",
	 "Cereza y mandarina en el mismo cogollo, morado con pelos naranjas. La más vistosa de la carpa."),
]
AUTOS = [
	("gscauto", "GSC Auto", "gsc", "GSC × Ruderalis",
	 "La galleta en versión automática: cabe en cualquier sitio y no espera el cambio de luz. No se clona."),
	("gelatoauto", "Gelato Auto", "gelato", "Gelato × Ruderalis",
	 "El postre de la Gelato a su edad. Lo que pierde de planta lo gana de vueltas al año."),
	("wcakeauto", "Wedding Cake Auto", "wcake", "Wedding Cake × Ruderalis",
	 "Resina de sobra para lo poco que tarda. A 18/6 de principio a fin y no se le toca el fotoperiodo."),
]
FAMILIA = ("modernas", {"n": "Las de ahora", "b": "thc", "v": 0.03, "s": []})

def mezcla(a, b, p=.5):
	a, b = a.lstrip('#'), b.lstrip('#')
	return '#' + ''.join('%02x' % int(round(int(a[i:i+2], 16) * (1 - p) + int(b[i:i+2], 16) * p)) for i in (0, 2, 4))

def main():
	D = json.load(open(DATOS, encoding='utf-8'))
	S, DEX, A, DIA, R, F = D["STRAINS"], D["DEX"], D["AUTO"], D["DIARIO"], D["RECIPES"], D["FAMILIAS"]
	fk, fv = FAMILIA
	if fk not in F: F[fk] = dict(fv)
	nuevas = []
	for k, n, ps, o, h in CRUCES:
		assert k not in S, k
		for p in ps: assert p in S, (k, p)
		rk = "+".join(sorted(ps))
		assert rk not in R, (k, rk)
		P = [S[p] for p in ps]
		m = lambda c: sum(float(x[c]) for x in P) / len(P)
		S[k] = {"n": n, "thc": min(24, int(round(m("thc")))), "y": int(round(m("y"))),
		        "d": round(m("d") * 4) / 4, "r": int(round(m("r"))),
		        "c": mezcla(P[0]["c"], P[1]["c"]), "ind": int(round(m("ind") / 5) * 5),
		        "hj": mezcla(P[0]["hj"], P[1]["hj"]), "tipo": "estable", "o": o,
		        "h": h, "gen": 1 + max(int(x["gen"] or 0) for x in P)}
		R[rk] = k
		DEX.append(k); DIA[k] = h; nuevas.append(k)
		if k not in F[fk]["s"]: F[fk]["s"].append(k)
	for k, n, p, o, h in AUTOS:
		assert k not in S and p in S, k
		x = S[p]
		rk = "+".join(sorted([p, "ruderalis"]))
		assert rk not in A["recipes"], (k, rk)
		S[k] = {"n": n, "thc": max(10, int(x["thc"]) - 3), "y": int(round(int(x["y"]) * .55)),
		        "d": max(1.75, round((float(x["d"]) - 1) * 4) / 4), "r": int(x["r"]),
		        "c": x["c"], "ind": int(x["ind"]), "hj": x["hj"], "tipo": "estable", "auto": 1,
		        "o": o, "h": h, "gen": int(x["gen"]) + 1}
		A["recipes"][rk] = k
		A["dex"].append(k); DIA[k] = h; nuevas.append(k)
		if k not in F["autos"]["s"]: F["autos"]["s"].append(k)
	json.dump(D, open(DATOS, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
	print("catalogo3: %d variedades (%d sin autos, %d autos) · %d nuevas: %s"
	      % (len(S), len(DEX), len(A["dex"]), len(nuevas), ", ".join(S[k]["n"] for k in nuevas)))

if __name__ == '__main__':
	main()
