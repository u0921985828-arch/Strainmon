# Ribera Verde (Godot) — ordenar la sala de cultivo de KAIA con los mandos (kaiacult.gd, con CAL; lo pidió el usuario: «tiene que
# tener lógica con el suelo que hay al rededor y las zonas donde las colocas»): una carpa (de 2 × 2) movida con las flechas cabe en la zona de
# cultivo y no en el pasillo, A no la deja donde no cabe, se queda donde se deja y sigue ahí tras guardar y cargar.
#   $GODOT --headless --path godot --script res://tests/kaia_orden.gd   → «kaia_orden: N comprobaciones, 0 fallos»
extends SceneTree
const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
var J
var M
var n := 0
var fallos := []
func chk(c: bool, t: String) -> void:
	n += 1
	if not c:
		fallos.append(t)
func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()
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
func _corre() -> void:
	Juego.GUARDADO = "user://prueba-kaia-orden.json"
	Juego.AJUSTES = "user://prueba-kaia-orden-aj.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S.duplicate(true)
	J.oraculo = true
	J.gancho_menu = func(items, o): return o
	J.gancho_texto = func(_t, _nm): pass
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	if not (J.S.get("mar") is Dictionary):
		J.S.mar = {}
	J.S.mar.lic = 1
	J.S.kc = {"niv": 0, "kits": [0, 0, 0, 0], "p": []}   # las cuatro carpas de 2 × 2, ya llegadas
	J.kc()
	J.S.erase("coloca")
	J.queued.clear()
	J.pending.clear()
	J.enter_map("cult-muelle", 1, 4, "down")
	J.mode = "world"
	var C := "cult-muelle"
	# la carpa 4 (4, 7): dos a la izquierda pisa el pasillo; una a la derecha, otra vez en la zona
	var vistos := []
	var fin := {"r": null}
	var co := func():
		fin.r = await J.mover_pieza(C, "kcs3")
	co.call()
	M.paso()
	for b in ["left", "left"]:
		J.press(b)
		vistos.append(J.ORDEN.no if J.ORDEN != null else "?")
	J.press("A")   # en el pasillo: no se deja
	M.paso()
	chk(J.ORDEN != null and vistos[0] == "" and vistos[1] == "zona", "con la carpa en el pasillo, A no la deja (%s)" % [vistos])
	J.press("right")
	vistos.append(J.ORDEN.no if J.ORDEN != null else "?")
	chk(vistos[2] == "", "en la x 3 cabe (%s)" % [vistos])
	J.press("A")
	for q in 30:
		M.paso()
	var p: Array = J.pos_pieza(C, "kcs3")
	chk(fin.r == true and int(p[0]) == 3 and int(p[1]) == 7, "dejada en la zona (%s %s)" % [fin.r, p])
	chk(J.MAPS[C].o[8][3] == "carpaKS3" and J.MAPS[C].o[7][3] == "carpaG2" and J.MAPS[C].o[8][5] == null, "en la sala, ya en su sitio nuevo")
	# guardar y cargar
	J.S.kc.p[15] = {"sid": "txoko", "prog": .3, "water": 100, "health": 100, "fert": false, "pest": false}
	var txt := JSON.stringify(J.S)
	J.S = Datos.enteros({"S": JSON.parse_string(txt)}).S
	J.MAPS[C] = J.D.MAPS[C].duplicate(true)
	Datos.enteros(J.MAPS[C])
	J.enter_map(C, 1, 4, "down")
	p = J.pos_pieza(C, "kcs3")
	chk(int(p[0]) == 3 and int(p[1]) == 7 and J.MAPS[C].o[8][3] == "carpaKS3" and J.kc().p[15] is Dictionary, "tras guardar y cargar, igual")
	print("kaia_orden: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
