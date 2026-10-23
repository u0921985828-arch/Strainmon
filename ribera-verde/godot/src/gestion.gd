# MAESTRO [6] (con Datos.CAL): la plantilla por local (lealtad de 1 a 10 con su riesgo de chivato, el capataz, el sueldo, la eficiencia y
# el contable que blanquea), el olor de la nave (carbón activo que se gasta con el uso y la humedad, y el ozonizador en el conducto),
# la seguridad de la nave y los locales (puerta blindada, alarma, perro y cámaras, que se ven en los monitores del despacho) y el
# club KAIA con el mismo panel que el dispensario de la asociación. Todo por Datos.hash_str, sin tirar del azar.
# Cadena: … → campo → gestion → retencion → juego.
extends "res://src/campo.gd"

func staff_ok() -> bool:
	return Datos.CAL and D.has("STAFF") and S != null

# ---------- la lealtad (w.lt, de 1 a 10; w.lea, de 1 a 5, la sigue para las cuentas de antes) ----------
func lealtad(w: Dictionary) -> int:
	if w.get("lt") == null:
		w.lt = clampi(int(w.lea) * 2, 1, 10)
	return int(w.lt)

# 0: de 1 a 3 · 1: de 4 a 7 · 2: de 8 a 9 · 3: 10
func banda(lt: int) -> int:
	var B: Array = D.STAFF.topo
	for i in B.size():
		if lt <= int(B[i][0]):
			return i
	return B.size() - 1

func prob_topo(w: Dictionary) -> float:
	return float(D.STAFF.topo[banda(lealtad(w))][1])

func pon_lealtad(w: Dictionary, v: int) -> void:
	var b0 := banda(lealtad(w))
	w.lt = clampi(v, 1, 10)
	w.lea = clampi(ceili(int(w.lt) / 2.0), 1, 5)
	if int(w.lt) >= 10:   # lealtad absoluta: ni un chivato aguanta ahí
		w.erase("topo")
		w.erase("visto")
	elif banda(int(w.lt)) < b0:   # baja de banda: el riesgo de la nueva
		tira_topo(w, "baja")

# ¿le ha comprado la policía? Al entrar y cada vez que baja de banda
func tira_topo(w: Dictionary, tag: String) -> void:
	if w.get("topo"):
		return
	if Datos.hash_str("topo|%s|%s|%d" % [w.id, tag, int(S.day)]) % 1000 < int(prob_topo(w) * 1000):
		w.topo = 1

func eficiencia(w: Dictionary) -> int:
	var E: Array = D.STAFF.ef
	var hab: int = int(w.lab) if w.get("rol") == "calle" or w.get("rol") == "contable" else int(w.cui)
	return int(E[0]) + int(E[1]) * hab

# el local de cada uno: el piso (gerente), la calle, la nave (naveros y madres) o el local del contable
func local_staff(w: Dictionary) -> String:
	if w.get("rol") == "contable":
		return String(w.get("loc", ""))
	if w.get("rol") == "lugar":   # MAESTRO [9]: los lugartenientes de los pisos de venta
		return "pisos"
	return String(D.STAFF.roles.get(w.get("rol"), ""))

func nombre_local(k: String) -> String:
	match k:
		"piso":
			return K("El piso")
		"calle":
			return K("La calle")
		"nave":
			return K("La nave")
		"pisos":
			return K("Los pisos")
		"":
			return K("Sin trabajo")
	return String(D.LOCALES[k].n) if D.LOCALES.has(k) else k

# al amanecer, después de los sueldos: la lealtad sube o baja, los chivatos dan calor y el capataz los ve
func staff_dia() -> void:
	if not staff_ok():
		return
	var ST: Dictionary = D.STAFF
	for w in S.plantilla:
		lealtad(w)
		if not w.get("t0"):   # los de antes de MAESTRO [6], una vez
			w.t0 = 1
			tira_topo(w, "t0")
		if not w.get("rol"):
			continue
		var lt := lealtad(w)
		var sm := int(w.get("sm", 1))
		if banda(lt) == 1 and (sm == 0 or int(S.heat) >= int(ST.baja.calor)) and Datos.hash_str("baja|%s|%d" % [w.id, int(S.day)]) % 1000 < int(float(ST.baja.p) * 1000):
			pon_lealtad(w, lt - 1)
		elif sm == 2 and lt < int(ST.sube.tope) and Datos.hash_str("sube|%s|%d" % [w.id, int(S.day)]) % 1000 < int(float(ST.sube.p) * 1000):
			pon_lealtad(w, lt + 1)
		if w.get("topo"):
			S.heat = mini(100, int(S.heat) + int(ST.chivato.calor))
	# el capataz (lealtad 10): vigila a los de su local
	for c in S.plantilla:
		if not c.get("rol") or lealtad(c) < 10:
			continue
		var L := local_staff(c)
		for w in S.plantilla:
			if w == c or not w.get("topo") or w.get("visto") or local_staff(w) != L:
				continue
			if Datos.hash_str("capataz|%s|%s|%d" % [c.id, w.id, int(S.day)]) % 1000 < int(float(ST.capataz.p) * 1000):
				w.visto = 1
				var N: String = K("SMS · ") + String(c.n).to_upper()
				var tx: String = T("Jefe, ojo con {n}: ayer le vi hablando con uno de paisano detrás de {l}. Yo no le contaría nada.", {"n": w.n, "l": nombre_local(L).to_lower()})
				queue("capataz" + String(w.id), func(): await talk(N, [tx]), [[N, [tx]]])

# los chivatos de la nave: la redada, ×STAFF.chivato.redada
func chivato_nave() -> float:
	if not staff_ok():
		return 1.0
	for w in de_la_nave():
		if w.get("topo"):
			return float(D.STAFF.chivato.redada)
	return 1.0

# ---------- el contable (rol «contable», w.loc): cada mañana, el efectivo a la caja de su local, menos su comisión ----------
func contable_dia() -> void:
	if not staff_ok():
		return
	var C: Dictionary = D.STAFF.contable
	for w in S.plantilla:
		if w.get("rol") != "contable":
			continue
		var k := String(w.get("loc", ""))
		if not S.loc.has(k):
			libre(w)
			continue
		var o := neg_o(k)
		if int(o.get("cd", -1)) == int(S.day):   # una vez al día
			continue
		o.cd = int(S.day)
		var hoy: float = metido(o)
		var x: int = int(floorf(minf(float(S.money), (neg_tope(k) - hoy) * eficiencia(w) / 100.0)))
		if x < 1:
			continue
		var com: int = roundi(x * float(C.com))
		S.money -= x
		o.caja = hoy + x - com
		o.dia = S.day
		w.lv = int(w.get("lv", 0)) + x - com

# ---------- el olor de la nave: el carbón activo (S.nave.cb, de 100 a 0) y el ozonizador (S.nave.oz: "", "tubo" o "sala") ----------
func carbon(N: Dictionary) -> float:
	if N.get("cb") == null:
		N.cb = 100.0
	return float(N.cb)

# con extracción, el carbón se gasta cada día, más con lluvia (la humedad lo satura antes)
func carbon_dia() -> void:
	if not staff_ok() or S.get("nave") == null or int(S.nave.ex) == 0:
		return
	var O: Dictionary = D.OLOR_NAVE
	var f: float = float(O.humedad) if Datos.tiempo(S.day, 720).k in ["lluvia", "tormenta", "niebla"] else 1.0
	S.nave.cb = maxf(0.0, carbon(S.nave) - float(O.uso) * f)

# el factor de olor de la redada: sin carbón, como sin filtro; con el ozonizador y carbón, nada
func olor_nave() -> float:
	var N: Dictionary = S.nave
	var o: float = float(D.EXTR_NAVE[int(N.ex)].olor)
	if not staff_ok() or int(N.ex) == 0:
		return o
	if carbon(N) <= 0:
		return 1.0
	if String(N.get("oz", "")) != "":
		return 0.0
	return o

func olor_txt() -> String:
	var N: Dictionary = S.nave
	if int(N.ex) == 0:
		return K("Sin extracción no hay filtro: el olor sale a la calle.")
	var oz := String(N.get("oz", ""))
	var t: String = T("Carbón activo al {p} %.", {"p": int(carbon(N))}) + " "
	if carbon(N) <= 0:
		t += K("Saturado: huele como sin filtro. Cámbialo.")
	elif oz == "tubo":
		t += K("Con el ozonizador en el conducto, en la calle no huele nada.")
	elif oz == "sala":
		t += K("El ozonizador está en la sala: no huele nada, pero quema los terpenos de las flores.")
	else:
		t += T("En la calle se nota un {p} % del olor.", {"p": roundi(olor_nave() * 100)})
	return t

func olor_menu() -> void:
	var N: Dictionary = S.nave
	var O: Dictionary = D.OLOR_NAVE
	while true:
		var ops := []
		var lc := ""
		if int(N.ex) > 0:
			lc = T("Cambiar el carbón · {e}", {"e": Datos.eur(O.carbon.p)})
			ops.append(lc)
		var oz := String(N.get("oz", ""))
		var lo := ""
		if int(N.ex) > 0 and oz == "":
			lo = T("Ozonizador · {e}", {"e": Datos.eur(O.ozono.p)})
			ops.append(lo)
		elif oz != "":
			lo = K("Mover el ozonizador")
			ops.append(lo)
		ops.append(K("Nada"))
		var c: int = await ask(K("EL OLOR") + " · " + olor_txt(), ops)
		var op: String = ops[c] if c >= 0 and c < ops.size() else ""
		if op == "" or op == "Nada":
			return
		if op == lc:
			if not await tarjeta(float(O.carbon.p), I18n.v(O.carbon.n)):
				continue
			N.cb = 100.0
			sfx("get")
			await say(K("Arrieta cambia el carbón de los filtros. Huele a nuevo."))
		elif op == lo:
			if oz == "":
				if await ask(String(I18n.v(O.ozono.d)) + " " + Datos.eur(O.ozono.p), [K("Comprar"), K("No")]) != 0:
					continue
				if not await tarjeta(float(O.ozono.p), I18n.v(O.ozono.n)):
					continue
			var w: int = await ask(K("¿Dónde va el ozonizador?"), [K("En el conducto, después del filtro"), K("En la sala, con las plantas")])
			N.oz = "sala" if w == 1 else "tubo"
			sfx("sel")
			await say(K("En el conducto: el ozono no toca las flores.") if N.oz == "tubo" else K("En la sala: el ozono quema los terpenos y lo que se cuelgue se venderá peor."))

# ---------- la seguridad (S.seg[local] = {pb, al, pe, ca}) ----------
func seg_tiene(k: String, it: String) -> bool:
	return staff_ok() and S.get("seg") is Dictionary and S.seg.has(k) and S.seg[k].get(it)

func locales_seg() -> Array:
	var L := []
	if S.get("nave") != null:
		L.append("nave")
	for k in S.loc:
		L.append(k)
	return L

func prob_robo(k: String) -> float:
	var p: float = float(D.SEGURIDAD.robo)
	for it in D.SEGURIDAD.items:
		if seg_tiene(k, it.k):
			p *= float(it.robo)
	return p

# por la noche, en cada local tuyo: lo del secadero de la nave o la caja del local; con cámaras, se recupera una parte
func robos_dia() -> void:
	if not staff_ok() or not D.has("SEGURIDAD"):
		return
	for k in locales_seg():
		if Datos.hash_str("robo|%s|%d" % [k, int(S.day)]) % 1000 >= int(prob_robo(k) * 1000):
			continue
		var rec: float = float(D.SEGURIDAD.recupera) if seg_tiene(k, "ca") else 0.0
		var tx := ""
		if k == "nave":
			var g := 0.0
			for Me in S.nave.m:
				if Me and float(Me.g) >= 1:
					var q: float = Datos.jsround(float(Me.g) * (1 - rec) * 10) / 10.0
					Me.g = Datos.jsround((float(Me.g) - q) * 10) / 10.0
					g += q
			if g < 1:
				continue
			tx = T("Han entrado de noche en la nave y se han llevado {g} del secadero.", {"g": g_txt(g)})
		else:
			var o := neg_o(k)
			var e: int = roundi(metido(o) * (1 - rec))
			if e < 1:
				continue
			o.caja = float(o.caja) - e
			tx = T("Han entrado de noche en {n} y se han llevado {e} de la caja.", {"n": D.LOCALES[k].n, "e": Datos.eur(e)})
		if rec > 0:
			tx += " " + K("Las cámaras lo grabaron todo: la policía ha recuperado la mitad.")
		var N: String = K("SMS · ALARMA") if seg_tiene(k, "al") else K("SMS · VECINO")
		var t2 := tx
		queue("robo" + k, func(): await talk(N, [t2]), [[N, [t2]]])

func seguridad_menu() -> void:
	var j := 0
	while true:
		var L := locales_seg()
		if L.is_empty():
			await say(K("No tienes ningún local que proteger."))
			return
		var rows := []
		for k in L:
			var n_ := 0
			for it in D.SEGURIDAD.items:
				if seg_tiene(k, it.k):
					n_ += 1
			rows.append({"label": nombre_local(k), "right": T("{n} de {t}", {"n": n_, "t": D.SEGURIDAD.items.size()}), "desc": T("Riesgo de robo: {p} % al día.", {"p": _dos(prob_robo(k) * 100)})})
		rows.append({"label": K("Volver"), "desc": ""})
		j = await menu(rows, {"cls": "full", "title": K("SEGURIDAD"), "desc": true, "initial": mini(j, rows.size() - 1)})
		if j < 0 or j >= L.size():
			return
		await seguridad_local(L[j])

func seguridad_local(k: String) -> void:
	if not (S.get("seg") is Dictionary):
		S.seg = {}
	if not S.seg.has(k):
		S.seg[k] = {}
	while true:
		var its: Array = D.SEGURIDAD.items
		var rows := []
		for it in its:
			rows.append({"label": it.n, "right": K("puesta") if seg_tiene(k, it.k) else Datos.eur(it.p), "desc": it.d})
		rows.append({"label": K("Volver"), "desc": ""})
		var i: int = await menu(rows, {"cls": "full", "title": nombre_local(k).to_upper(), "title2": T("robo {p} %", {"p": _dos(prob_robo(k) * 100)}), "desc": true})
		if i < 0 or i >= its.size():
			return
		var it: Dictionary = its[i]
		if seg_tiene(k, it.k):
			await say(T("{n}: ya está puesta.", {"n": it.n}))
			continue
		if await ask(T("{n} para {l}: {e}, con tarjeta. {d}", {"n": it.n, "l": nombre_local(k).to_lower(), "e": Datos.eur(it.p), "d": it.d}), [K("Comprar"), K("No")]) != 0:
			continue
		if not await tarjeta(float(it.p), I18n.v(it.n) + " · " + nombre_local(k)):
			continue
		S.seg[k][it.k] = int(S.day)
		sfx("get")
		toast(T("{n}: puesta", {"n": it.n}), 1400)

# los monitores del despacho: lo que ven las cámaras de cada local
func monitores() -> void:
	var rows := []
	for k in locales_seg():
		if not seg_tiene(k, "ca"):
			rows.append({"label": nombre_local(k), "right": K("sin cámaras"), "desc": K("Ponle cámaras desde SEGURIDAD.")})
			continue
		var t := ""
		if k == "nave":
			var gente := de_la_nave().size()
			t = T("{n} trabajando · {g} en el secadero · {o}", {"n": gente, "g": g_txt(nave_stock()), "o": olor_txt()})
		else:
			var o := neg_o(k)
			t = T("Ayer vendió {a}. En la caja, {c}. El local {l}.", {"a": Datos.eur(int(o.ay)), "c": Datos.eur(metido(o)), "l": neg_cuidado(k)})
		var sos := ""
		for w in S.plantilla:
			if w.get("visto") and local_staff(w) == k:
				sos = " " + T("{n} sale a hablar por teléfono cada poco.", {"n": w.n})
		rows.append({"label": nombre_local(k), "right": K("en directo"), "desc": t + sos})
	if rows.is_empty():
		await say(K("Los monitores están apagados: no tienes locales con cámaras."))
		return
	rows.append({"label": K("Volver"), "desc": ""})
	await menu(rows, {"cls": "full", "title": K("MONITORES"), "desc": true})

# ---------- la plantilla por local (StaffManagerUI): la cuadrícula de cada local con rol, sueldo, lealtad y eficiencia ----------
func plantilla_locales() -> void:
	var P: Dictionary = D.PLANTILLA
	var j := 0
	while true:
		var ks := ["piso", "calle"]
		if S.get("nave") != null:
			ks.append("nave")
		if S.plantilla.any(func(w): return w.get("rol") == "lugar"):
			ks.append("pisos")
		for k in S.loc:
			ks.append(k)
		ks.append("")
		var rows := []
		for k in ks:
			var W: Array = S.plantilla.filter(func(w): return local_staff(w) == k)
			rows.append({"label": nombre_local(k), "right": T("{n} personas", {"n": W.size()}) if W.size() != 1 else K("1 persona"), "desc": ", ".join(PackedStringArray(W.map(func(w): return w.n))) if W.size() else K("Nadie.")})
		if S.plantilla.size() < int(P.max):
			rows.append({"label": K("Pedir gente a Patxi"), "right": Datos.eur(P.sobre), "desc": K("Patxi te manda a alguien del barrio que quiere currar. No sabes a quién hasta que llega.")})
		rows.append({"label": K("Volver"), "desc": ""})
		j = await menu(rows, {"cls": "full", "title": K("PLANTILLA POR LOCAL"), "title2": T("{a} de {b}", {"a": S.plantilla.size(), "b": int(P.max)}), "desc": true, "initial": mini(j, rows.size() - 1)})
		if j < 0 or j == rows.size() - 1:
			return
		if j >= ks.size():
			await pedir_gente()
		else:
			await cuadricula(ks[j])

func fila_staff(w: Dictionary) -> Dictionary:
	var sm := int(w.get("sm", 1))
	var su: String = T("{p} %", {"p": roundi(float(D.STAFF.contable.com) * 100)}) if w.get("rol") == "contable" else (Datos.eur(sueldo_w(w)) if sueldo_w(w) else "—")
	var t := "%s · %s · L%d · %d %%" % [rol_txt(w), su, lealtad(w), eficiencia(w)]
	var d: String = ficha_gente(w) + ". " + rol_desc(w) + " " + T("Sueldo {s}.", {"s": I18n.v(D.STAFF.sueldo[sm][0]).to_lower()})
	if w.get("visto"):
		d += " " + K("El capataz dice que habla con la policía.")
	return {"label": ("(!) " if w.get("visto") else "") + String(w.n), "right": t, "desc": d}

func cuadricula(k: String) -> void:
	var i := 0
	while true:
		var W: Array = S.plantilla.filter(func(w): return local_staff(w) == k)
		if W.is_empty():
			await say(T("En {l} no trabaja nadie.", {"l": nombre_local(k).to_lower()}))
			return
		var rows: Array = W.map(fila_staff)
		rows.append({"label": K("Volver"), "desc": ""})
		i = await menu(rows, {"cls": "full", "title": nombre_local(k).to_upper(), "title2": K("rol · sueldo · lealtad · eficiencia"), "desc": true, "initial": mini(i, rows.size() - 1)})
		if i < 0 or i >= W.size():
			return
		await trabajo(W[i])

# lo que añade MAESTRO [6] al menú de cada uno: de contable y el sueldo
func ops_staff(w: Dictionary) -> Array:
	if not staff_ok():
		return []
	var o := []
	if w.get("rol") != "contable" and S.loc.size():
		o.append(K("De contable"))
	if w.get("rol") and not w.get("rol") in ["calle", "contable", "lugar"]:   # el lugarteniente va a comisión
		o.append(T("Sueldo: {s}", {"s": I18n.v(D.STAFF.sueldo[int(w.get("sm", 1))][0]).to_lower()}))
	return o

func staff_op(w: Dictionary, op: String) -> bool:
	if not staff_ok() or op == "":
		return false
	if op == "De contable":
		var ks: Array = S.loc.keys()
		var lb: Array = ks.map(func(k): return String(D.LOCALES[k].n))
		lb.append(K("Nada"))
		var c: int = await ask(T("{d} ¿De qué local?", {"d": I18n.v(D.STAFF.contable.txt)}), lb)
		if c < 0 or c >= ks.size():
			return true
		for x in S.plantilla:
			if x != w and x.get("rol") == "contable" and x.get("loc") == ks[c]:
				libre(x)
		libre(w)
		w.rol = "contable"
		w.loc = ks[c]
		sfx("sel")
		await say(T("{n}: «Desde mañana llevo la caja de {l}. Lo que entre, limpio a la cuenta, menos lo mío».", {"n": w.n, "l": D.LOCALES[ks[c]].n}))
		return true
	if op == T("Sueldo: {s}", {"s": I18n.v(D.STAFF.sueldo[int(w.get("sm", 1))][0]).to_lower()}):
		var SL: Array = D.STAFF.sueldo
		var lb := []
		for s in SL:
			lb.append(T("{s} · {e} al día", {"s": s[0], "e": Datos.eur(roundi(int(D.PLANTILLA.sueldo.get(w.rol, 0)) * float(s[1])))}))
		var c: int = await ask(T("El sueldo de {n}. Con el bajo, su lealtad se resiente; con el alto, sube poco a poco.", {"n": w.n}), lb)
		if c >= 0 and c < SL.size():
			w.sm = c
			sfx("sel")
		return true
	return false

# ---------- el panel del club (MAESTRO [6]): KAIA, el Club del Puerto, como el dispensario de la asociación ----------
func panel_club(id: String, N: String) -> void:
	while true:
		var ops := [K("El dispensario"), K("El almacén"), K("Nada")]
		if id == "muelle":   # KAIA, el tuyo: también el diseño y el orden del local
			ops = [K("El dispensario"), K("El almacén"), K("El diseño"), K("Ordenar el local"), K("Nada")]
		if puertas_int("club-" + id).size():   # (lo pidió el usuario): el almacén, por su puerta
			ops.erase(K("El almacén"))
		var c: int = await ask(K("¿Qué miramos, presidente?") if id == "rv" else K("¿Qué miramos, jefe?"), ops, N)
		var op: String = ops[c] if c >= 0 and c < ops.size() else ""
		if op == K("El dispensario"):
			if id == "rv":
				await dispensario_aso()
			else:
				await dispensario_kaia(N)
		elif op == K("El almacén"):
			await almacen_club(id)
		elif op == K("El diseño"):
			await diseno_kaia(N)
		elif op == K("Ordenar el local"):
			await ordenar("club-muelle")
			return
		else:
			return
