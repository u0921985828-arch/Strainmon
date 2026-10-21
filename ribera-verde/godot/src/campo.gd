# MAESTRO [4] (con Datos.CAL): la carretera comarcal entre Mendialde y Errotabarri (CAMPO), las landraces salvajes de su claro y el
# caserío abandonado como refugio (dormir y esconder lo que lleves; la redada no llega). La botritis, en granja.gd; el control de
# carretera, en eventos.gd (control_trafico).
# Cadena: … → eventos → campo → retencion → juego.
extends "res://src/eventos.gd"

func campo_ok() -> bool:
	return Datos.CAL and D.has("CAMPO") and S != null and int(S.ch) >= int(D.CAMPO.ch)

func campo_s() -> Dictionary:
	if not (S.get("campo") is Dictionary):
		S.campo = {"r": {}, "ref": {}}
	return S.campo

# las salidas de lado de Mendialde y Errotabarri a la comarcal (por la carretera y por la pista) y, en la comarcal, sus salvajes
func montar_campo(mapa: String) -> void:
	if not Datos.CAL or not D.has("CAMPO") or S == null:
		return
	var C: Dictionary = D.CAMPO
	if C.puertas.has(mapa):
		var m: Dictionary = MAPS[mapa]
		for q in C.puertas[mapa]:
			var k := "%d,%d" % [int(q[0]), int(q[1])]
			if campo_ok():
				var der: bool = int(q[0]) > 0
				m.exits[k] = {"to": C.mapa, "x": int(q[2]), "y": int(q[3]), "dir": "right" if der else "left", "lado": "right" if der else "left"}
			else:
				m.exits.erase(k)
	if mapa != C.mapa:
		return
	var mc: Dictionary = MAPS[C.mapa]
	for i in C.sitios.size():
		var s: Array = C.sitios[i]
		var w := salvaje(i)
		mc.o[int(s[1])][int(s[0])] = sprite_salvaje(w) if not w.is_empty() else null

# la red de carreteras (lo pidió el usuario: «no hay más caminos entre los demás pueblos? Habría que crearlos»; la red completa):
# siete carreteras que se andan como la comarcal (MAPS carr-*, de tools/carreteras.py), abiertas cuando sus dos pueblos tienen
# autobús (CARRETERAS.rutas[*].ch). En cada pueblo, la casilla del borde pasa a suelo sin estorbo y lleva a su carretera; sin CAL
# o sin abrir, el borde como estaba (CARR_ORIG)
static var CARR_ORIG := {}

func carretera_ok(id: String) -> bool:
	return Datos.CAL and D.has("CARRETERAS") and S != null and D.CARRETERAS.rutas.has(id) and int(S.ch) >= int(D.CARRETERAS.rutas[id].ch)

func montar_carreteras(mapa: String) -> void:
	if not D.has("CARRETERAS") or not MAPS.has(mapa):
		return
	var C: Dictionary = D.CARRETERAS
	if not C.puertas.has(mapa):
		return
	var m: Dictionary = MAPS[mapa]
	var abiertas := {}
	for q in C.puertas[mapa]:
		var k := "%d,%d" % [int(q[0]), int(q[1])]
		if carretera_ok(String(q[2])):
			abiertas[k] = true
			m.exits[k] = {"to": String(q[2]), "x": int(q[3]), "y": int(q[4]), "dir": "right" if int(q[3]) <= 1 else "left", "lado": String(q[5])}
		elif m.exits.has(k) and String(m.exits[k].to) == String(q[2]):
			m.exits.erase(k)
	for c in C.abre.get(mapa, []):   # [x, y, la salida que la abre]: la del norte de Errotabarri pasa por la fila 1
		var x := int(c[0])
		var y := int(c[1])
		var k := "%d,%d" % [x, y]
		var ko := mapa + "|" + k
		if abiertas.has("%d,%d" % [int(c[2]), int(c[3])]):
			if not CARR_ORIG.has(ko):
				CARR_ORIG[ko] = [m.g[y][x], m.o[y][x]]
			var dx := 1 if x == 0 else (-1 if x == int(m.w) - 1 else 0)
			var dy := 1 if y == 0 else (-1 if y == int(m.h) - 1 else 0)
			var g: String = String(m.g[y + dy][x + dx])
			m.g[y][x] = g if not SOLID_G.search(g) else "grass"
			m.o[y][x] = null
		elif CARR_ORIG.has(ko):
			m.g[y][x] = CARR_ORIG[ko][0]
			m.o[y][x] = CARR_ORIG[ko][1]
			CARR_ORIG.erase(ko)

# la planta salvaje del sitio i esta semana: {sid, t} (t: «sem», madura con semillas; «esq», en vegetativo, para esquejes) o {}.
# Según el clima: en invierno no hay; con tormenta o nieve, ese día no se ve; y lo recogido no vuelve hasta CAMPO.vuelve días
func salvaje(i: int) -> Dictionary:
	if not campo_ok():
		return {}
	var C: Dictionary = D.CAMPO
	var r = campo_s().r.get(str(i))
	if r != null and S.day - int(r) < int(C.vuelve):
		return {}
	if Datos.tiempo(S.day, 720).k in C.no:
		return {}
	var mes := float(Datos.fecha(S.day).m)   # los números de datos.json son float
	var t := "sem" if mes in C.sem else ("esq" if mes in C.esq else "")
	if t == "":
		return {}
	var wk: int = int(S.day) / 7
	if Datos.hash_str("salv%d_%d" % [wk, i]) % 100 >= int(float(C.p) * 100):
		return {}
	var B: Array = D._base.BANCO if D.has("_base") else D.BANCO
	return {"sid": String(B[Datos.hash_str("salvsid%d_%d" % [wk, i]) % B.size()][0]), "t": t}

func sprite_salvaje(w: Dictionary) -> String:
	var ind: float = float(Datos.ind_de(S, w.sid))
	return "hp%d-%d" % [0 if ind >= 70 else (1 if ind <= 30 else 2), 5 if w.t == "sem" else 3]   # i18n-no

func campo_obj(x: int, y: int, o) -> bool:
	if await huerta_obj(x, y, o):   # la huerta de la tía
		return true
	if not Datos.CAL or not D.has("CAMPO"):
		return false
	var C: Dictionary = D.CAMPO
	if S.map == C.mapa and o is String and o.begins_with("hp"):
		for i in C.sitios.size():
			if int(C.sitios[i][0]) == x and int(C.sitios[i][1]) == y:
				await recoger_salvaje(i)
				return true
	if S.map == C.refugio.map:
		if o == C.refugio.caja:
			await escondite()
			return true
		if o == "bedT" or o == "bedB":   # i18n-no
			await bed_action(K("Un camastro con una manta de lana. Aquí no te busca nadie."))
			return true
		if o == "table":
			await say(K("Una mesa de castaño con un candil. Alguien dejó un mapa de la comarca con los claros marcados en lápiz."))
			return true
		if o == "iwin":
			await say(K("Por la ventana, la carretera comarcal y el monte."))
			return true
	return false

func recoger_salvaje(i: int) -> void:
	var w := salvaje(i)
	if w.is_empty():
		return
	var s = strain(w.sid)
	if w.t == "sem":
		var C: Dictionary = D.CAMPO
		var nn: int = int(C.n[0]) + Datos.hash_str("salvn%d_%d" % [S.day, i]) % (int(C.n[1]) - int(C.n[0]) + 1)
		if await ask(T("Una {s} salvaje, madura y con semillas en los cogollos.", {"s": s.n}), [K("Recoger semillas"), K("Dejarla")]) != 0:
			return
		await gesto("cosechar")
		add_seeds(w.sid, nn)
		campo_s().r[str(i)] = S.day
		sfx("get")
		await say(T("Sacas {n} semillas puras de {s}. Van con las demás, para plantar o cruzar.", {"n": nn, "s": s.n}))
	else:
		if await ask(T("Una {s} salvaje en pleno crecimiento.", {"s": s.n}), [K("Sacar esqueje"), K("Dejarla")]) != 0:
			return
		if S.esquejes.size() >= 12:
			await say(K("El propagador está lleno: 12 esquejes. Planta alguno antes."))
			return
		await gesto("esqueje")
		S.esquejes.append({"sid": w.sid, "f": roll_feno(w.sid), "dia": S.day})
		discover(w.sid)
		campo_s().r[str(i)] = S.day
		sfx("get")
		await say(T("Cortas una punta de la {s} y la envuelves en papel húmedo. Plántala antes del {d}.", {"s": s.n, "d": Datos.fd(S.day + D.ESQUEJE_DIAS + 1, S.day)}))
	MAPS[S.map].o[int(D.CAMPO.sitios[i][1])][int(D.CAMPO.sitios[i][0])] = null

# el arcón del caserío: lo que escondes aquí no lo encuentran ni la redada ni Darko
func escondite() -> void:
	var R: Dictionary = campo_s().ref
	while true:
		var gl := 0.0
		for k in R:
			gl += float(R[k].g)
		var c: int = await ask(T("Un arcón de madera bajo unos sacos. Dentro: {g}.", {"g": g_txt(gl)}), [K("Esconder lo que llevo"), K("Sacarlo todo"), K("Nada")])
		if c == 0:
			var n_ := 0
			for k in S.buds.keys():
				if float(S.buds[k].g) >= 1:
					mover_lote(S.buds, R, k, float(S.buds[k].g))
					n_ += 1
			await say(K("Lo metes en el arcón y lo tapas con los sacos.") if n_ else K("No llevas cogollos encima."))
		elif c == 1:
			if R.is_empty():
				await say(K("El arcón está vacío."))
				continue
			for k in R.keys():
				mover_lote(R, S.buds, k, float(R[k].g))
			await say(K("Lo sacas todo del arcón y lo guardas en la mochila."))
		else:
			return

# ---------- la huerta abandonada de la tía (lo pidió el usuario: «encontrar la huerta abandonada de al lado de casa, en el pueblo,
# para poder cultivar ahí en exterior»; con Datos.CAL) ----------
# Detrás del garaje, entre las zarzas del monte (town 9,1), una cancilla: con A, te abres paso y queda una senda con la puerta a la
# huerta (MAPS.huerta, hecho aquí: 30 × 12, el monte alrededor y, dentro del seto, cuatro bancales y un camino; la huerta, de 16 × 10,
# en medio para que la cámara no vea fuera del mapa). Desbrozada (HUERTA.desbroce minutos), ocho sitios en tierra:
# se plantan, riegan, abonan, tratan y cosechan como las macetas (pot_action con hu), al raso: crecen con la temperatura del
# día (Datos.tiempo), en vegetativo dentro de HUERTA.veg (del 20 de abril al 5 de agosto) y florecen fuera; cuantos más días en
# vegetativo, más gramos (HUERTA.g, hasta HUERTA.cap). La lluvia las riega; la helada y la nieve les quitan salud; con lluvia en
# floración, la botritis. Sin luz que pagar ni olor en casa. S.huerta: {v: el día que la encontraste, l: el que la desbrozaste,
# p: las plantas de los sitios}
const HUERTA := {"mapa": "huerta", "w": 30, "h": 12, "seto": [7, 1, 22, 10], "camino": 14, "puerta": [9, 1], "senda": [[9, 0], [9, 2]], "llega": [15, 9], "sale": [9, 2],   # i18n-no
	"sitios": [[10, 4], [12, 4], [17, 4], [19, 4], [10, 8], [12, 8], [17, 8], [19, 8]], "bancales": [[9, 4, 13, 5], [16, 4, 20, 5], [9, 7, 13, 8], [16, 7, 20, 8]],
	"atrezo": [[8, 3, "bidonT"], [8, 9, "cuboS"], [21, 3, "manzano"], [21, 9, "crate"], [20, 9, "sacos"]],   # i18n-no
	"desbroce": 240, "riego": 30, "veg": [420, 805], "g": 250, "cap": 500, "veg_dias": 60,
	"agua": [.2, .2, .3, .35, .45, .6, .7, .7, .5, .35, .25, .2], "plaga": 1.2, "helada": 25, "nieve": 50}
var _town19 = null   # lo que había en town en la cancilla y la senda, para dejarlo como estaba sin CAL

func huerta_s() -> Dictionary:
	if not (S.get("huerta") is Dictionary):
		S.huerta = {"v": 0, "l": 0, "p": []}
	var h: Dictionary = S.huerta
	while h.p.size() < HUERTA.sitios.size():
		h.p.append(null)
	return h

func huerta_vista() -> bool:   # ¿la has encontrado?
	return Datos.CAL and S != null and S.get("huerta") is Dictionary and int(S.huerta.get("v", 0)) > 0

func huerta_lista() -> bool:   # ¿desbrozada?
	return huerta_vista() and int(S.huerta.get("l", 0)) > 0

func montar_huerta(k: String) -> void:
	if k == "town" and MAPS.has("town"):
		var m: Dictionary = MAPS.town
		var q: Array = HUERTA.puerta
		var cs: Array = [q] + HUERTA.senda   # la cancilla y la senda que lleva a ella, de tierra pisada
		if _town19 == null:
			_town19 = cs.map(func(c): return [m.g[c[1]][c[0]], m.o[c[1]][c[0]]])
		var kq := "%d,%d" % [q[0], q[1]]
		for i in cs.size():
			m.g[cs[i][1]][cs[i][0]] = "dirt" if huerta_vista() else _town19[i][0]   # i18n-no
			m.o[cs[i][1]][cs[i][0]] = null if huerta_vista() else _town19[i][1]
		if huerta_vista():
			m.doors[kq] = {"to": HUERTA.mapa, "x": int(HUERTA.llega[0]), "y": int(HUERTA.llega[1]), "dir": "up"}
		else:
			m.doors.erase(kq)
	if k == HUERTA.mapa:
		MAPS[HUERTA.mapa] = mapa_huerta()

# el mapa: el monte alrededor; dentro del seto (HUERTA.seto: x0, y0, x1, y1), una fila de monte arriba, el camino de tierra por el
# medio hasta la salida de abajo y los cuatro bancales (con zarzas y hierba alta hasta que la desbrozas; luego, la tierra arada con
# lo plantado)
func mapa_huerta() -> Dictionary:
	var W: int = HUERTA.w
	var H: int = HUERTA.h
	var x0: int = HUERTA.seto[0]
	var y0: int = HUERTA.seto[1]
	var x1: int = HUERTA.seto[2]
	var y1: int = HUERTA.seto[3]
	var cx: int = HUERTA.camino
	var g := []
	var o := []
	for y in H:
		g.append([])
		o.append([])
		for x in W:
			g[y].append("grass")   # i18n-no
			var dentro: bool = x >= x0 and x <= x1 and y > y0   # debajo del seto, hierba: el monte taparía lo de la última fila
			o[y].append(null if dentro else ("monte" if (x * 7 + y * 3) % 5 < 3 else "monte2"))   # i18n-no
	for y in range(y0 + 1, y1 + 1):
		o[y][x0] = "seto"   # i18n-no
		o[y][x1] = "seto"   # i18n-no
	for x in range(x0 + 1, x1):
		o[y1][x] = "seto"   # i18n-no
	for y in range(y0 + 1, H):
		g[y][cx] = "dirt"   # i18n-no
		g[y][cx + 1] = "dirt"   # i18n-no
		if y == y1:
			o[y][cx] = null
			o[y][cx + 1] = null
	var lista := huerta_lista()
	for b in HUERTA.bancales:
		for y in range(int(b[1]), int(b[3]) + 1):
			for x in range(int(b[0]), int(b[2]) + 1):
				g[y][x] = "surco" if lista else "tallgrass"   # i18n-no
				if not lista and (x + y) % 2 == 0:
					o[y][x] = "bush"   # i18n-no
	for a in HUERTA.atrezo:   # el bidón con la manguera del grifo del garaje, el cubo, el manzano, las herramientas y el compost
		o[int(a[1])][int(a[0])] = a[2]
	var m := {"name": HUERTA.mapa, "w": W, "h": H, "g": g, "o": o, "exits": {}, "doors": {}, "music": "town", "blds": [], "est": null}   # i18n-no
	for x in [cx, cx + 1]:
		m.doors["%d,%d" % [x, y1]] = {"to": "town", "x": int(HUERTA.sale[0]), "y": int(HUERTA.sale[1]), "dir": "down"}   # i18n-no
	if lista:
		for i in HUERTA.sitios.size():
			var s: Array = HUERTA.sitios[i]
			o[int(s[1])][int(s[0])] = sprite_huerta(huerta_s().p[i])
	return m

# hp<v>-<fase> (huerto.py, como las salvajes): v por el % índica, la fase por el progreso; seca, hs<v>-<fase> (pinta.gd la pinta parda)
func sprite_huerta(p):
	if not (p is Dictionary):
		return null
	var ind: float = float(Datos.ind_de(S, p.sid))
	var v: int = 0 if ind >= 70 else (1 if ind <= 30 else 2)
	var fa: int = 1 if p.prog < .12 else (2 if p.prog < .35 else (3 if p.prog < .65 else (4 if p.prog < 1 else 5)))
	return ("hs%d-%d" if p.get("dead") else "hp%d-%d") % [v, fa]   # i18n-no

func huerta_objs() -> void:
	if not MAPS.has(HUERTA.mapa) or not huerta_lista():
		return
	var o: Array = MAPS[HUERTA.mapa].o
	for i in HUERTA.sitios.size():
		var s: Array = HUERTA.sitios[i]
		o[int(s[1])][int(s[0])] = sprite_huerta(huerta_s().p[i])

func huerta_veg(dia: int) -> bool:   # ¿días largos? (dentro de HUERTA.veg, mes × 100 + día)
	var f := Datos.fecha(dia)
	var md: int = int(f.m) * 100 + int(f.d)
	return md >= int(HUERTA.veg[0]) and md <= int(HUERTA.veg[1])

# los factores de una planta de la huerta, como Cultivo.factores de una plaza: sin foco ni maceta, el sol y la tierra
func huerta_f(p) -> Dictionary:
	var vd: float = float(p.get("vd", 0)) if p is Dictionary else 0.0
	var t: float = float(Datos.tiempo(S.day, S.min).t)
	return {"g": float(HUERTA.g) * clampf(vd / float(HUERTA.veg_dias), .25, 1.0), "cap": float(HUERTA.cap), "crec": Cultivo.f_clima({"t": t, "hr": 50.0}), "thc": 0.0,
		"agua": float(HUERTA.agua[int(Datos.fecha(S.day).m) - 1]), "plaga": float(HUERTA.plaga), "hr": 50.0, "moho": 1.0, "ciclo": "veg" if huerta_veg(S.day) else "flor"}   # i18n-no

func huerta_hu(i: int) -> Dictionary:
	var s: Array = HUERTA.sitios[i]
	var p = huerta_s().p[i]
	return {"l": huerta_s().p, "v": [int(s[0]) * 16 + 8, int(s[1]) * 16 - 8], "f": huerta_f(p)}

func plants_advance(mn: int) -> void:
	super(mn)
	huerta_avanza(mn)

# cada rato: crecen (Cultivo.plant_step), la lluvia las riega y cuentan los días en vegetativo
func huerta_avanza(mn: int) -> void:
	if not huerta_lista():
		return
	var L: Array = huerta_s().p
	var llueve: bool = Datos.tiempo(S.day, S.min).k in ["lluvia", "tormenta"]   # i18n-no
	var cambia := false
	for i in L.size():
		var p = L[i]
		if not (p is Dictionary) or p.get("dead"):
			continue
		var a = sprite_huerta(p)
		if llueve:
			p.water = 100.0
		if p.prog >= .12 and p.prog < .65:
			p.vd = float(p.get("vd", 0)) + mn / 1440.0
		Cultivo.plant_step(S, p, mn / 60.0, huerta_f(p))
		cambia = cambia or sprite_huerta(p) != a
	if cambia:
		huerta_objs()

func new_day() -> void:
	super()
	huerta_dia()

# al amanecer: la helada y la nieve de ayer (la mínima), y la botritis de las que florecen con lluvia
func huerta_dia() -> void:
	if not huerta_lista():
		return
	var ay := Datos.tiempo(S.day - 1, 360)
	var B: Dictionary = D.BOTRITIS if D.has("BOTRITIS") else {}
	var L: Array = huerta_s().p
	for i in L.size():
		var p = L[i]
		if not (p is Dictionary) or p.get("dead"):
			continue
		var dano := 0.0
		if ay.k == "nieve":   # i18n-no
			dano = float(HUERTA.nieve)
		elif int(ay.min) <= 0:
			dano = float(HUERTA.helada)
		if p.get("bot"):
			dano += float(B.get("dano", 0))
		elif B.size() and ay.k in ["lluvia", "tormenta"] and p.prog >= .65 and p.prog < 1 and int(p.get("prev", 0)) < S.day:   # i18n-no
			var pr: float = float(B.lluvia) * (1 - float(D.IVS.res) * Cultivo.iv_f(p.get("f"), 3)) * (1 - Cultivo.fam(S, "res"))
			if Datos.hash_str("hbot%d_%d_%s" % [S.day, i, p.sid]) % 1000 < int(pr * 1000):
				p.bot = S.day
		if dano > 0:
			p.health = maxf(0, float(p.health) - dano)
			if p.health <= 0:
				p.dead = true
	huerta_objs()

# A en la huerta o en la cancilla del pueblo
func huerta_obj(x: int, y: int, o) -> bool:
	if not Datos.CAL:
		return false
	if S.map == "town":   # i18n-no
		var q: Array = HUERTA.puerta
		if not huerta_vista() and y == int(q[1]) and (x == int(q[0]) or x == int(q[0]) + 1) and o in ["monte", "monte2"]:   # i18n-no
			if await ask(K("Detrás del garaje, entre las zarzas, asoma una cancilla vieja de madera. Al otro lado se ven bancales comidos por la hierba."), [K("Abrirte paso"), K("Dejarlo")]) != 0:
				return true
			await fade(1)
			huerta_s().v = S.day
			montar_huerta("town")
			advance_time(10)
			await fade(0)
			sfx("get")
			await say(K("Apartas las zarzas y empujas la cancilla: la huerta de la tía. Hace años que nadie la toca."))
			return true
		if o == "sign" and x == 1 and y == 8 and not huerta_vista():   # i18n-no
			await say(I18n.v(D.SIGNS.get("town:1,8", "")))
			await say(K("Alguien ha escrito a lápiz debajo: «La huerta de Maite, detrás del garaje»."))
			return true
		return false
	if S.map != HUERTA.mapa:
		return false
	if not huerta_lista():
		var en_bancal := false
		for b in HUERTA.bancales:
			en_bancal = en_bancal or (x >= int(b[0]) and x <= int(b[2]) and y >= int(b[1]) and y <= int(b[3]))
		if en_bancal:
			if await ask(T("Los bancales de la tía, comidos por las zarzas y la hierba. Limpiarlos te lleva unas {h} horas.", {"h": int(HUERTA.desbroce) / 60}), [K("Desbrozar"), K("Dejarlo")]) == 0:
				await fade(1)
				advance_time(int(HUERTA.desbroce))
				huerta_s().l = S.day
				MAPS[HUERTA.mapa] = mapa_huerta()
				await fade(0)
				sfx("get")
				await say(K("Arrancas las zarzas, cavas y dejas la tierra en surcos. Caben ocho plantas al sol."))
			return true
	for i in HUERTA.sitios.size():
		var s: Array = HUERTA.sitios[i]
		if huerta_lista() and int(s[0]) == x and int(s[1]) == y:
			await pot_action(i, huerta_hu(i))
			huerta_objs()
			return true
	if o == "bidonT":   # i18n-no
		var vivas: Array = huerta_s().p.filter(func(p): return p is Dictionary and not p.get("dead"))
		if not huerta_lista() or vivas.is_empty():
			await say(K("Un bidón azul con una manguera que llega del grifo del garaje."))
			return true
		if await ask(T("Un bidón con la manguera del grifo del garaje. Regar las {n} plantas te lleva media hora.", {"n": vivas.size()}), [K("Regar todas"), K("Nada")]) == 0:
			await accion("regar")
			for p in vivas:
				p.water = 100.0
			advance_time(int(HUERTA.riego))
			huerta_objs()
			cuenta("riego")
			sfx("sel")
			await say(K("Riegas toda la huerta. Agua al 100%."))
		return true
	if o == "crate":   # i18n-no
		await say(K("Las herramientas de la tía: una azada, unas tijeras de podar y unos guantes de jardín gastados."))
		return true
	if o == "sacos":   # i18n-no
		await say(K("Sacos de compost que la tía dejó hechos tierra. La huerta no necesita más."))
		return true
	if o == "cuboS":   # i18n-no
		await say(K("Un cubo con una pala de mano dentro."))
		return true
	if o == "manzano":   # i18n-no
		await say(K("Un manzano viejo que sigue dando manzanas pequeñas y ácidas."))
		return true
	return false
