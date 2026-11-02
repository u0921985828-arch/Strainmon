# EL ESQUEJE, la revista mensual de cultivo (lo pidió el usuario: «Molaría que hubiese un periódico del cannabis o alguna
# revista»; solo con Datos.CAL). REVISTA de tools/revista.py. Un número por mes del calendario (el n.º 1, el del mes en que
# empieza la partida); se compra en el quiosco de prensa del Ensanche, en los dos growshops, en los estancos y en el mercado de
# la Ribera, o llega al buzón el día 1 si estás suscrito (tienda online, doce números). Cada número se arma con el estado de la
# partida: portada, la variedad del mes (con su pista si no la tienes), TALLER (una de las doce técnicas: la primera vez que se
# lee se aprende y da su efecto, con tope), MERCADO con los precios de verdad, la Copa, los clasificados (el del mes deja algo:
# descuento en la chatarrería, un club que paga más por una variedad), cartas y LEGAL. Los números se guardan (S.rev.col) y se
# releen desde la MOCHILA (la meta, los doce números distintos: REVISTA.cab.col).
# Cadena: … → caza → copaot → acto3 → revista → retencion → juego.
extends "res://src/acto3.gd"

const REV_COLOR := "#3c7a28"   # i18n-no

func rev() -> Dictionary:
	if not (S.get("rev") is Dictionary):
		S.rev = {"col": [], "tec": [], "sus": 0}
	if not (S.rev.get("col") is Array):
		S.rev.col = []
	if not (S.rev.get("tec") is Array):
		S.rev.tec = []
	if S.rev.get("sus") == null:
		S.rev.sus = 0
	return S.rev

func rev_hay() -> bool:
	return Datos.CAL and D.has("REVISTA")

# ---------- el número del mes ----------
# n.º 1 = el mes de CAL0; cada mes que pasa, uno más
func rev_num(dia := -1) -> int:
	if not rev_hay():
		return 0
	var d := int(S.day) if dia < 0 else dia
	var f: Dictionary = Datos.fecha(d)
	var f0: Dictionary = Datos.fecha(1)
	return (int(f.y) - int(f0.y)) * 12 + int(f.m) - int(f0.m) + 1

func rev_mes(n: int) -> String:   # «mayo de 2026» del número n
	var f0: Dictionary = Datos.fecha(1)
	var m := int(f0.m) + n - 1
	var y := int(f0.y) + int(floor(float(m - 1) / 12.0))
	m = ((m - 1) % 12) + 1
	return T("{m} de {y}", {"m": I18n.v(String(D.MESES[m - 1])), "y": y})

func rev_tiene(n: int) -> bool:
	for v in rev().col:
		if int(v) == n:
			return true
	return false

func rev_tec(n: int) -> Dictionary:   # la técnica de ese número: las doce ciclan
	var T: Array = D.REVISTA.tec
	return T[(maxi(1, n) - 1) % T.size()]

func rev_cls(n: int) -> Dictionary:
	var C: Array = D.REVISTA.cls
	return C[Datos.hash_str("rev-cls|%d" % n) % C.size()]

func rev_car(n: int) -> String:
	var C: Array = D.REVISTA.car
	return I18n.v(String(C[Datos.hash_str("rev-car|%d" % n) % C.size()]))

func rev_var(n: int) -> String:   # la variedad del mes: una de STRAINS, fija por número
	var ks: Array = D.STRAINS.keys()
	ks.sort()
	return String(ks[Datos.hash_str("rev-var|%d" % n) % ks.size()])

# ---------- lo que dejan las técnicas aprendidas ----------
func rev_bono(e: String) -> float:
	if not rev_hay():
		return 0.0
	return Cultivo.rev_bono(S, e)

# ---------- el texto del número ----------
func rev_titular(n: int) -> String:
	var R: Dictionary = D.REVISTA
	if n <= 1:
		return I18n.v(String(R.tit.tia[0]))
	if S.get("mar") is Dictionary and S.mar.get("lic"):
		return I18n.v(String(R.tit.ley[2]))
	if S.get("mar") is Dictionary and S.mar.get("kaia"):
		return I18n.v(String(R.tit.ley[1]))
	var mes := int(Datos.fecha(int(S.day)).m)
	if mes == 10 and int(S.ch) >= int(D.COPA_OT.ch):
		return I18n.v(String(R.tit.copa[0]))
	if mes == 11 and S.get("cot") is Dictionary and not S.cot.y.is_empty():
		return I18n.v(String(R.tit.copa[1]))
	if S.get("bt") is Dictionary and S.bt.get("ab"):
		return I18n.v(String(R.tit.tia[1]))
	if nivel_poli() > 0:
		return I18n.v(String(R.tit.poli[nivel_poli()]))
	return I18n.v(String(R.tit.poli[0]))

func rev_texto(n: int) -> String:
	var R: Dictionary = D.REVISTA
	var SE: Dictionary = R.sec
	var o := PackedStringArray()
	# portada
	o.append("%s · %s" % [I18n.v(String(R.cab.sub)).to_upper(), rev_mes(n).to_upper()])
	o.append(rev_titular(n))
	# la variedad del mes
	var sid := rev_var(n)
	var s: Dictionary = strain(sid)
	var li := PackedStringArray()
	li.append("%s · %s" % [I18n.v(String(s.n)), linea_ind(sid)])
	li.append(I18n.v(String(s.o)))
	if not S.disc.get(sid):
		var p := rev_pista(sid)
		li.append(T("Dónde conseguirla: {p}.", {"p": p}) if p != "" else K("De esta no dicen de dónde sale. Alguien de la comarca la tendrá."))
	else:
		li.append(K("Esta ya la tienes en la GENOTECA."))
	o.append("%s\n%s" % [I18n.v(String(SE.vari)), "\n".join(li)])
	# el taller: la técnica
	var tc := rev_tec(n)
	o.append("%s · %s\n%s" % [I18n.v(String(SE.tec)), I18n.v(String(tc.n)), I18n.v(String(tc.t))])
	# el mercado
	o.append("%s\n%s" % [I18n.v(String(SE.merc)), rev_mercado()])
	# la Copa
	o.append("%s\n%s" % [I18n.v(String(SE.copa)), rev_copa(n)])
	# los clasificados
	var cl := rev_cls(n)
	o.append("%s\n%s — %s" % [I18n.v(String(SE.cls)), I18n.v(String(cl.n)), I18n.v(String(cl.t))])
	# cartas
	o.append("%s\n%s" % [I18n.v(String(SE.car)), rev_car(n)])
	# legal
	o.append("%s\n%s" % [I18n.v(String(SE.leg)), rev_legal()])
	o.append(I18n.v(String(R.cab.pie)))
	return "\n\n".join(o)

func rev_pista(sid: String) -> String:   # de CAZA (la gente y las fiestas) o de REGALO (lo que escondió la tía)
	if D.has("CAZA"):
		for e in D.CAZA.l:
			if String(e.k) == sid:
				return I18n.v(String(e.pista))
	if D.has("REGALO") and D.REGALO.has(sid):
		return K("la tía la escondió en algún sitio de la comarca")
	if rec_de(sid) != "":
		return T("de receta: {r}", {"r": rec_de(sid)})
	return ""

func rec_de(sid: String) -> String:   # las hojas de su receta, en una línea
	if not D.RECIPES.has(sid):
		return ""
	var h: Array = []
	for k in D.RECIPES[sid]:
		h.append(I18n.v(String(strain(String(k)).n)))
	return " + ".join(h)

func rev_mercado() -> String:
	var l := PackedStringArray()
	l.append(T("Flor al por mayor, en la lonja: {e} el gramo al {t} % de THC.", {"e": Datos.eur(precio_mayor(20.0)), "t": 20}))
	l.append(T("En los clubs: {e} el gramo al {t} %.", {"e": Datos.eur(precio_club(20.0)), "t": 20}))
	l.append(T("Extracción, a los catadores: {e} el gramo al {t} %.", {"e": Datos.eur(precio_rosin(60.0)), "t": 60}))
	l.append(K("Precios de referencia: lo curado y lo manicurado sube, y lo verde baja."))
	return "\n".join(l)

func rev_copa(n: int) -> String:
	if int(S.ch) < int(D.COPA_OT.ch):
		return K("El jurado de la plaza prepara la Copa de otoño. Se abrirá a quien tenga algo que presentar.")
	var l := PackedStringArray()
	var y := int(Datos.fecha(int(S.day)).y)
	l.append(T("Copa de otoño: el {d} de {m}, en la plaza. Cinco categorías.", {"d": int(D.COPA_OT.d), "m": I18n.v(String(D.MESES[int(D.COPA_OT.m) - 1]))}))
	if S.get("cot") is Dictionary and S.cot.y.has(str(y)):
		var ps: Dictionary = S.cot.y[str(y)]
		for c in D.COPA_OT.cats:
			if ps.has(String(c.k)):
				l.append(T("{c}: {p}º puesto.", {"c": I18n.v(String(c.n)), "p": int(ps[String(c.k)])}))
	elif n > 0:
		l.append(K("Este año aún no se ha presentado nada a tu nombre."))
	return "\n".join(l)

func rev_legal() -> String:
	if S.get("mar") is Dictionary and S.mar.get("lic"):
		return K("Con la licencia del muelle, la distribuidora puede mover género legal cada día. La revista recuerda que lo que sale de ahí va con papeles.")
	if S.get("mar") is Dictionary and S.mar.get("kaia"):
		return K("KAIA abre en el muelle con dispensario para socios. A los treinta días de abrir, la ley permite pedir licencia de distribuidora.")
	if S.get("aso") is Dictionary and S.aso.get("pres"):
		return K("Las asociaciones con presidencia al día pueden tener dispensario para socios. Fuera de eso, nada de vender a quien no es socio.")
	return K("Las asociaciones piden una ley clara: cultivo compartido, dispensario para socios y nada de venta a la calle.")

# ---------- comprar, leer y guardar ----------
# el número cuesta lo mismo en todas partes menos en GROW IBARBIDE, que hace su 10 % como con lo demás
func rev_precio(donde := "prensa") -> float:
	return snappedf(float(D.REVISTA.cab.p) * (.9 if donde == "ane" else 1.0), 0.01)

# donde: «prensa», «kiko», «ane», «est» o «mercado» (solo para el texto del vendedor)
func rev_compra(donde := "prensa") -> void:
	if not rev_hay():
		return
	var n := rev_num()
	var R := rev()
	if rev_tiene(n):
		await say(T("{r}, el número de {m}. Ese ya lo tienes.", {"r": I18n.v(String(D.REVISTA.cab.n)), "m": rev_mes(n)}))
		return
	var ops := [T("Comprarla ({e})", {"e": Datos.eur(rev_precio(donde))}), K("Nada")]
	if await ask(T("{r}, {s}. El número de {m}: «{t}».", {"r": I18n.v(String(D.REVISTA.cab.n)), "s": I18n.v(String(D.REVISTA.cab.sub)), "m": rev_mes(n), "t": rev_titular(n)}), ops) != 0:
		return
	if float(S.money) < rev_precio(donde):
		await say(K("No llevas suelto."))
		return
	S.money = snappedf(float(S.money) - rev_precio(donde), 0.01)
	sfx("coin")
	update_hud()
	await rev_guarda(n)

func rev_guarda(n: int) -> void:
	var R := rev()
	if not rev_tiene(n):
		R.col.append(n)
		R.col.sort()
	revisa_logros()
	await rev_lee(n)

func rev_lee(n: int) -> void:
	var tc := rev_tec(n)
	var nuevo: bool = not rev().tec.has(String(tc.k))
	await gesto("revista")
	await leer("%s · %s" % [I18n.v(String(D.REVISTA.cab.n)), rev_mes(n)], rev_texto(n))
	if nuevo:
		rev().tec.append(String(tc.k))
		sfx("get")
		toast(T("Aprendes una técnica: {n}", {"n": I18n.v(String(tc.n))}), 2200)

# el día 1 de cada mes, si estás suscrito, el número al buzón
func rev_dia() -> void:
	if not rev_hay():
		return
	var R := rev()
	if int(R.sus) <= 0 or int(Datos.fecha(int(S.day)).d) != 1:
		return
	var n := rev_num()
	if rev_tiene(n):
		return
	R.sus = int(R.sus) - 1
	R.col.append(n)
	R.col.sort()
	revisa_logros()
	var li := [T("Tienes en el buzón el número de {m}: «{t}».", {"m": rev_mes(n), "t": rev_titular(n)}),
		T("Te quedan {q} números de la suscripción.", {"q": int(R.sus)}) if int(R.sus) > 0 else K("Era el último de la suscripción: se renueva en la tienda online.")]
	var nm_: String = T("SMS · {n}", {"n": I18n.v(String(D.REVISTA.cab.n))})
	queue("revista", func(): await talk(nm_, li), [[nm_, li]])

func rev_suscribe() -> void:
	var R := rev()
	R.sus = int(R.sus) + int(D.REVISTA.cab.susn)

# la pila de números, desde la MOCHILA
func rev_menu() -> void:
	var R := rev()
	var i := 0
	while true:
		var rows := []
		var ns: Array = R.col.duplicate()
		ns.reverse()
		for n in ns:
			rows.append({"label": T("N.º {n} · {m}", {"n": int(n), "m": rev_mes(int(n))}), "right": I18n.v(String(rev_tec(int(n)).n)), "desc": rev_titular(int(n))})
		if rows.is_empty():
			return
		rows.append({"label": K("Salir"), "desc": K("Volver.")})
		i = await menu(rows, {"cls": "full", "title": I18n.v(String(D.REVISTA.cab.n)), "title2": T("{n} de {t} números", {"n": R.col.size(), "t": int(D.REVISTA.cab.col)}), "desc": true, "initial": clampi(i, 0, rows.size() - 1)})
		if i < 0 or i >= ns.size():
			return
		await rev_lee(int(ns[i]))

func rev_ficha() -> String:
	var R := rev()
	var l := PackedStringArray()
	l.append(T("{n} números guardados · {t} técnicas aprendidas.", {"n": R.col.size(), "t": R.tec.size()}))
	var b := PackedStringArray()
	for e in ["rend", "cal", "thc", "moho", "clon"]:
		var v := rev_bono(e)
		if v > 0:
			b.append({"rend": T("cosecha +{p} %", {"p": Datos.pct(v * 100)}), "cal": T("calidad +{p} %", {"p": Datos.pct(v * 100)}),
				"thc": T("THC +{p} %", {"p": Datos.pct(v * 100)}), "moho": T("menos moho ({p} %)", {"p": Datos.pct(v * 100)}),
				"clon": T("esquejes más resistentes")}[e])
	if not b.is_empty():
		l.append(", ".join(b) + ".")
	l.append(T("Pulsa A para releer cualquier número."))
	return "\n".join(l)
