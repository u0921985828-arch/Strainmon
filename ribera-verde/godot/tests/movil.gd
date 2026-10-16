# Ribera Verde (Godot) — 1.51: la pantalla del móvil con sus aplicaciones (lo pidió el usuario: «cuando le das al móvil no aparece
# ningún icono… que fuese una pantalla de un móvil, con el diseño del juego, estilo a cuando abres la caja fuerte»; movil.py, con CAL).
#   $GODOT --headless --path godot --script res://tests/movil.gd   → «movil: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también movil-*.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
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

func foto(dir: String, k: String) -> void:
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("movil-%s.png" % k))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-movil.json"
	Juego.AJUSTES = "user://prueba-movil-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	S.ch = maxi(int(S.ch), 6)
	S.flags.kiko1 = true
	S.sms = [{"de": "Kiko", "t": "Hola"}, {"de": "Toño", "t": "Ojo"}]
	var ops := ["Llamar", "Pedir a Kiko", "Mensajes", "Gente", "Plantilla", "Banca", "Tienda online", "Calendario", "Mapa"]
	# 1 · cada aplicación con su icono a mano
	for o in ops:
		chk(J.APP_MOVIL.has(o) and Atlas.foto_misc("mv-" + J.APP_MOVIL[o]) != null, "el icono de %s" % o)
	chk(Atlas.foto_misc("mv-movil") != null and Atlas.foto_misc("mv-movil").c.get_width() == 80, "la carcasa, 80 px")
	# 2 · la rejilla de 3 × 3: flechas sin salirse
	var V := {"ops": ops, "i": 0}
	chk(not J.mueve_movil(V, "left") and not J.mueve_movil(V, "up"), "en la esquina no se sale")
	chk(J.mueve_movil(V, "right") and V.i == 1 and J.mueve_movil(V, "down") and V.i == 4, "derecha y abajo (%d)" % V.i)
	V.i = 8
	chk(not J.mueve_movil(V, "down") and not J.mueve_movil(V, "right"), "en la última no se sale")
	# 3 · lo que se pinta: la carcasa, un icono por aplicación, el aviso de los SMS y el marco del elegido
	V.i = 2
	var R: Array = J.rects_movil(V)
	var spr := R.filter(func(r): return typeof(r[0]) == TYPE_STRING).map(func(r): return r[1])
	chk(spr.has("mv-movil") and ops.all(func(o): return spr.has("mv-" + J.APP_MOVIL[o])), "los sprites: %s" % [spr])
	chk(R.any(func(r): return typeof(r[0]) != TYPE_STRING and r[4] == "#e03838"), "el aviso rojo de los mensajes")
	chk(R.any(func(r): return typeof(r[0]) != TYPE_STRING and r[4] == "#f8d040"), "el marco del elegido")
	var x0: int = (J.SW - 80) >> 1
	chk(R.all(func(r): return typeof(r[0]) == TYPE_STRING or (int(r[0]) >= x0 and int(r[0]) + int(r[2]) <= x0 + 80)), "todo dentro del móvil")
	chk(J.desc_movil(V).begins_with("Mensajes") and J.desc_movil(V).contains("2 mensajes"), "la descripción: %s" % J.desc_movil(V))
	# la ficha de la variedad (1.51): el grupo, la hoja y la lámina
	var Vf := {"l": ["thai", "rif"], "i": 0}
	chk(J.desc_ficha(Vf).begins_with("Sativa") and J.desc_ficha(Vf).contains("caídas"), "la ficha de la Thai: %s" % J.desc_ficha(Vf))
	Vf.i = 1
	chk(J.desc_ficha(Vf).begins_with("Índica") and J.rects_ficha(Vf).any(func(r): return r[4] == J.COLOR_GRUPO[4]), "la ficha del Afghani")
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
		J.enter_map("home", 4, 6, "up")
		J.mode = "world"
		J.MOVIL_V = {"ops": ops, "i": 2}
		J._dlg_fijo(J.desc_movil(J.MOVIL_V), "MÓVIL")
		await foto(dir, "pantalla")
		J.MOVIL_V = null
		for k in ["thai", "rif", "hawai"]:   # 1.51: la ficha de la variedad con su hoja (Genoteca)
			J.FICHA_V = {"l": [k], "i": 0}
			J._dlg_fijo(J.desc_ficha(J.FICHA_V), str(J.D.STRAINS[k].n).to_upper())
			await foto(dir, "ficha-" + k)
		J.FICHA_V = null
		J.set_process(true)
	print("movil: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
