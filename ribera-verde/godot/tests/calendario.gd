# Ribera Verde (Godot) — 1.42: el calendario (el día 1 es el lunes 20 de abril de 2026; semanas de 7, meses con sus días y los
# bisiestos) y el mapa de la comarca en croquis (croquis.gd). Sin oráculo del HTML (congelado en la 1.37): parte del S de casa-carro.
#   $GODOT --headless --path godot --script res://tests/calendario.gd   → «calendario: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también cal-<caso>.png y mapa-<caso>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")
const Croquis = preload("res://src/croquis.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false   # la versión entera (con PLAY, las de Google Play: tests/play.gd)
	_corre.call_deferred()

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func foto(dir: String, k: String) -> void:
	for q in 2:   # la primera vez el cuadro del texto se coloca en el siguiente fotograma
		await process_frame
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join(k + ".png"))

# 1.43 (lo pidió el usuario): centrado como la nevera y la caja, a lo ancho y en lo que deja el cuadro del texto, sin que lo pise
func centrado(k: String, o: Vector2i, w: int, h: int) -> void:
	var al: int = J.alto_libre()
	chk(abs(J.SW - w - 2 * o.x) <= 1, "%s, a lo ancho: x %d en %d" % [k, o.x, J.SW])
	chk(o.y + h <= al and abs(al - h - 2 * o.y) <= 4 or o.y <= 2, "%s, a lo alto: y %d, h %d, libre %d" % [k, o.y, h, al])
	chk(al >= 116, "%s: el cuadro del texto deja %d px" % [k, al])

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-cal.json"
	Juego.AJUSTES = "user://prueba-cal-ajustes.json"
	Datos.CAL = true
	# 1 · las fechas
	var f := Datos.fecha(1)
	chk(f.y == 2026 and f.m == 4 and f.d == 20 and f.s == 0, "día 1: %s" % [f])
	chk(Datos.fd_larga(1) == "lunes, 20 de abril de 2026", Datos.fd_larga(1))
	for d in range(1, 800):
		if Datos.fecha(d + 7).s != Datos.fecha(d).s:
			chk(false, "semana de 7 en el día %d" % d)
			break
	chk(Datos.fd(12, 1) == "1 de mayo", "día 12: " + Datos.fd(12, 1))
	chk(Datos.fecha(Datos.dia_de(2026, 12, 31) + 1).y == 2027 and Datos.fecha(Datos.dia_de(2026, 12, 31) + 1).m == 1, "año nuevo")
	chk(Datos.fecha(Datos.dia_de(2028, 2, 28) + 1).d == 29 and Datos.fecha(Datos.dia_de(2027, 2, 28) + 1).m == 3, "bisiestos")
	chk(Datos.dia_de(2027, 4, 20) - Datos.dia_de(2026, 4, 20) == 365 and Datos.dia_de(2029, 4, 20) - Datos.dia_de(2028, 4, 20) == 365, "años de 365")
	var cuenta := 0
	for m in 12:
		cuenta += Datos.dias_mes(2028, m + 1)
	chk(cuenta == 366, "2028, 366 días: %d" % cuenta)
	chk(Datos.fd(Datos.dia_de(2027, 1, 3), 1) == "3 de enero de 2027", "con el año si cambia: " + Datos.fd(Datos.dia_de(2027, 1, 3), 1))
	chk(Datos.fd_hud(1) == "LUN 20 ABR" and Datos.fd_corto(12) == "1 may", Datos.fd_hud(1) + " / " + Datos.fd_corto(12))
	# 2 · el mes del clima, el del calendario
	chk(Cultivo.mes_de(1) == 3 and Cultivo.mes_de(12) == 4 and Cultivo.mes_de(Datos.dia_de(2027, 1, 15)) == 0, "mes_de")
	# 3 · sin calendario (las pruebas contra el HTML), como antes
	Datos.CAL = false
	chk(Datos.fd(12, 1) == "día 12" and Datos.fd_hud(12) == "DÍA 12" and Cultivo.mes_de(1) == int(Datos.carga().MES0), "CAL = false")
	Datos.CAL = true
	# 4 · la partida
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "casa-carro":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	J.S.day = 1
	J.S.due = 1500
	J.S.deadline = 12
	var mk: Array = J.marcas_cal()
	chk(mk.any(func(x): return x.d == 12 and x.t.begins_with("plazo")), "el plazo, señalado: %s" % [mk])
	var V := {"y": 2026, "m": 4}
	var rs: Array = Croquis.rects_cal(J.SW, V, 1, mk)
	chk(rs.all(func(r): return r[0] >= 0 and r[1] >= 0 and r[0] + r[2] <= J.SW and r[1] + r[3] <= 120), "el calendario, dentro")
	chk(rs.filter(func(r): return r[4] == "#f8d040").size() == 1, "hoy, marcado")
	chk(Croquis.desc_cal({"y": 2026, "m": 5}, 1, mk).contains("12, plazo") == false and Croquis.desc_cal({"y": 2026, "m": 5}, 1, mk).contains("1, plazo"), "el plazo en mayo: " + Croquis.desc_cal({"y": 2026, "m": 5}, 1, mk))
	chk(Croquis.mueve_cal(V, "left") and V.m == 3 and Croquis.mueve_cal(V, "right") and Croquis.mueve_cal(V, "right") and V.m == 5, "meses %s" % [V])
	V = {"y": 2026, "m": 12}
	Croquis.mueve_cal(V, "right")
	chk(V.y == 2027 and V.m == 1, "de diciembre a enero %s" % [V])
	for y in [2026, 2027, 2028]:
		for m in range(1, 13):
			var r2: Array = Croquis.rects_cal(J.SW, {"y": y, "m": m}, 1, [])
			var oc := Croquis.origen_cal(J.SW, {"y": y, "m": m})
			if abs(Croquis.LIBRE - Croquis.alto_cal({"y": y, "m": m}) - 2 * oc.y) > 4:
				chk(false, "%d-%d sin centrar: %d" % [y, m, oc.y])
			if not r2.all(func(r): return r[1] + r[3] <= 120):
				chk(false, "%d-%d se sale" % [y, m])
	# 5 · el mapa: seis pueblos, los cerrados en gris, el marco y la chincheta dentro
	var im0 := Croquis.imagen(J.D, 0)
	var im8 := Croquis.imagen(J.D, 8)
	chk(im0.get_width() == Croquis.MW and im0.get_height() == Croquis.MH, "tamaño del croquis")
	var p: Array = Croquis.PUEBLOS.ibarbide.p
	var dif := 0
	for yy in range(-6, 6):
		for xx in range(-8, 8):
			if im0.get_pixel(p[0] + xx, p[1] + yy) != im8.get_pixel(p[0] + xx, p[1] + yy):
				dif += 1
	chk(dif > 10, "Ibarbide, en gris antes del capítulo 4: %d" % dif)
	for k in Croquis.ORDEN:
		var q: Array = Croquis.PUEBLOS[k].p
		chk(not Croquis.es_mar(q[0], q[1]), k + " en tierra")
	# 5b · los caminos (lo pidió el usuario: «en el mapa se deberían de ver los caminos que conectan los pueblos»): desde Ribera
	# Verde, por los píxeles de camino, se llega a todos los pueblos
	var CAM := [Croquis.C_BORDE, Croquis.C_CENTRO, Croquis.C_PUENTE, Croquis.C_PISTA]
	var PASA := CAM + [Color8(226, 212, 172), Color8(40, 30, 24), Color8(120, 114, 104), Color8(122, 58, 40), Color8(160, 150, 130)]   # y por debajo de los rótulos
	var ini: Vector2 = Croquis.camino_pts(Croquis.CAMINOS[0])[12]
	var vis := {Vector2i(ini): true}
	var cola := [Vector2i(ini)]
	while cola.size():
		var a: Vector2i = cola.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			var b: Vector2i = a + d
			if b.x < 0 or b.y < 0 or b.x >= Croquis.MW or b.y >= Croquis.MH or vis.has(b) or not PASA.has(im8.get_pixel(b.x, b.y)):
				continue
			vis[b] = true
			cola.append(b)
	chk(vis.keys().filter(func(v): return CAM.has(im8.get_pixel(v.x, v.y))).size() > 500 and CAM.has(im8.get_pixel(int(ini.x), int(ini.y))), "hay caminos en el croquis (%d px)" % vis.size())
	for k in Croquis.ORDEN:
		var q: Array = Croquis.PUEBLOS[k].p
		var llega := false
		var dm := 999.0
		for v in vis:
			dm = minf(dm, Vector2(v).distance_to(Vector2(q[0], q[1])))
			if Vector2(v).distance_to(Vector2(q[0], q[1])) <= 12:   # las casas del pueblo tapan el final
				llega = true
				break
		chk(llega, "un camino llega a %s (a %d px)" % [k, int(dm)])
	var MV := {"i": 0}
	for i in Croquis.ORDEN.size():
		var r3: Array = Croquis.rects_mapa(J.SW, MV, "town")
		chk(r3.all(func(r): return r[0] >= 0 and r[1] >= 0 and r[0] + r[2] <= J.SW and r[1] + r[3] <= 120), "marco fuera en %d" % i)
		Croquis.mueve_mapa(MV, "right")
	chk(MV.i == 0, "la vuelta entera")
	J.S.ch = 1
	chk(Croquis.desc_mapa(J.D, 1, {"i": Croquis.ORDEN.find("ibarbide")}, "town").contains("capítulo 4"), "Ibarbide cerrado")
	chk(Croquis.desc_mapa(J.D, 1, {"i": Croquis.ORDEN.find("town")}, "town").contains("Estás aquí"), "estás aquí")
	chk(Croquis.pueblo_de("nave") == "valdehierro" and Croquis.pueblo_de("disco") == "ibarbide" and Croquis.pueblo_de("home") == "town", "pueblo_de")
	# 6 · el móvil: Calendario y Mapa
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
		J.S.ch = 3
		J.CAL_V = {"y": 2026, "m": 4}
		J._dlg_fijo(Croquis.desc_cal(J.CAL_V, 1, J.marcas_cal()), "CALENDARIO")
		await foto(dir, "cal-abril")
		J.S.day = 30
		J.CAL_V = {"y": 2026, "m": 5}
		J._dlg_fijo(Croquis.desc_cal(J.CAL_V, 30, J.marcas_cal()), "CALENDARIO")
		await foto(dir, "cal-mayo")
		centrado("calendario", Croquis.origen_cal(J.SW, J.CAL_V, J.alto_libre()), 7 * Croquis.CW + 8, Croquis.alto_cal(J.CAL_V))
		J.CAL_V = null
		J.MAPA_V = {"i": 1}
		J._dlg_fijo(Croquis.desc_mapa(J.D, 3, J.MAPA_V, "town"), "")   # 1.43: sin pestaña, que no pise el croquis
		await foto(dir, "mapa-cap3")
		centrado("mapa", Croquis.origen_mapa(J.SW, J.alto_libre()), Croquis.MW, Croquis.MH)
		J.S.ch = 8
		J.MAPA_V = {"i": 2}
		J._dlg_fijo(Croquis.desc_mapa(J.D, 8, J.MAPA_V, "town"), "")   # 1.43: sin pestaña, que no pise el croquis
		await foto(dir, "mapa-cap8")
		centrado("mapa 8", Croquis.origen_mapa(J.SW, J.alto_libre()), Croquis.MW, Croquis.MH)
		J.MAPA_V = null
	for x in fallos:
		print("  FALLO ", x)
	print("calendario: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
