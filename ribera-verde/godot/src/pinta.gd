# Ribera Verde (Godot) — 14-render y lo que dibuja 01b-arte: el lienzo de SW × 160 según el modo, como render(now) del HTML.
# Mundo (renderWorld: casillas, orillas, objetos, edificios, carpas del piso, personajes con su sombra, objetos del suelo, palomas y
# gaviotas, efectos, bocadillos, la tarde, la noche y las farolas), combate (renderBattle), título e intro (renderTitle) y la
# carpa: la vista B (renderCarpa: el cuarto, la carpa en 3/4, extras, el cono de luz, macetas y plantas, el foco, barras y
# cursor) o, si hay arte para todo, la vista C (vista.gd). En otro modo no se pinta nada y se queda el último fotograma.
# Capas (hijos, en este orden): c0 lo de siempre · ad con mezcla aditiva (las farolas o el cono del foco: 'lighter') · vc la vista C
# · c1 lo que va encima en la carpa (plantas, foco, barras, cursor y efectos de la vista B; efectos de la C).
# Lo que el canvas pinta con antialias (rectángulos en medio píxel, la elipse de la intro, el cono, las líneas del agua del título,
# los sitios libres) se pinta píxel a píxel con su cobertura exacta.
extends Node2D

const Datos = preload("res://src/datos.gd")
const Atlas = preload("res://src/atlas.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Procedural = preload("res://src/procedural.gd")
const Vista = preload("res://src/vista.gd")

const SH := 160
const DIR4 := {"down": "south", "up": "north", "left": "west", "right": "east"}
const TRANS := {"water": "agua", "dirt": "tierra", "plaza": "plaza", "pista": "tierra"}
const HIERBA := ["grass", "flowers", "tallgrass"]
const FUMA := ["fum", "puro", "pipa", "vap"]

var J = null
var c0 := Node2D.new()
var ad := Node2D.new()
var vc = Vista.new()
var c1 := Node2D.new()
var now := 0.0
var modo := ""
var cam := Vector2i.ZERO
var g := {}                  # geometría de la carpa abierta (vista B)
var ambiente_on := true      # las pruebas de pantalla lo apagan (el HTML tira de Math.random)
var L: CanvasItem            # la capa en la que se pinta
var cache := {}

func _init() -> void:
	for n in [c0, ad, vc, c1]:
		add_child(n)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ad.material = m
	c0.draw.connect(func(): _capa(c0, 0))
	ad.draw.connect(func(): _capa(ad, 1))
	c1.draw.connect(func(): _capa(c1, 2))
	vc.visible = false

# render(now): mundo, combate, carpa (B o C) o título; en otro modo, nada
func redibuja(t: float) -> void:
	if J == null:
		return
	var m: String = J.mode
	if m == "world" and J.S:
		modo = "world"
	elif m == "battle" and J.B:
		modo = "battle"
	elif m == "carpa" and J.VC:
		modo = "carpa"
	elif m == "title" or m == "intro":
		modo = "title"
	else:
		return
	now = t
	vc.visible = false
	if modo == "carpa":
		g = Vista.geo(J.S, J.VC.ci)
		if g.vc:
			modo = "carpaC"
			vc.visible = true
			vc.pinta(J.S, J.VC, now, J.SW)
	elif modo == "world":
		cam = camara()
	c0.queue_redraw()
	ad.queue_redraw()
	c1.queue_redraw()

func _capa(ci: CanvasItem, n: int) -> void:
	L = ci
	if modo == "world":
		[_mundo, _farolas, func(): pass][n].call()
	elif modo == "battle":
		if n == 0:
			_combate()
	elif modo == "title":
		if n == 0:
			_titulo()
	elif modo == "carpa":
		[_carpa_fondo, _cono, _carpa_encima][n].call()
	elif modo == "carpaC" and n == 2:
		L.draw_set_transform(Vector2(OX(), 0))
		_vfx({"x": 0, "y": 0}, "home")
	L.draw_set_transform(Vector2.ZERO)

# ---------- utilidades de dibujo ----------
func OX() -> int:
	return (J.SW - 240) >> 1

static func css(s: String) -> Color:
	if s.begins_with("#"):
		return Procedural.col(s)
	var n := s.substr(s.find("(") + 1).replace(")", "").split(",")
	return Color8(int(n[0]), int(n[1]), int(n[2]), Datos.jsround(float(n[3]) * 255) if n.size() > 3 else 255)

func _img(im: Image, x: float, y: float, mod := Color.WHITE) -> void:
	L.draw_texture(Atlas.tex(im), Vector2(x, y), mod)

func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	if w > 0 and h > 0:
		L.draw_rect(Rect2(x, y, w, h), c)

func _pinta(f, xP: float, yP: float) -> void:
	_img(f.c, Datos.jsround(xP - f.cel.ancla[0]), Datos.jsround(yP - f.cel.ancla[1]))

func _dibujar(gr, s: String, dir: String, t: float, xP: float, yP: float, o := {}):
	var f = Atlas.frame_de(gr, s, dir, t, o)
	if f:
		_pinta(f, xP, yP)
	return f

# cobertura de un píxel (x, y) por una lista de cajas (unión), con 4 × 4 muestras: exacta en medios píxeles
static func _cubre(cajas: Array, x: int, y: int) -> float:
	var n := 0
	for j in 4:
		var sy := y + (j + .5) / 4
		for i in 4:
			var sx := x + (i + .5) / 4
			for b in cajas:
				if sx >= b[0] and sx < b[2] and sy >= b[1] and sy < b[3]:
					n += 1
					break
	return n / 16.0

# fondoAncho: la escena de 240 centrada; las bandas de los lados, con el reflejo de los bordes (o la copia, con cortes)
func _fondo_ancho(img: Image, cortes = null) -> void:
	var ox := OX()
	if not ox:
		_img(img, 0, 0)
		return
	var key := "fa|%d|%d|%s" % [img.get_instance_id(), J.SW, str(cortes)]
	if not cache.has(key):
		var o := Image.create(J.SW, SH, false, Image.FORMAT_RGBA8)
		o.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(ox, 0))
		var esp := img.duplicate()
		esp.flip_x()
		for c in (cortes if cortes else [[0, 160, ""]]):
			var y0: int = c[0]
			var h: int = int(c[1]) - y0
			var lado: String = c[2]
			if lado != "dch":   # izquierda: las ox columnas de la izquierda, al revés
				o.blit_rect(esp, Rect2i(240 - ox, y0, ox, h), Vector2i(0, y0))
			if lado != "izq":   # derecha: las de la derecha, al revés
				o.blit_rect(esp, Rect2i(0, y0, ox, h), Vector2i(J.SW - ox, y0))
			if lado == "dch":
				o.blit_rect(img, Rect2i(240 - ox, y0, ox, h), Vector2i(0, y0))
			if lado == "izq":
				o.blit_rect(img, Rect2i(0, y0, ox, h), Vector2i(240 + ox, y0))
		cache[key] = o
	_img(cache[key], 0, 0)

# ---------- mundo ----------
func camara() -> Vector2i:
	var m: Dictionary = J.MAPS[J.S.map]
	var cx: float = J.P.px + 8 - J.SW / 2.0
	var cy: float = J.P.py + 8 - SH / 2.0
	var mw: int = m.w * 16
	var mh: int = m.h * 16
	cx = (mw - J.SW) / 2.0 if mw <= J.SW else clampf(cx, 0, mw - J.SW)
	cy = (mh - SH) / 2.0 if mh <= SH else clampf(cy, 0, mh - SH)
	return Vector2i(Datos.jsround(cx), Datos.jsround(cy))

func story_mark(id: String) -> bool:
	var S: Dictionary = J.S
	var F: Dictionary = S.flags
	match id:
		"kiko": return not F.get("kiko1") or (S.ch == 4 and not F.get("lab"))
		"baltasar": return (S.ch == 3 and not F.get("metB")) or (S.due > 0 and S.money >= S.due) or (S.ch >= 8 and not S.get("encargo") and not (S.get("encVeto", 0) > S.day))
		"tono2": return J.is_night()
		"jurado": return true
		"molina": return not F.get("molina1") or not S.protect
		"darko": return S.ch < 6
		"txaro": return (S.ch >= 2 and not F.get("txaro")) or (S.ch >= 4 and not F.get("txaro2"))
		"inaki": return not F.get("inaki")
	return false

func _mundo() -> void:
	var S: Dictionary = J.S
	var P: Dictionary = J.P
	var m: Dictionary = J.MAPS[S.map]
	_rect(0, 0, J.SW, SH, Color.BLACK)
	var tx0 := floori(cam.x / 16.0)
	var ty0 := floori(cam.y / 16.0)
	var list := []
	# hasta 6 filas por debajo y 2 casillas a cada lado de la pantalla (1.10, 14-render.js): los objetos altos (el árbol, de 6
	# filas; el monte, 3 de ancho) se ven aunque su pie esté fuera
	for ty in range(ty0, ty0 + SH / 16 + 7):
		for tx in range(tx0 - 2, tx0 + ceili(J.SW / 16.0) + 3):
			if tx < 0 or ty < 0 or tx >= m.w or ty >= m.h:
				continue
			var sx: int = tx * 16 - cam.x
			var sy: int = ty * 16 - cam.y
			var k: String = m.g[ty][tx]
			if _arte_tile(k, tx, ty, sx, sy):
				_arte_orilla(m, k, tx, ty, sx, sy)
			var o = m.o[ty][tx]
			if o and o != "carpa":
				_arte_obj(o, tx, ty, list)
	_arte_edificios(m)
	if S.map == "home":
		for t in m.get("carpas", []):
			list.append([t.y * 16, _carpa_mapa.bind(t)])
		for ci in J.D.SITIOS.size():
			if J.sitio_visible(ci):
				_sitio(J.D.SITIOS[ci])
		if not S.flags.get("letter"):
			var lx: int = 3 * 16 - cam.x
			var ly: int = 5 * 16 - cam.y
			_rect(lx + 5, ly + 5, 7, 5, css("#fafaf2"))
			_rect(lx + 8, ly + 7, 2, 1, css("#c04040"))
	if Atlas.ok and ambiente_on:
		for e in J.ents:
			_ambiente(e)
	for e in J.ents:
		list.append([e.py, _pj.bind(e, e.look, false, 320.0)])
	list.append([P.py, _pj.bind(P, J.D.LOOKS.player, true, P.dur)])
	var bolsa = Atlas.foto_misc("bolsa")
	if bolsa:
		for it in J.D.ITEMS:
			if not it.hidden and it.map == S.map and not S.taken.get(it.id):
				list.append([it.y * 16, _pinta.bind(bolsa, it.x * 16 - cam.x + 8, it.y * 16 - cam.y + 8)])
	_criaturas(list)
	for i in list.size():
		list[i].append(i)
	list.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[2] < b[2]))
	for o in list:
		o[1].call()
	if Atlas.ok:
		_vfx(cam, S.map)
	var bob := floori(now / 400) % 2
	for e in J.ents:
		var bx: int = Datos.jsround(e.px - cam.x) + 4
		var by: int = Datos.jsround(e.py - cam.y) - 16 + bob
		if e.def.get("client"):
			_bocadillo(bx, by, "$", css("#2a9a4a"))
		elif story_mark(e.id):
			_bocadillo(bx, by, "!", css("#e03030"))
	if J.D.ZONAS.has(S.map):
		var h: float = S.min / 60.0
		if h >= 17.5 and h < 20.5:
			_rect(0, 0, J.SW, SH, Color8(255, 130, 50, Datos.jsround(.13 * sin((h - 17.5) / 3 * PI) * 255)))
		var a := noche()
		if a > 0:
			_rect(0, 0, J.SW, SH, Color8(14, 20, 72, Datos.jsround(a * 255)))

func noche() -> float:
	var h: float = J.S.min / 60.0
	return .5 if h >= 21 or h < 5 else ((h - 19) / 2 * .5 if h >= 19 else ((7 - h) / 2 * .5 if h < 7 else 0.0))

# las farolas con la noche cerrada: un degradado radial (r 1 → 28) sumado a lo que hay ('lighter')
func _farolas() -> void:
	if not J.D.ZONAS.has(J.S.map):   # farolas de cada zona de fuera (1.10)
		return
	var a := noche()
	if a <= .2:
		return
	var im := _farola(a)
	for l in J.D.LAMPS[J.S.map]:
		var x: int = l[0] * 16 + 8 - cam.x
		var y: int = l[1] * 16 + 2 - cam.y
		if x < -30 or y < -30 or x > J.SW + 30 or y > SH + 30:
			continue
		_img(im, x - 30, y - 22)

func _farola(a: float) -> Image:
	var key := "far|%f" % a
	if cache.has(key):
		return cache[key]
	var im := Image.create(60, 60, false, Image.FORMAT_RGBA8)
	for y in 60:
		for x in 60:
			var d := Vector2(x + .5 - 30, y + .5 - 30).length()   # el centro, en (x, y + 8) de la farola: (30, 30) del recuadro
			var t := clampf((d - 1) / 27.0, 0, 1)
			var al := a * .7 * (1 - t)
			im.set_pixel(x, y, Color8(Datos.jsround(255 * al), Datos.jsround(214 * al), Datos.jsround(120 * al), 255))
	cache[key] = im
	return im

func _arte_tile(k: String, tx: int, ty: int, sx: int, sy: int) -> bool:
	if not Atlas.ok:
		return false
	var an = Atlas.sobre.get("tile:" + k)
	if an:
		var a = Atlas.anim_de(an[0][0], an[0][1])
		var pis: bool = not a.get("bucle")
		if not pis or (J.P.x == tx and J.P.y == ty):
			var pt: float = J.P.get("pisT", 0.0)
			var f = Atlas.frame_de(an[0][0], an[0][1], "unica", (now - (pt if pt else now)) if pis else now, {"bucle": not pis})
			if f:
				if f.c.get_width() >= 32:
					L.draw_texture_rect_region(Atlas.tex(f.c), Rect2(sx, sy, 16, 16), Rect2((tx & 1) * 16, (ty & 1) * 16, 16, 16))
				else:
					_img(f.c, sx, sy)
				return true
	var f = Atlas.frame_de(Atlas.cubre("tile:" + k), k, "unica", 0, {"i": 0})
	if f == null:
		return false
	if f.c.get_width() > 16 and f.c.get_height() == 16:   # tira de variantes (orgánico)
		L.draw_texture_rect_region(Atlas.tex(f.c), Rect2(sx, sy, 16, 16), Rect2(variante(k, tx, ty) * 16, 0, 16, 16))
		return true
	L.draw_texture_rect(Atlas.tex(f.c), Rect2(sx, sy, 16, 16), false)
	if k == "grass":
		_detalle(tx, ty, sx, sy)
	return true

# orgánico (1.10, 01b-arte.js): el mismo hash de casilla que el HTML (hashT) para que nada vaya a compás de la rejilla: qué
# variante de un firme sale (la 0, la lisa, la que más), qué detalle lleva la hierba y dónde, y cuánto se corre (y si va en
# espejo) cada árbol y cada monte
static func hash_t(x: int, y: int) -> int:
	var a := (x * 1103 + y * 2459 + x * y * 31) % 9973
	return (a * a + x * 7 + y * 3) % 9973

const TIRADAS := {"hormigon": 8, "pista": 8, "rotoT": 6, "rotoB": 6}
static func variante(k: String, tx: int, ty: int) -> int:
	var v: int = (hash_t(tx, ty) >> 2) % int(TIRADAS.get(k, 4))
	return v if v < 4 else 0

# en 1 de cada 4 casillas de hierba, uno de los 5 detalles (8 × 8) en cualquier sitio de la casilla
func _detalle(tx: int, ty: int, sx: int, sy: int) -> void:
	if J.P.x == tx and J.P.y == ty:
		return
	var h := hash_t(tx, ty)
	if h % 4:
		return
	var f = Atlas.frame_de(Atlas.cubre("misc:detalles"), "detalles", "unica", 0, {"i": 0})
	if f == null:
		return
	L.draw_texture_rect_region(Atlas.tex(f.c), Rect2(sx + (h / 7) % 9, sy + (h / 11) % 9, 8, 8), Rect2((h / 3) % 5 * 8, 0, 8, 8))

const DESF := {"tree": [6, 3], "tree2": [6, 3], "manzano": [5, 3], "monte": [4, 2], "monte2": [4, 2]}
static func desfase(o: String, x: int, y: int) -> Dictionary:
	var r = DESF.get(o)
	if r == null:
		return {"dx": 0, "dy": 0, "esp": 0}
	var h := hash_t(x, y)
	var n: int = 2 * r[0] + 1
	return {"dx": h % n - r[0], "dy": (h / n) % (2 * r[1] + 1) - r[1], "esp": (h / 97) % 2}

func _mascara(m: Dictionary, tx: int, ty: int) -> int:
	var H := func(x: int, y: int) -> bool: return x >= 0 and y >= 0 and x < m.w and y < m.h and HIERBA.has(m.g[y][x])
	var n: bool = H.call(tx, ty - 1)
	var s: bool = H.call(tx, ty + 1)
	var w: bool = H.call(tx - 1, ty)
	var e: bool = H.call(tx + 1, ty)
	return int(w or n or H.call(tx - 1, ty - 1)) | int(e or n or H.call(tx + 1, ty - 1)) << 1 | int(w or s or H.call(tx - 1, ty + 1)) << 2 | int(e or s or H.call(tx + 1, ty + 1)) << 3

func _arte_orilla(m: Dictionary, k: String, tx: int, ty: int, sx: int, sy: int) -> void:
	if not TRANS.has(k) or not Atlas.ok:
		return
	var mk := _mascara(m, tx, ty)
	if not mk or mk == 15:
		return
	var f = Atlas.frame_de("tileset-transiciones", TRANS[k] + "-%02d" % mk, "unica", 0, {"i": 0})
	if f:
		L.draw_texture_rect(Atlas.tex(f.c), Rect2(sx, sy, 16, 16), false)

# los de la pared, subidos a su altura (1.10, ALZA de 01b-arte.js: px)
const ALZA := {"iwin": -13, "poster": -13, "shelfW": -16, "bottles": -13}

func _arte_obj(o: String, tx: int, ty: int, list: Array) -> void:
	var gr = Atlas.cubre("obj:" + o)
	if not gr:
		return
	var an = Atlas.sobre.get("obj:" + o)
	var d := desfase(o, tx, ty)
	var f = Atlas.frame_de(an[0][0], an[0][1], "unica", now, {"bucle": true}) if an else Atlas.frame_de(gr, o, "unica", 0, {"i": 0, "esp": d.esp})
	if f == null:
		return
	var xp: int = tx * 16 + 8 + d.dx - cam.x
	var yp: int = ty * 16 + 15 + d.dy + int(ALZA.get(o, 0)) - cam.y
	if f.cel.h > 16:
		list.append([ty * 16 + mini(0, d.dy), _pinta.bind(f, xp, yp)])   # corrido hacia abajo, no pasa delante de quien está en su fila
	else:
		_pinta(f, xp, yp)

func _arte_edificios(m: Dictionary) -> void:
	if not Atlas.ok:
		return
	for b in m.get("blds", []):
		var gr: String = "edificio-" + b.get("fachada", b.id)
		var f = Atlas.frame_de(gr, "base", "unica", 0, {"i": 0})
		if f == null:
			continue
		_img(f.c, b.x0 * 16 - cam.x, b.y0 * 16 - cam.y)
		var gp: String = "edificio-" + b.get("puerta", b.id)
		if b.get("doorX") != null and Atlas.anim_de(gp, "puerta"):
			var dy: int = b.y0 + b.h - 1
			var abierta: bool = J.P.x >= b.doorX and J.P.x <= b.doorX + (1 if b.get("ancha") else 0) and (J.P.y == dy or J.P.y == dy + 1)
			var p = Atlas.frame_de(gp, "puerta", "unica", 0, {"i": -1 if abierta else 0})
			if p:
				_img(_sin_pared(p.c, "%s|%d" % [gp, p.i]) if b.get("mascara") else p.c, b.doorX * 16 - 8 + b.get("dx", 0) - cam.x, (dy + 1) * 16 - 32 - cam.y)

# edificios grises con puerta (1.10): su fachada (b.fachada, con hueco para la puerta), la puerta de otra (b.puerta) y, con b.mascara,
# sin su trozo de pared (PARED: los colores de la fachada del piso, quitados desde el borde del fotograma hacia dentro mientras sigan siendo pared; puertaSinPared)
const PARED := {"248,248,240": 1, "246,232,200": 1, "224,206,170": 1, "220,214,198": 1}
var _sin_pared_c := {}
func _sin_pared(c: Image, k: String) -> Image:
	if _sin_pared_c.has(k):
		return _sin_pared_c[k]
	var w := c.get_width()
	var h := c.get_height()
	var d: Image = c.duplicate()
	d.convert(Image.FORMAT_RGBA8)
	var st := []
	for i in w:
		st.append(i)
		st.append((h - 1) * w + i)
	for j in h:
		st.append(j * w)
		st.append(j * w + w - 1)
	while not st.is_empty():
		var i: int = st.pop_back()
		var xi := i % w
		var yi := i / w
		var px := d.get_pixel(xi, yi)
		if px.a8 == 0 or not PARED.has("%d,%d,%d" % [px.r8, px.g8, px.b8]):
			continue
		d.set_pixel(xi, yi, Color(px.r, px.g, px.b, 0))
		if xi > 0:
			st.append(i - 1)
		if xi < w - 1:
			st.append(i + 1)
		if yi > 0:
			st.append(i - w)
		if yi < h - 1:
			st.append(i + w)
	_sin_pared_c[k] = d
	return d

# la carpa del piso, entera desde su base (sprite del atlas o la procedural); con plantas, la luz se escapa bajo la puerta
func _carpa_mapa(t: Dictionary) -> void:
	var xc: int = (t.x0 + t.x1 + 1) * 8 - cam.x
	var yb: int = t.y * 16 + 15 - cam.y
	var f = Atlas.foto_misc("carpa-" + t.t + "-mapa")
	if f:
		_pinta(f, xc, yb)
	else:
		var c := Procedural.carpa_mapa(t.t)
		_img(c, xc - (c.get_width() >> 1), yb - c.get_height() + 1)
	if J.plantas_vivas(t.ci):
		var tipo: String = J.D.FOCOS[J.S.carpas[t.ci].foco].tipo
		_rect(xc - 3, yb + 1, 6, 1, css(J.D.FOCO_LUZ[tipo] + ".6)"))

# el sitio libre: rectángulo de trazos [3, 2] en medio píxel (strokeRect con antialias), rgba(60,70,90,.45). El canvas pinta cada
# trazo por separado (en una esquina donde acaba uno y empieza otro, los dos se mezclan uno encima del otro): cada trazo, su
# cobertura exacta (medios píxeles), con ingletes en las esquinas de dentro
func _sitio(st: Dictionary) -> void:
	var w: float = st.w * 16 - 3
	var key := "sit|%d" % w
	if not cache.has(key):
		var h := 15.0
		var pts := [Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h), Vector2(0, 0)]
		var lon := 2 * (w + h)
		var trazos := []
		var s := 0.0
		while s < lon:
			var cajas := []
			_trazo(pts, s, minf(s + 3, lon), cajas)
			var o := {}
			for b in cajas:
				for yy in range(floori(b[1]), ceili(b[3])):
					for xx in range(floori(b[0]), ceili(b[2])):
						var c := _cubre(cajas, xx, yy)
						if c > 0:
							o[Vector2i(xx + 1, yy)] = c
			trazos.append(o)
			s += 5
		cache[key] = trazos
	var col := Color8(60, 70, 90)
	var a := Datos.jsround(.45 * 255) / 255.0
	var x0: int = st.x * 16 - cam.x
	var y0: int = st.y * 16 - cam.y
	for o in cache[key]:
		for p in o:
			_rect(x0 + p.x, y0 + p.y, 1, 1, Color(col, a * o[p]))

# una máscara del canvas ({w, h, a: alfas}) → {Vector2i: 0-1}
static func _mascara_a(mk: Dictionary) -> Dictionary:
	var o := {}
	for y in int(mk.h):
		for x in int(mk.w):
			var v: int = mk.a[y * int(mk.w) + x]
			if v:
				o[Vector2i(x, y)] = v / 255.0
	return o

# un trazo del contorno entre las longitudes s0 y s1: cada tramo recto, de 1 px de grueso; en las esquinas de dentro, ingletes
# (el tramo se alarga medio píxel). Coordenadas desde la esquina del rectángulo, desplazadas medio píxel (el centro de la línea)
static func _trazo(pts: Array, s0: float, s1: float, cajas: Array) -> void:
	var acc := 0.0
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var l := a.distance_to(b)
		var t0 := maxf(s0, acc)
		var t1 := minf(s1, acc + l)
		if t1 > t0:
			var d := (b - a) / l
			var p0 := a + d * (t0 - acc)
			var p1 := a + d * (t1 - acc)
			if t0 > s0:
				p0 -= d * .5
			if t1 < s1:
				p1 += d * .5
			cajas.append([minf(p0.x, p1.x) - (.5 if d.x == 0 else 0.0) + .5, minf(p0.y, p1.y) - (.5 if d.y == 0 else 0.0) + .5,
				maxf(p0.x, p1.x) + (.5 if d.x == 0 else 0.0) + .5, maxf(p0.y, p1.y) + (.5 if d.y == 0 else 0.0) + .5])
		acc += l

# personajes: el fotograma (acción, andar, idle o base), con la sombra; las acciones de fumar sueltan su humo
func _pj(e: Dictionary, look, isP: bool, dur: float) -> void:
	var gr = Atlas.grupo_look(look)
	if not gr:
		return
	var f = _pj_frame(e, gr, isP, dur)
	if f == null:
		return
	var xp: int = Datos.jsround(e.px - cam.x) + 8
	var yp: int = Datos.jsround(e.py - cam.y) + 15
	var sm := Color8(0, 0, 0, 56)
	_rect(xp - 4, yp - 1, 8, 3, sm)
	_rect(xp - 5, yp, 10, 1, sm)
	_pinta(f, xp, yp)
	var a = e.get("act")
	if a and a.get("humo") and not a.get("humoHecho") and f.i >= a.humo.frame:
		a.humoHecho = 1
		J.lanzar_vfx(a.humo.vfx, e.px + 8 + a.humo.off[0], e.py + 15 + a.humo.off[1], now, J.S.map, true)

func _pj_frame(e: Dictionary, gr, isP: bool, dur: float):
	var dir: String = DIR4[e.dir]
	if e.get("act") and not isP and e.moving:
		e.act = null
	if e.get("act"):
		var t: float = now - e.act.t0
		var f = Atlas.frame_de(gr, e.act.n, dir, t)
		if f and t < Atlas.duracion(gr, e.act.n):
			return f
		e.act = null
	if e.moving:
		var s = "run" if isP and dur < 200 and Atlas.anim_de(gr, "run") else ("walk" if Atlas.anim_de(gr, "walk") else null)
		if s:
			var par: int = e.parity if isP else (int(e.x) + int(e.y)) & 1
			return Atlas.frame_de(gr, s, dir, 0, {"ph": (par + minf(1, e.t / dur)) / 2})
	if Atlas.tiene_dir(gr, "idle", dir):
		return Atlas.frame_de(gr, "idle", dir, now + Datos.hash_str(str(e.get("id", "p"))) % 5000, {"bucle": true})
	return Atlas.frame_de(gr, "base", dir, 0, {"i": 0})

# ambiente: solo quieto, en pantalla y sin diálogo; al hablarle se corta (el azar es aparte: no toca el del juego)
func _ambiente(e: Dictionary) -> void:
	var gr = Atlas.grupo_look(e.look)
	if not gr:
		return
	var am = Atlas.d.get("ambiente", {}).get(gr)
	if not am:
		return
	var dt := func() -> float: return (am.cada_s[0] + randf() * (am.cada_s[1] - am.cada_s[0])) * 1000
	if not e.has("amb"):
		e.amb = now + dt.call()
	if not J.is_free():
		if e.get("act"):
			e.act = null
			e.amb = now + dt.call()
		return
	var sx: float = e.px - cam.x
	var sy: float = e.py - cam.y
	if e.get("act") or e.moving or sx < -16 or sy < -16 or sx > J.SW or sy > SH or now < e.amb:
		return
	e.amb = now + dt.call()
	var menor: bool = Atlas.d.get("menores", []).has(gr)
	var ops := []
	for n in am.acciones:
		if Atlas.anim_de(gr, n) and not (menor and _fuma(n)):
			ops.append(n)
	if ops.is_empty():
		return
	var n: String = ops[randi() % ops.size()]
	var fu = null if menor else Atlas.d.get("fumador", {}).get(gr)
	e.act = {"n": n, "t0": now}
	if fu and _fuma(n):
		e.act.humo = {"vfx": fu.vfx, "frame": fu.frame_humo, "off": fu.offset_boca}

static func _fuma(n: String) -> bool:
	for k in FUMA:
		if n.contains(k):
			return true
	return false

func _criaturas(list: Array) -> void:
	if not Atlas.ok or J.S.map != "town":
		return
	var m: Dictionary = J.MAPS.town
	if Atlas.anim_de("paloma", "idle"):
		for e in J.ents:
			if e.id == "patxi":
				list.append([e.py, _dibujar.bind("paloma", "idle", "unica", now, e.px + 24 - cam.x, e.py + 15 - cam.y)])
				break
	if Atlas.anim_de("gaviota", "idle"):
		if not m.has("docks"):
			var dk := []
			for y in m.h:
				for x in m.w:
					if m.g[y][x] == "dock" and not m.o[y][x]:
						dk.append([x, y])
			var dd := []
			for i in dk.size():
				if i % 5 == 2 and dd.size() < 2:
					dd.append(dk[i])
			m.docks = dd
		for p in m.docks:
			list.append([p[1] * 16, _dibujar.bind("gaviota", "idle", "unica", now + p[0] * 311, p[0] * 16 + 8 - cam.x, p[1] * 16 + 15 - cam.y)])

# efectos del atlas de una capa (mapa, 'home' en la carpa o '*' en el combate); sube 1 px cada 3 fotogramas y, en la calle, el viento
func _vfx(c, capa: String) -> void:
	var vs := []
	for v in J.vfx:
		if now - v.t0 < Atlas.duracion(v.id, "efecto"):
			vs.append(v)
	J.vfx = vs
	for v in vs:
		if v.capa != capa:
			continue
		var t: float = now - v.t0
		var a = Atlas.anim_de(v.id, "efecto")
		var fi := floori(t * (a.fps if a.get("fps") else 10) / 1000.0)
		var dy := floori(fi / 3.0) if v.sube else 0
		var dx := floori(fi / 6.0) if v.sube and capa == "town" else 0
		_dibujar(v.id, "efecto", "unica", t, v.x - c.x + dx, v.y - c.y - dy)

func _bocadillo(x: int, y: int, ch: String, col: Color) -> void:
	_rect(x - 1, y - 1, 9, 10, css("#26262e"))
	_rect(x, y, 7, 8, Color.WHITE)
	_rect(x + 2, y + 8, 3, 1, Color.WHITE)
	var gl: Array = J.D.GLYPH[ch]
	for j in gl.size():
		for i in 5:
			if gl[j][i] == "#":
				_rect(x + 1 + i, y + j, 1, 1, col)

# ---------- combate ----------
func _combate() -> void:
	var B: Dictionary = J.B
	var fo = Atlas.cubre("combate:fondo-" + ("ladron" if B.kind == "thief" else "policia")) if Atlas.ok else null
	var ff = Atlas.frame_de(fo, "base", "unica", 0, {"i": 0}) if fo else null
	if ff:
		_fondo_ancho(ff.c, J.D.CORTES_COMBATE)
	L.draw_set_transform(Vector2(OX(), 0))
	var k := minf(1, float(B.t) / 700)
	var e := 1 - pow(1 - k, 3)
	var ex := Datos.jsround(154 - (1 - e) * 180)
	var px := Datos.jsround(40 + (1 - e) * 190)
	var fE = _comb_frame("E")
	var fP = _comb_frame("P")
	var sh := Datos.jsround(sin(float(B.shakeP) / 18) * 3) if B.shakeP > 0 else 0
	var parpadea: bool = B.flashE > 0 and floori(float(B.flashE) / 70) % 2 == 0
	if fE:
		if B.get("gone") and B.get("aE") and B.aE.n == "huir":
			_pinta(fE, ex + 24 + Datos.jsround((now - B.aE.t0) * .12), 66)
		elif not B.get("gone") and not parpadea:
			_pinta(fE, ex + 24, 66)
	if fP:
		_pinta(fP, px + 24 + sh, 142)
	if Atlas.ok:
		_vfx({"x": 0, "y": 0}, "*")

func _comb_frame(who: String):
	var gr = J.grupo_combate(who)
	if not gr:
		return null
	var B: Dictionary = J.B
	var a = B.get("a" + who)
	var dir := "north" if who == "P" else "south"
	if a:
		var t: float = now - a.t0
		if t < Atlas.duracion(gr, a.n) or a.n == "desmayo":
			return Atlas.frame_de(gr, a.n, "east" if a.n == "huir" else dir, t, {"bucle": a.n == "huir"})
		B["a" + who] = null
	var f = Atlas.frame_de(gr, "idle", dir, now, {"bucle": true})
	return f if f else Atlas.frame_de(gr, "base", dir, 0, {"i": 0})

# ---------- título e intro ----------
func _titulo() -> void:
	var t := now / 1000.0
	var ox := OX()
	var gr = Atlas.cubre("misc:hoja-titulo") if Atlas.ok else null
	var f = Atlas.frame_de(gr, "base", "unica", 0, {"i": 0}) if gr else null
	if f:
		_fondo_ancho(f.c)
	# el agua: rayas de 1 px con x fraccionaria (antialias en sus extremos)
	var c := css("#1e3a64")
	for b in [-240, 0, 240]:
		for y in range(112, 160, 4):
			var o := sin(t * 1.5 + y) * 6
			_raya(ox + b + 20 + o + (y * 7) % 60, y, 30, c)
			_raya(ox + b + 140 - o + (y * 5) % 50, y, 24, c)
	if J.mode != "title":
		_rect(0, 0, J.SW, SH, Color(0, 0, 0, Datos.jsround(.35 * 255) / 255.0))
		var mk = J.D.get("MASCARAS", {}).get("elipse")
		var el: Dictionary
		var o0 := Vector2i(ox + 120, 104)
		if mk:
			if not cache.has("el|canvas"):
				cache["el|canvas"] = _mascara_a(mk)
			el = cache["el|canvas"]
			o0 = Vector2i(ox + 84, 95)
		else:
			el = _elipse(34, 7)
		var col := css("#2a6a48")
		for p in el:
			_rect(o0.x + p.x, o0.y + p.y, 1, 1, Color(col, el[p]))
		_retrato(J.D.LOOKS.kiko, ox + 120, 104, 2)

func _raya(x0: float, y: int, w: float, c: Color) -> void:
	var x1 := x0 + w
	for x in range(maxi(0, floori(x0)), mini(J.SW, ceili(x1))):
		var cv := minf(x + 1, x1) - maxf(x, x0)
		if cv >= 1:
			_rect(x, y, 1, 1, c)
		elif cv > 0:
			_rect(x, y, 1, 1, Color(c, cv))

# cobertura de una elipse centrada en (0, 0) con 16 × 16 muestras por píxel: {Vector2i(x, y) relativo: 0-1}
func _elipse(rx: float, ry: float) -> Dictionary:
	var key := "el|%f|%f" % [rx, ry]
	if cache.has(key):
		return cache[key]
	var o := {}
	for y in range(-ceili(ry) - 1, ceili(ry) + 1):
		for x in range(-ceili(rx) - 1, ceili(rx) + 1):
			var n := 0
			for j in 16:
				var dy := (y + (j + .5) / 16) / ry
				for i in 16:
					var dx := (x + (i + .5) / 16) / rx
					if dx * dx + dy * dy <= 1:
						n += 1
			if n:
				o[Vector2i(x, y)] = n / 256.0
	cache[key] = o
	return o

# arteRetrato: el personaje a ×k, de frente, con su idle si lo tiene; pies en (cx, fy)
func _retrato(look, cx: float, fy: float, k: int) -> void:
	var gr = Atlas.grupo_look(look)
	if not gr:
		return
	var f = Atlas.frame_de(gr, "idle", "south", now, {"bucle": true}) if Atlas.tiene_dir(gr, "idle", "south") else null
	if f == null:
		f = Atlas.frame_de(gr, "base", "south", 0, {"i": 0})
	if f == null:
		return
	var im: Image = f.c
	L.draw_texture_rect(Atlas.tex(im), Rect2(Datos.jsround(cx - f.cel.ancla[0] * k), Datos.jsround(fy - f.cel.ancla[1] * k), im.get_width() * k, im.get_height() * k), false)

# ---------- la carpa, vista B (renderCarpa sin vista C) ----------
func _carpa_fondo() -> void:
	var D: Dictionary = J.D
	var c: Dictionary = g.c
	_fondo_ancho(Procedural.cuarto34())
	L.draw_set_transform(Vector2(OX(), 0))
	if c.get("goteo"):
		var e := Procedural.extra34("goteo")
		var gx: int = g.x0 + g.w + g.s + 12
		var gy: int = int(D.VB.PARED) + 8
		_img(e, gx - (e.get_width() >> 1), gy - e.get_height() + 1)
		var tp: Array = Vista.punto(g, g.W - 6, g.D * .7, 4)
		var osc := css("#1c1d22")
		var y0 := gy - e.get_height() + 1
		_rect(tp[0], y0, gx - tp[0] - 1, 1, osc)
		_rect(tp[0], y0, 1, tp[1] - y0, osc)
	var cv := Procedural.carpa34(c.t)
	_img(cv, g.x0 - 1, g.yf + 2 - cv.get_height())
	if c.get("filtro"):
		var e := Procedural.extra34("filtro")
		var p: Array = Vista.punto(g, g.W * .55, g.D * .85, g.H - 24)
		_img(e, p[0] - (e.get_width() >> 1), p[1] - e.get_height() + 1)
	if c.get("vent"):
		var e := Procedural.extra34("vent")
		var p: Array = Vista.punto(g, 2, g.D * .8, 110)
		_img(e, p[0], p[1] - e.get_height() + 1)

# el cono de luz del foco encendido (dentro de la carpa): trapecio con degradado vertical, sumado ('lighter')
func _cono() -> void:
	if not J.plantas_vivas(J.VC.ci):
		return
	var D: Dictionary = J.D
	var c: Dictionary = g.c
	var F: Dictionary = D.FOCOS[c.foco]
	var key := "cono|%s|%s" % [c.t, c.foco]
	if not cache.has(key):
		var a: float = .05 + .09 * minf(1, F.w / 600.0)
		var lw := Datos.jsround(D.FOCO_CM.get(c.foco, 40) * D.VB.M / 2)
		var hw: float = g.w / 2.0 + g.s
		var fx: float = g.fx
		var fy: float = g.fy
		var yf: float = g.yf
		var pol := PackedVector2Array([Vector2(fx - lw, fy), Vector2(fx + lw, fy), Vector2(fx + hw, yf), Vector2(fx - hw, yf)])
		var cx0: int = g.x0 + 1
		var cx1: int = cx0 + g.w + g.s - 1
		var cob := Procedural.cobertura(pol)
		var luz := css(D.FOCO_LUZ[F.tipo] + "1)")
		var o := {}
		for p in cob:
			if p.x < cx0 or p.x >= cx1:
				continue
			var t := clampf((p.y + .5 - fy) / (yf - fy), 0, 1)
			var al: float = a * (1 - t) * cob[p]
			o[p] = Color8(Datos.jsround(luz.r8 * al), Datos.jsround(luz.g8 * al), Datos.jsround(luz.b8 * al), 255)
		cache[key] = o
	L.draw_set_transform(Vector2(OX(), 0))
	var o: Dictionary = cache[key]
	for p in o:
		_rect(p.x, p.y, 1, 1, o[p])

func _carpa_encima() -> void:
	var S: Dictionary = J.S
	var D: Dictionary = J.D
	var c: Dictionary = g.c
	var F: Dictionary = D.FOCOS[c.foco]
	L.draw_set_transform(Vector2(OX(), 0))
	var clip := Rect2i(g.x0 + 1, 0, g.w + g.s - 1, SH)
	var fsel := Vista.fila_sel(g, J.VC.sel)
	var pl: Array = g.pl.duplicate()
	pl.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and (a.x < b.x or (a.x == b.x and a.i < b.i))))
	for q in pl:
		_planta_b(q, Vista.A35 if q.fila < fsel else 1.0, clip)
	var fc := Procedural.foco34(c.foco)
	var x0: int = g.fx - (fc.get_width() >> 1)
	var y0: int = g.fy - fc.get_height() + 1
	var ty: int = y0 + (4 if F.tipo == "led" else 0)
	if ty > g.barra:
		var cu := css("#2a2b30")
		_rect(x0 + 2, g.barra, 1, ty - g.barra, cu)
		_rect(x0 + fc.get_width() - 3, g.barra, 1, ty - g.barra, cu)
	_img(fc, x0, y0)
	var bs := Vista.barras(S, g, J.VC.sel)
	for b in bs:
		Vista.pinta_barra(L, b, Vista.A35 if b.fila < fsel else 1.0, now)
	Vista.pinta_cursor(L, g, J.VC, bs, now)
	if Atlas.ok:
		_vfx({"x": 0, "y": 0}, "home")

# una textura recortada al rectángulo de la carpa (la luz y las copas no salen por los lados)
func _img_clip(im: Image, x: int, y: int, src: Rect2i, clip: Rect2i, mod: Color) -> void:
	var dst := Rect2i(x, y, src.size.x, src.size.y).intersection(clip)
	if dst.size.x <= 0 or dst.size.y <= 0:
		return
	var s := Rect2i(src.position + dst.position - Vector2i(x, y), dst.size)
	L.draw_texture_rect_region(Atlas.tex(im), Rect2(dst), Rect2(s), mod)

# maceta y planta de una plaza
func _planta_b(q: Dictionary, al: float, clip: Rect2i) -> void:
	var S: Dictionary = J.S
	var p = S.pots[q.i]
	var k: String = S.macetas[q.i]
	var m := Procedural.maceta34(k)
	var mp := Procedural.maceta_px(k)
	var mod := Color(1, 1, 1, al)
	_img_clip(m, q.x - (m.get_width() >> 1), q.y - Datos.jsround(mp.e / 2.0 + mp.hb), Rect2i(Vector2i.ZERO, m.get_size()), clip, mod)
	if p == null:
		return
	var s = Datos.strain(S, p.sid)
	var dead: bool = true if p.get("dead") else false
	var st := 9 if dead else Cultivo.plant_stage(p)
	var pc := Procedural.planta34(Datos.porte_planta(S, p), st, not dead and p.water <= 0, s.c if s else "#9bd35a", q.cw, q.ch)
	var yb: int = q.y - mp.hb + 1
	var a := 1 if not dead and p.water > 0 and st >= 2 else 0
	var x: int = q.x - 24
	var y: int = yb - 79
	if not a:
		_img_clip(pc, x, y, Rect2i(Vector2i.ZERO, pc.get_size()), clip, mod)
	else:
		var tt: float = now + q.x * 37
		var sn := sin(tt / 950) * .7 + sin(tt / 410) * .3
		for r in range(0, pc.get_height(), 2):
			var dx := Datos.jsround(a * sn * pow(maxf(0, (79.0 - r) / 79), 1.5))
			_img_clip(pc, x + dx, y + r, Rect2i(0, r, pc.get_width(), 2), clip, mod)
	if p.pest and not dead:
		var rojo := Color(css("#e02828"), al)
		for n in 6:
			var r := Rect2i(q.x - 6 + ((n * 5 + floori(now / 300)) % 12), yb - 8 - ((n * 7) % 14), 1, 1)
			if clip.encloses(r):
				_rect(r.position.x, r.position.y, 1, 1, rojo)
