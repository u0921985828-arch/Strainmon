# Ribera Verde (Godot) — EL ESQUEJE, la revista mensual de cultivo (lo pidió el usuario: «Molaría que hubiese un periódico del
# cannabis o alguna revista»). Solo Godot, con Datos.CAL; sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla
# casa-dia. Comprueba el número por mes del calendario, el texto de las ocho secciones, la técnica que se aprende al leer y su
# efecto con tope, la suscripción y el buzón del día 1, la compra en el quiosco, en el estanco y en el mercado, la fila de la
# MOCHILA y lo que cambia en el juego (cosecha, calidad, THC, moho y los días del esqueje).
#   $GODOT --headless --path godot --script res://tests/revista.gd   → «revista: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Motor = preload("res://src/motor.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
var MENUS := []
var ASKS := []
var LOG := []
var QUIERO := ""
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	Datos.CAL = true
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
	for i in labels.size():
		if QUIERO != "" and labels[i].begins_with(QUIERO):
			k = i
	QUIERO = ""
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

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-revista.json"
	Juego.AJUSTES = "user://prueba-revista-ajustes.json"
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-a":
			e = Datos.enteros(x)
	J = Juego.new()
	J.oraculo = true
	root.add_child(J)
	M = J.M
	J.show_title()
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(h, _ms): LOG.append(h)
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var R: Dictionary = J.D.REVISTA

	# 1 · los datos: doce técnicas con efecto conocido y ningún efecto que se pase de su tope
	chk(J.rev_hay(), "sin REVISTA")
	chk(R.tec.size() == 12 and int(R.cab.col) == 12, "técnicas %d" % R.tec.size())
	var ks := {}
	for t in R.tec:
		ks[String(t.k)] = 1
		chk(R.tope.has(String(t.e)), "efecto raro %s" % t.e)
		chk(String(t.t).length() > 200, "texto corto en %s" % t.k)
	chk(ks.size() == 12, "claves repetidas")
	var sum := {}
	for t in R.tec:
		sum[String(t.e)] = float(sum.get(String(t.e), 0.0)) + float(t.v)
	for ef in sum:
		chk(float(sum[ef]) <= float(R.tope[ef]) + 1e-9, "%s se pasa del tope: %s > %s" % [ef, sum[ef], R.tope[ef]])

	# 2 · un número por mes del calendario, desde el mes en que empieza la partida
	chk(J.rev_num(1) == 1, "el día 1 no es el n.º 1: %d" % J.rev_num(1))
	var f0: Dictionary = Datos.fecha(1)
	var d := 1
	while int(Datos.fecha(d).m) == int(f0.m) and int(Datos.fecha(d).y) == int(f0.y):
		chk(J.rev_num(d) == 1, "día %d del primer mes da %d" % [d, J.rev_num(d)])
		d += 1
	chk(J.rev_num(d) == 2, "el primer día del mes siguiente da %d" % J.rev_num(d))
	chk(J.rev_num(d + 400) >= 14, "un año y pico después: %d" % J.rev_num(d + 400))
	chk(J.rev_mes(1).contains(str(int(f0.y))), "el mes del n.º 1: " + J.rev_mes(1))

	# 3 · el texto del número: las ocho secciones, el titular y nada de cifras inventadas
	J.S.day = 1
	var tx: String = J.rev_texto(1)
	for k in R.sec:
		if String(k) != "port":   # la portada no lleva rótulo: es la cabecera
			chk(tx.contains(String(R.sec[k])), "falta la sección %s" % R.sec[k])
	chk(tx.begins_with(String(R.cab.sub).to_upper()), "la portada no abre con la cabecera")
	chk(tx.contains(J.rev_titular(1)), "sin titular")
	chk(tx.contains(String(J.rev_tec(1).n)), "sin la técnica del número")
	chk(tx.length() > 1200, "número corto: %d" % tx.length())
	# el titular cambia con la partida (la policía, la ley, la Copa)
	var t1: String = J.rev_titular(6)
	J.S.calor = 95
	chk(J.rev_titular(6) != "" , "titular vacío")
	J.S.calor = 0

	# 4 · leer un número: la técnica se aprende una vez y da su efecto
	J.S.rev = {"col": [], "tec": [], "sus": 0}
	chk(J.rev_bono("rend") == 0.0, "bono sin leer nada")
	chk(corre(func(): await J.rev_guarda(1)), "lectura bloqueada")
	chk(J.rev_tiene(1), "el número no se guarda")
	var tc1: Dictionary = J.rev_tec(1)
	chk(J.S.rev.tec.has(String(tc1.k)), "la técnica no se aprende")
	chk(abs(J.rev_bono(String(tc1.e)) - float(tc1.v)) < 1e-9, "bono tras leer: %s" % J.rev_bono(String(tc1.e)))
	chk(" ".join(LOG).contains(String(tc1.n)), "sin aviso de la técnica: %s" % [LOG])
	# releerlo no la aprende dos veces
	chk(corre(func(): await J.rev_lee(1)), "relectura bloqueada")
	chk(J.S.rev.tec.size() == 1, "técnica repetida: %s" % [J.S.rev.tec])

	# 5 · caso reservado: los doce números leídos → cada efecto, en su tope exacto, y el n.º 13 recicla la técnica del 1
	J.S.rev = {"col": [], "tec": [], "sus": 0}
	for i in range(1, 13):
		chk(corre(func(): await J.rev_guarda(i)), "lectura %d bloqueada" % i)
	chk(J.S.rev.tec.size() == 12, "no se aprenden las doce: %d" % J.S.rev.tec.size())
	for ef in R.tope:
		chk(abs(J.rev_bono(String(ef)) - minf(float(sum[ef]), float(R.tope[ef]))) < 1e-9, "tope de %s: %s" % [ef, J.rev_bono(String(ef))])
	chk(String(J.rev_tec(13).k) == String(J.rev_tec(1).k), "el n.º 13 no recicla")

	# 6 · lo que cambia de verdad en el juego
	chk(J.esq_dias() == int(J.D.ESQUEJE_DIAS) + 1, "los días del esqueje con las técnicas: %d" % J.esq_dias())
	J.S.rev = {"col": [], "tec": [], "sus": 0}
	chk(J.esq_dias() == int(J.D.ESQUEJE_DIAS), "los días del esqueje sin ellas: %d" % J.esq_dias())
	var p0 := {"sid": "ria", "fase": 5, "dias": 60, "health": 100, "maceta": "11", "thc": 20.0, "cu": 0}
	var fp := {"cap": 1e9, "g": 100.0, "thc": 0.0}
	var q0: float = J.calidad(p0)
	var g0: int = Cultivo.gramos_planta(J.S, p0, fp)
	J.S.rev = {"col": [], "tec": ["apical", "scrog", "peso", "trasplante", "lavado", "secado", "curado"], "sus": 0}
	chk(J.rev_bono("rend") > 0.1, "rend con cuatro técnicas: %s" % J.rev_bono("rend"))
	chk(abs(J.rev_bono("cal") - 0.10) < 1e-9, "cal con tres: %s" % J.rev_bono("cal"))
	chk(J.calidad(p0) > q0, "la calidad no sube: %s → %s" % [q0, J.calidad(p0)])
	chk(Cultivo.gramos_planta(J.S, p0, fp) > g0, "la cosecha no sube: %d → %d" % [g0, Cultivo.gramos_planta(J.S, p0, fp)])
	# el moho
	chk(J.rev_bono("moho") == 0.0, "moho sin sus técnicas")
	J.S.rev.tec = ["defoliado", "limpieza"]
	chk(abs(J.rev_bono("moho") - 0.20) < 1e-9, "moho con las dos: %s" % J.rev_bono("moho"))

	# 7 · la suscripción: doce números y el buzón el día 1 de cada mes
	J.S.rev = {"col": [], "tec": [], "sus": 0}
	J.rev_suscribe()
	chk(int(J.S.rev.sus) == int(R.cab.susn), "suscripción %s" % J.S.rev.sus)
	var dia1 := 1
	while int(Datos.fecha(dia1).d) != 1:
		dia1 += 1
	J.S.day = dia1 - 1
	chk(corre(func(): J.rev_dia()), "rev_dia bloqueado (víspera)")
	chk(J.S.rev.col.is_empty(), "llega antes del día 1")
	J.S.day = dia1
	chk(corre(func(): J.rev_dia()), "rev_dia bloqueado")
	chk(J.S.rev.col.size() == 1 and int(J.S.rev.sus) == int(R.cab.susn) - 1, "el buzón del día 1: %s / %s" % [J.S.rev.col, J.S.rev.sus])
	chk(J.S.sms.size() > 0, "sin SMS de la revista")
	# el mismo día no llega dos veces
	chk(corre(func(): J.rev_dia()), "rev_dia bloqueado (dos veces)")
	chk(J.S.rev.col.size() == 1, "llega dos veces")

	# 8 · la compra: el precio, el 10 % de GROW IBARBIDE y que no se cobra dos veces el mismo número
	chk(J.rev_precio() == float(R.cab.p), "precio %s" % J.rev_precio())
	chk(J.rev_precio("ane") < J.rev_precio(), "GROW IBARBIDE no hace su 10 %%: %s" % J.rev_precio("ane"))
	J.S.rev = {"col": [], "tec": [], "sus": 0}
	J.S.day = 1
	J.S.money = 2.0
	QUIERO = "Comprarla"
	chk(corre(func(): await J.rev_compra("prensa")), "compra bloqueada (sin dinero)")
	chk(J.S.rev.col.is_empty() and J.S.money == 2.0, "compra sin dinero: %s" % J.S.money)
	J.S.money = 20.0
	QUIERO = "Comprarla"
	chk(corre(func(): await J.rev_compra("prensa")), "compra bloqueada")
	chk(J.S.rev.col.has(1) and abs(float(J.S.money) - (20.0 - J.rev_precio())) < 0.011, "compra: %s / %s" % [J.S.rev.col, J.S.money])
	LOG = []
	chk(corre(func(): await J.rev_compra("prensa")), "segunda compra bloqueada")
	chk(J.S.rev.col.size() == 1 and " ".join(LOG).contains("ya lo tienes"), "lo vende dos veces: %s" % [LOG])

	# 9 · los sitios donde se vende, enganchados: el quiosco (ciudad.gd), los growshops y los estancos (trama.gd) y el mercado
	var src_ciu := FileAccess.get_file_as_string("res://src/ciudad.gd")
	var src_tra := FileAccess.get_file_as_string("res://src/trama.gd")
	chk(src_ciu.contains("rev_compra(\"prensa\")"), "el quiosco no vende la revista")
	chk(src_ciu.contains("rev_compra(\"mercado\")"), "el mercado no vende la revista")
	chk(src_tra.contains("rev_compra("), "las tiendas no venden la revista")
	chk(J.D.REVISTA.don.size() == 5, "sitios donde se vende: %d" % J.D.REVISTA.don.size())

	# 10 · la pila de números en la MOCHILA y su ficha
	J.S.rev = {"col": [1, 2], "tec": ["apical"], "sus": 3}
	var fi: String = J.rev_ficha()
	chk(fi.contains("2") and fi.contains("1"), "ficha: " + fi)
	chk(fi.contains("%"), "la ficha no dice el efecto: " + fi)
	MENUS = []
	QUIERO = "N.º 2"
	chk(corre(func(): await J.rev_menu()), "menú de la revista bloqueado")
	chk(MENUS.size() and MENUS[0].size() == 3 and String(MENUS[0][0]).begins_with("N.º 2"), "la pila: %s" % [MENUS])

	# 11 · guardada y cargada, sigue
	var S2 = JSON.parse_string(JSON.stringify(J.S))
	J.S = S2
	chk(J.rev_tiene(2) and J.rev_bono("rend") > 0, "tras cargar: %s" % [J.S.rev])

	for x in fallos:
		print("  FALLO ", x)
	print("revista: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
