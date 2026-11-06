# Landrace Hunters (Godot) — ni un bloque negro en el mapa pintado (lo vio el usuario: «¿Y ese pedazo de error en el mapa?» y «ahí en
# la iglesia también se ve como el sprite tiene un fondo negro»). Pinta cada mapa entero, trozo a trozo, y busca cuadros de 8 × 8
# píxeles negros puros: el suelo que no se pinta (una clave de g sin arte, o el hueco transparente del sprite de un edificio).
#   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 2600x1700x24" $GODOT --path godot --rendering-driver opengl3 \
#     --audio-driver Dummy --resolution 1560x720 --script res://tests/negro_render.gd -- --sin-arranque [--pintar <dir>]
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var n := 0
var fallos := []

const MAPAS := ["zorroza", "casco", "abando", "lapunta", "town", "alto", "puerto", "mendialde", "ibarbide", "ensanche",
	"valdehierro", "errotabarri", "astilleros", "muelle", "callejon", "comarcal", "metropoli",
	"catedral-in", "sannicolas-in", "iglesiaz-in", "mercado-in", "teatro-in", "home", "nave", "club-rv", "disco", "growcity"]

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# el mapa entero a una imagen, por trozos de pantalla (como tests/bilbao.gd)
func plano(k: String) -> Image:
	var m: Dictionary = J.MAPS[k]
	J.montar_aparcamiento(k)
	J.S.map = k
	J.mode = "world"
	J.ents = []
	var mw: int = int(m.w) * 16
	var mh: int = int(m.h) * 16
	var big := Image.create(mw, mh, false, Image.FORMAT_RGBA8)
	var sw: int = J.SW
	var xs := []
	var x := 0
	while true:
		xs.append(maxi(0, mini(x, mw - sw)))
		if x + sw >= mw:
			break
		x += sw
	var ys := []
	var y := 0
	while true:
		ys.append(maxi(0, mini(y, mh - 180)))
		if y + 180 >= mh:
			break
		y += 180
	for cy in ys:
		for cx in xs:
			J.P.px = cx - 8 + sw / 2.0
			J.P.py = cy - 8 + 90.0
			for q in 2:
				await process_frame
				J.pintor.redibuja(0.0)
				await RenderingServer.frame_post_draw
			var im: Image = J.sv.get_texture().get_image()
			im.convert(Image.FORMAT_RGBA8)
			# por la cámara de verdad: en un mapa más pequeño que la pantalla queda aire a los lados, que no es el mapa
			var c: Vector2i = J.pintor.cam
			var sx0: int = maxi(0, cx - c.x)
			var sy0: int = maxi(0, cy - c.y)
			var w0: int = mini(sw - sx0, mw - (sx0 + c.x))
			var h0: int = mini(180 - sy0, mh - (sy0 + c.y))
			if w0 > 0 and h0 > 0:
				big.blit_rect(im, Rect2i(sx0, sy0, w0, h0), Vector2i(sx0 + c.x, sy0 + c.y))
	return big

const LADO := 8   # un cuadro de 8 × 8 negros no sale de ningún sprite del juego; un agujero de suelo, sí

func negros(im: Image) -> Array:
	var r := []
	var y := 0
	while y < im.get_height() - LADO:
		var x := 0
		while x < im.get_width() - LADO:
			# el agujero es el fondo negro con el tinte de la hora encima: un cuadro liso y muy oscuro (de día, negro puro)
			var c0: Color = im.get_pixel(x, y)
			var todo: bool = c0.r + c0.g + c0.b <= 0.2
			if todo:
				for j in range(0, LADO, 2):
					for i in range(0, LADO, 2):
						if im.get_pixel(x + i, y + j) != c0:
							todo = false
							break
					if not todo:
						break
			if todo:
				r.append("(%d, %d)" % [x / 16, y / 16])
			x += 4
		y += 4
	return r

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-negro.json"
	Juego.AJUSTES = "user://prueba-negro-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for q in O:
		if q.k == "nave2":
			e = Datos.enteros(q)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.S.ch = 8
	J.S.min = 12 * 60
	J.S.flags.conce = true
	J.oraculo = false
	J.set_process(false)
	var dir := arg("--pintar")
	await process_frame
	for k in MAPAS:
		if not J.MAPS.has(k):
			continue
		J.enter_map(k, 1, 1, "right")
		var im: Image = await plano(k)
		if dir != "":
			im.save_png(dir.path_join("negro-%s.png" % k))
		var ng: Array = negros(im)
		chk(ng.is_empty(), "%s: %d cuadros negros en el suelo (%s)" % [k, ng.size(), ", ".join(ng.slice(0, 6))])
	for f in fallos:
		print("  ", f)
	print("negro_render: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
