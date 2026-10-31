#!/usr/bin/env bash
# Landrace Hunters — la plantilla web sin hilos (web_nothreads_release) de Godot 4.7 compilada con la clave AES-256 del index.pck
# (lo pidió el usuario: «que los scripts no se puedan leer del paquete»). La clave, en ~/.landrace/pck.key (64 hex, fuera del repo;
# este script no la imprime). Deja ~/.landrace/web_nothreads_release.zip, que usa `node tools/wordpress.js --cifrar`.
# Necesita: scons (pip install scons), Emscripten 4.0.11 (el de los builds web de Godot 4.7) y unos 4 GB libres; tarda ~1 h con 4 núcleos.
#   tools/plantilla-web.sh [carpeta de las fuentes, /home/user/godot-src] [carpeta de emsdk, /home/user/emsdk]
set -euo pipefail
SRC=${1:-/home/user/godot-src}
EMSDK=${2:-/home/user/emsdk}
CLAVE_F=${LH_CLAVE:-$HOME/.landrace/pck.key}
OUT=$HOME/.landrace/web_nothreads_release.zip
grep -qE '^[0-9a-fA-F]{64}$' "$CLAVE_F" || { echo "falta la clave de 64 hex en $CLAVE_F"; exit 1; }
[ -d "$SRC/.git" ] || git clone -q --depth 1 --branch 4.7-stable https://github.com/godotengine/godot "$SRC"
if [ ! -x "$EMSDK/emsdk" ]; then git clone -q --depth 1 https://github.com/emscripten-core/emsdk.git "$EMSDK"; fi
"$EMSDK/emsdk" install 4.0.11 >/dev/null
"$EMSDK/emsdk" activate 4.0.11 >/dev/null
# shellcheck disable=SC1091
source "$EMSDK/emsdk_env.sh" >/dev/null 2>&1
cd "$SRC"
SCRIPT_AES256_ENCRYPTION_KEY=$(cat "$CLAVE_F") scons platform=web target=template_release threads=no -j"$(nproc)" >/dev/null
cp bin/godot.web.template_release.wasm32.nothreads.zip "$OUT"
chmod 600 "$OUT"
rm -rf bin/obj   # los objetos (varios GB)
echo "plantilla: $OUT ($(stat -c %s "$OUT") bytes)"
