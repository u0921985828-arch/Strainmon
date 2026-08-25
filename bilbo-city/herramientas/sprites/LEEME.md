# Sprites traídos de PixelLab

El juego forja su arte por código y seguirá pudiendo hacerlo. Esto es la vía alternativa:
bajar dibujos de [PixelLab](https://www.pixellab.ai), cuantizarlos a la paleta del juego y
empaquetarlos en la hoja que el juego ya sabe leer.

```bash
export PIXELLAB_API_KEY=...
python3 herramientas/sprites/pixellab.py --coste          # solo la cuenta
python3 herramientas/sprites/pixellab.py --simular        # sin red ni clave
python3 herramientas/sprites/pixellab.py                  # las siete siluetas
python3 herramientas/sprites/pixellab.py --que largo_pantalon,abrigo_pantalon
python3 herramientas/sprites/pixellab.py --diag --que largo_pantalon   # reparto por partes
python3 herramientas/sprites/pixellab.py --lamina hojas.png --esc 4     # verlas sin abrir el juego
```

`--lamina` vuelca las hojas empaquetadas a un PNG usando solo Pillow: enseñar una tirada no
obliga a compilar `node-canvas`. Sale la hoja **tal como se guardó**, con los colores de
plantilla en sus rampas, que es justo lo que hay que mirar — piel en tonos carne, pelo en
marrones, torso en azules, piernas en verdes, calzado en maderas. Una manga en tonos carne
es el reparto equivocándose.

## No se baja un personaje: se baja una silueta

Un vecino de Bilbao no es un dibujo, es una combinación: complexión, torso, piernas,
calzado, peinado, gorro y bolsa. Pedirle a PixelLab cada combinación entera son ochenta
hojas para vestir a treinta y cuatro arquetipos, y el número treinta y cinco vuelve a
costar lo mismo que el primero. Así que se baja lo único que no se puede fabricar —**la
silueta**— y todo lo demás se pone encima:

| | |
|---|---|
| **Se baja** | el cuerpo con su ropa: chaqueta y pantalón, abrigo, falda, pantalón corto, capucha. |
| **Se repinta** | el color de la chaqueta, del pantalón, del calzado, de la piel y del pelo. |
| **Se forja encima** | el pelo largo, la txapela, el casco de obra, la mochila, el carro de la compra y el fogonazo. |

La hoja no viene pintada de los colores finales: viene de **colores de plantilla**, uno por
parte del cuerpo —magenta el torso, verde las piernas, cian el calzado, azul el pelo— y el
empaquetado los guarda cada uno en su propia rampa de la paleta. Como las rampas no se
tocan entre sí, repintar es cambiar índices por índices: la tabla de 256 bytes que arma
`lutDe()` en el juego. Un vecino nuevo cuesta **cero llamadas**.

De propina, dos cosas salen gratis de ahí: **calvo** es mandarle el pelo al color de su
piel, y **canoso** es mandárselo al gris. Ninguno de los dos necesita hoja propia.

## De cada silueta se baja menos de lo que se ve

* **Cinco direcciones de ocho.** Oeste es este del revés, y lo mismo las dos diagonales.
  El precio de esto es que un personaje asimétrico cambia de mano al girar — por eso la
  bolsa y la mochila no van en la hoja, sino forjadas encima.
* **Once dibujos de dieciséis poses.** Los dos pasos de apoyo del andar son el mismo
  dibujo, las dos zancadas de la carrera también, y **disparar es apuntar** con el
  fogonazo encima y un píxel de retroceso, que lo pone el juego. Las poses que repiten
  dibujo van desplazadas un píxel para que no se queden clavadas.

## La cuenta

| | Llamadas | A quién viste |
|---|---|---|
| Un personaje entero, 8 direcciones × 16 poses | 128 | a uno |
| Una silueta, 5 direcciones × 11 dibujos | **55** | a todos los que la lleven |
| Las siete siluetas | **385** | los 34 arquetipos, y los que se inventen después |

**Bajar una sola ya es jugable.** El juego busca para cada arquetipo la silueta más
parecida a su ropa, y si no hay ninguna lo forja como siempre: nunca se queda nadie sin
dibujar. Se puede empezar por `largo_pantalon`, mirar cómo queda y seguir.

## Hace falta dos cosas que aquí no hay

1. **Una clave de API.** No hay ninguna en el repositorio ni en el entorno, y no debe
   haberla: va por `PIXELLAB_API_KEY`.
2. **Salida a internet hacia `api.pixellab.ai`.** El contenedor de las sesiones de Claude
   la tiene cerrada — el proxy contesta 403 al CONNECT — así que **esto se ejecuta en
   local**, no desde una sesión.

`--simular` existe justo por eso: dibuja monigotes de relleno con los mismos colores de
plantilla y el mismo recorrido, y sirve para comprobar que el troceado, el repintado, la
compresión, la escritura y la carga en el juego funcionan **antes** de gastar una sola
llamada. Está probado así de punta a punta. Lo que sale no vale para jugar: después,
`git checkout referencia/bilbo-city.html`.

Lo que baja se guarda en `cache/` —que no va al repositorio— así que repetir una tirada no
se paga dos veces y cambiar solo el empaquetado no cuesta nada. **Lo simulado y lo traído
se guardan con clave distinta** (`sim_` y `api_`): sin eso, el `--simular` que se recomienda
arriba dejaba la caché llena de monigotes, la tirada de verdad los encontraba, no llamaba a
PixelLab ni una vez y terminaba diciendo que todo había ido bien.

## Medidas y paleta

La celda es de **24×32 con el pivote en (12,30)** y la paleta la de **61 colores**: las dos
las fija `CONTEXT.md` §18, y el empaquetador **las lee del propio juego**, no las lleva
escritas. Si mañana cambian allí, aquí no hay nada que tocar.

Las rampas de plantilla van por familia de la paleta —`tez0..tez7` para la piel,
`ladrillo0..3` para el pelo, `ria2..5` para el torso, `verde2..5` para las piernas y
`luz2..4` para el calzado—, que es lo que esta pieza necesitaba y antes había que apañar
juntando colores sueltos.

## La paleta va forzada

A cada petición se le manda `color_image`: un PNG con los 24 tonos de las rampas de
plantilla y ninguno más. Eso cierra la lista de colores que el generador puede usar, así
que **lo que vuelve ya viene en las rampas** y el reparto por partes deja de tener que
adivinar. Antes se le pedía «magenta vivo» y se confiaba en que no lo apagara.

Y todas las celdas de una silueta van con **la misma semilla**, sacada de su nombre. Sin
eso, cada una de las 55 llamadas inventa una persona distinta y el que anda cambia de cara
a cada paso.

## Lo que hay que mirar en la primera tirada

Todo esto se sostiene sobre una cosa: que el generador **respete los colores de plantilla**.
Si devuelve la chaqueta sombreada hacia el gris, o se salta un color, el reparto por partes
se equivoca y no salta ningún error — sale un vecino con media manga del color de la piel y
no se ve hasta tenerlo en el juego. Por eso el empaquetador avisa solo:

```
¡ojo! largo_pantalon quieto south: sin calzado, 61% desvaído
```

«sin *algo*» es que ese color de plantilla no aparece: el generador lo ignoró, y esa parte
no se podrá repintar. «desvaído» es que devolvió la mayoría de los píxeles sin saturación,
y el reparto se está apoyando en la vecindad en vez de en el color. Con cualquiera de los
dos, **para y ajusta el texto antes de seguir**: `CLAVES` para los colores y `ESTILO` para
el «sin degradados, sin tramado» que los mantiene separables. `--diag` enseña el recuento
de cada celda.

El reparto se hace **por matiz**, no por color normalizado, y el contorno se reconoce por
no tener color, no por ser oscuro. Las dos cosas costaron un fallo cada una: normalizando,
un brillo del pelo azul se acercaba más al magenta del torso que al azul, y media cabeza
salía repintada de color chaqueta; y con el contorno por oscuridad, el azul del pelo
—luminancia 29 a plena intensidad— se iba entero al contorno y el personaje salía calvo.

## Cómo se comprueba sin bajar nada

Dos baterías, las dos dentro de `./verificar.sh`.

`herramientas/sprites/pruebas_sprites.py` le da al empaquetador colores fabricados —cada
color de plantilla con su sombra y su brillo, negros de contorno, grises sueltos— y
comprueba que cada uno acaba en la rampa que le toca, que los matices de plantilla están a
60° unos de otros, que las poses del juego salen todas de los once dibujos sin sobrar
ninguno, y que la hoja simulada tiene de verdad sus tres direcciones en espejo y su
retroceso de un píxel al disparar.

La batería del HTML monta una hoja de mentira con las rampas y verifica el otro extremo:
que los nombres de silueta que espera el juego son los que baja el empaquetador, que cada
arquetipo encuentra silueta, que el repintado le pone a cada uno su ropa y que dos vecinos
de la misma silueta no salen clavados. `--coste` revisa las tablas sin tocar nada.

## Por qué no entra ni un PNG

El repositorio no lleva imágenes, y esto no lo cambia. La hoja se escribe en el bloque
`/*<<<SPRITES*/` del HTML como **un índice de paleta por píxel**, comprimida con deflate y
en base64 — el mismo formato que la trama de la ciudad. El juego sigue siendo un archivo
solo y el arte sigue atado a los 48 colores de la paleta.

## Si la API contesta raro

Los nombres de los extremos y de los campos están todos juntos al principio de
`pixellab.py`, en `API_*`: es lo único que puede haber cambiado desde que se escribió
esto. Cuando la respuesta no trae imagen donde se espera, el error imprime el cuerpo
entero — leerlo es más rápido que adivinar.

Un 429 o un 5xx se reintentan cuatro veces, esperando el doble cada vez. No es un lujo:
una tirada son 385 llamadas seguidas y sin eso un solo 429 a media tirada se llevaba por
delante todo lo ya pagado. Un 401 no se reintenta — por insistir no mejora una clave mala.
