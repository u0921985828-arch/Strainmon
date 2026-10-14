# Ribera Verde (Godot) — 15-arranque y el bucle: guardar y cargar (con migrate de las partidas viejas), el título, el nombre,
# la partida nueva, entrar en el juego, update (el jugador, los personajes, el reloj del juego y los eventos pendientes) y
# el HUD. El dibujo de cada modo (mundo, carpa, combate, título) lo hace pinta.gd en el lienzo de SW × SH (180).
# Cadena: ui → mundo → granja → trama → juego (este es el script de la escena).
extends "res://src/trama.gd"

const Pinta = preload("res://src/pinta.gd")
const Arte = preload("res://src/arte.gd")

static var GUARDADO := "user://partida.json"   # las pruebas usan otro
var pintor = null

func _ready() -> void:
	super()
	if oraculo:
		return
	Arte.carga()
	pintor = Pinta.new()
	pintor.J = self
	lienzo.add_child(pintor)
	name_in.text_submitted.connect(func(_t): if name_box.visible: press("A"))
	if OS.get_cmdline_user_args().has("--sin-arranque"):
		return
	show_title()

func _process(dt: float) -> void:
	if oraculo:
		return
	var ms := dt * 1000
	M.avanza(M.reloj + ms)
	update(minf(50, ms))
	pintor.redibuja(M.reloj)
	_process_ui()

func _notification(w: int) -> void:
	if oraculo:
		return
	if w == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Atrás: B con un diálogo, un menú o la carpa abiertos; andando por el mapa, la pausa (el menú START, con el reloj
		# parado); en el título, sale
		if handlers.size():
			press("B")
		elif mode == "world":
			press("START")
		elif mode == "title" and lock == 0:
			get_tree().quit()
	elif w == NOTIFICATION_APPLICATION_PAUSED or w == NOTIFICATION_WM_CLOSE_REQUEST:
		suelta_todo()
		if S and (mode == "world" or mode == "carpa" or mode == "battle"):
			save()
	elif w == NOTIFICATION_APPLICATION_RESUMED:
		# al volver a la app, andando por el mapa, en pausa: el menú START
		if mode == "world" and is_free() and not P.moving:
			press("START")
	elif w == NOTIFICATION_APPLICATION_FOCUS_OUT:
		suelta_todo()

# ---------- guardado (a un archivo aparte y luego se cambia de nombre; sin ordenar las claves y con todos los decimales) ----------
func save():
	if S == null:
		return false
	S.x = P.x
	S.y = P.y
	S.dir = P.dir
	var tmp := GUARDADO + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(S, "", false, true))
	f.close()
	return DirAccess.rename_absolute(tmp, GUARDADO) == OK

func load_save():
	if not FileAccess.file_exists(GUARDADO):
		return null
	var j = JSON.parse_string(FileAccess.get_file_as_string(GUARDADO))
	return Datos.enteros(j) if j is Dictionary else null

func migrate() -> void:
	if not S.get("carpas"):   # antes de la 1.6: macetas extra → carpa de 100; lámpara LED → LED en cada carpa
		S.carpas = [{"t": "p60", "foco": "led200" if S.get("led") else "cfl"}]
		var po := int(S.get("potsOwned", 2)) if S.get("potsOwned") else 2
		if po > 2:
			S.carpas.append({"t": "m100", "foco": "led480" if S.get("led") else "cfl"})
		var nn := 0
		for c in S.carpas:
			nn += int(D.CARPAS[c.t].plazas)
		var old: Array = S.get("pots", []) if S.get("pots") else []
		var np := []
		for i in nn:
			np.append((old[i] if i < old.size() else null) if i < po else null)
		S.pots = np
		var mc := []
		for i in nn:
			mc.append("plastico7")
		S.macetas = mc
		S.erase("potsOwned")
		S.erase("led")
	if not S.get("eco"):   # antes de la 1.10: la deuda pasa a la escala real del capítulo
		var tb := {4: D.DEUDA - D.PLAZOS["3"], 5: D.DEUDA - D.PLAZOS["3"], 6: D.PLAZOS["7"], 7: D.PLAZOS["7"]}
		S.debt = 0 if S.ch >= 8 else int(tb.get(int(S.ch), 0) if tb.get(int(S.ch), 0) else D.DEUDA)
		if S.get("due", 0) > 0:
			S.due = int(D.PLAZOS[str(S.ch)]) if S.ch == 3 or S.ch == 5 else S.debt
			S.deadline = maxi(S.deadline, S.day + (10 if S.ch == 5 else 7))
		if S.ch >= 8:
			S.imp0 = S.sales
			S.impN = 0
	# partidas guardadas por chapter() antes de poner el plazo: capítulo 5 o 7 sin nada que pagar
	if (S.ch == 5 or S.ch == 7) and not (S.get("due", 0) > 0) and S.get("debt", 0) > 0:
		S.due = mini(int(D.PLAZOS["5"]), S.debt) if S.ch == 5 else S.debt
		S.deadline = maxi(S.get("deadline", 0) if S.get("deadline") else 0, S.day + (10 if S.ch == 5 else 7))
	if S.get("nave") != null and S.nave.get("r") == null:   # 1.35: los recibos, cada RECIBO.dias
		S.nave.r = S.day + D.RECIBO.dias
	if S.get("setas") != null and S.setas.get("r") == null:
		S.setas.r = S.day + D.RECIBO.dias
	if not S.has("clubReg") and S.has("clubDia"):   # 1.34: en los clubs donde ya vendías, el encargado y el presidente ya se fían de ti
		for k in D.PRESI:
			if S.clubDia.has(k) or (S.get("clubEnc") and S.clubEnc.k == k):
				for id in [k, "pres_" + k]:
					S.rel[id] = maxi(rel(id), int(D.CLUB.confia))
	if S.get("arcon"):   # 1.36 (lo pidió el usuario): sin el arcón; los cogollos, a la caja fuerte (o encima, sin ella) y los extractos, a la nevera
		var A: Dictionary = S.arcon
		var bu: Dictionary = A.get("buds", {}) if A.get("buds") else {}
		for k in bu.keys():
			mover_lote(bu, S.caja.buds if S.get("caja") else S.buds, k, bu[k].g)
		var ro: Dictionary = A.get("rosin", {}) if A.get("rosin") else {}
		for k in ro.keys():
			mover_rosin(ro, nevera().rosin, k, ro[k].g)
	S.erase("arcon")
	if S.get("caja") and S.caja.get("rosin"):
		for k in S.caja.rosin.keys():
			mover_rosin(S.caja.rosin, nevera().rosin, k, S.caja.rosin[k].g)
		S.caja.erase("rosin")
	var sin_mis: bool = not S.has("misiones")
	var sin_itin: bool = not S.has("itin")
	var sin_log: bool = not S.has("logros")
	var d := new_state()
	for k in d:
		if not S.has(k):
			S[k] = d[k]
	for k in d.items:
		if not S.items.has(k):
			S.items[k] = 0
	if sin_mis:   # 1.11: las de capítulos pasados, hechas y sin regalo
		for m in D.MISIONES:
			if m.ch < S.ch:
				S.misiones[m.id] = 0
	if S.ch > 6:   # 1.28: las de la Copa, en una partida que ya la ganó
		cerrar_copa()
	if sin_itin:   # 1.23: lo hecho, sin aviso
		for p in D.ITINERARIO:
			if itin_ok(p.id):
				S.itin[p.id] = 0
	# 1.10: el plazo del capítulo 3 corre desde Toño (las partidas sin él, desde hoy) y la protección de Molina dura 10 días desde hoy
	if S.ch == 3 and not S.flags.get("metB") and not (S.get("due", 0) > 0):
		S.due = int(D.PLAZOS["3"])
		S.deadline = S.day + 7
		S.flags.tono = S.day
	if S.flags.get("metB") and not S.flags.has("tono"):   # ya conoces a Toño: sale en el móvil (trama, llamar)
		S.flags.tono = S.day
	if S.get("protect") and not S.get("protHasta"):
		S.protHasta = S.day + int(D.CUOTA_DIAS)
	if not S.flags.has("diario"):   # 1.25: el diario sale bajo la almohada; las partidas de antes ya lo tenían
		S.flags.diario = 1
	if S.get("nave") != null and not S.nave.has("m"):   # 1.30: la nave de antes (una variedad para todos) pasa a 4 mesas con ella, ya dando, y lo que había, en la 1.ª
		var o: Dictionary = S.nave
		S.nave = nave_nueva()
		if o.get("sid"):
			for i in S.nave.m.size():
				S.nave.m[i] = {"k": o.sid, "thc": o.thc, "y": 1, "dia": int(S.day) - int(D.NAVE.crece), "g": Datos.jsround(o.g * 10) / 10.0 if i == 0 else 0, "t": o.thc, "abo": 0}
	if S.get("nave") != null and not S.nave.has("f"):   # 1.33: el equipo de la nave; la de antes, con los LED de serie y nada más
		var fs := []
		for i in int(D.NAVE.max):
			fs.append("led")
		S.nave.f = fs
		S.nave.ex = 0
		S.nave.rg = 0
	if S.get("nave") != null and not S.nave.has("ma"):   # 1.34: la carpa de las madres, vacía
		S.nave.ma = []
	for w in naveros():   # 1.31: cada trabajador de la nave, su mesa (w.mesa); los de antes, la que les tocaba por el orden de la plantilla
		if w.get("mesa") == null:
			for i in int(D.NAVE.max):
				if navero_de(i) == null:
					w.mesa = i
					break
	if S.get("envio") is Array:   # 1.31: el pH− de 250 ml ya no se vende; lo pedido a Kiko de antes llega como la botella de 1 L
		for i in S.envio.size():
			var l: String = S.envio[i]
			if l.begins_with("pH− ") and l.ends_with(" 250 ml"):
				S.envio[i] = l.trim_suffix(" 250 ml") + " 1 L"
	if not S.flags.has("vendDia"):   # 1.29.1: el dia de un vendedor era el de la entrega; ahora, el de la cosecha (los de antes no pierden)
		for v in S.curro.vend:
			v.erase("dia")
		S.flags.vendDia = 1
	for k in S.custom:   # 1.11: los cruces con nombre largo («A × B», de antes) pasan a uno corto, con la misma clave; 1.24: y
		# los que se llaman como una variedad nueva (Purple Thai × Haze, sin receta antes, se llamaba «Purple Haze»)
		var C: Dictionary = S.custom[k]
		if not C.n.contains(" × ") and C.n.length() <= Datos.NOM_MAX and not D.DEX.any(func(dx): return String(D.STRAINS[dx].n).to_lower() == String(C.n).to_lower()):
			continue
		var cp: PackedStringArray = C.n.split(" × ")
		var cw := Datos.palabras(C.n)
		var ch := ceili(cw.size() / 2.0)
		var wa: Array = Datos.palabras(cp[0]) if cp.size() > 1 else cw.slice(0, ch)
		var wb: Array = Datos.palabras(cp[-1]) if cp.size() > 1 else cw.slice(ch)
		C.n = Datos.nombre_cruce(wa, wb, func(nm: String) -> bool:
			for dx in D.DEX:
				if D.STRAINS[dx].n.to_lower() == nm.to_lower():
					return true
			for q in S.custom:
				if not is_same(S.custom[q], C) and S.custom[q].n.to_lower() == nm.to_lower():
					return true
			return false)
	var nh := huecos().size()
	while S.pots.size() < nh:
		S.pots.append(null)
	while S.macetas.size() < nh:
		S.macetas.append("plastico7")
	if sin_log:   # 1.27: lo conseguido, sin aviso (al final: con el diario de arriba)
		for l in D.LOGROS:
			if logro_ok(l.id):
				S.logros[l.id] = 0

# ---------- título y partida nueva ----------
func show_title() -> void:
	mode = "title"
	if not oraculo:
		titulo.show()
	update_hud()
	music("title")
	if not oraculo:
		run(_titulo_entra)

# 1.35: el aviso de edad (la primera vez) y, sin PULSA START, los botones del título; con B se cierran y A o START los abren
func _titulo_entra() -> void:
	if not aj.aviso:
		await aviso_edad()
		if not aj.aviso:
			return
	await _title_press()

# el aviso de contenido, una vez (se guarda en los ajustes): mayores de 18 o salir
func aviso_edad() -> void:
	await say("Landrace Hunters es un juego de ficción para mayores de 18 años.", "AVISO")
	var c: int = await ask("Trata del cultivo y la venta de cannabis, delito en muchos países. No anima a consumir ni a vender.", ["TENGO 18 O MÁS", "SALIR"], "AVISO")
	if c != 0:
		get_tree().quit()
		return
	aj.aviso = true
	ajustes_guarda()

func title_press(b):
	if (b != "A" and b != "START") or lock:
		return
	lock += 1
	await _title_press()
	lock -= 1

func _title_press() -> void:
	sfx("sel")
	var i := 0
	var ult := ""
	while true:
		var sv = load_save()
		var ops := (["CONTINUAR"] if sv else []) + ["NUEVA PARTIDA", "OPCIONES", "CRÉDITOS"]
		i = await menu(ops, {"cls": "titulo", "initial": maxi(0, ops.find(ult))})
		if i < 0:
			return
		ult = ops[i]
		if ops[i] == "OPCIONES":
			await opciones(true)
		elif ops[i] == "CRÉDITOS":
			await creditos()
		elif ops[i] == "CONTINUAR":
			S = sv
			migrate()
			await fade(1)
			if not oraculo:
				titulo.hide()
			enter_game()
			await fade(0)
			show_objective()
			return
		elif not sv or await ask("Hay una partida guardada. ¿Empezar de cero y sobrescribirla?", ["Sí", "No"]) == 0:
			await new_game()
			return

# importar la partida (1.22, importar de 12-menus): la exportada, pegada en la caja de texto (lo que haya en el portapapeles sale ya
# escrito); sustituye a la de ahora (migrate, como CONTINUAR) y se guarda; la cola de avisos de la otra partida se vacía. Desde el
# título no hay partida en marcha: se guarda tal cual y el título ofrece CONTINUAR
const IMPORTA_MAX := 2000000

func partida_valida(s) -> bool:
	return s is Dictionary and s.get("name") is String and (s.get("day") is int or s.get("day") is float) and (s.get("ch") is int or s.get("ch") is float) \
		and s.get("map") is String and MAPS.has(s.map) and s.get("pots") is Array and s.get("flags") is Dictionary

# lo pegado no trae <, >, " ni ` (como en el HTML, donde los nombres van a menús y avisos)
static func limpia_import(v):
	if v is String:
		return v.replace("<", "").replace(">", "").replace("\"", "").replace("`", "")
	if v is Array:
		var a := []
		for x in v:
			a.append(limpia_import(x))
		return a
	if v is Dictionary:
		var o := {}
		for k in v:
			o[limpia_import(k)] = limpia_import(v[k])
		return o
	return v

func importar(desde_titulo := false) -> void:
	var ini := DisplayServer.clipboard_get().strip_edges() if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD) else ""
	if ini.length() > IMPORTA_MAX:
		ini = ""
	var t = await pedir_texto("Pega aquí la partida exportada", ini, IMPORTA_MAX, false, true, true)
	if t == null:
		return
	var js := JSON.new()   # (JSON.parse_string avisa en la consola si no es JSON)
	var s = limpia_import(Datos.enteros(js.data)) if js.parse(t) == OK and js.data is Dictionary else null
	if not partida_valida(s):
		await say("Eso no es una partida exportada.")
		return
	var pierde := " La de ahora se pierde." if not desde_titulo else (" La guardada se pierde." if FileAccess.file_exists(GUARDADO) else "")
	if await ask("¿Cargar la partida de %s, día %s?%s" % [s.name, n(s.day), pierde], ["Cargar", "No"]) != 0:
		return
	if desde_titulo:
		var tmp := GUARDADO + ".tmp"   # como save(): a un .tmp y, entero, en su sitio
		var f := FileAccess.open(tmp, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(s, "", false, true))
			f.close()
		if f == null or DirAccess.rename_absolute(tmp, GUARDADO) != OK:
			await say("No se ha podido guardar la partida.")
			return
		sfx("coin")
		await say("Partida cargada.")
		return
	S = s
	pending.clear()
	queued.clear()
	migrate()
	enter_game()
	var ok = save()
	sfx("coin")
	await say("Partida cargada." if ok else "Partida cargada, pero no se ha podido guardar.")

# OPCIONES (en el título y en el menú START): A cambia cada fila; se guardan al momento
func opciones(desde_titulo := false) -> void:
	var i := 0
	while true:
		var it := [{"label": "MÚSICA", "right": "%d %%" % (aj.musica * 25)}, {"label": "EFECTOS", "right": "%d %%" % (aj.efectos * 25)},
			{"label": "TEXTO", "right": TEXTO_VEL[aj.texto]}, {"label": "SONIDO", "right": "SÍ" if aj.sonido else "NO"}]
		if not desde_titulo:
			it.append({"label": "EXPORTAR PARTIDA"})
		it.append({"label": "IMPORTAR PARTIDA"})
		if desde_titulo and FileAccess.file_exists(GUARDADO):
			it.append({"label": "BORRAR PARTIDA"})
		it.append({"label": "VOLVER"})
		i = await menu(it, {"cls": "start", "initial": i, "title": "OPCIONES"})
		if i < 0 or it[i].label == "VOLVER":
			return
		if it[i].label == "EXPORTAR PARTIDA":
			await exportar()
			continue
		if it[i].label == "IMPORTAR PARTIDA":
			await importar(desde_titulo)
			continue
		match it[i].label:
			"MÚSICA":
				aj.musica = (aj.musica + 1) % 5
			"EFECTOS":
				aj.efectos = (aj.efectos + 1) % 5
			"TEXTO":
				aj.texto = (aj.texto + 1) % 3
			"SONIDO":
				aj.sonido = not aj.sonido
			"BORRAR PARTIDA":
				if await ask("¿Borrar la partida guardada? No se puede deshacer.", ["Sí, borrarla", "No"]) == 0:
					DirAccess.remove_absolute(ProjectSettings.globalize_path(GUARDADO))
					await say("Partida borrada.")
					i = 0
		ajustes_aplica()
		ajustes_guarda()
		if it[i].label == "EFECTOS":
			sfx("coin")   # para oír el volumen nuevo

var VERSION: String = ProjectSettings.get_setting("application/config/version", "")
const CREDITOS := """LANDRACE HUNTERS · genética de barrio
Versión %s para Android

Un juego de Eddie.
Hecho con Godot Engine y con la ayuda de Claude Code (Anthropic).

ARTE
Personajes, escenarios y objetos: PixelLab (pixellab.ai), revisados y retocados a mano. Carpas por dentro, plantas, equipo, muebles, iconos y el icono de la app: dibujados a mano, píxel a píxel.

MÚSICA Y SONIDO
Chiptune original, sintetizado en el propio juego.

FUENTES
Press Start 2P · Copyright 2012 The Press Start 2P Project Authors. SIL Open Font License 1.1.
Atkinson Hyperlegible · Copyright 2020 Braille Institute of America, Inc. SIL Open Font License 1.1.

FICCIÓN
Ribera Verde, Mendialde, Puerto Viejo, Valdehierro, Errotabarri y sus personajes son inventados: cualquier parecido con personas o lugares reales es casualidad. Las variedades llevan el nombre de genéticas conocidas y su historia es solo información.
El cultivo y la venta de cannabis son delito en muchos países. Este juego no anima a consumir ni a vender.

Gracias por jugar."""
const PRIVACIDAD := """Landrace Hunters no recoge, no envía y no comparte ningún dato.

· No tiene cuentas, anuncios ni compras.
· No usa internet ni pide permisos.
· La partida y los ajustes se guardan solo en este móvil, en la carpeta privada de la app. Se borran al desinstalarla (o desde OPCIONES · BORRAR PARTIDA).
· Tampoco se copian en la copia de seguridad de Google.

Si tienes dudas, escribe a la dirección de contacto de la ficha de la tienda."""

# CRÉDITOS (en el título): los créditos, las licencias (Godot y las fuentes, enteras, como piden) y la privacidad
func creditos() -> void:
	var i := 0
	while true:
		i = await menu(["CRÉDITOS", "LICENCIAS", "PRIVACIDAD", "VOLVER"], {"cls": "start", "initial": i, "title": "CRÉDITOS"})
		if i < 0 or i == 3:
			return
		if i == 0:
			await leer("CRÉDITOS", CREDITOS % VERSION)
		elif i == 1:
			await leer("LICENCIAS", licencias())
		else:
			await leer("PRIVACIDAD", PRIVACIDAD)

func licencias() -> String:
	var t := "Este juego usa Godot Engine, con licencia MIT:\n\n" + Engine.get_license_text()
	for f in ["OFL-PressStart2P.txt", "OFL-AtkinsonHyperlegible.txt"]:
		t += "\n\n— %s —\n\n%s" % [f.trim_prefix("OFL-").trim_suffix(".txt"), FileAccess.get_file_as_string("res://fuentes/" + f).strip_edges()]
	t += "\n\nGODOT ENGINE: PARTES DE TERCEROS"
	for c in Engine.get_copyright_info():
		t += "\n\n" + str(c.name)
		for p in c.parts:
			for cp in p.copyright:
				t += "\n© " + str(cp)
			t += "\nLicencia: " + str(p.license)
	var li := Engine.get_license_info()
	for k in li:
		t += "\n\n— %s —\n\n%s" % [k, str(li[k]).strip_edges()]
	return t

func choose_name() -> String:
	var opts := ["EDDIE", "ÁLEX", "LUR", "ANDER", "Otro..."]
	var i: int = await menu(opts, {"cls": "start", "cancel": false, "title": "NOMBRE"})
	if i < 4:
		return opts[i]
	var v: String = str(await pedir_texto("¿Cómo te llamas?", "", 8, true, false)).to_upper().substr(0, 8)
	return v if v != "" else "EDDIE"

func new_game() -> void:
	# prólogo (1.10): en el caserío de la familia, en Mendialde; el piso de la tía, en Ribera Verde, está a un autobús
	S = new_state()
	S.map = "casa-ama"
	S.x = 2
	S.y = 4
	S.dir = "down"
	S.flags.llegada = false
	await fade(1)
	if not oraculo:
		titulo.hide()
	mode = "intro"
	music("home")
	await fade(0)
	await talk("???", ["¿Diga? ¿Eres familia de Maite, la de Ribera Verde? Un barrio obrero a orillas de la ría.", "Me llamo Kiko. Llevo treinta años con el growshop de su calle."])
	await talk("KIKO", ["Conservo genéticas: variedades locales de Afganistán, México o la India, y los cruces que salen de ellas.",
		"Las apunto todas en un registro, una GENOTECA. Tu tía Maite me ayudaba a mantenerla.", "Perdona. ¿Cómo te llamabas?"])
	S.name = await choose_name()
	await talk("KIKO", ["{N}. Hacía años que no te veía por el barrio.", "Maite murió hace tres semanas. Te ha dejado su piso, su armario de cultivo... y una deuda.",
		"Coge el autobús en la plaza del pueblo: te deja enfrente del piso. La llave está en el buzón.", "Lee la carta que te dejó. Después pásate por el growshop."])
	await fade(1)
	enter_game()
	await wait(300)
	await fade(0)
	await chapter(1)
	await wait(2600)
	show_objective()

func enter_game() -> void:
	mode = "world"
	enter_map(S.map, S.x, S.y, S.dir)
	if tile_solid(MAPS[S.map], P.x, P.y):   # partidas viejas: la casilla puede ser ahora una carpa
		if S.map == "home":
			enter_map(S.map, 2, 4, "down")
		else:
			enter_map(S.map, 5, 9, "down")
	if S.clientsDay != S.day:
		spawn_clients()
	# 1.13: lo que se quedó en la cola al guardar (la cama guarda antes de que salgan los avisos de la noche)
	if S.get("orden") and S.day > S.orden:
		queue("raid", raid_event)
	elif S.get("orden") and S.orden == S.day:
		queue("orden", aviso_orden)
	if S.due > 0 and S.day > S.deadline:
		queue("penalty", penalty_event)
	update_hud()

# ---------- bucle ----------
func update(dt: float) -> void:
	if oraculo:   # la prueba de la historia: el reloj del juego y los paseos quietos, solo los eventos pendientes
		if mode == "world" and S and is_free() and pending.size() and not P.moving:
			run(pending.pop_front())
		return
	if mode == "world" and S:
		update_player(dt)
		update_ents(dt)
		if is_free():
			update_patrullas(dt)
		if is_free():
			time_acc += dt
			while time_acc >= D.MS_PER_MIN:
				time_acc -= D.MS_PER_MIN
				tick_minute()
			if pending.size() and not P.moving:
				run(pending.pop_front())
		hud_t -= dt
		if hud_t <= 0 or sosp_hud() != hud_visto:   # la barra de sospecha, en el fotograma en que cambia
			hud_t = 250
			update_hud()
	elif mode == "battle" and B:
		B.t += dt
		if B.flashE > 0:
			B.flashE -= dt
		if B.shakeP > 0:
			B.shakeP -= dt

func update_hud() -> void:
	if oraculo:
		return
	if mode != "world" or S == null:
		hud.hide()
		return
	var hh := "%02d" % int(floor(S.min / 60.0))
	var mm := "%02d" % (int(floor(int(S.min) % 60 / 10.0)) * 10)
	hud_visto = sosp_hud()
	var r := total_rosin()
	var ro := (" · " + Datos.coma(Datos.jsround(r * 10) / 10.0) + " g rosin") if r else ""
	hud_pon("DÍA %s · %s:%s\n%s · %d g%s" % [n(S.day), hh, mm, Datos.eur(S.money), int(floor(total_buds())), ro], Datos.jsround(S.heat),
		Datos.jsround(SOSP.v) if n_patrullas() else -1, SOSP.alarma != null, float(S.get("orden", 0)) > 0)
