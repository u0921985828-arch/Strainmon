# F8 (de trama.gd): el calendario y el mapa, las bandejas de clones, el concesionario, el muelle, las obras, abrir con llave y los gestos.
extends "res://src/setas.gd"

# los días señalados: el plazo de Don Baltasar, los recibos, los encargos y la asamblea
func marcas_cal() -> Array:
	var r := []
	if S.get("due", 0) > 0 and S.get("deadline"):
		r.append({"d": int(S.deadline), "c": "#d03028", "t": T("plazo de Don Baltasar ({e})", {"e": Datos.eur(S.due)})})
	for o in recibos():
		r.append({"d": int(o[1]), "c": "#3060c0", "t": T("recibo de {n}", {"n": o[0]})})
	if S.get("encargo") is Dictionary and S.encargo.get("hasta"):
		r.append({"d": int(S.encargo.hasta), "c": "#308040", "t": T("encargo de Toño")})
	if S.get("clubEnc") is Dictionary and S.clubEnc.get("hasta"):
		r.append({"d": int(S.clubEnc.hasta), "c": "#308040", "t": T("encargo del club")})
	if S.get("nave") != null and S.nave.get("op") is Dictionary and not S.nave.get("mia"):
		r.append({"d": int(S.day) if ventana_nave() else proxima_ventana(), "c": "#d08020", "t": T("se puede comprar la nave")})
	if S.get("aso") is Dictionary and int(S.aso.get("asam", 0)):
		r.append({"d": int(S.aso.asam), "c": "#a050b0", "t": T("asamblea de la asociación")})
	r.append_array(cup_marcas())   # MAESTRO [5]
	r.sort_custom(func(a, b): return a.d < b.d)
	return r

func elegir_cal() -> void:
	var f := Datos.fecha(int(S.day))
	CAL_V = {"y": int(f.y), "m": int(f.m)}
	var mk := marcas_cal()
	_dlg_fijo(Croquis.desc_cal(CAL_V, int(S.day), mk), T("CALENDARIO"))
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "B":
			pop()
			pr.res(null)
			return
		if Croquis.mueve_cal(CAL_V, b):
			sfx("sel")
			_dlg_fijo(Croquis.desc_cal(CAL_V, int(S.day), mk), T("CALENDARIO")))
	await Motor.espera(pr)
	CAL_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()

func elegir_mapa() -> void:
	var aqui := Croquis.pueblo_de(S.map)
	if not Croquis.PUEBLOS.has(aqui):   # MAESTRO [9]: desde la ciudad, la comarca con la chincheta en Ibarbide
		aqui = "ibarbide"
	MAPA_V = {"i": Croquis.ORDEN.find(aqui)}
	_dlg_fijo(Croquis.desc_mapa(D, int(S.ch), MAPA_V, aqui), "")   # 1.43: sin pestaña, que no pise el croquis
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "B":
			pop()
			pr.res(null)
			return
		if Croquis.mueve_mapa(MAPA_V, b):
			sfx("sel")
			_dlg_fijo(Croquis.desc_mapa(D, int(S.ch), MAPA_V, aqui), ""))   # 1.43: sin pestaña, que no pise el croquis
	await Motor.espera(pr)
	MAPA_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()

func corta_bandeja(i: int, Me: Dictionary) -> void:
	var N: Dictionary = S.nave
	if N.bc.size() >= BANDEJAS_NAVE or N.bc.any(func(b): return int(b.m) == i):
		return
	N.bc.append({"m": i, "k": Me.k, "f": Me.get("f"), "d": int(S.day)})

func bandeja_lista(b: Dictionary) -> bool:
	return int(S.day) - int(b.d) >= int(D.NAVE.raiz)

func bandejas_listas() -> Array:
	if S.get("nave") == null or not S.nave.has("bc"):
		return []
	return S.nave.bc.filter(func(b): return bandeja_lista(b))

func bandejas_nave() -> void:
	var N: Dictionary = S.nave
	if not N.has("bc") or N.bc.is_empty():
		await say(T("El carro de las bandejas de clones: dos baldas con sus tubos T5 y sus tapas. Vacío. Antes de pasar cada mesa a 12/12, quien la cuida le corta {n} esquejes y aquí echan raíces en un día; con ellos, la mesa vuelve a empezar.", {"n": int(D.NAVE.tacos)}) if int(D.NAVE.raiz) == 1 else T("El carro de las bandejas de clones: dos baldas con sus tubos T5 y sus tapas. Vacío. Antes de pasar cada mesa a 12/12, quien la cuida le corta {n} esquejes y aquí echan raíces en {d} días; con ellos, la mesa vuelve a empezar.", {"n": int(D.NAVE.tacos), "d": int(D.NAVE.raiz)}))
		return
	var rows := []
	for b in N.bc:
		var k := lot_sid(b.k)
		var s = strain(k)
		var faltan: int = int(D.NAVE.raiz) - (int(S.day) - int(b.d))
		rows.append({"label": T("Mesa {m} · {n}", {"m": int(b.m) + 1, "n": s.n}), "right": K("enraizada") if faltan <= 0 else ("%d d" % faltan), "sw": s.c, "ic": ic_cog(k),
			"desc": T("{n} esquejes de {v}{f}, cortados el {d}, en tacos de turba con su tapa. {r}", {"n": int(D.NAVE.tacos), "v": s.n, "f": etiq(b.get("f")), "d": Datos.fd(int(b.d), S.day),
				"r": T("Ya tienen raíces: la mesa {m} vuelve a empezar con ellos al cosecharse.", {"m": int(b.m) + 1}) if faltan <= 0 else (T("Les faltan un día para echar raíces.") if faltan == 1 else T("Les faltan {d} días para echar raíces.", {"d": faltan}))})})
	rows.append({"label": K("Volver"), "desc": ""})
	await menu(rows, {"cls": "full", "title": K("BANDEJAS DE CLONES"), "title2": T("{a} de {b}", {"a": N.bc.size(), "b": BANDEJAS_NAVE}), "desc": true})

# ---------- el concesionario (1.43, lo pidió el usuario) ----------
# AUTOS RIBERA abre en el barrio alto (montar_alto) con el capítulo CONCE.ch y CONCE.patri entre efectivo y cuenta. Precios con IVA;
# aparte, el impuesto de matriculación (IEDMT: por los g de CO2/km, sobre el precio sin IVA) y los gastos de gestoría y placas. En
# efectivo, como mucho CONCE.efe (Ley 11/2021); el resto, por transferencia. El seguro, domiciliado cada mes (recibos). La entrega,
# a los días de matricularlo; el deportivo, bajo pedido. Se revende con la depreciación (CONCE.dep). Con un vehículo vas de parada en
# parada a cualquier hora (conducir): con su gasolina y, a veces, un control de tráfico; la moto, además, por la calle (vehiculo)
func coches_mios() -> Array:
	var r := []
	for k in D.CONCE.orden:
		if coche_ya(k) and not S.coches[k].get("grua"):
			r.append(k)
	return r

func iedmt(k: String) -> int:
	var V: Dictionary = D.CONCE.v[k]
	if V.get("exenta"):
		return 0
	for t in D.CONCE.iedmt:
		if float(V.co2) <= float(t[0]):
			return roundi(float(V.p) / 1.21 * float(t[1]))
	return 0

func total_coche(k: String) -> int:
	return int(D.CONCE.v[k].p) + iedmt(k) + int(D.CONCE.gastos)

func seguro_anio(k) -> int:   # 1.43.2: la póliza, al año
	return int(D.CONCE.v[k].seg)

# lo que te paga el concesionario por el tuyo: el precio, menos lo que pierde al salir (dep.ya) y cada mes (dep.mes), hasta dep.min
func valor_coche(k: String) -> int:
	var c: Dictionary = S.coches[k]
	var dp: Dictionary = D.CONCE.dep
	var meses: int = maxi(0, int(S.day) - int(c.dia)) / int(D.CONCE.mes)
	return roundi(float(D.CONCE.v[k].p) * maxf(float(dp.min), 1.0 - float(dp.ya) - float(dp.mes) * meses))

func ficha_coche(k: String) -> String:
	var V: Dictionary = D.CONCE.v[k]
	var ie := iedmt(k)
	return T("{d}\n{l} l/100 km · {co2} g CO2/km. Total {tot} (matriculación {ie}, gastos {g}). Entrega en {ent} días.\nAl año: seguro {seg} e impuesto de circulación {iv}. Revisión cada {rk} km ({r}) y neumáticos cada {nk} km ({ne}). Sin billete de autobús: solo la gasolina.", {"d": V.d, "l": Datos.coma(V.l), "co2": int(V.co2),
		"tot": Datos.eur(total_coche(k)), "ie": Datos.eur(ie) if ie else K("exenta"), "g": Datos.eur(D.CONCE.gastos), "ent": int(V.entrega),
		"seg": Datos.eur(V.seg), "iv": Datos.eur(V.ivtm), "rk": Datos.miles(V.revKm), "r": Datos.eur(V.rev), "nk": Datos.miles(V.neuKm), "ne": Datos.eur(V.neu)})

func _art_m(k: String) -> String:   # «la moto» → «a»; «el utilitario» → «o»
	return "a" if String(D.CONCE.v[k].art).begins_with("la ") else "o"

func ficha_expo(k: String) -> void:
	var V: Dictionary = D.CONCE.v[k]
	if S.get("coches") is Dictionary and S.coches.has(k):
		await say(T("{A}, como {a} tuya.", {"A": mayus(V.art), "a": V.art}) if _art_m(k) == "a" else T("{A}, como {a} tuyo.", {"A": mayus(V.art), "a": V.art}))
		return
	if await ask("%s · %s.\n%s" % [V.n, Datos.eur(V.p), V.d], [K("Hablar con Arantxa"), K("Nada")]) == 0:
		await comprar_coche(k)

func talk_conce():
	var C: Dictionary = D.CONCE
	var i := 0
	while true:
		var it := []
		var tuyos := []
		var sin := []
		for k in C.orden:
			var V: Dictionary = C.v[k]
			var c = S.coches.get(k) if S.get("coches") is Dictionary else null
			if c != null and coche_ya(k):
				tuyos.append(k)
				if c.get("r") == null:
					sin.append(k)
			var lb: String = V.n
			if c != null and coche_ya(k):
				lb = T("{n} · tuya", {"n": V.n}) if _art_m(k) == "a" else T("{n} · tuyo", {"n": V.n})
			elif c != null:
				lb = T("{n} · pedida", {"n": V.n}) if _art_m(k) == "a" else T("{n} · pedido", {"n": V.n})
			it.append({"label": lb, "right": Datos.eur(V.p), "desc": ficha_coche(k)})
		it.append({"label": K("Vender"), "disabled": tuyos.is_empty(), "desc": T("Te lo recompran: pierde un {ya} % al salir del concesionario y un {mes} % cada mes, hasta el {min} % de lo que valía.", {"ya": roundi(C.dep.ya * 100), "mes": Datos.coma(C.dep.mes * 100), "min": roundi(C.dep.min * 100)})})
		it.append({"label": K("Asegurar"), "disabled": sin.is_empty(), "desc": T("Sin seguro no se puede circular: la multa es de {e} y el vehículo, a la grúa.", {"e": Datos.eur(C.sinSeguro)})})
		it.append({"label": K("Nada"), "desc": T("Precios con IVA. Aparte, la matriculación por emisiones y {g} de gestoría y placas.", {"g": Datos.eur(C.gastos)})})
		i = await menu(it, {"cls": "full", "title": C.n, "title2": T("Cuenta {b} · efectivo {e}", {"b": Datos.eur(S.banco), "e": Datos.eur(S.money)}), "desc": true, "initial": i})
		var no: int = C.orden.size()
		if i < 0 or i >= no + 2:
			if S.get("coches") is Dictionary and not S.coches.is_empty():
				await say(K("Cualquier cosa, aquí estamos. Y ojo con la ITV."), K("ARANTXA"))
			return
		if i < no:
			await comprar_coche(C.orden[i])
		elif i == no:
			await vender_coche(tuyos)
		else:
			await asegurar_coche(sin)

func comprar_coche(k: String) -> void:
	var A := K("ARANTXA")
	var C: Dictionary = D.CONCE
	var V: Dictionary = C.v[k]
	if S.get("coches") is Dictionary and S.coches.has(k):
		await say((T("{A} ya es tuya.", {"A": mayus(V.art)}) if _art_m(k) == "a" else T("{A} ya es tuyo.", {"A": mayus(V.art)})) if coche_ya(k) else T("{A} está en camino: te aviso por SMS.", {"A": mayus(V.art)}), A)
		return
	var tot := total_coche(k)
	var sm := seguro_anio(k)
	var efe: int = mini(mini(int(S.money), int(C.efe)), tot)
	var tr: int = tot - efe
	if await ask(T("{n}: {tot} en total. {efe} en efectivo, que más no deja la ley, y {tr} por transferencia; el seguro, {sm} al año, domiciliado. ¿Lo firmas?", {"n": V.n, "tot": Datos.eur(tot), "efe": Datos.eur(efe), "tr": Datos.eur(tr), "sm": Datos.eur(sm)}), [K("Firmar"), K("No")], A) != 0:
		return
	if S.banco < tr + sm:
		sfx("bad")
		await say(T("Con la transferencia y el primer año del seguro hacen falta {e} en tu cuenta, y hay {b}. Lo dejamos reservado si quieres.", {"e": Datos.eur(tr + sm), "b": Datos.eur(S.banco)}), A)
		return
	S.money -= efe
	cobro_banco(tr, C.n + " · " + V.n)
	cobro_banco(sm, T("Seguro · {n}", {"n": V.n}))
	if not (S.get("coches") is Dictionary):
		S.coches = {}
	S.coches[k] = {"dia": int(S.day) + int(V.entrega), "p": tot, "r": int(S.day) + int(V.entrega) + int(C.anio), "iv": int(S.day) + int(V.entrega), "km": 0}
	if V.calor:
		S.heat = mini(100, int(S.heat) + int(V.calor))
	sfx("coin")
	update_hud()
	var fx: String = T(" Lo traen bajo pedido de fábrica.") if k == "deportivo" else ""
	await say(T("Firmado. {A}, a tu nombre: en {d} días está matriculada y te aviso por SMS.{x}", {"A": mayus(V.art), "d": int(V.entrega), "x": fx}) if _art_m(k) == "a" else T("Firmado. {A}, a tu nombre: en {d} días está matriculado y te aviso por SMS.{x}", {"A": mayus(V.art), "d": int(V.entrega), "x": fx}), A)

func vender_coche(l: Array) -> void:
	var A := K("ARANTXA")
	var it := []
	for k in l:
		it.append({"label": D.CONCE.v[k].n, "right": Datos.eur(valor_coche(k)), "desc": T("Pagaste {p} y lleva {km} km. Te damos {v}, por transferencia.", {"p": Datos.eur(S.coches[k].p), "km": Datos.miles(S.coches[k].get("km", 0)), "v": Datos.eur(valor_coche(k))})})
	it.append({"label": K("Nada"), "desc": ""})
	var j: int = await menu(it, {"cls": "full", "title": K("VENDER"), "desc": true})
	if j < 0 or j >= l.size():
		return
	var k: String = l[j]
	var v := valor_coche(k)
	if await ask(T("Por {a} te damos {v}. ¿Trato hecho?", {"a": D.CONCE.v[k].art, "v": Datos.eur(v)}), [K("Vender"), K("No")], A) != 0:
		return
	S.coches.erase(k)
	abono_banco(v, T("{n} · venta", {"n": D.CONCE.n}))
	sfx("coin")
	update_hud()
	await say(T("Hecho: {v} en tu cuenta. El seguro se da de baja hoy.", {"v": Datos.eur(v)}), A)

func asegurar_coche(l: Array) -> void:
	var k: String = l[0]
	var sm := seguro_anio(k)
	if not cobro_banco(sm, T("Seguro · {n}", {"n": D.CONCE.v[k].n})):
		sfx("bad")
		await say(T("El año de póliza son {e}, de la cuenta, y no hay.", {"e": Datos.eur(sm)}), K("ARANTXA"))
		return
	S.coches[k].r = int(S.day) + int(D.CONCE.anio)
	S.coches[k].erase("grua")
	sfx("coin")
	await say(T("Póliza en vigor: {e} al año, domiciliado. Y te saco {a} del depósito de la grúa.", {"e": Datos.eur(sm), "a": D.CONCE.v[k].art}), K("ARANTXA"))

# cada mañana: la apertura (con el capítulo y el dinero), las entregas y el seguro de cada uno; sin pagar, la póliza se anula
func conce_dia() -> void:
	if not Datos.CAL:   # contra el HTML congelado (1.37), nada
		return
	var C: Dictionary = D.CONCE
	if S.flags.get("conce") == null and int(S.ch) >= int(C.ch) and float(S.money) + float(S.banco) >= float(C.patri):
		S.flags.conce = S.day
		if S.map == "alto":
			montar_alto()
		queue("conce", func(): await talk(K("SMS · ") + C.n, [C.txt.abre]))
	if not (S.get("coches") is Dictionary):
		return
	for k in C.orden:
		var c = S.coches.get(k)
		if c == null:
			continue
		var V: Dictionary = C.v[k]
		if int(c.dia) == int(S.day):
			var cx: String = T(" Y en la calle, montado.") if k == "moto" else T(" Y en la calle, al volante.") if D.VEHICULOS.has(k) else ""
			var tx: String = T("{A} ya está matriculada y con el seguro en vigor. Desde cualquier parada de autobús puedes ir en ella, a la hora que quieras.{x}", {"A": mayus(V.art), "x": cx}) if _art_m(k) == "a" else T("{A} ya está matriculado y con el seguro en vigor. Desde cualquier parada de autobús puedes ir en él, a la hora que quieras.{x}", {"A": mayus(V.art), "x": cx})
			queue("coche" + k, func(): await talk(K("SMS · ") + C.n, [tx]))
		if c.get("r") != null and not cobra(c, seguro_anio(k), K("ASEGURADORA"), true, T("seguro de {a}", {"a": String(V.art)}), int(C.anio)):
			c.r = null
			var tx2: String = T("Póliza anulada por impago: {a} ya no tiene seguro. Sin seguro no se puede circular.", {"a": V.art})
			queue("seg" + k, func(): await talk(K("SMS · ASEGURADORA"), [tx2]))
		multa_aparcado(k)
		if c.get("iv") == null:   # de antes de la 1.43.2
			c.iv = maxi(int(c.dia), int(S.day))
		if not cobra(c, float(V.ivtm), K("AYUNTAMIENTO"), true, T("impuesto de circulación de {a}", {"a": String(V.art)}), int(C.anio), "iv"):   # sin pagar, por apremio con recargo
			var e: float = roundf(float(V.ivtm) * (1.0 + float(C.recargo)))
			pagar_recibo(e, T("Apremio · IVTM · {n}", {"n": String(V.n)}))
			c.iv = int(c.iv) + int(C.anio)
			var tx3: String = T("Providencia de apremio: el impuesto de circulación de {a}, con un {r} % de recargo, {e}, cobrado de lo que tienes.", {"a": V.art, "r": roundi(float(C.recargo) * 100), "e": Datos.eur(e)})
			queue("iv" + k, func(): await talk(K("SMS · AYUNTAMIENTO"), [tx3]))

# MAESTRO [3] (lo pidió el usuario: «si tienes aparcado el coche más de 3 días en el mismo pueblo, te pueden poner multa»): fuera del
# garaje, pasados CONCE.multa.dias desde que lo aparcaste (c.ap), cada día CONCE.multa.p de una multa de CONCE.multa.e. Por hash, sin el azar
func multa_aparcado(k: String) -> void:
	var c: Dictionary = S.coches[k]
	if donde(k) == GARAJE or not coche_ya(k):
		c.erase("ap")
		return
	if c.get("ap") == null:   # aparcado antes de esto
		c.ap = S.day
	var M: Dictionary = D.CONCE.multa
	if int(S.day) - int(c.ap) <= int(M.dias) or Datos.hash_str("multa|%d|%s" % [int(S.day), k]) % 1000 >= float(M.p) * 1000:
		return
	var V: Dictionary = D.CONCE.v[k]
	var pu: String = D.PARADAS[donde(k)].n
	var f := pagar_recibo(float(M.e), T("Multa · {p}", {"p": pu}))
	var tx: String = T("Multa del Ayuntamiento de {p}: {a} lleva más de {d} días en el aparcamiento de la parada. {e}, cobrados de lo que tienes.", {"p": pu, "a": V.art, "d": int(M.dias), "e": Datos.eur(M.e)})
	if f > 0:
		tx += " " + T("Te quedan a deber {f}.", {"f": Datos.eur(f)})
	queue("multa" + k, func(): await talk(K("SMS · AYUNTAMIENTO"), [tx]))

# de parada en parada con tu vehículo (CONCE.km de cada una; CONCE.v[k].t del tiempo del autobús, sin esperas)
func tramo(a: String, b: String, k: String) -> Dictionary:
	var V: Dictionary = D.CONCE.v[k]
	var km: int = int(D.CONCE.km[a]) + int(D.CONCE.km[b])
	var pj: int = int(D.METRO.peaje) if "metropoli" in [a, b] and D.has("METRO") else 0   # MAESTRO [9]: la autopista, con su peaje
	return {"km": km, "min": maxi(5, roundi(viaje(a, b).min * float(V.t))), "eur": maxi(1, roundi(km * float(V.l) / 100.0 * float(D.CONCE.litro))) + pj}

func conducir(k):
	var aqui: String = S.map
	var ds := []
	for x in D.PARADAS:
		if x != aqui and (S.ch >= int(D.PARADAS[x].cap) or (x == "metropoli" and metro_ya())):   # MAESTRO [9]: la ciudad, por patrimonio
			ds.append(x)
	var it := []
	for x in ds:
		var t := tramo(aqui, x, k)
		it.append({"label": D.PARADAS[x].n, "right": T("{m} min · {e}", {"m": t.min, "e": Datos.eur(t.eur)})})
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿A dónde vas?")})
	if i < 0 or i >= ds.size():
		return
	var x: String = ds[i]
	var t := tramo(aqui, x, k)
	if S.money >= t.eur:   # la gasolina: en efectivo o con tarjeta
		S.money -= t.eur
	elif not cobro_banco(t.eur, K("Gasolinera")):
		sfx("bad")
		await say(T("Para la gasolina hacen falta {e} y no te llega.", {"e": Datos.eur(t.eur)}))
		return
	var taller := kilometros(k, int(t.km))
	sfx("door")
	await fade(1)
	await anim_viaje(k, aqui, x, int(t.min))
	advance_time(t.min)
	var a: Array = D.PARADAS[x].a
	if Datos.CAL:   # MAESTRO [3]: se queda en el aparcamiento de la parada (en Ribera Verde, en el garaje, y sales por su puerta)
		S.coches[k].en = x
		S.coches[k].ap = S.day   # el día que lo aparcas (multa_aparcado)
		if x == GARAJE:
			a = [GARAJE_B.x0 + 1, GARAJE_B.y0 + GARAJE_B.h, "down"]
		else:
			montar_aparcamiento(x)
			a = llegada_parque(x, k)
	enter_map(x, int(a[0]), int(a[1]), a[2])
	if S.clientsDay != S.day:
		spawn_clients()
	update_hud()
	await wait(80)
	await fade(0)
	if Datos.CAL:
		await caida_moto(k)
	if taller != "":
		sfx("bad")
		await talk(K("SMS · TALLER"), [taller])
	await control_trafico(k)
	await metro_llegada()   # MAESTRO [9]: las bandas de la ciudad

# Los km de cada vehículo; al pasar cada CONCE.v[k].revKm, la revisión (aceite y filtros), y cada neuKm, los neumáticos
func kilometros(k: String, km: int) -> String:
	var V: Dictionary = D.CONCE.v[k]
	var c: Dictionary = S.coches[k]
	var a: int = int(c.get("km", 0))
	c.km = a + km
	var tx := []
	for q in [["rev", "revKm", K("la revisión de {km} km (aceite y filtros)")], ["neu", "neuKm", K("neumáticos nuevos a los {km} km")]]:  # i18n-no
		var n: int = int(c.km) / int(V[q[1]]) - a / int(V[q[1]])
		if n > 0:
			var e: float = float(V[q[0]]) * n
			var f := pagar_recibo(e, T("Taller · {n}", {"n": String(V.n)}))
			var qt: String = T(String(q[2]), {"km": Datos.miles(int(c.km) / int(V[q[1]]) * int(V[q[1]]))})
			tx.append(T("{q}: {e} (te quedan a deber {f})", {"q": qt, "e": Datos.eur(e), "f": Datos.eur(f)}) if f > 0 else T("{q}: {e}", {"q": qt, "e": Datos.eur(e)}))
	return T("{a}, en el taller. {tx}.", {"a": mayus(V.art), "tx": ". ".join(tx)}) if tx.size() else ""

# ---------- MAESTRO [3]: el garaje, el aparcamiento y el maletero (con Datos.CAL) ----------
# (lo pidió el usuario: «tiene que estar en el garaje; del garaje viajas al otro pueblo y se queda estacionado en un aparcamiento;
# no se usa por el mapa»). Cada vehículo está en un pueblo (S.coches[k].en): en Ribera Verde, en el garaje; en los demás, en el
# aparcamiento de la parada (plazas_parque). Desde la parada o con A delante de él: viajar o el maletero. El maletero
# (MALETERO.kg por vehículo) guarda cogollos como la caja fuerte y los envasa al vacío (la envasadora, en la tienda online: en un
# control de tráfico, MALETERO.vacio.f)
func coche_menu(k: String):
	var V: Dictionary = D.CONCE.v[k]
	var ops := [K("Viajar"), K("Maletero")]
	ops.append_array(ops_abono(k))
	ops.append(K("Nada"))
	var j: int = await ask(T("{A}, en el aparcamiento. Maletero: {g} de {c}.", {"A": mayus(V.art), "g": g_txt(mal_peso(k)), "c": _kg(int(D.MALETERO.kg.get(k, 0)))}), ops)
	var op: String = ops[j] if j >= 0 and j < ops.size() else ""
	if j == 0:
		await conducir(k)
	elif j == 1:
		await maletero(k)
	elif op != "":
		await accion_abono(k, op)

# (MAESTRO [3]: «rellenar tanques de abono de la nave»): las garrafas de abono de floración que llevas, al maletero; en Valdehierro,
# del maletero a la estantería y los tanques de la nave (S.nave.ab)
func ops_abono(k: String) -> Array:
	var o := []
	if int(S.items.get("fert", 0)) + int(S.items.get("ofert", 0)) > 0:
		o.append(T("Cargar el abono {dv}", {"dv": de_art(String(D.CONCE.v[k].art))}))
	if S.map == "valdehierro" and S.get("nave") and float(mal_ab(k).m) + float(mal_ab(k).o) > 0:   # i18n-no
		o.append(K("Rellenar los tanques de la nave"))
	return o

func accion_abono(k: String, op: String) -> void:
	var A := mal_ab(k)
	if op == K("Rellenar los tanques de la nave"):
		var da := {"m": int(A.m), "o": int(A.o)}
		S.nave.ab.m += A.m
		S.nave.ab.o += A.o
		A.m = 0
		A.o = 0
		sfx("sel")
		await say(T("Descargas el abono en la nave: MEATZA ×{m} y ORTUA BIO ×{o}. Los tanques, llenos: MEATZA ×{tm} · ORTUA BIO ×{to}.", da.merged({"tm": dosis_txt(S.nave.ab.m), "to": dosis_txt(S.nave.ab.o)})))
		return
	var cabe: int = int(floor((mal_kg(k) - mal_peso(k)) / float(D.MALETERO.dosis)))
	var q := {"m": 0, "o": 0}
	for par in [["fert", "m"], ["ofert", "o"]]:   # i18n-no
		var n: int = mini(int(S.items.get(par[0], 0)), cabe)
		cabe -= n
		q[par[1]] = n
		S.items[par[0]] = int(S.items.get(par[0], 0)) - n
		A[par[1]] = int(A[par[1]]) + n
	if q.m + q.o < 1:
		await say(K("En el maletero no cabe más."))
		return
	sfx("sel")
	await say(T("Cargas el abono en el maletero: MEATZA ×{m} y ORTUA BIO ×{o} dosis.", q) + ((" " + K("No cabe todo: el resto se queda fuera.")) if int(S.items.get("fert", 0)) + int(S.items.get("ofert", 0)) > 0 else ""))

# A en la puerta del garaje: salir con uno de los que hay dentro o abrirle el maletero
func garaje_menu():
	var ks := aparcados(GARAJE)
	if ks.is_empty():
		await say(K("El garaje de la tía. Está vacío: aquí se guarda lo que compres en AUTOS RIBERA."))
		return
	var ops := []
	for k in ks:
		ops.append(T("Salir en {v}", {"v": String(D.CONCE.v[k].art)}))
	for k in ks:
		ops.append(T("Maletero {dv}", {"dv": de_art(String(D.CONCE.v[k].art))}))
	var ab := []
	for k in ks:
		for o in ops_abono(k):
			ops.append(o)
			ab.append(k)
	ops.append(K("Nada"))
	var c: int = await ask(K("El garaje de la tía."), ops)
	if c < 0 or c >= ops.size() - 1:
		return
	if c < ks.size():
		await conducir(ks[c])
	elif c < 2 * ks.size():
		await maletero(ks[c - ks.size()])
	else:
		await accion_abono(ab[c - 2 * ks.size()], ops[c])

func maletero(k: String) -> void:
	MAL_K = k
	var i := 0
	while true:
		var e = await elegir_almacen("mal", i)
		if e == null:
			return
		i = e.i
		if e.k == "+":
			await guardar_mal(k)
			continue
		if e.k == "v":
			await envasar(k)
			continue
		var g: float = minf(floor(e.b.g * 10) / 10.0, floor(libre_mochila()))
		if g < 1:
			await say(K("No te cabe nada más encima."))
			continue
		mover_lote(mal(k).buds, S.buds, e.k, g)
		sfx("sel")
		await say(T("Sacas {g} de {n}.", {"g": g_txt(g), "n": lot_nombre(e.k)}))

func guardar_mal(k: String) -> void:
	var L := bud_lots(1)
	if L.is_empty():
		await say(K("No llevas cogollos encima."))
		return
	var q := 0.0
	for l in L:
		var g: float = minf(l[1].g, floor(mal_kg(k) - mal_peso(k)))
		if g < 1:
			break
		q += g
		mover_lote(S.buds, mal(k).buds, l[0], g)
	sfx("sel")
	if q < 1:
		await say(K("En el maletero no cabe más."))
		return
	await say(T("Guardas {q} en el maletero.", {"q": g_txt(q)}) + ((" " + T("No cabe todo: el resto se queda fuera.")) if total_buds() >= 1 else ""))

# al vacío: con la envasadora (S.items.vacio), cada lote del maletero, en su bolsa (b.vac): en un registro, se nota menos
func envasar(k: String) -> void:
	if not S.items.get("vacio"):
		await say(K("Sin envasadora al vacío: se pide en la tienda online."))
		return
	var n := 0
	for q in mal(k).buds:
		if not mal(k).buds[q].get("vac"):
			mal(k).buds[q].vac = true
			n += 1
	sfx("sel")
	await say(T("Envasas al vacío {n} lotes del maletero.", {"n": n}) if n else K("Ya está todo envasado."))

func mal_vacio(k: String) -> bool:   # todo lo del maletero, al vacío
	for q in mal(k).buds:
		if not mal(k).buds[q].get("vac"):
			return false
	return true

# la moto (MALETERO.cae): de vez en cuando, en un bache, se cae parte de la carga
func caida_moto(k: String) -> void:
	if k != "moto" or mal_g(k) < 1 or Cultivo.azar() >= float(D.MALETERO.cae):
		return
	var L: Dictionary = mal(k).buds
	var q0: String = L.keys()[0]
	var g: float = floor(float(L[q0].g) * float(D.MALETERO.caeF) + 1)
	L[q0].g = float(L[q0].g) - g
	if L[q0].g < 1:
		L.erase(q0)
	sfx("bad")
	await say(T("Un bache: se ha caído {g} del baúl de la moto.", {"g": g_txt(g)}))

# el control de tráfico (CONCE.control; el deportivo, el triple): el seguro y, si te registran, lo que lleves encima
func control_trafico(k: String) -> void:
	var C: Dictionary = D.CONCE
	if Cultivo.azar() >= float(C.control) * (3.0 if k == "deportivo" else 1.0):
		return
	var V: Dictionary = C.v[k]
	sfx("bad")
	await say(T("Control de tráfico a la entrada. «Buenas. Carné, permiso de circulación y el seguro de {a}.»", {"a": V.art}), K("AGENTE"))
	if S.coches[k].get("r") == null:
		var f: float = pagar_recibo(float(C.sinSeguro), K("Multa · sin seguro"))
		S.coches[k].grua = true
		await say(T("Sin seguro en vigor: denuncia de {e} (te faltan {f}) y {a}, a la grúa hasta que lo asegures.", {"e": Datos.eur(C.sinSeguro), "f": Datos.eur(f), "a": V.art}) if f > 0 else T("Sin seguro en vigor: denuncia de {e} y {a}, a la grúa hasta que lo asegures.", {"e": Datos.eur(C.sinSeguro), "a": V.art}), K("AGENTE"))
	var enmal: bool = Datos.CAL and mal_g(k) >= 1   # MAESTRO [3]: lo del maletero también cuenta; al vacío, se nota menos
	if total_buds() < 1 and total_rosin() <= 0 and not enmal:
		await say(K("«Todo en orden. Circule.»"), K("AGENTE"))
		return
	var pr: float = .5 + float(S.heat) / 200.0
	if enmal and Datos.CAL and D.has("CONTROL"):   # MAESTRO [4]: el peso del maletero también cuenta
		pr += mal_g(k) / 1000.0 * float(D.CONTROL.kg)
	if enmal and mal_vacio(k):
		pr *= float(D.MALETERO.vacio.f)
	if Cultivo.azar() >= pr:
		await say(K("Te mira un rato. «Circule.»"), K("AGENTE"))
		return
	if Datos.CAL and D.has("CONTROL") and await resolver_control(k, enmal):
		return
	var habia: bool = total_buds() >= 1 or total_rosin() > 0
	var r := confiscate()
	if enmal:
		var gm := mal_g(k)
		mal(k).buds = {}
		r[0] = T("{r} y {g} del maletero", {"r": r[0], "g": g_txt(gm)}) if habia else T("{g} del maletero", {"g": g_txt(gm)})
	S.heat = mini(100, int(S.heat) + 10)
	update_hud()
	await say(T("«¿Y este olor?» Te registran {a}: te requisan {r} y te multan con {e}.", {"a": V.art, "r": r[0], "e": Datos.eur(r[1])}), K("AGENTE"))

# MAESTRO [4]: el control de carretera (PoliceCheckpoint). Te van a registrar: huir (mejor en el deportivo o en la moto; si no sale,
# multa y calor), sobornar al agente, entregarle la carga tú (sin multa) o dejar que registren (lo de siempre, devuelve false).
# Las tiradas, por hash_str (no por Cultivo.azar). true: ya está resuelto
func resolver_control(k: String, enmal: bool) -> bool:
	var C: Dictionary = D.CONTROL
	var V: Dictionary = D.CONCE.v[k]
	var gl := total_buds() + (mal_g(k) if enmal else 0.0)
	var cost: int = Datos.jsround(float(C.soborno.base) + gl * float(C.soborno.g))
	var ops := [K("Huir"), T("Sobornar ({e})", {"e": Datos.eur(cost)}), K("Entregar la carga"), K("Dejar que registren")]
	var c: int = await ask(T("«Abra {a}, por favor.» Llevas {g} encima y en el maletero.", {"a": V.art, "g": g_txt(gl)}), ops, K("AGENTE"))
	var h := Datos.hash_str("control%d_%d_%s" % [S.day, int(S.min), k]) % 100
	if c == 0:
		var ph: float = float(C.huir.get(k, C.huir.p))
		if h < int(ph * 100):
			S.heat = mini(100, int(S.heat) + int(C.huida.calor))
			update_hud()
			sfx("bad")
			await say(T("Pisas a fondo y te pierdes por la comarcal. Te han visto la matrícula: calor +{c}.", {"c": int(C.huida.calor)}))
			return true
		confiscate(false)
		if enmal:
			mal(k).buds = {}
		var f: float = pagar_recibo(float(C.fallo.multa), K("Multa · huida"))
		S.heat = mini(100, int(S.heat) + int(C.fallo.calor))
		update_hud()
		await say(T("Te cierran el paso en la rotonda. Te requisan {r} y te multan con {e} por darte a la fuga.", {"r": g_txt(gl), "e": Datos.eur(float(C.fallo.multa) - f)}), K("AGENTE"))
		return true
	if c == 1:
		if S.money < cost:
			await say(K("No llevas tanto dinero encima."))
			return false
		S.money -= cost
		if h < int((float(C.soborno.p) - float(S.heat) / float(C.soborno.calor)) * 100):
			update_hud()
			await say(K("Se guarda el sobre sin mirarte. «Circule. Y no le he visto.»"), K("AGENTE"))
			return true
		await say(K("«¿Me está intentando sobornar?» Se queda el sobre como prueba."), K("AGENTE"))
		return false
	if c == 2:
		confiscate(false)
		if enmal:
			mal(k).buds = {}
		S.heat = mini(100, int(S.heat) + int(C.entregar.calor))
		update_hud()
		await say(T("Le das la carga sin rechistar: {r}. «Por esta vez, sin multa. Circule.»", {"r": g_txt(gl)}), K("AGENTE"))
		return true
	return false

# ---------- El muelle de Puerto Viejo, los envíos por mar y el piso franco ----------
# (lo pidió el usuario: «distribución a gran escala por un piso franco o una persona… un mini puerto para hacer envíos, invertir en un
# barco, empezando por uno pequeño… algo adictivo cuando ya lo tienes todo, continuando la trama»). Desde el capítulo MAR.ch: Koldo, el
# amigo de la tía Maite, te da su txalupa; los envíos zarpan del noray de cada barco hacia las rutas que abre la reputación; el
# primero que llega abre el piso franco de Gorka, que reparte por tierra lo que le dejes; cada semana, un pedido con prima, y al
# final, el último trabajo de Koldo. Lo de cada día, en mar_dia y franco_dia (desde curro_dia).

func mar_ok() -> bool:
	return Datos.CAL and D.has("MAR") and S.get("mar") is Dictionary

func barco_k(k: String) -> Dictionary:
	for B in D.MAR.barcos:
		if B.k == k:
			return B
	return {}

func rutas_mar() -> Array:
	var o := []
	for i in D.MAR.rutas.size():
		if float(S.mar.rep) >= float(D.MAR.rutas[i].rep):
			o.append(i)
	return o

func rango_mar() -> String:
	var r: String = D.MAR.rangos[0][1]
	for x in D.MAR.rangos:
		if float(S.mar.kg) >= float(x[0]):
			r = x[1]
	return r

func en_mar(k: String):
	for e in S.mar.env:
		if e.b == k:
			return e
	return null

func cap_mar() -> int:
	var c := 0
	for k in S.mar.b:
		c = maxi(c, int(barco_k(k).kg))
	return c

func _ped_txt(p: Dictionary) -> String:
	return T("{kg} a {r}, de {thc} % de THC o más, antes del {d}", {"kg": _kg(int(p.g)), "r": D.MAR.rutas[int(p.r)].n, "thc": int(p.thc), "d": Datos.fd(int(p.d), S.day)})

func talk_koldo() -> void:
	var R: Dictionary = D.MAR
	var N := K("KOLDO")
	if S.get("mar") == null:
		await talk(N, [K("Tú eres el sobrino de Maite. Tienes su cara cuando se reía de los guardias."),
			K("En los ochenta, tu tía y yo traíamos semillas de fuera en mi txalupa. Las primeras landraces de la comarca llegaron por este muelle."),
			K("La txalupa sigue ahí, en el primer noray. Se llama Maite: se la puse yo. Ahora es tuya."),
			T("Cargas en el noray, eliges la ruta y zarpas. A la vuelta, te pagan por transferencia de una conservera, {e}: limpio.", {"e": R.empresa}),
			T("Pequeño al principio: {a} como mucho. Y no menos de {b} por viaje, que el gasoil no es gratis.", {"a": _kg(int(barco_k("txalupa").kg) * 1000), "b": _kg(int(R.min))})])
		S.mar = {"b": ["txalupa"], "rep": 0, "kg": 0.0, "env": [], "ped": null, "pd": 0, "paso": 0, "fin": 0, "n": 0}
		confia("koldo", 10)
		montar_muelle(S.map)
		build_ents()
		sfx("get")
		return
	var i := 0
	while true:
		var M_: Dictionary = S.mar
		var ops := [K("Los envíos en el mar"), K("El pedido de la semana"), K("Las rutas"), K("Comprar un barco")]
		if R.has("obras"):
			ops.append(K("Las obras del muelle"))
		if int(M_.get("ley", 0)) > 0:
			ops.append(K("La distribuidora") if M_.get("lic") else K("La licencia"))
		var gran: bool = not M_.get("fin") and float(M_.rep) >= float(R.gran.rep) and ("pesquero" in M_.b or "atunero" in M_.b)
		if gran:
			ops.append(K("El último trabajo"))
		ops.append(K("Nada"))
		i = await ask(T("{r} · {kg} exportados · reputación {rep}.", {"r": rango_mar(), "kg": _kg(int(float(M_.kg) * 1000)), "rep": int(M_.rep)}), ops, N)
		var l: String = ops[i] if i >= 0 else K("Nada")
		if l == "Nada":
			await say(K("Ondo ibili. Que el mar te sea leve."), N)
			return
		if l == "Los envíos en el mar":
			if M_.env.is_empty():
				await say(K("Ahora mismo no tienes nada en el mar. Se carga en el noray de cada barco."), N)
			else:
				var L := []
				for e in M_.env:
					L.append(T("{b}, a {r} con {kg}: llega el {d}.", {"b": may1(barco_k(e.b).n), "r": R.rutas[int(e.r)].n, "kg": _kg(int(e.g)), "d": Datos.fd(int(e.d), S.day)}))
				await talk(N, L)
		elif l == "El pedido de la semana":
			if M_.ped is Dictionary:
				await say(T("Esta semana piden {p}. Si lo cumples, pagan un {b} % más.", {"p": _ped_txt(M_.ped), "b": Datos.jsround((float(R.ped.bonus) - 1) * 100)}), N)
			elif int(M_.paso) < 1:
				await say(K("Primero, un viaje que salga bien. Luego te presento a la gente de fuera."), N)
			else:
				await say(K("Esta semana no hay pedido. Los lunes suelen llamar."), N)
		elif l == "Las rutas":
			var L := []
			for j in R.rutas.size():
				var rt: Dictionary = R.rutas[j]
				L.append((T("{r}: {d} día más de viaje, pagan ×{px}.", {"r": rt.n, "d": int(rt.d), "px": Datos.coma(float(rt.px))}) if int(rt.d) == 1 else T("{r}: {d} días más de viaje, pagan ×{px}.", {"r": rt.n, "d": int(rt.d), "px": Datos.coma(float(rt.px))})) if float(M_.rep) >= float(rt.rep) else T("{r}: con reputación {rep}.", {"r": rt.n, "rep": int(rt.rep)}))
			await talk(N, L)
		elif l == "Comprar un barco":
			await comprar_barco(N)
		elif l == "Las obras del muelle":
			await obras_muelle(N)
		elif l == "La licencia":
			await licencia_mar(N)
		elif l == "La distribuidora":
			await vender_legal(N)
		elif l == "El último trabajo":
			await say(T("Un armador de {r} quiere {kg} en un solo viaje, y lo paga como nadie. Es el trabajo que tu tía y yo nunca nos atrevimos a hacer. Si sale, el muelle es tuyo.", {"r": R.rutas[int(R.gran.ruta)].n, "kg": _kg(int(R.gran.kg) * 1000)}), N)
			M_.gr = 1

func comprar_barco(N: String) -> void:
	var ops := []
	var bs := []
	for B in D.MAR.barcos:
		if not B.k in S.mar.b:
			ops.append("%s · %s" % [may1(B.n), Datos.eur(B.p)])
			bs.append(B)
	if bs.is_empty():
		await say(K("Ya tienes la flota entera. Ni la cofradía tiene tantos."), N)
		return
	ops.append(K("Nada"))
	var j: int = await ask(K("Barcos de segunda mano de la cofradía. Se pagan por transferencia."), ops, N)
	if j < 0 or j >= bs.size():
		return
	var B: Dictionary = bs[j]
	if B.get("req") and not obra_ya(B.req):
		await say(T("{b} no cabe en el muelle tal como está. Antes, {o}: {t}", {"b": may1(B.n), "o": obra_k(B.req).n, "t": obra_k(B.req).txt}), N)
		return
	if not await confirm(T("{b}: {p}, carga hasta {kg}, {d} días de viaje. ¿Lo compras?", {"b": may1(B.n), "p": Datos.eur(B.p), "kg": _kg(int(B.kg) * 1000), "d": int(B.dias)})):
		return
	if not cobro_banco(float(B.p), T("Compra · {n}", {"n": B.n})):
		await say(K("En la cuenta no llega. Con el banco no se discute."), N)
		return
	S.mar.b.append(B.k)
	montar_muelle("muelle")
	sfx("get")
	await say(K("Hecho. Lo amarro en su noray esta misma tarde."), N)

func confirm(t: String) -> bool:
	return await ask(t, [K("Sí"), K("No")]) == 0

# A en el noray: el barco de ese amarre
func mar_noray(x: int) -> void:
	var B := {}
	for b in D.MAR.barcos:
		if int(b.nor) == x:
			B = b
	if B.is_empty():
		await say(K("Un noray de hierro, gastado por los cabos."))
		return
	if S.get("mar") == null:
		await say(K("Un noray de la cofradía. Koldo, el viejo de la acera, sabe de quién es cada amarre."))
		return
	if not B.k in S.mar.b:
		await say(T("Amarre libre. Aquí cabe {b}: Koldo lo vende por {p}.", {"b": B.n, "p": Datos.eur(B.p)}))
		return
	var e = en_mar(B.k)
	if e != null:
		await say(T("{b} está en el mar, camino de {r}. Vuelve el {d}.", {"b": may1(B.n), "r": D.MAR.rutas[int(e.r)].n, "d": Datos.fd(int(e.d), S.day)}))
		return
	await cargar_envio(B)

func cargar_envio(B: Dictionary) -> void:
	var R: Dictionary = D.MAR
	var rs := rutas_mar()
	var ops := []
	for j in rs:
		var rt: Dictionary = R.rutas[j]
		ops.append({"label": rt.n, "right": "×" + Datos.coma(float(rt.px)), "desc": T("{d} días de viaje con {b}.", {"d": int(B.dias) + int(rt.d), "b": B.n})})
	ops.append({"label": K("Nada")})
	var ir: int = await menu(ops, {"cls": "right", "title": K("¿A dónde?"), "desc": true})
	if ir < 0 or ir >= rs.size():
		return
	var ri_: int = rs[ir]
	var carga := []   # [k, g, thc, calidad]
	var tot := 0
	var cap: int = int(B.kg) * 1000
	while true:
		var lots := bud_lots(1)
		lots = lots.filter(func(l): return carga.all(func(c): return c[0] != l[0]))
		var it := lots.map(venta_item)
		if tot >= int(R.min):
			it.append({"label": T("Zarpar ({kg})", {"kg": _kg(tot)})})
		it.append({"label": K("Nada")})
		var i: int = await menu(it, {"cls": "right", "title": T("La carga · {a} de {b}", {"a": _kg(tot), "b": _kg(cap)})})
		if i >= 0 and i < lots.size():
			var l: Array = lots[i]
			var g = await cuanto(T("¿Cuánto de {n}?", {"n": lot_nombre(l[0])}), mini(int(floor(l[1].g)), cap - tot), [250, 500, 1000, 2000, 5000, 10000, 20000], func(v): return _kg(int(v)))
			if g > 0:
				carga.append([l[0], int(g), float(l[1].thc), calidad(l[1], true)])
				tot += int(g)
			if tot >= cap:
				await say(K("La bodega va llena."))
			continue
		if i == lots.size() and tot >= int(R.min):
			break
		return
	if tot < int(R.min):
		return
	var rt: Dictionary = R.rutas[ri_]
	var P_ = S.mar.ped
	var ped: bool = P_ is Dictionary and int(P_.r) == ri_ and tot >= int(P_.g) and S.day <= int(P_.d) and carga.all(func(c): return c[2] >= float(P_.thc))
	var gr: bool = S.mar.get("gr") and not S.mar.get("fin") and ri_ == int(R.gran.ruta) and tot >= int(R.gran.kg) * 1000
	var e := 0.0
	for c in carga:
		e += precio_mayor(c[2]) * c[3] * float(rt.px) * c[1]
		use_buds(c[0], c[1])
	if ped:
		e *= float(R.ped.bonus)
		S.mar.ped = null
	var pm: float = float(B.r) + float(rt.r) + float(S.heat) / 1000.0
	if obra_ya("caseta"):   # 1.52: la caseta de la cofradía vigila el muelle
		pm *= float(obra_k("caseta").r)
	var mal: bool = Cultivo.azar() < pm and not gr
	S.mar.env.append({"b": B.k, "r": ri_, "g": tot, "e": Datos.jsround(e), "d": S.day + int(B.dias) + int(rt.d), "mal": mal, "ped": ped, "gr": gr})
	sfx("get")
	update_hud()
	await say(T("Sueltas amarras. {b} sale hacia {r} con {kg}: llega el {d}.", {"b": may1(B.n), "r": rt.n, "kg": _kg(tot), "d": Datos.fd(S.day + int(B.dias) + int(rt.d), S.day)}) + (T(" Es el pedido de la semana.") if ped else "") + (T(" El último trabajo de Koldo.") if gr else ""))
	if Datos.CAL and D.has("PISOS9") and int(S.mar.get("exp", 0)) < 1:   # MAESTRO [9]: con la exportación, la red de pisos
		S.mar.exp = 1
		queue("pisos9", func(): await talk(K("SMS · IÑAKI"), [K("Me dicen que ya sacas género por mar. Con ese volumen, monta pisos de venta por los pueblos, con alguien de tu plantilla al frente: MÓVIL → PISOS.")]))

func mar_dia() -> void:
	if not mar_ok():
		return
	var R: Dictionary = D.MAR
	var M_: Dictionary = S.mar
	var quedan := []
	for e in M_.env:
		if S.day < int(e.d):
			quedan.append(e)
			continue
		var B := barco_k(e.b)
		var dest: String = R.rutas[int(e.r)].n
		if e.mal:
			S.heat = mini(100, int(S.heat) + int(R.calor))
			queue("mar" + e.b, func(): await talk(K("SMS · KOLDO"), [T("Malas noticias: la patrullera paró a {b} antes de {r}. Se han quedado la carga; el barco lo saco yo con la cofradía. Tranquilo unos días.", {"b": B.n, "r": dest})]))
			continue
		abono_banco(float(e.e), T("Transferencia · {n}", {"n": R.empresa}))
		S.sales += int(e.e)
		M_.kg = float(M_.kg) + float(e.g) / 1000.0
		M_.rep = float(M_.rep) + float(e.g) / 1000.0 + (float(R.ped.rep) if e.ped else 0.0)
		M_.n = int(M_.n) + 1
		var lin := [T("{b} ha llegado a {r}. {e} ha transferido {x}.", {"b": may1(B.n), "r": dest, "e": R.empresa, "x": Datos.eur(e.e)}) + (T(" Con la prima del pedido.") if e.ped else "")]
		if int(M_.paso) < 1:
			M_.paso = 1
			M_.pd = S.day
			lin.append(K("Ya tienes nombre fuera. Mi sobrino Gorka mueve cantidad por tierra: tiene un piso franco en el muelle, la puerta de la casa amarilla. Pásate."))
		if e.get("gr"):
			M_.fin = S.day
			abono_banco(float(R.gran.premio), T("Prima · {n}", {"n": R.empresa}))
			lin.append(K("Lo has hecho. Treinta años soñándolo y lo has hecho tú. Me retiro: el muelle es tuyo, y la cofradía ya lo sabe."))
			lin.append(K("Maite estaría orgullosa. Y un poco celosa."))
		queue("mar" + e.b, func(): await talk(K("SMS · KOLDO"), lin))
	M_.env = quedan
	obras_dia()
	# el pedido de la semana: desde el primer viaje, cada 7 días
	if int(M_.paso) >= 1 and S.day >= int(M_.get("pd", 0)):
		var rs := rutas_mar()
		var r: int = rs[ri(0, rs.size() - 1)]
		var g: int = clampi(ri(1, cap_mar()), 1, 40) * 1000
		M_.ped = {"r": r, "g": maxi(g, int(R.min)), "thc": ri(int(R.ped.thc[0]), int(R.ped.thc[1])), "d": S.day + int(R.ped.dias)}
		M_.pd = S.day + int(R.ped.dias)
		var P_: Dictionary = M_.ped
		queue("marPed", func(): await talk(K("SMS · KOLDO"), [T("Pedido de la semana: {p}. Pagan un {b} % más.", {"p": _ped_txt(P_), "b": Datos.jsround((float(R.ped.bonus) - 1) * 100)})]))  # i18n-no

# el piso franco de Gorka: lo que dejas en el alijo, lo reparte por tierra cada mañana
func talk_gorka() -> void:
	var FR: Dictionary = D.FRANCO
	var N := K("GORKA")
	var F = S.get("franco")
	if not F is Dictionary:
		await say(K("Así que tú eres el de la txalupa. Koldo dice que eres de fiar."), N)
		var j: int = await ask(T("El piso es {alq} al mes, en efectivo. Lo que me dejes en las cajas, lo reparto yo por tierra, al por mayor: {kg} al día, y me quedo el {c} %.", {"alq": Datos.eur(FR.alq), "kg": _kg(int(FR.dia[0])), "c": Datos.jsround(float(FR.com) * 100)}), [K("Alquilar el piso"), K("Nada")], N)
		if j != 0:
			return
		if S.money < float(FR.alq):
			await say(K("Sin el primer mes por delante, nada."), N)
			return
		S.money -= float(FR.alq)
		S.franco = {"r": S.day + int(FR.per), "buds": {}, "caja": 0, "cal": 0.0, "niv": 0, "v": 0}
		confia("gorka", 5)
		update_hud()
		sfx("get")
		await say(K("Trato. Las cajas de la izquierda son el alijo: deja ahí el género y pasa a por la caja cuando quieras."), N)
		return
	while true:
		var rec: String = T("Recoger la caja ({e})", {"e": Datos.eur(F.caja)})
		var ops := [K("Cómo va"), rec]
		var nv: int = int(F.niv)
		if nv < FR.mej.size():
			ops.append("%s · %s" % [FR.mej[nv].n, Datos.eur(FR.mej[nv].p)])
		ops.append(K("Dejar el piso"))
		ops.append(K("Nada"))
		var i: int = await ask(T("Reparto hasta {a} al día. En el alijo hay {b}.", {"a": _kg(int(FR.dia[nv])), "b": _kg(int(stock_franco()))}), ops, N)
		var l: String = ops[i] if i >= 0 else K("Nada")
		if l == "Nada":
			return
		if l == "Cómo va":
			var cal: int = int(F.cal)
			var cq := {"kg": _kg(int(F.get("v", 0))), "d": Datos.fd(int(F.r), S.day)}
			await say(T("Ayer moví {kg}. La calle está tranquila. El alquiler, el {d}.", cq) if cal < 40 else (T("Ayer moví {kg}. La calle está caliente. El alquiler, el {d}.", cq) if cal < 70 else T("Ayer moví {kg}. La calle está que arde: afloja o nos cae una. El alquiler, el {d}.", cq)), N)
		elif l == rec:
			if int(F.caja) < 1:
				await say(K("Hoy no hay nada que recoger."), N)
			else:
				S.money += int(F.caja)
				await say(T("Aquí tienes: {e}, contados.", {"e": Datos.eur(F.caja)}), N)
				F.caja = 0
				update_hud()
				sfx("get")
		elif l == "Dejar el piso":
			if await confirm(K("¿Dejas el piso franco? Lo que haya en el alijo y en la caja te lo llevas tú.")):
				for k in F.buds.keys():
					mover_lote(F.buds, S.buds, k, F.buds[k].g)
				S.money += int(F.caja)
				S.franco = null
				update_hud()
				await say(K("Tú sabrás. Si vuelves, aquí estoy."), N)
				return
		elif nv < FR.mej.size():
			var mj: Dictionary = FR.mej[nv]
			if not await confirm("%s: %s. %s" % [mj.n, Datos.eur(mj.p), mj.d]):
				continue
			if S.money < float(mj.p):
				await say(K("Eso va en efectivo, y no lo llevas."), N)
				continue
			S.money -= float(mj.p)
			F.niv = nv + 1
			update_hud()
			sfx("get")
			await say(T("Hecho. {d}", {"d": mj.d}), N)

func stock_franco() -> float:
	var t := 0.0
	var F = S.get("franco")
	if F is Dictionary:
		for k in F.buds:
			t += float(F.buds[k].g)
	return t

# las cajas del alijo, en el piso franco
func alijo_franco() -> void:
	var F = S.get("franco")
	if not F is Dictionary:
		await say(K("Cajas de fruta vacías. Aquí se guarda el género, si alquilas el piso: habla con Gorka."))
		return
	var FR: Dictionary = D.FRANCO
	while true:
		var lots := bud_lots(1)
		var it := lots.map(venta_item)
		it.append({"label": K("Nada")})
		var i: int = await menu(it, {"cls": "right", "title": T("Al alijo · {a} de {b}", {"a": _kg(int(stock_franco())), "b": _kg(int(FR.cap))})})
		if i < 0 or i >= lots.size():
			return
		var l: Array = lots[i]
		var mx: int = mini(int(floor(l[1].g)), int(FR.cap - stock_franco()))
		if mx < 1:
			await say(K("El alijo está lleno."))
			return
		var g = await cuanto(T("¿Cuánto de {n} dejas?", {"n": lot_nombre(l[0])}), mx, [100, 250, 500, 1000, 2000, 5000], func(v): return _kg(int(v)))
		if g > 0:
			mover_lote(S.buds, F.buds, l[0], g)
			sfx("get")
			update_hud()

func franco_dia() -> void:
	var F = S.get("franco")
	if not Datos.CAL or not F is Dictionary:
		return
	var FR: Dictionary = D.FRANCO
	if not cobra(F, float(FR.alq), K("GORKA"), false, K("el piso franco"), int(FR.per)):
		S.franco = null
		queue("franco", func(): await talk(K("SMS · GORKA"), [K("Sin alquiler no hay piso. Lo del alijo cubre lo que debes. Si vuelves con dinero, hablamos.")]))
		return
	var cap: int = int(FR.dia[int(F.niv)])
	var ks: Array = F.buds.keys()
	ks.sort_custom(func(a, b): return float(F.buds[a].thc) > float(F.buds[b].thc))
	var v := 0
	for k in ks:
		if v >= cap:
			break
		var b: Dictionary = F.buds[k]
		var g: int = mini(int(floor(b.g)), cap - v)
		if g < 1:
			continue
		var e := Datos.jsround(precio_mayor(b.thc) * calidad(b, true) * float(FR.px) * g * (1 - float(FR.com)))
		F.caja = int(F.caja) + e
		S.sales += e
		b.g -= g
		v += g
		if b.g < .5:
			F.buds.erase(k)
	F.v = v
	F.cal = maxf(0, minf(100, float(F.cal) + v * float(FR.cal.g)) - float(FR.cal.baja))
	if F.cal >= float(FR.cal.redada):
		var perdido: float = stock_franco()
		var caja: int = int(F.caja)
		F.buds = {}
		F.caja = 0
		F.cal = float(FR.cal.vuelve)
		queue("franco", func(): await talk(K("SMS · GORKA"), [T("Han entrado en el piso. Yo estaba fuera. Se han llevado {kg} y {e} de la caja. Habrá que aflojar.", {"kg": _kg(int(perdido)), "e": Datos.eur(caja)})]))

# ---------- Las obras del muelle, el club KAIA y la ley ----------
# (lo pidió el usuario: «el barrio del puerto viejo… comenzar destartalado… ir reformándolo poco a poco, edificio por edificio… para
# meter un barco más grande se tiene que reformar el espacio… montar otro club ahí… una legalización del cannabis en España que
# abriría un mercado mucho mayor»). Las obras (MAR.obras) se pagan por el banco y se acaban a los d días (S.mar.ob: el día en que
# acaba cada una; S.mar.oba: las ya avisadas); el pesquero pide el pantalán y el atunero, el dique; las casas dan alquiler cada
# semana; el club KAIA despacha lo que le dejas (S.mar.kaia); MAR.legal.dias después de abrirlo, la ley (S.mar.ley): con la
# licencia (S.mar.lic), la distribuidora compra hasta MAR.legal.dia al día, sin calor y por el banco, y KAIA despacha más.

func obra_k(k: String) -> Dictionary:
	for O in D.MAR.get("obras", []):
		if O.k == k:
			return O
	return {}

func obras_muelle(N: String) -> void:
	var R: Dictionary = D.MAR
	var M_: Dictionary = S.mar
	if not (M_.get("ob") is Dictionary):
		M_.ob = {}
	while true:
		var it := []
		for O in R.obras:
			var r: String = K("hecha") if obra_ya(O.k) else (K("en obras") if M_.ob.has(O.k) else Datos.eur(O.p))
			var falta: String = T(" Antes, {o}.", {"o": obra_k(O.req).n}) if O.get("req") and not obra_ya(O.req) else ""
			it.append({"label": may1(O.n), "right": r, "desc": T(O.txt) + falta})
		it.append({"label": K("Nada")})
		var i: int = await menu(it, {"cls": "right", "title": K("Las obras del muelle"), "desc": true})
		if i < 0 or i >= R.obras.size():
			return
		var O: Dictionary = R.obras[i]
		if obra_ya(O.k):
			await say(T("{o} ya está como nueva.", {"o": may1(O.n)}), N)
			continue
		if M_.ob.has(O.k):
			await say(T("Los de la obra acaban {o} el {d}.", {"o": O.n, "d": Datos.fd(int(M_.ob[O.k]), S.day)}), N)
			continue
		if O.get("req") and not obra_ya(O.req):
			await say(T("Primero {o}. Sin eso, aquí no entra ni el camión.", {"o": obra_k(O.req).n}), N)
			continue
		if not await confirm(T("{o}: {p} por transferencia, {d} días de obra. ¿Adelante?", {"o": may1(O.n), "p": Datos.eur(O.p), "d": int(O.d)})):
			continue
		if not cobro_banco(float(O.p), T("Obra · {n}", {"n": O.n})):
			await say(K("En la cuenta no llega. Los de la obra cobran por adelantado."), N)
			continue
		M_.ob[O.k] = int(S.day) + int(O.d)
		sfx("coin")
		update_hud()
		await say(T("Mañana mismo empiezan con {o}. Acaban el {d}.", {"o": O.n, "d": Datos.fd(int(M_.ob[O.k]), S.day)}), N)

# al amanecer (mar_dia): las obras que acaban, los alquileres, lo que despacha KAIA y la ley
func obras_dia() -> void:
	var R: Dictionary = D.MAR
	var M_: Dictionary = S.mar
	if not R.has("obras") or not (M_.get("ob") is Dictionary):
		return
	if not (M_.get("oba") is Dictionary):
		M_.oba = {}
	var nueva := false
	for O in R.obras:
		if obra_ya(O.k) and not M_.oba.has(O.k):
			M_.oba[O.k] = int(S.day)
			nueva = true
			if O.k == "casas":
				M_.alq = int(S.day) + 7
			var t: String = T("Terminada {o}. {t}", {"o": O.n, "t": O.txt})
			queue("obra" + O.k, func(): await talk(K("SMS · KOLDO"), [t]))
	if nueva and S.map == "muelle":
		montar_muelle("muelle")
		build_ents()
	if obra_ya("casas") and int(S.day) >= int(M_.get("alq", 0)):
		abono_banco(float(obra_k("casas").alq), K("Alquileres · muelle"))
		M_.alq = int(S.day) + 7
	var L = M_.get("kaia")
	if L is Dictionary:
		var g = min(L.g, kaia_dia() * (D.VENTA_EXTR.dia if L.get("x") else 1.0) * kaia_tiron(L))
		var e := Datos.jsround(g * L.pg)
		L.g -= g
		L.tot += e
		if M_.get("lic"):
			abono_banco(e, K("KAIA · dispensario"))
		else:
			S.money += e
		S.sales += e
		queue("historia", check_story)
		if L.g < 1:
			M_.kaia = null
			var tot = L.tot
			queue("kaia", func(): await talk(K("SMS · KAIA"), [T("Se acabó lo del dispensario: {e} en total.", {"e": Datos.eur(tot)})]))
	if staff_ok():
		almacen_dia("muelle")   # MAESTRO [6]: el almacén de KAIA
	var LG: Dictionary = R.legal
	if M_.oba.has("club") and not M_.get("ley") and int(S.day) >= int(M_.oba.club) + int(LG.dias):
		M_.ley = int(S.day)
		queue("ley", func(): await talk(K("SMS · KOLDO"), [LG.txt, T("Ya es otra película, sobrino: con la licencia, {n} te compra hasta {kg} al día, sin patrulleras y por el banco. Ven a verme.", {"n": LG.n, "kg": _kg(int(LG.dia))})]))

func kaia_dia() -> float:
	return float(D.MAR.kaia.dia) * (float(D.MAR.legal.kaia) if S.mar.get("lic") else 1.0)

# el club KAIA, el tuyo: la encargada y el dispensario que llenas tú; MAESTRO [6], con el panel de la asociación
func talk_kaia(N: String) -> void:
	if staff_ok():
		await panel_club("muelle", N)
		return
	await dispensario_kaia(N)

func dispensario_kaia(N: String) -> void:
	if not (S.get("mar") is Dictionary):
		return
	var K: Dictionary = D.MAR.kaia
	var M_: Dictionary = S.mar
	var L = M_.get("kaia")
	if L is Dictionary:
		await gestiona_kaia(N)
		return
	var VX: Dictionary = D.VENTA_EXTR
	var lots := lotes_venta(K.g[0], VX.club_g[0])
	if lots.is_empty():
		await say(T("Bienvenido a KAIA. Aquí el dispensario lo llenas tú: déjame {g} g o más y los socios retiran {d} al día.", {"g": int(K.g[0]), "d": g_txt(kaia_dia())}), N)
		return
	var it := lots.map(venta_item)
	it.append({"label": T("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": T("¿Qué lote?")})
	if i < 0 or i >= lots.size():
		return
	var l: Array = lots[i]
	var x := es_extr(l)
	var k: String = l[0]
	var b: Dictionary = l[1]
	var pg := Datos.jsround((precio_extr(k, b.thc, "club") if x else precio_club(b.thc)) * calidad(b, not x) * float(K.f) * 100) / 100.0
	var ops := []
	for g in (VX.club_g if x else K.g):
		if g <= floor(b.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(g * pg)])
	o.append(T("Nada"))
	var j: int = await ask(T("{n} a {p} € el gramo para los socios. ¿Cuánto dejas?", {"n": venta_nombre(l), "p": _dos(pg)}), o, N)
	if j < 0 or j >= ops.size():
		return
	usa_lote(l, ops[j])
	M_.kaia = {"k": k, "g": ops[j], "pg": pg, "p0": pg, "thc": float(b.thc), "tot": 0}
	if x:
		M_.kaia.x = true
	sfx("sel")
	await say(T("Al dispensario. Cada mañana, {g} para los socios.", {"g": g_txt(kaia_dia() * (VX.dia if x else 1.0))}), N)

# lo que retiran los socios según el precio que pongas (lo pidió el usuario: «que actúes tú como encargado del dispensario»): al de la
# casa (p0), lo de siempre; más caro, menos, y más barato, más (MAR.kaia.precio: el paso y los topes)
func kaia_tiron(L: Dictionary) -> float:
	if not L.get("p0"):
		return 1.0
	return clampf(pow(float(L.p0) / float(L.pg), 2.0), .4, 1.6)

# el dispensario de KAIA, tuyo: lo que hay, rellenarlo con más del mismo lote, el precio y retirar lo que queda
func gestiona_kaia(N: String) -> void:
	var M_: Dictionary = S.mar
	var KP: Dictionary = D.MAR.kaia.precio
	while M_.get("kaia") is Dictionary:
		var L: Dictionary = M_.kaia
		var x := true if L.get("x") else false
		var nm_: String = extr_nombre(L.k, true) if x else lot_nombre(L.k)
		var dia: float = kaia_dia() * (D.VENTA_EXTR.dia if x else 1.0) * kaia_tiron(L)
		var mas := lotes_venta(1, 1).filter(func(l): return l[0] == L.k and es_extr(l) == x)
		var ops := [K("Rellenar"), K("Subir el precio"), K("Bajar el precio"), K("Retirar lo que queda"), K("Nada")]
		var c: int = await ask(T("Tu dispensario, jefe: {g} de {n} a {p} € el gramo. Salen unos {d} al día. Llevamos {e}.", {"g": g_txt(L.g), "n": nm_, "p": _dos(L.pg), "d": g_txt(dia), "e": Datos.eur(L.tot)}), ops, N)
		if c == 0:
			if mas.is_empty():
				await say(T("No llevas más {n}. Para cambiar de género, retira lo que queda y deja otro.", {"n": nm_}), N)
				continue
			var l: Array = mas[0]
			var b: Dictionary = l[1]
			var gs := []
			for g in (D.VENTA_EXTR.club_g if x else D.MAR.kaia.g):
				if g <= floor(b.g):
					gs.append(int(g))
			if gs.is_empty():
				gs.append(int(floor(b.g)))
			var o := gs.map(func(g): return "%d g" % g)
			o.append(K("Nada"))
			var j: int = await ask(T("¿Cuánta {n} más dejas? Llevas {g}.", {"n": nm_, "g": g_txt(b.g)}), o, N)
			if j < 0 or j >= gs.size():
				continue
			L.thc = (float(L.get("thc", b.thc)) * L.g + float(b.thc) * gs[j]) / (L.g + gs[j])
			usa_lote(l, gs[j])
			L.g += gs[j]
			sfx("sel")
		elif c == 1 or c == 2:
			var p0: float = float(L.get("p0", L.pg))
			L.p0 = p0
			var f: float = clampf(float(L.pg) / p0 + (float(KP.paso) if c == 1 else -float(KP.paso)), float(KP.min), float(KP.max))
			L.pg = Datos.jsround(p0 * f * 100) / 100.0
			sfx("sel")
		elif c == 3:
			if not await confirm(T("¿Te llevas los {g} de {n} que quedan?", {"g": g_txt(L.g), "n": nm_})):
				continue
			var thc: float = float(L.get("thc", strain(lot_sid(L.k)).thc))
			if x:
				add_rosin(L.k, L.g, thc)
			else:
				add_buds(L.k, L.g, thc)
			M_.kaia = null
			sfx("get")
			await say(K("Vaciado. El dispensario, a la espera de lo que traigas."), N)
			return
		else:
			return

# el diseño de KAIA (lo pidió el usuario: «el diseño y todo»): el suelo, las paredes y los muebles de uno de los estilos de los clubs,
# por MAR.kaia.dis.p y al día siguiente (S.mar.kd = estilo, S.mar.kdd = día); montar_club lo pone
func kaia_estilos() -> Array:
	return [["itsaso", K("Marinero")], ["kalea", K("De barrio")], ["fundicion", K("Industrial")], ["ensanche", K("Moderno")], ["", K("Clásico")]]

func kaia_estilo() -> String:
	var M_ = S.get("mar")
	if not (M_ is Dictionary) or not M_.has("kd") or int(S.day) < int(M_.get("kdd", 0)):
		return "itsaso"
	return String(M_.kd)

func diseno_kaia(N: String) -> void:
	var E := kaia_estilos()
	var ya := kaia_estilo()
	var it := []
	for e in E:
		it.append({"label": e[1], "right": K("el de ahora") if e[0] == ya else Datos.eur(D.MAR.kaia.dis.p), "disabled": e[0] == ya})
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("KAIA · el diseño")})
	if i < 0 or i >= E.size() or E[i][0] == ya:
		return
	if not await confirm(T("Suelo, paredes y muebles {e}: {p} por transferencia, listo mañana. ¿Adelante?", {"e": E[i][1].to_lower(), "p": Datos.eur(D.MAR.kaia.dis.p)})):
		return
	if not cobro_banco(float(D.MAR.kaia.dis.p), K("KAIA · reforma")):
		await say(K("En la cuenta no llega para la reforma."), N)
		return
	S.mar.kd = E[i][0]
	S.mar.kdd = int(S.day) + 1
	sfx("get")
	await say(K("Mañana lo verás cambiado. Los socios ya están preguntando."), N)

# la licencia, cuando ya hay ley
func licencia_mar(N: String) -> void:
	var LG: Dictionary = D.MAR.legal
	if not await confirm(T("La licencia de cultivo y distribución: {p} por transferencia. Con ella, {n} te compra hasta {kg} al día, sin calor. ¿La sacas?", {"p": Datos.eur(LG.lic), "n": LG.n, "kg": _kg(int(LG.dia))})):
		return
	if not cobro_banco(float(LG.lic), K("Licencia · cannabis")):
		await say(K("En la cuenta no llega. El ministerio no fía."), N)
		return
	S.mar.lic = int(S.day)
	sfx("get")
	await say(K("Con papeles. Treinta años escondiéndonos y ahora te dan un sello. Maite se partiría de risa."), N)

# la distribuidora legal: hasta MAR.legal.dia al día, por el banco y sin calor
func vender_legal(N: String) -> void:
	var LG: Dictionary = D.MAR.legal
	var M_: Dictionary = S.mar
	if int(M_.get("lgd", -1)) != int(S.day):
		M_.lgd = int(S.day)
		M_.lgg = 0
	var resto: int = int(LG.dia) - int(M_.lgg)
	if resto < 100:
		await say(T("Por hoy, {n} no quiere más. Mañana, otros {kg}.", {"n": LG.n, "kg": _kg(int(LG.dia))}), N)
		return
	var lots := bud_lots(100)
	if lots.is_empty():
		await say(T("{n} compra de 100 g para arriba, en cogollo curado o sin curar.", {"n": LG.n}), N)
		return
	var it := lots.map(venta_item)
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": T("{n} · hoy, hasta {kg}", {"n": LG.n, "kg": _kg(resto)})})
	if i < 0 or i >= lots.size():
		return
	var l: Array = lots[i]
	var g = await cuanto(T("¿Cuánto de {n}?", {"n": lot_nombre(l[0])}), mini(int(floor(l[1].g)), resto), [100, 250, 500, 1000, 2000, 5000], func(v): return _kg(int(v)))
	if g <= 0:
		return
	var e := Datos.jsround(precio_mayor(float(l[1].thc)) * calidad(l[1], true) * float(LG.f) * int(g))
	use_buds(l[0], int(g))
	M_.lgg = int(M_.lgg) + int(g)
	abono_banco(e, T("Venta · {n}", {"n": LG.n}))
	S.sales += e
	sfx("coin")
	update_hud()
	queue("historia", check_story)
	await say(T("{kg} de {l}, con factura: {e} a la cuenta.", {"kg": _kg(int(g)), "l": lot_nombre(l[0]), "e": Datos.eur(e)}), N)

# las cifras de una cerradura de teclado (siempre las mismas para cada cosa y cada partida)
func cifras_acceso(k: String) -> String:
	return "%04d" % (absi(("%s|%s" % [S.name, k]).hash()) % 10000)

# cuándo acaba cada parte: [la llave entra o la tarjeta, la primera cifra, la última cifra, el clic, el final]
func tiempos_acceso(V: Dictionary) -> Dictionary:
	var k: String = V.k
	if GESTOS.has(k):   # 1.54
		return {"fin": float(GESTOS[k])}
	var n: int = maxi(1, str(V.c).length())
	match k:
		"llave", "candado":
			return {"entra": 420.0, "gira": 760.0, "fin": 1000.0}
		"clave":
			return {"t1": 150.0, "clic": 150.0 + n * ACC_TECLA + 60, "fin": 150.0 + n * ACC_TECLA + 360}
		"pin":
			return {"entra": 400.0, "t1": 450.0, "clic": 450.0 + n * ACC_TECLA + 60, "fin": 450.0 + n * ACC_TECLA + 360}
		"rueda":
			return {"para": 350.0, "cada": 220.0, "clic": 350.0 + (n - 1) * 220 + 60, "fin": 350.0 + (n - 1) * 220 + 400}
	return {"fin": 600.0}

func acceso(k: String, c := "", ok := true) -> void:
	if not Datos.CAL:
		return
	if gancho_acceso.is_valid():
		gancho_acceso.call(k, c, ok)
		return
	var V := {"k": k, "c": c, "ok": ok, "t0": M.reloj}
	var T := tiempos_acceso(V)
	var pr := Motor.Prom.new()
	var st := {"fuera": false}
	var cierra := func():
		if not st.fuera:
			st.fuera = true
			pop()
		pr.res(0)
	var suena := func(ms: float, s: String):
		M.timeout(func():
			if not pr.listo:
				sfx(s), ms)
	match k:
		"llave", "candado":
			suena.call(T.entra, "tick")
			suena.call(T.gira, "llave")
		"clave", "pin":
			for i in str(c).length():
				suena.call(T.t1 + i * ACC_TECLA, "tecla")
			suena.call(T.clic, "sel" if ok else "bad")
		"rueda":
			for i in str(c).length():
				suena.call(T.para + i * T.cada, "tick")
			suena.call(T.clic, "llave" if ok else "clac")
	ACCESO_V = V
	push(func(b: String):
		if b == "A" or b == "B":
			cierra.call())
	M.timeout(cierra, T.fin + 250)
	await Motor.espera(pr)
	ACCESO_V = null

func _glifo(R: Array, ch: String, x: int, y: int, s: int, col: String) -> void:
	var g: String = ACC_GLIFO.get(ch, "")
	var w: int = 5 if g.length() == 25 else 3
	if w == 5:
		x -= s
	for i in g.length():
		if g[i] == "1":
			R.append([x + (i % w) * s, y + (i / w) * s, s, s, col])

# los rectángulos [x, y, w, h, color] del momento t (ms desde que empezó)
func rects_acceso(V: Dictionary, now: float) -> Array:
	var R := []
	var t: float = now - float(V.t0)
	var T := tiempos_acceso(V)
	var x0: int = (SW - ACC_W) >> 1
	var y0: int = (SH - ACC_H) >> 1
	var cx: int = x0 + (ACC_W >> 1)
	var cy: int = y0 + (ACC_H >> 1)
	var k: String = V.k
	var c: String = str(V.c)
	if GESTOS.has(k):   # 1.54: el plano de detalle de cada acción; 1.54.1, de sprites, a 144 × 96
		_gs = Rect2i((SW - GS_W) >> 1, (SH - GS_H) >> 1, GS_W, GS_H)
		R.append([_gs.position.x - 2, _gs.position.y - 2, GS_W + 4, GS_H + 4, "#26262e"])
		_gesto_rects(R, V, t)
		return R
	R.append([x0 - 2, y0 - 2, ACC_W + 4, ACC_H + 4, "#26262e"])
	match k:
		"llave":   # la puerta de madera, el escudo de latón y la llave que entra por la derecha y gira
			R.append([x0, y0, ACC_W, ACC_H, "#6a4a30"])
			for xx in range(x0 + 11, x0 + ACC_W, 12):
				R.append([xx, y0, 1, ACC_H, "#5a3c26"])
			R.append([cx - 8, cy - 22, 16, 44, "#b08a3a"])
			R.append([cx - 8, cy - 22, 16, 1, "#d8b860"])
			R.append([cx - 8, cy - 22, 1, 44, "#d8b860"])
			R.append([cx - 8, cy + 21, 16, 1, "#7a5a20"])
			R.append([cx + 7, cy - 22, 1, 44, "#7a5a20"])
			R.append([cx - 5, cy - 18, 10, 6, "#8a6a28"])   # el pomo, encima
			R.append([cx - 3, cy - 6, 6, 5, "#101010"])
			R.append([cx - 1, cy - 2, 2, 7, "#101010"])
			_llave_h(R, t, T, cx, cy, Rect2i(cx + 3, y0, x0 + ACC_W - cx - 3, ACC_H))
		"candado":   # la persiana de chapa y el candado: la llave sube por debajo, gira y salta el arco
			R.append([x0, y0, ACC_W, ACC_H, "#7a7e86"])
			for yy in range(y0 + 3, y0 + ACC_H, 5):
				R.append([x0, yy, ACC_W, 1, "#5e626a"])
			R.append([x0, cy - 6, ACC_W, 4, "#9a9ea6"])   # el pasador
			var lift: int = Datos.jsround(_suave((t - T.gira) / 160.0) * 6) if V.ok else 0
			R.append([cx - 8, cy - 15 - lift, 16, 3, "#b8bcc4"])
			R.append([cx - 8, cy - 15 - lift, 3, 13, "#b8bcc4"])
			R.append([cx + 5, cy - 15 - lift, 3, 13 + (lift if lift else 0), "#b8bcc4"])
			R.append([cx - 7, cy - 15 - lift, 1, 13, "#e0e4ec"])
			R.append([cx - 10, cy - 2, 20, 18, "#c09838"])
			R.append([cx - 10, cy - 2, 20, 2, "#e0c060"])
			R.append([cx - 10, cy + 14, 20, 2, "#806020"])
			R.append([cx - 1, cy + 7, 3, 5, "#101010"])
			_llave_v(R, t, T, cx, cy, Rect2i(x0, cy + 12, ACC_W, y0 + ACC_H - cy - 12))
		"clave", "pin":
			_teclado(R, V, t, T, cx, y0 + (14 if k == "pin" else 6))
		"rueda":   # la puerta de la caja: cuatro ruedas que se paran en su cifra y la manilla que gira
			R.append([x0, y0, ACC_W, ACC_H, "#3a4048"])
			R.append([x0 + 5, y0 + 5, ACC_W - 10, ACC_H - 10, "#5a6068"])
			R.append([x0 + 5, y0 + 5, ACC_W - 10, 1, "#7a8088"])
			R.append([x0 + 5, y0 + 5, 1, ACC_H - 10, "#7a8088"])
			var n := c.length()
			var wx: int = cx - (n * 16 - 4) / 2
			for i in n:
				var para: float = T.para + i * T.cada
				var d: int = int(c[i])
				if t < para:
					d = (d + int((para - t) / 60.0) + 1) % 10
				R.append([wx + i * 16, cy - 22, 12, 16, "#101418"])
				R.append([wx + i * 16, cy - 22, 12, 1, "#000000"])
				_glifo(R, str(d), wx + i * 16 + 3, cy - 19, 2, "#e8e0c0" if t >= para else "#a09880")
			var led: String = "#c03030"
			if t >= T.clic:
				led = "#40e060" if V.ok else ("#ff4040" if int(t / 120.0) % 2 == 0 else "#601010")
			R.append([x0 + ACC_W - 16, y0 + 10, 5, 5, led])
			var gi: float = _suave((t - T.clic) / 220.0) if V.ok else 0.0
			var mx: int = cx + (Datos.jsround(sin(t / 30.0)) if not V.ok and t >= T.clic and t < T.clic + 300 else 0)
			R.append([mx - 5, cy + 6, 10, 10, "#a0a4ac"])
			R.append([mx - 3, cy + 8, 6, 6, "#7a8088"])
			if gi < .34:   # la manilla, de pie
				R.append([mx - 1, cy - 1, 3, 24, "#c8ccd4"])
			elif gi < .67:   # en diagonal
				for q in 6:
					R.append([mx - 8 + q * 3, cy + 18 - q * 3, 3, 3, "#c8ccd4"])
			else:   # tumbada: abierta
				R.append([mx - 12, cy + 10, 24, 3, "#c8ccd4"])
			# el dedo: en la rueda que se está parando y, al final, en la manilla
			if t < T.clic:
				_dedo(R, wx + clampi(floori((t - T.para) / T.cada) + 1, 0, n - 1) * 16 + 6, cy - 4)
			else:
				_dedo(R, mx + 4, cy + 14)
	if (k == "llave" or k == "candado") and t >= T.gira and t < T.gira + 220:   # el clic
		var py: int = cy - 4 if k == "llave" else cy + 9
		for q in [[-8, 0, 3, 1], [6, 0, 3, 1], [0, -8, 1, 3], [0, 6, 1, 3], [-6, -6, 2, 2], [5, -6, 2, 2]]:
			R.append([cx + q[0], py + q[1], q[2], q[3], "#f8e070"])
	return R

# 0.55 (lo pidió el usuario: «la llave… flotan»): la mano de PixelLab con la llave, la manga por el canto derecho del panel; entra
# por el bombín (lo de dentro, recortado: cl empieza a la derecha del ojo de la cerradura) y gira (acc-llave-1, la muñeca de canto)
func _llave_h(R: Array, t: float, T: Dictionary, cx: int, cy: int, cl: Rect2i) -> void:
	var kx: int = cx - 14 + Datos.jsround((1 - _suave(t / T.entra)) * 34)
	if t < T.entra + (T.gira - T.entra) * 0.5:
		R.append(["@", "acc-llave-0", kx, cy - 21, cl])
	else:
		R.append(["@", "acc-llave-1", kx, cy - 22, cl])

# la del candado, la misma mano girada: sube por debajo del ojo (cl empieza debajo) y gira
func _llave_v(R: Array, t: float, T: Dictionary, cx: int, cy: int, cl: Rect2i) -> void:
	var ky: int = cy + 3 + Datos.jsround((1 - _suave(t / T.entra)) * 20)
	R.append(["@", "acc-llave-v0" if t < T.entra + (T.gira - T.entra) * 0.5 else "acc-llave-v1", cx - 7, ky, cl])

# el dedo de PixelLab (acc-dedo: la yema en (2, 0), la manga por abajo a la derecha) en (x, y)
func _dedo(R: Array, x: float, y: float) -> void:
	var x0: int = (SW - ACC_W) >> 1
	var y0: int = (SH - ACC_H) >> 1
	R.append(["@", "acc-dedo", Datos.jsround(x) - 2, Datos.jsround(y), Rect2i(x0, y0, ACC_W, ACC_H)])

# el teclado: pantalla con asteriscos, el piloto y 12 teclas; con la tarjeta (pin), la ranura arriba
func _teclado(R: Array, V: Dictionary, t: float, T: Dictionary, cx: int, ty: int) -> void:
	var x0: int = (SW - ACC_W) >> 1
	var y0: int = (SH - ACC_H) >> 1
	R.append([x0, y0, ACC_W, ACC_H, "#4a4e56" if V.k == "pin" else "#8a7e6a"])
	R.append([cx - 24, ty, 48, 62, "#d0d0c8"])
	R.append([cx - 24, ty, 48, 1, "#f0f0e8"])
	R.append([cx - 24, ty + 61, 48, 1, "#909088"])
	var c: String = str(V.c)
	if V.k == "pin":   # la tarjeta entra por la ranura
		var vis: int = Datos.jsround(14 - _suave(t / T.entra) * 11)
		R.append([cx - 14, ty + 1, 28, 2, "#101010"])
		R.append([cx - 12, ty + 1 - vis, 24, vis, "#3070c0"])
		if vis > 6:
			R.append([cx - 8, ty + 1 - vis + 2, 5, 4, "#d0b040"])
	R.append([cx - 20, ty + 5, 32, 11, "#183018"])
	var hechas: int = clampi(int(floor((t - T.t1) / ACC_TECLA)) + 1, 0, c.length()) if t >= T.t1 else 0
	for i in hechas:
		_glifo(R, "·", cx - 18 + i * 6, ty + 9, 1, "#80f080")
	var led: String = "#c03030"
	if t >= T.clic:
		led = "#40e060" if V.ok else ("#ff4040" if int(t / 120.0) % 2 == 0 else "#601010")
	R.append([cx + 15, ty + 8, 5, 5, led])
	var pulsa := ""
	if t >= T.t1 and t < T.t1 + c.length() * ACC_TECLA and fmod(t - T.t1, ACC_TECLA) < 150:
		pulsa = c[int((t - T.t1) / ACC_TECLA)]
	var teclas := "123456789*0#"
	for i in 12:
		var bx: int = cx - 19 + (i % 3) * 14
		var by: int = ty + 20 + (i / 3) * 10
		var ch: String = teclas[i]
		var p: bool = ch == pulsa
		R.append([bx, by + (1 if p else 0), 11, 8, "#58d080" if p else "#b8b8c0"])
		if not p:
			R.append([bx, by + 7, 11, 1, "#80808a"])
		_glifo(R, ch, bx + 4, by + 2 + (1 if p else 0), 1, "#303038")
	# el dedo: en la tecla que toca (bajado al pulsar), entre una y otra encima de la siguiente y, al acabar, abajo a la derecha
	var n: int = c.length()
	var ix: int = clampi(int((t - T.t1) / ACC_TECLA), 0, n - 1) if t >= T.t1 else 0
	if n > 0 and t < T.clic:
		var ti: int = teclas.find(c[ix])
		var pul: bool = t >= T.t1 and fmod(t - T.t1, ACC_TECLA) < 150
		_dedo(R, cx - 19 + (ti % 3) * 14 + 5, ty + 20 + (ti / 3) * 10 + (3 if pul else -2))
	else:
		_dedo(R, cx + 22, ty + 48)

func gesto(k: String, o := {}) -> void:
	var gp = gesto_p
	var gsid := gesto_sid
	gesto_p = null
	gesto_sid = ""
	if not Datos.CAL or not GESTOS.has(k):
		return
	var pl := gesto_planta(gp, gsid)
	if gancho_acceso.is_valid():
		gancho_acceso.call(k, str(o.get("m", "")), true)
		if gancho_gesto.is_valid():
			gancho_gesto.call(k, pl)
		return
	var V := {"k": k, "c": str(o.get("m", "")), "ok": true, "t0": M.reloj, "pl": pl, "tab": bool(o.get("tab", false))}
	var pr := Motor.Prom.new()
	var st := {"fuera": false}
	var cierra := func():
		if not st.fuera:
			st.fuera = true
			pop()
		pr.res(0)
	for s in GESTO_SON.get(k, []):
		var nm_: String = s[1]
		M.timeout(func():
			if not pr.listo:
				sfx(nm_), float(s[0]))
	ACCESO_V = V
	push(func(b: String):
		if b == "A" or b == "B":
			cierra.call())
	M.timeout(cierra, float(GESTOS[k]) + 200)
	await Motor.espera(pr)
	ACCESO_V = null

var gancho_gesto := Callable()   # (tipo, pl) · las pruebas miran la planta del gesto

# la planta del gesto (lo pidió el usuario: «que salga tal y como está la planta»): la de la vista C de su carpa (img: su fotograma de
# su alto, con los colores de su variedad, los daños y seca sin agua; la muerta, en marrones) y sus colores (cog, hoja) para la cola y
# las genéricas; con solo la variedad (sid: la mesa de manicurar, la de cruces), solo los colores
func gesto_planta(p, sid: String) -> Dictionary:
	var o := {}
	if p is Dictionary:
		o.cog = Datos.color_cog(S, p)
		o.hoja = Datos.hoja_planta(S, p)
		var i := -1
		for j in S.pots.size():
			if is_same(S.pots[j], p):
				i = j
		if i < 0:
			return o
		o.i = i
		var g = VistaC.geo(S, Cultivo.huecos(S)[i].c)
		if g == null or VistaC.vista_c(S, g) == null:
			return o
		for q in g.pl:
			if q.i == i and q.v.p != null:
				var A = VistaC.Arte
				if q.v.muerta:
					o.img = A.recolor(A.aplasta(A.altura(q.v.p.n, q.v.hp)[1], q.v.hp), D.VC_SECA)
				else:
					o.img = VistaC.img_planta(S, p, q.v)
	elif sid != "" and strain(sid):
		o.cog = String(strain(sid).c)
		o.hoja = Datos.hoja_de(S, sid)
	return o

# los verdes de los sprites del gesto (gestos.py) a los de la variedad: el cogollo de la planta genérica (la rampa clave, en verde) y el
# de la cola (COG), y las hojas de la cola (HOJA)
const GS_COG := {"#4e7a2e": -60, "#86b44e": 0, "#c2e088": 50, "#4a6a2a": -60, "#6a8e3a": -30, "#8ab456": 0, "#b4d47c": 50}
const GS_HOJA := {"#1e3a1a": -70, "#2f5a26": -45, "#4f8a3a": -10, "#78b450": 25, "#a8d878": 55}
var _gs_col := {}

func _gs_color(n: String, pl: Dictionary) -> Image:
	var f = Atlas.foto_misc(n)
	if f == null or not pl.has("cog"):
		return f.c if f else null
	var k := "%s|%s|%s" % [n, pl.cog, pl.hoja]
	if not _gs_col.has(k):
		if _gs_col.size() > 64:
			_gs_col.clear()
		var m := {}
		for c in GS_COG:
			m[c] = Datos.shade(pl.cog, GS_COG[c]) if GS_COG[c] else pl.cog
		for c in GS_HOJA:
			m[c] = Datos.shade(pl.hoja, GS_HOJA[c])
		if n.begins_with("gs-planta"):
			m.merge(Datos.vc_tonos(pl.hoja), true)
		_gs_col[k] = VistaC.Arte.recolor(f.c, m)
	return _gs_col[k]

# un sprite del gesto con los colores de la planta (si los hay)
func _gspc(R: Array, n: String, x: float, y: float, V: Dictionary) -> void:
	var pl: Dictionary = V.get("pl", {})
	if not pl.has("cog"):
		_gsp(R, n, x, y)
		return
	var im = _gs_color(n, pl)
	if im:
		R.append(["@", im, _gs.position.x + Datos.jsround(x), _gs.position.y + Datos.jsround(y), _gs])

func _gsp(R: Array, n: String, x: float, y: float) -> void:
	R.append(["@", n, _gs.position.x + Datos.jsround(x), _gs.position.y + Datos.jsround(y), _gs])

# 0.56 (lo pidió el usuario: «molaría que la vista sea POV»): la mano de PixelLab, en primera persona, en (x, y) y la manga alargada
# hasta el canto con su misma inclinación: la tuya, hacia la esquina de abajo a la derecha (la del mechero, -ab, a la izquierda); la del
# cliente, -i, hacia la de arriba a la izquierda. Fila a fila, el corte entero de la manga corrido lo que se corre la manga: nunca flota
func _gsm(R: Array, n: String, x: float, y: float) -> void:
	_gsp(R, n, x, y)
	var f = Atlas.foto_misc(n)
	if f == null:
		return
	var w: int = f.c.get_width()
	var M: Array = _gs_manga(n, f.c)   # [fila, x0, x1, pendiente]
	var X: int = _gs.position.x + Datos.jsround(x)
	var Y: int = _gs.position.y + Datos.jsround(y)
	var arriba: bool = n.ends_with("-i")
	var ys: int = M[0]
	var lejos: int = (Y + ys - _gs.position.y) if arriba else (_gs.end.y - 1 - (Y + ys))
	if lejos <= 0:
		return
	if not arriba:   # la tuya, en perspectiva: el antebrazo se ensancha hacia el canto (más cerca de los ojos), en una imagen
		var B: Array = _gs_brazo(n, f.c, M, lejos)   # [imagen, x de su esquina respecto a X]
		R.append(["@", B[0], X + B[1], Y + ys + 1, _gs, n])
		return
	for k in range(1, lejos + 1):
		var fy: int = Y + ys + (-k if arriba else k)
		var dx: int = Datos.jsround(M[3] * k)
		var r := Rect2i(X + dx + M[1], fy, M[2] - M[1] + 1, 1).intersection(_gs)
		if r.size.x <= 0:
			break
		R.append(["@", n, X + dx, fy - ys, r])

# el antebrazo visto en perspectiva (lo pidió el usuario: «más cortos y anchos hacia abajo»): fila a fila desde el corte de la manga
# hasta el canto, corrido con su pendiente y cada vez más ancho (GS_BRAZO px por fila); la fila de la manga se estira por dentro y
# los cantos de 1 px (el contorno) se quedan
const GS_BRAZO := 0.7
var _gs_br := {}
func _gs_brazo(n: String, im: Image, M: Array, lejos: int) -> Array:
	var key := "%s|%d" % [n, lejos]
	if _gs_br.has(key):
		return _gs_br[key]
	if _gs_br.size() > 64:
		_gs_br.clear()
	var ys: int = M[0]
	var x0: int = M[1]
	var w0: int = M[2] - M[1] + 1
	var fila := []
	for i in w0:
		fila.append(im.get_pixel(x0 + i, ys))
	var lo := 1 << 20
	var hi := -(1 << 20)
	var L := []
	for k in range(1, lejos + 1):
		var wk: int = w0 + int(GS_BRAZO * k)
		var c: float = x0 + w0 / 2.0 + M[3] * k
		var a: int = int(floor(c - wk / 2.0))
		L.append([a, wk])
		lo = mini(lo, a)
		hi = maxi(hi, a + wk)
	var out := Image.create(maxi(1, hi - lo), maxi(1, lejos), false, Image.FORMAT_RGBA8)
	for k in L.size():
		var a: int = L[k][0]
		var wk: int = L[k][1]
		for i in wk:
			var j: int = 0 if i == 0 else (w0 - 1 if i == wk - 1 else clampi(1 + int((i - 1) * (w0 - 2) / float(maxi(1, wk - 2))), 1, w0 - 2))
			out.set_pixel(a - lo + i, k, fila[j])
	_gs_br[key] = [out, lo]
	return _gs_br[key]

# el corte de la manga: la fila (de las 20 del canto) donde ya es entera, el tramo de esa fila que es manga (el del lado de su esquina:
# el derecho la tuya, el izquierdo la del mechero y la del cliente) y lo que se corre en x por cada fila hacia fuera
var _gs_mg := {}
func _gs_manga(n: String, im: Image) -> Array:
	if _gs_mg.has(n):
		return _gs_mg[n]
	var w: int = im.get_width()
	var h: int = im.get_height()
	var arriba: bool = n.ends_with("-i")
	var der: bool = not arriba and not n.ends_with("-ab")
	var tramo := func(fy: int) -> Array:   # [x0, x1] del tramo pegado a la esquina
		var xs: Array = range(w - 1, -1, -1) if der else range(w)
		var a := -1
		var b := -1
		for i in xs:
			if im.get_pixel(i, fy).a > 0.5:
				if a < 0:
					a = i
				b = i
			elif a >= 0:
				break
		return [mini(a, b), maxi(a, b)] if a >= 0 else [0, -1]
	var filas: Array = []
	for k in mini(20, h):
		filas.append(k if arriba else h - 1 - k)
	var ancho := 0
	for fy in filas:
		var t: Array = tramo.call(fy)
		ancho = maxi(ancho, t[1] - t[0] + 1)
	var ys: int = filas[0]
	for fy in filas:
		var t: Array = tramo.call(fy)
		if t[1] - t[0] + 1 >= ancho * 0.9:
			ys = fy
			break
	var t0: Array = tramo.call(ys)
	var yi: int = clampi(ys + (8 if arriba else -8), 0, h - 1)
	var t1: Array = tramo.call(yi)
	var sl: float = ((t0[0] + t0[1]) - (t1[0] + t1[1])) / 2.0 / maxf(1.0, absf(ys - yi))
	_gs_mg[n] = [ys, t0[0], t0[1], sl]
	return _gs_mg[n]

func _gsr(R: Array, x: float, y: float, w: int, h: int, c: String) -> void:
	var r := Rect2i(_gs.position.x + Datos.jsround(x), _gs.position.y + Datos.jsround(y), w, h).intersection(_gs)
	if r.size.x > 0 and r.size.y > 0:
		R.append([r.position.x, r.position.y, r.size.x, r.size.y, c])

# la maceta en dos capas (lo pidió el usuario: «partir la maceta en dos, la trasera y delantera»): el canto de atrás y la tierra
# (filas 0-7 del sprite, en (40, 60)) detrás de la planta y el canto de delante y el cuerpo (de la 8 abajo) delante
const GS_MAC_CORTE := 8
func _gs_mac(R: Array, n: String, delante: bool) -> void:
	var y: int = _gs.position.y + 60 + GS_MAC_CORTE
	var c := Rect2i(_gs.position.x, y, _gs.size.x, _gs.end.y - y) if delante else Rect2i(_gs.position.x, _gs.position.y, _gs.size.x, y - _gs.position.y)
	R.append(["@", n, _gs.position.x + 40, _gs.position.y + 60, c])

# la maceta de tela con su planta (v: vegetativa, f: en flor, "": sin planta) en el suelo de la carpa; con la planta del gesto, la de
# verdad (su fotograma de la vista C, con el pie en la tierra de la maceta: las macetas de la vista C miden lo mismo que esta) o, sin ella,
# la genérica con sus colores
func _gs_maceta(R: Array, pl: String, moja := false, V := {}) -> void:
	var n: String = "gs-maceta-m" if moja else "gs-maceta"
	_gs_mac(R, n, false)
	var gp: Dictionary = V.get("pl", {})
	if gp.has("img"):
		var im: Image = gp.img
		R.append(["@", im, _gs.position.x + 56 - (im.get_width() >> 1), _gs.position.y + 67 - im.get_height(), _gs])
	elif pl != "":
		_gspc(R, "gs-planta-" + pl, 36, -29, V)
	_gs_mac(R, n, true)

func _gesto_rects(R: Array, V: Dictionary, t: float) -> void:
	var k: String = V.k
	var c: String = str(V.c)
	match k:
		"regar":   # la regadera entra, se inclina y el agua cae del pitorro a la tierra, que se oscurece
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "v", t > 600, V)
			# 0.56: en primera persona, tu brazo desde la esquina de abajo a la derecha y la alcachofa (0, 25) encima de la tierra
			var e: float = _mv(70, 0, t / 300.0) if t < 1000 else _mv(0, 70, (t - 1000) / 200.0)
			var x: float = 58 + e
			var y: float = 18 + e + (sin((t - 300) / 140.0) if t > 300 and t < 1000 else 0.0)
			if t > 320 and t < 1000:   # el chorro de la alcachofa (x, y + 27) a la tierra de la maceta (fila 64)
				for d in 12:
					var f: float = fmod((t - 320) / 260.0 + d / 12.0, 1.0)
					_gsr(R, x - f * 3 + (d % 3), y + 27 + f * (64 - y - 27), 1, 2, "#8ac8f8" if d % 2 else "#5aa0e0")
			_gsm(R, "gm-regar", x, y)
		"tratar":   # el pulverizador en la mano: dos apretones, la bruma hacia la planta y los bichos que caen
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "v", false, V)
			for i in 3:
				if t < 650 + i * 120:
					_gsp(R, "gs-bicho", [46, 60, 42][i], [26, 38, 46][i])
			var apr: bool = (t > 250 and t < 450) or (t > 600 and t < 800)
			var e: float = _mv(70, 0, t / 220.0) if t < 1000 else _mv(0, 70, (t - 1000) / 200.0)
			_gsm(R, "gm-spray", 72 + e, 20 + e + (1 if apr else 0))   # la boquilla en (0, 2)
			for p in [250.0, 600.0]:
				var f: float = (t - p) / 500.0
				if f > 0 and f < 1:
					_gsp(R, "gs-bruma-%d" % mini(2, int(f * 3)), 70 - f * 24, 23 + f * 6)
		"abonar":   # la mano trae la botella, la inclina sobre la maceta y el chorro ámbar cae a la tierra
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "v", false, V)
			var e: float = _mv(70, 0, t / 250.0) if t < 1000 else _mv(0, 70, (t - 1000) / 200.0)
			if t > 300 and t < 1000:   # del tapón (0, 15) a la tierra (fila 64)
				var largo: int = mini(12, int((t - 300) / 20.0))
				_gsr(R, 51, 52, 1, largo, "#d89a3a")
				_gsr(R, 52, 53, 1, maxi(0, largo - 2), "#a86a1a")
			_gsm(R, "gm-abono", 51 + e, 27 + e)   # el tapón en (1, 25)
		"plantar":   # la plántula baja a la maceta, la mano aprieta la tierra; 1.57.2: dentro de la maceta, delante del canto de atrás
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_mac(R, "gs-maceta", false)
			_gsp(R, "gs-brote", 36, _mv(-90, -28, t / 600.0))
			if t > 600:   # la tierra alrededor del tallo
				for i in 6:
					_gsr(R, 49 + i * 3 + (1 if i > 2 else 0), 67 + (i % 2), 2, 1, "#3e2c1e" if i % 2 else "#56402a")
			_gs_mac(R, "gs-maceta", true)
			if t > 650:   # los dedos (2, 10) aprietan la tierra junto al tallo
				var e: float = _mv(60, 0, (t - 650) / 150.0)
				_gsm(R, "gm-vacia", 58 + e, 52 + e + (Datos.jsround(sin((t - 800) / 90.0) * 2) if t > 800 else 0))
		"sembrar":   # 1.57.2 (lo pidió el usuario: «sería mejor echar una semilla al sembrar»): la mano trae la semilla entre los dedos,
			# la suelta, cae a la tierra y la mano la tapa
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_mac(R, "gs-maceta", false)
			if t >= 420 and t < 900:
				_gsp(R, "gs-semilla", 51, _mv(48, 62, (t - 420) / 200.0))
			if t > 900:   # tapada: un montoncito de tierra
				_gsr(R, 53, 66, 5, 1, "#56402a")
				_gsr(R, 52, 67, 7, 1, "#3e2c1e")
			_gs_mac(R, "gs-maceta", true)
			if t < 420:   # la semilla en (7, 18) de la mano
				var e: float = _mv(70, 0, t / 400.0)
				_gsm(R, "gm-semilla", 44 + e, 30 + e)
			elif t < 820:   # los dedos (2, 10), abiertos donde estaba la semilla, y se va
				var e: float = _mv(0, 70, (t - 600) / 200.0) if t > 600 else 0.0
				_gsm(R, "gm-vacia", 49 + e, 38 + e)
			elif t < 1150:
				_gsm(R, "gm-vacia", 51, 52 + Datos.jsround(sin((t - 820) / 90.0) * 2))
		"esqueje":   # las tijeras en la mano cortan una rama y el esqueje va al vaso de agua
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "v", false, V)
			_gsp(R, "gs-vaso", 104, 62)
			if t < 500:   # la punta en (0, 5)
				var e: float = _mv(70, 0, t / 300.0)
				_gsm(R, "gm-tij-c" if t > 420 else "gm-tij-a", 62 + e, 31 + e)
			else:
				var f: float = (t - 500) / 500.0
				_gspc(R, "gs-esqueje", _mv(56, 102, f), _mv(26, 48, f) - sin(clampf(f, 0, 1) * PI) * 10, V)
				_gsm(R, "gm-tij-c", 62 + _mv(0, 70, f), 31 + _mv(0, 70, f))
		"cosechar":   # las tijeras cortan la cola de arriba y se la llevan
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "f", false, V)
			if t < 500:
				var e: float = _mv(70, 0, t / 300.0)
				_gsm(R, "gm-tij-c" if t > 420 else "gm-tij-a", 56 + e, 13 + e)
			else:
				var f: float = (t - 500) / 600.0
				_gspc(R, "gs-cola", _mv(40, 100, f), _mv(2, 8, f) - sin(clampf(f, 0, 1) * PI) * 6, V)
				_gsm(R, "gm-tij-c", 56 + _mv(0, 70, f), 13 + _mv(0, 70, f))
		"manicurar":   # la cola en la mesa, cuatro tijeretazos, las hojitas caen y queda pelada
			_gsp(R, "gs-f-mesa", 0, 0)
			_gspc(R, "gs-cola-p" if t > 650 else "gs-cola", 56, 34, V)
			var P := [[78, 36], [34, 44], [80, 50], [32, 32]]
			for i in 4:
				var ts: float = 250 + i * 250
				if t > ts:
					_gspc(R, "gs-hojita", P[i][0] + 2 - i, minf(74, P[i][1] + 8 + (t - ts) * .08), V)
			var j: int = clampi(int((t - 125) / 250.0), 0, 3)
			var cerr: bool = absf(t - (250 + j * 250)) < 60
			_gsm(R, "gm-tij-c" if cerr else "gm-tij-a", P[j][0], P[j][1] - 5)
		"polen":   # el pincel en la mano da vueltas sobre la cola de arriba y suelta el polen
			_gsp(R, "gs-f-carpa", 0, 0)
			_gs_maceta(R, "f", false, V)
			for i in 10:
				var ti: float = 150 + i * 90
				if t > ti:
					_gsr(R, 48 + (i * 7) % 16, minf(60, 28 + (t - ti) * .03 + (i % 3)), 1, 1, "#f0d040" if i % 2 else "#e0b020")
			var ex: float = minf(1.0, t / 200.0)   # entra desde la esquina y luego da vueltas; la punta en (0, 14)
			_gsm(R, "gm-pincel", 56 + (1 - ex) * 70 + cos(t / 150.0) * 8 * ex, 12 + (1 - ex) * 70 + sin(t / 150.0) * 3 * ex)
		"fumar":
			_gesto_fumar(R, c, t, bool(V.get("tab", false)))
		"vender":   # la mano del cliente (enfrente, desde arriba a la izquierda) con el billete y la tuya (desde abajo a la derecha) con
			# la bolsita; se cambian y se van
			_gsp(R, "gs-f-calle", 0, 0)
			if t < 650:
				var e: float = _mv(70, 0, t / 400.0)
				_gsm(R, "gm-billete-i", 2 - e, -8 - e)   # el billete en (55, 52)
				_gsm(R, "gm-bolsita", 72 + e, 26 + e)   # la bolsa en (8, 25)
			else:
				var e: float = _mv(0, 70, (t - 700) / 400.0)
				_gsm(R, "gm-bolsita-i", 18 - e, -6 - e)   # la bolsa en (38, 25)
				_gsm(R, "gm-billete", 66 + e, 36 + e)
		"pagar":   # tu mano va y viene: coge un billete del fajo, lo deja en el montón (cinco veces) y lo empuja
			_gsp(R, "gs-f-mesa", 0, 0)
			_gsp(R, "gs-fajo", 14, 40)
			for i in 5:
				var ti: float = 150 + i * 170
				if t > ti + 153:
					_gsp(R, "gs-billete", 84 + (i % 2) * 3, 42 - i * 2)
				if t > ti and t <= ti + 170:
					var f: float = (t - ti) / 170.0
					if f < 0.4:   # vacía, al fajo (los dedos en (2, 10)); la primera vez, desde la esquina
						var e: float = 70.0 if i == 0 else 0.0
						_gsm(R, "gm-vacia", _mv(84 + e, 18, f / 0.4), _mv(34 + e, 34, f / 0.4))
					elif f < 0.9:   # con el billete (su canto en (0, 10)), del fajo al montón
						_gsm(R, "gm-billete", _mv(18, 84, (f - 0.5) / 0.4) if f > 0.5 else 18.0, 34 - i * 2)
					else:
						_gsm(R, "gm-vacia", 84, 34)
			if t > 1000:   # empuja el montón y se va por la esquina
				var e: float = _mv(0, 70, (t - 1000) / 200.0)
				_gsm(R, "gm-vacia", 84 + e, 34 + e)
		"dormir":   # en la cama, de noche (o la siesta, de día); respira y suben las zetas
			_gsp(R, "gs-f-cama-d" if c == "siesta" else "gs-f-cama-n", 0, 0)
			_gsp(R, "gs-dormido-%d" % (1 if fmod(t, 1000) > 500 else 0), 16, 30)   # 1.55.1: de lado, tapado, el pecho sube y baja
			for i in 3:
				var f: float = fmod(t / 900.0 + i / 3.0, 1.0)
				_gsp(R, "gs-z", 50 + f * 16 + sin(f * 6) * 2, 36 - f * 30)

# fumar: la mano con el porro, la pipa o el vaporizador (el bong, en la mesa), el mechero los enciende, la brasa y el humo; el
# vaporizador, su piloto y el vapor. 0.55 (lo pidió el usuario: «si es con o sin tabaco se tiene que diferenciar»): el porro con tabaco,
# la punta retorcida con hebras marrones y el humo gris; solo hierba, la punta en cono con hebras verdes y el humo más blanco
func _gesto_fumar(R: Array, m: String, t: float, tab := false) -> void:
	if m == "":
		m = "porro"
	_gsp(R, "gs-f-cuarto", 0, 0)
	var e: float = _mv(70, 0, t / 150.0)   # la mano entra desde la esquina de abajo a la derecha (0.56: en primera persona)
	var x: float = 58 + e
	var punta := Vector2(x + 1, 55 + e)
	match m:
		"porro":
			_gsm(R, "gm-porro", x, 25 + e)   # la punta en (1, 30)
			for i in 4:   # las hebras de la punta
				_gsr(R, punta.x - 1 + i, punta.y - 1 + (i % 2) * 2 - (1 if tab and i == 0 else 0), 1, 1, ["#8a5a2a", "#6a4020", "#a87040", "#5a3a1a"][i] if tab else ["#5a8a3a", "#3e6a2a", "#7aa04a", "#2e5a20"][i])
			if tab:   # el papel retorcido
				_gsr(R, punta.x - 3, punta.y + 1, 2, 1, "#e8e0d0")
		"pipa":
			punta = Vector2(x + 6, 47 + e)
			_gsm(R, "gm-pipa", x, 45 + e)   # la boca de la cazoleta en (6, 2)
		"vapo":
			_gsm(R, "gm-vapo", x, 30 + e)   # la boquilla en (7, 0); el piloto en (13, 18)
			if t > 300 and int(t / 250.0) % 2:
				_gsr(R, x + 13, 48 + e, 1, 2, "#60e070")
		"bong":
			punta = Vector2(63, 64)
			_gsp(R, "gs-bong", 56, 40)
			if t > 450:
				for i in 4:
					var f: float = fmod(t / 400.0 + i / 4.0, 1.0)
					_gsp(R, "gs-burbuja", 74 + (i * 3) % 9, 82 - f * 8)
	if m != "vapo":   # 0.55: la otra mano sube con el mechero (la llama, en (36, 0)), lo enciende y baja; 0.56: desde abajo a la izquierda
		if t > 150 and t < 500:
			_gsm(R, "gm-mech1-ab", punta.x - 36, punta.y - 3)
		elif t <= 150:
			_gsm(R, "gm-mech0-ab", punta.x - 36, _mv(GS_H + 2, punta.y - 3, t / 150.0))
		elif t < 700:
			_gsm(R, "gm-mech0-ab", punta.x - 36, _mv(punta.y - 3, GS_H + 2, (t - 500) / 200.0))
		if t > 300:   # la brasa
			_gsr(R, punta.x - 1, punta.y - 1, 2, 2, "#ffb040" if int(t / 150.0) % 2 else "#f86a20")
	var sale := Vector2(80, 44) if m == "bong" else punta   # el humo del bong sale por arriba del tubo
	for i in 3:
		var ti: float = 450 + i * 300
		if t > ti:
			var f: float = (t - ti) / 900.0
			if f < 1:
				_gsp(R, "gs-humo-%d" % mini(2, int(f * 3)), sale.x - 12 - f * 6, sale.y - 14 - f * 36)
				if m == "porro":   # el tono del humo: gris con tabaco, blanco solo hierba
					_gsr(R, sale.x - 6 - f * 6, sale.y - 8 - f * 36, 3, 2, "#9a9a9a" if tab else "#f4f4f0")
