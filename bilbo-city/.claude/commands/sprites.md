---
description: Trae de PixelLab una silueta de sprites y juzga si el estarcido salió limpio
---

Trae de PixelLab la silueta que te digan —o `largo_pantalon` si no dicen ninguna— y juzga
el resultado.

**Comprueba primero que hay salida**, porque de esto depende dónde se puede ejecutar:

```
curl -s -o /dev/null -w '%{http_code}\n' --max-time 12 https://api.pixellab.ai/v1/balance
```

`000` significa que la política de red del entorno remoto no tiene permitido
`api.pixellab.ai`, y no hay forma de saltárselo desde dentro: o lo abre el dueño del
entorno en claude.ai/code, o esto se ejecuta en local. Cualquier otro código —incluso un
401— quiere decir que se llega y se puede tirar desde aquí.

Lee antes `herramientas/sprites/LEEME.md`: explica por qué se baja una silueta y no un
personaje, y qué es cada color de plantilla.

1. Comprueba que hay clave: `PIXELLAB_API_KEY` en el entorno. Si no está, párate y pídela
   — nunca la escribas en ningún fichero del repositorio.
2. Si en la caché hay imágenes de una tirada anterior con otros textos, bórrala
   (`herramientas/sprites/cache/`). Si no, te devolverá las de antes sin llamar a nadie.
3. Lanza la tirada con diagnóstico y lámina:

   ```
   python3 herramientas/sprites/pixellab.py --diag --que <silueta> --lamina hojas.png --esc 4
   ```

4. **Abre `hojas.png` y míralo.** No des por buena una tirada sin verla. Lo que sale es la
   hoja tal como se guardó, con los colores de plantilla en sus rampas:

   | Parte | Rampa | Tiene que salir en |
   |---|---|---|
   | piel | `tez0..7` | tonos carne |
   | pelo | `ladrillo0..3` | marrones |
   | torso | `ria2..5` | azules |
   | piernas | `verde2..5` | verdes |
   | calzado | `luz2..4` | ocres |

   Una manga en tonos carne, o un pantalón en azules, es el reparto por partes
   equivocándose. El personaje se verá mal en el juego y no saltará ningún error.

5. Lee también los avisos de la consola. `sin <parte>` = el generador ignoró ese color de
   plantilla y esa parte no se podrá repintar. `N% desvaído` = devolvió la celda apagada y
   el reparto se apoyó en la vecindad en vez de en el color.

Si algo de lo anterior falla, **ajusta y vuelve a tirar** antes de bajar más siluetas:
`CLAVES` para los colores de plantilla y `ESTILO` para el «bloques planos, sin degradados
ni tramado» que los mantiene separables. Los dos están al principio de `pixellab.py`.
Después de cada cambio, `python3 herramientas/sprites/pruebas_sprites.py`.

Cuando la silueta salga limpia:

- `./verificar.sh html` tiene que pasar en verde.
- Saca las hojas repintadas para verlas de verdad, si tienes `node-canvas` compilado:
  `node herramientas/html/personajes.js --esc 6 --que protagonista,amaia,p6`.
- Haz commit y push a `claude/new-session-e7mg1m`, incluyendo el bloque `SPRITES` del HTML.
  Es la única forma de que la sesión en la nube vea el resultado.
- Di cuántas llamadas quedan: son 55 por silueta y 385 las siete.

Y no dejes en el repositorio una hoja simulada (`--simular`): son monigotes de relleno.
