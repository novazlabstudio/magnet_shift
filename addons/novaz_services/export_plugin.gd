@tool
extends EditorExportPlugin

func _get_name() -> String:
	return "NovazServices"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid

# Yol res://addons/ klasörüne göre
func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	return PackedStringArray(["novaz_services/bin/NovazServices-release.aar"])

# Google Play Games Services v2 (ücretsiz; sunucu gerekmez)
func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	return PackedStringArray(["com.google.android.gms:play-services-games-v2:22.1.0"])
