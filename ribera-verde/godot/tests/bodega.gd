# Ribera Verde (Godot) — la bodega del barco (lo pidió el usuario: «en el maletero caben 20 kg, pero al barco solo puedes llevar 10…
# que tú metas esos 10, puedas salir del menú y volver a meter más»; con CAL): lo cargado se queda en la bodega hasta zarpar,
# se puede sacar y se suma a lo de la vuelta siguiente.
#   $GODOT --headless --path godot --script res://tests/bodega.gd   → «bodega: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const At = preload("res://tests/atrezo.gd")

var J
var M
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
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
	if q == "<B>":
		M.timeout(func(): J.press("B"), 5)
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

func foto(dir: String, k: String) -> void:
	if dir == "":
		return
	J.oraculo = false
	J.toast_box.hide()
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("muelle-%s.png" % k))
	J.oraculo = true

func entra(mapa: String, x: int, y: int, dir := "up") -> void:
	J.enter_map(mapa, x, y, dir)
	J.build_ents()
	J.mode = "world"

func pisa_puerta(x: int, y: int, fx: int, fy: int) -> bool:
	var P = J.P
	P.x = x
	P.y = y
	P.fx = fx
	P.fy = fy
	var d = J.MAPS[J.S.map].doors.get("%d,%d" % [x, y])
	if d == null:
		return false
	return corre(func(): await J.entra_local(d))

func espera(c: Callable) -> bool:
	var t0: float = M.reloj
	while not (c.call() and J.is_free() and J.pending.is_empty()):
		if M.reloj - t0 > 60000 or not M.paso():
			return false
	return true

func lote() -> String:
	return str(J.venta_item(J.bud_lots(1)[0]).label)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-bodega.json"
	Juego.AJUSTES = "user://prueba-bodega-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	S.ch = 8
	S.erase("franco")
	S.banco = 300000
	S.money = 20000
	S.heat = 0
	S.protect = false
	S.buds = {}
	S.mar = {"b": ["txalupa", "pesquero"], "rep": 0, "kg": 0.0, "env": [], "ped": null, "pd": 0, "paso": 0, "fin": 0, "n": 0}
	var sid: String = J.D.STRAINS.keys()[0]
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var R: Dictionary = J.D.MAR
	var B: Dictionary = R.barcos[1]   # el pesquero: 12 kg, más de lo que cabe en la mochila más grande (10 kg)
	entra("muelle", int(B.nor), int(B.y) - 1)
	# 1 · cargas lo que llevas encima y te vas sin zarpar: se queda en la bodega
	J.add_buds(sid, 6000, 24)
	QUIERO = ["Burdeos", lote(), J._kg(5000), "Nada"]
	chk(corre(func(): await J.mar_noray(int(B.nor))) and S.mar.env.is_empty(), "sin zarpar, el barco sigue amarrado")
	chk(J.bodega_g(B.k) == 5000, "los 5 kg se quedan en la bodega (%s)" % J.bodega_g(B.k))
	chk(absf(J.total_buds() - 1000) < .5, "y ya no los llevas encima: te queda 1 kg (%s)" % J.total_buds())
	# 2 · vuelves con más (del maletero, por ejemplo) y lo sumas a lo que ya estaba
	J.add_buds(sid, 5000, 24)
	QUIERO = ["Burdeos", lote(), J._kg(5000), "Nada"]
	chk(corre(func(): await J.mar_noray(int(B.nor))) and J.bodega_g(B.k) == 10000, "se suma a lo cargado: %s" % J.bodega_g(B.k))
	# 3 · sacar de la bodega: vuelve encima, lo que quepa en la mochila
	S.buds = {}
	S.items.bolsa = 2
	var libre: float = floor(J.libre_mochila())
	QUIERO = ["Burdeos", "Descargar", "Nada"]
	chk(corre(func(): await J.mar_noray(int(B.nor))) and absf(J.total_buds() - minf(libre, 10000)) < 1.5, "descargas lo que cabe (%s de %s libres)" % [J.total_buds(), libre])
	chk(absf(J.bodega_g(B.k) + J.total_buds() - 10000) < 1.5, "y no se pierde nada (%s a bordo)" % J.bodega_g(B.k))
	# 4 · tres viajes y zarpa con todo: 12 kg, la bodega entera
	S.buds = {}
	S.mar.bod = {}
	for g in [5000, 5000, 2000]:
		J.add_buds(sid, g, 24)
		QUIERO = ["Burdeos", lote(), J._kg(g), "Nada"]
		corre(func(): await J.mar_noray(int(B.nor)))
	chk(J.bodega_g(B.k) == 12000, "la bodega, llena con los tres viajes (%s)" % J.bodega_g(B.k))
	QUIERO = ["Burdeos", "Zarpar"]
	chk(corre(func(): await J.mar_noray(int(B.nor))) and S.mar.env.size() == 1, "zarpa: %s" % [S.mar.env])
	var en: Dictionary = S.mar.env[0] if S.mar.env.size() else {}
	chk(int(en.get("g", 0)) == 12000, "con los 12 kg (%s)" % en.get("g"))
	chk(J.bodega_g(B.k) == 0, "y la bodega, vacía al salir")
	var esp: int = Datos.jsround(J.precio_mayor(24) * J.calidad({"g": 1, "thc": 24, "dia": S.day}, true) * float(R.rutas[0].px) * 12000)
	chk(absi(int(en.get("e", 0)) - esp) <= 2, "lo que pagan, por todo: %s (%d)" % [en.get("e"), esp])
	# 5 · la txalupa (3 kg) no carga más que su bodega aunque vengas con más
	S.buds = {}
	J.add_buds(sid, 5000, 24)
	QUIERO = ["Burdeos", lote(), J._kg(3000), "Nada"]
	corre(func(): await J.mar_noray(int(R.barcos[0].nor)))
	chk(J.bodega_g("txalupa") <= 3000, "la txalupa, hasta 3 kg (%s)" % J.bodega_g("txalupa"))
	print("bodega: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	quit(1 if fallos.size() else 0)
