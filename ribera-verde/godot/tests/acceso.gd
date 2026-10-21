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
	if typeof(e[0]) == TYPE_STRING:   # 1.54.1: un sprite ['@', n, x, y, recorte] (o una imagen: el antebrazo, la planta)
		return (e[1] is Image or Atlas.foto_misc(e[1]) != null) and Rect2i(0, 0, J.SW, J.SH).encloses(e[4])
	return e[0] >= 0 and e[1] >= 0 and e[0] + e[2] <= J.SW and e[1] + e[3] <= J.SH

func tiene(R: Array, col: String) -> bool:
	return R.any(func(e): return typeof(e[0]) != TYPE_STRING and e[4] == col)

# 0.55: la mano de PixelLab (un sprite que empieza por pre) llega al canto del panel: "der" o "aba"; nunca flota
# el antebrazo (lo pidió el usuario: «hasta el final y completarlo con un giro circular… como un cilindro… que no tenga esos picos en la
# manga»): del ancho del puño todo el largo, con la raya negra a los dos lados y la media luna negra en la punta, nada después, sin
# semitransparencias y sin restos de la manga de PixelLab fuera del cilindro
func brazo_cilindro(im: Image, g: Dictionary) -> bool:
	var c: Vector2 = g.c
	var ax: Vector2 = g.ax
	var pe := Vector2(-ax.y, ax.x)
	var r: float = g.r
	var L: float = g.l
	var px := func(p: Vector2) -> Color:
		var q := Vector2i(floori(p.x), floori(p.y))
		if q.x < 0 or q.y < 0 or q.x >= im.get_width() or q.y >= im.get_height():
			return Color(0, 0, 0, 0)
		return im.get_pixel(q.x, q.y)
	for y in im.get_height():
		for x in im.get_width():
			var a: float = im.get_pixel(x, y).a
			if a > 0.0 and a < 1.0:
				return false
			var d := Vector2(x + 0.5, y + 0.5) - c
			if a > 0.5 and g.tela.has(im.get_pixel(x, y).to_rgba32()) and d.dot(ax) > 1.0 and absf(d.dot(pe)) > r + 0.5:
				return false   # un pico de la manga vieja
	# de dentro afuera por cada lado y por la punta: lo último pintado es la raya negra y luego, nada
	var borde := func(m: Vector2, dir: Vector2, desde: float, hasta: float) -> bool:
		var ultimo := Vector2(-1, -1)
		var k: float = desde
		while k <= hasta:
			if px.call(m + dir * k).a > 0.5:
				ultimo = (m + dir * k).floor()
			k += 0.25
		if ultimo.x < 0 or px.call(m + dir * (hasta + 0.75)).a > 0.5:
			return false
		for e in [Vector2.ZERO, Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:   # la raya, en ese píxel o al lado (en diagonal va en escalera)
			var q: Color = px.call(ultimo + e + Vector2(0.5, 0.5))
			if q.a > 0.5 and q.get_luminance() < 0.2:
				return true
		return false
	for t in range(int(r) + 2, int(L - r)):   # desde donde ya no está la mano
		var m := c + ax * (t + 0.5)
		for lado in [-1.0, 1.0]:
			if not borde.call(m, pe * lado, r - 2.0, r + 1.0):
				return false
	return borde.call(c, ax, L - 2.0, L + 1.0)

func nombre_e(e: Array) -> String:
	if typeof(e[0]) != TYPE_STRING:
		return ""
	return String(e[1]) if typeof(e[1]) == TYPE_STRING else (String(e[5]) if e.size() > 5 else "")

func mano_canto(R: Array, pre: String, canto: String, x1: int, y1: int) -> bool:
	for e in R:
		if typeof(e[0]) == TYPE_STRING and e[1] is Image and e.size() > 6 and String(e[5]).begins_with(pre):
			return brazo_cilindro(e[1], e[6])
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
			# 0.56, en primera persona: lo pintado de la mano (con la manga alargada) toca el canto de abajo o el derecho (pov), el de abajo
			# (pov-ab, la del mechero) o el de arriba o el izquierdo (pov-i, la del cliente)
			var r: Rect2i = Rect2i(int(e[2]), int(e[3]), f.c.get_width(), f.c.get_height()).intersection(e[4])
			if canto == "pov" and (r.end.y >= y1 or r.end.x >= x1):
				return true
			if canto == "pov-ab" and r.end.y >= y1:
				return true
			if canto == "pov-i" and (r.position.y <= y1 or r.position.x <= x1):
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
	chk(J.rects_acceso(V, 300).any(func(e): return typeof(e[0]) == TYPE_STRING and typeof(e[1]) == TYPE_STRING and e[1] == "acc-llave-0") and J.rects_acceso(V, 900).any(func(e): return typeof(e[0]) == TYPE_STRING and typeof(e[1]) == TYPE_STRING and e[1] == "acc-llave-1"), "la llave gira: la muñeca de canto")
	V = {"k": "regar", "c": "", "ok": true, "t0": 0.0, "pl": {}}
	var rg: Array = J.rects_acceso(V, 600)
	var gx: int = (J.SW - J.GS_W) >> 1
	var gy: int = (J.SH - J.GS_H) >> 1
	chk(mano_canto(rg, "gm-regar", "pov", gx + J.GS_W, gy + J.GS_H), "regar: el brazo entra desde la esquina de abajo (en primera persona)")
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
			["polen", "gm-pincel", 600.0], ["vender", "gm-bolsita", 500.0], ["pagar", "gm-billete", 400.0], ["pagar", "gm-vacia", 1100.0]]:
		var W := {"k": q[0], "c": "", "ok": true, "t0": 0.0, "pl": {}}
		chk(mano_canto(J.rects_acceso(W, q[2]), q[1], "pov", gx + J.GS_W, gy + J.GS_H), "%s: la mano (%s) entra desde la esquina de abajo" % [q[0], q[1]])
	chk(mano_canto(J.rects_acceso({"k": "vender", "c": "", "ok": true, "t0": 0.0, "pl": {}}, 500.0), "gm-billete-i", "pov-i", gx, gy), "vender: la mano del cliente entra desde la esquina de arriba")
	for m in ["porro", "pipa", "vapo"]:
		chk(mano_canto(J.rects_acceso({"k": "fumar", "c": m, "ok": true, "t0": 0.0, "pl": {}}, 700.0), "gm-" + m, "pov", gx + J.GS_W, gy + J.GS_H), "fumar %s: la mano entra desde la esquina de abajo" % m)
	for m in ["porro", "pipa", "bong"]:   # el mechero, en la otra mano, desde abajo; encendido en el centro
		var W := {"k": "fumar", "c": m, "ok": true, "t0": 0.0, "pl": {}}
		var bien := true
		for ms in [80.0, 300.0, 600.0]:
			bien = bien and mano_canto(J.rects_acceso(W, ms), "gm-mech", "pov-ab", 0, gy + J.GS_H)
		chk(bien and J.rects_acceso(W, 300.0).any(func(e): return nombre_e(e) == "gm-mech1-ab") and not J.rects_acceso(W, 300.0).any(func(e): return typeof(e[0]) == TYPE_STRING and typeof(e[1]) == TYPE_STRING and String(e[1]).begins_with("gs-mechero")), "fumar %s: el mechero en la mano, desde el canto de abajo" % m)
	var pg := {"k": "pagar", "c": "", "ok": true, "t0": 0.0, "pl": {}}
	var al_fajo := false
	var con_billete := false
	for ms in range(150, 1000, 10):
		for q in J.rects_acceso(pg, float(ms)):
			if nombre_e(q) != "" and q[2] - gx <= 24:
				al_fajo = al_fajo or nombre_e(q) == "gm-vacia"
				con_billete = con_billete or nombre_e(q) == "gm-billete"
	chk(al_fajo and con_billete, "pagar: la mano va al fajo y coge el billete")
	var con_t: Array = J.rects_acceso({"k": "fumar", "c": "porro", "ok": true, "t0": 0.0, "pl": {}, "tab": true}, 800.0)
	var sin_t: Array = J.rects_acceso({"k": "fumar", "c": "porro", "ok": true, "t0": 0.0, "pl": {}, "tab": false}, 800.0)
	chk(con_t != sin_t and tiene(con_t, "#8a5a2a") and not tiene(con_t, "#5a8a3a") and tiene(sin_t, "#5a8a3a") and tiene(con_t, "#9a9a9a") and tiene(sin_t, "#f4f4f0"), "el porro con tabaco y solo hierba se distinguen (hebras y humo)")
	# y el cuerpo del porro (lo pidió el usuario: «el peta sin tabaco va a ser verde; en el peta con tabaco se verá que es marrón y verde
	# detrás del papel»)
	var imp := func(R: Array) -> Image:
		for q in R:
			if nombre_e(q) == "gm-porro":
				return q[1]
		return null
	var ps: Image = imp.call(sin_t)
	var pc: Image = imp.call(con_t)
	var cs := [0, 0]   # lo que cambia entre los dos (el cuerpo): verdes y marrones
	var cc := [0, 0]
	if ps != null and pc != null and ps.get_size() == pc.get_size():
		for y in ps.get_height():
			for x in ps.get_width():
				if ps.get_pixel(x, y) == pc.get_pixel(x, y):
					continue
				for par in [[ps.get_pixel(x, y), cs], [pc.get_pixel(x, y), cc]]:
					var c: Color = par[0]
					if c.a > 0.5 and c.g > c.r + 0.08 and c.g > c.b + 0.08:
						par[1][0] += 1
					elif c.a > 0.5 and c.r > c.g + 0.08 and c.g > c.b + 0.08:
						par[1][1] += 1
	chk(cs[0] >= 20 and cs[1] == 0 and cc[1] >= 10 and cc[0] >= 3, "el porro: verde sin tabaco %s, marrón y verde con tabaco %s" % [cs, cc])
	# el pulgar en el mechero encendido (lo pidió el usuario: «a la hora de encender el mechero, desaparece el dedo gordo»): la yema
	# encima de la cabeza de metal, y la llama sin tapar
	var mf = Atlas.foto_misc("gm-mech1-ab")
	var pulgar := 0   # piel en las 4 filas de encima de la cabeza de metal, sobre su canto izquierdo (la rueda)
	var llama := 0
	if mf != null:
		var mi: Image = mf.c
		var hx := 999
		var hy := 999
		for y in mi.get_height():
			for x in mi.get_width():
				var c := mi.get_pixel(x, y)
				llama += 1 if c.a > 0.5 and c.r > 0.8 and c.b < 0.4 and c.g < 0.9 else 0
				if c.a > 0.5 and absf(c.r - c.g) < 0.06 and absf(c.g - c.b) < 0.1 and c.r > 0.45 and c.r < 0.75:
					hx = mini(hx, x)
					hy = mini(hy, y)
		for y in range(maxi(0, hy - 4), hy):
			for x in range(maxi(0, hx - 1), mini(mi.get_width(), hx + 3)):
				var q := mi.get_pixel(x, y)
				pulgar += 1 if q.a > 0.5 and q.r > 0.8 and q.g > 0.55 and q.g < 0.82 and q.b > 0.38 and q.b < 0.72 else 0
	chk(pulgar >= 4 and llama >= 6, "el mechero encendido: el pulgar sobre la rueda (%d px) y la llama (%d px)" % [pulgar, llama])
	chk(not J.rects_acceso({"k": "regar", "c": "", "ok": true, "t0": 0.0, "pl": {}}, 600.0).any(func(e): return typeof(e[0]) == TYPE_STRING and typeof(e[1]) == TYPE_STRING and (String(e[1]).begins_with("gs-regadera") or e[1] == "gs-regar")), "la regadera vieja (y la de perfil) ya no sale")
	# la maceta en dos capas (lo pidió el usuario: «el sprite de la planta se queda detrás del de la maceta»): el canto de atrás y la
	# tierra, la planta (o el brote, o la semilla) y, delante, el canto de delante y el cuerpo; las dos mitades se tocan sin pisarse
	for q in [["regar", 600.0, "gs-planta"], ["tratar", 600.0, "gs-planta"], ["abonar", 600.0, "gs-planta"], ["plantar", 900.0, "gs-brote"],
			["sembrar", 600.0, "gs-semilla"], ["esqueje", 300.0, "gs-planta"], ["cosechar", 700.0, "gs-planta"], ["polen", 600.0, "gs-planta"]]:
		var Rm: Array = J.rects_acceso({"k": q[0], "c": "", "ok": true, "t0": 0.0, "pl": {}}, q[1])
		var im := []
		var ip := -1
		for i in Rm.size():
			var em: Array = Rm[i]
			if typeof(em[0]) == TYPE_STRING and typeof(em[1]) == TYPE_STRING:
				if String(em[1]).begins_with("gs-maceta"):
					im.append(i)
				elif String(em[1]).begins_with(q[2]) and ip < 0:
					ip = i
		var bien: bool = im.size() == 2 and ip > im[0] and ip < im[1]
		if bien:
			var a: Rect2i = Rm[im[0]][4]
			var b: Rect2i = Rm[im[1]][4]
			bien = a.end.y == b.position.y and a.end.y == gy + 60 + J.GS_MAC_CORTE
		chk(bien, "%s: %s entre las dos mitades de la maceta (%s, %d)" % [q[0], q[2], im, ip])
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
		for k in ["llave", "candado", "clave", "pin", "rueda"] + J.GESTOS.keys() + ["fumar:pipa", "fumar:bong", "fumar:vapo", "fumar:porro:tab", "dormir:siesta"]:
			var kk: String = k.split(":")[0]
			var W := {"k": kk, "c": k.split(":")[1] if ":" in k else ("1998" if k == "rueda" else ("" if J.GESTOS.has(k) else "4271")), "ok": true, "t0": 0.0, "tab": k.ends_with(":tab")}
			var TT: Dictionary = J.tiempos_acceso(W)
			for ms in ([0.0, (TT.get("entra", TT.get("t1", TT.get("para", 0.0))) as float) + 80, float(TT.fin)] if not J.GESTOS.has(kk) else [150.0, 400.0, float(TT.fin) * .5, float(TT.fin) * .85]):
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
