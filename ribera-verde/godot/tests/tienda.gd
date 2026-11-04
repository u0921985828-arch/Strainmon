# Landrace Hunters (Godot) — LA TIENDA de extras y las semillas doradas (lo pidió el usuario: «Quiero que el juego no sea demo
# pero que podamos elegir cosas para que sean como extras o dlc, objetos para comprar y demas / O incluso algún tipo de moneda
# especial»). Solo Godot, con Datos.CAL; sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-dia.
# Comprueba el catálogo (22 cosas, 4 categorías, los paquetes solo con dinero de verdad), lo que se gana jugando con su tope, el
# regalo a quien compró el juego completo, los requisitos de cada extra, lo que deja cada compra en la partida (semillas, items,
# el camarote, el arcón, las reformas, el concesionario, el despacho, la huerta, el banco de la tía y el muelle con KAIA), que lo
# de una sola vez no se compra dos veces y que no se cobra si no hay nada que mandar.
#   $GODOT --headless --path godot --script res://tests/tienda.gd   → «tienda: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Tienda = preload("res://src/tienda.gd")
const Plataforma = preload("res://src/plataforma.gd")
const Motor = preload("res://src/motor.gd")
const I18n = preload("res://src/i18n.gd")

var J
var M
var D
var S0 := {}
var n := 0
var fallos := []
var QUIERO := []
var MENUS := []

func _initialize() -> void:
	Datos.PLAY = false
	Datos.CAL = true
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo: fin %s libre %s pend %s modo %s" % [st.fin, J.is_free(), J.pending.size(), J.mode])
			return false
	return true

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

func estado(k: String) -> Dictionary:
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	for x in O:
		if x.k == k:
			return Datos.enteros(x).S
	return {}

# los logros y las misiones ya dados: así nada de lo que pasa al comprar suma semillas doradas por su cuenta
func reset() -> void:
	J.S = S0.duplicate(true)
	J.S.erase("tn")
	for l in D.LOGROS:
		J.S.logros[String(l.id)] = 1
	J.tn().sd = 10000

func compra(k: String) -> String:
	var x: Dictionary = J.tn_def(k)
	var r := {"t": ""}
	QUIERO = ["Comprar"]
	corre(func(): r.t = await J.tn_aplica(x))
	return String(r.t)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-tienda.json"
	Juego.AJUSTES = "user://prueba-tienda-ajustes.json"
	Datos.CAL = true
	D = Datos.carga()
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	S0 = estado("casa-extr")
	J.S = S0.duplicate(true)
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	reset()

	# 1 · el catálogo
	chk(J.tn_hay(), "la tienda está en los datos")
	var T0: Dictionary = D.TIENDA
	chk(T0.it.size() == 22 and T0.cat.size() == 4, "22 cosas en 4 categorías (%d/%d)" % [T0.it.size(), T0.cat.size()])
	var packs: Array = T0.it.filter(func(x): return String(x.cat) == "sd")
	chk(packs.size() == 4 and packs.all(func(x): return x.has("prod") and float(x.p) > 0 and int(x.sd) == 0), "los 4 paquetes, solo con dinero de verdad")
	chk(T0.it.filter(func(x): return String(x.cat) != "sd").all(func(x): return not x.has("prod") and int(x.sd) > 0 and x.has("ef")), "lo demás, solo con semillas doradas")
	var ks := {}
	for x in T0.it:
		ks[String(x.k)] = 1
	chk(ks.size() == 22, "claves sin repetir (%d)" % ks.size())
	chk(J.tn_txt(1).ends_with(I18n.v(String(T0.mon.n1))) and J.tn_txt(3).ends_with(I18n.v(String(T0.mon.n))), "1 semilla dorada / 3 semillas doradas (%s · %s)" % [J.tn_txt(1), J.tn_txt(3)])

	# 2 · lo que se gana jugando, con su tope
	reset()
	J.tn().sd = 0
	J.tn_gana("cap")
	chk(J.tn_sd() == int(J.tn_gana_def("cap").v), "el capítulo da sus semillas doradas (%d)" % J.tn_sd())
	J.tn_gana("diario", 3)
	chk(J.tn_sd() == 8 + 3, "tres objetivos diarios, tres semillas (%d)" % J.tn_sd())
	J.tn_gana("copa98")
	J.tn_gana("copa98")
	chk(int(J.tn().g.copa98) == 25, "la Copa de la asociación, una sola vez por el tope (%d)" % int(J.tn().g.copa98))
	J.tn_gana("nada_de_esto")
	chk(J.tn_sd() == 8 + 3 + 25, "una vía que no existe no da nada (%d)" % J.tn_sd())

	# 3 · el regalo a quien compró el juego completo cuando era una demo
	reset()
	J.tn().sd = 0
	J.tn().r = 0
	J.aj.completo = false
	J.tn_regalo()
	chk(J.tn_sd() == 0 and int(J.tn().r) == 0, "sin la compra de antes, sin regalo")
	J.aj.completo = true
	J.tn_regalo()
	chk(J.tn_sd() == int(T0.mon.regalo) and int(J.tn().r) == 1, "con la compra de antes, el regalo (%d)" % J.tn_sd())
	J.tn_regalo()
	chk(J.tn_sd() == int(T0.mon.regalo), "el regalo, una sola vez")
	J.aj.completo = false

	# 4 · los requisitos: sin lo que pide, no se compra
	reset()
	for k in ["csobres", "edesp", "ehuerta", "elab", "ekaia"]:
		var x: Dictionary = J.tn_def(k)
		var e: Dictionary = J.tn_estado(x)
		chk(not e.ok and not e.ya and String(e.rz) == I18n.v(String(x.rz)), "%s: todavía no, y dice por qué" % k)
	chk(J.tn_estado(J.tn_def("cabono")).ok, "el abono no pide nada")
	J.tn().sd = 0
	var e0: Dictionary = J.tn_estado(J.tn_def("cabono"))
	chk(not e0.ok and String(e0.rz).contains(J.tn_txt(12)), "sin semillas doradas, dice cuántas faltan (%s)" % e0.rz)

	# 5 · lo que deja cada compra
	reset()
	var it0: int = int(J.S.items.get("fert", 0))
	chk(compra("cabono") != "" and int(J.S.items.fert) == it0 + 100 and int(J.S.items.phm) == int(J.S.items.get("phm", 0)), "abono: 100 dosis de floración")
	reset()
	chk(compra("cmaceta") != "" and int(J.S.items.get("m_tela35", 0)) == 9, "nueve macetas de tela de 35 L")
	reset()
	chk(compra("ctarros") != "" and int(J.S.items.get("tarros", 0)) == 1, "los tarros de curado")
	reset()
	chk(compra("earcon") != "" and int(J.S.nevera.arcon) == 1, "el arcón congelador")
	reset()
	chk(not J.reforma_pagada() and compra("eobra") != "" and J.reforma_pagada(), "las reformas, pagadas")
	reset()
	J.S.flags.erase("conce")
	chk(compra("econce") != "" and J.S.flags.get("conce") != null, "AUTOS RIBERA, abierto")
	reset()
	chk(not J.cam_ya() and compra("ecam") != "" and J.cam_ya() and J.cam_est() == int(D.CAMAROTE.est.max) and int(J.S.cam.sob) == int(D.CAMAROTE.sob.u), "el camarote con sus cuatro estanterías y doce sobres")
	chk(compra("csobres") != "" and int(J.S.cam.sob) == int(D.CAMAROTE.sob.u) + 12, "con el camarote, los sobres sí")
	reset()
	J.S.nave = {"d": 1, "m": [], "w": []}
	chk(J.desp().is_empty() and compra("edesp") != "" and not J.desp().is_empty(), "el despacho de lujo")
	reset()
	J.S.huerta = {"v": 1}
	chk(compra("ehuerta") != "" and int(J.S.huerta.l) <= int(J.S.day) and int(J.S.huerta.m.ibc) == int(J.HUERTA_MEJ.ibc.max), "la huerta ampliada con sus mejoras")
	reset()
	J.S.disc[String(J.HILO.semilla)] = true
	var ll: bool = J.bt_llave()
	var tl: String = compra("elab")
	chk(ll and tl != "" and J.bt().c.size() == D.BANCO_TIA.col.size(), "el banco de la tía, con las seis colecciones (llave %s · «%s» · %d)" % [ll, tl, J.bt().c.size()])
	reset()
	J.S.mar = {"d": 1}
	chk(compra("ekaia") != "" and J.S.mar.ob.size() == D.MAR.obras.size(), "el muelle reformado y KAIA")

	# 6 · las semillas que da la tienda
	reset()
	var s0: int = J.S.seeds.size()
	var t1 := compra("gland")
	var nu: int = J.S.seeds.keys().filter(func(k): return J.S.disc.get(k)).size()
	chk(t1 != "" and J.S.seeds.size() >= s0 + 1 and nu > 0, "tres landraces, con su ficha descubierta (%s)" % t1)
	reset()
	J.S.disc[String(J.HILO.semilla)] = false
	var t2 := compra("ghaze")
	chk(t2 != "" and int(J.S.seeds.get(String(J.HILO.semilla), 0)) >= 5, "cinco Haze del 98 (%s)" % t2)
	reset()
	chk(compra("gauto") != "" and J.tn_faltan("auto").size() < D.AUTO.dex.size(), "cuatro autoflorecientes")
	# con todas descubiertas, no hay nada que mandar y no se cobra
	reset()
	for b in D.BANCO:
		J.S.disc[String(b[0])] = true
	for c in D.CAZA.l:
		J.S.disc[String(c.k)] = true
	chk(J.tn_faltan("land").is_empty(), "sin landraces que falten, la lista vacía")
	var sd0: int = J.tn_sd()
	QUIERO = ["Comprar"]
	corre(func(): await J.tn_compra(J.tn_def("gland")))
	chk(J.tn_sd() == sd0 and J.tn_veces("gland") == 0, "no hay nada que mandar: no se cobra")

	# 7 · lo de una sola vez, una sola vez; y la compra de verdad descuenta
	reset()
	var sd1: int = J.tn_sd()
	QUIERO = ["Comprar"]
	corre(func(): await J.tn_compra(J.tn_def("earcon")))
	chk(J.tn_sd() == sd1 - int(J.tn_def("earcon").sd) and J.tn_veces("earcon") == 1, "el arcón se cobra una vez (%d)" % J.tn_sd())
	var e2: Dictionary = J.tn_estado(J.tn_def("earcon"))
	chk(not e2.ok and e2.ya, "el arcón, ya comprado")
	var sd2: int = J.tn_sd()
	QUIERO = ["Dejarlo"]
	corre(func(): await J.tn_compra(J.tn_def("cabono")))
	chk(J.tn_sd() == sd2, "dejarlo no cobra")

	# 8 · los paquetes de dinero de verdad: solo con la marca «tienda»
	reset()
	Tienda.TIENDA_REAL = false
	var sd3: int = J.tn_sd()
	corre(func(): await J.tn_pack(J.tn_def("sd1")))
	chk(J.tn_sd() == sd3, "sin la marca «tienda», los paquetes no dan nada")
	MENUS.clear()
	QUIERO = ["Volver"]
	corre(func(): await J.tienda_menu())
	chk(MENUS.size() and not MENUS[0].any(func(l): return String(l).begins_with("SEMILLAS DORADAS")), "sin la marca, la categoría de paquetes no sale")
	Tienda.TIENDA_REAL = true
	Datos.PLAY = true
	Plataforma.PRUEBA_COMPRA = "ok"
	QUIERO = ["Comprar"]
	corre(func(): await J.tn_pack(J.tn_def("sd1")))
	chk(J.tn_sd() == sd3 + int(J.tn_def("sd1").da), "el paquete comprado da sus semillas doradas (%d)" % J.tn_sd())
	Plataforma.PRUEBA_COMPRA = "cancelada"
	var sd4: int = J.tn_sd()
	QUIERO = ["Comprar"]
	corre(func(): await J.tn_pack(J.tn_def("sd2")))
	chk(J.tn_sd() == sd4, "compra cancelada: nada")
	MENUS.clear()
	QUIERO = ["Volver"]
	corre(func(): await J.tienda_menu())
	chk(MENUS.size() and MENUS[0].any(func(l): return String(l).begins_with("SEMILLAS DORADAS")), "con la marca, la categoría de paquetes sale")
	Datos.PLAY = false

	# 9 · la pantalla: las cuatro categorías, cómo se ganan y volver
	reset()
	MENUS.clear()
	QUIERO = ["EXTRAS", "Volver", "Volver"]
	corre(func(): await J.tienda_menu())
	chk(MENUS.size() >= 2 and MENUS[1].size() == D.TIENDA.it.filter(func(x): return String(x.cat) == "ext").size() + 1, "EXTRAS: sus cosas y Volver (%d)" % MENUS[1].size())
	chk(J.tn_como().contains(I18n.v(String(T0.mon.pie))), "CÓMO SE GANAN dice que el juego entero viene con la aplicación")

	for f in fallos:
		print("FALLO  " + f)
	print("tienda: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for r in [Juego.GUARDADO, Juego.GUARDADO + ".bak", Juego.AJUSTES]:
		if FileAccess.file_exists(r):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	quit(1 if fallos.size() else 0)
