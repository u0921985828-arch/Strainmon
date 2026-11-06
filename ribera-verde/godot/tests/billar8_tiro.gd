# Ribera Verde (Godot) — el tiro de la bola 8 con más control y el rival equilibrado y rápido (lo pidió el usuario: «el control del
# tiro: apuntar más fino, efecto a la blanca, la fuerza más clara; y el rival equilibrado y rápido»; con CAL): el efecto de la blanca
# (retroceso y seguir) en la física, arriba y abajo de un toque en pasos de 0,2°, un toque de A cambia el efecto, la barra con sus
# marcas, la del último tiro y la blanca con el punto del taco; el rival que se ajusta a cómo te va con él y que no se hace esperar.
#   $GODOT --headless --path godot --script res://tests/billar8_tiro.gd   → «billar8_tiro: N comprobaciones, 0 fallos»
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

# la blanca a la izquierda de la bola 1, en línea, golpe lleno: dónde acaba la blanca con cada efecto
func lleno(efe: float) -> float:
	var V := mesa({0: Vector2(20, 42), 1: Vector2(50, 42)})   # floja: que la bola no vuelva de la banda
	var ev := B8.dispara(V, 0.0, .2, efe)
	B8.simula(V, ev)
	return V.b[0].p.x

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-billar8-tiro.json"
	Juego.AJUSTES = "user://prueba-billar8-tiro-ajustes.json"
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
	# 1 · el efecto en la física: al centro se para casi en el sitio; con retroceso vuelve; con seguir sigue tras la bola
	var x0 := lleno(0.0)
	var xr := lleno(-1.0)
	var xs := lleno(1.0)
	chk(absf(x0 - 47.5) < 6, "al centro, la blanca se queda donde choca (%.1f)" % x0)
	chk(xr < x0 - 12, "con retroceso, vuelve (%.1f < %.1f)" % [xr, x0])
	chk(xs > x0 + 12, "con seguir, sigue (%.1f > %.1f)" % [xs, x0])
	var V := mesa({0: Vector2(40, 42), 1: Vector2(80, 42)})
	var ev := B8.dispara(V, 0.0, .45, -1.0)
	B8.simula(V, ev)
	chk(float(V.b[0].get("efe", 0.0)) == 0.0, "el efecto se gasta en el choque")
	V = mesa({0: Vector2(40, 42), 1: Vector2(80, 70)})   # sin bola delante: a la banda, y el efecto se va
	ev = B8.dispara(V, 0.0, .3, 1.0)
	B8.simula(V, ev)
	chk(float(V.b[0].get("efe", 0.0)) == 0.0, "en la banda, el efecto se va")
	V = mesa({0: Vector2(40, 42), 1: Vector2(80, 42)})
	var ev2 := B8.dispara(V, 0.0, .45)
	chk(float(V.b[0].efe) == 0.0, "sin decirlo, al centro (el rival y lo de antes)")
	# 2 · los mandos: un toque de arriba o abajo, un paso fino; un toque de A, el efecto; A apretado, la fuerza
	auto = false
	V = mesa({0: Vector2(40, 42), 1: Vector2(120, 42)})
	J.MESA8 = V
	var res := {"r": {}}
	var a := {"v": 0.0, "d": 0.0, "e": []}
	M.timeout(func(): a.v = float(V.ang), 100)
	M.timeout(func(): J.press("down"), 150)
	M.timeout(func(): J.press("down"), 200)
	M.timeout(func(): a.d = float(V.ang), 260)
	M.timeout(func():
		J.set_held("A", true)
		J.press("A"), 400)
	M.timeout(func(): J.set_held("A", false), 450)    # un toque: el efecto
	M.timeout(func(): a.e.append(float(V.efe)), 500)
	M.timeout(func():
		J.set_held("A", true)
		J.press("A"), 600)
	M.timeout(func(): J.set_held("A", false), 650)
	M.timeout(func(): a.e.append(float(V.efe)), 700)
	M.timeout(func():
		J.set_held("A", true)
		J.press("A"), 900)
	M.timeout(func(): J.set_held("A", false), 900 + B8.CARGA_MS * .4)
	chk(corre(func(): res.r = await J._b8_tuyo(V, "X"), 20000), "tu tiro con los mandos")
	chk(absf(a.d - a.v - 2 * J.B8_PASO) < 1e-4, "dos toques abajo: dos pasos de 0,2° (%.4f)" % (a.d - a.v))
	chk(a.e == [-1.0, 1.0], "un toque de A: retroceso y luego seguir (%s)" % [a.e])
	chk(not res.r.is_empty() and float(res.r.efe) == 1.0 and absf(float(res.r.f) - .4) < .06, "el tiro lleva el efecto y su fuerza (%s)" % [res.r])
	chk(absf(float(V.get("fza", -1)) - float(res.r.get("f", 0))) < 1e-6, "la marca del último tiro")
	auto = true
	# 3 · la barra: las tres marcas de un cuarto, la del último tiro y la blanca con el punto del taco (más arriba con seguir)
	V.f = .5
	var R1: Array = B8.rects(V, 240, 180, 1000.0)
	var O2 := B8.origen(240)
	var bx: int = O2.x - B8.BANDA - 9
	var marcas := R1.filter(func(q): return typeof(q[0]) != TYPE_STRING and q[0] == bx - 2 and q[2] == 2 and q[3] == 1)
	chk(marcas.size() == 3, "tres marcas en la barra: %d" % marcas.size())
	var pto := func(VV) -> int:
		for q in B8.rects(VV, 240, 180, 1000.0):
			if typeof(q[0]) != TYPE_STRING and q[4] == "#e04040" and q[2] == 1 and q[3] == 1 and q[0] == bx + 2:
				return int(q[1])
		return -1
	V.efe = 1.0
	var ya: int = pto.call(V)
	V.efe = -1.0
	var yb: int = pto.call(V)
	chk(ya > 0 and yb > ya, "el punto del taco: arriba con seguir, abajo con retroceso (%d, %d)" % [ya, yb])
	J.MESA8 = null
	# 4 · el rival equilibrado: le ganas, juega mejor; pierdes, peor; con un tope
	S.erase("b8aj")
	chk(J.b8_ajuste("puerto") == 0.0, "de primeras, su pulso")
	J.b8_apunta("puerto", "yo")
	chk(is_equal_approx(J.b8_ajuste("puerto"), J.B8_AJ), "le ganas: sube %.2f" % J.b8_ajuste("puerto"))
	J.b8_apunta("puerto", "el")
	J.b8_apunta("puerto", "el")
	chk(is_equal_approx(J.b8_ajuste("puerto"), -J.B8_AJ), "pierdes dos: baja (%.2f)" % J.b8_ajuste("puerto"))
	for k in 10:
		J.b8_apunta("puerto", "el")
	chk(is_equal_approx(J.b8_ajuste("puerto"), -J.B8_AJ_MAX), "con su tope (%.2f)" % J.b8_ajuste("puerto"))
	J.b8_apunta("puerto", "")
	chk(is_equal_approx(J.b8_ajuste("puerto"), -J.B8_AJ_MAX), "tablas: nada")
	chk(J.b8_ajuste("valde") == 0.0, "por club")
	Datos.CAL = false
	chk(J.b8_ajuste("puerto") == 0.0, "sin CAL, su pulso de siempre")
	Datos.CAL = true
	# 5 · rápido: lo que tarda el rival en tirar, con la mesa a la vista (sin el oráculo)
	J.oraculo = false
	V = B8.nueva("X")
	V.saque = false
	J.MESA8 = V
	var t0: float = M.reloj
	var tr0 := Time.get_ticks_msec()
	var s := {"r": {}}
	chk(corre(func(): s.r = await J._b8_suyo(V, .4, "X"), 10000000), "el rival tira (piensa en otro hilo: aquí el reloj del juego corre sin esperar)")
	var ms: float = M.reloj - t0
	var mr: int = Time.get_ticks_msec() - tr0
	chk(not s.r.is_empty() and s.r.has("ang") and mr < J.B8_PIENSA_MAX + 1500, "y no se hace esperar: %.0f ms de juego, %d de reloj" % [ms, mr])
	# piensa con tope: con la hora ya pasada, se queda con el primer tiro que valga, enseguida
	var V2 := B8.nueva("X")
	var evq := B8.dispara(V2, .3, 1.0)
	B8.simula(V2, evq)
	V2.saque = false
	var te := Time.get_ticks_msec()
	var e1 := B8.elige(V2, 1, .5, te)
	var de := Time.get_ticks_msec() - te
	chk(e1.has("ang") and e1.has("f") and de < 400, "con el tope pasado, %d ms y un tiro (%s)" % [de, e1.get("tipo")])
	J.MESA8 = null
	J.oraculo = true
	print("billar8_tiro: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
