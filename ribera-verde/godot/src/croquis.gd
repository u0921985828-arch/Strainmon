# Ribera Verde (Godot) — 1.42: el mapa de la comarca y el calendario (lo pidió el usuario: «un mapa donde se vean todos los
# pueblos, no detalladamente pero modo croquis texturizado» y «que empiece el juego el 20 de abril de 2026»). Todo propio:
# el croquis se pinta píxel a píxel en una imagen (papel con su grano, el mar con sus olas, la ría, el monte, los bosques,
# los campos, los pueblos con sus casas y las líneas de autobús a trazos con sus minutos) y las letras son una fuente de 3 × 5
# hecha aquí. Los pueblos sin línea todavía (PARADAS.cap > S.ch) salen en gris. El calendario, una hoja del mes con la semana
# de lunes a domingo, hoy marcado y los días señalados (plazos, recibos, encargos, la asamblea).
extends RefCounted

const Datos = preload("res://src/datos.gd")

const MW := 232   # el croquis
const MH := 112
const CW := 16    # una casilla del calendario
const CH := 12

# la fuente de 3 × 5 (filas de 3 bits, de arriba abajo)
const F := {
	"A": [2, 5, 7, 5, 5], "B": [6, 5, 6, 5, 6], "C": [3, 4, 4, 4, 3], "D": [6, 5, 5, 5, 6], "E": [7, 4, 6, 4, 7],
	"F": [7, 4, 6, 4, 4], "G": [3, 4, 5, 5, 3], "H": [5, 5, 7, 5, 5], "I": [7, 2, 2, 2, 7], "J": [1, 1, 1, 5, 2],
	"K": [5, 5, 6, 5, 5], "L": [4, 4, 4, 4, 7], "M": [5, 7, 7, 5, 5], "N": [6, 5, 5, 5, 5], "Ñ": [7, 0, 6, 5, 5],
	"O": [2, 5, 5, 5, 2], "P": [6, 5, 6, 4, 4], "Q": [2, 5, 5, 6, 3], "R": [6, 5, 6, 5, 5], "S": [3, 4, 2, 1, 6],
	"T": [7, 2, 2, 2, 2], "U": [5, 5, 5, 5, 7], "V": [5, 5, 5, 5, 2], "W": [5, 5, 7, 7, 5], "X": [5, 5, 2, 5, 5],
	"Y": [5, 5, 2, 2, 2], "Z": [7, 1, 2, 4, 7],
	"0": [7, 5, 5, 5, 7], "1": [2, 6, 2, 2, 7], "2": [6, 1, 2, 4, 7], "3": [6, 1, 2, 1, 6], "4": [5, 5, 7, 1, 1],
	"5": [7, 4, 6, 1, 6], "6": [3, 4, 7, 5, 7], "7": [7, 1, 2, 2, 2], "8": [7, 5, 7, 5, 7], "9": [7, 5, 7, 1, 6],
	"'": [2, 2, 0, 0, 0], ":": [0, 2, 0, 2, 0], "-": [0, 0, 7, 0, 0], ".": [0, 0, 0, 0, 2], "?": [6, 1, 2, 0, 2],
	"€": [3, 4, 7, 4, 3], "/": [1, 1, 2, 4, 4], " ": [0, 0, 0, 0, 0],
}
const SIN_TILDE := {"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U"}

# los píxeles de un texto (4 px por letra), desde (0, 0)
static func letras(t: String) -> Array:
	var r := []
	var x := 0
	for ch in t.to_upper():
		var g = F.get(SIN_TILDE.get(ch, ch), F["?"])
		for fy in 5:
			for fx in 3:
				if int(g[fy]) & (4 >> fx):
					r.append(Vector2i(x + fx, fy))
		x += 4
	return r

static func ancho(t: String) -> int:
	return max(0, t.length() * 4 - 1)

# un texto como rectángulos [x, y, 1, 1, color]
static func texto(rs: Array, x: int, y: int, t: String, c: String) -> void:
	for p in letras(t):
		rs.append([x + p.x, y + p.y, 1, 1, c])

# ---------- el croquis ----------
# los pueblos: p, en el croquis; z, las zonas del juego que caen en él; d, lo que cuenta al elegirlo
const PUEBLOS := {
	"puerto": {"p": [40, 30], "d": "Puerto Viejo, en la costa: el puerto, la lonja y el club de los marineros."},
	"town": {"p": [116, 48], "d": "Ribera Verde, tu barrio, en la ría: el piso de la tía, el barrio alto y los astilleros."},
	"ibarbide": {"p": [190, 34], "d": "Ibarbide, la ciudad grande: el Casco Viejo, el Ensanche y la Kale Zaharra."},
	"valdehierro": {"p": [48, 80], "d": "Valdehierro, el pueblo de las fábricas: naves, la chatarrería y tu nave."},
	"mendialde": {"p": [122, 94], "d": "Mendialde, el pueblo del monte: el caserío donde empezó todo."},
	"errotabarri": {"p": [194, 84], "d": "Errotabarri, la aldea del molino viejo, al final de la pista."},
}
const ORDEN := ["puerto", "town", "ibarbide", "errotabarri", "mendialde", "valdehierro"]
const ZONA := {"town": "town", "alto": "town", "astilleros": "town", "home": "town", "shop": "town", "bar": "town", "txaro": "town",
	"comisaria": "town", "almacen": "town", "club-rv": "town", "puerto": "puerto", "club-puerto": "puerto",
	"valdehierro": "valdehierro", "club-valde": "valdehierro", "nave": "valdehierro", "mendialde": "mendialde", "casa-ama": "mendialde",
	"errotabarri": "errotabarri", "ibarbide": "ibarbide", "ensanche": "ibarbide", "callejon": "ibarbide", "growcity": "ibarbide",
	"club-ibar": "ibarbide", "club-ens": "ibarbide", "disco": "ibarbide", "setas": "ibarbide",
	"disco-vip": "ibarbide", "est-rv": "town", "est-puerto": "puerto", "est-valde": "valdehierro", "est-mendi": "mendialde", "est-erro": "errotabarri", "est-ibar": "ibarbide",   # 1.47
	"pasillo": "town", "sotano": "town", "cuarto-t": "valdehierro", "nave-d": "valdehierro", "nave-h": "valdehierro", "muelle": "puerto", "franco": "puerto"}   # 1.51

static func pueblo_de(mapa: String) -> String:
	return ZONA.get(mapa, "town")

static func abierto(D: Dictionary, ch: int, k: String) -> bool:
	return ch >= int(D.PARADAS[k].cap)

static func _h(x: int, y: int, s := 0) -> float:
	var h: int = (x * 374761393 + y * 668265263 + s * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0

# ruido suave (por casillas de g px, bilineal)
static func _ruido(x: int, y: int, g: int, s: int) -> float:
	var gx := x / g
	var gy := y / g
	var fx := float(x % g) / g
	var fy := float(y % g) / g
	var a := lerpf(_h(gx, gy, s), _h(gx + 1, gy, s), fx)
	var b := lerpf(_h(gx, gy + 1, s), _h(gx + 1, gy + 1, s), fx)
	return lerpf(a, b, fy)

static func costa(x: int) -> float:
	return 17.0 + 5.0 * sin(x * 0.07) + 3.0 * sin(x * 0.19 + 1.0) - (6.0 if x > 160 and x < 222 else 0.0) * sin(clampf((x - 160) / 62.0, 0, 1) * PI)

static func ria(y: int) -> float:
	return 112.0 + 5.0 * sin(y * 0.09) + y * 0.08

static func _px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < MW and y < MH:
		im.set_pixel(x, y, c)

static func _caja(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in h:
		for xx in w:
			_px(im, x + xx, y + yy, c)

static func _txt(im: Image, x: int, y: int, t: String, c: Color, borde: Color) -> void:
	var ps := letras(t)
	for p in ps:
		for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			_px(im, x + p.x + d.x, y + p.y + d.y, borde)
	for p in ps:
		_px(im, x + p.x, y + p.y, c)

static func _linea(im: Image, a: Vector2, b: Vector2, c: Color, trazo := 0) -> Array:
	var n := int(max(absf(b.x - a.x), absf(b.y - a.y)))
	var r := []
	for i in n + 1:
		var p := a.lerp(b, float(i) / max(1, n))
		if trazo == 0 or (i % (trazo * 2)) < trazo:
			_px(im, int(round(p.x)), int(round(p.y)), c)
		r.append(p)
	return r

static func es_mar(x: int, y: int) -> bool:
	if y < costa(x):
		return true
	var rx := ria(y)
	var w := 2.5 if y < 40 else (1.5 if y < 70 else 0.9)
	return absf(x - rx) < w

# la imagen del croquis para el capítulo ch (la cachea pinta.gd)
static func imagen(D: Dictionary, ch: int) -> Image:
	var im := Image.create(MW, MH, false, Image.FORMAT_RGBA8)
	var papel := Color8(226, 212, 172)
	for y in MH:
		for x in MW:
			var n := _ruido(x, y, 9, 1) * 0.6 + _ruido(x, y, 3, 2) * 0.25 + _h(x, y, 3) * 0.15
			var c: Color
			if es_mar(x, y):
				c = Color8(132, 170, 186).darkened(0.12 * n)
				if y < costa(x) - 3 and _h(x / 6, y / 4, 9) > 0.78 and (x % 6) < 3 and y % 4 == 1:
					c = Color8(196, 220, 226)   # las olas
			else:
				c = papel.darkened(0.16 * n)
				if absf(y - costa(x)) < 1.5:
					c = Color8(120, 100, 70)   # la línea de costa
			im.set_pixel(x, y, c)
	# el borde de la costa, doble (como en los croquis): una línea fina por fuera
	for x in MW:
		_px(im, x, int(costa(x)) - 3, Color8(110, 150, 168))
	# el monte de Mendialde y del sur: montañas en V con su sombra a rayas
	var montes := [[88, 102, 10], [100, 96, 12], [146, 100, 11], [160, 106, 9], [70, 104, 8], [136, 84, 8], [20, 104, 9], [212, 108, 8]]
	for m in montes:
		var mx: int = m[0]
		var my: int = m[1]
		var r: int = m[2]
		for i in r + 1:
			_px(im, mx - i, my - r + i, Color8(96, 80, 60))
			_px(im, mx + i, my - r + i, Color8(96, 80, 60))
			if i > 1 and i % 2 == 0:
				for j in range(1, i):
					if j % 2 == 0:
						_px(im, mx + j - 1, my - r + i, Color8(150, 130, 100))
	# los bosques: copas de 2 × 2 con su sombra, por manchas
	var bosques := [[70, 54, 16], [152, 60, 15], [24, 58, 12], [94, 74, 12], [166, 92, 10], [214, 60, 12], [140, 42, 8]]
	for b in bosques:
		for q in 26:
			var a: float = _h(q, b[0], 4) * TAU
			var d: float = sqrt(_h(q, b[1], 5)) * b[2]
			var tx := int(b[0] + cos(a) * d)
			var ty := int(b[1] + sin(a) * d * 0.6)
			if es_mar(tx, ty) or es_mar(tx + 1, ty + 1):
				continue
			_caja(im, tx, ty, 2, 2, Color8(78, 112, 62))
			_px(im, tx, ty, Color8(118, 150, 82))
			_px(im, tx + 1, ty + 2, Color8(150, 132, 96))
	# los campos de Errotabarri: parcelas a rayas
	var campos := [[176, 70, 12, 8, 0], [190, 92, 14, 7, 1], [208, 76, 10, 9, 1], [172, 84, 9, 6, 0]]
	for c in campos:
		for yy in c[3]:
			for xx in c[2]:
				if (yy + (xx if c[4] else 0)) % 3 == 0:
					_px(im, c[0] + xx, c[1] + yy, Color8(176, 168, 96))
		for xx in c[2]:
			_px(im, c[0] + xx, c[1] - 1, Color8(140, 120, 80))
	# las líneas de autobús, desde Ribera Verde, a trazos (en gris si aún no hay línea), con sus minutos
	var rv: Array = PUEBLOS.town.p
	for k in ORDEN:
		if k == "town":
			continue
		var pp: Array = PUEBLOS[k].p
		var ok := abierto(D, ch, k)
		var a := Vector2(rv[0], rv[1])
		var b := Vector2(pp[0], pp[1])
		var m := (a + b) / 2 + Vector2(0, 6 if b.y < a.y else -6).rotated(0.4 if b.x > a.x else -0.4)
		var col := Color8(122, 58, 40) if ok else Color8(160, 150, 130)
		_linea(im, a, m, col, 2)
		_linea(im, m, b, col, 2)
		var t := "%d'" % int(D.PARADAS[k].min)
		_txt(im, int(m.x) - ancho(t) / 2, int(m.y) - 2, t, col, papel)
	# los pueblos: casitas (y lo suyo: grúas, chimeneas, el molino, el muelle)
	for k in ORDEN:
		var ok := abierto(D, ch, k)
		var p: Array = PUEBLOS[k].p
		var cx: int = p[0]
		var cy: int = p[1]
		var casa := Color8(150, 64, 48) if ok else Color8(150, 144, 132)
		var tejado := Color8(96, 40, 32) if ok else Color8(118, 112, 104)
		var nc: int = {"town": 14, "ibarbide": 22, "puerto": 8, "valdehierro": 9, "mendialde": 6, "errotabarri": 5}[k]
		var rr: int = {"town": 9, "ibarbide": 12, "puerto": 6, "valdehierro": 7, "mendialde": 5, "errotabarri": 5}[k]
		for q in nc:
			var a: float = _h(q, cx, 7) * TAU
			var d: float = sqrt(_h(q, cy, 8)) * rr
			var hx := int(cx + cos(a) * d)
			var hy := int(cy + sin(a) * d * 0.6)
			if es_mar(hx, hy) or es_mar(hx + 2, hy + 2):
				continue
			_caja(im, hx, hy + 1, 3, 2, casa)
			_caja(im, hx, hy, 3, 1, tejado)
		if k == "ibarbide":   # las calles del Ensanche, en cuadrícula
			for i in 4:
				_linea(im, Vector2(cx - 2 + i * 5, cy + 4), Vector2(cx - 2 + i * 5, cy + 12), Color8(120, 100, 80))
			_linea(im, Vector2(cx - 3, cy + 8), Vector2(cx + 14, cy + 8), Color8(120, 100, 80))
		elif k == "town":   # las grúas de los astilleros en la desembocadura
			for g in [[cx - 6, cy - 20], [cx + 6, cy - 22]]:
				_linea(im, Vector2(g[0], g[1]), Vector2(g[0], g[1] + 7), tejado)
				_linea(im, Vector2(g[0] - 2, g[1]), Vector2(g[0] + 4, g[1]), tejado)
		elif k == "valdehierro":   # chimeneas con humo
			for g in [[cx + 6, cy - 6], [cx + 9, cy - 5]]:
				_caja(im, g[0], g[1], 1, 5, tejado)
				_px(im, g[0] + 1, g[1] - 2, Color8(170, 160, 150))
				_px(im, g[0] + 2, g[1] - 3, Color8(190, 182, 170))
		elif k == "errotabarri":   # el molino: la rueda
			for i in 8:
				var an := i * TAU / 8
				_px(im, cx + 8 + int(round(cos(an) * 3)), cy - 3 + int(round(sin(an) * 3)), tejado)
			_px(im, cx + 8, cy - 3, tejado)
		elif k == "puerto":   # el muelle y una barca
			_linea(im, Vector2(cx - 4, cy - 6), Vector2(cx - 4, cy - 12), Color8(96, 72, 48))
			_caja(im, cx + 2, cy - 11, 4, 1, Color8(96, 72, 48))
			_px(im, cx + 3, cy - 12, Color8(240, 236, 220))
		elif k == "mendialde":   # el caserío
			_caja(im, cx - 10, cy - 2, 5, 3, casa)
			_linea(im, Vector2(cx - 11, cy - 2), Vector2(cx - 8, cy - 5), tejado)
			_linea(im, Vector2(cx - 8, cy - 5), Vector2(cx - 5, cy - 2), tejado)
		var nm: String = D.PARADAS[k].n
		var ly: int = cy + (rr * 6 / 10) + 4
		if k == "town":
			ly = cy + 9
		_txt(im, cx - ancho(nm) / 2, ly, nm, Color8(40, 30, 24) if ok else Color8(120, 114, 104), papel)
	# el mar con su nombre, la rosa de los vientos y el marco doble
	_txt(im, 70, 6, "MAR", Color8(70, 104, 124), Color8(150, 186, 200))
	var rx := MW - 12
	var ry := 9
	_linea(im, Vector2(rx, ry - 5), Vector2(rx, ry + 5), Color8(70, 60, 50))
	_linea(im, Vector2(rx - 5, ry), Vector2(rx + 5, ry), Color8(70, 60, 50))
	_txt(im, rx - 1, ry - 12, "N", Color8(70, 60, 50), Color8(150, 186, 200))
	for i in MW:
		for e in [0, 2]:
			_px(im, i, e, Color8(84, 62, 40))
			_px(im, i, MH - 1 - e, Color8(84, 62, 40))
	for j in MH:
		for e in [0, 2]:
			_px(im, e, j, Color8(84, 62, 40))
			_px(im, MW - 1 - e, j, Color8(84, 62, 40))
	return im

# (lo pidió el usuario): centrados como la nevera y la caja fuerte, a lo ancho y en el alto que deja libre el cuadro del texto
const LIBRE := 133   # sin cuadro a la vista (las pruebas), lo que deja uno de dos líneas: 180 − 47

static func centro_y(h: int, alto: int) -> int:
	return maxi(2, (alto - h) >> 1)

static func origen_mapa(sw: int, alto := LIBRE) -> Vector2i:
	return Vector2i((sw - MW) >> 1, centro_y(MH, alto))

# encima de la imagen: el marco del pueblo elegido y la chincheta de dónde estás (rectángulos [x, y, w, h, color])
static func rects_mapa(sw: int, V: Dictionary, aqui: String, alto := LIBRE) -> Array:
	var o := origen_mapa(sw, alto)
	var rs := []
	var p: Array = PUEBLOS[ORDEN[int(V.i)]].p
	var x: int = o.x + p[0] - 12
	var y: int = o.y + p[1] - 8
	for e in [[x, y, 24, 1], [x, y + 15, 24, 1], [x, y, 1, 16], [x + 23, y, 1, 16]]:
		rs.append([e[0], e[1], e[2], e[3], "#f8d040"])
	var q: Array = PUEBLOS[aqui].p
	var cx: int = o.x + q[0]
	var cy: int = o.y + q[1] - 7
	rs.append([cx - 1, cy - 3, 3, 3, "#e03028"])   # la chincheta
	rs.append([cx, cy - 2, 1, 1, "#ff9080"])
	rs.append([cx, cy, 1, 3, "#30303a"])
	return rs

static func desc_mapa(D: Dictionary, ch: int, V: Dictionary, aqui: String) -> String:
	var k: String = ORDEN[int(V.i)]
	var t: String = PUEBLOS[k].d
	if k == aqui:
		t += " Estás aquí."
	if Datos.CAL and not Datos.PLAY and k == "ibarbide" and ch >= int(D.SETAS.ch):   # 1.43.8: el bajo de las setas, en el mapa
		t += " " + D.SETAS_SITIO.mapa
	if k == "town":
		t += "\nDe su plaza salen todos los autobuses."
	elif abierto(D, ch, k):
		t += "\nAutobús: %d min, %s." % [int(D.PARADAS[k].min), Datos.eur(D.PARADAS[k].eur)]
	else:
		t += "\nSin autobús hasta el capítulo %d." % int(D.PARADAS[k].cap)
	return t

static func mueve_mapa(V: Dictionary, b: String) -> bool:
	if b == "left" or b == "up":
		V.i = posmod(int(V.i) - 1, ORDEN.size())
		return true
	if b == "right" or b == "down":
		V.i = posmod(int(V.i) + 1, ORDEN.size())
		return true
	return false

# ---------- el calendario ----------
static func alto_cal(V: Dictionary) -> int:
	var s0: int = Datos.fecha(Datos.dia_de(V.y, V.m, 1)).s
	return 22 + int(ceil((s0 + Datos.dias_mes(V.y, V.m)) / 7.0)) * CH + 4

static func origen_cal(sw: int, V: Dictionary, alto := LIBRE) -> Vector2i:
	return Vector2i((sw - (7 * CW + 8)) >> 1, centro_y(alto_cal(V) + 4, alto) + 2)

# los días señalados del mes que se ve: [{d (día de partida), c (color), t (texto)}]
static func rects_cal(sw: int, V: Dictionary, hoy: int, marcas: Array, alto := LIBRE) -> Array:
	var o := origen_cal(sw, V, alto)
	var rs := []
	var W := 7 * CW + 8
	var y: int = V.y
	var m: int = V.m
	var nd := Datos.dias_mes(y, m)
	var d1 := Datos.dia_de(y, m, 1)
	var s0: int = Datos.fecha(d1).s
	var H := alto_cal(V)
	rs.append([o.x - 2, o.y - 2, W + 4, H + 4, "#54402a"])
	rs.append([o.x, o.y, W, H, "#f0e6c8"])
	rs.append([o.x, o.y, W, 11, "#3a6a3a"])
	var tit := "%s %d" % [Datos.MES_N[m - 1], y]
	texto(rs, o.x + (W - ancho(tit)) / 2, o.y + 3, tit, "#f8f0d8")
	for i in 7:
		texto(rs, o.x + 4 + i * CW + 6, o.y + 14, "LMXJVSD"[i], "#a03020" if i == 6 else "#54402a")
	for d in nd:
		var k := s0 + d
		var cx := o.x + 4 + (k % 7) * CW
		var cy := o.y + 22 + (k / 7) * CH
		var dia := d1 + d
		var fondo := "#e4d8b4" if k % 7 >= 5 else "#f8f0d8"
		if dia < hoy:
			fondo = "#d8ccaa"
		if dia == hoy:
			fondo = "#f8d040"
		rs.append([cx, cy, CW - 1, CH - 1, fondo])
		var t := str(d + 1)
		texto(rs, cx + (CW - 1 - ancho(t)) / 2, cy + 2, t, "#8a7a60" if dia < hoy else ("#a03020" if k % 7 == 6 else "#30281c"))
		var nm := 0
		for e in marcas:
			if int(e.d) == dia and nm < 3:
				rs.append([cx + 2 + nm * 4, cy + 8, 3, 2, e.c])
				nm += 1
	return rs

static func desc_cal(V: Dictionary, hoy: int, marcas: Array) -> String:
	var t := "Hoy es %s." % Datos.fd_larga(hoy)
	var d1 := Datos.dia_de(V.y, V.m, 1)
	var d2 := d1 + Datos.dias_mes(V.y, V.m) - 1
	var L := []
	for e in marcas:
		if int(e.d) >= d1 and int(e.d) <= d2 and int(e.d) >= hoy:
			L.append("%d, %s" % [int(Datos.fecha(int(e.d)).d), e.t])
	if L.size() > 3:   # 1.43: el cuadro, de tres líneas como mucho; el resto, en los puntos de colores
		L = L.slice(0, 2) + ["y %d más" % (L.size() - 2)]
	if L.size():
		t += " En %s: %s." % [Datos.MES_N[V.m - 1], " · ".join(L)]
	t += "\nFlechas: otro mes · B: cerrar."
	return t

static func mueve_cal(V: Dictionary, b: String) -> bool:
	var dm := -1 if b == "left" or b == "up" else (1 if b == "right" or b == "down" else 0)
	if dm == 0:
		return false
	var m: int = V.m + dm
	V.y = int(V.y) + (1 if m > 12 else (-1 if m < 1 else 0))
	V.m = posmod(m - 1, 12) + 1
	return true
