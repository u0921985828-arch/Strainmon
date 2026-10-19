# Ribera Verde (Godot) — MAESTRO [8] «Sistema de Diálogos HD»: el retrato de quien habla (PortraitRect), en la charla en vivo,
# las llamadas y los SMS. Se hace aquí, píxel a píxel, con la identidad de la persona (su look de LOOKS o el de la calle: piel,
# pelo y peinado, gorra o capucha, barba, gafas, camiseta; de chica o de chico, GENERO) y su gesto según el tono de lo que dice
# (expresion: 0 tranquilo, 1 contento, 2 enfadado, 3 dudando). Arte propio, sin nada de fuera. Cacheado por persona y gesto.
extends RefCounted

const Datos = preload("res://src/datos.gd")

const W := 32
const K := Color8(0x26, 0x26, 0x2e)          # el contorno (paleta fija)
const FONDO := Color8(0xa9, 0xd2, 0xec)      # el de la caja de diálogo
const BORDE := Color8(0x46, 0x74, 0x9a)
const OJO := Color8(0xf8, 0xf8, 0xf0)
const NEUTRO := 0
const ALEGRE := 1
const ENFADO := 2
const DUDA := 3

static var cache := {}

# el gesto por el tono: lo enfadado manda, luego lo contento y luego la duda (castellano e inglés)
const P_ENFADO := ["largo de aquí", "lárgate", "fuera de aquí", "ni se te ocurra", "te lo advierto", "cuidado", "joder", "mierda", "me debes", "págame", "paga ", "pagar", "no me hagas", "último aviso", "policía", "multa", "redada", "te vas a enterar", "¡no", "get out", "warning", "you owe", "pay up", "damn", "last chance", "police", "raid"]   # i18n-no
const P_ALEGRE := ["gracias", "genial", "perfecto", "trato hecho", "enhorabuena", "bienvenid", "me alegro", "qué bien", "jaja", "estupendo", "bien hecho", "de lujo", "buenísim", "thanks", "thank you", "great", "deal", "welcome", "congrat", "haha", "perfect", "well done"]   # i18n-no
const P_DUDA := ["quizá", "quizás", "no sé", "a lo mejor", "puede que", "hmm", "mmm", "…", "...", "¿", "maybe", "not sure", "perhaps", "i guess", "?"]   # i18n-no

static func expresion(t: String) -> int:
	var s := t.to_lower()
	for p in P_ENFADO:
		if s.contains(p):
			return ENFADO
	for p in P_ALEGRE:
		if s.contains(p):
			return ALEGRE
	for p in P_DUDA:
		if s.contains(p):
			return DUDA
	return NEUTRO

static func _c(h, def: Color) -> Color:
	if h is String and h.begins_with("#") and h.length() >= 7:
		return Color.html(h.substr(0, 7))
	return def

static func _osc(c: Color, f := 0.78) -> Color:
	return Color(c.r * f, c.g * f, c.b * f, 1)

static func _cla(c: Color, f := 0.25) -> Color:
	return c.lerp(Color.WHITE, f)

# look: {id, skin, hair, style, hat, shirt, beard, glasses}; mujer: el muñeco es de chica; boca: 1 abierta (hablando)
static func textura(look: Dictionary, mujer: bool, expr: int, boca := 0) -> ImageTexture:
	var k := "%s|%d|%d|%d" % [str(look.get("id", "")), int(mujer), expr, boca]
	if cache.has(k):
		return cache[k]
	if cache.size() > 256:
		cache.clear()
	var t := ImageTexture.create_from_image(imagen(look, mujer, expr, boca))
	cache[k] = t
	return t

static func imagen(look: Dictionary, mujer: bool, expr: int, boca := 0) -> Image:
	var im := Image.create(W, W, false, Image.FORMAT_RGBA8)
	im.fill(FONDO)
	var hsh: int = Datos.hash_str(str(look.get("id", "x")))
	var piel := _c(look.get("skin"), Color8(0xf0, 0xc0, 0x98))
	var pelo := _c(look.get("hair"), Color8(0x4a, 0x34, 0x24))
	var ropa := _c(look.get("shirt"), Color8(0x5a, 0x7a, 0xb0))
	var gorro := _c(look.get("hat"), ropa)
	var est := str(look.get("style", "short"))
	if mujer and est in ["short", "bald"]:
		est = "long" if hsh % 2 else "bun"
	var ancho := 7 + (hsh >> 3) % 2          # media cara: 7 u 8
	var cx := 16
	var y0 := 7                               # lo alto de la cabeza
	var y1 := 22                              # la barbilla
	var R := func(x: int, y: int, w: int, h: int, c: Color):
		for yy in range(maxi(0, y), mini(W, y + h)):
			for xx in range(maxi(0, x), mini(W, x + w)):
				im.set_pixel(xx, yy, c)
	# el pelo largo, detrás
	if est == "long" or est == "curly" and mujer:
		R.call(cx - ancho - 1, y0 + 2, 2 * ancho + 2, 17 + (hsh % 3), pelo)
	# los hombros y el cuello
	for y in range(25, W):
		var a := 8 + (y - 25)
		R.call(cx - a, y, 2 * a, 1, ropa)
	R.call(cx - 2, 21, 4, 5, _osc(piel))
	R.call(cx - 3, 25, 6, 1, _osc(ropa))
	if mujer:
		R.call(cx - 3, 26, 6, 2, _osc(piel, .9))   # el escote
	# la cabeza: un óvalo
	for y in range(y0, y1 + 1):
		var e := 0
		if y == y0:
			e = 3
		elif y == y0 + 1:
			e = 1
		elif y >= y1 - 1:
			e = 2 if y == y1 else 1
		R.call(cx - ancho + e, y, 2 * (ancho - e), 1, piel)
		R.call(cx + ancho - e - 2, y, 2, 1, _osc(piel, .88))   # la sombra de la derecha (la luz, arriba a la izquierda)
	# las orejas
	R.call(cx - ancho - 1, 14, 1, 3, _osc(piel, .9))
	R.call(cx + ancho, 14, 1, 3, _osc(piel, .8))
	# el pelo de arriba, por peinado
	match est:
		"bald":
			R.call(cx - ancho, 13, 1, 3, pelo)
			R.call(cx + ancho - 1, 13, 1, 3, pelo)
			im.set_pixel(cx - 3, y0 + 1, _cla(piel, .4))
		"cap":
			R.call(cx - ancho, y0 - 1, 2 * ancho, 5, gorro)
			R.call(cx - ancho, y0 + 4, 2 * ancho + 4, 2, _osc(gorro))      # la visera
			R.call(cx - ancho, y0 + 6, 1, 4, pelo)
			R.call(cx + ancho - 1, y0 + 6, 1, 4, pelo)
			R.call(cx - 3, y0, 3, 1, _cla(gorro))
		"hood":
			R.call(cx - ancho - 2, y0 - 2, 2 * ancho + 4, 4, gorro)
			R.call(cx - ancho - 2, y0 + 2, 3, 20 - y0, gorro)
			R.call(cx + ancho - 1, y0 + 2, 3, 20 - y0, _osc(gorro))
			R.call(cx - ancho + 1, y0 + 2, 2 * ancho - 2, 2, pelo)
		"bun":
			R.call(cx - 3, y0 - 4, 6, 4, pelo)
			R.call(cx - ancho, y0 - 1, 2 * ancho, 4, pelo)
			R.call(cx - ancho, y0 + 3, 2, 4, pelo)
			R.call(cx + ancho - 2, y0 + 3, 2, 4, pelo)
		"curly":
			for i in range(-ancho - 1, ancho + 1, 2):
				R.call(cx + i, y0 - 2 + (1 if (i + hsh) % 4 == 0 else 0), 2, 2, pelo)
			R.call(cx - ancho - 1, y0, 2 * ancho + 2, 3, pelo)
			R.call(cx - ancho - 1, y0 + 3, 2, 6, pelo)
			R.call(cx + ancho - 1, y0 + 3, 2, 6, pelo)
		"long":
			R.call(cx - ancho - 1, y0 - 1, 2 * ancho + 2, 4, pelo)
			R.call(cx - ancho - 1, y0 + 3, 2, 12, pelo)
			R.call(cx + ancho - 1, y0 + 3, 2, 12, pelo)
			R.call(cx - 2 + (hsh % 3) - 1, y0 + 3, 4, 1, pelo)            # el flequillo
		_:   # short
			R.call(cx - ancho, y0 - 1, 2 * ancho, 4, pelo)
			R.call(cx - ancho, y0 + 3, 1, 3, pelo)
			R.call(cx + ancho - 1, y0 + 3, 1, 3, pelo)
			R.call(cx - ancho + 1 + hsh % 4, y0 + 3, 3, 1, pelo)
	if est != "cap" and est != "hood" and est != "bald":
		R.call(cx - 4, y0, 3, 1, _cla(pelo, .3))                        # el brillo del pelo
	# los ojos (fila 14), las cejas y la boca, por el gesto
	var ey := 14
	for s in [-1, 1]:
		var ex: int = cx - 4 if s < 0 else cx + 2
		if expr == ALEGRE:
			R.call(ex, ey, 2, 1, K)                                        # los ojos entornados, contentos
			im.set_pixel(ex, ey + 1, _osc(piel)); im.set_pixel(ex + 1, ey + 1, _osc(piel))
		else:
			R.call(ex, ey, 2, 2, OJO)
			R.call(ex + (1 if s < 0 else 0), ey, 1, 2, K)                 # la pupila, hacia el medio
		var cy := ey - 2
		if expr == ENFADO:
			im.set_pixel(ex + (1 if s < 0 else 0), cy + 1, pelo.darkened(.3))
			im.set_pixel(ex + (0 if s < 0 else 1), cy, pelo.darkened(.3))
			im.set_pixel(ex + (1 if s < 0 else 0), cy, pelo.darkened(.3))
		elif expr == ALEGRE:
			R.call(ex, cy - 1, 2, 1, pelo.darkened(.3))
		elif expr == DUDA and s > 0:
			R.call(ex, cy - 1, 2, 1, pelo.darkened(.3))
		else:
			R.call(ex, cy, 2, 1, pelo.darkened(.3))
	if look.get("glasses"):
		for s in [-1, 1]:
			var gx: int = cx - 5 if s < 0 else cx + 1
			R.call(gx, ey - 1, 4, 1, K); R.call(gx, ey + 2, 4, 1, K)
			R.call(gx, ey - 1, 1, 4, K); R.call(gx + 3, ey - 1, 1, 4, K)
		R.call(cx - 1, ey, 2, 1, K)
	im.set_pixel(cx, 17, _osc(piel, .82))                                  # la nariz
	var my := 19
	var lb := Color8(0x8a, 0x3a, 0x34)
	if boca:
		R.call(cx - 1, my, 3, 2, Color8(0x4a, 0x1e, 0x1e))
		R.call(cx - 1, my + 1, 3, 1, Color8(0xc0, 0x50, 0x50))
	elif expr == ALEGRE:
		R.call(cx - 2, my, 5, 1, lb); im.set_pixel(cx - 3, my - 1, lb); im.set_pixel(cx + 3, my - 1, lb)
	elif expr == ENFADO:
		R.call(cx - 2, my, 5, 1, lb); im.set_pixel(cx - 3, my + 1, lb); im.set_pixel(cx + 3, my + 1, lb)
	elif expr == DUDA:
		R.call(cx, my, 3, 1, lb)
	else:
		R.call(cx - 1, my, 4, 1, lb)
	if look.get("beard"):
		var bc := pelo.darkened(.1)
		R.call(cx - ancho + 1, 18, 2, 4, bc); R.call(cx + ancho - 3, 18, 2, 4, bc)
		R.call(cx - ancho + 2, 21, 2 * ancho - 4, 2, bc)
		R.call(cx - 2, my - 1, 5, 1, bc)
	if mujer:
		im.set_pixel(cx - 4, ey - 1, K); im.set_pixel(cx + 3, ey - 1, K)   # las pestañas
	# el contorno: todo lo que no es fondo y toca fondo
	var cp := im.duplicate()
	for y in W:
		for x in W:
			if cp.get_pixel(x, y) != FONDO:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < W and q.y < W and cp.get_pixelv(q) != FONDO and q.y < W - 1:
					im.set_pixel(x, y, K)
					break
	# el marco
	for i in W:
		im.set_pixel(i, 0, BORDE); im.set_pixel(i, W - 1, BORDE)
		im.set_pixel(0, i, BORDE); im.set_pixel(W - 1, i, BORDE)
	return im
