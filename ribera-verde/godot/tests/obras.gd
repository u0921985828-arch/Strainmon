# Ribera Verde (Godot) — 1.52: las obras del muelle, el club KAIA y la ley (lo pidió el usuario: «el barrio del puerto viejo… comenzar
# destartalado… ir reformándolo poco a poco, edificio por edificio… montar otro club ahí… una legalización del cannabis»; con CAL).
#   $GODOT --headless --path godot --script res://tests/obras.gd   → «obras: N comprobaciones, 0 fallos»
#   con -- --sin-arranque --pintar <dir> (y xvfb, --rendering-driver opengl3) deja también obras-<sitio>.png
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")
const At = preload("res://tests/atrezo.gd")

var J
var M
var LOG := []
var QUIERO := []
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

func _menu(items: Array, o: Dictionary) -> Dictionary:
	var labels := []
	for it in items:
		labels.append(it if it is String else str(it.get("label", "")))
	var k := labels.size() - 1
	var q: String = QUIERO.pop_front() if QUIERO.size() else ""
	if q == "<B>":
		M.timeout(func(): J.press("B"), 5)
	for i in labels.size():
		if q != "" and labels[i].begins_with(q):
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
			print("  bloqueo: ", LOG.slice(-3), " ", QUIERO)
			return false
	return true

func foto(dir: String, k: String) -> void:
	if dir == "":
		return
	J.oraculo = false
	J.toast_box.hide()
	for q in 2:
		await process_frame
		J.pintor.redibuja(0.0)
		for r in 4:
			await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("obras-%s.png" % k))
	J.oraculo = true

func entra(mapa: String, x: int, y: int, dir := "up") -> void:
	J.enter_map(mapa, x, y, dir)
	J.build_ents()
	J.mode = "world"

func pisa_puerta(x: int, y: int, fx: int, fy: int) -> bool:
	var P = J.P
	P.x = x
	P.y = y
	P.fx = fx
	P.fy = fy
	var d = J.MAPS[J.S.map].doors.get("%d,%d" % [x, y])
	if d == null:
		return false
	return corre(func(): await J.entra_local(d))

func espera(c: Callable) -> bool:
	var t0: float = M.reloj
	while not (c.call() and J.is_free() and J.pending.is_empty()):
		if M.reloj - t0 > 60000 or not M.paso():
			return false
	return true

func lote() -> String:
	return str(J.venta_item(J.bud_lots(1)[0]).label)

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-obras.json"
	Juego.AJUSTES = "user://prueba-obras-ajustes.json"
	Datos.CAL = true
	var OJ = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in OJ:
		if x.k == "nave2":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	J.S = e.S
	var S = J.S
	S.ch = 8
	S.erase("mar")
	S.erase("franco")
	S.flags.erase("koldoSms")
	S.banco = 300000
	S.money = 20000
	S.heat = 0
	S.protect = false
	S.buds = {}
	var sid: String = J.D.STRAINS.keys()[0]
	J.add_buds(sid, 9000, 24)
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	var dir := arg("--pintar")
	if dir != "":
		J.set_process(false)
	var D: Dictionary = J.D
	var R: Dictionary = D.MAR
	var mu: Dictionary = J.MAPS.muelle
	var fach := func(id: String) -> String:
		for b in mu.blds:
			if b.id == id:
				return b.get("fachada", b.id)
		return ""
	# 0 · los datos: cada obra con su casa y sus requisitos; el arte de cada ruina, en el atlas
	for O in R.obras:
		chk(int(O.p) > 0 and int(O.d) > 0 and str(O.txt) != "", "la obra %s, con precio, días y texto" % O.k)
		if O.get("req"):
			chk(not J.obra_k(O.req).is_empty(), "%s pide %s, que existe" % [O.k, O.req])
		for id in O.get("b", []):
			chk(Atlas.frame_de("edificio-%s-ruina" % id, "base", "unica", 0, {"i": 0}) != null, "la ruina de %s, dibujada" % id)
	chk(Atlas.frame_de("edificio-club-kaia", "base", "unica", 0, {"i": 0}) != null, "la fachada de KAIA, dibujada")
	chk(Atlas.frame_de(Atlas.cubre("tile:dockR"), "dockR", "unica", 0, {"i": 0}) != null, "el pantalán podrido, dibujado")
	chk(J.barco_k("pesquero").req == "pantalan" and J.barco_k("atunero").req == "dique", "el pesquero pide el pantalán y el atunero, el dique")
	chk(D.CLUBS.has("muelle") and D.CLUBS.muelle.get("tuyo") and D.GENERO.enc.has("muelle") and D.SOCIO.n.has("muelle"), "con CAL, KAIA entre los clubs")
	# 1 · al principio, destartalado: las casas en ruina y el pantalán podrido
	entra("muelle", 12, 9)
	corre(func(): await J.talk_koldo())
	chk(S.mar is Dictionary, "Koldo da la txalupa")
	for O in R.obras:
		for id in O.get("b", []):
			chk(fach.call(id) == id + "-ruina", "%s, en ruina" % id)
	chk(fach.call("marinera") == "marinera", "la casa de Gorka, como estaba")
	var podr: int = mu.g[10].count("dockR")
	chk(podr == R.podrido.size(), "el pantalán podrido: %d tablones" % podr)
	chk(not mu.doors.has("10,6"), "la casa blanca, sin puerta")
	await foto(dir, "ruina")
	# 2 · el club pide el pantalán; el pantalán, por el banco y en sus días
	var b0: float = S.banco
	QUIERO = ["Las obras del muelle", "La casa blanca", "Sí", "Nada", "Nada"]
	corre(func(): await J.talk_koldo())
	chk(not S.mar.ob.has("club") and S.banco == b0, "sin pantalán, el club no")
	QUIERO = ["Las obras del muelle", "El pantalán", "Sí", "Nada", "Nada"]
	corre(func(): await J.talk_koldo())
	var PA: Dictionary = J.obra_k("pantalan")
	chk(int(S.mar.ob.get("pantalan", 0)) == S.day + int(PA.d) and absf(b0 - S.banco - float(PA.p)) < 1, "el pantalán, por transferencia: acaba el día %s" % S.mar.ob.get("pantalan"))
	QUIERO = ["Comprar un barco", "El pesquero", "Sí", "Nada"]
	corre(func(): await J.talk_koldo())
	chk(not "pesquero" in S.mar.b, "con el pantalán en obras, el pesquero todavía no")
	S.day += int(PA.d) - 1
	LOG.clear()
	corre(func(): J.mar_dia())
	chk(not J.obra_ya("pantalan") and not " ".join(LOG).contains("Terminada"), "la víspera, en obras")
	S.day += 1
	corre(func(): J.mar_dia())
	chk(J.obra_ya("pantalan") and " ".join(LOG).contains("Terminada el pantalán"), "el SMS del pantalán terminado")
	chk(mu.g[10].count("dockR") == 0, "el pantalán, nuevo")
	# 3 · las demás obras: la caseta, las casas y el club
	for k in ["caseta", "casas", "club", "dique"]:
		var OB: Dictionary = J.obra_k(k)
		QUIERO = ["Las obras del muelle", J.may1(OB.n).left(12), "Sí", "Nada", "Nada"]
		corre(func(): await J.talk_koldo())
		chk(S.mar.ob.has(k), "la obra %s, encargada" % k)
	S.day += 7
	LOG.clear()
	corre(func(): J.mar_dia())
	for k in ["caseta", "casas", "club", "dique"]:
		chk(J.obra_ya(k), "la obra %s, terminada" % k)
	chk(fach.call("marinera5") == "club-kaia" and fach.call("marinera6") == "marinera6" and fach.call("marinera3") == "marinera3", "las casas reformadas; la blanca, KAIA")
	var dk = mu.doors.get("10,6")
	chk(dk is Dictionary and dk.to == "club-muelle" and dk.gate == "club:muelle" and not J.tile_solid(mu, 10, 6), "la puerta de KAIA")
	# 4 · los alquileres, cada semana
	b0 = S.banco
	S.day = int(S.mar.alq)
	corre(func(): J.mar_dia())
	chk(absf(S.banco - b0 - float(J.obra_k("casas").alq)) < 1 and int(S.mar.alq) == S.day + 7, "el alquiler de las casas, a la cuenta")
	# 5 · la caseta: menos patrulleras (la probabilidad, por el mismo azar)
	chk(float(J.obra_k("caseta").r) < 1, "la caseta, menos riesgo")
	# 6 · el atunero, con el dique
	QUIERO = ["Comprar un barco", "El atunero", "Sí", "Nada"]
	corre(func(): await J.talk_koldo())
	chk("atunero" in S.mar.b, "con el dique, el atunero")
	entra("muelle", 12, 9)
	var mal: Array = At.accesos(J, "muelle").filter(func(t): return not t.begins_with("barco"))
	chk(mal.is_empty(), "en el muelle reformado se llega a todo: %s" % [mal])
	await foto(dir, "reformado")
	# 7 · KAIA por dentro: sin carné, la encargada y el dispensario
	J.P.x = 10
	J.P.y = 7
	chk(pisa_puerta(10, 6, 10, 7) and S.map == "club-muelle", "se entra a KAIA sin carné: %s" % S.map)
	chk(J.ents.any(func(x): return x.get("id") == "club_muelle"), "la encargada de KAIA")
	await foto(dir, "kaia")
	var m0: float = S.money
	QUIERO = [lote(), "100 g"]
	corre(func(): await J.talk_club("muelle"))
	chk(S.mar.get("kaia") is Dictionary and int(S.mar.kaia.g) == 100, "100 g al dispensario de KAIA")
	S.day += 1
	corre(func(): J.mar_dia())
	chk(S.money > m0 and int(S.mar.kaia.g) == 100 - int(R.kaia.dia), "KAIA despacha %d g: %s" % [int(R.kaia.dia), S.money - m0])
	# 8 · la ley: a MAR.legal.dias de abrir KAIA; la licencia y la distribuidora
	var LG: Dictionary = R.legal
	chk(int(S.mar.get("ley", 0)) == 0, "todavía sin ley")
	S.day = int(S.mar.oba.club) + int(LG.dias)
	LOG.clear()
	corre(func(): J.mar_dia())
	chk(int(S.mar.get("ley", 0)) == S.day and " ".join(LOG).contains("Congreso"), "la ley, con su SMS")
	S.banco += 100000
	b0 = S.banco
	QUIERO = ["La licencia", "Sí", "Nada"]
	corre(func(): await J.talk_koldo())
	chk(S.mar.get("lic") and absf(b0 - S.banco - float(LG.lic)) < 1, "la licencia, por transferencia")
	b0 = S.banco
	var h0: int = int(S.heat)
	var g0: float = J.total_buds()
	QUIERO = ["La distribuidora", lote(), "1 kg", "Nada"]
	corre(func(): await J.talk_koldo())
	var vend: float = g0 - J.total_buds()
	chk(vend > 0 and vend <= float(LG.dia) and S.banco > b0 and int(S.heat) == h0, "la distribuidora compra %s g, por el banco y sin calor" % vend)
	chk(kaia_ok(J, R), "con licencia, KAIA despacha más")
	# 9 · sin CAL, ni KAIA ni obras entre los clubs
	Datos.CAL = false
	Datos.carga()
	chk(not J.D.CLUBS.has("muelle"), "sin CAL, KAIA no está entre los clubs")
	Datos.CAL = true
	Datos.carga()
	chk(J.D.CLUBS.has("muelle"), "con CAL, otra vez")
	print("obras: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  FALLO: ", f)
	quit(1 if fallos.size() else 0)

func kaia_ok(J_, R: Dictionary) -> bool:
	return absf(J_.kaia_dia() - float(R.kaia.dia) * float(R.legal.kaia)) < .01
