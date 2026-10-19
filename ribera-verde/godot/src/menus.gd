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
		var it := [{"label": "GENOTECA", "right": "%d/%d" % [desc, D.DEX.size()], "ic": icono("cogollo")}, {"label": "MOCHILA", "right": _kg(int(floor(peso_encima()))), "ic": icono("bolsa")},
			{"label": "MÓVIL", "right": ("%d SMS" % ns) if ns else null, "ic": icono("movil")}, {"label": "PLANTAS", "right": str(vivas), "ic": icono("maceta")},
			{"label": "OBJETIVO", "right": "cap. %d" % S.ch, "ic": icono("trofeo")}, {"label": "GUARDAR", "ic": icono("guardar")},
			{"label": "OPCIONES", "ic": icono("altavoz")}, {"label": "SALIR", "ic": icono("salir")}]
		if Datos.PLAY:   # U4: el registro de diálogo
			it.insert(5, {"label": "REGISTRO", "right": str(registro.size()), "ic": icono("movil")})
		if Datos.PLAY and S.flags.get("demo4"):   # U11: la demo, acabada
			it.insert(0, {"label": "JUEGO COMPLETO", "right": "cap. %d" % int(D.COMPLETO.ch), "ic": icono("trofeo")})
		i = await menu(it, {"cls": "start", "initial": i, "startCloses": true, "title": "%s · %s" % [Datos.fd_hud(S.day), reloj_txt()], "title2": Datos.eur(S.money)})
		if i < 0 or it[i].label == "SALIR":
			return
		if it[i].label == "JUEGO COMPLETO":
			if await demo_menu():
				await cap4_sigue()
				return
			continue
		if it[i].label == "REGISTRO":
			await leer("REGISTRO", "\n\n".join(PackedStringArray(_registro_inv())) if registro.size() else "Todavía no has hablado con nadie.")
			continue
		var k: int = ["GENOTECA", "MOCHILA", "MÓVIL", "PLANTAS", "OBJETIVO", "GUARDAR", "OPCIONES"].find(it[i].label)
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
			await say("Partida guardada." if save() else "No se ha podido guardar la partida.")
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

# Todas las de la Genoteca, en su orden; las de receta abren lo que entra; las demás dicen dónde están sus semillas
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
			items.append({"label": "%s %s" % [nn, s.n], "right": Datos.pct(s.thc) + "%", "sw": s.c, "ic": ic_cog(k), "k": k, "desc": strain_line(k) + (("\n" + s.h) if s.get("h") else "") + (("\nCata: " + S.catas[k]) if S.catas.has(k) else "")})
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
	var vistas := []   # 1.51: la ficha de cada variedad con su hoja, en el orden de la lista
	for k in DEX:
		if S.disc.get(k):
			vistas.append(k)
	vistas.append_array(cust)
	if i >= 0 and i < items.size() and items[i].get("diario"):
		await recetario()
	elif i >= 0 and i < items.size() and items[i].get("c"):
		if not Datos.CAL or await ask(S.custom[items[i].c].n, ["Ver la hoja", "Cambiar el nombre"]) == 1:
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
	var au := "Autofloreciente: florece por la edad, sin cambiar la luz. " if Datos.CAL and st.get("auto") else ""   # 1.52
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
	var gt: String = ["SATIVA", "HIBRIDO SATIVA", "EQUILIBRADO", "HIBRIDO INDICA", "INDICA"][g]
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
		var rows := [{"label": "Dinero", "right": Datos.eur(S.money), "ic": icono("billetes"), "desc": "Lo que llevas encima. Don Baltasar también lo cuenta."},
			{"label": M.n, "right": "%d de %s" % [int(floor(peso_encima())), _kg(int(M.g))], "ic": icono("bolsa"), "desc": "Cogollos y extractos que llevas encima. Lo que no cabe al cosechar va a la caja fuerte."}]
		if S.get("caja"):
			var CJ: Dictionary = D.CAJA[S.caja.nivel]
			rows.append({"label": "Caja fuerte", "right": "%s · %d g" % [Datos.eur(caja_e()), int(floor(caja_g()))], "ic": icono("billetes"),
				"desc": "%s, detrás del diploma. Caben %s y %s.\nLo que está dentro no lo llevas encima." % [CJ.n, Datos.eur(CJ.money), _kg(int(CJ.g))]})
		if nevera_r() >= .1:
			rows.append({"label": "Nevera", "right": Datos.coma(Datos.jsround(nevera_r() * 10) / 10.0) + " g", "ic": icono("cogollo"),
				"desc": "Los extractos, en frío, en casa (caben %s g). Un control en la calle no la ve; una redada se la lleva." % n(nevera_cap())})
		rows.append({"label": "Vida", "right": "%s/%s" % [n(S.hp), n(S.hpMax)], "desc": "Se recupera durmiendo, comiendo o con el tiempo."})
		if int(S.pelea.xp) > 0:
			rows.append({"label": "Pelea", "right": "nivel %d" % nivel_pelea(), "desc": ficha_pelea()})
		for k in D.PRODUCTOS:   # 1.23: por marca
			if k == "fert" or S.items.get(k, 0) > 0:
				rows.append({"label": D.PRODUCTOS[k].n, "right": "×" + n(S.items.get(k, 0)), "ic": icono("abono"), "desc": D.DESC_PROD[k]})
		if S.items.get("medidor", 0):
			rows.append({"label": "Medidor de pH y EC", "right": "×1", "desc": "Con él corriges el pH justo y ves la EC y el pH de cada maceta en PLANTAS."})
		if S.items.get("tarros"):
			rows.append({"label": "Tarros de curado", "right": "en casa", "desc": "Los cogollos en la caja fuerte y los extractos en la nevera se curan en %d días: suben un %d %% de THC y se venden un %d %% más caros." % [int(D.CURADO.dias), Datos.jsround(D.CURADO.thc * 100), Datos.jsround(D.CURADO.precio * 100)]})
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
			rows.append({"label": "Esqueje " + strain(e.sid).n + etiq(e.f), "right": Datos.fd_corto(e.dia + D.ESQUEJE_DIAS), "sw": strain(e.sid).c, "ic": ic_cog(e.sid),
				"desc": "Enraizando en el propagador. Plántalo en una plaza vacía antes de que acabe el %s.\nPulsa A para ponerle nombre o tirarlo." % Datos.fd(e.dia + D.ESQUEJE_DIAS, S.day), "k": "e", "e": e})
		for k in S.buds:
			var b: Dictionary = S.buds[k]
			rows.append({"label": lot_nombre(k), "right": "%d g · %s%%" % [int(floor(b.g)), Datos.pct(b.thc)], "sw": strain(lot_sid(k)).c, "ic": ic_cog(lot_sid(k)),
				"desc": ("Cogollos de un fenotipo estrella, en lote aparte.\n" if k.ends_with("*") else "Cogollos listos para vender.\n") + ((cura_txt(b) + "\n") if cura_txt(b) else "") + ((S.catas[lot_sid(k)] + "\n") if S.catas.has(lot_sid(k)) else "") + strain(lot_sid(k)).o + "\nPulsa A para catarlo" + (", analizarlo" if S.items.get("analizador") else "") + " o tirarlo.", "k": "b", "key": k})
		for k in S.rosin:
			var b: Dictionary = S.rosin[k]
			var ro := rosin_item([k, b])
			ro.desc = D.EXTR[tipo_extr(k)].n + ": extracción sin disolventes. La compran los catadores.\n" + ((S.catas["r:" + k] + "\n") if S.catas.has("r:" + k) else "") + strain(lot_sid(k)).o + ("\nPulsa A para catarlo o tirarlo." if Datos.CAL else "\nPulsa A para tirarlo.")
			ro.k = "r"
			ro.key = k
			rows.append(ro)
		if Datos.CAL:   # 1.47: lo de fumar (el estanco y el grow)
			for q in [["papel", "Papel de liar", "hojas", "Una hoja por porro. En el estanco."], ["filtros", "Filtros", "", "Cada porro gasta uno. En el estanco."],
					["tabaco", "Tabaco de liar", "g", "Para mezclar: 0,7 g por porro y el porro lleva menos hierba. En el estanco."], ["mechero", "Mechero", "", "Para el porro, la pipa y el bong."],
					["grinder", "Grinder", "", "El porro te sale con 0,4 g de hierba en vez de 0,5."], ["pipa", "Pipa de cristal", "", "Sentado en un sofá o una silla: 0,2 g de cogollo o 0,1 de extracto."],
					["bong", "Bong de cristal", "", "Sentado: 0,3 g de cogollo o 0,1 de extracto."], ["vapo", "Vaporizador", "", "Sentado: 0,2 g de cogollo o 0,1 de extracto, sin mechero; en la calle huele menos."]]:
				var v := float(S.items.get(q[0], 0))
				if v > 0:
					rows.append({"label": q[1], "right": ("%s %s" % [n(floor(v * 10) / 10.0), q[2]]) if q[2] != "" else "×" + n(v), "ic": icono(q[0]), "desc": q[3]})
		if S.items.get("prensa"):
			rows.append({"label": "Prensa de rosin", "right": "en la mesa", "desc": "De 5 g de cogollo, 1 g de rosin con el triple de THC. Se usa en la mesa del piso."})
		if S.items.get("tamiz"):
			rows.append({"label": "Tamices de seda", "right": "en la mesa", "desc": "Dry sift: de la flor, el kief con algo más del doble de THC. Se usa en la mesa del piso."})
		if S.items.get("ice"):
			rows.append({"label": "Kit Ice-o-lator", "right": "en la mesa", "desc": "Agua con hielo y bolsas de malla: la resina más limpia. Se usa en la mesa del piso."})
		if S.items.get("mallas00"):   # 1.36
			rows.append({"label": "Mallas 00", "right": "en el piso", "desc": "La malla «doble cero» de la tía: dry sift de lo más fino, solo las cabezas. Se usa en los tamices del piso."})
		if S.items.get("lavadora"):
			rows.append({"label": "Lavadora de extracción", "right": "en el piso", "desc": "Ice-o-lator en grande: bate sola con las bolsas de malla. Está montada junto a la nevera."})
		if S.items.get("estatica"):
			rows.append({"label": "Máquina de static", "right": "en el piso", "desc": "La placa cargada levanta las cabezas de resina de la flor fría: la resina más pura."})
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
		elif rows[i].get("k") == "r":   # 1.36: tirar un extracto; 1.47: o catarlo
			if Datos.CAL:
				await extr_accion(rows[i].key)
			else:
				await tirar_lote(rows[i].key, true)
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
