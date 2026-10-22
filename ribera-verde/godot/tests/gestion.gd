# Landrace Hunters (Godot) — MAESTRO [6] (con Datos.CAL): la plantilla por local (lealtad de 1 a 10 con chivatos y capataz, sueldo y
# eficiencia, el contable), el olor de la nave (carbón y ozonizador), la seguridad (robos, cámaras, monitores) y el panel de KAIA.
#   $GODOT --headless --path godot --script res://tests/gestion.gd   → «gestion: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
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
			print("  bloqueo: fin %s libre %s handlers %s pend %s modo %s" % [st.fin, J.is_free(), J.handlers.size(), J.pending.size(), J.mode])
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-gestion.json"
	Juego.AJUSTES = "user://prueba-gestion-ajustes.json"
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
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var D = Datos.carga()
	var S: Dictionary = J.S
	S.ch = 6
	J.mode = "world"
	var mk := func(id: String, lea: int, rol, extra := {}) -> Dictionary:
		var w := {"id": id, "n": id.capitalize(), "lab": 3, "cui": 3, "lea": lea, "rol": rol}
		w.merge(extra, true)
		return w
	# 1 · la lealtad de 1 a 10, sus bandas y el riesgo de chivato (15, 5, 2 y 0 %)
	var w1: Dictionary = mk.call("pl1", 3, null)
	chk(J.lealtad(w1) == 6 and J.banda(2) == 0 and J.banda(3) == 0 and J.banda(4) == 1 and J.banda(7) == 1 and J.banda(8) == 2 and J.banda(9) == 2 and J.banda(10) == 3, "bandas")
	var pt := []
	for lt in [2, 5, 8, 10]:
		var c := 0
		for i in 3000:
			var w: Dictionary = mk.call("t%d_%d" % [lt, i], 1, null, {"lt": lt})
			J.tira_topo(w, "alta")
			if w.get("topo"):
				c += 1
		pt.append(c / 3000.0)
	chk(absf(pt[0] - .15) < .025 and absf(pt[1] - .05) < .015 and absf(pt[2] - .02) < .01 and pt[3] == 0.0, "chivatos por banda: %s" % [pt])
	var w2: Dictionary = mk.call("pl2", 3, null, {"lt": 9, "topo": 1})
	J.pon_lealtad(w2, 10)
	chk(not w2.get("topo") and w2.lea == 5, "con lealtad 10, ni un chivato: %s" % [w2])
	J.pon_lealtad(w2, 3)
	chk(w2.lea == 2 and w2.lt == 3, "la de 1 a 5 sigue a la de 1 a 10: %s" % [w2])
	# 2 · el sueldo bajo, normal o alto y la eficiencia
	var wn: Dictionary = mk.call("nv1", 3, "nave", {"mesa": 0})
	chk(J.sueldo_w(wn) == 30, "sueldo normal: %d" % J.sueldo_w(wn))
	wn.sm = 0
	chk(J.sueldo_w(wn) == 23, "sueldo bajo: %d" % J.sueldo_w(wn))
	wn.sm = 2
	chk(J.sueldo_w(wn) == 38, "sueldo alto: %d" % J.sueldo_w(wn))
	chk(J.eficiencia(wn) == 76 and J.eficiencia(mk.call("x", 3, "calle", {"lab": 5})) == 100, "eficiencia")
	chk(J.ficha_gente(wn).contains("/10") and J.ficha_gente(wn).contains("76 %"), "ficha: " + J.ficha_gente(wn))
	# 3 · cada mañana: con el sueldo bajo o mucho calor, la lealtad media baja; con el alto, sube hasta 9; los chivatos dan calor
	S.nave = J.nave_nueva()
	S.nave.r = 99999
	var wb: Dictionary = mk.call("nb", 3, "nave", {"mesa": 0, "sm": 0, "lt": 7, "t0": 1})
	var wa: Dictionary = mk.call("na", 3, "nave", {"mesa": 1, "sm": 2, "lt": 8, "t0": 1})
	var wt: Dictionary = mk.call("nt", 3, "madres", {"lt": 5, "topo": 1, "t0": 1})
	S.plantilla = [wb, wa, wt]
	S.heat = 0
	var d0: int = S.day
	for d in 60:
		S.day = d0 + d
		J.staff_dia()
	chk(int(wb.lt) < 7 and int(wb.lt) >= 1, "sueldo bajo, menos lealtad: %d" % wb.lt)
	chk(int(wa.lt) == 9, "sueldo alto, hasta 9: %d" % wa.lt)
	chk(int(S.heat) >= 60, "el chivato da calor: %d" % S.heat)
	chk(J.chivato_nave() == float(D.STAFF.chivato.redada), "con un chivato en la nave, la redada ×2")
	# el capataz (10) ve al chivato de su local; el de otro local, no
	S.heat = 0
	var wc: Dictionary = mk.call("nc", 3, "nave", {"mesa": 2, "lt": 10, "t0": 1})
	var wo: Dictionary = mk.call("no", 3, "gerente", {"lt": 4, "topo": 1, "t0": 1})
	S.plantilla = [wt, wc, wo]
	LOG = []
	for d in 30:
		S.day = d0 + 100 + d
		J.staff_dia()
	chk(corre(func(): pass), "la cola del capataz")
	chk(wt.get("visto") and not wo.get("visto"), "el capataz ve al de la nave y no al del piso: %s %s" % [wt.get("visto"), wo.get("visto")])
	chk(" ".join(LOG).contains(wt.n), "SMS del capataz: %s" % [LOG])
	# los de antes (sin lt ni t0): se ponen una vez
	var wv: Dictionary = {"id": "pv", "n": "Viejo", "lab": 2, "cui": 2, "lea": 4, "rol": "gerente"}
	S.plantilla = [wv]
	J.staff_dia()
	chk(int(wv.lt) == 8 and wv.get("t0") == 1, "partida vieja: %s" % [wv])
	# 4 · el sueldo, en plantilla_dia
	S.plantilla = [mk.call("ps", 3, "gerente", {"sm": 2, "lt": 6, "t0": 1})]
	S.money = 1000
	S.pots = []
	J.plantilla_dia()
	chk(int(S.money) == 1000 - 50, "el gerente con sueldo alto cobra 50: %s" % S.money)
	# 5 · el contable: cada mañana, el efectivo a la caja de su local menos su comisión; al día siguiente, a la cuenta
	S.loc = {"mendi": {"r": S.day + 30, "caja": 0, "dia": 0, "tot": 0}}
	var wk: Dictionary = mk.call("ck", 3, null, {"lt": 6, "t0": 1, "lab": 5})
	S.plantilla = [wk]
	QUIERO = ["De contable", D.LOCALES.mendi.n]
	chk(corre(func(): await J.trabajo(wk)), "de contable")
	chk(wk.rol == "contable" and wk.loc == "mendi", "contable del local: %s" % [wk])
	S.money = 10000
	S.banco = 0
	J.contable_dia()
	var tope: int = J.neg_tope("mendi")
	var com: int = roundi(tope * float(D.STAFF.contable.com))
	chk(int(S.money) == 10000 - tope and is_equal_approx(float(S.loc.mendi.caja), tope - com), "metido %s, caja %s (tope %d)" % [S.money, S.loc.mendi.caja, tope])
	J.contable_dia()
	chk(int(S.money) == 10000 - tope, "una vez al día: el tope")
	S.day += 1
	J.recibos_dia()
	chk(int(S.banco) >= roundi((tope - com) * (1 - float(D.LOCALES.mendi.com))), "al día siguiente, a la cuenta: %s" % S.banco)
	chk(J.rol_txt(wk).contains(D.LOCALES.mendi.n), "rol: " + J.rol_txt(wk))
	# 6 · el olor: el carbón se gasta (más con lluvia), saturado huele como sin filtro, con ozono nada; en la sala, sin terpenos
	S.nave.ex = 1
	S.nave.cb = 100.0
	J.carbon_dia()
	chk(float(S.nave.cb) < 100.0, "el carbón se gasta: %s" % S.nave.cb)
	chk(is_equal_approx(J.olor_nave(), float(D.EXTR_NAVE[1].olor)), "con carbón, el filtro")
	S.nave.cb = 0.0
	chk(J.olor_nave() == 1.0, "saturado, como sin filtro")
	S.nave.cb = 50.0
	S.nave.oz = "tubo"
	chk(J.olor_nave() == 0.0, "con el ozonizador en el conducto, nada")
	S.nave.oz = "sala"
	S.nave.m[0] = {"k": "ria", "g": 10.0, "t": 18.0, "abo": 0}
	S.buds = {}
	chk(corre(func(): await J.secadero_nave()), "descolgar")
	var bz: Dictionary = S.buds.get("ria", {})
	chk(bz.get("oz") == 1 and is_equal_approx(J.calidad(bz), float(D.OLOR_NAVE.oz_q)), "con el ozono en la sala, sin terpenos: %s" % [bz])
	S.nave.oz = ""
	QUIERO = ["Cambiar el carbón", "Nada"]
	S.banco = 1000
	S.nave.cb = 3.0
	chk(corre(func(): await J.olor_menu()), "el menú del olor")
	chk(float(S.nave.cb) == 100.0 and int(S.banco) == 1000 - int(D.OLOR_NAVE.carbon.p), "carbón nuevo: %s %s" % [S.nave.cb, S.banco])
	# 7 · la seguridad: cada cosa baja el robo; con cámaras se recupera la mitad y en la redada tu gente sale por detrás
	S.seg = {}
	chk(is_equal_approx(J.prob_robo("mendi"), float(D.SEGURIDAD.robo)), "robo sin nada")
	S.banco = 100000
	QUIERO = ["Puerta blindada", "Comprar", "Alarma", "Comprar", "Perro", "Comprar", "Volver"]
	chk(corre(func(): await J.seguridad_local("mendi")), "comprar seguridad")
	chk(is_equal_approx(J.prob_robo("mendi"), float(D.SEGURIDAD.robo) * .4 * .5 * .5), "con puerta, alarma y perro: %s" % J.prob_robo("mendi"))
	S.seg = {}
	var robos := 0
	var d1: int = S.day
	for d in 1000:
		S.day = d1 + d
		S.loc.mendi.caja = 200.0
		S.loc.mendi.dia = S.day
		J.robos_dia()
		if float(S.loc.mendi.caja) < 200:
			robos += 1
	chk(robos > 5 and robos < 40, "robos sin seguridad en 1000 días: %d" % robos)
	S.seg = {"mendi": {"ca": 1}}
	var rec := false
	for d in 1000:
		S.day = d1 + d
		S.loc.mendi.caja = 200.0
		S.loc.mendi.dia = S.day
		J.robos_dia()
		if float(S.loc.mendi.caja) < 200:
			rec = float(S.loc.mendi.caja) == 100.0
			break
	chk(rec, "con cámaras, la mitad: %s" % S.loc.mendi.caja)
	chk(corre(func(): pass), "cola de robos")
	S.seg = {"nave": {"ca": 1}}
	S.nave.oz = ""
	S.nave.cb = 100.0
	var nv: Dictionary = mk.call("nr", 3, "nave", {"mesa": 0, "lt": 6, "t0": 1})
	S.plantilla = [nv]
	S.nave.m[0] = {"k": "ria", "g": 0.0, "t": 18.0, "abo": 0, "p": 0.3}
	S.money = 1000
	Cultivo.fijo = 0.0
	J.plantilla_dia()
	Cultivo.fijo = -1
	chk(S.get("nave") == null and S.plantilla.size() == 1 and nv.get("rol") == null, "redada con cámaras: la gente se queda: %s" % [S.plantilla])
	chk(corre(func(): pass), "cola de la redada")
	# los monitores
	S.nave = J.nave_nueva()
	S.nave.r = 99999
	S.seg = {"nave": {"ca": 1}}
	MENUS = []
	QUIERO = []
	chk(corre(func(): await J.monitores()), "monitores")
	chk(MENUS.size() and MENUS[0].has("La nave") and MENUS[0].has(D.LOCALES.mendi.n), "monitores: %s" % [MENUS])
	# 8 · la plantilla por local, en cuadrícula
	S.plantilla = [mk.call("g1", 3, "gerente", {"lt": 6, "t0": 1}), mk.call("n1", 4, "nave", {"mesa": 0, "lt": 8, "t0": 1, "visto": 1, "topo": 1})]
	MENUS = []
	QUIERO = ["La nave", "Volver", "Volver"]
	chk(corre(func(): await J.plantilla()), "plantilla por local")
	chk(MENUS.size() >= 2 and MENUS[0].has("El piso") and MENUS[0].has("La calle") and MENUS[0].has("La nave") and MENUS[0].has(D.LOCALES.mendi.n) and MENUS[0].has("Sin trabajo"), "los locales: %s" % [MENUS[0] if MENUS.size() else []])
	chk(MENUS.size() >= 2 and MENUS[1][0].begins_with("(!)"), "el chivato visto, marcado: %s" % [MENUS[1] if MENUS.size() > 1 else []])
	var fs: Dictionary = J.fila_staff(S.plantilla[1])
	chk(String(fs.right).contains("L8") and String(fs.right).contains("30 €") and String(fs.right).contains(" %"), "la fila: %s" % fs.right)
	# 9 · KAIA, con el panel del dispensario de la asociación; su almacén vende cada mañana
	S.mar = {"b": ["txalupa"], "rep": 0, "kg": 0.0, "env": [], "ped": null, "pd": 0, "paso": 0, "fin": 0, "n": 0, "oba": {}}
	S.buds = {"ria": {"g": 50.0, "thc": 18.0}}
	MENUS = []
	var lv: String = String(J.venta_item(J.lotes_venta(1, 1)[0]).label)
	QUIERO = ["Nada"]
	chk(corre(func(): await J.talk_kaia("ENCARGADA")), "KAIA")
	# el almacén va por su puerta (repaso.gd): el panel ya no lo lleva
	chk(MENUS.size() and MENUS[0].has("El dispensario") and not MENUS[0].has("El almacén"), "el panel de KAIA: %s" % [MENUS])
	MENUS = []
	QUIERO = ["Guardar", lv, "Nada", "Nada"]
	chk(corre(func(): await J.almacen_club("muelle")), "el almacén de KAIA")
	chk(J.alm_g("muelle") > 0 and J.alm_g("rv") == 0, "al almacén de KAIA: %s" % J.alm_g("muelle"))
	var m0: float = S.money
	J.almacen_dia("muelle")
	chk(S.money > m0, "los socios de KAIA retiran: %s" % [S.money - m0])
	J.aso().pres = true
	MENUS = []
	QUIERO = ["El dispensario", "Nada", "Nada"]
	chk(corre(func(): await J.talk_delroy()), "Delroy")
	chk(MENUS.size() >= 2 and MENUS[1] == ["El dispensario", "Nada"], "el mismo panel en la asociación: %s" % [MENUS])
	# 10 · sin CAL: como antes
	Datos.CAL = false
	D = Datos.carga()
	var wz: Dictionary = mk.call("z", 3, "nave", {"sm": 0, "mesa": 0})
	chk(J.sueldo_w(wz) == 30 and J.ficha_gente(wz) == "Labia 3 · cuidado 3 · lealtad 3", "sin CAL, la ficha y el sueldo de antes: %s" % J.ficha_gente(wz))
	S.nave.ex = 1
	S.nave.cb = 0.0
	chk(J.olor_nave() == float(D.EXTR_NAVE[1].olor) and J.chivato_nave() == 1.0, "sin CAL, el olor de antes")
	S.plantilla = [wz]
	J.staff_dia()
	chk(wz.get("lt") == null, "sin CAL, sin lealtad nueva")
	print("gestion: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO ", f)
	J.queue_free()
	quit(1 if fallos.size() else 0)
