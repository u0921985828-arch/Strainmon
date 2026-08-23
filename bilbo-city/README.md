# Bilbo City

Juego sandbox 2D cenital tipo *GTA Chinatown Wars*, ambientado en **Bilbao**, para móvil.
Además del crimen se pueden hacer curros honrados: repartir pintxos, descargar en el muelle,
turnos de taxi, peón de obra. Y pagar el alquiler cada semana.

Todo el arte y todo el audio se generan por código. **El repositorio no contiene ni una
imagen ni un archivo de sonido.**

---

## Arranque rápido

```bash
# dependencias, una sola vez
pip install -r herramientas/requirements.txt
cd herramientas/html && npm install && cd ../..
apt-get install -y dotnet-sdk-8.0        # para compilar el C# sin Unity

# jugar al prototipo: abrir en el navegador
open referencia/bilbo-city.html

# verificar que todo sigue en pie
./verificar.sh
```

Para el proyecto Unity: Unity 2022.3 LTS → abrir `unity/BilboCity` →
menú **BilboCity → Preparar escena** → Play.

Para trabajar con Claude Code: `claude` desde la raíz. Lee `CLAUDE.md` solo, y tienes los
comandos `/verificar`, `/tarea`, `/ciudad` y `/portar`.

---

## Las dos implementaciones

| | Estado |
|---|---|
| `referencia/bilbo-city.html` | Completo, **ejecutado y probado**. Fuente de la verdad. |
| `unity/BilboCity/` | Puerto a Unity, **compila** (Roslyn contra remedo de la API), **sin abrir en el editor todavía**. Objetivo de producción. |

El HTML no es un juguete ni deuda técnica: es el documento de diseño ejecutable. Se iteró
ahí porque es barato, y solo cuando el juego ya se sentía bien se llevó al motor. Cuando el
comportamiento de los dos no coincida, gana el HTML.

---

## Qué hay en el juego

**La ciudad es Bilbao de verdad.** No es procedural: un atlas de 20×20 celdas reparte 17
barrios reales y encima se tallan la ría en arco (entra por Bolueta, vértice en el Arenal,
sale por Zorroza), el Canal de Deusto que convierte Zorrotzaurre en isla, la Gran Vía en
diagonal con Moyúa y Sagrado Corazón, San Mamés como estadio elíptico, diez puentes y los
montes cerrando el valle. Cada barrio tiene su tamaño de manzana, ancho de calle, pavimento
y tinte de color.

**Contenido.** 8 misiones de campaña encadenadas · 8 curros con reputación por gremio y
contratos con bonus · 5 armas · búsqueda policial escalada · 7 interiores · 15 sitios, cinco
de ellos monumentos visitables · conducción con derrape y daño · alquiler semanal.

**Arte.** Paleta bloqueada de 48 colores con cuantizador. Personajes montados por capas:
8 direcciones × 14 poses × 20 arquetipos. 13 chasis de vehículo × 7 libreas. Fuente de mapa
de bits propia de 5×7 con contorno y bisel. Mobiliario urbano sembrado por hash de casilla,
así que la ciudad sale siempre igual.

---

## Verificación

```bash
./verificar.sh          # todo
./verificar.sh html     # solo el prototipo
./verificar.sh csharp   # solo Unity
```

**El C# se compila de verdad, sin tener Unity.** En `herramientas/compilar/` hay un remedo
de la API del motor — solo firmas, nunca se ejecuta — y el código del juego se compila
contra él con Roslyn, con las mismas opciones que usa Unity 2022.3 (netstandard2.1, C# 9)
y la misma separación de ensamblados que los `.asmdef`: el runtime no ve `UnityEditor`. Va
con `-warnaserror`. Esto resuelve sobrecargas, conversiones implícitas y genéricos, que es
lo que un analizador de sintaxis no puede.

No sustituye a abrir Unity: no cubre las versiones de los paquetes, ni IL2CPP, ni los
`.meta`. Cubre la parte aburrida, que era la larga.

**El prototipo HTML se prueba ejecutándolo.** El arnés monta un DOM simulado con canvas real,
arranca el juego, juega las 8 misiones, entra y sale de los 7 interiores, comprueba que los
15 sitios estén sobre suelo pisable y en su barrio, mide la conectividad de la red viaria,
prueba combate, conducción desde 16 puntos al azar, muerte y 150 s de bucle.

**El C# se analiza sobre el árbol de sintaxis real** (tree-sitter). No es un compilador, pero
verifica sintaxis, miembros inexistentes, aridad de llamadas y constructores, miembros de
enum, tipos desconocidos y listas modificadas mientras se recorren — el fallo que más aparece
al portar de JavaScript a C#, porque en JS no pasa nada y en C# la excepción salta en el
siguiente `MoveNext`.

Último resultado bueno conocido:

```
20 ficheros compilan · 0 errores · 0 avisos
8 misiones · 7 interiores · 15/15 sitios en su barrio
red viaria conectada al 98,5 % · conducción mediana 12,5 casillas
150 s de bucle sin excepciones
61 tipos · 240 métodos · 541 campos · 0 fallos
```

La batería del HTML no está sembrada: usa `Math.random()`, así que las cifras de conducción
bailan entre pasadas y la campaña puede quedarse a un paso de completar una misión dentro
del tope de 40 iteraciones del arnés. Si sale un `FALLO misión no completable`, repítelo
antes de darlo por roto — y siembra el generador, que es el arreglo de verdad.

---

## Estructura

```
CLAUDE.md            contexto y convenciones del proyecto
TAREAS.md            lo que queda, por orden
verificar.sh         verificación completa
referencia/          prototipo HTML, forja de sprites, estudio de arte, capturas
unity/BilboCity/     proyecto Unity 2022.3 LTS
herramientas/
  compilar/          compilación real del C# sin Unity (remedo de la API + Roslyn)
  csharp/            analizadores de sintaxis y semántica
  html/              arnés de pruebas y renderizador del plano
.claude/             permisos y comandos para Claude Code
```

---

## Lo siguiente

Está en `TAREAS.md`. **Abrir el proyecto en Unity.** El C# ya compila con Roslyn contra el
remedo de la API, que era la parte que se podía hacer sin editor; lo que falta es que opine
el motor, se cree la escena y el juego arranque en un móvil de verdad.
