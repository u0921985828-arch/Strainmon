extends SceneTree
# Las entradas, cuadradas con las baldosas (lo pidió el usuario: «todas las entradas a edificios y demás deberían estar cuadradas con
# las baldosas»): en todos los mapas, cada edificio que se entra tiene su puerta dibujada encima de sus casillas de puerta (doorX, y la
# de al lado si es ancha), centrada con ±2 px. Con la puerta encima (anim «puerta»), lo que cambia entre cerrada y abierta; sin ella
# (Bilbao), el hueco oscuro de la planta baja de la fachada que cae sobre esas casillas, con ±4 px.
const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

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
	var vistas := {}
	for mk in J.MAPS:
		var m: Dictionary = J.MAPS[mk]
		for b in m.get("blds", []):
			if b.get("doorX") == null:
				continue
			var gp: String = "edificio-" + b.get("puerta", b.id)
			var gr: String = "edificio-" + b.get("fachada", b.id)
			var c0: float = int(b.doorX) * 16 + (16.0 if b.get("ancha") else 8.0)   # el centro de las casillas, en px del mapa
			var t := "%s %s (doorX %d)" % [mk, b.get("fachada", b.id), int(b.doorX)]
			if Atlas.anim_de(gp, "puerta"):
				var k := "%s|%s|%s" % [gp, b.get("dx", 0), b.get("ancha", false)]
				if vistas.has(k) and vistas[k] == int(b.doorX) - int(b.x0):
					continue
				vistas[k] = int(b.doorX) - int(b.x0)
				var p0 = Atlas.frame_de(gp, "puerta", "unica", 0, {"i": 0})
				var p1 = Atlas.frame_de(gp, "puerta", "unica", 0, {"i": -1})
				var a: Image = p0.c
				var bi: Image = p1.c
				# la fila de abajo que más cambia al abrirse; la hoja, lo que cambia en ella y, a los lados, lo que sigue de su mismo
				# color en la cerrada (una hoja que se abre hacia un lado deja a la vista solo una parte)
				var fy := -1
				var mejor := 0
				for y in range(a.get_height() / 2, a.get_height()):
					var c := 0
					for x in a.get_width():
						if not a.get_pixel(x, y).is_equal_approx(bi.get_pixel(x, y)):
							c += 1
					if c > mejor:
						mejor = c
						fy = y
				ok(fy >= 0, t + ": la puerta no cambia al abrirse")
				if fy < 0:
					continue
				var xa := 999
				var xb := -1
				for x in a.get_width():
					if not a.get_pixel(x, fy).is_equal_approx(bi.get_pixel(x, fy)):
						xa = mini(xa, x)
						xb = maxi(xb, x)
				while xa > 0 and a.get_pixel(xa - 1, fy).is_equal_approx(a.get_pixel(xa, fy)):
					xa -= 1
				while xb < a.get_width() - 1 and a.get_pixel(xb + 1, fy).is_equal_approx(a.get_pixel(xb, fy)):
					xb += 1
				var org: float = int(b.doorX) * 16 - 8 + int(b.get("dx", 0))
				var cx: float = org + (xa + xb + 1) / 2.0
				ok(absf(cx - c0) <= 2.0, "%s: la hoja (%d..%d px) centrada en %.1f, sus casillas en %.1f" % [t, int(org) + xa, int(org) + xb + 1, cx, c0])
			else:
				var f = Atlas.frame_de(gr, "base", "unica", 0, {"i": 0})
				ok(f != null, t + ": sin fachada")
				if f == null:
					continue
				var im: Image = f.c
				var y: int = im.get_height() - 12
				var a0: int = (int(b.doorX) - int(b.x0)) * 16   # sus casillas, dentro de la fachada
				var a1: int = a0 + (32 if b.get("ancha") else 16)
				var l := 9999
				var r := -1
				var osc := 0
				for x in range(a0 + 4, a1 - 4):   # los huecos oscuros que pisan sus casillas (no solo su canto), enteros aunque se salgan
					if _lum(im.get_pixel(x, y)) >= .45:
						continue
					osc += 1
					var xl := x
					var xr := x
					while xl > 0 and _lum(im.get_pixel(xl - 1, y)) < .45:
						xl -= 1
					while xr < im.get_width() - 1 and _lum(im.get_pixel(xr + 1, y)) < .45:
						xr += 1
					l = mini(l, xl)
					r = maxi(r, xr)
				ok(osc * 2 >= a1 - a0 - 8, "%s: sus casillas (rel %d..%d) no caen en el hueco de la puerta (%d px oscuros)" % [t, a0, a1, osc])
				var cx: float = (l + r + 1) / 2.0
				ok(r >= 0 and absf(cx - (a0 + a1) / 2.0) <= 4.0, "%s: el hueco (rel %d..%d) centrado en %.1f, sus casillas en %.1f" % [t, l, r + 1, cx, (a0 + a1) / 2.0])
	print("puertas_rejilla: %d comprobaciones, %d fallos" % [n, fallos])
	quit(1 if fallos else 0)
