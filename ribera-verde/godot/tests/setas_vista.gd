# Ribera Verde (Godot) — 1.43.9: el bajo de las setas a la vista (lo pidió el usuario: «que puedas entrar al bajo y veas las setas
# crecer»): A en una estantería abre las tres baldas con sus seis bandejas dibujadas (el micelio que cubre el sustrato por días y
# horas, las setas que salen y abren, las gotas de la humedad, lo contaminado y lo seco) y la elegida en grande; flechas eligen,
# A abre lo de las bandejas y vuelve a las baldas, B cierra; sin Datos.CAL, el menú de antes.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla setas.
#   $GODOT --headless --path godot --script res://tests/setas_vista.gd   → «setas_vista: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también bajo-<caso>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var MENUS := []
var LOG := []
var TECLAS := []
var n := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	o = o.duplicate()
	o.initial = labels.size() - 1
	return o

# las teclas de la prueba, una por intervalo; sin teclas, A (los textos) y, en la vista, B
func _tecla() -> void:
	if not J.handlers.size():
		return
	if TECLAS.size():
		J.press(TECLAS.pop_front())
	else:
		J.press("B" if J.SETAS_V != null else "A")

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

func pinta(dir: String, k: String, V: Dictionary) -> void:
	J.SETAS_V = V
	J._dlg_fijo(J.desc_bajo(V), "EL BAJO")
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	var im: Image = root.get_texture().get_image()
	im.save_png(dir.path_join("bajo-%s.png" % k))
	J.SETAS_V = null

# lo blanco del micelio y lo alto de los tallos de una bandeja dibujada a u = 1
func mide(b) -> Array:
	var o := []
	J._bandeja_seta(o, b, 0, 0, 1, 7)
	var mic := 0
	var tallo := 0
	for r in o:
		if r[4] in ["#f0eee6", "#e0dcd0"]:
			mic += 1
		elif r[4] == "#e8e0d0":
			tallo += int(r[3])
	return [mic, tallo]

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-setas-vista.json"
	Juego.AJUSTES = "user://prueba-setas-vista-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "setas":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.enter_map("setas", int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	var S = J.S
	var Z: Dictionary = J.D.SETAS
	var dir := arg("--pintar")
	if dir != "":
		await process_frame
		J.set_process(false)
		await pinta(dir, "baldas", {"i": 0})   # la primera, dos veces: el cuadro del texto se coloca en el siguiente fotograma
		await pinta(dir, "baldas", {"i": 0})
		await pinta(dir, "contaminada", {"i": 3})
		await pinta(dir, "hueco", {"i": 5})
		# una bandeja, día a día: de recién hecha a lista
		var B0: Array = S.setas.bandejas
		for dd in [0, 2, 4, 6, 7, 8, 9, 10]:
			S.setas.bandejas = [{"d": S.day - dd, "hum": 80}]
			await pinta(dir, "dia%02d" % dd, {"i": 0})
		S.setas.bandejas = [{"d": S.day, "hum": 30, "mala": "seca"}]
		await pinta(dir, "seca", {"i": 0})
		S.setas.bandejas = B0
		J.set_process(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(_tecla, 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · las flechas: tres estanterías, abajo (2r) y arriba (2r + 1); no se sale por los bordes
	var V := {"i": 0}
	chk(J.mueve_bajo(V, "up") and V.i == 1, "arriba: %s" % V)
	chk(not J.mueve_bajo(V, "up") and V.i == 1, "por arriba no se sale")
	chk(J.mueve_bajo(V, "right") and V.i == 3 and J.mueve_bajo(V, "right") and V.i == 5, "a la derecha: %s" % V)
	chk(not J.mueve_bajo(V, "right") and J.mueve_bajo(V, "down") and V.i == 4, "borde derecho y abajo: %s" % V)
	chk(not J.mueve_bajo(V, "down") and J.mueve_bajo(V, "left") and V.i == 2, "abajo no se sale; izquierda: %s" % V)
	# 2 · los textos, por fase (pantalla setas: día 20, bandejas de los días 18, 12, 9, 8 contaminada y 15)
	chk(J.desc_bajo({"i": 0}).contains("micelio cubre el") and J.desc_bajo({"i": 0}).contains("día 3 de 10"), "colonizando: %s" % J.desc_bajo({"i": 0}))
	chk(J.desc_bajo({"i": 1}).contains("las setas crecen"), "fructificando: %s" % J.desc_bajo({"i": 1}))
	chk(J.desc_bajo({"i": 2}).contains("lista para recoger"), "lista: %s" % J.desc_bajo({"i": 2}))
	chk(J.desc_bajo({"i": 3}).contains("contaminada") and not J.desc_bajo({"i": 3}).contains("día "), "contaminada: %s" % J.desc_bajo({"i": 3}))
	chk(J.desc_bajo({"i": 5}).contains("Hueco libre") and J.desc_bajo({"i": 5}).contains("5 de 6"), "hueco: %s" % J.desc_bajo({"i": 5}))
	# 3 · se ve crecer: el micelio, día a día y hora a hora; los tallos, mientras fructifica; lista, como el último
	var m0 := 0
	var crece := true
	for dd in range(0, int(Z.colon) + 1):
		var r := mide({"d": S.day - dd, "hum": 80})
		if r[0] < m0:
			crece = false
		m0 = r[0]
	chk(crece and mide({"d": S.day, "hum": 80})[0] < mide({"d": S.day - Z.colon, "hum": 80})[0], "el micelio crece por días")
	var min0: int = S.min
	S.min = 0
	var a0: int = mide({"d": S.day - 2, "hum": 80})[0]
	S.min = 1439
	var a1: int = mide({"d": S.day - 2, "hum": 80})[0]
	S.min = min0
	chk(a1 > a0, "y por horas: %d → %d" % [a0, a1])
	var t0 := -1
	crece = true
	for dd in range(int(Z.colon), int(Z.colon + Z.fruto) + 1):
		var r := mide({"d": S.day - dd, "hum": 80})
		if r[1] < t0:
			crece = false
		t0 = r[1]
	chk(crece and mide({"d": S.day - Z.colon, "hum": 80})[1] < t0 and mide({"d": S.day - 1, "hum": 80})[1] == 0, "las setas crecen: %d" % t0)
	chk(mide({"d": S.day - 30, "hum": 80})[1] == t0, "lista: las setas enteras")
	chk(mide({"d": S.day - 8, "hum": 80, "mala": "contaminada"})[1] == 0 and mide({"d": S.day - 8, "hum": 0, "mala": "seca"})[0] == 0, "malas: sin setas ni micelio blanco")
	# 4 · las gotas, por la humedad
	var g := func(h):
		var o := []
		J._bandeja_seta(o, {"d": S.day - 2, "hum": h}, 0, 0, 1, 7)
		return o.filter(func(r): return r[4] == "rgba(225,242,255,0.75)").size()
	chk(g.call(100) > g.call(40) and g.call(0) == 0, "gotas: %d %d %d" % [g.call(100), g.call(40), g.call(0)])
	# 5 · las baldas: el marco amarillo, en la elegida
	var R: Array = J.rects_bajo({"i": 3})
	var am: Array = R.filter(func(r): return r[4] == "#f8d040")
	var x0: int = (J.SW - J.BAJO_W) >> 1
	chk(am.size() == 4 and am[0][0] == x0 + 4 + 46 + 3 - 2 and am[0][1] == 4 + 52 - 31 - 2, "marco de la 4.ª: %s" % [am.slice(0, 1)])
	# 6 · A en la estantería 1: la vista sale en su bandeja de abajo (2); A abre el menú de las bandejas y se vuelve; B cierra
	var vis := []
	J.gancho_bajo = func(i0):
		vis.append(i0)
		return 2 if vis.size() == 1 else null
	MENUS = []
	chk(corre(func(): await J.obj_local(1, 2, "baldaS")), "baldas bloqueadas")
	chk(vis == [2, 2], "la vista, en la bandeja 2 y de vuelta: %s" % [vis])
	chk(MENUS.size() >= 1 and MENUS[0].has("Pulverizar") and MENUS[0].has("Recoger"), "el menú de las bandejas: %s" % [MENUS])
	# 7 · la vista de verdad, con las teclas: derecha, arriba y A → la 3.ª de la segunda estantería (3), y luego un hueco
	J.gancho_bajo = Callable()
	TECLAS = ["right", "up", "A"]
	MENUS = []
	var r7 := {}
	chk(corre(func(): r7.v = await J.elegir_bajo(0)), "vista bloqueada")
	chk(r7.get("v") == 3 and J.SETAS_V == null, "elegida con las flechas: %s" % [r7])
	TECLAS = ["right", "right", "up", "A"]
	LOG = []
	chk(corre(func(): await J.vista_bajo(0)), "hueco bloqueado")
	chk(LOG.size() == 1 and LOG[0].contains("no hay bandeja") and MENUS.is_empty(), "hueco: %s %s" % [LOG, MENUS])
	# 8 · sin Datos.CAL (las pruebas contra el HTML): el menú de antes, sin vista
	Datos.CAL = false
	vis = []
	J.gancho_bajo = func(i0):
		vis.append(i0)
		return null
	MENUS = []
	chk(corre(func(): await J.obj_local(0, 2, "baldaS")), "sin CAL bloqueado")
	chk(vis.is_empty() and MENUS.size() == 1, "sin CAL: %s %s" % [vis, MENUS])
	Datos.CAL = true
	for x in fallos:
		print("  FALLO ", x)
	print("setas_vista: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
