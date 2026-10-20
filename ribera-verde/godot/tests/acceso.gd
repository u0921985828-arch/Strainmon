# Ribera Verde (Godot) — 1.53: abrir con llave, candado, teclado o rueda (lo pidió el usuario: «simulando teclear una clave o meter una
# llave, como animación»). Con CAL: qué se anima en cada sitio (gancho_acceso), los dibujos de cada tipo por momentos (rects_acceso:
# dentro de la pantalla, la llave que entra, las cifras que se teclean, el piloto verde o rojo) y que A lo pasa.
#   $GODOT --headless --path godot --script res://tests/acceso.gd   → «acceso: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también acceso-<tipo>-<ms>.png
extends SceneTree
const Atlas = preload("res://src/atlas.gd")

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var n := 0
var fallos := []
var VIO := []

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
	return R.all(func(e): return dentro1(e))

func dentro1(e: Array) -> bool:
	if typeof(e[0]) == TYPE_STRING:   # 1.54.1: un sprite ['@', n, x, y, recorte]
		return Atlas.foto_misc(e[1]) != null and Rect2i(0, 0, J.SW, J.SH).encloses(e[4])
	return e[0] >= 0 and e[1] >= 0 and e[0] + e[2] <= J.SW and e[1] + e[3] <= J.SH

func tiene(R: Array, col: String) -> bool:
	return R.any(func(e): return typeof(e[0]) != TYPE_STRING and e[4] == col)

# 0.55: la mano de PixelLab (un sprite que empieza por pre) llega al canto del panel: "der" o "aba"; nunca flota
func mano_canto(R: Array, pre: String, canto: String, x1: int, y1: int) -> bool:
	for e in R:
		if typeof(e[0]) == TYPE_STRING and typeof(e[1]) == TYPE_STRING and String(e[1]).begins_with(pre):
			var f = Atlas.foto_misc(e[1])
			if f == null:
				return false
			if canto == "der" and int(e[2]) + f.c.get_width() >= x1:
				return true
			if canto == "aba" and int(e[3]) + f.c.get_height() >= y1:
				return true
			if canto == "izq" and int(e[2]) <= x1:
				return true
	return false

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
	var ast := func(t): return J.rects_acceso(V, t).filter(func(q): return typeof(q[0]) != TYPE_STRING and q[4] == "#80f080").size()
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
	# 3a · 0.55 (lo pidió el usuario: «la regadera y la mano flotan… la llave… hacerlas con sprites de PixelLab»): la mano entra por
	# el canto del panel en todos los momentos, y el agua de la regadera cae dentro de la maceta
	var ax1: int = ((J.SW - J.ACC_W) >> 1) + J.ACC_W
	var ay1: int = ((J.SH - J.ACC_H) >> 1) + J.ACC_H
	for q in [["llave", "acc-llave-", "der"], ["candado", "acc-llave-v", "aba"], ["clave", "acc-dedo", "aba"], ["pin", "acc-dedo", "aba"], ["rueda", "acc-dedo", "aba"]]:
		V = {"k": q[0], "c": "" if q[0] in ["llave", "candado"] else "4271", "ok": true, "t0": 0.0}
		T = J.tiempos_acceso(V)
		var bien := true
		for ms in [0.0, T.fin * 0.3, T.fin * 0.6, T.fin - 1]:
			bien = bien and mano_canto(J.rects_acceso(V, ms), q[1], q[2], ax1, ay1)
		chk(bien, "%s: la mano entra por el canto (%s)" % [q[0], q[2]])
	V = {"k": "llave", "c": "", "ok": true, "t0": 0.0}
	chk(J.rects_acceso(V, 300).any(func(e): return typeof(e[0]) == TYPE_STRING and e[1] == "acc-llave-0") and J.rects_acceso(V, 900).any(func(e): return typeof(e[0]) == TYPE_STRING and e[1] == "acc-llave-1"), "la llave gira: la muñeca de canto")
	V = {"k": "regar", "c": "", "ok": true, "t0": 0.0, "pl": {}}
	var rg: Array = J.rects_acceso(V, 600)
	var gx: int = (J.SW - J.GS_W) >> 1
	var gy: int = (J.SH - J.GS_H) >> 1
	chk(mano_canto(rg, "gs-regar", "der", gx + J.GS_W, 0), "regar: el brazo entra por el canto derecho")
	var gotas: Array = rg.filter(func(e): return typeof(e[0]) != TYPE_STRING and (e[4] == "#8ac8f8" or e[4] == "#5aa0e0"))
	var abajo: int = 0
	var en_maceta := gotas.size() > 0
	for g in gotas:
		abajo = maxi(abajo, g[1] + g[3] - gy)
		en_maceta = en_maceta and g[0] - gx >= 44 and g[0] - gx <= 68
	chk(en_maceta and abajo >= 60 and abajo <= 67, "regar: el agua cae en la tierra de la maceta (%d)" % abajo)
	# 0.55: las manos de PixelLab de cada gesto llegan al canto (la tuya por la derecha; la del cliente, por la izquierda)
	for q in [["tratar", "gm-spray", 600.0], ["abonar", "gm-abono", 600.0], ["plantar", "gm-vacia", 900.0], ["sembrar", "gm-semilla", 300.0],
			["sembrar", "gm-vacia", 1000.0], ["esqueje", "gm-tij", 300.0], ["cosechar", "gm-tij", 700.0], ["manicurar", "gm-tij", 600.0],
			["polen", "gm-pincel", 600.0], ["vender", "gm-bolsita", 500.0], ["pagar", "gm-billete", 400.0], ["pagar", "gm-vacia", 1250.0]]:
		var W := {"k": q[0], "c": "", "ok": true, "t0": 0.0, "pl": {}}
		chk(mano_canto(J.rects_acceso(W, q[2]), q[1], "der", gx + J.GS_W, 0), "%s: la mano (%s) entra por el canto derecho" % [q[0], q[1]])
	chk(mano_canto(J.rects_acceso({"k": "vender", "c": "", "ok": true, "t0": 0.0, "pl": {}}, 500.0), "gm-billete-i", "izq", gx, 0), "vender: la mano del cliente entra por el canto izquierdo")
	for m in ["porro", "pipa", "vapo"]:
		chk(mano_canto(J.rects_acceso({"k": "fumar", "c": m, "ok": true, "t0": 0.0, "pl": {}}, 700.0), "gm-" + m, "der", gx + J.GS_W, 0), "fumar %s: la mano entra por el canto derecho" % m)
	var con_t: Array = J.rects_acceso({"k": "fumar", "c": "porro", "ok": true, "t0": 0.0, "pl": {}, "tab": true}, 800.0)
	var sin_t: Array = J.rects_acceso({"k": "fumar", "c": "porro", "ok": true, "t0": 0.0, "pl": {}, "tab": false}, 800.0)
	chk(con_t != sin_t and tiene(con_t, "#8a5a2a") and not tiene(con_t, "#5a8a3a") and tiene(sin_t, "#5a8a3a") and tiene(con_t, "#9a9a9a") and tiene(sin_t, "#f4f4f0"), "el porro con tabaco y solo hierba se distinguen (hebras y humo)")
	chk(not J.rects_acceso({"k": "regar", "c": "", "ok": true, "t0": 0.0, "pl": {}}, 600.0).any(func(e): return typeof(e[0]) == TYPE_STRING and typeof(e[1]) == TYPE_STRING and String(e[1]).begins_with("gs-regadera")), "la regadera vieja ya no sale")
	# 3b · 1.54: cada acción de cerca. accion() lleva su gesto; catar, el porro; todos los dibujos, dentro y en movimiento
	VIO.clear()
	for q in [["regar", "regar"], ["plantar", "plantar"], ["cosechar", "cosechar"], ["cruzar", "polen"], ["vender", "vender"]]:
		VIO.clear()
		chk(corre(func(): await J.accion(q[0])) and tipos() == [q[1]], "accion(%s) → %s: %s" % [q[0], q[1], VIO])
	var lk = S.buds.keys()[0] if S.buds.size() else null
	if lk != null and float(S.buds[lk].g) >= 1:
		VIO.clear()
		chk(corre(func(): await J.catar(lk, 0.5)) and VIO.size() and VIO[0] == ["fumar", "porro", true], "catar → el porro: %s" % [VIO])
	for gk in J.GESTOS:
		for m in (["porro", "pipa", "bong", "vapo"] if gk == "fumar" else (["", "siesta"] if gk == "dormir" else [""])):
			var W := {"k": gk, "c": m, "ok": true, "t0": 0.0}
			var fin: float = J.tiempos_acceso(W).fin
			var a0: Array = J.rects_acceso(W, 0)
			var a1: Array = J.rects_acceso(W, fin * .4)
			var a2: Array = J.rects_acceso(W, fin)
			chk(dentro(a0) and dentro(a1) and dentro(a2), "%s %s: dentro de la pantalla" % [gk, m])
			chk(a0 != a1 and a1 != a2, "%s %s: se mueve" % [gk, m])
	# 4 · de verdad (sin gancho): A lo pasa y se cierra
	J.gancho_acceso = Callable()
	var t0: float = M.reloj
	chk(corre(func(): await J.acceso("clave", "1234")) and J.ACCESO_V == null, "A lo pasa")
	chk(M.reloj - t0 < 1000, "sin esperar al final (%d ms)" % int(M.reloj - t0))
	if dir != "":
		for k in ["llave", "candado", "clave", "pin", "rueda"] + J.GESTOS.keys() + ["fumar:pipa", "fumar:bong", "fumar:vapo", "dormir:siesta"]:
			var kk: String = k.split(":")[0]
			var W := {"k": kk, "c": k.split(":")[1] if ":" in k else ("1998" if k == "rueda" else ("" if J.GESTOS.has(k) else "4271")), "ok": true, "t0": 0.0}
			var TT: Dictionary = J.tiempos_acceso(W)
			for ms in ([0.0, (TT.get("entra", TT.get("t1", TT.get("para", 0.0))) as float) + 80, float(TT.fin)] if not J.GESTOS.has(kk) else [150.0, float(TT.fin) * .5, float(TT.fin) * .85]):
				J.ACCESO_V = W.duplicate()
				J.ACCESO_V.t0 = M.reloj - ms
				for q in 2:
					await process_frame
					J.pintor.redibuja(M.reloj)
					for r in 4:
						await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(dir.path_join("acceso-%s-%04d.png" % [k.replace(":", "-"), int(ms)]))
		J.ACCESO_V = null
	print("acceso: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)
