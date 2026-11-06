# Landrace Hunters (Godot) — teclado y ratón en el ordenador (lo pidió el usuario: «los controles conectados al AWSD y el
# botón A y B, que sea el clic izquierdo y derecho»).
#  · W A S D son las flechas; el clic izquierdo en el mundo es A y el derecho es B (también encima de un menú); el izquierdo
#    sobre un mando aprieta ese mando y no A; el ratón que Godot imita con un dedo no aprieta nada.
#  · En la web del ordenador (sin pantalla táctil; aquí, UI.RATON_PRUEBA) la cruceta y A/B no se ven ni ocupan sitio: el clic
#    donde estaba la cruceta es A, el derecho donde estaba A es B; START, MÓVIL y SONIDO se quedan.
#   $GODOT --headless --path godot --script res://tests/raton.gd -- --sin-arranque   → «raton: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var n := 0
var fallos := []
var got := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func raton(b: int, p: Vector2, emulado := false) -> void:
	for on in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = b
		e.position = p
		e.global_position = p
		e.pressed = on
		if emulado:
			e.device = InputEvent.DEVICE_ID_EMULATION
		J.get_viewport().push_input(e)

func tecla(k: int) -> void:
	for on in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.pressed = on
		J.get_viewport().push_input(e)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-raton.json"
	Juego.AJUSTES = "user://prueba-raton-ajustes.json"
	J = Juego.new()
	root.add_child(J)
	for i in 5:
		await process_frame
	J.handlers.clear()
	J.push(func(b): got.append(b))
	# un punto de la pantalla del juego que no sea la cruceta ni un mando
	var tam: Vector2 = J.get_viewport().get_visible_rect().size
	var vacio := Vector2(-1, -1)
	for y in range(8, int(tam.y), 8):
		for x in range(8, int(tam.x), 8):
			var p := Vector2(x, y)
			if vacio.x < 0 and not J.zona_cruz.has_point(p) and J.mando_en(p) == "" and not J.zona_ab.has_point(p):
				vacio = p
	chk(vacio.x >= 0, "hay sitio libre en %s" % [tam])

	got.clear()
	for k in [KEY_W, KEY_A, KEY_S, KEY_D]:
		tecla(k)
	chk(got == ["up", "left", "down", "right"], "W A S D, las flechas: %s" % [got])

	got.clear()
	raton(MOUSE_BUTTON_LEFT, vacio)
	chk(got == ["A"], "clic izquierdo en el mundo = A: %s" % [got])

	got.clear()
	raton(MOUSE_BUTTON_RIGHT, vacio)
	chk(got == ["B"], "clic derecho = B: %s" % [got])

	got.clear()
	raton(MOUSE_BUTTON_LEFT, vacio, true)
	raton(MOUSE_BUTTON_RIGHT, vacio, true)
	chk(got.is_empty(), "el ratón imitado por un dedo no aprieta: %s" % [got])

	if J.botones.has("B"):
		got.clear()
		raton(MOUSE_BUTTON_LEFT, J.botones["B"].get_global_rect().get_center())
		chk(not got.has("A"), "clic izquierdo en el mando B no es A: %s" % [got])

	# un menú abierto: el derecho lo cierra (B) aunque caiga encima
	J.handlers.clear()
	var st := {"r": null}
	var co := func():
		st.r = await J.menu(["Uno", "Dos"], {})
	co.call()
	for i in 3:
		await process_frame
	var c: Vector2 = J.menu_box.get_global_rect().get_center() if J.menu_box.visible else vacio
	raton(MOUSE_BUTTON_RIGHT, c)
	for i in 3:
		await process_frame
	chk(st.r == -1, "clic derecho encima del menú lo cierra: %s" % [st.r])

	# la web del ordenador: sin cruceta ni A/B
	var pa: Vector2 = J.botones["A"].get_global_rect().get_center()
	var pc: Vector2 = J.botones["left"].get_global_rect().get_center()
	J.set("RATON_PRUEBA", true)
	J.ajusta()
	var ocultos := true
	for k in ["up", "down", "left", "right", "mid", "A", "B"]:
		ocultos = ocultos and not J.botones[k].visible
	chk(ocultos, "la cruceta y A/B no se ven en la web del ordenador")
	chk(J.botones["START"].visible and J.botones["SONIDO"].visible, "START y SONIDO sí")
	chk(J.zona_cruz.size == Vector2.ZERO and J.zona_ab.size == Vector2.ZERO, "la cruceta y A/B no ocupan sitio")
	J.handlers.clear()
	J.push(func(b): got.append(b))
	got.clear()
	chk(J.mando_en(pc) == "", "donde estaba la cruceta no hay mando")
	raton(MOUSE_BUTTON_LEFT, pc)
	raton(MOUSE_BUTTON_RIGHT, pa)
	chk(got == ["A", "B"], "donde estaban la cruceta y A, el clic es A y B: %s" % [got])
	J.set("RATON_PRUEBA", false)

	print("raton: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO " + f)
	quit(1 if fallos.size() else 0)
