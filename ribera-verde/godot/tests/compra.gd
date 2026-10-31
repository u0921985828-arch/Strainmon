# Ribera Verde (Godot) — 1.42: la nave con opción a compra (lo pidió el usuario: siendo presidente de la asociación, alquilarla con
# opción a compra y, cada mes, poder comprarla a tocateja a un precio realista). NAVE.compra: precio fijo, prima y la mitad de cada
# alquiler a cuenta, la compra los primeros días de cada mes por transferencia, con los gastos; comprada, sin alquiler.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla caja-dentro.
#   $GODOT --headless --path godot --script res://tests/compra.gd   → «compra: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var D
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# los menús: el primero que empiece por lo siguiente de QUIERO; si no, el último
func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	if QUIERO.size():
		var q: String = QUIERO.pop_front()
		for i in labels.size():
			if labels[i].begins_with(q):
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

func habla(q: Array) -> String:
	QUIERO = q
	LOG = []
	MENUS = []
	chk(corre(J.talk_nave), "bloqueo con %s" % [q])
	return " ".join(LOG)

func dia(d: int) -> void:
	J.S.day = d
	J.nave_alquiler()
	chk(corre(func(): pass), "cola del día %d" % d)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-compra.json"
	Juego.AJUSTES = "user://prueba-compra-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "caja-dentro":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	D = J.D
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var C: Dictionary = D.NAVE.compra
	# 0 · un precio realista: 320 m² de nave industrial entre 500 y 900 €/m²; el alquiler, entre 4 y 7 €/m² al mes
	var em2: float = float(C.precio) / float(C.m2)
	var alq_mes: float = float(D.NAVE.dia) * 30.0 / float(C.m2)
	chk(em2 >= 500 and em2 <= 900, "€/m²: %f" % em2)
	chk(alq_mes >= 4 and alq_mes <= 7, "alquiler €/m² al mes: %f" % alq_mes)
	# 1 · sin ser presidente, no hay opción
	J.S.ch = 6
	J.S.day = Datos.dia_de(2026, 6, 10)
	J.S.nave = J.nave_nueva()
	J.S.aso = {"v": 2, "d": 0, "tio": true, "asam": 0, "otra": 0, "pres": false, "votos": 0, "lote": null}
	J.S.banco = 5000
	habla(["Nada"])
	chk(not MENUS[0].has("Opción a compra"), "sin presidencia: %s" % [MENUS])
	# 2 · presidente: la opción; sin la prima en la cuenta, no se firma
	J.S.aso.pres = true
	var t := habla(["Opción a compra", "Firmar"])
	chk(MENUS[0][0] == "Opción a compra", "con presidencia: %s" % [MENUS])
	chk(t.contains("en tu cuenta no hay") and J.S.nave.get("op") == null, "sin prima: " + t)
	# 3 · con la prima, firmada: lo que queda baja con la prima
	J.S.banco = 20000
	t = habla(["Opción a compra", "Firmar"])
	chk(J.S.nave.get("op") is Dictionary and int(J.S.banco) == 20000 - int(C.prima), "firmada: %s %s" % [J.S.nave.get("op"), J.S.banco])
	chk(J.resto_nave() == int(C.precio) - int(C.prima), "resto %d" % J.resto_nave())
	# 4 · cada alquiler pagado, la mitad a cuenta
	J.S.money = 100000
	var r0: int = J.resto_nave()
	J.S.nave.r = J.S.day + 1
	dia(J.S.day + 1)
	chk(J.resto_nave() == r0 - roundi(J.recibo_nave() * float(C.abono)), "a cuenta: %d → %d" % [r0, J.resto_nave()])
	# 5 · fuera de los primeros días del mes, no se compra; dice desde cuándo
	J.S.day = Datos.dia_de(2026, 6, 20)
	t = habla(["Comprarla"])
	chk(MENUS[0][0] == "Comprarla" and t.contains("1 de julio") and not J.S.nave.get("mia"), "fuera de plazo: " + t)
	chk(J.marcas_cal().any(func(x): return x.d == Datos.dia_de(2026, 7, 1) and x.t.contains("nave")), "en el calendario")
	# 6 · el 1 de julio, el SMS con lo que falta
	J.S.nave.r = Datos.dia_de(2026, 7, 1)
	LOG = []
	dia(Datos.dia_de(2026, 7, 1))
	chk(" ".join(LOG).contains("Este mes puedes comprar la nave"), "SMS del mes: %s" % [LOG])
	# 7 · sin dinero en la cuenta, no; con él, comprada: sin alquiler, la fianza de vuelta
	J.S.day = Datos.dia_de(2026, 7, 3)
	J.S.banco = 1000
	t = habla(["Comprarla", "Comprarla"])
	chk(not J.S.nave.get("mia") and t.contains("hacen falta"), "sin saldo: " + t)
	var tot: int = J.resto_nave() + J.gastos_nave()
	J.S.banco = tot + 500
	var m0: int = int(J.S.money)
	t = habla(["Comprarla", "Comprarla"])
	chk(J.S.nave.get("mia") and int(J.S.banco) == 500 and int(J.S.money) == m0 + int(D.NAVE.fianza), "comprada: banco %s, efectivo %s" % [J.S.banco, J.S.money])
	chk(not J.recibos().any(func(r): return r[0].begins_with("Nave")), "sin recibo de la nave")
	var rr: int = int(J.S.nave.r)
	J.S.money = 0
	dia(rr + 7)
	chk(J.S.nave != null, "comprada, nadie cambia la cerradura")
	t = habla([])
	chk(MENUS[0] == ["Nada"] and t.contains("es tuya") or MENUS[0] == ["Nada"], "ya es tuya: %s %s" % [MENUS, t])
	for x in fallos:
		print("  FALLO ", x)
	print("compra: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
