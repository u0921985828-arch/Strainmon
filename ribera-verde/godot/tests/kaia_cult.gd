# Ribera Verde (Godot) — la sala de cultivo de KAIA (kaiacult.gd, con CAL; lo pidió el usuario: «incluso molaría tener un cultivo
# finalmente en la nueva asociación de KAIA», «tiene que tener lógica con el suelo que hay al rededor y las zonas donde las colocas» y
# «como en casa, cultivo con carpas, pero más grandes de primeras, con una inversión realista, después como en la nave en esa misma
# habitación, ya con posibilidad de poner a alguien a trabajar ahí y la inversión será más grande»): la puerta de KAIA, cerrada sin la
# licencia; dentro, el pasillo y la zona de cultivo; las carpas por niveles (4 de 2 × 2, 2 de 4 × 2 y 1 de 4 × 4) por la cuenta, que
# llegan al día siguiente, y el paso de un nivel al siguiente con las de antes de segunda mano; las
# carpas solo en la zona y sin montarse encima de nada; plantar, crecer con el goteo y cosechar; la obra de la sala con las mesas y
# quien las lleva, que cortan, secan y llenan el almacén de KAIA; nada encima de nada; sin CAL, nada.
#   $GODOT --headless --path godot --script res://tests/kaia_cult.gd   → «kaia_cult: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var LOG := []
var MENUS := []
var TIT := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	MENUS.append(items.map(func(it): return it if it is String else str(it.get("label", ""))))
	TIT.append(str(o.get("title", "")))
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
			break
	o = o.duplicate()
	o.initial = k
	return o

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo")
			return false
	return true

func dicho(t: String) -> bool:
	return LOG.any(func(l): return String(l).contains(t))

func mundo(mapa: String, x: int, y: int) -> bool:
	J.enter_map(mapa, x, y, "down")
	J.mode = "world"
	return corre(func(): pass)

func alcance_d(mapa: String, x0: int, y0: int) -> Dictionary:
	var m: Dictionary = J.MAPS[mapa]
	var q := [[x0, y0]]
	var v := {}
	var i := 0
	while i < q.size():
		var c: Array = q[i]
		i += 1
		var kk := "%d,%d" % [c[0], c[1]]
		if v.has(kk) or not J.pisable(m, c[0], c[1]) or m.o[c[1]][c[0]]:
			continue
		v[kk] = true
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			q.append([c[0] + d[0], c[1] + d[1]])
	return v

func delante(v: Dictionary, x: int, y: int) -> bool:
	return [[0, 1], [0, -1], [1, 0], [-1, 0]].any(func(d): return v.has("%d,%d" % [x + d[0], y + d[1]]))

# la red del riego y del drenaje de la sala (kaiacult.gd red_riego y red_fuera; lo pidió el usuario: «todas las conexiones de riego,
# de drenaje hazlas con cabeza y pensando… LOGICAS» y «que tampoco sea el depósito… tendrá que estar fuera de las carpas»), contra los
# sprites (cajas_obj), no contra sus propias cuentas. Dentro: cada red, de una pieza, por la electroválvula de cada mesa y de debajo
# del desagüe de cada bandeja (mesaN: en su canto, a la derecha) al colector, y las dos a la boca de servicio del canto de delante;
# nada por el suelo de un pasillo (debajo de las mesas, pegado a la pared de la derecha o a la de delante). Fuera: el tanque, el
# programador y el depósito, en el paso de delante de la carpa; la impulsión, de la bomba del tanque al programador y de él a la
# boca; el drenaje, de la boca al tubo de entrada del depósito, por encima, y la vuelta, de su bomba al tanque; ningún tubo encima de
# otro y nada por el suelo por el que se anda
func _caja(C: Array, o: String):
	for c in C:
		if c.o == o:
			return c
	return null

func _opaco(c, x: int, y: int) -> bool:
	var u: int = x - int(c.px)
	var v: int = y - int(c.py)
	return u >= 0 and v >= 0 and u < c.c.get_width() and v < c.c.get_height() and c.c.get_pixel(u, v).a8 > 0

func _toca(t: Array, c) -> bool:   # el tramo pasa por un píxel del aparato (o pegado a él)
	for q in _px(t):
		for d in [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]:
			if _opaco(c, q[0] + d[0], q[1] + d[1]):
				return true
	return false

func _px(t: Array) -> Array:
	var o := []
	for y in range(mini(int(t[1]), int(t[3])), maxi(int(t[1]), int(t[3])) + 1):
		for x in range(mini(int(t[0]), int(t[2])), maxi(int(t[0]), int(t[2])) + 1):
			o.append([x, y])
	return o

func _junta(a: Array, b: Array) -> bool:   # dos tramos que se tocan (con 1 px de holgura, lo que mide el tubo)
	return mini(int(a[0]), int(a[2])) <= maxi(int(b[0]), int(b[2])) + 1 and mini(int(b[0]), int(b[2])) <= maxi(int(a[0]), int(a[2])) + 1 and mini(int(a[1]), int(a[3])) <= maxi(int(b[1]), int(b[3])) + 1 and mini(int(b[1]), int(b[3])) <= maxi(int(a[1]), int(a[3])) + 1

# el tubo de extracción de cada carpa a la pared (kaiacult.gd tubos_ext; lo pidió el usuario: «todas las conexiones… lógicas» y «No
# quiero que ningún objeto de pared o suelo se superponga sobre otro»): n carpas servidas, cada una de la boca del techo de su carpa,
# recto al pasamuros de la pared de atrás o por su ramal al colector, que sale a la pared; sin pisarse (a un tubo como poco), con los
# pasamuros separados y dentro de la pared, y ningún tramo por encima de un píxel de otra carpa, de un depósito o de lo de la pared
func tubos_ok(n: int, txt: String) -> void:
	var T: Array = J.tubos_ext()
	var m: Dictionary = J.MAPS[J.S.map]
	var C: Array = J.cajas_obj(J.S.map, m.o)
	var malos := []
	var serv := {}
	var pms := []
	var tr := []   # cada tramo: [x0, y0, x1, y1, su carpa (-1, la de sala; -2, el colector)]
	var col = null
	for i in T.size():
		var q: Array = T[i]
		var ci: int = int(q[3])
		var tipo: String = String(q[6])
		if (tipo == "rama") == (int(q[1]) == int(J.KC_TUBO_PARED)) or int(q[2]) <= int(q[1]) + 4 or int(q[2]) >= int(m.h) * 16:
			malos.append("tubo %d: %s" % [i, q])
		if tipo != "rama":
			pms.append(int(q[0]))
		tr.append([int(q[0]) - 2, int(q[1]), int(q[0]) + 2, int(q[2]), ci])
		if tipo == "col":
			col = q
			tr.append([int(q[5][0]) - 2, int(q[2]) - 2, int(q[5][1]) + 2, int(q[2]) + 2, ci])
		elif ci >= 0:
			serv[ci] = true
			var p: Array = J.kc_pos(ci)
			var t: Array = J.kc_Nc(ci).tam
			if int(q[0]) < int(p[0]) * 16 + 6 or int(q[0]) > (int(p[0]) + int(t[0])) * 16 - 7 or int(q[2]) != (int(p[1]) + int(t[1])) * 16 - (int(t[1]) * 8 + 32) + 1:
				malos.append("tubo %d, fuera de la boca de su carpa: %s" % [i, q])
			if not bool(q[4]):
				malos.append("tubo %d, fuera de su mitad" % i)
			if not J.kc_cabe_filtro(ci, int(q[0]) - int(p[0]) * 16):   # y donde su filtro cuelga en la vista C sin tocar una cuerda
				malos.append("tubo %d, donde su filtro no cabe entre las cuerdas: %s" % [i, q])
		elif m.o[int(q[2]) / 16 + 3][int(q[0]) / 16] == null:
			malos.append("tubo %d, sin la carpa de sala debajo" % i)
	for q in T:
		if String(q[6]) == "rama" and (col == null or int(q[1]) != int(col[2]) or int(q[0]) < int(col[5][0]) or int(q[0]) > int(col[5][1])):
			malos.append("ramal sin colector: %s" % [q])
	for i in pms.size():
		if pms[i] - J.KC_PM < 0 or pms[i] + J.KC_PM > int(m.w) * 16 - 1:
			malos.append("pasamuros fuera de la pared en %d" % pms[i])
		for k in range(i + 1, pms.size()):
			if absi(pms[k] - pms[i]) < 2 * J.KC_PM + 2:
				malos.append("pasamuros %d y %d, montados" % [pms[i], pms[k]])
	for i in tr.size():
		for k in range(i + 1, tr.size()):
			var a: Array = tr[i]
			var b: Array = tr[k]
			if int(a[4]) == -2 or int(b[4]) == -2:
				continue   # el colector, empalmado con sus ramales
			if a[0] <= b[2] + 4 and b[0] - 4 <= a[2] and a[1] <= b[3] and b[1] <= a[3]:
				malos.append("tubos %s y %s, juntos" % [a, b])
	for t in tr:
		for c in C:
			var ca: int = J.kc_ancla(c.o) if c.o is String else -1
			if (ca >= 0 and ca == int(t[4])) or String(c.o) == "carpaG2":
				continue
			var pisa := false
			for yy in range(maxi(int(t[1]), int(c.py)), mini(int(t[3]), int(c.py) + c.c.get_height() - 1) + 1):
				for xx in range(int(t[0]), int(t[2]) + 1):
					if _opaco(c, xx, yy):
						pisa = true
						break
				if pisa:
					break
			if pisa and not (int(t[4]) == -1 and String(c.o) == "carpaKX"):
				malos.append("un tubo (%s) encima de %s (%d, %d)" % [t, c.o, c.x, c.y])
	chk(serv.size() + (T.size() if T.size() and int(T[0][3]) == -1 else 0) == n and malos.is_empty(), "%s: %d tubos a la pared, %d al colector %s" % [txt, pms.size(), T.filter(func(q): return String(q[6]) == "rama").size(), malos.slice(0, 4)])

# el depósito del goteo de cada carpa de la fase 1 (kaia_cult.py NIV.dep; lo pidió el usuario: «que tampoco sea el depósito… tendrá que
# estar fuera de las carpas y demás. Esas cosas hay que hacerlas con lógica»), contra los sprites: n, cada uno fuera de su carpa y
# pegado a uno de sus lados, con el grifo hacia ella (depKd a su derecha, depK a su izquierda) y su manguera del grifo al poste de la
# carpa; ningún tubo de extracción del techo por encima de un depósito; en la vista C, el depósito en pequeño a ese lado (depi). Cada
# uno, a su tamaño (lo pidió el usuario: «los depósitos se deben de dibujar de diferentes tamaños también»): el de más litros, más alto
# y más ancho en el mapa (NIV.ds, kaia_riego.py)
func deps_ok(n: int, txt: String) -> void:
	var m: Dictionary = J.MAPS[J.S.map]
	var C: Array = J.cajas_obj(J.S.map, m.o)
	var en := func(x: int, y: int):
		for c in C:
			if int(c.x) == x and int(c.y) == y:
				return c
		return null
	var malos := []
	var k := 0
	var mg: Array = J.tubos_dep()
	var tam := {}   # litros → [ancho, alto] del sprite en el mapa
	for ci in J.kc_ns():
		if not J.kc_tiene(ci):
			continue
		k += 1
		var p: Array = J.kc_pos(ci)
		var t: Array = J.kc_Nc(ci).tam
		var d: Array = J.kc_dep(ci)
		var x: int = int(p[0]) + int(d[0])
		var y: int = int(p[1]) + int(d[1])
		var izq := int(d[0]) < 0
		var cb = en.call(x, y)
		var ct = en.call(int(p[0]), int(p[1]) + int(t[1]) - 1)
		var N: Dictionary = J.kc_Nc(ci)
		if m.o[y][x] != String(N.ds) + ("" if izq else "d") or not (int(d[0]) == -1 or int(d[0]) == int(t[0])) or int(d[1]) < 0 or int(d[1]) >= int(t[1]) or cb == null or ct == null:
			malos.append("carpa %d: %s en (%d, %d)" % [ci, m.o[y][x], x, y])
			continue
		var ur: Rect2i = cb.c.get_used_rect()
		if tam.has(int(N.dl)) and tam[int(N.dl)] != [ur.size.x, ur.size.y]:
			malos.append("carpa %d: el depósito de %d L, de otro tamaño que el de su nivel" % [ci, int(N.dl)])
		tam[int(N.dl)] = [ur.size.x, ur.size.y]
		if J.kc_carpa_en(x, y) >= 0 or J.kc_carpa_en(x, y, true) != ci or J.kc_def(ci).depi != izq:
			malos.append("carpa %d: el depósito, dentro, de otra o en la vista al otro lado" % ci)
		var X: int = x * 16
		var hy: int = (y + 1) * 16 - 1 - 6
		var xg: int = X + 13 if izq else X + 2   # el grifo
		var xp: int = X + 16 if izq else X - 1   # el poste de la carpa
		var gc: Color = cb.c.get_pixel(xg - int(cb.px), hy - int(cb.py)) if _opaco(cb, xg, hy) else Color(0, 0, 0, 0)
		if not (gc.a > 0 and gc.r > .55 and gc.b < .45) or not _opaco(ct, xp, hy):
			malos.append("carpa %d: el grifo (%s) o el poste, no a la altura de la manguera" % [ci, gc])
		var hay := false
		for q in mg:
			for r in q[1]:
				var r1: int = int(r[0]) + int(r[2]) - 1   # del poste al canto del grifo
				if int(r[1]) == hy and int(r[3]) == 1 and ((izq and r1 == xp and int(r[0]) <= xg + 2) or (not izq and int(r[0]) == xp and r1 >= xg - 2)):
					hay = true
		if not hay:
			malos.append("carpa %d: sin manguera del grifo a la carpa" % ci)
		for q in J.tubos_ext():
			for yy in range(int(cb.py), int(cb.py) + cb.c.get_height()):
				for xx in range(int(q[0]) - 2, int(q[0]) + 3):
					if yy >= int(q[1]) and yy <= int(q[2]) and _opaco(cb, xx, yy):
						malos.append("carpa %d: un tubo del techo encima del depósito" % ci)
	var ls: Array = tam.keys()
	ls.sort()
	for i in range(1, ls.size()):
		if not (tam[ls[i]][0] >= tam[ls[i - 1]][0] and tam[ls[i]][1] > tam[ls[i - 1]][1]):
			malos.append("el depósito de %d L, no más grande que el de %d L: %s" % [ls[i], ls[i - 1], tam])
	chk(k == n and malos.is_empty(), "%s: %d depósitos, cada uno a su lado, a su tamaño (%s) y con su manguera %s" % [txt, k, tam, malos.slice(0, 4)])

# cada red de L, de una pieza con sus aparatos (cajas o rectángulos [x, y, w, h])
func _de_una(L: Array, ap: Array) -> int:
	var g := []
	for i in L.size() + ap.size():
		g.append(i)
	var une := func(i: int, j: int) -> bool:
		if i < L.size() and j < L.size():
			return _junta(L[i], L[j])
		if i < L.size() and j >= L.size():
			return _toca_ap(L[i], ap[j - L.size()])
		return false
	var cambia := true
	while cambia:
		cambia = false
		for i in g.size():
			for j in g.size():
				if g[i] != g[j] and une.call(i, j):
					var a: int = mini(g[i], g[j])
					g[i] = a
					g[j] = a
					cambia = true
	var trozos := {}
	for x in g:
		trozos[x] = true
	return trozos.size()

func _toca_ap(t: Array, c) -> bool:   # un aparato (su caja) o la boca de servicio (un rectángulo)
	if c is Array:
		for q in _px(t):
			if q[0] >= c[0] - 1 and q[0] <= c[0] + c[2] and q[1] >= c[1] - 1 and q[1] <= c[1] + c[3]:
				return true
		return false
	return _toca(t, c)

func _arriba(c) -> int:   # la primera fila pintada de un aparato, en el mapa
	for v in c.c.get_height():
		for u in c.c.get_width():
			if c.c.get_pixel(u, v).a8 > 0:
				return int(c.py) + v
	return 1 << 20

func _pisa(a: Array, b: Array) -> bool:   # dos rectángulos [x, y, w, h, color] que se montan
	return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]

func red_logica(SA: String, ms: Dictionary) -> void:
	var F2: Dictionary = J.D.KAIA_CULT.f2
	var red: Array = J.red_riego()
	var C: Array = J.cajas_obj(SA, ms.o)
	var W: int = int(ms.w) * 16
	var H: int = int(ms.h) * 16
	chk(not ms.o.any(func(r): return r.any(func(c): return c in ["tanqueN", "riegoN", "drenKS", "drenKS2"])), "dentro de la carpa, ni el tanque, ni el programador, ni el depósito")
	chk(red.size() >= 2 * 2 + F2.mesas.size() + 2, "la red: %d tramos" % red.size())
	for tp in ["sum", "dren"]:
		var L: Array = red.filter(func(q): return q[4] == tp)
		chk(_de_una(L, []) == 1, "%s: de una pieza" % ("la impulsión" if tp == "sum" else "el drenaje"))
		chk(L.any(func(q): return maxi(int(q[1]), int(q[3])) == H - 1 and int(q[0]) >= W - 9), "%s: a la boca de servicio, por la pared de la derecha" % ("la impulsión" if tp == "sum" else "el drenaje"))
	for k in F2.mesas.size():
		var mx: int = int(F2.mesas[k][0])
		var my: int = int(F2.mesas[k][1])
		var me = null
		for c in C:
			if c.o == "mesaKP" and int(c.x) == mx and int(c.y) == my:
				me = c
		chk(me != null, "la mesa %d, pintada" % (k + 1))
		if me == null:
			continue
		# el desagüe de mesaN: el cuadradito oscuro del canto de la bandeja, a la derecha (celda 37-38, 37-38 del sprite)
		var xd: int = int(me.px) + 37
		var yd: int = int(me.py) + 38
		var baja = null
		for q in red:
			if q[4] == "dren" and int(q[0]) == int(q[2]) and int(q[0]) >= xd - 1 and int(q[0]) <= xd + 2 and mini(int(q[1]), int(q[3])) >> 4 == my:
				baja = q
		chk(baja != null and mini(int(baja[1]), int(baja[3])) > yd and _opaco(me, int(baja[0]), mini(int(baja[1]), int(baja[3]))), "mesa %d: su bajante sale de debajo de la bandeja, bajo su desagüe (%s; el desagüe en %d, %d)" % [k + 1, baja, xd, yd])
		chk(baja != null and red.any(func(q): return q[4] == "dren" and int(q[1]) == int(q[3]) and int(q[1]) == maxi(int(baja[1]), int(baja[3])) and int(baja[0]) >= mini(int(q[0]), int(q[2])) and int(baja[0]) <= maxi(int(q[0]), int(q[2]))), "mesa %d: y cae al colector de su fila" % (k + 1))
		var xv: int = mx * 16 + 10
		chk(red.any(func(q): return q[4] == "sum" and int(q[1]) == int(q[3]) and xv >= mini(int(q[0]), int(q[2])) and xv <= maxi(int(q[0]), int(q[2])) and int(q[1]) >= my * 16 + 9 and int(q[1]) <= my * 16 + 11), "mesa %d: la impulsión pasa por su electroválvula" % (k + 1))
	var malos := []
	for q in red:
		for p in _px(q):
			var tx: int = int(p[0]) >> 4
			var ty: int = int(p[1]) >> 4
			var ok: bool = p[0] >= W - 9 or p[1] >= H - 3 or (ty < ms.o.size() and tx < ms.o[ty].size() and ms.o[ty][tx] != null)
			if not ok:
				for c in C:
					if _opaco(c, int(p[0]), int(p[1])):
						ok = true
						break
			if not ok:
				malos.append("%s %d,%d" % [q[4], p[0], p[1]])
	chk(malos.is_empty(), "nada por el suelo de un pasillo: %s" % [malos.slice(0, 4)])

func red_fuera(MA: String) -> void:
	var m: Dictionary = J.MAPS[MA]
	var F2: Dictionary = J.D.KAIA_CULT.f2
	var red: Array = J.red_fuera()
	var C: Array = J.cajas_obj(MA, m.o)
	var tq = _caja(C, "tanqueKB")
	var rg = _caja(C, "riegoKB")
	var dr = _caja(C, "drenKB")
	var b: Array = J.kc_boca()
	chk(tq != null and rg != null and dr != null, "fuera, el tanque, el programador y el depósito, pintados")
	if tq == null or rg == null or dr == null:
		return
	var CX: Dictionary = F2.carpa
	chk(F2.fuera.all(func(q): return int(q[1]) == int(CX.def[1]) + int(CX.tam[1]) and m.o[int(q[1])][int(q[0])] == q[2]), "en el paso de delante de la carpa de sala")
	chk([tq, rg, dr].all(func(c): return _arriba(c) >= (int(CX.def[1]) + int(CX.tam[1])) * 16), "de una casilla de alto: ninguno se monta en la carpa")
	var ca = _caja(C, String(CX.obj))
	chk(ca != null and _opaco(ca, int(b[0]) + 3, int(b[1]) + 3) and int(b[1]) + int(b[3]) <= _arriba(dr), "la boca de servicio, en el frente de la carpa y por encima del depósito (%s)" % [b])
	var S_: Array = red.filter(func(q): return q[4] == "sum")
	var Dr: Array = red.filter(func(q): return q[4] == "dren")
	chk(_de_una(S_, [tq, rg, b]) == 1, "la impulsión, de una pieza con el tanque, el programador y la boca")
	chk(S_.any(func(q): return _toca(q, tq)) and S_.any(func(q): return _toca(q, rg)) and S_.any(func(q): return _toca_ap(q, b)), "de la bomba del tanque al programador y de él a la boca")
	chk(_de_una(Dr, [b, dr, tq]) == 1, "el drenaje y la vuelta, de una pieza con la boca, el depósito y el tanque")
	var cae = null   # el tramo que entra en el depósito: de la boca, recto abajo, a su tubo de entrada
	for q in Dr:
		if int(q[0]) == int(q[2]) and _toca(q, dr) and _toca_ap(q, b) and maxi(int(q[1]), int(q[3])) <= _arriba(dr) + 2:
			cae = q
	chk(cae != null, "el drenaje cae de la boca, recto, al tubo de arriba del depósito")
	chk(Dr.any(func(q): return not q[5] and _toca(q, dr) and _toca(q, tq)), "y la vuelta, de la bomba del depósito al tanque, por detrás")
	var rs: Array = J._tubos_de(S_)
	var rd: Array = J._tubos_de(Dr)
	var pisan := []
	for a in rs:
		for c in rd:
			if _pisa(a, c):
				pisan.append([a.slice(0, 4), c.slice(0, 4)])
	chk(pisan.is_empty(), "ningún tubo encima de otro: %s" % [pisan.slice(0, 2)])
	var v := alcance_d(MA, 1, 2)
	var malos := []
	for q in red:
		for p in _px(q):
			if v.has("%d,%d" % [int(p[0]) >> 4, int(p[1]) >> 4]):
				malos.append("%s %d,%d" % [q[4], p[0], p[1]])
	chk(malos.is_empty(), "fuera, nada por el suelo por el que se anda: %s" % [malos.slice(0, 4)])
	chk(delante(v, int(F2.fuera[0][0]), int(F2.fuera[0][1])), "se llega al rincón del riego")

func _corre() -> void:
	Cultivo.pm = 4242   # el Park-Miller del oráculo: sin él, `azar()` cae en randf() y una plaga podía secar la planta de la carpa
	Juego.GUARDADO = "user://prueba-kaia-cult.json"
	Juego.AJUSTES = "user://prueba-kaia-cult-ajustes.json"
	Datos.CAL = true
	Atlas.carga()
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D: Dictionary = J.D
	var KC: Dictionary = D.KAIA_CULT
	var C: String = KC.mapa
	J.queued.clear()
	J.pending.clear()
	J.mode = "world"
	if not (J.S.get("mar") is Dictionary):
		J.S.mar = {}
	J.S.mar.erase("lic")
	if J.S.get("nave") is Dictionary:   # la nave de la partida de las pantallas (la 1.37), con lo que nave_dia lee ahora
		if not J.S.nave.has("ma"):
			J.S.nave.ma = []
		if not J.S.nave.has("r"):
			J.S.nave.r = int(J.S.day) + 30
	J.S.erase("kc")
	# 1 · los datos: la sala, su puerta en KAIA, sus carpas y la obra
	var PZ: Array = D.ORDEN_P[C].piezas
	chk(D.MAPS.has(C) and int(D.MAPS[C].w) == 16 and int(D.MAPS[C].h) == 10 and PZ.size() == 7 and PZ.all(func(q): return q.zona == ["floorG"] and q.si == "kc"), "la sala de 16 × 10, con las siete carpas de los tres niveles, que van en la zona")
	var NV: Array = KC.niv
	chk(NV.size() == 3 and NV.map(func(q): return [int(q.max), int(q.tam[0]), int(q.tam[1])]) == [[4, 2, 2], [2, 4, 2], [1, 4, 4]] and PZ.all(func(q): return q.o.size() == int(NV[["s", "m", "l"].find(str(q.k).substr(2, 1))].tam[0]) * int(NV[["s", "m", "l"].find(str(q.k).substr(2, 1))].tam[1]) + 1 and q.o.back()[2] == String(NV[["s", "m", "l"].find(str(q.k).substr(2, 1))].ds) + ("" if int(q.o.back()[0]) < 0 else "d")), "los niveles: 4 de 2 × 2, 2 de 4 × 2 y 1 de 4 × 4, cada pieza de su tamaño y su depósito")
	chk(D.PUERTAS_INT["club-muelle"].any(func(q): return q.to == C and int(q.x) == 15 and int(q.y) == 1 and q.llave == "kc"), "la puerta, en la pared de KAIA")
	chk(D.MAPS["club-muelle"].o[2][14] == "jukebox" and D.MAPS["club-muelle"].o[2][15] == null and D.ORDEN_P["club-muelle"].pie.any(func(c): return int(c[0]) == 15 and int(c[1]) == 2), "la gramola, a un lado; delante de la puerta, libre")
	var cm: Dictionary = D.MAPS[C]
	chk(range(2, cm.h).all(func(y): return cm.g[y][0] == "floorC_itsaso" and cm.g[y][2] == "floorC_itsaso" and cm.g[y][3] == "floorG" and cm.g[y][15] == "floorG"), "el pasillo con el suelo del club y la zona de cultivo con el del grow")
	var kps := []
	for N in NV:
		var kq := 0
		for q in N.kit.l:
			kq += int(q[1])
		kps.append(kq)
		var wl: float = float(D.FOCOS[KC.foco].w) * float(N.nf)
		chk(kq == int(N.kit.p) and D.FOCOS[KC.foco].w == 720 and wl / (float(N.cm[0]) * float(N.cm[1]) / 1e4) >= 300 and wl / (float(N.cm[0]) * float(N.cm[1]) / 1e4) <= float(D.W_M2), "%s: el kit a precio de tienda (%d €), %d LED de 720 W (%d W/m²)" % [N.n, kq, int(N.nf), int(wl / (float(N.cm[0]) * float(N.cm[1]) / 1e4))])
	var kp: int = kps[0]
	chk(kps[0] < kps[1] and kps[1] < kps[2] and int(NV[0].plazas) * 4 == int(NV[1].plazas) * 2 and int(NV[1].plazas) * 2 == int(NV[2].plazas), "cada nivel, más inversión por carpa y las mismas plazas en total: %s" % [kps])
	chk(int(KC.f2.p) > kps[2] and KC.f2.mesas.size() == 8 and int(D.PLANTILLA.sueldo.kaia) > 0, "la obra, más inversión que la carpa grande: %d €" % int(KC.f2.p))
	chk(cm.o[1][2] == "ctrlN" and D.ORDEN_RESERVA[C].any(func(c): return int(c[0]) == 2 and int(c[1]) == 2), "el cuadro en la pared del pasillo, con su casilla de delante reservada")
	# 2 · sin la licencia, cerrada
	chk(mundo("club-muelle", 15, 2) and J.MAPS["club-muelle"].o[1][15] == "puertaI", "en KAIA, la puerta")
	LOG = []
	chk(corre(func(): await J.object_action(15, 1)) and J.S.map == "club-muelle" and dicho("licencia"), "sin la licencia, cerrada")
	# 3 · con ella, dentro: vacía, sin carpas
	J.S.mar.lic = int(J.S.day)
	chk(corre(func(): await J.object_action(15, 1)) and J.S.map == C and J.P.x == 1 and J.P.y == 2, "con la licencia, dentro (%s %d,%d)" % [J.S.map, J.P.x, J.P.y])
	var m: Dictionary = J.MAPS[C]
	chk(not m.o.any(func(r): return r.any(func(c): return c != null and str(c).begins_with("carpa"))), "vacía: las carpas se compran")
	# 4 · el cuadro: un kit, por la cuenta, llega mañana
	J.S.banco = 0
	LOG = []
	QUIERO = ["Comprar:", "Comprarlo"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().kits.all(func(d): return int(d) < 0) and dicho("tarjeta no pasa"), "sin dinero en la cuenta, no")
	J.S.banco = 100000
	QUIERO = ["Comprar:", "Comprarlo"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().kits.filter(func(d): return int(d) >= 0).size() == 1 and is_equal_approx(float(J.S.banco), 100000.0 - kp), "comprado, por la cuenta (%d €)" % int(J.S.banco))
	chk(mundo(C, 1, 2) and m.o[3][13] == null, "hoy no está")
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][13] == "carpaKS0" and m.o[2][13] == "carpaG2" and m.o[2][14] == "carpaG2" and m.o[3][14] == "carpaG2" and m.o[4][13] == null, "mañana, montada en su sitio, 2 × 2")
	chk(J.sprite_local("carpaKS0") == "kcs", "la carpa, cerrada como las de casa, con el servicio del lado con más sitio en su sitio de serie: a la derecha, la de su depósito, que empatan (%s)" % J.sprite_local("carpaKS0"))
	chk(not MENUS.is_empty(), "el cuadro, con menú")
	TIT = []
	QUIERO = []
	MENUS = []
	corre(func(): await J.object_action(2, 1))
	chk(MENUS.size() and not MENUS.back().any(func(l): return str(l).begins_with("Montar la carpa de sala")) and MENUS.back().any(func(l): return str(l).begins_with("Pasar a la Carpa 400×200")), "en el primer nivel, pasar al siguiente, no la reforma: %s" % [MENUS.back() if MENUS.size() else []])
	for i in 3:
		QUIERO = ["Comprar:", "Comprarlo"]
		corre(func(): await J.object_action(2, 1))
	LOG = []
	TIT = []
	QUIERO = []
	corre(func(): await J.object_action(2, 1))
	chk(J.kc().kits.filter(func(d): return int(d) >= 0).size() == 4 and not MENUS.back().any(func(l): return str(l).begins_with("Comprar:")), "cuatro como mucho")
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][13] == "carpaKS0" and m.o[7][8] == "carpaKS1" and m.o[7][11] == "carpaKS2" and m.o[7][14] == "carpaKS3", "las cuatro, en su sitio")
	deps_ok(4, "las cuatro")
	LOG.clear()
	chk(corre(func(): await J.object_action(13, 6)) and dicho("depósito del goteo de la carpa 4"), "A en el depósito de la carpa 4: el suyo, fuera de ella")
	var v := alcance_d(C, 1, 2)
	for y in m.h:
		for x in m.w:
			if m.o[y][x] and m.o[y][x] != "carpaG2" and m.o[y][x] != "mesaKC2":
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [m.o[y][x], x, y])
	# 5 · nada encima de nada: ni las carpas ni lo de la pared
	var sl: Array = J.solapes_de(J.cajas_obj(C, m.o))
	chk(sl.is_empty(), "las cuatro carpas, sin solapes: %s" % [sl.slice(0, 3)])
	# 6 · la regla de la zona y la del solape
	chk(J.cabe_pieza(C, "kcs0", 1, 4) == "zona" and J.cabe_pieza(C, "kcs0", 2, 4) == "zona", "en el pasillo, no: «%s»" % J.cabe_pieza(C, "kcs0", 1, 4))
	chk(J.cabe_pieza(C, "kcs0", 4, 5) == "", "en la zona libre, sí: «%s»" % J.cabe_pieza(C, "kcs0", 4, 5))
	chk(J.cabe_pieza(C, "kcs3", 8, 8) == "solapa", "pegada delante de otra carpa, con su techo encima de ella, no: «%s»" % J.cabe_pieza(C, "kcs3", 8, 8))
	chk(J.cabe_pieza(C, "kcs2", 10, 5) == "solapa", "ni con su depósito debajo del techo de otra carpa: «%s»" % J.cabe_pieza(C, "kcs2", 10, 5))
	chk(J.cabe_pieza(C, "kcs2", 6, 6) == "servicio", "ni tapando el sitio de al lado de la puerta lateral de otra: «%s»" % J.cabe_pieza(C, "kcs2", 6, 6))
	chk(J.cabe_pieza(C, "kcs0", 9, 3) == "tubo", "ni dejando a una sin camino para su tubo hasta la pared: «%s»" % J.cabe_pieza(C, "kcs0", 9, 3))
	chk(str(D.ORDEN_MOTIVO.servicio).contains("puerta lateral") and str(D.ORDEN_MOTIVO.tubo).contains("tubo"), "los motivos del servicio y del tubo, dichos")
	# el lado de la puerta, donde se dejó: no cambia al mover otra
	J.S.coloca = {C: {"kcs2": [4, 3]}}
	J.MAPS[C].erase("opos")
	mundo(C, 1, 2)
	var L0: int = J.kc_lado(2)
	chk(J.kc().get("ld", {}).get("2") == [L0, 4, 3], "movida, su lado se guarda (%s)" % [J.kc().get("ld")])
	J.S.coloca[C]["kcs3"] = [7, 3]
	J.MAPS[C].erase("opos")
	mundo(C, 1, 2)
	chk(J.kc_lado_en(2, J.MAPS[C].o, J.kc_pos(2)) != L0 and J.kc_lado(2) == L0, "otra al lado: con más sitio por el otro, la puerta sigue donde estaba (%d → %d)" % [L0, J.kc_lado(2)])
	J.S.coloca = {}
	J.kc().erase("ld")
	J.MAPS[C].erase("opos")
	mundo(C, 1, 2)
	chk(J.kc_lado(2) == J.kc_lado_serie(2) and J.sprite_local("carpaKS2") == "kcs", "de serie, el de serie")
	chk(str(D.ORDEN_MOTIVO.zona).contains("zona de cultivo") and str(D.ORDEN_MOTIVO.solapa).contains("encima"), "los motivos, dichos")
	chk(J.cabe_pieza("home", "carpa0", 8, 2) != "zona", "las carpas de casa, sin la regla")
	mundo("club-muelle", 14, 3)
	var gr := []
	for y in int(J.MAPS["club-muelle"].h):
		for x in int(J.MAPS["club-muelle"].w):
			if J.MAPS["club-muelle"].o[y][x] == "jukebox":
				gr.append([x, y])
	chk(gr == [[14, 2]], "KAIA montado, una sola gramola, en (14, 2): %s" % [gr])
	mundo(C, 1, 2)
	TIT = []
	QUIERO = ["Ordenar la sala"]
	chk(corre(func(): await J.object_action(2, 1)) and TIT.has(D.ORDEN_P[C].n), "el cuadro ordena la sala (%s)" % [TIT])
	J.S.coloca = {C: {"kcs0": [0, 4]}}
	J.aplica_orden(C)
	chk(int(J.pos_pieza(C, "kcs0")[0]) >= 3, "una carpa guardada en el pasillo vuelve a la zona (%s)" % [J.pos_pieza(C, "kcs0")])
	J.S.coloca = {}
	J.MAPS[C].erase("opos")
	chk(mundo(C, 1, 2) and int(J.pos_pieza(C, "kcs0")[0]) == 13 and int(J.pos_pieza(C, "kcs0")[1]) == 2, "de serie, otra vez (%s)" % [J.pos_pieza(C, "kcs0")])
	# 7 · plantar en las plazas de una carpa, por cualquiera de sus casillas
	J.S.seeds = {"txoko": 3}
	QUIERO = ["Plaza 1", J.strain("txoko").n]
	MENUS = []
	LOG = []
	chk(corre(func(): await J.object_action(13, 3)) and J.kc().p[0] is Dictionary and J.kc().p[0].sid == "txoko" and int(J.S.seeds.get("txoko", 0)) == 2, "plantada en la plaza 1 (%s · %s · %s)" % [MENUS.slice(-3), J.kc().p.slice(0, 2), LOG.slice(-3)])
	chk(J.sprite_local("carpaKS0") == "kcs" and J.sprite_local("carpaKS1") == "kcsi", "con una planta, cerrada igual (las plantas, por dentro: kc_vista)")
	QUIERO = ["Plaza 4", J.strain("txoko").n]
	chk(corre(func(): await J.object_action(14, 2)) and J.kc().p[3] is Dictionary and J.kc_plantadas(0) == 2, "por la otra punta, la misma carpa, plaza 4")
	# 8 · crecen solas, con el goteo, también fuera de la sala
	chk(mundo("club-muelle", 15, 2), "fuera")
	if not (J.kc().p[0] is Dictionary):
		for f in fallos:
			print("  ✗ " + f)
		quit(1)
		return
	var p: Dictionary = J.kc().p[0]
	p.water = 20.0
	J.plants_advance(60)
	chk(float(p.prog) > 0 and is_equal_approx(float(p.water), 100.0), "crece y el goteo la riega (prog %.3f, agua %d)" % [float(p.prog), int(p.water)])
	var h := 0
	while float(p.prog) < 1 and h < 24 * 200:
		J.plants_advance(60)
		h += 1
	chk(float(p.prog) >= 1 and not p.get("dead") and float(p.health) > 50, "lista en %d días (salud %d)" % [h / 24, int(p.health)])
	var sd: float = float(J.strain("txoko").d)
	chk(h / 24.0 >= sd * .5 and h / 24.0 <= sd * 2.5, "a su ritmo: %.1f días para %.1f" % [h / 24.0, sd])
	# 9 · cosechar
	chk(mundo(C, 1, 2), "dentro otra vez")
	var g0 := 0.0
	for k in J.S.buds:
		g0 += float(J.S.buds[k].g)
	QUIERO = ["Plaza 1", "Cosechar"]
	LOG = []
	chk(corre(func(): await J.object_action(13, 3)) and J.kc().p[0] == null and dicho("Cosechas"), "cosechada")
	var g1 := 0.0
	for k in J.S.buds:
		g1 += float(J.S.buds[k].g)
	chk(g1 - g0 >= 60, "con sus dos LED, una buena planta: %d g" % int(g1 - g0))
	# 9b · los niveles conviven (lo pidió el usuario: «ir completando con las diferentes medidas la sala, con espacio para pasar entre
	# ellas»): pasar al siguiente compra la primera del tamaño nuevo y las de antes se quedan, con sus plantas
	var bn: float = float(J.S.banco)
	QUIERO = ["Pasar a la", "Comprarla"]
	chk(corre(func(): await J.object_action(2, 1)) and int(J.kc().niv) == 1 and int(J.kc().kits[4]) == int(J.S.day) + 1 and J.kc_kits() == 4 and J.kc().p[3] is Dictionary, "a las de 4 × 2: una pedida y las cuatro de 2 × 2 siguen (%s)" % [J.kc().kits])
	chk(is_equal_approx(float(J.S.banco), bn - kps[1]), "por la cuenta, solo la nueva (%d €)" % int(bn - J.S.banco))
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][3] == "carpaKM0" and m.o[2][6] == "carpaG2" and m.o[2][7] == "depKmd" and m.o[3][7] == null and m.o[3][13] == "carpaKS0" and J.sprite_local("carpaKM0") == "kcmi", "mañana, la de 4 × 2 en su sitio, con las de antes")
	# el lado del servicio (puerta lateral, ventana e intractor; kc_lado): el que tiene más casillas libres al lado a las que se llega
	# y, si empatan, el de su depósito, en su sitio de serie con las siete en el suyo; con el servicio a la izquierda, el sprite en
	# espejo (kcsi, kcmi). De serie, la 4.ª de 2 × 2, contra la pared de la sala, a la izquierda (al lado de su depósito queda una
	# casilla); la 3.ª, con los depósitos de la 2.ª y el suyo a la izquierda, a la derecha; la 2.ª, a la izquierda; la 1.ª, entre el
	# hueco de delante del depósito de la 2.ª de 4 × 2 y el de delante del suyo (1 y 1), a la derecha, la del suyo
	var lados := []
	for ci in J.kc_ns():
		if int(J.kc().kits[ci]) >= 0:
			var ob: String = String(J.kc_Nc(ci).obj) + str(J.kc_iN(ci))
			if J.sprite_local(ob).ends_with("i") != (J.kc_lado(ci) < 0):
				lados.append(ob)
	chk(lados.is_empty() and J.sprite_local("carpaKS3") == "kcsi" and J.sprite_local("carpaKS2") == "kcs" and J.sprite_local("carpaKS1") == "kcsi" and J.sprite_local("carpaKS0") == "kcs" and J.sprite_local("carpaKM0") == "kcmi", "el servicio de cada carpa, del lado con más sitio (%s)" % [lados])
	QUIERO = ["Comprar: Carpa 400×200", "Comprarlo"]
	corre(func(): await J.object_action(2, 1))
	J.S.day += 1
	chk(mundo(C, 1, 2) and m.o[3][8] == "carpaKM1" and J.solapes_de(J.cajas_obj(C, m.o)).is_empty(), "las dos de 4 × 2, sin solapes")
	var o5: int = J.kc_off(5)
	QUIERO = ["Plaza 8", J.strain("txoko").n]
	J.S.seeds = {"txoko": 3}
	chk(corre(func(): await J.object_action(11, 2)) and J.kc().p[o5 + 7] is Dictionary and J.kc_plantadas(5) == 1, "la segunda, por su otra punta, plaza 8")
	J.kc().p[o5 + 7] = null
	QUIERO = ["Pasar a la", "Comprarla"]
	corre(func(): await J.object_action(2, 1))
	J.S.day += 1
	chk(int(J.kc().niv) == 2 and mundo(C, 1, 2) and m.o[8][3] == "carpaKL0" and m.o[5][6] == "carpaG2" and J.kc_kits() == 7 and J.solapes_de(J.cajas_obj(C, m.o)).is_empty(), "la de 4 × 4 con las seis de antes, sin solapes")
	tubos_ok(7, "las siete carpas")
	deps_ok(7, "las siete carpas")
	MENUS = []
	QUIERO = []
	corre(func(): await J.object_action(2, 1))
	chk(MENUS.size() and not MENUS.back().any(func(l): return str(l).begins_with("Comprar") or str(l).begins_with("Pasar")) and MENUS.back().any(func(l): return str(l).begins_with("Montar la carpa de sala")), "con la sala llena, ya solo la carpa de sala: %s" % [MENUS.back() if MENUS.size() else []])
	v = alcance_d(C, 1, 2)
	for y in m.h:
		for x in m.w:
			if m.o[y][x] and m.o[y][x] != "carpaG2":
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [m.o[y][x], x, y])
	# 10 · la carpa de sala (lo pidió el usuario: «que la sala sea previamente una carpa»): con plantas, no; vacía, se paga, se venden
	# las siete de segunda mano y, a los días, la carpa que ocupa toda la zona, que se entra, con las 8 mesas dentro
	LOG = []
	QUIERO = ["Montar la carpa de sala"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().get("f2") == null and dicho("Antes, cosecha"), "con plantas en las carpas, aún no")
	J.kc().p[3] = null
	var b0: float = float(J.S.banco)
	QUIERO = ["Montar la carpa de sala", "Hacer la obra"]
	J.kc().kits.append(int(J.S.day) + 1)   # una carpa pagada que aún no ha llegado: primero que llegue, no se vende al 40 % sin montarla
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().get("f2") == null and dicho("espera a que llegue"), "con una carpa en camino, aún no")
	J.kc().kits.pop_back()
	QUIERO = ["Montar la carpa de sala", "Hacer la obra"]
	chk(corre(func(): await J.object_action(2, 1)) and J.kc().get("f2") != null and J.kc_kits() == 0, "la obra, en marcha")
	var ven := 0
	for ci in 7:
		ven += roundi(kps[[0, 0, 0, 0, 1, 1, 2][ci]] * float(KC.f2.venta))
	chk(is_equal_approx(float(J.S.banco), b0 - int(KC.f2.p) + ven), "por la cuenta, menos las siete de segunda mano (%d €)" % int(b0 - J.S.banco))
	chk(mundo(C, 1, 2) and not m.o.any(func(r): return r.any(func(c): return c != null and (str(c).begins_with("carpa") or str(c).begins_with("mesa")))), "en obras: ni carpas ni mesas")
	LOG = []
	chk(corre(func(): await J.object_action(2, 1)) and dicho("en obras"), "el cuadro lo dice")
	J.S.day += int(KC.f2.dias)
	var CX: Dictionary = KC.f2.carpa
	chk(mundo(C, 1, 2) and m.o[int(CX.def[1]) + int(CX.tam[1]) - 1][int(CX.def[0])] == "carpaKX" and m.o[int(CX.def[1])][int(CX.def[0]) + int(CX.tam[0]) - 1] == "carpaG2", "la carpa de sala, en toda la zona")
	tubos_ok(2, "la de sala")
	red_fuera(C)
	LOG = []
	chk(corre(func(): await J.object_action(int(KC.f2.fuera[0][0]), int(KC.f2.fuera[0][1]))) and dicho("rincón del riego"), "el rincón del riego lo dice")
	chk(alcance_d(C, 1, 2).has("%d,%d" % [int(KC.f2.fuera[0][0]) - 1, int(KC.f2.fuera[0][1])]), "y se llega a él")
	sl = J.solapes_de(J.cajas_obj(C, m.o))
	chk(sl.is_empty(), "la carpa de sala, sin solapes: %s" % [sl.slice(0, 3)])
	v = alcance_d(C, 1, 2)
	chk(delante(v, int(CX.puerta[0]), int(CX.puerta[1]) - 1) or delante(v, int(CX.puerta[0]), int(CX.puerta[1])), "se llega a su puerta")
	chk(J.pos_pieza(C, "kcs0") == [13, 2] and J.piezas_ya(C).is_empty(), "sin carpas que ordenar")
	var SA: String = KC.f2.sala
	chk(corre(func(): await J.object_action(int(CX.puerta[0]), int(CX.puerta[1]) - 1)) and J.S.map == SA and J.P.x == int(KC.f2.entra[0]) and J.P.y == int(KC.f2.entra[1]), "se entra en la carpa de sala (%s %d,%d)" % [J.S.map, J.P.x, J.P.y])
	var ms: Dictionary = J.MAPS[SA]
	chk(KC.f2.mesas.all(func(q): return ms.o[int(q[1])][int(q[0])] == "mesaKP" and ms.o[int(q[1])][int(q[0]) + 1] == "mesaKP2" and ms.o[int(q[1])][int(q[0]) + 2] == "mesaKP2"), "las ocho mesas de 240 cm, montadas en sus tres casillas")
	chk(ms.o[1][1] == "ctrlN" and KC.f2.ext.all(func(e): return ms.o[1][int(e)] == "extrG" and ms.o[1][int(e) - 1] == "filtroN"), "el cuadro y, en la pared de atrás, cada extractor con su filtro de carbón")
	sl = J.solapes_de(J.cajas_obj(SA, ms.o))
	chk(sl.is_empty(), "las mesas, sin solapes: %s" % [sl.slice(0, 3)])
	red_logica(SA, ms)
	v = alcance_d(SA, int(KC.f2.entra[0]), int(KC.f2.entra[1]))
	for y in ms.h:
		for x in ms.w:
			if ms.o[y][x] and ms.o[y][x] != "mesaKP2":
				chk(delante(v, x, y), "se llega a %s (%d, %d)" % [ms.o[y][x], x, y])
	LOG = []
	chk(corre(func(): await J.object_action(int(KC.f2.ext[0]), 1)) and dicho("filtro de carbón"), "el extractor lo dice")
	chk(mundo(SA, int(KC.f2.sale[0]), int(KC.f2.sale[1]) - 1), "dentro")
	# 11 · las mesas: plantar y, sin nadie, no avanzan
	QUIERO = ["Plantar", J.strain("txoko").n]
	chk(corre(func(): await J.object_action(1, 3)) and J.kc_me(0) is Dictionary and J.kc_me(0).k.begins_with("txoko"), "plantada la mesa 1")
	chk(J.mesa_de("mesaKP", 2, 3) != null and int(J.mesa_de("mesaKP", 2, 3).fm) == 1 and J.mesa_de("mesaKP", 2, 3).foco == "led", "en el mapa, con sus plantas y su foco")
	var p0 := float(J.kc_me(0).p)
	J.nave_dia()
	chk(is_equal_approx(float(J.kc_me(0).p), p0), "sin nadie que la lleve, no avanza")
	# 12 · quien lleva la sala
	var w := {"id": "plk", "n": "Iker", "lab": 3, "cui": 4, "lea": 4, "rol": null}
	J.S.plantilla = [w]
	chk(J.ops_staff(w).has("A la sala de KAIA"), "en la plantilla, la opción")
	corre(func(): await J.staff_op(w, "A la sala de KAIA"))
	chk(w.rol == "kaia" and J.kc_cultiva() == w and J.rol_txt(w) == "sala de KAIA" and J.rol_desc(w).contains("KAIA"), "a la sala")
	chk(J.local_staff(w) == "kaia" and J.nombre_local(J.local_staff(w)) == "La sala de KAIA", "en la plantilla, en su sala y no «Sin trabajo»: %s" % J.local_staff(w))
	chk(not J.ops_staff({"id": "x", "n": "Ane", "lab": 1, "cui": 1, "lea": 1, "rol": null}).has("A la sala de KAIA"), "uno solo")
	chk(mundo(SA, int(KC.f2.entra[0]), int(KC.f2.entra[1])) and J.ents.any(func(e): return e.id == "kcw"), "de pie en la sala")
	LOG = []
	chk(corre(func(): await J.npc_talk({"id": "kcw"})) and dicho("mesas"), "habla de las mesas")
	var mo0: float = float(J.S.money)
	J.S.money = 1000
	J.plantilla_dia()
	chk(is_equal_approx(float(J.S.money), 1000.0 - J.sueldo_w(w)) and J.sueldo_w(w) > 0, "cobra su sueldo (%d €)" % J.sueldo_w(w))
	J.S.money = mo0
	var d := 0
	while J.kc_me(0).get("h") == null and d < 200:
		J.S.day += 1
		J.nave_dia()
		d += 1
	chk(J.kc_me(0).get("h") != null and float(J.kc_me(0).h.g) >= 500 and int(J.kc_me(0).n) == 1, "cortada entera en %d días: %d g" % [d, int(J.kc_me(0).h.g)])
	chk(d >= int(J.strain("txoko").d) * .5, "a su ritmo")
	var a0: float = J.alm_g("muelle")
	J.S.day += int(D.NAVE.seca)
	J.nave_dia()
	chk(J.kc_me(0).get("h") == null and J.alm_g("muelle") > a0, "seca, al almacén de KAIA (%d g)" % int(J.alm_g("muelle") - a0))
	# lo que no cabe en el almacén, en la mesa, para llevártelo
	J.kc_me(0).h = {"g": float(D.MERCADO.alm.g) * 2, "t": 20.0, "d": J.S.day}
	J.S.day += int(D.NAVE.seca)
	J.nave_dia()
	chk(J.alm_g("muelle") <= float(D.MERCADO.alm.g) + .1 and float(J.kc_me(0).g) >= 1, "lo que no cabe, en la mesa (%d g)" % int(J.kc_me(0).g))
	var gm := float(J.kc_me(0).g)
	QUIERO = ["Llevarte lo seco"]
	chk(corre(func(): await J.object_action(1, 3)) and float(J.kc_me(0).g) < gm, "te lo llevas")
	# 12b · con las plantas crecidas, la copa no sube hasta el foco: pierde filas enteras y deja FOCO_AIRE px (la nave, con techo, igual)
	var At = load("res://src/atlas.gd")
	var Ar = load("res://src/arte.gd")
	var tope_ok := 0
	for q in D.KAIA_CULT.f2.mesas:
		var md = J.mesa_de("mesaKP", int(q[0]), int(q[1]))
		var ym: int = int(q[1]) * 16 + 15
		var tope: int = int(md.get("techo", 0)) + int(D.FOCO_POLEA) + 12 + int(D.FOCO_AIRE) + 1
		for fm in [2, 3, 4]:
			for po in ["i", "h", "s"]:
				var f = At.frame_de(At.cubre("obj:mesaN"), "plantasN-%d-%s" % [fm, po], "unica", 0, {"i": 0})
				if f == null:
					continue
				var o = J.pintor.copa_bajo_foco(f, ym, md)
				var top: int = ym - 47 + Ar.fila_arriba(o.c)
				var top0: int = ym - 47 + Ar.fila_arriba(f.c)
				chk(top >= tope and (top0 < tope or o.c == f.c) and o.c.get_size() == f.c.get_size(), "KAIA (%d, %d) %d-%s: la punta en %d, el foco hasta %d" % [q[0], q[1], fm, po, top, tope])
				chk(o.c.get_pixel(24, 46) == f.c.get_pixel(24, 46) and o.c.get_pixel(24, 47) == f.c.get_pixel(24, 47), "la base del tallo se queda")
				if top0 < tope:
					tope_ok += 1
	chk(tope_ok > 0, "la sativa en flor tocaba el foco antes")
	var mdn = {"foco": "led", "techo": 0}
	var fs = At.frame_de(At.cubre("obj:mesaN"), "plantasN-4-s", "unica", 0, {"i": 0})
	chk(J.pintor.copa_bajo_foco(fs, 4 * 16 + 15, mdn) == fs, "en la nave caben enteras")
	Datos.CAL = false
	chk(J.pintor.copa_bajo_foco(fs, 3 * 16 + 15, mdn) == fs, "sin CAL, como antes")
	Datos.CAL = true
	# 13 · las salas de antes: la de las tres carpas de regalo y la de los kits de 240 × 240, al nivel de las de 4 × 2 con sus plantas
	J.S.kc = {"p": [null, null, null, null, null, {"sid": "txoko", "prog": .3, "water": 50.0, "health": 100.0}]}
	chk(int(J.kc().niv) == 1 and J.kc_kits() == 2 and J.kc_tiene(4) and J.kc_tiene(5) and J.kc().p[J.kc_off(4)] is Dictionary and J.kc().p.size() == J.kc_off(J.kc_ns()), "la primera, pasada, en las de 4 × 2")
	var vj := []
	for i in 36:
		vj.append({"sid": "txoko", "prog": .3, "water": 50.0, "health": 100.0} if i == 30 else null)
	for i in 17:   # 18 plantas: caben 16
		vj[i] = {"sid": "txoko", "prog": .3, "water": 50.0, "health": 100.0}
	J.S.kc = {"kits": [0, 0, 0, int(J.S.day) + 1], "p": vj}
	var bco: float = J.S.banco
	var smv: int = int(J.S.seeds.get("txoko", 0))
	J.queued.clear()
	chk(int(J.kc().niv) == 1 and J.kc().kits == [-1, -1, -1, -1, 0, 0, -1] and J.kc().p[J.kc_off(4)] is Dictionary and J.kc_plantadas(4) == 8 and J.kc_plantadas(5) == 8, "la de los kits, pasada (%d + %d)" % [J.kc_plantadas(4), J.kc_plantadas(5)])
	chk(is_equal_approx(J.S.banco - bco, 2 * J.KC_KIT_VIEJO) and int(J.S.seeds.get("txoko", 0)) - smv == 2 and J.queued.has("kcmig"), "lo que no cabe, devuelto: %s € y %d semillas" % [J.S.banco - bco, int(J.S.seeds.get("txoko", 0)) - smv])
	J.queued.clear()
	J.pending.clear()
	# cada nivel rinde más por plaza que el de antes
	var gs := []
	for nv in 3:
		J.S.kc = {"niv": nv, "kits": [], "p": []}
		var cb: int = J.kc_base(nv)
		gs.append(float(J.kc_f(cb).g) * int(J.kc_Nc(cb).plazas) * int(J.kc_Nc(cb).max))
	chk(gs[0] < gs[1] and gs[1] < gs[2], "lleno, cada nivel rinde más: %s" % [gs])
	J.S.kc = {"kits": [], "p": [], "f2": 3, "m": []}
	chk(int(J.kc().niv) == 0 and J.kc().get("f2") == 3, "la reformada, igual")
	# 13b · la sala reformada de antes, con seis mesas: las suyas siguen en su sitio y las dos que faltan, vacías (kc)
	var m6 := []
	for i in 6:
		m6.append({"k": "txoko", "p": .1 * (i + 1), "dia": 1, "g": 0, "t": 0, "abo": 1, "dn": 0, "am": 0, "ao": 0, "n": 0})
	J.S.kc = {"niv": 2, "kits": [], "p": [], "v": 2, "f2": 3, "m": m6.duplicate()}
	var m8: Array = J.kc().m
	chk(m8.size() == KC.f2.mesas.size() and m8.size() == 8 and m8.slice(0, 6) == m6 and m8[6] == null and m8[7] == null, "de seis mesas a ocho: las seis con lo suyo y dos vacías (%d)" % m8.size())
	chk(J.kc().m.size() == 8 and J.kc_me(5) != null and J.kc_me(6) == null and J.kc_fase(6) == 0, "otra vez, igual: ocho")
	# 14 · sin CAL, nada
	Datos.CAL = false
	chk(J.puertas_int("club-muelle").is_empty() and J.sprite_local("carpaKS0") == "carpaKS0" and not J.kc_hay(), "sin CAL, ni la puerta ni la sala")
	Datos.CAL = true
	print("kaia_cult: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
