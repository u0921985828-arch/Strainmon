# Ribera Verde (Godot) — el arte de la vista C (arte/carpa.png + carpa.json, del atlas del HTML con tools/godot.js) y lo que
# 01b-arte y 09b-carpa le hacen píxel a píxel: alto del dibujo, fotograma de cada alto, quitar filas (vcAplasta), colores de
# la variedad (conRampa), campana apagada, luz de cada foco, pared recortada al ancho de la carpa y la planta seca
extends RefCounted

const Datos = preload("res://src/datos.gd")

static var img: Image
static var spr := {}        # sprite → [[x, y, w, h], …] (un rect por fotograma)
static var rampa: Array = []
static var cache := {}
static var texs := {}

static func carga() -> void:
	if img:
		return
	img = Image.new()
	img.load_png_from_buffer(FileAccess.get_file_as_bytes("res://arte/carpa.png"))
	img.convert(Image.FORMAT_RGBA8)
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://arte/carpa.json"))
	spr = j.sprites
	rampa = j.rampa

static func hay(n: String) -> bool:
	carga()
	return spr.has(n)

static func n_fotos(n: String) -> int:
	return spr[n].size()

static func foto(n: String, i := 0) -> Image:
	var k := "f|%s|%d" % [n, i]
	if not cache.has(k):
		var r: Array = spr[n][i]
		cache[k] = img.get_region(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
	return cache[k]

# anchos (px) de la familia de sprites «pre» + ancho, en el orden del atlas
static func anchos(pre: String) -> Array:
	carga()
	var o := []
	for k in spr:
		if k.begins_with(pre):
			var s: String = k.substr(pre.length())
			if s.is_valid_int() and int(s) > 0:
				o.append(int(s))
	return o

# alto del dibujo: de la última fila a la primera con algo
static func alto(im: Image) -> int:
	var k := im.get_instance_id()
	if cache.has(k):
		return cache[k]
	var a := 0
	for y in im.get_height():
		var hay_px := false
		for x in im.get_width():
			if im.get_pixel(x, y).a8 > 0:
				hay_px = true
				break
		if hay_px:
			a = im.get_height() - y
			break
	cache[k] = a
	return a

# de los fotogramas del sprite n, el más bajo que no baja de h: [alto, imagen, índice]
static func altura(n: String, h: int) -> Array:
	var k := "alt|" + n
	if not cache.has(k):
		var L := []
		for i in n_fotos(n):
			L.append([alto(foto(n, i)), foto(n, i), i])
		L.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[2] < b[2]))
		cache[k] = L
	for e in cache[k]:
		if e[0] >= h:
			return e
	return cache[k][-1]

# la planta más baja que su fotograma pierde filas enteras, nunca se escala: las que tienen menos píxeles de debajo de la cola
# (el 40 % de arriba); la cola solo si no basta. Las 2 últimas filas (la base del tallo) se quedan
static func aplasta(c: Image, h: int) -> Image:
	var a := alto(c)
	if h >= a:
		return c
	var k := "apl|%d|%d" % [c.get_instance_id(), h]
	if cache.has(k):
		return cache[k]
	var W := c.get_width()
	var H := c.get_height()
	var y0 := H - a
	var cola := y0 + Datos.jsround(a * .4)
	var n := {}
	var filas := []
	for y in range(y0, H - 2):
		var m := 0
		for x in W:
			if c.get_pixel(x, y).a8 > 0:
				m += 1
		n[y] = m
		filas.append(y)
	filas.sort_custom(func(p, q):
		var bp := 1 if p < cola else 0
		var bq := 1 if q < cola else 0
		if bp != bq:
			return bp < bq
		if n[p] != n[q]:
			return n[p] < n[q]
		return q < p)
	var fuera := {}
	for y in filas.slice(0, a - h):
		fuera[y] = true
	var o := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var y := H
	for s in range(H - 1, y0 - 1, -1):
		if not fuera.has(s):
			y -= 1
			o.blit_rect(c, Rect2i(0, s, W, 1), Vector2i(0, y))
	cache[k] = o
	return o

# colores exactos (#rrggbb → #rrggbb)
static func recolor(c: Image, mapa: Dictionary) -> Image:
	var tb := {}
	for a in mapa:
		tb[Datos.hexi(a)] = Color.html(mapa[a])
	var o: Image = c.duplicate()
	for y in o.get_height():
		for x in o.get_width():
			var p := o.get_pixel(x, y)
			if p.a8 == 0:
				continue
			var key := (p.r8 << 16) | (p.g8 << 8) | p.b8
			if tb.has(key):
				var t: Color = tb[key]
				o.set_pixel(x, y, Color8(t.r8, t.g8, t.b8, p.a8))
	return o

# planta seca: filter saturate(.4) sepia(.7) del canvas (matrices de Filter Effects, en sRGB)
static func seca(c: Image) -> Image:
	var s := .4
	var a := 1 - .7
	var Ms := [[.213 + .787 * s, .715 - .715 * s, .072 - .072 * s], [.213 - .213 * s, .715 + .285 * s, .072 - .072 * s], [.213 - .213 * s, .715 - .715 * s, .072 + .928 * s]]
	var Mp := [[.393 + .607 * a, .769 - .769 * a, .189 - .189 * a], [.349 - .349 * a, .686 + .314 * a, .168 - .168 * a], [.272 - .272 * a, .534 - .534 * a, .131 + .869 * a]]
	var o: Image = c.duplicate()
	for y in o.get_height():
		for x in o.get_width():
			var p := o.get_pixel(x, y)
			if p.a8 == 0:
				continue
			var v := [p.r8 / 255.0, p.g8 / 255.0, p.b8 / 255.0]
			var w := []
			for r in 3:
				w.append(Ms[r][0] * v[0] + Ms[r][1] * v[1] + Ms[r][2] * v[2])
			var z := []
			for r in 3:
				z.append(Datos.jsround(clampf(Mp[r][0] * w[0] + Mp[r][1] * w[1] + Mp[r][2] * w[2], 0, 1) * 255))
			o.set_pixel(x, y, Color8(z[0], z[1], z[2], p.a8))
	return o

# daños de la plaga encima de la planta, sacados de su propio fotograma (c0, antes de los colores de la variedad): en las
# hojas y el tallo (los verdes de VC_HOJA) y en los cogollos (la rampa clave), nunca en la base del tallo, cada píxel con el
# tono de su sitio en la rampa, así que la luz y la sombra del sprite se quedan: en las hojas, manchas amarillas con el centro
# pardo, el punteado claro de los bichos y, en el nivel 3, bordes quemados; en los cogollos, telilla blanca y podrido pardo.
# La silueta no cambia. nivel 1-3; sem: la misma planta, las mismas manchas
const DANO_AMARILLO := ["#4c4a1e", "#7c7428", "#b4a83a", "#e2d66a", "#a8984a", "#605a2a"]
const DANO_PARDO := ["#3a2416", "#5c3a1e", "#7e5228", "#a87638", "#8a6434", "#4c3220"]
const DANO_PUNTO := ["#8a8a60", "#b8b484", "#e8e6b0", "#f4f2cc", "#e0dca8", "#a8a47c"]
const DANO_TELA := ["#f4f2ea", "#cfcbc0", "#8e8a80"]      # la rampa del cogollo: clara, media y oscura
const DANO_PODRIDO := ["#9a8670", "#6e5c4a", "#463a30"]

static func azar(x: int, y: int, s: int, k: int) -> float:
	var h := (x * 73856093 + y * 19349663 + s * 83492791 + k * 40503) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	h = ((h ^ (h >> 16)) * 668265263) & 0x7fffffff
	return float(h ^ (h >> 15)) / 2147483648.0

static func dano(im: Image, c0: Image, nivel: int, sem: int) -> Image:
	var hj: Array = Datos.carga().VC_HOJA
	var ix := {}
	for j in hj.size():
		ix[Datos.hexi(hj[j])] = j
	for j in rampa.size():
		ix[Datos.hexi(rampa[j])] = 10 + j
	var col := {}
	for t in ["a", "p", "."]:
		col[t] = (DANO_AMARILLO if t == "a" else (DANO_PARDO if t == "p" else DANO_PUNTO)).map(func(h): return Color.html(h))
		col["c" + t] = (DANO_PODRIDO if t == "p" else DANO_TELA).map(func(h): return Color.html(h))
	var o: Image = im.duplicate()
	var W := o.get_width()
	var H := o.get_height()
	var mancha: float = [0, .18, .28, .38][nivel]   # celdas de 4 × 4 con mancha
	var punto: float = [0, .10, .15, .20][nivel]
	# las manchas, una vez por celda (centro y radio) antes de mirar los píxeles
	var cw := W / 4 + 3
	var celdas := []
	for cy in range(-1, H / 4 + 2):
		for cx in range(-1, W / 4 + 2):
			if azar(cx, cy, sem, 1) >= mancha:
				celdas.append(null)
			else:
				celdas.append(Vector3(cx * 4 + azar(cx, cy, sem, 2) * 4, cy * 4 + azar(cx, cy, sem, 3) * 4, 1.1 + azar(cx, cy, sem, 4) * (.5 + .4 * nivel)))
	for y in range(H - alto(c0), H - 3):
		for x in W:
			var p0 := c0.get_pixel(x, y)
			if p0.a8 == 0:
				continue
			var j = ix.get((p0.r8 << 16) | (p0.g8 << 8) | p0.b8)
			if j == null:
				continue
			var t := ""
			for cy in range(y / 4 - 1, y / 4 + 2):
				for cx in range(x / 4 - 1, x / 4 + 2):
					var m = celdas[(cy + 1) * cw + cx + 1]
					if m == null:
						continue
					var d := sqrt((x + .5 - m.x) * (x + .5 - m.x) + (y + .5 - m.y) * (y + .5 - m.y))
					if d <= m.z * .45 and nivel >= 2:
						t = "p"
					elif d <= m.z and t == "":
						t = "a"
			var cogollo: bool = j >= 10
			if cogollo and t == "a":
				t = ""
			if t == "" and nivel >= 3 and not cogollo and azar(x, y, sem, 5) < .4:
				for e in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var a: int = x + e.x
					var b: int = y + e.y
					if a < 0 or b < 0 or a >= W or b >= H or c0.get_pixel(a, b).a8 == 0:
						t = "p"
			if t == "" and azar(x, y, sem, 6) < punto:
				t = "."
			if t != "":
				var c: Color = col[("c" + t) if cogollo else t][(j - 10) if cogollo else j]
				o.set_pixel(x, y, Color8(c.r8, c.g8, c.b8, im.get_pixel(x, y).a8))
	return o

# la campana con la boca apagada: los tonos cálidos y los casi blancos (el tubo del CFL) pasan a gris oscuro
static func apagado(c: Image) -> Image:
	var k := "off|%d" % c.get_instance_id()
	if cache.has(k):
		return cache[k]
	var o: Image = c.duplicate()
	for y in o.get_height():
		for x in o.get_width():
			var p := o.get_pixel(x, y)
			if p.a8 and (p.r8 > p.b8 + 40 or mini(p.r8, mini(p.g8, p.b8)) > 190):
				var l := Datos.jsround((p.r8 * .3 + p.g8 * .59 + p.b8 * .11) * .3)
				o.set_pixel(x, y, Color8(l, l + 2, l + 4, p.a8))
	cache[k] = o
	return o

# pared o luz de la carpa: la de 240 × 160 con la pared del fondo recortada a su ancho (los laterales, con los postes del fondo, enteros)
# la boca del foco mide a px y la luz sale de una de 46: con un foco más ancho, la luz se ensancha por igual desde el centro
static func luz_k(vc: Dictionary) -> float:
	return maxf(1, vc.foco.a / 46.0)

static func fondo(t: String, vc: Dictionary, capa: String) -> Image:
	var kl := luz_k(vc) if capa.begins_with("luz") else 1.0
	var k := "vc|%s|%s" % [t, capa] + ("|%d" % vc.foco.a if kl > 1 else "")
	if cache.has(k):
		return cache[k]
	var s := foto("carpa-c-" + capa)
	if kl > 1:
		var e := Image.create(240, 160, false, Image.FORMAT_RGBA8)
		for i in 240:
			e.blit_rect(s, Rect2i(int(floor(120 + (i + .5 - 120) / kl)), 0, 1, 160), Vector2i(i, 0))
		s = e
	var L: int = Datos.carga().VCA.lado
	var xl: int = vc.xl
	var xr: int = xl + vc.w
	var o := Image.create(240, 160, false, Image.FORMAT_RGBA8)
	_pega(o, s, 0, L, xl - L)
	_pega(o, s, xl, vc.w, xl)
	_pega(o, s, 240 - L, L, xr)
	# el suelo, más oscuro lejos del foco (1.10 P5): hasta un 25 % en las esquinas de delante, por la distancia al centro (x 120, y 150)
	if capa == "pared":
		var V: Dictionary = Datos.carga().VCA
		for y in range(int(V.fondo), 160):
			var h: float = (vc.w + 32 * (y - V.fondo) / 19.0) / 2
			var dy: float = (y + .5 - V.base) / 19
			for i in range(maxi(0, ceili(120 - h)), mini(240, ceili(120 + h))):
				var dx: float = (i + .5 - 120) / h
				var kk := Datos.jsround(64 * minf(1, dx * dx + dy * dy))
				var p := o.get_pixel(i, y)
				if p.a8:
					o.set_pixel(i, y, Color8((p.r8 * (256 - kk)) >> 8, (p.g8 * (256 - kk)) >> 8, (p.b8 * (256 - kk)) >> 8, p.a8))
	cache[k] = o
	return o

static func _pega(o: Image, s: Image, sx: int, w: int, dx: int) -> void:
	for x in w:
		if dx + x < 0 or dx + x >= 240 or sx + x < 0 or sx + x >= s.get_width():
			continue
		for y in 160:
			o.set_pixel(dx + x, y, s.get_pixel(sx + x, y))

# tonos de la capa de luz (los de la imagen A; luz() les pone el color de cada foco): base, haz, resplandor y núcleo
const VC_LZ := [[198, 130, 77], [231, 150, 86], [255, 172, 82], [255, 224, 149]]

# la luz de un LED de barras (vcLuzLed): el suelo y los postes, de carpa-c-luz-led (ensanchada con el foco); en la pared del fondo, un
# haz por barra (de la última fila del sprite del foco) que baja hasta el pie de la pared abriéndose lo justo para que los de fuera
# lleguen a las paredes de la carpa. Bajo las barras, el núcleo; con un haz, el haz; con dos o más, el resplandor; entre haces, nada
static func luz_led(t: String, vc: Dictionary) -> Image:
	var k := "vc|%s|luz-led|%s|%d" % [t, vc.foco.n, vc.fy]
	if cache.has(k):
		return cache[k]
	var o: Image = fondo(t, vc, "luz-led").duplicate()
	var fc := foto(vc.foco.n)
	var fw := fc.get_width()
	var ox := 120 - (fw >> 1)
	var B := []
	for i in fw:
		if fc.get_pixel(i, fc.get_height() - 1).a8:
			if B.size() and B[-1][1] == ox + i - 1:
				B[-1][1] = ox + i
			else:
				B.append([ox + i, ox + i])
	var V: Dictionary = Datos.carga().VCA
	var X0: int = vc.xl
	var X1: int = vc.xl + vc.w - 1
	var y0: int = vc.fy + 1
	var y1 := int(V.fondo) - 2
	var s := 0.0
	if B.size():
		s = float(maxi(maxi(B[0][0] - X0, X1 - B[-1][1]), 0)) / (y1 - y0)
	for y in range(y0, y1 + 1):
		var e := s * (y - y0)
		for i in range(X0, X1 + 1):
			var p := i + .5
			var n := 0
			for b in B:
				if p >= b[0] - e and p <= b[1] + 1 + e:
					n += 1
			if not n:
				o.set_pixel(i, y, Color(0, 0, 0, 0))
				continue
			var z: Array = VC_LZ[3 if y < y0 + 2 else (2 if n > 1 else 1)]
			o.set_pixel(i, y, Color8(z[0], z[1], z[2], 255))
	cache[k] = o
	return o

# la de sodio (y la del CFL) con el foco bajado (vcLuzBaja): en la pared del fondo, de la boca al pie (138), baja con él; arriba, nada
static func luz_baja(t: String, vc: Dictionary) -> Image:
	var L := fondo(t, vc, "luz")
	var V: Dictionary = Datos.carga().VCA
	var y0 := int(V.boca)
	var y1 := int(V.fondo) - 2
	var dy: int = vc.fy - y0
	if dy <= 0:
		return L
	var k := "vc|%s|luz-baja|%d|%d" % [t, vc.foco.a, vc.fy]
	if cache.has(k):
		return cache[k]
	var o: Image = L.duplicate()
	o.fill_rect(Rect2i(vc.xl, y0, vc.w, y1 + 1 - y0), Color(0, 0, 0, 0))
	if y1 + 1 - y0 - dy > 0:
		o.blit_rect(L, Rect2i(vc.xl, y0, vc.w, y1 + 1 - y0 - dy), Vector2i(vc.xl, y0 + dy))
	cache[k] = o
	return o

# de dónde cuelga la campana (vcCuelga): la primera y la última columna con algo de su fila de arriba (las cuerdas de los LED) y esa fila
const VC_CUERDA := Color8(28, 29, 34)
const VC_POLEA := [Color8(58, 60, 68), Color8(122, 133, 132)]   # cuerpo y brillo de la rueda
static func cuelga(c: Image) -> Array:
	var k := "cuelga|%d" % c.get_instance_id()
	if cache.has(k):
		return cache[k]
	var o := [0, 0, 0]
	for r in c.get_height():
		var a := -1
		var b := -1
		for i in c.get_width():
			if c.get_pixel(i, r).a8:
				if a < 0:
					a = i
				b = i
		if a >= 0:
			o = [a, b, r]
			break
	cache[k] = o
	return o

# la luz de cada tipo de foco: la del sodio, tal cual; las demás, con su color (misma luminosidad). Los LED, de barras, la suya (luz_led)
static func luz(t: String, vc: Dictionary) -> Image:
	var L := luz_led(t, vc) if vc.tipo == "led" and hay("carpa-c-luz-led") else luz_baja(t, vc)
	var lc: Dictionary = Datos.carga().LUZ_C
	if not lc.has(vc.tipo):
		return L
	var k := "vc|%s|luz|%s|%d|%d" % [t, vc.tipo, vc.foco.a, vc.fy]
	if cache.has(k):
		return cache[k]
	var c: Array = lc[vc.tipo][0]
	var lk: float = .299 * c[0] + .587 * c[1] + .114 * c[2]
	var o: Image = L.duplicate()
	for y in 160:
		for x in 240:
			var p := o.get_pixel(x, y)
			if p.a8:
				var l := (.299 * p.r8 + .587 * p.g8 + .114 * p.b8) / lk
				o.set_pixel(x, y, Color8(Datos.u8(minf(255, c[0] * l)), Datos.u8(minf(255, c[1] * l)), Datos.u8(minf(255, c[2] * l)), p.a8))
	cache[k] = o
	return o

# columnas (primera y última) con algo de cada imagen
static func caja(im: Image) -> Array:
	var k := "caja|%d" % im.get_instance_id()
	if cache.has(k):
		return cache[k]
	var a := im.get_width()
	var b := -1
	for y in im.get_height():
		for x in im.get_width():
			if im.get_pixel(x, y).a8 > 0:
				a = mini(a, x)
				b = maxi(b, x)
	cache[k] = [a, b]
	return cache[k]

# el agua de la garrafa y del depósito pequeño: los píxeles «dentro» (par[0]) de las fr filas de abajo (fracción de las filas que
# la tienen) pasan al color del agua (par[1])
static func nivel(im: Image, par: Array, fr: float) -> Image:
	var K := Datos.hexi(par[0])
	# las filas del agua (y0, y1), una vez por imagen: se pide cada fotograma
	var kf := "nivf|%d|%s" % [im.get_instance_id(), par[0]]
	if not cache.has(kf):
		var a := im.get_height()
		var b := -1
		for y in im.get_height():
			for x in im.get_width():
				var p := im.get_pixel(x, y)
				if p.a8 and ((p.r8 << 16) | (p.g8 << 8) | p.b8) == K:
					a = mini(a, y)
					b = maxi(b, y)
		cache[kf] = [a, b]
	var y0: int = cache[kf][0]
	var y1: int = cache[kf][1]
	var n := 0 if y1 < 0 else Datos.jsround((y1 - y0 + 1) * clampf(fr, 0, 1))
	var k := "niv|%d|%d" % [im.get_instance_id(), n]
	if cache.has(k):
		return cache[k]
	var A := Color.html(par[1])
	var o: Image = im.duplicate()
	for y in range(maxi(0, y1 - n + 1), y1 + 1):
		for x in o.get_width():
			var p := o.get_pixel(x, y)
			if p.a8 and ((p.r8 << 16) | (p.g8 << 8) | p.b8) == K:
				o.set_pixel(x, y, Color8(A.r8, A.g8, A.b8, p.a8))
	cache[k] = o
	return o

static func tex(k: String, im: Image) -> ImageTexture:
	if not texs.has(k):
		texs[k] = ImageTexture.create_from_image(im)
	return texs[k]
