# Ribera Verde (Godot) — 1.39: la nevera de serie con 1 kg y el arcón congelador de la tienda online (5 kg más, llega al día
# siguiente). Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla nevera-dentro.
#   $GODOT --headless --path godot --script res://tests/nevera.gd   → «nevera: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Motor = preload("res://src/motor.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := ""
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
			print("  bloqueo: fin %s libre %s lock %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.lock, J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-nevera.json"
	Juego.AJUSTES = "user://prueba-nevera-ajustes.json"
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nevera-dentro":
			e = Datos.enteros(x)
	J = Juego.new()
	J.oraculo = true
	root.add_child(J)
	M = J.M
	J.show_title()
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var r: float = J.nevera_r()
	# 1 · de serie, 1 kg
	chk(J.nevera_cap() == 1000.0, "cap de serie %s" % J.nevera_cap())
	chk(J._hueco_alm(false) == floor((1000.0 - r) * 10 + 1e-9) / 10.0, "hueco de serie %s" % J._hueco_alm(false))
	var A := {"t": "nevera", "i": 1}
	chk(J.desc_almacen(A).contains("de 1000 ("), "visor de serie: " + J.desc_almacen(A))
	# los botes, a 40 g: el de 8 g, por debajo de la mitad
	chk(float(J.D.NEVERA.bote) == 40.0, "bote %s" % J.D.NEVERA.bote)
	# 2 · la tienda online: la fila del arcón, sin dinero no pasa
	J.S.banco = 100
	QUIERO = "Arcón congelador"
	chk(corre(J.tienda_online), "tienda bloqueada (sin dinero)")
	chk(MENUS.size() and MENUS[0].has("Arcón congelador"), "sin fila del arcón: %s" % [MENUS])
	chk(J.S.nevera.get("arcon") == null, "pedido sin dinero")
	# con dinero: pedido, cobrado de la cuenta y marcado
	J.S.banco = 1000
	MENUS = []
	QUIERO = "Arcón congelador"
	chk(corre(J.tienda_online), "tienda bloqueada")
	var p: float = J.D.NEVERA.arcon.p
	chk(J.S.banco == 1000 - p, "cobro %s" % J.S.banco)
	chk(int(J.S.nevera.get("arcon", 0)) == -(int(J.S.day) + 1), "pedido %s" % J.S.nevera.get("arcon"))
	chk(MENUS.size() >= 2 and MENUS[1].has("Arcón congelador · pedido"), "fila pedida: %s" % [MENUS])
	chk(J.nevera_cap() == 1000.0, "cap antes de llegar %s" % J.nevera_cap())
	# 3 · hoy no llega; mañana, sí
	J.llega_mueble()
	chk(J.S.nevera.arcon != 1, "llega el mismo día")
	J.S.day += 1
	LOG = []
	chk(corre(func(): J.llega_mueble()), "llegada bloqueada")
	chk(J.S.nevera.arcon == 1, "no llega: %s" % J.S.nevera.arcon)
	chk(J.nevera_cap() == 6000.0, "cap con el arcón %s" % J.nevera_cap())
	chk(" ".join(LOG).contains("6 kg"), "aviso: %s" % [LOG])
	chk(J._hueco_alm(false) == floor((6000.0 - r) * 10 + 1e-9) / 10.0, "hueco con el arcón %s" % J._hueco_alm(false))
	chk(J.desc_almacen(A).contains("de 6000 ("), "visor con el arcón: " + J.desc_almacen(A))
	# 4 · ya en casa: la fila, sin comprar otra; la redada vacía la nevera, el arcón se queda
	MENUS = []
	J.S.banco = 1000
	chk(corre(J.tienda_online), "tienda bloqueada (en casa)")
	chk(MENUS.size() and MENUS[0].has("Arcón congelador · en casa") and J.S.banco == 1000, "en casa: %s" % [MENUS])
	J.S.nevera.rosin = {}
	chk(J.nevera_cap() == 6000.0, "tras vaciarla %s" % J.nevera_cap())
	# 5 · guardada y cargada, sigue (el JSON da 1.0)
	var S2 = JSON.parse_string(JSON.stringify(J.S))
	J.S = S2
	chk(J.nevera_cap() == 6000.0, "tras cargar %s" % J.nevera_cap())
	for x in fallos:
		print("  FALLO ", x)
	print("nevera: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
