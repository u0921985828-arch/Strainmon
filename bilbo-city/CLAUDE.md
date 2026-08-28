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

Tres cosas de esa batería no se miden solas y hay que decirlas aparte. **El sonido no se
ejercitaba**: `sfx()` empieza con `if(!AU.ctx) return` y el arnés no tenía `AudioContext`, así
que todas las llamadas a sonido de toda la batería eran no-ops silenciosos y el catálogo
entero se quedaba sin tocar. Ahora el arnés trae un contexto de mentira —los nodos no suenan,
aquí no hay tarjeta, pero se construyen, se conectan y se programan, que es donde están los
errores— y la batería produce los nueve sonidos y el motor. **El reloj del arnés es
virtual** —`now += 16.7` por paso—, así que «150 s de bucle sin excepciones» no dice nada del
coste: un bucle O(n²) nuevo pasaba igual de verde. El tiempo se mide desde fuera, con
`process.hrtime`, en cuatro sitios distintos de la ciudad. El canvas del arnés es de software
y sin GPU, así que esos milisegundos son varias veces los del navegador (hoy, de 4,7 a 6,5): el
número no es el presupuesto del juego, es el testigo de que no se ha multiplicado. Y **el
guardado se prueba de ida y vuelta**, no mirando si hay algo escrito: antes bastaba con que el
almacén tuviera una clave, así que un campo nuevo de `S` que se olvidara en `guardar()` se
perdía al recargar sin que nadie se enterara.

`herramientas/compilar/` compila el C# de verdad, sin tener Unity: hay un remedo de la API
del motor — solo firmas, nunca se ejecuta — y el juego se compila contra él con Roslyn, con
las opciones de Unity 2022.3 (netstandard2.1, C# 9) y la separación de ensamblados de los
`.asmdef`, así que el runtime no ve `UnityEditor`. Va con `-warnaserror`. **Si añades API
del motor que el remedo no tenga, añádela a `herramientas/compilar/apinado/Api/` con la
firma exacta de Unity** — una firma inventada de más tapa errores reales, que es lo único
que puede estropear esta herramienta.

`herramientas/plano/vehiculos.py` compara la punta de los dieciocho chasis. La tabla existía
solo en el prototipo: en el puerto **todo coche se creaba con `vmax: 11f` fijo**, así que el
autobús de línea corría lo mismo que el deportivo, y comprarse un deportivo por 1600 € solo
ponía un booleano —el coche del jugador seguía siendo el mismo utilitario—.

`herramientas/plano/armas.py` compara la tabla de armas —daño, alcance, cadencia, precio y
munición— entre los dos. Es la trampa de siempre y ya mordió: el alcance del puño y el del
bate se quedaron en Unity con el `1.0` y el `1.4` que el HTML abandonó por engañosos —5,2 m y
7,2 m, o sea pegar desde la otra acera—, y como la tabla la usan también los matones, la
diferencia iba en los dos sentidos.

`herramientas/plano/sitios.py`, `singulares.py` y `calles.py` comparan las coordenadas de
los 57 sitios, las medidas de los 13 singulares y los puntos de paso de las 513 calles entre
el HTML y el C#. Es la trampa clásica de tener dos implementaciones: el HTML pasa la
batería, el C# no se ejecuta aquí, y Unity acaba poniendo las cosas en otro lado sin que
nadie lo vea.

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
- **Paleta bloqueada de 61 colores, la de CONTEXT.md §18.6.** Seis familias de ocho tonos
  —hormigón, ladrillo, verde industrial, ría, luz artificial y tez— más los acentos. Todo
  sprite pasa por `cuantizar` / `Paleta.Cuantizar`. No introduzcas colores nuevos.
  Los nombres de siempre (`C.asfalto`, `C.piel1`) siguen valiendo: ahora son **apodos** que
  apuntan a un color de familia, repartidos por significado y no por color más cercano.
  `herramientas/plano/paleta.py` compara colores y apodos entre el HTML y Unity.
- **Sin assets importados.** Ni PNG, ni WAV, ni fuentes TTF de terceros en el
  repositorio. Si necesitas algo nuevo, se forja por código en `Assets/Scripts/Arte/`.
  **Excepción con condiciones: los sprites de personaje pueden venir de PixelLab**
  (`herramientas/sprites/`), pero entran cuantizados a la paleta y escritos como índices
  comprimidos en el bloque `SPRITES`, nunca como archivo de imagen. Y entran por
  **siluetas**, no por personajes: cada parte del cuerpo en su rampa, para poder repintarla
  (ver *El arte*). Lo que falte se sigue forjando: el juego no puede depender de que haya
  hoja.
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

### Los suelos que el plano no distingue

Del plano salen siete cosas: calzada, acera, manzana, parque, agua, puente y monte. El juego
tiene arte para más —muelle, patio de manzana, plaza— y lo tenía **sin una sola casilla donde
ponerlo**: la grúa y el contenedor marítimo se forjaban al arrancar y no se plantaban nunca, y
Zorrotzaurre era césped. `clasificarSuelos()` y `clasificarNombres()` le ponen nombre a la
geometría que ya hay, **sin mover una casilla**:

| | |
|---|---|
| **Muelle** | La acera pegada al agua en barrio industrial —Zorrotza, Olabeaga, Bolueta—, más la de las nueve calles «Muelle …» del callejero, y de ahí quince metros tierra adentro: la explanada donde caben la grúa y el camión. Tres condiciones a la vez, y cada una quita algo: la orilla de Abandoibarra también toca el agua y es un paseo, y el césped de la ladera tampoco es muelle aunque llegue al agua. |
| **Patio de manzana** | El hueco cerrado por edificio que no da a la calzada ni al borde del mapa, y de menos de trescientas casillas: más que eso no es un patio, es un parque al que se entra por otro lado. |
| **Plaza** | La acera de las setenta y siete calles que el callejero llama «Plaza …», extendida dos casillas. No se puede sacar midiendo el ancho: en el plano **ninguna acera pasa de una casilla de holgura**, ni la del Arenal. El nombre sí lo sabe, y el nombre es un dato del plano. |

Es clasificación, no invención: si mañana el extractor sabe distinguirlos, esto sobra.

**La orilla y el muro.** La ría es la mancha más grande de la pantalla y llegaba pegada a la
ciudad sin un canto, dos colores planos. Ahora el agua lleva su espuma contra el borde y la
tierra su paramento en sombra con la albardilla clara encima: eso es lo que dice que del agua
a la calle hay tres metros de subida y no un charco. Y el parque lleva **paseo perimetral** por
donde da a la calle, que a un parque no se entra pisando el césped.

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

**Y no todo el mundo va a algún sitio.** Uno de cada cuatro peatones sale esperando —sentado
en un banco o en la parada del bus— y se queda quieto entre ocho y treinta segundos. Sin eso,
una marquesina es un tejadillo con nadie debajo y un banco es un mueble.

**El tráfico y los peatones también.** `TRAFICO_BARRIO` y `PEATON_BARRIO` reparten trece
chasis y veintiún arquetipos según el estilo: taxis y gabardinas por la Gran Vía, monos de
faena y camiones en Zorrotzaurre, motos por el Casco.

## La calle: bordillo, pasos y mobiliario

El mobiliario iba sembrado por hash sobre cualquier acera: una farola cada 29 casillas
—150 m, y en Bilbao hay una cada 25— caída en mitad del ancho, un semáforo en medio de una
recta y **ni un paso de cebra en toda la ciudad**, con los dos tiles forjados y sin usarlos
nadie. Una calle no es una acera con cosas repartidas: es un bordillo con todo alineado
encima, cruces donde se cruza, y el barrio decidiendo qué hay.

Se calcula **una vez al cargar** y se guarda un byte por casilla (`MOB`), como los tejados:
siete kilómetros de calle no se resuelven por fotograma.

- **El bordillo se dibuja**, no se supone: canto claro en la acera y sombra sobre el asfalto
  de enfrente. Desde arriba, una acera y una calzada solo se distinguen por el color; con el
  escalón se ve cuál está más alta.
- **Los pasos de cebra se encuentran solos.** En mitad de una calle la acera acompaña a los
  dos lados y justo en la bocacalle se interrumpe: ahí es donde cruza la gente. Las bandas
  van paralelas al tráfico, como se pintan de verdad. Salen 10 327 pasos.
- **Todo lo demás va en la fila del bordillo** y a paso fijo a lo largo de la calle: farola
  cada cuatro casillas (21 m), árbol de alineación cada cuatro con otro desfase, papelera
  cada nueve, y los contenedores **en batería de tres**, que es como están en la calle.
- **El semáforo va en la esquina y solo con un paso al lado.** Puesto en cada acera que toca
  un cruce salían 24 058, uno cada cinco metros.
- **El barrio manda**: el Casco (denso) no tiene arbolado y sí bolardos en fila; el Ensanche
  y lo abierto, al revés. La marquesina va donde para el bus de verdad, y la terraza en la
  acera del bar, la tasca o el asador.

**Y la calzada se pinta.** El paso de cebra estaba, pero el resto de la marca vial no: no
había una sola línea de detención ni una plaza de aparcamiento marcada en siete kilómetros de
calle. Ahora la casilla de calzada lleva su pintura, calculada con la misma pasada:

- **Línea de detención** de 40 cm delante de cada paso, y solo por donde se llega a él: la
  cebra vertical cruza una calle norte-sur, así que se para por arriba y por abajo.
- **Plaza de aparcamiento en línea.** Una casilla mide 5,16 m, que es justo lo que ocupa un
  coche aparcado: cada casilla de calzada pegada al bordillo, en tramo recto, es una plaza
  con su línea de fondo a 2,20 m y sus travesaños. De cada tres se deja una sin marcar —vados,
  contenedores, la parada del bus—.

- **Flecha de carril** antes del cruce y en el sentido de la marcha, pero **solo en el cruce
  que tiene paso**: pintada en cada bocacalle salían 36 000, una de cada cinco casillas de
  calzada, y eso no es una ciudad, es un parking. Con la condición del paso quedan 1 700.

Los códigos de pintura van del 200 para arriba (`esPintura`), separados de los muebles: antes
la cebra era el 20 y el 21 y la primera pieza nueva de atrezzo se habría dibujado como un paso.

**El rótulo del local.** Un bar con chincheta y sin nombre en la puerta es un icono flotando
sobre una manzana: lo que se lee desde la acera de enfrente es el rótulo, y es lo que hace que
una calle tenga comercios y no huecos. Va en la fachada con cara a la calle más cercana al
sitio —no siempre la de delante del portal: en el Casco hay locales metidos en un pasaje— y,
si no hay ninguna, contra el canto de la manzana.

**El atrezzo.** Una acera con farolas y papeleras no es una calle: es un pasillo. Además de lo
de siempre hay buzón, parquímetro, señal, hidrante, jardinera, seto, aparcabicis, los iglús del
vidrio y del papel, la moto y la bici aparcadas, el quiosco de prensa y la **boca de metro** en
las once estaciones —hasta ahora el metro se cogía tocando una chincheta sobre una manzana—. El
Casco no lleva la farola de aluminio de la Gran Vía: lleva la de fundición. En la plaza hay
fuente, estatua, reloj y quiosco; en el parque, columpio, tobogán, arenero, portería y fuente
de beber; en el muelle, grúa, contenedores apilados, hormigonera, escombros y el noray de
amarre; en el patio de manzana, trastos, tendedero y la bici del vecino.

**Y una calle levantada.** Bilbao siempre tiene una obra: cada doscientas y pico casillas de
bordillo van tres seguidas con el andamio contra la fachada, la valla que corta el paso y el
cono en el canto. Es lo que ocupa una obra de verdad —no se levanta una acera de cinco metros
y se deja el andamio suelto en mitad—. El andamio es **de una planta, 3,80 m**, y no de seis:
la ley 6 le da a la acera un tope de cuatro metros, y con razón, que un andamio de seis es un
muro. Y el toldo va donde hay escaparate y la placa en la fachada del singular, atados al
sitio como la terraza al bar.

La batería lo mide: que ningún paso caiga fuera de la calzada, que ninguna marca vial se pinte
fuera de ella, que ninguna línea de detención se quede sin su paso delante, que ningún mueble
esté lejos del bordillo, que ningún semáforo esté suelto y que la separación entre farolas
—contada sobre las casillas de bordillo— caiga entre 15 y 45 m.

**Y que no sobre nada.** Toda pieza con medida en `MOB_M` se forja al arrancar, así que cuesta
arranque y memoria; si además no está en `MOB_PIEZA` ni en ninguna siembra, no la ve nadie. Es
el fallo que dejó la grúa y el contenedor marítimo forjados sobre una ciudad sin muelles, y
después cinco piezas de obra sin una acera donde ponerse. La batería lo barre en los tres
sitios donde pasa: **mobiliario** (`MOB_M` contra lo plantado), **muebles de interior**
(`MUEBLES` contra los caracteres de las trece plantas) y **chasis** (`CHASIS` contra las
listas de tráfico). O se planta, o no se forja.

**Y hay gaviotas.** Diez, planeando en círculo por la capa de vuelo —no las tapa nada— con
su sombra en el suelo, y haciendo el corro sobre el agua cuando hay ría cerca, que es donde
comen. Bilbao es puerto a catorce kilómetros del mar: las hay hasta en el Casco. Se reciclan
alrededor del jugador como el tráfico, y de cerca: la pantalla enseña trece casillas de ancho
y diez gaviotas repartidas por noventa no se ven nunca.

**Los coches aparcan en su plaza.** Los cuarenta coches aparcados se soltaban en cualquier
casilla de calzada, en mitad del carril y cruzados. La plaza pintada dice dónde va uno y de
qué lado queda el bordillo, así que ahora van arrimados y mirando a donde va la calle.

## El sol, la hora y el canto negro

La pregunta era si lo que faltaba era contorno o sombra. Son dos cosas distintas y hacían
falta las dos: **el canto dice dónde acaba un objeto** y **la sombra dice cuánto levanta y
dónde se apoya**. Desde arriba, sin sombra, un tejado y el patio de al lado son dos manchas
de color a la misma altura.

- **El sol gira con la hora.** Bilbao está a 43° N: sale por el este, cruza por el sur y se
  pone por el oeste, así que a mediodía la sombra apunta al norte —arriba en pantalla— y a
  primera y última hora se tumba y cruza la calle entera. El largo es altura partida por la
  tangente de la elevación, con tope de cuatro casillas: al ras del horizonte la sombra sale
  infinita y taparía la ciudad.
- **La sombra se resuelve mirando desde la casilla**, no pintando desde el edificio: se mira
  hacia el sol y, si hay manzana a menos de lo que proyecta, esa casilla está a la sombra.
  Por eso dobla la esquina y se para en la acera de enfrente sin llevar la cuenta de nada.
- **La luz de la hora**: noche azul, amanecer y atardecer cálidos, mediodía limpio. Antes
  solo había noche y a las nueve de la mañana la ciudad se veía igual que a las tres.
- **De noche se encienden las ventanas.** A las once la ciudad era una mancha negra con
  farolas: lo que dice que ahí vive gente es la ventana encendida. Se enciende una de cada
  tres, y **siempre la misma** —sale del hash de la casilla, el piso y el hueco—, que si
  parpadeara al mover la cámara sería un cartel de neón y no un edificio. Cada tipo de
  fachada tiene el cristal donde lo tiene: el balcón dos píxeles más arriba, el mirador
  entero, la persiana solo por debajo. Por eso el hueco de ventana (`AN_VENT`, `X_VENT`)
  está fuera de la forja: de noche hay que volver a encontrarlo.
- **De noche las farolas encienden** un charco de luz en escalones —no en degradado, y no es
  un sprite: es luz, como el tinte, y un sprite a medio alfa se saltaría la regla de que todo
  el arte va opaco y en paleta.
- **Todo lo que está de pie proyecta al mismo sitio** y con su altura: la persona (1,7 m), el
  coche (1,5), la farola (4) y el árbol (5,6) salen de la misma cuenta que la manzana. La del
  coche iba dos píxeles abajo a la derecha a cualquier hora, y la de la gente era una elipse
  fija. Sin sol —de noche o dentro de un sitio— queda la sombra de contacto: que algo apoya
  en el suelo hay que verlo igual.
- **Una sombra se para en la fachada.** Al llegar a la pared, la sombra trepa por ella, y en
  una vista cenital eso no se ve: una farola de cuatro metros a primera hora proyecta veinte,
  y sin recortar se le subía al tejado del edificio de al lado. Se corta en la primera manzana
  que encuentra por el camino (`sombraCorta`).
- **Un singular no es una manzana más.** La torre Iberdrola son 165 m y a media tarde su
  sombra cruza Abandoibarra entera; con la altura del barrio —13 m— proyectaba lo mismo que
  el portal de al lado. Cada uno lleva la suya (`ALTO_SINGULAR` / `AltoSingular`, comparadas
  por `singulares.py`) y su sombra es la planta barrida: la caja, su copia corrida y las
  bandas que las unen, **en un trazo y un solo relleno** — con dos rellenos superpuestos la
  parte común sale al doble de oscuro. Tope de 20 casillas: al ras del horizonte una torre
  proyecta cuatrocientos metros y taparía media ciudad.
- **La cara sur solo la da el sol a mediodía.** A primera y a última hora viene de costado y
  la fachada se apaga. Sin esto la calle cambiaba de hora y las paredes seguían igual de
  encendidas a las ocho que a las dos.
- **Dentro, de noche, la luz está encendida**: cálida y floja, no azul y oscura. Con el tinte
  de la calle, entrar en casa a las once era meterse en una cueva.
- **Canto negro en el mobiliario**, la misma regla que ya tenían los iconos del HUD. Solo se
  exige donde hay margen: lo que toca el borde del lienzo no puede llevarlo.

**Y las proporciones del mobiliario.** Estaba dibujado a ojo: una papelera de 1,9 m de ancho,
un bolardo más gordo que una farola, un contenedor de barco de cuatro metros y árboles de
dos. Ahora cada pieza sale de una tabla en metros (`MOB_M` / `MedidasMob`) y se forja a
**20 px/m**, la densidad a la que está dibujada la gente: una papelera se mira al lado de
quien la usa, no al lado de un coche. Lo que pasa de cuatro metros de alto se recorta ahí —
una farola de nueve tapa media manzana y deja de ser una farola.

La batería comprueba que la sombra cae al oeste a las 9, al norte a las 14 y al este a las
20, que a las 23 no hay sol, que la de las 9 es más larga que la de las 14 y que a mediodía
la ciudad no va teñida. El verificador de estilo comprueba que cada pieza mide lo que dice la
tabla y que lleva canto, y `herramientas/plano/mobiliario.py` que la tabla sea la misma en el
HTML y en Unity.

```bash
node herramientas/html/captura.js foto.png --donde 1176,428 --hora 20:45
```

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

## El callejero

El HUD dice por qué calle vas, y son **513 calles de Bilbao sacadas del plano municipal**:
nombre oficial y sitio real, no una lista escrita a mano.

**Cómo se sacan, que tiene truco.** Sobre el mapa el plano no escribe «ALAMEDA URQUIJO» de
un tirón: reparte las letras a lo largo de la calle, una a una y siguiendo su curva. Al
extraer el texto llegan hechas picadillo — la primera versión sacó mil seiscientas «calles»
llamadas `E R O S` u `O T E R O`. Pero el plano trae además, en el margen derecho, el
**índice alfabético del callejero** con el nombre entero y su casilla de la cuadrícula
(A-G × 1-7). Así que se usan los dos: del mapa sale **dónde**, del índice sale **qué**.

1. Las letras del mapa se encadenan por geometría — mismo cuerpo, misma línea de base,
   hacia delante y a menos de dos cuerpos. Las tolerancias son apretadas a propósito: con
   margen de sobra la cadena salta al rótulo de al lado y salen dos calles entrelazadas.
2. Cada cadena se busca en el índice, **solo entre las calles de su casilla o una vecina**.
   Vale que un nombre contenga al otro —el mapa pone «URQUIJO» y el índice «Urquijo
   Alameda»— pero solo si el trozo común pasa de cinco letras y no hay empate.
3. Las dos condiciones a la vez son las que tiran la basura: los números de portal, las
   letras de la cuadrícula y los equipamientos no están en el índice, y un nombre que sí
   está pero aparece en la otra punta de Bilbao no es esa calle.

```bash
python3 herramientas/plano/extraer.py ruta/al/plano_bilbao.pdf
```

Eso reescribe la tabla entera en los dos ficheros, entre `/*<<<CALLES*/` y `/*CALLES>>>*/`:
**no la edites a mano esperando que sobreviva**. El PDF no entra en el repositorio, así que
esa parte se prueba con un **PDF de mentira** —mapa con rótulos repetidos, un equipamiento
sobre una manzana, un número, un barrio, y su índice de margen— en
`herramientas/plano/pruebas_extraer.py`, dentro de `./verificar.sh`.

**Del rótulo a las casillas.** Cada calle llega como unos cuantos puntos de paso: los sitios
donde el plano la rotula. El juego busca el camino de calle que los une, así que lo que se
afirma no es una coordenada sino un trazado. Tres cosas, cada una de un intento fallido:

- **La acera es calle.** Con solo calzada, el Casco Viejo se quedaba mudo —las Siete Calles
  son peatonales y el plano no les pinta trazo de rodadura— y andando, que es la mitad del
  rato, el rótulo no salía nunca. El camino va por calzada ∪ acera ∪ plaza.
- **Pero la calzada vale menos.** Dijkstra con dos precios (calzada 1, acera 4): a igual
  precio el camino se va por la acera y la Gran Vía sale nombrada por el portal.
- **Dos pasadas: primero los trazados, después las faldas.** En una sola, la falda de una
  calle se comía el trazado de la vecina. Y si aun así alguna se queda a cero, se le da la
  casilla de su propio rótulo: que dos calles se disputen una esquina pasa en Bilbao
  también; que una desaparezca del juego, no.

La caja de búsqueda es proporcional al tramo, no fija: con sesenta casillas fijas, mil
calles eran minutos de carga. `node herramientas/html/escala-calles.js 1200` lo mide —
**1234 calles se nombran en medio segundo**.

Para verlo:

```bash
node herramientas/html/plano.js salida.png --calles
node herramientas/html/plano.js ensanche.png --calles --zoom 3 --zona 560,250,380,170
```

**Lo que no está rotulado en el plano no se nombra.** El índice trae unas mil cuatrocientas
calles y se recuperan 513: el resto son las que el plano no rotula sobre el mapa, o cuyo
rótulo queda tan partido que no se puede afirmar cuál es. Donde no hay calle, el HUD enseña
el barrio. Una calle inventada en el sitio de una que existe es peor que no poner nada.

## La portada

El título iba en HTML: tipografía del sistema, degradados y el mapa teñido de rojo. Nada
de eso está en el juego, así que la primera pantalla mentía sobre lo que venía después.
Ahora se dibuja entera en su lienzo con **la fuente BLOQUE, la paleta y los sprites
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
mide en píxeles CSS y lo pasa a milímetros. Y **falla**, no solo mide: durante un tiempo salía con 0 pasara lo que pasara, así que el
joystick que obligó a rehacer el mando se habría podido colar otra vez. No está dentro de
`verificar.sh` porque necesita navegador; se ejecuta a mano al tocar el mando o la portada.
Con el 17 % de marco de la primera versión y el
joystick atado a la altura, en un móvil de 5,4" el joystick salía a **14,5 mm** —más
pequeño que el pulgar que lo usa— y los botones a 9,1 mm, justo en el mínimo que se puede
acertar. Ahora el marco es `clamp(112px, 20%, 220px)` y el joystick se mide **desde el
marco**: 21 mm y 14,5 mm en ese mismo móvil.

El mando **no lleva ni un degradado de CSS**: los sprites los forja el juego (`forjarMando`)
en la paleta y con la luz de arriba a la izquierda, como todo lo demás, y el tamaño en
pantalla va en múltiplos enteros del sprite (`ajustarMando`) para que no salgan píxeles a
medias. La letra va dentro del sprite y en negro, que sobre plástico de hueso es lo único
que se lee.

## Los mandos: pedales, no magnitud de joystick

Al volante el **joystick solo dirige**, y el gas y el freno son sus propios botones:

| | |
|---|---|
| **B mantenido** | Acelerador. La aceleración se integra, así que cuanto más se mantiene, más corre — no hay tope de pulsación. |
| **A mantenido** | Freno, 7 m/s². A toques, frena a toques. Parado y con A puesto, marcha atrás. |
| **A, toque corto** | Parado, te bajas. En marcha, claxon. Se distinguen por el tiempo (250 ms), que es lo único que no obliga a meter otro botón en un marco donde no cabe. |

Antes la **magnitud del joystick** hacía de acelerador, y eso obliga a llevar el pulgar a
medio recorrido mientras se apunta el rumbo con el mismo dedo: o corres o giras.

A pie el joystick sigue mandando la velocidad, pero **con inercia**: pide una velocidad y
las piernas tardan en darla (3,5 m/s² para arrancar, 6 para parar). Iba directa, así que
soltar y volver a empujar cambiaba de paseo a carrera en un fotograma.

**El pedal se lee del botón y de la tecla a la vez.** La batería mueve `teclas` a mano, sin
lanzar eventos, así que mirando solo el estado del botón el coche no arrancaba en las
pruebas aunque en el juego fuese bien.

## Los interiores: la casilla mide 0,40 m

Fuera, una casilla son **5,16 m**. Dentro no puede serlo, y durante mucho tiempo lo fue: con
esa vara el piso medía **72×41 m**, una cama 5 m de ancho, la puerta 10 m y cruzar el salón
costaba cincuenta segundos. Lo que se veía al entrar no se parecía a una casa porque no
tenía el tamaño de una casa.

Ahora la casilla de interior mide **0,40 m** y se dibuja a **8 px**: 20 px por metro, que es
la densidad a la que está dibujada la gente.

Midió 0,80 durante bastante tiempo, y ahí había otro problema escondido: **un muro ocupa una
casilla entera**, así que los tabiques medían 80 cm. Uno de verdad son 10 y una medianera 30.
Entre el 20 y el 44 % de la superficie de cada planta era pared —el piso perdía casi la
mitad— y por eso por dentro los sitios parecían cajas de cartón con todo apelotonado. Con la
casilla a 0,40 los tabiques de dentro bajan a 40 cm; **la fachada se queda de 80 a propósito**,
que en un edificio viejo de Bilbao eso es un muro de carga, y además es lo que tiene el
mobiliario arrimado detrás. En pantalla no cambia nada: hay el doble de casillas, a la mitad.

Lo que la rejilla fina **no** arregla sola es la colocación: los muebles siguen donde los puso
la rejilla vieja, así que un armario deja 40 cm de hueco contra la pared. Eso se arregla
recolocando cada planta a mano, y es trabajo de diseño, no de transformación. Dentro de una
casa la vara de medir es una persona, no un coche, así que **dentro el personaje sale a
escala real** y no con la sobreescala que necesita la calle (ver `ESTILO.md`).

De ahí sale todo lo demás sin tocar nada más: las velocidades y las distancias se escriben en
metros y se convierten con `MS_I`, así que afinar la rejilla no movió ni una.

**Los trece sitios son plantas, no cajas.** El piso compartido tiene dos habitaciones, salón,
cocina y baño alrededor de un pasillo —62 m² útiles, lo que mide un piso de los sesenta en
Santutxu—; el bar tiene su barra, sus mesas y su aseo al fondo; el taller cabe dos coches de
4 m y tiene un portón de 3,2 m, porque por 1,6 no entra ninguno.

**El mobiliario no es un tile repetido: son piezas.** El plano se trocea una vez al entrar
(`piezasDe`) en rectángulos del mismo carácter, y cada pieza se dibuja **entera y a su
tamaño** —una cama de 0,8×2,4 m con su cabecero y su almohada—, igual que los edificios
singulares. Dos casillas de `C` seguidas son una cama de 1,6 m, no dos camas. Los muebles de
`UNITARIO_I` no se juntan nunca: cuatro sillas en fila son cuatro sillas.

Tres cosas que se aprendieron dibujando:

- **Un muro visto desde arriba no se distingue de un suelo** si solo cambia de color. Lleva
  sombra proyectada sobre la casilla que tiene debajo y canto oscuro por donde da a la
  habitación —solo por ahí: dibujado en el tile, una pared de tres metros se ve como tres
  ladrillos sueltos.
- **El suelo se queda en el fondo.** El primer parqué iba con la junta cada ocho píxeles y
  se leía como un muro de ladrillo. Una tabla son 1,2 m × 12 cm: veinticuatro píxeles de
  largo y tres de ancho.
- **El zoom es entero también aquí**, y si el sitio cabe en pantalla se enseña entero: una
  habitación se entiende de un vistazo, no asomándose por una mirilla.

**Y el atrezzo de dentro.** Un piso con cama, armario y sofá está amueblado, pero no está
habitado. Ahora hay televisión mirando al sofá, lavadora en la cocina, radiador debajo de la
ventana y alfombra en el suelo; taburetes en la barra del bar, con su futbolín y su máquina
recreativa al fondo; banco de trabajo y neumáticos en el taller. Las piezas nuevas van en
**minúscula** porque las mayúsculas se acabaron: el plano es un carácter por casilla.

Eso trajo una distinción que no existía: **`PISABLE_I`**, lo que se dibuja y **no** frena.
La alfombra no frena a nadie y el taburete tampoco —se pasa de lado—, y la diferencia no es
cosmética: una fila de taburetes delante de la barra, si frenase, sería un muro y dejaría
medio bar sin manera de llegar. `BLANDO_I` no servía, porque lo que está en esa lista ni
siquiera se dibuja.

La batería mide cada plano: metros cuadrados, ancho de puerta (de 0,8 a 3,2 m y de una
pieza), que **todo el suelo se pueda alcanzar desde la puerta**, que a cada dependiente se le
llegue, y que ningún mueble tenga medidas imposibles —una cama entre 0,8×1,6 y 1,6×2,4 m, un
coche de 1,6×4—. Un cuarto sellado por un mueble no se ve dibujando el plano: se ve cuando
no puedes entrar.

## El guardado desconfía del archivo

Se guarda en `window.storage` (con respaldo a `localStorage`) bajo `bilbocity_v4`, y se
carga **de forma atómica**: se valida y se acota cada campo en variables aparte, y el estado
del juego no se toca hasta que sale todo bien.

No es prudencia de más. Antes se hacía `Object.assign` nada más parsear, y un guardado a
medias —la pestaña cerrada mientras escribía, otra versión del juego, un campo a `null`—
reventaba a mitad. `cargar()` devolvía `false`, que el arranque lee como «aquí no hay
partida», y te dejaba **empezar una nueva encima del estado ya envenenado**: dinero `NaN`,
reloj `NaN`, y el protagonista en la casilla 99999, fuera del mapa, sin nada que pisar.

Tres reglas, y las tres hacen falta:

- **Un número que no es finito o se sale del rango vale el de fábrica**, no `undefined`.
- **La ropa y el arma se validan contra la lista de verdad** —la de la tienda y la de
  `ARMAS`—: una prenda que no existe deja el arquetipo sin torso y la forja se cae al vestir.
- **La posición se valida contra el mapa**: si no es andable, se cae a la casilla andable más
  cercana, y si viene basura, al portal.

La batería prueba las dos cosas: que una partida marcada vuelve **entera** —dinero, munición,
ropa, propiedades y sitio— y que nueve guardados rotos distintos no dejan la partida en mal
estado. Lo primero es lo que caza el campo nuevo que se olvida en `guardar()`; lo segundo,
lo de arriba.

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

## El prólogo: llegar a Bilbao

Una partida nueva **no empieza con el piso puesto**. Empieza en **Plaza Moyúa**, a las
19:20, recién bajado del autobús del aeropuerto y con el primo al teléfono: **Yeray**,
canario como el protagonista pero afincado aquí, que comparte el piso de Santutxu.

Va montado sobre el motor de misiones —con la marca `prologo` / `EsPrologo`, que es lo que
le quita el pago, el contador de misiones y la recogida de enemigos—, así que hereda gratis
la flecha, el cartel del HUD y el aviso de cada paso. Son dos pasos, y cada uno enseña una
cosa que hace falta para moverse por la ciudad: **coger el metro** (Moyúa → Santutxu, 3 €,
que andando son 2,3 km) y **entrar en un sitio**.

Tres detalles que no son evidentes:

- **El paso de `entrar` no lo puede ver el bucle de objetivos.** Dentro de un interior la
  vuelta se va por `actInterior` y no llega a mirarlos, así que lo comprueba `entrar()`.
- **El primo no está en la plantilla del interior.** El plano de `piso` lo reaprovechan las
  viviendas que se compran, y metido en `INT.piso` saldría también en el loft y en el
  caserío: se añade al entrar, y solo en la puerta de Santutxu.
- **El prólogo se guarda** (`S.prologo`). Recargar en mitad de la llegada, sin eso, te deja
  en la calle sin saber a dónde ibas.

El piso se llama **«Piso de Yeray»** en el plano hasta que te instalas; después es tuyo, con
su recibo y su casera. Y el utilitario aparcado en el portal desde el minuto uno ya tiene
dueño: es del primo, y lo dice él.

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
  Agachado se te ve **la mitad de lejos** y andas a 1 m/s en vez de a 6.
- **La figura anda en su propia vara.** La gente y el mobiliario se dibujan a 20 px/m —a la
  escala del suelo una persona mide 21 px y ahí no cabe una cara, ni ocho direcciones— y el
  suelo va a 12,4: **la figura es 1,6 veces más grande que la calle que pisa**. Andando a
  1,7 m/s de mapa avanzaba 0,6 alturas de cuerpo por segundo, cuando una persona de verdad
  avanza una entera, y eso es exactamente lo que se ve como patinar. El ojo no mide metros:
  mide cuerpos. Por eso lo que anda por encima del suelo va multiplicado por `ESC_FIG`
  —velocidad y zancada—, y en metros de mapa sale más rápido a propósito. Dentro de un sitio
  no hace falta, y por eso ahí siempre se vio bien: la casilla de interior va a 20 px/m, la
  misma vara que la gente.
- **La zancada del andar y la de la carrera no miden lo mismo**: 75 cm y 1,80 m. Con una sola
  medida la carrera salía a ocho pasos por segundo —el doble que un atleta— y las piernas
  eran un abanico.
- **Las velocidades se escriben en metros por segundo**, no en casillas. Medidas contra
  la escala del mapa, las de antes eran de otro juego: se andaba a 28,8 km/h, se corría
  a 89,2 y un utilitario hacía 204 km/h acelerando a 7,5 g. En casillas por segundo eso
  no se ve; en m/s no cuela. `MS` convierte, y `VMAX_VEH` da la punta de cada chasis en
  km/h de verdad.
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

Agachado no lleva dibujo nuevo: se acortan las dos piernas y baja **el cuerpo**, no la
figura entera. Esa distinción (`yt` en la tabla de posturas) hace falta desde que la celda
es la de 24×32 de CONTEXT.md §18.1: bajando la figura entera, el contorno de las botas se
quedaba fuera. Y de paso es más correcto — al ponerse en cuclillas los pies no se mueven.

## El arte

**Y la figura es de una pieza.** Al mover la pierna para que el paso se viera, la pierna se
despegó del cuerpo: a esta escala la cadera son seis píxeles y un desplazamiento de dos deja
el pantalón en el aire. Pero al comprobarlo salió que **ya venía roto de antes**: las posturas
acortan la pierna *desde arriba*, así que agachado, herido y media carrera dejaban una franja
de nada entre el torso y el pantalón —386 de 4320 fotogramas—. En una lámina de contacto eso
no canta, porque cada fotograma se mira solo; en movimiento se ve como una figura rota. Se
dibuja la cadera, que además es lo que hay ahí (el pantalón sigue puesto), y `estilo.js`
comprueba que **cada fotograma sea un solo trozo de píxeles pegados**. Las dos excepciones son
de dibujo y no de error: el fogonazo sale del cañón y el carro de la compra va al lado.

**Y gira la figura entera, no solo la cabeza.** Ocho direcciones son ocho dibujos, y es fácil
girar la cara y dejarse el resto: en las cuatro diagonales la cabeza y el torso iban girados y
**las piernas seguían de frente**, con los dos pies mirando a cámara; y de perfil los pies
apuntaban al revés que la cara, porque la pierna de delante se dibujaba por detrás del eje.
Ahora hay una sola cuenta —`mira`, cuánto se va la figura al lado al que mira— que colocan
igual las piernas de pantalón, las de falda y los zapatos, la pierna de detrás queda medio
tapada en las diagonales y el pie de delante asoma la punta. `estilo.js` lo mide: el pie tiene
que irse hacia donde mira el cuerpo, y de espaldas no puede verse la cara.

**El ciclo de andar mueve el pie.** El de antes cambiaba la pierna un píxel de largo y dejaba
el zapato clavado en la misma fila pasara lo que pasara: la figura no andaba, se deslizaba —y
eso, más que el tamaño, es lo que hacía que el andar no se creyera—. Un paso son cuatro
fotogramas: dos apoyos con las piernas separadas de verdad (`dx` en la tabla de posturas) y el
cuerpo abajo, y dos pasos por el centro con una pierna recogida y el cuerpo un píxel arriba.
El signo de `dx` no es el mismo de frente que de perfil: de perfil una pierna adelanta y la
otra se queda, pero de frente eso cruzaría las dos en el centro y lo que se ve es un nudo, así
que de frente se abren a los lados.

**Y la ropa tiene tres tonos de verdad.** Cuatro prendas tenían la luz igual que la base —la
camisa, la camiseta, el polo y los tirantes— y salían planas; la cazadora del protagonista iba
de asfalto con sombra de carbón, dos tonos que a veintiséis píxeles son el mismo, así que el
cuello y la cremallera se perdían dentro de la mancha. Además, lo que se abre por delante
lleva `cierre` y se le pintan solapa y cremallera; lo que no, escote: un jersey con cremallera
es una chaqueta, y a este tamaño se nota. El hombro cae un píxel a cada lado, que con el torso
rectangular la figura era un ladrillo con cabeza.

**La celda de personaje es de 24×32 con el pivote en (12,30)**, y la paleta la de 61
colores: las dos las fija `CONTEXT.md` §18. La celda es apretada a propósito y el arte la
llena, así que la regla del verificador no es «no tocar el canto» —el contorno de los pies
cae en la última fila por diseño— sino **no salirse**: un píxel de color en el borde es un
píxel al que le recortaron el contorno. Por eso el puñetazo, el fogonazo y el carro de la
compra van recogidos: los de antes contaban con siete píxeles de margen lateral y ahora
hay dos.

**Las seis leyes del sprite están en `ESTILO.md`** y se comprueban solas: medida en metros
a la densidad de su familia, cuerpo común con la ropa en capas, ancla por la base, huella y
estorbo, **orden de capas** —suelo, bloques, objetos, vuelo, HUD— y **visión**. La de capas se
verifica grabando un fotograma de verdad y mirando que el orden nunca retroceda; así se cazó
que el mobiliario iba mezclado con el suelo (un árbol de dos casillas perdía la mitad derecha)
y que las chinchetas se pintaban antes que la gente.

De la de visión salen tres cosas que hay que respetar al tocar el mobiliario:

- `TOPE_ALTO` dice cuánto puede medir lo que se planta en cada suelo —acera 4 m, parque 6,
  muelle 12, tejado 2,4— y la batería barre el mapa entero contra la tabla. Si hace falta
  algo más alto, se cambia la tabla y se justifica; no se cuela la pieza.
- Dentro de `OBJETO` **todo va en la misma cola ordenada por la base**, mobiliario incluido.
  Un `drawImage` suelto en el bucle de casillas se salta la profundidad: el jugador acaba
  pintado encima de la farola que tiene delante.
- Lo que pasa de `ALTO_TAPA` (2 m) puede esconder al jugador entero, y entonces se le pinta
  la silueta encima. Toda pieza nueva necesita su alto real en `MOB_M` para que la cuenta
  salga.

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
node herramientas/html/atrezzo.js     # las 58 piezas de calle juntas y a la misma escala
node herramientas/html/personajes.js  # las hojas de personaje, para juzgarlas
node herramientas/html/personajes.js --esc 8 --que protagonista,ertzaina
node herramientas/html/captura.js    # el juego en marcha, para ver el arte en la calle
node herramientas/html/fuentes.js     # seis fuentes en una imagen, para elegir
python3 herramientas/sprites/pixellab.py --simular   # sprites de PixelLab, sin gastar red
```

### Los sprites traídos no son personajes: son siluetas

Lo que se le pide a PixelLab no es «el protagonista», es **una silueta** — chaqueta con
pantalón, abrigo largo, falda, pantalón corto, capucha — y de cada una salen todos los
vecinos que la llevan. La hoja viene pintada con **colores de plantilla**, uno por parte
del cuerpo, y el empaquetado guarda cada parte en su propia rampa de la paleta; como las
rampas no comparten ni un color, repintar es cambiar índices por índices (`lutDe()`). El
pelo largo, el gorro, la bolsa y el fogonazo no se bajan nunca: se forjan encima, anclados
a la cabeza que trae la hoja (`capasEncima()`, `anclaCabeza()`). Es lo que evita que las
hojas se multipliquen por cada peinado y cada sombrero.

Y de cada silueta se baja menos de lo que se ve: **cinco direcciones de ocho** —las otras
tres son espejo— y **once dibujos de dieciséis poses**, porque los pasos de apoyo del andar
repiten y disparar es apuntar con el fogonazo encima. Salen 55 llamadas por silueta y **385
para el juego entero**; pedir cuatro personajes completos eran 512 y vestían a cuatro. El
arquetipo número treinta y ocho no cuesta ninguna.

Si no hay hoja de su silueta exacta, el juego busca la más parecida; si no hay ninguna, lo
forja. **Nunca se queda nadie sin dibujar**, y por eso bajar una sola silueta ya es jugable.

Todo esto se sostiene en que el generador respete los colores de plantilla, y ahí hay dos
trampas que costaron un fallo cada una. El reparto va **por matiz**, no por color
normalizado: un brillo del pelo azul, aclarado hacia el blanco, se acerca más al magenta
del torso que al azul del que salió, y media cabeza acababa repintada del color de la
chaqueta. Y el **contorno se reconoce por no tener color**, no por ser oscuro: el azul puro
tiene luminancia 29, así que con un umbral por oscuridad el pelo se iba entero al contorno y
el arquetipo salía calvo. Los píxeles desvaídos —brillos, sombras apagadas— no se reparten
por tono: se contagian del vecino con color. El empaquetador avisa cuando falta un color de
plantilla o cuando la mayoría de la celda vino apagada, y `--diag` enseña el recuento.

Los sprites de PixelLab necesitan clave (`PIXELLAB_API_KEY`) y salida a `api.pixellab.ai`,
que **desde una sesión de Claude está cerrada** —el proxy contesta 403 al CONNECT—: eso se
ejecuta en local. El orden de la tirada está en `herramientas/sprites/LEEME.md`, y no es
capricho: `--coste` y `--simular` no cuestan nada y comprueban la celda y la tubería entera,
así que **se hacen antes** de gastar las 385 llamadas. Antes de la tirada larga se imprime el
saldo de la cuenta; es un aviso, no un requisito, y nunca aborta.

**Ojo con la celda, que esta vía estuvo muerta sin que se viera.** El empaquetador saca la
celda del propio juego, pero leía solo la caja y los márgenes —24×32— y no la escala a la que
la forja la sube (`PJ_N`/`PJ_D`, hoy 4:3). El juego trabaja a 32×42, así que `cargarSprites`
habría rechazado **toda** hoja traída por «medidas raras» y se habría forjado todo igual, que
es justo lo que tapa el fallo: el juego nunca se queda sin dibujar. Ahora la escala también se
lee del HTML. Y `--simular` **escribe las hojas de mentira en el juego**: sirve para probar la
tubería sin red, pero no se commitea.

## El grano, y por qué no existía

El arte lleva **grano**: la acera no es un gris plano, es piedra; el asfalto tiene diente y
el ladrillo, mancha. Lo pinta `grano()` píxel a píxel y con la escala apagada, porque un
grano a escala 2 son bloques de dos por dos y eso es un damero, no una textura.

**No se dibujaba ninguno.** La función se llamaba `ruido`, y más abajo hay otra `function
ruido` —el ruido del sigilo, el que hace que un disparo oriente a quien lo oye—. Dos
`function` con el mismo nombre en el mismo ámbito no dan error en JavaScript: se izan las
dos y **gana la última**, también para las llamadas escritas antes. Así que las treinta y
una llamadas del arte le pasaban un lienzo donde esperaba una coordenada, no pintaban nada,
y el juego entero llevaba sin grano —el asfalto, la acera, el ladrillo, el revoco, el suelo
de los trece interiores— sin que saltara un solo aviso, porque el resultado de no pintar es
un tile liso, y un tile liso es un tile válido.

Se llama `grano`, que es como lo llamaban los comentarios desde el principio, y
`herramientas/html/duplicados.js` recorre el fichero contando llaves y falla si dos
funciones comparten nombre en el mismo ámbito.

Dos cosas que se aprendieron al encenderlo:

- **La máscara va por `hash`**, el mismo que siembra las farolas, y no por una suma de
  múltiplos: aquella dibujaba rayas en diagonal, y un tile de dieciséis repetido por toda
  una habitación convertía la diagonal en pana.
- **En hexadecimal a mano no se puede.** El suelo del hospital era `#8fa8a0` con su sombra
  en `#7d968e`: `cuantizar` manda los dos al mismo gris de la paleta, así que el jaspeado
  no existía y el suelo salía plano; y un tercer tono se iba a un verde de vegetación. Los
  colores se cogen de la paleta por su nombre, que para eso está.

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
