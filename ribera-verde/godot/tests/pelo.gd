# Ribera Verde (Godot) — el pelo de la protagonista (con Datos.CAL): cada pelo cambia el tono principal del pelo (#5c3a28)
# y el de sombra, pero no el iris (el mismo #5c3a28 junto al blanco del ojo o a la piel) ni la boca; el chico, igual que antes.
#   $GODOT --headless --path godot --script res://tests/pelo.gd   → «pelo: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")
const Atlas = preload("res://src/atlas.gd")

var J
var n := 0
var fallos := []

func _initialize() -> void:
	Datos.PLAY = false
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

func hexc(p: Color) -> int:
	return (p.r8 << 16) | (p.g8 << 8) | p.b8

func _corre() -> void:
	Juego.GUARDADO = "user://prueba-pelo.json"
	Juego.AJUSTES = "user://prueba-pelo-ajustes.json"
	Datos.CAL = true
	J = Juego.new()
	root.add_child(J)
	J.S = J.new_state()
	var S = J.S
	S.sexo = "f"
	var g = J.grupo_pj()
	chk(g != null, "la protagonista tiene grupo")
	for dir in ["south", "east", "west", "north"]:
		var f = Atlas.frame_de(g, "base", dir, 0, {"i": 0})
		if f == null:
			continue
		var c: Image = f.c
		for i in range(1, J.D.ROPA.pelo.v.size()):
			S.ropa = {"camiseta": 0, "pantalon": 0, "gorra": 0, "pelo": i}
			var o: Image = J.ropa_c(f, "player-f").c
			var pelo := 0
			var iris := 0
			var otros := 0
			for y in c.get_height():
				for x in c.get_width():
					var p := c.get_pixel(x, y)
					if p.a8 == 0:
						continue
					var a := hexc(p)
					var b := hexc(o.get_pixel(x, y))
					if a == 0x5c3a28:
						if Atlas._junto_blanco(c, x, y):
							iris += 1
							chk(b == a, "%s pelo %d: el iris (%d, %d) no cambia" % [dir, i, x, y])
						else:
							pelo += 1
							chk(b == Datos.hexi(J.D.ROPA.pelo.v[i][1]), "%s pelo %d: el pelo (%d, %d) cambia al suyo" % [dir, i, x, y])
					elif a != 0x4a2a2b:
						otros += 1
						chk(b == a, "%s pelo %d: (%d, %d) no es pelo y no cambia" % [dir, i, x, y])
			chk(pelo > 10, "%s pelo %d: hay pelo que cambiar (%d)" % [dir, i, pelo])
			if dir == "south":
				chk(iris >= 2, "de frente, los dos iris (%d)" % iris)
	print("pelo: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos.slice(0, 20):
		print("  FALLO: " + f)
	quit(1 if fallos.size() else 0)
