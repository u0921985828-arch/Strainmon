# Ribera Verde (Godot) — 11-historia, 12-menus y 13-combate: la tienda de Kiko, los personajes, la deuda, los capítulos y el
# imperio, el menú START (Genoteca, mochila, cultivo) y los combates con ladrones y policía. Mismo guion, mismo orden de azar.
extends "res://src/granja.gd"

var cap_hasta := 0.0       # el rótulo del capítulo dura 2,8 s: el objetivo que se pida mientras tanto sale al acabar
var endcard_on := false

# ---------- tienda ----------
func shop_cond(it: Dictionary) -> bool:
	if it.get("item") == "prensa":   # la prensa de rosin (1.10), una
		return not S.items.get("prensa")
	if it.get("item") == "analizador":   # el analizador de cannabinoides y terpenos (1.15), uno
		return not S.items.get("analizador") and not S.envio.has(it.lbl)
	if it.get("item") == "medidor" or it.get("item") == "tarros":   # el medidor de pH y EC (1.11) y los tarros de curado (1.29), uno
		return not S.items.get(it.item) and not S.envio.has(it.lbl)
	if it.get("aparato"):   # los aparatos de la sala (1.10), uno de cada; lo pedido por el móvil no se vuelve a vender
		return not S.sala.get(it.aparato) and not S.envio.has(it.lbl)
	if it.get("mueble"):   # el carro de esquejes (1.11), uno
		return not (S.get("muebles") is Dictionary and S.muebles.has(it.mueble))
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

func comprar_semillas(it: Dictionary) -> bool:
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
		return false
	var e := precio_sobre(it, l[j])
	if S.money < e:
		sfx("bad")
		await say("No te llega el dinero.", "KIKO")
		return false
	S.money -= e
	sfx("coin")
	add_seeds(it.sid, int(l[j][0]))
	toast("Comprado: %d × %s" % [int(l[j][0]), D.STRAINS[it.sid].n], 1200)
	return true

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

const IC := {"fert": "abono", "fertv": "abono", "phm": "abono", "ofert": "abono", "ofertv": "abono", "ophm": "abono", "insect": "insecticida", "spray": "spray", "bocata": "bocadillo"}

# las tiendas (1.14, D.TIENDAS): GROWSHOP KIKO y GROW IBARBIDE (ANE: un 10 % más barato y un capítulo antes, sin semillas, muebles ni
# aparatos: su ok() del JS, aquí a mano)
func tienda_ok(T: Dictionary, it: Dictionary) -> bool:
	return T.N != "ANE" or not (it.get("sid") or it.get("mueble") or it.get("aparato"))

func precio_t(T: Dictionary, it: Dictionary) -> int:
	return Datos.jsround(it.p * T.f * (.95 if T.N == "KIKO" and rel("kiko") >= D.REL.amigo else 1.0))   # 1.15: con confianza, Kiko hace un 5 %

func shop(T: Dictionary = {}) -> void:
	if T.is_empty():
		T = D.TIENDAS.kiko
	var i := 0
	while true:
		var list := []
		for it in D.SHOP:
			if S.ch + T.ch >= it.ch and tienda_ok(T, it) and shop_cond(it):
				list.append(it)
		var items := []
		for it in list:
			var ic = null
			if it.get("sid"):
				ic = icono("semillas")
			elif it.get("ic"):   # 1.31: las garrafas
				ic = icono(it.ic)
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
			items.append({"label": it.lbl, "right": Datos.eur(precio_t(T, it)) + ("/u" if it.get("sid") else ""), "sw": D.STRAINS[it.sid].c if it.get("sid") else null, "ic": ic,
				"desc": strain_line(it.sid) if it.get("sid") else it.get("desc", "")})
		items.append({"label": "Salir", "desc": "Volver al mostrador."})
		i = await menu(items, {"cls": "full", "title": T.t, "title2": "Tienes " + Datos.eur(S.money), "desc": true, "initial": i})
		if i < 0 or i >= list.size():
			break
		var it: Dictionary = list[i]
		if it.get("sid"):
			if await comprar_semillas(it) and T.N == "KIKO":
				confia("kiko", 1)
			await check_story()
			continue
		var p := precio_t(T, it)
		if S.money < p:
			sfx("bad")
			await say("No te llega el dinero.", T.N)
			continue
		S.money -= p
		sfx("coin")
		if T.N == "KIKO":
			confia("kiko", 1)
		await entregar(it, T.N)
		await check_story()
	await say("Ten cuidado ahí fuera.", T.N)

# lo comprado (en una tienda o en la chatarrería): a la mochila, a la sala o puesto en una carpa, si quieres
func entregar(it: Dictionary, N: String) -> void:
	if it.get("item"):
		S.items[it.item] += int(it.get("n", 1))
	if it.get("maceta"):
		S.items["m_" + it.maceta] += 1
	if it.get("bolsa"):
		S.items.bolsa = int(it.bolsa)
	if it.get("aparato"):
		S.sala[it.aparato] = true
	if not it.get("foco") and not it.get("carpa") and not it.get("extra") and not it.get("mueble"):
		toast("Comprado: " + it.lbl, 1200)
	if it.get("mueble"):
		if not (S.get("muebles") is Dictionary):
			S.muebles = {}
		S.muebles[it.mueble] = S.day + 1
		await say("Mañana te lo subo al piso y te lo monto junto a las carpas.", N)
	if it.get("carpa"):
		comprar_carpa(it.carpa, int(it.ci))
		await say(D.DICHO_CARPA[it.carpa], N)
	if it.get("extra"):
		S.items["x_" + it.extra] += 1
		var ok := []
		for ci in S.carpas.size():
			if falta_extra(S.carpas[ci], it.extra):
				ok.append(ci)
		var pl: bool = D.EXTRAS[it.extra].get("pl", false)
		if ok.is_empty():
			await say("Ya tienes unas en cada carpa. Te las guardo en la mochila." if pl else "Ya tienes uno en cada carpa. Te lo guardo en la mochila.", N)
		else:
			var o := []
			for ci in ok:
				o.append(D.CARPAS[S.carpas[ci].t].n)
			o.append("Luego")
			var c: int = await ask("¿Te las pongo ya?" if pl else "¿Te lo pongo ya?", o, N)
			if c >= 0 and c < ok.size():
				var vu: bool = it.extra == "goteo" and S.carpas[ok[c]].get("garrafas", false)
				var vk := poner_extra(ok[c], it.extra)
				toast(("Puestas: " if pl else "Puesto: ") + it.lbl, 1200)
				if vu:
					await say("Las garrafas de esa carpa vuelven a la mochila.", N)
				if vk != "":
					await say("El %s que tenías vuelve a tu mochila." % D.EXTRAS[vk].c.to_lower(), N)
	if it.get("foco"):
		S.items["f_" + it.foco] += 1
		var ok := []
		for ci in S.carpas.size():
			var cc = S.carpas[ci]
			if cc and D.FOCOS[it.foco].w <= D.CARPAS[cc.t].wmax:
				ok.append(ci)
		if ok.is_empty():
			await say("Ese foco calienta demasiado para tus carpas. Guárdalo hasta que tengas una más grande.", N)
		else:
			var o := []
			for ci in ok:
				o.append("%s (%s)" % [D.CARPAS[S.carpas[ci].t].n, D.FOCOS[S.carpas[ci].foco].n])
			o.append("Luego")
			var c: int = await ask("¿Lo cuelgo ya? El que quites va a tu mochila.", o, N)
			if c >= 0 and c < ok.size():
				instalar_foco(ok[c], it.foco)
				toast("Instalado: " + it.lbl, 1200)

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
		await got("2 dosis de MEATZA FLORACIÓN")
		await talk(N, ["La Skunk #1 aguanta casi todo: errores de riego, plagas, frío. Es la mejor para aprender.", "Planta en las macetas del armario de tu tía y riega cuando baje el agua.",
			"El abono da más cogollo. Si ves araña roja, insecticida: lo tengo aquí.", "Cuando esté lista, cosecha. Son feminizadas: casi nunca dan semilla, pero si sale alguna, guárdala.",
			"Las plantas siguen creciendo mientras duermes.", "Te iré mandando al móvil lo que te hace falta para salir adelante. Lo tienes en START, en OBJETIVO.",
			"Mi hijo Julen te espera en el piso. Sabe más que yo de esto: te ayudará hasta tu primera cosecha."])
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
		confia("txaro", 10)
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
	confia("txaro", 10)
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
	var amt := Datos.jsround(precio_calle(b.thc) * calidad(b) * 1.2 * 10)
	if await ask("Te doy %d € por 10 g de %s. ¿Hecho?" % [amt, lot_nombre(sid)], ["Hecho", "No"], N) != 0:
		return
	use_buds(sid, 10)
	S.money += amt
	S.sales += amt
	S.heat = min(100, S.heat + 3)
	S.iDay = S.day
	S.rep += 2
	confia("inaki", 1)
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
	var pg := Datos.jsround(precio_mayor(b.thc) * calidad(b) * (1.05 if rel("inaki") >= D.REL.amigo else 1.0) * 100) / 100.0   # 1.15: con confianza, un 5 % más
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
	confia("inaki", 1)
	sfx("coin")
	await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
	toast("+%s · %s al por mayor" % [Datos.eur(e), _kg(g)], 1600)
	await say("Cargado. Esta noche sale en el barco.", N)
	heat_warn()
	await check_story()

# ---------- la comarca con función (1.14, 11d-comarca) ----------
# Ibarbide: GROW IBARBIDE (TIENDAS.ane). Puerto Viejo: la lonja (NEREA), al por mayor a un 15 % más que Iñaki, hasta 500 g y cada
# 3 días. Valdehierro: la chatarrería del solar (BIXENTE), 3 piezas de segunda mano al día a mitad de precio. Errotabarri: el
# molino (ANDONI), 20 g de cogollo por 3 semillas de una landrace del banco que aún no tengas, una vez por semana
func talk_ane():
	var N := "ANE"
	await say("¿Qué te hace falta hoy?" if S.flags.get("ane") else "Kaixo. Esto es GROW IBARBIDE: el equipo, un 10 % más barato que en el barrio, y lo nuevo antes que nadie.", N)
	S.flags.ane = true
	await shop(D.TIENDAS.ane)

# las 3 piezas del día: las mismas para todos (_hash_t del día), sin repetir
func chatarra_dia() -> Array:
	var l: Array = D.CHATARRA.piezas.duplicate()
	var r := []
	for i in int(D.CHATARRA.n):
		var j := _hash_t(S.day, i + 7) % l.size()
		r.append(l[j])
		l.remove_at(j)
	return r

func talk_bixente():
	var N := "BIXENTE"
	if S.ch < int(D.CHATARRA.ch):
		await say("Compro chatarra y vendo lo que se puede aprovechar. Vuelve cuando cultives en serio.", N)
		return
	var i := 0
	while true:
		var ch = S.get("chatarra")
		var ya: Array = ch.v if ch is Dictionary and int(ch.d) == S.day else []
		var l := []
		for lbl in chatarra_dia():
			if ya.has(lbl):
				continue
			for it in D.SHOP:
				if it.lbl == lbl:
					if S.ch >= int(it.ch) and shop_cond(it):   # solo lo de su capítulo
						l.append(it)
					break
		if l.is_empty():
			await say("Hoy no me queda nada que te sirva. Mañana entra más.", N)
			return
		var items := []
		for it in l:
			items.append({"label": it.lbl, "right": Datos.eur(Datos.jsround(it.p * D.CHATARRA.f)), "desc": it.get("desc", "") + "\nDe segunda mano: funciona, pero sin garantía."})
		items.append({"label": "Nada", "desc": "Cada día entran tres piezas."})
		i = await menu(items, {"cls": "full", "title": "CHATARRERÍA DEL SOLAR", "title2": "Tienes " + Datos.eur(S.money), "desc": true, "initial": i})
		if i < 0 or i >= l.size():
			await say("Lo que entra, sale. Si lo quieres, no tardes.", N)
			return
		var it: Dictionary = l[i]
		var p := Datos.jsround(it.p * D.CHATARRA.f)
		if S.money < p:
			sfx("bad")
			await say("Sin dinero no hay trato.", N)
			continue
		S.money -= p
		sfx("coin")
		if not (ch is Dictionary and int(ch.d) == S.day):
			S.chatarra = {"d": S.day, "v": []}
		S.chatarra.v.append(it.lbl)
		await entregar(it, N)
		await check_story()

func talk_nerea():
	var N := "NEREA"
	var L: Dictionary = D.LONJA
	if S.ch < int(L.ch):
		await say("De madrugada se subasta el pescado. Lo otro, cuando te conozca más gente.", N)
		return
	if S.get("lonja") and S.day < int(S.lonja) + int(L.dias):
		await say("Los barcos de fuera vuelven el día %d. Tráelo entonces." % (int(S.lonja) + int(L.dias)), N)
		return
	var lots := bud_lots(100)
	if lots.is_empty():
		await say("Cargo para los barcos de fuera: de 100 a %d g, un %d %% por encima de lo que paga Iñaki. Cada %d días." % [int(L.g), Datos.jsround((L.f - 1) * 100), int(L.dias)], N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		await say("Otro día.", N)
		return
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var pg := Datos.jsround(precio_mayor(b.thc) * calidad(b) * L.f * 100) / 100.0
	var tope := mini(int(floor(b.g)), int(L.g))
	var ops := []
	for g in [100, 250]:
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
	S.lonja = S.day
	S.heat = min(100, S.heat + 2 + g / 100.0)
	S.rep += 1
	sfx("coin")
	await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
	toast("+%s · %s en la lonja" % [Datos.eur(e), _kg(g)], 1600)
	await say("Hecho. Sale con el pesquero de las cinco.", N)
	heat_warn()
	await check_story()

# la landrace del trueque: la primera del banco (las de su capítulo) que no tienes en la Genoteca; si no, una según el día. 1.26: también
# las que no se venden (REGALO), ya descubiertas, y antes que nada una de esas de la que no te queden semillas: que no se pierdan
func landrace_trueque() -> String:
	var r := []
	for k in D.REGALO:
		if S.disc.get(k) and str(D.STRAINS[k].o).begins_with("Landrace") and not D.BANCO.any(func(b): return b[0] == k):
			r.append(k)
	var l := []
	for b in D.BANCO:
		if S.ch >= int(b[2]):
			l.append(b[0])
	l.append_array(r)
	for k in l:
		if not S.disc.get(k):
			return k
	for k in r:
		if not S.seeds.get(k):
			return k
	return l[S.day % l.size()]

# Darko (1.17): en el capítulo 8, el ajuste de cuentas en sus esquinas de los astilleros. Pelea como un rival con DARKO.vida más
# y la carga (enemy_hits). Si le ganas, se va (S.flags.darkoFin = el día): ni él ni sus chicos vuelven por los astilleros
func ajuste_darko() -> void:
	var N := "DARKO"
	await talk(N, ["Mírate. Cargas en el barco de Iñaki y mi tío te llama socio.", "A mí me trata como a un recadero. Y todo empezó contigo.", "Esto lo arreglamos tú y yo. Aquí y ahora."])
	if await ask("¿Peleas con Darko?", ["Pelear", "Ahora no"], N) != 0:
		await say("Ya sabes dónde estoy. Mis chicos también.", N)
		return
	var r = await battle("darko")
	if r == "ko":
		return
	if r != "win":
		await say("Corre, corre. Aquí te espero.", N)
		return
	S.flags.darkoFin = S.day
	S.rep += int(D.DARKO.rep)
	sfx("get")
	await talk(N, ["Vale. Vale. Ya está.", "Las esquinas son tuyas. Yo me largo de aquí una temporada."])
	await fade(1)
	build_ents()
	await fade(0)
	await talk("SMS · DON BALTASAR", ["Me han contado lo de mi sobrino.", "Se va a trabajar a un pesquero de fuera. Le vendrá bien.", "Tú y yo seguimos como siempre."])

# Miren (1.17): la amiga de la tía Maite, en Errotabarri desde el capítulo MIREN.ch. Le llevas MIREN.g g de la variedad que
# cultivaban juntas (MIREN.sid) y te da la página que falta del diario (S.flags.pagina, PAGINA) y MIREN.n semillas
func talk_miren():
	var N := "MIREN"
	var M: Dictionary = D.MIREN
	var v: String = String(D.STRAINS[M.sid].n).to_upper()
	if S.flags.get("pagina") and not S.flags.get("lao"):
		await lao_miren(N)
		return
	if S.flags.get("pagina"):
		await say(pick(["Tu tía subía cada otoño con un táper de cogollos y se quedaba a dormir.", "Del caserío no me echó nadie gracias a ella. Eso no se olvida.", "Cuando la Haze te salga sola, acuérdate de nosotras."]), N)
		return
	if not S.flags.get("miren"):
		S.flags.miren = S.day
		await talk(N, ["¿Tú eres el de Maite? Tienes sus ojos.", "Me llamo Miren. Tu tía y yo cultivábamos juntas en este caserío, hace treinta años.", "Su diario tiene una página arrancada. Me la dio la última vez que subió.", "Tráeme %d g de %s, la que hacíamos las dos, y es tuya." % [int(M.g), v]])
		return
	var ks: Array = S.buds.keys().filter(func(k): return lot_sid(k) == M.sid)
	ks.sort_custom(func(a, b): return not a.ends_with("*") and b.ends_with("*"))   # primero lo que no es estrella
	var tot := 0.0
	for k in ks:
		tot += float(S.buds[k].g)
	if tot < float(M.g):
		await say("¿Me traes los %d g de %s? Sin prisa: aquí estoy." % [int(M.g), v], N)
		return
	if await ask("¿Le das %d g de %s?" % [int(M.g), v], ["Dárselos", "Todavía no"], N) != 0:
		await say("Cuando quieras.", N)
		return
	var q := float(M.g)
	for k in ks:
		var t: float = minf(q, float(S.buds[k].g))
		use_buds(k, t)
		q -= t
		if q <= 0:
			break
	S.flags.pagina = S.day
	add_seeds(M.s, int(M.n))
	await talk(N, ["Huele igual que entonces.", "Toma. La página que falta, y unas semillas de su Haze."])
	await got("la última página del diario y %d semillas de %s" % [int(M.n), String(D.STRAINS[M.s].n).to_upper()])
	await lao_miren(N)
	await say("Léela en casa, con calma.", N)

# 1.25: y MIREN.n2 de la de Laos (MIREN.s2, que no está en el banco; S.flags.lao: las partidas de antes, al volver a hablarle)
func lao_miren(N: String) -> void:
	var M: Dictionary = D.MIREN
	S.flags.lao = S.day
	add_seeds(M.s2, int(M.n2))
	await say("Y esto también era de las dos. La de Laos: la guardábamos para la Amnesia.", N)
	await got("%d semillas de %s" % [int(M.n2), String(D.STRAINS[M.s2].n).to_upper()])

func talk_andoni():
	var N := "ANDONI"
	var T: Dictionary = D.TRUEQUE
	if S.ch < int(T.ch):
		await say("El molino muele los domingos. Si te interesan las semillas viejas, vuelve más adelante.", N)
		return
	if S.get("trueque") and S.day < int(S.trueque) + int(T.dias):
		await say("Hasta el día %d no tengo más semillas para cambiar." % (int(S.trueque) + int(T.dias)), N)
		return
	var k := landrace_trueque()
	await say("Mi abuelo guardaba semillas en botes de cristal, junto a la harina. Tengo de %s." % D.STRAINS[k].n, N)
	var lots := bud_lots(int(T.g))
	if lots.is_empty():
		await say("Te doy %d por %d g de lo tuyo. Cuando los tengas, aquí estoy." % [int(T.n), int(T.g)], N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "%d semillas por %d g" % [int(T.n), int(T.g)]})
	if i < 0 or i >= lots.size():
		await say("Tú verás. El bote no se mueve de aquí.", N)
		return
	use_buds(lots[i][0], int(T.g))
	add_seeds(k, int(T.n))
	S.trueque = S.day
	await got("%d semillas de %s" % [int(T.n), String(D.STRAINS[k].n).to_upper()])
	await say("Cuídalas. Ya no quedan muchas así.", N)

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
	if S.ch >= int(D.DARKO.ch):   # el ajuste de cuentas (1.17)
		await ajuste_darko()
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
	if thc > float(D.COPA_THC):
		sfx("get")
		await say("Nueva marca. {N} gana la COPA DE RIBERA.", N)
		S.money += int(D.PREMIO_COPA)
		S.rep += 20
		await got(Datos.eur(D.PREMIO_COPA) + " y el trofeo de la Copa")
		await talk("DARKO", ["Esto no se acaba aquí.", "Mi tío se va a enterar."])
		S.flags.copa = true
		S.due = S.debt
		S.deadline = S.day + 7
		cerrar_copa()
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
		await lineas_nuevas()
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
# líneas de autobús nuevas (1.14): las paradas se abren por capítulos (PARADAS.cap); al abrirse, un SMS de la compañía
func lineas_nuevas() -> void:
	var L := []
	for k in D.PARADAS:
		if int(D.PARADAS[k].cap) == S.ch:
			L.append(D.PARADAS[k].n)
	if L.size():
		await talk("SMS · AUTOBUSES DE LA COMARCA", ["Nueva línea desde Ribera Verde: %s." % _lista(L), "Salidas de %d:%02d a %d:%02d, en la parada de la calle Ribera." % [int(D.BUS_HORAS[0]) / 60, int(D.BUS_HORAS[0]) % 60, int(D.BUS_HORAS[1]) / 60, int(D.BUS_HORAS[1]) % 60]])

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
			if not S.flags.get("kiko1"):
				return "Visita el growshop de Kiko, al lado de casa."
			var sg = itin_sig()   # 1.23: el paso del itinerario
			return sg.d if sg != null and not S.flags.get("harvest1") else "Planta y consigue tu primera cosecha."
		2:
			var mv := int(D.META_VENTAS)
			return "Gana %d € vendiendo (%d/%d)." % [mv, mini(mv, Datos.jsround(S.sales)), mv]
		3:
			return (("Ve al bar El Ancla antes de que acabe el día %s: Don Baltasar quiere %s." % [n(S.deadline), Datos.eur(S.due)]) if not S.flags.get("metB") else "Paga %s a Don Baltasar antes de que acabe el día %s." % [Datos.eur(S.due), n(S.deadline)]) + llevas()
		4:
			return "Kiko quiere verte en el growshop." if not S.flags.get("lab") else "Saca en la mesa 2 variedades de receta y cosecha una planta de cada (%d/2)." % rec_count()
		5:
			return "Paga %s a Don Baltasar antes de que acabe el día %s." % [Datos.eur(S.due), n(S.deadline)] + llevas()
		6:
			return "Gana la Copa: 20 g con más de 26,8% de THC al jurado de la plaza."
		7:
			return "Paga los últimos %s a Don Baltasar antes de que acabe el día %s." % [Datos.eur(S.due), n(S.deadline)] + llevas()
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
		"potente":   # 1.28: la Copa
			return D.POTENTES.any(func(k): return int(S.rec.get(k, 0)) > 0)
		"flor27":
			var H := huecos()
			for i in S.pots.size():
				var p = S.pots[i]
				if p is Dictionary and not p.get("dead") and Cultivo.fq(p) >= 1 and i < H.size() and S.carpas[H[i].c].foco == "led720":
					return true
			return false
		"copa27":
			return bud_lots(20).any(func(l): return Datos.jsround(l[1].thc * 10) / 10.0 > float(D.COPA_THC))
	return false

# ganada la Copa, las misiones que falten del capítulo 6, sin aviso ni regalo
func cerrar_copa() -> void:
	for m in D.MISIONES:
		if int(m.ch) == 6 and not S.misiones.has(m.id):
			S.misiones[m.id] = 0

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
	revisa_itinerario()   # 1.23
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
	revisa_logros()   # 1.27

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
	var h := con_logro(("<small>MISIÓN</small>" + sg.t) if sg else "")
	if h != "":
		toast(h, 3200)

# ---------- logros (1.27, 11i-logros.js): textos del HTML (D.LOGROS); aquí, lo que mira cada uno ----------
var logro_aviso: Array = []

func logro_ok(id: String) -> bool:
	var F: Dictionary = S.flags
	var disc := func(l): return l.all(func(k): return true if S.disc.get(k) else false)
	match id:
		"venta":
			return S.sales > 0
		"cosecha":
			return true if F.get("harvest1") else false
		"diario":
			return true if F.get("diario") else false
		"estrella":
			return S.fenos.values().has("estrella")
		"receta":
			return rec_count() >= 1
		"recetas10":
			return rec_count() >= 10
		"jack":
			return S.rec.get("leyenda") == 2
		"mitad":
			return D.DEX.filter(func(k): return S.disc.get(k)).size() >= ceili(D.DEX.size() / 2.0)
		"genoteca":
			return disc.call(D.DEX)
		"landraces":
			return disc.call(D.LANDRACES)
		"tia":
			return disc.call(D.TIA_DEJO)
		"rosin":
			return S.rosin.size() > 0 or S.arcon.rosin.size() > 0
		"cata":
			return S.catas.size() > 0
		"club":
			return S.clubs.values().any(func(v): return true if v else false)
		"presidente":   # 1.32
			return S.get("aso") is Dictionary and S.aso.get("pres") == true
		"goteo":
			return S.carpas.any(func(c): return c is Dictionary and c.get("goteo"))
		"carpas":
			return S.carpas.filter(func(c): return c is Dictionary).size() >= 3
		"plazo":
			return S.ch >= 4
		"libre":
			return S.debt <= 0
		"ventas10":
			return S.sales >= 10000
		"ventas100":
			return S.sales >= 100000
		"rival":
			return S.rivalFuera.size() > 0
		"darko":
			return true if F.get("darkoFin") else false
		"plantilla":
			return S.plantilla.size() > 0
		"nave":
			return true if S.get("nave") else false
		"ruedas":
			return S.get("veh") is Dictionary and S.veh.values().any(func(d): return d and d <= S.day)
		"casa":
			return deco_v("suelo") > 0 or deco_v("pared") > 0
	return false

func logros_n() -> int:
	return D.LOGROS.filter(func(l): return S.logros.has(l.id)).size()

func revisa_logros() -> void:
	for l in D.LOGROS:
		if not S.logros.has(l.id) and logro_ok(l.id):
			S.logros[l.id] = S.day
			logro_aviso.append(l.id)
	if logro_aviso.size():
		queue("logro", aviso_logro)

func logro_txt() -> String:
	var l := []
	for id in logro_aviso:
		for x in D.LOGROS:
			if x.id == id:
				l.append(esc(x.t))
	logro_aviso.clear()
	if l.is_empty():
		return ""
	sfx("get")
	return "<small>%s · %d/%d</small>%s" % ["LOGROS" if l.size() > 1 else "LOGRO", logros_n(), D.LOGROS.size(), " · ".join(l)]

# el aviso h (del itinerario o de la misión, en la cola mientras corre) con los logros debajo, si el otro no viene después
func con_logro(h: String) -> String:
	if queued.has("itin") and queued.has("mision"):
		return h
	var l := logro_txt()
	return ((h + "<br>") if h != "" else "") + l if l != "" else h

func aviso_logro():
	if queued.has("itin") or queued.has("mision"):   # lo dirán ellos
		return
	var l := logro_txt()
	if l != "":
		toast(l, 2600)

# START → OBJETIVO → LOGROS
func logros_menu():
	var it := []
	for l in D.LOGROS:
		var h: bool = S.logros.has(l.id)
		it.append({"label": l.t, "right": (("día %s" % n(S.logros[l.id])) if S.logros[l.id] else "HECHO") if h else null, "desc": l.d})
	it.append({"label": "Volver", "desc": ""})
	await menu(it, {"cls": "full", "title": "LOGROS", "title2": "%d de %d" % [logros_n(), D.LOGROS.size()], "desc": true})

# el plazo (1.11): Toño avisa cuando quedan 3 días y el último, con lo que llevas
func recuerdo_plazo():
	var nd := int(S.deadline - S.day)   # los días, como los cuenta Baltasar (talk_baltasar)
	var ll: float = S.money + caja_e()
	await talk("SMS · TOÑO", [("Don Baltasar quiere %s antes de que acabe el día %s. Te quedan %d días." % [Datos.eur(S.due), n(S.deadline), nd]) if nd > 0 else "Hoy es el último día para los %s de Don Baltasar." % Datos.eur(S.due)])
	await say(("Llevas %s entre el bolsillo y la caja: te faltan %s." % [Datos.eur(ll), Datos.eur(S.due - ll)]) if ll < S.due else "Llevas %s entre el bolsillo y la caja: ya lo tienes.%s Ve al bar El Ancla." % [Datos.eur(ll), " Saca lo que falte de la caja y" if S.money < S.due else ""])

# START → OBJETIVO: el del capítulo, las misiones (con lo que hay que hacer abajo) y la deuda
# (1.23: y el ITINERARIO hasta el primer plazo, hasta el capítulo 4; con A, sus pasos)
func objetivo_menu():
	while true:
		var iti: bool = S.ch <= 4
		var it := [{"label": "CAPÍTULO %d" % S.ch, "desc": "%s\n%s" % [D.CH_TITLES.get(str(S.ch), ""), objective_text()]}]
		if iti:
			it.append(itin_row())
		var ini := 0
		var mv := misiones_ver()
		for i in mv.size():
			var hecha: bool = S.misiones.has(mv[i].id)
			it.append({"label": mv[i].t, "right": "HECHA" if hecha else null, "desc": mv[i].d})
			if not hecha and ini == 0:
				ini = i + 1 + (1 if iti else 0)
		if iti and itin_sig() != null:
			ini = 1
		var plazo := ("Plazo: %s antes de que acabe el día %s. Llevas %s.\n" % [Datos.eur(S.due), n(S.deadline), Datos.eur(S.money + caja_e())]) if S.due > 0 else ""
		it.append({"label": "LOGROS", "right": "%d/%d" % [logros_n(), D.LOGROS.size()], "desc": "Lo que llevas conseguido en la partida. Pulsa A para verlos."})   # 1.27
		it.append({"label": "DEUDA", "right": Datos.eur(S.debt), "desc": plazo + "Ventas %s · Reputación %s · Calor %d %%" % [Datos.eur(S.sales), n(S.rep), Datos.jsround(S.heat)]})
		it.append({"label": "Volver", "desc": ""})
		var i: int = await menu(it, {"cls": "full", "title": "OBJETIVO", "title2": "cap. %d" % S.ch, "desc": true, "initial": ini})
		if iti and i == 1:
			await itinerario_menu()
			continue
		if i == it.size() - 3:   # 1.27
			await logros_menu()
			continue
		return

# ---------- Julen y el itinerario (1.23, 11h-guia.js): textos del HTML (D.ITINERARIO, D.JULEN, D.MINERAL_ORG); aquí, lo que mira cada paso ----------
var itin_aviso: Array = []

func itin_ok(id: String) -> bool:
	var F: Dictionary = S.flags
	var h1: bool = true if F.get("harvest1") else false
	match id:
		"bus":
			return not llegando()
		"carta":
			return true if F.get("letter") else false
		"kiko":
			return true if F.get("kiko1") else false
		"julen":
			return (true if F.get("julen1") else false) or h1
		"plantar":
			return S.pots.any(func(p): return p is Dictionary) or h1
		"regar":   # o riego automático
			return (true if F.get("gRiego") else false) or h1 or (S.pots.any(func(p): return p is Dictionary) and S.carpas.any(func(c): return c is Dictionary and (true if (c.get("goteo") or c.get("garrafas")) else false)))
		"veg":   # ya en flor, no toca
			return (true if (F.get("gVeg") or F.get("gFlor") or F.get("harvest1")) else false) or S.pots.any(func(p): return p is Dictionary and (p.prog >= .65 or (true if (p.get("fv") or p.get("fert")) else false)))   # p.fv, p.fert: partidas de antes de gVeg
		"flor":
			return (true if F.get("gFlor") else false) or h1 or S.pots.any(func(p): return p is Dictionary and (true if p.get("fert") else false))
		"cosecha":
			return h1
		"vender":
			return S.sales > 0
		"ventas":
			return S.ch >= 3
		"baltasar":
			return (true if F.get("metB") else false) or S.ch >= 4
		"juntar":
			return S.ch >= 4 or (S.ch == 3 and S.due > 0 and S.money + caja_e() >= S.due)
		"pagar":
			return S.ch >= 4
	return false

func itin_hecho(p: Dictionary) -> bool:
	return S.itin.has(p.id) or itin_ok(p.id)

func itin_sig():
	for p in D.ITINERARIO:
		if not itin_hecho(p):
			return p
	return null

func itin_n() -> int:
	return D.ITINERARIO.filter(func(p): return itin_hecho(p)).size()

func julen_aqui() -> bool:
	return S.map == "home" and (true if S.flags.get("julen1") else false) and not S.flags.get("harvest1")   # ya te ha saludado y sigue en el piso

# lo que toca ahora, con lo que te falta para hacerlo
func paso_cultivo() -> String:
	var sg = itin_sig()
	if sg == null:
		return pick(D.JULEN.tips)
	var sin := func(ks: Array) -> bool: return not ks.any(func(k): return S.items.get(k, 0) > 0)
	var t: String = sg.d
	if sg.id == "plantar" and not S.seeds.values().any(func(v): return v > 0):
		t += " Si no te quedan semillas, mi aita tiene."
	elif (sg.id == "veg" and sin.call(["fertv", "ofertv"])) or (sg.id == "flor" and sin.call(["fert", "ofert"])):
		t += " No te queda: mi aita lo vende en el growshop."
	elif (sg.id == "veg" or sg.id == "flor") and sin.call(["phm", "ophm"]):
		t += " Y te falta pH−: lo tiene mi aita."
	return t

func talk_julen():
	var N := "JULEN"
	if not S.flags.get("julen1"):
		await talk(N, D.JULEN.tarde if S.flags.get("harvest1") else D.JULEN.hola)
		S.items.ofertv += 2
		await got("2 dosis de ORTUA BIO CRECIMIENTO")
		S.items.ophm += 4
		await got("4 dosis de pH− ORTUA BIO")
		await talk(N, D.JULEN.ph + D.MINERAL_ORG + ([] if S.flags.get("harvest1") else D.JULEN.aqui))
		S.flags.julen1 = true
		return
	if not S.flags.get("harvest1"):
		var c: int = await ask("¿Qué pasa?", ["¿Qué hago ahora?", "Mineral u orgánico", "Nada"], N)
		if c == 0:
			await say(paso_cultivo(), N)
		elif c == 1:
			await talk(N, D.MINERAL_ORG)
		else:
			await say("Aquí estoy si me necesitas.", N)
		return
	var c: int = await ask("¿Qué tal la cosecha?", ["Un consejo", "Mineral u orgánico", "Nada"], N)
	if c == 0:
		await say(pick(D.JULEN.tips), N)
	elif c == 1:
		await talk(N, D.MINERAL_ORG)
	else:
		await say("Agur. Saluda a las plantas de mi parte.", N)

# run() → revisa_misiones → aquí: apunta los pasos hechos y avisa del último (y del siguiente); si Julen está delante, lo comenta
func revisa_itinerario() -> void:
	if not S.has("itin"):
		return
	var I: Array = D.ITINERARIO
	for i in I.size():
		if not S.itin.has(I[i].id) and itin_ok(I[i].id):
			S.itin[I[i].id] = S.day
			if i >= int(D.ITIN_MUDO):
				itin_aviso.append(I[i].id)
	if itin_aviso.size():
		queue("itin", aviso_itin)

func aviso_itin():
	var ids := itin_aviso.duplicate()
	itin_aviso.clear()
	var p: Dictionary = {}
	for x in D.ITINERARIO:
		if x.id == ids[-1]:
			p = x
	var sg = itin_sig()
	toast(con_logro("<small>ITINERARIO · %d/%d</small>%s" % [itin_n(), D.ITINERARIO.size(), p.t] + ("<br>Ahora: " + sg.t if sg != null else "")), 2800)
	var j := ids.map(func(id): return D.JULEN.ok.get(id)).filter(func(x): return x != null)
	if julen_aqui() and j.size():
		await say(j[-1], "JULEN")

# START → OBJETIVO → ITINERARIO
func itin_row() -> Dictionary:
	var sg = itin_sig()
	var I: Array = D.ITINERARIO
	var i: int = I.find(sg) if sg != null else -1
	var desc := "Hecho: el primer plazo, pagado."
	if sg != null:
		desc = "Ahora: %s. %s" % [sg.t, sg.d] + (("\nDespués: %s." % I[i + 1].t) if i + 1 < I.size() else "")
	return {"label": "ITINERARIO", "right": "%d/%d" % [itin_n(), I.size()], "itin": 1, "desc": desc}

func itinerario_menu():
	var sg = itin_sig()
	var I: Array = D.ITINERARIO
	var it := []
	for p in I:
		it.append({"label": p.t, "right": "HECHO" if itin_hecho(p) else ("AHORA" if p == sg else null), "desc": p.d})
	it.append({"label": "Volver", "desc": ""})
	await menu(it, {"cls": "full", "title": "ITINERARIO", "title2": "%d/%d" % [itin_n(), I.size()], "desc": true, "initial": maxi(0, I.find(sg) if sg != null else 0)})

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
		if S.flags.get("julen1"):   # 1.23: se vuelve al growshop (antes del capítulo, que lo quita del piso)
			await talk("JULEN", D.JULEN.adios)
		await chapter(2)
		spawn_clients()
		await talk("SMS · KIKO", ["Primera cosecha. Bien hecho.", "La gente que busca material lleva un $ encima. Puedes venderles en la calle.", "Cuanto más vendas, más se fijará la policía: es el CALOR. Y de noche hay quien roba."])
		await lineas_nuevas()
		show_objective()
	if S.ch == 2 and S.sales >= D.META_VENTAS:
		S.due = int(D.PLAZOS["3"])   # el plazo, desde ya (1.10)
		S.deadline = S.day + 7
		S.flags.tono = S.day
		await chapter(3)
		await say("Un hombre enorme en chándal te corta el paso.")
		await talk("TOÑO", ["Tú vives en el piso de Maite, ¿no?", "Don Baltasar quiere verte. En el bar El Ancla. Hoy.", "Y ve contando: tienes siete días para el primer pago.", "No me hagas venir a buscarte."])
		await lineas_nuevas()
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
	var L := ["Me dice uno de la comisaría que mañana entran en tu piso con orden de registro.", "Esta noche, el dinero y los cogollos a la caja o fuera de casa. Las plantas no se pueden esconder."]
	if S.ch >= 5:
		L.append("O paga a Molina, que aún estás a tiempo.")
	await talk("SMS · KIKO", L)

# la redada (1.11): lo de fuera y las plantas, siempre; la caja fuerte, nunca. La multa (multa_redada) sale de lo de fuera y, si no
# llega, de la caja. Lo de encima, solo si estás en casa (1.13)
func raid_event():
	S.orden = 0
	if S.protect:
		S.heat = 50
		await talk("SMS · MOLINA", ["Esta noche había orden de entrada en tu piso. La he parado.", "Baja el ritmo."])
		return
	music("redada")
	sfx("bad")
	await say("REDADA. La policía entra en tu piso con una orden de registro.")
	var casa: bool = S.map == "home"
	var ne: int = S.esquejes.size() + S.bandejas.size()
	var g := int(floor((total_buds() if casa else 0.0) + arcon_g()))   # lo de encima y el arcón (1.10)
	var ro: float = (total_rosin() if casa else 0.0) + arcon_r()
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
	if casa:
		S.buds = {}
		S.rosin = {}
	S.arcon = {"buds": {}, "rosin": {}}
	S.esquejes = []
	S.bandejas = []
	S.heat = D.CALOR_REDADA
	var multa := multa_redada(npl, g + Datos.jsround(ro / D.ROSIN.rend))   # el rosin, como la flor de la que sale
	var fine: float = multa - pagar_casa(multa)
	var lo := []
	if npl:
		lo.append("todas las plantas")
	if ne:
		lo.append("los esquejes" if ne > 1 else "el esqueje")
	if g:
		lo.append("%d g" % g)
	if ro:
		lo.append(rosin_txt(ro))
	await say("%s. Multa: %s%s." % [("Se llevan " + _lista(lo)) if lo.size() else "No encuentran nada que llevarse", Datos.eur(multa), (" (pagas %s: no tienes más)" % Datos.eur(fine)) if fine < multa else ""])
	if eq.size():
		await say("Y el equipo de las carpas con plantas: " + ", ".join(eq) + ".")
	await say("La caja de detrás del diploma ni la ven. Las semillas no son delito: se quedan." if S.get("caja") != null else "Las semillas no son delito: se quedan.")
	await say("Toca empezar de nuevo. Y vender menos una temporada.")
	music(map_music())

func ending() -> void:
	await fade(1)
	music("final")
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
	music(map_music())
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

# exportar la partida (1.11, exportar de 12-menus): el JSON de S al portapapeles
var exportado := ""   # lo último copiado (las pruebas lo leen: sin pantalla no hay portapapeles)

func exportar() -> void:
	exportado = JSON.stringify(S, "", false, true)
	DisplayServer.clipboard_set(exportado)
	await say("Partida copiada al portapapeles. Pégala en una nota o en un correo para guardarla.")

# recetario (1.11): cada variedad de receta con sus maneras de sacarla (RECIPES, en cualquier orden; RECETA_ORD, madre × padre)
func recetas() -> Dictionary:
	var R := {}
	for h in D.RECIPES:
		var t: String = D.RECIPES[h]
		if not R.has(t):
			R[t] = []
		R[t].append({"k": Array(h.split("+")), "ord": false})
	for h in D.RECETA_ORD:
		var t: String = D.RECETA_ORD[h]
		if not R.has(t):
			R[t] = []
		R[t].append({"k": Array(h.split(">")), "ord": true})
	return R

func receta_txt(o: Dictionary) -> String:
	return (" × " if o.ord else " + ").join(PackedStringArray(o.k.map(func(k): return D.STRAINS[k].n))) + (", en ese orden" if o.ord else "")

# REGALO (12-menus, por datos.json): las semillas que se consiguen sin comprarlas

func donde_semilla(k: String) -> String:
	var l := []
	if D.REGALO.has(k):
		l.append(D.REGALO[k])
	for it in D.SHOP:
		if it.get("sid") == k:
			l.append("en el growshop de Kiko desde el cap. %s" % n(it.ch))
			break
	for b in D.BANCO:
		if b[0] == k:
			l.append("en el banco de semillas del PC desde el cap. %s" % n(b[2]))
			break
	if D.MISIONES.any(func(m): return m.get("s") is Dictionary and m.s.has(k)):
		l.append("de premio en una misión")
	if recetas().has(k):
		l.append("de su receta")
	return "Semillas: " + "; ".join(PackedStringArray(l)) + "."

# el diario de la tía Maite (1.16): su nota de cada variedad (DIARIO, de 12-menus; 1.25: todas)
func diario_txt(t: String) -> String:
	return ("«%s»\n" % D.DIARIO[t]) if D.DIARIO.has(t) else ""

# 1.25: todas las de la Genoteca, en su orden; las de receta abren lo que entra; las demás dicen dónde están sus semillas
func tipo_diario(t: String, R: Dictionary) -> String:
	if R.has(t):
		return ("%d recetas" % R[t].size()) if R[t].size() > 1 else "receta"
	return "tienda" if D.SHOP.any(func(it): return it.get("sid") == t) else "landrace"

func recetario():
	var R := recetas()
	var ts: Array = D.DEX
	var i := 0
	while true:
		var items := []
		var nd := 0
		for t in ts:
			if S.disc.get(t):
				nd += 1
			items.append({"label": ("✓ " if S.disc.get(t) else "  ") + D.STRAINS[t].n, "right": tipo_diario(t, R), "sw": D.STRAINS[t].c, "ic": ic_cog(t),
				"desc": diario_txt(t) + ("\no ".join(PackedStringArray(R[t].map(func(o): return receta_txt(o)))) if R.has(t) else donde_semilla(t))})
		if S.flags.get("pagina"):   # la página que falta (1.17)
			items.append({"label": "  La última página", "desc": "«%s»" % D.PAGINA})
		items.append({"label": "Volver", "desc": ""})
		i = await menu(items, {"cls": "full", "title": "DIARIO DE LA TÍA MAITE", "title2": "%d/%d" % [nd, ts.size()], "desc": true, "initial": i})
		if i == ts.size() and S.flags.get("pagina"):
			continue
		if i < 0 or i >= ts.size():
			return
		if not R.has(ts[i]):
			continue
		var t: String = ts[i]
		var ks := []
		for o in R[t]:
			for k in o.k:
				if not ks.has(k):
					ks.append(k)
		var it2 := []
		for k in ks:
			it2.append({"label": ("✓ " if S.disc.get(k) else "  ") + D.STRAINS[k].n, "right": ("×" + n(S.seeds[k])) if S.seeds.get(k) else "", "sw": D.STRAINS[k].c, "ic": ic_cog(k), "desc": donde_semilla(k)})
		it2.append({"label": "Volver", "desc": ""})
		await menu(it2, {"cls": "full", "title": D.STRAINS[t].n.to_upper(), "title2": "lo que entra", "desc": true})

# cambiar el nombre a una variedad propia (1.11): sin repetir el de otra
func renombrar_variedad(k: String) -> void:
	var C: Dictionary = S.custom[k]
	var v = await pedir_texto("Nuevo nombre de la variedad", C.n, Datos.NOM_MAX)
	if v == null or v == "" or v == C.n:
		return
	var l: String = v.to_lower()
	for d in D.DEX:
		if D.STRAINS[d].n.to_lower() == l:
			await say("Ya hay una variedad con ese nombre.")
			return
	for q in S.custom:
		if not is_same(S.custom[q], C) and S.custom[q].n.to_lower() == l:
			await say("Ya hay una variedad con ese nombre.")
			return
	var a: String = C.n
	C.n = v
	sfx("sel")
	await say("La %s pasa a llamarse %s." % [a, v])

func genoteca():
	var i := 0
	while true:
		i = await menu_genoteca(i)
		if i < 0:
			break

func menu_genoteca(i0: int) -> int:
	var DEX: Array = D.DEX
	var nr := 0
	for t in DEX:
		if S.disc.get(t):
			nr += 1
	var items := []
	if S.flags.get("diario"):   # sale bajo la almohada (1.25)
		items.append({"label": "DIARIO DE LA TÍA MAITE", "right": "%d/%d" % [nr, DEX.size()], "ic": icono("guardar"), "diario": 1, "desc": "Su cuaderno: las %d variedades, lo que apuntó de cada una, las recetas de los cruces y dónde conseguir las semillas." % DEX.size()})
	for j in DEX.size():
		var k: String = DEX[j]
		var s: Dictionary = D.STRAINS[k]
		var nn := "%02d" % (j + 1)
		if S.disc.get(k):
			items.append({"label": "%s %s" % [nn, s.n], "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "desc": strain_line(k) + (("\n" + s.h) if s.get("h") else "") + (("\nCata: " + S.catas[k]) if S.catas.has(k) else "")})
		else:
			items.append({"label": nn + " ??????", "desc": "Sin descubrir."})
	var cust := []
	for k in S.custom:
		if S.disc.get(k):
			cust.append(k)
	for k in cust:
		var s: Dictionary = S.custom[k]
		items.append({"label": "★ " + s.n, "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "desc": strain_line(k) + "\nPulsa A para cambiarle el nombre.", "c": k})
	var nd := 0
	for k in DEX:
		if S.disc.get(k):
			nd += 1
	var i: int = await menu(items, {"cls": "full", "title": "GENOTECA", "title2": "%d/%d · %d propias" % [nd, DEX.size(), cust.size()], "desc": true, "initial": i0})
	if i >= 0 and i < items.size() and items[i].get("diario"):
		await recetario()
	elif i >= 0 and i < items.size() and items[i].get("c"):
		await renombrar_variedad(items[i].c)
	return i

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
		rows.append({"label": "Vida", "right": "%s/%s" % [n(S.hp), n(S.hpMax)], "desc": "Se recupera durmiendo, comiendo o con el tiempo."})
		if int(S.pelea.xp) > 0:
			rows.append({"label": "Pelea", "right": "nivel %d" % nivel_pelea(), "desc": ficha_pelea()})
		for k in D.PRODUCTOS:   # 1.23: por marca
			if k == "fert" or S.items.get(k, 0) > 0:
				rows.append({"label": D.PRODUCTOS[k].n, "right": "×" + n(S.items.get(k, 0)), "ic": icono("abono"), "desc": D.DESC_PROD[k]})
		if S.items.get("medidor", 0):
			rows.append({"label": "Medidor de pH y EC", "right": "×1", "desc": "Con él corriges el pH justo y ves la EC y el pH de cada maceta en PLANTAS."})
		if S.items.get("tarros"):
			rows.append({"label": "Tarros de curado", "right": "en el arcón", "desc": "Lo que guardas en el arcón se cura en %d días: se vende un %d %% más caro y ya no pierde THC." % [int(D.CURADO.dias), Datos.jsround(D.CURADO.precio * 100)]})
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
			rows.append({"label": "Semilla " + strain(k).n, "right": "×" + n(S.seeds[k]), "sw": strain(k).c, "ic": icono("semillas"), "desc": strain_line(k) + "\nPulsa A para tirarlas.", "k": "s", "sid": k})
		for e in S.esquejes:
			rows.append({"label": "Esqueje " + strain(e.sid).n + etiq(e.f), "right": "día " + n(e.dia + D.ESQUEJE_DIAS), "sw": strain(e.sid).c, "ic": ic_cog(e.sid),
				"desc": "Enraizando en el propagador. Plántalo en una plaza vacía antes de que acabe el día %s.\nPulsa A para ponerle nombre o tirarlo." % n(e.dia + D.ESQUEJE_DIAS), "k": "e", "e": e})
		for k in S.buds:
			var b: Dictionary = S.buds[k]
			rows.append({"label": lot_nombre(k), "right": "%d g · %s%%" % [int(floor(b.g)), Datos.pct(b.thc)], "sw": strain(lot_sid(k)).c, "ic": ic_cog(lot_sid(k)),
				"desc": ("Cogollos de un fenotipo estrella, en lote aparte.\n" if k.ends_with("*") else "Cogollos listos para vender.\n") + ((cura_txt(b) + "\n") if cura_txt(b) else "") + ((S.catas[lot_sid(k)] + "\n") if S.catas.has(lot_sid(k)) else "") + strain(lot_sid(k)).o + "\nPulsa A para catarlo" + (" o analizarlo." if S.items.get("analizador") else "."), "k": "b", "key": k})
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
		elif rows[i].get("k") == "e":
			await esqueje_accion(rows[i].e, S.esquejes)
		elif rows[i].get("k") == "b":   # la cata y el análisis (1.15)
			await lote_accion(rows[i].key)
		elif rows[i].get("k") == "s":   # tirar semillas (1.11)
			var sid: String = rows[i].sid
			var ns: int = int(S.seeds[sid])
			var o := ["Tirar 1", "Tirar todas", "Nada"] if ns > 1 else ["Tirar", "Nada"]
			var c: int = await ask("%s de %s." % [("%d semillas" % ns) if ns > 1 else "1 semilla", strain(sid).n], o)
			if c >= 0 and c < o.size() and o[c] != "Nada":
				var q: int = ns if o[c] == "Tirar todas" else 1
				S.seeds[sid] -= q
				if not S.seeds[sid]:
					S.seeds.erase(sid)
				sfx("sel")
				await say(("Tiras las %d semillas." % q) if q > 1 else "Tiras 1 semilla.")

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
			rows.append({"label": "  %d · %s%s" % [h.j + 1, s.n, etiq(p.get("f"))], "sw": s.c, "ic": ic_cog(p.sid),
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
		var g = Atlas.cubre("combate:frente:darko") if B.get("jefe") else Atlas.grupo_look(B.get("look"))   # sin look (como en grupoLook), el del ladrón; Darko (1.17): su personaje es de 32 px; pelea con el suyo de combate (1.21)
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
		return await gancho_combate.call(kind)
	lock += 1
	var res = null
	music(D.MUS_COMBATE.get(kind, "battle"))
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
	elif kind == "rival" or kind == "darko":
		B = rival_b(kind)
	else:
		B = {"kind": kind, "name": pick(D.COPS), "look": D.LOOKS.cop, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	if B.kind == "thief":
		# desde el capítulo 5 (1.10), ladrones más duros: +4 de vida y +1 a cada golpe; un rival (1.16), RIVAL.vida más y +1 a cada golpe
		var dd := 1 if ch >= 5 else 0
		var rr := 1 if B.has("rival") else 0
		B.hpMax = 12 + ch * 2 + ri(0, 4) + 4 * dd + int(D.RIVAL.vida) * rr + (int(D.DARKO.vida) if B.get("jefe") else 0)
		B.hp = B.hpMax
		B.atk = [2 + (ch >> 2) + dd + rr, 4 + (ch >> 1) + dd + rr]
	mode = "battle"
	update_hud()
	wipe_fuera()
	await wait(650)
	bhud_build()
	if B.get("jefe"):
		await say("Darko se quita la sudadera y la tira al suelo.")
		await say("«Ni Iñaki ni mi tío. Tú y yo.»", B.name)
	elif B.has("rival"):
		await say("%s se te planta delante." % B.rival)
		await say(pick(["«Te lo he dicho por las buenas.»", "«Aquí se vende lo mío.»", "«Vamos a arreglarlo.»"]), B.name)
	elif kind == "thief":
		await say("Un %s te corta el paso." % B.name.to_lower())
		await say(pick(["«La mochila. Dámela y no pasa nada.»", "«Eh, tú. Sé lo que llevas encima.»", "«Quieto. El dinero y lo que lleves.»"]), B.name)
	else:
		b_anim("E", "alto")
		await say("%s te da el alto." % B.name)
		await say(pick(["«Control rutinario. ¿Llevas algo encima?»", "«Documentación. Y vacía los bolsillos.»", "«Aquí huele a marihuana. ¿Es tuya?»"]), B.name)
	while not res:
		if B.kind == "thief":
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
	return res

func el_b() -> String:
	return B.rival if B.has("rival") else "El " + B.name.to_lower()

func enemy_hits():
	# la carga de Darko (1.17): a veces coge la barra y el golpe siguiente vale el doble (CUBRIRSE lo deja en la mitad). La guardia o la
	# esquiva de esta ronda se gastan con ella (1.24): contra la barra hay que cubrirse o apartarse en la ronda del golpe
	if B.get("jefe") and not B.get("carga") and Cultivo.azar() < float(D.DARKO.carga):
		B.carga = 1
		B.cubre = 0
		B.esquiva = 0
		await say("%s coge una barra de hierro del suelo. El próximo golpe va a doler." % el_b())
		return null
	# ESQUIVAR (1.18): con suerte (prob_esquiva, los reflejos) no te toca y tu golpe siguiente no falla y hace PELEA.contra más
	# (B.contra); si no, te da entero. La amenaza fallida (B.furia) suma PELEA.furia al golpe
	if B.get("esquiva"):
		B.esquiva = 0
		if Cultivo.azar() < prob_esquiva():
			b_anim("E", "ataque")
			await say(("%s baja la barra y te apartas a tiempo." % el_b()) if B.get("carga") else ("%s se lanza y te apartas a tiempo." % el_b()))
			B.carga = 0
			B.furia = 0
			B.contra = 1
			return null
		await say("No te apartas a tiempo.")
	var dmg := (ri(int(B.atk[0]), int(B.atk[1])) + (int(D.PELEA.furia) if B.get("furia") else 0)) * (2 if B.get("carga") else 1)
	b_anim("E", "ataque")
	await say(("%s te da con la barra." % el_b()) if B.get("carga") else ("%s %s." % [el_b(), pick(["te golpea", "te empuja contra un portal", "te da una patada", "te tira al suelo"])]))
	B.carga = 0
	B.furia = 0
	var dd: int = int(ceil(dmg / 2.0)) if B.get("cubre") else dmg
	if B.get("cubre"):   # CUBRIRSE (1.16)
		B.cubre = 0
		await say("Te cubres: el golpe duele la mitad.")
	b_anim("P", "herido")
	vfx_combate("vfx-golpe", 64, 112)
	B.shakeP = 450.0
	sfx("hurt")
	S.hp = maxi(0, S.hp - dd)
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
		var m: int = await menu(["PUÑETAZO", "PATADA", "CUBRIRSE", "ESQUIVAR"], {"cls": "battle"})
		if m < 0:
			return null
		if m == 2:
			B.cubre = 1
			B.guardia = 1
			B.esquiva = 0
			await say("Te pones en guardia: el próximo golpe no fallará.")
			return await enemy_hits()
		if m == 3:   # ESQUIVAR (1.18)
			B.esquiva = 1
			B.cubre = 0
			await say("Te quedas atento para apartarte.")
			return await enemy_hits()
		var mv := {"n": "PATADA", "acc": .65, "d": [8, 12]} if m else {"n": "PUÑETAZO", "acc": .92, "d": [4, 7]}
		await wait(b_anim("P", "patada" if m else "golpe") * .6)
		await say("Le das una patada." if mv.n == "PATADA" else "Le das un puñetazo.")
		var g = B.get("guardia")
		var k = B.get("contra")
		B.guardia = 0
		B.contra = 0
		if g or k or Cultivo.azar() < minf(float(D.PELEA.accMax), mv.acc + int(S.pelea.ref) * float(D.PELEA.acc)):   # la fuerza suma al golpe y los reflejos, a la puntería (1.18)
			var d: int = ri(mv.d[0], mv.d[1]) + int(S.pelea.fue) + (int(D.PELEA.contra) if k else 0)
			if k:
				await say("Le pillas abierto.")
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
		prompt("¿Qué le dices?")
		var h: int = await menu(["CALMAR", "AMENAZAR"], {"cls": "battle"})
		if h < 0:
			return null
		if h == 0:
			await say("%s: «Tranquilo. Somos del mismo barrio.»" % S.name)
			if not B.get("jefe") and Cultivo.azar() < clampf(.25 + S.rep / 300.0, .25, .7):
				await say("«Vale... Tú eres el de Maite. Olvídalo.»")
				return "talk"
			await say("«Aquí ya no hay nada que hablar.»" if B.get("jefe") else "«No me cuentes historias.»")
		else:   # AMENAZAR (1.18): funciona mejor cuanto más tocado está y cuanta más fuerza tienes; si falla, te pega con rabia
			await say("%s: «Lárgate ahora que puedes.»" % S.name)
			if not B.get("jefe") and Cultivo.azar() < prob_amenaza():
				await say(("%s se lo piensa mejor." if B.has("rival") else "%s se lo piensa mejor y se va.") % el_b())
				return "talk"
			B.furia = 1
			await say("«A mí no me amenaza nadie.»" if B.get("jefe") else "«¿A mí? Ahora vas a ver.»")
	elif c == 3:
		if Cultivo.azar() < minf(float(D.PELEA.huirMax), .5 + int(S.pelea.ref) * float(D.PELEA.huir)):
			sfx("door")
			await say("Consigues escapar.")
			return "flee"
		await say("Te corta el paso. No puedes escapar.")
	if B.hp <= 0:
		if B.get("jefe"):   # Darko (1.17) no huye: se queda en el suelo, y la reputación la da ajuste_darko
			b_anim("E", "herido")
			await say("%s cae al suelo, sin aire." % el_b())
		else:
			B.gone = true
			b_anim("E", "huir")
			await say("%s sale corriendo." % el_b())
		if B.has("rival"):
			if not B.get("jefe"):
				S.rep += int(D.RIVAL.rep)
			if S.hpMax < 60:
				S.hpMax += 2
				S.hp += 2
				bhud_act()
				await say("Aguantas más. VIDA máxima: %d." % S.hpMax)
			await experiencia()
			return "win"
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
		await experiencia()
		return "win"
	return await enemy_hits()

# la experiencia (1.18): cada pelea ganada da PELEA.xp y con cada PELEA.nv subes un nivel y eliges FUERZA o REFLEJOS (13-combate.js)
func nivel_pelea() -> int:
	var x := int(S.pelea.xp)
	return D.PELEA.nv.filter(func(v): return x >= int(v)).size()

func prob_esquiva() -> float:
	return float(D.PELEA.esq0) + int(S.pelea.ref) * float(D.PELEA.esq)

func prob_amenaza() -> float:
	return clampf(float(D.PELEA.amen0) + (1 - float(B.hp) / float(B.hpMax)) * float(D.PELEA.amen) + int(S.pelea.fue) * float(D.PELEA.amenF), float(D.PELEA.amen0), float(D.PELEA.amenMax))

func experiencia() -> void:
	var P: Dictionary = S.pelea
	P.xp = int(P.xp) + int(D.PELEA.xp["darko" if B.get("jefe") else ("rival" if B.has("rival") else "thief")])
	var mx := int(D.PELEA.max)
	while nivel_pelea() > int(P.fue) + int(P.ref) and (int(P.fue) < mx or int(P.ref) < mx):
		sfx("get")
		await say("Subes a nivel %d de pelea." % (int(P.fue) + int(P.ref) + 1))
		var f := int(P.fue) < mx
		var r := int(P.ref) < mx
		var o := 0 if f else 1
		if f and r:   # sin cancelar: las dos son una elección
			await type_text("¿Qué entrenas?", "")
			o = await menu(["Fuerza", "Reflejos"], {"cls": "right", "cancel": false})
			if not oraculo:
				dlg.hide()
				dlg_nm.hide()
		if o == 0:
			P.fue = int(P.fue) + 1
			await say("FUERZA %d: cada golpe hace %d más." % [P.fue, P.fue])
		else:
			P.ref = int(P.ref) + 1
			await say("REFLEJOS %d: aciertas, esquivas y escapas mejor." % P.ref)

func ficha_pelea() -> String:   # la fila Pelea de la MOCHILA
	var P: Dictionary = S.pelea
	var nv := nivel_pelea()
	var s := "" if nv >= D.PELEA.nv.size() else " (nivel %d con %d)" % [nv + 1, int(D.PELEA.nv[nv])]
	return "Fuerza %d · reflejos %d · %d de experiencia%s.\nSube ganando peleas: un ladrón da %d, un rival %d." % [int(P.fue), int(P.ref), int(P.xp), s, int(D.PELEA.xp.thief), int(D.PELEA.xp.rival)]

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
	await sobre_caja()

# al fondo de la caja (1.25), un sobre con semillas de una landrace que no está en el banco (S.flags.cajaSem; las partidas de antes,
# la próxima vez que la abres)
func sobre_caja() -> void:
	S.flags.cajaSem = S.day
	await say("Al fondo de la caja hay un sobre de papel de estraza: «Oaxaca, 1979».")
	await semillas_tia("oaxaca", "Bien secas y a oscuras: siguen buenas.", 3)

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
	if not S.flags.get("cajaSem"):
		await sobre_caja()
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
	if cap_mochila() < g:   # 1.13
		var mi := 0
		while D.MOCHILAS[mi].g < g:
			mi += 1
		await say("No te caben en la %s. Hazte con una %s y vuelve." % [D.MOCHILAS[int(S.items.get("bolsa", 0))].n.to_lower(), D.MOCHILAS[mi].n.to_lower()], N)
		return
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
		var oi: int = await ask("El arcón: %s.\nEncima: %s de %s." % [arcon_txt(), g_txt(peso_encima()), _kg(int(cap_mochila()))] + (("\nCon los tarros, los cogollos se curan en %d días." % int(D.CURADO.dias)) if S.items.get("tarros") else ""), ops)
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
		ops.append_array(["Mensajes", "Gente"])
		if S.ch >= int(D.PLANTILLA.ch):
			ops.append("Plantilla")
		ops.append_array(["Tienda online", "Colgar"])
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
		elif op == "Gente":   # 1.15
			await gente()
		elif op == "Plantilla":   # 1.19
			await plantilla()
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
	return await fijo_menu(c.f)   # 1.15: que venga, un regalo o que venda para ti

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
	S.heat = minf(100, S.heat + 1)
	await say("%s: «Vale, voy para allá»." % f.n)
	advance_time(int(D.LLAMADA_MIN))
	update_hud()
	if not S.fijos.any(func(x): return x.id == f.id):   # 1.22: se ha largado a medianoche mientras venía (curro_dia)
		return true
	f.dia = S.day
	await talk_client({"id": "tel-" + f.id, "fijo": true, "fid": f.id, "n": f.n.to_upper(), "map": S.map, "x": P.x, "y": P.y, "type": f.t, "want": ri(int(ct.g[0]), int(ct.g[1])),
		"minThc": mini(24, 15 + int(S.ch)) if f.t == "pij" or f.t == "vip" else 0})   # 1.30: el VIP de GAUA, como un pijo
	return true

# lo que Kiko manda a casa: lo del growshop que no son semillas, carpas ni la prensa, más caro; lo que ya está pedido no se repite
func precio_envio(it: Dictionary) -> int:
	return Datos.jsround(it.p * D.ENVIO)

func pedible(it: Dictionary) -> bool:
	return not it.get("sid") and not it.get("carpa") and not it.get("mueble") and it.get("item") != "prensa" and S.ch >= it.ch and shop_cond(it)   # shop_cond ya cuenta lo pedido

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

# =========================================================
# LA GENTE (1.15, 11e-gente): trabajadores, clubs y la cata (la confianza, en mundo.gd)
# =========================================================
func curro_dia() -> void:
	var C: Dictionary = S.curro
	var J: Dictionary = D.CURRO.jard
	var V: Dictionary = D.CURRO.vend
	if C.get("jard"):
		if S.money < J.sueldo:
			C.jard = null
			confia("begona", -10)
			queue("jard", func(): await talk("SMS · BEGOÑA", ["Sin cobrar no vuelvo, majo. Cuando tengas el dinero, hablamos."]))
		else:
			S.money -= int(J.sueldo)
			cuidar_plantas()
			S.heat = min(100, S.heat + J.calor)
	var fin := []
	var vende := false
	for v in C.vend:
		var r := Cultivo.azar()
		var N: String = "SMS · " + v.n.to_upper()
		if r < V.pilla:
			fin.append(v)
			S.heat = min(100, S.heat + V.calorPilla)
			confia(v.id, -5)
			queue("vend" + v.id, func(): await talk(N, ["Me ha parado la policía. Se han quedado con %s de %s. Lo siento." % [g_txt(v.g), lot_nombre(v.k)]]))
			continue
		if r < V.pilla + V.estafa * (D.REL.max - rel(v.id)) / D.REL.max:
			fin.append(v)
			S.fijos = S.fijos.filter(func(f): return f.id != v.id)
			S.rel[v.id] = 0
			queue("vend" + v.id, func(): await say("%s no contesta al móvil. Se ha largado con %s de %s." % [v.n, g_txt(v.g), lot_nombre(v.k)]))
			continue
		var g: int = mini(int(floor(v.g)), ri(int(V.g[0]), int(V.g[1])))
		var e := Datos.jsround(precio_calle(v.thc) * calidad(v) * D.ZONAS.town.precio * g * (1 - V.com))
		v.g -= g
		S.money += e
		S.sales += e
		S.heat = min(100, S.heat + V.calor)
		confia(v.id, 1)
		vende = true
		if v.g < 1:
			fin.append(v)
			queue("vend" + v.id, func(): await talk(N, ["Vendidos los últimos %d g: %s en tu buzón. Si quieres que siga, déjame más." % [g, Datos.eur(e)]]))
		else:
			queue("vend" + v.id, func(): await talk(N, ["Vendidos %d g: %s en tu buzón. Me quedan %s." % [g, Datos.eur(e), g_txt(v.g)]]))
	if fin.size():
		C.vend = C.vend.filter(func(v): return not fin.has(v))
	if vende:   # 1.22: lo vendido cuenta para la historia
		queue("historia", check_story)
	plantilla_dia()   # la plantilla (1.19)
	aso_dia()   # la asociación (1.32)

# regar, tratar las plagas con tu insecticida y rellenar garrafas y depósitos (Begoña y el gerente de la plantilla)
func cuidar_plantas() -> void:
	for p in S.pots:
		if p == null or p.get("dead"):
			continue
		p.water = 100
		if p.get("pest") and S.items.insect > 0:
			S.items.insect -= 1
			p.pest = false
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if c == null:
			continue
		if c.get("garrafas"):
			c.erase("gar")
		if c.get("goteo"):
			c.dep = Cultivo.goteo_l(S, ci)

func _vend_de(id: String):
	for v in S.curro.vend:
		if v.id == id:
			return v
	return null

# un cliente de la agenda, desde el móvil: que venga, un regalo (una vez al día), cómo va su venta o que venda para ti
func fijo_menu(f: Dictionary) -> bool:
	var v = _vend_de(f.id)
	var puede: bool = rel(f.id) >= D.REL.socio and S.curro.vend.size() < D.CURRO.vend.max
	var ops := ["Que venga"]
	if total_buds() >= D.REL.regaloG:
		ops.append("Regalarle %d g" % int(D.REL.regaloG))
	if v:
		ops.append("Cómo va la venta")
	elif puede:
		ops.append("Que venda para mí")
	ops.append("Nada")
	var oi: int = await ask("%s · %s · confianza %d (%s)" % [f.n, D.CTYPES[f.t].label.to_lower(), rel(f.id), rel_nivel(f.id)], ops)
	var op: String = ops[oi]
	if op == "Que venga":
		return await llamar_fijo(f)
	if op.begins_with("Regalarle"):
		if f.get("regalo") == S.day:
			await say("%s: «¿Otra vez? Gracias, pero hoy ya me has invitado»." % f.n)
			return false
		var lots := bud_lots(D.REL.regaloG)
		var it := lots.map(lot_item)
		it.append({"label": "Nada"})
		var i: int = await menu(it, {"cls": "right", "title": "¿Qué le regalas?"})
		if i < 0 or i >= lots.size():
			return false
		use_buds(lots[i][0], D.REL.regaloG)
		f.regalo = S.day
		confia(f.id, int(D.REL.regalo))
		sfx("get")
		await say("%s: «¡Gracias! Se lo cuento a todo el mundo»." % f.n)
		return false
	if op == "Cómo va la venta":
		await say("%s: «Me quedan %s de %s. Cada día vendo lo que puedo y te dejo el %d %% en el buzón»." % [f.n, g_txt(v.g), lot_nombre(v.k), Datos.jsround((1 - D.CURRO.vend.com) * 100)])
		return false
	if op == "Que venda para mí":
		return await contratar_vendedor(f)
	return false

func contratar_vendedor(f: Dictionary) -> bool:
	var V: Dictionary = D.CURRO.vend
	var lots := bud_lots(V.lotes[0])
	if lots.is_empty():
		await say("%s: «Cuando tengas %d g o más, hablamos»." % [f.n, int(V.lotes[0])])
		return false
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote le dejas?"})
	if i < 0 or i >= lots.size():
		return false
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var ops := []
	for g in V.lotes:
		if g <= floor(b.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g" % g)
	o.append("Nada")
	var j: int = await ask("%s vende a precio de calle y se queda el %d %%. ¿Cuánto le dejas?" % [f.n, Datos.jsround(V.com * 100)], o)
	if j < 0 or j >= ops.size():
		return false
	use_buds(k, ops[j])
	var vd := {"id": f.id, "n": f.n, "k": k, "thc": b.thc, "g": ops[j]}
	vd.merge(cura_de(b))
	S.curro.vend.append(vd)
	sfx("sel")
	await say("%s: «Hecho. Cada día te dejo lo vendido en el buzón»." % f.n)
	return false

# MÓVIL → GENTE: a quién conoces y cuánto se fía de ti
func gente() -> void:
	var rows := []
	for id in D.GENTE:
		if S.rel.has(id):
			rows.append({"label": D.GENTE[id], "right": "%d · %s" % [rel(id), "jardinera" if id == "begona" and S.curro.get("jard") else rel_nivel(id)], "desc": D.QUE_DA.get(id, "Hablar cada día suma confianza.")})
	for k in D.CLUBS:
		if S.rel.has(k):
			rows.append({"label": D.CLUBS[k].n, "right": "%d · %s" % [rel(k), rel_nivel(k)], "desc": "Eres socio. Vender y cumplir los encargos suma." if S.clubs.get(k) else "Hazte socio para vender y comprar."})
	for f in S.fijos:
		var v = _vend_de(f.id)
		rows.append({"label": f.n, "right": "%d · %s" % [rel(f.id), "vende para ti" if v else rel_nivel(f.id)],
			"desc": ("Le dejaste %s: le quedan %s." % [lot_nombre(v.k), g_txt(v.g)]) if v else "Cliente de la agenda. Buen precio y regalos suman; con %d vende para ti." % int(D.REL.socio)})
	if rows.is_empty():
		await say("Todavía no conoces a nadie.")
		return
	var i := 0
	while true:
		i = await menu(rows, {"cls": "full", "title": "GENTE", "title2": "%d persona%s" % [rows.size(), "s" if rows.size() > 1 else ""], "desc": true, "initial": i})
		if i < 0:
			return

# Begoña (la vecina): consejos, un regalo al día y, con confianza y desde el capítulo 3, la jardinera
const BEGONA_TIPS := ["Bajo una lámpara las plantas beben mucho. Riégalas a diario, majo.", "Si se te ponen amarillas las hojas de abajo, les falta agua o abono.", "Tu tía siempre tenía el piso oliendo a limón. Ahora sé por qué."]
func talk_begona():
	var N := "BEGOÑA"
	var J: Dictionary = D.CURRO.jard
	if S.curro.get("jard"):
		var c: int = await ask("¿Qué tal las plantas, majo? Paso cada mañana: %s al día." % Datos.eur(J.sueldo), ["Charlar", "Que lo deje", "Nada"], N)
		if c == 0:
			await say(pick(BEGONA_TIPS), N)
		elif c == 1:
			S.curro.jard = null
			await say("Como quieras. Si me necesitas, aquí estoy.", N)
		return
	var ops := ["Charlar"]
	if total_buds() >= D.REL.regaloG:
		ops.append("Regalarle %d g" % int(D.REL.regaloG))
	if S.ch >= J.ch and rel("begona") >= D.REL.amigo:
		ops.append("Contratarla")
	ops.append("Nada")
	var oi: int = await ask("Tu tía me dejaba cuidarle las plantas cuando se iba. Con confianza, se habla de todo." if S.ch >= J.ch and rel("begona") < D.REL.amigo else "Hola, majo. ¿Cómo van esas plantas?", ops, N)
	var op: String = ops[oi]
	if op == "Charlar":
		await say(pick(BEGONA_TIPS), N)
	elif op.begins_with("Regalarle"):
		if S.flags.get("regBeg") == S.day:
			await say("Hoy ya me has dado, majo. Mañana más.", N)
			return
		var lots := bud_lots(D.REL.regaloG)
		var it := lots.map(lot_item)
		it.append({"label": "Nada"})
		var i: int = await menu(it, {"cls": "right", "title": "¿Qué le das?"})
		if i < 0 or i >= lots.size():
			return
		use_buds(lots[i][0], D.REL.regaloG)
		S.flags.regBeg = S.day
		confia("begona", int(D.REL.regalo))
		sfx("get")
		await say("Ay, gracias. Para dormir, como hacía tu tía.", N)
	elif op == "Contratarla":
		if await ask("Te riego, relleno las garrafas y el depósito y, si tienes insecticida, trato las plagas. %s al día, cada mañana. ¿Hecho?" % Datos.eur(J.sueldo), ["Hecho", "Ahora no"], N) != 0:
			return
		S.curro.jard = {"dia": S.day}
		await say("Mañana empiezo. Ya sé dónde dejaba la llave tu tía.", N)

# los clubs cannábicos (CLUBS): el carné, vender un lote al día, comprar 10 g y encargos de semillas
func precio_club(thc: float) -> float:
	return 3 + thc * .15

# el carné (la cuota, una vez); 1.30: también en la puerta, la primera vez que entras (entra_local). true si eres socio
func carne_club(k: String) -> bool:
	var C: Dictionary = D.CLUBS[k]
	var N: String = C.n
	if await ask("%s%s. Dentro no se vende nada: lo tuyo entra por la puerta de atrás. La cuota son %s. ¿Te haces socio?" % [C.n, "" if k == "rv" else ", asociación de consumidores", Datos.eur(C.cuota)], ["Hacerme socio", "No"], N) != 0:
		return false
	if S.money < C.cuota:
		sfx("bad")
		await say("Sin la cuota no hay carné.", N)
		return false
	S.money -= int(C.cuota)
	S.clubs[k] = true
	S.rep += 1
	confia(k, 2)
	sfx("coin")
	await got("el carné de " + C.n)
	return true

# el encargado de cada club; 1.30: dentro, detrás de la vitrina del dispensario
func talk_club(k: String):
	var N: String = D.CLUBS[k].n
	if not S.clubs.get(k):
		if not await carne_club(k):
			return
	var E = S.get("clubEnc")
	var c: int = await ask("¿Qué te trae?", ["Vender al club", "Comprar %d g" % int(D.CLUB.compra), "Entregar las semillas" if E and E.k == k else "Encargo de semillas", "Nada"], N)
	if c == 0:
		await vender_club(k)
	elif c == 1:
		await comprar_club(k)
	elif c == 2:
		await encargo_club(k)

func vender_club(k: String) -> void:
	var C: Dictionary = D.CLUBS[k]
	var N: String = C.n
	if S.clubDia.get(k) == S.day:
		await say("Hoy ya hemos cerrado caja. Mañana.", N)
		return
	var lots := bud_lots(D.CLUB.g[0])
	if lots.is_empty():
		await say("De %d g para arriba, entre %s y %s € el gramo según el THC. Una entrega al día." % [int(D.CLUB.g[0]), _dos(precio_club(12)), _dos(precio_club(30))], N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		return
	var kk: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var pg := Datos.jsround(precio_club(b.thc) * calidad(b) * (1.05 if b.get("ana") else 1.0) * 100) / 100.0
	var ops := []
	for g in D.CLUB.g:
		if g <= floor(b.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(g * pg)])
	o.append("Nada")
	var j: int = await ask("%s a %s € el gramo%s. ¿Cuánto?" % [lot_nombre(kk), _dos(pg), " (analizado)" if b.get("ana") else ""], o, N)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	var e := Datos.jsround(g * pg)
	use_buds(kk, g)
	S.money += e
	S.sales += e
	S.heat = min(100, S.heat + D.CLUB.calor)
	S.rep += 1
	S.clubDia[k] = S.day
	confia(k, 2)
	sfx("coin")
	await accion("vender", {"id": "vfx-monedas", "x": P.px + 8, "y": P.py + 2})
	toast("+%s · %d g al club" % [Datos.eur(e), g], 1600)
	await say("Por la puerta de atrás, como siempre. Gracias.", N)
	await check_story()

func comprar_club(k: String) -> void:
	var C: Dictionary = D.CLUBS[k]
	var N: String = C.n
	if S.clubCompra.get(k) == S.day:
		await say("Lo de hoy ya está repartido. Mañana hay más.", N)
		return
	var sid: String = C.sid[int(S.day) % C.sid.size()]
	var s: Dictionary = D.STRAINS[sid]
	var p := Datos.jsround(precio_calle(s.thc) * D.CLUB.compraF * D.CLUB.compra)
	if await ask("Hoy tenemos %s (%s %%): %d g por %s. ¿Te los llevas?" % [s.n, Datos.pct(s.thc), int(D.CLUB.compra), Datos.eur(p)], ["Comprar", "No"], N) != 0:
		return
	if S.money < p:
		sfx("bad")
		await say("Sin dinero no hay reparto.", N)
		return
	if libre_mochila() < D.CLUB.compra:
		await say("No te caben en la bolsa.", N)
		return
	S.money -= p
	S.clubCompra[k] = S.day
	add_buds(sid, D.CLUB.compra, s.thc, S.buds, 1)
	discover(sid)
	sfx("coin")
	toast("Comprado: %d g de %s" % [int(D.CLUB.compra), s.n], 1200)

func encargo_club(k: String) -> void:
	var N: String = D.CLUBS[k].n
	var E = S.get("clubEnc")
	var EN: Dictionary = D.CLUB.enc
	if E:
		if E.k != k:
			await say("Ya tienes un encargo pendiente en %s. Cumple ese primero." % D.CLUBS[E.k].n, N)
			return
		var s = strain(E.sid)
		var t: int = int(S.seeds.get(E.sid, 0))
		if t < E.n:
			await say("Nos faltan %d semillas de %s. Hasta el día %s." % [int(E.n) - t, s.n, n(E.hasta)], N)
			return
		S.seeds[E.sid] = t - int(E.n)
		if not S.seeds[E.sid]:
			S.seeds.erase(E.sid)
		S.money += int(E.pago)
		S.sales += int(E.pago)
		S.rep += 3
		confia(k, 5)
		S.clubEnc = null
		S.clubEncDia = S.day
		sfx("coin")
		toast("+%s · %d semillas de %s" % [Datos.eur(E.pago), int(E.n), s.n], 1600)
		await say("Las sembramos para los socios. Buen trabajo.", N)
		await check_story()
		return
	if S.clubEncDia == S.day:
		await say("Hoy ya no hay más encargos. Mañana.", N)
		return
	var cand := []
	for it in D.SHOP:
		if it.get("sid") and S.ch >= it.ch:
			cand.append([it.sid, Datos.jsround(it.p * EN.n * EN.f)])
	if S.ch >= 4:
		var vistos := []
		for h in D.RECIPES:
			var sr: String = D.RECIPES[h]
			if not vistos.has(sr):
				vistos.append(sr)
				if S.disc.get(sr):
					cand.append([sr, int(EN.receta) * int(EN.n)])
	var el: Array = pick(cand)
	var sid: String = el[0]
	var pago: int = el[1]
	var s: Dictionary = D.STRAINS[sid]
	if await ask("Los socios quieren %d semillas de %s. Pagamos %s, en %d días. ¿Te encargas?" % [int(EN.n), s.n, Datos.eur(pago), int(EN.dias)], ["Aceptar", "No"], N) != 0:
		await say("Si cambias de idea, aquí estamos.", N)
		return
	S.clubEnc = {"k": k, "sid": sid, "n": int(EN.n), "hasta": S.day + int(EN.dias), "pago": pago}
	await say("Hasta el día %s. Las semillas, aquí." % n(S.clubEnc.hasta), N)

func vencer_encargo_club() -> void:
	var E = S.get("clubEnc")
	if E == null or S.day <= E.hasta:
		return
	S.clubEnc = null
	S.rep = maxi(0, S.rep - 3)
	confia(E.k, -10)
	queue("clubEnc", func(): await talk("SMS · " + D.CLUBS[E.k].n, ["Se acabó el plazo de las semillas. Los socios no se olvidan."]))

# la cata (desde la mochila) y el analizador de THC
func nota_cata(sid: String, thc: float) -> String:
	var ind := Datos.ind_de(S, sid)
	var a: String = aroma_de(sid)
	var e := "relaja y pesa" if ind >= 65 else ("sube y despeja" if ind <= 35 else "equilibrado")
	var p: String = (Datos.pct(thc) + " % de THC") if S.items.get("analizador") else ("floja" if thc < 12 else ("media" if thc < 18 else ("fuerte" if thc < 24 else "muy fuerte")))
	return "Aroma %s%s · %s · %s" % [a, (" (" + D.TERPENOS[a] + ")") if S.items.get("analizador") else "", e, p]

func aroma_de(sid: String) -> String:
	return D.AROMAS[Datos.hash_str(sid) % D.AROMAS.size()]

func cbd_de(sid: String) -> float:   # CBD del 0,2 al 1 % según el % índica
	return Datos.jsround(20 + Datos.ind_de(S, sid) * 0.8) / 100.0

func catar(k: String) -> void:
	var b = S.buds.get(k)
	if b == null or b.g < D.CATA.g:
		return
	var sid := lot_sid(k)
	var thc: float = b.thc
	var cu := float(b.get("cu", 0))
	var fresca: bool = b.get("dia") != null
	use_buds(k, D.CATA.g)
	if S.buds.has(k):
		S.buds[k].cata = true
	S.catas[sid] = nota_cata(sid, thc)
	advance_time(int(D.CATA.min))
	update_hud()
	await say("Catas %s: %s." % [lot_nombre(k), S.catas[sid]] + (" Bien curada: suave y con todo el aroma." if cu >= 1 else (" Sin curar del todo: rasca y huele a verde." if cu or fresca else "")))   # 1.29

func analizar(k: String) -> void:
	var b = S.buds.get(k)
	if b == null or not S.items.get("analizador"):
		return
	b.ana = true
	sfx("get")
	var sid := lot_sid(k)
	await say("Analizado: %s · THC %s %% · CBD %s %% · terpeno principal, %s. Lo que va con análisis se vende mejor." % [lot_nombre(k), Datos.pct(b.thc), Datos.pct(cbd_de(sid)), D.TERPENOS[aroma_de(sid)]])

func lote_accion(k: String) -> void:
	var b: Dictionary = S.buds[k]
	var ops := ["Catar %s g" % Datos.coma(D.CATA.g)]
	if S.items.get("analizador") and not b.get("ana"):
		ops.append("Analizar")
	ops.append("Nada")
	var oi: int = await ask("%s: %d g · %s %%%s%s%s" % [lot_nombre(k), int(floor(b.g)), Datos.pct(b.thc), cura_corto(b), " · catado" if b.get("cata") else "", " · analizado" if b.get("ana") else ""], ops)
	var op: String = ops[oi]
	if op.begins_with("Catar"):
		await catar(k)
	elif op == "Analizar":
		await analizar(k)

# los rivales (1.16, 13-combate): en las zonas de venta lejos de Darko, un camello que no quiere competencia. Cada venta en la calle
# de su zona le suma una (S.rivales[zona]); con RIVAL.umbral sale a buscarte: pelear, pagarle su cuota o irte
func nom_rival(R: Dictionary) -> String:
	return R.n.substr(0, 1) + R.n.substr(1).to_lower()

func cuota_rival(z: String) -> int:
	return Datos.jsround(D.RIVAL.cuota * D.ZONAS[z].precio)

func rival_b(kind := "rival") -> Dictionary:
	if kind == "darko":
		return {"kind": "thief", "rival": "Darko", "jefe": 1, "name": "DARKO", "look": D.LOOKS.darko, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	var R: Dictionary = D.RIVALES.get(S.map, D.RIVALES.alto)
	return {"kind": "thief", "rival": nom_rival(R), "name": R.n, "look": Datos.rand_look("rival" + R.n, "thief"), "t": 0.0, "flashE": 0.0, "shakeP": 0.0}

func rival_venta(z):
	if S.ch < D.RIVAL.ch or not D.RIVALES.has(z) or float(S.rivalFuera.get(z, 0)) >= S.day:
		return
	S.rivales[z] = int(S.rivales.get(z, 0)) + 1
	if S.rivales[z] >= D.RIVAL.umbral:
		queue("rival", func(): await rival_event(z))

func rival_event(z: String) -> void:
	if S.map != z:   # si te has ido de su zona, te buscará en la próxima venta
		return
	var R: Dictionary = D.RIVALES[z]
	var N: String = R.n
	var nom := nom_rival(R)
	var c := cuota_rival(z)
	await talk(N, ["Eh, tú. Llevas %d ventas en %s." % [int(S.rivales[z]), R.sitio], R.frase, "O me pagas %s o lo arreglamos aquí." % Datos.eur(c)])
	var o: int = await ask("¿Qué haces?", ["Pelear", "Pagarle " + Datos.eur(c), "Irte"], N)
	if o == 0:
		var r = await battle("rival")
		if r == "win":
			S.rivalFuera[z] = S.day + int(D.RIVAL.dias)
			S.rivales[z] = 0
			sfx("get")
			await say("%s no volverá por %s en %d días. Mientras, sus clientes te pagan un %d %% más." % [nom, R.sitio, int(D.RIVAL.dias), Datos.jsround((D.RIVAL.f - 1) * 100)])
			return
		if r == "talk":
			S.rivales[z] = 0
			await say("%s: «Vale. Pero no te quiero ver tanto por aquí.»" % nom)
			return
		S.rivales[z] = 0 if r == "ko" else int(D.RIVAL.umbral) - int(D.RIVAL.vuelve)
		return
	if o == 1 and S.money >= c:
		S.money -= c
		S.rivales[z] = 0
		sfx("coin")
		update_hud()
		await say("%s se guarda el dinero. «Así me gusta. Hasta la próxima.»" % nom)
		return
	if o == 1:
		await say("No llevas tanto dinero encima.")
	S.rivales[z] = int(D.RIVAL.umbral) - int(D.RIVAL.vuelve)
	await say("Te apartas. %s se queda mirándote." % nom)

# ---------- la plantilla (1.19, 11f-plantilla): gente del barrio que trabaja para ti ----------
func ficha_gente(w: Dictionary) -> String:
	return "Labia %d · cuidado %d · lealtad %d" % [w.lab, w.cui, w.lea]

func gerente():
	for w in S.plantilla:
		if w.get("rol") == "gerente":
			return w
	return null

func naveros() -> Array:
	return S.plantilla.filter(func(w): return w.get("rol") == "nave")

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
		return "calle · " + g_txt(w.g)
	return w.rol if w.get("rol") else "sin trabajo"

func rol_desc(w: Dictionary) -> String:
	var P: Dictionary = D.PLANTILLA
	match w.get("rol"):
		"calle":
			return "Vende %s en la calle: le quedan %s." % [lot_nombre(w.k), g_txt(w.g)]
		"gerente":
			return "Cuida el piso y cosecha al arcón por %s al día." % Datos.eur(P.sueldo.gerente)
		"nave":
			return "Cultiva la mesa %d de la nave por %s al día: %d g." % [int(w.mesa) + 1, Datos.eur(P.sueldo.nave), nave_g(w)]
	return "Dale trabajo: calle, gerente o nave."

# deja el trabajo; lo que le quedaba del lote vuelve al arcón
func libre(w: Dictionary) -> void:
	if w.get("rol") == "calle" and w.g >= 1:
		add_buds(w.k, w.g, w.thc, S.arcon.buds, w.get("cu"), w.get("dia"))
	w.rol = null
	w.erase("k")
	w.erase("thc")
	w.erase("g")
	w.erase("cu")
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
			rows.append({"label": "Pedir gente a Patxi", "right": Datos.eur(P.sobre), "desc": "Patxi te manda a alguien del barrio que quiere currar. No sabes a quién hasta que llega."})
		var t2: String = "%d de %d" % [L.size(), int(P.max)] + ((" · nave " + g_txt(nave_stock())) if S.get("nave") != null else "")
		i = await menu(rows, {"cls": "full", "title": "PLANTILLA", "title2": t2, "desc": true, "initial": mini(i, rows.size() - 1)})
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
		await say("Patxi cobra %s por el sobre. No te llega." % Datos.eur(P.sobre))
		return
	if libres.is_empty():
		await say("Patxi ya no conoce a nadie más que quiera currar.")
		return
	S.money -= int(P.sobre)
	var nm: String = pick(libres)
	S.plN = int(S.plN) + 1
	var w := {"id": "pl%d" % int(S.plN), "n": nm, "lab": ri(1, 5), "cui": ri(1, 5), "lea": ri(1, 5), "rol": null}
	var t: int = w.lab + w.cui + w.lea
	sfx("get")
	await talk("SMS · PATXI", ["Te mando a %s. %s" % [nm, "Vale oro." if t >= 12 else ("No es gran cosa, pero quiere currar." if t <= 6 else "Gente normal del barrio.")]])
	if await ask("%s: %s. ¿Le contratas?" % [nm, ficha_gente(w)], ["Contratar", "No"]) != 0:
		await say("%s se va por donde ha venido. El sobre ya es de Patxi." % nm)
		return
	S.plantilla.append(w)
	sfx("sel")
	await say("%s entra en tu plantilla. Dale trabajo desde aquí." % nm)

# un lote de los de encima para la calle: [clave, THC, gramos] o null
func lote_calle(w: Dictionary):
	var P: Dictionary = D.PLANTILLA
	var lots := bud_lots(P.lotes[0])
	if lots.is_empty():
		await say("Para la calle hace falta un lote de %d g o más encima." % int(P.lotes[0]))
		return null
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote le das?"})
	if i < 0 or i >= lots.size():
		return null
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var ops := []
	for g in P.lotes:
		if g <= floor(b.g):
			ops.append(int(g))
	var o2 := ops.map(func(g): return "%d g" % g)
	o2.append("Nada")
	var j: int = await ask("%s vende a precio de calle y se queda el %d %%. ¿Cuánto le das?" % [w.n, Datos.jsround(P.com * 100)], o2)
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
		ops.append("A la calle")
	if w.get("rol") != "gerente" and gerente() == null:
		ops.append("De gerente")
	if w.get("rol") != "nave" and S.get("nave") != null and naveros().size() < int(D.NAVE.max):
		ops.append("A la nave")
	if w.get("rol"):
		ops.append("Dejarlo libre")
	ops.append_array(["Despedir", "Nada"])
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
		await say("%s: «Hecho. Cada día te dejo lo vendido en el buzón»." % w.n)
	elif op == "De gerente":
		libre(w)
		w.rol = "gerente"
		sfx("sel")
		await say("%s: «Cada mañana me paso por el piso: riego, trato las plagas y lo que esté listo lo cosecho y lo dejo en el arcón. %s al día»." % [w.n, Datos.eur(P.sueldo.gerente)])
	elif op == "A la nave":
		libre(w)
		w.mesa = mesa_libre()
		w.rol = "nave"
		sfx("sel")
		await say("%s: «Mañana empiezo en la mesa %d de la nave. %s al día»." % [w.n, int(w.mesa) + 1, Datos.eur(P.sueldo.nave)])
	elif op == "Dejarlo libre":
		var g: float = w.g if w.get("rol") == "calle" else 0.0
		libre(w)
		await say(("%s te deja lo que le quedaba en el arcón: %s." % [w.n, g_txt(g)]) if g >= 1 else "%s se queda sin trabajo." % w.n)
	elif op == "Despedir":
		if await ask("¿Despides a %s?" % w.n, ["Despedir", "No"]) != 0:
			return
		var g: float = w.g if w.get("rol") == "calle" else 0.0
		libre(w)
		S.plantilla = S.plantilla.filter(func(x): return x != w)
		await say("%s se va." % w.n + ((" Lo que le quedaba, %s, está en el arcón." % g_txt(g)) if g >= 1 else ""))

# el gerente, cada mañana: cuida las plantas y cosecha las que están listas al arcón (su sisa, por la lealtad); da los gramos
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
			add_buds(p.sid + "*" if cl == "estrella" else p.sid, q, thc, S.arcon.buds)
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
		var N: String = "SMS · " + w.n.to_upper()
		var tt := tot
		queue("gerente", func(): await talk(N, ["He cosechado %d g. Está en el arcón." % tt]))
		queue("historia", check_story)
	return tot

# al amanecer (desde curro_dia): sueldos, el gerente, la calle y la nave
func plantilla_dia() -> void:
	var P: Dictionary = D.PLANTILLA
	var fuera := []
	var vende := false
	nave_alquiler()
	for w in S.plantilla:
		if w.get("rol") != "gerente" and w.get("rol") != "nave":
			continue
		if S.money < P.sueldo[w.rol]:
			w.rol = null
			var N: String = "SMS · " + w.n.to_upper()
			queue("pl" + w.id, func(): await talk(N, ["Sin cobrar no curro. Cuando tengas el dinero, me llamas."]))
		else:
			S.money -= int(P.sueldo[w.rol])
	var ger = gerente()
	if ger != null:
		cuidar_casa(ger)
	for w in S.plantilla:
		if w.get("rol") != "calle":
			continue
		var N: String = "SMS · " + w.n.to_upper()
		var lote := lot_nombre(w.k)
		var r := Cultivo.azar()
		var pp: float = P.poli - P.poliC * (w.cui - 1)
		var pr: float = pp + P.robo - P.roboC * (w.cui - 1)
		var pf: float = pr + P.fuga * (5 - w.lea) / 4 * (.5 if ger != null else 1.0)
		var pt: float = pf + P.timo - P.timoL * (w.lab - 1)
		var m := ""
		if r < pp:
			S.heat = min(100, S.heat + P.calorPoli)
			m = "Me ha parado la policía. Se han quedado con %s de %s. Lo siento." % [g_txt(w.g), lote]
			w.g = 0
		elif r < pr:
			var q: int = int(ceil(w.g / 2.0))
			w.g -= q
			m = "Me han atracado en un portal. Se han llevado %s de %s." % [g_txt(q), lote] + ((" Me quedan %s." % g_txt(w.g)) if w.g >= 1 else "")
		elif r < pf:
			fuera.append(w)
			var gg: float = w.g
			var nm: String = w.n
			queue("pl" + w.id, func(): await say("%s no contesta al móvil. Se ha largado con %s de %s." % [nm, g_txt(gg), lote]))
			continue
		else:
			var q: int = mini(int(floor(w.g)), ri(int(P.g[0]), int(P.g[1])) * int(w.lab))
			w.g -= q
			if r < pt:
				m = "Me han pagado %d g con billetes falsos. No me he dado cuenta hasta el banco." % q
			else:
				var e := Datos.jsround(precio_calle(w.thc) * calidad(w) * D.ZONAS.town.precio * q * (1 - P.com))
				S.money += e
				S.sales += e
				S.heat = min(100, S.heat + P.calor)
				vende = true
				m = ("Vendidos %d g: %s en tu buzón. Me quedan %s." % [q, Datos.eur(e), g_txt(w.g)]) if w.g >= 1 else ("Vendidos los últimos %d g: %s en tu buzón. Dame más cuando quieras." % [q, Datos.eur(e)])
		if w.g < 1:
			libre(w)
		var mm := m
		queue("pl" + w.id, func(): await talk(N, [mm]))
	if fuera.size():
		S.plantilla = S.plantilla.filter(func(w): return not fuera.has(w))
	if vende:   # 1.22: lo vendido cuenta para la historia
		queue("historia", check_story)
	nave_dia()

# la nave: el alquiler, lo primero de la mañana (antes que los sueldos; sin él, Arrieta cambia la cerradura y se queda la fianza)
func nave_alquiler() -> void:
	if S.get("nave") == null:
		return
	if S.money < D.NAVE.dia:
		for w in naveros():
			libre(w)
		S.nave = null
		queue("nave", func(): await talk("SMS · ARRIETA", ["No me has pagado la nave. Cambio la cerradura y me quedo la fianza."]))
		return
	S.money -= int(D.NAVE.dia)

# después de la calle, la redada (menos con cuidado) y lo que da cada mesa que ya da (1.30): cada trabajador cuida la suya (w.mesa);
# nave_g × el rendimiento de lo plantado y, con su abono y dosis en la estantería, lo del abono (ABONO, ABONO_BIO), al secadero de
# esa mesa (Me.g, con su THC medio, Me.t, y el día de la cosecha de lo más viejo que cuelga, Me.cd: 1.31)
func nave_dia() -> void:
	var N = S.get("nave")
	if N == null:
		return
	var W := naveros()
	if W.is_empty() or not N.m.any(func(x): return x != null):
		return
	var mc := 0
	for w in W:
		mc = maxi(mc, int(w.cui))
	if Cultivo.azar() < maxf(0, D.NAVE.redada - D.NAVE.redadaC * mc):
		var ns: Array = W.map(func(w): return w.n)
		var quien: String = (", ".join(PackedStringArray(ns.slice(0, -1))) + " y " + ns[-1]) if ns.size() > 1 else ns[0]
		var gg: float = nave_stock()
		S.nave = null
		S.plantilla = S.plantilla.filter(func(w): return w.get("rol") != "nave")
		S.heat = min(100, S.heat + D.NAVE.calor)
		sfx("bad")
		queue("nave", func(): await say("La policía ha entrado en la nave de Valdehierro. Se lleva las plantas%s y a %s." % [(", " + g_txt(gg)) if gg >= 1 else "", quien]))
		return
	for i in W.size():
		var Me = N.m[int(W[i].mesa)]
		if not Me or S.day - Me.dia < D.NAVE.crece:
			continue
		var g: float = nave_g(W[i]) * Me.y
		var thc: float = Me.thc
		if Me.abo == 1 and N.ab.m > 0:
			N.ab.m -= 1
			g *= 1 + D.ABONO.rend
			thc += D.ABONO.thc
		elif Me.abo == 2 and N.ab.o > 0:
			N.ab.o -= 1
			g *= 1 + D.ABONO_BIO.rend
			thc += D.ABONO_BIO.thc
		g = Datos.jsround(g * 10) / 10.0
		if not (Me.g >= 1):   # lo que queda por debajo de 1 g no se recoge: cuenta como vacío
			Me.cd = S.day
		Me.t = Datos.jsround((Me.t * Me.g + thc * g) / (Me.g + g) * 10) / 10.0
		Me.g = Datos.jsround((Me.g + g) * 10) / 10.0

# Arrieta, el dueño de la nave de Valdehierro
func talk_nave() -> void:
	var A := "ARRIETA"
	var N = S.get("nave")
	if S.ch < int(D.NAVE.ch):
		await say("La nave no se alquila. Ahora mismo, no.", A)
		return
	if N == null:
		if await ask("La nave está vacía: %s de fianza y %s al día, que te cobro cada mañana. Sin preguntas." % [Datos.eur(D.NAVE.fianza), Datos.eur(D.NAVE.dia)], ["Alquilarla", "No"], A) != 0:
			return
		if S.money < D.NAVE.fianza:
			sfx("bad")
			await say("Sin la fianza no hay llave.", A)
			return
		S.money -= int(D.NAVE.fianza)
		S.nave = nave_nueva()
		sfx("coin")
		await got("la llave de la nave")
		await say("Dentro hay %d mesas de cultivo, una por persona. Pon a tu gente desde el móvil y planta tú lo que quieras." % int(D.NAVE.max), A)
		return
	var ops := ["Dejar la nave", "Nada"]
	var oi: int = await ask("La nave: %d de %d mesas plantadas · %d de %d trabajando. Lo demás, dentro." % [N.m.filter(func(x): return x != null).size(), int(D.NAVE.max), naveros().size(), int(D.NAVE.max)], ops, A)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op == "Dejar la nave":
		if await ask("¿Dejas la nave? Te devuelvo la fianza%s." % ("; lo que no recojas se queda aquí" if nave_stock() >= 1 else ""), ["Dejarla", "No"], A) != 0:
			return
		for w in naveros():
			libre(w)
		S.nave = null
		S.money += int(D.NAVE.fianza)
		sfx("coin")
		await say("Trato hecho. Si la quieres otra vez, ya sabes dónde estoy.", A)

# ---------- los locales (1.30, 11j-locales): los clubs por dentro, la nave y GAUA ----------
# la puerta de un local (on_step_end, mundo.gd): cerrada, te deja delante; el club, la primera vez, el carné; GAUA, la entrada
func entra_local(d: Dictionary):
	var gk: PackedStringArray = String(d.gate).split(":")
	var t: String = gk[0]
	if t == "club":
		var k: String = gk[1]
		if S.ch < int(D.CLUBS[k].ch):
			atras_puerta()
			await say("Una puerta sin rótulo, con un timbre. No abre nadie.")
			return
		if not S.clubs.get(k):
			atras_puerta()
			if not await carne_club(k):
				return
		if k == "rv":   # 1.32: la asociación
			await entra_aso(d)
			return
	elif t == "nave":
		if S.get("nave") == null:
			atras_puerta()
			await say("La persiana está echada con un candado. La llave la tiene Arrieta, el dueño.")
			return
	elif t == "disco":
		if S.ch < int(D.DISCO.ch) or not disco_abierta():
			atras_puerta()
			await say("%s abre de 23:00 a 6:00." % D.DISCO.n)
			return
		if not noche_ya():
			atras_puerta()
			if not await entrada_disco():
				return
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
	if S.map.begins_with("club-"):
		var k: String = S.map.substr(5)
		var C: Dictionary = D.CLUBS[k]
		match o:
			"tarros":
				txt = "Tarros de cristal con la etiqueta de cada variedad que ha pasado por el club."
			"pizarra":
				txt = "En la pizarra, a tiza: «Hoy, %s»." % strain(C.sid[int(S.day) % C.sid.size()]).n
			"cartelC":
				txt = "NORMAS DE %s\nSolo socios mayores de edad, con el carné a la vista. Lo que se retira, se consume dentro." % C.n
			"tacos":
				txt = "El taquero: seis tacos, la tiza y el triángulo."
			"vitrina":
				txt = "La vitrina del dispensario: tarros con muestras y una báscula de precisión."
			"mesita":
				txt = "Una mesa baja con un cenicero, un grinder y un librillo."
			"sofaF", "sofaF2", "sofaB", "sofaB2":
				txt = "Un sofá chester de cuero verde, gastado de tanto uso."
			"billar", "billar2":
				txt = "La mesa de billar, con el tapete recién cepillado. %s juega con apuesta." % D.BILLAR.n[k]
			"poster":
				txt = "Un cartel antiguo de una feria del cáñamo."
			"fotoMaite":   # 1.32
				txt = "%s, en un campo. En la placa: «Maite, presidenta fundadora»." % ("La tía Maite y Delroy, de jóvenes" if aso().tio else "La tía Maite, joven, con un hombre de rastas negras")
			"plantDeco":
				txt = "Una kentia en una maceta de barro."
	if S.map == "nave":
		if S.get("nave") == null:
			await say("La nave está vacía.")
			return true
		match o:
			"mesaN", "mesaN2":
				await mesa_nave(mesa_de(x if o == "mesaN" else x - 1))
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
			"crate":
				txt = "Sacos de sustrato y macetas apiladas."
	if S.map == "disco":
		match o:
			"bottles":
				txt = "Botellas de ginebra, ron y vodka, iluminadas desde abajo."
			"neon":
				txt = "El neón de %s: la luna rosa." % D.DISCO.n
			"altavoz":
				txt = "El altavoz retumba en el pecho."
			"cabina", "cabina2":
				txt = "La cabina del DJ: dos platos y la mesa de mezclas."
			"sofaV", "sofaV2", "mesaV":
				txt = "El reservado: sofá de terciopelo y una cubitera en la mesa."
			"cordon", "cordonF":
				txt = "El cordón del reservado. Lo abre la RRPP."
	if txt == "":
		return false
	await say(txt)
	return true

# ---------- el club: el socio y el billar ----------
func talk_socio(k: String):
	var nn: String = D.SOCIO.n[k]
	var N := nn.to_upper()
	var c: int = await ask(pick(["¿Qué tal? Siéntate, hay sitio.", "Aquí se está tranquilo, ¿eh?"]), ["Charlar", "Compartir uno", "Nada"], N)
	if c == 0:
		await say(pick(D.SOCIO.charla), N)
		return
	if c != 1:
		return
	if S.porro.get(k) == S.day:
		await say("Hoy ya hemos compartido. Mañana, más.", N)
		return
	var lots := bud_lots(D.SOCIO.g)
	if lots.is_empty():
		await say("Cuando tengas algo encima, lo compartimos. Con %s vale." % g_txt(D.SOCIO.g), N)
		return
	var it: Array = lots.map(func(l): return lot_item(l))
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué compartes?"})
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
	await say("Compartes %s en el sofá. %s: «%s»" % [lot_nombre(kk), nn, "Esto es otra liga. Se lo cuento a los del club." if thc >= 20 else "Suave, de los de charlar. Gracias."])

# el billar: hasta BILLAR.dia partidas al día con cada uno, de BILLAR.tiros tiros. Cada tiro, la barra de fuerza va y viene: con A
# en el verde, la bola dentro (3 puntos); en el amarillo, la rozas (1). El otro mete con BILLAR.hab × 0,6 y la roza hasta BILLAR.hab
var TIRO = null   # la barra mientras apuntas: {t0}, en el reloj del juego (pinta.gd la dibuja)

func fuerza_tiro(ms: float) -> float:
	var f: float = fmod(ms, float(D.BILLAR.periodo)) / float(D.BILLAR.periodo)
	return f * 2 if f < .5 else 2 - f * 2

func puntos_tiro(p: float) -> int:
	var d: float = absf(p - D.BILLAR.centro)
	return 3 if d <= D.BILLAR.verde else (1 if d <= D.BILLAR.amarillo else 0)

func tiro_rival() -> int:
	var r := Cultivo.azar()
	return 3 if r < D.BILLAR.hab * .6 else (1 if r < D.BILLAR.hab else 0)

# un tiro: el texto y, con A, dónde estaba la barra (de 0 a 1; 1.31: arranca en un punto al azar, para que no baste con contar); las
# pruebas lo cambian (gancho_billar, ui.gd)
func tiro_billar(txt: String) -> float:
	if gancho_billar.is_valid():
		return float(gancho_billar.call(txt))
	await type_text(txt, "BILLAR")
	var pr := Motor.Prom.new()
	TIRO = {"t0": M.reloj - Cultivo.azar() * D.BILLAR.periodo}
	push(func(b: String):
		if b == "A":
			pop()
			pr.res(fuerza_tiro(M.reloj - TIRO.t0)))
	var p: float = await Motor.espera(pr)
	TIRO = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	sfx("hit")
	return p

func talk_billar(k: String):
	var nb: String = D.BILLAR.n[k]
	var N := nb.to_upper()
	var Db = S.billar.get(k)
	if not (Db is Dictionary and Db.d == S.day):
		Db = {"d": S.day, "n": 0}
		S.billar[k] = Db
	if Db.n >= D.BILLAR.dia:
		await say("Por hoy ya está bien. Mañana te doy la revancha.", N)
		return
	var ops: Array = D.BILLAR.apuestas.map(func(e): return "A " + Datos.eur(e))
	ops.append("Nada")
	var c: int = await ask("¿Unas bolas? %d tiros cada uno: la bola dentro, 3 puntos; si la rozas, 1. Quien sume más se lleva la apuesta." % int(D.BILLAR.tiros), ops, N)
	if c < 0 or c >= D.BILLAR.apuestas.size():
		return
	var e: int = int(D.BILLAR.apuestas[c])
	if S.money < e:
		sfx("bad")
		await say("Sin dinero encima no se juega.", N)
		return
	Db.n += 1
	var yo := 0
	var el := 0
	var T := ["Fallas", "La rozas: 1 punto", "¡Dentro! 3 puntos"]
	var RT := ["falla", "la roza", "¡dentro!"]
	for i in int(D.BILLAR.tiros):
		var p := puntos_tiro(await tiro_billar("Tiro %d de %d · tú %d, %s %d. Pulsa A con la barra en el verde." % [i + 1, int(D.BILLAR.tiros), yo, nb, el]))
		var q := tiro_rival()
		yo += p
		el += q
		await say("%s. %s: %s." % [T[[0, 1, 3].find(p)], nb, RT[[0, 1, 3].find(q)]])
	if yo > el:
		S.money += e
		confia(k, 1)
		sfx("coin")
	elif yo < el:
		S.money -= e
		sfx("bad")
	advance_time(int(D.BILLAR.min))
	update_hud()
	if yo > el:
		await say("%d a %d: ganas tú. %s te paga %s: «La próxima, la revancha»." % [yo, el, nb, Datos.eur(e)])
	elif yo < el:
		await say("%d a %d: gana %s. Le pagas %s." % [yo, el, nb, Datos.eur(e)])
	else:
		await say("%d a %d: empate. Nadie paga." % [yo, el])

# ---------- la nave: mesas, estantería, secadero y escritorio ----------
# S.nave: {m: las NAVE.max mesas (null, vacía, o {k: el lote, f: el fenotipo, thc, y: × cosecha, dia: el de plantar, g y t: lo que hay
# en el secadero y su THC medio, abo: 0 sin abono, 1 MEATZA, 2 ORTUA BIO}), ab: {m, o}: dosis de floración de cada marca en la estantería}
func nave_nueva() -> Dictionary:
	var m := []
	m.resize(int(D.NAVE.max))
	return {"m": m, "ab": {"m": 0, "o": 0}}

# la mesa de la nave que empieza en la columna x (MESAS_X), o −1
func mesa_de(x: int) -> int:
	for i in D.MESAS_X.size():
		if int(D.MESAS_X[i]) == x:
			return i
	return -1

func nave_stock() -> float:
	var t := 0.0
	if S.get("nave") != null:
		for Me in S.nave.m:
			if Me:
				t += Me.g
	return t

func fase_mesa(i: int) -> int:
	if S.get("nave") == null or i < 0 or i >= S.nave.m.size() or not S.nave.m[i]:
		return 0
	var d: int = int(S.day - S.nave.m[i].dia)
	return 1 if d < 1 else (2 if d < 3 else (3 if d < D.NAVE.crece else 4))

func thc_nave(sid: String, f) -> float:
	return Datos.jsround(strain(sid).thc * (f.t if f else 1.0) * D.NAVE.thc * 10) / 10.0

func mesa_txt(Me: Dictionary) -> String:
	return strain(lot_sid(Me.k)).n + etiq(Me.get("f"))

func mesa_nave(i: int) -> void:
	var N: Dictionary = S.nave
	var Me = N.m[i]
	var w = navero_de(i)
	var ops: Array = ["Arrancar y plantar" if Me else "Plantar"]
	if Me:
		ops.append("Abono")
	ops.append("Nada")
	var que: String = (mesa_txt(Me) + " · " + D.FASE_MESA[fase_mesa(i)] + " · " + D.ABONO_MESA[int(Me.abo)]) if Me else "vacía"
	var oi: int = await ask("Mesa %d · %s\n%s" % [i + 1, que, ("La cuida " + w.n + ".") if w else "Nadie la cuida: pon a alguien de tu plantilla en la nave."], ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op == "Plantar" or op == "Arrancar y plantar":
		if Me and Me.g >= 1:
			await say("Antes, descuelga del secadero lo de esta mesa.")
			return
		await plantar_mesa(i)
	elif op == "Abono":
		var c: int = await ask("¿Qué abono le echa cada día? En la estantería: MEATZA ×%d · ORTUA BIO ×%d." % [int(N.ab.m), int(N.ab.o)], ["Sin abono", "MEATZA Floración", "ORTUA BIO Floración", "Nada"])
		if c < 3:
			Me.abo = c
			sfx("sel")

# con una semilla o un esqueje, tu gente saca una madre y llena la mesa de clones: toda la mesa, con su fenotipo
func plantar_mesa(i: int) -> void:
	var own := _own()
	var esq := []   # [esqueje, 1 si es de las bandejas del carro]
	for e in S.esquejes:
		esq.append([e, 0])
	for e in S.bandejas:
		esq.append([e, 1])
	if own.is_empty() and esq.is_empty():
		await say("No llevas semillas ni esquejes.")
		return
	var items := []
	for o in own:
		var s = strain(o[0])
		items.append({"label": s.n, "right": "×" + n(o[1]), "sw": s.c, "ic": ic_cog(o[0]), "desc": strain_line(o[0])})
	for eb in esq:
		var s = strain(eb[0].sid)
		items.append({"label": "Esqueje " + s.n + etiq(eb[0].f), "right": "bandeja" if eb[1] else "esqueje", "sw": s.c, "ic": ic_cog(eb[0].sid), "desc": "Clon enraizado: la mesa entera sale con su fenotipo."})
	items.append({"label": "Cancelar", "desc": ""})
	var j: int = await menu(items, {"cls": "full", "title": "¿QUÉ PLANTAS EN LA MESA?", "desc": true})
	if j < 0 or j >= own.size() + esq.size():
		return
	var sid: String
	var f: Dictionary
	if j < own.size():
		sid = own[j][0]
		S.seeds[sid] -= 1
		if not S.seeds[sid]:
			S.seeds.erase(sid)
		f = roll_feno(sid)
	else:
		var e: Dictionary = esq[j - own.size()][0]
		var l: Array = S.bandejas if esq[j - own.size()][1] else S.esquejes
		l.remove_at(l.find(e))
		sid = e.sid
		f = e.f
	S.nave.m[i] = {"k": sid + ("*" if Cultivo.clase_feno(f) == "estrella" else ""), "f": f, "thc": thc_nave(sid, f), "y": f.y, "dia": S.day, "g": 0, "t": 0, "abo": 0}
	sfx("sel")
	await say("Mesa %d: %s%s. De la madre salen los clones para toda la mesa. A los %d días empieza a dar." % [i + 1, strain(sid).n, etiq(f), int(D.NAVE.crece)])

func estante_nave() -> void:
	var N: Dictionary = S.nave
	var ops := []
	if S.items.get("fert", 0):
		ops.append("Dejar MEATZA ×%d" % int(S.items.fert))
	if S.items.get("ofert", 0):
		ops.append("Dejar ORTUA BIO ×%d" % int(S.items.ofert))
	ops.append("Nada")
	var oi: int = await ask("La estantería de los abonos: MEATZA FLORACIÓN ×%d · ORTUA BIO FLORACIÓN ×%d. Cada mesa con abono gasta una dosis al día." % [int(N.ab.m), int(N.ab.o)], ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op.begins_with("Dejar MEATZA"):
		N.ab.m += S.items.fert
		S.items.fert = 0
		sfx("sel")
	elif op.begins_with("Dejar ORTUA"):
		N.ab.o += S.items.ofert
		S.items.ofert = 0
		sfx("sel")

# descolgar del secadero lo que quepa en la mochila, mesa por mesa (cada una, su lote, sin curar y con el día de su cosecha, Me.cd: 1.31)
func secadero_nave() -> void:
	if nave_stock() < 1:
		await say("El secadero está vacío. Cada mesa da cada mañana, a los %d días de plantarla." % int(D.NAVE.crece))
		return
	var lleva := 0
	var cabe := int(floor(libre_mochila()))
	for Me in S.nave.m:
		if not Me or Me.g < 1:
			continue
		var q: int = mini(int(floor(Me.g)), cabe - lleva)
		if q < 1:
			break
		add_buds(Me.k, q, Me.t, null, 0, Me.get("cd", S.day))
		Me.g = Datos.jsround((Me.g - q) * 10) / 10.0
		lleva += q
	if not lleva:
		await say("No te cabe nada más en la mochila.")
		return
	sfx("get")
	update_hud()
	await say("Descuelgas %s del secadero." % g_txt(lleva) + ((" Quedan %s: no te caben." % g_txt(nave_stock())) if nave_stock() >= 1 else ""))

func escritorio_nave() -> void:
	var N: Dictionary = S.nave
	var rows := []
	for i in N.m.size():
		var Me = N.m[i]
		var w = navero_de(i)
		var ab: String = D.ABONO_MESA[int(Me.abo)] if Me else ""
		rows.append({"label": "Mesa %d · %s" % [i + 1, strain(lot_sid(Me.k)).n if Me else "vacía"], "right": D.FASE_MESA[fase_mesa(i)] if Me else "",
			"desc": ("La cuida " + w.n if w else "Nadie la cuida") + "." + ((" %s · en el secadero, %s." % [ab.substr(0, 1).to_upper() + ab.substr(1), g_txt(Me.g)]) if Me else "")})
	rows.append({"label": "Estantería", "right": "%d + %d dosis" % [int(N.ab.m), int(N.ab.o)], "desc": "MEATZA FLORACIÓN y ORTUA BIO FLORACIÓN: una dosis al día por mesa con abono."})
	var i := 0
	while true:
		i = await menu(rows, {"cls": "full", "title": "LA NAVE", "title2": "%s al día" % Datos.eur(D.NAVE.dia), "desc": true, "initial": i})
		if i < 0:
			break

func talk_navero(i: int):
	var w = navero_de(i)
	if not w:
		return
	var Me = S.nave.m[i] if S.get("nave") != null else null
	var f := fase_mesa(i)
	var t: String
	if not Me:
		t = "Mi mesa está vacía. Plántame algo y la saco adelante."
	elif f < 4:
		t = "La %s va bien: %s. A los %d días empieza a dar." % [strain(lot_sid(Me.k)).n, D.FASE_MESA[f], int(D.NAVE.crece)]
	else:
		t = "Cada mañana cuelgo lo de mi mesa en el secadero." + (" Se ha acabado el abono de la estantería." if Me.abo and not S.nave.ab["m" if Me.abo == 1 else "o"] else "")
	await say(t, String(w.n).to_upper())

# ---------- GAUA ----------
# la noche empieza a las 23:00: lo de después de medianoche es de la noche del día anterior (S.noche: lo pagado y hecho esa noche)
func noche_id() -> int:
	return int(S.day) if S.min >= D.DISCO.abre else int(S.day) - 1

func disco_abierta() -> bool:
	return S.min >= D.DISCO.abre or S.min < D.DISCO.cierra

func noche_ya() -> bool:
	return S.get("noche") is Dictionary and int(S.noche.id) == noche_id()

func noche_gaua() -> Dictionary:
	if not noche_ya():
		S.noche = {"id": noche_id(), "copas": 0, "ronda": 0, "baile": 0, "mesa": 0}
	return S.noche

func entrada_disco() -> bool:
	var N := "PORTERO"
	if await ask("La entrada, %s. Se paga una vez por noche." % Datos.eur(D.DISCO.entrada), ["Pagar", "No"], N) != 0:
		return false
	if S.money < D.DISCO.entrada:
		sfx("bad")
		await say("Sin entrada no se pasa.", N)
		return false
	S.money -= int(D.DISCO.entrada)
	noche_gaua()
	sfx("coin")
	update_hud()
	return true

func echar_disco():
	await say("Las seis. Se encienden las luces y el portero echa a todo el mundo.", "PORTERO")
	await warp({"to": "ensanche", "x": 38, "y": 9, "dir": "down"})

func talk_gorila():
	await say("Abrimos a las once de la noche. Hasta las seis." if not disco_abierta() else ("Ya has pagado esta noche. Pasa." if noche_ya() else "La entrada, %s. En la puerta." % Datos.eur(D.DISCO.entrada)), "PORTERO")

# la barra, el DJ y la RRPP, solo con GAUA abierta (1.31): si te quedas quieto pasadas las seis, el portero te echa al hablar con ellos
func talk_barra():
	if not disco_abierta():
		await echar_disco()
		return
	var N := "CAMARERA"
	var X := noche_gaua()
	var c: int = await ask("¿Qué te pongo?", ["Una copa · " + Datos.eur(D.DISCO.copa), "Invitar a una ronda · " + Datos.eur(D.DISCO.ronda), "Nada"], N)
	if c == 0:
		if X.copas >= D.DISCO.copaMax:
			await say("Por hoy ya vale. Agua, si quieres.", N)
			return
		if S.money < D.DISCO.copa:
			sfx("bad")
			await say("Sin dinero no hay copa.", N)
			return
		S.money -= int(D.DISCO.copa)
		X.copas += 1
		if X.copas == 1:
			confia("gaua", 1)
		advance_time(10)
		sfx("coin")
		update_hud()
		await say(["Un gin-tonic con mucho hielo.", "Otra. La música sube.", "La tercera. Mejor que sea la última."][int(X.copas) - 1])
	elif c == 1:
		if X.ronda:
			await say("Ya has invitado esta noche. Con una, ya te conocen.", N)
			return
		if S.money < D.DISCO.ronda:
			sfx("bad")
			await say("No te llega para la ronda.", N)
			return
		S.money -= int(D.DISCO.ronda)
		X.ronda = 1
		S.rep += 1
		confia("gaua", 3)
		advance_time(10)
		sfx("coin")
		update_hud()
		await say("Invitas a la barra entera. Medio local brinda por ti.")

func talk_dj():
	if not disco_abierta():
		await echar_disco()
		return
	var c: int = await ask(pick(["¿Qué tal suena?", "Esta noche se llena."]), ["Bailar", "Pedir una canción", "Nada"], "DJ")
	if c == 0:
		await bailar()
	elif c == 1:
		sfx("sel")
		await say(pick(["Te la pongo después de esta.", "¿Esa? Hace años que no la pincho. Venga, va.", "Esa no la tengo. Te pongo algo parecido."]), "DJ")

# bailar (una vez por noche): media hora y, la mitad de las veces, alguien te pide el número (un pijo para la agenda)
func bailar() -> void:
	var X := noche_gaua()
	if X.baile:
		await say("Ya has bailado esta noche. Las piernas no dan para más.")
		return
	X.baile = 1
	await fade(1)
	advance_time(30)
	update_hud()
	await wait(200)
	await fade(0)
	confia("gaua", 2)
	var id := "gaua%d" % int(X.id)
	if S.fijos.size() < D.FIJOS_MAX and not S.fijos.any(func(f): return f.id == id) and Cultivo.azar() < D.DISCO.ligar:
		var nf := nombre_fijo(id)
		S.fijos.append({"id": id, "n": nf, "t": "pij", "dia": 0})
		sfx("get")
		await say("Bailas media hora sin parar. %s te pide el número: «Si tienes de lo bueno, llámame»." % nf)
		return
	await say("Bailas media hora sin parar. Sales de la pista con la camiseta empapada.")

# el reservado (una vez por noche): una hora y la RRPP te presenta a un cliente VIP (CTYPES.vip) para la agenda
func talk_rrpp():
	if not disco_abierta():
		await echar_disco()
		return
	var N := "RRPP"
	var X := noche_gaua()
	if X.mesa:
		await say("Disfruta del reservado. Si conoces a alguien que merezca la pena, me lo presentas.", N)
		return
	if S.fijos.size() >= D.FIJOS_MAX:   # 1.31: antes de cobrar
		await say("Tu agenda ya está llena. Cuando tengas sitio para alguien que importa, vuelve.", N)
		return
	if await ask("El reservado: sofá, mesa y botella, %s la noche. Ahí se sienta la gente que importa." % Datos.eur(D.DISCO.mesa), ["Reservar", "No"], N) != 0:
		return
	if S.money < D.DISCO.mesa:
		sfx("bad")
		await say("Para el reservado hace falta dinero. Otra noche.", N)
		return
	S.money -= int(D.DISCO.mesa)
	X.mesa = 1
	confia("gaua", 5)
	sfx("coin")
	await fade(1)
	advance_time(60)
	update_hud()
	await wait(200)
	await fade(0)
	var nv: String = D.DISCO.vip[int(S.vipN) % D.DISCO.vip.size()]
	var id := "vip%d" % int(S.vipN)
	S.vipN += 1
	S.fijos.append({"id": id, "n": nv, "t": "vip", "dia": 0})
	sfx("get")
	await say("Una hora en el reservado. La RRPP te presenta a %s: «Me han dicho que lo tuyo es de lo mejor. Llámame». Apuntas su número." % nv)

func talk_baila(i: int):
	await say(D.BAILA[i], "GENTE")

# ---------- LA ASOCIACIÓN (1.32, 11j-locales): la de la tía Maite, en el barrio alto (CLUBS.rv) ----------
# la segunda vez que entras (otro día), Delroy; presentarte (la asamblea) o refundarla; de presidente, el dispensario (ASO, DELROY)
func aso() -> Dictionary:
	if not (S.get("aso") is Dictionary):
		S.aso = {"v": 0, "d": 0, "tio": false, "asam": 0, "otra": 0, "pres": false, "votos": 0, "lote": null}
	return S.aso

func delroy_aqui() -> bool:
	return int(aso().v) >= int(D.ASO.visitas)

func votos_aso() -> int:
	var O: Dictionary = D.ASO
	var n := 0
	for id in O.gente:
		if rel(id) >= int(D.REL.amigo):
			n += 1
	return mini(int(O.votos), int(O.base) + (int(O.delroy) if aso().tio else 0) + int(O.amigo) * n + int(floor(rel("rv") / float(O.relV))))

# la puerta (entra_local): cada día que entras cuenta una visita; la segunda, Delroy está dentro
func entra_aso(d: Dictionary) -> void:
	var A := aso()
	if int(A.d) != int(S.day):
		A.v = int(A.v) + 1
		A.d = S.day
	await warp(d)
	if delroy_aqui() and not A.tio:
		await say("Junto a la foto de la tía Maite, un hombre mayor con las rastas y la barba canas no te quita ojo.")

func talk_delroy() -> void:
	var A := aso()
	var N: String = D.DELROY.n
	if not A.tio:
		await talk(N, D.DELROY.revela)
		A.tio = true
		confia("delroy", 5)
	var c: int = await ask("¿Qué tal, presidente?" if A.pres else "Dime, sobrino.", ["Charlar", "El dispensario" if A.pres else "La presidencia", "Nada"], N)
	if c == 0:
		await say(pick(D.DELROY.charla), N)
	elif c == 1:
		if A.pres:
			await dispensario_aso()
		else:
			await presidencia_aso()

func presidencia_aso() -> void:
	var A := aso()
	var N: String = D.DELROY.n
	var O: Dictionary = D.ASO
	if A.asam:   # con la asamblea pendiente, todavía se puede refundar
		if await ask("La asamblea es el día %d, por la mañana. Habla con la gente del barrio: cada amigo trae votos. O la refundas ya, por %s." % [int(A.asam), Datos.eur(O.refunda)], ["Refundarla", "Nada"], N) != 0:
			return
	else:
		var c: int = await ask("Hacen falta %d votos de %d. Hoy tendrías %d. O pagas %s de deudas y registro y la refundas tú." % [int(O.mayoria), int(O.votos), votos_aso(), Datos.eur(O.refunda)], ["Presentarme", "Refundarla", "Nada"], N)
		if c == 0:
			if S.day < int(A.otra):
				await say("Hasta el día %d no hay otra asamblea. Gánate al barrio mientras." % int(A.otra), N)
				return
			A.asam = int(S.day) + int(O.dias)
			sfx("sel")
			await say("Apuntado. La asamblea, el día %d. %s también se presenta." % [int(A.asam), O.rival], N)
			return
		if c != 1:
			return
	if S.money < int(O.refunda):
		sfx("bad")
		await say("Sin los %s no hay refundación." % Datos.eur(O.refunda), N)
		return
	S.money -= int(O.refunda)
	A.pres = true
	A.asam = 0
	confia("delroy", 10)
	confia("rv", 10)
	update_hud()
	sfx("get")
	await say("Pagas las deudas de la gestora y el registro. La asociación vuelve a nacer, con tus estatutos. Maite estaría orgullosa.", N)

# el dispensario: un lote a la vez; dice cuánto queda y lo que llevas
func dispensario_aso() -> void:
	var A := aso()
	var N: String = D.DELROY.n
	var O: Dictionary = D.ASO
	var L = A.lote
	if L is Dictionary:
		await say("En el dispensario quedan %s de %s, a %s € el gramo. Llevas %s." % [g_txt(L.g), lot_nombre(L.k), _dos(L.pg), Datos.eur(L.tot)], N)
		return
	var lots := bud_lots(O.g[0])
	if lots.is_empty():
		await say("Déjame %d g o más y los socios lo retiran, %d g al día. El dinero, a tu buzón." % [int(O.g[0]), int(O.dia)], N)
		return
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		return
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var pg := Datos.jsround(precio_club(b.thc) * calidad(b) * float(O.f) * 100) / 100.0
	var ops := []
	for g in O.g:
		if g <= floor(b.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(g * pg)])
	o.append("Nada")
	var j: int = await ask("%s a %s € el gramo para los socios. ¿Cuánto dejas?" % [lot_nombre(k), _dos(pg)], o, N)
	if j < 0 or j >= ops.size():
		return
	use_buds(k, ops[j])
	A.lote = {"k": k, "g": ops[j], "pg": pg, "tot": 0}
	sfx("sel")
	await say("Al dispensario. Cada mañana, %d g para los socios." % int(O.dia), N)

# al amanecer (curro_dia): la asamblea, si toca, y lo que retiran los socios del dispensario
func aso_dia() -> void:
	var A := aso()
	var O: Dictionary = D.ASO
	if A.asam and S.day >= int(A.asam):
		var v := votos_aso()
		var gana := v >= int(O.mayoria)
		A.asam = 0
		A.votos = v
		if gana:
			A.pres = true
			confia("delroy", 10)
		else:
			A.otra = int(S.day) + int(O.espera)
		var t: String = ("¡%d votos de %d! Eres el presidente de la asociación, sobrino. Como tu tía." % [v, int(O.votos)]) if gana else ("%d votos de %d: gana %s. Gánate al barrio y preséntate otra vez desde el día %d." % [v, int(O.votos), O.rival, int(A.otra)])
		queue("aso", func(): await talk("SMS · DELROY", [t]))
	var L = A.lote
	if not A.pres or not (L is Dictionary):
		return
	var g = min(L.g, O.dia)
	var e := Datos.jsround(g * L.pg)
	L.g -= g
	L.tot += e
	S.money += e
	S.sales += e
	queue("historia", check_story)
	if L.g < 1:
		A.lote = null
		queue("asoLote", func(): await talk("SMS · DELROY", ["Se acabó lo del dispensario: %s en total, en tu buzón." % Datos.eur(L.tot)]))

# ---------- el bajo de las setas (1.20, 11g-setas): el local clandestino de la Kale Zaharra ----------
func fase_seta(b: Dictionary) -> String:
	if b.get("mala"):
		return b.mala
	var d: int = int(S.day - b.d)
	return "colonizando" if d < D.SETAS.colon else ("fructificando" if d < D.SETAS.colon + D.SETAS.fruto else "lista")

func setas_dia() -> void:
	var L = S.get("setas")
	if L == null:
		return
	var Z: Dictionary = D.SETAS
	if S.money < Z.dia:
		S.setas = null
		queue("setas", func(): await talk("SMS · TXOMIN", ["No me has pagado el bajo. Cambio la cerradura; lo de dentro y la fianza, para mí."]))
		return
	S.money -= int(Z.dia)
	var vivas: Array = L.bandejas.filter(func(b): return not b.get("mala"))
	if vivas.is_empty():
		return
	if Cultivo.azar() < Z.redada:
		var gg: float = L.g
		S.setas = null
		S.heat = min(100, S.heat + Z.calorRedada)
		sfx("bad")
		queue("setas", func(): await say("La policía ha entrado en el bajo de la Kale Zaharra. Se lleva las bandejas%s." % ((" y " + g_txt(gg) + " de setas") if gg >= 1 else "")))
		return
	var malas := []
	for b in vivas:
		b.hum = maxf(0, b.hum - Z.seca)
		if not b.hum:
			b.mala = "seca"
			malas.append("seca")
			continue
		if fase_seta(b) != "lista" and Cultivo.azar() < Z.cont + (Z.contSeca if b.hum < 50 else 0.0):
			b.mala = "contaminada"
			malas.append("contaminada")
	if malas.size():
		var t: String = ("Se te han echado a perder %d bandejas. Tíralas." % malas.size()) if malas.size() > 1 else ("Una bandeja se te ha %s. Tírala." % ("secado" if malas[0] == "seca" else "contaminado"))
		queue("setas", func(): await talk("SMS · TXOMIN", [t]))

func talk_txomin() -> void:
	var T := "TXOMIN"
	var Z: Dictionary = D.SETAS
	if S.ch < int(Z.ch):
		await say("¿Setas? Eso era antes, chaval. Ahora solo paseo.", T)
		return
	if S.get("setas") == null:
		if await ask("El bajo de mi casa: oscuro, húmedo y nadie pregunta. %s de fianza y %s al día, que te cobro cada mañana. Las bandejas te las preparo yo." % [Datos.eur(Z.fianza), Datos.eur(Z.dia)], ["Alquilarlo", "No"], T) != 0:
			return
		if S.money < Z.fianza:
			sfx("bad")
			await say("Sin la fianza no hay llave.", T)
			return
		S.money -= int(Z.fianza)
		S.setas = {"bandejas": [], "g": 0}
		sfx("coin")
		await got("la llave del bajo")
		await say("Compra las bandejas y tenlas húmedas. Lo demás lo hace el tiempo.", T)
		return
	var L: Dictionary = S.setas
	while true:
		var B: Array = L.bandejas
		var cnt := {}
		for k in D.FASES_SETA:
			cnt[k] = 0
		for b in B:
			cnt[fase_seta(b)] += 1
		var hum: Array = B.filter(func(b): return not b.get("mala"))
		var partes := []
		for k in D.FASES_SETA:
			if cnt[k]:
				partes.append("%d %s" % [cnt[k], D.FASES_SETA[k][1 if cnt[k] > 1 else 0]])
		var est: String = ", ".join(PackedStringArray(partes)) if B.size() else "sin bandejas"
		var ops := []
		if B.size() < Z.max:
			ops.append("Comprar bandeja (%s)" % Datos.eur(Z.bandeja))
		if hum.size():
			ops.append("Pulverizar")
		if cnt.lista:
			ops.append("Recoger")
		if B.any(func(b): return b.get("mala")):
			ops.append("Tirar las malas")
		if L.g >= 1:
			ops.append("Venderle " + g_txt(L.g))
		ops.append_array(["Dejar el bajo", "Nada"])
		var hm := 0.0
		for b in hum:
			hm += b.hum
		var oi: int = await ask("El bajo: %s%s." % [est, (" · humedad %d %%" % Datos.jsround(hm / hum.size())) if hum.size() else ""], ops, T)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Nada":
			return
		if op.begins_with("Comprar"):
			if S.money < Z.bandeja:
				sfx("bad")
				await say("Sin dinero no hay bandeja.", T)
				continue
			S.money -= int(Z.bandeja)
			B.append({"d": S.day, "hum": 100})
			sfx("coin")
			await say("Lista para colonizar. En %d días la habrá cogido el micelio; %d más y a recoger." % [int(Z.colon), int(Z.fruto)], T)
		elif op == "Pulverizar":
			for b in hum:
				b.hum = 100
			advance_time(int(Z.min))
			update_hud()
			if S.get("setas") == null:   # si pasa de medianoche, setas_dia puede cerrar el bajo
				return
			sfx("sel")
			var v: Array = L.bandejas.filter(func(b): return not b.get("mala"))   # pasada la medianoche, setas_dia ya las ha secado (o echado a perder)
			var hv := 0.0
			for b in v:
				hv += b.hum
			await say(("Pulverizas las bandejas: humedad al %d %%." % Datos.jsround(hv / v.size())) if v.size() else "Pulverizas las bandejas.")
		elif op == "Recoger":
			var g := 0
			var quedan := []
			for b in B:
				if fase_seta(b) != "lista":
					quedan.append(b)
				else:
					g += ri(int(Z.g[0]), int(Z.g[1]))
			L.bandejas = quedan
			L.g += g
			sfx("get")
			await say("Recoges las setas y las dejas secando en el bajo: %d g." % g)
		elif op == "Tirar las malas":
			var k: int = B.filter(func(b): return b.get("mala")).size()
			L.bandejas = B.filter(func(b): return not b.get("mala"))
			await say(("Tiras %d bandejas." % k) if k > 1 else "Tiras la bandeja.")
		elif op.begins_with("Venderle"):
			var g: int = int(floor(L.g))
			var e: int = g * int(Z.precio)
			L.g -= g
			S.money += e
			S.sales += e
			S.heat = min(100, S.heat + Z.calor)
			sfx("coin")
			toast("+%s · %d g de setas" % [Datos.eur(e), g], 1600)
			await say("Para mis clientes de siempre. %s." % Datos.eur(e), T)
			await check_story()
		elif op == "Dejar el bajo":
			if await ask("¿Dejas el bajo? Te devuelvo la fianza; lo que haya dentro se queda.", ["Dejarlo", "No"], T) != 0:
				continue
			S.setas = null
			S.money += int(Z.fianza)
			sfx("coin")
			await say("Como quieras. La puerta, cerrada al salir.", T)
			return
