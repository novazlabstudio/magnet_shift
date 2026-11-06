@tool
extends EditorExportPlugin

func _get_name() -> String:
	return "InAppReview"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid

# Yol res://addons/ klasörüne göre
func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	return PackedStringArray(["inapp_review/bin/InAppReview-release.aar"])

# Google'ın ücretsiz Play In-App Review kütüphanesi (yeni izin istemez)
func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	return PackedStringArray(["com.google.android.play:review:2.0.2"])
