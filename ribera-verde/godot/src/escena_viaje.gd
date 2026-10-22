# Ribera Verde (Godot) — 1.56: el viaje, como pantalla de carga (lo pidió el usuario: «en el autobús no hay animación como tampoco en
# los demás vehículos, como una pantalla de carga, pero que sea el vehículo andando recto desde una vista de perfil»). El autobús o tu
# vehículo del concesionario, de perfil, entra por la izquierda, rueda por la carretera mientras el monte, los caseríos y el guardarraíl
# pasan por detrás a distinta velocidad, y sale por la derecha. El cielo y la luz, por la hora; de noche, los faros. Arriba, de dónde a
# dónde y los minutos; abajo, la barra. Arte a mano en tools/sprites/a-mano/viaje.py (arte/viaje.png + viaje.json).
extends RefCounted

const Croquis = preload("res://src/croquis.gd")
const Atlas = preload("res://src/atlas.gd")
const Datos = preload("res://src/datos.gd")
const I18n = preload("res://src/i18n.gd")

const DUR := 3000.0      # ms: entra, rueda y sale
const ENTRA := 700.0
const SALE := 2300.0
const VEL := {"bus": 0.11, "moto": 0.16, "utilitario": 0.17, "berlina": 0.18, "deportivo": 0.26}   # px/ms del fondo cercano
const CAPAS := [["monte", 64, 0.12], ["lejos", 48, 0.22], ["pueblo", 18, 0.4], ["cerca", 132, 1.0]]   # pieza, y, parallax (lejos y pueblo, por tipo: «lejos-rural»…)
# el pueblo de detrás, por el sitio al que vas (lo pidió el usuario: «que no todos los pueblos sean iguales»); las casas de lejos, a la
# mitad, más arriba y más despacio (de viaje.py); lo que no está, por el trayecto
const PUEBLOS := ["rural", "costa", "industria", "barrio", "ciudad"]
const PUEBLO_DE := {"town": "barrio", "puerto": "costa", "muelle": "costa", "valdehierro": "industria", "mendialde": "rural",
		"errotabarri": "rural", "ibarbide": "ciudad", "metropoli": "ciudad", "zorroza": "barrio"}
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
	var k := clave(String(V.veh))
	var m: Dictionary = META[k]
	var cuerpo: Image = R[k]
	var w := cuerpo.get_width()
	var vel: float = VEL.get(k, 0.15)
	var p := pos(e, sw, w, vel)
	var corre := p.y
	var tp := pueblo(V)
	_cielo(P, sw, lz, corre)
	_fondo(P, sw, sh, corre + float(tp[1]), tin, String(tp[0]))
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
	var t2: String = I18n.T("{n} MIN", {"n": int(V.min)})
	_texto(P, (sw - Croquis.ancho(t2)) / 2, 44, t2, 1)
	var bw := sw - 40
	P._rect(20, sh - 6, bw, 3, Color(0, 0, 0, 0.5))
	P._rect(20, sh - 6, int(bw * e / DUR), 3, Color("#8bd448"))

# el cielo (lo pidió el usuario: «el fondo del cielo» al estilo de los muebles): el degradado en tonos tramados con Bayer 4 × 4,
# cacheado por ancho y luz; las nubes, el sol y la luna de PixelLab (tools/sprites/pixellab-viaje); las nubes van a la deriva por
# lo andado (corre), lentas
const CIELO_TONOS := 6
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const NUBES := [["nube-3", 10, 8, 0.05], ["nube-1", 150, 30, 0.08], ["nube-2", 300, 14, 0.06], ["nube-0", 420, 40, 0.1], ["nube-1", 560, 22, 0.07]]
const NUBE_TINTE := [Color(1, 1, 1), Color(1.0, 0.78, 0.74), Color(0.36, 0.40, 0.58)]
static var CIELO_IM := {}

static func cielo_img(sw: int, lz: int) -> Image:
	var key := "%d-%d" % [sw, lz]
	if not CIELO_IM.has(key):
		var c0 := Color(CIELO[lz][0])
		var c1 := Color(CIELO[lz][1])
		var tono := []
		for i in CIELO_TONOS:
			tono.append(c1 if i == CIELO_TONOS - 1 else c0.lerp(c1, i / float(CIELO_TONOS - 1)))
		var im := Image.create(sw, 120, false, Image.FORMAT_RGBA8)
		for y in 120:
			var t := y / 119.0 * (CIELO_TONOS - 1)
			for x in sw:
				im.set_pixel(x, y, tono[mini(CIELO_TONOS - 1, int(t + BAYER[(y % 4) * 4 + x % 4] / 16.0))])
		CIELO_IM[key] = im
	return CIELO_IM[key]

static func _cielo(P, sw: int, lz: int, corre := 0.0) -> void:
	P._img(cielo_img(sw, lz), 0, 0)
	P._rect(0, 120, sw, int(P.SH) - 120, Color(CIELO[lz][1]))   # 1.57.2: hasta abajo, que entre el monte y la carretera no se vea lo de detrás
	if lz == 2:   # estrellas fijas y la luna
		for i in 40:
			var hs := (i * 2654435761 + 977) & 0xffffff
			var sx := hs % sw
			var sy := 4 + (hs >> 9) % 58
			P._rect(sx, sy, 1, 1, Color("#e8ecff") if i % 3 else Color("#9aa4d0"))
		P._img(R.luna, sw - 48, 10)
	elif lz == 0:   # el sol, arriba a la derecha
		P._img(R.sol, sw - 48, 8)
	else:         # al atardecer, bajo
		P._img(R.sol, sw - 64, 40, Color(1.0, 0.72, 0.5))
	var vuelta := sw + 120
	for n in NUBES:
		var im: Image = R[n[0]]
		var x := int(fposmod(float(n[1]) - corre * float(n[3]), float(vuelta))) - 60
		P._img(im, x, int(n[2]), NUBE_TINTE[lz])

# [tipo, desfase]: el tipo por el destino (o por el trayecto) y dónde empieza, por el trayecto
static func pueblo(V: Dictionary) -> Array:
	var h := absi(hash("%s>%s" % [V.get("de", ""), V.get("a", "")]))
	var t: String = PUEBLO_DE.get(String(V.get("k", "")), PUEBLOS[h % PUEBLOS.size()])
	return [t, float(h % 1760)]

static func _fondo(P, sw: int, sh: int, corre: float, tin: Color, tipo := "rural") -> void:
	# las capas de fondo, repetidas
	for c in CAPAS:
		var im: Image = R[c[0] + ("-" + tipo if c[0] in ["lejos", "pueblo"] else "")]
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

# (lo pidió el usuario: «estos recursos se podrían usar antes de la pantalla de inicio, como de carga del juego, en una carretera
# sin texto, los vehículos andando y la barra cargándose»): al abrir el juego, de día, la carretera quieta con los vehículos que pasan
# por los dos carriles (en el de enfrente, al revés y un poco más oscuros) y, abajo, la barra; sin letras
const CARGA := 3600.0
const CARRIL_LEJOS := 13
# por carril, todos a la misma marcha (no se adelantan ni se montan): vehículo, carril (0 este lado, hacia la derecha; 1 el de enfrente,
# hacia la izquierda) y dónde va en la vuelta (0..1)
const CARGA_V := [["utilitario", 0, 0.0], ["moto", 0, 0.36], ["deportivo", 0, 0.68], ["bus", 1, 0.1], ["berlina", 1, 0.55]]
const MARCHA := [0.2, 0.14]   # px/ms por carril
const HUECO := 300            # la vuelta: la pantalla, el vehículo más largo y este hueco
static var VUELTA := {}   # los vehículos del carril de enfrente, al revés (nombre → Image)

static func _al_reves(k: String) -> Image:
	if not VUELTA.has(k):
		var im: Image = R[k].duplicate()
		im.flip_x()
		VUELTA[k] = im
	return VUELTA[k]

static func pinta_carga(P, e: float) -> void:
	if not carga():
		return
	var sw: int = P.J.SW
	var sh: int = P.SH
	if Datos.CAL and Atlas.ok:   # 1.57.1: la calle con el arte del juego
		pinta_calle(P, e)
	else:
		_cielo(P, sw, 0, e * 0.1)
		_fondo(P, sw, sh, 0.0, Color(1, 1, 1))
		_coches(P, e, Y_CARRETERA + CARRIL_LEJOS, Y_CARRETERA + CARRIL)
	# la barra, con su marco
	var bw := sw - 80
	var bx := 40
	var by := sh - 8
	P._rect(bx - 1, by - 1, bw + 2, 5, Color("#1a1420"))
	P._rect(bx, by, bw, 3, Color("#3a3446"))
	P._rect(bx, by, int(bw * clampf(e / CARGA, 0.0, 1.0)), 3, Color("#8bd448"))
	P._rect(bx, by, int(bw * clampf(e / CARGA, 0.0, 1.0)), 1, Color("#c4f088"))

# los vehículos de perfil por los dos carriles (suelo de cada carril: el de enfrente y este)
static func _coches(P, e: float, suelo1: int, suelo0: int) -> void:
	var sw: int = P.J.SW
	for carril in [1, 0]:
		for v in CARGA_V:
			if int(v[1]) != carril:
				continue
			var k: String = v[0]
			var m: Dictionary = META[k]
			var w: int = R[k].get_width()
			var vuelta := float(sw + 170 + HUECO)
			var anda := e * float(MARCHA[carril]) + float(v[2]) * vuelta
			var x := fposmod(anda, vuelta) - w
			if carril == 1:
				x = sw - x - w
			var suelo := suelo0 if carril == 0 else suelo1
			var bote := 1 if int(anda / 18.0) % 4 == 0 else 0
			var vx := int(x)
			var vy := suelo - int(m.suelo) - bote
			var tv := Color(1, 1, 1) if carril == 0 else Color(0.82, 0.84, 0.9)
			P._rect(vx + 3, suelo - 1, w - 6, 2, Color(0, 0, 0, 0.35))
			P._img(R[k] if carril == 0 else _al_reves(k), vx, vy, tv)
			for r in m.ruedas:
				var d := int(r[2])
				var f := posmod(int(floor(anda / (PI * d) * 4.0)), 4)
				var rx := int(r[0]) if carril == 0 else w - int(r[0])
				var rim: Image = R["rueda-%d-%d" % [d, f if carril == 0 else 3 - f]]
				P._img(rim, vx + rx - d / 2, vy + bote + int(r[1]) - d / 2, tv)

# (lo pidió el usuario: «que aparezcan en la pantalla de carga los sprites reales de césped, árboles, setos, también molaría que
# pasasen algún transeúnte… que se quede de fondo la carretera andando coches y por la acera transeúntes andando, en bici, patinete»): la
# calle del juego vista de lado, quieta, de abajo arriba: la acera de delante, la calzada (dos carriles), la acera de detrás y dos filas de
# hierba con árboles y setos, el monte y el cielo; por las aceras, gente andando, en bici y en patinete; por la calzada, los vehículos de
# perfil. La carga y el título (CALLE_FIL: filas de 16 px desde abajo)
const CALLE_FIL := ["grass", "walk", "roadB", "roadT", "walk", "grass", "grass"]   # i18n-no · abajo, la hierba con la barra de la carga
# los de las aceras: acera (0 la de detrás, 1 la de delante), sentido, px/ms, dónde va en la vuelta (0..1) y vehículo
const PEATONES := [[0, 1, 0.040, 0.05, ""], [0, -1, 0.034, 0.40, ""], [0, 1, 0.085, 0.62, "bici"], [0, -1, 0.045, 0.85, ""],
	[1, -1, 0.042, 0.20, ""], [1, 1, 0.066, 0.50, "patinete"], [1, -1, 0.090, 0.75, "bici"], [1, 1, 0.038, 0.95, ""]]

# (lo pidió el usuario: «que se vea alguna planta en vegetativo, alguna floración, dependiendo del punto del año… cómo sería el
# cultivo en exterior»): en la hierba de detrás, un bancal con tres plantas de exterior por la fecha del sistema (la carga y el título no
# tienen partida): (mes, hasta el día, fase: -1 nada, 0 plántula, 1-2 vegetativo, 3 prefloración, 4 floración,
# 5 madura, 6 cortada). Las plantas, dibujadas a mano con contorno como el árbol y el seto (huerto-pl, hp<variedad>-<1..5>: índica,
# sativa e híbrida); cortada, el bancal vacío. Calendario del norte: se siembra a mediados de abril, florece en agosto y se corta en octubre
const HUERTO := [[3, 31, -1], [4, 14, -1], [4, 30, 0], [5, 15, 0], [5, 31, 1], [6, 15, 1], [6, 30, 2], [7, 31, 2], [8, 24, 3],
	[8, 31, 4], [9, 20, 4], [9, 30, 5], [10, 20, 5], [10, 31, 6], [12, 31, -1]]
const HUERTO_X := 0.55    # dónde empieza el bancal, por el ancho de la pantalla
const HUERTO_N := 3
const HUERTO_PASO := 24   # 1,5 m entre plantas
const HUERTO_FASE := [1, 2, 3, 4, 4, 5]   # fase del bancal → la de huerto-pl (1 plántula … 5 madura); 6, cortada: nada
static var FECHA := []    # [mes, día] para las pruebas; vacío, la del sistema

static func fase_huerto(mes: int, dia: int) -> int:
	for q in HUERTO:
		if mes < int(q[0]) or (mes == int(q[0]) and dia <= int(q[1])):
			return int(q[2])
	return -1

static func fecha_huerto() -> Array:
	if FECHA.size() == 2:
		return FECHA
	var d := Time.get_date_dict_from_system()
	return [int(d.month), int(d.day)]

static func _huerto(P, sw: int, fy: int, list: Array) -> void:
	var f0 := fecha_huerto()
	var fase := fase_huerto(f0[0], f0[1])
	var x0 := int(sw * HUERTO_X) & ~15
	var x1 := x0 + HUERTO_PASO * (HUERTO_N - 1) + 16
	P._rect(x0 - 4, fy - 2, x1 - x0 + 8, 3, Color8(0x6a, 0x4a, 0x2e))   # el bancal de tierra
	P._rect(x0 - 3, fy - 3, x1 - x0 + 6, 1, Color8(0x8a, 0x64, 0x40))
	for i in HUERTO_N:
		var fi := fase
		if i == 1 and fi in [4, 5]:   # la del medio, una sativa que va más tarde
			fi -= 1
		var sm := "hp%d-%d" % [i % 3, HUERTO_FASE[fi]] if fi >= 0 and fi < HUERTO_FASE.size() else ""
		var f = Atlas.frame_de(Atlas.cubre("obj:" + sm), sm, "unica", 0, {"i": 0, "esp": i % 2 == 1}) if sm != "" else null
		if f:
			list.append([fy, f, x0 + 8 + i * HUERTO_PASO, fy])

static func calle_y0(P) -> int:
	return int(P.SH) - 16 * CALLE_FIL.size()

static func pinta_calle(P, e: float) -> void:
	var sw: int = P.J.SW
	var y0 := calle_y0(P)
	_cielo(P, sw, 0, e * 0.1)
	var im: Image = R.monte
	var x := 0
	while x < sw:
		P._img(im, x, y0 - im.get_height() + 3, Color(1, 1, 1))
		x += im.get_width()
	var n := CALLE_FIL.size()
	var cols := ceili(sw / 16.0)
	for i in n:
		var k: String = CALLE_FIL[n - 1 - i]
		var sy := y0 + i * 16
		for tx in cols:
			var kk := k
			if i == 0 and P.hash_t(tx, 5) % 9 == 0:
				kk = "flowers"
			_tile(P, kk, tx, i, tx * 16, sy)
		if k == "grass" and i + 1 < n and CALLE_FIL[n - 2 - i] == "walk":   # el canto de la hierba junto a la acera
			P._rect(0, sy + 15, sw, 1, Color8(0x5a, 0xa0, 0x4e))
			P._rect(0, sy + 14, sw, 1, Color8(0x72, 0xbc, 0x5e))
		if k == "grass" and i > 0 and CALLE_FIL[n - i] == "walk":
			P._rect(0, sy, sw, 1, Color8(0x5a, 0xa0, 0x4e))
			P._rect(0, sy + 1, sw, 1, Color8(0x72, 0xbc, 0x5e))
	# en la fila de hierba de abajo, setos y algún árbol (con el pie en la fila)
	var fy := y0 + 31
	var gt = Atlas.cubre("obj:tree")
	var gs = Atlas.cubre("obj:seto")
	var list := []
	var ult := -9
	var hx := int(sw * HUERTO_X) >> 4
	for tx in range(-1, cols + 1):
		if Datos.CAL and tx >= hx - 2 and tx <= hx + 4:   # 1.57.2: el sitio del bancal
			continue
		var h: int = P.hash_t(tx, 3)
		var d: Dictionary = P.desfase("tree", tx, 3)
		if gt and tx - ult >= 3 and (h % 3 == 0 or tx - ult >= 7):   # árboles sueltos, a 3-7 casillas
			ult = tx
			var k := "tree2" if h % 5 == 0 else "tree"
			var g2 = Atlas.cubre("obj:" + k)
			var f = Atlas.frame_de(g2 if g2 else gt, k, "unica", 0, {"i": 0, "esp": d.esp})
			if f:
				list.append([fy - 2, f, tx * 16 + 8 + d.dx, fy - 2])
		elif h % 4 and gs:
			var f2 = Atlas.frame_de(gs, "seto", "unica", 0, {"i": 0})
			if f2:
				list.append([fy, f2, tx * 16 + 8, fy])
	if Datos.CAL:
		_huerto(P, sw, fy - 10, list)   # en lo alto de la hierba, que el tráfico no lo tape
	list.sort_custom(func(a, b): return a[0] < b[0])
	for q in list:
		P._pinta(q[1], q[2], q[3])
	# la acera de detrás, el carril de enfrente, el de este lado y la de delante
	_peatones(P, e, 0, y0 + 47)
	_coches(P, e, y0 + 60, y0 + 77)
	_peatones(P, e, 1, y0 + 95)

static func _tile(P, k: String, tx: int, ty: int, sx: int, sy: int) -> void:
	var fp = Atlas.frame_de("exterior-mosaico", "mo-" + k, "unica", 0, {"i": 0})
	if fp:
		Atlas.dibuja(P.L, fp.c, Rect2(sx, sy, 16, 16), Rect2(((tx & 3) + 4 * (ty & 3)) * 16, 0, 16, 16))
		return
	var f = Atlas.frame_de(Atlas.cubre("tile:" + k), k, "unica", 0, {"i": 0})
	if f:
		Atlas.dibuja(P.L, f.c, Rect2(sx, sy, 16, 16), Rect2(0, 0, 16, 16))

static func _peatones(P, e: float, acera: int, yp: int) -> void:
	var sw: int = P.J.SW
	var vuelta := float(sw + 64)
	for i in PEATONES.size():
		var q: Array = PEATONES[i]
		if int(q[0]) != acera:
			continue
		var gr = Atlas.grupo_look(Datos.rand_look("calle%d" % i, "client"))
		if not gr:
			continue
		var anda: float = e * float(q[2]) + float(q[3]) * vuelta
		var x := fposmod(anda, vuelta) - 32.0
		if int(q[1]) < 0:
			x = sw - x
		var dir := "east" if int(q[1]) > 0 else "west"
		var v: String = q[4]
		if v != "" and not Atlas.anim_de("vehiculos", v + "-atras"):
			v = ""
		var f = null
		if v == "patinete":
			f = Atlas.frame_de(gr, "base", dir, 0, {"i": 0})
		else:
			f = Atlas.frame_de(gr, "walk", dir, 0, {"ph": fposmod(anda / (48.0 if v == "bici" else 32.0), 1.0)})
		if f == null:
			continue
		var xp := int(x)
		var sm := Color8(0, 0, 0, 56)
		P._rect(xp - 4, yp - 1, 8, 3, sm)
		P._rect(xp - 5, yp, 10, 1, sm)
		if v != "":
			var o := {"i": int(anda / 8.0) % 2}
			var va = Atlas.frame_de("vehiculos", v + "-atras", dir, 0, o)
			var vd = Atlas.frame_de("vehiculos", v + "-delante", dir, 0, o)
			if va:
				P._pinta(va, xp, yp)
			P._pinta(f, xp, yp - int(P.J.D.VEHICULOS[v].sube))
			if vd:
				P._pinta(vd, xp, yp)
		else:
			P._pinta(f, xp, yp)

# el trayecto y los minutos, con el contorno oscuro por los ocho lados (lo pidió el usuario: «mientras no se tape el texto»): se lee
# encima de cualquier fachada, también de las blancas
const TEXTO_BORDE := Color("#1a1420")
static func _texto(P, x: int, y: int, t: String, s: int) -> void:
	for q in Croquis.letras(t):
		for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
			P._rect(x + q.x * s + d.x, y + q.y * s + d.y, s, s, TEXTO_BORDE)
	for q in Croquis.letras(t):
		P._rect(x + q.x * s, y + q.y * s, s, s, Color("#f8f4e8"))
