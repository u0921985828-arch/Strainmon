# Ribera Verde (Godot) — 1.53: abrir con llave, candado, teclado o rueda (lo pidió el usuario: «simulando teclear una clave o meter una
# llave, como animación»). Con CAL: qué se anima en cada sitio (gancho_acceso), los dibujos de cada tipo por momentos (rects_acceso:
# dentro de la pantalla, la llave que entra, las cifras que se teclean, el piloto verde o rojo) y que A lo pasa.
#   $GODOT --headless --path godot --script res://tests/acceso.gd   → «acceso: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también acceso-<tipo>-<ms>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var n := 0
var fallos := []
var VIO := []

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
	var k := labels.size() - 1
	for i in labels.size():
		if labels[i] in ["Mirar detrás", "1998", "Salir"]:
			k = i
			break
	if not labels.has("1998") and not labels.has("Mirar detrás") and not labels.has("Salir"):
		M.timeout(func(): J.press("B"), 5)
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
			return false
	return true

func entra(mapa: String, x: int, y: int) -> void:
	J.enter_map(mapa, x, y, "up")
	J.build_ents()
	J.mode = "world"

func tipos() -> Array:
	return VIO.map(func(v): return v[0])

func dentro(R: Array) -> bool:
	return R.all(func(e): return e[0] >= 0 and e[1] >= 0 and e[0] + e[2] <= J.SW and e[1] + e[3] <= J.SH)

func tiene(R: Array, col: String) -> bool:
	return R.any(func(e): return e[4] == col)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-acceso.json"
	Juego.AJUSTES = "user://prueba-acceso-ajustes.json"
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
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	J.gancho_acceso = func(k, c, ok): VIO.append([k, c, ok])
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
	# 1 · dónde: el portal del piso (llave), la nave (candado y alarma), el cajero (tarjeta y PIN), la caja de la tía (la rueda)
	entra("town", 5, 9)
	J.P.x = 5
	J.P.y = 8
	VIO.clear()
	chk(corre(func(): J.on_step_end()) and S.map == "home" and tipos() == ["llave"], "el portal del piso: %s %s" % [S.map, VIO])
	entra("valdehierro", 12, 8)
	J.P.x = 12
	J.P.y = 7
	VIO.clear()
	chk(corre(func(): await J.entra_local(J.MAPS.valdehierro.doors["12,7"])) and S.map == "nave" and tipos() == ["candado", "clave"], "la nave: %s %s" % [S.map, VIO])
	chk(VIO.size() == 2 and str(VIO[1][1]).length() == 4 and VIO[1][1] == J.cifras_acceso("nave"), "la alarma, 4 cifras siempre iguales")
	VIO.clear()
	chk(corre(func(): await J.cajero()) and tipos() == ["pin"], "el cajero: %s" % [VIO])
	entra("home", 5, 5)
	var caja = S.get("caja")
	S.caja = null
	VIO.clear()
	chk(corre(func(): await J.diploma_action()) and VIO.size() and VIO[0] == ["rueda", "1998", true], "la caja de la tía, con 1998: %s" % [VIO])
	S.caja = caja if caja else {"money": 0, "buds": {}, "nivel": 1}
	VIO.clear()
	chk(corre(func(): await J.caja_action()) and VIO.size() and VIO[0][0] == ("rueda" if int(S.caja.nivel) == 1 else "clave"), "abrir la caja: %s" % [VIO])
	# 2 · sin CAL, nada
	Datos.CAL = false
	VIO.clear()
	await J.acceso("llave")
	chk(VIO.is_empty() and J.ACCESO_V == null, "sin CAL no se anima")
	Datos.CAL = true
	# 3 · los dibujos por momentos
	var V := {"k": "llave", "c": "", "ok": true, "t0": 0.0}
	var r0: Array = J.rects_acceso(V, 0)
	var r1: Array = J.rects_acceso(V, 500)
	chk(dentro(r0) and dentro(r1), "la llave, dentro de la pantalla")
	chk(r0 != r1, "la llave se mueve")
	chk(tiene(J.rects_acceso(V, 800), "#f8e070") and not tiene(J.rects_acceso(V, 200), "#f8e070"), "el clic al girar")
	V = {"k": "clave", "c": "4271", "ok": true, "t0": 0.0}
	var T: Dictionary = J.tiempos_acceso(V)
	chk(dentro(J.rects_acceso(V, 0)), "el teclado, dentro")
	var ast := func(t): return J.rects_acceso(V, t).filter(func(q): return q[4] == "#80f080").size()
	chk(ast.call(0) == 0 and ast.call(T.t1 + 10) > 0 and ast.call(T.t1 + 10) < ast.call(T.t1 + 3 * J.ACC_TECLA + 10), "los asteriscos salen de uno en uno")
	chk(tiene(J.rects_acceso(V, T.t1 + 20), "#58d080"), "la tecla pulsada, en verde")
	chk(tiene(J.rects_acceso(V, T.clic - 10), "#c03030") and tiene(J.rects_acceso(V, T.clic + 10), "#40e060"), "el piloto: rojo y, al final, verde")
	V.ok = false
	chk(not tiene(J.rects_acceso(V, T.clic + 10), "#40e060"), "con la clave mala, no se pone verde")
	V = {"k": "pin", "c": "0815", "ok": true, "t0": 0.0}
	chk(dentro(J.rects_acceso(V, 0)) and tiene(J.rects_acceso(V, 0), "#3070c0"), "la tarjeta del cajero")
	V = {"k": "rueda", "c": "1998", "ok": true, "t0": 0.0}
	T = J.tiempos_acceso(V)
	chk(dentro(J.rects_acceso(V, 0)) and tiene(J.rects_acceso(V, T.fin), "#40e060"), "la rueda: dentro y abre")
	V = {"k": "candado", "c": "", "ok": true, "t0": 0.0}
	chk(dentro(J.rects_acceso(V, 0)) and J.rects_acceso(V, 0) != J.rects_acceso(V, 1000), "el candado: dentro y se abre")
	# 4 · de verdad (sin gancho): A lo pasa y se cierra
	J.gancho_acceso = Callable()
	var t0: float = M.reloj
	chk(corre(func(): await J.acceso("clave", "1234")) and J.ACCESO_V == null, "A lo pasa")
	chk(M.reloj - t0 < 1000, "sin esperar al final (%d ms)" % int(M.reloj - t0))
	if dir != "":
		for k in ["llave", "candado", "clave", "pin", "rueda"]:
			var W := {"k": k, "c": "1998" if k == "rueda" else "4271", "ok": true, "t0": 0.0}
			var TT: Dictionary = J.tiempos_acceso(W)
			for ms in [0.0, (TT.get("entra", TT.get("t1", TT.get("para", 0.0))) as float) + 80, float(TT.fin)]:
				J.ACCESO_V = W.duplicate()
				J.ACCESO_V.t0 = M.reloj - ms
				for q in 2:
					await process_frame
					J.pintor.redibuja(M.reloj)
					for r in 4:
						await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(dir.path_join("acceso-%s-%04d.png" % [k, int(ms)]))
		J.ACCESO_V = null
	print("acceso: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)
