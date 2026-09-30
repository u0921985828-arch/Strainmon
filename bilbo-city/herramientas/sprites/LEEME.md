# Los sprites de personaje

El juego forja su arte por código, y los personajes también. Este directorio es el
empaquetador: de donde salgan las 385 celdas, las cuantiza a la paleta del juego y las
escribe en la hoja que el juego ya sabe leer.

**Salen de tres sitios, y el que manda es el primero.**

| | |
|---|---|
| `--mano` | **lo que se usa.** Las celdas se dibujan aquí mismo: trazados SVG sobre un esqueleto (`cuerpos.py` + `vector.py`), fotografiados y reducidos. Ni red, ni clave, ni un céntimo, y cien por cien nuestras. |
| (nada) | PixelLab. Necesita clave y salida a internet. Queda como alternativa, no como dependencia. |
| `--simular` | monigotes de relleno. No valen para jugar: valen para ejercitar el empaquetador. |

```bash
python3 herramientas/sprites/pixellab.py --mano           # lo normal: sin red ni clave
export PIXELLAB_API_KEY=...
python3 herramientas/sprites/pixellab.py --coste          # solo la cuenta
python3 herramientas/sprites/pixellab.py --simular        # monigotes, sin red ni clave
python3 herramientas/sprites/pixellab.py                  # las siete siluetas, de PixelLab
python3 herramientas/sprites/pixellab.py --que largo_pantalon,abrigo_pantalon
python3 herramientas/sprites/pixellab.py --diag --que largo_pantalon   # reparto por partes
python3 herramientas/sprites/pixellab.py --lamina hojas.png --esc 4     # verlas sin abrir el juego
python3 herramientas/sprites/pixellab.py --prompts --que abrigo_falda   # qué se pediría
```

`--prompts` escribe las descripciones tal cual se mandarían, con su longitud, y no pide
nada: ni red, ni clave, ni un céntimo. Es el único sitio donde el texto se puede leer —de
la API vuelve la imagen, no lo que entendió— y por tanto el único sitio donde se afina
antes de gastar la tirada y no después. Léelo entero de una silueta antes de lanzar las
siete.

`--lamina` vuelca las hojas empaquetadas a un PNG usando solo Pillow: enseñar una tirada no
obliga a compilar `node-canvas`. Sale la hoja **tal como se guardó**, con los colores de
plantilla en sus rampas, que es justo lo que hay que mirar — piel en tonos carne, pelo en
marrones, torso en azules, piernas en verdes, calzado en maderas. Una manga en tonos carne
es el reparto equivocándose.

## Las celdas se dibujan aquí: un esqueleto y un SVG, no un mapa de píxeles

`cuerpos.py` no guarda dibujos: guarda **huesos**. Catorce puntos por pose —cabeza, cuello,
hombros, codos, manos, caderas, rodillas, tobillos y puntas— y un grosor por tramo.

Quien los dibuja es `vector.py`, en **SVG**, y ahí está la gracia: un SVG es texto, se
escribe aquí igual que los números del esqueleto, pero **se fotografía**. Se dibuja en
unidades de celda con decimales —una cabeza son ocho puntos de una curva, no ciento
cuarenta rectángulos—, `capturar.js` hace **una sola foto** de las 55 con Chromium a ×16, y
la reducción por mayoría decide qué píxel se enciende. A ×16 y con `shape-rendering=crispEdges`
cada submuestra es un color plano y exacto, así que la reducción es una cuenta y no una
adivinanza.

Lo que da el SVG y no daba la cápsula: el hombro que cae, la cintura metida, el bulto del
puño, la cuña del zapato y el flequillo. Y se puede abrir y mirar.

    python3 herramientas/sprites/vector.py foto.png   # las 55 en bruto, para mirarlas
    python3 herramientas/sprites/vector.py --escribe  # revelarlas a celdas.py

`celdas.py` es la foto ya recortada, **generada y guardada en el repositorio**: capturar
necesita node y el Chromium de Playwright, y el empaquetador tiene que poder correr sin
ninguno de los dos. No se edita a mano; después de tocar un hueso o un trazado, se rehace.

Antes de todo esto fueron 55 rejillas de texto escritas a mano, y salía cuadrada: un cuerpo
apilado a base de rectángulos tiene los hombros, la cintura y la cadera del mismo ancho, y
redondearle las esquinas después no lo arregla.

Lo que se gana, además de la forma:

* **Una pose son catorce números.** Mover un brazo es cambiar un par; antes era reescribir
  ocho filas de veinticuatro caracteres sin descuadrar ninguna.
* **Es la misma persona en las 55.** El esqueleto base es uno por vista —de frente, de tres
  cuartos y de perfil— y las poses solo lo desplazan, así que la estatura, el ancho de
  hombros y el tamaño de la cabeza no pueden bailar entre celdas. Es justo lo que no
  garantiza pedir 385 dibujos sueltos a un generador.
* **Cinco cabezas y once poses, no 55 dibujos.** La cabeza cambia con la dirección y el
  cuerpo con la pose, y de las cinco direcciones el cuerpo solo distingue tres. Lo único
  que separa las cinco direcciones de una misma vista es por dónde corta el pelo.
* **El volumen no se dibuja: se calcula.** `trazos.py` saca la normal de cada píxel de la
  propia forma y la ilumina desde arriba a la izquierda, igual en las 385. Sombreadas a
  ojo no saldrían iguales entre sí y el baile se vería al animarlas.

## Cada parte se pinta ya en su rampa

Las rampas de la paleta tienen ocho tonos para la piel y cuatro para chaqueta, pantalón y
pelo. `luces_rampa()` le pasa al pintor la **luminancia exacta** de cada uno de esos tonos,
así que cada píxel nace en el escalón en el que va a acabar en vez de aplastarse contra el
más parecido. Es la diferencia entre una figura de tres colores y una con bulto, y es lo
que comprueba `pruebas_sprites.py`: si la piel deja de usar cinco de sus ocho tonos, la
batería lo canta.

El matiz sigue siendo el de plantilla —la piel tono carne, el torso magenta, las piernas
verdes— porque el reparto por partes va por matiz. Para subir de brillo sin poder subir más
el color (el azul puro ya está a tope) se mezcla con blanco: baja la saturación pero deja
el matiz clavado, que es por lo único que el empaquetado reconoce la parte.

Y una costura: donde el brazo toca el torso va el tono más oscuro de la rampa. Comparten
color, y sin esa raya el brazo y el pecho se funden en un solo bloque.

## Una celda, siete siluetas

Se escribe **un** cuerpo —la chaqueta a la cadera y el pantalón entero— y las otras seis
siluetas salen de ése por regla, en `trazos.viste`: el abrigo baja el torso hasta la
rodilla, la falda cierra el hueco entre las piernas y cae con vuelo, el pantalón corto sube
el bajo por encima de la rodilla y deja la pantorrilla al aire, la manga corta pasa el
antebrazo a piel. Por eso son 55 celdas y no 385.

La rodilla se mide sobre la parte **maciza** de la pierna, no sobre el primer píxel que
asoma. De frente el muslo va detrás del tronco y de la cadera solo asoman dos píxeles a
cada lado: midiendo contra esas migas, el pantalón corto empezaba por encima del faldón y
la silueta se quedaba sin un solo píxel de pantalón que repintar.

## Y si se baja de PixelLab: no se baja un personaje, se baja una silueta

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

## Cómo está escrita cada petición

Una descripción son seis trozos, en este orden, y el orden importa: lo que va delante pesa
más, y no todo se puede arreglar después.

| | | |
|---|---|---|
| **El estarcido** | `SETS` + `CLAVES` | Quién es y de qué color de plantilla va cada parte. Va primero porque es lo único irrecuperable: si el pantalón vuelve del color de la chaqueta, la celda está perdida — el empaquetado reparte por matiz, no adivina. |
| **Qué hace** | `DIBUJOS` | Brazos y piernas, dicho entero. A 32 píxeles no se lee la cara: se lee el hombro, el paso y el bulto de la cabeza. |
| **Hacia dónde mira** | `MIRADA` | Escrito, no solo en el campo `direction` de la API, que es una etiqueta y no dice qué se ve desde ahí. Va en términos de pantalla —«a la derecha del cuadro»— y no del personaje: su derecha es nuestra izquierda, y el espejo de las tres direcciones que no se piden depende de que esto no se lea de dos maneras. |
| **Qué hace su ropa** | `NOTAS` | Por dónde acaba la prenda y qué tapa. Es lo que distingue una silueta de otra a esta escala; sin ello, el abrigo largo y la cazadora vuelven el mismo dibujo con otro color. Y tiene parte mecánica: si el abrigo tapase la pierna entera, la rampa `piernas` se quedaría sin un píxel que repintar. Por eso la gabardina va abierta. |
| **La misma persona** | `MISMA` | La semilla fija el ruido de partida, no el contenido; con la pose cambiando tanto, dos llamadas con la misma semilla se van de complexión. |
| **El encuadre y el estilo** | `ENCUADRE`, `ESTILO` | Cierran porque se repiten en las 385. El encuadre es el que hace que las celdas se puedan animar seguidas: cabeza en la segunda fila, suelas en la última, caderas en la columna del medio. |

Ninguna lleva un «no»: lo que no se quiere vive en `NEGATIVO`, en su propio campo. Mezclado
con lo positivo, el «no» compite con lo que sí se pide y encima el generador dibuja lo que
se le nombra. `pruebas_sprites.py` lo comprueba en las 385, y comprueba también que ninguna
pasa de 1250 caracteres — una correa, no un límite de la API: a las diez frases el
generador reparte la atención y deja de hacer caso a la primera, que es la que importa.

Que más texto salga mejor **no está medido**, y desde una sesión sin red no se puede medir.
Se mira con `--prompts` y se prueba con una silueta antes de lanzar las siete.

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
`/*<<<SPRITES*/` como **un índice de paleta por píxel**, comprimida con deflate y en
base64 — el mismo formato que la trama de la ciudad. El juego sigue siendo un archivo solo
y el arte sigue atado a los colores de la paleta.

Y se escribe **en los dos sitios a la vez**: el HTML y
`unity/BilboCity/Assets/Scripts/Arte/Siluetas.cs`, igual que hace el extractor del plano.
Ninguno de los dos bloques se edita a mano; regenerarlos es volver a correr esto.
`herramientas/plano/siluetas.py` compara celda, rampas, nombres y bytes, y está dentro de
`./verificar.sh`: si solo se commitea uno, la verificación se para.

## Si la API contesta raro

Los nombres de los extremos y de los campos están todos juntos al principio de
`pixellab.py`, en `API_*`: es lo único que puede haber cambiado desde que se escribió
esto. Cuando la respuesta no trae imagen donde se espera, el error imprime el cuerpo
entero — leerlo es más rápido que adivinar.

Un 429 o un 5xx se reintentan cuatro veces, esperando el doble cada vez. No es un lujo:
una tirada son 385 llamadas seguidas y sin eso un solo 429 a media tirada se llevaba por
delante todo lo ya pagado. Un 401 no se reintenta — por insistir no mejora una clave mala.
