# Ribera Verde (Godot) — 1.56: el viaje de perfil, como pantalla de carga (lo pidió el usuario: «en el autobús no hay animación como
# tampoco en los demás vehículos, como una pantalla de carga, pero que sea el vehículo andando recto desde una vista de perfil»). Con
# CAL: el arte (arte/viaje.png + viaje.json) trae el autobús y los cuatro vehículos del concesionario con sus ruedas; el vehículo entra
# por la izquierda, se queda en medio y sale por la derecha; la luz va por la hora; la parada y conducir lo llaman (gancho_viaje); dura
# DUR y A lo pasa; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/viaje.gd   → «viaje: N comprobaciones, 0 fallos»
#   con -- --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también viaje-<vehículo>-<luz>-<ms>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const EscViaje = preload("res://src/escena_viaje.gd")

var J
var M
var n := 0
var fallos := []
var VIO := []
var auto := {"a": true}

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

func _menu(_items: Array, o: Dictionary) -> Dictionary:
	o = o.duplicate()
	o.initial = 0
	return o

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-viaje.json"
	Juego.AJUSTES = "user://prueba-viaje-ajustes.json"
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
	S.banco = 50000
	S.money = 20000
	S.protect = false
	S.flags.llegada = true
	S.coches = {"utilitario": {"km": 0, "r": 1, "dia": 0}}
	J.oraculo = true
	J.enter_map("town", 5, 9, "up")
	J.build_ents()
	J.mode = "world"
	J.gancho_menu = _menu
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if auto.a and J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
	# 1 · el arte
	chk(EscViaje.carga(), "carga arte/viaje.png y viaje.json")
	for k in ["bus"] + J.D.CONCE.v.keys():
		chk(EscViaje.META.has(k) and EscViaje.R.has(k), "el %s, de perfil" % k)
		if EscViaje.META.has(k):
			var m: Dictionary = EscViaje.META[k]
			chk(m.ruedas.size() == 2, "%s: dos ruedas" % k)
			for r in m.ruedas:
				for f in 4:
					chk(EscViaje.R.has("rueda-%d-%d" % [int(r[2]), f]), "%s: rueda %d, fotograma %d" % [k, int(r[2]), f])
			var w: int = EscViaje.R[k].get_width()
			chk(int(m.suelo) >= EscViaje.R[k].get_height() - 2 and int(m.faro[0]) > w / 2, "%s: el suelo abajo y el faro delante" % k)
	for k in ["monte", "cerca", "carretera"]:
		chk(EscViaje.R.has(k), "el fondo: %s" % k)
	chk(EscViaje.clave("tractor") == "bus", "un vehículo sin dibujo, el autobús")
	# el autobús y el cielo de PixelLab (lo pidió el usuario: «el sprite del bus, más del estilo del juego, muebles con PixelLab, como
	# también el fondo del cielo»): cada rueda en su paso de rueda, el protagonista en una ventana; nubes, sol y luna; el cielo tramado
	var bus: Image = EscViaje.R.bus
	var by := bus.get_height() - 1
	for r in EscViaje.META.bus.ruedas:
		var cx := int(r[0])
		var rd := int(r[2]) / 2
		chk(bus.get_pixel(cx, by).is_equal_approx(Color("#2a2d34")) and bus.get_pixel(cx - rd - 1, by).a > 0.5 and bus.get_pixel(cx + rd + 1, by).a > 0.5, "bus: la rueda de %d en su paso (sombra dentro, carrocería a los lados)" % cx)
	var gorra := false
	for y in bus.get_height():
		for x in bus.get_width():
			gorra = gorra or bus.get_pixel(x, y).is_equal_approx(Color("#5aa861"))
	chk(gorra, "bus: el protagonista, con la gorra verde, en la ventana")
	# los pueblos (lo pidió el usuario: «que no todos los pueblos sean iguales y que, por lo alejadas que estén las casas de la carretera,
	# se vean más o menos pequeñas»): uno por tipo, en dos capas; las casas de lejos, a la mitad, más arriba y más despacio
	var alto_casas := func(im: Image, base: int) -> int:   # lo más alto que sale del prado
		for y in base - 7:
			for x in im.get_width():
				if im.get_pixel(x, y).a > 0.5 and not im.get_pixel(x, y).is_equal_approx(im.get_pixel(0, base - 1)):
					return base - y
		return 0
	var vistos := []
	for t in EscViaje.PUEBLOS:
		var pc: Image = EscViaje.R.get("pueblo-" + t)
		var pl: Image = EscViaje.R.get("lejos-" + t)
		chk(pc != null and pc.get_width() == 704 and pc.get_height() == 108, "%s: el pueblo de junto a la carretera, con el arte del juego" % t)
		chk(pl != null and pl.get_width() == 704 and pl.get_height() == 80, "%s: el de lejos" % t)
		if pc == null or pl == null:
			continue
		var hc: int = alto_casas.call(pc, 96)
		var hl: int = alto_casas.call(pl, 52)
		chk(hc >= 80 and hl > 0 and hl <= hc * 0.6, "%s: lo de lejos, más pequeño (%d px frente a %d)" % [t, hl, hc])
		chk(not vistos.any(func(o: Image): return o.get_data() == pc.get_data()), "%s: distinto de los demás" % t)
		vistos.append(pc)
	chk(EscViaje.CAPAS[1][0] == "lejos" and EscViaje.CAPAS[2][0] == "pueblo" and EscViaje.CAPAS[1][2] < EscViaje.CAPAS[2][2] and EscViaje.CAPAS[1][2] > EscViaje.CAPAS[0][2], "lejos, más despacio que el pueblo y más deprisa que el monte")
	chk(EscViaje.CAPAS[1][1] + 52 < EscViaje.CAPAS[2][1] + 96 and EscViaje.CAPAS[1][1] + 80 >= EscViaje.CAPAS[3][1], "el pie de lo de lejos, más arriba; su prado, hasta el quitamiedos")
	chk(EscViaje.CAPAS[2][1] + 96 >= EscViaje.CAPAS[3][1], "el pie de las casas, detrás del quitamiedos")
	chk(J.D.PARADAS.keys().all(func(k): return EscViaje.PUEBLOS.has(EscViaje.pueblo({"k": k, "de": "", "a": ""})[0])), "cada parada con su pueblo")
	chk(EscViaje.pueblo({"k": "puerto"})[0] == "costa" and EscViaje.pueblo({"k": "ibarbide"})[0] == "ciudad" and EscViaje.pueblo({"k": "valdehierro"})[0] == "industria" and EscViaje.pueblo({"k": "mendialde"})[0] == "rural", "el pueblo, por el destino")
	# el texto no se tapa: cada píxel claro de las letras, rodeado de claro o del contorno, nunca del fondo
	var lienzo := Image.create(200, 30, false, Image.FORMAT_RGBA8)
	var fp := FakeP.new()
	fp.im = lienzo
	EscViaje._texto(fp, 4, 4, "RIBERA VERDE - PUERTO VIEJO", 1)
	var claro := Color("#f8f4e8")
	var mal := 0
	for y in range(1, 29):
		for x in range(1, 199):
			if lienzo.get_pixel(x, y).is_equal_approx(claro):
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var c := lienzo.get_pixel(x + dx, y + dy)
						if not (c.is_equal_approx(claro) or c.is_equal_approx(EscViaje.TEXTO_BORDE)):
							mal += 1
	chk(mal == 0, "el texto, con su contorno por los ocho lados (%d px al aire)" % mal)
	var tipos := {}
	for i in 30:
		tipos[EscViaje.pueblo({"de": "a%d" % i, "a": "b"})[0]] = 1
	chk(tipos.size() >= 4, "sin destino conocido, por el trayecto (%d tipos)" % tipos.size())
	for k in ["nube-0", "nube-1", "nube-2", "nube-3", "sol", "luna"]:
		chk(EscViaje.R.has(k) and EscViaje.R[k].get_width() >= 16, "el cielo: %s" % k)
	for lz in 3:
		var ci: Image = EscViaje.cielo_img(J.SW, lz)
		var tonos := {}
		var mezcla := false
		for y in ci.get_height():
			var fila := {}
			for x in 8:
				fila[ci.get_pixel(x, y).to_html()] = 1
				tonos[ci.get_pixel(x, y).to_html()] = 1
			mezcla = mezcla or fila.size() == 2
		chk(tonos.size() == EscViaje.CIELO_TONOS and mezcla, "el cielo %d: %d tonos tramados" % [lz, tonos.size()])
		chk(ci.get_pixel(0, 0).is_equal_approx(Color(EscViaje.CIELO[lz][0])) and ci.get_pixel(0, 119).is_equal_approx(Color(EscViaje.CIELO[lz][1])), "el cielo %d: de arriba abajo" % lz)
	# 2 · el movimiento y la luz
	var sw: int = J.SW
	for k in ["bus", "moto"]:
		var w: int = EscViaje.R[k].get_width()
		var p0: Vector2 = EscViaje.pos(0, sw, w, 0.1)
		var p1: Vector2 = EscViaje.pos(EscViaje.ENTRA, sw, w, 0.1)
		var p2: Vector2 = EscViaje.pos(EscViaje.SALE - 1, sw, w, 0.1)
		var p3: Vector2 = EscViaje.pos(EscViaje.DUR, sw, w, 0.1)
		chk(p0.x + w <= 0, "%s: entra desde fuera, por la izquierda (%d)" % [k, p0.x])
		chk(absf(p1.x - (sw - w) * 0.5) < 1 and absf(p2.x - p1.x) < 1, "%s: en medio mientras rueda" % k)
		chk(p3.x >= sw, "%s: sale por la derecha (%d)" % [k, p3.x])
		chk(p3.y > p1.y and p1.y > p0.y, "%s: el fondo corre hacia atrás" % k)
	chk(EscViaje.luz(12 * 60) == 0 and EscViaje.luz(20 * 60) == 1 and EscViaje.luz(2 * 60) == 2, "día, atardecer y noche")
	# 3 · sin CAL, nada
	Datos.CAL = false
	var t0: float = M.reloj
	chk(corre(func(): await J.anim_viaje("bus", "town", "puerto", 30)) and J.VIAJE_V == null and M.reloj - t0 < EscViaje.DUR, "sin CAL no se anima (%d ms)" % int(M.reloj - t0))
	Datos.CAL = true
	# 4 · dura lo suyo y A lo pasa
	auto.a = false
	var vio := {"v": false}
	M.timeout(func(): vio.v = J.VIAJE_V != null and J.VIAJE_V.veh == "bus" and J.VIAJE_V.a == "Puerto Viejo" and J.VIAJE_V.k == "puerto", 1000)
	t0 = M.reloj
	chk(corre(func(): await J.anim_viaje("bus", "town", "puerto", 30)), "el viaje termina solo")
	chk(vio.v, "a mitad, VIAJE_V con el autobús y el destino")
	chk(M.reloj - t0 >= EscViaje.DUR and M.reloj - t0 < EscViaje.DUR + 1500 and J.VIAJE_V == null, "dura %d ms" % int(M.reloj - t0))
	M.timeout(func(): J.press("A"), 800)
	t0 = M.reloj
	chk(corre(func(): await J.anim_viaje("deportivo", "town", "ibarbide", 25)) and M.reloj - t0 < EscViaje.DUR and J.VIAJE_V == null, "A lo pasa (%d ms)" % int(M.reloj - t0))
	auto.a = true
	# 5 · la parada y conducir lo llaman
	J.gancho_viaje = func(v, de, a): VIO.append([v, de, a, J.S.map])
	J.enter_map("town", 5, 9, "up")
	J.build_ents()
	J.mode = "world"
	S = J.S
	S.min = 12 * 60
	VIO.clear()
	chk(corre(func(): await J.parada_action()) and VIO.size() == 1 and VIO[0][0] == "bus" and VIO[0][1] == "town" and J.S.map == VIO[0][2], "el autobús: %s → %s" % [VIO, S.map])
	J.enter_map("town", 5, 9, "up")
	J.build_ents()
	VIO.clear()
	S = J.S
	S.coches = {"utilitario": {"km": 0, "r": 1, "dia": 0}}
	chk(corre(func(): await J.conducir("utilitario")) and VIO.size() == 1 and VIO[0][0] == "utilitario" and J.S.map == VIO[0][2], "el utilitario: %s → %s" % [VIO, S.map])
	J.gancho_viaje = Callable()
	# 6 · 1.57: la carga del juego (la carretera sin letras, los vehículos y la barra) y, después, el título con más atrezo
	var lados := {}
	for v in EscViaje.CARGA_V:
		chk(EscViaje.META.has(v[0]), "la carga: el %s, dibujado" % v[0])
		lados[int(v[1])] = true
	chk(lados.size() == 2, "la carga: vehículos en los dos carriles")
	for c in [0, 1]:   # en un carril, a la misma marcha y sin montarse
		var xs := []
		for v in EscViaje.CARGA_V:
			if int(v[1]) == c:
				xs.append(float(v[2]) * (sw + 170 + EscViaje.HUECO))
		xs.sort()
		var ok := true
		for i in xs.size():
			var sig: float = xs[(i + 1) % xs.size()] + (0.0 if i + 1 < xs.size() else float(sw + 170 + EscViaje.HUECO))
			ok = ok and sig - xs[i] >= 170 + 8
		chk(ok, "la carga: carril %d, sin montarse (%s)" % [c, xs])
	auto.a = false
	t0 = M.reloj
	var st0 := {"m": ""}
	M.timeout(func(): st0.m = J.mode, 1000)
	var fin := {"m": ""}
	chk(corre(func():
		await J.arranque()
		fin.m = J.mode
		J.mode = "world") and fin.m == "title", "la carga acaba en el título (%s)" % fin.m)
	chk(st0.m == "carga" and M.reloj - t0 >= EscViaje.CARGA and M.reloj - t0 < EscViaje.CARGA + 1500, "la carga dura %d ms" % int(M.reloj - t0))
	auto.a = true
	t0 = M.reloj
	fin.m = ""
	chk(corre(func():
		await J.arranque()
		fin.m = J.mode
		J.mode = "world") and fin.m == "title" and M.reloj - t0 < 1000, "A pasa la carga (%d ms)" % int(M.reloj - t0))
	# 1.57.1: la calle de la carga sigue en el título (no la partida de fondo): gente por las dos aceras, en bici y en patinete
	var ac := {}
	var vs := {}
	for q in EscViaje.PEATONES:
		ac[int(q[0])] = true
		vs[q[4]] = true
	chk(ac.size() == 2 and vs.has("") and vs.has("bici") and vs.has("patinete"), "la calle: andando, en bici y en patinete por las dos aceras")
	chk(EscViaje.CALLE_FIL.has("grass") and EscViaje.CALLE_FIL.has("walk") and EscViaje.CALLE_FIL.has("roadT"), "la calle: hierba, aceras y calzada del juego")
	J.mode = "title"
	J.pintor.redibuja(5000.0)
	chk(J.pintor.modo == "calle", "el título: la calle de fondo (%s)" % J.pintor.modo)
	Datos.CAL = false
	J.pintor.redibuja(5000.0)
	chk(J.pintor.modo == "demo", "sin CAL, el título de antes (%s)" % J.pintor.modo)
	Datos.CAL = true
	J.demo_e = null
	J.mode = "world"
	# 6b · 1.57.2: el bancal de exterior por la fecha: nada en invierno, plántula en abril, vegetativo hasta julio, flor en agosto y
	# septiembre, madura en octubre y cortada a finales; los dibujos, en el atlas
	var esp := {[1, 10]: -1, [4, 10]: -1, [4, 20]: 0, [5, 20]: 1, [7, 1]: 2, [8, 10]: 3, [9, 1]: 4, [10, 1]: 5, [10, 17]: 5, [10, 25]: 6, [11, 5]: -1, [12, 31]: -1}
	for k in esp:
		chk(EscViaje.fase_huerto(k[0], k[1]) == esp[k], "el bancal el %d/%d: %d (%d)" % [k[1], k[0], EscViaje.fase_huerto(k[0], k[1]), esp[k]])
	var fz := -1
	var ok_f := true
	for mes in range(1, 13):
		for dia in range(1, 32):
			var f := EscViaje.fase_huerto(mes, dia)
			if f >= 0 and fz >= 0 and f < fz:
				ok_f = false
			fz = f if f >= 0 else fz
	chk(ok_f, "el bancal: las fases no van hacia atrás en el año")
	chk(range(3).all(func(v): return range(1, 6).all(func(i): var k := "hp%d-%d" % [v, i]; return EscViaje.Atlas.cubre("obj:" + k) == "huerto-pl" and EscViaje.Atlas.frame_de("huerto-pl", k, "unica", 0, {"i": 0}) != null)), "el bancal: las tres variedades en sus cinco fases, con contorno (huerto-pl)")
	var alt := []   # 16 px/m: la plántula, de 20 cm; la madura, de 1,4 a 2 m (la sativa, la más alta); cada fase, más alta que la de antes
	for v in 3:
		var hs := []
		for i in range(1, 6):
			hs.append(EscViaje.Atlas.frame_de("huerto-pl", "hp%d-%d" % [v, i], "unica", 0, {"i": 0}).c.get_used_rect().size.y)
		alt.append(hs)
	chk(alt.all(func(hs): return hs[0] <= 6 and hs[4] >= 22 and hs[4] <= 32 and range(4).all(func(j): return hs[j] < hs[j + 1])), "el bancal: a 16 px/m y creciendo %s" % [alt])
	# 7 · los dibujos
	if dir != "":
		J.hud.hide()
		for veh in ["bus", "utilitario", "berlina", "deportivo", "moto"]:
			for h in ([12, 20, 2] if veh == "bus" else [12]):
				for ms in ([400, 1500, 2700] if veh == "bus" and h == 12 else [1500]):
					J.VIAJE_V = {"veh": veh, "de": "Ribera Verde", "a": "Puerto Viejo", "min": 35, "h": h * 60, "t0": 0.0}
					J.pintor.redibuja(ms)
					for r in 3:
						await RenderingServer.frame_post_draw
					var im: Image = J.sv.get_texture().get_image()
					im.save_png(dir.path_join("viaje-%s-%02d-%04d.png" % [veh, h, ms]))
		for k in J.D.PARADAS:   # cada destino, su pueblo
			J.VIAJE_V = {"veh": "bus", "k": k, "de": "Ribera Verde", "a": k, "min": 35, "h": 720, "t0": 0.0}
			J.pintor.redibuja(1500)
			for r in 3:
				await RenderingServer.frame_post_draw
			J.sv.get_texture().get_image().save_png(dir.path_join("pueblo-%s.png" % k))
		J.VIAJE_V = null
		for md in ["carga", "title"]:   # 1.57.1: la calle, en la carga y de fondo en el título
			for ms in [800.0, 2600.0]:
				J.mode = md
				J.carga_t0 = 0.0
				J.pintor.redibuja(ms)
				for r in 3:
					await RenderingServer.frame_post_draw
				J.sv.get_texture().get_image().save_png(dir.path_join("calle-%s-%04d.png" % [md, int(ms)]))
		for fe in [[3, 1], [5, 5], [6, 1], [7, 15], [8, 10], [9, 10], [10, 10], [10, 28]]:   # 1.57.2: el bancal por el año
			EscViaje.FECHA = fe
			J.mode = "carga"
			J.pintor.redibuja(2600.0)
			for r in 3:
				await RenderingServer.frame_post_draw
			J.sv.get_texture().get_image().save_png(dir.path_join("huerto-%02d-%02d.png" % fe))
		EscViaje.FECHA = []
		J.mode = "world"
	print("viaje: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)

class FakeP:
	var im: Image
	func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
		im.fill_rect(Rect2i(x, y, w, h).intersection(Rect2i(0, 0, im.get_width(), im.get_height())), c)
