# Ribera Verde (Godot) — el rastro de la chatarrería (lo pidió el usuario tras probarlo: «lo que se te queda obsoleto, que lo
# puedas vender»; con Datos.CAL): Bixente compra los focos, macetas y accesorios de sobra de la mochila a RASTRO.compra (la
# mitad), sin tope y preguntando antes; lo vendido, vendido (no hay puesto ni se recompra); lo montado en las carpas no se vende;
# sin CAL, como antes.
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
	# 2 · venderle el foco viejo: pregunta antes y lo paga a RASTRO.compra (la mitad) de su precio
	S.items.f_led100 = 1
	S.items.f_cfl = 1
	S.items.m_plastico7 = 2
	chk(is_equal_approx(float(R.compra), 0.5) and not R.has("max") and not R.has("dias"), "a la mitad, sin tope ni días")
	var din := float(S.money)
	MENUS.clear()
	QUIERO = ["Venderle", "Foco LED 100 W", "Vender", "Nada"]
	chk(corre(func(): await J.talk_bixente()), "venta del foco")
	var p_led := Datos.jsround(110 * float(R.compra))
	chk(float(S.money) == din + p_led and int(S.items.f_led100) == 0, "pagado a %d €" % p_led)
	chk(MENUS.size() >= 3 and MENUS[2] == ["Vender", "No"], "¿seguro? %s" % [MENUS.slice(2, 3)])
	chk(not S.has("rastro"), "sin puesto: lo vendido, vendido")
	chk(MENUS[1].any(func(l): return String(l).begins_with("Foco CFL")), "lo de serie también se vende")
	# si dices que no, no se vende
	din = float(S.money)
	QUIERO = ["Venderle", "Foco CFL", "No", "Nada"]
	chk(corre(func(): await J.talk_bixente()), "no vender el CFL")
	chk(float(S.money) == din and int(S.items.f_cfl) == 1, "dicho que no, sigue en la mochila")
	# lo de serie, a su precio de RASTRO.base
	QUIERO = ["Venderle", "Foco CFL", "Vender", "Nada"]
	chk(corre(func(): await J.talk_bixente()), "venta del CFL")
	chk(float(S.money) == din + Datos.jsround(float(R.base.cfl) * float(R.compra)) and int(S.items.f_cfl) == 0, "el CFL a su precio")
	# 3 · comprar: solo la chatarra del día (no sale a cuenta: vender no paga más que comprar)
	chk(float(R.compra) <= float(D.CHATARRA.f), "no hay trampa de comprar y vender")
	MENUS.clear()
	QUIERO = ["Comprar", "Nada"]
	chk(corre(func(): await J.talk_bixente()), "a comprar")
	chk(MENUS.size() >= 2 and MENUS[1].size() <= int(D.CHATARRA.n) + J.armas_venta().size() + 1, "en venta, solo lo del día %s" % [MENUS.slice(1, 2)])
	# 4 · sin tope: le vendes todo lo que te sobre
	S.items.m_plastico7 = 15
	din = float(S.money)
	QUIERO = ["Venderle"]
	for i in 15:
		QUIERO.append_array(["Maceta", "Vender"])
	QUIERO.append("Nada")
	chk(corre(func(): await J.talk_bixente()), "venta de macetas")
	chk(int(S.items.m_plastico7) == 0 and float(S.money) == din + 15 * J.rastro_compra(J.rastro_pieza("m_plastico7")), "las 15, sin tope")
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
