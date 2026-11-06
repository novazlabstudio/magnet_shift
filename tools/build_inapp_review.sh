#!/bin/zsh
# Google Play In-App Review Godot eklentisini derler -> addons/inapp_review/bin/InAppReview-release.aar
# Gereken: Godot 4.6.3 export şablonları, Android SDK (~/Library/Android/sdk), JDK 17, Gradle 8.11.1.
set -e
cd "$(dirname "$0")/../android_plugins/inapp_review"
TPL="$HOME/Library/Application Support/Godot/export_templates/4.6.3.stable/android_source.zip"
mkdir -p libs
[ -f libs/godot-lib.template_release.aar ] || unzip -q -j -o "$TPL" libs/release/godot-lib.template_release.aar -d libs
export JAVA_HOME=$(ls -d "$HOME"/Library/Java/jdk-17*/Contents/Home | head -1)
export ANDROID_HOME="$HOME/Library/Android/sdk"
echo "sdk.dir=$ANDROID_HOME" > local.properties
GRADLE=$(ls -d "$HOME"/.gradle/wrapper/dists/gradle-8.11.1-bin/*/gradle-8.11.1/bin/gradle | head -1)
"$GRADLE" --no-daemon -q assembleRelease
mkdir -p ../../addons/inapp_review/bin
cp build/outputs/aar/inappreview-release.aar ../../addons/inapp_review/bin/InAppReview-release.aar
echo "Hazır: addons/inapp_review/bin/InAppReview-release.aar"
