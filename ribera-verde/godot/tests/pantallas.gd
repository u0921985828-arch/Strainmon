# Ribera Verde (Godot) — C2 de las pantallas: cada escena de godot/tests/pantallas.json (la saca tools/godot-pantallas.js del HTML:
# el piso, la calle de día, de tarde y la hierba pisada, la tienda, el bar, la vista B de la carpa, la vista C en el lienzo ancho,
# los combates, el título y la intro) pintada por el juego de verdad (juego.gd → pinta.gd en su SubViewport de SW × 160) y
# comparada píxel a píxel con html-p-<escena>.png.
# Lo opaco (casillas, sprites, carpas, macetas, plantas, barras, bocadillos) tiene que salir igual. Lo que el canvas mezcla
# (sombras, la fila de delante en transparencia, la tarde y la noche, el antialias de los trazos, del agua del título, de la elipse
# y del cono, y la suma de las farolas y del cono) lo mezcla la GPU en coma flotante y el canvas en 8 bits: cada canal, como mucho
# a TOL (4; en la carpa, TOL_C, 5: la luz de la vista C, un «overlay», dobla la diferencia de 2 de la sombra de la maceta de
# delante, translúcida sobre la maceta translúcida, más 1 de su redondeo). Deja godot-p-*.png y dif-p-*.png (rojo: más de 1; amarillo: 1).
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --script res://tests/pantallas.gd --
#     --sin-arranque --pintar <dir con html-p-*.png> [--pantallas f.json]
#   → «C2 pantallas: N escenas, 0 diferencias»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

const TOL := 4
const TOL_C := 5

var J
var fallos: Array = []

func _initialize() -> void:
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func _corre() -> void:
	var dir := arg("--pintar")
	var f := arg("--pantallas", "res://tests/pantallas.json")
	var O = JSON.parse_string(FileAccess.get_file_as_string(f))
	if dir == "" or O == null:
		print("uso: … --script res://tests/pantallas.gd -- --sin-arranque --pintar <dir> [--pantallas f.json]")
		quit(2)
		return
	Juego.GUARDADO = "user://prueba-pantallas.json"
	Juego.AJUSTES = "user://prueba-pantallas-ajustes.json"   # los ajustes de serie, no los del que juega
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.AJUSTES))
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.set_process(false)
	J.pintor.ambiente_on = false
	var tot := 0
	for e0 in O:
		var e = Datos.enteros(e0)
		monta(e)
		J.pintor.redibuja(float(e.now))
		for n in 3:
			await RenderingServer.frame_post_draw
		var im: Image = J.sv.get_texture().get_image()
		im.convert(Image.FORMAT_RGBA8)
		var k: String = e.k
		im.save_png(dir.path_join("godot-p-%s.png" % k))
		var ref := Image.load_from_file(dir.path_join("html-p-%s.png" % k))
		ref.convert(Image.FORMAT_RGBA8)
		if ref.get_size() != im.get_size():
			fallos.append("%s: tamaño %s, HTML %s" % [k, im.get_size(), ref.get_size()])
			continue
		var dif := Image.create(im.get_width(), 160, false, Image.FORMAT_RGBA8)
		var n := 0
		var n2 := 0
		var mx := 0
		for y in 160:
			for x in im.get_width():
				var a := im.get_pixel(x, y)
				var b := ref.get_pixel(x, y)
				var d := maxi(absi(a.r8 - b.r8), maxi(absi(a.g8 - b.g8), absi(a.b8 - b.b8)))
				if d:
					n += 1
					mx = maxi(mx, d)
					if d > 1:
						n2 += 1
					dif.set_pixel(x, y, Color(1, 0, 0) if d > 1 else Color(1, 1, 0))
				else:
					dif.set_pixel(x, y, Color(b.r, b.g, b.b).darkened(.7))
		dif.save_png(dir.path_join("dif-p-%s.png" % k))
		print("%-18s SW %d · píxeles distintos %5d (más de 1: %5d) · diferencia máxima %d" % [k, im.get_width(), n, n2, mx])
		var tol := TOL_C if k.begins_with("carpa-c") else TOL
		if mx > tol:
			fallos.append("%s: diferencia máxima %d (> %d)" % [k, mx, tol])
		tot += 1
	for x in fallos:
		print("  FALLO ", x)
	print("C2 pantallas: %d escenas, %d diferencias" % [tot, fallos.size()])
	J.queue_free()
	quit(1 if fallos.size() else 0)

# el estado de la escena tal como lo tenía el HTML justo antes de pintar
func monta(e: Dictionary) -> void:
	J.SW = int(e.sw)
	J.sv.size = Vector2i(J.SW, 160)
	J.S = e.S
	J.B = e.B
	J.VC = e.VC
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
