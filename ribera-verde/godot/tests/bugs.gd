# Landrace Hunters (Godot) — los bugs E1-E14 de la fase 3 del plan de Google Play: una prueba por bug, que fallaba antes del arreglo.
#   $GODOT --headless --path godot --script res://tests/bugs.gd   → «bugs: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
var n := 0
var fallos := []
var LOG := []
var QUIERO := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo: fin %s libre %s pend %s modo %s" % [st.fin, J.is_free(), J.pending.size(), J.mode])
			return false
	return true

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
	o = o.duplicate()
	o.initial = k
	return o

func escribe(ruta: String, t: String) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(t)
	f.close()

func borra(ruta: String) -> void:
	for r in [ruta, ruta + ".tmp", ruta + ".bak"]:
		if FileAccess.file_exists(r) or DirAccess.dir_exists_absolute(r):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	OS.execute("rm", ["-f", ProjectSettings.globalize_path(ruta + ".tmp")])

func estado(k: String) -> Dictionary:
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	for x in O:
		if x.k == k:
			return Datos.enteros(x).S
	return {}

# vuelve a cargar la partida guardada como CONTINUAR (sin el título)
func continuar() -> void:
	J.S = J.load_save()
	J.pending.clear()
	J.queued.clear()
	J.migrate()
	J.enter_game()

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-bugs.json"
	Juego.AJUSTES = "user://prueba-bugs-ajustes.json"
	Datos.CAL = true
	var D: Dictionary = Datos.carga()
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(J.nm(t))
	J.gancho_toast = func(_h, _ms): pass
	J.gancho_combate = func(_k): return "win"
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var G := Juego.GUARDADO
	var S0 := estado("casa-extr")
	J.S = S0.duplicate(true)
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"

	# E1 · el disco lleno: un .tmp que no se puede escribir entero no sustituye a la partida buena (aquí, el .tmp es /dev/full)
	borra(G)
	chk(J.save(), "E1: guardar")
	var bueno := FileAccess.get_file_as_string(G)
	OS.execute("ln", ["-sf", "/dev/full", ProjectSettings.globalize_path(G + ".tmp")])
	J.S.money = 12345
	var ok = J.save()
	OS.execute("rm", ["-f", ProjectSettings.globalize_path(G + ".tmp")])
	var sv = J.load_save()
	chk(not ok and sv is Dictionary and FileAccess.get_file_as_string(G) == bueno, "E1: con el disco lleno, la partida de antes (guardó %s, cargada %s)" % [ok, sv != null])
	J.S.money = S0.money
	chk(J.save() and FileAccess.file_exists(G + ".bak"), "E1: la copia .bak")

	# E2 · una partida guardada incompleta no se carga: sale la .bak
	escribe(G, JSON.stringify({"name": "rota", "map": "home"}))
	sv = J.load_save()
	chk(sv is Dictionary and J.partida_valida(sv) and sv.name == S0.name, "E2: la incompleta, con la .bak (%s)" % [sv.get("name") if sv is Dictionary else sv])
	escribe(G, "{\"name\":")
	sv = J.load_save()
	chk(sv is Dictionary and sv.name == S0.name, "E2: la cortada, con la .bak")

	# E3 · la casilla de la partida ocupada, en un interior bajo: a la casilla libre más cercana, dentro del mapa
	J.S = S0.duplicate(true)
	J.S.map = "shop"
	var sm: Dictionary = J.MAPS.shop
	var oc := Vector2i(-1, -1)
	for y in sm.h:
		for x in sm.w:
			if oc.x < 0 and J.tile_solid(sm, x, y) and x > 0 and y > 0 and x < sm.w - 1 and y < sm.h - 1:
				oc = Vector2i(x, y)
	J.S.x = oc.x
	J.S.y = oc.y
	J.enter_game()
	chk(J.P.x >= 0 and J.P.y >= 0 and J.P.x < sm.w and J.P.y < sm.h and not J.tile_solid(sm, J.P.x, J.P.y) and absi(J.P.x - oc.x) + absi(J.P.y - oc.y) <= 3,
		"E3: de %s a (%d, %d) en la tienda de %d × %d" % [oc, J.P.x, J.P.y, sm.w, sm.h])

	# E4 · la redada: lo que se lleva, antes del primer aviso (si se cierra la app a medias, no se repite ni se pierde);
	# y al salir con un guion a medias no se guarda
	J.S = S0.duplicate(true)
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	J.S.orden = J.S.day - 1
	J.S.protect = false
	J.S.pots[0] = {"sid": "ria", "prog": .5, "water": 80, "health": 100, "fert": false, "pest": false, "f": J.roll_feno("ria")}
	var co := func(): await J.raid_event()
	co.call()   # se para en el primer say
	var vacias := true
	for p in J.S.pots:
		vacias = vacias and p == null
	chk(J.S.orden == 0 and vacias and J.S.heat == D.CALOR_REDADA, "E4: la redada ya hecha al primer aviso (macetas vacías %s, calor %s)" % [vacias, J.S.heat])
	while J.handlers.size():
		J.handlers[-1].call("A")
		for k in 30:
			M.paso()
	borra(G)
	J.lock = 1
	chk(J.has_method("guarda_al_salir") and not J.guarda_al_salir() and not FileAccess.file_exists(G), "E4: con un guion a medias no se guarda al salir")
	J.lock = 0
	chk(J.has_method("guarda_al_salir") and J.guarda_al_salir() and FileAccess.file_exists(G), "E4: libre, sí")

	# E5 · el plazo vencido: el castigo, antes del primer aviso; guardado y cargado a medias, no se cuenta dos veces
	J.S = S0.duplicate(true)
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	J.S.due = 1000
	J.S.debt = 1000
	J.S.deadline = J.S.day - 1
	J.S.vencidos = 0
	co = func(): await J.penalty_event()
	co.call()
	var due1 = J.S.due
	chk(J.S.vencidos == 1 and J.S.due > 1000 and J.S.deadline > J.S.day, "E5: el castigo al primer aviso (vencidos %s, deuda %s)" % [J.S.vencidos, J.S.due])
	J.save()
	while J.handlers.size():
		J.handlers[-1].call("A")
		for k in 30:
			M.paso()
	continuar()
	chk(not J.queued.has("penalty") and J.S.vencidos == 1 and J.S.due == due1, "E5: cargado, no se cuenta dos veces (vencidos %s)" % J.S.vencidos)

	# E6 · en un combate no se guarda al salir
	J.S = S0.duplicate(true)
	J.enter_map("home", 5, 5, "up")
	J.mode = "battle"
	borra(G)
	chk(J.has_method("guarda_al_salir") and not J.guarda_al_salir() and not FileAccess.file_exists(G), "E6: en combate no se guarda")
	J.mode = "world"

	# E7 · los avisos en cola se guardan con la partida
	J.S = S0.duplicate(true)
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	J.pending.clear()
	J.queued.clear()
	var o := {"r": J.S.day + int(D.RECIBO.aviso)}
	J.cobra(o, 300, "BANCO", true, "Prueba")
	J.queue("plazo", J.recuerdo_plazo)
	chk(J.pending.size() == 2, "E7: dos avisos en cola")
	J.save()
	continuar()
	chk(J.queued.has("avPrueba") and J.queued.has("plazo"), "E7: los avisos, al cargar (%s)" % [J.queued.keys()])
	LOG = []
	J.S.due = 500
	J.S.deadline = J.S.day + 3
	corre(func(): pass)
	chk(" ".join(LOG).contains("recibo de Prueba"), "E7: el aviso del recibo sale: %s" % [LOG])

	# E8 · importar: los tipos y los rangos de cada clave
	var b0 := S0.duplicate(true)
	chk(J.partida_valida(b0), "E8: la buena vale")
	for mal in [{"money": "x"}, {"carpas": {}}, {"min": 480.5}, {"day": -3}, {"pots": "nada"}]:
		var b := S0.duplicate(true)
		b.merge(mal, true)
		chk(not J.partida_valida(b), "E8: no vale %s" % [mal])
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var malas := []
	for x in O:
		var s = Datos.enteros(x).S
		if s is Dictionary and s.get("name") is String and not J.partida_valida(s):
			malas.append(x.k)
	chk(malas.is_empty(), "E8: las partidas de las pantallas valen: %s" % [malas])

	# E9 · importar no lee el portapapeles solo: botón PEGAR, caja de texto de varias líneas y tope
	var src := FileAccess.get_file_as_string("res://src/juego.gd")
	var ini := src.find("func importar(")
	var cuerpo := src.substr(ini, src.find("\nfunc ", ini + 10) - ini)
	chk(ini > 0 and not cuerpo.contains("clipboard_get"), "E9: importar no lee el portapapeles al abrir")
	chk(J.has_method("pegar_partida") and J.get("import_te") is TextEdit, "E9: PEGAR y una caja de varias líneas")

	# E10 · importar desde START no cambia la partida en caliente: al acabar los menús, como CONTINUAR
	J.S = S0.duplicate(true)
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	var otra := S0.duplicate(true)
	otra.name = "Otra"
	otra.money = 777
	var vieja = J.S
	J.gancho_pedir = func(_t, _i, _m, _c): return JSON.stringify(otra)
	QUIERO = ["Cargar"]
	var durante := {"S": null}
	corre(func():
		await J.importar(false)
		durante.S = J.S)
	J.gancho_pedir = Callable()
	chk(durante.S == vieja and J.S.name == "Otra" and J.S.money == 777, "E10: la de antes hasta cerrar los menús (durante %s, después %s)" % [durante.S.name if durante.S else null, J.S.name])

	# E11 · START cierra el móvil
	J.S = S0.duplicate(true)
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	var gm = J.gancho_menu
	J.gancho_menu = Callable()
	var res := {"i": 99}
	var cm := func(): res.i = await J.elegir_movil(["Mensajes", "Mapa"])
	cm.call()
	J.press("START")
	for k in 5:
		M.paso()
	chk(res.i == -1 and J.handlers.is_empty(), "E11: START cierra el móvil (%s)" % res.i)
	while J.handlers.size():
		J.handlers[-1].call("B")
	J.gancho_menu = gm

	# E12 · la factura de la luz no se lleva los céntimos
	J.S = S0.duplicate(true)
	J.S.money = 1000.75
	J.S.banco = 0
	J.S.min = 1400
	J.S.pots[0] = {"sid": "ria", "prog": .5, "water": 80, "health": 100, "fert": false, "pest": false, "f": J.roll_feno("ria")}
	var luz = Cultivo.avanza(J.S, 60)
	chk(luz > 0 and is_equal_approx(float(J.S.money), 1000.75 - float(luz)), "E12: luz %s, dinero %s" % [luz, J.S.money])

	# E13 · pop() quita su manejador, no el de arriba
	J.S = S0.duplicate(true)
	J.handlers.clear()
	var tt := func(): await J.type_text("Hola")
	tt.call()
	var otro := func(_b): pass
	J.handlers.append(otro)
	for k in 40:
		M.paso()
	chk(J.handlers.size() == 1 and J.handlers[0] == otro, "E13: queda el de arriba (%d manejadores)" % J.handlers.size())
	J.handlers.clear()

	# E14 · nada de «navegador» en lo que se ve
	var nav := []
	for f in DirAccess.get_files_at("res://src"):
		if f.ends_with(".gd") and FileAccess.get_file_as_string("res://src/" + f).contains("en este navegador"):
			nav.append(f)
	chk(nav.is_empty(), "E14: «en este navegador» en %s" % [nav])

	borra(G)
	for x in fallos:
		print("  FALLO ", x)
	print("bugs: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
