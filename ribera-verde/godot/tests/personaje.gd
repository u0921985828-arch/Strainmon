# Landrace Hunters (Godot) — MAESTRO [1]: crear el personaje (chico o chica y el cumpleaños, S.sexo y S.cumple), la melena de la
# protagonista sobre todos los fotogramas, las pasivas (PERSONAJE: carga, patrullas, regateo), el regalo del cumpleaños con sus tres
# cartas (una vez al año, con el 29 de febrero) y la semilla estrella; sin Datos.CAL, nada de esto.
#   $GODOT --headless --path godot --script res://tests/personaje.gd   → «personaje: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Motor = preload("res://src/motor.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
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
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

const Atlas = preload("res://src/atlas.gd")

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-personaje.json"
	Juego.AJUSTES = "user://prueba-personaje-ajustes.json"
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
	J.enter_map("home", 9, 3, "up")
	J.mode = "world"
	var D = J.D
	var PE: Dictionary = D.PERSONAJE
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · crear: chica, cumpleaños el 29 de febrero
	J.S.erase("sexo")
	J.S.erase("cumple")
	var cap0: float = J.cap_mochila()
	var vis0: int = J.vista_pat()
	chk(vis0 == int(D.PAT.vista[0]), "sin elegir, la vista de siempre %d" % vis0)
	QUIERO = ["CHICA", "Febrero", "29"]
	chk(corre(func(): await J.elegir_personaje()), "elegir_personaje termina")
	chk(J.S.gen is Dictionary, "S.gen (las generaciones) sigue siendo un diccionario")
	chk(J.S.get("sexo") == "f" and J.S.get("cumple") == {"d": 29, "m": 2}, "chica y 29-2: %s %s" % [J.S.get("sexo"), J.S.get("cumple")])
	chk(MENUS.size() >= 3 and MENUS[-1].size() == 29, "febrero con 29 días en el menú: %d" % (MENUS[-1].size() if MENUS.size() else -1))
	# 2 · pasivas: ella, la patrulla ve un 15 % menos; él, un 15 % más de carga; sin elegir (partidas de antes), nada
	chk(J.vista_pat() == int(floor(int(D.PAT.vista[0]) * (1 - PE.poli))) and J.vista_pat() < vis0, "vista con chica %d" % J.vista_pat())
	chk(J.vista_pat(true) == int(floor(int(D.PAT.vista[0]) * 2 * (1 - PE.poli))), "vista de caza %d" % J.vista_pat(true))
	chk(absf(J.cap_mochila() - cap0) < 1e-9, "chica: carga igual")
	J.S.sexo = "m"
	chk(absf(J.cap_mochila() - cap0 * (1 + PE.carga)) < 1e-6 and J.vista_pat() == vis0, "chico: +15 %% carga %s → %s" % [cap0, J.cap_mochila()])
	# 3 · la melena: solo en ella, en todos los fotogramas, con contorno; él, igual que antes
	var cambia := 0
	var iguales := 0
	var mira := 0
	for gr in ["player", "player-combate"]:
		for an in ["base", "run"]:
			for d in ["south", "east", "north", "west"]:
				var f = Atlas.frame_de(gr, an, d, 0, {"i": 0})
				if f == null:
					continue
				mira += 1
				J.S.sexo = "m"
				var a: Image = J.ropa_c(f, gr).c
				J.S.sexo = "f"
				var b: Image = J.ropa_c(f, gr).c
				if a.get_data() == f.c.get_data():
					iguales += 1
				if b.get_data() != a.get_data():
					cambia += 1
	chk(mira >= 8 and cambia == mira and iguales == mira, "melena en %d de %d; él igual en %d" % [cambia, mira, iguales])
	# 4 · el cumpleaños: el 29-2 de 2028 (bisiesto) y el 28-2 de 2027; un regalo al año; sin CAL, nada
	var d28 := Datos.dia_de(2027, 2, 28)
	var d29 := Datos.dia_de(2028, 2, 29)
	chk(J.es_cumple(d28) and J.es_cumple(d29) and not J.es_cumple(Datos.dia_de(2028, 2, 28)) and not J.es_cumple(Datos.dia_de(2027, 3, 1)), "es_cumple con bisiestos")
	J.S.day = d29 - 1
	J.queued.clear()
	J.pending.clear()
	var it0: int = int(J.S.items.get("fert", 0))
	QUIERO = ["RARO"]
	chk(corre(func(): J.new_day()), "new_day del cumpleaños")
	chk(int(J.S.get("cumpleY", 0)) == 2028 and int(J.S.items.get("fert", 0)) == it0 + int(PE.cumple.rara.fert), "regalo raro: fert %d → %d" % [it0, int(J.S.items.get("fert", 0))])
	chk(MENUS.any(func(m): return m.size() == 3 and m[0].begins_with("LEGENDARIO") and m[1].begins_with("ÉPICO") and m[2].begins_with("RARO")), "las tres cartas")
	var nm := MENUS.size()
	J.queued.clear()
	chk(corre(func(): J.queue("x", func(): pass); if J.es_cumple(J.S.day) and int(J.S.get("cumpleY", 0)) != 2028: J.queue("cumple", J.cumple_event)), "otra vez el mismo año")
	chk(MENUS.size() == nm, "un regalo por año")
	# legendario: la semilla sale estrella
	QUIERO = ["LEGENDARIO"]
	var sid: String = J.semilla_cumple()
	var s0: int = int(J.S.seeds.get(sid, 0))
	chk(corre(func(): await J.cumple_event()), "regalo legendario")
	chk(int(J.S.seeds.get(sid, 0)) == s0 + 1 and int(J.S.estrella.get(sid, 0)) == 1, "semilla ★ de %s" % sid)
	var f := {"id": 1, "t": 0.7, "y": 0.8}
	J.estrella_regalo(sid, f)
	chk(J.Cultivo.clase_feno(f) == "estrella" and not J.S.estrella.has(sid), "sale estrella %s" % [f])
	var f2 := {"id": 2, "t": 0.7, "y": 0.8}
	J.estrella_regalo(sid, f2)
	chk(J.Cultivo.clase_feno(f2) != "estrella", "solo la primera")
	# épico
	QUIERO = ["ÉPICO"]
	var fk: String = "f_" + PE.cumple.epica.foco
	var e0: int = int(J.S.items.get(fk, 0))
	chk(corre(func(): await J.cumple_event()), "regalo épico")
	chk(int(J.S.items.get(fk, 0)) == e0 + int(PE.cumple.epica.n), "focos %d" % int(J.S.items.get(fk, 0)))
	# sin CAL: ni melena, ni pasivas, ni cumpleaños, ni menús
	Datos.CAL = false
	J.S.sexo = "f"
	chk(J.vista_pat() == vis0 and not J.es_cumple(d29) and not J.es_chica(), "sin CAL, nada")
	nm = MENUS.size()
	chk(corre(func(): await J.elegir_personaje()) and MENUS.size() == nm, "sin CAL, sin menús")
	Datos.CAL = true
	print("personaje: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  FALLO ", x)
	quit(1 if fallos.size() else 0)
