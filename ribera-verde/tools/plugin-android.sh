#!/usr/bin/env bash
# Fase 6: compila el plugin Android de Landrace Hunters (tools/android-plugin, Java) contra la godot-lib de la plantilla de Godot 4.7
# y deja el AAR en godot/addons/landrace_play/bin/landrace-play.aar (va al repo: la exportación no necesita compilarlo).
# Necesita el Android SDK (ANDROID_HOME, por defecto /home/user/android-sdk) y Gradle 8.11.1 (el de la plantilla).
set -euo pipefail
cd "$(dirname "$0")/android-plugin"
SDK="${ANDROID_HOME:-/home/user/android-sdk}"
PLANTILLA="$HOME/.local/share/godot/export_templates/4.7.stable/android_source.zip"
GRADLE="${GRADLE:-$(ls -d "$HOME"/.gradle/wrapper/dists/gradle-8.11.1-bin/*/gradle-8.11.1/bin/gradle | head -1)}"
mkdir -p libs
unzip -o -j -q "$PLANTILLA" libs/release/godot-lib.template_release.aar -d libs
echo "sdk.dir=$SDK" > local.properties
"$GRADLE" --no-daemon -q assembleRelease
SAL=../../godot/addons/landrace_play/bin
mkdir -p "$SAL"
cp build/outputs/aar/landrace-play-release.aar "$SAL/landrace-play.aar"
ls -l "$SAL/landrace-play.aar"
