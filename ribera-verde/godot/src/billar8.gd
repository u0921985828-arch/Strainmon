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
const EFECTO := 0.55       # lo que vuelve (retroceso) o sigue (seguir) la blanca, de lo que llevaba, en un golpe lleno

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
		b.append({"n": i, "p": Vector2.ZERO, "v": Vector2.ZERO, "en": true, "rod": 0.0, "dir": 0.0})
	var fx := W * PIE
	var sx := 2 * R * 0.866 + 0.08
	var sy := 2 * R + 0.08
	for i in RACK.size():
		for j in RACK[i].size():
			b[RACK[i][j]].p = Vector2(fx + i * sx, H / 2 + (j - i / 2.0) * sy)
	b[0].p = Vector2(W * RAYA, H / 2)
	return {"b": b, "gr": ["", ""], "turno": 0, "mano": true, "saque": true, "ang": 0.0, "f": 0.0, "fase": "coloca",
		"tiros": 0, "nb": nb, "ultimo": "", "anim": 0.0, "np": 0, "caen": []}

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

# efe: el efecto de la blanca, de −1 (retroceso: le das abajo y vuelve) a 1 (seguir: arriba y sigue tras la bola); 0, al centro
static func dispara(V: Dictionary, ang: float, f: float, efe := 0.0) -> Dictionary:
	V.b[0].v = Vector2.from_angle(ang) * (VMIN + VSUBE * clampf(f, 0, 1)) * (SAQUE if V.get("saque", false) else 1.0)
	V.b[0].efe = clampf(efe, -1, 1)
	V.b[0].efd = Vector2.from_angle(ang)
	return ev_nuevo()

static func en_tronera(p: Vector2) -> bool:
	var T := troneras()
	for i in T.size():
		if p.distance_to(T[i]) < (T_MEDIO if i == 1 or i == 4 else T_RONERA):
			return true
	return false

static func paso(V: Dictionary, ev: Dictionary) -> void:
	var b: Array = V.b
	V.np = int(V.get("np", 0)) + 1
	for d in b:
		if d.en and d.v != Vector2.ZERO:
			d.p += d.v * DT
			d.rod = float(d.get("rod", 0.0)) + d.v.length() * DT   # lo rodado (el dibujo gira con él)
			d.dir = d.v.angle()
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
			if V.has("caen"):   # para dibujarla cayendo en su tronera
				V.caen.append({"n": d.n, "p": d.p, "np": V.np})
			d.en = false
			d.v = Vector2.ZERO
			ev.met.append(d.n)
			if d.n == 0:
				ev.blanca = true
			continue
		if d.n == 0 and float(d.get("efe", 0.0)) != 0.0 and (d.p.x < R or d.p.x > W - R or d.p.y < R or d.p.y > H - R):
			d.efe = 0.0   # en la banda antes que en una bola, el efecto se va
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
				# el instante del choque: se vuelve atrás lo que se han metido una en otra en este paso (tb), se choca con la normal
				# del punto de contacto de verdad y se sigue; si no, el corte depende de cuánto se solapan en el paso (hasta 4°)
				var vr: Vector2 = a.v - c.v
				var tb := 0.0
				var bq := dd.dot(vr)
				var v2 := vr.length_squared()
				if it == 0 and bq > 0 and v2 > 1e-9:
					var disc := bq * bq - v2 * (l2 - 4 * R * R)
					tb = clampf((-bq + sqrt(maxf(disc, 0))) / v2, 0, DT)
					a.p -= a.v * tb
					c.p -= c.v * tb
					dd = c.p - a.p
					l2 = dd.length_squared()
				var l := sqrt(l2)
				var nn := dd / l
				var rel: float = (a.v - c.v).dot(nn)
				if rel > 0:
					var imp := rel * (1 + E_BOLA) / 2
					var s0: float = a.v.length()
					a.v -= nn * imp
					c.v += nn * imp
					if i == 0 and float(a.get("efe", 0.0)) != 0.0:   # el efecto, en el primer choque de la blanca: cuanto más llena, más
						a.v += a.efd * s0 * EFECTO * float(a.efe) * maxf(0.0, nn.dot(a.efd))
						a.efe = 0.0
					hubo = true
					if tb > 0:
						a.p += a.v * tb
						c.p += c.v * tb
						l = 2 * R
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
			if d.v == Vector2.ZERO and d.n == 0:
				d.efe = 0.0

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
	C.caen = []
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
# Juega como una persona que sabe jugar (lo pidió el usuario: «Tiene que ser un jugador realista de billar»): mira cada bola suya
# con cada tronera y calcula lo fácil que es (el corte, lo que anda la blanca, lo que anda la tocada y lo ancha que le queda la
# boca desde donde está), apunta al centro de lo que entra, prueba la fuerza que deja la blanca para la siguiente y no lo que deja
# al otro si falla; si no hay nada que meter con cabeza, juega a defender (toca una suya flojito y esconde la blanca), y si está
# tapado sale por banda. Falla como falla una persona: el mismo pulso pesa más de lejos y en los cortes finos.

static func gauss() -> float:
	var a := maxf(1e-6, Cultivo.azar())
	var b := Cultivo.azar()
	return sqrt(-2 * log(a)) * cos(2 * PI * b)

# la función de error (Abramowitz y Stegun 7.1.26): lo que da P de que entre con un error normal
static func erf(x: float) -> float:
	var s := signf(x)
	x = absf(x)
	var t := 1.0 / (1.0 + .3275911 * x)
	var y := 1.0 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - .284496736) * t + .254829592) * t * exp(-x * x)
	return s * y

# el pulso: lo que se le va el taco (radianes) y la fuerza (de 0 a 1) según la habilidad (BILLAR.hab, de 0 a 1)
static func pulso_ang(hab: float) -> float:
	return clampf(.012 + (.5 - hab) * .06, .002, .04)

static func pulso_f(hab: float) -> float:
	return clampf(.035 + (.5 - hab) * .1, .01, .08)

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

# dónde cruza la banda el centro de una bola que sale de p hacia u (la misma cuenta que paso() para ver si cae)
static func _cruce(p: Vector2, u: Vector2) -> Vector2:
	var t := 1e9
	if u.x > 1e-6: t = minf(t, (W - R - p.x) / u.x)
	elif u.x < -1e-6: t = minf(t, (R - p.x) / u.x)
	if u.y > 1e-6: t = minf(t, (H - R - p.y) / u.y)
	elif u.y < -1e-6: t = minf(t, (R - p.y) / u.y)
	return p + u * t

# lo que entra en la tronera pk desde bp: [ángulo del centro de la boca, media boca en radianes] o [] si no entra
static func boca_desde(bp: Vector2, pk: int) -> Array:
	var B: Vector2 = bocas()[pk]
	var a0 := (B - bp).angle()
	var T: Vector2 = troneras()[pk]
	var tr := T_MEDIO if pk == 1 or pk == 4 else T_RONERA
	var entra := func(a: float) -> bool:
		return _cruce(bp, Vector2.from_angle(a)).distance_to(T) < tr
	if not entra.call(a0):
		return []
	var lados := []
	for sg in [-1.0, 1.0]:
		var lo := 0.0
		var hi := .6
		for it in 10:
			var m := (lo + hi) / 2
			if entra.call(a0 + sg * m):
				lo = m
			else:
				hi = m
		lados.append(lo)
	var c: float = a0 + (lados[1] - lados[0]) / 2
	return [c, (lados[0] + lados[1]) / 2]

# los tiros directos: {n, pk, ang, f (la justa para que llegue), p (probabilidad con su pulso), cs (coseno del corte), d1, d2}
static func tiros(V: Dictionary, q: int, hab: float, desde = null) -> Array:
	var c0: Vector2 = V.b[0].p if desde == null else desde
	var sa := pulso_ang(hab)
	var L := []
	for n in objetivos(V, q):
		var bp: Vector2 = V.b[n].p
		for pk in 6:
			var bo := boca_desde(bp, pk)
			if bo.is_empty():
				continue
			var dir := Vector2.from_angle(bo[0])
			var pkp: Vector2 = _cruce(bp, dir)
			var d2 := bp.distance_to(pkp)
			var g := bp - dir * 2 * R
			var a := g - c0
			var d1 := a.length()
			if d1 < .5:
				continue
			var cs := a.normalized().dot(dir)
			if cs < .2:
				continue
			if not _seg_libre(V, c0, g, [0, n]) or not _seg_libre(V, bp, pkp, [0, n]):
				continue
			# lo que se va la tocada con el error del taco: el punto de contacto se corre d1·δ y la bola sale con ese giro / (2R·cos)
			var sig := d1 * sa / (2 * R * cs) + .004
			var p := erf(float(bo[1]) / (sig * sqrt(2.0)))
			var vob := sqrt(2 * MU * (d2 + 10)) / (.975 * cs)
			var f := (sqrt(vob * vob + 2 * MU * d1) - VMIN) / VSUBE
			if f > 1:
				continue
			L.append({"n": n, "pk": pk, "ang": a.angle(), "f": clampf(f, .06, 1), "p": p, "cs": cs, "d1": d1, "d2": d2, "boca": bo[0]})
	L.sort_custom(func(x, y): return x.p > y.p or (x.p == y.p and x.n < y.n))
	return L

# hacia dónde sale la bola n si la blanca sale con ang y f (solo hasta el choque; NAN si toca otra o ninguna)
static func _sale(V: Dictionary, n: int, ang: float, f: float) -> float:
	var C := copia(V)
	var ev := dispara(C, ang, f)
	for k in 240 * 3:
		paso(C, ev)
		if ev.primer >= 0 or quieta(C):
			break
	return C.b[n].v.angle() if ev.primer == n and C.b[n].v != Vector2.ZERO else NAN

# la puntería de quien sabe jugar: corrige el ángulo de la bola fantasma hasta que la tocada sale hacia la boca (con la física de
# la mesa, que choca por pasos y no en el punto exacto), por la secante
static func afina(V: Dictionary, n: int, quiere: float, ang: float, f: float) -> float:
	var a0 := ang
	var e0 := angle_difference(quiere, _sale(V, n, a0, f))
	if is_nan(e0) or absf(e0) < .002:
		return a0
	var a1 := a0 + (.004 if e0 > 0 else -.004)
	for it in 4:
		var e1 := angle_difference(quiere, _sale(V, n, a1, f))
		if is_nan(e1):
			return a0
		if absf(e1) < .002 or absf(e1 - e0) < 1e-6:
			return a1
		var a2 := a1 - e1 * (a1 - a0) / (e1 - e0)
		a0 = a1
		e0 = e1
		a1 = clampf(a2, ang - .08, ang + .08)
	return a1

# lo mejor que tiene q desde la mesa C (con la blanca dentro): la probabilidad del tiro más fácil
static func mejor_p(C: Dictionary, q: int, hab: float) -> float:
	if not C.b[0].en:
		return .85   # bola en mano: casi siempre se mete
	var L := tiros(C, q, hab)
	return L[0].p if L.size() else 0.0

# simula el tiro en una copia: {r (resuelve), C (la mesa después), ev}
static func prueba(V: Dictionary, q: int, ang: float, f: float) -> Dictionary:
	var C := copia(V)
	var ob := objetivos(C, q)
	var ev := dispara(C, ang, f)
	simula(C, ev)
	var r := resuelve(C, ev, q, ob)
	return {"r": r, "C": C, "ev": ev}

# lo que vale una mesa tras el tiro de q: lo que le queda a él y lo que le deja al otro
static func deja(Pr: Dictionary, q: int, hab: float, pos: float, cuida: float) -> float:
	var r: Dictionary = Pr.r
	if r.fin == "gana":
		return 100.0
	if r.fin == "pierde":
		return -100.0
	if r.falta:
		return -1.5 - cuida
	var C: Dictionary = Pr.C
	if r.sigue:
		return 1.0 + pos * mejor_p(C, q, hab)
	return -cuida * mejor_p(C, 1 - q, hab)

# el tiro del rival: {ang, f, tipo ("saque" | "ataque" | "defensa" | "banda"), n, pk, prob}; hab, de 0 a 1 (la de BILLAR.hab)
# lim: la hora (Time.get_ticks_msec) a la que deja de mirar más tiros y se queda con el mejor visto; 0, sin límite (las pruebas)
static func elige(V: Dictionary, q: int, hab: float, lim := 0) -> Dictionary:
	var sa := pulso_ang(hab)
	var sf := pulso_f(hab)
	if V.saque:   # a romper: de lleno a la de delante, con todo
		return {"ang": (V.b[1].p - V.b[0].p).angle() + gauss() * sa * .5, "f": clampf(.9 + hab * .2 + gauss() * sf * .5, .7, 1), "tipo": "saque", "n": 1}
	var pos := clampf((hab - .2) * 3, .15, 1)     # cuánto piensa en la siguiente
	var cuida := clampf((hab - .2) * 2.5, .1, .9)  # cuánto mira lo que deja al otro
	var mejor := {"v": -1e9}
	# atacar: las más fáciles, cada una con tres fuerzas (la justa, con algo más y fuerte), por lo que deja
	var L := tiros(V, q, hab)
	for i in mini(4, L.size()):
		var c: Dictionary = L[i]
		for k in [0.0, .15, .35]:
			if lim > 0 and mejor.has("ang") and Time.get_ticks_msec() > lim:
				break
			var f := clampf(float(c.f) + k, .06, 1)
			var ang := afina(V, int(c.n), float(c.boca), float(c.ang), f)
			var Pr := prueba(V, q, ang, f)
			if not Pr.r.sigue and Pr.r.fin != "gana":
				continue   # sin errores, no entra: la geometría engaña (otra bola, la blanca que cae)
			var v: float = float(c.p) * deja(Pr, q, hab, pos, cuida) + (1 - float(c.p)) * (-cuida * mejor_p(Pr.C, 1 - q, hab) * .8)
			if c.n == 8 and Pr.r.fin == "gana":
				v = float(c.p) * 100.0 - (1 - float(c.p)) * 2
			if v > mejor.v:
				mejor = {"v": v, "ang": ang, "f": f, "tipo": "ataque", "n": c.n, "pk": c.pk, "prob": c.p}
	# defender: si no hay un tiro claro (cuanto más sabe, antes lo ve), tocar una suya flojo y dejar la blanca escondida
	var pm: float = float(mejor.get("prob", 0.0))
	if not mejor.has("ang") or (pm < .1 + hab * .5 and hab > .25 and Cultivo.azar() < hab * 1.6):
		var c0: Vector2 = V.b[0].p
		var obs := []
		for n in objetivos(V, q):
			var r := rayo(V, (V.b[n].p - c0).angle())
			if r.n == n:
				obs.append([c0.distance_to(V.b[n].p), n])
		obs.sort()
		for o in obs.slice(0, 3):
			var n: int = o[1]
			var a0: float = (V.b[n].p - c0).angle()
			var dd: float = o[0]
			for off in [0.0, -.5, .5, -.85, .85]:   # de lleno, medio y fino a cada lado
				var a: float = a0 + asin(clampf(off * 2 * R / maxf(dd, 2 * R), -1, 1))
				var fl := clampf((sqrt(2 * MU * (dd + 12)) - VMIN) / VSUBE, .05, .8)   # lo justo para llegar y un poco
				for f in [fl, fl + .08, fl + .18]:
					if lim > 0 and mejor.has("ang") and Time.get_ticks_msec() > lim:
						break
					var Pr := prueba(V, q, a, f)
					if Pr.r.falta:
						continue
					var v: float = deja(Pr, q, hab, pos, 1.0) + (.25 if mejor_p(Pr.C, 1 - q, hab) == 0 else 0.0)
					if v > mejor.v:
						mejor = {"v": v, "ang": a, "f": f, "tipo": "defensa", "n": n}
	# tapado (o nada mejor): por banda, con el ángulo que da la banda de verdad (devuelve E_BANDA de lo que entra)
	if mejor.v <= -1.0 or not mejor.has("ang"):
		for k in bandas(V, q):
			if lim > 0 and mejor.has("ang") and mejor.v > -3.0 and Time.get_ticks_msec() > lim:
				break
			var Pr := prueba(V, q, float(k.ang), float(k.f))
			var v: float = deja(Pr, q, hab, pos, cuida) - .1
			if Pr.r.falta and Pr.r.motivo != "blanca":
				v = -3.0
			if v > mejor.v:
				mejor = {"v": v, "ang": k.ang, "f": k.f, "tipo": "banda", "n": k.n}
	if not mejor.has("ang"):   # ni eso: a la más cercana de lleno, a ver
		var obs := objetivos(V, q)
		var n0: int = obs[0]
		for n in obs:
			if V.b[n].p.distance_to(V.b[0].p) < V.b[n0].p.distance_to(V.b[0].p):
				n0 = n
		mejor = {"ang": (V.b[n0].p - V.b[0].p).angle(), "f": .4, "tipo": "ataque", "n": n0}
	var o := mejor.duplicate()
	o.erase("v")
	o.ang = float(mejor.ang) + gauss() * sa
	o.f = clampf(float(mejor.f) * (1 + gauss() * sf), .04, 1)
	return o

# las bandas: a cada bola suya por cada banda, apuntando al sitio de la banda del que sale hacia ella (la banda devuelve E_BANDA de
# lo que entra de frente, así que no es el espejo: x = (e·dy0·x1 + dy1·x0) / (e·dy0 + dy1)). [{ang, f, n}]
static func bandas(V: Dictionary, q: int) -> Array:
	var c0: Vector2 = V.b[0].p
	var L := []
	for n in objetivos(V, q):
		var b: Vector2 = V.b[n].p
		for lado in 4:
			var hz := lado < 2               # arriba y abajo: banda horizontal
			var lim: float = (R if lado % 2 == 0 else (H - R if hz else W - R))
			var d0: float = absf((c0.y if hz else c0.x) - lim)
			var d1: float = absf((b.y if hz else b.x) - lim)
			if d0 < .5 or d1 < .5:
				continue
			var t := (E_BANDA * d0 * (b.x if hz else b.y) + d1 * (c0.x if hz else c0.y)) / (E_BANDA * d0 + d1)
			var pb := Vector2(t, lim) if hz else Vector2(lim, t)
			if en_tronera(pb) or not _seg_libre(V, c0, pb, [0]) or not _seg_libre(V, pb, b, [0, n]):
				continue
			var l := c0.distance_to(pb) + pb.distance_to(b) / E_BANDA
			L.append({"ang": (pb - c0).angle(), "f": clampf((sqrt(2 * MU * (l + 40)) - VMIN) / VSUBE, .2, .9), "n": n, "l": l})
	L.sort_custom(func(x, y): return x.l < y.l)
	return L.slice(0, 6)

# con bola en mano: donde le queda el tiro más fácil y, para la siguiente, un poco de ángulo (de lleno, la blanca se para)
static func coloca_ia(V: Dictionary, q: int, hab := .5) -> Vector2:
	if V.saque:   # a romper: en la raya de cabecera, un poco a un lado
		return sitio_libre(V, Vector2(W * RAYA, H / 2 + 6), 0)
	var mejor := Vector2(W * RAYA, H / 2)
	var mv := -1e9
	var C := copia(V)
	for n in objetivos(V, q):
		var bp: Vector2 = V.b[n].p
		for pk in 6:
			var bo := boca_desde(bp, pk)
			if bo.is_empty():
				continue
			var dir := Vector2.from_angle(bo[0])
			for dd in [12.0, 20.0, 30.0]:
				for gi in [-.35, 0.0, .35]:
					var p: Vector2 = bp - dir.rotated(gi) * (2 * R + dd)
					if not libre(V, p, 0):
						continue
					C.b[0].p = p
					var L := tiros(C, q, hab, p)
					if L.is_empty():
						continue
					var v: float = float(L[0].p) - dd / 400.0 + (.05 if L.size() > 1 else 0.0) + (.03 if gi != 0.0 else 0.0)
					if v > mv:
						mv = v
						mejor = p
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

# las bolas, a mano (tools/sprites/a-mano/bolas.py; lo pidió el usuario: «Las bolas también tienen que tener sprites, cuando se
# mueven y demás»): una fila por bola, 8 direcciones × 8 fases del rodar y 3 de la caída en la tronera; celdas de 5 × 5
static var BOLAS: Image = null
static var BOLAS_J := {}
const CAE_MS := 240.0

static func carga_bolas() -> bool:
	if BOLAS != null:
		return true
	var im := Image.new()
	if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://arte/billar_bolas.png")) != OK:
		return false
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://arte/billar_bolas.json"))
	if typeof(j) != TYPE_DICTIONARY:
		return false
	BOLAS_J = j
	BOLAS = im
	return true

# la celda de una bola: la dirección en la que rueda y la fase (una vuelta entera cada 2πR de camino)
static func celda_bola(d: Dictionary) -> Rect2i:
	var c := int(BOLAS_J.c)
	var nd := int(BOLAS_J.dirs)
	var nf := int(BOLAS_J.fases)
	var di := posmod(roundi(float(d.get("dir", 0.0)) / (TAU / nd)), nd)
	var fi := posmod(int(float(d.get("rod", 0.0)) / (TAU * R) * nf), nf)
	return Rect2i((di * nf + fi) * c, int(d.n) * c, c, c)

static func celda_caida(n: int, k: int) -> Rect2i:
	var c := int(BOLAS_J.c)
	return Rect2i((int(BOLAS_J.dirs) * int(BOLAS_J.fases) + k) * c, n * c, c, c)

# la sombra en el paño, la silueta corrida 1 px abajo a la derecha
static func _sombra(o: Array, cx: int, cy: int) -> void:
	var c := "rgba(10,30,18,0.45)"
	o.append([cx, cy - 1, 3, 1, c])
	o.append([cx - 1, cy, 5, 3, c])
	o.append([cx, cy + 3, 3, 1, c])

static func _bola_d(o: Array, cx: int, cy: int, d: Dictionary, clip: Rect2i) -> void:
	if carga_bolas():
		o.append(["@", BOLAS, cx - 2, cy - 2, clip, celda_bola(d)])
	else:
		_bola(o, cx, cy, d.n)

static func _bola_n(o: Array, cx: int, cy: int, n: int, clip: Rect2i) -> void:
	_bola_d(o, cx, cy, {"n": n}, clip)

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
		if d.en:
			_sombra(o, x0 + roundi(d.p.x), y0 + roundi(d.p.y))
	# las que caen: hacia el centro de su tronera, cada vez más pequeñas y oscuras
	var T := troneras()
	for c in V.get("caen", []):
		if not c.has("t") or not carga_bolas():
			continue
		var k := (now - float(c.t)) / CAE_MS
		if k < 0 or k >= 1:
			continue
		var tp: Vector2 = T[0]
		for t in T:
			if t.distance_to(c.p) < tp.distance_to(c.p):
				tp = t
		var p: Vector2 = c.p.lerp(tp, minf(1.0, k * 2))
		o.append(["@", BOLAS, x0 + roundi(p.x) - 2, y0 + roundi(p.y) - 2, clip, celda_caida(int(c.n), mini(2, int(k * 3)))])
	for d in b:
		if d.en and d.n != 0:
			_bola_d(o, x0 + roundi(d.p.x), y0 + roundi(d.p.y), d, clip)
	var c0: Dictionary = b[0]
	var fase: String = V.fase
	if c0.en:
		_bola_d(o, x0 + roundi(c0.p.x), y0 + roundi(c0.p.y), c0, clip)
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
		if V.has("efe"):   # con CAL (venta.gd _b8_tuyo): las marcas de un cuarto, la del último tiro y el efecto de la blanca
			for k in [1, 2, 3]:
				o.append([bx - 2, y0 - 4 + bh - roundi(bh * k / 4.0), 2, 1, "#a0a0a8" if k != 2 else "#f8f8f0"])
			if V.has("fza"):
				o.append([bx, y0 - 4 + bh - roundi(float(V.fza) * bh), 5, 1, "#f8f8f0"])
			var ey := y0 + bh + 2   # la blanca de frente, con el punto donde le da el taco
			o.append([bx - 1, ey, 7, 7, "#26262e"])
			o.append([bx, ey + 1, 5, 5, "#f8f8f0"])
			o.append([bx + 1, ey, 3, 7, "#f8f8f0"])
			o.append([bx + 1, ey + 1, 3, 5, "#f8f8f0"])
			o.append([bx + 2, ey + 3 - roundi(float(V.efe) * 2), 1, 1, "#e04040"])
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
				_bola_n(o, xx + 3 + i * 7, yb, L[i].n, clip)
			else:
				_aro(o, xx + 3 + i * 7, yb, "rgba(255,255,255,0.25)")
		if g != "" and quedan(V, g) == 0:
			_bola_n(o, xx + 3 + 7 * 7, yb, 8, clip)
	return o.filter(func(x): return typeof(x[0]) == TYPE_STRING or (x[0] >= 0 and x[1] >= 0 and x[0] + x[2] <= sw and x[1] + x[3] <= sh))   # nada fuera de la pantalla (los sprites, con su recorte)
