# Ribera Verde (Godot) — el reloj (lo pidió el usuario: «el tiempo en el juego debería pasar más lento» y, después, «la velocidad
# a la que va el juego no puede ser seleccionable»; con Datos.CAL): un día del juego dura 8 minutos de verdad, siempre, sin
# ajuste que lo cambie (ni OPCIONES → RELOJ ni aj.rl/aj.reloj guardados); sin CAL, el ritmo de antes (4).
#   $GODOT --headless --path godot --script res://tests/reloj.gd   → «reloj: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# minutos del juego que pasan en `seg` segundos de verdad, a 60 fotogramas
func pasan(seg: float) -> int:
	J.S.min = 8 * 60
	J.time_acc = 0.0
	var d0: int = J.S.day
	for i in int(seg * 60):
		J.update(1000 / 60.0)
	return (J.S.day - d0) * 1440 + J.S.min - 8 * 60

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-reloj.json"
	Juego.AJUSTES = "user://prueba-reloj-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-extr":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.enter_map("home", 5, 5, "up")
	J.mode = "world"
	J.oraculo = false
	J.gancho_toast = func(_h, _ms): pass
	# 1 · 8 minutos el día (lo pidió el usuario: «un intermedio»): 3 minutos del juego por segundo
	chk(J.reloj_i() == J.RELOJ_SERIE and J.RELOJ_DIA[J.reloj_i()] == 8, "8 min el día (%s)" % J.reloj_i())
	var m := pasan(30)
	chk(m >= 89 and m <= 90, "30 s = 90 min (%d)" % m)
	chk(absf(J.ms_por_min() * 1440 - 8 * 60000) < 1, "un día = 8 min (%s ms el minuto)" % J.ms_por_min())
	# 2 · ningún ajuste lo cambia (lo pidió el usuario: «no la puedes seleccionar desde el menú»)
	for v in [0, 2, 3, 9]:
		J.aj.rl = v
		chk(absf(J.ms_por_min() * 1440 - 8 * 60000) < 1, "aj.rl = %d, igual (%s)" % [v, J.ms_por_min()])
	J.aj.erase("rl")
	for v in [0, 1, 2]:
		J.aj.reloj = v
		chk(J.RELOJ_DIA[J.reloj_i()] == 8, "aj.reloj = %d, igual" % v)
	J.aj.erase("reloj")
	J.aj.rl = 0
	m = pasan(30)
	chk(m >= 89 and m <= 90, "con el ajuste viejo, 30 s = 90 min (%d)" % m)
	J.aj.erase("rl")
	# 3 · sin CAL, como el HTML
	Datos.CAL = false
	chk(J.ms_por_min() == J.D.MS_PER_MIN, "sin CAL, el de antes (%s)" % J.ms_por_min())
	m = pasan(30)
	chk(m >= 179 and m <= 180, "sin CAL, 30 s = 180 min (%d)" % m)
	Datos.CAL = true
	# 4 · OPCIONES ya no trae la fila del reloj
	var labels := []
	J.gancho_menu = func(items: Array, o: Dictionary) -> Dictionary:
		labels.clear()
		for it in items:
			labels.append(str(it.get("label", "")))
		o = o.duplicate()
		o.initial = labels.size() - 1
		return o
	var st := {"fin": false}
	var co := func():
		await J.run(func(): await J.opciones())
		st.fin = true
	co.call()
	J.M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	var t0: float = J.M.reloj
	while not st.fin and J.M.reloj - t0 < 20000 and J.M.paso():
		pass
	chk(st.fin, "OPCIONES se cierra")
	chk(not labels.has("RELOJ"), "sin la fila RELOJ (%s)" % [labels])
	chk(labels.has("VIBRACIÓN") and labels.has("AHORRO"), "las demás siguen (%s)" % [labels])
	chk(J.ms_por_min() * 1440 == 8 * 60000, "tras OPCIONES, sigue a 8 min")
	print("reloj: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit()
