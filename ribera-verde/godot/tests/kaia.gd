# Ribera Verde (Godot) — el club KAIA, el tuyo (lo pidió el usuario: «que actúes tú como encargado del dispensario, de lo que hay, del
# diseño y de todo»), y la planta de los gestos tal como es (lo pidió el usuario: «sale la planta en grande… tendría que ser de los colores
# de la genética»); con CAL.
#   $GODOT --headless --path godot --script res://tests/kaia.gd   → «kaia: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var LOG := []
var QUIERO := []
var MENUS := []
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
			break
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
			print("  bloqueo: ", LOG.slice(-3), " ", QUIERO)
			return false
	return true

func lote() -> String:
	return str(J.venta_item(J.bud_lots(1)[0]).label)

func vio(t: String) -> bool:
	return MENUS.any(func(l): return l.has(t))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-kaia.json"
	Juego.AJUSTES = "user://prueba-kaia-ajustes.json"
	Datos.CAL = true
	var OJ = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in OJ:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	var D: Dictionary = J.D
	S.ch = 8
	S.erase("mar")
	S.banco = 300000
	S.money = 20000
	S.heat = 0
	S.buds = {}
	var sid: String = D.STRAINS.keys()[0]
	J.add_buds(sid, 3000, 24)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var K: Dictionary = D.MAR.kaia
	var KP: Dictionary = K.precio
	# 0 · el muelle con todas las obras hechas: KAIA abierto
	J.enter_map("muelle", 12, 9, "up")
	J.build_ents()
	J.mode = "world"
	corre(func(): await J.talk_koldo())
	chk(S.mar is Dictionary, "Koldo da la txalupa")
	S.mar.ob = {}
	S.mar.oba = {}
	for O in D.MAR.obras:
		S.mar.ob[O.k] = int(S.day)
		S.mar.oba[O.k] = int(S.day)
	S.mar.alq = int(S.day) + 7
	chk(J.obra_ya("club"), "KAIA, abierto")
	J.enter_map("club-muelle", 8, 9, "up")
	J.build_ents()
	J.mode = "world"
	chk(S.map == "club-muelle", "dentro de KAIA")
	# 1 · el panel del jefe: dispensario, almacén, diseño y ordenar
	MENUS.clear()
	QUIERO = ["Nada"]
	chk(corre(func(): await J.talk_kaia("Encargada")), "la encargada")
	for t in ["El dispensario", "El almacén", "El diseño", "Ordenar el local"]:
		chk(vio(t), "el panel de KAIA ofrece «%s»: %s" % [t, MENUS])
	# 2 · llenar el dispensario
	QUIERO = ["El dispensario", lote(), "%d g" % int(K.g[1]), "Nada"]
	chk(corre(func(): await J.talk_kaia("Encargada")), "dejar género")
	var L = S.mar.get("kaia")
	chk(L is Dictionary and int(L.g) == int(K.g[1]), "%d g al dispensario: %s" % [int(K.g[1]), L])
	var p0: float = float(L.pg)
	chk(absf(J.kaia_tiron(L) - 1.0) < 1e-6, "al precio de la casa, lo de siempre")
	# 3 · lo que hay y el precio
	MENUS.clear()
	QUIERO = ["El dispensario", "Subir el precio", "Nada", "Nada"]
	corre(func(): await J.talk_kaia("Encargada"))
	chk(vio("Rellenar") and vio("Retirar lo que queda"), "el dispensario gestionado: %s" % [MENUS])
	chk(absf(float(L.pg) - Datos.jsround(p0 * (1 + float(KP.paso)) * 100) / 100.0) < .011, "sube el precio un paso: %s → %s" % [p0, L.pg])
	chk(J.kaia_tiron(L) < 1.0, "más caro, salen menos (%s)" % J.kaia_tiron(L))
	QUIERO = ["El dispensario"]
	for i in 12:
		QUIERO.append("Subir el precio")
	QUIERO.append_array(["Nada", "Nada"])
	corre(func(): await J.talk_kaia("Encargada"))
	chk(absf(float(L.pg) - Datos.jsround(p0 * float(KP.max) * 100) / 100.0) < .011, "el precio, como mucho ×%s: %s" % [KP.max, L.pg])
	QUIERO = ["El dispensario"]
	for i in 20:
		QUIERO.append("Bajar el precio")
	QUIERO.append_array(["Nada", "Nada"])
	corre(func(): await J.talk_kaia("Encargada"))
	chk(absf(float(L.pg) - Datos.jsround(p0 * float(KP.min) * 100) / 100.0) < .011, "el precio, como poco ×%s: %s" % [KP.min, L.pg])
	chk(J.kaia_tiron(L) > 1.0 and J.kaia_tiron(L) <= 1.6, "más barato, salen más (%s)" % J.kaia_tiron(L))
	# 4 · cada mañana, lo que tira el precio
	var g0: float = float(L.g)
	var esp: float = minf(g0, J.kaia_dia() * J.kaia_tiron(L))
	var m0: float = S.money
	S.day += 1
	corre(func(): J.mar_dia())
	chk(absf(g0 - float(L.g) - esp) < .01, "salen %s g: %s" % [esp, g0 - float(L.g)])
	chk(absf(S.money - m0 - Datos.jsround(esp * float(L.pg))) < 1.01, "y lo cobras: %s" % (S.money - m0))
	# 5 · rellenar con más del mismo lote
	g0 = float(L.g)
	var b0: float = J.total_buds()
	QUIERO = ["El dispensario", "Rellenar", "%d g" % int(K.g[0]), "Nada", "Nada"]
	corre(func(): await J.talk_kaia("Encargada"))
	chk(absf(float(L.g) - g0 - float(K.g[0])) < .01 and absf(b0 - J.total_buds() - float(K.g[0])) < .01, "rellenar: +%d g" % int(K.g[0]))
	# 6 · retirar lo que queda
	g0 = float(L.g)
	b0 = J.total_buds()
	QUIERO = ["El dispensario", "Retirar lo que queda", "Sí", "Nada"]
	corre(func(): await J.talk_kaia("Encargada"))
	chk(S.mar.get("kaia") == null and absf(J.total_buds() - b0 - g0) < .01, "retirado: vuelven %s g" % g0)
	# 7 · la vitrina es el dispensario
	MENUS.clear()
	QUIERO = ["Nada"]
	corre(func(): await J.obj_local(0, 0, "vitrina"))
	chk(MENUS.any(func(l): return l.any(func(t): return t.begins_with(sid) or t.contains("g ·") or t == "Nada")) or LOG.any(func(t): return str(t).contains("dispensario")), "la vitrina abre el dispensario: %s" % [MENUS])
	# 8 · el diseño: se paga por transferencia y se ve al día siguiente
	var mk: Dictionary = J.MAPS["club-muelle"]
	J.montar_club("club-muelle")
	chk(String(mk.get("est", "")) == "itsaso", "KAIA, marinero de serie: %s" % mk.get("est"))
	var bb: float = S.banco
	QUIERO = ["El diseño", "Industrial", "Sí", "Nada"]
	corre(func(): await J.talk_kaia("Encargada"))
	chk(absf(bb - S.banco - float(K.dis.p)) < 1 and String(S.mar.get("kd", "")) == "fundicion", "la reforma, por transferencia")
	J.montar_club("club-muelle")
	chk(String(mk.get("est", "")) == "itsaso", "hasta mañana, como estaba")
	S.day += 1
	J.montar_club("club-muelle")
	var suf := func(s: String) -> int:
		var c := 0
		for row in mk.g:
			for t in row:
				if t is String and t.ends_with("_" + s):
					c += 1
		return c
	chk(String(mk.get("est", "")) == "fundicion" and suf.call("fundicion") > 0 and suf.call("itsaso") == 0, "al día siguiente, industrial: %d casillas" % suf.call("fundicion"))
	S.mar.kd = ""
	J.montar_club("club-muelle")
	chk(mk.get("est") == null and suf.call("fundicion") == 0 and suf.call("itsaso") == 0, "el clásico, sin sufijo")
	S.mar.kd = "itsaso"
	J.montar_club("club-muelle")
	chk(String(mk.get("est", "")) == "itsaso" and suf.call("itsaso") > 0, "y otra vez marinero")
	# 9 · ordenar el local desde el panel y desde una mesita
	MENUS.clear()
	QUIERO = ["Ordenar el local", "Terminar"]
	corre(func(): await J.talk_kaia("Encargada"))
	chk(vio("Los sofás de la izquierda") and vio("Terminar"), "ordenar el local desde el panel: %s" % [MENUS])
	MENUS.clear()
	QUIERO = ["Ordenar el local", "Terminar"]
	corre(func(): await J.obj_local(8, 3, "mesita"))
	chk(vio("Los sofás de la izquierda"), "ordenar el local desde una mesita: %s" % [MENUS])
	# 10 · los gestos con la planta tal como es
	var PL := []
	J.gancho_acceso = func(_k, _c, _ok): pass
	J.gancho_gesto = func(k, pl): PL.append([k, pl])
	J.enter_map("home", 5, 5, "up")
	var p := {"sid": sid, "prog": .2, "water": 70, "health": 100, "fert": false, "pest": false, "f": {"id": 77, "t": 1, "y": 1, "i": null}}
	S.pots[0] = p
	var alto := func(pr: float) -> int:
		p.prog = pr
		PL.clear()
		J.gesto_p = p
		corre(func(): await J.gesto("regar"))
		if PL.is_empty() or not PL[0][1].has("img"):
			return -1
		return (PL[0][1].img as Image).get_used_rect().size.y
	var h1: int = alto.call(.2)
	var h2: int = alto.call(.5)
	var h3: int = alto.call(.9)
	chk(h1 > 0 and h1 < h2 and h2 <= h3, "el gesto de regar, con la planta de su alto: %d < %d ≤ %d" % [h1, h2, h3])
	chk(PL.size() and str(PL[0][1].get("cog", "")) == str(Datos.color_cog(S, p)), "con el color de su variedad")
	var cs := {}
	for s in D.STRAINS.keys().slice(0, 6):
		PL.clear()
		J.gesto_sid = s
		corre(func(): await J.gesto("manicurar"))
		chk(PL.size() == 1 and PL[0][1].get("cog") == String(D.STRAINS[s].c), "manicurar %s, con el color de su cogollo" % s)
		if PL.size():
			cs[str(PL[0][1].get("cog"))] = 1
	chk(cs.size() > 1, "variedades distintas, colores distintos")
	var base: Image = J._gs_color("gs-cola", {})
	var pin: Image = J._gs_color("gs-cola", {"cog": "#c04ad0", "hoja": "#3a7a30"})
	chk(base != null and pin != null and base.get_data() != pin.get_data(), "la cola del gesto, repintada")
	J.gesto_p = null
	J.gesto_sid = ""
	PL.clear()
	corre(func(): await J.gesto("regar"))
	chk(PL.size() == 1 and not PL[0][1].has("img"), "sin planta, la genérica")
	print("kaia: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
