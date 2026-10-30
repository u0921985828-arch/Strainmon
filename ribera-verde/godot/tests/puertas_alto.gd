extends SceneTree
# Las puertas, a la medida del protagonista (lo pidió el usuario: «la puerta es demasiado pequeña para el personaje»): en todos los
# mapas, cada puerta de la calle que llega al suelo (anim «puerta» de su edificio) deja, abierta, un hueco más alto que el protagonista
# (su sprite de frente, de los pies a la gorra, + 1 px) y de al menos HUECO_W px de ancho. Las de Bilbao, sin anim, también (su hueco
# oscuro de la fachada, en las columnas de sus casillas).
#   $GODOT --headless --path godot --script res://tests/puertas_alto.gd   → «puertas_alto: N comprobaciones, 0 fallos»
const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")
const HUECO_W := 10
const PERSIANA := {"molino": .6}   # el portón del molino es de persiana metálica gris, más clara que un hueco

var fallos := 0
var n := 0

func ok(c: bool, t: String) -> void:
	n += 1
	if not c:
		fallos += 1
		print("FALLO ", t)

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func _lum(c: Color) -> float:
	return .299 * c.r + .587 * c.g + .114 * c.b

func _corre() -> void:
	Juego.GUARDADO = "user://p.json"
	Juego.AJUSTES = "user://pa.json"
	Datos.CAL = true
	Atlas.carga()
	var J = Juego.new()
	root.add_child(J)
	await process_frame
	var pj: Image = Atlas.frame_de("player", "base", "south", 0, {"i": 0}).c
	var alto_pj: int = pj.get_used_rect().size.y
	ok(alto_pj >= 25 and alto_pj <= 30, "el protagonista mide %d px" % alto_pj)
	var vistas := {}
	for mk in J.MAPS:
		for b in J.MAPS[mk].get("blds", []):
			if b.get("doorX") == null:
				continue
			var gp: String = "edificio-" + b.get("puerta", b.id)
			var t := "%s %s" % [mk, b.get("fachada", b.id)]
			if Atlas.anim_de(gp, "puerta"):
				if vistas.has(gp):
					continue
				vistas[gp] = true
				var a: Image = Atlas.frame_de(gp, "puerta", "unica", 0, {"i": 0}).c
				var o: Image = Atlas.frame_de(gp, "puerta", "unica", 0, {"i": -1}).c
				var y0 := 999
				var y1 := -1
				var x0 := 999
				var x1 := -1
				for y in a.get_height():
					for x in a.get_width():
						if not a.get_pixel(x, y).is_equal_approx(o.get_pixel(x, y)):
							y0 = mini(y0, y)
							y1 = maxi(y1, y)
							x0 = mini(x0, x)
							x1 = maxi(x1, x)
				if y1 < a.get_height() - 2:
					continue   # no llega al suelo (el escaparate del concesionario)
				ok(y1 - y0 + 1 > alto_pj, "%s: hueco de %d px de alto, el protagonista %d" % [t, y1 - y0 + 1, alto_pj])
				ok(x1 - x0 + 1 >= HUECO_W, "%s: hueco de %d px de ancho" % [t, x1 - x0 + 1])
			else:
				var f = Atlas.frame_de("edificio-" + b.get("fachada", b.id), "base", "unica", 0, {"i": 0})
				if f == null:
					continue
				var im: Image = f.c
				# lo oscuro seguido más alto en las columnas de sus casillas (una junta clara en medio no corta el hueco)
				var a0: int = (int(b.doorX) - int(b.x0)) * 16
				var y: int = im.get_height() - 12
				var h := 0
				var lu: float = PERSIANA.get(b.get("fachada", b.id), .45)
				for cx in range(a0 + 3, a0 + (32 if b.get("ancha") else 16) - 3):
					var hc := 0
					while y - hc >= 0 and _lum(im.get_pixel(cx, y - hc)) < lu:
						hc += 1
					h = maxi(h, hc)
				ok(h + 12 > alto_pj, "%s: hueco de la fachada de %d px de alto, el protagonista %d" % [t, h + 12, alto_pj])
	print("puertas_alto: %d comprobaciones, %d fallos" % [n, fallos])
	quit(1 if fallos else 0)
