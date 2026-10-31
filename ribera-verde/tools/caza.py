# Landrace Hunters — las landraces por estación y por gente y las fiestas fijas (ESTUDIO, tanda 4; lo pidió el usuario: «metas
# mano a las mejoras que hablamos»; solo con Datos.CAL). Escribe CAZA en godot/datos/datos.json:
#  · fi: las fiestas del calendario (mes, día, cuántos días, el mapa donde se celebran y el SMS de la víspera);
#  · l: diecisiete landraces que, además del banco del PC, da la gente una vez por partida: en su estación (est), un día de
#    temporal (cl), en una fiesta (fi), con confianza (rel), desde un capítulo (ch), conocido el muelle (mar) y, en la feria, por
#    dinero (eur). Con CAL no se venden en el banco del PC (Datos._aplica_auto): solo las da la gente. Con las 13
#    de REGALO y la Malana del Acto II, 30 que se cazan. Todas reales; los textos, propios.
#   python3 -I tools/caza.py
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

FIESTAS = [
	{"k": "feria", "n": "Feria de semillas de primavera", "m": 5, "d": 15, "dias": 3, "mapa": "mercado-in", "de": "KIKO",
		"sms": "Mañana empieza la feria de semillas en el mercado de la Ribera, en Bilbao. Tres días. Los de los puestos traen cosas que no verás en ningún banco."},
	{"k": "barrio", "n": "Fiestas del barrio", "m": 8, "d": 14, "dias": 5, "mapa": "town", "de": "ABUELA TXARO",
		"sms": "Mañana empiezan las fiestas del barrio, cinco días. Ven a la calle, que tu tía no se perdía ni una y todos te preguntan."},
	{"k": "romeria", "n": "Romería de la ermita", "m": 9, "d": 8, "dias": 1, "mapa": "ermita-in", "de": "ABUELA TXARO",
		"sms": "Mañana es la romería de la ermita. Tu tía subía todos los años con sus cuadernos. La serora guarda algo para quien suba."},
]

L = [
	{"k": "zamal", "q": "koldo", "cl": ["tormenta"], "mar": 1, "n": 3, "pista": "Koldo, en el muelle, un día de temporal",
		"t": ["Con esta mar no sale nadie. Siéntate, que te cuento.",
			"Hace años me quedé en la Reunión un mes por un motor roto. Me traje esto en una lata de tabaco. Zamal, lo llaman allí. Para ti."]},
	{"k": "etiopia", "q": "bi_serora", "fi": "romeria", "n": 3, "pista": "la serora de la ermita, el día de la romería",
		"t": ["Has subido el día de la romería, como ella. Tu tía me dejó un sobre para quien viniera hoy.",
			"Dice: «Ethiopian Highland, de un monje de las tierras altas. Que suba al monte otra vez.»"]},
	{"k": "kashmir", "q": "bi_me_es", "fi": "feria", "eur": 40, "n": 3, "pista": "el puesto de especias, en la feria de semillas",
		"t": ["Para la feria traigo lo de mi primo de Cachemira, en bolsitas de té. Semillas de Kashmiri, de su valle."]},
	{"k": "vietblack", "q": "bi_me_fl", "fi": "feria", "eur": 40, "n": 3, "pista": "el puesto de flores, en la feria de semillas",
		"t": ["Las flores no se venden solas. Para los que saben, debajo del mostrador: Vietnamese Black, de los montes."]},
	{"k": "hthai", "q": "bi_me_ve", "fi": "feria", "eur": 40, "n": 3, "pista": "el puesto de verdura, en la feria de semillas",
		"t": ["Mi mujer es de Chiang Mai. Su padre las guardaba en el arroz: Highland Thai. Solo las saco en la feria."]},
	{"k": "colgold", "q": "patxi", "fi": "barrio", "n": 3, "pista": "Patxi, en las fiestas del barrio",
		"t": ["¡Fiestas! Mira, esto lo ganó tu tía en la tómbola de la txosna, el último año. Me lo dejó a mí para que no lo fumara.",
			"Colombian Gold. De la sierra de Santa Marta, dijo ella. Tuyo."]},
	{"k": "punto", "q": "txaro", "fi": "barrio", "n": 3, "pista": "la abuela Txaro, en las fiestas del barrio",
		"t": ["En fiestas se regala, que lo dice el refrán. Mi vecino colombiano me trajo de su tierra hace mil años.",
			"Punto Rojo. Yo no sé qué es, pero tu tía decía que era buena. Toma."]},
	{"k": "mich", "q": "julen", "est": ["verano"], "rel": 20, "n": 3, "pista": "Julen, en verano, si sois amigos",
		"t": ["He vuelto de México. Lo de las playas, mentira: estuve en el altiplano, con un abuelo que cultiva como antes.",
			"Me dio estas. Michoacán. Mejor en tus manos que en las mías."]},
	{"k": "kif", "q": "bixente", "est": ["otoño"], "n": 3, "pista": "Bixente, en la chatarrería, en otoño",
		"t": ["Un camionero de Tánger me dejó una caja de piezas en septiembre. Debajo de los tornillos, esto.",
			"Kif del Rif. Yo de esto no entiendo; tú sí. Llévatelo."]},
	{"k": "beldia", "q": "andoni", "est": ["primavera"], "rel": 20, "n": 3, "pista": "Andoni, en el molino, en primavera, si sois amigos",
		"t": ["En primavera limpio los botes del abuelo. Este no lo cambio, te lo regalo, que tú los cuidas.",
			"Beldia, de Ketama. La más vieja que tengo."]},
	{"k": "libano", "q": "andoni", "est": ["invierno"], "n": 3, "pista": "Andoni, en el molino, en invierno",
		"t": ["En invierno el molino para y yo ordeno el desván. Salió un bote de mi abuelo, de cuando estuvo embarcado.",
			"Pone «Bekaa». Libanesa. Llévatela, que tú las haces crecer."]},
	{"k": "durban", "q": "inaki", "est": ["verano"], "rel": 20, "n": 3, "pista": "Iñaki, en verano, si sois amigos",
		"t": ["Un cliente sudafricano, de los que vienen a hacer surf. No tenía suelto y me pagó con esto.",
			"Durban Poison, dice. Tú que plantas, sácale partido."]},
	{"k": "swazi", "q": "arrieta", "est": ["otoño"], "rel": 20, "n": 3, "pista": "Arrieta, en la nave, en otoño, si sois amigos",
		"t": ["Vaciando la nave de al lado, un saco de semillas de pájaro. Y en medio, un sobre con letra de mujer.",
			"Swazi Gold. Si es lo que creo, es de tu tía. Le alquilé un rincón hace años."]},
	{"k": "congo", "q": "delroy", "est": ["invierno"], "rel": 20, "n": 3, "pista": "Delroy, en la asociación, en invierno, si sois amigos",
		"t": ["En invierno me acuerdo de los que se fueron. Tu tía y yo cambiamos semillas con un congoleño de Bilbao.",
			"Estas son las suyas: Congolese. Las guardaba para ella."]},
	{"k": "nepal", "q": "miren", "est": ["primavera"], "rel": 20, "flag": "lao", "n": 3, "pista": "Miren, en Errotabarri, en primavera, si sois amigos",
		"t": ["En primavera tu tía venía a sembrar conmigo. Un año trajo estas de Nepal, de un viaje que no me quiso contar.",
			"Nepalese. Las colinas del Himalaya, decía. Ya es hora de que vuelvan a la tierra."]},
	{"k": "panama", "q": "kiko", "est": ["invierno"], "rel": 20, "n": 3, "pista": "Kiko, en el growshop, en invierno, si sois amigos",
		"t": ["En enero hago inventario. Detrás de las lámparas viejas, un sobre de tu tía: Panama Red, del 79, dice.",
			"No sé si germinarán. Si alguien lo consigue, eres tú."]},
	{"k": "thai", "q": "bi_capataz", "est": ["invierno"], "n": 3, "pista": "el capataz del almacén del muelle de Bilbao, en invierno",
		"t": ["En invierno llegan menos cargueros. Uno de Bangkok dejó esto en un palé roto. Thai, de las selvas del norte.",
			"Aquí nadie lo quiere. Llévatelo antes de que lo barra."]},
]

def main():
	s = open(DATOS, encoding='utf8').read()
	D = json.loads(s)
	ks = [e["k"] for e in L]
	assert len(set(ks)) == len(ks) == 17
	assert all(e["q"] != "txomin" for e in L)   # con PLAY no está (npc_cond)
	assert not (set(ks) & set(D["REGALO"])), set(ks) & set(D["REGALO"])
	fk = {f["k"] for f in FIESTAS}
	for e in L:
		assert D["STRAINS"][e["k"]]["tipo"] == "landrace", e["k"]
		assert e.get("fi") is None or e["fi"] in fk
		assert set(e.get("est", [])) <= {"primavera", "verano", "otoño", "invierno"}
		assert set(e.get("cl", [])) <= set(D["TIEMPO"]["k"])
	D["CAZA"] = {"fi": FIESTAS, "l": L}
	t = json.dumps(D, ensure_ascii=False, separators=(',', ':'))
	if t != s:
		open(DATOS, 'w', encoding='utf8').write(t)
	reg = [k for k in D["REGALO"] if D["STRAINS"].get(k, {}).get("tipo") == "landrace"]
	assert "malana" not in ks and "malana" not in reg
	print("caza: %d por estación y gente + %d de REGALO + la Malana del Acto II = %d landraces que se cazan · %d fiestas" % (len(L), len(reg), len(L) + len(reg) + 1, len(FIESTAS)))

main()
