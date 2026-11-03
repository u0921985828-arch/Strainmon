# Landrace Hunters — lo que quedaba del repaso 0.76 en «4 · Economía» y «5 · Genética y estadísticas»
# (docs/REPASO-ESTRUCTURA.md). Escribe en godot/datos/datos.json las claves nuevas, todas detrás de Datos.CAL
# (el HTML está congelado en la 1.37 y sus oráculos comparan cifra a cifra sin CAL):
#  · MERCADO.club.topec: lo que un club te coge al día ya no es fijo (200 g desde el primer día, que con los cinco
#    clubs igualaba el kilo de Iñaki pagando un 43 % más por gramo), sino de min a max según la confianza del
#    encargado (rel = REL.socio): sin conocerte 100 g, de socio 130 g. Con los cinco clubs a tope, 650 g al día:
#    por debajo de la carga de 1.000 g de Iñaki, que sigue siendo el canal del volumen (docs/ECONOMIA.md);
#  · CLUB.calorg: los gramos de cada entrega suman calor (antes, +1 por entrega fuese de 50 o de 200 g). A 75 g
#    por punto, el club paga mejor el gramo pero también calienta más por gramo que el por mayor: cada canal
#    tiene su contrapartida, no uno que gana en todo;
#  · IVS.basec: los IV de una línea nueva salían de [6, 18], media 12, por debajo del punto neutro (16): toda
#    línea nueva nacía con un 3 % menos de cosecha y de THC que su ficha. [10, 22] tiene media 16;
#  · ENERGIA.casa.limc y ENERGIA.nave.limc: el piso no podía pasar de 5.320 W con todo puesto y la nave de 5.760,
#    así que el generador y las placas no hacían falta nunca. 4.600 W (un escalón real de potencia contratada) en
#    los dos: el piso a tope con calefactor y aire se pasa, y la nave con sus cuatro mesas de LED también;
#  · PLAZO_PCT: el plazo del capítulo 5 se quedaba en los 12.000 € pactados cuando el negocio ya movía 4.000 €/día
#    (tres días de carga de Iñaki). Don Baltasar pide lo pactado o esta parte de lo facturado desde el plazo
#    anterior, lo que sea más; los tres perfiles de tests/economia.gd facturan 5.949-9.430 € entre plazos, así que
#    a ellos el suelo de 12.000 € no se les mueve.
#   python3 -I tools/repaso_eco_gen.py
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

# el tope por club y día: de min (sin confianza) a max (de socio, rel)
CLUB_TOPEC = {"min": 100, "max": 130, "rel": 50}
CLUB_CALORG = 75         # un punto de calor por cada 75 g de la entrega, además de CLUB.calor
IVS_BASEC = [10, 22]     # media 16 = el punto neutro de Cultivo.iv_f
ENERGIA_LIMC = {"casa": 4600, "nave": 4600}
PLAZO_PCT = 0.5          # la parte de lo facturado entre plazos que pide Don Baltasar, si es más que lo pactado


def main():
	s = open(DATOS, encoding='utf8').read()
	D = json.loads(s)
	D["MERCADO"]["club"]["topec"] = CLUB_TOPEC
	D["CLUB"]["calorg"] = CLUB_CALORG
	D["IVS"]["basec"] = IVS_BASEC
	for k, v in ENERGIA_LIMC.items():
		D["ENERGIA"][k]["limc"] = v
	D["PLAZO_PCT"] = PLAZO_PCT
	# lo que tiene que seguir cumpliéndose
	assert CLUB_TOPEC["min"] >= max(D["CLUB"]["g"][0], D["MERCADO"]["club"]["g"][-1]), 'el tope mínimo tiene que dar para una entrega'
	assert CLUB_TOPEC["rel"] == D["REL"]["socio"], 'el tope llega a su máximo con la confianza de socio'
	assert sum(IVS_BASEC) / 2 == 16, 'la media de la línea nueva, en el punto neutro'
	assert IVS_BASEC[1] - IVS_BASEC[0] == D["IVS"]["base"][1] - D["IVS"]["base"][0], 'el mismo abanico de antes'
	# el piso y la nave a tope, por encima de lo contratado (si no, el generador y las placas no harían falta)
	casa = 3 * (max(f["w"] for f in D["FOCOS"].values()) + sum(x["w"] for k, x in D["EXTRAS"].items() if k in ("vent", "filtro150", "intra"))) \
		+ sum(a["w"] for a in D["APARATOS"].values())
	nave = D["NAVE"]["max"] * max(f["w"] for f in D["FOCO_NAVE"].values())
	assert casa > ENERGIA_LIMC["casa"] and nave > ENERGIA_LIMC["nave"], 'a tope hay que pasarse de lo contratado'
	# el suelo pactado no se mueve para quien factura como los perfiles de tests/economia.gd (9.430 € como mucho entre plazos)
	assert PLAZO_PCT * 9430 < D["PLAZOS"]["5"], 'al jugador justo no le puede subir el plazo'
	# cada canal en su sitio: los cinco clubs a tope no llegan a una carga de Iñaki, y el club calienta más por gramo
	nc = sum(1 for k, c in D["CLUBS"].items() if not c.get("tuyo", False))
	pc = D["CLUB"]["precio"] if "precio" in D["CLUB"] else None
	assert nc * CLUB_TOPEC["max"] < D["IMPERIO"][0]["mayor"], 'los clubs a tope no pueden pasar a Iñaki'
	calor_g = (D["CLUB"]["calor"] + CLUB_TOPEC["max"] / CLUB_CALORG) / CLUB_TOPEC["max"]
	mayor_g = (2 + D["IMPERIO"][0]["mayor"] / 100.0) / D["IMPERIO"][0]["mayor"]
	assert calor_g > mayor_g, 'el club tiene que calentar más por gramo que el por mayor'
	t = json.dumps(D, ensure_ascii=False, separators=(',', ':'))
	if t != s:
		open(DATOS, 'w', encoding='utf8').write(t)
	print("repaso eco/gen: club %d-%d g/día · calor cada %d g · IV %s · potencia %d W (piso %d W a tope, nave %d de %d) · plazo %d %% de lo facturado"
		% (CLUB_TOPEC["min"], CLUB_TOPEC["max"], CLUB_CALORG, IVS_BASEC, ENERGIA_LIMC["casa"], casa, nave, ENERGIA_LIMC["nave"], PLAZO_PCT * 100))


main()
