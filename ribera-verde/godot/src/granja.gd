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
		if c and en_flor(ci):   # (1.11) sin extractor, OLOR; con uno corto de caudal, 1
			a += int(D.OLOR) if Cultivo.kit_de(c) == "" else (1 if Cultivo.ext_carpa(S, ci) < D.OLOR_MAL else 0)
	return a

func luz_carpa(ci: int) -> int:
	return Cultivo.luz_carpa(S, ci)

func factura_luz() -> int:
	var e := 0
	for ci in S.carpas.size():
		if S.carpas[ci] and plantas_vivas(ci):
			e += luz_carpa(ci)
	return e + Cultivo.factura_sala(S) + factura_carro()   # y el carro de esquejes (1.11)

# el carro de esquejes (1.11, CARRO): con algún esqueje en las bandejas, los tubos T5 gastan luz a 18/6
func factura_carro() -> int:
	return Datos.jsround(D.CARRO.w * D.H_24 * 18 / 24.0 / 1000 * D.KWH) if S.bandejas.size() else 0

func carro_ya() -> bool:
	return "carro" in muebles_ya()

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
	if S.min % 30 == 0 and (D.ZONAS.has(S.map) or S.map == "home"):
		music(map_music())

func new_day() -> void:
	S.day += 1
	# la cuota de Molina (1.10): pasado el último día pagado, se acaba la protección (antes de la redada de esta noche)
	if S.protect and S.get("protHasta") and S.day > S.protHasta:
		S.protect = false
		queue("cuota", func(): await talk("SMS · MOLINA", ["Se acabó lo pagado.", "Si quieres que mis agentes sigan mirando hacia otro lado, ya sabes dónde está la comisaría."]))
	# la policía (1.11, NIVEL_POLI): con la orden de ayer, la redada; con 90 o más, la orden (y el aviso), o Molina la para
	if S.get("orden") and S.day > S.orden:
		queue("raid", raid_event)
	elif not S.get("orden") and S.heat >= D.NIVEL_POLI[3][0]:
		if S.protect:
			queue("raid", raid_event)
		else:
			S.orden = S.day
			queue("orden", aviso_orden)
	S.heat = max(0, S.heat - baja_calor())
	var luz := factura_luz()
	var olor := olor_dia()
	var av := []
	var nf: float = pagar_recibo(luz, "Luz") if luz > 0 else 0.0    # 1.35: domiciliada; si no llega, de lo de fuera y de la caja (1.10)
	S.luz = {"d": S.day, "e": luz, "o": olor}
	if luz > 0:
		av.append("Factura de la luz: −" + Datos.eur(luz - nf) + ((" (te faltan %s)" % Datos.eur(nf)) if nf else ""))
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
	var seb := 0
	for e in S.bandejas:
		if S.day - e.dia > D.CARRO.dias:
			seb += 1
	if seb:
		S.bandejas = S.bandejas.filter(func(e): return S.day - e.dia <= D.CARRO.dias)
		av.append("Se %s en las bandejas" % [("han secado %d esquejes" % seb) if seb > 1 else "ha secado un esqueje"])
	curado_dia(av)   # el curado (1.29)
	if av.size() and mode == "world":
		toast("<br>".join(av), 1600)
	spawn_clients()
	recibir_pedido()
	recibir_envio()
	instalar_caja()
	llega_mueble()
	vencer_encargo()
	curro_dia()   # la gente (1.15)
	setas_dia()   # el bajo de las setas (1.20)
	recibos_dia()   # 1.35
	conce_dia()   # 1.43
	vencer_encargo_club()
	if S.due > 0 and S.day > S.deadline:   # 1.10: también sin haber visto a Baltasar (el plazo corre desde Toño)
		queue("penalty", penalty_event)
	elif S.due > 0 and (S.deadline - S.day == 3 or S.deadline == S.day):   # 1.11: a 3 días y el último
		queue("plazo", recuerdo_plazo)
	queue("calor", heat_warn)   # 1.22: el olor de la noche también avisa

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

# número y nombre de cada planta (1.11, nomPlanta de 09-cultivo): la nº de su fenotipo o el nombre de S.fnom, que heredan sus esquejes
func nom_planta(f) -> String:
	if not (f is Dictionary and f.get("id")):
		return ""
	var k := str(int(f.id))
	var fn: Dictionary = S.get("fnom", {})
	return (" «%s»" % fn[k]) if fn.has(k) else " nº " + k

func etiq(f) -> String:
	return nom_planta(f) + marca_feno(f)

func nombrar_planta(f: Dictionary) -> void:
	if not S.has("fnom"):
		S.fnom = {}
	var k := str(int(f.id))
	var v = await pedir_texto("Nombre de la planta (y sus esquejes)", S.fnom.get(k, ""), 12)
	if v == null or (v == "" and not S.fnom.has(k)):
		return
	if v != "":
		S.fnom[k] = v
	else:
		S.fnom.erase(k)
	sfx("sel")
	await say(("Ahora se llama «%s». Sus esquejes, también." % v) if v != "" else ("Sin nombre: vuelve a ser la nº %s." % k))

# un esqueje del propagador o de las bandejas del carro (l): ponerle nombre o tirarlo
func esqueje_accion(e: Dictionary, l: Array) -> void:
	var c: int = await ask("Esqueje de %s%s." % [strain(e.sid).n, etiq(e.f)], ["Nombrar", "Tirar", "Nada"])
	if c == 0:
		await nombrar_planta(e.f)
	elif c == 1:
		l.remove_at(l.find(e))
		sfx("sel")
		await say("Tiras el esqueje.")

# ---------- plantar y cuidar ----------
func _own() -> Array:
	var o := []
	for k in S.seeds:
		if S.seeds[k] > 0:
			o.append([k, S.seeds[k]])
	return o

func plantar(i: int) -> void:
	var own := _own()
	var esq := []   # [esqueje, 1 si es de las bandejas del carro]
	for e in S.esquejes:
		esq.append([e, 0])
	for e in S.bandejas:
		esq.append([e, 1])
	if own.is_empty() and esq.is_empty():
		await say("Maceta vacía. No tienes semillas: cómpralas en el growshop de Kiko.")
		return
	var items := []
	for o in own:
		var s = strain(o[0])
		items.append({"label": s.n, "right": "×" + n(o[1]), "sw": s.c, "ic": ic_cog(o[0]), "desc": strain_line(o[0])})
	for eb in esq:
		var e: Dictionary = eb[0]
		var s = strain(e.sid)
		var v = feno_visto(e.f)
		var dv := ("Fenotipo estrella: THC ×%s y cosecha ×%s." % [Datos.coma(e.f.t), Datos.coma(e.f.y)]) if v == "estrella" else ("Fenotipo flojo: rinde menos que la media." if v == "floja" else "Su fenotipo se sabrá cuando coseches a la madre o a un clon suyo.")
		items.append({"label": "Esqueje " + s.n + etiq(e.f), "right": "bandeja" if eb[1] else "esqueje", "sw": s.c, "ic": ic_cog(e.sid),
			"desc": "Clon enraizado: la misma planta que su madre, con su fenotipo.\n%s\nSe seca si no lo plantas antes del %s." % [dv, Datos.fd(e.dia + (D.CARRO.dias if eb[1] else D.ESQUEJE_DIAS) + 1, S.day)]})
	items.append({"label": "Cancelar", "desc": ""})
	var j: int = await menu(items, {"cls": "full", "title": "¿QUÉ PLANTAS?", "desc": true})
	if j < 0 or j >= own.size() + esq.size():
		return
	if j >= own.size():
		var e: Dictionary = esq[j - own.size()][0]
		var l: Array = S.bandejas if esq[j - own.size()][1] else S.esquejes
		l.remove_at(l.find(e))
		S.pots[i] = {"sid": e.sid, "prog": .12, "water": 70, "health": 100, "fert": false, "pest": false, "f": e.f}   # ya enraizado: empieza de plántula
		sfx("sel")
		await accion("plantar")
		await say("Plantas el esqueje de %s%s." % [strain(e.sid).n, etiq(e.f)])
		await pista_barras()
		return
	var sid: String = own[j][0]
	S.seeds[sid] -= 1
	if not S.seeds[sid]:
		S.seeds.erase(sid)
	S.pots[i] = {"sid": sid, "prog": 0, "water": 70, "health": 100, "fert": false, "pest": false, "f": roll_feno(sid)}
	sfx("sel")
	await accion("plantar")
	await say("Has plantado %s%s." % [strain(sid).n, nom_planta(S.pots[i].f)])
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
	await say("Cortas una punta de la %s%s y la pones a enraizar.\nPlántala antes del %s: es la misma planta." % [s.n, nom_planta(p.f), Datos.fd(S.day + D.ESQUEJE_DIAS + 1, S.day)])
	if carro_ya():
		await say("O pínchala en el carro: allí aguanta %d días." % D.CARRO.dias)

func stage_name(p: Dictionary) -> String:
	return Cultivo.stage_name(p)

func pot_action(i: int) -> void:
	var p = S.pots[i]
	if p == null:
		if macetas_libres(i, false).size():
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
		var c: int = await ask("%s%s lista para cosechar.\nSalud %d%% · Agua %d%%" % [s.n, etiq(p.get("f")), Datos.jsround(p.health), Datos.jsround(p.water)], ["Cosechar", "Nombrar", "Esperar"])
		if c == 0:
			await harvest(i)
		elif c == 1:
			if not p.get("f"):
				p.f = roll_feno(p.sid)
			await nombrar_planta(p.f)
		return
	var veg_k := []
	if p.prog < .65 and not _fv(p) > 0:
		for k in ["fertv", "ofertv"]:
			if S.items.get(k, 0) > 0:
				veg_k.append(k)
	var opts := ["Regar"]
	if not p.fert or veg_k.size():
		opts.append("Abonar")
	if p.pest:
		opts.append("Tratar plaga")
	if p.prog >= .2 and p.prog < .65 and not (Datos.CAL and s.get("auto")):   # 1.52: las autos no se clonan
		opts.append("Sacar esqueje")
	opts.append_array(["Nombrar", "Arrancar", "Salir"])
	var c: int = await ask("%s%s · %s %d%%\nAgua %d%% · Salud %d%%%s" % [s.n, etiq(p.get("f")), stage_name(p), int(floor(p.prog * 100)), Datos.jsround(p.water),
		Datos.jsround(p.health), " · PLAGA" if p.pest else ""], opts)
	var op: String = opts[c]
	if op == "Regar":
		var v := pos_plaza(i)
		await accion("regar", {"id": "vfx-gotas", "x": v[0], "y": v[1] - 6})
		p.water = 100
		S.flags.gRiego = 1
		sfx("sel")
		await say("Riegas la planta. Agua al 100%.")
	elif op == "Abonar":
		await abonar(p, veg_k)
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
	elif op == "Nombrar":
		if not p.get("f"):
			p.f = roll_feno(p.sid)
		await nombrar_planta(p.f)
	elif op == "Arrancar":
		if await ask("¿Seguro que quieres arrancarla?", ["Sí", "No"]) == 0:
			S.pots[i] = null
			await say("Arrancas la planta.")

# tierra (1.10): como mucho LITROS_M2 litros por m² de suelo en cada carpa, sumando todas sus macetas
func litros_max(ci: int) -> int:
	var cm: Array = D.CARPAS[S.carpas[ci].t].cm
	return Datos.jsround(cm[0] * cm[2] / 1e4 * D.LITROS_M2)

func litros_carpa(ci: int) -> int:
	var a := 0
	var hu := huecos()
	for i in hu.size():
		if hu[i].c == ci:
			a += int(D.MACETAS.get(S.macetas[i], D.MACETAS.plastico7).l)
	return a

# macetas de repuesto que caben en la plaza i (y no son la que ya tiene): hasta CARPAS[t].lmax y, con tierra, sin pasar de litros_max
func macetas_libres(i: int, tierra := true) -> Array:
	var h: Dictionary = huecos()[i]
	var C: Dictionary = D.CARPAS[S.carpas[h.c].t]
	var sobra: int = litros_max(h.c) - litros_carpa(h.c) + int(D.MACETAS[S.macetas[i]].l)
	var o := []
	for k in D.MACETAS:
		if S.items.get("m_" + k, 0) > 0 and D.MACETAS[k].l <= C.lmax and k != S.macetas[i] and (not tierra or D.MACETAS[k].l <= sobra):
			o.append(k)
	return o

func cambiar_maceta(i: int) -> void:
	var l := macetas_libres(i)
	var ci: int = huecos()[i].c
	var tl := "tierra %d de %d L" % [litros_carpa(ci), litros_max(ci)]
	if l.is_empty():
		await say(("No cabe más tierra en la carpa (%s)." % tl) if macetas_libres(i, false).size() else "No tienes otra maceta que quepa aquí.")
		return
	var it := []
	for k in l:
		it.append({"label": "Maceta " + D.MACETAS[k].n, "right": "×" + n(S.items["m_" + k]), "ic": icono("maceta"), "desc": desc_maceta(k)})
	var j: int = await menu(it, {"cls": "full", "title": "CAMBIAR MACETA", "title2": "Ahora: " + D.MACETAS[S.macetas[i]].n + " · " + tl, "desc": true})
	if j < 0:
		return
	var k: String = l[j]
	S.items["m_" + k] -= 1
	S.items["m_" + S.macetas[i]] = S.items.get("m_" + S.macetas[i], 0) + 1
	S.macetas[i] = k
	sfx("sel")
	var h: Dictionary = huecos()[i]   # su garrafa, llena para la maceta nueva
	var gc: Dictionary = S.carpas[h.c]
	if gc.get("gar") != null and h.j < gc.gar.size():
		gc.gar[h.j] = null
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
		it.append({"label": "Foco " + D.FOCOS[k].n, "right": "×" + n(S.items["f_" + k]), "ic": icono(Atlas.ico_foco(k)), "desc": desc_foco(k)})
	var j: int = await menu(it, {"cls": "full", "title": "CAMBIAR FOCO", "title2": "Ahora: " + D.FOCOS[S.carpas[ci].foco].n, "desc": true})
	if j < 0:
		return
	instalar_foco(ci, l[j])
	await say("Cuelgas el foco %s. El viejo va a la mochila." % D.FOCOS[l[j]].n)

# pl: femenino plural (las garrafas) · lo que le falta a la carpa (con goteo, las garrafas no)
static func falta_extra(c, k: String) -> bool:
	return c != null and not c.get(k) and not (k == "garrafas" and c.get("goteo"))

func extras_libres(ci: int) -> Array:
	var o := []
	for k in D.EXTRAS:
		if falta_extra(S.carpas[ci], k) and S.items.get("x_" + k, 0) > 0:
			o.append(k)
	return o

# abono, pH y EC (1.11, 09-cultivo): lo que aprovecha la dosis (con pH− y medidor, 1; a ojo, .75; sin pH−, .5) y su texto.
# 1.23: por marca (D.PRODUCTOS): el pH− que se gasta es el de su marca y, si no hay, el otro
func ph_item(bio):
	for k in (["ophm", "phm"] if bio else ["phm", "ophm"]):
		if S.items.get(k, 0) > 0:
			return k
	return null

func abono_q(bio = 0) -> float:
	return float(Cultivo.abo_de(bio).q[(2 if S.items.get("medidor", 0) else 1) if ph_item(bio) != null else 0])

# 1.23 (09-cultivo: abonar): el de crecimiento (veg_k: los que hay, en vegetativo y sin él) o el de floración; con dos marcas, eliges
func abonar(p: Dictionary, veg_k: Array) -> void:
	var veg := veg_k.size() > 0
	var ks := veg_k
	if not veg:
		ks = []
		for x in ["fert", "ofert"]:
			if S.items.get(x, 0) > 0:
				ks.append(x)
	if ks.is_empty():
		await say("No te queda ABONO.")
		return
	var k: String = ks[0]
	if ks.size() > 1:
		var L := []
		for x in ks:
			L.append("%s ×%s" % [D.PRODUCTOS[x].n, n(S.items[x])])
		L.append("Nada")
		var c: int = await ask("¿Qué abono le echas?", L)
		if c < 0 or c >= ks.size():
			return
		k = ks[c]
	var bio: bool = true if D.PRODUCTOS[k].bio else false
	var ph = ph_item(bio)
	var q := abono_q(bio)
	if ph != null:
		S.items[ph] -= 1
		if not D.PRODUCTOS[ph].bio:
			p.min = 1
	S.items[k] -= 1
	if bio:
		p.org = 1
	else:
		p.min = 1
	if veg:
		p.fv = q
		if bio:
			p.fvo = 1
		S.flags.gVeg = 1
	else:
		p.fert = true
		p.fq = q
		if bio:
			p.fo = 1
		S.flags.gFlor = 1
	sfx("sel")
	var t := "Echas una dosis de %s. %s" % [String(D.PRODUCTOS[k].n).to_upper(), "Crecerá más deprisa." if veg else "Dará más cosecha."]
	if ph != null:
		t += ("\nCon el medidor, el pH al %s: lo aprovecha entero." % Datos.coma(D.ABONO.ph[2])) if S.items.get("medidor", 0) else "\nCorriges el pH a ojo, sin medidor: lo aprovecha casi todo."
	elif bio:
		t += "\nSin pH−, la tierra amortigua el agua del grifo: lo aprovecha al %d %%." % Datos.jsround(D.ABONO_BIO.q[0] * 100)
	else:
		t += "\nSin pH−, el agua del grifo (pH %s) bloquea %d %% del abono." % [Datos.coma(D.ABONO.ph[0]), Datos.jsround((1 - D.ABONO.q[0]) * 100)]
	await say(t)
	if ph != null and (true if D.PRODUCTOS[ph].bio else false) != bio:
		await say(("No te queda pH− de su marca: gastas una dosis de %s." % D.PRODUCTOS[ph].n) + (" Con el mineral, el sustrato ya no está vivo." if bio else ""))

func _fv(p: Dictionary) -> float:
	return float(p.fv) if p.get("fv") != null else 0.0

func abono_txt(p: Dictionary) -> String:
	var L := []
	if _fv(p) > 0:
		L.append("crecimiento" + (" bio" if p.get("fvo") else ""))
	if p.fert:
		L.append("floración" + (" bio" if p.get("fo") else ""))
	var t := ("Abonada (" + " y ".join(L) + ")") if L.size() else "Sin abonar"
	if Cultivo.sustrato_vivo(p):
		t += " · sustrato vivo"
	if S.items.get("medidor", 0) and L.size():
		var ec := Datos.jsround((.4 + ((.4 if p.get("fvo") else .7) if _fv(p) > 0 else 0.0) + ((.5 if p.get("fo") else .9) if p.fert else 0.0)) * 10) / 10.0
		var iv := _ph_i(_fv(p), p.get("fvo")) if _fv(p) > 0 else 2   # cada dosis, con la q de su marca (phDe)
		var ifl := _ph_i(Cultivo.fq(p), p.get("fo")) if p.fert else 2
		t += " · EC %s · pH %s" % [Datos.coma(ec), Datos.coma(D.ABONO.ph[mini(iv, ifl)])]
	return t

func _ph_i(q: float, bio) -> int:
	var Q: Array = Cultivo.abo_de(bio).q
	return 2 if q >= float(Q[2]) else (1 if q >= float(Q[1]) else 0)

# el goteo llega lleno y las garrafas que hubiera vuelven a la mochila; las garrafas llegan llenas; un kit de extracción
# devuelve el que hubiera (1.11: lo devuelve poner_extra, para el mensaje)
func poner_extra(ci: int, k: String) -> String:
	var c: Dictionary = S.carpas[ci]
	var vk := Cultivo.kit_de(c) if D.KITS.has(k) else ""
	S.items["x_" + k] -= 1
	if vk != "":
		c[vk] = false
		S.items["x_" + vk] = S.items.get("x_" + vk, 0) + 1
	c[k] = true
	if k == "goteo":
		c.dep = Cultivo.goteo_l(S, ci)
		if c.get("garrafas"):
			c.garrafas = false
			c.erase("gar")
			S.items.x_garrafas = S.items.get("x_garrafas", 0) + 1
	if k == "garrafas":
		c.gar = []
	sfx("sel")
	return vk

# el temporizador de la carpa ci (vista de carpa, a la izquierda del foco): automático, 18/6 (madres) o 12/12 (floración)
func temporizador(ci: int) -> void:
	var c: Dictionary = S.carpas[ci]
	var k := Cultivo.ciclo_de(c)
	var K: Array = D.CICLOS.keys()
	var opts := []
	for x in K:
		opts.append(D.CICLOS[x].m)
	opts.append("Salir")
	var j: int = await ask("Temporizador · %s: %s\nLuz %s al día con plantas" % [D.CICLOS[k].n, D.CICLOS[k].c.to_lower(), Datos.eur(luz_carpa(ci))], opts)
	if j < 0 or j >= K.size() or K[j] == k:
		return
	if K[j] == "auto":
		c.erase("ciclo")
	else:
		c.ciclo = K[j]
	sfx("sel")
	await say(D.CICLOS[K[j]].d)

func carpa_action(ci: int) -> void:
	var c: Dictionary = S.carpas[ci]
	var C: Dictionary = D.CARPAS[c.t]
	var F: Dictionary = D.FOCOS[c.foco]
	var f := focos_libres(ci).size()
	var ex := extras_libres(ci)
	var gl := Cultivo.goteo_l(S, ci)
	var dep: float = (c.dep if c.get("dep") != null else float(gl)) if c.get("goteo") else 0.0
	var gar: bool = c.get("garrafas", false) and not c.get("goteo")
	var ga := Cultivo.garrafas_carpa(S, ci)
	var ll: bool = dep < gl if c.get("goteo") else (gar and ga[0] < ga[1])
	var opts := ["Cambiar foco"] if f else []
	for k in ex:
		opts.append("Poner " + D.EXTRAS[k].c.to_lower())
	if ll:
		opts.append("Rellenar depósito" if c.get("goteo") else "Rellenar garrafas")
	opts.append("Salir")
	var gt: String = (" · goteo %s de %s L" % [Datos.miles(floor(dep)), Datos.miles(gl)]) if c.get("goteo") else ((" · garrafas %d de %d L" % [int(floor(ga[0])), ga[1]]) if gar else "")
	var k: int = await ask("%s · %s plantas · %s\n%d W/m² · luz %s al día con plantas%s" % [C.n, n(C.plazas), F.n, Datos.jsround(F.w / (C.cm[0] * C.cm[2] / 1e4)), Datos.eur(luz_carpa(ci)), gt], opts)
	if opts[k] == "Cambiar foco":
		await cambiar_foco(ci)
		return
	if opts[k] == "Rellenar depósito":
		c.dep = gl
		sfx("sel")
		await say("Llenas el depósito del goteo: %s L." % Datos.miles(gl))
		return
	if opts[k] == "Rellenar garrafas":
		c.gar = []
		sfx("sel")
		await say("Llenas las garrafas: %d L." % ga[1])
		return
	var ix := k - (1 if f else 0)
	if k < 0 or ix < 0 or ix >= ex.size():
		return
	var x: String = ex[ix]
	var vu: bool = x == "goteo" and c.get("garrafas", false)
	var vk := poner_extra(ci, x)
	await say("Pones %s %s en %s %s.\n%s%s%s" % ["las" if D.EXTRAS[x].get("pl") else "el", D.EXTRAS[x].n.to_lower(), "el" if C.n.begins_with("Armario") else "la", C.n.to_lower(), D.EXTRAS[x].d,
		"\nLas garrafas vuelven a la mochila." if vu else "", ("\nEl %s vuelve a la mochila." % D.EXTRAS[vk].c.to_lower()) if vk != "" else ""])

# ---------- cosecha ----------
func semillas_cosecha(p: Dictionary) -> Dictionary:
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
	return {"cria": cria, "fem": fem, "n": nn}

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
	var sc := semillas_cosecha(p)
	var cria: bool = sc.cria
	var fem: bool = sc.fem
	var nn: int = sc.n
	var lk: String = p.sid + "*" if cl == "estrella" else p.sid
	add_buds(lk, g, thc)
	if nn:
		add_seeds(p.sid, nn)
	var sobra := mini(g, int(floor(peso_encima() - cap_mochila())))   # lo que no cabe encima, a la caja fuerte (1.36; antes, al arcón)
	var a_caja := mini(sobra, int(floor(D.CAJA[int(S.caja.nivel)].g - caja_g()))) if sobra >= 1 and S.get("caja") else 0
	if a_caja >= 1:
		mover_lote(S.buds, S.caja.buds, lk, a_caja)
	if p.get("f") and p.f.get("id"):
		S.fenos[str(int(p.f.id))] = cl
	S.pots[i] = null
	sfx("get")
	if S.rec.get(p.sid) == 1:   # una variedad de receta sacada en la mesa, cosechada (capítulo 4)
		S.rec[p.sid] = 2
	await say("Cosechas %d g de %s. THC: %s%%." % [g, s.n, Datos.pct(thc)])
	if sobra >= 1:
		await say("No te cabe todo en la %s: " % D.MOCHILAS[int(S.items.get("bolsa", 0))].n.to_lower() + ("%d g van a la caja fuerte." % a_caja if a_caja >= 1 else "")
			+ (("%sLlevas %d g de más: guárdalos en cuanto puedas." % [" " if a_caja >= 1 else "", sobra - a_caja]) if sobra - a_caja >= 1 else ""))
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
	if not S.items.get("tarros") and not S.flags.get("curado"):   # 1.29, una vez
		S.flags.curado = S.day
		await say("Sale sin curar. Con unos tarros de curado (los vende Kiko), en la caja fuerte se cura en %d días: algo más de THC y se vende más cara. Sin curar no pierde nada." % int(D.CURADO.dias))   # 1.36: ya no pierde THC; curando, sube
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
# la cama del piso y, desde la 1.10, la de casa de ama (txt): allí no hay robo de Darko ni aviso de plagas (las plantas están en el piso).
# El aviso dice solo la luz pagada durmiendo (1.11): la factura es de un día entero, a medianoche (new_day); una siesta que no pasa de las 12, nada
func bed_action(txt := ""):
	var piso: bool = S.map == "home"
	var deco: bool = piso and con_deco().size() > 0
	var c: int = await ask(txt if txt else "Tu cama. Todavía huele a la colonia de la tía.", ["Dormir hasta las 7", "Siesta de 3 h"] + (["Cambiarte de ropa"] if piso else []) + (["Decorar la casa"] if deco else []) + ["Nada"])
	if piso and c == 2:   # ropa y pelo (1.21)
		await vestirte()
		return
	if deco and c == 3:   # 1.27
		await decorar()
		return
	if c > 1:
		return
	await fade(1)
	var mins := 180 if c == 1 else Cultivo.minutos_cama(S, 0)
	var antes := []
	var d0: int = S.day
	for p in S.pots:
		antes.append([true if p.pest else false, true if p.get("dead") else false] if p else null)
	advance_time(mins)
	S.hp = S.hpMax
	build_ents()
	update_hud()
	await wait(500)
	await fade(0)
	var hoy = S.luz if S.get("luz") and S.day > d0 else null
	var diario: bool = piso and not S.flags.get("diario")   # el diario de la tía, bajo la almohada (1.25)
	if diario:
		S.flags.diario = S.day
	save()
	toast("Has descansado" + ((" · Luz −" + Datos.eur(hoy.e)) if hoy and hoy.e else "") + ((" · Olor: calor +" + n(hoy.o)) if hoy and hoy.o else "") + " · Partida guardada", 1800)
	if not piso:
		return
	if diario:
		await almohada()
	if S.day > d0 and S.ch == 7 and not S.flags.get("robo") and (S.money > 1000 or gramos_flor() + nevera_r() / D.ROSIN.rend > 100):
		await robo_darko()   # la amenaza de Darko (1.10; 1.36: con lo de la nevera)
	await aviso_plaga(antes)

# la primera vez que duermes en el piso (1.25): el diario de la tía Maite, bajo la almohada (S.flags.diario; el recetario, en trama)
func almohada() -> void:
	await say("Das vueltas y más vueltas. Al ahuecar la almohada notas algo duro dentro de la funda.")
	sfx("get")
	await say("Un cuaderno de tapas verdes, gastado de tanto abrirlo: «Cuaderno de cultivo · M.». El diario de la tía Maite.")
	await say("Una página por cada variedad que conoció: lo que apuntó de ella, las recetas de sus cruces y dónde guardaba las semillas que no se venden.")
	await say("Lo tienes en START → GENOTECA. Algunas landraces no están en ningún banco: habrá que buscarlas.")

static func _lista(L: Array) -> String:
	return L[0] if L.size() == 1 else ", ".join(L.slice(0, -1)) + " y " + L[-1]

# al despertar: las que han cogido plaga mientras dormías (y el insecticida que te queda), las que la siguen teniendo sin
# tratar, las que se han secado del todo (antes: [plaga, muerta] de cada plaza al acostarte) y las que florecen con moho porque
# su carpa pasa de HR_OK de noche (09c-sala; 1.11: clima_carpa)
func aviso_plaga(antes: Array) -> void:
	var nuevas := []
	var siguen := []
	var muertas := []
	var moho := []
	var H := huecos()
	var hum := []
	for ci in S.carpas.size():
		hum.append(S.carpas[ci] != null and Cultivo.clima_carpa(S, ci, true).hr > D.HR_OK[1])
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
		else:
			if p.pest:
				(siguen if a[0] else nuevas).append(nom)
			if hum[H[i].c] and p.prog >= .65 and p.prog < 1:
				moho.append(nom)
	if nuevas.size():
		var k: int = S.items.insect
		sfx("bad")
		await say("¡Plaga en %s! Trátala%s con INSECTICIDA: %s" % [_lista(nuevas), "s" if nuevas.size() > 1 else "", ("te queda%s %d." % ["n" if k > 1 else "", k]) if k else "no te queda; cómpralo en el growshop."])
	if siguen.size():
		await say("Sigue la plaga en %s: sin tratar, pierde%s salud cada hora." % [_lista(siguen), "n" if siguen.size() > 1 else ""])
	if muertas.size():
		await say("Se ha%s secado del todo %s. Retírala%s con A." % ["n" if muertas.size() > 1 else "", _lista(muertas), "s" if muertas.size() > 1 else ""])
	if moho.size():
		await say("Moho en %s: de noche la carpa pasa del %s %% de humedad. Un extractor a su medida con intractor, un ventilador o un deshumidificador la bajan." % [_lista(moho), n(D.HR_OK[1])])

# ---------- PC ----------
func pc_action():
	var o := ["Genoteca"]
	if S.ch >= 2:
		o.append("Banco de semillas")
	o.append_array(["Notas de la tía", "Tienda online"])
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
	elif c == "Tienda online":
		await tienda_online()
	elif c == "Caja empotrada":
		await pedir_caja()
	elif c == "Guardar partida":
		await say("Partida guardada." if save() else "No se ha podido guardar en este navegador.")

# ---------- salón (12c-salon, 1.10): los muebles se compran por internet y llegan al día siguiente ----------
func por_hora(l: Array) -> String:
	return l[(int(S.day) * 24 + int(S.min) / 60) % l.size()]

func noticia() -> String:
	if S.heat >= 60:
		return "Noticias: la policía busca un cultivo de interior en Ribera Verde. Los vecinos denuncian olor a marihuana en varios portales."
	if S.heat >= 30:
		return "Noticias: detenido en el puerto un hombre con dos kilos de marihuana escondidos en una furgoneta de reparto."
	return "Noticias: el tiempo. Nubes y claros en la costa y la ría en calma. Nada que contar en Ribera Verde."

func mueble_action(k):
	if k == "carro":
		await carro_action()
		return
	if k == "sillon":
		var o := (["Leer el diario de la tía Maite"] if S.flags.get("diario") else []) + ["Cambiar el tapizado", "Nada"]
		var oi: int = await ask("Tu sillón de lectura. La lámpara da una luz cálida.", o)
		var c: String = o[oi] if oi >= 0 and oi < o.size() else ""
		if c == "Cambiar el tapizado":
			await cambiar_deco(k)
			return
		if c != "Leer el diario de la tía Maite":
			return
		advance_time(30)
		update_hud()
		await recetario()
		return
	if k == "cuadro":
		var o := ["Cambiar la lámina", "Nada"]
		var oi: int = await ask("En la pared del salón: %s." % D.DECO.cuadro.v[deco_v("cuadro")].to_lower(), o)
		if oi == 0:
			await cambiar_deco(k)
		return
	if k == "sofa":
		var o := ["Echar una cabezada (1 h)"]
		if "tv" in muebles_ya():
			o.append("Ver la tele")
		o.append("Cambiar el tapizado")
		o.append("Nada")
		var oi: int = await ask("Tu sofá. Todavía huele a nuevo.", o)
		var c: String = o[oi] if oi >= 0 and oi < o.size() else ""
		if c == "Ver la tele":
			await mueble_action("tv")
			return
		if c == "Cambiar el tapizado":
			await cambiar_deco(k)
			return
		if c != "Echar una cabezada (1 h)":
			return
		await fade(1)
		advance_time(60)
		S.hp = min(S.hpMax, S.hp + 5)
		build_ents()
		update_hud()
		await wait(300)
		await fade(0)
		await say("Una cabezada en el sofá: +5 de vida.")
		return
	if k == "tv":
		var o := ["Noticias", "Documental", "Nada"]
		var oi: int = await ask("La tele.", o)
		var c: String = o[oi] if oi >= 0 and oi < o.size() else ""
		if c == "Nada" or c == "":
			return
		var t := noticia() if c == "Noticias" else por_hora(D.DOCU)
		advance_time(60)
		update_hud()
		await say(t)
		return
	var o := ["Jugar (2 h)", "Foro de cultivo", "Tienda online", "Apagar"]
	var oi: int = await ask("El PC gaming. Los ventiladores brillan de colores.", o)
	var c: String = o[oi] if oi >= 0 and oi < o.size() else ""
	if c == "Jugar (2 h)":
		var t := por_hora(D.JUEGOS)
		await fade(1)
		advance_time(120)
		build_ents()
		update_hud()
		await wait(300)
		await fade(0)
		await say(t)
	elif c == "Foro de cultivo":
		var t := por_hora(D.FORO)
		advance_time(30)
		update_hud()
		await say("Foro de cultivo · " + t)
	elif c == "Tienda online":
		await tienda_online()

# personalizar la casa (1.16): elegir el tapizado o la lámina (DECO, 12c-salon)
func cambiar_deco(k: String) -> void:
	var Dk: Dictionary = D.DECO[k]
	var v := deco_v(k)
	var items := []
	for j in Dk.v.size():
		items.append({"label": Dk.v[j] + (" · ahora" if j == v else "")})
	items.append({"label": "Volver"})
	var i: int = await menu(items, {"title": "Cambiar " + Dk.q, "initial": v})
	if i < 0 or i >= Dk.v.size() or i == v:
		return
	S.deco[k] = i
	sfx("sel")
	montar_casa()
	await say("Cambias %s %s: %s." % [Dk.q, ("de " + D.MUEBLES[k].art).replace("de el ", "del "), Dk.v[i].to_lower()])

# decorar la casa (1.27): en la cama del piso, lo que tiene DECO de lo que ya ha llegado
func con_deco() -> Array:
	return muebles_ya().filter(func(k): return D.DECO.has(k))

func decorar() -> void:
	var i := 0
	while true:
		var ks := con_deco()
		var items := []
		for k in ks:
			var a: String = D.MUEBLES[k].art
			items.append({"label": "%s: %s" % [a.left(1).to_upper() + a.substr(1), String(D.DECO[k].v[deco_v(k)]).to_lower()]})
		items.append({"label": "Listo"})
		i = await menu(items, {"title": "Decorar la casa", "initial": i})
		if i < 0 or i >= ks.size():
			return
		await cambiar_deco(ks[i])

# reformas (1.27, REFORMA de 12c-salon): el suelo y las paredes, por la tienda online; el instalador o el pintor viene al día siguiente
func reformas() -> void:
	var i := 0
	while true:
		var items := []
		var ks := []
		for k in D.REFORMA:
			var R: Dictionary = D.REFORMA[k]
			var v := deco_v(k)
			var o = S.obra.get(k) if S.get("obra") is Dictionary else null
			for j in R.v.size():
				var en: bool = j == v
				var pd: bool = o != null and int(o.v) == j
				ks.append([k, j])
				items.append({"label": "%s: %s" % [R.n, R.v[j][0]] + (" · pedido" if pd else " · en casa" if en else ""), "right": Datos.eur(R.v[j][1]), "disabled": o != null or en,
					"desc": R.v[j][2] + (("\n%s viene mañana." % R.quien) if pd else "\nYa hay una obra pedida: viene mañana." if o != null else "" if en else ("\n%s viene mañana." % R.quien))})
		items.append({"label": "Volver", "desc": "Pagas con lo que llevas y, si no llega, con la caja fuerte."})
		i = await menu(items, {"cls": "full", "title": "REFORMAS", "title2": "Suelo y paredes · tienes " + Datos.eur(S.money + caja_e()), "desc": true, "initial": i})
		if i < 0 or i >= ks.size():
			return
		var k: String = ks[i][0]
		var j: int = ks[i][1]
		var R: Dictionary = D.REFORMA[k]
		var p = R.v[j][1]
		if not await tarjeta(p, "Reforma · " + String(R.n).to_lower()):   # 1.35: con tarjeta
			continue
		if not (S.get("obra") is Dictionary):
			S.obra = {}
		S.obra[k] = {"v": j, "dia": S.day + 1}
		sfx("coin")
		toast("Pedido: %s, %s · mañana" % [R.n.to_lower(), String(R.v[j][0]).to_lower()], 1400)

# ropa y pelo (1.21, vestirte): desde la cama del piso, la camiseta, el pantalón, la gorra y el pelo (S.ropa[k], índice en ROPA[k].v)
func vestirte() -> void:
	while true:
		var ks: Array = D.ROPA.keys()
		var items := []
		for k in ks:
			items.append({"label": "%s: %s" % [D.ROPA[k].n, String(D.ROPA[k].v[ropa_v(k)][0]).to_lower()]})
		items.append({"label": "Listo"})
		var i: int = await menu(items, {"title": "Ropa y pelo"})
		if i < 0 or i >= ks.size():
			return
		var k: String = ks[i]
		var R: Dictionary = D.ROPA[k]
		var v := ropa_v(k)
		var its := []
		for n in R.v.size():
			its.append({"label": R.v[n][0] + (" · ahora" if n == v else "")})
		its.append({"label": "Volver"})
		var j: int = await menu(its, {"title": R.n, "initial": v})
		if j >= 0 and j < R.v.size() and j != v:
			S.ropa[k] = j
			sfx("sel")

func tienda_online() -> void:
	var i := 0
	while true:
		var ks: Array = D.MUEBLES.keys().filter(func(k): return not D.MUEBLES[k].get("grow"))
		var vs: Array = D.VEHICULOS.keys().filter(func(k): return not D.VEHICULOS[k].get("conce"))   # 1.43: la moto, en el concesionario
		var ya := muebles_ya()
		var items := []
		for k in ks:
			var m: Dictionary = D.MUEBLES[k]
			var en: bool = k in ya
			var pd: bool = not en and S.get("muebles") is Dictionary and float(S.muebles.get(k, 0)) > 0
			var al := "a casa" if k == "cartel" else "al salón"   # el póster, al dormitorio (1.27)
			items.append({"label": m.n + (" · en casa" if en else " · pedido" if pd else ""), "right": Datos.eur(m.p), "disabled": en or pd,
				"desc": m.d + ("" if en else ("\nLlega mañana: te lo suben %s." % al) if pd else ("\nLlega mañana y te lo suben %s." % al))})
		for k in vs:   # el patinete y la bici (1.13)
			var v: Dictionary = D.VEHICULOS[k]
			var d = S.veh.get(k) if S.get("veh") is Dictionary else null
			var en: bool = d != null and float(d) <= S.day
			items.append({"label": v.n + (" · tuyo" if en else " · pedido" if d else ""), "right": Datos.eur(v.p), "disabled": d != null and float(d) > 0,
				"desc": v.d + ("" if en else "\nLlega mañana: te lo dejan en el portal.")})
		var AR: Dictionary = D.NEVERA.arcon   # el arcón congelador (1.39): 5 kg más de extractos, en frío
		var ar = S.nevera.get("arcon") if S.get("nevera") != null else null
		items.append({"label": AR.n + (" · en casa" if ar == 1 else " · pedido" if ar != null else ""), "right": Datos.eur(AR.p), "disabled": ar != null,
			"desc": AR.d + ("\nLa nevera de serie: %s." % (Datos.coma(D.NEVERA.g / 1000.0) + " kg") if ar == null else "")})
		items.append({"label": "Reformas: suelo y paredes", "desc": "El suelo y las paredes del piso: el instalador o el pintor vienen al día siguiente."})   # 1.27
		if Datos.CAL:   # 1.43.6: el camarote
			items.append({"label": "El camarote: almacén", "desc": "Habilitar el camarote de arriba como almacén, las estanterías de tarros de cristal de 10 L y los sobres de humedad."})
		var SO: Dictionary = D.SOTANO
		var sot_ok: bool = Datos.CAL and S.ch >= int(SO.ch)   # 1.51: el sótano de casa, para setas
		if sot_ok:
			var sd = S.sot.get("d") if S.get("sot") is Dictionary else null
			items.append({"label": SO.obra.n + (" · hecho" if sd != null and float(sd) <= S.day else " · mañana" if sd != null else ""), "right": Datos.eur(SO.obra.p), "disabled": sd != null, "desc": SO.obra.d})
		items.append({"label": "Salir", "desc": "Con tarjeta, de la cuenta del banco."})
		i = await menu(items, {"cls": "full", "title": "TIENDA ONLINE", "title2": "Muebles y transporte · en la cuenta " + Datos.eur(S.banco), "desc": true, "initial": i})
		if i == ks.size() + vs.size():
			if ar == null and await tarjeta(AR.p, "Tienda online · " + AR.n):
				nevera().arcon = -(S.day + 1)   # pedido: el día en que llega, en negativo; 1, en casa
				sfx("coin")
				toast("Pedido: " + AR.n + " · llega mañana", 1400)
			continue
		if i == ks.size() + vs.size() + 1:
			await reformas()
			continue
		if Datos.CAL and i == ks.size() + vs.size() + 2:
			await camarote_tienda()
			continue
		if sot_ok and i == ks.size() + vs.size() + 3:
			if not (S.get("sot") is Dictionary) and await tarjeta(SO.obra.p, "Tienda online · " + SO.obra.n):
				S.sot = {"d": S.day + 1, "bandejas": [], "g": 0, "fr": []}
				sfx("coin")
				toast("Pedido: " + SO.obra.n + " · los obreros vienen mañana", 1400)
			continue
		if i < 0 or i >= ks.size() + vs.size():
			return
		var es_m: bool = i < ks.size()
		var k: String = ks[i] if es_m else vs[i - ks.size()]
		var m: Dictionary = D.MUEBLES[k] if es_m else D.VEHICULOS[k]
		if not await tarjeta(m.p, "Tienda online · " + m.n):   # 1.35: con tarjeta
			continue
		var cl: String = "muebles" if es_m else "veh"
		if not (S.get(cl) is Dictionary):
			S[cl] = {}
		S[cl][k] = S.day + 1
		sfx("coin")
		toast("Pedido: " + m.n + " · llega mañana", 1400)

# el camarote (1.43.6, lo pidió el usuario: «habilitar el camarote de arriba… como almacén» con «botes más grandes de cristal con
# bóvedas de humedad»): la obra, las estanterías de 6 tarros de 10 L (hasta CAMAROTE.est.max) y las cajas de sobres al 62 %; todo
# con tarjeta y al día siguiente (llega_camarote)
func camarote_tienda() -> void:
	var CM: Dictionary = D.CAMAROTE
	var i := 0
	while true:
		var c := cam()
		var hecha: bool = c.has("d")
		var lista := cam_ya()
		var ne: int = c.get("e", []).size()
		var pend_e: int = ne - cam_est()
		var pend_s := 0
		for q in c.get("sp", []):
			pend_s += int(q[1])
		var items := [
			{"label": CM.obra.n + (" · hecho" if lista else " · mañana" if hecha else ""), "right": Datos.eur(CM.obra.p), "disabled": hecha, "desc": CM.obra.d},
			{"label": "%s · %d/%d%s" % [CM.est.n, ne, int(CM.est.max), (" · %d mañana" % pend_e) if pend_e else ""], "right": Datos.eur(CM.est.p), "disabled": not hecha or ne >= int(CM.est.max),
				"desc": (CM.est.d % int(CM.tarro)) + ("" if hecha else "\nAntes hay que habilitar el camarote.")},
			{"label": CM.sob.n + ((" · quedan %d" % ceili(float(c.get("sob", 0)) - 1e-9)) if float(c.get("sob", 0)) > 0 else "") + ((" · %d mañana" % pend_s) if pend_s else ""), "right": Datos.eur(CM.sob.p), "disabled": not hecha,
				"desc": (CM.sob.d % int(CM.dura)) + ("\nCon sobres, lo curado se afina en %d días: se vende un %d %% más caro." % [int(CM.af), Datos.jsround(CM.extra * 100)])},
			{"label": "Volver"}]
		i = await menu(items, {"cls": "full", "title": "EL CAMAROTE", "title2": "Almacén · en la cuenta " + Datos.eur(S.banco), "desc": true, "initial": i})
		if i < 0 or i > 2:
			return
		var art: Dictionary = [CM.obra, CM.est, CM.sob][i]
		if not await tarjeta(art.p, "Tienda online · " + art.n):
			continue
		if not (S.get("cam") is Dictionary):
			S.cam = {"e": [], "sob": 0.0, "sp": [], "buds": {}}
		if i == 0:
			S.cam.d = S.day + 1
		elif i == 1:
			S.cam.e.append(S.day + 1)
		else:
			S.cam.sp.append([S.day + 1, int(CM.sob.u)])
		sfx("coin")
		toast("Pedido: " + art.n + " · " + ("los obreros vienen mañana" if i == 0 else "llega mañana"), 1400)

func llega_camarote() -> void:
	if not Datos.CAL or not (S.get("cam") is Dictionary):
		return
	var av := []
	if S.cam.has("d") and int(S.cam.d) == S.day:
		av.append("Los obreros acaban el camarote: aislado, con pladur, tarima, luz y deshumidificador. Se sube por la escalera escamoteable de entre las carpas.")
	var ne: int = S.cam.e.filter(func(d): return int(d) == S.day).size()
	if ne:
		av.append("Llega%s %s: te %s suben al camarote. Caben ahora %s kg." % ["" if ne == 1 else "n", "la estantería de tarros de 10 L" if ne == 1 else "%d estanterías de tarros de 10 L" % ne, "la" if ne == 1 else "las", Datos.coma(cam_cap() / 1000.0)])
	var quedan := []
	for q in S.cam.sp:
		if int(q[0]) <= S.day:
			S.cam.sob = float(S.cam.get("sob", 0)) + int(q[1])
			av.append("Llegan los sobres de humedad al 62 %%: uno en cada tarro del camarote (quedan %d)." % ceili(S.cam.sob - 1e-9))
		else:
			quedan.append(q)
	S.cam.sp = quedan
	if av.size():
		montar_casa()
		queue("camarote", func():
			sfx("get")
			for t in av:
				await say(t))

func llega_mueble() -> void:
	llega_camarote()   # 1.43.6
	if Datos.CAL and S.get("sot") is Dictionary and int(S.sot.get("d", -1)) == S.day:   # 1.51: el sótano
		queue("sotano", func():
			sfx("get")
			await say("Los obreros acaban el sótano: sin trastos, impermeabilizado, con luz, desagüe y tres estanterías de rejilla. Se baja por la puerta del dormitorio. Las bandejas te las prepara Txomin."))
	if S.get("nevera") != null and S.nevera.get("arcon") != null and S.nevera.arcon != 1 and -int(S.nevera.arcon) <= S.day:   # el arcón (1.39)
		S.nevera.arcon = 1
		queue("arcon", func():
			sfx("get")
			await say("Llega el mensajero con el arcón congelador: te lo dejan enchufado al lado de la nevera. En frío caben ahora %s." % (Datos.coma(nevera_cap() / 1000.0) + " kg")))
	var ob := []   # las reformas (1.27)
	if S.get("obra") is Dictionary:
		for k in S.obra.keys():
			if S.obra[k].dia <= S.day:
				ob.append(k)
	if ob.size():
		for k in ob:
			S.deco[k] = S.obra[k].v
			S.obra.erase(k)
		montar_casa()
		queue("obra", func():
			sfx("get")
			for k in ob:
				var R: Dictionary = D.REFORMA[k]
				await say("%s viene a primera hora: %s, %s." % [R.quien, R.nuevo, String(R.v[deco_v(k)][0]).to_lower()]))
	var vs := []   # el patinete y la bici (1.13)
	if S.get("veh") is Dictionary:
		for k in D.VEHICULOS:
			if S.veh.get(k) == S.day:
				vs.append(D.VEHICULOS[k].art)
	if vs.size():
		queue("vehiculo", func():
			sfx("get")
			await say("Llega el mensajero con %s. En la calle vas montado; con B, aún más rápido." % _lista(vs)))
	var l := []
	var on := []
	var gr := []
	if S.get("muebles") is Dictionary:
		for k in D.MUEBLES:
			if S.muebles.get(k) == S.day:
				l.append(D.MUEBLES[k].art)
				(gr if D.MUEBLES[k].get("grow") else on).append(D.MUEBLES[k].art)
	if l.is_empty():
		return
	montar_casa()
	# si estás donde lo montan, te apartas a la casilla libre más cercana (llegaMueble en el HTML)
	if S.map == "home" and tile_solid(MAPS.home, P.x, P.y):
		var ok := false
		for r in range(1, 4):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if ok or maxi(absi(dx), absi(dy)) != r or tile_solid(MAPS.home, P.x + dx, P.y + dy):
						continue
					var x: int = P.x + dx
					var y: int = P.y + dy
					P.x = x
					P.y = y
					P.px = x * 16.0
					P.py = y * 16.0
					P.fx = x
					P.fy = y
					P.moving = false
					S.x = x
					S.y = y
					ok = true
	queue("mueble", func():
		sfx("get")
		if on.size():
			await say("Llega el mensajero con %s: te lo dejan montado en %s." % [_lista(on), "casa" if D.MUEBLES.cartel.art in on else "el salón"])   # el póster, en el dormitorio (1.27)
		if gr.size():
			await say("Kiko te sube %s y te lo deja montado delante de las carpas." % _lista(gr)))

# el carro de esquejes (1.11, carroAction): en la tabla de corte, los del propagador se pinchan en las bandejas, donde aguantan
# CARRO.dias desde ese día; se plantan desde la plaza vacía (plantar)
func carro_action() -> void:
	# 1.40 (lo pidió el usuario): el carro se ve tal cual, dos bandejas de tacos (arriba y abajo) en vez de un menú; A en un taco
	# vacío pincha los del propagador y A en un esqueje lo nombra o lo tira
	var cap: int = D.CARRO.bandejas * D.CARRO.plazas
	var sel := mini(S.bandejas.size(), cap - 1)
	while true:
		var q = await elegir_carro(sel)
		if q == null:
			return
		sel = int(q)
		var nb: int = S.bandejas.size()
		if sel < nb:
			await esqueje_accion(S.bandejas[sel], S.bandejas)
			sel = mini(sel, maxi(0, S.bandejas.size()))
			continue
		if S.esquejes.is_empty():
			await say("Taco vacío. Saca esquejes de una madre en vegetativo y pínchalos aquí.")
			continue
		var m: int = mini(cap - nb, S.esquejes.size())
		for e in S.esquejes.slice(0, m):
			S.bandejas.append({"sid": e.sid, "f": e.f, "dia": S.day})
		S.esquejes = S.esquejes.slice(m)
		sfx("sel")
		await say("En la tabla de corte, corte en bisel y hormona: %s." % (("pinchas %d esquejes" % m) if m > 1 else "pinchas 1 esqueje"))
		await say("En las bandejas aguantan hasta el %s: plántalos cuando haya hueco." % Datos.fd(S.day + D.CARRO.dias, S.day))
		var r: int = S.esquejes.size()
		if r:
			await say(("No caben %d: se quedan en el propagador." % r) if r > 1 else "No cabe 1: se queda en el propagador.")
		sel = mini(S.bandejas.size(), cap - 1)

# la vista del carro (en trama.gd): el taco elegido (0-23: la bandeja de arriba, 0-11, y la de abajo, 12-23) o null
func elegir_carro(_i0 := 0):
	return null

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
		i = await menu(items, {"cls": "full", "title": "BANCO DE SEMILLAS", "title2": "Sobres de %s · en la cuenta %s" % [n(D.SOBRE), Datos.eur(S.banco)], "desc": true, "initial": i})
		if i < 0 or i >= l.size():
			return
		var k: String = l[i][0]
		var pr := int(l[i][1])
		if not await tarjeta(pr, "Banco de semillas"):   # 1.35: con tarjeta
			continue
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
	var mios := coches_mios()   # 1.43: con un vehículo del concesionario, a dónde quieras y a cualquier hora
	if mios.size() and not llegando():
		var ops: Array = ["En autobús"]
		for k in mios:
			ops.append("En " + String(D.CONCE.v[k].art))
		ops.append("Nada")
		var c: int = await ask("PARADA DE %s\n¿Cómo vas?" % String(pa.n).to_upper(), ops)
		if c < 0 or c > mios.size():
			return
		if c > 0:
			await conducir(mios[c - 1])
			return
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
			if k != aqui and S.ch >= int(D.PARADAS[k].cap):   # las líneas, por capítulos (1.14)
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

# la mesa (1.35): las extracciones que puedes hacer (extr_ya; extraer, en trama), cruzar o nada
func lab_action():
	var L := extr_ya()
	if not L.is_empty():
		var c: int = await ask("La mesa de la tía. ¿Qué haces?", L.map(func(t): return D.EXTR[t].v) + ["Cruzar semillas", "Nada"])
		if c >= 0 and c < L.size():
			await extraer(L[c])
			return
		if c != L.size():
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
	if is_new and not D.SHOP.any(func(it): return it.get("sid") == r):   # la de tienda sigue estable
		S.gen[r] = 1
	if Datos.receta_de(S, A, Bk) and not S.rec.get(r):   # de receta, sacada en la mesa: falta cosecharla (capítulo 4)
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
			await say("Te tiemblan las manos: es JACK HERER.")
			await talk("SMS · KIKO", ["¿Jack Herer? ¿De semilla propia? Llevo veinte años detrás de ella.", "Tu tía estaría orgullosa. Estabilízala y guárdala bien: eso vale más que el piso."])
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
	if VC.sel == Vista.SEL_TEMP:
		var k := Cultivo.ciclo_de(c)
		L.append("Temporizador")
		L.append(D.CICLOS[k].n + " · " + D.CICLOS[k].c)
		L.append(("Luz " + Datos.eur(luz_carpa(VC.ci)) + " al día") if plantas_vivas(VC.ci) else "Apagado")
	elif VC.sel < 0:
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
			L.append(strain(p.sid).n + etiq(p.get("f")))
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
		if b == "left" and VC.sel == -1:
			VC.sel = Vista.SEL_TEMP
		elif b == "right" and VC.sel == Vista.SEL_TEMP:
			VC.sel = -1
		elif b == "down":
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
		elif k < 0:
			VC.sel = Vista.SEL_TEMP
	elif b == "up":
		var f := pl.filter(func(q): return q.fila == cur.fila + 1)
		VC.sel = cerca.call(f, cur.x).i if f.size() else -1
	elif b == "down":
		var f := pl.filter(func(q): return q.fila == cur.fila - 1)
		if f.size():
			VC.sel = cerca.call(f, cur.x).i

func _vc_accion() -> void:
	if VC.sel == Vista.SEL_TEMP:
		await temporizador(VC.ci)
	elif VC.sel < 0:
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
		toast("◀ ▶ ▲ ▼ eliges planta, foco o reloj · A la cuidas · B sales", 2800)
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
	revisa_misiones()   # 1.11: lo montado en la carpa cuenta ya
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
func aviso_orden():
	pass
func recuerdo_plazo():
	pass
func penalty_event():
	pass

# ---------- el banco, los recibos y los locales (1.35, 11k-banco) ----------
# el efectivo (S.money) y la cuenta (S.banco): con tarjeta, lo que deja rastro; la luz, domiciliada; el cajero, con sus topes al día
func movimiento(t: String, e: float) -> void:
	S.mov.push_front({"d": S.day, "t": t, "e": roundi(e)})
	if S.mov.size() > int(D.CUENTA.mov):
		S.mov.resize(int(D.CUENTA.mov))

func cobro_banco(e: float, t: String) -> bool:
	if S.banco < e:
		return false
	S.banco -= e
	movimiento(t, -e)
	return true

func abono_banco(e: float, t: String) -> void:
	S.banco += e
	movimiento(t, e)

func pagar_recibo(e: float, t: String) -> float:
	var b: float = minf(S.banco, e)
	if b > 0:
		S.banco -= b
		movimiento(t, -b)
	return pagar_casa(e - b)

func tarjeta(e: float, t: String) -> bool:
	if cobro_banco(e, t):
		return true
	sfx("bad")
	await say("La tarjeta no pasa: en la cuenta tienes %s. Ingresa efectivo en un cajero." % Datos.eur(S.banco))
	return false

func sacado() -> float:
	return float(S.saca.e) if S.get("saca") is Dictionary and S.saca.d == S.day else 0.0

func ingresado() -> float:
	return float(S.ingr.e) if S.get("ingr") is Dictionary and S.ingr.d == S.day else 0.0

func cantidad(t: String, mx: int) -> int:
	var v := []
	for x in D.CUENTA.pasos:
		if x < mx:
			v.append(int(x))
	if mx >= 1:
		v.append(mx)
	var ops := []
	for x in v:
		ops.append(Datos.eur(x))
	ops.append("Nada")
	var i: int = await ask(t, ops)
	return v[i] if i >= 0 and i < v.size() else 0

func cajero() -> void:
	await acceso("pin", cifras_acceso("pin"))   # 1.53: la tarjeta y el PIN
	while true:
		var ops := ["Sacar", "Ingresar", "Movimientos", "Salir"]
		var oi: int = await ask("CAJERO · en la cuenta tienes %s." % Datos.eur(S.banco), ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "Sacar":
			var mx := int(floorf(minf(S.banco, D.CUENTA.sacar - sacado())))
			if mx < 1:
				sfx("bad")
				await say("No hay saldo." if S.banco < 1 else "Hoy ya has sacado %s: es el tope del cajero." % Datos.eur(sacado()))
				continue
			var e: int = await cantidad("¿Cuánto sacas? Hoy, hasta %s." % Datos.eur(mx), mx)
			if not e:
				continue
			S.saca = {"d": S.day, "e": sacado() + e}
			S.banco -= e
			S.money += e
			movimiento("Cajero", -e)
			sfx("coin")
			update_hud()
		elif op == "Ingresar":
			var mx := int(floorf(minf(S.money, D.CUENTA.ingreso - ingresado())))
			if mx < 1:
				sfx("bad")
				await say("No llevas efectivo." if S.money < 1 else "Hoy ya has ingresado %s. Más, y el banco pregunta de dónde sale." % Datos.eur(ingresado()))
				continue
			var e: int = await cantidad("¿Cuánto ingresas? Sin preguntas, hasta %s al día." % Datos.eur(D.CUENTA.ingreso), mx)
			if not e:
				continue
			S.ingr = {"d": S.day, "e": ingresado() + e}
			S.money -= e
			S.banco += e
			movimiento("Ingreso en efectivo", e)
			sfx("coin")
			update_hud()
		elif op == "Movimientos":
			await banca()
		else:
			return

func recibo_nave() -> float:
	return D.RECIBO.dias * D.NAVE.dia

func recibo_setas() -> float:
	var ay: float = float(D.SETAS_AY.sueldo) if Datos.CAL and S != null and S.get("setas") is Dictionary and S.setas.get("ay") else 0.0   # 1.51: el ayudante
	return D.RECIBO.dias * D.SETAS.dia + ay

func recibos() -> Array:
	var r := []
	if S.get("nave") != null and not S.nave.get("mia"):
		r.append(["Nave de Valdehierro", S.nave.r, recibo_nave(), "efectivo", r.size()])
	if S.get("setas") != null:
		r.append(["Bajo de la Kale Zaharra", S.setas.r, recibo_setas(), "efectivo", r.size()])
	for k in S.loc:
		r.append([D.LOCALES[k].n, S.loc[k].r, D.LOCALES[k].sem, "cuenta", r.size()])
	for k in D.CONCE.orden:   # 1.43.2: el seguro y el impuesto de circulación de cada vehículo, domiciliados, cada año
		if S.get("coches") is Dictionary and S.coches.has(k):
			if S.coches[k].get("r") != null:
				r.append(["Seguro · " + String(D.CONCE.v[k].n), S.coches[k].r, seguro_anio(k), "cuenta", r.size()])
			if S.coches[k].get("iv") != null:
				r.append(["Impuesto de circulación · " + String(D.CONCE.v[k].n), S.coches[k].iv, D.CONCE.v[k].ivtm, "cuenta", r.size()])
	if S.protect and S.get("protHasta"):
		r.append(["Sargento Molina", S.protHasta + 1, D.SOBORNO, "mano", r.size()])
	r.sort_custom(func(a, b): return a[1] < b[1] or a[1] == b[1] and a[4] < b[4])   # estable, como sort de JS
	return r

const COMO := {"cuenta": "de la cuenta", "efectivo": "en efectivo", "mano": "en mano, en la comisaría"}

func banca() -> void:
	var it := []
	for r in recibos():
		it.append({"label": "Recibo · " + r[0], "right": Datos.eur(r[2]), "desc": "El %s, %s." % [Datos.fd(r[1], S.day), COMO[r[3]]]})
	for m in S.mov:
		it.append({"label": m.t, "right": ("−" if m.e < 0 else "+") + Datos.eur(absf(m.e)), "desc": mayus(Datos.fd_larga(m.d)) + "."})
	it.append({"label": "Salir", "desc": "Ingresos en efectivo: hasta %s al día sin preguntas (hoy, %s)." % [Datos.eur(D.CUENTA.ingreso), Datos.eur(ingresado())]})
	await menu(it, {"cls": "full", "title": "BANCA", "title2": "Saldo " + Datos.eur(S.banco), "desc": true})

# un recibo (o.r, el día): el aviso, el cobro (en efectivo, de lo que llevas y de la caja; o domiciliado) y la gracia; false si se pierde
func cobra(o: Dictionary, e: float, quien: String, banco: bool, t: String, per := 0, f := "r") -> bool:
	var N := "SMS · " + quien
	if S.day == o[f] - D.RECIBO.aviso:
		var tx: String = ("El %s se carga el recibo de %s: %s. Saldo: %s." % [Datos.fd(o[f], S.day), t, Datos.eur(e), Datos.eur(S.banco)]) if banco else ("El %s paso a cobrar: %s, en efectivo. Tenlo preparado." % [Datos.fd(o[f], S.day), Datos.eur(e)])
		queue("av" + t, func(): await talk(N, [tx]))
	if S.day < o[f]:
		return true
	var ok: bool = cobro_banco(e, "Recibo · " + t) if banco else (S.money + caja_e() >= e and pagar_casa(e) == 0)
	if ok:
		o[f] += per if per else int(D.RECIBO.dias)   # 1.43.2: el seguro y el impuesto, cada año (per; f, el campo de la fecha)
		return true
	if S.day < o[f] + (D.RECIBO.graciaB if banco else D.RECIBO.gracia):
		var tx: String = ("Recibo de %s devuelto: %s. Si el %s no hay saldo, %s." % [t, Datos.eur(e), Datos.fd(o[f] + D.RECIBO.graciaB, S.day), "se cobra por apremio, con recargo" if f == "iv" else "se rescinde el contrato"]) if banco else "He pasado a cobrar y no había nada. Vuelvo mañana; como no esté, cambio la cerradura."
		queue("dv" + t, func(): await talk(N, [tx]))
		return true
	return false

func recibos_dia() -> void:
	for k in S.loc.keys():
		var L: Dictionary = D.LOCALES[k]
		var o: Dictionary = S.loc[k]
		if Datos.CAL:   # 1.45: lo que ha vendido el negocio (neg_venta), a la cuenta; la limpieza baja y el género se gasta
			neg_o(k)
			var v := neg_venta(k)
			o.ay = v
			o.vt = int(o.vt) + v
			if v > 0:
				abono_banco(v, "Ventas · " + L.n)
			o.cu = maxi(0, int(o.cu) - int(D.NEGOCIO.cu[1]))
			o.st = maxi(0, int(o.st) - 1)
		if o.caja > 0:   # lo de ayer, ya limpio
			var nt: int = roundi(o.caja * (1 - L.com))
			abono_banco(nt, "Ingresos · " + L.n)
			o.tot += nt
			o.caja = 0
		if not cobra(o, L.sem, "BANCO", true, L.n):
			S.loc.erase(k)
			var tx: String = "Contrato de %s rescindido por impago. La fianza no se devuelve." % L.n
			queue("loc" + k, func(): await talk("SMS · BANCO", [tx]))
	if S.protect and S.protHasta - S.day == D.RECIBO.aviso:
		var tx: String = "Lo nuestro se acaba el %s. Si quieres seguir, ya sabes dónde está la comisaría." % Datos.fd(S.protHasta, S.day)
		queue("avMolina", func(): await talk("SMS · MOLINA", [tx]))

# los locales (LOCALES): uno por pueblo, por lo pagado de la deuda; meter efectivo en la caja del negocio, que sale limpio mañana
func pagado_deuda() -> float:
	return D.DEUDA - S.debt

func local_de(m: String, x: int, y: int) -> String:
	for k in D.LOCALES:
		var L: Dictionary = D.LOCALES[k]
		if L.map == m and L.x == x and L.y == y:
			return k
	return ""

func del_neg(L: Dictionary) -> String:   # «las llaves del lavadero», «de la taberna»
	var t: String = L.neg
	return "del " + t.substr(3) if t.begins_with("el ") else ("de la " + t.substr(3) if t.begins_with("la ") else t)

func metido(o: Dictionary) -> float:
	return o.caja if o.dia == S.day else 0.0

func rotulo_local(k: String) -> void:
	var L: Dictionary = D.LOCALES[k]
	var N: String = String(L.n).to_upper()
	if not S.loc.has(k):
		if pagado_deuda() < L.pago:
			await say("SE ALQUILA. Debajo, a boli: «Preguntar en el bar El Ancla». El dueño es amigo de Don Baltasar: hasta que no le hayas pagado %s, para ti no está." % Datos.eur(L.pago))
			return
		if await ask("SE TRASPASA: %s, con el local. %s de fianza y %s cada %s días, domiciliados. Por su caja pasa el efectivo que metas, hasta %s al día: al día siguiente, en tu cuenta, menos un %d %% de gastos e impuestos." % [L.neg, Datos.eur(L.fianza), Datos.eur(L.sem), n(D.RECIBO.dias), Datos.eur(L.tope), roundi(L.com * 100)], ["Alquilarlo", "No"]) != 0:
			return
		if not await tarjeta(L.fianza + L.sem, "Fianza · " + L.n):
			return
		S.loc[k] = {"r": S.day + D.RECIBO.dias, "caja": 0, "dia": 0, "tot": 0}
		if Datos.CAL:
			neg_o(k)
		sfx("coin")
		update_hud()
		await got("las llaves " + del_neg(L))
		await say("%s: el negocio sigue con su gente. Tú metes el efectivo en la caja y, a la mañana siguiente, sale en el banco como lo que ha hecho." % L.n)
		if Datos.CAL:
			montar_locales(S.map)
			await say("Por dentro se lleva todo: la caja, el género, la limpieza y las mejoras. Lo que venda, si lo cuidas, también entra en la cuenta.")
		return
	if Datos.CAL:   # 1.45: el negocio se lleva desde dentro
		await say("%s es tuyo: la caja, el género y la gente están dentro. Entra por la puerta." % mayus(L.neg))
		return
	var o: Dictionary = S.loc[k]
	while true:
		var hoy: float = metido(o)
		var ops := ["Meter efectivo", "Dejar el local", "Nada"]
		var oi: int = await ask("Hoy, %s de %s en caja · lavado en total, %s · próximo recibo, el %s." % [Datos.eur(hoy), Datos.eur(L.tope), Datos.eur(o.tot), Datos.fd(o.r, S.day)], ops, N)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "Meter efectivo":
			var mx := int(floorf(minf(S.money, L.tope - hoy)))
			if mx < 1:
				sfx("bad")
				await say("No llevas efectivo." if S.money < 1 else "Hoy ya hay %s en la caja: más, y Hacienda se fija." % Datos.eur(L.tope))
				continue
			var e: int = await cantidad("¿Cuánto metes en la caja? Hoy, hasta %s." % Datos.eur(mx), mx)
			if not e:
				continue
			o.caja = hoy + e
			o.dia = S.day
			S.money -= e
			sfx("coin")
			update_hud()
			await say("Mañana entran en la cuenta %s como ingresos %s." % [Datos.eur(roundi(o.caja * (1 - L.com))), del_neg(L)])
		elif op == "Dejar el local":
			if await ask("¿Dejas %s? Te devuelven la fianza a la cuenta%s." % [L.neg, "; lo de la caja de hoy se queda en el negocio" if o.caja > 0 else ""], ["Dejarlo", "No"]) != 0:
				continue
			S.loc.erase(k)
			abono_banco(L.fianza, "Fianza · " + L.n)
			sfx("coin")
			update_hud()
			await say("Has dejado %s." % L.neg)
			return
		else:
			return

# ---------- los negocios por dentro (1.45, lo pidió el usuario; con Datos.CAL) ----------
# «que también funcione… dependiendo de cómo cuides el local»: S.loc[k] gana cu (la limpieza, 0-100: baja NEGOCIO.cu[1] al día),
# st (los días de género que quedan), mj (las mejoras compradas, 0-2), ay (lo que vendió ayer) y vt (lo vendido en total).
# Cada mañana, el negocio vende su base × limpieza × mejoras × género (sin género, NEGOCIO.sinGen) ± NEGOCIO.azar, y entra limpio
func neg_o(k: String) -> Dictionary:
	var o: Dictionary = S.loc[k]
	for c in [["cu", int(D.NEGOCIO.cu[0])], ["st", 0], ["mj", 0], ["ay", 0], ["vt", 0]]:
		if not o.has(c[0]):
			o[c[0]] = c[1]
	return o

func neg_tope(k: String) -> int:
	return roundi(float(D.LOCALES[k].tope) * (1 + float(D.NEGOCIO.mjT) * int(neg_o(k).mj)))

func neg_venta(k: String) -> int:
	var N: Dictionary = D.NEGOCIO.k[k]
	var o := neg_o(k)
	var f: float = (0.4 + 0.6 * int(o.cu) / 100.0) * (1 + float(D.NEGOCIO.mjF) * int(o.mj)) * (1.0 if int(o.st) > 0 else float(D.NEGOCIO.sinGen))
	var a: float = 1 + float(D.NEGOCIO.azar) * ((absi(hash("%s|%d" % [k, int(S.day)])) % 201) / 100.0 - 1)
	return roundi(float(N.base) * f * a)

func neg_cuidado(k: String) -> String:
	for c in D.NEGOCIO.cuTxt:
		if int(neg_o(k).cu) >= int(c[0]):
			return c[1]
	return ""

func neg_caja(k: String) -> void:
	var L: Dictionary = D.LOCALES[k]
	var N: Dictionary = D.NEGOCIO.k[k]
	var T: String = String(L.n).to_upper()
	while S.loc.has(k):
		var o := neg_o(k)
		var hoy: float = metido(o)
		var ops := ["Meter efectivo", "Las cuentas", "Reponer género"]
		if int(o.mj) < N.mj.size():
			ops.append("Mejora: " + N.mj[int(o.mj)].n)
		ops += ["Dejar el local", "Nada"]
		var oi: int = await ask("LA CAJA · hoy, %s de %s metidos · ayer vendió %s." % [Datos.eur(hoy), Datos.eur(neg_tope(k)), Datos.eur(int(o.ay))], ops, T)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "Meter efectivo":
			var mx := int(floorf(minf(S.money, neg_tope(k) - hoy)))
			if mx < 1:
				sfx("bad")
				await say("No llevas efectivo." if S.money < 1 else "Hoy ya hay %s en la caja: más, y Hacienda se fija." % Datos.eur(neg_tope(k)))
				continue
			var e: int = await cantidad("¿Cuánto metes en la caja? Hoy, hasta %s." % Datos.eur(mx), mx)
			if not e:
				continue
			o.caja = hoy + e
			o.dia = S.day
			S.money -= e
			sfx("coin")
			update_hud()
			await say("Mañana entran en la cuenta %s como ingresos %s." % [Datos.eur(roundi(o.caja * (1 - L.com))), del_neg(L)])
		elif op == "Las cuentas":
			await say("Ayer vendió %s; en total, %s. Por la caja has lavado %s." % [Datos.eur(int(o.ay)), Datos.eur(int(o.vt)), Datos.eur(int(o.tot))], T)
			await say("El local %s (%d %%). Género para %d días. Mejoras: %d de %d. El recibo, %s el %s." % [neg_cuidado(k), int(o.cu), int(o.st), int(o.mj), N.mj.size(), Datos.eur(L.sem), Datos.fd(o.r, S.day)], T)
		elif op == "Reponer género":
			await neg_genero(k)
		elif op.begins_with("Mejora"):
			var M: Dictionary = N.mj[int(o.mj)]
			if await ask("%s: %s, con tarjeta. Vende un %d %% más y por la caja pasa un %d %% más al día." % [M.n, Datos.eur(M.p), roundi(float(D.NEGOCIO.mjF) * 100), roundi(float(D.NEGOCIO.mjT) * 100)], ["Hacerla", "No"], T) != 0:
				continue
			if not await tarjeta(M.p, "Obra · " + L.n):
				continue
			o.mj = int(o.mj) + 1
			montar_locales(S.map)
			build_ents()
			sfx("get")
			await say("Hecho: %s." % M.n.to_lower())
		elif op == "Dejar el local":
			if await ask("¿Dejas %s? Te devuelven la fianza a la cuenta; las mejoras se quedan." % L.neg, ["Dejarlo", "No"]) != 0:
				continue
			S.loc.erase(k)
			abono_banco(L.fianza, "Fianza · " + L.n)
			sfx("coin")
			update_hud()
			await say("Has dejado %s. Devuelves las llaves al salir." % L.neg)
			return
		else:
			return

func neg_genero(k: String) -> void:
	var L: Dictionary = D.LOCALES[k]
	var N: Dictionary = D.NEGOCIO.k[k]
	var o := neg_o(k)
	var dias := int(D.NEGOCIO.st)
	var e: int = roundi(float(N.gen) * dias)
	if await ask("Género (%s): queda para %d días. Sin género vende un %d %% de lo normal. ¿Pides para %d días por %s, con tarjeta?" % [N.gn, int(o.st), roundi(float(D.NEGOCIO.sinGen) * 100), dias, Datos.eur(e)], ["Pedirlo", "No"]) != 0:
		return
	if not await tarjeta(e, "Género · " + L.n):
		return
	o.st = int(o.st) + dias
	sfx("coin")
	update_hud()
	toast("Género para %d días" % int(o.st), 1400)

func neg_limpiar(k: String) -> void:
	var o := neg_o(k)
	if await ask("El local %s (%d %%). ¿Lo friegas y lo ordenas? Es una hora." % [neg_cuidado(k), int(o.cu)], ["Limpiar", "Nada"]) != 0:
		return
	await fade(1)
	advance_time(int(D.NEGOCIO.limpia))
	o.cu = 100
	update_hud()
	await wait(300)
	await fade(0)
	sfx("get")
	toast("El local reluce", 1400)

func talk_neg(k: String) -> void:
	var N: Dictionary = D.NEGOCIO.k[k]
	var o := neg_o(k)
	var T: String = N.emp[2]
	var q: String = ("Ayer hicimos %s. " % Datos.eur(int(o.ay))) + ("El local %s." % neg_cuidado(k)) + (" Y nos estamos quedando sin %s." % N.gn if int(o.st) <= 1 else "")
	var c: int = await ask(q, ["La caja", "Nada"], T)
	if c == 0:
		await neg_caja(k)

func sprite_rotulo() -> String:
	for k in D.LOCALES:
		if D.LOCALES[k].map == S.map:
			return "rotuloL-%d" % (1 if S.loc.has(k) else 0)
	return "rotuloL-0"
