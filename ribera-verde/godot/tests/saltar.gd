# Landrace Hunters (Godot) — 0.51 (lo pidió el usuario): saltar el tutorial y no perder la partida guardada.
#  · NUEVA PARTIDA (con Datos.CAL) pregunta si jugar el tutorial o saltarlo; saltado, el nombre y el personaje, y la partida
#    empieza en el piso tras la primera cosecha (41 g de Skunk #1, la carta, Kiko, el itinerario hasta cosechar) y en el capítulo 2.
#    Sin Datos.CAL, sin la pregunta.
#  · load_save: la partida con una clave de otro tipo (de otra versión) se arregla (repara_partida) en vez de empezar de cero; la
#    que no tiene arreglo se copia en partida.rota.json antes de nada.
#   $GODOT --headless --path godot --script res://tests/saltar.gd   → «saltar: N comprobaciones, 0 fallos»
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
	var k := 0
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
		if M.reloj - t0 > 120000 or not M.paso():
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func borra() -> void:
	for x in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.GUARDADO + x))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.GUARDADO.get_basename() + ".rota.json"))

func escribe(s: Dictionary) -> void:
	var f := FileAccess.open(Juego.GUARDADO, FileAccess.WRITE)
	f.store_string(JSON.stringify(s))
	f.close()

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-saltar.json"
	Juego.AJUSTES = "user://prueba-saltar-ajustes.json"
	Datos.CAL = true
	borra()
	J = Juego.new()
	root.add_child(J)
	M = J.M
	D = J.D
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)

	# 1 · saltar el tutorial
	QUIERO = ["Saltarlo", "ÁLEX", "CHICA"]
	MENUS = []
	LOG = []
	chk(corre(func(): await J.new_game()), "bloqueo saltando")
	chk(MENUS.size() and MENUS[0] == ["Jugarlo", "Saltarlo"], "la pregunta, lo primero: %s" % [MENUS.slice(0, 1)])
	var S: Dictionary = J.S
	chk(S.name == "ÁLEX" and S.get("sexo") == "f", "el nombre y el personaje: %s %s" % [S.name, S.get("sexo")])
	chk(int(S.ch) == 2, "el capítulo 2 (%s)" % S.ch)
	chk(S.flags.get("harvest1") and S.flags.get("letter") and S.flags.get("kiko1") and S.flags.get("llegada"), "las flags del tutorial: %s" % [S.flags])
	chk(S.buds.has("ria") and int(S.buds.ria.g) == 41, "41 g de Skunk #1: %s" % [S.buds])
	chk(int(S.seeds.get("ria", 0)) == 1 and S.disc.get("ria"), "una semilla, descubierta: %s %s" % [S.seeds, S.disc])
	chk(S.itin.has("cosecha") and not S.itin.has("vender"), "el itinerario hasta cosechar: %s" % [S.itin])
	chk(S.logros.has("cosecha"), "el logro de la cosecha")
	chk(S.map == "home" and J.mode == "world", "en el piso (%s, %s)" % [S.map, J.mode])
	chk(" ".join(LOG).contains("Primera cosecha"), "el SMS de Kiko del capítulo 2")
	chk(J.partida_valida(S), "la partida saltada es válida")
	chk(FileAccess.file_exists(Juego.GUARDADO), "guardada (chapter guarda)")

	# 2 · sin Datos.CAL, sin la pregunta (el prólogo de siempre)
	Datos.CAL = false
	QUIERO = []
	MENUS = []
	chk(corre(func(): await J.new_game()), "bloqueo sin CAL")
	chk(MENUS.size() and not MENUS[0].has("Saltarlo") and MENUS[0][0] == "EDDIE", "sin CAL, el nombre lo primero: %s" % [MENUS.slice(0, 1)])
	chk(int(J.S.ch) == 1 and not J.S.flags.get("harvest1"), "sin CAL, el capítulo 1")
	Datos.CAL = true

	# 3 · la partida de otra versión: una clave con otro tipo se arregla
	borra()
	var b := S.duplicate(true)
	b.money = "x"
	b.carpas = {}
	b.min = 2000
	b.map = "mapa-que-ya-no-existe"
	escribe(b)
	var c = J.load_save()
	chk(c is Dictionary, "la partida con claves de otro tipo se carga (antes, null y partida nueva)")
	if c is Dictionary:
		chk(c.name == "ÁLEX" and int(c.ch) == 2 and c.buds.has("ria"), "lo demás, intacto")
		chk((c.money is int or c.money is float) and c.carpas is Array and int(c.min) == 1439 and c.map == "home", "arreglada: %s %s %s %s" % [c.money, c.carpas, c.min, c.map])
		chk(J.partida_valida(c), "y válida")
	chk(not FileAccess.file_exists(Juego.GUARDADO.get_basename() + ".rota.json"), "la arreglada no se copia aparte")
	# la que no tiene arreglo (sin nombre) no se pierde: partida.rota.json
	var r := S.duplicate(true)
	r.erase("name")
	escribe(r)
	chk(J.load_save() == null, "sin nombre, no se carga")
	var rota := Juego.GUARDADO.get_basename() + ".rota.json"
	chk(FileAccess.file_exists(rota) and FileAccess.get_file_as_string(rota) == FileAccess.get_file_as_string(Juego.GUARDADO), "copiada en .rota.json")
	# la .bak sana, cuando la principal no tiene arreglo
	var f := FileAccess.open(Juego.GUARDADO + ".bak", FileAccess.WRITE)
	f.store_string(JSON.stringify(S))
	f.close()
	var k = J.load_save()
	chk(k is Dictionary and k.name == "ÁLEX", "la .bak, si la principal no vale")
	# importar sigue estricto (E8)
	chk(not J.partida_valida(b), "importar: la de tipos cambiados sigue sin valer")
	borra()
	print("saltar: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  ✗ " + x)
	quit(1 if fallos.size() else 0)
