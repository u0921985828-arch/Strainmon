# Landrace Hunters — LA TIENDA DE EXTRAS (lo pidió el usuario: «Quiero que el juego no sea demo pero que podamos elegir cosas
# para que sean como extras o dlc, objetos para comprar y demas / O incluso algún tipo de moneda especial»). Solo Godot, con
# Datos.CAL. Escribe TIENDA en godot/datos/datos.json:
#  · mon: la moneda del juego, las SEMILLAS DORADAS (nombre propio): cómo se ganan jugando y el regalo a quien compró el juego
#    completo cuando el juego era una demo;
#  · gana: lo que da cada cosa de la partida (objetivo diario, capítulo, Copa, fenotipo raro, número de la revista, logro), con
#    su tope por partida donde hace falta, para que la moneda se gane jugando y no solo se compre;
#  · cat: las categorías de la tienda, por orden;
#  · it: el catálogo. Cada cosa lleva su clave, nombre, categoría, texto, precio en semillas doradas (sd), si es de una sola vez
#    (una) y qué deja en la partida (ef). Los paquetes de semillas doradas (categoría «sd») son los únicos que se pagan con
#    dinero de verdad, por Google Play (prod, el id del producto; consumibles).
# El juego entero viene con la aplicación: los extras adelantan trabajo o dan cosas, nunca abren capítulos ni historia, y todo
# lo que hay en la tienda se consigue también jugando (req dice con qué se abre cada extra).
# python3 -I tools/tienda.py (desde ribera-verde/)
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

MON = {
	"n": "semillas doradas",
	"n1": "semilla dorada",
	"ic": "semilla",
	"regalo": 300,       # a quien compró el juego completo cuando el juego era una demo
	"prod0": "juego_completo",
	"txt": "Las semillas doradas se ganan jugando: objetivos diarios, capítulos, la Copa, fenotipos raros, los números de EL ESQUEJE y los logros. En la tienda también se pueden comprar.",
	"pie": "El juego entero viene con la aplicación. Lo de aquí adelanta trabajo o da cosas: nada de esto abre capítulos ni historia, y todo se consigue jugando.",
}

# lo que da cada cosa de la partida; tope, lo máximo que puede dar esa vía en una partida (0 = sin tope)
GANA = [
	{"k": "diario", "v": 1, "tope": 0, "t": "Cada objetivo diario hecho"},
	{"k": "cap", "v": 8, "tope": 0, "t": "Cada capítulo nuevo"},
	{"k": "copa", "v": 10, "tope": 0, "t": "Cada oro de la Copa de otoño"},
	{"k": "copaabs", "v": 30, "tope": 0, "t": "La Copa absoluta"},
	{"k": "rareza", "v": 3, "tope": 0, "t": "Cada fenotipo raro nuevo del cuaderno"},
	{"k": "revista", "v": 2, "tope": 0, "t": "Cada número nuevo de EL ESQUEJE"},
	{"k": "logro", "v": 2, "tope": 0, "t": "Cada logro"},
	{"k": "copa98", "v": 25, "tope": 25, "t": "Ganar la Copa de la asociación"},
]

CAT = [
	{"k": "sd", "n": "SEMILLAS DORADAS", "d": "Paquetes de semillas doradas."},
	{"k": "gen", "n": "GENÉTICAS", "d": "Semillas de variedades que también salen jugando."},
	{"k": "cul", "n": "CULTIVO", "d": "Abono, tarros, sobres, macetas y focos."},
	{"k": "ext", "n": "EXTRAS", "d": "Trabajo ya hecho: obras, locales y salas."},
]

# Los paquetes de semillas doradas: lo único que se paga con dinero de verdad (consumibles de Google Play).
PACKS = [
	{"k": "sd1", "n": "Puñado de semillas doradas", "cat": "sd", "sd": 0, "da": 120, "prod": "sd_120", "p": 2.99,
		"t": "Ciento veinte semillas doradas."},
	{"k": "sd2", "n": "Sobre de semillas doradas", "cat": "sd", "sd": 0, "da": 400, "prod": "sd_400", "p": 7.99,
		"t": "Cuatrocientas semillas doradas. Un trece por ciento más por semilla que el puñado."},
	{"k": "sd3", "n": "Bote de semillas doradas", "cat": "sd", "sd": 0, "da": 1000, "prod": "sd_1000", "p": 17.99,
		"t": "Mil semillas doradas. Un veinticinco por ciento más por semilla que el puñado."},
	{"k": "sd4", "n": "Caja de semillas doradas", "cat": "sd", "sd": 0, "da": 2600, "prod": "sd_2600", "p": 39.99,
		"t": "Dos mil seiscientas semillas doradas. Un cuarenta y cinco por ciento más por semilla que el puñado."},
]

# El catálogo que se paga con semillas doradas. ef: {tipo: …} lo que deja en la partida (lo aplica tienda.gd).
#  · req: con qué se abre ese extra en la partida (vacío, siempre); rz, el texto de por qué todavía no.
IT = [
	# ---------- genéticas ----------
	{"k": "gland", "n": "Tres landraces", "cat": "gen", "sd": 40, "una": False,
		"t": "Tres semillas de landrace de las que te falten, una de cada variedad, con su ficha ya descubierta. Si ya las tienes todas, no hay nada que mandar.",
		"ef": {"tipo": "semillas", "n": 3, "grupo": "land"}},
	{"k": "grec", "n": "Cinco de receta", "cat": "gen", "sd": 60, "una": False,
		"t": "Cinco semillas de una variedad de receta que te falte. El recetario de la CannaDex sigue diciendo cómo se saca por tu cuenta.",
		"ef": {"tipo": "semillas", "n": 5, "grupo": "rec", "misma": True}},
	{"k": "gauto", "n": "Cuatro autoflorecientes", "cat": "gen", "sd": 35, "una": False,
		"t": "Cuatro semillas autoflorecientes, una de cada variedad, de las que te falten.",
		"ef": {"tipo": "semillas", "n": 4, "grupo": "auto"}},
	{"k": "ghaze", "n": "Cinco Haze del 98", "cat": "gen", "sd": 120, "una": False,
		"t": "Cinco semillas de la Haze del 98, la de la lata del manzano del cuaderno azul de la tía.",
		"req": "haze", "rz": "Hace falta la lata del cuaderno azul de la tía.",
		"ef": {"tipo": "semillas", "n": 5, "grupo": "haze", "misma": True}},
	# ---------- cultivo ----------
	{"k": "cabono", "n": "Abono para una temporada", "cat": "cul", "sd": 12, "una": False,
		"t": "Cien dosis de abono de crecimiento, cien de floración y doscientas de corrector, de la marca mineral, a casa.",
		"ef": {"tipo": "items", "it": {"fertv": 100, "fert": 100, "phm": 200}}},
	{"k": "cbio", "n": "Abono orgánico para una temporada", "cat": "cul", "sd": 14, "una": False,
		"t": "Lo mismo de la marca orgánica: cien dosis de crecimiento, cien de floración y doscientas de corrector. El sustrato sigue vivo y frena las plagas.",
		"ef": {"tipo": "items", "it": {"ofertv": 100, "ofert": 100, "ophm": 200}}},
	{"k": "ctarros", "n": "Los tarros de curado", "cat": "cul", "sd": 10, "una": True,
		"t": "Los tarros de cristal de Kiko para la caja fuerte y la nevera: lo que guardas ahí se cura.",
		"ef": {"tipo": "items", "it": {"tarros": 1}}},
	{"k": "cmaceta", "n": "Nueve macetas de tela", "cat": "cul", "sd": 15, "una": False,
		"t": "Nueve macetas de tela de treinta y cinco litros, de las que entran en la carpa grande y en KAIA.",
		"ef": {"tipo": "items", "it": {"m_tela35": 9}}},
	{"k": "cfoco", "n": "Dos LED de los grandes", "cat": "cul", "sd": 30, "una": False,
		"t": "Dos focos LED de setecientos veinte vatios, los de la carpa grande.",
		"ef": {"tipo": "items", "it": {"f_led720": 2}}},
	{"k": "csobres", "n": "Doce sobres de humedad", "cat": "cul", "sd": 8, "una": False,
		"t": "Doce sobres al sesenta y dos por ciento para los tarros de diez litros del camarote.",
		"req": "cam", "rz": "Hace falta el camarote habilitado.",
		"ef": {"tipo": "sobres", "n": 12}},
	# ---------- extras ----------
	{"k": "earcon", "n": "El arcón congelador", "cat": "ext", "sd": 80, "una": True,
		"t": "El arcón congelador de cinco kilos puesto al lado de la nevera, desde hoy.",
		"ef": {"tipo": "arcon"}},
	{"k": "eobra", "n": "Suelos y paredes", "cat": "ext", "sd": 60, "una": True,
		"t": "Todas las reformas de suelo y de pared del piso, pagadas: se eligen en REFORMAS sin volver a pagarlas.",
		"ef": {"tipo": "reforma"}},
	{"k": "econce", "n": "AUTOS RIBERA, abierto", "cat": "ext", "sd": 120, "una": True,
		"t": "El concesionario del barrio alto abierto desde hoy, sin esperar al capítulo cinco ni al patrimonio. Los vehículos se siguen pagando con tu dinero.",
		"ef": {"tipo": "conce"}},
	{"k": "ecam", "n": "El camarote, listo", "cat": "ext", "sd": 150, "una": True,
		"t": "La obra del camarote hecha, sus cuatro estanterías de tarros de diez litros puestas y doce sobres de humedad dentro.",
		"ef": {"tipo": "camarote"}},
	{"k": "edesp", "n": "El despacho de lujo", "cat": "ext", "sd": 180, "una": True,
		"t": "El despacho de la nave con los monitores y la caja fuerte de alta capacidad, la que no encuentra la redada.",
		"req": "nave", "rz": "Hace falta la nave de Valdehierro.",
		"ef": {"tipo": "despacho"}},
	{"k": "ehuerta", "n": "La huerta, al doble y con riego", "cat": "ext", "sd": 200, "una": True,
		"t": "La huerta de la tía ampliada al doble, con los bidones, el depósito de mil litros, el goteo con bomba solar, las herramientas y la motoazada.",
		"req": "huerta", "rz": "Hay que encontrar antes la huerta, detrás del garaje del barrio.",
		"ef": {"tipo": "huerta"}},
	{"k": "elab", "n": "El laboratorio del banco", "cat": "ext", "sd": 260, "una": True,
		"t": "Las seis colecciones del banco de la tía dadas por entregadas: la cámara fría, el laboratorio, la sala de catas, el archivo, el mostrador de los socios y la placa, destapados de golpe.",
		"req": "bt", "rz": "Hace falta la llave del cuarto de atrás, la de la lata del cuaderno azul.",
		"ef": {"tipo": "banco"}},
	{"k": "ekaia", "n": "KAIA, con las obras hechas", "cat": "ext", "sd": 300, "una": True,
		"t": "La reforma del muelle pagada y KAIA abierto con su dispensario, sin esperar a la cuadrilla.",
		"req": "muelle", "rz": "Hace falta el muelle de Puerto Viejo, del capítulo ocho.",
		"ef": {"tipo": "kaia"}},
]


def main():
	s = open(DATOS, encoding='utf8').read()
	D = json.loads(s)
	it = PACKS + IT
	ks = [x["k"] for x in it]
	assert len(set(ks)) == len(ks), ks
	cats = {c["k"] for c in CAT}
	assert all(x["cat"] in cats for x in it)
	assert all(x["t"] and x["n"] for x in it)
	# los paquetes de dinero de verdad, solo en la categoría sd; y al revés
	for x in it:
		if x["cat"] == "sd":
			assert x.get("prod") and x.get("da", 0) > 0 and x.get("p", 0) > 0 and int(x.get("sd", 0)) == 0, x["k"]
		else:
			assert not x.get("prod") and int(x["sd"]) > 0 and x.get("ef"), x["k"]
	assert len({x["prod"] for x in PACKS}) == len(PACKS)
	# por semilla, cada paquete más grande no puede salir más caro que el anterior
	un = [p["p"] / p["da"] for p in PACKS]
	assert un == sorted(un, reverse=True), un
	gk = [g["k"] for g in GANA]
	assert len(set(gk)) == len(gk) and all(g["v"] > 0 for g in GANA)
	# con lo que se gana jugando se tiene que poder pagar lo de la tienda sin pagar nada: el total del catálogo de una vez
	una = sum(x["sd"] for x in IT if x.get("una"))
	assert una <= 1500, una
	assert all(x["ef"]["tipo"] != "items" or all(v > 0 for v in x["ef"]["it"].values()) for x in IT)
	D["TIENDA"] = {"mon": MON, "gana": GANA, "cat": CAT, "it": it}
	t = json.dumps(D, ensure_ascii=False, separators=(',', ':'))
	if t != s:
		open(DATOS, 'w', encoding='utf8').write(t)
	print("tienda: %d cosas · %d paquetes de %s · %d categorías · %d vías para ganarlas · %d semillas doradas los extras de una vez"
		% (len(it), len(PACKS), MON["n"], len(CAT), len(GANA), una))


main()
