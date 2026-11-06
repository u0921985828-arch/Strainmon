# Ribera Verde (Godot) — el corte de madre y el cruce entre clones (lo pidió el usuario: «más que más landraces me refería a
# meter más descendencias no más landraces»; con CAL): en el armario de las madres, GUARDAR ESTE CORTE apunta el fenotipo exacto
# de esa madre con nombre propio y, de ahí en adelante, la madre se mete desde el corte guardado y cada esqueje sale idéntico;
# en el carro de esquejes, POLINIZAR ENTRE CLONES cruza dos esquejes pinchados y da semillas sin perder ninguna de las dos
# líneas, porque las madres siguen vivas.
#   $GODOT --path godot --script res://tests/cortes.gd   → «cortes: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Desc = preload("res://src/descend.gd")

var J
var M
var LOG := []
var MENUS := []
var QUIERO := []
var n := 0
var fallos := []

var t_ini := 0.0

func _initialize() -> void:
	Datos.PLAY = false
	t_ini = float(Time.get_ticks_msec())
	_corre.call_deferred()

# un tope duro: si algo revienta a mitad, el SceneTree se queda vivo para siempre
func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - t_ini > 240000:
		print("cortes: se quedó colgada")
		quit(2)
	return false

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
	Juego.GUARDADO = "user://prueba-cortes.json"
	Juego.AJUSTES = "user://prueba-cortes-ajustes.json"
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
	var D: Dictionary = J.D
	var E: Dictionary = D.DESC
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"

	# 1 · el corte de una madre del armario: se guarda con nombre propio y el fenotipo tal cual
	J.S.nave = {"ma": [{"k": "ria", "f": {"id": 7, "t": 1.3, "y": 1.2, "i": 70.0}, "v": 100, "e": 0}], "m": [], "bc": []}
	J.S.cortes = []
	LOG = []
	MENUS = []
	QUIERO = ["Guardar este corte"]
	chk(corre(func(): await J.madre_ops(0)), "guardar el corte se queda colgado")
	chk(Desc.cortes(J.S).size() == 1, "el corte se guardó: %s" % [J.S.get("cortes")])
	var C: Dictionary = Desc.cortes(J.S)[0]
	chk(String(C.k) == "ria" and C.f == J.S.nave.ma[0].f, "el corte guarda la variedad y el fenotipo")
	chk(String(J.S.nave.ma[0].get("ct", "")) == String(C.n), "la madre pasa a llamarse como su corte")
	chk(J.madre_txt(J.S.nave.ma[0]) == String(C.n), "y así sale en la vista: %s" % J.madre_txt(J.S.nave.ma[0]))
	chk(dicho("corte"), "no dice que se apunta el corte: %s" % [LOG])

	# 2 · una madre ya con corte no se vuelve a guardar
	LOG = []
	MENUS = []
	QUIERO = ["Nada"]
	chk(corre(func(): await J.madre_ops(0)), "colgado con la madre ya apuntada")
	chk(not MENUS.is_empty() and not MENUS[0].any(func(l): return String(l).contains("corte")), "deja guardar dos veces el mismo corte: %s" % [MENUS])

	# 3 · desde el corte se mete otra madre, idéntica
	J.S.nave.ma = []
	LOG = []
	MENUS = []
	QUIERO = ["De un corte guardado", String(C.n)]
	chk(corre(func(): await J.madre_meter()), "meter la madre del corte se queda colgado")
	chk(J.S.nave.ma.size() == 1, "no entró la madre del corte: %s" % [MENUS])
	chk(J.S.nave.ma.size() == 1 and J.S.nave.ma[0].f == C.f, "la madre del corte lleva el mismo fenotipo")
	chk(Desc.cortes(J.S).size() == 1, "el corte no se gasta: se puede repetir")
	chk(J.S.nave.ma.size() == 1 and int(J.S.nave.ma[0].v) == Desc.corte_vigor() and Desc.corte_vigor() < 100,
		"la madre del corte entra recién enraizada, a %d %% de vigor" % int(J.S.nave.ma[0].v))
	# y solo una al día: el corte no es un repuesto gratis de la carpa
	LOG = []
	QUIERO = ["De un corte guardado", String(C.n)]
	chk(corre(func(): await J.madre_meter()), "el segundo corte del día se queda colgado")
	chk(J.S.nave.ma.size() == 1, "dos madres de corte el mismo día: %d" % J.S.nave.ma.size())

	# 4 · y sus esquejes salen con ese mismo fenotipo
	J.S.esquejes = []
	var q: int = J._al_propagador(J.S.nave.ma[0], 2)
	chk(q == 2 and J.S.esquejes.size() == 2, "los esquejes del corte")
	chk(J.S.esquejes[0].f == C.f and J.S.esquejes[1].f == C.f, "cada esqueje sale idéntico al corte")

	# 5 · el tope de cortes
	J.S.nave.ma = [{"k": "thai", "f": {"id": 8, "t": 1.0, "y": 1.0, "i": 10.0}, "v": 100, "e": 0}]
	while Desc.cortes(J.S).size() < Desc.corte_tope():
		Desc.corte_pon(J.S, "thai", {"id": 9, "t": 1.0, "y": 1.0, "i": 50.0})
	LOG = []
	MENUS = []
	QUIERO = ["Nada"]
	chk(corre(func(): await J.madre_ops(0)), "colgado con los cortes llenos")
	chk(not MENUS.is_empty() and not MENUS[0].any(func(l): return String(l).contains("corte")), "con %d cortes ya no se ofrece guardar otro" % Desc.corte_tope())

	# 6 · el cruce entre clones: dos esquejes pinchados de variedades distintas
	J.S.bandejas = [{"sid": "ria", "f": {"id": 10, "t": 1.0, "y": 1.0, "i": 70.0}, "dia": int(J.S.day)},
		{"sid": "thai", "f": {"id": 11, "t": 1.0, "y": 1.0, "i": 10.0}, "dia": int(J.S.day)}]
	chk(J.clones_ya(), "con dos esquejes distintos se puede polinizar entre clones")
	var r := Datos.cross_result(J.S, "ria", "thai")
	J.S.seeds = {}
	J.S.disc.erase(r)
	LOG = []
	MENUS = []
	QUIERO = ["Skunk", "Thai", "Polinizar"]
	chk(corre(func(): await J.clones_cruce()), "el cruce entre clones se queda colgado")
	chk(int(J.S.seeds.get(r, 0)) == int(E.clon.sem), "salen %d semillas: %s" % [int(E.clon.sem), J.S.seeds])
	chk(J.S.bandejas.is_empty(), "el cruce gasta los dos esquejes: %s" % [J.S.bandejas])
	chk(int(J.S.get("clonx", 0)) == int(J.S.day), "apunta el día del cruce para el que viene")
	chk(int(J.S.gen.get(r, 0)) == 1, "la variedad nueva nace en F1")
	chk(bool(J.S.disc.get(r)), "la variedad queda descubierta")
	chk(dicho("se han quedado en el cruce"), "no dice que los esquejes se gastan: %s" % [LOG])
	chk(J.clones_espera() > 0, "no hay espera hasta el siguiente cruce: %d" % J.clones_espera())

	# 6b · en el taco vacío, «Nada» no pincha nada (el aviso de cancelar no puede ejecutar la acción)
	J.S.bandejas = [{"sid": "ria", "f": {"id": 20, "t": 1.0, "y": 1.0, "i": 70.0}, "dia": int(J.S.day)},
		{"sid": "thai", "f": {"id": 21, "t": 1.0, "y": 1.0, "i": 10.0}, "dia": int(J.S.day)}]
	J.S.esquejes = [{"sid": "ria", "f": {"id": 22, "t": 1.0, "y": 1.0, "i": 70.0}, "dia": int(J.S.day)},
		{"sid": "ria", "f": {"id": 23, "t": 1.0, "y": 1.0, "i": 70.0}, "dia": int(J.S.day)}]
	var vez := {"n": 0}
	J.gancho_carro = func():
		vez.n += 1
		return 5 if vez.n == 1 else null   # un taco vacío y luego B
	LOG = []
	QUIERO = ["Nada"]
	chk(corre(func(): await J.carro_action()), "el carro se queda colgado con «Nada»")
	J.gancho_carro = Callable()
	chk(J.S.bandejas.size() == 2 and J.S.esquejes.size() == 2, "«Nada» ha pinchado los esquejes igual: bandejas %d, propagador %d" % [J.S.bandejas.size(), J.S.esquejes.size()])

	# 7 · con un solo esqueje, o con dos de la misma, no hay cruce
	J.S.bandejas = [{"sid": "ria", "f": {"id": 12, "t": 1.0, "y": 1.0, "i": 70.0}, "dia": int(J.S.day)},
		{"sid": "ria", "f": {"id": 13, "t": 1.0, "y": 1.0, "i": 70.0}, "dia": int(J.S.day)}]
	chk(not J.clones_ya(), "dos esquejes de la misma variedad no cruzan")
	J.S.bandejas = []
	chk(not J.clones_ya(), "sin esquejes, tampoco")

	# 8 · sin CAL no hay descendencias
	Datos.CAL = false
	Datos.carga()
	chk(not Desc.hay(), "sin CAL, nada de descendencias")
	Datos.CAL = true
	Datos.carga()

	print("cortes: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for t in fallos:
		print("  FALLO: " + t)
	quit(1 if fallos.size() else 0)
