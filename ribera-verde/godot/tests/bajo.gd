# Ribera Verde (Godot) — 1.44: el bajo de las setas entero (lo pidió el usuario: «los sprites y todo para crear el piso bajo, donde
# se cultivan, se secan, almacenan y se crean microdosis y comestibles»): el armario de almacén, la mesa de trabajo y el
# deshidratador en el mapa (montar_setas), lo recogido a secar (S.setas.fr) y al armario (secar_setas), la encapsuladora y los
# moldes de Txomin, las cajas de la mesa, su venta, el armario por dentro y, sin Datos.CAL, el bajo de antes.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla setas.
#   $GODOT --headless --path godot --script res://tests/bajo.gd   → «bajo: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también bajo-mapa.png y bajo-armario.png
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

func foto(dir: String, k: String) -> void:
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("bajo-%s.png" % k))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-bajo.json"
	Juego.AJUSTES = "user://prueba-bajo-ajustes.json"
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
	var Z: Dictionary = J.D.SETAS_PRO
	var X: Dictionary = Z.x
	var dir := arg("--pintar")
	if dir != "":
		S.setas.merge({"dh": true, "enc": true, "mol": true, "g": 120, "mc": 5, "cc": 3, "fr": [{"g": 30, "d": S.day}]}, true)
		J.enter_map("setas", 5, 4, "up")
		J.mode = "world"
		await process_frame
		J.set_process(false)
		await foto(dir, "mapa")
		await foto(dir, "mapa")
		J.ARM_V = {}
		J._dlg_fijo(J.desc_armario(), "EL ARMARIO")
		await foto(dir, "armario")
		J.ARM_V = null
		J.set_process(true)
		S.setas = e.S.setas.duplicate(true)
		S = J.S
	S.setas = {"bandejas": [{"d": S.day - 20, "hum": 90}, {"d": S.day - 20, "hum": 90}], "g": 0, "r": S.day + 30}
	S.money = 1000
	S.heat = 0
	J.enter_map("setas", 5, 4, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("B" if J.ARM_V != null or J.SETAS_V != null else "A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var m: Dictionary = J.MAPS.setas
	# 1 · el mapa: el armario y la mesa siempre; el deshidratador, cuando es tuyo; se llega a todo andando desde la puerta
	chk(m.o[int(X.armS[1])][int(X.armS[0])] == "armS" and m.o[int(X.mesaS[1])][int(X.mesaS[0])] == "mesaS", "armario y mesa: %s" % [m.o])
	chk(m.o[int(X.deshidS[1])][int(X.deshidS[0])] == null, "sin deshidratador")
	for c in [[0, 2], [1, 2], [2, 2], [4, 2], [6, 2], X.armS, X.mesaS, X.deshidS, [9, 5]]:
		chk(llega("setas", [4, 5], [int(c[0]), int(c[1])]), "se llega a %s" % [c])
	# 2 · recoger: a secar en la malla (SETAS_PRO.seca días); después, al armario
	QUIERO = ["Recoger"]
	chk(corre(func(): await J.bajo_menu("")), "recoger bloqueado")
	var fr: Array = S.setas.get("fr", [])
	chk(fr.size() == 1 and fr[0].g >= 50 and S.setas.g == 0 and LOG.any(func(t): return t.contains("malla del secadero")), "a secar: %s %s" % [fr, LOG])
	var gfr: int = int(fr[0].g) if fr.size() else 0
	chk(J.sprite_local("secaS") == "secaS-1" and J.sprite_local("armS") == "armS-0-0-0", "secadero lleno, armario vacío")
	chk(J.txt_secando("secaS").contains("secándose") and J.txt_secando("secaS").contains("el "), "el secadero: %s" % J.txt_secando("secaS"))
	S.day += int(Z.seca) - 1
	chk(J.secar_setas() == 0 and S.setas.g == 0, "aún no")
	S.day += 1
	chk(J.secar_setas() == gfr and S.setas.g == gfr and S.setas.fr.is_empty(), "seco, al armario: %s" % [S.setas])
	chk(J.sprite_local("secaS") == "secaS-0" and J.sprite_local("armS") == "armS-1-0-0", "armario: %s" % J.sprite_local("armS"))
	# 3 · Txomin: el deshidratador, la encapsuladora y los moldes
	S.ch = maxi(int(S.ch), int(J.D.SETAS.ch))
	for q in ["Deshidratador", "Encapsuladora", "Moldes"]:
		QUIERO = [q]
		var m0: int = S.money
		chk(corre(J.talk_txomin), "Txomin bloqueado")
		var k: String = {"Deshidratador": "deshid", "Encapsuladora": "encap", "Moldes": "moldes"}[q]
		chk(m0 - S.money == int(Z[k]), "%s: %d" % [q, m0 - S.money])
	chk(S.setas.get("dh") and S.setas.get("enc") and S.setas.get("mol"), "el equipo: %s" % [S.setas])
	chk(J.sprite_local("mesaS") == "mesaS-1-1", "la mesa equipada")
	J.enter_map("setas", 5, 4, "up")
	chk(m.o[int(X.deshidS[1])][int(X.deshidS[0])] == "deshidS", "el deshidratador, en el mapa")
	# 4 · con el deshidratador, en un día
	S.setas.fr = [{"g": 40, "d": S.day}]
	chk(J.sprite_local("deshidS") == "deshidS-1" and J.sprite_local("secaS") == "secaS-0", "deshidratador encendido")
	S.day += 1
	var g0: float = S.setas.g
	chk(J.secar_setas() == 40 and S.setas.g == g0 + 40, "en un día")
	# 5 · la mesa: una caja de microdosis y otra de comestibles por lote
	S.setas.g = 25
	QUIERO = ["Microdosis", "Comestibles", "Nada"]
	var m1: int = S.money
	var t1: int = int(S.min) + 1440 * int(S.day)
	chk(corre(J.mesa_setas), "mesa bloqueada")
	chk(S.setas.g == 5 and S.setas.get("mc") == 1 and S.setas.get("cc") == 1 and m1 - S.money == int(Z.choco), "la mesa: %s %d" % [S.setas, m1 - S.money])
	chk(int(S.min) + 1440 * int(S.day) - t1 == int(Z.min.mc) + int(Z.min.cc), "el tiempo de la mesa")
	QUIERO = ["Microdosis", "Nada"]
	LOG = []
	chk(corre(J.mesa_setas), "mesa sin setas bloqueada")
	chk(S.setas.mc == 1 and LOG.any(func(t): return t.contains("Hacen falta")), "sin setas: %s" % [LOG])
	chk(J.sprite_local("armS") == "armS-1-1-1", "armario: %s" % J.sprite_local("armS"))
	# 6 · el armario por dentro
	S.setas.mc = 4
	S.setas.cc = 2
	S.setas.g = 130
	chk(J.desc_armario().contains("microdosis: 4") and J.desc_armario().contains("comestibles: 2"), J.desc_armario())
	var R: Array = J.rects_armario()
	chk(R.filter(func(r): return r[4] == "#2a2a30").size() == 3 and R.filter(func(r): return r[4] == "#4a7ac0").size() == 4 and R.filter(func(r): return r[4] == "#6a3a20").size() == 2, "botes, cajitas y cajas")
	chk(J.sprite_local("armS") == "armS-2-2-1", "armario: %s" % J.sprite_local("armS"))
	chk(corre(func(): await J.obj_local(int(X.armS[0]), int(X.armS[1]), "armS")) and J.ARM_V == null, "el armario se abre y se cierra")
	# 7 · Txomin compra las cajas
	QUIERO = ["Microdosis:", "Comestibles:"]
	var m2: int = S.money
	S.heat = 0
	chk(corre(J.talk_txomin), "venta bloqueada")
	chk(S.money - m2 == 4 * int(Z.p.mc) + 2 * int(Z.p.cc) and S.setas.mc == 0 and S.setas.cc == 0 and S.heat == 6 * Z.calor, "venta: %d %s" % [S.money - m2, S.heat])
	# 8 · sin Datos.CAL: el bajo de antes (sin muebles nuevos, lo recogido directo al secadero)
	Datos.CAL = false
	J.enter_map("setas", 5, 4, "up")
	chk(m.o[int(X.armS[1])][int(X.armS[0])] == null and m.o[int(X.mesaS[1])][int(X.mesaS[0])] == null and m.o[int(X.deshidS[1])][int(X.deshidS[0])] == null, "sin CAL, sin muebles")
	S.setas.bandejas = [{"d": S.day - 20, "hum": 90}]
	S.setas.fr = []
	var g3: float = S.setas.g
	QUIERO = ["Recoger"]
	chk(corre(func(): await J.bajo_menu("")), "recoger sin CAL bloqueado")
	chk(S.setas.g > g3 and S.setas.fr.is_empty(), "sin CAL, directo: %s" % [S.setas])
	MENUS = []
	chk(corre(J.talk_txomin) and not MENUS.is_empty() and not MENUS[-1].any(func(t): return t.begins_with("Deshidratador") or t.begins_with("Moldes")), "Txomin sin CAL: %s" % [MENUS])
	Datos.CAL = true
	J.enter_map("setas", 5, 4, "up")
	for x in fallos:
		print("  FALLO ", x)
	print("bajo: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
