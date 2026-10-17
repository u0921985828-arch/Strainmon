# Ribera Verde (Godot) — 1.56: el viaje, como pantalla de carga (lo pidió el usuario: «en el autobús no hay animación como tampoco en
# los demás vehículos, como una pantalla de carga, pero que sea el vehículo andando recto desde una vista de perfil»). El autobús o tu
# vehículo del concesionario, de perfil, entra por la izquierda, rueda por la carretera mientras el monte, los caseríos y el guardarraíl
# pasan por detrás a distinta velocidad, y sale por la derecha. El cielo y la luz, por la hora; de noche, los faros. Arriba, de dónde a
# dónde y los minutos; abajo, la barra. Arte a mano en tools/sprites/a-mano/viaje.py (arte/viaje.png + viaje.json).
extends RefCounted

const Croquis = preload("res://src/croquis.gd")

const DUR := 3000.0      # ms: entra, rueda y sale
const ENTRA := 700.0
const SALE := 2300.0
const VEL := {"bus": 0.11, "moto": 0.16, "utilitario": 0.17, "berlina": 0.18, "deportivo": 0.26}   # px/ms del fondo cercano
const CAPAS := [["monte", 64, 0.12], ["medio", 92, 0.4], ["cerca", 132, 1.0]]   # pieza, y, parallax
const Y_CARRETERA := 142
const CARRIL := 27        # el suelo de las ruedas, desde arriba de la carretera

static var R := {}       # recortes: nombre → Image
static var META := {}

static func carga() -> bool:
	if R.size():
		return true
	var im := Image.new()
	if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://arte/viaje.png")) != OK:
		return false
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://arte/viaje.json"))
	if typeof(j) != TYPE_DICTIONARY:
		return false
	for k in j.r:
		var q: Array = j.r[k]
		R[k] = im.get_region(Rect2i(int(q[0]), int(q[1]), int(q[2]), int(q[3])))
	META = j.v
	return true

static func clave(veh: String) -> String:
	return veh if META.has(veh) else "bus"

# la luz por la hora: 0 día, 1 atardecer o amanecer, 2 noche
static func luz(mins: int) -> int:
	var h := (mins / 60) % 24
	if h >= 8 and h < 19:
		return 0
	if h == 7 or h == 19 or h == 20:
		return 1
	return 2

const CIELO := [["#7ec0ee", "#d4ecf8"], ["#5a4a8a", "#f0a868"], ["#0c1228", "#26345e"]]
const TINTE := [Color(1, 1, 1), Color(1.0, 0.82, 0.72), Color(0.42, 0.48, 0.72)]

# la posición del vehículo (x en pantalla) y lo andado por el fondo, a los e ms
static func pos(e: float, sw: int, w: int, vel: float) -> Vector2:
	var cx := (sw - w) * 0.5
	var x: float
	if e < ENTRA:
		var t := e / ENTRA
		x = lerpf(-w - 4.0, cx, 1.0 - (1.0 - t) * (1.0 - t))
	elif e < SALE:
		x = cx
	else:
		var t := minf(1.0, (e - SALE) / (DUR - SALE))
		x = lerpf(cx, sw + 4.0, t * t)
	return Vector2(x, e * vel)

static func pinta(P, V: Dictionary, now: float) -> void:
	if not carga():
		return
	var sw: int = P.J.SW
	var sh: int = P.SH
	var e := clampf(now - float(V.t0), 0.0, DUR)
	var lz := luz(int(V.get("h", 720)))
	var tin: Color = TINTE[lz]
	# el cielo, en bandas
	var c0 := Color(CIELO[lz][0])
	var c1 := Color(CIELO[lz][1])
	for i in 12:
		P._rect(0, i * 10, sw, 10, c0.lerp(c1, i / 11.0))
	if lz == 2:   # estrellas fijas y la luna
		for i in 40:
			var hs := (i * 2654435761 + 977) & 0xffffff
			var sx := hs % sw
			var sy := 4 + (hs >> 9) % 58
			P._rect(sx, sy, 1, 1, Color("#e8ecff") if i % 3 else Color("#9aa4d0"))
		P._rect(sw - 46, 14, 10, 10, Color("#f0ecd0"))
		P._rect(sw - 47, 16, 12, 6, Color("#f0ecd0"))
		P._rect(sw - 44, 13, 6, 12, Color("#f0ecd0"))
		P._rect(sw - 42, 15, 3, 3, Color("#d8d2b0"))
	elif lz == 0:   # el sol, arriba a la derecha
		P._rect(sw - 44, 12, 12, 12, Color("#fff4c0"))
		P._rect(sw - 46, 15, 16, 6, Color("#fff4c0"))
	var k := clave(String(V.veh))
	var m: Dictionary = META[k]
	var cuerpo: Image = R[k]
	var w := cuerpo.get_width()
	var vel: float = VEL.get(k, 0.15)
	var p := pos(e, sw, w, vel)
	var corre := p.y
	# las capas de fondo, repetidas
	for c in CAPAS:
		var im: Image = R[c[0]]
		var cw := im.get_width()
		var dx := -int(fposmod(corre * float(c[2]), cw))
		var x := dx
		while x < sw:
			P._img(im, x, int(c[1]), tin)
			x += cw
	# la carretera
	var ca: Image = R.carretera
	var x2 := -int(fposmod(corre, ca.get_width()))
	while x2 < sw:
		P._img(ca, x2, Y_CARRETERA, tin)
		x2 += ca.get_width()
	P._rect(0, Y_CARRETERA + ca.get_height(), sw, sh, Color("#3a4a30") * tin)
	# el vehículo: de noche, el haz de los faros delante
	var suelo := Y_CARRETERA + CARRIL
	var bote := 1 if int(e / 90.0) % 4 == 0 and e > 60.0 else 0
	var vx := int(p.x)
	var vy := suelo - int(m.suelo) - bote
	if lz > 0:
		var fx := vx + int(m.faro[0]) + 1
		var fy := vy + int(m.faro[1])
		for i in 5:
			P._rect(fx + i * 8, fy - i - 1, 8, 3 + i * 2, Color(1.0, 0.94, 0.6, 0.30 - i * 0.05))
	P._rect(vx + 3, suelo - 1, w - 6, 2, Color(0, 0, 0, 0.35))   # la sombra
	var tv: Color = Color(1, 1, 1) if lz == 0 else tin.lerp(Color(1, 1, 1), 0.45)
	P._img(cuerpo, vx, vy, tv)
	var anda := corre + (p.x - (sw - w) * 0.5)   # lo que gira la rueda: lo andado más lo que se mueve en pantalla
	for r in m.ruedas:
		var d := int(r[2])
		var f := int(floor(anda / (PI * d) * 4.0)) % 4
		P._img(R["rueda-%d-%d" % [d, posmod(f, 4)]], vx + int(r[0]) - d / 2, vy + bote + int(r[1]) - d / 2, tv)
	if lz > 0:
		P._rect(vx + int(m.faro[0]), vy + int(m.faro[1]), 2, 2, Color("#fff6c0"))
	# arriba, el trayecto y los minutos; abajo, la barra
	var t1: String = "%s - %s" % [String(V.de), String(V.a)]
	_texto(P, (sw - Croquis.ancho(t1) * 2) / 2, 30, t1, 2)
	var t2: String = "%d MIN" % int(V.min)
	_texto(P, (sw - Croquis.ancho(t2)) / 2, 44, t2, 1)
	var bw := sw - 40
	P._rect(20, sh - 6, bw, 3, Color(0, 0, 0, 0.5))
	P._rect(20, sh - 6, int(bw * e / DUR), 3, Color("#8bd448"))

static func _texto(P, x: int, y: int, t: String, s: int) -> void:
	for q in Croquis.letras(t):
		P._rect(x + q.x * s + 1, y + q.y * s + 1, s, s, Color("#1a1420"))
	for q in Croquis.letras(t):
		P._rect(x + q.x * s, y + q.y * s, s, s, Color("#f8f4e8"))
