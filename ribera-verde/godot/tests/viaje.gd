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
	for k in ["monte", "medio", "cerca", "carretera"]:
		chk(EscViaje.R.has(k), "el fondo: %s" % k)
	chk(EscViaje.clave("tractor") == "bus", "un vehículo sin dibujo, el autobús")
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
	M.timeout(func(): vio.v = J.VIAJE_V != null and J.VIAJE_V.veh == "bus" and J.VIAJE_V.a == "Puerto Viejo", 1000)
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
	J.demo_e = null
	var sv: Array = J.demo_entra(5000.0)
	var coches := 0
	var gente := 0
	var acera := true
	for e2 in J.ents:
		if e2.get("veh"):
			coches += 1
			acera = acera and (int(e2.y) == 10 or int(e2.y) == 11) and e2.moving
		elif String(e2.id).begins_with("demoG"):
			gente += 1
	var py: int = J.P.y
	J.demo_sale(sv)
	chk(coches >= 3 and acera, "el título: %d vehículos por la calzada" % coches)
	chk(gente >= 2 and py != 10 and py != 11, "el título: %d más andando y el protagonista por la acera (fila %d)" % [gente, py])
	Datos.CAL = false
	J.demo_e = null
	sv = J.demo_entra(5000.0)
	var hay := false
	for e2 in J.ents:
		hay = hay or e2.get("veh") != null
	J.demo_sale(sv)
	chk(not hay, "sin CAL, el título de antes")
	Datos.CAL = true
	J.demo_e = null
	J.mode = "world"
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
		J.VIAJE_V = null
	print("viaje: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)
