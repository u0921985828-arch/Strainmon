# Ribera Verde (Godot) — la nave cerrada hasta alquilarla y por reformar (lo pidió el usuario: «cuando todavía no tienes la nave
# alquilada o comprada, no se debería poder abrir la puerta, como en los locales que no están alquilados… estaría bien que cuando
# lo vayas a alquilar, entres al local y por reformar»). Con CAL: la persiana no se abre sin alquilar (puerta_cerrada), Arrieta te
# la enseña por dentro (nave-r: sin muebles, con los trastos del último) y, al salir, te pregunta otra vez.
#   $GODOT --headless --path godot --script res://tests/nave_puerta.gd   → «nave_puerta: N comprobaciones, 0 fallos»
#   (con xvfb y opengl3, `-- --pintar <dir>`: la persiana delante y la nave por reformar)
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

func habla(q: Array) -> String:
	QUIERO = q
	LOG = []
	MENUS = []
	chk(corre(J.talk_nave), "bloqueo con %s" % [q])
	return " ".join(LOG)

func arg(k: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else ""

func pinta(k: String) -> void:
	var dir := arg("--pintar")
	if dir == "":
		return
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("nave-%s.png" % k))

func bld_nave(m: Dictionary) -> Dictionary:
	for b in m.blds:
		if b.id == "nave":
			return b
	return {}

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-nave-puerta.json"
	Juego.AJUSTES = "user://prueba-nave-puerta-ajustes.json"
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
	J.S.ch = 6
	J.S.erase("nave")
	J.S.money = 20000
	J.enter_map("valdehierro", 17, 8, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · sin alquilar, la persiana se queda echada aunque estés delante; los locales sin alquilar, igual
	var V: Dictionary = J.MAPS.valdehierro
	var b := bld_nave(V)
	chk(J.has_method("puerta_cerrada"), "puerta_cerrada")
	if not J.has_method("puerta_cerrada"):
		return _fin()
	chk(J.puerta_cerrada(V, b), "sin alquilar: cerrada")
	J.enter_map("valdehierro", 12, 7, "up")
	await pinta("persiana")
	J.enter_map("valdehierro", 17, 8, "up")
	chk(J.gate_cerrado("neg:valde") == not J.S.loc.has("valde"), "el taller sin alquilar: cerrado")
	Datos.CAL = false
	chk(not J.puerta_cerrada(V, b), "sin CAL, como antes")
	Datos.CAL = true
	# 2 · la nave por dentro, con Arrieta: sin muebles, con trastos; no se alquila nada ni se paga
	var t := habla(["Verla por dentro"])
	chk(MENUS.size() and MENUS[0].has("Verla por dentro"), "la opción: %s" % [MENUS])
	chk(J.S.map == "nave-r" and J.S.get("nave") == null and int(J.S.money) == 20000, "dentro sin alquilar: %s %s %s" % [J.S.map, J.S.get("nave"), J.S.money])
	await pinta("reformar")
	var R: Dictionary = J.MAPS.get("nave-r", {})
	var objs := []
	for fila in R.get("o", []):
		for o in fila:
			if o != null:
				objs.append(o)
	chk(objs.size() >= 6 and not objs.any(func(o): return str(o).begins_with("mesaN") or o in ["escritorio", "secadero", "estanteN", "carpaM"]), "por reformar: %s" % [objs])
	chk(R.get("exits", {}).has("6,7") and R.o[6][6] == null and R.o[6][7] == null, "la salida libre")
	var hechos := {}
	for y in R.h:   # cada trasto, con su texto
		for x in R.w:
			var o = R.o[y][x]
			if o == null or hechos.has(o):
				continue
			hechos[o] = 1
			LOG = []
			chk(corre(func(): await J.object_action(x, y)), "A en %s" % o)
			chk(LOG.size() > 0, "%s dice algo" % o)
	# 3 · al salir, Arrieta pregunta; alquilada, la persiana se abre
	QUIERO = ["Alquilarla"]
	MENUS = []
	J.enter_map("valdehierro", 12, 8, "down")
	chk(corre(func(): pass), "la cola al salir")
	chk(MENUS.size() and MENUS[0].has("Alquilarla"), "al salir, la oferta: %s" % [MENUS])
	chk(J.S.get("nave") != null and not J.puerta_cerrada(V, b), "alquilada: abierta")
	_fin()

func _fin() -> void:
	for x in fallos:
		print("  FALLO " + x)
	print("nave_puerta: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
