# F8 (de trama.gd): el combate, la caja fuerte, el robo de Darko y los encargos de Baltasar, la sala.
extends "res://src/menus.gd"

func bhud_datos() -> Dictionary:
	var f: float = B.hp / float(B.hpMax) if B.kind == "thief" else S.heat / 100.0
	var pf: float = S.hp / float(S.hpMax)
	return {"e": [B.name, I18n.v("VIDA") if B.kind == "thief" else I18n.v("SOSP."), maxf(0, f), hp_col(f) if B.kind == "thief" else Color("#e05050")],
		"p": [S.name, "%d g" % int(floor(total_buds())), maxf(0, pf), hp_col(pf), "%s/%s · %s" % [n(S.hp), n(S.hpMax), Datos.eur(S.money)]]}

func bhud_build() -> void:
	bhud_pon(bhud_datos())

func bhud_act() -> void:
	if B:
		bhud_pon(bhud_datos())

# el texto de la caja sin esperar a nadie (las preguntas del combate, con el menú al lado)
func prompt(t: String) -> void:
	if oraculo:
		return
	dlg.show()
	dlg_nm.hide()
	dlg_more.hide()
	dlg_txt.text = nm(t)
	_coloca.call_deferred()

func grupo_combate(who: String):
	if not Atlas.ok or B == null:
		return null
	if who == "P":
		var g = Atlas.cubre("combate:espalda:player-f") if es_chica() else null   # MAESTRO [1]: la suya, de PixelLab
		return g if g else Atlas.cubre("combate:espalda:player")
	if B.kind == "thief":
		var g = Atlas.cubre("combate:frente:darko") if B.get("jefe") else Atlas.grupo_look(B.get("look"))   # sin look (como en grupoLook), el del ladrón; Darko (1.17): su personaje es de 32 px; pelea con el suyo de combate (1.21)
		return g if g else Atlas.cubre("combate:frente:ladron")
	return Atlas.cubre("combate:frente:policia")

# lanza una animación de combate; devuelve su duración en ms
func b_anim(who: String, nn: String) -> float:
	var g = grupo_combate(who)
	if not g or Atlas.anim_de(g, nn) == null:
		return 0.0
	B["a" + who] = {"n": nn, "t0": M.reloj}
	return Atlas.duracion(g, nn)

func vfx_combate(id: String, x: float, y: float) -> void:
	if Atlas.ok:
		lanzar_vfx(id, x, y, M.reloj, "*", false)

func battle(kind):
	if gancho_combate.is_valid():
		return await gancho_combate.call(kind)
	lock += 1
	var res = null
	music(D.MUS_COMBATE.get(kind, "battle"))
	sfx("enc")
	for k in 3:
		fade_pon(.85, true, true)
		await wait(70)
		fade_pon(0, true, true)
		await wait(70)
	wipe_go()
	await wait(480)
	var ch: int = S.ch
	if kind == "thief":
		var nm_: String = pick(D.THIEVES)
		B = {"kind": kind, "name": nm_, "look": Datos.rand_look("th" + Datos.js_num(Cultivo.azar()), "thief"), "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	elif kind == "rival" or kind == "darko":
		B = rival_b(kind)
	else:
		B = {"kind": kind, "name": pick(D.COPS), "look": D.LOOKS.cop, "t": 0.0, "flashE": 0.0, "shakeP": 0.0}
	if B.kind == "thief":
		# desde el capítulo 5 (1.10), ladrones más duros: +4 de vida y +1 a cada golpe; un rival (1.16), RIVAL.vida más y +1 a cada golpe
		var dd := 1 if ch >= 5 else 0
		var rr := 1 if B.has("rival") else 0
		B.hpMax = 12 + ch * 2 + ri(0, 4) + 4 * dd + int(D.RIVAL.vida) * rr + (int(D.DARKO.vida) if B.get("jefe") else 0)
		B.hp = B.hpMax
		B.atk = [2 + (ch >> 2) + dd + rr, 4 + (ch >> 1) + dd + rr]
	mode = "battle"
	update_hud()
	wipe_fuera()
	await wait(650)
	bhud_build()
	if B.get("jefe"):
		await say(K("Darko se quita la sudadera y la tira al suelo."))
		await say(K("«Ni Iñaki ni mi tío. Tú y yo.»"), B.name)
	elif B.has("rival"):
		await say(T("{r} se te planta delante.", {"r": B.rival}))
		await say(pick([K("«Te lo he dicho por las buenas.»"), K("«Aquí se vende lo mío.»"), K("«Vamos a arreglarlo.»")]), B.name)
	elif kind == "thief":
		await say(T("Un {n} te corta el paso.", {"n": I18n.v(B.name).to_lower()}))
		await say(pick([K("«La mochila. Dámela y no pasa nada.»"), K("«Eh, tú. Sé lo que llevas encima.»"), K("«Quieto. El dinero y lo que lleves.»")]), B.name)
	else:
		b_anim("E", "alto")
		await say(T("{n} te da el alto.", {"n": B.name}))
		await say(pick([K("«Control rutinario. ¿Llevas algo encima?»"), K("«Documentación. Y vacía los bolsillos.»"), K("«Aquí huele a marihuana. ¿Es tuya?»")]), B.name)
	while not res:
		if B.kind == "thief":
			res = await thief_round()
		else:
			res = await cop_round()
	bhud_pon(null)
	if not oraculo:
		dlg.hide()
		dlg_nm.hide()
		menu_box.hide()
	await fade(1)
	mode = "world"
	B = null
	if res == "ko":
		advance_time(360)
		S.hp = S.hpMax
		enter_map("home", 2, 4, "down")
	else:
		music(map_music())
	update_hud()
	await fade(0)
	if res == "ko":
		await say(K("Te despiertas en casa con la cabeza vendada. Un vecino te encontró en el portal."))
	S.cool = 25
	heat_warn()
	lock -= 1
	return res

func el_b() -> String:
	return B.rival if B.has("rival") else T("El {n}", {"n": I18n.v(B.name).to_lower()})

func enemy_hits():
	# la carga de Darko (1.17): a veces coge la barra y el golpe siguiente vale el doble (CUBRIRSE lo deja en la mitad). La guardia o la
	# esquiva de esta ronda se gastan con ella (1.24): contra la barra hay que cubrirse o apartarse en la ronda del golpe
	if B.get("jefe") and not B.get("carga") and Cultivo.azar() < float(D.DARKO.carga):
		B.carga = 1
		B.cubre = 0
		B.esquiva = 0
		await say(T("{b} coge una barra de hierro del suelo. El próximo golpe va a doler.", {"b": el_b()}))
		return null
	# ESQUIVAR (1.18): con suerte (prob_esquiva, los reflejos) no te toca y tu golpe siguiente no falla y hace PELEA.contra más
	# (B.contra); si no, te da entero. La amenaza fallida (B.furia) suma PELEA.furia al golpe
	if B.get("esquiva"):
		B.esquiva = 0
		if Cultivo.azar() < prob_esquiva():
			b_anim("E", "ataque")
			await say(T("{b} baja la barra y te apartas a tiempo.", {"b": el_b()}) if B.get("carga") else T("{b} se lanza y te apartas a tiempo.", {"b": el_b()}))
			B.carga = 0
			B.furia = 0
			B.contra = 1
			return null
		await say(K("No te apartas a tiempo."))
	var dmg := (ri(int(B.atk[0]), int(B.atk[1])) + (int(D.PELEA.furia) if B.get("furia") else 0)) * (2 if B.get("carga") else 1)
	b_anim("E", "ataque")
	await say(T("{b} te da con la barra.", {"b": el_b()}) if B.get("carga") else T(pick([K("{b} te golpea."), K("{b} te empuja contra un portal."), K("{b} te da una patada."), K("{b} te tira al suelo.")]), {"b": el_b()}))
	B.carga = 0
	B.furia = 0
	var dd: int = int(ceil(dmg / 2.0)) if B.get("cubre") else dmg
	if B.get("cubre"):   # CUBRIRSE (1.16)
		B.cubre = 0
		await say(K("Te cubres: el golpe duele la mitad."))
	b_anim("P", "herido")
	vfx_combate("vfx-golpe", 64, 112)
	B.shakeP = 450.0
	sfx("hurt")
	S.hp = maxi(0, S.hp - dd)
	bhud_act()
	await wait(450)
	if S.hp <= 0:
		b_anim("P", "desmayo")
		await say(K("Pierdes el conocimiento."))
		var lost := 0
		for b in S.buds.values():
			var l := int(floor(b.g / 2))
			lost += l
			b.g -= l
		for k in S.buds.keys():
			if S.buds[k].g < .5:
				S.buds.erase(k)
		var lr := 0.0
		for k in S.rosin.keys():   # y la mitad del rosin (1.10)
			var qr: float = Datos.jsround(S.rosin[k].g * 5) / 10.0
			lr += qr
			use_rosin(k, qr)
		var lm := Datos.jsround(S.money * .3)
		S.money -= lm
		await say(T("Te roba {g} g, {r} y {e}.", {"g": lost, "r": rosin_txt(lr), "e": Datos.eur(lm)}) if lr > 0 else T("Te roba {g} g y {e}.", {"g": lost, "e": Datos.eur(lm)}))
		return "ko"
	return null

func thief_round():
	prompt(K("¿Qué haces?"))
	var c: int = await menu([K("LUCHAR"), K("MOCHILA"), K("HABLAR"), K("HUIR")], {"cls": "battle", "cancel": false})
	if c == 0:
		prompt(K("Elige un golpe."))
		var m: int = await menu([K("PUÑETAZO"), K("PATADA"), K("CUBRIRSE"), K("ESQUIVAR")], {"cls": "battle"})
		if m < 0:
			return null
		if m == 2:
			B.cubre = 1
			B.guardia = 1
			B.esquiva = 0
			await say(K("Te pones en guardia: el próximo golpe no fallará."))
			return await enemy_hits()
		if m == 3:   # ESQUIVAR (1.18)
			B.esquiva = 1
			B.cubre = 0
			await say(K("Te quedas atento para apartarte."))
			return await enemy_hits()
		var mv := {"n": "PATADA", "acc": .65, "d": [8, 12]} if m else {"n": "PUÑETAZO", "acc": .92, "d": [4, 7]}   # i18n-no
		await wait(b_anim("P", "patada" if m else "golpe") * .6)
		await say(K("Le das una patada.") if mv.n == "PATADA" else K("Le das un puñetazo."))
		var g = B.get("guardia")
		var k = B.get("contra")
		B.guardia = 0
		B.contra = 0
		if g or k or Cultivo.azar() < minf(float(D.PELEA.accMax), mv.acc + int(S.pelea.ref) * float(D.PELEA.acc)):   # la fuerza suma al golpe y los reflejos, a la puntería (1.18)
			var d: int = ri(mv.d[0], mv.d[1]) + int(S.pelea.fue) + (int(D.PELEA.contra) if k else 0)
			if k:
				await say(K("Le pillas abierto."))
			b_anim("E", "herido")
			vfx_combate("vfx-golpe", 178, 40)
			B.flashE = 500.0
			sfx("hit")
			B.hp -= d
			bhud_act()
			await wait(500)
			if m and d >= 11:
				await say(K("Le has hecho daño de verdad."))
		else:
			await say(K("Fallas."))
	elif c == 1:
		prompt(K("¿Qué usas?"))
		var it: int = await menu([{"label": T("SPRAY ×{n}", {"n": n(S.items.spray)}), "ic": icono("spray")}, {"label": T("BOCATA ×{n}", {"n": n(S.items.bocata)}), "ic": icono("bocadillo")}], {"cls": "battle"})
		if it < 0:
			return null
		if it == 0:
			if not S.items.spray:
				await say(K("No te queda SPRAY."))
				return null
			S.items.spray -= 1
			b_anim("P", "spray")
			vfx_combate("vfx-spray", 178, 48)
			await say(K("Le echas SPRAY DE PIMIENTA a la cara."))
			b_anim("E", "herido")
			B.flashE = 700.0
			sfx("hit")
			B.hp -= ri(12, 16)
			bhud_act()
			await wait(500)
			await say(K("No puede abrir los ojos."))
		else:
			if not S.items.bocata:
				await say(K("No te quedan BOCATAS."))
				return null
			S.items.bocata -= 1
			b_anim("P", "comer")
			S.hp = mini(S.hpMax, S.hp + 15)
			sfx("get")
			bhud_act()
			await say(K("Te comes un BOCATA. Recuperas vida."))
	elif c == 2:
		prompt(K("¿Qué le dices?"))
		var h: int = await menu([K("CALMAR"), K("AMENAZAR")], {"cls": "battle"})
		if h < 0:
			return null
		if h == 0:
			await say(T("{n}: «Tranquilo. Somos del mismo barrio.»", {"n": S.name}))
			if not B.get("jefe") and Cultivo.azar() < clampf(.25 + S.rep / 300.0, .25, .7):
				await say(K("«Vale... Tú eres el de Maite. Olvídalo.»"))
				return "talk"
			await say(K("«Aquí ya no hay nada que hablar.»") if B.get("jefe") else K("«No me cuentes historias.»"))
		else:   # AMENAZAR (1.18): funciona mejor cuanto más tocado está y cuanta más fuerza tienes; si falla, te pega con rabia
			await say(T("{n}: «Lárgate ahora que puedes.»", {"n": S.name}))
			if not B.get("jefe") and Cultivo.azar() < prob_amenaza():
				await say(T("{b} se lo piensa mejor.", {"b": el_b()}) if B.has("rival") else T("{b} se lo piensa mejor y se va.", {"b": el_b()}))
				return "talk"
			B.furia = 1
			await say(K("«A mí no me amenaza nadie.»") if B.get("jefe") else K("«¿A mí? Ahora vas a ver.»"))
	elif c == 3:
		if Cultivo.azar() < minf(float(D.PELEA.huirMax), .5 + int(S.pelea.ref) * float(D.PELEA.huir)):
			sfx("door")
			await say(K("Consigues escapar."))
			return "flee"
		await say(K("Te corta el paso. No puedes escapar."))
	if B.hp <= 0:
		if B.get("jefe"):   # Darko (1.17) no huye: se queda en el suelo, y la reputación la da ajuste_darko
			b_anim("E", "herido")
			await say(T("{b} cae al suelo, sin aire.", {"b": el_b()}))
		else:
			B.gone = true
			b_anim("E", "huir")
			await say(T("{b} sale corriendo.", {"b": el_b()}))
		if B.has("rival"):
			if not B.get("jefe"):
				S.rep += int(D.RIVAL.rep)
			if S.hpMax < 60:
				S.hpMax += 2
				S.hp += 2
				bhud_act()
				await say(T("Aguantas más. VIDA máxima: {n}.", {"n": int(S.hpMax)}))
			await experiencia()
			return "win"
		var loot: int = ri(20, 40) + S.ch * 10
		S.money += loot
		S.rep += 2
		sfx("coin")
		bhud_act()
		await say(T("Al huir se le cae la cartera: +{e}.", {"e": Datos.eur(loot)}))
		if S.hpMax < 60:
			S.hpMax += 2
			S.hp += 2
			bhud_act()
			await say(T("Aguantas más. VIDA máxima: {n}.", {"n": int(S.hpMax)}))
		await experiencia()
		return "win"
	return await enemy_hits()

# la experiencia (1.18): cada pelea ganada da PELEA.xp y con cada PELEA.nv subes un nivel y eliges FUERZA o REFLEJOS (13-combate.js)
func nivel_pelea() -> int:
	var x := int(S.pelea.xp)
	return D.PELEA.nv.filter(func(v): return x >= int(v)).size()

func prob_esquiva() -> float:
	return float(D.PELEA.esq0) + int(S.pelea.ref) * float(D.PELEA.esq)

func prob_amenaza() -> float:
	return clampf(float(D.PELEA.amen0) + (1 - float(B.hp) / float(B.hpMax)) * float(D.PELEA.amen) + int(S.pelea.fue) * float(D.PELEA.amenF), float(D.PELEA.amen0), float(D.PELEA.amenMax))

func experiencia() -> void:
	var P: Dictionary = S.pelea
	P.xp = int(P.xp) + int(D.PELEA.xp["darko" if B.get("jefe") else ("rival" if B.has("rival") else "thief")])
	var mx := int(D.PELEA.max)
	while nivel_pelea() > int(P.fue) + int(P.ref) and (int(P.fue) < mx or int(P.ref) < mx):
		sfx("get")
		await say(T("Subes a nivel {n} de pelea.", {"n": int(P.fue) + int(P.ref) + 1}))
		var f := int(P.fue) < mx
		var r := int(P.ref) < mx
		var o := 0 if f else 1
		if f and r:   # sin cancelar: las dos son una elección
			await type_text(K("¿Qué entrenas?"), "")
			o = await menu([K("Fuerza"), K("Reflejos")], {"cls": "right", "cancel": false})
			if not oraculo:
				dlg.hide()
				dlg_nm.hide()
		if o == 0:
			P.fue = int(P.fue) + 1
			await say(T("FUERZA {f}: cada golpe hace {f} más.", {"f": int(P.fue)}))
		else:
			P.ref = int(P.ref) + 1
			await say(T("REFLEJOS {r}: aciertas, esquivas y escapas mejor.", {"r": int(P.ref)}))

func ficha_pelea() -> String:   # la fila Pelea de la MOCHILA
	var P: Dictionary = S.pelea
	var nv := nivel_pelea()
	var a := {"f": int(P.fue), "r": int(P.ref), "x": int(P.xp), "t": int(D.PELEA.xp.thief), "v": int(D.PELEA.xp.rival)}
	if nv >= D.PELEA.nv.size():
		return T("Fuerza {f} · reflejos {r} · {x} de experiencia.\nSube ganando peleas: un ladrón da {t}, un rival {v}.", a)
	a.nv = nv + 1
	a.c = int(D.PELEA.nv[nv])
	return T("Fuerza {f} · reflejos {r} · {x} de experiencia (nivel {nv} con {c}).\nSube ganando peleas: un ladrón da {t}, un rival {v}.", a)

# devuelve lo requisado en texto (cogollos y, si hay, rosin) y la multa
func confiscate(extra_fine := true) -> Array:
	var g := int(floor(total_buds()))
	var ro := total_rosin()
	var fine = min(S.money, int(D.MULTA_CALLE)) if extra_fine else 0
	if B:
		b_anim("E", "multa")
	S.buds = {}
	S.rosin = {}
	S.money -= fine
	S.heat = max(0, S.heat - 15)
	return [T("{g} g y {r}", {"g": g, "r": rosin_txt(ro)}) if ro else "%d g" % g, fine]

# el soborno (1.10) sube también con el dinero que llevas encima: un 5 %
func precio_soborno() -> int:
	return Datos.jsround(40 + S.heat * 4 + carga_sosp() * .5 + S.money * .05)

func cop_round():
	var cost := precio_soborno()
	prompt(K("¿Qué haces?"))
	var c: int = await menu([K("SOBORNAR"), K("HABLAR"), K("HUIR"), K("ENTREGAR")], {"cls": "battle", "cancel": false})
	if c == 0:
		if await ask(T("¿Ofrecerle {e} con disimulo?", {"e": Datos.eur(cost)}), [K("Sí"), K("No")]) != 0:
			return null
		if S.money < cost:
			await say(K("No llevas tanto dinero encima."))
			return null
		if not S.protect and S.ch >= 3 and Cultivo.azar() < .15:
			await say(T("{n}: «¿Me intentas sobornar a mí? Esto me lo quedo.»", {"n": B.name}))
			var r := confiscate()
			S.heat = min(100, S.heat + 20)
			sfx("bad")
			await say(T("Te requisan {x} y te multan con {e}.", {"x": r[0], "e": Datos.eur(r[1])}))
			return "caught"
		S.money -= cost
		S.heat = max(0, S.heat - 10)
		sfx("coin")
		bhud_act()
		b_anim("E", "soborno")
		await say(T("{n} se guarda el sobre. «Aquí no ha pasado nada.»", {"n": B.name}))
		return "bribe"
	if c == 1:
		await say(T("{n}: «Solo estaba dando un paseo, agente.»", {"n": S.name}))
		if Cultivo.azar() < clampf(.3 + S.rep / 250.0 - S.heat / 300.0, .1, .85):
			await say(T("{n}: «Bien. Circula.»", {"n": B.name}))
			return "talk"
		await say(T("{n}: «No. Vacía los bolsillos.»", {"n": B.name}))
		var r := confiscate()
		sfx("bad")
		bhud_act()
		await say(T("Te requisan {x} y te multan con {e}.", {"x": r[0], "e": Datos.eur(r[1])}))
		return "caught"
	if c == 2:
		if Cultivo.azar() < .45 + (.15 if is_night() else 0.0):
			sfx("door")
			S.heat = min(100, S.heat + 8)
			await say(K("Sales corriendo entre los coches y lo pierdes."))
			return "flee"
		b_anim("E", "perseguir")
		await say(T("{n} te alcanza y te reduce en el suelo.", {"n": B.name}))
		var r := confiscate()
		S.hp = maxi(1, S.hp - 5)
		sfx("hurt")
		bhud_act()
		await say(T("Te requisan {x} y te multan con {e}.", {"x": r[0], "e": Datos.eur(r[1])}))
		return "caught"
	var r := confiscate(false)
	bhud_act()
	await say(T("Le entregas {x}. «Buena decisión. Por esta vez, sin multa.»", {"x": r[0]}))
	return "caught"

# ---------- la caja fuerte, el robo de Darko y los encargos de Baltasar (1.10, 11b-caja) ----------
# la caja: C, la de la tía Maite, detrás del diploma de la Copa de 1998 (la pista está en sus notas del ordenador): 20.000 € y
# 2 kg; B, la empotrada, por el ordenador desde el capítulo 4 (CAJA_P, la instala Kiko al día siguiente): 50.000 € y 2,5 kg.
# Lo que hay dentro no va encima: no cuenta para los encuentros ni te lo quitan un control, un ladrón o Darko. En una redada no la
# tocan (1.11: raid_event; solo pagan de ella la multa que no llegue de fuera). La luz y lo que se compra por el ordenador se pagan de fuera y, si no llega, de la caja
func diploma_action():
	if S.get("caja"):
		await caja_action()
		return
	if await ask(K("Un diploma enmarcado: «COPA DE RIBERA 1998 · 2º PREMIO: MAITE»."), [K("Mirar detrás"), K("Dejarlo")]) != 0:
		return
	await say(K("Detrás del marco hay una caja fuerte empotrada en la pared. Tiene una rueda de cuatro cifras."))
	var ops := ["1976", "1979", "1987", "1998"]
	var j: int = await ask(K("¿Qué combinación pruebas?"), ops + [K("Dejarlo")])
	if j < 0 or j >= ops.size():
		return
	await acceso("rueda", ops[j], int(ops[j]) == int(D.CAJA_ANIO))   # 1.53: las cuatro ruedas
	if int(ops[j]) != int(D.CAJA_ANIO):
		sfx("bump")
		await say(K("Clac. No se abre."))
		return
	S.caja = {"money": int(D.MAITE_CAJA), "buds": {}, "nivel": 1}
	sfx("get")
	await say(K("Clic. La caja se abre."))
	await say(T("Dentro hay {e} y una nota de la tía: «Para ti, {N}. Lo que guardes aquí no te lo quita nadie en la calle».", {"e": Datos.eur(D.MAITE_CAJA)}))
	await say(T("Caben {e} y {g}. Lo que está dentro no lo llevas encima.", {"e": Datos.eur(D.CAJA[1].money), "g": _kg(int(D.CAJA[1].g))}))
	await sobre_caja()

# al fondo de la caja (1.25), un sobre con semillas de una landrace que no está en el banco (S.flags.cajaSem; las partidas de antes,
# la próxima vez que la abres)
func sobre_caja() -> void:
	S.flags.cajaSem = S.day
	await say(K("Al fondo de la caja hay un sobre de papel de estraza: «Oaxaca, 1979»."))
	await semillas_tia("oaxaca", K("Bien secas y a oscuras: siguen buenas."), 3)

# cuánto: los pasos que caben por debajo del máximo y el máximo; 0 si no eliges nada
func cuanto(txt: String, mx: float, pasos: Array, fmt: Callable):
	var ops := []
	for v in pasos:
		if v < mx:
			ops.append(v)
	ops.append(mx)
	var o := ops.map(fmt)
	o.append(K("Nada"))
	var j: int = await ask(txt, o)
	return ops[j] if j >= 0 and j < ops.size() else 0

# Un lote de menos de 10 g, con su décima (0,4 g no es «0 g»); sin CAL, como g_txt
func g_lote(g: float) -> String:
	if Datos.CAL and g > 0 and g < 10 and absf(g - floor(g)) >= .05:
		return Datos.coma(floor(g * 10 + 1e-9) / 10.0) + " g"
	return g_txt(g)

# «300 € y 50 g», «300 €, 50 g y 2 g de rosin» o, sin cogollos, «300 € y 2 g de rosin»
func lo_que(e: float, g: float, r: float) -> String:
	var L := [Datos.eur(e)]
	if g >= 1 or r < .1:
		L.append(g_txt(g))
	if r >= .1:
		L.append(rosin_txt(r))
	return T("{a} y {b}", {"a": L[0], "b": L[1]}) if L.size() == 2 else T("{a}, {b} y {c}", {"a": L[0], "b": L[1], "c": L[2]})

# lo que cabe todavía en la caja (1.36: solo cogollos; los extractos, en la nevera)
func _hueco(C: Dictionary) -> float:
	return C.g - caja_g()

# (lo pidió el usuario): al abrirla, la caja por dentro (rects_almacen): los billetes abren el menú de siempre y un tarro, sacarlo
func caja_action():
	if int(S.caja.nivel) == 1:   # 1.53: la rueda de la tía o, la empotrada, su teclado
		await acceso("rueda", "%04d" % int(D.CAJA_ANIO))
	else:
		await acceso("clave", cifras_acceso("caja"))
	if not S.flags.get("cajaSem"):
		await sobre_caja()
	var i := 0
	while true:
		var e = await elegir_almacen("caja", i)
		if e == null:
			return
		i = e.i
		if e.k == "$":
			await caja_dinero()
			return
		if e.k == "+":   # GUARDAR (1.36)
			await guardar_almacen("caja")
			continue
		var g: float = minf(floor(e.b.g * 10) / 10.0, floor(libre_mochila()))
		if g < 1:
			await say(K("No te cabe nada más encima."))
			continue
		mover_lote(S.caja.buds, S.buds, e.k, g)
		sfx("sel")
		await say(T("Sacas {g} de {l}.", {"g": g_txt(g), "l": lot_nombre(e.k)}))

func caja_dinero():   # el menú de siempre (cajaMenu en el HTML; caja_menu es el estilo del menú en ui.gd)
	while true:
		var C: Dictionary = D.CAJA[int(S.caja.nivel)]
		var ops := [K("Guardar todo"), K("Guardar dinero"), K("Guardar cogollos"), K("Sacar dinero"), K("Sacar cogollos"), K("Sacar todo"), K("Cerrar")]   # 1.36: los extractos, en la nevera
		var oi: int = await ask(T("{c}: {d} (caben {e} y {g}).\nEncima: {m}.", {"c": C.n, "d": lo_que(S.caja.money, caja_g(), 0), "e": Datos.eur(C.money), "g": _kg(int(C.g)),
			"m": lo_que(S.money, total_buds(), 0)}), ops)
		var op: String = ops[oi] if oi >= 0 and oi < ops.size() else ""
		if op == "" or op == "Cerrar":
			return
		if op == "Guardar todo":
			var e: float = minf(S.money, C.money - S.caja.money)
			S.money -= e
			S.caja.money += e
			var g := 0.0
			var r := 0.0
			for k in S.buds.keys():
				var q: float = minf(S.buds[k].g, _hueco(C))
				if q < .5:   # menos de medio gramo no es un lote (mover_lote)
					break
				g += q
				mover_lote(S.buds, S.caja.buds, k, q)
			sfx("sel")
			await say(T("Guardas {x}. No cabe todo: el resto se queda fuera.", {"x": lo_que(e, g, r)}) if S.money >= 1 or total_buds() >= 1 else T("Guardas {x}.", {"x": lo_que(e, g, r)}))
		elif op == "Sacar todo":   # los gramos, hasta el tope de la mochila (1.10)
			var e: float = S.caja.money
			var g := 0.0
			var r := 0.0
			S.money += e
			S.caja.money = 0
			for k in S.caja.buds.keys():
				var q: float = minf(S.caja.buds[k].g, floor(libre_mochila()))
				if q < .5:
					break
				g += q
				mover_lote(S.caja.buds, S.buds, k, q)
			sfx("sel")
			await say(T("Sacas {x}. No te cabe todo encima: el resto se queda en la caja.", {"x": lo_que(e, g, r)}) if caja_g() >= .5 else T("Sacas {x}.", {"x": lo_que(e, g, r)}))
		elif op == "Guardar dinero" or op == "Sacar dinero":
			var mete := op == "Guardar dinero"
			var mx: float = minf(S.money, C.money - S.caja.money) if mete else float(S.caja.money)
			if mx < 1:
				await say((K("No llevas dinero encima.") if S.money < 1 else K("No cabe más dinero.")) if mete else K("La caja no tiene dinero."))
				continue
			var e = await cuanto(K("¿Cuánto guardas?") if mete else K("¿Cuánto sacas?"), mx, [100, 500, 1000, 5000, 10000, 20000], func(v): return Datos.eur(v))
			if not e:
				continue
			S.money += -e if mete else e
			S.caja.money += e if mete else -e
			sfx("sel")
		else:
			var mete := op == "Guardar cogollos"
			var de: Dictionary = S.buds if mete else S.caja.buds
			var a: Dictionary = S.caja.buds if mete else S.buds
			var lots := []
			for k in de:
				lots.append([k, de[k]])
			if lots.is_empty():
				await say(K("No llevas cogollos encima.") if mete else K("La caja no tiene cogollos."))
				continue
			if mete and _hueco(C) < 1:
				await say(K("No caben más cogollos."))
				continue
			if not mete and libre_mochila() < 1:
				await say(K("No te cabe nada más encima."))
				continue
			var it := lots.map(lot_item)
			it.append({"label": K("Nada")})
			var i: int = await menu(it, {"cls": "right", "title": K("¿Qué guardas?") if mete else K("¿Qué sacas?")})
			if i < 0 or i >= lots.size():
				continue
			var k: String = lots[i][0]
			var b: Dictionary = lots[i][1]
			var g = await cuanto(T("{l}: ¿cuánto?", {"l": lot_nombre(k)}), minf(b.g, _hueco(C)) if mete else minf(b.g, floor(libre_mochila())), [10, 50, 100, 500, 1000], func(v): return g_txt(v))
			if not g:
				continue
			mover_lote(de, a, k, g)
			sfx("sel")

# el ordenador: las notas de la tía (la pista de la combinación) y la caja empotrada
func notas_tia():
	await talk(K("NOTAS DE LA TÍA"), [K("«Veinte años de cultivos, apuntados día a día.»"), K("«Lo que no quiero llevar a la calle lo guardo detrás de mi premio. La combinación, el año en que lo gané.»")])

func pedir_caja():
	var C2: Dictionary = D.CAJA[2]
	if await ask(T("Caja empotrada: {e} y {g}. Kiko la instala mañana detrás del diploma, con lo que ya tengas dentro. {p}.", {"e": Datos.eur(C2.money), "g": _kg(int(C2.g)), "p": Datos.eur(D.CAJA_P)}), [K("Pedirla"), K("Nada")]) != 0:
		return
	if S.money + caja_e() < D.CAJA_P:
		sfx("bad")
		await say(K("No te llega el dinero."))
		return
	pagar_casa(D.CAJA_P)
	S.caja.mejora = 1
	sfx("coin")
	toast(K("Pedida: caja empotrada · llega mañana"), 1400)

func instalar_caja():
	if not S.get("caja") or not S.caja.get("mejora"):
		return
	S.caja.erase("mejora")
	S.caja.nivel = 2
	queue("caja", func():
		sfx("get")
		await talk(K("SMS · KIKO"), [K("Ya está: la caja empotrada, detrás del diploma. Lo de la vieja lo tienes dentro."), T("Caben {e} y {g}.", {"e": Datos.eur(D.CAJA[2].money), "g": _kg(int(D.CAJA[2].g))})]))

# el robo de Darko: la primera noche del capítulo 7 que duermes con más de 1.000 € o 100 g fuera de la caja (el rosin cuenta
# como la flor de la que sale: gramos_flor), se llevan la mitad
func robo_darko():
	S.flags.robo = true
	var e := int(floor(S.money / 2.0))
	var g := 0
	var r := 0.0
	for k in S.buds:
		var b: Dictionary = S.buds[k]
		var l := int(floor(b.g / 2.0))
		g += l
		b.g -= l
	for k in S.buds.keys():
		if S.buds[k].g < .5:
			S.buds.erase(k)
	for k in S.rosin.keys():   # y la mitad del rosin, como un ladrón
		var q: float = Datos.jsround(S.rosin[k].g * 5) / 10.0
		r += q
		use_rosin(k, q)
	var A: Dictionary = nevera()   # y la mitad de lo de la nevera (1.36; antes, del arcón)
	for k in A.rosin.keys():
		var q: float = Datos.jsround(A.rosin[k].g * 5) / 10.0
		r += q
		A.rosin[k].g = Datos.jsround((A.rosin[k].g - q) * 10) / 10.0
		if A.rosin[k].g < .1:
			A.rosin.erase(k)
	S.money -= e
	sfx("bad")
	await say(K("Te despierta un portazo. La cerradura está forzada y el piso, revuelto."))
	await say(T("Se han llevado {x}. La caja de detrás del diploma sigue cerrada.", {"x": lo_que(e, g, r)}) if S.get("caja") else T("Se han llevado {x}.", {"x": lo_que(e, g, r)}))
	await talk(K("SMS · DARKO"), [K("Te dije que esto no se acababa ahí.")])
	if not S.get("caja"):
		await say(K("Si la tía guardaba sus cosas en algún sitio, ahora te vendría bien saber dónde."))
	save()

# los encargos de Baltasar (capítulo 8): llevar ENCARGO[nivel del imperio] gramos al almacén de los astilleros, de noche, en 2 días,
# a PAGO_ENCARGO €/g. Si no llegas, reputación −10 y 5 días sin encargos
func encargo_baltasar(N: String):
	if S.get("encargo"):
		await say(T("Toño te espera en el almacén de los astilleros, de noche, con {g}. Hasta el {f}.", {"g": _kg(int(S.encargo.g)), "f": Datos.fd(S.encargo.hasta, S.day)}), N)
		return
	if S.get("encVeto", 0) > S.day:
		await say(T("Me fallaste, {N}. Vuelve el {f}.", {"f": Datos.fd(S.encVeto, S.day)}), N)
		return
	var g := int(D.ENCARGO[imperio_nivel()])
	var pe := int(D.PAGO_ENCARGO)
	await talk(N, [K("Ya no me debes nada, {N}. Pero tengo trabajo, si lo quieres."), T("{g} en el almacén de los astilleros, de noche. Toño los recoge.", {"g": _kg(g)}),
		T("Pago {p} € el gramo: {e}. Tienes {d} días.", {"p": pe, "e": Datos.eur(g * pe), "d": int(D.ENCARGO_DIAS)})])
	if cap_mochila() < g:   # 1.13
		var mi := 0
		while D.MOCHILAS[mi].g < g:
			mi += 1
		await say(T("No te caben en la {a}. Hazte con una {b} y vuelve.", {"a": I18n.v(D.MOCHILAS[int(S.items.get("bolsa", 0))].n).to_lower(), "b": I18n.v(D.MOCHILAS[mi].n).to_lower()}), N)
		return
	if await ask(K("¿Aceptas el encargo?"), [K("Aceptar"), K("No")], N) != 0:
		await say(K("Tú sabrás. La oferta sigue en pie."), N)
		return
	S.encargo = {"g": g, "hasta": S.day + int(D.ENCARGO_DIAS)}
	await say(T("Toño estará allí cada noche hasta el {f}. No le hagas esperar.", {"f": Datos.fd(S.encargo.hasta, S.day)}), N)
	show_objective()

func talk_tono_almacen():
	var N := K("TOÑO")
	if S.get("encargo") == null:   # vencido con él delante (sigue en pantalla hasta el próximo build_ents)
		await say(K("El plazo se acabó. Don Baltasar ya te escribirá."), N)
		return
	var E: Dictionary = S.encargo
	if not is_night():
		await say(K("¿De día? ¿Tú estás loco? Vuelve de noche, a partir de las nueve."), N)
		return
	if total_buds() < E.g:
		await say(T("Don Baltasar dijo {g}. Llevas {l}. Vuelve con todo.", {"g": _kg(int(E.g)), "l": g_txt(total_buds())}), N)
		return
	if await ask(T("¿Entregas {g}? Toño se lleva primero los lotes más flojos.", {"g": _kg(int(E.g))}), [K("Entregar"), K("Todavía no")], N) != 0:
		return
	var q: float = E.g
	var ls := []
	for k in S.buds:
		ls.append([k, S.buds[k].thc, ls.size()])
	ls.sort_custom(func(a, b): return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]))
	for l in ls:
		var k: String = l[0]
		var t: float = minf(q, S.buds[k].g)
		use_buds(k, t)
		q -= t
		if q <= 0:
			break
	var e: int = int(E.g) * int(D.PAGO_ENCARGO)
	S.money += e
	S.sales += e
	S.heat = min(100, S.heat + 3)
	S.rep += 2
	S.encargo = null
	sfx("coin")
	toast(T("+{e} · encargo de Don Baltasar", {"e": Datos.eur(e)}), 1600)
	await say(K("Contado. Don Baltasar estará contento."), N)
	await fade(1)
	build_ents()
	await fade(0)
	show_objective()
	await check_story()

func vencer_encargo():
	if not S.get("encargo") or S.day <= S.encargo.hasta:
		return
	S.encargo = null
	S.rep = max(0, S.rep - 10)
	S.encVeto = S.day + int(D.ENCARGO_VETO)
	var L := [K("No apareciste. Don Baltasar no se olvida."), T("Reputación −10. Nada de encargos hasta el {f}.", {"f": Datos.fd(S.encVeto, S.day)})]
	queue("encargo", func(): await talk(K("SMS · TOÑO"), L), [[K("SMS · TOÑO"), L]])

# ---------- la sala (1.10, 09c-sala): clima y arcón ----------
func t_clima(cl: Dictionary) -> String:
	return "%s °C · %s %%" % [Datos.coma(cl.t), n(cl.hr)]

func _mal(cl: Dictionary) -> String:
	var L := []
	if cl.t < D.T_OK[0]:
		L.append(I18n.v("frío"))
	if cl.t > D.T_OK[1]:
		L.append(I18n.v("calor"))
	if cl.hr < D.HR_OK[0]:
		L.append(I18n.v("seco"))
	if cl.hr > D.HR_OK[1]:
		L.append(I18n.v("húmedo"))
	return (" (" + ", ".join(L) + ")") if L.size() else ""

func sala_desc() -> String:
	var d := Cultivo.clima_sala(S, false)
	var nc := Cultivo.clima_sala(S, true)
	var ap := []
	for k in D.APARATOS:
		if k != "termo" and S.sala.get(k):
			ap.append(I18n.v(D.APARATOS[k].n))
	var mes: String = I18n.v(D.MESES[Cultivo.mes_de(int(S.day))])
	var fs := Cultivo.factura_sala(S)
	var a := {"m": mes.substr(0, 1).to_upper() + mes.substr(1), "d": t_clima(d), "dm": _mal(d), "n": t_clima(nc), "nm": _mal(nc),
		"t0": n(D.T_OK[0]), "t1": n(D.T_OK[1]), "h0": n(D.HR_OK[0]), "h1": n(D.HR_OK[1]), "ap": ", ".join(ap) if ap.size() else K("ninguno"), "f": Datos.eur(fs)}
	if fs:
		return T("{m} · de día {d}{dm} · de noche {n}{nm}\nBien: {t0}-{t1} °C y {h0}-{h1} %. Aparatos: {ap} · {f} al día.", a)
	return T("{m} · de día {d}{dm} · de noche {n}{nm}\nBien: {t0}-{t1} °C y {h0}-{h1} %. Aparatos: {ap}.", a)
