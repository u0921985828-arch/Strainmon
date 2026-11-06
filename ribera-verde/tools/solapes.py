#!/usr/bin/env python3
# Landrace Hunters — que ningún mueble se pinte encima de otro (lo pidió el usuario: «No quiero que ningún objeto de pared o suelo se
# superponga sobre otro / Queda mal y descuidado»). Los mapas de datos.json que traían dos objetos montados (godot/tests/solapes.gd los
# encuentra con los sprites de verdad): cada uno, a una casilla libre de al lado. Se puede pasar las veces que se quiera: solo mueve lo
# que sigue en su sitio viejo con el nuevo libre (en MAPS y, en los negocios, también en NEGOCIO[k].o, la copia de su mapa).
#   python3 -I tools/solapes.py
import json
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DJ = os.path.join(RAIZ, "godot", "datos", "datos.json")

# mapa: [(x, y, x2, y2, objeto)]; x2 None = quitarlo
MUEVE = {
	# growcity y almacen, mapas de antes del calendario: con Datos.CAL, en el juego (SOLAPE_CAL de mundo.gd), para no cambiarlos sin CAL
	"cuarto-t": [(5, 2, 2, 2, "mesita")],       # la mesilla, que se metía en la cama: junto a la mesa, sin tapar el cuadro
	"nave-h": [(5, 2, 4, 2, "mesita")],
	"muelle": [(18, 10, 19, 10, "nasas")],      # las nasas, junto a la caja y no encima
}

# los negocios (NEGOCIO.k[k]: sus muebles o, los de cada mejora mj[i].o y el empleado emp [id, look, nombre, x, y]): (x, y, objeto) →
# (x2, y2); después, su mapa (MAPS["loc-" + k].o) se rehace con los muebles, como lo dejaría montar_locales (los de 2 casillas, con su «2»)
NEG = {
	# la taberna: la barra baja una fila, para que el botellero y la cafetera de la pared no queden detrás de ella; Pello, entre las dos
	"puerto": {"o": {(0, 2, "barrilTb"): (0, 6), (3, 2, "cafeTb"): (4, 2), (2, 3, "barraTb"): (2, 4), (4, 3, "barraTb"): (4, 4),
		(6, 3, "cajaL"): (7, 3), (2, 4, "taburTb"): (2, 5), (3, 4, "taburTb"): (3, 5), (5, 4, "taburTb"): (5, 5)},
		"mj": {(0, 4, "barrilTb"): (0, 4), (3, 6, "barrilTb"): (3, 7)}, "emp": (4, 3)},
	# la quesería: la caja, una casilla más allá del mostrador
	"mendi": {"o": {(10, 5, "cajaL"): (11, 5)}},
	# la lavandería: las cuatro lavadoras de la mejora, una en la pared y tres en isla; la mesa de doblar del cesto, a la izquierda del banco
	"ibar": {"o": {(8, 5, "cestaL"): (7, 5)}, "mj": {(4, 2, "lavaN"): (0, 2), (9, 2, "lavaN"): (9, 4), (0, 3, "lavaN"): (10, 4), (0, 4, "lavaN"): (11, 4)}},
}
NEG_ANCHO = ["elevT", "fosoT", "bancoT", "boxL", "cubaQ", "mostrQ", "hornoP", "mostrP", "doblaL", "hornoN", "recambT", "barraN", "botN", "estP",
	"mostrN", "doblaN", "mesaP", "barraTb", "botTb"]   # mundo.gd NEG_ANCHO / NEG_LARGO
NEG_LARGO = {"elevT": 5, "fosoT": 5, "boxL": 5}


# las máquinas de las extracciones del piso, en la fila de abajo (su pieza de ORDEN_P["home"]): cada sprite es algo más ancho que su
# casilla y, pegadas, se montaban; con Datos.CAL (defc, calle.gd def_p), una casilla libre entre cada dos y la de la puerta (5, 7), libre.
# Sin CAL, donde estaban (las pruebas contra el HTML)
EXTR = {"lavadora": 0, "mallas": 2, "staticM": 11, "prensaM": 7, "tamizM": 9}


def extr(D):
	n = 0
	for P in D["ORDEN_P"]["home"]["piezas"]:
		if P["k"] in EXTR and P.get("defc") != [EXTR[P["k"]], P["def"][1]]:
			P["defc"] = [EXTR[P["k"]], P["def"][1]]
			n += 1
	return n


def mueve_lista(L, cambios):
	n = 0
	for q in L:
		c = cambios.get((q[0], q[1], q[2]))
		if c is not None and [q[0], q[1]] != list(c):
			q[0], q[1] = c
			n += 1
	return n


def negocios(D):
	n = 0
	for k, C in NEG.items():
		N = D["NEGOCIO"]["k"][k]
		n += mueve_lista(N["o"], C.get("o", {}))
		for M in N["mj"]:
			n += mueve_lista(M["o"], C.get("mj", {}))
		if "emp" in C:
			N["emp"][3], N["emp"][4] = C["emp"]
		m = D["MAPS"]["loc-" + k]
		O = [[None] * m["w"] for _ in range(m["h"])]
		for x, y, o in N["o"]:
			O[y][x] = o
			if o in NEG_ANCHO:
				for j in range(1, NEG_LARGO.get(o, 2)):
					O[y][x + j] = o + "2"
		m["o"] = O
	return n


def main():
	with open(DJ, encoding="utf-8") as fh:
		D = json.load(fh)
	n = 0
	for mp, L in MUEVE.items():
		os_ = [D["MAPS"][mp]["o"]]
		if mp.startswith("loc-") and mp[4:] in D.get("NEGOCIO", {}) and "o" in D["NEGOCIO"][mp[4:]]:
			os_.append(D["NEGOCIO"][mp[4:]]["o"])
		for O in os_:
			for x, y, x2, y2, o in L:
				if O[y][x] != o:
					continue
				if x2 is None:
					O[y][x] = None
				elif not O[y2][x2]:
					O[y][x] = None
					O[y2][x2] = o
				else:
					continue
				n += 1
	n += negocios(D)
	n += extr(D)
	with open(DJ, "w", encoding="utf-8") as fh:
		json.dump(D, fh, ensure_ascii=False, separators=(",", ":"))
	print("solapes: %d objetos movidos" % n)


if __name__ == "__main__":
	main()
