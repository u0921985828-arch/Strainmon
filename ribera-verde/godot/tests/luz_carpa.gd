# Landrace Hunters (Godot) — el foco, encendido por el temporizador (lo pidió el usuario: «cuando esté en 12 h y esté a oscuras se
# tiene que ver a oscuras»), con Datos.CAL. Cultivo.foco_on: desde las 6:00, 18 h (18/6) o 12 h (12/12; en automático, en cuanto
# una florece). En la vista C: en sus horas de luz, igual a cualquier hora; en las de noche, la carpa a oscuras, sin haz.
#   xvfb-run … --rendering-driver opengl3 --script res://tests/luz_carpa.gd -- --sin-arranque [--pintar <dir>]
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Vista = preload("res://src/vista.gd")
const Arte = preload("res://src/arte.gd")

var n_ok := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func ok(que: String, c: bool) -> void:
	if c:
		n_ok += 1
	else:
		fallos.append(que)

func estado(e: Dictionary) -> Dictionary:
	var S := Cultivo.nuevo_estado()
	S.carpas = [{"t": e.t, "foco": e.foco}]
	S.carpas[0].merge(e.get("x", {}).duplicate(true))
	S.macetas = e.macetas.duplicate()
	S.pots = []
	for p in e.pots:
		S.pots.append(p.duplicate(true) if p else null)
	S.custom = e.get("custom", {})
	S.gen = e.get("gen", {})
	return S

func pinta(S: Dictionary, cal: bool) -> Image:
	Datos.CAL = cal
	var sv := SubViewport.new()
	sv.size = Vector2i(240, 160)
	sv.transparent_bg = false
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var v = Vista.new()
	sv.add_child(v)
	v.pinta(S, {"ci": 0, "sel": -9}, 0.0)
	for n in 3:
		await RenderingServer.frame_post_draw
	var im := sv.get_texture().get_image()
	im.convert(Image.FORMAT_RGBA8)
	sv.queue_free()
	return im

const AZUL := 30
const AZUL_N := 700   # antes del cambio, 14; después, unos 1450

func lum(c: Color) -> float:
	return .299 * c.r + .587 * c.g + .114 * c.b

# la media de luz de los píxeles de la lista
func media(im: Image, P: Array) -> float:
	var t := 0.0
	for p in P:
		t += lum(im.get_pixel(p.x, p.y))
	return t / maxf(1, P.size())

# la luz verde de trabajo (lo pidió el usuario): en lo que se ve, el verde por encima del rojo y del azul
func verde(im: Image, P: Array) -> bool:
	var c := Vector3.ZERO
	for p in P:
		var q := im.get_pixel(p.x, p.y)
		c += Vector3(q.r, q.g, q.b)
	return c.y > 1.5 * c.x and c.y > 1.5 * c.z

func distintos(a: Image, b: Image) -> int:
	var n := 0
	for y in 160:
		for x in 240:
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				n += 1
	return n

func con(e: Dictionary, ciclo: String, h: int) -> Dictionary:
	var S := estado(e)
	S.carpas[0].ciclo = ciclo
	S.min = h * 60
	return S

func _corre() -> void:
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/oraculo.json"))
	var dir := arg("--pintar")
	# las horas: 18/6 de 6:00 a 24:00, 12/12 de 6:00 a 18:00, automático por la fase
	Datos.CAL = true
	var e0: Dictionary = O.escenas.filter(func(x): return x.k == "m100-flor")[0]
	for c in [["veg", 5, false], ["veg", 6, true], ["veg", 23, true], ["veg", 0, false], ["flor", 6, true], ["flor", 17, true], ["flor", 18, false], ["flor", 3, false]]:
		ok("%s a las %d: %s" % c, Cultivo.foco_on(con(e0, c[0], c[1]), 0) == c[2])
	var fl := false
	var S0 := con(e0, "auto", 20)
	for p in S0.pots:
		if p and not p.get("dead") and Cultivo.plant_stage(p) >= 3:
			fl = true
	ok("auto con una en flor: 12 h", Cultivo.horas_luz(S0, 0) == (12 if fl else 18))
	var v := con(e0, "auto", 20)
	for p in v.pots:
		if p:
			p.prog = .5
	ok("auto sin ninguna en flor: 18 h", Cultivo.horas_luz(v, 0) == 18 and Cultivo.foco_on(v, 0))
	Datos.CAL = false
	ok("sin CAL, como el HTML: con plantas, siempre", Cultivo.foco_on(con(e0, "flor", 3), 0))
	for e in O.escenas:
		if e.html == null:
			continue
		var S := estado(e)
		var g = Vista.geo(S, 0)
		if g.vc == null or not Cultivo.plantas_vivas(S, 0):
			continue
		# sin CAL cambian el tresbolillo y el tallo a la vista (tallo_vista.gd, plantacion.gd): de día, igual a otra hora de luz
		var a: Image = await pinta(con(e, "flor", 8), true)
		var dia: Image = await pinta(con(e, "flor", 12), true)
		var noche: Image = await pinta(con(e, "flor", 22), true)
		if dir != "":
			var j := Image.create(484, 160, false, Image.FORMAT_RGBA8)
			j.blit_rect(dia, Rect2i(0, 0, 240, 160), Vector2i.ZERO)
			j.blit_rect(noche, Rect2i(0, 0, 240, 160), Vector2i(244, 0))
			j.resize(484 * 3, 480, Image.INTERPOLATE_NEAREST)
			j.save_png(dir.path_join("luz-%s.png" % e.k))
		var P := []
		for y in range(0, 160, 2):
			for x in range(0, 240, 2):
				if lum(a.get_pixel(x, y)) > .04:
					P.append(Vector2i(x, y))
		ok("%s: de día, igual a otra hora de luz" % e.k, distintos(a, dia) == 0)
		ok("%s: de noche, a oscuras (≤ 25 %%)" % e.k, media(noche, P) <= .25 * media(dia, P))
		ok("%s: de noche, con la luz verde de trabajo" % e.k, verde(noche, P))
		# la campana (se pinta encima de la capa de la luz) también, a oscuras y en verde (lo dijo el usuario: «el foco… no entra en
		# el filtro, ni se oscurece»)
		var C := []
		var gv = Vista.geo(con(e, "flor", 22), 0)
		var fc := Arte.foto(gv.vc.foco.n)
		for cx in gv.vc.get("fxs", [120]):
			for y in range(int(gv.vc.fy) - 15, int(gv.vc.fy) - 15 + fc.get_height()):
				for x in range(int(cx) - (fc.get_width() >> 1), int(cx) + (fc.get_width() >> 1)):
					if x >= 0 and x < 240 and y >= 0 and y < 160 and lum(a.get_pixel(x, y)) > .04:
						C.append(Vector2i(x, y))
		ok("%s: de noche, la campana a oscuras y en verde" % e.k, C.size() > 20 and media(noche, C) <= .3 * media(dia, C) and verde(noche, C))
	# en todas las carpas y con todos los focos (lo dijo el usuario: «lo mismo tiene que pasar en todas las carpas y con todas las
	# luces»): de noche, a oscuras y en verde, la campana también; de día, nada de luz por encima de la boca de la carpa (lo dijo el
	# usuario: «arriba, cuando está encendido el foco, salen como un poco de reflejo… es un error»)
	var boca := int(Datos.carga().VCA.boca)
	var vistas := {}
	for e in O.escenas:
		if e.html == null:
			continue
		for f in Datos.carga().FOCOS:
			var x: Dictionary = e.duplicate(true)
			x.foco = f
			var S := estado(x)
			var g = Vista.geo(S, 0)
			if g.vc == null or not Cultivo.plantas_vivas(S, 0):
				continue
			var q := "%s+%s" % [e.k, f]
			Datos.CAL = true
			var L := Arte.luz(e.t, g.vc)
			var n := 0
			for y in boca:
				for i in 240:
					if L.get_pixel(i, y).a8:
						n += 1
			ok("%s: nada de luz encima de la boca (%d px)" % [q, n], n == 0)
			Datos.CAL = false
			var n0 := 0
			var L0 := Arte.luz(e.t, g.vc)
			for y in boca:
				for i in 240:
					if L0.get_pixel(i, y).a8:
						n0 += 1
			vistas[q] = n0
			var dia: Image = await pinta(con(x, "flor", 12), true)
			var noche: Image = await pinta(con(x, "flor", 22), true)
			var P := []
			for y in range(0, 160, 2):
				for i in range(0, 240, 2):
					if lum(dia.get_pixel(i, y)) > .04:
						P.append(Vector2i(i, y))
			ok("%s: de noche, a oscuras y en verde" % q, media(noche, P) <= .25 * media(dia, P) and verde(noche, P))
			var C := []
			var gv = Vista.geo(con(x, "flor", 22), 0)
			var fc := Arte.foto(gv.vc.foco.n)
			for cx in gv.vc.get("fxs", [120]):
				for y in range(int(gv.vc.fy) - 15, int(gv.vc.fy) - 15 + fc.get_height()):
					for i in range(int(cx) - (fc.get_width() >> 1), int(cx) + (fc.get_width() >> 1)):
						if i >= 0 and i < 240 and y >= 0 and y < 160 and lum(dia.get_pixel(i, y)) > .04:
							C.append(Vector2i(i, y))
			ok("%s: de noche, el foco a oscuras y en verde" % q, C.size() > 20 and media(noche, C) <= .3 * media(dia, C) and verde(noche, C))
	ok("sin CAL, el reflejo de arriba sigue (como el HTML)", vistas.values().max() > 0)
	print("combinaciones carpa+foco: ", vistas.size())
	Datos.CAL = false
	# lo dijo el usuario: «la lámpara CFL… no se ve la luz cuando está encendida» y, apagado, «no hay nada que refleje la luz en las
	# paredes»: con CAL, el CFL encendido tiñe de su azul el suelo y la pared (píxeles con el azul 20 por encima del rojo, abajo) y la
	# carpa sin plantas (apagada) sale a oscuras como la noche
	var e1: Dictionary = O.escenas.filter(func(x): return x.k == "p60-cfl")[0]
	var dia: Image = await pinta(con(e1, "flor", 12), true)
	var azul := 0
	for y in range(80, 160):
		for x in 240:
			var c := dia.get_pixel(x, y)
			if c.b8 - c.r8 >= AZUL and lum(c) > .5:
				azul += 1
	ok("p60-cfl: el CFL encendido se ve (%d px azules)" % azul, azul >= AZUL_N)
	for k in ["p60-cfl", "p60-cfl-muertas"]:
		var e: Dictionary = O.escenas.filter(func(x): return x.k == k)[0]
		var S := con(e, "flor", 12)
		for i in S.pots.size():
			S.pots[i] = null
		var vacia: Image = await pinta(S, true)
		var P := []
		for y in range(0, 160, 2):
			for x in range(0, 240, 2):
				if lum(dia.get_pixel(x, y)) > .04:
					P.append(Vector2i(x, y))
		ok("%s: sin plantas, apagada y a oscuras" % k, not Cultivo.foco_on(S, 0) and media(vacia, P) <= .25 * media(dia, P) and verde(vacia, P))
		var sin: Image = await pinta(S, false)
		ok("%s: sin CAL, sin plantas, como el HTML (sin oscurecer)" % k, media(sin, P) > .5 * media(dia, P))
	Datos.CAL = true
	for f in fallos:
		print("FALLO  ", f)
	print("luz_carpa: %d comprobaciones, %d fallos" % [n_ok + fallos.size(), fallos.size()])
	quit(1 if fallos.size() else 0)
