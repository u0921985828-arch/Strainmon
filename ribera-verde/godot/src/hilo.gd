# El cuaderno azul de la tía Maite (lo pidió el usuario: «el juego ya me aburre… igual le falta historia, falta contexto»; solo con
# Datos.CAL): un hilo propio por encima de la deuda, por capítulos y por la gente que la conoció. Kiko lo abre (desde el capítulo 3),
# Delroy cuenta la noche de la Copa del 98, los tres trozos del cuaderno están con Miren, con la serora de la ermita de Mendialde y
# con la abuela Txaro, y juntos dicen dónde enterró la tía su Haze del 98: en la huerta de detrás del garaje. Allí se decide qué
# hacer con la verdad: contarla en la asociación, ir a por Baltasar o guardártela. S.hilo = {p: paso, tr: {trozo: día}, cor: lo que
# te paras con la gente, el: la elección, d: día de cada paso}. Cadena: … → copa → ciudad → hilo → retencion → juego.
extends "res://src/ciudad.gd"

const HILO := {"ch": 3, "semilla": "silver", "n": 5, "lamb": 3, "baltasar": 3000, "vela": 50, "rep": 5, "confia": 15}   # i18n-no
const TROZOS := ["miren", "serora", "txaro"]   # i18n-no
# lo que dice OBJETIVO → LA TÍA MAITE en cada paso: [título, qué hacer]
var HILO_PASOS := [[I18n.K("Un mensaje de Kiko"), I18n.K("Kiko quiere contarte algo de tu tía. Pásate por el growshop de Ribera Verde.")],
	[I18n.K("Un mensaje de Kiko"), I18n.K("Kiko quiere contarte algo de tu tía. Pásate por el growshop de Ribera Verde.")],
	[I18n.K("La noche del 98"), I18n.K("Kiko dice que la noche de la Copa del 98 tu tía estaba con Delroy. Búscalo en la asociación del barrio alto.")],
	[I18n.K("El cuaderno en tres"), I18n.K("La tía partió su cuaderno azul en tres: uno con Miren (Errotabarri), otro en la ermita de Mendialde y otro con la abuela Txaro.")],
	[I18n.K("La lata del manzano"), I18n.K("Los tres trozos dicen lo mismo: «debajo del manzano de la huerta». La huerta de la tía, detrás del garaje del barrio.")],
	[I18n.K("Lo que haces con la verdad"), ""],
	[I18n.K("El cuaderno, cerrado"), I18n.K("Ya sabes lo que pasó en la Copa del 98. Lo que hagas con eso es cosa tuya.")]]

func hilo() -> Dictionary:
	if not (S.get("hilo") is Dictionary):
		S.hilo = {"p": 0, "tr": {}, "cor": 0, "el": -1, "d": {}}
	return S.hilo

func hilo_p() -> int:
	return int(hilo().get("p", 0)) if Datos.CAL else 0

func hilo_paso(p: int) -> void:
	var H := hilo()
	H.p = p
	H.d[str(p)] = int(S.day)

func hilo_visible() -> bool:
	return Datos.CAL and S != null and int(S.get("ch", 0)) >= int(HILO.ch)

func hilo_trozos() -> int:
	return TROZOS.filter(func(t): return hilo().tr.has(t)).size()

# al amanecer (granja.gd): Kiko escribe una vez, desde el capítulo 3
func hilo_dia() -> void:
	if not hilo_visible() or hilo_p() != 0 or not S.flags.get("letter"):
		return
	hilo_paso(1)
	var L := [K("{N}, pásate por la tienda cuando puedas. Tengo que contarte una cosa de tu tía que no te conté al principio.")]
	queue("hilo1", func(): await talk(K("SMS · KIKO"), L), [[K("SMS · KIKO"), L]])   # i18n-no

# al entrar en un mapa (mundo.gd): la lata, en la huerta
func hilo_entra(mapa: String) -> void:
	if Datos.CAL and mapa == "huerta" and hilo_p() == 4:   # i18n-no
		queue("hiloLata", func(): await hilo_lata())   # i18n-no

# npc_talk: si la persona tiene algo del cuaderno, su escena; si no, lo de siempre (false)
func hilo_talk(id: String) -> bool:
	if not hilo_visible():
		return false
	var p := hilo_p()
	match id:
		"kiko":
			if p <= 1:
				await hilo_kiko()
				return true
		"delroy":
			if p == 2:
				await hilo_delroy()
				return true
			if p == 5 and int(hilo().el) == 0:
				await hilo_asociacion()
				return true
		"miren":
			if p == 3 and not hilo().tr.has("miren") and S.flags.get("pagina"):
				await hilo_miren()
				return true
		"bi_serora":
			if p == 3 and not hilo().tr.has("serora"):
				await hilo_serora()
				return true
		"txaro":
			if p == 3 and not hilo().tr.has("txaro") and S.flags.get("txaro"):
				await hilo_txaro()
				return true
		"baltasar":
			if p == 5 and int(hilo().el) == 1:
				await hilo_baltasar()
				return true
	return false

func hilo_kiko() -> void:
	var N := K("KIKO")
	await talk(N, [K("Cierra la puerta, anda."), K("Tu tía tenía dos cuadernos. El diario, que ya tienes, y uno azul que no enseñaba a nadie."),
		K("En el azul apuntaba su planta madre: la Haze con la que se presentó a la Copa del 98. Nunca la metió en la CannaDex."),
		K("Aquella noche pasó algo. Volvió con el segundo premio y no quiso volver a hablar de esa planta. Ni conmigo."),
		K("El que estuvo con ella toda la noche fue Delroy, el de la asociación del barrio alto. Pregúntale a él.")])
	hilo_paso(2)
	await got(K("una pista: «LA NOCHE DEL 98»"))

func hilo_delroy() -> void:
	var N := K("DELROY")
	await talk(N, [K("El cuaderno azul... Kiko no ha tardado en contártelo."), K("La Copa del 98 se jugaba en la plaza. Tu tía llevaba un tarro que olía a limón desde la otra punta."),
		K("Baltasar se presentaba también. Y Toño, el chaval que hoy le guarda la puerta, era el que llevaba los tarros a la mesa del jurado."),
		K("Cuando abrieron el de tu tía, tenía moho. Ese no era su tarro. Yo lo había olido una hora antes."), K("Ganó Baltasar. Ella se quedó segunda y no protestó: sin pruebas, en este barrio, mejor callar."),
		K("Después partió el cuaderno en tres, para que nadie lo tuviera entero."), K("Un trozo se lo dio a Miren, la de Errotabarri. Otro lo subió a la ermita de Mendialde, a la serora."),
		K("Y el tercero se lo dejó a alguien del barrio que casi no sale de casa. Tú sabrás a quién.")])
	confia("delroy", 5)
	hilo_paso(3)
	await got(K("una pista: «EL CUADERNO EN TRES»"))

# los tres trozos, en el orden que quieras; con el tercero, se juntan
func hilo_trozo(t: String) -> void:
	hilo().tr[t] = int(S.day)
	var n := hilo_trozos()
	await got(T("un trozo del cuaderno azul ({n}/3)", {"n": n}))
	if n >= TROZOS.size():
		await talk(K("EL CUADERNO AZUL"), [K("Juntas los tres trozos. La letra apretada de la tía, con manchas de tierra."),
			K("«Haze del 98, fenotipo del limón. Madre: la que trajo Miren de su viaje. La mejor que he tenido.»"),
			K("«Toño cambió mi tarro. Lo vi meterse en el bar de Baltasar con él debajo del brazo. No tengo pruebas, solo esto.»"),
			K("«Las semillas buenas, en la lata de galletas, debajo del manzano de la huerta. Que no las encuentre él.»")])
		hilo_paso(4)
		var L := [K("Si el cuaderno dice lo que creo, ve a la huerta. Y no se lo cuentes a nadie del bar.")]
		queue("hilo4", func(): await talk(K("SMS · DELROY"), L), [[K("SMS · DELROY"), L]])   # i18n-no

func hilo_miren() -> void:
	var N := K("MIREN")
	await talk(N, [K("Delroy me ha llamado. Sabía que vendrías."), K("La madre de esa Haze la traje yo de un viaje, en un bote de carretes de fotos. Tu tía la hizo suya."),
		K("Me dio su trozo del cuaderno la última vez que subió. Me dijo: «Si viene alguien con mis ojos, dáselo».")])
	if await ask(K("¿Te quedas a cenar con Miren?"), [K("Quedarte a cenar"), K("Tienes prisa")], N) == 0:
		hilo().cor = int(hilo().cor) + 1
		await talk(N, [K("Alubias, como cuando subía ella. Hablaba de ti, ¿sabes? Decía que algún día volverías al barrio.")])
	else:
		await say(K("Vete, vete. Ella también iba siempre corriendo."), N)
	await hilo_trozo("miren")

func hilo_serora() -> void:
	var N := K("SERORA")
	var C := ciu()
	C.serora = true
	await talk(N, [K("Tú preguntas por los cuadernos de Maite. Tienes su misma manera de entrar, sin hacer ruido."),
		K("Me dejó un sobre para quien viniera a buscarlo. Y me pidió una cosa: que esa persona encendiera una vela por su hermana, que murió joven.")])
	var vela := int(HILO.vela)
	var op := [T("Encender la vela y dejar {e} en el cepillo", {"e": Datos.eur(vela)}), K("Coger el sobre y ya")]
	if await ask(K("¿Qué haces?"), op, N) == 0:
		if float(S.money) >= vela:
			S.money -= vela
			hilo().cor = int(hilo().cor) + 1
			S.heat = maxf(0.0, float(S.heat) - 5)
			sfx("coin")
			update_hud()
			await say(K("La vela tiembla y se queda quieta. La serora asiente sin decir nada."), N)
		else:
			await say(K("No llevas tanto encima. Enciendes una vela de las de un euro igualmente."), N)
	else:
		await say(K("Ella la habría encendido. Toma, es tuyo."), N)
	await hilo_trozo("serora")

func hilo_txaro() -> void:
	var N := K("ABUELA TXARO")
	await talk(N, [K("Pasa, pasa. Ya sabía yo que tarde o temprano vendrías a por el papel de tu tía."),
		K("Lo tengo en el costurero, debajo de los botones. Ella me dijo: «Txaro, tú no lo enseñes ni al cura»."), K("¿Sabes que esa noche del 98 vino aquí llorando? Nunca la había visto así.")])
	if await ask(K("¿Te tomas un café con ella?"), [K("Tomarte el café"), K("Coger el papel y marcharte")], N) == 0:
		hilo().cor = int(hilo().cor) + 1
		confia("txaro", 5)
		await say(K("Te enseña fotos de las fiestas del barrio. En casi todas sale tu tía, riéndose."), N)
	await hilo_trozo("txaro")

# la lata, al entrar en la huerta con los tres trozos; ahí se decide
func hilo_lata() -> void:
	var sid: String = String(HILO.semilla)
	await talk(K("LA HUERTA"), [K("Al fondo, junto al manzano, la tierra se hunde un poco. Escarbas con las manos."),
		K("Una lata de galletas oxidada. Dentro, envueltas en papel de periódico del 98, semillas y una nota."),
		K("«Si las tienes tú, {N}, haz con esto lo que yo no me atreví. O no hagas nada: también vale. M.»")])
	add_seeds(sid, int(HILO.n))
	await got(T("{n} semillas de {s}, la Haze del 98 de la tía", {"n": int(HILO.n), "s": String(strain(sid).n).to_upper()}))
	var el := -1
	while el < 0:   # sin elegir no se cierra: la lata ya está abierta
		el = await ask(K("¿Qué haces con lo que dice el cuaderno?"), [K("Contarlo en la asociación"), K("Ir a por Baltasar"), K("Guardártelo")])
	hilo().el = el
	hilo_paso(5)
	if el == 2:
		await hilo_fin()
	else:
		await say(K("Delroy estará en la asociación.") if el == 0 else K("Baltasar estará en el bar, como siempre."))

func hilo_asociacion() -> void:
	var N := K("DELROY")
	await talk(N, [K("Así que era verdad. Casi treinta años oliéndomelo."), K("La colgamos aquí, al lado de su foto. Que la lea quien quiera: los socios tienen derecho a saber quién era ella."),
		K("Toma: unas semillas de Jamaica que tu tía me hizo prometer que no vendería nunca.")])
	confia("delroy", int(HILO.confia))
	S.rep = float(S.rep) + int(HILO.rep)
	add_seeds("lamb", int(HILO.lamb))
	await got(T("{n} semillas de {s} y {r} de reputación", {"n": int(HILO.lamb), "s": String(strain("lamb").n).to_upper(), "r": int(HILO.rep)}))
	await hilo_fin()

func hilo_baltasar() -> void:
	var N := K("DON BALTASAR")
	await talk(N, [K("¿Un cuaderno? ¿Casi treinta años después vienes con un cuaderno?"), K("..."),
		K("Toño hizo lo que le dijeron. Y yo gané una copa que no me ha dado más que disgustos."), K("Coge esto. No quiero volver a oír el nombre de tu tía en mi bar.")])
	S.money = float(S.money) + int(HILO.baltasar)
	S.heat = minf(100.0, float(S.heat) + 5)
	sfx("coin")
	update_hud()
	await got(T("{e} en efectivo", {"e": Datos.eur(int(HILO.baltasar))}))
	await hilo_fin()

func hilo_fin() -> void:
	hilo_paso(6)
	var el := int(hilo().el)
	var cor := int(hilo().cor)
	var L := [K("Delroy me ha contado lo del cuaderno. La asociación está llena de gente leyéndolo. Tu tía estaría contenta.") if el == 0 else
		(K("Me han dicho que has ido al bar. Ten cuidado con lo que has cogido: Baltasar no regala nada.") if el == 1 else
		K("Lo que pone el cuaderno se queda contigo. Ella hizo lo mismo casi treinta años. A lo mejor tenía razón."))]
	L.append(K("Y gracias por quedarte con la gente que la quería. Eso ella no lo olvidaba nunca.") if cor >= 2 else K("Planta esas semillas. Es lo que ella habría querido."))
	queue("hilo6", func(): await talk(K("SMS · KIKO"), L), [[K("SMS · KIKO"), L]])   # i18n-no

# OBJETIVO → LA TÍA MAITE: los pasos hechos y el que toca
func hilo_menu() -> void:
	var p := maxi(1, hilo_p())
	var it := []
	for i in range(1, mini(p, 6) + 1):
		var d: String = HILO_PASOS[i][1]
		if i == 3:
			d += "\n" + T("Trozos: {n}/3.", {"n": hilo_trozos()})
		if i == 5:
			d = [K("Has decidido contarlo en la asociación. Habla con Delroy."), K("Has decidido ir a por Baltasar. Está en el bar El Ancla."), K("Has decidido guardártelo.")][maxi(0, int(hilo().el))]
		var hecho: bool = i < p or p == 6
		it.append({"label": HILO_PASOS[i][0], "right": K("HECHO") if hecho else K("AHORA"), "desc": d})
	it.append({"label": K("Volver"), "desc": ""})
	await menu(it, {"cls": "full", "title": K("LA TÍA MAITE"), "desc": true, "initial": maxi(0, it.size() - 2)})

func hilo_derecha() -> String:
	return "%d/6" % mini(6, hilo_p())
