# Los Actos III y IV (ESTUDIO, tanda 6; lo pidió el usuario: «metas mano a las mejoras que hablamos»; solo con Datos.CAL).
# III, «La patente de la Haze»: cerrado el Acto II, Semillas Ondarea pide registrar como suyas la Haze del 98 y landraces del banco
# de la tía. Hay A3.plazo días para oponerse desde el ordenador de la tía, con pruebas que salen de lo que has hecho: el cuaderno
# azul, la Haze del 98 fijada (la genética), el banco de la tía con colecciones entregadas, el correo de Garro (si le acusaste en el
# Acto II) y la firma de la asamblea (si contaste lo del cuaderno en la asociación). Con A3.min, la oficina deniega el registro.
# IV, «Lo que queda de la tía»: Garro llama con su oferta y los finales los decide la genética: abrir el banco (completo), vender a
# Ondarea, irte con Miren con la Haze fijada o, perdida la oposición y sin ceder, la caída. Quien te acompaña es quien te ayudó.
# S.a3 = {p: paso, d: {paso: día}, pr: pruebas presentadas, gan: 1 ganada, fin: el final, ll: día de la última llamada}.
# Cadena: … → acto2 → caza → copaot → acto3 → retencion → juego.
extends "res://src/copaot.gd"

const A3 := {"ch": 7, "plazo": 30, "dias": 7, "min": 3, "llamada": 7, "banco": 3, "miren": 30, "rep": 10, "prest": 3,   # i18n-no
	"venta": [250000, 60000], "pierde": 15, "calor": 30, "haze": "silver"}   # i18n-no
const PRUEBAS3 := ["cuaderno", "fijada", "banco", "correo", "asamblea"]   # i18n-no
const FINALES := ["banco", "vender", "miren", "caida"]   # i18n-no

var A3_PASOS := [["", ""], [I18n.K("La patente de la Haze"), ""], [I18n.K("La oposición, presentada"), ""], [I18n.K("La resolución"), ""],
	[I18n.K("Lo que queda de la tía"), ""]]

func a3() -> Dictionary:
	if not (S.get("a3") is Dictionary):
		S.a3 = {"p": 0, "d": {}, "pr": [], "gan": 0, "fin": ""}
	return S.a3

func a3_p() -> int:
	return int(a3().get("p", 0)) if Datos.CAL else 0

func a3_paso(p: int) -> void:
	var A := a3()
	A.p = p
	A.d[str(p)] = int(S.day)

func a3_dia(p: int) -> int:
	return int(a3().d.get(str(p), S.day))

func a3_fijada() -> bool:
	return S.disc.get(String(A3.haze)) and Cultivo.gen_de(S, String(A3.haze)) >= int(D.GEN_ESTABLE)

# las pruebas que tienes hoy
func a3_pruebas() -> Array:
	var r := []
	for k in PRUEBAS3:
		var ok := false
		match k:
			"cuaderno":
				ok = hilo_p() >= 6
			"fijada":
				ok = a3_fijada()
			"banco":
				ok = bt_n() >= int(A3.banco)
			"correo":
				ok = String(a2().get("acu", "")) == CULPABLE
			"asamblea":
				ok = int(hilo().get("el", 2)) == 0
		if ok:
			r.append(k)
	return r

func a3_prueba_n(k: String) -> String:
	return {"cuaderno": K("El cuaderno azul de 1998, con las notas de cría de la tía"),
		"fijada": T("La Haze del 98 fijada en F{g}: la línea es estable y es vuestra", {"g": int(D.GEN_ESTABLE)}),
		"banco": T("El banco de la tía con {n} colecciones entregadas: las landraces eran de todos", {"n": int(A3.banco)}),
		"correo": K("El correo de Garro ofreciendo dinero por la Haze: sabía que no era suya"),
		"asamblea": K("La firma de la asamblea de la asociación")}[k]

# al amanecer: el aviso de Delroy, la resolución y las llamadas de Garro
func hilo_dia() -> void:
	super()
	if not Datos.CAL or a2_p() < 3:
		return
	var p := a3_p()
	if p == 0:
		if int(S.ch) >= int(A3.ch) and int(S.day) > int(a2().d.get("3", S.day)):
			a3_paso(1)
			var L := [K("Malas noticias. Semillas Ondarea ha pedido en la Oficina de Variedades Vegetales registrar como suyas la «Haze 98» y tres landraces del banco de tu tía."),
				T("Si se lo dan, nadie podrá vender ni regalar esas semillas con su nombre. Hay plazo para oponerse hasta el {f}, desde el ordenador de tu tía. Hacen falta pruebas.", {"f": Datos.fd(a3_dia(1) + int(A3.plazo), S.day)})]
			queue("a3aviso", func(): await talk(K("SMS · DELROY"), L), [[K("SMS · DELROY"), L]])   # i18n-no
	elif p == 1 and int(S.day) > a3_dia(1) + int(A3.plazo):
		a3_resuelve(false)
	elif p == 2 and int(S.day) >= a3_dia(2) + int(A3.dias):
		a3_resuelve(a3().pr.size() >= int(A3.min))
	elif p == 3 and a3().fin == "" and int(S.day) > a3_dia(3) and int(S.day) >= int(a3().get("ll", -100)) + int(A3.llamada):
		queue("a3garro", a3_llamada)

func a3_resuelve(gana: bool) -> void:
	a3().gan = 1 if gana else 0
	a3_paso(3)
	var L := [K("La oficina ha denegado el registro de Ondarea: la Haze del 98 y esas landraces existían antes que ellos, y eran de todos. Lo ha firmado esta mañana."),
		K("Garro no se va a quedar quieto. Te llamará.")] if gana else [K("La oficina ha concedido el registro a Semillas Ondarea. Sin pruebas, la Haze del 98 es suya en los papeles."),
		K("No puedes vender ni regalar sus semillas con ese nombre. Garro te va a llamar, y ahora tiene la sartén por el mango.")]
	queue("a3res", func(): await talk(K("SMS · DELROY"), L), [[K("SMS · DELROY"), L]])   # i18n-no

# el ordenador de la tía: la oposición, con las pruebas que tengas
func pc_action():
	if a3_p() == 1:
		await a3_oposicion()
	await super()

func a3_oposicion() -> void:
	var pr := a3_pruebas()
	var l := []
	for k in PRUEBAS3:
		l.append(("✓ " if pr.has(k) else "· ") + a3_prueba_n(k))
	await talk(K("EL ORDENADOR DE LA TÍA"), [K("La sede electrónica de la Oficina de Variedades Vegetales. Expediente de Semillas Ondarea: «Haze 98» y tres landraces."),
		T("Plazo de oposición hasta el {f}. Lo que puedes adjuntar hoy:", {"f": Datos.fd(a3_dia(1) + int(A3.plazo), S.day)}) + "\n" + "\n".join(l),
		T("Con {m} pruebas, la oposición se sostiene. Tienes {n}.", {"m": int(A3.min), "n": pr.size()})])
	if await ask(K("¿Presentas la oposición?"), [K("Presentarla ahora"), K("Todavía no")], K("EL ORDENADOR DE LA TÍA")) != 0:
		return
	a3().pr = pr
	a3_paso(2)
	sfx("coin")
	await got(T("la oposición, presentada con {n} pruebas: la resolución, el {f}", {"n": pr.size(), "f": Datos.fd(a3_dia(2) + int(A3.dias), S.day)}))

# la llamada de Garro: la oferta y los finales
func a3_oferta() -> int:
	return int(A3.venta[0 if int(a3().gan) else 1])

func a3_llamada() -> void:
	var A := a3()
	A.ll = int(S.day)
	var N := K("LLAMADA · UNAI GARRO")
	var acu := String(a2().get("acu", "")) == CULPABLE
	await talk(N, [K("Sé que me acusaste delante de medio barrio. No te lo voy a negar: quería esa Haze y la sigo queriendo.") if acu else K("No nos conocemos, pero yo a ti sí: tienes la Haze de Maite."),
		(K("La oficina te ha dado la razón. Me da igual: la quiero en mi catálogo y pago por ella.") if int(A.gan) else K("La Haze del 98 ya es mía en los papeles. Te ofrezco algo por la madre y las notas, y te dejo en paz.")),
		T("{e} por la madre de la Haze del 98, sus semillas y las notas de cría. Hoy.", {"e": Datos.eur(a3_oferta())})])
	var abierto: bool = bt().has("fin")
	var con_miren: bool = a3_fijada() and rel("miren") >= int(A3.miren)
	var it := [{"label": K("El banco de la tía es del barrio"), "disabled": not abierto,
			"desc": K("Lo que es de todos no se vende.") if abierto else K("Antes tienes que abrir el banco de semillas de la tía: todas sus colecciones, con la Haze del 98 fijada.")},
		{"label": T("Vender a Semillas Ondarea · {e}", {"e": Datos.eur(a3_oferta())}), "desc": K("Garro se lleva la madre, las semillas de la Haze y las notas. El barrio se enterará.")},
		{"label": K("Irte con Miren a Errotabarri"), "disabled": not con_miren,
			"desc": K("Subir al monte con la Haze fijada, lejos de todo.") if con_miren else T("Hace falta la Haze del 98 fijada y la confianza de Miren ({r}/{m}).", {"r": rel("miren"), "m": int(A3.miren)})},
		{"label": K("Colgar"), "desc": K("Que vuelva a llamar.") if int(A.gan) else K("Sin la oposición ganada, Ondarea irá a por ti.")}]
	var i: int = await menu(it, {"cls": "full", "title": K("LA OFERTA DE ONDAREA"), "desc": true, "initial": 3})
	if i < 0 or i == 3:
		if int(A.gan):
			await say(K("«Volveré a llamar. Siempre vuelvo a llamar.»"), N)
			return
		await a3_final("caida")
		return
	await a3_final(FINALES[i])

func a3_final(k: String) -> void:
	var A := a3()
	A.fin = k
	a3_paso(4)
	var ay := a2_ayuda_n()
	match k:
		"banco":
			await talk(ay, [K("Garro ha colgado sin despedirse. Lo que está en el banco del barrio no lo puede comprar nadie."),
				K("Esta tarde vienen los socios a pedir semillas. Uno de ellos se ha llevado la Haze del 98 para su huerta. Como quería ella.")])
			S.rep = float(S.rep) + int(A3.rep)
			S.prest = int(S.get("prest", 0)) + int(A3.prest)
			await got(T("FIN · el banco de la tía, de todos ({r} de reputación)", {"r": int(A3.rep)}))
		"vender":
			S.banco = float(S.get("banco", 0)) + a3_oferta()
			S.seeds.erase(String(A3.haze))
			S.rep = float(S.rep) - int(A3.pierde)
			confia(a2_ayuda(), -int(A3.pierde))
			await talk(ay, [K("Ya me he enterado. No te voy a decir nada: el dinero también es la vida."),
				K("Pero la Haze de tu tía ya lleva el nombre de otro. Eso no lo arregla ninguna transferencia.")])
			await got(T("FIN · {e} en la cuenta y la Haze del 98, de Ondarea", {"e": Datos.eur(a3_oferta())}))
		"miren":
			confia("miren", 10)
			await talk(K("MIREN"), [K("Sube cuando quieras. Arriba la tierra es buena y nadie pregunta."),
				K("Tu tía siempre dijo que la Haze tenía que volver al monte. Tú la has fijado: ahora no se pierde."),
				K("Lo de abajo no se acaba porque te vayas. Pero aquí arriba, al menos, la cosecha es tuya.")])
			await got(K("FIN · con Miren, en Errotabarri, con la Haze del 98"))
		"caida":
			S.heat = minf(100.0, float(S.heat) + int(A3.calor))
			S.seeds.erase(String(A3.haze))
			update_hud()
			await talk(K("CARTA · ABOGADOS DE ONDAREA"), [K("Requerimiento: cese inmediato en la reproducción y distribución de la variedad registrada «Haze 98»."),
				K("Se ha dado traslado a las autoridades. Cualquier semilla de la variedad en su poder será intervenida.")])
			await talk(ay, [K("Han venido con un notario y se han llevado las semillas de la Haze. La policía ya sabe tu nombre."),
				K("Lo que queda de la tía es lo que tengas en las carpas y lo que recuerde el barrio. Empieza otra vez, despacio.")])
			await got(T("FIN · la caída: sin la Haze del 98 y con calor +{c}", {"c": int(A3.calor)}))
	update_hud()
	await say(K("La historia de la tía Maite termina aquí. La partida sigue: tus carpas, tu gente y tus semillas."))

# OBJETIVO → LA TÍA MAITE: los Actos III y IV debajo del II
func hilo_items() -> Array:
	var it := super()
	var p := a3_p()
	for i in range(1, mini(p, 4) + 1):
		var d := ""
		match i:
			1:
				d = T("Semillas Ondarea quiere registrar como suyas la Haze del 98 y landraces del banco de la tía. Oponte desde su ordenador antes del {f}, con {m} pruebas. Tienes {n}.", {"f": Datos.fd(a3_dia(1) + int(A3.plazo), S.day), "m": int(A3.min), "n": a3_pruebas().size()})
			2:
				d = T("Presentada con {n} pruebas. La oficina resuelve el {f}.", {"n": a3().pr.size(), "f": Datos.fd(a3_dia(2) + int(A3.dias), S.day)})
			3:
				d = (K("La oficina dio la razón a la tía.") if int(a3().gan) else K("La oficina dio el registro a Ondarea.")) + " " + K("Unai Garro llama con su oferta: lo que elijas lo decide lo que has cultivado.")
			4:
				d = {"banco": K("El banco de la tía, de todos."), "vender": K("Vendiste la Haze del 98 a Ondarea."), "miren": K("Te fuiste con Miren a Errotabarri con la Haze fijada."), "caida": K("La caída: Ondarea se llevó la Haze.")}.get(String(a3().fin), "")
		it.append({"label": A3_PASOS[i][0], "right": K("HECHO") if i < p or p == 4 else K("AHORA"), "desc": d})
	return it

func hilo_derecha() -> String:
	var p := a3_p()
	if p == 0:
		return super()
	if p < 3:
		return T("III · {n}/{m}", {"n": a3_pruebas().size(), "m": int(A3.min)})
	return K("IV · HECHO") if p == 4 else K("IV · AHORA")
