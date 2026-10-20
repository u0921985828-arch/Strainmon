# MAESTRO [7] (con Datos.CAL): la gente con gustos y manera de ser (el arquetipo), la manera de hablar por zona (pueblo, barrio y
# centro), las charlas con memoria y los encargos que salen de ellas, fiar a los de la agenda, los pedidos por efecto y aroma, los
# combates con golpes, armas y estados (sangrado y aturdido) y las tiendas por secciones, tipos y marcas. Todo por Datos.hash_str.
# Cadena: … → campo → gestion → vida → retencion → juego.
extends "res://src/gestion.gd"

func vida_ok() -> bool:
	return Datos.CAL and D.has("GENTE7") and S != null

func _h(s: String) -> int:
	return Datos.hash_str(s)

func _elige(L: Array, sal: String):
	return L[_h(sal) % L.size()]

func quien(c: Dictionary) -> String:
	return String(c.get("fid", c.get("id", "")))

# ---------- la manera de hablar por zona ----------
func zona_habla(mapa: String) -> String:
	for k in D.GENTE7.zonas:
		if mapa in D.GENTE7.zonas[k]:
			return k
	return "obrero"

func jerga(k: String, sal: String, mapa := "") -> String:
	return String(_elige(D.GENTE7.jerga[zona_habla(mapa if mapa != "" else String(S.map))][k], "%s|%s|%d|%d" % [k, sal, int(S.day), int(S.min)]))

# ---------- gustos, arquetipo y pedidos ----------
# (lo pidió el usuario tras probarlo: «que no pidan un híbrido de sativa»): el gusto es solo el olor y el pedido, solo lo fuerte
# que sea (el THC); el efecto (ef_de, de la genética) queda para el colocón, no para lo que pide la gente
func ef_de(sid: String) -> String:
	var ind := float(Datos.ind_de(S, lot_sid(sid)))
	return "indica" if ind >= 65 else ("sativa" if ind <= 35 else "hibrida")

func ef_txt(ef: String) -> String:
	return {"indica": K("índica"), "sativa": K("sativa"), "hibrida": K("híbrida")}[ef]

func gusto_de(id: String) -> Dictionary:
	var h := _h("gusto|" + id)
	return {"ar": String(D.AROMAS[(h / 3) % D.AROMAS.size()])}

func gusto_txt(id: String) -> String:
	var g := gusto_de(id)
	return T("Le gusta la de olor {a}.", {"a": g.ar})

func arq_de(c: Dictionary) -> String:
	var L: Array = D.GENTE7.arq.get(String(c.get("type", c.get("t", "cur"))), ["currela"])
	return String(L[_h("arq|" + quien(c)) % L.size()])

func arq_txt(a: String) -> String:
	return String(D.GENTE7.arqs.get(a, D.GENTE7.arqs.currela).n)

# el pedido del día: {thc} o {} (el catador no pide así)
func pedido_de(c: Dictionary) -> Dictionary:
	if not vida_ok() or c.get("type") == "ext":
		return {}
	var P: Dictionary = D.GENTE7.pedido
	var q := quien(c)
	if _h("pedido|%s|%d" % [q, int(S.day)]) % 100 >= int(float(P.p) * 100):
		return {}
	return {"thc": int(P.thc[0]) + _h("pthc|" + q) % (int(P.thc[1]) - int(P.thc[0]) + 1)}

func casa_pedido(p: Dictionary, sid: String, b: Dictionary) -> bool:
	return not p.is_empty() and float(b.thc) >= float(p.thc)

func cuantos_gustos(c: Dictionary, sid: String) -> int:
	var g := gusto_de(quien(c))
	return 1 if aroma_de(lot_sid(sid)) == g.ar else 0

# ---------- la memoria (S.mem[id] = {n, d, s, ok, mal, fav}) ----------
func mem(id: String) -> Dictionary:
	if not (S.get("mem") is Dictionary):
		S.mem = {}
	if not S.mem.has(id):
		S.mem[id] = {"n": 0, "d": 0, "s": "", "ok": 0, "mal": 0, "fav": 0}
	return S.mem[id]

# el saludo de un cliente: lo que recuerda de ti, un chisme si le hiciste un favor o la manera de hablar de su zona
func cal_saludo(c: Dictionary, N: String) -> bool:
	if not vida_ok():
		return false
	var q := quien(c)
	var M_: Dictionary = mem(q) if c.get("fid") else {}
	var mapa := String(c.get("map", S.map))
	if not M_.is_empty() and fiado_de(q) != null and fiado_de(q).get("imp"):
		await say(K("Oye… lo de lo que te debo, que no me olvido. Dame un poco más."), N)
	elif not M_.is_empty() and int(M_.fav):
		M_.fav = 0
		S.heat = maxf(0, float(S.heat) - float(D.GENTE7.fiar.favor))
		await say(K("Por fiarme el otro día, te cuento una cosa:"), N)
		await say(jerga("chisme", q, mapa), N)
	elif not M_.is_empty() and int(M_.n) >= 1 and String(M_.s) != "" and D.STRAINS.has(lot_sid(String(M_.s))):
		await say(T("¿Qué tal? La {s} de la otra vez estaba de diez.", {"s": lot_nombre(String(M_.s))}), N)
	else:
		await say(jerga("hola", q, mapa), N)
	return true

func cal_busco(c: Dictionary) -> String:
	var p := pedido_de(c)
	if p.is_empty():
		return ""
	return T("Busco {g} g de algo fuerte, del {t} % de THC para arriba. Si me lo traes, te lo pago bien.", {"g": n(c.want), "t": int(p.thc)})

# el precio: con el pedido acertado, PEDIDO.plus más
func cal_precio(c: Dictionary, sid: String, b: Dictionary) -> float:
	if not vida_ok():
		return 1.0
	return 1.0 + float(D.GENTE7.pedido.plus) if casa_pedido(pedido_de(c), sid, b) else 1.0

# lo que cuela al pedir lo justo o caro: el pedido equivocado resta; sin pedido, lo que le va suma
func cal_acc(c: Dictionary, sid: String, b: Dictionary, j: int, acc: float) -> float:
	if not vida_ok() or j == 0:
		return acc
	var p := pedido_de(c)
	if not p.is_empty():
		return acc if casa_pedido(p, sid, b) else maxf(.05, acc - float(D.GENTE7.pedido.menos))
	return minf(.97, acc + cuantos_gustos(c, sid) * float(D.GENTE7.pedido.gusto))

func cal_frase(k: String, c: Dictionary) -> String:
	return jerga(k, quien(c), String(c.get("map", S.map))) if vida_ok() else ""

# después de vender: el regalo del pedido acertado, la memoria y, a veces, un encargo
func cal_vendido(c: Dictionary, sid: String, b: Dictionary, N: String) -> void:
	if not vida_ok():
		return
	var q := quien(c)
	if casa_pedido(pedido_de(c), sid, b):
		var R: Array = _elige(D.GENTE7.pedido.regalo, "regalo|%s|%d" % [q, int(S.day)])
		S.items[String(R[0])] = int(S.items.get(String(R[0]), 0)) + int(R[1])
		await say(T("«Justo lo que buscaba.» Te da también {x}.", {"x": nombre_regalo(String(R[0]), int(R[1]))}), N)
	if c.get("fid"):
		var M_ := mem(q)
		M_.n = int(M_.n) + 1
		M_.d = int(S.day)
		M_.s = sid
		await ofrece_encargo(N, q)

func nombre_regalo(k: String, nn: int) -> String:
	match k:
		"papel":
			return T("{n} hojas de papel", {"n": nn})
		"mechero":
			return K("un mechero")
		"bocata":
			return K("un bocata")
		"spray":
			return K("un spray de pimienta")
	return k

# ---------- fiar (S.fiado = [{id, n, arq, e, d, dia, imp, ult}]) ----------
func fiados() -> Array:
	if not (S.get("fiado") is Array):
		S.fiado = []
	return S.fiado

func fiado_de(id: String):
	for f in fiados():
		if String(f.id) == id:
			return f
	return null

func nombre_fijo_id(id: String, def: String) -> String:
	for f in S.fijos:
		if String(f.id) == id:
			return String(f.n)
	return def

# 0: paga ya · 1: fiado (no cobras ahora)
func cal_fiar(c: Dictionary, e: int) -> int:
	if not vida_ok() or not c.get("fid"):
		return 0
	var F: Dictionary = D.GENTE7.fiar
	var q := quien(c)
	if fiados().size() >= int(F.max) or fiado_de(q) != null:
		return 0
	if _h("fiar|%s|%d" % [q, int(S.day)]) % 100 >= int(float(F.p) * 100):
		return 0
	var N := String(c.get("n", ""))
	var d: int = int(F.dias[0]) + _h("fdias|" + q) % (int(F.dias[1]) - int(F.dias[0]) + 1)
	var k: int = await ask(T("Me pillas sin un duro. ¿Me lo fías hasta el {d}? Te lo pago, palabra.", {"d": Datos.fd(int(S.day) + d, int(S.day))}), [K("Fiárselo"), K("Que pague ya")], N)
	if k == 0:
		fiados().append({"id": q, "n": nombre_fijo_id(q, N), "arq": arq_de(c), "e": e, "d": int(S.day) + d, "dia": int(S.day)})
		confia(q, 2)
		await say(K("«Eres de los buenos. No te fallo.»"), N)
		return 1
	confia(q, -1)
	await say(K("Rebusca en todos los bolsillos y al final te lo paga, a regañadientes."))
	return 0

# cada mañana: los que vencen pagan (al buzón) o no según su arquetipo (el jubilado, tarde pero paga); los encargos caducan
func vida_dia() -> void:
	if not vida_ok():
		return
	var F: Dictionary = D.GENTE7.fiar
	for f in fiados().duplicate():
		if f.get("imp"):
			continue
		var A: Dictionary = D.GENTE7.arqs.get(String(f.arq), D.GENTE7.arqs.currela)
		if int(S.day) < int(f.d) + int(A.tarde):
			continue
		var N := T("SMS · {n}", {"n": String(f.n).to_upper()})
		var M_ := mem(String(f.id))
		if _h("paga|%s|%d" % [String(f.id), int(f.dia)]) % 100 < int(float(A.paga) * 100):
			S.money = float(S.money) + int(f.e)
			S.sales = int(S.sales) + int(f.e)
			confia(String(f.id), 5)
			M_.ok = int(M_.ok) + 1
			M_.fav = 1
			fiados().erase(f)
			var tx := T("Te he dejado {e} en el buzón. Gracias por fiarme; te debo una.", {"e": Datos.eur(int(f.e))})
			queue("fiado" + String(f.id), func(): await talk(N, [tx]), [[N, [tx]]])
		else:
			f.imp = true
			M_.mal = int(M_.mal) + 1
			var tx := K("No llego, de verdad. Dame unos días.")
			queue("fiado" + String(f.id), func(): await talk(N, [tx]), [[N, [tx]]])
	var E = S.get("encargo7")
	if E is Dictionary and int(S.day) > int(E.d):
		S.encargo7 = null
		S.rep = maxi(0, int(S.rep) - 1)
		var N2 := T("SMS · {n}", {"n": String(E.n).to_upper()})
		var t2 := K("Ya no hace falta. Otra vez será.")
		queue("encargo7", func(): await talk(N2, [t2]), [[N2, [t2]]])

func fila_deuda(f: Dictionary) -> Dictionary:
	return {"label": String(f.n), "right": (T("{e} · no paga", {"e": Datos.eur(int(f.e))}) if f.get("imp") else T("{e} · el {d}", {"e": Datos.eur(int(f.e)), "d": Datos.fd_corto(int(f.d))})),
		"desc": T("{a}. Le fiaste el {d}.", {"a": may1(I18n.v(arq_txt(String(f.arq)))), "d": Datos.fd(int(f.dia), int(S.day))})}

func deudas() -> void:
	var i := 0
	while true:
		var L := fiados()
		if L.is_empty():
			await say(K("Nadie te debe nada."))
			return
		var rows := L.map(fila_deuda)
		rows.append({"label": K("Volver")})
		i = await menu(rows, {"cls": "full", "title": K("DEUDAS"), "desc": true, "initial": clampi(i, 0, rows.size() - 1)})
		if i < 0 or i >= L.size():
			return
		await deuda(L[i])

func deuda(f: Dictionary) -> void:
	var F: Dictionary = D.GENTE7.fiar
	var N := String(f.n)
	if not f.get("imp"):
		await say(T("{n} te debe {e}. Vence el {d}.", {"n": N, "e": Datos.eur(int(f.e)), "d": Datos.fd(int(f.d), int(S.day))}))
		return
	if int(f.get("ult", -1)) == int(S.day):
		await say(T("Ya has hablado hoy con {n}. Déjale respirar.", {"n": N}))
		return
	var e2 := int(round(int(f.e) * (1 + float(F.interes))))
	var c: int = await ask(T("{n} no te ha pagado los {e}. ¿Qué haces?", {"n": N, "e": Datos.eur(int(f.e))}), [K("Perdonarle"), T("Exigirle {e}", {"e": Datos.eur(e2)}), K("Amenazarle"), K("Nada")])
	if c == 0:
		fiados().erase(f)
		S.rep = int(S.rep) + int(F.rep)
		confia(String(f.id), int(F.rel))
		await say(K("«Te debo la vida. En el barrio se va a saber que eres legal.»"), N)
	elif c == 1:
		f.ult = int(S.day)
		if not D.ZONAS.has(S.map):
			await say(K("Para cobrar hay que quedar en la calle."))
			f.erase("ult")
			return
		var A: Dictionary = D.GENTE7.arqs.get(String(f.arq), D.GENTE7.arqs.currela)
		if _h("pelea|%s|%d" % [String(f.id), int(S.day)]) % 100 < int(float(A.pelea) * 100):
			await say(T("{n} se pone chulo: «¿Intereses? Te vas a enterar».", {"n": N}))
			var r = await battle("thief")
			if r == "win":
				fiados().erase(f)
				S.money = float(S.money) + e2
				S.sales = int(S.sales) + e2
				await say(T("Al final suelta los {e}.", {"e": Datos.eur(e2)}))
			return
		if _h("exige|%s|%d" % [String(f.id), int(S.day)]) % 100 < int(float(F.exige) * 100):
			fiados().erase(f)
			S.money = float(S.money) + e2
			S.sales = int(S.sales) + e2
			confia(String(f.id), -5)
			sfx("coin")
			await say(T("Te paga los {e}, intereses incluidos, mirando al suelo.", {"e": Datos.eur(e2)}), N)
		else:
			await say(K("«No tengo nada, te lo juro.» Hoy no le sacas ni un euro."), N)
	elif c == 2:
		f.ult = int(S.day)
		S.heat = minf(100, float(S.heat) + float(F.calor))
		confia(String(f.id), -20)
		if _h("amenaza|%s|%d" % [String(f.id), int(S.day)]) % 100 < int(float(F.amenaza) * 100):
			fiados().erase(f)
			S.money = float(S.money) + int(f.e)
			S.sales = int(S.sales) + int(f.e)
			await say(T("Se asusta y te paga los {e}. En el barrio se habla de ti, y no para bien.", {"e": Datos.eur(int(f.e))}), N)
		else:
			await say(K("Se esconde: no te coge el teléfono. Y alguien ha oído la amenaza."), N)
		heat_warn()

# ---------- los encargos de las charlas (S.encargo7 = {q, n, pu, g, ef, d, e}) ----------
func pueblos_encargo() -> Array:
	var aqui := preload("res://src/croquis.gd").pueblo_de(String(S.map))
	return D.GENTE7.encargo.pu.keys().filter(func(k): return k != aqui and D.PARADAS.has(k) and int(S.ch) >= int(D.PARADAS[k].cap))

func ofrece_encargo(N: String, sal: String) -> void:
	if not vida_ok() or S.get("encargo7") is Dictionary:
		return
	var E: Dictionary = D.GENTE7.encargo
	if int(S.rep) < int(E.rep):
		return
	var pz := float(E.p) * (2.0 if borr() >= float(E.borr) else 1.0)   # con unas copas encima, la gente te cuenta más
	if _h("encargo|%s|%d" % [sal, int(S.day)]) % 100 >= int(pz * 100):
		return
	var pus := pueblos_encargo()
	if pus.is_empty():
		return
	var pu: String = _elige(pus, "epu|%s|%d" % [sal, int(S.day)])
	var g: int = int(E.g[0]) + _h("eg|" + sal) % (int(E.g[1]) - int(E.g[0]) + 1)
	var th: int = int(D.GENTE7.pedido.thc[0]) + _h("eef|%s|%d" % [sal, int(S.day)]) % (int(D.GENTE7.pedido.thc[1]) - int(D.GENTE7.pedido.thc[0]) + 1)
	var d: int = int(E.dias[0]) + _h("ed|" + sal) % (int(E.dias[1]) - int(E.dias[0]) + 1)
	var e: int = int(round(g * precio_calle(18) * float(E.plus)))
	var qn: String = _elige(E.quien, "eq|" + sal)
	var c: int = await ask(T("Por cierto: {q} en {p} necesita {g} g de algo del {t} % para arriba. Si se los llevas antes del {d}, te paga {e}. ¿Te animas?", {"q": qn, "p": E.pu[pu], "g": g, "t": th, "d": Datos.fd(int(S.day) + d, int(S.day)), "e": Datos.eur(e)}), [K("Me animo"), K("Paso")], N)
	if c != 0:
		return
	S.encargo7 = {"q": sal, "n": T("{q} de {n}", {"q": qn, "n": may1(N.to_lower())}), "pu": pu, "g": g, "t": th, "d": int(S.day) + d, "e": e}
	await say(T("«Te paso su número. Cuando estés en {p}, llámale.»", {"p": E.pu[pu]}), N)

func cal_llamar_filas() -> Array:
	var E = S.get("encargo7") if vida_ok() else null
	if not (E is Dictionary):
		return []
	return [{"label": String(E.n), "right": D.GENTE7.encargo.pu[E.pu], "desc": T("Encargo: {g} g del {t} % para arriba antes del {d}. Paga {e}.", {"g": int(E.g), "t": int(E.get("t", 0)), "d": Datos.fd(int(E.d), int(S.day)), "e": Datos.eur(int(E.e))}), "enc": E}]

func entrega_encargo(E: Dictionary) -> void:
	var N := String(E.n).to_upper()
	if preload("res://src/croquis.gd").pueblo_de(String(S.map)) != String(E.pu) or not D.ZONAS.has(S.map):
		await say(T("«Estoy en {p}. Llámame cuando estés por aquí, en la calle.»", {"p": D.GENTE7.encargo.pu[E.pu]}), N)
		return
	var lots := bud_lots(float(E.g), float(E.get("t", 0)))   # los de antes (con «ef»), cualquiera
	if lots.is_empty():
		await say(T("«¿No traes {g} g del {t} % para arriba? Entonces nada.»", {"g": int(E.g), "t": int(E.get("t", 0))}), N)
		return
	var it := lots.map(lot_item)
	it.append({"label": K("Nada")})
	var i: int = await menu(it, {"cls": "right", "title": K("¿Qué le llevas?")})
	if i < 0 or i >= lots.size():
		return
	use_buds(String(lots[i][0]), float(E.g))
	S.money = float(S.money) + int(E.e)
	S.sales = int(S.sales) + int(E.e)
	S.rep = int(S.rep) + 3
	confia(String(E.q), 5)
	S.encargo7 = null
	sfx("coin")
	await say(T("Viene en diez minutos, mira el material y te paga {e}. «Ya me dijeron que eras de fiar.»", {"e": Datos.eur(int(E.e))}), N)
	await check_story()

# las charlas sentado (en el bar, el club o un banco): un chisme de la zona y, a veces, un encargo
func cal_charla(e) -> void:
	if not vida_ok() or e.get("pat") or not (e.get("def") is Dictionary) or e.def.get("client"):
		return
	if not (S.get("charla7") is Dictionary):
		S.charla7 = {}
	var id := String(e.id)
	if int(S.charla7.get(id, -1)) == int(S.day):
		return
	S.charla7[id] = int(S.day)
	await say(jerga("chisme", id), K("GENTE"))
	await ofrece_encargo(K("GENTE"), id)

# ---------- los combates: golpes, armas y estados ----------
func c7() -> bool:
	return Datos.CAL and D.has("COMBATE7") and B != null

func _br(tag: String) -> int:
	B.r = int(B.get("r", 0)) + 1
	return _h("%s|%d|%d|%s" % [tag, int(S.day), int(B.r), String(B.name)])

func arma() -> String:
	for k in ["bate", "cadena"]:
		if int(S.items.get(k, 0)) > 0:
			return k
	return ""

func arma_rival() -> void:
	if not c7() or B.get("jefe"):
		return
	B.navaja = _br("navaja") % 100 < int(float(D.COMBATE7.navaja) * 100)

func golpe_txt(mv: String) -> String:
	var t := I18n.v(String(_elige(D.COMBATE7.golpes[mv], "golpe|%d|%d" % [int(S.day), int(B.get("r", 0))])))
	var a := arma()
	return t + ((K(" Con el bate, se nota.") if a == "bate" else K(" Con la cadena, se nota.")) if a != "" else "")

func arma_d() -> int:
	var a := arma()
	return int(D.COMBATE7.armas[a].d) if c7() and a != "" else 0

# después de un golpe tuyo que entra: con el bate, aturdido (no te pega en su turno); con la cadena, sangra unos turnos
func tras_golpe() -> void:
	if not c7():
		return
	var a := arma()
	var C: Dictionary = D.COMBATE7
	var pa := float(C.armas.bate.aturde) if a == "bate" else float(C.aturde)
	if _br("aturde") % 100 < int(pa * 100):
		B.aturde = 1
		await say(T("{b} se queda aturdido.", {"b": el_b()}))
	if a == "cadena" and not B.get("sangra") and _br("sangra") % 100 < int(float(C.armas.cadena.sangra) * 100):
		B.sangra = int(C.sangra.turnos)
		await say(T("{b} sangra.", {"b": el_b()}))

# al acabar tu turno: lo que sangra cada uno (tú no caes por sangrar: te quedas en 1)
func sangra_tick() -> void:
	if not c7():
		return
	var d := int(D.COMBATE7.sangra.d)
	if int(B.get("sangra", 0)) > 0 and B.hp > 0:
		B.sangra = int(B.sangra) - 1
		B.hp -= d
		bhud_act()
		await say(T("{b} sigue sangrando: −{d}.", {"b": el_b(), "d": d}))
	if int(B.get("psangra", 0)) > 0:
		B.psangra = int(B.psangra) - 1
		S.hp = maxi(1, int(S.hp) - d)
		bhud_act()
		await say(T("El corte te sigue sangrando: −{d}.", {"d": d}))

func aturdido() -> bool:
	if not c7() or not B.get("aturde"):
		return false
	B.aturde = 0
	await say(T("{b} no se tiene en pie: no te ataca.", {"b": el_b()}))
	return true

func recibe_txt() -> String:
	return T(_elige(D.COMBATE7.recibe, "recibe|%d|%d" % [int(S.day), int(B.get("r", 0))]), {"b": el_b()})

# cuando te da: si lleva navaja, a veces te corta y sangras unos turnos
func corte() -> void:
	if not c7() or not B.get("navaja") or int(B.get("psangra", 0)) > 0:
		return
	if _br("corte") % 100 < int(float(D.COMBATE7.pcorta) * 100):
		B.psangra = int(D.COMBATE7.sangra.turnos)
		await say(T("{b} saca una navaja y te alcanza en el brazo. Sangras.", {"b": el_b()}))

func armas_venta() -> Array:
	var r := []
	for k in D.COMBATE7.armas:
		if int(S.items.get(k, 0)) <= 0:
			var A: Dictionary = D.COMBATE7.armas[k]
			r.append({"lbl": A.n, "p": int(A.p), "desc": A.desc, "arma": k})
	return r

# ---------- las tiendas por secciones, tipos y marcas ----------
# [sección, tipo]: el tipo es la clave de CATALOGO.marcas y se traduce al pintarlo
func cat_de(it: Dictionary) -> Array:
	if it.get("sub"):
		return [{"Papel y filtros": "fumar", "Tabaco": "fumar", "Mecheros": "fumar"}.get(String(it.sub), "varios"), String(it.sub)]   # i18n-no
	if it.get("sid"):
		var s: Dictionary = D.STRAINS.get(String(it.sid), {})
		if s.get("auto"):
			return ["semillas", "Autoflorecientes"]   # i18n-no
		var ind := float(s.get("ind", 50))
		return ["semillas", "Índicas" if ind >= 65 else ("Sativas" if ind <= 35 else "Híbridas")]   # i18n-no
	if it.get("foco"):
		return ["luz", "LED" if String(it.foco).begins_with("led") else "Sodio"]   # i18n-no
	if it.get("carpa"):
		return ["cultivo", "Carpas"]   # i18n-no
	if it.get("maceta"):
		return ["cultivo", "Macetas"]   # i18n-no
	if it.get("mueble"):
		return ["cultivo", "Carros"]   # i18n-no
	if it.get("extra"):
		var x := String(it.extra)
		if x in ["goteo", "garrafas"]:
			return ["riego", "Riego"]   # i18n-no
		if x == "sello":
			return ["plagas", "Tratamientos"]   # i18n-no
		return ["clima", "Ventilación" if x == "vent" else "Extracción"]   # i18n-no
	if it.get("aparato"):
		return ["clima", "Climatización"]   # i18n-no
	if it.get("bolsa"):
		return ["varios", "Bolsas"]   # i18n-no
	var k := String(it.get("item", ""))
	if k in ["fert", "fertv", "phm"]:
		return ["riego", "Abono mineral"]   # i18n-no
	if k in ["ofert", "ofertv", "ophm"]:
		return ["riego", "Abono orgánico"]   # i18n-no
	if k == "medidor":
		return ["riego", "Medición"]   # i18n-no
	if k in ["insect", "fungi", "prevent"]:
		return ["plagas", "Tratamientos"]   # i18n-no
	if k in ["prensa", "tamiz", "ice"]:
		return ["extraccion", "Prensas y tamices"]   # i18n-no
	if k in ["lavadora", "estatica"]:
		return ["extraccion", "Máquinas"]   # i18n-no
	if k == "tarros":
		return ["extraccion", "Curado"]   # i18n-no
	if k == "analizador":
		return ["extraccion", "Análisis"]   # i18n-no
	if k in ["grinder", "pipa", "bong", "vapo"]:
		return ["fumar", "Pipas y bongs"]   # i18n-no
	if k in ["papel", "filtros"]:
		return ["fumar", "Papel y filtros"]   # i18n-no
	if k == "tabaco":
		return ["fumar", "Tabaco"]   # i18n-no
	if k == "mechero":
		return ["fumar", "Mecheros"]   # i18n-no
	if k == "bocata":
		return ["varios", "Comida"]   # i18n-no
	if k == "spray":
		return ["varios", "Defensa"]   # i18n-no
	return ["varios", "Varios"]   # i18n-no

func marca_de(it: Dictionary) -> String:
	return String(D.CATALOGO.marcas.get(cat_de(it)[1], ""))

func cat_n(c: String) -> String:
	for x in D.CATALOGO.cats:
		if String(x[0]) == c:
			return String(x[1])
	return c

# las filas de filtro de la tienda (encima de los artículos; los artículos no cambian de nombre): F = {c, s, m}
func filtra_tienda(list: Array, F: Dictionary) -> Dictionary:
	if not Datos.CAL or not D.has("CATALOGO") or list.size() <= 8:
		return {"filas": [], "list": list}
	var filas := []
	var l := list.filter(func(it): return (F.c == "" or cat_de(it)[0] == F.c) and (F.s == "" or cat_de(it)[1] == F.s) and (F.m == "" or marca_de(it) == F.m))
	if F.c == "":
		for x in D.CATALOGO.cats:
			var nn := list.filter(func(it): return cat_de(it)[0] == x[0]).size()
			if nn:
				filas.append({"label": "▸ " + I18n.v(String(x[1])), "right": str(nn), "desc": K("Ver solo esta sección."), "f": {"c": String(x[0]), "s": "", "m": ""}})
	elif F.s == "":
		var subs := []
		for it in l:
			if not subs.has(cat_de(it)[1]):
				subs.append(cat_de(it)[1])
		if subs.size() > 1:
			for s in subs:
				filas.append({"label": "▸ " + I18n.v(String(s)), "right": str(l.filter(func(it): return cat_de(it)[1] == s).size()), "desc": K("Ver solo este tipo."), "f": {"c": F.c, "s": String(s), "m": ""}})
	elif F.m == "":
		var ms := []
		for it in l:
			var m := marca_de(it)
			if m != "" and not ms.has(m):
				ms.append(m)
		if ms.size() > 1:
			for m in ms:
				filas.append({"label": "▸ " + m, "right": "", "desc": K("Ver solo esta marca."), "f": {"c": F.c, "s": F.s, "m": m}})
	if F.c != "":
		filas.push_front({"label": "◂ " + (K("Todas las secciones") if F.s == "" else I18n.v(cat_n(F.c))), "right": "", "desc": K("Volver atrás."), "f": ({"c": "", "s": "", "m": ""} if F.s == "" else {"c": F.c, "s": "", "m": ""})})
	return {"filas": filas, "list": l}

# la carta del bar, el club o la discoteca: lo de siempre y lo de CARTA
func carta(bb: String) -> Array:
	var L: Array = BEBIDAS[bb].duplicate()
	if vida_ok() and D.has("CARTA"):
		for x in D.CARTA.get(bb, []):
			L.append([I18n.v(String(x[0])), float(x[1]), int(x[2]), float(x[3])])
	return L
