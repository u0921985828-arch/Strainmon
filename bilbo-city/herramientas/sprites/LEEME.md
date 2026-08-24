# Sprites traídos de PixelLab

El juego forja su arte por código y seguirá pudiendo hacerlo. Esto es la vía alternativa:
bajar sprites de [PixelLab](https://www.pixellab.ai), cuantizarlos a la paleta del juego y
empaquetarlos en la hoja que el juego ya sabe leer.

```bash
export PIXELLAB_API_KEY=...
python3 herramientas/sprites/pixellab.py --que protagonista,ertzaina
python3 herramientas/sprites/pixellab.py --simular      # sin red ni clave
```

## Hace falta dos cosas que aquí no hay

1. **Una clave de API.** No hay ninguna en el repositorio ni en el entorno, y no debe
   haberla: va por `PIXELLAB_API_KEY`.
2. **Salida a internet hacia `api.pixellab.ai`.** El contenedor de las sesiones de Claude
   la tiene cerrada — el proxy contesta 403 al CONNECT — así que **esto se ejecuta en
   local**, no desde una sesión.

`--simular` existe justo por eso: dibuja siluetas de relleno con el mismo tamaño y el
mismo recorrido, y sirve para comprobar que el empaquetado, la compresión, la escritura
en el HTML y la carga en el juego funcionan **antes** de gastar una sola llamada. Está
probado así de punta a punta.

## Qué hace exactamente

Por cada arquetipo pide 8 direcciones × 14 poses = **112 imágenes**, y con ellas monta la
hoja de 8 columnas por 14 filas que el juego dibuja. Ojo al coste: cuatro personajes son
448 llamadas.

Lo que baja se guarda en `cache/` —que no va al repositorio— así que repetir una tirada no
se paga dos veces y cambiar solo el empaquetado no cuesta nada. **Lo simulado y lo traído
se guardan con clave distinta** (`sim_` y `api_`): sin eso, el `--simular` que se recomienda
arriba dejaba la caché llena de monigotes, la tirada de verdad los encontraba, no llamaba a
PixelLab ni una vez y terminaba diciendo que todo había ido bien.

## Por qué no entra ni un PNG

El repositorio no lleva imágenes, y esto no lo cambia. La hoja se escribe en el bloque
`/*<<<SPRITES*/` del HTML como **un índice de paleta por píxel**, comprimida con deflate y
en base64 — el mismo formato que la trama de la ciudad. El juego sigue siendo un archivo
solo y el arte sigue atado a los 48 colores de la paleta.

Un arquetipo que no esté en la hoja **se forja por código**, como siempre. Se puede traer
de dos en dos y nunca se queda un personaje sin dibujar.

## Si la API contesta raro

Los nombres de los extremos y de los campos están todos juntos al principio de
`pixellab.py`, en `API_*`: es lo único que puede haber cambiado desde que se escribió
esto. Cuando la respuesta no trae imagen donde se espera, el error imprime el cuerpo
entero — leerlo es más rápido que adivinar.
