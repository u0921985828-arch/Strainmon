# Landrace Hunters (Godot) — las carpas de KAIA por dentro, como las de casa (kaiacult.gd kc_vista, con CAL; lo pidió el usuario:
# «te dije que como las de casa… ese sistema no me gusta nada, tiene que ser visual»): A en una carpa de KAIA abre la vista de la
# carpa de casa (mode carpa) con sus plantas en filas, sus LED repartidos a lo ancho y el temporizador; plantar desde la vista; el
# tiempo y el guardado con lo de casa en su sitio; al salir, todo como estaba; las tres carpas (la de 400 × 400, por mitades) y los
# esquemas de 4 a 32 plazas; sin el atlas, la lista de siempre.
#   $GODOT --headless --path godot --script res://tests/kaia_vista.gd [-- --sin-arranque --salida DIR]   → «kaia_vista: N comprobaciones, 0 fallos»
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

# la vista de una mesa con plantas (lo pidió el usuario: «los sprites de las plantas no están dentro de la bandeja»; «el visor estilo a
# casa con la carpa de fondo»): las cinco macetas de casa con el pie en el fondo de la bandeja (o-mesaF, filas 12 a 24) y dentro de su
# ancho; cada planta encima de su maceta; los dos LED de 720 de casa, por encima de todas las plantas; el canto de delante encima
func mesa_dentro(R: Array, que: String) -> void:
	var A = load("res://src/arte.gd")
	var mf: Image = load("res://src/escena_extr.gd").pl("o-mesaF")
	var mi: Image = A.foto("maceta-c-tela11-20")
	var led: Image = A.foto(J.MESAK_LED)
	var x0: int = (J.SW - 240) >> 1
	var my: int = J.MAD_H - 2 - mf.get_height()
	var mx: int = x0 + ((240 - mf.get_width()) >> 1)
	var mac := []
	var leds := []
	var pl := []
	var canto := -1
	for j in R.size():
		var q = R[j]
		if not (q is Array and q.size() > 3 and q[0] is String and q[0] == "@"):
			continue
		if q[1] is Image and q[1].get_size() == mi.get_size() and q[1].get_data() == mi.get_data():
			mac.append([int(q[2]), int(q[3]) + mi.get_height(), j])
		elif q[1] is Image and q[1].get_size() == led.get_size() and q[1].get_data() == led.get_data():
			leds.append(int(q[3]) + led.get_height())
		elif q[1] == mf and q.size() > 4 and q[4] is Rect2i and q[4].position.y == my + J.MESAK_CANTO:
			canto = j
		elif q[1] is Image and q[1] != mf and not mac.is_empty() and mac[-1][2] == j - 1:
			pl.append([int(q[3]) + q[1].get_height() - A.alto(q[1]), int(q[3]) + q[1].get_height(), int(q[2]) + (q[1].get_width() >> 1), mac[-1][0] + (mi.get_width() >> 1)])
	chk(mac.size() == 5, "%s: las cinco macetas (%d)" % [que, mac.size()])
	for m in mac:
		chk(m[1] >= my + 12 and m[1] <= my + J.MESAK_CANTO + 2 and m[0] >= mx + 8 and m[0] + mi.get_width() <= mx + 184, "%s: la maceta en la bandeja (x %d, base %d; la bandeja de %d a %d, el fondo de %d a %d)" % [que, m[0] - mx, m[1] - my, 8, 184, 12, J.MESAK_CANTO + 2])
		chk(canto > m[2], "%s: el canto de la bandeja, delante de la maceta" % que)
	chk(pl.size() == 5, "%s: una planta por maceta (%d)" % [que, pl.size()])
	var cima := 1000
	for p in pl:
		chk(absi(p[2] - p[3]) <= 1, "%s: la planta, centrada en su maceta (%d, %d)" % [que, p[2], p[3]])
		cima = mini(cima, p[0])
	chk(leds.size() == 2, "%s: el LED doble, los dos LED de 720 de casa (%d)" % [que, leds.size()])
	for b in leds:
		chk(b <= cima - 4, "%s: el LED por encima de las plantas (su pie %d, la cima %d)" % [que, b, cima])

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
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo")
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
func abre(ci: int, h := 0) -> Dictionary:
	var st := {"fin": false}
	var co := func():
		await J.run(func(): await J.kc_vista(ci, h))
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while J.mode != "carpa" and M.reloj - t0 < 20000 and M.paso():
		pass
	for i in 40:   # el fundido
		M.paso()
	return st

func cierra(st: Dictionary) -> bool:
	J.press("B")
	var t0: float = M.reloj
	while not st.fin and M.reloj - t0 < 20000 and M.paso():
		pass
	for i in 10:
		M.paso()
	return st.fin and J.mode == "world"

func foto(dir: String, k: String) -> void:
	if dir == "":
		return
	var o0: bool = J.oraculo
	J.oraculo = false
	J.toast_box.hide()
	J.dlg.hide()
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("kaia-vista-%s.png" % k))
	J.oraculo = o0   # como estaba (la vista de las mesas, con pantalla)

func dicho(t: String) -> bool:
	return LOG.any(func(l): return String(l).contains(t))

func planta(sid: String, prog: float) -> Dictionary:
	var p: Dictionary = Cultivo.nueva_planta(J.S, sid)
	p.prog = prog
	p.water = 80.0
	return p

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-kaia-vista.json"
	Juego.AJUSTES = "user://prueba-kaia-vista-ajustes.json"
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
	if J.S.get("nave") is Dictionary:
		if not J.S.nave.has("ma"):
			J.S.nave.ma = []
		if not J.S.nave.has("r"):
			J.S.nave.r = int(J.S.day) + 30
	J.S.kc = {"niv": 0, "kits": [0, 0, 0, 0], "p": []}
	J.kc()
	J.S.min = 12 * 60
	var casa_c: Array = J.S.carpas.duplicate(true)
	var casa_n: int = J.S.pots.size()
	var casa_m: Array = J.S.macetas.duplicate()
	J.kc().p[0] = planta("txoko", 0.2)
	J.kc().p[1] = planta("txoko", 0.6)
	J.kc().p[3] = planta("txoko", 0.9)
	J.enter_map(C, 4, 5, "up")
	J.mode = "world"
	corre(func(): pass)
	# 1 · la carpa de 200 × 200 por dentro: la vista de casa, con sus 4 plazas, 2 LED y el temporizador
	var st := abre(0)
	chk(J.mode == "carpa" and J.VC != null and J.KCV != null, "A en la carpa de KAIA: la vista de la carpa, como en casa (%s)" % J.mode)
	chk(J.S.carpas.size() == 1 and String(J.S.carpas[0].t).begins_with("kcs4") and J.S.pots.size() == 4 and D.CARPAS.has(J.S.carpas[0].t), "la carpa de KAIA, con sus 4 plazas: %s" % [J.S.carpas[0].get("t")])
	var g: Dictionary = Vista.geo(J.S, 0)
	chk(g.vc != null and g.pl.size() == 4 and g.vc.fxs.size() == 2 and g.vc.w <= Vista.VC_KC_W + 1, "la vista C: 4 plazas, 2 LED a lo ancho (%s), %d px" % [g.vc.fxs if g.vc else null, g.vc.w if g.vc else 0])
	chk(J.S.pots[0] == J.kc().p[0] and J.S.pots[3] == J.kc().p[3] and J.S.pots[2] == null, "las plantas, las de KAIA")
	await foto(dir, "s4")
	# plantar desde la vista, en la plaza vacía (con su hu: en S.kc.p)
	J.S.seeds.txoko = int(J.S.seeds.get("txoko", 0)) + 3
	J.VC.sel = 2
	QUIERO = [J.strain("txoko").n]
	J.VC.ocupado = true
	chk(hace(func(): await J._vc_accion()) and J.kc().p[2] is Dictionary and J.S.pots[2] == J.kc().p[2], "plantar desde la vista: a S.kc.p (%s)" % [J.kc().p[2]])
	# el tiempo: lo de casa sigue en su sitio y KAIA crece una vez
	var pr0: float = float(J.kc().p[0].prog)
	J.advance_time(60)
	chk(J.S.carpas.size() == 1 and J.KCV.get("bak") != null and float(J.kc().p[0].prog) > pr0, "pasa una hora con la vista abierta: crece (%.4f → %.4f) y la vista sigue" % [pr0, float(J.kc().p[0].prog)])
	var pr1: float = float(J.kc().p[0].prog)
	J.kc_vista_off()
	J.kc_avanza(60)
	var dk: float = float(J.kc().p[0].prog) - pr1
	J.kc().p[0].prog = pr1
	J.kc_vista_on()
	chk(absf((pr1 - pr0) - dk) < 1e-6, "una sola vez, no dos: %.5f y %.5f" % [pr1 - pr0, dk])
	# guardar con la vista abierta: la partida, con las carpas de casa
	J.save()
	var sv = JSON.parse_string(FileAccess.get_file_as_string(Juego.GUARDADO))
	chk(sv is Dictionary and sv.carpas.size() == casa_c.size() and sv.pots.size() == casa_n and not str(sv.carpas).contains("kcs"), "guardada con lo de casa: %d carpas, %d plazas" % [sv.carpas.size() if sv is Dictionary else -1, sv.pots.size() if sv is Dictionary else -1])
	chk(J.S.carpas.size() == 1, "y la vista, otra vez con la de KAIA")
	# la copia en la nube al pausar la app (retencion.gd al_pausar), también con lo de casa
	var stub := Node.new()
	var sc := GDScript.new()
	sc.source_code = "extends Node\nvar t := \"\"\nfunc nube_guarda(x: String) -> void:\n\tt = x\n"
	sc.reload()
	stub.set_script(sc)
	var pn = J.plat_n
	J.plat_n = stub
	var pl0: bool = Datos.PLAY
	Datos.PLAY = true
	J.al_pausar()
	Datos.PLAY = pl0
	J.plat_n = pn
	var nb = JSON.parse_string(String(stub.t))
	chk(nb is Dictionary and nb.carpas.size() == casa_c.size() and nb.pots.size() == casa_n and not String(stub.t).contains("kcs") and J.S.carpas.size() == 1, "la copia de la nube al pausar, con lo de casa (%d carpas) y la vista sigue" % [nb.carpas.size() if nb is Dictionary else -1])
	stub.free()
	# ni misiones ni logros por lo de KAIA (S.carpas es la suya mientras la vista está abierta)
	J.S.logros.erase("goteo")   # la carpa de KAIA lleva goteo; la de casa, no
	var lg0: Dictionary = J.S.logros.duplicate()
	var mi0: Dictionary = J.S.misiones.duplicate()
	var trampa: bool = J.logro_ok("goteo")
	J.revisa_logros()
	J.revisa_misiones()
	chk(trampa and J.S.logros == lg0 and J.S.misiones == mi0, "con la vista abierta (goteo a la vista: %s), ni logros ni misiones nuevos" % trampa)
	# el temporizador, el de esta carpa
	J.VC.sel = Vista.SEL_TEMP
	J.VC.ocupado = true
	QUIERO = [D.CICLOS.flor.m]
	hace(func(): await J._vc_accion())
	var ck: String = Cultivo.ciclo_de(J.kc_cc(0))
	chk(QUIERO.is_empty() and ck != "auto" and J.kc_f(0).ciclo == ck, "el temporizador, en su carpa y en lo que crece: %s" % ck)
	J.VC.sel = -1
	MENUS = []
	J.VC.ocupado = true
	hace(func(): await J._vc_accion())
	chk(MENUS.size() and MENUS[0].has("Esquema de la carpa") and MENUS[0].has("Salir"), "A en los LED: su equipo y el esquema: %s" % [MENUS])
	chk(cierra(st), "B: fuera")
	chk(J.KCV == null and J.S.carpas.size() == casa_c.size() and J.S.pots.size() == casa_n and J.S.macetas == casa_m and not D.CARPAS.keys().any(func(k): return String(k).begins_with("kc")), "al salir, lo de casa como estaba")
	chk(J.kc_cc(0).get("t") == null and J.kc().p[2] is Dictionary, "y lo de KAIA, guardado en S.kc")
	chk(J.S.logros.keys().all(func(l): return lg0.has(l) or J.logro_ok(l)), "al salir, ningún logro que no se cumpla en casa (%s)" % [J.S.logros.keys().filter(func(l): return not lg0.has(l))])
	# 2 · el esquema de 16 de 25 L: 4 filas
	J.S.kc.pat = [{"m": "tela25", "n": 16}]
	J.kc()
	st = abre(0)
	g = Vista.geo(J.S, 0)
	chk(g.vc != null and g.pl.size() == 16 and int(g.C.filas) == 4 and int(g.C.cols) == 4, "16 de 25 L: 4 × 4 en la vista (%d)" % g.pl.size())
	var ys := {}
	for q in g.pl:
		ys[q.y] = 1
	chk(ys.size() == 4 and ys.keys().all(func(y): return int(y) >= 140 and int(y) <= 158), "cuatro filas en el suelo: %s" % [ys.keys()])
	await foto(dir, "s16")
	cierra(st)
	# 3 · la de 400 × 200 (8 plazas, 4 LED) y 18 de 35 L
	J.S.kc = {"niv": 1, "kits": [0, 0], "p": []}   # la de antes, de un nivel: a los sitios de su tamaño
	J.kc()
	var c4: int = J.kc_base(1)
	var o4: int = J.kc_off(c4)
	for i in 6:
		J.kc().p[o4 + i] = planta("txoko", 0.15 * i + 0.1)
	st = abre(c4)
	g = Vista.geo(J.S, 0)
	chk(g.vc != null and g.pl.size() == 8 and g.vc.fxs.size() == 4 and int(g.C.filas) == 2, "400 × 200: 8 plazas en 2 filas y 4 LED (%d)" % g.pl.size())
	await foto(dir, "m8")
	cierra(st)
	var pt: Array = J.S.kc.pat if J.S.kc.get("pat") is Array else []
	while pt.size() <= c4:
		pt.append(null)
	pt[c4] = {"m": "tela35", "n": 18}
	J.S.kc.pat = pt
	J.kc()
	st = abre(c4)
	g = Vista.geo(J.S, 0)
	chk(g.vc != null and g.pl.size() == 18 and int(g.C.filas) == 3, "18 de 35 L: 6 × 3 (%d)" % g.pl.size())
	await foto(dir, "m18")
	cierra(st)
	# 4 · la de 400 × 400, por mitades: delante y al fondo
	J.S.kc = {"niv": 2, "kits": [0], "p": []}
	J.kc()
	var c6: int = J.kc_base(2)
	var o6: int = J.kc_off(c6)
	for i in 16:
		J.kc().p[o6 + i] = planta("txoko", 0.05 * i + 0.1)
	st = abre(c6)
	g = Vista.geo(J.S, 0)
	chk(J.kc_mitades(c6) == 2 and g.vc != null and g.pl.size() == 8 and int(J.KCV.a) == o6 and g.vc.fxs.size() == 4, "400 × 400: la mitad de delante, 8 plazas y 4 LED (%d %d %s %d %s)" % [J.kc_mitades(c6), g.pl.size(), J.KCV.get("a") if J.KCV else null, g.vc.fxs.size() if g.vc else -1, J.mode])
	MENUS = []
	QUIERO = ["Ver la mitad del fondo"]
	J.VC.sel = -1
	J.VC.ocupado = true
	hace(func(): await J._vc_accion())
	var t0: float = M.reloj
	while not (J.KCV != null and int(J.KCV.h) == 1 and J.mode == "carpa") and M.reloj - t0 < 20000 and M.paso():
		pass
	for i in 40:
		M.paso()
	chk(J.KCV != null and int(J.KCV.h) == 1 and int(J.KCV.a) == o6 + 8 and J.S.pots[0] == J.kc().p[o6 + 8], "la mitad del fondo: de la plaza 9 a la 16 (%s %s)" % [J.KCV, J.mode])
	await foto(dir, "l-fondo")
	chk(cierra(st) and J.KCV == null and J.S.carpas.size() == casa_c.size(), "B: fuera, con lo de casa")
	# 4b · la carpa de sala: A en una mesa abre su vista (la pared de la carpa, el LED doble y la mesa con sus plantas)
	J.S.kc = {"niv": 2, "kits": [-1, -1, -1, -1, -1, -1, -1], "p": [], "v": 2, "f2": 0, "m": []}
	J.kc()
	var ms := []   # kc() deja la sala de antes con sus ocho mesas vacías: aquí, las de la prueba, de una vez
	for i in 8:
		ms.append(null if i == 5 else {"k": "txoko", "f": Cultivo.nueva_planta(J.S, "txoko").f, "thc": 18.0, "y": 1.0, "dia": J.S.day, "g": 0, "t": 0, "abo": 1, "p": [.05, .3, .5, .7, .9, 0, .4, .8][i], "dn": 0, "am": 0, "ao": 0, "n": 0})
	J.kc().m = ms
	var SA: String = J.D.KAIA_CULT.f2.sala
	J.enter_map(SA, 6, 7, "up")
	J.S.min = 12 * 60
	J.oraculo = false   # la vista solo sale con pantalla
	J.update_hud()
	var mp: Array = J.D.KAIA_CULT.f2.mesas[2]
	var stm := {"fin": false}
	var com := func():
		await J.run(func(): await J.kc_obj(int(mp[0]), int(mp[1]), J.MAPS[SA].o[int(mp[1])][int(mp[0])]))
		stm.fin = true
	com.call()
	var t1: float = M.reloj
	while J.MESA_KV == null and M.reloj - t1 < 20000 and M.paso():
		pass
	chk(J.MESA_KV != null and int(J.MESA_KV.i) == 2 and not J.hud.visible, "A en la mesa 3: su vista, sin el HUD encima")
	var R: Array = J.rects_mesak(J.MESA_KV)
	var imgs := 0
	for q in R:
		if q is Array and q.size() > 1 and q[0] is String and q[0] == "@":
			imgs += 1
	chk(imgs >= 4, "la pared, los dos LED y la mesa: %d imágenes" % imgs)
	mesa_dentro(R, "mesa 3")
	await foto(dir, "mesa-veg")
	J.press("right")
	M.paso()
	chk(int(J.MESA_KV.i) == 3, "▶: la mesa 4")
	mesa_dentro(J.rects_mesak(J.MESA_KV), "mesa 4")
	var th: float = M.reloj
	while M.reloj - th < 1500 and M.paso():   # el reloj sigue y el HUD se refresca cada 250 ms: no vuelve encima de la vista
		pass
	chk(J.MESA_KV != null and not J.hud.visible, "con el reloj andando, el HUD sigue sin salir encima de la vista")
	await foto(dir, "mesa-flor")
	J.press("down")
	M.paso()
	chk(int(J.MESA_KV.i) == 7, "▼: la de debajo, la 8")
	J.press("down")
	M.paso()
	chk(int(J.MESA_KV.i) == 7, "▼ en la fila de abajo: se queda")
	J.press("left")
	J.press("left")
	M.paso()
	chk(int(J.MESA_KV.i) == 5 and J.desc_mesak(J.MESA_KV).contains(J.K("vacía")), "la 6, vacía: %s" % J.desc_mesak(J.MESA_KV))
	J.S.min = 2 * 60
	chk(not J.luz_mesak(7) and J.luz_mesak(0) == false, "a las 2 de la noche, el LED apagado")
	J.S.min = 20 * 60
	chk(J.luz_mesak(0) and not J.luz_mesak(7), "a las 20: la que crece, a 18/6, encendida; la de flor, a 12/12, apagada")
	await foto(dir, "mesa-v")
	J.press("B")
	t1 = M.reloj
	while not stm.fin and M.reloj - t1 < 20000 and M.paso():
		pass
	chk(stm.fin and J.MESA_KV == null and J.hud.visible, "B: fuera, con el HUD")
	J.S.min = 12 * 60
	J.oraculo = true
	# 5 · sin CAL o sin licencia, como antes
	J.S.mar.erase("lic")
	LOG = []
	chk(hace(func(): await J.kc_carpa(0)) and J.KCV == null and dicho("licencia"), "sin la licencia, nada")
	print("kaia_vista: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
