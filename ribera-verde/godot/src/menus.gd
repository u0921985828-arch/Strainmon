# F8 (de trama.gd): el menú START y la ficha de la variedad.
extends "res://src/trama.gd"

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
		var it := [{"label": K("CANNADEX") if Datos.CAL else K("GENOTECA"), "right": "%d/%d" % [desc, D.DEX.size()], "ic": icono("cogollo")}, {"label": K("MOCHILA"), "right": _kg(int(floor(peso_encima()))), "ic": icono("bolsa")},
			{"label": K("MÓVIL"), "right": T("{n} SMS", {"n": ns}) if ns else null, "ic": icono("movil")}, {"label": K("PLANTAS"), "right": str(vivas), "ic": icono("maceta")},
			{"label": K("OBJETIVO"), "right": T("cap. {n}", {"n": int(S.ch)}), "ic": icono("trofeo")}, {"label": K("GUARDAR"), "ic": icono("guardar")},
			{"label": K("OPCIONES"), "ic": icono("altavoz")}, {"label": K("SALIR"), "ic": icono("salir")}]
		if Datos.PLAY:   # U4: el registro de diálogo
			it.insert(5, {"label": K("REGISTRO"), "right": str(registro.size()), "ic": icono("movil")})
		if Datos.PLAY and S.flags.get("demo4"):   # U11: la demo, acabada
			it.insert(0, {"label": K("JUEGO COMPLETO"), "right": T("cap. {n}", {"n": int(D.COMPLETO.ch)}), "ic": icono("trofeo")})
		i = await menu(it, {"cls": "start", "initial": i, "startCloses": true, "title": "%s · %s" % [Datos.fd_hud(S.day), reloj_txt()], "title2": Datos.eur(S.money)})
		if i < 0 or it[i].label == "SALIR":
			return
		if it[i].label == "JUEGO COMPLETO":
			if await demo_menu():
				await cap4_sigue()
				return
			continue
		if it[i].label == "REGISTRO":
			await leer(K("REGISTRO"), "\n\n".join(PackedStringArray(_registro_inv())) if registro.size() else K("Todavía no has hablado con nadie."))
			continue
		var k: int = ["CANNADEX" if Datos.CAL else "GENOTECA", "MOCHILA", "MÓVIL", "PLANTAS", "OBJETIVO", "GUARDAR", "OPCIONES"].find(it[i].label)   # i18n-no
		var i0 := i
		i = k
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
			await say(K("Partida guardada.") if save() else K("No se ha podido guardar la partida."))
		elif i == 6:
			await opciones()
			if get("relanza"):   # E10: la partida importada se abre al cerrar el menú
				return
		i = i0

# U4: el registro, de lo último a lo primero
func _registro_inv() -> Array:
	var r := registro.duplicate()
	r.reverse()
	return r

func exportar() -> void:
	exportado = JSON.stringify(S, "", false, true)
	DisplayServer.clipboard_set(exportado)
	await say(K("Partida copiada al portapapeles. Pégala en una nota o en un correo para guardarla."))

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
	var rr := (" × " if o.ord else " + ").join(PackedStringArray(o.k.map(func(k): return D.STRAINS[k].n)))
	return T("{r}, en ese orden", {"r": rr}) if o.ord else rr

# REGALO (12-menus, por datos.json): las semillas que se consiguen sin comprarlas

func donde_semilla(k: String) -> String:
	var l := []
	if D.REGALO.has(k):
		l.append(I18n.v(D.REGALO[k]))
	for it in D.SHOP:
		if it.get("sid") == k:
			l.append(T("en el growshop de Kiko desde el cap. {n}", {"n": n(it.ch)}))
			break
	for b in D.BANCO:
		if b[0] == k:
			l.append(T("en el banco de semillas del PC desde el cap. {n}", {"n": n(b[2])}))
			break
	if D.MISIONES.any(func(m): return m.get("s") is Dictionary and m.s.has(k)):
		l.append(T("de premio en una misión"))
	if recetas().has(k):
		l.append(T("de su receta"))
	return T("Semillas: {l}.", {"l": "; ".join(PackedStringArray(l))})

# el diario de la tía Maite (1.16): su nota de cada variedad (DIARIO, de 12-menus; 1.25: todas)
func diario_txt(t: String) -> String:
	return ("«%s»\n" % I18n.v(D.DIARIO[t])) if D.DIARIO.has(t) else ""

# Todas las de la Genoteca, en su orden; las de receta abren lo que entra; las demás dicen dónde están sus semillas
func tipo_diario(t: String, R: Dictionary) -> String:
	if R.has(t):
		return T("{n} recetas", {"n": R[t].size()}) if R[t].size() > 1 else K("receta")
	return K("tienda") if D.SHOP.any(func(it): return it.get("sid") == t) else K("landrace")

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
				"desc": diario_txt(t) + (("\n" + T("o") + " ").join(PackedStringArray(R[t].map(func(o): return receta_txt(o)))) if R.has(t) else donde_semilla(t))})
		if S.flags.get("pagina"):   # la página que falta (1.17)
			items.append({"label": "  " + T("La última página"), "desc": "«%s»" % I18n.v(D.PAGINA)})
		items.append({"label": K("Volver"), "desc": ""})
		i = await menu(items, {"cls": "full", "title": K("DIARIO DE LA TÍA MAITE"), "title2": "%d/%d" % [nd, ts.size()], "desc": true, "initial": i})
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
		it2.append({"label": K("Volver"), "desc": ""})
		await menu(it2, {"cls": "full", "title": D.STRAINS[t].n.to_upper(), "title2": K("lo que entra"), "desc": true})

# cambiar el nombre a una variedad propia (1.11): sin repetir el de otra
func renombrar_variedad(k: String) -> void:
	var C: Dictionary = S.custom[k]
	var v = await pedir_texto(T("Nuevo nombre de la variedad"), C.n, Datos.NOM_MAX)
	if v == null or v == "" or v == C.n:
		return
	var l: String = v.to_lower()
	for d in D.DEX:
		if D.STRAINS[d].n.to_lower() == l:
			await say(K("Ya hay una variedad con ese nombre."))
			return
	for q in S.custom:
		if not is_same(S.custom[q], C) and S.custom[q].n.to_lower() == l:
			await say(K("Ya hay una variedad con ese nombre."))
			return
	var a: String = C.n
	C.n = v
	sfx("sel")
	await say(T("La {a} pasa a llamarse {v}.", {"a": a, "v": v}))

func genoteca():
	if Datos.CAL:
		await cannadex()
		return
	var i := 0
	while true:
		i = await menu_genoteca(i)
		if i < 0:
			break

# La CannaDex (con Datos.CAL; lo pidió el usuario: «juntarlo todo… catalogarlo por zonas o por los cruces»): la Genoteca, el diario
# de la tía Maite y las familias en un solo sitio. Cada variedad, con lo que se sabe de ella: su ficha (descubierta), la nota de la
# tía (con el diario), las recetas o dónde están sus semillas, su familia y la cata. Por familias, por generación, todas y tus cruces.
func dex_ver(k: String) -> bool:
	return S.disc.get(k) or S.flags.get("diario")

func dex_familia(k: String) -> String:
	for f in D.FAMILIAS:
		if D.FAMILIAS[f].s.has(k):
			return f
	return ""

func dex_cosechada(k: String) -> bool:
	return S.get("cult") is Dictionary and S.cult.has(k)

func dex_desc(k: String, R: Dictionary, todo := false) -> String:
	if not dex_ver(k):
		return K("Sin descubrir.")
	var s: Dictionary = D.STRAINS[k]
	var l := []
	if S.disc.get(k):
		l.append(strain_line(k))
		if todo and s.get("h"):
			l.append(s.h)
	var nota := diario_txt(k).strip_edges()
	if S.flags.get("diario") and nota != "":
		l.append(nota)
	l.append(T("Receta: {r}.", {"r": (" " + T("o") + " ").join(PackedStringArray(R[k].map(func(o): return receta_txt(o))))}) if R.has(k) else donde_semilla(k))
	var f := dex_familia(k)
	if f != "":
		l.append(T("Familia: {f} · {c}", {"f": I18n.v(String(D.FAMILIAS[f].n)), "c": K("cosechada") if dex_cosechada(k) else K("sin cosechar")}))
	if S.catas.has(k):
		l.append(T("Cata: {c}", {"c": S.catas[k]}))
	return "\n".join(PackedStringArray(l))

func dex_fila(k: String, R: Dictionary) -> Dictionary:
	var nn := "%02d" % (D.DEX.find(k) + 1)
	var s: Dictionary = D.STRAINS[k]
	if not dex_ver(k):
		return {"label": nn + " ??????", "desc": K("Sin descubrir."), "k": k}
	var it := {"label": "%s %s%s" % [nn, s.n, " ✓" if dex_cosechada(k) else ""], "right": (Datos.pct(s.thc) + "%") if S.disc.get(k) else tipo_diario(k, R), "ic": ic_cog(k), "k": k, "desc": dex_desc(k, R)}
	if S.disc.get(k):
		it.sw = s.c
	return it

# los grupos por generación: landraces, 1.ª a 4.ª, autoflorecientes y las demás
func dex_generaciones() -> Array:
	var G := [[K("Landraces"), []], [K("1.ª generación"), []], [K("2.ª generación"), []], [K("3.ª generación"), []], [K("4.ª generación"), []], [K("Autoflorecientes"), []], [K("Otras"), []]]
	for k in D.DEX:
		var s: Dictionary = D.STRAINS[k]
		var g := 6
		if s.get("auto"):
			g = 5
		elif s.get("tipo") == "landrace":
			g = 0
		elif s.get("gen"):
			g = clampi(int(s.gen), 1, 4)
		G[g][1].append(k)
	return G.filter(func(x): return x[1].size() > 0)

func dex_cuenta(ks: Array) -> String:
	return "%d/%d" % [ks.filter(func(k): return S.disc.get(k)).size(), ks.size()]

func cannadex() -> void:
	var i := 0
	while true:
		var cust := []
		for k in S.custom:
			if S.disc.get(k):
				cust.append(k)
		var fc: Array = fam_cuenta()
		var items := [{"label": K("POR FAMILIAS"), "right": "%d/%d" % [fc[0], fc[1]], "ic": icono("cogollo"), "q": "fam",
				"desc": K("Las variedades por su zona de origen y por sus líneas de cruces. Cosecha todas las de una familia y te quedas su bono para siempre.")},
			{"label": K("POR GENERACIÓN"), "right": dex_cuenta(D.DEX), "ic": icono("cogollo"), "q": "gen", "desc": K("Las landraces y los cruces de 1.ª a 4.ª generación, las autoflorecientes y las demás.")},
			{"label": K("TODAS"), "right": dex_cuenta(D.DEX), "ic": icono("cogollo"), "q": "todas", "desc": K("Todas las variedades, en su orden.")}]
		if cust.size():
			items.append({"label": K("TUS CRUCES"), "right": str(cust.size()), "ic": icono("cogollo"), "q": "cust", "desc": K("Las variedades que has sacado tú en la mesa de cruces.")})
		if S.get("album") is Array and S.album.size():   # ESTUDIO, tanda 2: el cuaderno de fenotipos
			items.append({"label": K("CUADERNO DE FENOTIPOS"), "right": str(S.album.size()), "ic": icono("guardar"), "q": "album", "desc": K("Cada planta rara que has cosechado, con sus rasgos, el día y el sitio, y lo que lleva ya su línea.")})
		if S.flags.get("pagina"):   # la página que falta (1.17)
			items.append({"label": K("LA ÚLTIMA PÁGINA"), "ic": icono("guardar"), "q": "pagina", "desc": "«%s»" % I18n.v(D.PAGINA)})
		items.append({"label": K("Volver"), "desc": ""})
		var t2 := T("{a}/{b} · {c} propias", {"a": D.DEX.filter(func(k): return S.disc.get(k)).size(), "b": D.DEX.size(), "c": cust.size()})
		i = await menu(items, {"cls": "full", "title": K("CANNADEX"), "title2": t2, "desc": true, "initial": i})
		if i < 0 or i >= items.size() or not items[i].has("q"):
			return
		match items[i].q:
			"fam":
				await dex_familias()
			"gen":
				var G := dex_generaciones()
				var j := 0
				while true:
					var it2 := []
					for g in G:
						it2.append({"label": g[0], "right": dex_cuenta(g[1]), "desc": ", ".join(PackedStringArray(g[1].map(func(k): return D.STRAINS[k].n if dex_ver(k) else "??????")))})
					it2.append({"label": K("Volver"), "desc": ""})
					j = await menu(it2, {"cls": "full", "title": K("POR GENERACIÓN"), "title2": dex_cuenta(D.DEX), "desc": true, "initial": j})
					if j < 0 or j >= G.size():
						break
					await dex_lista(G[j][1], String(G[j][0]).to_upper())
			"todas":
				await dex_lista(D.DEX, K("TODAS"))
			"cust":
				await dex_cruces(cust)
			"pagina":
				await leer(K("LA ÚLTIMA PÁGINA"), "«%s»" % I18n.v(D.PAGINA))
			"album":
				await cuaderno_fenos()

# ESTUDIO, tanda 2: el cuaderno de fenotipos, de la última a la primera: la planta, sus rasgos, cuándo y dónde, y cómo va su línea
func cuaderno_fenos() -> void:
	var j := 0
	while true:
		var it := []
		var l: Array = S.album.duplicate()
		l.reverse()
		for a in l:
			var r := []
			for k in a.get("ra", []):
				r.append(I18n.v(D.RAREZAS.r[k].n))
			if String(a.get("sh", "")) != "":
				r.append(K("rara (no se hereda)"))
			var li := []
			for k in S.get("ra", {}).get(a.sid, {}):
				li.append(T("{n} al {p} %", {"n": I18n.v(D.RAREZAS.r[k].n), "p": roundi(float(D.RAREZAS.niv[int(S.ra[a.sid][k])]) * 100)}))
			it.append({"label": strain(a.sid).n + nom_planta({"id": a.id}), "right": Datos.fd_corto(int(a.d)), "ic": ic_cog(a.sid),
				"desc": T("{r} · {l}", {"r": y_lista(r), "l": lugar_album(String(a.m))}) + "\n" + (T("Su línea: {x}.", {"x": y_lista(li)}) if li.size() else K("Su línea no lleva ningún rasgo: cosecha semillas de una planta que lo saque."))})
		it.append({"label": K("Volver"), "desc": ""})
		j = await menu(it, {"cls": "full", "title": K("CUADERNO DE FENOTIPOS"), "title2": str(S.album.size()), "desc": true, "initial": j})
		if j < 0 or j >= l.size():
			return

func lugar_album(m: String) -> String:
	if m == "home":   # i18n-no
		return K("en el piso")
	if m.begins_with("nave"):
		return K("en la nave")
	if m == "huerta":   # i18n-no
		return K("en la huerta")
	if m.begins_with("cult-"):
		return K("en la sala de KAIA")
	return T("en {m}", {"m": nombre_lugar(m)})

func dex_familias() -> void:
	var i := 0
	var ks: Array = D.FAMILIAS.keys()
	while true:
		var items := []
		for k in ks:
			var F: Dictionary = D.FAMILIAS[k]
			var c: int = F.s.filter(func(sid): return dex_cosechada(sid)).size()
			var ok: bool = c == F.s.size()
			items.append({"label": ("★ " if ok else "") + I18n.v(String(F.n)), "right": "%d/%d" % [c, F.s.size()],
				"desc": fam_bono_txt(F) + (T(" (conseguido)") if ok else "") + "\n" + ", ".join(PackedStringArray(F.s.map(func(sid): return (("✓ " if dex_cosechada(sid) else "") + strain(sid).n) if dex_ver(sid) else "??????")))})
		items.append({"label": K("Volver"), "desc": K("Cada variedad cuenta al cosecharla, en casa o en la nave.")})
		var fc := fam_cuenta()
		i = await menu(items, {"cls": "full", "title": K("POR FAMILIAS"), "title2": T("{a}/{b} · prestigio {p} · {t} trofeos", {"a": fc[0], "b": fc[1], "p": int(S.get("prest", 0)), "t": cup_trofeos().size()}), "desc": true, "initial": i})
		if i < 0 or i >= ks.size():
			return
		var F: Dictionary = D.FAMILIAS[ks[i]]
		await dex_lista(F.s.filter(func(sid): return D.STRAINS.has(sid)), I18n.v(String(F.n)).to_upper(), fam_bono_txt(F))

# una lista de variedades: A abre la hoja (descubierta), lo que entra (con receta) o todo lo apuntado
func dex_lista(ks: Array, titulo: String, t2 := "") -> void:
	var R := recetas()
	var i := 0
	while true:
		var items := []
		for k in ks:
			items.append(dex_fila(k, R))
		items.append({"label": K("Volver"), "desc": ""})
		i = await menu(items, {"cls": "full", "title": titulo, "title2": t2 if t2 != "" else dex_cuenta(ks), "desc": true, "initial": i})
		if i < 0 or i >= ks.size():
			return
		var k: String = ks[i]
		if not dex_ver(k):
			continue
		var op := []
		if S.disc.get(k):
			op.append(K("Ver la hoja"))
		if R.has(k):
			op.append(K("Lo que entra"))
		op.append(K("Leerlo todo"))
		var c: String = op[0] if op.size() == 1 else op[await ask(D.STRAINS[k].n, op)]
		if c == "Ver la hoja":
			var vistas: Array = ks.filter(func(x): return S.disc.get(x))
			await ficha_variedad(vistas, vistas.find(k))
		elif c == "Lo que entra":
			await dex_entra(k, R)
		else:
			await leer(D.STRAINS[k].n.to_upper(), dex_desc(k, R, true))

func dex_entra(t: String, R: Dictionary) -> void:
	var ks := []
	for o in R[t]:
		for k in o.k:
			if not ks.has(k):
				ks.append(k)
	var it2 := []
	for k in ks:
		it2.append({"label": ("✓ " if S.disc.get(k) else "  ") + D.STRAINS[k].n, "right": ("×" + n(S.seeds[k])) if S.seeds.get(k) else "", "sw": D.STRAINS[k].c, "ic": ic_cog(k), "desc": donde_semilla(k)})
	it2.append({"label": K("Volver"), "desc": ""})
	await menu(it2, {"cls": "full", "title": D.STRAINS[t].n.to_upper(), "title2": K("lo que entra"), "desc": true})

func dex_cruces(cust: Array) -> void:
	var i := 0
	while true:
		var items := []
		for k in cust:
			var s: Dictionary = S.custom[k]
			items.append({"label": "★ " + s.n, "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "desc": strain_line(k) + "\n" + T("Pulsa A para ver la hoja o cambiarle el nombre."), "c": k})
		items.append({"label": K("Volver"), "desc": ""})
		i = await menu(items, {"cls": "full", "title": K("TUS CRUCES"), "title2": str(cust.size()), "desc": true, "initial": i})
		if i < 0 or i >= cust.size():
			return
		if await ask(S.custom[cust[i]].n, [K("Ver la hoja"), K("Cambiar el nombre")]) == 1:
			await renombrar_variedad(cust[i])
		else:
			await ficha_variedad(cust, i)

func menu_genoteca(i0: int) -> int:
	var DEX: Array = D.DEX
	var nr := 0
	for t in DEX:
		if S.disc.get(t):
			nr += 1
	var items := []
	if S.flags.get("diario"):   # sale bajo la almohada (1.25)
		items.append({"label": K("DIARIO DE LA TÍA MAITE"), "right": "%d/%d" % [nr, DEX.size()], "ic": icono("guardar"), "diario": 1, "desc": T("Su cuaderno: las {n} variedades, lo que apuntó de cada una, las recetas de los cruces y dónde conseguir las semillas.", {"n": DEX.size()})})
	if Datos.CAL:   # MAESTRO [5]: la CannaDex por familias
		var fc: Array = fam_cuenta()
		items.append({"label": K("CANNADEX · FAMILIAS"), "right": "%d/%d" % [fc[0], fc[1]], "ic": icono("guardar"), "fam": 1, "desc": K("Las variedades por familias. Cosecha todas las de una familia y te quedas su bono para siempre.")})
	for j in DEX.size():
		var k: String = DEX[j]
		var s: Dictionary = D.STRAINS[k]
		var nn := "%02d" % (j + 1)
		if S.disc.get(k):
			items.append({"label": "%s %s" % [nn, s.n], "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "k": k, "desc": strain_line(k) + (("\n" + s.h) if s.get("h") else "") + (("\n" + T("Cata: {c}", {"c": S.catas[k]})) if S.catas.has(k) else "")})
		else:
			items.append({"label": nn + " ??????", "desc": K("Sin descubrir.")})
	var cust := []
	for k in S.custom:
		if S.disc.get(k):
			cust.append(k)
	for k in cust:
		var s: Dictionary = S.custom[k]
		items.append({"label": "★ " + s.n, "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "desc": strain_line(k) + "\n" + T("Pulsa A para cambiarle el nombre."), "c": k})
	var nd := 0
	for k in DEX:
		if S.disc.get(k):
			nd += 1
	var i: int = await menu(items, {"cls": "full", "title": K("GENOTECA"), "title2": T("{a}/{b} · {c} propias", {"a": nd, "b": DEX.size(), "c": cust.size()}), "desc": true, "initial": i0})
	var vistas := []   # 1.51: la ficha de cada variedad con su hoja, en el orden de la lista
	for k in DEX:
		if S.disc.get(k):
			vistas.append(k)
	vistas.append_array(cust)
	if i >= 0 and i < items.size() and items[i].get("diario"):
		await recetario()
	elif i >= 0 and i < items.size() and items[i].get("fam"):
		await fam_menu()
	elif i >= 0 and i < items.size() and items[i].get("c"):
		if not Datos.CAL or await ask(S.custom[items[i].c].n, [K("Ver la hoja"), K("Cambiar el nombre")]) == 1:
			await renombrar_variedad(items[i].c)
		else:
			await ficha_variedad(vistas, vistas.find(items[i].c))
	elif Datos.CAL and i >= 0 and i < items.size() and items[i].get("k"):
		await ficha_variedad(vistas, vistas.find(items[i].k))
	return i

func grupo_n(ind: float) -> int:
	var p := roundi(ind * 100)
	return 0 if p <= 10 else (1 if p < 40 else (2 if p <= 60 else (3 if p < 90 else 4)))

func desc_ficha(V: Dictionary) -> String:
	var k: String = V.l[V.i]
	var st = strain(k)
	var p := Hoja.params(D, S, k)
	var land: bool = st.get("tipo") == "landrace"
	var au := (T("Autofloreciente: florece por la edad, sin cambiar la luz.") + " ") if Datos.CAL and st.get("auto") else ""   # 1.52
	return "%s\n%s%s %s" % [Hoja.grupo(p.ind, land), au, Hoja.como(p), (st.get("o", "") + ".") if st.get("o") else ""]

func ficha_variedad(lista: Array, i0: int) -> void:
	if lista.is_empty() or i0 < 0:
		return
	FICHA_V = {"l": lista, "i": i0}
	var nom := func(): return str(strain(FICHA_V.l[FICHA_V.i]).n).to_upper()
	_dlg_fijo(desc_ficha(FICHA_V), nom.call())
	if gancho_menu.is_valid():   # las pruebas: se ve y se cierra
		FICHA_V = null
		return
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "B":
			pop()
			pr.res(null)
			return
		var d: int = {"left": -1, "right": 1}.get(b, 0)
		if d and FICHA_V.l.size() > 1:
			FICHA_V.i = (FICHA_V.i + d + FICHA_V.l.size()) % FICHA_V.l.size()
			sfx("sel")
			_dlg_fijo(desc_ficha(FICHA_V), nom.call()))
	await Motor.espera(pr)
	FICHA_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()

# la lámina (128 × 100): el papel, la hoja (Hoja.W × Hoja.H, la pinta pinta.gd en hoja_xy), el nombre y la franja del grupo
func rects_ficha(V: Dictionary) -> Array:
	var o := []
	var k: String = V.l[V.i]
	var x0: int = (SW - 128) >> 1
	var y0: int = maxi(2, (alto_libre() - 100) >> 1)
	o.append_array([[x0, y0, 128, 100, "#5a5040"], [x0 + 1, y0 + 1, 126, 98, "#f4f2ea"], [x0 + 3, y0 + 3, 122, 94, "#e8e4d6"], [x0 + 4, y0 + 4, 120, 92, "#f8f6ee"]])
	var g := grupo_n(Hoja.params(D, S, k).ind)
	o.append([x0 + 4, y0 + 4, 3, 92, COLOR_GRUPO[g]])
	var t: String = str(strain(k).n)
	if t.length() > 28:
		t = t.left(27) + "."
	Croquis.texto(o, x0 + 64 - (Croquis.ancho(t) >> 1), y0 + 74, t, "#22261e")
	var gt: String = I18n.v([K("SATIVA"), K("HIBRIDO SATIVA"), K("EQUILIBRADO"), K("HIBRIDO INDICA"), K("INDICA")][g])
	Croquis.texto(o, x0 + 64 - (Croquis.ancho(gt) >> 1), y0 + 83, gt, COLOR_GRUPO[g])
	if V.l.size() > 1:   # las flechas
		o.append_array([[x0 + 9, y0 + 36, 1, 5, "#8a8070"], [x0 + 8, y0 + 37, 1, 3, "#8a8070"], [x0 + 7, y0 + 38, 1, 1, "#8a8070"],
			[x0 + 118, y0 + 36, 1, 5, "#8a8070"], [x0 + 119, y0 + 37, 1, 3, "#8a8070"], [x0 + 120, y0 + 38, 1, 1, "#8a8070"]])
	return o

func hoja_xy() -> Vector2i:
	return Vector2i(((SW - 128) >> 1) + 32, maxi(2, (alto_libre() - 100) >> 1) + 6)

func mochila() -> void:
	var i := 0
	while true:
		var M: Dictionary = D.MOCHILAS[int(S.items.get("bolsa", 0))]
		var rows := [{"label": K("Dinero"), "right": Datos.eur(S.money), "ic": icono("billetes"), "desc": K("Lo que llevas encima. Don Baltasar también lo cuenta.")},
			{"label": M.n, "right": T("{n} de {kg}", {"n": int(floor(peso_encima())), "kg": _kg(int(M.g))}), "ic": icono("bolsa"), "desc": K("Cogollos y extractos que llevas encima. Lo que no cabe al cosechar va a la caja fuerte.")}]
		if S.get("caja"):
			var CJ: Dictionary = D.CAJA[S.caja.nivel]
			rows.append({"label": K("Caja fuerte"), "right": "%s · %d g" % [Datos.eur(caja_e()), int(floor(caja_g()))], "ic": icono("billetes"),
				"desc": T("{n}, detrás del diploma. Caben {e} y {kg}.\nLo que está dentro no lo llevas encima.", {"n": CJ.n, "e": Datos.eur(CJ.money), "kg": _kg(int(CJ.g))})})
		if nevera_r() >= .1:
			rows.append({"label": K("Nevera"), "right": Datos.coma(Datos.jsround(nevera_r() * 10) / 10.0) + " g", "ic": icono("cogollo"),
				"desc": T("Los extractos, en frío, en casa (caben {n} g). Un control en la calle no la ve; una redada se la lleva.", {"n": n(nevera_cap())})})
		rows.append({"label": K("Vida"), "right": "%s/%s" % [n(S.hp), n(S.hpMax)], "ic": icono("corazon"), "desc": K("Se recupera durmiendo, comiendo o con el tiempo.")})
		if int(S.pelea.xp) > 0:
			rows.append({"label": K("Pelea"), "right": T("nivel {n}", {"n": nivel_pelea()}), "desc": ficha_pelea()})
		for k in D.PRODUCTOS:   # 1.23: por marca
			if k == "fert" or S.items.get(k, 0) > 0:
				rows.append({"label": D.PRODUCTOS[k].n, "right": "×" + n(S.items.get(k, 0)), "ic": icono("abono"), "desc": D.DESC_PROD[k]})
		if S.items.get("medidor", 0):
			rows.append({"label": K("Medidor de pH y EC"), "right": "×1", "desc": K("Con él corriges el pH justo y ves la EC y el pH de cada maceta en PLANTAS.")})
		if S.items.get("tarros"):
			rows.append({"label": K("Tarros de curado"), "right": K("en casa"), "desc": T("Los cogollos en la caja fuerte y los extractos en la nevera se curan en {d} días: suben un {t} % de THC y se venden un {p} % más caros.", {"d": int(D.CURADO.dias), "t": Datos.jsround(D.CURADO.thc * 100), "p": Datos.jsround(D.CURADO.precio * 100)})})
		rows.append_array([{"label": K("Insecticida (tratamientos)"), "right": "×" + n(S.items.insect), "ic": icono("insecticida"), "desc": K("Úsalo en una maceta con plaga.")},
			{"label": K("Spray de pimienta"), "right": "×" + n(S.items.spray), "ic": icono("spray"), "desc": K("Solo en combate.")},
			{"label": K("Bocata"), "right": "×" + n(S.items.bocata), "ic": icono("bocadillo"), "desc": K("Pulsa A para comerlo: +15 de vida."), "k": "bocata"}])
		for k in D.MACETAS:
			if S.items.get("m_" + k, 0) > 0:
				rows.append({"label": T("Maceta {n}", {"n": D.MACETAS[k].n}), "right": "×" + n(S.items["m_" + k]), "ic": icono("maceta"), "desc": desc_maceta(k) + "\n" + (T("Se cambia en una plaza vacía de la carpa.") if D.CARPAS.values().any(func(c): return int(c.get("lmax", 0)) >= int(D.MACETAS[k].l)) else K("Para los esquemas de las carpas de KAIA."))})
		for k in D.FOCOS:
			if S.items.get("f_" + k, 0) > 0:
				rows.append({"label": T("Foco {n}", {"n": D.FOCOS[k].n}), "right": "×" + n(S.items["f_" + k]), "ic": icono(Atlas.ico_foco(k)), "desc": desc_foco(k) + "\n" + T("Se cuelga desde la vista de carpa: ▲ hasta el foco y A.")})
		for k in D.EXTRAS:
			if S.items.get("x_" + k, 0) > 0:
				rows.append({"label": D.EXTRAS[k].n, "right": "×" + n(S.items["x_" + k]), "ic": icono(Atlas.ICX[k]), "desc": I18n.v(D.EXTRAS[k].d) + "\n" + (T("Se ponen desde la vista de carpa: ▲ hasta el foco y A.") if D.EXTRAS[k].get("pl") else T("Se pone desde la vista de carpa: ▲ hasta el foco y A."))})
		for k in S.seeds:
			rows.append({"label": T("Semilla {n}", {"n": strain(k).n}), "right": "×" + n(S.seeds[k]), "sw": strain(k).c, "ic": icono("semillas"), "desc": strain_line(k) + "\n" + T("Pulsa A para tirarlas."), "k": "s", "sid": k})
		for e in S.esquejes:
			rows.append({"label": T("Esqueje {n}", {"n": strain(e.sid).n + etiq(e.f)}), "right": Datos.fd_corto(e.dia + D.ESQUEJE_DIAS), "sw": strain(e.sid).c, "ic": ic_cog(e.sid),
				"desc": T("Enraizando en el propagador. Plántalo en una plaza vacía antes de que acabe el {d}.\nPulsa A para ponerle nombre o tirarlo.", {"d": Datos.fd(e.dia + D.ESQUEJE_DIAS, S.day)}), "k": "e", "e": e})
		for k in S.buds:
			var b: Dictionary = S.buds[k]
			rows.append({"label": lot_nombre(k), "right": "%d g · %s%%" % [int(floor(b.g)), Datos.pct(b.thc)], "sw": strain(lot_sid(k)).c, "ic": ic_cog(lot_sid(k)),
				"desc": (T("Cogollos de un fenotipo estrella, en lote aparte.") if k.ends_with("*") else T("Cogollos listos para vender.")) + "\n" + ((cura_txt(b) + "\n") if cura_txt(b) else "") + ((S.catas[lot_sid(k)] + "\n") if S.catas.has(lot_sid(k)) else "") + I18n.v(strain(lot_sid(k)).o) + "\n" + (T("Pulsa A para catarlo, analizarlo o tirarlo.") if S.items.get("analizador") else T("Pulsa A para catarlo o tirarlo.")), "k": "b", "key": k})
		for k in S.rosin:
			var b: Dictionary = S.rosin[k]
			var ro := rosin_item([k, b])
			ro.desc = T("{n}: extracción sin disolventes. La compran los catadores.", {"n": D.EXTR[tipo_extr(k)].n}) + "\n" + ((S.catas["r:" + k] + "\n") if S.catas.has("r:" + k) else "") + I18n.v(strain(lot_sid(k)).o) + "\n" + (T("Pulsa A para catarlo o tirarlo.") if Datos.CAL else T("Pulsa A para tirarlo."))
			ro.k = "r"
			ro.key = k
			rows.append(ro)
		if Datos.CAL:   # 1.47: lo de fumar (el estanco y el grow)
			for q in [["papel", K("Papel de liar"), K("hojas"), K("Una hoja por porro. En el estanco.")], ["filtros", K("Filtros"), "", K("Cada porro gasta uno. En el estanco.")],
					["tabaco", K("Tabaco de liar"), "g", K("Para mezclar: 0,7 g por porro y el porro lleva menos hierba. En el estanco.")], ["mechero", K("Mechero"), "", K("Para el porro, la pipa y el bong.")],
					["grinder", K("Grinder"), "", K("El porro te sale con 0,4 g de hierba en vez de 0,5.")], ["pipa", K("Pipa de cristal"), "", K("Sentado en un sofá o una silla: 0,2 g de cogollo o 0,1 de extracto.")],
					["bong", K("Bong de cristal"), "", K("Sentado: 0,3 g de cogollo o 0,1 de extracto.")], ["vapo", K("Vaporizador"), "", K("Sentado: 0,2 g de cogollo o 0,1 de extracto, sin mechero; en la calle huele menos.")]]:
				var v := float(S.items.get(q[0], 0))
				if v > 0:
					rows.append({"label": q[1], "right": T("{n} {u}", {"n": n(floor(v * 10) / 10.0), "u": q[2]}) if q[2] != "" else "×" + n(v), "ic": icono(q[0]), "desc": q[3]})
		if S.items.get("prensa"):
			rows.append({"label": K("Prensa de rosin"), "right": K("en la mesa"), "desc": K("De 5 g de cogollo, 1 g de rosin con el triple de THC. Se usa en la mesa del piso.")})
		if S.items.get("tamiz"):
			rows.append({"label": K("Tamices de seda"), "right": K("en la mesa"), "desc": K("Dry sift: de la flor, el kief con algo más del doble de THC. Se usa en la mesa del piso.")})
		if S.items.get("ice"):
			rows.append({"label": K("Kit Ice-o-lator"), "right": K("en la mesa"), "desc": K("Agua con hielo y bolsas de malla: la resina más limpia. Se usa en la mesa del piso.")})
		if S.items.get("mallas00"):   # 1.36
			rows.append({"label": K("Mallas 00"), "right": K("en el piso"), "desc": K("La malla «doble cero» de la tía: dry sift de lo más fino, solo las cabezas. Se usa en los tamices del piso.")})
		if S.items.get("lavadora"):
			rows.append({"label": K("Lavadora de extracción"), "right": K("en el piso"), "desc": K("Ice-o-lator en grande: bate sola con las bolsas de malla. Está montada junto a la nevera.")})
		if S.items.get("estatica"):
			rows.append({"label": K("Máquina de static"), "right": K("en el piso"), "desc": K("La placa cargada levanta las cabezas de resina de la flor fría: la resina más pura.")})
		i = await menu(rows, {"cls": "full", "title": K("MOCHILA"), "title2": T("{n} g encima · {c} g en la caja", {"n": int(floor(total_buds())), "c": int(floor(caja_g()))}) if S.get("caja") else T("{n} g encima", {"n": int(floor(total_buds()))}), "desc": true, "initial": i})
		if i < 0:
			return
		if rows[i].get("k") == "bocata":
			if S.items.bocata > 0 and S.hp < S.hpMax:
				S.items.bocata -= 1
				S.hp = mini(S.hpMax, S.hp + 15)
				sfx("get")
				toast(K("Te comes el bocata. +15 de vida"), 1200)
			else:
				sfx("bump")
		elif rows[i].get("k") == "e":
			await esqueje_accion(rows[i].e, S.esquejes)
		elif rows[i].get("k") == "b":   # la cata y el análisis (1.15)
			await lote_accion(rows[i].key)
		elif rows[i].get("k") == "r":   # 1.36: tirar un extracto; 1.47: o catarlo
			if Datos.CAL:
				await extr_accion(rows[i].key)
			else:
				await tirar_lote(rows[i].key, true)
		elif rows[i].get("k") == "s":   # tirar semillas (1.11)
			var sid: String = rows[i].sid
			var ns: int = int(S.seeds[sid])
			var o := [K("Tirar 1"), K("Tirar todas"), K("Nada")] if ns > 1 else [K("Tirar"), K("Nada")]
			var c: int = await ask(T("{n} semillas de {s}.", {"n": ns, "s": strain(sid).n}) if ns > 1 else T("1 semilla de {s}.", {"s": strain(sid).n}), o)
			if c >= 0 and c < o.size() and o[c] != "Nada":
				var q: int = ns if o[c] == "Tirar todas" else 1
				S.seeds[sid] -= q
				if not S.seeds[sid]:
					S.seeds.erase(sid)
				sfx("sel")
				await say(T("Tiras las {n} semillas.", {"n": q}) if q > 1 else K("Tiras 1 semilla."))

func plantas() -> void:
	var rows := []
	var H := huecos()
	var cl := Cultivo.clima_sala(S, is_night())
	rows.append({"label": K("Sala"), "right": t_clima(cl) if S.sala.get("termo") else "¿?", "desc": sala_desc() if S.sala.get("termo") else K("Sin termohigrómetro no sabes la temperatura ni la humedad de la sala. Kiko lo vende.")})
	for ci in S.carpas.size():
		var c = S.carpas[ci]
		if not c:
			continue
		var C: Dictionary = D.CARPAS[c.t]
		var F: Dictionary = D.FOCOS[c.foco]
		var wm2 := Datos.jsround(F.w / (C.cm[0] * C.cm[2] / 1e4))
		rows.append({"label": C.n, "right": F.n, "ic": icono(Atlas.ico_carpa(c.t)), "desc": (T("{p} plantas · foco {f}, {w} W/m² (poca luz: crecen más despacio y con menos THC)\nLuz: {e} al día con plantas · hasta {wm} W, macetas de {l} L y {lm} L de tierra ({lc} puestos).\n{x}{d}", {"p": n(C.plazas), "f": F.n, "w": wm2,
			"e": Datos.eur(luz_carpa(ci)), "wm": n(C.wmax), "l": n(C.lmax), "lm": litros_max(ci), "lc": litros_carpa(ci), "x": Cultivo.ext_txt(S, ci),
			"d": (" · " + T("dentro, de día {c}", {"c": t_clima(Cultivo.clima_carpa(S, ci, false))})) if S.sala.get("termo") and plantas_vivas(ci) else ""}) if wm2 < D.W_M2 else
			T("{p} plantas · foco {f}, {w} W/m²\nLuz: {e} al día con plantas · hasta {wm} W, macetas de {l} L y {lm} L de tierra ({lc} puestos).\n{x}{d}", {"p": n(C.plazas), "f": F.n, "w": wm2,
			"e": Datos.eur(luz_carpa(ci)), "wm": n(C.wmax), "l": n(C.lmax), "lm": litros_max(ci), "lc": litros_carpa(ci), "x": Cultivo.ext_txt(S, ci),
			"d": (" · " + T("dentro, de día {c}", {"c": t_clima(Cultivo.clima_carpa(S, ci, false))})) if S.sala.get("termo") and plantas_vivas(ci) else ""}))})
		for i in H.size():
			var h: Dictionary = H[i]
			if h.c != ci:
				continue
			var p = S.pots[i]
			var Mc: Dictionary = D.MACETAS[S.macetas[i]]
			if not p:
				rows.append({"label": "  " + T("{n} · vacía", {"n": int(h.j + 1)}), "right": n(Mc.l) + " L", "ic": icono("maceta"), "desc": T("Maceta de {n}. Planta algo desde la carpa de tu piso.", {"n": Mc.n})})
				continue
			var s = strain(p.sid)
			var desc := K("Se ha secado. Retírala.") if p.get("dead") else T("{f} · Agua {a}% · Salud {s}%\n{p}{b} · maceta de {m}.", {"f": K("Lista para cosechar") if p.prog >= 1 else stage_name(p), "a": Datos.jsround(p.water),
				"s": Datos.jsround(p.health), "p": (T("PLAGA: trátala con insecticida.") + " ") if p.pest else "", "b": abono_txt(p), "m": Mc.n})
			rows.append({"label": "  %d · %s%s" % [h.j + 1, s.n, etiq(p.get("f"))], "sw": s.c, "ic": ic_cog(p.sid),
				"right": K("muerta") if p.get("dead") else (K("LISTA") if p.prog >= 1 else "%d%%" % int(floor(p.prog * 100))), "desc": desc})
	var luz := factura_luz()
	var i := 0
	while true:
		i = await menu(rows, {"cls": "full", "title": K("CULTIVO"), "title2": T("Luz {e}/día", {"e": Datos.eur(luz)}) if luz else K("Luz apagada"), "desc": true, "initial": i})
		if i < 0:
			break
