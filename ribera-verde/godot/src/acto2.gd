# El Acto II, «Quién entró en el piso» (ESTUDIO, tanda 3; lo pidió el usuario: «metas mano a las mejoras que hablamos»; solo con
# Datos.CAL): cerrado el cuaderno azul (hilo.gd, paso 6), la abuela Txaro avisa de que la semana del entierro de la tía vio luz en
# el piso; la rueda de la caja del diploma está forzada. Tres sospechosos —Darko, Unai Garro (un comprador de semillas de Bilbao,
# de Semillas Ondarea) y el sargento Molina— y cinco pistas: el ordenador de la tía, el cura de la catedral, el teatro, Hacienda y
# Koldo en el muelle. Quien te ayuda sale de lo que elegiste con el cuaderno (Delroy, Baltasar o Kiko) y te da una pista; con
# A2.min pistas se acusa delante de él. S.a2 = {p: paso, pi: {pista: día}, acu: a quién acusaste, d: día de cada paso}.
# Cadena: … → kaiacult → salafria → acto2 → retencion → juego.
extends "res://src/salafria.gd"

const A2 := {"min": 4, "rep": 5, "confia": 10, "semilla": "malana", "n": 3, "calor_darko": 10, "calor_molina": 20, "pierde": 5}   # i18n-no
const PISTAS := ["pc", "catedral", "teatro", "hacienda", "muelle"]   # i18n-no
const SOSPECHOSOS := ["darko", "garro", "molina"]   # i18n-no
const CULPABLE := "garro"   # i18n-no
const AYUDA := ["delroy", "baltasar", "kiko"]   # i18n-no · por la elección del cuaderno (hilo().el): asociación, Baltasar, guardártelo
const AYUDA_PISTA := {"delroy": "hacienda", "baltasar": "muelle", "kiko": "pc"}   # i18n-no

var A2_PASOS := [[I18n.K("Luz en el piso"), I18n.K("La abuela Txaro vio luz en el piso de tu tía la semana del entierro. Mira la caja de detrás del diploma.")],
	[I18n.K("Luz en el piso"), I18n.K("La abuela Txaro vio luz en el piso de tu tía la semana del entierro. Mira la caja de detrás del diploma.")],
	[I18n.K("Quién entró en el piso"), ""],
	[I18n.K("El piso, cerrado"), ""]]

func a2() -> Dictionary:
	if not (S.get("a2") is Dictionary):
		S.a2 = {"p": 0, "pi": {}, "acu": "", "d": {}}
	return S.a2

func a2_p() -> int:
	return int(a2().get("p", 0)) if Datos.CAL else 0

func a2_paso(p: int) -> void:
	var A := a2()
	A.p = p
	A.d[str(p)] = int(S.day)

func a2_pistas() -> int:
	return PISTAS.filter(func(t): return a2().pi.has(t)).size()

func a2_ayuda() -> String:
	return AYUDA[clampi(int(hilo().get("el", 2)), 0, 2)]

func a2_ayuda_n() -> String:
	return {"delroy": K("DELROY"), "baltasar": K("DON BALTASAR"), "kiko": K("KIKO")}[a2_ayuda()]

func a2_sospechoso(k: String) -> String:
	return {"darko": K("Darko"), "garro": K("Unai Garro, de Semillas Ondarea"), "molina": K("El sargento Molina")}[k]

# al amanecer: cerrado el cuaderno azul un día antes, Txaro escribe
func hilo_dia() -> void:
	super()
	if not hilo_visible() or hilo_p() < 6 or a2_p() != 0 or int(S.day) <= int(hilo().d.get("6", S.day)):
		return
	a2_paso(1)
	var L := [K("{N}, una cosa que no te he contado. La semana del entierro de tu tía vi luz en su piso de madrugada, dos noches seguidas."),
		K("Tú aún no habías llegado. Y la llave solo la tenía ella. Mira lo de detrás del diploma, que ella ahí guardaba lo suyo.")]
	queue("a2txaro", func(): await talk(K("SMS · ABUELA TXARO"), L), [[K("SMS · ABUELA TXARO"), L]])   # i18n-no

# el diploma: la rueda forzada abre la investigación
func diploma_action():
	if a2_p() == 1:
		await a2_rueda()
	await super()

func a2_rueda() -> void:
	await talk(K("EL DIPLOMA"), [K("Descuelgas el diploma. Alrededor de la rueda de la caja, la pintura está levantada: marcas de destornillador, viejas."),
		K("Alguien intentó abrirla sin la combinación antes de que tú llegaras. No pudo: la caja aguanta. Buscaba algo que la tía guardaba."),
		K("El cuaderno azul. Y por esas fechas solo tres personas preguntaban por él: Darko, un comprador de semillas de Bilbao que le escribía, y el sargento Molina.")])
	a2_paso(2)
	await got(K("una pista: «QUIÉN ENTRÓ EN EL PISO»"))
	var ay := a2_ayuda()
	var pk: String = AYUDA_PISTA[ay]
	a2().pi[pk] = int(S.day)
	var L: Array = {"delroy": [K("Lo de la caja... Te cuento lo único que sé: Molina estuvo esa mañana en Hacienda, en Bilbao. Hice cola detrás de él. Él no fue.")],
		"baltasar": [K("Ya me han contado lo del diploma. A Darko no lo busques: ese día estaba en la mar con Koldo, todo el barrio lo vio salir. No es de los míos, pero eso no.")],
		"kiko": [K("Lo del piso... Tu tía me dijo que le escribía un tío de Bilbao por el ordenador, uno que quería comprarle la Haze. Mira su correo.")]}[ay]
	queue("a2ayuda", func(): await talk(K("SMS · ") + a2_ayuda_n(), L), [[K("SMS · ") + a2_ayuda_n(), L]])   # i18n-no

# las pistas, por la gente; con las que hacen falta, la acusación delante de quien te ayuda
func hilo_talk(id: String) -> bool:
	if a2_p() == 2:
		var pk := ""
		if id.begins_with("bi_cura_") and S.map == "catedral-in":   # i18n-no
			pk = "catedral"
		elif (id.begins_with("bi_taquillera") or id == "bi_ainhoa") and S.map == "teatro-in":   # i18n-no
			pk = "teatro"
		elif id == "bi_funcionaria":   # i18n-no
			pk = "hacienda"
		elif id == "koldo":   # i18n-no
			pk = "muelle"
		if pk != "" and not a2().pi.has(pk) and not ciudad_cerrada():
			await a2_pista(pk, id)
			return true
		if id == a2_ayuda():
			await a2_ayudante()
			return true
	return await super(id)

# el ordenador de la tía: su correo
func pc_action():
	if a2_p() == 2 and not a2().pi.has("pc"):
		await a2_pista("pc")
	await super()

func a2_pista(pk: String, id := "") -> void:
	match pk:
		"pc":
			await talk(K("EL ORDENADOR DE LA TÍA"), [K("En el correo de la tía, un hilo con un tal Unai Garro, de Semillas Ondarea, Bilbao. Dos semanas antes del entierro."),
				K("«Le ofrezco cuarenta mil euros por la madre de su Haze del 98 y sus notas de cría. Es mi última oferta.»"),
				K("La tía contestó una línea: «No está en venta. No vuelva a escribirme.»"),
				K("Y el registro del ordenador dice que alguien lo encendió el día del entierro, a las 11:40, cuando estaba toda la gente en la catedral.")])
		"catedral":
			await talk(K("SACERDOTE"), [K("¿El funeral de Maite? Aquí, a las once. Estaba medio barrio, y llorando."),
				K("Solo me extrañó un señor de traje, de fuera. Me preguntó a qué hora acababa y si la familia volvería luego a casa."),
				K("Se fue antes de la comunión. Dejó una tarjeta en el cepillo, fíjate: «Semillas Ondarea». No volví a verlo.")])
		"teatro":
			await talk(K("AINHOA") if id == "bi_ainhoa" else K("TAQUILLERA"),
				[K("¿Garro? Sí, el de las semillas tiene abono. Cuando vino la policía a preguntar por un robo, dijo que esa mañana estaba aquí, en el ensayo general."),
				K("Ese día no hubo ensayo: el teatro estuvo cerrado toda la semana por la obra del tejado. Aún tengo el cartel en el cajón.")])
		"hacienda":
			await talk(K("FUNCIONARIA"), [K("Esto no se lo puedo enseñar... pero el registro de entrada es público."),
				K("El sargento Molina presentó un recurso aquí ese día. Sello de las 11:20, ventanilla 3. De Bilbao a Ribera Verde hay media hora larga.")])
		"muelle":
			await talk(K("KOLDO"), [K("¿Darko? Ese día salimos juntos a por chipirones a las seis de la mañana y no volvimos hasta la noche, con mala mar."),
				K("Tendrá sus cosas, pero ese día estaba vomitando por la borda de mi txalupa, no en el piso de tu tía.")])
	a2().pi[pk] = int(S.day)
	await got(T("una pista del piso ({n}/{t})", {"n": a2_pistas(), "t": PISTAS.size()}))
	if a2_pistas() >= int(A2.min):
		await say(T("Ya tienes bastante. Habla con {n}.", {"n": a2_ayuda_n().capitalize()}))

func a2_ayudante() -> void:
	var N := a2_ayuda_n()
	if a2_pistas() < int(A2.min):
		await say(T("«Aún no tienes bastante: {n} de {t}. Pregunta en el teatro, en la catedral, en Hacienda, en el muelle y mira el ordenador de tu tía.»", {"n": a2_pistas(), "t": int(A2.min)}), N)
		return
	await talk(N, [K("A ver, cuéntame lo que tienes."), K("Tres nombres y un piso forzado. Piénsalo bien: acusar a alguien en este barrio no se deshace.")])
	var ops := SOSPECHOSOS.map(func(k): return a2_sospechoso(k))
	ops.append(K("Aún no lo tengo claro"))
	var c: int = await ask(K("¿Quién entró en el piso de la tía?"), ops, N)
	if c < 0 or c >= SOSPECHOSOS.size():
		return
	var k: String = SOSPECHOSOS[c]
	a2().acu = k
	a2_paso(3)
	if k == CULPABLE:
		await talk(N, [K("Garro. Quería la Haze y la tía se la negó. Sabía cuándo estaría el piso vacío y mintió con el teatro."),
			K("Lo llamamos juntos. Al tercer tono, cuelga. A la hora, un mensajero trae un sobre sin remite."),
			K("Dentro, el sobre de semillas de Malana que tu tía guardaba en el cajón de la cocina. Es lo único que pudo llevarse.")])
		add_seeds(String(A2.semilla), int(A2.n))
		S.rep = float(S.rep) + int(A2.rep)
		confia(a2_ayuda(), int(A2.confia))
		await got(T("{n} semillas de {s} y {r} de reputación", {"n": int(A2.n), "s": String(strain(String(A2.semilla)).n).to_upper(), "r": int(A2.rep)}))
		var L := [K("Semillas Ondarea sigue preguntando por la Haze de tu tía. Ahora sabe que la tienes tú. Ten cuidado, que esto no se ha acabado.")]
		queue("a2fin", func(): await talk(K("SMS · DELROY"), L), [[K("SMS · DELROY"), L]])   # i18n-no
	else:
		var darko := k == "darko"
		S.heat = minf(100.0, float(S.heat) + int(A2.calor_darko if darko else A2.calor_molina))
		confia(a2_ayuda(), -int(A2.pierde))
		update_hud()
		await talk(N, [K("¿Darko? Ese día estaba en la mar, lo sabe todo el muelle. Se va a enterar de que lo has dicho.") if darko else
			K("¿Molina? Estaba en Hacienda, en Bilbao, con el sello en la mano. Y ahora sabe que lo has acusado tú."),
			K("Lo dicho no se deshace. El que entró sigue por ahí.")])
		var L := [K("Me han dicho que un tal Garro, de Semillas Ondarea, va preguntando por la Haze de tu tía. A lo mejor te equivocaste de nombre.")]
		queue("a2fin", func(): await talk(K("SMS · KIKO"), L), [[K("SMS · KIKO"), L]])   # i18n-no

# OBJETIVO → LA TÍA MAITE: el cuaderno y, después, el Acto II
func hilo_menu() -> void:
	if a2_p() == 0:
		await super()
		return
	var p := a2_p()
	var it := [{"label": HILO_PASOS[6][0], "right": K("HECHO"), "desc": HILO_PASOS[6][1]}]
	for i in range(1, mini(p, 3) + 1):
		var d: String = A2_PASOS[i][1]
		if i == 2:
			d = T("Sospechosos: Darko, Unai Garro (Semillas Ondarea) y el sargento Molina. Pistas: {n}/{t}: el ordenador de la tía, la catedral, el teatro, Hacienda y el muelle. Con {m}, habla con {a}.",
				{"n": a2_pistas(), "t": PISTAS.size(), "m": int(A2.min), "a": a2_ayuda_n().capitalize()})
		if i == 3:
			d = K("Acertaste: fue Garro, de Semillas Ondarea.") if a2().acu == CULPABLE else T("Acusaste a {s}. No fue.", {"s": a2_sospechoso(String(a2().acu))})
		it.append({"label": A2_PASOS[i][0], "right": K("HECHO") if i < p or p == 3 else K("AHORA"), "desc": d})
	it.append({"label": K("Volver"), "desc": ""})
	await menu(it, {"cls": "full", "title": K("LA TÍA MAITE"), "desc": true, "initial": maxi(0, it.size() - 2)})

func hilo_derecha() -> String:
	if a2_p() == 0:
		return super()
	return T("II · {n}/{t}", {"n": mini(a2_pistas(), PISTAS.size()), "t": PISTAS.size()}) if a2_p() < 3 else K("II · HECHO")
