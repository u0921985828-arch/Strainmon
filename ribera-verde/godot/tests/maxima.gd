# Landrace Hunters — una partida con todo al máximo (lo pidió el usuario: «una partida actualizada con todo al máximo, todo
# comprado y todo lo mejor»). No es una prueba: es la herramienta que la fabrica. Parte de `new_state()`, la rellena por áreas
# con las funciones del juego, la pasa por `migrate()` y `partida_valida()`, la carga de verdad (`enter_game`) y la deja
# exportada en el formato de COPIA DE SEGURIDAD (`cierra_partida`: LH1.…) y en JSON.
#   $GODOT --headless --path godot --script res://tests/maxima.gd -- --salida <dir>
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Menus = preload("res://src/menus.gd")
const MaxCultivo = preload("res://tests/max/cultivo.gd")
const MaxMundo = preload("res://tests/max/mundo.gd")

var J
var M
var LOG := []
var MENUS := []
var QUIERO := ""
var fallos := []
var n := 0

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera: así existe todo (setas, apuestas, cifras reales)
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
	for i in labels.size():
		if QUIERO != "" and labels[i].begins_with(QUIERO):
			k = i
	QUIERO = ""
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
			return false
	return true

func _salida() -> String:
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--salida" and i + 1 < a.size():
			return a[i + 1]
	return "/tmp"

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-maxima.json"
	Juego.AJUSTES = "user://prueba-maxima-ajustes.json"
	J = Juego.new()
	J.oraculo = true   # sin animaciones ni esperas
	root.add_child(J)
	M = J.M
	J.show_title()
	J.S = J.new_state()
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass

	# el estado al máximo, por áreas
	_cultivo(J)
	_historia(J)
	_negocios(J)
	_mundo(J)

	J.migrate()
	chk(J.partida_valida(J.S), "partida_valida dice que no")
	J.enter_game()
	chk(J.mode == "world", "no entra al mundo: %s" % J.mode)

	var js := JSON.stringify(J.S, "", false, true)
	var lh := Menus.cierra_partida(js)
	chk(Menus.abre_partida(lh) == js, "la exportada no se vuelve a abrir igual")
	var s2 = JSON.parse_string(Menus.abre_partida(lh))
	chk(J.partida_valida(s2), "la exportada no es válida")

	var dir := _salida()
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir + "/partida-maxima.txt", FileAccess.WRITE)
	f.store_string(lh)
	f.close()
	var g := FileAccess.open(dir + "/partida-maxima.json", FileAccess.WRITE)
	g.store_string(js)
	g.close()

	print("maxima: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  - " + x)
	print("  JSON %d B · LH1 %d B · %s" % [js.length(), lh.length(), dir])
	quit(1 if fallos.size() else 0)

# — los cuatro bloques: el estado al máximo por áreas, con las tablas del juego como catálogo —

func _cultivo(_J) -> void:
	MaxCultivo.pon(J)

func _historia(_J) -> void:
	var S = J.S
	var D = Datos.D
	# el último capítulo, la deuda pagada y la carta, el diario y la lata leídos
	S.ch = 8
	S.day = 420
	S.debt = 0
	S.due = 0
	S.vencidos = 0
	S.eco = 2
	S.rep = 100
	S.heat = 0
	S.hpMax = 60
	S.hp = 60
	S.sales = 400
	for k in ["letter", "diario", "pagina", "cajaSem", "kiko1", "julen1", "harvest1", "tono", "inaki", "ane",
			"molina1", "darko1", "darkoFin", "miren", "txaro", "txaro2", "robo", "rescate", "conce", "copa",
			"cupVip", "lab", "nevera", "curado", "taper", "tarros", "setasSms", "koldoSms", "rutaTia", "naveVer",
			"gVeg", "gFlor", "gRiego", "metB", "barras", "rastroP", "regBeg", "notaAma", "llegada"]:
		S.flags[k] = 1
	# toda la genética descubierta y fijada en F4, con semillas de sobra
	for sid in D.STRAINS.keys():
		S.seeds[sid] = 99
		S.disc[sid] = true
		S.gen[sid] = int(D.GEN_ESTABLE)
	# el hilo del cuaderno azul, los actos y las copas
	S.hilo = {"p": 9, "tr": {"miren": 1, "serora": 1, "txaro": 1}, "cor": 1, "el": 0, "d": {}}
	S.a2 = {"p": 9, "pi": {"pc": 1, "catedral": 1, "teatro": 1, "hacienda": 1, "muelle": 1}, "acu": "garro", "d": {}}
	S.a3 = {"p": 9, "d": {}, "pr": ["cuaderno", "haze", "banco", "correo", "asamblea"], "gan": 1, "fin": "banco"}
	S.cot = {"y": {}, "tro": ["potencia", "sabor", "landrace", "cruce", "extraccion"], "abs": [2026]}
	S.bt = {"c": {}, "tt": []}
	for c in D.BANCO_TIA.col:
		S.bt.c[String(c.id)] = 1
	# las misiones, el itinerario y los logros al completo
	for m in D.MISIONES:
		S.misiones[String(m.id)] = 1
	for l in D.LOGROS:
		S.logros[String(l.id)] = 1
	# la revista: la suscripción, todas las técnicas y la colección
	S.rev = {"col": [], "tec": [], "sus": 12, "nw": []}
	for i in 12:
		S.rev.col.append(i + 1)
	for t in D.REVISTA.tec:
		S.rev.tec.append(String(t.k))
	# LA TIENDA: las semillas doradas y los extras
	S.tn = {"sd": 9999, "c": {}, "g": {}, "r": 1}
	for it in D.TIENDA.it:
		if it.get("k") != null and String(it.get("cat", "")) != "sd":
			S.tn.c[String(it.k)] = 1

func _negocios(_J) -> void:
	var S = J.S
	var D = Datos.D
	# la nave, comprada y con el mejor equipo en las mesas
	S.nave = J.nave_nueva()
	S.nave.ex = D.EXTR_NAVE.size() - 1
	S.nave.rg = D.RIEGO_NAVE.size() - 1
	S.nave.ab = {"m": 99.0, "o": 99.0}
	S.nave.op = 1
	S.nave.mia = true
	S.nave.cur = 1
	S.nave.bc = []
	# la presidencia de la asociación y la confianza con todos los clubs
	S.aso = {"v": 9, "d": 1, "tio": true, "asam": 1, "otra": 0, "pres": true, "votos": 40, "lote": null, "al": {}}
	for k in D.CLUBS.keys():
		S.clubs[k] = 20
	# los seis locales y los negocios, con sus mejoras
	for k in D.LOCALES.keys():
		S.loc[k] = {"caja": 0.0, "lim": 1.0, "mej": {}, "g": {}}
	# el mar: los tres barcos, la reputación y la ley
	S.mar = {"b": ["txalupa", "pesquero", "atunero"], "rep": 100, "kg": 0.0, "env": [], "ped": null,
			"pd": 0, "paso": 0, "fin": 0, "n": 9, "obras": 9, "lic": 1, "legal": 1, "bod": {}}
	# el piso franco, los pisos de venta y la ciudad
	S.franco = {"r": S.day + 30, "buds": {}, "caja": 0, "cal": 0.0, "niv": 2, "v": 1}
	S.pisos = {}
	# la plantilla: la gente del barrio con los números al tope
	S.plantilla = []
	for i in 6:
		S.plantilla.append({"n": "", "labia": 5, "cuidado": 5, "lealtad": 5, "rol": "vend", "d": S.day})
	S.plN = 6
	# la sala de cultivo de KAIA, en el nivel más alto
	S.kc = {"niv": int(D.KAIA_CULT.niv.size()) - 1, "kits": [], "p": [], "pat": {}}
	# el despacho de lujo
	S.desp = {"d": int(S.day), "money": 0, "buds": {}, "niv": 2}

func _mundo(_J) -> void:
	MaxMundo.pon(J)
