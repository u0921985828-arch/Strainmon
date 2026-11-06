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
# encaje (lo pidió el usuario: «tiene que entrar perfecto el personaje en la puerta»): de pie en la casilla de la puerta, de espaldas
# (quieto, andando y corriendo; él y ella), cada píxel suyo cae dentro del hueco de la abierta (por filas, de lo que cambia entre la
# cerrada y la abierta) o, en las de Bilbao, sobre lo oscuro de la fachada o fuera de ella
const POSES := [["base", 1], ["idle", 4], ["walk", 4], ["run", 6]]

var fallos := 0
var PINTA := ""
# con --pintar <dir>: cada puerta abierta con el protagonista encima (rojo lo que se sale)
func _pinta(nom: String, base: Image, ox: int, oy: int, pim: Image) -> void:
	if PINTA == "":
		return
	var w := Image.create(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8)
	w.fill(Color(.2, .6, .3))
	w.blend_rect(base, Rect2i(Vector2i.ZERO, base.get_size()), Vector2i.ZERO)
	for by in pim.get_height():
		for bx in pim.get_width():
			var c := pim.get_pixel(bx, by)
			var u := ox + bx
			var v := oy + by
			if c.a > .5 and u >= 0 and v >= 0 and u < w.get_width() and v < w.get_height():
				w.set_pixel(u, v, c.lerp(w.get_pixel(u, v), .35))
	w.resize(w.get_width() * 4, w.get_height() * 4, Image.INTERPOLATE_NEAREST)
	w.save_png(PINTA.path_join(nom.replace(" ", "_") + ".png"))
var n := 0

func ok(c: bool, t: String) -> void:
	n += 1
	if not c:
		fallos += 1
		print("FALLO ", t)

func _initialize() -> void:
	Datos.PLAY = false
	var ar := OS.get_cmdline_user_args()
	if ar.has("--pintar"):
		PINTA = ar[ar.find("--pintar") + 1]
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
	var pj0: Image = Atlas.frame_de("player", "base", "south", 0, {"i": 0}).c
	var alto_pj: int = pj0.get_used_rect().size.y
	ok(alto_pj >= 25 and alto_pj <= 30, "el protagonista mide %d px" % alto_pj)
	var pjs: Array = []   # [nombre, Image] de espaldas
	for gr in ["player", "player-f"]:
		for po in POSES:
			for i in po[1]:
				var f = Atlas.frame_de(gr, po[0], "north", 0, {"i": i})
				if f != null:
					pjs.append(["%s %s %d" % [gr, po[0], i], f.c])
	ok(pjs.size() == 30, "fotogramas del protagonista de espaldas: %d" % pjs.size())
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
				# por filas, el tramo que cambia de la cerrada a cualquiera de las otras (la hoja que se abre es del hueco); por debajo del
				# hueco, el suelo (los pies pisan el umbral)
				var fil := {}
				var fs: Array = []
				for i in range(1, 4):
					fs.append(Atlas.frame_de(gp, "puerta", "unica", 0, {"i": i}).c)
				for yy in a.get_height():
					var f0 := 999
					var f1 := -1
					for xx in a.get_width():
						for fi in fs:
							if not a.get_pixel(xx, yy).is_equal_approx(fi.get_pixel(xx, yy)):
								f0 = mini(f0, xx)
								f1 = maxi(f1, xx)
					if f1 >= 0:
						fil[yy] = [f0, f1]
				# de jamba a jamba: lo que cambia en alguna fila (las jambas no se mueven; la hoja que gira, sí, y su canto de las
				# bisagras es del hueco)
				var j0 := 999
				var j1 := -1
				for yy in fil:
					j0 = mini(j0, fil[yy][0])
					j1 = maxi(j1, fil[yy][1])
				for yy in fil:
					fil[yy] = [j0, j1]
				for yy in range(y1 + 1, a.get_height()):
					fil[yy] = [-99, 99]
				var dx: int = int(b.get("dx", 0))
				for cas in ([8] if b.get("ancha") else [0]):   # en las anchas, entra por el medio (_dx_ancha en pinta.gd)
					var peor := ""
					for pj in pjs:
						var im: Image = pj[1]
						var fu := 0
						for by in im.get_height():
							for bx in im.get_width():
								if im.get_pixel(bx, by).a < .5:
									continue
								var u: int = bx - dx + cas
								var v: int = by + 1
								if v >= a.get_height():
									continue
								if not fil.has(v) or u < fil[v][0] or u > fil[v][1]:
									fu += 1
						if fu and peor == "":
							peor = "%s: %d px fuera" % [pj[0], fu]
					ok(peor == "", "%s (casilla %d): el protagonista no entra en el hueco (%s)" % [t, cas / 16, peor])
					_pinta("%s-%d" % [t, cas / 16], o, cas - dx, 1, pjs[0][1])
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
				var c0: int = a0 - 8
				for cas in ([8] if b.get("ancha") else [0]):   # en las anchas, entra por el medio (_dx_ancha en pinta.gd)
					var peor := ""
					for pj in pjs:
						var pim: Image = pj[1]
						var fu := 0
						for by in pim.get_height():
							for bx in pim.get_width():
								if pim.get_pixel(bx, by).a < .5:
									continue
								var u: int = c0 + cas + bx
								var v: int = im.get_height() - 31 + by
								if u < 0 or v < 0 or u >= im.get_width() or v >= im.get_height():
									continue
								var c := im.get_pixel(u, v)
								if c.a > .5 and _lum(c) >= lu:
									fu += 1
						if fu and peor == "":
							peor = "%s: %d px fuera" % [pj[0], fu]
					ok(peor == "", "%s (casilla %d): el protagonista no entra en el hueco (%s)" % [t, cas / 16, peor])
					_pinta("%s-%d" % [t, cas / 16], im, c0 + cas, im.get_height() - 31, pjs[0][1])
	print("puertas_alto: %d comprobaciones, %d fallos" % [n, fallos])
	quit(1 if fallos else 0)
