# Ribera Verde (Godot) — 15-arranque y el bucle: guardar y cargar (con migrate de las partidas viejas), el título, el nombre,
# la partida nueva, entrar en el juego, update (el jugador, los personajes, el reloj del juego y los eventos pendientes) y
# el HUD. El dibujo de cada modo (mundo, carpa, combate, título) lo hace pinta.gd en el lienzo de SW × SH (180).
# Cadena: ui → mundo → granja → trama → retencion → juego (este es el script de la escena).
extends "res://src/retencion.gd"

const Pinta = preload("res://src/pinta.gd")
const Arte = preload("res://src/arte.gd")

static var GUARDADO := "user://partida.json"   # las pruebas usan otro
static var FTUE_CORTO := true   # U1 (fase 5): con Datos.PLAY, la partida empieza en el piso; tests/ciclo.gd lo apaga para recorrer el prólogo
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
	if Datos.PLAY:   # fase 6: los informes (si los aceptó) y las compras ya hechas
		plat().errores(aj.get("errores", false))
		plat().consultar()
	if OS.get_cmdline_user_args().has("--sin-arranque"):
		return
	if Datos.CAL and not OS.get_cmdline_user_args().has("--sin-carga"):
		_arranca.call_deferred()   # las pruebas que ponen oraculo al añadir el juego, al título de antes
	else:
		show_title()

func _arranca() -> void:
	if oraculo:
		show_title()
	else:
		run(arranque)

# (lo pidió el usuario: «estos recursos se podrían usar antes de la pantalla de inicio, como de carga del juego, en una carretera
# sin texto, los vehículos andando y la barra cargándose; luego aparece la pantalla de inicio»): la carretera con los vehículos y la barra
# (EscViaje.pinta_carga) durante CARGA ms, sin botones; A, B o START la pasan; después, el título
var carga_t0 := 0.0
func arranque() -> void:
	mode = "carga"
	carga_t0 = M.reloj
	hud.hide()
	titulo.hide()
	var vis := {}
	for k in botones:
		vis[k] = botones[k].visible
		botones[k].visible = false
	music("title")
	var st := {"ok": false}
	var prom := Motor.Prom.new()
	var cierra := func():
		if not st.ok:
			st.ok = true
			prom.res(0)
	push(func(b):
		if b == "A" or b == "B" or b == "START":
			cierra.call())
	M.timeout(cierra, 500.0 if Datos.PLAY else EscViaje.CARGA)   # U1 (fase 5): sin la carga falsa de 3,6 s
	await Motor.espera(prom)
	pop()
	if mode != "carga":   # otra cosa la cambió (las pruebas)
		for k in vis:
			botones[k].visible = vis[k]
		return
	await fade(1)
	for k in vis:
		botones[k].visible = vis[k]
	show_title()
	await fade(0)

var pausa_foco := false
var zona_vista := Rect2i()
var mudo_antes := false
func _process(dt: float) -> void:
	if oraculo or pausa_foco:
		return
	# R12: un giro de 180° no cambia el tamaño de la ventana, pero sí el lado de la muesca: se mira la zona segura cada segundo
	if OS.has_feature("mobile") and Engine.get_process_frames() % 60 == 0:
		var zs := DisplayServer.get_display_safe_area()
		if zs != zona_vista:
			zona_vista = zs
			ajusta()
	var ms := dt * 1000
	M.avanza(M.reloj + ms)
	update(minf(50, ms))
	# R2: con un menú, el lector o la caja de importar encima del mapa o de la carpa (el reloj parado, nada se mueve detrás), o con
	# la pantalla en negro, el lienzo no se repinta ni se vuelve a componer: se queda el último fotograma (uno más tras taparse,
	# por si el guion cambió algo justo antes de abrir el menú)
	if lienzo_quieto():
		quieto_n += 1
	else:
		quieto_n = 0
	if quieto_n < 2:
		pintor.redibuja(M.reloj)
	vision_borracho()
	var upd := SubViewport.UPDATE_DISABLED if quieto_n >= 3 else SubViewport.UPDATE_ALWAYS
	if sv.render_target_update_mode != upd:
		sv.render_target_update_mode = upd
	_process_ui()

# MAESTRO [2]: de FISIO.vision de borrachera para arriba, la pantalla en triple con los colores separados (aberración); más
# fuerte cuanto más cerca de FISIO.tope. Sin borrachera, sin material (la pantalla de siempre)
const VISION_SH := preload("res://src/vision.gdshader")
var vision_mat: ShaderMaterial = null
func vision_k() -> float:
	var b := borr()
	if mode != "world" or b <= float(D.FISIO.vision):
		return 0.0
	return clampf((b - float(D.FISIO.vision)) / (float(D.FISIO.tope) - float(D.FISIO.vision)), 0.15, 1.0)

func vision_borracho() -> void:
	var k := vision_k()
	if k <= 0:
		if pantalla.material:
			pantalla.material = null
		return
	if vision_mat == null:
		vision_mat = ShaderMaterial.new()
		vision_mat.shader = VISION_SH
	if pantalla.material != vision_mat:
		pantalla.material = vision_mat
	vision_mat.set_shader_parameter("k", k)
	vision_mat.set_shader_parameter("t", M.reloj / 1000.0)

var quieto_n := 0
func lienzo_quieto() -> bool:
	if fade_el.color.a >= 1.0 and not fade_tw_vivo():
		return true
	if mode != "world" and mode != "carpa":
		return false
	if not (menu_box.visible or lector.visible or import_box.visible):
		return false
	for v in [ACCESO_V, VIAJE_V, TIRO, MESA_B, ORDEN, ALMACEN, CARRO_V, SETAS_V, ARM_V, CAL_V, MAPA_V, FICHA_V, MOVIL_V]:
		if v != null:
			return false
	return wipe_t0 < 0 and not P.moving

func fade_tw_vivo() -> bool:
	return fade_tw != null and fade_tw.is_valid() and fade_tw.is_running()

func _notification(w: int) -> void:
	if oraculo:
		return
	if w == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Atrás: B con un diálogo, un menú o la carpa abiertos; andando por el mapa, la pausa (el menú START, con el reloj
		# parado); en el título, sale
		if handlers.size():
			press("B")
		elif mode == "world":
			press("START")   # i18n-no
		elif mode == "title" and lock == 0:
			get_tree().quit()
	elif w == NOTIFICATION_APPLICATION_PAUSED or w == NOTIFICATION_WM_CLOSE_REQUEST:
		suelta_todo()
		guarda_al_salir()
		al_pausar()   # fase 6: el aviso de la cosecha y la nube
	elif w == NOTIFICATION_APPLICATION_RESUMED:
		ajusta.call_deferred()   # R12: la muesca puede haber cambiado de lado mientras no se veía
		al_volver()   # fase 6: lo que han crecido las plantas
		# al volver a la app, andando por el mapa, en pausa: el menú START
		if mode == "world" and is_free() and not P.moving:
			press("START")   # i18n-no
	elif w == NOTIFICATION_APPLICATION_FOCUS_OUT:
		suelta_todo()
		if OS.has_feature("mobile") and not pausa_foco:   # R13: con la persiana bajada o en multiventana, quieto y en silencio
			pausa_foco = true
			mudo_antes = AudioServer.is_bus_mute(0)
			AudioServer.set_bus_mute(0, true)
	elif w == NOTIFICATION_APPLICATION_FOCUS_IN:
		if pausa_foco:
			pausa_foco = false
			AudioServer.set_bus_mute(0, mudo_antes)

# ---------- guardado (a un archivo aparte y luego se cambia de nombre; sin ordenar las claves y con todos los decimales) ----------
# E4 y E6 (fase 3): al salir de la app solo se guarda sin un guion a medias (lock) y fuera del combate: si no, se queda la última
# partida guardada (la de antes del guion; la pausa con START guarda antes de abrir el menú)
func guarda_al_salir() -> bool:
	if S == null or lock > 0 or not (mode == "world" or mode == "carpa"):
		return false
	return save()

# E1 (fase 3): el .tmp se relee entero antes de ponerlo en su sitio (con el disco lleno sale cortado y la partida buena se queda) y
# la anterior pasa a partida.json.bak. E7: los avisos en cola van con la partida (cola_guardar), no en S
func save():
	if S == null:
		return false
	S.x = P.x
	S.y = P.y
	S.dir = P.dir
	if Datos.PLAY and not oraculo:   # fase 6: la hora del móvil al guardar, para el progreso offline
		S.ts = ahora()
	var o: Dictionary = S
	var cola := cola_guardar()
	if cola.size():
		o = S.duplicate()
		o["_cola"] = cola
	return escribe_partida(JSON.stringify(o, "", false, true))

static func escribe_partida(t: String) -> bool:
	var tmp := GUARDADO + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(t)
	var err := f.get_error()
	f.close()
	if err != OK or FileAccess.get_file_as_string(tmp) != t:
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(GUARDADO):
		DirAccess.remove_absolute(GUARDADO + ".bak")
		if DirAccess.rename_absolute(GUARDADO, GUARDADO + ".bak") != OK:
			return false
	return DirAccess.rename_absolute(tmp, GUARDADO) == OK

# E2: solo una partida válida (partida_valida); si no, la .bak
func load_save():
	for r in [GUARDADO, GUARDADO + ".bak"]:
		if not FileAccess.file_exists(r):
			continue
		var js := JSON.new()   # (JSON.parse_string avisa en la consola si no es JSON)
		if js.parse(FileAccess.get_file_as_string(r)) != OK or not js.data is Dictionary:
			continue
		var j = Datos.enteros(js.data)
		if partida_valida(j):
			return j
	return null

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
	# El plazo del capítulo 3 corre desde Toño (las partidas sin él, desde hoy) y la protección de Molina dura 10 días desde hoy
	if S.ch == 3 and not S.flags.get("metB") and not (S.get("due", 0) > 0):
		S.due = int(D.PLAZOS["3"])
		S.deadline = S.day + dias_plazo(3)
		if Datos.PLAY:
			S.due0 = S.due
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

# El aviso de edad (la primera vez) y, sin PULSA START, los botones del título; con B se cierran y A o START los abren
func _titulo_entra() -> void:
	if not aj.aviso:
		await aviso_edad()
		if not aj.aviso:
			return
	await _title_press()

# el aviso de contenido, una vez (se guarda en los ajustes): mayores de 18 o salir
func aviso_edad() -> void:
	await say(K("Landrace Hunters es un juego de ficción para mayores de 18 años."), K("AVISO"))
	var c: int = await ask(K("Ficción. No es una guía de cultivo. Trata del cannabis, que es delito en muchos países.") if Datos.PLAY else K("Trata del cultivo y la venta de cannabis, delito en muchos países. No anima a consumir ni a vender."), [K("TENGO 18 O MÁS"), K("SALIR")], K("AVISO"))
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
		var ops := ([K("CONTINUAR")] if sv else []) + [K("NUEVA PARTIDA"), K("OPCIONES"), K("CRÉDITOS")]
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
			var ts := float(S.get("ts", 0))
			await fade(1)
			if not oraculo:
				titulo.hide()
			enter_game()
			fuera_desde(ts)   # fase 6
			await fade(0)
			show_objective()
			return
		elif not sv or await ask(K("Hay una partida guardada. ¿Empezar de cero y sobrescribirla?"), [K("Sí"), K("No")]) == 0:
			await new_game()
			return

# importar la partida (1.22, importar de 12-menus): la exportada, pegada en la caja de texto (lo que haya en el portapapeles sale ya
# escrito); sustituye a la de ahora (migrate, como CONTINUAR) y se guarda; la cola de avisos de la otra partida se vacía. Desde el
# título no hay partida en marcha: se guarda tal cual y el título ofrece CONTINUAR

# E8 (fase 3): cada clave de new_state() con su tipo (los números, finitos; la hora, el día y el capítulo, enteros y en su rango)
const VAL_ENTEROS := {"day": [1, 1e9], "min": [0, 1439], "ch": [0, 8]}
func partida_valida(s) -> bool:
	if not (s is Dictionary and s.get("name") is String and s.get("map") is String and MAPS.has(s.map) and s.get("pots") is Array and s.get("flags") is Dictionary):
		return false
	for k in VAL_ENTEROS:
		var v = s.get(k)
		if not (v is int or v is float) or not is_finite(float(v)) or float(v) != floorf(float(v)) or float(v) < VAL_ENTEROS[k][0] or float(v) > VAL_ENTEROS[k][1]:
			return false
	var base := new_state()
	for k in base:
		if not s.has(k) or base[k] == null or s[k] == null:
			continue
		var a = base[k]
		var v = s[k]
		if a is int or a is float:
			if not (v is int or v is float) or not is_finite(float(v)):
				return false
		elif typeof(a) != typeof(v) and not (a is bool and (v is int or v is float)):
			return false
	return true

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

# E9 (fase 3): sin leer el portapapeles al abrir (PEGAR en la caja). E10: en partida, no cambia S con los menús abiertos: se guarda
# y, al cerrarse todo (run, lock 0), se carga como CONTINUAR (relanza)
var relanza := false

func importar(desde_titulo := false, nube = null) -> void:
	var t = nube if nube != null else await pedir_partida(I18n.v("Pega aquí la partida exportada"))   # fase 6: o la de la nube
	if t == null or t == "":
		if nube != null:
			await say(K("No hay ninguna partida en la nube."))
		return
	var js := JSON.new()   # (JSON.parse_string avisa en la consola si no es JSON)
	var s = limpia_import(Datos.enteros(js.data)) if js.parse(t) == OK and js.data is Dictionary else null
	if not partida_valida(s):
		await say(K("Eso no es una partida exportada."))
		return
	var A := {"n": s.name, "f": Datos.fd(int(s.day))}
	var preg: String = T("¿Cargar la partida de {n}, {f}? La de ahora se pierde.", A) if not desde_titulo else (T("¿Cargar la partida de {n}, {f}? La guardada se pierde.", A) if FileAccess.file_exists(GUARDADO) else T("¿Cargar la partida de {n}, {f}?", A))
	if await ask(preg, [K("Cargar"), K("No")]) != 0:
		return
	if desde_titulo:
		if not escribe_partida(JSON.stringify(s, "", false, true)):   # como save()
			await say(K("No se ha podido guardar la partida."))
			return
		sfx("coin")
		await say(K("Partida cargada."))
		return
	if not Datos.CAL:   # contra el HTML congelado (historia.gd): en caliente, como en la 1.22
		S = s
		pending.clear()
		queued.clear()
		migrate()
		enter_game()
		var ok = save()
		sfx("coin")
		await say(K("Partida cargada.") if ok else K("Partida cargada, pero no se ha podido guardar."))
		return
	if not escribe_partida(JSON.stringify(s, "", false, true)):
		await say(K("No se ha podido guardar la partida."))
		return
	sfx("coin")
	relanza = true
	await say(K("Partida cargada. Se abre al cerrar el menú."))

func relanzar() -> void:
	relanza = false
	var sv = load_save()
	if sv == null:
		return
	S = sv
	pending.clear()
	queued.clear()
	migrate()
	enter_game()

# (lo pidió el usuario: exportar e importar, más escondidos): al final de OPCIONES, en su submenú y con su aviso
func copia_seguridad(desde_titulo: bool) -> void:
	var it := []
	if not desde_titulo:
		it.append({"label": K("EXPORTAR PARTIDA")})
	it.append({"label": K("IMPORTAR PARTIDA")})
	if Datos.PLAY and plat().hay():   # fase 6: Play Games (se sube sola al salir de la app)
		it.append({"label": K("CARGAR DE LA NUBE")})
	it.append({"label": K("VOLVER")})
	var i: int = await menu(it, {"cls": "start", "title": K("COPIA DE SEGURIDAD")})
	if i < 0 or it[i].label == "VOLVER":
		return
	if it[i].label == "EXPORTAR PARTIDA":
		await exportar()
	elif it[i].label == "CARGAR DE LA NUBE":
		await importar(desde_titulo, await plat().nube_carga())
	else:
		await importar(desde_titulo)

# OPCIONES (en el título y en el menú START): A cambia cada fila; se guardan al momento
var IDIOMA_NOM := [I18n.K("SISTEMA"), I18n.K("ESPAÑOL"), I18n.K("ENGLISH")]

func opciones(desde_titulo := false) -> void:
	var i := 0
	while true:
		var it := [{"label": K("MÚSICA"), "right": "%d %%" % (aj.musica * 25)}, {"label": K("EFECTOS"), "right": "%d %%" % (aj.efectos * 25)},
			{"label": K("TEXTO"), "right": TEXTO_VEL[aj.texto]}, {"label": K("SONIDO"), "right": K("SÍ") if aj.sonido else K("NO")}]
		if not Datos.CAL:   # 1.43.4: las pruebas contra el HTML, como antes
			if not desde_titulo:
				it.append({"label": K("EXPORTAR PARTIDA")})
			it.append({"label": K("IMPORTAR PARTIDA")})
		if desde_titulo and FileAccess.file_exists(GUARDADO):
			it.append({"label": K("BORRAR PARTIDA")})
		if Datos.CAL:
			it.insert(4, {"label": K("VIBRACIÓN"), "right": K("SÍ") if aj.vibra else K("NO")})   # 1.57
			it.insert(5, {"label": K("AHORRO"), "right": K("30 FPS") if aj.ahorro else K("NO")})   # R3
			it.append({"label": K("COPIA DE SEGURIDAD")})
		if Datos.PLAY:   # U5: accesibilidad
			var c := it.size() - (1 if Datos.CAL else 0)
			it.insert(c, {"label": K("TAMAÑO DE TEXTO"), "right": TAM_NOM[clampi(int(aj.get("tam", 1)), 0, 2)]})
			it.insert(c + 1, {"label": K("ZURDO"), "right": K("SÍ") if aj.get("zurdo") else K("NO")})
			it.insert(c + 2, {"label": K("DALTÓNICO"), "right": K("SÍ") if aj.get("dalt") else K("NO")})
			it.insert(c + 3, {"label": K("SIN DESTELLOS"), "right": K("SÍ") if aj.get("calma") else K("NO")})
			it.insert(c + 4, {"label": K("AVISO DE COSECHA"), "right": K("SÍ") if aj.get("avisos") else K("NO")})   # fase 6
			it.insert(c + 5, {"label": K("INFORMES DE ERRORES"), "right": K("SÍ") if aj.get("errores") else K("NO")})
			it.insert(c + 6, {"label": K("IDIOMA"), "right": IDIOMA_NOM[clampi(int(aj.get("idioma", 0)), 0, 2)]})   # F7
		it.append({"label": K("VOLVER")})
		i = await menu(it, {"cls": "start", "initial": i, "title": K("OPCIONES")})
		if i < 0 or it[i].label == "VOLVER":
			return
		if it[i].label == "COPIA DE SEGURIDAD":
			await copia_seguridad(desde_titulo)
			if relanza:
				return
			continue
		if it[i].label == "EXPORTAR PARTIDA":
			await exportar()
			continue
		if it[i].label == "IMPORTAR PARTIDA":
			await importar(desde_titulo)
			if relanza:
				return
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
			"VIBRACIÓN":
				aj.vibra = not aj.vibra
				vibra()
			"AHORRO":
				aj.ahorro = not aj.ahorro
			"TAMAÑO DE TEXTO":
				aj.tam = (int(aj.get("tam", 1)) + 1) % 3
			"ZURDO":
				aj.zurdo = not aj.get("zurdo", false)
			"DALTÓNICO":
				aj.dalt = not aj.get("dalt", false)
			"SIN DESTELLOS":
				aj.calma = not aj.get("calma", false)
			"AVISO DE COSECHA":   # fase 6: el permiso de Android 13 solo al activarlo
				aj.avisos = not aj.get("avisos", false)
				if aj.avisos and not await plat().permiso_avisos():
					aj.avisos = false
					await say(K("Sin permiso para avisar. Se puede dar en los ajustes del móvil."))
				elif aj.avisos:
					await say(K("Te avisaremos cuando una planta esté lista para cosechar (con la app cerrada)."))
			"IDIOMA":   # F7: el del sistema, castellano o inglés
				aj.idioma = (clampi(int(aj.get("idioma", 0)), 0, 2) + 1) % 3
			"INFORMES DE ERRORES":   # fase 6 (U10): opt-in
				if not aj.get("errores", false):
					aj.errores = await ask(K("Si el juego falla, ¿enviar un informe técnico anónimo (modelo del móvil, versión de Android y del juego, y dónde falló) para arreglarlo? Sin datos personales ni de la partida. Se puede quitar cuando quieras."), [K("Sí, enviar"), K("No")]) == 0
				else:
					aj.errores = false
				plat().errores(aj.errores)
			"BORRAR PARTIDA":
				if await ask(K("¿Borrar la partida guardada? No se puede deshacer."), [K("Sí, borrarla"), K("No")]) == 0:
					DirAccess.remove_absolute(ProjectSettings.globalize_path(GUARDADO))
					await say(K("Partida borrada."))
					i = 0
		ajustes_aplica()
		ajustes_guarda()
		if it[i].label == "EFECTOS":
			sfx("coin")   # para oír el volumen nuevo

var VERSION: String = ProjectSettings.get_setting("application/config/version", "")
var CREDITOS: String = I18n.K("""LANDRACE HUNTERS · genética de barrio
Versión {v} para Android

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

Gracias por jugar.""")
var PRIVACIDAD: String = I18n.K("""Landrace Hunters no vende, no alquila y no usa tus datos para anuncios.

· Se juega sin conexión y sin anuncios. Los capítulos 1 a 3 son gratis; el juego completo es una compra única por Google Play: la tarjeta y el pago los gestiona Google, nosotros solo sabemos que está comprado.
· Play Games (si inicias sesión): los logros y la partida en la nube se guardan en tu cuenta de Google Play Juegos.
· Informes de errores (OPCIONES · INFORMES DE ERRORES, apagados de serie): si los activas y el juego falla, se envía un informe técnico anónimo (modelo del móvil, versión de Android y del juego, y lo que fallaba), sin tu nombre, cuenta ni partida. Se apagan en el mismo sitio.
· Aviso de cosecha (OPCIONES · AVISO DE COSECHA, apagado de serie): el móvil te avisa cuando tus plantas están listas. Pide el permiso de notificaciones solo si lo activas; el aviso se programa en el propio móvil.
· La partida y los ajustes se guardan en este móvil, en la carpeta privada de la app. Se borran al desinstalarla (o desde OPCIONES · BORRAR PARTIDA).
· Si tienes activada la copia de seguridad de Android, el sistema la guarda en tu cuenta de Google (no pasa por nosotros).

Si tienes dudas, escribe a la dirección de contacto de la ficha de la tienda.""")

# CRÉDITOS (en el título): los créditos, las licencias (Godot y las fuentes, enteras, como piden) y la privacidad
func creditos() -> void:
	var i := 0
	while true:
		i = await menu([K("CRÉDITOS"), K("LICENCIAS"), K("PRIVACIDAD"), K("VOLVER")], {"cls": "start", "initial": i, "title": K("CRÉDITOS")})
		if i < 0 or i == 3:
			return
		if i == 0:
			await leer(K("CRÉDITOS"), T(CREDITOS, {"v": VERSION}))
		elif i == 1:
			await leer(K("LICENCIAS"), licencias())
		else:
			await leer(K("PRIVACIDAD"), PRIVACIDAD)

func licencias() -> String:
	var t := I18n.v("Este juego usa Godot Engine, con licencia MIT:\n\n") + Engine.get_license_text()
	for f in ["OFL-PressStart2P.txt", "OFL-AtkinsonHyperlegible.txt", "LICENCIA-DejaVu.txt"]:   # i18n-no
		t += "\n\n— %s —\n\n%s" % [f.trim_prefix("OFL-").trim_prefix("LICENCIA-").trim_suffix(".txt"), FileAccess.get_file_as_string("res://fuentes/" + f).strip_edges()]   # i18n-no
	t += I18n.v("\n\nGODOT ENGINE: PARTES DE TERCEROS")
	for c in Engine.get_copyright_info():
		t += "\n\n" + str(c.name)
		for p in c.parts:
			for cp in p.copyright:
				t += "\n© " + str(cp)
			t += I18n.v("\nLicencia: ") + str(p.license)
	var li := Engine.get_license_info()
	for k in li:
		t += "\n\n— %s —\n\n%s" % [k, str(li[k]).strip_edges()]
	return t

func choose_name() -> String:
	var opts := [K("EDDIE"), K("ÁLEX"), K("LUR"), K("ANDER"), K("Otro...")]
	var i: int = await menu(opts, {"cls": "start", "cancel": false, "title": K("NOMBRE")})
	if i < 4:
		return opts[i]
	var v: String = str(await pedir_texto(I18n.v("¿Cómo te llamas?"), "", 8, true, false)).to_upper().substr(0, 8)
	return v if v != "" else K("EDDIE")

# MAESTRO [1] (con Datos.CAL): chico o chica (la melena y las pasivas de PERSONAJE) y el cumpleaños (día y mes, S.cumple)
func elegir_personaje() -> void:
	if not Datos.CAL:
		return
	var g: int = await menu([{"label": K("CHICO"), "desc": K("Solo cambia cómo te ves: lo demás, igual.")}, {"label": K("CHICA"), "desc": K("Solo cambia cómo te ves: lo demás, igual.")}],   # sin ventajas por sexo (lo pidió el usuario)
		{"cls": "start", "cancel": false, "title": K("¿QUIÉN ERES?"), "desc": true})
	S.sexo = "f" if g == 1 else "m"
	var ms := []
	for m in Datos.MES_N:
		ms.append(I18n.v(m).capitalize())
	var m: int = await menu(ms, {"cls": "full", "cancel": false, "title": K("TU CUMPLEAÑOS: EL MES")})
	var ds := []
	for d in Datos.dias_mes(2028, m + 1):   # con el 29 de febrero
		ds.append(str(d + 1))
	var d: int = await menu(ds, {"cls": "full", "cancel": false, "title": K("TU CUMPLEAÑOS: EL DÍA")})
	S.cumple = {"d": d + 1, "m": m + 1}

func new_game() -> void:
	if Datos.PLAY and FTUE_CORTO:
		await new_game_corto()
		return
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
	await talk("???", [K("¿Diga? ¿Eres familia de Maite, la de Ribera Verde? Un barrio obrero a orillas de la ría."), K("Me llamo Kiko. Llevo treinta años con el growshop de su calle.")])
	await talk(K("KIKO"), [K("Conservo genéticas: variedades locales de Afganistán, México o la India, y los cruces que salen de ellas."),
		K("Las apunto todas en un registro, una GENOTECA. Tu tía Maite me ayudaba a mantenerla."), K("Perdona. ¿Cómo te llamabas?")])
	S.name = await choose_name()
	await elegir_personaje()
	await talk(K("KIKO"), [K("{N}. Hacía años que no te veía por el barrio."), K("Maite murió hace tres semanas. Te ha dejado su piso, su armario de cultivo... y una deuda."),
		K("Coge el autobús en la plaza del pueblo: te deja enfrente del piso. La llave está en el buzón."), K("Lee la carta que te dejó. Después pásate por el growshop.")])
	await fade(1)
	enter_game()
	await wait(300)
	await fade(0)
	await chapter(1)
	await wait(2600)
	show_objective()

# U1 (fase 5, plan de Google Play): plantar en menos de 90 s. Sin el prólogo del caserío ni el autobús: Kiko pregunta el nombre,
# la partida empieza en el piso delante del armario, la carta en dos líneas, Kiko por SMS con las semillas y el abono, y Julen
# en el piso, que explica cada paso del itinerario al hacerlo (aviso_itin); la flecha (objetivo_xy) señala el armario
func new_game_corto() -> void:
	S = new_state()
	S.flags.llegada = true
	await fade(1)
	if not oraculo:
		titulo.hide()
	mode = "intro"
	music("home")
	await fade(0)
	await talk(K("KIKO"), [K("Soy Kiko, el del growshop de la calle de tu tía Maite, en Ribera Verde. ¿Cómo te llamabas?")])
	S.name = await choose_name()
	await elegir_personaje()
	for k in ["letter", "kiko1", "julen1"]:
		S.flags[k] = true
	add_seeds("ria", 3)
	S.items.fert += 2
	S.items.ofertv += 2
	S.items.ophm += 4
	var si: Dictionary = sitio(0)
	S.x = int(si.x)
	S.y = int(si.y) + 1
	S.dir = "up"
	await fade(1)
	enter_game()
	await wait(200)
	await fade(0)
	await talk(K("CARTA"), [K("«{N}: el piso y el armario de cultivo son tuyos. Le debo dinero a Baltasar, el del bar El Ancla. Lo siento.»"),
		K("«Kiko te ayudará. Empieza plantando: A delante del armario.»")])
	await talk(K("SMS · KIKO"), [K("Te he dejado en el armario 3 semillas de SKUNK #1, abono y pH−. Julen, mi hijo, está en el piso: te explica cada paso.")])
	await chapter(1)
	show_objective()

# la casilla que señala la flecha del objetivo (U2, fase 5; solo con Datos.PLAY), en el mapa en el que estás; (-1, -1) si no hay
func objetivo_xy() -> Vector2i:
	var no := Vector2i(-1, -1)
	if not Datos.PLAY or S == null or int(S.ch) != 1 or S.flags.get("harvest1") or mode != "world":
		return no
	if llegando():
		if D.PARADAS.has(S.map):
			var a: Array = D.PARADAS[S.map].a
			return Vector2i(int(a[0]), int(a[1]))
		return no
	var sg = itin_sig()
	if sg == null:
		return no
	var casa: bool = sg.id in ["carta", "plantar", "regar", "veg", "flor", "cosecha"]
	if S.map == "home" and casa and sg.id != "carta":
		for ci in S.carpas.size():
			if S.carpas[ci]:
				var si: Dictionary = sitio(ci)
				return Vector2i(int(si.x), int(si.y))
	var va: String = "home" if casa else ("shop" if sg.id == "kiko" else "")
	if va != "" and S.map != va:
		for k in MAPS[S.map].get("doors", {}):
			if MAPS[S.map].doors[k].get("to") == va:
				var xy: PackedStringArray = String(k).split(",")
				return Vector2i(int(xy[0]), int(xy[1]))
	return no

func enter_game() -> void:
	mode = "world"
	enter_map(S.map, S.x, S.y, S.dir)
	var cl := casilla_libre(MAPS[S.map], P.x, P.y)   # partidas viejas: la casilla puede ser ahora una carpa o un mueble (E3: la libre más cercana)
	if cl != Vector2i(P.x, P.y):
		enter_map(S.map, cl.x, cl.y, "down")
	if S.clientsDay != S.day:
		spawn_clients()
	# Lo que se quedó en la cola al guardar (la cama guarda antes de que salgan los avisos de la noche)
	if S.get("orden") and S.day > S.orden:
		queue("raid", raid_event)
	elif S.get("orden") and S.orden == S.day:
		queue("orden", aviso_orden)
	if S.due > 0 and S.day > S.deadline:
		queue("penalty", penalty_event)
	cola_cargar()
	update_hud()

# E3 (fase 3): la casilla libre más cercana (BFS) dentro del mapa y a la que se llega andando desde sus salidas (no la de detrás
# de una barra); sin salidas, la libre más cercana
func casilla_libre(m: Dictionary, x: int, y: int) -> Vector2i:
	var w := int(m.w)
	var h := int(m.h)
	var x0 := clampi(x, 0, w - 1)
	var y0 := clampi(y, 0, h - 1)
	var sal := {}
	for k in m.get("exits", {}).keys() + m.get("doors", {}).keys():
		var xy: PackedStringArray = String(k).split(",")
		sal[Vector2i(int(xy[0]), int(xy[1]))] = true
	var llega := {}   # lo que se anda desde las salidas
	var q := sal.keys()
	for c in q:
		llega[c] = true
	while q.size():
		var c: Vector2i = q.pop_front()
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var v: Vector2i = c + d
			if not llega.has(v) and not tile_solid(m, v.x, v.y):
				llega[v] = true
				q.append(v)
	var vale := func(c: Vector2i) -> bool: return not tile_solid(m, c.x, c.y) and not sal.has(c) and (llega.has(c) or sal.is_empty())
	if x == x0 and y == y0 and not tile_solid(m, x, y):   # libre: donde estaba, como siempre
		return Vector2i(x, y)
	var visto := {Vector2i(x0, y0): true}
	var cola := [Vector2i(x0, y0)]
	while cola.size():
		var c: Vector2i = cola.pop_front()
		if vale.call(c):
			return c
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var v: Vector2i = c + d
			if v.x >= 0 and v.y >= 0 and v.x < w and v.y < h and not visto.has(v):
				visto[v] = true
				cola.append(v)
	return Vector2i(x0, y0)

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

# MAESTRO [2]: la borrachera y el colocón en el recuadro, solo si los hay (con la sativa o la índica que se note)
func hud_fisio() -> Array:
	var o := []
	if borr() >= 1:
		o.append([I18n.v("ALCOHOL"), "%d %%" % int(borr()), Color("#f08070") if borr() > float(D.FISIO.vision) else Color("#f0b090")])
	if colo() >= 1:
		var e := efecto()
		o.append([I18n.v("COLOCÓN"), ("%d %%" % int(colo())) + ("" if e == "" else " · " + (I18n.v("SATIVA") if e == "sativa" else I18n.v("ÍNDICA"))), Color("#b8a0f0")])
	return o

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
	var ro := T(" · {g} g rosin", {"g": Datos.coma(Datos.jsround(r * 10) / 10.0)}) if r else ""
	var sp := Datos.jsround(SOSP.v) if n_patrullas() else -1
	var od := float(S.get("orden", 0)) > 0
	if Datos.CAL:   # 1.50 (lo pidió el usuario): efectivo, cuenta, flores y extractos encima, en su recuadro
		var gb := total_buds()
		hud_pon("%s · %s:%s" % [Datos.fd_hud(S.day), hh, mm], Datos.jsround(S.heat), sp, SOSP.alarma != null, od, [
			[I18n.v("EFECTIVO"), Datos.eur(S.money), Color("#eef8f0")],
			[I18n.v("BANCO"), Datos.eur(float(S.get("banco", 0))), Color("#a8d8f0")],
			[I18n.v("FLORES"), ("%d g" % int(floor(gb))) if gb >= 10 or gb == floor(gb) else Datos.coma(floor(gb * 10 + 1e-9) / 10.0) + " g", Color("#9ee070")],
			[I18n.v("ROSIN"), Datos.coma(Datos.jsround(r * 10) / 10.0) + " g", Color("#f0c050")]] + hud_fisio())
		return
	hud_pon("%s · %s:%s\n%s · %d g%s" % [Datos.fd_hud(S.day), hh, mm, Datos.eur(S.money), int(floor(total_buds())), ro], Datos.jsround(S.heat), sp, SOSP.alarma != null, od)
