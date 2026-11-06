# Ribera Verde (Godot) — 1.57 (lo pidió el usuario: «cómo es la UI de las flechas y botones, se puede mejorar para que sean lo mejor
# para jugar con el móvil en horizontal, estudiando en qué zonas caen los dedos, por proporciones, preparado para Android, iOS y demás»).
# Con CAL, los mandos de geo_pulgar en seis móviles y tabletas (ppp y zona segura de verdad: muesca, isla, barra de inicio): en mm desde
# el canto, del tamaño del pulgar, sin pisarse, dentro de la zona segura y lejos de los cantos de los gestos. Sin CAL, geo_mandos.
#   xvfb + $GODOT --path godot --rendering-driver opengl3 --resolution 2600x1700 --script res://tests/mandos_geo.gd -- --sin-arranque [--pintar <dir>]
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var n := 0
var fallos := []

# nombre, ancho, alto (px), ppp, zona segura [izq, der, arriba, abajo] (px)
const MOVILES := [
	["android-20x9", 2400, 1080, 420.0, [110, 0, 0, 0]],
	["android-barato", 1600, 720, 270.0, [0, 0, 0, 0]],
	["iphone-15", 2556, 1179, 460.0, [177, 177, 0, 63]],
	["iphone-se", 1334, 750, 326.0, [0, 0, 0, 0]],
	["ipad-11", 2360, 1640, 264.0, [0, 0, 0, 40]],
	["tableta-android", 1920, 1200, 224.0, [0, 0, 0, 0]],
]

var ANTES := {}

func _initialize() -> void:
	_corre.call_deferred()

func chk(c: bool, t: String) -> void:
	n += 1
	if not c:
		fallos.append(t)

func _corre() -> void:
	var a := OS.get_cmdline_user_args()
	var dir := ""
	for i in a.size():
		if a[i] == "--pintar" and i + 1 < a.size():
			dir = a[i + 1]
	Juego.GUARDADO = "user://prueba-mandos.json"
	Juego.AJUSTES = "user://prueba-mandos-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.S.flags.llegada = true
	J.enter_map("town", 12, 10, "down")
	J.build_ents()
	J.mode = "world"
	J.hud.show()
	for cal in [false, true]:
		Datos.CAL = cal
		for m in MOVILES:
			J.DPI_PRUEBA = m[3]
			J.ZONA_PRUEBA = m[4].map(func(v): return float(v))
			get_root().size = Vector2i(m[1], m[2])
			J.ajusta()
			for k in 4:
				await process_frame
			var mm: float = m[3] / 25.4   # px por mm
			var nom: String = m[0]
			if not cal:   # lo de antes (geo_mandos), para comparar: los nuevos, nunca más pequeños
				ANTES[nom] = {"a": _r("A").size.x, "c": J.cruz.size.x, "s": _r("START").size.y}
			if cal:
				_mira(nom, m, mm)
				var ra: Dictionary = ANTES[nom]
				chk(_r("A").size.x >= ra.a - 1 and J.cruz.size.x >= ra.c - 1 and _r("START").size.y >= ra.s - 1, "%s: más grandes que antes (A %d ≥ %d px, cruz %d ≥ %d, START %d ≥ %d)" % [nom, _r("A").size.x, ra.a, J.cruz.size.x, ra.c, _r("START").size.y, ra.s])
				print("%s: A %.1f mm, cruz %.1f mm, START %.1f mm (antes %.1f, %.1f, %.1f)" % [nom, _r("A").size.x / mm, J.cruz.size.x / mm, _r("START").size.y / mm, ra.a / mm, ra.c / mm, ra.s / mm])
			if dir != "":
				await RenderingServer.frame_post_draw
				var im: Image = get_root().get_texture().get_image()
				im.save_png(dir.path_join("mandos-%s-%s.png" % ["nuevo" if cal else "antes", nom]))
	J.DPI_PRUEBA = 0.0
	J.ZONA_PRUEBA = []
	# en una ventana de escritorio (sin tacto: los de antes, geo_mandos) de cualquier forma, de 4:3 a 21:9: dentro, sin pisar el escenario de diálogos
	Datos.CAL = true
	J.dlg.show()
	for t in [Vector2i(1560, 720), Vector2i(2400, 1080), Vector2i(2520, 1080), Vector2i(1280, 960), Vector2i(1024, 768), Vector2i(2560, 1600), Vector2i(800, 600), Vector2i(1920, 1080)]:
		get_root().size = t
		J.ajusta()
		for k in 4:
			await process_frame
		var v := Rect2(Vector2.ZERO, Vector2(t))
		var zonas := [J.zona_cruz, J.zona_ab, _r("START"), _r("MOVIL"), _r("SONIDO")]
		chk(zonas.all(func(z): return v.encloses(z) and not z.intersects(J.ui_rect())) and not _r("MOVIL").intersects(J.zona_cruz) and not _r("MOVIL").grow(4).intersects(_r("START")),
			"ventana %dx%d: mandos dentro y fuera del escenario (%s · %s)" % [t.x, t.y, zonas, J.ui_rect()])
	J.dlg.hide()
	print("mandos_geo: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)

func _r(b: String) -> Rect2:
	return J.botones[b].get_global_rect()

func _mira(nom: String, m: Array, mm: float) -> void:
	var W: float = m[1]
	var H: float = m[2]
	var z: Array = m[4]
	var segura := Rect2(z[0], z[2], W - z[0] - z[1], H - z[2] - z[3])
	var cruz: Rect2 = J.cruz
	var A := _r("A")
	var B := _r("B")
	var todos := {"cruz": cruz, "A": A, "B": B, "START": _r("START"), "MOVIL": _r("MOVIL"), "SONIDO": _r("SONIDO")}
	# del tamaño del pulgar (en mm de verdad)
	chk(A.size.x / mm >= 9.0 and B.size.x / mm >= 9.0, "%s: A y B de %.1f mm (9 o más)" % [nom, A.size.x / mm])
	chk(cruz.size.x / 3 / mm >= 7.0, "%s: cada flecha de %.1f mm (7 o más: 44 pt de iOS, 48 dp de Android)" % [nom, cruz.size.x / 3 / mm])
	var f: float = J.pulgar_f
	chk(A.size.x / mm >= 11.0 and cruz.size.x / mm >= 23.5, "%s: grandes (A %.1f mm, cruz %.1f mm; f %.2f)" % [nom, A.size.x / mm, cruz.size.x / mm, f])
	# dentro de la zona segura y lejos de los cantos de los gestos (9 mm de los lados, 8 del de abajo)
	for k in todos:
		var r: Rect2 = todos[k]
		chk(segura.encloses(r), "%s: %s dentro de la zona segura" % [nom, k])
		if k != "SONIDO":
			chk(r.position.x / mm >= 8.9 and (W - r.end.x) / mm >= 8.9 and (H - r.end.y) / mm >= 7.9, "%s: %s lejos de los cantos (%.1f, %.1f, %.1f mm)" % [nom, k, r.position.x / mm, (W - r.end.x) / mm, (H - r.end.y) / mm])
	# sin pisarse, con aire entre medias (2 mm)
	var ks := todos.keys()
	for i in ks.size():
		for j in range(i + 1, ks.size()):
			chk(not todos[ks[i]].grow(2 * mm).intersects(todos[ks[j]]), "%s: %s y %s separados" % [nom, ks[i], ks[j]])
	# donde cae el pulgar: la cruz a unos 25 mm del canto y de 20 a 32 del borde de abajo; B y A en el arco del pulgar derecho
	var c := cruz.get_center()
	var hc: float = cruz.size.x / 2 / mm
	chk(c.x / mm >= 19 and c.x / mm <= maxf(31, 10 + hc) and (H - c.y) / mm >= 18 and (H - c.y) / mm <= maxf(34, 10 + hc), "%s: la cruz a %.1f mm del canto y %.1f del borde" % [nom, c.x / mm, (H - c.y) / mm])
	var ac := A.get_center()
	var bc := B.get_center()
	chk(bc.x < ac.x and bc.y > ac.y and (W - ac.x) / mm >= 12 and (W - ac.x) / mm <= maxf(26, 10 + A.size.x / 2 / mm), "%s: A más arriba y fuera, B más abajo y dentro (A a %.1f mm del canto)" % [nom, (W - ac.x) / mm])
	chk(ac.distance_to(bc) / mm >= 13 and ac.distance_to(bc) / mm <= 20 * maxf(1, f), "%s: A y B a %.1f mm (de 13 a %.0f)" % [nom, ac.distance_to(bc) / mm, 20 * maxf(1, f)])
	# el toque, en más sitio que el dibujo (y un dedo entre A y B, a uno de los dos)
	chk(J.zona_cruz.encloses(cruz) and J.zona_ab.encloses(A) and J.zona_ab.encloses(B) and J.mando_en((ac + bc) / 2) != "", "%s: las zonas de toque abarcan los mandos" % nom)
	chk(J.mando_en(A.get_center() + Vector2(A.size.x * .6, 0)) == "A", "%s: un toque un poco fuera de A es A" % nom)
	# START y MÓVIL se tocan enteros (la zona de A y B no se los come) y no pisan el recuadro del HUD
	for k in ["START", "MOVIL"]:
		var r: Rect2 = todos[k]
		chk(J.mando_en(r.get_center()) == k and J.mando_en(Vector2(r.get_center().x, r.end.y - 1)) == k, "%s: %s se toca entero" % [nom, k])
		chk(not J.hud.get_global_rect().intersects(r), "%s: %s fuera del HUD" % [nom, k])
