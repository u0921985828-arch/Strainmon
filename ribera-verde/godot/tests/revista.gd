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
const I18n = preload("res://src/i18n.gd")

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

	# 3b · NOTICIAS DE LA COMARCA: el registro de sucesos, el titular que sale de él y el relleno
	J.S.rev = {"col": [], "tec": [], "sus": 0, "nw": []}
	J.S.day = 1
	J.rev_nota("redada")
	chk(J.S.rev.nw.size() == 1 and String(J.S.rev.nw[0].k) == "redada", "rev_nota no apunta: %s" % [J.S.rev.nw])
	J.rev_nota("redada")
	chk(J.S.rev.nw.size() == 1, "la misma noticia del mismo día, dos veces: %s" % [J.S.rev.nw])
	J.rev_nota("copa", 2)
	J.rev_nota("copa", 5)
	J.rev_nota("copa", 3)
	var wc := {}
	for w in J.S.rev.nw:
		if String(w.k) == "copa":
			wc = w
	chk(int(wc.get("v", 0)) == 5, "la cifra de la Copa no se queda con la mayor: %s" % [wc])
	J.rev_nota("", 0)
	chk(J.S.rev.nw.size() == 2, "una clave vacía entra en el registro: %s" % [J.S.rev.nw])
	var nw1: Array = J.rev_nw_de(1)
	chk(nw1.size() == 2, "las noticias del n.º 1: %d" % nw1.size())
	var pr := true   # por prioridad, de más a menos
	for i in range(1, nw1.size()):
		if int(nw1[i - 1].df.p) < int(nw1[i].df.p):
			pr = false
	chk(pr, "las noticias no van por prioridad: %s" % [nw1.map(func(x): return [x.df.k, x.df.p])])
	var nt: String = J.rev_nw_txt(nw1[0])
	chk(nt.length() > 40 and not nt.contains("{"), "el cuerpo de la noticia: " + nt)
	chk(J.rev_titular(1) == J.T(String(nw1[0].df.ti)) or J.rev_titular(1) == String(nw1[0].df.ti), "el titular no sale de la noticia gorda: %s" % J.rev_titular(1))
	var nx: String = J.rev_noticias(1)
	chk(nx.contains(nt) and nx.count("· ") == nw1.size(), "la sección de noticias: " + nx)
	var tx1: String = J.rev_texto(1)
	chk(tx1.contains(String(R.sec.nw)) and tx1.contains(nt), "el número no trae sus noticias")
	# las del mes anterior rellenan el número siguiente si el mes no trae tres
	var d2 := 1
	while J.rev_num(d2) < 2:
		d2 += 1
	J.S.day = d2
	J.rev_nota("kaia")
	var nw2: Array = J.rev_nw_de(2)
	chk(nw2.size() >= 1 and String(nw2[0].df.k) == "kaia", "el suceso del mes nuevo no abre su número: %s" % [nw2.map(func(x): return x.df.k)])
	chk(nw2.size() == 3, "el n.º 2 no se completa con el mes anterior: %d" % nw2.size())
	# sin sucesos, el relleno deducido del estado: nunca menos de dos líneas
	J.S.rev = {"col": [], "tec": [], "sus": 0, "nw": []}
	J.S.day = 1
	chk(J.rev_nw_de(1).is_empty(), "sucesos sin registro")
	chk(J.rev_relleno(1).size() >= 2, "relleno corto: %d" % J.rev_relleno(1).size())
	var nr: String = J.rev_noticias(1)
	chk(nr.count("· ") >= 2 and not nr.contains("{"), "el relleno del n.º 1: " + nr)
	chk(J.rev_titular(1) != "", "sin titular sin sucesos")
	# el registro tiene tope
	for i in range(0, 80):
		J.S.day = 1 + i
		J.rev_nota("redada")
	chk(J.S.rev.nw.size() == J.NW_TOPE, "el registro no tiene tope: %d" % J.S.rev.nw.size())
	J.S.day = 1

	# 3c · LA AGENDA DEL MES: la Copa, las fiestas, el plazo y el número que viene
	J.S.rev = {"col": [], "tec": [], "sus": 0, "nw": []}
	var A: Dictionary = R.ag
	var ag1: String = J.rev_agenda(1)
	chk(ag1.ends_with(J.T(String(A.num))), "la agenda no acaba con el número que viene: " + ag1)
	chk(not ag1.contains("{"), "la agenda sin sustituir: " + ag1)
	var ncopa := 0   # el número del mes de la Copa de otoño
	for i in range(1, 25):
		if int(J.rev_my(i).m) == int(J.D.COPA_OT.m):
			ncopa = i
			break
	chk(ncopa > 0, "sin mes de la Copa")
	J.S.ch = int(J.D.COPA_OT.ch)
	chk(J.rev_agenda(ncopa).contains(J.T(String(A.copa), {"d": Datos.fd_corto(Datos.dia_de(int(J.rev_my(ncopa).y), int(J.D.COPA_OT.m), int(J.D.COPA_OT.d)))})),
		"la agenda del mes de la Copa: " + J.rev_agenda(ncopa))
	J.S.ch = 1
	chk(not J.rev_agenda(ncopa).contains(J.T(String(A.copa), {"d": Datos.fd_corto(Datos.dia_de(int(J.rev_my(ncopa).y), int(J.D.COPA_OT.m), int(J.D.COPA_OT.d)))})),
		"la Copa en la agenda antes de su capítulo")
	var nfi := 0   # un número con fiesta
	for i in range(1, 25):
		for f in J.D.CAZA.fi:
			if int(f.m) == int(J.rev_my(i).m):
				nfi = i
				break
		if nfi > 0:
			break
	chk(nfi > 0, "sin fiestas en el calendario")
	if nfi > 0:
		var agf: String = J.rev_agenda(nfi)
		var hay := false
		for f in J.D.CAZA.fi:
			if int(f.m) == int(J.rev_my(nfi).m) and agf.contains(I18n.v(String(f.n))):
				hay = true
		chk(hay, "la fiesta del mes no sale en la agenda: " + agf)
	# el plazo de la deuda, en el mes en que vence
	J.S.due = 5000
	J.S.deadline = 20
	var agp: String = J.rev_agenda(J.rev_num(20))
	chk(agp.contains(J.T(String(A.plazo), {"d": Datos.fd_corto(20)})), "el plazo no sale en su mes: " + agp)
	J.S.due = 0
	J.S.deadline = 0
	var tx2: String = J.rev_texto(1)
	chk(tx2.contains(String(R.sec.ag)) and tx2.contains(J.T(String(A.num))), "el número no trae su agenda")

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

	# 10b · las noticias del cannabis: tres breves por número, de fuera de la comarca y sin repetirse en el mismo número
	# (lo pidió el usuario: «también noticias del cannabis»)
	J.S.ch = 8
	var sinm := []
	for num in range(1, 25):
		var ms: Array = J.rev_mun_de(num)
		var kms := {}
		for m in ms:
			kms[String(m.k)] = 1
		if ms.size() != 3 or kms.size() != 3:
			sinm.append(num)
	chk(sinm.is_empty(), "números con menos de tres noticias del mundo o con repetidas: %s" % [sinm])
	J.S.ch = 1
	var m1: Array = J.rev_mun_de(1)
	var tarde := []
	for m in m1:
		if int(m.ch) > 1:
			tarde.append(String(m.k))
	chk(m1.size() >= 1 and tarde.is_empty(), "el n.º 1 cuenta lo que aún no toca: %s" % [tarde])
	J.S.ch = 8
	var mx: String = J.rev_mundo(3)
	chk(mx.length() > 300 and mx.split("\n\n").size() == 3, "la plana del mundo: %d caracteres" % mx.length())
	var sec: Array = J.rev_secciones(3)
	var hay_mun := false
	for q in sec:
		if String(q.k) == "mun":
			hay_mun = true
	chk(hay_mun, "la sección del mundo no sale en el número")
	chk(J.REV_ART.has("vg-mun") if J.rev_art() else true, "la viñeta del mundo no está en la hoja de arte")

	# 11 · guardada y cargada, sigue
	var S2 = JSON.parse_string(JSON.stringify(J.S))
	J.S = S2
	chk(J.rev_tiene(2) and J.rev_bono("rend") > 0, "tras cargar: %s" % [J.S.rev])

	for x in fallos:
		print("  FALLO ", x)
	print("revista: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
