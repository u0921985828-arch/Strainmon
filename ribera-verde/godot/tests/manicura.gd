# Ribera Verde (Godot) — la manicura a la vista (setas.gd manicura_action con CAL; lo pidió el usuario: «una escena como la de las
# extracciones»): tres pasos con su barra y la escena «mani» encima (escena_extr.gd); la parte que entra deja el lote manicurado en
# MANICURA.base + (1 − base) × q, y por debajo de 1 se puede repasar; sin CAL, el gesto de antes y manicurado entero.
#   $GODOT --headless --path godot --script res://tests/manicura.gd   → «manicura: N comprobaciones, 0 fallos»
#   con ventana y -- --sin-arranque --salida <dir>: la escena de cada paso, que se pinta y se mueve (mani-<paso>-<a|b>.png)
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var LOG := []
var QUIERO := []
var TIROS := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
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
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
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
			print("  bloqueo")
			return false
	return true

func dicho(t: String) -> bool:
	return LOG.any(func(l): return String(l).contains(t))

# la escena animada (lo pidió el usuario: «rehaz las demás animaciones, con esta calidad»): sus 4 fotogramas de PixelLab, distintos de
# la escena, y en pantalla, en el sitio de la escena, el fotograma que toca a cada hora
func anima(now: float, T: Dictionary, k: String) -> String:
	var Es = load("res://src/escena_extr.gd")
	var b0: Image = Es.pl(k)
	for i in range(1, 5):
		var f: Image = Es.PL.get("%s/%d" % [k, i])
		if f == null or f.get_size() != b0.get_size():
			return "sin el fotograma %d" % i
		if f.get_data() == b0.get_data():
			return "el fotograma %d es la escena quieta" % i
	var c := 8 * int(Es.PL_MS)
	var t0: float = floorf(now / c) * c + 1
	var vistos := {}
	var antes: Image = null
	for paso in [0, 1, 2]:
		var t: float = t0 + paso * int(Es.PL_MS)
		var im: Image = await foto(T, t)
		var y0: int = ((J.SH - 8) >> 1) - int(Es.H) - 10
		var q: Image = im.get_region(Rect2i((J.SW - int(Es.W)) >> 1, y0, int(Es.W), int(Es.H)))
		var esp: Image = Es.pl_t(k, t).duplicate()
		esp.convert(Image.FORMAT_RGBA8)
		if q.get_data() != esp.get_data():
			return "a los %d ms no se ve el fotograma %d" % [int(t - t0), Es.foto_pl(k, t)]
		vistos[Es.foto_pl(k, t)] = 1
		if antes != null and antes.get_data() == q.get_data():
			return "la escena no cambia a los %d ms" % int(t - t0)
		antes = q
	return "" if vistos.size() == 3 else "solo %d fotogramas" % vistos.size()

func foto(T, now: float) -> Image:
	J.TIRO = T
	J.pintor.redibuja(now)
	for q in 3:
		await RenderingServer.frame_post_draw
	var im: Image = J.sv.get_texture().get_image()
	im.convert(Image.FORMAT_RGBA8)
	return im

func escenas(dir: String) -> void:
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "tiro-lavadora":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.set_process(false)
	J.pintor.ambiente_on = false
	J.SW = int(e.sw)
	J.sv.size = Vector2i(J.SW, J.SH)
	J.S = e.S
	J.B = e.B
	J.VC = e.VC
	J.vfx = e.vfx
	J.ents = []
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.SOSP = e.SOSP
	for c in e.P:
		J.P[c] = e.P[c]
	J.mode = e.mode
	var now: float = e.now
	var Pa: Array = J.D.MANICURA.pasos
	for i in Pa.size():
		var T: Dictionary = e.TIRO.duplicate()
		T.merge({"esc": "mani", "paso": i, "n": Pa.size(), "per": float(J.D.MANICURA.per), "mov": 0.0, "ritmo": 0.0}, true)
		var sin_esc: Dictionary = T.duplicate()
		sin_esc.erase("esc")
		var base: Image = await foto(sin_esc, now)
		var a: Image = await foto(T, now)
		var b: Image = await foto(T, now + 730)
		a.save_png(dir.path_join("mani-%d-a.png" % i))
		b.save_png(dir.path_join("mani-%d-b.png" % i))
		chk(a.get_data() != base.get_data(), "paso %d: se pinta" % i)
		chk(a.get_data() != b.get_data(), "paso %d: se mueve" % i)
		chk(load("res://src/escena_extr.gd").pl("mani-%d" % i) != null, "paso %d: su escena de PixelLab" % i)
		var m: String = await anima(now, T, "mani-%d" % i)
		chk(m == "", "paso %d: animada (%s)" % [i, m])
	print("manicura: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-manicura.json"
	Juego.AJUSTES = "user://prueba-manicura-ajustes.json"
	Datos.CAL = true
	var dir := arg("--salida")
	if dir != "":
		await escenas(dir)
		return
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	var S = J.S
	var D: Dictionary = J.D
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	S.buds = {}
	S.rosin = {}
	S.items.erase("prensa")
	S.items.erase("tamiz")
	S.items.erase("ice")
	S.items.erase("lavadora")
	S.items.erase("estatica")
	var sid: String = D.STRAINS.keys()[0]
	J.add_buds(sid, 40, 15)
	var lote := func(): QUIERO = [str(J.lot_item([sid, S.buds[sid]]).label)]
	var Pa: Array = D.MANICURA.pasos
	chk(Pa.size() == 3 and Pa.all(func(q): return q[0] is String and float(q[1]) > 0), "tres pasos con su tolerancia")
	# 1 · los tres pasos, con la escena «mani» encima de cada barra; todos dentro: manicurado entero
	var c0 := float(D.BILLAR.centro)
	J.gancho_billar = func(txt):
		TIROS.append(txt)
		return c0
	LOG = []
	lote.call()
	chk(corre(func(): await J.manicura_action()), "la mesa")
	chk(TIROS.size() == 3 and TIROS[0] == Pa[0][0], "tres barras: %s" % [TIROS])
	chk(float(S.buds[sid].mc) == 1.0 and dicho("manicurados"), "todo dentro: manicurado entero (%s)" % S.buds[sid].get("mc"))
	# 2 · ninguno dentro: a medias, y se puede repasar
	S.buds[sid].erase("mc")
	TIROS = []
	J.gancho_billar = func(txt):
		TIROS.append(txt)
		return c0 + 1.0
	LOG = []
	lote.call()
	chk(corre(func(): await J.manicura_action()) and is_equal_approx(float(S.buds[sid].mc), float(D.MANICURA.base)), "todo fuera: %s" % S.buds[sid].get("mc"))
	chk(dicho("Se pueden repasar"), "y lo dice: %s" % [LOG])
	chk(J.bud_lots(1).filter(func(l): return float(l[1].get("mc", 0)) < 1).size() == 1, "a medias, sale otra vez para repasar")
	# 3 · repasado con uno dentro: sube, nunca baja
	var i0 := [0]
	J.gancho_billar = func(_txt):
		i0[0] += 1
		return c0 if i0[0] == 1 else c0 + 1.0
	lote.call()
	chk(corre(func(): await J.manicura_action()) and is_equal_approx(float(S.buds[sid].mc), float(D.MANICURA.base) + (1 - float(D.MANICURA.base)) / 3.0), "repasado: %s" % S.buds[sid].get("mc"))
	var mc1 := float(S.buds[sid].mc)
	J.gancho_billar = func(_txt): return c0 + 1.0
	lote.call()
	chk(corre(func(): await J.manicura_action()) and float(S.buds[sid].mc) == mc1, "otra vez fuera: no baja")
	# 4 · el precio, por lo manicurado
	var p1: float = J.calidad(S.buds[sid]) if J.has_method("calidad") else 0.0
	chk(J.has_method("calidad") == false or p1 > 1.0, "se vende más caro: %s" % p1)
	# 5 · sin CAL, el gesto de antes, sin barras, y manicurado entero
	Datos.CAL = false
	S.buds[sid].erase("mc")
	TIROS = []
	J.gancho_billar = func(txt):
		TIROS.append(txt)
		return c0
	lote.call()
	chk(corre(func(): await J.manicura_action()) and TIROS.is_empty() and float(S.buds[sid].mc) == 1.0, "sin CAL, como antes (%s · %s)" % [TIROS, S.buds[sid].get("mc")])
	Datos.CAL = true
	print("manicura: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
