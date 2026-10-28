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

# lo que pinta.gd necesita de una mesa del mapa: {Me, fm (la fase), foco} o null si o no es una mesa (la de la nave; kaiacult.gd, las de KAIA)
func mesa_de(o: String, x: int, y: int):
	if o != "mesaN":   # i18n-no
		return null
	var i := mesa_idx(x, y)
	var N = S.get("nave")
	return {"Me": N.m[i] if N != null and i >= 0 and i < N.m.size() else null, "fm": fase_mesa(i), "foco": (N.f[i] if N != null else "led") if i >= 0 else null}   # i18n-no

func thc_nave(sid: String, f) -> float:
	return Datos.jsround(strain(sid).thc * (f.t if f else 1.0) * D.NAVE.thc * 10) / 10.0

func mesa_txt(Me: Dictionary) -> String:
	return strain(lot_sid(Me.k)).n + etiq(Me.get("f"))

func mesa_nave(i: int) -> void:
	var N: Dictionary = S.nave
	var Me = N.m[i]
	var w = navero_de(i)
	var ops: Array = [K("Arrancar y plantar") if Me else K("Plantar")]
	if Me:
		ops.append(K("Abono"))
	ops.append(K("Focos"))
	ops.append(K("Nada"))
	var que: String = (mesa_txt(Me) + " · " + I18n.v(D.FASE_MESA[fase_mesa(i)]) + " · " + cosecha_txt(Me) + " · " + I18n.v(D.ABONO_MESA[int(Me.abo)])) if Me else K("vacía")
	var oi: int = await ask(T("Mesa {i} · {que} · {foco}\n{cuida}", {"i": i + 1, "que": que, "foco": D.FOCO_NAVE[N.f[i]].n, "cuida": T("La cuida {n}.", {"n": w.n}) if w else K("Nadie la cuida: pon a alguien de tu plantilla en la nave.")}), ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if op == "Focos":
		await focos_nave(i)
	elif op == "Plantar" or op == "Arrancar y plantar":
		if Me and Me.get("h") != null:
			await say(K("Lo de esta mesa aún se está secando en el secadero: espera a descolgarlo."))
			return
		if Me and Me.g >= 1:
			await say(K("Antes, descuelga del secadero lo de esta mesa."))
			return
		await plantar_mesa(i)
	elif op == "Abono":
		var c: int = await ask(T("¿Qué abono le echa cada día? En la estantería: MEATZA ×{m} · ORTUA BIO ×{o}.", {"m": dosis_txt(N.ab.m), "o": dosis_txt(N.ab.o)}), [K("Sin abono"), K("MEATZA Floración"), K("ORTUA BIO Floración"), K("Nada")])
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
		await say(K("No llevas semillas ni esquejes."))
		return null
	var items := []
	for j in ma.size():
		var k := lot_sid(ma[j].k)
		var s = strain(k)
		items.append({"label": T("Madre {j}: {nom}{et}", {"j": j + 1, "nom": s.n, "et": etiq(ma[j].get("f"))}), "right": K("clon"), "sw": s.c, "ic": ic_cog(k), "desc": K("Un clon de la carpa de las madres: no se gasta nada.")})
	for b in bc:
		var k := lot_sid(b.k)
		var s = strain(k)
		items.append({"label": T("Bandeja: {nom}{et}", {"nom": s.n, "et": etiq(b.get("f"))}), "right": T("{n} clones", {"n": int(D.NAVE.tacos)}), "sw": s.c, "ic": ic_cog(k), "desc": K("Los clones enraizados del carro de bandejas: una mesa entera.")})
	for o in own:
		var s = strain(o[0])
		items.append({"label": s.n, "right": "×" + n(o[1]), "sw": s.c, "ic": ic_cog(o[0]), "desc": strain_line(o[0])})
	for eb in esq:
		var s = strain(eb[0].sid)
		items.append({"label": T("Esqueje {nom}{et}", {"nom": s.n, "et": etiq(eb[0].f)}), "right": K("bandeja") if eb[1] else K("esqueje"), "sw": s.c, "ic": ic_cog(eb[0].sid), "desc": K("Clon enraizado: sale con su fenotipo.")})
	items.append({"label": K("Cancelar"), "desc": ""})
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
	var p = await elegir_planta(K("¿QUÉ PLANTAS EN LA MESA?"), true)
	if p == null:
		return
	var sid: String = p.sid
	var f: Dictionary = p.f
	S.nave.m[i] = {"k": sid + ("*" if Cultivo.clase_feno(f) == "estrella" else ""), "f": f, "thc": thc_nave(sid, f), "y": f.y, "dia": S.day, "g": 0, "t": 0, "abo": 0, "p": float(D.NAVE.clon), "dn": 0, "am": 0, "ao": 0, "n": 0}
	sfx("sel")
	await say(T("Mesa {i}: {nom}{et}. De la madre salen los clones para toda la mesa: enraízan, crecen a 18/6 y florecen a 12/12. Se cosecha entera en unos {d} días y vuelve a empezar.", {"i": i + 1, "nom": strain(sid).n, "et": etiq(f), "d": dias_mesa(S.nave.m[i])}))

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
	if Datos.CAL:
		await vista_madres()
		return
	var N: Dictionary = S.nave
	var i := 0
	while true:
		var c = cuida_madres()
		var rows := []
		for j in N.ma.size():
			var M: Dictionary = N.ma[j]
			var k := lot_sid(M.k)
			var s = strain(k)
			rows.append({"label": T("Madre {j} · {nom}", {"j": j + 1, "nom": s.n}), "right": T("{n} esq.", {"n": int(M.e)}) if M.e else ("%d %%" % int(M.v)), "sw": s.c, "ic": ic_cog(k),
				"desc": T("{m}. Vigor {v} % · {e} esquejes listos.", {"m": madre_txt(M), "v": int(M.v), "e": int(M.e)}) if M.e else T("{m}. Vigor {v} %.", {"m": madre_txt(M), "v": int(M.v)})})
		if N.ma.size() < int(D.MADRES.max):
			rows.append({"label": K("Meter una madre"), "right": T("{a} de {b}", {"a": N.ma.size(), "b": int(D.MADRES.max)}), "desc": K("Con una semilla o un esqueje: la madre de una genética que quieras guardar. De ella salen los esquejes y los clones de las mesas.")})
		rows.append({"label": K("Volver"), "desc": ""})
		i = await menu(rows, {"cls": "full", "title": K("LAS MADRES"), "title2": T("Las cuida {n}", {"n": c.n}) if c != null else K("Nadie las cuida"), "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0 or i == rows.size() - 1:
			return
		if i >= N.ma.size():
			await madre_meter()
			continue
		await madre_ops(i)

# meter una madre en la carpa, con una semilla o un esqueje
func madre_meter() -> void:
	var N: Dictionary = S.nave
	var c = cuida_madres()
	var p = await elegir_planta(K("¿QUÉ MADRE METES?"), false)
	if p == null:
		return
	if Datos.CAL and strain(p.sid).get("auto"):   # 1.52
		await say(T("La {nom} es autofloreciente: florece por la edad y no se queda de madre. Sus esquejes florecerían enanos.", {"nom": strain(p.sid).n}))
		return
	N.ma.append({"k": p.sid + ("*" if Cultivo.clase_feno(p.f) == "estrella" else ""), "f": p.f, "v": 100, "e": 0})
	sfx("sel")
	await say(T("La {nom}{et}, a la carpa de las madres: a 18/6, siempre en crecimiento.", {"nom": strain(p.sid).n, "et": etiq(p.f)}) + " " + (T("{n} se encarga.", {"n": c.n}) if c != null else K("Sin nadie que la cuide, se va apagando: pon a alguien de tu plantilla en las madres.")))

# los esquejes van al propagador (S.esquejes, con su tope); devuelve los que caben de q
func _al_propagador(M: Dictionary, q: int) -> int:
	q = mini(q, int(D.MADRES.propagador) - S.esquejes.size())
	for j in maxi(0, q):
		S.esquejes.append({"sid": lot_sid(M.k), "f": M.f, "dia": S.day})
	return q

# lo de una madre: recoger los esquejes que le ha sacado quien las cuida, cortárselos tú (con CAL, una vez al día) o quitarla
func madre_ops(i: int) -> void:
	var N: Dictionary = S.nave
	var c = cuida_madres()
	var M: Dictionary = N.ma[i]
	var ops := []
	var rec := ""
	if M.e:
		rec = T("Recoger {n} esquejes", {"n": int(M.e)}) if M.e > 1 else T("Recoger {n} esqueje", {"n": int(M.e)})
		ops.append(rec)
	var cor := Datos.CAL and int(M.get("cd", -1)) != int(S.day) and int(M.v) >= int(D.MADRES.get("corte_v", 40))
	if cor:
		ops.append(K("Cortarle esquejes"))
	ops.append_array([K("Quitarla"), K("Nada")])
	var oi: int = await ask(T("Madre {j}: {m} · vigor {v} %.", {"j": i + 1, "m": madre_txt(M), "v": int(M.v)}) + ("" if M.e else (" " + (T("{n} le saca esquejes cada mañana.", {"n": c.n}) if c != null else K("Nadie le saca esquejes.")))), ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if rec != "" and op == rec:
		var q := _al_propagador(M, int(M.e))
		if q < 1:
			await say(T("El propagador está lleno: {n} esquejes. Planta alguno antes.", {"n": int(D.MADRES.propagador)}))
			return
		M.e = int(M.e) - q
		sfx("get")
		var fq := Datos.fd(int(S.day) + int(D.ESQUEJE_DIAS) + 1, S.day)
		await say(T("{q} esquejes de la {m}, al propagador. Plántalos antes del {f}.", {"q": q, "m": madre_txt(M), "f": fq}) if q > 1 else T("Un esqueje de la {m}, al propagador. Plántalos antes del {f}.", {"m": madre_txt(M), "f": fq}))
		return
	if op == K("Cortarle esquejes"):   # con CAL: tú, con las tijeras, las puntas de las ramas de abajo (le cuesta algo de vigor)
		if S.esquejes.size() >= int(D.MADRES.propagador):
			await say(T("El propagador está lleno: {n} esquejes. Planta alguno antes.", {"n": int(D.MADRES.propagador)}))
			return
		gesto_sid = str(M.k)
		await gesto("esqueje")
		var q := _al_propagador(M, int(D.MADRES.get("corte", 2)))
		M.cd = int(S.day)
		M.v = maxi(0, int(M.v) - int(D.MADRES.get("corte_p", 5)))
		sfx("get")
		var fq := Datos.fd(int(S.day) + int(D.ESQUEJE_DIAS) + 1, S.day)
		await say(T("Le cortas {q} esquejes a la {m}, al propagador. Plántalos antes del {f}. Mañana, más.", {"q": q, "m": madre_txt(M), "f": fq}) if q > 1 else T("Le cortas un esqueje a la {m}, al propagador. Plántalo antes del {f}. Mañana, más.", {"m": madre_txt(M), "f": fq}))
		return
	if op == K("Quitarla"):
		if await ask(T("¿Quitas la madre de {m}? Se tira.", {"m": madre_txt(M)}), [K("Quitarla"), K("No")]) != 0:
			return
		N.ma.remove_at(i)
		sfx("sel")

# ---------- el armario de las madres por dentro (lo pidió el usuario: «vista por dentro, como la carpa de casa»; con CAL) ----------
# La carpa plateada de la vista C (carpa-c-pared) con sus dos LED a 18/6 y el temporizador en la pared, las madres en sus macetas de
# tela con el tono de hoja de su variedad, su vigor y los esquejes listos, y los huecos libres. Flechas eligen; A, la madre
# (madre_ops: recoger, cortarle esquejes, quitarla) o el hueco (madre_meter); B cierra. MADRES_V = {i: el sitio elegido}
func vista_madres() -> void:
	var i := 0
	while S.get("nave") != null:
		var r = await elegir_madres(i)
		if r == null:
			return
		i = int(r)
		if i < S.nave.ma.size():
			await madre_ops(i)
		elif S.nave.ma.size() < int(D.MADRES.max):
			await madre_meter()
			i = mini(i, maxi(0, S.nave.ma.size() - 1))

func luz_madres() -> bool:   # el LED, a 18/6 desde las 6 de la mañana (como el temporizador de casa), con alguna madre dentro
	return S.get("nave") != null and not S.nave.ma.is_empty() and posmod(int(S.min) - 6 * 60, 24 * 60) < 18 * 60

func desc_madres(V: Dictionary) -> String:
	var N: Dictionary = S.nave
	var c = cuida_madres()
	var cu: String = T("Las cuida {n}.", {"n": c.n}) if c != null else K("Nadie las cuida.")
	var lz: String = K("LED encendido, a 18/6.") if luz_madres() else (K("LED apagado: sus 6 horas de noche.") if not N.ma.is_empty() else K("LED apagado: no hay madres."))
	if V.i >= N.ma.size():
		return T("Hueco libre · {a} de {b} madres. {l} {c}\nA: meter una madre · B: cerrar.", {"a": N.ma.size(), "b": int(D.MADRES.max), "l": lz, "c": cu})
	var M: Dictionary = N.ma[V.i]
	return T("Madre {j} · {m} · vigor {v} % · {e} esquejes listos. {l}\nA: cortar o recoger esquejes · B: cerrar.", {"j": V.i + 1, "m": madre_txt(M), "v": int(M.v), "e": int(M.e), "l": lz})

func elegir_madres(i0 := 0):
	if gancho_madres.is_valid():
		return gancho_madres.call(i0)
	var nmax: int = int(D.MADRES.max)
	MADRES_V = {"i": clampi(i0, 0, nmax - 1)}
	_dlg_fijo(desc_madres(MADRES_V), K("LAS MADRES"))
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(null)
			return
		if b == "A":
			pop()
			pr.res(MADRES_V.i)
			return
		var n2: int = int(MADRES_V.i) + (-1 if b == "left" else (1 if b == "right" else 0))
		if n2 != int(MADRES_V.i) and n2 >= 0 and n2 < nmax:
			MADRES_V.i = n2
			sfx("sel")
			_dlg_fijo(desc_madres(MADRES_V), K("LAS MADRES")))
	var e = await Motor.espera(pr)
	MADRES_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	return e

const ArteM = preload("res://src/arte.gd")
const VistaM = preload("res://src/vista.gd")
const MAD_PARED := 58   # la carpa de la vista C, de la fila 58 abajo (MAD_H px: lo que cabe encima del diálogo)
const MAD_H := 102
var _mad_cache := {}

func _madre_img(M: Dictionary):   # la planta en crecimiento de la vista C, con el tono de hoja de su variedad
	var p := {"sid": lot_sid(M.k), "f": M.get("f")}
	var po := Datos.porte_planta(S, p)
	var n := "planta-c-%s2-38" % po
	if not ArteM.hay(n):
		return null
	var hj := Datos.hoja_planta(S, p)
	var k := n + "|" + hj
	if not _mad_cache.has(k):
		if _mad_cache.size() > 64:
			_mad_cache.clear()
		_mad_cache[k] = ArteM.recolor(ArteM.foto(n), Datos.vc_tonos(hj))
	return _mad_cache[k]

# los sitios de las madres: el centro x de cada una y la base de su maceta
func sitios_madres() -> Array:
	var x0: int = (SW - 240) >> 1
	var o := []
	var nmax: int = int(D.MADRES.max)
	for k in nmax:
		o.append([x0 + 120 + int(round((k - (nmax - 1) / 2.0) * 44)), MAD_H - 6])
	return o

func rects_madres(V: Dictionary) -> Array:
	var o := []
	var x0: int = (SW - 240) >> 1
	var clip := Rect2i(x0, 0, 240, MAD_H)
	var N: Dictionary = S.nave if S.get("nave") != null else {"ma": []}
	var on := luz_madres()
	o.append([0, 0, SW, SH, "#0e0e12"])
	if ArteM.hay("carpa-c-pared"):
		o.append(["@", ArteM.foto("carpa-c-pared"), x0, -MAD_PARED, clip])
	# los dos LED colgados del techo con sus cuerdas y su luz
	var fl := "foco-c-led200-30"
	for fx in [x0 + 76, x0 + 164]:
		if ArteM.hay(fl):
			var fi: Image = ArteM.foto(fl)
			o.append([fx - 22, 0, 1, 9, ArteM.VC_CUERDA])
			o.append([fx + 21, 0, 1, 9, ArteM.VC_CUERDA])
			o.append(["@", fi, fx - (fi.get_width() >> 1), 8, clip])
		if on:
			o.append([fx - 30, 24, 60, MAD_H - 30, "rgba(255,244,210,0.07)"])
	# el temporizador, a 18/6, en la pared de la izquierda
	o.append_array(VistaM.temporizador(x0 + 12, 20, "veg", on))
	var st := sitios_madres()
	for k in st.size():
		var cx: int = st[k][0]
		var yb: int = st[k][1]
		if k < N.ma.size():
			var M: Dictionary = N.ma[k]
			var im = _madre_img(M)
			var mc := "maceta-c-tela11-26"
			var mi: Image = ArteM.foto(mc) if ArteM.hay(mc) else null
			var top: int = yb - (ArteM.alto(mi) if mi != null else 12)
			if im != null:
				var dv: int = 0 if int(M.v) >= 50 else (2 if int(M.v) >= 20 else 4)   # sin vigor, más baja
				o.append(["@", im, cx - (im.get_width() >> 1), top + 5 - im.get_height() + dv, clip])
			if mi != null:
				o.append(["@", mi, cx - (mi.get_width() >> 1), yb - mi.get_height(), clip])
			for e in int(M.e):   # los esquejes listos, en un vaso al pie de la maceta
				o.append([cx + 10 + (e % 2) * 3, yb - 4 - (e >> 1) * 3, 2, 2, "#6ac04a"])
			o.append_array([[cx - 16, yb + 2, 32, 3, "#16161c"], [cx - 16, yb + 2, Datos.jsround(32 * clampf(float(M.v) / 100.0, 0, 1)), 3, "#58c060" if int(M.v) >= 50 else "#e0a040"]])
		else:   # el hueco: el sitio de la maceta, marcado en el suelo
			o.append_array([[cx - 8, yb - 1, 16, 1, "#8a8e96"], [cx - 8, yb - 12, 1, 11, "#8a8e96"], [cx + 7, yb - 12, 1, 11, "#8a8e96"]])
	if not on:   # la noche del temporizador: la carpa a oscuras
		o.append([x0, 0, 240, MAD_H, "rgba(4,4,10,0.72)"])
	var cx: int = st[clampi(int(V.i), 0, st.size() - 1)][0]   # el sitio elegido
	o.append_array([[cx - 20, 22, 40, 1, "#f8d040"], [cx - 20, MAD_H - 1, 40, 1, "#f8d040"], [cx - 20, 22, 1, MAD_H - 22, "#f8d040"], [cx + 19, 22, 1, MAD_H - 22, "#f8d040"]])
	return o

func talk_madres():
	var w = cuida_madres()
	if w == null:
		return
	var N: Dictionary = S.nave
	var dos: bool = int(D.MADRES.esq) + (1 if w.cui >= 4 else 0) > 1
	var t: String
	if N.ma.is_empty():
		t = K("La carpa está vacía. Tráeme una madre, una semilla o un esqueje de lo que quieras guardar, y te la cuido.")
	elif N.ma.size() > 1:
		t = T("{n} madres, a 18/6 y bien regadas. Cada mañana les saco dos esquejes; los tienes en la carpa.", {"n": N.ma.size()}) if dos else T("{n} madres, a 18/6 y bien regadas. Cada mañana les saco un esqueje; los tienes en la carpa.", {"n": N.ma.size()})
	else:
		t = K("Una madre, a 18/6 y bien regadas. Cada mañana les saco dos esquejes; los tienes en la carpa.") if dos else K("Una madre, a 18/6 y bien regadas. Cada mañana les saco un esqueje; los tienes en la carpa.")
	await say(t, w.n.to_upper())

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
	ops.append(K("Nada"))
	var c: int = await ask(T("Mesa {i}: {n}. {d}\n¿Los cambias? Los de ahora se los queda Arrieta.", {"i": i + 1, "n": D.FOCO_NAVE[k].n, "d": D.FOCO_NAVE[k].d}), ops)
	if c < 0 or c >= ks.size():
		return
	var F: Dictionary = D.FOCO_NAVE[ks[c]]
	if S.money < F.p:
		sfx("bad")
		await say(K("No te llega."))
		return
	S.money -= F.p
	N.f[i] = ks[c]
	sfx("coin")
	update_hud()
	await say(T("Arrieta cuelga los {n} en la mesa {i}. {d}", {"n": F.n, "i": i + 1, "d": F.d}) + ((" " + K("Con tanto foco, la nave se calienta: hará falta más extracción.")) if calor_nave() > float(D.EXTR_NAVE[int(N.ex)].cap) else ""))

# las mejoras de la nave (1.33, mejorasNave): la extracción y el riego, nivel a nivel
func _fila_mejora(L: Array, k: String, t: String) -> Dictionary:
	var a: Dictionary = L[int(S.nave[k])]
	var b = L[int(S.nave[k]) + 1] if int(S.nave[k]) + 1 < L.size() else null
	return {"label": "%s: %s" % [I18n.v(t), I18n.v(a.n)], "right": Datos.eur(b.p) if b else K("a tope"), "desc": T("Siguiente: {n}. {d}", {"n": b.n, "d": b.d}) if b else a.d}

func mejoras_nave() -> void:
	var N: Dictionary = S.nave
	var j := 0
	while true:
		var F := [_fila_mejora(D.EXTR_NAVE, "ex", K("Extracción")), _fila_mejora(D.RIEGO_NAVE, "rg", K("Riego"))]
		var Q := ["ex", "rg"]
		if Datos.CAL:
			var cu: Dictionary = D.CURADO_NAVE
			F.append({"label": "%s: %s" % [I18n.v(K("Curado")), T("{t} tarros", {"t": int(navc_cap() / float(D.CAMAROTE.tarro))})], "right": K("a tope") if int(navc().get("mj", 0)) else Datos.eur(cu.p), "desc": cu.d})
			Q.append("cur")
			if _nave_tope():
				var ds: Dictionary = D.DESPACHO
				F.append({"label": K("Despacho de lujo"), "right": K("hecho") if desp_ya() else Datos.eur(ds.p), "desc": ds.d})
				Q.append("desp")
		F.append({"label": K("Volver"), "desc": ""})
		j = await menu(F, {"cls": "full", "title": K("MEJORAS DE LA NAVE"), "title2": T("Nave {n}", {"n": nivel_nave()}), "desc": true, "initial": j})
		if j < 0 or j >= Q.size():
			return
		if Q[j] == "cur" or Q[j] == "desp":
			await _mejora_cal(Q[j])
			continue
		var L: Array = D.RIEGO_NAVE if j else D.EXTR_NAVE
		var k := "rg" if j else "ex"
		if int(N[k]) + 1 >= L.size():
			continue
		var b: Dictionary = L[int(N[k]) + 1]
		if await ask(T("{n}: {d} {p}, montado hoy mismo.", {"n": b.n, "d": b.d, "p": Datos.eur(b.p)}), [K("Comprar"), K("No")]) != 0:
			continue
		if S.money < b.p:
			sfx("bad")
			await say(K("No te llega."))
			continue
		S.money -= b.p
		N[k] = int(N[k]) + 1
		sfx("coin")
		update_hud()
		montar_nave()
		await say(T("Arrieta y los suyos montan {a}. La nave ya es una nave {n}.", {"a": b.a, "n": nivel_nave()}))

# MAESTRO [8]: la nave a tope (extracción y riego) abre el despacho de lujo
func _nave_tope() -> bool:
	return int(S.nave.ex) + 1 >= D.EXTR_NAVE.size() and int(S.nave.rg) + 1 >= D.RIEGO_NAVE.size()

func _mejora_cal(q: String) -> void:
	var M: Dictionary = D.CURADO_NAVE if q == "cur" else D.DESPACHO
	if (q == "cur" and int(navc().get("mj", 0))) or (q == "desp" and desp_ya()):
		return
	if await ask(T("{n}: {d} {p}, montado hoy mismo.", {"n": M.n, "d": M.d, "p": Datos.eur(M.p)}), [K("Comprar"), K("No")]) != 0:
		return
	if S.money < M.p:
		sfx("bad")
		await say(K("No te llega."))
		return
	S.money -= M.p
	if q == "cur":
		navc().mj = 1
	else:
		S.desp = {"d": S.day, "money": 0, "buds": {}}
	sfx("coin")
	update_hud()
	montar_nave()
	if q == "cur":
		await say(T("Arrieta cuelga dos estanterías más de tarros: ya caben {g} g curando en la nave.", {"g": Datos.jsround(navc_cap())}))
	else:
		await say(K("Arrieta y los suyos dejan el despacho de lujo: tarima, sofá, la pared de monitores con las cámaras de tus locales y una caja fuerte de las grandes."))

# MAESTRO [8]: la caja fuerte del despacho de lujo (fuera de la nave: la redada no la encuentra)
func caja_desp() -> void:
	if not desp_ya():
		return
	var Ds: Dictionary = S.desp
	var C: Dictionary = D.DESPACHO.caja
	while true:
		var g := 0.0
		for k in Ds.buds:
			g += float(Ds.buds[k].g)
		var ops := [K("Guardar dinero"), K("Sacar dinero"), K("Guardar cogollos"), K("Sacar cogollos"), K("Nada")]
		var o: int = await ask(T("La caja del despacho: {m} y {g} g (caben {cm} y {cg} g).", {"m": Datos.eur(Ds.money), "g": Datos.jsround(g), "cm": Datos.eur(C.money), "cg": int(C.g)}), ops)
		if o < 0 or o == 4:
			return
		if o == 0:
			var mx: int = int(min(S.money, float(C.money) - float(Ds.money)))
			if mx <= 0:
				await say(K("No hay nada que guardar o la caja está llena."))
				continue
			var q = await cuanto(K("¿Cuánto guardas?"), mx, [1000, 5000, 20000, 50000, 100000], func(v): return Datos.eur(v))
			if int(q) <= 0:
				continue
			S.money -= int(q)
			Ds.money = float(Ds.money) + int(q)
		elif o == 1:
			if float(Ds.money) <= 0:
				await say(K("No hay dinero en la caja."))
				continue
			var q = await cuanto(K("¿Cuánto sacas?"), int(Ds.money), [1000, 5000, 20000, 50000, 100000], func(v): return Datos.eur(v))
			if int(q) <= 0:
				continue
			Ds.money = float(Ds.money) - int(q)
			S.money += int(q)
		elif o == 2:
			var ks := []
			for k in S.buds:
				if float(S.buds[k].g) > 0:
					ks.append(k)
			if ks.is_empty() or g >= float(C.g):
				await say(K("No hay nada que guardar o la caja está llena."))
				continue
			var e: int = await menu(ks.map(func(k): return {"label": lot_nombre(k), "right": "%d g" % int(S.buds[k].g)}), {"title": K("¿Qué guardas?")})
			if e < 0:
				continue
			var mg: int = int(min(float(S.buds[ks[e]].g), float(C.g) - g))
			mover_lote(S.buds, Ds.buds, ks[e], mg)
			await say(T("Guardas {g} g en la caja del despacho.", {"g": mg}))
		elif o == 3:
			var ks: Array = Ds.buds.keys()
			if ks.is_empty():
				await say(K("No hay cogollos en la caja."))
				continue
			var e: int = await menu(ks.map(func(k): return {"label": lot_nombre(k), "right": "%d g" % int(Ds.buds[k].g)}), {"title": K("¿Qué sacas?")})
			if e < 0:
				continue
			mover_lote(Ds.buds, S.buds, ks[e], float(Ds.buds[ks[e]].g))
		update_hud()

func estante_nave() -> void:
	var N: Dictionary = S.nave
	var ops := []
	var dm := ""
	var dob := ""
	if S.items.get("fert", 0):
		dm = T("Dejar MEATZA ×{n}", {"n": int(S.items.fert)})
		ops.append(dm)
	if S.items.get("ofert", 0):
		dob = T("Dejar ORTUA BIO ×{n}", {"n": int(S.items.ofert)})
		ops.append(dob)
	if S.map == "nave" and puertas_int("nave").size():   # 1.52.1: el escritorio está en el despacho; la nave se ordena desde la nave
		ops.append(K("Ordenar la nave"))
	ops.append(K("Nada"))
	var da := {"m": dosis_txt(N.ab.m), "o": dosis_txt(N.ab.o)}
	var oi: int = await ask(T("La estantería de los abonos: MEATZA FLORACIÓN ×{m} · ORTUA BIO FLORACIÓN ×{o}. Cada mesa con abono gasta menos de una dosis al día.", da) if int(N.rg) >= 2 else T("La estantería de los abonos: MEATZA FLORACIÓN ×{m} · ORTUA BIO FLORACIÓN ×{o}. Cada mesa con abono gasta una dosis al día.", da), ops)
	var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
	if dm != "" and op == dm:
		N.ab.m += S.items.fert
		S.items.fert = 0
		sfx("sel")
	elif dob != "" and op == dob:
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
			await say(T("En el secadero cuelgan {g} secándose: mañana se pueden descolgar.", {"g": g_txt(cu)}))
		else:
			await say(K("El secadero está vacío. Cada mesa se cosecha entera al final de su ciclo y se seca aquí un día.") if int(D.NAVE.seca) == 1 else T("El secadero está vacío. Cada mesa se cosecha entera al final de su ciclo y se seca aquí {n} días.", {"n": int(D.NAVE.seca)}))
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
		if staff_ok() and String(S.nave.get("oz", "")) == "sala":   # MAESTRO [6]: el ozono en la sala quema los terpenos
			S.buds[Me.k].oz = 1
		Me.g = Datos.jsround((Me.g - q) * 10) / 10.0
		lleva += q
	if not lleva:
		await say(K("No te cabe nada más en la mochila."))
		return
	sfx("get")
	update_hud()
	await say(T("Descuelgas {g} del secadero.", {"g": g_txt(lleva)}) + ((" " + T("Quedan {g}: no te caben.", {"g": g_txt(nave_stock() - cu)})) if nave_stock() - cu >= 1 else "") + ((" " + T("Siguen colgados {g}, secándose.", {"g": g_txt(cu)})) if cu >= 1 else ""))

func _filas_escritorio() -> Array:
	var N: Dictionary = S.nave
	var rows := []
	for i in N.m.size():
		var Me = N.m[i]
		var w = navero_de(i)
		var ab: String = D.ABONO_MESA[int(Me.abo)] if Me else ""
		var det := ""
		if Me:
			var ab_ := I18n.v(ab)
			var da := {"ab": ab_.substr(0, 1).to_upper() + ab_.substr(1), "co": cosecha_txt(Me), "c": int(Me.get("n", 0)) + 1, "g": g_txt(Me.g)}
			if Me.get("h") != null:
				da.h = g_txt(Me.h.g)
				det = " " + T("{ab} · {co} · ciclo {c} · en el secadero, {g} y {h} secándose.", da)
			else:
				det = " " + T("{ab} · {co} · ciclo {c} · en el secadero, {g}.", da)
		rows.append({"label": T("Mesa {i} · {n}", {"i": i + 1, "n": strain(lot_sid(Me.k)).n if Me else K("vacía")}), "right": D.FASE_MESA[fase_mesa(i)] if Me else "",
			"desc": (T("La cuida {n}.", {"n": w.n}) if w else K("Nadie la cuida.")) + " " + I18n.v(D.FOCO_NAVE[N.f[i]].n) + "." + det})
	rows.append({"label": K("Estantería"), "right": T("{m} + {o} dosis", {"m": dosis_txt(N.ab.m), "o": dosis_txt(N.ab.o)}), "desc": K("MEATZA FLORACIÓN y ORTUA BIO FLORACIÓN: menos de una dosis al día por mesa con abono.") if int(N.rg) >= 2 else K("MEATZA FLORACIÓN y ORTUA BIO FLORACIÓN: una dosis al día por mesa con abono.")})
	var E: Dictionary = D.EXTR_NAVE[int(N.ex)]
	var so := sofoco_nave()
	rows.append({"label": K("Clima"), "right": T("{a} de {b}", {"a": n(calor_nave()), "b": n(E.cap)}), "desc": T("El calor de los focos encendidos y lo que saca la extracción ({n}).", {"n": E.n}) + ((" " + T("Hace demasiado calor: las mesas dan un {p} % menos.", {"p": int(Datos.jsround((1 - so) * 100))})) if so < 1 else "")})
	if S.map == "nave":   # 1.52.1 (lo pidió el usuario): solo con el escritorio en la nave; con el despacho, desde la estantería o el riego de la nave
		rows.append({"label": K("Ordenar la nave"), "right": "", "desc": K("Mover las mesas y el tanque del riego: la manguera va del tanque a cada mesa por el suelo libre. Pulsa A.")})   # 1.37 (12d-orden)
	rows.append({"label": K("La gente"), "right": T("{n} aquí", {"n": de_la_nave().size()}), "desc": K("Quién cuida cada mesa y las madres: cambiarlos de mesa, una prima o un curso. Pulsa A.")})   # 1.34
	rows.append({"label": K("Mejoras"), "right": T("Nave {n}", {"n": nivel_nave()}), "desc": T("Extracción: {e}. Riego: {r}. Pulsa A para mejorarlas.", {"e": E.n, "r": D.RIEGO_NAVE[int(N.rg)].n})})
	if staff_ok():   # MAESTRO [6]: el olor, la seguridad y los monitores
		rows.append({"label": K("El olor"), "right": T("carbón {p} %", {"p": int(carbon(N))}) if int(N.ex) else "", "desc": olor_txt() + " " + K("Pulsa A.")})
		rows.append({"label": K("Seguridad"), "right": "", "desc": K("Puertas blindadas, alarmas, perros y cámaras para la nave y los locales. Pulsa A.")})
		rows.append({"label": K("Monitores"), "right": "", "desc": K("Lo que ven las cámaras de cada local. Pulsa A.")})
	return rows

func escritorio_nave() -> void:
	var i := 0
	while true:
		var rows := _filas_escritorio()
		i = await menu(rows, {"cls": "full", "title": K("LA NAVE"), "title2": T("{e} al día", {"e": Datos.eur(D.NAVE.dia)}), "desc": true, "initial": i})
		var l: String = rows[i].label if i >= 0 else ""
		if l == "Mejoras":
			await mejoras_nave()
		elif l == "La gente":
			await gente_nave()
		elif l == "Ordenar la nave":
			await ordenar("nave")
		elif l == "El olor":
			await olor_menu()
		elif l == "Seguridad":
			await seguridad_menu()
		elif l == "Monitores":
			await monitores()
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
			await say(K("En la nave no trabaja nadie. Pon a tu gente desde el móvil: MÓVIL → PLANTILLA."))
			return
		var rows := []
		for w in W:
			rows.append({"label": w.n, "right": K("madres") if w.rol == "madres" else T("mesa {n}", {"n": int(w.mesa) + 1}), "desc": ficha_gente(w) + ". " + rol_desc(w)})
		rows.append({"label": K("Volver"), "desc": ""})
		i = await menu(rows, {"cls": "full", "title": K("LA GENTE DE LA NAVE"), "title2": T("{n} trabajando", {"n": W.size()}), "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0 or i >= W.size():
			return
		var w: Dictionary = W[i]
		var ops := []
		if w.rol == "nave":
			ops.append(K("Cambiar de mesa"))
		var pr := T("Prima · {e}", {"e": Datos.eur(D.MANDO.prima)})
		var cs := T("Curso · {e}", {"e": Datos.eur(D.MANDO.curso)})
		ops.append_array([pr, cs, K("Nada")])
		var oi: int = await ask(T("{w} · {f} · {s}", {"w": w.n, "f": ficha_gente(w), "s": K("las madres") if w.rol == "madres" else T("la mesa {n}", {"n": int(w.mesa) + 1})}), ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "Cambiar de mesa":
			var ms := []
			for j in int(D.NAVE.max):
				if j != int(w.mesa):
					ms.append(j)
			var lb := []
			for j in ms:
				var o = navero_de(j)
				lb.append(T("Mesa {n} · con {o}", {"n": j + 1, "o": o.n}) if o != null else T("Mesa {n}", {"n": j + 1}))
			lb.append(K("Nada"))
			var c: int = await ask(T("¿A qué mesa pasa {n}?", {"n": w.n}), lb)
			if c < 0 or c >= ms.size():
				continue
			var o = navero_de(ms[c])
			if o != null:
				o.mesa = w.mesa
			w.mesa = ms[c]
			sfx("sel")
			await say(T("{a} pasa a la mesa {i} y {b}, a la {j}.", {"a": w.n, "i": int(w.mesa) + 1, "b": o.n, "j": int(o.mesa) + 1}) if o != null else T("{a} pasa a la mesa {i}.", {"a": w.n, "i": int(w.mesa) + 1}))
		elif op == pr:
			await prima(w)
		elif op == cs:
			await curso(w)

func talk_navero(i: int):
	var w = navero_de(i)
	if not w:
		return
	var Me = S.nave.m[i] if S.get("nave") != null else null
	var f := fase_mesa(i)
	var t: String
	if not Me:
		t = K("Mi mesa está vacía. Plántame algo y la saco adelante.")
	else:
		t = T("La {nom} va bien: {f}, {c}. Cuando acaba la flor la corto entera, la cuelgo en el secadero y vuelvo a empezar con los esquejes que saqué antes de pasarla a 12/12.", {"nom": strain(lot_sid(Me.k)).n, "f": D.FASE_MESA[f], "c": cosecha_txt(Me)}) + ((" " + K("Se ha acabado el abono de la estantería.")) if Me.abo and float(S.nave.ab["m" if Me.abo == 1 else "o"]) < float(D.RIEGO_NAVE[int(S.nave.rg)].dosis) else "") \
			+ ((" " + K("Y aquí dentro hace un calor que no veas: hace falta más extracción.")) if sofoco_nave() < 1 else "")
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
	var N := K("PORTERO")
	if await ask(T("La entrada, {e}. Se paga una vez por noche.", {"e": Datos.eur(D.DISCO.entrada)}), [K("Pagar"), K("No")], N) != 0:
		return false
	if S.money < D.DISCO.entrada:
		sfx("bad")
		await say(K("Sin entrada no se pasa."), N)
		return false
	S.money -= int(D.DISCO.entrada)
	noche_gaua()
	sfx("coin")
	update_hud()
	return true

func echar_disco():
	await say(K("Las seis. Se encienden las luces y el portero echa a todo el mundo."), K("PORTERO"))
	await warp({"to": "ensanche", "x": 38, "y": 9, "dir": "down"})

func talk_gorila():
	await say(K("Abrimos a las once de la noche. Hasta las seis.") if not disco_abierta() else (K("Ya has pagado esta noche. Pasa.") if noche_ya() else T("La entrada, {e}. En la puerta.", {"e": Datos.eur(D.DISCO.entrada)})), K("PORTERO"))

# la barra, el DJ y la RRPP, solo con GAUA abierta (1.31): si te quedas quieto pasadas las seis, el portero te echa al hablar con ellos
func talk_barra():
	if not disco_abierta():
		await echar_disco()
		return
	var N := K("CAMARERA")
	var X := noche_gaua()
	var c: int = await ask(K("¿Qué te pongo?"), [T("Una copa · {e}", {"e": Datos.eur(D.DISCO.copa)}), T("Invitar a una ronda · {e}", {"e": Datos.eur(D.DISCO.ronda)}), K("Nada")], N)
	if c == 0:
		if X.copas >= D.DISCO.copaMax:
			await say(K("Por hoy ya vale. Agua, si quieres."), N)
			return
		if S.money < D.DISCO.copa:
			sfx("bad")
			await say(K("Sin dinero no hay copa."), N)
			return
		S.money -= int(D.DISCO.copa)
		X.copas += 1
		if X.copas == 1:
			confia("gaua", 1)
		advance_time(10)
		sfx("coin")
		update_hud()
		await say([K("Un gin-tonic con mucho hielo."), K("Otra. La música sube."), K("La tercera. Mejor que sea la última.")][int(X.copas) - 1])
	elif c == 1:
		if X.ronda:
			await say(K("Ya has invitado esta noche. Con una, ya te conocen."), N)
			return
		if S.money < D.DISCO.ronda:
			sfx("bad")
			await say(K("No te llega para la ronda."), N)
			return
		S.money -= int(D.DISCO.ronda)
		X.ronda = 1
		S.rep += 1
		confia("gaua", 3)
		advance_time(10)
		sfx("coin")
		update_hud()
		await say(K("Invitas a la barra entera. Medio local brinda por ti."))

func talk_dj():
	if not disco_abierta():
		await echar_disco()
		return
	var c: int = await ask(pick([K("¿Qué tal suena?"), K("Esta noche se llena.")]), [K("Bailar"), K("Pedir una canción"), K("Nada")], K("DJ"))
	if c == 0:
		await bailar()
	elif c == 1:
		sfx("sel")
		await say(pick([K("Te la pongo después de esta."), K("¿Esa? Hace años que no la pincho. Venga, va."), K("Esa no la tengo. Te pongo algo parecido.")]), K("DJ"))

# bailar (una vez por noche): media hora y, la mitad de las veces, alguien te pide el número (un pijo para la agenda)
func bailar() -> void:
	var X := noche_gaua()
	if X.baile:
		await say(K("Ya has bailado esta noche. Las piernas no dan para más."))
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
		await say(T("Bailas media hora sin parar. {n} te pide el número: «Si tienes de lo bueno, llámame».", {"n": nf}))
		return
	await say(K("Bailas media hora sin parar. Sales de la pista con la camiseta empapada."))

# el reservado (una vez por noche): una hora y la RRPP te presenta a un cliente VIP (CTYPES.vip) para la agenda
func talk_rrpp():
	if not disco_abierta():
		await echar_disco()
		return
	var N := K("RRPP")
	var X := noche_gaua()
	if X.mesa:
		await say(K("Disfruta del reservado. Si conoces a alguien que merezca la pena, me lo presentas."), N)
		return
	if S.fijos.size() >= D.FIJOS_MAX:   # 1.31: antes de cobrar
		await say(K("Tu agenda ya está llena. Cuando tengas sitio para alguien que importa, vuelve."), N)
		return
	if await ask(T("El reservado: sofá, mesa y botella, {e} la noche. Ahí se sienta la gente que importa.", {"e": Datos.eur(D.DISCO.mesa)}), [K("Reservar"), K("No")], N) != 0:
		return
	if S.money < D.DISCO.mesa:
		sfx("bad")
		await say(K("Para el reservado hace falta dinero. Otra noche."), N)
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
	await say(T("Una hora en el reservado. La RRPP te presenta a {n}: «Me han dicho que lo tuyo es de lo mejor. Llámame». Apuntas su número.", {"n": nv}))
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
	await say(D.DISCO_CAL.vip[(i + S.day) % D.DISCO_CAL.vip.size()], K("GENTE"))

func talk_baila(i: int):
	await say(D.BAILA[i], K("GENTE"))

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
	return T("{x} de {n}", {"x": D.EXTR[q.x].n, "n": strain(q.k).n}) if q.x != "" else strain(q.k).n

func comprar_mercado(id: String, N: String, pool: Array) -> void:
	var TM: Dictionary = D.MERCADO[tipo_mer(id)]
	var l: Array = mercado_lista(id, pool).filter(func(q): return int(q.g) >= int((TM.gx if q.x != "" else TM.g)[0]))
	if l.is_empty():
		await say(K("Hoy ya está todo repartido. Mañana entra más."), N)
		return
	var it := l.map(func(q): return {"label": nombre_mer(q), "right": "%d g · %s %% · %s €/g" % [int(q.g), Datos.pct(q.thc), _dos(precio_mer(id, q))], "sw": "#d89a18" if q.x != "" else strain(q.k).c, "ic": ic_cog(q.k),
		"desc": T("{n}: {g} g a {t} % de THC, a {p} el gramo.", {"n": nombre_mer(q), "g": int(q.g), "t": Datos.pct(q.thc), "p": _dos(precio_mer(id, q)) + " €"})})
	it.append({"label": K("Nada"), "desc": K("No comprar nada hoy.")})
	# A lo ancho, con el nombre entero (en la columna de la derecha se cortaba: «Beldi», «Zam»…)
	var i: int = await menu(it, {"cls": "full", "title": K("Hoy tenemos"), "desc": true} if Datos.CAL else {"cls": "right", "title": K("Hoy tenemos")})
	if i < 0 or i >= l.size():
		return
	var q: Dictionary = l[i]
	var pg := precio_mer(id, q)
	var ops := []
	for g in (TM.gx if q.x != "" else TM.g):
		if g <= int(q.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(Datos.jsround(g * pg))])
	o.append(K("Nada"))
	var j: int = await ask(T("{n}, al {t} % de THC. ¿Cuánto te llevas?", {"n": nombre_mer(q), "t": Datos.pct(q.thc)}), o, N)
	if j < 0 or j >= ops.size():
		return
	var g: int = ops[j]
	var e := Datos.jsround(g * pg)
	if S.money < e:
		sfx("bad")
		await say(K("Sin dinero no hay trato."), N)
		return
	if libre_mochila() < g:
		await say(K("No te cabe en la bolsa."), N)
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
	toast(T("Comprado: {g} g de {n}", {"g": g, "n": nombre_mer(q)}), 1400)

# el almacén del club (1.45, de presidente): lo que dejas en sus estanterías (S.aso.al: buds y rosin, hasta MERCADO.alm.g de flor)
# lo retiran los socios del dispensario cada mañana (aso_dia), MERCADO.alm.dia g de flor al día, a precio de dispensario
func alm_club(id := "rv") -> Dictionary:
	var A: Dictionary = S.mar if id == "muelle" else aso()   # MAESTRO [6]: el de KAIA, igual
	if not (A.get("al") is Dictionary):
		A.al = {"buds": {}, "rosin": {}, "tot": 0}
	return A.al

func alm_g(id := "rv") -> float:
	var al := alm_club(id)
	var t := 0.0
	for k in al.buds:
		t += float(al.buds[k].g)
	for k in al.rosin:
		t += float(al.rosin[k].g) / D.ROSIN.rend
	return t

func almacen_club(id := "rv") -> void:
	if id == "rv" and not aso().pres:
		await say(K("El almacén del club, con llave. La tiene el presidente."))
		return
	while true:
		var al := alm_club(id)
		var ops := [K("Guardar"), K("Sacar"), K("Nada")]
		var c: int = await ask(T("EL ALMACÉN DEL CLUB · {a} de {b} ocupados. Lo de aquí lo retiran los socios del dispensario, {d} g al día; en total, {t}.", {"a": g_txt(alm_g(id)), "b": g_txt(D.MERCADO.alm.g), "d": int(D.MERCADO.alm.dia), "t": Datos.eur(int(al.tot))}), ops)
		if c == 0:
			var lots := lotes_venta(1, 1)
			if lots.is_empty():
				await say(K("No llevas nada encima."))
				continue
			var it := lots.map(venta_item)
			it.append({"label": K("Nada")})
			var i: int = await menu(it, {"cls": "right", "title": K("¿Qué guardas?")})
			if i < 0 or i >= lots.size():
				continue
			var lt: Array = lots[i]
			var x := es_extr(lt)
			var b: Dictionary = lt[1]
			var cabe: float = (float(D.MERCADO.alm.g) - alm_g(id)) * (D.ROSIN.rend if x else 1.0)
			var g: float = minf(float(b.g), floorf(cabe * 10) / 10.0)
			if g < .1:
				await say(K("Las estanterías están llenas."))
				continue
			var L: Dictionary = al.rosin if x else al.buds
			var k: String = lt[0]
			if L.has(k):
				L[k].thc = (float(L[k].thc) * float(L[k].g) + float(b.thc) * g) / (float(L[k].g) + g)
				L[k].g = float(L[k].g) + g
			else:
				L[k] = {"g": g, "thc": float(b.thc), "q": calidad(b, not x)}
			usa_lote(lt, g)
			sfx("sel")
			toast(T("Al almacén: {g}", {"g": g_txt(g)}), 1200)
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
				await say(K("El almacén está vacío."))
				continue
			it.append({"label": K("Nada")})
			var i: int = await menu(it, {"cls": "right", "title": K("¿Qué sacas?")})
			if i < 0 or i >= ks.size():
				continue
			var k: String = ks[i][0]
			var x: bool = ks[i][1]
			var b: Dictionary = (al.rosin if x else al.buds)[k]
			var g: float = minf(float(b.g), floorf(libre_mochila()))
			if g < .1:
				await say(K("No te cabe en la bolsa."))
				continue
			if x:
				add_rosin(k, g, b.thc)
			else:
				add_buds(k, g, b.thc)
			b.g = float(b.g) - g
			if b.g < .1:
				(al.rosin if x else al.buds).erase(k)
			sfx("sel")
			toast(T("Sacado: {g}", {"g": g_txt(g)}), 1200)
		else:
			return

func almacen_dia(id := "rv") -> void:
	var A: Dictionary = S.mar if id == "muelle" else aso()
	if (id == "rv" and not A.pres) or not (A.get("al") is Dictionary):
		return
	var al := alm_club(id)
	var fc: float = float(D.MAR.kaia.f) if id == "muelle" else float(D.ASO.f)
	var r: float = float(D.MERCADO.alm.dia)
	var e := 0.0
	for x in [false, true]:
		var L: Dictionary = al.rosin if x else al.buds
		for k in L.keys():
			if r <= 0:
				break
			var b: Dictionary = L[k]
			var g: float = minf(float(b.g), r * (D.ROSIN.rend if x else 1.0))
			var pg: float = (precio_extr(k, b.thc, "club") if x else precio_club(b.thc)) * float(b.get("q", 1)) * fc
			e += g * pg
			r -= g / D.ROSIN.rend if x else g
			b.g = float(b.g) - g
			if b.g < .1:
				L.erase(k)
	if e > 0:
		var ee := Datos.jsround(e)
		al.tot = int(al.tot) + ee
		if id == "muelle" and S.mar.get("lic"):   # KAIA con licencia, por el banco
			abono_banco(ee, K("KAIA · dispensario"))
		else:
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
		await say(K("Junto a la foto de la tía Maite, un hombre mayor con las rastas y la barba canas no te quita ojo."))

func talk_delroy() -> void:
	var A := aso()
	var N: String = D.DELROY.n
	if not A.tio:
		await talk(N, D.DELROY.revela)
		A.tio = true
		confia("delroy", 5)
	var c: int = await ask(K("¿Qué tal, presidente?") if A.pres else K("Dime, sobrino."), [K("Charlar"), K("El dispensario") if A.pres else K("La presidencia"), K("Nada")], N)
	if c == 0:
		await say(pick(D.DELROY.charla), N)
	elif c == 1:
		if A.pres and staff_ok():   # MAESTRO [6]: el panel, el mismo que el de KAIA
			await panel_club("rv", N)
		elif A.pres:
			await dispensario_aso()
		else:
			await presidencia_aso()

func presidencia_aso() -> void:
	var A := aso()
	var N: String = D.DELROY.n
	var O: Dictionary = D.ASO
	if A.asam:   # con la asamblea pendiente, todavía se puede refundar
		if await ask(T("La asamblea es el {f}, por la mañana. Habla con la gente del barrio: cada amigo trae votos. O la refundas ya, por {e}.", {"f": Datos.fd(int(A.asam), S.day), "e": Datos.eur(O.refunda)}), [K("Refundarla"), K("Nada")], N) != 0:
			return
	else:
		var c: int = await ask(T("Hacen falta {m} votos de {v}. Hoy tendrías {h}. O pagas {e} de deudas y registro y la refundas tú.", {"m": int(O.mayoria), "v": int(O.votos), "h": votos_aso(), "e": Datos.eur(O.refunda)}), [K("Presentarme"), K("Refundarla"), K("Nada")], N)
		if c == 0:
			if S.day < int(A.otra):
				await say(T("Hasta el {f} no hay otra asamblea. Gánate al barrio mientras.", {"f": Datos.fd(int(A.otra), S.day)}), N)
				return
			A.asam = int(S.day) + int(O.dias)
			sfx("sel")
			await say(T("Apuntado. La asamblea, el {f}. {r} también se presenta.", {"f": Datos.fd(int(A.asam), S.day), "r": O.rival}), N)
			return
		if c != 1:
			return
	if S.money < int(O.refunda):
		sfx("bad")
		await say(T("Sin los {e} no hay refundación.", {"e": Datos.eur(O.refunda)}), N)
		return
	S.money -= int(O.refunda)
	A.pres = true
	A.asam = 0
	confia("delroy", 10)
	confia("rv", 10)
	update_hud()
	sfx("get")
	await say(K("Pagas las deudas de la gestora y el registro. La asociación vuelve a nacer, con tus estatutos. Maite estaría orgullosa."), N)

# el dispensario: un lote a la vez; dice cuánto queda y lo que llevas
func dispensario_aso() -> void:
	var A := aso()
	if Datos.CAL and not await vista_disp(A, "lote"):   # (lo pidió el usuario): en sus vitrinas
		return
	var N: String = D.DELROY.n
	var O: Dictionary = D.ASO
	var L = A.lote
	if L is Dictionary:
		await say(T("En el dispensario quedan {g} de {n}, a {p} € el gramo. Llevas {t}.", {"g": g_txt(L.g), "n": extr_nombre(L.k, true) if L.get("x") else lot_nombre(L.k), "p": _dos(L.pg), "t": Datos.eur(L.tot)}), N)
		return
	var VX: Dictionary = D.VENTA_EXTR
	var lots := lotes_venta(O.g[0], VX.club_g[0])
	if lots.is_empty():
		await say(T("Déjame {a} g o más y los socios lo retiran, {d} g al día. El dinero, a tu buzón.", {"a": int(O.g[0]), "d": int(O.dia)}), N)
		return
	var it := lots.map(venta_item)
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Qué lote?")})
	if i < 0 or i >= lots.size():
		return
	var l: Array = lots[i]
	var x := es_extr(l)
	var k: String = l[0]
	var b: Dictionary = l[1]
	var pg := Datos.jsround((precio_extr(k, b.thc, "club") if x else precio_club(b.thc)) * calidad(b, not x) * float(O.f) * 100) / 100.0
	var ops := []
	for g in (VX.club_g if x else O.g):
		if g <= floor(b.g):
			ops.append(int(g))
	var o := []
	for g in ops:
		o.append("%d g · %s" % [g, Datos.eur(g * pg)])
	o.append(K("Nada"))
	var j: int = await ask(T("{n} a {p} € el gramo para los socios. ¿Cuánto dejas?", {"n": venta_nombre(l), "p": _dos(pg)}), o, N)
	if j < 0 or j >= ops.size():
		return
	usa_lote(l, ops[j])
	A.lote = {"k": k, "g": ops[j], "pg": pg, "tot": 0}
	if Datos.CAL:   # la vitrina enseña su THC
		A.lote.thc = float(b.thc)
	if x:   # 1.43.7: de una extracción retiran VENTA_EXTR.dia de lo de la flor
		A.lote.x = true
	sfx("sel")
	await say(T("Al dispensario. Cada mañana, {g} para los socios.", {"g": g_txt(O.dia * (VX.dia if x else 1.0))}), N)

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
		var t: String = T("¡{v} votos de {t}! Eres el presidente de la asociación, sobrino. Como tu tía.", {"v": v, "t": int(O.votos)}) if gana else T("{v} votos de {t}: gana {r}. Gánate al barrio y preséntate otra vez desde el {f}.", {"v": v, "t": int(O.votos), "r": O.rival, "f": Datos.fd(int(A.otra), S.day)})
		queue("aso", func(): await talk(K("SMS · DELROY"), [t]))
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
		queue("asoLote", func(): await talk(K("SMS · DELROY"), [T("Se acabó lo del dispensario: {e} en total, en tu buzón.", {"e": Datos.eur(L.tot)})]))   # i18n-no: «asoLote» es la clave de la cola
