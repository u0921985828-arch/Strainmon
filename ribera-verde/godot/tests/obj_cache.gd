# Landrace Hunters (Godot) — R47 (0.78): el sprite de cada objeto se resolvía en cada fotograma (2,9 ms de GDScript en `casco`).
# Ahora se guarda por objeto, casilla, sprite y generación de la rejilla (`_obj_f` + `_cpon` de pinta.gd). La prueba: en todos los
# mapas, de día y de noche, la pantalla con la caché es la misma, píxel a píxel, que resolviéndolo cada vez (OBJ_CACHE = false),
# también después de ordenar un mueble (la rejilla cambia y la caché tiene que rehacerse).
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 1560x720 --script res://tests/obj_cache.gd
#     -- --sin-arranque   → «obj_cache: N comprobaciones, 0 fallos»
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
	for y in a.get_height():
		for x in a.get_width():
			if not a.get_pixel(x, y).is_equal_approx(b.get_pixel(x, y)):
				c += 1
	return c

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-objcache.json"
	Juego.AJUSTES = "user://prueba-objcache-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	J = Juego.new()
	root.add_child(J)
	await process_frame
	J.oraculo = true
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
	var mapas: Array = J.MAPS.keys()
	mapas.sort()
	for mk in mapas:
		var m: Dictionary = J.MAPS[mk]
		var px := clampi(int(m.w) / 2, 0, int(m.w) - 1)
		var py := clampi(int(m.h) / 2, 0, int(m.h) - 1)
		J.enter_map(mk, px, py, "down")
		J.mode = "world"
		J.ents = J.ents.filter(func(e): return not e.get("pat"))
		for hora in [600, 1380]:
			J.S.min = hora
			var t: float = 123456.0 + hora
			J.pintor.OBJ_CACHE = true
			await foto(t)
			var a: Image = await foto(t)
			J.pintor.OBJ_CACHE = false
			var b: Image = await foto(t)
			var d := distintos(a, b)
			chk(d == 0, "%s a las %d: %d píxeles distintos" % [mk, hora / 60, d])
			J.pintor.OBJ_CACHE = true
	# la rejilla cambia (como al ordenar un mueble): la caché no puede dar el sprite de antes
	var casa: Dictionary = J.MAPS["home"]
	J.enter_map("home", 6, 5, "down")
	J.mode = "world"
	var fy := -1
	var fx := -1
	for ty in int(casa.h):
		for tx in int(casa.w):
			if casa.o[ty][tx] == null or casa.o[ty][tx] == "":
				if fy < 0:
					fy = ty
					fx = tx
	await foto(2000.0)
	var antes: Image = await foto(2000.0)
	casa.o[fy][fx] = "table"
	await foto(2000.0)
	var puesto: Image = await foto(2000.0)
	chk(distintos(antes, puesto) > 0, "la mesa puesta en (%d, %d) no cambia la pantalla: la caché no vio la rejilla nueva" % [fx, fy])
	J.pintor.OBJ_CACHE = false
	var sin_c: Image = await foto(2000.0)
	chk(distintos(puesto, sin_c) == 0, "con la mesa nueva, la caché no da lo mismo que resolver cada vez")
	casa.o[fy][fx] = null
	J.pintor.OBJ_CACHE = true
	for f in fallos:
		print("FALLO ", f)
	print("obj_cache: %d comprobaciones, %d fallos (%d mapas)" % [n, fallos.size(), mapas.size()])
	quit(1 if fallos.size() else 0)
