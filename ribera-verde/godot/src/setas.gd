# F8 (de trama.gd): el bajo de las setas, la caja y la nevera por dentro, ordenar y el carro de esquejes.
extends "res://src/nave.gd"

func sot_ya() -> bool:
	return Datos.CAL and S.get("sot") is Dictionary and float(S.sot.get("d", 1e9)) <= S.day

func SL():
	if es_sot():
		return S.sot if sot_ya() else null
	return S.get("setas")

# las estanterías del sitio (cada una, dos bandejas) en el orden del mapa, de arriba abajo y de izquierda a derecha
func _baldas() -> Array:
	var m = MAPS.get("sotano" if es_sot() else "setas")
	var r := []
	if m == null:
		return r
	for y in int(m.h):
		for x in int(m.w):
			if m.o[y][x] == "baldaS":
				r.append(x + 1000 * y)
	return r

func n_baldas() -> int:
	return maxi(1, _baldas().size())

func balda_i(x: int) -> int:
	for i in _baldas().size():
		if _baldas()[i] % 1000 == x:
			return i
	return 0

func max_bandejas() -> int:
	if es_sot():
		return int(D.SOTANO.max)
	return 2 * n_baldas() if Datos.CAL else int(D.SETAS.max)

func fase_seta(b: Dictionary) -> String:
	if b.get("mala"):
		return b.mala
	var d: int = int(S.day - b.d)
	return "colonizando" if d < D.SETAS.colon else ("fructificando" if d < D.SETAS.colon + D.SETAS.fruto else "lista")

# las cepas (1.46, lo pidió el usuario: «diferentes panes… juntar esos micelios y crear nuevas variedades… en un libro de recetas…
# que no se permita hacer ciertos cruces»; con Datos.CAL): cepas inventadas (CEPAS.v, cada una con su forma: cúpula, campana, plato o
# racimo), los panes de micelio (S.setas.panes {k: n}), lo descubierto (S.setas.cd) y lo seco por cepa (S.setas.gv {k: g}, que suma
# S.setas.g; lo que no tiene cepa es Txuria). Juntar dos panes solo prende si la pareja está en el cuaderno (CEPAS.r); unas formas
# se repelen (CEPAS.veta). Nada de método ni de dosis.
func cepa_de(b) -> String:
	var v = b.get("v") if b is Dictionary else null
	return str(v) if v != null and D.CEPAS.v.has(str(v)) else "txuria"

func receta_cepa(a: String, b: String) -> String:
	for r in D.CEPAS.r:
		if (r[0] == a and r[1] == b) or (r[0] == b and r[1] == a):
			return r[2]
	return ""

func veta_cepa(a: String, b: String) -> bool:
	var fa: String = D.CEPAS.v[a].f
	var fb: String = D.CEPAS.v[b].f
	for v in D.CEPAS.veta:
		if (v[0] == fa and v[1] == fb) or (v[0] == fb and v[1] == fa):
			return true
	return false

func gv_setas(L: Dictionary) -> Dictionary:
	var gv: Dictionary = L.get("gv", {}).duplicate() if L.get("gv") is Dictionary else {}
	var s := 0.0
	for k in gv:
		s += float(gv[k])
	if float(L.g) - s > 0.001:
		gv["txuria"] = float(gv.get("txuria", 0)) + float(L.g) - s
	return gv

func suma_gv(L: Dictionary, k: String, g: float) -> void:   # antes de sumarlo a L.g
	var gv := gv_setas(L)
	gv[k] = float(gv.get(k, 0)) + g
	L.gv = gv

func quita_gv(L: Dictionary, g: float) -> void:   # después de restarlo de L.g: de la cepa que más hay
	var gv := gv_setas(L)
	var t := 0.0
	for k in gv:
		t += float(gv[k])
	g = t - float(L.g)
	var ks: Array = gv.keys()
	ks.sort_custom(func(a, b): return gv[a] > gv[b] or (gv[a] == gv[b] and a < b))
	for k in ks:
		var q: float = minf(g, float(gv[k]))
		gv[k] = float(gv[k]) - q
		g -= q
		if gv[k] <= 0.001:
			gv.erase(k)
	L.gv = gv

func cepa_ya(L: Dictionary, k: String) -> bool:
	return k == "txuria" or k in L.get("cd", [])

func descubre_cepa(L: Dictionary, k: String) -> void:
	if not L.get("cd") is Array:
		L.cd = []
	if not k in L.cd:
		L.cd.append(k)

# los panes de micelio que vende Txomin (CEPAS.v[k].pan)
func panes_txomin(T: String) -> void:
	var L: Dictionary = SL()
	while true:
		var ks := []
		var ops := []
		for k in D.CEPAS.v:
			var c: Dictionary = D.CEPAS.v[k]
			if c.has("pan"):
				ks.append(k)
				ops.append("%s · %s (%s)" % [c.n, D.CEPAS.fam[c.f], Datos.eur(c.pan)])
		ops.append("Nada")
		var oi: int = await ask("Panes de micelio, cada uno de su cepa. Con uno, te preparo una bandeja de esa cepa; juntando dos en la mesa, sale otra si está en el cuaderno.", ops, T)
		if oi < 0 or oi >= ks.size():
			return
		var k: String = ks[oi]
		var pz: int = int(D.CEPAS.v[k].pan)
		if S.money < pz:
			sfx("bad")
			await say("Sin %s no hay pan." % Datos.eur(pz), T)
			continue
		S.money -= pz
		if not L.get("panes") is Dictionary:
			L.panes = {}
		L.panes[k] = int(L.panes.get(k, 0)) + 1
		descubre_cepa(L, k)
		sfx("coin")
		await say("Un pan de %s: %s" % [nom_cepa(k), D.CEPAS.v[k].d], T)

# los panes que tienes, para elegir uno (sin el excluido): [[k, "Nombre (n)"]]
func mis_panes(L: Dictionary, sin := "") -> Array:
	var o := []
	var P: Dictionary = L.get("panes", {}) if L.get("panes") is Dictionary else {}
	for k in D.CEPAS.v:
		if int(P.get(k, 0)) > 0 and k != sin:
			o.append([k, "%s (%d)" % [nom_cepa(k), int(P[k])]])
	return o

# juntar dos micelios en la mesa de trabajo: solo si la pareja está en el cuaderno; sin gastar nada si no prende
func juntar_micelios() -> void:
	var L: Dictionary = S.setas
	var A := mis_panes(L)
	if A.is_empty():
		await say("No tienes panes de micelio. Txomin los vende en la puerta.")
		return
	var oa: int = await ask("Juntar micelios: el primer pan.", A.map(func(x): return x[1]) + ["Nada"])
	if oa < 0 or oa >= A.size():
		return
	var a: String = A[oa][0]
	var B := mis_panes(L, a)
	if B.is_empty():
		await say("Hace falta un pan de otra cepa para juntarlo con el de %s." % nom_cepa(a))
		return
	var ob: int = await ask("Juntar %s con…" % nom_cepa(a), B.map(func(x): return x[1]) + ["Nada"])
	if ob < 0 or ob >= B.size():
		return
	var b: String = B[ob][0]
	if veta_cepa(a, b):
		sfx("bad")
		await say("%s y %s no se juntan: un %s y una %s se repelen, las hifas no se tocan. No gastas nada." % [nom_cepa(a), nom_cepa(b), D.CEPAS.fam[D.CEPAS.v[a].f], D.CEPAS.fam[D.CEPAS.v[b].f]])
		return
	var r: String = receta_cepa(a, b)
	if r == "":
		sfx("bad")
		await say("No prende: %s con %s no está en el cuaderno. No gastas nada." % [nom_cepa(a), nom_cepa(b)])
		return
	L.panes[a] = int(L.panes[a]) - 1
	L.panes[b] = int(L.panes[b]) - 1
	L.panes[r] = int(L.panes.get(r, 0)) + int(D.CEPAS.sale)
	var nueva: bool = not cepa_ya(L, r)
	descubre_cepa(L, r)
	advance_time(int(D.CEPAS.min))
	update_hud()
	sfx("get")
	await say("Juntas los dos micelios en un pan nuevo y, al rato, prende: %d panes de %s.%s" % [int(D.CEPAS.sale), nom_cepa(r), (" ¡Nueva en tu cuaderno! " + D.CEPAS.v[r].d) if nueva else ""])

# el cuaderno de las cepas: cada una con su forma, de dónde sale y si ya la tienes; y lo que no se junta
func cuaderno_setas() -> void:
	var L: Dictionary = S.setas
	var ks: Array = D.CEPAS.v.keys()
	while true:
		var ops := []
		for k in ks:
			ops.append("%s%s · %s" % ["✓ " if cepa_ya(L, k) else "", nom_cepa(k), D.CEPAS.fam[D.CEPAS.v[k].f]])
		ops.append("Lo que no se junta")
		ops.append("Nada")
		var n_ya: int = ks.filter(func(k): return cepa_ya(L, k)).size()
		var oi: int = await ask("El cuaderno de las cepas: %d de %d." % [n_ya, ks.size()], ops)
		if oi < 0 or oi >= ks.size() + 1:
			return
		if oi == ks.size():
			var t := []
			for v in D.CEPAS.veta:
				t.append("un %s con una %s" % [D.CEPAS.fam[v[0]], D.CEPAS.fam[v[1]]] if v[1] == "campana" or v[1] == "cupula" else "%s con %s" % [D.CEPAS.fam[v[0]], D.CEPAS.fam[v[1]]])
			await say("No se juntan: %s; se repelen. Y lo que no está en el cuaderno no prende." % " ni ".join(PackedStringArray(t)))
			continue
		var k: String = ks[oi]
		var c: Dictionary = D.CEPAS.v[k]
		var de := "La vende Txomin (%s el pan)." % Datos.eur(c.pan) if c.has("pan") else ""
		for r in D.CEPAS.r:
			if r[2] == k:
				de = "Sale de juntar %s con %s." % [nom_cepa(r[0]), nom_cepa(r[1])]
		await say("%s · %s · %d.ª generación. %s %s Rinde ×%s y se paga ×%s." % [c.n, D.CEPAS.fam[c.f], int(c.gen), c.d if cepa_ya(L, k) else "Aún no la has tenido.", de, str(c.g), str(c.p)])

func setas_dia() -> void:
	if Datos.CAL and sot_ya():   # 1.51: el sótano de casa, sin recibo ni redada propia (la de casa se lo lleva)
		secar_setas(S.sot)
		_setas_bandejas(S.sot, "SMS · TXOMIN")
	var L = S.get("setas")
	if L == null:
		return
	var Z: Dictionary = D.SETAS
	if not cobra(L, recibo_setas(), "TXOMIN", false, "el bajo"):   # 1.35: cada RECIBO.dias (granja.gd)
		S.setas = null
		queue("setas", func(): await talk("SMS · TXOMIN", ["No me has pagado el bajo. Cambio la cerradura; lo de dentro y la fianza, para mí."]))
		return
	if Datos.CAL:
		secar_setas(L)   # 1.44: lo seco, al armario
		if L.get("ay") and int(L.ay) < S.day:   # 1.51: el ayudante, como un navero: pulveriza y recoge lo listo
			ayudante_setas(L)
	var vivas: Array = L.bandejas.filter(func(b): return not b.get("mala"))
	if vivas.is_empty():
		return
	if Cultivo.azar() < Z.redada:
		var gg: float = L.g
		S.setas = null
		S.heat = min(100, S.heat + Z.calorRedada)
		sfx("bad")
		queue("setas", func(): await say("La policía ha entrado en el bajo de la Kale Zaharra. Se lleva las bandejas%s." % ((" y " + g_txt(gg) + " de setas") if gg >= 1 else "")))
		return
	_setas_bandejas(L, "SMS · TXOMIN")

# lo que pasa cada noche en unas bandejas (el bajo o el sótano): se secan y alguna se echa a perder
func _setas_bandejas(L: Dictionary, quien: String) -> void:
	var Z: Dictionary = D.SETAS
	var malas := []
	for b in L.bandejas.filter(func(b): return not b.get("mala")):
		b.hum = maxf(0, b.hum - Z.seca)
		if not b.hum:
			b.mala = "seca"
			malas.append("seca")
			continue
		if fase_seta(b) != "lista" and Cultivo.azar() < Z.cont + (Z.contSeca if b.hum < 50 else 0.0):
			b.mala = "contaminada"
			malas.append("contaminada")
	if malas.size():
		var t: String = ("Se te han echado a perder %d bandejas. Tíralas." % malas.size()) if malas.size() > 1 else ("Una bandeja se te ha %s. Tírala." % ("secado" if malas[0] == "seca" else "contaminado"))
		if L == S.get("sot"):
			t = t.replace("Tíralas.", "Las del sótano: tíralas.").replace("Tírala.", "La del sótano: tírala.")
		queue("setas", func(): await talk(quien, [t]))

# (lo pidió el usuario: «que se cultive como la nave»): Ekaitz, el ayudante del bajo grande, cada mañana: todo húmedo y lo listo, a secar
func ayudante_setas(L: Dictionary) -> void:
	var Z: Dictionary = D.SETAS
	var g := 0
	var quedan := []
	for b in L.bandejas:
		if b.get("mala"):
			continue   # las malas las deja: las tiras tú
		if fase_seta(b) == "lista":
			var x: int = roundi(ri(int(Z.g[0]), int(Z.g[1])) * float(D.CEPAS.v[cepa_de(b)].g))
			L.fr = L.get("fr", []) + [{"g": x, "d": S.day, "v": cepa_de(b)}]
			g += x
		else:
			b.hum = 100
			quedan.append(b)
	L.bandejas = quedan + L.bandejas.filter(func(b): return b.get("mala"))
	if g:
		queue("setas", func(): await talk("SMS · " + str(D.SETAS_AY.n).to_upper(), ["Bandejas pulverizadas. He recogido %d g y están secándose." % g]))

func talk_setero() -> void:
	var A: Dictionary = D.SETAS_AY
	var N: String = str(A.n).to_upper()
	if S.get("setas") == null:
		await say("Sin bajo no hay faena. Me vuelvo con mi tío.", N)
		return
	var L: Dictionary = S.setas
	var vivas: Array = L.bandejas.filter(func(b): return not b.get("mala"))
	var c: int = await ask("Todo en orden: %d bandejas vivas de %d. Cada mañana las pulverizo y recojo lo que esté listo." % [vivas.size(), max_bandejas()], ["Seguir así", "Despedirlo", "Nada"], N)
	if c == 1:
		if await ask("¿Seguro? Txomin no se lo va a tomar bien.", ["Despedirlo", "No"], N) == 0:
			L.erase("ay")
			build_ents()
			await say("Vale. Ahí te quedas con las bandejas.", N)
	elif c == 0:
		await say("Lo que tú digas, jefe.", N)

func talk_txomin() -> void:
	var T := "TXOMIN"
	var Z: Dictionary = D.SETAS
	if S.ch < int(Z.ch):
		await say("¿Setas? Eso era antes, chaval. Ahora solo paseo.", T)
		return
	if sot_ya():   # 1.51: las bandejas para el sótano de casa
		var cs: int = await ask("¿Para el sótano de tu casa o para mi bajo?", ["Para el sótano", "El bajo", "Nada"], T)
		if cs == 0:
			_SOT = true
			await bajo_menu(T)
			_SOT = false
			return
		if cs != 1:
			return
	if S.get("setas") == null:
		var e: float = Z.fianza + recibo_setas()
		if await ask("El bajo de mi casa: oscuro, húmedo y nadie pregunta. %s de fianza y %s cada %s días, en efectivo; el primero, ahora. Las bandejas te las preparo yo." % [Datos.eur(Z.fianza), Datos.eur(recibo_setas()), n(D.RECIBO.dias)] + (" Caben %d." % (2 * maxi(1, MAPS["setas-g"].o[2].filter(func(o): return o == "baldaS").size())) if Datos.CAL and MAPS.has("setas-g") else ""), ["Alquilarlo", "No"], T) != 0:
			return
		if S.money < e:
			sfx("bad")
			await say("Sin %s no hay llave." % Datos.eur(e), T)
			return
		S.money -= e
		S.setas = {"bandejas": [], "g": 0, "r": S.day + D.RECIBO.dias}
		sfx("coin")
		await got("la llave del bajo")
		await say("Compra las bandejas y tenlas húmedas. Lo demás lo hace el tiempo.", T)
		return
	await bajo_menu(T)

# pulverizar las bandejas vivas (SETAS.min): false si, pasada la medianoche, setas_dia ha cerrado el bajo (1.34, pulverizarBajo)
func pulverizar_bajo() -> bool:
	var L: Dictionary = SL()
	for b in L.bandejas:
		if not b.get("mala"):
			b.hum = 100
	advance_time(int(D.SETAS.min))
	update_hud()
	if SL() == null:
		return false
	sfx("sel")
	var v: Array = L.bandejas.filter(func(b): return not b.get("mala"))   # pasada la medianoche, setas_dia ya las ha secado (o echado a perder)
	var hv := 0.0
	for b in v:
		hv += b.hum
	await say(("Pulverizas las bandejas: humedad al %d %%." % Datos.jsround(hv / v.size())) if v.size() else "Pulverizas las bandejas.")
	return true

# las bandejas del bajo (1.34, bajoMenu): con Txomin, en la puerta (T), todo; dentro, en las baldas (T vacío), lo de las bandejas: ni
# comprar (las prepara él), ni venderle, ni dejar el bajo
func bajo_menu(T: String) -> void:
	var Z: Dictionary = D.SETAS
	var L: Dictionary = SL()
	while true:
		var B: Array = L.bandejas
		var cnt := {}
		for k in D.FASES_SETA:
			cnt[k] = 0
		for b in B:
			cnt[fase_seta(b)] += 1
		var hum: Array = B.filter(func(b): return not b.get("mala"))
		var partes := []
		for k in D.FASES_SETA:
			if cnt[k]:
				partes.append("%d %s" % [cnt[k], D.FASES_SETA[k][1 if cnt[k] > 1 else 0]])
		var est: String = ", ".join(PackedStringArray(partes)) if B.size() else "sin bandejas"
		var ops := []
		if T != "" and B.size() < max_bandejas():
			ops.append("Comprar bandeja (%s)" % Datos.eur(Z.bandeja))
		if T != "" and Datos.CAL:   # 1.46: los panes de micelio
			ops.append("Panes de micelio")
		if hum.size():
			ops.append("Pulverizar")
		if cnt.lista:
			ops.append("Recoger")
		if B.any(func(b): return b.get("mala")):
			ops.append("Tirar las malas")
		if T != "" and L.g >= 1:
			ops.append("Venderle " + g_txt(L.g))
		if T != "" and Datos.CAL and not es_sot():   # 1.44: el equipo del bajo y lo que haces en la mesa
			var ZP: Dictionary = D.SETAS_PRO
			if L.get("mc", 0):
				ops.append("Microdosis: %d %s" % [L.mc, "caja" if L.mc == 1 else "cajas"])
			if L.get("cc", 0):
				ops.append("Comestibles: %d %s" % [L.cc, "caja" if L.cc == 1 else "cajas"])
			if not L.get("dh"):
				ops.append("Deshidratador (%s)" % Datos.eur(ZP.deshid))
			if not L.get("enc"):
				ops.append("Encapsuladora (%s)" % Datos.eur(ZP.encap))
			if not L.get("mol"):
				ops.append("Moldes (%s)" % Datos.eur(ZP.moldes))
		if T != "" and Datos.CAL and not es_sot() and not L.get("ay"):   # 1.51: el ayudante, como los de la nave
			ops.append("Contratar a %s (%s)" % [D.SETAS_AY.n, Datos.eur(D.SETAS_AY.sueldo)])
		if T != "" and not es_sot():
			ops.append("Dejar el bajo")
		ops.append("Nada")
		var hm := 0.0
		for b in hum:
			hm += b.hum
		var oi: int = await ask(("El sótano: %s%s." if es_sot() else "El bajo: %s%s.") % [est, (" · humedad %d %%" % Datos.jsround(hm / hum.size())) if hum.size() else ""] + ("" if T != "" or B.size() else " Las bandejas las prepara Txomin, en la puerta."), ops, T)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Nada":
			return
		if op.begins_with("Comprar"):
			if S.money < Z.bandeja:
				sfx("bad")
				await say("Sin dinero no hay bandeja.", T)
				continue
			var v := "txuria"
			if Datos.CAL:   # 1.46: de qué cepa (Txuria, la de Txomin, o uno de tus panes)
				var P := mis_panes(L)
				var oc: int = 0
				if P.size():
					oc = await ask("¿De qué cepa? La Txuria la pongo yo; si no, uno de tus panes.", ["Txuria (la de Txomin)"] + P.map(func(x): return x[1]) + ["Nada"], T)
					if oc < 0 or oc > P.size():
						continue
				if oc > 0:
					v = P[oc - 1][0]
					L.panes[v] = int(L.panes[v]) - 1
			S.money -= int(Z.bandeja)
			B.append({"d": S.day, "hum": 100, "v": v} if Datos.CAL else {"d": S.day, "hum": 100})
			sfx("coin")
			await say("Lista para colonizar. En %d días la habrá cogido el micelio; %d más y a recoger." % [int(Z.colon), int(Z.fruto)], T)
		elif op.begins_with("Contratar"):
			var A: Dictionary = D.SETAS_AY
			if await ask("%s Cada %s días, %s más en el recibo del bajo." % [A.d, n(D.RECIBO.dias), Datos.eur(A.sueldo)], ["Contratarlo", "No"], T) != 0:
				continue
			L.ay = S.day
			sfx("coin")
			await say("Mañana empieza. Es de fiar: lo he criado yo.", T)
		elif op == "Panes de micelio":
			await panes_txomin(T)
		elif op == "Pulverizar":
			if not await pulverizar_bajo():   # si pasa de medianoche, setas_dia puede cerrar el bajo
				return
		elif op == "Recoger":
			var g := 0
			var quedan := []
			var pv := {}   # 1.46: lo recogido por cepa (rinde CEPAS.v[k].g)
			for b in B:
				if fase_seta(b) != "lista":
					quedan.append(b)
				else:
					var x: int = ri(int(Z.g[0]), int(Z.g[1]))
					if Datos.CAL:
						x = roundi(x * float(D.CEPAS.v[cepa_de(b)].g))
						pv[cepa_de(b)] = int(pv.get(cepa_de(b), 0)) + x
					g += x
			L.bandejas = quedan
			sfx("get")
			if Datos.CAL:   # 1.44: frescas, a secar; secas, al armario (secar_setas)
				var nf := []
				var tx := []
				for k in pv:
					nf.append({"g": pv[k], "d": S.day, "v": k})
					tx.append("%s %d g" % [nom_cepa(k), pv[k]])
				L.fr = L.get("fr", []) + nf
				await say("Recoges %d g de setas%s y las tiendes en %s: en %s, al armario." % [g, (" (" + ", ".join(PackedStringArray(tx)) + ")") if pv.size() > 1 or not pv.has("txuria") else "", "el deshidratador" if L.get("dh") else "la malla del secadero", "un día" if dias_secar(L) == 1 else "%d días" % dias_secar(L)])
			else:
				L.g += g
				await say("Recoges las setas y las dejas secando en el bajo: %d g." % g)
		elif op == "Tirar las malas":
			var k: int = B.filter(func(b): return b.get("mala")).size()
			L.bandejas = B.filter(func(b): return not b.get("mala"))
			await say(("Tiras %d bandejas." % k) if k > 1 else "Tiras la bandeja.")
		elif op.begins_with("Microdosis:") or op.begins_with("Comestibles:"):
			var kk: String = "mc" if op.begins_with("Micro") else "cc"
			var nn: int = int(L[kk])
			var e: int = nn * int(D.SETAS_PRO.p[kk])
			L[kk] = 0
			S.money += e
			S.sales += e
			S.heat = min(100, S.heat + D.SETAS_PRO.calor * nn)
			sfx("coin")
			toast("+%s · %d %s de %s" % [Datos.eur(e), nn, "caja" if nn == 1 else "cajas", "microdosis" if kk == "mc" else "comestibles"], 1600)
			await say("Esto se mueve solo. %s." % Datos.eur(e), T)
			await check_story()
		elif op.begins_with("Deshidratador") or op.begins_with("Encapsuladora") or op.begins_with("Moldes"):
			var kk: String = "dh" if op.begins_with("Desh") else ("enc" if op.begins_with("Enc") else "mol")
			var pz: int = int(D.SETAS_PRO[{"dh": "deshid", "enc": "encap", "mol": "moldes"}[kk]])
			if S.money < pz:
				sfx("bad")
				await say("Sin %s no hay trato." % Datos.eur(pz), T)
				continue
			S.money -= pz
			L[kk] = true
			sfx("coin")
			await say({"dh": "Te lo bajo yo y lo enchufo junto al secadero: lo que recojas, seco en un día.",
				"enc": "La encapsuladora, en la mesa de trabajo. Con setas secas del armario, cajas de microdosis.",
				"mol": "Los moldes y el chocolate, en la mesa de trabajo. Con setas secas del armario, cajas de comestibles."}[kk], T)
		elif op.begins_with("Venderle"):
			var g: int = int(floor(L.g))
			var e: int = g * int(Z.precio)
			if Datos.CAL:   # 1.46: cada cepa a su precio (CEPAS.v[k].p)
				var gv := gv_setas(L)
				var ev := 0.0
				for k in gv:
					ev += float(gv[k]) * float(Z.precio) * float(D.CEPAS.v[k].p if D.CEPAS.v.has(k) else 1)
				e = roundi(ev * g / maxf(float(L.g), 0.001))
			L.g -= g
			if Datos.CAL:
				quita_gv(L, g)
			S.money += e
			S.sales += e
			S.heat = min(100, S.heat + Z.calor)
			sfx("coin")
			toast("+%s · %d g de setas" % [Datos.eur(e), g], 1600)
			await say("Para mis clientes de siempre. %s." % Datos.eur(e), T)
			await check_story()
		elif op == "Dejar el bajo":
			if await ask("¿Dejas el bajo? Te devuelvo la fianza; lo que haya dentro se queda.", ["Dejarlo", "No"], T) != 0:
				continue
			S.setas = null
			S.money += int(Z.fianza)
			sfx("coin")
			await say("Como quieras. La puerta, cerrada al salir.", T)
			return

func por_thc(L: Dictionary) -> Array:
	var o := []
	for k in L:
		o.append([k, L[k]])
	o.sort_custom(func(a, b): return a[1].thc > b[1].thc or (a[1].thc == b[1].thc and a[0] < b[0]))
	return o

func items_almacen(t: String) -> Array:
	var o := []
	if t == "cam":   # 1.43.6: el camarote, GUARDAR y los tarros de 10 L (CAMAROTE.tarro g cada uno)
		o.append({"k": "+"})
		var tc := float(D.CAMAROTE.tarro)
		for l in por_thc(cam().get("buds", {})):
			var g: float = floor(l[1].g)
			var nt: int = maxi(1, ceili(g / tc - 1e-9))
			for q in nt:
				o.append({"k": l[0], "b": l[1], "r": 0, "q": q, "n": nt, "gj": g - tc * (nt - 1) if q == nt - 1 else tc})
		return o
	if t == "caja":
		o.append({"k": "$"})
		o.append({"k": "+"})   # GUARDAR, el primer tarro (vacío)
		# (lo pidió el usuario: realista): cada lote, en los tarros de ALM.tarro g que llenaría de verdad (de 4 L, sin aplastar)
		var tg := float(D.ALM.tarro)
		for l in por_thc(S.caja.buds):
			var g: float = floor(l[1].g)
			var nt: int = maxi(1, ceili(g / tg - 1e-9))
			for q in nt:
				o.append({"k": l[0], "b": l[1], "r": 0, "q": q, "n": nt, "gj": g - tg * (nt - 1) if q == nt - 1 else tg})
		return o
	o.append({"k": "+", "s": -1, "j": 0})
	var tipos: Array = D.TIPOS_EXTR
	var todo := por_thc(nevera().rosin)
	for s in tipos.size():
		var j := 0
		for l in todo:
			if tipo_extr(l[0]) == tipos[s]:
				o.append({"k": l[0], "b": l[1], "r": 1, "s": s, "j": j})
				j += 1
	return o

func mueve_almacen(A: Dictionary, b: String) -> bool:
	var it := items_almacen(A.t)
	var nn := it.size()
	var i: int = A.i
	if not nn:
		return false
	var j := i
	var F := int(D.ALM.fila)
	if A.t == "cam":   # 1.43.6: seis por balda
		var FC := int(D.CAMAROTE.est.tarros)
		j = i + {"left": -1, "right": 1, "up": -FC, "down": FC}.get(b, 0)
		j = maxi(0, mini(nn - 1, j))
	elif A.t == "caja":
		if b == "left":
			j = i - 1
		elif b == "right":
			j = i + 1
		elif b == "up":
			j = 0 if i <= F else i - F
		elif b == "down":
			j = 1 if i == 0 else i + F
		j = maxi(0, mini(nn - 1, j))
	else:
		var c: Dictionary = it[i]
		if b == "left" and c.j > 0:
			j = i - 1
		elif b == "right" and i + 1 < nn and it[i + 1].s == c.s:
			j = i + 1
		elif b == "up" or b == "down":
			var d := -1 if b == "up" else 1
			var mejor := -1
			var s: int = c.s + d
			while s >= -1 and s < D.TIPOS_EXTR.size() and mejor < 0:
				var en := []
				for q in nn:
					if it[q].s == s:
						en.append(q)
				if en.size():
					mejor = en[mini(c.j, en.size() - 1)]
				s += d
			if mejor >= 0:
				j = mejor
	if j == i:
		return false
	A.i = j
	return true

func _pct_txt(p: float) -> String:
	return "%d %%" % Datos.jsround(p * 100)

func desc_almacen(A: Dictionary) -> String:
	var its := items_almacen(A.t)
	var it = its[A.i] if A.i < its.size() else null
	if A.t == "cam":   # 1.43.6
		var CM: Dictionary = D.CAMAROTE
		var so: float = float(cam().get("sob", 0))
		var sob_t := ("Sobres de humedad: %d (uno por tarro, %d días)." % [ceili(so - 1e-9), int(CM.dura)]) if so > 0 else "Sin sobres de humedad: lo curado no se afina."
		if it == null or it.k == "+":
			return "GUARDAR: llevas %s de cogollos y en el camarote caben %s más (%d tarros de 10 L). %s\nA: guardar · B: cerrar." % [g_txt(total_buds()), g_txt(maxf(0, cam_cap() - cam_g())), cam_est() * int(CM.est.tarros), sob_t]
		var tj: String = (" en %d tarros (este, el %d.º: %d g)" % [int(it.n), int(it.q) + 1, int(it.gj)]) if int(it.n) > 1 else ""
		var af := float(it.b.get("af", 0))
		return "%s: %s%s · %s %% THC%s%s.\nA: sacarlo · B: cerrar." % [lot_nombre(it.k), g_lote(it.b.g), tj, Datos.pct(it.b.thc), cura_corto(it.b),
			(" · afinada al 62 %%" if af >= 1 else (" · afinándose (%d %%)" % Datos.jsround(af * 100))) if af else ""]
	if A.t == "caja":
		var C: Dictionary = D.CAJA[int(S.caja.nivel)]
		var g := caja_g()
		if it != null and it.k == "+":
			return "GUARDAR: llevas %s de cogollos y en la caja caben %s más.%s\nA: guardar · B: cerrar." % [g_txt(total_buds()), g_txt(maxf(0, C.g - g)), (" Con los tarros se curan en %d días." % int(D.CURADO.dias)) if S.items.get("tarros") else ""]
		if it == null or it.k == "$":
			return "Dinero: %s de %s (%s). Tarros: %s de %s (%s).\nA: guardar o sacar · B: cerrar." % [Datos.eur(S.caja.money), Datos.eur(C.money), _pct_txt(S.caja.money / C.money), g_lote(g), _kg(int(C.g)), _pct_txt(g / C.g)]
		var tj: String = (" en %d tarros (este, el %d.º: %d g)" % [int(it.n), int(it.q) + 1, int(it.gj)]) if int(it.n) > 1 else ""
		return "%s: %s%s · %s %% THC%s.\nA: sacarlo · B: cerrar." % [lot_nombre(it.k), g_lote(it.b.g), tj, Datos.pct(it.b.thc), cura_corto(it.b)]
	var r := nevera_r()
	if it == null or it.k == "+":
		return "GUARDAR: llevas %s g de extractos y en la nevera caben %s g más.%s\nA: guardar · B: cerrar." % [Datos.coma(Datos.jsround(total_rosin() * 10) / 10.0), Datos.coma(maxf(0, floor((nevera_cap() - r) * 10 + 1e-9) / 10.0)),
			(" En los tarros, en frío, se curan en %d días." % int(D.CURADO.dias)) if S.items.get("tarros") else " Con tarros, se curarían en frío."]
	var cu := float(it.b.get("cu", 0))
	return "%s: %s g · %s %% THC · %s. Nevera: %s g de %d (%s).\nA: sacarlo · B: cerrar." % [extr_nombre(it.k), Datos.coma(it.b.g), Datos.pct(it.b.thc), "curado" if cu >= 1 else ("curándose" if cu else "sin curar"),
		Datos.coma(Datos.jsround(r * 10) / 10.0), int(nevera_cap()), _pct_txt(r / nevera_cap())]

func _dlg_fijo(t: String, nombre: String) -> void:
	if oraculo:
		return
	dlg.show()
	dlg_nm.visible = nombre != ""
	dlg_nm_txt.text = nombre
	dlg_more.hide()
	dlg_txt.text = nm(t)
	_coloca.call_deferred()

# la vista: hasta que eliges (A) o cierras (B: null); i0, el que sale elegido. Las pruebas la cambian (gancho_almacen, ui.gd)
func elegir_almacen(t: String, i0 := 0):
	if gancho_almacen.is_valid():
		var q = gancho_almacen.call(t)
		if q == null:
			return null
		var its := items_almacen(t)
		if int(q) >= its.size():
			return null
		var r: Dictionary = its[int(q)].duplicate()
		r.i = int(q)
		return r
	var nn := items_almacen(t).size()
	ALMACEN = {"t": t, "i": maxi(0, mini(nn - 1, i0))}
	var N := "CAJA FUERTE" if t == "caja" else "CAMAROTE" if t == "cam" else "NEVERA"
	_dlg_fijo(desc_almacen(ALMACEN), N)
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(null)
			return
		if b == "A":
			var its := items_almacen(t)
			if ALMACEN.i < its.size():
				pop()
				var r: Dictionary = its[ALMACEN.i].duplicate()
				r.i = ALMACEN.i
				pr.res(r)
			return
		if mueve_almacen(ALMACEN, b):
			sfx("sel")
			_dlg_fijo(desc_almacen(ALMACEN), N))
	var e = await Motor.espera(pr)
	ALMACEN = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	return e

# un tarro de w × h en (x, y), a escala k: por dentro, lo que lleva (den: alm-cog-p/-s o alm-x-<tipo>, almacen.py) a su nivel,
# de 1 a 4 cuartos de f (0-1), sobre el color c (el de la variedad, que asoma por los cogollos) o, en los botes, el v de detrás
# del cristal (en la nevera, el blanco); encima, el cristal y la tapa (spr: alm-tarro, alm-tarro-s o alm-bote; -g al doble) y la
# etiqueta de papel con el sello verde del curado (1.36.1; 1.36.2: cada cosa, como es)
func _tarro(o: Array, x: int, y: int, w: int, h: int, c: String, f: float, cu: bool, spr: String, den: String, k := 1, v := "#2a343a", suf := "") -> void:
	var g := "-g" if k > 1 else ""
	var n := clampi(int(ceil(f * 4.0 - 1e-9)), 1, 4)
	o.append([x + k, y + 4 * k, (w - 2) * k, (h - 5) * k, c if w >= 14 else v])
	o.append(["@", den + "-" + str(n) + g + suf, x + k, y + 4 * k])   # suf: «-xl», lo de dentro de los tarros de 10 L (1.43.6)
	o.append(["@", spr + g, x, y])
	if w >= 14:
		var yl: int = y + Datos.jsround(h / 2.0) * k
		o.append(["@", "alm-etiqueta" + g, x + 4 * k, yl])
		if cu:
			o.append([x + 11 * k, yl + k, 2 * k, 2 * k, "#3f8a46"])
	elif cu:
		o.append([x + (w - 3) * k, y + 4 * k, 2 * k, 2 * k, "#58c070"])

# lo de dentro de un lote: los cogollos pelados (manicurados) o sin pelar; el extracto por su tipo, y el rosin curado, cremoso
func _dentro_lote(k: String, b: Dictionary, r := false) -> String:
	if not r:
		return "alm-cog-" + ("p" if float(b.get("mc", 0)) >= 1 else "s")
	var t := tipo_extr(k)
	return "alm-x-" + t + ("-cu" if t == "rosin" and float(b.get("cu", 0)) >= 1 else "")

func _marco(o: Array, x: int, y: int, w: int, h: int) -> void:
	o.append_array([[x, y, w, 1, "#f8d040"], [x, y + h - 1, w, 1, "#f8d040"], [x, y, 1, h, "#f8d040"], [x + w - 1, y, 1, h, "#f8d040"]])

func _color_lote(k: String) -> String:
	var st = strain(lot_sid(k))
	return st.c if st else "#7aa63e"

func _barra_alm(o: Array, px: int, py: int, n: int, ic: String, f: float, c: String) -> void:
	var y := py + 66 + n * 10
	o.append(["@", "alm-ic-" + ic, px + 4, y - 1])
	o.append([px + 15, y, Datos.jsround(40 * maxf(0, minf(1, f))), 5, c])

# la ventana del elegido (lo pidió el usuario), a la derecha: en grande y con sus barras (panelAlmacen en 11m-almacen)
func panel_almacen(o: Array, A: Dictionary, px: int, py: int) -> void:
	var its := items_almacen(A.t)
	var it = its[A.i] if A.i < its.size() else null
	o.append(["@", "alm-panel", px, py])
	if it == null:
		return
	if A.t == "cam":   # 1.43.6: el tarro de 10 L y sus barras (lo afinado, con la gota)
		var so: float = float(cam().get("sob", 0))
		if it.k == "+":
			o.append(["@", "alm-mas-xl", px + 19, py + 16])
			_barra_alm(o, px, py, 0, "g", peso_encima() / cap_mochila(), "#e0a040")
			_barra_alm(o, px, py, 1, "cu", cam_g() / maxf(1.0, cam_cap()), "#d8b048")
			_barra_alm(o, px, py, 2, "hr", minf(1.0, so / float(maxi(1, cam_tarros()))), "#4e9ad8")
			return
		_tarro(o, px + 19, py + 16, 22, 31, _color_lote(it.k), float(it.gj) / float(D.CAMAROTE.tarro), float(it.b.get("cu", 0)) >= 1, "alm-tarro-xl-s" if it.k.contains("*") else "alm-tarro-xl", _dentro_lote(it.k, it.b), 1, "#2a343a", "-xl")
		_barra_alm(o, px, py, 0, "thc", it.b.thc / 30.0, "#e8d070")
		_barra_alm(o, px, py, 1, "cu", float(it.b.get("cu", 0)), "#58c070")
		_barra_alm(o, px, py, 2, "hr", float(it.b.get("af", 0)), "#4e9ad8")
		return
	var caja: bool = A.t == "caja"
	var C: Dictionary = D.CAJA[int(S.caja.nivel)] if caja else {}
	if it.k == "$":
		var nn: int = maxi(1, ceili(minf(1.0, S.caja.money / C.money) * 3)) if S.caja.money > 0 else 0
		for q in nn:
			o.append(["@", "alm-fajo-g", px + 15, py + 38 - q * 12])
		_barra_alm(o, px, py, 0, "eur", S.caja.money / C.money, "#7cc07a")
		_barra_alm(o, px, py, 1, "cu", caja_g() / C.g, "#d8b048")
		return
	if it.k == "+":
		o.append(["@", "alm-mas-g", px + 12, py + 8])
		_barra_alm(o, px, py, 0, "g", peso_encima() / cap_mochila(), "#e0a040")
		_barra_alm(o, px, py, 1, "cu", caja_g() / C.g if caja else nevera_r() / nevera_cap(), "#58b0e0")
		return
	if not it.r:
		_tarro(o, px + 12, py + 8, 18, 25, _color_lote(it.k), float(it.gj) / float(D.ALM.tarro), float(it.b.get("cu", 0)) >= 1, "alm-tarro-s" if it.k.contains("*") else "alm-tarro", _dentro_lote(it.k, it.b), 2)
		_barra_alm(o, px, py, 0, "thc", it.b.thc / 30.0, "#e8d070")
		_barra_alm(o, px, py, 1, "cu", float(it.b.get("cu", 0)), "#58c070")
		_barra_alm(o, px, py, 2, "mc", float(it.b.get("mc", 0)), "#a0c8f0")
		return
	var cap: float = float(D.NEVERA.bote)
	_tarro(o, px + 18, py + 20, 12, 12, D.COLOR_EXTR[tipo_extr(it.k)], it.b.g / cap, float(it.b.get("cu", 0)) >= 1, "alm-bote", _dentro_lote(it.k, it.b, true), 2)
	_barra_alm(o, px, py, 0, "thc", it.b.thc / 90.0, "#e8d070")
	_barra_alm(o, px, py, 1, "cu", float(it.b.get("cu", 0)), "#58c070")
	_barra_alm(o, px, py, 2, "g", it.b.g / cap, "#e0a040")

# la vista: la caja (168 × 100) o la nevera (152 × 120) y, a su derecha, la ventana del elegido (60 × 100), centradas juntas.
# Rectángulos [x, y, w, h, color] y sprites ["@", nombre, x, y] (misc:alm-*, con el ancla arriba a la izquierda)
func rects_almacen(A: Dictionary) -> Array:
	var o := []
	var it := items_almacen(A.t)
	var F := int(D.ALM.fila)
	if A.t == "cam":   # 1.43.6: el camarote (168 × 100), seis tarros de 10 L por balda y dos baldas a la vista
		var FC := int(D.CAMAROTE.est.tarros)
		var x0: int = (SW - 232) >> 1
		var y0 := 4
		o.append(["@", "alm-camarote", x0, y0])
		var fila0: int = 0 if A.i < FC else int(floor(float(A.i) / FC)) - 1
		for f in 2:
			var y: int = y0 + 6 + f * 46
			for c in FC:
				var q: int = (fila0 + f) * FC + c
				if q >= it.size():
					continue
				var Jt: Dictionary = it[q]
				var x: int = x0 + 7 + c * 26
				if Jt.k == "+":
					o.append(["@", "alm-mas-xl", x, y])
				else:
					_tarro(o, x, y, 22, 31, _color_lote(Jt.k), float(Jt.gj) / float(D.CAMAROTE.tarro), float(Jt.b.get("cu", 0)) >= 1, "alm-tarro-xl-s" if Jt.k.contains("*") else "alm-tarro-xl", _dentro_lote(Jt.k, Jt.b), 1, "#2a343a", "-xl")
				if q == A.i:
					_marco(o, x - 2, y - 2, 26, 35)
		if fila0 > 0:
			o.append_array([[x0 + 160, y0 + 3, 2, 1, "#f8d040"], [x0 + 159, y0 + 4, 4, 1, "#f8d040"]])
		if it.size() > (fila0 + 2) * FC:
			o.append_array([[x0 + 159, y0 + 88, 4, 1, "#f8d040"], [x0 + 160, y0 + 89, 2, 1, "#f8d040"]])
		o.append_array([[x0 + 8, y0 + 89, 140, 5, "#2a2d34"], [x0 + 9, y0 + 90, Datos.jsround(138 * minf(1.0, cam_g() / maxf(1.0, cam_cap()))), 3, "#d8b048"]])
		panel_almacen(o, A, x0 + 172, y0)
		return o
	if A.t == "caja":
		var C: Dictionary = D.CAJA[int(S.caja.nivel)]
		var x0: int = (SW - 232) >> 1
		var y0 := 4
		var pm := minf(1.0, S.caja.money / C.money)
		var pg := minf(1.0, caja_g() / C.g)
		o.append(["@", "alm-caja", x0, y0])
		var nf: int = maxi(1, ceili(pm * D.ALM.fajos)) if S.caja.money > 0 else 0
		for q in int(D.ALM.fajos):
			var x: int = x0 + 8 + (q % 3) * 17
			var y: int = y0 + 52 - int(q / 3) * 12
			if q < nf:
				o.append(["@", "alm-fajo", x, y])
			else:
				o.append([x, y + 6, 15, 2, "#22252c"])
		o.append_array([[x0 + 8, y0 + 70, 49, 6, "#2a2d34"], [x0 + 9, y0 + 71, Datos.jsround(47 * pm), 4, "#7cc07a"]])
		if A.i == 0:
			_marco(o, x0 + 6, y0 + 8, 53, 66)
		var jar := it.slice(1)
		var sel: int = A.i - 1
		var fila0: int = 0 if sel < F else int(floor(float(sel) / F)) - 1
		for f in 2:
			var y: int = y0 + 8 + f * 34
			for c in F:
				var q: int = (fila0 + f) * F + c
				if q >= jar.size():
					continue
				var Jt: Dictionary = jar[q]
				var x: int = x0 + 69 + c * 23
				if Jt.k == "+":
					o.append(["@", "alm-mas", x, y])
				else:
					_tarro(o, x, y, 18, 25, _color_lote(Jt.k), float(Jt.gj) / float(D.ALM.tarro), float(Jt.b.get("cu", 0)) >= 1, "alm-tarro-s" if Jt.k.contains("*") else "alm-tarro", _dentro_lote(Jt.k, Jt.b))
				if q == sel:
					_marco(o, x - 2, y - 2, 22, 29)
		if fila0 > 0:
			o.append_array([[x0 + 160, y0 + 8, 2, 1, "#f8d040"], [x0 + 159, y0 + 9, 4, 1, "#f8d040"]])
		if jar.size() > (fila0 + 2) * F:
			o.append_array([[x0 + 159, y0 + 71, 4, 1, "#f8d040"], [x0 + 160, y0 + 72, 2, 1, "#f8d040"]])
		o.append_array([[x0 + 68, y0 + 82, 92, 6, "#2a2d34"], [x0 + 69, y0 + 83, Datos.jsround(90 * pg), 4, "#d8b048"]])
		panel_almacen(o, A, x0 + 172, y0)
		return o
	var x0: int = (SW - 216) >> 1
	var y0 := 4
	var p := minf(1.0, nevera_r() / nevera_cap())
	var cs = it[A.i] if A.i < it.size() else null
	var P := int(D.ALM.piso)
	o.append_array([["@", "alm-nevera", x0, y0], ["@", "alm-guardar", x0 + 6, y0 + 5]])
	if cs != null and cs.k == "+":
		_marco(o, x0 + 5, y0 + 4, 46, 13)
	for s in D.TIPOS_EXTR.size():
		var e: String = D.TIPOS_EXTR[s]
		var y: int = y0 + 19 + s * 14
		var L := it.filter(func(x): return x.s == s)
		var off: int = maxi(0, cs.j - P + 1) if cs != null and cs.s == s else 0
		o.append_array([[x0 + 6, y + 2, 5, 10, D.COLOR_EXTR[e]], [x0 + 6, y + 2, 5, 1, "#ffffff"]])
		var vis := L.slice(off, off + P)
		for q in vis.size():
			var Jt: Dictionary = vis[q]
			var x: int = x0 + 15 + q * 15
			_tarro(o, x, y + 1, 12, 12, D.COLOR_EXTR[e], Jt.b.g / float(D.NEVERA.bote), float(Jt.b.get("cu", 0)) >= 1, "alm-bote", _dentro_lote(Jt.k, Jt.b, true), 1, "#c4d6dc")
			if cs != null and cs.s == s and Jt.j == cs.j:
				_marco(o, x - 2, y - 1, 16, 16)
		if off > 0:
			o.append_array([[x0 + 12, y + 6, 1, 3, "#f8a020"], [x0 + 11, y + 7, 1, 1, "#f8a020"]])
		if L.size() > off + P:
			o.append_array([[x0 + 136, y + 6, 1, 3, "#f8a020"], [x0 + 137, y + 7, 1, 1, "#f8a020"]])
	var hb := Datos.jsround(94 * p)
	o.append([x0 + 143, y0 + 20 + 94 - hb, 3, hb, "#58b0e0"])
	panel_almacen(o, A, x0 + 156, y0)
	return o

# GUARDAR (1.36, lo pidió el usuario): el primer tarro de la caja (los cogollos que llevas) y la fila de arriba de la nevera (los
# extractos): todo lo que quepa o un lote
func _hueco_alm(caja: bool) -> float:
	return floor(D.CAJA[int(S.caja.nivel)].g - caja_g()) if caja else floor((nevera_cap() - nevera_r()) * 10 + 1e-9) / 10.0

func guardar_almacen(t: String):
	if t == "cam":   # 1.43.6: el camarote, como la caja
		await _guardar_cam()
		return
	var caja := t == "caja"
	var L := bud_lots(1) if caja else rosin_lots(.1)
	var de: Dictionary = S.buds if caja else S.rosin
	var a: Dictionary = S.caja.buds if caja else nevera().rosin
	var mn := 1.0 if caja else .1
	if L.is_empty():
		await say("No llevas cogollos encima." if caja else "No llevas extractos encima.")
		return
	if _hueco_alm(caja) < mn:
		await say("En la caja no caben más cogollos." if caja else "En la nevera ya no cabe más.")
		return
	var j: int = await ask("¿Qué guardas en la caja?" if caja else "¿Qué guardas en la nevera?", ["Todos los cogollos" if caja else "Todos los extractos", "Un lote" if caja else "Un extracto", "Nada"])
	if j == 0:
		var q := 0.0
		for l in L:
			var g: float = minf(l[1].g, _hueco_alm(caja))
			if g < mn:
				break
			q += g
			if caja:
				mover_lote(de, a, l[0], g)
			else:
				mover_rosin(de, a, l[0], g)
		sfx("sel")
		var resto: bool = total_buds() >= 1 if caja else total_rosin() >= .1
		await say("Guardas %s en %s.%s" % [g_txt(q) if caja else Datos.coma(Datos.jsround(q * 10) / 10.0) + " g", "la caja" if caja else "la nevera", " No cabe todo: el resto se queda fuera." if resto else ""])
		return
	if j != 1:
		return
	var its := L.map(lot_item) if caja else L.map(rosin_item)
	its.append({"label": "Nada"})
	var i: int = await menu(its, {"cls": "right", "title": "¿Qué guardas?"})
	if i < 0 or i >= L.size():
		return
	var k: String = L[i][0]
	var b: Dictionary = L[i][1]
	var g
	if caja:
		g = await cuanto("%s: ¿cuánto?" % lot_nombre(k), minf(floor(b.g), _hueco_alm(caja)), [10, 50, 100, 500, 1000], func(v): return g_txt(v))
	else:
		g = await cuanto("%s: ¿cuánto?" % extr_nombre(k), minf(b.g, _hueco_alm(caja)), [1, 5, 10, 50], func(v): return Datos.coma(v) + " g")
	if not g:
		return
	if caja:
		mover_lote(de, a, k, g)
	else:
		mover_rosin(de, a, k, g)
	sfx("sel")

func _guardar_cam():
	var L := bud_lots(1)
	var hueco := func() -> float: return floor(cam_cap() - cam_g())
	if L.is_empty():
		await say("No llevas cogollos encima.")
		return
	if hueco.call() < 1:
		await say("En el camarote no caben más tarros: pide otra estantería en la tienda online." if cam_est() < int(D.CAMAROTE.est.max) else "El camarote está lleno.")
		return
	var j: int = await ask("¿Qué guardas en el camarote?", ["Todos los cogollos", "Un lote", "Nada"])
	if j == 0:
		var q := 0.0
		for l in L:
			var g: float = minf(l[1].g, hueco.call())
			if g < 1:
				break
			q += g
			mover_lote(S.buds, S.cam.buds, l[0], g)
		sfx("sel")
		await say("Guardas %s en los tarros del camarote.%s" % [g_txt(q), " No cabe todo: el resto se queda fuera." if total_buds() >= 1 else ""])
		return
	if j != 1:
		return
	var its := L.map(lot_item)
	its.append({"label": "Nada"})
	var i: int = await menu(its, {"cls": "right", "title": "¿Qué guardas?"})
	if i < 0 or i >= L.size():
		return
	var k: String = L[i][0]
	var g = await cuanto("%s: ¿cuánto?" % lot_nombre(k), minf(floor(L[i][1].g), hueco.call()), [10, 50, 100, 500, 1000], func(v): return g_txt(v))
	if not g:
		return
	mover_lote(S.buds, S.cam.buds, k, g)
	sfx("sel")

# el camarote (1.43.6): las estanterías de tarros de 10 L; GUARDAR el primero y, en los demás, sacar un lote
func camarote_action():
	if cam_est() == 0:
		await say("Aquí van las estanterías de los tarros de 10 L. Se piden en la tienda online.")
		return
	if not (S.cam.get("buds") is Dictionary):
		S.cam.buds = {}
	var i := 0
	while true:
		var e = await elegir_almacen("cam", i)
		if e == null:
			return
		i = e.i
		if e.k == "+":
			await guardar_almacen("cam")
			continue
		var g: float = minf(floor(e.b.g * 10) / 10.0, floor(libre_mochila()))
		if g < 1:
			await say("No te cabe nada más encima.")
			continue
		mover_lote(S.cam.buds, S.buds, e.k, g)
		sfx("sel")
		await say("Sacas %s de %s." % [g_txt(g), lot_nombre(e.k)])

# la nevera (1.36): en la vista, GUARDAR arriba y, en los pisos, sacar un extracto
func nevera_action():
	var i := 0
	while true:
		var e = await elegir_almacen("nevera", i)
		if e == null:
			return
		i = e.i
		if e.k == "+":
			await guardar_almacen("nevera")
			continue
		var g: float = minf(e.b.g, floor(libre_mochila() * 10 + 1e-9) / 10.0)
		if g < .1:
			await say("No te cabe nada más encima.")
			continue
		mover_rosin(nevera().rosin, S.rosin, e.k, g)
		sfx("sel")
		await say("Sacas %s g de %s." % [Datos.coma(g), extr_nombre(e.k, true)])

# la mesa de manicurar (1.36, junto a la de genética): tijeras, guantes y bandeja; pela un lote de los que llevas encima
func manicura_action():
	if "charas" in extr_ya():
		var j: int = await ask("La mesa de manicurar. ¿Qué haces?", ["Manicurar un lote", D.EXTR.charas.v, "Nada"])
		if j == 1:
			await extraer("charas")
			return
		if j != 0:
			return
	var lots := bud_lots(1).filter(func(l): return float(l[1].get("mc", 0)) < 1)
	if lots.is_empty():
		await say("La mesa de manicurar: tijeras de punta fina, guantes y una bandeja con rejilla. %s" % ["Lo que llevas ya está manicurado." if total_buds() >= 1 else "Trae cogollos para pelarlos."])
		return
	var its := lots.map(lot_item)
	its.append({"label": "Nada"})
	var i: int = await menu(its, {"cls": "right", "title": "Manicurar: ¿qué lote?"})
	if i < 0 or i >= lots.size():
		return
	var k: String = lots[i][0]
	var b: Dictionary = lots[i][1]
	var m: int = mini(int(D.MANICURA.max), maxi(15, Datos.jsround(b.g * (1 - float(b.get("mc", 0))) * D.MANICURA.min)))
	await say("Con las tijeras, cogollo a cogollo: fuera las hojitas con poca resina, que quede limpio y redondo.", "MANICURA")
	await gesto("manicurar")   # 1.54
	b.mc = 1
	advance_time(m)
	sfx("get")
	var dur: String = (("%d h" % int(m / 60)) + ((" %d min" % (m % 60)) if m % 60 else "")) if m >= 60 else "%d min" % m
	await say("%s: %s manicurados en %s. Se venden un %d %% más caros." % [lot_nombre(k), g_txt(b.g), dur, Datos.jsround(D.MANICURA.precio * 100)])

# un mueble por máquina (1.36), montado en el piso cuando la tienes (montar_casa)
func mueble_extr(o: String):
	var Mu: Dictionary = D.MUEBLE_EXTR[o]
	var ya := extr_ya()
	var L: Array = Mu.t.filter(func(t): return t in ya)
	if L.is_empty():
		await say(Mu.n + ".")
		return
	if L.size() == 1:
		await extraer(L[0])
		return
	var ops := L.map(func(t): return D.EXTR[t].v)
	ops.append("Nada")
	var j: int = await ask(Mu.n + ". ¿Qué haces?", ops)
	if j >= 0 and j < L.size():
		await extraer(L[j])

# ---------- ordenar (1.37, 12d-orden): mover una pieza con las flechas; A la deja si cabe y B la devuelve ----------
# mientras mueves, la pieza se ve en el mapa en el cursor (aunque no quepa); O y G, los objetos y el suelo sin ella
func _vista_orden(m: Dictionary, P_: Dictionary, O: Array, G: Array) -> void:
	for y in int(m.h):
		m.o[y] = O[y].duplicate()
		m.g[y] = G[y].duplicate()
	if P_.get("suelo"):
		var fs := ("-" + str(deco_v("suelo"))) if deco_v("suelo") else ""
		for y in int(m.h):
			for x in int(m.w):
				if str(m.g[y][x]).begins_with("alf"):
					m.g[y][x] = "floor" + fs
		var cs := celdas_p(P_, ORDEN.x, ORDEN.y)
		for j in cs.size():
			var c: Array = cs[j]
			if c[1] >= 0 and c[1] < int(m.h) and c[0] >= 0 and c[0] < int(m.w) and m.g[c[1]][c[0]] != "mat":
				m.g[c[1]][c[0]] = "alf" + str(deco_v("alfombra")) + "abcd"[j] + fs
		return
	for c in celdas_p(P_, ORDEN.x, ORDEN.y):
		if c[2] and c[1] >= 0 and c[1] < int(m.h) and c[0] >= 0 and c[0] < int(m.w):
			m.o[c[1]][c[0]] = c[2]
	if str(P_.get("si", "")) == "carpa":   # 1.55: la carpa se pinta donde la llevas
		for t in m.get("carpas", []):
			if "carpa%d" % int(t.ci) == P_.k:
				t.x1 = int(ORDEN.x) + int(t.x1) - int(t.x0)
				t.x0 = int(ORDEN.x)
				t.y = int(ORDEN.y)

func mover_pieza(mapa: String, k: String) -> bool:
	var m: Dictionary = MAPS[mapa]
	var P_ := pieza_de(mapa, k)
	if not m.get("opos", {}).has(k):
		return false
	var x0: int = int(m.opos[k][0])
	var y0: int = int(m.opos[k][1])
	if not P_.get("suelo"):
		for c in celdas_p(P_, x0, y0):
			m.o[c[1]][c[0]] = null
	var O := copia_o(m)
	var G: Array = m.g.map(func(r): return r.duplicate())
	ORDEN = {"mapa": mapa, "k": k, "x": x0, "y": y0, "no": ""}
	var xs := []
	var ys := []
	for o in P_.o:
		xs.append(int(o[0])); ys.append(int(o[1]))
	for g in P_.get("gente", []):
		xs.append(int(g[0])); ys.append(int(g[1]))
	var mx := [-int(xs.min()), int(m.w) - 1 - int(xs.max())]
	var my := [-int(ys.min()), int(m.h) - 1 - int(ys.max())]
	var muestra := func():
		ORDEN.no = cabe_pieza(mapa, k, ORDEN.x, ORDEN.y, O)
		_vista_orden(m, P_, O, G)
		_dlg_fijo("%s · %s\nFlechas: mover · A: dejar aquí · B: como estaba" % [P_.n, D.ORDEN_MOTIVO[ORDEN.no] if ORDEN.no != "" else "Aquí cabe."], D.ORDEN_P[mapa].n)
	muestra.call()
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(false)
			return
		if b == "A":
			if ORDEN.no != "":
				sfx("no")
				return
			pop()
			pr.res(true)
			return
		var d = {"left": [-1, 0], "right": [1, 0], "up": [0, -1], "down": [0, 1]}.get(b)
		if d == null:
			return
		var nx := clampi(ORDEN.x + d[0], mx[0], mx[1])
		var ny := clampi(ORDEN.y + d[1], my[0], my[1])
		if nx == ORDEN.x and ny == ORDEN.y:
			return
		ORDEN.x = nx
		ORDEN.y = ny
		sfx("sel")
		muestra.call())
	var r: bool = await Motor.espera(pr)
	var x: int = ORDEN.x
	var y: int = ORDEN.y
	ORDEN = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	for j in int(m.h):
		m.o[j] = O[j].duplicate()
		m.g[j] = G[j].duplicate()
	if not P_.get("suelo"):
		for c in celdas_p(P_, x0, y0):
			m.o[c[1]][c[0]] = c[2]
	if r:
		if not (S.get("coloca") is Dictionary):
			S.coloca = {}
		if not S.coloca.has(mapa):
			S.coloca[mapa] = {}
		S.coloca[mapa][k] = [x, y]
	rehace_orden(mapa)
	if r:
		sfx("get")
	return r

# después de mover: el mapa con lo elegido y la gente en su sitio
func rehace_orden(mapa: String) -> void:
	if mapa == "home":
		MAPS.home.carpasK = null
		montar_casa()
	elif mapa == "nave":
		montar_nave()
	else:
		montar_club(mapa)
	if S.map == mapa:
		coloca_gente(mapa)

# ORDENAR: la lista de lo que se puede mover, hasta Terminar
func ordenar(mapa: String) -> void:
	if not D.ORDEN_P.has(mapa) or S.map != mapa:   # 1.52.1 (lo pidió el usuario): una sala solo se ordena desde dentro de ella
		return
	var i := 0
	while true:
		var L := piezas_ya(mapa)
		var items: Array = L.map(func(P_): return {"label": P_.n})
		items.append({"label": "Terminar"})
		i = await menu(items, {"title": D.ORDEN_P[mapa].n, "initial": i, "cancel": true})
		if i < 0 or i >= L.size():
			return
		await mover_pieza(mapa, L[i].k)

func mueve_carro(V: Dictionary, b: String) -> bool:
	var P := int(D.CARRO.plazas)
	var F := P >> 1
	var nt: int = D.CARRO.bandejas * 2
	var i: int = V.i
	var R: int = i / F
	var c: int = i % F
	if b == "left":
		c -= 1
	elif b == "right":
		c += 1
	elif b == "up":
		R -= 1
	elif b == "down":
		R += 1
	if c < 0 or c >= F or R < 0 or R >= nt:
		return false
	V.i = R * F + c
	return true

func desc_carro(V: Dictionary) -> String:
	var cap: int = D.CARRO.bandejas * D.CARRO.plazas
	var nb: int = S.bandejas.size()
	if V.i < nb:
		var e: Dictionary = S.bandejas[V.i]
		var s = strain(e.sid)
		var hasta: int = int(e.dia) + int(D.CARRO.dias)
		return "Esqueje de %s%s: pinchado el %s, aguanta hasta el %s%s.\nA: nombrarlo o tirarlo · B: cerrar." % [s.n, etiq(e.f), Datos.fd(e.dia, S.day), Datos.fd(hasta, S.day), " (hoy es el último)" if hasta <= S.day else ""]
	var pr: int = S.esquejes.size()
	return "Taco vacío · %d de %d ocupados. %s\n%s · B: cerrar." % [nb, cap, ("En el propagador llevas %d." % pr) if pr else "El propagador está vacío.", "A: pinchar" if pr and nb < cap else "A: ver"]

func elegir_carro(i0 := 0):
	if gancho_carro.is_valid():
		return gancho_carro.call()
	var cap: int = D.CARRO.bandejas * D.CARRO.plazas
	CARRO_V = {"i": clampi(i0, 0, cap - 1)}
	_dlg_fijo(desc_carro(CARRO_V), "CARRO DE ESQUEJES")
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(null)
			return
		if b == "A":
			pop()
			pr.res(CARRO_V.i)
			return
		if mueve_carro(CARRO_V, b):
			sfx("sel")
			_dlg_fijo(desc_carro(CARRO_V), "CARRO DE ESQUEJES"))
	var e = await Motor.espera(pr)
	CARRO_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	return e

func _esqueje(o: Array, cx: int, y: int, hj: String, k := 1, seco := false, bm: Array = CLON) -> void:
	var c := {"X": hj if not seco else "#b8a050", "D": Color(hj).darkened(.35).to_html(false) if not seco else "#8a7a38", "T": "#4f7a32" if not seco else "#9a8a48",
		"L": Color(hj).lightened(.3).to_html(false) if not seco else "#d0bc70", "K": Color(hj).darkened(.55).to_html(false) if not seco else "#6a5c2c",
		"R": "#e8e0c8"}
	var w: int = bm[0].length() >> 1
	var y0: int = y - (bm.size() - 1) * k
	for r in bm.size():
		var l: String = bm[r]
		var a := 0
		while a < l.length():
			var ch := l[a]
			if not c.has(ch):
				a += 1
				continue
			var b := a
			while b < l.length() and l[b] == ch:
				b += 1
			o.append([cx + (a - w) * k, y0 + r * k, (b - a) * k, k, ("#" + c[ch]) if not c[ch].begins_with("#") else c[ch]])
			a = b

# el taco de turba en su alvéolo de la bandeja negra (x, y: la esquina del alvéolo; k: el tamaño del píxel)
func _taco(o: Array, cx: int, y: int, k := 1) -> void:
	o.append_array([[cx - 7 * k, y, 14 * k, 7 * k, "#141418"], [cx - 7 * k, y, 14 * k, k, "#30303a"], [cx - 5 * k, y + k, 10 * k, 3 * k, "#8a5a34"],
		[cx - 4 * k, y + k, 8 * k, k, "#a8743f"], [cx - 5 * k, y + 4 * k, 10 * k, 2 * k, "#6a4026"], [cx - k, y + 2 * k, 2 * k, k, "#4a2c18"]])

# el taco de turba en grande, suelto (como sale de la bandeja): 12 × 9, con la tierra de arriba y su textura
func _taco_g(o: Array, cx: int, y: int) -> void:
	o.append_array([[cx - 6, y, 12, 9, "#3a2a1e"], [cx - 6, y, 12, 2, "#5a4030"], [cx - 5, y + 1, 10, 1, "#6a4c38"], [cx - 6, y + 8, 12, 1, "#2a1e16"],
		[cx - 4, y + 4, 1, 1, "#4e3826"], [cx + 2, y + 3, 1, 1, "#4e3826"], [cx - 1, y + 6, 1, 1, "#4e3826"], [cx + 4, y + 6, 1, 1, "#4e3826"]])

func _hoja_de(sid: String) -> String:
	var s = strain(sid)
	return String(s.get("hj", "#57a33e")) if s else "#57a33e"

func rects_carro(V: Dictionary) -> Array:
	var o := []
	var x0: int = (SW - CARRO_W - 64) >> 1
	var y0 := 4
	var F := int(D.CARRO.plazas) >> 1
	var nb: int = S.bandejas.size()
	# el carro: patas, ruedas y las dos baldas
	o.append_array([[x0, y0, CARRO_W, CARRO_H, "#1c1e24"], [x0 + 1, y0 + 1, CARRO_W - 2, CARRO_H - 2, "#2a2d34"]])
	o.append_array([[x0 + 2, y0 + 2, 3, CARRO_H - 8, "#8a92a2"], [x0 + CARRO_W - 5, y0 + 2, 3, CARRO_H - 8, "#8a92a2"],
		[x0 + 3, y0 + 2, 1, CARRO_H - 8, "#b8bec8"], [x0 + CARRO_W - 4, y0 + 2, 1, CARRO_H - 8, "#b8bec8"]])
	o.append_array([[x0 + 1, y0 + CARRO_H - 6, 6, 5, "#26262e"], [x0 + CARRO_W - 7, y0 + CARRO_H - 6, 6, 5, "#26262e"],
		[x0 + 3, y0 + CARRO_H - 4, 2, 2, "#6c7482"], [x0 + CARRO_W - 5, y0 + CARRO_H - 4, 2, 2, "#6c7482"]])
	for t in int(D.CARRO.bandejas):
		var sy: int = y0 + 3 + t * 51
		var on: bool = nb > 0
		# los tubos T5 en su pantalla y su luz
		o.append_array([[x0 + 7, sy, CARRO_W - 14, 4, "#5a606c"], [x0 + 9, sy + 3, CARRO_W - 18, 2, "#f4f8ec" if on else "#9aa0a8"]])
		if on:
			o.append_array([[x0 + 7, sy + 5, CARRO_W - 14, 4, "rgba(250,255,230,0.18)"], [x0 + 7, sy + 9, CARRO_W - 14, 6, "rgba(250,255,230,0.08)"]])
		# la bandeja negra y, encima, la tapa transparente con su reflejo
		o.append_array([[x0 + 7, sy + 8, CARRO_W - 14, 41, "#16161c"], [x0 + 8, sy + 9, CARRO_W - 16, 39, "#26262e"], [x0 + 7, sy + 47, CARRO_W - 14, 2, "#3c3e48"]])
		o.append_array([[x0 + 8, sy + 6, CARRO_W - 16, 1, "rgba(210,236,255,0.55)"], [x0 + 8, sy + 6, 1, 10, "rgba(210,236,255,0.45)"],
			[x0 + CARRO_W - 9, sy + 6, 1, 10, "rgba(210,236,255,0.45)"], [x0 + 12, sy + 7, 10, 1, "rgba(255,255,255,0.5)"], [x0 + 26, sy + 7, 3, 1, "rgba(255,255,255,0.5)"]])
		for r in 2:
			for c in F:
				var s: int = t * F * 2 + r * F + c
				var cx: int = x0 + 10 + c * 16 + 7
				var cy: int = sy + 17 + r * 22
				_taco(o, cx, cy)
				if s < nb:
					var e: Dictionary = S.bandejas[s]
					_esqueje(o, cx, cy + 2, _hoja_de(e.sid), 1, int(e.dia) + int(D.CARRO.dias) <= S.day)
				if s == V.i:
					o.append_array([[cx - 8, cy - 13, 16, 1, "#f8d040"], [cx - 8, cy + 8, 16, 1, "#f8d040"], [cx - 8, cy - 13, 1, 22, "#f8d040"], [cx + 7, cy - 13, 1, 22, "#f8d040"]])
	# a la derecha, el elegido en grande, los días que le quedan y el propagador
	var px: int = x0 + CARRO_W + 4
	o.append_array([[px, y0, 60, CARRO_H, "#1c1e24"], [px + 1, y0 + 1, 58, CARRO_H - 2, "#2a2d34"], [px + 6, y0 + 4, 48, 62, "#20222a"]])
	var cx: int = px + 30
	if V.i < nb:
		var e: Dictionary = S.bandejas[V.i]
		var hasta: int = int(e.dia) + int(D.CARRO.dias)
		var seco: bool = hasta <= S.day
		# las raíces, por los días que lleva en la bandeja
		var ra: Array = RAICES.slice(0, clampi(2 * (int(S.day) - int(e.dia)), 0, RAICES.size()))
		if ra.size():
			_esqueje(o, cx, y0 + 52 + ra.size(), "#e8e0c8", 1, false, ra)
		_taco_g(o, cx, y0 + 44)
		_esqueje(o, cx, y0 + 45, _hoja_de(e.sid), 1, seco, CLON_G)
		var f := clampf(float(hasta - S.day + 1) / float(D.CARRO.dias + 1), 0.0, 1.0)
		o.append_array([[px + 6, y0 + 68, 48, 5, "#16161c"], [px + 6, y0 + 68, Datos.jsround(48 * f), 5, "#58c070" if f > .34 else "#e0a040"]])
	else:
		_taco_g(o, cx, y0 + 44)
	# el propagador: un esqueje por cada uno que espera
	o.append_array([[px + 6, y0 + 76, 48, 26, "#16161c"], [px + 7, y0 + 77, 46, 1, "rgba(210,236,255,0.45)"]])
	var pr: int = mini(S.esquejes.size(), 12)
	for q in pr:
		var e: Dictionary = S.esquejes[q]
		var ex: int = px + 10 + (q % 6) * 7
		var ey: int = y0 + 88 + (q / 6) * 11
		o.append_array([[ex - 2, ey, 5, 3, "#6a4026"], [ex - 2, ey, 5, 1, "#8a5a34"]])
		_esqueje(o, ex, ey, _hoja_de(e.sid), 1, false, CLON_MINI)
	return o

# lo que lleva la bandeja, en días con decimales (la hora cuenta: se ve crecer)
func t_seta(b: Dictionary) -> float:
	return float(S.day - b.d) + float(S.min) / 1440.0

# un número de 0 a 1 fijo por bandeja y sitio (las manchas del micelio y dónde sale cada seta)
func _hs(a: int, b: int, c: int) -> float:
	var h: int = (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
	return float(absi(h) % 1000) / 1000.0

func mueve_bajo(V: Dictionary, b: String) -> bool:
	var r: int = V.i >> 1
	var j: int = V.i & 1
	if b == "left":
		r -= 1
	elif b == "right":
		r += 1
	elif b == "up":
		j = 1
	elif b == "down":
		j = 0
	var n2: int = 2 * r + j
	if r < 0 or r >= n_baldas() or n2 == V.i:
		return false
	V.i = n2
	return true

func desc_bajo(V: Dictionary) -> String:
	var Z: Dictionary = D.SETAS
	var B: Array = SL().bandejas
	if V.i >= B.size():
		return "Hueco libre en la balda · %d de %d bandejas. Las prepara Txomin, en la puerta.\nB: cerrar." % [B.size(), max_bandejas()]
	var b: Dictionary = B[V.i]
	var f: String = fase_seta(b)
	var t := t_seta(b)
	var tot: int = int(Z.colon) + int(Z.fruto)
	var q := ""
	match f:
		"colonizando":
			q = "el micelio cubre el %d %% del sustrato" % Datos.jsround(100 * clampf(t / Z.colon, 0, 1))
		"fructificando":
			q = "las setas crecen: %d %%" % Datos.jsround(100 * clampf((t - Z.colon) / Z.fruto, 0, 1))
		"lista":
			q = "lista para recoger"
		"contaminada":
			q = "contaminada: hay que tirarla"
		"seca":
			q = "seca: hay que tirarla"
	var dd: String = (" · día %d de %d" % [mini(int(S.day - b.d) + 1, tot), tot]) if not b.get("mala") else ""
	return "Bandeja %d%s · %s%s · humedad %d %%.\nA: pulverizar, recoger o tirar · B: cerrar." % [V.i + 1, (" · " + nom_cepa(cepa_de(b))) if Datos.CAL else "", q, dd, Datos.jsround(b.hum)]

func elegir_bajo(i0 := 0):
	if gancho_bajo.is_valid():
		return gancho_bajo.call(i0)
	SETAS_V = {"i": clampi(i0, 0, 2 * n_baldas() - 1)}
	var tit := "EL SÓTANO" if es_sot() else "EL BAJO"
	_dlg_fijo(desc_bajo(SETAS_V), tit)
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "B":
			pop()
			pr.res(null)
			return
		if b == "A":
			pop()
			pr.res(SETAS_V.i)
			return
		if mueve_bajo(SETAS_V, b):
			sfx("sel")
			_dlg_fijo(desc_bajo(SETAS_V), tit))
	var e = await Motor.espera(pr)
	SETAS_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
	return e

# la vista hasta B: con A sobre una bandeja, el menú de las bandejas (y se vuelve a las baldas); sobre un hueco, que las prepara Txomin
func vista_bajo(i0 := 0) -> void:
	var i := i0
	while SL() != null:
		var r = await elegir_bajo(i)
		if r == null:
			return
		i = int(r)
		if SL() == null:
			return
		if i < SL().bandejas.size():
			await bajo_menu("")
		else:
			await say("En ese hueco no hay bandeja. Las prepara Txomin: se las compras en la puerta.")

# una bandeja (19 × 15 unidades de u px) en x, y: la caja de plástico con la tapa, el sustrato, el micelio, las setas y las gotas
func _bandeja_seta(o: Array, b, x: int, y: int, u: int, sid: int) -> void:
	var R := func(cx: int, cy: int, w: int, h: int, c: String): o.append([x + cx * u, y + cy * u, w * u, h * u, c])
	R.call(0, 0, 19, 15, "rgba(200,222,222,0.16)")
	R.call(0, 1, 1, 14, "#8a9a9a")
	R.call(18, 1, 1, 14, "#8a9a9a")
	R.call(0, 14, 19, 1, "#6a7a7a")
	R.call(0, 0, 19, 1, "#d8e4e4")
	if b == null:
		R.call(1, 13, 17, 1, "#3a3e44")
		return
	var Z: Dictionary = D.SETAS
	var f: String = fase_seta(b)
	var t := t_seta(b)
	var mala = b.get("mala")
	# el sustrato
	R.call(1, 10, 17, 4, "#8a6a4a" if mala == "seca" else "#7a5a3a")
	R.call(1, 12, 17, 2, "#6a4a2e" if mala != "seca" else "#7a5a3c")
	# el micelio: celdas blancas por lo que lleva colonizado (entera desde que fructifica)
	var cov: float = 1.0 if f in ["fructificando", "lista"] else (clampf(t / Z.colon, 0, 1) if mala == null else 0.5)
	for cy in [10, 11, 12, 13]:
		for cx in range(1, 18):
			var h := _hs(sid, cx, cy)
			if h * (1.0 + (cy - 10) * 0.6) < cov:
				R.call(cx, cy, 1, 1, ("#f0eee6" if cy == 10 else "#e0dcd0") if mala != "seca" else "#b8a888")
	if mala == "contaminada":
		for k in 6:
			var cx: int = 2 + int(_hs(sid, k, 7) * 15)
			var cy: int = 10 + int(_hs(sid, k, 8) * 3)
			R.call(cx, cy, 2, 1, "#4a8a3a" if k % 2 else "#3a6a2a")
		R.call(2 + int(_hs(sid, 9, 9) * 14), 11, 1, 1, "#8a8a8a")
	elif mala == "seca":
		for cx in range(3, 17, 4):
			R.call(cx, 11, 1, 2, "#5a4030")
	else:
		# las setas: cinco, cada una a su ritmo; primordio (punto), tallo y sombrero que se abre
		var fr: float = 1.0 if f == "lista" else clampf((t - Z.colon) / Z.fruto, 0, 1) if f == "fructificando" else -1.0
		if fr >= 0:
			# Cada cepa con su forma y sus colores (CEPAS.v): cúpula (la de siempre), campana, plato o racimo
			var cp: Dictionary = D.CEPAS.v[cepa_de(b)] if Datos.CAL else D.CEPAS.v.txuria
			var C0: String = cp.c[0]
			var C1: String = cp.c[1]
			var C2: String = cp.c[2]
			var PI: String = cp.pie
			var fm: String = cp.f
			for k in 5:
				var cx: int = 2 + k * 3 + int(_hs(sid, k, 1) * 3)
				var dl: float = _hs(sid, k, 2) * 0.3
				var g: float = 1.0 if f == "lista" else clampf((fr - dl) / (1.0 - dl), 0, 1)
				var hs: int = int(round(g * (3 + int(_hs(sid, k, 3) * 4))))
				if g < 0.15:
					R.call(cx, 9, 1, 1, "#e8dcc0")
					continue
				var cw: int = 1 if g < 0.4 else (3 if g < 0.8 else 5)
				if fm == "campana":   # pie largo y fino, sombrero estrecho y alto
					hs += 2
					R.call(cx, 10 - hs, 1, hs, PI)
					var bw: int = mini(cw, 3)
					R.call(cx - (bw >> 1), 9 - hs, bw, 1, C0)
					R.call(cx - (bw >> 1), 8 - hs, bw, 1, C0)
					R.call(cx, 7 - hs, 1, 1, C1)
					if bw >= 3:
						R.call(cx - 1, 8 - hs, 1, 1, C2)
				elif fm == "plano":   # pie corto, plato ancho
					hs = maxi(1, hs - 1)
					R.call(cx, 10 - hs, 1, hs, PI)
					var pw: int = 1 if g < 0.4 else (3 if g < 0.7 else 5 if g < 0.9 else 7)
					R.call(cx - (pw >> 1), 9 - hs, pw, 1, C0)
					if pw >= 3:
						R.call(cx - (pw >> 1) + 1, 8 - hs, pw - 2, 1, C1)
						R.call(cx - (pw >> 1), 9 - hs, 1, 1, C2)
				elif fm == "racimo":   # tres sombreritos de un mismo pie, a distintas alturas
					hs = maxi(1, hs - 1)
					R.call(cx, 10 - hs, 1, hs, PI)
					R.call(cx, 9 - hs, 1, 1, C0)
					if g >= 0.4:
						R.call(cx - 1, 10 - hs, 1, 1, C2)
						R.call(cx + 1, 11 - hs, 1, 1, C0)
					if g >= 0.8:
						R.call(cx - 1, 9 - hs, 1, 1, C1)
						R.call(cx + 1, 10 - hs, 1, 1, C1)
				else:   # cúpula: la de siempre
					R.call(cx, 10 - hs, 1, hs, PI)
					R.call(cx - (cw >> 1), 9 - hs, cw, 1, C0)
					R.call(cx - maxi(0, (cw >> 1) - 1), 8 - hs, maxi(1, cw - 2), 1, C1)
					if cw >= 3:
						R.call(cx - (cw >> 1), 9 - hs, 1, 1, C2)
	# las gotas de la tapa: más cuanto más húmeda
	var nd: int = int(round(float(b.hum) / 100.0 * 9))
	for k in nd:
		R.call(1 + int(_hs(sid, k, 4) * 17), 1 + int(_hs(sid, k, 5) * 3), 1, 1, "rgba(225,242,255,0.75)")

func rects_bajo(V: Dictionary) -> Array:
	var o := []
	var x0: int = (SW - BAJO_W) >> 1
	var y0 := 4
	var B: Array = SL().bandejas if SL() != null else []
	# la pared del bajo y la bombilla
	o.append_array([[x0, y0, BAJO_W, BAJO_H, "#1a1814"], [x0 + 1, y0 + 1, BAJO_W - 2, BAJO_H - 2, "#24211c"],
		[x0 + 1, y0 + 1, 140, 30, "rgba(255,214,140,0.06)"], [x0 + 70, y0 + 1, 2, 3, "#3a3a40"], [x0 + 68, y0 + 4, 6, 4, "#ffe6a8"]])
	var nb := n_baldas()
	var pg: int = (V.i >> 1) / 3   # 1.51: de tres en tres estanterías (el bajo grande tiene nueve)
	if nb > 3:
		for q in ceili(nb / 3.0):
			o.append([x0 + 70 - 3 * ceili(nb / 3.0) + 6 * q, y0 + BAJO_H - 3, 4, 2, "#f8d040" if q == pg else "#5a5e66"])
	for r in 3:
		if 3 * pg + r >= nb:
			continue
		var rx: int = x0 + 4 + r * 46
		# la estantería: dos patas, la barra de arriba y dos baldas de rejilla
		o.append_array([[rx, y0 + 8, 2, 98, "#5a5e66"], [rx + 42, y0 + 8, 2, 98, "#5a5e66"], [rx + 1, y0 + 8, 1, 98, "#8a8e96"], [rx + 43, y0 + 8, 1, 98, "#8a8e96"],
			[rx, y0 + 8, 44, 2, "#8a8e96"]])
		for j in 2:
			var sy: int = y0 + (52 if j == 1 else 100)   # la cara de la balda: arriba (j = 1) y abajo (j = 0)
			o.append_array([[rx, sy, 44, 2, "#b8bcc4"], [rx, sy + 2, 44, 1, "#5a5e66"]])
			for gx in range(rx + 2, rx + 42, 3):
				o.append([gx, sy + 2, 1, 1, "#8a8e96"])
			var i: int = 2 * (3 * pg + r) + j
			var bx: int = rx + 3
			var by: int = sy - 31
			_bandeja_seta(o, B[i] if i < B.size() else null, bx, by, 2, i * 131 + (int(B[i].d) if i < B.size() else 0))
			if i < B.size() and not B[i].get("mala"):   # su humedad, debajo de la balda
				o.append_array([[bx, sy + 4, 38, 2, "#16161c"], [bx, sy + 4, Datos.jsround(38 * clampf(B[i].hum / 100.0, 0, 1)), 2, "#58a8e0" if B[i].hum >= 50 else "#e0a040"]])
			if i == V.i:
				o.append_array([[bx - 2, by - 2, 42, 1, "#f8d040"], [bx - 2, by + 30, 42, 1, "#f8d040"], [bx - 2, by - 2, 1, 33, "#f8d040"], [bx + 39, by - 2, 1, 33, "#f8d040"]])
	# a la derecha, la elegida en grande, su humedad y lo que lleva
	var px: int = x0 + 144
	o.append_array([[px, y0 + 4, 60, BAJO_H - 8, "#16161c"], [px + 1, y0 + 5, 58, BAJO_H - 10, "#20222a"]])
	var e = B[V.i] if V.i < B.size() else null
	_bandeja_seta(o, e, px + 1, y0 + 12, 3, V.i * 131 + (int(e.d) if e != null else 0))
	if e != null:
		var Z: Dictionary = D.SETAS
		var tot: float = Z.colon + Z.fruto
		var fp: float = 1.0 if e.get("mala") else clampf(t_seta(e) / tot, 0, 1)
		o.append_array([[px + 6, y0 + 66, 48, 4, "#0e0e12"], [px + 6, y0 + 66, Datos.jsround(48 * clampf(e.hum / 100.0, 0, 1)), 4, "#58a8e0" if e.hum >= 50 else "#e0a040"]])
		o.append_array([[px + 6, y0 + 76, 48, 4, "#0e0e12"], [px + 6, y0 + 76, Datos.jsround(48 * Z.colon / tot), 4, "#3a3830"],
			[px + 6, y0 + 76, Datos.jsround(48 * fp), 4, "#8a5a3a" if e.get("mala") else ("#e8e0d0" if fp < Z.colon / tot else "#c89060")]])
		o.append([px + 6 + Datos.jsround(48 * Z.colon / tot), y0 + 75, 1, 6, "#f0eee6"])
	return o

func dias_secar(L: Dictionary) -> int:
	return int(D.SETAS_PRO.sech if L.get("dh") else D.SETAS_PRO.seca)

func secar_setas(L = null) -> int:
	if L == null:
		L = SL()
	if L == null or not L.has("fr"):
		return 0
	var q := []
	var g := 0
	for f in L.fr:
		if int(S.day - f.d) >= dias_secar(L):
			g += int(f.g)
			if Datos.CAL:
				suma_gv(L, cepa_de(f), int(f.g))   # 1.46: lo seco, por cepa
		else:
			q.append(f)
	L.fr = q
	L.g += g
	return g

func txt_secando(o: String) -> String:
	var L: Dictionary = SL()
	var dh: bool = L.get("dh", false)
	if o == "secaS" and dh:
		return "La malla del secadero, sin usar: ahora secas en el deshidratador."
	var fr: Array = L.get("fr", [])
	var nm: String = "el deshidratador" if o == "deshidS" else "la malla del secadero"
	if fr.is_empty():
		return "%s está %s. Lo que recojas se seca aquí y pasa al armario." % [nm[0].to_upper() + nm.substr(1), "vacío" if o == "deshidS" else "vacía"]
	var g := 0
	var d: int = 1 << 30
	for f in fr:
		g += int(f.g)
		d = mini(d, int(f.d) + dias_secar(L))
	return "En %s, %s de setas secándose; las primeras pasan al armario el %s." % [nm, g_txt(g), Datos.fd(d, S.day)]

# lo lleno de cada piso del armario: 0 vacío, 1 a medias, 2 lleno (SETAS_PRO.lleno)
func lleno_arm(k: String) -> int:
	if S.get("setas") == null:
		return 0
	var v: float = float(S.setas.get(k, 0))
	var u: Array = D.SETAS_PRO.lleno[k]
	return 0 if v < float(u[0]) else (1 if v < float(u[1]) else 2)

func mesa_setas() -> void:
	var Z: Dictionary = D.SETAS_PRO
	while S.get("setas") != null:
		var L: Dictionary = S.setas
		var ops := []
		if L.get("enc"):
			ops.append("Microdosis (%d g)" % int(Z.lote))
		if L.get("mol"):
			ops.append("Comestibles (%d g + %s)" % [int(Z.lote), Datos.eur(Z.choco)])
		if Datos.CAL:   # 1.46: juntar micelios y el cuaderno de las cepas
			ops.append_array(["Juntar micelios", "El cuaderno"])
		if ops.is_empty():
			await say("La mesa de trabajo, con la báscula. Para las microdosis falta la encapsuladora y para los comestibles, los moldes: te los consigue Txomin, en la puerta.")
			return
		ops.append("Nada")
		var oi: int = await ask("La mesa de trabajo. En el armario, %s de setas secas." % g_txt(L.g), ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Nada":
			return
		if op == "Juntar micelios":
			await juntar_micelios()
			continue
		if op == "El cuaderno":
			await cuaderno_setas()
			continue
		var mc: bool = op.begins_with("Micro")
		if L.g < Z.lote:
			sfx("bad")
			await say("Hacen falta %d g de setas secas del armario." % int(Z.lote))
			continue
		if not mc and S.money < Z.choco:
			sfx("bad")
			await say("Sin %s no hay chocolate." % Datos.eur(Z.choco))
			continue
		L.g -= Z.lote
		if Datos.CAL:
			quita_gv(L, Z.lote)
		if not mc:
			S.money -= int(Z.choco)
		var kk: String = "mc" if mc else "cc"
		L[kk] = int(L.get(kk, 0)) + 1
		advance_time(int(Z.min[kk]))
		update_hud()
		sfx("get")
		await say("Llenas las cápsulas con la encapsuladora y cierras la cajita: una caja de microdosis, al armario." if mc else "Fundes el chocolate, llenas los moldes y, cuando enfría, los encajas: una caja de comestibles, al armario.")

func desc_armario() -> String:
	var L: Dictionary = S.setas
	var fr: Array = L.get("fr", [])
	var g := 0
	for f in fr:
		g += int(f.g)
	var cv := ""
	if Datos.CAL and L.g >= 1:   # 1.46: lo seco, por cepa
		var gv := gv_setas(L)
		var t := []
		for k in gv:
			if gv[k] >= 1:
				t.append("%s %s" % [nom_cepa(k), g_txt(gv[k])])
		cv = " (" + ", ".join(PackedStringArray(t)) + ")"
	return "Setas secas: %s%s · microdosis: %d · comestibles: %d.%s\nB: cerrar." % [g_txt(L.g), cv, int(L.get("mc", 0)), int(L.get("cc", 0)), (" Secándose, %s." % g_txt(g)) if g else ""]

func vista_armario() -> void:
	if gancho_bajo.is_valid():
		gancho_bajo.call(-1)
		return
	ARM_V = {}
	_dlg_fijo(desc_armario(), "EL ARMARIO")
	var pr := Motor.Prom.new()
	push(func(b: String):
		if b == "A" or b == "B":
			pop()
			pr.res(null))
	await Motor.espera(pr)
	ARM_V = null
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()

# el armario por dentro: tres baldas de acero; arriba los botes de cristal (uno por cada 50 g), en medio las cajitas de las
# microdosis y abajo las cajas de los comestibles (hasta lo que cabe a la vista)
func rects_armario() -> Array:
	var o := []
	var L: Dictionary = S.setas if S.get("setas") != null else {}
	var w := 150
	var h := 108
	var x0: int = (SW - w) >> 1
	var y0 := 4
	o.append_array([[x0, y0, w, h, "#4a4e56"], [x0 + 2, y0 + 2, w - 4, h - 4, "#2e3036"], [x0, y0, w, 2, "#ccd0d6"], [x0, y0, 2, h, "#a8acb4"]])
	for j in 3:
		var sy: int = y0 + 34 + j * 34
		o.append_array([[x0 + 2, sy - 2, w - 4, 2, "#a8acb4"], [x0 + 2, sy, w - 4, 1, "#4a4e56"]])
	# los botes: 12 × 18 con la tapa negra y lo seco dentro
	var nb: int = mini(int(ceil(float(L.get("g", 0)) / 50.0)), 10)
	for k in nb:
		var bx: int = x0 + 6 + k * 14
		var by: int = y0 + 13
		o.append_array([[bx, by + 2, 12, 17, "#cfe2e6"], [bx + 9, by + 2, 3, 17, "#a6c0c6"], [bx, by, 12, 3, "#2a2a30"],
			[bx, by + 9, 12, 10, "#8a6a4a"], [bx + 2, by + 10, 2, 2, "#a8865a"], [bx + 6, by + 13, 3, 2, "#6a4a2a"], [bx + 3, by + 16, 2, 2, "#6a4a2a"]])
	# las cajitas de las microdosis: 9 × 13, blancas con la banda azul
	for k in mini(int(L.get("mc", 0)), 13):
		var bx: int = x0 + 5 + k * 11
		var by: int = y0 + 53
		o.append_array([[bx, by, 9, 13, "#f0f0ea"], [bx + 7, by, 2, 13, "#c8c8c0"], [bx, by + 3, 9, 2, "#4a7ac0"]])
	# las cajas de los comestibles: 16 × 9, cartón crema con la tapa de chocolate, de dos en dos
	for k in mini(int(L.get("cc", 0)), 16):
		var bx: int = x0 + 6 + (k % 8) * 17
		var by: int = y0 + 93 - (k / 8) * 10
		o.append_array([[bx, by, 16, 9, "#e8d8b8"], [bx, by, 16, 2, "#6a3a20"], [bx + 6, by + 4, 4, 2, "#8a4a28"]])
	return o
