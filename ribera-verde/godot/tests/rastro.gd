# Ribera Verde (Godot) — el rastro de la chatarrería (lo pidió el usuario tras probarlo: «lo que se te queda obsoleto, que lo
# puedas vender»; con Datos.CAL): Bixente compra los focos, macetas y accesorios de sobra de la mochila a RASTRO.compra, los pone
# a la venta a CHATARRA.f, se van a los RASTRO.dias y caben RASTRO.max; lo montado en las carpas no se vende; sin CAL, como antes.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-extr.
#   $GODOT --headless --path godot --script res://tests/rastro.gd   → «rastro: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var S
var D
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
			print("  bloqueo: fin %s libre %s pend %s modo %s" % [st.fin, J.is_free(), J.pending.size(), J.mode])
			return false
	return true

func log_tiene(t: String) -> bool:
	for l in LOG:
		if String(l).contains(t):
			return true
	return false

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-rastro.json"
	Juego.AJUSTES = "user://prueba-rastro-ajustes.json"
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
	S = J.S
	D = J.D
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var R: Dictionary = D.RASTRO
	S.ch = 3
	S.money = 1000.0
	S.erase("rastro")
	for k in S.items.keys():
		if String(k).substr(0, 2) in ["f_", "m_", "x_"]:
			S.items[k] = 0
	# 1 · sin nada de sobra, no hay qué venderle; lo montado en las carpas no cuenta
	var foco0: String = S.carpas[0].foco
	chk(J.rastro_vendible().is_empty(), "lo montado no se vende")
	QUIERO = ["Venderle"]
	LOG.clear()
	chk(corre(func(): await J.talk_bixente()), "bixente sin nada")
	chk(MENUS.size() >= 1 and MENUS[0].has("Comprar") and MENUS[0].has("Venderle"), "compra o venta")
	chk(log_tiene("No te sobra nada"), "nada que venderle")
	chk(S.carpas[0].foco == foco0, "la carpa sigue con su foco")
	# 2 · venderle el foco viejo: RASTRO.compra de su precio, y a su puesto
	S.items.f_led100 = 1
	S.items.f_cfl = 1
	S.items.m_plastico7 = 2
	var din := float(S.money)
	MENUS.clear()
	QUIERO = ["Venderle", "Foco LED 100 W", "Nada"]
	chk(corre(func(): await J.talk_bixente()), "venta del foco")
	var p_led := Datos.jsround(110 * float(R.compra))
	chk(float(S.money) == din + p_led and int(S.items.f_led100) == 0, "pagado a %d €" % p_led)
	chk(S.rastro.size() == 1 and String(S.rastro[0].k) == "f_led100" and int(S.rastro[0].d) == int(S.day), "al puesto")
	chk(MENUS.size() >= 2 and MENUS[1].any(func(l): return String(l).begins_with("Foco CFL")), "lo de serie también se vende")
	# lo de serie, a su precio de RASTRO.base
	din = float(S.money)
	QUIERO = ["Venderle", "Foco CFL", "Nada"]
	chk(corre(func(): await J.talk_bixente()), "venta del CFL")
	chk(float(S.money) == din + Datos.jsround(float(R.base.cfl) * float(R.compra)) and int(S.items.f_cfl) == 0, "el CFL a su precio")
	# 3 · comprarlo de vuelta, a CHATARRA.f (no sale a cuenta: compra < venta)
	chk(float(R.compra) < float(D.CHATARRA.f), "no hay trampa de comprar y vender")
	din = float(S.money)
	MENUS.clear()
	QUIERO = ["Comprar", "Foco LED 100 W", "Luego", "Nada"]
	chk(corre(func(): await J.talk_bixente()), "compra del foco")
	chk(MENUS.size() >= 2 and MENUS[1].has("Foco LED 100 W"), "el foco, en la lista de la chatarrería")
	chk(float(S.money) == din - Datos.jsround(110 * float(D.CHATARRA.f)) and int(S.items.f_led100) == 1, "comprado a mitad de precio")
	chk(S.rastro.size() == 1 and String(S.rastro[0].k) == "f_cfl", "sale del puesto")
	# 4 · lo del puesto se va a los RASTRO.dias y caben RASTRO.max
	S.rastro[0].d = int(S.day) - int(R.dias) - 1
	chk(J.rastro_stock().is_empty(), "se lo lleva otro")
	S.items.m_plastico7 = int(R.max) + 3
	QUIERO = ["Venderle"]
	for i in int(R.max) + 2:
		QUIERO.append("Maceta")
	QUIERO.append("Nada")
	chk(corre(func(): await J.talk_bixente()), "venta de macetas")
	chk(S.rastro.size() == int(R.max) and int(S.items.m_plastico7) == 1, "caben %d" % int(R.max))
	# 5 · la pista al cambiar el foco, una vez
	S.flags.erase("rastroP")
	chk(J.pista_rastro().contains("Bixente") and J.pista_rastro() == "", "la pista, una vez")
	# 6 · sin CAL, como antes: ni pregunta ni puesto
	Datos.CAL = false
	MENUS.clear()
	QUIERO = ["Nada"]
	chk(corre(func(): await J.talk_bixente()), "sin CAL")
	chk(MENUS.size() >= 1 and not MENUS[0].has("Venderle") and not MENUS[0].has("Maceta de plástico 7 L"), "sin CAL, solo la chatarra del día")
	S.flags.erase("rastroP")
	chk(J.pista_rastro() == "", "sin CAL, sin pista")
	Datos.CAL = true
	print("rastro: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
