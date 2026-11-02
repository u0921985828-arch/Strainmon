# Landrace Hunters — EL ESQUEJE, la revista mensual de cultivo (lo pidió el usuario: «Molaría que hubiese un periódico del
# cannabis o alguna revista»). Solo Godot, con Datos.CAL. Escribe REVISTA en godot/datos/datos.json:
#  · cab: la cabecera (nombre propio, sin marcas reales), el lema, el precio del número y la suscripción anual;
#  · tec: doce técnicas de cultivo reales, una por número (ciclan). La primera vez que se lee un número, su técnica se aprende
#    y da su efecto, pequeño y con tope (rend, cal, thc, moho, clon); nada de dosis ni de cifras de abono;
#  · tit: los titulares de portada por el nivel de la policía (0-3) y los de la ley y la Copa;
#  · cls: los clasificados: uno por número, con lo que deja de verdad (descuento en la chatarrería, un club que paga más por una
#    variedad ese mes, semillas de la feria);
#  · car: la sección de cartas, cada una propia, sin personas ni marcas reales;
#  · don: dónde se vende (quiosco del Ensanche, los dos growshops, los estancos y el mercado de la Ribera).
# python3 -I tools/revista.py (desde ribera-verde/)
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

CAB = {
	"n": "EL ESQUEJE",
	"sub": "revista mensual de cultivo",
	"pie": "Edita la Federación de Clubs de la Comarca · Redacción en el Ensanche",
	"p": 4.5,            # el número, en el quiosco y en los estancos
	"sus": 45.0,         # suscripción de doce números, en la tienda online; llega al buzón el día 1
	"susn": 12,
	"col": 12,           # números distintos para el logro
}

# Las doce técnicas: nombre, qué hace en el juego (clave y tanto por uno) y el texto de la sección TALLER.
# Topes en revista.gd: rend .15, cal .12, thc .02, moho .25, clon .18.
TEC = [
	{"k": "apical", "n": "La poda apical", "e": "rend", "v": 0.04,
		"t": "Cortar la punta del tallo principal cuando la planta tiene cuatro o cinco pisos de hojas. La planta deja de tirar hacia arriba y reparte la fuerza entre las ramas de abajo: en vez de una cola grande y seis pequeñas, salen cuatro o seis colas parecidas. Se hace en crecimiento y nunca en floración. Con el mismo foco y la misma maceta, se llena más superficie: de aquí sale el cuatro por ciento más de cosecha que verás en tus próximos cortes."},
	{"k": "lavado", "n": "El lavado de raíces", "e": "cal", "v": 0.04,
		"t": "Los últimos días antes de cortar, solo agua. La planta tira de lo que tiene guardado en las hojas y el cogollo sale limpio: ni sabor a abono ni ceniza negra. Se nota en la cata y en lo que te pagan por el lote, no en el peso. Si has abonado fuerte, alarga el lavado; si has llevado la planta justa de comida, con menos días basta."},
	{"k": "defoliado", "n": "El defoliado justo", "e": "moho", "v": 0.10,
		"t": "Quitar las hojas grandes que tapan los cogollos de dentro, y solo esas. Entra aire y entra luz donde antes había sombra y humedad parada: es ahí donde empieza el moho. Dos manos como mucho, una al entrar en floración y otra a mitad, y nunca a una planta tocada o recién trasplantada. No es poda estética: es ventilación."},
	{"k": "trasplante", "n": "El trasplante a tiempo", "e": "rend", "v": 0.03,
		"t": "La raíz que da la vuelta al fondo de la maceta y se queda dando vueltas no vuelve a crecer igual. Se trasplanta cuando las raíces llegan al borde del cepellón y antes de que lo aten: la planta no se para ni un día. Trasplantar tarde cuesta una semana de crecimiento; trasplantar pronto, a una maceta enorme, encharca el sustrato."},
	{"k": "scrog", "n": "La malla horizontal", "e": "rend", "v": 0.05,
		"t": "Una malla a un palmo y medio de la maceta, y las ramas se van metiendo por los cuadros a medida que crecen. Todas las puntas quedan a la misma altura, y a la misma altura del foco: no hay colas quemadas arriba ni cogollos de aire abajo. Se monta en crecimiento, antes de cambiar la luz; después ya no se mueve nada."},
	{"k": "peso", "n": "Riego por peso", "e": "rend", "v": 0.03,
		"t": "Coge la maceta por el borde y levántala. Si pesa como un ladrillo mojado, no toca; si vuela, toca. Se riega por peso, no por días. Con el peso aprendes cuánta agua pide cada planta, y las raíces se hacen a buscar el agua en vez de nadar en ella. La maceta siempre mojada acaba con la raíz ahogada y la planta amarilla."},
	{"k": "tricomas", "n": "Los tricomas al corte", "e": "thc", "v": 0.01,
		"t": "El punto de corte no se mira en el calendario, se mira con una lupa en la resina de los cogollos de arriba: cuando las cabezas pasan de transparentes a blancas lechosas, es el día. Antes, el cogollo pesa menos y pega menos; mucho después, se vuelve pesado y tumba. Dos días de diferencia cambian el efecto de toda la cosecha."},
	{"k": "secado", "n": "El secado lento", "e": "cal", "v": 0.03,
		"t": "El cogollo se seca en una habitación fresca, a oscuras y con el aire moviéndose despacio, nunca con un calefactor ni al sol. Rápido por fuera y verde por dentro es lo que huele a heno. Lento, el cogollo se dobla y el tallo cruje: ese es el que después cura bien en el tarro."},
	{"k": "madres", "n": "Las madres por turnos", "e": "clon", "v": 0.08,
		"t": "Una madre a la que le quitas todos los esquejes el mismo día tarda semanas en volver. Se corta por turnos, de una rama cada vez, y la madre no se para: siempre hay una parte de la planta creciendo mientras la otra se recupera. Y el esqueje se coge de las ramas de abajo, que enraízan antes que las puntas."},
	{"k": "calorfondo", "n": "Calor de fondo para los esquejes", "e": "clon", "v": 0.07,
		"t": "El esqueje no enraíza con calor en las hojas, enraíza con calor en el taco. El propagador templado por abajo y el aire de la habitación fresco: la raíz tira y la hoja no se gasta. Si se ponen mustios el primer día es normal; si se ponen amarillos, les sobra luz. Nada de abono hasta que haya raíz."},
	{"k": "limpieza", "n": "La limpieza entre ciclos", "e": "moho", "v": 0.10,
		"t": "Entre cosecha y cosecha, la carpa se vacía y se limpia: paredes, bandeja, ventiladores, los filos de la cremallera. Las esporas y los bichos del ciclo anterior están ahí esperando a las plantas nuevas, que son las más blandas. Media hora de trapo ahorra un ciclo entero perdido por moho."},
	{"k": "curado", "n": "El curado en tarro", "e": "cal", "v": 0.03,
		"t": "El tarro se llena a tres cuartos, se cierra y se abre un rato cada día los primeros días. Lo que queda de humedad dentro del cogollo se reparte y sale, y lo que olía a verde se convierte en olor a variedad. Es el paso que más cambia el precio y el que más gente se salta por tener prisa."},
]

TIT = {
	"poli": [
		"«Un otoño tranquilo»: la comarca, sin sustos",
		"La policía refuerza las patrullas en los barrios",
		"Investigación abierta por venta de marihuana en la comarca",
		"Un juzgado autoriza registros: qué dice la ley y qué no",
	],
	"ley": [
		"Los clubs piden una ley que ponga orden",
		"KAIA abre en el muelle: un club con dispensario",
		"Licencia para el muelle: la primera distribuidora legal de la comarca",
	],
	"copa": [
		"Se acerca la Copa de otoño: cinco categorías y un jurado nuevo",
		"La Copa de otoño, al detalle: quién ganó y con qué",
	],
	"tia": [
		"Hace años, en esta comarca, una mujer guardaba semillas",
		"El cuaderno azul: la memoria genética de un barrio",
	],
}

CLS = [
	{"k": "chatarra", "n": "Chatarrería de Valdehierro", "t": "«Material de cultivo de segunda mano. Lo que entra esta semana, a mitad. Pregunta por Bixente.»", "ef": "chatarra"},
	{"k": "club", "n": "Clubs de la comarca", "t": "«Se busca género de una variedad concreta para el dispensario del mes. Se paga por encima del precio de siempre.»", "ef": "club"},
	{"k": "feria", "n": "Tablón de la feria", "t": "«Intercambio de semillas de colección. Quien traiga algo de su tierra, se va con algo de otra.»", "ef": "feria"},
	{"k": "curro", "n": "Se busca", "t": "«Hacen falta manos para manicurar. Por días, pagado al terminar. Preguntar en los clubs.»", "ef": ""},
	{"k": "lonja", "n": "Lonja de Puerto Viejo", "t": "«Compra de flor y de extracción al por mayor. Lotes grandes, pago en el día.»", "ef": ""},
	{"k": "grow", "n": "Growshop", "t": "«Liquidación de focos de la temporada pasada. Mientras queden.»", "ef": ""},
]

CAR = [
	"«Llevo tres cosechas con las puntas quemadas y le echaba la culpa al foco. Era el abono. Menos es más.» — Un socio de Mendialde",
	"«Mi vecina me denunció por el olor. Puse un filtro de carbón como es debido y se acabó el problema. No es ilegal oler a nada.» — Un lector del Ensanche",
	"«Después de veinte años, lo mejor que he fumado era una planta de semilla regalada, sin nombre y sin papeles.» — Un jubilado de Errotabarri",
	"«Guardo las semillas en un tarro, en la nevera, con un sobre de los que vienen en las zapatillas. Me han germinado de hace doce años.» — Una socia de Puerto Viejo",
	"«Dejad de perseguir el veinticinco por ciento. Preguntad a quién le gusta lo que cultiváis.» — Un catador",
	"«Las landraces no son una moda: son lo que había antes de que todo oliera igual.» — Un lector del barrio alto",
]

SEC = {   # los títulos de las secciones, en orden
	"port": "PORTADA",
	"vari": "LA VARIEDAD DEL MES",
	"tec": "TALLER",
	"merc": "MERCADO",
	"copa": "LA COPA Y LAS CATAS",
	"cls": "CLASIFICADOS",
	"car": "CARTAS",
	"leg": "LEGAL",
}

DON = ["prensa", "kiko", "ane", "est", "mercado"]   # quiosco, growshop de Kiko, GROW IBARBIDE, estancos, mercado de la Ribera

TOPE = {"rend": 0.15, "cal": 0.12, "thc": 0.02, "moho": 0.25, "clon": 0.18}


def main():
	s = open(DATOS, encoding='utf8').read()
	D = json.loads(s)
	ks = [t["k"] for t in TEC]
	assert len(set(ks)) == len(ks) == 12, ks
	assert all(t["e"] in TOPE for t in TEC)
	for e, tp in TOPE.items():   # ningún efecto puede pasarse de su tope ni con las doce leídas
		assert round(sum(t["v"] for t in TEC if t["e"] == e), 6) <= tp + 1e-9, e
	assert len(set(c["k"] for c in CLS)) == len(CLS)
	assert len(CAR) >= 6
	D["REVISTA"] = {"cab": CAB, "tec": TEC, "tit": TIT, "cls": CLS, "car": CAR, "sec": SEC, "don": DON, "tope": TOPE}
	t = json.dumps(D, ensure_ascii=False, separators=(',', ':'))
	if t != s:
		open(DATOS, 'w', encoding='utf8').write(t)
	print("revista: %s · %d técnicas · %d clasificados · %d cartas · %d sitios donde se vende" % (CAB["n"], len(TEC), len(CLS), len(CAR), len(DON)))


main()
