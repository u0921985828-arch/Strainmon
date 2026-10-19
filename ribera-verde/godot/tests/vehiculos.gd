# Landrace Hunters (Godot) — MAESTRO [3]: los vehículos se quedan donde los dejas (S.coches[k].pos, S.conduce), no se atraviesan, se
# conducen desde el aparcado, el maletero por kg (MALETERO.kg) con la envasadora al vacío, el control de tráfico con el maletero y la
# grúa al depósito si están mal aparcados; sin Datos.CAL, como antes.
#   $GODOT --headless --path godot --script res://tests/vehiculos.gd   → «vehiculos: N comprobaciones, 0 fallos»
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
	Datos.PLAY = false
	_corre.call_deferred()

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
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s mov %s run %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode, J.P.moving, J.get("corriendo")])
			return false
	return true

const Atlas = preload("res://src/atlas.gd")

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-vehiculos.json"
	Juego.AJUSTES = "user://prueba-vehiculos-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = J.D
	var S = J.S
	S.money = 5000
	S.coches = {"utilitario": {"dia": 0, "p": 20000, "r": S.day + 365, "iv": S.day + 365}, "moto": {"dia": 0, "p": 4000, "r": S.day + 365, "iv": S.day + 365}}
	S.conduce = "utilitario"
	# 1) conduces solo el tuyo; al entrar en un sitio, se queda fuera, donde estabas
	J.enter_map("town", 3, 10, "down")
	J.mode = "world"
	chk(J.vehiculo() == "utilitario", "conduces el utilitario: %s" % J.vehiculo())
	J.enter_map("home", 9, 3, "up")
	var p = S.coches.utilitario.get("pos")
	chk(p is Array and p[0] == "town" and int(p[1]) == 3 and int(p[2]) == 10 and S.get("conduce") == null, "aparcado en la calle al entrar: %s %s" % [p, S.get("conduce")])
	chk(S.coches.moto.get("pos") == null, "la moto no se mueve")
	# 2) en la calle: está donde lo dejaste, no se pasa por encima y vas a pie
	J.enter_map("town", 3, 11, "up")
	chk(J.coche_en(3, 10) == "utilitario" and J.coche_en(3, 11) == "", "coche_en: %s" % J.coche_en(3, 10))
	chk(J.vehiculo() == null, "a pie: %s" % J.vehiculo())
	J.P.dir = "up"
	J.try_move("up")
	chk(J.P.y == 11 and not J.P.moving, "el coche aparcado no se atraviesa: %d" % J.P.y)
	# 3) A delante: conducir
	QUIERO = ["Conducir"]
	chk(corre(func(): await J.coche_menu("utilitario")), "coche_menu")
	chk(S.get("conduce") == "utilitario" and S.coches.utilitario.get("pos") == null and J.P.x == 3 and J.P.y == 10, "al volante desde el aparcado: %s (%d, %d)" % [S.get("conduce"), J.P.x, J.P.y])
	# 4) el maletero: capacidad en kg por vehículo, guardar y sacar
	chk(J.mal_kg("utilitario") == 150000.0 and J.mal_kg("moto") == 40000.0 and J.mal_kg("deportivo") == 30000.0, "MALETERO.kg")
	J.add_buds("ria", 100, 18.0)
	var b0: float = J.total_buds()
	chk(corre(func(): await J.guardar_mal("utilitario")), "guardar en el maletero")
	chk(absf(J.mal_g("utilitario") - b0) < 0.01 and J.total_buds() < 1, "guardado %.1f de %.1f" % [J.mal_g("utilitario"), b0])
	J.mal("moto").buds = {}
	J.add_buds("ria", 60, 18.0)
	J.S.coches.moto.mal.buds["x"] = {"g": 39990.0, "thc": 18.0}
	chk(corre(func(): await J.guardar_mal("moto")), "guardar en la moto llena")
	chk(J.mal_g("moto") <= 40000.0 and J.total_buds() >= 1, "no pasa de 40 kg: %.1f" % J.mal_g("moto"))
	J.S.coches.moto.mal.buds = {}
	J.S.buds = {}
	# 5) al vacío: sin envasadora no; con ella, todo
	S.items.erase("vacio")
	chk(corre(func(): await J.envasar("utilitario")) and not J.mal_vacio("utilitario"), "sin envasadora, nada")
	S.items.vacio = 1
	chk(corre(func(): await J.envasar("utilitario")) and J.mal_vacio("utilitario"), "envasado al vacío")
	# 6) el control: con el maletero; al vacío, la probabilidad × vacio.f
	var ctl: float = D.CONCE.control
	var vf: float = D.MALETERO.vacio.f
	D.CONCE.control = 1.0
	S.heat = 100
	D.MALETERO.vacio.f = 0.0
	chk(corre(func(): await J.control_trafico("utilitario")) and J.mal_g("utilitario") >= 100, "al vacío (f = 0), no lo notan: %.1f" % J.mal_g("utilitario"))
	D.MALETERO.vacio.f = 1.0
	chk(corre(func(): await J.control_trafico("utilitario")) and J.mal_g("utilitario") < 1, "registro: el maletero, requisado")
	chk(LOG.any(func(t): return "maletero" in String(t)), "lo dice el agente")
	D.CONCE.control = ctl
	D.MALETERO.vacio.f = vf
	# 7) la grúa: en la acera, al depósito; en la calzada, no; la moto, nunca
	J.aparcar("utilitario", "town", 11, 0, "down")
	J.aparcar("moto", "town", 12, 0, "down")
	chk(J.mal_aparcado("utilitario") and not J.mal_aparcado("moto"), "mal aparcado en la acera; la moto, no")
	chk(corre(func(): J.conce_dia()), "conce_dia")
	chk(S.coches.utilitario.get("dep") != null and S.coches.utilitario.get("pos") == null and J.coche_en(11, 0) == "", "al depósito")
	chk(S.coches.moto.get("pos") is Array and J.coche_en(12, 0) == "moto", "la moto sigue")
	var m0: float = S.money
	S.conduce = null
	chk(corre(func(): await J.recoger_deposito("utilitario")), "recoger del depósito")
	chk(S.coches.utilitario.get("dep") == null and S.money == m0 - float(D.MALETERO.tasa) and S.conduce == "utilitario", "recogido por %s" % Datos.eur(D.MALETERO.tasa))
	J.aparcar("utilitario", "town", 3, 10, "down")
	chk(not J.mal_aparcado("utilitario"), "en la calzada, bien")
	# 8) la envasadora, en la tienda online
	S.items.erase("vacio")
	S.banco = 1000
	QUIERO = ["Envasadora al vacío", "Salir"]
	chk(corre(func(): await J.tienda_online()), "tienda online")
	chk(S.items.get("vacio") and absf(float(S.banco) - (1000 - float(D.MALETERO.vacio.p))) < 0.01, "envasadora comprada: banco %s" % S.banco)
	# 9) sin CAL, como antes: el mejor que tengas y nada se aparca
	Datos.CAL = false
	S.coches.utilitario.erase("pos")
	S.coches.moto.erase("pos")
	S.conduce = null
	J.enter_map("town", 3, 10, "down")
	chk(J.vehiculo() == "utilitario", "sin CAL, el mejor: %s" % J.vehiculo())
	J.enter_map("home", 9, 3, "up")
	chk(S.coches.utilitario.get("pos") == null and J.coche_en(3, 10) == "", "sin CAL, nada aparcado")
	Datos.CAL = true
	print("vehiculos: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("FALLO ", f)
	quit()
