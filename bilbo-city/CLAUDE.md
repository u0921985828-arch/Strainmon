# Bilbo City

Juego sandbox 2D cenital ambientado en **Bilbao**, para móvil: ciudad abierta, historia
que no obliga, nivel de personaje y propiedades que se compran. Además del crimen se
pueden hacer curros honrados. Todo el arte y el audio se generan por código: **no hay ni
una imagen ni un archivo de sonido en el repositorio**.

## Las dos implementaciones

| | |
|---|---|
| `referencia/bilbo-city.html` | Prototipo completo, **ejecutado y probado**. Es la fuente de la verdad. |
| `unity/BilboCity/` | Puerto a Unity. **Compila** (Roslyn contra remedo de la API), pero **no se ha abierto en el editor**. Es el objetivo de producción. |

Cuando el comportamiento de los dos no coincida, **gana el HTML**: es el que está validado.
No cambies la lógica de juego en Unity sin comprobar antes qué hace el HTML.

## Antes de dar nada por terminado

```bash
./verificar.sh          # todo
./verificar.sh html     # solo el prototipo
./verificar.sh csharp   # solo Unity
```

Requisitos, una vez:

```bash
pip install -r herramientas/requirements.txt
cd herramientas/html && npm install    # compila 'canvas' de forma nativa
apt-get install -y dotnet-sdk-8.0      # Roslyn, para compilar el C# sin Unity
```

**No des por buena una tarea sin que `./verificar.sh` pase en verde.** Si tocas la trama
de la ciudad, saca también el plano y míralo (ver *La ciudad*):

```bash
node herramientas/html/plano.js
```

## Qué comprueba cada cosa

`herramientas/html/pruebas.js` arranca el juego de verdad sobre un DOM simulado con canvas
real: juega las 8 misiones, entra y sale de **todos** los interiores —la lista sale del
juego, así que uno nuevo se prueba solo— comprobando que tienen puerta, que las filas del
plano miden lo mismo y que no hay ningún tendero empotrado en una pared; compra ropa y
verifica que el sprite cambia; recorre las tres redes de transporte; comprueba el sigilo
—postura, cono, línea de vista, ruido y que un delito sin testigos no da estrellas—;
verifica que los sitios están sobre suelo pisable y cerca de donde los pone el plano; mide
la conectividad de la red viaria, y prueba combate, conducción desde 16 puntos al azar,
muerte y 150 s de bucle.

`herramientas/compilar/` compila el C# de verdad, sin tener Unity: hay un remedo de la API
del motor — solo firmas, nunca se ejecuta — y el juego se compila contra él con Roslyn, con
las opciones de Unity 2022.3 (netstandard2.1, C# 9) y la separación de ensamblados de los
`.asmdef`, así que el runtime no ve `UnityEditor`. Va con `-warnaserror`. **Si añades API
del motor que el remedo no tenga, añádela a `herramientas/compilar/apinado/Api/` con la
firma exacta de Unity** — una firma inventada de más tapa errores reales, que es lo único
que puede estropear esta herramienta.

`herramientas/plano/sitios.py` y `herramientas/plano/singulares.py` comparan las
coordenadas de los 57 sitios y las medidas de los 13 singulares entre el HTML y el C#. Es
la trampa clásica de tener dos implementaciones: el HTML pasa la batería, el C# no se
ejecuta aquí, y Unity acaba poniendo las cosas en otro lado sin que nadie lo vea.

`herramientas/csharp/` analiza el C# sobre el árbol de sintaxis real (tree-sitter). No es un
compilador, pero verifica sintaxis, miembros inexistentes, aridad de llamadas y
constructores, miembros de enum, tipos desconocidos y **listas modificadas mientras se
recorren** — este último es el fallo que más aparece al portar de JS a C#: en JS no pasa
nada, en C# la excepción salta en el siguiente `MoveNext`.

## Convenciones que hay que respetar

- **Código en español.** Nombres de clases, métodos, variables y comentarios. `Ciudad`,
  `Jugador`, `Rodable()`, `PuntoAcera()`. No mezcles inglés.
- **Comentarios que expliquen el porqué**, no el qué. Si un comentario repite lo que dice
  la línea siguiente, sobra.
- **Nada de físicas de Unity.** Ni `Rigidbody2D` ni `Collider2D`. La colisión es por casilla
  con deslizamiento por ejes (`Movimiento.Deslizar`). Es predecible y va rápido en móvil.
- **Paleta bloqueada de 48 colores.** Todo sprite pasa por `Paleta.Cuantizar`. No introduzcas
  colores nuevos sin añadirlos a la paleta.
- **Sin assets importados.** Ni PNG, ni WAV, ni fuentes TTF de terceros en el
  repositorio. Si necesitas algo nuevo, se forja por código en `Assets/Scripts/Arte/`.
  **Excepción con condiciones: los sprites de personaje pueden venir de PixelLab**
  (`herramientas/sprites/`), pero entran cuantizados a la paleta y escritos como índices
  comprimidos en el bloque `SPRITES`, nunca como archivo de imagen. Lo que falte se sigue
  forjando: el juego no puede depender de que haya hoja.
- **En artefactos web no uses `localStorage` directamente**: el HTML usa `window.storage` con
  respaldo a `localStorage`.
- **Nada de `Math.random()` en el prototipo.** Usa `azar()`, o `rnd(a,b)` / `rndi(a,b)`, que
  van por encima. El generador es sembrable (`sembrar(n)`) y la batería lo siembra, así que
  dos pasadas dan lo mismo. Un `Math.random()` suelto rompe eso y devuelve los rojos
  intermitentes que costó quitar.

## La trampa de la Y

En el mundo del juego la **Y crece hacia abajo** (como en un canvas). En Unity crece hacia
arriba. La conversión está centralizada:

- `Mundo.AMundo(Vector2)` / `Mundo.ACasilla(Vector3)` para posiciones.
- `Lienzo.VolcarEn(...)` voltea la Y al construir los atlas de textura.
- El ángulo de un vehículo se pasa a Unity con signo cambiado: `-Ang * Mathf.Rad2Deg`.

Si algo sale espejado o al revés, empieza mirando ahí.

## La ciudad

Bilbao no es procedural ni está trazada a mano: **está sacada del plano municipal**. El
plano oficial es un PDF vectorial y trae la ciudad en dos capas que se separan limpias:

- las **manzanas**, los parques y la ría son polígonos con su color de relleno;
- la **calzada** es un trazo blanco con el ancho real de cada calle — un callejón del
  Casco Viejo y la Gran Vía son la misma línea con distinto grosor.

`herramientas/plano/extraer.py` separa esas capas, las pasa a casillas y escribe el
resultado comprimido en el HTML y en `unity/.../Ciudad/Plano.cs` a la vez. Lo que se
dibuja son **las calles de Bilbao**, no unas calles verosímiles: la retícula del Ensanche,
la diagonal de la Gran Vía, la elipse de Moyúa, el meandro de Deusto, la Ribera de Deustu
entre el Canal de Deusto y la ría, las revueltas de Artxanda y las autopistas cruzando el
monte.

```bash
python3 herramientas/plano/extraer.py ruta/al/plano_bilbao.pdf
```

El mapa mide **1440×776 casillas a 5,16 m cada una**: 7,4 km de este a oeste por 4 de
norte a sur, el término municipal entero. Es rectangular porque el valle lo es.

**El bloque `/*<<<PLANO*/ … /*PLANO>>>*/` no se edita a mano** — ni en el HTML ni en
`Plano.cs`. Se vuelve a ejecutar el extractor.

### Qué se toma del plano y qué no

Se toma la **geometría**: por dónde va cada calle, dónde acaba una manzana, dónde está el
parque, dónde pone el ayuntamiento el rótulo de cada barrio. Eso son hechos geográficos de
la ciudad, no una creación de quien dibujó el plano. No se toma nada de su forma de
dibujarlo: ni colores, ni tipografías, ni símbolos, ni composición. **El PDF no entra en el
repositorio**; solo entra la rejilla derivada, y el juego la pinta con arte propio.

### Cuatro cosas que no son obvias y cuestan de encontrar

- **El plano pinta la ría de una vez y le devuelve el suelo encima.** La mancha de agua se
  come Zorrotzaurre, y la isla reaparece porque después le pintan el suelo blanco por
  encima. Por eso los rellenos se redibujan **en el orden del plano** (`seqno`) y el blanco
  es una clase más. Reordenando por clases, la Ribera de Deustu queda bajo el agua.
- **Las calles peatonales no llevan trazo blanco.** Las Siete Calles, media Bilbao la Vieja
  y los pasajes de los grupos de viviendas son el hueco entre manzanas y nada más. Lo que
  queda en blanco a menos de seis casillas de una casa es calle; el mismo blanco lejos de
  toda casa es monte.
- **La acera se saca erosionando la calzada, y eso parte la red.** En una calle de tres
  casillas en diagonal el interior queda en una hilera que solo se toca por la esquina, y
  los coches se mueven en cruz. Hay dos remiendos después del corte, uno local para las
  diagonales y otro global; la cifra a vigilar es la que imprime el extractor
  (`calzada en una pieza`, ahora 95,6 %) y la que mide la batería.
- **Los barrios se reparten por cercanía al rótulo, pero andando.** El agua no se cruza —
  los puentes tampoco — así que Deustu no se come Olabeaga aunque estén a doscientos metros
  a vuelo de pájaro. Es una aproximación: el plano no dibuja los límites de barrio, solo
  los rotula, y en la frontera entre dos hay casillas que caen en el vecino.

**Hay monte.** `MONTE` / `Suelo.Monte` es un tipo de suelo propio y es la mitad del mapa:
se pisa pero no se conduce, y va más tupido de árboles que un parque urbano.

**Los sitios llevan la coordenada del plano**, no una pista. Por eso se colocan buscando la
casilla pisable **más cercana** (`cercaDe` / `Ciudad.CercaDe`), no una al azar del
vecindario: correr la catedral cien metros la saca del Casco Viejo. La batería comprueba
que ninguno se va más de 30 casillas de donde lo pone el plano, y
`herramientas/plano/sitios.py` que el HTML y Unity tengan las mismas coordenadas.

Si tocas el extractor, **comprueba tres cosas**: que la red viaria siga por encima del
90 % (lo mide la batería), que los sitios sigan cerca de su coordenada, y saca el plano y
míralo:

```bash
node herramientas/html/plano.js                      # con rótulos y chinchetas
node herramientas/html/plano.js salida.png --zoom 2 --sin-nombres
node herramientas/html/manzanas.js                   # el grano de la trama
```

## El mundo: tejados, tráfico y gente

Tres cosas que salen del plano sin escribir una coordenada, porque el estilo de cada
barrio ya viene del extractor:

**Los tejados dicen en qué barrio estás.** Cuatro familias —teja, pizarra, azotea y nave—
y la elige el barrio de **cada casilla**, no el del rincón por el que el recorrido empezó
el edificio: la manzana del Casco Viejo es una sola pieza de 6366 casillas que cruza a
Abando, y tomando el estilo del origen el casco entero salía de pizarra. Los umbrales
(`familiaTejado`) salen de medir el plano: la mediana de una manzana son 44 casillas y el
percentil 90 son 220.

Dos cosas que costaron un intento cada una: los tejados son **materia, no objetos** —un
depósito dibujado dentro del tile se repite en cada casilla y la azotea parece papel
pintado, así que los remates van sueltos y sembrados por hash como las farolas—; y la
variante cambia **por parches de 6 casillas**, que con un solo tile una manzana así es una
plancha lisa.

**El tráfico y los peatones también.** `TRAFICO_BARRIO` y `PEATON_BARRIO` reparten trece
chasis y dieciocho arquetipos según el estilo: taxis y gabardinas por la Gran Vía, monos de
faena y camiones en Zorrotzaurre, motos por el Casco.

## Los edificios singulares

Trece sitios —San Mamés, el Guggenheim, el Arriaga, el Ayuntamiento, la catedral, Begoña,
la torre Iberdrola, el Euskalduna, Abando, la Ribera, la Alhóndiga, el Arena y los
Almacenes Ibaizabal— **se dibujan enteros y a su tamaño real**, encima del tejado
genérico. Antes eran una chincheta sobre una manzana igual que las demás: el juego te
decía dónde estaban y desde arriba no se veía nada. La estación de Abando ocupa 35 casillas
de largo porque la nave mide 180 m; no cabe en pantalla de una vez, y así debe ser.

Tres cosas que hay que respetar al tocarlos:

**Se dibujan en casillas, no en píxeles.** El pincel que recibe cada dibujo (`T`) trabaja en
unidades de casilla, con decimales. La primera versión iba en píxeles absolutos y valía
mientras un singular medía ocho casillas; a treinta y cinco, un remate de tres píxeles sobre
un lienzo de mil se pierde. Esto no es un detalle de estilo: **el tamaño final no se conoce
hasta que carga la ciudad**, porque se encogen hasta que caben.

**Se colocan solos, y por eso hay que fiarse del plano hasta cierto punto.** El rótulo del
plano trae un error de unas casillas, y en dos casos es gordo: los de San Mamés y el Arena
caen literalmente en mitad de la ría. `colocarSingulares()` desliza la caja alrededor del
rótulo (tabla de sumas acumuladas, cada candidato son cuatro restas), se queda donde más
manzana pisa y menos agua toca, y si a 10 casillas no hay suelo busca a 20; si aún así no
cabe, encoge el edificio de 10 en 10 %. El tope de 20 es a propósito: la batería exige que
ningún sitio se aleje más de 30 del plano, así que la colocación no puede ser nunca la que
rompa eso.

**No pintan sobre la calle ni sobre el agua.** `dibSingulares` va casilla a casilla, no de un
trazo: la caja de un edificio de 180 m siempre pilla un trozo de calle por medio y esa calle
tiene que seguir estando. `pintable()` es la lista de lo que se respeta — calle, acera de
enfrente, ría, muelle, puente y monte.

Las medidas están escritas en dos sitios (`PLANO_SINGULAR` en el HTML, `DePlano` en
`Singulares.cs`) y `herramientas/plano/singulares.py` las compara, igual que
`sitios.py` compara las coordenadas.

Sobre nombres: los edificios públicos van con el suyo, que es un hecho de la ciudad. **Las
marcas comerciales no**: no hay ningún Corte Inglés ni ninguna otra cadena en el mapa. Los
grandes almacenes de la Gran Vía son los **Almacenes Ibaizabal**, inventados, con su
interior de tres mostradores y su encargada; igual que Trapos Gran Vía, la Tasca Ondarra o
la Galería Abandoibarra. Sitio real, nombre nuestro.

## La portada

El título iba en HTML: tipografía del sistema, degradados y el mapa teñido de rojo. Nada
de eso está en el juego, así que la primera pantalla mentía sobre lo que venía después.
Ahora se dibuja entera en su lienzo con **la fuente BLOQUE, la paleta de 48 y los sprites
forjados**, sobre un trozo del plano de verdad —con la ría dentro, que es lo que se
reconoce de Bilbao desde arriba— y a **escala entera**, para que un píxel del rótulo mida
lo mismo que un píxel del juego. La barra de carga dice qué se está forjando.

Los botones siguen siendo `<div>`: la lógica no cambia, solo se colocan encima de lo
dibujado y se quedan transparentes. Así el clic sigue funcionando igual en el navegador,
en la batería y en `mando.js`.

Dos trampas del arranque, las dos por preguntar lo que no era:

- **`map` está preasignado**, así que `map.length` dice que sí desde el primer paso de la
  carga. El fondo se cacheaba vacío y la portada salía negra. Hay una bandera,
  `ciudadLista`, y `cargarCiudad` tira la caché del mapa.
- **A una casilla por píxel el recorte cae entero sobre manzanas**: 320 casillas son
  kilómetro y medio de edificios y sale una plancha oscura. Se coge el doble de ciudad.

## El mando

La pantalla en medio y los mandos en el marco. El reparto no se decide de memoria:
`node herramientas/html/mando.js` abre el juego en Chromium a tamaños de móvil reales,
mide en píxeles CSS y lo pasa a milímetros. Con el 17 % de marco de la primera versión y el
joystick atado a la altura, en un móvil de 5,4" el joystick salía a **14,5 mm** —más
pequeño que el pulgar que lo usa— y los botones a 9,1 mm, justo en el mínimo que se puede
acertar. Ahora el marco es `clamp(112px, 20%, 220px)` y el joystick se mide **desde el
marco**: 21 mm y 14,5 mm en ese mismo móvil.

El mando **no lleva ni un degradado de CSS**: los sprites los forja el juego (`forjarMando`)
en la paleta y con la luz de arriba a la izquierda, como todo lo demás, y el tamaño en
pantalla va en múltiplos enteros del sprite (`ajustarMando`) para que no salgan píxeles a
medias. La letra va dentro del sprite y en negro, que sobre plástico de hueso es lo único
que se lee.

## Comercio y transporte

Los sitios donde se entra son **trece**, y los cinco últimos los comparten varios POI: el
rótulo de la puerta lo pone el sitio (`entrar(id, desde, nombre)`), no el plano de dentro.
Dos tascas iguales por dentro y con distinto nombre en la puerta es lo que hay en
cualquier barrio, y así no se duplica un plano por cada esquina.

**La ropa cambia al personaje de verdad.** No es un icono ni una estadística: la forja ya
sabe montar cualquier combinación de torso, piernas, calzado y gorro —es como se dibujan
los veinte peatones—, así que comprar una prenda cambia cuatro campos del arquetipo del
protagonista y tira su hoja (`delete HOJAS.protagonista` / `Hojas.Remove`) para que se
vuelva a forjar. Cambiarse **quita una estrella**, como repintar el coche: la descripción
que la pasma va pasando por la emisora deja de valer.

**Tres redes de transporte**, y lo que las diferencia es la cobertura:

| | Tarifa | Paradas | Velocidad |
|---|---|---|---|
| **Bilbobus** | 2 € | los 34 barrios | lenta |
| **Metro** | 3 € | 11 estaciones | la más rápida |
| **Cercanías** | 3 € | 6 apeaderos | rápida, y baja al fondo del valle |

Viajar cuesta dinero y **reloj** (`S.min`), y con estrellas no te dejan subir: si no, un
billete de dos euros sería la mejor huida del juego. Abando es de las dos redes, que es lo
que pasa de verdad.

Las paradas de bus **no son POIs** y no llevan coordenada escrita: se sacan del rótulo de
cada barrio en el plano, con la acera más cercana. Treinta y cuatro chinchetas más taparían
la ciudad en el radar, así que se encuentran estando encima.

## Nivel, propiedades y alquiler

La fama por gremio (`S.rep`) ya existía y desbloquea curros, pero es local. El **nivel de
personaje** (`S.nivel`) es el resumen de todo — misiones, curros, golpes limpios — y es lo
que abre las armas grandes (uzi a nivel 4, escopeta a 6), los vehículos (furgoneta 2,
deportivo 5) y, sobre todo, **lo que te dejan comprar**. La curva sube deprisa a propósito:
si el dinero llega antes que el nivel, comprar deja de ser una meta y pasa a ser un trámite.

**Diez propiedades**, cuatro viviendas y seis negocios. No hay inmobiliaria ni menú de
compra: las viviendas se compran **en su puerta** y los negocios **a su dueño, dentro**. Si
quieres el taller, vas al taller y se lo dices a Iker. Un negocio renta cada día —se cobra
al dormir— y en un local tuyo no se paga: comer, vestirte o que te arreglen el coche sale
gratis en tu propia casa, que se nota más que un número en una pantalla de estadísticas.

**El alquiler tiene a alguien al otro lado.** Amaia lleva la cuenta del piso de Santutxu, y
los estados van en orden y sin callejones sin salida:

| | |
|---|---|
| `aldia` | Al día. Solo aquí te vende el piso, y solo con paciencia ≥ 3. |
| `debiendo` | Un recibo sin pagar. Duermes peor. |
| `avisado` | Dos recibos: te avisa de que la próxima te cambia la cerradura. |
| `desahuciado` | Tres: la llave ya no entra. Volver cuesta la deuda **más** la cerradura. |
| `okupa` | Has forzado la puerta. Es un delito, se oye, duermes en el suelo y a veces viene la pasma. |

Pagando se vuelve siempre, aunque el precio de volver suba. Y hay salida limpia: **dejar el
piso** corta el recibo, y **comprarlo** lo corta para siempre. El estado de la casera es
precondición de la compra: eso ata las dos cosas y hace que comprar dependa de cómo te has
portado, no solo de la cartera.

## Sigilo

Hasta que se metió esto, el juego repartía estrellas por el hecho de hacer algo, mirara
quien mirara: robar un coche en un descampado a las cuatro de la mañana costaba lo mismo
que robarlo delante de una patrulla. **Ahora lo que cuenta es que te vean**, y esa es la
regla entera: `delito(n)` solo llama a `estrellas(n)` si `testigos()` dice que sí.

Todo cuelga de tres cosas que ya estaban: `lineaVista`, hacia dónde mira cada uno y el
reloj.

- **La postura la decide el propio joystick**, sin botón nuevo: por debajo de `AGACHA`
  (0,34) vas agachado, por encima de `CORRE` (0,82) corriendo. Se queda puesta al soltar,
  que si no, agacharse para mirar una esquina y levantarse solo al parar sería inservible.
  Agachado se te ve **la mitad de lejos** y andas a 1,25 casillas/s en vez de a 4,8.
- **Cono de 60° y línea de vista.** A menos de 2,2 casillas no hace falta cono: te tiene
  encima. Un coche se ve venir aunque vayas despacio; **de noche** (antes de las 7 y
  después de las 21) el alcance baja de 15 casillas a 9.
- **La sospecha se llena mirando y se vacía al perderte de vista.** El HUD lo pinta en un
  ojo debajo del arma: sin eso, el sigilo se juega a ciegas.
- **El ruido no ve, pero orienta.** Un disparo son 18 casillas —5 con silenciador, que se
  compra en el Bazar por 520 €—, un cristal roto 7, el claxon 12, una explosión 30. Quien
  lo oye va a mirar ahí.
- **Los enemigos de misión nacen sin saber que existes** y dan vueltas por donde están.
  Sin eso el sigilo no serviría de nada: toda la banda te vendría encima al aparecer.
- **Golpe por la espalda**: cuerpo a cuerpo, a menos de 1,4 casillas, por detrás y a
  alguien desprevenido — cae de un golpe y casi sin ruido. Es el premio de haber ido
  despacio; si no, el sigilo solo serviría para tardar más en llegar al mismo tiroteo.
- **Despistar a la pasma** ya no es alejarse: es que ninguno te tenga a la vista. Agachado
  detrás de un contenedor, con la patrulla a diez metros pero mirando a otro lado, la
  cuenta corre — y baja a 8 segundos por estrella en vez de 12.

Agachado no lleva dibujo nuevo: se acortan las dos piernas y se baja el cuerpo dos
píxeles. **Dos, no tres**: con tres, el contorno de los pies se sale de la celda y salta
la regla del verificador.

## El arte

**Todo el juego sigue una sola guía de estilo: [`referencia/ESTILO.md`](referencia/ESTILO.md).**
Proporciones, vista, dirección de la luz, uso del color, contorno, tipografía, rejilla de
la interfaz y animación. Léela antes de dibujar nada.

No es un documento de buenas intenciones: la mitad de sus reglas las comprueba
`herramientas/html/estilo.js` sobre el arte de verdad —el que se forja al arrancar— y
`./verificar.sh` falla si alguna se incumple. Las reglas que se comprueban solas son las
que sobreviven.

```bash
node herramientas/html/estilo.js      # ¿el arte cumple la guía?
node herramientas/html/iconos.js      # todos los iconos en una hoja, a dos tamaños
node herramientas/html/personajes.js  # las hojas de personaje, para juzgarlas
node herramientas/html/personajes.js --esc 8 --que protagonista,ertzaina
node herramientas/html/captura.js    # el juego en marcha, para ver el arte en la calle
node herramientas/html/fuentes.js     # seis fuentes en una imagen, para elegir
python3 herramientas/sprites/pixellab.py --simular   # sprites de PixelLab, sin gastar red
```

Los sprites de PixelLab necesitan clave (`PIXELLAB_API_KEY`) y salida a `api.pixellab.ai`,
que **desde una sesión de Claude está cerrada**: eso se ejecuta en local. Ver
`herramientas/sprites/LEEME.md`.

## Pixel perfect

El arte es pixel art y hay que dibujarlo sin medios píxeles. Tres reglas, y las tres hacen
falta a la vez:

- **Escala entera.** Un píxel de textura ocupa un número entero de píxeles de pantalla. En
  el HTML el zoom se redondea (con histéresis, para que no baile); en Unity el tamaño
  ortográfico se despeja de `Screen.height / (2 · PPU · escala)` con `escala` entera.
- **Cámara clavada al píxel.** Si la cámara se traslada en fracciones, el mundo entero
  tiembla al andar aunque cada sprite esté bien.
- **Sprites clavados al píxel.** Todo lo que lleve `SpriteRenderer` se coloca con
  `Mundo.AMundoPixel`, no con `Mundo.AMundo`.

Y `DPR` entero en el HTML: con 1,5 un píxel de textura cae a caballo de dos de pantalla.

## Estructura

```
referencia/          prototipo HTML probado, forja de sprites, estudio de arte, capturas
unity/BilboCity/     proyecto Unity 2022.3 LTS
  Assets/Scripts/
    Arte/            paleta, forja de personajes, tiles, vehículos, fuente de bits
    Ciudad/          carga de la trama de Bilbao, volcado a Tilemaps, mobiliario urbano
    Entidades/       jugador, vehículo, peatones, enemigos, tráfico
    Juego/           estado, combate, misiones, curros, interiores, acciones, bootstrap
    UI/              HUD, controles táctiles, menús, audio, guardado
  Assets/Editor/     script que prepara la escena
herramientas/        verificadores de C# y arnés de pruebas del HTML
TAREAS.md            lo que queda por hacer, por orden
```

## Cómo abrir el proyecto Unity

Unity 2022.3 LTS → abrir `unity/BilboCity` → menú **BilboCity → Preparar escena** → Play.

No hay ningún `.unity` en el repositorio a propósito: lo crea el script del editor. Una
escena serializada a mano es la mejor forma de acabar con un proyecto que no carga.

## Qué NO hacer

- No reescribas el HTML para "modernizarlo". Es la referencia probada, no deuda técnica.
- No metas dependencias nuevas de Unity sin una razón fuerte. El proyecto va con paquetes
  base a propósito.
- No sustituyas la trama por algo procedural. La gracia es que sea Bilbao de verdad.
- No añadas `.unity`, `.meta` ni `Library/` al repositorio.
