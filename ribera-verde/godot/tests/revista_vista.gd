# Landrace Hunters (Godot) — EL ESQUEJE a la vista (lo pidió el usuario: «que los números se vean como revista, con portada y
# páginas dibujadas»). Solo Godot, con Datos.CAL. Comprueba el atlas del arte (tools/sprites/a-mano/revista.py), las planas de cada
# número (portada + una por sección, con su viñeta), el hueco del texto dentro del papel y, en la imagen de verdad, que la plana se
# pinta, que el texto del lector cae dentro del papel y que ◀ ▶ pasa de plana.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --resolution 1560x720 --script res://tests/revista_vista.gd -- [--salida <dir>]
extends SceneTree

const Datos = preload("res://src/datos.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
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
	n += 1
	if not ok:
		fallos.append(que)
		print("FALLO  " + que)

func _corre() -> void:
	var dir := arg("--salida")
	Datos.carga()
	var Juego = load("res://src/juego.gd")
	var UI = load("res://src/ui.gd")
	Juego.GUARDADO = "user://prueba-revvista.json"
	UI.AJUSTES = "user://prueba-revvista-ajustes.json"
	for f in [Juego.GUARDADO, UI.AJUSTES]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-a":
			e = Datos.enteros(x)
	J = Juego.new()
	J.oraculo = false
	root.add_child(J)
	await espera(5)
	J.ajustes_aplica()
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	await espera(5)
	_atlas()
	_planas()
	await _render(dir)
	print("revista_vista: %d comprobaciones, %d fallos%s" % [n, fallos.size(), (": " + "; ".join(fallos)) if fallos.size() else ""])
	quit(1 if fallos.size() else 0)

# ---------- el atlas del arte ----------
func _atlas() -> void:
	check("el atlas de la revista carga (arte/revista.png)", J.rev_art())
	var A: Dictionary = J.REV_ART
	for k in ["papel", "papel2", "mancheta", "filete", "filete2", "grapa", "dobl"]:
		check("el atlas trae %s" % k, A.has(k))
	for k in J.REV_VG.values():
		check("el atlas trae la viñeta vg-%s" % k, A.has("vg-" + k))
	for k in J.REV_ILU.values():
		check("el atlas trae la ilustración pt-%s" % k, A.has("pt-" + k))
	check("el atlas trae pt-planta y pt-carpa (los de reserva)", A.has("pt-planta") and A.has("pt-carpa"))
	if A.has("mancheta"):
		var mc: Image = A["mancheta"]
		check("la mancheta cabe en la plana (%d px)" % mc.get_width(), mc.get_width() <= J.rev_caja().size.x - 12)
	if A.has("papel"):
		check("el papel es tileable (64 × 64)", A["papel"].get_width() == 64 and A["papel"].get_height() == 64)

# ---------- las planas de cada número ----------
func _planas() -> void:
	for num in [1, 3, 7, 12, 25]:
		var rv: Dictionary = J.rev_paginas(num)
		var pags: Array = rv.pags
		var tit: Array = rv.tit
		var vg: Array = rv.vg
		check("n.º %d: más de una plana (%d)" % [num, pags.size()], pags.size() > 1)
		check("n.º %d: una cabecera y una viñeta por plana" % num, tit.size() == pags.size() and vg.size() == pags.size())
		check("n.º %d: la portada va primero, sin viñeta ni cabecera" % num, String(tit[0]) == "" and String(vg[0]) == "")
		check("n.º %d: la portada lleva su ilustración (%s)" % [num, rv.ilu], J.REV_ART.has("pt-" + String(rv.ilu)))
		var falta := []
		for i in range(1, pags.size()):
			if String(pags[i]).strip_edges() == "" or String(tit[i]) == "" or not J.REV_ART.has("vg-" + String(vg[i])):
				falta.append(i)
		check("n.º %d: ninguna plana vacía ni sin viñeta (%s)" % [num, falta], falta.is_empty())
		# el texto de las planas dice lo mismo que el número de siempre (nada se pierde por el camino)
		var ent: String = J.rev_texto(num)
		var fuera := []
		for q in J.rev_secciones(num):
			var t := String(q.tit)
			if t != "" and not ent.contains(t):
				fuera.append(t)
			if t != "" and not pags.any(func(x): return String(x).contains(String(q.txt).split("\n")[0])) and not tit.any(func(x): return String(x).begins_with(t)):
				fuera.append(t)
		check("n.º %d: las planas traen todas las secciones (%s)" % [num, fuera], fuera.is_empty())
		# el hueco del texto, dentro del papel y de la pantalla
		var c: Rect2i = J.rev_caja()
		check("n.º %d: la plana cabe en el lienzo (%s)" % [num, c], c.position.x >= 0 and c.end.x <= J.SW and c.position.y >= 0 and c.end.y <= J.SH)
		J.lector_rev = rv
		var malas := []
		for i in pags.size():
			J.lector_i = i
			var z: Rect2i = J.rev_zona()
			if not c.encloses(z) or z.size.x < 60 or z.size.y < 30:
				malas.append(i)
		check("n.º %d: el hueco del texto, dentro del papel (%s)" % [num, malas], malas.is_empty())
		# lo dibujado, dentro de la plana
		var fuera_r := []
		for i in pags.size():
			J.lector_i = i
			var l: Array = J.rects_revista()
			if l.is_empty():
				fuera_r.append(i)
				continue
			for e in l:
				if typeof(e[0]) == TYPE_STRING:
					if not c.intersects(Rect2i(int(e[2]), int(e[3]), (e[1] as Image).get_width(), (e[1] as Image).get_height())):
						fuera_r.append(i)
						break
					continue
				if not c.encloses(Rect2i(int(e[0]), int(e[1]), int(e[2]), int(e[3]))) and int(e[1]) != c.position.y - 1 and int(e[1]) != c.end.y:
					fuera_r.append(i)
					break
		check("n.º %d: nada dibujado fuera de la plana (%s)" % [num, fuera_r], fuera_r.is_empty())
		J.lector_rev = {}
		J.lector_i = 0

# ---------- la imagen de verdad ----------
func _render(dir: String) -> void:
	var num := 3
	var rv: Dictionary = J.rev_paginas(num)
	J.leer("EL ESQUEJE", J.rev_texto(num), rv)
	await espera(30)
	check("la revista abre el lector en modo revista", J.lector.visible and not J.lector_rev.is_empty())
	var c: Rect2i = J.rev_caja()
	var pl := Rect2(J.scr.position + Vector2(c.position.x * J.u, c.position.y * J.u), Vector2(c.size.x * J.u, c.size.y * J.u))
	check("el texto de la portada va dentro del papel", pl.grow(1).encloses(J.lector.get_global_rect()))
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
		img.save_png(dir.path_join("revista-portada.png"))
	check("el papel se pinta en las cuatro esquinas de la plana", _papel(img, pl))
	check("la plana no deja negro dentro", not _negro(img, pl))
	# ▶ pasa de plana: la viñeta de la sección cambia
	for i in 3:
		J.press("right")
		await espera(6)
	check("◀ ▶ pasa de plana (%d)" % J.lector_i, J.lector_i == 3)
	check("la plana 3 lleva su viñeta (%s)" % String(rv.vg[3]), String(rv.vg[3]) != "")
	await espera(10)
	check("el texto de la sección va dentro del papel", pl.grow(1).encloses(J.lector.get_global_rect()))
	await RenderingServer.frame_post_draw
	img = root.get_texture().get_image()
	if dir != "":
		img.save_png(dir.path_join("revista-seccion.png"))
	check("el papel se pinta también en la plana de la sección", _papel(img, pl))
	J.press("B")
	await espera(10)
	check("B cierra la revista y deja el lector como estaba", not J.lector.visible and J.lector_rev.is_empty())

# las cuatro esquinas de dentro de la plana, en papel (claro y cálido)
func _papel(img: Image, r: Rect2) -> bool:
	for p in [Vector2(r.position.x + 20, r.position.y + 3), Vector2(r.end.x - 6, r.position.y + 3),
			Vector2(r.position.x + 20, r.end.y - 4), Vector2(r.end.x - 6, r.end.y - 4)]:
		var x := clampi(int(p.x), 0, img.get_width() - 1)
		var y := clampi(int(p.y), 0, img.get_height() - 1)
		var c: Color = img.get_pixel(x, y)
		if c.r < .7 or c.g < .68 or c.b > c.r:
			return false
	return true

func _negro(img: Image, r: Rect2) -> bool:
	var x := int(r.position.x) + 4
	while x < int(r.end.x) - 4:
		var y := int(r.position.y) + 4
		while y < int(r.end.y) - 4:
			var c: Color = img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1))
			if c.r + c.g + c.b < .12:
				return true
			y += 7
		x += 7
	return false
