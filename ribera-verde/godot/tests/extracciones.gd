# Ribera Verde (Godot) — 1.38: la escena de cada extracción encima de su barra (escena_extr.gd). Sobre la escena tiro-lavadora de
# las pantallas, cada tipo y cada paso con TIRO.esc: tiene que pintarse (distinto de la barra sola) y moverse (distinto a otra hora).
# Deja ext-<tipo>-<paso>-<a|b>.png en --salida.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --script res://tests/extracciones.gd --
#     --sin-arranque --salida <dir>
#   → «extracciones: N escenas, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func foto(e: Dictionary, T, now: float) -> Image:
	J.TIRO = T
	J.pintor.redibuja(now)
	for n in 3:
		await RenderingServer.frame_post_draw
	var im: Image = J.sv.get_texture().get_image()
	im.convert(Image.FORMAT_RGBA8)
	return im

func _corre() -> void:
	var dir := arg("--salida")
	Juego.GUARDADO = "user://prueba-extr.json"
	Juego.AJUSTES = "user://prueba-extr-ajustes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.AJUSTES))
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "tiro-lavadora":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.set_process(false)
	J.pintor.ambiente_on = false
	J.SW = int(e.sw)
	J.sv.size = Vector2i(J.SW, J.SH)
	J.S = e.S
	J.B = e.B
	J.VC = e.VC
	J.vfx = e.vfx
	J.ents = []
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.SOSP = e.SOSP
	for c in e.P:
		J.P[c] = e.P[c]
	J.mode = e.mode
	var now: float = e.now
	var fallos := []
	var tot := 0
	for t in J.D.EXTR:
		var n: int = J.D.EXTR[t].pasos.size() + (1 if t == "seco" else 0)
		for i in n:
			var T: Dictionary = e.TIRO.duplicate()
			T.merge({"esc": t, "paso": i, "n": n, "per": J.D.EXTR[t].per, "mov": float(J.D.EXTR[t].get("mov", 0)), "ritmo": float(J.D.EXTR[t].get("ritmo", 0))}, true)
			var sin_esc: Dictionary = T.duplicate()
			sin_esc.erase("esc")
			var base: Image = await foto(e, sin_esc, now)
			var a: Image = await foto(e, T, now)
			var b: Image = await foto(e, T, now + 1730)
			a.save_png(dir.path_join("ext-%s-%d-a.png" % [t, i]))
			b.save_png(dir.path_join("ext-%s-%d-b.png" % [t, i]))
			if a.get_data() == base.get_data():
				fallos.append("%s %d: no se pinta" % [t, i])
			if a.get_data() == b.get_data():
				fallos.append("%s %d: no se mueve" % [t, i])
			if load("res://src/escena_extr.gd").pl("%s-%d" % [t, i]) == null:   # de PixelLab (lo pidió el usuario: «con esta calidad»)
				fallos.append("%s %d: sin su escena de PixelLab" % [t, i])
			tot += 1
	for k in ["manos", "epi", "auto", "flujo", "micro", "bal", "res"]:   # el laboratorio (bancotia.gd lab_ver): cada paso con su escena
		var n: int = J.lab_pasos(k).size()
		for i in n:
			var T: Dictionary = e.TIRO.duplicate()
			T.merge({"esc": "l" + k, "paso": i, "n": n, "per": float(J.D.MANICURA.per), "mov": 0.0, "ritmo": 0.0}, true)
			var sin_esc: Dictionary = T.duplicate()
			sin_esc.erase("esc")
			var base: Image = await foto(e, sin_esc, now)
			var a: Image = await foto(e, T, now)
			var b: Image = await foto(e, T, now + 1730)
			a.save_png(dir.path_join("lab-%s-%d-a.png" % [k, i]))
			if a.get_data() == base.get_data():
				fallos.append("lab %s %d: no se pinta" % [k, i])
			if a.get_data() == b.get_data():
				fallos.append("lab %s %d: no se mueve" % [k, i])
			if load("res://src/escena_extr.gd").pl("l%s-%d" % [k, i]) == null:   # la escena es de PixelLab (lo pidió el usuario)
				fallos.append("lab %s %d: sin su escena de PixelLab" % [k, i])
			tot += 1
	# el EPI a la vista: de PixelLab (pixellab_epi.py) parado y andando, con la bata, los guantes y las gafas y sin la gorra en las
	# cuatro direcciones
	J.TIRO = null
	var gr = J.grupo_pj()
	for d in ["down", "up", "left", "right"]:
		J.P.dir = d
		var f = J.pintor._pj_frame(J.P, gr, true, 0.0)
		if f == null:
			fallos.append("EPI %s: sin fotograma" % d)
			continue
		var pl = J.epi_pl(f.c)
		if pl == null:
			fallos.append("EPI %s: sin el de PixelLab" % d)
			continue
		var bl := 0
		var az := 0
		var gorra := 0
		for y in pl.get_height():
			for x in pl.get_width():
				var p: Color = pl.get_pixel(x, y)
				if p.a8 == 0:
					continue
				if p.r8 > 200 and p.g8 > 205 and p.b8 > 205:
					bl += 1
				if p.b8 > p.r8 + 50 and p.b8 > 140:
					az += 1
				if p.g8 > p.r8 + 40 and p.g8 > p.b8 + 30:
					gorra += 1
		if bl < 20 or (d != "up" and az < 1) or gorra > 0:
			fallos.append("EPI %s: de PixelLab, bata %d, guantes %d, gorra %d" % [d, bl, az, gorra])
		var gp: Image = pl.duplicate()
		gp.resize(32 * 8, 32 * 8, Image.INTERPOLATE_NEAREST)
		gp.save_png(dir.path_join("epi-pl-%s.png" % d))
		# lo demás (correr, las acciones), por colores: el fotograma de correr
		var fr = Atlas.frame_de(gr, "run", {"down": "south", "up": "north", "left": "west", "right": "east"}[d], 0, {"i": 0})
		if fr == null or J.epi_pl(fr.c) != null:
			fallos.append("EPI %s: correr no va por colores" % d)
			continue
		var o: Image = J.epi_img(fr.c)
		var cu := {}
		for y in o.get_height():
			for x in o.get_width():
				var p := o.get_pixel(x, y)
				if p.a8 > 0:
					for c in ["bata", "guante", "cristal", "montura"]:
						if p.is_equal_approx(J.EPI_COL[c]):
							cu[c] = int(cu.get(c, 0)) + 1
		if int(cu.get("bata", 0)) < (20 if d == "down" or d == "up" else 8):   # corriendo de lado, la bata se ve de canto
			fallos.append("EPI %s: sin bata %s" % [d, cu])
		if d != "up" and int(cu.get("guante", 0)) < 1:
			fallos.append("EPI %s: sin guantes %s" % [d, cu])
		if int(cu.get("cristal", 0)) + int(cu.get("montura", 0)) < 1:
			fallos.append("EPI %s: sin gafas %s" % [d, cu])
		var gx: Image = o.duplicate()
		gx.resize(o.get_width() * 8, o.get_height() * 8, Image.INTERPOLATE_NEAREST)
		gx.save_png(dir.path_join("epi-%s.png" % d))
		tot += 1
	# la protagonista, también de PixelLab, y con el EPI puesto no se corre (las normas del laboratorio): andando
	var sx = J.S.get("sexo")
	J.S.sexo = "f"
	var gf = J.grupo_pj()
	for d in ["down", "up", "left", "right"]:
		J.P.dir = d
		var f = J.pintor._pj_frame(J.P, gf, true, 0.0)
		if f == null or J.epi_pl(f.c) == null:
			fallos.append("EPI de ella %s: sin el de PixelLab" % d)
		else:
			var gp: Image = J.epi_pl(f.c).duplicate()
			gp.resize(32 * 8, 32 * 8, Image.INTERPOLATE_NEAREST)
			gp.save_png(dir.path_join("epi-pl-f-%s.png" % d))
		tot += 1
	J.S.sexo = sx
	var m0 = J.S.map
	var e0 = J.lab().get("e")
	J.S.map = String(J.D.LAB.mapa)
	J.lab().e = true
	var mv = J.P.moving
	J.P.moving = true
	J.P.dir = "down"
	var fc = J.pintor._pj_frame(J.P, gr, true, 120.0)
	if not J.epi_puesto() or fc == null or J.epi_pl(fc.c) == null:
		fallos.append("EPI: con prisa en el laboratorio corre (sin el de PixelLab)")
	J.lab().e = false
	var fs = J.pintor._pj_frame(J.P, gr, true, 120.0)
	if fs == null or J.epi_pl(fs.c) != null:
		fallos.append("EPI: sin él puesto ya no corre")
	J.P.moving = mv
	J.lab().e = e0
	J.S.map = m0
	tot += 1
	for x in fallos:
		print("  FALLO ", x)
	print("extracciones: %d escenas, %d fallos" % [tot, fallos.size()])
	J.queue_free()
	quit(1 if fallos.size() else 0)
