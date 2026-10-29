# Ribera Verde (Godot) — los Actos III y IV (ESTUDIO, tanda 6; con CAL): el aviso de Delroy cerrado el Acto II desde el capítulo 7;
# las pruebas, de lo hecho (cuaderno, Haze fijada, banco, el correo si acusaste a Garro, la asamblea si lo contaste); la oposición
# desde el ordenador y su resolución; el plazo que pasa; la llamada de Garro cada semana; los cuatro finales —el banco, vender,
# Miren, la caída— solo con lo que has cultivado; OBJETIVO; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/acto3.gd   → «acto3: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")
const Cultivo = preload("res://src/cultivo.gd")
const I18n = preload("res://src/i18n.gd")

var J
var M
var LOG := []
var MENUS := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	var dis := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
		dis.append(not (it is String) and it.get("disabled", false))
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q) and not dis[i]:
			k = i
			break
	o = o.duplicate()
	o.initial = k
	return o

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo")
			return false
	return true

func dicho(t: String) -> bool:
	return LOG.any(func(l): return String(l).contains(t))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-acto3.json"
	Juego.AJUSTES = "user://prueba-acto3-ajustes.json"
	Datos.CAL = true
	Datos.carga()
	Atlas.carga()
	var D: Dictionary = Datos.carga()
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-noche":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	J.S.flags.letter = true
	J.S.min = 600
	J.S.disc["silver"] = true
	if not (J.S.get("gen") is Dictionary):
		J.S.gen = {}
	J.S.gen["silver"] = 1
	J.S.seeds["silver"] = 5
	J.S.erase("a3")
	J.S.erase("bt")
	J.S.hilo = {"p": 6, "tr": {"miren": 1, "serora": 1, "txaro": 1}, "cor": 2, "el": 0, "d": {"6": int(J.S.day) - 20}}
	J.S.a2 = {"p": 3, "pi": {"pc": 1, "hacienda": 1, "teatro": 1, "catedral": 1}, "acu": "garro", "d": {"3": int(J.S.day) - 1}}
	var A3: Dictionary = J.A3
	# 0 · cerrado el Acto II, desde el capítulo 7, el aviso de Delroy
	J.S.ch = 6
	J.hilo_dia()
	chk(J.a3_p() == 0, "antes del capítulo 7, nada")
	J.S.ch = 8
	J.S.a2.d["3"] = int(J.S.day)
	J.hilo_dia()
	chk(J.a3_p() == 0, "el mismo día del Acto II, nada")
	J.S.a2.d["3"] = int(J.S.day) - 1
	J.hilo_dia()
	chk(J.a3_p() == 1 and J.queued.has("a3aviso"), "al día siguiente, el SMS de Delroy")
	J.queued.clear()
	chk(J.hilo_derecha() == "III · 3/3", "OBJETIVO: %s" % J.hilo_derecha())
	# 1 · las pruebas salen de lo hecho: el cuaderno, el correo (acusaste a Garro) y la asamblea (lo contaste en la asociación)
	chk(J.a3_pruebas() == ["cuaderno", "correo", "asamblea"], "las pruebas: %s" % [J.a3_pruebas()])
	J.S.gen["silver"] = int(D.GEN_ESTABLE)
	J.S.bt = {"c": {"kush": 1, "costa": 1, "africa": 1}}
	chk(J.a3_pruebas().size() == 5, "con la Haze fijada y tres colecciones del banco, las cinco")
	J.S.gen["silver"] = 1
	J.S.erase("bt")
	# 2 · la oposición, desde el ordenador de la tía
	QUIERO = ["Todavía no"]
	LOG = []
	chk(corre(func(): await J.pc_action()) and J.a3_p() == 1 and dicho("Oficina de Variedades"), "«Todavía no»: sin presentar")
	QUIERO = ["Presentarla"]
	chk(corre(func(): await J.pc_action()) and J.a3_p() == 2 and J.a3().pr.size() == 3, "presentada con 3 pruebas")
	LOG = []
	chk(corre(func(): await J.pc_action()) and not dicho("Oficina de Variedades"), "presentada, el ordenador de siempre")
	# 3 · la resolución, a los A3.dias
	var d2: int = J.a3_dia(2)
	J.S.day = d2 + int(A3.dias) - 1
	J.hilo_dia()
	chk(J.a3_p() == 2, "antes de tiempo, nada")
	J.S.day = d2 + int(A3.dias)
	J.hilo_dia()
	chk(J.a3_p() == 3 and int(J.a3().gan) == 1 and J.queued.has("a3res"), "con 3 pruebas, ganada")
	J.queued.clear()
	J.hilo_dia()
	chk(not J.queued.has("a3garro"), "el mismo día, Garro no llama")
	J.S.day += 1
	J.hilo_dia()
	chk(J.queued.has("a3garro"), "al día siguiente, la llamada de Garro")
	J.queued.clear()
	# 4 · colgar con la oposición ganada: vuelve a llamar a los A3.llamada días
	QUIERO = ["Colgar"]
	MENUS = []
	LOG = []
	chk(corre(func(): await J.a3_llamada()) and J.a3().fin == "" and dicho("Sé que me acusaste") and dicho("250.000"), "colgar: sin final; Garro sabe que le acusaste")
	chk(MENUS.size() > 0 and MENUS[0].size() == 4, "las cuatro salidas (%s)" % [MENUS])
	J.S.day += 1
	J.hilo_dia()
	chk(not J.queued.has("a3garro"), "al día siguiente no vuelve")
	J.S.day += int(A3.llamada) - 1
	J.hilo_dia()
	chk(J.queued.has("a3garro"), "a los %d días, sí" % int(A3.llamada))
	J.queued.clear()
	# 5 · lo que no tienes no se elige: sin el banco abierto ni la Haze fijada, el banco y Miren no
	QUIERO = ["El banco"]
	chk(corre(func(): await J.a3_llamada()) and J.a3().fin == "", "el banco, sin abrir, no se elige")
	QUIERO = ["Irte con Miren"]
	chk(corre(func(): await J.a3_llamada()) and J.a3().fin == "", "Miren, sin la Haze fijada, no")
	# 6 · vender: el dinero a la cuenta, sin la Haze, menos reputación
	var b0 := float(J.S.get("banco", 0))
	var r0 := float(J.S.rep)
	QUIERO = ["Vender"]
	chk(corre(func(): await J.a3_llamada()) and J.a3().fin == "vender" and J.a3_p() == 4, "vender a Ondarea: el final")
	chk(is_equal_approx(float(J.S.banco), b0 + 250000) and not J.S.seeds.has("silver") and float(J.S.rep) < r0, "250.000 € a la cuenta, sin la Haze, menos reputación")
	chk(J.hilo_derecha() == "IV · HECHO", "OBJETIVO: %s" % J.hilo_derecha())
	var it: Array = J.hilo_items()
	chk(it.size() == 1 + 3 + 4 and String(it[-1].desc).contains("Vendiste"), "OBJETIVO: los pasos del III y el IV (%d)" % it.size())
	J.S.day += 30
	J.hilo_dia()
	chk(not J.queued.has("a3garro"), "con final, Garro ya no llama")
	# 7 · perdida: el plazo pasa sin presentar; colgar es la caída
	J.S.seeds["silver"] = 5
	J.S.a3 = {"p": 1, "d": {"1": int(J.S.day)}, "pr": [], "gan": 0, "fin": ""}
	J.S.day += int(A3.plazo)
	J.hilo_dia()
	chk(J.a3_p() == 1, "el último día del plazo, aún no")
	J.S.day += 1
	J.hilo_dia()
	chk(J.a3_p() == 3 and int(J.a3().gan) == 0, "pasado el plazo, perdida")
	var h0 := float(J.S.heat)
	J.S.heat = minf(h0, 50.0)
	h0 = float(J.S.heat)
	QUIERO = ["Colgar"]
	LOG = []
	chk(corre(func(): await J.a3_llamada()) and J.a3().fin == "caida" and dicho("60.000"), "perdida y sin ceder: la caída (oferta de 60.000 €)")
	chk(is_equal_approx(float(J.S.heat), h0 + int(A3.calor)) and not J.S.seeds.has("silver"), "la caída: calor +%d y sin la Haze" % int(A3.calor))
	# 8 · Miren, con la Haze fijada y su confianza
	J.S.a3 = {"p": 3, "d": {"3": int(J.S.day) - 1}, "pr": [], "gan": 1, "fin": ""}
	J.S.gen["silver"] = int(D.GEN_ESTABLE)
	J.S.rel["miren"] = int(A3.miren)
	QUIERO = ["Irte con Miren"]
	LOG = []
	chk(corre(func(): await J.a3_llamada()) and J.a3().fin == "miren" and dicho("volver al monte"), "con la Haze fijada: Miren")
	# 9 · el banco de la tía, abierto: lo de todos no se vende
	J.S.a3 = {"p": 3, "d": {"3": int(J.S.day) - 1}, "pr": [], "gan": 1, "fin": ""}
	J.S.bt = {"c": {}, "fin": int(J.S.day) - 3}
	r0 = float(J.S.rep)
	QUIERO = ["El banco"]
	chk(corre(func(): await J.a3_llamada()) and J.a3().fin == "banco" and is_equal_approx(float(J.S.rep), r0 + int(A3.rep)), "con el banco abierto: de todos")
	# 10 · lo de antes cambia las pruebas: sin acusar a Garro y guardándote el cuaderno, solo una; perdida
	J.S.a2.acu = "molina"
	J.S.hilo.el = 2
	J.S.gen["silver"] = 1
	J.S.erase("bt")
	J.S.a3 = {"p": 1, "d": {"1": int(J.S.day)}, "pr": [], "gan": 0, "fin": ""}
	chk(J.a3_pruebas() == ["cuaderno"], "acusando a Molina y sin la asamblea: %s" % [J.a3_pruebas()])
	QUIERO = ["Presentarla"]
	chk(corre(func(): await J.pc_action()) and J.a3_p() == 2, "presentada con 1")
	J.S.day += int(A3.dias)
	J.hilo_dia()
	chk(J.a3_p() == 3 and int(J.a3().gan) == 0, "con 1 prueba, perdida")
	J.S.day += 1
	J.queued.clear()
	J.hilo_dia()
	QUIERO = ["Colgar"]
	LOG = []
	chk(corre(func(): await J.a3_llamada()) and dicho("No nos conocemos"), "sin acusarle, Garro se presenta")
	# 11 · sin CAL, nada
	Datos.CAL = false
	Datos.carga()
	J.S.erase("a3")
	J.queued.clear()
	J.hilo_dia()
	chk(J.a3_p() == 0 and not J.S.has("a3"), "sin CAL, no hay Actos III ni IV")
	Datos.CAL = true
	Datos.carga()
	print("acto3: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for t in fallos:
		print("  FALLO: " + t)
	quit(1 if fallos.size() else 0)
