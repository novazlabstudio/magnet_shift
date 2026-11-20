#!/bin/zsh
# Google Play Games + yerel bildirim Godot eklentisini derler -> addons/novaz_services/bin/NovazServices-release.aar
# Play Games proje kimliği (APP_ID) scripts/PlayGamesIds.gd içindeki APP_ID satırından okunur ve AAR'ın
# kaynaklarına (game_services_project_id) yazılır. APP_ID boşsa Play Games kapalı kalır, bildirimler çalışır.
# Gereken: Godot 4.6.3 export şablonları, Android SDK (~/Library/Android/sdk), JDK 17, Gradle 8.11.1.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/android_plugins/novaz_services"
TPL="$HOME/Library/Application Support/Godot/export_templates/4.6.3.stable/android_source.zip"
mkdir -p libs src/main/res/values
[ -f libs/godot-lib.template_release.aar ] || unzip -q -j -o "$TPL" libs/release/godot-lib.template_release.aar -d libs
APP_ID=$(grep -m1 '^const APP_ID' "$ROOT/scripts/PlayGamesIds.gd" | sed -E 's/.*"([0-9]*)".*/\1/')
cat > src/main/res/values/strings.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<!-- tools/build_services.sh üretir; elle düzenleme -->
<resources>
    <string name="game_services_project_id" translatable="false">${APP_ID}</string>
</resources>
XML
export JAVA_HOME=$(ls -d "$HOME"/Library/Java/jdk-17*/Contents/Home | head -1)
export ANDROID_HOME="$HOME/Library/Android/sdk"
echo "sdk.dir=$ANDROID_HOME" > local.properties
GRADLE=$(ls -d "$HOME"/.gradle/wrapper/dists/gradle-8.11.1-bin/*/gradle-8.11.1/bin/gradle | head -1)
"$GRADLE" --no-daemon -q assembleRelease
mkdir -p "$ROOT/addons/novaz_services/bin"
cp build/outputs/aar/novazservices-release.aar "$ROOT/addons/novaz_services/bin/NovazServices-release.aar"
echo "Hazır: addons/novaz_services/bin/NovazServices-release.aar (Play Games APP_ID: ${APP_ID:-yok})"
