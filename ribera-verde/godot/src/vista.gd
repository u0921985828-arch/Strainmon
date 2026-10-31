# Ribera Verde (Godot) — la vista C de 09b-carpa.js: la carpa por dentro a pantalla completa (imagen A).
# geo(S, ci) es vcGeo + vistaC: dónde va cada maceta y qué planta, a qué alto. pinta(S, VC, now) dibuja como renderCarpaC:
# fondo negro, pared, macetas y plantas (las de delante de la fila elegida en transparencia), la luz del foco en «overlay»
# (shader sobre lo ya pintado), la campana y el cursor. Todo en px del juego: el nodo va en el SubViewport de SH de alto, con la escena abajo (pinta: alto).
# Encima de cada planta, su barra de agua y de cosecha con el aviso de plaga, y los daños de la plaga pintados sobre sus
# hojas (como el HTML desde la 1.10: barras, posCursor, vcBarra y vcDano de 09b-carpa.js).
extends Node2D

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Arte = preload("res://src/arte.gd")
const Procedural = preload("res://src/procedural.gd")
const Atlas = preload("res://src/atlas.gd")

# el canvas guarda el alfa global en 8 bits: .35 → 89/255
const A35 := 89 / 255.0
# barra de cada planta: marco, agua (2 filas), raya, cosecha (2 filas), marco; con plaga, la «!» al lado
const BW := 16
const BH := 7
const BP := 6
const OSC := Color8(0x26, 0x26, 0x2e)
const SEL_TEMP := -2   # VC.sel del temporizador (1.10)
const RUEDA := [[3, 0], [4, 0], [5, 1], [6, 2], [6, 3], [6, 4], [5, 5], [4, 6], [3, 6], [2, 6], [1, 5], [0, 4], [0, 3], [0, 2], [1, 1], [2, 0]]
const VACIO := Color8(0x4a, 0x4a, 0x56)
# con CAL, con el foco apagado (las horas de noche del temporizador, Cultivo.foco_on, o sin plantas), la carpa a oscuras con la luz
# verde de trabajo (Arte.VERDE_C; lo pidió el usuario: «como si tuviese luz verde en el armario para no joder las plantas»)

const OVERLAY := """// i18n-no
shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, filter_nearest;
uniform float fuerza = 1.0;
uniform vec3 oscuro = vec3(1.0);
void fragment() {
	vec4 s = texture(TEXTURE, UV);
	vec3 b = texture(pantalla, SCREEN_UV).rgb;
	vec3 m = 2.0 * b * s.rgb;
	vec3 n = 1.0 - 2.0 * (1.0 - b) * (1.0 - s.rgb);
	vec3 o = mix(m, n, step(vec3(0.5000001), b));
	COLOR = vec4(mix(b, o, s.a * fuerza) * oscuro, 1.0);   // oscuro: la noche del temporizador (con CAL)
}
"""

var base := Node2D.new()
var luz := Sprite2D.new()
var encima := Node2D.new()
var S: Dictionary
var VC: Dictionary
var g: Dictionary
var now := 0.0
var sw := 240
var sh := 160   # el alto del lienzo (180 en el juego): la escena va abajo

func _init() -> void:
	for n in [base, luz, encima]:
		add_child(n)
	luz.centered = false
	var shd := Shader.new()
	shd.code = OVERLAY
	luz.material = ShaderMaterial.new()
	luz.material.shader = shd
	base.draw.connect(_pinta_base)
	encima.draw.connect(_pinta_encima)

# ---------- geometría ----------
# (cerca: si ninguno entra en el 25 %, el más cercano: con el atlas, la carpa nunca vuelve a la vista B por un ancho)
static func vc_sprite(pre: String, px: float, cerca := false):
	var m = null
	for a in Arte.anchos(pre):
		if (cerca or absf(a - px) <= px * .25) and (m == null or absf(a - px) < absf(m.a - px)):
			m = {"a": a, "n": pre + str(a)}
	return m

static func vc_planta_sprite(po: String, st: int, esp: int):
	var pre := "planta-c-" + ("h" if st < 2 else po) + ("" if st >= 3 else str(st)) + "-"
	var A := Arte.anchos(pre)
	if A.is_empty():
		return null
	A.sort()
	var a: int = A[0]
	for x in A:
		if x <= esp - 2:
			a = x
	return {"a": a, "n": pre + str(a)}

# vcGeo: la vista B (P pasa cm a px: x desde la izquierda, y de fondo desde el frente, z de alto) y, si hay arte para todo, la C
static func punto(g: Dictionary, x: float, y: float, z: float) -> Array:
	var VB: Dictionary = Datos.carga().VB
	if g.has("pk"):   # la carpa plateada de frente: cada fondo y, entre las columnas del suelo de delante y las de la pared
		var k: Dictionary = g.pk
		var t: float = y / g.D
		var xl: float = g.x0 + (k.xb[0] - k.xf[0]) * t
		var xr: float = g.x0 + g.w + (k.xb[1] - k.xf[1]) * t
		return [Datos.jsround(xl + (xr - xl) * x / g.W), Datos.jsround(g.yf - 17 * t - z * VB.M)]
	return [Datos.jsround(g.x0 + x * VB.M + y * VB.X), Datos.jsround(g.yf - y * VB.F - z * VB.M)]

static func geo(S: Dictionary, ci: int):
	var D := Datos.carga()
	var VB: Dictionary = D.VB
	var c: Dictionary = S.carpas[ci]
	var C: Dictionary = D.CARPAS[c.t]
	var W: float = C.cm[0]
	var H: float = C.cm[1]
	var Dp: float = C.cm[2]
	var w := Datos.jsround(W * VB.M)
	var sx := Datos.jsround(Dp * VB.X)
	var o := {"c": c, "C": C, "W": W, "H": H, "D": Dp, "w": w, "s": sx, "x0": 120 - ((w + sx) >> 1), "yf": int(VB.PARED) + Datos.jsround(Dp * VB.F)}
	var f = Atlas.foto_misc("carpa-" + c.t + "-vista") if VB.PLATA.has(c.t) else null
	if f:   # con el atlas, la carpa plateada de frente (VB_PLATA)
		var k: Dictionary = VB.PLATA[c.t]
		o.pk = k
		o.plata = f
		o.x0 = 120 + int(k.xf[0])
		o.w = int(k.xf[1]) - int(k.xf[0]) + 1
		o.s = 0
		o.yf = 155
	var pl := []
	var hu := Cultivo.huecos(S)
	for i in hu.size():
		var q: Dictionary = hu[i]
		if q.c != ci:
			continue
		var r := plaza_rejilla(C, q.j)
		r.i = i
		pl.append(r)
	if Datos.CAL:
		tresbolillo(pl, W, S.macetas)
	for a in pl:
		var d := 2 * minf(minf(a.cx, W - a.cx), minf(a.cy, Dp - a.cy))
		for b in pl:
			if b != a:
				d = minf(d, sqrt((a.cx - b.cx) * (a.cx - b.cx) + (a.cy - b.cy) * (a.cy - b.cy)))
		a.cw = d - D.HOLGURA
		a.ch = H - 28 - D.FOCO_SEP.get(c.foco, 40) - D.MACETA_CM.get(S.macetas[a.i], D.MACETA_CM.plastico7)[1]
		var xy := punto(o, a.cx, a.cy, 0)
		a.x = xy[0]
		a.y = xy[1]
	o.pl = pl
	o.fx = punto(o, W / 2, Dp / 2, 0)[0]
	o.fy = punto(o, 0, Dp / 2, H - 28)[1]
	o.barra = punto(o, 0, Dp / 2, H - 4)[1]
	if f:   # de frente, lo que cuelga no sube del techo de dentro (8 filas sobre yt): cuerdas, campana y filtro
		o.techo = 157 + int(o.pk.yt) - 8
		o.barra = maxi(o.barra, o.techo)
		o.fy = maxi(o.fy, o.techo + Procedural.foco34(c.foco).get_height() - 1)
	o.vc = vista_c(S, o)
	if o.vc:
		o.fx = 120
		o.fy = o.vc.fy
		o.fw = o.vc.foco.a
	else:   # vista B: lo que se ve de cada plaza por encima del suelo (maceta y planta) y el ancho del foco
		o.fw = Procedural.foco34(c.foco).get_width()
		for q in pl:
			var mp := Procedural.maceta_px(S.macetas[q.i])
			q.alto = mp.hb + Datos.jsround(mp.e / 2.0)
			var p = S.pots[q.i]
			if p:
				q.alto += Procedural.alto_planta(Datos.porte_planta(S, p), 0 if p.get("dead") else Cultivo.plant_stage(p), true if p.get("dead") else false, q)
	o.tx = (int(o.vc.xl) - 24) if o.vc else (int(o.x0) - 16)   # el temporizador (1.10), a la izquierda de la carpa
	if o.vc and C.get("sl"):   # KAIA, con el servicio a la izquierda (kc_lado): en la pared de la derecha, en espejo
		o.tx = int(o.vc.xl) + int(o.vc.w) + 13
	o.ty = 84
	return o

# la plaza j de la carpa C en su rejilla: columna, fila y centro (cm desde la esquina izquierda de atrás)
static func plaza_rejilla(C: Dictionary, j: int) -> Dictionary:
	var cols := int(C.cols)
	var col: int = j % cols
	var fila: int = j / cols
	var n := mini(cols, int(C.plazas) - fila * cols)
	return {"col": col, "fila": fila, "cx": (col + .5) * float(C.cm[0]) / n, "cy": (fila + .5) * float(C.cm[2]) / C.filas}

# (lo pidió el usuario: «un plano desde arriba… para aprovechar el espacio y que desde la vista C se vean lo mejor posible las plantas…
# en tres bolillos… en las que se pueda»): las filas seguidas con las mismas plazas se corren a un lado y a otro, alternas, un cuarto de
# su separación o lo que deje la maceta más ancha de la fila hasta la pared (TRES_HOLGURA cm); con menos de TRES_MIN cm, quietas. Una
# fila con otro número de plazas ya cae entre las de al lado. Lo dibuja tests/plantacion.gd (docs/plano/plantacion)
const TRES_HOLGURA := 2.0
const TRES_MIN := 3.0
static func tresbolillo(pl: Array, W: float, macetas: Array) -> void:
	var D := Datos.carga()
	var F := {}
	for q in pl:
		if not F.has(q.fila):
			F[q.fila] = {"n": 0, "d": 0.0}
		F[q.fila].n += 1
		var k: String = macetas[q.i] if D.MACETA_CM.has(macetas[q.i]) else "plastico7"
		F[q.fila].d = maxf(F[q.fila].d, float(D.MACETA_CM[k][0]))
	var lado := {}
	var sg := 1
	for f in range(F.size()):
		var n: int = F[f].n
		if F.has(f - 1) and F[f - 1].n == n or F.has(f + 1) and F[f + 1].n == n:
			var s := minf(W / (4 * n), W / (2 * n) - F[f].d / 2 - TRES_HOLGURA)
			lado[f] = s * sg if s >= TRES_MIN else 0.0
			sg = -sg
	for q in pl:
		q.cx += float(lado.get(q.fila, 0.0))

# el temporizador de enchufe (1.10, 09b-carpa: vcTemp), como rectángulos [x, y, w, h, color]: caja blanca de 11 × 13 con su rueda
# de 16 pinzas (las bajadas, CICLOS[k].on, del color de su modo) y, debajo, el enchufe y el piloto; cuelga de su cable desde arriba
static func temporizador(x: int, y: int, k: String, on: bool) -> Array:
	var C: Dictionary = Datos.carga().CICLOS[k]
	var o := [[x + 5, 0, 1, y, Arte.VC_CUERDA], [x + 1, y, 9, 1, OSC], [x, y + 1, 11, 11, OSC], [x + 1, y + 12, 9, 1, OSC], [x + 1, y + 1, 9, 11, Color.html("#e8e8e0")],
		[x + 9, y + 2, 1, 10, Color.html("#bcb4a2")], [x + 2, y + 11, 7, 1, Color.html("#bcb4a2")], [x + 3, y + 2, 5, 5, Color.html("#f8f8f0")]]
	for n in RUEDA.size():
		o.append([x + 2 + RUEDA[n][0], y + 1 + RUEDA[n][1], 1, 1, Color.html(C.col) if n < int(C.on) else Color.html("#6a6e78")])
	o.append_array([[x + 5, y + 3, 1, 2, OSC], [x + 4, y + 9, 1, 1, OSC], [x + 6, y + 9, 1, 1, OSC], [x + 8, y + 9, 1, 1, Color.html("#e04040") if on else Color.html("#7a2a30")]])
	return o

# el del piso, en la pared a la izquierda de la carpa (5 × 7) y su cable hasta ella (xl: su borde)
static func temporizador_mapa(xl: int, yb: int, k: String) -> Array:
	var x := xl - 7
	var y := yb - 29
	return [[x, y, 5, 7, OSC], [x + 1, y + 1, 3, 5, Color.html("#e8e8e0")], [x + 1, y + 1, 3, 3, Color.html(Datos.carga().CICLOS[k].col)], [x + 2, y + 2, 1, 1, Color.html("#f8f8f0")],
		[x + 2, y + 5, 1, 1, OSC], [x + 5, y + 4, 2, 1, Arte.VC_CUERDA]]

static func vista_c(S: Dictionary, g: Dictionary):
	var D := Datos.carga()
	var c: Dictionary = g.c
	var W: float = g.W
	var tipo: String = D.FOCOS[c.foco].tipo
	var VCA: Dictionary = D.VCA
	var Z: float = (VCA.base - VCA.boca) / (g.H - 28)
	if g.C.get("kc"):   # las carpas grandes de KAIA (kaiacult.gd): como mucho VC_KC_W px de ancho, más lejos
		Z = minf(Z, VC_KC_W / W)
	var w := Datos.jsround(W * Z)
	# las campanas de sodio son foco-c-NN; el CFL, foco-c-cfl-NN, y los LED, con su modelo (foco-c-led200-NN)
	var pf: String = "foco-c-" if tipo == "sodio" else ("foco-c-" + c.foco + "-" if tipo == "led" else "foco-c-" + tipo + "-")
	var pxf: float = D.FOCO_CM.get(c.foco, 45) * Z
	if g.C.get("kc"):   # los LED de KAIA (c.nf a lo ancho), un poco más estrechos que su parte, para que se vean separados
		pxf = minf(pxf, float(w) / maxi(1, int(c.get("nf", 1))) - 3)
	var foco = vc_sprite(pf, pxf, true)
	if not Arte.hay("carpa-c-pared") or not Arte.hay("carpa-c-luz") or foco == null:
		return null
	# el techo para el foco: en las de KAIA, el extractor con su filtro cuelga donde sale su tubo (kc_filtro) y el LED no sube más que
	# su parte de abajo (le quita su alto a la carpa, como de verdad); en las demás, y en la mitad de delante de la de 4 × 4, VCA.boca
	var tope := int(VCA.boca)
	if g.C.get("kc") and g.C.get("ext", true):
		var T := kc_techo(W, g.H, maxi(1, int(c.get("nf", 1))), String(c.foco), g.C.get("fil", [50, 1]))
		var f := kc_filtro_en(T, int(T.xl) + Datos.jsround(float(g.C.get("ux", .5)) * int(T.w)), float(g.C.get("ux", .5)) < .5) if not T.is_empty() else {}
		if not f.is_empty():
			tope = maxi(tope, 3 + Arte.alto(f.im) + 15 - Arte.foto(foco.n).get_used_rect().position.y)
	var filas: Array = D.VC_FILA[int(g.C.filas) - 1] if int(g.C.filas) <= D.VC_FILA.size() else filas_n(int(g.C.filas))
	var wy := func(y: float) -> float: return w + 32 * (y - VCA.fondo) / 19
	var yq := func(q: Dictionary) -> int: return int(filas[mini(q.fila, filas.size() - 1)])
	var xy := func(q: Dictionary, y: float) -> int: return Datos.jsround(120 + (q.cx / W - .5) * wy.call(y))
	var v := []
	var fy := 1000000000
	var viva := false
	for q in g.pl:
		# la de 7 L es maceta-c-NN; las demás llevan su tipo (maceta-c-tela11-NN)
		var k: String = S.macetas[q.i] if D.MACETA_CM.has(S.macetas[q.i]) else "plastico7"
		var m = vc_sprite("maceta-c-" if k == "plastico7" else "maceta-c-" + k + "-", D.MACETA_CM[k][0] * Z, true)
		if m == null:
			return null
		var y: int = yq.call(q)
		var x: int = xy.call(q, y)
		var r := {"x": x, "y": y, "m": m, "Z": Z, "tierra": D.VC_TIERRA.get(m.n, Datos.jsround(Arte.foto(m.n).get_height() * .7)), "hp": 0, "p": null, "muerta": false}
		var p = S.pots[q.i]
		if p:   # la muerta: la de su porte en vegetativo, seca (marrón) y 4 cm más baja
			var muerta := true if p.get("dead") else false
			r.muerta = muerta
			var st := 2 if muerta else Cultivo.plant_stage(p)
			var po := Datos.porte_planta(S, p)
			var Dh: Array = D.PLANTA_CM[po].h
			var e: float = wy.call(y) - 2 * absf(x - 120)
			for o in g.pl:
				if o != q and yq.call(o) == y:
					e = minf(e, absf(xy.call(o, y) - x))
			r.esp = Datos.jsround(e)
			var s = vc_planta_sprite(po, st, r.esp)
			if s == null:
				return null
			r.p = s
			r.hp = mini(Arte.alto(Arte.foto(s.n)), mini(Datos.jsround(minf(Dh[st] - (4 if muerta else 0), q.ch) * Z), int(floor(y - r.tierra - tope - D.FOCO_SEP[c.foco] * Z))))
			# el foco, a la distancia de su fase de la cima de cada planta (la que lo tiene más cerca manda); de la muerta, a la de seguridad
			if not muerta:
				viva = true
			fy = mini(fy, int(y - r.tierra - r.hp) - Datos.jsround(D.FOCO_SEP[c.foco] * (1 if muerta else D.FOCO_FASE[st]) * Z))
		v.append(r)
	for j in g.pl.size():
		var q: Dictionary = g.pl[j]
		q.v = v[j]
		q.x = v[j].x
		q.y = v[j].y
		q.alto = v[j].tierra + 4 + v[j].hp
	# el goteo: una manguera por fila, en el suelo detrás de sus macetas, de la primera llave a la pared derecha; cada maceta, su
	# llave y su microtubo justo a su derecha (bx)
	var lg = null
	if c.get("goteo"):
		var F := {}
		var orden_f := []
		for q in g.pl:
			var x1: int = Arte.caja(Arte.foto(q.v.m.n))[1]
			if not F.has(q.fila):
				F[q.fila] = {"fila": q.fila, "y": q.y - 3, "x": 1e9}
				orden_f.append(q.fila)
			var f: Dictionary = F[q.fila]
			q.bx = q.x - 16 + x1 + 2
			q.yl = f.y
			f.x = minf(f.x, q.bx)
		orden_f.sort()
		lg = []
		for k in orden_f:
			lg.append(F[k])
		lg.sort_custom(func(a, b): return a.y < b.y)
		for f in lg:
			f.x = int(f.x)
			f.xw = Datos.jsround(120 + wy.call(f.y) / 2) - 1
			f.xl = Datos.jsround(120 - wy.call(f.y) / 2)   # la pared izquierda, por donde entra en las de KAIA con el depósito a ese lado
	# la boca del foco (fy): baja hasta su distancia de las plantas, nunca por encima del techo (VCA.boca); sin vivas (apagado), arriba
	fy = maxi(tope, fy) if viva else tope
	var fxs := []   # dónde cuelga cada foco: uno en el centro; en las de KAIA, sus LED repartidos a lo ancho (c.nf)
	var nf := maxi(1, int(c.get("nf", 1)))
	for k in nf:
		fxs.append(120 + Datos.jsround((k + .5) * w / nf - w / 2.0))
	return {"Z": Z, "w": w, "xl": 120 - (w >> 1), "foco": foco, "tipo": tipo, "lg": lg, "fy": fy, "fxs": fxs}

# las carpas de KAIA de más de dos filas (de delante atrás, de la fila 158 a la 140 del suelo)
const VC_KC_W := 156.0
static func filas_n(n: int) -> Array:
	var o := []
	for i in n:
		o.append(158 - Datos.jsround(i * 18.0 / maxi(1, n - 1)))
	return o

# ---------- dibujo ----------
# las poleas del foco bajado (vcPoleas), como rectángulos [x, y, w, h, color]: una por lado, colgada del techo (fila VCA.boca − 15) por
# fuera de cada extremo de la fila de arriba de la campana; la cuerda que sostiene baja por su borde de dentro hasta la campana y la que
# se tira, por el de fuera, 8 filas, con su tirador
static func poleas(fc: Image, fy: int, cx0 := 120) -> Array:
	var cu := Arte.cuelga(fc)
	var fx := cx0 - (fc.get_width() >> 1)
	var y0 := int(Datos.carga().VCA.boca) - 15
	var K: Color = Arte.VC_CUERDA
	var M: Color = Arte.VC_POLEA[0]
	var H: Color = Arte.VC_POLEA[1]
	var o := []
	for ls in [[fx + cu[0], -1], [fx + cu[1], 1]]:
		var X: int = ls[0]
		var cx: int = X + 2 * ls[1]
		var T: int = X + 4 * ls[1]
		# cuerdas, tirador (contorno y cuerpo), rueda (contorno de 5 × 5 sin esquinas, cuerpo, eje y brillo) y el gancho del techo
		o.append_array([[X, y0 + 3, 1, fy - 15 + cu[2] - (y0 + 3), K], [T, y0 + 3, 1, 8, K], [T - 1, y0 + 11, 3, 3, K], [T, y0 + 12, 1, 1, M],
			[cx - 1, y0 + 1, 3, 5, K], [cx - 2, y0 + 2, 5, 3, K], [cx - 1, y0 + 2, 3, 3, M], [cx, y0 + 3, 1, 1, K], [cx - 1, y0 + 2, 1, 1, H], [cx, y0, 1, 1, K]])
	return o.filter(func(e): return e[3] > 0)

# de atrás adelante: fila (y), luego x y plaza
static func orden(g_: Dictionary) -> Array:
	var o: Array = g_.pl.duplicate()
	o.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and (a.x < b.x or (a.x == b.x and a.i < b.i))))
	return o

static func clave_planta(S_: Dictionary, p: Dictionary, v: Dictionary) -> String:
	var k := "pl|%s|%d|%s|%s|%s" % [v.p.n, v.hp, Datos.color_cog(S_, p), Datos.hoja_planta(S_, p), p.water <= 0]
	var n := nivel_dano(p)
	return k + ("|d%d|%d" % [n, semilla(p)] if n else "")

# daños de la plaga según la salud que le queda; tratada, ninguno
static func nivel_dano(p: Dictionary) -> int:
	if not p.pest or p.get("dead"):
		return 0
	return 1 if p.health >= 75 else (2 if p.health >= 45 else 3)

# cada planta, sus manchas: del id de su fenotipo (los esquejes, las de su madre)
static func semilla(p: Dictionary) -> int:
	var f = p.get("f")
	return int(f.id) if f is Dictionary and f.get("id") else Datos.hash_str(p.sid)

# la planta tal como se pinta: el fotograma de su alto (sin las filas de más), con los colores de su variedad y seca sin agua
static func img_planta(S_: Dictionary, p: Dictionary, v: Dictionary) -> Image:
	var sc := Datos.color_cog(S_, p)
	var c0 := Arte.aplasta(Arte.altura(v.p.n, v.hp)[1], v.hp)
	var mapa := {Arte.rampa[0]: Datos.shade(sc, 50), Arte.rampa[1]: sc, Arte.rampa[2]: Datos.shade(sc, -60)}
	mapa.merge(Datos.vc_tonos(Datos.hoja_planta(S_, p)), true)
	var im := Arte.recolor(c0, mapa)
	var n := nivel_dano(p)
	if n:
		im = Arte.dano(im, c0, n, semilla(p) ^ Datos.hash_str(v.p.n))
	if p.water <= 0:
		im = Arte.seca(im)
	return im

# la textura de la planta de la plaza q (la seca, de su porte en marrón) o null si no hay
static func tex_planta(S_: Dictionary, q: Dictionary) -> ImageTexture:
	var p = S_.pots[q.i]
	var v: Dictionary = q.v
	if p == null or v.p == null:
		return null
	var k := ("seca|%s|%d" % [v.p.n, v.hp]) if v.muerta else clave_planta(S_, p, v)
	var t: ImageTexture = Arte.tex_de(k)
	if t == null:
		var im := Arte.recolor(Arte.aplasta(Arte.altura(v.p.n, v.hp)[1], v.hp), Datos.carga().VC_SECA) if v.muerta else img_planta(S_, p, v)
		t = Arte.tex(k, im)
		t.set_meta("uso", uso_de(im))
	return t

# su garrafa (sin goteo), o null
static func garrafa_sp(S_: Dictionary, q: Dictionary):
	var ca: Dictionary = S_.carpas[Cultivo.huecos(S_)[q.i].c]
	var gar := Cultivo.garrafa_l(S_, q.i) if ca.get("garrafas") and not ca.get("goteo") else 0
	return vc_sprite("extra-c-garrafa-", 100 * pow(gar / 1000.0 / (.7 * .5 * .85), 1 / 3.0) * q.v.Z, true) if gar else null

# (lo pidió el usuario: «lo mismo con las plantas, lo que viene siendo el tallo y la tierra… tiene que estar a la vista») la tierra de
# cada maceta (de su borde a 2 filas por debajo de la superficie, zona_tierra) y las VC_TALLO filas de abajo de su tallo (zona_tallo):
# si una maceta, una planta o una garrafa que se pinta después (más adelante, o al lado en su fila) las pisa, se vuelven a pintar
# encima al A_VISTA, vistas a través (a_la_vista, _a_la_vista). Las de delante de la fila elegida ya van en transparencia: ni pisan ni
# se repintan
const VC_TALLO := 8
const A_VISTA := 166 / 255.0

# lo pintado de la planta (Rect2i) y las columnas del pie de su tallo (la última fila con algo); va en la textura (tex_planta)
static func uso_de(im: Image) -> Array:
	var u := im.get_used_rect()
	var a := im.get_width()
	var b := -1
	var y := u.end.y - 1
	while b < 0 and y >= u.position.y:
		for x in im.get_width():
			if im.get_pixel(x, y).a8 > 0:
				a = mini(a, x)
				b = maxi(b, x)
		y -= 1
	return [u, a, b]

static func uso_planta(t: ImageTexture) -> Array:
	if not t.has_meta("uso"):
		t.set_meta("uso", uso_de(t.get_image()))
	return t.get_meta("uso")

static func zona_tierra(q: Dictionary) -> Rect2i:
	var mi := Arte.foto(q.v.m.n)
	var cx: Array = Arte.caja(mi)
	var rim: int = q.y - 31 + (mi.get_height() - Arte.alto(mi))
	return Rect2i(q.x - 16 + int(cx[0]), rim, int(cx[1]) - int(cx[0]) + 1, q.y - int(q.v.tierra) + 3 - rim)

static func zona_tallo(S_: Dictionary, q: Dictionary) -> Rect2i:
	var t := tex_planta(S_, q)
	if t == null:
		return Rect2i()
	var u: Array = uso_planta(t)
	var yb: int = q.y - int(q.v.tierra)
	var x: int = q.x - (t.get_width() >> 1)
	var h := mini(VC_TALLO, t.get_height())
	return Rect2i(x + int(u[1]) - 1, yb - h + 1, int(u[2]) - int(u[1]) + 3, h)

# lo que pinta la plaza q: su maceta, su planta (1 px más a cada lado, por el balanceo) y su garrafa
static func cajas_de(S_: Dictionary, q: Dictionary) -> Array:
	var mi := Arte.foto(q.v.m.n)
	var cx: Array = Arte.caja(mi)
	var top: int = mi.get_height() - Arte.alto(mi)
	var o := [Rect2i(q.x - 16 + int(cx[0]), q.y - 31 + top, int(cx[1]) - int(cx[0]) + 1, mi.get_height() - top)]
	var t := tex_planta(S_, q)
	if t != null:
		var u: Rect2i = uso_planta(t)[0]
		o.append(Rect2i(q.x - (t.get_width() >> 1) + u.position.x - 1, q.y - int(q.v.tierra) - t.get_height() + 1 + u.position.y, u.size.x + 2, u.size.y))
	var gs = garrafa_sp(S_, q)
	if gs:
		var gf := Arte.foto(gs.n)
		var gu := gf.get_used_rect()
		o.append(Rect2i(q.x - 16 + int(cx[1]) - 1 - 24 + gu.position.x, q.y - 3 - 47 + gu.position.y, gu.size.x, gu.size.y))
	return o

# las plazas (de orden) cuya tierra o tallo pisa algo que se pinta después
static func a_la_vista(S_: Dictionary, g_: Dictionary, fsel := 0) -> Array:
	var o := []
	if not Datos.CAL or g_.is_empty() or g_.vc == null:
		return o
	var ord := orden(g_)
	var cs := []
	for q in ord:
		cs.append(cajas_de(S_, q) if q.fila >= fsel else [])
	for j in ord.size():
		var q: Dictionary = ord[j]
		if q.fila < fsel:
			continue
		var zs := [zona_tierra(q), zona_tallo(S_, q)]
		var pisa := false
		for k in range(j + 1, ord.size()):
			for r in cs[k]:
				for z in zs:
					if z.has_area() and r.intersects(z):
						pisa = true
		if pisa:
			o.append(q)
	return o

# las barras, de delante atrás: cada una encima de su planta (2 filas de aire) y, si pisa otra, encima de esa. La de la
# plaza elegida deja sitio encima para el cursor (CUR filas); si la elegida no tiene barra (vacía o muerta), su cursor
# también aparta las barras
const CUR := 7
static func con_barra(S_: Dictionary, q: Dictionary) -> bool:
	var p = S_.pots[q.i]
	return p != null and not p.get("dead") and (not q.has("v") or q.v.p != null)

static func barras(S_: Dictionary, g_: Dictionary, sel := -1) -> Array:
	var o := []
	if g_.is_empty():
		return o
	var cajas := []
	for q in g_.pl:
		if q.i == sel and not con_barra(S_, q):
			cajas.append(caja_cursor(pos_cursor(g_, sel, [])))
	var pl: Array = g_.pl.duplicate()
	pl.sort_custom(func(a, b): return a.y > b.y or (a.y == b.y and (a.x < b.x or (a.x == b.x and a.i < b.i))))
	# con CAL, la tierra y el tallo de las demás (de la fila elegida y de detrás) también apartan la barra (a_la_vista)
	var zs := []
	if Datos.CAL and g_.get("vc") != null:
		var fs := fila_sel(g_, sel)
		for q in g_.pl:
			if q.fila >= fs:
				zs.append([q.i, zona_tierra(q)])
				zs.append([q.i, zona_tallo(S_, q)])
	for q in pl:
		if not con_barra(S_, q):
			continue
		var p: Dictionary = S_.pots[q.i]
		var r := Rect2i(q.x - (BW >> 1), q.y - q.alto + 3 - BH, BW + (BP if p.pest else 0), BH)
		var cur := CUR if q.i == sel else 0
		var ob: Array = cajas.duplicate()
		for z in zs:
			if z[0] != q.i and z[1].has_area():
				ob.append(z[1])
		var mueve := true
		while mueve:
			mueve = false
			for c in ob:
				if c.grow(1).intersects(r.grow_individual(0, cur, 0, 0)):
					r.position.y = c.position.y - BH - 1
					mueve = true
		var caja := r.grow_individual(0, cur, 0, 0)
		cajas.append(caja)
		o.append({"i": q.i, "r": r, "p": p, "caja": caja, "fila": q.fila})
	return o

# el cursor de la plaza elegida (arriba a la izquierda de la flecha, sin el bote de 1 px): encima de su barra, en el sitio
# que deja, o encima de su planta (12 px si no hay)
static func pos_cursor(g_: Dictionary, sel: int, bs: Array) -> Vector2i:
	for q in g_.pl:
		if q.i == sel:
			for e in bs:
				if e.i == sel:
					return Vector2i(q.x, e.r.position.y - 6)
			return Vector2i(q.x, q.y - (q.alto if q.alto else 12) - 9)
	return Vector2i(-1, -1)

# lo que ocupa el cursor en pantalla con el bote: 9 × 7 px
static func caja_cursor(c: Vector2i) -> Rect2i:
	return Rect2i(c.x - 4, c.y - 1, 9, 7)

# la fila de la plaza elegida: las de delante van en transparencia
static func fila_sel(g_: Dictionary, sel: int) -> int:
	for q in g_.pl:
		if q.i == sel:
			return q.fila
	return 0

func pinta(S_: Dictionary, VC_: Dictionary, now_: float, ancho := 240, alto := 160) -> void:
	S = S_
	VC = VC_
	now = now_
	sw = ancho
	sh = alto
	g = geo(S, VC.ci)
	var ox := (sw - 240) >> 1
	for n in [base, luz, encima]:
		n.position = Vector2(ox, sh - 160)
	var on := Cultivo.foco_on(S, VC.ci)
	luz.visible = on and g.vc != null
	luz.material.set_shader_parameter("oscuro", Vector3.ONE)
	if luz.visible:
		luz.texture = Arte.tex("luz|%s|%s|%d|%d|%d|%s" % [g.c.t, g.vc.tipo, g.vc.foco.a, g.vc.fy, g.vc.fxs.size(), Datos.CAL], Arte.luz(g.c.t, g.vc))
		luz.material.set_shader_parameter("fuerza", Arte.luz_c().get(g.vc.tipo, [0, 1])[1])
	elif g.vc != null and (Datos.CAL or Cultivo.plantas_vivas(S, VC.ci)):   # apagado (la noche del temporizador o, con CAL, sin plantas): sin haz y a oscuras
		luz.visible = true
		luz.texture = Arte.tex("luz|vacia", Image.create(240, 160, false, Image.FORMAT_RGBA8))
		luz.material.set_shader_parameter("oscuro", Arte.VERDE_C)
	base.queue_redraw()
	encima.queue_redraw()

func _pinta_base() -> void:
	var ox := (sw - 240) >> 1
	base.draw_rect(Rect2(-ox, 160 - sh, sw, sh), Color.BLACK)
	if g.is_empty() or g.vc == null:
		return
	base.draw_texture(Arte.tex("pared|" + g.c.t, Arte.fondo(g.c.t, g.vc, "pared")), Vector2.ZERO)
	var c: Dictionary = g.c
	for e in temporizador(g.tx, g.ty, Cultivo.ciclo_de(c), Cultivo.foco_on(S, VC.ci)):
		base.draw_rect(Rect2(e[0], e[1], e[2], e[3]), e[4])
	var D := Datos.carga()
	var xr: int = g.vc.xl + g.vc.w
	# el filtro de carbón, colgado del techo arriba a la izquierda (el extractor tiembla 1 px), y el ventilador de pinza en el poste
	# del fondo derecho, a 55 cm del suelo, siempre girando
	var kk := Cultivo.kit_de(c)   # (1.11) el kit de 100 mm, a 30 cm; el de 150, a 50; el de 125, según la carpa
	if g.C.get("kc"):   # KAIA: el extractor donde sale su tubo (en la de 4 × 4, solo en la mitad del fondo) y su servicio (kc_servicio)
		var f := kc_filtro(g) if g.C.get("ext", true) else {}
		if not f.is_empty():
			base.draw_texture(Arte.tex(f.k, f.im), Vector2(int(f.x) + int(floor(now / 90)) % 2, f.y))
		for e in kc_servicio(g):
			base.draw_texture(Arte.tex(e.k, e.im), Vector2(e.x, e.y))
	elif kk != "":
		var fs = vc_sprite("extra-c-filtro-", (30 if kk == "filtro100" or kk == "filtro" and (c.t == "p60" or c.t == "p80") else 50) * g.vc.Z, true)
		var fi := Arte.foto(fs.n)
		base.draw_texture(Arte.tex("x|" + fs.n, fi), Vector2(g.vc.xl + 10 - 47 + int(floor(now / 90)) % 2, 3 - (fi.get_height() - Arte.alto(fi))))
	if c.get("vent"):
		var nv := posmod(int(floor(now / 70)), Arte.n_fotos("extra-c-vent"))
		base.draw_texture(Arte.tex("x|vent|%d" % nv, Arte.foto("extra-c-vent", nv)), Vector2(xr + 1 - 24, int(D.VCA.fondo) - Datos.jsround(55 * g.vc.Z) - 47))
	var fsel := fila_sel(g, VC.sel)
	var fa = null
	for q in orden(g):
		var al := A35 if q.fila < fsel else 1.0
		if g.vc.lg != null and q.fila != fa:
			fa = q.fila
			_ramal(g.vc.lg, fa, al)
		_planta(q, al)
	for q in a_la_vista(S, g, fsel):
		_a_la_vista(q)

# las carpas de KAIA por dentro (kc_def; lo pidió el usuario: «el extractor y el intractor… se verá… en la vista C, dependiendo de
# dónde esté la mesa colocada» y «lo más realista posible… coherencia y lógica»): el servicio (la puerta lateral, la ventana de malla
# y la manga del intractor, kc_def.serv) va en la pared del lado con más sitio libre al lado de la carpa en el mapa (kc_lado: sl, la
# izquierda), como en su sprite (kcs/kcsi); el aire entra por abajo por ese lado y sale por arriba por el otro: el extractor con su
# filtro cuelga del techo donde sale su tubo (ux, en la mitad contraria). El depósito del goteo está fuera (la tela no deja verlo): solo
# entra su manguera por el pasamuros (depi). Los sprites, de kaia_vc.py, dibujados en la tira de la pared de la derecha de la plantilla
# (VCA.lado): Arte.off es su esquina en la tira (u px desde la esquina de atrás, la fila); en la de la izquierda, en espejo
static func kc_servicio(g_: Dictionary) -> Array:
	var o := []
	var sl: bool = g_.C.get("sl", false)
	var xr: int = int(g_.vc.xl) + int(g_.vc.w)
	for s in g_.C.get("serv", []):
		var n := "kc-serv-" + String(s)
		if not Arte.hay(n) or not Arte.off.has(n):
			continue
		var im := Arte.foto(n)
		var of: Array = Arte.off[n]
		var k := "kcs|%s|%s" % [n, sl]
		if sl:
			var e: Image = Arte.cache.get(k)
			if e == null:
				e = im.duplicate()
				e.flip_x()
				Arte.cache[k] = e
			im = e
		o.append({"k": k, "im": im, "x": int(g_.vc.xl) - int(of[0]) - im.get_width() if sl else xr + int(of[0]), "y": int(of[1]), "n": n})
	return o

# el extractor con su filtro (kc_def.fil: su largo), colgado del techo donde sale su tubo (ux) y hacia la pared más cerca
static func kc_filtro(g_: Dictionary) -> Dictionary:
	var T := kc_techo(float(g_.W), float(g_.H), maxi(1, int(g_.c.get("nf", 1))), String(g_.c.foco), g_.C.get("fil", [50, 1]))
	var ux := float(g_.C.get("ux", .5))
	return kc_filtro_en(T, int(g_.vc.xl) + Datos.jsround(ux * int(g_.vc.w)), ux < .5) if not T.is_empty() else {}

# el techo de una carpa de KAIA en su vista C, como en vista_c: su escala, su ancho y, de cada LED (nf a lo ancho), las columnas de sus
# dos cuerdas con su trinquete y su rueda (poleas); con eso, el extractor con su filtro cuelga donde no lo cruza ninguna (kc_filtro_en)
# y el tubo del mapa sale por donde cabe (kaiacult.gd kc_cabe_filtro)
static func kc_techo(W: float, H: float, nf: int, foco_k: String, fil: Array) -> Dictionary:
	var D := Datos.carga()
	var Z: float = minf((float(D.VCA.base) - float(D.VCA.boca)) / (H - 28), VC_KC_W / W)
	var w := Datos.jsround(W * Z)
	var foco = vc_sprite("foco-c-" + foco_k + "-", minf(D.FOCO_CM.get(foco_k, 45) * Z, float(w) / maxi(1, nf) - 3), true)
	var fs = vc_sprite("extra-c-filtro-", float(fil[0]) * Z, true)
	if foco == null or fs == null:
		return {}
	var fc := Arte.foto(foco.n)
	var oc := []
	for k in maxi(1, nf):
		for e in poleas(fc, int(D.VCA.boca) + 30, 120 + Datos.jsround((k + .5) * w / maxi(1, nf) - w / 2.0)):
			oc.append([int(e[0]), int(e[0]) + int(e[2]) - 1])
	return {"Z": Z, "w": w, "xl": 120 - (w >> 1), "fs": fs, "oc": oc}

# el extractor con su filtro, con su tubo en la columna xd (donde sale por el techo en el mapa): tumbado de lado hacia la pared más
# cerca (izq0) o, si así lo cruza una cuerda, hacia la otra; si de lado no cabe entre las cuerdas de un LED (en las de 4 m, con cuatro
# LED a lo ancho, el de 75 cm no cabe), tumbado de frente a fondo (kc-filtrof-*, de kaia_vc.py: su tapa redonda), como se cuelga de
# verdad entre dos LED; con su temblor de 1 px y otro de aire, sin tocar ninguna cuerda, trinquete ni rueda ({} si no cabe de ninguna)
static func kc_filtro_en(T: Dictionary, xd: int, izq0: bool) -> Dictionary:
	var libre := func(a: int, b: int) -> bool: return T.oc.all(func(o): return int(o[1]) < a - 1 or int(o[0]) > b + 2)
	var fi := Arte.foto(T.fs.n)
	var bb: Array = Arte.caja(fi)
	var y := 3 - (fi.get_height() - Arte.alto(fi))
	for iz in [izq0, not izq0]:
		var cx: int = int(bb[0]) + 3   # el tubo de aluminio, encima del extractor (columnas 1 a 6 desde el canto)
		var a: int = xd - cx + int(bb[0])
		var b: int = xd - cx + int(bb[1])
		if iz:   # hacia la izquierda: en espejo, con el extractor a la derecha
			cx = fi.get_width() - 1 - cx
			a = xd - cx + fi.get_width() - 1 - int(bb[1])
			b = xd - cx + fi.get_width() - 1 - int(bb[0])
		if not libre.call(a, b):
			continue
		var k: String = "x|%s|%s" % [T.fs.n, "i" if iz else "d"]
		var im := fi
		if iz:
			im = Arte.cache.get(k)
			if im == null:
				im = fi.duplicate()
				im.flip_x()
				Arte.cache[k] = im
		return {"k": k, "im": im, "x": xd - cx, "y": y, "xd": xd, "de": "lado"}
	var n: String = "kc-filtrof-" + str(T.fs.a)
	if Arte.hay(n):
		var ff := Arte.foto(n)
		var bf: Array = Arte.caja(ff)
		if libre.call(xd - 23 + int(bf[0]), xd - 23 + int(bf[1])):   # el tubo, en las columnas 22 a 25: la 23, como el de lado
			return {"k": "x|" + n, "im": ff, "x": xd - 23, "y": 3 - (ff.get_height() - Arte.alto(ff)), "xd": xd, "de": "frente"}
	return {}

# la manguera del goteo de la fila fa (2 px: tubo y brillo), de su primera llave a la pared derecha; la de la primera fila entra
# por la pared (pasamuros) y las demás bajan por la pared desde la de detrás
func _ramal(lg: Array, fa: int, al: float) -> void:
	var i := -1
	for j in lg.size():
		if lg[j].fila == fa:
			i = j
			break
	if i < 0:
		return
	var f: Dictionary = lg[i]
	var osc := Color(Color.html("#1c1d22"), al)
	_rect(f.x, f.y - 1, f.xw - f.x + 1, 1, Color(Color.html("#4a4c54"), al))
	_rect(f.x, f.y, f.xw - f.x + 1, 1, osc)
	if i:
		var a: Dictionary = lg[i - 1]
		var n := maxi(absi(f.xw - a.xw), f.y - a.y)
		for k in (n + 1 if n > 0 else 0):
			_rect(a.xw + Datos.jsround(float(f.xw - a.xw) * k / n), a.y + Datos.jsround(float(f.y - a.y) * k / n), 1, 1, osc)
	elif Datos.carga().CARPAS.get(g.c.t, {}).get("depi"):   # el depósito a la izquierda (KAIA, kc_def): entra por la pared izquierda
		_rect(f.xl, f.y - 1, f.x - f.xl, 1, Color(Color.html("#4a4c54"), al))
		_rect(f.xl, f.y, f.x - f.xl, 1, osc)
		_rect(f.xl - 1, f.y - 2, 3, 4, Color(Color.html("#3a3c44"), al))
		_rect(f.xl, f.y - 1, 1, 2, osc)
	else:
		_rect(f.xw - 1, f.y - 2, 3, 4, Color(Color.html("#3a3c44"), al))
		_rect(f.xw, f.y - 1, 1, 2, osc)

# como fillRect del canvas: un ancho o un alto negativo pinta hacia la izquierda o hacia arriba
func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	if w < 0:
		x += w
		w = -w
	if h < 0:
		y += h
		h = -h
	if w > 0 and h > 0:
		base.draw_rect(Rect2(x, y, w, h), c)

func _planta(q: Dictionary, al: float) -> void:
	var v: Dictionary = q.v
	var mod := Color(1, 1, 1, al)
	var osc := Color(Color.html("#1c1d22"), al)
	var p = S.pots[q.i]
	var D := Datos.carga()
	var ca: Dictionary = S.carpas[Cultivo.huecos(S)[q.i].c]
	var mi := Arte.foto(v.m.n)
	var mx1: int = Arte.caja(mi)[1]
	var rim: int = q.y - 31 + (mi.get_height() - Arte.alto(mi))
	# su garrafa (sin goteo), detrás de la maceta a la derecha, con el agua que le queda; el tubo del gotero va del tapón a la tierra
	var gar := Cultivo.garrafa_l(S, q.i) if ca.get("garrafas") and not ca.get("goteo") else 0
	var gs = garrafa_sp(S, q)
	var gc: int = q.x - 16 + mx1 - 1
	var gb: int = q.y - 3
	# su sombra en el suelo (1.10 P5): del ancho de la maceta, debajo de su base
	var mx0: int = Arte.caja(mi)[0]
	var som := Color(0, 0, 0, 56 / 255.0 * al)
	_rect(q.x - 16 + mx0 - 1, q.y - 1, mx1 - mx0 + 3, 2, som)
	_rect(q.x - 16 + mx0 + 1, q.y + 1, mx1 - mx0 - 1, 1, som)
	if gs:
		var gi := Arte.nivel(Arte.foto(gs.n), D.VC_AGUA.garrafa, Cultivo.garrafa(S, q.i) / gar)
		base.draw_texture(Arte.tex("img|%d" % gi.get_instance_id(), gi), Vector2(gc - 24, gb - 47), mod)
	# con goteo, su microtubo sube de la manguera por la derecha de la maceta, con su llave, y entra por el borde hasta la tierra
	var got: bool = ca.get("goteo", false) and q.has("yl")
	if got:
		_rect(q.bx, rim - 1, 1, q.yl - rim + 1, osc)
		base.draw_texture(Arte.tex("x|llave", Arte.foto("extra-c-llave")), Vector2(q.bx - 24, q.yl + 1 - 47), mod)
	base.draw_texture(Arte.tex("m|" + v.m.n, mi), Vector2(q.x - 16, q.y - 31), mod)
	if got:
		_rect(q.x + 3, rim - 1, q.bx - q.x - 3, 1, osc)
		_rect(q.x + 3, rim, 1, 2, osc)
	if gs:
		var gf := Arte.foto(gs.n)
		var cx: int = gc - 24 + int(Arte.caja(gf)[0]) + 2
		var cy: int = gb - Arte.alto(gf) - 1
		var ty: int = mini(cy, rim) - 2
		_rect(q.x + 3, ty, cx - q.x - 2, 1, osc)
		_rect(cx, ty, 1, cy - ty, osc)
		_rect(q.x + 3, ty, 1, rim + 2 - ty, osc)
	if p == null or v.p == null:
		return
	var t := tex_planta(S, q)
	if v.muerta:   # seca: los verdes de hoja y tallo a marrones, quieta
		base.draw_texture(t, Vector2(q.x - (t.get_width() >> 1), q.y - v.tierra - t.get_height() + 1), mod)
		return
	var yb: int = q.y - v.tierra
	var b := t.get_height() - 1
	# se mece; con el ventilador encendido, el doble de deprisa
	_balanceo(t, q.x - (t.get_width() >> 1), yb - b, b, 1 if p.water > 0 else 0, now * (2 if ca.get("vent") else 1) + q.x * 37, mod)
	if p.pest:
		for n in 6:
			base.draw_rect(Rect2(q.x - 8 + ((n * 5 + int(floor(now / 300))) % 16), yb - 12 - ((n * 7) % 20), 1, 1), Color(Color.html("#e02828"), al))

# pinta la textura por franjas de 2 filas desplazadas con un seno: la base (fila b) quieta y la copa hasta ±a px
func _balanceo(t: Texture2D, x: int, y: int, b: int, a: int, tt: float, mod: Color) -> void:
	if not a:
		base.draw_texture(t, Vector2(x, y), mod)
		return
	var s := sin(tt / 950) * .7 + sin(tt / 410) * .3
	for r in range(0, t.get_height(), 2):
		var dx := Datos.jsround(a * s * pow(maxf(0, float(b - r) / b), 1.5))
		base.draw_texture_rect_region(t, Rect2(x + dx, y + r, t.get_width(), 2), Rect2(0, r, t.get_width(), 2), mod)

# lo de _balanceo que cae dentro de z (en px de la escena)
func _trozo(t: Texture2D, x: int, y: int, b: int, a: int, tt: float, mod: Color, z: Rect2i) -> void:
	var s := sin(tt / 950) * .7 + sin(tt / 410) * .3
	for r in range(0, t.get_height(), 2):
		var dx := Datos.jsround(a * s * pow(maxf(0, float(b - r) / b), 1.5)) if a and b > 0 else 0
		var f := Rect2i(x + dx, y + r, t.get_width(), mini(2, t.get_height() - r)).intersection(z)
		if f.has_area():
			base.draw_texture_rect_region(t, Rect2(f), Rect2(f.position - Vector2i(x + dx, y), f.size), mod)

# la tierra y el pie del tallo de q otra vez, encima de lo que las pisa (a_la_vista): la maceta, el microtubo que entra en la tierra y la
# planta (en la tierra, toda; por encima del borde, solo el tallo), al A_VISTA
func _a_la_vista(q: Dictionary) -> void:
	var v: Dictionary = q.v
	var mod := Color(1, 1, 1, A_VISTA)
	var zt := zona_tierra(q)
	var o := Vector2i(q.x - 16, q.y - 31)
	base.draw_texture_rect_region(Arte.tex("m|" + v.m.n, Arte.foto(v.m.n)), Rect2(zt), Rect2(zt.position - o, zt.size), mod)
	var ca: Dictionary = S.carpas[Cultivo.huecos(S)[q.i].c]
	if ca.get("goteo", false) and q.has("yl") or garrafa_sp(S, q):
		_rect(q.x + 3, zt.position.y, 1, 2, Color(Color.html("#1c1d22"), A_VISTA))
	var t := tex_planta(S, q)
	if t == null:
		return
	var zs := zona_tallo(S, q)
	var arriba := Rect2i(zs.position, Vector2i(zs.size.x, maxi(0, zt.position.y - zs.position.y)))
	var p: Dictionary = S.pots[q.i]
	var yb: int = q.y - v.tierra
	var b := t.get_height() - 1
	var a := 0 if v.muerta or p.water <= 0 else 1
	var tt: float = now * (2 if ca.get("vent") else 1) + q.x * 37
	for z in [zt, arriba]:
		_trozo(t, q.x - (t.get_width() >> 1), yb - b, b, a, tt, mod, z)

func _pinta_encima() -> void:
	if g.is_empty() or g.vc == null:
		return
	var D := Datos.carga()
	var on := Cultivo.foco_on(S, VC.ci)
	var fc := Arte.foto(g.vc.foco.n)
	var im := fc if on else Arte.apagado(fc)
	# apagado (con CAL), la campana, sus poleas y el depósito, a oscuras con la luz verde de trabajo, como lo demás (lo dijo el usuario:
	# «el foco se tendría que ver a oscuras»): se pintan encima de la capa de la luz y no les llegaba
	var V := Arte.VERDE_C
	var tn := Color(V.x, V.y, V.z) if Datos.CAL and not on else Color.WHITE
	# la campana, con la boca en fy; bajada, cuelga de dos poleas del techo (poleas) y luego se pinta ella
	var fy: int = g.vc.fy
	for cx in g.vc.get("fxs", [120]):
		var fx: int = int(cx) - (fc.get_width() >> 1)
		if fy > int(D.VCA.boca):
			for e in poleas(fc, fy, int(cx)):
				encima.draw_rect(Rect2(e[0], e[1], e[2], e[3]), e[4] * tn)
		encima.draw_texture(Arte.tex("foco|%s|%s" % [g.vc.foco.n, on], im), Vector2(fx, fy - 15), tn)
	# el depósito del goteo está fuera: arriba a la derecha, en pequeño, con el agua que le queda en la mirilla (el de KAIA, en el suelo
	# al lado de la carpa: la tela no deja verlo; solo entra su manguera, _ramal)
	if g.vc.lg != null and not g.C.get("kc"):
		var l := Cultivo.goteo_l(S, VC.ci)
		var dep = g.c.get("dep")
		var di := Arte.nivel(Arte.foto("extra-c-deposito"), D.VC_AGUA.deposito, (float(dep) if dep != null else float(l)) / l)
		var dx: int = g.vc.xl + g.vc.w + 22 - 24
		var dy := 8 - 28
		encima.draw_texture(Arte.tex("img|%d" % di.get_instance_id(), di), Vector2(dx, dy), tn)
	var bs := barras(S, g, VC.sel)
	var fsel := fila_sel(g, VC.sel)
	for b in bs:
		_barra(b, A35 if b.fila < fsel else 1.0)
	_cursor(bs)

# agua: azul, y por debajo de 30 (toca regar) parpadea en rojo; cosecha: verde hasta que está lista, y entonces dorada y
# parpadeando; con plaga, la «!» roja al lado. Rectángulos que no se pisan: con transparencia (al) no se suman
# U5 (fase 5, OPCIONES con Datos.PLAY): DALTONICO pone iconos además del color (la gota con sed y la marca de lista, a los
# lados de la barra); CALMA (SIN DESTELLOS) quita el parpadeo: el rojo de la sed y el dorado de lista, fijos
static var DALTONICO := false
static var CALMA := false

static func pinta_barra(L: CanvasItem, b: Dictionary, al: float, now: float) -> void:
	var r: Rect2i = b.r
	var p: Dictionary = b.p
	var x := r.position.x
	var y := r.position.y
	var tic := int(floor(now / 400)) % 2 == 1 and not CALMA
	var R := func(rx: int, ry: int, w: int, h: int, c: Color) -> void:
		if w > 0 and h > 0:
			L.draw_rect(Rect2(rx, ry, w, h), Color(c, al))
	var n := BW - 2
	for f in [y, y + 3, y + 6]:
		R.call(x + 1, f, n, 1, OSC)
	R.call(x, y + 1, 1, BH - 2, OSC)
	R.call(x + BW - 1, y + 1, 1, BH - 2, OSC)
	var sed: bool = p.water < 30 and (tic or CALMA)
	var na := ceili(clampf(p.water, 0, 100) * n / 100.0)
	R.call(x + 1, y + 1, na, 1, Color8(0xf0, 0x80, 0x78) if sed else Color8(0x76, 0xb4, 0xf2))
	R.call(x + 1, y + 2, na, 1, Color8(0xe0, 0x40, 0x40) if sed else Color8(0x4a, 0x92, 0xe0))
	R.call(x + 1 + na, y + 1, n - na, 2, Color8(0x7a, 0x2a, 0x30) if sed else VACIO)
	var lista: bool = p.prog >= 1
	var nc := n if lista else floori(clampf(p.prog, 0, 1) * n)
	R.call(x + 1, y + 4, nc, 1, (Color8(0xff, 0xf4, 0xb0) if tic else Color8(0xf8, 0xd8, 0x60)) if lista else Color8(0xb0, 0xe4, 0x8c))
	R.call(x + 1, y + 5, nc, 1, (Color8(0xf8, 0xd8, 0x60) if tic else Color8(0xd8, 0xa0, 0x30)) if lista else Color8(0x62, 0xaa, 0x56))
	R.call(x + 1 + nc, y + 4, n - nc, 2, VACIO)
	if p.pest:
		var px := x + BW
		var rojo := Color8(0xa0, 0x20, 0x20) if tic else Color8(0xe0, 0x40, 0x40)
		var bla := Color8(0xf8, 0xf8, 0xf0)
		R.call(px, y, BP, 1, OSC)
		R.call(px, y + BH - 1, BP, 1, OSC)
		R.call(px, y + 1, 1, BH - 2, OSC)
		R.call(px + BP - 1, y + 1, 1, BH - 2, OSC)
		R.call(px + 1, y + 1, 1, BH - 2, rojo)
		R.call(px + BP - 2, y + 1, 1, BH - 2, rojo)
		R.call(px + 2, y + 4, 2, 1, rojo)
		R.call(px + 2, y + 1, 2, 3, bla)
		R.call(px + 2, y + 5, 2, 1, bla)
	if DALTONICO:
		var W := Color8(0xf8, 0xf8, 0xf0)
		if p.water < 30:   # la gota, a la izquierda
			R.call(x - 5, y, 5, 6, OSC)
			R.call(x - 3, y + 1, 1, 1, W)
			R.call(x - 4, y + 2, 3, 2, W)
			R.call(x - 3, y + 4, 1, 1, W)
		if lista:   # la marca de lista, a la derecha (después de la «!»)
			var cx: int = x + BW + (BP if p.pest else 0)
			R.call(cx, y + 1, 6, 5, OSC)
			R.call(cx + 1, y + 3, 1, 1, W)
			R.call(cx + 2, y + 4, 1, 1, W)
			R.call(cx + 3, y + 3, 1, 1, W)
			R.call(cx + 4, y + 2, 1, 1, W)

static func pinta_cursor(L: CanvasItem, g: Dictionary, VC: Dictionary, bs: Array, now: float) -> void:
	var b := int(floor(now / 300)) % 2
	var osc := Color.html("#26262e")
	var cla := Color.html("#f8f8f0")
	if VC.sel < 0:
		var x: int = g.tx - 8 if VC.sel == SEL_TEMP else g.fx - (int(g.fw) >> 1) - 8
		var y: int = g.ty + 6 if VC.sel == SEL_TEMP else g.fy - 5
		L.draw_rect(Rect2(x - 1, y - 4, 6, 9), osc)
		for k in 4:
			L.draw_rect(Rect2(x + b + k, y - 3 + k, 1, 7 - 2 * k), cla)
		return
	for q in g.pl:
		if q.i == VC.sel:
			L.draw_rect(Rect2(q.x - 7, q.y, 14, 2), Color(1, 1, 240 / 255.0, A35))
	var c := pos_cursor(g, VC.sel, bs)
	if c == Vector2i(-1, -1):
		return
	var x := c.x
	var y := c.y + b
	L.draw_rect(Rect2(x - 4, y - 1, 9, 6), osc)
	for k in 4:
		L.draw_rect(Rect2(x - 3 + k, y + k, 7 - 2 * k, 1), cla)

func _barra(b: Dictionary, al: float) -> void:
	pinta_barra(encima, b, al, now)

func _cursor(bs: Array) -> void:
	pinta_cursor(encima, g, VC, bs, now)
