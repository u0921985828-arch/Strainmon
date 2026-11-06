# Ribera Verde (Godot) — el bajo de Txomin, profesional (lo pidió el usuario: «el lugar donde está… las setas… debería de ser el
# mismo mapa o algo más grande, el doble de grande molaría, y mejor organizado todo, que sea el bajo de Txomin, donde ahí pues sea
# más profesional el cultivo de setas, que también se pueda cruzar micelios para crear nuevas variedades de setas»): el mapa de 22 × 12
# por zonas (tools/bajo_pro.py), las catorce estanterías y las 28 bandejas, la puerta del callejón a su fila, los muebles del obrador y
# del laboratorio con su texto y, en la campana de flujo, el cruce de micelios que da una cepa tuya (CEPAS.cruce, S.setas.mis).
#   $GODOT --headless --path godot --script res://tests/bajo_pro.gd   → «bajo_pro: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
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


func pinta(dir: String, k: String, V: Dictionary) -> void:
	J.SETAS_V = V
	J._dlg_fijo(J.desc_bajo(V), "EL BAJO")
	for q in 2:
		await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("cepas-%s.png" % k))
	J.SETAS_V = null

# los rectángulos de una bandeja lista de la cepa v, a u = 1
func dibuja(v: String) -> Array:
	var o := []
	J._bandeja_seta(o, {"d": J.S.day - 20, "hum": 90, "v": v}, 0, 0, 1, 7)
	return o


func _corre() -> void:
	Juego.GUARDADO = "user://prueba-bajopro.json"
	Juego.AJUSTES = "user://prueba-bajopro-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "setas":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	var D: Dictionary = J.D
	var C: Dictionary = D.CEPAS
	S.ch = maxi(int(S.ch), int(D.SETAS.ch))
	S.setas = {"bandejas": [], "g": 0, "r": S.day + 30}
	S.money = 4000
	S.heat = 0
	J.enter_map("callejon", 17, 9, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("B" if J.SETAS_V != null else "A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · el mapa, el doble y por zonas: 22 × 12, el tabique con su hueco, el suelo técnico del laboratorio y la puerta a su fila
	var m: Dictionary = J.MAPS.setas
	chk(int(m.w) == 22 and int(m.h) == 12 and int(m.w) * int(m.h) >= 2 * 18 * 7, "el bajo, el doble: %d × %d" % [m.w, m.h])
	chk(J.n_baldas() == 14 and J.max_bandejas() == 28, "catorce estanterías, 28 bandejas: %d" % J.n_baldas())
	var pared := 0
	for x in int(m.w):
		if String(m.g[5][x]).begins_with("iwT") and String(m.g[6][x]).begins_with("iwB"):
			pared += 1
	chk(pared == 20 and J.pisable(m, 10, 5) and J.pisable(m, 11, 6), "el tabique de 20 con su hueco: %d" % pared)
	chk(String(m.g[3][18]) == "floorLab" and String(m.g[3][2]) == "floorSe", "el suelo técnico del laboratorio: %s" % m.g[3][18])
	var pc: Dictionary = J.MAPS.callejon.doors["19,7"]
	chk(int(pc.x) == 4 and int(pc.y) == 10, "la puerta del callejón, a la fila de la suya: %d, %d" % [pc.x, pc.y])
	chk(String(m.g[11][4]) == "mat" and m.exits.has("4,11") and m.exits.has("5,11"), "la salida, en su fila")
	# 2 · se anda todo: de la puerta a cada estantería, a la campana y a la mesa de trabajo
	QUIERO = ["El bajo", "Alquilarlo"]
	chk(corre(func(): await J.talk_txomin()) and S.get("setas") is Dictionary, "alquilar el bajo")
	J.enter_map("setas", int(pc.x), int(pc.y), "up")
	J.mode = "world"
	m = J.MAPS.setas
	var falta := []
	for q in [[0, 7], [8, 7], [16, 7], [14, 2], [5, 2], [0, 2], [9, 2], [19, 8]]:
		if not llega("setas", [int(pc.x), int(pc.y)], q):
			falta.append(q)
	chk(falta.is_empty(), "no se llega a: %s" % [falta])
	chk(m.o[2][0] == "armS" and m.o[2][5] == "mesaS" and m.o[2][14] == "labFlujo" and m.o[7][9] == "humidS", "cada cosa en su zona: %s" % [m.o[2]])
	# 3 · los muebles del obrador y del laboratorio, con su texto (ninguno mudo)
	var mudos := []
	for q in [[9, 2], [17, 2], [20, 2], [12, 2], [13, 1], [16, 1], [19, 1], [12, 3], [10, 4]]:
		LOG = []
		if not corre(func(): await J.object_action(q[0], q[1])) or LOG.is_empty() or " ".join(LOG).contains("Nada que"):
			mudos.append([q, LOG])
	chk(mudos.is_empty(), "muebles mudos: %s" % [mudos])
	# 4 · la campana: lo del cuaderno manda a la mesa, lo que se repele no gasta y el resto da una cepa tuya
	var L: Dictionary = S.setas
	L.panes = {"txuria": 1, "urre": 1, "adar": 1, "iluna": 1}
	var p0: Dictionary = L.panes.duplicate()
	LOG = []
	QUIERO = ["Txuria", "Urrezko", "Nada"]
	chk(corre(func(): await J.object_action(14, 2)) and L.panes == p0 and " ".join(LOG).contains("en la mesa"), "lo del cuaderno, a la mesa: %s" % [LOG])
	LOG = []
	QUIERO = ["Adartxo", "Iluna", "Nada"]
	chk(corre(func(): await J.object_action(14, 2)) and L.panes == p0 and " ".join(LOG).contains("se repelen"), "en la campana también se repelen: %s" % [LOG])
	var t0: int = int(S.min) + 1440 * int(S.day)
	LOG = []
	QUIERO = ["Txuria", "Iluna", "Cruzar"]
	chk(corre(func(): await J.object_action(14, 2)), "cruzar bloqueado")
	var mis: Dictionary = J.mis_cepas()
	chk(mis.size() == 1 and int(L.panes.txuria) == 0 and int(L.panes.iluna) == 0, "gasta los dos panes: %s %s" % [mis.size(), L.panes])
	var id: String = mis.keys()[0]
	var cp: Dictionary = mis[id]
	chk(int(L.panes.get(id, 0)) == int(C.cruce.sale) and L.cd.has(id), "los panes de la tuya y el cuaderno: %s" % [L.panes])
	chk(int(S.min) + 1440 * int(S.day) - t0 == int(C.cruce.min), "lo que lleva: %d" % [int(S.min) + 1440 * int(S.day) - t0])
	chk(cp.pa.has("txuria") and cp.pa.has("iluna") and cp.f in ["cupula", "campana"] and int(cp.gen) == int(C.cruce.gen), "de sus dos padres: %s" % [cp])
	chk(String(cp.n).length() <= 20 and String(cp.n) != "" and not C.v.has(id) and J.cepa_hay(id) and J.cepa_v(id).n == cp.n, "nombre propio y clave nueva: %s" % String(cp.n))
	chk(float(cp.g) > 0.5 and float(cp.p) > 0.5 and cp.c.size() == 3 and String(cp.c[0]).begins_with("#"), "sus números y su color: %s %s %s" % [cp.g, cp.p, cp.c])
	chk(J.cepas_ks().size() == C.v.size() + 1, "en el cuaderno con las demás: %d" % J.cepas_ks().size())
	# el mismo par, la misma cepa; y el tope
	LOG = []
	L.panes.txuria = 1
	L.panes.iluna = 1
	L.panes.erase(id)   # la tuya, fuera de la lista: su nombre empieza por el de su madre
	QUIERO = ["Txuria", "Iluna", "Cruzar"]
	chk(corre(func(): await J.object_action(14, 2)) and J.mis_cepas().size() == 1 and " ".join(LOG).contains("Vuelve a prender"), "el mismo par, la misma cepa: %s" % [LOG])
	for i in int(C.cruce.max):
		L.mis["x%d" % i] = {"n": "X%d" % i, "f": "cupula", "gen": 5, "g": 1.0, "p": 1.0, "c": ["#111111", "#222222", "#333333"], "pie": "#eeeeee", "d": "", "pa": ["txuria", "urre"]}
	LOG = []
	L.panes.txuria = 1
	L.panes.urre = 1
	QUIERO = ["Nada"]
	chk(corre(func(): await J.object_action(14, 2)) and " ".join(LOG).contains("De ahí no pasa"), "el tope de cepas propias: %s" % [LOG])
	# 5 · el cuaderno dice de dónde sale la tuya
	for i in int(C.cruce.max):
		L.mis.erase("x%d" % i)
	MENUS = []
	LOG = []
	QUIERO = ["✓ " + String(cp.n), "Nada", "Nada"]
	chk(corre(func(): await J.cuaderno_setas()) and " ".join(LOG).contains("en la campana"), "el cuaderno, con la tuya: %s" % [LOG])
	# 6 · sin Datos.CAL, el bajo de siempre
	Datos.CAL = false
	chk(int(J.MAPS["setas-g"].w) == 22, "el mapa grande sigue en los datos")
	Datos.CAL = true
	for x in fallos:
		print("  FALLO ", x)
	print("bajo_pro: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
