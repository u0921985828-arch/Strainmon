# Ribera Verde (Godot) — cada abono en su fase (lo pidió el usuario: «en crecimiento no debe estar permitido echar abono de
# floración y a su vez lo mismo en crecimiento, mecánicas algo más simples»; con Datos.CAL): en crecimiento (prog < .65) solo el
# de CRECIMIENTO y en floración solo el de FLORACIÓN; sin el que toca, no se echa el otro; sin CAL, como antes.
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-extr.
#   $GODOT --headless --path godot --script res://tests/abono_fase.gd   → «abono_fase: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var S
var D
var MENUS := []
var LOG := []
var QUIERO := []
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

func log_tiene(t: String) -> bool:
	for l in LOG:
		if String(l).contains(t):
			return true
	return false

func planta(prog: float) -> Dictionary:
	return {"sid": "ria", "prog": prog, "water": 80.0, "health": 100.0, "pest": false, "fert": false, "fv": null, "f": {"id": 7, "t": 18.0, "y": 1.0, "i": .5}}

func cuida(p: Dictionary, q: Array) -> Array:
	S.pots[0] = p
	MENUS.clear()
	LOG.clear()
	QUIERO = q
	chk(corre(func(): await J.pot_action(0)), "pot_action %s" % [q])
	return MENUS[0] if MENUS.size() else []

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-abono.json"
	Juego.AJUSTES = "user://prueba-abono-ajustes.json"
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
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	# 1 · en crecimiento, sin abono de crecimiento: sale ABONAR, pero no echa el de floración
	S.items.fertv = 0
	S.items.ofertv = 0
	S.items.fert = 2
	S.items.ofert = 0
	var p := planta(.5)
	var m := cuida(p, ["Abonar"])
	chk(m.has("Abonar"), "crecimiento sin abonar: ABONAR %s" % [m])
	chk(int(S.items.fert) == 2 and not p.fert, "en crecimiento no se echa el de floración (fert %d, %s)" % [S.items.fert, p.fert])
	chk(log_tiene("solo le va el abono de CRECIMIENTO"), "dice por qué")
	# 2 · en crecimiento, con el de crecimiento: lo echa y el de floración se queda
	S.items.fertv = 1
	m = cuida(p, ["Abonar"])
	chk(int(S.items.fertv) == 0 and float(p.fv) > 0 and int(S.items.fert) == 2 and not p.fert, "echa el de crecimiento (%s)" % [p])
	# 3 · ya abonada de crecimiento: en crecimiento no sale ABONAR (aunque haya de floración)
	m = cuida(p, ["Salir"])
	chk(not m.has("Abonar"), "abonada de crecimiento: sin ABONAR %s" % [m])
	# 4 · en floración, con los dos: echa el de floración y el de crecimiento se queda
	S.items.fertv = 1
	var q := planta(.8)
	m = cuida(q, ["Abonar"])
	chk(m.has("Abonar"), "floración sin abonar: ABONAR")
	chk(q.fert and int(S.items.fert) == 1 and int(S.items.fertv) == 1 and q.fv == null, "en floración, el de floración (%s)" % [q])
	# 5 · ya abonada de floración: no sale ABONAR
	m = cuida(q, ["Salir"])
	chk(not m.has("Abonar"), "abonada de floración: sin ABONAR %s" % [m])
	# 6 · en floración sin el de floración: no echa el de crecimiento
	S.items.fert = 0
	var r := planta(.8)
	m = cuida(r, ["Abonar"])
	chk(not r.fert and int(S.items.fertv) == 1 and r.fv == null, "en floración no se echa el de crecimiento (%s)" % [r])
	# 7 · sin CAL, como antes: en crecimiento ya abonada, ABONAR echa el de floración
	Datos.CAL = false
	S.items.fert = 1
	var v := planta(.5)
	v.fv = .75
	m = cuida(v, ["Abonar"])
	chk(m.has("Abonar") and v.fert and int(S.items.fert) == 0, "sin CAL, como antes (%s)" % [v])
	Datos.CAL = true
	print("abono_fase: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
