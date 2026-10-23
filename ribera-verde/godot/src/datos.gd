# Ribera Verde (Godot) — los datos del juego HTML (datos/datos.json, lo saca tools/godot.js del index.html compilado) y las
# cuentas de color y de porte de 00-nucleo, 03-datos y 09b-carpa, con el mismo redondeo que JavaScript
extends RefCounted

const I18n = preload("res://src/i18n.gd")

static var D := {}

static func carga() -> Dictionary:
	if D.is_empty():
		D = JSON.parse_string(FileAccess.get_file_as_string("res://datos/datos.json"))
	if _cal_d != CAL or _play_d != PLAY:
		_aplica_auto()
		_aplica_play()
	return D

# ---------- la versión de Google Play (PLAY): datos/play.json (lo escribe tools/play.py) ----------
# Con PLAY, los textos de cultivo sin cifras reales (pH, °C, micras), los híbridos con nombre propio y fuera el bajo de las setas y
# las apuestas del billar. Las pruebas contra el HTML (y las de la versión entera) ponen PLAY = false antes de cargar nada.
# Solo cambia textos y en su sitio (las mismas listas y diccionarios), así que se puede ir y volver.
static var PLAY := true
static var _play_d = null
static var _P := {}
static var _rx_n: RegEx = null
static var _rx_r := []
static var _play0 := {}

static func _aplica_play() -> void:
	_play_d = PLAY
	if _P.is_empty():
		_P = JSON.parse_string(FileAccess.get_file_as_string("res://datos/play.json"))
		var alt := []
		var ks: Array = _P.nombres.keys()
		ks.sort_custom(func(a, b): return a.length() > b.length() or (a.length() == b.length() and a < b))
		for k in ks:
			alt.append(_esc(k))
		var L: String = _P.letra
		_rx_n = RegEx.create_from_string("(?<![%s])(%s)(?![%s\\-])" % [L, "|".join(alt), L])
		for r in _P.rep:
			_rx_r.append([RegEx.create_from_string(r[0]), r[1].replace("\\1", "$1")])
		for k in _P.claves:
			_play0[k] = D[k].duplicate(true)
	for k in _play0:
		_vuelve(D[k], _play0[k])
	if PLAY:
		for k in _play0:
			_cambia(D[k], k)

static func _esc(t: String) -> String:
	var r := ""
	for c in t:
		r += ("\\" + c) if "\\^$.|?*+()[]{}#-".contains(c) else c
	return r

# lo de antes, hoja a hoja (sin cambiar las listas ni los diccionarios)
static func _vuelve(v, o) -> void:
	if v is Dictionary:
		for k in o:
			if not v.has(k):
				continue
			if o[k] is String:
				v[k] = o[k]
			else:
				_vuelve(v[k], o[k])
	elif v is Array:
		for i in mini(v.size(), o.size()):
			if o[i] is String:
				v[i] = o[i]
			else:
				_vuelve(v[i], o[i])

static func _cambia(v, ruta: String) -> void:
	if v is Dictionary:
		for k in v:
			if v[k] is String:
				v[k] = _hoja(v[k], ruta + "." + str(k))
			else:
				_cambia(v[k], ruta + "." + str(k))
	elif v is Array:
		for i in v.size():
			if v[i] is String:
				v[i] = _hoja(v[i], ruta + "." + str(i))
			else:
				_cambia(v[i], ruta + "." + str(i))

static func _hoja(s: String, ruta: String) -> String:
	return _P.set[ruta] if _P.set.has(ruta) else tp(s)

# el texto que se ve (diálogos, menús, avisos): con PLAY, los mismos cambios que en los datos
static var SOLO_NOMBRES := false   # F7: en inglés, solo los nombres (los cambios de rep son frases en castellano)
static func tp(s: String) -> String:
	if not PLAY or _rx_n == null or s == "":
		return s
	if not SOLO_NOMBRES:
		for r in _rx_r:
			s = r[0].sub(s, r[1], true)
	var o := ""
	var i := 0
	for m in _rx_n.search_all(s):
		o += s.substr(i, m.get_start() - i) + str(_P.nombres[m.get_string(1)])
		i = m.get_end()
	return o + s.substr(i)

# Las autoflorecientes (AUTO) entran en la Genoteca, las recetas y el banco solo con CAL (las pruebas contra el HTML, sin ellas)
static var _cal_d = null
static func _aplica_auto() -> void:
	_cal_d = CAL
	if not D.has("_base"):
		D._base = {"DEX": D.DEX.duplicate(), "RECIPES": D.RECIPES.duplicate(), "BANCO": D.BANCO.duplicate()}
	D.DEX = D._base.DEX.duplicate()
	D.RECIPES = D._base.RECIPES.duplicate()
	D.BANCO = D._base.BANCO.duplicate()
	if CAL:
		D.DEX.append_array(D.AUTO.dex)
		D.RECIPES.merge(D.AUTO.recipes)
		D.BANCO.append_array(D.AUTO.banco)
	# MAESTRO [4]: el fungicida, el preventivo y el sellado de la botritis, al final de la tienda (solo con CAL)
	if D.has("BOTRITIS"):
		if not D._base.has("SHOP"):
			D._base.SHOP = D.SHOP.duplicate()
		D.SHOP = D._base.SHOP.duplicate()
		if CAL:   # al final: PLAY restaura los textos de SHOP por posición
			D.SHOP.append_array(D.BOTRITIS.shop)
			D.EXTRAS["sello"] = D.BOTRITIS.extra
		else:
			D.EXTRAS.erase("sello")
	# MAESTRO [9]: Hiriburu, la ciudad de la autopista (solo con CAL: su parada, sus km, su zona, sus patrullas y sus clientes)
	var MT: Dictionary = D.get("METRO", {})
	if not MT.is_empty():
		for t in [[D.PARADAS, MT.parada], [D.CONCE.km, MT.km], [D.ZONAS, MT.zona], [D.PATRULLAS, MT.pat], [D.CLIENT_TILES, MT.ct], [D.RONDA, MT.ronda]]:
			if CAL:
				t[0]["metropoli"] = t[1]
			else:
				t[0].erase("metropoli")
	# Bilbao, zonas nuevas (lo pidió el usuario: «Añade como zonas nuevas / No quiero caos»; tools/bilbao.py): con CAL, Zorroza (la
	# parada «Bilbao»), La Punta, Abando y el Casco Viejo, con lo del suelo (dec), sus farolas, zona, patrullas, clientes y ronda;
	# sin CAL, nada (los mapas de siempre no cambian y el oráculo tampoco)
	var BI: Dictionary = D.get("BILBAO", {})
	if not BI.is_empty():
		for k in BI.MAPS:
			if CAL:
				D.MAPS[k] = BI.MAPS[k]
				D.MAPS[k].dec = BI.DEC.get(k, {})
				for t in [["LAMPS", BI.LAMPS[k]], ["CLIENT_TILES", BI.CLIENT_TILES[k]], ["RONDA", BI.RONDA[k]], ["ZONAS", BI.ZONAS[k]], ["PATRULLAS", BI.PATRULLAS[k]]]:   # i18n-no
					D[t[0]][k] = t[1]
			else:
				D.MAPS.erase(k)
				for t in ["LAMPS", "CLIENT_TILES", "RONDA", "ZONAS", "PATRULLAS"]:   # i18n-no
					D[t].erase(k)
		for k in BI.get("IN", {}):   # los de dentro: el teatro, las iglesias y el mercado (ciudad.gd)
			if CAL:
				D.MAPS[k] = BI.IN[k]
			else:
				D.MAPS.erase(k)
		if CAL:
			D.PARADAS["zorroza"] = BI.PARADA
			D.CONCE.km["zorroza"] = BI.KM
		else:
			D.PARADAS.erase("zorroza")
			D.CONCE.km.erase("zorroza")
	# Los pueblos con su sitio propio (tools/pueblos.py): con CAL, sus clientes y su ronda sin lo que tapan los hitos
	var PU: Dictionary = D.get("PUEBLOS", {})
	if not PU.is_empty():
		if not D._base.has("PCT"):
			D._base.PCT = {}
			for t in ["CLIENT_TILES", "RONDA"]:   # i18n-no
				D._base.PCT[t] = {}
				for k in PU.MAPS:
					D._base.PCT[t][k] = D[t].get(k, [])
		for t in ["CLIENT_TILES", "RONDA"]:   # i18n-no
			for k in PU.MAPS:
				D[t][k] = PU[t][k] if CAL else D._base.PCT[t][k]
	# El club KAIA del muelle, el tuyo (solo con CAL: las pruebas contra el HTML recorren D.CLUBS)
	var K: Dictionary = D.get("KAIA", {})
	if K.is_empty():
		return
	var tablas := [[D.CLUBS, K.CLUBS], [D.MUEBLE_CLUB, K.MUEBLE_CLUB], [D.LUZ_CLUB, K.LUZ_CLUB], [D.GENERO.enc, K.enc], [D.SOCIO.n, K.SOCIO], [D.BILLAR.n, K.BILLAR_N], [D.BILLAR.hab, K.BILLAR_HAB]]
	for t in tablas:
		if CAL:
			t[0]["muelle"] = t[1]
		else:
			t[0].erase("muelle")

# Math.round de JavaScript: la mitad, hacia arriba (round() de Godot la aleja del cero)
# ---------- el calendario (1.42, lo pidió el usuario: la partida empieza el lunes 20 de abril de 2026 y cada día suma uno) ----------
# El día 1 de la partida (S.day) es CAL0; los meses, con sus días (y los bisiestos), y la semana de lunes a domingo. Las pruebas que
# comparan con el HTML congelado (historia, C1, pantallas) ponen CAL = false: «día N» y un mes por día, como antes.
static var CAL := true
const CAL0 := [2026, 4, 20]
const DIA_SEM := ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]   # i18n-no: se traducen al enseñarlos (I18n.v)
const MES_N := ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]

static func bisiesto(y: int) -> bool:
	return (y % 4 == 0 and y % 100 != 0) or y % 400 == 0

static func dias_mes(y: int, m: int) -> int:
	return [31, 29 if bisiesto(y) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]

# los días desde el 1-1-1970 (proléptico gregoriano) y al revés: así no hay que contar mes a mes
static func dias_civil(y: int, m: int, d: int) -> int:
	var yy := y - (1 if m <= 2 else 0)
	var era := (yy if yy >= 0 else yy - 399) / 400
	var yoe := yy - era * 400
	var doy := (153 * (m + (-3 if m > 2 else 9)) + 2) / 5 + d - 1
	var doe := yoe * 365 + yoe / 4 - yoe / 100 + doy
	return era * 146097 + doe - 719468

static func civil(z0: int) -> Array:
	var z := z0 + 719468
	var era := (z if z >= 0 else z - 146096) / 146097
	var doe := z - era * 146097
	var yoe := (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
	var doy := doe - (365 * yoe + yoe / 4 - yoe / 100)
	var mp := (5 * doy + 2) / 153
	var d := doy - (153 * mp + 2) / 5 + 1
	var m := mp + (3 if mp < 10 else -9)
	return [yoe + era * 400 + (1 if m <= 2 else 0), m, d]

# el día de partida dia → {y, m (1-12), d, s (0 lunes … 6 domingo)}
static func fecha(dia: int) -> Dictionary:
	var z := dias_civil(CAL0[0], CAL0[1], CAL0[2]) + dia - 1
	var c := civil(z)
	return {"y": c[0], "m": c[1], "d": c[2], "s": posmod(z + 3, 7)}   # el 1-1-1970 fue jueves

# el día de partida de una fecha
static func dia_de(y: int, m: int, d: int) -> int:
	return dias_civil(y, m, d) - dias_civil(CAL0[0], CAL0[1], CAL0[2]) + 1

# «día 12» (CAL = false) o «12 de mayo» (con el año si no es el de hoy, hoy)
static func fd(dia: int, hoy := -1) -> String:
	if not CAL:
		return I18n.T("día {n}", {"n": js_num(dia)})
	var f := fecha(dia)
	if hoy >= 0 and int(fecha(hoy).y) != int(f.y):
		return I18n.T("{d} de {m} de {y}", {"d": f.d, "m": MES_N[f.m - 1], "y": f.y})
	return I18n.T("{d} de {m}", {"d": f.d, "m": MES_N[f.m - 1]})

# corto, para las columnas de los menús: «día 12» o «12 may»
static func fd_corto(dia: int) -> String:
	if not CAL:
		return I18n.T("día {n}", {"n": js_num(dia)})
	var f := fecha(dia)
	return "%d %s" % [f.d, I18n.v(MES_N[f.m - 1]).substr(0, 3)]

# el de arriba (HUD, START y móvil): «DÍA 12» o «LUN 20 ABR»
static func fd_hud(dia: int) -> String:
	if not CAL:
		return I18n.T("DÍA {n}", {"n": js_num(dia)})
	var f := fecha(dia)
	return "%s %d %s" % [I18n.v(DIA_SEM[f.s]).substr(0, 3).to_upper(), f.d, I18n.v(MES_N[f.m - 1]).substr(0, 3).to_upper()]

# entera: «lunes, 20 de abril de 2026»
static func fd_larga(dia: int) -> String:
	if not CAL:
		return I18n.T("día {n}", {"n": js_num(dia)})
	var f := fecha(dia)
	return I18n.T("{s}, {d} de {m} de {y}", {"s": DIA_SEM[f.s], "d": f.d, "m": MES_N[f.m - 1], "y": f.y})

# ---------- el tiempo de fuera (1.52): por mes del calendario, uno por día ----------
static func estacion(dia: int) -> String:
	var f := fecha(dia)
	var E: Array = carga().TIEMPO.est
	var e: String = E[E.size() - 1][2]
	for x in E:
		if int(f.m) > int(x[0]) or (int(f.m) == int(x[0]) and int(f.d) >= int(x[1])):
			e = x[2]
	return e

# {k: sol/nubes/lluvia/niebla/tormenta/nieve, n, max, min, t (a esa hora), est}
static func tiempo(dia: int, minuto: int) -> Dictionary:
	var T: Dictionary = carga().TIEMPO
	var m: int = int(fecha(dia).m) - 1
	var h := hash_str("tiempo%d" % dia)
	var r := h % 100
	var k: String = T.k[0]
	for i in T.k.size():
		r -= int(T.p[m][i])
		if r < 0:
			k = T.k[i]
			break
	var v: int = int((h >> 8) % (2 * int(T.var) + 1)) - int(T.var)
	var mx: int = int(T.t[m][0]) + v + int(T.dt[k])
	var mn: int = mini(int(T.t[m][1]) + v + mini(0, int(T.dt[k])), mx - 3)
	# la mínima a las 6 y la máxima a las 15
	var hh := float(minuto) / 60.0
	var u := (hh - 6.0) / 9.0 if hh >= 6.0 and hh <= 15.0 else (1.0 - (fposmod(hh - 15.0, 24.0)) / 15.0)
	var t := mn + (mx - mn) * (0.5 - 0.5 * cos(PI * clampf(u, 0.0, 1.0)))
	if k == "nieve":
		mx = mini(mx, 3)
		mn = mini(mn, 0)
		t = minf(t, 2.0)
	return {"k": k, "n": T.n[k], "max": mx, "min": mn, "t": jsround(t), "est": estacion(dia)}

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
# el color de los cogollos de una planta: el de su variedad o, si es rara (MAESTRO [5], f.sh), el suyo
static func color_cog(S: Dictionary, p: Dictionary) -> String:
	var f = p.get("f")
	if CAL and f is Dictionary and f.get("sh"):
		return String(carga().SHINY.c[f.sh])
	return String(strain(S, p.sid).c)

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
		return "NaN"   # i18n-no
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
	carga()
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
# recetas por hojas (1.11, recetaDe): las variedades con nombre de las que sale un híbrido propio (S.custom[id].hojas)
static func hojas_de(S: Dictionary, id: String) -> Array:
	if S and S.has("custom") and S.custom.has(id) and S.custom[id].get("hojas") is Array:
		return S.custom[id].hojas
	return [id]

static func hojas_cruce(S: Dictionary, a: String, b: String) -> Array:
	var h := []
	for x in hojas_de(S, a) + hojas_de(S, b):
		if not h.has(x):
			h.append(x)
	h.sort()
	return h

static func receta_de(S: Dictionary, a: String, b: String):
	carga()
	if D.RECETA_ORD.has(a + ">" + b):
		return D.RECETA_ORD[a + ">" + b]
	if a == b:
		return null
	return D.RECIPES.get("+".join(hojas_cruce(S, a, b)))

# nombre corto de un cruce (1.11, nombreCruce de 03-datos): dos palabras de los padres, hasta NOM_MAX letras, sin repetir; si no, « #2»…
const NOM_MAX := 20

static func palabras(n: String) -> Array:
	var re := RegEx.create_from_string("^F\\d+$")
	return Array(n.split(" ")).filter(func(p): return p != "" and p != "×" and not p.begins_with("#") and re.search(p) == null)

static func nombre_cruce(wa: Array, wb: Array, usado: Callable) -> String:
	var c := []
	var r := []
	if wa.size() and wb.size():
		for n in [wa[0] + " " + wb[-1], wb[0] + " " + wa[-1]]:
			if not c.has(n):
				c.append(n)
	for x in wa:
		for y in wb:
			if x != y:
				r.append(x + " " + y)
				r.append(y + " " + x)
	var ri := []
	for i in r.size():
		ri.append([r[i], i])
	ri.sort_custom(func(p, q): return p[0].length() < q[0].length() or (p[0].length() == q[0].length() and p[1] < q[1]))
	for e in ri:
		if not c.has(e[0]):
			c.append(e[0])
	var ok := []
	for n in c:
		var w: PackedStringArray = n.split(" ")
		if w[0] != w[1] and n.length() <= NOM_MAX:
			ok.append(n)
	for n in ok:
		if not usado.call(n):
			return n
	var base := ""
	for n in ok:
		if n.length() <= NOM_MAX - 4:
			base = n
			break
	if base == "":
		base = (wa[0] if wa.size() else (wb[0] if wb.size() else I18n.K("Cruce"))).substr(0, NOM_MAX - 4)
	var k := 2
	while true:
		var nm := base.substr(0, NOM_MAX - 2 - str(k).length()).rstrip(" ") + " #" + str(k)
		if not usado.call(nm):
			return nm
		k += 1
	return ""

static func cross_result(S: Dictionary, a: String, b: String) -> String:
	carga()
	var rc = receta_de(S, a, b)
	if rc:
		return rc
	var ks := [a, b]
	ks.sort()
	var key := "+".join(ks)
	var id := "x" + b36(hash_str(key))
	if not S.custom.has(id):
		var A = strain(S, a)
		var B = strain(S, b)
		var R := rng_seed(hash_str(key))
		var usado := func(n: String) -> bool:
			var l := n.to_lower()
			if l == A.n.to_lower() or l == B.n.to_lower():
				return true
			for k in D.DEX:
				if D.STRAINS[k].n.to_lower() == l:
					return true
			for k in S.custom:
				if S.custom[k].n.to_lower() == l:
					return true
			return false
		var C := {"n": nombre_cruce(palabras(A.n), palabras(B.n), usado)}
		C.thc = minf(33, jsround(((A.thc + B.thc) / 2.0 + R.sig() * 3.5 - 1.5) * 10) / 10.0)
		C.y = jsround((A.y + B.y) / 2.0 + R.sig() * 8 - 4)
		C.d = jsround(((A.d + B.d) / 2.0 + R.sig() * .6 - .3) * 2) / 2.0
		C.r = int(clamp_js(jsround((A.r + B.r) / 2.0 + R.sig() * 10 - 5), 20, 95))
		C.o = I18n.T("{a} × {b} · híbrido propio", {"a": A.n, "b": B.n})
		if CAL and A.get("auto") and B.get("auto"):   # 1.52: la auto es recesiva; solo sale auto de dos autos
			C.auto = 1
		S.custom[id] = C
		var m := 30 + int(floor(R.sig() * 41))
		C.m = m
		C.ma = a
		C.pa = b
		C.hojas = hojas_cruce(S, a, b)
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
