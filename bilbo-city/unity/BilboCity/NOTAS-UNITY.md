# Bilbo City · Unity

Juego sandbox 2D cenital ambientado en Bilbao, para móvil. Todo el arte y todo el audio se
generan por código en tiempo de ejecución: **el proyecto no contiene ni una imagen ni un
archivo de sonido**.

---

## Estado de verificación

**El C# ya compila.** No en Unity — en el entorno donde se trabaja no hay editor — sino
con Roslyn contra un remedo de la API del motor que vive en `herramientas/compilar/`. Los
20 ficheros compilan a ensamblado, con la misma separación que los `.asmdef` (el proyecto
de runtime no ve `UnityEditor`) y con `-warnaserror`: cero errores, cero avisos.

```bash
apt-get install -y dotnet-sdk-8.0
herramientas/compilar/compilar.sh
```

Salieron dos errores y se arreglaron: `Random.value` ambiguo entre `UnityEngine.Random` y
`System.Random` en `Misiones.cs`, y un campo muerto en `RenderCiudad.cs`. Están anotados
en `TAREAS.md`.

Sigue en pie la cadena de verificación sobre el árbol de sintaxis (tree-sitter), que es más
barata y caza cosas que el compilador no mira:

| Comprobación | Resultado |
|---|---|
| Sintaxis de los 20 ficheros | **todos parsean, 0 errores** |
| Tabla de símbolos | 61 tipos · 240 métodos · 541 campos y propiedades |
| Miembros que no existen | **0** |
| Número de argumentos en llamadas y constructores | **0 fallos** |
| Miembros de enum y tipos anidados | **0 fallos** |
| Tipos referenciados desconocidos | **0** |
| Listas modificadas mientras se recorren | **0 casos sin salida** |

La última comprobación merece una nota: es el fallo que más veces aparece al portar de
JavaScript a C#. En JS no pasa nada; en C# la excepción salta en el siguiente `MoveNext`.
El analizador construye el grafo de llamadas, propaga qué método toca qué lista y resuelve
el tipo de la variable del `foreach` para no confundir los seis métodos distintos llamados
`Tic` que hay en el proyecto. Se validó plantando a propósito un fallo conocido: lo cazó.

Para pasarlo tú:

```bash
pip install tree_sitter tree_sitter_c_sharp
./Herramientas/comprobar.sh
```

**Aun así, cuenta con que la primera compilación en Unity dé algún error.** El remedo de la
API no es el motor: reproduce las firmas que este proyecto usa, pero no las versiones de los
paquetes, ni IL2CPP, ni los `.meta`, ni una firma que Unity haya cambiado y aquí esté puesta
a mano. Lo que ya no debería salir es la lista larga: sobrecargas mal resueltas, conversiones
que no existen, genéricos que no encajan, miembros inventados.

Y compilar sigue sin ser ejecutar. Que el juego arranque, se vea Bilbao y no pete a los diez
minutos es la tarea 2 de `TAREAS.md`.

`bilbo-city.html` sigue siendo la implementación de referencia: está ejecutada y probada.
Si algo aquí no cuadra, la respuesta está ahí.

---

## Instalación

1. Unity **2022.3 LTS**.
2. Abre la carpeta `BilboCity` como proyecto.
3. Menú **BilboCity → Preparar escena**.
4. **Play**.

Para Android: menú **BilboCity → Ajustes recomendados para Android** y Build normal.

No se incluye ningún `.unity` a propósito: una escena serializada a mano y sin poder abrirla
es la mejor forma de acabar con un proyecto que no carga. La crea el script del editor.

---

## Qué hay dentro

**La ciudad es Bilbao.** Un atlas de 20×20 celdas reparte 17 barrios reales; encima se tallan
la ría en arco (entra por Bolueta, vértice en el Arenal, sale por Zorroza), el Canal de Deusto
que convierte Zorrotzaurre en isla, la Gran Vía en diagonal con Moyúa y Sagrado Corazón, San
Mamés como estadio elíptico, diez puentes y los montes cerrando el valle. Cada barrio tiene su
tamaño de manzana, ancho de calle, pavimento y tinte.

**Contenido:** 8 misiones de campaña encadenadas · 8 curros con reputación por gremio y
contratos con bonus · 5 armas · búsqueda policial escalada · 7 interiores · 15 sitios,
5 de ellos monumentos visitables · conducción con derrape y daño · alquiler semanal.

**Arte:** 48 colores bloqueados con cuantizador. Personajes montados por capas, 8 direcciones
× 14 poses × 20 arquetipos. 13 chasis de vehículo × 7 libreas. Fuente de bits propia de 5×7
con contorno y bisel. Mobiliario urbano sembrado por hash de casilla, así que la ciudad sale
siempre igual.

---

## Mapa de ficheros

| Fichero | Qué hace |
|---|---|
| `Arte/Paleta.cs` | 48 colores, cuantizador, `Lienzo` (dibujo por píxel) |
| `Arte/ForjaChar.cs` | Personajes por capas · 8 dirs × 14 poses × 20 arquetipos |
| `Arte/Forja.cs` | Tiles, vehículos, props, armas en mano, fogonazos |
| `Arte/Fuente.cs` | Fuente de bits e iconos del HUD |
| `Ciudad/Ciudad.cs` | El atlas de Bilbao, la ría, el canal, la Gran Vía, los puentes |
| `Ciudad/RenderCiudad.cs` | Vuelca el mapa a Tilemaps y anima el agua |
| `Ciudad/Mobiliario.cs` | Siembra farolas, árboles, contenedores, semáforos, grúas |
| `Entidades/Jugador.cs` | Movimiento a pie, poses, conversión mundo↔Unity |
| `Entidades/Vehiculo.cs` | Física de coche a mano: agarre, derrape, daño |
| `Entidades/Npc.cs` | Peatones, enemigos, tráfico y patrullas |
| `Juego/Estado.cs` | Partida, armas, curros, contratos, sitios |
| `Juego/Combate.cs` | Balas con pool y subpasos, partículas, estrellas |
| `Juego/Misiones.cs` | Las 8 misiones y los 8 curros |
| `Juego/Interiores.cs` | Los 7 interiores, diálogos y minijuego |
| `Juego/Acciones.cs` | Botón de acción, ataque con auto-apuntado, conversaciones |
| `Juego/Juego.cs` | Bootstrap y bucle principal |
| `UI/Hud.cs` | Radar circular, anillo de salud, panel de misión |
| `UI/Controles.cs` | Joystick táctil, audio sintetizado, guardado |
| `UI/MenuMovil.cs` | Móvil, pausa y tiendas |

---

## Decisiones que conviene conocer

**Nada de físicas de Unity.** Ni Rigidbody2D ni Collider2D. Colisión por casilla con
deslizamiento por ejes. Predecible, rápida en móvil, idéntica en todas las máquinas.

**La Y va al revés.** En el mundo del juego crece hacia abajo; en Unity hacia arriba. La
conversión está centralizada en `Mundo.AMundo` / `Mundo.ACasilla`, y `Lienzo.VolcarEn`
voltea la Y al construir los atlas. Si algo sale espejado, mira ahí.

**Sin basura en el bucle caliente.** Las balas salen de un pool, no se crean y destruyen por
disparo. El radar se pinta sobre un buffer cacheado y sube a la GPU una sola vez por frame,
y el fondo del mapa solo se recalcula cuando el jugador cambia de casilla.

**Atlas por arquetipo, bajo demanda.** `ForjaChar.Hoja()` compila la hoja la primera vez que
se pide ese arquetipo y la cachea. Arranque rápido, memoria solo por lo que sale en pantalla.

**Ciclo de vida de app.** 60 fps objetivo, pantalla sin apagarse, y guardado automático al
perder el foco, al pausar y al salir. El guardado va versionado y con migración tolerante:
si la partida está corrupta o es de una versión más nueva, se descarta sin petar.

---

## Lo que queda

- **Abrir el proyecto en Unity y compilar de verdad.** Roslyn ya dice que sí; el editor
  todavía no ha opinado. Es el paso pendiente de verdad.
- Sin oclusión de interiores de manzana: los patios se ven, pero sin transición.
- El mobiliario son GameObjects sueltos (unos cuantos miles). Funciona y Unity los culla,
  pero si el presupuesto de dibujado aprieta, el siguiente paso es un tercer Tilemap en modo
  `Individual` con ordenación por eje Y.
- Sin compras integradas, ni analítica, ni logros. Eso es trabajo de publicación, no de juego.
