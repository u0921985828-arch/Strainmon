# Ribera Verde (Godot) — 1.52: el tiempo de fuera (lo pidió el usuario: «en vez de la hora en grande… la temperatura en grados,
# el clima y un sprite según el clima; lógica por estaciones del año»; con Datos.CAL).
#   $GODOT --headless --path godot --script res://tests/tiempo.gd   → «tiempo: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también tiempo-*.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func foto(dir: String, k: String, t := 1000.0) -> void:
	J.toast_box.hide()
	for q in 2:
		await process_frame
		J.pintor.redibuja(t)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("tiempo-%s.png" % k))

func dia_con(k: String, desde := 1) -> int:
	for d in range(desde, desde + 2000):
		if Datos.tiempo(d, 720).k == k:
			return d
	return -1

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-tiempo.json"
	Juego.AJUSTES = "user://prueba-tiempo-ajustes.json"
	Datos.CAL = true
	var D := Datos.carga()
	var T: Dictionary = D.TIEMPO
	# 1 · los datos: 12 meses que suman 100, la máxima por encima de la mínima
	chk(T.p.size() == 12 and T.p.all(func(r): return r.reduce(func(a, b): return a + b, 0) == 100), "los % de cada mes suman 100")
	chk(T.t.size() == 12 and T.t.all(func(r): return r[0] > r[1]), "máx > mín cada mes")
	# 2 · las estaciones por la fecha (el día 1 es el 20 de abril de 2026)
	var E := {[2026, 4, 20]: "primavera", [2026, 6, 20]: "primavera", [2026, 6, 21]: "verano", [2026, 9, 22]: "verano", [2026, 9, 23]: "otoño",
		[2026, 12, 20]: "otoño", [2026, 12, 21]: "invierno", [2027, 1, 1]: "invierno", [2027, 3, 19]: "invierno", [2027, 3, 20]: "primavera"}
	for f in E:
		var e := Datos.estacion(Datos.dia_de(f[0], f[1], f[2]))
		chk(e == E[f], "%s: %s (%s)" % [f, E[f], e])
	# 3 · un tiempo por día, igual cada vez, con la temperatura del día entre la mínima y la máxima
	var malos := 0
	var cnt := {}
	var nieve_fuera := 0
	var tmes := {}
	for d in range(1, 731):
		var a := Datos.tiempo(d, 600)
		if a.k != Datos.tiempo(d, 600).k or a.k != Datos.tiempo(d, 1300).k:
			malos += 1
		for h in [0, 360, 540, 900, 1200, 1439]:
			var b := Datos.tiempo(d, h)
			if b.t < b.min or b.t > b.max:
				malos += 1
		var m: int = int(Datos.fecha(d).m)
		if a.k == "nieve" and m >= 4 and m <= 10:
			nieve_fuera += 1
		cnt[a.k] = cnt.get(a.k, 0) + 1
		if not tmes.has(m):
			tmes[m] = []
		tmes[m].append(Datos.tiempo(d, 900).t)
	chk(malos == 0, "el mismo tiempo todo el día y la temperatura entre mín y máx (%d fuera)" % malos)
	chk(T.k.all(func(k): return cnt.get(k, 0) > 0), "en dos años sale de todo: %s" % [cnt])
	chk(nieve_fuera == 0, "no nieva de abril a octubre (%d)" % nieve_fuera)
	var med := func(m): return tmes[m].reduce(func(a, b): return a + b, 0) / float(tmes[m].size())
	chk(med.call(8) > med.call(1) + 8, "agosto (%.1f) más caliente que enero (%.1f)" % [med.call(8), med.call(1)])
	var d0 := dia_con("sol")
	chk(Datos.tiempo(d0, 6 * 60).t == Datos.tiempo(d0, 6 * 60).min and Datos.tiempo(d0, 15 * 60).t == Datos.tiempo(d0, 15 * 60).max, "la mínima a las 6 y la máxima a las 15")
	# 4 · el móvil: el dibujo y los grados en vez de la hora en grande; la descripción con el tiempo y la estación
	J = Juego.new()
	root.add_child(J)
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	for x in O:
		if x.k == "nave2":
			J.S = Datos.enteros(x).S
	var S = J.S
	var ops := ["Llamar", "Pedir a Kiko", "Mensajes", "Gente", "Plantilla", "Banca", "Tienda online", "Calendario", "Mapa"]
	var x0: int = (J.SW - 80) >> 1
	for k in T.k:
		S.day = dia_con(k)
		S.min = 15 * 60
		var R: Array = J.rects_movil({"ops": ops, "i": 0})
		var ic: Array = J.ICONO_TIEMPO[k]
		var col := {}
		for row in ic:
			for c in row:
				if c != ".":
					col[J.COLOR_TIEMPO[c]] = 1
		chk(col.keys().all(func(c): return R.any(func(r): return typeof(r[0]) != TYPE_STRING and r[4] == c)), "%s: su dibujo en el móvil" % k)
		chk(R.all(func(r): return typeof(r[0]) == TYPE_STRING or (int(r[0]) >= x0 and int(r[0]) + int(r[2]) <= x0 + 80)), "%s: todo dentro del móvil" % k)
		var Ti := Datos.tiempo(int(S.day), int(S.min))
		var ds: String = J.desc_movil({"ops": ops, "i": 0})
		chk(ds.contains("%d °C" % Ti.t) and ds.contains(Ti.est) and ds.contains(str(Ti.n).to_lower()), "%s: la descripción (%s)" % [k, ds])
		chk(ic.size() == 9 and ic.all(func(r): return r.length() == 13), "%s: 13 × 9" % k)
	# sin CAL, la hora en grande como antes
	Datos.CAL = false
	var R0: Array = J.rects_movil({"ops": ops, "i": 0})
	chk(not R0.any(func(r): return typeof(r[0]) != TYPE_STRING and r[4] == J.COLOR_TIEMPO.s), "sin CAL, sin el tiempo")
	chk(J.calle_tiempo() == 1.0, "sin CAL, la calle no cambia")
	Datos.CAL = true
	# 5 · la calle: con lluvia, menos gente y menos calor por venta
	S.day = dia_con("lluvia")
	chk(is_equal_approx(J.calle_tiempo(), float(T.calle.lluvia)) and J.calle_tiempo() < 1.0, "con lluvia, el calor de la calle ×%s" % J.calle_tiempo())
	S.day = dia_con("sol")
	chk(J.calle_tiempo() == 1.0, "con sol, igual")
	S.day = dia_con("tormenta")
	chk(J.calle_tiempo() < J.calle_tiempo() + 0.01 and J.calle_tiempo() == float(T.calle.tormenta), "con tormenta, ×%s" % J.calle_tiempo())
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
		J.enter_map("town", 14, 10, "down")
		J.mode = "world"
		for k in ["sol", "lluvia", "tormenta", "niebla", "nieve"]:
			S.day = dia_con(k)
			S.min = 12 * 60
			await foto(dir, "calle-" + k)
		# sin relámpagos (lo pidió el usuario: «sigue habiendo destellos… pam, pam, cada cierto tiempo»): con tormenta, la calle no se
		# aclara de golpe en ningún momento de los 7 s en los que antes caía uno
		S.day = dia_con("tormenta")
		var luz := []
		for t in [7050.0, 14030.0, 3500.0]:
			await foto(dir, "tormenta-%d" % int(t), t)
			var im := Image.load_from_file(dir.path_join("tiempo-tormenta-%d.png" % int(t)))
			var s := 0.0
			for y in range(0, im.get_height(), 8):
				for x in range(0, im.get_width(), 8):
					var c := im.get_pixel(x, y)
					s += c.r + c.g + c.b
			luz.append(s)
		chk(luz[0] < luz[2] * 1.05 and luz[1] < luz[2] * 1.05, "con tormenta, sin relámpago que aclare la pantalla: %s" % [luz])
		J.enter_map("home", 4, 6, "up")
		S.day = dia_con("lluvia")
		J.MOVIL_V = {"ops": ops, "i": 0}
		J._dlg_fijo(J.desc_movil(J.MOVIL_V), "MÓVIL")
		await foto(dir, "movil")
		J.MOVIL_V = null
		J.set_process(true)
	print("tiempo: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
