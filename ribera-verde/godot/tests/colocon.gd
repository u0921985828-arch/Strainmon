# Landrace Hunters (Godot) — el colocón en la pantalla (lo pidió el usuario: «dependiendo del porcentaje de colocón… que la vista de
# la pantalla se hace más pequeña, con la forma ovalada de un ojo, y que se ve humo cuando fumas. Difuminado»), con Datos.CAL.
# ojo_k: de FISIO.efecto a FISIO.tope, de 0,1 a 1 (el ojo más cerrado); humo_k: 1 al fumar (colocar) y 0 a los HUMO_MS.
#   $GODOT --headless --path godot --script res://tests/colocon.gd   → «colocon: N comprobaciones, 0 fallos»
#   con pantalla (xvfb-run … --rendering-driver opengl3) y -- --pintar <dir>: colocon-<n>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
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
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
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
	Juego.GUARDADO = "user://prueba-colocon.json"
	Juego.AJUSTES = "user://prueba-colocon-ajustes.json"
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
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = J.D
	var S: Dictionary = J.S
	var F: Dictionary = D.FISIO
	S.erase("borr")
	S.erase("colo")
	S.erase("efe")
	J.mode = "world"
	# 1 · sin colocón, ni ojo ni humo ni filtro
	chk(J.ojo_k() == 0.0 and J.humo_k() == 0.0, "sin fumar, nada")
	J.vision_borracho()
	chk(J.pantalla.material == null, "sin filtro")
	# 2 · el ojo: por debajo de FISIO.efecto, abierto; de ahí a tope, cada vez más cerrado
	S.colo = float(F.efecto) - 1
	chk(J.ojo_k() == 0.0, "por debajo de %d, sin ojo" % int(F.efecto))
	var ant := 0.0
	for c in [F.efecto, 40, 60, 80, F.tope]:
		S.colo = float(c)
		chk(J.ojo_k() > ant, "a %d, más cerrado: %s" % [int(c), J.ojo_k()])
		ant = J.ojo_k()
	chk(is_equal_approx(J.ojo_k(), 1.0), "a tope, el ojo entero")
	J.vision_borracho()
	chk(J.pantalla.material is ShaderMaterial and J.vision_mat.shader.code.contains("uniform float ojo") and J.vision_mat.get_shader_parameter("ojo") == 1.0, "con el filtro del ojo")
	J.mode = "battle"
	chk(J.ojo_k() > 0.0, "en el combate, también el ojo (lo pidió el usuario)")
	J.mode = "world"
	# 3 · el humo: al fumar (colocar) sale entero y se va en HUMO_MS
	S.erase("colo")
	J.colocar("", 10)
	chk(J.humo_k() > 0.95, "al fumar, humo: %s" % J.humo_k())
	J.vision_borracho()
	chk(J.vision_mat.get_shader_parameter("humo") > 0.95, "el humo en el filtro")
	J.humo_ms = Time.get_ticks_msec() - J.HUMO_MS * 0.5
	chk(J.humo_k() > 0.4 and J.humo_k() < 0.6, "a la mitad, medio humo: %s" % J.humo_k())
	J.humo_ms = Time.get_ticks_msec() - J.HUMO_MS - 10
	chk(J.humo_k() == 0.0, "pasado el rato, sin humo")
	# 4 · capturas: abierto, a medias, a tope y con el humo
	var dir := ""
	var a := OS.get_cmdline_user_args()
	if a.find("--pintar") >= 0:
		dir = a[a.find("--pintar") + 1]
	if dir != "" and DisplayServer.get_name() != "headless":
		J.enter_map("home", 5, 5, "down")
		J.mode = "world"
		var casos := [[0.0, false], [45.0, false], [100.0, false], [60.0, true]]
		for i in casos.size():
			S.colo = casos[i][0]
			J.humo_ms = Time.get_ticks_msec() - (300 if casos[i][1] else 1e9)
			for f in 8:
				J.pintor.redibuja(M.reloj)
				J.vision_borracho()
				await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(dir.path_join("colocon-%d.png" % i))
	# 4b · en pixel art, como el juego (lo pidió el usuario: «los efectos… del mismo estilo que el juego»): el filtro sobre una
	# pantalla de 60 × 45 a 4 ×, cada píxel del juego de un solo color (sin degradados entre medias) y con pocos colores nuevos
	if DisplayServer.get_name() != "headless":
		var sh: Shader = load(a[a.find("--shader") + 1]) if a.find("--shader") >= 0 else J.VISION_SH
		var src := Image.create(60, 45, false, Image.FORMAT_RGBA8)
		var pal := [Color8(70, 120, 60), Color8(150, 110, 70), Color8(200, 190, 160), Color8(60, 70, 110)]
		for y in 45:
			for x in 60:
				src.set_pixel(x, y, pal[(x / 7 + y / 5) % pal.size()])
		var sv := SubViewport.new()
		sv.size = Vector2i(240, 180)
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(sv)
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(src)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.size = Vector2(240, 180)
		var mt := ShaderMaterial.new()
		mt.shader = sh
		tr.material = mt
		sv.add_child(tr)
		for caso in [[0.6, 0.0], [0.3, 1.0], [1.0, 0.7]]:
			mt.set_shader_parameter("ojo", caso[0])
			mt.set_shader_parameter("humo", caso[1])
			mt.set_shader_parameter("t", 3.7)
			for f in 3:
				await RenderingServer.frame_post_draw
			var im := sv.get_texture().get_image()
			im.convert(Image.FORMAT_RGBA8)
			var rotos := 0
			var cols := {}
			for by in 45:
				for bx in 60:
					var c0 := im.get_pixel(bx * 4, by * 4)
					cols[c0.to_html()] = 1
					for dy in 4:
						for dx in 4:
							if im.get_pixel(bx * 4 + dx, by * 4 + dy) != c0:
								rotos += 1
			chk(rotos == 0, "ojo %s humo %s: cada píxel del juego, de un color (%d sueltos)" % [caso[0], caso[1], rotos])
			chk(cols.size() <= 40, "ojo %s humo %s: pocos colores, sin degradados (%d)" % [caso[0], caso[1], cols.size()])
			if dir != "":
				im.resize(720, 540, Image.INTERPOLATE_NEAREST)
				im.save_png(dir.path_join("colocon-pixel-%s-%s.png" % caso))
		sv.queue_free()
	# 5 · sin CAL, nada
	Datos.CAL = false
	S.colo = 90.0
	J.humo_ms = Time.get_ticks_msec()
	chk(J.ojo_k() == 0.0 and J.humo_k() == 0.0, "sin CAL, como antes")
	Datos.CAL = true
	print("colocon: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  FALLO ", x)
	quit(1 if fallos.size() else 0)
