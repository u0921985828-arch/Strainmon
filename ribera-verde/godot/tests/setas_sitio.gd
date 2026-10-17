# Ribera Verde (Godot) — 1.43.8: el bajo de las setas, con su sitio (lo pidió el usuario: «no existe mapa y sitio del bajo de las
# setas»): el bajo y la Kale Zaharra existían, pero nada decía dónde. Se llega andando de la parada de Ibarbide al callejón, a Txomin y
# a la puerta del bajo; con Ibarbide abierta, el SMS de Julen (una vez, y no con el bajo alquilado), MÓVIL → Mapa y el cartel de la
# Kale Zaharra lo dicen; sin Datos.CAL, nada nuevo. Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-extr.
#   $GODOT --headless --path godot --script res://tests/setas_sitio.gd   → «setas_sitio: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
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


# camino a pie por casillas pisables y sin objetos (las puertas, solo como destino)
func llega(mapa: String, de: Array, a: Array) -> bool:
	var m: Dictionary = J.MAPS[mapa]
	var v := {"%d,%d" % de: true}
	var q := [de]
	while q.size():
		var c: Array = q.pop_front()
		for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			var nx: int = c[0] + d[0]
			var ny: int = c[1] + d[1]
			if nx == a[0] and ny == a[1]:
				return true
			var kk := "%d,%d" % [nx, ny]
			if not v.has(kk) and J.pisable(m, nx, ny) and not m.o[ny][nx]:
				v[kk] = true
				q.append([nx, ny])
	return false

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-setas-sitio.json"
	Juego.AJUSTES = "user://prueba-setas-sitio-ajustes.json"
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
	var D = J.D
	var S = J.S
	var SS: Dictionary = D.SETAS_SITIO
	var Croquis = preload("res://src/croquis.gd")
	S.erase("setas")
	S.flags.erase("setasSms")
	# 1 · el sitio existe y se llega andando: de la parada de Ibarbide al callejón, y del callejón a Txomin y a la puerta del bajo
	var PA: Dictionary = D.PARADAS.ibarbide
	var mi: Dictionary = J.MAPS.ibarbide
	var mc: Dictionary = J.MAPS.callejon
	chk(J.MAPS.has("setas") and mc.doors.has("19,7") and mc.doors["19,7"].to == "setas" and mi.doors.has("19,0") and mi.doors["19,0"].to == "callejon", "mapas y puertas")
	chk(llega("ibarbide", [int(PA.a[0]), int(PA.a[1])], [19, 0]), "de la parada al callejón")
	chk(llega("callejon", [10, 16], [19, 7]), "del callejón a la puerta del bajo")
	chk(llega("callejon", [10, 16], [17, 9]), "del callejón a Txomin")
	var nt = D.NPCDEF.filter(func(x): return x.id == "txomin")
	chk(nt.size() == 1 and nt[0].map == "callejon" and int(nt[0].x) == 17 and int(nt[0].y) == 8, "Txomin en el callejón: %s" % [nt])
	# 2 · antes de Ibarbide (capítulo 3), ni SMS ni sitio en el mapa
	S.ch = int(D.SETAS.ch) - 1
	LOG = []
	chk(corre(J.check_story), "historia bloqueada (cap. 3)")
	chk(not S.flags.get("setasSms") and not " ".join(LOG).contains("Txomin"), "SMS antes de tiempo: %s" % [LOG])
	chk(not Croquis.desc_mapa(D, int(S.ch), {"i": Croquis.ORDEN.find("ibarbide")}, "town").contains(SS.mapa), "mapa antes de tiempo")
	# 3 · con Ibarbide: el SMS de Julen, una vez, apuntado en los mensajes; el mapa del móvil y el cartel lo dicen
	S.ch = int(D.SETAS.ch)
	LOG = []
	chk(corre(J.check_story), "historia bloqueada (cap. 4)")
	chk(S.flags.get("setasSms") == S.day and " ".join(LOG).contains("Kale Zaharra") and " ".join(LOG).contains("GROW IBARBIDE"), "SMS: %s" % [LOG])
	chk(JSON.stringify(S.get("sms", [])).contains("Txomin"), "el SMS, en los mensajes")
	LOG = []
	chk(corre(J.check_story), "historia bloqueada (otra vez)")
	chk(not " ".join(LOG).contains("Txomin"), "SMS repetido: %s" % [LOG])
	var dm: String = Croquis.desc_mapa(D, int(S.ch), {"i": Croquis.ORDEN.find("ibarbide")}, "town")
	chk(dm.contains(SS.mapa), "MÓVIL → Mapa: %s" % dm)
	J.enter_map("callejon", 8, 11, "up")
	J.mode = "world"
	LOG = []
	chk(corre(func(): await J.object_action(8, 10)), "cartel bloqueado")
	chk(" ".join(LOG).contains("KALE ZAHARRA") and " ".join(LOG).contains(SS.cartel), "cartel: %s" % [LOG])
	# 4 · alquilado, ya no avisa (partida nueva con el bajo)
	S.flags.erase("setasSms")
	S.setas = {"b": [], "g": 0, "r": S.day + 10}
	LOG = []
	chk(corre(J.check_story), "historia bloqueada (alquilado)")
	chk(not S.flags.get("setasSms"), "SMS con el bajo alquilado")
	S.erase("setas")
	# 5 · sin Datos.CAL (las pruebas contra el HTML): ni SMS, ni mapa, ni cartel nuevos
	Datos.CAL = false
	LOG = []
	chk(corre(J.check_story), "historia bloqueada (sin CAL)")
	chk(not S.flags.get("setasSms"), "SMS sin CAL")
	chk(not Croquis.desc_mapa(D, int(S.ch), {"i": Croquis.ORDEN.find("ibarbide")}, "town").contains(SS.mapa), "mapa sin CAL")
	LOG = []
	chk(corre(func(): await J.object_action(8, 10)), "cartel sin CAL bloqueado")
	chk(not " ".join(LOG).contains(SS.cartel), "cartel sin CAL")
	Datos.CAL = true
	for x in fallos:
		print("  FALLO ", x)
	print("setas_sitio: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
