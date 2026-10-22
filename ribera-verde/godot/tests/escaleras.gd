# Landrace Hunters (Godot) — el paso subterráneo de Zorroza (lo pidió el usuario: «los pasos a nivel para pasar encima de las vías
# tienen que estar… O escaleras, que bajes unas escaleras y aparezcas en las del otro lado, sin cambiar el mapa. Mejor que lo del
# ascensor. Me gusta más. Porque además en la estación de tren de Zorroza el ascensor no funciona»), con Datos.CAL: las vías no se
# cruzan andando; tres bocas de escalera (andén de la vía ancha, andén de la vía estrecha, la ría); andando a la derecha hacia una,
# eliges a qué lado sales, bajas hundiéndote por los peldaños, fundido y, en el mismo mapa, subes por la otra boca hasta su entrada;
# el ascensor, averiado. Sin CAL, las vías se pisan como antes.
#   $GODOT --headless --path godot --script res://tests/escaleras.gd   → «escaleras: N comprobaciones, 0 fallos»
#   (con xvfb y opengl3, `-- --pintar <dir>`: esc-<n>.png, la bajada y la subida fotograma a fotograma)
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var HONDO := []   # lo hundido en cada fotograma de la escalera
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func arg(k: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else ""

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

# de pie en (x, y), un paso a la derecha: hasta que acaba lo que dispare
func empuja(x: int, y: int, d := "right") -> bool:
	J.enter_map("zorroza", x, y, d)
	J.mode = "world"
	HONDO = []
	J.try_move(d)
	var t0: float = M.reloj
	while J.P.moving or J.ESC != null or not J.is_free() or not J.pending.is_empty():
		if J.ESC != null:
			HONDO.append(int(J.ESC.h))
		if M.reloj - t0 > 30000 or not M.paso():
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-escaleras.json"
	Juego.AJUSTES = "user://prueba-escaleras-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.S.ch = 9
	J.S.erase("veh")
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	J.enter_map("zorroza", 12, 14, "down")
	var m: Dictionary = J.MAPS.zorroza
	# 1 · el mapa: sin pasos a nivel; las tres bocas de 2 casillas con su entrada libre; las vías, cerradas al paso
	var g := {}
	for fila in m.g:
		for t in fila:
			g[t] = true
	chk(not g.has("viaX") and not g.has("viaEX") and g.has("via") and g.has("viaE"), "sin pasos a nivel, con las dos vías")
	var bocas: Array = m.get("escaleras", [])
	chk(bocas.size() == 3, "tres bocas: %s" % [bocas])
	for b in bocas:
		var x := int(b.x)
		var y := int(b.y)
		chk(m.o[y][x] == "escZ" and m.o[y][x + 1] == "escZ2", "la boca (%d, %d), de 2 casillas" % [x, y])
		chk(not J.tile_solid(m, x - 1, y), "la entrada de (%d, %d), libre" % [x, y])
		chk(String(b.n) != "", "la boca (%d, %d) dice a dónde va" % [x, y])
	chk(J.tile_solid(m, 18, 20) and J.tile_solid(m, 18, 23), "las vías no se pisan")
	var asc := []
	for y in int(m.h):
		for x in int(m.w):
			if m.o[y][x] == "ascensorZ":
				asc.append(Vector2i(x, y))
	chk(asc.size() == 1 and m.o[asc[0].y][asc[0].x + 1] == "ascensorZ2", "el ascensor, de 2 casillas: %s" % [asc])
	# 2 · andando hacia las vías, no se cruza
	chk(empuja(18, 19, "down") and J.P.y == 19, "contra la vía, quieto (%d, %d)" % [J.P.x, J.P.y])
	# 3 · por la escalera: del andén de arriba al de la vía estrecha, eligiendo; en el mismo mapa, en su entrada, mirando a la izquierda
	var b0: Dictionary = bocas[0]
	QUIERO = ["Al andén de la vía estrecha"]
	MENUS = []
	chk(empuja(int(b0.x) - 1, int(b0.y)), "la bajada acaba")
	chk(MENUS.size() == 1 and MENUS[0].size() == 3, "a qué lado: las otras dos y «Nada» (%s)" % [MENUS])
	chk(J.S.map == "zorroza" and J.P.x == int(bocas[1].x) - 1 and J.P.y == int(bocas[1].y) and J.P.dir == "left", "sale por la boca del andén de la vía estrecha (%d, %d, %s)" % [J.P.x, J.P.y, J.P.dir])
	chk(J.S.x == J.P.x and J.S.y == J.P.y and J.P.px == J.P.x * 16.0 and J.P.py == J.P.y * 16.0 and not J.P.moving and J.ESC == null, "de pie y quieto al acabar")
	var mx: int = HONDO.max() if HONDO.size() else 0
	chk(mx == J.ESC_HONDO and HONDO[0] <= 2 and HONDO[-1] <= 2, "baja hundiéndose hasta %d px y sube (%d → %d → %d)" % [J.ESC_HONDO, HONDO[0] if HONDO.size() else -1, mx, HONDO[-1] if HONDO.size() else -1])
	# 4 · de vuelta y a la ría; «Nada», sin moverse
	QUIERO = ["A la ría"]
	chk(empuja(int(bocas[1].x) - 1, int(bocas[1].y)) and J.P.y == int(bocas[2].y), "del andén de abajo, a la ría (%d)" % J.P.y)
	QUIERO = ["Nada"]
	chk(empuja(int(bocas[2].x) - 1, int(bocas[2].y)) and J.P.x == int(bocas[2].x) - 1 and J.P.y == int(bocas[2].y) and HONDO.is_empty(), "«Nada»: se queda arriba")
	# 5 · el ascensor no funciona; la escalera dice por dónde se baja
	LOG = []
	var st := {"f": false}
	var co := func():
		await J.run(func(): await J.object_action(asc[0].x, asc[0].y))
		st.f = true
	co.call()
	while not st.f:
		M.paso()
	chk(" ".join(LOG).contains("no funciona"), "el ascensor: %s" % [LOG])
	# 6 · el plano de cerca, fotograma a fotograma
	var dir := arg("--pintar")
	if dir != "":
		await pinta(dir, bocas)
	# 7 · sin CAL, las vías se pisan y no hay escalera
	Datos.CAL = false
	chk(not J.tile_solid(m, 18, 20), "sin CAL, la vía se pisa")
	Datos.CAL = true
	_fin()

# la bajada y la subida, a la vez que el juego (con la cámara del juego)
func pinta(dir: String, bocas: Array) -> void:
	J.oraculo = false
	var b: Dictionary = bocas[0]
	J.enter_map("zorroza", int(b.x) - 1, int(b.y), "right")
	J.mode = "world"
	QUIERO = ["Al andén de la vía estrecha"]
	var k := 0
	var t0 := Time.get_ticks_msec()
	await foto(dir, k)
	J.try_move("right")
	while Time.get_ticks_msec() - t0 < 6000:
		for i in 6:
			await process_frame
		k += 1
		await foto(dir, k)
		if J.is_free() and J.ESC == null and k > 3:
			break
	await foto(dir, k + 1)
	J.oraculo = true

func foto(dir: String, k: int) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("esc-%02d.png" % k))

func _fin() -> void:
	print("escaleras: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
