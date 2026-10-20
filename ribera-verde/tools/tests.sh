#!/usr/bin/env bash
# Todas las suites de godot/tests. Uso: G=/ruta/godot tools/tests.sh [salida]
# Las que pintan (mandos_geo, ciclo, extracciones, retratos, pantallas, prueba, capas) van con xvfb y opengl3.
cd "$(dirname "$0")/../godot" || exit 1
G=${G:-/home/user/godot-bin/Godot_v4.7-stable_linux.x86_64}
OUT=${1:-/tmp/lh-tests}; mkdir -p "$OUT"
X=(xvfb-run -a -s "-screen 0 2600x1700x24")
P=(--rendering-driver opengl3 --audio-driver Dummy --resolution 1560x720)
export LIBGL_ALWAYS_SOFTWARE=1
GRAF=" mandos_geo pixel ciclo extracciones pantallas prueba capas capturas capturas_ui perf ftue retratos "
for f in tests/*.gd; do
  t=$(basename "$f" .gd)
  case "$GRAF" in *" $t "*) continue;; esac
  echo "== $t"; timeout 900 "$G" --headless --path . --script "res://tests/$t.gd" 2>&1 | grep -E "^$t: |SCRIPT ERROR|Parse Error" | tail -3
done
echo "== mandos_geo"; timeout 1200 "${X[@]}" "$G" --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 2600x1700 --script res://tests/mandos_geo.gd -- --sin-arranque 2>&1 | grep -E "^mandos_geo: |SCRIPT ERROR|Parse Error" | tail -3
echo "== pixel"; timeout 900 "${X[@]}" "$G" --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 2600x1700 --script res://tests/pixel.gd 2>&1 | grep -E "^pixel: |FALLO|SCRIPT ERROR|Parse Error" | tail -5
for t in prueba capas; do
  echo "== $t"; timeout 1200 "${X[@]}" "$G" --path . "${P[@]}" --script "res://tests/$t.gd" 2>&1 | grep -E "^(C1|C2|capas): |SCRIPT ERROR|Parse Error" | tail -3
done
echo "== extracciones"; timeout 1200 "${X[@]}" "$G" --path . "${P[@]}" --script res://tests/extracciones.gd -- --sin-arranque --salida "$OUT/ex" 2>&1 | grep -E "^extracciones: |SCRIPT ERROR|Parse Error" | tail -3
echo "== retratos"; timeout 900 "${X[@]}" "$G" --path . "${P[@]}" --script res://tests/retratos.gd -- --sin-arranque 2>&1 | grep -E "^retratos: |SCRIPT ERROR|Parse Error" | tail -3
echo "== pantallas"; mkdir -p "$OUT/pp"; cp ../tools/ref/pantallas/html-p-*.png "$OUT/pp/"
timeout 1500 "${X[@]}" "$G" --path . "${P[@]}" --script res://tests/pantallas.gd -- --sin-arranque --pintar "$OUT/pp" 2>&1 | grep -E "^C2 pantallas: |SCRIPT ERROR|Parse Error" | tail -3
echo "== ciclo"; timeout 1800 "${X[@]}" "$G" --path . "${P[@]}" --fixed-fps 60 --script res://tests/ciclo.gd -- --salida "$OUT/ciclo" 2>&1 | grep -E "^ciclo: |SCRIPT ERROR|Parse Error" | tail -3
for L in es en; do echo "== capturas_ui $L"; timeout 900 "${X[@]}" "$G" --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 2400x1080 --script res://tests/capturas_ui.gd -- --salida "$OUT/capui-$L" --idioma $L --dpi 420 2>&1 | grep -E "^capturas_ui: |SCRIPT ERROR|Parse Error" | tail -3; done
echo "== ftue"; timeout 900 "${X[@]}" "$G" --path . "${P[@]}" --fixed-fps 60 --script res://tests/ftue.gd 2>&1 | grep -E "^ftue: |^FALLO|SCRIPT ERROR|Parse Error" | tail -3
echo FIN_BATERIA
