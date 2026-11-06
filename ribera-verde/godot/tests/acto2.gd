# Ribera Verde (Godot) — el Acto II, «Quién entró en el piso» (ESTUDIO, tanda 3; con CAL): cerrado el cuaderno azul, al día
# siguiente Txaro avisa; la rueda del diploma, forzada, abre la investigación; quien te ayuda (por la elección del cuaderno) da una
# pista; las otras en el ordenador, el muelle, la catedral, el teatro y Hacienda; con cuatro, la acusación: Garro, las semillas y la
# reputación; otro, más calor; el menú de OBJETIVO; las partidas de antes; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/acto2.gd   → «acto2: N comprobaciones, 0 fallos»
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
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
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
	Juego.GUARDADO = "user://prueba-acto2.json"
	Juego.AJUSTES = "user://prueba-acto2-ajustes.json"
	Datos.CAL = true
	Datos.carga()
	Atlas.carga()
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
	J.S.ch = maxi(int(J.S.ch), 5)
	J.S.flags.letter = true
	J.S.erase("a2")
	# 0 · una partida de antes: sin Acto II, el menú de siempre
	J.S.hilo = {"p": 6, "tr": {"miren": 1, "serora": 1, "txaro": 1}, "cor": 2, "el": 0, "d": {"6": int(J.S.day)}}
	chk(J.a2_p() == 0 and J.hilo_derecha() == "6/6", "de antes, sin Acto II: %s" % J.hilo_derecha())
	# 1 · el mismo día que se cierra el cuaderno, nada; al día siguiente, Txaro
	J.hilo_dia()
	chk(J.a2_p() == 0, "el mismo día, nada")
	J.S.hilo.d["6"] = int(J.S.day) - 1
	J.S.ch = 4
	J.hilo_dia()
	chk(J.a2_p() == 0, "antes del cap. 5 (Molina), nada")
	J.S.ch = 5
	J.hilo_dia()
	chk(J.a2_p() == 1 and J.queued.has("a2txaro"), "al día siguiente, el SMS de Txaro")
	J.queued.clear()
	# 2 · la rueda del diploma abre la investigación; Delroy (lo contaste en la asociación) da la de Hacienda
	LOG = []
	chk(corre(func(): await J.diploma_action()), "el diploma")
	chk(J.a2_p() == 2 and dicho("marcas de destornillador") and dicho("Darko"), "la rueda, forzada, y los tres nombres")
	chk(J.a2().pi.keys() == ["hacienda"] and dicho("Molina no vino al funeral"), "Delroy da la pista de Hacienda (%s)" % [J.a2().pi])
	J.queued.clear()
	chk(J.hilo_derecha() == "II · 1/5", "OBJETIVO: %s" % J.hilo_derecha())
	# 3 · las pistas
	LOG = []
	chk(corre(func(): await J.pc_action()) and J.a2().pi.has("pc") and dicho("Semillas Ondarea") and dicho("11:40"), "el correo de la tía")
	LOG = []
	chk(corre(func(): await J.pc_action()) and not dicho("11:40"), "una vez")
	var r := {"v": false}
	var mar0 = J.S.get("mar")
	J.S.mar = null
	chk(corre(func(): r.v = await J.hilo_talk("koldo")) and not r.v and not J.a2().pi.has("muelle"), "Koldo sin conocerlo: su presentación primero")
	J.S.mar = {}
	chk(corre(func(): r.v = await J.hilo_talk("koldo")) and r.v and J.a2().pi.has("muelle") and dicho("chipirones"), "Koldo: Darko estaba en la mar")
	J.S.mar = mar0
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("delroy")) and r.v and dicho("Aún no tienes bastante") and J.a2_p() == 2, "con 3 de 4, Delroy dice que falta y sigue con lo suyo")
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("delroy")) and r.v and not dicho("Aún no tienes bastante"), "una vez al día")
	J.S.map = "catedral-in"
	J.S.min = 600
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("bi_cura_catedral")) and r.v and J.a2().pi.has("catedral") and dicho("tarjeta"), "el cura de la catedral")
	chk(dicho("Habla con Delroy"), "con 4, a Delroy")
	J.S.map = "home"
	chk(corre(func(): r.v = await J.hilo_talk("bi_funcionaria")) and not r.v, "la de Hacienda, ya dada: lo de siempre")
	# 4 · acusar a Garro
	var sem := int(J.S.seeds.get("malana", 0))
	var rep := float(J.S.rep)
	MENUS = []
	QUIERO = ["Ahora no"]
	chk(corre(func(): r.v = await J.hilo_talk("delroy")) and r.v and J.a2_p() == 2 and J.a2().acu == "", "«Ahora no»: lo de siempre")
	MENUS = []
	QUIERO = ["Sí", "Unai Garro"]
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("delroy")) and r.v, "la acusación")
	chk(J.a2_p() == 3 and J.a2().acu == "garro" and int(J.S.seeds.get("malana", 0)) == sem + 3 and is_equal_approx(float(J.S.rep), rep + 5), "Garro: acertaste, las semillas de Malana y la reputación")
	chk(dicho("Ahora sabe que la tienes tú") and J.hilo_derecha() == "II · HECHO", "y se cierra: %s" % J.hilo_derecha())
	J.queued.clear()
	MENUS = []
	QUIERO = ["Volver"]
	chk(corre(func(): await J.hilo_menu()) and MENUS.size() and MENUS[0].has("Quién entró en el piso") and MENUS[0].has("El piso, cerrado"), "OBJETIVO, con el Acto II: %s" % [MENUS])
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("delroy")) and not r.v, "cerrado, Delroy vuelve a lo suyo")
	# 5 · con Baltasar (fuiste a por él), la pista del muelle; acusar a Darko sale caro
	J.S.erase("a2")
	J.S.hilo.el = 1
	J.a2_paso(1)
	chk(corre(func(): await J.diploma_action()) and J.a2().pi.keys() == ["muelle"], "Baltasar da la del muelle")
	J.queued.clear()
	for k in ["catedral", "teatro", "hacienda"]:
		J.a2().pi[k] = int(J.S.day)
	LOG = []
	chk(corre(func(): r.v = await J.hilo_talk("baltasar")) and r.v and dicho("mira el ordenador") and J.a2().acu == "", "sin el ordenador no se acusa")
	J.a2().pi["pc"] = int(J.S.day)
	var h0 := float(J.S.heat)
	var cf := int(J.S.rel.get("baltasar", 0)) if J.S.get("rel") is Dictionary else 0
	QUIERO = ["Sí", "Darko"]
	chk(corre(func(): r.v = await J.hilo_talk("baltasar")) and r.v and J.a2().acu == "darko", "acusar a Darko")
	chk(is_equal_approx(float(J.S.heat), minf(100, h0 + 10)), "más calor (%s)" % J.S.heat)
	J.queued.clear()
	# 6 · guardártelo: te ayuda Kiko
	J.S.erase("a2")
	J.S.hilo.el = 2
	J.a2_paso(1)
	chk(corre(func(): await J.diploma_action()) and J.a2().pi.keys() == ["pc"], "Kiko da la del ordenador")
	J.queued.clear()
	MENUS = []
	LOG = []
	chk(corre(func(): await J.npc_talk({"id": "kiko"})) and dicho("Aún no tienes bastante") and MENUS.size() > 0, "Kiko sigue vendiendo durante la investigación (%s)" % [MENUS])
	# 6b · con la caja empotrada, la rueda era la de la caja vieja
	var caja0 = J.S.get("caja")
	J.S.caja = {"nivel": 2}
	J.S.erase("a2")
	J.a2_paso(1)
	LOG = []
	chk(corre(func(): await J.diploma_action()) and dicho("caja vieja que quitó Kiko") and J.a2_p() == 2, "la empotrada: la caja vieja")
	J.S.caja = caja0
	J.queued.clear()
	# 7 · sin CAL, nada
	J.S.erase("a2")
	Datos.CAL = false
	Datos.carga()
	J.S.hilo.d["6"] = 0
	J.hilo_dia()
	chk(not J.S.has("a2") and J.a2_p() == 0, "sin CAL, no empieza")
	Datos.CAL = true
	Datos.carga()
	print("acto2: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for t in fallos:
		print("  FALLO: " + t)
	quit(1 if fallos.size() else 0)
