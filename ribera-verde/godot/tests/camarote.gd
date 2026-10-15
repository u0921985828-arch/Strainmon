# Ribera Verde (Godot) — 1.43.6: el camarote de arriba, de almacén (lo pidió el usuario): la obra, las estanterías de tarros de
# cristal de 10 L y los sobres de humedad al 62 % por la tienda online, la escalera entre las carpas, el mapa de arriba, la vista
# de los tarros, guardar y sacar, el curado y el afinado, los sobres que se gastan, la redada y, sin Datos.CAL, nada de esto.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-extr.
#   $GODOT --headless --path godot --script res://tests/camarote.gd   → «camarote: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también camarote-<caso>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Motor = preload("res://src/motor.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func arg(k: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else ""

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

func pinta(dir: String, k: String, A) -> void:
	J.ALMACEN = A
	if A != null:
		J._dlg_fijo(J.desc_almacen(A), "CAMAROTE")
	else:
		J.dlg.hide()
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	var im: Image = root.get_texture().get_image()
	im.save_png(dir.path_join("camarote-%s.png" % k))
	J.ALMACEN = null

func dias(k: int) -> void:
	for q in k:
		J.S.day += 1
		J.curado_dia([])

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-camarote.json"
	Juego.AJUSTES = "user://prueba-camarote-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	var dir := arg("--pintar")
	J.S = e.S
	J.S.erase("cam")
	J.enter_map("home", 9, 3, "up")
	J.mode = "world"
	var D = J.D
	var CM: Dictionary = D.CAMAROTE
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · sin camarote: ni escalera ni nada; la tienda online trae la fila, y sin dinero no pasa
	chk(not J.cam_ya() and J.MAPS.home.o[2][9] == null, "escalera sin obra: %s" % J.MAPS.home.o[2][9])
	J.S.banco = 100
	QUIERO = ["El camarote", CM.obra.n]
	chk(corre(J.tienda_online), "tienda bloqueada (sin dinero)")
	chk(MENUS.size() and MENUS[0].has("El camarote: almacén"), "sin fila del camarote: %s" % [MENUS])
	chk(not J.S.has("cam"), "obra sin dinero")
	# 2 · la obra: cobrada de la cuenta, al día siguiente
	J.S.banco = 10000
	MENUS = []
	QUIERO = ["El camarote", CM.obra.n]
	chk(corre(J.tienda_online), "tienda bloqueada (obra)")
	chk(J.S.banco == 10000 - CM.obra.p, "cobro de la obra %s" % J.S.banco)
	chk(J.S.get("cam") is Dictionary and int(J.S.cam.d) == int(J.S.day) + 1 and not J.cam_ya(), "obra pedida %s" % [J.S.get("cam")])
	chk(MENUS.size() >= 3 and MENUS[2][0].contains("mañana"), "fila de la obra pedida: %s" % [MENUS])
	# las estanterías y los sobres, solo con la obra pedida; hasta CAMAROTE.est.max
	MENUS = []
	QUIERO = ["El camarote", CM.est.n, CM.est.n, CM.sob.n]
	chk(corre(J.tienda_online), "tienda bloqueada (estanterías)")
	chk(J.S.cam.e.size() == 2 and J.S.cam.sp.size() == 1, "pedidos %s" % [J.S.cam])
	chk(J.S.banco == 10000 - CM.obra.p - 2 * CM.est.p - CM.sob.p, "cobro %s" % J.S.banco)
	# 3 · al día siguiente: la obra hecha, la escalera entre las carpas A y B, las estanterías y los sobres
	J.S.day += 1
	LOG = []
	chk(corre(func(): J.llega_mueble()), "llegada bloqueada")
	chk(J.cam_ya() and J.cam_est() == 2, "obra %s estanterías %d" % [J.cam_ya(), J.cam_est()])
	chk(J.cam_cap() == 2 * 6 * float(CM.tarro), "cap %s" % J.cam_cap())
	chk(float(J.S.cam.sob) == 12.0 and J.S.cam.sp.is_empty(), "sobres %s" % [J.S.cam])
	chk(" ".join(LOG).contains("escalera escamoteable") and " ".join(LOG).contains("3,48 kg"), "avisos: %s" % [LOG])
	J.montar_casa()
	chk(J.MAPS.home.o[int(CM.y)][int(CM.x)] == "escaleraC", "escalera %s" % J.MAPS.home.o[int(CM.y)][int(CM.x)])
	# ordenar: ni en la escalera ni delante
	chk(J.cabe_pieza("home", "mesa", int(CM.vuelta[0]), int(CM.vuelta[1]), null, false) != "", "la mesa delante de la escalera")
	chk(J.cabe_pieza("home", "mesa", int(CM.x), int(CM.y), null, false) != "", "la mesa en la escalera")
	# lo que estuviera puesto ahí vuelve a su sitio al montar la casa
	J.S.coloca = {"home": {"planta": [int(CM.vuelta[0]), int(CM.vuelta[1])]}}
	J.MAPS.home.carpasK = ""
	J.montar_casa()
	var pp: Array = J.pos_pieza("home", "planta")
	chk(pp != [int(CM.vuelta[0]), int(CM.vuelta[1])] and J.MAPS.home.o[int(CM.vuelta[1])][int(CM.vuelta[0])] == null and J.MAPS.home.o[int(CM.y)][int(CM.x)] == "escaleraC", "la planta, fuera de la escalera: %s" % [pp])
	if dir != "":
		J.set_process(false)
		J.enter_map("home", int(CM.vuelta[0]), int(CM.vuelta[1]), "up")
		await pinta(dir, "piso", null)
		await pinta(dir, "piso", null)
	# 4 · subir: el camarote con sus dos estanterías y la trampilla para bajar
	chk(corre(func(): await J.object_action(int(CM.x), int(CM.y))), "subir bloqueado")
	chk(J.S.map == "camarote" and int(J.P.x) == int(CM.desde[0]) and int(J.P.y) == int(CM.desde[1]), "arriba en %s (%d, %d)" % [J.S.map, J.P.x, J.P.y])
	var Mo: Array = J.MAPS.camarote.o
	chk(Mo[2][1] == "estanteC" and Mo[2][3] == "estanteC" and Mo[2][5] == null and Mo[2][7] == null, "estanterías: %s" % [Mo[2]])
	chk(J.MAPS.camarote.exits.has("4,5") and J.MAPS.camarote.exits["4,5"].to == "home", "trampilla")
	# 5 · guardar los cogollos: dos lotes, en tarros de 10 L
	var sid: String = D.DEX[0]
	var sid2: String = D.DEX[1]
	J.S.buds = {sid: {"g": 700.0, "thc": 15.0, "dia": J.S.day}, sid2 + "*": {"g": 100.0, "thc": 20.0, "dia": J.S.day}}
	LOG = []
	QUIERO = ["Todos los cogollos"]
	chk(corre(J._guardar_cam), "guardar bloqueado")
	chk(J.cam_g() == 800.0 and J.total_buds() == 0.0, "guardado %s fuera %s" % [J.cam_g(), J.total_buds()])
	var its: Array = J.items_almacen("cam")
	chk(its.size() == 1 + 3 + 1 and its[0].k == "+", "tarros %d" % its.size())
	chk(J.cam_tarros() == 4, "tarros ocupados %d" % J.cam_tarros())
	var R: Array = J.rects_almacen({"t": "cam", "i": 2})
	var spr := R.filter(func(r): return r[0] is String).map(func(r): return r[1])
	chk("alm-camarote" in spr and "alm-mas-xl" in spr and "alm-tarro-xl" in spr and "alm-tarro-xl-s" in spr, "vista: %s" % [spr])
	chk(spr.any(func(s): return s.begins_with("alm-cog-s-") and s.ends_with("-xl")), "lo de dentro, de 10 L: %s" % [spr])
	for r in R:
		if r[0] is String:
			chk(J.Atlas.sobre.has("misc:" + r[1]) or J.Atlas.cubre("misc:" + r[1]) != null, "sin sprite " + r[1])
	chk(J.desc_almacen({"t": "cam", "i": 0}).contains("Sobres de humedad: 12"), "desc: " + J.desc_almacen({"t": "cam", "i": 0}))
	# la rejilla: 6 por balda
	var A := {"t": "cam", "i": 0}
	chk(J.mueve_almacen(A, "right") and A.i == 1, "derecha %d" % A.i)
	chk(not J.mueve_almacen(A, "down") or A.i == 4, "abajo %d" % A.i)
	# no cabe más de lo que cabe
	J.S.buds = {sid: {"g": 5000.0, "thc": 15.0}}
	QUIERO = ["Todos los cogollos"]
	chk(corre(J._guardar_cam), "guardar bloqueado (lleno)")
	chk(J.cam_g() == J.cam_cap(), "lleno %s de %s" % [J.cam_g(), J.cam_cap()])
	J.S.buds = {}
	J.S.cam.buds = {sid: {"g": 700.0, "thc": 15.0, "dia": J.S.day}}
	# 6 · el curado (sin los tarros de Kiko: los de 10 L ya lo son) y, con sobres, el afinado; los sobres se gastan
	J.S.items.erase("tarros")
	var c0: float = J.calidad(J.S.cam.buds[sid])
	dias(int(D.CURADO.dias))
	var b: Dictionary = J.S.cam.buds[sid]
	chk(float(b.get("cu", 0)) >= 1 and float(b.get("af", 0)) < 1.5 / float(CM.af), "curado (y empieza a afinar) %s" % [b])
	dias(int(CM.af))
	chk(float(b.get("af", 0)) >= 1, "afinado %s" % [b])
	var c1: float = J.calidad(b)
	chk(absf(c1 - (c0 + float(D.CURADO.precio) + float(CM.extra))) < 1e-6, "calidad %s → %s" % [c0, c1])
	var gast: float = 3.0 * (int(D.CURADO.dias) + int(CM.af)) / float(CM.dura)
	chk(absf(float(J.S.cam.sob) - (12.0 - gast)) < 1e-6, "sobres %s (gastados %s)" % [J.S.cam.sob, gast])
	# sin sobres no afina
	J.S.cam.buds[sid2] = {"g": 100.0, "thc": 20.0, "cu": 1.0}
	J.S.cam.sob = 0.0
	dias(3)
	chk(float(J.S.cam.buds[sid2].get("af", 0)) == 0.0, "afina sin sobres")
	# 7 · sacarlo: lo afinado va con el lote, y al juntarlo con otro sin afinar, por gramos
	J.S.buds = {sid: {"g": 700.0, "thc": 15.0}}
	J.mover_lote(J.S.cam.buds, J.S.buds, sid, 700.0)
	chk(absf(float(J.S.buds[sid].get("af", 0)) - .5) < 1e-6 and not J.S.cam.buds.has(sid), "afinado al sacar %s" % [J.S.buds[sid]])
	if dir != "":
		J.S.cam.buds = {sid: {"g": 700.0, "thc": 15.0, "cu": 1.0, "af": 1.0}, sid2 + "*": {"g": 260.0, "thc": 21.0, "cu": .5, "mc": 1.0}, D.DEX[2]: {"g": 90.0, "thc": 18.0}}
		J.S.cam.sob = 9.0
		J.enter_map("camarote", int(CM.desde[0]), int(CM.desde[1]), "up")
		await pinta(dir, "arriba", null)
		await pinta(dir, "vista", {"t": "cam", "i": 1})
		await pinta(dir, "vista-mas", {"t": "cam", "i": 0})
	# 8 · bajar por la trampilla
	J.enter_map("camarote", int(CM.desde[0]), int(CM.desde[1]), "up")
	chk(corre(func(): await J.warp(J.MAPS.camarote.exits["4,5"])), "bajar bloqueado")
	chk(J.S.map == "home" and int(J.P.x) == int(CM.vuelta[0]) and int(J.P.y) == int(CM.vuelta[1]), "abajo en %s (%d, %d)" % [J.S.map, J.P.x, J.P.y])
	# 9 · la redada se lo lleva (el camarote no está escondido, la caja sí)
	J.S.protect = false
	J.S.cam.buds = {sid: {"g": 300.0, "thc": 15.0}}
	LOG = []
	chk(corre(J.raid_event), "redada bloqueada")
	chk(J.S.cam.buds.is_empty() and " ".join(LOG).contains("del camarote"), "redada: %s %s" % [J.S.cam.buds, LOG])
	# 10 · guardado y cargado, sigue
	J.S = JSON.parse_string(JSON.stringify(J.S))
	chk(J.cam_ya() and J.cam_est() == 2, "tras cargar %s %d" % [J.cam_ya(), J.cam_est()])
	# 11 · sin Datos.CAL (las pruebas contra el HTML): ni fila, ni escalera
	Datos.CAL = false
	MENUS = []
	QUIERO = []
	chk(corre(J.tienda_online), "tienda bloqueada (sin CAL)")
	chk(MENUS.size() and not MENUS[0].has("El camarote: almacén"), "fila sin CAL: %s" % [MENUS])
	J.MAPS.home.carpasK = ""
	J.montar_casa()
	chk(J.MAPS.home.o[int(CM.y)][int(CM.x)] == null and not J.cam_ya(), "escalera sin CAL")
	Datos.CAL = true
	for x in fallos:
		print("  FALLO ", x)
	print("camarote: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
