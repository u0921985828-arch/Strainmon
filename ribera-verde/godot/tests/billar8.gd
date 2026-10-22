# Ribera Verde (Godot) — la bola 8 de verdad (1.58, lo pidió el usuario: «estilo 8 ball pool»; con Datos.CAL): la mesa desde
# arriba con 15 bolas y la blanca, física de choques y bandas (billar8.gd), mesa abierta y luego lisas o rayadas, faltas con bola en
# mano, la negra al final; el rival con la misma física y su pulso. Apuntar con las flechas y la fuerza con A apretado (_b8_tuyo).
# Sin CAL, el billar de barras de antes.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-extr.
#   $GODOT --headless --path godot --script res://tests/billar8.gd   → «billar8: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const B8 = preload("res://src/billar8.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
var S
var D
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []
var auto := true

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

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

func corre(f: Callable, tope := 60000.0) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > tope or not M.paso():
			print("  bloqueo: fin %s libre %s pend %s modo %s" % [st.fin, J.is_free(), J.pending.size(), J.mode])
			return false
	return true

func log_tiene(t: String) -> bool:
	for l in LOG:
		if String(l).contains(t):
			return true
	return false

# una mesa vacía con solo esas bolas: {n: Vector2}
func mesa(bolas: Dictionary, saque := false) -> Dictionary:
	var V := B8.nueva("X")
	for d in V.b:
		d.en = bolas.has(d.n)
		if d.en:
			d.p = bolas[d.n]
	V.saque = saque
	V.mano = false
	return V

func tira(V: Dictionary, q: int, ang: float, f: float) -> Dictionary:
	var ob := B8.objetivos(V, q)
	var ev := B8.dispara(V, ang, f)
	B8.simula(V, ev)
	var r := B8.resuelve(V, ev, q, ob)
	r.ev = ev
	return r

# hacia el centro de b desde a
func hacia(a: Vector2, b: Vector2) -> float:
	return (b - a).angle()

func dentro(V: Dictionary) -> bool:
	for d in V.b:
		if d.en and (d.p.x < B8.R - .5 or d.p.x > B8.W - B8.R + .5 or d.p.y < B8.R - .5 or d.p.y > B8.H - B8.R + .5):
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-billar8.json"
	Juego.AJUSTES = "user://prueba-billar8-ajustes.json"
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
		if auto and J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	Cultivo.pm = 4242
	# 1 · el triángulo: 15 bolas sin tocarse, la negra en el centro, una lisa y una rayada en las esquinas de atrás
	var V := B8.nueva("X")
	var toca := false
	for i in 16:
		for j in range(i + 1, 16):
			if V.b[i].p.distance_to(V.b[j].p) < 2 * B8.R:
				toca = true
	chk(not toca and V.b.size() == 16, "16 bolas sin tocarse")
	chk(V.b[8].p.x > V.b[1].p.x and absf(V.b[8].p.y - B8.H / 2) < .01, "la negra en el centro del triángulo")
	chk(B8.lisa(B8.RACK[4][0]) != B8.lisa(B8.RACK[4][4]), "las esquinas de atrás, una de cada")
	chk(V.b[0].p.x <= B8.W * B8.RAYA and V.saque and V.mano, "la blanca en la cabecera, con bola en mano al sacar")
	# 2 · la física: el saque es determinista, abre el triángulo y nada se sale ni se solapa
	var V1 := B8.nueva("X")
	var e1 := B8.dispara(V1, hacia(V1.b[0].p, V1.b[1].p), .95)
	B8.simula(V1, e1)
	var V2 := B8.nueva("X")
	var e2 := B8.dispara(V2, hacia(V2.b[0].p, V2.b[1].p), .95)
	B8.simula(V2, e2)
	var igual := true
	for i in 16:
		if V1.b[i].p != V2.b[i].p or V1.b[i].en != V2.b[i].en:
			igual = false
	chk(igual, "el mismo saque, la misma mesa")
	chk(e1.primer == 1, "el saque toca la 1 primero")
	chk(B8.quieta(V1) and dentro(V1), "todo quieto y dentro del tapete")
	var abierto := 0.0
	for i in range(1, 16):
		if V1.b[i].en:
			abierto = maxf(abierto, V1.b[i].p.distance_to(V.b[i].p))
	chk(abierto > 20, "el triángulo se abre (%.1f px)" % abierto)
	var solapa := false
	for i in 16:
		for j in range(i + 1, 16):
			if V1.b[i].en and V1.b[j].en and V1.b[i].p.distance_to(V1.b[j].p) < 2 * B8.R - .2:
				solapa = true
	chk(not solapa, "sin bolas solapadas")
	# una bola de frente a la tronera de la esquina entra; la blanca se queda
	var pk: Vector2 = B8.bocas()[0]
	var Vm := mesa({0: Vector2(40, 30), 3: Vector2(25, 18)})
	var dir: Vector2 = (pk - Vm.b[3].p).normalized()
	var fant: Vector2 = Vm.b[3].p - dir * 2 * B8.R
	var r := tira(Vm, 0, hacia(Vm.b[0].p, fant), .45)
	chk(3 in r.ev.met and not Vm.b[3].en and Vm.b[0].en, "la 3 a la tronera de la esquina %s" % [r.ev.met])
	chk(not r.falta and r.sigue and r.grupo == "lisas" and Vm.gr == ["lisas", "rayadas"], "mesa abierta: metes una lisa, eres lisas")
	# el rozamiento la para
	var Vr := mesa({0: Vector2(84, 42)})
	B8.dispara(Vr, 0.3, .3)
	var pasos := 0
	while not B8.quieta(Vr) and pasos < B8.PASOS_MAX:
		B8.paso(Vr, B8.ev_nuevo())
		pasos += 1
	chk(pasos < B8.PASOS_MAX and dentro(Vr), "el paño la para (%d pasos)" % pasos)
	# 3 · las faltas
	var Vb := mesa({0: Vector2(30, 30), 4: Vector2(60, 60)})
	Vb.gr = ["lisas", "rayadas"]
	r = tira(Vb, 0, hacia(Vb.b[0].p, B8.troneras()[0]), 1.0)
	chk(r.falta and r.motivo == "blanca" and not Vb.b[0].en, "se cuela la blanca: falta")
	Vb = mesa({0: Vector2(30, 60), 4: Vector2(140, 20)})
	Vb.gr = ["lisas", "rayadas"]
	r = tira(Vb, 0, PI / 2, .08)
	chk(r.falta and r.motivo == "nada", "sin tocar ninguna: falta (%s)" % r.motivo)
	Vb = mesa({0: Vector2(30, 42), 12: Vector2(60, 42), 4: Vector2(120, 70)})
	Vb.gr = ["lisas", "rayadas"]
	r = tira(Vb, 0, 0.0, .3)
	chk(r.falta and r.motivo == "otra", "primero una rayada siendo lisas: falta")
	# 4 · la negra: antes de tiempo, pierdes; con las tuyas dentro, ganas; con la blanca detrás, pierdes; al sacar, vuelve al pie
	var Vn := mesa({0: Vector2(40, 30), 8: Vector2(25, 18), 2: Vector2(120, 60)})
	Vn.gr = ["lisas", "rayadas"]
	fant = Vn.b[8].p - ((pk - Vn.b[8].p).normalized()) * 2 * B8.R
	r = tira(Vn, 0, hacia(Vn.b[0].p, fant), .45)
	chk(r.fin == "pierde", "la negra antes de tiempo: pierdes (%s)" % r.fin)
	Vn = mesa({0: Vector2(40, 30), 8: Vector2(25, 18), 12: Vector2(120, 60)})
	Vn.gr = ["lisas", "rayadas"]
	chk(B8.objetivos(Vn, 0) == [8], "sin lisas, la negra")
	r = tira(Vn, 0, hacia(Vn.b[0].p, fant), .45)
	chk(r.fin == "gana", "la negra con las tuyas dentro: ganas (%s)" % r.fin)
	Vn = mesa({0: Vector2(40, 30), 8: Vector2(25, 18), 12: Vector2(120, 60)})
	Vn.gr = ["lisas", "rayadas"]
	var ev := B8.ev_nuevo()
	ev.primer = 8
	ev.met = [8]
	ev.blanca = true
	Vn.b[8].en = false
	chk(B8.resuelve(Vn, ev, 0, [8]).fin == "pierde", "la negra y la blanca detrás: pierdes")
	Vn = mesa({0: Vector2(40, 30), 1: Vector2(100, 42), 9: Vector2(130, 20)}, true)
	ev = B8.ev_nuevo()
	ev.primer = 1
	ev.met = [8]
	Vn.b[8].en = false
	var rs := B8.resuelve(Vn, ev, 0, B8.objetivos(Vn, 0))
	chk(rs.fin == "" and Vn.b[8].en and absf(Vn.b[8].p.x - B8.W * B8.PIE) < 8, "la negra al sacar vuelve al pie")
	# en el saque no hay grupo aunque entre una
	Vn = mesa({0: Vector2(40, 30), 1: Vector2(100, 42)}, true)
	ev = B8.ev_nuevo()
	ev.primer = 1
	ev.met = [1]
	rs = B8.resuelve(Vn, ev, 0, B8.objetivos(Vn, 0))
	chk(rs.sigue and Vn.gr == ["", ""], "metes al sacar: sigues, la mesa sigue abierta")
	# 5 · el rival: con la misma física; el bueno gana más; las partidas acaban
	var gana := {0: 0, 1: 0}
	var tiros := 0
	var t0 := Time.get_ticks_msec()
	for g in 12:
		var W := B8.nueva("X")
		var q := 0
		var fin := -1
		var nt := 0
		while fin < 0 and nt < 160:
			nt += 1
			if W.mano:
				W.b[0].en = true
				W.b[0].p = B8.coloca_ia(W, q)
				chk(B8.libre(W, W.b[0].p, 0) and (not W.saque or W.b[0].p.x <= B8.W * B8.RAYA + .01), "bola en mano en sitio libre")
				W.mano = false
			var s := B8.elige(W, q, .55 if q == 0 else .3)
			r = tira(W, q, s.ang, s.f)
			W.saque = false
			if r.fin != "":
				fin = q if r.fin == "gana" else 1 - q
			elif r.falta:
				W.mano = true
				q = 1 - q
			elif not r.sigue:
				q = 1 - q
		tiros += nt
		if fin >= 0:
			gana[fin] += 1
	chk(gana[0] + gana[1] >= 11, "las partidas acaban (%s)" % [gana])
	chk(gana[0] > gana[1], "el de más pulso gana más (%s)" % [gana])
	var ms := float(Time.get_ticks_msec() - t0) / maxf(1, tiros)
	chk(ms < 400, "lo que piensa el rival, por tiro: %.0f ms" % ms)
	# 6 · el dibujo: dentro de la pantalla en cada fase
	for fase in ["coloca", "apunta", "carga", "ia", "rueda"]:
		V = B8.nueva("Ander")
		V.fase = fase
		V.f = .6
		V.ang = .2
		V.gr = ["lisas", "rayadas"]
		var o: Array = B8.rects(V, 240, 180, 0)
		var fuera := o.filter(func(x): return x[0] < 0 or x[1] < 0 or x[0] + x[2] > 240 or x[1] + x[3] > 180)
		chk(o.size() > 100 and fuera.is_empty(), "%s: %d rectángulos, %d fuera" % [fase, o.size(), fuera.size()])
	# 7 · los mandos de verdad: bola en mano con las flechas, apuntar y la fuerza con A apretado
	auto = false
	V = B8.nueva("X")
	J.MESA8 = V
	var x0: float = V.b[0].p.x
	var y0: float = V.b[0].p.y
	var res := {"r": {}}
	M.timeout(func(): J.set_held("down", true), 50)
	M.timeout(func(): J.set_held("down", false), 550)
	M.timeout(func(): J.press("A"), 650)          # deja la blanca
	M.timeout(func(): J.set_held("right", true), 800)
	M.timeout(func(): J.set_held("right", false), 1100)
	M.timeout(func():
		J.set_held("A", true)
		J.press("A"), 1300)                        # empieza a cargar
	M.timeout(func(): J.set_held("A", false), 1300 + B8.CARGA_MS * .5)
	var a_ini := {"v": 0.0}
	M.timeout(func(): a_ini.v = float(V.ang), 790)
	chk(corre(func(): res.r = await J._b8_tuyo(V, "X"), 20000), "tu tiro con los mandos")
	chk(V.b[0].p.y > y0 + 12 and absf(V.b[0].p.x - x0) < .01 and not V.mano, "la blanca baja con la flecha (%.1f → %.1f)" % [y0, V.b[0].p.y])
	chk(not res.r.is_empty() and absf(float(res.r.f) - .5) < .06, "media carga, media fuerza (%s)" % [res.r])
	chk(not res.r.is_empty() and float(res.r.ang) > a_ini.v + .05, "a la derecha gira (%.2f → %s)" % [a_ini.v, res.r.get("ang")])
	# la blanca no sale de la cabecera al sacar
	V = B8.nueva("X")
	J.MESA8 = V
	M.timeout(func(): J.set_held("right", true), 50)
	M.timeout(func(): J.set_held("right", false), 3000)
	M.timeout(func(): J.press("A"), 3100)
	M.timeout(func(): J.press("B"), 3300)          # ¿lo dejas? → Dejarlo
	for t in [3400, 3700, 4200, 5200, 7000]:    # y A en el menú, cuando salga
		M.timeout(func():
			if J.handlers.size():
				J.press("A"), t)
	QUIERO = ["Dejarlo"]
	chk(corre(func(): res.r = await J._b8_tuyo(V, "X"), 20000), "B para dejarlo")
	chk(V.b[0].p.x <= B8.W * B8.RAYA + .01, "al sacar, la blanca no pasa de la cabecera")
	chk(res.r.is_empty(), "lo dejas: {}")
	J.MESA8 = null
	auto = true
	# 8 · la partida entera desde el billarista, con apuesta: gana el que la gana, paga el que pierde
	S.money = 500.0
	S.billar = {}
	J.gancho_billar8 = func(W): return B8.elige(W, 0, 1.0)
	var din := float(S.money)
	QUIERO = ["A 20 €"]
	LOG.clear()
	chk(corre(func(): await J.talk_billar("puerto")), "partida con apuesta")
	var dif := float(S.money) - din
	chk(dif == 20 or dif == -20 or dif == 0, "se paga la apuesta (%s)" % dif)
	chk(int(S.billar.puerto.n) == 1 and J.MESA8 == null, "una partida del día, y la mesa se quita")
	chk(log_tiene("Mesa abierta"), "pregunta con la mesa abierta")
	# dejarla es perderla
	J.gancho_billar8 = func(_W): return null
	din = float(S.money)
	QUIERO = ["A 10 €"]
	chk(corre(func(): await J.talk_billar("puerto")), "la dejas")
	chk(float(S.money) == din - 10, "la dejas: pagas")
	# 9 · sin CAL, el de barras de antes
	Datos.CAL = false
	J.gancho_billar8 = func(_W):
		chk(false, "sin CAL no hay mesa de bolas")
		return null
	J.gancho_billar = func(_t): return .7
	Cultivo.fijo = .9
	QUIERO = ["A 10 €"]
	LOG.clear()
	chk(corre(func(): await J.talk_billar("puerto")), "sin CAL")
	chk(log_tiene("lisas para ti"), "sin CAL, el texto de antes")
	Cultivo.fijo = -1
	J.gancho_billar = Callable()
	J.gancho_billar8 = Callable()
	Datos.CAL = true
	# 10 · las capturas (con -- --sin-arranque --pintar <dir>, xvfb y opengl3): billar8-<momento>.png
	var dpin := arg("--pintar")
	if dpin != "":
		J.set_process(false)
		J.oraculo = false
		Cultivo.pm = 777
		var Vc := B8.nueva("Ander")
		var fotos := []
		Vc.fase = "coloca"
		fotos.append(["saque", Vc.duplicate(true), "Bola en mano: las flechas la mueven y A la deja."])
		Vc.mano = false
		Vc.fase = "apunta"
		Vc.ang = hacia(Vc.b[0].p, Vc.b[1].p) + .01
		fotos.append(["apunta", Vc.duplicate(true), "Flechas: apuntar (arriba y abajo, fino). A apretado: la fuerza; al soltar, tiras. B: dejarlo."])
		var evc := B8.dispara(Vc, Vc.ang, .95)
		B8.simula(Vc, evc)
		Vc.saque = false
		Vc.gr = ["lisas", "rayadas"]
		for nn in [2, 5, 11]:
			Vc.b[nn].en = false
		Vc.fase = "carga"
		Vc.f = .7
		var bo: Array = B8.objetivos(Vc, 0)
		Vc.ang = hacia(Vc.b[0].p, Vc.b[bo[0]].p)
		fotos.append(["carga", Vc.duplicate(true), "Te quedas las lisas. Dentro. Sigues."])
		Vc.fase = "ia"
		Vc.turno = 1
		Vc.f = .4
		fotos.append(["rival", Vc.duplicate(true), "Estudia la mesa…"])
		for fo in fotos:
			J.MESA8 = fo[1]
			J._dlg_fijo(fo[2], "ANDER" if fo[0] == "rival" else "")
			for q in 2:
				await process_frame
				J.pintor.redibuja(M.reloj)
				for rr in 4:
					await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(dpin.path_join("billar8-%s.png" % fo[0]))
		J.MESA8 = null
		J.oraculo = true
	print("billar8: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
