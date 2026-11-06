# Ribera Verde (Godot) — el repaso de coherencia con la partida del usuario (día 200, cap. 8): A en cada mueble y en cada persona de
# cada mapa; lo que no respondía nada (OBJ_MUDO en mundo.gd y los barcos del muelle), el póster del dormitorio que abría el PC gaming
# y la encargada de KAIA, muda (club_muelle sin rama en npc_talk). Con CAL.
#   $GODOT --headless --path godot --script res://tests/repaso.gd   → «repaso: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja repaso-club.png, repaso-almacen.png y repaso-vitrina.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var n := 0
var fallos := []
var LOG := []
var MEN := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func corre(f: Callable) -> bool:
	var st := {"fin": false}
	var co := func():
		await J.run(f)
		st.fin = true
	co.call()
	var t0: float = M.reloj
	while not st.fin or not J.is_free() or not J.pending.is_empty():
		if M.reloj - t0 > 30000 or not M.paso():
			return false
	return true

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	MEN.append(str(o.get("title", "")) + " → " + " | ".join(labels))
	o = o.duplicate()
	o.initial = labels.size() - 1   # la última: Nada
	return o

# A delante de (x, y) en el mapa: lo que sale (textos y menús)
func a_en(mapa: String, x: int, y: int) -> String:
	LOG.clear()
	MEN.clear()
	J.mode = "world"
	J.P.x = x
	J.P.y = y + 1
	J.P.dir = "up"
	chk(await corre(func(): await J.object_action(x, y)), "%s (%d, %d): se queda colgado" % [mapa, x, y])
	return " ¦ ".join(MEN + LOG)

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func foto(dir: String, k: String) -> void:
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("repaso-%s.png" % k))

func busca(mapa: String, o: String) -> Array:
	var m: Dictionary = J.MAPS[mapa]
	for y in int(m.h):
		for x in int(m.w):
			if m.o[y][x] == o:
				return [x, y]
	return []

func entra(mapa: String) -> void:
	var m: Dictionary = J.MAPS[mapa]
	var ex: Array = (m.exits.keys()[0] if m.exits.size() else "1,2").split(",")
	J.enter_map(mapa, int(ex[0]), int(ex[1]) - 1, "up")
	J.build_ents()

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-repaso.json"
	Juego.AJUSTES = "user://prueba-repaso-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	S.ch = 8
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(("%s: " % nm if nm else "") + str(t))
	J.gancho_toast = func(h, _ms): LOG.append("aviso: " + str(h))
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)

	# 1. lo que no respondía nada: cada «mapa:objeto» de OBJ_MUDO, con su texto
	for k in J.OBJ_MUDO:
		if not ":" in k:
			continue
		var mapa: String = k.get_slice(":", 0)
		var o: String = k.get_slice(":", 1)
		if not J.MAPS.has(mapa):
			chk(false, "%s: no hay mapa" % k)
			continue
		if mapa == "setas" and not (S.get("setas") is Dictionary):   # el bajo, solo con el alquiler
			S.setas = {"r": int(S.day) + 5, "bandejas": [], "g": 0}
		entra(mapa)
		var p := busca(mapa, o)
		if p.is_empty():   # lo que sale según la partida (la banderola del concesionario, la mesita del ayudante): se pone
			var m: Dictionary = J.MAPS[mapa]
			for y in range(2, int(m.h) - 1):
				for x in int(m.w):
					if p.is_empty() and m.o[y][x] == null and m.o[y + 1][x] == null and J.ent_at(x, y) == null and J.ent_at(x, y + 1) == null:
						m.o[y][x] = o
						p = [x, y]
		chk(p.size() == 2, "%s: no está en el mapa" % k)
		if p.size() == 2:
			var t := await a_en(mapa, p[0], p[1])
			chk(t.find(String(J.OBJ_MUDO[k]).left(20)) >= 0, "%s: «%s»" % [k, t])
	# y la planta de interior de cualquier sitio, sin el suyo
	for mapa in ["est-rv", "est-puerto"]:
		if J.MAPS.has(mapa):
			entra(mapa)
			var p := busca(mapa, "plantDeco")
			if p.size() == 2:
				var t := await a_en(mapa, p[0], p[1])
				chk(t != "", "%s plantDeco: mudo" % mapa)
	# los barcos del muelle
	if J.MAPS.has("muelle"):
		entra("muelle")
		for b in J.D.MAR.barcos:
			var p := busca("muelle", b.o)
			if p.size() == 2:
				var t := await a_en("muelle", p[0], p[1])
				chk(t.find("noray") >= 0, "muelle %s: «%s»" % [b.o, t])

	# 2. el póster del dormitorio: su menú, no el del PC gaming
	S.muebles = S.get("muebles") if S.get("muebles") is Dictionary else {}
	S.muebles.cartel = 1
	entra("home")
	J.montar_casa()
	var pc := busca("home", "cartel")
	chk(pc.size() == 2, "home: no está el póster")
	if pc.size() == 2:
		var t := await a_en("home", pc[0], pc[1])
		chk(t.find("póster") >= 0 and t.find("PC gaming") < 0, "home cartel: «%s»" % t)
	var pg := busca("home", "gpc")
	if pg.size() == 2:   # y el PC gaming sigue siendo el PC gaming
		var t := await a_en("home", pg[0], pg[1])
		chk(t.find("PC gaming") >= 0, "home gpc: «%s»" % t)

	# 3. ninguna persona de club sin rama: la encargada de KAIA responde
	var hay := false
	for d in J.D.NPCDEF:
		if String(d.id).begins_with("club_"):
			hay = hay or d.id == "club_muelle"
	chk(hay, "no hay club_muelle en NPCS")
	if J.MAPS.has("club-muelle"):
		entra("club-muelle")
		for en in J.ents:
			if en.id == "club_muelle":
				LOG.clear()
				MEN.clear()
				chk(await corre(func(): await J.hablar_con(en)), "club_muelle: colgado")
				chk((MEN + LOG).size() > 0, "club_muelle: muda")

	# 4. (lo pidió el usuario) el almacén del dispensario, por su puerta; sin ser presidente, con llave
	S.aso = J.aso()
	S.aso.pres = false
	entra("club-rv")
	var pu: Array = J.puertas_int("club-rv").filter(func(q): return String(q.get("to", "")) != "banco-rv")   # la del cuarto de atrás, en tests/banco_tia.gd
	chk(pu.size() == 1 and J.MAPS["club-rv"].o[1][int(pu[0].x)] == "puertaI", "club-rv: sin la puerta del almacén")
	chk(J.MAPS["club-rv"].o[2][int(pu[0].x)] == null, "club-rv: algo delante de la puerta")
	var t4 := await a_en("club-rv", int(pu[0].x), 1)
	chk(t4.find("llave") >= 0 and S.map == "club-rv", "club-rv sin ser presidente: «%s»" % t4)
	S.aso.pres = true
	entra("club-rv")
	await a_en("club-rv", int(pu[0].x), 1)
	chk(S.map == "alm-rv", "la puerta del almacén no lleva a alm-rv (%s)" % S.map)
	var es := busca("alm-rv", "almC")
	chk(es.size() == 2, "alm-rv: sin estanterías")
	if es.size() == 2:
		var ta := await a_en("alm-rv", es[0], es[1])
		chk(ta.find("ALMACÉN DEL CLUB") >= 0, "alm-rv almC: «%s»" % ta)
		chk(J.sprite_local("almC") == "almC-0", "alm-rv: la estantería vacía (%s)" % J.sprite_local("almC"))
	await a_en("alm-rv", 1, 1)
	chk(S.map == "club-rv", "la puerta del almacén no vuelve al club (%s)" % S.map)
	entra("club-rv")
	# 5. (lo pidió el usuario) el dispensario, en sus vitrinas: el lote en tarros de ALM.tarro y, con A, el menú de siempre
	S.aso.lote = {"k": "ria", "g": 300, "pg": 8.5, "tot": 120, "thc": 18.0}
	J.DISP = {"H": S.aso, "key": "lote"}
	var its: Array = J.items_almacen("disp")
	chk(its.size() == 1 + ceili(300.0 / float(J.D.ALM.tarro)), "vitrina: %d huecos" % its.size())
	var R: Array = J.rects_almacen({"t": "disp", "i": 1})
	chk(R.any(func(r): return r[0] is String and String(r[1]).begins_with("alm-tarro")), "vitrina: sin tarros")
	chk(J.desc_almacen({"t": "disp", "i": 1}).find("8,50") >= 0, "vitrina: «%s»" % J.desc_almacen({"t": "disp", "i": 1}))
	J.DISP = null
	LOG.clear()
	MEN.clear()
	chk(await corre(func(): await J.dispensario_aso()), "dispensario_aso: colgado")
	chk(" ".join(LOG).find("quedan") >= 0, "dispensario, tras la vitrina: «%s»" % " ".join(MEN + LOG))
	var dir := arg("--pintar")
	if dir != "":
		J.oraculo = false
		J.set_process(false)
		J.enter_map("club-rv", 3, 2, "up")
		J.build_ents()
		J.mode = "world"
		await foto(dir, "club")
		S.aso.al = {"buds": {"ria": {"g": 700.0, "thc": 14.0, "q": 1.0}}, "rosin": {}, "tot": 0}
		J.enter_map("alm-rv", 1, 3, "up")
		J.build_ents()
		await foto(dir, "almacen")
		J.enter_map("club-rv", 1, 4, "up")
		J.build_ents()
		J.DISP = {"H": S.aso, "key": "lote"}
		J.ALMACEN = {"t": "disp", "i": 2}
		J._dlg_fijo(J.desc_almacen(J.ALMACEN), "DISPENSARIO")
		await foto(dir, "vitrina")
	print("repaso: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)
