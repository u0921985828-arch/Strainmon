# EL ESQUEJE, la revista mensual de cultivo (lo pidió el usuario: «Molaría que hubiese un periódico del cannabis o alguna
# revista»; solo con Datos.CAL). REVISTA de tools/revista.py. Un número por mes del calendario (el n.º 1, el del mes en que
# empieza la partida); se compra en el quiosco de prensa del Ensanche, en los dos growshops, en los estancos y en el mercado de
# la Ribera, o llega al buzón el día 1 si estás suscrito (tienda online, doce números). Cada número se arma con el estado de la
# partida: portada, NOTICIAS DE LA COMARCA (lo que ha pasado de verdad en tu partida ese mes: rev_nota lo apunta cuando pasa y
# el número lo cuenta como nota de prensa; si el mes viene tranquilo, noticias deducidas del estado), la variedad del mes (con su
# pista si no la tienes), TALLER (una de las doce técnicas: la primera vez que se lee se aprende y da su efecto, con tope),
# MERCADO con los precios de verdad, la Copa, LA AGENDA DEL MES (lo que viene por el calendario: la Copa, las fiestas, el plazo,
# los recibos, la ventana de la nave), los clasificados (el del mes deja algo: descuento en la chatarrería, un club que paga más
# por una variedad), cartas y LEGAL. Los números se guardan (S.rev.col) y se
# releen desde la MOCHILA (la meta, los doce números distintos: REVISTA.cab.col).
# Cadena: … → caza → copaot → acto3 → revista → retencion → juego.
extends "res://src/acto3.gd"

const REV_COLOR := "#3c7a28"   # i18n-no

func rev() -> Dictionary:
	if not (S.get("rev") is Dictionary):
		S.rev = {"col": [], "tec": [], "sus": 0, "nw": []}
	if not (S.rev.get("col") is Array):
		S.rev.col = []
	if not (S.rev.get("tec") is Array):
		S.rev.tec = []
	if S.rev.get("sus") == null:
		S.rev.sus = 0
	if not (S.rev.get("nw") is Array):   # el registro de sucesos: las partidas de antes no lo tienen
		S.rev.nw = []
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
	var my := rev_my(n)
	return T("{m} de {y}", {"m": I18n.v(String(D.MESES[int(my.m) - 1])), "y": int(my.y)})

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

# ---------- el registro de sucesos: de aquí salen las noticias ----------
const NW_TOPE := 60   # lo que se guarda del registro
const NW_MAX := 3     # noticias por número

# lo llama el juego cuando algo pasa (desde cualquier módulo: el stub está en mundo.gd). «v» es la cifra que lleve la noticia
func rev_nota(k: String, v := 0) -> void:
	if not rev_hay() or k == "":
		return
	var R := rev()
	for w in R.nw:
		if String(w.get("k", "")) == k and int(w.get("d", 0)) == int(S.day):
			w.v = maxi(int(w.get("v", 0)), int(v))   # la misma noticia con más cifra (los podios de la Copa)
			return
	R.nw.append({"k": k, "d": int(S.day), "v": int(v)})
	while R.nw.size() > NW_TOPE:
		R.nw.pop_front()

func nw_def(k: String) -> Dictionary:
	for w in D.REVISTA.nw:
		if String(w.k) == k:
			return w
	return {}

# los sucesos que cuenta el número n: los de su mes y, si no llena, los del mes anterior; por prioridad y sin repetir clave
func rev_nw_de(n: int) -> Array:
	var o := []
	var vis := {}
	for mes in [n, n - 1]:
		var l := []
		for w in rev().nw:
			var k := String(w.get("k", ""))
			if vis.has(k) or rev_num(int(w.get("d", 1))) != mes:
				continue
			var df := nw_def(k)
			if df.is_empty():
				continue
			vis[k] = 1
			l.append({"d": int(w.get("d", 1)), "v": int(w.get("v", 0)), "df": df})
		l.sort_custom(func(a, b): return int(a.df.p) > int(b.df.p) if int(a.df.p) != int(b.df.p) else int(a.d) > int(b.d))
		o.append_array(l)
		if o.size() >= NW_MAX:
			break
	return o.slice(0, NW_MAX)

func rev_nw_txt(e: Dictionary) -> String:
	return T(String(e.df.t), {"d": Datos.fd_corto(int(e.d)), "v": int(e.v)})

# las noticias deducidas del estado: entran cuando el mes no trae sucesos suyos
func rev_relleno(n: int) -> Array:
	var o := []
	for r in D.REVISTA.rel:
		var k := String(r.k)
		var a := {}
		match k:
			"clima":
				var my := rev_my(n)
				var d1 := Datos.dia_de(int(my.y), int(my.m), 1)
				var t: Array = D.TIEMPO.t[int(my.m) - 1]
				a = {"c": Datos.estacion(d1), "x": T("de {a} a {b} °C de media", {"a": int(t[1]), "b": int(t[0])})}
			"poli":
				var np := nivel_poli()
				a = {"p": [K("tranquila"), K("con más patrullas de lo normal"), K("con una investigación abierta"), K("con una orden de registro firmada")][clampi(np, 0, 3)]}
			"dex":
				var nd: int = D.DEX.filter(func(x): return S.disc.get(x)).size()
				if nd < 3:
					continue
				a = {"n": nd}
			"obras":
				if not (S.get("mar") is Dictionary) or not D.MAR.obras.any(func(ob): return not obra_ya(String(ob.k))):
					continue
			"clubs":
				if not (S.get("aso") is Dictionary and S.aso.get("pres")) and not (S.get("mar") is Dictionary and S.mar.get("kaia")):
					continue
			_:
				pass
		o.append(T(String(r.t), a))
	return o

func rev_noticias(n: int) -> String:
	var l := PackedStringArray()
	for e in rev_nw_de(n):
		l.append("· " + rev_nw_txt(e))
	if l.size() < 2:
		var rl := rev_relleno(n)
		var i := 0
		while l.size() < 2 and i < rl.size():
			l.append("· " + String(rl[(Datos.hash_str("rev-rel|%d" % n) + i) % rl.size()]))
			i += 1
	return "\n".join(l)

# ---------- la agenda del mes: lo que viene por el calendario ----------
func rev_my(n: int) -> Dictionary:   # el mes y el año del número n
	var f0: Dictionary = Datos.fecha(1)
	var m := int(f0.m) + n - 1
	var y := int(f0.y) + int(floor(float(m - 1) / 12.0))
	return {"m": ((m - 1) % 12) + 1, "y": y}

func rev_agenda(n: int) -> String:
	var A: Dictionary = D.REVISTA.ag
	var my := rev_my(n)
	var m := int(my.m)
	var y := int(my.y)
	var l := PackedStringArray()
	if int(S.ch) >= int(D.COPA_OT.ch) and m == int(D.COPA_OT.m):
		l.append("· " + T(String(A.copa), {"d": Datos.fd_corto(Datos.dia_de(y, m, int(D.COPA_OT.d)))}))
	for f in D.CAZA.fi:
		if int(f.m) == m:
			l.append("· " + T(String(A.fiesta), {"n": I18n.v(String(f.n)), "d": Datos.fd_corto(Datos.dia_de(y, m, int(f.d))), "q": int(f.dias)}))
	if int(S.get("due", 0)) > 0 and int(S.get("deadline", 0)) > 0:
		var fp: Dictionary = Datos.fecha(int(S.deadline))
		if int(fp.m) == m and int(fp.y) == y:
			l.append("· " + T(String(A.plazo), {"d": Datos.fd_corto(int(S.deadline))}))
	if S.get("nave") is Dictionary and S.nave.get("op") != null and not S.nave.get("mia"):
		l.append("· " + T(String(A.nave)))
	if (S.get("nave") is Dictionary and S.nave.get("r") != null) or (S.get("loc") is Dictionary and not S.loc.is_empty()) or (S.get("setas") is Dictionary and S.setas != null):
		l.append("· " + T(String(A.recibo)))
	if l.is_empty():
		l.append("· " + T(String(A.nada)))
	l.append("· " + T(String(A.num)))
	return "\n".join(l)

# ---------- el texto del número ----------
func rev_titular(n: int) -> String:
	var R: Dictionary = D.REVISTA
	var nw := rev_nw_de(n)
	if nw.size():   # la noticia gorda del mes manda en la portada
		return I18n.v(String(nw[0].df.ti))
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
	return I18n.v(String(R.tit.calma[rev_est(n)]))   # el mes tranquilo: su estación (si no, en junio salía «Un otoño tranquilo»)

# la estación del número n, en el orden de REVISTA.tit.calma (primavera, verano, otoño, invierno)
func rev_est(n: int) -> int:
	var my := rev_my(n)
	var e := Datos.estacion(Datos.dia_de(int(my.y), int(my.m), 15))
	var i: int = ["primavera", "verano", "otoño", "invierno"].find(e)   # i18n-no
	return i if i >= 0 else 0

# ---------- la parodia del género (0.82): lo que trae cualquier revista de cultivo de quiosco ----------
# (lo pidió el usuario). Cada número, además de lo suyo, lleva los reclamos de la portada, la entrevista del mes, el póster
# central, el consultorio, el banco de pruebas con su publirreportaje, dos planas de anuncios de los negocios de la comarca, el
# horóscopo del cultivador y la fe de errores del número anterior. Textos en REVISTA (tools/revista.py); nada de publicaciones,
# marcas ni personas de verdad: se parodia el género, no a nadie.

# el reclamo de la portada, fijo por número
func rev_faldon(n: int) -> String:
	var F: Array = D.REVISTA.fal
	return I18n.v(String(F[Datos.hash_str("rev-fal|%d" % n) % F.size()]))

# ¿existe ya en la partida? (el capítulo y, si lo pide, su aviso de S.flags). La revista no entrevista a quien no has visto ni
# anuncia un negocio que no ha abierto (ataque de la revisión: el n.º 1 anunciaba AUTOS RIBERA, del capítulo 5)
func rev_existe(x: Dictionary) -> bool:
	if int(S.get("ch", 1)) < int(x.get("ch", 1)):
		return false
	var f := String(x.get("f", ""))
	return f == "" or bool(S.flags.get(f, 0))

# los que ya existen, en el orden de la lista (nunca vacío: Kiko, los estancos y la Federación están desde el capítulo 1)
func rev_hoy(l: Array) -> Array:
	var o := []
	for x in l:
		if rev_existe(x):
			o.append(x)
	return o if o.size() else [l[0]]

# la entrevista del mes: quién, de qué y sus tres preguntas
func rev_ent(n: int) -> String:
	var E: Array = rev_hoy(D.REVISTA.ent)
	var e: Dictionary = E[Datos.hash_str("rev-ent|%d" % n) % E.size()]
	var l := PackedStringArray()
	l.append("%s · %s" % [I18n.v(String(e.n)), I18n.v(String(e.o))])
	for q in e.q:
		l.append("— " + I18n.v(String(q[0])))
		l.append("— " + I18n.v(String(q[1])))
	return "\n".join(l)

# el consultorio: dos preguntas de lectores con su respuesta
func rev_con(n: int) -> String:
	var C: Array = D.REVISTA.con
	var i := Datos.hash_str("rev-con|%d" % n) % C.size()
	var l := PackedStringArray()
	for k in 2:
		var c: Dictionary = C[(i + k) % C.size()]
		l.append(I18n.v(String(c.p)))
		l.append(I18n.v(String(c.r)))
	return "\n".join(l)

# el banco de pruebas: el aparato del mes, su nota y el publirreportaje
func rev_tst(n: int) -> String:
	var A: Array = D.REVISTA.tst
	var t: Dictionary = A[Datos.hash_str("rev-tst|%d" % n) % A.size()]
	return "%s\n%s\n\n%s" % [T("{n} · nota {q}", {"n": I18n.v(String(t.n)), "q": rev_dec(String(t.no))}), I18n.v(String(t.t)), I18n.v(String(D.REVISTA.tstp))]

# la nota del banco de pruebas, con el separador decimal del idioma (en inglés, «9.4»; no se traduce sola porque no lleva letras)
func rev_dec(x: String) -> String:
	return x.replace(",", ".") if I18n.en() else x   # i18n-no

# el horóscopo del cultivador: el del mes del número
func rev_hor(n: int) -> String:
	var H: Array = D.REVISTA.hor
	return I18n.v(String(H[(int(rev_my(n).m) - 1) % H.size()]))

# la fe de errores: una errata del número anterior (el n.º 1 no tiene anterior)
func rev_err(n: int) -> String:
	if n <= 1:
		return K("No hay número anterior, así que esta vez no hemos podido equivocarnos. El mes que viene, sin falta.")
	var E: Array = D.REVISTA.err
	return I18n.v(String(E[Datos.hash_str("rev-err|%d" % n) % E.size()]))

# los anuncios a toda página: dos por número, distintos entre sí
func rev_anu(n: int, k: int) -> String:
	var A: Array = rev_hoy(D.REVISTA.anu)
	var i := (Datos.hash_str("rev-anu|%d" % n) + (k * 3 + k if A.size() > 1 else 0)) % A.size()
	var a: Dictionary = A[i]
	return "%s\n%s\n\n%s" % [I18n.v(String(a.n)), I18n.v(String(a.t)), I18n.v(String(a.pie))]

# la lámina del póster: el porte de la variedad del mes por su % índica (la índica, baja y ancha; la sativa, espigada)
func rev_pst_pl(n: int) -> String:
	var i := Datos.ind_de(S, rev_var(n))
	return "ps-ind" if i >= 65 else ("ps-sat" if i <= 35 else "ps-hib")   # i18n-no

# el póster central: la variedad del mes a toda página
func rev_pst(n: int) -> String:
	var sid := rev_var(n)
	var s: Dictionary = strain(sid)
	var P: Dictionary = D.REVISTA.pst
	return "%s\n%s · %s\n%s" % [I18n.v(String(P.cab)), I18n.v(String(s.n)), linea_ind(sid), I18n.v(String(P.pie))]

# las secciones del número, en orden: cada una {k, tit, txt} (la portada lleva además «cab», la línea de arriba). De aquí salen el
# texto corrido (rev_texto) y las planas de la revista a la vista (rev_paginas)
func rev_secciones(n: int) -> Array:
	var R: Dictionary = D.REVISTA
	var SE: Dictionary = R.sec
	var o := []
	# portada
	o.append({"k": "port", "tit": "", "cab": "%s · %s" % [I18n.v(String(R.cab.sub)).to_upper(), rev_mes(n).to_upper()],
		"txt": "%s\n%s" % [rev_titular(n), rev_faldon(n)]})
	# las noticias de la comarca
	o.append({"k": "nw", "tit": I18n.v(String(SE.nw)), "txt": rev_noticias(n)})
	# la entrevista del mes
	o.append({"k": "ent", "tit": I18n.v(String(SE.ent)), "txt": rev_ent(n)})
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
	o.append({"k": "vari", "tit": I18n.v(String(SE.vari)), "txt": "\n".join(li)})
	# el taller: la técnica
	var tc := rev_tec(n)
	o.append({"k": "tec", "tit": "%s · %s" % [I18n.v(String(SE.tec)), I18n.v(String(tc.n))], "txt": I18n.v(String(tc.t))})
	# el primer anuncio a toda página
	o.append({"k": "anu", "tit": "", "txt": rev_anu(n, 0)})
	# el consultorio y el banco de pruebas
	o.append({"k": "con", "tit": I18n.v(String(SE.con)), "txt": rev_con(n)})
	o.append({"k": "tst", "tit": I18n.v(String(SE.tst)), "txt": rev_tst(n)})
	# el póster central, en la grapa de la revista
	o.append({"k": "pst", "tit": "", "txt": rev_pst(n)})
	# el mercado
	o.append({"k": "merc", "tit": I18n.v(String(SE.merc)), "txt": rev_mercado()})
	# el segundo anuncio
	o.append({"k": "anu2", "tit": "", "txt": rev_anu(n, 1)})
	# la Copa
	o.append({"k": "copa", "tit": I18n.v(String(SE.copa)), "txt": rev_copa(n)})
	# la agenda del mes
	o.append({"k": "ag", "tit": I18n.v(String(SE.ag)), "txt": rev_agenda(n)})
	# los clasificados
	var cl := rev_cls(n)
	o.append({"k": "cls", "tit": I18n.v(String(SE.cls)), "txt": "%s — %s" % [I18n.v(String(cl.n)), I18n.v(String(cl.t))]})
	# cartas
	o.append({"k": "car", "tit": I18n.v(String(SE.car)), "txt": rev_car(n)})
	# el horóscopo y la fe de errores
	o.append({"k": "hor", "tit": I18n.v(String(SE.hor)), "txt": rev_hor(n)})
	o.append({"k": "err", "tit": I18n.v(String(SE.err)), "txt": rev_err(n)})
	# legal
	o.append({"k": "leg", "tit": I18n.v(String(SE.leg)), "txt": rev_legal()})
	# el pie de la revista, al final de la última plana
	o.append({"k": "pie", "tit": "", "txt": "%s\n\n%s" % [I18n.v(String(R.cab.lema)), I18n.v(String(R.cab.pie))]})
	return o

func rev_texto(n: int) -> String:
	var o := PackedStringArray()
	for q in rev_secciones(n):
		if q.has("cab"):
			o.append(String(q.cab))
		o.append("%s\n%s" % [String(q.tit), String(q.txt)] if String(q.tit) != "" else String(q.txt))
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
		tn_gana("revista")   # LA TIENDA (tienda.gd): semillas doradas por el número nuevo
	revisa_logros()
	await rev_lee(n)

func rev_lee(n: int) -> void:
	var tc := rev_tec(n)
	var nuevo: bool = not rev().tec.has(String(tc.k))
	await gesto("revista")
	# con el arte de la revista, el número se lee como una revista: portada y planas dibujadas (rects_revista); si el atlas no
	# está (una partida vieja del HTML, sin CAL), el lector de siempre
	var rv := rev_paginas(n) if Datos.CAL and rev_art() else {}
	await leer("%s · %s" % [I18n.v(String(D.REVISTA.cab.n)), rev_mes(n)], rev_texto(n), rv)
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
	tn_gana("revista")   # LA TIENDA (tienda.gd)
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

# ---------- EL ESQUEJE a la vista: la plana dibujada (0.82) ----------
# (lo pidió el usuario: «que los números se vean como revista, con portada y páginas dibujadas»): un número ya no es una lista de
# texto, es una revista. La portada lleva su mancheta, la ilustración que toca por lo que cuenta el titular y el titular debajo; cada
# sección, su plana, con la viñeta de la sección, los filetes y, al pie, un punto por plana con el de la suya relleno. El papel, la
# mancheta, los filetes, las nueve viñetas y las ocho ilustraciones son arte a mano (tools/sprites/a-mano/revista.py →
# arte/revista.png + revista.json, como arte/billar.png); el texto lo pone encima el lector de ui.gd en modo revista (lector_rev),
# que va sin caja y en tinta, y se desliza con ▲▼ si una sección no cabe.
# la revista encima de la mesa: cerrada se ve la portada, una hoja A4 de pie (1 : 1,41); abierta, la doble página con su lomo, el
# arte y el titular en la hoja de la izquierda y el texto en la de la derecha, como cualquier revista (lo dijo el usuario: «la
# revista no tiene forma de A4 ni de magazine… no me parece todavía una revista en condiciones»)
const REV_PW := 118         # la hoja, en píxeles del lienzo
const REV_PH := 168
const REV_Y := 6
const REV_LOMO := 4         # el lomo entre las dos hojas
const REV_FOTO_H := 52      # lo que se ve de la ilustración en la hoja de la izquierda
# la foto grande de la hoja izquierda, por sección (de las ocho ilustraciones del atlas)
const REV_FOTO := {"nw": "redada", "ent": "club", "var": "planta", "tec": "carpa", "con": "planta", "tst": "nave",
	"merc": "feria", "copa": "copa", "ag": "carpa", "cls": "feria", "car": "club", "hor": "planta", "err": "redada",
	"leg": "redada"}   # i18n-no
const REV_VG := {"nw": "nw", "ent": "ent", "vari": "var", "tec": "tec", "anu": "anu", "con": "con", "tst": "tst", "pst": "pst", "merc": "merc", "anu2": "anu", "copa": "copa", "ag": "ag", "cls": "cls", "car": "car", "hor": "hor", "err": "err", "leg": "leg"}   # i18n-no
# de qué va la portada según el suceso que manda en el titular
const REV_ILU := {"redada": "redada", "orden": "redada", "acusa": "redada", "embargo": "redada", "copa": "copa", "copa6": "copa",
	"kaia": "club", "ley": "club", "presi": "club", "metro": "club", "banco": "planta", "bancofin": "planta", "patente": "planta",
	"rara": "planta", "huerta": "planta", "nave": "nave", "conce": "nave", "mar": "barco", "fi-feria": "feria",
	"fi-barrio": "feria", "fi-romeria": "feria"}   # i18n-no
static var REV_ART := {}   # el atlas: nombre → Image

static func rev_art() -> bool:
	if REV_ART.size():
		return true
	var im := Image.new()
	if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://arte/revista.png")) != OK:
		return false
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://arte/revista.json"))
	if typeof(j) != TYPE_DICTIONARY or not (j.get("r") is Dictionary):
		return false
	for k in j.r:
		var q: Array = j.r[k]
		REV_ART[String(k)] = im.get_region(Rect2i(int(q[0]), int(q[1]), int(q[2]), int(q[3])))
	return true

# el ancho de hoja que cabe en el lienzo (la doble página lo llena a lo ancho)
func rev_pw() -> int:
	return clampi((SW - 6 - REV_LOMO) >> 1, 84, REV_PW)

func rev_portada() -> bool:
	return lector_rev.is_empty() or lector_i == 0

func rev_caja() -> Rect2i:   # la revista: la portada sola o la doble página, centrada en el lienzo
	var pw := rev_pw()
	var w: int = pw if rev_portada() else pw * 2 + REV_LOMO
	return Rect2i((SW - w) >> 1, REV_Y, w, REV_PH)

func rev_hoja(der: bool) -> Rect2i:   # una de las dos hojas (con la portada, la hoja es la revista entera)
	var c := rev_caja()
	var pw := rev_pw()
	if c.size.x <= pw:
		return c
	return Rect2i(c.position.x + ((pw + REV_LOMO) if der else 0), c.position.y, pw, c.size.y)

# una pieza del atlas al doble, para el despiece de la hoja izquierda
static func rev_x2(k: String) -> Image:
	var kk := k + "@2"
	if REV_ART.has(kk):
		return REV_ART[kk]
	var im: Image = REV_ART[k].duplicate()
	im.resize(im.get_width() * 2, im.get_height() * 2, Image.INTERPOLATE_NEAREST)
	REV_ART[kk] = im
	return im

# la ilustración de la portada del número n
func rev_ilu(n: int) -> String:
	for e in rev_nw_de(n):
		var k := String(e.df.k)
		if REV_ILU.has(k):
			return String(REV_ILU[k])
	if S.get("mar") is Dictionary and (S.mar.get("lic") or (S.mar.get("b") is Array and S.mar.b.size() > 1)):
		return "barco"
	var mes := int(Datos.fecha(int(S.day)).m)
	if mes == 10 or mes == 11:
		return "copa"
	if mes == 5:
		return "feria"
	if S.get("nave") is Dictionary and S.nave.get("r") != null:
		return "nave"
	if S.get("aso") is Dictionary and S.aso.get("pres"):
		return "club"
	if S.get("carpas") is Array and not S.carpas.is_empty():
		return "carpa"
	return "planta"

# las planas del número: una por sección (las largas, partidas), con su viñeta y su título
func rev_paginas(n: int) -> Dictionary:
	var pags: Array[String] = []
	var tit: Array[String] = []
	var vg: Array[String] = []
	var secs := rev_secciones(n)
	var pie := ""
	if not secs.is_empty() and String(secs[-1].k) == "pie":
		pie = String(secs.pop_back().txt)
	for i in secs.size():
		var q: Dictionary = secs[i]
		var txt := String(q.txt)
		if String(q.k) == "port":
			pags.append("%s\n%s" % [String(q.cab), txt])   # la cabecera y el titular, seguidos: la portada tiene el hueco justo
			tit.append("")
			vg.append("")
			continue
		if i == secs.size() - 1 and pie != "":   # el pie de la revista cierra la última plana
			txt += "\n\n" + pie
		var trozos := paginas(txt, 380)   # lo que cabe en una plana sin apretar; si se pasa, se desliza con ▲▼
		for t in trozos.size():
			pags.append(String(trozos[t]))
			tit.append(String(q.tit) if t == 0 else "%s (%d)" % [String(q.tit), t + 1])
			vg.append(String(REV_VG.get(String(q.k), "")))
	return {"n": n, "pags": pags, "tit": tit, "vg": vg, "ilu": rev_ilu(n), "pst": rev_pst_pl(n)}

# la clave de la plana que se está viendo (la de su viñeta: «anu» el anuncio, «pst» el póster central)
func rev_vg_i() -> String:
	var vgs: Array = lector_rev.get("vg", [])
	return String(vgs[lector_i]) if lector_i >= 0 and lector_i < vgs.size() else ""

# el hueco que le queda al texto: en la portada, debajo de la mancheta y la foto; abierta, la hoja de la derecha entera (el arte
# y la foto se quedan en la de la izquierda). En píxeles del lienzo; ui.gd coloca ahí el lector
func rev_zona() -> Rect2i:
	var h := rev_hoja(true)
	if rev_portada():
		return Rect2i(h.position.x + 8, h.position.y + 102, h.size.x - 16, h.size.y - 112)
	if rev_vg_i() == "anu":   # el anuncio ocupa la hoja: el texto, dentro de su recuadro
		return Rect2i(h.position.x + 13, h.position.y + 34, h.size.x - 26, h.size.y - 56)
	return Rect2i(h.position.x + 8, h.position.y + 9, h.size.x - 16, h.size.y - 24)

# el papel de una hoja, tileado y con sus cantos
func _rev_papel(h: Rect2i) -> Array:
	var o := []
	var clip := Rect2i(h.position.x, h.position.y, h.size.x, h.size.y)
	var pap: Image = REV_ART["papel"]
	var y := h.position.y
	while y < h.end.y:
		var x := h.position.x
		while x < h.end.x:
			o.append(["@", pap, x, y, clip])
			x += pap.get_width()
		y += pap.get_height()
	o.append([h.position.x, h.position.y - 1, h.size.x, 1, "#8a8372"])
	o.append([h.position.x, h.end.y, h.size.x, 1, "#8a8372"])
	o.append([h.position.x - 1, h.position.y, 1, h.size.y, "#8a8372"])
	o.append([h.end.x, h.position.y, 1, h.size.y, "#8a8372"])
	return o

# la revista dibujada: la sombra sobre la mesa, las hojas con su papel, el lomo con las grapas, y encima lo de cada plana (la
# portada con su mancheta y su ilustración; abierta, el arte en la hoja izquierda y los filetes del texto en la derecha). Lo pinta
# _encima() de pinta.gd
func rects_revista() -> Array:
	var o := []
	if lector_rev.is_empty() or not rev_art():
		return o
	var c := rev_caja()
	var por := rev_portada()
	var vk := rev_vg_i()
	o.append([c.position.x + 3, c.position.y + 4, c.size.x, c.size.y, "#1c1a1655"])   # la sombra de la revista en la mesa
	var hi := rev_hoja(false)
	var hd := rev_hoja(true)
	o.append_array(_rev_papel(hi))
	if not por:
		o.append_array(_rev_papel(hd))
		var lx: int = hi.end.x
		o.append([lx, c.position.y, REV_LOMO, c.size.y, "#cdc3a8"])   # el lomo, en sombra
		o.append([lx, c.position.y, 1, c.size.y, "#8a8372"])
		o.append([lx + REV_LOMO - 1, c.position.y, 1, c.size.y, "#8a8372"])
		var gr: Image = REV_ART["grapa"]
		var gclip := Rect2i(c.position.x, c.position.y, c.size.x, c.size.y)
		for g in [c.position.y + 38, c.end.y - 50]:   # las dos grapas del lomo
			o.append(["@", gr, lx + ((REV_LOMO - gr.get_width()) >> 1), g, gclip])
	if por:   # la portada: mancheta, filete, la ilustración del mes y la cinta del reclamo
		var clip := Rect2i(hi.position.x, hi.position.y, hi.size.x, hi.size.y)
		var mc: Image = REV_ART[rev_mancheta()]
		o.append(["@", mc, hi.position.x + ((hi.size.x - mc.get_width()) >> 1), hi.position.y + 4, clip])
		o.append_array(_rev_filete("filete", hi.position.x + 8, hi.position.y + 42, hi.size.x - 16, clip))
		var il: Image = REV_ART.get("pt-" + String(lector_rev.get("ilu", "planta")), REV_ART["pt-planta"])
		var ix: int = hi.position.x + ((hi.size.x - il.get_width()) >> 1)
		var iy: int = hi.position.y + 48
		o.append(["@", il, ix, iy, Rect2i(ix, iy, il.get_width(), 48).intersection(clip)])
		o.append([ix - 1, iy - 1, il.get_width() + 2, 1, "#2b2a26"])   # el marco de la foto
		o.append([ix - 1, iy + 48, il.get_width() + 2, 1, "#2b2a26"])
		o.append([ix - 1, iy, 1, 48, "#2b2a26"])
		o.append([ix + il.get_width(), iy, 1, 48, "#2b2a26"])
		o.append_array(_rev_filete("filete", hi.position.x + 8, hi.position.y + 98, hi.size.x - 16, clip))
		o.append(["@", REV_ART["cinta"], hi.end.x - 28, iy + 2, clip])   # la cinta del reclamo, en la esquina de la foto
	else:
		var clip := Rect2i(hi.position.x, hi.position.y, hi.size.x, hi.size.y)
		# la hoja de la izquierda: el cintillo de la sección, la foto grande con su marco y, debajo, el despiece
		o.append_array(_rev_filete("filete", hi.position.x + 8, hi.position.y + 8, hi.size.x - 16, clip))
		if vk == "pst":   # el póster central: la lámina a toda hoja
			var pl: Image = REV_ART.get(String(lector_rev.get("pst", "ps-hib")), REV_ART["ps-hib"])
			var px: int = hi.position.x + ((hi.size.x - pl.get_width()) >> 1)
			o.append(["@", pl, px, hi.position.y + 50, clip])
			o.append([px - 1, hi.position.y + 49, pl.get_width() + 2, 1, "#2b2a26"])
			o.append([px - 1, hi.position.y + 50 + pl.get_height(), pl.get_width() + 2, 1, "#2b2a26"])
			o.append(["@", rev_x2("vg-pst"), hi.position.x + ((hi.size.x - 48) >> 1), hi.position.y + 16, clip])
		elif vk == "anu":   # el anuncio: el megáfono grande a la izquierda y el recuadro en la hoja del texto
			o.append(["@", rev_x2("vg-anu"), hi.position.x + ((hi.size.x - 48) >> 1), hi.position.y + 46, clip])
			o.append_array(_rev_filete("filete", hi.position.x + 8, hi.position.y + 104, hi.size.x - 16, clip))
			var ax: int = hd.position.x + 8
			var aw: int = hd.size.x - 16
			var ay: int = hd.position.y + 24
			var ah: int = hd.size.y - 40
			o.append([ax, ay, aw, ah, "#f7f2e2"])
			o.append([ax, ay, 2, ah, "#2b2a26"])
			o.append([ax + aw - 2, ay, 2, ah, "#2b2a26"])
			var dclip := Rect2i(hd.position.x, hd.position.y, hd.size.x, hd.size.y)
			o.append_array(_rev_filete("filete", ax, ay, aw, dclip))
			o.append_array(_rev_filete("filete", ax, ay + ah - 5, aw, dclip))
		else:
			var fo: Image = REV_ART.get("pt-" + String(REV_FOTO.get(vk, "planta")), REV_ART["pt-planta"])
			var fx: int = hi.position.x + ((hi.size.x - fo.get_width()) >> 1)
			var fy: int = hi.position.y + 16
			var fh: int = mini(fo.get_height(), REV_FOTO_H)   # la foto, apaisada: le deja la mitad de abajo de la hoja al despiece
			o.append(["@", fo, fx, fy, Rect2i(fx, fy, fo.get_width(), fh).intersection(clip)])
			o.append([fx - 1, fy - 1, fo.get_width() + 2, 1, "#2b2a26"])
			o.append([fx - 1, fy + fh, fo.get_width() + 2, 1, "#2b2a26"])
			o.append([fx - 1, fy, 1, fh, "#2b2a26"])
			o.append([fx + fo.get_width(), fy, 1, fh, "#2b2a26"])
			o.append_array(_rev_filete("filete2", hi.position.x + 8, fy + fh + 6, hi.size.x - 16, clip))
			# el despiece: la viñeta de la sección al doble, en su recuadro (si no cabe en la hoja, a su tamaño)
			if vk != "" and REV_ART.has("vg-" + vk):
				var vi: Image = rev_x2("vg-" + vk)
				var vy: int = fy + fh + 20
				if vy + vi.get_height() + 8 > hi.end.y:
					vi = REV_ART["vg-" + vk]
					vy = fy + fh + 16
				var vx: int = hi.position.x + ((hi.size.x - vi.get_width()) >> 1)
				o.append([vx - 6, vy - 6, vi.get_width() + 12, vi.get_height() + 12, "#f7f2e2"])
				o.append(["@", vi, vx, vy, clip])
				o.append([vx - 6, vy - 6, vi.get_width() + 12, 1, "#8a8372"])
				o.append([vx - 6, vy + vi.get_height() + 5, vi.get_width() + 12, 1, "#8a8372"])
			if vk == "tst":   # el banco de pruebas, con el sello de la nota
				o.append(["@", REV_ART["sello"], hi.end.x - 30, hi.position.y + 12, clip])
		# la hoja de la derecha: los filetes de la cabecera y del pie del texto
		var dclip2 := Rect2i(hd.position.x, hd.position.y, hd.size.x, hd.size.y)
		if vk != "anu":
			o.append_array(_rev_filete("filete2", hd.position.x + 8, hd.position.y + 26, hd.size.x - 16, dclip2))
			o.append_array(_rev_filete("filete2", hd.position.x + 8, hd.end.y - 16, hd.size.x - 16, dclip2))
	var np: int = lector_rev.pags.size()   # el pie: un punto por plana, el de esta relleno
	if np > 1:
		var ax: int = c.position.x + ((c.size.x - (np * 5 - 2)) >> 1)
		for i in np:
			o.append([ax + i * 5, c.end.y - 7, 3, 3, "#27551a" if i == lector_i else "#9a9382"])
	return o

# la cabecera dibujada, en el idioma del juego: el nombre de la revista es texto traducido (EL ESQUEJE / THE CUTTING), así que
# la mancheta en español solo vale mientras el nombre no cambie
func rev_mancheta() -> String:
	var nom := String(D.REVISTA.cab.n)
	if I18n.v(nom).to_upper() != nom.to_upper() and REV_ART.has("mancheta-en"):
		return "mancheta-en"
	return "mancheta"

func _rev_filete(k: String, x: int, y: int, w: int, clip: Rect2i) -> Array:
	var o := []
	var im: Image = REV_ART[k]
	var c := Rect2i(x, y, w, im.get_height()).intersection(clip)
	var i := x
	while i < x + w:
		o.append(["@", im, i, y, c])
		i += im.get_width()
	return o
