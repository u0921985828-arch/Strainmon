# F8 (de trama.gd): la plantilla, la compra de la nave, los locales por dentro y el club con el socio y el billar.
extends "res://src/movil.gd"

func gerente():
	for w in S.plantilla:
		if w.get("rol") == "gerente":
			return w
	return null

func naveros() -> Array:
	return S.plantilla.filter(func(w): return w.get("rol") == "nave")

# Con el de las madres (cuida_madres)
func de_la_nave() -> Array:
	return S.plantilla.filter(func(w): return w.get("rol") == "nave" or w.get("rol") == "madres")

# llevar a la gente (1.34, MANDO de 11f-plantilla): una prima (lealtad +1) y un curso (cuidado +1; a los de la calle, labia +1), hasta
# 5, cada uno una vez cada MANDO.dias días por persona (w.pr, w.cu1)
func curso_de(w: Dictionary) -> Array:
	return ["lab", "labia"] if w.get("rol") == "calle" else ["cui", "cuidado"]

func prima(w: Dictionary) -> void:
	var M: Dictionary = D.MANDO
	if w.get("pr") != null and S.day - int(w.pr) < int(M.dias):
		await say(T("A {n} ya le diste una prima el {d}. Hasta el {h}, no.", {"n": w.n, "d": Datos.fd(int(w.pr), S.day), "h": Datos.fd(int(w.pr) + int(M.dias), S.day).trim_prefix("día ")}))
		return
	if w.lea >= 5:
		await say(T("{n} ya te es leal del todo: una prima no le cambia nada.", {"n": w.n}))
		return
	if S.money < M.prima:
		sfx("bad")
		await say(K("No te llega."))
		return
	S.money -= int(M.prima)
	w.pr = S.day
	w.lea = int(w.lea) + 1
	sfx("coin")
	update_hud()
	await say(T("{n}: «Gracias, jefe. Aquí me tienes». Lealtad {l}.", {"n": w.n, "l": int(w.lea)}))

func curso(w: Dictionary) -> void:
	var M: Dictionary = D.MANDO
	var kn := curso_de(w)
	var k: String = kn[0]
	var nn: String = kn[1]
	if int(w[k]) >= 5:
		await say(T("{n} ya tiene labia 5: no hay curso que le enseñe más.", {"n": w.n}) if k == "lab" else T("{n} ya tiene cuidado 5: no hay curso que le enseñe más.", {"n": w.n}))
		return
	if w.get("cu1") != null and S.day - int(w.cu1) < int(M.dias):
		await say(T("{n} hizo un curso el {d}. Hasta el {h}, no.", {"n": w.n, "d": Datos.fd(int(w.cu1), S.day), "h": Datos.fd(int(w.cu1) + int(M.dias), S.day).trim_prefix("día ")}))
		return
	if S.money < M.curso:
		sfx("bad")
		await say(K("No te llega."))
		return
	S.money -= int(M.curso)
	w.cu1 = S.day
	w[k] = int(w[k]) + 1
	sfx("coin")
	update_hud()
	await say(T("{n} hace un curso de venta: a tratar con la gente. Labia {v}.", {"n": w.n, "v": int(w[k])}) if k == "lab" else T("{n} hace un curso de cultivo: riego, plagas y poda. Cuidado {v}.", {"n": w.n, "v": int(w[k])}))

# la mesa de cada trabajador de la nave (1.31: w.mesa, la suya mientras trabaje allí; antes, el orden de la plantilla): quién cuida la
# mesa i y la mesa que le toca al que llega (la primera plantada sin nadie y, si no, la primera libre)
func navero_de(i: int):
	for w in S.plantilla:
		if w.get("rol") == "nave" and w.get("mesa") != null and int(w.mesa) == i:
			return w
	return null

func mesa_libre() -> int:
	var L := []
	for i in int(D.NAVE.max):
		if navero_de(i) == null:
			L.append(i)
	for i in L:
		if S.nave.m[i]:
			return i
	return L[0]

func nave_g(w: Dictionary) -> int:
	return int(D.NAVE.g + D.NAVE.gC * (w.cui - 3))

func rol_txt(w: Dictionary) -> String:
	if w.get("rol") == "calle":
		return T("calle · {g}", {"g": g_txt(w.g)})
	return {"gerente": T("gerente"), "nave": T("nave"), "madres": T("madres")}.get(w.rol, w.rol) if w.get("rol") else T("sin trabajo")

func rol_desc(w: Dictionary) -> String:
	var P: Dictionary = D.PLANTILLA
	match w.get("rol"):
		"calle":
			return T("Vende {l} en la calle: le quedan {g}.", {"l": lot_nombre(w.k), "g": g_txt(w.g)})
		"gerente":
			return T("Cuida el piso y cosecha a la caja fuerte por {e} al día.", {"e": Datos.eur(P.sueldo.gerente)})
		"nave":
			return T("Cultiva la mesa {m} de la nave por {e} al día: con su cuidado, la cosecha da un {p} %.", {"m": int(w.mesa) + 1, "e": Datos.eur(P.sueldo.nave), "p": int(Datos.jsround(100.0 * nave_g(w) / float(D.NAVE.g)))})
		"madres":   # 1.34
			return T("Cuida las madres de la nave por {e} al día y les saca esquejes.", {"e": Datos.eur(P.sueldo.madres)})
	return T("Dale trabajo: calle, gerente, nave o las madres.")

# deja el trabajo; lo que le quedaba del lote vuelve a la caja fuerte
func libre(w: Dictionary) -> void:
	if w.get("rol") == "calle" and w.g >= 1:
		add_buds(w.k, w.g, w.thc, S.caja.buds if S.get("caja") else S.buds, w.get("cu"), w.get("dia"), w.get("mc", 0))
	w.rol = null
	w.erase("k")
	w.erase("thc")
	w.erase("g")
	w.erase("cu")
	w.erase("mc")
	w.erase("dia")
	w.erase("mesa")

func plantilla() -> void:
	var P: Dictionary = D.PLANTILLA
	var i := 0
	while true:
		var L: Array = S.plantilla
		var rows := []
		for w in L:
			rows.append({"label": w.n, "right": rol_txt(w), "desc": ficha_gente(w) + ". " + rol_desc(w)})
		if L.size() < int(P.max):
			rows.append({"label": K("Pedir gente a Patxi"), "right": Datos.eur(P.sobre), "desc": K("Patxi te manda a alguien del barrio que quiere currar. No sabes a quién hasta que llega.")})
		var t2: String = T("{a} de {b} · nave {g}", {"a": L.size(), "b": int(P.max), "g": g_txt(nave_stock())}) if S.get("nave") != null else T("{a} de {b}", {"a": L.size(), "b": int(P.max)})
		i = await menu(rows, {"cls": "full", "title": K("PLANTILLA"), "title2": t2, "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0:
			return
		if i >= L.size():
			await pedir_gente()
		else:
			await trabajo(L[i])

func pedir_gente() -> void:
	var P: Dictionary = D.PLANTILLA
	var libres := []
	for nb in D.BARRIO:
		if not S.plantilla.any(func(w): return w.n == nb):
			libres.append(nb)
	if S.money < P.sobre:
		sfx("bad")
		await say(T("Patxi cobra {e} por el sobre. No te llega.", {"e": Datos.eur(P.sobre)}))
		return
	if libres.is_empty():
		await say(K("Patxi ya no conoce a nadie más que quiera currar."))
		return
	S.money -= int(P.sobre)
	var nm: String = pick(libres)
	S.plN = int(S.plN) + 1
	var w := {"id": "pl%d" % int(S.plN), "n": nm, "lab": ri(1, 5), "cui": ri(1, 5), "lea": ri(1, 5), "rol": null}
	var t: int = w.lab + w.cui + w.lea
	sfx("get")
	await talk(K("SMS · PATXI"), [T("Te mando a {n}. {s}", {"n": nm, "s": K("Vale oro.") if t >= 12 else (K("No es gran cosa, pero quiere currar.") if t <= 6 else K("Gente normal del barrio."))})])
	if await ask(T("{n}: {f}. ¿Le contratas?", {"n": nm, "f": ficha_gente(w)}), [K("Contratar"), K("No")]) != 0:
		await say(T("{n} se va por donde ha venido. El sobre ya es de Patxi.", {"n": nm}))
		return
	S.plantilla.append(w)
	sfx("sel")
	await say(T("{n} entra en tu plantilla. Dale trabajo desde aquí.", {"n": nm}))

# un lote de los de encima para la calle: [clave, THC, gramos] o null
func lote_calle(w: Dictionary):
	var P: Dictionary = D.PLANTILLA
	var lots := bud_lots(P.lotes[0])
	if lots.is_empty():
		await say(T("Para la calle hace falta un lote de {g} g o más encima.", {"g": int(P.lotes[0])}))
		return null
	var it := lots.map(lot_item)
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Qué lote le das?")})
	if i < 0 or i >= lots.size():
		return null
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var ops := []
	for g in P.lotes:
		if g <= floor(b.g):
			ops.append(int(g))
	var o2 := ops.map(func(g): return "%d g" % g)
	o2.append(K("Nada"))
	var j: int = await ask(T("{n} vende a precio de calle y se queda el {p} %. ¿Cuánto le das?", {"n": w.n, "p": int(Datos.jsround(P.com * 100))}), o2)
	if j < 0 or j >= ops.size():
		return null
	var thc: float = b.thc
	var c := cura_de(b)
	use_buds(k, ops[j])
	return [k, thc, ops[j], c]

func trabajo(w: Dictionary) -> void:
	var P: Dictionary = D.PLANTILLA
	var ops := []
	if w.get("rol") != "calle":
		ops.append(K("A la calle"))
	if w.get("rol") != "gerente" and gerente() == null:
		ops.append(K("De gerente"))
	if w.get("rol") != "nave" and S.get("nave") != null and naveros().size() < int(D.NAVE.max):
		ops.append(K("A la nave"))
	if w.get("rol") != "madres" and S.get("nave") != null and cuida_madres() == null:   # 1.34
		ops.append(K("A las madres"))
	if w.get("rol"):
		ops.append(K("Dejarlo libre"))
	var lpr := T("Prima · {e}", {"e": Datos.eur(D.MANDO.prima)})
	var lcu := T("Curso · {e}", {"e": Datos.eur(D.MANDO.curso)})
	ops.append_array([lpr, lcu, K("Despedir"), K("Nada")])
	var oi: int = await ask("%s · %s · %s" % [w.n, ficha_gente(w), rol_txt(w)], ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op == "A la calle":
		var r = await lote_calle(w)
		if r == null:
			return
		libre(w)
		w.rol = "calle"
		w.k = r[0]
		w.thc = r[1]
		w.g = r[2]
		w.merge(r[3], true)
		sfx("sel")
		await say(T("{n}: «Hecho. Cada día te dejo lo vendido en el buzón».", {"n": w.n}))
	elif op == "De gerente":
		libre(w)
		w.rol = "gerente"
		sfx("sel")
		await say(T("{n}: «Cada mañana me paso por el piso: riego, trato las plagas y lo que esté listo lo cosecho y lo dejo en la caja fuerte. {e} al día».", {"n": w.n, "e": Datos.eur(P.sueldo.gerente)}))
	elif op == "A la nave":
		libre(w)
		w.mesa = mesa_libre()
		w.rol = "nave"
		sfx("sel")
		await say(T("{n}: «Mañana empiezo en la mesa {m} de la nave. {e} al día».", {"n": w.n, "m": int(w.mesa) + 1, "e": Datos.eur(P.sueldo.nave)}))
	elif op == "A las madres":
		libre(w)
		w.rol = "madres"
		sfx("sel")
		await say(T("{n}: «Mañana empiezo con las madres de la nave: riego, poda y esquejes. {e} al día».", {"n": w.n, "e": Datos.eur(P.sueldo.madres)}))
	elif op == lpr:
		await prima(w)
	elif op == lcu:
		await curso(w)
	elif op == "Dejarlo libre":
		var g: float = w.g if w.get("rol") == "calle" else 0.0
		libre(w)
		await say(T("{n} te deja lo que le quedaba en la caja fuerte: {g}.", {"n": w.n, "g": g_txt(g)}) if g >= 1 else T("{n} se queda sin trabajo.", {"n": w.n}))
	elif op == "Despedir":
		if await ask(T("¿Despides a {n}?", {"n": w.n}), [K("Despedir"), K("No")]) != 0:
			return
		var g: float = w.g if w.get("rol") == "calle" else 0.0
		libre(w)
		S.plantilla = S.plantilla.filter(func(x): return x != w)
		await say(T("{n} se va. Lo que le quedaba, {g}, está en la caja fuerte.", {"n": w.n, "g": g_txt(g)}) if g >= 1 else T("{n} se va.", {"n": w.n}))

# el gerente, cada mañana: cuida las plantas y cosecha las que están listas a la caja fuerte (su sisa, por la lealtad); da los gramos
func cuidar_casa(w: Dictionary) -> int:
	cuidar_plantas()
	var tot := 0
	for i in S.pots.size():
		var p = S.pots[i]
		if p == null or p.get("dead") or p.prog < 1:
			continue
		var f := factores(i)
		var g := gramos_planta(p, f)
		var thc := Cultivo.thc_cosecha(S, p, f)
		var cl := Cultivo.clase_feno(p.get("f"))
		var sc := semillas_cosecha(p)
		var q: int = g - int(floor(g * D.PLANTILLA.sisa * (5 - w.lea)))
		if q >= 1:
			add_buds(p.sid + "*" if cl == "estrella" else p.sid, q, thc, S.caja.buds if S.get("caja") else S.buds)
		if sc.n:
			add_seeds(p.sid, sc.n)
		if p.get("f") and p.f.get("id"):
			S.fenos[str(int(p.f.id))] = cl
		if S.rec.get(p.sid) == 1:
			S.rec[p.sid] = 2
		S.pots[i] = null
		tot += q
	if tot:
		S.flags.harvest1 = true
		var N: String = K("SMS · ") + w.n.to_upper()
		var tt := tot
		var L := [T("He cosechado {g} g. Está en la caja fuerte.", {"g": tt})]
		queue("gerente", func(): await talk(N, L), [[N, L]])
		queue("historia", check_story)
	return tot

# al amanecer (desde curro_dia): sueldos, el gerente, la calle y la nave
func plantilla_dia() -> void:
	var P: Dictionary = D.PLANTILLA
	var fuera := []
	var vende := false
	nave_alquiler()
	for w in S.plantilla:
		if w.get("rol") == null or not P.sueldo.has(w.rol):   # gerente, nave y madres (1.34)
			continue
		if S.money < P.sueldo[w.rol]:
			w.rol = null
			var N: String = K("SMS · ") + w.n.to_upper()
			queue("pl" + w.id, func(): await talk(N, [K("Sin cobrar no curro. Cuando tengas el dinero, me llamas.")]))
		else:
			S.money -= int(P.sueldo[w.rol])
	var ger = gerente()
	if ger != null:
		cuidar_casa(ger)
	for w in S.plantilla:
		if w.get("rol") != "calle":
			continue
		var N: String = K("SMS · ") + w.n.to_upper()
		var lote := lot_nombre(w.k)
		var r := Cultivo.azar()
		var pp: float = P.poli - P.poliC * (w.cui - 1)
		var pr: float = pp + P.robo - P.roboC * (w.cui - 1)
		var pf: float = pr + P.fuga * (5 - w.lea) / 4 * (.5 if ger != null else 1.0)
		var pt: float = pf + P.timo - P.timoL * (w.lab - 1)
		var m := ""
		if r < pp:
			S.heat = min(100, S.heat + P.calorPoli)
			m = T("Me ha parado la policía. Se han quedado con {g} de {l}. Lo siento.", {"g": g_txt(w.g), "l": lote})
			w.g = 0
		elif r < pr:
			var q: int = int(ceil(w.g / 2.0))
			w.g -= q
			m = T("Me han atracado en un portal. Se han llevado {g} de {l}. Me quedan {q}.", {"g": g_txt(q), "l": lote, "q": g_txt(w.g)}) if w.g >= 1 else T("Me han atracado en un portal. Se han llevado {g} de {l}.", {"g": g_txt(q), "l": lote})
		elif r < pf:
			fuera.append(w)
			var gg: float = w.g
			var nm: String = w.n
			queue("pl" + w.id, func(): await say(T("{n} no contesta al móvil. Se ha largado con {g} de {l}.", {"n": nm, "g": g_txt(gg), "l": lote})))
			continue
		else:
			var q: int = mini(int(floor(w.g)), ri(int(P.g[0]), int(P.g[1])) * int(w.lab))
			w.g -= q
			if r < pt:
				m = T("Me han pagado {g} g con billetes falsos. No me he dado cuenta hasta el banco.", {"g": q})
			else:
				var e := Datos.jsround(precio_calle(w.thc) * calidad(w) * D.ZONAS.town.precio * q * (1 - P.com))
				S.money += e
				S.sales += e
				S.heat = min(100, S.heat + P.calor)
				vende = true
				m = T("Vendidos {g} g: {e} en tu buzón. Me quedan {q}.", {"g": q, "e": Datos.eur(e), "q": g_txt(w.g)}) if w.g >= 1 else T("Vendidos los últimos {g} g: {e} en tu buzón. Dame más cuando quieras.", {"g": q, "e": Datos.eur(e)})
		if w.g < 1:
			libre(w)
		var mm := m
		queue("pl" + w.id, func(): await talk(N, [mm]))
	if fuera.size():
		S.plantilla = S.plantilla.filter(func(w): return not fuera.has(w))
	if vende:   # 1.22: lo vendido cuenta para la historia
		queue("historia", check_story)
	nave_dia()

# la nave: el alquiler, lo primero de la mañana (antes que los sueldos; sin él, Arrieta cambia la cerradura y se queda la fianza).
# Cada RECIBO.dias, en efectivo, con su aviso (cobra, granja.gd)
func nave_alquiler() -> void:
	var N = S.get("nave")
	if N == null or N.get("mia"):   # 1.42: comprada, sin alquiler
		return
	var r0: int = int(N.r)
	if cobra(N, recibo_nave(), K("ARRIETA"), false, K("la nave")):
		if N.get("op") is Dictionary:
			if int(N.r) > r0:   # 1.42: la parte del alquiler que va a la compra
				N.op.pag = int(N.op.pag) + roundi(recibo_nave() * float(D.NAVE.compra.abono))
			if Datos.CAL and int(Datos.fecha(S.day).d) == 1:
				var tx := T("Este mes puedes comprar la nave, hasta el {d}: quedan {r} y {g} de gastos. Por transferencia, en el notario.", {"d": Datos.fd(S.day + int(D.NAVE.compra.ventana) - 1, S.day), "r": Datos.eur(resto_nave()), "g": Datos.eur(gastos_nave())})
				queue("naveC", func(): await talk(K("SMS · ARRIETA"), [tx]))   # i18n-no
		elif Datos.CAL and S.get("aso") is Dictionary and S.aso.get("pres") and int(Datos.fecha(S.day).d) == 1 and not N.get("of"):
			N.of = true
			queue("naveC", func(): await talk(K("SMS · ARRIETA"), [K("Me han dicho que ahora presides la asociación del barrio. Si quieres, la nave te la alquilo con opción a compra: pásate y lo hablamos.")]))   # i18n-no
		return
	for w in de_la_nave():
		libre(w)
	S.nave = null
	queue("nave", func(): await talk(K("SMS · ARRIETA"), [K("No me has pagado la nave. Cambio la cerradura y me quedo la fianza.")]))

# después de la calle, la redada (menos con cuidado) y el ciclo de cada mesa (1.41, lo pidió el usuario: por ciclos, como de verdad).
# Los clones de la madre enraízan, crecen a 18/6 y florecen a 12/12 al ritmo de su variedad (prog_mesa: 1/d al día, como en el piso,
# desde NAVE.clon); al acabar, el navero corta la mesa entera y la cuelga en el secadero (Me.h: {g, t, d}) y vuelve a empezar con
# los esquejes que sacó antes de pasar a flor. Lo de la cosecha: los W de sus focos × g/W (FOCO_NAVE.gpw) × la variedad y el
# fenotipo × el cuidado del navero (nave_g / NAVE.g) × el riego × el calor; el abono, por los días del ciclo que lo tuvo (Me.am,
# Me.ao de Me.dn). Lo colgado se seca NAVE.seca días y pasa a lo que se descuelga (Me.g, con su THC, Me.t, y el día de la cosecha, Me.cd)
func nave_dia() -> void:
	var N = S.get("nave")
	if N == null:
		return
	madres_dia()   # 1.34
	for Me in N.m:
		if Me and Me.get("h") != null and S.day - int(Me.h.d) >= int(D.NAVE.seca):
			if not (Me.g >= 1):   # lo que queda por debajo de 1 g no se recoge: cuenta como vacío
				Me.cd = int(Me.h.d)
			Me.t = Datos.jsround((Me.t * Me.g + Me.h.t * Me.h.g) / (Me.g + Me.h.g) * 10) / 10.0
			Me.g = Datos.jsround((Me.g + Me.h.g) * 10) / 10.0
			Me.erase("h")
	var W := naveros()
	if W.is_empty() or not N.m.any(func(x): return x != null):
		return
	var mc := 0
	for w in W:
		mc = maxi(mc, int(w.cui))
	if Cultivo.azar() < maxf(0, D.NAVE.redada - D.NAVE.redadaC * mc) * D.EXTR_NAVE[int(N.ex)].olor:   # 1.33: con los filtros, huele menos
		var ns: Array = de_la_nave().map(func(w): return w.n)
		var quien: String = T("{a} y {b}", {"a": ", ".join(PackedStringArray(ns.slice(0, -1))), "b": ns[-1]}) if ns.size() > 1 else ns[0]
		var gg: float = nave_stock()
		S.nave = null
		S.plantilla = S.plantilla.filter(func(w): return w.get("rol") != "nave" and w.get("rol") != "madres")
		S.heat = min(100, S.heat + D.NAVE.calor)
		sfx("bad")
		queue("nave", func(): await say(T("La policía ha entrado en la nave de Valdehierro. Se lleva las plantas, {g} y a {q}.", {"g": g_txt(gg), "q": quien}) if gg >= 1 else T("La policía ha entrado en la nave de Valdehierro. Se lleva las plantas y a {q}.", {"q": quien})))
		return
	var R: Dictionary = D.RIEGO_NAVE[int(N.rg)]
	var so := sofoco_nave()
	for i in W.size():
		var Me = N.m[int(W[i].mesa)]
		if not Me:
			continue
		var p := prog_mesa(Me)
		Me.dn = int(Me.get("dn", 0)) + 1
		if Me.abo == 1 and N.ab.m >= R.dosis:
			N.ab.m = Datos.jsround((N.ab.m - R.dosis) * 10) / 10.0
			Me.am = int(Me.get("am", 0)) + 1
		elif Me.abo == 2 and N.ab.o >= R.dosis:
			N.ab.o = Datos.jsround((N.ab.o - R.dosis) * 10) / 10.0
			Me.ao = int(Me.get("ao", 0)) + 1
		var p0 := p
		p += 1.0 / float(strain(lot_sid(Me.k)).d)
		if Datos.CAL and N.has("bc") and p0 < FLOR_MESA and p >= FLOR_MESA:   # 1.43: antes de pasarla a 12/12, la bandeja de clones
			corta_bandeja(int(W[i].mesa), Me)
		if p < 1:
			Me.p = Datos.jsround(p * 1000) / 1000.0
			continue
		var c := cosecha_mesa(Me, int(W[i].mesa), W[i], so)
		if Me.get("h") != null:
			c.t = Datos.jsround((Me.h.t * Me.h.g + c.t * c.g) / (Me.h.g + c.g) * 10) / 10.0
			c.g = Datos.jsround((Me.h.g + c.g) * 10) / 10.0
		Me.h = {"g": c.g, "t": c.t, "d": S.day}
		if N.has("bc"):   # 1.43: la mesa vuelve a empezar con su bandeja (la de antes de la 1.43, con los clones que ya tenía)
			N.bc = N.bc.filter(func(b): return int(b.m) != int(W[i].mesa))
		Me.p = float(D.NAVE.clon)
		Me.n = int(Me.get("n", 0)) + 1
		Me.dn = 0
		Me.am = 0
		Me.ao = 0

# lo que va del ciclo de una mesa (0-1): Me.p o, en una mesa de antes de la 1.41 (por días), lo que llevaría desde que se plantó
func prog_mesa(Me: Dictionary) -> float:
	if Me.get("p") != null:
		return float(Me.p)
	return minf(.95, float(D.NAVE.clon) + float(S.day - Me.dia) / float(strain(lot_sid(Me.k)).d))

# la cosecha entera de la mesa i al final del ciclo: {g, t}
func cosecha_mesa(Me: Dictionary, i: int, w: Dictionary, so: float) -> Dictionary:
	var N: Dictionary = S.nave
	var F: Dictionary = D.FOCO_NAVE[N.f[i]]
	var R: Dictionary = D.RIEGO_NAVE[int(N.rg)]
	var dn := maxf(1, float(Me.get("dn", 1)))
	var am := float(Me.get("am", 0)) / dn
	var ao := float(Me.get("ao", 0)) / dn
	var g: float = float(F.w) * float(F.gpw) * float(strain(lot_sid(Me.k)).y) / float(D.Y_MEDIA) * float(Me.y) * nave_g(w) / float(D.NAVE.g) \
		* (1 + float(R.rend)) * so * (1 + float(D.ABONO.rend) * am + float(D.ABONO_BIO.rend) * ao)
	var thc: float = Me.thc + float(F.thc) + float(R.thc) + float(D.ABONO.thc) * am + float(D.ABONO_BIO.thc) * ao
	return {"g": Datos.jsround(g * 10) / 10.0, "t": Datos.jsround(thc * 10) / 10.0}

# los días que le quedan a la mesa hasta la cosecha
func cosecha_txt(Me: Dictionary) -> String:
	var d := dias_mesa(Me)
	return T("cosecha mañana") if d == 1 else T("cosecha en {d} días", {"d": d})

func dias_mesa(Me: Dictionary) -> int:
	return maxi(1, ceili((1 - prog_mesa(Me)) * float(strain(lot_sid(Me.k)).d) - 1e-9))

# las madres de la nave, cada mañana (1.34, MADRES de 11j-locales): con quien las cuide, a 100 de vigor y con sus esquejes; sin nadie,
# se apagan y, a 0, se mueren
func madres_dia() -> void:
	var N: Dictionary = S.nave
	var c = cuida_madres()
	if N.ma.is_empty():
		return
	var muertas := 0
	var quedan := []
	for M in N.ma:
		if c != null:
			M.v = 100
			M.e = mini(int(D.MADRES.tope), int(M.e) + int(D.MADRES.esq) + (1 if c.cui >= 4 else 0))
			quedan.append(M)
			continue
		M.v = maxi(0, int(M.v) - int(D.MADRES.pierde))
		if M.v > 0:
			quedan.append(M)
		else:
			muertas += 1
	N.ma = quedan
	if muertas:
		var t: String = T("Sin nadie que las cuide, se han muerto {n} madres de la nave.", {"n": muertas}) if muertas > 1 else T("Sin nadie que la cuide, se ha muerto una madre de la nave.")
		queue("madres", func(): await say(t))

# Arrieta, el dueño de la nave de Valdehierro
func talk_nave() -> void:
	var A := K("ARRIETA")
	var N = S.get("nave")
	if S.ch < int(D.NAVE.ch):
		await say(K("La nave no se alquila. Ahora mismo, no."), A)
		return
	if N == null:
		var e: float = D.NAVE.fianza + recibo_nave()   # 1.35: la fianza y la primera semana; después, cada RECIBO.dias, en efectivo
		if await ask(T("La nave está vacía: {f} de fianza y {r} cada {d} días, en efectivo; el primero, ahora. Paso a cobrar y te aviso antes. Sin preguntas.", {"f": Datos.eur(D.NAVE.fianza), "r": Datos.eur(recibo_nave()), "d": n(D.RECIBO.dias)}), [K("Alquilarla"), K("No")], A) != 0:
			return
		if S.money < e:
			sfx("bad")
			await say(T("Sin {e} no hay llave.", {"e": Datos.eur(e)}), A)
			return
		S.money -= e
		S.nave = nave_nueva()
		sfx("coin")
		await got(K("la llave de la nave"))
		await say(T("Dentro hay {n} mesas de cultivo, una por persona. Pon a tu gente desde el móvil y planta tú lo que quieras.", {"n": int(D.NAVE.max)}), A)
		return
	var ops := [K("Dejar la nave"), K("Nada")]
	var tc := ""   # 1.42: la opción a compra (lo pidió el usuario: siendo presidente de la asociación)
	if N.get("mia"):
		ops = [K("Nada")]
		tc = " " + T("La nave es tuya.")
	elif N.get("op") is Dictionary:
		ops.insert(0, K("Comprarla"))
		tc = " " + T("Opción a compra: llevas {a} de {b}.", {"a": Datos.eur(N.op.pag), "b": Datos.eur(N.op.p)})
	elif S.get("aso") is Dictionary and S.aso.get("pres"):
		ops.insert(0, K("Opción a compra"))
	var oi: int = await ask(T("La nave: {a} de {b} mesas plantadas · {c} de {d} trabajando. Lo demás, dentro.", {"a": N.m.filter(func(x): return x != null).size(), "b": int(D.NAVE.max), "c": naveros().size(), "d": int(D.NAVE.max)}) + tc, ops, A)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op == "Opción a compra":
		await opcion_nave()
		return
	if op == "Comprarla":
		await comprar_nave()
		return
	if op == "Dejar la nave":
		var st: bool = nave_stock() >= 1
		var tdj: String
		if N.get("op"):
			tdj = T("¿Dejas la nave? Te devuelvo la fianza; lo que no recojas se queda aquí; la opción a compra se pierde, y lo pagado para ella.") if st else T("¿Dejas la nave? Te devuelvo la fianza; la opción a compra se pierde, y lo pagado para ella.")
		else:
			tdj = T("¿Dejas la nave? Te devuelvo la fianza; lo que no recojas se queda aquí.") if st else T("¿Dejas la nave? Te devuelvo la fianza.")
		if await ask(tdj, [K("Dejarla"), K("No")], A) != 0:
			return
		for w in de_la_nave():
			libre(w)
		S.nave = null
		S.money += int(D.NAVE.fianza)
		sfx("coin")
		await say(K("Trato hecho. Si la quieres otra vez, ya sabes dónde estoy."), A)

# ---------- la nave con opción a compra (1.42, lo pidió el usuario: «cuando seas presidente de la asociación, alquilas con opción
# a compra la nave, por la tranquilidad; cada mes te da la opción de comprarla a tocateja, a un precio realista»). NAVE.compra:
# 320 m² en el polígono de Valdehierro a unos 690 €/m² (precio, fijo mientras dure); la prima de la opción (prima) y la mitad
# de cada alquiler (abono) se descuentan; se compra los primeros días de cada mes (ventana), por transferencia desde la cuenta, con
# los gastos de la compraventa (gastos: transmisiones, notario y registro). Comprada, no hay alquiler ni Arrieta que cambie la cerradura.
func resto_nave() -> int:
	var N = S.get("nave")
	if N == null or not N.get("op") is Dictionary:
		return int(D.NAVE.compra.precio)
	return maxi(0, int(N.op.p) - int(N.op.pag))

func gastos_nave() -> int:
	return roundi(float(D.NAVE.compra.precio) * float(D.NAVE.compra.gastos))

func ventana_nave() -> bool:
	return int(Datos.fecha(S.day).d) <= int(D.NAVE.compra.ventana)

# el primer día de la próxima ventana
func proxima_ventana() -> int:
	var f := Datos.fecha(S.day)
	var y: int = f.y
	var m: int = int(f.m) + 1
	if m > 12:
		m = 1
		y += 1
	return Datos.dia_de(y, m, 1)

func opcion_nave() -> void:
	var A := K("ARRIETA")
	var C: Dictionary = D.NAVE.compra
	var t := T("Te la vendo por {p} ({m} m², a unos {pm} el metro). Firmamos la opción: {pr} de prima, que se descuentan, y la mitad de cada alquiler va a la compra. El precio no se mueve. Los primeros {d} días de cada mes, si quieres, la compras a tocateja con lo que falte, más los gastos ({g}), en el notario y por transferencia.", {"p": Datos.eur(C.precio), "m": int(C.m2), "pm": Datos.eur(roundi(float(C.precio) / float(C.m2))), "pr": Datos.eur(C.prima), "d": int(C.ventana), "g": Datos.eur(gastos_nave())})
	if await ask(t, [K("Firmar la opción"), K("No")], A) != 0:
		return
	if not cobro_banco(float(C.prima), K("Prima de la opción · nave")):
		sfx("bad")
		await say(T("La prima, por transferencia: en tu cuenta no hay {e}.", {"e": Datos.eur(C.prima)}), A)
		return
	S.nave.op = {"d": int(S.day), "pag": int(C.prima), "p": int(C.precio)}
	sfx("coin")
	update_hud()
	await say(T("Firmado. Quedan {e}; la mitad de cada alquiler, a cuenta. El primer día de cada mes te mando un mensaje con lo que falta.", {"e": Datos.eur(resto_nave())}), A)

func comprar_nave() -> void:
	var A := K("ARRIETA")
	if not ventana_nave():
		await say(T("La compra, los primeros {n} días de mes. El próximo, desde el {d}.", {"n": int(D.NAVE.compra.ventana), "d": Datos.fd(proxima_ventana(), S.day)}), A)
		return
	var tot: int = resto_nave() + gastos_nave()
	if await ask(T("Quedan {r} y {g} de gastos: {t}, por transferencia. Te devuelvo la fianza de {f}. ¿La compras?", {"r": Datos.eur(resto_nave()), "g": Datos.eur(gastos_nave()), "t": Datos.eur(tot), "f": Datos.eur(D.NAVE.fianza)}), [K("Comprarla"), K("No")], A) != 0:
		return
	if not cobro_banco(float(tot), K("Compra de la nave de Valdehierro")):
		sfx("bad")
		await say(T("En tu cuenta hay {b} y hacen falta {t}. El mes que viene, otra vez.", {"b": Datos.eur(S.banco), "t": Datos.eur(tot)}), A)
		return
	S.nave.mia = true
	S.nave.op.pag = int(S.nave.op.p)
	S.money += int(D.NAVE.fianza)
	sfx("get")
	update_hud()
	await got(K("las escrituras de la nave"))
	await say(K("Firmado en el notario. La nave es tuya: ni alquiler ni cerradura que cambiar. Suerte."), A)

# ---------- los locales (1.30, 11j-locales): los clubs por dentro, la nave y GAUA ----------
# la puerta de un local (on_step_end, mundo.gd): cerrada, te deja delante; el club, la primera vez, el carné; GAUA, la entrada
func entra_local(d: Dictionary):
	var gk: PackedStringArray = String(d.gate).split(":")
	var t: String = gk[0]
	if t == "club":
		var k: String = gk[1]
		if S.ch < int(D.CLUBS[k].ch):
			atras_puerta()
			await say(K("Una puerta sin rótulo, con un timbre. No abre nadie."))
			return
		if not S.clubs.get(k) and not D.CLUBS[k].get("tuyo"):
			atras_puerta()
			if not await carne_club(k):
				return
		if k == "rv":   # 1.32: la asociación
			await entra_aso(d)
			return
	elif t == "nave":
		if S.get("nave") == null:
			atras_puerta()
			await say(K("La persiana está echada con un candado. La llave la tiene Arrieta, el dueño."))
			return
	elif t == "franco":   # 1.51: el piso franco de Gorka, desde el primer envío
		if not mar_ok() or int(S.mar.paso) < 1:
			atras_puerta()
			await say(K("Un portal con el timbre sin nombre. No abre nadie."))
			return
	elif t == "sot":   # 1.51: la escalera del sótano
		if not sot_ya():
			P.x = int(P.fx)
			P.y = int(P.fy)
			P.px = P.x * 16.0
			P.py = P.y * 16.0
			P.dir = "left"
			S.x = P.x
			S.y = P.y
			S.dir = "left"
			await say(D.SOTANO.txt.cerrado)
			return
	elif t == "setas":   # 1.34: el bajo de Txomin
		if S.get("setas") == null or Datos.PLAY:
			atras_puerta()
			await say(K("Una puerta gris con un candado. No es la tuya.") if Datos.PLAY else K("La puerta del bajo de Txomin, con un candado. La llave te la da él, si lo alquilas."))
			return
	elif t == "neg":   # 1.45: los negocios alquilados
		if not S.loc.has(gk[1]):
			atras_puerta()
			await say(K("Cerrado. En el cristal, el cartel de SE TRASPASA."))
			return
	elif t == "disco":
		if S.ch < int(D.DISCO.ch) or not disco_abierta():
			atras_puerta()
			await say(T("{n} abre de 23:00 a 6:00.", {"n": D.DISCO.n}))
			return
		if not noche_ya():
			atras_puerta()
			if not await entrada_disco():
				return
	match t:   # 1.53: lo tuyo se abre con su llave, su candado o su clave
		"nave":
			await acceso("candado")
			await acceso("clave", cifras_acceso("nave"))
		"setas":
			await acceso("candado")
		"neg", "franco":
			await acceso("llave")
		"club":
			if D.CLUBS[gk[1]].get("tuyo"):
				await acceso("llave")
	await warp(d)

func atras_puerta() -> void:
	var y: int = P.y + 1
	P.fy = y
	P.y = y
	P.py = y * 16.0
	P.dir = "down"
	S.y = y
	S.dir = "down"

# lo que hay dentro de los locales (object_action, mundo.gd); false si no es de un local
func obj_local(x: int, y: int, o) -> bool:
	if o == null:
		return false
	var txt := ""
	if Datos.CAL and S.map == "muelle" and o == "noray":   # 1.51
		await mar_noray(x)
		return true
	if Datos.CAL and S.map == "franco" and o == "crate":
		await alijo_franco()
		return true
	if Datos.CAL and S.map == "muelle" and o in ["redes", "nasas"]:
		await say(K("Redes de la cofradía, remendadas mil veces.") if o == "redes" else K("Nasas para el bogavante, apiladas a secar."))
		return true
	if Datos.CAL and o in ["escaleraD", "escaleraD2"]:   # i18n-no   # 1.47: la escalera al reservado de GAUA
		if not disco_abierta():
			await echar_disco()
		elif noche_gaua().mesa:
			await subir_vip()
		else:
			await say(K("Arriba está el reservado, con la cristalera encima de la pista. Sin mesa, no se sube: la RRPP te la vende."), K("RRPP"))
		return true
	if Datos.CAL and o in ["escaleraDB", "escaleraDB2"]:   # i18n-no
		await bajar_vip()
		return true
	if S.map == "disco-vip":
		match o:
			"bottles":
				txt = K("Las botellas buenas, las del reservado.")
			"barraD":
				txt = K("La barra del reservado. Pídele a la camarera.")
			"neon":
				txt = T("El neón de {n}, también arriba.", {"n": D.DISCO.n})
			"altavoz":
				txt = K("Un altavoz: aquí arriba la música llega más limpia.")
			"sofaV", "sofaV2", "mesaV":   # i18n-no
				txt = K("Tu mesa: sofá de terciopelo, cubitera y botella. Desde aquí se ve toda la pista por el cristal.")
	if S.map == "cuarto-t":   # 1.51: el cuartucho del taller, detrás de su puerta
		if not S.loc.has("valde"):
			await say(K("Ya no es tuyo: devuelve las llaves al salir."))
			return true
		match o:
			"bedT", "bedB":   # i18n-no
				await bed_action(K("La cama del cuartucho: un somier de 90, una manta de cuadros y la radio en la mesilla."))
				return true
			"armR":
				if await ask(D.NEGOCIO.k.valde.txt.armR, [K("Cambiarte de ropa"), K("Nada")]) == 0:
					await vestirte()
				return true
			"mesaC":
				txt = K("Una mesa de camping con un hornillo y una cafetera italiana.")
			"mesita":
				txt = K("La mesilla: la radio, un despertador y una revista de coches.")
			"cuadro":
				txt = K("Un calendario de un taller de neumáticos, de hace años.")
	if S.map == "nave-h" or S.map == "nave-d":   # 1.51: la habitación y el despacho de la nave
		if S.get("nave") == null:
			await say(K("La nave ya no es tuya."))
			return true
		match o:
			"bedT", "bedB":   # i18n-no
				await bed_action(K("La cama de la habitación de la nave: se oyen los extractores al otro lado de la pared."))
				return true
			"armR":
				if await ask(K("Un armario con ropa de faena y una muda limpia."), [K("Cambiarte de ropa"), K("Nada")]) == 0:
					await vestirte()
				return true
			"escritorio", "escritorio2":
				await escritorio_nave()
				return true
			"estanteN":
				await estante_nave()
				return true
			"mesita":
				txt = K("La mesilla, con un flexo y el cargador del móvil.")
			"perchero":
				txt = K("La percha: un mono de trabajo y un chubasquero.")
			"cuadro":
				txt = K("El plano de la nave, con las mesas, las tomas de agua y la luz.")
			"crate":
				txt = K("Cajas de archivo: facturas de la luz, del agua y del sustrato.")
	if S.map.begins_with("loc-") and Datos.CAL:   # 1.45: los negocios por dentro
		var k: String = S.map.substr(4)
		var N: Dictionary = D.NEGOCIO.k[k]
		var ob: String = o.trim_suffix("2") if o.ends_with("2") and o.left(-1) in NEG_ANCHO else o
		if not S.loc.has(k):
			await say(K("Ya no es tuyo: devuelve las llaves al salir."))
			return true
		if ob == "cajaL":
			await neg_caja(k)
		elif ob == "fregona":
			await neg_limpiar(k)
		elif ob == N.go:
			if N.txt.has(ob):
				await say(N.txt[ob])
			await neg_genero(k)
		elif ob in ["bedT", "bedB"]:   # i18n-no
			await bed_action(K("La cama del cuartucho: un somier de 90, una manta de cuadros y la radio en la mesilla."))
		elif ob == "armR":
			if await ask(N.txt.armR, [K("Cambiarte de ropa"), K("Nada")]) == 0:
				await vestirte()
		else:
			await say(N.txt.get(ob, ATREZO_TXT.get(S.map, {}).get(ob, T("Lo de {n}.", {"n": D.LOCALES[k].neg}))))   # 1.57.2: y el atrezo del taller
		return true
	if S.map == "nave" and o in ["bedT", "bedB"]:   # i18n-no   # 1.45: el camastro de la nave
		await bed_action(K("El camastro de la nave, detrás de las mesas: se oyen los extractores toda la noche."))
		return true
	if S.map == "club-rv" and o == "almC":   # 1.45: el almacén del club
		await almacen_club()
		return true
	if S.map == "shop" or S.map == "growcity":   # los dos grows (1.34): lo nuevo de cada uno
		match o:
			"pizarra":
				txt = T("En la pizarra de Kiko, a tiza: «{t}».", {"t": D.PIZARRA_KIKO[int(S.day) % D.PIZARRA_KIKO.size()]})
			"sacos":
				txt = K("Sacos de 50 litros: fibra de coco, perlita y tierra abonada.")
			"macetasP":
				txt = K("Macetas de tela apiladas, de 11, 18 y 25 litros.")
			"botesW":
				txt = K("Botes de abono por litros: MEATZA en azul, ORTUA BIO en verde.")
			"neonG":
				txt = K("Un neón verde: una hoja de siete puntas y GROW IBARBIDE debajo.")
			"semillero":
				txt = K("Un propagador con tapa: bandejas de alveolos con esquejes de muestra y su manta térmica.")
			"carpaDemo", "carpaDemo2":   # i18n-no
				txt = K("La carpa de exposición: 120 × 120, con el LED de barras encendido y plantas de plástico dentro.")
		if txt == "":
			return false
		await say(txt)
		return true
	if S.map.begins_with("club-"):
		var k: String = S.map.substr(5)
		var C: Dictionary = D.CLUBS[k]
		if o == "mesita" and D.ORDEN_P.has(S.map) and aso().pres:   # 1.37 (lo pidió el usuario): de presidente, desde una mesita se ordena el local
			if await ask(D.MUEBLE_CLUB[k].mesa, [K("Ordenar el local"), K("Nada")]) == 0:
				await ordenar(S.map)
			return true
		match o:
			"tarros":
				txt = K("Tarros de cristal con la etiqueta de cada variedad que ha pasado por el club.")
			"pizarra":
				txt = T("En la pizarra, a tiza: «Hoy, {n}».", {"n": strain(C.sid[int(S.day) % C.sid.size()]).n})
			"cartelC":
				txt = T("NORMAS DE {n}\nSolo socios mayores de edad, con el carné a la vista. Lo que se retira, se consume dentro.", {"n": C.n})
			"tacos":
				txt = K("El taquero: seis tacos, la tiza y el triángulo.")
			"vitrina":
				txt = K("La vitrina del dispensario: tarros con muestras y una báscula de precisión.")
			"mesita":   # 1.34: cada club, con los suyos
				txt = D.MUEBLE_CLUB[k].mesa
			"sofaF", "sofaF2", "sofaB", "sofaB2":   # i18n-no
				txt = D.MUEBLE_CLUB[k].sofa
			"billar", "billar2":
				txt = T("La mesa de billar, con el tapete recién cepillado. {n} echa partidas.", {"n": D.BILLAR.n[k]}) if Datos.PLAY else T("La mesa de billar, con el tapete recién cepillado. {n} juega con apuesta.", {"n": D.BILLAR.n[k]})
			"poster":
				txt = K("Un cartel antiguo de una feria del cáñamo.")
			"fotoMaite", "fotoMaite2":   # i18n-no   # 1.32 (1.33: de 2 casillas)
				txt = K("La tía Maite y Delroy, de jóvenes, en un campo. En la placa: «Maite, presidenta fundadora».") if aso().tio else K("La tía Maite, joven, con un hombre de rastas negras, en un campo. En la placa: «Maite, presidenta fundadora».")
			"plantDeco":
				txt = K("Una kentia en una maceta de barro.")
		if txt == "" and D.DECO_CLUB.has(o):   # 1.34: lo que cuelga de sus paredes
			txt = D.DECO_CLUB[o]
	if S.map == "nave":
		if S.get("nave") == null:
			await say(K("La nave está vacía."))
			return true
		match o:
			"mesaN", "mesaN2":   # i18n-no
				await mesa_nave(mesa_idx(x, y))   # 1.37: donde esté (12d-orden)
				return true
			"estanteN":
				await estante_nave()
				return true
			"secadero":
				await secadero_nave()
				return true
			"escritorio", "escritorio2":
				await escritorio_nave()
				return true
			"carpaM", "carpaM2":   # 1.34 · i18n-no
				await carpa_madres()
				return true
			"clonN", "clonN2":   # 1.43 · i18n-no
				await bandejas_nave()
				return true
			"tanqueN", "riegoN", "ctrlN":   # 1.52.1: el riego, que también se mueve desde aquí · i18n-no
				if puertas_int("nave").size():
					if await ask(T("El riego de la nave: {n}.", {"n": D.RIEGO_NAVE[int(S.nave.rg)].n}), [K("Ordenar la nave"), K("Nada")]) == 0:
						await ordenar("nave")
					return true
			"crate":
				txt = K("Sacos de sustrato y macetas apiladas.")
	if S.map == "setas" or S.map == "sotano":   # 1.34: el bajo de las setas por dentro (1.51: y el sótano de casa)
		if SL() == null:
			await say(K("El sótano está a medio hacer: mañana acaban los obreros.") if S.map == "sotano" else K("El bajo ya no es tuyo. Txomin cambiará la cerradura."))
			return true
		match o:
			"baldaS":
				if Datos.CAL:   # 1.43.9: las baldas a la vista, con las setas creciendo
					await vista_bajo(2 * balda_i(x))
				else:
					await bajo_menu("")
				return true
			"humidS":
				if SL().bandejas.any(func(b): return not b.get("mala")):
					await pulverizar_bajo()
				else:
					await say(K("El pulverizador de mochila de Txomin. Con él se tienen húmedas las bandejas."))
				return true
			"secaS", "deshidS":   # i18n-no
				if Datos.CAL:   # 1.44: lo que se seca, y cuándo pasa al armario
					txt = txt_secando(o)
				else:
					txt = T("En el secadero, {g} de setas secas. Txomin te las compra en la puerta.", {"g": g_txt(SL().g)}) if SL().g >= 1 else K("El secadero está vacío. Lo que recojas se seca aquí.")
			"armS":   # 1.44: el armario de almacén, por dentro
				await vista_armario()
				return true
			"mesaS":   # 1.44: la mesa de trabajo
				await mesa_setas()
				return true
			"tuboS":
				txt = K("Una tubería vieja que suda. Por eso aquí la humedad nunca baja.")
			"crate":
				txt = K("Cajas de bandejas vacías de Txomin, apiladas.")
			"cuboS":
				txt = K("Un cubo y un cepillo. Lo que se echa a perder, fuera.")
	if S.map == "conce":   # 1.43
		var C: Dictionary = D.CONCE
		for k in C.orden:
			if o == C.v[k].o or o == C.v[k].o + "2":
				await ficha_expo(k)
				return true
		match o:
			"rotuloK", "rotuloK2":   # i18n-no
				txt = K("AUTOS RIBERA. Debajo, más pequeño: «Concesionario · Taller · Financiación».")
			"preciosK":
				txt = T("Precios con IVA. Aparte, la matriculación (el impuesto, según las emisiones) y {e} de gestoría y placas.", {"e": Datos.eur(C.gastos)})
			"catalogoK":
				txt = K("Catálogos con las fichas técnicas: potencia, consumo, emisiones y la etiqueta medioambiental.")
			"cafeK":
				txt = K("Una cafetera de cápsulas y vasitos para los clientes. Huele a café y a coche nuevo.")
			"ruedasK":
				txt = K("Neumáticos de invierno, apilados. Con el coche se monta un juego en el taller.")
			"mesaK", "mesaK2":   # i18n-no
				txt = K("La mesa de Arantxa, con el ordenador y los contratos. Habla con ella.")
			"plantDeco":
				txt = K("Una planta de plástico con polvo.")
	if S.map == "disco":
		match o:
			"bottles":
				txt = K("Botellas de ginebra, ron y vodka, iluminadas desde abajo.")
			"neon":
				txt = T("El neón de {n}: la luna rosa.", {"n": D.DISCO.n})
			"altavoz":
				txt = K("El altavoz retumba en el pecho.")
			"cabina", "cabina2":
				txt = K("La cabina del DJ: dos platos y la mesa de mezclas.")
			"sofaV", "sofaV2", "mesaV":   # i18n-no
				txt = K("El reservado: sofá de terciopelo y una cubitera en la mesa.")
			"cordon", "cordonF":
				txt = K("El cordón del reservado. Lo abre la RRPP.")
	if txt == "":
		return false
	await say(txt)
	return true

# Donde lleva el club una mujer (GENERO.enc), «la encargada»
func con_encargada(t: String, k: String) -> String:
	return t.replace("El encargado", "La encargada") if Datos.CAL and D.GENERO.enc.has(k) else t

# Los demás socios de cada club (GENTE_CLUB)
func talk_gente_club(k: String, j: int):
	var e = ents.filter(func(x): return x.id == "cg%d" % (j + 1))
	await say(con_encargada(D.GENTE_CLUB[(int(S.day) + j + D.CLUBS.keys().find(k)) % D.GENTE_CLUB.size()], k), K("SOCIA") if Datos.CAL and e.size() and mujer_look(e[0].look) else K("SOCIO"))

# el sprite de lo que cambia en los locales (1.34, spriteLocal de 11j-locales): el secadero del bajo, con setas o vacío, y la carpa de
# las madres, con las que tenga; los demás, con estilo, el de su club (estiloLocal)
func sprite_local(o: String) -> String:
	if o == "secaS":
		if Datos.CAL:   # 1.44: con setas tendidas mientras se secan en la malla (sin deshidratador)
			return "secaS-%d" % (1 if SL() != null and not SL().get("dh") and SL().get("fr", []).size() else 0)   # i18n-no
		return "secaS-%d" % (1 if SL() != null and SL().g >= 1 else 0)   # i18n-no
	if o == "deshidS":
		return "deshidS-%d" % (1 if SL() != null and SL().get("fr", []).size() else 0)   # i18n-no
	if o == "armS":
		return "armS-%d-%d-%d" % [lleno_arm("g"), lleno_arm("mc"), lleno_arm("cc")]   # i18n-no
	if o == "mesaS":
		return "mesaS-%d-%d" % [1 if S.get("setas") != null and S.setas.get("enc") else 0, 1 if S.get("setas") != null and S.setas.get("mol") else 0]   # i18n-no
	if o == "carpaM":
		return "carpaM-%d" % (S.nave.ma.size() if S.get("nave") != null and S.nave.has("ma") else 0)   # i18n-no
	if o == "clonN":   # 1.43: el carro de bandejas de la nave, por lo lleno
		var nb: int = S.nave.bc.size() if S.get("nave") != null and S.nave.has("bc") else 0
		return "clonN-%d" % (0 if nb == 0 else 1 if nb <= 2 else 2)   # i18n-no
	if o == "rotuloL":   # 1.35 (granja.gd)
		return sprite_rotulo()
	var e = MAPS[S.map].get("est") if MAPS.has(S.map) else null
	return (o + "-" + e) if e and D.ESTILO_OBJ.has(o) else o

# las bandejas de la balda x del bajo (1.34, bandejasBalda): las dos que le tocan (2x abajo, 2x + 1 arriba), en su fase
func bandejas_balda(x: int) -> Array:
	var r := []
	if SL() == null:
		return r
	var B: Array = SL().bandejas
	var bi := balda_i(x)
	for j in 2:
		if 2 * bi + j < B.size():
			r.append("bandejaS-%s-%d" % [fase_seta(B[2 * bi + j]), j])   # i18n-no
	return r

# ---------- el club: el socio y el billar ----------
func talk_socio(k: String):
	var nn: String = D.SOCIO.n[k]
	var N := nn.to_upper()
	var c: int = await ask(pick([K("¿Qué tal? Siéntate, hay sitio."), K("Aquí se está tranquilo, ¿eh?")]), [K("Charlar"), K("Compartir uno"), K("Nada")], N)
	if c == 0:
		await say(con_encargada(pick(D.SOCIO.charla), k), N)
		return
	if c != 1:
		return
	if S.porro.get(k) == S.day:
		await say(K("Hoy ya hemos compartido. Mañana, más."), N)
		return
	var lots := bud_lots(D.SOCIO.g)
	if lots.is_empty():
		await say(T("Cuando tengas algo encima, lo compartimos. Con {g} vale.", {"g": g_txt(D.SOCIO.g)}), N)
		return
	var it: Array = lots.map(func(l): return lot_item(l))
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Qué compartes?")})
	if i < 0 or i >= lots.size():
		return
	var kk: String = lots[i][0]
	var thc: float = lots[i][1].thc
	use_buds(kk, D.SOCIO.g)
	S.porro[k] = S.day
	confia(k, int(D.SOCIO.rel))
	advance_time(int(D.SOCIO.min))
	update_hud()
	sfx("sel")
	await say(T("Compartes {l} en el sofá. {n}: «Esto es otra liga. Se lo cuento a los del club.»", {"l": lot_nombre(kk), "n": nn}) if thc >= 20 else T("Compartes {l} en el sofá. {n}: «Suave, de los de charlar. Gracias.»", {"l": lot_nombre(kk), "n": nn}))

func fuerza_tiro(ms: float, per := -1.0) -> float:
	if per < 0:
		per = float(D.BILLAR.periodo)
	var f: float = fmod(ms, per) / per
	return f * 2 if f < .5 else 2 - f * 2

func resultado_tiro(d: float, f: float, a: float) -> String:
	if f >= float(D.BILLAR.falta):
		return "falta"
	return "dentro" if absf(d - D.BILLAR.centro) <= a and absf(f - D.BILLAR.centro) <= D.BILLAR.verde else "falla"

# un tiro: el texto y, con A, dónde estaba la barra (de 0 a 1; 1.31: arranca en un punto al azar, para que no baste con contar); las
# pruebas lo cambian (gancho_billar, ui.gd)
# 1.36, los minijuegos de las máquinas (o: mov y ritmo): con mov, el verde va y viene en mov ms (la static) y sale lo que se separa
# del verde, como si estuviera quieto en el centro; con ritmo, la barra acelera y frena (la lavadora: el tiempo, deformado)
func centro_tiro(T: Dictionary, now: float) -> float:
	var mv := float(T.get("mov", 0))
	return .5 + .32 * sin((now - T.t0) / mv * 2 * PI) if mv else float(D.BILLAR.centro)

func pos_tiro(T: Dictionary, now: float) -> float:
	var ms: float = now - T.t0
	var per := float(T.get("per", -1.0))
	if per < 0:
		per = float(D.BILLAR.periodo)
	var q := per * 1.6
	var rt := float(T.get("ritmo", 0))
	return fuerza_tiro(ms + rt * q / (2 * PI) * sin(ms / q * 2 * PI) if rt else ms, per)

func tiro_billar(txt: String, fase := "fuerza", a := 0.0, per := -1.0, nom := K("BILLAR"), o := {}) -> float:   # 1.35: per y nom, las extracciones
	if gancho_billar.is_valid():
		return float(gancho_billar.call(txt))
	if per < 0:
		per = float(D.BILLAR.periodo)
	await type_text(txt, nom)
	var pr := Motor.Prom.new()
	TIRO = {"t0": M.reloj - Cultivo.azar() * per, "f": fase, "a": a, "per": per, "mov": float(o.get("mov", 0)), "ritmo": float(o.get("ritmo", 0))}
	if o.has("esc"):   # 1.38: la escena de la extracción encima de la barra (escena_extr.gd)
		TIRO.esc = o.esc
		TIRO.paso = o.paso
		TIRO.n = o.n
	push(func(b: String):
		if b == "A":
			pop()
			pr.res(pos_tiro(TIRO, M.reloj) - centro_tiro(TIRO, M.reloj) + float(D.BILLAR.centro)))
	var p: float = await Motor.espera(pr)
	TIRO = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	sfx("hit")
	return p

# las extracciones (1.35, 11l-extraccion): una tanda de barras; la calidad q es la parte que entra, y sale rend × (0,6 + 0,4 q)
# del peso con thc × (0,9 + 0,1 q) veces el THC, hasta tope
func sale_extr(E: Dictionary, g: float, q: float) -> float:
	return maxf(.1, Datos.jsround(g * E.rend * (.6 + .4 * q) * 10) / 10.0)

func extraer(t: String):
	var E: Dictionary = D.EXTR[t]
	if t == "seco" and S.items.get("mallas00"):   # 1.36: con las mallas 00, el dry sift «doble cero»
		E = E.duplicate(true)
		E.merge(D.SECO00, true)
		E.pasos = D.EXTR.seco.pasos + [D.SECO00.paso]
	var kief: bool = E.de == "kief"
	var N: String = E.n.to_upper()
	var lots: Array = kief_lots(1) if kief else bud_lots(5)
	if lots.is_empty():
		await say(T("{n}: necesitas 1 g de kief, del tamiz o del Ice-o-lator, como mínimo.", {"n": N}) if kief else T("{n}: necesitas 5 g de cogollos como mínimo.", {"n": N}))
		return
	var oil = null
	var kf = null
	if t == "moon":
		oil = mayor_lote(rosin_lots(D.MOON.oil).filter(func(l): return tipo_extr(l[0]) == "rosin"))
		kf = mayor_lote(kief_lots(D.MOON.kief))
		if oil == null or kf == null:
			await say(K("MOONROCK: necesitas rosin para bañar el cogollo y kief para rebozarlo."))
			return
	var it := lots.map(rosin_item if kief else lot_item)
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": T("{n}: ¿de qué?", {"n": E.n})})
	if i < 0 or i >= lots.size():
		return
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var tope := int(floor(b.g))
	if oil != null:
		tope = mini(tope, mini(int(floor(oil[1].g / D.MOON.oil + 1e-9)), int(floor(kf[1].g / D.MOON.kief + 1e-9))))
	if tope < 1:
		await say(K("MOONROCK: no te llega el rosin o el kief para un gramo."))
		return
	var base: Array = [1, 5, 25] if kief else ([1, 3, 10] if oil != null else [5, 25, 100])
	var ops: Array = base.filter(func(g): return g < tope)
	ops.append(tope)
	var tx := ops.map(func(g): return T("{g} g → {r} g de {e}", {"g": g, "r": Datos.coma(sale_extr(E, g, 1)), "e": E.n.to_lower()}))
	tx.append(K("Nada"))
	var j: int = await ask(T("{l}: {g} g. ¿Cuánto usas?", {"l": (E.n + " · " + lot_nombre(k)) if kief else lot_nombre(k), "g": tope}), tx)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	await say(E.d, N)
	var ok := 0
	for ip in E.pasos.size():
		var p: Array = E.pasos[ip]
		var d: float = await tiro_billar(p[0], "dir", p[1], E.per, N, E.merged({"esc": t, "paso": ip, "n": E.pasos.size()}, true))
		if absf(d - float(D.BILLAR.centro)) <= p[1]:
			ok += 1
	var q: float = float(ok) / E.pasos.size()
	var r := sale_extr(E, g, q)
	var thc: float = b.thc
	if oil != null:
		var o: float = Datos.jsround(g * D.MOON.oil * 10) / 10.0
		var m: float = Datos.jsround(g * D.MOON.kief * 10) / 10.0
		thc = (b.thc * g + oil[1].thc * o + kf[1].thc * m) / (g + o + m)
		use_rosin(oil[0], o)
		use_rosin(kf[0], m)
	thc = minf(E.tope, thc * E.thc * (.9 + .1 * q))
	if kief:
		use_rosin(k, g)
	else:
		use_buds(k, g)
	add_rosin(k if t == "rosin" else base_extr(k) + "~" + E.get("sale", t), r, thc)
	advance_time(E.min)
	sfx("get")
	var ar := {"e": E.n, "l": lot_nombre(base_extr(k)), "r": Datos.coma(r), "t": Datos.pct(thc)}
	await say(T("Te sale perfecto. {e} de {l}: {r} g con un {t} % de THC.", ar) if q >= 1 else T("Te sale bien, con algo de pérdida. {e} de {l}: {r} g con un {t} % de THC.", ar) if q >= .5 else T("Te sale regular: pierdes bastante. {e} de {l}: {r} g con un {t} % de THC.", ar))

func una_bola(m: int) -> String:
	return "una" if m == 1 else str(m)

func talk_billar(k: String):
	var B: Dictionary = D.BILLAR
	var nb: String = B.n[k]
	var N := nb.to_upper()
	var Db = S.billar.get(k)
	if not (Db is Dictionary and Db.d == S.day):
		Db = {"d": S.day, "n": 0}
		S.billar[k] = Db
	if Db.n >= B.dia:
		await say(K("Por hoy ya está bien. Mañana te doy la revancha."), N)
		return
	var ops: Array = [K("Una partida")] if Datos.PLAY else B.apuestas.map(func(e): return T("A {e}", {"e": Datos.eur(e)}))   # Google Play: sin apuestas
	ops.append(K("Nada"))
	var c: int = await ask(T("¿Una a la bola 8? {n} lisas para ti, {n} rayadas para mí y la negra al final: quien la meta, gana.", {"n": int(B.bolas)}) if Datos.PLAY else T("¿Una a la bola 8? {n} lisas para ti, {n} rayadas para mí y la negra al final: quien la meta se lleva la apuesta.", {"n": int(B.bolas)}), ops, N)
	if c < 0 or c >= ops.size() - 1:
		return
	var e: int = 0 if Datos.PLAY else int(B.apuestas[c])
	if S.money < e:
		sfx("bad")
		await say(K("Sin dinero encima no se juega."), N)
		return
	Db.n += 1
	var V := {"yo": int(B.bolas), "el": int(B.bolas), "negra": 1}
	MESA_B = V
	var yo := true
	var mano := false
	var seguro := false
	var deja := 1.0
	var fin := ""
	await say(K("Sacas tú. Las tuyas, las lisas."))
	var t := 0
	while t < int(B.turnos) and fin == "":
		t += 1
		if yo:
			var extra := (" " + I18n.T("Bola en mano: la colocas donde quieras.")) if mano else ((" " + I18n.T("La blanca ha quedado bien.")) if deja > 1 else "")
			var ta := {"y": V.yo, "nb": nb, "el": V.el}
			var tt: String
			if V.yo:
				tt = I18n.T("Tu turno · te quedan {y}; a {nb}, {el}.", ta) if V.el else I18n.T("Tu turno · te quedan {y}; a {nb}, la negra.", ta)
			else:
				tt = I18n.T("Tu turno · te queda la negra; a {nb}, {el}.", ta) if V.el else I18n.T("Tu turno · te queda la negra; a {nb}, la negra.", ta)
			var i: int = await ask(tt + extra, D.TIROS.map(func(x): return x.n))
			var T: Dictionary = D.TIROS[0 if i < 0 else i]
			if T.get("seguro"):
				seguro = true
				deja = 1.0
				mano = false
				yo = false
				await say(I18n.K("Escondes la blanca detrás de sus bolas. Le toca, y no lo tiene fácil."))
				continue
			var a: float = Datos.jsround(float(T.a) * deja * (float(B.manoX) if mano else 1.0) * 1000) / 1000.0
			deja = 1.0
			mano = false
			var d1 := await tiro_billar(I18n.T("{t}: para la barra en el verde para apuntar.", {"t": T.n}), "dir", a)
			var f1 := await tiro_billar(I18n.T("Ahora la fuerza: en el verde, dentro; pasada, se cuela la blanca."), "fuerza")
			var r := resultado_tiro(d1, f1, a)
			if r == "falta":
				if not V.yo:
					fin = "el"
					await say(I18n.K("La negra entra... y la blanca detrás. Falta sobre la negra: pierdes."))
					break
				mano = true
				yo = false
				await say(I18n.T("Demasiado fuerte: la blanca se cuela. Falta: {nb} juega con bola en mano.", {"nb": nb}))
				continue
			if r == "dentro":
				if not V.yo:
					V.negra = 0
					fin = "yo"
					await say(I18n.K("¡La negra, dentro!"))
					break
				V.yo -= 1
				deja = float(T.get("deja", 1))
				await say((I18n.T("¡Dentro! Te quedan {n}. Sigues tú.", {"n": V.yo}) if V.yo > 1 else I18n.T("¡Dentro! Te queda {n}. Sigues tú.", {"n": V.yo})) if V.yo else I18n.K("¡Dentro! Ya solo te queda la negra. Sigues tú."))
				continue
			yo = false
			await say(I18n.T("No entra. Le toca a {nb}.", {"nb": nb}))
			continue
		var p: float = float(B.hab[k]) + (float(B.mano) if mano else 0.0)
		var m := 0
		var falta := false
		if seguro:
			p *= float(B.seguro)
		mano = false
		seguro = false
		while true:
			var rr := Cultivo.azar()
			if rr < p:
				if not V.el:
					V.negra = 0
					fin = "el"
					break
				V.el -= 1
				m += 1
				p = float(B.hab[k])
				continue
			if rr > float(B.faltaR):
				falta = true
			break
		if fin != "":
			await say((I18n.T("{nb} mete una y tira a la negra: dentro.", {"nb": nb}) if m == 1 else I18n.T("{nb} mete {m} y tira a la negra: dentro.", {"nb": nb, "m": m})) if m else I18n.T("{nb} tira a la negra: dentro.", {"nb": nb}))
			break
		if falta and not V.el:
			fin = "yo"
			await say(I18n.T("{nb} tira a la negra y se le cuela la blanca. Falta sobre la negra: pierde.", {"nb": nb}))
			break
		if falta:
			mano = true
		yo = true
		var tx: String
		var tm := {"nb": nb, "m": m}
		if m == 1:
			tx = I18n.T("{nb} mete una y se le cuela la blanca: bola en mano para ti.", tm) if falta else I18n.T("{nb} mete una y falla.", tm)
		elif m:
			tx = I18n.T("{nb} mete {m} y se le cuela la blanca: bola en mano para ti.", tm) if falta else I18n.T("{nb} mete {m} y falla.", tm)
		else:
			tx = I18n.T("{nb} cuela la blanca: bola en mano para ti.", tm) if falta else I18n.T("{nb} falla.", tm)
		await say(tx)
	MESA_B = null
	if fin == "yo":
		S.money += e
		confia(k, 1)
		sfx("coin")
	elif fin == "el":
		S.money -= e
		sfx("bad")
	advance_time(int(B.min))
	update_hud()
	if Datos.PLAY:
		await say(I18n.T("Ganas tú. {nb}: «La próxima, la revancha».", {"nb": nb}) if fin == "yo" else I18n.T("Gana {nb}.", {"nb": nb}) if fin == "el" else I18n.K("Se hace tarde y lo dejáis en tablas."))
	elif fin == "yo":
		await say(I18n.T("Ganas tú. {nb} te paga {e}: «La próxima, la revancha».", {"nb": nb, "e": Datos.eur(e)}))
	elif fin == "el":
		await say(I18n.T("Gana {nb}. Le pagas {e}.", {"nb": nb, "e": Datos.eur(e)}))
	else:
		await say(I18n.K("Se hace tarde y lo dejáis en tablas. Nadie paga."))

# la mesa del billar mientras dura la partida (rectsMesaBillar de 11j-locales): [x, y, w, h, color] en la pantalla
func rects_mesa_billar(V: Dictionary) -> Array:
	var x0: int = (SW - 100) >> 1
	var y0 := 4
	var o := [[x0 - 1, y0 - 1, 102, 54, "#26262e"], [x0, y0, 100, 52, "#74502e"], [x0, y0, 100, 1, "#a46e40"], [x0 + 4, y0 + 4, 92, 44, "#2f7a46"]]
	for q in [[2, 2], [48, 2], [94, 2], [2, 46], [48, 46], [94, 46]]:
		o.append([x0 + q[0], y0 + q[1], 4, 4, "#121519"])
	var MB: Dictionary = D.MESA_BOLAS
	var bola := func(q, c: String, b: String) -> void:
		var x: int = int(q[0]) + x0 + 4
		var y: int = int(q[1]) + y0 + 4
		o.append([x + 1, y, 2, 4, c])
		o.append([x, y + 1, 4, 2, c])
		if b != "":
			o.append([x, y + 1, 4, 2, b])
	bola.call(MB.blanca, "#f8f8f0", "")
	for i in mini(int(V.yo), MB.yo.size()):
		bola.call(MB.yo[i], "#e0b84a", "")
	for i in mini(int(V.el), MB.el.size()):
		bola.call(MB.el[i], "#f8f8f0", "#e04040")
	if V.negra:
		bola.call(MB.negra, "#26262e", "")
	return o
