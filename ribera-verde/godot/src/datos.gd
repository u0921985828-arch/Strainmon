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

static func pct(n: float) -> String:
	return ("%.1f" % n).replace(".", ",")
