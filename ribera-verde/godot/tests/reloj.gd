# Ribera Verde (Godot) — el reloj más lento (lo pidió el usuario: «el tiempo en el juego debería pasar más lento»; con Datos.CAL):
# OPCIONES → RELOJ, lo que dura un día del juego en minutos de verdad (4, 8 de serie, 12, 24); sin CAL, el ritmo de antes (4).
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
	# 1 · de serie, 8 minutos el día (lo pidió el usuario: «un intermedio»): 3 minutos del juego por segundo
	chk(not J.aj.has("rl") and J.reloj_i() == 1, "de serie, el 1 (%s)" % J.reloj_i())
	var m := pasan(30)
	chk(m >= 89 and m <= 90, "de serie, 30 s = 90 min (%d)" % m)
	chk(absf(J.ms_por_min() * 1440 - 8 * 60000) < 1, "un día = 8 min (%s ms el minuto)" % J.ms_por_min())
	# 2 · rápido (el del HTML), el de antes y lento
	J.aj.rl = 0
	m = pasan(30)
	chk(m >= 179 and m <= 180, "rápido, 30 s = 180 min (%d)" % m)
	J.aj.rl = 2
	m = pasan(30)
	chk(m >= 59 and m <= 60, "12 min, 30 s = 60 min (%d)" % m)
	J.aj.rl = 3
	m = pasan(30)
	chk(m >= 29 and m <= 30, "lento, 30 s = 30 min (%d)" % m)
	# 3 · los ajustes de antes (aj.reloj, [4, 12, 24]): el de serie pasa al nuevo, 24 sigue en 24
	J.aj.erase("rl")
	J.aj.reloj = 1
	chk(J.RELOJ_DIA[J.reloj_i()] == 8, "el de serie de antes (12), al de ahora (8)")
	J.aj.reloj = 2
	chk(J.RELOJ_DIA[J.reloj_i()] == 24, "el lento de antes, 24")
	J.aj.reloj = 0
	chk(J.RELOJ_DIA[J.reloj_i()] == 8, "el rápido de antes, al de serie")
	J.aj.reloj = 1
	# 4 · un ajuste roto no rompe el reloj
	J.aj.rl = 9
	chk(absf(J.ms_por_min() - 1000.0) < .01, "fuera de rango, el lento (%s)" % J.ms_por_min())
	# 5 · sin CAL, como el HTML, aunque el ajuste diga otra cosa
	Datos.CAL = false
	J.aj.rl = 3
	chk(J.ms_por_min() == J.D.MS_PER_MIN, "sin CAL, el de antes (%s)" % J.ms_por_min())
	m = pasan(30)
	chk(m >= 179 and m <= 180, "sin CAL, 30 s = 180 min (%d)" % m)
	Datos.CAL = true
	J.aj.erase("rl")
	# 6 · OPCIONES lo enseña y lo cambia en bucle
	var vistos := []
	var veces := [0]
	J.gancho_menu = func(items: Array, o: Dictionary) -> Dictionary:
		var labels := []
		for it in items:
			labels.append(str(it.get("label", "")))
		var k := labels.find("RELOJ")
		if k >= 0:
			vistos.append(items[k].right)
		o = o.duplicate()
		o.initial = k if k >= 0 and veces[0] < 4 else labels.size() - 1
		veces[0] += 1
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
	chk(vistos == ["1 DÍA = 8 MIN", "1 DÍA = 12 MIN", "1 DÍA = 24 MIN", "1 DÍA = 4 MIN", "1 DÍA = 8 MIN"], "OPCIONES → RELOJ en bucle (%s)" % [vistos])
	chk(J.reloj_i() == 1, "vuelve al de serie (%s)" % J.reloj_i())
	var a = JSON.parse_string(FileAccess.get_file_as_string(Juego.AJUSTES))
	chk(a is Dictionary and int(a.get("rl", -1)) == 1, "se guarda en los ajustes (%s)" % [a])
	print("reloj: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit()
