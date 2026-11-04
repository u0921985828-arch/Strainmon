# Landrace Hunters (Godot) — (lo dijo el usuario: «La pantalla de inicio deja que desear además de que los
# textos no están centrados»): en la pantalla de título, el texto de cada botón queda centrado al píxel en su
# pastilla y no toca las flechas, y el velo deja leer el rótulo sobre la calle del fondo. Se mide en la
# imagen de verdad: los píxeles claros del texto dentro del rectángulo de cada botón.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --resolution 1560x720 --script res://tests/titulo_ui.gd -- [--salida <dir>]
extends SceneTree

const Datos = preload("res://src/datos.gd")

var J
var fallos := []

func _initialize() -> void:
	Datos.PLAY = true
	Datos.CAL = true
	_corre.call_deferred()

func espera(k: int) -> void:
	for i in k:
		await process_frame

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func check(que: String, ok: bool) -> void:
	print(("OK     " if ok else "FALLO  ") + que)
	if not ok:
		fallos.append(que)

func tecla(k: int, on: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = on
	Input.parse_input_event(e)

func _corre() -> void:
	var dir := arg("--salida")
	Datos.carga()
	var UI = load("res://src/ui.gd")
	var Juego = load("res://src/juego.gd")
	Juego.GUARDADO = "user://prueba-titui.json"
	UI.AJUSTES = "user://prueba-titui-ajustes.json"
	for f in [Juego.GUARDADO, UI.AJUSTES]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	J = load("res://juego.tscn").instantiate()
	root.add_child(J)
	await espera(10)
	for i in 900:
		await process_frame
		if J.mode == "title":
			break
	await espera(20)
	for j in 8:   # el aviso de edad y su pregunta
		if J.menu_box.visible and not J.dlg.visible:
			break
		tecla(KEY_Z, true)
		await espera(1)
		tecla(KEY_Z, false)
		await espera(20)
	await espera(10)
	check("el título abre su menú (%s)" % J.mode, J.mode == "title" and J.menu_box.visible)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
		img.save_png(dir.path_join("titulo.png"))
	var lista: Node = J.menu_col.get_child(0)
	var n := 0
	for b in lista.get_children():
		var r: Rect2 = b.get_global_rect()
		n += 1
		# los píxeles del texto: los claros (el texto es #e8f8ec sobre verde, o #10301c sobre amarillo)
		# por dentro del borde de la pastilla, que también es claro
		var m := 5
		var x0 := int(r.position.x) + m
		var x1 := int(r.end.x) - m
		var y0 := int(r.position.y) + m
		var y1 := int(r.end.y) - m
		# el texto del botón elegido es oscuro sobre amarillo; el de los demás, claro sobre verde oscuro
		var amarillo := 0
		var ax0 := x1
		var ax1 := x0
		var ay0 := y1
		var ay1 := y0
		for y in range(maxi(0, y0), mini(img.get_height(), y1)):
			for x in range(maxi(0, x0), mini(img.get_width(), x1)):
				var c: Color = img.get_pixel(x, y)
				if c.r > .8 and c.g > .7 and c.b < .7:
					amarillo += 1
					ax0 = mini(ax0, x)
					ax1 = maxi(ax1, x)
					ay0 = mini(ay0, y)
					ay1 = maxi(ay1, y)
		var sel: bool = amarillo > (x1 - x0) * (y1 - y0) / 8
		if sel:   # el relleno amarillo de la pastilla elegida, por dentro de su borde y su sombra
			x0 = ax0 + 2
			x1 = ax1 - 1
			y0 = ay0 + 2
			y1 = ay1 - 1
		var cols := {}
		var hay := 0
		for y in range(maxi(0, y0), mini(img.get_height(), y1)):
			for x in range(maxi(0, x0), mini(img.get_width(), x1)):
				var c: Color = img.get_pixel(x, y)
				var l: float = c.get_luminance()
				var es: bool = (l < .2) if sel else (l > .8 and c.b > .7 and c.r > .7)
				if es:
					hay += 1
					cols[x] = true
		if hay < 10:
			check("botón %d: se le ve el texto (%d píxeles)" % [n, hay], false)
			continue
		# en bloques de columnas seguidas: en el botón elegido, las flechas de los lados son dos bloques
		# aparte y el texto es el del medio
		var xs: Array = cols.keys()
		xs.sort()
		var bloques: Array = []
		for x in xs:
			if bloques.is_empty() or x > int(bloques[-1][1]) + 2:
				bloques.append([x, x])
			else:
				bloques[-1][1] = x
		# fuera los bloques pegados a los cantos: son las flechas ◀ ▶ del botón elegido, no el texto
		var zf: float = (8 + 2.5 + 2) * J.us
		var zi: float = r.position.x + zf
		var zd: float = r.end.x - zf
		var txt_b: Array = bloques.filter(func(b): return float(b[1]) >= zi and float(b[0]) <= zd)
		check("botón %d: el texto, separado de las flechas (%d de %d bloques)" % [n, txt_b.size(), bloques.size()], txt_b.size() >= 1)
		bloques = txt_b
		var izq: int = int(bloques[0][0])
		var der: int = int(bloques[-1][1])
		var centro := (izq + der) / 2.0
		var cb := r.get_center().x
		check("botón %d: el texto centrado en su pastilla (texto %.1f, pastilla %.1f)" % [n, centro, cb], absf(centro - cb) <= 2.0)
		var a: float = 2.5 * J.us + 8 * J.us
		check("botón %d: el texto no llega a las flechas (%d .. %d en %d .. %d)" % [n, izq, der, x0, x1], izq > r.position.x + a - 1 and der < r.end.x - a + 1)
	check("el título tiene sus botones (%d)" % n, n >= 3)
	print("titulo_ui: %d botones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() > 0 else 0)
