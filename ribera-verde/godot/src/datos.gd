# Ribera Verde (Godot) — los datos del juego HTML (datos/datos.json, lo saca tools/godot.js del index.html compilado) y las
# cuentas de color y de porte de 00-nucleo, 03-datos y 09b-carpa, con el mismo redondeo que JavaScript
extends RefCounted

static var D := {}

static func carga() -> Dictionary:
	if D.is_empty():
		D = JSON.parse_string(FileAccess.get_file_as_string("res://datos/datos.json"))
	return D

# Math.round de JavaScript: la mitad, hacia arriba (round() de Godot la aleja del cero)
static func jsround(x: float) -> int:
	return int(floor(x + 0.5))

# Uint8ClampedArray: la mitad, al par
static func u8(x: float) -> int:
	x = clampf(x, 0.0, 255.0)
	var f := floorf(x)
	var r := x - f
	if r > 0.5 or (r == 0.5 and int(f) % 2 == 1):
		f += 1.0
	return int(f)

# hashStr de 00-nucleo.js: FNV-1a de 32 bits
static func hash_str(s: String) -> int:
	var h := 2166136261
	for i in s.length():
		h = ((h ^ s.unicode_at(i)) * 16777619) & 0xffffffff
	return h

static func hexi(h: String) -> int:
	return h.substr(1).hex_to_int()

static func ihex(n: int) -> String:
	return "#%02x%02x%02x" % [(n >> 16) & 255, (n >> 8) & 255, n & 255]

static func mix(a: String, b: String, t := 0.5) -> String:
	var A := hexi(a)
	var B := hexi(b)
	var o := 0
	for s in [16, 8, 0]:
		o |= jsround(((A >> s) & 255) * (1 - t) + ((B >> s) & 255) * t) << s
	return ihex(o)

static func shade(h: String, amt: int) -> String:
	var n := hexi(h)
	var o := 0
	for s in [16, 8, 0]:
		o |= clampi(((n >> s) & 255) + amt, 0, 255) << s
	return ihex(o)

static func rgb_hls(h: String) -> Array:
	var n := hexi(h)
	var r := (n >> 16) / 255.0
	var g := ((n >> 8) & 255) / 255.0
	var b := (n & 255) / 255.0
	var M := maxf(r, maxf(g, b))
	var m := minf(r, minf(g, b))
	var l := (M + m) / 2
	var d := M - m
	if d == 0:
		return [0.0, l, 0.0]
	var s := d / (2 - M - m) if l > .5 else d / (M + m)
	var H: float
	if M == r:
		H = (g - b) / d + (6 if g < b else 0)
	elif M == g:
		H = (b - r) / d + 2
	else:
		H = (r - g) / d + 4
	return [H / 6, l, s]

static func hls_rgb(H: float, l: float, s: float) -> String:
	var q := l * (1 + s) if l < .5 else l + s - l * s
	var p := 2 * l - q
	var t := func(x: float) -> float:
		x = fmod(x + 1, 1)
		return p + (q - p) * 6 * x if x < 1.0 / 6 else (q if x < .5 else (p + (q - p) * (2.0 / 3 - x) * 6 if x < 2.0 / 3 else p))
	var f := func(v: float) -> int: return jsround(clampf(v, 0, 1) * 255)
	return ihex((f.call(t.call(H + 1.0 / 3)) << 16) | (f.call(t.call(H)) << 8) | f.call(t.call(H - 1.0 / 3)))

# ---------- variedades ----------
static func strain(S: Dictionary, sid: String):
	var d := carga()
	if d.STRAINS.has(sid):
		return d.STRAINS[sid]
	if S and S.has("custom") and S.custom.has(sid):
		return S.custom[sid]
	return null

static func tono_hoja(i: float) -> String:
	return mix("#8aa83e", "#57a33e", i / 65) if i <= 65 else mix("#57a33e", "#3f7a34", (i - 65) / 35)

static func ind_de(S: Dictionary, sid: String) -> float:
	var s = strain(S, sid)
	if s == null:
		s = {"d": 3.5}
	if s.get("ind") != null:
		return s.ind
	return 75.0 if s.d <= 3 else (20.0 if s.d >= 4.5 else 50.0)

static func hoja_de(S: Dictionary, sid: String) -> String:
	var s = strain(S, sid)
	return s.hj if s and s.get("hj") else tono_hoja(ind_de(S, sid))

static func f_i(p: Dictionary):
	return p.f.get("i") if p.get("f") is Dictionary else null

# tono de la hoja de una planta: el de su variedad, movido como el de su % índica respecto al de la variedad
static func hoja_planta(S: Dictionary, p: Dictionary) -> String:
	var h := hoja_de(S, p.sid)
	var i = f_i(p)
	var i0 := ind_de(S, p.sid)
	if i == null or i == i0:
		return h
	var A := hexi(tono_hoja(i))
	var B := hexi(tono_hoja(i0))
	var Hh := hexi(h)
	var o := 0
	for s in [16, 8, 0]:
		o |= clampi(((Hh >> s) & 255) + ((A >> s) & 255) - ((B >> s) & 255), 0, 255) << s
	return ihex(o)

static func porte_ind(i: float) -> String:
	return "i" if i >= 70 else ("s" if i < 30 else "h")

static func porte_planta(S: Dictionary, p: Dictionary) -> String:
	var i = f_i(p)
	return porte_ind(i if i != null else ind_de(S, p.sid))

# los verdes de la paleta A movidos en tono, luz y saturación como su verde medio (#57a33e) hasta el tono de la hoja hj
static var tonos_c := {}
static func vc_tonos(hj: String) -> Dictionary:
	if tonos_c.has(hj):
		return tonos_c[hj]
	var b := rgb_hls(hj)
	var r := rgb_hls("#57a33e")
	var o := {}
	for k in carga().VC_HOJA:
		var c := rgb_hls(k)
		o[k] = hls_rgb(fmod(c[0] + b[0] - r[0] + 1, 1), clampf(c[1] + b[1] - r[1], 0, 1), clampf(c[2] * b[2] / maxf(r[2], .01), 0, 1))
	tonos_c[hj] = o
	return o

static func miles(n: float) -> String:
	var s := str(jsround(n))
	var o := ""
	var neg := s.begins_with("-")
	if neg:
		s = s.substr(1)
	while s.length() > 3:
		o = "." + s.substr(s.length() - 3) + o
		s = s.substr(0, s.length() - 3)
	return ("-" if neg else "") + s + o

static func eur(n: float) -> String:
	return miles(n) + " €"


# ---------- números como en JavaScript ----------
# String(n): los enteros sin decimales; los demás, el decimal más corto que vuelve a dar el mismo double
static func js_num(x) -> String:
	if x is int:
		return str(x)
	var f: float = x
	if is_nan(f):
		return "NaN"
	if f == floorf(f) and absf(f) < 1e21:
		return str(int(f))
	for d in range(1, 21):
		var s := String.num(f, d)
		if s.to_float() == f:
			while s.ends_with("0"):
				s = s.left(-1)
			return s
	return String.num(f, 20)

# toFixed: el printf de Godot redondea las mitades exactas al par; JavaScript, hacia arriba (en valor absoluto)
static func to_fixed(x: float, f: int) -> String:
	var t := absf(x) * pow(2.0, f + 1)
	if t == floorf(t) and t < 1e15 and int(t) % 2 == 1:
		var n := (int(t) * int(pow(5.0, f)) + 1) / 2
		var s := str(n)
		if f > 0:
			while s.length() <= f:
				s = "0" + s
			s = s.left(-f) + "." + s.right(f)
		return ("-" if x < 0 else "") + s
	return ("%." + str(f) + "f") % x

static func coma(x) -> String:
	return js_num(x).replace(".", ",")

static func pct(n: float) -> String:
	return to_fixed(n, 1).replace(".", ",")

# Number.prototype.toString(36) de un entero sin signo
static func b36(n: int) -> String:
	var dig := "0123456789abcdefghijklmnopqrstuvwxyz"
	if n == 0:
		return "0"
	var s := ""
	while n > 0:
		s = dig[n % 36] + s
		n /= 36
	return s

# rngSeed de 00-nucleo (mulberry32): todo en 32 bits sin signo
class Rng:
	var t := 0
	func _init(s: int) -> void:
		t = s & 0xffffffff
	func sig() -> float:
		t = (t + 0x6D2B79F5) & 0xffffffff
		var r := ((t ^ (t >> 15)) * (1 | t)) & 0xffffffff
		r = (r ^ ((r + (((r ^ (r >> 7)) * (61 | r)) & 0xffffffff)) & 0xffffffff)) & 0xffffffff
		return float((r ^ (r >> 14)) & 0xffffffff) / 4294967296.0

static func rng_seed(s: int) -> Rng:
	return Rng.new(s)

static func clamp_js(v: float, a: float, b: float) -> float:
	return maxf(a, minf(b, v))

# randLook de 03-datos: el aspecto de un cliente o un ladrón, siempre el mismo para la misma semilla
static func rand_look(seed: String, kind: String) -> Dictionary:
	var D := carga()
	var R := rng_seed(hash_str(seed))
	var p := func(a: Array): return a[int(floor(R.sig() * a.size()))]
	if kind == "thief":
		var o := {"id": "t" + seed}
		o.skin = p.call(D.SKINS)
		o.hair = p.call(D.HAIRS)
		o.style = "hood"
		o.hat = p.call(["#2a2a30", "#3a2a4a", "#2a3a2a", "#4a2a2a"])
		o.shirt = "#2a2a30"
		o.shirt2 = p.call(["#c02828", "#e0e0e0", "#3a8a3a"])
		o.pants = "#3a3a44"
		return o
	var o := {"id": "n" + seed}
	o.skin = p.call(D.SKINS)
	o.hair = p.call(D.HAIRS)
	o.style = p.call(["short", "short", "long", "curly", "bun", "cap", "bald"])
	o.hat = p.call(D.CLOTH)
	o.shirt = p.call(D.CLOTH)
	o.pants = p.call(["#36466e", "#3a3a44", "#5a4a3a", "#4a6aa8", "#2a2a30"])
	o.beard = 1 if R.sig() < .15 else 0
	o.glasses = 1 if R.sig() < .15 else 0
	return o

static func dex() -> Array:
	return carga().DEX

# crossResult de 03-datos (a: la madre, b: el padre): la receta o un híbrido propio en S.custom, con el m % de la madre
static func cross_result(S: Dictionary, a: String, b: String) -> String:
	var D := carga()
	var ks := [a, b]
	ks.sort()
	var key := "+".join(ks)
	if D.RECIPES.has(key):
		return D.RECIPES[key]
	var id := "x" + b36(hash_str(key))
	if not S.custom.has(id):
		var A = strain(S, a)
		var B = strain(S, b)
		var R := rng_seed(hash_str(key))
		var w := func(s) -> Array: return Array(s.n.split(" ")).filter(func(p): return not p.begins_with("#"))
		var wa: Array = w.call(A)
		var wb: Array = w.call(B)
		var usado := func(n: String) -> bool:
			if n == A.n or n == B.n:
				return true
			for k in D.DEX:
				if D.STRAINS[k].n == n:
					return true
			for k in S.custom:
				if S.custom[k].n == n:
					return true
			return false
		var name: String = wa[0] + " " + wb[-1]
		if wa[0] == wb[-1] or usado.call(name):
			name = wb[0] + " " + wa[-1]
		if usado.call(name):
			name = A.n + " × " + B.n
		if usado.call(name):
			name += " F" + str(2 + int(floor(R.sig() * 7)))
		var C := {"n": name}
		C.thc = minf(33, jsround(((A.thc + B.thc) / 2.0 + R.sig() * 3.5 - 1.5) * 10) / 10.0)
		C.y = jsround((A.y + B.y) / 2.0 + R.sig() * 8 - 4)
		C.d = jsround(((A.d + B.d) / 2.0 + R.sig() * .6 - .3) * 2) / 2.0
		C.r = int(clamp_js(jsround((A.r + B.r) / 2.0 + R.sig() * 10 - 5), 20, 95))
		C.o = A.n + " × " + B.n + " · híbrido propio"
		S.custom[id] = C
		var m := 30 + int(floor(R.sig() * 41))
		C.m = m
		C.ma = a
		C.pa = b
		C.ind = jsround((m * ind_de(S, a) + (100 - m) * ind_de(S, b)) / 100.0)
		C.hj = mix(hoja_de(S, b), hoja_de(S, a), m / 100.0)
		C.c = mix(B.c, A.c, m / 100.0)
	return id

# JSON → los enteros que JavaScript guarda como enteros vuelven a int (Godot los lee como float)
static func enteros(v):
	if v is Dictionary:
		for k in v:
			v[k] = enteros(v[k])
		return v
	if v is Array:
		for i in v.size():
			v[i] = enteros(v[i])
		return v
	if v is float and v == floorf(v) and absf(v) < 9e15:
		return int(v)
	return v
