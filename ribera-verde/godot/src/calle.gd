# F8 (de mundo.gd): el movimiento, las acciones del atlas, los clientes y la venta, las patrullas y ordenar.
extends "res://src/mundo.gd"

# ---------- movimiento ----------
func update_player(dt: float) -> void:
	if P.moving:
		P.t += dt
		var k := minf(1, P.t / P.dur)
		P.px = (P.fx + (P.x - P.fx) * k) * 16
		P.py = (P.fy + (P.y - P.fy) * k) * 16
		var vv := vaiven(k)   # MAESTRO [2]: borracho, el paso se va de lado
		P.px += vv * absf(P.y - P.fy)
		P.py += vv * absf(P.x - P.fx)
		if k < 1:
			return
		P.moving = false
		P.px = P.x * 16.0
		P.py = P.y * 16.0
		paso_sobra = minf(P.t - P.dur, P.dur * 0.5) if Datos.CAL else 0.0
		on_step_end()
		P.chain = true
	if not is_free():
		P.chain = false
		return
	var d = dir_order[-1] if dir_order.size() else null
	if d == null:
		if P.chain and deriva():   # MAESTRO [2]: borracho, al soltar das un paso de más
			try_move(P.dir)
			return
		P.chain = false
		P.hold = 0.0
		return
	P.der = 0
	if SENT != null:   # 1.49: una flecha te levanta, mirando hacia ella, sin dar el paso todavía
		levantarte(d)
		P.chain = false
		P.hold = 150.0
		return
	if d != P.dir:
		P.dir = d
		if not P.chain:
			P.hold = 90.0
			return
	if P.hold > 0:
		P.hold -= dt
		return
	try_move(d)

func try_move(d: String) -> void:
	var m: Dictionary = MAPS[S.map]
	var dv: Array = DV[d]
	var ex = m.exits.get("%d,%d" % [P.x, P.y])
	if ex and d == ex.get("lado", "down"):   # 1.51: las salidas de lado (al muelle), con su flecha
		P.chain = false
		run(func(): await warp(ex))
		return
	var nx: int = P.x + dv[0]
	var ny: int = P.y + dv[1]
	if tile_solid(m, nx, ny) or ent_at(nx, ny) or coche_en(nx, ny) != "":
		if M.reloj - P.bumpT > 350:
			sfx("bump")
			P.bumpT = M.reloj
		P.chain = false
		return
	P.fx = P.x
	P.fy = P.y
	P.x = nx
	P.y = ny
	P.t = paso_sobra if P.chain else 0.0   # 1.57: andando seguido, lo que sobró del paso anterior (sin tirones entre casillas)
	paso_sobra = 0.0
	P.moving = true
	P.pisT = M.reloj
	P.dur = paso_ms()
	P.parity ^= 1

# el patinete o la bici (1.13, vehiculo() de 12c-salon): en la calle (ZONAS), el mejor que tengas
func vehiculo():
	var v = S.get("veh")
	if not D.ZONAS.has(S.map):
		return null
	if not Datos.CAL:   # MAESTRO [3]: con CAL, los del concesionario no van por el mapa: del garaje o del aparcamiento, de pueblo a pueblo
		for k in ["deportivo", "berlina", "utilitario", "moto"]:   # 1.43: lo del concesionario, antes que nada (el mejor que tengas)
			if coche_ya(k) and not S.coches[k].get("grua") and D.VEHICULOS.has(k):
				return k
	if not (v is Dictionary):
		return null
	for k in ["bici", "patinete"]:
		if v.get(k) and float(v[k]) <= S.day:
			return k
	return null

# MAESTRO [3] (lo pidió el usuario: «tiene que estar en el garaje y del garaje viajas al otro pueblo, y se queda estacionado en un
# aparcamiento; no se usa por el mapa»): cada vehículo del concesionario está en un pueblo (S.coches[k].en; sin él, GARAJE, el de
# casa): en Ribera Verde, dentro del garaje; en los demás, en una plaza del aparcamiento dibujado junto a la parada (APARC)
const GARAJE := "town"

func donde(k: String) -> String:
	return String(S.coches[k].get("en", GARAJE))

func aparcados(mapa: String) -> Array:   # los tuyos que están en mapa, por orden
	var o := []
	if Datos.CAL and S.get("coches") is Dictionary:
		for k in D.CONCE.orden:
			if S.coches.has(k) and coche_ya(k) and donde(k) == mapa:
				o.append(k)
	return o

# el aparcamiento de cada pueblo, dibujado junto a la parada (3 × 4 casillas: cuatro plazas de 2 × 1 a la izquierda y el pasillo a la
# derecha; aparcamiento.py), en suelo libre que no corta el paso a nada (lo comprueba tests/vehiculos.gd)
const APARC := {"puerto": [17, 10], "valdehierro": [17, 11], "mendialde": [25, 19], "errotabarri": [13, 13], "ibarbide": [7, 23], "metropoli": [1, 24]}   # i18n-no
var _aparc0 := {}

func montar_aparcamiento(mapa: String) -> void:
	if not APARC.has(mapa) or not MAPS.has(mapa):
		return
	var m: Dictionary = MAPS[mapa]
	var x0: int = APARC[mapa][0]
	var y0: int = APARC[mapa][1]
	if not _aparc0.has(mapa):
		var g0 := []
		for y in range(y0, y0 + 4):
			g0.append(m.g[y].slice(x0, x0 + 3))
		_aparc0[mapa] = g0
	for y in 4:
		for x in 3:
			m.g[y0 + y][x0 + x] = "road" if Datos.CAL else _aparc0[mapa][y][x]   # i18n-no
	var bs: Array = m.blds.filter(func(q): return q.id != "aparcamiento")   # i18n-no
	if Datos.CAL:
		bs.append({"id": "aparcamiento", "x0": x0, "y0": y0, "w": 3, "h": 4})   # i18n-no
	m.blds.clear()
	m.blds.append_array(bs)
	m.erase("_parque")

# las plazas del aparcamiento de mapa (la casilla de la izquierda de cada una, de arriba abajo); sin aparcamiento (no debería
# pasar), las casillas de calzada libres más cerca de donde te deja el autobús
func plazas_parque(mapa: String) -> Array:
	var m: Dictionary = MAPS[mapa]
	if m.has("_parque"):
		return m._parque
	var o := []
	if APARC.has(mapa):
		for i in 4:
			o.append(Vector2i(APARC[mapa][0], APARC[mapa][1] + i))
	elif D.PARADAS.has(mapa):
		var a: Array = D.PARADAS[mapa].a
		var c := []
		for y in m.h:
			for x in m.w:
				var d: int = absi(x - int(a[0])) + absi(y - int(a[1]))
				if d >= 2 and d <= 10 and m.o[y][x] == null and not tile_solid(m, x, y) and pisable(m, x, y) and String(m.g[y][x]).begins_with("road"):
					c.append([d, x, y])
		c.sort()
		for q in c.slice(0, 4):
			o.append(Vector2i(q[1], q[2]))
	m._parque = o
	return o

func coche_en(x: int, y: int) -> String:   # el tuyo aparcado en (x, y) de este mapa (las dos casillas de su plaza), o ""
	if S.map == GARAJE:
		return ""
	var ks := aparcados(S.map)
	var pl := plazas_parque(S.map)
	var ancha := APARC.has(S.map)
	for i in mini(ks.size(), pl.size()):
		if pl[i] == Vector2i(x, y) or (ancha and pl[i] + Vector2i(1, 0) == Vector2i(x, y)):
			return ks[i]
	return ""

func llegada_parque(mapa: String, k: String) -> Array:   # dónde te deja el coche: en el pasillo, al lado de su plaza
	var i: int = aparcados(mapa).find(k)
	if not APARC.has(mapa) or i < 0 or i > 3:
		return D.PARADAS[mapa].a
	return [APARC[mapa][0] + 2, APARC[mapa][1] + i, "down"]   # i18n-no

# el garaje de la tía, dibujado junto al piso (lo pidió el usuario: «dibujado en el mapa junto al piso»): 2 × 3 casillas a la
# derecha del portal, con la puerta en la fila de la acera; el cartel del piso, que estaba ahí, pasa al otro lado del portal
const GARAJE_B := {"id": "garaje", "x0": 9, "y0": 6, "w": 2, "h": 3}   # i18n-no
const GARAJE_CARTEL := [Vector2i(9, 8), Vector2i(1, 8)]
var _garaje0 = null

func montar_garaje(mapa: String) -> void:
	if mapa != GARAJE or not MAPS.has(mapa):
		return
	var m: Dictionary = MAPS[mapa]
	var b := GARAJE_B
	if _garaje0 == null:
		_garaje0 = {"g": m.g.duplicate(true), "o": m.o.duplicate(true)}
	for y in range(b.y0, b.y0 + b.h):
		for x in range(b.x0, b.x0 + b.w):
			m.g[y][x] = "wall_garaje" if Datos.CAL else _garaje0.g[y][x]   # i18n-no
			m.o[y][x] = ("garaje" if y == b.y0 + b.h - 1 else null) if Datos.CAL else _garaje0.o[y][x]   # i18n-no
	var c0: Vector2i = GARAJE_CARTEL[0]
	var c1: Vector2i = GARAJE_CARTEL[1]
	if Datos.CAL:
		m.o[c1.y][c1.x] = "sign"   # i18n-no
		D.SIGNS["%s:%d,%d" % [mapa, c1.x, c1.y]] = D.SIGNS["%s:%d,%d" % [mapa, c0.x, c0.y]]
	else:
		m.o[c1.y][c1.x] = _garaje0.o[c1.y][c1.x]
	var bs: Array = m.blds.filter(func(q): return q.id != "garaje")
	if Datos.CAL:
		bs.append(b.duplicate())
	m.blds.clear()
	m.blds.append_array(bs)
	m.erase("_parque")

# Un vehículo del concesionario (S.coches: {k: {dia: cuándo llega, p: lo pagado, r: el próximo recibo del seguro o null}}), ya entregado
func coche_ya(k: String) -> bool:
	return S.get("coches") is Dictionary and S.coches.has(k) and int(S.coches[k].dia) <= int(S.day)

# MAESTRO [2]: el desmayo. FISIO.desmayo.h horas después te despiertas en la parada del pueblo (la de Ribera Verde si la zona
# no tiene), sin FISIO.desmayo.dinero del efectivo ni FISIO.desmayo.cosas de los cogollos y extractos que llevabas encima
func desmayo() -> void:
	var F: Dictionary = D.FISIO.desmayo
	await fade(1)
	var pa: String = S.map if D.PARADAS.has(S.map) else ("ibarbide" if S.map in ["ensanche", "callejon"] else "town")
	var dm := snappedf(float(S.money) * float(F.dinero), 0.01)
	S.money = snappedf(float(S.money) - dm, 0.01)
	var g0 := total_buds() + total_rosin()
	for k in S.buds.keys():
		S.buds[k].g = snappedf(float(S.buds[k].g) * (1 - float(F.cosas)), 0.1)
		if S.buds[k].g < .5:
			S.buds.erase(k)
	for k in S.rosin.keys():
		S.rosin[k].g = snappedf(float(S.rosin[k].g) * (1 - float(F.cosas)), 0.1)
		if S.rosin[k].g < .1:
			S.rosin.erase(k)
	var gp := g0 - total_buds() - total_rosin()
	advance_time(int(F.h) * 60)
	S.borr = float(D.FISIO.inercia[0])   # se te ha pasado lo peor
	var A: Array = D.PARADAS[pa].a
	enter_map(pa, int(A[0]), int(A[1]), A[2])
	update_hud()
	await wait(80)
	await fade(0)
	await say(T("Te despiertas en el banco de la parada, con la cabeza a punto de estallar. Han pasado {h} horas.", {"h": int(F.h)}) + \
		(" " + T("Te faltan {e} de la cartera.", {"e": Datos.eur(dm)}) if dm > 0 else "") + (" " + T("Y {g} g de lo que llevabas encima.", {"g": Datos.coma(snappedf(gp, 0.1))}) if gp > 0 else ""))

func paso_ms() -> float:   # ms por casilla: a pie, corriendo o montado (pasoMs)
	var v = vehiculo()
	if v:
		return float(D.VEHICULOS[v].paso[1 if held.B else 0])
	var e := efecto()   # MAESTRO [2]: la sativa te acelera y la índica te pesa
	return (130.0 if held.B else 240.0) / (float(D.FISIO[e].vel) if e != "" else 1.0)

# MAESTRO [2]: de FISIO.inercia[0] a [1] de borrachera, el paso se tuerce (vaiven, en px) y al soltar sigues una casilla más
# (deriva, una vez por soltar, con más probabilidad cuanto más borracho; sin azar: por el número de pasos)
func vaiven(k: float) -> float:
	var b := borr()
	if b <= float(D.FISIO.inercia[0]):
		return 0.0
	var f := minf(1.0, (b - float(D.FISIO.inercia[0])) / (float(D.FISIO.inercia[1]) - float(D.FISIO.inercia[0])))
	return float(D.FISIO.vaiven) * f * sin(k * PI) * (1 if int(S.steps) % 2 else -1)

func deriva() -> bool:
	var b := borr()
	if b <= float(D.FISIO.inercia[0]) or P.get("der") or vehiculo():
		return false
	P.der = 1
	var p := minf(1.0, (b - float(D.FISIO.inercia[0])) / (float(D.FISIO.inercia[1]) - float(D.FISIO.inercia[0]))) * float(D.FISIO.deriva)
	return Datos.hash_str("deriva|%d|%d" % [int(S.day), int(S.steps)]) % 1000 < p * 1000

func on_step_end() -> void:
	S.x = P.x
	S.y = P.y
	S.dir = P.dir
	S.steps += 1
	if S.cool > 0:
		S.cool -= 1
	var m: Dictionary = MAPS[S.map]
	var door = m.doors.get("%d,%d" % [P.x, P.y])
	if door:
		if door.get("gate"):   # 1.30: la puerta de un local (entra_local, trama.gd)
			run(func(): await entra_local(door))
		else:
			run(func():
				if door.to == "home" and S.map != "home":   # 1.53: la llave del piso
					await acceso("llave")
				await warp(door))
		return
	if (S.map == "disco" or S.map == "disco-vip") and not disco_abierta():
		run(func(): await echar_disco())
		return
	if not D.ZONAS.has(S.map):
		return
	if borr() >= float(D.FISIO.tope):   # MAESTRO [2]: en la calle con la borrachera a tope, al suelo
		run(func(): await desmayo())
		return
	var Z: Dictionary = D.ZONAS[S.map]
	if S.map == "town" and P.y >= 13 and P.y <= 14 and P.x >= 18 and P.x <= 22:
		if S.ch >= 2 and S.ch < 7 and not S.flags.get("darko1"):
			queue("darko", func():
				for e in ents:
					if e.id == "darko":
						e.dir = "up"
				await talk_darko())
			return
		if S.ch >= 5 and not S.flags.get("molina1"):
			queue("molina", talk_molina)
			return
	# ladrones al azar por paso; la policía ya no (1.10): patrulla por la calle (más abajo). Con la alarma, nada
	if S.ch >= 2 and S.cool <= 0 and SOSP.alarma == null:
		var g := gramos_flor()   # el rosin también atrae ladrones (1.10)
		var tall: bool = m.g[P.y][P.x] == "tallgrass"
		var pt: float = .004 * (2.5 if is_night() else 1.0) * (3.0 if tall else 1.0) * Z.lad if (g >= 5 or S.money >= 150) else 0.0
		if Cultivo.azar() < pt:
			S.cool = 25
			run(func(): await battle("thief"))

func update_ents(dt: float) -> void:
	var free := is_free()
	var m: Dictionary = MAPS[S.map]
	for e in ents:
		if e.get("pat"):   # las patrullas andan en update_patrullas
			continue
		if e.moving:
			e.t += dt
			var k := minf(1, e.t / 320)
			e.px = (e.fx + (e.x - e.fx) * k) * 16
			e.py = (e.fy + (e.y - e.fy) * k) * 16
			if k >= 1:
				e.moving = false
				e.fx = e.x
				e.fy = e.y
			continue
		if not free or not e.wander:
			continue
		e.wt -= dt
		if e.wt > 0:
			continue
		e.wt = 1200 + Cultivo.azar() * 2600
		var d: String = pick(["up", "down", "left", "right"])
		e.dir = d
		var nx: int = e.x + DV[d][0]
		var ny: int = e.y + DV[d][1]
		if absi(nx - e.hx) > e.wander or absi(ny - e.hy) > e.wander:
			continue
		var k := "%d,%d" % [nx, ny]
		if tile_solid(m, nx, ny) or ent_at(nx, ny) or (nx == P.x and ny == P.y) or (P.moving and nx == P.fx and ny == P.fy) or m.doors.has(k) or m.exits.has(k) or llegada_bus(nx, ny):   # ni en la llegada del autobús (1.10)
			continue
		e.fx = e.x
		e.fy = e.y
		e.x = nx
		e.y = ny
		e.t = 0.0
		e.moving = true

func world_press(b: String) -> void:
	if mode == "title":
		title_press(b)
		return
	if not is_free() or P.moving:
		return
	if SENT != null and b == "A":   # 1.49: sentado, lo que puedes hacer sin levantarte
		run(menu_sentado)
	elif SENT != null and b == "B":
		levantarte()
	elif b == "A":
		interact()
	elif b == "START":
		if not oraculo:   # E4 (fase 3): la pausa guarda antes de abrir el menú (al salir de la app con él abierto ya no se guarda)
			call("save")
		run(start_menu)
	elif b == "MOVIL":
		run(movil_menu)

# la casilla de delante; si es una silla (1.27.1), la de encima, desde cualquier lado: el ordenador que tiene delante
func delante() -> Array:
	var dv: Array = DV[P.dir]
	var m: Dictionary = MAPS[S.map]
	var tx: int = P.x + dv[0]
	var ty: int = P.y + dv[1]
	if ty >= 0 and ty < m.h and tx >= 0 and tx < m.w and m.o[ty][tx] in SILLAS:
		ty -= 1
	return [tx, ty]

func interact() -> void:
	var dv: Array = DV[P.dir]
	var m: Dictionary = MAPS[S.map]
	if Datos.CAL:   # 1.47: un asiento delante (sofá, sillón, silla, banco, taburete): sentarte
		var sx: int = P.x + dv[0]
		var sy: int = P.y + dv[1]
		if sy >= 0 and sy < m.h and sx >= 0 and sx < m.w and asiento_de(m.o[sy][sx]) != "" and ent_at(sx, sy) == null:
			run(func(): await asiento(sx, sy))
			return
	var de := delante()
	var tx: int = de[0]
	var ty: int = de[1]
	var ck := coche_en(tx, ty)   # MAESTRO [3]: tu vehículo en el aparcamiento: viajar o el maletero
	if ck != "":
		run(func(): await coche_menu(ck))
		return
	var e = ent_at(tx, ty)
	if e == null and ty >= 0 and ty < m.h and tx >= 0 and tx < m.w and m.o[ty][tx] in COUNTERS:
		e = ent_at(tx + dv[0], ty + dv[1])
	if e:
		run(func(): await hablar_con(e))
		return
	var it = item_at(tx, ty)
	if it:
		run(func(): await pick_item(it))
		return
	run(func(): await object_action(tx, ty))

func sent_geo(k) -> Array:
	return SENT_GEO.get(k, [0, 9])

func asiento_de(o) -> String:
	if not (o is String):
		return ""
	if ASIENTOS.has(o):
		return o
	if o.ends_with("2") and ASIENTOS.has(o.left(-1)):
		return o.left(-1)
	return ""

func asiento(x: int, y: int) -> void:
	var k := asiento_de(MAPS[S.map].o[y][x])
	var ops := [K("Sentarte")]
	var fuera: bool = Datos.CAL and S.map != "home" and ASIENTO_FUERA.has(k)   # 1.51: el sillón y la silla de otras casas no son los tuyos
	if fuera:
		pass
	elif k in ["silla", "sillaG"]:   # i18n-no
		ops.append(K("Usar el ordenador"))
	elif k in ["sofa", "sillon", "sofaF", "sofaB", "sofaV"]:   # i18n-no
		ops.append(K("Otra cosa"))
	ops.append(K("Nada"))
	var j: int = await ask(ASIENTO_FUERA[k] if fuera else ASIENTO_TXT[k], ops)
	var c: String = ops[j] if j >= 0 and j < ops.size() else K("Nada")
	if c == "Nada":
		return
	if c != "Sentarte":
		if Datos.CAL and c == "Usar el ordenador":   # (lo pidió el usuario): para usar el ordenador te sientas, y te quedas sentado
			await sentado(x, y, k)
			await object_action(x, y - 1)
			return
		var de := delante()
		await object_action(de[0], de[1])
		return
	await sentado(x, y, k)

# sentado delante de un ordenador (la silla de la tía o la gaming, con algo encima): las manos en la mesa (_pj_sentado)
func sent_mesa() -> bool:
	if not Datos.CAL or SENT == null or not (SENT.get("k") in ["silla", "sillaG"]) or S.map != "home":   # i18n-no
		return false
	var o = MAPS[S.map].o[SENT.y - 1][SENT.x] if SENT.y > 0 else null
	return o is String and o != ""

func sentado(x: int, y: int, k: String) -> void:
	SENT = {"x": x, "y": y, "d": ASIENTOS[k], "k": k, "dir0": P.dir}
	P.dir = "down" if SENT.d == "sur" else "up"

# (lo pidió el usuario: «que te puedas sentar de verdad»): sentado es un estado, no un menú; el mundo sigue (la gente
# anda, el reloj corre, el móvil y START funcionan) y te quedas hasta que te levantas: con B o con una flecha. Con A, lo que
# se puede hacer sentado (menu_sentado)
func levantarte(d = null) -> void:
	if SENT == null:
		return
	P.dir = d if d != null else SENT.dir0
	SENT = null

func bebidas_aqui() -> String:
	if S.map in ["bar", "loc-puerto"]:
		return "bar"
	if S.map.begins_with("club-"):
		return "club"
	if S.map in ["disco", "disco-vip", "disco-g"]:
		return "disco"
	return ""

# quien está a tu lado: junto al asiento o junto a la casilla donde estás (ni la policía de patrulla)
func al_lado() -> Array:
	var r := []
	if SENT == null:
		return r
	for e in ents:
		if e.get("pat") or e.moving:
			continue
		var d1: int = absi(e.x - SENT.x) + absi(e.y - SENT.y)
		var d2: int = absi(e.x - P.x) + absi(e.y - P.y)
		if d1 <= 1 or d2 <= 1 or (absi(e.x - SENT.x) <= 1 and absi(e.y - SENT.y) <= 1):
			r.append(e)
	return r

func hablar_con(e) -> void:
	if not e.moving:
		e.dir = OPP[P.dir]
	habla_look = e.get("look") if e.get("look") is Dictionary else null   # MAESTRO [8]: el retrato de la charla en vivo
	await _hablar_con(e)
	habla_look = null

func _hablar_con(e) -> void:
	if e.def.get("client"):
		await talk_client(e.def.client)
	else:
		await npc_talk(e.def)
		var r = rel_de(e.id)
		if not e.get("pat") and r:
			saludo(r)
		if Datos.CAL and SENT != null:   # MAESTRO [7]: sentado, la charla y, a veces, un encargo
			await cal_charla(e)

func menu_sentado() -> void:
	if SENT == null:
		return
	var ops := []   # [texto, clave]
	if sent_mesa():
		ops.append([K("Usar el ordenador"), "pc"])
	ops.append([K("Fumarte uno"), "fumar"])
	var bb := bebidas_aqui()
	if bb != "":
		ops.append([K("Pedir algo"), "beber"])
	for e in al_lado():
		ops.append([T("Hablar con {q}", {"q": nombre_ent(e)}), e])
	ops.append([K("Mirar el móvil"), "movil"])
	ops.append([K("Quedarte un rato"), "rato"])
	ops.append([K("Levantarte"), "fuera"])
	var j: int = await ask(K("Estás sentado."), ops.map(func(o): return o[0]))
	if j < 0 or j >= ops.size():
		return
	var c = ops[j][1]
	if not (c is String):
		await hablar_con(c)
		return
	match c:
		"pc":
			await object_action(SENT.x, SENT.y - 1)
		"fumar":
			await fumar_sentado()
		"beber":
			await beber_sentado(bb)
		"movil":
			await movil_menu()
		"rato":
			await rato_sentado()
		"fuera":
			levantarte()

func nombre_ent(e) -> String:   # dónde está respecto al asiento
	var dx: int = e.x - SENT.x
	var dy: int = e.y - SENT.y
	if dx < 0:
		return K("quien tienes a la izquierda")
	if dx > 0:
		return K("quien tienes a la derecha")
	return K("quien tienes delante") if (dy > 0) == (SENT.d == "sur") else K("quien tienes detrás")

func beber_sentado(bb: String) -> void:
	var L: Array = carta(bb)
	var j: int = await ask(K("¿Qué te pones?"), L.map(func(b): return T("{b} · {p}", {"b": b[0], "p": Datos.eur(b[1])})) + [K("Nada")])
	if j < 0 or j >= L.size():
		return
	var b: Array = L[j]
	if float(S.money) < float(b[1]):
		await say(K("No llevas suelto ni para eso."))
		return
	S.money = snappedf(float(S.money) - float(b[1]), 0.01)
	advance_time(int(b[2]))
	beber_alc(float(b[3]))   # MAESTRO [2]
	update_hud()
	var bt := borr()
	await say(T("{b}. Te lo tomas sentado, sin prisa.", {"b": b[0]}) + ("" if float(b[3]) <= 0 or bt <= float(D.FISIO.inercia[0]) else (T(" Ya vas tocado: te cuesta andar recto.") if bt <= float(D.FISIO.vision) else T(" Lo ves todo triple. Si sales así a la calle, acabas en el suelo."))))

func rato_sentado() -> void:
	advance_time(30)
	var t := T("Pasas media hora mirando a la gente.")
	if D.ZONAS.has(S.map) and float(S.heat) > 0 and not is_night():
		S.heat = maxf(0, float(S.heat) - 1)   # sentado y quieto en un banco, pasas desapercibido
		t += T(" Sentado en un banco no llamas la atención.")
	update_hud()
	await say(t)

# dónde echa el humo sentado (la boca, o encima de la cabeza si está de espaldas)
func boca_sentado() -> Vector2:
	if SENT == null:   # de pie
		return Vector2(P.px + 8, P.py - 4)
	var sur: bool = SENT.d == "sur"
	var g := sent_geo(SENT.get("k"))
	return Vector2(SENT.x * 16 + 8 + int(g[0]) + (4 if sur else 0), SENT.y * 16 + int(g[1]) - (9 if sur else 22))   # la boca, 9 filas sobre la cadera; de espaldas, encima de la cabeza

func fumar_sentado() -> void:
	if S.map == "comisaria":
		await say(K("¿Aquí, en comisaría? Mejor no."))
		return
	if S.map in NO_FUMAR or S.map.begins_with("loc-") or S.map.begins_with("est-"):
		await say(K("Aquí dentro no se puede fumar."))
		return
	var ms := []
	for k in FUMAR:
		if FUMAR[k].con.all(func(i): return float(S.items.get(i, 0)) > 0):
			ms.append(k)
	if ms.is_empty():
		await say(K("No tienes con qué: el papel y el mechero, en el estanco; las pipas, el bong y el vaporizador, en el grow."))
		return
	var mk: String = ms[0]
	if ms.size() > 1:
		var j: int = await ask(K("¿Cómo?"), ms.map(func(k): return FUMAR[k].n) + [K("Nada")])
		if j < 0 or j >= ms.size():
			return
		mk = ms[j]
	var F: Dictionary = FUMAR[mk]
	var gb: float = F.g
	var tab := false
	if mk == "porro":
		if S.items.get("grinder"):
			gb = 0.4   # desmenuzado con el grinder, se aprovecha más
		if float(S.items.get("tabaco", 0)) >= 0.7:
			var t: int = await ask(K("¿Con tabaco?"), [K("Con tabaco"), K("Solo hierba"), K("Nada")])
			if t < 0 or t > 1:
				return
			if t == 0:
				tab = true
				gb = F.gt
	var ls := bud_lots(gb).map(func(l): return [l[0], l[1], false])
	# (lo pidió el usuario: «las extracciones se deberían de poder fumar también con tabaco, sin tabaco no, porque sería con la
	# pipa»): en el porro, el extracto solo con tabaco (grt); solo, en la pipa, el bong o el vaporizador
	var gx: float = F.gr if F.gr > 0 else (float(F.grt) if tab and Datos.CAL else 0.0)
	if gx > 0:
		ls += rosin_lots(gx).map(func(l): return [l[0], l[1], true])
	if ls.is_empty():
		var sin_tab: bool = mk == "porro" and Datos.CAL and not tab and not rosin_lots(F.grt).is_empty()
		await say(K("No llevas nada para fumar.") if F.gr > 0 else (K("Sin cogollos, el extracto solo se lía con tabaco; si no, en una pipa, un bong o el vaporizador.") if sin_tab else K("No llevas cogollos para liarte uno.")))
		return
	var i := 0
	if ls.size() > 1:
		i = await menu(ls.map(func(l): return rosin_item([l[0], l[1]]) if l[2] else lot_item([l[0], l[1]])), {"title": K("¿DE CUÁL?")})
		if i < 0 or i >= ls.size():
			return
	var lk: String = ls[i][0]
	var r: bool = ls[i][2]
	var thc: float = ls[i][1].thc
	var nom: String = extr_nombre(lk, true) if r else lot_nombre(lk)
	if r:
		use_rosin(lk, gx)
	else:
		use_buds(lk, gb)
	if mk == "porro":
		S.items.papel = int(S.items.papel) - 1
		if S.items.get("filtros"):
			S.items.filtros = int(S.items.filtros) - 1
		if tab:
			S.items.tabaco = snappedf(float(S.items.tabaco) - 0.7, 0.1)
	marca_cata(lk, r, lot_sid(lk), thc)   # fumarlo es catarlo
	colocar(lot_sid(lk), (gx if r else gb) * thc * 10)   # MAESTRO [2]
	await gesto("fumar", {"m": mk})   # 1.54
	var b := boca_sentado()
	for n in 3:
		lanzar_vfx("vfx-humo-porro", b.x, b.y, M.reloj, S.map, true)
		await wait(700)
	advance_time(15)
	var t := (T("Te lías uno de {nom} con tabaco y te lo fumas sin prisa.", {"nom": nom}) if tab else T("Te lías uno de {nom} y te lo fumas sin prisa.", {"nom": nom})) if mk == "porro" else \
		(T("Cargas la pipa de {nom} y le das unas caladas.", {"nom": nom}) if mk == "pipa" else (T("Cargas el bong de {nom} y le das unas caladas.", {"nom": nom}) if mk == "bong" else T("Cargas el vaporizador de {nom} y le das unas caladas.", {"nom": nom})))
	if D.ZONAS.has(S.map):
		S.heat = minf(100, S.heat + (1 if mk == "vapo" else 3))
		heat_warn()
		t += T(" Fumar en la calle llama la atención.")
	update_hud()
	await say(t)

func object_action(x: int, y: int) -> void:
	var m: Dictionary = MAPS[S.map]
	var o = m.o[y][x] if y >= 0 and y < m.h and x >= 0 and x < m.w else null
	if await campo_obj(x, y, o):   # MAESTRO [4]: las salvajes de la comarcal y el refugio
		return
	var pi_ = puerta_int(S.map, x, y)
	if pi_ != null and o == pi_.o:   # 1.51: las puertas de dentro
		await cruzar_puerta(pi_)
		return
	if await obj_local(x, y, o):   # los locales (1.30)
		return
	if S.map == "home":
		for t in m.get("carpas", []):
			if x >= t.x0 and x <= t.x1 and y == t.y:
				await abrir_carpa(t.ci)
				return
		var sl := sitio_libre(x, y)
		if sl >= 0:
			await say((T("Hueco junto a la cama: aquí cabe una carpa de 120×120.") + (T(" Kiko las tendrá más adelante.") if S.ch < 5 else T(" Kiko las vende."))) if sl == 2 else K("Aquí cabe una carpa de cultivo. Kiko vende carpas de 100×100."))
			return
		if mueble_de(o) != "":
			await mueble_action(mueble_de(o))
			return
		for k in D.MUEBLES:   # el sitio vacío de un mueble del salón
			var mu: Dictionary = D.MUEBLES[k]
			if mu.get("suelo") and k in muebles_ya():   # la alfombra puesta no es un objeto: nada (1.27)
				continue
			var mp: Array = pos_pieza("home", k) if not pieza_de("home", k).is_empty() else [int(mu.x), int(mu.y)]   # 1.37: donde lo puso el jugador
			if (o == null or o == "plantDeco") and (x == mp[0] or (not mu.get("uno") and x == mp[0] + 1)) and y == mp[1]:   # lo que haya encima, antes (como en el HTML)
				var pd = S.get("muebles", {}).get(k) if S.get("muebles") is Dictionary else null
				if mu.get("grow") and not pd:   # el carro de esquejes (1.11): sin pedir, nada
					break
				await say(T("Aquí va {art}: llega mañana.", {"art": mu.art}) if pd else T("Aquí iría bien {art}. Se compra por internet: en el ordenador de la tía o con el móvil.", {"art": mu.art}))
				return
		if o != null and D.MUEBLE_EXTR.has(o):   # 1.36: los muebles de las extracciones
			await mueble_extr(o)
			return
		match o:
			"bedT", "bedB":   # i18n-no
				await bed_action()
				return
			"pc":
				await pc_action()
				return
			"lab", "lab2":
				await lab_action()
				return
			"trim":   # 1.36
				await manicura_action()
				return
			"table":
				if not S.flags.get("letter"):
					await letter_action()
					return
				# (lo pidió el usuario): con la carta leída, la mesa redonda ordena la casa (12d-orden)
				var j := await ask(K("La mesa redonda de la tía. Desde aquí se ve todo el piso."), [K("Ordenar la casa"), K("Leer la carta"), K("Nada")])
				if j == 0:
					await ordenar("home")
				elif j == 1:
					await letter_action()
				return
			"fridge":
				if S.flags.get("nevera"):
					if extr_algo() or nevera_r() > 0 or total_rosin() > 0:   # 1.36: los extractos, en frío
						await nevera_action()
					else:
						await say(K("La nevera: medio limón, leche y un táper de alubias que dejó la tía."))
					return
				S.flags.nevera = S.day   # 1.25: el bote de la tía
				await say(K("Detrás del táper de alubias hay un bote de cristal con una etiqueta: «Choco Thai. NO TOCAR»."))
				await semillas_tia("choco", K("El frío las ha conservado: siguen buenas."), 3)
				return
			"plantDeco":
				await say(K("Una monstera. La tía Maite le hablaba cada mañana."))
				return
			"iwin":
				await say(K("Por la ventana se ve la ría. Huele a salitre."))
				return
			"poster":
				await diploma_action()
				return
	if o == "escaleraC" and S.map == "home":   # 1.43.6: el camarote
		sfx("door")
		await fade(1)
		enter_map("camarote", int(D.CAMAROTE.desde[0]), int(D.CAMAROTE.desde[1]), "up")
		update_hud()
		await wait(80)
		await fade(0)
		return
	if S.map == "camarote":
		match o:
			"estanteC":
				await camarote_action()
				return
			"deshumC":
				await say(K("El deshumidificador: deja el camarote entre el 58 y el 62 % de humedad, a 18 °C. Los sobres de dentro de los tarros hacen el resto."))
				return
			"crate":
				await say(K("Cajas de la tía: revistas de jardinería, un ventilador viejo y los adornos de Navidad."))
				return
	if S.map == "casa-ama":   # el caserío de la familia, en Mendialde (1.10)
		match o:
			"table":
				var nueva: bool = not S.flags.get("notaAma")
				S.flags.notaAma = true
				await say(K("Una nota de tu ama: «Te he dejado un táper de alubias en la nevera. Llama cuando llegues. Y no te metas en líos».") if nueva else K("La nota de ama: «...y no te metas en líos»."))
				return
			"fridge":
				if S.flags.get("taper"):
					await say(K("La nevera de casa. El táper ya va en la mochila."))
					return
				S.flags.taper = true
				S.items.bocata += 1
				await got(K("el táper de alubias de ama (1 × BOCATA)"))
				return
			"bedT", "bedB":   # si pierdes el último autobús · i18n-no
				await bed_action(K("Tu cama de siempre, con la colcha de cuadros."))
				return
			"iwin":
				await say(K("Por la ventana se ven el monte y la carretera de la comarca."))
				return
			"plantDeco":
				await say(K("Los geranios de ama. Les sobra agua."))
				return
	var txt := ""
	if S.map == "txaro":
		txt = {"bedT": K("Una cama con colcha de ganchillo."), "bedB": K("Una cama con colcha de ganchillo."), "table": K("Un bote de aceite con una etiqueta a mano: «Para dormir. 2 gotas»."),
			"fridge": K("Nevera de las de antes. No es tuya."), "iwin": K("Por la ventana se ve el parque de los Sauces.")}.get(o, "")
	elif S.map == "comisaria":
		txt = {"iwin": K("Por la ventana se ve la plaza del Ensanche."), "shelfW": K("Archivadores con expedientes. Hay uno con tu calle."), "counter": K("El mostrador de denuncias. No hay nadie detrás.")}.get(o, "")
	elif S.map == "almacen":
		txt = {"crate": K("Cajas precintadas con el sello de una conservera que cerró hace años."), "btable": K("Una mesa con una báscula y rollos de film transparente.")}.get(o, "")
	if not txt and Datos.CAL and ATREZO_TXT.has(S.map):   # 1.51
		txt = ATREZO_TXT[S.map].get(o, "")
	if txt:
		await say(txt)
		return
	match o:
		"sign":
			var st: String = "%s:%d,%d" % [S.map, x, y]
			await say(I18n.v(D.SIGNS.get(st, K("Está tan desgastado que no se lee."))) + (("\n" + I18n.v(D.SETAS_SITIO.cartel)) if Datos.CAL and not Datos.PLAY and st == D.SETAS_SITIO.k else ""))   # 1.43.8
		"parada":
			await parada_action()
		"garaje":   # MAESTRO [3]
			await garaje_menu()
		"cajero":   # 1.35 (granja.gd)
			await cajero()
		"rotuloL":
			var k := local_de(S.map, x, y)
			if k != "":
				await rotulo_local(k)
		"bush":
			for it in D.ITEMS:
				if it.hidden and it.map == S.map and it.x == x and it.y == y and not S.taken.get(it.id):
					await pick_item(it)
					return
		"fountain":
			await say(K("La fuente de la plaza. Lleva años sin agua potable."))
		"shelfW":
			await say(K("Botes de abono, sustrato de coco y medidores de pH."))
		"display":
			await say(K("Sobres de semillas de bancos de todo el mundo, ordenados por tipo."))
		"vitrinaP", "vitrinaP2":   # 1.47 · i18n-no
			await say(K("La vitrina iluminada: grinders, pipas de cristal, bongs y vaporizadores. Se piden en el mostrador."))
		"estanteE", "estanteE2":   # i18n-no
			await say(K("Cajetillas de todos los colores, en filas. Lo de liar, en el mostrador."))
		"humidor":
			await say(K("El humidificador de los puros, con su higrómetro."))
		"papelE":
			await say(K("El expositor del papel de fumar: librillos de todos los tamaños."))
		"mostrE", "mostrE2":   # i18n-no
			await say(K("Mecheros de colores en la vitrina del mostrador."))
		"bottles":
			await say(K("Txakoli, pacharán y orujo casero."))
		"jukebox":
			sfx("get")
			await say(K("La gramola suena: rock vasco de los 80."))
		"crate":
			await say(K("Cajas de madera de los astilleros, podridas por la humedad.") if S.map == "astilleros" else (K("Cajas de piezas de la fundición, oxidadas.") if S.map == "valdehierro" else (K("Cajas de fruta vacías. La frutería de la esquina cerró en verano.") if S.map == "callejon" else K("Cajas de pescado vacías del puerto."))))

# ---------- acciones y efectos del atlas (01b-arte accion, lanzarVfx) ----------
func accion(nn: String, vf = null) -> void:
	var g = grupo_pj()
	if Datos.CAL and GESTO_DE.has(nn):   # 1.54: y el plano de detalle (gesto, trama.gd)
		var na := "plantar" if nn == "sembrar" else nn   # 1.57.2: al sembrar, el protagonista hace lo de plantar
		if g != null and Atlas.anim_de(g, na) != null:
			P.act = {"n": na, "t0": M.reloj}
		if vf:
			lanzar_vfx(vf.id, vf.x, vf.y, M.reloj, S.map, false)
		await gesto(GESTO_DE[nn])
		if P.act and P.act.n == na:
			P.act = null
		return
	if g == null or Atlas.anim_de(g, nn) == null:
		return
	P.act = {"n": nn, "t0": M.reloj}
	if vf:
		lanzar_vfx(vf.id, vf.x, vf.y, M.reloj, S.map, false)
	await wait(Atlas.duracion(g, nn))
	if P.act and P.act.n == nn:
		P.act = null

func lanzar_vfx(id: String, x: float, y: float, now: float, capa: String, sube: bool) -> void:
	if Atlas.anim_de(id, "efecto"):
		vfx.append({"id": id, "x": x, "y": y, "t0": now, "capa": capa, "sube": sube})

# los rivales (1.16, 13-combate): con el rival de la zona echado, sus clientes pagan un RIVAL.f más
func rival_f(z: String) -> float:
	return float(D.RIVAL.f) if float(S.rivalFuera.get(z, 0)) >= S.day else 1.0

# clientes del día por zona (1.10): en el barrio, como siempre; en el barrio alto, pijos y turistas desde el capítulo 3; en los
# astilleros (las esquinas de Darko), estudiantes y currelas. Con la prensa (1.10), catadores de rosin en la ciudad, los
# astilleros, Puerto Viejo y Valdehierro
func spawn_clients() -> void:
	S.clientsDay = S.day
	S.clients = []
	if S.ch >= 2:
		var nn := mini(10, 4 + int(floor(S.rep / 15.0)) + (1 if S.ch >= 4 else 0))
		var tipos := ["est", "est", "cur", "cur"]
		if S.ch >= 3:
			tipos.append("tur")
		if S.ch >= 4:
			tipos.append_array(["pij", "pij"])
		var zonas := [["town", nn, tipos], ["astilleros", 2 + (1 if S.ch >= 4 else 0), ["est", "cur"]]]
		if S.ch >= 3:
			zonas.append(["alto", 2 + (1 if S.ch >= 4 else 0), ["pij", "tur"]])
		var mas := 1 if S.ch >= 4 else 0   # la comarca (1.10)
		zonas.append_array([["puerto", 2 + mas, ["tur", "tur", "cur", "est"]], ["valdehierro", 2 + mas, ["est", "cur", "cur"]], ["mendialde", 1, ["cur"]], ["errotabarri", 1, ["cur", "tur"]]])
		if S.ch >= 4:   # la ciudad grande (1.14), con su línea
			var m5 := 1 if S.ch >= 5 else 0
			zonas.append_array([["ibarbide", 3 + m5, ["tur", "tur", "pij", "est"]], ["ensanche", 3 + m5, ["pij", "pij", "cur", "est"]], ["callejon", 2, ["est", "cur", "pij"]]])
		var usado := {}
		if S.ch >= 3 and extr_algo():
			for zx in [["town", 2], ["astilleros", 1], ["puerto", 1], ["valdehierro", 1]] + ([["ibarbide", 1], ["ensanche", 1]] if S.ch >= 4 else []):
				zonas.append([zx[0], zx[1], ["ext"], "x"])
		if metro_ya():   # MAESTRO [9]: Hiriburu, al final para no mover las tiradas de los demás
			zonas.append(["metropoli", 6 + (2 if S.ch >= 8 else 0), ["pij", "pij", "tur", "cur", "est"]])
		for zz in zonas:
			var map_: String = zz[0]
			if not usado.has(map_):
				usado[map_] = {}
				for d in D.NPCDEF:
					if d.map == map_:
						usado[map_]["%d,%d" % [d.x, d.y]] = true
				for it in D.ITEMS:
					if it.map == map_:
						usado[map_]["%d,%d" % [it.x, it.y]] = true
			var used: Dictionary = usado[map_]
			var pre: String = zz[3] if zz.size() > 3 else ""
			for i in int(zz[1]):
				var t: Array = []
				for k in 30:
					t = pick(D.CLIENT_TILES[map_])
					if not used.has("%d,%d" % [t[0], t[1]]):
						break
				used["%d,%d" % [t[0], t[1]]] = true
				var type: String = pick(zz[2])
				var ct: Dictionary = D.CTYPES[type]
				var id := "c%d_%s%s%d" % [S.day, pre, {"town": "", "alto": "b", "astilleros": "s", "puerto": "p", "valdehierro": "v", "mendialde": "m", "errotabarri": "e", "ibarbide": "i", "ensanche": "n", "callejon": "k", "metropoli": "h"}[map_], i]
				var want := ri(int(ct.g[0]), int(ct.g[1]))
				var mt := 0
				if type == "pij":
					mt = mini(24, 15 + S.ch)
				elif type == "tur" and Cultivo.azar() < .4:
					mt = 15
				S.clients.append({"id": id, "map": map_, "x": int(t[0]), "y": int(t[1]), "type": type, "want": want, "minThc": mt, "look": Datos.rand_look(id, "client")})
	if D.ZONAS.has(S.map):
		build_ents()

func remove_client(id: String) -> void:
	S.clients = S.clients.filter(func(c): return c.id != id)
	ents = ents.filter(func(e): return e.id != id)

# Con lluvia, tormenta o nieve hay menos gente en la calle: el calor de cada venta, por esto
func calle_tiempo() -> float:
	return float(D.TIEMPO.calle.get(Datos.tiempo(int(S.day), int(S.min)).k, 1.0)) if Datos.CAL else 1.0

# el catador (1.10) solo compra rosin: a precio_rosin, y el «caro» cuela según lo que pase del 50 % de THC
func talk_client(c: Dictionary) -> void:
	var ct: Dictionary = D.CTYPES[c.type]
	var N: String = c.get("n", etiqueta_ct(c.type, mujer_look(c.get("look"))))   # n: el nombre de un cliente de la agenda (12b-movil)
	var ext: bool = c.type == "ext"
	var ya: bool = (not ext) and await cal_saludo(c, N)   # MAESTRO [7]: la memoria, la deuda, el chisme o la manera de hablar de su zona
	if not ya:
		await say(pick(ct.greet), N)
	var bus := "" if ext else cal_busco(c)
	if ext:
		await say(T("Busco {g} g de rosin o de hachís.", {"g": n(c.want)}), N)
	elif bus != "":
		await say(bus, N)
	else:
		await say(T("Busco {g} g de algo potente, mínimo {thc}% de THC.", {"g": n(c.want), "thc": n(c.minThc)}) if c.minThc else T("Busco {g} g.", {"g": n(c.want)}), N)
	var lots := rosin_lots(c.want) if ext else bud_lots(c.want, c.minThc)
	if lots.is_empty():
		await say(K("Eso no me vale. Vuelve cuando tengas lo que busco.") if (total_rosin() if ext else total_buds()) > 0 else K("¿No llevas nada? Vale."), N)
		return
	var it := lots.map(rosin_item if ext else lot_item)
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Qué le vendes?")})
	if i < 0 or i >= lots.size():
		await say(K("Vale, otro día."), N)
		return
	var sid: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var xn: String = (D.EXTR[tipo_extr(sid)].n.to_lower() + " ") if ext else ""
	var base: float = (precio_rosin(b.thc) * D.EXTR[tipo_extr(sid)].px if ext else precio_calle(b.thc)) * calidad(b, not ext) * ct.mult * D.ZONAS[c.get("map", "town")].precio * rival_f(c.get("map", "town")) * c.want
	if Datos.CAL and not ext:   # MAESTRO [5]: la misma cepa, mucho en el mismo pueblo, hasta la mitad
		var sat := saturado(lot_sid(sid), c.get("map", "town"))
		base *= sat
		if sat < .8:
			await say(K("Esa la está vendiendo todo el mundo por aquí. Ya no se paga como antes."), N)
		base *= cal_precio(c, sid, b)   # MAESTRO [7]: el pedido acertado
	var pr := [Datos.jsround(base * .85), Datos.jsround(base), Datos.jsround(base * 1.3)]
	var j: int = await ask(T("{g} g de {x} de {nom}. ¿Cuánto le pides?", {"g": n(c.want), "x": xn.substr(0, xn.length() - 1), "nom": lot_nombre(sid)}) if ext else T("{g} g de {nom}. ¿Cuánto le pides?", {"g": n(c.want), "nom": lot_nombre(sid)}), [T("Rebaja · {p} €", {"p": int(pr[0])}), T("Justo · {p} €", {"p": int(pr[1])}), T("Caro · {p} €", {"p": int(pr[2])}), K("Cancelar")])
	if j == 3:
		await say(K("Entonces me voy."), N)
		return
	var mt: float = 50.0 if ext else (c.minThc if c.minThc else 14)
	var acc: float = [1.0, .92, clampf(.3 + (b.thc - mt) * .05 + (.25 if c.type == "pij" else 0.0) + (.15 if c.type == "tur" else 0.0) + (.3 if c.type == "vip" else 0.0), .1, .9)][j]
	if j > 0:   # 1.15: la confianza de los de la agenda, la cata y el análisis
		acc = minf(.97, acc + (rel(c.fid) / 250.0 if c.get("fid") else 0.0) + (.05 if b.get("cata") else 0.0) + (.1 if b.get("ana") else 0.0))
	if Datos.CAL and not ext:
		acc = cal_acc(c, sid, b, j, acc)
	if Cultivo.azar() < acc:
		var fio: int = 0 if ext else await cal_fiar(c, int(pr[j]))   # MAESTRO [7]: fiárselo a uno de la agenda
		if c.get("fid"):
			confia(c.fid, [3, 2, 1][j])
		if ext:
			use_rosin(sid, c.want)
		else:
			use_buds(sid, c.want)
		if not fio:
			S.money += pr[j]
			S.sales += pr[j]
		if Datos.CAL and not ext:
			satura(lot_sid(sid), c.get("map", "town"), c.want)
		var fc := calle_tiempo()
		S.heat = minf(100, Datos.jsround((S.heat + (D.CALOR_CALLE.base + c.want * (D.CALOR_CALLE.rosin if ext else D.CALOR_CALLE.g)) * fc) * 10) / 10.0)
		S.rep += [3, 2, 1][j]
		sfx("coin")
		await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
		remove_client(c.id)
		apunta_fijo(c)
		var fr := "" if ext else cal_frase("si", c)
		await say(fr if fr != "" else pick([K("Trato hecho."), K("Gracias. Nos vemos."), K("Bien. Se lo diré a mis amigos.")]), N)
		toast(T("+{p} · {g} g de {x} vendidos", {"p": Datos.eur(pr[j]), "g": n(c.want), "x": xn.substr(0, xn.length() - 1)}) if ext else (T("Fiado · {g} g", {"g": n(c.want)}) if fio else T("+{p} · {g} g vendidos", {"p": Datos.eur(pr[j]), "g": n(c.want)})), 1600)
		if not ext:
			await cal_vendido(c, sid, b, N)
		visto_vender()
		heat_warn()
		await check_story()
		rival_venta(c.get("map", "town"))
		# en las esquinas de Darko (1.10), 1 de cada 3 ventas acaba con uno de sus chicos encima
		if c.get("map") == "astilleros" and not S.flags.get("darkoFin") and Cultivo.azar() < 1.0 / 3:
			await say(K("Uno de los chicos de Darko te ha visto vender."))
			await say(K("«Te dijimos que lejos de nuestras esquinas.»"), K("CHICO DE DARKO"))
			await battle("thief")
	else:
		S.rep = maxi(0, S.rep - 1)
		if c.get("fid"):
			confia(c.fid, -2)
		sfx("bad")
		remove_client(c.id)
		var fr := "" if ext else cal_frase("no", c)
		await say(fr if fr != "" else pick([K("¿Tanto? No."), K("A ese precio, paso."), K("Eso es demasiado. Adiós.")]), N)

# MAESTRO [5]: la saturación del mercado. S.sat[pueblo][cepa] = gramos vendidos en la calle de ese pueblo; con SATURA.g, el precio
# baja SATURA.baja (la mitad), y cada día se olvida SATURA.dia de lo vendido (sat_dia, desde new_day)
func saturado(sid: String, mapa: String) -> float:
	var g := float(S.get("sat", {}).get(preload("res://src/croquis.gd").pueblo_de(mapa), {}).get(sid, 0))
	return 1 - float(D.SATURA.baja) * minf(1, g / float(D.SATURA.g))

func satura(sid: String, mapa: String, g: float) -> void:
	if not S.has("sat"):
		S.sat = {}
	var pu := preload("res://src/croquis.gd").pueblo_de(mapa)
	if not S.sat.has(pu):
		S.sat[pu] = {}
	S.sat[pu][sid] = float(S.sat[pu].get(sid, 0)) + g

func sat_dia() -> void:
	for pu in S.get("sat", {}).keys():
		for k in S.sat[pu].keys():
			S.sat[pu][k] = float(S.sat[pu][k]) * (1 - float(D.SATURA.dia))
			if S.sat[pu][k] < 1:
				S.sat[pu].erase(k)
		if S.sat[pu].is_empty():
			S.sat.erase(pu)

# policía por niveles (1.11, 11-historia): el nivel por el calor (con la orden, 3), lo que baja cada día y la multa de la redada
func nivel_poli() -> int:
	if S.get("orden"):
		return 3
	var n := 0
	for i in D.NIVEL_POLI.size():
		if S.heat >= D.NIVEL_POLI[i][0]:
			n = i
	return n

func baja_calor() -> float:
	return D.NIVEL_POLI[nivel_poli()][2] * (1.5 if S.protect else 1.0)

func multa_redada(plantas: int, g: int) -> int:
	return mini(int(D.MULTA_TOPE), int(D.MULTA_REDADA) + int(D.MULTA_PLANTA) * plantas + int(D.MULTA_G) * g)

# Un aviso antes, con 50 (con 60 investigan), que dice por dónde se vende sin tanto calor
func heat_warn() -> void:
	if S.heat >= 70 and not S.flags.get("heatW"):
		S.flags.heatW = true
		S.flags.heatA = true
		toast(T("<small>CUIDADO</small>La policía investiga. Si el calor llega a {n} al cambiar el día, habrá orden de registro.", {"n": int(D.NIVEL_POLI[3][0])}), 3200)
	elif S.heat >= D.CALOR_AVISO and S.heat < 70 and not S.flags.get("heatA"):
		S.flags.heatA = true
		toast(T("<small>CALOR</small>Con {n}, la policía investiga. Vende menos en la calle: Iñaki compra al por mayor con menos calor.", {"n": int(D.NIVEL_POLI[2][0])}) if S.ch >= 3 else T("<small>CALOR</small>Con {n}, la policía investiga. Vende menos en la calle: Iñaki compra 10 g al día con menos calor.", {"n": int(D.NIVEL_POLI[2][0])}), 3200)
	if S.heat < 60:
		S.flags.heatW = false
	if S.heat < D.CALOR_AVISO - 10:
		S.flags.heatA = false

func re_calle() -> RegEx:
	if _re_calle == null:
		_re_calle = RegEx.create_from_string(D.CALLE)
		_re_tapa = RegEx.create_from_string(D.TAPA_VISTA)
	return _re_calle

func n_patrullas() -> int:
	var p = D.PATRULLAS.get(S.map)
	var k := int(p[1 if is_night() else 0]) if p != null and S.ch >= 2 else 0
	return k + 1 if k and nivel_poli() >= 2 else k   # investigación (1.11): una más

# lo que enseña la barra del HUD: si cambia, el HUD se rehace sin esperar a su cuarto de segundo
func sosp_hud():
	return ("A" if SOSP.alarma != null else str(Datos.jsround(SOSP.v))) if n_patrullas() else ""

func carga_sosp() -> float:
	return total_buds() + total_rosin()

func sitio_patrulla(i: int) -> Array:
	var l: Array = D.RONDA[S.map]
	var h0 := _hash_t(S.day * 7 + i * 131, S.map.length() * 17 + i)
	for k in l.size():
		var t: Array = l[(h0 + k * 61) % l.size()]
		if absi(t[0] - P.x) + absi(t[1] - P.y) >= 6 and ent_at(t[0], t[1]) == null:
			return [int(t[0]), int(t[1])]
	var t0: Array = l[h0 % l.size()]
	return [int(t0[0]), int(t0[1])]

func mk_patrulla(i: int) -> Dictionary:
	var xy := sitio_patrulla(i)
	var x: int = xy[0]
	var y: int = xy[1]
	var d := {"id": "pat%d" % i, "map": S.map, "x": x, "y": y, "look": "cop"}
	return {"id": d.id, "x": x, "y": y, "px": x * 16.0, "py": y * 16.0, "hx": x, "hy": y, "dir": ["down", "left", "up", "right"][_hash_t(x, y) % 4], "look": D.LOOKS.cop,
		"def": d, "wander": 0, "wt": 0, "moving": false, "t": 0.0, "fx": x, "fy": y, "act": null,
		"pat": true, "mapa": S.map, "pasos": 6 + _hash_t(y, x) % 6, "espera": 0.0, "giro": 0, "caza": false, "dur": float(D.PAT.paso[0])}

func pon_patrullas() -> void:
	var nn := n_patrullas()
	var hay := ents.filter(func(e): return e.get("pat")).size()
	for i in range(hay, nn):
		ents.append(mk_patrulla(i))
	if hay > nn:
		ents = ents.filter(func(e): return not e.get("pat") or int(e.id.substr(3)) < nn)

# ¿ve el agente e la casilla (x, y)? En su cono (o, con lejos, a lejos casillas a la redonda) o pegada a él, con la línea limpia
func ve_casilla(e: Dictionary, x: int, y: int, lejos: int) -> bool:
	re_calle()
	var dx: int = x - e.x
	var dy: int = y - e.y
	var ad := absi(dx) + absi(dy)
	if ad == 0:
		return true
	var m: Dictionary = MAPS[S.map]
	if ad > 1:
		if lejos:
			if ad > lejos:
				return false
		else:
			var f: Array = DV[e.dir]
			var fr: int = dx * f[0] + dy * f[1]
			var la: int = absi(dx * f[1]) + absi(dy * f[0])
			if fr <= 0 or la > fr or fr > vista_pat():
				return false
	var nn := maxi(absi(dx), absi(dy))
	for s in range(1, nn):
		var cx: int = e.x + Datos.jsround(float(dx) * s / nn)
		var cy: int = e.y + Datos.jsround(float(dy) * s / nn)
		var o = m.o[cy][cx]
		if _re_edif.search(m.g[cy][cx]) != null or (o and _re_tapa.search(o) != null):
			return false
	return true

func te_pilla(e: Dictionary) -> bool:
	return ve_casilla(e, P.x, P.y, vista_pat(true) if e.caza else 0)

func _libre_ronda(e: Dictionary, m: Dictionary, d: String) -> bool:
	var nx: int = e.x + DV[d][0]
	var ny: int = e.y + DV[d][1]
	var k := "%d,%d" % [nx, ny]
	if nx < 0 or ny < 0 or nx >= m.w or ny >= m.h or re_calle().search(m.g[ny][nx]) == null:
		return false
	return not tile_solid(m, nx, ny) and ent_at(nx, ny) == null and not (nx == P.x and ny == P.y) and not (P.moving and nx == P.fx and ny == P.fy) \
		and not m.doors.has(k) and not m.exits.has(k) and not llegada_bus(nx, ny)

# un paso de ronda: recto si puede (3 de cada 4), si no, a un lado; media vuelta solo en un callejón
func paso_ronda(e: Dictionary, m: Dictionary) -> void:
	if re_calle().search(m.g[e.y][e.x]) == null:
		paso_vuelta(e, m)
		return
	var ops := ["up", "down", "left", "right"].filter(func(d): return d != OPP[e.dir] and _libre_ronda(e, m, d))
	var otras := ops.filter(func(d): return d != e.dir)
	var d = null
	if ops.has(e.dir) and Cultivo.azar() < .75:
		d = e.dir
	elif otras.size():
		d = pick(otras)
	elif ops.size():
		d = ops[0]
	elif _libre_ronda(e, m, OPP[e.dir]):
		d = OPP[e.dir]
	if d == null:
		return
	e.dir = d
	e.fx = e.x
	e.fy = e.y
	e.x += DV[d][0]
	e.y += DV[d][1]
	e.t = 0.0
	e.moving = true
	e.dur = float(D.PAT.paso[1 if is_night() else 0])

# fuera de la calle (tras una caza, por la hierba o el parque): un paso por el camino más corto a la calle más cercana
func paso_vuelta(e: Dictionary, m: Dictionary) -> void:
	var k0 := "%d,%d" % [e.x, e.y]
	var prev := {k0: null}
	var q := [[e.x, e.y]]
	var fin = null
	var qi := 0
	while qi < q.size() and fin == null:
		var c: Array = q[qi]
		qi += 1
		for d in ["up", "down", "left", "right"]:
			var nx: int = c[0] + DV[d][0]
			var ny: int = c[1] + DV[d][1]
			var k := "%d,%d" % [nx, ny]
			if prev.has(k) or tile_solid(m, nx, ny) or m.doors.has(k) or m.exits.has(k) or (nx == P.x and ny == P.y) or (P.moving and nx == P.fx and ny == P.fy) \
					or ents.any(func(o): return not is_same(o, e) and o.x == nx and o.y == ny):
				continue
			prev[k] = [c[0], c[1], d]
			if re_calle().search(m.g[ny][nx]) != null:
				fin = k
				break
			q.append([nx, ny])
	if fin == null:
		return
	var k: String = fin
	var p: Array = prev[k]
	while "%d,%d" % [p[0], p[1]] != k0:
		k = "%d,%d" % [p[0], p[1]]
		p = prev[k]
	var xy := k.split(",")
	e.dir = p[2]
	e.fx = e.x
	e.fy = e.y
	e.x = int(xy[0])
	e.y = int(xy[1])
	e.t = 0.0
	e.moving = true
	e.dur = float(D.PAT.paso[1 if is_night() else 0])

# un paso de caza: el primero del camino más corto hasta el jugador (por lo que no es sólido, sin puertas ni salidas ni gente)
func paso_caza(e: Dictionary, m: Dictionary) -> void:
	var k0 := "%d,%d" % [e.x, e.y]
	var prev := {k0: null}
	var q := [[e.x, e.y]]
	var fin = null
	var qi := 0
	while qi < q.size() and fin == null:
		var c: Array = q[qi]
		qi += 1
		for d in ["up", "down", "left", "right"]:
			var nx: int = c[0] + DV[d][0]
			var ny: int = c[1] + DV[d][1]
			var k := "%d,%d" % [nx, ny]
			if prev.has(k):
				continue
			if nx == P.x and ny == P.y:
				prev[k] = [c[0], c[1], d]
				fin = k
				break
			if tile_solid(m, nx, ny) or m.doors.has(k) or m.exits.has(k) or ents.any(func(o): return not is_same(o, e) and o.x == nx and o.y == ny):
				continue
			prev[k] = [c[0], c[1], d]
			q.append([nx, ny])
	if fin == null:
		return
	var k: String = fin
	var p: Array = prev[k]
	while "%d,%d" % [p[0], p[1]] != k0:
		k = "%d,%d" % [p[0], p[1]]
		p = prev[k]
	e.dir = p[2]
	var xy := k.split(",")
	var nx := int(xy[0])
	var ny := int(xy[1])
	if nx == P.x and ny == P.y:
		return
	e.fx = e.x
	e.fy = e.y
	e.x = nx
	e.y = ny
	e.t = 0.0
	e.moving = true
	e.dur = float(D.PAT.corre[1 if is_night() else 0])

# en el mundo y libre (update): mueve a los agentes, sube o baja la sospecha y lleva la alarma
func update_patrullas(dt: float) -> void:
	if not D.ZONAS.has(S.map):
		return
	if ents.filter(func(e): return e.get("pat")).size() != n_patrullas():
		pon_patrullas()
	var pats := ents.filter(func(e): return e.get("pat"))
	var m: Dictionary = MAPS[S.map]
	if pats.is_empty():
		SOSP.v = 0.0
		return
	for e in pats:
		if e.moving:
			e.t += dt
			var k := minf(1, e.t / e.dur)
			e.px = (e.fx + (e.x - e.fx) * k) * 16
			e.py = (e.fy + (e.y - e.fy) * k) * 16
			if k >= 1:
				e.moving = false
				e.fx = e.x
				e.fy = e.y
			continue
		if e.caza:
			if e.espera > 0:   # el «¡alto!» (PAT.alto ms quieto)
				e.espera -= dt
				continue
			if absi(e.x - P.x) + absi(e.y - P.y) == 1 and not P.moving:
				pillado(e)
				return
			paso_caza(e, m)
			continue
		if e.espera > 0:
			e.espera -= dt
			if e.espera <= 600 and not e.giro:
				e.giro = 1
				e.dir = pick(["up", "down", "left", "right"])
			continue
		e.pasos -= 1
		if e.pasos <= 0:
			e.pasos = 6 + int(floor(Cultivo.azar() * 6))
			e.espera = 900 + Cultivo.azar() * 900
			e.giro = 0
			continue
		paso_ronda(e, m)
	var ve = null
	for e in pats:
		if te_pilla(e):
			ve = e
			break
	var seg := dt / 1000.0
	if SOSP.alarma != null:
		var e = null
		for p in pats:
			if p.id == SOSP.alarma:
				e = p
		if e == null:   # al cambiar el turno se va el que te seguía
			SOSP.alarma = null
			SOSP.v = 50.0
			music(map_music())
			toast(K("Lo has despistado."), 1600)
			return
		if ve:
			SOSP.sinVer = 0.0
		else:
			SOSP.sinVer += dt
		if SOSP.sinVer >= D.PAT.olvida and absi(e.x - P.x) + absi(e.y - P.y) > D.PAT.pierde:
			e.caza = false
			e.espera = 1200.0
			SOSP.alarma = null
			SOSP.v = 50.0
			music(map_music())
			toast(K("Lo has despistado."), 1600)
		return
	if SOSP.tregua > 0:
		SOSP.tregua -= dt
	var g := 0.0 if SOSP.tregua > 0 else carga_sosp()
	if ve and g > 0:
		SOSP.v = minf(100, SOSP.v + (8 + minf(g, 100) * .12) * float(D.PAT.sube[1 if is_night() else 0]) * (1 + S.heat / 100.0) * (.4 if S.protect else 1.0) * seg \
			* (float(D.FISIO.indica.sosp) if efecto() == "indica" else 1.0))   # MAESTRO [2]: con la índica, tranquilo, levantas menos sospechas
		if not SOSP.aviso and (not is_night() or SOSP.v >= 40):
			SOSP.aviso = 1
			toast(K("Oyes pasos detrás de ti.") if is_night() else K("Un agente te está mirando."), 1800)
	else:
		SOSP.v = maxf(0, SOSP.v - D.PAT.baja * seg)
	if SOSP.v >= 100:
		alarma(ve if ve else pats[0])

func alarma(e: Dictionary) -> void:
	SOSP.alarma = e.id
	SOSP.sinVer = 0.0
	e.caza = true
	e.espera = float(D.PAT.alto)
	sfx("enc")
	music(map_music())
	toast(K("<small>¡ALTO, POLICÍA!</small>Corre (B): métete en un portal o aléjate."), 2200)

# vender cerca de un agente (talk_client), aunque no mire: la sospecha sube de golpe
func visto_vender() -> void:
	if SOSP.alarma != null:
		return
	for e in ents:
		if e.get("pat") and ve_casilla(e, P.x, P.y, vista_pat()):
			SOSP.v = minf(100, SOSP.v + D.PAT.vende)
			SOSP.aviso = 1
			toast(K("Un agente te ha visto vender."), 1600)
			return

# te alcanza: el control de siempre (battle); después, una tregua
func pillado(e: Dictionary) -> void:
	e.caza = false
	e.espera = 1500.0
	e.dir = OPP[P.dir]
	SOSP = {"v": 0.0, "alarma": null, "sinVer": 0.0, "aviso": 1, "tregua": float(D.PAT.tregua)}
	run(func(): await battle("police"))

# al cambiar de mapa (enter_map): la sospecha y la alarma se quedan en la calle
func reset_sosp() -> void:
	SOSP = {"v": 0.0, "alarma": null, "sinVer": 0.0, "aviso": 0, "tregua": 0.0}

func pieza_de(mapa: String, k: String) -> Dictionary:
	for P_ in D.ORDEN_P[mapa].piezas:
		if P_.k == k:
			return P_
	return {}

func pieza_ya(P_: Dictionary) -> bool:
	match str(P_.get("si", "")):
		"extr":
			return mueble_ya(D.MUEBLE_EXTR[P_.k])
		"mueble":
			return P_.k in muebles_ya()
		"riego":
			return S.get("nave") != null and int(S.nave.get("rg", 0)) >= 1
		"cal":   # 1.55.1: la cama, el ordenador de la tía y la mesa de cruces, con CAL
			return Datos.CAL
		"carpa":   # 1.55: la carpa que tengas, con CAL
			var ci := int(str(P_.k).substr(5))
			return Datos.CAL and ci < S.carpas.size() and S.carpas[ci] is Dictionary
	return true

func piezas_ya(mapa: String) -> Array:
	return D.ORDEN_P[mapa].piezas.filter(func(P_): return pieza_ya(P_))

func pos_pieza(mapa: String, k: String) -> Array:
	if ORDEN != null and ORDEN.mapa == mapa and ORDEN.k == k:
		return [int(ORDEN.x), int(ORDEN.y)]
	var c = S.get("coloca") if S != null else null
	if c is Dictionary and c.get(mapa) is Dictionary and c[mapa].has(k):
		return [int(c[mapa][k][0]), int(c[mapa][k][1])]
	var d: Array = pieza_de(mapa, k).def
	return [int(d[0]), int(d[1])]

func celdas_p(P_: Dictionary, x: int, y: int) -> Array:
	var l := []
	for o in P_.o:
		var ob_ = o[2] if o.size() > 2 else null
		if o.size() > 3 and not (S.get("nave") != null and int(S.nave.get("rg", 0)) >= int(o[3])):
			ob_ = null
		l.append([x + int(o[0]), y + int(o[1]), ob_])
	return l

func gente_p(P_: Dictionary, x: int, y: int) -> Array:
	var l := []
	for g in P_.get("gente", []):
		l.append([x + int(g[0]), y + int(g[1]), g[2], g[3]])
	return l

func gente_fija(mapa: String) -> Array:
	var con := {}
	for P_ in D.ORDEN_P[mapa].piezas:
		for g in P_.get("gente", []):
			con[g[2]] = true
	var l := []
	for d in D.NPCDEF:
		if d.map == mapa and not con.has(d.id):
			l.append([int(d.x), int(d.y)])
	return l

func hueco_carpa(mapa: String) -> Array:
	var l := []
	if mapa != "home":
		return l
	for ci in D.SITIOS.size():
		if sitio_visible(ci):
			var s: Dictionary = sitio(ci)
			for j in int(s.w):
				l.append([int(s.x) + j, int(s.y)])
	return l

func pisable(m: Dictionary, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= int(m.w) or y >= int(m.h):
		return false
	var k := "%d,%d" % [x, y]
	return SOLID_G.search(m.g[y][x]) == null and m.g[y][x] != "mat" and not m.exits.has(k) and not m.doors.has(k)

func andable(m: Dictionary, O: Array, B := {}) -> Dictionary:
	var v := {}
	var q := []
	var semillas: Array = m.exits.keys()
	for mp in (D.PUERTAS_INT if Datos.CAL and D.has("PUERTAS_INT") else {}):   # 1.51: las puertas de dentro también son entradas
		if is_same(MAPS.get(mp), m):
			for e in D.PUERTAS_INT[mp]:
				semillas.append("%d,%d" % [int(e.x), int(e.y)])
	for k in semillas:
		var p: PackedStringArray = k.split(",")
		var x := int(p[0])
		var y := int(p[1])
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			var nx: int = x + d[0]
			var ny: int = y + d[1]
			var kk := "%d,%d" % [nx, ny]
			if not v.has(kk) and pisable(m, nx, ny) and not O[ny][nx] and not B.has(kk):
				v[kk] = true
				q.append([nx, ny])
	var i := 0
	while i < q.size():
		var c: Array = q[i]
		i += 1
		for d in DIRS_ORDEN:
			var nx: int = c[0] + d[0]
			var ny: int = c[1] + d[1]
			var kk := "%d,%d" % [nx, ny]
			if not v.has(kk) and pisable(m, nx, ny) and not O[ny][nx] and not B.has(kk):
				v[kk] = true
				q.append([nx, ny])
	return v

func copia_o(m: Dictionary) -> Array:
	return m.o.map(func(r): return r.duplicate())

func sin_pieza(mapa: String, k: String) -> Array:
	var m: Dictionary = MAPS[mapa]
	var O := copia_o(m)
	var P_ := pieza_de(mapa, k)
	var op = m.get("opos", {})
	if op.has(k) and not P_.get("suelo"):
		for c in celdas_p(P_, int(op[k][0]), int(op[k][1])):
			if c[1] >= 0 and c[1] < O.size() and c[0] >= 0 and c[0] < O[c[1]].size():
				O[c[1]][c[0]] = null
	return O

# '' si la pieza k cabe en (x, y); si no, el motivo (D.ORDEN_MOTIVO)
func cabe_pieza(mapa: String, k: String, x: int, y: int, O = null, jug := true) -> String:
	if O == null:
		O = sin_pieza(mapa, k)
	var m: Dictionary = MAPS[mapa]
	var Dm: Dictionary = D.ORDEN_P[mapa]
	var P_ := pieza_de(mapa, k)
	var F := celdas_p(P_, x, y)
	var G := gente_p(P_, x, y)
	for c in F + G:
		if c[0] < 0 or c[1] < 0 or c[0] >= int(m.w) or c[1] >= int(m.h):
			return "fuera"
	var fila := func(cy: int, dy: int) -> bool:
		if dy < 0:
			return cy == 1
		if P_.has("fila"):
			return cy == int(P_.fila)
		return cy >= int(Dm.filas[0]) and cy <= int(Dm.filas[1])
	if P_.get("suelo"):
		for c in F:
			if not fila.call(c[1], 0) or not pisable(m, c[0], c[1]):
				return "fuera"
		return ""
	for j in F.size():
		var dy := int(P_.o[j][1])
		if not fila.call(F[j][1], dy) or (dy >= 0 and not pisable(m, F[j][0], F[j][1])):
			return "fuera"
	for c in G:
		if not pisable(m, c[0], c[1]):
			return "fuera"
	var res := {}
	for c in gente_fija(mapa) + Dm.pie + reserva_orden(mapa):
		res["%d,%d" % [int(c[0]), int(c[1])]] = true
	var otras: Array = piezas_ya(mapa).filter(func(Q): return Q.k != k)
	for Q in otras:
		var q := pos_pieza(mapa, Q.k)
		for g in gente_p(Q, q[0], q[1]):
			res["%d,%d" % [g[0], g[1]]] = true
	var hueco := {}
	for c in hueco_carpa(mapa):
		hueco["%d,%d" % [c[0], c[1]]] = true
	for c in F + G:
		var kk := "%d,%d" % [c[0], c[1]]
		if hueco.has(kk):
			return "carpa"
		if O[c[1]][c[0]] or res.has(kk):
			return "ocupado"
	if jug and S.map == mapa:
		for c in F + G:
			if c[0] == int(P.x) and c[1] == int(P.y):
				return "tu"
	var O2: Array = O.map(func(r): return r.duplicate())
	for c in F:
		O2[c[1]][c[0]] = c[2]
	# la gente no se mueve y no se pasa por ella: a cada uno se le habla desde al lado o por encima de un mostrador
	var gente: Array = gente_fija(mapa) + G
	for Q in otras:
		var q := pos_pieza(mapa, Q.k)
		gente += gente_p(Q, q[0], q[1])
	var B := {}
	for g in gente:
		B["%d,%d" % [int(g[0]), int(g[1])]] = true
	var v := andable(m, O2, B)
	var deben: Array = Dm.pie + hueco_carpa(mapa)
	if jug and S.map == mapa:
		deben.append([int(P.x), int(P.y)])
	for c in deben:
		if not v.has("%d,%d" % [int(c[0]), int(c[1])]):
			return "paso"
	for g in gente:
		var gx := int(g[0])
		var gy := int(g[1])
		var ok := false
		for d in DIRS_ORDEN:
			var nx: int = gx + d[0]
			var ny: int = gy + d[1]
			if v.has("%d,%d" % [nx, ny]):
				ok = true
			elif ny >= 0 and ny < O2.size() and nx >= 0 and nx < O2[ny].size() and O2[ny][nx] and v.has("%d,%d" % [gx + 2 * d[0], gy + 2 * d[1]]):
				ok = true
			if ok:
				break
		if not ok:
			return "paso"
	for cy in range(2, int(m.h)):
		for cx in int(m.w):
			var o = O2[cy][cx]
			if not o or ORDEN_SIN_LADO.search(o) != null:
				continue
			var lado := false
			for d in DIRS_ORDEN:
				var kd := "%d,%d" % [cx + d[0], cy + d[1]]
				if v.has(kd) or B.has(kd):
					lado = true
					break
			if not lado:
				return "paso"
	if mapa == "nave" and S.get("nave") != null and int(S.nave.get("rg", 0)) >= 1:
		var pos := {k: [x, y]}
		for i in D.MESAS_X.size():
			if ruta_riego(i, O2, pos) == null:
				return "riego"
	return ""

# quita las piezas del mapa (las de serie del plano la primera vez: las que están enteras en su sitio de serie)
func quita_orden(mapa: String) -> void:
	var m: Dictionary = MAPS[mapa]
	if not m.has("opos"):
		m.opos = {}
		for P_ in D.ORDEN_P[mapa].piezas:
			if P_.get("suelo") or P_.get("si") == "carpa" or (P_.get("si") == "cal" and not Datos.CAL):   # 1.55: las carpas las pone montar_casa
				continue
			var ok := true
			for o in P_.o:
				var yy: int = int(P_.def[1]) + int(o[1])
				var xx: int = int(P_.def[0]) + int(o[0])
				if not (yy >= 0 and yy < int(m.h) and xx >= 0 and xx < int(m.w) and m.o[yy][xx] == (o[2] if o.size() > 2 else null)):
					ok = false
					break
			if ok:
				m.opos[P_.k] = [int(P_.def[0]), int(P_.def[1])]
	for k in m.opos:
		var P_ := pieza_de(mapa, k)
		if P_.get("suelo"):
			continue
		for o in P_.o:
			var xx: int = int(m.opos[k][0]) + int(o[0])
			var yy: int = int(m.opos[k][1]) + int(o[1])
			if xx >= 0 and yy >= 0 and xx < int(m.w) and yy < int(m.h):
				m.o[yy][xx] = null
	m.opos = {}

# monta las piezas: cada una donde se eligió; si ya no cabe, en su sitio de reserva o en el libre más cercano (y se apunta)
func aplica_orden(mapa: String) -> void:
	if not MAPS.has(mapa) or S == null:
		return
	var m: Dictionary = MAPS[mapa]
	quita_orden(mapa)
	for P_ in piezas_ya(mapa):
		var p := pos_pieza(mapa, P_.k)
		if cabe_pieza(mapa, P_.k, p[0], p[1], copia_o(m), false) != "":
			var cs := []
			if P_.has("alt"):
				cs.append([int(P_.alt[0]), int(P_.alt[1])])
			cs += cercanas(m, p)
			var hit = null
			for c in cs:
				if cabe_pieza(mapa, P_.k, c[0], c[1], copia_o(m), false) == "":
					hit = c
					break
			if hit == null:
				continue
			p = hit
			if not (S.get("coloca") is Dictionary):
				S.coloca = {}
			if not S.coloca.has(mapa):
				S.coloca[mapa] = {}
			S.coloca[mapa][P_.k] = [p[0], p[1]]
		m.opos[P_.k] = [p[0], p[1]]
		if not P_.get("suelo"):
			for c in celdas_p(P_, p[0], p[1]):
				if c[0] >= 0 and c[1] >= 0 and c[0] < int(m.w) and c[1] < int(m.h):
					m.o[c[1]][c[0]] = c[2]

func cercanas(m: Dictionary, p: Array) -> Array:
	var c := []
	for y in int(m.h):
		for x in int(m.w):
			c.append([x, y])
	var x0: int = p[0]
	var y0: int = p[1]
	c.sort_custom(func(a, b):
		var da: int = absi(a[0] - x0) + absi(a[1] - y0)
		var db: int = absi(b[0] - x0) + absi(b[1] - y0)
		if da != db:
			return da < db
		if a[1] != b[1]:
			return a[1] < b[1]
		return a[0] < b[0])
	return c

func coloca_gente(mapa: String) -> void:
	if mapa == "nave":
		coloca_naveros()
		return
	for P_ in piezas_ya(mapa):
		var q := pos_pieza(mapa, P_.k)
		for g in gente_p(P_, q[0], q[1]):
			for e in ents:
				if e.id == g[2]:
					e.x = g[0]; e.y = g[1]; e.px = g[0] * 16.0; e.py = g[1] * 16.0; e.hx = g[0]; e.hy = g[1]; e.fx = g[0]; e.fy = g[1]; e.dir = g[3]; e.moving = false
					break

func montar_club(mapa: String) -> void:
	if mapa.begins_with("club-") and D.ORDEN_P.has(mapa):
		aplica_orden(mapa)
	if mapa == "club-rv":   # 1.45 (lo pidió el usuario): el almacén del club, de presidente (MERCADO.alm)
		var m: Dictionary = MAPS[mapa]
		for y in int(m.h):
			for x in int(m.w):
				if m.o[y][x] == "almC":
					m.o[y][x] = null
		if Datos.CAL and S != null and S.get("aso") is Dictionary and S.aso.get("pres"):
			for q in [[9, 2], [12, 2], [13, 2], [11, 2]]:
				if m.o[q[1]][q[0]] == null and m.o[q[1] + 1][q[0]] == null:
					m.o[q[1]][q[0]] = "almC"   # i18n-no
					break

# el marco de la pieza en el cursor: verde si cabe, rojo si no; y la casilla de su gente, en azul
func rects_orden() -> Array:
	if ORDEN == null:
		return []
	var P_ := pieza_de(ORDEN.mapa, ORDEN.k)
	var F := []
	var cs := celdas_p(P_, ORDEN.x, ORDEN.y)
	for j in cs.size():
		if P_.get("suelo") or int(P_.o[j][1]) >= 0:
			F.append(cs[j])
	var c := "#e04040" if ORDEN.no != "" else "#58d080"
	var x0 := 99999
	var y0 := 99999
	var x1 := -99999
	var y1 := -99999
	for f in F:
		x0 = mini(x0, f[0] * 16); y0 = mini(y0, f[1] * 16); x1 = maxi(x1, (f[0] + 1) * 16); y1 = maxi(y1, (f[1] + 1) * 16)
	var o := [[x0, y0, x1 - x0, 1, c], [x0, y1 - 1, x1 - x0, 1, c], [x0, y0, 1, y1 - y0, c], [x1 - 1, y0, 1, y1 - y0, c]]
	for g in gente_p(P_, ORDEN.x, ORDEN.y):
		o.append([g[0] * 16 + 6, g[1] * 16 + 6, 4, 4, "#80b0f0"])
	return o

# las mesas de la nave, donde estén
func pos_mesa(i: int) -> Array:
	return pos_pieza("nave", "m" + str(i))

func mesa_idx(x: int, y: int) -> int:
	for i in D.MESAS_X.size():
		var p := pos_mesa(i)
		if p[1] == y and (p[0] == x or p[0] + 1 == x):
			return i
	return -1

# la lámpara del billar de la asociación, sobre el billar, donde esté
func luz_club(k: String) -> Dictionary:
	var L: Dictionary = D.LUZ_CLUB[k]
	if k != "rv":
		return L
	var p := pos_pieza("club-rv", "billar")
	var l0: Array = [p[0] * 16 + 16, p[1] * 16 + 6] + L.l[0].slice(2)
	return {"fondo": L.fondo, "l": [l0, L.l[1]]}

# la manguera guiada (rutaRiego): {c, t, lado, Y} o null
func ruta_riego(i: int, O = null, pos := {}):
	var m: Dictionary = MAPS.nave
	if O == null:
		O = m.o
	var XY: Array = pos["m" + str(i)] if pos.has("m" + str(i)) else pos_mesa(i)
	var X: int = int(XY[0])
	var Y: int = int(XY[1])
	var T: int = int((pos.riego if pos.has("riego") else pos_pieza("nave", "riego"))[0])
	var libre := func(x: int, y: int) -> bool: return y >= 3 and pisable(m, x, y) and not O[y][x]
	var fin := func(x: int, y: int) -> String:
		if y == Y - 1 and (x == X or x == X + 1):
			return "up"
		if y == Y and x == X - 1:
			return "right"
		if y == Y and x == X + 2:
			return "left"
		return ""
	var peso := func(c: int) -> float: return (100.0 if c == T else 0.0) + (0.0 if c == X else 0.5 if c == X + 1 else 1.0 + absi(c - X))
	var cols := range(int(m.w))
	cols.sort_custom(func(a, b):
		var pa: float = peso.call(a)
		var pb: float = peso.call(b)
		if pa != pb:
			return pa < pb
		return a < b)
	for c in cols:
		if Y == 3:
			if c == X or c == X + 1:
				return {"c": c, "t": [], "lado": "up", "Y": Y}
			continue
		if not libre.call(c, 3):
			continue
		var pa := {"%d,3" % c: null}
		var q := [[c, 3]]
		var hit = null
		var i_ := 0
		while i_ < q.size():
			var cu: Array = q[i_]
			i_ += 1
			if fin.call(cu[0], cu[1]) != "":
				hit = cu
				break
			for d in DIRS_ORDEN:
				var nx: int = cu[0] + d[0]
				var ny: int = cu[1] + d[1]
				var kk := "%d,%d" % [nx, ny]
				if not pa.has(kk) and libre.call(nx, ny):
					pa[kk] = cu
					q.append([nx, ny])
		if hit == null:
			continue
		var t := []
		var p = hit
		while p != null:
			t.push_front(p)
			p = pa["%d,%d" % [p[0], p[1]]]
		return {"c": c, "t": t, "lado": fin.call(hit[0], hit[1]), "Y": Y}
	return null

# la manguera de la nave (mangueraNave, 11j-locales): el grifo, la tubería por el pie de la pared y cada bajada por su ruta
func manguera_nave() -> Array:
	if S == null or S.get("nave") == null or not int(S.nave.get("rg", 0)):
		return []
	var rg := int(S.nave.rg)
	var key := str(rg) + "|" + JSON.stringify(S.get("coloca", {}).get("nave", {})) + "|" + (str(ORDEN.k) + str(ORDEN.x) + "," + str(ORDEN.y) if ORDEN != null and ORDEN.mapa == "nave" else "")
	if RIEGO_CACHE != null and RIEGO_CACHE.key == key:
		return RIEGO_CACHE.o
	var y: int = int(D.RIEGO_Y)
	var K := "#1c1d22"
	var G := "#3a3c44"
	var L := "#8a92a2"
	var o := []
	var TX: int = pos_pieza("nave", "riego")[0]
	var t0: int = TX * 16 + 8
	var cx: int = (TX + 2) * 16
	var rutas := []
	for i in D.MESAS_X.size():
		var r = ruta_riego(i)
		if r != null:
			rutas.append(r)
	o.append_array([[t0, 0, 1, 12, "#a46e40"], [t0 + 1, 0, 1, 12, "#dcac6c"], [t0 - 2, 12, 5, 2, L], [t0 - 1, 10, 3, 1, "#e04040"], [t0, 9, 1, 1, "#e04040"], [t0, 14, 1, 2, L], [t0, 16, 1, 7, G]])
	var a := t0
	var b := t0
	for r in rutas:
		a = mini(a, int(r.c) * 16 + 8)
		b = maxi(b, int(r.c) * 16 + 8)
	o.append_array([[a, y, b + 1 - a, 1, G], [a, y + 1, b + 1 - a, 1, K]])
	var xx := t0 + 32
	while xx < b:
		o.append([xx, y - 1, 1, 3, L])
		xx += 32
	xx = t0 - 32
	while xx > a:
		o.append([xx, y - 1, 1, 3, L])
		xx -= 32
	for r in rutas:
		var x: int = int(r.c) * 16 + 8
		var pts := [[x, y + 2]]
		for tt in r.t:
			pts.append([int(tt[0]) * 16 + 8, int(tt[1]) * 16 + 8])
		var e: Array = pts[pts.size() - 1]
		pts.append([e[0], int(r.Y) * 16 - 7] if r.lado == "up" else [e[0] + (-9 if r.lado == "left" else 9), e[1]])
		var j := pts.size() - 2
		while j > 0:
			var p0: Array = pts[j - 1]
			var p1: Array = pts[j]
			var p2: Array = pts[j + 1]
			if (p0[0] == p1[0] and p1[0] == p2[0]) or (p0[1] == p1[1] and p1[1] == p2[1]):
				pts.remove_at(j)
			j -= 1
		for jj in range(1, pts.size()):
			var q1: Array = pts[jj - 1]
			var q2: Array = pts[jj]
			if q1[0] == q2[0]:
				o.append_array([[q1[0], mini(q1[1], q2[1]), 1, absi(q2[1] - q1[1]), K], [q1[0] + 1, mini(q1[1], q2[1]), 1, absi(q2[1] - q1[1]), G]])
			else:
				o.append_array([[mini(q1[0], q2[0]), q1[1], absi(q2[0] - q1[0]) + 2, 1, K], [mini(q1[0], q2[0]), q1[1] + 1, absi(q2[0] - q1[0]) + 2, 1, G]])
		if rg < 2:
			o.append_array([[x - 1, y - 1, 3, 2, L], [x - 1, y - 2, 3, 1, "#e04040"]])
		else:
			o.append_array([[x - 1, y - 2, 3, 3, "#4a72c2"], [x - 1, y - 5, 3, 3, "#26262e"]])
			var c: int = cx + (int(D.RIEGO_CTRL[0]) if x < cx + int(D.RIEGO_CTRL[0]) else int(D.RIEGO_CTRL[1]))
			o.append_array([[x, int(D.RIEGO_CABLE), 1, y - 5 - int(D.RIEGO_CABLE), "#26262e"], [mini(x, c), int(D.RIEGO_CABLE), absi(c - x) + 1, 1, "#26262e"]])
	RIEGO_CACHE = {"key": key, "o": o}
	return o
