# La Copa de otoño por categorías (ESTUDIO, tanda 5; lo pidió el usuario: «metas mano a las mejoras que hablamos»; solo con
# Datos.CAL): COPA_OT de tools/copa_ot.py. Cada 17 de octubre, desde el capítulo 7, el jurado de la plaza abre cinco categorías
# —potencia, sabor, landrace pura, cruce propio y extracción—, una muestra por categoría y año (S.cot.y[año][cat] = puesto). Los
# rivales suben cada año hasta su tope; el podio da dinero, trofeo y prestigio (S.prest, como la CannaCup), y ganar tres
# categorías el mismo año, la Copa absoluta (S.cot.abs).
# Cadena: … → acto2 → caza → copaot → acto3 → retencion → juego.
extends "res://src/caza.gd"

const COT_COLOR := "#d07020"   # i18n-no

func cot() -> Dictionary:
	if not (S.get("cot") is Dictionary):
		S.cot = {"y": {}, "tro": [], "abs": []}
	return S.cot

func copa_ot_dia(y: int) -> int:
	return Datos.dia_de(y, int(D.COPA_OT.m), int(D.COPA_OT.d))

func copa_ot_hoy() -> bool:
	if not Datos.CAL or int(S.get("ch", 0)) < int(D.COPA_OT.ch):
		return false
	return int(S.day) == copa_ot_dia(int(Datos.fecha(int(S.day)).y))

func cot_anos(y: int) -> int:   # los años desde el primero de la partida: lo que han mejorado los rivales
	return maxi(0, y - int(Datos.fecha(1).y))

func cot_aroma(y: int) -> String:
	return String(D.AROMAS[Datos.hash_str("cota|%d" % y) % D.AROMAS.size()])

func cot_cat(k: String) -> Dictionary:
	for c in D.COPA_OT.cats:
		if String(c.k) == k:
			return c
	return {}

func cot_rivales(k: String, y: int) -> Array:
	var c := cot_cat(k)
	var r := []
	var rv: Array = D.COPA_OT.rivales
	for j in rv.size():   # su nivel (fijo por rival), lo que suben al año y un día mejor o peor que nunca les quita lo ganado
		var paso := int((float(c.r[1]) - float(c.r[0])) * 10) + 1
		var ru := maxi(1, int(float(c.sube) * 8))
		var x := float(c.r[0]) + float(Datos.hash_str("cot|%s|%d" % [k, j]) % paso) / 10.0 + float(c.sube) * cot_anos(y) + float(Datos.hash_str("cot|%s|%d|%d" % [k, j, y]) % ru) / 10.0
		r.append([I18n.v(String(rv[j])), minf(float(c.tope), Datos.jsround(x * 10) / 10.0)])
	return r

# las muestras que valen para esa categoría: [[clave, lote]…]
func cot_lotes(k: String) -> Array:
	var c := cot_cat(k)
	if k == "ext":
		return rosin_lots(float(c.g))
	var o := []
	for l in bud_lots(float(c.g)):
		var sid := lot_sid(l[0])
		var curado: bool = float(l[1].get("cu", 0)) >= 0.99
		match k:
			"pot":
				if curado:
					o.append(l)
			"sab":
				o.append(l)
			"land":
				if curado and String(strain(sid).get("tipo", "")) == "landrace":
					o.append(l)
			"cru":
				if curado and S.get("custom") is Dictionary and S.custom.has(sid):
					o.append(l)
	return o

func cot_puntos(k: String, b: Dictionary, sid: String, y: int) -> float:
	if k != "sab":
		return Datos.jsround(float(b.thc) * 10) / 10.0
	var P: Dictionary = D.COPA_OT.sab
	var p := float(P.base) + float(P.cu) * minf(1.0, float(b.get("cu", 0))) + float(P.ar) * minf(1.0, float(b.get("ar", 0)))
	if float(b.get("af", 0)) >= 1:
		p += float(P.af)
	if aroma_de(sid) == cot_aroma(y):
		p += float(P.aroma)
	return Datos.jsround(p * 10) / 10.0

func cot_txt(k: String, x: float) -> String:
	return T("{p} puntos", {"p": Datos.coma(x)}) if k == "sab" else Datos.pct(x) + " %"   # i18n-no

func cot_ano(y: int) -> Dictionary:
	var A: Dictionary = cot().y
	if not (A.get(str(y)) is Dictionary):
		A[str(y)] = {}
	return A[str(y)]

func talk_copa_ot() -> void:
	var N := K("JURADO")
	var C: Dictionary = D.COPA_OT
	var y: int = int(Datos.fecha(int(S.day)).y)
	var hecho := cot_ano(y)
	if hecho.is_empty():
		await talk(N, [K("Bienvenido a la COPA DE OTOÑO de la asociación: cinco categorías y una muestra por categoría."),
			T("Este año, en sabor, se premia el aroma {a}. Gana tres categorías y te llevas la Copa absoluta.", {"a": cot_aroma(y)})])
	var i := 0
	while true:
		var items := []
		for c in C.cats:
			var pl = hecho.get(String(c.k))
			items.append({"label": I18n.v(String(c.n)), "right": (T("{p}.º puesto", {"p": int(pl)}) if int(pl) <= 3 else K("fuera del podio")) if pl != null else "",
				"disabled": pl != null, "desc": I18n.v(String(c.d))})
		items.append({"label": K("Salir"), "desc": T("Los rivales mejoran cada año. Este año, en sabor, el aroma {a}.", {"a": cot_aroma(y)})})
		i = await menu(items, {"cls": "full", "title": K("COPA DE OTOÑO"), "title2": T("Prestigio {p} · {t} trofeos", {"p": int(S.get("prest", 0)), "t": cot().tro.size()}), "desc": true, "initial": i})
		if i < 0 or i >= C.cats.size():
			return
		await cot_presenta(C.cats[i], y)

func cot_presenta(c: Dictionary, y: int) -> void:
	var N := K("JURADO")
	var C: Dictionary = D.COPA_OT
	var k := String(c.k)
	var lots := cot_lotes(k)
	if lots.is_empty():
		await say(T("Para {c} no traes nada que valga. {d}", {"c": I18n.v(String(c.n)).to_lower(), "d": I18n.v(String(c.d))}), N)
		return
	var it: Array = lots.map(rosin_item if k == "ext" else lot_item)
	it.append({"label": K("Todavía no")})
	var j: int = await menu(it, {"cls": "right", "title": I18n.v(String(c.n))})
	if j < 0 or j >= lots.size():
		return
	var lk: String = lots[j][0]
	var b: Dictionary = lots[j][1]
	var sid := lot_sid(lk)
	var pt := cot_puntos(k, b, sid, y)
	if k == "ext":
		use_rosin(lk, float(c.g))
	else:
		use_buds(lk, float(c.g))
	var tab := cot_rivales(k, y)
	tab.append([S.name if S.get("name") else K("Tú"), pt, true])
	tab.sort_custom(func(a, e): return a[1] > e[1] or (a[1] == e[1] and a.size() > e.size()))
	var pl := 0
	for q in tab.size():
		if tab[q].size() > 2:
			pl = q
	var L := []
	for q in tab.size():
		L.append("%d. %s · %s" % [q + 1, tab[q][0], cot_txt(k, tab[q][1])])
	await say(T("{c}: el jurado ha decidido.", {"c": I18n.v(String(c.n))}) + "\n" + "\n".join(L), N)
	cot_ano(y)[k] = pl + 1
	if pl >= C.premio.size():
		sfx("bad")
		await say(K("Esta vez, fuera del podio. Los demás también trabajan todo el año."), N)
		return
	var e: int = int(C.premio[pl])
	S.money += e
	S.prest = int(S.get("prest", 0)) + int(C.prest[pl])
	S.rep += 2 * (3 - pl)
	cot().tro.append({"y": y, "k": k, "pl": pl + 1, "s": sid})
	sfx("get")
	update_hud()
	await got(T("{e} y el trofeo de {c}, {p}.º puesto", {"e": Datos.eur(e), "c": I18n.v(String(c.n)).to_lower(), "p": pl + 1}))
	var oros := 0
	for x in cot_ano(y).values():
		if int(x) == 1:
			oros += 1
	if oros >= int(C.abs.n) and not (y in cot().abs):
		cot().abs.append(y)
		S.money += int(C.abs.eur)
		S.prest = int(S.get("prest", 0)) + int(C.abs.prest)
		update_hud()
		sfx("enc")
		await say(T("¡{n} categorías ganadas! La COPA ABSOLUTA de {y} es tuya.", {"n": oros, "y": y}), N)
		await got(T("{e} y la Copa absoluta", {"e": Datos.eur(int(C.abs.eur))}))

# el jurado, el día de la Copa de otoño
func hilo_talk(id: String) -> bool:
	if await super(id):
		return true
	if id == "jurado" and copa_ot_hoy():
		await talk_copa_ot()
		return true
	return false

# al amanecer: el SMS de la asociación a COPA_OT.aviso días y el mismo día
func hilo_dia() -> void:
	super()
	if not Datos.CAL or int(S.ch) < int(D.COPA_OT.ch):
		return
	var y: int = int(Datos.fecha(int(S.day)).y)
	var falta := copa_ot_dia(y) - int(S.day)
	if falta != 0 and falta != int(D.COPA_OT.aviso):
		return
	var L := [T("Hoy es la Copa de otoño, en la plaza de Ribera Verde: potencia, sabor, landrace pura, cruce propio y extracción.") if falta == 0 else T("El {d}, la Copa de otoño en la plaza de Ribera Verde: cinco categorías, una muestra en cada una.", {"d": Datos.fd(copa_ot_dia(y), S.day)}),
		T("En sabor, este año, el aroma {a}. Los rivales vienen más fuertes que el año pasado.", {"a": cot_aroma(y)}) if cot_anos(y) > 0 else T("En sabor, este año, el aroma {a}. Es la primera edición: los rivales ya llevan años preparándose.", {"a": cot_aroma(y)})]
	queue("copaot", func(): await talk(K("SMS · ASOCIACIÓN"), L), [[K("SMS · ASOCIACIÓN"), L]])   # i18n-no

func marcas_cal() -> Array:
	var r := super()
	if not Datos.CAL or int(S.get("ch", 0)) < int(D.COPA_OT.ch):
		return r
	var y: int = int(Datos.fecha(int(S.day)).y)
	for yy in [y, y + 1]:
		r.append({"d": copa_ot_dia(yy), "c": COT_COLOR, "t": T("Copa de otoño en la plaza")})
	r.sort_custom(func(a, b): return a.d < b.d)
	return r
