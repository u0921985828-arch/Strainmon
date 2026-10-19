# F8 (de trama.gd): la nave por dentro, GAUA, la asociación y los mercados.
extends "res://src/venta.gd"

# ---------- la nave: mesas, estantería, secadero y escritorio ----------
# S.nave: {m: las NAVE.max mesas (null, vacía, o {k: el lote, f: el fenotipo, thc, y: × cosecha, dia: el de plantar, g y t: lo que hay
# en el secadero y su THC medio, abo: 0 sin abono, 1 MEATZA, 2 ORTUA BIO}), ab: {m, o}: dosis de floración de cada marca en la estantería}
func nave_nueva() -> Dictionary:
	var m := []
	m.resize(int(D.NAVE.max))
	var fs := []
	for i in int(D.NAVE.max):
		fs.append("led")
	return {"m": m, "ab": {"m": 0, "o": 0}, "f": fs, "ex": 0, "rg": 0, "ma": [], "r": S.day + D.RECIBO.dias}   # 1.34: las madres (ma); 1.35: el día del recibo (r)

# el equipo de la nave (1.33, FOCO_NAVE, EXTR_NAVE, RIEGO_NAVE y NIVEL_NAVE de 11j-locales): el calor de los focos encendidos, lo que
# quita el que no saca la extracción y las dosis de la estantería, enteras
func calor_nave() -> float:
	var t := 0.0
	for i in S.nave.m.size():
		if S.nave.m[i]:
			t += float(D.FOCO_NAVE[S.nave.f[i]].calor)
	return t

func sofoco_nave() -> float:
	return maxf(.6, 1 - .08 * maxf(0, calor_nave() - float(D.EXTR_NAVE[int(S.nave.ex)].cap)))

func dosis_txt(x) -> String:
	return Datos.js_num(Datos.jsround(float(x) * 10) / 10.0).replace(".", ",")

func nivel_nave() -> String:
	return D.NIVEL_NAVE[int(S.nave.ex) + int(S.nave.rg)]

func nave_stock() -> float:
	var t := 0.0
	if S.get("nave") != null:
		for Me in S.nave.m:
			if Me:
				t += Me.g + (float(Me.h.g) if Me.get("h") != null else 0.0)
	return t

# lo que cuelga secándose en el secadero (1.41): g
func colgado_nave() -> float:
	var t := 0.0
	if S.get("nave") != null:
		for Me in S.nave.m:
			if Me and Me.get("h") != null:
				t += float(Me.h.g)
	return t

func fase_mesa(i: int) -> int:
	if S.get("nave") == null or i < 0 or i >= S.nave.m.size() or not S.nave.m[i]:
		return 0
	var Me: Dictionary = S.nave.m[i]
	if Me.get("p") == null:   # una mesa de antes de la 1.41 (las pantallas del HTML): por días
		var d: int = int(S.day - Me.dia)
		return 1 if d < 1 else (2 if d < 3 else (3 if d < D.NAVE.crece else 4))
	var p := float(Me.p)   # 1.41: por el ciclo, como las plantas del piso (plant_stage)
	return 1 if p < .35 else (2 if p < .65 else (3 if p < .85 else 4))

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
	ops.append("Focos")
	ops.append("Nada")
	var que: String = (mesa_txt(Me) + " · " + D.FASE_MESA[fase_mesa(i)] + " · " + cosecha_txt(Me) + " · " + D.ABONO_MESA[int(Me.abo)]) if Me else "vacía"
	var oi: int = await ask("Mesa %d · %s · %s\n%s" % [i + 1, que, D.FOCO_NAVE[N.f[i]].n, ("La cuida " + w.n + ".") if w else "Nadie la cuida: pon a alguien de tu plantilla en la nave."], ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op == "Focos":
		await focos_nave(i)
	elif op == "Plantar" or op == "Arrancar y plantar":
		if Me and Me.get("h") != null:
			await say("Lo de esta mesa aún se está secando en el secadero: espera a descolgarlo.")
			return
		if Me and Me.g >= 1:
			await say("Antes, descuelga del secadero lo de esta mesa.")
			return
		await plantar_mesa(i)
	elif op == "Abono":
		var c: int = await ask("¿Qué abono le echa cada día? En la estantería: MEATZA ×%s · ORTUA BIO ×%s." % [dosis_txt(N.ab.m), dosis_txt(N.ab.o)], ["Sin abono", "MEATZA Floración", "ORTUA BIO Floración", "Nada"])
		if c < 3:
			Me.abo = c
			sfx("sel")

# una semilla o un esqueje de los tuyos, que se gasta (1.34, elegirPlanta: o, con madres, el clon de una madre de la nave, que no se
# gasta): {sid, f} o null
func elegir_planta(title: String, madres: bool):
	var own := _own()
	var esq := []   # [esqueje, 1 si es de las bandejas del carro]
	for e in S.esquejes:
		esq.append([e, 0])
	for e in S.bandejas:
		esq.append([e, 1])
	var ma: Array = S.nave.ma if madres and S.get("nave") != null else []
	var bc: Array = bandejas_listas() if madres else []   # 1.43: las bandejas de clones enraizados de la nave
	if own.is_empty() and esq.is_empty() and ma.is_empty() and bc.is_empty():
		await say("No llevas semillas ni esquejes.")
		return null
	var items := []
	for j in ma.size():
		var k := lot_sid(ma[j].k)
		var s = strain(k)
		items.append({"label": "Madre %d: %s%s" % [j + 1, s.n, etiq(ma[j].get("f"))], "right": "clon", "sw": s.c, "ic": ic_cog(k), "desc": "Un clon de la carpa de las madres: no se gasta nada."})
	for b in bc:
		var k := lot_sid(b.k)
		var s = strain(k)
		items.append({"label": "Bandeja: %s%s" % [s.n, etiq(b.get("f"))], "right": "%d clones" % int(D.NAVE.tacos), "sw": s.c, "ic": ic_cog(k), "desc": "Los clones enraizados del carro de bandejas: una mesa entera."})
	for o in own:
		var s = strain(o[0])
		items.append({"label": s.n, "right": "×" + n(o[1]), "sw": s.c, "ic": ic_cog(o[0]), "desc": strain_line(o[0])})
	for eb in esq:
		var s = strain(eb[0].sid)
		items.append({"label": "Esqueje " + s.n + etiq(eb[0].f), "right": "bandeja" if eb[1] else "esqueje", "sw": s.c, "ic": ic_cog(eb[0].sid), "desc": "Clon enraizado: sale con su fenotipo."})
	items.append({"label": "Cancelar", "desc": ""})
	var j: int = await menu(items, {"cls": "full", "title": title, "desc": true})
	if j < 0 or j >= items.size() - 1:
		return null
	if j < ma.size():
		return {"sid": lot_sid(ma[j].k), "f": ma[j].f}
	j -= ma.size()
	if j < bc.size():
		S.nave.bc.erase(bc[j])
		return {"sid": lot_sid(bc[j].k), "f": bc[j].get("f")}
	j -= bc.size()
	if j < own.size():
		var sid: String = own[j][0]
		S.seeds[sid] -= 1
		if not S.seeds[sid]:
			S.seeds.erase(sid)
		return {"sid": sid, "f": roll_feno(sid)}
	var e: Dictionary = esq[j - own.size()][0]
	var l: Array = S.bandejas if esq[j - own.size()][1] else S.esquejes
	l.remove_at(l.find(e))
	return {"sid": e.sid, "f": e.f}

# con una semilla o un esqueje, tu gente saca una madre y llena la mesa de clones: toda la mesa, con su fenotipo
func plantar_mesa(i: int) -> void:
	var p = await elegir_planta("¿QUÉ PLANTAS EN LA MESA?", true)
	if p == null:
		return
	var sid: String = p.sid
	var f: Dictionary = p.f
	S.nave.m[i] = {"k": sid + ("*" if Cultivo.clase_feno(f) == "estrella" else ""), "f": f, "thc": thc_nave(sid, f), "y": f.y, "dia": S.day, "g": 0, "t": 0, "abo": 0, "p": float(D.NAVE.clon), "dn": 0, "am": 0, "ao": 0, "n": 0}
	sfx("sel")
	await say("Mesa %d: %s%s. De la madre salen los clones para toda la mesa: enraízan, crecen a 18/6 y florecen a 12/12. Se cosecha entera en unos %d días y vuelve a empezar." % [i + 1, strain(sid).n, etiq(f), dias_mesa(S.nave.m[i])])

# la carpa de las madres (1.34, carpaMadres de 11j-locales): hasta MADRES.max madres (S.nave.ma: {k, f, v: el vigor, e: los esquejes
# listos}); se mete una con una semilla o un esqueje; los esquejes se recogen aquí, al propagador (S.esquejes, con su tope)
func cuida_madres():
	for w in S.plantilla:
		if w.get("rol") == "madres":
			return w
	return null

func madre_txt(M: Dictionary) -> String:
	return strain(lot_sid(M.k)).n + etiq(M.get("f"))

func carpa_madres() -> void:
	var N: Dictionary = S.nave
	var i := 0
	while true:
		var c = cuida_madres()
		var rows := []
		for j in N.ma.size():
			var M: Dictionary = N.ma[j]
			var k := lot_sid(M.k)
			var s = strain(k)
			rows.append({"label": "Madre %d · %s" % [j + 1, s.n], "right": ("%d esq." % int(M.e)) if M.e else ("%d %%" % int(M.v)), "sw": s.c, "ic": ic_cog(k),
				"desc": "%s. Vigor %d %%%s." % [madre_txt(M), int(M.v), (" · %d esquejes listos" % int(M.e)) if M.e else ""]})
		if N.ma.size() < int(D.MADRES.max):
			rows.append({"label": "Meter una madre", "right": "%d de %d" % [N.ma.size(), int(D.MADRES.max)], "desc": "Con una semilla o un esqueje: la madre de una genética que quieras guardar. De ella salen los esquejes y los clones de las mesas."})
		rows.append({"label": "Volver", "desc": ""})
		i = await menu(rows, {"cls": "full", "title": "LAS MADRES", "title2": ("Las cuida " + c.n) if c != null else "Nadie las cuida", "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0 or i == rows.size() - 1:
			return
		if i >= N.ma.size():
			var p = await elegir_planta("¿QUÉ MADRE METES?", false)
			if p == null:
				continue
			if Datos.CAL and strain(p.sid).get("auto"):   # 1.52
				await say("La %s es autofloreciente: florece por la edad y no se queda de madre. Sus esquejes florecerían enanos." % strain(p.sid).n)
				continue
			N.ma.append({"k": p.sid + ("*" if Cultivo.clase_feno(p.f) == "estrella" else ""), "f": p.f, "v": 100, "e": 0})
			sfx("sel")
			await say("La %s%s, a la carpa de las madres: a 18/6, siempre en crecimiento." % [strain(p.sid).n, etiq(p.f)] + ((" %s se encarga." % c.n) if c != null else " Sin nadie que la cuide, se va apagando: pon a alguien de tu plantilla en las madres."))
			continue
		var M: Dictionary = N.ma[i]
		var ops := []
		if M.e:
			ops.append("Recoger %d %s" % [int(M.e), "esquejes" if M.e > 1 else "esqueje"])
		ops.append_array(["Quitarla", "Nada"])
		var oi: int = await ask("Madre %d: %s · vigor %d %%." % [i + 1, madre_txt(M), int(M.v)] + ("" if M.e else ((" %s le saca esquejes cada mañana." % c.n) if c != null else " Nadie le saca esquejes.")), ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op.begins_with("Recoger"):
			var q: int = mini(int(M.e), int(D.MADRES.propagador) - S.esquejes.size())
			if q < 1:
				await say("El propagador está lleno: %d esquejes. Planta alguno antes." % int(D.MADRES.propagador))
				continue
			for j in q:
				S.esquejes.append({"sid": lot_sid(M.k), "f": M.f, "dia": S.day})
			M.e = int(M.e) - q
			sfx("get")
			await say("%s de la %s, al propagador. Plántalos antes del %s." % [("%d esquejes" % q) if q > 1 else "Un esqueje", madre_txt(M), Datos.fd(int(S.day) + int(D.ESQUEJE_DIAS) + 1, S.day)])
			continue
		if op == "Quitarla":
			if await ask("¿Quitas la madre de %s? Se tira." % madre_txt(M), ["Quitarla", "No"]) != 0:
				continue
			N.ma.remove_at(i)
			sfx("sel")

func talk_madres():
	var w = cuida_madres()
	if w == null:
		return
	var N: Dictionary = S.nave
	var dos: bool = int(D.MADRES.esq) + (1 if w.cui >= 4 else 0) > 1
	await say("La carpa está vacía. Tráeme una madre, una semilla o un esqueje de lo que quieras guardar, y te la cuido." if N.ma.is_empty()
		else "%s, a 18/6 y bien regadas. Cada mañana les saco %s; los tienes en la carpa." % [("%d madres" % N.ma.size()) if N.ma.size() > 1 else "Una madre", "dos esquejes" if dos else "un esqueje"], w.n.to_upper())

# los focos de la mesa i (1.33, focosNave): cambiarlos por los de otro tipo (los de antes se los queda Arrieta)
func focos_nave(i: int) -> void:
	var N: Dictionary = S.nave
	var k: String = N.f[i]
	var ks := []
	var ops := []
	for x in D.FOCO_NAVE:
		if x != k:
			ks.append(x)
			ops.append("%s · %s" % [D.FOCO_NAVE[x].n, Datos.eur(D.FOCO_NAVE[x].p)])
	ops.append("Nada")
	var c: int = await ask("Mesa %d: %s. %s\n¿Los cambias? Los de ahora se los queda Arrieta." % [i + 1, D.FOCO_NAVE[k].n, D.FOCO_NAVE[k].d], ops)
	if c < 0 or c >= ks.size():
		return
	var F: Dictionary = D.FOCO_NAVE[ks[c]]
	if S.money < F.p:
		sfx("bad")
		await say("No te llega.")
		return
	S.money -= F.p
	N.f[i] = ks[c]
	sfx("coin")
	update_hud()
	await say("Arrieta cuelga los %s en la mesa %d. %s" % [F.n, i + 1, F.d] + (" Con tanto foco, la nave se calienta: hará falta más extracción." if calor_nave() > float(D.EXTR_NAVE[int(N.ex)].cap) else ""))

# las mejoras de la nave (1.33, mejorasNave): la extracción y el riego, nivel a nivel
func _fila_mejora(L: Array, k: String, t: String) -> Dictionary:
	var a: Dictionary = L[int(S.nave[k])]
	var b = L[int(S.nave[k]) + 1] if int(S.nave[k]) + 1 < L.size() else null
	return {"label": "%s: %s" % [t, a.n], "right": Datos.eur(b.p) if b else "a tope", "desc": ("Siguiente: %s. %s" % [b.n, b.d]) if b else a.d}

func mejoras_nave() -> void:
	var N: Dictionary = S.nave
	var j := 0
	while true:
		j = await menu([_fila_mejora(D.EXTR_NAVE, "ex", "Extracción"), _fila_mejora(D.RIEGO_NAVE, "rg", "Riego"), {"label": "Volver", "desc": ""}], {"cls": "full", "title": "MEJORAS DE LA NAVE", "title2": "Nave " + nivel_nave(), "desc": true, "initial": j})
		if j < 0 or j > 1:
			return
		var L: Array = D.RIEGO_NAVE if j else D.EXTR_NAVE
		var k := "rg" if j else "ex"
		if int(N[k]) + 1 >= L.size():
			continue
		var b: Dictionary = L[int(N[k]) + 1]
		if await ask("%s: %s %s, montado hoy mismo." % [b.n, b.d, Datos.eur(b.p)], ["Comprar", "No"]) != 0:
			continue
		if S.money < b.p:
			sfx("bad")
			await say("No te llega.")
			continue
		S.money -= b.p
		N[k] = int(N[k]) + 1
		sfx("coin")
		update_hud()
		montar_nave()
		await say("Arrieta y los suyos montan %s. La nave ya es una nave %s." % [b.a, nivel_nave()])

func estante_nave() -> void:
	var N: Dictionary = S.nave
	var ops := []
	if S.items.get("fert", 0):
		ops.append("Dejar MEATZA ×%d" % int(S.items.fert))
	if S.items.get("ofert", 0):
		ops.append("Dejar ORTUA BIO ×%d" % int(S.items.ofert))
	if S.map == "nave" and puertas_int("nave").size():   # 1.52.1: el escritorio está en el despacho; la nave se ordena desde la nave
		ops.append("Ordenar la nave")
	ops.append("Nada")
	var oi: int = await ask("La estantería de los abonos: MEATZA FLORACIÓN ×%s · ORTUA BIO FLORACIÓN ×%s. Cada mesa con abono gasta %suna dosis al día." % [dosis_txt(N.ab.m), dosis_txt(N.ab.o), "menos de " if int(N.rg) >= 2 else ""], ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op.begins_with("Dejar MEATZA"):
		N.ab.m += S.items.fert
		S.items.fert = 0
		sfx("sel")
	elif op.begins_with("Dejar ORTUA"):
		N.ab.o += S.items.ofert
		S.items.ofert = 0
		sfx("sel")
	elif op == "Ordenar la nave":
		await ordenar("nave")

# descolgar del secadero lo que quepa en la mochila, mesa por mesa (cada una, su lote, sin curar y con el día de su cosecha, Me.cd: 1.31)
func secadero_nave() -> void:
	var cu := colgado_nave()
	if nave_stock() - cu < 1:
		if cu >= 1:
			await say("En el secadero cuelgan %s secándose: mañana se pueden descolgar." % g_txt(cu))
		else:
			await say("El secadero está vacío. Cada mesa se cosecha entera al final de su ciclo y se seca aquí %s." % ("un día" if int(D.NAVE.seca) == 1 else "%d días" % int(D.NAVE.seca)))
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
	await say("Descuelgas %s del secadero." % g_txt(lleva) + ((" Quedan %s: no te caben." % g_txt(nave_stock() - cu)) if nave_stock() - cu >= 1 else "") + ((" Siguen colgados %s, secándose." % g_txt(cu)) if cu >= 1 else ""))

func _filas_escritorio() -> Array:
	var N: Dictionary = S.nave
	var rows := []
	for i in N.m.size():
		var Me = N.m[i]
		var w = navero_de(i)
		var ab: String = D.ABONO_MESA[int(Me.abo)] if Me else ""
		rows.append({"label": "Mesa %d · %s" % [i + 1, strain(lot_sid(Me.k)).n if Me else "vacía"], "right": D.FASE_MESA[fase_mesa(i)] if Me else "",
			"desc": ("La cuida " + w.n if w else "Nadie la cuida") + ". " + D.FOCO_NAVE[N.f[i]].n + "." + ((" %s · %s · ciclo %d · en el secadero, %s%s." % [ab.substr(0, 1).to_upper() + ab.substr(1), cosecha_txt(Me), int(Me.get("n", 0)) + 1, g_txt(Me.g), (" y %s secándose" % g_txt(Me.h.g)) if Me.get("h") != null else ""]) if Me else "")})
	rows.append({"label": "Estantería", "right": "%s + %s dosis" % [dosis_txt(N.ab.m), dosis_txt(N.ab.o)], "desc": "MEATZA FLORACIÓN y ORTUA BIO FLORACIÓN: %suna dosis al día por mesa con abono." % ("menos de " if int(N.rg) >= 2 else "")})
	var E: Dictionary = D.EXTR_NAVE[int(N.ex)]
	var so := sofoco_nave()
	rows.append({"label": "Clima", "right": "%s de %s" % [n(calor_nave()), n(E.cap)], "desc": "El calor de los focos encendidos y lo que saca la extracción (%s)." % E.n + ((" Hace demasiado calor: las mesas dan un %d %% menos." % Datos.jsround((1 - so) * 100)) if so < 1 else "")})
	if S.map == "nave":   # 1.52.1 (lo pidió el usuario): solo con el escritorio en la nave; con el despacho, desde la estantería o el riego de la nave
		rows.append({"label": "Ordenar la nave", "right": "", "desc": "Mover las mesas y el tanque del riego: la manguera va del tanque a cada mesa por el suelo libre. Pulsa A."})   # 1.37 (12d-orden)
	rows.append({"label": "La gente", "right": "%d aquí" % de_la_nave().size(), "desc": "Quién cuida cada mesa y las madres: cambiarlos de mesa, una prima o un curso. Pulsa A."})   # 1.34
	rows.append({"label": "Mejoras", "right": "Nave " + nivel_nave(), "desc": "Extracción: %s. Riego: %s. Pulsa A para mejorarlas." % [E.n, D.RIEGO_NAVE[int(N.rg)].n]})
	return rows

func escritorio_nave() -> void:
	var i := 0
	while true:
		var rows := _filas_escritorio()
		i = await menu(rows, {"cls": "full", "title": "LA NAVE", "title2": "%s al día" % Datos.eur(D.NAVE.dia), "desc": true, "initial": i})
		var l: String = rows[i].label if i >= 0 else ""
		if l == "Mejoras":
			await mejoras_nave()
		elif l == "La gente":
			await gente_nave()
		elif l == "Ordenar la nave":
			await ordenar("nave")
		if i < 0:
			break

# la gente de la nave (1.34, genteNave): cada uno con su ficha y su sitio; a los de las mesas, cambiarlos de mesa (con el que la tenga,
# se cambian); a todos, una prima o un curso
func gente_nave() -> void:
	var i := 0
	while true:
		var W := de_la_nave()
		W.sort_custom(func(a, b):
			var ma := 1 if a.rol == "madres" else 0
			var mb := 1 if b.rol == "madres" else 0
			if ma != mb:
				return ma < mb
			return ma == 0 and int(a.mesa) < int(b.mesa))
		if W.is_empty():
			await say("En la nave no trabaja nadie. Pon a tu gente desde el móvil: MÓVIL → PLANTILLA.")
			return
		var rows := []
		for w in W:
			rows.append({"label": w.n, "right": "madres" if w.rol == "madres" else "mesa %d" % (int(w.mesa) + 1), "desc": ficha_gente(w) + ". " + rol_desc(w)})
		rows.append({"label": "Volver", "desc": ""})
		i = await menu(rows, {"cls": "full", "title": "LA GENTE DE LA NAVE", "title2": "%d trabajando" % W.size(), "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0 or i >= W.size():
			return
		var w: Dictionary = W[i]
		var ops := []
		if w.rol == "nave":
			ops.append("Cambiar de mesa")
		ops.append_array(["Prima · " + Datos.eur(D.MANDO.prima), "Curso · " + Datos.eur(D.MANDO.curso), "Nada"])
		var oi: int = await ask("%s · %s · %s" % [w.n, ficha_gente(w), "las madres" if w.rol == "madres" else "la mesa %d" % (int(w.mesa) + 1)], ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "Cambiar de mesa":
			var ms := []
			for j in int(D.NAVE.max):
				if j != int(w.mesa):
					ms.append(j)
			var lb := []
			for j in ms:
				var o = navero_de(j)
				lb.append("Mesa %d" % (j + 1) + ((" · con " + o.n) if o != null else ""))
			lb.append("Nada")
			var c: int = await ask("¿A qué mesa pasa %s?" % w.n, lb)
			if c < 0 or c >= ms.size():
				continue
			var o = navero_de(ms[c])
			if o != null:
				o.mesa = w.mesa
			w.mesa = ms[c]
			sfx("sel")
			await say("%s pasa a la mesa %d" % [w.n, int(w.mesa) + 1] + ((" y %s, a la %d." % [o.n, int(o.mesa) + 1]) if o != null else "."))
		elif op.begins_with("Prima"):
			await prima(w)
		elif op.begins_with("Curso"):
			await curso(w)

func talk_navero(i: int):
	var w = navero_de(i)
	if not w:
		return
	var Me = S.nave.m[i] if S.get("nave") != null else null
	var f := fase_mesa(i)
	var t: String
	if not Me:
		t = "Mi mesa está vacía. Plántame algo y la saco adelante."
	else:
		t = "La %s va bien: %s, %s. Cuando acaba la flor la corto entera, la cuelgo en el secadero y vuelvo a empezar con los esquejes que saqué antes de pasarla a 12/12." % [strain(lot_sid(Me.k)).n, D.FASE_MESA[f], cosecha_txt(Me)] + (" Se ha acabado el abono de la estantería." if Me.abo and float(S.nave.ab["m" if Me.abo == 1 else "o"]) < float(D.RIEGO_NAVE[int(S.nave.rg)].dosis) else "") \
			+ (" Y aquí dentro hace un calor que no veas: hace falta más extracción." if sofoco_nave() < 1 else "")
	await say(t, String(w.n).to_upper())

# ---------- GAUA ----------
# la noche empieza a las 23:00: lo de después de medianoche es de la noche del día anterior (S.noche: lo pagado y hecho esa noche)
func noche_id() -> int:
	return int(S.day) if S.min >= D.DISCO.abre else int(S.day) - 1

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
	if Datos.CAL:   # 1.47: el reservado, arriba
		await subir_vip()

# (lo pidió el usuario): el reservado, arriba; desde la cristalera del suelo se ve la pista de abajo
func subir_vip() -> void:
	var C: Dictionary = D.DISCO_CAL
	await warp({"to": "disco-vip", "x": int(C.sube[0]), "y": int(C.sube[1]), "dir": "down"})

func bajar_vip() -> void:
	var C: Dictionary = D.DISCO_CAL
	await warp({"to": "disco", "x": int(C.baja[0]), "y": int(C.baja[1]), "dir": "down"})

func talk_vip(i: int) -> void:
	if not disco_abierta():
		await echar_disco()
		return
	await say(D.DISCO_CAL.vip[(i + S.day) % D.DISCO_CAL.vip.size()], "GENTE")

func talk_baila(i: int):
	await say(D.BAILA[i], "GENTE")

# ---------- LA ASOCIACIÓN (1.32, 11j-locales): la de la tía Maite, en el barrio alto (CLUBS.rv) ----------
# la segunda vez que entras (otro día), Delroy; presentarte (la asamblea) o refundarla; de presidente, el dispensario (ASO, DELROY)
# ---------- los mercados (1.45, lo pidió el usuario: «en el club se tiene que poder tanto comprar como vender extracciones y
# diferentes tipos de hierba, no solo una… a todos los mercados»; con Datos.CAL) ----------
# MERCADO[tipo] (club, mayor): cada mercado (id: club_<k>, inaki, lonja) saca cada día n cogollos y nx extracciones de su lista (pool),
# con lo que tiene de cada uno (st/stx gramos), y compra varios lotes al día hasta su tope (en gramos de flor: S.mer_v[id])
func tipo_mer(id: String) -> String:
	return "club" if id.begins_with("club_") else "mayor"

func pool_mayor() -> Array:
	var l := ["ria"]
	for b in D.BANCO:
		if int(b[2]) <= int(S.ch):
			l.append(b[0])
	return l

func resto_mer(id: String, tope: float) -> float:
	var v = S.get("mer_v", {}).get(id) if S.get("mer_v") is Dictionary else null
	return tope - (float(v.g) if v is Dictionary and int(v.d) == int(S.day) else 0.0)

func suma_mer(id: String, g: float) -> void:
	if not (S.get("mer_v") is Dictionary):
		S.mer_v = {}
	var v = S.mer_v.get(id)
	S.mer_v[id] = {"d": S.day, "g": (float(v.g) if v is Dictionary and int(v.d) == int(S.day) else 0.0) + g}

func mercado_lista(id: String, pool: Array) -> Array:
	if not (S.get("mer") is Dictionary):
		S.mer = {}
	var M = S.mer.get(id)
	if M is Dictionary and int(M.d) == int(S.day):
		return M.l
	var T: Dictionary = D.MERCADO[tipo_mer(id)]
	var h: int = absi(hash("%s|%d" % [id, int(S.day)]))
	var l := []
	var p := pool.duplicate()
	for i in int(T.n):
		if p.is_empty():
			break
		var sid: String = p[(h + i * 7919) % p.size()]
		p.erase(sid)
		l.append({"k": sid, "x": "", "g": int(T.st[0]) + (h / (i + 3)) % (int(T.st[1]) - int(T.st[0]) + 1), "thc": float(strain(sid).thc)})
	for i in int(T.nx):
		var sid: String = pool[(h / 7 + i * 104729) % pool.size()]
		var xt: String = D.MERCADO.x[(h / 13 + i * 3) % D.MERCADO.x.size()]
		var E: Dictionary = D.EXTR[xt]
		l.append({"k": sid, "x": xt, "g": int(T.stx[0]) + (h / (i + 5)) % (int(T.stx[1]) - int(T.stx[0]) + 1), "thc": minf(float(E.tope), Datos.jsround(float(strain(sid).thc) * float(E.thc) * 10) / 10.0)})
	S.mer[id] = {"d": S.day, "l": l}
	return l

func precio_mer(id: String, q: Dictionary) -> float:
	var T: Dictionary = D.MERCADO[tipo_mer(id)]
	var e: float = (precio_rosin(q.thc) * float(D.EXTR[q.x].px) * float(T.fx)) if q.x != "" else ((precio_calle(q.thc) if tipo_mer(id) == "club" else precio_mayor(q.thc)) * float(T.f))
	return Datos.jsround(e * 100) / 100.0

func nombre_mer(q: Dictionary) -> String:
	return (D.EXTR[q.x].n + " de " + strain(q.k).n) if q.x != "" else strain(q.k).n

func comprar_mercado(id: String, N: String, pool: Array) -> void:
	var T: Dictionary = D.MERCADO[tipo_mer(id)]
	var l: Array = mercado_lista(id, pool).filter(func(q): return int(q.g) >= int((T.gx if q.x != "" else T.g)[0]))
	if l.is_empty():
		await say("Hoy ya está todo repartido. Mañana entra más.", N)
		return
	var it := l.map(func(q): return {"label": nombre_mer(q), "right": "%d g · %s %% · %s €/g" % [int(q.g), Datos.pct(q.thc), _dos(precio_mer(id, q))], "sw": "#d89a18" if q.x != "" else strain(q.k).c, "ic": ic_cog(q.k),
		"desc": "%s: %d g a %s %% de THC, a %s el gramo." % [nombre_mer(q), int(q.g), Datos.pct(q.thc), _dos(precio_mer(id, q)) + " €"]})
	it.append({"label": "Nada", "desc": "No comprar nada hoy."})
	# A lo ancho, con el nombre entero (en la columna de la derecha se cortaba: «Beldi», «Zam»…)
	var i: int = await menu(it, {"cls": "full", "title": "Hoy tenemos", "desc": true} if Datos.CAL else {"cls": "right", "title": "Hoy tenemos"})
	if i < 0 or i >= l.size():
		return
	var q: Dictionary = l[i]
	var pg := precio_mer(id, q)
	var ops := []
	for g in (T.gx if q.x != "" else T.g):
		if g <= int(q.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(Datos.jsround(g * pg))])
	o.append("Nada")
	var j: int = await ask("%s, al %s %% de THC. ¿Cuánto te llevas?" % [nombre_mer(q), Datos.pct(q.thc)], o, N)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	var e := Datos.jsround(g * pg)
	if S.money < e:
		sfx("bad")
		await say("Sin dinero no hay trato.", N)
		return
	if libre_mochila() < g:
		await say("No te cabe en la bolsa.", N)
		return
	S.money -= e
	q.g = int(q.g) - g
	if q.x != "":
		add_rosin(q.k if q.x == "rosin" else q.k + "~" + q.x, g, q.thc)
		discover(q.k)
	else:
		add_buds(q.k, g, q.thc, S.buds, 1)
	confia(id.substr(5) if id.begins_with("club_") else id, 1)
	update_hud()
	sfx("coin")
	toast("Comprado: %d g de %s" % [g, nombre_mer(q)], 1400)

# el almacén del club (1.45, de presidente): lo que dejas en sus estanterías (S.aso.al: buds y rosin, hasta MERCADO.alm.g de flor)
# lo retiran los socios del dispensario cada mañana (aso_dia), MERCADO.alm.dia g de flor al día, a precio de dispensario
func alm_club() -> Dictionary:
	var A := aso()
	if not (A.get("al") is Dictionary):
		A.al = {"buds": {}, "rosin": {}, "tot": 0}
	return A.al

func alm_g() -> float:
	var al := alm_club()
	var t := 0.0
	for k in al.buds:
		t += float(al.buds[k].g)
	for k in al.rosin:
		t += float(al.rosin[k].g) / D.ROSIN.rend
	return t

func almacen_club() -> void:
	var N: String = D.DELROY.n
	if not aso().pres:
		await say("El almacén del club, con llave. La tiene el presidente.")
		return
	while true:
		var al := alm_club()
		var ops := ["Guardar", "Sacar", "Nada"]
		var c: int = await ask("EL ALMACÉN DEL CLUB · %s de %s ocupados. Lo de aquí lo retiran los socios del dispensario, %d g al día; en total, %s." % [g_txt(alm_g()), g_txt(D.MERCADO.alm.g), int(D.MERCADO.alm.dia), Datos.eur(int(al.tot))], ops)
		if c == 0:
			var lots := lotes_venta(1, 1)
			if lots.is_empty():
				await say("No llevas nada encima.")
				continue
			var it := lots.map(venta_item)
			it.append({"label": "Nada"})
			var i: int = await menu(it, {"cls": "right", "title": "¿Qué guardas?"})
			if i < 0 or i >= lots.size():
				continue
			var lt: Array = lots[i]
			var x := es_extr(lt)
			var b: Dictionary = lt[1]
			var cabe: float = (float(D.MERCADO.alm.g) - alm_g()) * (D.ROSIN.rend if x else 1.0)
			var g: float = minf(float(b.g), floorf(cabe * 10) / 10.0)
			if g < .1:
				await say("Las estanterías están llenas.")
				continue
			var L: Dictionary = al.rosin if x else al.buds
			var k: String = lt[0]
			if L.has(k):
				L[k].thc = (float(L[k].thc) * float(L[k].g) + float(b.thc) * g) / (float(L[k].g) + g)
				L[k].g = float(L[k].g) + g
			else:
				L[k] = {"g": g, "thc": float(b.thc), "q": calidad(b)}
			usa_lote(lt, g)
			sfx("sel")
			toast("Al almacén: %s" % g_txt(g), 1200)
		elif c == 1:
			var it := []
			var ks := []
			for k in al.buds:
				ks.append([k, false])
				it.append({"label": lot_nombre(k), "right": g_txt(al.buds[k].g)})
			for k in al.rosin:
				ks.append([k, true])
				it.append({"label": extr_nombre(k), "right": g_txt(al.rosin[k].g)})
			if ks.is_empty():
				await say("El almacén está vacío.")
				continue
			it.append({"label": "Nada"})
			var i: int = await menu(it, {"cls": "right", "title": "¿Qué sacas?"})
			if i < 0 or i >= ks.size():
				continue
			var k: String = ks[i][0]
			var x: bool = ks[i][1]
			var b: Dictionary = (al.rosin if x else al.buds)[k]
			var g: float = minf(float(b.g), floorf(libre_mochila()))
			if g < .1:
				await say("No te cabe en la bolsa.")
				continue
			if x:
				add_rosin(k, g, b.thc)
			else:
				add_buds(k, g, b.thc)
			b.g = float(b.g) - g
			if b.g < .1:
				(al.rosin if x else al.buds).erase(k)
			sfx("sel")
			toast("Sacado: %s" % g_txt(g), 1200)
		else:
			return

func almacen_dia() -> void:
	var A := aso()
	if not A.pres or not (A.get("al") is Dictionary):
		return
	var al := alm_club()
	var r: float = float(D.MERCADO.alm.dia)
	var e := 0.0
	for x in [false, true]:
		var L: Dictionary = al.rosin if x else al.buds
		for k in L.keys():
			if r <= 0:
				break
			var b: Dictionary = L[k]
			var g: float = minf(float(b.g), r * (D.ROSIN.rend if x else 1.0))
			var pg: float = (precio_extr(k, b.thc, "club") if x else precio_club(b.thc)) * float(b.get("q", 1)) * float(D.ASO.f)
			e += g * pg
			r -= g / D.ROSIN.rend if x else g
			b.g = float(b.g) - g
			if b.g < .1:
				L.erase(k)
	if e > 0:
		var ee := Datos.jsround(e)
		al.tot = int(al.tot) + ee
		S.money += ee
		S.sales += ee
		queue("historia", check_story)

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
		if await ask("La asamblea es el %s, por la mañana. Habla con la gente del barrio: cada amigo trae votos. O la refundas ya, por %s." % [Datos.fd(int(A.asam), S.day), Datos.eur(O.refunda)], ["Refundarla", "Nada"], N) != 0:
			return
	else:
		var c: int = await ask("Hacen falta %d votos de %d. Hoy tendrías %d. O pagas %s de deudas y registro y la refundas tú." % [int(O.mayoria), int(O.votos), votos_aso(), Datos.eur(O.refunda)], ["Presentarme", "Refundarla", "Nada"], N)
		if c == 0:
			if S.day < int(A.otra):
				await say("Hasta el %s no hay otra asamblea. Gánate al barrio mientras." % Datos.fd(int(A.otra), S.day), N)
				return
			A.asam = int(S.day) + int(O.dias)
			sfx("sel")
			await say("Apuntado. La asamblea, el %s. %s también se presenta." % [Datos.fd(int(A.asam), S.day), O.rival], N)
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
		await say("En el dispensario quedan %s de %s, a %s € el gramo. Llevas %s." % [g_txt(L.g), extr_nombre(L.k, true) if L.get("x") else lot_nombre(L.k), _dos(L.pg), Datos.eur(L.tot)], N)
		return
	var VX: Dictionary = D.VENTA_EXTR
	var lots := lotes_venta(O.g[0], VX.club_g[0])
	if lots.is_empty():
		await say("Déjame %d g o más y los socios lo retiran, %d g al día. El dinero, a tu buzón." % [int(O.g[0]), int(O.dia)], N)
		return
	var it := lots.map(venta_item)
	it.append({"label": "Nada"})
	var i: int = await menu(it, {"cls": "right", "title": "¿Qué lote?"})
	if i < 0 or i >= lots.size():
		return
	var l: Array = lots[i]
	var x := es_extr(l)
	var k: String = l[0]
	var b: Dictionary = l[1]
	var pg := Datos.jsround((precio_extr(k, b.thc, "club") if x else precio_club(b.thc)) * calidad(b) * float(O.f) * 100) / 100.0
	var ops := []
	for g in (VX.club_g if x else O.g):
		if g <= floor(b.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(g * pg)])
	o.append("Nada")
	var j: int = await ask("%s a %s € el gramo para los socios. ¿Cuánto dejas?" % [venta_nombre(l), _dos(pg)], o, N)
	if j < 0 or j >= ops.size():
		return
	usa_lote(l, ops[j])
	A.lote = {"k": k, "g": ops[j], "pg": pg, "tot": 0}
	if x:   # 1.43.7: de una extracción retiran VENTA_EXTR.dia de lo de la flor
		A.lote.x = true
	sfx("sel")
	await say("Al dispensario. Cada mañana, %s para los socios." % g_txt(O.dia * (VX.dia if x else 1.0)), N)

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
		var t: String = ("¡%d votos de %d! Eres el presidente de la asociación, sobrino. Como tu tía." % [v, int(O.votos)]) if gana else ("%d votos de %d: gana %s. Gánate al barrio y preséntate otra vez desde el %s." % [v, int(O.votos), O.rival, Datos.fd(int(A.otra), S.day)])
		queue("aso", func(): await talk("SMS · DELROY", [t]))
	if Datos.CAL:
		almacen_dia()   # 1.45: lo del almacén del club
	var L = A.lote
	if not A.pres or not (L is Dictionary):
		return
	var g = min(L.g, O.dia * (D.VENTA_EXTR.dia if L.get("x") else 1.0))
	var e := Datos.jsround(g * L.pg)
	L.g -= g
	L.tot += e
	S.money += e
	S.sales += e
	queue("historia", check_story)
	if L.g < 1:
		A.lote = null
		queue("asoLote", func(): await talk("SMS · DELROY", ["Se acabó lo del dispensario: %s en total, en tu buzón." % Datos.eur(L.tot)]))
