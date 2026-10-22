# Ribera Verde (Godot) — el rival de la bola 8 como un jugador de billar de verdad (lo pidió el usuario: «Tiene que ser un jugador
# realista de billar»): elige la bola y la tronera por lo fácil que es (corte, distancias, ángulo de entrada), deja la blanca para el
# tiro siguiente, juega a defender cuando no hay tiro, sale de un tapado por banda, saca a romper y coloca la bola en mano con cabeza;
# falla como falla una persona (más de lejos y en los cortes finos) y el que tiene más pulso juega mejor.
#   $GODOT --headless --path godot --script res://tests/billar8_ia.gd   → «billar8_ia: N comprobaciones, 0 fallos»
#   -- --partidas N   (12 de serie)   -- --solo-estad   (solo las cifras, sin comprobar)
extends SceneTree

const Datos = preload("res://src/datos.gd")
const B8 = preload("res://src/billar8.gd")
const Cultivo = preload("res://src/cultivo.gd")

var n := 0
var fallos := []

func arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func tira(V: Dictionary, q: int, ang: float, f: float) -> Dictionary:
	var ob := B8.objetivos(V, q)
	var ev := B8.dispara(V, ang, f)
	B8.simula(V, ev)
	var r := B8.resuelve(V, ev, q, ob)
	r.ev = ev
	return r

# una partida entre dos pulsos; apunta lo que hace cada uno
func partida(habs: Array, E: Array) -> int:
	var W := B8.nueva("X")
	var q := 0
	var fin := -1
	var nt := 0
	var tanda := 0
	while fin < 0 and nt < 160:
		nt += 1
		if W.mano:
			W.b[0].en = true
			W.b[0].p = B8.coloca_ia(W, q, habs[q])
			if not W.saque:
				var Lm := B8.tiros(W, q, habs[q])
				E[q].manos += 1
				E[q].mano_p += float(Lm[0].p) if Lm.size() else 0.0
			chk(B8.libre(W, W.b[0].p, 0) and (not W.saque or W.b[0].p.x <= B8.W * B8.RAYA + .01), "bola en mano en sitio libre")
			W.mano = false
		var saque: bool = W.saque
		var ob := B8.objetivos(W, q)
		var t0 := Time.get_ticks_usec()
		var s := B8.elige(W, q, habs[q])
		if OS.get_cmdline_user_args().has("--traza"):
			print("TIRO q=", q, " ", s.get("tipo"), " n=", s.get("n"), " prob=", s.get("prob", -1), " f=%.2f" % s.f)
		E[q].us += Time.get_ticks_usec() - t0
		E[q].tiros += 1
		var r := tira(W, q, s.ang, s.f)
		W.saque = false
		var mios := 0
		for m in r.ev.met:
			if m != 0 and m in ob:
				mios += 1
		if saque:
			E[q].saques += 1
			E[q].saque_mete += 1 if r.ev.met.size() > (1 if r.ev.blanca else 0) else 0
		elif s.get("tipo", "") == "defensa":
			E[q].defensas += 1
		else:
			E[q].ataques += 1
			if mios > 0:
				E[q].metidas += 1
		if s.get("tipo", "") == "banda":
			E[q].bandas += 1
			E[q].bandas_ok += 0 if (r.falta and r.motivo in ["nada", "otra"]) else 1
		if r.falta and OS.get_cmdline_user_args().has("--traza"):
			print("FALTA ", r.motivo, " q=", q, " ", s, " primer=", r.ev.primer)
		if r.falta:
			E[q].faltas[r.motivo] = int(E[q].faltas.get(r.motivo, 0)) + 1
		if r.sigue and not r.falta:
			tanda += mios
			E[q].tanda = maxi(E[q].tanda, tanda)
		else:
			tanda = 0
		if r.fin != "":
			fin = q if r.fin == "gana" else 1 - q
			if r.fin == "gana":
				E[q].gana_negra += 1
			else:
				E[q].pierde_negra += 1
		elif r.falta:
			W.mano = true
			q = 1 - q
		elif not r.sigue:
			q = 1 - q
	return fin

func estad() -> Dictionary:
	return {"tiros": 0, "us": 0, "saques": 0, "saque_mete": 0, "ataques": 0, "metidas": 0, "defensas": 0, "bandas": 0, "bandas_ok": 0,
		"faltas": {}, "tanda": 0, "gana_negra": 0, "pierde_negra": 0, "gana": 0, "manos": 0, "mano_p": 0.0}

func informe(nom: String, e: Dictionary) -> String:
	return "%s: %d tiros, %.0f ms/tiro · saques %d (meten %d) · bola en mano %d (p media %.2f) · metidas %d/%d ataques (%.0f %%) · defensas %d · bandas %d (%d tocan) · faltas %s · mejor tanda %d · gana %d (negra %d, pierde con la negra %d)" % [
		nom, e.tiros, e.us / 1000.0 / maxf(1, e.tiros), e.saques, e.saque_mete, e.manos, e.mano_p / maxf(1, e.manos), e.metidas, e.ataques, 100.0 * e.metidas / maxf(1, e.ataques), e.defensas,
		e.bandas, e.bandas_ok, e.faltas, e.tanda, e.gana, e.gana_negra, e.pierde_negra]

func _corre() -> void:
	Datos.CAL = true
	Cultivo.pm = 4242
	var np := int(arg("--partidas", "12"))
	var E := [estad(), estad()]
	for g in np:
		var fin := partida([.55, .3], E)
		if fin >= 0:
			E[fin].gana += 1
	print(informe("pulso .55", E[0]))
	print(informe("pulso .30", E[1]))
	if OS.get_cmdline_user_args().has("--solo-estad"):
		quit(0)
		return
	var A: Dictionary = E[0]
	var Bb: Dictionary = E[1]
	var nada := int(A.faltas.get("nada", 0)) + int(Bb.faltas.get("nada", 0))
	chk(nada <= np, "no tocar ninguna bola, como mucho una por partida (%d en %d)" % [nada, np])
	chk(A.metidas * 2 > A.ataques, "el de pulso .55 mete más de la mitad de los que ataca (%d/%d)" % [A.metidas, A.ataques])
	chk(A.metidas * Bb.ataques > Bb.metidas * A.ataques, "el de más pulso mete más (%d/%d contra %d/%d)" % [A.metidas, A.ataques, Bb.metidas, Bb.ataques])
	chk(A.gana > Bb.gana, "el de más pulso gana más (%d contra %d)" % [A.gana, Bb.gana])
	chk(A.defensas > 0 and Bb.defensas > 0, "los dos juegan a defender (%d y %d)" % [A.defensas, Bb.defensas])
	chk(A.bandas + Bb.bandas > 0 and (A.bandas_ok + Bb.bandas_ok) * 3 >= (A.bandas + Bb.bandas) * 2, "por banda, dos de cada tres tocan una suya (%d/%d)" % [A.bandas_ok + Bb.bandas_ok, A.bandas + Bb.bandas])
	chk(A.saque_mete + Bb.saque_mete > 0, "al sacar se mete alguna")
	chk(A.manos == 0 or A.mano_p / A.manos > .5, "con bola en mano se deja un tiro fácil (p media %.2f)" % (A.mano_p / maxf(1, A.manos)))
	for e in E:
		chk(e.us / 1000.0 / maxf(1, e.tiros) < 400, "menos de 400 ms por tiro (%.0f)" % (e.us / 1000.0 / maxf(1, e.tiros)))
	tapado()
	print("billar8_ia: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("FALLO  ", f)
	quit(1 if fallos.size() else 0)

# la blanca tapada (ninguna suya a la vista): sale por banda y toca una suya la mayoría de las veces
func tapado() -> void:
	var ok := 0
	for k in 10:
		var W := B8.nueva("X")
		W.saque = false
		W.mano = false
		W.gr = ["lisas", "rayadas"]
		for d in W.b:
			d.en = d.n in [0, 1, 8, 9]
		W.b[0].p = Vector2(84, 70)
		W.b[1].p = Vector2(84 + k, 20)
		W.b[9].p = Vector2(84 + k * .5, 45)
		W.b[8].p = Vector2(150, 70)
		chk(B8.rayo(W, (W.b[1].p - W.b[0].p).angle()).n != 1, "tapado %d: la 1 no se ve" % k)
		var s := B8.elige(W, 0, .55)
		chk(s.tipo == "banda", "tapado %d: sale por banda (%s)" % [k, s.tipo])
		var r := tira(W, 0, s.ang, s.f)
		if r.ev.primer == 1:
			ok += 1
	chk(ok >= 6, "tapado: por banda toca la suya (%d de 10)" % ok)
