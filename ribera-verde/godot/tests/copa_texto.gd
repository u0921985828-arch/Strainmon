# Ribera Verde (Godot) — los textos de las misiones de la Copa sin pH ni EC (lo pidió el usuario en las decisiones:
# «simplificarlos»; con Datos.CAL). START → OBJETIVO en el capítulo 6 enseña el texto llano (dc) de «Floración a tope»;
# sin CAL, el de siempre (el oráculo del HTML no cambia).
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-extr.
#   $GODOT --headless --path godot --script res://tests/copa_texto.gd   → «copa_texto: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var S
var D
var DESCS := []
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
	for it in items:
		if it is Dictionary:
			DESCS.append(str(it.get("desc", "")))
	o = o.duplicate()
	o.initial = items.size() - 1   # Volver
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
			return false
	return true

func con_ph(t: String) -> bool:
	return t.contains("pH") or t.contains(" EC")

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-copa.json"
	Juego.AJUSTES = "user://prueba-copa-ajustes.json"
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
	S = J.S
	D = J.D
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	S.ch = 6
	S.flags.kiko1 = true
	var copa: Array = D.MISIONES.filter(func(m): return int(m.ch) == 6)
	chk(copa.size() == 3, "tres misiones de la Copa")
	# 1 · con CAL, ninguna misión enseña pH ni EC, y la de la floración dice lo mismo sin ellos
	for m in D.MISIONES:
		chk(not con_ph(J.mision_desc(m)), "%s sin pH ni EC: %s" % [m.id, J.mision_desc(m)])
	var flor: Dictionary = copa.filter(func(m): return m.id == "flor27")[0]
	var t: String = J.mision_desc(flor)
	chk(t.contains("LED de 720 W") and t.contains("MEATZA FLORACIÓN") and t.contains("medidor") and t.contains("ORTUA BIO"), "lo que hay que comprar sigue: %s" % t)
	# 2 · lo que se ve en START → OBJETIVO
	DESCS.clear()
	chk(corre(func(): await J.objetivo_menu()), "objetivo")
	chk(DESCS.has(t), "el menú enseña el texto llano")
	chk(not DESCS.any(func(d): return con_ph(d)), "nada con pH ni EC en OBJETIVO")
	# 3 · sin CAL, el de siempre (el del oráculo)
	Datos.CAL = false
	chk(J.mision_desc(flor) == str(flor.d) and con_ph(J.mision_desc(flor)), "sin CAL, el texto de antes")
	Datos.CAL = true
	print("copa_texto: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
