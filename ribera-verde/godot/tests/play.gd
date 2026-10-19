# Landrace Hunters (Godot) — la versión de Google Play (Datos.PLAY, fase 2 del plan): sin cifras reales de cultivo en lo que se ve
# (°C, micras, µm, pH; ni rastro de «pk-»), los híbridos con nombre propio (las landraces, igual), sin el bajo de las setas ni las
# apuestas del billar, el aviso nuevo y la copia de seguridad de Android. Y que con PLAY = false todo vuelve a ser como antes.
#   $GODOT --headless --path godot --script res://tests/play.gd   → «play: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []
var MAL := RegEx.create_from_string("°C|µm|[Mm]icra|\\bpH\\b|\\bpk-|PK_TILE|[Pp]ok[eé]mon")

func _initialize() -> void:
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

# todos los textos de un valor de los datos
func textos(v, out: Array, ruta: String) -> void:
	if v is String:
		out.append([ruta, v])
	elif v is Dictionary:
		for k in v:
			textos(v[k], out, ruta + "." + str(k))
	elif v is Array:
		for i in v.size():
			textos(v[i], out, ruta + "." + str(i))

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-play.json"
	Juego.AJUSTES = "user://prueba-play-ajustes.json"
	Datos.CAL = true
	Datos.PLAY = true
	var D: Dictionary = Datos.carga()
	var P = JSON.parse_string(FileAccess.get_file_as_string("res://datos/play.json"))
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://datos/datos.json"))
	# 1 · los datos: nada de °C, micras ni pH en ningún texto (los mapas no tienen textos que se vean)
	var T := []
	for k in D:
		if k != "MAPS" and k != "_base" and k != "NEW_STATE" and k != "MASCARAS":
			textos(D[k], T, k)
	var malos := []
	for t in T:
		if MAL.search(t[1]):
			malos.append("%s: %s" % [t[0], t[1].substr(0, 90)])
	chk(malos.is_empty(), "datos con cifras reales (%d): %s" % [malos.size(), malos.slice(0, 6)])
	chk(T.size() > 3000, "textos recorridos: %d" % T.size())
	# 2 · las variedades: los híbridos con nombre propio, las landraces igual, y ningún nombre viejo en los textos
	var L: Array = D.LANDRACES
	var guarda := ["congopan", "malapan", "malapck", "ruderalis", "durbanauto"]
	var mal_n := []
	for k in D.STRAINS:
		var a: String = O.STRAINS[k].n
		var b: String = D.STRAINS[k].n
		if k in L or k in guarda:
			if a != b:
				mal_n.append("%s cambia: %s → %s" % [k, a, b])
		elif a == b:
			mal_n.append("%s sin nombre nuevo: %s" % [k, a])
	chk(mal_n.is_empty(), "nombres: %s" % [mal_n])
	var viejos := []
	for v in P.nombres:
		if v.length() >= 5:
			viejos.append(v)
	var con_viejo := []
	var rx := RegEx.create_from_string("(?<![A-Za-zÀ-ÿ0-9])(%s)(?![A-Za-zÀ-ÿ0-9\\-])" % "|".join(viejos.map(func(x): return Datos._esc(x))))
	for t in T:
		if rx.search(t[1]):
			con_viejo.append("%s: %s" % [t[0], t[1].substr(0, 80)])
	chk(con_viejo.is_empty(), "nombres viejos en los textos (%d): %s" % [con_viejo.size(), con_viejo.slice(0, 6)])
	# 3 · el código: cada texto entre comillas de src/*.gd, después de Datos.tp (lo que hacen diálogos, menús y avisos)
	var lit := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var malos_c := []
	for f in DirAccess.get_files_at("res://src"):
		if not f.ends_with(".gd"):
			continue
		var i := 0
		for l in FileAccess.get_file_as_string("res://src/" + f).split("\n"):
			i += 1
			var c := l.strip_edges()
			if c.begins_with("#"):
				continue
			var sin := l.split(" # ")[0] if not l.contains("\"#") else l
			for m in lit.search_all(sin):
				var s: String = Datos.tp(m.get_string(1))
				if MAL.search(s):
					malos_c.append("%s:%d %s" % [f, i, s.substr(0, 70)])
	chk(malos_c.is_empty(), "textos del código con cifras reales (%d): %s" % [malos_c.size(), malos_c.slice(0, 8)])
	chk(not MAL.search(Datos.tp("Echa pH− con el medidor de pH y EC: el pH al 6,2 y 20 °C, malla de 73 µm")), "Datos.tp")
	# 4 · las extracciones y el foro, sin cifras; la Ice-o-lator no es la variedad Ice
	chk(not String(D.EXTR.rosin.d).contains("80") and not String(D.EXTR.ice.d).contains("4"), "extracciones: %s / %s" % [D.EXTR.rosin.d, D.EXTR.ice.d])
	chk(String(D.EXTR.ice.n) == "Ice-o-lator" and Datos.tp("el kit Ice-o-lator") == "el kit Ice-o-lator", "Ice-o-lator")
	chk(Datos.tp("una Ice muy blanca") == "una Ize muy blanca", "Ice → Ize: %s" % Datos.tp("una Ice muy blanca"))
	chk(Datos.tp("es JACK HERER.") == "es JAK HERRER.", "JACK HERER → JAK HERRER: %s" % Datos.tp("es JACK HERER."))
	# 5 · ida y vuelta: sin PLAY, como antes (en su sitio: las mismas listas)
	var foro: Array = D.FORO
	Datos.PLAY = false
	Datos.carga()
	chk(D.STRAINS.ria.n == "Skunk #1" and foro == D.FORO and String(D.FORO[0]).begins_with("pH del agua"), "sin PLAY: %s / %s" % [D.STRAINS.ria.n, D.FORO[0]])
	chk(Datos.tp("pH− y Skunk #1") == "pH− y Skunk #1", "sin PLAY, tp no cambia nada")
	var iguales := true
	for k in P.claves:
		if JSON.stringify(D[k]) != JSON.stringify(O[k]) and k != "BANCO":
			iguales = false
			print("  distinto sin PLAY: ", k)
	chk(iguales, "sin PLAY, los datos de antes")
	Datos.PLAY = true
	Datos.carga()
	chk(D.STRAINS.ria.n == "Skonk #1" and not String(D.FORO[0]).contains("pH"), "otra vez con PLAY: %s" % D.STRAINS.ria.n)
	# 6 · el juego: sin Txomin, sin SMS, sin mapa ni cartel del bajo, la puerta cerrada, sin sótano en la tienda; billar sin apuestas
	var Oe = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in Oe:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(J.nm(t))
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var S = J.S
	var Croquis = preload("res://src/croquis.gd")
	S.erase("setas")
	S.flags.erase("setasSms")
	S.ch = int(D.SETAS.ch) + 1
	var tx = D.NPCDEF.filter(func(x): return x.id == "txomin")[0]
	chk(not J.npc_cond(tx), "Txomin no sale")
	J.enter_map("callejon", 8, 11, "up")
	J.mode = "world"
	chk(J.ents.filter(func(x): return x.get("id") == "txomin").is_empty(), "Txomin en el callejón")
	LOG = []
	chk(corre(J.check_story), "historia bloqueada")
	chk(not S.flags.get("setasSms") and not " ".join(LOG).contains("Txomin"), "SMS de las setas: %s" % [LOG])
	chk(not Croquis.desc_mapa(D, int(S.ch), {"i": Croquis.ORDEN.find("ibarbide")}, "town").contains(D.SETAS_SITIO.mapa), "el bajo en el mapa")
	LOG = []
	chk(corre(func(): await J.object_action(8, 10)), "cartel bloqueado")
	chk(not " ".join(LOG).contains(D.SETAS_SITIO.cartel), "cartel del bajo: %s" % [LOG])
	J.enter_map("callejon", 19, 8, "up")
	J.mode = "world"
	LOG = []
	chk(corre(func(): await J.entra_local(J.MAPS.callejon.doors["19,7"])), "puerta del bajo bloqueada")
	chk(S.map == "callejon" and not " ".join(LOG).contains("Txomin"), "la puerta del bajo: %s en %s" % [LOG, S.map])
	# el billar: «Una partida» o «Nada», sin euros
	MENUS = []
	QUIERO = ["Nada"]
	var m0 = S.money
	chk(corre(func(): await J.talk_billar("ibar")), "billar bloqueado")
	chk(MENUS.size() and MENUS[0] == ["Una partida", "Nada"] and S.money == m0, "billar: %s" % [MENUS])
	# el aviso de edad
	LOG = []
	QUIERO = ["TENGO"]
	chk(corre(J.aviso_edad), "aviso bloqueado")
	chk(" ".join(LOG).contains("No es una guía de cultivo") and not " ".join(LOG).contains("No anima a"), "aviso: %s" % [LOG])
	# 7 · Android: la copia de seguridad automática de la partida
	chk(FileAccess.get_file_as_string("res://export_presets.cfg").contains("user_data_backup/allow=true"), "user_data_backup")
	for x in fallos:
		print("  FALLO ", x)
	print("play: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
