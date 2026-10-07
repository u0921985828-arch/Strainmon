# Ribera Verde (Godot) — 15-arranque y el bucle: guardar y cargar (con migrate de las partidas viejas), el título, el nombre,
# la partida nueva, entrar en el juego, update (el jugador, los personajes, el reloj del juego y los eventos pendientes) y
# el HUD. El dibujo de cada modo (mundo, carpa, combate, título) lo hace pinta.gd en el lienzo de SW × 160.
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
		# Atrás: B con un diálogo o un menú abierto; si no, guarda y sale
		if handlers.size():
			press("B")
		elif mode == "carpa" or mode == "world":
			if is_free() or mode == "carpa":
				save()
			get_tree().quit()
		else:
			get_tree().quit()
	elif w == NOTIFICATION_APPLICATION_PAUSED or w == NOTIFICATION_WM_CLOSE_REQUEST:
		suelta_todo()
		if S and (mode == "world" or mode == "carpa" or mode == "battle"):
			save()
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
	var d := new_state()
	for k in d:
		if not S.has(k):
			S[k] = d[k]
	for k in d.items:
		if not S.items.has(k):
			S.items[k] = 0
	var nh := huecos().size()
	while S.pots.size() < nh:
		S.pots.append(null)
	while S.macetas.size() < nh:
		S.macetas.append("plastico7")

# ---------- título y partida nueva ----------
func show_title() -> void:
	mode = "title"
	if not oraculo:
		titulo.show()
	update_hud()
	music("title")

func title_press(b):
	if (b != "A" and b != "START") or lock:
		return
	lock += 1
	await _title_press()
	lock -= 1

func _title_press() -> void:
	sfx("sel")
	var sv = load_save()
	var c := 1
	if sv:
		c = await menu(["CONTINUAR", "NUEVA PARTIDA"], {"cls": "start"})
		if c < 0:
			return
	if c == 0:
		S = sv
		migrate()
		await fade(1)
		if not oraculo:
			titulo.hide()
		enter_game()
		await fade(0)
		show_objective()
		return
	if sv and await ask("Hay una partida guardada. ¿Empezar de cero y sobrescribirla?", ["Sí", "No"]) != 0:
		return
	await new_game()

func choose_name() -> String:
	var opts := ["EDDIE", "ÁLEX", "LUR", "ANDER", "Otro..."]
	var i: int = await menu(opts, {"cls": "start", "cancel": false, "title": "NOMBRE"})
	if i < 4:
		return opts[i]
	var pr := Motor.Prom.new()
	name_in.text = ""
	name_box.show()
	_coloca()
	name_in.grab_focus.call_deferred()
	push(func(b: String):
		if b == "A":
			var v := name_in.text.strip_edges().to_upper().substr(0, 8)
			name_box.hide()
			name_in.release_focus()
			pop()
			pr.res(v if v != "" else "EDDIE"))
	return await Motor.espera(pr)

func new_game() -> void:
	S = new_state()
	await fade(1)
	if not oraculo:
		titulo.hide()
	mode = "intro"
	music("home")
	await fade(0)
	await talk("???", ["Ribera Verde. Un barrio obrero a orillas de la ría.", "Me llamo Kiko. Llevo treinta años con el growshop de la esquina."])
	await talk("KIKO", ["Conservo genéticas: variedades locales de Afganistán, México o la India, y los cruces que salen de ellas.",
		"Las apunto todas en un registro, una GENOTECA. Tu tía Maite me ayudaba a mantenerla.", "Perdona. ¿Cómo te llamabas?"])
	S.name = await choose_name()
	await talk("KIKO", ["{N}. Hacía años que no te veía por el barrio.", "Maite murió hace tres semanas. Te ha dejado su piso, su armario de cultivo... y una deuda.",
		"Lee la carta que te dejó. Después pásate por el growshop."])
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
			time_acc += dt
			while time_acc >= D.MS_PER_MIN:
				time_acc -= D.MS_PER_MIN
				tick_minute()
			if pending.size() and not P.moving:
				run(pending.pop_front())
		hud_t -= dt
		if hud_t <= 0:
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
	hud_pon("DÍA %s · %s:%s\n%s · %d g" % [n(S.day), hh, mm, Datos.eur(S.money), int(floor(total_buds()))], Datos.jsround(S.heat))
