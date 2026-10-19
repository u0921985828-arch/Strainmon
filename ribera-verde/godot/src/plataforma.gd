# Fase 6 (U7, U10, U11): Google Play por el plugin Android LandracePlay (addons/landrace_play, fuente en tools/android-plugin):
# la compra única del juego completo (Play Billing), los logros y el guardado en la nube (Play Games v2), el aviso local de la
# cosecha (con POST_NOTIFICATIONS solo si el jugador lo activa) y los informes de errores (Sentry, solo con el opt-in).
# Sin el plugin (escritorio, pruebas) todo es un no-op y la compra responde PRUEBA_COMPRA.
extends Node

const PLUGIN := "LandracePlay"
const PG_JSON := "res://datos/play_games.json"
const SENTRY_DSN := ""   # el DSN del proyecto de Sentry (lo pone Eddie); vacío, no se envía nada aunque se active

static var PRUEBA_COMPRA := "cancelada"   # sin plugin: lo que devuelve comprar() ("ok", "cancelada", "pendiente", "error")
static var PRUEBA_PERMISO := false        # sin plugin: lo que devuelve permiso_avisos()

var PL = null
var pg := {}
var enviados: Array = []   # lo que se ha pedido (para las pruebas): ["logro:venta", "aviso:3600", "evento:cap_2"…]
var comprado := false
signal compra_fin(estado: String)
signal permiso_fin(ok: bool)
signal nube_fin(datos: String)

func _ready() -> void:
	if FileAccess.file_exists(PG_JSON):
		var j = JSON.parse_string(FileAccess.get_file_as_string(PG_JSON))
		pg = j if j is Dictionary else {}
	if Engine.has_singleton(PLUGIN):
		PL = Engine.get_singleton(PLUGIN)
		PL.compra.connect(func(e: String): compra_fin.emit(e))
		PL.comprado.connect(func(_p: String): comprado = true)
		PL.permiso.connect(func(ok: bool): permiso_fin.emit(ok))
		PL.nube.connect(func(t: String): nube_fin.emit(t))
		PL.conectar(String(pg.get("app_id", "")) != "")

func hay() -> bool:
	return PL != null

# ---------- compra única ----------
func comprar(producto: String) -> String:
	enviados.append("compra:" + producto)
	if PL == null:
		return PRUEBA_COMPRA
	PL.comprar(producto)
	return await compra_fin

# las compras ya hechas (al reinstalar o en otro móvil): emite comprado y deja `comprado`
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
