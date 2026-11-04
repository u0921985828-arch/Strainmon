# Ribera Verde (Godot) — la migración de la partida (docs/MIGRACION-BETA.md): el directorio privado de la app se borra al
# desinstalarla y una firma nueva obliga a desinstalar, así que la copia se saca a un archivo con el selector del sistema
# (ACTION_CREATE_DOCUMENT), se manda a otra app (ACTION_SEND) o se abre de un archivo (ACTION_OPEN_DOCUMENT), y en el título,
# sin partida guardada, RECUPERAR PARTIDA sale a la vista. Sin plugin manda Plataforma.PRUEBA_DOC / PRUEBA_ABIERTO.
#   $GODOT --headless --path godot --script res://tests/migracion.gd   → «migracion: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Plataforma = preload("res://src/plataforma.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var PEGO = null
var TECLA := "A"
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

# lo dicho en cualquiera de los avisos (puede caer algún texto del juego por medio)
func dice(sub: String) -> bool:
	for t in LOG:
		if String(t).contains(sub):
			return true
	return false

func borra_guardado() -> void:
	for r in [Juego.GUARDADO, Juego.GUARDADO + ".bak"]:
		if FileAccess.file_exists(r):
			DirAccess.remove_absolute(r)

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
	if QUIERO.size():
		var q: String = QUIERO.pop_front()
		for i in labels.size():
			if labels[i].begins_with(q):
				k = i
				break
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

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-migracion.json"
	Juego.AJUSTES = "user://prueba-migracion-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "caja-dentro":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	J.gancho_pedir = func(_t, _i, _m, _c): return PEGO
	M.intervalo(func():
		if J.handlers.size():
			J.press(TECLA), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)

	# 1 · sin selector de archivos (escritorio): como siempre, al portapapeles
	Plataforma.PRUEBA_DOC = -1
	Plataforma.PRUEBA_ABIERTO = ""
	chk(not J.doc_hay(), "sin plugin y sin PRUEBA_DOC, no hay selector")
	J.exportado = ""
	LOG = []
	MENUS = []
	chk(corre(func(): await J.exportar()), "bloqueo exportando sin selector")
	chk(MENUS.is_empty(), "sin selector, sin menú de destino: %s" % [MENUS])
	chk(J.exportado.begins_with("LH1."), "exportada comprimida: %s" % J.exportado.substr(0, 12))
	chk(dice("portapapeles"), "el aviso del portapapeles: %s" % [LOG])

	# 2 · con selector: GUARDAR EN UN ARCHIVO, MANDARLA A OTRA APP, COPIAR EL TEXTO
	Plataforma.PRUEBA_DOC = 1
	chk(J.doc_hay(), "con PRUEBA_DOC >= 0, hay selector")
	LOG = []
	MENUS = []
	QUIERO = ["GUARDAR"]
	chk(corre(func(): await J.exportar()), "bloqueo guardando en un archivo")
	chk(MENUS.size() and MENUS[0] == ["GUARDAR EN UN ARCHIVO", "MANDARLA A OTRA APP", "COPIAR EL TEXTO", "VOLVER"], "el menú de destino: %s" % [MENUS])
	chk(dice("Partida guardada en el archivo") and dice("desinstal"), "el aviso de guardado: %s" % [LOG])
	var env: Array = J.plat().enviados
	chk(env.size() and String(env[-1]).begins_with("guarda_doc:landrace-"), "el nombre del archivo: %s" % [env])
	chk(String(env[-1]).ends_with(".txt") and String(env[-1]).contains("-d%d" % int(J.S.day)), "el día en el nombre: %s" % [env[-1]])

	Plataforma.PRUEBA_DOC = 0   # el jugador deja el selector
	LOG = []
	MENUS = []
	QUIERO = ["GUARDAR"]
	chk(corre(func(): await J.exportar()), "bloqueo dejando el selector")
	chk(dice("No se ha guardado"), "si lo deja, lo dice: %s" % [LOG])

	Plataforma.PRUEBA_DOC = 1
	LOG = []
	MENUS = []
	QUIERO = ["MANDARLA"]
	J.plat().enviados = []
	chk(corre(func(): await J.exportar()), "bloqueo compartiendo")
	chk(J.plat().enviados.has("comparte"), "mandada a otra app: %s" % [J.plat().enviados])

	LOG = []
	MENUS = []
	QUIERO = ["COPIAR"]
	chk(corre(func(): await J.exportar()), "bloqueo copiando el texto")
	chk(dice("portapapeles"), "COPIAR EL TEXTO, al portapapeles: %s" % [LOG])

	# 3 · importar: de dónde viene (ABRIR UN ARCHIVO, PEGAR EL TEXTO; sin plugin, sin nube)
	var guardada: String = J.exportado
	MENUS = []
	QUIERO = ["VOLVER"]
	chk(corre(func(): await J.importar(true)), "bloqueo eligiendo el origen")
	chk(MENUS.size() and MENUS[0] == ["ABRIR UN ARCHIVO", "PEGAR EL TEXTO", "VOLVER"], "el menú del origen: %s" % [MENUS])

	Plataforma.PRUEBA_ABIERTO = guardada
	MENUS = []
	LOG = []
	QUIERO = ["ABRIR", "Cargar"]
	J.plat().enviados = []
	chk(corre(func(): await J.importar(true)), "bloqueo abriendo el archivo")
	chk(J.plat().enviados.has("abre_doc"), "se ha pedido el archivo: %s" % [J.plat().enviados])
	chk(FileAccess.file_exists(Juego.GUARDADO), "la partida del archivo, guardada")
	var sv = J.load_save()
	chk(sv is Dictionary and int(sv.day) == int(J.S.day), "la partida cargada es la del archivo")

	Plataforma.PRUEBA_ABIERTO = ""   # lo deja: ni aviso ni cambio
	MENUS = []
	LOG = []
	QUIERO = ["ABRIR"]
	chk(corre(func(): await J.importar(true)), "bloqueo dejando el archivo")
	chk(LOG.is_empty(), "si deja el archivo, no dice nada: %s" % [LOG])

	PEGO = guardada   # PEGAR EL TEXTO sigue valiendo
	MENUS = []
	LOG = []
	QUIERO = ["PEGAR", "Cargar"]
	chk(corre(func(): await J.importar(true)), "bloqueo pegando el texto")
	chk(dice("Partida cargada"), "pegada y cargada: %s" % [LOG])

	# 4 · en el título, sin partida guardada, RECUPERAR PARTIDA a la vista
	borra_guardado()
	chk(J.load_save() == null, "sin partida guardada")
	MENUS = []
	QUIERO = []
	TECLA = "B"   # B cierra el menú del título (si no, el bucle no acaba)
	chk(corre(func(): await J._title_press()), "bloqueo en el título")
	chk(MENUS.size() and MENUS[0] == ["NUEVA PARTIDA", "RECUPERAR PARTIDA", "OPCIONES", "CRÉDITOS"], "el título sin partida: %s" % [MENUS[0] if MENUS.size() else []])
	Datos.CAL = false
	MENUS = []
	QUIERO = []
	chk(corre(func(): await J._title_press()), "bloqueo en el título sin CAL")
	chk(MENUS.size() and not MENUS[0].has("RECUPERAR PARTIDA"), "sin CAL, el título de antes: %s" % [MENUS[0] if MENUS.size() else []])

	print("migracion: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  ✗ " + f)
	quit(1 if fallos.size() else 0)
