# Ribera Verde — notas para Claude Code

Juego web de un solo archivo: HTML, CSS y JavaScript sin frameworks ni dependencias en tiempo de ejecución. Todo el arte se dibuja por código en canvas. La interfaz (diálogos, menús, HUD) es DOM superpuesto al canvas.

## Comandos

- `npm run build`: une `src/` en `index.html` (offline, fuentes en base64) y `dist/ribera-verde.artifact.html` (formato Artifact: sin `<head>`, fuentes de Google Fonts). Nunca edites esos dos a mano.
- `npm test`: compila y ejecuta `tools/test-historia.js`, que recorre la historia 1→8 en Chromium sin ventana. Tiene que seguir dando **34/34 y 0 errores JS**. La transcripción de diálogos queda en `tools/salida/`.
- `npm run docs`: compila y regenera `docs/GENETICA.md` y `docs/MAPA.md` leyendo los datos de `index.html`. Ejecútalo si tocas variedades, mapas, personajes, objetos o la tienda. El texto «cómo se consigue» de las variedades de tienda y landraces está a mano en `ORIGIN` (`tools/generar-docs.js`).
- `npm run capturas`: compila y regenera `screenshots/`.
- `test`, `docs` y `capturas` leen `index.html`. Si los lanzas con `node tools/...` en vez de `npm run`, ejecuta antes `node tools/build.js`.
- `npm run test:arte`: prueba el motor de sprites con un atlas «de calco» (16 comprobaciones). No toca el `index.html` de la raíz: compila en `tools/salida/arte/`.
- Los scripts de Playwright aceptan `CHROMIUM_PATH` (otro Chromium), `RV_HTML` (otro HTML) y `RV_SALIDA` (otra carpeta de salida). `tools/build.js` acepta `--atlas-dir` y `--salida`.

## Módulos (`src/js`, se concatenan en orden alfabético dentro de un único `<script>`)

`00-nucleo` utilidades · `01-tiles` casillas procedurales (`TILES`, `T()`, `SOLID_G`) · `01b-arte` sprites del atlas de PixelLab (`ARTE`, `frameDe`, `dibujarPJ`, `ambiente`, `accion`, `bAnim`, `artePlanta`…; sin atlas no hace nada) · `02-sprites` personajes 16×20 y plantas 16×26 · `03-datos` `STRAINS`, `DEX`, `RECIPES`, `crossResult`, `LOOKS`, `CTYPES` · `04-mapas` `MAPS` (`town`, `home`, `shop`, `bar`), `POTS` · `05-audio` chiptune y efectos (WebAudio) · `06-controles` teclado y botones táctiles · `07-interfaz` `say`/`talk`/`ask`/`menu`/`toast`/`fade` · `08-mundo` estado `S`, `NPCDEF`, `ITEMS`, movimiento, interacción · `09-cultivo` tiempo, plantas, cama, PC, carta, mesa de genética · `10-calle` clientes y venta · `11-historia` tienda, diálogos de personajes, capítulos, eventos y final · `12-menus` menú START · `13-combate` ladrones y policía · `14-render` dibujo del mundo, del combate y del título · `15-arranque` guardado, título, partida nueva, bucle y `boot`.

## Convenciones

- Resolución interna 240×160, casilla 16 px. En procedural, los personajes se dibujan en `y − 4` y las plantas en `y − 10`, y en combate el sprite de 16×20 se escala ×3. Con atlas mandan las celdas de `manifest.celdas` (ver «Sprites»).
- Toda la UI se mide en «píxeles de consola»: `--u = 100cqw / 240` (la `.screen` es `container-type: inline-size`).
- Los guiones son `async` y se escriben de forma lineal: `await say(texto, NOMBRE)`, `await ask(texto, opciones, NOMBRE)` devuelve un índice y `await menu(items, {cls, title, desc})` devuelve el índice o −1. `{N}` se sustituye por el nombre del jugador.
- La entrada va a una pila de manejadores (`push`/`pop`). Sin manejador, la recibe el mundo (`worldPress`).
- `run(fn)` envuelve cualquier guion con `lock`. El tiempo y el movimiento solo avanzan si `isFree()`.
- Los eventos de historia que nacen fuera de un guion van por `queue(clave, fn)` y se ejecutan cuando el mundo queda libre: redada y retraso al cambiar de día, Darko y Molina al pisar la entrada de la plaza, y `checkStory()` cada vez que se descubre una variedad. Las puertas y los encuentros aleatorios se lanzan con `run()` desde `onStepEnd()`.
- `S` tiene que ser JSON puro: se guarda en `localStorage` (`riberaVerde_v1`) y en el snapshot de recarga. Si añades un campo, ponle su valor por defecto en `newState()`; `migrate()` lo rellena en las partidas antiguas.
- Formatos: `pct(n)` → «12,5»; `eur(n)` → «1300 €», «12.500 €» (en es-ES no se agrupan los números de 4 cifras).

## Partes frágiles (ya rompieron algo una vez)

- **`[hidden]{display:none!important}`** tiene que seguir en el CSS: varios componentes fijan `display` y sin esa regla se quedan visibles.
- **`.right` y `.full` son variantes del menú** (`.menu.right`, `.menu.full`). No las reutilices en el marco de la consola: cuando la columna derecha se llamaba `.right`, el menú salía en fila. Las columnas laterales se llaman `.sideL` y `.sideR`.
- **Build:** usa `String.replace` con función. El código contiene `$'` (glifo `'$'`) y `${`, que un reemplazo con texto interpretaría.
- **`crossResult`:** la función `w` recibe la variedad, no su nombre (`w(A)`). Pasarle `A.n` rompía todos los cruces sin receta.
- **La redada** se comprueba en `newDay()` **antes** de que baje el calor. Al revés no llegaba nunca a 90.
- **Personajes detrás de mostradores:** `interact()` mira una casilla más allá si delante hay `counter`, `barcounter` o `btable`. Comprueba que se pueda llegar a esa casilla (Josune quedó atrapada detrás de dos taburetes).
- **Cambios de capítulo por contador** (variedades, ventas): tienen que comprobarse donde cambia el contador. Al principio el capítulo 5 no saltaba si la 8.ª variedad llegaba por un regalo o un arbusto; ahora `discover()` encola `checkStory()`.
- **Tests:** el piloto automático sustituye `menu` y `typeText` en `window`. Si los conviertes en `const`, el test deja de poder elegir opciones.

## Paleta fija

Hierba `#84cc6c` `#62aa56` `#b0e48c` `#3f8a46` · tierra `#dcc08a` · acera `#dcd6c6` `#bcb4a2` · carretera `#6c7482` · agua `#4a92e0` `#76b4f2` `#b4dcfa` · madera `#c48a52` `#a46e40` `#dcac6c` `#74502e` · contorno `#26262e` · tejados: piso `#d65a4a`, growshop `#46a262`, bar `#4a72c2`, gris `#8a92a2` · caja de diálogo `#f8f8f0` con borde `#46749a` y `#a9d2ec`, texto `#3a3a44` · flecha y alertas `#e04040` · carcasa `#2b9466`. Colores de variedades en `STRAINS[*].c`.

## Cómo añadir cosas

- **Variedad:** añádela en `STRAINS` (el orden del objeto es el número de la Genoteca). Si sale de un cruce, añade la terna en `RECIPES`. Si no, añade su origen en `ORIGIN` (`tools/generar-docs.js`). Después, `npm run docs`.
- **Personaje:** look en `LOOKS`, entrada en `NPCDEF` (`map`, `x`, `y`, `cond`, `talk`) y la función `talkX` en `11-historia`. Si tiene misión, añade su caso en `storyMark()` para que salga la «!».
- **Objeto:** entrada en `ITEMS`. Con `hidden:1`, el objeto va dentro de un arbusto (`bush`) en esa casilla.
- **Mapa:** `newMap()` + `gr`/`ob`/`rect`/`building` en `buildMaps()`, `doors` para entrar y `exits` (felpudo + abajo) para salir.
- **Capítulo:** `CH_TITLES`, `objectiveText()`, la transición en `checkStory()` o en el diálogo que lo dispare, y un paso nuevo en `tools/test-historia.js`.

## Sprites (PixelLab)

- Guía: `docs/PIXELLAB.md`. Qué generar y con qué parámetros: `art/manifest.json`. Qué herramienta para cada sprite, en qué orden y cuánto cuesta: `docs/CATALOGO-SPRITES.md` (se genera con `npm run sprites:catalogo`; no lo edites a mano). Comando: `/sprites [F0..F8|id|estado]` (`.claude/skills/sprites/SKILL.md`). El servidor MCP tiene que llamarse `pixellab`.
- Flujo único: PixelLab → `art/crudo/<grupo>/<sprite>/<dir>/<NN>.png` → `npm run sprites:procesar` → `art/procesado/` → `--atlas` → `assets/sprites/atlas.{png,json}` → build (lo incrusta como `ATLAS`). No edites `art/crudo` ni el atlas a mano. `art/crudo/_ref/` guarda los PNG intermedios de los pasos `previo`.
- Celdas y anclas fijas (`manifest.celdas`): personaje 32×32 con los pies en (16,30), dibujado en (px−8, py−15); planta 32×32 (16,31); combate 64×64 (32,62), pies del rival en (ex+24, 66) y del jugador en (px+24, 142); tiles 16×16; tiles animados en bloques de 32×32; edificios y carpa por la base.
- `referencias` sirve para revisar y para los colores de identidad. A PixelLab solo se envía `entrada`, con el nombre exacto del parámetro de la herramienta; `sprites:validar` lo comprueba. `art/referencias/mapa/` son recortes del mapa + máscara para `create_map_object` (con atlas en el build salen con los tiles aprobados).
- Familias (`manifest.familias`): personaje, mapa-terreno, mapa-objeto, objeto-lote, imagen, procedural. Los assets con el mismo `lote` van en una sola llamada; `depende_de` marca el orden; `previo` es un paso anterior con su propia herramienta.
- Partes frágiles:
  - El bloqueo de color va así: colores de identidad del asset (declarados + los de sus referencias), luego los colores que ya usa el juego (`existentes`). La maestra (121) es solo para PixelLab. Si se bloqueara solo contra la maestra, la tierra acabaría convertida en tono de piel. `paleta.js` deja fuera `mapa/` y la pantalla de título: si entraran, el blanco y negro de las máscaras se colarían en los sprites.
  - Los cogollos se piden en magenta: es la rampa clave que el motor cambia por el color de cada variedad.
  - Máximo 15 colores: por grupo en personajes, combate y VFX; por sprite en tiles, objetos, plantas, edificios y fondos.
  - El nombre de cada animación es su carpeta en `art/crudo/<grupo>/`: no se puede repetir dentro de un asset (las tres de balanceo de la planta se llaman `balanceo-<fase>`).
  - Ningún menor fuma: lo comprueba `sprites:validar`, `procesar.js` no exporta `fumador` para un menor y el motor filtra las acciones de fumar de los grupos de `menores`.
  - Las acciones del jugador (`accion()`) se esperan dentro de los guiones; sin atlas resuelven al instante y los tests no cambian.
  - Escala y estilo (decidido con la persona): figura de 16×16 px como los RPG de portátil de 2004, cabeza grande, cara de dos ojos de 1×2 sin boca, sin idle (estático). Receta del player (`pixellab` en el manifiesto): frontal con `create_image_pro` 16×24 (64 candidatos) → lado, espalda y cada paso de caminar con `edit_image_pixen` sobre el frontal (1 gen cada uno, conserva tamaño y estilo) → `reduce_colors` de todo junto. El oeste lo pone el motor en espejo.
  - A 16 px no funcionan: `create_character` v3 (perfiles emborronados, mínimo 32 px de lienzo) ni `create_image_pro` con referencia para otras vistas (sale troceado o a otra escala).
  - v3 con referencia frontal puede ponerle la gorra del revés en los perfiles: revisa este/oeste y corrígelos con `edit_image_pixen` + `save_to_asset` **antes** de animar (las animaciones salen de la rotación guardada).
  - Las plantillas (`breathing-idle`, `walking-4-frames`) sobre un personaje v3 con referencia pueden salir de espaldas mirando al sur o enseñar la cara de espaldas: revisa cada dirección fotograma a fotograma. Repetir la misma plantilla en la misma dirección no regenera nada.
  - `reduce_colors` exige el mismo tamaño en todos los fotogramas: las animaciones v3 salen a 40×40 y las rotaciones a 32×32; rellena las rotaciones a 40×40 (centradas, sin tocar píxeles) y mándalas como `data:` URL.
  - Las animaciones de plantilla cambian los tonos respecto a la rotación. Antes de procesar, `reduce_colors` con `num_colors: 15` y **todos** los fotogramas del personaje en una sola llamada; su salida va a `art/crudo` y el job queda en `pixellab.reduce_colors_job`.
  - En sesiones cloud, `backblaze.pixellab.ai` está bloqueado: descarga con `https://api.pixellab.ai/mcp/characters/<id>/download` (zip) y `https://api.pixellab.ai/mcp/images/<job>/download?index=N`, que no piden token.
