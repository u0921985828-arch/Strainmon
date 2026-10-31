# Landrace Hunters (Godot) — la lluvia y la nieve en un solo dibujo (pinta.gd `_rects_lote`; lo pidió el usuario: «que no vaya petado…
# que vaya lo más fluido posible», en la web): en la calle, con lluvia, tormenta y nieve, de día y de noche y en varios momentos, la
# pantalla con las gotas en un lote es la misma, píxel a píxel, que pintándolas una a una (LOTE_ON = false).
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1560x720 --script res://tests/lluvia_lote.gd
#     -- --sin-arranque   → «lluvia_lote: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func foto(t: float) -> Image:
	for q in 2:
		J.pintor.redibuja(t)
		await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func distintos(a: Image, b: Image) -> int:
	var c := 0
	for y in range(0, a.get_height(), 1):
		for x in range(0, a.get_width(), 1):
			if not a.get_pixel(x, y).is_equal_approx(b.get_pixel(x, y)):
				c += 1
	return c

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-lluvia.json"
	Juego.AJUSTES = "user://prueba-lluvia-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.oraculo = true   # sin _process: cada fotograma lo pinta la prueba, con el mismo reloj
	J.pintor.ambiente_on = false
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	for x in O:
		if x.k == "nave2":
			J.S = Datos.enteros(x).S.duplicate(true)
	var ns: Dictionary = J.new_state()
	for k in ns:
		if not J.S.has(k):
			J.S[k] = ns[k]
	J.migrate()
	J.queued.clear()
	J.pending.clear()
	J.ajusta()
	for mk in ["town", "abando", "muelle"]:
		var m: Dictionary = J.MAPS[mk]
		J.enter_map(mk, int(m.w) / 2, int(m.h) / 2, "down")
		J.mode = "world"
		J.ents = J.ents.filter(func(e): return not e.get("pat"))
		for k in ["lluvia", "tormenta", "nieve"]:
			var d := -1
			for x in range(1, 3000):
				if Datos.tiempo(x, 720).k == k and Datos.tiempo(x, 1380).k == k:
					d = x
					break
			chk(d > 0, "%s: sin día de %s" % [mk, k])
			if d < 0:
				continue
			J.S.day = d
			for hora in [720, 1380]:
				J.S.min = hora
				for t in [1000.0, 98765.0]:
					J.pintor.LOTE_ON = true
					var a: Image = await foto(t)
					J.pintor.LOTE_ON = false
					var b: Image = await foto(t)
					var dd := distintos(a, b)
					chk(dd == 0, "%s %s a las %d (%d): %d píxeles distintos" % [mk, k, hora / 60, t, dd])
	J.pintor.LOTE_ON = true
	for f in fallos:
		print("FALLO ", f)
	print("lluvia_lote: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
