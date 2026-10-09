# Ribera Verde (Godot) — el chiptune de 05-audio.js, sintetizado una vez al arrancar: cada efecto y cada canción (un bucle de
# sus 32 pasos) es un AudioStreamWAV de 16 bits con las mismas ondas (cuadrada, triangular, sierra y ruido), las mismas rampas
# exponenciales de volumen y de frecuencia y la ganancia maestra de 0,16. El ruido sale de un generador propio con semilla fija:
# no toca el azar del juego (Cultivo.azar).
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
var voces: Array = []
var ruido := PackedFloat32Array()

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
	for i in 8:
		var v := AudioStreamPlayer.new()
		add_child(v)
		voces.append(v)
	for k in ["blip", "tick", "sel", "back", "bump", "door", "coin", "get", "hit", "hurt", "enc", "bad"]:
		efectos[k] = _efecto(k)
	var T: Dictionary = Datos.carga().TUNES
	for n in T:
		temas[n] = _tema(T[n])
	_vol()
	if actual != "":
		var a := actual
		actual = ""
		music(a)

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

# la canción entera (32 pasos de 60/bpm/2 s), en bucle: las colas que pasan del final suenan al principio
func _tema(T: Dictionary) -> AudioStreamWAV:
	var st: float = 60.0 / T.bpm / 2
	var n: int = T.mel.size()
	var b := PackedFloat32Array()
	b.resize(int(round(st * n * HZ)))
	for i in n:
		var m: float = T.mel[i]
		var ba: float = T.bas[i]
		if m:
			_tono(b, mf(m), i * st, st * .9, "square", .07, 0, true)
		if ba:
			_tono(b, mf(ba), i * st, st * .95, "triangle", .16, 0, true)
	return _wav(b, true)

func _wav(b: PackedFloat32Array, bucle: bool) -> AudioStreamWAV:
	var d := PackedByteArray()
	d.resize(b.size() * 2)
	for i in b.size():
		d.encode_s16(i * 2, clampi(int(b[i] * MASTER * 32767), -32768, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = HZ
	w.stereo = false
	w.data = d
	if bucle:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = b.size()
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
	musica.stop()
	if temas.has(n):
		musica.stream = temas[n]
		musica.play()

func _vol() -> void:
	musica.volume_db = linear_to_db(vm) if on and vm > 0 else -80.0
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
