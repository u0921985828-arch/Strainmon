# Landrace Hunters (Godot) — el controlador de clima, a la vista (kaiacult.gd vista_clima, con CAL; lo pidió el usuario: «el
# controlador de clima de KAIA, que sea visual, también aplicar a la nave»): el cuadro de KAIA y el de la nave abren la pantalla del
# controlador con la temperatura, la humedad, el VPD, las 24 horas del temporizador y el extractor; A, a lo de siempre; B, cerrar.
#   $GODOT --headless --path godot --script res://tests/clima_vista.gd [-- --salida DIR]   → «clima_vista: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Atlas = preload("res://src/atlas.gd")
const Vista = preload("res://src/vista.gd")

var J
var M
var LOG := []
var MENUS := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
			break
	o = o.duplicate()
	o.initial = k
	return o

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	var k := 0
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		k += 1
		if J.handlers.size() and k % 12 == 0:   # el piloto: A a lo que salga
			J.press("A")
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo ", J.mode, " ", J.lock, " ", J.handlers.size(), " ", J.pending.size(), " ", st.fin)
			return false
	return true

# con la vista abierta: corre f y confirma con A lo que salga encima (menús y textos), no la vista
func hace(f: Callable) -> bool:
	var st := {"fin": false}
	var h0: int = J.handlers.size()
	var co := func():
		await f.call()
		st.fin = true
	co.call()
	var t0: float = M.reloj
	var k := 0
	while not st.fin:
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo en la vista")
			return false
		k += 1
		if J.handlers.size() > h0 and k % 12 == 0:
			J.press("A")
	return true

# abre la carpa ci (mitad h) y espera a la vista; devuelve el estado de la corrutina (fin)
func foto(dir: String, k: String) -> void:
	if dir == "":
		return
	J.toast_box.hide()
	for q in 2:
		await process_frame
		J.pintor.redibuja(M.reloj)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("clima-%s.png" % k))

func planta(sid: String, prog: float) -> Dictionary:
	var p: Dictionary = Cultivo.nueva_planta(J.S, sid)
	p.prog = prog
	p.water = 80.0
	return p

# abre la vista del clima s, espera, saca la foto k y la cierra con b; devuelve lo que devolvió la vista
func vista(s: String, dir: String, k: String, b: String):
	var st := {"fin": false, "r": null}
	J.oraculo = false
	var gm = J.gancho_menu
	J.gancho_menu = Callable()
	var co := func():
		st.r = await J.vista_clima(s)
		st.fin = true
	co.call()
	for i in 30:
		M.paso()
	var abierta: bool = J.CLIMA_V != null and String(J.CLIMA_V.s) == s
	await foto(dir, k)
	print("  vista ", s, " h=", J.handlers.size(), " modo=", J.mode, " lock=", J.lock)
	J.press(b)
	var t0: float = M.reloj
	while not st.fin and M.reloj - t0 < 20000 and M.paso():
		pass
	J.oraculo = true
	J.gancho_menu = gm
	return [abierta, st.r, J.CLIMA_V == null]

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-clima-vista.json"
	Juego.AJUSTES = "user://prueba-clima-vista-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	var dir := arg("--salida")
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D: Dictionary = J.D
	var C: String = D.KAIA_CULT.mapa
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	if not (J.S.get("mar") is Dictionary):
		J.S.mar = {}
	J.S.mar.lic = int(J.S.day)
	J.S.nave = J.nave_nueva()
	J.S.kc = {"niv": 0, "kits": [0, 0, 0, 0], "p": []}
	J.kc()
	J.S.min = 12 * 60
	# 1 · KAIA: el clima de la sala, a 18/6 mientras crecen
	J.kc().p[0] = planta("txoko", 0.2)
	J.kc().p[1] = planta("txoko", 0.4)
	var c: Dictionary = J.clima_v("kaia")
	chk(absf(float(c.t) - float(D.KAIA_CULT.clima.t)) < 1.0 and float(c.hr) >= 40 and float(c.hr) <= 70 and c.luz and int(c.hz) == 18, "KAIA a mediodía: %s °C, %s %%, luz a %d/%d" % [c.t, c.hr, c.hz, 24 - int(c.hz)])
	chk(float(c.vpd) > .8 and float(c.vpd) < 1.8 and c.graf.size() == 24 and c.graf.filter(func(g): return g[1]).size() == 18, "el VPD (%.2f kPa) y las 24 horas, 18 con luz" % float(c.vpd))
	J.S.min = 3 * 60
	c = J.clima_v("kaia")
	chk(not c.luz and float(c.t) < float(D.KAIA_CULT.clima.t) and float(c.hr) > float(D.KAIA_CULT.clima.hr), "a las 3, la noche del temporizador: más fresco y más húmedo (%s °C, %s %%)" % [c.t, c.hr])
	J.kc().p[1] = planta("txoko", 0.9)
	J.S.min = 12 * 60
	c = J.clima_v("kaia")
	chk(int(c.hz) == 12 and c.graf.filter(func(g): return g[1]).size() == 12, "con una en flor, 12/12")
	J.S.min = 20 * 60
	chk(not J.clima_v("kaia").luz, "a 12/12, a las 20 ya a oscuras")
	# cada carpa con su temporizador: otra en crecimiento, a 18/6; la pantalla lo dice y a las 20 sigue la luz en esa
	J.kc().p[J.kc_off(1)] = planta("txoko", 0.3)
	c = J.clima_v("kaia")
	chk(c.mix and int(c.hz) == 18 and c.luz and int(c.nf) == 3, "dos carpas, una en flor y otra creciendo: 12/12 y 18/6 (%s)" % [c])
	J.kc().p[J.kc_off(1)] = null
	# la sala reformada: las plantas, en las mesas (S.kc.m), no en S.kc.p
	var kc0: Dictionary = J.S.kc.duplicate(true)
	J.S.min = 12 * 60
	J.S.kc = {"niv": 2, "kits": [-1, -1, -1, -1, -1, -1, -1], "p": [], "v": 2, "f2": 0, "m": []}
	J.kc()
	for i in 6:
		J.kc().m.append({"k": "txoko", "dia": int(J.S.day), "p": 0.3 if i < 5 else 0.9, "thc": 18.0, "y": 1.0, "g": 0, "t": 0, "abo": 1, "dn": 0, "am": 0, "ao": 0, "n": 0})
	c = J.clima_v("kaia")
	chk(J.kc_f2() and int(c.nf) == 6 and c.luz and float(c.cg) > 0 and c.mix, "con las mesas: 6 con plantas, la luz encendida y la extracción en marcha (%s)" % [c])
	J.S.kc = kc0
	J.kc()
	J.S.min = 12 * 60
	J.enter_map(C, 2, 2, "up")
	J.mode = "world"
	var nm1 := MENUS.size()
	chk(corre(func(): await J.kc_cuadro()) and MENUS.size() > nm1, "con el piloto de las pruebas, el menú de siempre (%s)" % [MENUS.slice(-1)])
	var r = await vista("kaia", dir, "kaia", "B")
	chk(r[0] and r[1] == false and r[2], "A en el cuadro de KAIA: la pantalla del clima; B la cierra (%s)" % [r])
	var nm0 := MENUS.size()
	J.oraculo = false
	var gm = J.gancho_menu
	J.gancho_menu = Callable()
	var st := {"fin": false}
	var co := func():
		await J.kc_cuadro()
		st.fin = true
	co.call()
	for i in 30:
		M.paso()
	chk(J.CLIMA_V != null, "el cuadro de KAIA abre primero la pantalla del clima")
	J.press("B")
	var t0: float = M.reloj
	while not st.fin and M.reloj - t0 < 20000 and M.paso():
		pass
	J.oraculo = true
	J.gancho_menu = gm
	chk(st.fin and MENUS.size() == nm0, "y con B se sale sin el menú del cuadro")
	# 2 · la nave: cuatro mesas de sodio sin extracción, el sofoco
	for i in 4:
		J.S.nave.m[i] = {"k": "txoko", "dia": int(J.S.day), "p": 0.5}
		J.S.nave.f[i] = "sodio"
	J.S.nave.ex = 0
	c = J.clima_v("nave")
	chk(float(c.t) > float(D.T_OK[1]) and float(c.cg) > 1.0 and int(c.nf) == 4 and int(c.hz) == 18, "la nave con 4 de sodio y sin extracción: %.1f °C, carga %d %%" % [float(c.t), roundi(100 * float(c.cg))])
	# la pantalla y el juego, de acuerdo: en cuanto el calor pasa de lo que saca la extracción, el sofoco (sofoco_nave) y el aviso
	J.S.nave.f[2] = "led"
	J.S.nave.m[3] = null
	for ex in D.EXTR_NAVE.size():
		J.S.nave.ex = ex
		c = J.clima_v("nave")
		chk((float(c.sof) < 1.0) == (float(c.t) > float(D.T_OK[1])) and (float(c.sof) < 1.0) == (float(c.cg) > 1.0), "extracción %d: carga %d %%, %.1f °C, sofoco %.2f" % [ex, roundi(100 * float(c.cg)), float(c.t), float(c.sof)])
	J.S.min = 2 * 60
	var tn: float = float(J.clima_v("nave").t)
	J.S.min = 12 * 60
	chk(is_equal_approx(tn, float(J.clima_v("nave").t)), "el calor de la nave no depende de la hora (%.1f °C)" % tn)
	J.S.nave.f[2] = "sodio"
	J.S.nave.m[3] = {"k": "txoko", "dia": int(J.S.day), "p": 0.5}
	J.S.nave.ex = 0
	r = await vista("nave", dir, "nave-calor", "A")
	chk(r[0] and r[1] == true and r[2], "la pantalla de la nave; A, a lo de siempre (%s)" % [r])
	J.S.nave.ex = D.EXTR_NAVE.size() - 1
	c = J.clima_v("nave")
	chk(float(c.t) >= float(D.T_OK[0]) and float(c.t) <= float(D.T_OK[1]) and float(c.cg) <= 1.0, "con dos de 315 mm: %.1f °C, carga %d %%" % [float(c.t), roundi(100 * float(c.cg))])
	J.S.nave.m[2].p = 0.9
	c = J.clima_v("nave")
	chk(int(c.hz) == 12, "una mesa en flor: la nave a 12/12")
	J.S.min = 2 * 60
	r = await vista("nave", dir, "nave-noche", "B")
	chk(r[0] and r[1] == false, "de noche, con B, cerrada")
	J.S.nave.m = [null, null, null, null]
	J.S.nave.m.resize(int(D.NAVE.max))
	c = J.clima_v("nave")
	chk(int(c.nf) == 0 and not c.luz and float(c.cg) == 0.0, "la nave vacía: sin luz y sin carga")
	# 3 · sin CAL, como antes
	Datos.CAL = false
	chk(await J.vista_clima("nave") == true and J.CLIMA_V == null, "sin CAL, sin pantalla")
	Datos.CAL = true
	for x in fallos:
		print("  FALLO ", x)
	print("clima_vista: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
