# Ribera Verde (Godot) — MAESTRO [5], lo que faltaba (con Datos.CAL): las familias de la CannaDex y su bono (FAMILIAS, S.cult,
# Cultivo.fam), la CannaCup por calendario con el prestigio (CUP, S.cup, S.prest) y la potencia contratada (ENERGIA, S.ener).
# Sin oráculo del HTML (congelado en la 1.37): parte del S de la pantalla casa-extr.
#   $GODOT --headless --path godot --script res://tests/familias.gd   → «familias: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Cultivo = preload("res://src/cultivo.gd")

var J
var M
var S
var D
var n := 0
var fallos := []
var DICHO := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func _menu(items: Array, o: Dictionary) -> Dictionary:
	o = o.duplicate()
	o.initial = 0 if String(o.get("title", "")).begins_with("¿Qué") else items.size() - 1
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
			return false
	return true

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-familias.json"
	Juego.AJUSTES = "user://prueba-familias-ajustes.json"
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
	J.gancho_texto = func(t, _nm): DICHO.append(str(t))
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)

	# 1 · las familias cubren la CannaDex entera, sin repetir
	var vistas := {}
	var rep := 0
	for k in D.FAMILIAS:
		for sid in D.FAMILIAS[k].s:
			if vistas.has(sid):
				rep += 1
			vistas[sid] = k
			chk(D.STRAINS.has(sid), "familia %s: %s existe" % [k, sid])
	chk(rep == 0, "ninguna variedad en dos familias")
	for sid in D.DEX:
		chk(vistas.has(sid), "%s tiene familia" % sid)

	# 2 · sin nada cosechado, sin bono (×1: lo de antes no cambia); con la familia entera, su bono
	S.erase("cult")
	var p := {"sid": "ria", "health": 100, "f": {"id": 7, "t": 1, "y": 1}}
	var f := {"g": 40.0, "cap": 999.0, "thc": 0.0}
	var g0: int = Cultivo.gramos_planta(S, p, f)
	var t0: float = Cultivo.thc_cosecha(S, p, f)
	S.cult = {}
	chk(Cultivo.fam(S, "g") == 0.0 and Cultivo.gramos_planta(S, p, f) == g0, "S.cult vacío: los mismos gramos")
	var sk: Array = D.FAMILIAS.skunk.s
	for j in sk.size() - 1:
		J.cult_apunta(sk[j])
	chk(not Cultivo.fam_llena(S, "skunk") and Cultivo.fam(S, "g") == 0.0, "a falta de una, sin bono")
	J.pending.clear()
	J.queued.clear()
	J.cult_apunta(sk[sk.size() - 1])
	chk(Cultivo.fam_llena(S, "skunk"), "la familia Skunk, completa")
	chk(is_equal_approx(Cultivo.fam(S, "g"), float(D.FAMILIAS.skunk.v)), "bono de gramos = %s" % Cultivo.fam(S, "g"))
	chk(J.queued.has("famskunk"), "el aviso de la familia completa en la cola")
	var g1: int = Cultivo.gramos_planta(S, p, f)
	chk(g1 > g0, "con el bono, más gramos (%d → %d)" % [g0, g1])
	chk(Cultivo.thc_cosecha(S, p, f) == t0, "el bono de gramos no toca el THC")
	for sid in D.FAMILIAS.haze.s:
		S.cult[sid] = 1
	chk(Cultivo.thc_cosecha(S, p, f) > t0, "con las Haze, más THC")
	Datos.CAL = false
	chk(Cultivo.fam(S, "g") == 0.0 and Cultivo.gramos_planta(S, p, f) == g0, "sin CAL, sin bono")
	Datos.CAL = true
	chk(J.fam_cuenta() == [2, D.FAMILIAS.size()], "2 familias completas de %d" % D.FAMILIAS.size())
	var dm: float = Cultivo.fam(S, "res")
	chk(dm == 0.0, "sin las del Kush, sin bono contra el moho")

	# 3 · la CannaCup: el 15 de marzo, junio, septiembre y diciembre, desde el capítulo 7
	var jun := Datos.dia_de(2026, 6, 15)
	S.ch = 7
	S.day = 1
	chk(J.cup_proxima() == jun, "la primera, el 15 de junio de 2026 (%d)" % J.cup_proxima())
	chk(J.cup_es(jun) and not J.cup_es(jun - 1) and not J.cup_es(jun + 1), "solo ese día")
	chk(J.cup_es(Datos.dia_de(2026, 9, 15)) and J.cup_es(Datos.dia_de(2026, 12, 15)) and J.cup_es(Datos.dia_de(2027, 3, 15)), "cada trimestre")
	chk(not J.cup_es(Datos.dia_de(2026, 7, 15)), "julio, no")
	S.ch = 6
	chk(not J.cup_es(jun), "en el capítulo 6, la Copa de la historia, no la CannaCup")
	S.ch = 7
	S.day = jun - int(D.CUP.aviso)
	J.queued.clear()
	J.cup_aviso()
	chk(J.queued.has("cup"), "el SMS, a %d días" % int(D.CUP.aviso))
	S.day = jun - 1
	J.queued.clear()
	J.cup_aviso()
	chk(not J.queued.has("cup"), "la víspera, sin SMS")
	S.day = jun
	chk(J.cup_hoy(), "hoy es la CannaCup")
	chk(J.cup_marcas().size() == 1 and int(J.cup_marcas()[0].d) == jun, "en el calendario")
	var P: Dictionary = J.cup_perfil(J.cup_ed(jun))
	chk(P.t in [0, 1, 2] and P.a in D.AROMAS, "un perfil por edición")
	chk(J.cup_perfil(J.cup_ed(jun)) == P, "el mismo perfil siempre (por hash)")
	var rv: Array = J.cup_rivales(J.cup_ed(jun))
	chk(rv.size() == 3, "tres rivales")
	for r in rv:
		chk(r[1] >= float(D.CUP.rival[0]) and r[1] <= float(D.CUP.rival[1]), "rival %s en su rango: %s" % [r[0], r[1]])
	# sin tarro curado no se compite
	S.buds = {"ria": {"g": 30.0, "thc": 31.0, "dia": jun - 3}}
	var m0: float = S.money
	S.erase("prest")
	S.erase("cup")
	chk(corre(J.talk_cup), "talk_cup sin curar")
	chk(float(S.buds.ria.g) == 30.0 and S.money == m0, "sin curar: ni se gasta ni se cobra")
	# curado del todo: 31 % gana
	S.buds.ria.cu = 1.0
	chk(corre(J.talk_cup), "talk_cup")
	chk(is_equal_approx(float(S.buds.ria.g), 30.0 - float(D.CUP.g)), "se presentan %d g" % int(D.CUP.g))
	chk(S.money == m0 + float(D.CUP.premio[0]), "el premio del primero")
	chk(int(S.get("prest", 0)) == int(D.CUP.prest[0]), "prestigio %d" % int(S.get("prest", 0)))
	chk(J.cup_trofeos().size() == 1 and int(J.cup_trofeos()[0].pl) == 1, "el trofeo")
	chk(int(S.prest) >= int(D.CUP.vip), "con un primer puesto, ya llega para los VIP")
	# una vez por edición
	var m1: float = S.money
	chk(corre(J.talk_cup), "talk_cup otra vez")
	chk(S.money == m1 and J.cup_trofeos().size() == 1, "una vez por edición")
	# flojo: sin podio
	S.day = Datos.dia_de(2026, 9, 15)
	S.buds = {"ria": {"g": 30.0, "thc": 12.0, "cu": 1.0, "dia": 1}}
	chk(corre(J.talk_cup), "talk_cup flojo")
	chk(J.cup_trofeos().size() == 1 and int(S.cup.ed[str(J.cup_ed(S.day))]) == 4, "12 %: cuarto, sin trofeo")
	# el jurado sale en la plaza ese día
	var jd: Dictionary = {}
	for d in D.NPCDEF:
		if d.id == "jurado":
			jd = d
	chk(J.npc_cond(jd), "el jurado, en la plaza el día de la CannaCup")
	S.day += 1
	chk(not J.npc_cond(jd), "y al día siguiente, no")

	# 4 · la potencia contratada
	var E: Dictionary = D.ENERGIA
	S.sala = {"calef": true, "aire": true}
	S.carpas = []
	S.pots = []
	S.erase("ener")
	S.erase("nave")
	chk(J.carga_w("casa") == 2400, "calefactor y aire: 2,4 kW (%d)" % J.carga_w("casa"))
	var lim0: int = int(E.casa.lim)
	E.casa.lim = 0
	var h0 := 20
	S.heat = h0
	var av := []
	J.energia_dia(av)
	chk(int(S.heat) == h0 + 3 * int(E.calor), "2,4 kW de más: calor +%d (%d)" % [3 * int(E.calor), int(S.heat)])
	chk(av.size() == 1, "con su aviso")
	S.ener = {"casa": {"pl": int(S.day)}}
	S.heat = h0
	av = []
	J.energia_dia(av)
	chk(int(S.heat) == h0 and av.is_empty(), "con las placas (2,5 kW), nada")
	S.ener = {"casa": {"gen": int(S.day)}}
	S.heat = h0
	S.money = 100
	av = []
	J.energia_dia(av)
	var gas: int = Datos.jsround(2.4 * float(E.h) * float(E.gen.kwh))
	chk(int(S.heat) == h0 and S.money == 100 - gas, "con el generador: gasóleo %d €, sin calor" % gas)
	S.money = 0
	J.energia_dia([])
	chk(int(S.heat) == h0 + 3 * int(E.calor), "sin efectivo para el gasóleo, como sin generador")
	S.ener = {"casa": {"pl": int(S.day) + 1}}
	S.heat = h0
	J.energia_dia([])
	chk(int(S.heat) > h0, "lo pedido no cuenta hasta mañana")
	Datos.CAL = false
	S.heat = h0
	J.energia_dia([])
	chk(int(S.heat) == h0, "sin CAL, nada")
	Datos.CAL = true
	E.casa.lim = lim0
	S.ener = {}
	S.heat = h0
	J.energia_dia([])
	chk(int(S.heat) == h0, "con la potencia de serie, el piso no se pasa")

	print("familias: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  FALLO: ", x)
	quit(0 if fallos.is_empty() else 1)
