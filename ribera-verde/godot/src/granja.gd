# Ribera Verde (Godot) — 09-cultivo y la lógica de 09b-carpa: el tiempo (minuto a minuto y de golpe), el día nuevo con su
# factura y su olor, plantar, cuidar, sacar esquejes, cosechar, la cama, el PC (Genoteca y banco de semillas), la carta, la
# mesa de genética y la vista de carpa (VC: elegir plaza o foco y cuidar). Los números salen de Cultivo (src/cultivo.gd).
extends "res://src/mundo.gd"

const Vista = preload("res://src/vista.gd")

var VC = null    # carpa abierta: {ci, sel: plaza (índice de huecos) o −1 = el foco, ocupado}
var vc_texto := ""   # lo que se lee en la ficha (textContent de #vcInfo); "" si está oculta

# ---------- equipo ----------
func huecos() -> Array:
	return Cultivo.huecos(S)

func factores(i: int) -> Dictionary:
	return Cultivo.factores(S, i)

func gramos_planta(p: Dictionary, f: Dictionary) -> int:
	return Cultivo.gramos_planta(S, p, f)

func plantas_vivas(ci: int) -> bool:
	return Cultivo.plantas_vivas(S, ci)

func en_flor(ci: int) -> bool:
	var H := huecos()
	for i in H.size():
		var p = S.pots[i]
		if H[i].c == ci and p and not p.get("dead") and p.prog >= .65:
			return true
	return false

func olor_dia() -> int:
	var a := 0
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if c and not c.get("filtro") and en_flor(ci):
			a += int(D.OLOR)
	return a

func luz_carpa(ci: int) -> int:
	return Cultivo.luz_carpa(S, ci)

func factura_luz() -> int:
	var e := 0
	for ci in S.carpas.size():
		if S.carpas[ci] and plantas_vivas(ci):
			e += luz_carpa(ci)
	return e

func kwh_foco(k: String) -> int:
	return Datos.jsround(D.FOCOS[k].w * D.H_LUZ / 1000)

static func signo(v: float) -> String:
	return ("+" if v >= 0 else "−") + str(absi(Datos.jsround(v)))

static func pc(t: String, f: float) -> String:
	return "" if absf(f - 1) < .001 else " · %s %s%%" % [t, signo((f - 1) * 100)]

func desc_foco(k: String) -> String:
	var F: Dictionary = D.FOCOS[k]
	return "%s W · ilumina %s×%s cm · %s g/W (%s abonando)%s%s · riego ×%s\nLuz: %d kWh (%s) al día con plantas." % [n(F.w), n(F.lado), n(F.lado), Datos.coma(F.gpw),
		Datos.coma(Datos.jsround(F.gpw * 1.25 * 100) / 100.0), pc("crece", F.crec), (" · THC +" + Datos.pct(F.thc)) if F.thc else "", Datos.coma(F.agua), kwh_foco(k), Datos.eur(kwh_foco(k) * D.KWH)]

func desc_maceta(k: String) -> String:
	var Mc: Dictionary = D.MACETAS[k]
	return "%s L · hasta %s g por planta%s%s · riego ×%s%s" % [n(Mc.l), n(Mc.cap), pc("cosecha", Mc.rend), pc("crece", Mc.crec), Datos.coma(Mc.agua), " · menos plagas" if Mc.plaga < 1 else ""]

# ---------- tiempo ----------
func plants_advance(mn: int) -> void:
	Cultivo.plants_advance(S, mn)

func advance_time(mn: int) -> void:
	while mn > 0:
		var st := mini(60, mn)
		mn -= st
		S.min += st
		plants_advance(st)
		if S.min >= 1440:
			S.min -= 1440
			new_day()

func tick_minute() -> void:
	S.min += 1
	if S.min % 10 == 0:
		plants_advance(10)
	if S.min % 30 == 0 and S.hp < S.hpMax:
		S.hp += 1
	if S.min >= 1440:
		S.min -= 1440
		new_day()
	if S.min % 30 == 0 and D.ZONAS.has(S.map):
		music(map_music())

func new_day() -> void:
	S.day += 1
	# la cuota de Molina (1.10): pasado el último día pagado, se acaba la protección (antes de la redada de esta noche)
	if S.protect and S.get("protHasta") and S.day > S.protHasta:
		S.protect = false
		queue("cuota", func(): await talk("SMS · MOLINA", ["Se acabó lo pagado.", "Si quieres que mis agentes sigan mirando hacia otro lado, ya sabes dónde está la comisaría."]))
	if S.heat >= 90:
		queue("raid", raid_event)   # antes de que el calor baje con el nuevo día
	S.heat = max(0, S.heat - (20 if S.protect else 12))
	var luz := factura_luz()
	var olor := olor_dia()
	var av := []
	S.luz = {"d": S.day, "e": luz, "o": olor}
	if luz > 0:
		pagar_casa(luz)    # de lo de fuera y, si no llega, de la caja (1.10)
		av.append("Factura de la luz: −" + Datos.eur(luz))
	if olor:
		S.heat = min(100, S.heat + olor)
		av.append("Olor a cogollo: calor +%d" % olor)
	var sec := 0
	for e in S.esquejes:
		if S.day - e.dia > D.ESQUEJE_DIAS:
			sec += 1
	if sec:
		S.esquejes = S.esquejes.filter(func(e): return S.day - e.dia <= D.ESQUEJE_DIAS)
		av.append("Se %s sin plantar" % [("han secado %d esquejes" % sec) if sec > 1 else "ha secado un esqueje"])
	if av.size() and mode == "world":
		toast("<br>".join(av), 1600)
	spawn_clients()
	recibir_pedido()
	instalar_caja()
	vencer_encargo()
	if S.due > 0 and S.day > S.deadline:   # 1.10: también sin haber visto a Baltasar (el plazo corre desde Toño)
		queue("penalty", penalty_event)

# ---------- fenotipo ----------
func tira_feno(sg: float) -> Dictionary:
	var m := func() -> float: return Datos.jsround(clampf(1 + sg * Cultivo.gauss(), .6, 1.5) * 100) / 100.0
	var t: float = m.call()
	return {"t": t, "y": m.call()}

func roll_feno(sid: String) -> Dictionary:
	return Cultivo.roll_feno(S, sid)

func feno_visto(f):
	if f is Dictionary and f.get("id"):
		return S.fenos.get(str(int(f.id)))
	return null

func marca_feno(f) -> String:
	var v = feno_visto(f)
	return " ★" if v == "estrella" else (" (floja)" if v == "floja" else "")

# ---------- plantar y cuidar ----------
func _own() -> Array:
	var o := []
	for k in S.seeds:
		if S.seeds[k] > 0:
			o.append([k, S.seeds[k]])
	return o

func plantar(i: int) -> void:
	var own := _own()
	var esq: Array = S.esquejes
	if own.is_empty() and esq.is_empty():
		await say("Maceta vacía. No tienes semillas: cómpralas en el growshop de Kiko.")
		return
	var items := []
	for o in own:
		var s = strain(o[0])
		items.append({"label": s.n, "right": "×" + n(o[1]), "sw": s.c, "ic": ic_cog(o[0]), "desc": strain_line(o[0])})
	for e in esq:
		var s = strain(e.sid)
		var v = feno_visto(e.f)
		var dv := ("Fenotipo estrella: THC ×%s y cosecha ×%s." % [Datos.coma(e.f.t), Datos.coma(e.f.y)]) if v == "estrella" else ("Fenotipo flojo: rinde menos que la media." if v == "floja" else "Su fenotipo se sabrá cuando coseches a la madre o a un clon suyo.")
		items.append({"label": "Esqueje " + s.n + marca_feno(e.f), "right": "esqueje", "sw": s.c, "ic": ic_cog(e.sid),
			"desc": "Clon enraizado: la misma planta que su madre, con su fenotipo.\n%s\nSe seca si no lo plantas antes del día %s." % [dv, n(e.dia + D.ESQUEJE_DIAS + 1)]})
	items.append({"label": "Cancelar", "desc": ""})
	var j: int = await menu(items, {"cls": "full", "title": "¿QUÉ PLANTAS?", "desc": true})
	if j < 0 or j >= own.size() + esq.size():
		return
	if j >= own.size():
		var e: Dictionary = esq[j - own.size()]
		esq.remove_at(j - own.size())
		S.pots[i] = {"sid": e.sid, "prog": .12, "water": 70, "health": 100, "fert": false, "pest": false, "f": e.f}   # ya enraizado: empieza de plántula
		sfx("sel")
		await accion("plantar")
		await say("Plantas el esqueje de %s%s." % [strain(e.sid).n, marca_feno(e.f)])
		await pista_barras()
		return
	var sid: String = own[j][0]
	S.seeds[sid] -= 1
	if not S.seeds[sid]:
		S.seeds.erase(sid)
	S.pots[i] = {"sid": sid, "prog": 0, "water": 70, "health": 100, "fert": false, "pest": false, "f": roll_feno(sid)}
	sfx("sel")
	await accion("plantar")
	await say("Has plantado %s." % strain(sid).n)
	await pista_barras()

# con la primera planta, qué dice su barra
func pista_barras() -> void:
	if S.flags.get("barras"):
		return
	S.flags.barras = true
	await say("Cada planta lleva su barra: arriba, el agua (roja: toca regar); abajo, la cosecha (dorada: lista).")
	await say("Si le sale plaga, verás una «!» roja y manchas en las hojas. Trátala con INSECTICIDA.")

func sacar_esqueje(i: int) -> void:
	var p: Dictionary = S.pots[i]
	var s = strain(p.sid)
	if S.esquejes.size() >= 12:
		await say("El propagador está lleno: 12 esquejes. Planta alguno antes.")
		return
	S.esquejes.append({"sid": p.sid, "f": p.f if p.get("f") else roll_feno(p.sid), "dia": S.day})
	if not p.get("f"):
		p.f = S.esquejes[-1].f
	p.health = max(1, p.health - 5)
	sfx("sel")
	await say("Cortas una punta de la %s y la pones a enraizar.\nPlántala antes del día %s: es la misma planta." % [s.n, n(S.day + D.ESQUEJE_DIAS + 1)])

func stage_name(p: Dictionary) -> String:
	return Cultivo.stage_name(p)

func pot_action(i: int) -> void:
	var p = S.pots[i]
	if p == null:
		if macetas_libres(i).size():
			var c: int = await ask("Plaza vacía con una maceta de %s." % D.MACETAS[S.macetas[i]].n, ["Plantar", "Cambiar maceta", "Salir"])
			if c == 1:
				await cambiar_maceta(i)
				return
			if c != 0:
				return
		await plantar(i)
		return
	var s = strain(p.sid)
	if p.get("dead"):
		await say("La %s se ha secado del todo." % s.n)
		S.pots[i] = null
		await say("Retiras la planta muerta.")
		return
	if p.prog >= 1:
		var c: int = await ask("%s%s lista para cosechar.\nSalud %d%% · Agua %d%%" % [s.n, marca_feno(p.get("f")), Datos.jsround(p.health), Datos.jsround(p.water)], ["Cosechar", "Esperar"])
		if c == 0:
			await harvest(i)
		return
	var opts := ["Regar"]
	if not p.fert:
		opts.append("Abonar")
	if p.pest:
		opts.append("Tratar plaga")
	if p.prog >= .2 and p.prog < .65:
		opts.append("Sacar esqueje")
	opts.append_array(["Arrancar", "Salir"])
	var c: int = await ask("%s%s · %s %d%%\nAgua %d%% · Salud %d%%%s" % [s.n, marca_feno(p.get("f")), stage_name(p), int(floor(p.prog * 100)), Datos.jsround(p.water),
		Datos.jsround(p.health), " · PLAGA" if p.pest else ""], opts)
	var op: String = opts[c]
	if op == "Regar":
		var v := pos_plaza(i)
		await accion("regar", {"id": "vfx-gotas", "x": v[0], "y": v[1] - 6})
		p.water = 100
		sfx("sel")
		await say("Riegas la planta. Agua al 100%.")
	elif op == "Abonar":
		if S.items.fert > 0:
			S.items.fert -= 1
			p.fert = true
			sfx("sel")
			await say("Echas una dosis de ABONO. Dará más cosecha.")
		else:
			await say("No te queda ABONO.")
	elif op == "Tratar plaga":
		if S.items.insect > 0:
			S.items.insect -= 1
			p.pest = false
			sfx("sel")
			await say("Aplicas INSECTICIDA con guantes y mascarilla. Plaga eliminada.")
		else:
			await say("No tienes INSECTICIDA. Kiko lo vende.")
	elif op == "Sacar esqueje":
		await sacar_esqueje(i)
	elif op == "Arrancar":
		if await ask("¿Seguro que quieres arrancarla?", ["Sí", "No"]) == 0:
			S.pots[i] = null
			await say("Arrancas la planta.")

# macetas de repuesto que caben en la carpa de la plaza i (y no son la que ya tiene)
func macetas_libres(i: int) -> Array:
	var h: Dictionary = huecos()[i]
	var C: Dictionary = D.CARPAS[S.carpas[h.c].t]
	var o := []
	for k in D.MACETAS:
		if S.items.get("m_" + k, 0) > 0 and D.MACETAS[k].l <= C.lmax and k != S.macetas[i]:
			o.append(k)
	return o

func cambiar_maceta(i: int) -> void:
	var l := macetas_libres(i)
	if l.is_empty():
		await say("No tienes otra maceta que quepa aquí.")
		return
	var it := []
	for k in l:
		it.append({"label": "Maceta " + D.MACETAS[k].n, "right": "×" + n(S.items["m_" + k]), "ic": icono("maceta"), "desc": desc_maceta(k)})
	var j: int = await menu(it, {"cls": "full", "title": "CAMBIAR MACETA", "title2": "Ahora: " + D.MACETAS[S.macetas[i]].n, "desc": true})
	if j < 0:
		return
	var k: String = l[j]
	S.items["m_" + k] -= 1
	S.items["m_" + S.macetas[i]] = S.items.get("m_" + S.macetas[i], 0) + 1
	S.macetas[i] = k
	sfx("sel")
	await say("Pones la maceta de %s. La vieja va a la mochila." % D.MACETAS[k].n)

func focos_libres(ci: int) -> Array:
	var o := []
	for k in D.FOCOS:
		if S.items.get("f_" + k, 0) > 0 and D.FOCOS[k].w <= D.CARPAS[S.carpas[ci].t].wmax and k != S.carpas[ci].foco:
			o.append(k)
	return o

func instalar_foco(ci: int, k: String) -> void:
	var c: Dictionary = S.carpas[ci]
	S.items["f_" + k] -= 1
	S.items["f_" + c.foco] = S.items.get("f_" + c.foco, 0) + 1
	c.foco = k
	sfx("sel")

func cambiar_foco(ci: int) -> void:
	var l := focos_libres(ci)
	if l.is_empty():
		await say("No tienes otro foco que aguante esta carpa.")
		return
	var it := []
	for k in l:
		it.append({"label": "Foco " + D.FOCOS[k].n, "right": "×" + n(S.items["f_" + k]), "ic": icono("lampara"), "desc": desc_foco(k)})
	var j: int = await menu(it, {"cls": "full", "title": "CAMBIAR FOCO", "title2": "Ahora: " + D.FOCOS[S.carpas[ci].foco].n, "desc": true})
	if j < 0:
		return
	instalar_foco(ci, l[j])
	await say("Cuelgas el foco %s. El viejo va a la mochila." % D.FOCOS[l[j]].n)

func extras_libres(ci: int) -> Array:
	var o := []
	for k in D.EXTRAS:
		if not S.carpas[ci].get(k) and S.items.get("x_" + k, 0) > 0:
			o.append(k)
	return o

func poner_extra(ci: int, k: String) -> void:
	S.items["x_" + k] -= 1
	S.carpas[ci][k] = true
	sfx("sel")

func carpa_action(ci: int) -> void:
	var c: Dictionary = S.carpas[ci]
	var C: Dictionary = D.CARPAS[c.t]
	var F: Dictionary = D.FOCOS[c.foco]
	var f := focos_libres(ci).size()
	var ex := extras_libres(ci)
	var opts := ["Cambiar foco"] if f else []
	for k in ex:
		opts.append("Poner " + D.EXTRAS[k].c.to_lower())
	opts.append("Salir")
	var k: int = await ask("%s · %s plantas · %s\n%d W/m² · luz %s al día con plantas" % [C.n, n(C.plazas), F.n, Datos.jsround(F.w / (C.cm[0] * C.cm[2] / 1e4)), Datos.eur(luz_carpa(ci))], opts)
	if opts[k] == "Cambiar foco":
		await cambiar_foco(ci)
		return
	var ix := k - (1 if f else 0)
	if k < 0 or ix < 0 or ix >= ex.size():
		return
	var x: String = ex[ix]
	poner_extra(ci, x)
	await say("Pones el %s en %s %s.\n%s" % [D.EXTRAS[x].n.to_lower(), "el" if C.n.begins_with("Armario") else "la", C.n.to_lower(), D.EXTRAS[x].d])

# ---------- cosecha ----------
func harvest(i: int) -> void:
	var p: Dictionary = S.pots[i]
	var s = strain(p.sid)
	var f := factores(i)
	var fe: Dictionary = p.f if p.get("f") else {"t": 1, "y": 1}
	var cl := Cultivo.clase_feno(p.get("f"))
	var g := gramos_planta(p, f)
	var thc := Cultivo.thc_cosecha(S, p, f)
	var v := pos_plaza(i)
	await accion("cosechar")
	await accion("oler", {"id": "vfx-brillo", "x": v[0], "y": v[1] - 12})
	var cria: bool = Cultivo.gen_de(S, p.sid) < D.GEN_ESTABLE
	var fem := false
	for it in D.SHOP:
		if it.get("sid") == p.sid:
			fem = true
	var nn := 0
	if cria:
		nn = ri(2, 5)
	elif not fem or Cultivo.azar() < D.SEMILLA_HERMA:
		nn = ri(1, 3)
	add_buds(p.sid + "*" if cl == "estrella" else p.sid, g, thc)
	if nn:
		add_seeds(p.sid, nn)
	if p.get("f") and p.f.get("id"):
		S.fenos[str(int(p.f.id))] = cl
	S.pots[i] = null
	sfx("get")
	if S.rec.get(p.sid) == 1:   # una variedad de receta sacada en la mesa, cosechada (capítulo 4)
		S.rec[p.sid] = 2
	await say("Cosechas %d g de %s. THC: %s%%." % [g, s.n, Datos.pct(thc)])
	if cl == "estrella":
		sfx("enc")
		await say("¡Fenotipo estrella! THC ×%s y cosecha ×%s sobre la media de la %s." % [Datos.coma(fe.t), Datos.coma(fe.y), s.n])
		await say("Va a un lote aparte (★). Si le sacaste esquejes, guárdalos: son esta misma planta.")
	elif cl == "floja":
		await say("Fenotipo flojo: THC ×%s y cosecha ×%s de la media." % [Datos.coma(fe.t), Datos.coma(fe.y)])
	if nn:
		var pl := "s" if nn > 1 else ""
		if cria:
			await say("Las plantas de la línea se han polinizado entre ellas: recoges %d semillas de %s." % [nn, s.n])
		elif not fem:
			await say("Son semillas regulares: algún macho ha polinizado unas flores. Recoges %d semilla%s de %s." % [nn, pl, s.n])
		else:
			await say("Una flor hermafrodita ha polinizado unas pocas: recoges %d semilla%s de %s." % [nn, pl, s.n])
	S.flags.harvest1 = true
	await check_story()

# estabilizar: la línea cruzada consigo misma sube una generación (F1 → F2 → F3 → estable)
func estabilizar(k: String) -> void:
	var s = strain(k)
	var g := Cultivo.gen_de(S, k)
	if await ask("¿Estabilizar %s (F%d)? Gastas 2 semillas y guardas 1." % [s.n, g], ["Estabilizar", "Cancelar"]) != 0:
		return
	S.seeds[k] -= 2
	if not S.seeds[k]:
		S.seeds.erase(k)
	await accion("cruzar", {"id": "vfx-polen", "x": P.px + 8, "y": P.py - 4})
	sfx("enc")
	await fade(1, true)
	await wait(450)
	await fade(0, true)
	var GE := int(D.GEN_ESTABLE)
	if g + 1 >= GE:
		S.gen.erase(k)
		sfx("get")
		add_seeds(k, 1)
		await say("%s ya es una línea estable: todas sus plantas salen iguales.\nGuardas 1 semilla." % s.n)
	else:
		S.gen[k] = g + 1
		add_seeds(k, 1)
		await say("Guardas 1 semilla F%d de %s: cultívala para tener más.\n%s para fijarla." % [g + 1, s.n, "Falta una generación" if GE - g - 1 == 1 else "Faltan %d generaciones" % (GE - g - 1)])

# ---------- cama ----------
# la cama del piso y, desde la 1.10, la de casa de ama (txt): allí no hay robo de Darko ni aviso de plagas (las plantas están en el piso)
func bed_action(txt := ""):
	var piso: bool = S.map == "home"
	var c: int = await ask(txt if txt else "Tu cama. Todavía huele a la colonia de la tía.", ["Dormir hasta las 7", "Siesta de 3 h", "Nada"])
	if c > 1:
		return
	await fade(1)
	var mins := 180 if c == 1 else Cultivo.minutos_cama(S, 0)
	var antes := []
	for p in S.pots:
		antes.append([true if p.pest else false, true if p.get("dead") else false] if p else null)
	advance_time(mins)
	S.hp = S.hpMax
	build_ents()
	update_hud()
	await wait(500)
	await fade(0)
	var hoy = S.luz if S.get("luz") and S.luz.d == S.day else null
	save()
	toast("Has descansado" + ((" · Luz −" + Datos.eur(hoy.e)) if hoy and hoy.e else "") + ((" · Olor: calor +" + n(hoy.o)) if hoy and hoy.o else "") + " · Partida guardada", 1800)
	if not piso:
		return
	if S.ch == 7 and not S.flags.get("robo") and (S.money > 1000 or gramos_flor() > 100):
		await robo_darko()   # la amenaza de Darko (1.10)
	await aviso_plaga(antes)

static func _lista(L: Array) -> String:
	return L[0] if L.size() == 1 else ", ".join(L.slice(0, -1)) + " y " + L[-1]

# al despertar: las que han cogido plaga mientras dormías (y el insecticida que te queda), las que la siguen teniendo sin
# tratar y las que se han secado del todo (antes: [plaga, muerta] de cada plaza al acostarte)
func aviso_plaga(antes: Array) -> void:
	var nuevas := []
	var siguen := []
	var muertas := []
	var H := huecos()
	var nc := 0
	for c in S.carpas:
		if c:
			nc += 1
	var varias := nc > 1
	for i in S.pots.size():
		var p = S.pots[i]
		if not p:
			continue
		var a = antes[i] if i < antes.size() and antes[i] else [false, false]
		var nom := "la %s (%splaza %d)" % [strain(p.sid).n, (D.CARPAS[S.carpas[H[i].c].t].n + ", ") if varias else "", H[i].j + 1]
		if p.get("dead"):
			if not a[1]:
				muertas.append(nom)
		elif p.pest:
			(siguen if a[0] else nuevas).append(nom)
	if nuevas.size():
		var k: int = S.items.insect
		sfx("bad")
		await say("¡Plaga en %s! Trátala%s con INSECTICIDA: %s" % [_lista(nuevas), "s" if nuevas.size() > 1 else "", ("te queda%s %d." % ["n" if k > 1 else "", k]) if k else "no te queda; cómpralo en el growshop."])
	if siguen.size():
		await say("Sigue la plaga en %s: sin tratar, pierde%s salud cada hora." % [_lista(siguen), "n" if siguen.size() > 1 else ""])
	if muertas.size():
		await say("Se ha%s secado del todo %s. Retírala%s con A." % ["n" if muertas.size() > 1 else "", _lista(muertas), "s" if muertas.size() > 1 else ""])

# ---------- PC ----------
func pc_action():
	var o := ["Genoteca"]
	if S.ch >= 2:
		o.append("Banco de semillas")
	o.append("Notas de la tía")
	if S.ch >= 4 and S.get("caja") and S.caja.nivel == 1 and not S.caja.get("mejora"):
		o.append("Caja empotrada")
	o.append_array(["Guardar partida", "Apagar"])
	var c: String = o[await ask("El ordenador de la tía. Tiene su registro de cultivos de veinte años.", o)]
	if c == "Genoteca":
		await genoteca()
	elif c == "Banco de semillas":
		await banco_semillas()
	elif c == "Notas de la tía":
		await notas_tia()
	elif c == "Caja empotrada":
		await pedir_caja()
	elif c == "Guardar partida":
		await say("Partida guardada." if save() else "No se ha podido guardar en este navegador.")

# banco de semillas: las landraces en sobres de SOBRE semillas; el pedido llega al día siguiente (new_day)
func banco_semillas() -> void:
	var i := 0
	while true:
		var l := []
		for b in D.BANCO:
			if S.ch >= b[2]:
				l.append(b)
		var items := []
		for b in l:
			var s: Dictionary = D.STRAINS[b[0]]
			var np: int = S.pedido.count(b[0])
			items.append({"label": s.n + (" · pedida" if np else ""), "right": Datos.eur(b[1]), "sw": s.c, "ic": ic_cog(b[0]), "desc": strain_line(b[0]) + "\n" + s.h})
		items.append({"label": "Salir", "desc": "Los pedidos llegan mañana por la mañana."})
		i = await menu(items, {"cls": "full", "title": "BANCO DE SEMILLAS", "title2": "Sobres de %s · tienes %s" % [n(D.SOBRE), Datos.eur(S.money + caja_e())], "desc": true, "initial": i})
		if i < 0 or i >= l.size():
			return
		var k: String = l[i][0]
		var pr := int(l[i][1])
		if S.money + caja_e() < pr:
			sfx("bad")
			await say("No te llega el dinero.")
			continue
		pagar_casa(pr)
		S.pedido.append(k)
		sfx("coin")
		toast("Pedido: " + D.STRAINS[k].n + " · llega mañana", 1400)

func recibir_pedido() -> void:
	if S.pedido.is_empty():
		return
	var c := {}
	for k in S.pedido:
		c[k] = c.get(k, 0) + int(D.SOBRE)
	S.pedido = []
	var nl := []
	for k in c:
		S.seeds[k] = S.seeds.get(k, 0) + c[k]
		discover(k)
		nl.append("%s ×%d" % [D.STRAINS[k].n, c[k]])
	queue("pedido", func():
		sfx("get")
		await say("Llega el paquete del banco de semillas:\n%s semillas." % ", ".join(nl))
		await check_story())

func letter_action():
	if S.flags.get("letter"):
		await say("La carta de la tía Maite. «Cuida el armario. Y perdona lo de Baltasar.»")
		return
	await say("Hay una carta encima de la mesa. Es de la tía Maite.")
	await talk("CARTA", ["«{N}: si lees esto, el piso es tuyo. Cuídalo.»", "«Al fondo del salón está mi armario de cultivo. Lo he tenido treinta años y nunca me ha fallado.»",
		"«Pásate por el growshop de Kiko, aquí al lado. Él te enseñará lo que yo no pude.»", "«Le debo dinero a Baltasar, el del bar El Ancla. No es buena gente. Lo siento.»"])
	S.flags.letter = true
	show_objective()

# ---------- el autobús de la comarca (1.10, paradaAction de 08-mundo) ----------
# en el poste de la parada: a dónde, cuánto y cuánto tarda; el reloj corre lo que dura el viaje. El primer viaje (del pueblo al
# piso: llegando()) lo paga ama y solo va a Ribera Verde
func viaje(a: String, b: String) -> Dictionary:
	return {"min": int(D.PARADAS[a].min + D.PARADAS[b].min), "eur": D.PARADAS[a].eur + D.PARADAS[b].eur}

func parada_action():
	var aqui: String = S.map
	var pa: Dictionary = D.PARADAS[aqui]
	if S.min < int(D.BUS_HORAS[0]) or S.min > int(D.BUS_HORAS[1]):   # fuera de horario: se puede esperar al primero (el reloj corre hasta las 7:00)
		if await ask("PARADA DE %s\nEl primer autobús pasa a las 7:00 y el último, a las 21:00." % String(pa.n).to_upper(), ["Esperar al de las 7:00", "Nada"]) != 0:
			return
		await fade(1)
		advance_time((int(D.BUS_HORAS[0]) - int(S.min) + 1440) % 1440)
		build_ents()
		update_hud()
		await wait(300)
		await fade(0)
		await say("Las siete. Llega el primer autobús, medio vacío.")
	var ama := llegando()
	var ds := []
	if ama:
		ds = ["town"]
	else:
		for k in D.PARADAS:
			if k != aqui:
				ds.append(k)
	var it := []
	for k in ds:
		var v := viaje(aqui, k)
		it.append({"label": D.PARADAS[k].n, "right": "billete de ama" if ama else "%s · %d min" % [Datos.eur(v.eur), v.min]})
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿A dónde vas?"})
	if i < 0 or i >= ds.size():
		return
	var k: String = ds[i]
	var v := viaje(aqui, k)
	if not ama:
		if S.money < v.eur:
			await say("El billete hasta %s cuesta %s. No te llega." % [D.PARADAS[k].n, Datos.eur(v.eur)])
			return
		S.money -= v.eur
	sfx("door")
	await fade(1)
	advance_time(v.min)
	var a: Array = D.PARADAS[k].a
	enter_map(k, int(a[0]), int(a[1]), a[2])
	if S.clientsDay != S.day:
		spawn_clients()
	update_hud()
	await wait(80)
	await fade(0)
	if ama:
		S.flags.llegada = true
		await say("Ribera Verde. El piso de la tía es el del tejado rojo, al otro lado de la calle.")
		show_objective()

# ---------- mesa de genética ----------
func _mk(l: Array) -> Array:
	var o := []
	for e in l:
		var s = strain(e[0])
		o.append({"label": s.n, "right": "×" + n(e[1]), "sw": s.c, "ic": ic_cog(e[0]), "desc": strain_line(e[0])})
	return o

# la prensa de rosin (1.10): de un lote de 5 g o más, una parte (5, 25, 100 g o todo) a rosin con el triple de THC
func rosin_de(g: float) -> float:
	return Datos.jsround(g * D.ROSIN.rend * 10) / 10.0

func prensar():
	var lots := bud_lots(5)
	if lots.is_empty():
		await say("PRENSA DE ROSIN: necesitas 5 g de cogollos como mínimo.")
		return
	var it := lots.map(lot_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué prensas?"})
	if i < 0 or i >= lots.size():
		return
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var tot := int(floor(b.g))
	var ops := [5, 25, 100].filter(func(g): return g < tot)
	ops.append(tot)
	var tx := ops.map(func(g): return "%d g → %s g de rosin" % [g, Datos.coma(rosin_de(g))])
	tx.append("Nada")
	var j: int = await ask("%s: %d g. ¿Cuánto prensas?" % [lot_nombre(k), tot], tx)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	var r := rosin_de(g)
	var thc: float = minf(D.ROSIN.tope, b.thc * D.ROSIN.thc)
	use_buds(k, g)
	add_rosin(k, r, thc)
	advance_time(30)
	sfx("get")
	await say("Prensas %d g de %s: %s g de rosin con un %s %% de THC." % [g, lot_nombre(k), Datos.coma(r), Datos.pct(thc)])

func lab_action():
	if S.items.get("prensa"):
		var c: int = await ask("La mesa de la tía. ¿Qué haces?", ["Prensar rosin", "Cruzar semillas", "Nada"])
		if c == 0:
			await prensar()
			return
		if c != 1:
			return
	if not S.flags.get("lab"):
		await say("Una mesa con un microscopio viejo y frascos. Kiko sabrá qué hacer con esto.")
		return
	var GE := int(D.GEN_ESTABLE)
	var hay := false
	for e in _own():
		if e[1] >= 2 and Cultivo.gen_de(S, e[0]) < GE:
			hay = true
	if _own().size() < 2 and not hay:
		await say("MESA DE GENÉTICA: necesitas semillas de dos variedades distintas para cruzar, o 2 de una línea sin estabilizar.")
		return
	var l1 := _own()
	var a: int = await menu(_mk(l1), {"cls": "full", "title": "CRUCE · MADRE", "desc": true})
	if a < 0:
		return
	var A: String = l1[a][0]
	var l2 := _own().filter(func(e): return e[0] != A)
	var ga := Cultivo.gen_de(S, A)
	var it2 := _mk(l2)
	if ga < GE and S.seeds[A] >= 2:
		it2.push_front({"label": "%s · estabilizar" % strain(A).n, "right": "F%d→%s" % [ga, ("F%d" % (ga + 1)) if ga + 1 < GE else "estable"], "sw": strain(A).c, "ic": ic_cog(A),
			"desc": "Cruzas dos plantas de la misma línea y guardas la mejor semilla. Gastas 2 y te quedas 1.\nEn la F%d la variedad queda fijada: todas sus plantas salen iguales." % GE})
	if it2.is_empty():
		await say("Para cruzar %s necesitas semillas de otra variedad." % strain(A).n)
		return
	var b: int = await menu(it2, {"cls": "full", "title": "CRUCE · PADRE", "title2": strain(A).n, "desc": true})
	if b < 0:
		return
	if it2.size() > l2.size() and b == 0:
		await estabilizar(A)
		return
	var Bk: String = l2[b - (it2.size() - l2.size())][0]
	if await ask("¿Cruzar %s × %s? Gastas 1 semilla de cada." % [strain(A).n, strain(Bk).n], ["Cruzar", "Cancelar"]) != 0:
		return
	S.seeds[A] -= 1
	S.seeds[Bk] -= 1
	for k in [A, Bk]:
		if not S.seeds[k]:
			S.seeds.erase(k)
	var r := Datos.cross_result(S, A, Bk)
	var is_new: bool = not S.disc.get(r)
	var s = strain(r)
	if is_new:
		S.gen[r] = 1
	var kr := [A, Bk]
	kr.sort()
	if D.RECIPES.has("+".join(kr)) and not S.rec.get(r):   # de receta, sacada en la mesa: falta cosecharla (capítulo 4)
		S.rec[r] = 1
	await accion("cruzar", {"id": "vfx-polen", "x": P.px + 8, "y": P.py - 4})
	sfx("enc")
	await fade(1, true)
	await wait(450)
	await fade(0, true)
	add_seeds(r, 2)
	if is_new:
		sfx("get")
		await say("Nueva variedad: %s." % s.n)
		await say("THC %s%% · ~%d g/m² · %s días.\nObtienes 2 semillas F1: la línea aún no es estable." % [Datos.pct(s.thc), gm2(s), Datos.coma(s.d)])
		if r == "leyenda":
			await say("Te tiemblan las manos: es GHOST TRAIN HAZE.")
			await talk("SMS · KIKO", ["¿Ghost Train Haze? ¿De semilla propia? Llevo veinte años detrás de ella.", "Tu tía estaría orgullosa. Estabilízala y guárdala bien: eso vale más que el piso."])
	else:
		await say("Obtienes 2 semillas de %s." % s.n)
	await check_story()

# ---------- vista de carpa (09b-carpa) ----------
func vc_geo(ci: int) -> Dictionary:
	return Vista.geo(S, ci)

func maceta_px(k: String) -> Dictionary:
	var m: Array = D.MACETA_CM.get(k, D.MACETA_CM.plastico7)
	return {"w": Datos.jsround(m[0] * D.VB.M), "e": maxi(3, Datos.jsround(m[0] * D.VB.F)), "hb": Datos.jsround(m[1] * D.VB.M)}

# alto en px de la planta; en una plaza q, con el tope de alto de la plaza (q.ch)
func alto_planta(p: Dictionary, q = null) -> int:
	var Dp: Dictionary = D.PLANTA_CM[Datos.porte_planta(S, p)]
	var h := Datos.jsround(Dp.h[2 if p.get("dead") else Cultivo.plant_stage(p)] * D.VB.M)
	if q:
		h = mini(h, int(floor(q.ch * D.VB.M)))
	return h - (4 if p.get("dead") else 0)

# dónde lanzar un efecto sobre la plaza i (riego, cosecha): en la vista, sobre la planta; si no, sobre el jugador
func pos_plaza(i: int) -> Array:
	var q = null
	if VC:
		for o in vc_geo(VC.ci).pl:
			if o.i == i:
				q = o
	if q == null:
		return [P.px + 8, P.py + 2]
	if q.get("v"):
		return [q.x, q.y - q.v.tierra - (int(q.v.hp) >> 1)]
	var p = S.pots[i]
	var h := alto_planta(p, q) if p else 0
	return [q.x, q.y - maceta_px(S.macetas[i]).hb - Datos.jsround(h / 2.0)]

# la ficha de la izquierda: [título, líneas] (una línea con «!» delante va en rojo); vc_texto es lo que se lee en ella
func vc_ficha() -> void:
	if VC == null or VC.ocupado:
		vc_texto = ""
		vc_info_pon(null)
		return
	var c: Dictionary = S.carpas[VC.ci]
	var L := []
	if VC.sel < 0:
		L.append(D.FOCOS[c.foco].n)
		L.append(("Luz " + Datos.eur(luz_carpa(VC.ci)) + " al día") if plantas_vivas(VC.ci) else "Apagado")
		for k in D.EXTRAS:
			if c.get(k):
				L.append(D.EXTRAS[k].c)
	else:
		var i: int = VC.sel
		var p = S.pots[i]
		L.append("Plaza %d · %s L" % [huecos()[i].j + 1, n(D.MACETAS[S.macetas[i]].l)])
		if p == null:
			L.append("Vacía")
		else:
			L.append(strain(p.sid).n)
			if p.get("dead"):
				L.append("Seca")
			else:
				L.append("Cosecha lista" if p.prog >= 1 else "%s %d %%" % [stage_name(p), int(floor(p.prog * 100))])
				L.append("Agua %d %%" % Datos.jsround(p.water))
				L.append("Salud %d %%" % Datos.jsround(p.health))
			if p.pest and not p.get("dead"):
				L.append("!PLAGA")
	var t: String = D.CARPAS[c.t].n
	vc_texto = t
	for l in L:
		vc_texto += l.substr(1) if l.begins_with("!") else l
	vc_info_pon([t, L])

func vc_mover(b: String) -> void:
	var pl: Array = vc_geo(VC.ci).pl
	var cur = null
	for q in pl:
		if q.i == VC.sel:
			cur = q
	var cerca := func(l: Array, x: float) -> Dictionary:
		var m: Dictionary = l[0]
		for q in l.slice(1):
			if absf(q.x - x) < absf(m.x - x):
				m = q
		return m
	if cur == null:
		if b == "down":
			var fm := -1
			for q in pl:
				fm = maxi(fm, q.fila)
			VC.sel = cerca.call(pl.filter(func(q): return q.fila == fm), 120).i
		return
	if b == "left" or b == "right":
		var f := pl.filter(func(q): return q.fila == cur.fila)
		f.sort_custom(func(a, c): return a.x < c.x)
		var k := -1
		for j in f.size():
			if f[j].i == cur.i:
				k = j
		k += -1 if b == "left" else 1
		if k >= 0 and k < f.size():
			VC.sel = f[k].i
	elif b == "up":
		var f := pl.filter(func(q): return q.fila == cur.fila + 1)
		VC.sel = cerca.call(f, cur.x).i if f.size() else -1
	elif b == "down":
		var f := pl.filter(func(q): return q.fila == cur.fila - 1)
		if f.size():
			VC.sel = cerca.call(f, cur.x).i

func _vc_accion() -> void:
	if VC.sel < 0:
		await carpa_action(VC.ci)
	else:
		await pot_action(VC.sel)
	if VC:
		VC.ocupado = false
	vc_ficha()

func abrir_carpa(ci):
	sfx("door")
	await fade(1)
	var pl: Array = vc_geo(ci).pl
	VC = {"ci": ci, "sel": pl[0].i if pl.size() else -1, "ocupado": false}
	mode = "carpa"
	update_hud()
	vc_ficha()
	await fade(0)
	if not S.flags.get("vista"):
		S.flags.vista = true
		toast("◀ ▶ ▲ ▼ eliges planta o foco · A la cuidas · B sales", 2800)
	var pr := Motor.Prom.new()
	push(func(b: String):
		if VC.ocupado:
			return
		if b == "B":
			pop()
			pr.res()
			return
		if b == "A":
			VC.ocupado = true
			vc_ficha()
			_vc_accion()
			return
		if DV.has(b):
			var s0: int = VC.sel
			vc_mover(b)
			if s0 != VC.sel:
				sfx("tick")
				vc_ficha())
	await Motor.espera(pr)
	VC.ocupado = true
	vc_ficha()
	await fade(1)
	mode = "world"
	VC = null
	update_hud()
	await fade(0)

# ---------- virtuales: las definen trama y juego ----------
func save():
	return true
func genoteca():
	pass
func show_objective():
	pass
func raid_event():
	pass
func penalty_event():
	pass
