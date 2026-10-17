# Ribera Verde (Godot) — 1.38: la escena de cada extracción encima de su barra (lo pidió el usuario: «que sea visual»). Las máquinas
# son las del piso (tools/sprites/a-mano/extraccion.py: la lavadora de carga superior, el cubo de mallas, la prensa de palanca, los
# tamices y la máquina de static), con sus mismos colores y partes, a 3 o 4 veces su tamaño, y se mueven como en el proceso de
# verdad: la lavadora con el agua, el hielo y los cogollos dando vueltas y el desagüe por la manguera a las bolsas; el tamiz con los
# cogollos desmenuzados, que se tambalea y deja caer el polen al papel de cocina; la palanca que baja las planchas y el rosin que
# sale por los lados del papel; la placa cargada a la altura de la barra, con las cabezas subiendo; el charas frotado de la planta
# viva; el hachís prensado y el moonrock bañado y rebozado. Pixel art propio, a rectángulos, animado con el reloj (now, ms) y con la
# barra (p). Solo se pinta si el TIRO lleva «esc» (extraer, trama.gd); el billar y las pantallas de antes no la llevan.
extends RefCounted

const W := 160
const H := 76

static var P = null   # el pintor (pinta.gd)
static var X := 0
static var Y := 0
static var OX := 0    # el origen y la escala de la máquina (en píxeles de su sprite)
static var OY := 0
static var SC := 3

static var K := Color("#2a2a34")   # el contorno de los muebles (el de extraccion.py)
static var VERDE := Color("#4f8a3a")
static var VERDE_C := Color("#78b450")
static var VERDE_O := Color("#2f5a26")
static var PISTILO := Color("#d9853a")
static var KIEF := Color("#e8d890")
static var KIEF_C := Color("#f4e8b0")
static var KIEF_O := Color("#c9a648")
static var HIELO := Color("#d8f0ff")
static var AGUA := Color("#3a6ab0")
static var AGUA_C := Color("#7aaae0")
static var AMBAR := Color("#e0a828")
static var AMBAR_C := Color("#f6d060")
static var HACHIS := Color("#6b4a2a")
static var PAPEL := Color("#f4f0e0")
static var PAPEL_O := Color("#d8d2c0")
static var M0 := Color("#5a3a20")   # la madera (la de extraccion.py)
static var M1 := Color("#8a5a32")
static var M2 := Color("#c8935a")
static var M3 := Color("#e0b07a")
static var PIEL := Color("#d09a70")
static var PIEL_O := Color("#a06a48")
static var CALOR := Color("#f05030")

static func pinta(pintor, T: Dictionary, now: float, x0: int, y0: int) -> void:
	P = pintor
	X = x0
	Y = y0
	var t := now / 1000.0
	var p: float = pintor.J.pos_tiro(T, now)
	var i := int(T.get("paso", 0))
	var n := int(T.get("n", 1))
	P._rect(X - 2, Y - 2, W + 4, H + 10, Color("#26262e"))
	match String(T.esc):
		"lava": lava(i, t, p)
		"ice": ice(i, t, p)
		"seco": seco(i, n, t, p)
		"rosin": rosin(i, t, p)
		"charas": charas(i, t, p)
		"hash": hachis(i, t, p)
		"moon": moon(i, t, p)
		"stat": stat(i, t, p)
		_: r(0, 0, W, H, Color("#2b2f3a"))
	for k in n:   # los pasos: hechos, el de ahora y los que quedan
		P._rect(X + W - 6 * n + 6 * k, Y + H + 3, 4, 3, Color("#58d080") if k == i else Color("#a0a0a8") if k < i else Color("#4a4a54"))

# ── ayudas ──
static func r(x: float, y: float, w: float, hh: float, c: Color) -> void:   # un rectángulo, recortado al recuadro
	var a := maxi(floori(x), 0)
	var b := maxi(floori(y), 0)
	var a2 := mini(floori(x + w), W)
	var b2 := mini(floori(y + hh), H)
	if a2 > a and b2 > b:
		P._rect(X + a, Y + b, a2 - a, b2 - b, c)

static func px(x: float, y: float, c: Color) -> void:
	r(x, y, 1, 1, c)

static func borde(x: float, y: float, w: float, hh: float, c: Color) -> void:   # el rectángulo con el contorno de los muebles
	r(x - 1, y - 1, w + 2, hh + 2, K)
	r(x, y, w, hh, c)

static func elipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var R := int(ceil(ry))
	for dy in range(-R, R + 1):
		var f := 1.0 - float(dy * dy) / maxf(ry * ry, .01)
		if f < 0:
			continue
		var hw := int(rx * sqrt(f) + .5)
		r(roundi(cx) - hw, roundi(cy) + dy, 2 * hw + 1, 1, c)

static func disco(cx: float, cy: float, rr: float, c: Color) -> void:
	elipse(cx, cy, rr, rr, c)

static func linea(x0: float, y0: float, x1: float, y1: float, c: Color, g := 1) -> void:
	var nn := maxi(int(maxf(absf(x1 - x0), absf(y1 - y0))), 1)
	for k in nn + 1:
		var f := float(k) / nn
		r(roundi(lerpf(x0, x1, f)), roundi(lerpf(y0, y1, f)), g, g, c)

static func h(k: float) -> float:   # un azar fijo por número
	return fposmod(sin(k * 12.9898 + 78.233) * 43758.5453, 1.0)

static func fr(v: float) -> float:
	return fposmod(v, 1.0)

# la máquina en píxeles de su sprite (32 × 32), a SC veces
static func so(ox: int, oy: int, s: int) -> void:
	OX = ox
	OY = oy
	SC = s

static func q(x: float, y: float, w: float, hh: float, c: Color) -> void:
	r(OX + x * SC, OY + y * SC, w * SC, hh * SC, c)

static func qk(x: float, y: float, w: float, hh: float) -> void:   # el contorno de una pieza
	r(OX + x * SC - 1, OY + y * SC - 1, w * SC + 2, hh * SC + 2, K)

static func hl(x0: int, x1: int, y: int, c: Color) -> void:
	q(x0, y, x1 - x0 + 1, 1, c)

static func vl(x: int, y0: int, y1: int, c: Color) -> void:
	q(x, y0, 1, y1 - y0 + 1, c)

static func sx(x: float) -> float:   # de píxel del sprite a píxel del recuadro
	return OX + x * SC

static func sy(y: float) -> float:
	return OY + y * SC

static func cuarto(suelo: int) -> void:   # la pared del piso y el suelo de tarima
	r(0, 0, W, suelo, Color("#5a5068"))
	for k in 11:
		r(k * 16 + 5, 0, 1, suelo, Color("#544a62"))
	r(0, suelo - 3, W, 3, Color("#3a3240"))
	r(0, suelo, W, H - suelo, Color("#8a6644"))
	for k in 3:
		r(0, suelo + 4 + k * 5, W, 1, Color("#76563a"))

static func mesa(y: int) -> void:   # la mesa de madera de la tía (la de extraccion.py, más grande), de y para abajo
	cuarto(y + 8)
	r(0, y - 1, W, 1, K)
	r(0, y, W, 4, M2)
	r(0, y, W, 1, M3)
	r(0, y + 4, W, 2, M1)
	r(0, y + 6, W, 1, K)
	for x in [8, W - 14]:
		r(x, y + 7, 6, H - y - 7, M0)
		r(x, y + 7, 1, H - y - 7, M1)

static func cogollo(x: float, y: float, s := 1.0, giro := 0.0, capa := 0.0, frio := false) -> void:   # capa: 1 rebozado de kief
	disco(x, y, 3 * s + .6, K)
	disco(x, y, 3 * s, VERDE_O.lerp(KIEF_O, capa * .8))
	disco(x - s, y - s, 2 * s, VERDE.lerp(KIEF_O, capa))
	disco(x + s, y - .5 * s, 1.6 * s, VERDE_C.lerp(KIEF, capa))
	for k in 3:   # los pelos naranjas y la resina, girando
		var a := giro + k * 2.1
		px(x + cos(a) * 2 * s, y + sin(a) * 2 * s, PISTILO.lerp(KIEF_C, capa))
	px(x - s, y - 2 * s, KIEF_C)
	if frio:   # la escarcha de la flor congelada
		px(x + s, y - 2 * s, Color.WHITE)
		px(x - 2 * s, y, Color("#e8f4ff"))

static func cubito(x: float, y: float) -> void:
	r(x - 2, y - 2, 4, 4, HIELO)
	r(x - 2, y - 2, 2, 1, Color.WHITE)
	r(x - 2, y + 1, 4, 1, Color("#98c8e8"))

static func cae(x: float, y0: float, y1: float, w: float, nn: int, t: float, v: float, cols: Array) -> void:   # partículas que caen
	for k in nn:
		var yy := y0 + fr(t * v + h(k + 40)) * (y1 - y0)
		px(x + h(k) * w, yy, cols[k % cols.size()])

static func monton(cx: float, base: float, ancho: float, alto: int, c: Color, c2: Color) -> void:   # un montoncito
	for f in alto:
		var w := ancho * (1.0 - float(f) / (alto + 1))
		r(cx - w / 2, base - f - 1, w, 1, c if f % 2 else c2)

static func calor(x: float, y: float, w: float, alto: float, t: float, c: Color) -> void:   # el aire caliente que tiembla
	for k in int(w / 6):
		for j in 3:
			var yy := y - fr(t * .9 + h(k) + j * .33) * alto
			px(x + 3 + k * 6 + roundi(sin(yy * .7 + k) * 1.2), yy, c)

static func esfera(cx: int, cy: int, p: float, zona := .5, ancho := .12) -> void:   # termómetro de esfera o manómetro: la aguja es la barra
	disco(cx, cy, 8, K)
	disco(cx, cy, 7, Color("#e8e8ec"))
	for k in 5:
		var a := PI * (.75 + 1.5 * (zona - ancho + 2 * ancho * k / 4.0))
		px(cx + cos(a) * 6, cy + sin(a) * 6, Color("#38b060"))
	var a := PI * (.75 + 1.5 * clampf(p, 0, 1))
	linea(cx, cy, cx + cos(a) * 5, cy + sin(a) * 5, Color("#c02020"))
	px(cx, cy, K)

static func mano(cx: float, cy: float, izq: bool, resina: float) -> void:   # la palma abierta, de frente
	elipse(cx, cy, 13, 10, K)
	for k in 4:
		r(cx - 10 + k * 5.5 - 1, cy - 19 + absi(k - 1) * 2 - 1, 6, 13, K)
	for k in 4:
		r(cx - 10 + k * 5.5, cy - 19 + absi(k - 1) * 2, 4, 12, PIEL)
		r(cx - 10 + k * 5.5, cy - 19 + absi(k - 1) * 2, 4, 1, Color("#e8b890"))
	elipse(cx, cy, 12, 9, PIEL)
	r(cx + (10 if izq else -15), cy - 4, 5, 9, PIEL)   # el pulgar
	r(cx - 8, cy + 6, 16, 1, PIEL_O)
	for k in int(resina * 30):   # la película oscura de la resina
		px(cx - 8 + h(k) * 16, cy - 6 + h(k + 33) * 12, Color("#3a2616") if k % 2 else Color("#5a3a20"))

# ── la lavadora de extracción (lavadora en extraccion.py, a 3×) ──
static var B0 := Color("#1a3a8a")
static var B1 := Color("#2a52b8")
static var B2 := Color("#3a6ad8")
static var B3 := Color("#6a98ec")
static var W0 := Color("#b8c0c8")
static var W1 := Color("#dde2e8")
static var W2 := Color("#f6f8fa")
static var BOLSAS := [Color("#7ac060"), Color("#e0c040"), Color("#58a8e0"), Color("#e05a6a")]   # 220 (la de trabajo), 120, 90, 73

static func lavadora(ox: int, oy: int, t: float, lleno: float, ang: float, abierta: bool, marcha: bool, cosas: int) -> void:
	so(ox, oy, 3)
	qk(10, 25, 12, 6)
	qk(10, 13, 12, 12)
	qk(9, 11, 14, 2)
	q(10, 25, 12, 6, W1)   # la base
	vl(10, 25, 30, W2)
	vl(21, 25, 30, W0)
	hl(10, 21, 31, W0)
	hl(11, 20, 27, W0)
	q(13, 29, 1, 1, W0)
	q(18, 29, 1, 1, W0)
	q(10, 13, 12, 12, B1)   # la cuba translúcida
	vl(10, 13, 24, B2)
	vl(21, 13, 24, B0)
	var x0 := sx(11)   # lo de dentro, que se ve a través del plástico
	var x1 := sx(21)
	var fondo := sy(25)
	var sup := lerpf(fondo - 2, sy(14), lleno)
	if lleno > 0:
		r(x0, sup, x1 - x0, fondo - sup, B0)
		r(x0, sup, x1 - x0, 1, Color("#5a8acc"))
	var cx := (x0 + x1) / 2
	var cy := (sup + fondo) / 2 if lleno > .2 else fondo - 4
	var rx := (x1 - x0) / 2 - 4
	var ry := maxf((fondo - sup) / 2 - 4, 1)
	for capa in 2:   # detrás (más oscuro, a través del agua) y delante
		for k in cosas:
			var a := ang * (1.0 + .15 * (k % 3)) + k * TAU / cosas
			var delante := sin(a) > 0
			if delante != (capa == 1):
				continue
			var x := cx + cos(a) * rx * (.5 + .5 * h(k))
			var y := cy + sin(a) * ry + (h(k + 3) - .5) * 4
			if k % 3 == 2:
				cubito(x, y)
				if not delante:
					r(x - 2, y - 2, 4, 4, Color(B0, .45))
			else:
				cogollo(x, y, .9, a * 2 + k)
				if not delante:
					disco(x, y, 3, Color(B0, .45))
	if marcha and lleno > 0:   # la espuma y el remolino
		for k in 10:
			var a := ang * 1.3 + h(k) * TAU
			px(cx + cos(a) * rx, sup + 1 + (k % 2), Color("#e8f4ff"))
	vl(11, 14, 23, Color(B3, .8))
	for xx in [14, 17]:   # los nervios de la cuba
		q(xx, 14, 1, 4, Color(B2, .7))
	q(9, 11, 14, 2, W2)   # el aro blanco
	hl(9, 22, 12, W0)
	if abierta:   # la tapa abierta, echada hacia atrás: se ve de canto
		qk(10, 9, 12, 1)
		q(10, 9, 12, 1, B1)
		q(10, 9, 12, 1.0 / 3, B3)
		q(19, 8, 1, 1, K)
	else:
		qk(10, 8, 12, 3)
		q(10, 8, 12, 3, B2)
		hl(10, 21, 8, B3)
		hl(12, 18, 10, B1)
		q(12, 9, 5, 1, W2)
	q(18, 7, 4, 2, W1)   # la tira de los dos mandos
	q(19, 7, 1, 1, Color("#58f080") if marcha and fr(t) < .6 else B1)
	q(21, 7, 1, 1, B1)
	vl(22, 13, 28, W2)   # la manguera de desagüe
	vl(23, 14, 29, W0)
	q(23, 13, 1, 1, W1)
	hl(22, 24, 30, W0)

# el cubo de 20 L con las bolsas de malla (mallas en extraccion.py, a 3× o 4×), abierto por delante para ver lo de dentro
static func cubo(ox: int, oy: int, s: int, nivel: float, bolsas: int, ver_dentro := true) -> Dictionary:
	so(ox, oy, s)
	qk(9, 17, 14, 15)
	q(10, 17, 12, 14, Color("#e8ecee"))
	vl(10, 17, 30, Color.WHITE)
	vl(21, 17, 30, Color("#b8c0c4"))
	hl(9, 22, 17, Color("#c8d0d4"))
	hl(11, 20, 31, Color("#a8b0b4"))
	hl(10, 21, 22, Color("#c8d0d4"))
	var cx0 := sx(11)
	var cx1 := sx(21)
	var top := sy(18)
	var fondo := sy(30)
	if ver_dentro:   # la ventana del corte
		r(cx0 - 1, top - 1, cx1 - cx0 + 2, fondo - top + 2, K)
		r(cx0, top, cx1 - cx0, fondo - top, Color("#2a3440"))
		var sup := lerpf(fondo, top + 1, nivel)
		r(cx0, sup, cx1 - cx0, fondo - sup, AGUA)
		if nivel > 0:
			r(cx0, sup, cx1 - cx0, 1, AGUA_C)
		for k in bolsas:   # las paredes de malla de las bolsas, una dentro de otra
			var c: Color = BOLSAS[BOLSAS.size() - bolsas + k]
			r(cx0 + 1 + k * 2, top, 1, fondo - top - 1 - k * 2, Color(c, .8))
			r(cx1 - 2 - k * 2, top, 1, fondo - top - 1 - k * 2, Color(c, .8))
			r(cx0 + 1 + k * 2, fondo - 2 - k * 2, cx1 - cx0 - 2 - k * 4, 1, Color(c, .8))
	for k in bolsas:   # las bolsas, colgadas del borde
		var c: Color = BOLSAS[BOLSAS.size() - bolsas + k]
		var x := 9 + k * 4
		q(x, 15, 3, 2, c)
		q(x, 15, 3, 1, c.lightened(.25))
	return {"x0": cx0, "x1": cx1, "top": top, "fondo": fondo}

static func bolsa(x: float, y: float, w: float, hh: float, c: Color, dentro: Color, cuanto: float) -> void:   # una bolsa de malla colgando
	r(x - 1, y - 1, w + 2, hh + 2, K)
	r(x, y, w, hh, c.darkened(.35))
	for yy in range(int(y) + 3, int(y + hh) - 1, 2):
		for xx in range(int(x) + 1, int(x + w) - 1, 2):
			px(xx + (yy >> 1) % 2, yy, c.darkened(.15))
	r(x, y, w, 3, c)
	r(x, y, w, 1, c.lightened(.3))
	if cuanto > 0:
		var dh := 2 + cuanto * 4
		r(x + 2, y + hh - dh - 1, w - 4, dh, dentro)
		r(x + 3, y + hh - dh - 1, w - 6, 1, dentro.lightened(.25))

static func lava(i: int, t: float, p: float) -> void:
	cuarto(62)
	var vib := roundi(sin(t * 40)) if i == 1 else 0
	var lleno := 1.0
	var ang := 0.0
	if i == 0:   # cargarla: el agua con hielo entra y se echan los cogollos
		lleno = clampf(.25 + fr(t / 5) * 1.0, .25, 1)
		ang = t * .4
	elif i == 1:   # el lavado a baja velocidad: el bombo va a un lado y al otro
		ang = -cos(t * 1.1) * 6.5
	elif i == 2:   # reposo y desagüe
		lleno = 1.0 - fr(t / 5) * .85
		ang = .2 * sin(t)
	else:
		lleno = 0
	lavadora(-22 + vib, -21, t, lleno, ang, i == 0 or i == 3, i == 1, 9 if i < 2 else 6 if i == 2 else 0)
	if i == 0:
		for k in 3:   # el hielo cae dentro
			var f := fr(t * .8 + k * .33)
			cubito(36 + k * 9, -2 + f * 26)
		esfera(66, 14, p, .5)   # la temperatura: por debajo de 4 °C
		linea(60, 18, 44, 40, K)
	if i == 3:
		for k in 8:   # la bolsa de trabajo con la hoja lavada, al fondo
			px(36 + h(k) * 24, 66 + h(k + 4) * 5, VERDE_O)
	# la manguera hasta el cubo de las bolsas
	r(50, 69, 36, 3, K)
	r(50, 70, 36, 1, W1)
	r(84, 22, 3, 50, K)
	r(85, 22, 1, 49, W1)
	r(84, 20, 13, 3, K)
	r(85, 21, 11, 1, W1)
	var cb := cubo(60, -22, 3, .9 if i >= 2 else .1, 3 if i < 3 else 2)
	if i == 2:   # el agua baja por la manguera y cae a las bolsas
		for k in 6:
			var f := fr(t * 1.5 + k / 6.0)
			var d := f * 98
			var pp := Vector2(86 - (36 - d), 70) if d < 36 else Vector2(85, 70 - (d - 36)) if d < 86 else Vector2(85 + (d - 86), 21)
			px(pp.x, pp.y, AGUA_C)
		for k in 5:
			r(95 + (k % 2), 23 + fr(t * 3 + k / 5.0) * (cb.top - 20), 2, 2, AGUA_C)
		for k in 3:
			px(cb.x0 + 4 + fr(t + k * .3) * (cb.x1 - cb.x0 - 8), cb.top + 3, Color.WHITE)
	if i == 3:   # recoger cada bolsa aparte: sube, escurre y la resina se queda en el fondo
		var cual := int(t / 3) % 3
		var sube := minf(fr(t / 3) * 2.5, 1) * 26
		bolsa(cb.x0 + 2, cb.top - sube - 6, cb.x1 - cb.x0 - 4, 30, BOLSAS[cual + 1], KIEF_O.lerp(Color("#a8885a"), cual * .3), 1)
		for k in 3:
			px(cb.x0 + 8 + k * 9, cb.top - sube + 25 + fr(t * 2 + k * .3) * (sube + 6), AGUA_C)
		borde(132, 58, 24, 6, Color("#e8e0c8"))   # el tamiz de secar, en el suelo
		for k in cual:
			elipse(137 + k * 7, 60, 2, 1, KIEF_O)
			px(136 + k * 7, 60, KIEF)

# ── Ice-o-lator a mano: el cubo de mallas (a 4×), abierto por delante ──
static func ice(i: int, t: float, p: float) -> void:
	cuarto(64)
	if i == 3:   # secar la resina en frío: se desmenuza sobre el cartón con el tamiz fino y se airea
		borde(12, 50, 100, 18, Color("#c8a878"))   # el cartón
		r(16, 52, 92, 14, Color("#e8e0c8"))   # la malla de 25 µm encima
		for xx in range(18, 106, 3):
			r(xx, 52, 1, 14, Color("#d8d0b8"))
		var crece := 18 + int(fr(t / 8) * 46)
		for k in crece:
			r(20 + h(k) * 84, 54 + h(k + 30) * 10, 1 + int(h(k + 60) * 2), 1 + int(h(k + 90) * 2), KIEF_O if k % 3 else Color("#b8985a"))
		var tx := 34 + sin(t * 1.5) * 26   # el colador que la desmenuza
		borde(tx, 26, 28, 4, Color("#9aa0a8"))
		r(tx + 2, 22, 24, 4, Color("#b8985a"))
		for k in 3:
			r(tx + 4 + k * 8, 20, 5, 3, KIEF_O)
		cae(tx + 3, 31, 54, 22, 10, t, 1.6, [KIEF, KIEF_O])
		disco(134, 26, 15, K)   # el ventilador: aire, sin calor
		disco(134, 26, 14, Color("#d8dce2"))
		disco(134, 26, 12, Color("#2a2e36"))
		for k in 3:
			var a := t * 14 + k * TAU / 3
			linea(134, 26, 134 + cos(a) * 10, 26 + sin(a) * 10, Color("#c8ccd2"), 2)
		disco(134, 26, 2, Color("#d8dce2"))
		r(132, 41, 4, 23, K)
		r(133, 41, 2, 23, Color("#d8dce2"))
		for k in 5:
			px(118 - fr(t * 1.4 + k * .2) * 40, 22 + k * 3, Color("#c8e4f4"))
		return
	var nivel := .92
	var bolsas := 4
	if i == 2:
		bolsas = 4 - mini(int(t / 3) % 4, 3)
	var cb := cubo(-32, -54, 4, nivel, bolsas)
	var cx: float = (cb.x0 + cb.x1) / 2.0
	var sup: float = lerpf(cb.fondo, cb.top + 1, nivel)
	if i == 0:   # el agua con hielo, entre 1 y 3 °C: el termómetro es la barra
		for k in 6:
			cubito(cb.x0 + 5 + k * 6, sup + 2 + sin(t * 2 + k) * 1)
		for k in 4:
			cogollo(cb.x0 + 8 + k * 9, sup + 18 + sin(t * 1.3 + k) * 2 + (k % 2) * 8, 1.0, t + k, 0, true)
		for k in 3:
			var f := fr(t * .7 + k * .33)   # cae más hielo de la bolsa
			cubito(cb.x0 + 12 + k * 10, -4 + f * (sup - 2))
		linea(cx + 14, 2, cx + 14, sup + 20, K, 2)   # la sonda
		esfera(90, 22, p, .5)
		linea(84, 26, cx + 15, 8, K)
		for k in 4:
			px(cb.x0 + 4 + k * 10 + sin(t * 2 + k) * 2, cb.top - 3 - fr(t * .6 + k * .25) * 8, Color("#c8e4f4"))
	elif i == 1:   # remover suave: la pala da la vuelta y los cogollos giran sin romperse
		var a := t * 2.6
		var xp := cx + cos(a) * 12
		r(xp - 2, -2, 4, sup + 14, K)
		r(xp - 1, -2, 2, sup + 14, M2)
		r(xp - 4, sup + 10, 8, 10, K)
		r(xp - 3, sup + 11, 6, 8, M2)
		for k in 7:
			var b := a + k * TAU / 7
			var x: float = cx + cos(b) * 13
			var y: float = sup + 20 + sin(b) * 5 + (h(k) - .5) * 10
			if k % 3 == 2:
				cubito(x, y - 10)
			else:
				cogollo(x, y, .9 if sin(b) < 0 else 1.1, b * 3)
		for k in 8:
			var b := a * 1.3 + k * .8
			px(cx + cos(b) * 16, sup + 2 + sin(b) * 1.5, AGUA_C)
		disco(96, 24, 11, K)   # el reloj de cocina, los 15 minutos
		disco(96, 24, 10, Color("#e8e8ec"))
		var g := -PI / 2 + fr(t / 15) * TAU
		linea(96, 24, 96 + cos(g) * 7, 24 + sin(g) * 7, Color("#c02020"))
		r(94, 12, 4, 3, K)
	else:   # reposar y colar: se saca cada bolsa, escurre y la resina queda en el fondo
		var cual := 4 - bolsas
		var sube := minf(fr(t / 3) * 2.5, 1) * 40
		var c: Color = BOLSAS[cual]
		bolsa(cb.x0 + 1, cb.top - sube, cb.x1 - cb.x0 - 2, 44, c, VERDE.lerp(VERDE_O, .3) if cual == 0 else KIEF_O.lerp(Color("#a8885a"), (cual - 1) * .3), 1)
		for k in 4:
			px(cb.x0 + 6 + k * 8, cb.top - sube + 44 + fr(t * 2 + k * .25) * maxf(sube, 2), AGUA_C)
		borde(80, 54, 44, 6, Color("#c8a878"))   # el cartón con la malla, y la cuchara
		r(82, 54, 40, 4, Color("#e8e0c8"))
		for k in cual:
			elipse(88 + (k - 1) * 13, 55, 4, 1, KIEF_O)
			r(86 + (k - 1) * 13, 54, 3, 1, KIEF)
		var ch := 100 + sin(t * 2) * 10
		linea(ch, 50, ch + 16, 30, Color("#c8ccd2"), 2)
		elipse(ch, 51, 3, 1, Color("#c8ccd2"))

# ── Dry sift: los tamices de seda de su bastidor (tamizM, más grandes); el de ahora se tambalea y el polen cae al papel de cocina ──
static var SEDA := [Color("#8a8e96"), Color("#c8b878"), Color("#e8e0c0"), Color("#f4f0e0")]

static func tamiz(x: float, y: float, w: float, seda: Color, malla: int, dy: int) -> void:   # un bastidor de madera con la seda
	r(x - 1, y - 1, w + 2, 12, K)
	r(x, y, w, 10, M1)
	r(x, y, w, 1, M3)
	r(x + 4, y + 3, w - 8, 5 + dy, seda)
	for yy in range(int(y) + 3, int(y) + 8 + dy):   # la malla: más cerrada en cada paso
		for xx in range(int(x) + 4 + (yy % 2) * (malla >> 1), int(x + w) - 4, malla):
			px(xx, yy, seda.darkened(.3))

static func seco(i: int, n: int, t: float, p: float) -> void:
	mesa(52)
	borde(10, 50, 108, 6, PAPEL)   # el papel de cocina, a lo ancho de la mesa
	for k in 6:
		r(10 + k * 18, 50, 1, 6, PAPEL_O)
	for k in range(n - 1, i, -1):   # los que quedan, más finos, apilados en su bastidor a un lado
		var j := k - i - 1
		r(124, 40 - j * 6, 30, 5, K)
		r(125, 41 - j * 6, 28, 3, M1)
		r(126, 42 - j * 6, 26, 1, SEDA[mini(k, 3)])
	var dx := roundi(3 * sin(t * 16))
	var dy := roundi(sin(t * 16 + 1.2))
	var x0 := 26 + dx
	var malla: int = [4, 3, 2, 2][mini(i, 3)]
	for k in 18:   # los cogollos desmenuzados encima, saltando con el meneo
		var cx := x0 + 8 + h(k) * 62
		var cy := 18 - h(k + 20) * 4 + (1 if (k + int(t * 16)) % 2 else 0)
		var s := (1.0 - i * .2) * (.6 + h(k + 7) * .6)
		if s > .3:
			disco(cx, cy, 1.8 * s + .6, K)
			disco(cx, cy, 1.8 * s, VERDE_O if k % 2 else VERDE)
			px(cx, cy - 1, VERDE_C if k % 3 else KIEF_C)
	tamiz(x0, 20, 78, SEDA[mini(i, 3)], malla, dy)
	r(x0 - 7, 19 + dy, 7, 7, K)   # las manos que lo menean
	r(x0 - 6, 20 + dy, 6, 5, PIEL)
	r(x0 + 78, 19 - dy, 7, 7, K)
	r(x0 + 78, 20 - dy, 6, 5, PIEL)
	var cols: Array = [Color("#9aa050"), KIEF_O, Color("#7a9040")] if i == 0 else [KIEF, KIEF_O, KIEF_C]
	cae(x0 + 6, 31, 50, 66, 50, t, 1.3, cols)   # cae el polen
	var c1: Color = [Color("#b8b070"), Color("#d0bc78"), KIEF, KIEF_C][mini(i, 3)]
	monton(60, 50, 24 + i * 10 + fr(t / 6) * 8, 3 + 2 * i, c1, c1.darkened(.1))   # el montón crece
	if i == n - 1:   # al final, la tarjeta lo junta
		var f := fr(t / 2.5)
		borde(98 - f * 18, 42, 3, 8, Color("#c8c8d0"))

# ── la prensa de palanca (prensaM en extraccion.py, a 4×): la usan el rosin y el hachís ──
static func prensa(t: float, baja: float, palanca: float, brillo: float, carga: String) -> void:
	so(-4, -28, 4)
	for c in [[11, 20, 10, 2], [12, 9, 2, 11], [19, 9, 2, 11], [12, 8, 9, 2]]:
		qk(c[0], c[1], c[2], c[3])
	q(11, 20, 10, 2, Color("#3a3a40"))   # la base
	hl(11, 20, 20, Color("#5a5a62"))
	vl(12, 9, 19, Color("#c03a2a"))   # los postes y el puente
	vl(19, 9, 19, Color("#c03a2a"))
	vl(13, 9, 19, Color("#8a2a20"))
	vl(20, 9, 19, Color("#8a2a20"))
	q(12, 8, 9, 2, Color("#c03a2a"))
	hl(12, 20, 8, Color("#e05a44"))
	var px0 := sx(13)
	var pw := 7 * SC
	var yb := sy(18)   # la plancha de abajo
	var ya := sy(14) + baja * 6   # la de arriba baja con la palanca
	r(px0 - 1, yb - 1, pw + 2, 2 * SC + 2, K)
	r(px0, yb, pw, 2 * SC, Color("#b8bcc4"))
	r(px0, yb, pw, 1, Color("#e0e4ea"))
	var cal := Color("#5a3030").lerp(CALOR, brillo)
	r(px0, yb + 1, pw, 1, cal)
	var hueco := yb - (ya + 2 * SC)   # lo que hay entre las planchas
	if carga == "rosin" or carga == "hash":
		var ancho := 18 + baja * 8
		r(px0 - 4, yb - 2, pw + 8, 2, PAPEL)   # el papel de horno, doblado
		var hh := maxf(hueco - 2, 1)
		if carga == "rosin":   # la bolsa de malla con la flor, que se aplasta
			r(px0 + (pw - ancho) / 2, yb - 2 - hh, ancho, hh, VERDE.lerp(Color("#6a7038"), baja))
			for k in int(ancho / 3):
				px(px0 + (pw - ancho) / 2 + k * 3 + 1, yb - 2 - hh + 1, Color("#9aa078"))
			if baja > .2:   # el rosin sale por los lados del papel
				var sale := (baja - .2) * 14
				r(px0 - 4 - sale, yb - 2, sale + 4, 2, AMBAR)
				r(px0 + pw, yb - 2, sale + 4, 2, AMBAR)
				r(px0 - 4 - sale, yb - 2, sale + 4, 1, AMBAR_C)
				r(px0 + pw, yb - 2, sale + 4, 1, AMBAR_C)
				px(px0 - 2 - sale, yb + fr(t * 1.5) * 6, AMBAR)
		else:   # el kief envuelto se vuelve una placa de hachís
			r(px0 + (pw - ancho) / 2, yb - 2 - hh, ancho, hh, KIEF.lerp(HACHIS, baja))
			r(px0 + (pw - ancho) / 2, yb - 2 - hh, ancho, 1, KIEF_C.lerp(Color("#8a6040"), baja))
	r(px0 - 1, ya - 1, pw + 2, 2 * SC + 2, K)
	r(px0, ya, pw, 2 * SC, Color("#b8bcc4"))
	r(px0, ya, pw, 1, Color("#e0e4ea"))
	r(px0, ya + 2 * SC - 1, pw, 1, cal)
	r(px0 + 3, ya + 2, 2, 2, CALOR if brillo > .3 and fr(t * 1.5) < .6 else Color("#6a2a20"))   # la luz del calor
	if brillo > .4:
		calor(px0, ya - 1, pw, 6, t, Color(1, .6, .4, .7))
	var hx := sx(16)   # el husillo
	r(hx, sy(10), SC, ya - sy(10), Color("#5a5a62"))
	var pv := Vector2(sx(17), sy(10) + 1)   # la palanca, del eje a su puño negro
	var fin := pv + Vector2(cos(palanca), sin(palanca)) * 34
	linea(pv.x, pv.y - 1, fin.x, fin.y - 1, K, 4)
	linea(pv.x, pv.y, fin.x, fin.y, Color("#3a3a40"), 2)
	disco(fin.x, fin.y, 3, K)
	disco(fin.x, fin.y, 2, Color("#1a1a1e"))
	disco(pv.x, pv.y, 2, Color("#8a8e96"))

static func rosin(i: int, t: float, p: float) -> void:
	mesa(60)
	if i == 0:   # precalentar: las planchas cogen calor (el brillo es la barra); la bolsa espera en su papel
		prensa(t, 0, -.45, clampf(p, 0, 1), "")
		borde(96, 54, 30, 4, PAPEL)
		r(104, 50, 14, 4, K)
		r(105, 51, 12, 3, VERDE)
		esfera(132, 20, p, .5)
	elif i == 1:   # apretar despacio: la palanca baja, la bolsa se aplasta y el rosin corre por el papel
		var f := minf(fr(t / 4) * 1.25, 1)
		prensa(t, f, lerpf(-.45, .35, f), 1, "rosin")
		esfera(132, 20, p, .5)
	else:   # soltar a tiempo: se abre y el papel sale con el rosin; se recoge con la herramienta
		prensa(t, 0, -.7, .5, "")
		var sale := minf(fr(t / 3) * 2, 1)
		var x := 66 + sale * 40
		borde(x, 55, 40, 3, PAPEL)
		elipse(x + 20, 55, 13, 1, AMBAR)
		r(x + 12, 54, 16, 1, AMBAR_C)
		r(x + 16, 52, 8, 2, Color("#6a7038"))
		if sale >= 1:
			var g := x + 8 + fr(t / 1.2) * 24
			linea(g, 54, g + 10, 40, Color("#c8ccd2"), 2)

# ── Charas: se frota la flor de la planta viva, en el monte; se rasca la resina de las palmas y se amasa en una bola ──
static func monte() -> void:
	r(0, 0, W, H, Color("#9ac4e0"))
	r(0, 18, W, H, Color("#b8d8ec"))
	for x in W:   # las montañas
		var y1 := 22 + sin(x * .05) * 6 + sin(x * .13) * 3
		r(x, y1, 1, H - y1, Color("#6a7a90"))
		if y1 < 22:
			px(x, y1, Color("#e8eef4"))
		var y2 := 40 + sin(x * .07 + 2) * 4
		r(x, y2, 1, H - y2, Color("#4a6a3a"))
	r(0, 60, W, H - 60, Color("#3e5a2e"))

static func charas(i: int, t: float, p: float) -> void:
	monte()
	if i == 0:   # frotar la planta viva entre las palmas, sin arrancarla
		r(79, 44, 3, 32, K)   # el tallo y las hojas
		r(80, 44, 1, 32, VERDE_O)
		for k in 2:
			var y := 56 + k * 9
			for d in [-1, 1]:
				for j in 5:
					var a: float = -PI / 2 + d * (.5 + j * .3)
					linea(80, y, 80 + cos(a) * (8 + (2 - absi(j - 2)) * 3), y + sin(a) * 6 + 6, VERDE if j % 2 else VERDE_O)
		elipse(80, 34, 6, 14, K)   # la cola en flor
		elipse(80, 34, 5, 13, VERDE)
		for k in 10:
			px(77 + h(k) * 7, 22 + h(k + 3) * 24, PISTILO if k % 2 else KIEF_C)
		var dy := 6 * sin(t * 6)
		var res := clampf(.15 + fr(t / 8), 0, 1)
		mano(65, 38 + dy, true, res)
		mano(95, 38 - dy, false, res)
	elif i == 1:   # rascar la resina de las palmas
		r(0, 0, W, H, Color(0, 0, 0, .35))
		mano(80, 46, true, 1.0)
		var x := 64 + fr(t / 1.4) * 28
		r(x - 1, 26, 6, 24, K)
		r(x, 26, 4, 23, PIEL)
		r(x, 48, 4, 2, Color("#3a2616"))
		var b := 2 + fr(t / 6) * 3
		disco(62, 50, b + 1, K)
		disco(62, 50, b, Color("#3a2616"))
		px(61, 49, Color("#7a5a3a"))
	else:   # amasarla en una bola: brilla de la grasa
		r(0, 0, W, H, Color(0, 0, 0, .35))
		var dy := 3 * sin(t * 8)
		mano(56, 44 + dy, true, .5)
		mano(104, 44 - dy, false, .5)
		disco(80, 44, 7, K)
		disco(80, 44, 6, Color("#2e1e12"))
		var a := t * 6
		px(80 + cos(a) * 4, 44 + sin(a) * 4, Color("#8a6a4a"))
		px(80 + cos(a + 2.5) * 3, 44 + sin(a + 2.5) * 3, Color("#5a3a20"))
		px(78, 41, Color("#a08060"))

# ── Hachís prensado: el kief envuelto en papel, tibio entre las planchas de la prensa, y la palanca lo aprieta ──
static func hachis(i: int, t: float, p: float) -> void:
	mesa(60)
	if i == 0:
		prensa(t, .15, -.4, clampf(p, 0, 1) * .55, "hash")
		esfera(132, 20, p, .4)
		borde(98, 52, 22, 6, Color("#d8e8ec"))   # el cristal con el kief que queda
		monton(109, 52, 12, 3, KIEF, KIEF_C)
	else:
		var f := minf(fr(t / 3.5) * 1.3, 1)
		prensa(t, .15 + f * .85, lerpf(-.4, .35, f), .5, "hash")
		esfera(132, 20, p, .55)

# ── Moonrock: el rosin se funde en su bote, se baña el cogollo con las pinzas, se reboza en el kief del cristal y se seca ──
static func bote(x: float, y: float, rosin: float) -> void:   # el bote bajo de boca ancha (el de la nevera), sin la tapa
	r(x - 1, y - 1, 26, 18, K)
	r(x, y, 24, 16, Color(.85, .92, .96, .55))
	r(x, y + 16 - rosin * 12, 24, rosin * 12, AMBAR)
	r(x, y + 16 - rosin * 12, 24, 1, AMBAR_C)
	r(x, y + 14, 24, 2, Color("#c8d8e0"))   # el culo grueso
	r(x + 2, y + 2, 1, 10, Color.WHITE)

static func moon(i: int, t: float, p: float) -> void:
	mesa(60)
	if i <= 1:
		borde(30, 56, 40, 4, Color("#2a2a30"))   # la placa tibia
		r(34, 57, 4, 2, CALOR if fr(t * 2) < .6 else Color("#6a2a20"))
		bote(38, 40, .6)
		for k in 5:   # se funde y burbujea
			var f := fr(t * (.8 + h(k) * .6) + h(k + 3))
			px(40 + h(k + 8) * 20, 48 - f * 3, AMBAR_C)
		for k in 3:   # los cogollos que esperan
			cogollo(100 + k * 12, 54, 1.2, k)
	if i == 0:
		calor(38, 40, 24, 10, t, Color(1, .7, .4, .7))
		esfera(132, 16, p, .5)
		var g := 50 + sin(t * 2) * 6   # la herramienta lo remueve
		linea(g, 46, g + 14, 20, Color("#c8ccd2"), 2)
	elif i == 1:   # bañar el cogollo con las pinzas
		var baja := .5 - .5 * cos(t * 2)
		var y := 18 + baja * 26
		linea(48, -2, 50, y - 4, Color("#c8ccd2"), 2)
		linea(54, -2, 52, y - 4, Color("#c8ccd2"), 2)
		cogollo(50, y, 1.8, t)
		if baja > .6 or fr(t / PI) > .5:
			r(45, y + 1, 11, 4, AMBAR)
			px(50, y + 6 + fr(t * 3) * 6, AMBAR)
	elif i == 2:   # rebozarlo en el kief, en el cristal de los tamices
		borde(24, 52, 112, 6, Color("#d8e8ec"))
		monton(80, 52, 90, 4, KIEF, KIEF_C)
		var x := 80 + 26 * sin(t * 2)
		var capa := clampf(.3 + fr(t / 6), 0, 1)
		cogollo(x, 44, 2.0, x * .4, capa)
		for k in 5:
			px(x - 8 + h(k + int(t * 8)) * 16, 36 + h(k + 7) * 6, KIEF_C)
	else:   # secarlo sin que se pegue: en la rejilla, al aire
		borde(16, 46, 128, 2, Color("#8a8e96"))
		for k in 16:
			r(18 + k * 8, 47, 1, 12, K)
		for k in 3:
			cogollo(44 + k * 36, 39, 2.0, k, 1)
			if fr(t * .7 + k * .3) < .15:
				px(42 + k * 36, 32, Color.WHITE)
				px(43 + k * 36, 33, KIEF_C)
		for k in 4:
			px(150 - fr(t + k * .25) * 120, 18 + k * 4, Color("#8a8098"))

# ── Static: la máquina (staticM en extraccion.py, a 4×): la base negra con la bandeja, las guías, la placa cargada y su pantallita ──
static func maquina_static(t: float, placa: float, con_placa: bool, carga: float, verde: bool) -> void:
	so(-30, -30, 4)
	qk(10, 18, 12, 4)
	q(10, 18, 12, 4, Color("#24262c"))
	hl(10, 21, 18, Color("#3a3e46"))
	q(11, 17, 10, 1, Color("#8a8e96"))   # la bandeja
	var by := sy(17)
	monton(sx(16), by, 36, 2 + int(carga * 2), KIEF_C, Color.WHITE)
	vl(11, 9, 16, Color("#5a5e66"))   # las guías
	vl(20, 9, 16, Color("#5a5e66"))
	q(13, 19, 5, 2, Color("#0a1a10"))   # la pantallita: la altura de la placa
	r(sx(13) + 2, sy(19) + 3, (5 * SC - 4) * (1 - placa), 2, Color("#58f080"))
	q(20, 19, 1, 1, Color("#e04040"))
	q(22, 20, 1, 1, Color("#2a2a30"))   # el cable
	if con_placa:   # la placa, a su altura entre las guías
		var y := lerpf(sy(9), by - 10, placa)
		r(sx(10) - 1, y - 1, 12 * SC + 2, 2 * SC + 2, K)
		r(sx(10), y, 12 * SC, 2 * SC, Color("#c8e4f0"))
		r(sx(10), y, 12 * SC, 1, Color("#f0faff"))
		r(sx(12), y + 2 * SC - 2, 8 * SC, 2, Color("#f4e8b0"))
		var cerca := by - 3 - (y + 2 * SC)
		if cerca < 30:   # suben las cabezas
			for k in 26:
				var f := fr(t * 1.4 + h(k + 11))
				px(sx(11) + 2 + h(k) * (10 * SC - 4), by - 3 - f * cerca, Color.WHITE)
		if verde:   # demasiado cerca: sube también la hoja
			for k in 9:
				var f := fr(t * 1.1 + h(k + 21))
				px(sx(11) + 4 + h(k + 50) * (10 * SC - 8), by - 3 - f * cerca, VERDE_C)

static func placa_mesa(x: float, y: float, resina: float) -> void:   # la placa fuera, en la mesa
	r(x - 1, y - 1, 52, 6, K)
	r(x, y, 50, 4, Color("#c8e4f0"))
	r(x, y, 50, 1, Color("#f0faff"))
	if resina > 0:
		r(x + 4, y - 1, 42 * resina, 1, Color("#f4e8b0"))

static func stat(i: int, t: float, p: float) -> void:
	mesa(58)
	if i == 0:   # tamizar la flor congelada a la bandeja, con un tamiz en la mano
		maquina_static(t, 0, false, fr(t / 6), false)
		var dx := roundi(2 * sin(t * 14))
		tamiz(12 + dx, 18, 64, SEDA[2], 2, 0)
		for k in 8:
			cogollo(20 + dx + h(k) * 48, 15 - h(k + 2) * 2, .8, k, 0, true)
		cae(18 + dx, 29, 50, 52, 30, t, 1.2, [Color.WHITE, KIEF_C, Color("#d8e8f0")])
		for k in 4:
			px(20 + k * 14 + sin(t + k) * 3, 12 - fr(t * .5 + k * .25) * 12, Color("#b8d8f0"))
		placa_mesa(96, 52, 0)
	elif i == 1:   # cargar la placa: frotarla con el paño, saltan chispas
		maquina_static(t, 0, false, 1, false)
		placa_mesa(90, 52, 0)
		var f := fr(t / 1.2)
		var cx := 92 + (f if int(t / 1.2) % 2 == 0 else 1 - f) * 34
		borde(cx, 44, 14, 8, Color("#6a7a9a"))   # el paño
		r(cx, 44, 14, 1, Color("#8a9aba"))
		for k in 4:
			if h(k + int(t * 10)) > .5:
				px(cx - 6 + h(k + int(t * 10) + 5) * 30, 48 + (k % 3), Color("#f8f060"))
	elif i == 2:   # la altura: la placa sube y baja con la barra; suben las cabezas, y la hoja si está muy cerca
		maquina_static(t, clampf(p, 0, 1), true, 1, p > .78)
	else:   # rascar la placa con la tarjeta
		maquina_static(t, 0, false, .3, false)
		placa_mesa(86, 52, 1)
		var f := fr(t / 2)
		var cx := 88 + f * 44
		r(cx + 4, 51, 46 - f * 44, 1, Color.WHITE)
		borde(cx, 40, 4, 12, Color("#e8ecf2"))
		r(cx, 40, 4, 2, Color("#4a70c0"))
		monton(cx - 3, 52, 6 + f * 8, 2 + int(f * 2), Color.WHITE, KIEF_C)
