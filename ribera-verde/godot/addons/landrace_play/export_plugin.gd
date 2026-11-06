@tool
extends EditorPlugin
# Fase 6: mete en el AAB el plugin Android (bin/landrace-play.aar, de tools/plugin-android.sh), sus dependencias de Maven y,
# con el APP_ID de Play Games puesto en datos/play_games.json, su meta-data. Solo en la exportación con Gradle.

var exp: EditorExportPlugin

func _enter_tree() -> void:
	exp = Exporta.new()
	add_export_plugin(exp)

func _exit_tree() -> void:
	remove_export_plugin(exp)
	exp = null

class Exporta extends EditorExportPlugin:
	const DEPS := ["com.android.billingclient:billing:7.1.1", "com.google.android.gms:play-services-games-v2:20.1.2",
		"io.sentry:sentry-android:7.22.6", "androidx.core:core:1.13.1"]

	func _get_name() -> String:
		return "LandracePlay"

	func _supports_platform(p: EditorExportPlatform) -> bool:
		return p is EditorExportPlatformAndroid

	func _get_android_libraries(_p: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["landrace_play/bin/landrace-play.aar"])

	func _get_android_dependencies(_p: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(DEPS)

	func _get_android_manifest_application_element_contents(_p: EditorExportPlatform, _debug: bool) -> String:
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://datos/play_games.json"))
		var id := str(j.get("app_id", "")) if j is Dictionary else ""
		if id == "":
			return ""
		# «\u003» + el id: aapt lo lee como texto (un número suelto sería un entero y Play Games no arranca)
		return "<meta-data android:name=\"com.google.android.gms.games.APP_ID\" android:value=\"\\u003%s\" />\n" % id
