# Ribera Verde (Godot) — el chiptune de 05-audio.js: cada efecto y cada canción (un bucle de todos sus pasos) es un
# AudioStreamWAV de 16 bits con las mismas ondas (cuadrada, pulsos de 25 y 12,5 %, triangular, sierra y ruido), las mismas rampas
# de volumen y de frecuencia y la ganancia maestra de 0,16. Los efectos se sintetizan al arrancar; las canciones (TUNES ya
# convertido en pasos por tema() de 05-audio: melodía con su largo, arpegio, bajo y batería), en un hilo aparte, primero la que
# toca sonar, y suenan en cuanto están; al cambiar de canción, la que suena se apaga en 0,3 s y la nueva entra a los 0,4 s.
# El ruido sale de un generador propio con semilla fija: no toca el azar del juego (Cultivo.azar).
extends Node

const Datos = preload("res://src/datos.gd")

const HZ := 22050
const MASTER := .16

var on := true
var vm := 1.0   # volumen de la música y de los efectos (OPCIONES, de 0 a 1)
var ve := 1.0
var listo := false
var efectos := {}
var temas := {}
var actual := ""
var musica := AudioStreamPlayer.new()
var otra := AudioStreamPlayer.new()   # la que se apaga al cambiar de canción
var voces: Array = []
var ruido := PackedFloat32Array()
var golpes := {}   # batería: 1 bombo, 2 caja, 3 charles
var T := {}
var cola: Array = []
var hechos := {}
var hilo: Thread = null
var cerrojo := Mutex.new()
var parar := false
var espera := 0.0   # lo que falta para que entre la canción nueva (tiempo de juego, como el fundido)
var fundido: Tween = null

func init() -> void:
	if listo:
		return
	listo = true
	var r := RandomNumberGenerator.new()
	r.seed = 7
	ruido.resize(int(HZ * .3))
	for i in ruido.size():
		ruido[i] = r.randf() * 2 - 1
	add_child(musica)
	add_child(otra)
	for i in 8:
		var v := AudioStreamPlayer.new()
		add_child(v)
		voces.append(v)
	for k in ["blip", "tick", "sel", "back", "bump", "door", "coin", "get", "hit", "hurt", "enc", "bad"]:
		efectos[k] = _efecto(k)
	for k in [1, 2, 3]:
		var g := PackedFloat32Array()
		g.resize(int(HZ * .14))
		match k:
			1:
				_tono(g, 150, 0, .12, "triangle", .3, 45)
			2:
				_ruido(g, 0, .12, .12)
			3:
				_ruido(g, 0, .03, .05)
		golpes[k] = g
	T = Datos.carga().TUNES
	cola = T.keys()
	if cola.has(actual):
		cola.erase(actual)
		cola.push_front(actual)
	_vol()
	hilo = Thread.new()
	hilo.start(_hilo)

static func mf(n: float) -> float:
	return 440.0 * pow(2.0, (n - 69) / 12.0)

# una nota: onda a f (rampa exponencial hasta f2), volumen de vol a .001 en dur (exponencial) y corte a dur + .02
func _tono(b: PackedFloat32Array, f: float, t: float, dur: float, tipo := "square", vol := .25, f2 := 0.0, envuelve := false) -> void:
	var i0 := int(t * HZ)
	var n := int((dur + .02) * HZ)
	var nd := maxf(1, dur * HZ)
	var ph := 0.0
	var fr := f
	var rf := pow(f2 / f, 1 / nd) if f2 > 0 else 1.0
	var g := vol
	var rg := pow(.001 / vol, 1 / nd)
	for k in n:
		ph = fmod(ph + fr / HZ, 1.0)
		if k < nd:
			fr *= rf
			g *= rg
		var w := 0.0
		match tipo:
			"square":
				w = 1.0 if ph < .5 else -1.0
			"triangle":
				w = 1 - 4 * absf(ph - .5)
			"sawtooth":
				w = 2 * ph - 1
		var j := i0 + k
		if envuelve:
			j = j % b.size()
		elif j >= b.size():
			break
		b[j] += w * g

func _ruido(b: PackedFloat32Array, t: float, dur: float, vol := .3) -> void:
	var i0 := int(t * HZ)
	var n := int(dur * HZ)
	var g := vol
	var rg := pow(.001 / vol, 1.0 / maxf(1, n))
	for k in mini(n, ruido.size()):
		if i0 + k >= b.size():
			break
		b[i0 + k] += ruido[k] * g
		g *= rg

func _efecto(k: String) -> AudioStreamWAV:
	var b := PackedFloat32Array()
	b.resize(int(HZ * .75))
	var t := .005
	match k:
		"blip":
			_tono(b, 1200, t, .025, "square", .06)
		"tick":
			_tono(b, 900, t, .03, "square", .08)
		"sel":
			_tono(b, 880, t, .05, "square", .12)
			_tono(b, 1320, t + .05, .07, "square", .12)
		"back":
			_tono(b, 660, t, .05, "square", .1)
			_tono(b, 440, t + .05, .07, "square", .1)
		"bump":
			_tono(b, 110, t, .08, "triangle", .3)
		"door":
			_ruido(b, t, .18, .15)
			_tono(b, 300, t, .15, "triangle", .2, 120)
		"coin":
			_tono(b, 988, t, .07, "square", .14)
			_tono(b, 1319, t + .07, .18, "square", .14)
		"get":
			var ns := [72, 76, 79, 84]
			for i in ns.size():
				_tono(b, mf(ns[i]), t + i * .09, .12, "square", .13)
			_tono(b, mf(88), t + .38, .3, "square", .13)
		"hit":
			_ruido(b, t, .15, .4)
			_tono(b, 200, t, .12, "square", .2, 60)
		"hurt":
			_tono(b, 400, t, .25, "sawtooth", .18, 90)
			_ruido(b, t, .1, .2)
		"enc":
			for i in 8:
				_tono(b, mf(60 + i * 3), t + i * .045, .05, "square", .12)
		"bad":
			_tono(b, 220, t, .18, "square", .15)
			_tono(b, 160, t + .18, .35, "square", .15)
	var fin := b.size()
	while fin > 1 and absf(b[fin - 1]) < 1e-5:
		fin -= 1
	b.resize(fin)
	return _wav(b, false)

# el hilo: saca de la cola la siguiente canción, la sintetiza y la deja en hechos (el AudioStreamWAV se hace en _process)
func _hilo() -> void:
	while true:
		cerrojo.lock()
		if parar or cola.is_empty():
			cerrojo.unlock()
			return
		var n: String = cola.pop_front()
		cerrojo.unlock()
		var b := _tema(T[n])
		if parar:
			return
		var d := _bytes(b)
		cerrojo.lock()
		hechos[n] = d
		cerrojo.unlock()

# una nota de la música (voz de 05-audio): onda a f, de vol a la mitad en dur (lineal) y suelta en 30 ms
func _nota(cache: Dictionary, tipo: String, f: float, dur: float, vol: float) -> PackedFloat32Array:
	var k := "%s %.3f %.4f %.4f" % [tipo, f, dur, vol]
	if cache.has(k):
		return cache[k]
	var nd := maxi(1, int(dur * HZ))
	var nr := int(.03 * HZ)
	var c := PackedFloat32Array()
	c.resize(nd + nr)
	var duty := .25 if tipo == "pulse25" else .125
	var bajo := -duty / (1 - duty)
	var ph := .25 if tipo == "triangle" else .5 if tipo == "sawtooth" else 0.0   # empiezan en 0, como en WebAudio
	var paso := f / HZ
	for i in c.size():
		var w := 0.0
		match tipo:
			"square":
				w = 1.0 if ph < .5 else -1.0
			"triangle":
				w = 1 - 4 * absf(ph - .5)
			"sawtooth":
				w = 2 * ph - 1
			_:
				w = 1.0 if ph < duty else bajo
		c[i] = w * (vol * (1 - .5 * i / nd) if i < nd else vol * .5 * (1 - float(i - nd) / nr))
		ph = fmod(ph + paso, 1.0)
	cache[k] = c
	return c

# suma c en b desde t, en bucle: lo que pasa del final suena al principio
func _suma(b: PackedFloat32Array, c: PackedFloat32Array, t: float) -> void:
	var i0 := int(t * HZ)
	var L := b.size()
	var n := mini(c.size(), L - i0)
	for k in n:
		b[i0 + k] += c[k]
	for k in range(n, c.size()):
		b[(i0 + k) % L] += c[k]

# la canción entera (todos sus pasos de 60/bpm/2 s), en bucle
func _tema(D: Dictionary) -> PackedFloat32Array:
	var st: float = 60.0 / float(D.bpm) / 2
	var n: int = D.mel.size()
	var b := PackedFloat32Array()
	b.resize(int(round(st * n * HZ)))
	var cache := {}
	for i in n:
		if parar:
			break
		var t := i * st
		var m := float(D.mel[i])
		var a := float(D.arm[i])
		var ba := float(D.bas[i])
		var g := int(D.bat[i])
		if m > 0:
			_suma(b, _nota(cache, D.mo, mf(m), float(D.md[i]) * st - st * .1, float(D.mv)), t)
		if a > 0:
			_suma(b, _nota(cache, D.ao, mf(a), st * .9, float(D.av)), t)
		if ba > 0:
			_suma(b, _nota(cache, D.bo, mf(ba), st * .95, float(D.bv)), t)
		if g > 0:
			_suma(b, golpes[g], t)
	return b

func _bytes(b: PackedFloat32Array) -> PackedByteArray:
	var d := PackedByteArray()
	d.resize(b.size() * 2)
	for i in b.size():
		d.encode_s16(i * 2, clampi(int(b[i] * MASTER * 32767), -32768, 32767))
	return d

func _wav(b: PackedFloat32Array, bucle: bool) -> AudioStreamWAV:
	return _wav_de(_bytes(b), bucle)

func _wav_de(d: PackedByteArray, bucle: bool) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = HZ
	w.stereo = false
	w.data = d
	if bucle:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = d.size() / 2
	return w

func sfx(k: String) -> void:
	if not listo or not on or not efectos.has(k):
		return
	for v in voces:
		if not v.playing:
			v.stream = efectos[k]
			v.play()
			return
	voces[0].stream = efectos[k]
	voces[0].play()

func music(n: String) -> void:
	if n == actual:
		return
	actual = n
	if not listo:
		return
	cerrojo.lock()
	if cola.has(n):
		cola.erase(n)
		cola.push_front(n)
	cerrojo.unlock()
	if musica.playing:
		if fundido and fundido.is_valid():
			fundido.kill()
		var v := musica
		musica = otra
		otra = v
		musica.stop()
		fundido = create_tween()
		fundido.tween_property(v, "volume_db", -60.0, .3)
		fundido.tween_callback(v.stop)
		espera = .4
	_vol()
	_suena()

# en cuanto la canción que toca está hecha (y pasó el fundido), suena
func _suena() -> void:
	if temas.has(actual) and espera <= 0 and (musica.stream != temas[actual] or not musica.playing):
		musica.stream = temas[actual]
		musica.play()

func _process(d: float) -> void:
	if not listo:
		return
	espera = maxf(0, espera - d)
	cerrojo.lock()
	var h := hechos
	hechos = {}
	cerrojo.unlock()
	for n in h:
		temas[n] = _wav_de(h[n], true)
	if actual != "":
		_suena()

func _exit_tree() -> void:
	parar = true
	if hilo and hilo.is_started():
		hilo.wait_to_finish()

func _vol() -> void:
	musica.volume_db = linear_to_db(vm) if on and vm > 0 else -80.0
	if (not on or vm <= 0) and fundido and fundido.is_valid():
		fundido.kill()
		otra.stop()
	for v in voces:
		v.volume_db = linear_to_db(ve) if on and ve > 0 else -80.0

func set_on(v: bool) -> void:
	on = v
	if listo:
		_vol()

func niveles(m: float, e: float) -> void:
	vm = m
	ve = e
	if listo:
		_vol()
