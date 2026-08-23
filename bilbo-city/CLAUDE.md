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

**No des por buena una tarea sin que `./verificar.sh` pase en verde.** Si tocas la
generación de ciudad, saca también el plano y míralo:

```bash
node herramientas/html/plano.js
```

## Qué comprueba cada cosa

`herramientas/html/pruebas.js` arranca el juego de verdad sobre un DOM simulado con canvas
real: juega las 8 misiones, entra y sale de los 7 interiores, verifica que los 15 sitios
están sobre suelo pisable y en su barrio, mide la conectividad de la red viaria, prueba
combate, conducción desde 16 puntos al azar, muerte y 150 s de bucle.

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

Bilbao no es procedural: está trazada. `Ciudad.cs` tiene un atlas de 20×20 celdas donde cada
letra es un barrio (17 barrios reales), y encima se tallan la ría en arco, el Canal de Deusto
que hace isla a Zorrotzaurre, la Gran Vía en diagonal con Moyúa y Sagrado Corazón, San Mamés
como estadio elíptico, diez puentes y los montes cerrando el valle.

Si tocas el atlas o los trazados, **comprueba dos cosas**: que la red viaria siga conectada
por encima del 90 % (lo mide la batería) y que los 15 sitios sigan cayendo en su barrio.

## Estructura

```
referencia/          prototipo HTML probado, forja de sprites, estudio de arte, capturas
unity/BilboCity/     proyecto Unity 2022.3 LTS
  Assets/Scripts/
    Arte/            paleta, forja de personajes, tiles, vehículos, fuente de bits
    Ciudad/          generación de Bilbao, volcado a Tilemaps, mobiliario urbano
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
- No sustituyas la generación de ciudad por algo procedural. La gracia es que sea Bilbao.
- No añadas `.unity`, `.meta` ni `Library/` al repositorio.
