# Ribera Verde (Godot) — 1.43.4: exportar e importar la partida, más escondidos (lo pidió el usuario): ya no salen en OPCIONES,
# sino en su submenú COPIA DE SEGURIDAD, al final (y en el título, solo importar). Sin Datos.CAL, como antes (historia.gd).
#   $GODOT --headless --path godot --script res://tests/copia.gd   → «copia: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var D
var MENUS := []
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

# los menús: el primero que empiece por lo siguiente de QUIERO; si no, el último
func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	if QUIERO.size():
		var q: String = QUIERO.pop_front()
		for i in labels.size():
			if labels[i].begins_with(q):
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
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-copia.json"
	Juego.AJUSTES = "user://prueba-copia-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "caja-dentro":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	D = J.D
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	J.exportado = ""
	QUIERO = ["COPIA", "EXPORTAR", "VOLVER"]
	MENUS = []
	chk(corre(func(): await J.opciones(false)), "bloqueo exportando")
	chk(MENUS.size() >= 2 and not MENUS[0].has("EXPORTAR PARTIDA") and not MENUS[0].has("IMPORTAR PARTIDA"), "OPCIONES sin exportar ni importar: %s" % [MENUS])
	chk(MENUS[0][-2] == "COPIA DE SEGURIDAD" and MENUS[0][-1] == "VOLVER", "COPIA, la penúltima: %s" % [MENUS[0] if MENUS.size() else []])
	chk(MENUS[1] == ["EXPORTAR PARTIDA", "IMPORTAR PARTIDA", "VOLVER"], "el submenú: %s" % [MENUS])
	var s = JSON.parse_string(J.exportado) if J.exportado != "" else null
	chk(s is Dictionary and int(s.day) == int(J.S.day), "exportada")
	QUIERO = ["COPIA", "VOLVER", "VOLVER"]
	MENUS = []
	chk(corre(func(): await J.opciones(true)), "bloqueo en el título")
	chk(MENUS.size() >= 2 and MENUS[1] == ["IMPORTAR PARTIDA", "VOLVER"] and not MENUS[0].has("IMPORTAR PARTIDA"), "en el título, solo importar: %s" % [MENUS])
	Datos.CAL = false
	QUIERO = ["VOLVER"]
	MENUS = []
	chk(corre(func(): await J.opciones(false)), "bloqueo sin CAL")
	chk(MENUS.size() and MENUS[0].has("EXPORTAR PARTIDA") and not MENUS[0].has("COPIA DE SEGURIDAD"), "sin CAL, como antes: %s" % [MENUS])
	print("copia: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  ✗ " + f)
	quit(1 if fallos.size() else 0)
