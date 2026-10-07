# Ribera Verde (Godot) — la vista C de 09b-carpa.js: la carpa por dentro a pantalla completa (imagen A).
# geo(S, ci) es vcGeo + vistaC: dónde va cada maceta y qué planta, a qué alto. pinta(S, VC, now) dibuja como renderCarpaC:
# fondo negro, pared, macetas y plantas (las de delante de la fila elegida en transparencia), la luz del foco en «overlay»
# (shader sobre lo ya pintado), la campana y el cursor. Todo en px del juego: el nodo va en un SubViewport de 160 de alto.
# Solo en el port (extras): encima de cada planta, su barra de agua y de cosecha con el aviso de plaga, y los daños de la
# plaga pintados sobre sus hojas; C2 los apaga para comparar con el HTML.
extends Node2D

const Datos = preload("res://src/datos.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Arte = preload("res://src/arte.gd")

# el canvas guarda el alfa global en 8 bits: .35 → 89/255
const A35 := 89 / 255.0
# barra de cada planta: marco, agua (2 filas), raya, cosecha (2 filas), marco; con plaga, la «!» al lado
const BW := 16
const BH := 7
const BP := 6
const OSC := Color8(0x26, 0x26, 0x2e)
const VACIO := Color8(0x4a, 0x4a, 0x56)

static var extras := true

const OVERLAY := """
shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, filter_nearest;
uniform float fuerza = 1.0;
void fragment() {
	vec4 s = texture(TEXTURE, UV);
	vec3 b = texture(pantalla, SCREEN_UV).rgb;
	vec3 m = 2.0 * b * s.rgb;
	vec3 n = 1.0 - 2.0 * (1.0 - b) * (1.0 - s.rgb);
	vec3 o = mix(m, n, step(vec3(0.5000001), b));
	COLOR = vec4(mix(b, o, s.a * fuerza), 1.0);
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

func _init() -> void:
	for n in [base, luz, encima]:
		add_child(n)
	luz.centered = false
	var sh := Shader.new()
	sh.code = OVERLAY
	luz.material = ShaderMaterial.new()
	luz.material.shader = sh
	base.draw.connect(_pinta_base)
	encima.draw.connect(_pinta_encima)

# ---------- geometría ----------
static func vc_sprite(pre: String, px: float):
	var m = null
	for a in Arte.anchos(pre):
		if absf(a - px) <= px * .25 and (m == null or absf(a - px) < absf(m.a - px)):
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

# muertas: el HTML pasa a la vista B (procedural, fuera del corte); aquí la plaza se pinta sin planta (solo la maceta)
static func geo(S: Dictionary, ci: int):
	var D := Datos.carga()
	var c: Dictionary = S.carpas[ci]
	var C: Dictionary = D.CARPAS[c.t]
	var W: float = C.cm[0]
	var H: float = C.cm[1]
	var Dp: float = C.cm[2]
	var cols := int(C.cols)
	var pl := []
	var hu := Cultivo.huecos(S)
	for i in hu.size():
		var q: Dictionary = hu[i]
		if q.c != ci:
			continue
		var col: int = q.j % cols
		var fila: int = q.j / cols
		var n := mini(cols, int(C.plazas) - fila * cols)
		pl.append({"i": i, "col": col, "fila": fila, "cx": (col + .5) * W / n, "cy": (fila + .5) * Dp / C.filas})
	for a in pl:
		var d := 2 * minf(minf(a.cx, W - a.cx), minf(a.cy, Dp - a.cy))
		for b in pl:
			if b != a:
				d = minf(d, sqrt((a.cx - b.cx) * (a.cx - b.cx) + (a.cy - b.cy) * (a.cy - b.cy)))
		a.cw = d - D.HOLGURA
		a.ch = H - 28 - D.FOCO_SEP.get(c.foco, 40) - D.MACETA_CM.get(S.macetas[a.i], D.MACETA_CM.plastico7)[1]
	var o := {"c": c, "C": C, "W": W, "H": H, "D": Dp, "pl": pl}
	o.vc = vista_c(S, o)
	if o.vc:
		o.fx = 120
		o.fy = int(D.VCA.boca)
		o.fw = o.vc.foco.a
	return o

static func vista_c(S: Dictionary, g: Dictionary):
	var D := Datos.carga()
	var c: Dictionary = g.c
	var W: float = g.W
	var tipo: String = D.FOCOS[c.foco].tipo
	for k in D.EXTRAS:
		if c.get(k):
			return null
	var VCA: Dictionary = D.VCA
	var Z: float = (VCA.base - VCA.boca) / (g.H - 28)
	var w := Datos.jsround(W * Z)
	var foco = vc_sprite("foco-c-" if tipo == "sodio" else "foco-c-" + tipo + "-", D.FOCO_CM.get(c.foco, 45) * Z)
	if not Arte.hay("carpa-c-pared") or not Arte.hay("carpa-c-luz") or foco == null:
		return null
	var filas: Array = D.VC_FILA[int(g.C.filas) - 1]
	var wy := func(y: float) -> float: return w + 32 * (y - VCA.fondo) / 19
	var yq := func(q: Dictionary) -> int: return int(filas[mini(q.fila, filas.size() - 1)])
	var xy := func(q: Dictionary, y: float) -> int: return Datos.jsround(120 + (q.cx / W - .5) * wy.call(y))
	var v := []
	for q in g.pl:
		var k: String = S.macetas[q.i]
		var m = vc_sprite("maceta-c-", D.MACETA_CM[k][0] * Z) if k == "plastico7" else null
		if m == null:
			return null
		var y: int = yq.call(q)
		var x: int = xy.call(q, y)
		var r := {"x": x, "y": y, "m": m, "tierra": D.VC_TIERRA.get(m.n, Datos.jsround(Arte.foto(m.n).get_height() * .7)), "hp": 0, "p": null}
		var p = S.pots[q.i]
		if p and not p.get("dead"):
			var st := Cultivo.plant_stage(p)
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
			r.hp = mini(Arte.alto(Arte.foto(s.n)), mini(Datos.jsround(minf(Dh[st], q.ch) * Z), int(floor(y - r.tierra - VCA.boca - D.FOCO_SEP[c.foco] * Z))))
		v.append(r)
	for j in g.pl.size():
		var q: Dictionary = g.pl[j]
		q.v = v[j]
		q.x = v[j].x
		q.y = v[j].y
		q.alto = v[j].tierra + 4 + v[j].hp
	return {"Z": Z, "w": w, "xl": 120 - (w >> 1), "foco": foco, "tipo": tipo}

# ---------- dibujo ----------
# de atrás adelante: fila (y), luego x y plaza
static func orden(g_: Dictionary) -> Array:
	var o: Array = g_.pl.duplicate()
	o.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and (a.x < b.x or (a.x == b.x and a.i < b.i))))
	return o

static func clave_planta(S_: Dictionary, p: Dictionary, v: Dictionary) -> String:
	var k := "pl|%s|%d|%s|%s|%s" % [v.p.n, v.hp, Datos.strain(S_, p.sid).c, Datos.hoja_planta(S_, p), p.water <= 0]
	var n := nivel_dano(p)
	return k + ("|d%d|%d" % [n, semilla(p)] if n else "")

# daños de la plaga según la salud que le queda (solo en el port); tratada, ninguno
static func nivel_dano(p: Dictionary) -> int:
	if not extras or not p.pest or p.get("dead"):
		return 0
	return 1 if p.health >= 75 else (2 if p.health >= 45 else 3)

# cada planta, sus manchas: del id de su fenotipo (los esquejes, las de su madre)
static func semilla(p: Dictionary) -> int:
	var f = p.get("f")
	return int(f.id) if f is Dictionary and f.get("id") else hash(p.sid)

# la planta tal como se pinta: el fotograma de su alto (sin las filas de más), con los colores de su variedad y seca sin agua
static func img_planta(S_: Dictionary, p: Dictionary, v: Dictionary) -> Image:
	var s = Datos.strain(S_, p.sid)
	var c0 := Arte.aplasta(Arte.altura(v.p.n, v.hp)[1], v.hp)
	var mapa := {Arte.rampa[0]: Datos.shade(s.c, 50), Arte.rampa[1]: s.c, Arte.rampa[2]: Datos.shade(s.c, -60)}
	mapa.merge(Datos.vc_tonos(Datos.hoja_planta(S_, p)), true)
	var im := Arte.recolor(c0, mapa)
	var n := nivel_dano(p)
	if n:
		im = Arte.dano(im, c0, n, semilla(p) ^ hash(v.p.n))
	if p.water <= 0:
		im = Arte.seca(im)
	return im

# las barras, de delante atrás: cada una encima de su planta (2 filas de aire) y, si pisa otra, encima de esa. La de la
# plaza elegida deja sitio encima para el cursor (CUR filas)
const CUR := 7
static func barras(S_: Dictionary, g_: Dictionary, sel := -1) -> Array:
	var o := []
	if not extras or g_.is_empty() or g_.vc == null:
		return o
	var pl: Array = g_.pl.duplicate()
	pl.sort_custom(func(a, b): return a.y > b.y or (a.y == b.y and (a.x < b.x or (a.x == b.x and a.i < b.i))))
	for q in pl:
		var p = S_.pots[q.i]
		if p == null or p.get("dead") or q.v.p == null:
			continue
		var r := Rect2i(q.x - (BW >> 1), q.y - q.alto + 3 - BH, BW + (BP if p.pest else 0), BH)
		var cur := CUR if q.i == sel else 0
		var mueve := true
		while mueve:
			mueve = false
			for b in o:
				if b.caja.grow(1).intersects(r.grow_individual(0, cur, 0, 0)):
					r.position.y = b.caja.position.y - BH - 1
					mueve = true
		o.append({"i": q.i, "r": r, "p": p, "caja": r.grow_individual(0, cur, 0, 0)})
	return o

func pinta(S_: Dictionary, VC_: Dictionary, now_: float, ancho := 240) -> void:
	S = S_
	VC = VC_
	now = now_
	sw = ancho
	g = geo(S, VC.ci)
	var ox := (sw - 240) >> 1
	for n in [base, luz, encima]:
		n.position = Vector2(ox, 0)
	var on := Cultivo.plantas_vivas(S, VC.ci)
	luz.visible = on and g.vc != null
	if luz.visible:
		luz.texture = Arte.tex("luz|%s|%s" % [g.c.t, g.vc.tipo], Arte.luz(g.c.t, g.vc))
		luz.material.set_shader_parameter("fuerza", Datos.carga().LUZ_C.get(g.vc.tipo, [0, 1])[1])
	base.queue_redraw()
	encima.queue_redraw()

func _pinta_base() -> void:
	var ox := (sw - 240) >> 1
	base.draw_rect(Rect2(-ox, 0, sw, 160), Color.BLACK)
	if g.is_empty() or g.vc == null:
		return
	base.draw_texture(Arte.tex("pared|" + g.c.t, Arte.fondo(g.c.t, g.vc, "pared")), Vector2.ZERO)
	var fsel := 0
	for q in g.pl:
		if q.i == VC.sel:
			fsel = q.fila
	for q in orden(g):
		_planta(q, A35 if q.fila < fsel else 1.0)

func _planta(q: Dictionary, al: float) -> void:
	var v: Dictionary = q.v
	var mod := Color(1, 1, 1, al)
	base.draw_texture(Arte.tex("m|" + v.m.n, Arte.foto(v.m.n)), Vector2(q.x - 16, q.y - 31), mod)
	var p = S.pots[q.i]
	if p == null or v.p == null:
		return
	var k := clave_planta(S, p, v)
	var t: ImageTexture = Arte.texs.get(k)
	if t == null:
		t = Arte.tex(k, img_planta(S, p, v))
	var yb: int = q.y - v.tierra
	var b := t.get_height() - 1
	_balanceo(t, q.x - (t.get_width() >> 1), yb - b, b, 1 if p.water > 0 else 0, now + q.x * 37, mod)
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

func _pinta_encima() -> void:
	if g.is_empty() or g.vc == null:
		return
	var D := Datos.carga()
	var on := Cultivo.plantas_vivas(S, VC.ci)
	var fc := Arte.foto(g.vc.foco.n)
	var im := fc if on else Arte.apagado(fc)
	encima.draw_texture(Arte.tex("foco|%s|%s" % [g.vc.foco.n, on], im), Vector2(120 - 24, int(D.VCA.boca) - 15))
	var bs := barras(S, g, VC.sel)
	for b in bs:
		_barra(b)
	_cursor(bs)

# agua: azul, y por debajo de 30 (toca regar) parpadea en rojo; cosecha: verde hasta que está lista, y entonces dorada y
# parpadeando; con plaga, la «!» roja al lado
func _barra(b: Dictionary) -> void:
	var r: Rect2i = b.r
	var p: Dictionary = b.p
	var x := r.position.x
	var y := r.position.y
	var tic := int(floor(now / 400)) % 2 == 1
	encima.draw_rect(Rect2(x + 1, y, BW - 2, BH), OSC)
	encima.draw_rect(Rect2(x, y + 1, BW, BH - 2), OSC)
	var sed: bool = p.water < 30
	var na := ceili(clampf(p.water, 0, 100) * (BW - 2) / 100.0)
	encima.draw_rect(Rect2(x + 1, y + 1, BW - 2, 2), Color8(0x7a, 0x2a, 0x30) if sed and tic else VACIO)
	if na:
		encima.draw_rect(Rect2(x + 1, y + 1, na, 1), Color8(0xf0, 0x80, 0x78) if sed and tic else Color8(0x76, 0xb4, 0xf2))
		encima.draw_rect(Rect2(x + 1, y + 2, na, 1), Color8(0xe0, 0x40, 0x40) if sed and tic else Color8(0x4a, 0x92, 0xe0))
	var lista: bool = p.prog >= 1
	var nc := (BW - 2) if lista else floori(clampf(p.prog, 0, 1) * (BW - 2))
	encima.draw_rect(Rect2(x + 1, y + 4, BW - 2, 2), VACIO)
	if nc:
		encima.draw_rect(Rect2(x + 1, y + 4, nc, 1), (Color8(0xff, 0xf4, 0xb0) if tic else Color8(0xf8, 0xd8, 0x60)) if lista else Color8(0xb0, 0xe4, 0x8c))
		encima.draw_rect(Rect2(x + 1, y + 5, nc, 1), (Color8(0xf8, 0xd8, 0x60) if tic else Color8(0xd8, 0xa0, 0x30)) if lista else Color8(0x62, 0xaa, 0x56))
	if p.pest:
		var px := x + BW
		encima.draw_rect(Rect2(px, y, BP, BH), OSC)
		encima.draw_rect(Rect2(px + 1, y + 1, BP - 2, BH - 2), Color8(0xa0, 0x20, 0x20) if tic else Color8(0xe0, 0x40, 0x40))
		encima.draw_rect(Rect2(px + 2, y + 1, 2, 3), Color8(0xf8, 0xf8, 0xf0))
		encima.draw_rect(Rect2(px + 2, y + 5, 2, 1), Color8(0xf8, 0xf8, 0xf0))

func _cursor(bs: Array) -> void:
	var b := int(floor(now / 300)) % 2
	var osc := Color.html("#26262e")
	var cla := Color.html("#f8f8f0")
	if VC.sel < 0:
		var x: int = g.fx - (int(g.fw) >> 1) - 8
		var y: int = g.fy - 5
		encima.draw_rect(Rect2(x - 1, y - 4, 6, 9), osc)
		for k in 4:
			encima.draw_rect(Rect2(x + b + k, y - 3 + k, 1, 7 - 2 * k), cla)
		return
	for q in g.pl:
		if q.i == VC.sel:
			encima.draw_rect(Rect2(q.x - 7, q.y, 14, 2), Color(1, 1, 240 / 255.0, A35))
			var x: int = q.x
			var y: int = q.y - (q.alto if q.alto else 12) - 9 + b
			for e in bs:
				if e.i == q.i:
					y = e.r.position.y - 6 + b   # encima de su barra, en el sitio que deja (CUR)
			encima.draw_rect(Rect2(x - 4, y - 1, 9, 6), osc)
			for k in 4:
				encima.draw_rect(Rect2(x - 3 + k, y + k, 7 - 2 * k, 1), cla)
