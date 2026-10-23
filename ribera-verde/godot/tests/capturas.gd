# Landrace Hunters (Godot) — las capturas de la ficha de Google Play (fase 2 del plan): 8 escenas de tests/pantallas.json pintadas
# por el juego de verdad con Datos.PLAY (los textos de la versión de la tienda), a 320 × 180 y escaladas ×6 sin suavizar → 1920 × 1080;
# y el gráfico destacado: el título a 342 × 180, ×3 y recortado a 1024 × 500. No es una prueba: tools/tests.sh no la corre.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --script res://tests/capturas.gd --
#     --sin-arranque --salida <dir>   → «capturas: 9 imágenes en <dir>»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

# sin cogollos en primer plano (U12): el título, el piso, la calle, la nave, un club, el pueblo, el puerto y un combate
const ESCENAS := ["titulo-400", "casa-a", "calle-plaza", "nave2", "club-ibar", "mendialde", "puerto-tarde", "combate-ladron"]

var J

func _initialize() -> void:
	Datos.PLAY = true
	Datos.CAL = false   # los estados de pantallas.json son del HTML congelado: «día N»
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func _corre() -> void:
	var dir := arg("--salida")
	if dir == "":
		print("uso: … --script res://tests/capturas.gd -- --sin-arranque --salida <dir>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(dir)
	Datos.carga()
	Juego.GUARDADO = "user://prueba-capturas.json"
	Juego.AJUSTES = "user://prueba-capturas-ajustes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.AJUSTES))
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.set_process(false)
	J.pintor.ambiente_on = false
	var tot := 0
	var trabajos := []
	for i in ESCENAS.size():
		trabajos.append([ESCENAS[i], 320, 6, "captura-%d-%s.png" % [i + 1, ESCENAS[i]]])
	trabajos.append(["titulo-400", 342, 3, "destacado-1024x500.png"])
	for t in trabajos:
		var e: Dictionary = {}
		for x in O:
			if x.k == t[0]:
				e = Datos.enteros(x)
		e.sw = t[1]
		monta(e)
		J.pintor.redibuja(float(e.now))
		for n in 3:
			await RenderingServer.frame_post_draw
		var im: Image = J.sv.get_texture().get_image()
		im.convert(Image.FORMAT_RGBA8)
		im.resize(im.get_width() * t[2], im.get_height() * t[2], Image.INTERPOLATE_NEAREST)
		if t[3].begins_with("destacado"):
			im = im.get_region(Rect2i((im.get_width() - 1024) / 2, (im.get_height() - 500) / 2, 1024, 500))
		if t[0].begins_with("titulo"):
			im = await rotulo(im)
		im.convert(Image.FORMAT_RGB8)
		im.save_png(dir.path_join(t[3]))
		print("  %s %s" % [t[3], im.get_size()])
		tot += 1
	print("capturas: %d imágenes en %s" % [tot, dir])
	J.queue_free()
	quit(0)

# el rótulo del título (como _pinta_titulo en ui.gd) sobre la calle, en su SubViewport
func rotulo(im: Image) -> Image:
	var sv := SubViewport.new()
	sv.size = im.get_size()
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(im)
	sv.add_child(tr)
	var c := Control.new()
	c.size = Vector2(im.get_size())
	sv.add_child(c)
	var ui = J
	c.draw.connect(func():
		c.draw_rect(Rect2(0, 0, c.size.x, c.size.y), Color(0, 0, 0, .35))
		var f: Font = ui.display
		var k := c.size.x / 1024.0   # medido en el destacado (1024 × 500) y a escala en las capturas
		var s1 := roundi(64 * k)
		var y := 70.0 * k + (c.size.y - 500 * k) / 2
		for t1 in ["LANDRACE", "HUNTERS"]:
			y += 80 * k
			var x: float = (c.size.x - f.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1).x) / 2
			c.draw_string(f, Vector2(x + 9 * k, y + 9 * k), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("#10301c"))
			c.draw_string(f, Vector2(x + 4.5 * k, y + 4.5 * k), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("#2a7a40"))
			c.draw_string(f, Vector2(x, y), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color("#ffe680"))
		var n: Font = ui.negrita
		var l: String = ui.LEMA
		var s2 := roundi(30 * k)
		y += 64 * k
		var x2: float = (c.size.x - n.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, s2).x) / 2
		c.draw_string(n, Vector2(x2 + 3 * k, y + 3 * k), l, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color("#10301c"))
		c.draw_string(n, Vector2(x2, y), l, HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color("#9cf0a8")))
	for k in 3:
		await RenderingServer.frame_post_draw
	var r := sv.get_texture().get_image()
	sv.queue_free()
	return r

# como en tests/pantallas.gd
func monta(e: Dictionary) -> void:
	J.SW = int(e.sw)
	J.sv.size = Vector2i(J.SW, J.SH)
	J.S = e.S
	J.B = e.B
	J.VC = e.VC
	J.TIRO = e.get("TIRO")
	J.MESA_B = e.get("MESA_B")
	J.ALMACEN = e.get("ALMACEN")
	J.ORDEN = e.get("ORDEN")
	J.vfx = e.vfx
	J.ents = []
	if e.mode == "world" or e.mode == "carpa":
		J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
		for x in e.ents:
			for o in J.ents:
				if o.id == x.id:
					for c in x:
						o[c] = x[c]
		J.SOSP = e.SOSP
	for c in e.P:
		J.P[c] = e.P[c]
	J.mode = e.mode
