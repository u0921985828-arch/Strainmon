# Google Play por el plugin Android LandracePlay (addons/landrace_play, fuente en tools/android-plugin): las compras (Play
# Billing), los logros y el guardado en la nube (Play Games v2), el aviso local de la cosecha (con POST_NOTIFICATIONS solo si el
# jugador lo activa) y los informes de errores (Sentry, solo con el opt-in).
# Sin el plugin (escritorio, pruebas) todo es un no-op y la compra responde PRUEBA_COMPRA.
# Lo que se compra son los paquetes de semillas doradas de LA TIENDA (tienda.gd), consumibles: el plugin los consume para que se
# puedan volver a comprar. `comprado` es la compra única del juego completo de cuando el juego era una demo, que ya no se vende:
# se mira solo para regalar semillas doradas a quien la hizo (CONSUMIBLE, el prefijo de los paquetes).
# La copia de seguridad a un archivo (docs/MIGRACION-BETA.md): el directorio privado de la app se borra al desinstalarla y una
# firma nueva obliga a desinstalar, así que la partida se saca con el selector del sistema (sin permisos de almacenamiento):
# guarda_doc (ACTION_CREATE_DOCUMENT), abre_doc (ACTION_OPEN_DOCUMENT) y comparte (ACTION_SEND).
extends Node

const PLUGIN := "LandracePlay"   # i18n-no
const PG_JSON := "res://datos/play_games.json"
const SENTRY_DSN := ""   # el DSN del proyecto de Sentry (lo pone Eddie); vacío, no se envía nada aunque se active
const CONSUMIBLE := "sd_"   # i18n-no   el prefijo de los paquetes de semillas doradas, que se consumen y no cuentan como compra única

static var PRUEBA_COMPRA := "cancelada"   # sin plugin: lo que devuelve comprar() ("ok", "cancelada", "pendiente", "error")
static var PRUEBA_PERMISO := false        # sin plugin: lo que devuelve permiso_avisos()
static var PRUEBA_DOC := -1               # sin plugin: <0 no hay selector de archivos, 0 el usuario lo deja, 1 sale bien
static var PRUEBA_ABIERTO := ""           # sin plugin: el texto que devuelve abre_doc()

var PL = null
var pg := {}
var enviados: Array = []   # lo que se ha pedido (para las pruebas): ["logro:venta", "aviso:3600", "evento:cap_2"…]
var comprado := false
signal compra_fin(estado: String)
signal permiso_fin(ok: bool)
signal nube_fin(datos: String)
signal guardado_fin(ok: bool)
signal abierto_fin(txt: String)

func _ready() -> void:
	if FileAccess.file_exists(PG_JSON):
		var j = JSON.parse_string(FileAccess.get_file_as_string(PG_JSON))
		pg = j if j is Dictionary else {}
	if Engine.has_singleton(PLUGIN):
		PL = Engine.get_singleton(PLUGIN)
		PL.compra.connect(func(e: String): compra_fin.emit(e))
		PL.comprado.connect(func(p: String): comprado = comprado or not p.begins_with(CONSUMIBLE))
		PL.permiso.connect(func(ok: bool): permiso_fin.emit(ok))
		PL.nube.connect(func(t: String): nube_fin.emit(t))
		PL.guardado.connect(func(ok: bool): guardado_fin.emit(ok))
		PL.abierto.connect(func(t: String): abierto_fin.emit(t))
		PL.conectar(String(pg.get("app_id", "")) != "")

func hay() -> bool:
	return PL != null

# ---------- compras ----------
func comprar(producto: String) -> String:
	enviados.append("compra:" + producto)
	if PL == null:
		return PRUEBA_COMPRA
	PL.comprar(producto)
	return await compra_fin

# las compras ya hechas (al reinstalar o en otro móvil): emite comprado y deja `comprado` si fue la del juego completo
func consultar() -> void:
	if PL != null:
		PL.consultar()

# ---------- Play Games: logros y nube ----------
func id_logro(k: String) -> String:
	return String(pg.get("logros", {}).get(k, {}).get("id", ""))

func logro(k: String) -> void:
	enviados.append("logro:" + k)
	if PL != null and id_logro(k) != "":
		PL.logro(id_logro(k))

func nube_guarda(t: String) -> void:
	if PL != null:
		PL.nube_guarda("partida", t)

func nube_carga() -> String:
	if PL == null:
		return ""
	PL.nube_carga("partida")
	return await nube_fin

# ---------- la copia de seguridad, a un archivo o a otra app ----------
func doc_hay() -> bool:
	return PL != null or PRUEBA_DOC >= 0

func comparte(texto: String, asunto: String) -> void:
	enviados.append("comparte")
	if PL != null:
		PL.compartir(texto, asunto)

# guarda el texto donde diga el jugador; false si lo deja o si falla
func guarda_doc(nombre: String, texto: String) -> bool:
	enviados.append("guarda_doc:" + nombre)
	if PL == null:
		return PRUEBA_DOC > 0
	PL.guardar_doc(nombre, texto)
	return await guardado_fin

# el texto del archivo que elija el jugador; "" si lo deja o si falla
func abre_doc() -> String:
	enviados.append("abre_doc")
	if PL == null:
		return PRUEBA_ABIERTO
	PL.abrir_doc()
	return await abierto_fin

# ---------- aviso local de la cosecha ----------
func permiso_avisos() -> bool:
	if PL == null:
		return PRUEBA_PERMISO
	PL.permiso_avisos()
	return await permiso_fin

func aviso(seg: int, titulo: String, texto: String) -> void:
	enviados.append("aviso:%d" % seg)
	if PL != null:
		PL.aviso(seg, titulo, texto)

func sin_aviso() -> void:
	enviados.append("sin_aviso")
	if PL != null:
		PL.sin_aviso()

# ---------- informes de errores (opt-in) y el embudo del FTUE ----------
func errores(on: bool) -> void:
	if PL != null:
		PL.errores(on and SENTRY_DSN != "", SENTRY_DSN)

func evento(k: String) -> void:
	enviados.append("evento:" + k)
	if PL != null:
		PL.evento(k)
