# Ribera Verde (Godot) — lo que el HTML dibuja por código también con atlas, píxel a píxel como su painter (01-tiles):
# la carpa del piso sin sprite (carpaMapa: armario 80 y carpa 120) y la vista B de 09b-carpa (cuarto34, carpa34, maceta34,
# planta34, foco34 y extra34). Cada pieza es una Image hecha una vez (con su rngSeed) y guardada en caché.
extends RefCounted

const Datos = preload("res://src/datos.gd")

static var cache := {}

static func col(h: String) -> Color:
	return Pintor.col(h)

# painter de 01-tiles: F (fillRect), P (un píxel), blob, noise y box, todo con colores opacos y coordenadas enteras
class Pintor:
	var im: Image
	var R
	var w := 0
	var h := 0
	static func col(c: String) -> Color:
		var n := Datos.hexi(c)
		return Color8((n >> 16) & 255, (n >> 8) & 255, n & 255)
	func _init(w_: int, h_: int, seed: int) -> void:
		w = w_
		h = h_
		im = Image.create(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)
		R = Datos.rng_seed(seed)
	func r() -> float:
		return R.sig()
	func F(a: int, b: int, ww: int, hh: int, c: String) -> void:
		if ww < 0:
			a += ww
			ww = -ww
		if hh < 0:
			b += hh
			hh = -hh
		var x0 := maxi(a, 0)
		var y0 := maxi(b, 0)
		var x1 := mini(a + ww, w)
		var y1 := mini(b + hh, h)
		if x1 > x0 and y1 > y0:
			im.fill_rect(Rect2i(x0, y0, x1 - x0, y1 - y0), col(c))
	func P(a: int, b: int, c: String) -> void:
		if a >= 0 and b >= 0 and a < w and b < h:
			im.set_pixel(a, b, col(c))
	func blob(cx: float, cy: float, rx: float, ry: float, fill: String, out: String, hi := "", dark := "") -> void:
		var ins := func(px: int, py: int) -> bool:
			var dx := (px + .5 - cx) / rx
			var dy := (py + .5 - cy) / ry
			return dx * dx + dy * dy <= 1
		var py := int(floor(cy - ry - 1))
		while py <= cy + ry + 1:
			var px := int(floor(cx - rx - 1))
			while px <= cx + rx + 1:
				if ins.call(px, py):
					var edge: bool = not ins.call(px - 1, py) or not ins.call(px + 1, py) or not ins.call(px, py - 1) or not ins.call(px, py + 1)
					var c := out if edge else fill
					if not edge:
						var dx := (px + .5 - cx) / rx
						var dy := (py + .5 - cy) / ry
						if hi != "" and dx + dy < -.55 and r() < .75:
							c = hi
						elif dark != "" and dx + dy > .5 and r() < .55:
							c = dark
					P(px, py, c)
				px += 1
			py += 1
	func noise(n: int, cols: Array, x0 := 0, y0 := 0, ww := 16, hh := 16) -> void:
		for i in n:
			var x := x0 + int(floor(r() * ww))
			var y := y0 + int(floor(r() * hh))
			P(x, y, cols[int(floor(r() * cols.size()))])
	func box(a: int, b: int, ww: int, hh: int, fill: String, out: String) -> void:
		F(a, b, ww, hh, out)
		F(a + 1, b + 1, ww - 2, hh - 2, fill)
	# drawLeafPx: hoja de abanico de 7 foliolos
	func hoja(cx: float, cy: float, s: float, c: String) -> void:
		for L in [[-90, 1.0], [-60, .82], [-120, .82], [-28, .58], [-152, .58], [0, .32], [180, .32]]:
			var a: float = L[0] * PI / 180
			var dx := cos(a)
			var dy := sin(a)
			var ln: float = s * 2 * L[1]
			var wd: float = maxf(.6, s * .34 * L[1])
			var py := int(floor(cy - ln - 2))
			while py <= cy + ln + 2:
				var px := int(floor(cx - ln - 2))
				while px <= cx + ln + 2:
					var vx := px + .5 - cx
					var vy := py + .5 - cy
					var tt := (vx * dx + vy * dy) / ln
					if tt >= 0 and tt <= 1:
						var d := absf(vx * dy - vy * dx)
						if d <= wd * sin(PI * tt) + .15:
							P(px, py, c)
					px += 1
				py += 1
		F(Datos.jsround(cx), Datos.jsround(cy), 1, maxi(2, Datos.jsround(s)), c)
	func linea(a: Array, b: Array, c: String) -> void:
		var n := maxi(maxi(absi(b[0] - a[0]), absi(b[1] - a[1])), 1)
		for k in n + 1:
			P(Datos.jsround(a[0] + (b[0] - a[0]) * float(k) / n), Datos.jsround(a[1] + (b[1] - a[1]) * float(k) / n), c)

static func VK() -> Dictionary:
	return Datos.carga().VK

# el mueble del piso: frente de tela negra y techo visto desde arriba; pies en (w/2, alto − 1)
static func carpa_mapa(tk: String) -> Image:
	var key := "cm|" + tk
	if cache.has(key):
		return cache[key]
	var cm: Array = Datos.carga().CARPAS[tk].cm
	var w := Datos.jsround(cm[0] * .16)
	var hf := Datos.jsround(cm[1] * .16)
	var ht := Datos.jsround(cm[2] * .08)
	var t := Pintor.new(w, hf + ht, w)
	var K := VK()
	t.F(0, 0, w, ht, K.techo)
	t.F(0, 0, w, 1, K.hi)
	t.F(0, ht - 1, w, 1, K.hi)
	t.F(0, 0, 1, ht, K.pole)
	t.F(w - 1, 0, 1, ht, K.pole)
	if ht >= 6:
		t.F(w - 7, 2, 4, 3, K.osc)
		t.F(w - 6, 2, 2, 1, K.som)
	t.F(0, ht, w, hf, K.tela)
	t.F(0, ht, 1, hf, K.pole)
	t.F(w - 1, ht, 1, hf, K.pole)
	t.F(0, ht + hf - 1, w, 1, K.osc)
	var dw := 6 if w < 12 else 8
	var dx := 3 if w >= 19 else (w - dw) >> 1
	var dy := ht + 3
	t.F(dx, dy + 1, dw, hf - 5, "#2e3036")
	t.F(dx + 1, dy, dw - 2, 1, "#a0a4ac")
	t.F(dx, dy + 1, 1, hf - 5, "#a0a4ac")
	t.F(dx + dw - 1, dy + 1, 1, hf - 5, "#a0a4ac")
	t.P(dx + dw - 2, dy + 3, "#e0e2e8")
	if w >= 19:
		t.F(w - 9, ht + hf - 9, 6, 4, K.osc)
		for i in range(0, 6, 2):
			t.F(w - 9 + i, ht + hf - 9, 1, 4, "#3a3c44")
	cache[key] = t.im
	return t.im

# la carpa abierta en 3/4: lienzo de (ancho + corrimiento + 2) × (alto + fondo + 3); el frente izquierdo del suelo en (1, alto − 2)
static func carpa34(tk: String) -> Image:
	var key := "c34|" + tk
	if cache.has(key):
		return cache[key]
	var D := Datos.carga()
	var VB: Dictionary = D.VB
	var cm: Array = D.CARPAS[tk].cm
	var W: float = cm[0]
	var H: float = cm[1]
	var Dp: float = cm[2]
	var w := Datos.jsround(W * VB.M)
	var s := Datos.jsround(Dp * VB.X)
	var hp := Datos.jsround(H * VB.M)
	var dp := Datos.jsround(Dp * VB.F)
	var t := Pintor.new(w + s + 2, hp + dp + 3, w * 5 + 3)
	var YF := hp + dp + 1
	var P := func(a: float, y: float, z: float) -> Array:
		return [Datos.jsround(1 + a * VB.M + y * VB.X), Datos.jsround(YF - y * VB.F - z * VB.M)]
	var K := VK()
	var bx0 := 1 + s
	var bx1 := s + w
	var by0 := YF - dp - hp
	var by1 := YF - dp
	for y in range(by0, by1 + 1):
		for xx in range(bx0, bx1 + 1):
			var u := xx - bx0
			var v := y - by0
			var a := (u + v) % 8
			var b := (u - v + 800) % 8
			t.P(xx, y, K.my2 if a == 0 or b == 0 else (K.my3 if a == 4 and b == 4 else (K.my4 if a < 3 and b < 3 else K.my)))
	var xx := bx0 + 3
	while xx < bx1:
		t.F(xx, by0 + 2, 1, hp - 4, "#e6e9f0")
		xx += 17
	for k in range(1, s + 1):
		var x2 := bx0 - k
		var y0 := by0 + Datos.jsround(float(k) * dp / s)
		var y1 := by1 + Datos.jsround(float(k) * dp / s)
		for y in range(y0, y1 + 1):
			t.P(x2, y, K.som if (y - y0 + k * 3) % 8 == 0 else (K.lado2 if k > s / 2.0 else K.lado))
	for y in range(by1 + 1, YF + 1):
		var k := float(YF - y) / dp
		var xl := 1 + Datos.jsround(k * s)
		t.F(xl, y, w, 1, K.my4 if (YF - y) % 6 == 5 else K.my3)
	var a := 25
	while a < W:
		t.linea(P.call(a, 0, 0), P.call(a, Dp, 0), K.my4)
		a += 25
	t.F(bx0, by1, w, 1, K.som)
	for e in [[[0, Dp, 0], [0, Dp, H]], [[W, Dp, 0], [W, Dp, H]], [[0, Dp, H], [W, Dp, H]], [[0, Dp, H], [0, 0, H]], [[0, 0, 0], [0, 0, H]], [[W, 0, H], [W, Dp, H]],
			[[W, 0, 0], [W, 0, H]], [[W, 0, 0], [W, Dp, 0]]]:
		t.linea(P.callv(e[0]), P.callv(e[1]), K.marco)
	t.F(1, YF, w, 2, K.marco)
	t.F(1, YF, w, 1, K.marco2)
	t.linea(P.call(0, Dp / 2, H - 4), P.call(W, Dp / 2, H - 4), K.marco2)
	var bo: Array = P.call(W - 12, Dp, H - 14)
	t.blob(bo[0], bo[1], 3.5, 3.5, "#26272c", K.som)
	cache[key] = t.im
	return t.im

# el cuarto: pared del piso y suelo de tarima en 3/4 (240 × 160: la pared llega a VB.PARED)
static func cuarto34() -> Image:
	if cache.has("cuarto"):
		return cache.cuarto
	var t := Pintor.new(240, 160, 11)
	var c := "#ead8b4"
	var y0 := int(Datos.carga().VB.PARED)
	t.F(0, 0, 240, y0, c)
	for i in range(3, 240, 8):
		t.F(i, 0, 1, y0 - 5, Datos.shade(c, -8))
	t.F(0, y0 - 5, 240, 5, "#f4ecd8")
	t.F(0, y0 - 5, 240, 1, "#c8b896")
	t.F(0, y0 - 1, 240, 1, "#a89470")
	for y in range(y0, 160):
		t.F(0, y, 240, 1, "#b48446" if (y - y0) % 4 == 3 else "#d8a868")
	for y in range(y0, 160, 4):
		for i in 5:
			t.F(int(floor(t.r() * 236)) + 2, y, 1, 3, "#b48446")
	t.noise(240, ["#e6bc80"], 0, y0, 240, 160 - y0)
	t.F(190, 104, 7, 5, "#f4f4ee")
	t.F(190, 104, 7, 1, "#c8c8c0")
	t.P(192, 106, "#3a3a44")
	t.P(194, 106, "#3a3a44")
	t.F(193, 109, 1, y0 - 109 - 5, "#5a5e68")
	cache.cuarto = t.im
	return t.im

static func maceta_px(k: String) -> Dictionary:
	var D := Datos.carga()
	var M: Array = D.MACETA_CM.get(k, D.MACETA_CM.plastico7)
	var VB: Dictionary = D.VB
	return {"w": Datos.jsround(M[0] * VB.M), "e": maxi(3, Datos.jsround(M[0] * VB.F)), "hb": Datos.jsround(M[1] * VB.M)}

# maceta en 3/4: lienzo w × (hb + e); el centro de la base en (w/2, e/2 + hb)
static func maceta34(k: String) -> Image:
	var key := "m34|" + k
	if cache.has(key):
		return cache[key]
	var D := Datos.carga()
	var M: Array = D.MACETA_CM.get(k, D.MACETA_CM.plastico7)
	var cu: String = M[2]
	var bo: String = M[3]
	var tela: bool = M[4] != 0
	var mp := maceta_px(k)
	var w: int = mp.w
	var e: int = mp.e
	var hb: int = mp.hb
	var t := Pintor.new(w, hb + e, w)
	var r := w / 2.0
	var ry := e / 2.0
	var dentro := func(px: int, py: int, cy: float, rx: float, ryy: float) -> bool:
		var dx := (px + .5 - r) / rx
		var dy := (py + .5 - cy) / ryy
		return dx * dx + dy * dy <= 1
	for py in hb + e:
		for px in w:
			var cuerpo: bool = py >= ry and py <= ry + hb and (tela or absf(px + .5 - r) <= r - (py - ry) / hb)
			var fondo: bool = dentro.call(px, py, ry + hb, r - (0.0 if tela else 1.0), ry)
			if cuerpo or fondo:
				t.P(px, py, Datos.shade(cu, 14) if px < r * .5 else (Datos.shade(cu, -10) if px > r * 1.4 else cu))
	for py in e:
		for px in w:
			if dentro.call(px, py, ry, r, ry):
				t.P(px, py, ("#3a2a1c" if py < ry else "#5a3a20") if dentro.call(px, py, ry, r - 1.2, ry - 1) else bo)
	if tela:
		t.F(1, Datos.jsround(ry + hb * .45), w - 2, 1, Datos.shade(cu, -18))
		t.F(0, Datos.jsround(ry + 1), 1, 2, Datos.shade(bo, -20))
		t.F(w - 1, Datos.jsround(ry + 1), 1, 2, Datos.shade(bo, -20))
	cache[key] = t.im
	return t.im

# alto en px de la planta en la vista B; en una plaza q, con su tope (q.ch)
static func alto_planta(po: String, st: int, dead: bool, q = null) -> int:
	var D := Datos.carga()
	var P: Dictionary = D.PLANTA_CM[po]
	var h := Datos.jsround(P.h[2 if dead else st] * D.VB.M)
	if q != null:
		h = mini(h, int(floor(q.ch * D.VB.M)))
	return h - (4 if dead else 0)

# planta en 3/4 de un porte y una fase (9 = muerta). Lienzo 48 × 80 con la base del tallo en (24, 79)
static func planta34(po: String, st: int, dry: bool, bud: String, cw := 1e9, ch := 1e9) -> Image:
	var key := "p34|%s%d%s%s|%d|%d" % [po, st, dry, bud, Datos.jsround(minf(cw, 999)), Datos.jsround(minf(ch, 999))]
	if cache.has(key):
		return cache[key]
	var D := Datos.carga()
	var VB: Dictionary = D.VB
	var t := Pintor.new(48, 80, st * 7 + po.unicode_at(0))
	var B := 79
	var cx := 24
	var mu := st == 9
	var f := 2 if mu else st
	var PC: Dictionary = D.PLANTA_CM[po]
	var H := mini(Datos.jsround(PC.h[f] * VB.M), int(floor(ch * VB.M))) - (4 if mu else 0)
	var A: float = minf(PC.w[f], cw) * VB.M / 2
	var top := B - H + 1
	var g1 := "#b8aa48" if dry else "#3c9a3e"
	var g2 := "#8a7c30" if dry else "#22662a"
	var g3 := "#d8cc78" if dry else "#74d064"
	var ta := "#6a5430" if mu else g2
	var hoja := func(hx: float, hy: float, s: float) -> void:
		if mu:
			t.hoja(hx, hy + s * .8, s * .8, "#5a4a28")
			return
		t.hoja(hx, hy, s + .6, g2)
		t.hoja(hx, hy, s, g1)
		if s > 2.2:
			t.hoja(hx, hy - .5, s * .45, g3)
	var cogollo := func(bx: float, by: float, rx: float, ryy: float) -> void:
		t.blob(bx, by, rx, ryy, bud, Datos.shade(bud, -60), Datos.shade(bud, 50))
	if st == 0:
		t.F(cx, top + 2, 1, H - 2, g2)
		t.blob(cx - 2, top + 1.5, 2, 1.2, g1, g2, g3)
		t.blob(cx + 3, top + 1.5, 2, 1.2, g1, g2, g3)
		cache[key] = t.im
		return t.im
	if f == 1:
		t.F(cx, top + 3, 1, H - 3, g2)
		hoja.call(cx - 3, B - H * .45, 1.5)
		hoja.call(cx + 3, B - H * .6, 1.5)
		hoja.call(cx + .5, top + 3, 1.6)
		cache[key] = t.im
		return t.im
	var pisos := 5 if po == "s" else 6
	var abeto := .3 if po == "s" else .62
	var flor := f >= 3 and not mu
	var ry := ((1.25 if st == 4 else .95) * (1.5 if po == "s" else (.9 if po == "i" else 1.15))) if flor else 0.0
	var cima := top + (Datos.jsround(ry * 5) if flor else 4)
	t.F(cx - (1 if f >= 3 else 0), cima, 2 if f >= 3 else 1, B - cima, ta)
	for n in pisos:
		var k := float(n) / (pisos - 1)
		var y := Datos.jsround(B - H * (.22 + .62 * k)) + (2 if mu else 0)
		var hw := A * (1 - abeto * k)
		var s := maxf(1.3, minf(4.2, hw * .3))
		var bx := hw - s * 1.1
		var by := Datos.jsround(bx * (-.1 if mu else .45))
		var ty := maxi(y - by, top + int(ceil((s + .6) * 1.75)))
		var r := 1.1 + s * .28
		for d in [-1, 1]:
			t.linea([cx, y], [Datos.jsround(cx + d * bx), ty], ta)
			hoja.call(cx + d * bx, ty, s)
			if k < .7 and not mu:
				hoja.call(cx + d * bx * .45, y - Datos.jsround(by * .45) + 1, s * .7)
			if flor and n > 0:
				cogollo.call(cx + d * bx, maxf(ty - s * 1.3, top + r * ry * 1.3), r, r * ry * 1.3)
	if flor:
		var r := 2.6 if st == 4 else 2.0
		var rr := r * ry * 1.9
		cogollo.call(cx + .5, top + rr, r, rr)
		if st == 4:
			for i in 8:
				var px := cx - 2 + int(floor(t.r() * 5))
				var py := top + 1 + int(floor(t.r() * rr * 1.6))
				t.P(px, py, "#ffffff")
	else:
		hoja.call(cx + .5, top + 4.5, 1.6 if mu else 2.2)
	cache[key] = t.im
	return t.im

# foco colgado en 3/4, a su ancho real; lienzo (ancho + 2) × 10 con la parte de abajo en la última fila
static func foco34(id: String) -> Image:
	var key := "f34|" + id
	if cache.has(key):
		return cache[key]
	var D := Datos.carga()
	var tipo: String = D.FOCOS[id].tipo
	var w := Datos.jsround(D.FOCO_CM.get(id, 40) * D.VB.M)
	var W := w + 2
	var t := Pintor.new(W, 10, w)
	var cx := W >> 1
	var trap := func(y0: int, y1: int, a0: int, a1: int, c: String, hi: String) -> void:
		for y in range(y0, y1 + 1):
			var a := Datos.jsround(a0 + (a1 - a0) * float(y - y0) / maxi(1, y1 - y0))
			t.F(cx - (a >> 1), y, a, 1, hi if y == y0 and hi != "" else c)
	if tipo == "cfl":
		trap.call(1, 5, 6, w, "#e8eaf0", "#ffffff")
		t.F(cx - (w >> 1), 5, w, 1, "#a8aebb")
		t.F(cx - 1, 0, 2, 1, "#5a5e68")
		for i in [-2, 0, 2]:
			t.F(cx + i, 6, 1, 3, "#fffbe8")
		t.F(cx - 2, 9, 5, 1, "#d8d8c8")
	elif tipo == "sodio":
		trap.call(1, 6, Datos.jsround(w * .55), w, "#c8ccd6", "#e8eaf0")
		t.F(cx - (w >> 1), 6, w, 1, "#8a8e98")
		t.F(cx - Datos.jsround(w * .3), 7, Datos.jsround(w * .6), 2, "#ffb040")
		t.F(cx - Datos.jsround(w * .25), 7, Datos.jsround(w * .5), 1, "#ffe0a0")
		t.F(cx - 3, 0, 6, 1, "#5a5e68")
	elif id == "led720":
		t.F(1, 4, w, 1, "#2a2b30")
		t.F(1, 8, w, 1, "#2a2b30")
		for i in 6:
			var bx := 1 + Datos.jsround(i * (w - 4) / 5.0)
			t.F(bx, 4, 4, 5, "#1c1d22")
			t.F(bx, 9, 4, 1, "#ff70c0" if i % 2 else "#f4f0ff")
	else:
		t.F(1, 5, w, 1, "#3a3c44")
		t.F(1, 6, w, 3, "#1c1d22")
		t.F(2, 7, w - 2, 1, "#2a2b30")
		var d := ["#ff70c0", "#f4f0ff", "#c070ff"]
		for i in int(floor(w / 3.0)):
			t.F(2 + i * 3, 9, 2, 1, d[i % 3])
		t.F(cx - 3, 4, 6, 1, "#5a5e68")
	cache[key] = t.im
	return t.im

# extras de la carpa: ventilador de pinza, filtro de carbón con su extractor y depósito de goteo; base en la última fila, centrada
static func extra34(k: String) -> Image:
	var key := "x34|" + k
	if cache.has(key):
		return cache[key]
	var t: Pintor
	if k == "vent":
		t = Pintor.new(11, 14, 5)
		t.blob(5.5, 5, 5, 5, "#c8ccd6", "#3a3c44", "#e8eaf0")
		t.blob(5.5, 5, 1.6, 1.6, "#5a5e68", "#2a2b30")
		for ab in [[2, 2], [8, 2], [2, 8], [8, 8]]:
			t.P(ab[0], ab[1], "#8a8e98")
		t.F(5, 10, 1, 2, "#3a3c44")
		t.F(3, 12, 5, 2, "#2a2b30")
	elif k == "filtro":
		t = Pintor.new(32, 12, 6)
		t.F(8, 1, 24, 10, "#4a4c54")
		for i in range(9, 31, 2):
			t.F(i, 2, 1, 8, "#5e6068")
		t.F(8, 1, 24, 1, "#6a6e78")
		t.F(8, 10, 24, 1, "#2a2b30")
		t.F(30, 1, 2, 10, "#2a2b30")
		t.blob(4, 6, 3.5, 3.5, "#3a3c44", "#1c1d22", "#6a6e78")
		t.F(6, 4, 2, 4, "#a8aebb")
	else:
		t = Pintor.new(16, 24, 7)
		t.F(1, 6, 14, 18, "#2e4a66")
		t.F(1, 6, 14, 1, "#5a7a98")
		t.F(1, 12, 14, 1, "#4a6a88")
		t.F(2, 13, 12, 10, "#3a5a7c")
		t.blob(8, 4, 7, 3, "#26303a", "#1c1d22", "#3a4a5a")
		t.F(6, 0, 1, 4, "#1c1d22")
		t.F(9, 0, 1, 4, "#1c1d22")
	cache[key] = t.im
	return t.im

# ---------- antialias como el del canvas (lo que no cae en píxeles enteros) ----------
# cobertura exacta de un polígono convexo en cada píxel (recorte de Sutherland-Hodgman y área): {Vector2i: 0-1}
static func _recorta(pol: PackedVector2Array, x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	var p := pol
	for lado in 4:
		var o := PackedVector2Array()
		var n := p.size()
		for i in n:
			var a := p[i]
			var b := p[(i + 1) % n]
			var ia := _dentro(a, lado, x0, y0, x1, y1)
			var ib := _dentro(b, lado, x0, y0, x1, y1)
			if ia:
				o.append(a)
			if ia != ib:
				o.append(_corte(a, b, lado, x0, y0, x1, y1))
		p = o
		if p.is_empty():
			break
	return p

static func _dentro(v: Vector2, lado: int, x0: float, y0: float, x1: float, y1: float) -> bool:
	match lado:
		0: return v.x >= x0
		1: return v.x <= x1
		2: return v.y >= y0
	return v.y <= y1

static func _corte(a: Vector2, b: Vector2, lado: int, x0: float, y0: float, x1: float, y1: float) -> Vector2:
	var t := 0.0
	match lado:
		0: t = (x0 - a.x) / (b.x - a.x)
		1: t = (x1 - a.x) / (b.x - a.x)
		2: t = (y0 - a.y) / (b.y - a.y)
		_: t = (y1 - a.y) / (b.y - a.y)
	return a + (b - a) * t

static func area(p: PackedVector2Array) -> float:
	var s := 0.0
	for i in p.size():
		var a := p[i]
		var b := p[(i + 1) % p.size()]
		s += a.x * b.y - b.x * a.y
	return absf(s) / 2

static func cobertura(pol: PackedVector2Array) -> Dictionary:
	var o := {}
	var bb := Rect2(pol[0], Vector2.ZERO)
	for v in pol:
		bb = bb.expand(v)
	for y in range(int(floor(bb.position.y)), int(ceil(bb.end.y))):
		for x in range(int(floor(bb.position.x)), int(ceil(bb.end.x))):
			var c := _recorta(pol, x, y, x + 1, y + 1)
			if c.size() >= 3:
				var a := area(c)
				if a > 0:
					o[Vector2i(x, y)] = minf(1, a)
	return o
