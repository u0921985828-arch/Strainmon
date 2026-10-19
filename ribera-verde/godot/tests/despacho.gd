# Ribera Verde (Godot) — MAESTRO [8]: el curado en la nave (estanterías de tarros de 10 L, el doble con la ampliación), el
# despacho de lujo (tarima, paredes, alfombra, muebles, monitores de las cámaras de los locales y la caja fuerte grande) y los
# retratos de las charlas (en vivo, llamadas y SMS) con su expresión por el tono; sin Datos.CAL, nada de esto.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla nave2 (la nave equipada a tope).
#   $GODOT --headless --path godot --script res://tests/despacho.gd   → «despacho: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también despacho-<caso>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Motor = preload("res://src/motor.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var ALMQ := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
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

func pinta(dir: String, k: String) -> void:
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	var im: Image = root.get_texture().get_image()
	im.save_png(dir.path_join("despacho-%s.png" % k))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-despacho.json"
	Juego.AJUSTES = "user://prueba-despacho-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	var dir := arg("--pintar")
	J.S = e.S
	J.S.erase("desp")
	J.S.nave.erase("cur")
	J.enter_map("nave", 9, 4, "up")
	J.mode = "world"
	var D = J.D
	var CU: Dictionary = D.CURADO_NAVE
	var DS: Dictionary = D.DESPACHO
	var CM: Dictionary = D.CAMAROTE
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	J.gancho_almacen = func(_t): return ALMQ.pop_front() if ALMQ.size() else null
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var Mo: Array = J.MAPS.nave.o
	# 1 · el curado de serie: CURADO_NAVE.est estanterías de tarros de 10 L en la nave
	var ns := 0
	for q in CU.sitio:
		if Mo[int(q[1])][int(q[0])] == "estanteC":
			ns += 1
	chk(ns == int(CU.est), "estanterías de serie %d" % ns)
	chk(J.navc_est() == int(CU.est) and J.navc_cap() == float(CU.est) * float(CM.est.tarros) * float(CM.tarro), "cap %s" % J.navc_cap())
	# guardar y la vista de los tarros
	var sid: String = D.DEX[0]
	J.S.buds = {sid: {"g": 900.0, "thc": 15.0, "dia": J.S.day}}
	QUIERO = ["Todos los cogollos"]
	chk(corre(func(): await J._guardar_cam("navc")), "guardar bloqueado")
	chk(J.navc_g() == 900.0 and J.total_buds() == 0.0, "guardado %s" % J.navc_g())
	var its: Array = J.items_almacen("navc")
	chk(its.size() >= 2 and its[0].k == "+", "tarros %d" % its.size())
	var R: Array = J.rects_almacen({"t": "navc", "i": 1})
	var spr := R.filter(func(r): return r[0] is String).map(func(r): return r[1])
	chk("alm-tarro-xl" in spr or "alm-tarro-xl-s" in spr, "vista: %s" % [spr])
	chk(J.desc_almacen({"t": "navc", "i": 0}).contains("estanterías de la nave"), "desc " + J.desc_almacen({"t": "navc", "i": 0}))
	# lleno: no cabe más de lo que cabe
	J.S.buds = {sid: {"g": 9000.0, "thc": 15.0}}
	QUIERO = ["Todos los cogollos"]
	chk(corre(func(): await J._guardar_cam("navc")), "guardar bloqueado (lleno)")
	chk(J.navc_g() == J.navc_cap(), "lleno %s de %s" % [J.navc_g(), J.navc_cap()])
	# el curado al pasar los días (sin los tarros de Kiko)
	J.S.items.erase("tarros")
	J.S.nave.cur.buds = {sid: {"g": 500.0, "thc": 15.0, "dia": J.S.day}}
	var av := []
	for q in int(D.CURADO.dias):
		J.S.day += 1
		av = []
		J.curado_dia(av)
	chk(float(J.S.nave.cur.buds[sid].get("cu", 0)) >= 1, "curado %s" % [J.S.nave.cur.buds[sid]])
	# 2 · la ampliación (CURADO_NAVE.p): el doble de estanterías y de tarros
	J.S.money = 100000
	MENUS = []
	QUIERO = ["Curado", "Comprar"]
	chk(corre(J.mejoras_nave), "mejoras bloqueado (curado)")
	chk(int(J.navc().mj) == 1 and J.S.money == 100000 - int(CU.p), "ampliación %s %s" % [J.navc(), J.S.money])
	chk(J.navc_est() == 2 * int(CU.est), "estanterías %d" % J.navc_est())
	ns = 0
	Mo = J.MAPS.nave.o
	for q in CU.sitio:
		if Mo[int(q[1])][int(q[0])] == "estanteC":
			ns += 1
	chk(ns == 2 * int(CU.est), "estanterías en el mapa %d" % ns)
	chk(MENUS.size() and MENUS[0].any(func(l): return l.begins_with("Despacho de lujo")), "fila del despacho con la nave a tope: %s" % [MENUS])
	# A en una estantería abre los tarros (sin bloquear)
	var est: Array = []
	for q in CU.sitio:
		if Mo[int(q[1])][int(q[0])] == "estanteC" and est.is_empty():
			est = q
	J.S.buds = {}
	var g0: float = J.navc_g()
	ALMQ = [1]
	chk(corre(func(): await J.obj_local(int(est[0]), int(est[1]), "estanteC")), "estantería bloqueada")
	chk(J.total_buds() >= 1 and J.navc_g() < g0, "sacar de los tarros: fuera %s dentro %s" % [J.total_buds(), J.navc_g()])
	# 3 · el despacho de lujo: sin la nave a tope no se ofrece
	J.S.nave.ex = 0
	MENUS = []
	chk(corre(J.mejoras_nave), "mejoras bloqueado (sin tope)")
	chk(MENUS.size() and not MENUS[0].any(func(l): return l.begins_with("Despacho de lujo")), "despacho sin tope: %s" % [MENUS])
	J.S.nave.ex = D.EXTR_NAVE.size() - 1
	J.S.money = 100
	QUIERO = ["Despacho de lujo", "Comprar"]
	chk(corre(J.mejoras_nave), "mejoras bloqueado (sin dinero)")
	chk(not J.desp_ya(), "despacho sin dinero")
	J.S.money = 100000
	QUIERO = ["Despacho de lujo", "Comprar"]
	chk(corre(J.mejoras_nave), "mejoras bloqueado (despacho)")
	chk(J.desp_ya() and J.S.money == 100000 - int(DS.p), "despacho %s %s" % [J.desp(), J.S.money])
	# el mapa del despacho: suelo, paredes, alfombra y muebles
	J.enter_map("nave-d", 3, 3, "up")
	var md = J.MAPS["nave-d"]
	chk(md.g[3][5] == DS.suelo and String(md.g[0][3]).ends_with("-" + str(int(DS.pared))), "suelo/pared %s %s" % [md.g[3][5], md.g[0][3]])
	chk(String(md.g[int(DS.alf[1])][int(DS.alf[0])]).begins_with(String(DS.alf[2]) + "a"), "alfombra %s" % md.g[int(DS.alf[1])][int(DS.alf[0])])
	for q in DS.o:
		chk(md.o[int(q[1])][int(q[0])] == q[2], "mueble %s en (%d, %d): %s" % [q[2], q[0], q[1], md.o[int(q[1])][int(q[0])]])
		var s0: String = String(q[2])
		if not s0.ends_with("2"):
			chk(J.Atlas.cubre("obj:" + s0) != null, "sin sprite obj:" + s0)
	# se llega a la caja y a los monitores
	chk(not J.tile_solid(md, 5, 2) and not J.tile_solid(md, 7, 3), "delante de los monitores y de la caja, libre")
	# 4 · los monitores: las cámaras de los locales (sin bloquear)
	MENUS = []
	chk(corre(func(): await J.obj_local(5, 1, "monD")), "monitores bloqueado")
	chk(MENUS.size() or LOG.any(func(t): return t.contains("monitores")), "monitores: %s" % [MENUS])
	# 5 · la caja fuerte grande: guardar dinero y cogollos, sacar
	J.S.money = 60000
	J.S.buds = {sid: {"g": 300.0, "thc": 15.0}}
	QUIERO = ["Guardar dinero", "50.000", "Guardar cogollos", lot_n(sid), "Nada"]
	chk(corre(J.caja_desp), "caja bloqueada (guardar)")
	chk(int(J.S.desp.money) == 50000 and J.S.money == 10000, "dinero en la caja %s fuera %s" % [J.S.desp.money, J.S.money])
	chk(float(J.S.desp.buds.get(sid, {"g": 0}).g) == 300.0 and J.total_buds() == 0.0, "cogollos en la caja %s" % [J.S.desp.buds])
	# 6 · la redada de la nave no la encuentra
	var dm: int = int(J.S.desp.money)
	J.S.desp = JSON.parse_string(JSON.stringify(J.S.desp))
	chk(int(J.S.desp.money) == dm, "tras cargar")
	QUIERO = ["Sacar dinero", "1.000", "Nada"]
	chk(corre(J.caja_desp), "caja bloqueada (sacar)")
	chk(int(J.S.desp.money) == dm - 1000 and J.S.money == 11000, "sacar %s %s" % [J.S.desp.money, J.S.money])
	if dir != "":
		J.set_process(false)
		J.enter_map("nave-d", 3, 3, "up")
		await pinta(dir, "lujo")
		J.enter_map("nave", int(est[0]), int(est[1]) + 1, "up")
		await pinta(dir, "estanterias")
	# 7 · sin Datos.CAL: ni estanterías, ni despacho, ni filas
	Datos.CAL = false
	J.enter_map("nave", 9, 4, "up")
	ns = 0
	for q in CU.sitio:
		if J.MAPS.nave.o[int(q[1])][int(q[0])] == "estanteC":
			ns += 1
	chk(ns == 0, "estanterías sin CAL %d" % ns)
	J.enter_map("nave-d", 3, 3, "up")
	chk(J.MAPS["nave-d"].g[3][5] == "floorN" and J.MAPS["nave-d"].o[1][5] == "cuadro", "despacho sin CAL %s %s" % [J.MAPS["nave-d"].g[3][5], J.MAPS["nave-d"].o[1][5]])
	MENUS = []
	QUIERO = []
	chk(corre(J.mejoras_nave), "mejoras sin CAL")
	chk(MENUS.size() and MENUS[0].size() == 3, "filas sin CAL: %s" % [MENUS])
	Datos.CAL = true
	# 8 · dejar la nave: la caja del despacho se vacía antes
	J.enter_map("nave", 9, 4, "up")
	var m0: int = J.S.money
	var cd: int = int(J.S.desp.money)
	QUIERO = ["Dejar la nave", "Dejarla"]
	chk(corre(J.talk_nave), "dejar bloqueado")
	chk(J.S.nave == null and not J.S.has("desp") and J.S.money == m0 + cd + int(D.NAVE.fianza) and float(J.S.buds.get(sid, {"g": 0}).g) == 300.0, "al dejarla %s %s %s" % [J.S.money, J.S.get("desp"), J.S.buds])
	# 9 · los retratos: quién habla (en vivo, llamadas y SMS) y su gesto por el tono
	const Retrato = preload("res://src/retrato.gd")
	var rk = J.retrato_de("KIKO")
	chk(rk is Array and rk[0] == D.LOOKS.kiko and not rk[1], "retrato de Kiko %s" % [rk])
	var rs = J.retrato_de("SMS · BEGOÑA")
	chk(rs is Array and rs[0] == D.LOOKS.begona and rs[1], "retrato de Begoña (SMS) %s" % [rs])
	var rb = J.retrato_de("SMS · DON BALTASAR")
	chk(rb is Array and rb[0] == D.LOOKS.baltasar, "retrato de don Baltasar")
	chk(J.retrato_de("SMS · ARRIETA") is Array and J.retrato_de("IÑAKI")[0] == D.LOOKS.sailor, "Arrieta e Iñaki")
	chk(J.retrato_de("CARTA") == null and J.retrato_de("SMS · BANCO") == null and J.retrato_de("SMS · AUTOBUSES DE LA COMARCA") == null, "sin retrato lo que no es una persona")
	var rkol = J.retrato_de("SMS · KOLDO")
	chk(rkol is Array and rkol[0] == J.retrato_de("SMS · KOLDO")[0], "Koldo, siempre el mismo")
	J.habla_look = Datos.rand_look("prueba", "client")
	chk(J.retrato_de("FUMETA")[0] == J.habla_look, "en vivo, el de la persona")
	J.habla_look = null
	chk(Retrato.expresion("¡Gracias, majo! Trato hecho.") == Retrato.ALEGRE, "alegre")
	chk(Retrato.expresion("Me debes 3.000 €. Último aviso.") == Retrato.ENFADO, "enfadado")
	chk(Retrato.expresion("¿Seguro que quieres eso?") == Retrato.DUDA, "duda")
	chk(Retrato.expresion("Hoy hace sol en el puerto.") == Retrato.NEUTRO, "neutro")
	chk(Retrato.expresion("Thanks, mate! Deal.") == Retrato.ALEGRE and Retrato.expresion("You owe me. Last chance.") == Retrato.ENFADO, "en inglés")
	var i0: Image = Retrato.imagen(D.LOOKS.kiko, false, 0)
	var i1: Image = Retrato.imagen(D.LOOKS.kiko, false, 2)
	var i2: Image = Retrato.imagen(D.LOOKS.miren, true, 0)
	chk(i0.get_size() == Vector2i(32, 32) and i0.get_data() != i1.get_data() and i0.get_data() != i2.get_data(), "gesto e identidad cambian el retrato")
	chk(Retrato.textura(D.LOOKS.kiko, false, 1) == Retrato.textura(D.LOOKS.kiko, false, 1), "en caché")
	# en pantalla (fuera del oráculo): el PortraitRect, dentro de la caja y a la izquierda
	J.oraculo = false
	J.gancho_texto = Callable()
	chk(corre(func(): await J.type_text("¡Gracias, majo! Trato hecho.", "KIKO")), "type_text bloqueado")
	chk(J.retrato.visible and J.retrato.name == "PortraitRect" and J.retrato.texture != null, "retrato a la vista")
	if dir != "":
		J.enter_map("shop", 4, 4, "up")
		await pinta(dir, "retrato-kiko")
	chk(corre(func(): await J.type_text("Me debes 3.000 €. Último aviso.", "SMS · TOÑO")), "type_text bloqueado (SMS)")
	chk(J.retrato.visible, "retrato en el SMS")
	if dir != "":
		await pinta(dir, "retrato-sms")
	chk(corre(func(): await J.type_text("Hay una carta en la mesa.", "CARTA")), "type_text bloqueado (carta)")
	chk(not J.retrato.visible, "sin retrato en la carta")
	Datos.CAL = false
	chk(corre(func(): await J.type_text("Hola.", "KIKO")), "type_text bloqueado (sin CAL)")
	chk(not J.retrato.visible, "sin retrato sin CAL")
	Datos.CAL = true
	J.dlg.hide()
	J.oraculo = true
	for x in fallos:
		print("  FALLO ", x)
	print("despacho: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)

func lot_n(k: String) -> String:
	return J.lot_nombre(k)
