# F7: los textos en castellano e inglés (i18n/strings.csv: clave, es, en). El juego piensa en castellano: T() compone las frases
# con huecos con nombre ({n}) y K() marca los literales que se ven y se traducen al salir (los menús comparan la etiqueta en
# castellano); say, ask, menu, toast, leer, el HUD y las etiquetas pasan lo que enseñan por v(). Con PLAY, la clave es el texto
# ya cambiado por Datos.tp. En castellano, v() y T() devuelven lo mismo que antes, letra a letra (las pruebas contra el HTML).
extends RefCounted

const Datos = preload("res://src/datos.gd")
const CSV := "res://i18n/strings.csv"
const IDIOMAS := ["es", "en"]

# "" = el del sistema (castellano, euskera, catalán o gallego → es; lo demás → en). Fuera de la app exportada (las pruebas y
# el editor), castellano salvo que se elija.
static var LANG := ""
static var _en := {}
static var _cargado := false

static func idioma() -> String:
	if LANG == "":
		if not OS.has_feature("template"):
			return "es"
		return "es" if OS.get_locale_language() in ["es", "eu", "ca", "gl"] else "en"
	return LANG

static func en() -> bool:
	return idioma() == "en"

static func _carga() -> void:
	_cargado = true
	var f := FileAccess.open(CSV, FileAccess.READ)
	if f == null:
		return
	f.get_csv_line()
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() >= 3 and r[2] != "":
			_en[r[1]] = r[2]

# lo que se ve, en el idioma elegido (sin traducción, tal cual)
static func v(s: String) -> String:
	if s == "" or not en():
		return s
	if not _cargado:
		_carga()
	if Datos.PLAY:
		var t := Datos.tp(s)
		if _en.has(t):
			return _en[t]
	if _en.has(s):
		return _en[s]
	var c := s.substr(0, 1)
	if c != c.to_upper():   # «la skunk #1» (to_lower de un nombre): la del nombre con mayúscula, en minúscula
		var m := c.to_upper() + s.substr(1)
		var r := v(m)
		if r != m:
			return r.substr(0, 1).to_lower() + r.substr(1)
	return Datos.tp(s)   # sin inglés, el castellano (con los nombres de PLAY)

# lo que se ve: en inglés, la traducción (ya con los nombres de PLAY: Datos.tp no se pasa por el inglés,
# que cambiaría palabras como «Ice» o «Critical»); en castellano, Datos.tp
static func vt(s: String) -> String:
	return v(s) if en() else Datos.tp(s)

# una frase con huecos: T("Tienes {n} €", {"n": 30}); los textos que van en los huecos también se traducen
static func T(s: String, a := {}) -> String:
	var r := v(s)
	for k in a:
		var x = a[k]
		r = r.replace("{" + str(k) + "}", v(x) if x is String else str(x))
	return r

# marca un literal que se ve y se traduce al enseñarlo (las etiquetas de los menús, que el código compara en castellano)
static func K(s: String) -> String:
	return s
