# Bilbo City

Juego sandbox 2D cenital tipo GTA Chinatown Wars, ambientado en **Bilbao**, para móvil.
Además del crimen se pueden hacer curros honrados. Todo el arte y el audio se generan por
código: **no hay ni una imagen ni un archivo de sonido en el repositorio**.

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
real: juega las 8 misiones, entra y sale de los 7 interiores, verifica que los sitios
están sobre suelo pisable y cerca de donde los pone el plano, mide la conectividad de la
red viaria, prueba combate, conducción desde 16 puntos al azar, muerte y 150 s de bucle.

`herramientas/compilar/` compila el C# de verdad, sin tener Unity: hay un remedo de la API
del motor — solo firmas, nunca se ejecuta — y el juego se compila contra él con Roslyn, con
las opciones de Unity 2022.3 (netstandard2.1, C# 9) y la separación de ensamblados de los
`.asmdef`, así que el runtime no ve `UnityEditor`. Va con `-warnaserror`. **Si añades API
del motor que el remedo no tenga, añádela a `herramientas/compilar/apinado/Api/` con la
firma exacta de Unity** — una firma inventada de más tapa errores reales, que es lo único
que puede estropear esta herramienta.

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
- **Sin assets importados.** Ni PNG, ni WAV, ni fuentes TTF de terceros. Si necesitas algo
  nuevo, se forja por código en `Assets/Scripts/Arte/`.
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
