# Ribera Verde (Godot) — 1.43.3: cada nombre con su muñeco (lo pidió el usuario: «los nombres de chica, con personajes chica, y los
# chicos lo mismo»). GENERO en datos.json: los muñecos de chica, los nombres de chica y lo que se cambia con Datos.CAL.
# Sin oráculo del HTML: parte del S de la pantalla nave.
#   $GODOT --headless --path godot --script res://tests/generos.gd   → «generos: N comprobaciones, 0 fallos»
extends SceneTree

const Datos = preload("res://src/datos.gd")
const Juego = preload("res://src/juego.gd")

var J
var M
var D
var MENUS := []
var LOG := []
var QUIERO := []
var n := 0
var fallos := []

func _initialize() -> void:
	_corre.call_deferred()

func chk(c: bool, txt: String) -> void:
	n += 1
	if not c:
		fallos.append(txt)

# los menús: el primero que empiece por lo siguiente de QUIERO; si no, el último
func _corre() -> void:
	Juego.GUARDADO = "user://prueba-generos.json"
	Juego.AJUSTES = "user://prueba-generos-ajustes.json"
	Datos.CAL = true
	var O = JSON.parse_string(FileAccess.get_file_as_string("res://tests/pantallas.json"))
	var e: Dictionary = {}
	for x in O:
		if x.k == "nave":
			e = Datos.enteros(x)
	J = Juego.new()
	root.add_child(J)
	M = J.M
	D = J.D
	J.S = e.S
	# 1 · todos los nombres de chica de las listas están en GENERO.nombresM; los de chico, no
	for nm in ["Leire", "Nerea", "Ane", "Maialen", "Irati", "Uxue", "Jaione", "Edurne", "Arantza", "Garazi", "Amaia", "Itziar", "Rosario", "Nagore", "Maribel", "Lorea", "Yolanda", "YOLANDA"]:
		chk(J.mujer_nombre(nm), "chica: " + nm)
	for nm in ["Asier", "Ibai", "Unax", "Gorka", "Jon", "Xabi", "Mikel", "Koldo", "Txema", "Iker", "Peio", "Oier", "Xabier", "Eneko", "Gotzon", "Joseba", "Imanol", "Bixente"]:
		chk(not J.mujer_nombre(nm), "chico: " + nm)
	for nm in D.NOMBRES_FIJO + D.BARRIO:
		chk(D.GENERO.nombresM.has(nm) or ["Asier", "Ibai", "Unax", "Gorka", "Jon", "Xabi", "Mikel", "Koldo", "Txema", "Iker", "Peio", "Oier"].has(nm), "sin clasificar: " + nm)
	# 2 · las personas fijas: su muñeco, del sexo de su nombre
	var quien := {}   # id de NPCDEF @ mapa → ¿chica?
	for k in D.PRESI:
		quien["pres_%s@club-%s" % [k, k]] = J.mujer_nombre(D.PRESI[k].n)
	for k in D.SOCIO.n:
		quien["socio@club-" + k] = J.mujer_nombre(D.SOCIO.n[k])
	for k in D.CLUBS:
		quien["club_%s@club-%s" % [k, k]] = D.GENERO.enc.has(k)
	quien["arantxa@conce"] = true
	quien["conce2@conce"] = false
	var vistos := 0
	for d in D.NPCDEF:
		var id: String = d.id + "@" + d.map
		if quien.has(id):
			vistos += 1
			chk(J.mujer_look(J.mk_ent(d).look) == quien[id], "muñeco de %s: %s" % [id, J.sprite_look(J.mk_ent(d).look)])
	chk(vistos == quien.size(), "vistos %d de %d" % [vistos, quien.size()])
	chk(not J.mujer_look(J.mk_ent({"id": "bixente", "x": 0, "y": 0, "look": "bixente"}).look), "Bixente, chico")
	for k in ["vecina", "ane", "nerea", "miren", "begona", "josune", "camarera", "rrpp", "portera", "socia"]:
		chk(J.mujer_look(D.LOOKS[k]), "chica: look " + k)
	for k in ["arrieta", "andoni", "txomin", "kiko", "julen", "delroy", "gorila", "dj", "portero", "socio", "judge"]:
		chk(not J.mujer_look(D.LOOKS[k]), "chico: look " + k)
	# 3 · los clientes de la calle: el nombre de la agenda, del sexo de su muñeco (los 6 muñecos salen)
	var m := 0
	for i in 300:
		var cid := "c%d" % i
		var f: bool = J.mujer_look({"id": "n" + cid})
		m += int(f)
		chk(J.mujer_nombre(J.nombre_fijo(cid)) == f, "cliente %s: %s" % [cid, J.nombre_fijo(cid)])
	chk(m > 100 and m < 200, "chicas %d de 300" % m)
	chk(J.etiqueta_ct("pij", true) == "PIJA" and J.etiqueta_ct("pij", false) == "PIJO" and J.etiqueta_ct("ext", true) == "CATADORA", "etiquetas")
	# 4 · la nave: el muñeco de cada navero, del sexo de su nombre
	var nombres := ["Jaione", "Mikel", "Koldo", "Edurne", "Amaia"]
	J.S.plantilla = []
	for i in 5:
		J.S.plantilla.append({"id": "pl%d" % (90 + i), "n": nombres[i], "lab": 3, "cui": 3, "lea": 3, "rol": "madres" if i == 4 else "nave", "mesa": null if i == 4 else i})
	J.enter_map("nave", 7, 6, "up")
	var nv := 0
	for x in J.ents:
		if x.id.length() == 3 and x.id.begins_with("nv"):
			var w = J.cuida_madres() if x.id == "nvm" else J.navero_de(int(x.id[2]))
			if w:
				nv += 1
				chk(J.mujer_look(x.look) == J.mujer_nombre(w.n), "navero %s %s: %s" % [x.id, w.n, J.sprite_look(x.look)])
	chk(nv == 5, "naveros %d" % nv)
	# 5 · los rivales y las encargadas
	for z in D.RIVALES:
		var R: Dictionary = D.RIVALES[z]
		var s: String = J.sprite_look(J.look_rival(R))
		chk(s != "ladron3" if J.mujer_nombre(R.n) else s.begins_with("ladron"), "rival %s: %s" % [R.n, s])
	chk(J.con_encargada("El encargado no deja entrar.", "valde") == "La encargada no deja entrar.", "encargada valde")
	chk(J.con_encargada("El encargado no deja entrar.", "puerto") == "El encargado no deja entrar.", "encargado puerto")
	# 6 · sin Datos.CAL (las pruebas contra el HTML), todo como estaba
	Datos.CAL = false
	for d in D.NPCDEF:
		if d.id == "pres_puerto":
			chk(J.mk_ent(d).look.id == D.LOOKS.presi_puerto.id, "sin CAL, el look de siempre")
	chk(J.etiqueta_ct("pij", true) == "PIJO", "sin CAL, PIJO")
	print("generos: %d comprobaciones, %d fallos" % [n, fallos.size()])
	for f in fallos:
		print("  ✗ " + f)
	quit(1 if fallos.size() else 0)
