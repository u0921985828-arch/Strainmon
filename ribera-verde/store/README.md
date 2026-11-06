# store/ · lo que pide Google Play (fase 2 del plan)

Todo para la versión de la tienda (`Datos.PLAY = true`, paquete `com.landracehunters.game`). Nada de esto se sube solo: lo
pega Eddie en la Play Console.

| Archivo | Para qué |
|---|---|
| `privacy-policy.md` | La política de privacidad (es + en), para publicarla en una URL pública |
| `data-safety.md` | Respuestas al formulario «Seguridad de los datos» |
| `iarc.md` | Respuestas al cuestionario de clasificación (drogas, delito, violencia leve; sin apuestas) y público objetivo |
| `ficha-es.md`, `ficha-en.md` | Título, descripción corta y larga (con el aviso) y los demás campos |
| `graficos/icono-512.png` | Icono de alta resolución (512 × 512) |
| `graficos/destacado-1024x500.png` | Gráfico destacado (1024 × 500) |
| `graficos/captura-1..8-*.png` | 8 capturas de 1920 × 1080 (16:9), del juego con PLAY |

Rehacer las capturas y el destacado (desde `ribera-verde/godot`, con xvfb y Godot 4.7):

    xvfb-run -a -s "-screen 0 2600x1700x24" $GODOT --path . --rendering-driver opengl3 --audio-driver Dummy \
      --resolution 1920x1080 --script res://tests/capturas.gd -- --sin-arranque --salida ../store/graficos

Medir las fichas: `python3 -I tools/ficha.py` (desde `ribera-verde/`).
