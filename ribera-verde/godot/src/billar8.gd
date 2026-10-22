# Ribera Verde (Godot) — el billar a la bola 8 de verdad (lo pidió el usuario: «estilo 8 ball pool»): la mesa vista desde arriba con
# las quince bolas en triángulo y la blanca, física de bolas (choques, bandas, roce y troneras), la línea de tiro con la bola
# fantasma y hacia dónde sale la bola tocada, la fuerza cargando el taco y las reglas de la bola 8: mesa abierta hasta la primera
# que entra bien, lisas (1-7) o rayadas (9-15), falta con bola en mano para el otro (blanca dentro, no tocar nada o tocar primero
# una que no es tuya) y la negra al final: dentro con las tuyas fuera, ganas; antes de tiempo o con falta, pierdes. El rival apunta
# con la misma física (busca la bola y la tronera, prueba los mejores tiros y falla según su habilidad). Todo determinista con un
# paso fijo (DT): la animación y las pruebas dan lo mismo. Las cuentas, en píxeles de la mesa (W × H, el tapete entre bandas).
extends RefCounted

const Cultivo = preload("res://src/cultivo.gd")

const W := 168.0          # el tapete, de banda a banda (2:1, como una mesa de 8 pies)
const H := 84.0
const R := 2.5            # el radio de la bola (5 px)
const DT := 1.0 / 240.0   # el paso de la física
const MU := 80.0          # el roce del paño (px/s²)
const PARA := 3.0         # por debajo, quieta
const E_BOLA := 0.95      # lo que devuelve un choque entre bolas
const E_BANDA := 0.75     # y una banda
const VMIN := 40.0        # la fuerza: de VMIN a VMIN + VSUBE px/s
const SAQUE := 2.4        # el saque, más fuerte que un tiro (taco de abrir y todo el brazo)
const VSUBE := 380.0
const T_RONERA := 5.6     # lo que traga una tronera de esquina (radio desde su centro)
const T_MEDIO := 5.0      # y una del medio
const CARGA_MS := 1100.0  # lo que tarda la fuerza en llegar a tope con A apretado
const RAYA := 0.25        # la cabecera (de la blanca al sacar)
const PIE := 0.72         # el pie (el vértice del triángulo)
const PASOS_MAX := 240 * 14
const CHOQUES := 8         # vueltas de choques por paso

# las troneras: las cuatro esquinas y las dos del medio, un poco fuera del tapete
static func troneras() -> Array:
	return [Vector2(-.5, -.5), Vector2(W / 2, -1.5), Vector2(W + .5, -.5), Vector2(-.5, H + .5), Vector2(W / 2, H + 1.5), Vector2(W + .5, H + .5)]

# a dónde se apunta para meterla en cada una (la boca, no el fondo)
static func bocas() -> Array:
	return [Vector2(1.5, 1.5), Vector2(W / 2, 0), Vector2(W - 1.5, 1.5), Vector2(1.5, H - 1.5), Vector2(W / 2, H), Vector2(W - 1.5, H - 1.5)]

static func lisa(n: int) -> bool:
	return n >= 1 and n <= 7

static func rayada(n: int) -> bool:
	return n >= 9 and n <= 15

static func de_grupo(n: int, g: String) -> bool:
	return lisa(n) if g == "lisas" else rayada(n) if g == "rayadas" else false

# el triángulo: el 1 en el vértice, la negra en el centro y una lisa y una rayada en las esquinas de atrás
const RACK := [[1], [9, 2], [10, 8, 3], [11, 4, 12, 5], [6, 13, 14, 7, 15]]

static func nueva(nb: String) -> Dictionary:
	var b := []
	for i in 16:
		b.append({"n": i, "p": Vector2.ZERO, "v": Vector2.ZERO, "en": true})
	var fx := W * PIE
	var sx := 2 * R * 0.866 + 0.08
	var sy := 2 * R + 0.08
	for i in RACK.size():
		for j in RACK[i].size():
			b[RACK[i][j]].p = Vector2(fx + i * sx, H / 2 + (j - i / 2.0) * sy)
	b[0].p = Vector2(W * RAYA, H / 2)
	return {"b": b, "gr": ["", ""], "turno": 0, "mano": true, "saque": true, "ang": 0.0, "f": 0.0, "fase": "coloca",
		"tiros": 0, "nb": nb, "ultimo": "", "anim": 0.0}

static func en_mesa(V: Dictionary, n: int) -> bool:
	return V.b[n].en

static func quedan(V: Dictionary, g: String) -> int:
	var c := 0
	for d in V.b:
		if d.en and de_grupo(d.n, g):
			c += 1
	return c

static func quieta(V: Dictionary) -> bool:
	for d in V.b:
		if d.en and d.v != Vector2.ZERO:
			return false
	return true

# ---------- la física ----------

static func ev_nuevo() -> Dictionary:
	return {"primer": -1, "met": [], "blanca": false, "toques": 0}

static func dispara(V: Dictionary, ang: float, f: float) -> Dictionary:
	V.b[0].v = Vector2.from_angle(ang) * (VMIN + VSUBE * clampf(f, 0, 1)) * (SAQUE if V.get("saque", false) else 1.0)
	return ev_nuevo()

static func en_tronera(p: Vector2) -> bool:
	var T := troneras()
	for i in T.size():
		if p.distance_to(T[i]) < (T_MEDIO if i == 1 or i == 4 else T_RONERA):
			return true
	return false

static func paso(V: Dictionary, ev: Dictionary) -> void:
	var b: Array = V.b
	for d in b:
		if d.en and d.v != Vector2.ZERO:
			d.p += d.v * DT
	for d in b:
		if not d.en:
			continue
		# la tronera se mira donde el centro cruza la línea de la banda, no donde ha llegado en este paso: así lo que cae no
		# depende de la velocidad (antes, la rápida se metía más en la boca y caía; la lenta rebotaba)
		var t := 0.0
		var sale := 0.0
		for e in [d.p.x - R, W - R - d.p.x, d.p.y - R, H - R - d.p.y]:
			sale = maxf(sale, -e)
		if sale > 0 and d.v != Vector2.ZERO:
			var vx: float = absf(d.v.x)
			var vy: float = absf(d.v.y)
			if d.p.x < R and vx > 0: t = maxf(t, (R - d.p.x) / vx)
			if d.p.x > W - R and vx > 0: t = maxf(t, (d.p.x - W + R) / vx)
			if d.p.y < R and vy > 0: t = maxf(t, (R - d.p.y) / vy)
			if d.p.y > H - R and vy > 0: t = maxf(t, (d.p.y - H + R) / vy)
		if en_tronera(d.p - d.v * t):
			d.en = false
			d.v = Vector2.ZERO
			ev.met.append(d.n)
			if d.n == 0:
				ev.blanca = true
			continue
		if d.p.x < R:
			d.p.x = R
			d.v.x = absf(d.v.x) * E_BANDA
		elif d.p.x > W - R:
			d.p.x = W - R
			d.v.x = -absf(d.v.x) * E_BANDA
		if d.p.y < R:
			d.p.y = R
			d.v.y = absf(d.v.y) * E_BANDA
		elif d.p.y > H - R:
			d.p.y = H - R
			d.v.y = -absf(d.v.y) * E_BANDA
	# los choques, en varias vueltas por paso: en el triángulo apretado un golpe tiene que pasar de bola en bola en el mismo
	# instante (como en la realidad); con una sola vuelta se quedaba a medias y el saque no abría las bolas
	for it in CHOQUES:
		var hubo := false
		for i in 16:
			var a: Dictionary = b[i]
			if not a.en:
				continue
			for j in range(i + 1, 16):
				var c: Dictionary = b[j]
				if not c.en or (a.v == Vector2.ZERO and c.v == Vector2.ZERO):
					continue
				var dd: Vector2 = c.p - a.p
				var l2 := dd.length_squared()
				if l2 >= 4 * R * R or l2 == 0:
					continue
				var l := sqrt(l2)
				var nn := dd / l
				var rel: float = (a.v - c.v).dot(nn)
				if rel > 0:
					var imp := rel * (1 + E_BOLA) / 2
					a.v -= nn * imp
					c.v += nn * imp
					hubo = true
					if it == 0:
						ev.toques += 1
					if ev.primer < 0 and (i == 0 or j == 0):
						ev.primer = j if i == 0 else i
				if it == 0:
					var sobra := (2 * R - l) / 2
					a.p -= nn * sobra
					c.p += nn * sobra
		if not hubo:
			break
	for d in b:
		if d.en and d.v != Vector2.ZERO:
			var s: float = d.v.length()
			var s2 := s - MU * DT
			d.v = d.v * (s2 / s) if s2 > PARA else Vector2.ZERO

# hasta que se paran todas (las pruebas y el rival)
static func simula(V: Dictionary, ev: Dictionary) -> Dictionary:
	var n := 0
	while not quieta(V) and n < PASOS_MAX:
		paso(V, ev)
		n += 1
	for d in V.b:
		d.v = Vector2.ZERO
	return ev

static func copia(V: Dictionary) -> Dictionary:
	var C := V.duplicate()
	C.b = []
	for d in V.b:
		C.b.append(d.duplicate())
	C.gr = V.gr.duplicate()
	return C

# ---------- las reglas ----------

static func objetivos(V: Dictionary, q: int) -> Array:
	var g: String = V.gr[q]
	var o := []
	for d in V.b:
		if d.en and d.n != 0 and d.n != 8 and (g == "" or de_grupo(d.n, g)):
			o.append(d.n)
	if g != "" and o.is_empty():
		o.append(8)
	return o

# lo que pasa tras un tiro de q: {falta, sigue, fin ("" | "gana" | "pierde"), grupo (el que se lleva), motivo}
static func resuelve(V: Dictionary, ev: Dictionary, q: int, ob: Array) -> Dictionary:
	var r := {"falta": false, "sigue": false, "fin": "", "grupo": "", "motivo": ""}
	var saque: bool = V.saque
	if ev.blanca:
		r.falta = true
		r.motivo = "blanca"
	elif ev.primer < 0:
		r.falta = true
		r.motivo = "nada"
	elif not saque and not (ev.primer in ob):
		r.falta = true
		r.motivo = "otra"
	var negra: bool = 8 in ev.met
	if negra and saque:   # la negra al sacar vuelve al pie
		V.b[8].en = true
		V.b[8].p = sitio_libre(V, Vector2(W * PIE, H / 2))
		ev.met.erase(8)
		negra = false
	if negra:
		r.fin = "gana" if (ob == [8] and not r.falta) else "pierde"
		if r.fin == "pierde" and not r.falta:
			r.motivo = "pronto"
		return r
	if V.gr[q] == "" and not saque and not r.falta:
		for n in ev.met:
			if n != 0:
				r.grupo = "lisas" if lisa(n) else "rayadas"
				V.gr[q] = r.grupo
				V.gr[1 - q] = "rayadas" if r.grupo == "lisas" else "lisas"
				break
	if r.falta:
		return r
	for n in ev.met:
		if n != 0 and (saque or V.gr[q] == "" or de_grupo(n, V.gr[q])):
			r.sigue = true
	return r

# al tope de tiros (se hace tarde): gana a quien le quedan menos bolas suyas en la mesa; con la mesa abierta o empatados, tablas
static func al_tope(V: Dictionary) -> String:
	if V.gr[0] == "":
		return ""
	var a := quedan(V, V.gr[0])
	var b := quedan(V, V.gr[1])
	return "yo" if a < b else "el" if b < a else ""

# un sitio libre cerca de p (la negra que vuelve, la blanca en mano)
static func libre(V: Dictionary, p: Vector2, sin := 0) -> bool:
	if p.x < R or p.x > W - R or p.y < R or p.y > H - R or en_tronera(p):
		return false
	for d in V.b:
		if d.en and d.n != sin and d.p.distance_to(p) < 2 * R + .3:
			return false
	return true

static func sitio_libre(V: Dictionary, p: Vector2, sin := -1) -> Vector2:
	if libre(V, p, sin):
		return p
	for k in range(1, 40):
		for a in 12:
			var q := p + Vector2.from_angle(a * PI / 6) * k
			if libre(V, q, sin):
				return q
	return p

# ---------- la línea de tiro ----------

# la primera bola que toca la blanca yendo hacia ang, sin contar bandas: {n, t (lo que anda), g (la fantasma)} o la banda
static func rayo(V: Dictionary, ang: float) -> Dictionary:
	var o: Vector2 = V.b[0].p
	var u := Vector2.from_angle(ang)
	var mejor := 1e9
	var nb := -1
	for d in V.b:
		if not d.en or d.n == 0:
			continue
		var w: Vector2 = d.p - o
		var t := w.dot(u)
		if t <= 0:
			continue
		var e2 := w.length_squared() - t * t
		if e2 >= 4 * R * R:
			continue
		var tt := t - sqrt(4 * R * R - e2)
		if tt < mejor:
			mejor = tt
			nb = d.n
	var tb := 1e9
	if u.x > 1e-6:
		tb = minf(tb, (W - R - o.x) / u.x)
	elif u.x < -1e-6:
		tb = minf(tb, (R - o.x) / u.x)
	if u.y > 1e-6:
		tb = minf(tb, (H - R - o.y) / u.y)
	elif u.y < -1e-6:
		tb = minf(tb, (R - o.y) / u.y)
	if nb >= 0 and mejor <= tb:
		return {"n": nb, "t": mejor, "g": o + u * mejor}
	return {"n": -1, "t": tb, "g": o + u * tb}

# ---------- el rival ----------

static func gauss() -> float:
	var a := maxf(1e-6, Cultivo.azar())
	var b := Cultivo.azar()
	return sqrt(-2 * log(a)) * cos(2 * PI * b)

static func _seg_libre(V: Dictionary, a: Vector2, c: Vector2, sin: Array) -> bool:
	var u := c - a
	var l := u.length()
	if l < 1e-3:
		return true
	u /= l
	for d in V.b:
		if not d.en or d.n in sin:
			continue
		var w: Vector2 = d.p - a
		var t := clampf(w.dot(u), 0, l)
		if (a + u * t).distance_to(d.p) < 2 * R - .2:
			return false
	return true

# los tiros directos a cada tronera: [puntos, ángulo, fuerza, bola]
static func candidatos(V: Dictionary, q: int, desde = null) -> Array:
	var c0: Vector2 = V.b[0].p if desde == null else desde
	var L := []
	for n in objetivos(V, q):
		var bp: Vector2 = V.b[n].p
		for pk in bocas():
			var dir: Vector2 = (pk - bp)
			var d2 := dir.length()
			if d2 < 1:
				continue
			dir /= d2
			var g := bp - dir * 2 * R
			var a := g - c0
			var d1 := a.length()
			if d1 < 1:
				continue
			var cs := a.normalized().dot(dir)
			if cs < .3:
				continue
			if not _seg_libre(V, c0, g, [0, n]) or not _seg_libre(V, bp, pk, [0, n]):
				continue
			# la fuerza que pide el roce: la tocada llega a la tronera y la blanca, a la tocada (con algo de sobra, no más)
			var vc := sqrt(2 * MU * (d2 + 12)) / cs
			var f := clampf((sqrt(vc * vc + 2 * MU * d1) * 1.1 - VMIN) / VSUBE, .12, .85)
			L.append([cs * cs * 100.0 / (1 + (d1 + d2) / 60.0), a.angle(), f, n])
	L.sort_custom(func(x, y): return x[0] > y[0] or (x[0] == y[0] and x[3] < y[3]))
	return L

# lo que vale un tiro para q tras simularlo
static func valor(V: Dictionary, q: int, ang: float, f: float) -> float:
	var C := copia(V)
	var ob := objetivos(C, q)
	var ev := dispara(C, ang, f)
	simula(C, ev)
	var r := resuelve(C, ev, q, ob)
	if r.fin == "gana":
		return 1000.0
	if r.fin == "pierde":
		return -1000.0
	if r.falta:
		return -60.0
	var v := 0.0
	for n in ev.met:
		if n != 0:
			v += 25.0
	if r.sigue:
		v += 20.0 + candidatos(C, q).size() * 2.0
	return v

# el tiro del rival: {ang, f}; hab, de 0 a 1 (la de BILLAR.hab)
static func elige(V: Dictionary, q: int, hab: float) -> Dictionary:
	if V.saque:
		return {"ang": (V.b[1].p - V.b[0].p).angle() + gauss() * .01, "f": .95}
	var L := candidatos(V, q)
	var mejor := {"ang": 0.0, "f": .5, "v": -1e9}
	var s := .012 + (.5 - hab) * .06
	# lo que vale con su pulso: el tiro y los dos de al lado (un corte tan fino o una banda tan justa que con un poco de error
	# ni la toca no le vale)
	var pulso := func(ang: float, f: float) -> float:
		var v: float = valor(V, q, ang, f)
		if v > -60:
			v = (v + valor(V, q, ang + s, f) + valor(V, q, ang - s, f)) / 3.0
		return v
	for i in mini(4, L.size()):
		var v: float = pulso.call(L[i][1], L[i][2])
		if v > mejor.v:
			mejor = {"ang": L[i][1], "f": L[i][2], "v": v}
	if L.is_empty() or mejor.v < 0:   # sin tiro claro: una suya de lleno (al centro), con la fuerza que pide la distancia
		var c0: Vector2 = V.b[0].p
		var bp := []
		for n in objetivos(V, q):
			var bn: Vector2 = V.b[n].p
			var a := (bn - c0).angle()
			var r := rayo(V, a)
			if r.n == n:
				bp.append([float(r.t), a])
		bp.sort_custom(func(x, y): return x[0] < y[0])
		for i in mini(4, bp.size()):
			var f := clampf((sqrt(2 * MU * (float(bp[i][0]) + 40)) - VMIN) / VSUBE, .15, 1)
			var v: float = pulso.call(bp[i][1], f)
			if v > mejor.v:
				mejor = {"ang": bp[i][1], "f": f, "v": v}
		if mejor.v < 0:   # tapado: a banda, los ángulos de una vuelta entera y, de los mejores, el que aguanta su pulso
			var bs := []
			for a in 24:
				bs.append([valor(V, q, a * PI / 12, .6), a * PI / 12])
			bs.sort_custom(func(x, y): return x[0] > y[0])
			for i in 3:
				var v: float = pulso.call(bs[i][1], .6)
				if v > mejor.v:
					mejor = {"ang": bs[i][1], "f": .6, "v": v}
	return {"ang": float(mejor.ang) + gauss() * s, "f": clampf(float(mejor.f) + gauss() * .03, .1, 1)}

# con bola en mano: detrás de la bola más fácil, en línea con su tronera
static func coloca_ia(V: Dictionary, q: int) -> Vector2:
	var mejor := Vector2(W * RAYA, H / 2)
	var mv := -1e9
	for n in objetivos(V, q):
		var bp: Vector2 = V.b[n].p
		for pk in bocas():
			var dir: Vector2 = (pk - bp).normalized()
			for dd in [22.0, 34.0, 14.0]:
				var p: Vector2 = bp - dir * (2 * R + dd)
				if V.saque and p.x > W * RAYA:
					continue
				if not libre(V, p, 0) or not _seg_libre(V, p, bp, [0, n]) or not _seg_libre(V, bp, pk, [0, n]):
					continue
				var v: float = 100.0 - dd - bp.distance_to(pk) / 4.0
				if v > mv:
					mv = v
					mejor = p
				break
	return sitio_libre(V, mejor, 0)

# ---------- el dibujo: [x, y, w, h, color] en la pantalla ----------

const COL := ["#f8f8f0", "#e8c040", "#3a62c8", "#e04040", "#7a4aa8", "#f08a30", "#2e9a5a", "#8a3030", "#26262e"]
const PANO := "#2f7a46"
const PANO_O := "#286a3c"

# la mesa y el taco de PixelLab (lo pidió el usuario: «Hazlo con sprites de PixelLab mejor»): arte/billar.png + billar.json de
# tools/sprites/pixellab_billar.py (la mesa con 11 px de banda alrededor del tapete y el taco en NT ángulos con su punta)
static var ARTE := {}
static var PUNTA := {}
static var NT := 0
static var BANDA := 11

static func carga() -> bool:
	if ARTE.size():
		return true
	var im := Image.new()
	if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://arte/billar.png")) != OK:
		return false
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://arte/billar.json"))
	if typeof(j) != TYPE_DICTIONARY:
		return false
	for k in j.r:
		var q: Array = j.r[k]
		ARTE[k] = im.get_region(Rect2i(int(q[0]), int(q[1]), int(q[2]), int(q[3])))
	PUNTA = j.v
	NT = int(j.nt)
	BANDA = int(j.banda)
	return true

static func origen(sw: int) -> Vector2i:
	return Vector2i((sw - int(W)) >> 1, 14)

static func _bola(o: Array, cx: int, cy: int, n: int) -> void:
	var c: String = COL[n if n <= 8 else n - 8]
	var raya := n >= 9
	var bl: String = COL[0]
	o.append([cx - 1, cy - 2, 3, 1, bl if raya else c])
	o.append([cx - 2, cy - 1, 5, 3, c])
	o.append([cx - 1, cy + 2, 3, 1, bl if raya else c])
	o.append([cx - 1, cy - 1, 1, 1, "#ffffff" if n != 8 else "#6a6a78"])   # el brillo

static func _aro(o: Array, cx: int, cy: int, c: String) -> void:
	for q in [[-1, -2, 3, 1], [-1, 2, 3, 1], [-2, -1, 1, 3], [2, -1, 1, 3]]:
		o.append([cx + q[0], cy + q[1], q[2], q[3], c])

static func _puntos(o: Array, a: Vector2, c: Vector2, ox: int, oy: int, col: String, cada := 2) -> void:
	var l := a.distance_to(c)
	var n := int(l / cada)
	var visto := {}
	for i in range(1, n + 1):
		var p := a.lerp(c, i * cada / l)
		var k := Vector2i(roundi(p.x) + ox, roundi(p.y) + oy)
		if not visto.has(k):
			visto[k] = 1
			o.append([k.x, k.y, 1, 1, col])

static func rects(V: Dictionary, sw: int, sh: int, now: float) -> Array:
	var O := origen(sw)
	var x0 := O.x
	var y0 := O.y
	var o := [[0, 0, sw, sh, "rgba(8,10,14,0.72)"]]
	var clip := Rect2i(0, 0, sw, sh)
	var arte := carga()
	if arte:
		o.append(["@", ARTE.mesa, x0 - BANDA, y0 - BANDA, clip])
	else:
		o.append([x0 - 10, y0 - 10, int(W) + 20, int(H) + 20, "#26262e"])
		o.append([x0 - 9, y0 - 9, int(W) + 18, int(H) + 18, "#74502e"])
		o.append([x0 - 9, y0 - 9, int(W) + 18, 1, "#a46e40"])
		o.append([x0 - 4, y0 - 4, int(W) + 8, int(H) + 8, "#1f5a34"])   # las bandas de goma
		o.append([x0, y0, int(W), int(H), PANO])
		o.append([x0, y0, int(W), 1, PANO_O])
		o.append([x0, y0, 1, int(H), PANO_O])
		for i in range(1, 8):   # los rombos de la madera
			if i != 4:
				o.append([x0 + int(W * i / 8.0), y0 - 7, 1, 1, "#dcac6c"])
				o.append([x0 + int(W * i / 8.0), y0 + int(H) + 6, 1, 1, "#dcac6c"])
		for i in range(1, 4):
			o.append([x0 - 7, y0 + int(H * i / 4.0), 1, 1, "#dcac6c"])
			o.append([x0 + int(W) + 6, y0 + int(H * i / 4.0), 1, 1, "#dcac6c"])
		for t in troneras():
			var cx := x0 + roundi(t.x)
			var cy := y0 + roundi(t.y)
			o.append([cx - 3, cy - 4, 7, 9, "#121519"])
			o.append([cx - 4, cy - 3, 9, 7, "#121519"])
	o.append([x0 + int(W * RAYA), y0 + 1, 1, int(H) - 2, "rgba(255,255,255,0.12)"])   # la cabecera
	o.append([x0 + int(W * PIE), y0 + int(H / 2), 1, 1, "rgba(255,255,255,0.3)"])   # el pie
	var b: Array = V.b
	for d in b:
		if d.en and d.n != 0:
			_bola(o, x0 + roundi(d.p.x), y0 + roundi(d.p.y), d.n)
	var c0: Dictionary = b[0]
	var fase: String = V.fase
	if c0.en:
		_bola(o, x0 + roundi(c0.p.x), y0 + roundi(c0.p.y), 0)
		if fase == "coloca" and int(now / 250) % 2 == 0:
			_aro(o, x0 + roundi(c0.p.x), y0 + roundi(c0.p.y), "#f8f8f0" if V.get("vale", true) else "#e04040")
		if fase == "apunta" or fase == "carga" or fase == "ia":
			var u := Vector2.from_angle(V.ang)
			var r := rayo(V, V.ang)
			_puntos(o, c0.p, r.g, x0, y0, "rgba(255,255,255,0.75)")
			var g: Vector2 = r.g
			_aro(o, x0 + roundi(g.x), y0 + roundi(g.y), "rgba(255,255,255,0.85)")
			if r.n >= 0:
				var dn: Vector2 = (b[r.n].p - g).normalized()
				_puntos(o, b[r.n].p, b[r.n].p + dn * 16, x0, y0, "rgba(255,255,255,0.75)")
				var tg := (u - dn * u.dot(dn))   # hacia dónde se va la blanca
				if tg.length() > .05:
					_puntos(o, g, g + tg.normalized() * 10 * tg.length(), x0, y0, "rgba(200,220,255,0.55)", 3)
			var tira := 3.0 + 12.0 * float(V.f)   # el taco, hacia atrás con la fuerza
			var a: Vector2 = c0.p - u * (R + tira)
			if arte and NT > 0:
				var ti := posmod(roundi(float(V.ang) / TAU * NT), NT)
				var pt: Array = PUNTA["taco-%d" % ti]
				o.append(["@", ARTE["taco-%d" % ti], x0 + roundi(a.x - float(pt[0])), y0 + roundi(a.y - float(pt[1])), clip])
			else:
				_puntos(o, a, a - u * 70, x0, y0, "#c48a52", 1)
				_puntos(o, a, a - u * 4, x0, y0, "#e8e0d0", 1)
	# la fuerza, a la izquierda de la mesa
	var bx := x0 - BANDA - 9
	var bh := int(H) + 8
	if bx >= 2:
		o.append([bx - 1, y0 - 5, 7, bh + 2, "#26262e"])
		o.append([bx, y0 - 4, 5, bh, "#3a3446"])
		var fh := roundi(float(V.f) * bh)
		o.append([bx, y0 - 4 + bh - fh, 5, fh, "#58d080" if V.f < .8 else "#e0b84a" if V.f < .95 else "#e04040"])
	# lo que le queda a cada uno, debajo
	var yb := y0 + int(H) + 16
	for q in 2:
		var g: String = V.gr[q]
		var L := []
		for d in b:
			if d.n != 0 and d.n != 8 and (de_grupo(d.n, g) if g != "" else false):
				L.append(d)
		var xx: int = x0 + 3 if q == 0 else x0 + int(W) - 3 - 7 * 8
		if q == V.turno and int(now / 400) % 2 == 0 and fase != "rueda":
			o.append([xx - 3, yb - 3, 7 * 8 + 1, 7, "rgba(255,255,255,0.18)"])
		for i in L.size():
			if L[i].en:
				_bola(o, xx + 3 + i * 7, yb, L[i].n)
			else:
				_aro(o, xx + 3 + i * 7, yb, "rgba(255,255,255,0.25)")
		if g != "" and quedan(V, g) == 0:
			_bola(o, xx + 3 + 7 * 7, yb, 8)
	return o.filter(func(x): return typeof(x[0]) == TYPE_STRING or (x[0] >= 0 and x[1] >= 0 and x[0] + x[2] <= sw and x[1] + x[3] <= sh))   # nada fuera de la pantalla (los sprites, con su recorte)
