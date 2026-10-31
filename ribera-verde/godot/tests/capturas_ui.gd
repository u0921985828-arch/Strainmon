# Landrace Hunters (Godot) — F7: la interfaz entera (mandos, cajas, menús) en un móvil apaisado, en castellano o en inglés, para ver
# que el texto no se sale: el combate, START, OPCIONES, un diálogo, la tienda, la Genoteca, la mochila y el móvil. No es una prueba
# (tools/tests.sh no la corre); comprueba que ninguna etiqueta de los menús se corta y saca las 8 capturas.
#   xvfb-run … $GODOT --path godot --rendering-driver opengl3 --audio-driver Dummy --resolution 2000x900 \
#     --script res://tests/capturas_ui.gd -- --salida <dir> --idioma en   → «capturas_ui: 8 pantallas, 0 cortes»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

const PANTALLAS := ["combate", "start", "opciones", "dialogo", "tienda", "genoteca", "mochila", "movil", "objetivo", "carpa", "pregunta", "aviso"]

var J
var cortes := []

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func _initialize() -> void:
	Datos.PLAY = true
	Datos.CAL = true
	_corre.call_deferred()

func espera(n: int) -> void:
	for i in n:
		await process_frame

func _corre() -> void:
	var dir := arg("--salida")
	var idioma := arg("--idioma", "es")
	DirAccess.make_dir_recursive_absolute(dir)
	Datos.carga()
	Juego.GUARDADO = "user://prueba-capui.json"
	Juego.AJUSTES = "user://prueba-capui-ajustes.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.AJUSTES))
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var n := 0
	for p in PANTALLAS:
		J = Juego.new()
		J.oraculo = false
		root.add_child(J)
		await espera(3)
		J.aj.idioma = 2 if idioma == "en" else 1
		if arg("--dpi") != "":   # los ppp de un móvil (mandos_geo): los mandos a su tamaño real
			J.DPI_PRUEBA = float(arg("--dpi"))
		J.ajustes_aplica()
		J.S = J.new_game_estado() if J.has_method("new_game_estado") else J.S
		for x in O:
			if x.k == ("combate-ladron" if p == "combate" else "casa-a"):
				_monta(Datos.enteros(x))
		await espera(2)
		match p:
			"combate":
				J.mode = "battle"
				J.B.hp = 30
				J.B.hpMax = 30
				J.bhud_pon(J.bhud_datos())
				J.thief_round()
			"start":
				J.start_menu()
			"opciones":
				J.opciones()
			"dialogo":
				J.talk("KIKO", [J.K("Lo primero, el agua. La del grifo hay que corregirla: si no, la planta no aprovecha el abono.")])
			"tienda":
				J.shop()
			"genoteca":
				J.genoteca()
			"mochila":
				J.mochila()
			"movil":
				J.movil_menu()
			"objetivo":
				J.objetivo_menu()
			"carpa":                     # la vista de carpa: la ficha de la izquierda y el cursor sobre la pantalla de 240
				J.abrir_carpa(0)
			"pregunta":                  # un diálogo con opciones (el caso más apretado: texto + menú a la vez)
				J.ask("¿Le compras el carro de esquejes a Kiko por 240 €?", [J.K("Sí, me lo llevo"), J.K("Ahora no")], "KIKO")
			"aviso":                     # el aviso de arriba (toast), con el HUD al lado
				J.toast("Has llegado al capítulo 2: ya puedes vender en la calle.", 60000.0)
		await espera(90)
		_mira_cortes(p)
		if p == "combate" and Datos.PLAY:   # 1.58: la caja del jugador no tapa al jugador (lo de la izquierda) ni pisa la del enemigo
			var rp: Rect2 = J.bP.get_global_rect()
			var re: Rect2 = J.bE.get_global_rect()
			var es: Rect2 = J.escena.get_global_rect()
			# el jugador está de pie abajo (pies en la fila 142 de 160, 64 px de alto): la caja, entera por encima de su cintura
			if rp.end.y > es.position.y + es.size.y * .6 or rp.intersects(re):
				cortes.append("combate: la caja de EDDIE en %s tapa al jugador o a la del enemigo (%s)" % [rp, re])
			# con CAL, el combate en su lado (el enemigo arriba a la izquierda, hasta la columna 94; el protagonista abajo a la derecha, con la
			# gorra en la fila 86): las dos cajas, a la derecha del enemigo y por encima de la gorra
			var k := es.size.x / 240
			if Datos.CAL and (minf(rp.position.x, re.position.x) < es.position.x + 96 * k or maxf(rp.end.y, re.end.y) > es.position.y + 86 * k):
				cortes.append("combate: las cajas (%s, %s) tapan al enemigo o al protagonista (escena %s)" % [re, rp, es])
		_mira_hueco(p)
		_mira_maquetado(p)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(dir.path_join("ui-%d-%s-%s.png" % [n + 1, p, idioma]))
		n += 1
		J.queue_free()
		await espera(2)
	print("capturas_ui: %d pantallas, %d cortes%s" % [n, cortes.size(), (": " + "; ".join(cortes)) if cortes.size() else ""])
	quit(0)

# una etiqueta cortada: su texto ocupa más de lo que mide (Label con clip o recorte) o se sale de la pantalla
func _mira_cortes(p: String) -> void:
	var vp := root.get_visible_rect()
	for c in _todos(J):
		if not (c is Label or c is RichTextLabel) or not c.is_visible_in_tree() or c.get("text") == "":
			continue
		var r: Rect2 = c.get_global_rect()
		if r.size.x <= 0:
			continue
		if c is Label:
			var f: Font = c.get_theme_font("font")
			var fs: int = c.get_theme_font_size("font_size")
			var w := 0.0
			for l in String(c.text).split("\n"):
				w = maxf(w, f.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
			if c.autowrap_mode == TextServer.AUTOWRAP_OFF and w > r.size.x + 1:
				cortes.append("%s: «%s» %d > %d" % [p, c.text, w, r.size.x])
		if r.end.x > vp.end.x + 1 or r.position.x < -1:
			cortes.append("%s: «%s» fuera de la pantalla" % [p, String(c.text).left(30)])

# 0.72, el repaso del maquetado: el menú no pisa el diálogo, el HUD no sale con un menú que ya dice lo mismo, las etiquetas de una
# lista arrancan todas en la misma columna y la marca de «sigue la lista» se ve y se toca
func _mira_maquetado(p: String) -> void:
	if J.menu_box.visible and J.dlg.visible:
		var rm: Rect2 = J.menu_box.get_global_rect()
		var rd: Rect2 = J.dlg.get_global_rect()
		if J.menu_box.get_meta("cls", "right") != "battle" and rm.intersects(rd):
			cortes.append("%s: el menú %s pisa el diálogo %s" % [p, rm, rd])
	if J.menu_box.visible and J.menu_box.get_meta("cls", "right") in ["full", "start"] and J.hud.visible:
		cortes.append("%s: el HUD sale con el menú abierto, que ya dice la fecha y el dinero" % p)
	for c in J.menu_col.get_children():
		if not (c is VBoxContainer):
			continue
		var xs := {}
		for fila in c.get_children():
			if not (fila is HBoxContainer):
				continue
			for n in fila.get_children():
				if n is Label and String(n.text).strip_edges() != "" and String(n.text) != "▸" and n.size_flags_horizontal == Control.SIZE_EXPAND_FILL:
					xs[roundi(n.get_global_rect().position.x)] = true
					break
		if xs.size() > 1:
			cortes.append("%s: las etiquetas de la lista arrancan en %s" % [p, xs.keys()])
	for c in J.menu_col.get_children():
		if c is Label and String(c.text) in ["▲", "▼"] and c.size.y < 8 * J.us - .5:
			cortes.append("%s: la marca «%s» mide %.1f u de alto (mínimo 8)" % [p, c.text, c.size.y / J.us])

# un menú con más filas de las que enseña no deja debajo de la última un hueco donde cabría otra (lo vio el usuario en la tienda)
func _mira_hueco(p: String) -> void:
	if not J.menu_box.visible:
		return
	var lh: float = 14.5 * J.us
	for c in J.menu_col.get_children():
		if c is VBoxContainer and c.get_child_count() > 0 and c.get_child_count() < J.m_items.size():
			var libre: float = c.size.y - c.get_combined_minimum_size().y
			if libre >= lh - .5:
				cortes.append("%s: hueco de %.1f filas debajo de la última (%d de %d)" % [p, libre / lh, c.get_child_count(), J.m_items.size()])
	var aire: float = J.menu_col.size.y - J.menu_col.get_combined_minimum_size().y
	if J.menu_box.get_meta("cls", "") == "full" and aire >= lh - .5:   # caben todas: la caja, sin aire debajo
		cortes.append("%s: %.1f filas de aire en la caja" % [p, aire / lh])

func _todos(n: Node) -> Array:
	var r := [n]
	for c in n.get_children():
		r.append_array(_todos(c))
	return r

func _monta(e: Dictionary) -> void:
	# el ancho de la escena, el de la pantalla (ajusta), no el de la del oráculo (240): si no, se pinta a la izquierda y las cajas, que
	# van por la escena centrada, parecen fuera
	J.S = e.S
	J.B = e.B
	J.VC = e.VC
	J.vfx = e.vfx
	J.ents = []
	if e.mode == "world" or e.mode == "carpa":
		J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	for c in e.P:
		J.P[c] = e.P[c]
	J.mode = e.mode
