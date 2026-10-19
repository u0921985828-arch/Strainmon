# MAESTRO [9] (con Datos.CAL): el final de partida. Los pisos de venta (PISOS9, S.pisos): desde el primer envío por mar, uno por
# pueblo, alquilado o comprado, con un lugarteniente de tu plantilla que vende cada mañana lo que le dejas en su almacén, a la pureza
# y al precio que le marcas. Y la ciudad (METRO, S.metro): Hiriburu se abre al llegar al patrimonio neto de METRO.umbral y se va
# por la autopista con tu vehículo; dentro, los clubs VIP (compra, mejoras y lo que dejan cada noche en la cuenta), el concejal que
# cobra por mirar a otro lado (el riesgo de que te cierren un club) y los cuatro barrios que se disputan dos bandas. Todo por
# Datos.hash_str, sin tocar el azar del oráculo.
# Cadena: … → gestion → vida → metro → retencion → juego.
extends "res://src/vida.gd"

var rival_fac := ""   # la banda contra la que peleas (rival_b)

func _hm(s: String) -> int:
	return Datos.hash_str(s)

func _pm(s: String, p: float) -> bool:   # true con probabilidad p, por hash
	return _hm(s) % 10000 < int(p * 10000)

# ---------- los pisos de venta ----------
func pisos_ok() -> bool:
	return Datos.CAL and D.has("PISOS9") and S != null and S.get("mar") is Dictionary and int(S.mar.get("paso", 0)) >= 1

func pisos_d() -> Dictionary:
	if not (S.get("pisos") is Dictionary):
		S.pisos = {}
	return S.pisos

func piso_n(k: String) -> String:
	return String(D.PARADAS[k].n) if D.PARADAS.has(k) else String(D.METRO.parada.n)

func pisos_lista() -> Array:   # los pueblos con piso posible (la ciudad, si está abierta)
	var o := []
	for k in D.PISOS9.k:
		if k == "metropoli" and not metro_ya():
			continue
		if k != "metropoli" and k != "town" and S.ch < int(D.PARADAS[k].cap):
			continue
		o.append(k)
	return o

func stock_piso(F: Dictionary) -> float:
	var t := 0.0
	for k in F.buds:
		t += float(F.buds[k].g)
	return t

func lt_de(k: String):   # el lugarteniente del piso k, o null
	for w in S.plantilla:
		if w.get("rol") == "lugar" and w.get("pv") == k:
			return w
	return null

func aqui_pueblo() -> String:
	return "metropoli" if S.map.begins_with("metropoli") or S.map.begins_with("vip-") else Croquis.pueblo_de(S.map)

func pisos() -> void:
	var i := 0
	while true:
		var L := pisos_lista()
		var P := pisos_d()
		var rows := []
		for k in L:
			var F = P.get(k)
			var r: String = K("sin piso")
			if F is Dictionary:
				var w = lt_de(k)
				r = T("{s} · {e}", {"s": _kg(int(stock_piso(F))), "e": Datos.eur(F.caja)}) if w else T("sin lugarteniente · {s}", {"s": _kg(int(stock_piso(F)))})
			rows.append({"label": piso_n(k), "right": r, "desc": desc_piso(k)})
		rows.append({"label": K("Salir"), "desc": K("Un piso por pueblo: tu lugarteniente vende cada mañana lo que dejes en su almacén.")})
		i = await menu(rows, {"cls": "full", "title": K("PISOS"), "title2": T("{n} de {t}", {"n": P.size(), "t": L.size()}), "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0 or i >= L.size():
			return
		await piso_menu(L[i])

func desc_piso(k: String) -> String:
	var R: Dictionary = D.PISOS9.k[k]
	var F = pisos_d().get(k)
	if not F is Dictionary:
		return T("Alquiler: {a} al mes. Comprarlo: {p}.", {"a": Datos.eur(R.alq), "p": Datos.eur(R.p)})
	var w = lt_de(k)
	var q := {"l": w.n if w else K("nadie"), "p": K(D.PISOS9.pur[int(F.pur)][0]), "x": K(D.PISOS9.px[int(F.px)][0]), "v": _kg(int(F.get("v", 0))), "c": int(F.cal)}
	return T("Lugarteniente: {l} · {p}, {x} · ayer {v} · calor {c}.", q)

func piso_menu(k: String) -> void:
	var R: Dictionary = D.PISOS9.k[k]
	var P := pisos_d()
	var nm := piso_n(k)
	if not P.get(k) is Dictionary:
		var j: int = await ask(T("Un piso discreto en {n}: {a} al mes o {p} en propiedad.", {"n": nm, "a": Datos.eur(R.alq), "p": Datos.eur(R.p)}), [K("Alquilarlo"), K("Comprarlo"), K("Nada")])
		if j == 0:
			if S.money < float(R.alq):
				sfx("bad")
				await say(K("El primer mes va en efectivo, por delante. No te llega."))
				return
			S.money -= float(R.alq)
			P[k] = {"r": S.day + int(D.PISOS9.per), "mia": false, "buds": {}, "caja": 0, "pur": 0, "px": 1, "cal": 0.0, "v": 0}
		elif j == 1:
			if not cobro_banco(float(R.p), T("Compra · piso de {n}", {"n": nm})):
				sfx("bad")
				await say(T("Para comprarlo hacen falta {p} en la cuenta.", {"p": Datos.eur(R.p)}))
				return
			P[k] = {"r": 0, "mia": true, "buds": {}, "caja": 0, "pur": 0, "px": 1, "cal": 0.0, "v": 0}
		else:
			return
		sfx("get")
		update_hud()
		await say(T("El piso de {n} es tuyo. Pon a alguien de tu plantilla al frente y déjale género.", {"n": nm}))
		return
	while true:
		var F: Dictionary = P[k]
		var aqui := aqui_pueblo() == k
		var ops := [K("Cómo va"), K("Lugarteniente"), K("Pureza"), K("Precio")]
		if aqui:
			ops.append_array([K("Dejar género"), T("Recoger la caja ({e})", {"e": Datos.eur(F.caja)})])
		ops.append_array([K("Dejar el piso"), K("Nada")])
		var i: int = await ask(T("El piso de {n}. {d}", {"n": nm, "d": desc_piso(k)}) + ("" if aqui else " " + K("El género y la caja, en persona.")), ops)
		var l: String = ops[i] if i >= 0 else K("Nada")
		if l == "Nada":
			return
		if l == "Cómo va":
			var cq := {"v": _kg(int(F.get("v", 0))), "s": _kg(int(stock_piso(F))), "c": int(F.cal), "d": Datos.fd(int(F.r), S.day)}
			await say((T("Ayer salieron {v}; quedan {s}. Calor {c}. Tuyo, sin alquiler.", cq) if F.get("mia") else T("Ayer salieron {v}; quedan {s}. Calor {c}. El alquiler, el {d}.", cq)))
		elif l == "Lugarteniente":
			await elegir_lt(k)
		elif l == "Pureza":
			var o := []
			for q in D.PISOS9.pur:
				o.append(K(q[0]))
			var j: int = await ask(K("¿Cómo lo vende? Rebajado rinde más gramos, pero se nota y da más calor."), o)
			if j >= 0:
				F.pur = j
		elif l == "Precio":
			var o := []
			for q in D.PISOS9.px:
				o.append(K(q[0]))
			var j: int = await ask(K("¿A qué precio? Barato vende más; caro, menos."), o)
			if j >= 0:
				F.px = j
		elif l == "Dejar género":
			await dejar_piso(k)
		elif aqui and i == 5:   # recoger la caja (la fila lleva la cifra)
			if int(F.caja) < 1:
				await say(K("La caja está vacía."))
			else:
				S.money += int(F.caja)
				sfx("get")
				await say(T("Te llevas {e}.", {"e": Datos.eur(F.caja)}))
				F.caja = 0
				update_hud()
		elif l == "Dejar el piso":
			if not aqui and (stock_piso(F) >= 1 or int(F.caja) > 0):
				await say(K("Para vaciarlo tienes que estar en el pueblo."))
				continue
			if await confirm(K("¿Dejas el piso? Lo que haya en el almacén y en la caja te lo llevas tú.")):
				for b in F.buds.keys():
					mover_lote(F.buds, S.buds, b, F.buds[b].g)
				S.money += int(F.caja)
				var w = lt_de(k)
				if w:
					libre(w)
				P.erase(k)
				update_hud()
				return

func elegir_lt(k: String) -> void:
	var cs := []
	for w in S.plantilla:
		if w.get("rol") == null or (w.get("rol") == "lugar" and w.get("pv") == k):
			cs.append(w)
	if cs.is_empty():
		await say(K("No tienes a nadie libre en la plantilla. Pídele gente a Patxi desde el móvil."))
		return
	var it := cs.map(func(w): return {"label": w.n, "right": T("labia {l} · lealtad {e}", {"l": int(w.lab), "e": lealtad_lt(w)}), "desc": ficha_gente(w)})
	it.append({"label": K("Nadie")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Quién lleva el piso?"), "desc": true})
	var w0 = lt_de(k)
	if i < 0:
		return
	if w0:
		libre(w0)
	if i >= cs.size():
		return
	var w: Dictionary = cs[i]
	if w.get("rol") != null:
		libre(w)
	w.rol = "lugar"
	w.pv = k
	sfx("sel")
	await say(T("{n} lleva el piso de {p}.", {"n": w.n, "p": piso_n(k)}))

func lealtad_lt(w: Dictionary) -> int:   # de 1 a 10 (la de 1 a 5 de antes, ×2)
	return int(w.get("lt", int(w.get("lea", 3)) * 2))

func dejar_piso(k: String) -> void:
	var F: Dictionary = pisos_d()[k]
	var cap: float = float(D.PISOS9.cap)
	while true:
		var lots := bud_lots(1)
		var it := lots.map(venta_item)
		it.append({"label": K("Nada")})
		var i: int = await menu(it, {"cls": "right", "title": T("Al almacén · {a} de {b}", {"a": _kg(int(stock_piso(F))), "b": _kg(int(cap))})})
		if i < 0 or i >= lots.size():
			return
		var l: Array = lots[i]
		var mx: int = mini(int(floor(l[1].g)), int(cap - stock_piso(F)))
		if mx < 1:
			await say(K("El almacén está lleno."))
			return
		var g = await cuanto(T("¿Cuánto de {n} dejas?", {"n": lot_nombre(l[0])}), mx, [50, 100, 250, 500, 1000, 2000], func(v): return _kg(int(v)))
		if g > 0:
			mover_lote(S.buds, F.buds, l[0], g)
			sfx("get")
			update_hud()

# cada mañana (desde curro_dia): el alquiler, lo que vende el lugarteniente, su comisión y su sisa, el calor y la redada
func pisos_dia() -> void:
	if not pisos_ok():
		return
	var R: Dictionary = D.PISOS9
	var P := pisos_d()
	for k in P.keys():
		var F: Dictionary = P[k]
		var nm := piso_n(k)
		if not F.get("mia") and not cobra(F, float(R.k[k].alq), K("CASERO"), false, T("el piso de {n}", {"n": nm}), int(R.per)):
			var w0 = lt_de(k)
			if w0:
				libre(w0)
			P.erase(k)
			queue("piso" + k, func(): await talk(K("SMS · CASERO"), [T("Sin alquiler no hay piso en {n}. Lo que había dentro cubre lo que debes.", {"n": nm})]))
			continue
		var w = lt_de(k)
		F.v = 0
		if w == null or stock_piso(F) < 1:
			F.cal = maxf(0.0, float(F.cal) - float(R.cal.baja))
			continue
		var pur: float = float(R.pur[int(F.pur)][1])
		var pxx: float = float(R.px[int(F.px)][1])
		var dem: float = float(R.px[int(F.px)][2])
		var cap: int = int(round((float(R.dia) + float(R.lab) * int(w.get("lab", 1))) * dem))   # gramos vendidos al día
		var zp: float = float(D.ZONAS[k].precio) if D.ZONAS.has(k) else 1.0
		var ks: Array = F.buds.keys()
		ks.sort_custom(func(a, b): return float(F.buds[a].thc) > float(F.buds[b].thc))
		var vend := 0
		var e := 0
		for b in ks:
			if vend >= cap:
				break
			var L: Dictionary = F.buds[b]
			var sale: int = mini(cap - vend, int(floor(float(L.g) / pur)))   # rebajado: con menos gramos del almacén salen los mismos
			if sale < 1:
				continue
			var gasta: float = minf(float(L.g), sale * pur)
			e += Datos.jsround(precio_calle(L.thc) * calidad(L, true) * zp * pxx * sqrt(pur) * sale)
			L.g = float(L.g) - gasta
			vend += sale
			if float(L.g) < .5:
				F.buds.erase(b)
		var neto: int = Datos.jsround(e * (1 - float(R.com)))
		var lt := lealtad_lt(w)
		if lt < 5 and _pm("sisa|%s|%d" % [k, S.day], .5):   # poco leal: a veces se queda un pellizco
			neto = Datos.jsround(neto * (1 - float(R.sisa) * (5 - lt)))
		F.caja = int(F.caja) + neto
		F.v = vend
		S.sales += neto
		F.cal = clampf(float(F.cal) + vend * float(R.cal.g) + (1 - pur) * float(R.cal.pur) - float(R.cal.baja), 0.0, 100.0)
		if F.cal >= float(R.cal.redada):
			var perdido: float = stock_piso(F)
			var caja: int = int(F.caja)
			F.buds = {}
			F.caja = 0
			F.cal = float(R.cal.vuelve)
			S.heat = mini(100, int(S.heat) + int(R.cal.heat))
			S.plantilla.erase(w)
			var nn: String = w.n
			queue("piso" + k, func(): await talk(K("SMS · ") + nn.to_upper(), [T("Han entrado en el piso de {n}. Me llevan detenido. Se han quedado {kg} y {e} de la caja.", {"n": nm, "kg": _kg(int(perdido)), "e": Datos.eur(caja)})]))

# ---------- la ciudad: el patrimonio, la autopista y lo de dentro ----------
func metro_ok() -> bool:
	return Datos.CAL and D.has("METRO") and S != null

func metro_ya() -> bool:
	return metro_ok() and S.get("metro") is Dictionary

func patrimonio() -> float:
	var t: float = float(S.money) + float(S.get("banco", 0))
	if S.get("caja") is Dictionary:
		t += float(S.caja.get("money", 0))
	if S.get("desp") is Dictionary:
		t += float(S.desp.get("money", 0))
	if S.get("franco") is Dictionary:
		t += float(S.franco.get("caja", 0))
	for k in pisos_d():
		t += float(pisos_d()[k].caja)
	return t - maxf(0.0, float(S.get("debt", 0)))

func metro_d() -> Dictionary:
	var M_: Dictionary = S.metro
	if not M_.has("ter"):
		var ter := {}
		for b in D.METRO.barrios:
			ter[b] = {"c": 0, "f": String(D.METRO.barrios[b].f)}
		M_.ter = ter
	for q in ["vip", "at"]:
		if not M_.has(q):
			M_[q] = {}
	if not M_.has("sob"):
		M_.sob = 0
	return M_

func barrio_de(x: int, y: int) -> String:
	for b in D.METRO.barrios:
		var r: Array = D.METRO.barrios[b].r
		if x >= int(r[0]) and y >= int(r[1]) and x < int(r[2]) and y < int(r[3]):
			return b
	return ""

func control(b: String) -> int:
	return int(metro_d().ter[b].c) if metro_ya() else 0

# cada mañana (desde curro_dia): se abre la ciudad, lo que dejan los clubs VIP, las clausuras y las bandas
func metro_dia() -> void:
	if not metro_ok():
		return
	var MT: Dictionary = D.METRO
	if not S.get("metro") is Dictionary:
		if patrimonio() >= float(MT.umbral):
			S.metro = {"d": S.day}
			metro_d()
			var tx := [T("Tu nombre ya suena en Hiriburu. Con un patrimonio así, la ciudad se abre: la autopista sale de la parada, con tu vehículo ({p} de peaje).", {"p": Datos.eur(MT.peaje)}), K("Allí hay clubs para gente con dinero, un concejal que sabe mirar a otro lado y dos bandas que no te esperan con flores.")]
			queue("metro", func(): await talk(K("SMS · IÑAKI"), tx))
		return
	var M_ := metro_d()
	var C: Dictionary = MT.clausura
	for k in M_.vip.keys():
		var V: Dictionary = M_.vip[k]
		var R: Dictionary = MT.vip[k]
		if int(V.get("cl", 0)) > S.day:
			continue
		var p: float = float(C.p) + float(S.heat) / 100.0 * float(C.calor)
		if int(M_.sob) >= S.day:
			p *= float(C.sob)
		if int(V.get("mj", 0)) >= 2:
			p *= float(C.seg)
		if _pm("clausura|%s|%d" % [k, S.day], p):
			V.cl = S.day + int(C.dias)
			var f := pagar_recibo(float(C.multa), T("Multa · {n}", {"n": R.n}))
			var tx: String = T("Inspección en {n}: precintado {d} días y {e} de multa.", {"n": R.n, "d": int(C.dias), "e": Datos.eur(C.multa)})
			if f > 0:
				tx += " " + T("Te quedan a deber {f}.", {"f": Datos.eur(f)})
			queue("vip" + k, func(): await talk(K("SMS · AYUNTAMIENTO DE HIRIBURU"), [tx]))
			continue
		var e := vip_noche(k)
		V.ay = e
		V.tot = int(V.get("tot", 0)) + e
		abono_banco(e, R.n)
		S.sales += e
	# las bandas empujan donde tienes algo
	var T_: Dictionary = MT.ter
	for b in M_.ter:
		var t: Dictionary = M_.ter[b]
		if int(t.c) <= 0 or int(t.c) >= int(T_.suyo):
			continue
		if _pm("empuje|%s|%d" % [b, S.day], float(T_.p)):
			var q: int = int(T_.empuje[0]) + _hm("empujeq|%s|%d" % [b, S.day]) % (int(T_.empuje[1]) - int(T_.empuje[0]) + 1)
			t.c = maxi(0, int(t.c) - q)
			M_.at[b] = S.day
			var F: Dictionary = MT.fac[t.f]
			var tx: String = T("{f} se mueven en {b}: has perdido {q} puntos de control. {j} te espera allí.", {"f": F.n, "b": MT.barrios[b].n, "q": q, "j": may1(String(F.jefe).to_lower())})
			queue("ter" + b, func(): await talk(K("SMS · ") + K("UN CHAVAL DEL BARRIO"), [tx]))

func vip_noche(k: String) -> int:   # lo que deja una noche: lo suyo, sus mejoras y el control del barrio
	var R: Dictionary = D.METRO.vip[k]
	var V: Dictionary = metro_d().vip[k]
	var x: float = 1.0 + (float(D.METRO.mej[0].x) if int(V.get("mj", 0)) >= 1 else 0.0)
	return Datos.jsround(float(R.dia) * x * (0.4 + 0.6 * control(R.barrio) / 100.0))

# la gente de la ciudad (build_ents): los encargados de los clubs, el concejal, los jefes de las bandas y los clientes de dentro
func metro_npcs(mapa: String) -> Array:
	if not metro_ya():
		return []
	var MT: Dictionary = D.METRO
	var o := []
	if mapa == "metropoli":
		var Cj: Dictionary = MT.concejal
		o.append({"id": "m9_concejal", "map": mapa, "x": int(Cj.x), "y": int(Cj.y), "look": Cj.look, "dir": "down", "wander": 0})
		for f in MT.fac:
			var F: Dictionary = MT.fac[f]
			o.append({"id": "m9_fac_" + f, "map": mapa, "x": int(F.x), "y": int(F.y), "look": F.look, "dir": "down", "wander": 0})
	for k in MT.vip:
		if mapa == MT.vip[k].map:
			o.append({"id": "m9_vip_" + k, "map": mapa, "x": 9, "y": 2, "look": MT.vip[k].look, "dir": "down", "wander": 0})
	for n in MT.npc:
		if n.map == mapa:
			var d: Dictionary = n.duplicate()
			d.wander = 0
			o.append(d)
	return o

func talk_metro(id: String) -> void:
	var MT: Dictionary = D.METRO
	if id == "m9_concejal":
		await talk_concejal()
	elif id.begins_with("m9_fac_"):
		await talk_fac(id.substr(7))
	elif id.begins_with("m9_vip_"):
		await talk_vip9(id.substr(7))
	else:
		await say(pick([K("«Aquí se viene a que te vean.»"), K("«¿Tú eres el dueño? Buena música.»"), K("«La próxima la pago yo.»")]))

# la puerta de un club VIP (entra_local): comprarlo o entrar con tu llave
func vip_puerta(k: String) -> bool:
	if not metro_ya():
		atras_puerta()
		await say(K("Cerrado. Una cámara te mira desde lo alto."))
		return false
	var R: Dictionary = D.METRO.vip[k]
	var M_ := metro_d()
	if M_.vip.has(k):
		if int(M_.vip[k].get("cl", 0)) > S.day:
			atras_puerta()
			await say(T("Precinto del Ayuntamiento en la puerta: cerrado hasta el {d}.", {"d": Datos.fd(int(M_.vip[k].cl), S.day)}))
			return false
		await acceso("llave")
		return true
	atras_puerta()
	if await ask(T("{n}: SE TRASPASA. Local de copas con licencia hasta las 6, {p}. ¿Lo compras?", {"n": R.n, "p": Datos.eur(R.p)}), [K("Comprarlo"), K("Nada")]) != 0:
		return false
	if not cobro_banco(float(R.p), T("Compra · {n}", {"n": R.n})):
		sfx("bad")
		await say(T("Hacen falta {p} en la cuenta.", {"p": Datos.eur(R.p)}))
		return false
	M_.vip[k] = {"d": S.day, "mj": 0, "tot": 0, "ay": 0}
	sfx("get")
	update_hud()
	await say(T("{n} es tuyo. {e} lo lleva por ti: lo que deje cada noche, a tu cuenta.", {"n": R.n, "e": may1(String(R.enc).to_lower())}))
	return false

func talk_vip9(k: String) -> void:
	var MT: Dictionary = D.METRO
	var R: Dictionary = MT.vip[k]
	var N: String = R.enc
	var M_ := metro_d()
	if not M_.vip.has(k):
		await say(K("«Esto ya no es tuyo. Fuera.»"), N)
		return
	var V: Dictionary = M_.vip[k]
	while true:
		var b: String = R.barrio
		var ops := [K("Cómo va")]
		var mj: int = int(V.get("mj", 0))
		if mj < MT.mej.size():
			ops.append("%s · %s" % [I18n.v(String(MT.mej[mj].n)), Datos.eur(MT.mej[mj].p)])
		ops.append(K("Nada"))
		var i: int = await ask(T("Anoche, {e}. En {b} mandas un {c} %.", {"e": Datos.eur(V.get("ay", 0)), "b": MT.barrios[b].n, "c": control(b)}), ops, N)
		if i < 0 or i == ops.size() - 1:
			return
		if i == 0:
			var q := {"t": Datos.eur(V.get("tot", 0)), "s": K("Con el concejal, tranquilos.") if int(M_.sob) >= S.day else K("Sin el concejal, cualquier inspección nos cierra.")}
			await say(T("Desde que es tuyo, {t}. {s}", q), N)
			continue
		var M2: Dictionary = MT.mej[mj]
		if not await confirm("%s: %s. %s" % [I18n.v(String(M2.n)), Datos.eur(M2.p), I18n.v(String(M2.d))]):
			continue
		if not cobro_banco(float(M2.p), "%s · %s" % [I18n.v(String(R.n)), I18n.v(String(M2.n))]):
			sfx("bad")
			await say(T("Hacen falta {p} en la cuenta.", {"p": Datos.eur(M2.p)}), N)
			continue
		V.mj = mj + 1
		sfx("get")
		await say(T("Hecho. {d}", {"d": M2.d}), N)

func talk_concejal() -> void:
	var Cj: Dictionary = D.METRO.concejal
	var N: String = Cj.n
	var M_ := metro_d()
	if int(M_.sob) >= S.day:
		await say(T("«Usted y yo no nos conocemos. Hasta el {d}, ninguna inspección pasa por sus locales.»", {"d": Datos.fd(int(M_.sob), S.day)}), N)
		return
	var j: int = await ask(T("«Las licencias de ocio nocturno pasan por mi mesa. Por {e} al mes, las inspecciones se pierden por el camino.»", {"e": Datos.eur(Cj.sobre)}), [T("Darle el sobre ({e})", {"e": Datos.eur(Cj.sobre)}), K("Nada")], N)
	if j != 0:
		return
	if S.money < float(Cj.sobre):
		sfx("bad")
		await say(K("«Eso va en efectivo. Vuelva cuando lo traiga.»"), N)
		return
	S.money -= float(Cj.sobre)
	M_.sob = S.day + int(Cj.per)
	S.heat = maxi(0, int(S.heat) - 5)
	sfx("coin")
	update_hud()
	await say(T("Se guarda el sobre sin mirarlo. «Hasta el {d}, sin sustos.»", {"d": Datos.fd(int(M_.sob), S.day)}), N)

func talk_fac(f: String) -> void:
	var MT: Dictionary = D.METRO
	var F: Dictionary = MT.fac[f]
	var Tr: Dictionary = MT.ter
	var N: String = F.jefe
	var M_ := metro_d()
	var bs := []
	for b in M_.ter:
		if M_.ter[b].f == f and int(M_.ter[b].c) < int(Tr.suyo):
			bs.append(b)
	if bs.is_empty():
		await say(K("«Ya no tengo nada que hablar contigo. La ciudad es tuya… por ahora.»"), N)
		return
	var ops := []
	for b in bs:
		ops.append(T("Plantarles cara en {b} ({c} %)", {"b": MT.barrios[b].n, "c": int(M_.ter[b].c)}))
	ops.append(T("Pactar ({e})", {"e": Datos.eur(Tr.pacto_e)}))
	ops.append(K("Nada"))
	var i: int = await ask(T("«{f} mandan aquí. ¿Qué quieres?»", {"f": F.n}), ops, N)
	if i < 0 or i == ops.size() - 1:
		return
	if i == ops.size() - 2:
		if S.money < float(Tr.pacto_e):
			sfx("bad")
			await say(K("«Sin el dinero delante, no hay pacto.»"), N)
			return
		S.money -= float(Tr.pacto_e)
		var b0: String = bs[0]
		for b in bs:
			if int(M_.ter[b].c) < int(M_.ter[b0].c):
				b0 = b
		sube_control(b0, int(Tr.pacto))
		sfx("coin")
		update_hud()
		await say(T("«Trato.» En {b} te dejan sitio: {c} % de control.", {"b": MT.barrios[b0].n, "c": control(b0)}), N)
		return
	await pelea_barrio(bs[i], f)

# pelear por un barrio: ganas, +ter.pelea; pierdes, −ter.pierde; HABLAR, nada
func pelea_barrio(b: String, f: String) -> void:
	var MT: Dictionary = D.METRO
	var Tr: Dictionary = MT.ter
	rival_fac = f
	var r = await battle("rival")
	rival_fac = ""
	var M_ := metro_d()
	M_.at.erase(b)
	if r == "win":
		sube_control(b, int(Tr.pelea))
		sfx("get")
		await say(T("{f} se retiran de media {b}: {c} % de control.", {"f": MT.fac[f].n, "b": MT.barrios[b].n, "c": control(b)}) + (" " + T("{b} es tuyo.", {"b": MT.barrios[b].n}) if control(b) >= int(Tr.suyo) else ""))
	elif r == "talk":
		await say(K("Os separáis sin más. Nadie gana nada."))
	else:
		M_.ter[b].c = maxi(0, int(M_.ter[b].c) - int(Tr.pierde))
		await say(T("Te sacan de {b} a empujones: {c} % de control.", {"b": MT.barrios[b].n, "c": control(b)}))

func sube_control(b: String, q: int) -> void:
	var t: Dictionary = metro_d().ter[b]
	t.c = mini(int(D.METRO.ter.suyo), int(t.c) + q)

func rival_b(kind := "rival") -> Dictionary:
	if rival_fac != "" and kind == "rival":
		var F: Dictionary = D.METRO.fac[rival_fac]
		var o := Datos.rand_look("fac" + rival_fac, "thief")
		o.id = F.look
		return {"kind": "thief", "rival": F.n, "name": F.jefe, "look": o, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	return super.rival_b(kind)

# al llegar a la ciudad: si una banda se ha movido donde tienes algo, te espera (eventos de control territorial)
func metro_llegada() -> void:
	if not metro_ya() or S.map != "metropoli":
		return
	var M_ := metro_d()
	for b in M_.at.keys():
		var f: String = M_.ter[b].f
		var F: Dictionary = D.METRO.fac[f]
		var Tr: Dictionary = D.METRO.ter
		var pago: int = int(Tr.pacto_e) / 2
		var j: int = await ask(T("{j} y los suyos te cortan el paso: «{b} no es tuya.»", {"j": may1(String(F.jefe).to_lower()), "b": D.METRO.barrios[b].n}), [K("Plantarles cara"), T("Pagarles ({e})", {"e": Datos.eur(pago)}), K("Irte")], F.jefe)
		if j == 0:
			await pelea_barrio(b, f)
		elif j == 1 and S.money >= pago:
			S.money -= pago
			M_.at.erase(b)
			sfx("coin")
			update_hud()
			await say(K("Se guardan el dinero y se apartan. Por esta vez."))
		else:
			M_.at.erase(b)
			M_.ter[b].c = maxi(0, int(M_.ter[b].c) - int(Tr.pierde))
			await say(T("Te apartas. En {b} te queda un {c} %.", {"b": D.METRO.barrios[b].n, "c": control(b)}))

# lo de dentro de los clubs VIP (obj_local): mirar
func obj_vip(o) -> bool:
	if not (o is String) or not S.map.begins_with("vip-"):
		return false
	var t: Dictionary = D.METRO.txt
	var k := String(o).trim_suffix("2")
	await say(String(t[k]) if t.has(k) else K("Todo de diseño, todo carísimo."))
	return true

# la parada de la ciudad: no llega el autobús de la comarca; con tu vehículo, la autopista, y sin él (si te lo ha llevado la grúa),
# el de línea a Ibarbide (METRO.bus, más el peaje)
func parada_action():
	if S.map != "metropoli":
		return await super.parada_action()
	var mios: Array = coches_mios().filter(func(k): return donde(k) == "metropoli")
	var ops := []
	for k in mios:
		ops.append(T("En {v}", {"v": String(D.CONCE.v[k].art)}))
	for k in mios:
		ops.append(T("Maletero {dv}", {"dv": de_art(String(D.CONCE.v[k].art))}))
	var e: int = int(D.METRO.bus) + int(D.METRO.peaje)
	ops.append(T("Autobús de línea a Ibarbide ({e})", {"e": Datos.eur(e)}))
	ops.append(K("Nada"))
	var c: int = await ask(T("PARADA DE {p}\n¿Cómo vas?", {"p": I18n.v(String(D.METRO.parada.n)).to_upper()}), ops)
	if c < 0 or c >= ops.size() - 1:
		return
	if c < mios.size():
		await conducir(mios[c])
		return
	if c < 2 * mios.size():
		await maletero(mios[c - mios.size()])
		return
	if S.money < e:
		sfx("bad")
		await say(T("El billete cuesta {e}. No te llega.", {"e": Datos.eur(e)}))
		return
	S.money -= e
	sfx("door")
	await fade(1)
	var mins: int = int(D.METRO.parada.min) + int(D.PARADAS.ibarbide.min)
	await anim_viaje("bus", "metropoli", "ibarbide", mins)
	advance_time(mins)
	var a: Array = D.PARADAS.ibarbide.a
	enter_map("ibarbide", int(a[0]), int(a[1]), a[2])
	if S.clientsDay != S.day:
		spawn_clients()
	update_hud()
	await wait(80)
	await fade(0)
