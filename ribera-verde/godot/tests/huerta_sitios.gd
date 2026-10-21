# Landrace Hunters (Godot) — las plantas de la huerta en el suelo (lo pidió el usuario: «El cultivo tiene que ser igual que en la nave
# digamos, pero solo que no hay focos, está únicamente la luz del sol. No van por macetas sino que se plantan en el suelo pero se hacen
# más grandes cada planta y la distancia de una a otra es de una baldosa, en los bancales que has hecho en el mapa, bien centradas…
# Los tubos no están muy centrados que digamos no? Ajustalos bien a los bancales»), con Datos.CAL: cada sitio, un bloque de 2 × 2
# casillas dentro de su bancal, dos por bancal con una casilla libre en medio y simétricos; la planta (hg-<porte>-<fase>) con el pie en
# el centro del bloque, más grande que una de la mesa de la nave y con los colores de su variedad; las otras tres casillas, sólidas; A
# en cualquiera de las cuatro es el sitio; los tubos del goteo por el medio del camino y de cada fila de bancales, con el mismo margen a
# los dos lados y dentro de la tierra que se ve, y un gotero en el centro de cada sitio; y el plano de cerca, al sol y en la tierra.
#   $GODOT --headless --path godot --script res://tests/huerta_sitios.gd   → «huerta_sitios: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Pintor = preload("res://src/pinta.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var M
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
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
			return false
	return true

# lo que pinta el gesto k (sus sprites, por orden) y sus rectángulos de color
func gesto(k: String, t: float) -> Array:
	return J.rects_acceso({"k": k, "c": "", "ok": true, "t0": 0.0, "pl": {}, "sol": J.gesto_sol()}, t)

func nombres(R: Array) -> Array:
	return R.filter(func(e): return typeof(e[0]) == TYPE_STRING and typeof(e[1]) == TYPE_STRING).map(func(e): return String(e[1]))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-huerta-sitios.json"
	Juego.AJUSTES = "user://prueba-huerta-sitios-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = Datos.carga()
	Atlas.carga()
	var S: Dictionary = J.S
	S.mode = "world"
	J.mode = "world"
	var H: Dictionary = J.HUERTA
	# 1 · los sitios: un bloque de 2 × 2 dentro de su bancal, dos por bancal, una casilla libre en medio y simétricos
	var por_bancal := {}
	for i in H.sitios.size():
		var bl: Array = J.huerta_bloque(i)
		chk(bl.size() == 4, "sitio %d: 4 casillas (%s)" % [i, bl])
		var dentro := -1
		for k in H.bancales.size():
			var b: Array = H.bancales[k]
			if bl.all(func(c): return int(c[0]) >= int(b[0]) and int(c[0]) <= int(b[2]) and int(c[1]) >= int(b[1]) and int(c[1]) <= int(b[3])):
				dentro = k
		chk(dentro >= 0, "sitio %d, dentro de un bancal (%s)" % [i, bl])
		if dentro >= 0:
			por_bancal[dentro] = por_bancal.get(dentro, []) + [i]
	for k in H.bancales.size():
		var b: Array = H.bancales[k]
		var ss: Array = por_bancal.get(k, [])
		chk(ss.size() == 2, "bancal %d: dos sitios (%s)" % [k, ss])
		chk(int(b[3]) - int(b[1]) == 1, "bancal %d: dos filas, las de los bloques" % k)
		if ss.size() == 2:
			var a: Array = H.sitios[ss[0]]
			var c: Array = H.sitios[ss[1]]
			var x1: int = mini(int(a[0]), int(c[0]))
			var x2: int = maxi(int(a[0]), int(c[0]))
			chk(x2 - (x1 + 2) == 1, "bancal %d: una baldosa libre entre las dos plantas (%d)" % [k, x2 - (x1 + 2)])
			var bcx: int = (int(b[0]) + int(b[2]) + 1) * 8   # el centro del bancal, en px
			var bcy: int = (int(b[1]) + int(b[3]) + 1) * 8
			chk((x1 + 1) * 16 + (x2 + 1) * 16 == 2 * bcx, "bancal %d: las dos plantas, simétricas en el bancal (%d, %d; %d)" % [k, (x1 + 1) * 16, (x2 + 1) * 16, bcx])
			chk(int(a[1]) * 16 == bcy and int(c[1]) * 16 == bcy, "bancal %d: el pie de las plantas, en la línea del medio (%d)" % [k, bcy])
	var filas := {}
	for b in H.bancales:
		filas[int(b[1])] = int(b[3])
	var fk: Array = filas.keys()
	fk.sort()
	for j in range(1, fk.size()):
		chk(int(fk[j]) - int(filas[fk[j - 1]]) - 1 == 1, "entre filas de bancales, una baldosa libre (%d → %d)" % [filas[fk[j - 1]], fk[j]])
	# 2 · el mapa con lo plantado: el dibujo en la casilla de abajo a la izquierda, hgx en las otras tres; sólidas las cuatro
	var B: Array = D.BANCO
	var sids := [String(B[0][0]), String(B[1][0]), String(B[2][0])]
	var L := []
	for i in H.sitios.size():
		if i in [1, 3, 6]:
			L.append(null)
			continue
		var p: Dictionary = Cultivo.nueva_planta(S, sids[i % 3])
		p.prog = [.05, .2, .4, .5, .8, .95, 1.0, 1.0][i]
		L.append(p)
	S.huerta = {"v": 1, "l": 1, "p": L, "m": {"goteo": 1, "ibc": 2}, "agua": 500.0, "t": [0, 0, 0, 0, 0, 0, 0, 0], "ped": []}
	var ll: Array = H.llega
	J.enter_map("huerta", int(ll[0]), int(ll[1]), "up")
	var m: Dictionary = J.MAPS.huerta
	for i in H.sitios.size():
		var s: Array = H.sitios[i]
		var bl: Array = J.huerta_bloque(i)
		var ab = m.o[int(s[1])][int(s[0])]
		if L[i] == null:
			chk(ab == "hgx", "sitio %d vacío: hgx, sin dibujo (%s)" % [i, ab])
		else:
			chk(String(ab) == "hg-%s-%d" % [Datos.porte_planta(S, L[i]), [1, 2, 3, 3, 4, 4, 5, 5][i]], "sitio %d: hg-<porte>-<fase> (%s)" % [i, ab])
		chk(bl.slice(1).all(func(c): return m.o[int(c[1])][int(c[0])] == "hgx"), "sitio %d: las otras tres, hgx" % i)
		chk(bl.all(func(c): return J.tile_solid(m, int(c[0]), int(c[1]))), "sitio %d: las cuatro, sólidas" % i)
		chk(bl.all(func(c): return J.huerta_idx(int(c[0]), int(c[1])) == i), "sitio %d: A en cualquiera de las cuatro es el sitio" % i)
		chk(Atlas.cubre("obj:hgx") == null, "hgx no tiene dibujo")
	var libres := 0
	for b in H.bancales:
		for y in range(int(b[1]), int(b[3]) + 1):
			for x in range(int(b[0]), int(b[2]) + 1):
				if J.huerta_idx(x, y) < 0:
					libres += 1
					chk(m.o[y][x] == null, "la casilla libre del bancal (%d, %d), sin nada" % [x, y])
	chk(libres == 2 * H.bancales.size(), "una columna libre por bancal (%d casillas)" % libres)
	# se llega a cada sitio (una casilla del bloque junto a una que se pisa)
	var vis := {Vector2i(int(ll[0]), int(ll[1])): true}
	var cola := [Vector2i(int(ll[0]), int(ll[1]))]
	while cola.size():
		var c: Vector2i = cola.pop_front()
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var v: Vector2i = c + dd
			if v.x < 0 or v.y < 0 or v.x >= int(m.w) or v.y >= int(m.h) or vis.has(v) or J.tile_solid(m, v.x, v.y):
				continue
			vis[v] = true
			cola.append(v)
	for i in H.sitios.size():
		var junto: bool = J.huerta_bloque(i).any(func(c): return [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)].any(func(dd): return vis.has(Vector2i(int(c[0]), int(c[1])) + dd)))
		chk(junto, "se llega al sitio %d" % i)
	# plantar desde la casilla de arriba a la derecha de un sitio vacío
	var s3: Array = H.sitios[3]
	S.seeds = {sids[0]: 2}
	QUIERO = [J.strain(sids[0]).n]
	chk(corre(func(): await J.object_action(int(s3[0]) + 1, int(s3[1]) - 1)), "A en la casilla de arriba a la derecha del sitio 3")
	chk(J.huerta_s().p[3] is Dictionary and String(J.huerta_s().p[3].sid) == sids[0], "plantada en el sitio 3: %s" % [J.huerta_s().p[3]])
	chk(String(m.o[int(s3[1])][int(s3[0])]).begins_with("hg-"), "y se ve en su sitio: %s" % m.o[int(s3[1])][int(s3[0])])
	# 3 · el dibujo: tres portes y cinco fases, con el pie en el centro del bloque; más grande que una de la mesa de la nave
	var fm = Atlas.frame_de(Atlas.cubre("obj:mesaN"), "plantasN-4-h", "unica", 0, {"i": 0})
	var wm: int = Arte_ancho(fm.c) if fm else 0
	for po in ["i", "h", "s"]:
		for fa in range(1, 6):
			var k := "hg-%s-%d" % [po, fa]
			chk(Atlas.cubre("obj:" + k) == "huerta-pl", "%s, en el atlas (huerta-pl)" % k)
			var f = Atlas.frame_de("huerta-pl", k, "unica", 0, {"i": 0})
			chk(f != null, "%s: su dibujo" % k)
			if f == null:
				continue
			var an: Array = f.cel.ancla
			chk(f.c.get_size() == Vector2i(48, 64) and int(an[0]) == 16 and int(an[1]) == 55, "%s: 48 × 64 con el ancla en (16, 55) (%s, %s)" % [k, f.c.get_size(), an])
			# en la casilla (x, y) se pinta en (x·16 + 8 − 16, y·16 + 15 − 55): el pie (24, 40) cae en ((x + 1)·16, y·16)
			chk(8 - int(an[0]) + 24 == 16 and 15 - int(an[1]) + 40 == 0, "%s: el pie en el centro del bloque" % k)
			var u: Rect2i = f.c.get_used_rect()
			var cx: float = u.position.x + u.size.x / 2.0
			if fa >= 2:
				chk(absf(cx - 24) <= 1.5, "%s: centrada en el pie (centro %.1f)" % [k, cx])
				chk(u.end.y <= 63 and u.end.y >= 41, "%s: el pie en la tierra (abajo en %d)" % [k, u.end.y])
			if fa >= 3:   # lo pidió el usuario: «las plantas deben estar también en medio de los bancales»: la mata, centrada en el pie
				var cy: float = u.position.y + u.size.y / 2.0
				chk(absf(cy - 40) <= 2.5, "%s: en medio de su bancal (centro %.1f, el pie en 40)" % [k, cy])
			if fa == 5:
				chk(u.size.x >= 32 and u.size.x <= 40, "%s: la planta hecha ocupa su bloque, con hueco hasta la de al lado (%d px)" % [k, u.size.x])
				chk(wm > 0 and u.size.x > 2 * wm / 3, "%s: más grande que una de la mesa de la nave (%d > %d)" % [k, u.size.x, 2 * wm / 3])
	# el color de su variedad, como las de la nave
	if J.pintor != null:
		var f5 = Atlas.frame_de("huerta-pl", "hg-h-5", "unica", 0, {"i": 0})
		var pa: Dictionary = Cultivo.nueva_planta(S, sids[0])
		var pb: Dictionary = Cultivo.nueva_planta(S, sids[1])
		var ta: Image = J.pintor._tinte_planta(f5, pa).c
		var tb: Image = J.pintor._tinte_planta(f5, pb).c
		chk(ta.get_data() != f5.c.get_data(), "con el color de su variedad (%s)" % sids[0])
		chk(Datos.color_cog(S, pa) == Datos.color_cog(S, pb) or ta.get_data() != tb.get_data(), "dos variedades, dos colores")
		# el bancal, con su canto también junto al camino de tierra (con CAL, _mascara): la casilla de arriba a la derecha del bancal 0
		var bc: Array = H.bancales[0]
		var mh: Dictionary = J.MAPS.huerta
		chk(String(mh.g[int(bc[1])][int(bc[2])]) in ["surco", "surcoV"] and mh.g[int(bc[1])][int(bc[2]) + 1] == "dirt", "el bancal 0 da al camino: %s" % [mh.g[int(bc[1])].slice(int(bc[2]), int(bc[2]) + 2)])
		chk(J.pintor._mascara(mh, int(bc[2]), int(bc[1])) & 8 != 0, "el bancal, con su canto junto al camino (máscara %d)" % J.pintor._mascara(mh, int(bc[2]), int(bc[1])))
	else:
		chk(false, "sin pintor")
	# 4 · los tubos del goteo, centrados
	var tbs: Dictionary = Pintor.tubos_huerta(H, J.HUERTA_MEJ, 2)
	var cam_x: int = int(H.camino) * 16 + 16   # el medio del camino de 2 casillas
	var tronco: Array = tbs.v.filter(func(q): return int(q[0]) + 1 == cam_x)
	chk(tronco.size() == 1, "el tronco, por el medio del camino (%s)" % [tbs.v])
	var x0 := 9999
	var x1 := 0
	for b in H.bancales:
		x0 = mini(x0, int(b[0]) * 16)
		x1 = maxi(x1, (int(b[2]) + 1) * 16)
	var ramales: Array = tbs.h.filter(func(q): return int(q[0]) > x0 - 1 and int(q[1]) < x1 and int(q[1]) - int(q[0]) > 100)
	chk(ramales.size() == filas.size(), "un ramal por fila de bancales (%d)" % ramales.size())
	for q in ramales:
		var mi: int = int(q[0]) - x0
		var md: int = x1 - 1 - int(q[1])
		chk(mi == md, "el ramal, con el mismo margen a los dos lados (%d, %d)" % [mi, md])
		chk(mi >= 8, "y dentro de la tierra que se ve: la hierba de la orilla tapa 6 px (%d)" % mi)
		var en_medio := false
		for f in filas:
			en_medio = en_medio or int(q[2]) + 1 == (int(f) + int(filas[f]) + 1) * 8
		chk(en_medio, "el ramal, en la línea del medio de su fila de bancales (y %d)" % (int(q[2]) + 1))
		chk(int(q[0]) < cam_x and int(q[1]) > cam_x, "el ramal cruza el camino")
	if tronco.size() == 1:
		var ult := 0
		for q in ramales:
			ult = maxi(ult, int(q[2]) + 1)
		chk(int(tronco[0][2]) == ult, "el tronco llega al último ramal (%d, %d)" % [tronco[0][2], ult])
		var bo: Array = J.HUERTA_MEJ.goteo.x[0]
		chk(int(tronco[0][1]) + 1 == (int(bo[1]) + 1) * 16 + 8, "la principal, por el medio de la fila de debajo de la bomba")
	chk(tbs.g.size() == H.sitios.size(), "un gotero por sitio")
	for i in mini(tbs.g.size(), H.sitios.size()):
		var s: Array = H.sitios[i]
		chk(int(tbs.g[i][0]) + 1 == (int(s[0]) + 1) * 16 and int(tbs.g[i][1]) + 1 == int(s[1]) * 16, "el gotero %d, en el centro del sitio" % i)
	# 5 · el plano de cerca: en la huerta, al sol y en la tierra; en casa, la carpa y la maceta
	for q in ["misc:gs-f-huerta", "misc:gs-tierra", "misc:gs-tierra-m"]:
		chk(Atlas.cubre(q) == "gestos", "%s, en el atlas" % q)
	S.map = "huerta"
	chk(J.gesto_sol(), "en la huerta, el plano al sol")
	var gy: int = (J.SH - J.GS_H) >> 1
	for q in [["regar", 600.0, "gs-planta"], ["tratar", 600.0, "gs-planta"], ["abonar", 600.0, "gs-planta"], ["plantar", 900.0, "gs-brote"],
			["sembrar", 600.0, "gs-semilla"], ["esqueje", 300.0, "gs-planta"], ["cosechar", 700.0, "gs-planta"], ["polen", 600.0, "gs-planta"]]:
		var R := gesto(q[0], q[1])
		var ns := nombres(R)
		chk("gs-f-huerta" in ns and not ("gs-f-carpa" in ns), "%s en la huerta: al sol (%s)" % [q[0], ns])
		chk(not ns.any(func(x): return x.begins_with("gs-maceta")), "%s en la huerta: sin maceta" % q[0])
		var it := []
		var ip := -1
		for i in R.size():
			var em: Array = R[i]
			if typeof(em[0]) == TYPE_STRING and typeof(em[1]) == TYPE_STRING:
				if String(em[1]).begins_with("gs-tierra"):
					it.append(i)
				elif String(em[1]).begins_with(q[2]) and ip < 0:
					ip = i
		var bien: bool = it.size() == 2 and ip > it[0] and ip < it[1]
		if bien:
			bien = (R[it[0]][4] as Rect2i).end.y == (R[it[1]][4] as Rect2i).position.y and (R[it[0]][4] as Rect2i).end.y == gy + 60 + J.GS_MAC_CORTE
		chk(bien, "%s en la huerta: %s entre las dos mitades de la tierra (%s, %d)" % [q[0], q[2], it, ip])
	var Rp := gesto("plantar", 900.0)
	chk(not Rp.any(func(e): return typeof(e[0]) != TYPE_STRING and e.size() > 4 and String(e[4]) in ["#3e2c1e", "#56402a"]), "plantar en la huerta: la tierra que aprieta, la del bancal")
	S.map = "home"
	chk(not J.gesto_sol(), "en casa, no")
	var Rc := gesto("regar", 600.0)
	var nc := nombres(Rc)
	chk("gs-f-carpa" in nc and nc.filter(func(x): return x.begins_with("gs-maceta")).size() == 2 and not ("gs-f-huerta" in nc), "en casa: la carpa y la maceta (%s)" % [nc])
	Datos.CAL = false
	S.map = "huerta"
	chk(not J.gesto_sol(), "sin CAL, no")
	Datos.CAL = true
	print("huerta_sitios: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)

func Arte_ancho(im: Image) -> int:   # el ancho de lo pintado
	return im.get_used_rect().size.x
