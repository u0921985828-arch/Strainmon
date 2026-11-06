# Ribera Verde (Godot) — el bucle de eventos del HTML: setTimeout, setInterval y las esperas (wait) de los guiones, en un
# reloj propio (ms). En el juego, juego.gd lo hace avanzar con el tiempo real en cada fotograma; en la prueba de la historia
# (tests/historia.gd) va de evento en evento, sin esperar, en el mismo orden que el navegador.
# Los guiones son corrutinas de GDScript: «await M.wait(ms)» espera a que salte su temporizador, y una promesa (Prom) despierta
# en el acto a quien la esperaba, como la microtarea de una promesa resuelta.
extends RefCounted

class Prom:
	signal hecho(v)
	var listo := false
	var valor = null
	func res(v = null) -> void:
		if listo:
			return
		listo = true
		valor = v
		hecho.emit(v)

var reloj := 0.0
var cola: Array = []   # [cuando, orden, id, fn, cada (0: una vez)], ordenada por cuando y orden
var orden := 0
var vivos := {}        # id → true mientras no se quite

func _mete(e: Array) -> void:
	var lo := 0
	var hi := cola.size()
	while lo < hi:
		var m := (lo + hi) >> 1
		var c: Array = cola[m]
		if c[0] < e[0] or (c[0] == e[0] and c[1] < e[1]):
			lo = m + 1
		else:
			hi = m
	cola.insert(lo, e)

func timeout(fn: Callable, ms: float) -> int:
	orden += 1
	vivos[orden] = true
	_mete([reloj + maxf(0.0, ms), orden, orden, fn, 0.0])
	return orden

func intervalo(fn: Callable, ms: float) -> int:
	orden += 1
	vivos[orden] = true
	_mete([reloj + maxf(1.0, ms), orden, orden, fn, maxf(1.0, ms)])
	return orden

func quita(id: int) -> void:
	vivos.erase(id)

# el siguiente evento (false si no queda ninguno antes de «hasta»)
func paso(hasta := INF) -> bool:
	while not cola.is_empty():
		var e: Array = cola[0]
		if e[0] > hasta:
			return false
		cola.pop_front()
		if not vivos.has(e[2]):
			continue
		reloj = maxf(reloj, e[0])
		if e[4] > 0:
			orden += 1
			_mete([e[0] + e[4], orden, e[2], e[3], e[4]])
		else:
			vivos.erase(e[2])
		e[3].call()
		return true
	return false

# todo lo que toca hasta «hasta» y el reloj a «hasta»
func avanza(hasta: float) -> void:
	while paso(hasta):
		pass
	reloj = maxf(reloj, hasta)

func wait(ms: float) -> void:
	var p := Prom.new()
	timeout(p.res, ms)
	await p.hecho

# espera una promesa (aunque ya esté resuelta)
static func espera(p: Prom):
	if p.listo:
		return p.valor
	return await p.hecho
