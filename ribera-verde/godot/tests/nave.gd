# Ribera Verde (Godot) — 1.41: la nave por ciclos (lo pidió el usuario: «que sea realista»): los clones enraízan, crecen a 18/6 y
# florecen a 12/12 al ritmo de su variedad; al acabar, la mesa se corta entera (W × g/W de sus focos), se seca en el secadero y vuelve a
# empezar. Y la caja fuerte, con los tarros que llenaría cada lote de verdad (ALM.tarro g por tarro).
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla caja-dentro.
#   $GODOT --headless --path godot --script res://tests/nave.gd   → «nave: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también nave-caja-<caso>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
var D
var MENUS := []
var LOG := []
var QUIERO := ""
var n := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

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
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

# una mañana en la nave, sin redada
func manana() -> void:
	J.S.day += 1
	Cultivo.fijo = .99
	J.nave_dia()
	Cultivo.fijo = -1

func r1(x: float) -> float:
	return Datos.jsround(x * 10) / 10.0

# lo que da una mesa entera al final del ciclo, contado aquí aparte: W × g/W × variedad × fenotipo × cuidado × riego × abono
func espera_g(sid: String, foco: String, y: float, cui: int, ab: float) -> float:
	var F: Dictionary = D.FOCO_NAVE[foco]
	return r1(float(F.w) * float(F.gpw) * float(D.STRAINS[sid].y) / float(D.Y_MEDIA) * y * (float(D.NAVE.g) + float(D.NAVE.gC) * (cui - 3)) / float(D.NAVE.g) * (1 + float(D.ABONO.rend) * ab))

func pinta(dir: String, k: String, A: Dictionary) -> void:
	J.ALMACEN = A
	J._dlg_fijo(J.desc_almacen(A), "CAJA FUERTE")
	await process_frame
	await process_frame
	J.pintor.redibuja(0.0)
	for q in 4:
		await RenderingServer.frame_post_draw
	var im: Image = root.get_texture().get_image()
	im.save_png(dir.path_join("nave-caja-%s.png" % k))
	J.ALMACEN = null

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-nave.json"
	Juego.AJUSTES = "user://prueba-nave-ajustes.json"
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
	var dir := arg("--pintar")
	# 0 · la caja por dentro: un lote de 300 g son 3 tarros (115 + 115 + 70); uno de 40 g, 1
	J.S.caja.buds = {"ria": {"g": 300, "thc": 12}, "cheese": {"g": 40, "thc": 17}}
	var tg := float(D.ALM.tarro)
	var its: Array = J.items_almacen("caja")
	var tj := its.filter(func(x): return x.k == "ria")
	chk(its.size() == 2 + 3 + 1, "tarros: %d" % its.size())
	chk(tj.size() == 3 and tj[0].gj == tg and tj[1].gj == tg and tj[2].gj == 300 - 2 * tg and tj.all(func(x): return x.n == 3), "tarros de 300 g: %s" % [tj.map(func(x): return x.gj)])
	var A := {"t": "caja", "i": its.find(tj[2])}
	chk(J.desc_almacen(A).contains("300 g en 3 tarros (este, el 3.º: 70 g)"), "texto del tarro: " + J.desc_almacen(A))
	A.i = its.find(its.filter(func(x): return x.k == "cheese")[0])
	chk(not J.desc_almacen(A).contains("tarros"), "un tarro: " + J.desc_almacen(A))
	var rs: Array = J.rects_almacen({"t": "caja", "i": 4})
	chk(rs.all(func(r): return r[0] is String or (r[0] >= 0 and r[1] >= 0 and r[0] + r[2] <= J.SW and r[1] + r[3] <= 120)), "caja fuera de la pantalla")
	if dir != "":
		await process_frame
		J.set_process(false)
		J.S.caja.buds = {"ria*": {"g": 1906 - 258, "thc": 26.5}, "cheese": {"g": 129, "thc": 17}, "purpura": {"g": 129, "thc": 18}}
		await pinta(dir, "lote", {"t": "caja", "i": 3})
		await pinta(dir, "lote", {"t": "caja", "i": 3})
		await pinta(dir, "abajo", {"t": "caja", "i": 12})
		J.set_process(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · la nave con dos naveros (cuidado 3 en la mesa 1 y 5 en la 2) y la mesa 3 sin nadie
	J.S.ch = 5
	J.S.nave = J.nave_nueva()
	J.S.plantilla = [{"n": "Itziar", "rol": "nave", "mesa": 0, "cui": 3, "lab": 3, "lea": 3}, {"n": "Iker", "rol": "nave", "mesa": 1, "cui": 5, "lab": 3, "lea": 3}]
	J.S.buds = {}
	J.S.items.bolsa = 2
	J.S.esquejes = [{"sid": "ria", "f": {"id": 9901, "t": 1, "y": 1, "i": 50}, "dia": J.S.day}]
	QUIERO = "Esqueje"
	chk(corre(func(): await J.plantar_mesa(0)), "plantar bloqueado")
	var Me = J.S.nave.m[0]
	chk(Me != null and Me.p == float(D.NAVE.clon) and Me.n == 0 and J.fase_mesa(0) == 1, "plantada: %s" % [Me])
	var dd: int = ceili((1 - float(D.NAVE.clon)) * float(D.STRAINS.ria.d))
	chk(" ".join(LOG).contains("en unos %d días" % dd), "aviso al plantar: %s" % [LOG])
	# 2 · los días del ciclo: enraizando → vegetativo → floración → engordando; sin cosechar hasta el final
	var fases := []
	var d0: int = J.S.day
	while J.S.nave.m[0].get("h") == null and J.S.day - d0 < 10:
		fases.append(J.fase_mesa(0))
		manana()
	chk(J.S.day - d0 == dd, "días hasta la cosecha: %d (espera %d)" % [J.S.day - d0, dd])
	chk(fases == [1, 2, 4], "fases: %s" % [fases])
	var g0 := espera_g("ria", "led", 1.0, 3, 0)
	chk(Me.h.g == g0 and Me.h.d == J.S.day and Me.g == 0, "cosecha: %s (espera %s)" % [Me.h, g0])
	chk(Me.h.t == r1(J.thc_nave("ria", Me.f)), "THC: %s" % Me.h.t)
	chk(g0 > 1000, "una mesa de 1.440 W da más de 1 kg: %s" % g0)
	chk(Me.p == float(D.NAVE.clon) and Me.n == 1 and J.fase_mesa(0) == 1, "vuelve a empezar: %s" % [Me])
	# 3 · se seca: hoy no se descuelga; mañana, sí, con su día de cosecha
	LOG = []
	chk(corre(J.secadero_nave), "secadero bloqueado")
	chk(" ".join(LOG).contains("secándose") and J.S.buds.is_empty(), "colgado: %s" % [LOG])
	var dc: int = J.S.day
	manana()
	chk(Me.get("h") == null and Me.g == g0 and Me.cd == dc, "seco: %s" % [Me])
	chk(J.nave_stock() == g0 and J.colgado_nave() == 0, "en el secadero %s" % J.nave_stock())
	LOG = []
	chk(corre(J.secadero_nave), "descolgar bloqueado")
	var cab: float = floor(minf(g0, J.cap_mochila()))
	chk(J.S.buds.has("ria") and J.S.buds.ria.g == cab and int(J.S.buds.ria.get("dia", -1)) == dc, "descolgado: %s" % [J.S.buds])
	# 4 · el abono por los días que lo tuvo: la mesa 2 (cuidado 5), con MEATZA todo el ciclo; la 3, sin navero, no avanza
	J.S.buds = {}
	J.S.nave.m[0] = null
	J.S.nave.m[1] = {"k": "ria", "f": {"t": 1, "y": 1}, "thc": 10.8, "y": 1, "dia": J.S.day, "g": 0, "t": 0, "abo": 1, "p": float(D.NAVE.clon), "dn": 0, "am": 0, "ao": 0, "n": 0}
	J.S.nave.m[2] = {"k": "ria", "f": {"t": 1, "y": 1}, "thc": 10.8, "y": 1, "dia": J.S.day, "g": 0, "t": 0, "abo": 0, "p": float(D.NAVE.clon), "dn": 0, "am": 0, "ao": 0, "n": 0}
	J.S.nave.ab.m = 10
	for q in dd:
		manana()
	var M1 = J.S.nave.m[1]
	var g1 := espera_g("ria", "led", 1.0, 5, 1.0)
	chk(M1.get("h") != null and M1.h.g == g1 and M1.h.t == r1(10.8 + float(D.ABONO.thc)), "abonada: %s (espera %s)" % [M1.get("h"), g1])
	chk(J.S.nave.ab.m == 10 - dd, "dosis gastadas: %s" % J.S.nave.ab.m)
	chk(J.S.nave.m[2].p == float(D.NAVE.clon) and J.S.nave.m[2].get("h") == null, "sin navero no avanza: %s" % [J.S.nave.m[2]])
	# con abono solo un día de los del ciclo: 1/dd del abono
	J.S.nave.m[1] = {"k": "ria", "f": {"t": 1, "y": 1}, "thc": 10.8, "y": 1, "dia": J.S.day, "g": 0, "t": 0, "abo": 1, "p": float(D.NAVE.clon), "dn": 0, "am": 0, "ao": 0, "n": 0}
	J.S.nave.ab.m = 1
	for q in dd:
		manana()
	chk(J.S.nave.m[1].h.g == espera_g("ria", "led", 1.0, 5, 1.0 / dd), "medio abono: %s" % [J.S.nave.m[1].h])
	# 5 · los focos: sodio da menos por vatio que el LED (y la cerámica, en medio)
	var gs := espera_g("ria", "sodio", 1.0, 3, 0)
	var gl := espera_g("ria", "lec", 1.0, 3, 0)
	chk(gs < gl and gl < g0, "sodio %s < cerámica %s < LED %s" % [gs, gl, g0])
	J.S.nave.f[0] = "sodio"
	J.S.nave.m[0] = {"k": "ria", "f": {"t": 1, "y": 1}, "thc": 10.8, "y": 1, "dia": J.S.day, "g": 0, "t": 0, "abo": 0, "p": .99, "dn": 3, "am": 0, "ao": 0, "n": 0}
	manana()
	chk(J.S.nave.m[0].h.g == gs, "sodio: %s (espera %s)" % [J.S.nave.m[0].h, gs])
	# 6 · una sativa tarda más: la Kali Mist (d 4) más días que la Skunk #1 (d 2,5)
	J.S.nave.m[0] = {"k": "kali", "f": {"t": 1, "y": 1}, "thc": 16.2, "y": 1, "dia": J.S.day, "g": 0, "t": 0, "abo": 0, "p": float(D.NAVE.clon), "dn": 0, "am": 0, "ao": 0, "n": 0}
	d0 = J.S.day
	while J.S.nave.m[0].get("h") == null and J.S.day - d0 < 10:
		manana()
	chk(J.S.day - d0 == ceili((1 - float(D.NAVE.clon)) * float(D.STRAINS.kali.d)) and J.S.day - d0 > dd, "sativa: %d días" % (J.S.day - d0))
	# 7 · una mesa de antes (por días, sin p): su fase por días y, a la mañana, entra en el ciclo
	J.S.nave.m[0] = {"k": "ria", "thc": 10.8, "y": 1, "dia": J.S.day - int(D.NAVE.crece), "g": 30.5, "t": 10.8, "abo": 0}
	chk(J.fase_mesa(0) == 4 and J.prog_mesa(J.S.nave.m[0]) == .95, "mesa de antes: %d %s" % [J.fase_mesa(0), J.prog_mesa(J.S.nave.m[0])])
	manana()
	chk(J.S.nave.m[0].get("h") != null and J.S.nave.m[0].g == 30.5 and J.S.nave.m[0].p == float(D.NAVE.clon), "mesa de antes, cosechada: %s" % [J.S.nave.m[0]])
	# 8 · la redada se lo lleva todo, también lo que cuelga
	var tot: float = J.nave_stock()
	chk(tot >= J.colgado_nave() + 30.5 and J.colgado_nave() > 0, "con lo colgado: %s" % tot)
	LOG = []
	J.S.day += 1
	Cultivo.fijo = 0
	J.nave_dia()
	Cultivo.fijo = -1
	chk(corre(func(): pass), "redada bloqueada")
	chk(J.S.nave == null and " ".join(LOG).contains("La policía ha entrado en la nave"), "redada: %s" % [LOG])
	for x in fallos:
		print("  FALLO ", x)
	print("nave: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
