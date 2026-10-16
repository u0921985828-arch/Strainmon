# Ribera Verde (Godot) — 1.47: los muebles a escala con el protagonista (lo pidió el usuario: «el mobiliario debe de ser a escala
# realista para con el personaje, también en los clubs, casas y demás») y sentarse a fumarse uno (escala.py, e-<sprite>, con CAL).
#   $GODOT --headless --path godot --script res://tests/escala.gd   → «escala: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también esc-<mapa>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

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

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() and not labels.has("TENGO 18 O MÁS") else ""
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
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func llega(mapa: String, de: Array, a: Array) -> bool:
	var m: Dictionary = J.MAPS[mapa]
	var v := {"%d,%d" % de: true}
	var q := [de]
	while q.size():
		var c: Array = q.pop_front()
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			var nx: int = c[0] + d[0]
			var ny: int = c[1] + d[1]
			if nx == a[0] and ny == a[1]:
				return true
			var kk := "%d,%d" % [nx, ny]
			if not v.has(kk) and nx >= 0 and ny >= 0 and nx < int(m.w) and ny < int(m.h) and J.pisable(m, nx, ny) and not m.o[ny][nx]:
				v[kk] = true
				q.append([nx, ny])
	return false

func foto(dir: String, k: String) -> void:
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("esc-%s.png" % k))


const LUGARES := ["home", "casa-ama", "txaro", "bar", "shop", "growcity", "club-rv", "club-ibar", "club-puerto", "club-valde", "club-ens", "disco", "nave", "setas", "comisaria", "almacen", "conce", "camarote", "loc-rv", "loc-puerto", "loc-valde", "loc-erro", "loc-ibar"]

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-escala.json"
	Juego.AJUSTES = "user://prueba-escala-ajustes.json"
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
	S.loc = {}
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
		for k in LUGARES:
			var m: Dictionary = J.MAPS[k]
			var ex: Array = m.exits.keys()[0].split(",")
			J.enter_map(k, int(ex[0]), int(m.h) - 2, "up")
			J.mode = "world"
			await foto(dir, k)
			await foto(dir, k)
		J.set_process(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · los muebles a escala: cada e-<sprite>, más alto que el de antes y, con CAL, el que se pinta
	var esc := 0
	for g in ["escala-alto", "escala-ancho"]:
		for k in Atlas.d.cubre:
			if Atlas.d.cubre[k] == g:
				var o: String = k.trim_prefix("obj:e-")
				var fe = Atlas.frame_de(g, "e-" + o, "unica", 0, {"i": 0})
				var f0 = Atlas.frame_de(Atlas.cubre("obj:" + o), o, "unica", 0, {"i": 0})
				if fe and f0:
					esc += 1
					chk(fe.c.get_used_rect().size.y > f0.c.get_used_rect().size.y, "%s: más alto (%d > %d)" % [o, fe.c.get_used_rect().size.y, f0.c.get_used_rect().size.y])
	chk(esc >= 20, "muebles a escala: %d" % esc)
	chk(Atlas.cubre("obj:e-table") == "escala-alto" and Atlas.cubre("obj:e-sofaF") == "escala-ancho", "los grupos de escala")
	# el box del lavadero: 5 casillas (80 px), como los coches del concesionario
	var mr: Dictionary = J.MAPS["loc-rv"]
	chk(mr.o[4][1] == "boxL" and range(2, 6).all(func(x): return mr.o[4][x] == "boxL2"), "lavadero: el box de 5 casillas")
	var fb = Atlas.frame_de("negocios-coche", "boxL", "unica", 0, {"i": 0})
	chk(fb != null and fb.c.get_width() == 80, "el box, 80 px")
	# 2 · sentarse (1.47): el banco de la calle, fumarse uno (medio gramo, calor +3) y levantarse
	S.buds = {"ak47": {"g": 10.0, "thc": 18.0, "dia": S.day}}
	S.heat = 0
	S.items.papel = 50   # 1.47: el papel y el mechero, del estanco
	S.items.mechero = 1
	J.enter_map("town", 16, 17, "up")
	J.mode = "world"
	chk(J.asiento_de("bench") == "bench" and J.asiento_de("sofaF2") == "sofaF" and J.asiento_de("sillaG2") == "sillaG" and J.asiento_de("bancoT") == "", "los asientos")
	# 1.49 (lo pidió el usuario: «que te puedas sentar de verdad»): sentarte es quedarte sentado; con A, lo de sentado
	LOG = []
	QUIERO = ["Sentarte"]
	var dir0: String = J.P.dir
	chk(corre(func(): J.interact()) and J.SENT != null and J.SENT.k == "bench" and J.P.dir == "down", "el banco: sentado y se queda (%s)" % [J.SENT])
	chk(J.is_free(), "sentado, el mundo sigue (libre)")
	QUIERO = ["Fumarte uno"]
	chk(corre(func(): await J.menu_sentado()) and is_equal_approx(float(S.buds.ak47.g), 9.5) and J.SENT != null and float(S.heat) == 3.0
		and LOG.any(func(t): return t.contains("llama la atención")), "el banco: fumado y sigues sentado (%s g, calor %s, %s)" % [S.buds.ak47.g, S.heat, LOG])
	LOG = []
	QUIERO = ["Quedarte un rato"]
	var m0: int = int(S.min)
	chk(corre(func(): await J.menu_sentado()) and float(S.heat) == 2.0 and int(S.min) != m0 and J.SENT != null, "un rato en el banco: calor 2 (%s)" % S.heat)
	QUIERO = ["Levantarte"]
	chk(corre(func(): await J.menu_sentado()) and J.SENT == null and J.P.dir == dir0, "levantarte desde el menú")
	QUIERO = ["Sentarte"]
	corre(func(): J.interact())
	J.dir_order = ["left"]
	J.update_player(16.0)
	J.dir_order = []
	chk(J.SENT == null and J.P.dir == "left" and not J.P.moving, "una flecha te levanta, sin dar el paso")
	J.P.dir = "up"
	QUIERO = ["Sentarte"]
	corre(func(): J.interact())
	J.levantarte()
	chk(J.SENT == null and J.P.dir == "up", "B te levanta")
	# sin nada encima: no se lía
	S.buds = {}
	LOG = []
	QUIERO = ["Sentarte"]
	corre(func(): J.interact())
	QUIERO = ["Fumarte uno"]
	chk(corre(func(): await J.menu_sentado()) and LOG.any(func(t): return t.contains("No llevas")) and J.SENT != null, "sin hierba: %s" % [LOG])
	J.enter_map("town", 16, 17, "up")
	chk(J.SENT == null, "al cambiar de mapa, de pie")
	# en el bar no se fuma, pero se pide algo sentado en el taburete
	S.buds = {"ak47": {"g": 10.0, "thc": 18.0, "dia": S.day}}
	J.enter_map("bar", 1, 5, "up")
	LOG = []
	QUIERO = ["Sentarte"]
	corre(func(): J.interact())
	QUIERO = ["Fumarte uno"]
	chk(corre(func(): await J.menu_sentado()) and float(S.buds.ak47.g) == 10.0 and LOG.any(func(t): return t.contains("no se puede fumar")), "el bar: %s" % [LOG])
	S.money = 10.0
	MENUS = []
	QUIERO = ["Pedir algo", "Una caña"]
	chk(corre(func(): await J.menu_sentado()) and is_equal_approx(float(S.money), 7.5) and J.SENT != null, "una caña en el taburete: %s € %s" % [S.money, MENUS.slice(0, 2)])
	J.levantarte()
	# en el club, en el sofá: hablar con el socio de al lado
	var sc := []
	var mc: Dictionary = J.MAPS["club-ibar"]
	J.enter_map("club-ibar", 1, 6, "up")
	var so = null
	for en in J.ents:
		if en.id == "socio":
			so = en
	for y in mc.h:
		for x in mc.w:
			if so and J.asiento_de(mc.o[y][x]) != "" and absi(so.x - x) <= 1 and absi(so.y - y) <= 1 and sc.is_empty():
				sc = [x, y]
	chk(so != null and sc.size() == 2, "el club: un sofá junto al socio (%s)" % [sc])
	if sc.size() == 2:
		J.sentado(sc[0], sc[1], J.asiento_de(mc.o[sc[1]][sc[0]]))
		MENUS = []
		QUIERO = ["Nada"]
		corre(func(): await J.menu_sentado())
		chk(MENUS.size() >= 1 and MENUS[0].any(func(t): return t.begins_with("Hablar con")) and MENUS[0].has("Pedir algo"), "el sofá del club: hablar y pedir %s" % [MENUS.slice(0, 1)])
		J.levantarte()
	J.enter_map("home", 4, 4, "up")
	MENUS = []
	QUIERO = ["Usar el ordenador"]
	chk(corre(func(): J.interact()) and MENUS.size() >= 2 and MENUS[0] == ["Sentarte", "Usar el ordenador", "Nada"], "la silla: el ordenador %s" % [MENUS.slice(0, 2)])
	# sin CAL, la silla como estaba (directa al ordenador)
	Datos.CAL = false
	MENUS = []
	QUIERO = []
	chk(corre(func(): J.interact()) and MENUS.size() >= 1 and not MENUS[0].has("Sentarte"), "sin CAL, sin sentarse %s" % [MENUS.slice(0, 1)])
	Datos.CAL = true
	J.oraculo = false
	if dir != "":
		J.set_process(false)
		for q in [["town", 16, 16, 17, "sur"], ["club-ibar", -1, -1, -1, "sur"], ["club-ibar", -2, -1, -1, "norte"], ["home", 4, 3, 4, "norte"]]:
			var mk: String = q[0]
			var mm: Dictionary = J.MAPS[mk]
			var sx: int = q[1]
			var sy: int = q[2]
			if sx < 0:   # el primer sofá de frente (-1) o de espaldas (-2) del club
				var want := "sofaF" if sx == -1 else "sofaB"
				for y in mm.h:
					for x in mm.w:
						if sx < 0 and mm.o[y][x] == want:
							sx = x
							sy = y
			J.enter_map(mk, sx, sy + 1, "up")
			J.mode = "world"
			J.SENT = {"x": sx, "y": sy, "d": q[4]}
			J.vfx = []
			J.P.dir = "down" if q[4] == "sur" else "up"
			await foto(dir, "sentado-%s-%s" % [mk, q[4]])
			await foto(dir, "sentado-%s-%s" % [mk, q[4]])
			J.SENT = null
	print("escala: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit()
