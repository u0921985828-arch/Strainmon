# Ribera Verde (Godot) — el armario de las madres de la nave por dentro (nave.gd vista_madres, con CAL; lo pidió el usuario: «vista
# por dentro, como la carpa de casa»): la carpa de la vista C con el LED a 18/6 y su temporizador, las madres con el tono de su hoja y
# los huecos; las flechas eligen, A abre la madre (cortarle esquejes tú, una vez al día, recoger los listos) o mete una en el hueco, B
# cierra; sin CAL, el menú de antes.
#   $GODOT --headless --path godot --script res://tests/madres_vista.gd   → «madres_vista: N comprobaciones, 0 fallos»
#   (con -- --fotos <dir> y ventana, la captura de la vista)
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var LOG := []
var MENUS := []
var TIT := []
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
	MENUS.append(items.map(func(it): return it if it is String else str(it.get("label", ""))))
	TIT.append(str(o.get("title", "")))
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

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-madres-vista.json"
	Juego.AJUSTES = "user://prueba-madres-vista-aj.json"
	Datos.CAL = true
	Atlas.carga()
	var fotos := ""
	var a := OS.get_cmdline_user_args()
	if a.has("--fotos"):
		fotos = a[a.find("--fotos") + 1]
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	if not J.S.nave.has("ma"):
		J.S.nave.ma = []
	J.S.nave.ma = [{"k": "txoko", "f": null, "v": 100, "e": 0}, {"k": "txoko", "f": null, "v": 30, "e": 3}]
	J.S.esquejes = []
	J.S.min = 10 * 60
	var D: Dictionary = J.D
	# 1 · la vista: la carpa, los dos LED, el temporizador, las madres y el hueco
	var R: Array = J.rects_madres({"i": 0})
	var imgs := R.filter(func(q): return typeof(q[0]) == TYPE_STRING)
	chk(imgs.size() >= 1 + 2 + 2 * 2, "la pared, los LED y dos madres con su maceta: %d imágenes" % imgs.size())
	chk(J.luz_madres(), "a las 10, el LED encendido")
	J.S.min = 3 * 60
	chk(not J.luz_madres() and J.rects_madres({"i": 0}).any(func(q): return typeof(q[0]) != TYPE_STRING and str(q[4]).begins_with("rgba(4,4,10")), "a las 3, sus 6 horas de noche: a oscuras")
	J.S.min = 10 * 60
	chk(J.sitios_madres().size() == int(D.MADRES.max) and J.sitios_madres().all(func(q): return q[0] - 20 >= 0 and q[0] + 20 <= J.SW), "un sitio por madre, dentro de la pantalla")
	var im1 = J._madre_img(J.S.nave.ma[0])
	chk(im1 is Image and im1.get_width() > 0, "la madre, con el dibujo de la vista C")
	chk(J.desc_madres({"i": 1}).contains("3 esquejes") and J.desc_madres({"i": 3}).contains("Hueco libre"), "lo que dice cada sitio")
	# 2 · con los mandos: las flechas eligen, A elige, B cierra
	var fin := {"r": "?"}
	var co := func():
		fin.r = await J.elegir_madres(0)
	co.call()
	M.paso()
	chk(J.MADRES_V != null and int(J.MADRES_V.i) == 0, "abierta, en la primera")
	J.press("right")
	J.press("right")
	J.press("right")
	J.press("right")
	chk(int(J.MADRES_V.i) == int(D.MADRES.max) - 1, "a la derecha, hasta la última (%d)" % int(J.MADRES_V.i))
	J.press("left")
	J.press("A")
	for q in 10:
		M.paso()
	chk(fin.r == int(D.MADRES.max) - 2 and J.MADRES_V == null, "A, la elegida (%s)" % [fin.r])
	co = func():
		fin.r = await J.elegir_madres(1)
	co.call()
	M.paso()
	J.press("B")
	for q in 10:
		M.paso()
	chk(fin.r == null and J.MADRES_V == null, "B cierra")
	if fotos != "":
		J.oraculo = false
		J.enter_map("nave", 15, 4, "up")
		J.mode = "world"
		co = func():
			fin.r = await J.elegir_madres(1)
		co.call()
		for q in 3:
			await process_frame
			J.pintor.redibuja(0.0)
			for r in 4:
				await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(fotos.path_join("madres-dia.png"))
		J.press("B")
		J.S.min = 2 * 60
		co = func():
			fin.r = await J.elegir_madres(3)
		co.call()
		for q in 3:
			await process_frame
			J.pintor.redibuja(0.0)
			for r in 4:
				await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(fotos.path_join("madres-noche.png"))
		J.press("B")
		J.S.min = 10 * 60
		J.oraculo = true
	M.intervalo(func():   # desde aquí, los diálogos se pasan solos
		if J.handlers.size():
			J.press("A"), 12)
	# 3 · cortarle esquejes tú: una vez al día, con la madre fuerte; le cuesta vigor
	var Mm: Dictionary = J.S.nave.ma[0]
	QUIERO = ["Cortarle esquejes"]
	LOG = []
	chk(corre(func(): await J.madre_ops(0)) and J.S.esquejes.size() == 2 and int(Mm.cd) == int(J.S.day) and int(Mm.v) == 95 and dicho("Le cortas"), "le cortas dos esquejes (%d, vigor %d)" % [J.S.esquejes.size(), int(Mm.v)])
	MENUS = []
	QUIERO = []
	corre(func(): await J.madre_ops(0))
	chk(MENUS.size() and not MENUS.back().has("Cortarle esquejes"), "el mismo día, no otra vez: %s" % [MENUS.back() if MENUS.size() else []])
	MENUS = []
	corre(func(): await J.madre_ops(1))
	chk(MENUS.size() and not MENUS.back().has("Cortarle esquejes") and MENUS.back().any(func(l): return str(l).begins_with("Recoger 3")), "la floja (vigor 30), sin cortarle; lo de quien las cuida, se recoge: %s" % [MENUS.back() if MENUS.size() else []])
	QUIERO = ["Recoger"]
	chk(corre(func(): await J.madre_ops(1)) and J.S.esquejes.size() == 5 and int(J.S.nave.ma[1].e) == 0, "recogidos, al propagador")
	J.S.day += 1
	J.S.esquejes = []
	MENUS = []
	QUIERO = []
	corre(func(): await J.madre_ops(0))
	chk(MENUS.size() and MENUS.back().has("Cortarle esquejes"), "al día siguiente, otra vez")
	J.S.esquejes.resize(int(D.MADRES.propagador))
	J.S.esquejes.fill({"sid": "txoko", "f": null, "dia": J.S.day})
	QUIERO = ["Cortarle esquejes"]
	LOG = []
	chk(corre(func(): await J.madre_ops(0)) and J.S.esquejes.size() == int(D.MADRES.propagador) and dicho("propagador está lleno"), "con el propagador lleno, no")
	J.S.esquejes = []
	# 4 · desde la carpa del mapa: la vista (el gancho elige el hueco y luego cierra) y meter una madre en el hueco
	var vistos := []
	J.gancho_madres = func(i0):
		vistos.append(i0)
		return 2 if vistos.size() == 1 else null
	J.S.seeds = {"txoko": 2}
	QUIERO = [J.strain("txoko").n]
	chk(corre(func(): await J.carpa_madres()) and J.S.nave.ma.size() == 3 and vistos.size() == 2, "en el hueco, una madre más (%d · %s)" % [J.S.nave.ma.size(), vistos])
	J.gancho_madres = Callable()
	# 5 · sin CAL, el menú de antes
	Datos.CAL = false
	TIT = []
	QUIERO = ["Volver"]
	chk(corre(func(): await J.carpa_madres()) and TIT.has("LAS MADRES"), "sin CAL, el menú de antes (%s)" % [TIT])
	MENUS = []
	QUIERO = []
	corre(func(): await J.madre_ops(0))
	chk(MENUS.size() and not MENUS.back().has("Cortarle esquejes"), "sin CAL, sin cortarle tú")
	Datos.CAL = true
	print("madres_vista: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
