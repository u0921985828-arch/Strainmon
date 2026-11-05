# Landrace Hunters — una partida con todo al máximo (lo pidió el usuario: «una partida actualizada con todo al máximo, todo
# comprado y todo lo mejor»). No es una prueba: es la herramienta que la fabrica. Parte de `new_state()`, la rellena por áreas
# con las funciones del juego, la pasa por `migrate()` y `partida_valida()`, la carga de verdad (`enter_game`) y la deja
# exportada en el formato de COPIA DE SEGURIDAD (`cierra_partida`: LH1.…) y en JSON.
#   $GODOT --headless --path godot --script res://tests/maxima.gd -- --salida <dir>
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Menus = preload("res://src/menus.gd")

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

# — los cuatro bloques, de momento vacíos (los rellenan las áreas) —
func _cultivo(_J) -> void:
	pass

func _historia(_J) -> void:
	pass

func _negocios(_J) -> void:
	pass

func _mundo(_J) -> void:
	pass
