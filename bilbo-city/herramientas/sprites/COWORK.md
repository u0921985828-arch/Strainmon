# Encargo para Cowork · bajar los sprites de PixelLab

Este fichero es el parte de entrega para una sesión que corra **en local** —Cowork de
escritorio, o Claude Code en tu máquina—. No repite lo que ya está escrito: da el encargo, el
porqué, y dónde está cada cosa.

**Lee antes, en este orden:** `bilbo-city/CLAUDE.md` (el proyecto entero) y
`herramientas/sprites/LEEME.md` (cómo funciona esta pieza y la tirada paso a paso).

---

## Por qué esto no se hace desde una sesión remota

El contenedor de las sesiones de Claude en la nube tiene la salida cerrada hacia
`api.pixellab.ai`: la pasarela de egress contesta **403 al CONNECT** y la petición nunca sale.
Da igual la vía —clave por HTTP, `claude mcp add`, o `mcp-remote`—, las tres chocan con el
mismo muro y el error lo dice con todas las letras:

```
Host not in allowlist: api.pixellab.ai.
Add this host to your network egress settings to allow access.  (403)
```

No es la clave: es la política de red del entorno. **En una máquina local no existe ese
muro**, y por eso el encargo es este.

> Si algún día se permite el host en los ajustes del entorno, la vía remota se abre y esto
> se puede hacer allí también. Hasta entonces, local.

---

## El encargo, en una frase

Bajar de PixelLab las **siete siluetas** de personaje, comprobar que el generador respetó los
colores de plantilla, empaquetarlas en el bloque `SPRITES` del juego y dejar
`./verificar.sh` en verde.

## Lo que hay que respetar, sí o sí

- **Arte y código 100 % originales.** Nada con dueño: ni sprites de Pokémon, ni código de
  Habbo, ni descompilaciones, ni el wordmark de nadie. A PixelLab se le describe **el aspecto
  que queremos**, nunca «el estilo de tal juego»: pedirle a un generador la obra de otro es
  hacerle producir algo derivado de esa obra, y ese algo acabaría dentro del nuestro. El texto
  de `ESTILO` y `NEGATIVO` en `pixellab.py` ya está escrito con ese cuidado — no lo aflojes.
- **Ni un PNG en el repositorio.** La hoja se escribe como un índice de paleta por píxel,
  deflate y base64, dentro del HTML. El juego sigue siendo un archivo solo.
- **La clave nunca se commitea.** Va por `PIXELLAB_API_KEY` y no entra en ningún fichero del
  repositorio, ni en `.mcp.json`, ni en un comentario, ni en el mensaje de un commit.
- **Código y comentarios en español**, y los comentarios explican el **porqué**, no el qué.
- **Rama de trabajo:** `claude/personajes-script-run-6hav6m`. No empujes a otra.

## Cómo se hace

Está en `LEEME.md`, sección **«La tirada, paso a paso»**. El resumen del orden, que es lo que
importa, porque los tres primeros pasos son gratis y el cuarto cuesta 385 llamadas:

| | | Cuesta |
|---|---|---|
| 1 | `--coste` · confirma que la celda dice **32x42** | nada |
| 2 | `--simular` + `./verificar.sh html` + `git checkout` del HTML | nada |
| 3 | **una** silueta de verdad, con `--diag` y `--lamina` | 55 llamadas |
| 4 | el resto, si la de la 3 convence | 330 más |

**Si el paso 1 no dice `32x42`, para.** Esa es la medida a la que forja el juego
(`PJ_N`/`PJ_D`, hoy 4:3); la de diseño, 24×32, es otra cosa. Leerlo mal es exactamente lo que
tuvo esta vía muerta sin que nadie se enterara: el juego habría rechazado **toda** hoja
pagada por «medidas raras» y lo habría forjado todo igual, tan contento.

## Dónde tienes que parar y preguntar

Esto no es mecánico. Hay tres sitios donde la máquina no puede decidir sola:

1. **El aviso de plantilla.** Si sale `¡ojo! … sin calzado` o `… 61% desvaído`, el generador
   no respetó los colores de plantilla: esa parte no se podrá repintar y saldrá un vecino con
   media manga del color de la piel. **No sigas bajando.** Ajusta `CLAVES` (los colores) o
   `ESTILO` (el «sin degradados, sin tramado» que los mantiene separables), tira otra vez esa
   celda y vuelve a mirar. `--diag` da el recuento.
2. **La lámina del paso 3.** Sale con los colores de plantilla, no con los finales, y eso es
   justo lo que hay que mirar: piel en tonos carne, pelo en marrones, torso en azules, piernas
   en verdes, calzado en maderas. Cualquier cosa fuera de su rampa es el reparto
   equivocándose. Enséñala antes de pagar las otras seis.
3. **Si convence o no.** Si las figuras no se parecen a las que forja el juego —proporción,
   contorno, luz desde arriba a la izquierda—, el problema es el texto, no el empaquetado.
   Dilo en vez de seguir bajando.

## Cuándo está hecho

- `./verificar.sh` **entero en verde**. No des nada por bueno sin eso.
- `node herramientas/html/personajes.js --esc 6` mirado de verdad: los 38 arquetipos vestidos
  con las siluetas nuevas, cada uno con su ropa, y dos vecinos de la misma silueta que no
  salgan clavados.
- Commit en `claude/personajes-script-run-6hav6m`, sin la clave, sin PNGs y sin las hojas de
  `--simular`.

## Si prefieres el MCP en vez del script

PixelLab publica un MCP en `https://api.pixellab.ai/mcp`. En local funciona. La forma limpia
de configurarlo es **con el secreto fuera del repositorio**, en `.mcp.json`, apoyado en la
misma variable que ya usa el script:

```json
{ "mcpServers": { "pixellab": {
  "type": "http",
  "url": "https://api.pixellab.ai/mcp",
  "headers": { "Authorization": "Bearer ${PIXELLAB_API_KEY}" }
}}}
```

Claude Code expande `${...}` y avisa si la variable falta. **Ojo:** el MCP te da imágenes; el
trabajo de verdad —cuantizar a los 61 colores, repartir cada parte del cuerpo en su rampa,
comprimir y escribir el bloque `SPRITES`— lo hace `pixellab.py` y no hay atajo. Si bajas por
MCP, tendrás que meter esos PNG por la misma tubería igualmente.
