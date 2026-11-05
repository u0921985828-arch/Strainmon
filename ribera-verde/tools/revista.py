# Landrace Hunters — EL ESQUEJE, la revista mensual de cultivo (lo pidió el usuario: «Molaría que hubiese un periódico del
# cannabis o alguna revista»). Solo Godot, con Datos.CAL. Escribe REVISTA en godot/datos/datos.json:
#  · cab: la cabecera (nombre propio, sin marcas reales), el lema, el precio del número y la suscripción anual;
#  · tec: doce técnicas de cultivo reales, una por número (ciclan). La primera vez que se lee un número, su técnica se aprende
#    y da su efecto, pequeño y con tope (rend, cal, thc, moho, clon); nada de dosis ni de cifras de abono;
#  · tit: los titulares de portada por el nivel de la policía (0-3) y los de la ley y la Copa;
#  · cls: los clasificados: uno por número, con lo que deja de verdad (descuento en la chatarrería, un club que paga más por una
#    variedad ese mes, semillas de la feria);
#  · nw: el catálogo de noticias de la comarca, una por suceso de la partida (lo que apunta rev_nota), con su titular;
#  · rel: las noticias de relleno, deducidas del estado, para que el número nunca salga sin noticias;
#  · ag: los textos de la agenda del mes (lo que viene: la Copa, las fiestas, el plazo, los recibos, el tiempo);
#  · car: la sección de cartas, cada una propia, sin personas ni marcas reales;
#  · don: dónde se vende (quiosco del Ensanche, los dos growshops, los estancos y el mercado de la Ribera);
#  · fal, ent, con, tst/tstp, hor, err, anu y pst: la parodia del género (los reclamos de la portada, la entrevista, el
#    consultorio, el banco de pruebas con su publirreportaje, el horóscopo, la fe de errores, los anuncios y el póster central).
# python3 -I tools/revista.py (desde ribera-verde/)
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

CAB = {
	"n": "EL ESQUEJE",
	"sub": "revista mensual de cultivo",
	"lema": "Desde el 98 · Más páginas de anuncios que de cultivo, y aún así la mejor de la comarca",
	"pie": "Edita la Federación de Clubs de la Comarca · Redacción en el Ensanche · Tirada: la que sale · Esta revista la pagan los anuncios de las páginas de al lado · Firma quien quiere y responde quien puede · No se devuelven los originales, entre otras cosas porque nadie los manda",
	"p": 4.5,            # el número, en el quiosco y en los estancos
	"sus": 45.0,         # suscripción de doce números, en la tienda online; llega al buzón el día 1
	"susn": 12,
	"col": 12,           # números distintos para el logro
}

# El sobre de semillas grapado a la hoja (lo pidió el usuario: «molaría también que en cada revista regalen una semilla o algo
# así… como un sobre con una semilla dentro y como un paquetillo de regalo»): cada número trae REG["n"] semillas de una variedad
# del catálogo del banco del PC (nunca de las que se cazan, de receta, de la tía o autoflorecientes: el sobre no abre vías),
# una sola vez por número. El texto de la plana, con el reclamo de siempre de las revistas de quiosco.
REG = {
	"n": 3,
	"t": [
		"Grapado a esta página, como siempre, el sobre del mes. Va una variedad del catálogo, de las que cualquiera puede pedir por correo: no regalamos lo que no se encuentra, que para eso ya está el resto de la revista.",
		"Cortesía de los anunciantes, que para eso pagan. Despega el sobre con cuidado, que el año pasado alguien lo abrió con los dientes y se quedó sin regalo y sin muela.",
		"Un número, un sobre. Quien compre dos ejemplares del mismo mes que no nos escriba: ya nos ha escrito, y le contestamos lo mismo.",
	],
	"ya": "El sobre de este número ya lo despegaste. Queda la marca de la grapa y poco más.",
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
	# el titular de los meses tranquilos, por la estación del número (si no, en junio salía «Un otoño tranquilo»)
	"calma": [
		"«Una primavera tranquila»: la comarca, sin sustos",
		"«Un verano tranquilo»: la comarca, sin sustos",
		"«Un otoño tranquilo»: la comarca, sin sustos",
		"«Un invierno tranquilo»: la comarca, sin sustos",
	],
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
	"nw": "NOTICIAS DE LA COMARCA",
	"mun": "EL MUNDO DEL CANNABIS",
	"ent": "LA ENTREVISTA",
	"vari": "LA VARIEDAD DEL MES",
	"reg": "EL SOBRE DEL MES",
	"tec": "TALLER",
	"pst": "PÓSTER CENTRAL",
	"con": "EL CONSULTORIO",
	"tst": "BANCO DE PRUEBAS",
	"merc": "MERCADO",
	"copa": "LA COPA Y LAS CATAS",
	"ag": "LA AGENDA DEL MES",
	"cls": "CLASIFICADOS",
	"car": "CARTAS",
	"hor": "EL HORÓSCOPO DEL CULTIVADOR",
	"err": "FE DE ERRORES",
	"leg": "LEGAL",
}

DON = ["prensa", "kiko", "ane", "est", "mercado"]   # quiosco, growshop de Kiko, GROW IBARBIDE, estancos, mercado de la Ribera

# Las noticias del cannabis (lo pidió el usuario: «también noticias del cannabis»): la plana de fuera de la comarca, con tres
# breves por número. Todo es ficción del mundo del juego —congresos, ferias, aduanas, cooperativas, museos y bancos de
# semillas inventados—, contada como la cuenta una revista de quiosco. Nada de publicaciones, marcas, bancos, criadores,
# empresas, países con su ley de verdad ni personas reales; nada de método ni de dosis. «e», la estación en que encaja (0 =
# cualquiera, 1 primavera, 2 verano, 3 otoño, 4 invierno); «ch», el capítulo desde el que puede salir.
MUN = [
	{"k": "aduana", "e": 0, "ch": 1, "t": "Una aduana del sur devuelve un envío de semillas por un papel mal puesto",
		"c": "Mil sobres parados tres semanas por una casilla sin rellenar. El envío volvió entero y nadie perdió nada salvo la temporada, que es lo único que no se recupera. Desde la cooperativa que lo mandaba dicen que el formulario cambió en enero y que no se enteró nadie."},
	{"k": "feriaint", "e": 1, "ch": 1, "t": "La feria del norte cierra con más visitas que nunca y menos puestos",
		"c": "Tres pabellones llenos y la mitad de los expositores de hace cinco años. Los que quedan son los de siempre: viveros pequeños, gente que vende macetas y dos cooperativas que traen semilla de su tierra. Lo nuevo este año eran las charlas, que se llenaron antes que los puestos."},
	{"k": "museo", "e": 4, "ch": 2, "t": "Un museo del cultivo abre en una fábrica vieja",
		"c": "Herramienta de hace ochenta años, carteles de propaganda y una sala con las variedades que se cultivaban en el valle antes de que se dejara. Lo monta una asociación de vecinos y lo que se recauda va a mantener el edificio, que se caía."},
	{"k": "coop", "e": 3, "ch": 2, "t": "Una cooperativa de montaña recupera una variedad que se daba por perdida",
		"c": "La tenían tres familias, cada una con su línea, y ninguna sabía de las otras. Juntaron lo que quedaba, lo sembraron el mismo año y salió una planta que se parece bastante a la de las fotos viejas. Ahora buscan quién la cultive para que no dependa de un arcón."},
	{"k": "cong", "e": 3, "ch": 3, "t": "El congreso de genética del otoño se centra en las landraces",
		"c": "Dos días de ponencias sobre lo mismo: que las variedades de origen se están perdiendo más rápido de lo que se catalogan. La conclusión, la de siempre, es que hace falta más gente guardando semilla y menos gente guardándosela."},
	{"k": "precio", "e": 0, "ch": 3, "t": "El precio del kilovatio aprieta a los cultivos de interior de media Europa",
		"c": "Donde se cultiva con luz, la factura ya pesa más que el abono y el agua juntos. Los cultivos grandes se pasan a focos de menos consumo; los pequeños, directamente, a cultivar fuera cuando el clima deja."},
	{"k": "club", "e": 0, "ch": 4, "t": "Las asociaciones de otra comarca pactan un reglamento común",
		"c": "Catorce clubs firman lo mismo: carné, libro de socios, nada de calle y las cuentas a la vista una vez al año. No es ley ni lo pretende, pero en la práctica es lo más parecido que hay a una."},
	{"k": "lab", "e": 0, "ch": 4, "t": "Un laboratorio independiente publica su tabla de analíticas del año",
		"c": "Mil doscientas muestras analizadas y una conclusión incómoda: una de cada cinco no se parecía a lo que ponía en la etiqueta. El laboratorio no da nombres; dice que el problema no es quien miente, sino que casi nadie comprueba."},
	{"k": "mar", "e": 2, "ch": 5, "t": "Una conservera del litoral se mete a distribuidora con licencia",
		"c": "Mismo almacén, mismo frío y la mitad del camión para lo de siempre. Con el permiso en la mano, lo que antes iba de noche va de día y con albarán. En el puerto lo cuentan como una rareza; fuera, como lo que viene."},
	{"k": "semillas", "e": 1, "ch": 5, "t": "Un banco de semillas del este abre su catálogo al público",
		"c": "Cuatrocientas entradas con su ficha, su origen y quién la depositó, consultables por cualquiera. No venden: prestan a quien se compromete a devolver semilla de la cosecha. En seis meses han salido ochenta y han vuelto setenta y seis."},
	{"k": "copa", "e": 3, "ch": 6, "t": "Una copa internacional cambia las reglas tras años de quejas",
		"c": "A partir de este año, cata a ciegas de verdad, muestras recogidas por el jurado y nota del laboratorio aparte de la del paladar. Media sala aplaudió y la otra media se fue a mirar el reglamento."},
	{"k": "ley", "e": 0, "ch": 6, "t": "Un país del norte regula el autocultivo asociado y deja fuera la venta",
		"c": "Plantas contadas por persona, asociaciones con registro y nada de mostrador. Las cooperativas lo leen como un primer paso; los clubs, como un techo. Lo único claro es que ya hay un papel donde antes no había nada."},
	{"k": "robo", "e": 4, "ch": 7, "t": "Roban un banco de semillas y se llevan lo que no se puede reponer",
		"c": "Entraron por el tejado y se llevaron los arcones de una colección de cuarenta años. El seguro cubre el frigorífico. Lo de dentro, no: no hay precio para una semilla de la que no queda otra."},
	{"k": "patente", "e": 0, "ch": 7, "t": "Una empresa retira su solicitud de patente sobre una variedad de origen",
		"c": "La oposición la presentaron tres cooperativas con papeles de hace treinta años. La empresa retiró la solicitud sin dar explicaciones. En el sector se lee como un aviso: lo que no está documentado, alguien lo registra."},
	{"k": "secado", "e": 0, "ch": 8, "t": "Un estudio del sur pone cifras a lo que se pierde en el secado",
		"c": "Midieron cien lotes del mismo cultivo secados de ocho maneras. La diferencia entre el mejor y el peor era de un tercio del valor final. La conclusión del que lo firma: «la cosecha no se acaba cuando se corta»."},
	{"k": "mujeres", "e": 1, "ch": 8, "t": "Una red de cultivadoras publica su primer censo",
		"c": "Trescientas socias en once comarcas, la mitad con cultivo propio y un tercio al frente de una asociación. El censo se hizo porque, cuando preguntaron, nadie tenía el dato."},
]

# Las noticias de la comarca. Cada una va con la clave del suceso que la trae (lo apunta rev_nota al pasar en la partida) y se
# cuenta en el número del mes en que pasó o del siguiente. «t» es el cuerpo y «ti» el titular de portada si es la noticia gorda
# del mes. Nada de nombres reales ni de personas de verdad: la revista habla del barrio y de lo que se ve en la calle.
# {v} es la cifra que apuntó el suceso y {d} el día en que pasó.
NW = [
	{"k": "redada", "p": 9, "ti": "Un registro en el barrio se salda con plantas y material incautados",
		"t": "Agentes entraron el {d} en un piso del barrio con una orden del juzgado y se llevaron las plantas y el equipo que había montado. La asociación recuerda que un registro acaba casi siempre en multa y en la pérdida de todo el ciclo, y que el calor no se baja de un día para otro."},
	{"k": "orden", "p": 8, "ti": "Un juzgado de la comarca autoriza un registro domiciliario",
		"t": "Hay una orden firmada el {d} y no se sabe para cuándo. Desde los clubs piden calma y sentido común: menos movimiento en la calle, nada a la vista y esperar a que el asunto se enfríe."},
	{"k": "copa", "p": 9, "ti": "La Copa de otoño reparte premios en la plaza",
		"t": "El jurado de la plaza falló el {d} sus cinco categorías. Entre los premiados, un cultivador del barrio que subió al podio en {v} categoría(s). Las muestras se cataron a ciegas, como manda la Copa."},
	{"k": "copa6", "p": 8, "ti": "Una muestra del barrio pasa la marca de la Copa",
		"t": "El jurado dio por buena el {d} una muestra que pasa la marca que llevaba años sin moverse. En la mesa de catas se habló de foco, de abono y de paciencia, en ese orden."},
	{"k": "kaia", "p": 9, "ti": "Abre KAIA en el muelle: un club con dispensario para socios",
		"t": "El local del muelle abrió el {d} después de la obra. Tiene dispensario para socios y cocina pequeña, y en el barrio del puerto lo cuentan como la primera cosa nueva en años. A los treinta días de abrir, la ley permite pedir la licencia de distribuidora."},
	{"k": "ley", "p": 10, "ti": "La comarca tiene su primera distribuidora legal",
		"t": "La licencia salió el {d}: hasta cinco kilos al día con papeles, trazabilidad y control de lo que entra y lo que sale. Es el primer permiso de este tipo en la comarca y en los clubs se lee como el principio de algo."},
	{"k": "presi", "p": 7, "ti": "La asociación del barrio alto elige presidencia",
		"t": "La asamblea del {d} salió con un nombre nuevo al frente de la asociación que fundó, hace años, una vecina del barrio. Entre los acuerdos, dispensario para socios y las cuentas a la vista."},
	{"k": "banco", "p": 9, "ti": "Aparece un banco de semillas en el cuarto de atrás de la asociación",
		"t": "Detrás de una puerta que llevaba años cerrada había un banco de semillas con variedades locales de media comarca y de más lejos. La asociación lo abrió el {d} y busca completar las colecciones que faltan."},
	{"k": "bancofin", "p": 10, "ti": "El banco de semillas del barrio, completo",
		"t": "Las seis colecciones quedaron entregadas el {d}. Con la cámara fría, el laboratorio y la sala de catas en marcha, el barrio tiene un sitio donde una variedad no se pierde porque se muera quien la guardaba."},
	{"k": "nave", "p": 7, "ti": "Una nave de Valdehierro cambia de manos",
		"t": "La nave del polígono se escrituró el {d} después de un alquiler con opción a compra. En el polígono dicen que es la primera vez en mucho tiempo que una de esas naves se compra para trabajar y no para dejarla cerrada."},
	{"k": "conce", "p": 5, "ti": "Un concesionario abre en el barrio alto",
		"t": "Abrió el {d} con cuatro modelos en el escaparate, entrega en el día y seguro domiciliado. El barrio alto gana un negocio y pierde un solar, que es como se cuentan aquí estas cosas."},
	{"k": "fi-feria", "p": 6, "ti": "La feria de semillas llena el mercado de la Ribera",
		"t": "Tres días de puestos, intercambios y cosas que no se ven en ningún banco. Quien llevó algo de su tierra se fue con algo de otra, que es de lo que va la feria desde que se hace."},
	{"k": "fi-barrio", "p": 5, "ti": "Las fiestas del barrio, cinco días de calle",
		"t": "Txosnas, partidos y la gente mayor contando lo de siempre. En una esquina, los de la asociación con una mesa y un cartel: «esto no es un negocio, es un vecindario»."},
	{"k": "fi-romeria", "p": 5, "ti": "Romería en la ermita del monte",
		"t": "Un día de monte, de bocadillo y de hablar con quien no ves el resto del año. La serora abrió la ermita y hubo quien se quedó un rato dentro, sentado, sin decir nada."},
	{"k": "rara", "p": 6, "ti": "Un fenotipo raro, cosechado en la comarca",
		"t": "Una planta salió distinta a sus hermanas: porte, olor o resina fuera de lo normal. Lo que se hace en estos casos es guardar sus semillas y repetir la línea hasta que el rasgo se fije, que es la única manera de que no se pierda."},
	{"k": "acusa", "p": 8, "ti": "Un robo en un piso del barrio acaba con un nombre encima de la mesa",
		"t": "Lo que entró a buscar quien forzó la caja no era dinero. Después de semanas de preguntas por la comarca, el {d} se puso un nombre a la cosa. Lo que pase ahora ya no es asunto de esta revista."},
	{"k": "patente", "p": 10, "ti": "Un banco de semillas quiere registrar variedades de la comarca",
		"t": "La solicitud entró y hay oposición presentada. Si pasa, el nombre de unas cuantas variedades que aquí se cultivan desde siempre quedaría en manos de una empresa. En la asociación lo tienen claro: lo que es de todos no se registra."},
	{"k": "mar", "p": 7, "ti": "Vuelve a salir carga del muelle de Puerto Viejo",
		"t": "Un pesquero amarrado en el muelle viejo zarpó el {d} con la bodega hecha. Los del muelle no dicen nada y la conservera tampoco. Hace años que no se veía movimiento ahí."},
	{"k": "embargo", "p": 7, "ti": "Un embargo se lleva el equipo de un cultivo del barrio",
		"t": "Vino con papel y se fue con la carpa grande. La asociación insiste en lo de siempre: los plazos se pagan antes de ampliar, y quien presta a este tipo de interés no está haciendo un favor a nadie."},
	{"k": "huerta", "p": 5, "ti": "Vuelve a trabajarse una huerta abandonada detrás del garaje",
		"t": "Llevaba años con la cancilla cerrada y la hierba por la cintura. Ahora tiene bancales hechos y plantas al aire libre, que es como se cultivaba aquí antes de que todo fuera de interior."},
	{"k": "metro", "p": 6, "ti": "La ciudad de la autopista mira a la comarca",
		"t": "Clubs grandes, dinero y gente con tarjeta. De la comarca sale género para allí y de allí vienen preguntas que aquí no se hacían. Cada uno que saque sus cuentas."},
]

# Las noticias de relleno: se deducen del estado de la partida y entran si el mes no trae suceso. «k» la mira rev_relleno.
REL = [
	{"k": "clima", "t": "El mes viene {c}: {x}. Los de las carpas, ojo a la humedad; los de fuera, a lo que caiga."},
	{"k": "poli", "t": "La calle, {p}. Esta revista no da consejos legales, pero sí recuerda que el género encima pesa más de lo que parece."},
	{"k": "dex", "t": "En la comarca hay {n} variedades registradas con nombre y linaje. Cada una que se apunta es una que no se pierde."},
	{"k": "obras", "t": "Siguen las obras del muelle viejo: pantalán, dique y los bajos de las casas. Quien tenga algo que mover por mar, que espere a que acaben."},
	{"k": "clubs", "t": "Los clubs de la comarca mantienen el dispensario abierto para socios, con lo que entra de los cultivos de cada uno. Nada de calle."},
	{"k": "lonja", "t": "La lonja de Puerto Viejo sigue comprando flor y extracción al por mayor. Lotes grandes y pago en el día, como siempre."},
	{"k": "mercado", "t": "El puesto de semillas del mercado de la Ribera cambia el género cada semana. Merece la pena pasarse aunque no se compre."},
]

# La agenda del mes: lo que viene, por el calendario. Los huecos los rellena rev_agenda.
AG = {
	"copa": "Copa de otoño: el {d}, en la plaza, con sus cinco categorías.",
	"fiesta": "{n}: del {d}, {q} día(s).",
	"plazo": "Vence un plazo de la deuda el {d}.",
	"recibo": "Toca recibo: luz, alquileres y seguros.",
	"nave": "Los siete primeros días del mes, ventana para comprar la nave a tocateja.",
	"num": "El próximo número, el día 1. Si estás suscrito, al buzón.",
	"nada": "Mes tranquilo: ni Copa, ni fiestas, ni plazos. Buen momento para montar un ciclo largo.",
}

# ---------- la parodia del género: lo que trae cualquier revista de cultivo de quiosco ----------
# (lo pidió el usuario: que EL ESQUEJE sea una parodia de las revistas de cultivo). Todo propio: ni cabeceras, ni lemas, ni
# nombres de publicaciones de verdad; los anunciantes son los negocios del juego y los entrevistados, su gente. Se parodia el
# género —el faldón de portada que promete de todo, la entrevista al que se cree una leyenda, el consultorio que acaba
# recomendando lo que vende el anunciante, el banco de pruebas donde nada baja del nueve, el póster central, el horóscopo y la
# fe de errores— y nunca a nadie en concreto.

# el reclamo de la portada: uno por número, debajo del titular (el hueco de la portada da para uno, y en el género tampoco
# dicen mucho más)
FAL = [
	"REGALO: PÓSTER CENTRAL",
	"LA ENTREVISTA DEL MES",
	"EL CONSULTORIO, EN SU SITIO",
	"BANCO DE PRUEBAS: NOTA 9,4",
	"MÁS PÁGINAS QUE EL MES PASADO",
	"EL HORÓSCOPO DEL CULTIVADOR",
	"SORTEO* (*letra pequeña)",
	"LA FE DE ERRORES DE SIEMPRE",
]

# la entrevista del mes: el entrevistado, su oficio y tres preguntas. El tono, el del género: la pregunta grandilocuente y la
# respuesta a ras de suelo.
ENT = [
	{"n": "Kiko", "o": "growshop del barrio", "q": [
		["¿Qué ha cambiado en treinta años detrás del mostrador?", "Los focos. Lo demás lo sigue preguntando la misma gente: si riego poco o riego mucho. Riegas mucho."],
		["Se habla de usted como de una institución.", "Se habla de mí porque llevo la tienda que hay. Si hubiera dos, hablarían de la otra."],
		["Un consejo para quien empieza.", "Una planta. Una. Y la cosechas antes de comprar la segunda carpa."]]},
	{"n": "Delroy", "o": "socio fundador de la asociación", "q": [
		["Usted estuvo en los años en los que aquí no había nada.", "Había gente. Lo que no había era local, ni papeles, ni esta revista. Lo demás es lo mismo: semillas que alguien guarda y alguien pierde."],
		["¿Se cultivaba mejor antes?", "Se cultivaba peor y se disfrutaba igual. El que diga lo contrario no estaba."],
		["¿Y la genética de entonces?", "La que se guardó, está. La que no, no vuelve. Por eso se guarda."]]},
	{"n": "Bixente", "o": "chatarrería de Valdehierro", "q": [
		["¿Qué es lo que más le llega?", "Carpas de dos metros montadas una vez. La gente compra el equipo de su tercera cosecha antes de la primera."],
		["¿Se puede cultivar con material de segunda mano?", "Se puede cultivar con medio material de segunda mano. El extractor y el foco, nuevos; lo demás me lo compras a mí."],
		["¿La pieza más rara que ha pasado por aquí?", "Un filtro de carbón con la tierra dentro. Alguien lo usó de maceta."]]},
	{"n": "Begoña", "o": "jardinera, veinte años de oficio", "q": [
		["¿Las plantas de interior son jardinería?", "Son jardinería con la luz pagada. Lo que cambia es la factura, no la planta."],
		["Se le pide mucho el riego automático.", "Porque nadie quiere levantar la maceta. Levanta la maceta."],
		["¿El error que más ve?", "El abono como premio. La planta no se porta mejor porque le des más de comer."]]},
	{"n": "Arrieta", "o": "naves del polígono", "q": [
		["¿Por qué se alquilan tan baratas?", "Porque llevan diez años cerradas y el tejado se cae solo. Barato es lo que cuesta antes de la obra."],
		["¿Y la opción a compra?", "Es la única forma de que alguien haga la obra. Nadie arregla lo que no va a ser suyo."],
		["¿Qué pide a un inquilino?", "Que pague y que no me traiga a nadie que haga ruido. En ese orden."]]},
	{"n": "Andoni", "o": "molino de Errotabarri", "q": [
		["Aquí se cambia una cosa por otra.", "Aquí se cambia lo que sobra por lo que falta, que es lo que se hacía antes del dinero y lo que se hará después."],
		["¿Qué le traen?", "Semillas de gente que se va. Las guardo y las vuelvo a dar. No es un banco: es un cajón."],
		["¿Nunca se queda nada?", "Lo que no reclaman en dos años. Y eso también lo acabo dando."]]},
	{"n": "Iñaki", "o": "extracciones, al por mayor", "q": [
		["¿Cuánta flor hace falta para que salga a cuenta?", "Más de la que la gente cree. El que extrae su única planta se queda sin planta y sin extracción."],
		["¿Se nota el material de partida?", "Se nota todo. Lo malo, extraído, sigue siendo malo y además concentrado."],
		["¿La máquina lo arregla?", "La máquina no arregla nada. Ordena lo que ya había."]]},
	{"n": "La serora", "o": "ermita del monte", "q": [
		["No es lo habitual entrevistar a una serora en una revista de cultivo.", "Ni a mí me lo habían pedido. Aquí sube gente a sentarse y a no decir nada. Eso también es cuidar algo."],
		["¿Qué le cuentan?", "Lo que no cuentan en el bar. Y no se lo voy a contar yo a ustedes."],
		["¿Qué pide a quien suba?", "Que cierre la puerta al salir. Lo demás, cada uno."]]},
]

# el consultorio: la pregunta del lector y la respuesta del técnico, con el remate del género (el consejo bueno y, de paso, el
# producto del anunciante de la página de al lado)
CON = [
	{"p": "«Tengo las puntas amarillas desde la segunda semana. ¿Le falta hierro?»",
		"r": "Le sobra abono. Baja la mitad y riega dos veces con agua sola. Si en una semana no mejora, mira el pH antes de comprar nada. Medidores, en la página de al lado."},
	{"p": "«Mi carpa huele a tres calles de distancia. ¿Un ambientador?»",
		"r": "Un filtro de carbón del tamaño del extractor, y el extractor sacando aire, no metiéndolo. El ambientador tapa el olor a planta con olor a ambientador y planta. Filtros, en la página de al lado."},
	{"p": "«Me han regalado un esqueje sin nombre. ¿Puedo saber qué es?»",
		"r": "No. Puedes saber cómo se porta en tu carpa, que es lo que importa. Apúntale un nombre tuyo y la fecha, y así en la tercera cosecha sabrás más que el que te lo dio."},
	{"p": "«¿Cuántos días de floración tiene mi planta?»",
		"r": "Los que diga la planta. El calendario lo pone el que vende la semilla; el punto de corte, la lupa. Lupas, en la página de al lado."},
	{"p": "«Se me han quedado los cogollos con sabor raro, como a abono.»",
		"r": "Falta de lavado y prisa al secar. El año que viene, agua sola los últimos días y la habitación fresca. No hay nada que comprar para arreglar esto, y mira que lo hemos buscado."},
	{"p": "«Mi vecino dice que mi cultivo le va a subir la luz.»",
		"r": "No funciona así, pero tampoco hace falta discutirlo con él. Lo que sí le llega es el olor y el ruido: arregla eso y el vecino se le olvida el resto."},
	{"p": "«¿Merece la pena la hidroponía en casa?»",
		"r": "Si se te muere una planta en tierra, no. La hidroponía no perdona el despiste; la tierra sí, y encima te aguanta un fin de semana fuera."},
	{"p": "«Llevo cuatro cosechas y cada vez saco menos.»",
		"r": "Limpia la carpa entre ciclos, cambia el sustrato y mira los años que tiene el foco. Lo que no se ve gastándose es lo que te está comiendo la cosecha."},
]

# el banco de pruebas: nunca baja del nueve, y el pie lo explica. Aparatos del juego, sin marcas de verdad.
TST = [
	{"n": "Extractor de 125 con filtro", "no": "9,4", "t": "Mueve el aire de una carpa de uno veinte sin despeinarse y, con el filtro puesto, el pasillo no huele a nada. Ruido, el justo para que tu vecino no pregunte. Lo probamos tres semanas y seguimos sin tener nada malo que decir."},
	{"n": "Foco LED de 480 W", "no": "9,6", "t": "Llena un metro cuadrado de luz hasta las esquinas y la carpa sube dos grados, no ocho. Lo colgamos de dos poleas, lo subimos con la planta y no nos dio ni un disgusto. Caro, eso sí: lo pone hasta el fabricante."},
	{"n": "Medidor de pH y EC", "no": "9,2", "t": "Dos botones y una pantalla. Si lo calibras cuando toca, te ahorra tres cosechas de discusiones de bar sobre si el agua de aquí es dura. Nos lo mandaron y nos lo quedamos."},
	{"n": "Maceta de tela de 35 litros", "no": "9,5", "t": "Respira, no encharca y la raíz no da vueltas en el fondo. Se dobla y se guarda, que para quien tiene tres carpas y un armario es media mudanza menos. Lavar, a mano."},
	{"n": "Propagador con calor de fondo", "no": "9,3", "t": "El taco templado y la hoja fresca, que es como enraíza un esqueje. Nos sacó adelante dos bandejas de las que no esperábamos nada. El termostato, justo pero suficiente."},
	{"n": "Prensa de rosin de mano", "no": "9,1", "t": "Dos placas, un volante y el papel de cocina. Hace lo que promete con lo que le pongas, y lo que le pongas es exactamente lo que vas a probar: no hay máquina que arregle una flor mala."},
]
TST_PIE = "Publirreportaje: el aparato lo manda quien lo vende y aquí no lo devolvemos. Si alguna vez leen un cinco en esta sección, será que ese mes nadie se anunció."

# el horóscopo del cultivador: uno por mes del calendario, en el tono de siempre
HOR = [
	"Enero: el frío te va a enseñar dónde entra el aire en tu carpa. Marte está en el radiador y el radiador está apagado.",
	"Febrero: mes de decisiones. La tuya será comprar algo que no te hace falta. Evita los catálogos y a los amigos con opinión.",
	"Marzo: buen momento para sembrar y malo para contárselo a nadie. Las estrellas no hablan; tú tampoco.",
	"Abril: la humedad te acecha. Si abres la carpa y huele a bodega, no es nostalgia, es moho.",
	"Mayo: te cruzarás con alguien que tiene semillas de un sitio con nombre impronunciable. Acepta el intercambio.",
	"Junio: Venus en la terraza. Las plantas de fuera van a crecer más que tu paciencia.",
	"Julio: calor. Mucho calor. Las estrellas recomiendan un ventilador y bajar el foco de potencia, no de altura.",
	"Agosto: alguien te va a pedir «un poquito». Las estrellas no se pronuncian, pero nosotros sí: pésalo.",
	"Septiembre: mes de cosecha y de vecinos de vuelta. Revisa el filtro antes que el calendario.",
	"Octubre: Júpiter entra en la Copa. Presenta algo, aunque no ganes: en la mesa de catas se aprende más que en seis números de esta revista.",
	"Noviembre: los tarros te llaman. Ábrelos un rato al día y no mires más, que el curado no se mira, se espera.",
	"Diciembre: balance. Saldrán las cuentas o no, pero saldrá el año. Apunta lo que funcionó, que en marzo no te vas a acordar.",
]

# la fe de errores del número anterior: el chiste que toda revista del género tiene y nunca aprende
ERR = [
	"En el número anterior, donde decíamos «cuatro semanas de floración» debía decir «catorce». Pedimos perdón a quien cortó.",
	"En el número anterior publicamos el teléfono de la redacción en el anuncio de la chatarrería. Gracias a los doce lectores que llamaron preguntando por un extractor.",
	"En el número anterior, la foto del taller no era de un trasplante, era de alguien sacando una planta muerta. El pie era correcto igualmente.",
	"En el número anterior dijimos que la variedad del mes era de la comarca. Es de un sitio a nueve mil kilómetros. Lo sentimos, y la planta también.",
	"En el número anterior se colaron dos veces las mismas cartas. Nos las volvieron a mandar y nos hizo gracia la coincidencia.",
	"En el número anterior, el horóscopo de agosto salió en la página de legal. Hubo quien lo leyó como una sentencia y, visto lo visto, acertó.",
]

# los anuncios: el faldón del pie de plana. Negocios del juego, nada de marcas de verdad. Lo pidió el usuario: «molaría hacer
# banners de publicidad, no que sean solo texto, publicidad de Kiko por ejemplo, de algún Club, de la discoteca Gaua también
# por ejemplo, comercios locales» → cada anunciante lleva su banner dibujado, «b», que es la pieza ban-<b> de arte/revista.png
# (104 × 56, del generador de sprites por tools/sprites/sprgen_revista.py). Sin una sola letra en el dibujo: el texto lo pone
# el juego debajo, en el idioma que toque.
ANU = [
	{"n": "GROWSHOP DE KIKO", "b": "kiko", "t": "«Todo para tu cultivo y una charla gratis»", "pie": "Barrio de siempre. Abierto desde antes de que esto se llamara así."},
	{"n": "GROW IBARBIDE", "b": "ibar", "t": "«Lo último, y un diez por ciento menos»", "pie": "Ensanche. No preguntes por el callejón de detrás."},
	{"n": "CHATARRERÍA DE VALDEHIERRO", "b": "chatarra", "t": "«Tu equipo de hace dos años»", "pie": "Lo que entra esta semana, a mitad. Pregunta por Bixente."},
	{"n": "LONJA DE PUERTO VIEJO", "b": "lonja", "t": "«Compramos al por mayor. Pago en el día»", "pie": "Lotes grandes. No bajamos al muelle a mirar cien gramos."},
	{"n": "MOLINO DE ERROTABARRI", "b": "molino", "t": "«Trae lo que te sobra. Llévate lo que te falta»", "pie": "Sin dinero por medio. Sin excepciones."},
	{"n": "ESTANCOS DE LA COMARCA", "b": "estanco", "t": "«Papel, mechero y esta revista»", "pie": "Mira el rótulo de la T. Si no hay T, no hay revista."},
	{"n": "AUTOS RIBERA", "b": "autos", "t": "«Del scooter al deportivo. Entrega en el día»", "pie": "Financiación, seguro y la primera revisión. Barrio alto."},
	{"n": "FEDERACIÓN DE CLUBS", "b": "feder", "t": "«Hazte socio de tu club»", "pie": "Esta revista la edita quien se anuncia aquí."},
	{"n": "CLUB ITSASO", "b": "club", "t": "«Socios desde el 94. Sofá, billar y dispensario»", "pie": "Puerto Viejo. Carné en la puerta y el encargado te enseña la casa."},
	{"n": "GAUA", "b": "gaua", "t": "«De once a seis. El reservado, para quien lo pida»", "pie": "Ensanche. Entrada por noche. Lo de dentro no sale en la revista."},
]

# El capítulo desde el que cada uno existe en la partida (ataque de la revisión: el número 1 no puede entrevistar a quien aún no
# has visto ni anunciar un negocio que abre en el capítulo 5). «f», además, el aviso de S.flags que tiene que estar puesto.
# Lo filtra rev_ent/rev_anu con el estado; Kiko, los estancos y la Federación están desde el principio, así que nunca se queda
# el número sin entrevista ni sin anuncios.
ENT_CH = {"Kiko": 1, "Delroy": 4, "Bixente": 2, "Begoña": 3, "Arrieta": 3, "Andoni": 3, "Iñaki": 2, "La serora": 2}
ANU_CH = {
	"GROWSHOP DE KIKO": (1, ""), "GROW IBARBIDE": (4, ""), "CHATARRERÍA DE VALDEHIERRO": (2, ""),
	"LONJA DE PUERTO VIEJO": (2, ""), "MOLINO DE ERROTABARRI": (3, ""), "ESTANCOS DE LA COMARCA": (1, ""),
	"AUTOS RIBERA": (5, "conce"), "FEDERACIÓN DE CLUBS": (1, ""),
	"CLUB ITSASO": (2, ""), "GAUA": (4, ""),
}
for _e in ENT:
	_e["ch"] = ENT_CH[_e["n"]]
for _a in ANU:
	_a["ch"], _a["f"] = ANU_CH[_a["n"]]

# el póster central: la plana de la grapa, con la variedad del mes a toda página
PST = {
	"cab": "PÓSTER CENTRAL · PARA LA PUERTA DE LA CARPA",
	"pie": "Arranca por la grapa con cuidado. Si lo rompes, el mes que viene hay otro.",
}

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
	nk = [w["k"] for w in NW]
	assert len(set(nk)) == len(nk), nk
	assert all(len(w["t"]) > 120 and w["ti"] for w in NW), "noticia corta"
	assert len(set(r["k"] for r in REL)) == len(REL)
	assert len(REL) >= 5 and len(NW) >= 18
	assert len(HOR) == 12, "un horóscopo por mes"
	assert len(set(e["n"] for e in ENT)) == len(ENT) >= 6
	assert all(len(e["q"]) == 3 and all(len(x) == 2 for x in e["q"]) for e in ENT), "tres preguntas por entrevista"
	assert len(CON) >= 6 and all(c["p"].startswith("«") and c["r"] for c in CON)
	assert len(TST) >= 5 and all(t["no"][0] == "9" for t in TST), "en el banco de pruebas nada baja del nueve"
	assert len(ERR) >= 5 and len(FAL) >= 6 and len(ANU) >= 6
	assert all(len(f) <= 30 for f in FAL), "el reclamo de la portada tiene que caber en una línea"
	assert len(set(a["n"] for a in ANU)) == len(ANU)
	# desde el primer número tiene que haber entrevista y dos anuncios distintos (rev_ent/rev_anu filtran por capítulo)
	assert all(1 <= e["ch"] <= 8 for e in ENT) and any(e["ch"] == 1 for e in ENT)
	assert all(1 <= a["ch"] <= 8 for a in ANU) and sum(1 for a in ANU if a["ch"] == 1 and not a["f"]) >= 2
	assert all(len(a["n"]) + len(a["t"]) + len(a["pie"]) <= 150 for a in ANU), "el anuncio va a toda plana: tiene que caber"
	assert all(a.get("b") for a in ANU) and len(set(a["b"] for a in ANU)) == len(ANU), "cada anunciante, con su banner"
	# las noticias del cannabis: tres por número desde el primero, así que tiene que haber de sobra del capítulo 1
	assert len(MUN) >= 12 and len(set(m["k"] for m in MUN)) == len(MUN)
	assert all(1 <= m["ch"] <= 8 and 0 <= m["e"] <= 4 and m["t"] and m["c"] for m in MUN)
	assert sum(1 for m in MUN if m["ch"] == 1) >= 2
	assert REG["n"] >= 1 and len(REG["t"]) >= 2 and REG["ya"] and "reg" in SEC
	D["REVISTA"] = {"cab": CAB, "tec": TEC, "tit": TIT, "cls": CLS, "car": CAR, "sec": SEC, "don": DON, "tope": TOPE, "reg": REG,
		"nw": NW, "mun": MUN, "rel": REL, "ag": AG,
		"fal": FAL, "ent": ENT, "con": CON, "tst": TST, "tstp": TST_PIE, "hor": HOR, "err": ERR, "anu": ANU, "pst": PST}
	t = json.dumps(D, ensure_ascii=False, separators=(',', ':'))
	if t != s:
		open(DATOS, 'w', encoding='utf8').write(t)
	print("revista: %s · %d técnicas · %d noticias · %d de relleno · %d clasificados · %d cartas · %d sitios donde se vende" % (CAB["n"], len(TEC), len(NW), len(REL), len(CLS), len(CAR), len(DON)))
	print("  mundo: %d noticias del cannabis" % len(MUN))
	print("  parodia: %d entrevistas · %d consultorios · %d pruebas · %d horóscopos · %d erratas · %d anuncios · %d reclamos" % (len(ENT), len(CON), len(TST), len(HOR), len(ERR), len(ANU), len(FAL)))


main()
