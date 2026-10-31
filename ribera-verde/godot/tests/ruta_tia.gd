# Landrace Hunters (Godot) — la ruta de la tía por los pueblos y los ladrones solo de noche (lo pidió el usuario: «que haya cosas
# para hacer en cada pueblo… que la historia tenga algo que ver» y «que por el día no aparezcan carteristas, ni ladrones»; con CAL).
#   $GODOT --headless --path godot --script res://tests/ruta_tia.gd   → «ruta_tia: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
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

func habla(id: String) -> bool:
	var e = null
	for x in J.ents:
		if x.id == id:
			e = x
	if e == null:
		return false
	return corre(func(): await J.npc_talk(e.def))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-ruta.json"
	Juego.AJUSTES = "user://prueba-ruta-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · ladrones: de día no hay; de noche, sí
	var Z := {"lad": 1.0}
	S.money = 500
	S.min = 12 * 60
	chk(J.prob_ladron(10, false, Z) == 0.0, "de día, sin ladrones")
	S.min = 23 * 60
	var pn: float = J.prob_ladron(10, false, Z)
	chk(pn > 0.0, "de noche, sí: %s" % pn)
	S.min = 3 * 60
	chk(J.prob_ladron(10, true, Z) > pn, "de madrugada y alto, más")
	S.min = 12 * 60
	S.money = 0
	chk(J.prob_ladron(0, false, Z) == 0.0, "sin nada encima, nadie")
	Datos.CAL = false
	S.money = 500
	chk(J.prob_ladron(10, false, Z) > 0.0, "sin CAL, como antes (de día también)")
	Datos.CAL = true
	# 2 · la ruta: seis, un pueblo cada uno, fuera de Bilbao
	var R: Array = J.ruta_tia()
	chk(R.size() == 6, "seis recados de la tía: %d" % R.size())
	var mapas := {}
	for sc in R:
		mapas[sc.a.map] = true
		chk(J.D.LOOKS.has(sc.a.look), "%s: el muñeco %s" % [sc.id, sc.a.look])
		chk(String(sc.get("h", "")).length() > 20, "%s: su testimonio" % sc.id)
		chk(not sc.a.map in ["lapunta", "zorroza", "abando", "casco"], "%s: no es Bilbao" % sc.id)
	chk(mapas.size() == 6, "seis pueblos distintos: %s" % [mapas.keys()])
	chk(int(J.D.RUTA_TIA.min) == 3, "con 3, prueba del Acto III")
	# 3 · el del frontón, de verdad: 3 g y su testimonio
	S.ch = 2
	S.sec = {}
	S.flags.erase("rutaTia")
	J.enter_map("mendialde", 22, 21, "up")
	J.build_ents()
	J.mode = "world"
	chk(J.ents.any(func(x): return x.id == "sec_t_fronton") and J.sec_marca("sec_t_fronton"), "Pello, con su «!»")
	S.buds = {"ria": {"g": 5.0, "thc": 12.0, "dia": S.day}}
	var m0 := float(S.money)
	QUIERO = ["Skunk"]
	LOG = []
	chk(habla("sec_t_fronton") and J.sec_estado("t_fronton") == 2 and is_equal_approx(float(S.money), m0 + 40), "3 g y 40 € (%s, %s)" % [S.buds, S.money])
	chk(LOG.any(func(t): return String(t).begins_with("Testimonio para la tía")), "el testimonio en pantalla")
	chk(LOG.any(func(t): return String(t).contains("1/6")), "1/6 en la cuenta")
	chk(J.huellas().size() == 1, "una huella")
	chk(not "ruta" in J.a3_pruebas(), "con una, aún no es prueba")
	# 4 · con tres, prueba del Acto III; con las seis, el SMS de Delroy
	S.ch = 9
	var rep0 := int(S.rep)
	for i in range(1, 6):
		chk(corre(func(): await J.sec_premio(R[i])), "premio %s" % R[i].id)
		if i == 2:
			chk("ruta" in J.a3_pruebas(), "con tres, prueba: %s" % [J.a3_pruebas()])
			chk(not S.flags.get("rutaTia"), "aún sin el SMS")
	chk(J.huellas().size() == 6, "las seis")
	chk(S.flags.get("rutaTia"), "la ruta, cerrada")
	chk(J.cola_ya.has("rutaTia") or J.queued.has("rutaTia") or LOG.any(func(t): return String(t).contains("media comarca")), "el SMS de Delroy")
	var rp := 0
	for i in range(1, 6):
		rp += int(R[i].premio.get("rep", 0))
	chk(int(S.rep) == rep0 + rp + int(J.D.RUTA_TIA.todos.rep), "la reputación: %d" % S.rep)
	# 5 · en OBJETIVO → RECADOS
	QUIERO = ["LA RUTA"]
	chk(corre(func(): await J.recados_menu()), "el menú de recados")
	print("ruta_tia: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
