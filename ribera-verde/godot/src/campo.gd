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
	if mapa == "errotabarri" and abiertas.has("15,0"):   # la salida del norte pasa por la fila 1
		abiertas["15,1"] = true
	for c in C.abre.get(mapa, []):
		var x := int(c[0])
		var y := int(c[1])
		var k := "%d,%d" % [x, y]
		var ko := mapa + "|" + k
		if abiertas.has(k):
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
