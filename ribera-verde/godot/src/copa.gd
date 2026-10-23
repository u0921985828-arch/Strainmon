# MAESTRO [5] (lo que faltaba, con Datos.CAL): las familias de la CannaDex (FAMILIAS, S.cult: lo cosechado; la familia entera da su
# bono al cultivo, Cultivo.fam), la CannaCup por calendario (CUP: el 15 de marzo, junio, septiembre y diciembre, desde el capítulo 7,
# con el jurado en la plaza; se presenta un tarro curado del todo y puntúa el THC y el perfil de la edición; el podio da dinero,
# trofeo y prestigio, S.prest, que piden los clubs VIP de Hiriburu) y la potencia contratada (ENERGIA: pasarse en el piso o en la
# nave deja firma térmica, calor, salvo lo que cubren las placas y el generador insonorizado, S.ener).
extends "res://src/metro.gd"

# ---------- la CannaDex por familias ----------
func cult_apunta(sid: String) -> void:
	if not Datos.CAL:
		return
	if not (S.get("cult") is Dictionary):
		S.cult = {}
	if S.cult.has(sid):
		return
	var antes := {}
	for k in D.FAMILIAS:
		antes[k] = Cultivo.fam_llena(S, k)
	S.cult[sid] = int(S.day)
	for k in D.FAMILIAS:
		if not antes[k] and Cultivo.fam_llena(S, k):
			var F: Dictionary = D.FAMILIAS[k]
			var t: String = T("CannaDex: {n}, completa. {b}", {"n": I18n.v(String(F.n)), "b": fam_bono_txt(F)})
			queue("fam" + k, func():
				sfx("enc")
				await say(t), [["", [t]]])

func fam_bono_txt(F: Dictionary) -> String:
	var v: int = Datos.jsround(float(F.v) * 100)
	match String(F.b):
		"g":
			return T("Para siempre: un {v} % más de cogollo en todas tus cosechas.", {"v": v})
		"thc":
			return T("Para siempre: un {v} % más de THC en todas tus cosechas.", {"v": v})
		"flor":
			return T("Para siempre: la floración, un {v} % más rápida.", {"v": v})
	return T("Para siempre: un {v} % menos de moho y botritis.", {"v": v})

func fam_cuenta() -> Array:   # [familias completas, total]
	var n := 0
	for k in D.FAMILIAS:
		if Cultivo.fam_llena(S, k):
			n += 1
	return [n, D.FAMILIAS.size()]

func fam_menu() -> void:
	var i := 0
	var ks: Array = D.FAMILIAS.keys()
	while true:
		var items := []
		for k in ks:
			var F: Dictionary = D.FAMILIAS[k]
			var c := 0
			var l := []
			for sid in F.s:
				var ya: bool = S.get("cult") is Dictionary and S.cult.has(sid)
				if ya:
					c += 1
				l.append(("✓ " if ya else "· ") + (strain(sid).n if S.disc.get(sid) else "??????"))
			var ok: bool = c == F.s.size()
			items.append({"label": ("★ " if ok else "") + I18n.v(String(F.n)), "right": "%d/%d" % [c, F.s.size()],
				"desc": fam_bono_txt(F) + (T(" (conseguido)") if ok else T(" Cosecha todas:")) + "\n" + ", ".join(l)})
		items.append({"label": K("Salir"), "desc": K("Cada variedad cuenta al cosecharla, en casa o en la nave.")})
		var fc := fam_cuenta()
		i = await menu(items, {"cls": "full", "title": K("CANNADEX · FAMILIAS"), "title2": T("{a}/{b} · prestigio {p} · {t} trofeos", {"a": fc[0], "b": fc[1], "p": int(S.get("prest", 0)), "t": cup_trofeos().size()}), "desc": true, "initial": i})
		if i < 0 or i >= ks.size():
			return

# ---------- la CannaCup ----------
func cup_hoy() -> bool:
	return cup_es(int(S.day))

func cup_es(dia: int) -> bool:
	if not Datos.CAL or int(S.get("ch", 0)) < int(D.CUP.ch):
		return false
	var f := Datos.fecha(dia)
	return int(f.d) == int(D.CUP.dia) and float(f.m) in D.CUP.meses.map(func(x): return float(x))

func cup_ed(dia: int) -> int:
	var f := Datos.fecha(dia)
	return int(f.y) * 100 + int(f.m)

func cup_proxima() -> int:   # el día de la próxima edición (o hoy)
	var f := Datos.fecha(int(S.day))
	for dy in 2:
		for m in D.CUP.meses:
			var d := Datos.dia_de(int(f.y) + dy, int(m), int(D.CUP.dia))
			if d >= int(S.day):
				return d
	return int(S.day)

func cup_perfil(ed: int) -> Dictionary:
	var tps: Array = D.CUP.tipos
	return {"t": int(Datos.hash_str("cup|%d" % ed) % tps.size()), "a": D.AROMAS[Datos.hash_str("cupa|%d" % ed) % D.AROMAS.size()]}

func cup_perfil_txt(P: Dictionary) -> String:
	return T("una {t} de aroma {a}", {"t": I18n.v(String(D.CUP.tipos[P.t])), "a": P.a})

func tipo_de(sid: String) -> int:   # 0 sativa, 1 índica, 2 híbrida (como la cata)
	var ind := Datos.ind_de(S, sid)
	return 1 if ind >= 65 else (0 if ind <= 35 else 2)

func cup_rivales(ed: int) -> Array:
	var C: Dictionary = D.CUP
	var anos := maxi(0, int(ed / 100) - int(Datos.fecha(1).y))
	var r := []
	for j in C.rivales.size():
		var x := float(C.rival[0]) + float(Datos.hash_str("cupr%d|%d" % [j, ed]) % int((float(C.rival[1]) - float(C.rival[0])) * 10 + 1)) / 10.0 + float(C.subeY) * anos
		r.append([String(C.rivales[j]), x])
	return r

func cup_puntos(sid: String, b: Dictionary, P: Dictionary) -> float:
	var C: Dictionary = D.CUP
	var p: float = float(b.thc)
	if tipo_de(sid) == int(P.t):
		p += float(C.tipo)
	if aroma_de(sid) == String(P.a):
		p += float(C.aroma)
	if float(b.get("af", 0)) >= 1:
		p += float(C.af)
	return Datos.jsround(p * 10) / 10.0

func cup_trofeos() -> Array:
	return S.cup.get("tro", []) if S.get("cup") is Dictionary else []

func cup_aviso() -> void:   # en new_day: a CUP.aviso días y el mismo día
	if not Datos.CAL or int(S.get("ch", 0)) < int(D.CUP.ch):
		return
	var d := cup_proxima()
	var falta := d - int(S.day)
	if falta != 0 and falta != int(D.CUP.aviso):
		return
	var P := cup_perfil(cup_ed(d))
	var L := [T("Hoy es la CannaCup, en la plaza de Ribera Verde. Este trimestre se busca {p}.", {"p": cup_perfil_txt(P)}) if falta == 0 else T("El {d}, CannaCup en la plaza de Ribera Verde. Este trimestre se busca {p}.", {"d": Datos.fd(d, S.day), "p": cup_perfil_txt(P)}),
		T("Trae {g} g de un tarro curado del todo.", {"g": int(D.CUP.g)})]
	queue("cup", func(): await talk(K("SMS · ASOCIACIÓN"), L), [[K("SMS · ASOCIACIÓN"), L]])

func cup_marcas() -> Array:
	if not Datos.CAL or int(S.get("ch", 0)) < int(D.CUP.ch):
		return []
	return [{"d": cup_proxima(), "c": "#c0a020", "t": T("CannaCup en la plaza")}]

func talk_cup() -> void:
	var N := K("JURADO")
	var C: Dictionary = D.CUP
	var ed := cup_ed(int(S.day))
	var P := cup_perfil(ed)
	if not (S.get("cup") is Dictionary):
		S.cup = {"ed": {}, "tro": []}
	if S.cup.ed.has(str(ed)):
		await say(K("Ya has presentado tu tarro en esta edición. Vuelve el próximo trimestre."), N)
		return
	await talk(N, [K("Bienvenido a la CANNACUP de la asociación."), T("Este trimestre buscamos {p}. Cuenta el THC y, encima, el perfil.", {"p": cup_perfil_txt(P)}),
		T("Trae {g} g de un solo lote curado del todo, en tarro.", {"g": int(C.g)})])
	var lots := bud_lots(float(C.g)).filter(func(l): return float(l[1].get("cu", 0)) >= float(C.cu))
	if lots.is_empty():
		await say(K("Sin un tarro curado del todo no puedes competir. Cúralo y vuelve hoy mismo si te da tiempo."), N)
		return
	var it := lots.map(lot_item)
	it.append({"label": K("Todavía no")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Qué presentas?")})
	if i < 0 or i >= lots.size():
		return
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var sid := lot_sid(k)
	var pt := cup_puntos(sid, b, P)
	use_buds(k, float(C.g))
	var tab := cup_rivales(ed)
	tab.append([S.name if S.get("name") else K("Tú"), pt, true])
	tab.sort_custom(func(a, c): return a[1] > c[1] or (a[1] == c[1] and a.size() > c.size()))
	var pl := 0
	for j in tab.size():
		if tab[j].size() > 2:
			pl = j
	await fade(1)
	await wait(500)
	await fade(0)
	var L := []
	for j in tab.size():
		L.append("%d. %s · %s" % [j + 1, tab[j][0], Datos.pct(tab[j][1])])
	await say(K("El jurado ha catado y analizado.") + "\n" + "\n".join(L), N)
	S.cup.ed[str(ed)] = pl + 1
	if pl < C.premio.size():
		var e: int = int(C.premio[pl])
		S.money += e
		S.prest = int(S.get("prest", 0)) + int(C.prest[pl])
		S.cup.tro.append({"ed": ed, "pl": pl + 1, "k": sid})
		S.rep += 5 * (3 - pl)
		sfx("get")
		update_hud()
		await got(T("{e}, el trofeo del {p}.º puesto y {n} de prestigio", {"e": Datos.eur(e), "p": pl + 1, "n": int(C.prest[pl])}))
		if int(S.prest) >= int(C.vip) and not S.flags.get("cupVip"):
			S.flags.cupVip = true
			await say(K("Con ese palmarés, en los clubs de Hiriburu ya saben quién eres."), N)
	else:
		sfx("bad")
		await say(K("Esta vez no hay podio. Vuelve el próximo trimestre con algo mejor."), N)

# ---------- la potencia contratada ----------
func ener_ya(sitio: String, k: String) -> bool:
	return S.get("ener") is Dictionary and S.ener.get(sitio) is Dictionary and S.ener[sitio].has(k) and int(S.ener[sitio][k]) <= int(S.day)

func carga_w(sitio: String) -> int:
	var w := 0.0
	if sitio == "casa":
		for ci in S.carpas.size():
			if not Cultivo.plantas_vivas(S, ci):
				continue
			var c: Dictionary = S.carpas[ci]
			w += float(D.FOCOS[c.foco].w)
			for x in D.EXTRAS:
				if c.get(x):
					w += float(D.EXTRAS[x].w)
		for a in D.APARATOS:
			if S.sala.get(a):
				w += float(D.APARATOS[a].w)
	elif S.get("nave") != null:
		for i in S.nave.m.size():
			if S.nave.m[i]:
				w += float(D.FOCO_NAVE[S.nave.f[i]].w)
	return int(w)

# lo que pasa de la potencia: [exceso sin cubrir, W que cubre el generador]
func exceso_w(sitio: String) -> Array:
	var E: Dictionary = D.ENERGIA
	var x: int = carga_w(sitio) - int(E[sitio].lim)
	if ener_ya(sitio, "pl"):
		x -= int(E.pl.w)
	var g := 0
	if x > 0 and ener_ya(sitio, "gen"):
		g = mini(x, int(E.gen.w))
		x -= g
	return [maxi(0, x), g]

func energia_dia(av: Array) -> void:
	if not Datos.CAL:
		return
	var E: Dictionary = D.ENERGIA
	for sitio in ["casa", "nave"]:
		if sitio == "nave" and S.get("nave") == null:
			continue
		var r := exceso_w(sitio)
		var x: int = r[0]
		if r[1] > 0:   # el gasóleo, en efectivo; sin él, el generador no arranca
			var e: int = Datos.jsround(float(r[1]) / 1000.0 * float(E.h) * float(E.gen.kwh))
			if S.money >= e:
				S.money -= e
				av.append(T("Gasóleo del generador ({s}): −{e}", {"s": I18n.v(String(E[sitio].n)).to_lower(), "e": Datos.eur(e)}))
			else:
				x += r[1]
		if x > 0:
			var c: int = ceili(float(x) / 1000.0) * int(E.calor)
			S.heat = mini(100, int(S.heat) + c)
			av.append(T("{s}: {w} por encima de la potencia contratada. Firma térmica: calor +{c}", {"s": I18n.v(String(E[sitio].n)), "w": kw(x), "c": c}))

func kw(w: int) -> String:
	return Datos.coma(Datos.jsround(float(w) / 100.0) / 10.0) + " kW"   # i18n-no

func energia_tienda() -> void:
	var E: Dictionary = D.ENERGIA
	var i := 0
	while true:
		var ss := ["casa"]
		if S.get("nave") != null:
			ss.append("nave")
		var items := []
		var acc := []
		for sitio in ss:
			var r := exceso_w(sitio)
			var est: String = T("{c} de {l} contratados", {"c": kw(carga_w(sitio)), "l": kw(int(E[sitio].lim))}) + (T(" · se pasa {w}", {"w": kw(r[0])}) if r[0] > 0 else "")
			for k in ["pl", "gen"]:
				var Q: Dictionary = E[k]
				var ped: bool = S.get("ener") is Dictionary and S.ener.get(sitio) is Dictionary and S.ener[sitio].has(k)
				items.append({"label": "%s · %s" % [I18n.v(String(Q.n)), I18n.v(String(E[sitio].n)).to_lower()] + (T(" · puesto") if ener_ya(sitio, k) else T(" · mañana") if ped else ""),
					"right": Datos.eur(Q.p), "disabled": ped, "desc": I18n.v(String(Q.d)) + "\n" + est})
				acc.append([sitio, k])
		items.append({"label": K("Salir"), "desc": K("Lo que se pasa de la potencia contratada lo nota la compañía, y la policía se entera.")})
		i = await menu(items, {"cls": "full", "title": K("LA INSTALACIÓN ELÉCTRICA"), "title2": T("En la cuenta {e}", {"e": Datos.eur(S.banco)}), "desc": true, "initial": i})
		if i < 0 or i >= acc.size():
			return
		var sitio: String = acc[i][0]
		var k: String = acc[i][1]
		if await tarjeta(float(E[k].p), K("Tienda online") + " · " + I18n.v(String(E[k].n))):
			if not (S.get("ener") is Dictionary):
				S.ener = {}
			if not (S.ener.get(sitio) is Dictionary):
				S.ener[sitio] = {}
			S.ener[sitio][k] = int(S.day) + 1
			sfx("coin")
			toast(T("Pedido: {n} · lo instalan mañana", {"n": I18n.v(String(E[k].n))}), 1400)
