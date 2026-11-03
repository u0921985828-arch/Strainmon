# Ribera Verde (Godot) — 0.77: lo que quedaba del repaso de estructura, con CAL: la cuota de Molina por lo facturado, la tarifa
# de potencia de la luz, el rendimiento de la lavadora y la static y el tope del rosin, y lo que paga cada ruta del mar.
#   $GODOT --headless --path godot --script res://tests/pendientes.gd   → «pendientes: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Motor = preload("res://src/motor.gd")

var J
var M
var MENUS := []
var LOG := []
var QUIERO := ""
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
	for i in labels.size():
		if QUIERO != "" and labels[i].begins_with(QUIERO):
			k = i
	QUIERO = ""
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
			print("  bloqueo: fin %s libre %s lock %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.lock, J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-pend.json"
	Juego.AJUSTES = "user://prueba-pend-ajustes.json"
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nevera-dentro":
			e = Datos.enteros(x)
	J = Juego.new()
	J.oraculo = true
	root.add_child(J)
	M = J.M
	J.show_title()
	J.S = e.S
	J.enter_map(J.S.map, int(e.P.x), int(e.P.y), e.P.dir)
	J.mode = "world"
	J.gancho_menu = _menu
	J.gancho_texto = func(t, nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = J.D
	var Cultivo = J.Cultivo
	# 1 · la cuota de Molina: el mínimo de siempre si no has facturado, y el 5 %% de lo facturado desde el último pago
	J.S.sales = 0
	J.S.molS = 0
	chk(J.cuota_molina() == int(D.SOBORNO), "sin ventas, la de siempre: %s" % J.cuota_molina())
	J.S.sales = 400000
	chk(J.cuota_molina() == Datos.jsround(400000 * float(D.CUOTA_PCT)), "con 400.000 facturados: %s" % J.cuota_molina())
	J.S.molS = 380000
	chk(J.cuota_molina() == int(D.SOBORNO), "pagada hace poco, vuelve al mínimo: %s" % J.cuota_molina())
	J.S.molS = 100000
	chk(J.cuota_molina() == Datos.jsround(300000 * float(D.CUOTA_PCT)), "solo lo de después del pago: %s" % J.cuota_molina())
	Datos.CAL = false
	chk(J.cuota_molina() == int(D.SOBORNO), "sin CAL, la fija: %s" % J.cuota_molina())
	Datos.CAL = true
	# 2 · la tarifa de potencia: lo enchufado por encima de POTENCIA.gratis se paga al día
	var P: Dictionary = D.POTENCIA
	var S2 := {"carpas": [null, null, null], "sala": {}, "bandejas": []}
	chk(Cultivo.potencia_w(S2) == 0, "sin nada enchufado: %s" % Cultivo.potencia_w(S2))
	chk(Cultivo.factura_potencia(S2) == 0, "y no se paga nada: %s" % Cultivo.factura_potencia(S2))
	var fk: String = D.FOCOS.keys()[D.FOCOS.size() - 1]
	S2.carpas[0] = {"foco": fk}
	var w: int = Cultivo.potencia_w(S2)
	chk(w == int(float(D.FOCOS[fk].w)), "un foco de %s W: %s" % [D.FOCOS[fk].w, w])
	var esp_p: int = Datos.jsround(ceilf(maxf(0, w - float(P.gratis)) / float(P.paso)) * float(P.eur))
	chk(Cultivo.factura_potencia(S2) == esp_p, "la tarifa: %s (%d)" % [Cultivo.factura_potencia(S2), esp_p])
	# tres carpas con el foco más gordo, sus filtros y el aire pasan del contratado y cuestan todos los días
	S2.carpas[1] = {"foco": fk, "filtro150": 1}
	S2.carpas[2] = {"foco": fk, "filtro150": 1}
	S2.sala = {"aire": 1}
	var w3: int = w * 3 + 2 * int(float(D.EXTRAS.filtro150.w)) + int(float(D.APARATOS.aire.w))
	chk(Cultivo.potencia_w(S2) == w3, "tres carpas con filtro y aire: %s (%d)" % [Cultivo.potencia_w(S2), w3])
	chk(w3 > int(float(P.gratis)) and Cultivo.factura_potencia(S2) > 0, "y la tarifa se paga: %s" % Cultivo.factura_potencia(S2))
	var esp3: int = Datos.jsround(ceilf((w3 - float(P.gratis)) / float(P.paso)) * float(P.eur))
	chk(Cultivo.factura_potencia(S2) == esp3, "por escalones: %s (%d)" % [Cultivo.factura_potencia(S2), esp3])
	# el carro de esquejes también cuenta
	S2.bandejas = [{}]
	chk(Cultivo.potencia_w(S2) == w3 + int(float(D.CARRO.w)), "con el carro: %s" % Cultivo.potencia_w(S2))
	Datos.CAL = false
	chk(Cultivo.factura_potencia(S2) == 0, "sin CAL no hay tarifa: %s" % Cultivo.factura_potencia(S2))
	Datos.CAL = true
	# 3 · las extracciones: la lavadora y la static rinden lo que cuestan (rendc), y el rosin llega a topec
	for k in ["lava", "stat"]:
		var E: Dictionary = D.EXTR[k]
		chk(E.has("rendc") and float(E.rendc) > float(E.rend), "%s con rendc por encima: %s de %s" % [k, E.get("rendc"), E.rend])
		var g: float = J.sale_extr(E, 100.0, 1.0)
		var e_g: float = maxf(.1, Datos.jsround(100.0 * float(E.rendc) * 10) / 10.0)
		chk(absf(g - e_g) < .01, "%s de 100 g: %s (%s)" % [k, g, e_g])
	var R: Dictionary = D.EXTR.rosin
	chk(R.has("topec") and float(R.topec) > float(R.tope), "el rosin con topec: %s de %s" % [R.get("topec"), R.tope])
	# 4 · el mar: cada ruta paga pxc, por debajo del club
	for rt in D.MAR.rutas:
		chk(J.mar_px(rt) == float(rt.pxc) and float(rt.pxc) < float(rt.px), "%s paga %s (antes %s)" % [rt.n, J.mar_px(rt), rt.px])
	Datos.CAL = false
	chk(J.mar_px(D.MAR.rutas[0]) == float(D.MAR.rutas[0].px), "sin CAL, el de antes: %s" % J.mar_px(D.MAR.rutas[0]))
	Datos.CAL = true
	# y la bodega del atunero, más corta
	for B in D.MAR.barcos:
		if B.k == "atunero":
			chk(int(J.barco_k("atunero").kg) == int(B.kgc), "el atunero carga %s" % J.barco_k("atunero").kg)
	# 5 · la tarifa se cobra de verdad al pasar el día (Cultivo.avanza), no solo en el menú
	var molde: Dictionary = {}
	for c in J.S.carpas:
		if c:
			molde = c
	J.S.carpas = []
	for i in 3:
		var c: Dictionary = molde.duplicate(true)
		c.foco = fk
		c["filtro150"] = 1
		J.S.carpas.append(c)
	J.S.sala = {"aire": 1}
	var pot: int = Cultivo.factura_potencia(J.S)
	chk(pot > 0, "la tarifa de esta casa: %s" % pot)
	chk(J.factura_luz() >= pot, "el menú la cuenta: %s de %s" % [J.factura_luz(), pot])
	J.S.min = 23 * 60
	J.S.banco = 100000
	var b0: float = J.S.banco
	var luz: int = Cultivo.avanza(J.S, 120)
	chk(luz >= pot and absf(b0 - J.S.banco - luz) < 1, "cobrada al pasar el día: %d de la cuenta (%d de tarifa)" % [luz, pot])
	# 6 · los locales de 30.000 € rinden lo que cuestan
	for k in ["mendi", "erro"]:
		var N: Dictionary = D.NEGOCIO.k[k]
		chk(N.has("basec") and float(N.basec) > float(D.NEGOCIO.k.rv.base), "%s vende más que el lavadero de 3.000 €: %s" % [k, N.get("basec")])
		chk(N.has("genc") and float(N.genc) > float(N.gen), "%s con su género: %s de %s" % [k, N.get("genc"), N.gen])
	for x in fallos:
		print("  FALLO ", x)
	print("pendientes: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos.size() else 0)
