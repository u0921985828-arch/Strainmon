# Landrace Hunters (Godot) — el colocón en el combate y combates más llevaderos (lo pidió el usuario: «los combates o están muy
# complicados o he combatido todo fumado y en el combate no se notan los efectos»), con Datos.CAL.
#  · FISIO.comb: la índica duele menos (recibe) pero aciertas, esquivas y huyes peor; la sativa, al revés sin quitarte nada; la
#    borrachera (por encima de FISIO.vision) resta puntería y esquiva. Un aviso al empezar y el ojo del colocón también en combate.
#  · COMBATE7.facil: ladrones y rivales con menos vida y golpes más flojos.
#   $GODOT --headless --path godot --script res://tests/combate_colocon.gd   → «combate_colocon: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var D
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
	var k := 0
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
		if M.reloj - t0 > 600000 or not M.paso():
			print("  bloqueo: fin %s libre %s modo %s" % [st.fin, J.is_free(), J.mode])
			return false
	return true

# n peleas contra ladrones del capítulo ch, siempre a puñetazos, con la vida y la experiencia de partida: cuántas se ganan
func ganadas(ch: int, veces: int) -> int:
	var S: Dictionary = J.S
	var g := 0
	for i in veces:
		S.ch = ch
		S.hpMax = 30
		S.hp = 30
		S.pelea = {"xp": 0, "fue": 0, "ref": 0}
		S.items.spray = 0
		S.items.bocata = 0
		var r := {"v": null}
		corre(func(): r.v = await J.battle("thief"))
		if r.v == "win":
			g += 1
	return g

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-combate-colocon.json"
	Juego.AJUSTES = "user://prueba-combate-colocon-ajustes.json"
	Datos.CAL = true
	J = Juego.new()
	root.add_child(J)
	M = J.M
	D = J.D
	J.oraculo = true
	J.gancho_menu = _menu
	J.gancho_texto = func(t, _nm): LOG.append(t)
	J.gancho_toast = func(_h, _ms): pass
	M.intervalo(func():
		if J.handlers.size():
			J.press("A"), 12)
	M.intervalo(func(): J.update(1000 / 60.0), 1000 / 60.0)
	QUIERO = ["Saltarlo", "EDDIE", "CHICO"]
	chk(corre(func(): await J.new_game()), "bloqueo en la partida nueva")
	var S: Dictionary = J.S
	var C: Dictionary = D.FISIO.comb

	# 1 · lo que cambia el colocón (sin combate, nada)
	J.B = null
	chk(J.mod_comb().acc == 0.0 and J.mod_comb().recibe == 1.0, "fuera del combate, nada")
	J.B = {"kind": "thief", "name": "x", "hp": 20, "hpMax": 20, "atk": [5, 9]}
	S.colo = 0.0
	S.borr = 0.0
	chk(J.mod_comb().acc == 0.0 and J.mod_comb().esq == 0.0 and J.mod_comb().recibe == 1.0, "sin fumar, como siempre")
	S.colo = 60.0
	S.efe = {"ind": 80}
	var m: Dictionary = J.mod_comb()
	chk(m.recibe < 1.0 and m.acc < 0 and m.esq < 0 and m.huir < 0, "índica: duele menos y vas lento: %s" % [m])
	S.efe = {"ind": 20}
	m = J.mod_comb()
	chk(m.recibe == 1.0 and m.acc > 0 and m.esq > 0 and m.huir > 0, "sativa: más despierto: %s" % [m])
	var esq0: float = float(D.PELEA.esq0)
	chk(J.prob_esquiva() > esq0, "la sativa sube la esquiva: %s" % J.prob_esquiva())
	S.borr = float(D.FISIO.vision) + 10
	m = J.mod_comb()
	chk(is_equal_approx(m.acc, float(C.sativa.acc) + float(C.borr.acc)), "y borracho, resta puntería: %s" % [m])
	S.borr = 0.0
	# 2 · el ojo del colocón también en combate
	J.mode = "battle"
	chk(J.ojo_k() > 0.0, "en combate, el ojo: %s" % J.ojo_k())
	J.mode = "world"
	# 3 · más llevaderos: vida y golpes al 80 %
	J.B = {"kind": "thief", "name": "x", "hp": 40, "hpMax": 40, "atk": [5, 9]}
	J.facil_combate()
	chk(int(J.B.hpMax) == 32 and int(J.B.hp) == 32 and J.B.atk == [4, 7], "facil: %s %s" % [J.B.hpMax, J.B.atk])
	J.B = null
	# 4 · un combate entero colocado de índica: el aviso
	S.colo = 60.0
	S.efe = {"ind": 80}
	LOG = []
	S.ch = 2
	S.hp = 30
	S.hpMax = 30
	var dano := []
	var hp0 := {"v": 30}
	var r := {"v": null}
	chk(corre(func(): r.v = await J.battle("thief")), "bloqueo en el combate colocado")
	chk(" ".join(LOG).contains("colocado de índica"), "el aviso de la índica: %s" % [LOG.slice(0, 4)])
	S.colo = 0.0
	LOG = []
	chk(corre(func(): r.v = await J.battle("thief")), "bloqueo en el combate sin fumar")
	chk(not " ".join(LOG).contains("colocado"), "sin fumar, sin aviso")
	# 5 · la dificultad: en el capítulo 8, sin subir de nivel, a puñetazos, se gana la mayoría y más que antes
	var F0: Dictionary = D.COMBATE7.facil.duplicate()
	var veces := 60
	var ahora := ganadas(8, veces)
	D.COMBATE7.facil = {"vida": 1, "atk": 1}
	var antes := ganadas(8, veces)
	D.COMBATE7.facil = F0
	print("  capítulo 8, ganadas de %d: antes %d, ahora %d" % [veces, antes, ahora])
	chk(ahora >= veces * 0.5, "ahora se gana la mayoría: %d/%d" % [ahora, veces])
	chk(ahora > antes, "más fácil que antes: %d > %d" % [ahora, antes])
	# 6 · sin CAL, como antes
	Datos.CAL = false
	J.B = {"kind": "thief", "name": "x", "hp": 40, "hpMax": 40, "atk": [5, 9]}
	J.facil_combate()
	S.colo = 60.0
	chk(int(J.B.hpMax) == 40 and J.mod_comb().recibe == 1.0, "sin CAL, nada cambia")
	J.B = null
	Datos.CAL = true
	print("combate_colocon: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for x in fallos:
		print("  ✗ " + x)
	quit(1 if fallos.size() else 0)
