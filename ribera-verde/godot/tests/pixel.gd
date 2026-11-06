# Landrace Hunters (Godot) — 0.52 (lo pidió el usuario: «los sprites no son pixel perfect… tienen que ser cuadrados todos los píxeles»
# y «hay pestañas que aún tienen el aire que te dije ayer»). Con CAL, en seis móviles y en ventanas de escritorio:
#  · el mundo, a un número entero de píxeles de pantalla por píxel del juego (u) y la pantalla, del tamaño exacto SW × SH × u;
#  · la UI (cajas, retratos, iconos), también a un número entero (us), y el retrato, un múltiplo exacto de su dibujo;
#  · el lector (MIENTRAS ESTABAS FUERA, créditos…), del ancho y el alto de su texto con el margen de la caja si cabe, y a toda
#    pantalla con scroll si no;
#  · el cumpleaños, en rejilla (los meses de 3 en 3, los días de 7 en 7) en una caja de su tamaño, en el centro.
#   xvfb + $GODOT --path godot --rendering-driver opengl3 --resolution 2600x1700 --script res://tests/pixel.gd   → «pixel: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var n := 0
var fallos := []

const MOVILES := [
	["android-20x9", 2400, 1080, 420.0, [110, 0, 0, 0]],
	["android-barato", 1600, 720, 270.0, [0, 0, 0, 0]],
	["iphone-15", 2556, 1179, 460.0, [177, 177, 0, 63]],
	["iphone-se", 1334, 750, 326.0, [0, 0, 0, 0]],
	["ipad-11", 2360, 1640, 264.0, [0, 0, 0, 40]],
	["tableta-android", 1920, 1200, 224.0, [0, 0, 0, 0]],
	["escritorio-960", 960, 720, 0.0, []],
	["escritorio-1080p", 1920, 1080, 0.0, []],
	["ventana-pequena", 640, 400, 0.0, []],
	["ventana-estrecha", 700, 900, 0.0, []],
]

func _initialize() -> void:
	_corre.call_deferred()

func chk(c: bool, t: String) -> void:
	n += 1
	if not c:
		fallos.append(t)

func entero(x: float) -> bool:
	return absf(x - roundf(x)) < .001

func espera(k: int) -> void:
	for i in k:
		await process_frame

func _corre() -> void:
	var a := OS.get_cmdline_user_args()
	var dir := a[a.find("--pintar") + 1] if a.find("--pintar") >= 0 else ""
	Juego.GUARDADO = "user://prueba-pixel.json"
	Juego.AJUSTES = "user://prueba-pixel-ajustes.json"
	Datos.CAL = true
	Datos.PLAY = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-a":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	await espera(3)
	J.S = e.S
	J.S.flags.llegada = true
	J.enter_map("home", 5, 5, "down")
	J.build_ents()
	J.mode = "world"
	J.hud.show()
	var corto := "Mientras estabas fuera:\n· 3 plantas regadas\n· 120 € de la caja\n· Kiko te ha escrito"
	var largo := ""
	for i in 60:
		largo += "Línea %d de un texto largo que no cabe en la pantalla y tiene que ir con scroll.\n" % i
	for m in MOVILES:
		J.DPI_PRUEBA = m[3]
		J.ZONA_PRUEBA = m[4].map(func(v): return float(v))
		root.size = Vector2i(m[1], m[2])
		J.ajusta()
		await espera(3)
		var nom: String = m[0]
		chk(entero(J.u) and J.u >= 1, "%s: el mundo a escala entera (u %.3f)" % [nom, J.u])
		chk(J.pantalla.size == Vector2(J.SW, J.SH) * J.u, "%s: la pantalla, %s = %d × %d × %.3f" % [nom, J.pantalla.size, J.SW, J.SH, J.u])
		chk(entero(J.us) and J.us >= 1, "%s: la UI a escala entera (us %.3f)" % [nom, J.us])
		chk(entero(J.pantalla.position.x) and entero(J.pantalla.position.y), "%s: la pantalla en un píxel entero %s" % [nom, J.pantalla.position])
		# el retrato de quien habla: un múltiplo exacto de su dibujo
		J.retrato.texture = ImageTexture.create_from_image(Image.create(64, 64, false, Image.FORMAT_RGBA8))
		J.retrato.show()
		J.dlg.show()
		J._coloca()
		await espera(2)
		var k: float = J.retrato.size.x / 64.0
		chk(entero(k) and k >= 1 and J.retrato.size.x == J.retrato.size.y, "%s: el retrato, %s (× %.3f)" % [nom, J.retrato.size, k])
		J.retrato.hide()
		J.dlg.hide()
		# el lector: corto, de su alto; largo, a toda altura
		var R: Rect2 = J.ui_rect()
		var lleno: float = R.size.y - 6 * J.us
		J.leer("MIENTRAS ESTABAS FUERA", corto)
		await espera(4)
		var hc: float = J.lector.size.y
		var tc: float = J.lector_txt.size.y
		chk(hc < lleno * .7 and hc >= tc, "%s: el lector corto, sin aire (%.0f de %.0f; texto %.0f)" % [nom, hc, lleno, tc])
		var aire: float = J.lector.size.y - tc
		chk(aire <= 40 * J.us, "%s: alrededor del texto, solo el margen (%.0f px = %.1f u)" % [nom, aire, aire / J.us])
		chk(J.lector.size.x < R.size.x - 6 * J.us - 1 and J.lector_txt.get_line_count() == corto.split("\n").size(), "%s: el lector corto, del ancho de su texto (%.0f de %.0f, %d líneas)" % [nom, J.lector.size.x, R.size.x, J.lector_txt.get_line_count()])
		chk(absf(J.lector.get_rect().get_center().x - R.get_center().x) <= 1 and absf(J.lector.get_rect().get_center().y - R.get_center().y) <= 1, "%s: en el centro" % nom)
		if dir != "" and nom == "android-20x9":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(dir.path_join("lector-corto.png"))
		chk(J.lector_sc.size.y + 1 >= J.lector_txt.get_combined_minimum_size().y, "%s: el texto corto, entero sin scroll" % nom)
		J.press("B")
		await espera(2)
		J.leer("LARGO", largo)
		await espera(4)
		if dir != "" and nom == "android-20x9":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(dir.path_join("lector-largo.png"))
		chk(absf(J.lector.size.y - lleno) < 1.5, "%s: el lector largo, a toda altura (%.0f de %.0f)" % [nom, J.lector.size.y, lleno])
		J.press("B")
		await espera(2)
		# y otra vez el corto, tras el largo (no se queda grande)
		J.leer("MIENTRAS ESTABAS FUERA", corto)
		await espera(4)
		chk(absf(J.lector.size.y - hc) < 1.5, "%s: el corto otra vez, igual (%.0f, antes %.0f)" % [nom, J.lector.size.y, hc])
		J.press("B")
		await espera(2)
		# el cumpleaños, en rejilla
		for g in [[3, 12, "EL MES"], [7, 31, "EL DÍA"]]:
			var its := []
			for i in g[1]:
				its.append("Septiembre" if g[0] == 3 and i == 8 else str(i + 1))
			var res := {"v": -9}
			var co := func(): res.v = await J.menu(its, {"cls": "centro", "cols": g[0], "cancel": false, "title": "TU CUMPLEAÑOS: " + g[2]})
			co.call()
			await espera(4)
			var mb: Rect2 = J.menu_box.get_rect()
			chk(mb.size.x <= R.size.x and mb.size.y < R.size.y * .8 and R.encloses(mb), "%s %s: la caja, de su tamaño (%s en %s)" % [nom, g[2], mb, R])
			chk(absf(mb.get_center().x - R.get_center().x) <= 1, "%s %s: en el centro" % [nom, g[2]])
			if dir != "" and nom == "android-20x9":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(dir.path_join("cumple-%d.png" % g[0]))
			for b in ["right", "down", "down", "left"]:
				J.press(b)
				await espera(1)
			J.press("A")
			await espera(2)
			chk(res.v == 2 * g[0], "%s %s: las flechas en la rejilla (%d, quiero %d)" % [nom, g[2], res.v, 2 * g[0]])
	print("pixel: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)
