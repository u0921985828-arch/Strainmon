# Ribera Verde (Godot) — 14-render y lo que dibuja 01b-arte: el lienzo de SW × SH (180) según el modo, como render(now) del HTML.
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
const Arte = preload("res://src/arte.gd")
const Escena = preload("res://src/escena_extr.gd")
const Croquis = preload("res://src/croquis.gd")
const EscViaje = preload("res://src/escena_viaje.gd")
const Hoja = preload("res://src/hoja.gd")
const B8 = preload("res://src/billar8.gd")

const SH := 180   # 1.12 (ui.gd); las escenas de 240 × 160 van abajo: OY
const DIR4 := {"down": "south", "up": "north", "left": "west", "right": "east"}
const TRANS := {"water": "agua", "dirt": "tierra", "plaza": "plaza", "pista": "tierra", "arena": "plaza", "surco": "tierra", "surcoV": "tierra"}   # i18n-no
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
var mide = null   # tests/solapes.gd: con un Array, _arte_obj apunta lo que pintaría ({o, x, y, c, px, py}) y no pinta
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
	elif m == "title":
		modo = "demo"   # 1.35: la partida de fondo (demo_entra, mundo.gd)
		if Datos.CAL and Atlas.ok and EscViaje.carga():
			modo = "calle"   # 1.57.1 (lo pidió el usuario): la calle de la carga sigue de fondo, en vez de la partida
	elif m == "intro":
		modo = "title"
	elif m == "carga":
		modo = "carga"   # 1.57: la carga del juego, en la carretera (escena_viaje.gd)
	else:
		return
	now = t
	vc.visible = false
	if modo == "carpa":
		g = Vista.geo(J.S, J.VC.ci)
		if not g.vc and g.c.get("goteo"):
			g.lg = _lineas_goteo()
		if g.vc:
			modo = "carpaC"  # i18n-no
			vc.visible = true
			vc.pinta(J.S, J.VC, now, J.SW, SH)
	elif modo == "world":
		cam = camara()
	elif modo == "demo":
		var sv: Array = J.demo_entra(now)
		cam = camara()
		J.demo_sale(sv)
	c0.queue_redraw()
	ad.queue_redraw()
	c1.queue_redraw()

func _capa(ci: CanvasItem, n: int) -> void:
	L = ci
	if modo == "world":
		[_mundo, _farolas, _encima][n].call()
	elif modo == "demo":   # 1.35: el título, con la partida de fondo y el azul encima
		var sv: Array = J.demo_entra(now)
		[_mundo, _farolas, _encima][n].call()
		J.demo_sale(sv)
		if n == 2:
			_azul_demo()
	elif modo == "battle":
		if n == 0:
			_combate()
	elif modo == "title":
		if n == 0:
			_titulo()
	elif modo == "carpa":
		[_carpa_fondo, _cono, _carpa_encima][n].call()
	elif modo == "carga":
		if n == 0:
			EscViaje.pinta_carga(self, now - float(J.carga_t0))
	elif modo == "calle":
		if n == 0:
			EscViaje.pinta_calle(self, now - float(J.carga_t0))
		elif n == 2:   # un velo azul arriba, más suave que el de la partida de fondo, para que se lean el título y el lema
			for i in 11:
				_rect(0, i * 10, J.SW, 10, Color8(14, 22, 60, Datos.jsround((0.42 - i * 0.038) * 255)))
	elif modo == "carpaC" and n == 2:
		L.draw_set_transform(Vector2(OX(), OY()))
		_vfx({"x": 0, "y": 0}, "home")
	L.draw_set_transform(Vector2.ZERO)
	if n == 2 and J.VIAJE_V != null and modo != "title" and modo != "battle" and modo != "carga":   # 1.56: el viaje, de perfil
		EscViaje.pinta(self, J.VIAJE_V, now)
	if n == 2 and J.ACCESO_V != null and modo != "title" and modo != "battle" and modo != "carga":   # 1.53: la llave, el teclado…; 1.54: cada acción de cerca
		for e in J.rects_acceso(J.ACCESO_V, J.M.reloj):
			if typeof(e[0]) == TYPE_STRING:   # 1.54.1: ['@', sprite, x, y, recorte]: el sprite de misc dentro del panel (o la imagen: la planta del gesto)
				var f = {"c": e[1]} if e[1] is Image else Atlas.foto_misc(e[1])
				if f:
					var im: Image = f.c
					var cl: Rect2i = e[4] if e.size() > 4 else Rect2i(0, 0, J.SW, SH)
					_img_clip(im, int(e[2]), int(e[3]), Rect2i(0, 0, im.get_width(), im.get_height()), cl, Color.WHITE)
				continue
			_rect(e[0], e[1], e[2], e[3], css(e[4]))

# ---------- utilidades de dibujo ----------
func OX() -> int:
	return (J.SW - 240) >> 1

func OY() -> int:
	return SH - 160

static var _css := {}   # R4: cada color de texto se lee una vez
static func css(s: String) -> Color:
	var c = _css.get(s)
	if c != null:
		return c
	if s.begins_with("#"):
		c = Procedural.col(s)
	else:
		var n := s.substr(s.find("(") + 1).replace(")", "").split(",")
		c = Color8(int(n[0]), int(n[1]), int(n[2]), Datos.jsround(float(n[3]) * 255) if n.size() > 3 else 255)
	if _css.size() < 4096:
		_css[s] = c
	return c

func _img(im: Image, x: float, y: float, mod := Color.WHITE) -> void:
	if alfa < 1.0:
		mod.a *= alfa
	Atlas.dibuja(L, im, Rect2(x, y, im.get_width(), im.get_height()), null, mod)

func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	if w > 0 and h > 0:
		if alfa < 1.0:
			c.a *= alfa
		L.draw_rect(Rect2(x, y, w, h), c)

# translúcido si tapa al protagonista (lo pidió el usuario: «como en los Sims»; con CAL): lo que se pinta después de él (su pie, más
# abajo que el suyo) y le pisa el cuerpo con más de TAPA_PX píxeles opacos se pinta a TAPA_ALFA, para verlo detrás
const TAPA_ALFA := 0.45
const TAPA_PX := 12
var alfa := 1.0

func caja_pj() -> Rect2i:   # el cuerpo del protagonista en la pantalla (sus pies en px + 8, py + 15, como en _pj)
	var P: Dictionary = J.P
	return Rect2i(Datos.jsround(P.px - cam.x) + 2, Datos.jsround(P.py - cam.y) - 11, 12, 26)

func tapa_pj(im: Image, x: int, y: int, pie: float) -> bool:
	if not Datos.CAL or J.SENT != null or pie <= float(J.P.py) or J.mode != "world":
		return false
	var b := caja_pj().intersection(Rect2i(x, y, im.get_width(), im.get_height()))
	if b.size.x <= 0 or b.size.y <= 0:
		return false
	var nn := 0
	for yy in range(b.position.y, b.end.y):
		for xx in range(b.position.x, b.end.x):
			if im.get_pixel(xx - x, yy - y).a > .5:
				nn += 1
				if nn >= TAPA_PX:
					return true
	return false

# lo de encima de una mesa (las plantas y los focos, hasta TAPA_ALTO px sobre ella), que no está en su sprite: por su caja
const TAPA_ALTO := 48
func tapa_encima(x: int, y: int, w: int, pie: float) -> bool:
	if not Datos.CAL or J.SENT != null or pie <= float(J.P.py) or J.mode != "world":
		return false
	var b := caja_pj().intersection(Rect2i(x, y - TAPA_ALTO, w, TAPA_ALTO))
	return b.size.x * b.size.y >= TAPA_PX * 4

func _con_alfa(tapa: bool, f: Callable) -> void:
	if tapa:
		alfa = TAPA_ALFA
	f.call()
	alfa = 1.0

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

# fondoAncho: la escena de 240 centrada y abajo; las bandas de los lados, con el reflejo de los bordes (o la copia, con cortes), y
# la de arriba, con el reflejo de las primeras filas
func _fondo_ancho(img: Image, cortes = null) -> void:
	var ox := OX()
	var oy := OY()
	var key := "fa|%d|%d|%s" % [img.get_instance_id(), J.SW, str(cortes)]
	if not cache.has(key):
		var o := Image.create(J.SW, SH, false, Image.FORMAT_RGBA8)
		o.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(ox, oy))
		var esp := img.duplicate()
		esp.flip_x()
		for c in ((cortes if cortes else [[0, 160, ""]]) if ox else []):
			var y0: int = c[0]
			var h: int = int(c[1]) - y0
			var lado: String = c[2]
			var y := y0 + oy
			if lado != "dch":   # izquierda: las ox columnas de la izquierda, al revés
				o.blit_rect(esp, Rect2i(240 - ox, y0, ox, h), Vector2i(0, y))
			if lado != "izq":   # derecha: las de la derecha, al revés
				o.blit_rect(esp, Rect2i(0, y0, ox, h), Vector2i(J.SW - ox, y))
			if lado == "dch":
				o.blit_rect(img, Rect2i(240 - ox, y0, ox, h), Vector2i(0, y))
			if lado == "izq":
				o.blit_rect(img, Rect2i(0, y0, ox, h), Vector2i(240 + ox, y))
		if oy:   # arriba, las primeras oy filas del todo, al revés
			var b := o.get_region(Rect2i(0, oy, J.SW, oy))
			b.flip_y()
			o.blit_rect(b, Rect2i(0, 0, J.SW, oy), Vector2i.ZERO)
		if cache.size() > 512:   # R7: tope
			cache.clear()
		cache[key] = o
	_img(cache[key], 0, 0)

# ---------- mundo ----------
func camara() -> Vector2i:
	var m: Dictionary = J.MAPS[J.S.map]
	var o: bool = J.ORDEN != null and J.ORDEN.mapa == J.S.map   # 1.37: al ordenar, sobre la pieza (12d-orden)
	var cx: float = (J.ORDEN.x * 16.0 if o else J.P.px) + 8 - J.SW / 2.0
	var cy: float = (J.ORDEN.y * 16.0 if o else J.P.py) + 8 - SH / 2.0
	var mw: int = m.w * 16
	var mh: int = m.h * 16
	cx = (mw - J.SW) / 2.0 if mw <= J.SW else clampf(cx, 0, mw - J.SW)
	cy = (mh - SH) / 2.0 if mh <= SH else clampf(cy, 0, mh - SH)
	return Vector2i(Datos.jsround(cx), Datos.jsround(cy))

func story_mark(id: String) -> bool:
	var S: Dictionary = J.S
	var F: Dictionary = S.flags
	if id.begins_with("sec_") or id.begins_with("secb_"):   # 1.51: los recados
		return J.sec_marca(id)
	match id:
		"kiko": return not F.get("kiko1") or (S.ch == 4 and not F.get("lab"))
		"baltasar": return (S.ch == 3 and not F.get("metB")) or (S.due > 0 and S.money >= S.due) or (S.ch >= 8 and not S.get("encargo") and not (S.get("encVeto", 0) > S.day))
		"tono2": return J.is_night()
		"jurado": return true
		"molina": return not F.get("molina1") or not S.protect
		"darko": return S.ch < 6
		"darko2": return S.ch >= int(J.D.DARKO.ch) and not F.get("darkoFin")
		"txaro": return (S.ch >= 2 and not F.get("txaro")) or (S.ch >= 4 and not F.get("txaro2"))
		"inaki": return not F.get("inaki")
		"julen": return not F.get("julen1")
	return false

func _mundo() -> void:
	var S: Dictionary = J.S
	var P: Dictionary = J.P
	var m: Dictionary = J.MAPS[S.map]
	_rect(0, 0, J.SW, SH, Color.BLACK)
	var tx0 := floori(cam.x / 16.0)
	var ty0 := floori(cam.y / 16.0)
	var list := []
	var sombras := []
	var tras := []   # con CAL, los árboles de detrás de un edificio (m.tras, de mundo.gd): antes que los edificios
	var mt: Dictionary = m.get("tras", {}) if Datos.CAL else {}
	# hasta 6 filas por debajo y 2 casillas a cada lado de la pantalla (1.10, 14-render.js): los objetos altos (el árbol, de 6
	# filas; el monte, 3 de ancho) se ven aunque su pie esté fuera
	for ty in range(ty0, ty0 + ceili(SH / 16.0) + 7):
		for tx in range(tx0 - (15 if S.map == "muelle" else 2), tx0 + ceili(J.SW / 16.0) + 3):   # 1.51: los barcos del muelle, de hasta 15 casillas
			if tx < 0 or ty < 0 or tx >= m.w or ty >= m.h:
				continue
			var sx: int = tx * 16 - cam.x
			var sy: int = ty * 16 - cam.y
			var k: String = m.g[ty][tx]
			if _arte_tile(k, tx, ty, sx, sy):
				if k == "water":
					_playa_agua(m, tx, ty, sx, sy)
				_arte_orilla(m, k, tx, ty, sx, sy)
				if m.has("dec"):   # Bilbao: lo del suelo (tapa, imbornal, cebra) a ritmo fijo, de tools/bilbao.py
					_arte_dec(m.dec.get("%d,%d" % [tx, ty], ""), sx, sy)
			var o = m.o[ty][tx]
			if o and o != "carpa":
				_arte_obj(o, tx, ty, tras if mt.has("%d,%d" % [tx, ty]) else list, sombras)
	for r in sombras:
		_rect(r[0], r[1], r[2], r[3], Color8(0, 0, 0, 56))
	if Datos.CAL and S.map == "huerta" and J.huerta_m("goteo") > 0:   # el goteo de la huerta, en el suelo
		_manguera_huerta()
	for o in tras:
		o[1].call()
	if S.map == "disco-vip":
		_cristalera(m, tx0, ty0)
	_arte_edificios(m)
	if S.map == "home":
		for t in m.get("carpas", []):
			list.append([t.y * 16, _carpa_mapa.bind(t)])
		for ci in J.D.SITIOS.size():
			if J.sitio_visible(ci):
				_sitio(J.sitio(ci))
		if Datos.CAL:   # 1.55: el tubo de extracción de cada carpa a una ventana, detrás de lo de la fila 2
			list.append([2 * 16 - 1, _tubos_casa.bind(m)])
		if not S.flags.get("letter"):
			var mp: Array = J.pos_pieza("home", "mesa")   # 1.37: la carta, en la mesa redonda, donde esté
			var lx: int = mp[0] * 16 - cam.x
			var ly: int = mp[1] * 16 - cam.y
			if Datos.CAL:   # 1.50 (lo pidió el usuario): encima del tablero de la mesa a escala (e-table, de 3 px por encima de su
				# casilla a 2 px dentro), después de la mesa para que no la tape
				list.append([mp[1] * 16 + 1, func():
					_rect(lx + 5, ly - 2, 6, 3, css("#fafaf2"))
					_rect(lx + 5, ly + 1, 6, 1, css("#d8d4c4"))
					_rect(lx + 7, ly - 1, 2, 1, css("#c04040"))])
			else:
				_rect(lx + 5, ly + 5, 7, 5, css("#fafaf2"))
				_rect(lx + 8, ly + 7, 2, 1, css("#c04040"))
	if S.map == "nave":
		list.append([2 * 16 - 1, _manguera_nave])   # 1.33: la manguera del riego, detrás de lo de la fila 2
	if Atlas.ok and ambiente_on:
		for e in J.ents:
			_ambiente(e)
	if J.D.ZONAS.has(S.map):
		_vistas()
	for e in J.ents:
		list.append([e.py, _pj.bind(e, e.look, false, float(e.get("dur", 320.0)))])
	if Datos.CAL and S.map != J.GARAJE:   # MAESTRO [3]: los tuyos, en el aparcamiento de la parada, sin nadie
		var ak: Array = J.aparcados(S.map)
		var pl: Array = J.plazas_parque(S.map) if ak.size() else []
		for i in mini(ak.size(), pl.size()):
			if Atlas.anim_de("vehiculos", String(ak[i]) + "-atras"):
				list.append([pl[i].y * 16, _aparcado.bind(String(ak[i]), pl[i].x, pl[i].y, "right", 8 if J.APARC.has(S.map) else 0)])
	if J.SENT != null:   # 1.47: sentado, delante del asiento si se ve de frente y detrás si se ve de espaldas
		list.append([J.SENT.y * 16 + (1 if J.SENT.d == "sur" or J.SENT.get("k") in J.TABURETES else -1), _pj_sentado])
	else:
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
			if e.def.client.type == "ext":
				_bocadillo(bx, by, "gota", css("#d08a10"))
			else:
				_bocadillo(bx, by, "$", css("#2a9a4a"))
		elif story_mark(e.id) or e.get("caza"):
			_bocadillo(bx, by, "!", css("#e03030"))
	if Datos.PLAY:   # U2 (fase 5): la flecha amarilla encima del objetivo, botando
		var ob: Vector2i = J.objetivo_xy()
		if ob.x >= 0:
			var ax: int = ob.x * 16 - cam.x + 8
			var ay: int = ob.y * 16 - cam.y - 12 + bob * 2
			var ne := css("#202020")
			var am := css("#f8d040")
			_rect(ax - 2, ay - 5, 4, 5, ne)
			_rect(ax - 1, ay - 4, 2, 4, am)
			for r in 4:
				_rect(ax - 4 + r, ay + r, 8 - 2 * r, 1, am)
				_rect(ax - 5 + r, ay + r, 1, 1, ne)
				_rect(ax + 4 - r, ay + r, 1, 1, ne)
			_rect(ax - 1, ay + 4, 2, 1, ne)
	# el piso de noche (1.10 P5): se oscurece como la calle; la mancha de luz de cada carpa encendida, en _farolas
	if S.map == "home" and noche() > 0:
		_rect(0, 0, J.SW, SH, Color8(14, 20, 72, Datos.jsround(noche() * 255)))
	if _al_raso():
		var h: float = S.min / 60.0
		if h >= 17.5 and h < 20.5:
			_rect(0, 0, J.SW, SH, Color8(255, 130, 50, Datos.jsround(.13 * sin((h - 17.5) / 3 * PI) * 255)))
		if Datos.CAL:
			_tiempo(now)
		var a := noche()
		if a > 0:
			_rect(0, 0, J.SW, SH, Color8(14, 20, 72, Datos.jsround(a * 255)))
	var LZ = _luz_local()   # los locales (1.30): el fondo, encima de todo; sus luces, en _farolas
	if LZ and LZ.get("fondo"):
		_rect(0, 0, J.SW, SH, css(LZ.fondo))

# el tiempo en la calle (1.52): nubes que apagan, lluvia y nieve que caen, niebla y algún relámpago con tormenta
func _tiempo(now: float) -> void:
	var k: String = Datos.tiempo(int(J.S.day), int(J.S.min)).k
	if k == "sol":
		return
	var gris := {"nubes": 30, "lluvia": 55, "tormenta": 85, "niebla": 0, "nieve": 35}
	if gris[k]:
		_rect(0, 0, J.SW, SH, Color8(40, 48, 60, gris[k]))
	if k == "niebla":
		_rect(0, 0, J.SW, SH, Color8(200, 208, 214, 90))
		return
	if k == "nubes":
		return
	var n := 110 if k == "nieve" else 170
	for i in n:
		var hx := Datos.hash_str("ll%d" % i)
		if k == "nieve":
			var y := fposmod((hx >> 9) % SH + now / 40.0, SH)
			var x := fposmod(hx % J.SW + 3.0 * sin(now / 600.0 + i), J.SW)
			_rect(int(x), int(y), 1 + (hx >> 3) % 2, 1 + (hx >> 3) % 2, Color8(255, 255, 255, 235))
		else:
			var v := 0.35 + float((hx >> 5) % 10) / 40.0
			var y := fposmod((hx >> 9) % SH + now * v, SH)
			var x := fposmod(hx % J.SW - y / 3.0, J.SW)
			_rect(int(x), int(y), 1, 3, Color8(200, 220, 240, 200))   # la gota inclinada: dos trazos
			_rect(int(x) - 1, int(y) + 3, 1, 3, Color8(200, 220, 240, 200))
	if k == "tormenta" and fposmod(now, 7000.0) < 120.0 and not Vista.CALMA:
		_rect(0, 0, J.SW, SH, Color8(255, 255, 240, 110))

# al aire libre: las zonas de la calle y, con CAL (MAESTRO [4]), el muelle de Puerto Viejo, que ya no está siempre a pleno sol:
# el atardecer, el tiempo, la noche y sus farolas como en la calle
func _al_raso() -> bool:
	return J.D.ZONAS.has(J.S.map) or (Datos.CAL and (J.S.map in ["muelle", "comarcal", "huerta"] or J.S.map.begins_with("carr-")))

func _farolas_mapa() -> Array:   # las farolas de un mapa sin LAMPS: las «lamp» que tenga
	var o := []
	var m: Dictionary = J.MAPS[J.S.map]
	for y in int(m.h):
		for x in int(m.w):
			if m.o[y][x] == "lamp":
				o.append([x, y])
	return o

func noche() -> float:
	var h: float = J.S.min / 60.0
	return .5 if h >= 21 or h < 5 else ((h - 19) / 2 * .5 if h >= 19 else ((7 - h) / 2 * .5 if h < 7 else 0.0))

# las farolas con la noche cerrada: un degradado radial (r 1 → 28) sumado a lo que hay ('lighter')
func _farolas() -> void:
	if J.S.map == "home":
		_manchas()
	_luces_local()
	if not _al_raso():   # farolas de cada zona de fuera (1.10)
		return
	var a := noche()
	if a <= .2:
		return
	var im := _farola(a)
	for l in J.D.LAMPS.get(J.S.map, _farolas_mapa()):
		var x: int = l[0] * 16 + 8 - cam.x
		var y: int = l[1] * 16 + 2 - cam.y
		if x < -30 or y < -30 or x > J.SW + 30 or y > SH + 30:
			continue
		_img(im, x - 30, y - 22)

# delante de cada carpa encendida, de noche, la luz de su foco en el suelo: degradado radial (r 1 → 18) desde (xc, yb + 5), en la
# mitad de abajo (40 × 24 desde (xc − 20, yb − 4)), sumado a lo que hay
func _manchas() -> void:
	var a := noche()
	if a <= 0:
		return
	var m: Dictionary = J.MAPS[J.S.map]
	for t in m.get("carpas", []):
		if not Cultivo.foco_on(J.S, t.ci):
			continue
		var xc: int = (t.x0 + t.x1 + 1) * 8 - cam.x
		var yb: int = t.y * 16 + 15 - cam.y
		_img(_mancha(a, J.D.FOCOS[J.S.carpas[t.ci].foco].tipo), xc - 20, yb - 4)

func _mancha(a: float, tipo: String) -> Image:
	var key := "mancha|%f|%s" % [a, tipo]
	if cache.has(key):
		return cache[key]
	var c := css(J.D.FOCO_LUZ[tipo] + "1)")
	var im := Image.create(40, 24, false, Image.FORMAT_RGBA8)
	for y in 24:
		for x in 40:
			var d := Vector2(x + .5 - 20, y + .5 - 9).length()
			var t := clampf((d - 1) / 17.0, 0, 1)
			var al := minf(1, a * 1.2) * (1 - t)
			im.set_pixel(x, y, Color8(Datos.jsround(c.r8 * al), Datos.jsround(c.g8 * al), Datos.jsround(c.b8 * al), 255))
	if cache.size() > 512:   # R7: tope
		cache.clear()
	cache[key] = im
	return im

# la luz de los locales (luzLocal, 14-render; LUZ_CLUB, LUZ_DISCO y, 1.31, los LED de la nave, _luz_nave): cada luz, un degradado radial (r 1 → r) sumado; los focos de
# GAUA dan una vuelta a la pista cada 7 s (0,9 rad/s), cada uno desde su fase
func _luz_local():
	if J.S.map == "nave":
		return _luz_nave()
	if J.S.map.begins_with("club-"):   # 1.34: cada club, con la lámpara sobre su billar
		return J.luz_club(J.S.map.substr(5))   # 1.37: la de la asociación, sobre el billar donde esté
	if Datos.CAL and J.S.map in ["disco", "disco-vip"]:   # 1.47: GAUA grande, los focos sobre la pista nueva (y, arriba, por el cristal)
		return J.D.DISCO_CAL.luz
	return J.D.LUZ_DISCO if J.S.map == "disco" else ((J.D.LUZ_BAJO_G if int(J.MAPS.setas.w) > 10 else J.D.LUZ_BAJO) if J.S.map == "setas" else (J.D.LUZ_BAJO if J.S.map == "sotano" else null))   # 1.34: el bajo, con su bombilla

# la nave (1.31, luzNave de 11j-locales): bajo cada uno de los dos focos de una mesa plantada, su luz en las plantas (1.33: del color del foco)
func _luz_nave() -> Dictionary:
	var l := []
	for i in J.D.MESAS_X.size():
		if J.fase_mesa(i):
			var c: String = J.D.FOCO_NAVE[J.S.nave.f[i]].luz
			var XY: Array = J.pos_mesa(i)   # 1.37: donde esté la mesa
			for z in J.D.LUZ_MESA:
				l.append([int(XY[0]) * 16 + int(z[0]), int(z[1]) + (int(XY[1]) - 4) * 16, z[2], c, z[4]])
	return {"l": l}

func _luces_local() -> void:
	var LZ = _luz_local()
	if not LZ:
		return
	for l in LZ.get("l", []):
		_img(_luz(int(l[2]), l[3], float(l[4])), int(l[0]) - cam.x - int(l[2]), int(l[1]) - cam.y - int(l[2]))
	for fo in LZ.get("focos", []):
		var t: float = now / 1000.0 * .9 + float(fo[1])
		var R := int(LZ.R)
		var x: int = Datos.jsround(LZ.c[0] + cos(t) * LZ.r[0]) - cam.x
		var y: int = Datos.jsround(LZ.c[1] + sin(t) * LZ.r[1]) - cam.y
		_img(_luz(R, fo[0], .5), x - R, y - R)

func _luz(r: int, c: String, a: float) -> Image:
	var key := "luz|%d|%s|%f" % [r, c, a]
	if cache.has(key):
		return cache[key]
	var cc := c.split(",")
	var im := Image.create(2 * r, 2 * r, false, Image.FORMAT_RGBA8)
	for y in 2 * r:
		for x in 2 * r:
			var d := Vector2(x + .5 - r, y + .5 - r).length()
			var al := a * (1 - clampf((d - 1) / (r - 1.0), 0, 1))
			im.set_pixel(x, y, Color8(Datos.jsround(int(cc[0]) * al), Datos.jsround(int(cc[1]) * al), Datos.jsround(int(cc[2]) * al), 255))
	if cache.size() > 512:   # R7: tope
		cache.clear()
	cache[key] = im
	return im

# encima de todo (1.30): la barra del billar mientras apuntas (pintaTiro, 14-render); 1.35: la mesa de la partida (MESA_B) y dos
# barras: en la de la dirección, el verde es la tronera (TIRO.a); en la de la fuerza, el verde mete y el rojo cuela la blanca
func _encima() -> void:
	if J.MESA_B != null:
		for e in J.rects_mesa_billar(J.MESA_B):
			_rect(e[0], e[1], e[2], e[3], css(e[4]))
	if J.MESA8 != null:   # 1.58: la bola 8 de verdad (billar8.gd)
		for e in B8.rects(J.MESA8, J.SW, SH, J.M.reloj):
			if typeof(e[0]) == TYPE_STRING:   # ['@', imagen, x, y, recorte(, celda)]: la mesa, el taco y las bolas
				var im: Image = e[1]
				var src: Rect2i = e[5] if e.size() > 5 else Rect2i(0, 0, im.get_width(), im.get_height())
				_img_clip(im, int(e[2]), int(e[3]), src, e[4], Color.WHITE)
				continue
			_rect(e[0], e[1], e[2], e[3], css(e[4]))
	if J.TIRO != null:
		_tiro()
	if J.ORDEN != null and J.ORDEN.mapa == J.S.map:   # 1.37: el marco de la pieza que mueves (12d-orden)
		var cm := camara()
		for e in J.rects_orden():
			_rect(float(e[0]) - cm.x, float(e[1]) - cm.y, e[2], e[3], css(e[4]))
	if J.CARRO_V != null:   # el carro de esquejes por dentro (1.40)
		for e in J.rects_carro(J.CARRO_V):
			_rect(e[0], e[1], e[2], e[3], css(e[4]))
	if J.SETAS_V != null:   # 1.43.9: las baldas del bajo de las setas, a la vista
		for e in J.rects_bajo(J.SETAS_V):
			_rect(e[0], e[1], e[2], e[3], css(e[4]))
	if J.MADRES_V != null:   # el armario de las madres de la nave, por dentro (nave.gd rects_madres, con CAL)
		for e in J.rects_madres(J.MADRES_V):
			if typeof(e[0]) == TYPE_STRING:   # ['@', imagen, x, y, recorte]
				var im: Image = e[1]
				_img_clip(im, int(e[2]), int(e[3]), Rect2i(0, 0, im.get_width(), im.get_height()), e[4], Color.WHITE)
				continue
			_rect(e[0], e[1], e[2], e[3], e[4] if e[4] is Color else css(e[4]))
	if J.ARM_V != null:   # 1.44: el armario del bajo, por dentro
		for e in J.rects_armario():
			_rect(e[0], e[1], e[2], e[3], css(e[4]))
	if J.MAPA_V != null:   # 1.42: el mapa de la comarca, un croquis (croquis.gd)
		var mt: bool = J.metro_ya()   # con la autopista a Hiriburu
		var kc := "croquis|%d|%s" % [int(J.S.ch), mt]
		if not cache.has(kc):
			if cache.size() > 512:   # R7: tope
				cache.clear()
			cache[kc] = Croquis.imagen(J.D, int(J.S.ch), mt)
		var al: int = J.alto_libre()
		var o := Croquis.origen_mapa(J.SW, al)
		_img(cache[kc], o.x, o.y)
		for e in Croquis.rects_mapa(J.SW, J.MAPA_V, Croquis.pueblo_de(J.S.map), al):
			if e[4] == "#f8d040" and int(now / 400.0) % 2:
				continue
			_rect(e[0], e[1], e[2], e[3], css(e[4]))
	if J.CAL_V != null:   # 1.42: la hoja del mes
		for e in Croquis.rects_cal(J.SW, J.CAL_V, int(J.S.day), J.marcas_cal(), J.alto_libre()):
			_rect(e[0], e[1], e[2], e[3], css(e[4]))
	if J.FICHA_V != null:   # 1.51: la ficha de la variedad, con su hoja (hoja.gd)
		for e in J.rects_ficha(J.FICHA_V):
			_rect(e[0], e[1], e[2], e[3], css(e[4]))
		var hk: String = "hoja|" + str(J.FICHA_V.l[J.FICHA_V.i])
		if not cache.has(hk):
			if cache.size() > 512:   # R7: tope
				cache.clear()
			cache[hk] = Hoja.imagen(Hoja.params(J.D, J.S, J.FICHA_V.l[J.FICHA_V.i]))
		var hp: Vector2i = J.hoja_xy()
		_img(cache[hk], hp.x, hp.y)
	if J.ALMACEN != null or J.MOVIL_V != null:   # la caja fuerte y la nevera por dentro (1.36); 1.51, el móvil
		for e in (J.rects_almacen(J.ALMACEN) if J.ALMACEN != null else J.rects_movil(J.MOVIL_V)):
			if typeof(e[0]) == TYPE_STRING:   # ['@', sprite, x, y]: un sprite de misc por su esquina
				var f = Atlas.foto_misc(e[1])
				if f:
					_img(f.c, e[2], e[3])
				continue
			_rect(e[0], e[1], e[2], e[3], css(e[4]))

func _tiro() -> void:
	var B: Dictionary = J.D.BILLAR
	var w := 120
	var x0: int = (J.SW - w) >> 1
	var y0: int = (J.SH - 8) >> 1   # 1.36: centrada en la pantalla (lo pidió el usuario)
	var p: float = J.pos_tiro(J.TIRO, now)
	var dir: bool = J.TIRO.get("f") == "dir"
	var a: float = float(J.TIRO.a) if dir else float(B.verde)
	_rect(x0 - 2, y0 - 2, w + 4, 12, css("#26262e"))
	_rect(x0, y0, w, 8, css("#3a3446"))
	if not dir:
		_rect(x0 + Datos.jsround(B.falta * w), y0, w - Datos.jsround(B.falta * w), 8, css("#e04040"))
	_rect(x0 + Datos.jsround((J.centro_tiro(J.TIRO, now) - a) * w), y0, Datos.jsround(2 * a * w), 8, css("#58d080"))
	_rect(x0 + Datos.jsround(p * (w - 2)), y0 - 1, 2, 10, css("#ffffff"))
	if J.TIRO.has("esc"):   # 1.38: la escena de la extracción, encima de la barra
		Escena.pinta(self, J.TIRO, now, (J.SW - Escena.W) >> 1, y0 - Escena.H - 10)

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
	if cache.size() > 512:   # R7: tope
		cache.clear()
	cache[key] = im
	return im

func _arte_dec(n: String, sx: int, sy: int) -> void:
	if n == "":
		return
	var f = Atlas.frame_de("suelo-bilbao", n, "unica", 0, {"i": 0})
	if f:
		Atlas.dibuja(L, f.c, Rect2(sx, sy, 16, 16))

func _arte_tile(k: String, tx: int, ty: int, sx: int, sy: int) -> bool:
	if not Atlas.ok:
		return false
	if k == "cristalV":   # 1.47: el suelo de cristal del reservado: debajo, la pista de GAUA (y encima, _cristalera)
		var md: Dictionary = J.MAPS.disco
		return _arte_tile(md.g[ty][tx] if ty < md.g.size() and tx < md.g[ty].size() else "floorD", tx, ty, sx, sy)  # i18n-no
	if k.begins_with("cv"):
		return _curva(k, tx, ty, sx, sy)
	if k.begins_with("hito_"):   # los sitios de los pueblos (tools/pueblos.py): debajo, su suelo; encima, el edificio
		return _arte_tile(k.substr(5), tx, ty, sx, sy)
	if k == "arena":   # la playa: debajo, el agua si la toca; encima, la arena con su orilla (_playa)
		var ma: Dictionary = J.MAPS[J.S.map]
		var ag := _vecinas(ma, tx, ty, ["water"])
		if ag.any(func(f): return f.has(true)):
			_arte_tile("water", tx, ty, sx, sy)
		_img(_playa(tx, ty, ag, _vecinas(ma, tx, ty, HIERBA)), sx, sy)
		return true
	if k == "surco" or k == "surcoV":   # la tierra arada de los bancales: la tierra y, encima, sus surcos (surcoV: recién cavada; i18n-no)
		_arte_tile("dirt", tx, ty, sx, sy)
		_img(_surco(tx, ty, k == "surcoV"), sx, sy)   # i18n-no
		return true
	var an = Atlas.sobre.get("tile:" + k)
	if an:
		var a = Atlas.anim_de(an[0][0], an[0][1])
		var pis: bool = not a.get("bucle")
		if not pis or (J.P.x == tx and J.P.y == ty):
			var pt: float = J.P.get("pisT", 0.0)
			var f = Atlas.frame_de(an[0][0], an[0][1], "unica", (now - (pt if pt else now)) if pis else now, {"bucle": not pis})
			if f:
				if f.c.get_width() >= 32:
					Atlas.dibuja(L, f.c, Rect2(sx, sy, 16, 16), Rect2((tx & 1) * 16, (ty & 1) * 16, 16, 16))
				else:
					_img(f.c, sx, sy)
				return true
	if Datos.CAL and MOSAICO_TILE.has(k):   # 1.48 (lo pidió el usuario: «más de RPG clásico»): el mosaico de 64 × 64, sin la rejilla de 16
		var fp = Atlas.frame_de("exterior-mosaico", "mo-" + k, "unica", 0, {"i": 0})
		if fp:
			Atlas.dibuja(L, fp.c, Rect2(sx, sy, 16, 16), Rect2(((tx & 3) + 4 * (ty & 3)) * 16, 0, 16, 16))
			if HIERBA.has(k):
				_canto_hierba(tx, ty, sx, sy)
				if k == "grass":
					_detalle(tx, ty, sx, sy)
			elif k == "dirt":   # i18n-no
				_detalle_tierra(tx, ty, sx, sy)
			return true
	var f = Atlas.frame_de(Atlas.cubre("tile:" + k), k, "unica", 0, {"i": 0})
	if f == null:
		return false
	if f.c.get_width() > 16 and f.c.get_height() == 16:   # tira de variantes (orgánico)
		var v: int = (variante(k, tx, ty) + floori(now / 600)) % 4 if k == "baile" else variante(k, tx, ty)   # la pista de GAUA cambia cada 0,6 s (1.30)
		Atlas.dibuja(L, f.c, Rect2(sx, sy, 16, 16), Rect2(v * 16, 0, 16, 16))
		return true
	Atlas.dibuja(L, f.c, Rect2(sx, sy, 16, 16))
	if k == "grass":
		_detalle(tx, ty, sx, sy)
	elif Datos.CAL and k == "pista":   # i18n-no
		_detalle_tierra(tx, ty, sx, sy)
	return true

# Los firmes en mosaico (exterior-mosaico) y el canto de la hierba donde toca acera, calzada u hormigón: dos píxeles más oscuros,
# como un borde, en vez del corte seco de casilla a casilla
const MOSAICO_TILE := {"grass": 1, "flowers": 1, "tallgrass": 1, "dirt": 1, "walk": 1, "plaza": 1, "roadT": 1, "roadB": 1, "roadL": 1, "roadR": 1, "roadX": 1}   # roadL/R/X: las calles de norte a sur y los cruces del Ensanche de Bilbao
const DURO := {"walk": 1, "roadT": 1, "roadB": 1, "roadL": 1, "roadR": 1, "roadX": 1, "hormigon": 1, "rotoT": 1, "rotoB": 1}
func _canto_hierba(tx: int, ty: int, sx: int, sy: int) -> void:
	var m: Dictionary = J.MAPS[J.S.map]
	var c1 := Color8(0x5a, 0xa0, 0x4e)
	var c2 := Color8(0x72, 0xbc, 0x5e)
	for q in [[0, -1], [0, 1], [-1, 0], [1, 0]]:
		var nx: int = tx + q[0]
		var ny: int = ty + q[1]
		if nx >= 0 and ny >= 0 and nx < m.w and ny < m.h and q[0] == 0 and m.g[ny][nx].begins_with("cv"):   # la curva: solo donde llega la calzada
			var cv: Dictionary = _cv(m.g[ny][nx])
			for px in (0 if cv.t == "P" else 16):
				var o := _cv_o(cv, px)
				if q[1] == 1 and cv.r == 0 and o == 0:
					_rect(sx + px, sy + 15, 1, 1, c1); _rect(sx + px, sy + 14, 1, 1, c2)
				elif q[1] == -1 and cv.r == 2 and o == 16:
					_rect(sx + px, sy, 1, 1, c1); _rect(sx + px, sy + 1, 1, 1, c2)
			continue
		if nx < 0 or ny < 0 or nx >= m.w or ny >= m.h or not DURO.has(m.g[ny][nx]):
			continue
		if q[1] == -1:
			_rect(sx, sy, 16, 1, c1); _rect(sx, sy + 1, 16, 1, c2)
		elif q[1] == 1:
			_rect(sx, sy + 15, 16, 1, c1); _rect(sx, sy + 14, 16, 1, c2)
		elif q[0] == -1:
			_rect(sx, sy, 1, 16, c1); _rect(sx + 1, sy, 1, 16, c2)
		else:
			_rect(sx + 15, sy, 1, 16, c1); _rect(sx + 14, sy, 1, 16, c2)

# orgánico (1.10, 01b-arte.js): el mismo hash de casilla que el HTML (hashT) para que nada vaya a compás de la rejilla: qué
# variante de un firme sale (la 0, la lisa, la que más), qué detalle lleva la hierba y dónde, y cuánto se corre (y si va en
# espejo) cada árbol y cada monte
# Las curvas de las carreteras (lo pidió el usuario: «molaría que los caminos no siempre sean rectos», luego «más tramos rectos» y
# «hazlo mejor»; tools/carreteras.py): piezas de CV_PIEZA × 3 casillas «cv<R|O|P>-<d|u>-<columna><fila>» en las que la calzada (asfalto
# R, roto O o pista P) baja (d) o sube (u) una fila. Cada columna de píxeles copia la de la calzada recta corrida o px, sobre la hierba y
# con el canto de la hierba; o sale de una S suave con los escalones limpios del pixel art (de largos a cortos hasta el medio y de
# cortos a largos después, sin 2-1-2: _cv_tabla).
const CV_PIEZA := 4
static var _CV_T := PackedInt32Array()
static func _cv(k: String) -> Dictionary:
	var p := k.split("-")
	return {"t": p[0].substr(2, 1), "d": p[1] == "d", "c": int(p[2].substr(0, 1)), "r": int(p[2].substr(1, 1))}

static func _cv_tabla() -> PackedInt32Array:
	if _CV_T.size():
		return _CV_T
	var n: int = CV_PIEZA * 16
	var tramos := []   # cuántas columnas en cada altura, de 0 a 16
	tramos.resize(17)
	tramos.fill(0)
	for i in n:
		var t: float = (i + 0.5) / n
		tramos[roundi(16.0 * t * t * (3.0 - 2.0 * t))] += 1
	var a: Array = tramos.slice(0, 8)
	a.sort()
	a.reverse()
	var b: Array = tramos.slice(9, 17)
	b.sort()
	var t2: Array = a + [tramos[8]] + b
	for v in 17:
		for i in t2[v]:
			_CV_T.append(v)
	return _CV_T

static func _cv_o(cv: Dictionary, px: int) -> int:
	var o: int = _cv_tabla()[cv.c * 16 + px]
	return o if cv.d else 16 - o

func _curva(k: String, tx: int, ty: int, sx: int, sy: int) -> bool:
	var cv := _cv(k)
	var mo: bool = Datos.CAL and cv.t == "R"
	var fg = Atlas.frame_de("exterior-mosaico", "mo-grass", "unica", 0, {"i": 0}) if Datos.CAL else null
	if fg:
		Atlas.dibuja(L, fg.c, Rect2(sx, sy, 16, 16), Rect2(((tx & 3) + 4 * (ty & 3)) * 16, 0, 16, 16))
	else:
		var fh = Atlas.frame_de(Atlas.cubre("tile:grass"), "grass", "unica", 0, {"i": 0})
		if fh == null:
			return false
		Atlas.dibuja(L, fh.c, Rect2(sx, sy, 16, 16))
	var nom: Array = {"R": ["roadT", "roadB"], "O": ["rotoT", "rotoB"], "P": ["pista", "pista"]}[cv.t]   # i18n-no
	var fr := []
	for n in nom:
		fr.append(Atlas.frame_de("exterior-mosaico", "mo-" + n, "unica", 0, {"i": 0}) if mo else Atlas.frame_de(Atlas.cubre("tile:" + n), n, "unica", 0, {"i": 0}))
	if fr[0] == null or fr[1] == null:
		return false
	var arriba: int = ty - cv.r
	var tyr: int = arriba + (0 if cv.d == (cv.c < CV_PIEZA >> 1) else 1)   # la fila de arriba de la calzada recta de ese lado
	var c1 := Color8(0x5a, 0xa0, 0x4e)
	var c2 := Color8(0x72, 0xbc, 0x5e)
	var y0: int = cv.r * 16
	var ov := []   # la pista, con la orilla de hierba de la recta (tierra-03 arriba, tierra-12 abajo) corrida igual que la tierra
	if cv.t == "P" and Atlas.ok:
		for mk in [3, 12]:
			ov.append(Atlas.frame_de("tileset-transiciones", "tierra-%02d" % mk, "unica", 0, {"i": 0}))
	for px in 16:
		var o := _cv_o(cv, px)
		for i in 2:
			var a: int = maxi(o + i * 16, y0)
			var b: int = mini(o + i * 16 + 16, y0 + 16)
			if a >= b:
				continue
			var ys: int = tyr + i
			var x0: int = ((tx & 3) + 4 * (ys & 3)) * 16 if mo else (variante(nom[i], tx, ys) * 16 if fr[i].c.get_width() > 16 else 0)
			Atlas.dibuja(L, fr[i].c, Rect2(sx + px, sy + a - y0, 1, b - a), Rect2(x0 + px, a - o - i * 16, 1, b - a))
			if ov.size() == 2 and ov[i] != null:
				Atlas.dibuja(L, ov[i].c, Rect2(sx + px, sy + a - y0, 1, b - a), Rect2(px, a - o - i * 16, 1, b - a))
		for q in ([] if cv.t == "P" else [[o - 1, c1], [o - 2, c2], [o + 32, c1], [o + 33, c2]]):   # la pista, sin canto (como su orilla)
			if q[0] >= y0 and q[0] < y0 + 16:
				_rect(sx + px, sy + q[0] - y0, 1, 1, q[1])
	return true

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
	Atlas.dibuja(L, f.c, Rect2(sx + (h / 7) % 9, sy + (h / 11) % 9, 8, 8), Rect2((h / 3) % 5 * 8, 0, 8, 8))

# el atrezo de la tierra (lo pidió el usuario: «le daría más atrezo a los suelos de la tierra… me parece muy plano. Lo haría más
# imperfecto»), con CAL: en una de cada TIERRA_CADA casillas de tierra o de pista, por su hash, uno de los ocho detalles de
# tierra.py (piedra, huellas, matojo seco, charco, grieta, ramita, piedrecitas, terrón)
const TIERRA_CADA := 3
const TIERRA_N := 8
func _detalle_tierra(tx: int, ty: int, sx: int, sy: int) -> void:
	var h := hash_t(tx * 3 + 1, ty * 5 + 2)
	if h % TIERRA_CADA:
		return
	var f = Atlas.frame_de(Atlas.cubre("misc:tierra"), "tierra", "unica", 0, {"i": 0})   # i18n-no
	if f == null:
		return
	Atlas.dibuja(L, f.c, Rect2(sx, sy, 16, 16), Rect2((h / 7) % TIERRA_N * 16, 0, 16, 16))

const DESF := {"tree": [6, 3], "tree2": [6, 3], "manzano": [5, 3], "monte": [4, 2], "monte2": [4, 2]}
static func desfase(o: String, x: int, y: int) -> Dictionary:
	var r = DESF.get(o)
	if r == null:
		return {"dx": 0, "dy": 0, "esp": 0}
	var h := hash_t(x, y)
	var n: int = 2 * r[0] + 1
	return {"dx": h % n - r[0], "dy": (h / n) % (2 * r[1] + 1) - r[1], "esp": (h / 97) % 2}

# el bancal, con su canto por los cuatro lados (lo pidió el usuario: «los riegos deben de ir bien centrados en el bancal»): con CAL,
# para la tierra arada, todo lo que no es bancal cuenta como hierba, y junto al camino de tierra el bancal no se funde con él
const SURCOS := ["surco", "surcoV"]   # i18n-no
func _mascara(m: Dictionary, tx: int, ty: int) -> int:
	var su: bool = Datos.CAL and SURCOS.has(m.g[ty][tx])
	var H := func(x: int, y: int) -> bool: return x >= 0 and y >= 0 and x < m.w and y < m.h and (not SURCOS.has(m.g[y][x]) if su else HIERBA.has(m.g[y][x]))
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
		Atlas.dibuja(L, f.c, Rect2(sx, sy, 16, 16))

# La playa (lo pidió el usuario: «la playa molaría que no sea todo el rato recta… más al interior será más verde todo»): la arena
# («arena» de tools/carreteras.py), clara y con su grano, por código. La orilla no va por casillas: el agua es la media de las casillas
# de agua en PLAYA_R px alrededor de cada píxel (las esquinas salen redondas) más una ola suave que se mueve; de fuera adentro, el agua,
# la espuma, la arena mojada y la seca, y donde toca la hierba, matas de duna y la orilla de la plaza (TRANS)
const PLAYA_R := 10
const PLAYA_FASES := 4
const ARENA_C := ["#ecd8a6", "#e2cb94", "#f5e6bf", "#d3b983", "#fffaf0"]
const MOJADA_C := ["#cdb27c", "#bfa36e"]
const ESPUMA_C := ["#f6fbff", "#cfe6f6"]
const MATA_C := ["#4f8f46", "#6cae58", "#8acb6c"]
var _playa_c := {}

func _vecinas(m: Dictionary, tx: int, ty: int, tipos: Array) -> Array:   # 3 × 3: ¿es de esos tipos? (fuera del mapa, la del borde)
	var r := []
	for j in 3:
		var fila := []
		for i in 3:
			var x: int = clampi(tx + i - 1, 0, int(m.w) - 1)
			var y: int = clampi(ty + j - 1, 0, int(m.h) - 1)
			fila.append(tipos.has(m.g[y][x]))
		r.append(fila)
	return r

func _playa_agua(m: Dictionary, tx: int, ty: int, sx: int, sy: int) -> void:   # el agua que toca la arena: encima, la arena que le entra
	if not Datos.CAL or not _vecinas(m, tx, ty, ["arena"]).any(func(f): return f.has(true)):
		return
	_img(_playa(tx, ty, _vecinas(m, tx, ty, ["water"]), _vecinas(m, tx, ty, HIERBA)), sx, sy)

func _playa(tx: int, ty: int, ag: Array, hi: Array) -> Image:
	var f: int = int(now / 520.0) % PLAYA_FASES
	var k := "%s|%d|%d|%d|%s|%s" % [J.S.map, tx, ty, f, ag, hi]
	if not _playa_c.has(k):
		if _playa_c.size() > 1500:   # R7: tope
			_playa_c.clear()
		_playa_c[k] = playa_img(ag, hi, tx, ty, f)
	return _playa_c[k]

# la orilla de una casilla: ag y hi, 3 × 3 de agua y de hierba alrededor (la casilla en el centro); f, la fase de la ola. Lo del agua,
# transparente (se ve el agua de debajo). Estática para las pruebas (tests/carreteras.gd)
static func playa_img(ag: Array, hi: Array, tx: int, ty: int, f: int) -> Image:
	var im := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var R := PLAYA_R
	var n: float = (2 * R + 1) * (2 * R + 1)
	var verde: bool = hi.any(func(q): return q.has(true))
	for py in 16:
		for px in 16:
			var X: int = tx * 16 + px
			var Y: int = ty * 16 + py
			var w := 0
			for j in 3:
				for i in 3:
					if ag[j][i]:
						var ax: int = maxi((i - 1) * 16, px - R)
						var bx: int = mini((i - 1) * 16 + 16, px + R + 1)
						var ay: int = maxi((j - 1) * 16, py - R)
						var by: int = mini((j - 1) * 16 + 16, py + R + 1)
						if bx > ax and by > ay:
							w += (bx - ax) * (by - ay)
			var v: float = w / n - 0.5 + 0.12 * sin(X * 0.09 + Y * 0.05) + 0.06 * sin(X * 0.23 + Y * 0.11) + 0.03 * sin(X * 0.61 - Y * 0.29) + 0.035 * sin(X * 0.37 + f * TAU / PLAYA_FASES)
			if v > 0:
				continue
			var h := hash_t(X, Y)
			var c: String
			if v > -0.07:
				c = ESPUMA_C[1 if h % 4 == 0 else 0]
			elif v > -0.2:
				c = MOJADA_C[1 if h % 6 == 0 else 0]
			elif h % 31 == 0:
				c = ARENA_C[3]
			elif h % 47 == 0 and v < -0.45:
				c = ARENA_C[4]   # una concha
			elif h % 9 == 0:
				c = ARENA_C[1]
			elif h % 13 == 0:
				c = ARENA_C[2]
			else:
				c = ARENA_C[0]
			im.set_pixel(px, py, css(c))
	if verde:   # junto a la hierba, matas de duna: más cuanto más hierba alrededor
		var nh := 0
		for q in hi:
			for b in q:
				nh += int(b)
		var hm := hash_t(tx * 7 + 3, ty * 5 + 1)
		for t in mini(1 + nh / 3, 3):
			var mx: int = 2 + (hm >> (t * 3)) % 12
			var my: int = 4 + (hm / (7 + t * 5)) % 10
			if im.get_pixel(mx, my).a == 0 or im.get_pixel(mx, my) != css(ARENA_C[0]) and im.get_pixel(mx, my) != css(ARENA_C[1]) and im.get_pixel(mx, my) != css(ARENA_C[2]):
				continue
			for d in [[0, 0, 0], [-1, -1, 1], [1, -1, 1], [0, -2, 2], [-2, -2, 2], [2, -3, 2], [0, 1, 0]]:
				var x: int = mx + d[0]
				var y: int = my + d[1]
				if x >= 0 and y >= 0 and x < 16 and y < 16 and im.get_pixel(x, y).a > 0:
					im.set_pixel(x, y, css(MATA_C[d[2]]))
	return im

# la tierra arada («surco» de tools/carreteras.py, lo pidió el usuario: «zona más de tierra»): sobre la tierra, cada 4 px un caballón
# con su luz arriba y su sombra abajo, que no va del todo recto, y algún terrón
const SURCO_C := ["#d29a62", "#a8703f", "#9e7650"]
# la recién cavada o labrada (las herramientas y la motoazada de la huerta, campo.gd): una mancha de tierra húmeda y más oscura, de
# borde irregular, con más terrones
const SURCO_V := ["#b47c4c", "#6e4a2a", "#5a3c22", "#906238"]
var _surco_c := {}

func _surco(tx: int, ty: int, v := false) -> Image:
	var k := "%d|%d|%d" % [tx, ty, int(v)]
	if not _surco_c.has(k):
		if _surco_c.size() > 600:   # R7: tope
			_surco_c.clear()
		_surco_c[k] = surco_img(tx, ty, v)
	return _surco_c[k]

static func surco_img(tx: int, ty: int, v := false) -> Image:
	var im := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for px in 16:
		var X: int = tx * 16 + px
		var o: int = 1 if sin(X * 0.21 + ty * 1.7) > 0.55 else 0   # el surco, un poco torcido
		for py in 16:
			var r: int = (py + o) % 4
			var h := hash_t(X, ty * 16 + py)
			var d: float = pow((px - 7.5) / 7.6, 2) + pow((py - 8.0) / 7.0, 2)   # la mancha cavada, con el borde roto
			var C: Array = SURCO_V if v and d < .92 + (h % 5) * .05 else SURCO_C
			if r == 0:
				im.set_pixel(px, py, css(C[0]))
			elif r == 3:
				im.set_pixel(px, py, css(C[1]))
			elif h % (11 if C == SURCO_V else 37) == 0:
				im.set_pixel(px, py, css(C[2]))   # un terrón
			elif C == SURCO_V:
				im.set_pixel(px, py, css(C[3]))
	return im

# el goteo de la huerta (campo.gd, HUERTA_MEJ.goteo): la manguera negra por el suelo desde la bomba hasta el camino, por el medio del
# camino abajo y un ramal por cada fila de bancales, con un gotero en cada sitio y, si queda agua y hay planta, la gota
const MANG_C := ["#44444e", "#1e1e24", "#76b4f2"]

# lo pidió el usuario: «Los tubos no están muy centrados que digamos no? Ajustalos bien a los bancales». Los tubos de 2 px, centrados:
# la principal por el medio de la fila de debajo de la bomba, el tronco por el medio del camino y un ramal por la línea del medio de
# cada fila de bancales (la del pie de las plantas, campo.gd), con el mismo margen a los dos lados; el gotero, en el centro de cada sitio
func _manguera_huerta() -> void:
	var ox: float = -cam.x
	var oy: float = -cam.y
	var tb := tubos_huerta(J.huerta_def(), J.HUERTA_MEJ, J.huerta_m("ibc"))
	for q in tb.h:   # de x0 a x1, con el centro en la raya entre y e y + 1
		_rect(int(q[0]) + ox, int(q[2]) + oy, int(q[1]) - int(q[0]) + 1, 1, css(MANG_C[0]))
		_rect(int(q[0]) + ox, int(q[2]) + 1 + oy, int(q[1]) - int(q[0]) + 1, 1, css(MANG_C[1]))
	for q in tb.v:
		_rect(int(q[0]) + ox, int(q[1]) + oy, 1, int(q[2]) - int(q[1]) + 1, css(MANG_C[0]))
		_rect(int(q[0]) + 1 + ox, int(q[1]) + oy, 1, int(q[2]) - int(q[1]) + 1, css(MANG_C[1]))
	var agua: bool = float(J.huerta_s().get("agua", 0)) > 0
	for i in tb.g.size():
		var gx: int = tb.g[i][0]
		var gy: int = tb.g[i][1]
		_rect(gx + ox, gy - 1 + oy, 2, 4, css(MANG_C[1]))   # el gotero, en el centro del sitio (la mata lo tapa)
		if agua and J.huerta_s().p[i] is Dictionary:
			_rect(gx + ox, gy + 3 + oy, 1, 1, css(MANG_C[2]))   # la gota

# los tubos de 2 px: h [x0, x1, y] de x0 a x1 en las filas y e y + 1; v [x, y0, y1] en las columnas x y x + 1; g [x, y], los goteros
static func tubos_huerta(H: Dictionary, HM: Dictionary, n_ibc: int) -> Dictionary:
	var r := {"h": [], "v": [], "g": []}
	var b: Array = HM.goteo.x[0]
	var bx: int = int(b[0]) * 16 + 7   # el medio de la casilla de la bomba
	var cx: int = int(H.camino) * 16 + 15   # el medio del camino (2 casillas)
	var y0: int = (int(b[1]) + 1) * 16 + 7   # la principal, por el medio de la fila de debajo de la bomba
	var xa := 9999
	var xb := 0
	for q in H.bancales:
		xa = mini(xa, int(q[0]) * 16 + MANG_MARGEN)
		xb = maxi(xb, (int(q[2]) + 1) * 16 - 1 - MANG_MARGEN)
	var filas := {}
	for s in H.sitios:
		filas[int(s[1]) * 16 - 1] = true   # el pie de las plantas: la raya entre las dos filas del bancal
	var yf: int = 0
	for f in filas:
		yf = maxi(yf, int(f))
	r.v.append([bx, (int(b[1]) + 1) * 16 - 2, y0])
	r.h.append([mini(bx, cx), maxi(bx, cx), y0])
	var xi: Array = HM.ibc.x
	for j in mini(n_ibc, xi.size()):   # los depósitos de 1000 L, de su válvula a la principal
		var ix: int = int(xi[j][0]) * 16 + 7
		r.v.append([ix, (int(xi[j][1]) + 1) * 16 - 4, y0])
		r.h.append([mini(cx, ix), maxi(cx, ix), y0])
	r.v.append([cx, y0, yf + 1])
	for f in filas:
		r.h.append([xa, xb, int(f)])
	for s in H.sitios:
		r.g.append([(int(s[0]) + 1) * 16 - 1, int(s[1]) * 16 - 1])
	return r
const MANG_MARGEN := 10   # px de bancal a cada lado del ramal: dentro de la tierra que se ve (la hierba de la orilla tapa 6)

# los de la pared, subidos a su altura (1.10, ALZA de 01b-arte.js: px)
const ALZA := {"iwin": -13, "poster": -13, "shelfW": -16, "bottles": -13, "cuadro": -13, "cartel": -13, "tarros": -16, "pizarra": -13, "cartelC": -13, "tacos": -13, "neon": -13, "fotoMaite": -10, "extrN": -14, "extrG": -14, "filtroN": -12, "ctrlN": -12, "fotoK": -13, "ojoBuey": -13, "timon": -13, "red": -13, "diana": -13, "engranaje": -13, "neonH": -13, "copas": -16, "tuboS": -13, "botesW": -16, "neonG": -13, "btPlaca": -10}   # 1.30: los de los locales; 1.32: la foto de la tía (1.33: de 2 casillas, a -10); 1.33: el equipo de la nave en la pared; 1.34: lo de las paredes de los clubs, del bajo y de los grows

# los muebles que dejan sombra en el suelo (1.10 P5, SOMBRA_OBJ de 01b-arte.js): 1 px a cada lado del dibujo en sus 2 últimas filas
# y la fila de debajo, sin pisar el objeto de la casilla de al lado ni el de debajo; se pintan con todo el suelo ya puesto
const SOMBRA_OBJ := ["fridge", "crate", "table", "btable", "stool", "mesaTb", "taburTb", "barrilTb", "plantDeco", "lab", "lab2", "pc", "display", "counter", "barcounter", "jukebox", "bench", "bedB", "vitrina", "mesita", "barraD", "mesaV", "estanteN", "secadero", "altavoz", "trim", "prensaM", "tamizM", "mallas", "lavadora", "staticM", "armS", "mesaS"]  # i18n-no
const VALLAS := ["fence", "baranda"]

# la pieza de una valla por las de su clase de al lado: N = 1, E = 2, S = 4, O = 8
# la pieza del seto de PixelLab (pixellab_setos.py) para el seto de la calle: los setos de los mapas van en tramos de lado a lado; el
# tramo, alterno (setoH, setoH2) y con su remate redondo en cada punta (setoHi a la izquierda, setoHd a la derecha); suelto, el tramo
static func seto_pieza(mo: Array, tx: int, ty: int) -> String:
	var w: bool = tx > 0 and mo[ty][tx - 1] == "seto"   # i18n-no
	var e: bool = tx + 1 < mo[ty].size() and mo[ty][tx + 1] == "seto"   # i18n-no
	if w and not e:
		return "setoHd"   # i18n-no
	if e and not w:
		return "setoHi"   # i18n-no
	return "setoH2" if tx % 2 else "setoH"   # i18n-no

static func mascara_valla(mo: Array, o: String, tx: int, ty: int) -> int:
	var es := func(x: int, y: int) -> bool: return y >= 0 and y < mo.size() and x >= 0 and x < mo[y].size() and mo[y][x] == o
	return (1 if es.call(tx, ty - 1) else 0) | (2 if es.call(tx + 1, ty) else 0) | (4 if es.call(tx, ty + 1) else 0) | (8 if es.call(tx - 1, ty) else 0)

func _arte_obj(o: String, tx: int, ty: int, list: Array, sombras := []) -> void:
	var seca: bool = Datos.CAL and o.begins_with("hgs-")   # la planta muerta de la huerta (campo.gd): la de hg, parda
	if seca:
		o = "hg-" + o.substr(4)
	var gr = Atlas.cubre("obj:" + o)
	if not gr:
		return
	var an = Atlas.sobre.get("obj:" + o)
	var d := desfase(o, tx, ty)
	var md = J.mesa_de(o, tx, ty) if o == "mesaN" or o == "mesaKC" else null   # la mesa de la nave o de KAIA: {Me, fm, foco}  # i18n-no
	var fm: int = int(md.fm) if md != null else 0
	var pl = _plantas_mesa(gr, md.Me, fm) if fm else null   # 1.31: las plantas de la mesa de la nave, encima
	var sp: String = ("mesaN-%d" % mini(fm, 1)) if md != null else J.sprite_local(J.deco_sprite(o))   # 1.16: su tapizado o lámina; 1.30: la mesa de la nave, vacía o plantada; 1.34: lo de los locales (sprite_local)  # i18n-no
	var f = Atlas.frame_de(an[0][0], an[0][1], "unica", now, {"bucle": true}) if an else Atlas.frame_de(gr, sp, "unica", 0, {"i": 0, "esp": d.esp})
	var ge = Atlas.cubre("obj:e-" + o) if Datos.CAL and not an else null   # 1.47: a escala con el protagonista (escala.py), solo con CAL
	var fd = _detalle_obj(o, tx) if Datos.CAL and not an else null   # 1.48: con lo que trae encima (detalle.py)
	if fd != null:
		f = fd
		ge = null
	if ge:
		var fe = Atlas.frame_de(ge, "e-" + sp, "unica", 0, {"i": 0, "esp": d.esp})
		if fe == null:
			fe = Atlas.frame_de(ge, "e-" + o, "unica", 0, {"i": 0, "esp": d.esp})
		if fe != null:
			f = fe
	if Datos.CAL and o in VALLAS:   # lo pidió el usuario: las vallas conectan en x y en y (vallas.py: una pieza por sus vecinas N, E, S, O)
		var fv = Atlas.frame_de("vallas", "%s-%d" % [o, mascara_valla(J.MAPS[J.S.map].o, o, tx, ty)], "unica", 0, {"i": 0})
		if fv != null:
			f = fv
	if Datos.CAL and o == "seto":   # lo pidió el usuario («el seto… hicimos otro ya»): el de PixelLab de la huerta (seto-huerta), por tramos
		var fs = Atlas.frame_de("seto-huerta", seto_pieza(J.MAPS[J.S.map].o, tx, ty), "unica", 0, {"i": 0})
		if fs != null:
			f = fs
	if Datos.CAL and o == "mesita":   # 1.47 (lo pidió el usuario): las dos mesitas de los sofás, una mesa baja de frente a 3/4 como los sofás
		var mo: Array = J.MAPS[J.S.map].o
		var izq: bool = tx > 0 and mo[ty][tx - 1] == "mesita"
		var der: bool = tx + 1 < mo[ty].size() and mo[ty][tx + 1] == "mesita"
		var nl := 0   # en una fila de mesitas, de dos en dos desde la izquierda
		var q := tx - 1
		while q >= 0 and mo[ty][q] == "mesita":
			nl += 1
			q -= 1
		if izq and nl % 2 == 1:
			return
		if der:
			var fw = Atlas.frame_de("ocio-ancho", "w-" + sp, "unica", 0, {"i": 0})
			if fw == null:
				fw = Atlas.frame_de("ocio-ancho", "w-mesita", "unica", 0, {"i": 0})
			if fw != null:
				f = fw
	if f == null and not an and sp != o:
		f = Atlas.frame_de(gr, o, "unica", 0, {"i": 0, "esp": d.esp})
	if f == null:
		return
	if Datos.CAL and o.begins_with("hg-") and not seca:   # la de la huerta, con el tono de hoja y el cogollo de su variedad
		var hi: int = J.huerta_idx(tx, ty)
		if hi >= 0 and J.huerta_s().p[hi] is Dictionary:
			f = _tinte_planta(f, J.huerta_s().p[hi])
	if seca:
		f = {"c": _seca(f.c), "cel": f.cel}
	var xp: int = tx * 16 + 8 + d.dx - cam.x
	if Datos.CAL and o == "bench":   # 1.50: el banco de 1,6 m sobresale de su casilla; pegado al borde del mapa, hacia dentro
		xp += 5 if tx == 0 else (-5 if tx == int(J.MAPS[J.S.map].w) - 1 else 0)
	var yp: int = ty * 16 + 15 + d.dy + int(ALZA.get(o, 0)) - cam.y
	if o in SOMBRA_OBJ:
		var m: Dictionary = J.MAPS[J.S.map]
		var ob := func(x: int, y: int) -> bool: return y >= 0 and y < m.o.size() and x >= 0 and x < m.o[y].size() and m.o[y][x] != null and m.o[y][x] != ""
		var bb: Array = Arte.caja(f.c)
		var x0: int = Datos.jsround(xp - f.cel.ancla[0]) + int(bb[0])
		var x1: int = x0 + int(bb[1]) - int(bb[0])
		var sx: int = tx * 16 - cam.x
		if x0 - 1 >= sx or not ob.call(tx - 1, ty):
			sombras.append([x0 - 1, yp - 1, 1, 2])
		if x1 + 1 <= sx + 15 or not ob.call(tx + 1, ty):
			sombras.append([x1 + 1, yp - 1, 1, 2])
		if not ob.call(tx, ty + 1):
			sombras.append([x0, yp + 1, x1 - x0 + 1, 1])
	var ex := []   # 1.34: las bandejas del bajo, en su fase
	if o == "baldaS":
		for b in J.bandejas_balda(tx):
			var fb = Atlas.frame_de(gr, b, "unica", 0, {"i": 0})
			if fb != null:
				ex.append(fb)
	if mide != null:
		mide.append({"o": o, "x": tx, "y": ty, "c": f.c, "px": Datos.jsround(xp - f.cel.ancla[0]), "py": Datos.jsround(yp - f.cel.ancla[1])})
		return
	if f.cel.h > 16:
		var pie: int = ty * 16 + mini(0, d.dy)
		list.append([pie, func():
			var mx: int = Datos.jsround(xp - f.cel.ancla[0])
			var my: int = Datos.jsround(yp - f.cel.ancla[1])
			_con_alfa(tapa_pj(f.c, mx, my, pie) or (pl != null and tapa_encima(mx, my, f.c.get_width(), pie)), _pinta_mesa.bind(f, xp, yp, pl, md, fm, ex))])   # corrido hacia abajo, no pasa delante de quien está en su fila
	else:
		_pinta_mesa(f, xp, yp, pl, md, fm, ex)

# la planta seca: los mismos píxeles en cuatro pardos por su luz (el contorno, el más oscuro)
const SECA := [Color8(48, 32, 20), Color8(102, 72, 40), Color8(146, 110, 64), Color8(184, 152, 100)]
static var _seca_c := {}
static func _seca(c: Image) -> Image:
	var k := c.get_instance_id()
	if not _seca_c.has(k):
		var o: Image = c.duplicate()
		for y in o.get_height():
			for x in o.get_width():
				var q: Color = o.get_pixel(x, y)
				if q.a > 0:
					var l: float = (q.r + q.g + q.b) / 3.0
					o.set_pixel(x, y, SECA[0 if l < .22 else (1 if l < .42 else (2 if l < .62 else 3))])
		_seca_c[k] = o
	return _seca_c[k]

# (lo pidió el usuario: «que se note que es el sprite y lo que trae»): d-<objeto>-<mapa>-<tramo>, d-<objeto>-<mapa>,
# d-<objeto>-<tramo> o d-<objeto>, de detalle.py (grupos detalle-alto y detalle-16); el tramo, por la columna (los mostradores)
var _det_c := {}
func _detalle_obj(o: String, tx: int):
	var mp: String = J.S.map
	var key := "%s|%s|%d" % [o, mp, tx % 3]
	if _det_c.has(key):
		return _det_c[key]
	var r = null
	for g in ["detalle-alto", "detalle-16"]:
		for n in ["d-%s-%s-%d" % [o, mp, tx % 3], "d-%s-%s" % [o, mp], "d-%s-%d" % [o, tx % 3], "d-" + o]:
			if r == null:
				r = Atlas.frame_de(g, n, "unica", 0, {"i": 0})
	_det_c[key] = r
	return r

func _pinta_mesa(f, xp: float, yp: float, pl, md = null, fm := 0, ex := []) -> void:
	_pinta(f, xp, yp)
	pl = copa_bajo_foco(pl, int(yp + cam.y), md)
	if pl != null:
		_pinta(pl, xp, yp)
	if md != null and md.foco != null:
		_focos_mesa(String(md.foco), xp + cam.x, yp + cam.y, fm, pl.c if pl != null else null, int(md.get("techo", 0)))   # 1.33: y sus focos, colgados encima
	for fb in ex:   # 1.34: las bandejas del bajo
		_pinta(fb, xp, yp)

# sin sitio para colgar el foco encima de la copa (la sala de KAIA, con poco techo), las plantas pierden filas enteras, como en la
# vista C (Arte.aplasta): la punta queda a FOCO_AIRE px del foco a su altura más baja; ym, el ancla de la mesa en el mapa
func copa_bajo_foco(pl, ym: int, md):
	if not Datos.CAL or pl == null or md == null or md.foco == null:
		return pl
	var tope: int = int(md.get("techo", 0)) + int(J.D.FOCO_POLEA) + 12 + int(J.D.FOCO_AIRE) + 1
	var top: int = ym - 47 + Arte.fila_arriba(pl.c)
	if top >= tope:
		return pl
	var o: Dictionary = pl.duplicate()
	o.c = Arte.aplasta(pl.c, Arte.alto(pl.c) - (tope - top))
	return o

# los focos de la mesa i de la nave (1.33, focosMesa de 11j-locales; xp, yp: el ancla de la mesa en el mapa; pl: la imagen de sus
# plantas): dos, colgados de sus poleas a FOCO_AIRE px por encima de la punta más alta (la primera fila con algo de las plantas) o,
# sin plantas, a la altura de un esqueje; la cuerda del techo se desvanece hacia arriba en FOCO_DEG pasos; t0: dónde empieza el techo
# en el mapa (las mesas de una segunda fila, más abajo: su cuerda no cruza las de delante de la pared)
func _focos_mesa(foco: String, xp: float, yp: float, fm: int, pl, t0 := 0) -> void:
	var D = J.D
	var g = Atlas.cubre("obj:focoN")  # i18n-no
	var f = Atlas.frame_de(g, "focoN-%s-%d" % [foco, 1 if fm else 0], "unica", 0, {"i": 0}) if g else null  # i18n-no
	if f == null:
		return
	var top: float = (yp - 47 + Arte.fila_arriba(pl)) if pl != null else (yp - 47 + 25 - int(D.FOCO_ALTO))
	var yb: float = maxf(t0 + int(D.FOCO_POLEA) + 12, top - int(D.FOCO_AIRE) - 1)
	for dx in D.FOCO_DX:
		for e in _poleas_nave(int(xp) + int(dx), int(yb), t0):
			_rect(e[0] - cam.x, e[1] - cam.y, e[2], e[3], e[4])
		_pinta(f, xp + 8 + int(dx) - cam.x, yb - cam.y)

# poleasNave: dos cuerdas del techo (con su degradado) a dos poleas a FOCO_POLEA px, y de cada polea, el tramo que baja al asa del
# foco y el del tirador
func _poleas_nave(x0: int, yb: int, t0 := 0) -> Array:
	var D = J.D
	var K: Color = Arte.VC_CUERDA
	var M: Color = Arte.VC_POLEA[0]
	var H: Color = Arte.VC_POLEA[1]
	var y0 := t0 + int(D.FOCO_POLEA)
	var dg := float(D.FOCO_DEG)
	var asa: int = yb - 15 + int(D.FOCO_ASA)
	var o := []
	for ls in [[x0 + 1, -1], [x0 + 14, 1]]:
		var X: int = ls[0]
		var cx: int = X + 2 * ls[1]
		var T: int = X + 4 * ls[1]
		for y in range(t0, y0):
			o.append([cx, y, 1, 1, Color8(28, 29, 34, Datos.jsround(ceil(float(y - t0 + 1) / (y0 - t0) * dg) / dg * 255))])
		o.append_array([[X, y0 + 3, 1, asa - (y0 + 3), K], [T, y0 + 3, 1, 8, K], [T - 1, y0 + 11, 3, 3, K], [T, y0 + 12, 1, 1, M],
			[cx - 1, y0 + 1, 3, 5, K], [cx - 2, y0 + 2, 5, 3, K], [cx - 1, y0 + 2, 3, 3, M], [cx, y0 + 3, 1, 1, K], [cx - 1, y0 + 2, 1, 1, H]])
	return o.filter(func(e): return e[3] > 0)

# el riego de la nave (1.35, mangueraNave): el grifo, la tubería por el pie de la pared y, en cada mesa, su llave o su electroválvula
# y la bajada; 1.37: guiada del tanque a cada mesa, donde estén (manguera_nave, mundo.gd)
func _manguera_nave() -> void:
	for e in J.manguera_nave():
		_rect(float(e[0]) - cam.x, float(e[1]) - cam.y, e[2], e[3], css(e[4]))

# las plantas de la mesa i de la nave en la fase fm (1.31, plantasMesa de 01b-arte): las de su porte (porte_planta, por el % índica de
# su fenotipo) con el tono de hoja y el color de cogollo de la variedad, como en la vista C (hoja_planta, vc_tonos y la rampa de
# carpa-c-plantas-a); el fotograma, con su imagen ya cambiada
func _plantas_mesa(gr, Me, fm: int):
	var S_: Dictionary = J.S
	if not Me:
		return null
	var p := {"sid": J.lot_sid(Me.k), "f": Me.get("f")}
	var f = Atlas.frame_de(gr, "plantasN-1" if fm == 1 else "plantasN-%d-%s" % [fm, Datos.porte_planta(S_, p)], "unica", 0, {"i": 0})  # i18n-no
	if f == null:
		return null
	return _tinte_planta(f, p)

# los colores de la planta A del dibujo (las de la nave, las de la huerta) pasados a los de la variedad de p: el cogollo por la rampa
# de la vista C y los verdes por el tono de su hoja
func _tinte_planta(f: Dictionary, p: Dictionary) -> Dictionary:
	var S_: Dictionary = J.S
	var s = Datos.strain(S_, p.sid)
	var rk = Atlas.d.get("rampas", {}).get("carpa-c-plantas-a", {}).get("cogollo")
	if rk == null or s == null:
		return f
	var hj := Datos.hoja_planta(S_, p)
	var sc := Datos.color_cog(S_, p)
	var m := {rk.rampa[0]: Datos.shade(sc, 50), rk.rampa[1]: sc, rk.rampa[2]: Datos.shade(sc, -60)}
	m.merge(Datos.vc_tonos(hj), true)
	var o: Dictionary = f.duplicate()
	o.c = Atlas.con_rampa(f.c, m, "g|" + sc + "|" + hj)
	return o

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
			var abierta: bool = J.P.x >= b.doorX and J.P.x <= b.doorX + (1 if b.get("ancha") else 0) and (J.P.y == dy or J.P.y == dy + 1) and not J.puerta_cerrada(m, b)
			var p = Atlas.frame_de(gp, "puerta", "unica", 0, {"i": -1 if abierta else 0})
			if p:
				_img(_sin_pared(p.c, "%s|%d" % [gp, p.i]) if b.get("mascara") else p.c, b.doorX * 16 - 8 + b.get("dx", 0) - cam.x, (dy + 1) * 16 - 32 - cam.y)
		if b.get("rotulo") and Atlas.cubre("obj:" + b.rotulo):   # 1.47: la T del estanco, colgada encima de la puerta
			var fr = Atlas.frame_de(Atlas.cubre("obj:" + b.rotulo), b.rotulo, "unica", 0, {"i": 0})
			if fr:
				_img(fr.c, _rotulo_x(b) - cam.x, (b.y0 + b.h - 1) * 16 - 31 - cam.y)

# (lo pidió el usuario: «desde el que se ve el piso de abajo, en la cristalera del suelo, transparente»): en el reservado, la gente
# que baila abajo (en su sitio de la pista, con su vaivén) y, encima, el cristal: más oscuro que la pista, con sus juntas y el brillo
var _bailan := []
func _cristalera(m: Dictionary, tx0: int, ty0: int) -> void:
	# (lo pidió el usuario: «que se vea algo más que la pista»): por el cristal, lo de abajo entero en su sitio, recortado al
	# cristal: la barra, los altavoces, la gente de la barra y de alrededor y los que bailan (los de baila*, moviéndose)
	var g0 := Vector2i(m.w, m.h)
	var g1 := Vector2i(-1, -1)
	for ty in m.h:
		for tx in m.w:
			if m.g[ty][tx] == "cristalV":
				g0 = Vector2i(mini(g0.x, tx), mini(g0.y, ty))
				g1 = Vector2i(maxi(g1.x, tx), maxi(g1.y, ty))
	if g1.x < 0:
		return
	var clip := Rect2i(g0.x * 16 - cam.x, g0.y * 16 - cam.y, (g1.x - g0.x + 1) * 16, (g1.y - g0.y + 1) * 16)
	var abajo: Dictionary = J.MAPS.disco
	var lista := []
	for ty in range(g0.y, mini(int(abajo.h), g1.y + 3)):
		for tx in range(maxi(0, g0.x - 1), mini(int(abajo.w), g1.x + 2)):
			var o = abajo.o[ty][tx]
			if not o:
				continue
			var gr = Atlas.cubre("obj:" + o)
			if not gr:
				continue
			var f = Atlas.frame_de(gr, o, "unica", 0, {"i": 0})
			var ge = Atlas.cubre("obj:e-" + o)
			if ge:
				var fe = Atlas.frame_de(ge, "e-" + o, "unica", 0, {"i": 0})
				if fe != null:
					f = fe
			if f == null:
				continue
			var x0: int = Datos.jsround(tx * 16 + 8 - cam.x - f.cel.ancla[0])
			var y0: int = Datos.jsround(ty * 16 + 15 - cam.y - f.cel.ancla[1])
			lista.append([ty * 16, _img_clip.bind(f.c, x0, y0, Rect2i(0, 0, f.c.get_width(), f.c.get_height()), clip, Color.WHITE)])
	if _bailan.is_empty():
		for d in J.D.NPCDEF:
			if d.map == "disco" and d.id != "gorila" and J.npc_cond(d):
				_bailan.append(J.mk_ent(d))
	for i in _bailan.size():
		var e: Dictionary = _bailan[i]
		if e.id.begins_with("baila"):
			var t: float = now / 1000.0 + i * 1.7
			e.px = e.def.x * 16.0 + Datos.jsround(sin(t * 1.3) * 6)
			e.py = e.def.y * 16.0 + Datos.jsround(cos(t * .9) * 3)
			e.dir = ["down", "left", "down", "right"][int(t * .8 + i) % 4]
		var ex: int = Datos.jsround(e.px - cam.x) + 8
		var ey: int = Datos.jsround(e.py - cam.y) + 15
		if clip.has_point(Vector2i(ex, ey)):
			lista.append([e.py, _pj.bind(e, e.look, false, 320.0)])
	lista.sort_custom(func(a, b): return a[0] < b[0])
	for q in lista:
		q[1].call()
	var fr := Color(0.86, 0.94, 1.0, 0.5)
	for ty in range(maxi(0, ty0), mini(int(m.h), ty0 + ceili(SH / 16.0) + 1)):
		for tx in range(maxi(0, floori(cam.x / 16.0)), mini(int(m.w), floori(cam.x / 16.0) + ceili(J.SW / 16.0) + 1)):
			if m.g[ty][tx] != "cristalV":
				continue
			var sx: int = tx * 16 - cam.x
			var sy: int = ty * 16 - cam.y
			_rect(sx, sy, 16, 16, Color(0.03, 0.01, 0.08, 0.42))
			_rect(sx, sy, 16, 16, Color(0.62, 0.84, 1.0, 0.12))
			_rect(sx, sy, 16, 1, fr)
			_rect(sx, sy, 1, 16, fr)
			_rect(sx + 3, sy + 4, 4, 1, Color(1, 1, 1, 0.22))
			_rect(sx + 3, sy + 5, 2, 1, Color(1, 1, 1, 0.22))
			for q in [[0, -1, sx, sy - 1, 16, 1], [0, 1, sx, sy + 16, 16, 1], [-1, 0, sx - 1, sy, 1, 16], [1, 0, sx + 16, sy, 1, 16]]:   # el marco de cromo alrededor
				var nx: int = tx + int(q[0])
				var ny: int = ty + int(q[1])
				if ny < 0 or ny >= m.h or nx < 0 or nx >= m.w or m.g[ny][nx] != "cristalV":
					_rect(q[2], q[3], q[4], q[5], css("#c8ccd0"))

# El rótulo del estanco, centrado encima de su puerta
func _rotulo_x(b: Dictionary) -> int:
	var E: Dictionary = {}
	for k in J.D.ESTANCO.k:
		if J.D.ESTANCO.k[k].map == J.S.map:
			E = J.D.ESTANCO.k[k]
	return int(E.get("x", b.x0)) * 16 + (8 if E.get("ancha") else 0)

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
	for e in Vista.temporizador_mapa(xc - (Datos.jsround(J.D.CARPAS[t.t].cm[0] * .16) >> 1), yb, Cultivo.ciclo_de(J.S.carpas[t.ci])):
		_rect(e[0], e[1], e[2], e[3], e[4])
	var f = Atlas.foto_misc("carpa-" + t.t + "-mapa")
	if f:
		_con_alfa(tapa_pj(f.c, Datos.jsround(xc - f.cel.ancla[0]), Datos.jsround(yb - f.cel.ancla[1]), t.y * 16), _pinta.bind(f, xc, yb))
	else:
		var c := Procedural.carpa_mapa(t.t)
		_img(c, xc - (c.get_width() >> 1), yb - c.get_height() + 1)
	if Cultivo.foco_on(J.S, t.ci):
		var tipo: String = J.D.FOCOS[J.S.carpas[t.ci].foco].tipo
		_rect(xc - 3, yb + 1, 6, 1, css(J.D.FOCO_LUZ[tipo] + ".6)"))

# (lo pidió el usuario: «debería salir un tubo de extracción de cada carpa hacia una de las ventanas»): con el extractor puesto,
# el tubo flexible de aluminio sale por arriba de la carpa, corre por lo alto de la pared y baja a una rejilla en la ventana más
# cercana que no tape la propia carpa
func _tubos_casa(m: Dictionary) -> void:
	for q in ventanas_tubos(m):
		var t = q[0]
		var xc: int = q[1]
		var wx: int = q[2]
		# (lo pidió el usuario): sube de la boca del techo de la carpa al techo de la habitación, corre pegado al techo (por
		# encima de cuadros y puertas) y baja a la ventana, donde entra por una placa de chapa que sustituye la hoja de arriba; la
		# de abajo sigue siendo cristal
		var f = Atlas.foto_misc("carpa-" + t.t + "-mapa")
		# (lo pidió el usuario: «los tubos no llegan a las carpas, falta 1 o 2 píxeles»): la boca, en la primera fila opaca del
		# dibujo de la carpa tal como lo pinta _carpa_mapa (por su ancla), y el tubo un píxel dentro del techo
		var arriba: int = (t.y * 16 + 15 - int(f.cel.ancla[1]) + f.c.get_used_rect().position.y if f else t.y * 16 + 15 - 40) + 1
		var yc: int = -cam.y   # el techo
		var yw: int = 16 + 15 + int(ALZA.iwin) - 15 - cam.y   # la fila de arriba del dibujo de la ventana (iwin, en la fila 1)
		var xa: int = xc - cam.x
		var xb: int = wx - cam.x
		_tubo_codos(xa, xb, yc, arriba - cam.y, yw + 6)
		# la placa: la hoja de arriba de la ventana (filas 2 a 7 del dibujo), de chapa con la boca del tubo en medio
		_rect(xb - 7, yw + 2, 14, 6, css("#2a2a34"))
		_rect(xb - 6, yw + 3, 12, 4, css("#b4b8c0"))
		_rect(xb - 6, yw + 3, 12, 1, css("#e4e8ee"))
		for k in 3:
			_rect(xb - 5 + k * 4, yw + 5, 2, 1, css("#7a7e86"))   # los remaches
		_rect(xb - 3, yw + 3, 7, 2, css("#5a5e66"))   # la abrazadera en la placa
		_rect(xa - 3, arriba - cam.y - 2, 7, 2, css("#5a5e66"))   # la abrazadera en la boca de la carpa

# [carpa, x de su centro, x de su ventana] de cada carpa con extractor de la casa (1.55.3)
func ventanas_tubos(m: Dictionary) -> Array:
	var win := []
	for x in int(m.w):
		if m.o[1][x] == "iwin":
			win.append(x * 16 + 8)
	# A cada carpa con extractor, su ventana (que no quede detrás de ella), con los tramos de techo sin pisarse y lo más
	# cortos posible; si hay más carpas que ventanas, se comparten
	var cs := []
	for t in m.get("carpas", []):
		if Cultivo.kit_de(J.S.carpas[t.ci]) == "":
			continue
		var xc: int = (t.x0 + t.x1 + 1) * 8
		var half: int = Datos.jsround(J.D.CARPAS[t.t].cm[0] * .16) >> 1
		var ok := win.filter(func(w): return w < xc - half - 4 or w > xc + half + 4)
		if ok.size():
			cs.append({"t": t, "xc": xc, "ok": ok})
	var mejor := {"c": INF, "a": []}
	_asigna_ventanas(cs, 0, [], mejor)
	var r := []
	for i in cs.size():
		r.append([cs[i].t, cs[i].xc, mejor.a[i]])
	return r

func _asigna_ventanas(cs: Array, i: int, a: Array, mejor: Dictionary) -> void:
	if i == cs.size():
		var c := 0.0
		for j in a.size():
			c += absi(a[j] - cs[j].xc)
			for k in j:
				if a[k] == a[j]:
					c += 500   # la misma ventana
				elif maxi(mini(a[j], cs[j].xc), mini(a[k], cs[k].xc)) < mini(maxi(a[j], cs[j].xc), maxi(a[k], cs[k].xc)):
					c += 1000   # los tramos de techo, uno encima de otro
		if c < mejor.c:
			mejor.c = c
			mejor.a = a.duplicate()
		return
	for w in cs[i].ok:
		_asigna_ventanas(cs, i + 1, a + [w], mejor)

# (lo pidió el usuario: «en las curvas o giros del tubo no se deben cortar»): de la carpa (xa, hasta ya) al techo (yc), por el
# techo y abajo a la ventana (xb, hasta yb), con un codo curvo en cada giro en vez de dos tramos que se pisan
func _tubo_codos(xa: int, xb: int, yc: int, ya: int, yb: int) -> void:
	if absi(xb - xa) < 7:   # la ventana encima: recto
		_tubo(xa - 2, yc, 5, ya - yc, false)
		_tubo(xb - 2, yc, 5, yb - yc, false)
		return
	var xl := mini(xa, xb)
	var xr := maxi(xa, xb)
	var yl: int = ya if xl == xa else yb
	var yr: int = yb if xl == xa else ya
	var hueco: int = (xr - xl - 5) >> 1   # lo que cabe de curva a cada lado sin que se toquen
	var rl: int = clampi(mini(yl - yc - 6, hueco), 0, 3)
	var rr: int = clampi(mini(yr - yc - 6, hueco), 0, 3)
	_tubo(xl + 3 + rl, yc, xr - 2 - rr - (xl + 3 + rl), 5, true, true)
	_tubo(xl - 2, yc + 5 + rl, 5, yl - (yc + 5 + rl), false, true)
	_tubo(xr - 2, yc + 5 + rr, 5, yr - (yc + 5 + rr), false, true)
	_codo(xl - 2, yc, rl, 1)
	_codo(xr - 2, yc, rr, -1)

# el codo: un cuarto de toro de 5 px de grueso y ri de radio por dentro, con el tramo de bajada en x0..x0+4 desde el techo y0; lado 1,
# el del techo sale a la derecha; -1, a la izquierda. Arriba, la luz como en el tramo del techo; en la bajada, como en la bajada
const TUBO_C := ["#2a2a34", "#e4e8ee", "#b4b8c0", "#8a8e98", "#2a2a34"]
func _codo(x0: int, y0: int, ri: int, lado: int) -> void:
	var R := 5.0 + ri
	var pv := Vector2(x0 - ri if lado < 0 else x0 + 5 + ri, y0 + 5 + ri)   # el centro de la curva, en la esquina de dentro
	for j in 5 + ri:
		for i in 5 + ri:
			var px: int = (x0 - ri + i) if lado < 0 else (x0 + i)
			var py: int = y0 + j
			var dx := absf(px + 0.5 - pv.x)
			var dy := pv.y - (py + 0.5)
			var r := sqrt(dx * dx + dy * dy)
			if r > R + 0.35 or r < ri - 0.35:
				continue
			var b := clampi(int(R - r), 0, 4)
			var c: String
			if b == 0 or b == 4:
				c = TUBO_C[0]
			elif dy > dx:   # en el tramo del techo: la fila
				c = TUBO_C[b]
			else:   # en la bajada: la columna, con la luz a la izquierda
				c = TUBO_C[4 - b if lado < 0 else b]
			_rect(px, py, 1, 1, css(c))

# un tramo de tubo flexible de aluminio (5 px de grueso: contorno, luz, cuerpo, sombra, contorno) con sus aros cada 3 px
# (1.57: abierto, sin el canto de los extremos, para empalmar con los codos)
func _tubo(x: int, y: int, w: int, h: int, horiz: bool, abierto := false) -> void:
	if w <= 0 or h <= 0:
		return
	_rect(x, y, w, h, css("#2a2a34"))
	var e := 0 if abierto else 1
	if horiz:
		_rect(x + e, y + 1, w - 2 * e, 1, css("#e4e8ee"))
		_rect(x + e, y + 2, w - 2 * e, 1, css("#b4b8c0"))
		_rect(x + e, y + 3, w - 2 * e, 1, css("#8a8e98"))
		for xx in range(x + 2, x + w - 1, 3):
			_rect(xx, y + 1, 1, 3, css("#9aa0a8"))
	else:
		_rect(x + 1, y + e, 1, h - 2 * e, css("#e4e8ee"))
		_rect(x + 2, y + e, 1, h - 2 * e, css("#b4b8c0"))
		_rect(x + 3, y + e, 1, h - 2 * e, css("#8a8e98"))
		for yy in range(y + 2, y + h - 1, 3):
			_rect(x + 1, yy, 3, 1, css("#9aa0a8"))

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
		if cache.size() > 512:   # R7: tope
			cache.clear()
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
func _aparcado(k: String, x: int, y: int, d: String, dx := 0) -> void:   # dx: en la plaza de 2 casillas, en medio
	var xp: int = x * 16 - cam.x + 8 + dx
	var yp: int = y * 16 - cam.y + 15
	var dd: String = DIR4.get(d, "south")
	for p in ["-atras", "-delante"]:
		var f = Atlas.frame_de("vehiculos", k + p, dd, 0, {"i": 0})
		if f:
			_pinta(f, xp, yp)

func _pj(e: Dictionary, look, isP: bool, dur: float) -> void:
	var gr = J.grupo_pj() if isP else Atlas.grupo_look(look)
	if not gr:
		return
	var esc = J.ESC if isP and Datos.CAL else null   # por la escalera del paso subterráneo de Zorroza: a pie y cortado por abajo
	var v = null if esc != null else J.vehiculo() if isP else e.get("veh")   # 1.57: los coches de la demo del título, con su conductor; en la calle, con el patinete o la bici: detrás, él (subido) y delante (dibujarPJ)
	if v and not Atlas.anim_de("vehiculos", v + "-atras"):
		v = null
	var f = _monta_frame(e, gr, v, dur) if v else _pj_frame(e, gr, isP, dur)
	if f == null:
		return
	if isP:
		f = J.ropa_c(f, gr)   # ropa y pelo (1.21)
	var xp: int = Datos.jsround(e.px - cam.x) + 8
	var yp: int = Datos.jsround(e.py - cam.y) + 15
	if esc != null and int(esc.h) > 0:   # hundido h px en la escalera: lo de debajo de los peldaños no se ve (sin sombra)
		var im: Image = f.c
		var hv: int = int(f.cel.ancla[1]) + 1 - int(esc.h)
		if hv > 0:
			Atlas.dibuja(L, im, Rect2(Datos.jsround(xp - f.cel.ancla[0]), Datos.jsround(yp - f.cel.ancla[1]) + int(esc.h), im.get_width(), hv), Rect2(0, 0, im.get_width(), hv))
		return
	var sm := Color8(0, 0, 0, 56)
	_rect(xp - 4, yp - 1, 8, 3, sm)
	_rect(xp - 5, yp, 10, 1, sm)
	if v:
		var o := {"i": mini(1, floori(e.t / dur * 2)) if e.moving else 0}
		var d: String = DIR4[e.dir]
		var va = Atlas.frame_de("vehiculos", v + "-atras", d, 0, o)
		var vd = Atlas.frame_de("vehiculos", v + "-delante", d, 0, o)
		if va:
			_pinta(va, xp, yp)
		var V: Dictionary = J.D.VEHICULOS[v]
		if V.has("corta"):   # sentado (1.43): de la cintura para arriba; con techo, solo por dentro de la cabina (1.43.1)
			var cy := int(V.corta)
			var im: Image = f.c
			if V.get("cabina") and va:
				im = _en_cabina(f, va, int(V.sube), cy)
			Atlas.dibuja(L, im, Rect2(Datos.jsround(xp - f.cel.ancla[0]), Datos.jsround(yp - int(V.sube) - f.cel.ancla[1]), im.get_width(), cy), Rect2(0, 0, im.get_width(), cy))
		else:
			_pinta(f, xp, yp - int(V.sube))
		if vd:
			_pinta(vd, xp, yp)
	else:
		_pinta(f, xp, yp)
	var a = e.get("act")
	if a and a.get("humo") and not a.get("humoHecho") and f.i >= a.humo.frame:
		a.humoHecho = 1
		J.lanzar_vfx(a.humo.vfx, e.px + 8 + a.humo.off[0], e.py + 15 + a.humo.off[1], now, J.S.map, true)

# sentado (1.47; 1.55.3, a la altura de cada asiento, SENT_GEO): el fotograma quieto, en la casilla del asiento
var _sent_img := {}
# De frente, sentado: los muslos encima del asiento (vistos desde arriba), las rodillas, las espinillas colgando
# delante del canto (entre ellas se ve el banco) y las zapatillas en el suelo; de x 9 a 22 del fotograma, bajo el torso
const SENT_PIERNAS := ["anooonaanooona", "anonnnaannnona", ".annna..annna.", ".annna..annna.", ".ahhha..ahhha.", "..aaa....aaa.."]
# De espaldas en el taburete de la barra (asiento a 72 cm, 11 px): el culo encima del asiento y, a los lados del pie,
# las espinillas colgando hasta el reposapiés con las zapatillas; delante del taburete. TABURETE_SUBE: lo que sube del suelo
# la fila de los pies del fotograma; las zapatillas, en el reposapiés, y el culo, 6 filas más arriba, en el asiento
# sentado al ordenador, de espaldas (lo pidió el usuario: «como coloca los brazos cuando usa el ordenador Gaming o el de la
# tía» y «Has primero el Sprite del jugador con los brazos puestos y después lo sientas en la silla»): el fotograma «teclea» de
# PixelLab (tools/sprites/pixellab_teclea.py), con los codos abiertos y los antebrazos hacia el teclado, en vez del base
const SENT_MESA := "teclea"   # i18n-no
const SENT_TABURETE := [".akka....akka.", ".akka....akka.", ".akla....alka.", ".akka....akka.", ".akka....akka.", ".ahha....ahha.", ".aaaa....aaaa."]
const TABURETE_SUBE := 5
func _pj_sentado() -> void:
	var gr = J.grupo_pj()
	if not gr:
		return
	var tab: bool = J.SENT.d == "norte" and J.SENT.get("k") in J.TABURETES
	var mesa: bool = J.SENT.d == "norte" and not tab and J.sent_mesa()
	var f = frame_sentado(gr, mesa)
	if f == null:
		return
	f = J.ropa_c(f, gr)
	var c: Image = f.c
	var g: Array = J.sent_geo(J.SENT.get("k"))
	var sube: int = 9 - int(g[1])   # 1.55.3: lo que sube la cadera desde la de pie (la 9 de la casilla), por asiento (SENT_GEO)
	var clave := "%d|%s|%d|%s" % [c.get_instance_id(), J.SENT.d + str(tab), sube, str(J.SENT.get("k")) if mesa else ""]
	var im: Image = _sent_img.get(clave)
	if im == null:
		var y0: int = int(f.cel.ancla[1])   # la fila de los pies; la cadera, 6 más arriba (y0 - 6, el cinturón)
		im = Image.create(c.get_width(), c.get_height() + 8, false, c.get_format())
		if J.SENT.d == "sur":
			# de frente (1.50; 1.55.3, a la altura de su asiento): el torso con la cadera en el cojín y las piernas dobladas de
			# SENT_PIERNAS: muslos, espinillas hasta el suelo (tantas como haga falta) y zapatillas, con los pies donde de pie
			im.blit_rect(c, Rect2i(0, 0, c.get_width(), y0 - 5), Vector2i(0, 0))
			# los colores, del propio fotograma (la ropa los cambia): contorno, pantalón, su brillo y zapatilla
			var col := {"a": c.get_pixel(9, y0 - 5), "n": c.get_pixel(12, y0 - 5), "o": c.get_pixel(13, y0 - 5), "h": c.get_pixel(12, y0 - 2)}
			var filas := piernas_sentado(6 + sube)
			for i in filas.size():
				var r: String = filas[i]
				for x in r.length():
					if r[x] != ".":
						im.set_pixel(9 + x, y0 - 5 + i, col[r[x]])
		elif tab:
			# de espaldas: el torso con el culo en la fila del asiento y las piernas de SENT_TABURETE debajo (el pie del
			# taburete, entre ellas), todo TABURETE_SUBE más arriba (en yp)
			var col := {"a": c.get_pixel(9, y0 - 5), "k": c.get_pixel(12, y0 - 5), "l": c.get_pixel(13, y0 - 5), "h": c.get_pixel(12, y0 - 1)}
			im.blit_rect(c, Rect2i(0, 0, c.get_width(), y0 - 5), Vector2i(0, 0))
			for i in SENT_TABURETE.size():
				var r: String = SENT_TABURETE[i]
				for x in r.length():
					if r[x] != ".":
						im.set_pixel(9 + x, y0 - 5 + i, col[r[x]])
		else:
			# de espaldas (1.55.3): solo el torso, con la cadera en el cojín; las piernas, debajo del asiento, las tapa el respaldo
			# (delante del ordenador, el del fotograma «teclea», con los brazos ya puestos)
			im.blit_rect(c, Rect2i(0, 0, c.get_width(), y0 - 5), Vector2i(0, 0))
		_sent_img[clave] = im
	var xp: int = J.SENT.x * 16 - Datos.jsround(cam.x) + 8 + int(g[0])
	var yp: int = J.SENT.y * 16 - Datos.jsround(cam.y) + 15 - (TABURETE_SUBE if tab else sube)
	_img(im, Datos.jsround(xp - f.cel.ancla[0]), Datos.jsround(yp - f.cel.ancla[1]))

# el fotograma del protagonista sentado: delante del ordenador, el de SENT_MESA (si el grupo lo tiene); si no, el base
func frame_sentado(gr, mesa: bool):
	var f = Atlas.frame_de(gr, SENT_MESA, "north", 0, {"i": 0}) if mesa else null
	return f if f else Atlas.frame_de(gr, "base", DIR4[J.P.dir], 0, {"i": 0})

# las piernas de frente para n filas, de la cadera al suelo: los dos muslos, las espinillas que hagan falta y las zapatillas
static func piernas_sentado(n: int) -> Array:
	var l := [SENT_PIERNAS[0], SENT_PIERNAS[1]]
	for i in maxi(0, n - 4):
		l.append(SENT_PIERNAS[2])
	l.append(SENT_PIERNAS[4])
	l.append(SENT_PIERNAS[5])
	return l

# en coche con techo (1.43.1): el protagonista, solo donde hay cabina (lo que pinta <v>-atras), para que la visera no se salga
# del cristal; una vez por par de fotogramas
var _cabina := {}
func _en_cabina(f, va, sube: int, cy: int) -> Image:
	var c: Image = f.c
	var v: Image = va.c
	var k := "%d|%d|%d" % [c.get_instance_id(), v.get_instance_id(), sube]
	if _cabina.has(k):
		return _cabina[k]
	var o := Image.create(c.get_width(), c.get_height(), false, Image.FORMAT_RGBA8)
	var dx: int = int(va.cel.ancla[0]) - int(f.cel.ancla[0])
	var dy: int = int(va.cel.ancla[1]) - int(f.cel.ancla[1]) - sube
	for y in mini(cy, c.get_height()):
		for x in c.get_width():
			var X := x + dx
			var Y := y + dy
			if X >= 0 and Y >= 0 and X < v.get_width() and Y < v.get_height() and v.get_pixel(X, Y).a > 0:
				o.set_pixel(x, y, c.get_pixel(x, y))
	_cabina[k] = o
	return o

# montado (1.13, frameMonta): la acción si la hay; si no, en la bici pedalea (walk) y en el patinete va de pie (base)
func _monta_frame(e: Dictionary, gr, v: String, dur: float):
	var dir: String = DIR4[e.dir]
	if e.get("act"):
		var t: float = now - e.act.t0
		var f = Atlas.frame_de(gr, e.act.n, dir, t)
		if f and t < Atlas.duracion(gr, e.act.n):
			return f
		e.act = null
	if v == "bici" and e.moving:
		var w = Atlas.frame_de(gr, "walk", dir, 0, {"ph": (e.parity + minf(1, e.t / dur)) / 2})
		if w:
			return w
	return Atlas.frame_de(gr, "base", dir, 0, {"i": 0})

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
		_dibujar(v.id, "efecto", "unica", t, v.x - c.x + dx, v.y - c.y - dy, {"esp": true} if v.get("esp") else {})

# de día, por dónde mira cada agente (de noche, no: sigilo); con la alarma, ninguno (pintarVistas, 10b-patrulla)
func _vistas() -> void:
	if J.is_night() or J.SOSP.alarma != null:
		return
	var m: Dictionary = J.MAPS[J.S.map]
	var R := int(J.D.PAT.vista[0])
	var col := Color8(255, 230, 60, 87)
	for e in J.ents:
		if not e.get("pat"):
			continue
		for y in range(e.y - R, e.y + R + 1):
			for x in range(e.x - R, e.x + R + 1):
				if (x == e.x and y == e.y) or J.tile_solid(m, x, y) or not J.ve_casilla(e, x, y, 0):
					continue
				_rect(x * 16 - cam.x, y * 16 - cam.y, 16, 16, col)

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
		if Datos.CAL:   # con CAL, en su lado (J.lado_x): el fondo en espejo, con sus plataformas, y los cortes de los lados cambiados
			_fondo_ancho(_espejo_img(ff.c), J.D.CORTES_COMBATE.map(func(c): return [c[0], c[1], {"izq": "dch", "dch": "izq"}.get(c[2], c[2])]))
		else:
			_fondo_ancho(ff.c, J.D.CORTES_COMBATE)
	L.draw_set_transform(Vector2(OX(), OY()))
	var k := minf(1, float(B.t) / 700)
	var e := 1 - pow(1 - k, 3)
	var ex := Datos.jsround(J.lado_x(154 - (1 - e) * 180 + 24))
	var px := Datos.jsround(J.lado_x(40 + (1 - e) * 190 + 24))
	var fE = _comb_frame("E")
	var fP = J.ropa_c(_comb_frame("P"), J.grupo_combate("P"))
	var sh := Datos.jsround(sin(float(B.shakeP) / 18) * 3) if B.shakeP > 0 and not Vista.CALMA else 0
	var parpadea: bool = B.flashE > 0 and floori(float(B.flashE) / 70) % 2 == 0 and not Vista.CALMA   # U5: SIN DESTELLOS
	if fE:
		if B.get("gone") and B.get("aE") and B.aE.n == "huir":   # huye hacia fuera: con CAL, hacia la izquierda
			_pinta(fE, ex + (-1 if Datos.CAL else 1) * Datos.jsround((now - B.aE.t0) * .12), 66)
		elif not B.get("gone") and not parpadea:
			_pinta(fE, ex, 66)
	if fP:
		_pinta(fP, px + sh, 142)
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
			return Atlas.frame_de(gr, a.n, "east" if a.n == "huir" else dir, t, {"bucle": a.n == "huir", "esp": J.comb_espejo(gr, a.n)})
		B["a" + who] = null
	var f = Atlas.frame_de(gr, "idle", dir, now, {"bucle": true, "esp": J.comb_espejo(gr, "idle")})
	return f if f else Atlas.frame_de(gr, "base", dir, 0, {"i": 0, "esp": J.comb_espejo(gr, "base")})

# una imagen en espejo, una vez (el fondo del combate en su lado)
func _espejo_img(img: Image) -> Image:
	var k := "esp|%d" % img.get_instance_id()
	if not cache.has(k):
		var o := img.duplicate()
		o.flip_x()
		cache[k] = o
	return cache[k]

# ---------- título e intro ----------
# el azul del título (1.35, renderDemo): por bandas, más opaco arriba, donde va el rótulo
func _azul_demo() -> void:
	var DM: Dictionary = J.D.DEMO
	var n: int = DM.bandas
	var h := ceili(SH / float(n))
	var a0: float = DM.alfa[0]
	var a1: float = DM.alfa[1]
	for i in n:
		var a: float = Datos.jsround((a0 + (a1 - a0) * i / float(n - 1)) * 100) / 100.0
		_rect(0, i * h, J.SW, h, Color(DM.azul[0] / 255.0, DM.azul[1] / 255.0, DM.azul[2] / 255.0, Datos.jsround(a * 255) / 255.0))

func _titulo() -> void:
	var t := now / 1000.0
	var ox := OX()
	var oy := OY()
	var gr = Atlas.cubre("misc:hoja-titulo") if Atlas.ok else null
	var f = Atlas.frame_de(gr, "base", "unica", 0, {"i": 0}) if gr else null
	if f:
		_fondo_ancho(f.c)
	# el agua: rayas de 1 px con x fraccionaria (antialias en sus extremos)
	var c := css("#1e3a64")
	for b in [-240, 0, 240]:
		for y in range(112, 160, 4):
			var o := sin(t * 1.5 + y) * 6
			_raya(ox + b + 20 + o + (y * 7) % 60, y + oy, 30, c)
			_raya(ox + b + 140 - o + (y * 5) % 50, y + oy, 24, c)
	if J.mode != "title":
		_rect(0, 0, J.SW, SH, Color(0, 0, 0, Datos.jsround(.35 * 255) / 255.0))
		var mk = J.D.get("MASCARAS", {}).get("elipse")
		var el: Dictionary
		var o0 := Vector2i(ox + 120, 104 + oy)
		if mk:
			if not cache.has("el|canvas"):
				cache["el|canvas"] = _mascara_a(mk)
			el = cache["el|canvas"]
			o0 = Vector2i(ox + 84, 95 + oy)
		else:
			el = _elipse(34, 7)
		var col := css("#2a6a48")
		for p in el:
			_rect(o0.x + p.x, o0.y + p.y, 1, 1, Color(col, el[p]))
		_retrato(J.D.LOOKS.kiko, ox + 120, 104 + oy, 2)

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
	if cache.size() > 512:   # R7: tope
		cache.clear()
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
	Atlas.dibuja(L, im, Rect2(Datos.jsround(cx - f.cel.ancla[0] * k), Datos.jsround(fy - f.cel.ancla[1] * k), im.get_width() * k, im.get_height() * k))

# ---------- la carpa, vista B (renderCarpa sin vista C) ----------
func _carpa_fondo() -> void:
	var D: Dictionary = J.D
	var c: Dictionary = g.c
	_fondo_ancho(Procedural.cuarto34())
	L.draw_set_transform(Vector2(OX(), OY()))
	if c.get("goteo") and not g.has("plata"):
		_goteo()
	if g.has("plata"):
		_pinta(g.plata, 120, 157)
	else:
		var cv := Procedural.carpa34(c.t)
		_img(cv, g.x0 - 1, g.yf + 2 - cv.get_height())
	if c.get("goteo") and g.has("plata"):
		_goteo()
	for e in Vista.temporizador(g.tx, g.ty, Cultivo.ciclo_de(c), Cultivo.foco_on(J.S, J.VC.ci)):
		_rect(e[0], e[1], e[2], e[3], e[4])
	if Cultivo.kit_de(c) != "":
		var e := Procedural.extra34("filtro")
		var p: Array = Vista.punto(g, g.W * .55, g.D * .85, g.H - 24)
		var fy: int = maxi(p[1], g.techo + e.get_height() - 1) if g.has("plata") else p[1]
		_img(e, p[0] - (e.get_width() >> 1), fy - e.get_height() + 1)
	if c.get("vent"):
		var e := Procedural.extra34("vent")
		var p: Array = Vista.punto(g, 2, g.D * .8, 110)
		_img(e, p[0], p[1] - e.get_height() + 1)

# el depósito del goteo, fuera de la carpa: en 3/4, al pie de la pared y detrás; de frente, a su lado y con el tubo por la puerta
# (de su tamaño real: su capacidad, goteo_l), con el nivel del agua que le queda en un tubo transparente de delante; la manguera
# sale a 40 cm del suelo y entra por la pared derecha, donde baja al suelo (_lineas_goteo: los ramales y los microtubos)
func _goteo() -> void:
	var l: int = Cultivo.goteo_l(J.S, J.VC.ci)
	var e := Procedural.deposito34(l)
	var dp := Procedural.deposito_px(l)
	var gl: int = g.x0 + g.w + g.s + 4
	var ty: int = _suelo_goteo() - e.get_height() + 1
	_img(e, gl, ty)
	var nx: int = gl + Datos.jsround(e.get_width() * .3)
	var n0: int = ty + Datos.jsround(dp.e / 2.0) + 3
	var ln: int = dp.h - 5
	var dep: float = g.c.dep if g.c.get("dep") != null else float(l)
	var n := Datos.jsround(ln * dep / l)
	_rect(nx, n0, 2, ln, css("#4e6e8c"))
	_rect(nx, n0 + ln - n, 2, n, css("#8ec8f0"))
	var xe: int = g.lg[0].xw
	_rect(xe, _y_goteo(), gl - xe, 1, css("#1c1d22"))

# el suelo donde está el depósito y la altura de la manguera (40 cm)
func _suelo_goteo() -> int:
	return g.yf if g.has("plata") else int(J.D.VB.PARED) + 8

func _y_goteo() -> int:
	return _suelo_goteo() - Datos.jsround(40 * J.D.VB.M)

# el goteo por dentro (1.10): por cada fila, un ramal por el suelo detrás de sus macetas (a 3 cm de la más honda) que sale de la
# bajante de la pared derecha (a 4 cm); cada maceta, su llave en el ramal y su microtubo, que sube por su derecha hasta el borde
# (q.bx, q.yl: _planta_b); la bajante, a la derecha del último microtubo (en las pequeñas, la maceta llega casi a la pared). Las
# filas, de atrás adelante: {fila, d (cm de fondo), x y b (el primer y el último microtubo), xw (la bajante), y}
func _lineas_goteo() -> Array:
	var S: Dictionary = J.S
	var D: Dictionary = J.D
	var F := {}
	for q in g.pl:
		var k: String = S.macetas[q.i]
		if not F.has(q.fila):
			F[q.fila] = {"fila": q.fila, "d": 0.0, "x": 1000000000, "b": -1000000000}
		var f: Dictionary = F[q.fila]
		q.bx = q.x + (Procedural.maceta34(k).get_width() >> 1) + 1
		f.d = maxf(f.d, q.cy + D.MACETA_CM.get(k, D.MACETA_CM.plastico7)[0] / 2.0 + 3)
		f.x = mini(f.x, q.bx)
		f.b = maxi(f.b, q.bx)
	var fl: Array = F.values()
	fl.sort_custom(func(a, b): return a.fila > b.fila)
	for f in fl:
		f.d = minf(f.d, g.D - 3)
		var p: Array = Vista.punto(g, g.W - 4, f.d, 0)
		f.xw = maxi(p[0], f.b + 1)
		f.y = p[1]
	for q in g.pl:
		q.yl = F[q.fila].y
	return fl

# un tramo de manguera de 1 px, píxel a píxel (como raya en renderCarpa)
func _manguera(x0: int, y0: int, x1: int, y1: int, col: Color, clip: Rect2i) -> void:
	var n := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in n + 1:
		_rect_clip(x0 + (Datos.jsround(float(x1 - x0) * i / n) if n else 0), y0 + (Datos.jsround(float(y1 - y0) * i / n) if n else 0), 1, 1, col, clip)

# el ramal de una fila, que sale de la bajante (el primero, de la manguera que entra)
func _ramal(lg: Array, fila, al: float, clip: Rect2i) -> void:
	var i := 0
	while lg[i].fila != fila:
		i += 1
	var f: Dictionary = lg[i]
	var ax: int = lg[i - 1].xw if i else f.xw
	var ay: int = lg[i - 1].y if i else _y_goteo()
	var tu := Color(css("#1c1d22"), al)
	_manguera(ax, ay, f.xw, f.y, tu, clip)
	_rect_clip(mini(f.x, f.xw), f.y, absi(f.xw - f.x) + 1, 1, tu, clip)

# el cono de luz del foco encendido (dentro de la carpa): trapecio con degradado vertical, sumado ('lighter')
func _cono() -> void:
	if not Cultivo.foco_on(J.S, J.VC.ci):
		return
	var D: Dictionary = J.D
	var c: Dictionary = g.c
	var F: Dictionary = D.FOCOS[c.foco]
	var key := "cono|%s|%s|%s" % [c.t, c.foco, g.has("plata")]
	if not cache.has(key):
		var a: float = .05 + .09 * minf(1, F.w / 600.0)
		var lw := Datos.jsround(D.FOCO_CM.get(c.foco, 40) * D.VB.M / 2)
		var hw: float = g.w / 2.0 + g.s
		var fx: float = g.fx
		var fy: float = g.fy
		var yf: float = g.yf
		var pol := PackedVector2Array([Vector2(fx - lw, fy), Vector2(fx + lw, fy), Vector2(fx + hw, yf), Vector2(fx - hw, yf)])
		var cx0: int = g.x0 if g.has("plata") else g.x0 + 1
		var cx1: int = g.x0 + g.w if g.has("plata") else cx0 + g.w + g.s - 1
		var cob := Procedural.cobertura(pol)
		var luz := css(D.FOCO_LUZ[F.tipo] + "1)")
		var o := {}
		for p in cob:
			if p.x < cx0 or p.x >= cx1:
				continue
			var t := clampf((p.y + .5 - fy) / (yf - fy), 0, 1)
			var al: float = a * (1 - t) * cob[p]
			o[p] = Color8(Datos.jsround(luz.r8 * al), Datos.jsround(luz.g8 * al), Datos.jsround(luz.b8 * al), 255)
		if cache.size() > 512:   # R7: tope
			cache.clear()
		cache[key] = o
	L.draw_set_transform(Vector2(OX(), OY()))
	var o: Dictionary = cache[key]
	for p in o:
		_rect(p.x, p.y, 1, 1, o[p])

func _carpa_encima() -> void:
	var S: Dictionary = J.S
	var D: Dictionary = J.D
	var c: Dictionary = g.c
	var F: Dictionary = D.FOCOS[c.foco]
	L.draw_set_transform(Vector2(OX(), OY()))
	var clip := Rect2i(g.x0, 0, g.w, SH) if g.has("plata") else Rect2i(g.x0 + 1, 0, g.w + g.s - 1, SH)
	var fsel := Vista.fila_sel(g, J.VC.sel)
	var pl: Array = g.pl.duplicate()
	pl.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and (a.x < b.x or (a.x == b.x and a.i < b.i))))
	var lg: Array = g.get("lg", [])
	var fa = null
	for q in pl:
		var al := Vista.A35 if q.fila < fsel else 1.0
		if lg.size() and q.fila != fa:
			fa = q.fila
			_ramal(lg, fa, al, clip)
		_planta_b(q, al, clip)
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
	Atlas.dibuja(L, im, Rect2(dst), Rect2(s), mod)

# un rectángulo recortado al de la carpa
func _rect_clip(x: int, y: int, w: int, h: int, col: Color, clip: Rect2i) -> void:
	var r := Rect2i(x, y, w, h).intersection(clip)
	if r.size.x > 0 and r.size.y > 0:
		_rect(r.position.x, r.position.y, r.size.x, r.size.y, col)

# maceta y planta de una plaza; con garrafas (sin goteo), su garrafa detrás a la derecha, con el agua que le queda, y el tubo del
# gotero del tapón a la tierra de la maceta
func _planta_b(q: Dictionary, al: float, clip: Rect2i) -> void:
	var S: Dictionary = J.S
	var p = S.pots[q.i]
	var k: String = S.macetas[q.i]
	var m := Procedural.maceta34(k)
	var mp := Procedural.maceta_px(k)
	var mod := Color(1, 1, 1, al)
	var ca: Dictionary = S.carpas[Cultivo.huecos(S)[q.i].c]
	var gar: bool = ca.get("garrafas", false) and not ca.get("goteo", false)
	var gr: Image = Procedural.garrafa34(Cultivo.garrafa_l(S, q.i)) if gar else null
	var gx: int = q.x + (m.get_width() >> 1) - 4
	var gy: int = q.y - 1 - (gr.get_height() if gar else 0)
	var rim: int = q.y - Datos.jsround(mp.e / 2.0 + mp.hb)
	if gar:
		var nn := Datos.jsround((gr.get_height() - 5) * Cultivo.garrafa(S, q.i) / Cultivo.garrafa_l(S, q.i))
		_img_clip(gr, gx, gy, Rect2i(Vector2i.ZERO, gr.get_size()), clip, mod)
		_rect_clip(gx + 1, gy + gr.get_height() - 1 - nn, gr.get_width() - 2, nn, Color(css("#9ab8cc"), al), clip)
	# con goteo, su microtubo sube del ramal (detrás) por la derecha, con su llave, y entra por el borde hasta la tierra
	var got: bool = ca.get("goteo", false) and q.has("yl")
	var mt := Color(css("#1c1d22"), al)
	if got:
		_rect_clip(q.bx, rim - 1, 1, q.yl - rim, mt, clip)
		_rect_clip(q.bx, q.yl - 1, 2, 2, Color(css("#b8322a"), al), clip)
		_rect_clip(q.bx, q.yl - 1, 1, 1, Color(css("#e8644c"), al), clip)
	_img_clip(m, q.x - (m.get_width() >> 1), rim, Rect2i(Vector2i.ZERO, m.get_size()), clip, mod)
	if got:
		_rect_clip(q.x + 2, rim - 1, q.bx - q.x - 2, 1, mt, clip)
		_rect_clip(q.x + 2, rim, 1, 2, mt, clip)
	if gar:
		var tu := Color(css("#1c1d22"), al)
		_rect_clip(q.x + 3, gy - 1, gx + gr.get_width() - q.x - 5, 1, tu, clip)
		if rim + 2 > gy - 1:
			_rect_clip(q.x + 3, gy - 1, 1, rim + 2 - (gy - 1), tu, clip)
	if p == null:
		return
	var s = Datos.strain(S, p.sid)
	var dead: bool = true if p.get("dead") else false
	var st := 9 if dead else Cultivo.plant_stage(p)
	var pc := Procedural.planta34(Datos.porte_planta(S, p), st, not dead and p.water <= 0, Datos.color_cog(S, p) if s else "#9bd35a", q.cw, q.ch)
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
