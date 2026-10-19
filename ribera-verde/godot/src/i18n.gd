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
	return _en.get(s, s)

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
