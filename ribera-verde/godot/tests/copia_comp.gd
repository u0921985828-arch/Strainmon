# La partida exportada, comprimida y cifrada (lo pidió el usuario: «una forma de encriptado y comprimido del texto para que no
# ocupe tanto»): «LH1.» + base64 del gzip con XOR + «.» + md5 corto. Ida y vuelta, mucho más corta, con espacios, saltos de
# línea y texto de más alrededor; cortada o cambiada, el aviso propio; el JSON de antes sigue entrando; desde el título.
#   $GODOT --headless --path godot --script res://tests/copia_comp.gd   → «copia_comp: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var LOG := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = true
	Datos.CAL = true
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

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

# lo pegado → el guardado que queda (null si no se guardó) y lo que dijo
func importa(txt: String):
	if FileAccess.file_exists(Juego.GUARDADO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.GUARDADO))
	LOG.clear()
	chk(corre(func(): await J.importar(true, txt)), "importar sin bloqueo")
	return J.load_save() if FileAccess.file_exists(Juego.GUARDADO) else null

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-copia-comp.json"
	Juego.AJUSTES = "user://prueba-copia-comp-ajustes.json"
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.oraculo = true
	J.gancho_menu = func(_items, o): return o
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	J.S = J.new_state()
	J.saltar_tutorial()
	J.S.name = "EDDIE"
	J.S.money = 123456
	J.mode = "world"
	J.enter_game()
	var json := JSON.stringify(J.S, "", false, true)
	# 1. EXPORTAR deja el comprimido
	chk(corre(func(): await J.exportar()), "exportar")
	var c: String = J.exportado
	chk(c.begins_with(Juego.PARTIDA_PRE), "empieza por LH1.: " + c.substr(0, 12))
	chk(c.length() < json.length(), "más corta: %d de %d" % [c.length(), json.length()])
	chk(not c.contains("EDDIE") and not c.contains("money"), "no se lee")
	chk(Juego.abre_partida(c) == json, "ida y vuelta exacta")
	# 2. con espacios, saltos de línea y texto de más alrededor (copiado de un correo o una nota)
	var sucio := "Mi partida:\n"
	for i in range(0, c.length(), 60):
		sucio += c.substr(i, 60) + ("\r\n" if i % 120 == 0 else " ")
	sucio += "\nSaludos."
	chk(Juego.abre_partida(sucio) == json, "con saltos y texto alrededor")
	# 3. cortada o cambiada: nada y el aviso propio
	chk(Juego.abre_partida(c.substr(0, c.length() - 20)) == "", "cortada → vacío")
	var mal := c.substr(0, 40) + ("B" if c[40] != "B" else "C") + c.substr(41)
	chk(Juego.abre_partida(mal) == "", "cambiada → vacío")
	chk(Juego.abre_partida(c.substr(0, c.rfind(".") )) == "", "sin la suma → vacío")
	var s = importa(c.substr(0, c.length() / 2))
	chk(s == null, "cortada: no se guarda")
	chk(LOG.any(func(t): return String(t).contains("cortada")), "cortada: el aviso propio %s" % [LOG])
	# 4. desde el título: la comprimida, la sucia y el JSON de antes (con texto alrededor) se cargan igual
	for caso in [["comprimida", c], ["sucia", sucio], ["json", "copia: " + json + " fin"]]:
		s = importa(caso[1])
		chk(s != null and s.name == "EDDIE" and int(s.money) == 123456, "título, " + caso[0])
	# 5. lo que no es una partida, el aviso de siempre
	s = importa("hola")
	chk(s == null and LOG.any(func(t): return String(t).contains("no es una partida")), "no es partida %s" % [LOG])
	for f in fallos:
		print("  FALLO ", f)
	print("copia_comp: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit()
