# Landrace Hunters (Godot) — al cosechar en la huerta, arrancar la planta o dejarla revegetar (lo pidió el usuario: «Se corta vaya o
# se deja que revegete»), con Datos.CAL: la pregunta al cosechar, la poda (vuelve a vegetativo, el estrés y la mata pequeña), el
# reposo hasta la primavera del año siguiente (también en días largos), el frío del invierno entero sin curarse, el abono a cero, la
# temporada siguiente con más cosecha y más tope, el tope de años, las autoflorecientes y que dentro de casa no se pregunta.
#   $GODOT --headless --path godot --script res://tests/huerta_reveg.gd   → «huerta_reveg: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MENUS.append(labels)
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
			k = i
	o = o.duplicate()
	o.initial = k
	return o

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 60000 or not M.paso():
			print("  bloqueo: fin %s libre %s pend %s modo %s" % [st.fin, J.is_free(), J.pending.size(), J.mode])
			return false
	return true

func dicho(t: String) -> bool:
	for l in LOG:
		if String(l).contains(t):
			return true
	return false

func ofrecido(t: String) -> bool:
	for m in MENUS:
		for l in m:
			if String(l).contains(t):
				return true
	return false

# un día en el que el tiempo de las 6 cumple f (de d0 en adelante, hasta un año)
func dia_que(d0: int, f: Callable) -> int:
	for d in range(d0, d0 + 366):
		if f.call(Datos.tiempo(d, 360)):
			return d
	return -1

# la temporada de hora en hora hasta el día d1: regadas, sin plaga y con salud (como en tests/huerta.gd)
func temporada(d1: int) -> void:
	var S: Dictionary = J.S
	while int(S.day) < d1:
		for h in 24:
			S.min = h * 60
			for p in J.huerta_s().p:
				if p is Dictionary:
					p.water = 100.0
					p.pest = false
					p.health = 100.0
			J.huerta_avanza(60)
		S.day += 1
		S.min = 0

# el invierno de una revegetada podada ese día, día a día con huerta_dia y sin tocarle la salud: lo que le queda o si se seca
func invierno(p: Dictionary, poda: int) -> Dictionary:
	var S: Dictionary = J.S
	p.rev = 1
	p.rvd = poda
	p.prog = float(J.HUERTA.rev.prog)
	p.health = 100.0 - float(J.HUERTA.rev.estres)
	p.erase("dead")
	p.erase("bot")
	for d in range(poda + 1, J.huerta_prim(poda) + 1):
		S.day = d
		S.min = 360
		J.huerta_dia()
	return {"salud": float(p.health), "seca": true if p.get("dead") else false}

# planta en el sitio i el día d0 y la lleva hasta la cosecha del 20 de septiembre de ese año
func hasta_cosecha(i: int, sid: String, d0: int) -> void:
	var S: Dictionary = J.S
	S.seeds[sid] = int(S.seeds.get(sid, 0)) + 1
	S.day = d0
	S.min = 8 * 60
	QUIERO = [J.strain(sid).n]
	var s: Array = J.huerta_def().sitios[i]
	chk(corre(func(): await J.object_action(s[0], s[1])), "plantar en el sitio %d" % i)
	var pp = J.huerta_s().p[i]   # sin rarezas: la doble cosecha rebrota sola y aquí se prueba la revegetación (se mira aparte)
	if pp is Dictionary and pp.get("f") is Dictionary:
		pp.f.ra = []
	S.ra = {}
	temporada(Datos.dia_de(int(Datos.fecha(d0).y), 9, 20))
	var p = J.huerta_s().p[i]
	chk(p is Dictionary and float(p.prog) >= 1, "lista para cosechar en el sitio %d (%s)" % [i, p.prog if p is Dictionary else "null"])

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-hreveg.json"
	Juego.AJUSTES = "user://prueba-hreveg-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var S: Dictionary = J.S
	S.mode = "world"
	J.mode = "world"
	S.erase("huerta")
	var H: Dictionary = J.HUERTA
	var R: Dictionary = H.rev
	# la huerta, encontrada y desbrozada
	J.enter_map("town", 9, 2, "up")
	J.huerta_s().v = 1
	J.huerta_s().l = 1
	J.montar_huerta("town")
	J.MAPS[H.mapa] = J.mapa_huerta()
	J.enter_map(H.mapa, int(H.llega[0]), int(H.llega[1]), "up")
	var sid: String = String(Datos.carga().BANCO[0][0])
	var s0: Array = H.sitios[0]
	# 1 · la primera temporada y la pregunta al cosechar
	hasta_cosecha(0, sid, 1)
	var p0 = J.huerta_s().p[0]
	J.huerta_s().t[0] = 2
	var g1: int = Cultivo.gramos_planta(S, p0, J.huerta_f(p0, 0))
	var sa: float = float(p0.health)
	MENUS.clear()
	LOG.clear()
	QUIERO = ["Cosechar", "Dejarla revegetar"]
	chk(corre(func(): await J.object_action(s0[0], s0[1])), "cosechar y dejarla revegetar")
	chk(ofrecido("Dejarla revegetar") and ofrecido("Arrancarla"), "al cosechar se elige: %s" % [MENUS])
	chk(J.huerta_s().p[0] is Dictionary, "revegetando: la planta sigue en el sitio")
	p0 = J.huerta_s().p[0]
	chk(int(p0.get("rev", 0)) == 1, "primer año revegetada (rev %s)" % p0.get("rev"))
	chk(is_equal_approx(float(p0.prog), float(R.prog)) and float(p0.get("vd", -1)) == 0.0, "vuelve a vegetativo (prog %s, vd %s)" % [p0.prog, p0.get("vd")])
	chk(is_equal_approx(float(p0.health), maxf(float(R.min), sa - float(R.estres))), "el estrés de la poda: salud %s (de %s)" % [p0.health, sa])
	chk(not p0.has("bot") and not p0.has("corta") and p0.get("pest") == false, "sin botritis ni poda de antes: %s" % [p0])
	chk(J.huerta_t(0) == 2, "la tierra sigue labrada (%d)" % J.huerta_t(0))
	chk(String(J.MAPS.huerta.o[s0[1]][s0[0]]) == "hg-%s-2" % Datos.porte_planta(S, p0), "se ve la mata podada: %s" % J.MAPS.huerta.o[s0[1]][s0[0]])
	chk(dicho("Revegeta"), "lo dice: %s" % [LOG])
	# 2 · el reposo: no tira hasta la primavera del año siguiente a la poda, y el abono vuelve a cero
	chk(int(p0.get("rvd", 0)) > 0, "apunta el día de la poda (rvd %s)" % p0.get("rvd"))
	chk(J.huerta_prim(int(p0.rvd)) == Datos.dia_de(2027, 4, 20), "vuelve a tirar el 20 de abril de 2027 (%s)" % Datos.fd(J.huerta_prim(int(p0.rvd))))
	chk(not p0.has("fq") and not p0.has("fo") and p0.get("fert") == false and J._fv(p0) == 0.0, "el abono, a cero: hay que volver a abonarla (%s)" % [p0])
	S.items["fertv"] = 1
	MENUS.clear()
	QUIERO = ["Salir"]
	chk(corre(func(): await J.object_action(s0[0], s0[1])), "abrir la ficha de la revegetada")
	chk(ofrecido("Abonar"), "ABONAR se vuelve a ofrecer tras la poda: %s" % [MENUS])
	S.day = Datos.dia_de(2026, 11, 10)
	S.min = 600
	chk(not J.huerta_veg(S.day) and J.huerta_reposa(p0), "el 10 de noviembre, días cortos y en reposo")
	var pr: float = float(p0.prog)
	for h in 24 * 20:
		S.min = (h % 24) * 60
		J.huerta_avanza(60)
	chk(is_equal_approx(float(p0.prog), pr), "en reposo no crece en 20 días (%s → %s)" % [pr, p0.prog])
	# el mismo año no vuelve a dar: podada en días largos, sigue parada hasta la primavera siguiente
	var rvd0: int = int(p0.rvd)
	p0.rvd = Datos.dia_de(2026, 7, 1)
	S.day = Datos.dia_de(2026, 7, 10)
	chk(J.huerta_veg(S.day) and J.huerta_reposa(p0), "podada en julio: con días largos sigue en reposo")
	pr = float(p0.prog)
	for h in 24 * 30:
		S.min = (h % 24) * 60
		J.huerta_avanza(60)
	chk(is_equal_approx(float(p0.prog), pr), "y no vuelve a crecer ese mismo año (%s → %s)" % [pr, p0.prog])
	p0.rvd = rvd0
	# 3 · el frío de la revegetada, que no se cura sola
	S.day = Datos.dia_de(2026, 11, 10)
	var dh := dia_que(Datos.dia_de(2026, 11, 1), func(t): return int(t.min) <= 0 and t.k != "nieve")
	chk(dh > 0, "hay un día de helada")
	S.day = dh + 1
	p0.health = 100.0
	J.huerta_dia()
	chk(is_equal_approx(float(p0.health), 100.0 - float(H.helada) * float(R.frio)), "la helada le quita menos siendo leñosa: %s" % p0.health)
	var dt := dia_que(Datos.dia_de(2026, 12, 1), func(t): return int(t.min) > 0 and t.k != "nieve")
	chk(dt > 0, "hay un día sin helada")
	S.day = dt + 1
	p0.health = 50.0
	J.huerta_dia()
	chk(is_equal_approx(float(p0.health), 50.0), "en reposo no se repone sola: %s" % p0.health)
	# 3 bis · el invierno entero, sin forzarle la salud: uno flojo la deja tocada, uno duro se la lleva (tools/invierno.py)
	var i26: Dictionary = invierno(p0, Datos.dia_de(2026, 9, 21))
	chk(not i26.seca and float(i26.salud) < 60.0, "el invierno de 2026 la deja tocada: salud %.1f" % i26.salud)
	var i28: Dictionary = invierno(p0, Datos.dia_de(2028, 9, 21))
	chk(i28.seca, "el invierno de 2028, el duro, se la lleva (salud %.1f)" % i28.salud)
	print("  huerta_reveg: invierno 2026 → %.1f de salud, 2028 → %s" % [i26.salud, "seca" if i28.seca else "%.1f" % i28.salud])
	p0.erase("dead")
	p0.health = 100.0
	p0.rvd = rvd0
	# 4 · la temporada siguiente: con la raíz hecha, más cosecha
	S.day = Datos.dia_de(2027, 4, 25)
	S.min = 480
	chk(J.huerta_veg(S.day), "el 25 de abril del año siguiente, días largos otra vez")
	temporada(Datos.dia_de(2027, 6, 1))
	chk(float(p0.prog) > float(R.prog), "en primavera vuelve a tirar (prog %s)" % p0.prog)
	temporada(Datos.dia_de(2027, 9, 20))
	chk(float(p0.prog) >= 1, "lista otra vez a primeros de septiembre (%s)" % p0.prog)
	var g2: int = Cultivo.gramos_planta(S, p0, J.huerta_f(p0, 0))
	chk(is_equal_approx(float(J.huerta_f(p0, 0).cap), float(H.cap) * (1 + float(R.g) * int(p0.rev))), "el tope sube con el bono: %s" % J.huerta_f(p0, 0).cap)
	# con una variedad a tope de vegetativo y abonada, el tope ya no se come el bono
	var pg: Dictionary = Cultivo.nueva_planta(S, sid)
	pg.prog = 1.0
	pg.vd = float(H.veg_dias)
	pg.fert = true
	pg.fq = 1.0
	var gs: int = Cultivo.gramos_planta(S, pg, J.huerta_f(pg, 0))
	pg.rev = 1
	var gr: int = Cultivo.gramos_planta(S, pg, J.huerta_f(pg, 0))
	chk(gr >= int(gs * (1 + float(R.g)) * .95), "abonada y a tope de vegetativo, la revegetada da el +%d %%: %d g de %d" % [roundi(float(R.g) * 100), gr, gs])
	chk(g2 > g1, "la revegetada da más: %d g frente a %d g" % [g2, g1])
	chk(g2 >= int(g1 * (1 + float(R.g)) * .85), "y es por la raíz hecha (+%d %%): %d g de %d esperados" % [roundi(float(R.g) * 100), g2, roundi(g1 * (1 + float(R.g)))])
	print("  huerta_reveg: 1.er año %d g, revegetada %d g" % [g1, g2])
	# 5 · el tope de años: con rev.max, se arranca sin preguntar
	p0.rev = int(R.max)
	MENUS.clear()
	LOG.clear()
	QUIERO = ["Cosechar"]
	chk(corre(func(): await J.object_action(s0[0], s0[1])), "cosechar la del último año")
	chk(not ofrecido("Dejarla revegetar"), "al tope, ya no se ofrece: %s" % [MENUS])
	chk(J.huerta_s().p[0] == null and J.huerta_t(0) == 0, "arrancada y la tierra sin trabajar otra vez")
	chk(dicho("ya no da para más"), "lo dice: %s" % [LOG])
	chk(J.MAPS.huerta.o[s0[1]][s0[0]] == "hgx", "el sitio, vacío")
	# 6 · arrancarla a mano
	hasta_cosecha(1, sid, Datos.dia_de(2028, 4, 20))
	J.huerta_s().t[1] = 1
	var s1: Array = H.sitios[1]
	MENUS.clear()
	QUIERO = ["Cosechar", "Arrancarla"]
	chk(corre(func(): await J.object_action(s1[0], s1[1])), "cosechar y arrancarla")
	chk(J.huerta_s().p[1] == null and J.huerta_t(1) == 0, "el sitio queda libre y la tierra sin trabajar (p %s, t %d, menús %s)" % [J.huerta_s().p[1], J.huerta_t(1), MENUS])
	# 6 bis · con la rareza de doble cosecha rebrota sola, sin preguntar nada
	hasta_cosecha(2, sid, Datos.dia_de(2029, 4, 20))
	var p2 = J.huerta_s().p[2]
	p2.f.ra = ["doble"]
	var s2: Array = H.sitios[2]
	MENUS.clear()
	QUIERO = ["Cosechar"]
	chk(corre(func(): await J.object_action(s2[0], s2[1])), "cosechar una de doble cosecha")
	chk(not ofrecido("Dejarla revegetar"), "la de doble cosecha no pregunta: %s" % [MENUS])
	p2 = J.huerta_s().p[2]
	chk(p2 is Dictionary and int(p2.get("rb", 0)) == 1 and int(p2.get("rev", 0)) == 0, "rebrota sola, sin revegetar (%s)" % [p2])
	# 6 ter · las autoflorecientes no revegetan: florecen por la edad, no por la luz
	var sa_auto := ""
	for k in Datos.carga().STRAINS:
		if Datos.carga().STRAINS[k].get("auto"):
			sa_auto = String(k)
			break
	if sa_auto != "":
		var pa: Dictionary = Cultivo.nueva_planta(S, sa_auto)
		pa.prog = 1.0
		LOG.clear()
		MENUS.clear()
		var au := {"fin": false, "r": true}
		var co3 := func():
			au.r = await J.reveg(pa, {"huerta": true, "l": [pa]}, 0)
			au.fin = true
		co3.call()
		var ta: float = M.reloj
		while not au.fin and M.reloj - ta < 20000:
			M.paso()
		chk(au.fin and au.r == false and not ofrecido("Dejarla revegetar"), "la auto no se ofrece revegetar (%s, %s)" % [au, MENUS])
		chk(dicho("autofloreciente"), "y lo dice: %s" % [LOG])
	# 7 · dentro de casa no se revegeta (el fotoperiodo lo pones tú)
	var pc: Dictionary = Cultivo.nueva_planta(S, sid)
	pc.prog = 1.0
	var dentro := {"fin": false, "r": true}
	var co := func():
		dentro.r = await J.reveg(pc, null)
		dentro.fin = true
	co.call()
	var t0: float = M.reloj
	while not dentro.fin and M.reloj - t0 < 20000:
		M.paso()
	chk(dentro.fin and dentro.r == false, "en una maceta, reveg() no hace nada (%s)" % [dentro])
	# 8 · sin CAL, como antes
	Datos.CAL = false
	var pd: Dictionary = Cultivo.nueva_planta(S, sid)
	var sc := {"fin": false, "r": true}
	var co2 := func():
		sc.r = await J.reveg(pd, {"huerta": true})
		sc.fin = true
	co2.call()
	t0 = M.reloj
	while not sc.fin and M.reloj - t0 < 20000:
		M.paso()
	chk(sc.fin and sc.r == false, "sin CAL, no se revegeta (%s)" % [sc])
	Datos.CAL = true
	print("huerta_reveg: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
