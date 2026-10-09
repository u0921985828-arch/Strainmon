# Ribera Verde (Godot) — 11-historia, 12-menus y 13-combate: la tienda de Kiko, los personajes, la deuda, los capítulos y el
# imperio, el menú START (Genoteca, mochila, cultivo) y los combates con ladrones y policía. Mismo guion, mismo orden de azar.
extends "res://src/granja.gd"

var cap_hasta := 0.0       # el rótulo del capítulo dura 2,8 s: el objetivo que se pida mientras tanto sale al acabar
var endcard_on := false

# ---------- tienda ----------
func shop_cond(it: Dictionary) -> bool:
	if it.get("item") == "prensa":   # la prensa de rosin (1.10), una
		return not S.items.get("prensa")
	if it.get("item") == "medidor":   # el medidor de pH y EC (1.11), uno
		return not S.items.get("medidor") and not S.envio.has(it.lbl)
	if it.get("aparato"):   # los aparatos de la sala (1.10), uno de cada; lo pedido por el móvil no se vuelve a vender
		return not S.sala.get(it.aparato) and not S.envio.has(it.lbl)
	if it.get("bolsa"):   # la bolsa de deporte y la maleta (1.10)
		return bolsa_ya() < it.bolsa
	if it.get("extra"):
		var k: String = it.extra
		var nc := 0
		for c in S.carpas:
			if falta_extra(c, k):
				nc += 1
		return nc > S.items.get("x_" + k, 0) + S.envio.count(it.lbl)
	match it.get("carpa", ""):
		"p80":
			return S.carpas[0].t == "p60"
		"m100":
			return S.carpas.size() < 2 or S.carpas[1] == null
		"g150":
			return S.carpas.size() > 1 and S.carpas[1] != null and S.carpas[1].t == "m100"
		"m120":
			return S.carpas.size() > 1 and S.carpas[1] != null and (S.carpas.size() < 3 or S.carpas[2] == null)
	return true

func precio_sobre(it: Dictionary, nf: Array) -> int:
	return Datos.jsround(it.p * nf[0] * nf[1])

func comprar_semillas(it: Dictionary) -> void:
	var l: Array = D.SOBRES.duplicate()
	if S.ch >= 3:
		l.append(D.GRANEL)
	var o := []
	for nf in l:
		var nn := int(nf[0])
		o.append("%s · %s" % ["1 semilla" if nn == 1 else ("Bolsa de %d" % nn if nn >= 50 else "Sobre de %d" % nn), Datos.eur(precio_sobre(it, nf))])
	o.append("Nada")
	var j: int = await ask("Semillas feminizadas de %s. ¿Cuántas?" % D.STRAINS[it.sid].n, o, "KIKO")
	if j < 0 or j >= l.size():
		return
	var e := precio_sobre(it, l[j])
	if S.money < e:
		sfx("bad")
		await say("No te llega el dinero.", "KIKO")
		return
	S.money -= e
	sfx("coin")
	add_seeds(it.sid, int(l[j][0]))
	toast("Comprado: %d × %s" % [int(l[j][0]), D.STRAINS[it.sid].n], 1200)

# carpa comprada (en un sitio libre) o ampliada (mismo sitio): cada plaza conserva su planta y su maceta por (carpa, plaza)
func comprar_carpa(t: String, ci: int) -> void:
	var antes := []
	for h in huecos():
		antes.append("%d:%d" % [h.c, h.j])
	var pots: Array = S.pots
	var mac: Array = S.macetas
	if ci < S.carpas.size() and S.carpas[ci]:
		S.carpas[ci].t = t
	else:
		while S.carpas.size() <= ci:
			S.carpas.append(null)
		S.carpas[ci] = {"t": t, "foco": "cfl"}
	var np := []
	var nm_ := []
	for h in huecos():
		var j := antes.find("%d:%d" % [h.c, h.j])
		np.append(pots[j] if j >= 0 and j < pots.size() and pots[j] else null)
		nm_.append(mac[j] if j >= 0 and j < mac.size() and mac[j] else "plastico7")
	S.pots = np
	S.macetas = nm_

const IC := {"fert": "abono", "fertv": "abono", "phm": "abono", "insect": "insecticida", "spray": "spray", "bocata": "bocadillo"}

func shop() -> void:
	var i := 0
	while true:
		var list := []
		for it in D.SHOP:
			if S.ch >= it.ch and shop_cond(it):
				list.append(it)
		var items := []
		for it in list:
			var ic = null
			if it.get("sid"):
				ic = icono("semillas")
			elif it.get("item"):
				ic = icono(IC[it.item]) if IC.has(it.item) else null
			elif it.get("maceta"):
				ic = icono("maceta")
			elif it.get("foco"):
				ic = icono(Atlas.ico_foco(it.foco))
			elif it.get("extra"):
				ic = icono(Atlas.ICX[it.extra])
			elif it.get("carpa"):
				ic = icono(Atlas.ico_carpa(it.carpa))
			items.append({"label": it.lbl, "right": Datos.eur(it.p) + ("/u" if it.get("sid") else ""), "sw": D.STRAINS[it.sid].c if it.get("sid") else null, "ic": ic,
				"desc": strain_line(it.sid) if it.get("sid") else it.get("desc", "")})
		items.append({"label": "Salir", "desc": "Volver al mostrador."})
		i = await menu(items, {"cls": "full", "title": "GROWSHOP KIKO", "title2": "Tienes " + Datos.eur(S.money), "desc": true, "initial": i})
		if i < 0 or i >= list.size():
			break
		var it: Dictionary = list[i]
		if it.get("sid"):
			await comprar_semillas(it)
			await check_story()
			continue
		var p := int(it.p)
		if S.money < p:
			sfx("bad")
			await say("No te llega el dinero.", "KIKO")
			continue
		S.money -= p
		sfx("coin")
		if it.get("item"):
			S.items[it.item] += int(it.get("n", 1))
		if it.get("maceta"):
			S.items["m_" + it.maceta] += 1
		if it.get("bolsa"):
			S.items.bolsa = int(it.bolsa)
		if it.get("aparato"):
			S.sala[it.aparato] = true
		if not it.get("foco") and not it.get("carpa") and not it.get("extra"):
			toast("Comprado: " + it.lbl, 1200)
		if it.get("carpa"):
			comprar_carpa(it.carpa, int(it.ci))
			await say(D.DICHO_CARPA[it.carpa], "KIKO")
		if it.get("extra"):
			S.items["x_" + it.extra] += 1
			var ok := []
			for ci in S.carpas.size():
				if falta_extra(S.carpas[ci], it.extra):
					ok.append(ci)
			var pl: bool = D.EXTRAS[it.extra].get("pl", false)
			if ok.is_empty():
				await say("Ya tienes unas en cada carpa. Te las guardo en la mochila." if pl else "Ya tienes uno en cada carpa. Te lo guardo en la mochila.", "KIKO")
			else:
				var o := []
				for ci in ok:
					o.append(D.CARPAS[S.carpas[ci].t].n)
				o.append("Luego")
				var c: int = await ask("¿Te las pongo ya?" if pl else "¿Te lo pongo ya?", o, "KIKO")
				if c >= 0 and c < ok.size():
					var vu: bool = it.extra == "goteo" and S.carpas[ok[c]].get("garrafas", false)
					var vk := poner_extra(ok[c], it.extra)
					toast(("Puestas: " if pl else "Puesto: ") + it.lbl, 1200)
					if vu:
						await say("Las garrafas de esa carpa vuelven a la mochila.", "KIKO")
					if vk != "":
						await say("El %s que tenías vuelve a tu mochila." % D.EXTRAS[vk].c.to_lower(), "KIKO")
		if it.get("foco"):
			S.items["f_" + it.foco] += 1
			var ok := []
			for ci in S.carpas.size():
				var cc = S.carpas[ci]
				if cc and D.FOCOS[it.foco].w <= D.CARPAS[cc.t].wmax:
					ok.append(ci)
			if ok.is_empty():
				await say("Ese foco calienta demasiado para tus carpas. Guárdalo hasta que tengas una más grande.", "KIKO")
			else:
				var o := []
				for ci in ok:
					o.append("%s (%s)" % [D.CARPAS[S.carpas[ci].t].n, D.FOCOS[S.carpas[ci].foco].n])
				o.append("Luego")
				var c: int = await ask("¿Lo cuelgo ya? El que quites va a tu mochila.", o, "KIKO")
				if c >= 0 and c < ok.size():
					instalar_foco(ok[c], it.foco)
					toast("Instalado: " + it.lbl, 1200)
		await check_story()
	await say("Ten cuidado ahí fuera.", "KIKO")

func kiko_tip() -> String:
	var t: Array = D.KIKO_TIPS
	var l: Array = t[mini(3, maxi(0, S.ch - 1))].duplicate()
	if S.ch > 3:
		l.append_array(t[1])
	return pick(l)

# ---------- personajes ----------
func talk_kiko():
	var N := "KIKO"
	if not S.flags.get("kiko1"):
		await talk(N, ["{N}, pasa. Te pareces a tu tía.", "Maite y yo cultivamos juntos desde que cerraron los astilleros. Ella tenía mano; yo, paciencia.", "Para empezar, toma esto."])
		add_seeds("ria", 3)
		await got("3 semillas de SKUNK #1")
		S.items.fert += 2
		await got("2 dosis de ABONO")
		await talk(N, ["La Skunk #1 aguanta casi todo: errores de riego, plagas, frío. Es la mejor para aprender.", "Planta en las macetas del armario de tu tía y riega cuando baje el agua.",
			"El abono da más cogollo. Si ves araña roja, insecticida: lo tengo aquí.", "Cuando esté lista, cosecha. Son feminizadas: casi nunca dan semilla, pero si sale alguna, guárdala.",
			"Las plantas siguen creciendo mientras duermes.", "Te iré mandando al móvil lo que te hace falta para salir adelante. Lo tienes en START, en OBJETIVO."])
		S.flags.kiko1 = true
		show_objective()
		return
	if S.ch == 4 and not S.flags.get("lab"):
		await talk(N, ["Ya me han contado que has pagado a Baltasar. Bien hecho.", "Te he montado en el piso mi equipo de polinización: pinceles, bolsas de papel y una lupa."])
		S.flags.lab = true
		await got("la MESA DE GENÉTICA")
		add_seeds("rif", 3)
		await got("3 semillas de AFGHANI")
		await talk(N, ["Me las trajo un amigo de Mazar-i-Sharif en los ochenta. Las he ido renovando desde entonces.", "En la mesa polinizas una variedad con otra: gastas una semilla de cada y obtienes 2 del cruce.",
			"Algunos cruces dan variedades conocidas. Otros, híbridos que solo tendrás tú.", "Apúntalo todo en la GENOTECA. Las mejores genéticas salen de cruzar cruces.",
			"Empieza por las conocidas: saca dos de receta en la mesa y cosecha una planta de cada. Patxi, el de la plaza, se sabe unas cuantas."])
		show_objective()
		await check_story()
		return
	var alguna := false
	for p in S.pots:
		if p:
			alguna = true
	if S.seeds.is_empty() and not alguna and not total_buds() and not total_rosin() and not caja_g() and not caja_r() and not arcon_g() and not arcon_r() and S.money + caja_e() < 15:   # lo de la caja y el arcón también cuenta (1.10)
		await say("¿Sin semillas y sin dinero? Toma. Ya me lo pagarás.", N)
		add_seeds("ria", 2)
		await got("2 semillas de SKUNK #1")
	var c: int = await ask("¿Qué necesitas?", ["Comprar", "Un consejo", "Nada"], N)
	if c == 0:
		await shop()
	elif c == 1:
		await say(kiko_tip(), N)
	else:
		await say("Ten cuidado ahí fuera.", N)

func talk_josune():
	var N := "JOSUNE"
	var c: int = await ask("¡Kaixo! ¿Qué te pongo?", ["Pintxo · 4 €", "Kalimotxo · 3 €", "¿Algún rumor?", "Nada"], N)
	if c == 0 or c == 1:
		var cost := 3 if c else 4
		var hp := 6 if c else 12
		if S.money < cost:
			await say("Aquí no se fía.", N)
			return
		S.money -= cost
		S.hp = mini(S.hpMax, S.hp + hp)
		sfx("coin")
		await say("Un kalimotxo. Recuperas algo de vida." if c else "Pintxo de tortilla, recién hecha. Recuperas vida.", N)
		return
	if c == 2:
		await say(pick(["Dicen que alguien escondía cosas en los arbustos del parque.", "Iñaki, el del muelle, trae semillas de sus viajes.", "Txaro está con la quimio. Lo está pasando muy mal.",
			"Darko es sobrino de Baltasar. Por eso nadie le dice nada.", "El sargento Molina cobra por mirar hacia otro lado. Lo sabe todo el barrio."]), N)

func talk_patxi():
	S.patxi = S.get("patxi", 0) + 1
	var R: Array = D.RECIPE_HINTS
	await say("Cuando tengas una mesa de genética, ven a verme. Algo sé de cruces." if S.ch < 4 else "Cuarenta años cultivando en el monte. Te digo una cosa: " + R[S.patxi % R.size()], "PATXI")

func talk_txaro():
	var N := "ABUELA TXARO"
	if S.flags.get("txaro") and (S.flags.get("txaro2") or S.ch < 4):
		await say(pick(["Ya duermo de un tirón. Gracias, de verdad.", "Tu tía me ayudaba igual. No se lo contábamos a nadie."]), N)
		return
	# segunda misión (1.10), en su casa desde el capítulo 4: 10 g de una índica (70 % o más)
	if S.flags.get("txaro"):
		await talk(N, ["El aceite me ha devuelto el sueño. Gracias, de verdad.", "Pero el dolor no se va. El médico dice que, para eso, mejor una índica: relaja más.",
			"¿Me traerías 10 gramos de una índica? De las de hoja ancha."])
		var li := bud_lots(10).filter(func(l): return Datos.ind_de(S, lot_sid(l[0])) >= 70)
		if li.is_empty():
			await say("Cuando tengas 10 gramos de una índica, ven a verme. Aquí estaré.", N)
			return
		var it2 := li.map(lot_item)
		it2.append({"label": "Ahora no"})
		var i2: int = await menu(it2, {"cls": "right", "title": "¿Qué le das?"})
		if i2 < 0 or i2 >= li.size():
			await say("No pasa nada. Aquí estaré.", N)
			return
		use_buds(li[i2][0], 10)
		S.rep += 5
		await say("Toma, las últimas de mi Paco. Las trajo de Chitral, en las montañas de Pakistán.", N)
		add_seeds("chitral", 3)
		await got("3 semillas de CHITRAL KUSH")
		S.items.bocata += 3
		await got("3 × BOCATA")
		S.flags.txaro2 = true
		return
	await talk(N, ["Tú vives en el piso de Maite. Tu tía me ayudaba con... ya sabes.", "Desde la quimio apenas duermo y no tengo hambre. Las pastillas no me hacen nada.",
		"Me vendrían bien 5 gramos, para hacer aceite como me enseñó ella. ¿Me los das?"])
	var lots := bud_lots(5)
	if lots.is_empty():
		await say("Cuando tengas 5 gramos, acuérdate de mí.", N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Ahora no"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué le das?"})
	if i < 0 or i >= lots.size():
		await say("No pasa nada. Aquí estaré.", N)
		return
	use_buds(lots[i][0], 5)
	await say("Gracias. Toma: las trajo mi Paco de Pakistán en el setenta y seis. Nunca supe qué hacer con ellas.", N)
	add_seeds("hindu", 2)
	await got("2 semillas de HINDU KUSH")
	S.items.bocata += 3
	await say("Y llévate estos bocadillos, que comes poco.", N)
	await got("3 × BOCATA")
	S.flags.txaro = true
	await say("Me voy a casa a preparar el aceite. Vivo en la casa gris, al lado del bar. Pásate cuando quieras.", N)
	if S.map == "town":
		await fade(1)
		build_ents()
		await fade(0)

# Iñaki: 10 g para el viaje, una vez al día; desde el capítulo 3 también compra al por mayor
func talk_inaki():
	var N := "IÑAKI"
	if S.ch >= 3:
		var c: int = await ask("Aupa. ¿Qué traes?", ["10 g para el viaje", "Venta al por mayor", "Nada"], N)
		if c == 1:
			await venta_mayor(N)
			return
		if c != 0:
			return
	if S.iDay == S.day:
		await say("Ya me has vendido hoy. Mañana más, que el barco sale temprano.", N)
		return
	await say("Aupa. Me voy tres semanas a la mar. ¿Tienes 10 g para el viaje? Pago bien.", N)
	var lots := bud_lots(10)
	if lots.is_empty():
		await say("Pues nada. Si consigues 10 g, aquí estaré.", N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué le vendes?"})
	if i < 0 or i >= lots.size():
		return
	var sid: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var amt := Datos.jsround(precio_calle(b.thc) * 1.2 * 10)
	if await ask("Te doy %d € por 10 g de %s. ¿Hecho?" % [amt, lot_nombre(sid)], ["Hecho", "No"], N) != 0:
		return
	use_buds(sid, 10)
	S.money += amt
	S.sales += amt
	S.heat = min(100, S.heat + 3)
	S.iDay = S.day
	S.rep += 2
	sfx("coin")
	if not S.flags.get("inaki"):
		S.flags.inaki = true
		await say("Toma. Me las dio un marinero de Malaui en Mombasa, en el último viaje.", N)
		add_seeds("malawi", 2)
		await got("2 semillas de MALAWI GOLD")
	else:
		await say("Eskerrik asko. Hasta la vuelta.", N)
	await check_story()

func mayor_dia() -> int:
	return int(D.IMPERIO[imperio_nivel() if S.ch >= 8 else 0].mayor)

static func _kg(g: int) -> String:
	return (Datos.coma(g / 1000.0) + " kg") if g >= 1000 else "%d g" % g

static func _dos(x: float) -> String:
	return Datos.to_fixed(x, 2).replace(".", ",")

func venta_mayor(N: String) -> void:
	if S.mDay == S.day:
		await say("Hoy ya he cargado. Mañana sale otro barco.", N)
		return
	var lots := bud_lots(100)
	if lots.is_empty():
		await say("Al por mayor, de 100 g para arriba. Pago entre %s y %s € el gramo, según lo bueno que sea. Hasta %s por carga." % [_dos(precio_mayor(12)), _dos(precio_mayor(30)), _kg(mayor_dia())], N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		await say("Otro día.", N)
		return
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var pg := Datos.jsround(precio_mayor(b.thc) * 100) / 100.0
	var tope := mini(int(floor(b.g)), mayor_dia())
	var ops := []
	for g in [100, 250, 500, 1000, 2000, 5000, 10000]:
		if g < tope:
			ops.append(g)
	ops.append(tope)
	var o := []
	for g in ops:
		o.append("%s · %s" % [_kg(g), Datos.eur(g * pg)])
	o.append("Nada")
	var j: int = await ask("%s a %s € el gramo. ¿Cuánto cargas?" % [lot_nombre(k), _dos(pg)], o, N)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	var e := Datos.jsround(g * pg)
	use_buds(k, g)
	S.money += e
	S.sales += e
	S.mDay = S.day
	S.heat = min(100, S.heat + 2 + g / 100.0)   # 1.10: antes, por cada 250 g
	S.rep += 1
	sfx("coin")
	await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
	toast("+%s · %s al por mayor" % [Datos.eur(e), _kg(g)], 1600)
	await say("Cargado. Esta noche sale en el barco.", N)
	heat_warn()
	await check_story()

func talk_cop():
	if carga_sosp() > 0 and not S.protect:
		await say("¿Y ese olor? Quieto ahí.", "AGENTE")
		await battle("police")
		return
	await say(pick(["Circule.", "Todo tranquilo por aquí. Que siga así.", "De noche hay robos en el parque. Tenga cuidado."]), "AGENTE")

func talk_darko():
	var N := "DARKO"
	if S.ch == 6:
		await talk(N, ["¿Vienes a la Copa? Mi AMNESIA HAZE dio un 26,8 % de THC en el laboratorio.", "Nadie en Ribera ha pasado del 26. No vas a ser tú el primero."])
		return
	if S.ch >= 7:   # en los astilleros (1.10)
		await talk(N, ["¿Has dormido bien últimamente?" if S.flags.get("robo") else "Mi tío dice que ya no le debes nada. A mí, sí.", "Estas esquinas son mías. Si vendes aquí, mis chicos te lo van a recordar."])
		return
	S.flags.darko1 = true
	await talk(N, ["Así que tú te has quedado el piso de Maite.", "Soy DARKO. La hierba de este barrio la muevo yo.", "Vende lo tuyo si quieres, pero lejos de mis esquinas.", "No me hagas repetirlo."])
	await fade(1)
	build_ents()
	await fade(0)

# la cuota de Molina (1.10): SOBORNO cada CUOTA_DIAS días (S.protHasta, el último día cubierto; new_day la da por acabada).
# La primera vez, en la plaza; después, en la comisaría del barrio alto
func talk_molina():
	var N := "SARGENTO MOLINA"
	var sob := int(D.SOBORNO)
	var cd := int(D.CUOTA_DIAS)
	var plaza: bool = S.map == "town"
	if not S.flags.get("molina1"):
		S.flags.molina1 = true
		await talk(N, ["Así que eres tú quien vende en la plaza.", "Podría detenerte ahora mismo. O podemos entendernos.", "Por %s cada %d días, mis patrullas no pasan por tu calle. Y nada de registros en tu piso." % [Datos.eur(sob), cd]])
	elif S.protect:
		await say("Estás cubierto hasta el día %s. %s" % [n(S.protHasta), ("Te quedan %s días." % n(S.protHasta - S.day)) if S.protHasta > S.day else "Se acaba HOY."], N)
	var c: int = await ask("¿Pagar ya los diez días siguientes?" if S.protect else "¿Aceptas el trato del sargento?", ["Pagar " + Datos.eur(sob), "No"], N)
	if c == 0:
		if S.money < sob:
			await say("¿Con qué dinero? Vuelve cuando lo tengas.", N)
		else:
			S.money -= sob
			S.protHasta = int(max(S.day, S.protHasta if S.protect else 0)) + cd
			S.protect = true
			sfx("coin")
			await say("Bien. Mis agentes mirarán hacia otro lado hasta el día %s." % n(S.protHasta), N)
	elif not S.protect:
		S.heat = min(100, S.heat + 10)
		await say("Tú sabrás. Mis agentes van a estar muy atentos.", N)
		heat_warn()
	if plaza:
		await say("Si me necesitas, estoy en la comisaría del barrio alto.", N)
		await fade(1)
		build_ents()
		await fade(0)

func talk_jurado():
	var N := "JURADO"
	await talk(N, ["Esto es la COPA DE RIBERA, la de la asociación cannábica del barrio.", "Para competir, trae 20 g de una sola variedad. Se analizan en laboratorio.", "Marca a batir: DARKO, con AMNESIA HAZE, 26,8 % de THC."])
	var lots := bud_lots(20)
	if lots.is_empty():
		await say("Vuelve cuando tengas 20 g de algo.", N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Todavía no"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué presentas?"})
	if i < 0 or i >= lots.size():
		return
	var sid: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var thc := Datos.jsround(b.thc * 10) / 10.0
	var name_ := lot_nombre(sid).replace(" ★", "")
	use_buds(sid, 20)
	await fade(1)
	await wait(500)
	await fade(0)
	await say("Resultado del laboratorio. AMNESIA HAZE de Darko: 26,8 % de THC.", N)
	await say("%s de {N}: %s %% de THC." % [name_, Datos.pct(thc)], N)
	if thc > 26.8:
		sfx("get")
		await say("Nueva marca. {N} gana la COPA DE RIBERA.", N)
		S.money += int(D.PREMIO_COPA)
		S.rep += 20
		await got(Datos.eur(D.PREMIO_COPA) + " y el trofeo de la Copa")
		await talk("DARKO", ["Esto no se acaba aquí.", "Mi tío se va a enterar."])
		S.flags.copa = true
		S.due = S.debt
		S.deadline = S.day + 7
		await chapter(7)   # el plazo, antes: chapter() guarda
		show_objective()
	else:
		sfx("bad")
		await say("Gana DARKO. La Copa sigue abierta: vuelve con algo más potente.", N)

func talk_baltasar():
	var N := "DON BALTASAR"
	if S.ch < 3:
		await say("¿Y tú quién eres? No tengo nada que hablar contigo.", N)
		return
	# el plazo corre desde que Toño te avisa (1.10): si tardas más de 2 días en venir, «Llegas tarde»
	if S.ch == 3 and not S.flags.get("metB"):
		var tarde: bool = S.flags.has("tono") and S.day - S.flags.tono > 2
		await talk(N, ["Llegas tarde, {N}. Toño te dijo «hoy»." if tarde else "Siéntate, {N}. Vamos al grano.", "Tu tía Maite me debía %s. Las deudas no se mueren con la gente." % Datos.eur(D.DEUDA).replace(" €", " euros"),
			"Me los vas a pagar a plazos. El primero, %s%s." % [Datos.eur(S.due), ", con los intereses de tu retraso" if S.due > D.PLAZOS["3"] else ""],
			"Tienes hasta el día %s. Si no, Toño te hará una visita. Y Toño cobra intereses." % n(S.deadline)])
		S.flags.metB = true
		show_objective()
		return
	if S.ch >= 8:
		await encargo_baltasar(N)
		return
	if S.ch == 4:
		await say("Tranquilo. Ya te avisaré cuando toque el siguiente pago.", N)
		return
	if S.ch == 6:
		await say("Primero, la Copa. Darko te espera en la plaza.", N)
		return
	var left: int = S.deadline - S.day
	await say("Me debes %s para el día %s. %s" % [Datos.eur(S.due), n(S.deadline), ("Te quedan %d días." % left) if left > 0 else "Es HOY."], N)
	if S.money < S.due:
		await say("Vuelve cuando tengas el dinero.", N)
		return
	if await ask("¿Pagar ahora?", ["Pagar", "Todavía no"], N) != 0:
		return
	S.money -= S.due
	S.debt -= S.due
	var paid = S.due
	S.due = 0
	sfx("coin")
	toast("Pagado: " + Datos.eur(paid), 1500)
	if S.ch == 3:
		await talk(N, ["Puntual. Así me gusta.", "Quedan %s. Ya te avisaré del siguiente plazo." % Datos.eur(S.debt).replace(" €", "")])
		await chapter(4)
		await talk("SMS · KIKO", ["Pásate por el growshop. Tengo algo para ti."])
		show_objective()
	elif S.ch == 5:
		await talk(N, ["Me sorprendes, {N}.", "Quedan %s. Te propongo algo." % Datos.eur(S.debt).replace(" €", ""), "La COPA DE RIBERA se juega estos días en la plaza. Premio: %s." % Datos.eur(D.PREMIO_COPA),
			"Mi sobrino Darko compite. No ha perdido nunca.", "Gana la Copa y, con el premio y lo que vendas, me pagas lo que queda. Si puedes."])
		await chapter(6)
		show_objective()
	elif S.ch == 7:
		await talk(N, ["%s. Contados." % Datos.eur(paid), "Deuda saldada. Lo de tu tía queda cerrado.", "Una cosa más, {N}: si algún día quieres trabajar para mí, ya sabes dónde estoy."])
		S.debt = 0
		S.imp0 = S.sales
		S.impN = 0
		await ending()

# ---------- capítulos, objetivo e imperio ----------
func chapter(nn: int) -> void:
	S.ch = nn
	sfx("get")
	toast("<small>CAPÍTULO %d</small>%s" % [nn, D.CH_TITLES[str(nn)]], 2800)
	cap_hasta = M.reloj + 2800
	build_ents()
	await wait(400)
	save()

func objective_text() -> String:
	match int(S.ch):
		1:
			if llegando():
				return "Coge el autobús en la plaza de Mendialde hasta Ribera Verde."
			if not S.flags.get("letter"):
				return "Lee la carta que hay en la mesa." if S.map == "home" else "Entra en el piso de la tía Maite, enfrente de la parada, y lee la carta que hay en la mesa."
			return ("Visita el growshop de Kiko, al lado de casa." if not S.flags.get("kiko1") else "Planta y consigue tu primera cosecha.")
		2:
			var mv := int(D.META_VENTAS)
			return "Gana %d € vendiendo (%d/%d)." % [mv, mini(mv, Datos.jsround(S.sales)), mv]
		3:
			return (("Ve al bar El Ancla antes del día %s: Don Baltasar quiere %s." % [n(S.deadline), Datos.eur(S.due)]) if not S.flags.get("metB") else "Paga %s a Don Baltasar antes del día %s." % [Datos.eur(S.due), n(S.deadline)]) + llevas()
		4:
			return "Kiko quiere verte en el growshop." if not S.flags.get("lab") else "Saca en la mesa 2 variedades de receta y cosecha una planta de cada (%d/2)." % rec_count()
		5:
			return "Paga %s a Don Baltasar antes del día %s." % [Datos.eur(S.due), n(S.deadline)] + llevas()
		6:
			return "Gana la Copa: 20 g con más de 26,8% de THC al jurado de la plaza."
		7:
			return "Paga los últimos %s a Don Baltasar antes del día %s." % [Datos.eur(S.due), n(S.deadline)] + llevas()
	if S.get("encargo"):
		return "Encargo de Don Baltasar: lleva %s al almacén de los astilleros, de noche, antes de que acabe el día %s." % [_kg(int(S.encargo.g)), n(S.encargo.hasta)]
	var nv := imperio_nivel()
	var I: Array = D.IMPERIO
	var nd := 0
	for k in D.DEX:
		if S.disc.get(k):
			nd += 1
	var gen := "Genoteca %d/%d" % [nd, D.DEX.size()]
	if nv + 1 < I.size():
		var sig: Dictionary = I[nv + 1]
		return "Tu imperio · %s. Facturado desde la deuda: %s de %s para ser %s. %s." % [I[nv].n, Datos.eur(minf(sig.meta, facturado())), Datos.eur(sig.meta), sig.n.to_lower(), gen]
	return "Tu imperio · %s. Completa la %s." % [I[nv].n, gen]

# 1.11: en los plazos, lo que llevas entre el bolsillo y la caja
func llevas() -> String:
	return " Llevas %s." % Datos.eur(S.money + caja_e())

func show_objective():
	var d := cap_hasta - M.reloj
	if d > 0:
		M.timeout(show_objective, d)
		return
	toast("<small>OBJETIVO</small>" + esc(objective_text()), 3200)

# ---------- misiones guiadas (1.11, 11c-misiones.js): textos y regalos del HTML (D.MISIONES); aquí, lo que mira cada una ----------
var mision_aviso: Array = []

func _con_foco() -> Array:
	return S.carpas.filter(func(c): return c is Dictionary and D.FOCOS.has(str(c.get("foco"))))

func mision_ok(id: String) -> bool:
	match id:
		"caja":
			return true if S.get("caja") else false
		"luz":
			return _con_foco().any(func(c): return c.foco != "cfl")
		"carpa":
			return S.carpas.filter(func(c): return c is Dictionary).size() >= 2
		"olor":
			return S.carpas.any(func(c): return Cultivo.kit_de(c) != "")
		"inaki":
			return true if S.flags.get("inaki") else false
		"mayor":
			return float(S.get("mDay", 0)) > 0
		"potencia":
			return _con_foco().any(func(c): return float(D.FOCOS[c.foco].w) >= 400)
		"led":
			return _con_foco().any(func(c): return D.FOCOS[c.foco].tipo == "led" and float(D.FOCOS[c.foco].w) >= 480)
		"seis":
			return S.carpas.any(func(c): return c is Dictionary and int(D.CARPAS[c.t].plazas) >= 6)
	return false

func misiones_ver() -> Array:
	if not S.flags.get("kiko1"):
		return []
	return D.MISIONES.filter(func(m): return m.ch <= S.ch)

func mision_sig():
	for m in misiones_ver():
		if not S.misiones.has(m.id):
			return m
	return null

func premio_txt(m: Dictionary) -> Array:
	var r := []
	var p = m.get("p")
	if p:
		for k in p:
			r.append("%d %s" % [int(p[k]), D.PREMIO_N[k]])
	var s = m.get("s")
	if s:
		for k in s:
			r.append("%d semillas de %s" % [int(s[k]), strain(k).n.to_upper()])
	return r

# run() la llama al acabar cada guion: marca las cumplidas, da el regalo y encola el SMS
func revisa_misiones() -> void:
	for m in misiones_ver():
		if not S.misiones.has(m.id) and mision_ok(m.id):
			S.misiones[m.id] = S.day
			mision_aviso.append(m.id)
			var p = m.get("p")
			if p:
				for k in p:
					S.items[k] += int(p[k])
			var s = m.get("s")
			if s:
				for k in s:
					add_seeds(k, int(s[k]))
	if mision_aviso.size():
		queue("mision", aviso_mision)

func aviso_mision():
	while mision_aviso.size():
		var id: String = mision_aviso.pop_front()
		var m: Dictionary = {}
		for x in D.MISIONES:
			if x.id == id:
				m = x
		sfx("get")
		toast("<small>MISIÓN CUMPLIDA</small>" + m.t, 2400)
		await talk("SMS · KIKO", m.sms)
		for t in premio_txt(m):
			await got(t)
	var sg = mision_sig()
	if sg:
		toast("<small>MISIÓN</small>" + sg.t, 3200)

# el plazo (1.11): Toño avisa cuando quedan 3 días y el último, con lo que llevas
func recuerdo_plazo():
	var nd := int(S.deadline - S.day)   # los días, como los cuenta Baltasar (talk_baltasar)
	var ll: float = S.money + caja_e()
	await talk("SMS · TOÑO", [("Don Baltasar quiere %s antes de que acabe el día %s. Te quedan %d días." % [Datos.eur(S.due), n(S.deadline), nd]) if nd > 0 else "Hoy es el último día para los %s de Don Baltasar." % Datos.eur(S.due)])
	await say(("Llevas %s entre el bolsillo y la caja: te faltan %s." % [Datos.eur(ll), Datos.eur(S.due - ll)]) if ll < S.due else "Llevas %s entre el bolsillo y la caja: ya lo tienes.%s Ve al bar El Ancla." % [Datos.eur(ll), " Saca lo que falte de la caja y" if S.money < S.due else ""])

# START → OBJETIVO: el del capítulo, las misiones (con lo que hay que hacer abajo) y la deuda
func objetivo_menu():
	var it := [{"label": "CAPÍTULO %d" % S.ch, "desc": "%s\n%s" % [D.CH_TITLES.get(str(S.ch), ""), objective_text()]}]
	var ini := 0
	var mv := misiones_ver()
	for i in mv.size():
		var hecha: bool = S.misiones.has(mv[i].id)
		it.append({"label": mv[i].t, "right": "HECHA" if hecha else null, "desc": mv[i].d})
		if not hecha and ini == 0:
			ini = i + 1
	var plazo := ("Plazo: %s antes de que acabe el día %s. Llevas %s.\n" % [Datos.eur(S.due), n(S.deadline), Datos.eur(S.money + caja_e())]) if S.due > 0 else ""
	it.append({"label": "DEUDA", "right": Datos.eur(S.debt), "desc": plazo + "Ventas %s · Reputación %s · Calor %d %%" % [Datos.eur(S.sales), n(S.rep), Datos.jsround(S.heat)]})
	it.append({"label": "Volver", "desc": ""})
	await menu(it, {"cls": "full", "title": "OBJETIVO", "title2": "cap. %d" % S.ch, "desc": true, "initial": ini})

func facturado() -> float:
	return maxf(0, S.sales - S.get("imp0", 0))

func imperio_nivel() -> int:
	var nv := 0
	for i in D.IMPERIO.size():
		if facturado() >= D.IMPERIO[i].meta:
			nv = i
	return nv

func check_story():
	if S.ch == 1 and S.flags.get("harvest1"):
		await chapter(2)
		spawn_clients()
		await talk("SMS · KIKO", ["Primera cosecha. Bien hecho.", "La gente que busca material lleva un $ encima. Puedes venderles en la calle.", "Cuanto más vendas, más se fijará la policía: es el CALOR. Y de noche hay quien roba."])
		show_objective()
	if S.ch == 2 and S.sales >= D.META_VENTAS:
		S.due = int(D.PLAZOS["3"])   # el plazo, desde ya (1.10)
		S.deadline = S.day + 7
		S.flags.tono = S.day
		await chapter(3)
		await say("Un hombre enorme en chándal te corta el paso.")
		await talk("TOÑO", ["Tú vives en el piso de Maite, ¿no?", "Don Baltasar quiere verte. En el bar El Ancla. Hoy.", "Y ve contando: tienes siete días para el primer pago.", "No me hagas venir a buscarte."])
		show_objective()
	if S.ch >= 8 and imperio_nivel() > S.get("impN", 0):
		S.impN = imperio_nivel()
		var r: Dictionary = D.IMPERIO[S.impN]
		sfx("get")
		toast("<small>TU IMPERIO</small>" + r.n, 2800)
		await talk("SMS · IÑAKI", ["Se corre la voz: %s vendidos desde que pagaste a Baltasar." % Datos.eur(facturado()), "Desde hoy te cargo hasta %s al día en el barco." % _kg(int(r.mayor))])
		show_objective()
	if S.ch == 4 and S.flags.get("lab") and rec_count() >= 2:
		S.due = int(D.PLAZOS["5"])
		S.deadline = S.day + 10
		await chapter(5)
		await talk("SMS · TOÑO", ["Don Baltasar quiere %s en diez días." % Datos.eur(D.PLAZOS["5"]), "Otra cosa: un tal SARGENTO MOLINA pregunta por ti en la plaza."])
		show_objective()

func penalty_event():
	await say("TOÑO te estaba esperando.")
	var it := Datos.jsround(S.due * D.INTERES / 100) * 100
	S.vencidos += 1
	await talk("TOÑO", ["Don Baltasar dice que llegas tarde.", "Son %s más de intereses. Y esto, para que no se te olvide." % Datos.eur(it)])
	sfx("hurt")
	S.hp = maxi(1, S.hp - 15)
	S.due += it
	S.debt += it
	S.deadline = S.day + 5
	await say("La deuda del plazo sube a %s. Nuevo límite: día %s." % [Datos.eur(S.due), n(S.deadline)])
	if S.vencidos >= 3:
		S.vencidos = 0
		await embargo()

# al tercer plazo vencido (1.10), Toño se lleva la carpa más grande del fondo o de junto a la cama (B o C), con su foco, sus
# extras y sus plantas; sin ninguna de las dos, la mitad del dinero que llevas encima
func area_carpa(ci: int) -> float:
	var cm: Array = D.CARPAS[S.carpas[ci].t].cm
	return cm[0] * cm[2]

func quitar_carpa(ci: int) -> void:
	var antes := []
	for h in huecos():
		antes.append("%d:%d" % [int(h.c), int(h.j)])
	var pots: Array = S.pots
	var mac: Array = S.macetas
	S.carpas[ci] = null
	var np := []
	var nm := []
	for h in huecos():
		var j := antes.find("%d:%d" % [int(h.c), int(h.j)])
		np.append(pots[j] if j >= 0 and pots[j] else null)
		nm.append(mac[j] if j >= 0 and mac[j] else "plastico7")
	S.pots = np
	S.macetas = nm
	montar_casa()

func embargo() -> void:
	var ci := -1
	for c in [1, 2]:
		if c < S.carpas.size() and S.carpas[c] and (ci < 0 or area_carpa(c) > area_carpa(ci)):
			ci = c
	await talk("TOÑO", ["Tres plazos tarde. Don Baltasar se cobra en especie."])
	if ci >= 0:
		var nc: String = D.CARPAS[S.carpas[ci].t].n
		quitar_carpa(ci)
		sfx("bad")
		await say("TOÑO se lleva tu %s, con su foco y sus plantas." % nc)
	else:
		var e := int(floor(S.money / 2.0))
		S.money -= e
		sfx("bad")
		await say("TOÑO te vacía los bolsillos: se lleva %s." % Datos.eur(e))

# el aviso de la orden de registro (1.11): un día antes de la redada
func aviso_orden():
	sfx("bad")
	await talk("SMS · KIKO", ["Me dice uno de la comisaría que mañana entran en tu piso con orden de registro.", "Esta noche, el dinero y los cogollos a la caja o fuera de casa. Las plantas no se pueden esconder.", "O paga a Molina, que aún estás a tiempo."])

# la redada (1.11): lo de fuera y las plantas, siempre; la caja fuerte, nunca. La multa (multa_redada) sale de lo de fuera y, si no
# llega, de la caja
func raid_event():
	S.orden = 0
	if S.protect:
		S.heat = 50
		await talk("SMS · MOLINA", ["Esta noche había orden de entrada en tu piso. La he parado.", "Baja el ritmo."])
		return
	sfx("bad")
	await say("REDADA. La policía entra en tu piso con una orden de registro.")
	var g := int(floor(total_buds() + arcon_g()))   # lo de encima y el arcón (1.10)
	var ro := total_rosin() + arcon_r()
	var hs := huecos()
	var npl := 0
	for p in S.pots:
		if p and not p.get("dead"):
			npl += 1
	var eq := []
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if c == null:
			continue
		var con := false
		for i in hs.size():
			if hs[i].c == ci and S.pots[i] and not (true if S.pots[i].get("dead") else false):
				con = true
		if not con:
			continue
		for k in D.EXTRAS:
			if c.get(k):
				var nm: String = D.EXTRAS[k].n.to_lower()
				if not eq.has(nm):
					eq.append(nm)
				c.erase(k)
				if k == "goteo":
					c.erase("dep")
				if k == "garrafas":
					c.erase("gar")
	var np := []
	for p in S.pots:
		np.append(null)
	S.pots = np
	S.buds = {}
	S.rosin = {}
	S.arcon = {"buds": {}, "rosin": {}}
	S.esquejes = []
	S.heat = D.CALOR_REDADA
	var multa := multa_redada(npl, g + Datos.jsround(ro / D.ROSIN.rend))   # el rosin, como la flor de la que sale
	var fine: float = multa - pagar_casa(multa)
	await say("Se llevan todas las plantas%s. Multa: %s." % [("%s y %s" % [(", %d g" % g) if g else "", rosin_txt(ro)]) if ro else " y %d g" % g, Datos.eur(fine)])
	if eq.size():
		await say("Y el equipo de las carpas con plantas: " + ", ".join(eq) + ".")
	await say("La caja de detrás del diploma ni la ven. Las semillas no son delito: se quedan." if S.get("caja") != null else "Las semillas no son delito: se quedan.")
	await say("Toca empezar de nuevo. Y vender menos una temporada.")

func ending() -> void:
	await fade(1)
	endcard_on = true
	endcard_pon(["DEUDA SALDADA", "Has saldado los %s de tu tía Maite en %s días." % [Datos.eur(D.DEUDA), n(S.day)], "Variedades: %d · Ventas totales: %s" % [disc_count(), Datos.eur(S.sales)],
		"Ahora empieza tu imperio: cuanto más factures, más carga Iñaki en el barco.\n¿Completarás la GENOTECA? ¿Conseguirás la JACK HERER?", "Pulsa A"])
	await fade(0)
	sfx("get")
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "START":
			pop()
			pr.res())
	await Motor.espera(pr)
	await fade(1)
	endcard_on = false
	endcard_pon(null)
	await fade(0)
	await chapter(8)
	show_objective()

# ---------- menú START (12-menus) ----------
func start_menu():
	var i := 0
	while true:   # 1.10: con su icono y lo que hay en cada uno, y arriba el día, la hora y el dinero
		var ns: int = S.sms.size()
		var vivas := 0
		for p in S.pots:
			if p and not p.get("dead"):
				vivas += 1
		var desc := 0
		for k in D.DEX:
			if S.disc.get(k):
				desc += 1
		i = await menu([{"label": "GENOTECA", "right": "%d/%d" % [desc, D.DEX.size()], "ic": icono("cogollo")}, {"label": "MOCHILA", "right": _kg(int(floor(peso_encima()))), "ic": icono("bolsa")},
			{"label": "MÓVIL", "right": ("%d SMS" % ns) if ns else null, "ic": icono("movil")}, {"label": "PLANTAS", "right": str(vivas), "ic": icono("maceta")},
			{"label": "OBJETIVO", "right": "cap. %d" % S.ch, "ic": icono("trofeo")}, {"label": "GUARDAR", "ic": icono("guardar")},
			{"label": "OPCIONES", "ic": icono("altavoz")}, {"label": "SALIR", "ic": icono("salir")}],
			{"cls": "start", "initial": i, "startCloses": true, "title": "DÍA %d · %s" % [S.day, reloj_txt()], "title2": Datos.eur(S.money)})
		if i < 0 or i == 7:
			return
		if i == 0:
			await genoteca()
		elif i == 1:
			await mochila()
		elif i == 2:
			await movil_menu()
		elif i == 3:
			await plantas()
		elif i == 4:
			await objetivo_menu()
		elif i == 5:
			await say("Partida guardada." if save() else "No se ha podido guardar la partida.")
		elif i == 6:
			await opciones()

func genoteca():
	var items := []
	var DEX: Array = D.DEX
	for j in DEX.size():
		var k: String = DEX[j]
		var s: Dictionary = D.STRAINS[k]
		var nn := "%02d" % (j + 1)
		if S.disc.get(k):
			items.append({"label": "%s %s" % [nn, s.n], "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "desc": strain_line(k) + (("\n" + s.h) if s.get("h") else "")})
		else:
			items.append({"label": nn + " ??????", "desc": "Sin descubrir."})
	var cust := []
	for k in S.custom:
		if S.disc.get(k):
			cust.append(k)
	for k in cust:
		var s: Dictionary = S.custom[k]
		items.append({"label": "★ " + s.n, "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "desc": strain_line(k)})
	var nd := 0
	for k in DEX:
		if S.disc.get(k):
			nd += 1
	var i := 0
	while true:
		i = await menu(items, {"cls": "full", "title": "GENOTECA", "title2": "%d/%d · %d propias" % [nd, DEX.size(), cust.size()], "desc": true, "initial": i})
		if i < 0:
			break

func mochila() -> void:
	var i := 0
	while true:
		var M: Dictionary = D.MOCHILAS[int(S.items.get("bolsa", 0))]
		var rows := [{"label": "Dinero", "right": Datos.eur(S.money), "ic": icono("billetes"), "desc": "Lo que llevas encima. Don Baltasar también lo cuenta."},
			{"label": M.n, "right": "%d de %s" % [int(floor(peso_encima())), _kg(int(M.g))], "ic": icono("bolsa"), "desc": "Cogollos y rosin que llevas encima. Lo que no cabe al cosechar va al arcón de casa."}]
		if arcon_g() >= 1 or arcon_r() >= .1:
			rows.append({"label": "Arcón", "right": arcon_txt(), "ic": icono("cogollo"), "desc": "En casa, entre la cama y la nevera. Un control en la calle no lo ve; una redada se lo lleva."})
		if S.get("caja"):
			var CJ: Dictionary = D.CAJA[S.caja.nivel]
			rows.append({"label": "Caja fuerte", "right": "%s · %d g%s" % [Datos.eur(caja_e()), int(floor(caja_g())), (" · " + Datos.coma(Datos.jsround(caja_r() * 10) / 10.0) + " g rosin") if caja_r() >= .1 else ""], "ic": icono("billetes"),
				"desc": "%s, detrás del diploma. Caben %s y %s.\nLo que está dentro no lo llevas encima." % [CJ.n, Datos.eur(CJ.money), _kg(int(CJ.g))]})
		rows.append_array([{"label": "Vida", "right": "%s/%s" % [n(S.hp), n(S.hpMax)], "desc": "Se recupera durmiendo, comiendo o con el tiempo."},
			{"label": "Abono (dosis)", "right": "×" + n(S.items.fert), "ic": icono("abono"), "desc": "De floración. Una por planta: +%d %% de cosecha, con el pH corregido." % Datos.jsround(D.ABONO.rend * 100)}])
		if S.items.get("fertv", 0) > 0:
			rows.append({"label": "Abono de crecimiento", "right": "×" + n(S.items.fertv), "ic": icono("abono"), "desc": "Una por planta en crecimiento: crece un %d %% más deprisa hasta florecer." % Datos.jsround(D.ABONO.veg * 100)})
		if S.items.get("phm", 0) > 0:
			rows.append({"label": "pH− (dosis)", "right": "×" + n(S.items.phm), "ic": icono("abono"), "desc": "Se gasta una con cada dosis de abono: baja el pH del agua al %s." % Datos.coma(D.ABONO.ph[2])})
		if S.items.get("medidor", 0):
			rows.append({"label": "Medidor de pH y EC", "right": "×1", "desc": "Con él corriges el pH justo y ves la EC y el pH de cada maceta en PLANTAS."})
		rows.append_array([{"label": "Insecticida (tratamientos)", "right": "×" + n(S.items.insect), "ic": icono("insecticida"), "desc": "Úsalo en una maceta con plaga."},
			{"label": "Spray de pimienta", "right": "×" + n(S.items.spray), "ic": icono("spray"), "desc": "Solo en combate."},
			{"label": "Bocata", "right": "×" + n(S.items.bocata), "ic": icono("bocadillo"), "desc": "Pulsa A para comerlo: +15 de vida.", "k": "bocata"}])
		for k in D.MACETAS:
			if S.items.get("m_" + k, 0) > 0:
				rows.append({"label": "Maceta " + D.MACETAS[k].n, "right": "×" + n(S.items["m_" + k]), "ic": icono("maceta"), "desc": desc_maceta(k) + "\nSe cambia en una plaza vacía de la carpa."})
		for k in D.FOCOS:
			if S.items.get("f_" + k, 0) > 0:
				rows.append({"label": "Foco " + D.FOCOS[k].n, "right": "×" + n(S.items["f_" + k]), "ic": icono(Atlas.ico_foco(k)), "desc": desc_foco(k) + "\nSe cuelga desde la vista de carpa: ▲ hasta el foco y A."})
		for k in D.EXTRAS:
			if S.items.get("x_" + k, 0) > 0:
				rows.append({"label": D.EXTRAS[k].n, "right": "×" + n(S.items["x_" + k]), "ic": icono(Atlas.ICX[k]), "desc": D.EXTRAS[k].d + "\nSe pone%s desde la vista de carpa: ▲ hasta el foco y A." % ("n" if D.EXTRAS[k].get("pl") else "")})
		for k in S.seeds:
			rows.append({"label": "Semilla " + strain(k).n, "right": "×" + n(S.seeds[k]), "sw": strain(k).c, "ic": icono("semillas"), "desc": strain_line(k)})
		for e in S.esquejes:
			rows.append({"label": "Esqueje " + strain(e.sid).n + marca_feno(e.f), "right": "día " + n(e.dia + D.ESQUEJE_DIAS), "sw": strain(e.sid).c, "ic": ic_cog(e.sid),
				"desc": "Enraizando en el propagador. Plántalo en una plaza vacía antes de que acabe el día %s." % n(e.dia + D.ESQUEJE_DIAS)})
		for k in S.buds:
			var b: Dictionary = S.buds[k]
			rows.append({"label": lot_nombre(k), "right": "%d g · %s%%" % [int(floor(b.g)), Datos.pct(b.thc)], "sw": strain(lot_sid(k)).c, "ic": ic_cog(lot_sid(k)),
				"desc": ("Cogollos de un fenotipo estrella, en lote aparte.\n" if k.ends_with("*") else "Cogollos listos para vender.\n") + strain(lot_sid(k)).o})
		for k in S.rosin:
			var b: Dictionary = S.rosin[k]
			rows.append({"label": "Rosin · " + lot_nombre(k), "right": "%s g · %s%%" % [Datos.coma(b.g), Datos.pct(b.thc)], "sw": "#d89a18", "ic": ic_cog(lot_sid(k)),
				"desc": "Rosin: extracción prensada sin disolventes. Lo compran los catadores.\n" + strain(lot_sid(k)).o})
		if S.items.get("prensa"):
			rows.append({"label": "Prensa de rosin", "right": "en la mesa", "desc": "De 5 g de cogollo, 1 g de rosin con el triple de THC. Se usa en la mesa del piso."})
		i = await menu(rows, {"cls": "full", "title": "MOCHILA", "title2": "%d g encima" % int(floor(total_buds())) + ((" · %d g en la caja" % int(floor(caja_g()))) if S.get("caja") else ""), "desc": true, "initial": i})
		if i < 0:
			return
		if rows[i].get("k") == "bocata":
			if S.items.bocata > 0 and S.hp < S.hpMax:
				S.items.bocata -= 1
				S.hp = mini(S.hpMax, S.hp + 15)
				sfx("get")
				toast("Te comes el bocata. +15 de vida", 1200)
			else:
				sfx("bump")

func plantas() -> void:
	var rows := []
	var H := huecos()
	var cl := Cultivo.clima_sala(S, is_night())
	rows.append({"label": "Sala", "right": t_clima(cl) if S.sala.get("termo") else "¿?", "desc": sala_desc() if S.sala.get("termo") else "Sin termohigrómetro no sabes la temperatura ni la humedad de la sala. Kiko lo vende."})
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if not c:
			continue
		var C: Dictionary = D.CARPAS[c.t]
		var F: Dictionary = D.FOCOS[c.foco]
		var wm2 := Datos.jsround(F.w / (C.cm[0] * C.cm[2] / 1e4))
		rows.append({"label": C.n, "right": F.n, "ic": icono(Atlas.ico_carpa(c.t)), "desc": "%s plantas · foco %s, %d W/m²%s\nLuz: %s al día con plantas · hasta %s W, macetas de %s L y %d L de tierra (%d puestos).\n%s%s" % [n(C.plazas), F.n, wm2,
			" (poca luz: crecen más despacio y con menos THC)" if wm2 < D.W_M2 else "", Datos.eur(luz_carpa(ci)), n(C.wmax), n(C.lmax), litros_max(ci), litros_carpa(ci),
			Cultivo.ext_txt(S, ci), (" · dentro, de día " + t_clima(Cultivo.clima_carpa(S, ci, false))) if S.sala.get("termo") and plantas_vivas(ci) else ""]})
		for i in H.size():
			var h: Dictionary = H[i]
			if h.c != ci:
				continue
			var p = S.pots[i]
			var Mc: Dictionary = D.MACETAS[S.macetas[i]]
			if not p:
				rows.append({"label": "  %d · vacía" % (h.j + 1), "right": n(Mc.l) + " L", "ic": icono("maceta"), "desc": "Maceta de %s. Planta algo desde la carpa de tu piso." % Mc.n})
				continue
			var s = strain(p.sid)
			var desc := "Se ha secado. Retírala." if p.get("dead") else "%s · Agua %d%% · Salud %d%%\n%s%s · maceta de %s." % ["Lista para cosechar" if p.prog >= 1 else stage_name(p), Datos.jsround(p.water),
				Datos.jsround(p.health), "PLAGA: trátala con insecticida. " if p.pest else "", abono_txt(p), Mc.n]
			rows.append({"label": "  %d · %s%s" % [h.j + 1, s.n, marca_feno(p.get("f"))], "sw": s.c, "ic": ic_cog(p.sid),
				"right": "muerta" if p.get("dead") else ("LISTA" if p.prog >= 1 else "%d%%" % int(floor(p.prog * 100))), "desc": desc})
	var luz := factura_luz()
	var i := 0
	while true:
		i = await menu(rows, {"cls": "full", "title": "CULTIVO", "title2": ("Luz " + Datos.eur(luz) + "/día") if luz else "Luz apagada", "desc": true, "initial": i})
		if i < 0:
			break

# ---------- combate (13-combate) ----------
static func hp_col(f: float) -> Color:
	return Color("#58d080") if f > .5 else (Color("#f0c040") if f > .2 else Color("#f05050"))

func bhud_datos() -> Dictionary:
	var f: float = B.hp / float(B.hpMax) if B.kind == "thief" else S.heat / 100.0
	var pf: float = S.hp / float(S.hpMax)
	return {"e": [B.name, "VIDA" if B.kind == "thief" else "SOSP.", maxf(0, f), hp_col(f) if B.kind == "thief" else Color("#e05050")],
		"p": [S.name, "%d g" % int(floor(total_buds())), maxf(0, pf), hp_col(pf), "%s/%s · %s" % [n(S.hp), n(S.hpMax), Datos.eur(S.money)]]}

func bhud_build() -> void:
	bhud_pon(bhud_datos())

func bhud_act() -> void:
	if B:
		bhud_pon(bhud_datos())

# el texto de la caja sin esperar a nadie (las preguntas del combate, con el menú al lado)
func prompt(t: String) -> void:
	if oraculo:
		return
	dlg.show()
	dlg_nm.hide()
	dlg_more.hide()
	dlg_txt.text = nm(t)
	_coloca.call_deferred()

func grupo_combate(who: String):
	if not Atlas.ok or B == null:
		return null
	if who == "P":
		return Atlas.cubre("combate:espalda:player")
	if B.kind == "thief":
		var g = Atlas.grupo_look(B.look)
		return g if g else Atlas.cubre("combate:frente:ladron")
	return Atlas.cubre("combate:frente:policia")

# lanza una animación de combate; devuelve su duración en ms
func b_anim(who: String, nn: String) -> float:
	var g = grupo_combate(who)
	if not g or Atlas.anim_de(g, nn) == null:
		return 0.0
	B["a" + who] = {"n": nn, "t0": M.reloj}
	return Atlas.duracion(g, nn)

func vfx_combate(id: String, x: float, y: float) -> void:
	if Atlas.ok:
		lanzar_vfx(id, x, y, M.reloj, "*", false)

func battle(kind):
	if gancho_combate.is_valid():
		await gancho_combate.call(kind)
		return null
	lock += 1
	var res = null
	music("battle")
	sfx("enc")
	for k in 3:
		fade_pon(.85, true, true)
		await wait(70)
		fade_pon(0, true, true)
		await wait(70)
	wipe_go()
	await wait(480)
	var ch: int = S.ch
	if kind == "thief":
		var nm_: String = pick(D.THIEVES)
		B = {"kind": kind, "name": nm_, "look": Datos.rand_look("th" + Datos.js_num(Cultivo.azar()), "thief"), "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
		# desde el capítulo 5 (1.10), ladrones más duros: +4 de vida y +1 a cada golpe
		var dd := 1 if ch >= 5 else 0
		B.hpMax = 12 + ch * 2 + ri(0, 4) + 4 * dd
		B.hp = B.hpMax
		B.atk = [2 + (ch >> 2) + dd, 4 + (ch >> 1) + dd]
	else:
		B = {"kind": kind, "name": pick(D.COPS), "look": D.LOOKS.cop, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	mode = "battle"
	update_hud()
	wipe_fuera()
	await wait(650)
	bhud_build()
	if kind == "thief":
		await say("Un %s te corta el paso." % B.name.to_lower())
		await say(pick(["«La mochila. Dámela y no pasa nada.»", "«Eh, tú. Sé lo que llevas encima.»", "«Quieto. El dinero y lo que lleves.»"]), B.name)
	else:
		b_anim("E", "alto")
		await say("%s te da el alto." % B.name)
		await say(pick(["«Control rutinario. ¿Llevas algo encima?»", "«Documentación. Y vacía los bolsillos.»", "«Aquí huele a marihuana. ¿Es tuya?»"]), B.name)
	while not res:
		if kind == "thief":
			res = await thief_round()
		else:
			res = await cop_round()
	bhud_pon(null)
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
		menu_box.hide()
	await fade(1)
	mode = "world"
	B = null
	if res == "ko":
		advance_time(360)
		S.hp = S.hpMax
		enter_map("home", 2, 4, "down")
	else:
		music(map_music())
	update_hud()
	await fade(0)
	if res == "ko":
		await say("Te despiertas en casa con la cabeza vendada. Un vecino te encontró en el portal.")
	S.cool = 25
	heat_warn()
	lock -= 1

func enemy_hits():
	var dmg := ri(int(B.atk[0]), int(B.atk[1]))
	b_anim("E", "ataque")
	await say("El %s %s." % [B.name.to_lower(), pick(["te golpea", "te empuja contra un portal", "te da una patada", "te tira al suelo"])])
	b_anim("P", "herido")
	vfx_combate("vfx-golpe", 64, 112)
	B.shakeP = 450.0
	sfx("hurt")
	S.hp = maxi(0, S.hp - dmg)
	bhud_act()
	await wait(450)
	if S.hp <= 0:
		b_anim("P", "desmayo")
		await say("Pierdes el conocimiento.")
		var lost := 0
		for b in S.buds.values():
			var l := int(floor(b.g / 2))
			lost += l
			b.g -= l
		for k in S.buds.keys():
			if S.buds[k].g < .5:
				S.buds.erase(k)
		var lr := 0.0
		for k in S.rosin.keys():   # y la mitad del rosin (1.10)
			var qr: float = Datos.jsround(S.rosin[k].g * 5) / 10.0
			lr += qr
			use_rosin(k, qr)
		var lm := Datos.jsround(S.money * .3)
		S.money -= lm
		await say("Te roba %d g%s y %s." % [lost, (", " + rosin_txt(lr)) if lr > 0 else "", Datos.eur(lm)])
		return "ko"
	return null

func thief_round():
	prompt("¿Qué haces?")
	var c: int = await menu(["LUCHAR", "MOCHILA", "HABLAR", "HUIR"], {"cls": "battle", "cancel": false})
	if c == 0:
		prompt("Elige un golpe.")
		var m: int = await menu(["PUÑETAZO", "PATADA"], {"cls": "battle"})
		if m < 0:
			return null
		var mv := {"n": "PATADA", "acc": .65, "d": [8, 12]} if m else {"n": "PUÑETAZO", "acc": .92, "d": [4, 7]}
		await wait(b_anim("P", "patada" if m else "golpe") * .6)
		await say("Le das una patada." if mv.n == "PATADA" else "Le das un puñetazo.")
		if Cultivo.azar() < mv.acc:
			var d := ri(mv.d[0], mv.d[1])
			b_anim("E", "herido")
			vfx_combate("vfx-golpe", 178, 40)
			B.flashE = 500.0
			sfx("hit")
			B.hp -= d
			bhud_act()
			await wait(500)
			if m and d >= 11:
				await say("Le has hecho daño de verdad.")
		else:
			await say("Fallas.")
	elif c == 1:
		prompt("¿Qué usas?")
		var it: int = await menu([{"label": "SPRAY ×%s" % n(S.items.spray), "ic": icono("spray")}, {"label": "BOCATA ×%s" % n(S.items.bocata), "ic": icono("bocadillo")}], {"cls": "battle"})
		if it < 0:
			return null
		if it == 0:
			if not S.items.spray:
				await say("No te queda SPRAY.")
				return null
			S.items.spray -= 1
			b_anim("P", "spray")
			vfx_combate("vfx-spray", 178, 48)
			await say("Le echas SPRAY DE PIMIENTA a la cara.")
			b_anim("E", "herido")
			B.flashE = 700.0
			sfx("hit")
			B.hp -= ri(12, 16)
			bhud_act()
			await wait(500)
			await say("No puede abrir los ojos.")
		else:
			if not S.items.bocata:
				await say("No te quedan BOCATAS.")
				return null
			S.items.bocata -= 1
			b_anim("P", "comer")
			S.hp = mini(S.hpMax, S.hp + 15)
			sfx("get")
			bhud_act()
			await say("Te comes un BOCATA. Recuperas vida.")
	elif c == 2:
		await say("%s: «Tranquilo. Somos del mismo barrio.»" % S.name)
		if Cultivo.azar() < clampf(.25 + S.rep / 300.0, .25, .7):
			await say("«Vale... Tú eres el de Maite. Olvídalo.»")
			return "talk"
		await say("«No me cuentes historias.»")
	elif c == 3:
		if Cultivo.azar() < .5:
			sfx("door")
			await say("Consigues escapar.")
			return "flee"
		await say("Te corta el paso. No puedes escapar.")
	if B.hp <= 0:
		B.gone = true
		b_anim("E", "huir")
		await say("El %s sale corriendo." % B.name.to_lower())
		var loot: int = ri(20, 40) + S.ch * 10
		S.money += loot
		S.rep += 2
		sfx("coin")
		bhud_act()
		await say("Al huir se le cae la cartera: +%s." % Datos.eur(loot))
		if S.hpMax < 60:
			S.hpMax += 2
			S.hp += 2
			bhud_act()
			await say("Aguantas más. VIDA máxima: %d." % S.hpMax)
		return "win"
	return await enemy_hits()

# devuelve lo requisado en texto (cogollos y, si hay, rosin) y la multa
func confiscate(extra_fine := true) -> Array:
	var g := int(floor(total_buds()))
	var ro := total_rosin()
	var fine = min(S.money, int(D.MULTA_CALLE)) if extra_fine else 0
	if B:
		b_anim("E", "multa")
	S.buds = {}
	S.rosin = {}
	S.money -= fine
	S.heat = max(0, S.heat - 15)
	return ["%d g%s" % [g, (" y " + rosin_txt(ro)) if ro else ""], fine]

# el soborno (1.10) sube también con el dinero que llevas encima: un 5 %
func precio_soborno() -> int:
	return Datos.jsround(40 + S.heat * 4 + carga_sosp() * .5 + S.money * .05)

func cop_round():
	var cost := precio_soborno()
	prompt("¿Qué haces?")
	var c: int = await menu(["SOBORNAR", "HABLAR", "HUIR", "ENTREGAR"], {"cls": "battle", "cancel": false})
	if c == 0:
		if await ask("¿Ofrecerle %s con disimulo?" % Datos.eur(cost), ["Sí", "No"]) != 0:
			return null
		if S.money < cost:
			await say("No llevas tanto dinero encima.")
			return null
		if not S.protect and S.ch >= 3 and Cultivo.azar() < .15:
			await say("%s: «¿Me intentas sobornar a mí? Esto me lo quedo.»" % B.name)
			var r := confiscate()
			S.heat = min(100, S.heat + 20)
			sfx("bad")
			await say("Te requisan %s y te multan con %s." % [r[0], Datos.eur(r[1])])
			return "caught"
		S.money -= cost
		S.heat = max(0, S.heat - 10)
		sfx("coin")
		bhud_act()
		b_anim("E", "soborno")
		await say("%s se guarda el sobre. «Aquí no ha pasado nada.»" % B.name)
		return "bribe"
	if c == 1:
		await say("%s: «Solo estaba dando un paseo, agente.»" % S.name)
		if Cultivo.azar() < clampf(.3 + S.rep / 250.0 - S.heat / 300.0, .1, .85):
			await say("%s: «Bien. Circula.»" % B.name)
			return "talk"
		await say("%s: «No. Vacía los bolsillos.»" % B.name)
		var r := confiscate()
		sfx("bad")
		bhud_act()
		await say("Te requisan %s y te multan con %s." % [r[0], Datos.eur(r[1])])
		return "caught"
	if c == 2:
		if Cultivo.azar() < .45 + (.15 if is_night() else 0.0):
			sfx("door")
			S.heat = min(100, S.heat + 8)
			await say("Sales corriendo entre los coches y lo pierdes.")
			return "flee"
		b_anim("E", "perseguir")
		await say("%s te alcanza y te reduce en el suelo." % B.name)
		var r := confiscate()
		S.hp = maxi(1, S.hp - 5)
		sfx("hurt")
		bhud_act()
		await say("Te requisan %s y te multan con %s." % [r[0], Datos.eur(r[1])])
		return "caught"
	var r := confiscate(false)
	bhud_act()
	await say("Le entregas %s. «Buena decisión. Por esta vez, sin multa.»" % r[0])
	return "caught"

# ---------- la caja fuerte, el robo de Darko y los encargos de Baltasar (1.10, 11b-caja) ----------
# la caja: C, la de la tía Maite, detrás del diploma de la Copa de 1998 (la pista está en sus notas del ordenador): 20.000 € y
# 2 kg; B, la empotrada, por el ordenador desde el capítulo 4 (CAJA_P, la instala Kiko al día siguiente): 50.000 € y 2,5 kg.
# Lo que hay dentro no va encima: no cuenta para los encuentros ni te lo quitan un control, un ladrón o Darko. En una redada no la
# tocan (1.11: raid_event; solo pagan de ella la multa que no llegue de fuera). La luz y lo que se compra por el ordenador se pagan de fuera y, si no llega, de la caja
func diploma_action():
	if S.get("caja"):
		await caja_action()
		return
	if await ask("Un diploma enmarcado: «COPA DE RIBERA 1998 · 2º PREMIO: MAITE».", ["Mirar detrás", "Dejarlo"]) != 0:
		return
	await say("Detrás del marco hay una caja fuerte empotrada en la pared. Tiene una rueda de cuatro cifras.")
	var ops := ["1976", "1979", "1987", "1998"]
	var j: int = await ask("¿Qué combinación pruebas?", ops + ["Dejarlo"])
	if j < 0 or j >= ops.size():
		return
	if int(ops[j]) != int(D.CAJA_ANIO):
		sfx("bump")
		await say("Clac. No se abre.")
		return
	S.caja = {"money": int(D.MAITE_CAJA), "buds": {}, "nivel": 1}
	sfx("get")
	await say("Clic. La caja se abre.")
	await say("Dentro hay %s y una nota de la tía: «Para ti, {N}. Lo que guardes aquí no te lo quita nadie en la calle»." % Datos.eur(D.MAITE_CAJA))
	await say("Caben %s y %s. Lo que está dentro no lo llevas encima." % [Datos.eur(D.CAJA[1].money), _kg(int(D.CAJA[1].g))])

# cuánto: los pasos que caben por debajo del máximo y el máximo; 0 si no eliges nada
func cuanto(txt: String, mx: float, pasos: Array, fmt: Callable):
	var ops := []
	for v in pasos:
		if v < mx:
			ops.append(v)
	ops.append(mx)
	var o := ops.map(fmt)
	o.append("Nada")
	var j: int = await ask(txt, o)
	return ops[j] if j >= 0 and j < ops.size() else 0

static func g_txt(g: float) -> String:
	return "%d g" % int(floor(g))

# «300 € y 50 g», «300 €, 50 g y 2 g de rosin» o, sin cogollos, «300 € y 2 g de rosin»
func lo_que(e: float, g: float, r: float) -> String:
	var L := [Datos.eur(e)]
	if g >= 1 or r < .1:
		L.append(g_txt(g))
	if r >= .1:
		L.append(rosin_txt(r))
	return ", ".join(L.slice(0, -1)) + " y " + L[-1]

# lo que cabe todavía en la caja (los cogollos y el rosin comparten el hueco); el del rosin, al décimo de gramo
func _hueco(C: Dictionary) -> float:
	return C.g - caja_g() - caja_r()

func _hueco_r(C: Dictionary) -> float:
	return floor(_hueco(C) * 10 + 1e-9) / 10.0

func caja_action():
	while true:
		var C: Dictionary = D.CAJA[int(S.caja.nivel)]
		var ro: bool = (true if S.items.get("prensa") else false) or caja_r() > 0   # con la prensa (o rosin dentro), también el rosin
		var ops := ["Guardar todo", "Guardar dinero", "Guardar cogollos"] + (["Guardar rosin"] if ro else []) + ["Sacar dinero", "Sacar cogollos"] + (["Sacar rosin"] if ro else []) + ["Sacar todo", "Cerrar"]
		var oi: int = await ask("%s: %s (caben %s y %s).\nEncima: %s." % [C.n, lo_que(S.caja.money, caja_g(), caja_r()), Datos.eur(C.money), _kg(int(C.g)),
			lo_que(S.money, total_buds(), total_rosin())], ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Cerrar":
			return
		if op == "Guardar todo":
			var e: float = minf(S.money, C.money - S.caja.money)
			S.money -= e
			S.caja.money += e
			var g := 0.0
			var r := 0.0
			for k in S.buds.keys():
				var q: float = minf(S.buds[k].g, _hueco(C))
				if q < .5:   # menos de medio gramo no es un lote (mover_lote)
					break
				g += q
				mover_lote(S.buds, S.caja.buds, k, q)
			for k in S.rosin.keys():
				var q: float = minf(S.rosin[k].g, _hueco_r(C))
				if q < .1:
					break
				if not S.caja.get("rosin"):
					S.caja.rosin = {}
				r += q
				mover_rosin(S.rosin, S.caja.rosin, k, q)
			sfx("sel")
			await say("Guardas %s.%s" % [lo_que(e, g, r), " No cabe todo: el resto se queda fuera." if S.money >= 1 or total_buds() >= 1 or total_rosin() >= .1 else ""])
		elif op == "Sacar todo":   # los gramos, hasta el tope de la mochila (1.10)
			var e: float = S.caja.money
			var g := 0.0
			var r := 0.0
			S.money += e
			S.caja.money = 0
			for k in S.caja.buds.keys():
				var q: float = minf(S.caja.buds[k].g, floor(libre_mochila()))
				if q < .5:
					break
				g += q
				mover_lote(S.caja.buds, S.buds, k, q)
			if S.caja.get("rosin") != null:
				for k in S.caja.rosin.keys():
					var q: float = minf(S.caja.rosin[k].g, floor(libre_mochila() * 10 + 1e-9) / 10.0)
					if q < .1:
						break
					r += q
					mover_rosin(S.caja.rosin, S.rosin, k, q)
				if S.caja.rosin.is_empty():
					S.caja.erase("rosin")
			sfx("sel")
			await say("Sacas %s.%s" % [lo_que(e, g, r), " No te cabe todo encima: el resto se queda en la caja." if caja_g() >= .5 or caja_r() >= .1 else ""])
		elif op == "Guardar rosin" or op == "Sacar rosin":
			var mete := op == "Guardar rosin"
			var de: Dictionary = S.rosin if mete else S.caja.get("rosin", {})
			var lots := []
			for k in de:
				lots.append([k, de[k]])
			if lots.is_empty():
				await say("No llevas rosin encima." if mete else "La caja no tiene rosin.")
				continue
			if mete and _hueco_r(C) < .1:
				await say("No cabe más.")
				continue
			if not mete and libre_mochila() < .1:
				await say("No te cabe nada más encima.")
				continue
			var it := lots.map(rosin_item)
			it.append({"label": "Nada"})
			var i: int = await menu(it, {"cls": "right", "title": "¿Qué guardas?" if mete else "¿Qué sacas?"})
			if i < 0 or i >= lots.size():
				continue
			var k: String = lots[i][0]
			var b: Dictionary = lots[i][1]
			var g = await cuanto("Rosin · %s: ¿cuánto?" % lot_nombre(k), minf(b.g, _hueco_r(C)) if mete else minf(b.g, floor(libre_mochila() * 10 + 1e-9) / 10.0), [1, 5, 10, 50], func(v): return Datos.coma(v) + " g")
			if not g:
				continue
			if mete and not S.caja.get("rosin"):
				S.caja.rosin = {}
			mover_rosin(de, S.caja.rosin if mete else S.rosin, k, g)
			if not mete and S.caja.rosin.is_empty():
				S.caja.erase("rosin")
			sfx("sel")
		elif op == "Guardar dinero" or op == "Sacar dinero":
			var mete := op == "Guardar dinero"
			var mx: float = minf(S.money, C.money - S.caja.money) if mete else float(S.caja.money)
			if mx < 1:
				await say(("No llevas dinero encima." if S.money < 1 else "No cabe más dinero.") if mete else "La caja no tiene dinero.")
				continue
			var e = await cuanto("¿Cuánto guardas?" if mete else "¿Cuánto sacas?", mx, [100, 500, 1000, 5000, 10000, 20000], func(v): return Datos.eur(v))
			if not e:
				continue
			S.money += -e if mete else e
			S.caja.money += e if mete else -e
			sfx("sel")
		else:
			var mete := op == "Guardar cogollos"
			var de: Dictionary = S.buds if mete else S.caja.buds
			var a: Dictionary = S.caja.buds if mete else S.buds
			var lots := []
			for k in de:
				lots.append([k, de[k]])
			if lots.is_empty():
				await say("No llevas cogollos encima." if mete else "La caja no tiene cogollos.")
				continue
			if mete and _hueco(C) < 1:
				await say("No caben más cogollos.")
				continue
			if not mete and libre_mochila() < 1:
				await say("No te cabe nada más encima.")
				continue
			var it := lots.map(lot_item)
			it.append({"label": "Nada"})
			var i: int = await menu(it, {"cls": "right", "title": "¿Qué guardas?" if mete else "¿Qué sacas?"})
			if i < 0 or i >= lots.size():
				continue
			var k: String = lots[i][0]
			var b: Dictionary = lots[i][1]
			var g = await cuanto("%s: ¿cuánto?" % lot_nombre(k), minf(b.g, _hueco(C)) if mete else minf(b.g, floor(libre_mochila())), [10, 50, 100, 500, 1000], func(v): return g_txt(v))
			if not g:
				continue
			mover_lote(de, a, k, g)
			sfx("sel")

# el ordenador: las notas de la tía (la pista de la combinación) y la caja empotrada
func notas_tia():
	await talk("NOTAS DE LA TÍA", ["«Veinte años de cultivos, apuntados día a día.»", "«Lo que no quiero llevar a la calle lo guardo detrás de mi premio. La combinación, el año en que lo gané.»"])

func pedir_caja():
	var C2: Dictionary = D.CAJA[2]
	if await ask("Caja empotrada: %s y %s. Kiko la instala mañana detrás del diploma, con lo que ya tengas dentro. %s." % [Datos.eur(C2.money), _kg(int(C2.g)), Datos.eur(D.CAJA_P)], ["Pedirla", "Nada"]) != 0:
		return
	if S.money + caja_e() < D.CAJA_P:
		sfx("bad")
		await say("No te llega el dinero.")
		return
	pagar_casa(D.CAJA_P)
	S.caja.mejora = 1
	sfx("coin")
	toast("Pedida: caja empotrada · llega mañana", 1400)

func instalar_caja():
	if not S.get("caja") or not S.caja.get("mejora"):
		return
	S.caja.erase("mejora")
	S.caja.nivel = 2
	queue("caja", func():
		sfx("get")
		await talk("SMS · KIKO", ["Ya está: la caja empotrada, detrás del diploma. Lo de la vieja lo tienes dentro.", "Caben %s y %s." % [Datos.eur(D.CAJA[2].money), _kg(int(D.CAJA[2].g))]]))

# el robo de Darko: la primera noche del capítulo 7 que duermes con más de 1.000 € o 100 g fuera de la caja (el rosin cuenta
# como la flor de la que sale: gramos_flor), se llevan la mitad
func robo_darko():
	S.flags.robo = true
	var e := int(floor(S.money / 2.0))
	var g := 0
	var r := 0.0
	for k in S.buds:
		var b: Dictionary = S.buds[k]
		var l := int(floor(b.g / 2.0))
		g += l
		b.g -= l
	for k in S.buds.keys():
		if S.buds[k].g < .5:
			S.buds.erase(k)
	for k in S.rosin.keys():   # y la mitad del rosin, como un ladrón
		var q: float = Datos.jsround(S.rosin[k].g * 5) / 10.0
		r += q
		use_rosin(k, q)
	var A: Dictionary = S.arcon   # y la mitad de lo del arcón (1.10)
	for k in A.buds.keys():
		var l := int(floor(A.buds[k].g / 2.0))
		g += l
		A.buds[k].g -= l
		if A.buds[k].g < .5:
			A.buds.erase(k)
	for k in A.rosin.keys():
		var q: float = Datos.jsround(A.rosin[k].g * 5) / 10.0
		r += q
		A.rosin[k].g = Datos.jsround((A.rosin[k].g - q) * 10) / 10.0
		if A.rosin[k].g < .1:
			A.rosin.erase(k)
	S.money -= e
	sfx("bad")
	await say("Te despierta un portazo. La cerradura está forzada y el piso, revuelto.")
	await say("Se han llevado %s.%s" % [lo_que(e, g, r), " La caja de detrás del diploma sigue cerrada." if S.get("caja") else ""])
	await talk("SMS · DARKO", ["Te dije que esto no se acababa ahí."])
	if not S.get("caja"):
		await say("Si la tía guardaba sus cosas en algún sitio, ahora te vendría bien saber dónde.")
	save()

# los encargos de Baltasar (capítulo 8): llevar ENCARGO[nivel del imperio] gramos al almacén de los astilleros, de noche, en 2 días,
# a PAGO_ENCARGO €/g. Si no llegas, reputación −10 y 5 días sin encargos
func encargo_baltasar(N: String):
	if S.get("encargo"):
		await say("Toño te espera en el almacén de los astilleros, de noche, con %s. Hasta el día %s." % [_kg(int(S.encargo.g)), n(S.encargo.hasta)], N)
		return
	if S.get("encVeto", 0) > S.day:
		await say("Me fallaste, {N}. Vuelve el día %s." % n(S.encVeto), N)
		return
	var g := int(D.ENCARGO[imperio_nivel()])
	var pe := int(D.PAGO_ENCARGO)
	await talk(N, ["Ya no me debes nada, {N}. Pero tengo trabajo, si lo quieres.", "%s en el almacén de los astilleros, de noche. Toño los recoge." % _kg(g),
		"Pago %d € el gramo: %s. Tienes %d días." % [pe, Datos.eur(g * pe), int(D.ENCARGO_DIAS)]])
	if await ask("¿Aceptas el encargo?", ["Aceptar", "No"], N) != 0:
		await say("Tú sabrás. La oferta sigue en pie.", N)
		return
	S.encargo = {"g": g, "hasta": S.day + int(D.ENCARGO_DIAS)}
	await say("Toño estará allí cada noche hasta el día %s. No le hagas esperar." % n(S.encargo.hasta), N)
	show_objective()

func talk_tono_almacen():
	var N := "TOÑO"
	if S.get("encargo") == null:   # vencido con él delante (sigue en pantalla hasta el próximo build_ents)
		await say("El plazo se acabó. Don Baltasar ya te escribirá.", N)
		return
	var E: Dictionary = S.encargo
	if not is_night():
		await say("¿De día? ¿Tú estás loco? Vuelve de noche, a partir de las nueve.", N)
		return
	if total_buds() < E.g:
		await say("Don Baltasar dijo %s. Llevas %s. Vuelve con todo." % [_kg(int(E.g)), g_txt(total_buds())], N)
		return
	if await ask("¿Entregas %s? Toño se lleva primero los lotes más flojos." % _kg(int(E.g)), ["Entregar", "Todavía no"], N) != 0:
		return
	var q: float = E.g
	var ls := []
	for k in S.buds:
		ls.append([k, S.buds[k].thc, ls.size()])
	ls.sort_custom(func(a, b): return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))
	for l in ls:
		var k: String = l[0]
		var t: float = minf(q, S.buds[k].g)
		use_buds(k, t)
		q -= t
		if q <= 0:
			break
	var e: int = int(E.g) * int(D.PAGO_ENCARGO)
	S.money += e
	S.sales += e
	S.heat = min(100, S.heat + 3)
	S.rep += 2
	S.encargo = null
	sfx("coin")
	toast("+%s · encargo de Don Baltasar" % Datos.eur(e), 1600)
	await say("Contado. Don Baltasar estará contento.", N)
	await fade(1)
	build_ents()
	await fade(0)
	show_objective()
	await check_story()

func vencer_encargo():
	if not S.get("encargo") or S.day <= S.encargo.hasta:
		return
	S.encargo = null
	S.rep = max(0, S.rep - 10)
	S.encVeto = S.day + int(D.ENCARGO_VETO)
	queue("encargo", func(): await talk("SMS · TOÑO", ["No apareciste. Don Baltasar no se olvida.", "Reputación −10. Nada de encargos hasta el día %s." % n(S.encVeto)]))

# ---------- la sala (1.10, 09c-sala): clima y arcón ----------
func t_clima(cl: Dictionary) -> String:
	return "%s °C · %s %%" % [Datos.coma(cl.t), n(cl.hr)]

func _mal(cl: Dictionary) -> String:
	var L := []
	if cl.t < D.T_OK[0]:
		L.append("frío")
	if cl.t > D.T_OK[1]:
		L.append("calor")
	if cl.hr < D.HR_OK[0]:
		L.append("seco")
	if cl.hr > D.HR_OK[1]:
		L.append("húmedo")
	return (" (" + ", ".join(L) + ")") if L.size() else ""

func sala_desc() -> String:
	var d := Cultivo.clima_sala(S, false)
	var nc := Cultivo.clima_sala(S, true)
	var ap := []
	for k in D.APARATOS:
		if k != "termo" and S.sala.get(k):
			ap.append(D.APARATOS[k].n)
	var mes: String = D.MESES[Cultivo.mes_de(int(S.day))]
	var fs := Cultivo.factura_sala(S)
	return "%s · de día %s%s · de noche %s%s\nBien: %s-%s °C y %s-%s %%. Aparatos: %s%s." % [mes.substr(0, 1).to_upper() + mes.substr(1), t_clima(d), _mal(d), t_clima(nc), _mal(nc),
		n(D.T_OK[0]), n(D.T_OK[1]), n(D.HR_OK[0]), n(D.HR_OK[1]), ", ".join(ap) if ap.size() else "ninguno", (" · " + Datos.eur(fs) + " al día") if fs else ""]

func arcon_txt() -> String:
	return ("%s y %s" % [g_txt(arcon_g()), rosin_txt(arcon_r())]) if arcon_r() >= .1 else g_txt(arcon_g())

func arcon_action():
	while true:
		var ops := ["Guardar todo", "Guardar un lote", "Sacar un lote", "Cerrar"]
		var oi: int = await ask("El arcón: %s.\nEncima: %s de %s." % [arcon_txt(), g_txt(peso_encima()), _kg(int(cap_mochila()))], ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Cerrar":
			return
		if op == "Guardar todo":
			var g := total_buds()
			var r := total_rosin()
			if g < .5 and r < .1:
				await say("No llevas nada que guardar.")
				continue
			for k in S.buds.keys():
				mover_lote(S.buds, S.arcon.buds, k, S.buds[k].g)
			for k in S.rosin.keys():
				mover_rosin(S.rosin, S.arcon.rosin, k, S.rosin[k].g)
			sfx("sel")
			await say("Guardas %s en el arcón." % [("%s y %s" % [g_txt(g), rosin_txt(r)]) if r >= .1 else g_txt(g)])
			continue
		var mete := op == "Guardar un lote"
		var B: Dictionary = S.buds if mete else S.arcon.buds
		var Ro: Dictionary = S.rosin if mete else S.arcon.rosin
		var lots := []
		for k in B:
			lots.append([[k, B[k]], 0])
		for k in Ro:
			lots.append([[k, Ro[k]], 1])
		if lots.is_empty():
			await say("No llevas nada encima." if mete else "El arcón está vacío.")
			continue
		if not mete and libre_mochila() < .1:
			await say("No te cabe nada más encima.")
			continue
		var items := []
		for l in lots:
			items.append(rosin_item(l[0]) if l[1] else lot_item(l[0]))
		items.append({"label": "Nada"})
		var i: int = await menu(items, {"cls": "right", "title": "¿Qué guardas?" if mete else "¿Qué sacas?"})
		if i < 0 or i >= lots.size():
			continue
		var k: String = lots[i][0][0]
		var b: Dictionary = lots[i][0][1]
		var ro: bool = lots[i][1] == 1
		var tope: float = b.g if mete else minf(b.g, libre_mochila())
		var mx: float = floor(tope * 10 + 1e-9) / 10.0 if ro else floor(tope)
		if mx < (.1 if ro else 1.0):
			await say("No te cabe encima.")
			continue
		var g = await cuanto("%s%s: ¿cuánto?" % ["Rosin · " if ro else "", lot_nombre(k)], mx, [1, 5, 10, 50] if ro else [10, 50, 100, 500, 1000],
			(func(q): return Datos.coma(q) + " g") if ro else (func(q): return g_txt(q)))
		if not g:
			continue
		if ro:
			mover_rosin(Ro, S.arcon.rosin if mete else S.rosin, k, g)
		else:
			mover_lote(B, S.arcon.buds if mete else S.buds, k, g)
		sfx("sel")

# ---------- el móvil (1.10, 12b-movil) ----------
func reloj_txt() -> String:
	return "%02d:%02d" % [int(S.min) / 60, int(S.min) % 60]

func movil_menu():
	while true:
		var ops := ["Llamar"]
		if S.flags.get("kiko1"):
			ops.append("Pedir a Kiko")
		ops.append_array(["Mensajes", "Tienda online", "Colgar"])
		var ns: int = S.sms.size()
		var oi: int = await ask("MÓVIL · día %s, %s%s" % [n(S.day), reloj_txt(), (" · %d mensaje%s" % [ns, "s" if ns > 1 else ""]) if ns else ""], ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Colgar":
			return
		if op == "Llamar":
			if await llamar():
				return
		elif op == "Pedir a Kiko":
			await pedir_kiko()
		elif op == "Tienda online":
			await tienda_online()
		else:
			await mensajes()

# devuelve true si ha venido un cliente (el móvil se cierra)
func llamar() -> bool:
	var C := []
	if S.flags.get("kiko1"):
		C.append({"label": "Kiko", "right": "growshop", "desc": "Consejos de cultivo. Los pedidos, desde «Pedir a Kiko».", "k": "kiko"})
	if S.flags.get("tono"):
		C.append({"label": "Toño", "right": "Don Baltasar", "desc": "Lo que debes y hasta cuándo.", "k": "tono"})
	if S.flags.get("inaki"):
		C.append({"label": "Iñaki", "right": "muelle", "desc": "Compra al por mayor.", "k": "inaki"})
	for f in S.fijos:
		C.append({"label": f.n, "right": D.CTYPES[f.t].label.to_lower(), "desc": "Ya ha venido hoy." if f.dia == S.day else "Te compró en la calle. Si estás fuera, viene a buscarte.", "f": f})
	if C.is_empty():
		await say("La agenda está vacía.")
		return false
	var items := C.duplicate()
	items.append({"label": "Nada"})
	var i: int = await menu(items, {"cls": "right", "title": "LLAMAR"})
	if i < 0 or i >= C.size():
		return false
	var c: Dictionary = C[i]
	match c.get("k", ""):
		"kiko":
			await talk("KIKO", [kiko_tip()])
			return false
		"tono":
			await talk("TOÑO", [("Te quedan %s hasta el día %s. Don Baltasar no espera." % [Datos.eur(S.due), n(S.deadline)]) if S.due > 0 else "Ahora mismo no debes nada. Que siga así."])
			return false
		"inaki":
			await talk("IÑAKI", ["Ahora estoy en la mar. A la vuelta hablamos." if S.ch < 3 else ("Hoy ya he cargado. Mañana sale otro barco." if S.mDay == S.day else "Al por mayor, de 100 g para arriba y hasta %s por carga. Pásate por el muelle." % _kg(mayor_dia()))])
			return false
	return await llamar_fijo(c.f)

func llamar_fijo(f: Dictionary) -> bool:
	if f.dia == S.day:
		await say("%s ya ha venido hoy." % f.n)
		return false
	if not D.ZONAS.has(S.map):
		await say("%s: «¿Dónde estás? Quedamos en la calle»." % f.n)
		return false
	if SOSP.alarma:
		await say("%s: «¿Con la policía detrás? Ni de broma»." % f.n)
		return false
	var ct: Dictionary = D.CTYPES[f.t]
	f.dia = S.day
	S.heat = minf(100, S.heat + 1)
	await say("%s: «Vale, voy para allá»." % f.n)
	advance_time(int(D.LLAMADA_MIN))
	update_hud()
	await talk_client({"id": "tel-" + f.id, "fijo": true, "n": f.n.to_upper(), "map": S.map, "x": P.x, "y": P.y, "type": f.t, "want": ri(int(ct.g[0]), int(ct.g[1])),
		"minThc": mini(24, 15 + int(S.ch)) if f.t == "pij" else 0})
	return true

# lo que Kiko manda a casa: lo del growshop que no son semillas, carpas ni la prensa, más caro; lo que ya está pedido no se repite
func precio_envio(it: Dictionary) -> int:
	return Datos.jsround(it.p * D.ENVIO)

func pedible(it: Dictionary) -> bool:
	return not it.get("sid") and not it.get("carpa") and it.get("item") != "prensa" and S.ch >= it.ch and shop_cond(it)   # shop_cond ya cuenta lo pedido

func pedir_kiko():
	var i := 0
	var ult := ""
	while true:
		var l := []
		for it in D.SHOP:
			if pedible(it):
				if it.lbl == ult:   # el cursor, en lo último pedido si sigue en la lista
					i = l.size()
				l.append(it)
		var items := []
		for it in l:
			var nn: int = S.envio.count(it.lbl)
			items.append({"label": it.lbl + ((" · ×%d" % nn) if nn else ""), "right": Datos.eur(precio_envio(it)), "desc": it.get("desc", "")})
		items.append({"label": "Salir", "desc": "Lo pedido llega mañana por la mañana a casa."})
		i = await menu(items, {"cls": "full", "title": "PEDIR A KIKO", "title2": "Envío a casa +%d %% · tienes %s" % [Datos.jsround((D.ENVIO - 1) * 100), Datos.eur(S.money)], "desc": true, "initial": i})
		if i < 0 or i >= l.size():
			return
		var it: Dictionary = l[i]
		var e := precio_envio(it)
		if S.money < e:
			sfx("bad")
			await say("No te llega el dinero.")
			continue
		S.money -= e
		S.envio.append(it.lbl)
		ult = it.lbl
		sfx("coin")
		toast("Pedido: " + it.lbl + " · llega mañana", 1400)

func recibir_envio():
	if S.envio.is_empty():
		return
	var c := {}
	for lbl in S.envio:
		var it = null
		for x in D.SHOP:
			if x.lbl == lbl:
				it = x
				break
		if it == null:
			continue
		c[lbl] = c.get(lbl, 0) + 1
		if it.get("item"):
			S.items[it.item] += int(it.get("n", 1))
		if it.get("maceta"):
			S.items["m_" + it.maceta] += 1
		if it.get("foco"):
			S.items["f_" + it.foco] += 1
		if it.get("extra"):
			S.items["x_" + it.extra] += 1
		if it.get("bolsa"):
			S.items.bolsa = maxi(int(S.items.get("bolsa", 0)), int(it.bolsa))
		if it.get("aparato"):
			S.sala[it.aparato] = true
	S.envio = []
	var L := []
	for lbl in c:
		L.append(("%s ×%d" % [lbl, c[lbl]]) if c[lbl] > 1 else lbl)
	var t := ", ".join(L)
	queue("envio", func(): await talk("SMS · KIKO", ["Te he dejado el paquete en casa: %s." % t]))

func mensajes():
	if S.sms.is_empty():
		await say("No tienes mensajes.")
		return
	var i := 0
	while true:
		var items := []
		for m in S.sms:
			items.append({"label": m.n, "right": "día " + n(m.d), "desc": m.t})
		i = await menu(items, {"cls": "full", "title": "MENSAJES", "title2": "%d de %s" % [S.sms.size(), n(D.SMS_MAX)], "desc": true, "initial": i})
		if i < 0:
			return
